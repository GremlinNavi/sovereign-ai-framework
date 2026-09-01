# Privacy and data controls

Eternal Thread is designed to work locally by default. It stores user data outside
the source checkout unless `ETERNAL_THREAD_DATA_DIR` is explicitly configured.

## Choices before processing

The application records granular, revocable consent for local conversation storage,
conversation indexing, knowledge indexing, public-web research, and non-local AI
backends. Conversation and knowledge indexing and web research are disabled by
default. A remote backend is rejected unless it is enabled in configuration and the
user explicitly grants consent at first use.

Chat and embedding backends are independent. Enabling a remote embedding endpoint
can send conversation or knowledge text to that endpoint when indexing is enabled.
Before enabling one, identify the provider, location, retention terms, and any
cross-border transfer safeguards that apply to the deployment.

## Data lifecycle

- Conversation records are local JSONL files and default to a 30-day retention
  period. Configure `ETERNAL_THREAD_RETENTION_DAYS` to a suitable positive value.
- The retrieval index is derived data. Deleting a session also deletes its indexed
  conversation chunks.
- Tool audit records keep only a hash and length for string arguments; prompts,
  search queries, and URLs are not retained in the audit record.
- Safety-event logs record categories and timestamps, not chat content.

The CLI supports `/privacy`, `/consent <purpose>`, `/revoke <purpose>`,
`/export-data [path]`, `/delete-session [id]`, and `/delete-all-data`.

## Deployment assessment

This software does not itself guarantee legal compliance. Legal duties depend on the
operator, jurisdiction, deployment model, data flows, users, and purposes. A commercial
or hosted operator should obtain deployment-specific privacy/legal review and determine
which accountability, transparency, consent, retention, disposal, breach-response,
cross-border-transfer, and security-safeguard obligations apply.

Use full-disk encryption and operating-system account protections for sensitive local
data; the project does not implement custom cryptography. See
[REGULATORY_ALIGNMENT.md](REGULATORY_ALIGNMENT.md) for a non-authoritative engineering
traceability note covering selected proposed Canadian requirements.
