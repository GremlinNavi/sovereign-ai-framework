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
$DownloadScript = Join-Path $PSScriptRoot 'Invoke-GitPullTwin.ps1'

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
            if ($operator -eq '*') { $value *= $rhs }
            else {
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
    if ($value -lt 1.0 -or $value -gt 1024.0) { throw 'Twin factor must be between 1 and 1024.' }

    $guaranteed = [int64][Math]::Floor($value)
    $fraction = $value - [double]$guaranteed
    if ([Math]::Abs($fraction) -lt 1e-12) { $fraction = 0.0 }

    [pscustomobject]@{
        raw_expression = $Expression
        normalized_expression = $normalized
        expression_id = ConvertTo-ExpressionId $normalized
        value = [Math]::Round($value, 12)
        guaranteed_whole = $guaranteed
        fractional_part = [Math]::Round($fraction, 12)
        ceiling_value = [int64][Math]::Ceiling($value)
    }
}

function Resolve-OSWAPUpload([string]$Expression) {
    $base = Resolve-OSWAPExpression $Expression
    [pscustomobject]@{
        raw_expression = $base.raw_expression
        normalized_expression = $base.normalized_expression
        expression_id = $base.expression_id
        replication_factor = $base.value
        guaranteed_copies = $base.guaranteed_whole
        extra_copy_probability = $base.fractional_part
        max_possible_copies = $base.ceiling_value
    }
}

function Resolve-OSWAPDownload([string]$Expression) {
    $base = Resolve-OSWAPExpression $Expression
    if ([Math]::Abs([double]$base.value - [Math]::Round([double]$base.value)) -gt 1e-12) {
        throw 'OSWAP download twin=N must resolve to a whole-number source count.'
    }
    $count = [int64][Math]::Round([double]$base.value)
    if ($count -lt 2) { throw 'OSWAP download twin=N requires at least two independent sources.' }
    [pscustomobject]@{
        raw_expression = $base.raw_expression
        normalized_expression = $base.normalized_expression
        expression_id = $base.expression_id
        source_count = $count
        consensus = 'unanimous'
        selection = 'configured-order'
    }
}

function Get-CryptoRandomUInt32 {
    $bytes = New-Object byte[] 4
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    return [BitConverter]::ToUInt32($bytes, 0)
}

function Get-CryptoRandomIndex([int]$MaxExclusive) {
    if ($MaxExclusive -lt 1) { throw 'Random selection requires a positive upper bound.' }
    return [int](([uint64](Get-CryptoRandomUInt32)) % [uint64]$MaxExclusive)
}

function Get-CryptoRandomUnit { return ([double](Get-CryptoRandomUInt32)) / 4294967296.0 }

function Select-OSWAPDestinations([string[]]$Urls, $Resolution) {
    if (-not $Urls -or $Urls.Count -lt 1) { throw 'No eligible twin destinations are configured.' }
    if ($Resolution.max_possible_copies -gt $Urls.Count) {
        throw "Replication factor $($Resolution.replication_factor) may require $($Resolution.max_possible_copies) destinations, but only $($Urls.Count) are configured."
    }
    $targetCount = [int]$Resolution.guaranteed_copies
    if ($Resolution.extra_copy_probability -gt 0.0 -and (Get-CryptoRandomUnit) -lt [double]$Resolution.extra_copy_probability) { $targetCount++ }
    $pool = New-Object 'System.Collections.Generic.List[string]'
    foreach ($url in $Urls) { [void]$pool.Add($url) }
    for ($i = $pool.Count - 1; $i -gt 0; $i--) {
        $j = Get-CryptoRandomIndex ($i + 1)
        $tmp = $pool[$i]; $pool[$i] = $pool[$j]; $pool[$j] = $tmp
    }
    return @($pool | Select-Object -First $targetCount)
}

function Get-TwinPushUrls {
    $urls = @(& git remote get-url --push --all twin 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $urls) { throw "Git remote 'twin' has no configured push URLs." }
    return @($urls | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Invoke-UploadTwin([string]$Expression) {
    $resolution = Resolve-OSWAPUpload $Expression
    Write-Output ($resolution | ConvertTo-Json -Compress)
    if (-not $Execute) {
        Write-Host 'Upload expression resolved in preview mode. Re-run with -Execute to select destinations and request publication.'
        return
    }
    & git rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) { throw 'upload twin=N must run inside a Git work tree.' }
    $branch = (& git branch --show-current | Select-Object -Last 1).Trim()
    if ([string]::IsNullOrWhiteSpace($branch)) { throw 'Detached HEAD is not supported for twin upload.' }
    $urls = Get-TwinPushUrls
    if ($resolution.max_possible_copies -gt $urls.Count) { throw "Replication factor $($resolution.replication_factor) cannot be satisfied by the $($urls.Count) configured twin destinations." }
    Write-Host "Branch: $branch"
    Write-Host 'Eligible twin destinations:'
    $urls | ForEach-Object { Write-Host " - $_" }
    $selected = Select-OSWAPDestinations $urls $resolution
    Write-Host 'Selected destinations for this upload:'
    $selected | ForEach-Object { Write-Host " - $_" }
    $confirmation = Read-Host 'Type TWIN to upload the current committed state to these destinations'
    if ($confirmation -cne 'TWIN') { throw 'Twin upload cancelled.' }
    $head = (& git rev-parse HEAD | Select-Object -Last 1).Trim()
    foreach ($url in $selected) {
        & git push $url "HEAD:refs/heads/$branch"
        if ($LASTEXITCODE -ne 0) { throw "Git upload failed for destination $url with exit code $LASTEXITCODE." }
        $remoteHead = @(& git ls-remote $url "refs/heads/$branch" 2>$null)
        if ($LASTEXITCODE -ne 0 -or -not $remoteHead) { throw "Post-upload verification failed for $url" }
        $remoteSha = ((@($remoteHead)[0].ToString().Trim()) -split '\s+')[0]
        if ($remoteSha -ne $head) { throw "Post-upload verification failed for $url: remote $remoteSha != local $head" }
    }
    Write-Host "Twin upload completed and SHA-verified across $($selected.Count) destination(s)."
}

function Invoke-DownloadTwin([string]$Expression) {
    $resolution = Resolve-OSWAPDownload $Expression
    Write-Output ($resolution | ConvertTo-Json -Compress)
    if (-not $Execute) {
        Write-Host 'Download expression resolved in preview mode. Re-run with -Execute to fetch the selected sources and require unanimous agreement.'
        return
    }
    if (-not (Test-Path -LiteralPath $DownloadScript -PathType Leaf)) { throw "Twin download engine is missing: $DownloadScript" }
    & $DownloadScript -RepositoryPath (Get-Location).Path -SourceCount ([int]$resolution.source_count)
}

function Invoke-Preserve {
    if (-not (Test-Path -LiteralPath $PreserveScript)) { throw "Preservation implementation is missing: $PreserveScript" }
    & $PreserveScript
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
if ($text -eq 'get oswap ai') { Write-Host "OSWAP AI repository: $RepoRoot"; return }
if ($text -eq 'preserve') { Invoke-Preserve; return }
if ($text -match '^upload\s+twin=(.+)$') { Invoke-UploadTwin $Matches[1]; return }
if ($text -match '^download\s+twin=(.+)$') { Invoke-DownloadTwin $Matches[1]; return }
if ($text -match '^(?:push\s+)?twin=(.+)$') {
    Write-Warning 'Deprecated OSWAP spelling. Use: oswap upload twin=N'
    Invoke-UploadTwin $Matches[1]; return
}
if ($text -match '^pull\s+twin=(.+)$') {
    Write-Warning 'Deprecated OSWAP spelling. Use: oswap download twin=N'
    Invoke-DownloadTwin $Matches[1]; return
}
throw "Unknown OSWAP syntax: $text"
