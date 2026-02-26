param([string]$CsvPath)

$StatsPath = Join-Path (Split-Path $CsvPath) "DailyStats.csv"

if (-not (Test-Path $CsvPath)) {
    "Timestamp,TorrentName,FileName,DownloadSpeed,BytesAdded,Status" | Out-File -FilePath $CsvPath -Encoding utf8
}
if (-not (Test-Path $StatsPath)) {
    "Date,TotalMonitorSeconds" | Out-File -FilePath $StatsPath -Encoding utf8
}

# Key format will be "TorrentName|FileName" to ensure uniqueness
$lastFileProgress = @{}

while($true) {
    try {
        $torrents = Invoke-RestMethod 'http://127.0.0.1:8080/api/v2/torrents/info'
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $currentDay = Get-Date -Format "yyyy-MM-dd"

        foreach($t in $torrents) {
            $hash = $t.hash
            $tName = $t.name
            
            # API Call to get specific files for THIS torrent
            $files = Invoke-RestMethod "http://127.0.0.1:8080/api/v2/torrents/files?hash=$hash"

            foreach($f in $files) {
                $fName = $f.name
                $currentDownloaded = [long]$f.completed
                $uniqueKey = "$tName|$fName"

                if ($lastFileProgress.ContainsKey($uniqueKey)) {
                    $delta = $currentDownloaded - $lastFileProgress[$uniqueKey]

                    if ($delta -gt 0) {
                        $logEntry = [PSCustomObject]@{
                            Timestamp     = $timestamp
                            TorrentName   = $tName
                            FileName      = $fName
                            DownloadSpeed = $t.dlspeed # Torrent-level speed (API doesn't give per-file speed)
                            BytesAdded    = $delta
                            Status        = "Downloading"
                        }
                        $logEntry | Export-Csv -Path $CsvPath -Append -NoTypeInformation
                    }
                }
                $lastFileProgress[$uniqueKey] = $currentDownloaded
            }
        }

        # --- DAILY TIME TRACKING (Keep your existing logic) ---
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

        Write-Host "Monitoring files in $($torrents.Count) torrents... ($timestamp)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Waiting for qBittorrent API or Hash error..." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 10
}