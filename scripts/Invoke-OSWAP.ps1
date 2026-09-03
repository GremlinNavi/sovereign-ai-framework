# SPDX-License-Identifier: Apache-2.0
#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Command,
    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$SyntaxRoot = Join-Path $RepoRoot 'oswap-syntax'
$CommandsRoot = Join-Path $SyntaxRoot 'commands'
$PreserveScript = Join-Path $PSScriptRoot 'Invoke-OSWAPPreserve.ps1'

function Get-OSWAPCommandDefinition([string]$Name) {
    $path = Join-Path $CommandsRoot "$Name.json"
    if (-not (Test-Path -LiteralPath $path)) { throw "Unknown OSWAP command: $Name" }
    return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
}

function ConvertTo-ExpressionId([string]$Expression) {
    $id = ($Expression -replace '\s+', '')
    $map = @{ '+'='p'; '-'='m'; '*'='x'; '/'='d'; '^'='e'; '('='l'; ')'='r'; '.'='q' }
    foreach ($key in $map.Keys) { $id = $id.Replace($key, $map[$key]) }
    return $id
}

function Resolve-OSWAPExpression([string]$Expression) {
    $normalized = ($Expression -replace '\s+', '')
    if ([string]::IsNullOrWhiteSpace($normalized)) { throw 'Expression is empty.' }
    if ($normalized -notmatch '^[0-9+\-*/^().]+$') { throw 'Expression contains characters outside the OSWAP arithmetic grammar.' }

    $matches = [regex]::Matches($normalized, '(?:\d+(?:\.\d+)?|\.\d+)|[+\-*/^()]')
    $tokens = @($matches | ForEach-Object { $_.Value })
    if (($tokens -join '') -ne $normalized) { throw 'Expression tokenization failed.' }

    $script:oswapTokens = $tokens
    $script:oswapPos = 0

    function Peek-Token {
        if ($script:oswapPos -lt $script:oswapTokens.Count) { return $script:oswapTokens[$script:oswapPos] }
        return $null
    }

    function Take-Token {
        $token = Peek-Token
        if ($null -ne $token) { $script:oswapPos++ }
        return $token
    }

    function Parse-Primary {
        $token = Take-Token
        if ($null -eq $token) { throw 'Unexpected end of expression.' }

        if ($token -eq '(') {
            $value = Parse-Expression
            if ((Take-Token) -ne ')') { throw 'Missing closing parenthesis.' }
            return [double]$value
        }

        $number = 0.0
        if (-not [double]::TryParse($token, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$number)) {
            throw "Expected number, got '$token'."
        }
        return $number
    }

    function Parse-Power {
        $left = Parse-Primary
        if ((Peek-Token) -eq '^') {
            [void](Take-Token)
            $right = Parse-Unary
            return [Math]::Pow([double]$left, [double]$right)
        }
        return $left
    }

    function Parse-Unary {
        $token = Peek-Token
        if ($token -eq '+') { [void](Take-Token); return Parse-Unary }
        if ($token -eq '-') { [void](Take-Token); return -(Parse-Unary) }
        return Parse-Power
    }

    function Parse-Term {
        $value = Parse-Unary
        while ((Peek-Token) -in @('*','/')) {
            $operator = Take-Token
            $rhs = Parse-Unary
            if ($operator -eq '*') {
                $value *= $rhs
            } else {
                if ([Math]::Abs([double]$rhs) -lt 1e-15) { throw 'Division by zero.' }
                $value /= $rhs
            }
        }
        return $value
    }

    function Parse-Expression {
        $value = Parse-Term
        while ((Peek-Token) -in @('+','-')) {
            $operator = Take-Token
            $rhs = Parse-Term
            if ($operator -eq '+') { $value += $rhs } else { $value -= $rhs }
        }
        return $value
    }

    $value = [double](Parse-Expression)
    if ($script:oswapPos -ne $script:oswapTokens.Count) { throw "Unexpected token '$((Peek-Token))'." }
    if ([double]::IsNaN($value) -or [double]::IsInfinity($value)) { throw 'Expression result is not finite.' }
    if ($value -lt 1.0 -or $value -gt 1024.0) { throw 'Twin replication factor must be between 1 and 1024.' }

    $guaranteed = [int64][Math]::Floor($value)
    $fraction = $value - [double]$guaranteed
    if ([Math]::Abs($fraction) -lt 1e-12) { $fraction = 0.0 }

    [pscustomobject]@{
        raw_expression = $Expression
        normalized_expression = $normalized
        expression_id = ConvertTo-ExpressionId $normalized
        replication_factor = [Math]::Round($value, 12)
        guaranteed_copies = $guaranteed
        extra_copy_probability = [Math]::Round($fraction, 12)
        max_possible_copies = [int64][Math]::Ceiling($value)
    }
}

function Get-CryptoRandomUInt32 {
    $bytes = New-Object byte[] 4
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    } finally {
        $rng.Dispose()
    }
    return [BitConverter]::ToUInt32($bytes, 0)
}

function Get-CryptoRandomIndex([int]$MaxExclusive) {
    if ($MaxExclusive -lt 1) { throw 'Random selection requires a positive upper bound.' }
    return [int](([uint64](Get-CryptoRandomUInt32)) % [uint64]$MaxExclusive)
}

function Get-CryptoRandomUnit {
    return ([double](Get-CryptoRandomUInt32)) / 4294967296.0
}

function Select-OSWAPDestinations([string[]]$Urls, $Resolution) {
    if (-not $Urls -or $Urls.Count -lt 1) { throw 'No eligible twin destinations are configured.' }
    if ($Resolution.max_possible_copies -gt $Urls.Count) {
        throw "Replication factor $($Resolution.replication_factor) may require $($Resolution.max_possible_copies) destinations, but only $($Urls.Count) are configured."
    }

    $targetCount = [int]$Resolution.guaranteed_copies
    if ($Resolution.extra_copy_probability -gt 0.0) {
        $roll = Get-CryptoRandomUnit
        if ($roll -lt [double]$Resolution.extra_copy_probability) { $targetCount++ }
    }

    $pool = New-Object 'System.Collections.Generic.List[string]'
    foreach ($url in $Urls) { [void]$pool.Add($url) }

    for ($i = $pool.Count - 1; $i -gt 0; $i--) {
        $j = Get-CryptoRandomIndex ($i + 1)
        $tmp = $pool[$i]
        $pool[$i] = $pool[$j]
        $pool[$j] = $tmp
    }

    return @($pool | Select-Object -First $targetCount)
}

function Get-TwinPushUrls {
    $urls = @(& git remote get-url --push --all twin 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $urls) { throw "Git remote 'twin' has no configured push URLs." }
    return @($urls | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Get-OSWAPDisplayUrl([string]$Url) {
    if ([string]::IsNullOrWhiteSpace($Url)) { return '<empty>' }
    return ($Url -replace '^(https?://)[^/@]+@', '$1***@')
}

function Invoke-Twin([string]$Expression = '') {
    $resolution = $null
    if ($Expression) {
        $resolution = Resolve-OSWAPExpression $Expression
        Write-Output ($resolution | ConvertTo-Json -Compress)
        if (-not $Execute) {
            Write-Host 'Expression resolved in preview mode. Add -Execute to inspect the destination pool, select destinations, and request publication.'
            return
        }
    }

    & git rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) { throw 'twin publication must run inside a Git work tree.' }

    $branch = (& git branch --show-current | Select-Object -Last 1).Trim()
    if ([string]::IsNullOrWhiteSpace($branch)) { throw 'Detached HEAD is not supported for twin publication.' }

    $urls = Get-TwinPushUrls
    if ($resolution -and $resolution.max_possible_copies -gt $urls.Count) {
        throw "Replication factor $($resolution.replication_factor) cannot be satisfied by the $($urls.Count) configured twin destinations."
    }

    Write-Host "Branch: $branch"
    Write-Host 'Working tree:'
    & git status --short
    Write-Host 'Eligible twin destinations:'
    $urls | ForEach-Object { Write-Host " - $(Get-OSWAPDisplayUrl $_)" }

    if ($resolution) {
        Write-Host "Replication factor: $($resolution.replication_factor)"
        Write-Host "Guaranteed complete copies: $($resolution.guaranteed_copies)"
        Write-Host "Additional complete-copy probability: $([Math]::Round(100 * $resolution.extra_copy_probability, 6))%"
    } else {
        Write-Host "Replication factor: all configured destinations ($($urls.Count))"
    }

    if (-not $Execute) {
        Write-Host 'Preview only. Re-run with -Execute to request publication to all configured destinations.'
        return
    }

    $selected = if ($resolution) { Select-OSWAPDestinations $urls $resolution } else { @($urls) }

    Write-Host 'Selected destinations for this operation:'
    $selected | ForEach-Object { Write-Host " - $(Get-OSWAPDisplayUrl $_)" }

    $confirmation = Read-Host 'Type TWIN to publish the current committed state to these destinations'
    if ($confirmation -cne 'TWIN') { throw 'Twin publication cancelled.' }

    $localHead = (& git rev-parse HEAD | Select-Object -Last 1).Trim()
    if ([string]::IsNullOrWhiteSpace($localHead)) { throw 'Unable to resolve the local HEAD for post-push verification.' }

    foreach ($url in $selected) {
        $displayUrl = Get-OSWAPDisplayUrl $url
        & git push $url "HEAD:refs/heads/$branch"
        if ($LASTEXITCODE -ne 0) { throw "Git push failed for destination $displayUrl with exit code $LASTEXITCODE." }

        $remoteHead = @(& git ls-remote $url "refs/heads/$branch" 2>$null)
        if ($LASTEXITCODE -ne 0 -or -not $remoteHead) {
            throw "Post-push verification failed for $displayUrl"
        }
        $remoteSha = (($remoteHead | Select-Object -First 1) -split '\s+')[0]
        if ($remoteSha -ne $localHead) {
            throw "Post-push verification mismatch for $displayUrl. Expected $localHead, got $remoteSha."
        }
    }

    Write-Host "Twin publication completed and verified across $($selected.Count) destination(s)."
}

function Invoke-Preserve {
    if (-not (Test-Path -LiteralPath $PreserveScript)) { throw "Preservation implementation is missing: $PreserveScript" }
    & $PreserveScript
    if ($LASTEXITCODE -ne 0) { throw "Preservation workflow exited with code $LASTEXITCODE." }
}

$text = (($Command | Where-Object { $_ -ne $null }) -join ' ').Trim()
if (-not $text) { $text = 'help' }

if ($text -eq 'help') {
    Get-ChildItem -LiteralPath $CommandsRoot -Filter '*.json' | Sort-Object Name | ForEach-Object {
        $definition = Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
        Write-Host ("{0,-10} {1}" -f $definition.id, $definition.summary)
    }
    return
}

if ($text -match '^help\s+([a-z0-9-]+)$') {
    $definition = Get-OSWAPCommandDefinition $Matches[1]
    $definition.forms | ForEach-Object { Write-Host $_ }
    Write-Host $definition.summary
    return
}

if ($text -match '^explain\s+([a-z0-9-]+)$') {
    $name = $Matches[1]
    $definition = Get-OSWAPCommandDefinition $name
    $definition | ConvertTo-Json -Depth 8
    $knowledge = Join-Path $SyntaxRoot "knowledge\$name.md"
    if (Test-Path -LiteralPath $knowledge) { Write-Host ''; Get-Content -LiteralPath $knowledge }
    return
}

if ($text -eq 'get oswap syntax') {
    Write-Host "OSWAP syntax $((Get-Content -LiteralPath (Join-Path $SyntaxRoot 'VERSION') -Raw).Trim())"
    Write-Host "Path: $SyntaxRoot"
    return
}

if ($text -eq 'get oswap ai') {
    Write-Host "OSWAP AI repository: $RepoRoot"
    return
}

if ($text -eq 'preserve') {
    Invoke-Preserve
    return
}

if ($text -in @('twin', 'upload twin', 'push twin')) {
    Invoke-Twin
    return
}

if ($text -match '^(?:(?:upload|push)\s+)?twin=(.+)$') {
    Invoke-Twin $Matches[1]
    return
}

throw "Unknown OSWAP syntax: $text"
