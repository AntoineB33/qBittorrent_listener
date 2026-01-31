@echo off
echo Stopping Logging Session...

:: 1. Kill the PowerShell logger first so it stops writing to the CSV
taskkill /F /FI "IMAGENAME eq powershell.exe" /FI "WINDOWTITLE eq *logger.ps1*" /T >nul 2>&1
taskkill /F /IM powershell.exe /T >nul 2>&1

echo.
echo Closing qBittorrent...
:: 2. Force close qBittorrent and all its child processes
taskkill /F /IM qbittorrent.exe /T

echo.
echo --------------------------------------------------
echo [SUCCESS] qBittorrent and Logger have been stopped.
echo --------------------------------------------------
pause