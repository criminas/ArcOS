@echo off
title ArcOS Uninstaller

echo.
echo =============================
echo        ArcOS Uninstaller
echo =============================
echo.

:: --- Check for Administrator ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit
)

cd /d "%~dp0"

echo Running ArcOS removal script...
powershell -ExecutionPolicy Bypass -NoProfile -Command ^
""

# ===============================
# ArcOS Removal Script
# ===============================

Write-Host 'Restoring UI settings...'

# Restore transparency
Set-ItemProperty `
  -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' `
  -Name 'EnableTransparency' -Value 1 -ErrorAction SilentlyContinue

# Restore animations
Set-ItemProperty `
  -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' `
  -Name 'MinAnimate' -Value '1' -ErrorAction SilentlyContinue

Set-ItemProperty `
  -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' `
  -Name 'VisualFXSetting' -Value 0 -ErrorAction SilentlyContinue

Set-ItemProperty `
  -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
  -Name 'TaskbarAnimations' -Value 1 -ErrorAction SilentlyContinue

Write-Host 'Re-enabling services...'

$Services = @('DiagTrack','dmwappushservice')

foreach ($Service in $Services) {
    if (Get-Service $Service -ErrorAction SilentlyContinue) {
        Set-Service $Service -StartupType Manual
        Start-Service $Service -ErrorAction SilentlyContinue
    }
}

Write-Host 'Re-enabling scheduled tasks...'

$Tasks = @(
'\Microsoft\Windows\Application Experience\ProgramDataUpdater',
'\Microsoft\Windows\Customer Experience Improvement Program\Consolidator'
)

foreach ($Task in $Tasks) {
    Enable-ScheduledTask `
        -TaskPath (Split-Path $Task -Parent) `
        -TaskName (Split-Path $Task -Leaf) `
        -ErrorAction SilentlyContinue
}

Write-Host 'Restoring default power plan...'
powercfg -setactive SCHEME_BALANCED

Write-Host 'Removing ArcOS directory...'
Remove-Item 'C:\ArcOS' -Recurse -Force -ErrorAction SilentlyContinue

Write-Host 'ArcOS removal complete.'
""

echo.
echo =============================
echo   ArcOS Uninstalled
echo =============================
echo.

pause