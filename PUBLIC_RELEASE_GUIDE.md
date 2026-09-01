# Public source-release guide

This guide is the practical path from the prepared RC3 source tree to a public,
open-source release. It does not replace legal advice, platform documentation, or a
maintainer's review of the exact repository being published.

## 1. Make the disclosure decision first

Before making code, documentation, releases, or a repository public, decide whether
any part of the work needs patent review or another confidential treatment. Confirm
the public authorship, contributor authority, and brand wording. Do not turn a
private repository public merely because the current working tree appears clean.

## 2. Build a clean public source set

Review the complete Git history, all refs, tags, releases, release assets, forks,
and CI/Actions logs for secrets, personal data, internal records, or material without
permission for public distribution. If the development history cannot be safely
disclosed, publish a clean source-only repository or clean public history instead.

For public contributions, keep the DCO boundary active: the repository CI checks for
a `Signed-off-by:` trailer on every pull-request commit. That certification supports
the contribution record but is not a cryptographic signature or a replacement for
maintainer review of contributor authority.

Keep local data out of the source set: conversation history, audit logs, RAG/knowledge
files, indexes, `.env` files, API keys, local paths, and training/review data must
not be released. Run the read-only audit from inside the actual repository:

```powershell
.\tools\Test-PublicReleaseReadiness.ps1 -Version v0.4.0-rc3 -RequireClean
```

The audit deliberately makes no file, Git, network, remote, visibility, or account
changes. Treat its warnings as human-review work; it cannot prove that no sensitive
data exists. Run every item in [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) for the
exact source tree and assets to be published.

## 3. Preserve the portable local-first boundary

A Python virtual environment isolates the project’s Python dependencies and adapter
libraries. It does not install or start an inference runtime, download model weights,
or choose a model. Operators separately select and manage compatible local inference
runtimes and the models they serve. Ollama is a default adapter, not a bundled or
required project runtime.

The base Python package supports the `openai_compatible` local adapter without the
Ollama Python client. The `ollama` package is an optional project extra; the reviewed
default lock files include that client to support the default Ollama adapter. Neither
choice installs the Ollama service or model weights.

For a package install outside the reviewed lock-file path, `python -m pip install .`
installs the base package and `python -m pip install ".[ollama]"` adds the optional
Ollama client. Both remain Python dependency operations, not runtime or model
installation.

There is no automatic model download or cloud fallback. The application uses the
explicitly configured endpoints; a non-local backend requires the documented opt-in
and informed consent. This preserves the project's local-first, runtime-agnostic
design without silently changing a user's data boundary.

## 4. Verify the final commit and assets

From a clean virtual environment, run the verification commands in
[RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md). Rebuild the notices, SBOM, and release
assets from the exact reviewed commit. The Windows build supplies the executable with
the generated notices/SBOM and the required licensing, security, privacy,
configuration, and release-readme material; it intentionally does not package an
inference runtime or model weights. Smoke-test the final archive/build, not only a
working checkout.

Create `SHA256SUMS.txt` from the final files. Then run the read-only audit with the
actual asset and manifest, for example:

```powershell
.\tools\Test-PublicReleaseReadiness.ps1 -Version v0.4.0-rc3 -RequireClean `
  -ChecksumFile C:\releases\SHA256SUMS.txt `
  -ReleaseAsset C:\releases\eternal-thread-v0.4.0-rc3.zip
```

Complete the **Final public-release provenance** section of
[PROVENANCE.md](PROVENANCE.md) with the public repository URL, exact tag, full tag
target commit ID, asset filenames, and SHA-256 values. The hash of a retained input
archive is not a substitute for a final release-asset hash. Also complete its actual
final-diff and behavior-impact record from the final repository history; historical
retained-base notes are not a release diff.

## 5. Publish deliberately

Push the reviewed branch through the repository's chosen review controls, create the
`v0.4.0-rc3` tag from the verified commit, and record that commit ID in the provenance
record. Before or immediately after changing visibility, re-check the public
repository's branch and tag protections, vulnerability-reporting path, release notes,
and account security. Mark RC3 as a pre-release, attach the exact checked assets and
checksum manifest, and verify the uploads against their published hashes.

When maintaining a GitHub canonical source and a GitLab archival mirror, import the
same reviewed source set through separate host branches and review each host's commit
history independently. Their commit IDs may legitimately differ after host-specific
metadata or merge commits. Do not force-push one host's history over the other merely
to make hashes match. Record the host-specific branch, tag, and release references in
[docs/archive/](docs/archive/) after they exist.

Do not announce the release until each unchecked gate in
[RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) has been completed or deliberately
documented as not applicable.
