# OSWAP Codebase Record — 2026-09-02

Recorded UTC: 2026-09-03T01:11:05Z
Local project date: 2026-09-02 (America/Toronto)
Record type: OSWAPSACW durable provenance snapshot

## Scope

This record captures the current OSWAP implementation family as developed and validated on September 2, 2026. It distinguishes source that is committed and publishable from local-only or legacy components.

Each source snapshot below identifies the implementation state formally selected for this record. Documentation-only commits may sit on top of a recorded source snapshot without changing the implementation state being cited.

## Source snapshots

| Component | Role | Recorded source commit | Publication state |
| --- | --- | --- | --- |
| `oswap-ai-demonstrator` | OSWAP AI Demonstrator, OSWAP syntax/runtime integration | `b9b1a971f02bc3e15485714af32986b6bfa2fec4` | Existing GitHub and GitLab twin remotes |
| `PS-twin` / OSWAP Twin Transport | Auditable replicated Git transport | `29d8396820a2a6a612937adc54367cdae46a6531` | GitHub canonical slug `GremlinNavi/PS-twin`; GitLab compatibility slug `GremlinNavi-group/git-push-twin` |
| `sovereign-codex-installer` | Windows bootstrap for local Codex + Ollama workflow | `b96304e0937f2df4ee710c87a7e6061cce42cdba` | Existing GitHub and GitLab twin remotes |
| `oswapsacw-chatgpt-plugin` | OSWAP Standard for Auditable Code Workflows plugin | `ef934723f31ec3273f4884d9217318a02231861d` | Local Git repository; no remote configured at record time |
| `ps-twin` | Legacy predecessor / historical GitLab checkout | `1c9783e3ed833adebb52333084d9859964acc7a0` | Legacy; intentionally not mutated by this operation |

## Additional local-only component

`OSWAP Remote PowerShell for Android` is validated local source but was not a Git repository at record time. Its existing OSWAP audit material records APK SHA-256 `2be42898e48b18a5ba533ebee2bbd599fc2c54510413ea6fecb84127eb32339c` and source-archive SHA-256 `072e52da48a3d2af99d748592586b2d26283681e10bbb7d0eb7e748cf576d1d4`.
## Validated behavior

- Sovereign AI: OSWAP syntax self-test passed; Python regression suite passed 28/28 tests after merging the current GitHub `main` update.
- OSWAP Twin Transport: parser/conformance check passed for all 10 PowerShell source files; repository-wide PowerShell parsing also passed.
- Sovereign Codex Installer: `Install-SovereignCodex.ps1` parsed successfully.
- OSWAPSACW plugin: plugin conformance, canonical upload/download intent resolution, and marketplace validation passed.
- All dirty public-repository changes passed `git diff --check`; a basic credential/private-key pattern scan found no hits.

## Implemented OSWAP semantics represented by this snapshot

- `oswap upload twin=<OSWAP-ARITHMETIC>` is the canonical forward-publication spelling in the current tracked implementation.
- `push twin` remains a compatibility alias where documented.
- Twin arithmetic uses the restricted OSWAP grammar rather than arbitrary shell evaluation.
- Replication factors are bounded to the implemented range and fractional factors represent complete-copy selection, never partial repositories/files.
- Publication tooling preserves explicit execution/confirmation gates and verifies the resulting remote commit where implemented.
- OSWAPSACW defines `oswap upload twin=N` and `oswap download twin=N` as canonical user-facing workflow forms.

## Boundaries

This record describes implemented source, not every OSWAP design idea discussed during development. In particular, a generalized `joker` policy grammar and non-Git archival adapters are not claimed as implemented merely by this record.

No force-push, history rewrite, destructive cleanup, credential transfer, or new remote-repository creation is authorized or implied by this record. Existing repository-declared authorship, attribution, and licensing metadata remain authoritative.

## Publication verification rule

For Git transport, prefer exact remote `main` SHA equality with the local record commit. If an authenticated provider API must materialize the same tracked content as a provider-generated commit, the commit SHA may differ; in that case the changed content must be independently verified and the provider commit SHA recorded as transport-equivalent. Any unverified mismatch remains an unresolved audit gap.