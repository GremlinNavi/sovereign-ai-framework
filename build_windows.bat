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
copy /Y LICENSE dist\%APP_NAME%\LICENSE >nul
if errorlevel 1 goto :failed
copy /Y NOTICE dist\%APP_NAME%\NOTICE >nul
if errorlevel 1 goto :failed
copy /Y THIRD_PARTY_NOTICES.md dist\%APP_NAME%\THIRD_PARTY_NOTICES.md >nul
if errorlevel 1 goto :failed
copy /Y SBOM.cdx.json dist\%APP_NAME%\SBOM.cdx.json >nul
if errorlevel 1 goto :failed
copy /Y README.txt dist\%APP_NAME%\README.txt >nul
if errorlevel 1 goto :failed
copy /Y SECURITY.md dist\%APP_NAME%\SECURITY.md >nul
if errorlevel 1 goto :failed
copy /Y PRIVACY.md dist\%APP_NAME%\PRIVACY.md >nul
if errorlevel 1 goto :failed
copy /Y .env.example dist\%APP_NAME%\.env.example >nul
if errorlevel 1 goto :failed
echo.
echo Built: dist\%APP_NAME%\%APP_NAME%.exe
endlocal
exit /b 0

:failed
echo.
echo Build failed. Read the error above; no usable EXE was created.
pause
endlocal
exit /b 1
