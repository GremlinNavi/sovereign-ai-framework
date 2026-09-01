# Windows installation and safe updates

These two PowerShell helpers provide a small, inspectable Windows path for working
with the source checkout. They support Windows PowerShell 5.1 and PowerShell 7+.
They are optional conveniences; each command is visible in its script before it is
run.

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- Python 3.10 or newer, available as `python` (or supplied with `-PythonCommand`)
- Git only if you plan to use the update helper

The scripts do not change your PowerShell execution policy. If your device blocks a
script, follow your organization’s policy or inspect and run the individual commands
with the authorization appropriate for your machine.

## Install the Python package locally

From the repository root, run:

```powershell
.\tools\Install-EternalThread.ps1
```

The installer preflights Python 3.10+, creates `.venv` only when it is absent, and
uses `.venv\Scripts\python.exe` explicitly for all installation and validation
commands. It installs the base package with `pip install .`, then runs:

```powershell
.\.venv\Scripts\python.exe config.py --validate
```

This validation checks the selected configuration and initializes missing configured
local data directories, but it does not start an AI runtime or choose an alternative
backend.

The shipped configuration defaults to the Ollama adapter. The base installation
intentionally does **not** include its optional Python client, so it validates but
will not run that default adapter until you either install the opt-in client below or
deliberately configure a supported alternative.

The installer never creates or overwrites `.env`; review `.env.example` and make any
local configuration change yourself. It does not make global Python installations,
perform Git operations, install an inference runtime, download model files, or make
a remote backend selection.

The virtual-environment path must remain inside the checkout and cannot pass through
an existing symbolic link or junction. This guards against an accidental path escape;
it is not a replacement for normal workstation or repository trust controls.

To preview the planned action without creating a virtual environment or installing
anything, use:

```powershell
.\tools\Install-EternalThread.ps1 -WhatIf
```

### Optional Ollama Python client

Only if you have deliberately chosen the Ollama adapter, install its optional Python
client extra:

```powershell
.\tools\Install-EternalThread.ps1 -InstallOllamaClient
```

This invokes `pip install .[ollama]` in the project virtual environment. It does not
install or start the Ollama runtime and does not download or select any models. Those
remain separate operator choices with their own system, hardware, licence, and data
handling implications.

## Trust boundary

These helpers are convenience scripts, not a sandbox or authenticity-verification
system. `pip install .` builds and installs the source checkout you run, and the
update helper invokes the Git executable already available on your machine. A
recognized remote URL and `--ff-only` protect against common accidental update
mistakes, but do not verify Git signatures, branch protection, Python package
provenance, release-asset checksums, local Git hooks, or user-level Git/credential
configuration. Review the exact source and use the release provenance/checksum
process in `PUBLIC_RELEASE_GUIDE.md` before trusting a release.

### Deliberate backend health check

The base installation does not contact an inference backend. After you have selected
and started the intended backend yourself, you may deliberately request a health
check:

```powershell
.\tools\Install-EternalThread.ps1 -HealthCheck
```

The health check contacts only the endpoints already configured in `config.py` or
your local environment. It verifies the configured model names and does not select
or fall back to another backend. Keep the configured endpoint local unless you have
made and consented to the project’s separate remote-backend opt-in.

## Safely update a clean checkout

The update helper only works from a clean Git working tree. It accepts only `origin`
when that remote is one of these canonical repository locations:

- `https://github.com/GremlinNavi/sovereign-ai-framework(.git)`
- `git@github.com:GremlinNavi/sovereign-ai-framework(.git)`
- `ssh://git@github.com/GremlinNavi/sovereign-ai-framework(.git)`
- `https://gitlab.com/eternal-thread-group/sovereign-ai-framework(.git)`
- `git@gitlab.com:eternal-thread-group/sovereign-ai-framework(.git)`
- `ssh://git@gitlab.com/eternal-thread-group/sovereign-ai-framework(.git)`

Run it from anywhere inside that checkout:

```powershell
.\tools\Update-EternalThread.ps1
```

After verifying the working tree, current branch, and remote URL, it runs exactly:

```text
git pull --ff-only origin <current-branch>
```

It will stop if a fast-forward is not possible, if `git status --porcelain` reports
modified, staged, or non-ignored untracked files, or if the remote is not allowlisted.
It will not resolve a divergence for you and never makes commits or pushes. It also
never uses reset, checkout, clean, stash, or force operations.

Use `-WhatIf` to preview the update gate without fetching or changing the working
tree:

```powershell
.\tools\Update-EternalThread.ps1 -WhatIf
```

If the update is blocked, review `git status --short`, `git branch --show-current`,
and `git remote -v`; preserve your work before resolving any issue manually.

## Optional desktop accessibility preferences

The accessibility-first distribution fork includes a local-only preference helper:

```powershell
.\Tools\Set-EternalThreadGuiPreferences.ps1 -Theme HighContrast -FontScale 125
```

For a source checkout, run the equivalent helper from `tools\`. It writes only
`gui_preferences.json` in Eternal Thread's local data directory. Available bounded
choices are a system/light/dark/high-contrast theme, an 80–200% text scale, and an
opening-window size. It does not edit source files, `.env`, backend/model settings,
Git configuration, or Windows-wide accessibility settings. Use `-WhatIf` to preview
or `-Reset` to remove the local preferences and return to application defaults.
