@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Active Directory RSAT Installer

set "RSAT_BATCH=%~f0"
set "RSAT_PSFILE=%TEMP%\RSATSetup_%RANDOM%_%RANDOM%.ps1"
set "RSAT_MODE=%~1"

echo.
echo ============================================================
echo             ACTIVE DIRECTORY RSAT INSTALLER
echo ============================================================
echo.
echo This installer will:
echo   - Check your Windows version
echo   - Install the Active Directory management tools
echo   - Verify the PowerShell commands and management console
echo.
echo Administrator permission is required.
echo.
if /i not "%RSAT_MODE%"=="--confirmed" (
    choice /c YN /n /m "Continue? [Y/N]: "
    if errorlevel 2 exit /b 0
)

echo.
echo Checking administrator permissions...

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); if ($p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }" >nul 2>&1

if errorlevel 1 goto :elevate
goto :prepare

:elevate
echo Administrator permission is needed. Requesting approval...
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath $env:RSAT_BATCH -ArgumentList '--confirmed' -Verb RunAs; exit 0 } catch { Write-Host ('Unable to request administrator permission: ' + $_.Exception.Message) -ForegroundColor Red; exit 1 }"

if errorlevel 1 (
    echo.
    echo ERROR: Administrator permission was not granted.
    pause
    exit /b 1
)
exit /b 0

:prepare
echo Preparing installer...

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $lines=[IO.File]::ReadAllLines($env:RSAT_BATCH); $i=[Array]::IndexOf($lines,':__PS_PAYLOAD__'); if($i -lt 0){throw 'Installer content was not found.'}; $payload=[string]::Join([Environment]::NewLine,$lines[($i+1)..($lines.Length-1)]); [IO.File]::WriteAllText($env:RSAT_PSFILE,$payload,[System.Text.UTF8Encoding]::new($false)); $tokens=$null; $errors=$null; [System.Management.Automation.Language.Parser]::ParseFile($env:RSAT_PSFILE,[ref]$tokens,[ref]$errors) | Out-Null; if($errors.Count -gt 0){$errors | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }; exit 3}"

if errorlevel 1 (
    echo.
    echo ERROR: The installer could not be prepared.
    echo No RSAT installation changes were made.
    if exist "%RSAT_PSFILE%" del /q "%RSAT_PSFILE%" >nul 2>&1
    pause
    exit /b 1
)

echo.
echo Installing and verifying Active Directory RSAT...
echo This may take several minutes.
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%RSAT_PSFILE%"
set "RESULT=%ERRORLEVEL%"

del /q "%RSAT_PSFILE%" >nul 2>&1

echo.
if "%RESULT%"=="0" (
    echo ============================================================
    echo               RSAT INSTALLED AND VERIFIED
    echo ============================================================
) else (
    echo ============================================================
    echo                  RSAT INSTALLATION FAILED
    echo ============================================================
    echo.
    echo Review the error message and installer log above.
)

echo.
pause
exit /b %RESULT%


:__PS_PAYLOAD__
#requires -Version 5.1

$ErrorActionPreference = 'Stop'
$ExitCode = 0
$TranscriptStarted = $false
$RebootNeeded = $false
$LogPath = $null

try {
    $LogDirectory = Join-Path $env:ProgramData 'RSAT-Installer'
    New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null

    $TimeStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $LogPath = Join-Path $LogDirectory "RSAT-$TimeStamp.log"

    Start-Transcript -Path $LogPath -Force | Out-Null
    $TranscriptStarted = $true

    Write-Host ''
    Write-Host 'Checking Windows...' -ForegroundColor Cyan

    $OS = Get-CimInstance Win32_OperatingSystem
    $IsServer = [int]$OS.ProductType -ne 1

    Write-Host "Operating system: $($OS.Caption)"
    Write-Host ''

    Write-Host 'Checking Active Directory management tools...' -ForegroundColor Cyan

    if ($IsServer) {
        Import-Module ServerManager -ErrorAction Stop
        $Feature = Get-WindowsFeature -Name RSAT-AD-Tools

        if ($Feature.InstallState -ne 'Installed') {
            Write-Host 'Installing Active Directory management tools...' -ForegroundColor Yellow
            $Result = Install-WindowsFeature -Name RSAT-AD-Tools -IncludeAllSubFeature -IncludeManagementTools

            if (-not $Result.Success) {
                throw "RSAT installation failed: $($Result.ExitCode)"
            }

            if ($Result.RestartNeeded -eq 'Yes') {
                $RebootNeeded = $true
            }
        }
        else {
            Write-Host 'Active Directory management tools are already installed.' -ForegroundColor Green
        }

        $Feature = Get-WindowsFeature -Name RSAT-AD-Tools
        if ($Feature.InstallState -ne 'Installed') {
            throw 'The Active Directory management tools could not be verified after installation.'
        }
    }
    else {
        $CapabilityName = 'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0'
        $Capability = Get-WindowsCapability -Online -Name $CapabilityName

        if ($Capability.State -ne 'Installed') {
            Write-Host 'Installing Active Directory management tools...' -ForegroundColor Yellow
            Write-Host 'Windows may take several minutes to complete this operation.'
            Write-Host ''
            Add-WindowsCapability -Online -Name $CapabilityName | Out-Null
            $Capability = Get-WindowsCapability -Online -Name $CapabilityName
        }
        else {
            Write-Host 'Active Directory management tools are already installed.' -ForegroundColor Green
        }

        if ($Capability.State -ne 'Installed') {
            throw "RSAT installation could not be verified. Current state: $($Capability.State). Check Windows Update and Features on Demand settings."
        }
    }

    Write-Host ''
    Write-Host 'Verifying Active Directory PowerShell...' -ForegroundColor Cyan

    Import-Module ActiveDirectory -ErrorAction Stop

    $RequiredCommands = @(
        'Get-ADUser',
        'Get-ADComputer',
        'Get-ADDomain',
        'Get-ADDomainController',
        'Get-ADRootDSE',
        'Set-ADAccountPassword',
        'Unlock-ADAccount',
        'Disable-ADAccount',
        'Enable-ADAccount'
    )

    $MissingCommands = @(
        $RequiredCommands | Where-Object {
            -not (Get-Command $_ -Module ActiveDirectory -ErrorAction SilentlyContinue)
        }
    )

    if ($MissingCommands.Count -gt 0) {
        throw "Missing Active Directory commands: $($MissingCommands -join ', ')"
    }

    Write-Host "ActiveDirectory PowerShell: verified" -ForegroundColor Green
    Write-Host "Commands verified: $($RequiredCommands.Count)" -ForegroundColor Green

    $DsaPath = Join-Path $env:WINDIR 'System32\dsa.msc'
    if (Test-Path $DsaPath) {
        Write-Host 'Active Directory Users and Computers: available' -ForegroundColor Green
    }
    else {
        Write-Host 'Active Directory Users and Computers: not found' -ForegroundColor Yellow
    }

    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Green
    Write-Host '             RSAT INSTALLED AND VERIFIED' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Green

    if ($RebootNeeded) {
        Write-Host ''
        Write-Host 'A Windows restart is required.' -ForegroundColor Yellow
    }

    Write-Host ''
    Write-Host "Log file: $LogPath" -ForegroundColor Gray
}
catch {
    $ExitCode = 1
    Write-Host ''
    Write-Host 'RSAT INSTALLATION FAILED' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    if ($LogPath) {
        Write-Host "Log file: $LogPath" -ForegroundColor Gray
    }
}
finally {
    if ($TranscriptStarted) {
        try { Stop-Transcript | Out-Null } catch {}
    }
}

exit $ExitCode
