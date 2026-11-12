@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Incident Response Automator - EXE Compiler
color 0b

echo.
echo ==============================================================================
echo       INCIDENT RESPONSE AUTOMATOR - EXECUTABLE COMPILER
echo ==============================================================================
echo.
echo Source : %~dp0IncidentResponse-Automator.ps1
echo Output : %~dp0IncidentResponse.exe
echo.
echo This compiler installs PS2EXE for the current Windows user if needed.
echo The resulting application will request administrator elevation.
echo.

set "IR_SOURCE=%~dp0IncidentResponse-Automator.ps1"
set "IR_OUTPUT=%~dp0IncidentResponse.exe"
set "IR_BATCH=%~f0"
set "IR_BUILD_SCRIPT=%TEMP%\IRBuild_%RANDOM%_%RANDOM%.ps1"

if not exist "%IR_SOURCE%" (
    echo [ERROR] Cannot find the PowerShell source script:
    echo         "%IR_SOURCE%"
    echo.
    echo Place this compiler in the same folder as IncidentResponse-Automator.ps1.
    echo.
    pause
    exit /b 1
)

echo [1/3] Extracting build helper...

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$lines=[System.IO.File]::ReadAllLines($env:IR_BATCH); $marker=[Array]::IndexOf($lines, ':__PS_PAYLOAD__'); if($marker -lt 0 -or $marker -ge ($lines.Length-1)){Write-Error 'Embedded build script marker not found.'; exit 2}; [string[]]$payload=$lines[($marker+1)..($lines.Length-1)]; [System.IO.File]::WriteAllLines($env:IR_BUILD_SCRIPT,$payload,(New-Object System.Text.UTF8Encoding($true)))"

if errorlevel 1 (
    echo [ERROR] Could not extract the build helper.
    pause
    exit /b 1
)

if not exist "%IR_BUILD_SCRIPT%" (
    echo [ERROR] Build helper was not created.
    pause
    exit /b 1
)

echo [2/3] Checking build helper syntax...

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$tokens=$null; $errors=$null; [System.Management.Automation.Language.Parser]::ParseFile($env:IR_BUILD_SCRIPT,[ref]$tokens,[ref]$errors) | Out-Null; if($errors.Count -gt 0){$errors | ForEach-Object {Write-Host $_.ToString() -ForegroundColor Red}; exit 1}"

if errorlevel 1 (
    echo [ERROR] Embedded build helper failed its syntax check.
    del /q "%IR_BUILD_SCRIPT%" >nul 2>&1
    pause
    exit /b 1
)

echo [3/3] Starting executable build...
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%IR_BUILD_SCRIPT%"
set "IR_RESULT=%ERRORLEVEL%"

del /q "%IR_BUILD_SCRIPT%" >nul 2>&1

echo.
if "%IR_RESULT%"=="0" (
    echo ==============================================================================
    echo  SUCCESS: INCIDENTRESPONSE.EXE CREATED
    echo ==============================================================================
    echo.
    echo Output: "%IR_OUTPUT%"
) else (
    echo ==============================================================================
    echo  BUILD FAILED - REVIEW THE ERROR AND BUILD LOG
    echo ==============================================================================
)

echo.
pause
exit /b %IR_RESULT%

:__PS_PAYLOAD__
#requires -Version 5.1

$ErrorActionPreference = 'Stop'

$TranscriptStarted = $false
$StagingExe = $null
$ExitCode = 0
$LogFile = $null

try {
    # Verify the PowerShell environment.
    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or newer is required.'
    }

    if ($PSVersionTable.PSEdition -and $PSVersionTable.PSEdition -ne 'Desktop') {
        throw 'Use Windows PowerShell 5.1 (powershell.exe), not PowerShell 7.'
    }

    $SourceFile = [System.IO.Path]::GetFullPath($env:IR_SOURCE)
    $OutputFile = [System.IO.Path]::GetFullPath($env:IR_OUTPUT)

    if (-not (Test-Path -LiteralPath $SourceFile -PathType Leaf)) {
        throw "Source script not found: $SourceFile"
    }

    $OutputDirectory = Split-Path -Parent $OutputFile

    $Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $LogFile = Join-Path $env:TEMP "IncidentResponse-Build-$Timestamp.log"
    $StagingExe = Join-Path $OutputDirectory "IncidentResponse.build-$Timestamp.exe"

    Start-Transcript -Path $LogFile -Force | Out-Null
    $TranscriptStarted = $true

    Write-Host 'PowerShell build environment' -ForegroundColor Cyan
    Write-Host "PowerShell: $($PSVersionTable.PSVersion)"
    Write-Host "Source: $SourceFile"
    Write-Host "Output: $OutputFile"
    Write-Host "Log: $LogFile"

    # ------------------------------------------------------------------
    # STEP 1 - Validate the source PowerShell script.
    # ------------------------------------------------------------------

    Write-Host ''
    Write-Host '[1/5] Validating source script...' -ForegroundColor Cyan

    $Tokens = $null
    $ParseErrors = $null

    [System.Management.Automation.Language.Parser]::ParseFile(
        $SourceFile,
        [ref]$Tokens,
        [ref]$ParseErrors
    ) | Out-Null

    if ($ParseErrors.Count -gt 0) {
        $Details = $ParseErrors | ForEach-Object {
            "Line $($_.Extent.StartLineNumber): $($_.Message)"
        }

        throw "Source script contains syntax errors:`r`n$($Details -join "`r`n")"
    }

    Write-Host 'Source script syntax is valid.' -ForegroundColor Green

    # ------------------------------------------------------------------
    # STEP 2 - Prepare PowerShell Gallery and NuGet.
    # ------------------------------------------------------------------

    Write-Host ''
    Write-Host '[2/5] Preparing PowerShell Gallery...' -ForegroundColor Cyan

    [Net.ServicePointManager]::SecurityProtocol =
        [Net.ServicePointManager]::SecurityProtocol -bor
        [Net.SecurityProtocolType]::Tls12

    if (-not (Get-Command Get-PSRepository -ErrorAction SilentlyContinue)) {
        throw 'PowerShellGet is unavailable. Windows PowerShell 5.1 PowerShellGet is required.'
    }

    $Gallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue

    if (-not $Gallery) {
        Write-Host 'Registering PowerShell Gallery...' -ForegroundColor Yellow
        Register-PSRepository -Default -ErrorAction Stop
    }

    if (Get-Command Get-PackageProvider -ErrorAction SilentlyContinue) {
        $NuGetProvider = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue |
            Sort-Object Version -Descending |
            Select-Object -First 1

        if (-not $NuGetProvider) {
            Write-Host 'Installing NuGet provider...' -ForegroundColor Yellow

            Install-PackageProvider `
                -Name NuGet `
                -MinimumVersion '2.8.5.201' `
                -Scope CurrentUser `
                -Force `
                -ErrorAction Stop | Out-Null
        }
        else {
            Write-Host "NuGet provider found: $($NuGetProvider.Version)" -ForegroundColor Green
        }
    }

    # ------------------------------------------------------------------
    # STEP 3 - Install or verify PS2EXE.
    # ------------------------------------------------------------------

    Write-Host ''
    Write-Host '[3/5] Checking PS2EXE...' -ForegroundColor Cyan

    $Ps2ExeModule = Get-Module -ListAvailable -Name ps2exe |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $Ps2ExeModule) {
        Write-Host 'PS2EXE is missing.' -ForegroundColor Yellow
        Write-Host 'Installing PS2EXE for the current Windows user...' -ForegroundColor Yellow
        Write-Host 'Internet access to PowerShell Gallery is required.' -ForegroundColor Gray

        Install-Module `
            -Name ps2exe `
            -Repository PSGallery `
            -Scope CurrentUser `
            -Force `
            -AllowClobber `
            -ErrorAction Stop
    }
    else {
        Write-Host "PS2EXE found: version $($Ps2ExeModule.Version)" -ForegroundColor Green
    }

    Import-Module ps2exe -Force -ErrorAction Stop

    $CompilerCommand = Get-Command Invoke-ps2exe -ErrorAction Stop

    Write-Host 'PS2EXE loaded successfully.' -ForegroundColor Green

    # Make sure the installed version supports all requested parameters.
    $RequiredParameters = @(
        'inputFile',
        'outputFile',
        'noConsole',
        'title',
        'description',
        'company',
        'product',
        'version',
        'requireAdmin'
    )

    foreach ($Parameter in $RequiredParameters) {
        if (-not $CompilerCommand.Parameters.ContainsKey($Parameter)) {
            throw "Installed PS2EXE does not support required parameter: $Parameter"
        }
    }

    # ------------------------------------------------------------------
    # STEP 4 - Compile into a staging EXE.
    # ------------------------------------------------------------------

    Write-Host ''
    Write-Host '[4/5] Compiling application...' -ForegroundColor Cyan

    if (Test-Path -LiteralPath $StagingExe) {
        Remove-Item -LiteralPath $StagingExe -Force
    }

    $CompileParameters = @{
        inputFile    = $SourceFile
        outputFile   = $StagingExe
        noConsole    = $true
        title        = 'Security Incident Response Automator'
        description  = 'Incident Response Console for Active Directory, Microsoft 365 and Google Workspace'
        company      = 'Security Incident Response Automator Contributors'
        product      = 'Security Incident Response Automator'
        version      = '1.1.51.0'
        requireAdmin = $true
    }

    & $CompilerCommand @CompileParameters

    if (-not (Test-Path -LiteralPath $StagingExe -PathType Leaf)) {
        throw 'PS2EXE did not create the expected executable.'
    }

    $BuiltFile = Get-Item -LiteralPath $StagingExe

    if ($BuiltFile.Length -lt 10KB) {
        throw "Generated executable is unexpectedly small: $($BuiltFile.Length) bytes."
    }

    # Verify that the generated file has a Windows executable header.
    $Stream = [System.IO.File]::OpenRead($StagingExe)

    try {
        $Byte1 = $Stream.ReadByte()
        $Byte2 = $Stream.ReadByte()
    }
    finally {
        $Stream.Dispose()
    }

    if ($Byte1 -ne 0x4D -or $Byte2 -ne 0x5A) {
        throw 'Generated file does not have a valid Windows executable header.'
    }

    Write-Host "Staged executable verified: $([math]::Round($BuiltFile.Length / 1MB, 2)) MB" -ForegroundColor Green

    # ------------------------------------------------------------------
    # STEP 5 - Replace the existing EXE only after a successful build.
    # ------------------------------------------------------------------

    Write-Host ''
    Write-Host '[5/5] Publishing executable...' -ForegroundColor Cyan

    Move-Item -LiteralPath $StagingExe -Destination $OutputFile -Force -ErrorAction Stop

    $StagingExe = $null

    $FinalFile = Get-Item -LiteralPath $OutputFile

    Write-Host ''
    Write-Host '==============================================================================' -ForegroundColor Green
    Write-Host 'SUCCESS: INCIDENTRESPONSE.EXE CREATED AND VERIFIED' -ForegroundColor Green
    Write-Host '==============================================================================' -ForegroundColor Green

    Write-Host "Output: $OutputFile" -ForegroundColor Green
    Write-Host "Size: $([math]::Round($FinalFile.Length / 1MB, 2)) MB" -ForegroundColor Green
    Write-Host "Log: $LogFile" -ForegroundColor Green
}
catch {
    $ExitCode = 1

    Write-Host ''
    Write-Host '==============================================================================' -ForegroundColor Red
    Write-Host 'BUILD FAILED' -ForegroundColor Red
    Write-Host '==============================================================================' -ForegroundColor Red

    Write-Host $_.Exception.Message -ForegroundColor Red

    if ($LogFile) {
        Write-Host "Build log: $LogFile" -ForegroundColor Yellow
    }

    if ($_.ScriptStackTrace) {
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkYellow
    }

    if ($StagingExe -and (Test-Path -LiteralPath $StagingExe)) {
        Remove-Item -LiteralPath $StagingExe -Force -ErrorAction SilentlyContinue
    }
}
finally {
    if ($TranscriptStarted) {
        try {
            Stop-Transcript | Out-Null
        }
        catch {}
    }
}

exit $ExitCode
