# Safe PowerShell Git workflow

This guide uses Git from PowerShell to send reviewed updates to a remote repository.
It assumes the repository and its remote already exist. The supplied
[`Push-RepositoryUpdate.ps1`](tools/Push-RepositoryUpdate.ps1) intentionally stages
only the files you name, creates a DCO-signed commit, and pushes the current feature
branch.

## One-time setup on a computer

Set the identity that will appear permanently in commit history:

```powershell
git config --global user.name "Your public contributor name"
git config --global user.email "your-public-email@example.com"
git config --global commit.gpgSign true
```

Configure a verified signing key before enabling `commit.gpgSign`; otherwise omit the
last command until signing is configured. Authenticate to the hosting service using
its supported SSH or credential-manager flow—never paste a personal access token into
a tracked file or commit message.

## Normal update flow

From the repository root, inspect the change before staging it:

```powershell
git status --short
git diff -- README.md app\agent.py
git remote -v
```

Create a feature branch. The push helper deliberately blocks direct `main` or
`master` pushes unless you explicitly override it:

```powershell
git switch -c docs/ip-release-safeguards
```

Rehearse the exact push with no change to the repository or remote:

```powershell
.\tools\Push-RepositoryUpdate.ps1 `
  -Path README.md, IP_POLICY.md, DCO.md `
  -Message "Add release IP safeguards" `
  -WhatIf
```

When the printed repository, remote, branch, and file list are correct, run the same
command without `-WhatIf`:

```powershell
.\tools\Push-RepositoryUpdate.ps1 `
  -Path README.md, IP_POLICY.md, DCO.md `
  -Message "Add release IP safeguards"
```

The script will prompt before it stages files, creates the commit, and pushes. It
checks for an existing staged index, ignored files, likely sensitive paths, whitespace
errors, and common secret patterns. Review the resulting pull request on the hosting
service, then merge only after the required tests and approvals pass.

## What each Git step means

| Step | Effect | IP and safety significance |
|---|---|---|
| `git diff` | Shows unstaged local edits | Lets you review exactly what may become a permanent record. |
| `git add <file>` | Selects named content for the next commit | Avoids accidentally staging secrets or unrelated work. |
| `git commit -s` | Creates a local, signed-off history record | Records change history and the contributor’s DCO certification; it does not transfer ownership. |
| `git push` | Copies commits to the selected remote | Creates an off-device copy and may be a public disclosure if the repository is public. |
| Pull request and protected merge | Requests review before integration | Provides a visible review/approval trail and protects the canonical branch. |

Git history, signed commits, release tags, and SHA-256 checksums strengthen provenance:
they help show what changed, when, and under which project notices. They are not a
CIPO copyright registration, patent filing, trademark registration, or a substitute
for an employment/contractor assignment. A public push can expose information
worldwide, so do not push confidential data or a potentially patentable invention’s
enabling detail before deciding whether to file.

## If the helper stops

- **Existing staged changes:** run `git diff --cached`, decide whether they belong in
  this update, then either commit them separately or rerun with
  `-AllowExistingStagedChanges` after review.
- **Potential secret:** stop. Remove the secret from the change, use a local `.env`
  file or secret manager, and revoke any real credential that was exposed.
- **Main/master blocked:** keep the change on a feature branch and use a pull request.
  Use `-AllowProtectedBranch` only where your repository policy truly permits a
  direct, reviewed release push.
- **Wrong remote:** stop and inspect `git remote -v`; do not push until the URL and
  account are correct.
