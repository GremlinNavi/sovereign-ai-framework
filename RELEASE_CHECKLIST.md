# GitHub release checklist — Release Candidate #3

## Before publishing

- [ ] Review every tracked file and release archive for personal data.
- [ ] Exclude conversation histories, tool audit logs, knowledge files, training/review data, `.env` files, API keys, tokens, and local paths.
- [ ] Build with `requirements-build.lock` and retain the generated `THIRD_PARTY_NOTICES.md` beside every executable.
- [x] Apache-2.0 `LICENSE` added; the repository may be described as open source.
- [ ] Review the project name against the Canadian Trademarks Database before representing it as a protected brand.
- [ ] Confirm public authorship is shown as Zoey Prowse in `AUTHORS.md`, `NOTICE`, and `CITATION.cff`.

## Release

- [ ] Create a version tag, for example `v0.4.0`.
- [ ] Publish release notes stating the prototype status and known limitations.
- [ ] Attach the source archive and, if available, the Windows build.
- [ ] Attach `SHA256SUMS.txt` for every release asset.
- [ ] Mark the release as a pre-release if portability work or security review is incomplete.

## Claims and boundaries

- [ ] Use: “Sovereign AI Demonstrator — Eternal Thread.”
- [ ] Use: “Local-first. Auditable. Human-controlled.”
- [ ] Do not imply Government of Canada ownership, endorsement, procurement status, or production readiness.
- [x] Describe the portable-backend architecture as implemented: adapters, root `config.py`, and static configuration validation are present.
- [ ] Run the complete test suite from `requirements-test.lock` and a Windows build from `requirements-build.lock` before removing pre-release status.
