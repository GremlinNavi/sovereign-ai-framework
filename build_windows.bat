REM SPDX-FileCopyrightText: 2026 Nemi Prowse
REM SPDX-License-Identifier: Apache-2.0
@echo off
setlocal
python config.py --validate
if errorlevel 1 goto :failed
for /f "usebackq delims=" %%A in (`python config.py --build-name`) do set APP_NAME=%%A
if "%APP_NAME%"=="" goto :failed
python -m venv .venv
if errorlevel 1 goto :failed
call .venv\Scripts\activate.bat
REM Use the venv's bundled pip; do not upgrade packaging tools outside the reviewed locks.
python -m pip install -r requirements-build.lock
if errorlevel 1 goto :failed
python -m PyInstaller --noconfirm --clean --windowed --name "%APP_NAME%" launcher.py
if errorlevel 1 goto :failed
REM Generate release metadata from the reviewed, version-pinned build environment.
python tools\generate_release_metadata.py --root . --notices THIRD_PARTY_NOTICES.md --sbom SBOM.cdx.json
if errorlevel 1 goto :failed
set DIST_ROOT=dist\%APP_NAME%
set DOCS_ROOT=%DIST_ROOT%\Documentation
set LEGAL_ROOT=%DIST_ROOT%\Licences_and_Notices
set TOOLS_ROOT=%DIST_ROOT%\Tools
if not exist "%DOCS_ROOT%" mkdir "%DOCS_ROOT%"
if errorlevel 1 goto :failed
if not exist "%LEGAL_ROOT%" mkdir "%LEGAL_ROOT%"
if errorlevel 1 goto :failed
if not exist "%TOOLS_ROOT%" mkdir "%TOOLS_ROOT%"
if errorlevel 1 goto :failed
copy /Y START_HERE.txt "%DIST_ROOT%\START_HERE.txt" >nul
if errorlevel 1 goto :failed
copy /Y .env.example "%DIST_ROOT%\.env.example" >nul
if errorlevel 1 goto :failed
copy /Y README.txt "%DOCS_ROOT%\README.txt" >nul
if errorlevel 1 goto :failed
copy /Y SECURITY.md "%DOCS_ROOT%\SECURITY.md" >nul
if errorlevel 1 goto :failed
copy /Y PRIVACY.md "%DOCS_ROOT%\PRIVACY.md" >nul
if errorlevel 1 goto :failed
copy /Y UPSTREAM_REFERENCES.md "%DOCS_ROOT%\UPSTREAM_REFERENCES.md" >nul
if errorlevel 1 goto :failed
copy /Y ACCESSIBILITY_FORK.md "%DOCS_ROOT%\ACCESSIBILITY_FORK.md" >nul
if errorlevel 1 goto :failed
copy /Y tools\Set-EternalThreadGuiPreferences.ps1 "%TOOLS_ROOT%\Set-EternalThreadGuiPreferences.ps1" >nul
if errorlevel 1 goto :failed
copy /Y LICENSE "%LEGAL_ROOT%\LICENSE" >nul
if errorlevel 1 goto :failed
copy /Y NOTICE "%LEGAL_ROOT%\NOTICE" >nul
if errorlevel 1 goto :failed
copy /Y THIRD_PARTY_NOTICES.md "%LEGAL_ROOT%\THIRD_PARTY_NOTICES.md" >nul
if errorlevel 1 goto :failed
copy /Y SBOM.cdx.json "%LEGAL_ROOT%\SBOM.cdx.json" >nul
if errorlevel 1 goto :failed
echo.
echo Built: dist\%APP_NAME%\%APP_NAME%.exe
echo Start here: dist\%APP_NAME%\START_HERE.txt
endlocal
exit /b 0

:failed
echo.
echo Build failed. Read the error above; no usable EXE was created.
pause
endlocal
exit /b 1
