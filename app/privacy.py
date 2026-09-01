# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

"""Consent, retention, access and deletion controls for local application data.

This module intentionally stores only the user's choices and operational metadata.
It never stores a copy of a conversation in the consent or safety records.
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Callable

from .config import settings


class ConsentRequiredError(PermissionError):
    """Raised when an optional data-processing purpose lacks explicit consent."""


PURPOSES = {
    "local_storage": "save conversation records on this device",
    "conversation_indexing": "embed conversation records for retrieval in later chats",
    "knowledge_indexing": "embed files in the local knowledge directory",
    "web_research": "send search queries and page requests to public websites",
    "remote_backend": "send prompts and embeddings to a non-local AI endpoint",
}

_SESSION_ID = re.compile(r"[A-Za-z0-9][A-Za-z0-9_-]{0,127}\Z")


def validate_session_id(session_id: str) -> str:
    """Reject path traversal and malformed session identifiers."""
    if not _SESSION_ID.fullmatch(session_id):
        raise ValueError("Session IDs may contain only letters, numbers, underscores and hyphens")
    return session_id


class ConsentStore:
    """Persist granular, revocable consent without recording prompt content."""

    version = 1

    def __init__(self, path: Path | None = None) -> None:
        self.path = path or settings.consent_path

    def _read(self) -> dict:
        if not self.path.is_file():
            return {"version": self.version, "purposes": {}}
        try:
            data = json.loads(self.path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return {"version": self.version, "purposes": {}}
        return data if isinstance(data, dict) else {"version": self.version, "purposes": {}}

    def _write(self, data: dict) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    def granted(self, purpose: str) -> bool:
        if purpose not in PURPOSES:
            raise ValueError(f"Unknown consent purpose: {purpose}")
        return bool(self._read().get("purposes", {}).get(purpose, {}).get("granted"))

    def grant(self, purpose: str) -> None:
        if purpose not in PURPOSES:
            raise ValueError(f"Unknown consent purpose: {purpose}")
        data = self._read()
        data["version"] = self.version
        data.setdefault("purposes", {})[purpose] = {
            "granted": True,
            "granted_at": datetime.now(timezone.utc).isoformat(),
        }
        self._write(data)

    def revoke(self, purpose: str) -> None:
        if purpose not in PURPOSES:
            raise ValueError(f"Unknown consent purpose: {purpose}")
        data = self._read()
        data.setdefault("purposes", {})[purpose] = {
            "granted": False,
            "revoked_at": datetime.now(timezone.utc).isoformat(),
        }
        self._write(data)

    def require(self, purpose: str) -> None:
        if not self.granted(purpose):
            raise ConsentRequiredError(
                f"{PURPOSES[purpose].capitalize()} requires explicit consent. "
                f"Use /consent {purpose} or configure it in the desktop privacy dialog."
            )

    def prompt_for(self, purpose: str, ask: Callable[[str], str] = input) -> bool:
        """Request a concise, local command-line consent decision."""
        if self.granted(purpose):
            return True
        answer = ask(f"Allow the app to {PURPOSES[purpose]}? [y/N] ").strip().lower()
        if answer in {"y", "yes"}:
            self.grant(purpose)
            return True
        return False

    def summary(self) -> str:
        return "\n".join(
            f"{purpose}: {'granted' if self.granted(purpose) else 'not granted'} — {description}"
            for purpose, description in PURPOSES.items()
        )


def _session_timestamp(path: Path) -> datetime | None:
    """Read the most recent record timestamp without retaining its content."""
    latest: datetime | None = None
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return None
    for line in lines:
        try:
            timestamp = json.loads(line).get("timestamp")
            value = datetime.fromisoformat(timestamp.replace("Z", "+00:00")) if timestamp else None
        except (TypeError, ValueError, json.JSONDecodeError):
            continue
        if value and (latest is None or value > latest):
            latest = value
    return latest


def expired_session_ids(now: datetime | None = None) -> list[str]:
    """List stored sessions that have passed the configured retention period."""
    now = now or datetime.now(timezone.utc)
    cutoff = now - timedelta(days=settings.retention_days)
    expired = []
    for path in settings.history_dir.glob("*.jsonl"):
        timestamp = _session_timestamp(path)
        if timestamp and timestamp < cutoff:
            expired.append(validate_session_id(path.stem))
    return expired


def delete_session(session_id: str, rag: object | None = None) -> bool:
    """Delete a session record and its derived RAG chunks when available."""
    session_id = validate_session_id(session_id)
    path = settings.history_dir / f"{session_id}.jsonl"
    existed = path.is_file()
    if existed:
        path.unlink()
    if rag is not None and hasattr(rag, "delete_source"):
        rag.delete_source("conversation", session_id)
    return existed


def purge_expired_sessions(rag: object | None = None) -> list[str]:
    purged = []
    for session_id in expired_session_ids():
        delete_session(session_id, rag)
        purged.append(session_id)
    return purged


def export_personal_data(destination: Path) -> Path:
    """Export all locally stored user records in a portable JSON document."""
    sessions: dict[str, list[dict]] = {}
    for path in settings.history_dir.glob("*.jsonl"):
        records = []
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.strip():
                records.append(json.loads(line))
        sessions[validate_session_id(path.stem)] = records

    def read_records(path: Path) -> list[dict]:
        if not path.is_file():
            return []
        return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]

    payload = {
        "format": "eternal-thread-personal-data-v1",
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "sessions": sessions,
        "tool_audit": read_records(settings.audit_log_path),
        "safety_events": read_records(settings.safety_log_path),
        "consent": ConsentStore()._read(),
        "retention_days": settings.retention_days,
        "note": "The SQLite retrieval index contains derived chunks for these records and is removed by /delete-session or /delete-all-data.",
    }
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return destination


def delete_all_local_data(rag: object | None = None, *, include_knowledge: bool = False) -> None:
    """Delete known application data only; knowledge files require an explicit opt-in."""
    if rag is not None and hasattr(rag, "close"):
        rag.close()
    for path in settings.history_dir.glob("*.jsonl"):
        path.unlink()
    for path in (
        settings.audit_log_path,
        settings.safety_log_path,
        settings.index_path,
        settings.index_path.with_name(settings.index_path.name + "-shm"),
        settings.index_path.with_name(settings.index_path.name + "-wal"),
        settings.consent_path,
    ):
        if path.is_file():
            path.unlink()
    if include_knowledge:
        for path in settings.knowledge_dir.rglob("*"):
            if path.is_file():
                path.unlink()
