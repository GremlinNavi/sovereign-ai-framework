# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

import json
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path

from .agent import Agent
from .backends import BackendUnavailableError
from .export import export_session_txt, format_evidence_assessment
from .config import backend_unavailable_message, settings
from .privacy import (
    PURPOSES,
    ConsentStore,
    delete_all_local_data,
    delete_session,
    export_personal_data,
    purge_expired_sessions,
    validate_session_id,
)


def session_path(session_id: str) -> Path:
    session_id = validate_session_id(session_id)
    return settings.history_dir / f"{session_id}.jsonl"


def append_turn(session_id: str, role: str, content: str, *, consent: ConsentStore | None = None, **metadata: object) -> None:
    if not settings.store_conversations or consent is None or not consent.granted("local_storage"):
        return
    record = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "role": role,
        "content": content,
        **metadata,
    }
    with session_path(session_id).open("a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")


def load_turns(session_id: str, *, consent: ConsentStore | None = None) -> list[dict]:
    if not settings.store_conversations or consent is None or not consent.granted("local_storage"):
        return []
    path = session_path(session_id)
    if not path.exists():
        return []
    turns = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            turns.append(json.loads(line))
    return turns


def _index_conversation_if_permitted(agent: Agent, consent: ConsentStore, session_id: str, turns: list[dict]) -> int:
    if not settings.index_conversations or not consent.granted("conversation_indexing"):
        return 0
    return agent.rag.add_conversation(session_id, turns[-settings.history_context_turns :])


def _consent_for_configured_features(consent: ConsentStore) -> bool:
    """Obtain an explicit first-use decision for enabled processing features."""
    required = []
    if settings.store_conversations:
        required.append("local_storage")
    if settings.index_conversations:
        required.append("conversation_indexing")
    if settings.index_knowledge:
        required.append("knowledge_indexing")
    if settings.allow_remote_backends:
        from .config import is_local_endpoint
        if not is_local_endpoint(settings.chat_backend.base_url) or not is_local_endpoint(settings.embedding_backend.base_url):
            required.append("remote_backend")
    for purpose in required:
        if not consent.prompt_for(purpose):
            if purpose == "local_storage":
                print("Conversation persistence is disabled for this session.")
                continue
            if purpose == "remote_backend":
                print("A remote backend cannot be used without explicit consent.")
                return False
            print(f"{PURPOSES[purpose].capitalize()} was not enabled.")
    return True


def _report_backend_unavailable(role: str, exc: BackendUnavailableError) -> None:
    print(backend_unavailable_message(role, settings, reason=str(exc)))
    print("No alternative backend was used. Run `python config.py --health-check` after updating the local runtime or configuration.")


def _required_backends_available(agent: Agent, *roles: str) -> bool:
    """Check each local dependency before sending a user request to the agent."""
    for role in roles:
        backend = agent.chat_backend if role == "chat" else agent.embedding_backend
        try:
            backend.health_check()
        except BackendUnavailableError as exc:
            _report_backend_unavailable(role, exc)
            return False
    return True


def _report_backend_unavailable_during_request() -> None:
    print("The configured chat or embedding backend became unavailable while processing the request.")
    print("No alternative backend was used. Run `python config.py --health-check` after updating the local runtime or configuration.")


def main() -> int:
    consent = ConsentStore()
    if not _consent_for_configured_features(consent):
        return 2
    agent = Agent(consent)
    purged = purge_expired_sessions(agent.rag)
    if purged:
        print(f"Purged {len(purged)} expired conversation record(s).")
    session_id = sys.argv[1] if len(sys.argv) > 1 else datetime.now().strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:6]
    session_id = validate_session_id(session_id)
    turns = load_turns(session_id, consent=consent)
    if turns:
        print(f"Resumed session: {session_id}")

    # Index local knowledge at startup. Duplicates are ignored by SQLite.
    if settings.index_knowledge and consent.granted("knowledge_indexing"):
        try:
            added = agent.rag.ingest_directory(settings.knowledge_dir)
            if added:
                print(f"Indexed {added} new knowledge chunks.")
        except BackendUnavailableError as exc:
            _report_backend_unavailable("embedding", exc)

    print(f"Eternal Thread — Sovereign AI Demonstrator — chat backend={settings.chat_backend_name}, model={settings.chat_model}")
    print("Commands: /exit, /session, /privacy, /consent <purpose>, /revoke <purpose>, /reindex, /export [path], /export-data [path], /delete-session [id], /delete-all-data, /assess <question>")
    while True:
        try:
            user = input("\nYou> ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break
        if not user:
            continue
        if user == "/exit":
            break
        if user == "/session":
            print(session_id)
            continue
        if user == "/privacy":
            print(consent.summary())
            print(f"Retention: {settings.retention_days} day(s); storage root: {settings.data_root}")
            continue
        if user.startswith("/consent "):
            purpose = user.split(maxsplit=1)[1].strip()
            if purpose not in PURPOSES:
                print("Unknown purpose. Use /privacy to list valid purposes.")
            else:
                consent.grant(purpose)
                print(f"Consent granted for {purpose}.")
            continue
        if user.startswith("/revoke "):
            purpose = user.split(maxsplit=1)[1].strip()
            if purpose not in PURPOSES:
                print("Unknown purpose. Use /privacy to list valid purposes.")
            else:
                consent.revoke(purpose)
                print(f"Consent revoked for {purpose}.")
            continue
        if user == "/reindex":
            if not settings.index_knowledge or not consent.granted("knowledge_indexing"):
                print("Knowledge indexing requires ETERNAL_THREAD_INDEX_KNOWLEDGE=1 and consent.")
            else:
                try:
                    print(f"Indexed {agent.rag.ingest_directory(settings.knowledge_dir)} new chunks.")
                except BackendUnavailableError as exc:
                    _report_backend_unavailable("embedding", exc)
            continue
        if user.startswith("/export-data"):
            parts = user.split(maxsplit=1)
            destination = Path(parts[1]) if len(parts) == 2 else Path("eternal-thread-personal-data.json")
            if not destination.is_absolute():
                destination = Path.cwd() / destination
            export_personal_data(destination)
            print(f"Exported all locally held data: {destination}")
            continue
        if user.startswith("/export"):
            parts = user.split(maxsplit=1)
            destination = Path(parts[1]) if len(parts) == 2 else Path(f"{session_id}.txt")
            if not destination.is_absolute():
                destination = Path.cwd() / destination
            export_session_txt(session_id, destination)
            print(f"Exported: {destination}")
            continue
        if user.startswith("/delete-session"):
            parts = user.split(maxsplit=1)
            target = parts[1].strip() if len(parts) == 2 else session_id
            if delete_session(target, agent.rag):
                print(f"Deleted session {target} and its retrieval chunks.")
                if target == session_id:
                    session_id = datetime.now().strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:6]
                    turns = []
            else:
                print(f"No stored session named {target}.")
            continue
        if user == "/delete-all-data":
            confirmation = input("This deletes conversation, audit, consent, safety, and index data. Type DELETE to continue: ")
            if confirmation == "DELETE":
                delete_all_local_data(agent.rag)
                print("Local application data deleted. Restart the app before continuing.")
                return 0
            print("Deletion cancelled.")
            continue
        if user.startswith("/assess "):
            question = user[8:].strip()
            if not question:
                print("Usage: /assess <question>")
                continue
            if not _required_backends_available(agent, "chat", "embedding"):
                continue
            try:
                assessment = agent.assess_evidence(question)
            except (PermissionError, ValueError) as exc:
                print(f"Assessment unavailable: {exc}")
                continue
            except BackendUnavailableError:
                _report_backend_unavailable_during_request()
                continue
            report = format_evidence_assessment(assessment)
            print("\n" + report)
            append_turn(session_id, "evidence", report, consent=consent, sensitivity="public-research")
            continue

        # A normal chat always needs an embedding backend for local retrieval
        # before it calls the selected chat backend.  Check both roles explicitly
        # so a missing external runtime never becomes a traceback or a fallback.
        if not _required_backends_available(agent, "embedding", "chat"):
            continue
        append_turn(session_id, "user", user, consent=consent)
        turns.append({"role": "user", "content": user})
        try:
            result = agent.chat(turns)
        except BackendUnavailableError:
            _report_backend_unavailable_during_request()
            continue
        answer = result["content"]
        print(f"\nAssistant> {answer}")
        append_turn(session_id, "assistant", answer, consent=consent)
        turns.append({"role": "assistant", "content": answer})
        # Embed the latest conversation into the local RAG store for future sessions.
        try:
            _index_conversation_if_permitted(agent, consent, session_id, turns)
        except BackendUnavailableError as exc:
            _report_backend_unavailable("embedding", exc)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
