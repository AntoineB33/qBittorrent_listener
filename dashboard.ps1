param([string]$CsvPath, [string]$StatsPath)

function Get-Score {
    param($totalSent, $fileSize, $timestamp, $dailyStats)
    
    if ($fileSize -le 0) { return 0 }
    
    $date = (Get-Date $timestamp).Date
    $today = (Get-Date).Date
    
    # 1. Day Weight: More recent = higher weight
    $daysOld = ($today - $date).Days
    $dayWeight = 1 / ($daysOld + 1)
    
    # 2. Check Time Weight: Based on monitoring duration for that day
    $stat = $dailyStats | Where-Object { $_.Date -eq ($date.ToString("yyyy-MM-dd")) }
    $seconds = if ($stat) { [double]$stat.TotalMonitorSeconds } else { 1 }
    $timeWeight = [Math]::Log($seconds + 1)
    
    # Ratio: Data Sent / File Size
    $ratio = $totalSent / $fileSize
    
    # Final Score Calculation
    return [Math]::Round(($ratio * $dayWeight * $timeWeight), 6)
}

while($true) {
    Clear-Host
    if (Test-Path $CsvPath) {
        try {
            $torrents = Invoke-RestMethod 'http://127.0.0.1:8080/api/v2/torrents/info'
            $logs = Import-Csv $CsvPath
            $dailyStats = Import-Csv $StatsPath

            $report = foreach ($t in $torrents) {
                $hash = $t.hash
                $files = Invoke-RestMethod "http://127.0.0.1:8080/api/v2/torrents/files?hash=$hash"
                $completionDate = if ($t.completion_on -gt 0) { 
                    [TimeZoneInfo]::ConvertTimeFromUtc((Get-Date "1970-01-01").AddSeconds($t.completion_on), [TimeZoneInfo]::Local) 
                } else { $null }

                foreach ($f in $files) {
                    $uniqueKey = "$($t.name)|$($f.name)"
                    
                    # Filter logs for THIS specific file
                    $fileLogs = $logs | Where-Object { "$($_.TorrentName)|$($_.FileName)" -eq $uniqueKey }
                    $totalSent = ($fileLogs | Measure-Object BytesAdded -Sum).Sum
                    
                    # Logic: Count unique days in logs since the completion date
                    $daysTracked = ($fileLogs | Select-Object -ExpandProperty Timestamp | ForEach-Object { (Get-Date $_).Date.ToShortDateString() } | Select-Object -Unique).Count

                    # Only include if tracked for 5 or more days
                    if ($daysTracked -ge 5) {
                        [PSCustomObject]@{
                            Name      = $f.name.PadRight(40).Substring(0,40)
                            Size      = "{0:N2} MB" -f ($f.size / 1MB)
                            Sent      = "{0:N2} MB" -f ($totalSent / 1MB)
                            Days      = $daysTracked
                            Score     = Get-Score $totalSent $f.size $t.timestamp $dailyStats
                        }
                    }
                }
            }

            Write-Host "--- Torrent Priority Dashboard (5+ Days Tracked) ---" -ForegroundColor Yellow
            Write-Host "Formula: (Sent/Size) * DayWeight * TimeWeight`n" -ForegroundColor Gray

            if ($report) {
                $report | Sort-Object Score | Format-Table Name, Size, Sent, Days, Score
            } else {
                Write-Host "No files have reached the 5-day monitoring threshold yet." -ForegroundColor DarkGray
            }
        }
        catch {
            Write-Host "Error connecting to qBittorrent API..." -ForegroundColor Red
        }
    } else {
        Write-Host "Waiting for log data..." -ForegroundColor Red
    }
    Start-Sleep -Seconds 10
}