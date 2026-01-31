param([string]$CsvPath)

# Fix: Create header with all 5 columns if it doesn't exist
if (-not (Test-Path $CsvPath)) {
    "Timestamp,Name,DownloadSpeed,UploadSpeed,SentBytes" | Out-File -FilePath $CsvPath -Encoding utf8
}

$lastUploads = @{}

while($true) {
    try {
        $torrents = Invoke-RestMethod 'http://127.0.0.1:8080/api/v2/torrents/info'
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        foreach($t in $torrents) {
            $name = $t.name
            $currentTotalUpload = [long]$t.uploaded 
            $downSpeed = $t.dlspeed
            $upSpeed = $t.upspeed

            if ($lastUploads.ContainsKey($name)) {
                $delta = $currentTotalUpload - $lastUploads[$name]
                
                if ($delta -gt 0) {
                    $logEntry = [PSCustomObject]@{
                        Timestamp     = $timestamp
                        Name          = $name
                        DownloadSpeed = $downSpeed
                        UploadSpeed   = $upSpeed
                        SentBytes     = $delta
                    }
                    $logEntry | Export-Csv -Path $CsvPath -Append -NoTypeInformation
                }
            }
            $lastUploads[$name] = $currentTotalUpload
        }
        Write-Host "Monitoring $($torrents.Count) torrents... ($timestamp)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Waiting for qBittorrent API..." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 10
}