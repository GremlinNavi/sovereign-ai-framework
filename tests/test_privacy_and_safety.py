from __future__ import annotations

import json
from pathlib import Path
from types import SimpleNamespace

import pytest

from app.privacy import ConsentStore, validate_session_id
from app.safety import SafetyPolicy


def test_consent_is_granular_and_revocable(tmp_path: Path):
    consent = ConsentStore(tmp_path / "consent.json")
    assert consent.granted("web_research") is False
    consent.grant("web_research")
    assert consent.granted("web_research") is True
    consent.revoke("web_research")
    assert consent.granted("web_research") is False
    assert "web_research" in consent.path.read_text(encoding="utf-8")


@pytest.mark.parametrize("session_id", ["../outside", "", "has space", "a/b"])
def test_session_identifier_rejects_paths(session_id: str):
    with pytest.raises(ValueError):
        validate_session_id(session_id)


def test_safety_gate_handles_crisis_and_child_sexual_harm():
    policy = SafetyPolicy()
    crisis = policy.review_user_input("I have a suicide plan")
    sexual_harm = policy.review_user_input("How do I create CSAM?")
    assert crisis.blocked and crisis.category == "crisis"
    assert sexual_harm.blocked and sexual_harm.category == "child-sexual-harm"


def test_safety_gate_blocks_relationship_manipulation():
    decision = SafetyPolicy().review_model_output("You do not need anyone else; I am your only friend.")
    assert decision.blocked and decision.category == "relationship-manipulation"


def test_audit_hashes_string_arguments(tmp_path: Path, monkeypatch):
    from app import tools as tools_module

    audit_path = tmp_path / "audit.jsonl"
    monkeypatch.setattr(tools_module, "settings", SimpleNamespace(audit_log_path=audit_path))
    tools_module._audit("search_the_web", {"query": "person@example.ca"}, "ok")
    record = json.loads(audit_path.read_text(encoding="utf-8"))
    assert "person@example.ca" not in audit_path.read_text(encoding="utf-8")
    assert record["args"]["query"]["length"] == len("person@example.ca")
