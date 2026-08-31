@echo off
setlocal
python config.py --validate
if errorlevel 1 goto :failed
for /f "usebackq delims=" %%A in (`python config.py --build-name`) do set APP_NAME=%%A
if "%APP_NAME%"=="" goto :failed
python -m venv .venv
if errorlevel 1 goto :failed
call .venv\Scripts\activate.bat
python -m pip install --upgrade pip
if errorlevel 1 goto :failed
python -m pip install -r requirements-build.lock
if errorlevel 1 goto :failed
python -m PyInstaller --noconfirm --clean --windowed --name "%APP_NAME%" launcher.py
if errorlevel 1 goto :failed
python tools\generate_third_party_notices.py --output THIRD_PARTY_NOTICES.md
if errorlevel 1 goto :failed
copy /Y LICENSE dist\%APP_NAME%\LICENSE >nul
copy /Y NOTICE dist\%APP_NAME%\NOTICE >nul
copy /Y THIRD_PARTY_NOTICES.md dist\%APP_NAME%\THIRD_PARTY_NOTICES.md >nul
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
