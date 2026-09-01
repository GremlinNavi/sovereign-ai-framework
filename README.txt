SOVEREIGN AI DEMONSTRATOR — ETERNAL THREAD
Release and configuration guide

Creator: Nemi Prowse
Status: v0.4.0-rc4 (Release Candidate #4) portable-framework development pre-release

This project is a local-first, auditable AI-assisted research demonstrator. It is
not a Government of Canada product, service, endorsement, procurement, certification, or production system.

WHAT PORTABLE, OPEN-SOURCE MEANS

The framework’s inference backend is replaceable: users may select or develop a
compatible local backend without making Ollama, a particular model, or a particular
provider the identity of the project. This flexibility is not an endorsement,
certification, privacy guarantee, or support commitment for a replacement backend.
Validate a backend’s capabilities, endpoint, data handling, security controls, cost,
and its own licence and terms before use. Rebuild the local embedding index after
changing the embedding model or backend.

Apache-2.0 applies to the project material identified by this repository’s notices.
It permits use, modification, redistribution, and forks of that material subject to
its conditions. It does not license third-party model weights, serving software,
hosted services, datasets, or project trademarks. Modified distributions should use
their own branding and state their backend choices and material changes clearly.

PYTHON ENVIRONMENT AND INFERENCE RUNTIME

Use a Python virtual environment to isolate this project’s pinned Python
dependencies and adapter client libraries. A virtual environment does not install or
start Ollama or any other inference service, download model weights, select a model,
or grant rights to third-party models, datasets, or services. The operator must
separately choose, install or start, and configure a compatible inference runtime
and the chat and embedding models it serves.

Ollama is the default adapter for convenience, not a bundled runtime or a permanent
project dependency. A compatible local OpenAI-style server may instead be selected
in config.py. There is no automatic runtime installation, model download, or cloud
fallback: the application uses only the chat and embedding endpoints explicitly
configured by the operator. Non-local endpoints require an explicit remote-backend
opt-in and informed in-application consent.

The installable base package supports the OpenAI-compatible local adapter without
the Ollama Python client. The Ollama client is an optional project extra; the reviewed
default lock files include it for the default Ollama adapter. A Python client library
is still distinct from the separately managed inference service and model weights.
For an installation from project metadata rather than the lock files, use
  python -m pip install .
for the base package, and only use
  python -m pip install ".[ollama]"
when selecting the Ollama adapter. Neither command installs an inference service or
model weights.

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

Ollama, other inference runtimes, and model weights are not included in the Windows
build or installed by the project’s Python virtual environment.

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
endorsed. REGULATORY_ALIGNMENT.md records engineering traceability to selected
proposed Canadian requirements; it is not legal advice or a compliance claim.

Before public release, record the exact Git tag, tag target commit, release-asset
filenames, and their SHA-256 hashes in PROVENANCE.md. The checksum of a retained
input archive is not the checksum of the final public release asset. Follow
PUBLIC_RELEASE_GUIDE.md and RELEASE_CHECKLIST.md; their unchecked items require a
maintainer’s real-world confirmation.

From the actual Git repository, run the read-only readiness audit before release:
  .\tools\Test-PublicReleaseReadiness.ps1 -Version v0.4.0-rc4 -RequireClean
It makes no file, Git, network, remote, visibility, or account changes and cannot
prove the absence of sensitive data; review its warnings before publication.

WINDOWS BOOTSTRAP

For an optional Windows PowerShell bootstrap/update workflow, see WINDOWS_INSTALL.md.
It creates a project-local Python environment and validates configuration. It does
not change the system execution policy, overwrite .env, install a runtime or model,
or silently use a remote backend.

AUTHORSHIP AND CITATION

Copyright © 2026 Nemi Prowse. Licensed under Apache-2.0; see LICENSE, NOTICE, and
CITATION.cff. This is open-source software, but the licence does not grant permission
to imply creator or government endorsement.
