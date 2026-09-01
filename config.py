"""Central, user-editable configuration for Sovereign AI Demonstrator.

This file declares provider choices. Secrets stay in environment variables named by
``api_key_env``; they are never stored in the project or bundled application.
"""
from __future__ import annotations

import argparse
import os
from dataclasses import dataclass, field
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parent


def _bool_env(name: str, default: bool = False) -> bool:
    """Read an explicit boolean environment value.

    Privacy-affecting features deliberately default to ``False`` so that a
    configuration typo cannot silently enable them.
    """
    value = os.getenv(name)
    if value is None:
        return default
    normalised = value.strip().lower()
    if normalised in {"1", "true", "yes", "on"}:
        return True
    if normalised in {"0", "false", "no", "off"}:
        return False
    raise ValueError(f"{name} must be one of: 1/0, true/false, yes/no, on/off")


def _default_data_root() -> Path:
    """Keep mutable user data out of the source checkout by default."""
    local_app_data = os.getenv("LOCALAPPDATA")
    if local_app_data:
        return Path(local_app_data) / "SovereignAIDemonstrator"
    return Path.home() / ".local" / "share" / "SovereignAIDemonstrator"


def is_local_endpoint(url: str) -> bool:
    """Return whether a configured backend endpoint is loopback-only."""
    parsed = urlparse(url)
    hostname = (parsed.hostname or "").lower()
    return hostname in {"localhost", "127.0.0.1", "::1"}


def _load_dotenv(path: Path) -> None:
    """Load simple KEY=VALUE pairs without overriding the caller's environment."""
    if not path.is_file():
        return
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        name, value = line.split("=", 1)
        name = name.strip()
        value = value.strip()
        if value[:1] == value[-1:] and value[:1] in {"'", '"'}:
            value = value[1:-1]
        if name:
            os.environ.setdefault(name, value)


_load_dotenv(ROOT / ".env")

# Change these two values to select independent inference backends.
CHAT_BACKEND = os.getenv("SOVEREIGN_AI_DEMONSTRATOR_CHAT_BACKEND", "ollama")
EMBEDDING_BACKEND = os.getenv("SOVEREIGN_AI_DEMONSTRATOR_EMBEDDING_BACKEND", "ollama")
APP_NAME = "SovereignAIDemonstrator"


@dataclass(frozen=True)
class BackendConfig:
    kind: str
    base_url: str
    chat_model: str = ""
    embedding_model: str = ""
    api_key_env: str | None = None
    capabilities: frozenset[str] = field(default_factory=frozenset)


# Ollama variables remain supported so existing v0.3 setups continue to work.
BACKENDS: dict[str, BackendConfig] = {
    "ollama": BackendConfig(
        kind="ollama",
        base_url=os.getenv("OLLAMA_HOST", "http://127.0.0.1:11434"),
        chat_model=os.getenv("OLLAMA_MODEL", "qwen3:4b"),
        embedding_model=os.getenv("OLLAMA_EMBED_MODEL", "nomic-embed-text"),
        capabilities=frozenset({"chat", "embeddings", "tool_calling", "structured_output", "model_enumeration"}),
    ),
    "openai_compatible": BackendConfig(
        kind="openai_compatible",
        base_url=os.getenv("OPENAI_COMPATIBLE_BASE_URL", "http://127.0.0.1:8000/v1"),
        chat_model=os.getenv("OPENAI_COMPATIBLE_CHAT_MODEL", "local-chat-model"),
        embedding_model=os.getenv("OPENAI_COMPATIBLE_EMBEDDING_MODEL", "local-embedding-model"),
        api_key_env="OPENAI_COMPATIBLE_API_KEY",
        capabilities=frozenset({"chat", "embeddings", "tool_calling", "structured_output", "model_enumeration"}),
    ),
}


def _int_env(name: str, default: int, minimum: int = 0) -> int:
    value = int(os.getenv(name, str(default)))
    if value < minimum:
        raise ValueError(f"{name} must be >= {minimum}")
    return value


@dataclass(frozen=True)
class Settings:
    chat_backend_name: str
    embedding_backend_name: str
    chat_backend: BackendConfig
    embedding_backend: BackendConfig
    chat_model: str
    embedding_model: str
    top_k: int
    chunk_chars: int
    chunk_overlap: int
    max_web_results: int
    max_fetch_chars: int
    max_web_response_bytes: int
    max_search_response_bytes: int
    max_search_query_chars: int
    max_redirects: int
    request_timeout: float
    backend_timeout: float
    max_tool_calls_per_turn: int
    history_context_turns: int
    data_root: Path
    history_dir: Path
    knowledge_dir: Path
    index_path: Path
    audit_log_path: Path
    safety_log_path: Path
    consent_path: Path
    retention_days: int
    store_conversations: bool
    index_conversations: bool
    index_knowledge: bool
    web_research_enabled: bool
    allow_remote_backends: bool


def load_settings() -> Settings:
    if CHAT_BACKEND not in BACKENDS or EMBEDDING_BACKEND not in BACKENDS:
        raise ValueError("CHAT_BACKEND and EMBEDDING_BACKEND must name entries in BACKENDS")
    chat = BACKENDS[CHAT_BACKEND]
    embedding = BACKENDS[EMBEDDING_BACKEND]
    data_root = Path(os.getenv("SOVEREIGN_AI_DEMONSTRATOR_DATA_DIR", str(_default_data_root())))
    return Settings(
        chat_backend_name=CHAT_BACKEND, embedding_backend_name=EMBEDDING_BACKEND,
        chat_backend=chat, embedding_backend=embedding,
        chat_model=os.getenv("SOVEREIGN_AI_DEMONSTRATOR_CHAT_MODEL", chat.chat_model),
        embedding_model=os.getenv("SOVEREIGN_AI_DEMONSTRATOR_EMBEDDING_MODEL", embedding.embedding_model),
        top_k=_int_env("RAG_TOP_K", 6, 1), chunk_chars=_int_env("RAG_CHUNK_CHARS", 1200, 100),
        chunk_overlap=_int_env("RAG_CHUNK_OVERLAP", 200, 0), max_web_results=_int_env("WEB_MAX_RESULTS", 5, 1),
        max_fetch_chars=_int_env("WEB_MAX_FETCH_CHARS", 18000, 1000),
        max_web_response_bytes=_int_env("WEB_MAX_RESPONSE_BYTES", 2_000_000, 10_000),
        max_search_response_bytes=_int_env("WEB_MAX_SEARCH_RESPONSE_BYTES", 2_000_000, 10_000),
        max_search_query_chars=_int_env("WEB_MAX_QUERY_CHARS", 500, 1), max_redirects=_int_env("WEB_MAX_REDIRECTS", 3, 0),
        request_timeout=float(os.getenv("WEB_TIMEOUT", "15")), backend_timeout=float(os.getenv("BACKEND_TIMEOUT", "30")),
        max_tool_calls_per_turn=_int_env("MAX_TOOL_CALLS_PER_TURN", 4, 1), history_context_turns=_int_env("HISTORY_CONTEXT_TURNS", 12, 1),
        data_root=data_root, history_dir=data_root / "conversation_history" / "sessions",
        knowledge_dir=data_root / "knowledge", index_path=data_root / "knowledge" / "index.sqlite3",
        audit_log_path=data_root / "conversation_history" / "tool_audit.jsonl",
        safety_log_path=data_root / "conversation_history" / "safety_events.jsonl",
        consent_path=data_root / "privacy_consent.json",
        retention_days=_int_env("SOVEREIGN_AI_DEMONSTRATOR_RETENTION_DAYS", 30, 1),
        store_conversations=_bool_env("SOVEREIGN_AI_DEMONSTRATOR_STORE_CONVERSATIONS", True),
        index_conversations=_bool_env("SOVEREIGN_AI_DEMONSTRATOR_INDEX_CONVERSATIONS", False),
        index_knowledge=_bool_env("SOVEREIGN_AI_DEMONSTRATOR_INDEX_KNOWLEDGE", False),
        web_research_enabled=_bool_env("SOVEREIGN_AI_DEMONSTRATOR_ENABLE_WEB_RESEARCH", False),
        allow_remote_backends=_bool_env("SOVEREIGN_AI_DEMONSTRATOR_ALLOW_REMOTE_BACKENDS", False),
    )


def validate_configuration() -> Settings:
    current = load_settings()
    for provider in (current.chat_backend, current.embedding_backend):
        parsed = urlparse(provider.base_url)
        if parsed.scheme not in {"http", "https"} or not parsed.netloc:
            raise ValueError(f"Invalid backend URL: {provider.base_url!r}")
        if not is_local_endpoint(provider.base_url) and not current.allow_remote_backends:
            raise ValueError(
                "Remote AI backends are disabled. Set SOVEREIGN_AI_DEMONSTRATOR_ALLOW_REMOTE_BACKENDS=1 "
                "only after informing the user about the data transfer."
            )
    if not current.chat_model or not current.embedding_model:
        raise ValueError("Configured chat and embedding models must not be empty")
    if current.chunk_overlap >= current.chunk_chars:
        raise ValueError("RAG_CHUNK_OVERLAP must be smaller than RAG_CHUNK_CHARS")
    for path in (current.history_dir, current.knowledge_dir, current.audit_log_path.parent):
        path.mkdir(parents=True, exist_ok=True)
    return current


settings = validate_configuration()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Validate Sovereign AI Demonstrator configuration")
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--health-check", action="store_true", help="Check configured endpoints and verify configured model names are listed")
    parser.add_argument("--build-name", action="store_true")
    args = parser.parse_args()
    if args.build_name:
        print(APP_NAME)
    elif args.validate:
        print(f"Configuration valid: chat={settings.chat_backend_name}/{settings.chat_model}; embeddings={settings.embedding_backend_name}/{settings.embedding_model}")
    elif args.health_check:
        from app.backends import create_backend
        required_models: dict[str, set[str]] = {}
        for name, model in (
            (settings.chat_backend_name, settings.chat_model),
            (settings.embedding_backend_name, settings.embedding_model),
        ):
            required_models.setdefault(name, set()).add(model)
        for name, expected in required_models.items():
            backend = create_backend(name)
            available = set(backend.list_models())
            missing = expected - available
            if missing:
                raise RuntimeError(
                    f"Configured model(s) not listed by backend '{name}': {', '.join(sorted(missing))}"
                )
        print("Configured AI backend endpoints and model names passed health checks")
    else:
        parser.print_help()
