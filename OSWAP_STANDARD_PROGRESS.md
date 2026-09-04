# OSWAP Standard — Implementation Progress

SPDX-License-Identifier: Apache-2.0

Status: working progress record; non-normative  
Reviewed: 2026-09-02  
Project: Open-Source World Access Project (OSWAP)

This document records the current implementation boundary of the OSWAP Standard and the next syntax direction. It does not supersede `OSWAP_STANDARD.md` version 0.2.0.

## 1. Current normative baseline

OSWAP Standard 0.2.0 is implemented as a domain-specific language hosted by PowerShell.

PowerShell is the reference host, launcher, prompt surface, and implementation environment. OSWAP arithmetic is parsed by OSWAP itself rather than delegated to PowerShell evaluation.

The current public implementation supports restricted arithmetic using decimal numbers, parentheses, `^`, `*`, `/`, `+`, `-`, and unary signs.

The current implementation preserves the distinction between raw expression, normalized expression, transport-safe expression identifier, and evaluated replication factor.

## 2. Implemented 0.2 command surface

The current dispatcher recognizes forms including:

```text
help
help <command>
explain <command>
get oswap syntax
get oswap ai
preserve
upload twin
upload twin=<OSWAP-ARITHMETIC>
push twin
push twin=<OSWAP-ARITHMETIC>
```

## 3. Canonical forward upload syntax

The intended canonical publication form is now:

```text
oswap upload twin=N
```

`twin` is the OSWAP replication operator. `N` specifies the requested replication factor or an OSWAP arithmetic expression that resolves to that factor.

Examples:

```text
oswap upload twin=1
oswap upload twin=2
oswap upload twin=(9/3)
oswap upload twin=4*(15-(2^3-5))+18/3^2
```

For an integer result, OSWAP selects that many eligible destinations without replacement. `twin=1` therefore requests one complete build upload to one eligible destination selected by the OSWAP distribution policy.

The dispatcher and command definition now accept `upload twin=N` as the canonical forward spelling. The 0.2 `push twin=<OSWAP-ARITHMETIC>` form remains an implemented compatibility alias until a later normative standard explicitly decides its long-term status.

## 4. Replication names and dictionary aliases

Human-facing multiplicity words may resolve through the OSWAP dictionary layer to the same canonical replication cardinality.

```text
twin       -> 2
triplet    -> 3
quadruplet -> 4
quintuplet -> 5
```

Named multiplicities are aliases, not separate execution engines. Internally, implementations should normalize them to a numeric replication value before destination selection.

The dictionary layer is intended to support additional human-language and multilingual aliases while preserving one canonical machine meaning.

## 5. Fractional replication compatibility

OSWAP Standard 0.2 permits non-integer replication factors in the implemented range from `1` through `1024`.

For a value `n + f`, where `n = floor(value)` and `0 <= f < 1`:

- `n` complete copies are guaranteed;
- one additional complete copy is selected with probability `f`;
- no partial repository or partial file is created.

Example:

```text
oswap upload twin=(4+3)/2
```

Under the current 0.2 semantics, this resolves to `3.5`: three complete destinations are guaranteed and a fourth complete destination is selected with 50% probability.

A future normative revision should explicitly state whether `upload twin=N` preserves these fractional semantics unchanged.

## 6. Informed-consent execution model

Consequential OSWAP operations are preview-first and human-authorized.
Before a remote write, the implementation should disclose the material consequences of the operation, including the source state, eligible destination pool, resolved replication factor, selected destinations, and any relevant warnings.

The user must retain a normal cancellation path. Absence of affirmative authorization must be treated as denial.

The current 0.2 twin implementation already requires explicit execution mode and a terminal confirmation before publication. The longer-term standard is intended to generalize this into a consistent Y/N informed-consent layer for consequential OSWAP actions.

The intended sequence is:

```text
proposal
-> consequence preview
-> safety / policy / jurisdiction notices
-> human authorization
-> constrained execution
-> verification
-> provenance record
```

AI suggestions do not replace human authorization.

## 7. Local, model-agnostic AI integration

The Sovereign AI Framework already separates logical backend selection from provider-specific adapters. Current adapters include Ollama and OpenAI-compatible endpoints.

The OSWAP direction is to expose AI capabilities through stable OSWAP semantics while permitting inference to remain local and model-agnostic.

The PowerShell terminal can therefore act as the control and consent surface while inference is performed by an interchangeable local runtime.

OSWAP should not require centralized inference infrastructure merely to interpret or execute standard commands.

## 8. Dictionary and semantic database direction

The current OSWAP Database document defines a planned open, auditable catalogue with SQLite as the initial canonical local format and JSONL as the portable interchange format.

The dictionary/LLM integration is a next-layer design rather than a completed database implementation.

Its intended role is semantic normalization:

```text
human language / localized term
-> dictionary concept
-> canonical OSWAP semantic identifier
-> validated parameters
-> PowerShell-hosted execution
```

This allows aliases such as `triplet` and natural-language requests such as “upload to three repositories” to resolve to the same canonical operation without allowing the LLM to invent execution semantics.

Dictionary data should be declarative, versioned, attributable, and separable from model instructions.

## 9. Provenance and developer identity direction

Current OSWAP code already records expression provenance fields and SHA-256 integrity information in relevant workflows.

The proposed developer-identity layer extends this with uniquely minted, human-readable PEMDAS/Order-of-Operations identifiers backed by a cryptographic identity rather than treating the arithmetic result itself as a secret or authentication credential.

Blockchain or transparency-log anchoring is a planned provenance mechanism, not a currently implemented requirement of Standard 0.2.0.

The intended provenance record should distinguish at minimum:

```text
who proposed an action
who authorized it
what command was resolved
what sources or warnings were presented
what artifact was acted on
where it was sent
what result was verified
```

## 10. Jurisdiction-aware AI preflight direction

A planned OSWAP AI terminal capability is to identify potentially relevant jurisdictional, licensing, privacy, security, and software-distribution considerations before consequential publication.

The AI should operate as an issue-spotting and source-explanation layer, not as an autonomous legal authority.

A jurisdiction notice should preserve the distinction between enacted law, regulation, regulatory guidance, standards, project policy, and unresolved AI inference.

The developer retains the final decision and OSWAP records the decision context when provenance logging is enabled.

## 11. Preservation and archival direction

The implemented preservation workflow separates preservation from publication, hashes source material, encrypts sensitive packages before optional replication, and fails closed before plaintext publication.

Future distributed archival work may combine repository replication, content hashes, signed console-event records, transparency logs, and optional blockchain anchoring without placing raw sensitive console data directly on a public ledger.

## 12. Current implementation status

| Capability | Status on 2026-09-02 |
| --- | --- |
| OSWAP DSL boundary | Implemented/documented in 0.2.0 |
| Restricted OSWAP arithmetic parser | Implemented |
| `^` exponentiation semantics | Implemented |
| Expression provenance fields | Implemented |
| Semi-random twin destination selection | Implemented |
| Fractional replication factor | Implemented |
| Preview-first publication | Implemented |
| Explicit publication confirmation | Implemented |
| SHA-256 preservation manifest | Implemented |
| Encrypted preservation workflow | Implemented |
| Canonical config bridge | Implemented |
| Syntax self-test / CI exercise | Implemented |
| Model-agnostic backend abstraction | Implemented in Sovereign AI Framework |
| `oswap upload twin=N` spelling | Implemented as a forward-compatible alias; normative promotion pending |
| `triplet` / `quadruplet` / `quintuplet` dictionary aliases | Planned |
| Multilingual dictionary semantic resolver | Planned |
| Full OSWAP catalogue/database ingestion stack | Planned |
| Jurisdiction-aware AI preflight | Planned |
| PEMDAS developer identity minting | Planned |
| Blockchain/transparency provenance anchoring | Planned |
| OSWAP-controlled public AI/Git endpoints | Planned deployment |

## 13. Repository review notes
The public `GremlinNavi/oswap-ai-demonstrator` history includes Standard 0.2.0, parser corrections, syntax self-tests, canonical configuration work, fractional twin replication, preservation workflows, and expression-preview fixes.

On YETI-2, `oswap-ai-demonstrator-src` is currently one local commit ahead of GitHub `origin/main`; that local commit is a branding/documentation cleanup and does not replace Standard 0.2.0.

The active GitLab `GremlinNavi-group/git-push-twin` history has adopted the OSWAP 0.2 twin layer and contains the newer expression-preview work.

The YETI-2 checkout at `C:\Users\kmlpr\ps-twin` is currently behind its configured origin by 33 commits and still points to the older `eternal-thread-group/ps-twin.git` remote path. It should not be treated as the source of truth until its remote configuration and history are intentionally reconciled.

The standalone Sovereign Codex installer exists as a separate repository and is not part of the OSWAP language definition itself.

## 14. Recommended next standardization steps

1. Define `oswap upload twin=N` in the next normative OSWAP Standard revision.
2. Decide whether `push twin` remains a deprecated compatibility alias or a permanent lower-level transport alias.
3. Promote `upload twin=N` from forward-compatible implementation to normative syntax in the next standard revision.
4. Expand conformance tests for direct integers, integer expressions, fractional expressions, invalid factors, and alias equivalence.
5. Define the dictionary schema separately from executable handlers.
6. Define multiplicity aliases as semantic data rather than separate PowerShell functions.
7. Define a machine-readable informed-consent manifest for consequential operations.
8. Define provenance records independently from any particular blockchain or transparency-log backend.
9. Add jurisdiction-aware notices only after a source/version/status model is specified.
10. Keep implementation status explicit so planned infrastructure is never represented as deployed functionality.

## 15. Compatibility principle

OSWAP syntax should remain stable at the semantic layer even when the underlying Git forge, local AI model, inference runtime, archive backend, or operating system changes.

The standard describes intent and machine meaning; PowerShell is the first reference host rather than the permanent limit of the protocol.
