function Write-ExecutionReport {

    $Report = @{
        Timestamp      = Get-Date
        WindowsBuild   = $Global:CurrentBuild
        Processes      = (Get-Process).Count
        Services       = (Get-Service).Count
        RAM_Usage_MB   = [math]::Round((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize - (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory, 0) / 1024
    }

    $ReportPath = Join-Path $root "reports\deployment.json"

    if (-not (Test-Path (Join-Path $root "reports"))) {
        New-Item -ItemType Directory -Path (Join-Path $root "reports") | Out-Null
    }

    $Report | ConvertTo-Json -Depth 5 | Out-File $ReportPath
}