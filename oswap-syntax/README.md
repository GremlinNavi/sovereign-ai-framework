# Open-Source World Access Project language syntax

OSWAP is a domain-specific programming language (DSL) for expressing auditable digital access, repository transport, preservation, authorization, and accountability operations.

This directory contains the reference language syntax bundle for the Open-Source World Access Project. PowerShell is one supported host and implementation surface; it does not define OSWAP grammar or semantics.

Version: `0.2.0`

The normative project rules are defined in [`../OSWAP_STANDARD.md`](../OSWAP_STANDARD.md). Design rationale and social/safety intent are recorded in [`../OSWAP_INTENT.md`](../OSWAP_INTENT.md).

## Language status

OSWAP is not merely a Git naming convention, a PowerShell wrapper, a shell alias collection, or a list of command names. A conforming OSWAP implementation is expected to recognize OSWAP tokens and keywords, parse OSWAP expressions with OSWAP-defined precedence and semantics, map valid command forms to defined operations, keep host-language behavior behind an explicit language boundary, and validate implemented behavior with conformance tests.

OSWAP is domain-specific rather than general-purpose: its language surface is intentionally focused on auditable access, authorization, replication, preservation, provenance, and related digital-accountability workflows.

Implemented command forms:

```text
help
help <command>
explain <command>
get oswap syntax
get oswap ai
preserve
twin
twin=<OSWAP-ARITHMETIC>
upload twin
upload twin=<OSWAP-ARITHMETIC>
push twin
push twin=<OSWAP-ARITHMETIC>
```

`upload twin` is the canonical forward publication spelling. `push twin` remains a compatibility alias. Both preview publication to every configured push URL on the Git remote named `twin`. Execution requires `-Execute` plus an explicit `TWIN` confirmation.

`upload twin=<OSWAP-ARITHMETIC>` (and the compatibility alias `push twin=<OSWAP-ARITHMETIC>`) evaluates a restricted OSWAP arithmetic expression with `+`, `-`, `*`, `/`, `^`, unary signs, and parentheses. OSWAP owns this grammar; PowerShell does not define the expression semantics.

Positive fractional results are valid replication factors. A value of `3.5` means three guaranteed whole destination copies plus a 50% probability of one additional whole destination copy. It never means half a repository or half a file.

For example:

```text
oswap upload twin=(4+3)/2
```

resolves to `3.5` and selects destinations without replacement from the configured eligible `twin` push URL pool.

`preserve` launches the PowerShell-prompt-only sensitive-record preservation workflow. It preserves source bytes, creates a SHA-256 manifest, encrypts the package through the external `age` tool before any optional remote replication, and keeps sensitive descriptions out of Git-facing metadata.

## Installation command contract

The intended global OSWAP installation interface is:

```powershell
oswap install
```

That global command is a planned installer interface and is not yet registered by the current syntax bundle. The implemented local reference dispatcher remains:

```powershell
& .\scripts\Invoke-OSWAP.ps1 help
```

See [OSWAP_INSTALLATION.md](../OSWAP_INSTALLATION.md) for the current manual bootstrap procedure, package map, twin-source rules, installer stages, and safety requirements.

## Security boundary

Remote syntax data is declarative. OSWAP does not execute arbitrary repository text. The reference dispatcher uses a restricted local parser and never uses `Invoke-Expression` or language `eval` for arithmetic.

Publication is preview-first and never force-pushes, resets, cleans, or rewrites history.

The preservation workflow does not promise invisibility from spyware or privileged monitoring. It refuses to weaken antivirus, logging, or other operating-system security controls and instructs users to move to a trusted device if compromise is suspected.
