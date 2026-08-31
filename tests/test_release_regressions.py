from __future__ import annotations

from pathlib import Path
from types import SimpleNamespace


def test_dotenv_loader_preserves_explicit_environment(tmp_path: Path, monkeypatch):
    import config

    dotenv = tmp_path / ".env"
    dotenv.write_text("ONE=from-file\nTWO='quoted value'\n", encoding="utf-8")
    monkeypatch.setenv("ONE", "from-shell")
    monkeypatch.delenv("TWO", raising=False)
    config._load_dotenv(dotenv)
    assert config.os.environ["ONE"] == "from-shell"
    assert config.os.environ["TWO"] == "quoted value"


def test_openai_compatible_adapter_supplies_missing_tool_call_id():
    from app.backends.openai_compatible import OpenAICompatibleBackend

    converted = OpenAICompatibleBackend._messages([
        {
            "role": "assistant",
            "content": "",
            "tool_calls": [{"name": "search_the_web", "arguments": {"query": "test"}}],
        }
    ])
    assert converted[0]["tool_calls"][0]["id"] == "local-tool-call-1"


def test_failed_web_search_is_audited(tmp_path: Path, monkeypatch):
    from app import tools as tools_module

    audit_path = tmp_path / "audit.jsonl"
    monkeypatch.setattr(tools_module, "settings", SimpleNamespace(audit_log_path=audit_path))
    monkeypatch.setattr(tools_module, "search_web", lambda _query: (_ for _ in ()).throw(ValueError("blocked")))
    search = tools_module.make_tools(object())["search_the_web"]
    try:
        search("test")
    except ValueError:
        pass
    else:  # pragma: no cover - makes the intended failure explicit
        raise AssertionError("search should propagate its failure")
    assert '"status": "error:ValueError"' in audit_path.read_text(encoding="utf-8")
