# SPDX-License-Identifier: Apache-2.0
#requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Dispatcher = Join-Path $PSScriptRoot 'Invoke-OSWAP.ps1'

function Read-Required([string]$Prompt) {
    while ($true) {
        $value = Read-Host $Prompt
        if (-not [string]::IsNullOrWhiteSpace($value)) { return $value.Trim() }
        Write-Host 'A value is required.'
    }
}

function Get-RelativeChildPath([string]$Root, [string]$Child) {
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([char]92, [char]47) + [IO.Path]::DirectorySeparatorChar
    $childFull = [IO.Path]::GetFullPath($Child)
    if (-not $childFull.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside the preservation staging root: $childFull"
    }
    return $childFull.Substring($rootFull.Length)
}

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Arguments)
    & git @Arguments
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE." }
}

Write-Host 'OSWAP preservation workflow'
Write-Host ''
Write-Host 'This workflow does not promise invisibility from spyware or privileged monitoring.'
Write-Host 'If this device may be monitored, stop and move to a different trusted device.'
Write-Host 'OSWAP will not disable antivirus, logging, or other operating-system security controls.'
Write-Host ''

$trusted = Read-Host 'Type SAFE only if you have decided this device is appropriate for this preservation operation'
if ($trusted -cne 'SAFE') { throw 'Preservation cancelled. Use a trusted device before continuing.' }

$age = Get-Command age -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $age) {
    throw "The open-source 'age' encryption tool is required for the OSWAP reference preservation workflow. Install age separately, review it, then rerun 'oswap preserve'."
}

$sourceText = Read-Required 'Source file or directory to preserve'
$sourceItem = Get-Item -LiteralPath $sourceText -ErrorAction Stop
$sourcePath = $sourceItem.FullName

$defaultOutput = Join-Path $HOME 'OSWAP-Preserve'
$outputText = Read-Host "Output directory for encrypted package [$defaultOutput]"
if ([string]::IsNullOrWhiteSpace($outputText)) { $outputText = $defaultOutput }
$outputDirectory = [IO.Path]::GetFullPath($outputText)
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

$privateNote = Read-Host 'Optional private context note (stored only inside the encrypted package; press Enter to omit)'
$packageId = [Guid]::NewGuid().ToString('N')
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) "oswap-preserve-$packageId"
$payloadRoot = Join-Path $tempRoot 'payload'
$manifestPath = Join-Path $tempRoot 'manifest.json'
$zipPath = Join-Path $outputDirectory "$packageId.tmp.zip"
$encryptedPath = Join-Path $outputDirectory "$packageId.age"
$receiptPath = Join-Path $outputDirectory "$packageId.receipt.json"

try {
    New-Item -ItemType Directory -Path $payloadRoot -Force | Out-Null

    if ($sourceItem.PSIsContainer) {
        $targetRoot = Join-Path $payloadRoot $sourceItem.Name
        Copy-Item -LiteralPath $sourcePath -Destination $targetRoot -Recurse -Force
    } else {
        Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $payloadRoot $sourceItem.Name) -Force
    }

    $files = @()
    foreach ($file in @(Get-ChildItem -LiteralPath $payloadRoot -File -Recurse | Sort-Object FullName)) {
        $files += [pscustomobject]@{
            relative_path = Get-RelativeChildPath $payloadRoot $file.FullName
            length = [int64]$file.Length
            sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            last_write_utc = $file.LastWriteTimeUtc.ToString('o')
        }
    }

    if ($files.Count -lt 1) { throw 'The source contains no files to preserve.' }

    $manifest = [ordered]@{
        oswap_standard = '0.2.0'
        package_id = $packageId
        created_utc = [DateTime]::UtcNow.ToString('o')
        intent = 'survivor-controlled or user-controlled preservation; preservation is not publication'
        private_note = $privateNote
        source_kind = if ($sourceItem.PSIsContainer) { 'directory' } else { 'file' }
        source_leaf_name = $sourceItem.Name
        file_count = $files.Count
        files = $files
    }

    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

    Write-Host "Creating temporary local archive for package $packageId ..."
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
    [IO.Compression.ZipFile]::CreateFromDirectory($tempRoot, $zipPath, [IO.Compression.CompressionLevel]::Optimal, $false)

    Write-Host 'Encrypting package with age. Enter the encryption passphrase only in the age prompt.'
    & $age.Source '-p' '-o' $encryptedPath $zipPath
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $encryptedPath)) {
        throw "age encryption failed with exit code $LASTEXITCODE."
    }

    $cipherHash = (Get-FileHash -LiteralPath $encryptedPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $receipt = [ordered]@{
        oswap_standard = '0.2.0'
        package_id = $packageId
        created_utc = [DateTime]::UtcNow.ToString('o')
        ciphertext_file = [IO.Path]::GetFileName($encryptedPath)
        ciphertext_sha256 = $cipherHash
        plaintext_published = $false
        note = 'Receipt describes ciphertext only. Sensitive source metadata remains inside the encrypted package.'
    }
    $receipt | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $receiptPath -Encoding UTF8
} finally {
    Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host "Encrypted package: $encryptedPath"
Write-Host "Ciphertext receipt: $receiptPath"
Write-Host 'Temporary plaintext staging was deleted on a best-effort basis. Storage hardware may retain recoverable blocks.'
Write-Host 'Keep the age passphrase separate from replicated ciphertext.'
Write-Host ''

$replicate = Read-Host 'Replicate this ciphertext through an existing private/approved Git twin repository now? Type YES or press Enter for no'
if ($replicate -cne 'YES') {
    Write-Host 'Preservation completed locally. No remote repository was changed.'
    return
}

$gitRepoText = Read-Required 'Path to the existing Git repository approved for encrypted sensitive archives'
$gitRepo = [IO.Path]::GetFullPath($gitRepoText)
if (-not (Test-Path -LiteralPath $gitRepo -PathType Container)) { throw "Git repository path not found: $gitRepo" }

Push-Location -LiteralPath $gitRepo
try {
    Invoke-Git rev-parse --is-inside-work-tree *> $null

    $privacyAck = Read-Host 'Type PRIVATE to confirm you have reviewed this repository and its destinations for sensitive encrypted archival use'
    if ($privacyAck -cne 'PRIVATE') { throw 'Remote replication cancelled before staging.' }

    $archiveDirectory = Join-Path $gitRepo (Join-Path 'oswap-preserve' $packageId)
    New-Item -ItemType Directory -Path $archiveDirectory -Force | Out-Null

    $repoCipher = Join-Path $archiveDirectory ([IO.Path]::GetFileName($encryptedPath))
    $repoReceipt = Join-Path $archiveDirectory ([IO.Path]::GetFileName($receiptPath))
    Copy-Item -LiteralPath $encryptedPath -Destination $repoCipher -Force
    Copy-Item -LiteralPath $receiptPath -Destination $repoReceipt -Force

    $relativeCipher = "oswap-preserve/$packageId/$([IO.Path]::GetFileName($encryptedPath))"
    $relativeReceipt = "oswap-preserve/$packageId/$([IO.Path]::GetFileName($receiptPath))"

    Invoke-Git add -- $relativeCipher $relativeReceipt
    Write-Host 'Only the generic ciphertext package and ciphertext receipt are staged:'
    & git status --short -- $relativeCipher $relativeReceipt

    $commitAck = Read-Host 'Type ARCHIVE to create a local Git commit containing only these ciphertext paths'
    if ($commitAck -cne 'ARCHIVE') {
        & git reset -- $relativeCipher $relativeReceipt *> $null
        Remove-Item -LiteralPath $archiveDirectory -Recurse -Force -ErrorAction SilentlyContinue
        throw 'Preservation commit cancelled. Local encrypted package outside the Git repository remains intact.'
    }

    Invoke-Git commit --only -m "OSWAP preservation package $packageId" -- $relativeCipher $relativeReceipt
    $expression = Read-Host 'Twin replication expression [3]'
    if ([string]::IsNullOrWhiteSpace($expression)) { $expression = '3' }

    Write-Host 'OSWAP will now preview and then request explicit TWIN confirmation for semi-random destination publication.'
    & $Dispatcher 'push' "twin=$expression" -Execute
    if ($LASTEXITCODE -ne 0) { throw "Twin replication failed with exit code $LASTEXITCODE. The encrypted commit remains local for retry." }
} finally {
    Pop-Location
}

Write-Host 'Encrypted preservation package committed, replicated, and verified.'
