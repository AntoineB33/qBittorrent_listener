$CsvPath = "C:\Users\antoi\Documents\Home\health\entertainment\videos\qBittorrent_listener\traffic_log.csv"

if (-not (Test-Path $CsvPath)) {
    Write-Host "Error: CSV file not found at $CsvPath" -ForegroundColor Red
    return
}

# Force UTF8 to handle hidden characters and trim headers
$data = Import-Csv $CsvPath -Encoding utf8

if (-not $data) {
    Write-Host "CSV is empty." -ForegroundColor Yellow
    return
}

Write-Host "Found $($data.Count) rows in CSV. Processing..." -ForegroundColor Cyan

# Add a Date column and ensure SentBytes is treated as a Number
$data = $data | ForEach-Object {
    $datePart = ($_.Timestamp -split ' ')[0]
    $_ | Add-Member -MemberType NoteProperty -Name 'Date' -Value $datePart -Force
    $_ | Add-Member -MemberType NoteProperty -Name 'SentBytesNumeric' -Value ([long]$_.SentBytes) -Force
    $_
}

# Group and calculate totals
$dailySum = $data | Group-Object Name, Date | Select-Object `
    @{Name='Name';Expression={$_.Values[0]}}, 
    @{Name='Date';Expression={$_.Values[1]}}, 
    @{Name='TotalDay';Expression={($_.Group.SentBytesNumeric | Measure-Object -Sum).Sum}}

$allDates = $dailySum.Date | Where-Object {$_} | Select-Object -Unique | Sort-Object

if (-not $allDates) {
    Write-Host "No dates found. Check if the 'Timestamp' column header is correct." -ForegroundColor Red
    return
}

# Format for the GridView
$table = $dailySum | Group-Object Name | ForEach-Object {
    $obj = [PSCustomObject]@{ 'Torrent Name' = $_.Name }
    foreach ($day in $allDates) {
        $row = $_.Group | Where-Object Date -eq $day
        $val = if ($row) { $row.TotalDay } else { 0 }
        
        # Human readable sizes
        $disp = if ($val -ge 1GB) { "$([Math]::Round($val/1GB, 2)) GB" }
                elseif ($val -ge 1MB) { "$([Math]::Round($val/1MB, 2)) MB" }
                else { "$([Math]::Round($val/1KB, 2)) KB" }
        
        $obj | Add-Member -MemberType NoteProperty -Name $day -Value $disp
    }
    $obj
}

Write-Host "Launching GridView..." -ForegroundColor Green
$table | Out-GridView -Title "Daily Torrent Uploads" -Wait