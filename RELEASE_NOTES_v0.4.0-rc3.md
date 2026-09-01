# v0.4.0-rc3 — Release Candidate #3

Eternal Thread v0.4.0-rc3 is a public-source release candidate for the portable,
local-first AI research framework. It is a pre-release and is not represented as a
stable production deployment, Government of Canada product, endorsement, procurement,
or certification.

## Highlights

- Granular, revocable consent for local storage, conversation indexing, knowledge
  indexing, web research, and non-local AI backends.
- Retention, export, session deletion, whole-data deletion, and deletion of derived
  conversation retrieval chunks.
- Replaceable inference-backend interface with Ollama and OpenAI-compatible adapters.
- Evidence assessment with provenance, contradictions, evidence gaps, separate
  confidence dimensions, and mandatory human review before publication.
- Web-request security controls including URL validation, redirect revalidation,
  private/reserved-address rejection, bounded response bodies, and tool-call limits.
- Digital-safety baseline covering crisis signals, actionable interpersonal-violence
  requests, explicit relationship manipulation, and false professional-authority claims,
  plus local content-free unsafe-response reporting.
- Safety matching now normalizes whitespace and Unicode compatibility forms, while mild
  synthetic regression fixtures use opaque case IDs to reduce unnecessary reviewer exposure.
- `REGULATORY_ALIGNMENT.md` maps selected engineering controls to selected provisions
  of proposed Canadian Bills C-34 and C-36 while documenting residual gaps and avoiding
  claims of legal compliance.
- Release metadata consistently identifies this build as `v0.4.0-rc3` / `0.4.0rc3`.
- Ollama adapter now fails cleanly when its Python client is absent rather than failing
  module import, improving backend isolation and testability.
- A Python virtual environment isolates application dependencies and adapter clients;
  it does not install an inference service, download model weights, or select a model.
  Operators choose and manage their configured local runtime separately. There is no
  automatic model download or cloud fallback.
- The base package supports an OpenAI-compatible local adapter without the optional
  Ollama Python client. The reviewed default lock files retain that client for the
  default Ollama adapter only.
- Terminal backend preflight and `python config.py --health-check` now report an
  unavailable chat or embedding runtime clearly and continue safely without selecting
  an alternative backend. A packaged Windows build reads an external `.env` beside
  the executable, while process environment variables retain precedence.
- Windows builds generate/copy the SBOM, third-party notices, licence notices,
  security/privacy guidance, configuration template, and release readme beside the
  executable; no inference runtime or model weights are bundled.
- A read-only PowerShell public-release readiness audit now checks the actual Git
  repository, tracked-path classes, release metadata, and optional asset checksums.
- Pull-request CI now enforces a DCO `Signed-off-by:` trailer on every proposed
  commit; this contribution certification remains distinct from optional
  cryptographic commit or tag signing.
- GitHub Actions CI runs compilation, configuration validation, and the complete unit
  suite on Python 3.12 for both Ubuntu and Windows.

## Provenance and change scope

This RC3 preparation tree is derived from a maintainer-retained safety-hardened RC3
source archive. The historical canonicalization notes in `PROVENANCE.md` describe an
earlier input-archive pass only; they are not the final release diff. The current
preparation work includes the runtime-availability, packaging, documentation, test,
and public-release controls described above. Before publication, complete the final
tag, commit, asset-hash, and behavior-impact fields in `PROVENANCE.md` from the exact
reviewed Git history.

## Verification performed for this source RC

- Python source compilation, static configuration validation, and the full
  unit/regression suite must be repeated from the exact final source commit using the
  reviewed version-pinned environment. Record the command, result, and date in `PROVENANCE.md`.

The unit suite uses fake backend clients where appropriate; this is not a live Ollama,
model-quality, security-penetration, or production integration test.

## Known release gates

Before promoting this RC to stable `v0.4.0`:

- complete a clean Windows executable build using `requirements-build.lock`;
- smoke-test the exact release asset;
- retain generated third-party notices beside distributed executables;
- enable GitHub Private Vulnerability Reporting;
- complete the patent/public-disclosure, contributor-rights, trademark, and public
  identity decisions for the exact repository;
- audit all refs, history, releases, assets, and CI/Actions logs before any private
  repository is made public; and
- record the exact public tag target, asset filenames, and SHA-256 values in
  `PROVENANCE.md`;
- complete security review appropriate to the intended deployment scope; and
- re-check the status/text of any cited proposed legislation.

See `PUBLIC_RELEASE_GUIDE.md`, `RELEASE_CHECKLIST.md`, `SECURITY.md`, and
`REGULATORY_ALIGNMENT.md`.
