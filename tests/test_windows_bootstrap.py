# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_windows_installer_keeps_python_and_backend_boundaries_explicit():
    installer = (ROOT / "tools" / "Install-EternalThread.ps1").read_text(encoding="utf-8")
    lowered = installer.lower()

    assert "SPDX-FileCopyrightText: 2026 Nemi Prowse" in installer
    assert "SPDX-License-Identifier: Apache-2.0" in installer
    assert "[CmdletBinding(SupportsShouldProcess = $true" in installer
    assert "Assert-Python310OrNewer" in installer
    assert "Scripts\\python.exe" in installer
    assert "Assert-VenvPathDoesNotUseReparsePoints" in installer
    assert "ReparsePoint" in installer
    assert "-InstallOllamaClient" in installer
    assert "'.[ollama]'" in installer
    assert "shipped configuration defaults to the ollama adapter" in lowered
    assert "config.py', '--validate'" in installer
    assert "config.py', '--health-check'" in installer
    assert "Set-ExecutionPolicy".lower() not in lowered
    assert "ollama pull" not in lowered
    assert "ollama serve" not in lowered
    assert "git pull" not in lowered
    assert "copy-item" not in lowered


def test_windows_updater_only_allows_known_origins_and_fast_forwards():
    updater = (ROOT / "tools" / "Update-EternalThread.ps1").read_text(encoding="utf-8")
    lowered = updater.lower()

    assert "SPDX-FileCopyrightText: 2026 Nemi Prowse" in updater
    assert "[ValidateSet('origin')]" in updater
    assert "Test-ExpectedEternalThreadOrigin" in updater
    assert "github.com/GremlinNavi/sovereign-ai-framework" in updater
    assert "gitlab.com/eternal-thread-group/sovereign-ai-framework" in updater
    assert "Invoke-Git pull --ff-only $Remote $branch" in updater
    for prohibited in (
        "invoke-git reset",
        "invoke-git checkout",
        "invoke-git clean",
        "invoke-git stash",
        "invoke-git commit",
        "invoke-git push",
        "--force",
    ):
        assert prohibited not in lowered


def test_windows_install_documentation_describes_scoped_behavior_only():
    documentation = (ROOT / "WINDOWS_INSTALL.md").read_text(encoding="utf-8")
    lowered = documentation.lower()

    assert "Windows PowerShell 5.1" in documentation
    assert "Python 3.10" in documentation
    assert "Install-EternalThread.ps1" in documentation
    assert "Update-EternalThread.ps1" in documentation
    assert "git pull --ff-only origin <current-branch>" in documentation
    assert "not a sandbox or authenticity-verification" in lowered
    assert "symbolic link or junction" in lowered
    assert "Steam Deck".lower() not in lowered
    assert "Proton".lower() not in lowered
    assert "hot swapping" not in lowered
