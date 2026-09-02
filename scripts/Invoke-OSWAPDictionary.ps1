# SPDX-License-Identifier: Apache-2.0
#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidatePattern('^[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$')][string]$Language,
    [Parameter(Mandatory = $true)][ValidateLength(1, 256)][string]$Term,
    [string]$DataRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'oswap-syntax\data\dictionaries'),
    [ValidateRange(1, 50)][int]$Limit = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$languageTag = $Language.ToLowerInvariant()
$baseLanguage = ($languageTag -split '-')[0]
$candidates = @(
    (Join-Path $DataRoot "$languageTag.jsonl"),
    (Join-Path $DataRoot "$baseLanguage.jsonl"),
    (Join-Path $DataRoot 'all.jsonl')
) | Select-Object -Unique

$files = @($candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
if ($files.Count -eq 0) {
    throw "No local OSWAP dictionary index was found for '$Language'. Install or generate a licensed index under: $DataRoot"
}

$needle = $Term.Trim()
$results = New-Object System.Collections.Generic.List[object]
foreach ($file in $files) {
    foreach ($line in [IO.File]::ReadLines($file)) {
        if ($results.Count -ge $Limit) { break }
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try { $entry = $line | ConvertFrom-Json } catch { continue }
        $word = if ($entry.PSObject.Properties.Name -contains 'word') { [string]$entry.word } elseif ($entry.PSObject.Properties.Name -contains 'term') { [string]$entry.term } else { '' }
        if (-not $word.Equals($needle, [StringComparison]::OrdinalIgnoreCase)) { continue }
        $entryLanguage = if ($entry.PSObject.Properties.Name -contains 'lang_code') { [string]$entry.lang_code } elseif ($entry.PSObject.Properties.Name -contains 'language') { [string]$entry.language } else { $baseLanguage }
        if ($entryLanguage -and -not $entryLanguage.ToLowerInvariant().StartsWith($baseLanguage)) { continue }
        $results.Add($entry)
    }
    if ($results.Count -ge $Limit) { break }
}

if ($results.Count -eq 0) {
    Write-Host "No exact local dictionary match for '$Term' in '$Language'."
    return
}

$results | ConvertTo-Json -Depth 12
