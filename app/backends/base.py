# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Protocol


class BackendError(RuntimeError):
    """Base class for backend failures that can be shown to an application user."""


class BackendUnavailableError(BackendError):
    pass


class BackendCapabilityError(BackendError):
    pass


@dataclass(frozen=True)
class BackendCapabilities:
    chat: bool = True
    embeddings: bool = True
    tool_calling: bool = False
    structured_output: bool = False
    streaming: bool = False
    model_enumeration: bool = False
    context_window: int | None = None

    def require(self, *names: str) -> None:
        unavailable = [name for name in names if not getattr(self, name, False)]
        if unavailable:
            raise BackendCapabilityError("Configured AI backend does not support: " + ", ".join(unavailable))


@dataclass(frozen=True)
class ToolCall:
    name: str
    arguments: dict
    id: str | None = None


@dataclass(frozen=True)
class ChatResponse:
    content: str
    tool_calls: list[ToolCall] = field(default_factory=list)


class Backend(Protocol):
    name: str

    def capabilities(self) -> BackendCapabilities: ...
    def health_check(self) -> None: ...
    def list_models(self) -> list[str]: ...
    def chat(self, *, model: str, messages: list[dict], tools: list[dict] | None = None, json_schema: dict | None = None, temperature: float | None = None) -> ChatResponse: ...
    def embed(self, *, model: str, texts: str | list[str]) -> list[list[float]]: ...
