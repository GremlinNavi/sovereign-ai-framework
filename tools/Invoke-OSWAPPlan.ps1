[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Command,

    [ValidateRange(1, 1000000)]
    [int]$MaxTwins = 100,

    [string]$Python = "python"
)

$ErrorActionPreference = "Stop"
$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$PreviousPythonPath = $env:PYTHONPATH

try {
    if ($PreviousPythonPath) {
        $env:PYTHONPATH = "$RepositoryRoot$([IO.Path]::PathSeparator)$PreviousPythonPath"
    }
    else {
        $env:PYTHONPATH = $RepositoryRoot
    }

    & $Python -m app.oswap.cli --command $Command --max-twins $MaxTwins
    if ($LASTEXITCODE -ne 0) {
        throw "OSWAP planner exited with code $LASTEXITCODE"
    }
}
finally {
    $env:PYTHONPATH = $PreviousPythonPath
}
