# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

from .base import Backend
from ..config import BackendConfig, settings


def create_backend(name: str) -> Backend:
    """Create a configured adapter by its logical name, never by provider details in callers."""
    selected: BackendConfig
    if name == settings.chat_backend_name:
        selected = settings.chat_backend
    elif name == settings.embedding_backend_name:
        selected = settings.embedding_backend
    else:
        from config import BACKENDS
        selected = BACKENDS[name]
    if selected.kind == "ollama":
        from .ollama import OllamaBackend
        return OllamaBackend(name, selected, settings.backend_timeout)
    if selected.kind == "openai_compatible":
        from .openai_compatible import OpenAICompatibleBackend
        return OpenAICompatibleBackend(name, selected, settings.backend_timeout)
    raise ValueError(f"Unsupported backend kind {selected.kind!r} for {name!r}")
