# Security policy

Eternal Thread is a local-first demonstrator, not a network service. Keep it bound to
your machine and do not expose its web-research tools or backend endpoint to untrusted
networks without a separate security review.

## Supported release status

`v0.4.0-rc4` is a pre-release. Security controls are implemented and tested as an
engineering baseline, but the project has not completed an independent security
assessment and is not represented as production-ready.

## Reporting a vulnerability

Repository maintainers should enable GitHub Private Vulnerability Reporting under
the repository Security settings. Once enabled, use
**Security → Report a vulnerability** to send exploit details privately.

Do not post active exploit details, secrets, personal data, or proof-of-concept payloads
in a public issue. If private vulnerability reporting is not available yet, open a
public issue containing only a short request for a private security contact channel; do
not include vulnerability details until a private channel is available.

A useful report should include the affected version, component, impact, reproduction
conditions, and the minimum information needed to validate the issue. Please avoid
accessing data that is not yours or causing unnecessary service disruption.

## Current boundary

The web tool rejects non-HTTP(S) URLs, embedded credentials, and resolved private or
reserved addresses. Redirect destinations are revalidated and response sizes are
bounded. DNS can change between validation and connection, so these are
application-layer mitigations—not a complete SSRF boundary.

A hosted deployment needs additional controls such as network egress filtering,
destination allow-listing or connection-level address pinning, authentication,
authorization, rate limiting, secret management, monitoring, and independent threat
modelling.
