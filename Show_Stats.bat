@echo off
set "FOLDER=C:\Users\antoi\Documents\Home\health\entertainment\videos\qBittorrent_listener"

powershell -NoProfile -ExecutionPolicy Bypass -File "%FOLDER%\Show_Stats.ps1"

echo.
echo PowerShell has finished execution.
pause