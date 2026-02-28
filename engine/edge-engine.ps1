function Invoke-EdgeEngine {

    Write-ArcLog "Disabling Microsoft Edge components."

    # Kill Edge
    Get-Process msedge -ErrorAction SilentlyContinue | Stop-Process -Force

    # Disable background mode
    $edgePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    if (-not (Test-Path $edgePolicy)) {
        New-Item -Path $edgePolicy -Force | Out-Null
    }

    Set-ItemProperty -Path $edgePolicy -Name "StartupBoostEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path $edgePolicy -Name "BackgroundModeEnabled" -Type DWord -Value 0

    # Remove startup entries
    Remove-ItemProperty `
        -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" `
        -Name "MicrosoftEdgeAutoLaunch*" `
        -ErrorAction SilentlyContinue

    Write-ArcLog "Edge background behavior disabled."
}