# OSWAP AI Demonstrator

## Official project name

OSWAP AI Demonstrator

## One-line description

A Canadian reference implementation for local-first, auditable AI-assisted research and knowledge work.

## Short description

The OSWAP AI Demonstrator explores how AI-assisted knowledge work can operate under explicit data-boundary, provenance, auditability, security, and human-review requirements. It is designed as an inspectable reference implementation rather than a production Government of Canada system.

## Repository hosting metadata

Use this description for the GitHub and GitLab repository metadata:

> OSWAP AI Demonstrator: a portable, backend-agnostic local-first AI research framework with hybrid RAG, provenance-aware assessments, and portable text exports.

## Repository versus product identity

Use `OSWAP AI Demonstrator` for the product/display name. Use `oswap-ai-demonstrator` only when referring to the repository slug, clone path, package context, or other implementation-specific identifier.

`Eternal Thread` is a historical development name. It must not be used in active repository descriptions, current product headers, taglines, or homepage metadata.

## Open-Source World Access Project relationship

The Open-Source World Access Project (OSWAP) is the broader open-source initiative spanning software access, discovery, preservation, automation, and AI-assisted tooling. Its planned database layer is documented in [OSWAP_DATABASE.md](OSWAP_DATABASE.md).

The OSWAP AI Demonstrator is the AI demonstrator component within that broader initiative. It may interoperate with other OSWAP components while retaining its own implementation and release boundaries.

The local `knowledge/index.sqlite3` database belongs to the OSWAP AI Demonstrator's RAG runtime. It is not the OSWAP software catalogue.

## OSWAP-owned domains

OSWAP controls the following public domains:

- `oswap.ca`
- `oswap.jp`
- `oswap.us`

These owned domains may be used as stable OSWAP namespaces in project documentation and architecture examples. Ownership of a parent domain does not imply that every proposed subdomain is operational. DNS, TLS, routing, Git protocol behavior, and content equivalence must be separately deployed and verified.

## Planned OSWAP AI endpoints

The planned OSWAP-controlled public identities for this project are:

- `https://ai.oswap.ca`
- `https://ai.oswap.jp`
- `https://ai.oswap.us`

These are intended as peer endpoints rather than a primary-and-mirror hierarchy. They do not rename the OSWAP AI Demonstrator and they do not make any national domain the canonical copy.

The endpoints are intended to provide both a human-readable project surface and read-only Git access when the required infrastructure is deployed. Until DNS, TLS, routing, and Git protocol handling have been implemented and tested, documentation must describe them as planned rather than operational.

The wider OSWAP Git Push Twin design may also use expression-addressed repository subdomains such as `repo9d3.oswap.ca`, `repo9d3.oswap.jp`, and `repo9d3.oswap.us`, where `9d3` is a transport-safe representation of the canonical Order of Operations expression `9/3`. Those names are design examples until individually deployed and verified.

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

> OSWAP AI Demonstrator

Avoid:

> Canada's Sovereign AI
> Government of Canada Sovereign AI Platform
> Canada's Sovereign AI Platform

Those formulations imply institutional ownership, endorsement, or platform status that this project does not possess. The Government of Canada already uses closely related terminology for its own sovereign-AI programs and platform initiatives.

## Brand hierarchy

- Open-source access/discovery initiative: Open-Source World Access Project (OSWAP)
- AI product / demonstrator: OSWAP AI Demonstrator
- OSWAP-owned domains: `oswap.ca`, `oswap.jp`, `oswap.us`
- OSWAP AI public identity: `ai.oswap.ca`, `ai.oswap.jp`, and `ai.oswap.us` (planned)
- OSWAP data/discovery specification: OSWAP Database
- Repository identity: oswap-ai-demonstrator

## Federal-facing tagline

Local-first. Auditable. Human-controlled.

## Alternate technical descriptor

A sovereign-AI reference implementation for controlled, evidence-aware knowledge work.

## Tone

Professional, precise, understated, evidence-led, and candid about prototype limitations. Avoid hype, claims of government endorsement, and claims of production readiness that have not been independently demonstrated.
