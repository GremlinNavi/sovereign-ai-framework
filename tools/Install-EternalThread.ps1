# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0
<#
.SYNOPSIS
Creates or reuses a project-local Python virtual environment and installs Eternal Thread.

.DESCRIPTION
This Windows PowerShell 5.1+ and PowerShell 7+ helper keeps Python dependencies in
a project-local virtual environment. It preflights Python 3.10+, installs the base
package, and validates config.py with that virtual environment's Python executable.

It never changes the execution policy, creates or overwrites .env, makes a global
Python installation, installs an inference runtime, downloads a model, selects a
remote backend, or performs Git operations. The optional Ollama client is only the
Python package extra; it is not the Ollama runtime or any model.

.PARAMETER VenvPath
Project-relative virtual-environment path. The default is .venv. Existing path
components may not be symbolic links or junctions.

.PARAMETER PythonCommand
Python executable used only to create a missing virtual environment. It must be
Python 3.10 or newer.

.PARAMETER InstallOllamaClient
Opt in to install the project's optional .[ollama] Python dependency extra.

.PARAMETER HealthCheck
After the configuration check, deliberately contact only the already configured
backend endpoints and verify their selected models. It is off by default.

.EXAMPLE
.\tools\Install-EternalThread.ps1

.EXAMPLE
.\tools\Install-EternalThread.ps1 -InstallOllamaClient

.EXAMPLE
.\tools\Install-EternalThread.ps1 -HealthCheck
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [ValidateNotNullOrEmpty()]
    [string]$VenvPath = '.venv',

    [ValidateNotNullOrEmpty()]
    [string]$PythonCommand = 'python',

    [switch]$InstallOllamaClient,

    [switch]$HealthCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-ExternalCommand {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$ArgumentList,
        [Parameter(Mandatory)][string]$FailureMessage
    )

    & $FilePath @ArgumentList
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "$FailureMessage (exit code $exitCode)."
    }
}

function Assert-Python310OrNewer {
    param(
        [Parameter(Mandatory)][string]$PythonExecutable,
        [Parameter(Mandatory)][string]$Purpose
    )

    $versionOutput = & $PythonExecutable -c 'import sys; print(chr(46).join(map(str, sys.version_info[:3]))); raise SystemExit(0 if sys.version_info >= (3, 10) else 1)'
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "$Purpose must use Python 3.10 or newer. Select a supported Python with -PythonCommand or recreate the project virtual environment."
    }
    return (($versionOutput | Select-Object -Last 1).ToString().Trim())
}

function Resolve-ProjectRelativePath {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$RepositoryRoot
    )

    if ([IO.Path]::IsPathRooted($Path) -or $Path -match '(^|[\\/])\.\.([\\/]|$)') {
        throw 'VenvPath must be a project-relative path that does not traverse outside the repository.'
    }

    $fullPath = [IO.Path]::GetFullPath((Join-Path $RepositoryRoot $Path))
    $rootWithSeparator = $RepositoryRoot.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($rootWithSeparator, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'VenvPath must resolve inside the repository.'
    }
    return $fullPath
}

function Assert-VenvPathDoesNotUseReparsePoints {
    param(
        [Parameter(Mandatory)][string]$FullPath,
        [Parameter(Mandatory)][string]$RepositoryRoot
    )

    $rootItem = Get-Item -LiteralPath $RepositoryRoot -Force
    if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Refusing to create or reuse a virtual environment from a repository root that is a symbolic link or junction.'
    }

    $relativePath = $FullPath.Substring($RepositoryRoot.Length).TrimStart([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $currentPath = $RepositoryRoot
    foreach ($segment in $relativePath -split '[\\/]') {
        if (-not $segment) { continue }
        $currentPath = Join-Path $currentPath $segment
        $item = Get-Item -LiteralPath $currentPath -Force -ErrorAction SilentlyContinue
        if ($null -ne $item -and (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
            throw "VenvPath may not contain an existing symbolic link or junction: $currentPath"
        }
    }
}

try {
    $repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
    $venvFullPath = Resolve-ProjectRelativePath -Path $VenvPath -RepositoryRoot $repositoryRoot
    Assert-VenvPathDoesNotUseReparsePoints -FullPath $venvFullPath -RepositoryRoot $repositoryRoot
    $venvPython = Join-Path $venvFullPath 'Scripts\python.exe'
    $sourcePython = (Get-Command -Name $PythonCommand -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
    $sourcePythonVersion = Assert-Python310OrNewer -PythonExecutable $sourcePython -Purpose "The selected Python executable '$sourcePython'"

    Write-Output 'Eternal Thread Windows install bootstrap'
    Write-Output "Repository: $repositoryRoot"
    Write-Output "Bootstrap Python: $sourcePython ($sourcePythonVersion)"
    Write-Output "Virtual environment: $venvFullPath"

    if (Test-Path -LiteralPath (Join-Path $repositoryRoot '.env') -PathType Leaf) {
        Write-Output 'Existing .env detected: it will be preserved; configuration validation reads it without changing it.'
    } else {
        Write-Output 'No .env was created. Review .env.example and create local configuration manually if needed.'
    }

    if (Test-Path -LiteralPath $venvFullPath -PathType Leaf) {
        throw "Virtual-environment path is a file, not a directory: $venvFullPath"
    }

    if (-not (Test-Path -LiteralPath $venvFullPath -PathType Container)) {
        if (-not $PSCmdlet.ShouldProcess($venvFullPath, 'create a project-local Python virtual environment')) {
            Write-Output 'Install preview complete; no virtual environment, package, configuration, or backend changes were made.'
            return
        }
        Invoke-ExternalCommand -FilePath $sourcePython -ArgumentList @('-m', 'venv', $venvFullPath) -FailureMessage 'Could not create the project virtual environment'
        Write-Output "Created project-local virtual environment: $venvFullPath"
    }

    if (-not (Test-Path -LiteralPath $venvPython -PathType Leaf)) {
        throw "Existing virtual-environment directory does not contain Scripts\\python.exe: $venvFullPath. Refusing to replace it."
    }

    $venvPythonVersion = Assert-Python310OrNewer -PythonExecutable $venvPython -Purpose "The virtual environment at '$venvFullPath'"
    Write-Output "Virtual-environment Python: $venvPython ($venvPythonVersion)"

    if (-not $PSCmdlet.ShouldProcess($venvFullPath, 'install the Eternal Thread base Python package')) {
        Write-Output 'Install preview complete; no package, configuration, or backend changes were made.'
        return
    }

    Push-Location -LiteralPath $repositoryRoot
    try {
        Invoke-ExternalCommand -FilePath $venvPython -ArgumentList @('-m', 'pip', '--disable-pip-version-check', '--no-input', 'install', '.') -FailureMessage 'Base-package installation failed'
        Write-Output 'Installed Eternal Thread base package in the project-local virtual environment.'

        if ($InstallOllamaClient) {
            Invoke-ExternalCommand -FilePath $venvPython -ArgumentList @('-m', 'pip', '--disable-pip-version-check', '--no-input', 'install', '.[ollama]') -FailureMessage 'Optional Ollama Python-client installation failed'
            Write-Output 'Installed the optional Ollama Python client. No Ollama runtime was installed and no model was downloaded.'
        } else {
            Write-Warning 'The shipped configuration defaults to the Ollama adapter, but this base install excludes its optional Python client. Use -InstallOllamaClient if you intend to keep that adapter, or deliberately configure a supported alternative before launching the application.'
        }

        Invoke-ExternalCommand -FilePath $venvPython -ArgumentList @('config.py', '--validate') -FailureMessage 'Configuration validation failed'
        Write-Output 'Configuration validation completed with the selected virtual-environment Python.'

        if ($HealthCheck) {
            if ($PSCmdlet.ShouldProcess('the configured backend endpoints', 'run the explicitly requested backend health check')) {
                Invoke-ExternalCommand -FilePath $venvPython -ArgumentList @('config.py', '--health-check') -FailureMessage 'Configured-backend health check failed'
                Write-Output 'Configured-backend health check completed. No alternate backend was selected.'
            }
        } else {
            Write-Output 'Backend health check was not run. Use -HealthCheck only after deliberately selecting and starting the intended backend.'
        }
    } finally {
        Pop-Location
    }

    Write-Output 'Install bootstrap completed. No Git operation, inference-runtime installation, model download, remote-backend selection, or .env overwrite was performed.'
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
