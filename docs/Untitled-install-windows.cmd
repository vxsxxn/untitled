@echo off
REM ============================================================================
REM Untitled Installer for Windows - double-click this file.
REM ============================================================================
cd /d "%~dp0"

echo.
echo  Untitled Installer
echo  Downloading the installer...
echo.

powershell -ExecutionPolicy ByPass -NoProfile -Command "try { iex (irm 'https://untitled-aa.pages.dev/Untitled-install-windows.ps1') } catch { Write-Host $_.Exception.Message; exit 1 }"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  Installation didn't finish. The reason is printed above.
    echo  Fix it if you can, then run this file again.
    echo.
    pause
    exit /b 1
)

echo.
pause
