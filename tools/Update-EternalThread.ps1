# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0
<#
.SYNOPSIS
Safely fast-forwards the current Eternal Thread Git branch from its known origin.

.DESCRIPTION
This Windows PowerShell 5.1+ and PowerShell 7+ helper verifies that the current
repository is clean and that origin points to an expected Eternal Thread GitHub or
GitLab repository. It then runs `git pull --ff-only origin <current-branch>`.

It never uses force, reset, checkout, clean, stash, commit, or push. It stops rather
than resolving divergence or uncommitted work on the user's behalf.

.PARAMETER Remote
The verified remote name. Only origin is accepted because the expected public source
and archival-mirror URLs are deliberately allowlisted.

.EXAMPLE
.\tools\Update-EternalThread.ps1

.EXAMPLE
.\tools\Update-EternalThread.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateSet('origin')]
    [string]$Remote = 'origin'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    $output = & $script:gitExecutable @Arguments
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "Git command failed: git $($Arguments -join ' ') (exit code $exitCode)."
    }
    return $output
}

function Test-ExpectedEternalThreadOrigin {
    param([Parameter(Mandatory)][string]$RemoteUrl)

    $normalised = $RemoteUrl.Trim().TrimEnd('/')
    if ($normalised.EndsWith('.git', [StringComparison]::OrdinalIgnoreCase)) {
        $normalised = $normalised.Substring(0, $normalised.Length - 4)
    }

    $allowedOrigins = @(
        'https://github.com/GremlinNavi/sovereign-ai-framework',
        'git@github.com:GremlinNavi/sovereign-ai-framework',
        'ssh://git@github.com/GremlinNavi/sovereign-ai-framework',
        'https://gitlab.com/eternal-thread-group/sovereign-ai-framework',
        'git@gitlab.com:eternal-thread-group/sovereign-ai-framework',
        'ssh://git@gitlab.com/eternal-thread-group/sovereign-ai-framework'
    )

    foreach ($allowedOrigin in $allowedOrigins) {
        if ($normalised.Equals($allowedOrigin, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

try {
    $script:gitExecutable = (Get-Command -Name 'git' -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
    $insideWorkTree = (Invoke-Git rev-parse --is-inside-work-tree | Select-Object -Last 1).Trim()
    if ($insideWorkTree -ne 'true') {
        throw 'Run this helper from inside the Eternal Thread Git repository.'
    }

    # Git for Windows can emit a POSIX-style value for --show-toplevel. Walk from
    # PowerShell's native current directory instead, so normal checkouts and
    # linked worktrees are both located without converting a Git path.
    $repositoryRoot = (Get-Location).Path
    while (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot '.git'))) {
        $parent = Split-Path -LiteralPath $repositoryRoot -Parent
        if (-not $parent -or $parent -eq $repositoryRoot) {
            throw 'Could not locate the Git repository root from the current directory.'
        }
        $repositoryRoot = $parent
    }

    Push-Location -LiteralPath $repositoryRoot
    try {
        $status = Invoke-Git status --porcelain=v1
        if ($status) {
            throw 'Git reports a modified, staged, or non-ignored untracked path. Review and preserve or commit your changes before running this update helper.'
        }

        $branch = (Invoke-Git branch --show-current | Select-Object -Last 1).Trim()
        if (-not $branch) {
            throw 'Detached HEAD is not supported. Switch to a named branch before updating.'
        }

        $remoteUrl = (Invoke-Git remote get-url $Remote | Select-Object -Last 1).Trim()
        if (-not (Test-ExpectedEternalThreadOrigin -RemoteUrl $remoteUrl)) {
            throw "Remote '$Remote' is not an allowlisted Eternal Thread GitHub or GitLab origin. Review 'git remote -v' and correct it manually before updating."
        }

        Write-Output 'Eternal Thread fast-forward update helper'
        Write-Output "Repository: $repositoryRoot"
        Write-Output "Remote: $Remote ($remoteUrl)"
        Write-Output "Branch: $branch"
        Write-Output 'Policy: clean worktree required; fast-forward only; no commit, push, reset, checkout, clean, stash, or force operation.'

        if (-not $PSCmdlet.ShouldProcess("$Remote/$branch", 'run git pull --ff-only')) {
            Write-Output 'Update preview complete; no Git fetch or working-tree change was made.'
            return
        }

        Invoke-Git pull --ff-only $Remote $branch | ForEach-Object { Write-Output $_ }
        Write-Output 'Update completed with fast-forward-only policy. No commit, push, reset, checkout, clean, stash, or force operation was performed.'
    } finally {
        Pop-Location
    }
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
