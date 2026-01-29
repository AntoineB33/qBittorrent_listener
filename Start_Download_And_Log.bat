@echo off
setlocal enabledelayedexpansion

:: --- LOAD CONFIGURATION ---
set CONFIG_FILE=C:\Users\antoi\Documents\Home\health\entertainment\videos\qBittorrent_listener\config.txt

if not exist "%CONFIG_FILE%" (
    echo Error: %CONFIG_FILE% not found.
    pause
    exit /b
)

for /f "usebackq delims=" %%x in ("%CONFIG_FILE%") do set "%%x"

:: ---------------------

echo Starting qBittorrent...
start "" "%QB_PATH%"

echo.
echo Initializing TShark (Line-buffered mode)...
echo Monitoring Port: %QB_PORT%
echo Target Log: %LOG_FILE%

:: Find the active interface name
for /f "tokens=1,2" %%a in ('"C:\Program Files\Wireshark\tshark.exe" -D') do (
    :: This checks if the line contains "Wi-Fi" or "Ethernet"
    echo %%b | findstr /i "Wi-Fi Ethernet" >nul
    if !errorlevel! equ 0 (
        set ACTIVE_IF=%%a
        :: Strip the dot from the index (e.g., "4." becomes "4")
        set ACTIVE_IF=!ACTIVE_IF:.=!
        echo Found Active Interface: %%b (Index !ACTIVE_IF!)
    )
)

:: Start TShark using the dynamically found interface
:: -l : Flush output per line (prevents empty files on crash/kill)
:: -T fields: Outputs specific data fields for easier calculation
:: -e frame.len: Captures the packet size in bytes
:: -e frame.time_iso: Captures the date and time
"C:\Program Files\Wireshark\tshark.exe" -i %ACTIVE_IF% -l -f "port %QB_PORT%" -T fields -e frame.time_iso -e frame.len -e ip.src >> "%LOG_FILE%"