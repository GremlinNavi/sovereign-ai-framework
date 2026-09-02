# OSWAP AI Endpoint Contract

## Status

Planned infrastructure. The public endpoints described here are design targets until DNS, TLS, edge routing, and Git protocol handling have been deployed and tested.

## Purpose

The Sovereign AI Demonstrator is intended to be reachable through stable OSWAP-controlled public identities that do not depend on the continued use of any one Git forge.

The planned peer endpoints are:

- `https://ai.oswap.ca`
- `https://ai.oswap.us`

Neither endpoint is designated as the primary or canonical country endpoint. They are intended to represent the same project identity through independently addressable OSWAP domains.

## Browser behavior

An ordinary browser request to either endpoint should return a human-readable Sovereign AI Demonstrator project page with project status, documentation, source locations, release information, licensing, and integrity information.

## Git behavior

The same hostnames are intended to support read-only Git Smart HTTP access. After deployment and verification, the user-facing interface should support commands such as:

```text
git clone https://ai.oswap.ca
git clone https://ai.oswap.us
```

and, from an existing Git working tree:

```text
git pull https://ai.oswap.ca main
git pull https://ai.oswap.us main
```

The branch argument is an ordinary Git refspec. `main` is shown because it is the current default branch; documentation should not imply that a branch name is permanently fixed if the repository changes later.

## Initial protocol scope

The first public implementation should be read-only.

Required Git service:

- `git-upload-pack` for clone, fetch, and pull operations.

Not exposed by the initial public endpoint:

- `git-receive-pack` for unauthenticated or general public push operations.

Contributor write access should continue through authenticated repository-host workflows unless a separate, explicitly authenticated write endpoint is designed later.

## Forge independence

GitHub and GitLab are publication and collaboration hosts, not the permanent public identity of the project.

The intended relationship is:

```text
ai.oswap.ca / ai.oswap.us
        ↓
OSWAP-controlled project identity
        ↓
Git transport / repository routing
        ↓
GitHub, GitLab, or another compatible backend
```

Changing a backend should not require changing the public OSWAP endpoint advertised to users.

## Twin-domain principle

The `.ca` and `.us` endpoints are peers rather than a primary-and-mirror pair. They may initially route through different infrastructure while presenting equivalent project state.

The implementation should not claim synchronization guarantees that have not been verified. When integrity metadata is exposed publicly, it should identify the commit SHA and, where appropriate, release checksums that users can compare across endpoints.

## Naming

- Initiative: Open-Source World Access Project (OSWAP)
- AI project: Sovereign AI Demonstrator
- Repository slug: `sovereign-ai-framework`
- Planned public endpoints: `ai.oswap.ca` and `ai.oswap.us`

The endpoint names do not rename the Sovereign AI Demonstrator. They provide stable OSWAP-controlled addresses for it.

## Deployment principle

Browser-facing content and Git protocol traffic may share the same hostname, but they are separate request classes. The edge layer should route ordinary web requests to the project site and Git Smart HTTP requests to a Git-capable backend.

This document defines the intended public contract only. It does not claim that the endpoints are operational until they have been deployed and tested with real `git clone`, `git fetch`, and `git pull` commands.
