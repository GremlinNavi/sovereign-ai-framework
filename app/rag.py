# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

import json
import math
import re
import sqlite3
import threading
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from .backends import Backend
from .config import settings

@dataclass
class Chunk:
    source: str
    source_id: str
    text: str
    metadata: dict
    embedding: list[float]


def normalize_text(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def chunk_text(text: str, size: int | None = None, overlap: int | None = None) -> list[str]:
    text = normalize_text(text)
    size = size or settings.chunk_chars
    overlap = overlap if overlap is not None else settings.chunk_overlap
    if not text:
        return []
    if overlap >= size:
        raise ValueError("RAG_CHUNK_OVERLAP must be smaller than RAG_CHUNK_CHARS")
    chunks = []
    start = 0
    while start < len(text):
        end = min(len(text), start + size)
        if end < len(text):
            boundary = text.rfind(" ", start, end)
            if boundary > start + size // 2:
                end = boundary
        chunks.append(text[start:end].strip())
        if end >= len(text):
            break
        start = max(end - overlap, start + 1)
    return [c for c in chunks if c]


def cosine(a: list[float], b: list[float]) -> float:
    if not a or not b or len(a) != len(b):
        return -1.0
    dot = sum(x * y for x, y in zip(a, b))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(y * y for y in b))
    return dot / (na * nb) if na and nb else -1.0


class LocalRAG:
    """Small dependency-light vector store using the configured embedding backend."""

    def __init__(self, backend: Backend):
        self.backend = backend
        # A LocalRAG instance may be used by the GUI thread and a worker thread.
        # sqlite3 connections are deliberately thread-affine, so never retain a
        # connection on the instance itself. Each thread gets its own connection.
        self._connections = threading.local()
        self._schema_lock = threading.Lock()
        self._initialize_database()

    def _connect(self) -> sqlite3.Connection:
        connection = sqlite3.connect(settings.index_path, timeout=30.0)
        connection.execute("PRAGMA busy_timeout = 30000")
        return connection

    def _initialize_database(self) -> None:
        """Create the shared schema without retaining a cross-thread connection."""
        with self._schema_lock:
            connection = self._connect()
            try:
                # WAL allows readers to proceed while another thread writes. SQLite
                # still serializes writes, and busy_timeout lets a brief write wait
                # instead of failing with "database is locked".
                connection.execute("PRAGMA journal_mode = WAL")
                connection.execute("""
                    CREATE TABLE IF NOT EXISTS chunks (
                        id INTEGER PRIMARY KEY,
                        source TEXT NOT NULL,
                        source_id TEXT NOT NULL,
                        text TEXT NOT NULL,
                        metadata TEXT NOT NULL,
                        embedding TEXT NOT NULL,
                        UNIQUE(source, source_id, text)
                    )
                """)
                connection.commit()
            finally:
                connection.close()

    def _connection(self) -> sqlite3.Connection:
        """Return the calling thread's SQLite connection."""
        connection = getattr(self._connections, "connection", None)
        if connection is None:
            connection = self._connect()
            self._connections.connection = connection
        return connection

    def close(self) -> None:
        """Close this thread's connection, if it has opened one."""
        connection = getattr(self._connections, "connection", None)
        if connection is not None:
            connection.close()
            del self._connections.connection

    def embed(self, texts: str | list[str]) -> list[float] | list[list[float]]:
        self.backend.capabilities().require("embeddings")
        embeddings = self.backend.embed(model=settings.embedding_model, texts=texts)
        return embeddings[0] if isinstance(texts, str) else embeddings

    def add(self, source: str, source_id: str, text: str, metadata: dict | None = None) -> int:
        chunks = chunk_text(text)
        if not chunks:
            return 0
        embeddings = self.embed(chunks)
        inserted = 0
        with self._connection() as connection:
            for chunk, embedding in zip(chunks, embeddings):
                cur = connection.execute(
                    "INSERT OR IGNORE INTO chunks(source, source_id, text, metadata, embedding) VALUES (?, ?, ?, ?, ?)",
                    (source, source_id, chunk, json.dumps(metadata or {}), json.dumps(embedding)),
                )
                inserted += cur.rowcount
        return inserted

    def add_conversation(self, session_id: str, turns: Iterable[dict]) -> int:
        text_parts = []
        for turn in turns:
            role = turn.get("role", "unknown")
            content = turn.get("content", "").strip()
            if content and role in {"user", "assistant", "tool"}:
                text_parts.append(f"{role}: {content}")
        return self.add(
            source="conversation",
            source_id=session_id,
            text="\n".join(text_parts),
            metadata={"session_id": session_id},
        )

    def delete_source(self, source: str, source_id: str) -> int:
        """Remove all derived chunks for a source after a deletion request."""
        with self._connection() as connection:
            cursor = connection.execute(
                "DELETE FROM chunks WHERE source = ? AND source_id = ?", (source, source_id)
            )
        return cursor.rowcount

    def search(self, query: str, top_k: int | None = None, sources: set[str] | None = None) -> list[Chunk]:
        top_k = top_k or settings.top_k
        q = self.embed(query)
        rows = self._connection().execute(
            "SELECT source, source_id, text, metadata, embedding FROM chunks"
        ).fetchall()
        scored = []
        for source, source_id, text, metadata, embedding_json in rows:
            if sources and source not in sources:
                continue
            score = cosine(q, json.loads(embedding_json))
            scored.append((score, Chunk(source, source_id, text, json.loads(metadata), json.loads(embedding_json))))
        scored.sort(key=lambda x: x[0], reverse=True)
        return [chunk for score, chunk in scored[:top_k] if score > 0]

    def ingest_directory(self, directory: Path) -> int:
        total = 0
        for path in directory.rglob("*"):
            if not path.is_file() or path.name.startswith("."):
                continue
            if path.suffix.lower() not in {".txt", ".md", ".json", ".jsonl"}:
                continue
            text = path.read_text(encoding="utf-8", errors="ignore")
            total += self.add("knowledge", str(path.relative_to(directory)), text, {"path": str(path)})
        return total
