from __future__ import annotations

import json
from pathlib import Path

from .config import settings


def _private_record(record: dict) -> bool:
    return bool(record.get("private") or record.get("sensitivity") == "confidential")


def export_session_txt(session_id: str, destination: Path, *, include_confidential: bool = False) -> Path:
    path = settings.history_dir / f"{session_id}.jsonl"
    records = []
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.strip():
                records.append(json.loads(line))
    lines = [
        "SOVEREIGN AI DEMONSTRATOR",
        "RESEARCH CONVERSATION EXPORT",
        "=============================",
        "",
        f"Conversation ID: {session_id}",
        "",
    ]
    for record in records:
        if _private_record(record) and not include_confidential:
            lines.extend(["[CONFIDENTIAL CONTENT OMITTED FROM EXPORT]", ""])
            continue
        role = str(record.get("role", "unknown")).upper()
        timestamp = record.get("timestamp", "")
        if role == "EVIDENCE":
            lines.extend([
                "[EVIDENCE ASSESSMENT]",
                f"Timestamp: {timestamp}",
                str(record.get("content", "")),
                "",
            ])
        else:
            lines.extend([
                f"[{role}]",
                f"Timestamp: {timestamp}",
                str(record.get("content", "")),
                "",
            ])
    lines.extend(["END OF SOVEREIGN AI DEMONSTRATOR EXPORT", ""])
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    return destination


def format_evidence_assessment(assessment: object) -> str:
    data = assessment.to_dict() if hasattr(assessment, "to_dict") else assessment
    lines = [
        "OVERALL CONFIDENCE: {0}%".format(data["overall_confidence"]),
        "EVENT CONFIDENCE: {0}%".format(data["event_confidence"]),
        "LEGAL CONFIDENCE: {0}%".format(data["legal_confidence"]),
        "ATTRIBUTION CONFIDENCE: {0}%".format(data["attribution_confidence"]),
        "HUMAN REVIEW REQUIRED: YES",
        "",
        "SUMMARY:",
        data["summary"],
        "",
    ]
    if data.get("claims"):
        lines.append("CLAIMS:")
        for claim in data["claims"]:
            lines.append(f"[{claim['claim_id']}] {claim['claim']}")
            lines.append(f"Assessment: {claim['assessment']}")
            lines.append(f"Confidence: {claim['confidence']}%")
            if claim["supporting_sources"]:
                lines.append("Supporting sources: " + ", ".join(claim["supporting_sources"]))
            if claim["contradicting_sources"]:
                lines.append("Contradicting sources: " + ", ".join(claim["contradicting_sources"]))
            for caveat in claim["caveats"]:
                lines.append(f"Caveat: {caveat}")
            lines.append("")
    if data.get("sources"):
        lines.append("SOURCES:")
        for source in data["sources"]:
            lines.append(f"[{source['source_id']}] {source['title']}")
            lines.append(f"Type: {source['source_type']}")
            if source["publisher"]:
                lines.append(f"Publisher: {source['publisher']}")
            if source["url"]:
                lines.append(f"URL: {source['url']}")
            if source["retrieved_at"]:
                lines.append(f"Retrieved: {source['retrieved_at']}")
            if source["notes"]:
                lines.append(f"Notes: {source['notes']}")
            lines.append("")
    if data.get("conflicts"):
        lines.append("CONFLICTS / CONTRADICTIONS:")
        lines.extend(f"- {item}" for item in data["conflicts"])
        lines.append("")
    if data.get("evidence_gaps"):
        lines.append("EVIDENCE GAPS:")
        lines.extend(f"- {item}" for item in data["evidence_gaps"])
    return "\n".join(lines).strip()
