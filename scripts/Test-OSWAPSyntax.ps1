#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$dispatcher = Join-Path $PSScriptRoot 'Invoke-OSWAP.ps1'

& $dispatcher 'help' *> $null
& $dispatcher 'get oswap syntax' *> $null
& $dispatcher 'explain twin' *> $null

$firstLine = (& $dispatcher 'twin=(9/3)' | Select-Object -First 1)
$result = $firstLine | ConvertFrom-Json
if ($result.family_value -ne 3) { throw "Expected twin family 3, got $($result.family_value)." }
if ($result.expression_id -ne 'l9d3r') { throw "Expected expression id l9d3r, got $($result.expression_id)." }

$precedenceFailed = $false
try { & $dispatcher 'twin=-2^2' *> $null } catch { $precedenceFailed = $true }
if (-not $precedenceFailed) { throw 'Expected -2^2 to resolve to -4 and be rejected as an invalid twin family.' }

Write-Host 'OSWAP syntax self-test passed.'
