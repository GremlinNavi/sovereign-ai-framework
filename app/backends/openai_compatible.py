from __future__ import annotations

import json
import os
from urllib.parse import urljoin

import requests

from .base import BackendCapabilities, BackendUnavailableError, ChatResponse, ToolCall
from ..config import BackendConfig


class OpenAICompatibleBackend:
    """Dependency-light adapter for local servers exposing an OpenAI-style API."""

    def __init__(self, name: str, config: BackendConfig, timeout: float) -> None:
        self.name, self._config, self._timeout = name, config, timeout

    def capabilities(self) -> BackendCapabilities:
        declared = self._config.capabilities
        return BackendCapabilities(**{field: field in declared for field in BackendCapabilities.__dataclass_fields__ if field != "context_window"})

    def _headers(self) -> dict[str, str]:
        headers = {"Content-Type": "application/json"}
        if self._config.api_key_env and (key := os.getenv(self._config.api_key_env)):
            headers["Authorization"] = f"Bearer {key}"
        return headers

    def _url(self, path: str) -> str:
        return urljoin(self._config.base_url.rstrip("/") + "/", path)

    def _request(self, method: str, path: str, **kwargs):
        try:
            response = requests.request(method, self._url(path), timeout=self._timeout, headers=self._headers(), **kwargs)
            response.raise_for_status()
            return response.json()
        except (requests.RequestException, ValueError) as exc:
            raise BackendUnavailableError(f"AI backend '{self.name}' is unavailable or returned invalid data: {exc}") from exc

    def health_check(self) -> None:
        self.list_models()

    def list_models(self) -> list[str]:
        payload = self._request("GET", "models")
        return [str(item.get("id", "")) for item in payload.get("data", []) if item.get("id")]

    @staticmethod
    def _messages(messages: list[dict]) -> list[dict]:
        converted: list[dict] = []
        for message in messages:
            item = dict(message)
            calls = item.get("tool_calls")
            if calls:
                item["tool_calls"] = [
                    {
                        # A few compatible local servers omit an ID even though
                        # OpenAI's schema requires one. Preserve interoperability
                        # by supplying a stable local fallback for the next turn.
                        "id": call.get("id") or f"local-tool-call-{index}",
                        "type": "function",
                        "function": {"name": call["name"], "arguments": json.dumps(call.get("arguments", {}))},
                    }
                    for index, call in enumerate(calls, 1)
                ]
            if item.get("role") == "tool":
                item.pop("name", None)
            converted.append(item)
        return converted

    def chat(self, *, model: str, messages: list[dict], tools: list[dict] | None = None, json_schema: dict | None = None, temperature: float | None = None) -> ChatResponse:
        payload: dict = {"model": model, "messages": self._messages(messages)}
        if tools:
            payload["tools"] = tools
        if json_schema:
            payload["response_format"] = {"type": "json_schema", "json_schema": {"name": "assessment", "schema": json_schema}}
        if temperature is not None:
            payload["temperature"] = temperature
        result = self._request("POST", "chat/completions", json=payload)
        message = result.get("choices", [{}])[0].get("message", {})
        calls = []
        for call in message.get("tool_calls") or []:
            function = call.get("function", {})
            try:
                arguments = json.loads(function.get("arguments") or "{}")
            except json.JSONDecodeError as exc:
                raise BackendUnavailableError(f"AI backend '{self.name}' returned malformed tool arguments") from exc
            calls.append(ToolCall(name=str(function.get("name", "")), arguments=arguments, id=call.get("id")))
        return ChatResponse(content=str(message.get("content") or ""), tool_calls=calls)

    def embed(self, *, model: str, texts: str | list[str]) -> list[list[float]]:
        values = [texts] if isinstance(texts, str) else texts
        result = self._request("POST", "embeddings", json={"model": model, "input": values})
        return [item["embedding"] for item in result.get("data", [])]
