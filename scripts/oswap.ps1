# SPDX-License-Identifier: Apache-2.0
#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)][string[]]$Command,
    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Core = Join-Path $PSScriptRoot 'Invoke-OSWAP.ps1'
$Dictionary = Join-Path $PSScriptRoot 'Invoke-OSWAPDictionary.ps1'
$Assist = Join-Path $PSScriptRoot 'Invoke-OSWAPAssist.ps1'
$text = (($Command | Where-Object { $null -ne $_ }) -join ' ').Trim()

if ($text -match '^dictionary\s+lookup\s+lang=([A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*)\s+term=(.+)$') {
    & $Dictionary -Language $Matches[1] -Term $Matches[2]
    return
}

if ($text -match '^assist\s+powershell\s+(.+)$') {
    & $Assist -Prompt $Matches[1]
    return
}

& $Core @Command -Execute:$Execute
