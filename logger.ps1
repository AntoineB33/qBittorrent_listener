param([string]$CsvPath)

# Define path for daily stats (same folder as log)
$StatsPath = Join-Path (Split-Path $CsvPath) "DailyStats.csv"

# Initialize Files
if (-not (Test-Path $CsvPath)) {
    "Timestamp,Name,DownloadSpeed,UploadSpeed,SentBytes,Status" | Out-File -FilePath $CsvPath -Encoding utf8
}
if (-not (Test-Path $StatsPath)) {
    "Date,TotalMonitorSeconds" | Out-File -FilePath $StatsPath -Encoding utf8
}

$lastUploads = @{}

while($true) {
    try {
        $torrents = Invoke-RestMethod 'http://127.0.0.1:8080/api/v2/torrents/info'
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $currentDay = Get-Date -Format "yyyy-MM-dd"
        $currentTorrentNames = @()

        foreach($t in $torrents) {
            $name = $t.name
            $currentTorrentNames += $name
            $currentTotalUpload = [long]$t.uploaded 
            $downSpeed = $t.dlspeed
            $upSpeed = $t.upspeed

            if ($lastUploads.ContainsKey($name)) {
                $delta = $currentTotalUpload - $lastUploads[$name]
                
                # Log activity if data was sent
                if ($delta -gt 0) {
                    $logEntry = [PSCustomObject]@{
                        Timestamp     = $timestamp
                        Name          = $name
                        DownloadSpeed = $downSpeed
                        UploadSpeed   = $upSpeed
                        SentBytes     = $delta
                        Status        = "Active"
                    }
                    $logEntry | Export-Csv -Path $CsvPath -Append -NoTypeInformation
                }
            }
            $lastUploads[$name] = $currentTotalUpload
        }

        # --- FEATURE: REMOVED PACKET DETECTION ---
        $previousNames = $lastUploads.Keys | ForEach-Object { $_ }
        foreach ($oldName in $previousNames) {
            if ($oldName -notin $currentTorrentNames) {
                # Log that the torrent was removed
                $removeEntry = [PSCustomObject]@{
                    Timestamp     = $timestamp
                    Name          = $oldName
                    DownloadSpeed = 0
                    UploadSpeed   = 0
                    SentBytes     = 0
                    Status        = "REMOVED"
                }
                $removeEntry | Export-Csv -Path $CsvPath -Append -NoTypeInformation
                
                # Clean up the tracking variable
                $lastUploads.Remove($oldName)
                Write-Host "Removed: $oldName" -ForegroundColor Red
            }
        }

        # --- FEATURE: DAILY TIME TRACKING ---
        # Update daily stats file (+10 seconds)
        $stats = Import-Csv $StatsPath | Where-Object { $_.Date -eq $currentDay }
        if ($stats) {
            $newTime = [int]$stats.TotalMonitorSeconds + 10
            $allStats = Import-Csv $StatsPath | Where-Object { $_.Date -ne $currentDay }
            $allStats += [PSCustomObject]@{ Date = $currentDay; TotalMonitorSeconds = $newTime }
            $allStats | Export-Csv $StatsPath -NoTypeInformation
        } else {
            $newEntry = [PSCustomObject]@{ Date = $currentDay; TotalMonitorSeconds = 10 }
            $newEntry | Export-Csv $StatsPath -Append -NoTypeInformation
        }

        Write-Host "Monitoring $($torrents.Count) torrents... ($timestamp)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Waiting for qBittorrent API..." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 10
}