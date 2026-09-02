# SPDX-License-Identifier: Apache-2.0

<#
.SYNOPSIS
  Runs regression checks for the OSWAP syntax dispatcher and twin arithmetic.

.DESCRIPTION
  Exercises command discovery, expression normalization, replication-factor
  semantics, fractional-copy behavior, and operator-precedence rejection cases.
  The test intentionally runs publication syntax in preview mode only.

.EXAMPLE
  .\Test-OSWAPSyntax.ps1

  Runs the complete OSWAP syntax self-test and throws on the first failure.
#>
#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$dispatcher = Join-Path $PSScriptRoot 'Invoke-OSWAP.ps1'

# Smoke-test command discovery before evaluating arithmetic behavior.
& $dispatcher 'help' *> $null
& $dispatcher 'help preserve' *> $null
& $dispatcher 'get oswap syntax' *> $null
& $dispatcher 'explain twin' *> $null
& $dispatcher 'explain preserve' *> $null

# Integer expression: deterministic factor and expression identifier.
$firstLine = (& $dispatcher 'push' 'twin=(9/3)' | Select-Object -First 1)
$result = $firstLine | ConvertFrom-Json
if ([double]$result.replication_factor -ne 3.0) { throw "Expected replication factor 3, got $($result.replication_factor)." }
if ($result.expression_id -ne 'l9d3r') { throw "Expected expression id l9d3r, got $($result.expression_id)." }
if ([int64]$result.guaranteed_copies -ne 3) { throw 'Expected 3 guaranteed copies.' }
if ([double]$result.extra_copy_probability -ne 0.0) { throw 'Expected no fractional extra-copy probability.' }

# Fractional factor: guaranteed floor(N) copies plus one probabilistic copy.
$fractionLine = (& $dispatcher 'push' 'twin=(4+3)/2' | Select-Object -First 1)
$fraction = $fractionLine | ConvertFrom-Json
if ([double]$fraction.replication_factor -ne 3.5) { throw "Expected replication factor 3.5, got $($fraction.replication_factor)." }
if ([int64]$fraction.guaranteed_copies -ne 3) { throw 'Expected 3 guaranteed copies for 3.5.' }
if ([double]$fraction.extra_copy_probability -ne 0.5) { throw 'Expected 0.5 extra-copy probability.' }
if ([int64]$fraction.max_possible_copies -ne 4) { throw 'Expected at most 4 complete copies for factor 3.5.' }

# Regression check: exponentiation binds before unary negation, yielding an invalid negative factor.
$precedenceFailed = $false
try { & $dispatcher 'push' 'twin=-2^2' *> $null } catch { $precedenceFailed = $true }
if (-not $precedenceFailed) { throw 'Expected -2^2 to resolve to -4 and be rejected as an invalid twin factor.' }

Write-Host 'OSWAP syntax self-test passed.'
