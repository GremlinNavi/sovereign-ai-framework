# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

import queue
import sys
import threading
import tkinter as tk
import uuid
from pathlib import Path
from datetime import datetime
from tkinter import filedialog, messagebox, scrolledtext, ttk

from .agent import Agent
from .config import is_local_endpoint, settings
from .main import append_turn, load_turns
from .export import export_session_txt, format_evidence_assessment
from .privacy import ConsentStore, PURPOSES, delete_session, export_personal_data, purge_expired_sessions
from .safety import record_safety_event


class Worker(threading.Thread):
    """Run one AI-backend turn without touching the Tk GUI from this thread."""

    def __init__(self, turns: list[dict], results: queue.Queue, consent: ConsentStore):
        super().__init__(daemon=True)
        self.turns = turns
        self.results = results
        self.consent = consent

    def run(self) -> None:
        try:
            # The worker owns its backend state. Its RAG instance opens SQLite
            # connections only in this worker, never in the GUI thread.
            result = Agent(self.consent).chat(self.turns)
            self.results.put(("finished", result.get("content", ""), result))
        except Exception as exc:
            self.results.put(("error", f"{type(exc).__name__}: {exc}", None))


class AssessmentWorker(threading.Thread):
    """Run bounded web research + structured evidence assessment."""

    def __init__(self, question: str, results: queue.Queue, consent: ConsentStore):
        super().__init__(daemon=True)
        self.question = question
        self.results = results
        self.consent = consent

    def run(self) -> None:
        try:
            result = Agent(self.consent).assess_evidence(self.question)
            report = format_evidence_assessment(result)
            self.results.put(("evidence", report, result))
        except Exception as exc:
            self.results.put(("error", f"{type(exc).__name__}: {exc}", None))


class MainWindow:
    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.root.title("Eternal Thread — Sovereign AI Demonstrator")
        self.root.geometry("1100x760")
        self.root.minsize(760, 500)

        self.consent = ConsentStore()
        self._request_initial_consents()

        # This backend is only used from Tk's main thread for indexing and for
        # saving completed conversation turns.
        self.agent = Agent(self.consent)
        purge_expired_sessions(self.agent.rag)
        self.session_id = self._new_session_id()
        self.turns: list[dict] = []
        self.history_files: list[str] = []
        self.results: queue.Queue = queue.Queue()
        self.worker: Worker | None = None
        self.busy = False
        self.status = tk.StringVar()

        self._build_ui()
        self._load_sessions()
        self._new_chat()
        self._set_status(f"AI backend: {settings.chat_backend_name} • Chat model: {settings.chat_model}")

    @staticmethod
    def _new_session_id() -> str:
        return datetime.now().strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:6]

    def _build_ui(self) -> None:
        toolbar = ttk.Frame(self.root, padding=8)
        toolbar.pack(fill="x")
        self.new_button = ttk.Button(toolbar, text="New chat", command=self._new_chat)
        self.new_button.pack(side="left", padx=(0, 6))
        self.refresh_button = ttk.Button(toolbar, text="Refresh history", command=self._load_sessions)
        self.refresh_button.pack(side="left", padx=(0, 6))
        self.reindex_button = ttk.Button(toolbar, text="Reindex knowledge", command=self._reindex)
        self.reindex_button.pack(side="left")
        self.export_button = ttk.Button(toolbar, text="Export .txt", command=self._export_txt)
        self.export_button.pack(side="left", padx=(6, 0))
        self.export_data_button = ttk.Button(toolbar, text="Export my data", command=self._export_data)
        self.export_data_button.pack(side="left", padx=(6, 0))
        self.delete_button = ttk.Button(toolbar, text="Delete chat", command=self._delete_chat)
        self.delete_button.pack(side="left", padx=(6, 0))
        self.assess_button = ttk.Button(toolbar, text="Assess evidence", command=self._assess_evidence)
        self.assess_button.pack(side="left", padx=(6, 0))
        self.privacy_button = ttk.Button(toolbar, text="Privacy", command=self._show_privacy)
        self.privacy_button.pack(side="left", padx=(6, 0))
        self.report_button = ttk.Button(toolbar, text="Report unsafe response", command=self._report_unsafe_response)
        self.report_button.pack(side="right")

        content = ttk.PanedWindow(self.root, orient="horizontal")
        content.pack(fill="both", expand=True, padx=8, pady=(0, 8))

        sessions_frame = ttk.Frame(content, padding=4)
        content.add(sessions_frame, weight=1)
        ttk.Label(sessions_frame, text="Chats").pack(anchor="w", pady=(0, 4))
        self.session_list = tk.Listbox(sessions_frame, exportselection=False, width=30)
        self.session_list.pack(fill="both", expand=True)
        self.session_list.bind("<<ListboxSelect>>", self._select_session)

        chat_frame = ttk.Frame(content, padding=4)
        content.add(chat_frame, weight=4)
        self.transcript = scrolledtext.ScrolledText(chat_frame, wrap="word", state="disabled")
        self.transcript.pack(fill="both", expand=True)

        self.input = scrolledtext.ScrolledText(chat_frame, height=5, wrap="word")
        self.input.pack(fill="x", pady=(8, 0))
        self.input.bind("<Return>", self._send_on_enter)

        bottom = ttk.Frame(chat_frame, padding=(0, 6, 0, 0))
        bottom.pack(fill="x")
        ttk.Label(bottom, textvariable=self.status).pack(side="left", fill="x", expand=True)
        self.send_button = ttk.Button(bottom, text="Send", command=self._send)
        self.send_button.pack(side="right")

    def _set_status(self, text: str) -> None:
        self.status.set(text)

    def _set_busy(self, busy: bool) -> None:
        self.busy = busy
        state = "disabled" if busy else "normal"
        for widget in (self.new_button, self.refresh_button, self.reindex_button, self.export_button, self.export_data_button, self.delete_button, self.assess_button, self.privacy_button, self.report_button, self.session_list, self.send_button):
            widget.configure(state=state)

    def _load_sessions(self) -> None:
        if self.busy:
            return
        if not settings.store_conversations or not self.consent.granted("local_storage"):
            self.history_files = []
            self.session_list.delete(0, tk.END)
            return
        self.history_files = sorted((p.name[:-6] for p in settings.history_dir.glob("*.jsonl")), reverse=True)
        self.session_list.delete(0, tk.END)
        for session_id in self.history_files:
            self.session_list.insert(tk.END, session_id)

    def _new_chat(self) -> None:
        if self.busy:
            return
        self.session_id = self._new_session_id()
        self.turns = []
        self._render_transcript()
        self._set_status(f"New session: {self.session_id}")
        self.input.focus_set()

    def _select_session(self, _event: object = None) -> None:
        if self.busy:
            return
        selected = self.session_list.curselection()
        if not selected:
            return
        session_id = self.session_list.get(selected[0])
        self.session_id = session_id
        self.turns = [
            {"role": turn.get("role", ""), "content": turn.get("content", "")}
            for turn in load_turns(session_id, consent=self.consent)
            if turn.get("role") in {"user", "assistant", "evidence"} and turn.get("content")
        ]
        self._render_transcript()
        self._set_status(f"Resumed session: {session_id}")

    def _render_transcript(self) -> None:
        self.transcript.configure(state="normal")
        self.transcript.delete("1.0", tk.END)
        for turn in self.turns:
            self.transcript.insert(tk.END, f"{turn['role'].capitalize()}> {turn['content']}\n\n")
        self.transcript.see(tk.END)
        self.transcript.configure(state="disabled")

    def _append_error(self, message: str) -> None:
        self.transcript.configure(state="normal")
        self.transcript.insert(tk.END, f"Assistant error> {message}\n")
        self.transcript.see(tk.END)
        self.transcript.configure(state="disabled")

    def _reindex(self) -> None:
        if self.busy:
            return
        if not settings.index_knowledge or not self.consent.granted("knowledge_indexing"):
            messagebox.showinfo("Knowledge indexing", "Knowledge indexing is disabled until it is enabled in configuration and consent is granted.", parent=self.root)
            return
        try:
            added = self.agent.rag.ingest_directory(settings.knowledge_dir)
            self._set_status(f"Indexed {added} new knowledge chunks.")
        except Exception as exc:
            self._append_error(f"{type(exc).__name__}: {exc}")
            self._set_status("Reindex failed — see transcript")


    def _export_txt(self) -> None:
        if self.busy:
            return
        destination = filedialog.asksaveasfilename(
            parent=self.root,
            title="Export conversation as text",
            defaultextension=".txt",
            filetypes=[("Text files", "*.txt"), ("All files", "*.*")],
            initialfile=f"{self.session_id}.txt",
        )
        if not destination:
            return
        try:
            export_session_txt(self.session_id, Path(destination))
            self._set_status(f"Exported research record: {destination}")
        except Exception as exc:
            messagebox.showerror("Export failed", f"{type(exc).__name__}: {exc}", parent=self.root)

    def _export_data(self) -> None:
        destination = filedialog.asksaveasfilename(
            parent=self.root,
            title="Export all locally held data",
            defaultextension=".json",
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")],
            initialfile="eternal-thread-personal-data.json",
        )
        if not destination:
            return
        try:
            export_personal_data(Path(destination))
            self._set_status(f"Exported personal data: {destination}")
        except Exception as exc:
            messagebox.showerror("Export failed", f"{type(exc).__name__}: {exc}", parent=self.root)

    def _delete_chat(self) -> None:
        if self.busy:
            return
        if not messagebox.askyesno("Delete chat", "Delete this conversation and its derived retrieval chunks? This cannot be undone.", parent=self.root):
            return
        if delete_session(self.session_id, self.agent.rag):
            self._set_status(f"Deleted: {self.session_id}")
            self._new_chat()
            self._load_sessions()
        else:
            self._set_status("This chat has not been stored locally.")

    def _show_privacy(self) -> None:
        lines = [self.consent.summary(), "", f"Retention: {settings.retention_days} day(s)", f"Data location: {settings.data_root}"]
        messagebox.showinfo("Privacy controls", "\n".join(lines), parent=self.root)

    def _report_unsafe_response(self) -> None:
        record_safety_event("user-report", source="gui")
        messagebox.showinfo("Unsafe response reported", "A local, content-free safety event was recorded. No conversation text was sent anywhere.", parent=self.root)

    def _request_initial_consents(self) -> None:
        requests = []
        if settings.store_conversations:
            requests.append("local_storage")
        if settings.index_conversations:
            requests.append("conversation_indexing")
        if settings.index_knowledge:
            requests.append("knowledge_indexing")
        if settings.allow_remote_backends and (
            not is_local_endpoint(settings.chat_backend.base_url)
            or not is_local_endpoint(settings.embedding_backend.base_url)
        ):
            requests.append("remote_backend")
        for purpose in requests:
            if self.consent.granted(purpose):
                continue
            accepted = messagebox.askyesno(
                "Privacy choice",
                f"Allow the app to {PURPOSES[purpose]}?\n\nYou can review this later in Privacy.",
                parent=self.root,
            )
            if accepted:
                self.consent.grant(purpose)
            elif purpose == "remote_backend":
                raise PermissionError("A remote backend cannot be used without explicit consent.")

    def _assess_evidence(self) -> None:
        if self.busy:
            return
        question = self.input.get("1.0", tk.END).strip()
        if not question:
            messagebox.showinfo("Evidence assessment", "Enter the claim or research question in the message box first.", parent=self.root)
            return
        self.input.delete("1.0", tk.END)
        self._set_busy(True)
        self._set_status("Researching and assessing evidence locally…")
        self.worker = AssessmentWorker(question, self.results, self.consent)
        self.worker.start()
        self.root.after(50, self._poll_worker)

    def _send_on_enter(self, event: tk.Event) -> str | None:
        if event.state & 0x0001:  # Shift+Enter inserts a newline.
            return None
        self._send()
        return "break"

    def _send(self) -> None:
        text = self.input.get("1.0", tk.END).strip()
        if not text or self.busy:
            return
        self.input.delete("1.0", tk.END)
        self.turns.append({"role": "user", "content": text})
        append_turn(self.session_id, "user", text, consent=self.consent)
        self._render_transcript()
        self._set_busy(True)
        self._set_status("Thinking locally…")
        self.worker = Worker(list(self.turns), self.results, self.consent)
        self.worker.start()
        self.root.after(50, self._poll_worker)

    def _poll_worker(self) -> None:
        try:
            kind, value, result = self.results.get_nowait()
        except queue.Empty:
            if self.busy:
                self.root.after(50, self._poll_worker)
            return

        try:
            if kind == "finished":
                self.turns.append({"role": "assistant", "content": value})
                append_turn(self.session_id, "assistant", value, consent=self.consent)
                if settings.index_conversations and self.consent.granted("conversation_indexing"):
                    self.agent.rag.add_conversation(self.session_id, self.turns[-settings.history_context_turns :])
                self._render_transcript()
                self._set_status(f"Ready • {settings.chat_model}")
            elif kind == "evidence":
                self.turns.append({"role": "assistant", "content": value})
                append_turn(self.session_id, "evidence", value, consent=self.consent, sensitivity="public-research")
                self._render_transcript()
                self._set_status(f"Evidence assessment ready • {settings.chat_model}")
            else:
                self._append_error(value)
                self._set_status("Error — see transcript")
        except Exception as exc:
            self._append_error(f"{type(exc).__name__}: {exc}")
            self._set_status("Error — see transcript")
        finally:
            self.worker = None
            self._set_busy(False)
            self.input.focus_set()


def run_gui() -> int:
    root = tk.Tk()
    MainWindow(root)
    root.mainloop()
    return 0
