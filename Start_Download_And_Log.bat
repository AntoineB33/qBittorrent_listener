@echo off
setlocal enabledelayedexpansion

:: --- LOAD CONFIGURATION ---
set "FOLDER=C:\Users\antoi\Documents\Home\health\entertainment\videos\qBittorrent_listener"
set "CONFIG_FILE=%FOLDER%\config.txt"

if not exist "%CONFIG_FILE%" (echo [ERROR] Config missing & pause & exit /b)

:: Load variables from config.txt
for /f "usebackq delims=" %%x in ("%CONFIG_FILE%") do set "%%x"

echo Starting qBittorrent...
start "" "%QB_PATH%"

echo --------------------------------------------------
echo LOGGING ACTIVE - KEEP THIS WINDOW OPEN
echo --------------------------------------------------

:: Run PS1 and pass the LOG_FILE path as an argument
powershell -NoProfile -ExecutionPolicy Bypass -File "%FOLDER%\logger.ps1" -CsvPath "%LOG_FILE%"

pause