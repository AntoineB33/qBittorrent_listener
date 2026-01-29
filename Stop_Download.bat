@echo off
echo Stopping Network Listener (TShark)...
taskkill /F /IM tshark.exe /T

echo.
echo Closing qBittorrent...
:: Attempts to close gracefully first, then forces if needed
taskkill /IM qbittorrent.exe

echo.
echo All processes stopped. Logging finished.
pause