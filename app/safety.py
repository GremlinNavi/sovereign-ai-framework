# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

"""Deterministic safety gates for a small set of high-risk chatbot interactions.

The policy is intentionally narrow. It normalizes superficial text variations,
blocks only clear high-risk signals, and augments rather than replaces model-level
evaluation and human review. Safety event records contain category metadata only.
"""
from __future__ import annotations

import json
import re
import unicodedata
from dataclasses import dataclass
from datetime import datetime, timezone

from .config import settings


CRISIS_RESPONSE = (
    "I’m concerned that someone may be in immediate danger. I can’t help with actions that could harm "
    "you or someone else. If there is immediate danger in Canada, call or text 9-8-8 for suicide-crisis "
    "support, or call 9-1-1 for emergency help. If you are elsewhere, contact local emergency or crisis services."
)
HARMFUL_RESPONSE = (
    "I can’t help create, obtain, share, or encourage harmful content. I can help with immediate safety, "
    "reporting options, prevention, or reliable support resources instead."
)
RELATIONSHIP_BOUNDARY_RESPONSE = (
    "I can offer information and practical support, but I should not replace trusted people or emergency services."
)
PROFESSIONAL_BOUNDARY_RESPONSE = (
    "I can provide general information, but I should not claim to be a licensed professional or substitute for one."
)


@dataclass(frozen=True)
class SafetyDecision:
    blocked: bool
    category: str | None = None
    message: str | None = None


def normalize_safety_text(text: str) -> str:
    """Normalize superficial evasion without changing the meaning of ordinary text.

    NFKC folds compatibility forms, Unicode format controls are removed, and all
    whitespace runs collapse to one space. Case-folding is locale-independent.
    """
    normalized = unicodedata.normalize("NFKC", text)
    normalized = "".join(ch for ch in normalized if unicodedata.category(ch) != "Cf")
    return re.sub(r"\s+", " ", normalized).strip().casefold()


class SafetyPolicy:
    """Screen clear high-risk signals while allowing benign discussion and research."""

    # First-person statements indicating immediate self-harm or interpersonal-harm intent.
    _crisis_intent = re.compile(
        r"(?:\b(?:i|we)\s+(?:want|plan|intend|expect|am going|are going)\s+to\s+"
        r"(?:die|kill myself|kill ourselves|hurt myself|hurt ourselves|harm myself|harm ourselves)\b)"
        r"|(?:\b(?:i have|i've got|i made|i have made)\s+(?:a\s+)?suicide\s+plan\b)"
        r"|(?:\b(?:i|we)\s+(?:will|plan to|intend to|am going to|are going to)\s+"
        r"(?:kill|hurt|harm)\s+(?:him|her|them|someone|a person)\b)"
    )

    # Requests for actionable interpersonal violence. Mere discussion of violence does not match.
    _violent_instructions = re.compile(
        r"\b(?:how (?:do|can|could|would) i|give me (?:steps|instructions)|instructions? (?:to|for))\b"
        r".{0,80}\b(?:kill|hurt|harm|injure|attack)\b.{0,50}\b(?:him|her|them|someone|a person|people)\b"
    )

    # Clear creation/acquisition/distribution requests involving child sexual-abuse material,
    # plus explicit requests to sexually exploit a child/minor. Neutral reporting/prevention
    # discussion is intentionally outside this deterministic matcher.
    _sexual_harm_request = re.compile(
        r"(?:\b(?:create|make|produce|obtain|get|find|download|upload|share|send|distribute)\b"
        r".{0,50}\b(?:csam|child sexual abuse material|nudes? (?:of|from) (?:a )?(?:child|minor))\b)"
        r"|(?:\b(?:how (?:do|can|could|would) i|instructions? (?:to|for))\b"
        r".{0,60}\bsexually?\s+exploit\w*\s+(?:a\s+)?(?:child|minor)\b)"
    )

    # Output-only manipulation patterns. They are deliberately about exclusivity/secrecy,
    # not ordinary warmth or suggestions to seek support.
    _relationship_manipulation = re.compile(
        r"(?:\b(?:i am|i'm)\s+your\s+only\s+(?:friend|support)\b)"
        r"|(?:\byou\s+(?:only\s+need|do not need|don't need)\s+(?:me|anyone else|other people)\b)"
        r"|(?:\b(?:i am|i'm)\s+all\s+you\s+need\b)"
        r"|(?:\b(?:keep (?:this|our conversation)|let's keep (?:this|our conversation))\s+"
        r"(?:a\s+)?secret\s+from\s+(?:everyone|other people|your family|your friends)\b)"
        r"|(?:\b(?:do not|don't)\s+tell\s+(?:anyone|your family|your friends)\s+about\s+"
        r"(?:me|us|our conversations?)\b)"
        r"|(?:\byou\s+should\s+only\s+(?:talk|listen)\s+to\s+me\b)"
    )

    # Output-only false authority claims. Explicit disclaimers such as "I am not a therapist"
    # do not match because the expression rejects "not" immediately after the copula.
    _professional_impersonation = re.compile(
        r"\b(?:i am|i'm)\s+(?!not\b)(?:a\s+)?(?:licensed\s+|certified\s+|registered\s+)?"
        r"(?:therapist|psychologist|psychiatrist|doctor|physician|lawyer|attorney|nurse|social worker)\b"
    )

    def review_user_input(self, text: str) -> SafetyDecision:
        normalized = normalize_safety_text(text)
        if self._crisis_intent.search(normalized):
            return SafetyDecision(True, "crisis", CRISIS_RESPONSE)
        if self._sexual_harm_request.search(normalized):
            return SafetyDecision(True, "child-sexual-harm", HARMFUL_RESPONSE)
        if self._violent_instructions.search(normalized):
            return SafetyDecision(True, "violent-instructions", HARMFUL_RESPONSE)
        return SafetyDecision(False)

    def review_model_output(self, text: str) -> SafetyDecision:
        normalized = normalize_safety_text(text)
        if self._relationship_manipulation.search(normalized):
            return SafetyDecision(True, "relationship-manipulation", RELATIONSHIP_BOUNDARY_RESPONSE)
        if self._professional_impersonation.search(normalized):
            return SafetyDecision(True, "professional-impersonation", PROFESSIONAL_BOUNDARY_RESPONSE)
        return SafetyDecision(False)


def record_safety_event(category: str, *, source: str, model: str | None = None) -> None:
    """Record a minimal event without retaining prompts, responses, or user identity."""
    record = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "category": category,
        "source": source,
        "model": model or settings.chat_model,
    }
    settings.safety_log_path.parent.mkdir(parents=True, exist_ok=True)
    with settings.safety_log_path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(record, ensure_ascii=False) + "\n")
