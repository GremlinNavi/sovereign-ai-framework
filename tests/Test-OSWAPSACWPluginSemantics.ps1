# SPDX-License-Identifier: Apache-2.0
#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$DocRoot = Join-Path $RepoRoot 'docs\oswapsacw-chatgpt-plugin'
$TestingDoc = Get-Content -Raw (Join-Path $DocRoot 'OSWAPSACW_CHATGPT_PLUGIN_TESTING.md')
$Vectors = Get-Content -Raw (Join-Path $DocRoot 'OSWAPSACW_CHATGPT_PLUGIN_TEST_VECTORS.txt')

$requiredDocPatterns = @(
    'twin = cardinality',
    'joker = policy',
    'authorization subject',
    'MUST NOT require a one-human-to-one-principal mapping'
)
foreach ($pattern in $requiredDocPatterns) {
    if ($TestingDoc -notmatch [regex]::Escape($pattern)) {
        throw "Missing OSWAPSACW semantic contract text: $pattern"
    }
}

foreach ($case in @('CASE T01','CASE T02','CASE T03','CASE J01','CASE J02','CASE P01','CASE P02','CASE C01','CASE C02')) {
    if ($Vectors -notmatch [regex]::Escape($case)) { throw "Missing test vector: $case" }
}

Write-Output 'OSWAPSACW plugin semantic documentation snapshot passed.'
