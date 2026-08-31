# Security policy

Eternal Thread is a local-first demonstrator, not a network service. Keep it bound to
your machine and do not expose its web-research tools or backend endpoint to untrusted
networks without a separate security review.

The web tool rejects non-HTTP(S) URLs, embedded credentials, and resolved private or
reserved addresses. DNS can change between validation and connection, so this is an
application-layer mitigation—not a complete SSRF boundary. A hosted deployment needs
network egress controls, destination allow-listing or connection-level address pinning,
authentication, and independent threat modelling.

Report a suspected vulnerability privately to the repository maintainer. Do not post
active exploit details in a public issue before a fix is available.
