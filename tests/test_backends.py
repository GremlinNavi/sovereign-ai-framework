# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

from types import SimpleNamespace

import pytest

from app.backends import BackendCapabilities, BackendCapabilityError, BackendUnavailableError, ChatResponse
from app.backends.ollama import OllamaBackend
from app.config import BackendConfig


class FakeOllamaClient:
    def __init__(self, fail: bool = False):
        self.fail = fail

    def list(self):
        if self.fail:
            raise ConnectionError("offline")
        return SimpleNamespace(models=[SimpleNamespace(model="chat"), SimpleNamespace(model="embed")])

    def embed(self, *, model, input):
        values = [input] if isinstance(input, str) else input
        return SimpleNamespace(embeddings=[[1.0, 0.0] for _ in values])

    def chat(self, **_kwargs):
        return SimpleNamespace(message=SimpleNamespace(content="ok", tool_calls=[]))


def _ollama_config() -> BackendConfig:
    return BackendConfig("ollama", "http://127.0.0.1:11434", "chat", "embed", capabilities=frozenset({"chat", "embeddings", "tool_calling", "structured_output"}))


def test_ollama_adapter_normalizes_chat_embeddings_and_models():
    backend = OllamaBackend("ollama", _ollama_config(), 1)
    backend._client = FakeOllamaClient()
    assert backend.list_models() == ["chat", "embed"]
    assert backend.embed(model="embed", texts="hello") == [[1.0, 0.0]]
    assert backend.chat(model="chat", messages=[{"role": "user", "content": "hello"}]).content == "ok"
    assert backend.capabilities().tool_calling is True



def test_missing_ollama_python_client_fails_cleanly(monkeypatch):
    import app.backends.ollama as ollama_module

    monkeypatch.setattr(ollama_module, "OllamaClient", None)
    backend = ollama_module.OllamaBackend("ollama", _ollama_config(), 1)
    with pytest.raises(BackendUnavailableError, match="Ollama Python client is not installed"):
        backend.health_check()

def test_unavailable_backend_has_a_clear_error():
    backend = OllamaBackend("ollama", _ollama_config(), 1)
    backend._client = FakeOllamaClient(fail=True)
    with pytest.raises(BackendUnavailableError, match="unavailable"):
        backend.health_check()


def test_capability_detection_fails_gracefully():
    capabilities = BackendCapabilities(chat=True, embeddings=True)
    with pytest.raises(BackendCapabilityError, match="structured_output"):
        capabilities.require("chat", "structured_output")


def test_agent_selects_chat_and_embedding_backends(monkeypatch):
    import app.agent as agent_module

    selected = []
    class FakeBackend:
        def capabilities(self): return BackendCapabilities(chat=True, embeddings=True, tool_calling=True, structured_output=True)
        def chat(self, **_kwargs): return ChatResponse(content="")
        def embed(self, *, model, texts): return [[1.0] for _ in ([texts] if isinstance(texts, str) else texts)]
        def health_check(self): return None
        def list_models(self): return []

    monkeypatch.setattr(agent_module, "create_backend", lambda name: selected.append(name) or FakeBackend())
    monkeypatch.setattr(agent_module, "settings", SimpleNamespace(chat_backend_name="chat-host", embedding_backend_name="embed-host", max_tool_calls_per_turn=1))
    instance = agent_module.Agent()
    assert selected == ["chat-host", "embed-host"]
    assert instance.chat_backend is not instance.embedding_backend
