"""A deterministic safety gate for high-risk chatbot interactions.

It is intentionally conservative and augments, rather than replaces, model-level
evaluation and human review. Safety event records contain category metadata only.
"""
from __future__ import annotations

import json
import re
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


@dataclass(frozen=True)
class SafetyDecision:
    blocked: bool
    category: str | None = None
    message: str | None = None


class SafetyPolicy:
    """Screen only clear high-risk signals; ambiguous research requests reach normal review."""

    _crisis = re.compile(
        r"\b(kill myself|end my life|suicide plan|want to die|hurt myself|kill (him|her|them|someone)|harm (him|her|them|someone))\b",
        re.IGNORECASE,
    )
    _sexual_harm = re.compile(
        r"\b(child sexual abuse|sexual(?:ly)? exploit(?:ation|ing)? (?:a )?(child|minor)|nudes? (?:of|from) (?:a )?(child|minor)|csam)\b",
        re.IGNORECASE,
    )
    _relationship_manipulation = re.compile(
        r"\b(i am your only (friend|support)|you do not need (anyone|other people)|keep this secret from everyone)\b",
        re.IGNORECASE,
    )

    def review_user_input(self, text: str) -> SafetyDecision:
        if self._crisis.search(text):
            return SafetyDecision(True, "crisis", CRISIS_RESPONSE)
        if self._sexual_harm.search(text):
            return SafetyDecision(True, "child-sexual-harm", HARMFUL_RESPONSE)
        return SafetyDecision(False)

    def review_model_output(self, text: str) -> SafetyDecision:
        if self._relationship_manipulation.search(text):
            return SafetyDecision(
                True,
                "relationship-manipulation",
                "I can offer information and practical support, but I should not replace trusted people or emergency services.",
            )
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
