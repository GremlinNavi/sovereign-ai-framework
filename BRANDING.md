# Sovereign AI Demonstrator

## Official project name

Sovereign AI Demonstrator

## One-line description

A Canadian reference implementation for local-first, auditable AI-assisted research and knowledge work.

## Short description

The Sovereign AI Demonstrator explores how AI-assisted knowledge work can operate under explicit data-boundary, provenance, auditability, security, and human-review requirements. It is designed as an inspectable reference implementation rather than a production Government of Canada system.

## Open-Source World Access Project relationship

The Open-Source World Access Project (OSWAP) is a separate open-source software-access and discovery initiative. Its planned database layer is documented in [OSWAP_DATABASE.md](OSWAP_DATABASE.md).

OSWAP is not a replacement name for the Sovereign AI Demonstrator. The two projects may interoperate while retaining separate technical and branding boundaries.

The local `knowledge/index.sqlite3` database belongs to the Sovereign AI Demonstrator's RAG runtime. It is not the OSWAP software catalogue.

## Planned OSWAP AI endpoints

The planned OSWAP-controlled public identities for this project are:

- `https://ai.oswap.ca`
- `https://ai.oswap.us`

These are intended as peer endpoints rather than a primary-and-mirror pair. They do not rename the Sovereign AI Demonstrator and they do not make either national domain the canonical copy.

The endpoints are intended to provide both a human-readable project surface and read-only Git access when the required infrastructure is deployed. Until DNS, TLS, routing, and Git protocol handling have been implemented and tested, documentation must describe them as planned rather than operational.

See [OSWAP_AI_ENDPOINTS.md](OSWAP_AI_ENDPOINTS.md) for the endpoint contract and proposed Git behavior.

## Documentation languages

Public documentation is implemented in three supported languages:

- English (`en`)
- Canadian French (`fr-CA`)
- Japanese (`ja`)

Official project names, commands, URLs, repository slugs, file names, protocol names, hashes, and checksums remain unchanged across translations. English is the technical synchronization source unless a document explicitly states otherwise.

Localized documentation must preserve status qualifiers such as planned, experimental, unverified, or operational. A translation must not strengthen a technical claim beyond the English source.

See [LANGUAGES.md](LANGUAGES.md), [README.fr-CA.md](README.fr-CA.md), and [README.ja.md](README.ja.md).

## Federal-facing positioning

Use:

> Sovereign AI Demonstrator

Avoid:

> Canada's Sovereign AI
> Government of Canada Sovereign AI Platform
> Canada's Sovereign AI Platform

Those formulations imply institutional ownership, endorsement, or platform status that this project does not possess. The Government of Canada already uses closely related terminology for its own sovereign-AI programs and platform initiatives.

## Brand hierarchy

- Open-source access/discovery initiative: Open-Source World Access Project (OSWAP)
- AI product / demonstrator: Sovereign AI Demonstrator
- OSWAP AI public identity: `ai.oswap.ca` and `ai.oswap.us` (planned)
- OSWAP data/discovery specification: OSWAP Database
- Repository identity: sovereign-ai-framework

## Federal-facing tagline

Local-first. Auditable. Human-controlled.

## Alternate technical descriptor

A sovereign-AI reference implementation for controlled, evidence-aware knowledge work.

## Tone

Professional, precise, understated, evidence-led, and candid about prototype limitations. Avoid hype, claims of government endorsement, and claims of production readiness that have not been independently demonstrated.
