# OSWAP AI Endpoint Contract

## Status

OSWAP has registered `oswap.ca`, `oswap.jp`, and `oswap.us` for planned future infrastructure.

None of those domains or their OSWAP subdomains is represented by this document as a currently deployed OSWAP website, Git endpoint, API, or other public service. Domain registration and service availability are separate states.

The AI subdomains described here remain design targets until DNS, TLS, edge routing, hosting, and Git protocol handling have been deployed and tested for each endpoint.

Until then, current installation and repository instructions should use verified GitHub or GitLab repository URLs rather than an OSWAP-owned domain.

## Purpose

The OSWAP AI Demonstrator is intended eventually to be reachable through stable OSWAP-controlled public identities that do not depend on the continued use of any one Git forge.

The planned peer hostnames are:

- `ai.oswap.ca` — planned; not currently represented as online
- `ai.oswap.jp` — planned; not currently represented as online
- `ai.oswap.us` — planned; not currently represented as online

None of these is designated as the primary or canonical country endpoint. They are intended to represent the same project identity through independently addressable OSWAP domains after deployment and verification.

## Browser behavior

An ordinary browser request to a future deployed endpoint should return a human-readable OSWAP AI Demonstrator project page with project status, documentation, source locations, release information, licensing, and integrity information.

## Git behavior

The planned hostnames are intended to support read-only Git Smart HTTP access after deployment and verification.

Documentation and tests that need a deliberately non-operational hostname SHOULD use a reserved example or `.invalid` name rather than a real OSWAP-owned domain. For example:

```text
git clone https://ai.oswap.invalid
git pull https://ai.oswap.invalid main
```

`.invalid` is reserved for names that are intended to be visibly non-operational. The commands above are syntax illustrations only and are not expected to resolve.

After OSWAP infrastructure is actually deployed and independently verified, production documentation may replace the placeholder with the appropriate deployed hostname.

The branch argument is an ordinary Git refspec. `main` is shown because it is the current default branch; documentation should not imply that a branch name is permanently fixed if the repository changes later.

## Initial protocol scope

The first public implementation should be read-only.

Required Git service:

- `git-upload-pack` for clone, fetch, and pull operations.

Not exposed by the initial public endpoint:

- `git-receive-pack` for unauthenticated or general public push operations.

Contributor write access should continue through authenticated repository-host workflows unless a separate, explicitly authenticated write endpoint is designed later.

## Forge independence

GitHub and GitLab are current publication and collaboration hosts. Planned OSWAP-owned domains are future public identities, not currently deployed substitutes for those forge URLs.

The intended future relationship is:

```text
ai.oswap.ca / ai.oswap.jp / ai.oswap.us
        [planned; not currently online]
                    ↓
OSWAP-controlled project identity
                    ↓
Git transport / repository routing
                    ↓
GitHub, GitLab, or another compatible backend
```

Changing a backend should eventually not require changing the public OSWAP endpoint advertised to users.

## Peer-domain principle

The planned `.ca`, `.jp`, and `.us` endpoints are peers rather than a primary-and-mirror hierarchy. They may eventually route through different infrastructure while presenting equivalent project state.

The implementation must not claim synchronization guarantees that have not been verified. When integrity metadata is exposed publicly, it should identify the commit SHA and, where appropriate, release checksums that users can compare across endpoints.

Domain ownership alone is not evidence that a particular domain or subdomain is operational or that its repository state is equivalent to another endpoint. DNS delegation, TLS, application routing, Git behavior, and content equivalence are separate verification questions.

## Order of Operations repository addressing

OSWAP's broader Twin design explores expression-addressed repository identities. A canonical arithmetic identifier such as `9/3` may be encoded as the DNS-safe label `9d3` where a transport-safe form is required.

Proposed future names under the registered domains include:

```text
repo9d3.oswap.ca   [planned]
repo9d3.oswap.jp   [planned]
repo9d3.oswap.us   [planned]
```

A future PowerShell/Git wrapper may also accept a human-facing form such as:

```text
git pull repo(9/3).oswap.invalid
```

for parser documentation or testing, and then map a validated expression to a configured production hostname only after a deployment profile explicitly supplies one.

These examples are design concepts, not claims that the subdomains or wrapper syntax are currently operational. See the OSWAP Twin Order of Operations documentation for the addressing, subset-selection, provenance, and build-date model.

## Naming

- Initiative: Open-Source World Access Project (OSWAP)
- AI project: OSWAP AI Demonstrator
- Repository slug: `oswap-ai-demonstrator`
- Registered OSWAP domains reserved for future infrastructure: `oswap.ca`, `oswap.jp`, `oswap.us`
- Planned public AI hostnames: `ai.oswap.ca`, `ai.oswap.jp`, `ai.oswap.us`
- Current OSWAP website status: not yet deployed by this project

The endpoint names do not rename the OSWAP AI Demonstrator. They describe planned future OSWAP-controlled addresses.

## Deployment principle

Browser-facing content and Git protocol traffic may eventually share the same hostname, but they are separate request classes. A future edge layer may route ordinary web requests to the project site and Git Smart HTTP requests to a Git-capable backend.

A domain or subdomain MUST NOT be documented as operational until the relevant DNS, TLS, hosting/routing, and application or Git behavior have been tested from an external client.

This document defines an intended future contract only. It does not claim that the OSWAP domains, AI subdomains, or expression-addressed repository subdomains are currently online.
