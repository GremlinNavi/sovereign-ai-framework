# Open-Source World Access Project syntax

OSWAP syntax is a local, declarative command layer for the Open-Source World Access Project.

Version: `0.1.0`

Implemented command forms:

```text
help
help <command>
explain <command>
get oswap syntax
get oswap ai
twin
twin=<PEMDAS>
```

`twin` previews publication to every configured push URL on the Git remote named `twin`. Execution requires `-Execute` plus an explicit `TWIN` confirmation.

`twin=<PEMDAS>` evaluates a restricted arithmetic expression with `+`, `-`, `*`, `/`, `^`, and parentheses. The integer result is the required number of configured twin destinations. The original expression, normalized expression, transport-safe expression ID, and evaluated family value remain distinct provenance fields.

For example, `twin=(9/3)`, `twin=(6/2)`, and `twin=(12/4)` all resolve to family `3`, while preserving different expression identities.

## Installation command contract

The intended global OSWAP installation interface is:

```powershell
oswap install
```

That global command is a planned installer interface and is not yet registered by the current syntax bundle. The implemented local reference dispatcher remains:

```powershell
& .\scripts\Invoke-OSWAP.ps1 help
```

See [OSWAP_INSTALLATION.md](../OSWAP_INSTALLATION.md) for the current manual `gh repo clone` bootstrap procedure, package map, twin-source rules, installer stages, safety requirements, and the distinction between commands implemented now and planned command surfaces.

## Security boundary

Remote syntax data is declarative. OSWAP does not execute arbitrary repository text. The reference dispatcher uses a restricted local parser and never uses `Invoke-Expression` or language `eval` for arithmetic. Publication is preview-first and never force-pushes, resets, cleans, or rewrites history.
