@echo off
title Torrent Score Dashboard

set "FOLDER=%~dp0"
set "CONFIG_FILE=%FOLDER%\config.txt"

if not exist "%CONFIG_FILE%" (echo [ERROR] Config missing & pause & exit /b)

:: Load variables from config.txt
for /f "usebackq delims=" %%x in ("%CONFIG_FILE%") do set "%%x"

:: --- CHECK IF LOGGER IS RUNNING ---
:: We check for a powershell process specifically running the logger script
tasklist /v /fi "IMAGENAME eq powershell.exe" | findstr /i "logger.ps1" >nul
if %errorlevel% neq 0 (
    echo [INFO] Logger is not running. Starting it now...
    start "" "%FOLDER%\Start_Download_And_Log.bat"
    
    :: Give it a moment to initialize the CSV before the dashboard tries to read it
    timeout /t 2 >nul
)

:: Launch the Dashboard
powershell -NoProfile -ExecutionPolicy Bypass -File "%FOLDER%\dashboard.ps1" -CsvPath "%LOG_FILE%" -StatsPath "%STATS_FILE%"
pause