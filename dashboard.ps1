param([string]$CsvPath, [string]$StatsPath)

function Get-Score {
    param($totalSent, $timestamp, $dailyStats)
    
    # If no data sent, score is absolute zero
    if ($totalSent -le 0) { return 0 }

    $date = (Get-Date $timestamp).Date
    $today = (Get-Date).Date
    
    # 1. Day Weight: More recent = higher weight
    $daysOld = ($today - $date).Days
    $dayWeight = 1 / ($daysOld + 1)
    
    # 2. Check Time Weight: Based on monitoring duration for that day
    $stat = $dailyStats | Where-Object { $_.Date -eq ($date.ToString("yyyy-MM-dd")) }
    $seconds = if ($stat) { [double]$stat.TotalMonitorSeconds } else { 1 }
    $timeWeight = [Math]::Log($seconds + 1)
    
    # Final Score Calculation
    return [Math]::Round(($totalSent * $dayWeight * $timeWeight) / 1MB, 4)
}

while($true) {
    Clear-Host
    if (Test-Path $CsvPath) {
        $logs = Import-Csv $CsvPath
        $dailyStats = Import-Csv $StatsPath
        
        # Group logs by Name to calculate totals
        $groupedLogs = $logs | Group-Object Name
        
        $report = foreach ($group in $groupedLogs) {
            $totalSent = ($group.Group | Measure-Object SentBytes -Sum).Sum
            $lastEntry = $group.Group[-1]
            
            [PSCustomObject]@{
                Name      = $group.Name.PadRight(30).Substring(0,30)
                TotalSent = "{0:N2} MB" -f ($totalSent / 1MB)
                Status    = $lastEntry.Status
                Score     = Get-Score $totalSent $lastEntry.Timestamp $dailyStats
            }
        }

        Write-Host "--- Torrent Priority Dashboard (Worst to Best) ---" -ForegroundColor Yellow
        Write-Host "Sorted by: Lowest Score First`n" -ForegroundColor Gray

        # Sort Ascending (Worst Score -> Best Score)
        $report | Sort-Object Score | Format-Table Name, TotalSent, Status, Score
    } else {
        Write-Host "Waiting for log data in $CsvPath..." -ForegroundColor Red
    }
    Start-Sleep -Seconds 5
}