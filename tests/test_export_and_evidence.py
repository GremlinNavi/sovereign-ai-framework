# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

import json
from pathlib import Path
from types import SimpleNamespace


def test_export_omits_confidential_records(tmp_path: Path, monkeypatch):
    from app import export as export_module

    history = tmp_path / "sessions"
    history.mkdir()
    monkeypatch.setattr(export_module, "settings", SimpleNamespace(history_dir=history))
    session_id = "20260831-test"
    path = history / f"{session_id}.jsonl"
    path.write_text(
        json.dumps({"timestamp": "t1", "role": "user", "content": "hello"}) + "\n"
        + json.dumps({"timestamp": "t2", "role": "evidence", "content": "public finding", "sensitivity": "public-research"}) + "\n"
        + json.dumps({"timestamp": "t3", "role": "assistant", "content": "secret source identity", "private": True}) + "\n",
        encoding="utf-8",
    )
    destination = tmp_path / "export.txt"
    export_module.export_session_txt(session_id, destination)
    text = destination.read_text(encoding="utf-8")
    assert "hello" in text
    assert "public finding" in text
    assert "secret source identity" not in text
    assert "CONFIDENTIAL CONTENT OMITTED" in text


def test_assessment_scores_are_clamped():
    from app.research import normalize_assessment

    result = normalize_assessment({
        "overall_confidence": 150,
        "event_confidence": -5,
        "legal_confidence": "70",
        "attribution_confidence": "not-a-number",
        "summary": "test",
        "claims": [],
        "sources": [],
        "conflicts": [],
        "evidence_gaps": [],
    })
    assert result.overall_confidence == 100
    assert result.event_confidence == 0
    assert result.legal_confidence == 70
    assert result.attribution_confidence == 0


def test_publication_requires_explicit_human_review():
    from app.research import EvidenceAssessment, can_publish

    assessment = EvidenceAssessment(
        overall_confidence=90,
        event_confidence=95,
        legal_confidence=80,
        attribution_confidence=85,
        summary="test",
    )
    assert can_publish(assessment) is False
    assert can_publish(assessment, human_review_complete=True) is True
