# Release checklist — Release Candidate #3

## Before publishing

- [ ] Review every tracked file and release archive for personal data.
- [ ] Exclude conversation histories, tool audit logs, knowledge files, training/review data, `.env` files, API keys, tokens, and local paths.
- [ ] Confirm `app/`, `tests/`, and `tools/` are tracked source directories; do not publish them only inside a ZIP archive.
- [ ] Confirm generated ZIPs, executables, and SHA-256 manifests are absent from the default branch and will be uploaded only as release assets.
- [ ] Ensure the GitHub Actions `CI` workflow passes on the release commit.
- [ ] Ensure the GitLab Python CI jobs pass on the release commit when the GitLab twin is used for release validation.
- [ ] Run a repository-wide identity check so README, NOTICE, AUTHORS, CITATION, package metadata, and forge descriptions agree.
- [ ] Build with `requirements-build.lock`; the build generates and places `THIRD_PARTY_NOTICES.md` beside every executable.
- [x] Apache-2.0 `LICENSE` added; the repository may be described as open source.
- [ ] Review the project name against the Canadian Trademarks Database before representing it as a protected brand.
- [ ] Confirm public authorship is shown consistently in `AUTHORS.md`, `NOTICE`, and `CITATION.cff`.

## Release

- [ ] Create a version tag, for example `v0.4.0`.
- [ ] Publish release notes stating the prototype status and known limitations.
- [ ] Attach the source archive and, if available, the Windows build.
- [ ] Generate and attach `SHA256SUMS.txt` for every release asset after the final assets are built.
- [ ] Mark the release as a pre-release if portability work or security review is incomplete.

## Claims and boundaries

- [ ] Use: “OSWAP AI Demonstrator.”
- [ ] Use: “Local-first. Auditable. Human-controlled.”
- [ ] Do not imply Government of Canada ownership, endorsement, procurement status, or production readiness.
- [x] Describe the portable-backend architecture as implemented: adapters, root `config.py`, and static configuration validation are present.
- [ ] Run `build_windows.bat`, which installs the locked build/test environments, runs the test suite, and creates the Windows package, before removing pre-release status.
