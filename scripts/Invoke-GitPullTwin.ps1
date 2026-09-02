# SPDX-License-Identifier: Apache-2.0
#requires -Version 5.1
<#
.SYNOPSIS
Safely retrieves a branch from an explicit number of configured twin sources.
.DESCRIPTION
Fetches the requested branch independently from selected repositories configured on
the Git remote named "twin", compares their commit IDs, and only fast-forwards the
current local branch when every selected source agrees.

SourceCount 0 preserves the legacy "all configured twin sources" behavior.
OSWAP `download twin=N` always supplies an explicit integer N >= 2.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()][string]$RepositoryPath = (Get-Location).Path,
    [Parameter()][ValidateNotNullOrEmpty()][string]$Remote = 'twin',
    [Parameter()][string]$Branch,
    [Parameter()][ValidateRange(0, 1024)][int]$SourceCount = 0
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Invoke-GitChecked {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    $output = @(& git -C $script:RepositoryRoot @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) { throw "Git command failed: git $($Arguments -join ' ')`n$($output -join [Environment]::NewLine)" }
    return $output
}

function Get-TwinSourceLabel {
    param([Parameter(Mandatory = $true)][string]$Url,[Parameter(Mandatory = $true)][int]$Index)
    try {
        $uri = [Uri]$Url
        if (-not [string]::IsNullOrWhiteSpace($uri.Host)) { return "source $Index ($($uri.Host))" }
    } catch {}
    if ($Url -match '^[^@]+@([^:]+):') { return "source $Index ($($Matches[1]))" }
    return "source $Index"
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git was not found on PATH.' }
$resolvedPath = (Resolve-Path -LiteralPath $RepositoryPath).Path
$rootOutput = @(& git -C $resolvedPath rev-parse --show-toplevel 2>&1)
if ($LASTEXITCODE -ne 0) { throw "Not a Git working tree: $resolvedPath" }
$script:RepositoryRoot = ($rootOutput | Select-Object -First 1).Trim()

$currentBranchOutput = @(& git -C $script:RepositoryRoot symbolic-ref --quiet --short HEAD 2>&1)
if ($LASTEXITCODE -ne 0 -or $currentBranchOutput.Count -eq 0) { throw 'Twin download requires a checked-out branch; detached HEAD is not supported.' }
$currentBranch = ($currentBranchOutput | Select-Object -First 1).Trim()
if ([string]::IsNullOrWhiteSpace($Branch)) { $Branch = $currentBranch }
elseif ($Branch -ne $currentBranch) { throw "Requested branch '$Branch' is not the currently checked-out branch '$currentBranch'. Check out '$Branch' first." }

$null = Invoke-GitChecked -Arguments @('check-ref-format', '--branch', $Branch)
$status = @(Invoke-GitChecked -Arguments @('status', '--porcelain'))
if ($status.Count -gt 0) { throw 'Working tree is not clean. Commit, stash, or remove local changes before an OSWAP twin download.' }

$sourceUrls = @(& git -C $script:RepositoryRoot config --get-all "remote.$Remote.pushurl" 2>$null)
if ($LASTEXITCODE -ne 0) { $sourceUrls = @() }
$sourceUrls = @($sourceUrls | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
if ($sourceUrls.Count -eq 0) {
    $sourceUrls = @(& git -C $script:RepositoryRoot config --get-all "remote.$Remote.url" 2>$null)
    if ($LASTEXITCODE -ne 0) { $sourceUrls = @() }
    $sourceUrls = @($sourceUrls | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
}
if ($sourceUrls.Count -lt 2) { throw "Remote '$Remote' does not define at least two twin source URLs." }
if ($SourceCount -eq 1) { throw 'OSWAP twin download requires at least two independent sources.' }

$selectedUrls = if ($SourceCount -eq 0) { @($sourceUrls) } else {
    if ($SourceCount -gt $sourceUrls.Count) { throw "Requested $SourceCount twin sources, but only $($sourceUrls.Count) are configured." }
    @($sourceUrls | Select-Object -First $SourceCount)
}

$sessionId = [Guid]::NewGuid().ToString('N')
$tempRefs = New-Object System.Collections.Generic.List[string]
$fetchedCommits = New-Object System.Collections.Generic.List[string]

try {
    Write-Host 'OSWAP twin download preflight'
    Write-Host "Repository: $script:RepositoryRoot"
    Write-Host "Branch:     $Branch"
    Write-Host "Sources:    $($selectedUrls.Count)"
    Write-Host ''

    for ($i = 0; $i -lt $selectedUrls.Count; $i++) {
        $sourceNumber = $i + 1
        $url = [string]$selectedUrls[$i]
        $label = Get-TwinSourceLabel -Url $url -Index $sourceNumber
        $tempRef = "refs/oswap/twin-download/$sessionId/$sourceNumber"
        $refSpec = "+refs/heads/${Branch}:$tempRef"
        Write-Host "Fetching $label..."
        $fetchOutput = @(& git -C $script:RepositoryRoot fetch --no-tags --quiet $url $refSpec 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Failed to fetch $label. OSWAP download halted without modifying the local branch.`n$($fetchOutput -join [Environment]::NewLine)" }
        $tempRefs.Add($tempRef)
        $commitOutput = @(Invoke-GitChecked -Arguments @('rev-parse', '--verify', $tempRef))
        $commit = ($commitOutput | Select-Object -First 1).Trim()
        $fetchedCommits.Add($commit)
        Write-Host "  $label -> $commit"
    }

    $consensusCommit = $fetchedCommits[0]
    $disagreement = @($fetchedCommits | Where-Object { $_ -ne $consensusCommit })
    if ($disagreement.Count -gt 0) {
        Write-Host ''
        Write-Host 'Twin agreement: FAIL'
        throw 'Selected twin repositories disagree on the requested branch. No local integration was performed.'
    }

    Write-Host ''
    Write-Host "Twin agreement: PASS ($consensusCommit)"
    $localCommitOutput = @(Invoke-GitChecked -Arguments @('rev-parse', '--verify', 'HEAD'))
    $localCommit = ($localCommitOutput | Select-Object -First 1).Trim()
    Write-Host "Local HEAD:     $localCommit"
    if ($localCommit -eq $consensusCommit) { Write-Host 'Result:         already up to date.'; return }

    & git -C $script:RepositoryRoot merge-base --is-ancestor $localCommit $consensusCommit 2>$null
    $localIsAncestor = ($LASTEXITCODE -eq 0)
    & git -C $script:RepositoryRoot merge-base --is-ancestor $consensusCommit $localCommit 2>$null
    $remoteIsAncestor = ($LASTEXITCODE -eq 0)

    if ($localIsAncestor) {
        $targetRef = $tempRefs[0]
        if ($PSCmdlet.ShouldProcess("$Branch -> $consensusCommit", 'Fast-forward local branch from unanimous twin state')) {
            $mergeOutput = @(& git -C $script:RepositoryRoot merge --ff-only $targetRef 2>&1)
            if ($LASTEXITCODE -ne 0) { throw "Fast-forward failed. Twin repositories agreed, but the local branch was not modified successfully.`n$($mergeOutput -join [Environment]::NewLine)" }
            $mergeOutput | ForEach-Object { Write-Host $_ }
            Write-Host "OSWAP twin download complete: $Branch is now $consensusCommit"
        }
        return
    }
    if ($remoteIsAncestor) { Write-Host 'Result:         local branch is ahead of the unanimous twin state; no download was required.'; return }
    throw 'Local history has diverged from the unanimous twin state. No merge, rebase, reset, or automatic reconciliation was attempted.'
}
finally {
    foreach ($tempRef in $tempRefs) { & git -C $script:RepositoryRoot update-ref -d $tempRef 2>$null | Out-Null }
}
