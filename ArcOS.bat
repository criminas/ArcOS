@echo off
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
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

:: Unblock files (safe)
powershell -ExecutionPolicy Bypass -NoProfile -Command "Get-ChildItem '%~dp0' -Recurse | Unblock-File" >nul

echo.
echo Running ArcOS...
echo.

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0main.ps1"

echo.
echo Done.
pause