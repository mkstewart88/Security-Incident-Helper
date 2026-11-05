@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title Security Incident Automator Launcher
set "SCRIPT_PATH=%~dp0IncidentResponse-Automator.ps1"

if not exist "%SCRIPT_PATH%" (
    echo [ERROR] Could not find "%SCRIPT_PATH%"
    echo Please make sure Launch-IncidentAutomator.bat is in the same folder as IncidentResponse-Automator.ps1.
    echo.
    pause
    exit /b 1
)

type nul > "%SCRIPT_PATH%:Zone.Identifier" 2>nul

set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PS_EXE%" set "PS_EXE=powershell.exe"

"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$t=$null; $e=$null; [void][System.Management.Automation.Language.Parser]::ParseFile($env:SCRIPT_PATH, [ref]$t, [ref]$e); if ($e.Count -gt 0) { foreach ($err in $e) { Write-Host ('[SYNTAX ERROR] Line ' + $err.Extent.StartLineNumber + ': ' + $err.Message) -ForegroundColor Red }; exit 1 }"
if errorlevel 1 (
    echo.
    echo [ERROR] IncidentResponse-Automator.ps1 failed PowerShell syntax validation.
    pause
    exit /b 1
)

start "" "%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -STA -File "%SCRIPT_PATH%"
exit /b 0
