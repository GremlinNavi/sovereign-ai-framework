# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0
<#
.SYNOPSIS
Sets local-only Eternal Thread desktop-interface preferences.

.DESCRIPTION
Writes a small UTF-8 JSON preference file in Eternal Thread's local data directory.
It can change the application theme, text scale, and opening-window size. It does
not modify source code, Git repositories, .env, inference runtimes, models, or any
Windows-wide setting. Use -WhatIf to preview and -Reset to remove the preference file.

.EXAMPLE
.\tools\Set-EternalThreadGuiPreferences.ps1 -Theme HighContrast -FontScale 125

.EXAMPLE
.\tools\Set-EternalThreadGuiPreferences.ps1 -WindowWidth 1280 -WindowHeight 900

.EXAMPLE
.\tools\Set-EternalThreadGuiPreferences.ps1 -Reset
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [ValidateSet('System', 'Light', 'Dark', 'HighContrast')]
    [string]$Theme,

    [ValidateRange(80, 200)]
    [int]$FontScale,

    [ValidateRange(760, 3840)]
    [int]$WindowWidth,

    [ValidateRange(500, 2160)]
    [int]$WindowHeight,

    [ValidateNotNullOrEmpty()]
    [string]$DataDirectory,

    [switch]$Reset
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-EternalThreadDataDirectory {
    if (-not [string]::IsNullOrWhiteSpace($DataDirectory)) {
        return [System.IO.Path]::GetFullPath($DataDirectory)
    }

    if (-not [string]::IsNullOrWhiteSpace($env:ETERNAL_THREAD_DATA_DIR)) {
        return [System.IO.Path]::GetFullPath($env:ETERNAL_THREAD_DATA_DIR)
    }

    $localAppData = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
    if (-not [string]::IsNullOrWhiteSpace($localAppData)) {
        return (Join-Path $localAppData 'EternalThread')
    }

    return (Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)) '.local\share\EternalThread')
}

function Read-ExistingPreferences {
    param([Parameter(Mandatory)][string]$Path)

    $defaults = [ordered]@{
        schema_version = 1
        theme = 'system'
        font_scale = 100
        window_width = 1100
        window_height = 760
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return ,$defaults
    }

    try {
        $existing = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "GUI preference file is not valid JSON: $Path. Correct it manually or run with -Reset."
    }
    foreach ($name in @('theme', 'font_scale', 'window_width', 'window_height')) {
        $property = $existing.PSObject.Properties[$name]
        if ($null -ne $property) {
            $defaults[$name] = $property.Value
        }
    }
    return ,$defaults
}

function Get-BoundedIntegerPreference {
    param(
        [Parameter(Mandatory)]$Value,
        [Parameter(Mandatory)][int]$Minimum,
        [Parameter(Mandatory)][int]$Maximum,
        [Parameter(Mandatory)][int]$Default
    )

    try {
        $number = [int]$Value
    } catch {
        return $Default
    }
    if ($number -lt $Minimum -or $number -gt $Maximum) {
        return $Default
    }
    return $number
}

try {
    $dataRoot = Get-EternalThreadDataDirectory
    $rootPath = [System.IO.Path]::GetPathRoot($dataRoot)
    if ($dataRoot -eq $rootPath) {
        throw 'Refusing to use a filesystem root as the GUI-preferences directory.'
    }
    $preferencesPath = Join-Path $dataRoot 'gui_preferences.json'

    if ($Reset) {
        if (-not (Test-Path -LiteralPath $preferencesPath -PathType Leaf)) {
            Write-Output "No GUI preference file exists: $preferencesPath"
            return
        }
        if ($PSCmdlet.ShouldProcess($preferencesPath, 'remove Eternal Thread GUI preferences and return to application defaults')) {
            Remove-Item -LiteralPath $preferencesPath -Force
            Write-Output "Removed GUI preference file: $preferencesPath"
        }
        return
    }

    $changesRequested = $PSBoundParameters.ContainsKey('Theme') -or
        $PSBoundParameters.ContainsKey('FontScale') -or
        $PSBoundParameters.ContainsKey('WindowWidth') -or
        $PSBoundParameters.ContainsKey('WindowHeight')
    if (-not $changesRequested) {
        Write-Output 'No preference change was requested. Use -Theme, -FontScale, -WindowWidth, -WindowHeight, or -Reset.'
        Write-Output "Preference location: $preferencesPath"
        return
    }

    $preferences = Read-ExistingPreferences -Path $preferencesPath
    if ($PSBoundParameters.ContainsKey('Theme')) { $preferences['theme'] = $Theme.ToLowerInvariant().Replace('highcontrast', 'high_contrast') }
    if ($PSBoundParameters.ContainsKey('FontScale')) { $preferences['font_scale'] = $FontScale }
    if ($PSBoundParameters.ContainsKey('WindowWidth')) { $preferences['window_width'] = $WindowWidth }
    if ($PSBoundParameters.ContainsKey('WindowHeight')) { $preferences['window_height'] = $WindowHeight }
    if ([string]$preferences['theme'] -notin @('system', 'light', 'dark', 'high_contrast')) { $preferences['theme'] = 'system' }
    $preferences['font_scale'] = Get-BoundedIntegerPreference -Value $preferences['font_scale'] -Minimum 80 -Maximum 200 -Default 100
    $preferences['window_width'] = Get-BoundedIntegerPreference -Value $preferences['window_width'] -Minimum 760 -Maximum 3840 -Default 1100
    $preferences['window_height'] = Get-BoundedIntegerPreference -Value $preferences['window_height'] -Minimum 500 -Maximum 2160 -Default 760
    $preferences['schema_version'] = 1

    if (-not (Test-Path -LiteralPath $dataRoot -PathType Container)) {
        if (-not $PSCmdlet.ShouldProcess($dataRoot, 'create the local Eternal Thread data directory')) {
            Write-Output 'Preview complete; no local preference directory or file was created.'
            return
        }
        New-Item -ItemType Directory -Path $dataRoot -Force | Out-Null
    }

    $json = $preferences | ConvertTo-Json -Depth 3
    if ($PSCmdlet.ShouldProcess($preferencesPath, 'write local Eternal Thread GUI preferences')) {
        $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($preferencesPath, $json + [Environment]::NewLine, $utf8WithoutBom)
        Write-Output "Saved local GUI preferences: $preferencesPath"
        Write-Output "Theme: $($preferences['theme']); text scale: $($preferences['font_scale'])%; opening window: $($preferences['window_width'])x$($preferences['window_height'])"
    }
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
