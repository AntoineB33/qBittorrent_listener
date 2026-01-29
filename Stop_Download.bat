@echo off
echo Stopping Network Listener (TShark)...
:: /T kills child processes, /F forces it
taskkill /F /IM tshark.exe /T

echo.
echo Closing qBittorrent...
:: Added /F to force close and /T to ensure background threads die
taskkill /F /IM qbittorrent.exe /T

echo.
echo All processes stopped. Logging finished.
pause