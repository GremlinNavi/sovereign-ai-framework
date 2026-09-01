# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

from dataclasses import replace
from types import SimpleNamespace

from app.backends import BackendUnavailableError
from app.config import BackendConfig


def _configured_settings():
    import config

    return replace(
        config.settings,
        chat_backend_name="chat-test",
        embedding_backend_name="embedding-test",
        chat_backend=BackendConfig("test", "http://127.0.0.1:8111", "chat-model", "", capabilities=frozenset({"chat"})),
        embedding_backend=BackendConfig("test", "http://127.0.0.1:8222", "", "embedding-model", capabilities=frozenset({"embeddings"})),
        chat_model="chat-model",
        embedding_model="embedding-model",
    )


def test_health_check_reports_each_unavailable_role_without_traceback(capsys):
    import config

    class OfflineBackend:
        def list_models(self):
            raise BackendUnavailableError("offline")

    result = config.health_check_configured_backends(
        _configured_settings(), create_backend_fn=lambda _name: OfflineBackend()
    )

    output = capsys.readouterr().out
    assert result == 1
    assert "Chat backend 'chat-test'" in output
    assert "Embedding backend 'embedding-test'" in output
    assert "No alternative backend was used." in output
    assert "Traceback" not in output


def test_health_check_identifies_the_role_with_a_missing_model(capsys):
    import config

    class ReachableBackend:
        def __init__(self, models):
            self.models = models

        def list_models(self):
            return self.models

    backends = {
        "chat-test": ReachableBackend(["chat-model"]),
        "embedding-test": ReachableBackend([]),
    }
    result = config.health_check_configured_backends(
        _configured_settings(), create_backend_fn=lambda name: backends[name]
    )

    output = capsys.readouterr().out
    assert result == 1
    assert "Embedding backend 'embedding-test'" in output
    assert "does not list configured model 'embedding-model'" in output
    assert "Chat backend 'chat-test' at" not in output
    assert "Traceback" not in output


def test_frozen_build_uses_dotenv_next_to_the_executable(monkeypatch, tmp_path):
    import config

    executable = tmp_path / "EternalThread.exe"
    (tmp_path / ".env").write_text("ETERNAL_THREAD_TEST_FROM_DOTENV=external\n", encoding="utf-8")
    monkeypatch.setattr(config.sys, "frozen", True, raising=False)
    monkeypatch.setattr(config.sys, "executable", str(executable))
    monkeypatch.delenv("ETERNAL_THREAD_TEST_FROM_DOTENV", raising=False)

    assert config._configuration_root() == tmp_path
    config._load_dotenv(config._configuration_root() / ".env")
    assert config.os.environ["ETERNAL_THREAD_TEST_FROM_DOTENV"] == "external"


def test_cli_recovers_when_the_selected_embedding_backend_is_unavailable(monkeypatch, capsys):
    import app.main as main

    configured = _configured_settings()

    class OfflineBackend:
        def health_check(self):
            raise BackendUnavailableError("offline")

    class FakeAgent:
        def __init__(self, _consent):
            self.embedding_backend = OfflineBackend()
            self.chat_backend = OfflineBackend()
            self.rag = SimpleNamespace()

        def chat(self, _turns):
            raise AssertionError("A user request must not be sent after a failed backend preflight")

    responses = iter(["hello", "/exit"])
    monkeypatch.setattr(main, "settings", configured)
    monkeypatch.setattr(main, "ConsentStore", lambda: object())
    monkeypatch.setattr(main, "_consent_for_configured_features", lambda _consent: True)
    monkeypatch.setattr(main, "Agent", FakeAgent)
    monkeypatch.setattr(main, "purge_expired_sessions", lambda _rag: [])
    monkeypatch.setattr(main, "load_turns", lambda *_args, **_kwargs: [])
    monkeypatch.setattr(main, "append_turn", lambda *_args, **_kwargs: None)
    monkeypatch.setattr(main.sys, "argv", ["main.py"])
    monkeypatch.setattr("builtins.input", lambda _prompt: next(responses))

    assert main.main() == 0
    output = capsys.readouterr().out
    assert "Embedding backend 'embedding-test'" in output
    assert "No alternative backend was used." in output
    assert "Traceback" not in output
