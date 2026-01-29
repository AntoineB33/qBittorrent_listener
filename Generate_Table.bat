@echo off
setlocal
set "CONFIG_FILE=C:\Users\antoi\Documents\Home\health\entertainment\videos\qBittorrent_listener\config.txt"
for /f "usebackq delims=" %%x in ("%CONFIG_FILE%") do set "%%x"

powershell -NoProfile -Command ^
    "$data = Import-Csv '%LOG_FILE%' -Header Date,Time,Bytes;" ^
    "$report = $data | Group-Object Date | Select-Object " ^
    " @{n='Day';e={$_.Name}}, " ^
    " @{n='Packets';e={$_.Count}}, " ^
    " @{n='Total_MB';e={ [math]::Round(($_.Group | Measure-Object Bytes -Sum).Sum / 1MB, 2) }}; " ^
    "$report | Format-Table -AutoSize"

pause