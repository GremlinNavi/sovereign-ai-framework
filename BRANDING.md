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

## OSWAP domain status

OSWAP has registered the following domains for planned future project infrastructure:

- `oswap.ca`
- `oswap.jp`
- `oswap.us`

No official OSWAP website, AI endpoint, Git endpoint, API, or other public service on these domains is represented by this repository as currently deployed or online.

Domain registration may be stated as a project fact. Operational claims require separate verification of DNS, TLS, routing/hosting, service behavior, and relevant content state.

## Planned OSWAP AI hostnames

The following names are reserved in project design documents for possible future OSWAP-controlled public identities:

- `ai.oswap.ca` — planned; not currently represented as online
- `ai.oswap.jp` — planned; not currently represented as online
- `ai.oswap.us` — planned; not currently represented as online

These are intended as peer hostnames rather than a primary-and-mirror hierarchy. They do not rename the OSWAP AI Demonstrator and they do not make any national domain the canonical copy.

Documentation must not present these names as usable URLs or current clone targets until the corresponding infrastructure has been deployed and independently tested. Syntax examples that require a deliberately non-operational hostname should use a reserved documentation name such as `ai.oswap.invalid`.

The wider OSWAP Twin design may also reserve expression-addressed names such as `repo9d3.oswap.ca`, `repo9d3.oswap.jp`, and `repo9d3.oswap.us`. Those names remain design examples until individually deployed and verified.

See [OSWAP_AI_ENDPOINTS.md](OSWAP_AI_ENDPOINTS.md) for the endpoint contract and deployment-status rules.

## Documentation languages

Public documentation is implemented in three supported languages:

- English (`en`)
- Canadian French (`fr-CA`)
- Japanese (`ja`)

Official project names, commands, repository slugs, file names, protocol names, hashes, and checksums remain unchanged across translations. English is the technical synchronization source unless a document explicitly states otherwise.

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
- Registered OSWAP domains reserved for future infrastructure: `oswap.ca`, `oswap.jp`, `oswap.us`
- Planned OSWAP AI hostnames: `ai.oswap.ca`, `ai.oswap.jp`, and `ai.oswap.us` (not currently represented as online)
- OSWAP data/discovery specification: OSWAP Database
- Repository identity: oswap-ai-demonstrator

## Federal-facing tagline

Local-first. Auditable. Human-controlled.

## Alternate technical descriptor

A sovereign-AI reference implementation for controlled, evidence-aware knowledge work.

## Tone

Professional, precise, understated, evidence-led, and candid about prototype limitations. Avoid hype, claims of government endorsement, current website/service availability that has not been verified, and claims of production readiness that have not been independently demonstrated.
