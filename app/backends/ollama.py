from __future__ import annotations

from typing import Any

from ollama import Client

from .base import BackendCapabilities, BackendUnavailableError, ChatResponse, ToolCall
from ..config import BackendConfig


class OllamaBackend:
    """Adapter for Ollama's Python client; no Ollama types escape this module."""

    def __init__(self, name: str, config: BackendConfig, timeout: float) -> None:
        self.name = name
        self._config = config
        self._client = Client(host=config.base_url, timeout=timeout)

    def capabilities(self) -> BackendCapabilities:
        declared = self._config.capabilities
        return BackendCapabilities(**{field: field in declared for field in BackendCapabilities.__dataclass_fields__ if field != "context_window"})

    def health_check(self) -> None:
        try:
            self._client.list()
        except Exception as exc:
            raise BackendUnavailableError(f"AI backend '{self.name}' is unavailable at {self._config.base_url}: {exc}") from exc

    def list_models(self) -> list[str]:
        try:
            response = self._client.list()
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
        options: dict[str, Any] = {}
        if temperature is not None:
            options["temperature"] = temperature
        try:
            response = self._client.chat(model=model, messages=self._messages(messages), tools=tools, format=json_schema, options=options or None)
        except Exception as exc:
            raise BackendUnavailableError(f"AI backend '{self.name}' could not complete chat: {exc}") from exc
        calls = [ToolCall(name=call.function.name, arguments=dict(call.function.arguments or {})) for call in (response.message.tool_calls or [])]
        return ChatResponse(content=response.message.content or "", tool_calls=calls)

    def embed(self, *, model: str, texts: str | list[str]) -> list[list[float]]:
        try:
            return self._client.embed(model=model, input=texts).embeddings
        except Exception as exc:
            raise BackendUnavailableError(f"AI backend '{self.name}' could not create embeddings: {exc}") from exc
