# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0
<#
.SYNOPSIS
Performs a read-only pre-publication audit of the current Git repository.

.DESCRIPTION
This helper is deliberately conservative and makes no Git, network, repository, or
file changes. It checks the current working tree, tracked paths, release metadata,
and optional release-asset checksums before a repository is made public.

It cannot prove that no secret or personal data exists. It highlights paths and
release gates that must receive a human review, without printing potentially
sensitive file contents.

.EXAMPLE
.\tools\Test-PublicReleaseReadiness.ps1 -Version v0.4.0-rc3 -RequireClean

.EXAMPLE
.\tools\Test-PublicReleaseReadiness.ps1 -Version v0.4.0-rc3 -RequireClean `
    -ChecksumFile C:\releases\SHA256SUMS.txt `
    -ReleaseAsset C:\releases\eternal-thread-v0.4.0-rc3.zip
#>
[CmdletBinding()]
param(
    [ValidatePattern('^v?\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$')]
    [string]$Version = 'v0.4.0-rc3',

    [string[]]$ReleaseAsset = @(),

    [string]$ChecksumFile,

    [switch]$RequireClean
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-Error {
    param([Parameter(Mandatory)][string]$Message)
    $script:errors.Add($Message)
}

function Add-Warning {
    param([Parameter(Mandatory)][string]$Message)
    $script:warnings.Add($Message)
}

function Invoke-GitReadOnly {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    $output = & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed: git $($Arguments -join ' ')"
    }
    return $output
}

function Test-TrackedPathIsPublicSafe {
    param([Parameter(Mandatory)][string]$Path)

    $normalized = $Path.Replace('\', '/')
    if ($normalized -match '(^|/)\.env\.example$') { return $true }
    if ($normalized -match '(^|/)\.env($|\.)') { return $false }
    if ($normalized -match '(^|/)(\.venv|venv|\.ip-build-env|\.pytest_cache|__pycache__)(/|$)') { return $false }
    if ($normalized -match '(^|/)\.professionalism-audit-(data|pytest)(/|$)') { return $false }
    if ($normalized -match '\.spec$') { return $false }
    if ($normalized -match '\.(pem|key|pfx|p12|kdbx|sqlite3|sqlite3-shm|sqlite3-wal)$') { return $false }
    if ($normalized -match '(^|/)(id_rsa|id_dsa|id_ecdsa|id_ed25519)(\.pub)?$') { return $false }
    if ($normalized -match '(^|/)credentials\.json$' -or $normalized -match '(^|/)secrets\.[^/]+$') { return $false }
    if ($normalized -match '(^|/)conversation_history/(tool_audit\.jsonl|safety_events\.jsonl)$') { return $false }
    if ($normalized -match '(^|/)conversation_history/sessions/(?!\.gitkeep$)') { return $false }
    if ($normalized -match '(^|/)knowledge/(?!\.gitkeep$)') { return $false }
    if ($normalized -match '(^|/)training_data/(raw|curated|review)/(?!\.gitkeep$)') { return $false }
    return $true
}

function Get-ExpectedAssetHash {
    param(
        [Parameter(Mandatory)][string]$Manifest,
        [Parameter(Mandatory)][string]$AssetName
    )

    foreach ($line in Get-Content -LiteralPath $Manifest) {
        if ($line -match '^\s*([A-Fa-f0-9]{64})\s+\*?(.+?)\s*$' -and $Matches[2] -eq $AssetName) {
            return $Matches[1].ToUpperInvariant()
        }
    }
    return $null
}

function Test-ZipAssetContents {
    param([Parameter(Mandatory)][string]$Asset)

    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($Asset)
        try {
            $unsafeEntries = @(
                $archive.Entries |
                    Where-Object { -not $_.FullName.EndsWith('/') } |
                    Where-Object { -not (Test-TrackedPathIsPublicSafe $_.FullName) } |
                    ForEach-Object { $_.FullName }
            )
        } finally {
            $archive.Dispose()
        }
        if ($unsafeEntries.Count -gt 0) {
            Add-Error ('Release ZIP includes potentially private or sensitive paths: ' + ($unsafeEntries -join ', '))
        }
    } catch {
        Add-Warning "Could not inspect ZIP contents for $Asset. Review the archive manually before upload."
    }
}

try {
    $insideWorkTree = & git rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -ne 0 -or $insideWorkTree.Trim() -ne 'true') {
        throw 'Run this helper from inside the Git repository that you intend to publish.'
    }

    # Git for Windows may emit a POSIX-style path for `rev-parse --show-toplevel`.
    # Walk PowerShell's native working-directory path instead so this helper works
    # in both ordinary checkouts and linked worktrees.
    $repositoryRoot = (Get-Location).Path
    while (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot '.git'))) {
        $parent = Split-Path -LiteralPath $repositoryRoot -Parent
        if (-not $parent -or $parent -eq $repositoryRoot) {
            throw 'The current directory is not inside a Git working tree.'
        }
        $repositoryRoot = $parent
    }
    Push-Location -LiteralPath $repositoryRoot
    try {
        Write-Host "Repository: $repositoryRoot"
        Write-Host "Release line: $Version"
        Write-Host 'Mode: read-only; no files, commits, remotes, visibility, or GitHub settings will be changed.'

        $status = Invoke-GitReadOnly status --porcelain=v1
        if ($status) {
            $message = 'Working tree has uncommitted or untracked changes. Review `git status --short` before release.'
            if ($RequireClean) { Add-Error $message } else { Add-Warning $message }
        }

        $requiredFiles = @(
            'LICENSE', 'NOTICE', 'AUTHORS.md', 'CITATION.cff', 'DCO.md', 'IP_POLICY.md',
            'TRADEMARKS.md', 'SECURITY.md', 'CONTRIBUTING.md', 'THIRD_PARTY_NOTICES.md',
            'SBOM.cdx.json', 'RELEASE_CHECKLIST.md', 'PROVENANCE.md', '.gitignore'
        )
        foreach ($file in $requiredFiles) {
            if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
                Add-Error "Required public-release file is missing: $file"
            }
        }

        $tracked = Invoke-GitReadOnly ls-files
        $unsafeTracked = @($tracked | Where-Object { -not (Test-TrackedPathIsPublicSafe $_) })
        if ($unsafeTracked.Count -gt 0) {
            Add-Error ('Potentially private or sensitive paths are tracked: ' + ($unsafeTracked -join ', '))
        }

        $historyPaths = @('.env', '.env.local', 'conversation_history', 'knowledge/index.sqlite3', 'training_data', '.professionalism-audit-data', '.professionalism-audit-pytest', '*.pem', '*.key', '*.pfx', '*.p12')
        $historyMatches = Invoke-GitReadOnly log --all --format=%H -- $historyPaths
        if ($historyMatches) {
            Add-Warning 'Git history references potentially sensitive path classes. Inspect history before changing repository visibility; do not assume .gitignore protects past commits.'
        }

        $tagName = if ($Version.StartsWith('v')) { $Version } else { "v$Version" }
        $tagCommit = & git rev-list -n 1 $tagName 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $tagCommit) {
            Add-Warning "Tag $tagName does not exist yet. Create an annotated release tag only after this audit passes."
        } else {
            Write-Host "Tag $tagName resolves to $($tagCommit.Trim())"
        }

        $citationVersion = if (Test-Path -LiteralPath 'CITATION.cff') {
            (Select-String -LiteralPath 'CITATION.cff' -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim('"')
        }
        $expectedCitationVersion = $tagName.TrimStart('v')
        if ($citationVersion -and $citationVersion -ne $expectedCitationVersion) {
            Add-Warning "CITATION.cff version '$citationVersion' differs from release tag '$tagName'. Review intentional RC version formatting."
        }

        if ($ChecksumFile) {
            if (-not (Test-Path -LiteralPath $ChecksumFile -PathType Leaf)) {
                Add-Error "Checksum manifest was not found: $ChecksumFile"
            } elseif ($ReleaseAsset.Count -eq 0) {
                Add-Warning 'A checksum manifest was supplied without a release asset to verify.'
            } else {
                foreach ($asset in $ReleaseAsset) {
                    if (-not (Test-Path -LiteralPath $asset -PathType Leaf)) {
                        Add-Error "Release asset was not found: $asset"
                        continue
                    }
                    $assetName = [IO.Path]::GetFileName($asset)
                    $expectedHash = Get-ExpectedAssetHash -Manifest $ChecksumFile -AssetName $assetName
                    if (-not $expectedHash) {
                        Add-Error "Checksum manifest has no entry for release asset: $asset"
                        continue
                    }
                    $actualHash = (Get-FileHash -LiteralPath $asset -Algorithm SHA256).Hash.ToUpperInvariant()
                    if ($actualHash -ne $expectedHash) {
                        Add-Error "Checksum mismatch for release asset: $asset"
                    } else {
                        Write-Host "Checksum verified: $assetName"
                    }
                    if ([IO.Path]::GetExtension($asset).Equals('.zip', [StringComparison]::OrdinalIgnoreCase)) {
                        Test-ZipAssetContents -Asset $asset
                    }
                }
            }
        } elseif ($ReleaseAsset.Count -gt 0) {
            Add-Warning 'Release assets were supplied without a checksum manifest.'
        } else {
            Add-Warning 'No release asset/checksum pair was supplied. Verify every uploaded GitHub Release asset after upload.'
        }

        Write-Host ''
        if ($warnings.Count -gt 0) {
            Write-Host 'Warnings requiring human review:' -ForegroundColor Yellow
            $warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
        }
        if ($errors.Count -gt 0) {
            Write-Host 'Blocking findings:' -ForegroundColor Red
            $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
            exit 1
        }
        if ($warnings.Count -gt 0) {
            Write-Host 'Readiness audit completed with human-review warnings.' -ForegroundColor Yellow
            exit 2
        }
        Write-Host 'Readiness audit passed. Complete the legal/IP and GitHub visibility gates before publication.' -ForegroundColor Green
        exit 0
    } finally {
        Pop-Location
    }
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
