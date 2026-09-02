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

    function Peek-Token { if ($script:oswapPos -lt $script:oswapTokens.Count) { $script:oswapTokens[$script:oswapPos] } else { $null } }
    function Take-Token { $t = Peek-Token; if ($null -ne $t) { $script:oswapPos++ }; return $t }
    function Parse-Primary {
        $t = Take-Token
        if ($null -eq $t) { throw 'Unexpected end of expression.' }
        if ($t -eq '(') {
            $v = Parse-Expression
            if ((Take-Token) -ne ')') { throw 'Missing closing parenthesis.' }
            return [double]$v
        }
        $n = 0.0
        if (-not [double]::TryParse($t, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$n)) { throw "Expected number, got '$t'." }
        return $n
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
        $t = Peek-Token
        if ($t -eq '+') { [void](Take-Token); return Parse-Unary }
        if ($t -eq '-') { [void](Take-Token); return -(Parse-Unary) }
        return Parse-Power
    }
    function Parse-Term {
        $value = Parse-Unary
        while ((Peek-Token) -in @('*','/')) {
            $op = Take-Token
            $rhs = Parse-Unary
            if ($op -eq '*') { $value *= $rhs }
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
            $op = Take-Token
            $rhs = Parse-Term
            if ($op -eq '+') { $value += $rhs } else { $value -= $rhs }
        }
        return $value
    }

    $value = Parse-Expression
    if ($script:oswapPos -ne $script:oswapTokens.Count) { throw "Unexpected token '$((Peek-Token))'." }
    if ([double]::IsNaN($value) -or [double]::IsInfinity($value)) { throw 'Expression result is not finite.' }
    $rounded = [Math]::Round($value)
    if ([Math]::Abs($value - $rounded) -gt 1e-9) { throw 'Twin family result must be an integer.' }
    $family = [int64]$rounded
    if ($family -lt 1 -or $family -gt 1024) { throw 'Twin family result must be between 1 and 1024.' }

    [pscustomobject]@{
        raw_expression = $Expression
        normalized_expression = $normalized
        expression_id = ConvertTo-ExpressionId $normalized
        family_value = $family
    }
}

function Get-TwinPushUrls {
    $urls = @(& git remote get-url --push --all twin 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $urls) { throw "Git remote 'twin' has no configured push URLs." }
    return @($urls | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Invoke-Twin([string]$Expression = '') {
    $resolution = $null
    if ($Expression) {
        $resolution = Resolve-OSWAPExpression $Expression
        Write-Output ($resolution | ConvertTo-Json -Compress)
        if (-not $Execute) {
            Write-Host 'Expression resolved in preview mode. Use -Execute only after reviewing the destination mapping.'
            return
        }
    }

    & git rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) { throw 'twin must run inside a Git work tree.' }
    $urls = Get-TwinPushUrls
    if ($resolution -and $urls.Count -ne $resolution.family_value) {
        throw "Resolved twin family $($resolution.family_value) requires exactly $($resolution.family_value) configured push URLs; found $($urls.Count)."
    }

    Write-Host "Branch: $(& git branch --show-current)"
    Write-Host 'Working tree:'
    & git status --short
    Write-Host 'Twin destinations:'
    $urls | ForEach-Object { Write-Host " - $_" }

    if (-not $Execute) {
        Write-Host 'Preview only. Re-run with -Execute to request publication.'
        return
    }
    $confirmation = Read-Host 'Type TWIN to publish this state to the configured twin destinations'
    if ($confirmation -cne 'TWIN') { throw 'Twin publication cancelled.' }
    & git push twin
    if ($LASTEXITCODE -ne 0) { throw "git push twin failed with exit code $LASTEXITCODE." }
    foreach ($url in $urls) {
        & git ls-remote $url HEAD *> $null
        if ($LASTEXITCODE -ne 0) { throw "Post-push verification failed for $url" }
    }
    Write-Host 'Twin publication and endpoint reachability verification completed.'
}

$text = (($Command | Where-Object { $_ -ne $null }) -join ' ').Trim()
if (-not $text) { $text = 'help' }

if ($text -eq 'help') {
    Get-ChildItem -LiteralPath $CommandsRoot -Filter '*.json' | Sort-Object Name | ForEach-Object {
        $d = Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
        Write-Host ("{0,-10} {1}" -f $d.id, $d.summary)
    }
    exit 0
}
if ($text -match '^help\s+([a-z0-9-]+)$') {
    $d = Get-OSWAPCommandDefinition $Matches[1]
    $d.forms | ForEach-Object { Write-Host $_ }
    Write-Host $d.summary
    exit 0
}
if ($text -match '^explain\s+([a-z0-9-]+)$') {
    $name = $Matches[1]
    $d = Get-OSWAPCommandDefinition $name
    $d | ConvertTo-Json -Depth 8
    $knowledge = Join-Path $SyntaxRoot "knowledge\$name.md"
    if (Test-Path -LiteralPath $knowledge) { Write-Host ''; Get-Content -LiteralPath $knowledge }
    exit 0
}
if ($text -eq 'get oswap syntax') {
    Write-Host "OSWAP syntax $((Get-Content -LiteralPath (Join-Path $SyntaxRoot 'VERSION') -Raw).Trim())"
    Write-Host "Path: $SyntaxRoot"
    exit 0
}
if ($text -eq 'get oswap ai') {
    Write-Host "OSWAP AI repository: $RepoRoot"
    exit 0
}
if ($text -eq 'twin') { Invoke-Twin; exit 0 }
if ($text -match '^twin=(.+)$') { Invoke-Twin $Matches[1]; exit 0 }

throw "Unknown OSWAP syntax: $text"
