# Sovereign AI Demonstrator

A Canadian reference implementation for local-first, auditable AI-assisted research.

The `sovereign-ai-framework` repository is the source repository for the Sovereign AI Demonstrator; the repository slug is an implementation identifier, not a second product name. OSWAP is a separate open-source access and discovery initiative that may interoperate with this demonstrator.

Development history: [September 2, 2026 OSWAP branding and Twin transport session](docs/development-history/2026-09-02-oswap-branding-and-twin-session.md).

A local-first research framework with replaceable inference backends. It combines AI tool calling, conversation-history retrieval, local knowledge retrieval, public-web research, evidence assessments, provenance-oriented citations, confidence ratings, and universal `.txt` conversation exports.

**Creator:** Nemi Prowse

**Status:** v0.4 Release Candidate #3 is a portable-framework development release. It is not a Government of Canada product,
service, endorsement, or production deployment.

## Authorship, citation, and reuse

Sovereign AI Demonstrator was created by Nemi Prowse. Please retain
the project attribution and refer to [CITATION.cff](CITATION.cff) when citing this
software. The repository's release materials are documented in [NOTICE](NOTICE) and
[RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md).

This project is open source under the [Apache License, Version 2.0](LICENSE).
Copyright remains with Nemi Prowse and contributors retain copyright in their own
contributions. The `NOTICE` file preserves project attribution; the licence does not
grant permission to imply project or government endorsement.

## Architecture

```text
                         ┌───────────────┐
                         │ AI backend    │
                         │ local model   │
                         └──────┬────────┘
                                │
                         tool calls / chat
                                │
                     ┌──────────┴──────────┐
                     │       Agent         │
                     └──────────┬──────────┘
                                │
                  ┌─────────────┼─────────────┐
                  ▼             ▼             ▼
            Conversation     Knowledge      Web tools
             history           files       search/fetch
                  │             │             │
                  └─────────────┼─────────────┘
                                ▼
                         Local vector index
                         (SQLite + configured
                            embeddings)
```

## Requirements

- Python 3.10+
- A configured AI backend reachable from the application
- A chat model; tool calling and structured output are required for evidence assessment
- An embedding model

The default configuration uses Ollama with `qwen3:4b` for chat and `nomic-embed-text`
for embeddings. Ollama is the default adapter, not the identity of the framework.
The chat and embedding backends may be selected independently in the project-root
`config.py`.

## Setup

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements-test.lock
# Install the runtime required by the backend selected in config.py.
# For the default Ollama adapter:
ollama pull qwen3:4b
ollama pull nomic-embed-text
python -m app.main
```

On Windows PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements-test.lock
# For the default Ollama adapter:
ollama pull qwen3:4b
ollama pull nomic-embed-text
python -m app.main
```

Run the safety/regression tests with:

```bash
pytest -q
```

`requirements.lock` pins the reviewed runtime dependency set; `requirements-test.lock`
adds the test tools; and `requirements-build.lock` adds the Windows packaging tools.

To install the application from a source checkout and use its command-line entry
point, run:

```bash
pip install .
sovereign-ai-demonstrator
```

## Folders

- `conversation_history/sessions/` — JSONL conversation sessions.
- `conversation_history/tool_audit.jsonl` — local audit trail of tool calls and their status.
- `knowledge/` — local `.txt`, `.md`, `.json`, and `.jsonl` files used by RAG.
- `training_data/raw/` — raw data you may later curate or transform.
- `training_data/curated/` — cleaner datasets suitable for fine-tuning/evaluation workflows.
- `tests/` — safety/regression tests.

The SQLite vector index is generated at `knowledge/index.sqlite3` and can be deleted to rebuild it.

## Hybrid RAG behavior

Every user query is embedded through the configured embedding backend and compared against stored embeddings from:

1. conversation history,
2. local knowledge files,
3. previously fetched web pages.

The assistant receives the most relevant chunks as context. Web fetching automatically stores extracted page text in the same local retrieval index.

Training data is intentionally not ingested into RAG automatically; keep dataset development separate from runtime knowledge unless you explicitly decide otherwise.

## Security boundaries

The project is designed to fail closed around the web and tool surfaces:

- Only `http://` and `https://` URLs are accepted.
- Embedded URL credentials are rejected.
- Hostnames resolving to private, loopback, link-local, multicast, reserved, or unspecified addresses are rejected.
- Redirects are handled manually and each new destination is revalidated.
- Web response bodies are capped to prevent unbounded downloads.
- Search queries and tool-call counts have configurable limits.
- Tool calls are recorded in a local JSONL audit log.
- Retrieved conversation, local files, and web pages are explicitly framed to the model as untrusted data, not instructions.
- Tool schemas disallow unexpected arguments.

These are practical application-layer defenses, not a guarantee of complete security. Keep the assistant bound to your machine unless you deliberately add authentication and a stronger isolation boundary.

## Privacy, consent, and digital safety

The application now keeps mutable data outside the source checkout by default and
uses granular consent for local conversation storage, retrieval indexing, web
research, and non-local AI backends. Conversation and knowledge indexing and web
research are disabled by default. Remote endpoints are rejected unless explicitly
enabled and accepted by the user at first use.

Use `/privacy` to view choices, `/consent <purpose>` or `/revoke <purpose>` to manage
them, `/export-data` to export locally held records, and `/delete-session` or
`/delete-all-data` to remove local data and derived retrieval chunks. See
[PRIVACY.md](PRIVACY.md) and [DIGITAL_SAFETY_PLAN.md](DIGITAL_SAFETY_PLAN.md).

Safety controls screen clear crisis and child sexual-harm requests, avoid
relationship-manipulation behaviours, and record content-free safety events locally.
They are a baseline, not a replacement for tested model controls, human review, or a
deployment-specific legal and safety assessment.

## Web tools

The assistant can call:

- `search_the_web(query)` — scrapes DuckDuckGo's HTML result page.
- `fetch_webpage(url)` — fetches and extracts readable HTML text, then indexes it locally.

The DuckDuckGo HTML endpoint is used here to avoid requiring a paid search API. Search-engine HTML is not a stable API, so production deployments should consider replacing it with a supported API or self-hosted search backend.

## Backend and model selection

`config.py` is the central source of configuration. It selects independent chat and
embedding backends, their endpoints, models, timeouts, storage root, and RAG limits.
The default remains backward-compatible with `OLLAMA_HOST`, `OLLAMA_MODEL`, and
`OLLAMA_EMBED_MODEL` environment variables.

v0.4 ships two adapters:

- `ollama` — the default local Ollama adapter.
- `openai_compatible` — a dependency-light adapter for compatible local servers.

Set `SOVEREIGN_AI_DEMONSTRATOR_CHAT_BACKEND` and `SOVEREIGN_AI_DEMONSTRATOR_EMBEDDING_BACKEND` to select
an adapter. See `.env.example` and `README.txt`. Capabilities are declared in the
backend configuration and checked before dependent features run. Basic chat can continue without native tools, but evidence assessment
requires chat, tool calling, and structured-output support.

When changing the embedding model or backend, rebuild `knowledge/index.sqlite3`.
Embedding vectors from different models must not be mixed.

## Portable-backend roadmap

The framework treats Ollama as one replaceable inference adapter rather than a
permanent application dependency. The research workflow, local records, RAG store,
audit trail, exports, and human-review controls remain independent of the selected
backend.

The planned responsibility boundary is:

```text
README.txt      explains backend choices, requirements, and safe switching
config.py       declares the selected backend, models, endpoint, and capabilities
build_windows.bat validates the configuration and packages the application
application code uses a normalized backend interface, not provider-specific calls
```

Ollama and OpenAI-compatible local inference servers are currently supported.
Additional adapters (for example, a provider-specific llama.cpp or LM Studio adapter)
can be added without altering the agent, RAG, GUI, research, export, or storage layers.
A backend's declared chat, embedding, tool-calling, and structured-output capabilities
are checked before dependent features run. Run `python config.py --health-check` to
verify that configured local endpoints list the selected model names. This is not an
independent capability certification of every compatible server.

See [README.txt](README.txt) for the configuration and validation contract.

## Portable host and compatibility architecture

SteamOS, Proton, Linux handhelds, USB-C docking, and Git-hosted operating-system
forks are useful reference architectures for the project's portability goals, but
none is a required Sovereign AI Demonstrator dependency. The important transferable principles
are replaceable layers, reproducible environments, maintained compatibility bridges,
standard peripheral expansion, forkable source, and the ability to preserve known-good
software states independently of a single vendor or forge.

On Linux hosts, create a fresh project-specific `.venv` and install the reviewed
locked dependencies rather than copying a generated virtual environment between
machines. The `.venv` is a dependency-isolation boundary, not a security sandbox.
Host-level filesystem, process, device, and network restrictions remain operating-system
and deployment responsibilities.

See [PORTABLE_HOST_ARCHITECTURE.md](PORTABLE_HOST_ARCHITECTURE.md) for the SteamOS,
Proton, portable-copy, fork/mirror, Canadian open-computing, and future
configuration-driven host-profile rationale.

## Privacy note

Conversation history, embeddings, and fetched page text are stored locally. Web requests necessarily leave your machine because the web tool accesses the public internet. The application sends prompts and retrieved context only to the backend endpoint you configure. Keep that endpoint local when privacy is the goal.

## Desktop GUI

The project includes a native Tk desktop GUI in `app/gui.py` and `launcher.py`. On Windows, run `build_windows.bat` to create `dist\\SovereignAIDemonstrator\\SovereignAIDemonstrator.exe` by default, with no console window. The executable name is read from `config.py`. Tk is bundled with standard Windows Python installations, so the GUI does not need a separate Qt runtime.

The GUI is a thin client over the same local agent: conversation history, hybrid RAG, web tools, security checks, and the configured inference backend remain in the Python backend.

SQLite connections are thread-local. GUI work that calls an AI backend runs in a
background worker with its own backend instance and SQLite connection; the GUI never passes
an open database connection across that thread boundary. The index uses WAL mode
and a short busy wait so concurrent GUI reads/writes remain safe.

Inference runtimes and model weights are intentionally not bundled into the executable.
Install and configure the selected backend separately before launching the app.

## Evidence workflow

The research layer treats the model as an evidence-analysis tool, not an authority. It separates event confidence, legal confidence, attribution confidence, and overall evidentiary support; records supporting and contradicting sources; and always marks the result for human review. Confidence values are assessments of evidentiary support, not probabilities of guilt.

Every web citation must originate from an actual fetched/search result. Retrieved webpages, conversation excerpts, and local files are treated as untrusted data and never as instructions. The application does not intentionally fabricate sources or evidence.

`/assess <question>` performs a bounded public-web research pass followed by structured evidence assessment. In the GUI, enter a research question and use `Assess evidence`.

## Text exports

Conversation history remains the canonical local JSONL record. `Export .txt` creates a portable UTF-8 text record containing the conversation and any stored public-research evidence assessments. Records explicitly marked confidential are omitted unless a future caller intentionally requests confidential export.

The plain-text format is deliberately dependency-free so research records remain readable outside the project.

## Publication safeguard

Evidence assessments are never treated as publication authorization. The model is required to report uncertainty, contradictions, and evidence gaps, and the application records `HUMAN REVIEW REQUIRED: YES` for every assessment. A separate human decision is required before any research result is treated as publishable.

## Preparing a public GitHub release

Before making a repository public, remove personal conversation histories, tool audit
logs, knowledge files, `.env` files, API keys, local paths, and any training or review
data. Publish source archives and any Windows build as versioned GitHub release assets,
with release notes and a SHA-256 checksum file. Do not commit generated release archives,
checksums, executable builds, or personal data to the default branch. Mark unfinished
work as a pre-release.

Keep project identity precise: use **Sovereign AI Demonstrator** and
the tagline **Local-first. Auditable. Human-controlled.** Do not imply government
ownership, endorsement, or production readiness. See [BRANDING.md](BRANDING.md).
Review [SECURITY.md](SECURITY.md), [CONTRIBUTING.md](CONTRIBUTING.md), and generated
`THIRD_PARTY_NOTICES.md` before publishing an executable.
