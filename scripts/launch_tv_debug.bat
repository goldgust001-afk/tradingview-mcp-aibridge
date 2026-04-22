@echo off
REM Launches TradingView Desktop with Chrome DevTools Protocol on port 9222.
REM Supports both MSIX (Microsoft Store / modern installer) and classic installs.
REM Auto-detects install path via Get-AppxPackage so version upgrades are handled automatically.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch_tv_debug.ps1" %*
echo.
pause
