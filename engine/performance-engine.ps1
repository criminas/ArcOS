function Invoke-PerformanceEngine {

    Write-ArcLog "Applying aggressive performance profile."

    # =====================================================
    # Ensure Policy Paths Exist
    # =====================================================

    $AppPrivacy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
    if (-not (Test-Path $AppPrivacy)) {
        New-Item -Path $AppPrivacy -Force | Out-Null
    }

    $GameDVRPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
    if (-not (Test-Path $GameDVRPolicy)) {
        New-Item -Path $GameDVRPolicy -Force | Out-Null
    }

    # =====================================================
    # Disable Background UWP Apps
    # =====================================================

    try {
        Set-ItemProperty `
            -Path $AppPrivacy `
            -Name "LetAppsRunInBackground" `
            -Type DWord `
            -Value 2

        Write-ArcLog "Background apps disabled (policy enforced)."
    }
    catch {
        Write-ArcLog "Background app policy failed." "WARN"
    }

    # =====================================================
    # Disable SysMain (SSD systems benefit)
    # =====================================================

    try {
        Stop-Service SysMain -Force -ErrorAction SilentlyContinue
        Set-Service SysMain -StartupType Disabled -ErrorAction SilentlyContinue
        Write-ArcLog "SysMain disabled."
    }
    catch {}

    # =====================================================
    # Disable Windows Search Indexing
    # =====================================================

    try {
        Stop-Service WSearch -Force -ErrorAction SilentlyContinue
        Set-Service WSearch -StartupType Disabled -ErrorAction SilentlyContinue
        Write-ArcLog "Search indexing disabled."
    }
    catch {}

    # =====================================================
    # Disable Delivery Optimization
    # =====================================================

    try {
        Stop-Service DoSvc -Force -ErrorAction SilentlyContinue
        Set-Service DoSvc -StartupType Disabled -ErrorAction SilentlyContinue
        Write-ArcLog "Delivery Optimization disabled."
    }
    catch {}

    # =====================================================
    # Disable Consumer Experience & Tips
    # =====================================================

    try {
        $CDM = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"

        Set-ItemProperty -Path $CDM -Name "SubscribedContent-338388Enabled" -Value 0 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $CDM -Name "SubscribedContent-353698Enabled" -Value 0 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $CDM -Name "SubscribedContent-310093Enabled" -Value 0 -ErrorAction SilentlyContinue

        Write-ArcLog "Consumer features disabled."
    }
    catch {}

    # =====================================================
    # Disable Game DVR (Policy Level)
    # =====================================================

    try {
        Set-ItemProperty `
            -Path $GameDVRPolicy `
            -Name "AllowGameDVR" `
            -Type DWord `
            -Value 0

        Write-ArcLog "Game DVR disabled."
    }
    catch {}

    # =====================================================
    # Disable Hibernation (Frees Disk + Reduces Memory Image)
    # =====================================================

    try {
        powercfg -h off
        Write-ArcLog "Hibernation disabled."
    }
    catch {}

    # =====================================================
    # Memory Management Optimizations
    # =====================================================

    try {
        $MM = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

        Set-ItemProperty -Path $MM -Name "ClearPageFileAtShutdown" -Type DWord -Value 0
        Set-ItemProperty -Path $MM -Name "LargeSystemCache" -Type DWord -Value 0

        Write-ArcLog "Memory manager optimized."
    }
    catch {}

    # =====================================================
    # Disable Memory Compression (Optional but Aggressive)
    # =====================================================

    try {
        Disable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue
        Write-ArcLog "Memory compression disabled."
    }
    catch {}

    # =====================================================
    # High Performance Power Plan
    # =====================================================

    try {
        powercfg -setactive SCHEME_MIN
        Write-ArcLog "High performance power plan enabled."
    }
    catch {}

    # =====================================================
    # Remove Startup Bloat (Detection Only)
    # =====================================================

    try {
        Get-CimInstance Win32_StartupCommand |
        Where-Object { $_.Location -notlike "*Windows*" } |
        ForEach-Object {
            Write-ArcLog "Non-system startup item detected: $($_.Name)"
        }
    }
    catch {}

    Write-ArcLog "Aggressive performance profile applied."
}