@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo  Claude Code Status Monitor - Installer
echo ==========================================
echo.

:: Check Node.js
where node >nul 2>&1
if !errorlevel! neq 0 (
    echo ERROR: Node.js is required but not found on PATH.
    echo Please install Node.js from https://nodejs.org/ and try again.
    pause
    exit /b 1
)

set "TARGET=%USERPROFILE%\.claude\scripts"
set "SCRIPTS_DIR=%~dp0scripts"

:: Check if .claude directory exists
if not exist "%USERPROFILE%\.claude\" (
    echo Creating %USERPROFILE%\.claude\ directory...
    mkdir "%USERPROFILE%\.claude"
)

:: Create scripts directory
if not exist "%TARGET%\" (
    mkdir "%TARGET%"
)

:: Copy script files
echo Installing scripts to %TARGET%\...
copy /Y "%SCRIPTS_DIR%\write-status.js"   "%TARGET%\write-status.js"
copy /Y "%SCRIPTS_DIR%\status-monitor.ps1" "%TARGET%\status-monitor.ps1"
copy /Y "%SCRIPTS_DIR%\launch-monitor.bat" "%TARGET%\launch-monitor.bat"
echo.

:: Configure hooks in settings.json
set "SETTINGS=%USERPROFILE%\.claude\settings.json"

if exist "%SETTINGS%" (
    :: Use Node.js to safely update JSON
    node "%SCRIPTS_DIR%\install-hooks.js" "%SETTINGS%"
    if !errorlevel! neq 0 (
        echo WARNING: Failed to update settings.json automatically.
        echo Please add hooks manually. See README.md for details.
    )
) else (
    :: Create settings.json with hooks
    echo Creating %SETTINGS% with hooks configuration...
    node "%SCRIPTS_DIR%\install-hooks.js" "%SETTINGS%" --create
)

echo.
echo Installation complete!
echo.
echo Starting the status monitor...
echo.

:: Launch the monitor
start /min powershell -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "%TARGET%\status-monitor.ps1"

echo Done. You should see a small status bar appear on your screen.
pause
