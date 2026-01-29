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

:: --- START AGGREGATED LOGGING ---
:: We use a cleaner variable passing method to avoid quote hell
set "PS_COMMAND=$total = 0; $date = Get-Date -Format 'yyyy-MM-dd'; & 'C:\Program Files\Wireshark\tshark.exe' -i %ACTIVE_IF% -l -f 'port %QB_PORT%' -T fields -e frame.len | ForEach-Object { $total += [long]$_; $now = Get-Date -Format 'yyyy-MM-dd'; if ($now -ne $date) { \"$date,$($total/1MB)\" | Add-Content '%LOG_FILE%'; $total = 0; $date = $now; } }; \"$date,$($total/1MB)\" | Add-Content '%LOG_FILE%'"

powershell -ExecutionPolicy Bypass -Command "%PS_COMMAND%"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] TShark or PowerShell encountered an issue.
    echo Check if TShark is installed at the correct path.
    echo Ensure you are running as Administrator.
    pause
)