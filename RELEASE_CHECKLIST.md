# GitHub release checklist — v0.4.0-rc3

## How to use this checklist

`[x]` records a fact already present in this release-preparation source tree. It is
not a confirmation that a public repository, release asset, account setting, or legal
decision is ready. `[ ]` is a maintainer gate: do not mark it complete until the
named real-world review or action has occurred for the exact repository and release
being published.

## Release-preparation artifact facts

- [x] Apache-2.0 `LICENSE`, `NOTICE`, `IP_POLICY.md`, `TRADEMARKS.md`, and `DCO.md` are present.
- [x] Package and citation metadata identify this build as a release candidate rather than stable `v0.4.0`.
- [x] `REGULATORY_ALIGNMENT.md` distinguishes engineering alignment from legal compliance or certification.
- [x] Release documentation describes the portable, local-first architecture and its no-endorsement boundary.
- [x] Release documentation distinguishes virtual-environment Python dependencies from separately managed runtimes and model weights, and states that there is no automatic cloud fallback.
- [x] `THIRD_PARTY_NOTICES.md` and `SBOM.cdx.json` are present in this preparation tree.
- [x] The Windows build script generates notices/SBOM from its locked build environment and copies the licensing, safety, privacy, configuration, and release-readme materials beside the executable; it does not bundle an inference runtime or model weights.
- [x] The pull-request CI workflow checks DCO `Signed-off-by:` trailers on every proposed commit.

## Maintainer gates before first public access

- [ ] Review every tracked file and release archive for personal data.
- [ ] Exclude conversation histories, tool audit logs, knowledge files, training/review data, `.env` files, API keys, tokens, and local paths.
- [ ] Review the complete Git history, branches, tags, releases, release assets, forks, and CI/Actions logs—not only the current working tree—for material that must remain private.
- [ ] If history cannot safely be made public, prepare a clean source-only public repository or clean public history; do not publish a private development history by accident.
- [ ] Confirm public authorship in `AUTHORS.md`, `NOTICE`, and `CITATION.cff` is the identity the creator wants permanently associated with the public project.
- [ ] Enable GitHub Private Vulnerability Reporting and verify `SECURITY.md` matches the repository's actual reporting path.
- [ ] Review the project name against the Canadian Trademarks Database before representing it as a protected brand.
- [ ] Make and record the patent/public-disclosure decision before this public disclosure; obtain appropriate advice if needed.
- [ ] Confirm each contributor has signed off under `DCO.md` and that required employment, contractor, or assignment records are retained privately.
- [ ] Regenerate `THIRD_PARTY_NOTICES.md` and `SBOM.cdx.json` from a clean, reviewed version-pinned environment.
- [ ] Confirm every source file has the project copyright/SPDX header or a documented third-party notice.
- [ ] Confirm test fixtures, screenshots, sample data, documentation, and generated assets contain no sensitive or third-party material that lacks permission for public release.

## Verification gate — repeat on the exact final source tree

From a clean Python environment:

```bash
python -m venv .venv
# activate the environment for your platform
pip install -r requirements-test.lock
python -m compileall -q app tests config.py launcher.py
python config.py --validate
pytest -q
```

For a Windows executable:

```text
pip install -r requirements-build.lock
build_windows.bat
```

- [ ] Complete test suite passes with the locked test environment.
- [ ] Windows build completes on a clean supported Windows environment.
- [ ] Generated `THIRD_PARTY_NOTICES.md` and `SBOM.cdx.json` are retained beside every executable and source archive.
- [ ] Smoke-test the exact release archive/build, not only the working tree.
- [ ] Run `tools/Test-PublicReleaseReadiness.ps1 -Version v0.4.0-rc3 -RequireClean` from inside the actual Git repository. Treat warnings as human-review work; this read-only audit is not proof that no sensitive data exists.
- [ ] Re-run the read-only readiness audit with the final `SHA256SUMS.txt` and each final release asset before upload and after download verification.

## Final provenance gate

- [ ] Create the final release assets from the exact reviewed commit.
- [ ] Calculate SHA-256 for every final release asset and write the values to `SHA256SUMS.txt`.
- [ ] Complete the actual final-diff and behavior-impact record in `PROVENANCE.md` from the intended public baseline and exact final commit; do not reuse historical retained-base notes as the release diff.
- [ ] In `PROVENANCE.md`, replace the final-public-release placeholders with the public repository URL, exact tag, full tag target commit ID, asset filenames, and SHA-256 values.
- [ ] Independently compare every uploaded release asset with its published SHA-256 value.

## Git and hosted-release gate

- [ ] Create tag `v0.4.0-rc3`.
- [ ] Record the full commit ID resolved by `v0.4.0-rc3` in `PROVENANCE.md` before publishing the release.
- [ ] Configure or re-check public branch and tag protections appropriate to the chosen host after the repository becomes public; do not assume private-repository rules remain in force.
- [ ] Mark the GitHub Release as a **pre-release**.
- [ ] Publish release notes stating prototype status and known limitations.
- [ ] Attach the source archive and, if available, the Windows build.
- [ ] Attach `SHA256SUMS.txt` containing SHA-256 hashes for every release asset.
- [ ] Verify each uploaded asset against the published checksum after upload.

## Claims and boundaries

- [ ] Use: “Sovereign AI Demonstrator — Eternal Thread.”
- [ ] Use: “Local-first. Auditable. Human-controlled.”
- [ ] Describe C-34/C-36 work as engineering alignment or controls informed by proposed legislation—not certification, legal advice, or guaranteed compliance.
- [ ] Do not imply Government of Canada ownership, endorsement, procurement status, certification, or production readiness.
- [x] Describe the portable-backend architecture as implemented: adapters, root `config.py`, and static configuration validation are present.
- [x] State that virtual environments provide Python dependency isolation only; inference runtimes and model weights remain separately managed.
- [x] State that there is no automatic runtime installation, model download, or cloud fallback.
- [ ] Reserve stable tag `v0.4.0` until the complete test suite, Windows build, release-asset smoke test, and security review appropriate to the intended release scope are complete.
