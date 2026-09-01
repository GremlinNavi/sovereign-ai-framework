# v0.4.0-rc4 — Release Candidate #4

Eternal Thread v0.4.0-rc4 is a source release candidate for review. It remains a
portable, local-first demonstrator rather than a stable or production release. It is
not a Government of Canada product, service, endorsement, procurement,
certification, or deployment.

## Highlights

- Adds a small, auditable Windows PowerShell bootstrap that creates a project-local
  Python virtual environment, installs only the selected Python dependencies, and
  validates the project configuration.
- Adds a separate guarded update helper for existing Git checkouts. It verifies a
  recognized remote, refuses a dirty working tree, and uses only a fast-forward pull.
  It does not reset, force-push, create commits, or change branches.
- Makes the Ollama Python client an explicit installer option. The base package
  supports the `openai_compatible` adapter without that optional client; neither
  option installs an inference runtime or model weights.
- Documents Windows setup and the boundary between PowerShell orchestration,
  project configuration, the local runtime, and model selection.
- Updates release metadata for `v0.4.0-rc4` / `0.4.0rc4` and preserves the RC3
  retained-input record separately.

## Deliberate boundaries

The bootstrap does not alter a system execution policy, install Python globally,
overwrite `.env`, download models, install or start Ollama (or another runtime),
select a backend, or silently redirect work to a remote service. A configured local
backend remains the default; non-local use retains its explicit opt-in and consent
requirements.

The project implements configurable, replaceable backends; it does not claim live
runtime hot-swapping, universal hardware support, model equivalence, or support for
specific third-party operating systems, compatibility layers, or devices unless
those claims are separately tested and documented.

## Candidate provenance and review

This candidate is a reviewed source change on top of the public-safe RC3 source
candidate. It is not evidence of a `v0.4.0-rc4` tag, hosted release, executable,
source ZIP, or checksum manifest. Do not reuse the RC3 retained-input checksum as a
hash for RC4 assets.

Before a hosted pre-release is created, run the full test suite and public-release
readiness audit from the exact reviewed Git commit, build and smoke-test any intended
asset, calculate its SHA-256 value, and record the actual host references and
verification evidence in `PROVENANCE.md` and `docs/archive/v0.4.0-rc4.md`.

See `WINDOWS_INSTALL.md`, `PUBLIC_RELEASE_GUIDE.md`, `RELEASE_CHECKLIST.md`, and
`DEVELOPMENT_ATTRIBUTION.md`.
