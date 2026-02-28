$ErrorActionPreference = 'Stop'

# =====================================================
# Admin Validation
# =====================================================

$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ArcOS must be run as Administrator."
    exit 1
}

# =====================================================
# Windows Build Detection
# =====================================================

$Build = [int](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
$Global:CurrentBuild = $Build

# =====================================================
# Paths
# =====================================================

$root       = Split-Path -Parent $MyInvocation.MyCommand.Path
$enginePath = Join-Path $root 'engine'
$reportPath = Join-Path $root 'reports'
$manifest   = Join-Path $enginePath 'engine.manifest.json'

if (-not (Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath | Out-Null
}

# =====================================================
# Load Core Modules
# =====================================================

. "$enginePath\logger.ps1"
. "$enginePath\precheck.ps1"
. "$enginePath\rollback.ps1"
. "$enginePath\postcheck.ps1"

# Load Engines
Get-ChildItem "$enginePath\*-engine.ps1" | ForEach-Object {
    . $_.FullName
}

# =====================================================
# Metadata + Risk Handling
# =====================================================

$RiskOrder = @{
    "Stable"       = 1
    "Performance"  = 2
    "Minimal"      = 3
    "Experimental" = 4
}

$SelectedProfile = $env:ARCOS_PROFILE
if (-not $SelectedProfile) {
    $SelectedProfile = "Performance"
}

if (-not (Test-Path $manifest)) {
    Write-Host "Engine manifest missing."
    exit 1
}

$EngineManifest = Get-Content $manifest -Raw | ConvertFrom-Json

# =====================================================
# Engine Execution Wrapper
# =====================================================

$Global:RebootRequired = $false
$ExecutionReport = @()

function Invoke-EngineSafely {
    param (
        [string]$EngineName
    )

    if (-not $EngineManifest.$EngineName) {
        Write-ArcLog "$EngineName missing metadata." "WARN"
        return
    }

    $Meta = $EngineManifest.$EngineName

    if ($Global:CurrentBuild -lt $Meta.minBuild) {
        Write-ArcLog "$EngineName skipped (unsupported build)."
        return
    }

    if ($RiskOrder[$Meta.risk] -gt $RiskOrder[$SelectedProfile]) {
        Write-ArcLog "$EngineName skipped (risk tier)."
        return
    }

    $FunctionName = "Invoke-$EngineName"

    if (-not (Get-Command $FunctionName -ErrorAction SilentlyContinue)) {
        Write-ArcLog "$FunctionName not found." "ERROR"
        return
    }

    try {
        Write-ArcLog "Executing $EngineName"
        & $FunctionName

        if ($Meta.requiresReboot) {
            $Global:RebootRequired = $true
        }

        $ExecutionReport += @{
            Engine = $EngineName
            Status = "Success"
        }

        Write-ArcLog "$EngineName completed."
    }
    catch {
        Write-ArcLog "$EngineName failed: $($_.Exception.Message)" "ERROR"

        $ExecutionReport += @{
            Engine = $EngineName
            Status = "Failed"
        }
    }
}

# =====================================================
# Deployment Start
# =====================================================

Write-ArcLog "ArcOS deployment starting."
Invoke-Precheck
Initialize-Rollback

# Ordered execution
$EnginesToRun = @(
    "OneDriveEngine",
    "ServiceEngine",
    "TaskEngine",
    "AppxEngine",
    "RegistryEngine",
    "PolicyEngine",
    "AvatarEngine",
    "PerformanceEngine",
    "UIEngine",
    "WallpaperEngine"
)

foreach ($Engine in $EnginesToRun) {
    Invoke-EngineSafely -EngineName $Engine
}

Invoke-Postcheck

# =====================================================
# Reporting
# =====================================================

$ReportData = @{
    Timestamp     = Get-Date
    WindowsBuild  = $Global:CurrentBuild
    Profile       = $SelectedProfile
    Processes     = (Get-Process).Count
    Services      = (Get-Service).Count
    RAM_Used_MB   = [math]::Round(
        ((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize -
         (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory) / 1024
    )
    Engines       = $ExecutionReport
}

$ReportData | ConvertTo-Json -Depth 5 |
    Out-File (Join-Path $reportPath "deployment.json")

Write-ArcLog "ArcOS deployment complete."

# =====================================================
# Controlled Restart
# =====================================================

if ($Global:RebootRequired) {
    Write-Host ""
    Write-Host "Reboot required. Restarting in 5 seconds..."
    Start-Sleep -Seconds 5
    Restart-Computer -Force
}
else {
    Write-Host ""
    Write-Host "ArcOS completed. No reboot required."
}