# Security policy

Sovereign AI Demonstrator is a local-first demonstrator, not a network service. Keep it bound to
your machine and do not expose its web-research tools or backend endpoint to untrusted
networks without a separate security review.

## Supported versions

Security fixes are considered for the most recent `0.4.x` release or release candidate.
Older releases may require upgrading before a fix is available.

## Reporting a vulnerability

Use the repository's [private security-advisory reporting channel](https://github.com/GremlinNavi/sovereign-ai-framework/security/advisories)
when it is available. If private reporting has not been enabled by the maintainer,
open an issue containing only a request for a private contact channel—do not include
exploit details.

Include the affected version or commit, a minimal reproduction, impact, and any proposed
mitigation. The maintainer will acknowledge reports as soon as practical and coordinate
disclosure after users have a reasonable opportunity to update.

## Deployment boundary

The web tool accepts only public HTTP(S) destinations and rejects embedded credentials
and resolved non-public addresses. DNS can still change between validation and connection,
so this is an application-layer mitigation—not a complete SSRF boundary. A hosted
deployment needs network egress controls, destination allow-listing or connection-level
address pinning, authentication, logging controls, and independent threat modelling.
