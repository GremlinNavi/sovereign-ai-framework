SOVEREIGN AI DEMONSTRATOR
Release and configuration guide

Creator: Nemi Prowse
Status: v0.4 Release Candidate #3 portable-framework development release

This project is a local-first, auditable AI-assisted research demonstrator. It is
not a Government of Canada product, service, endorsement, or production system.

CURRENT CONFIGURATION

Configuration is declared centrally in the project-root config.py. Existing Ollama
environment variables remain supported for backward compatibility:

  OLLAMA_HOST              Default: http://127.0.0.1:11434
  OLLAMA_MODEL             Default: qwen3:4b
  OLLAMA_EMBED_MODEL       Default: nomic-embed-text
  RAG_TOP_K                Default: 6
  RAG_CHUNK_CHARS          Default: 1200
  RAG_CHUNK_OVERLAP        Default: 200
  WEB_MAX_RESULTS          Default: 5
  WEB_MAX_FETCH_CHARS      Default: 18000
  WEB_TIMEOUT              Default: 15 seconds

Ollama and model weights are not included in the Windows build.

PORTABLE BACKEND CONFIGURATION

Ollama is replaceable. The active boundary is:

  README.txt          explains available providers and safe configuration
  config.py           is the machine-readable source of configuration
  build_windows.bat   validates config.py and packages the app
  adapters            translate provider APIs into a common application interface

The common interface provides chat, embeddings, capability reporting, health checks,
and model enumeration. Current adapters are Ollama and OpenAI-compatible local
servers. The rest of the app does not depend on a specific vendor or model.

Before relying on a backend, validate:

  - the configured endpoint is reachable;
  - the chat and embedding models are available;
  - required capabilities (tool calling and structured output) are supported by the server in practice;
  - local data directories are writable.

Changing the embedding model requires rebuilding knowledge/index.sqlite3. Do not mix
vectors produced by different embedding models in one index.

Copy `.env.example` to `.env` when you want file-based configuration. The application
loads `.env` at startup; never commit that file or put secrets in it.

PUBLIC RELEASE SAFETY

Do not publish conversation history, audit logs, knowledge files, .env files, API
keys, local paths, or training/review data. Release source/build archives with a
version number, notes, and SHA-256 checksums. Keep all project claims accurate:
the demonstrator is local-first, auditable, human-controlled, and not government
endorsed.

AUTHORSHIP AND CITATION

Copyright © 2026 Nemi Prowse. Licensed under Apache-2.0; see LICENSE, NOTICE, and
CITATION.cff. This is open-source software, but the licence does not grant permission
to imply creator or government endorsement.
