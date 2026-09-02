# SPDX-License-Identifier: Apache-2.0
#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$dispatcher = Join-Path $PSScriptRoot 'Invoke-OSWAP.ps1'

& $dispatcher 'help' *> $null
& $dispatcher 'help preserve' *> $null
& $dispatcher 'get oswap syntax' *> $null
& $dispatcher 'explain twin' *> $null
& $dispatcher 'explain preserve' *> $null

$uploadLine = (& $dispatcher 'upload' 'twin=(9/3)' | Select-Object -First 1)
$upload = $uploadLine | ConvertFrom-Json
if ([double]$upload.replication_factor -ne 3.0) { throw "Expected upload replication factor 3, got $($upload.replication_factor)." }
if ($upload.expression_id -ne 'l9d3r') { throw "Expected expression id l9d3r, got $($upload.expression_id)." }
if ([int64]$upload.guaranteed_copies -ne 3) { throw 'Expected 3 guaranteed upload copies.' }

$fractionLine = (& $dispatcher 'upload' 'twin=(4+3)/2' | Select-Object -First 1)
$fraction = $fractionLine | ConvertFrom-Json
if ([double]$fraction.replication_factor -ne 3.5) { throw "Expected upload replication factor 3.5, got $($fraction.replication_factor)." }
if ([int64]$fraction.guaranteed_copies -ne 3) { throw 'Expected 3 guaranteed upload copies for 3.5.' }
if ([double]$fraction.extra_copy_probability -ne 0.5) { throw 'Expected 0.5 upload extra-copy probability.' }
if ([int64]$fraction.max_possible_copies -ne 4) { throw 'Expected at most 4 complete upload copies for factor 3.5.' }

$downloadLine = (& $dispatcher 'download' 'twin=(6/3)' | Select-Object -First 1)
$download = $downloadLine | ConvertFrom-Json
if ([int64]$download.source_count -ne 2) { throw "Expected download source count 2, got $($download.source_count)." }
if ($download.consensus -ne 'unanimous') { throw 'Expected unanimous download consensus.' }
if ($download.selection -ne 'configured-order') { throw 'Expected deterministic configured-order download source selection.' }

$fractionalDownloadRejected = $false
try { & $dispatcher 'download' 'twin=2.5' *> $null } catch { $fractionalDownloadRejected = $true }
if (-not $fractionalDownloadRejected) { throw 'Expected fractional download source count to be rejected.' }

$singleSourceRejected = $false
try { & $dispatcher 'download' 'twin=1' *> $null } catch { $singleSourceRejected = $true }
if (-not $singleSourceRejected) { throw 'Expected single-source download verification to be rejected.' }

$precedenceFailed = $false
try { & $dispatcher 'upload' 'twin=-2^2' *> $null } catch { $precedenceFailed = $true }
if (-not $precedenceFailed) { throw 'Expected -2^2 to resolve to -4 and be rejected as an invalid twin factor.' }

Write-Host 'OSWAP canonical upload/download syntax self-test passed.'
