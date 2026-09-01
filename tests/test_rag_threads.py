# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

import threading
from pathlib import Path
from types import SimpleNamespace

import app.rag as rag_module
from app.backends import BackendCapabilities, ChatResponse


class FakeBackend:
    name = "fake"

    def capabilities(self):
        return BackendCapabilities(chat=True, embeddings=True)

    def health_check(self):
        return None

    def list_models(self):
        return ["test-embed"]

    def chat(self, **_kwargs):
        return ChatResponse(content="")

    def embed(self, *, model: str, texts: str | list[str]):
        values = [texts] if isinstance(texts, str) else texts
        return [[1.0, 0.0] for _ in values]


def test_rag_uses_a_distinct_connection_per_thread(monkeypatch, tmp_path: Path):
    monkeypatch.setattr(
        rag_module,
        "settings",
        SimpleNamespace(
            index_path=tmp_path / "index.sqlite3",
            chunk_chars=1200,
            chunk_overlap=200,
            embedding_model="test-embed",
            top_k=6,
        ),
    )
    rag = rag_module.LocalRAG(FakeBackend())
    gui_connection_id = id(rag._connection())
    worker_connection_ids: list[int] = []
    worker_errors: list[Exception] = []

    def use_rag_from_worker() -> None:
        try:
            worker_connection_ids.append(id(rag._connection()))
            rag.add("knowledge", "worker.txt", "thread-local SQLite regression coverage")
            assert rag.search("SQLite")
            rag.close()
        except Exception as exc:  # pragma: no cover - surfaced below
            worker_errors.append(exc)

    worker = threading.Thread(target=use_rag_from_worker)
    worker.start()
    worker.join()

    assert not worker_errors
    assert len(worker_connection_ids) == 1
    assert worker_connection_ids[0] != gui_connection_id
    assert rag.search("SQLite")
    rag.close()
