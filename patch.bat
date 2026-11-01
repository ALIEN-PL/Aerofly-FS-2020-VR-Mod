@echo off
setlocal
cd /d "%~dp0"

echo ======================================================================
echo      Aerofly FS 2020 VR Mod Patcher (Meta Quest 2 / 3 / 3S / Pro)
echo ======================================================================
echo.

rem 1. Try running with Python first (fastest engine)
where python >nul 2>nul
if %ERRORLEVEL% equ 0 (
    python "%~dp0patcher_engine.py"
    if %ERRORLEVEL% equ 0 goto success
    goto error
)

rem 2. Fall back to PowerShell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0patch.ps1"
if %ERRORLEVEL% equ 0 goto success
goto error

:error
echo.
echo [!] An error occurred during the APK patching process.
echo     Make sure 'base.apk' is present in this folder and Java is installed.
echo.
pause
exit /b 1

:success
echo.
echo Press any key to exit...
pause >nul
exit /b 0
