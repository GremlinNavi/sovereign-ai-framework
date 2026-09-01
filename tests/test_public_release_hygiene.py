# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_packaging_metadata_keeps_ollama_client_optional():
    metadata = (ROOT / "pyproject.toml").read_text(encoding="utf-8")
    base_metadata, extras = metadata.split("[project.optional-dependencies]", maxsplit=1)

    assert "ollama==" not in base_metadata
    assert 'ollama = ["ollama==0.6.2"]' in extras
    assert "ollama==0.6.2" in (ROOT / "requirements.lock").read_text(encoding="utf-8")


def test_windows_build_copies_required_public_release_materials():
    build_script = (ROOT / "build_windows.bat").read_text(encoding="utf-8")

    assert "generate_release_metadata.py" in build_script
    for asset in (
        "LICENSE",
        "NOTICE",
        "THIRD_PARTY_NOTICES.md",
        "SBOM.cdx.json",
        "README.txt",
        "SECURITY.md",
        "PRIVACY.md",
        ".env.example",
    ):
        assert f"copy /Y {asset}" in build_script


def test_windows_build_uses_a_shallow_accessible_package_layout():
    build_script = (ROOT / "build_windows.bat").read_text(encoding="utf-8")
    start_here = (ROOT / "START_HERE.txt").read_text(encoding="utf-8")

    assert "set DOCS_ROOT=%DIST_ROOT%\\Documentation" in build_script
    assert "set LEGAL_ROOT=%DIST_ROOT%\\Licences_and_Notices" in build_script
    assert 'copy /Y START_HERE.txt "%DIST_ROOT%\\START_HERE.txt"' in build_script
    assert 'copy /Y README.txt "%DOCS_ROOT%\\README.txt"' in build_script
    assert 'copy /Y LICENSE "%LEGAL_ROOT%\\LICENSE"' in build_script
    assert "EternalThread.exe" in start_here
    assert "This package does not include an AI runtime, model weights, or a cloud fallback." in start_here


def test_owned_executable_and_release_automation_sources_have_spdx_headers():
    owned_sources = [
        ROOT / "build_windows.bat",
        ROOT / "tools" / "Install-EternalThread.ps1",
        ROOT / "tools" / "Push-RepositoryUpdate.ps1",
        ROOT / "tools" / "Test-PublicReleaseReadiness.ps1",
        ROOT / "tools" / "Update-EternalThread.ps1",
        ROOT / ".github" / "workflows" / "ci.yml",
        ROOT / ".github" / "dependabot.yml",
    ]

    for source in owned_sources:
        text = source.read_text(encoding="utf-8")
        assert "SPDX-FileCopyrightText: 2026 Nemi Prowse" in text
        assert "SPDX-License-Identifier: Apache-2.0" in text


def test_pull_request_ci_enforces_dco_signoff_without_write_permissions():
    workflow = (ROOT / ".github" / "workflows" / "ci.yml").read_text(encoding="utf-8")

    assert "name: DCO sign-off" in workflow
    assert "Signed-off-by:" in workflow
    assert "github.event_name == 'pull_request'" in workflow
    assert "permissions:\n  contents: read" in workflow


def test_release_readiness_helper_remains_read_only_by_design():
    helper = (ROOT / "tools" / "Test-PublicReleaseReadiness.ps1").read_text(encoding="utf-8").lower()

    for prohibited_command in ("git add", "git commit", "git push", "git reset", "git clean", "remove-item"):
        assert prohibited_command not in helper


def test_local_professionalism_audit_outputs_are_never_release_material():
    gitignore = (ROOT / ".gitignore").read_text(encoding="utf-8")
    helper = (ROOT / "tools" / "Test-PublicReleaseReadiness.ps1").read_text(encoding="utf-8")

    for path in (".professionalism-audit-data/", ".professionalism-audit-pytest/", "*.spec"):
        assert path in gitignore
    assert ".professionalism-audit-(data|pytest)" in helper
    assert "\\.spec$" in helper


def test_generated_third_party_notices_have_no_trailing_whitespace():
    notices = (ROOT / "THIRD_PARTY_NOTICES.md").read_text(encoding="utf-8")

    assert all(line == line.rstrip() for line in notices.splitlines())


def test_readiness_helper_treats_missing_release_tags_as_warnings():
    helper = (ROOT / "tools" / "Test-PublicReleaseReadiness.ps1").read_text(encoding="utf-8")

    assert "git rev-parse -q --verify" in helper
    assert "A missing pre-release tag is a normal readiness warning" in helper
