@echo off
setlocal EnableExtensions
title ArcOS

echo.
echo ===================================
echo              ArcOS
echo     Optimizing Your Windows PC
echo ===================================
echo.

:: Admin check
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Move to script directory
cd /d "%~dp0"

:: Unblock files safely
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"Get-ChildItem -LiteralPath '%~dp0' -Recurse -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue" >nul 2>&1

echo.
echo Running ArcOS...
echo.

:: Run main script
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0main.ps1"

if %errorlevel% neq 0 (
    echo.
    echo ArcOS encountered an error.
    pause
    exit /b
)

echo.
echo ===================================
echo        Optimization Complete
echo ===================================
echo.
echo Restarting in 5 seconds...
timeout /t 5 >nul

shutdown /r /t 0