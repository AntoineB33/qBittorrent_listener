@echo off
setlocal enabledelayedexpansion

:: --- LOAD CONFIGURATION ---
set "CONFIG_FILE=C:\Users\antoi\Documents\Home\health\entertainment\videos\qBittorrent_listener\config.txt"

if not exist "%CONFIG_FILE%" (
    echo [ERROR] Config file not found at: "%CONFIG_FILE%"
    pause
    exit /b
)

for /f "usebackq delims=" %%x in ("%CONFIG_FILE%") do set "%%x"

:: Verify variables
if "%QB_PATH%"=="" (echo [ERROR] QB_PATH missing & pause & exit /b)
if "%LOG_FILE%"=="" (echo [ERROR] LOG_FILE missing & pause & exit /b)

echo Starting qBittorrent...
start "" "%QB_PATH%"

:: --- FIND INTERFACE ---
set "ACTIVE_IF="
for /f "tokens=1*" %%a in ('"C:\Program Files\Wireshark\tshark.exe" -D') do (
    echo %%b | findstr /i "Wi-Fi Ethernet" >nul
    if !errorlevel! equ 0 (
        set "IF_INDEX=%%a"
        set "ACTIVE_IF=!IF_INDEX:.=!"
        set "IF_NAME=%%b"
        goto :FOUND_IF
    )
)

:FOUND_IF
if "%ACTIVE_IF%"=="" (echo [ERROR] No interface found & pause & exit /b)

echo Logging to: %LOG_FILE%
echo --------------------------------------------------

:: Header creation (only if file doesn't exist)
if not exist "%LOG_FILE%" (
    echo Date,Time,Packet_Size_Bytes,Source_IP > "%LOG_FILE%"
)

:: --- START TSHARK ---
:: -E separator=,  -> Forces CSV formatting
:: -E header=n     -> We handle the header manually to avoid repeats
"C:\Program Files\Wireshark\tshark.exe" -i %ACTIVE_IF% -l -t ad -f "port %QB_PORT%" ^
-T fields -e frame.time_delta_displayed -e frame.time -e frame.len -e ip.src ^
-E separator=, -E quote=d >> "%LOG_FILE%"

if %errorlevel% neq 0 (
    echo [ERROR] TShark failed. Check Admin rights.
    pause
)