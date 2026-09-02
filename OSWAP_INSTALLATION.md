# OSWAP installation and bootstrap contract

This document defines the installation interface for the Open-Source World Access Project (OSWAP) PowerShell environment.

## Status

The canonical user-facing command is planned as:

```powershell
oswap install
```

That command is an interface contract and roadmap target. It is not yet registered as a global command by this repository. Current users should follow the manual bootstrap procedure below until the installer implementation is added and tested.

Documentation must not claim that `oswap install`, `gh oswap install`, or a `gh-oswap` extension already exists unless the corresponding executable implementation is present in a published repository.

## Design goal

A user should need to remember one command after first-time bootstrap:

```powershell
oswap install
```

Repository names, forge URLs, dependency checks, package locations, and PATH registration should remain implementation details handled by the wizard.

The installer should be usable from a normal PowerShell-compatible environment and should remain readable, auditable, and non-destructive.

## Planned command surface

The initial command vocabulary should remain small:

```text
oswap install
oswap install ai
oswap install twin
oswap install syntax
oswap install all
oswap update
oswap repair
oswap doctor
oswap remove
```

`oswap install` should mean the recommended OSWAP environment. Package-specific forms should be optional shortcuts for advanced users and automated deployments.

## Current package map

The installer should treat repository coordinates as package metadata rather than requiring users to memorize forge paths.

| Package | Current GitHub source | Current GitLab twin | Role |
| --- | --- | --- | --- |
| `ai` | `GremlinNavi/sovereign-ai-framework` | `GremlinNavi-group/sovereign-ai-framework` | Local-first sovereign AI framework and current OSWAP syntax host |
| `twin` | `GremlinNavi/git-push-twin` | `GremlinNavi-group/git-push-twin` | PS-twin publication, redundancy, scrub, checksum, and Git transport tooling |
| `syntax` | bundled in `sovereign-ai-framework/oswap-syntax/` | bundled in the GitLab twin | Declarative OSWAP command definitions and local dispatcher data |

There is currently no separate public `oswap-syntax` repository. The installer must not fabricate one.

## Twin-source rule

OSWAP repositories are twins. GitHub and GitLab are distribution surfaces; neither should be described as the permanent canonical source of truth.

The first installer implementation may use GitHub CLI because the desired bootstrap primitive is:

```powershell
gh repo clone GremlinNavi/sovereign-ai-framework
```

However, package metadata should also retain the equivalent GitLab repository URL so the installation architecture can fall back to normal Git transport when GitHub CLI or GitHub itself is unavailable.

A source-selection failure is not permission to overwrite local repositories or reconcile divergent histories automatically.

## Current manual bootstrap

Until `oswap install` is implemented, the following commands use repository functionality that exists today.

### 1. Verify prerequisites

```powershell
git --version
gh --version
$PSVersionTable.PSVersion
```

Current OSWAP and PS-twin scripts support Windows PowerShell 5.1 or PowerShell 7+ where documented. Git is required for repository transport. GitHub CLI is required only for the `gh repo clone` bootstrap form.

### 2. Clone the current OSWAP repositories

From the directory where you want the checkouts:

```powershell
gh repo clone GremlinNavi/sovereign-ai-framework
gh repo clone GremlinNavi/git-push-twin
```

If GitHub CLI is unavailable, standard Git may be used with either published twin URL after verifying the repository identity.

### 3. Inspect the existing OSWAP syntax dispatcher

```powershell
Set-Location .\sovereign-ai-framework
& .\scripts\Invoke-OSWAP.ps1 help
```

The current dispatcher supports the implemented command forms documented in `oswap-syntax/README.md`. It does not yet register the global `oswap` command.

### 4. Configure the current PS-twin Git adapter when desired

Run the PS-twin installer from inside the repository that should receive the `twin` remote:

```powershell
& "..\git-push-twin\Install-GitPushTwin.ps1" `
  -RepositoryUrl @(
    "https://github.com/GremlinNavi/sovereign-ai-framework.git",
    "https://gitlab.com/GremlinNavi-group/sovereign-ai-framework.git"
  )
```

This configures repository-local Git publication behaviour. It is separate from the future OSWAP package installer and should remain separately auditable.

## Wizard execution contract

When the PowerShell install wizard is implemented, `oswap install` should perform these stages in order.

1. Preflight
   - detect PowerShell version;
   - detect Git;
   - detect GitHub CLI when the GitHub bootstrap adapter is selected;
   - verify writable install and command-registration locations;
   - show the intended package plan before network or PATH changes.

2. Source resolution
   - resolve each requested OSWAP package from a declarative package map;
   - prefer an explicitly selected source;
   - otherwise use an available verified twin without declaring a permanent primary;
   - refuse ambiguous or unexpected repository identities.

3. Acquisition
   - use `gh repo clone OWNER/REPO` when the GitHub CLI adapter is selected;
   - use standard `git clone` for GitLab or other Git-compatible twins;
   - update an existing managed checkout only after verifying its configured remotes;
   - never force-reset a checkout merely to make installation continue.

4. Package setup
   - install or expose the OSWAP syntax bundle;
   - install requested PS-twin tooling without silently publishing anything;
   - install the Sovereign AI Framework dependencies only for the selected package/profile;
   - keep model/runtime downloads explicit because they may be large and backend-specific.

5. Command registration
   - create a stable PowerShell entry point named `oswap`;
   - add only the required user-scoped command path;
   - avoid persistent execution-policy weakening;
   - report exactly what was changed and where.

6. Verification
   - run a local `oswap doctor`-equivalent check;
   - verify package paths and versions;
   - verify the syntax dispatcher can load declarative command definitions;
   - verify configured Git remotes without pushing;
   - report actionable failures rather than hiding partial installation.

## Safety requirements

The installer should follow these rules:

- preview planned changes before modifying PATH, PowerShell profiles, Git configuration, or existing checkouts;
- never store GitHub or GitLab access tokens in project files;
- never run arbitrary repository text as PowerShell code merely because it was downloaded;
- never use `Invoke-Expression` for OSWAP arithmetic syntax;
- never force-push, reset, clean, or rewrite Git history as an installation shortcut;
- preserve PS-twin's non-destructive secret-detection model;
- verify checksums or signed release metadata when packaged installer artifacts become available;
- make repeated `oswap install` runs idempotent wherever practical;
- distinguish installation success from external service availability.

## Package manifest direction

The wizard should eventually load a small declarative manifest describing package IDs, twin repository coordinates, install roles, supported platforms, dependency checks, and optional verification metadata.

The manifest should contain data only. It should not be a remote-code execution surface.

A conceptual record may include:

```text
id: ai
sources:
  github: GremlinNavi/sovereign-ai-framework
  gitlab: GremlinNavi-group/sovereign-ai-framework
role: application
```

The exact serialization format can be selected during implementation.

## Bootstrap boundary

There is an unavoidable first-install boundary: `oswap install` cannot be invoked globally until an OSWAP command shim/module has been installed.

The project should therefore distinguish:

```text
first-time bootstrap
        -> installs/registers OSWAP command layer
        -> oswap install
        -> normal package management
```

A GitHub CLI extension such as `gh oswap install` is a possible future bootstrap surface, but it must not be documented as an available command until that extension is actually published and maintained.

## Relationship to the existing syntax layer

`oswap-syntax/` remains the declarative command-data layer. `scripts/Invoke-OSWAP.ps1` is the current local reference dispatcher.

The future global `oswap` command should wrap or replace that dispatcher through a stable module/entry point rather than requiring users to memorize repository-relative script paths.

See:

- `oswap-syntax/README.md`
- `scripts/Invoke-OSWAP.ps1`
- `OSWAP_DATABASE.md`
- `OSWAP_AI_ENDPOINTS.md`
- the PS-twin repository documentation

## Documentation rule

Until implementation catches up with this contract, documentation should clearly label commands as one of:

- implemented now;
- current manual bootstrap;
- planned installer interface.

That distinction is required so OSWAP remains auditable and users are never instructed to run commands that do not exist yet.
