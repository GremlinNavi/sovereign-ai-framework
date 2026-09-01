# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0
<#!
.SYNOPSIS
Stages named files, creates one signed-off Git commit, and pushes the current branch.

.DESCRIPTION
This helper is intentionally conservative. It does not use force-push, reset, clean,
stash, history rewriting, wildcard staging, or directory staging. It rejects direct
pushes to main/master unless explicitly allowed and screens staged content for common
secret patterns. Use -WhatIf to inspect the intended action without making changes.

.EXAMPLE
.\tools\Push-RepositoryUpdate.ps1 -Path README.md, 'app\agent.py' -Message 'Document release safeguards'

.EXAMPLE
.\tools\Push-RepositoryUpdate.ps1 -Path README.md -Message 'Preview update' -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Path,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,

    [ValidateNotNullOrEmpty()]
    [string]$Remote = 'origin',

    [switch]$AllowProtectedBranch,

    [switch]$AllowExistingStagedChanges,

    [switch]$SkipSecretScan
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    $result = & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed: git $($Arguments -join ' ')"
    }
    return $result
}

function Test-RepositoryRelativeFile {
    param(
        [Parameter(Mandatory)][string]$Candidate,
        [Parameter(Mandatory)][string]$RepositoryRoot
    )

    if ([IO.Path]::IsPathRooted($Candidate) -or $Candidate -match '(^|[\\/])\.\.([\\/]|$)') {
        throw "Only existing repository-relative files may be staged: $Candidate"
    }
    $fullPath = [IO.Path]::GetFullPath((Join-Path $RepositoryRoot $Candidate))
    $rootWithSeparator = $RepositoryRoot.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($rootWithSeparator, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Only existing repository files may be staged: $Candidate"
    }
}

function Test-SensitivePath {
    param([Parameter(Mandatory)][string]$Candidate)
    $normalized = $Candidate.Replace('\\', '/')
    $sensitivePath = '(^|/)(\.env($|\.)|id_(rsa|dsa|ecdsa|ed25519)(\.pub)?$|.*\.(pem|key|pfx|p12|kdbx)$|.*(secret|credential).*)$'
    if ($normalized -match $sensitivePath) {
        throw "Refusing to stage a potentially sensitive path: $Candidate"
    }
}

Invoke-Git rev-parse --is-inside-work-tree | Out-Null
$repositoryRoot = (Get-Location).Path
while (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot '.git'))) {
    $parent = Split-Path -LiteralPath $repositoryRoot -Parent
    if (-not $parent -or $parent -eq $repositoryRoot) {
        throw 'The current directory is not inside a Git working tree.'
    }
    $repositoryRoot = $parent
}

$branch = (Invoke-Git branch --show-current).Trim()
if (-not $branch) {
    throw 'Detached HEAD is not supported. Switch to a named branch first.'
}
if ($branch -in @('main', 'master') -and -not $AllowProtectedBranch) {
    throw "Refusing to push directly to $branch. Create a feature branch and open a pull request, or pass -AllowProtectedBranch after review."
}

$remoteUrl = (Invoke-Git remote get-url $Remote).Trim()
if (-not $remoteUrl) {
    throw "Remote '$Remote' does not have a URL. Review 'git remote -v' before pushing."
}

$existingStaged = Invoke-Git diff --cached --name-only
if ($existingStaged -and -not $AllowExistingStagedChanges) {
    throw "The index already contains staged changes. Review them with 'git diff --cached', then rerun with -AllowExistingStagedChanges if they are intentional."
}

foreach ($candidate in $Path) {
    Test-RepositoryRelativeFile -Candidate $candidate -RepositoryRoot $repositoryRoot
    Test-SensitivePath -Candidate $candidate
    $ignored = & git check-ignore --quiet -- $candidate
    if ($LASTEXITCODE -eq 0) {
        throw "Refusing to stage an ignored file: $candidate"
    }
    if ($LASTEXITCODE -gt 1) {
        throw "Could not check ignore status for: $candidate"
    }
    # `git check-ignore --quiet` returns 1 for the expected “not ignored” case.
    # Clear that expected external-command status so `-WhatIf` exits successfully.
    $global:LASTEXITCODE = 0
}

Write-Host "Repository: $repositoryRoot"
Write-Host "Remote:     $Remote ($remoteUrl)"
Write-Host "Branch:     $branch"
Write-Host "Files:      $($Path -join ', ')"

if (-not $PSCmdlet.ShouldProcess("$Remote/$branch", 'stage named files, create a signed-off commit, and push')) {
    return
}

Invoke-Git add -- $Path
$stagedFiles = Invoke-Git diff --cached --name-only
if (-not $stagedFiles) {
    throw 'No changes were staged. Nothing was committed or pushed.'
}

Invoke-Git diff --cached --check
if (-not $SkipSecretScan) {
    $stagedText = Invoke-Git diff --cached --no-ext-diff --unified=0
    $secretPattern = '(?im)(api[_-]?key|access[_-]?key|secret|token|password)\s*[:=]\s*["'']?[^\s"'']{8,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|AKIA[0-9A-Z]{16}'
    if ($stagedText -match $secretPattern) {
        throw "Potential secret detected in staged content. Review 'git diff --cached'; no commit or push was performed."
    }
}

Write-Host 'Staged diff summary:'
Invoke-Git diff --cached --stat
Invoke-Git commit -s -m $Message
Invoke-Git push --set-upstream $Remote $branch

Write-Host "Pushed commit to $Remote/$branch. Open a pull request before merging into a protected branch."
