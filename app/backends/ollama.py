# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

from typing import Any

try:
    from ollama import Client as OllamaClient
except ImportError:  # Keep the adapter importable when another backend is used.
    OllamaClient = None  # type: ignore[assignment]

from .base import BackendCapabilities, BackendUnavailableError, ChatResponse, ToolCall
from ..config import BackendConfig


class OllamaBackend:
    """Adapter for Ollama's Python client; no Ollama types escape this module."""

    def __init__(self, name: str, config: BackendConfig, timeout: float) -> None:
        self.name = name
        self._config = config
        self._client = (
            OllamaClient(host=config.base_url, timeout=timeout)
            if OllamaClient is not None
            else None
        )

    def _require_client(self):
        if self._client is None:
            raise BackendUnavailableError(
                "The Ollama Python client is not installed. Install the locked runtime "
                "dependencies (for example: pip install -r requirements.lock) or select "
                "a different configured backend."
            )
        return self._client

    def capabilities(self) -> BackendCapabilities:
        declared = self._config.capabilities
        return BackendCapabilities(**{field: field in declared for field in BackendCapabilities.__dataclass_fields__ if field != "context_window"})

    def health_check(self) -> None:
        client = self._require_client()
        try:
            client.list()
        except Exception as exc:
            raise BackendUnavailableError(f"AI backend '{self.name}' is unavailable at {self._config.base_url}: {exc}") from exc

    def list_models(self) -> list[str]:
        client = self._require_client()
        try:
            response = client.list()
            return [model.model for model in getattr(response, "models", [])]
        except Exception as exc:
            raise BackendUnavailableError(f"Could not list models from '{self.name}': {exc}") from exc

    @staticmethod
    def _messages(messages: list[dict]) -> list[dict]:
        converted: list[dict] = []
        for message in messages:
            item = dict(message)
            calls = item.get("tool_calls")
            if calls:
                item["tool_calls"] = [
                    {"function": {"name": call["name"], "arguments": call.get("arguments", {})}}
                    for call in calls
                ]
            if item.get("role") == "tool":
                item.pop("tool_call_id", None)
                item["tool_name"] = item.pop("name", item.get("tool_name", "tool"))
            converted.append(item)
        return converted

    def chat(self, *, model: str, messages: list[dict], tools: list[dict] | None = None, json_schema: dict | None = None, temperature: float | None = None) -> ChatResponse:
        client = self._require_client()
        options: dict[str, Any] = {}
        if temperature is not None:
            options["temperature"] = temperature
        try:
            response = client.chat(model=model, messages=self._messages(messages), tools=tools, format=json_schema, options=options or None)
        except Exception as exc:
            raise BackendUnavailableError(f"AI backend '{self.name}' could not complete chat: {exc}") from exc
        calls = [ToolCall(name=call.function.name, arguments=dict(call.function.arguments or {})) for call in (response.message.tool_calls or [])]
        return ChatResponse(content=response.message.content or "", tool_calls=calls)

    def embed(self, *, model: str, texts: str | list[str]) -> list[list[float]]:
        client = self._require_client()
        try:
            return client.embed(model=model, input=texts).embeddings
        except Exception as exc:
            raise BackendUnavailableError(f"AI backend '{self.name}' could not create embeddings: {exc}") from exc
