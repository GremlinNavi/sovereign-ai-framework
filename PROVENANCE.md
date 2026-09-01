# Release provenance — v0.4.0-rc4

This file separates the retained RC3 input archive from the current RC4
source-candidate record and any later final public-release record. It is a
release-preparation record, not proof that a tag, repository, or hosted release has
already been made public.

## Declared retained base — owner verification required

- Source archive: `sovereign-ai-demonstrator-eternal-thread-v0.4.0-rc3-nemi-safety-hardened.zip`
- Source SHA-256: `7D23EEF377CA826968953572C73FDD733547E78F61988973DAB0850C9169F141`
- Maintainer/creator identity in project metadata: Nemi Prowse
- Retained-base release line: `v0.4.0-rc3` / Python package version `0.4.0rc3`

This record identifies the claimed retained base for the release-preparation work.
The named archive and its hash have not been independently verified in this workspace;
the owner must validate them against their retained original. Older
`c34-c36-alignment` archives are not identified here as replacement source trees.
Even if verified, the retained-base checksum does **not** identify a later rebuilt
source archive, Git tag, Windows build, or hosted release asset.

The supplied source ZIP examined for the public-source import is recorded separately
in [docs/archive/v0.4.0-rc3.md](docs/archive/v0.4.0-rc3.md). It has a different
filename and SHA-256 value, so this document deliberately makes no claim that the two
archives are interchangeable or that either one is a final hosted release asset.

## Historical retained-base notes — not a final release diff

The following notes describe the earlier canonicalization pass recorded with the
retained base. They are not a complete account of the current staging tree or the
final public release, and they must not be read as a statement that the final release
has no behavior changes:

1. Removes the accidentally packaged `.pytest_cache/` directory.
2. Removes an inaccurate release-note claim that `is_local_endpoint` had been newly exported; the retained project lineage already exported it.
3. Updates security-reporting wording so it remains accurate for an already-public repository.
4. Updates the README release-preparation wording and links this provenance record.
5. Preserves `REGULATORY_ALIGNMENT.md`, including the C-34/C-36 engineering traceability material.

The final release may include additional release-hygiene, documentation, dependency,
test, build, or application changes. Record the actual final diff in the next section
after the intended public baseline and tagged commit are known.

## Current RC4 source-candidate scope

RC4 adds a small opt-in Windows PowerShell bootstrap and guarded update workflow,
plus related documentation and release metadata. It is a source candidate only: no
`v0.4.0-rc4` tag, hosted source archive, executable, or checksum manifest is claimed
by this file. The retained RC3 archive hash above is not an RC4 asset hash.

## Final-diff and change-impact record — maintainer completion required

- Public comparison baseline (repository URL and commit/tag): `[TO BE COMPLETED]`
- Exact final public-release commit (full Git object ID): `[TO BE COMPLETED]`
- Concise final change summary against that baseline: `[TO BE COMPLETED]`
- Behavior-impact statement (including “documentation/release metadata only” only if true): `[TO BE COMPLETED]`
- Diff/review evidence (for example, reviewed compare URL or commit range): `[TO BE COMPLETED]`

Do not reuse the historical five-item note above as this summary. Derive the record
from the actual final repository history and reviewed changes.

## Final public-release provenance — maintainer completion required

Complete this section only after the final public-release commit has been reviewed,
the tag resolves to that exact commit, and the final assets have been generated.
Use the full commit ID and hashes calculated from the assets actually uploaded. Do
not copy the retained-base hash above into this section.

- Public repository URL: `[TO BE COMPLETED BEFORE PUBLIC RELEASE]`
- Release tag: `[TO BE COMPLETED; expected release candidate tag: v0.4.0-rc4]`
- Tag target commit (full Git object ID): `[TO BE COMPLETED]`
- Commit URL or immutable host reference: `[TO BE COMPLETED]`
- Final change summary and behavior-impact record completed: `[TO BE COMPLETED]`
- Source release asset filename: `[TO BE COMPLETED]`
- Source release asset SHA-256: `[TO BE COMPLETED]`
- Windows build asset filename and SHA-256 (if published): `[TO BE COMPLETED OR NOT PUBLISHED]`
- Checksum manifest filename and SHA-256: `[TO BE COMPLETED]`
- Final verification evidence (test command/result, archive smoke test, and date): `[TO BE COMPLETED]`
- Tag/commit signing status, if used: `[TO BE COMPLETED OR NOT USED]`

Publication gate: do not publish or announce the release until the tag, tag target
commit, and every asset hash above have been checked against the actual final
artifacts. Keep this record with the release notes and `SHA256SUMS.txt` so third
parties can identify exactly what was released.

## Verification policy

Release assets should be accompanied by a SHA-256 checksum for the final ZIP/build
and a manifest of the files contained in it. The source tree remains licensed under
Apache License 2.0 as stated in `LICENSE` and `NOTICE`. The release does not bundle
an inference runtime or model weights: a Python virtual environment supplies only
the project’s Python dependencies; operators separately choose and manage compatible
local runtimes and models. The project has no automatic cloud fallback.
