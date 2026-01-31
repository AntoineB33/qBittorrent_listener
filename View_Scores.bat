@echo off
setlocal enabledelayedexpansion

:: --- CONFIGURATION ---
set "FOLDER=C:\Users\antoi\Documents\Home\health\entertainment\videos\qBittorrent_listener"
set "LOG_FILE=%FOLDER%\traffic_log.csv"
set "STATS_FILE=%FOLDER%\DailyStats.csv"

echo Launching Live Score Dashboard...
powershell -NoProfile -ExecutionPolicy Bypass -File "%FOLDER%\dashboard.ps1" -CsvPath "%LOG_FILE%" -StatsPath "%STATS_FILE%"

pause