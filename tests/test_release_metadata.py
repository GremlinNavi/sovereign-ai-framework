# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_release_candidate_metadata_is_consistent():
    pyproject = (ROOT / "pyproject.toml").read_text(encoding="utf-8")
    citation = (ROOT / "CITATION.cff").read_text(encoding="utf-8")
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    checklist = (ROOT / "RELEASE_CHECKLIST.md").read_text(encoding="utf-8")

    assert 'version = "0.4.0rc4"' in pyproject
    assert "version: 0.4.0-rc4" in citation
    assert "v0.4.0-rc4" in readme
    assert "v0.4.0-rc4" in checklist
    assert "pre-release" in readme.lower()


def test_public_title_is_consistent_across_primary_metadata():
    canonical_title = "Eternal Thread — Sovereign AI Demonstrator"
    for filename in ("README.md", "BRANDING.md", "CITATION.cff", "NOTICE"):
        assert canonical_title in (ROOT / filename).read_text(encoding="utf-8")


def test_inspiration_record_is_utf8_and_scopes_its_claims():
    record = (ROOT / "INSPIRATION_AND_DESIGN_LINEAGE.txt").read_text(encoding="utf-8")

    assert record.startswith("CREATOR INSPIRATION RECORD\n")
    assert "Eternal Thread — Sovereign AI Demonstrator" in record
    assert "not a technical specification" in record
    assert "not a claim that the framework is sentient" in record


def test_upstream_references_cover_default_model_and_runtime():
    references = (ROOT / "UPSTREAM_REFERENCES.md").read_text(encoding="utf-8")

    assert "https://github.com/ollama/ollama" in references
    assert "https://huggingface.co/Qwen/Qwen3-4B" in references
    assert "https://huggingface.co/nomic-ai/nomic-embed-text-v1.5" in references
    assert "Rebuild the local retrieval index" in references


def test_release_docs_keep_compliance_claims_bounded():
    alignment = (ROOT / "REGULATORY_ALIGNMENT.md").read_text(encoding="utf-8").lower()
    security = (ROOT / "SECURITY.md").read_text(encoding="utf-8").lower()

    assert "not legal advice" in alignment
    assert "not" in alignment and "certification" in alignment
    assert "private vulnerability reporting" in security
    assert "do not post active exploit details" in security
