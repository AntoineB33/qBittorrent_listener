@echo off
setlocal enabledelayedexpansion

:: --- LOAD CONFIGURATION ---
set "CONFIG_FILE=C:\Users\antoi\Documents\Home\health\entertainment\videos\qBittorrent_listener\config.txt"

if not exist "%CONFIG_FILE%" (
    echo [ERROR] Config file not found at: "%CONFIG_FILE%"
    pause
    exit /b
)

:: Load variables (ensure config.txt has key=value format)
for /f "usebackq delims=" %%x in ("%CONFIG_FILE%") do set "%%x"

:: Verify variables loaded
if "%QB_PATH%"=="" (echo [ERROR] QB_PATH is missing from config & pause & exit /b)

echo Starting qBittorrent...
start "" "%QB_PATH%"

echo.
echo Searching for active network interface...

set "ACTIVE_IF="
for /f "tokens=1*" %%a in ('"C:\Program Files\Wireshark\tshark.exe" -D') do (
    echo %%b | findstr /i "Wi-Fi Ethernet" >nul
    if !errorlevel! equ 0 (
        set "IF_INDEX=%%a"
        :: Remove the trailing dot
        set "ACTIVE_IF=!IF_INDEX:.=!"
        set "IF_NAME=%%b"
        goto :FOUND_IF
    )
)

:FOUND_IF
if "%ACTIVE_IF%"=="" (
    echo [ERROR] Could not find a Wi-Fi or Ethernet interface.
    pause
    exit /b
)

echo Found Active Interface: %IF_NAME% (Index %ACTIVE_IF%)
echo Target Log: %LOG_FILE%
echo --------------------------------------------------

:: Start TShark
"C:\Program Files\Wireshark\tshark.exe" -i %ACTIVE_IF% -l -t ad -f "port %QB_PORT%" -T fields -e frame.time -e frame.len -e ip.src >> "%LOG_FILE%"

if %errorlevel% neq 0 (
    echo [ERROR] TShark failed to start. Are you running as Admin?
    pause
)