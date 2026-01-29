@echo off
setlocal enabledelayedexpansion

:: --- LOAD CONFIGURATION ---
set CONFIG_FILE=C:\Users\antoi\Documents\Home\health\entertainment\videos\qBittorrent_listener\config.txt

if not exist %CONFIG_FILE% (
    echo Error: %CONFIG_FILE% not found.
    pause
    exit /b
)

for /f "delims=" %%x in (%CONFIG_FILE%) do (
    set "%%x"
)

:: ---------------------

echo Starting qBittorrent...
start "" "%QB_PATH%"

echo.
echo qBittorrent started.
echo Now initializing network listener (TShark)...
echo Logging traffic on Port %QB_PORT% to %LOG_FILE%...
echo DO NOT CLOSE THIS WINDOW. Run "Stop_Download.bat" to finish.

:: Start TShark to listen. 
:: -i 1 selects the first network interface (Change to 2 or 3 if you have multiple)
:: -f filters traffic only for the qBittorrent port to keep the log readable
:: >> appends to the log file
"C:\Program Files\Wireshark\tshark.exe" -i 1 -f "tcp port %QB_PORT% or udp port %QB_PORT%" >> "%LOG_FILE%"