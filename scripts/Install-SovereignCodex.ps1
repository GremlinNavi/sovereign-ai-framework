<#
.SYNOPSIS
  Installs Sovereign AI Framework with local Ollama inference and open-source Codex CLI.

.DESCRIPTION
  Bootstraps a Windows installation of the Sovereign AI Framework, creates a
  Python virtual environment, configures local Ollama inference, validates the
  OSWAP AI configuration, and creates local launchers for OSWAP, the AI app,
  and Codex CLI.

  The installer prefers already-installed dependencies and only invokes the
  documented package/bootstrap path when a required tool is missing.

.PARAMETER InstallRoot
  Root directory used for the framework checkout, virtual environment, and
  generated launcher scripts.

.PARAMETER RepositoryUrl
  Git repository URL to clone when the framework checkout does not already
  exist.

.PARAMETER RepositoryName
  Directory name used for the cloned framework repository.

.PARAMETER ChatModel
  Local Ollama model used for normal chat inference.

.PARAMETER EmbeddingModel
  Local Ollama model used for embeddings.

.PARAMETER CodexModel
  Local Ollama model exposed to Codex CLI. Defaults to ChatModel when omitted.

.PARAMETER SkipCodexSmokeTest
  Skips the final read-only Codex integration smoke test.

.PARAMETER SkipRepositoryUpdate
  Prevents an existing repository checkout from being updated with git pull.

.EXAMPLE
  .\Install-SovereignCodex.ps1

  Installs with the default local models and installation root.

.EXAMPLE
  .\Install-SovereignCodex.ps1 -ChatModel 'qwen3:4b' -SkipCodexSmokeTest

  Installs the framework while skipping the final Codex smoke test.

.NOTES
  Windows 11 / PowerShell 5.1+. Remote inference and web research stay disabled
  by the generated default configuration. Review dependency installers and Git
  changes before using this script in a production or shared environment.
#>
#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$InstallRoot = (Join-Path $HOME "OSWAP"),
    [string]$RepositoryUrl = "https://github.com/GremlinNavi/oswap-ai-demonstrator.git",
    [string]$RepositoryName = "oswap-ai-demonstrator",
    [string]$ChatModel = "qwen3:4b",
    [string]$EmbeddingModel = "nomic-embed-text",
    [string]$CodexModel = "",
    [switch]$SkipCodexSmokeTest,
    [switch]$SkipRepositoryUpdate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$Version = "0.1.0"
$EndMarker = "# END OF INSTALLER: OSWAP-SOVEREIGN-CODEX-$Version"
if ([string]::IsNullOrWhiteSpace($CodexModel)) { $CodexModel = $ChatModel }

# Guard against partially copied installers before any dependency or repository work begins.
if ($MyInvocation.MyCommand.Path -and (Test-Path -LiteralPath $MyInvocation.MyCommand.Path)) {
    $self = Get-Content -LiteralPath $MyInvocation.MyCommand.Path -Raw
    if (-not $self.Contains($EndMarker)) { throw "Installer is incomplete or truncated. Expected: $EndMarker" }
}

$RepoPath = Join-Path $InstallRoot $RepositoryName
$BinPath = Join-Path $InstallRoot "bin"
$VenvPython = Join-Path $RepoPath ".venv\Scripts\python.exe"
$CodexLauncher = Join-Path $BinPath "Start-SovereignCodex.ps1"
$AILauncher = Join-Path $BinPath "Start-SovereignAI.ps1"
$OSWAPLauncher = Join-Path $BinPath "oswap.ps1"

# Helper functions centralize dependency resolution, process execution, and environment mutation.
function Step([string]$Text) { Write-Host ""; Write-Host "=== $Text ===" }
function Refresh-Path {
    $m = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $u = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = (@($m, $u) | Where-Object { $_ }) -join ";"
}
function Resolve-Exe([string]$Name, [string[]]$Fallbacks = @()) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($p in $Fallbacks) { if ($p -and (Test-Path -LiteralPath $p)) { return $p } }
    return $null
}
function Run([string]$Exe, [string[]]$Args = @()) { & $Exe @Args; if ($LASTEXITCODE -ne 0) { throw "'$Exe' exited with code $LASTEXITCODE." } }
function Winget-Install([string]$Id, [string]$Name) {
    Write-Host "Installing $Name..."
    & winget install --id $Id --exact --silent --disable-interactivity --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw "winget failed installing $Name ($Id)." }
    Refresh-Path
}
function Run-OfficialInstaller([string]$Uri, [string]$Name) {
    $tmp = Join-Path $env:TEMP ("oswap-" + [Guid]::NewGuid().ToString("N") + ".ps1")
    try {
        Write-Host "Downloading official $Name installer from $Uri"
        Invoke-WebRequest -Uri $Uri -OutFile $tmp -UseBasicParsing
        if ((Get-Item -LiteralPath $tmp).Length -lt 100) { throw "$Name installer download is unexpectedly small." }
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tmp
        if ($LASTEXITCODE -ne 0) { throw "$Name installer exited with code $LASTEXITCODE." }
    } finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
    Refresh-Path
}
function Test-Python312([string]$Path) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return $false }
    & $Path -c "import sys; raise SystemExit(0 if sys.version_info[:2] == (3,12) else 1)" 2>$null
    return ($LASTEXITCODE -eq 0)
}
function Find-Python312 {
    $candidates = @((Join-Path $env:LOCALAPPDATA "Programs\Python\Python312\python.exe"),(Join-Path $env:ProgramFiles "Python312\python.exe"))
    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if ($cmd) { $candidates += $cmd.Source }
    foreach ($p in ($candidates | Select-Object -Unique)) { if (Test-Python312 $p) { return $p } }
    $py = Get-Command py -ErrorAction SilentlyContinue
    if ($py) {
        $resolved = & $py.Source -3.12 -c "import sys; print(sys.executable)" 2>$null
        if ($LASTEXITCODE -eq 0 -and $resolved) {
            $p = [string]($resolved | Select-Object -Last 1)
            if (Test-Python312 $p) { return $p }
        }
    }
    return $null
}
function Ollama-Ready { try { $null = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/tags" -TimeoutSec 2; return $true } catch { return $false } }
function Start-Ollama([string]$Exe) {
    if (Ollama-Ready) { return }
    Start-Process -FilePath $Exe -ArgumentList "serve" -WindowStyle Hidden
    for ($i = 0; $i -lt 45; $i++) { Start-Sleep -Seconds 1; if (Ollama-Ready) { return } }
    throw "Ollama did not start on 127.0.0.1:11434."
}
function Pull-Model([string]$OllamaExe, [string]$Model) { Write-Host "Pulling/verifying model: $Model"; Run $OllamaExe @("pull", $Model) }
function Set-EnvLine([string]$Path, [string]$Name, [string]$Value) {
    $text = if (Test-Path -LiteralPath $Path) { Get-Content -LiteralPath $Path -Raw } else { "" }
    $pattern = "(?m)^\s*$([Regex]::Escape($Name))\s*=.*$"
    $line = "$Name=$Value"
    if ([Regex]::IsMatch($text, $pattern)) { $text = [Regex]::Replace($text, $pattern, $line) }
    else { if ($text -and -not $text.EndsWith("`n")) { $text += "`r`n" }; $text += "$line`r`n" }
    Set-Content -LiteralPath $Path -Value $text -Encoding UTF8
}

Step "Sovereign Codex installer v$Version"
if ($env:OS -ne "Windows_NT") { throw "This installer currently targets Windows." }
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw "winget is required to bootstrap Git/Python. Install or repair Microsoft App Installer, reopen PowerShell, and rerun." }

Step "Install Git"
$Git = Resolve-Exe "git" @((Join-Path $env:ProgramFiles "Git\cmd\git.exe"),(Join-Path ${env:ProgramFiles(x86)} "Git\cmd\git.exe"))
if (-not $Git) { Winget-Install "Git.Git" "Git"; $Git = Resolve-Exe "git" @((Join-Path $env:ProgramFiles "Git\cmd\git.exe")) }
if (-not $Git) { throw "git.exe could not be located." }

Step "Install Python 3.12"
$Python = Find-Python312
if (-not $Python) { Winget-Install "Python.Python.3.12" "Python 3.12"; $Python = Find-Python312 }
if (-not $Python) { throw "A usable Python 3.12 executable could not be located." }

Step "Install Ollama"
$Ollama = Resolve-Exe "ollama" @((Join-Path $env:LOCALAPPDATA "Programs\Ollama\ollama.exe"),(Join-Path $env:ProgramFiles "Ollama\ollama.exe"))
if (-not $Ollama) {
    Run-OfficialInstaller "https://ollama.com/install.ps1" "Ollama"
    $Ollama = Resolve-Exe "ollama" @((Join-Path $env:LOCALAPPDATA "Programs\Ollama\ollama.exe"),(Join-Path $env:ProgramFiles "Ollama\ollama.exe"))
}
if (-not $Ollama) { throw "ollama.exe could not be located." }

Step "Install open-source Codex CLI"
$Codex = Resolve-Exe "codex" @((Join-Path $env:LOCALAPPDATA "Programs\OpenAI\Codex\bin\codex.exe"))
if (-not $Codex) {
    Run-OfficialInstaller "https://chatgpt.com/codex/install.ps1" "OpenAI Codex CLI"
    $Codex = Resolve-Exe "codex" @((Join-Path $env:LOCALAPPDATA "Programs\OpenAI\Codex\bin\codex.exe"))
}
if (-not $Codex) { throw "codex.exe could not be located." }

Step "Clone/update Sovereign AI Framework"
New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
New-Item -ItemType Directory -Path $BinPath -Force | Out-Null
if (Test-Path -LiteralPath (Join-Path $RepoPath ".git")) {
    Run $Git @("-C", $RepoPath, "status", "--short")
    if (-not $SkipRepositoryUpdate) { Run $Git @("-C", $RepoPath, "pull", "--ff-only") }
} else {
    if (Test-Path -LiteralPath $RepoPath) { throw "$RepoPath exists but is not a Git repository." }
    Run $Git @("clone", $RepositoryUrl, $RepoPath)
}
if (-not (Test-Path -LiteralPath (Join-Path $RepoPath "oswap_config.py"))) { throw "Repository checkout does not contain oswap_config.py." }
if (-not (Test-Path -LiteralPath (Join-Path $RepoPath "scripts\Invoke-OSWAP.ps1"))) { throw "Repository checkout does not contain the OSWAP syntax dispatcher." }

Step "Configure Sovereign AI for local Ollama"
$EnvFile = Join-Path $RepoPath ".env"
$EnvExample = Join-Path $RepoPath ".env.example"
if (-not (Test-Path -LiteralPath $EnvFile)) {
    if (-not (Test-Path -LiteralPath $EnvExample)) { throw ".env.example is missing." }
    Copy-Item -LiteralPath $EnvExample -Destination $EnvFile
}
Set-EnvLine $EnvFile "OLLAMA_HOST" "http://127.0.0.1:11434"
Set-EnvLine $EnvFile "OLLAMA_MODEL" $ChatModel
Set-EnvLine $EnvFile "OLLAMA_EMBED_MODEL" $EmbeddingModel
Set-EnvLine $EnvFile "SOVEREIGN_AI_DEMONSTRATOR_CHAT_BACKEND" "ollama"
Set-EnvLine $EnvFile "SOVEREIGN_AI_DEMONSTRATOR_EMBEDDING_BACKEND" "ollama"
Set-EnvLine $EnvFile "SOVEREIGN_AI_DEMONSTRATOR_ENABLE_WEB_RESEARCH" "0"
Set-EnvLine $EnvFile "SOVEREIGN_AI_DEMONSTRATOR_ALLOW_REMOTE_BACKENDS" "0"

Step "Create Python environment"
if (-not (Test-Path -LiteralPath $VenvPython)) { Run $Python @("-m", "venv", (Join-Path $RepoPath ".venv")) }
Run $VenvPython @("-m", "pip", "install", "--upgrade", "pip")
Run $VenvPython @("-m", "pip", "install", "-r", (Join-Path $RepoPath "requirements.lock"))

Step "Start Ollama and pull models"
Start-Ollama $Ollama
Pull-Model $Ollama $ChatModel
if ($EmbeddingModel -ne $ChatModel) { Pull-Model $Ollama $EmbeddingModel }
if ($CodexModel -ne $ChatModel -and $CodexModel -ne $EmbeddingModel) { Pull-Model $Ollama $CodexModel }

Step "Validate OSWAP AI"
Push-Location $RepoPath
try {
    Run $VenvPython @("oswap_config.py", "--validate")
    Run $VenvPython @("oswap_config.py", "--health-check")
} finally { Pop-Location }

Step "Create launchers"
$repoLiteral = "'" + ($RepoPath -replace "'", "''") + "'"
$codexLiteral = "'" + ($Codex -replace "'", "''") + "'"
$modelLiteral = "'" + ($CodexModel -replace "'", "''") + "'"
$pythonLiteral = "'" + ($VenvPython -replace "'", "''") + "'"
$dispatcherLiteral = "'" + ((Join-Path $RepoPath "scripts\Invoke-OSWAP.ps1") -replace "'", "''") + "'"

# Generated launchers are intentionally small wrappers so their behavior remains easy to audit.
$oswapText = @'
#requires -Version 5.1
[CmdletBinding()]
param([Parameter(Position=0, ValueFromRemainingArguments=$true)][string[]]$Command, [switch]$Execute)
$Dispatcher=__DISPATCHER__
& $Dispatcher @Command -Execute:$Execute
exit $LASTEXITCODE
'@
$oswapText = $oswapText.Replace("__DISPATCHER__", $dispatcherLiteral)
Set-Content -LiteralPath $OSWAPLauncher -Value $oswapText -Encoding UTF8

$codexText = @'
#requires -Version 5.1
[CmdletBinding()]
param([string]$Task="", [string]$Model=__MODEL__, [switch]$AllowWrites)
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"
$Repo=__REPO__
$Codex=__CODEX__
$env:CODEX_OSS_BASE_URL="http://127.0.0.1:11434/v1"
Set-Location $Repo
if ([string]::IsNullOrWhiteSpace($Task)) { & $Codex --oss --local-provider ollama --model $Model; exit $LASTEXITCODE }
$Sandbox = if ($AllowWrites) {"workspace-write"} else {"read-only"}
if ($AllowWrites) { Write-Warning "Review Git diff before committing; Windows Codex sandbox behavior can vary by release." }
& $Codex exec --sandbox $Sandbox --oss --local-provider ollama --model $Model $Task
exit $LASTEXITCODE
'@
$codexText = $codexText.Replace("__MODEL__", $modelLiteral).Replace("__REPO__", $repoLiteral).Replace("__CODEX__", $codexLiteral)
Set-Content -LiteralPath $CodexLauncher -Value $codexText -Encoding UTF8

$aiText = @'
#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"
$Repo=__REPO__
$Python=__PYTHON__
Set-Location $Repo
& $Python -m app.main
exit $LASTEXITCODE
'@
$aiText = $aiText.Replace("__REPO__", $repoLiteral).Replace("__PYTHON__", $pythonLiteral)
Set-Content -LiteralPath $AILauncher -Value $aiText -Encoding UTF8

if (-not $SkipCodexSmokeTest) {
    Step "Read-only local Codex smoke test"
    $env:CODEX_OSS_BASE_URL = "http://127.0.0.1:11434/v1"
    Push-Location $RepoPath
    try {
        & $Codex exec --sandbox read-only --oss --local-provider ollama --model $CodexModel "Inspect this repository without modifying files. Reply exactly: Sovereign Codex local integration verified"
        if ($LASTEXITCODE -ne 0) { Write-Warning "Codex installed but the smoke test failed. Try a different local coding-capable Ollama model." }
    } finally { Pop-Location }
}

Step "Installation complete"
Write-Host "Repository: $RepoPath"
Write-Host "OSWAP syntax: & `"$OSWAPLauncher`" help"
Write-Host "OSWAP AI:     & `"$AILauncher`""
Write-Host "Local Codex:  & `"$CodexLauncher`""
Write-Host "Twin preview: & `"$OSWAPLauncher`" twin"
Write-Host "PEMDAS twin:  & `"$OSWAPLauncher`" 'twin=(9/3)'"
Write-Host "Hosted OpenAI inference is not required for this local Codex path."

# END OF INSTALLER: OSWAP-SOVEREIGN-CODEX-0.1.0
