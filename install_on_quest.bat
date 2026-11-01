@echo off
setlocal
cd /d "%~dp0"
title Meta Quest VR Mod Setup - Aerofly FS 2020

echo ========================================================
echo   Aerofly FS 2020 - Meta Quest VR Mod Installer/Setup
echo ========================================================
echo.

where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell is required to run this installer.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_on_quest.ps1" %*
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Installation/Setup failed. Please check the error messages above.
    echo.
    pause
    exit /b %ERRORLEVEL%
)

echo.
pause
exit /b 0
