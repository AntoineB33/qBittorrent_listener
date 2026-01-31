param([string]$CsvPath, [string]$StatsPath)

function Get-Score {
    param($sentBytes, $timestamp, $dailyStats)
    
    $date = (Get-Date $timestamp).Date
    $today = (Get-Date).Date
    
    # 1. Day Weight: More recent = higher weight
    # (1 / (days old + 1)) -> Today = 1, Yesterday = 0.5, etc.
    $daysOld = ($today - $date).Days
    $dayWeight = 1 / ($daysOld + 1)
    
    # 2. Check Time Weight: Longer monitoring = higher weight
    $stat = $dailyStats | Where-Object { $_.Date -eq ($date.ToString("yyyy-MM-dd")) }
    $seconds = if ($stat) { [double]$stat.TotalMonitorSeconds } else { 1 }
    $timeWeight = [Math]::Log($seconds + 1) # Log scale so massive times don't break the UI
    
    # Calculation (Simplified ratio logic)
    return [Math]::Round(($sentBytes * $dayWeight * $timeWeight) / 1024, 4)
}

while($true) {
    Clear-Host
    if (Test-Path $CsvPath) {
        $data = Import-Csv $CsvPath
        $dailyStats = Import-Csv $StatsPath
        
        $report = $data | Group-Object Name | ForEach-Object {
            $lastEntry = $_.Group[-1]
            $totalSent = ($_.Group | Measure-Object SentBytes -Sum).Sum
            
            [PSCustomObject]@{
                Name       = $_.Name.PadRight(30).Substring(0,30)
                TotalSent  = "{0:N2} MB" -f ($totalSent / 1MB)
                LastSeen   = $lastEntry.Timestamp
                Status     = $lastEntry.Status
                Score      = Get-Score $totalSent $lastEntry.Timestamp $dailyStats
            }
        }

        Write-Host "--- Torrent Priority Dashboard ---" -ForegroundColor Yellow
        $report | Sort-Object Score -Descending | Format-Table Name, TotalSent, Status, Score
    } else {
        Write-Host "Waiting for log data..."
    }
    Start-Sleep -Seconds 5
}