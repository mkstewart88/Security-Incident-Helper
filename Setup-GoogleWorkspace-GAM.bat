
@echo off
setlocal EnableExtensions DisableDelayedExpansion
title GAM7 - One-Click Setup

echo.
echo ============================================================
echo                    GAM7 - ONE-CLICK SETUP
echo ============================================================
echo.
echo This setup will:
echo   1. Check for an existing GAM7 installation.
echo   2. Check GitHub for the latest GAM7 release.
echo   3. Install GAM7 or offer an update when needed.
echo   4. Configure and verify your Windows user PATH.
echo   5. Configure and verify Google OAuth authorization.
echo.
echo GAM7 and Google authorization are configured for the
echo Windows account running this installer.
echo.
choice /c YN /n /m "Continue? [Y/N]: "
if errorlevel 2 exit /b 0

set "GAM_SOURCE=%~f0"
set "GAM_PSFILE=%TEMP%\GAM7_Setup_%RANDOM%_%RANDOM%_%RANDOM%.ps1"

if not exist "%TEMP%" (
    echo.
    echo ERROR: Windows TEMP folder is unavailable.
    pause
    exit /b 1
)

echo.
echo Preparing setup...

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $lines=[IO.File]::ReadAllLines($env:GAM_SOURCE); $marker=[Array]::IndexOf($lines,':__PS_PAYLOAD__'); if($marker -lt 0 -or $marker -ge ($lines.Length-1)){ throw 'Embedded PowerShell payload not found.' }; [string[]]$payload=$lines[($marker+1)..($lines.Length-1)]; [IO.File]::WriteAllLines($env:GAM_PSFILE,$payload,(New-Object System.Text.UTF8Encoding($false))); $tokens=$null; $parseErrors=$null; [System.Management.Automation.Language.Parser]::ParseFile($env:GAM_PSFILE,[ref]$tokens,[ref]$parseErrors) | Out-Null; if($parseErrors.Count -gt 0){ foreach($e in $parseErrors){ Write-Host ('Validation error at line {0}, column {1}: {2}' -f $e.Extent.StartLineNumber,$e.Extent.StartColumnNumber,$e.Message) -ForegroundColor Red }; exit 12 }; exit 0 } catch { Write-Host ('Unable to prepare setup: '+$_.Exception.Message) -ForegroundColor Red; exit 11 }"

set "PREP_RESULT=%ERRORLEVEL%"

if not "%PREP_RESULT%"=="0" (
    echo.
    echo ERROR: Setup could not be prepared.
    if exist "%GAM_PSFILE%" del /q "%GAM_PSFILE%" >nul 2>&1
    pause
    exit /b %PREP_RESULT%
)

echo.
echo Starting GAM7 setup...
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%GAM_PSFILE%"
set "RESULT=%ERRORLEVEL%"

del /q "%GAM_PSFILE%" >nul 2>&1

echo.
if "%RESULT%"=="0" (
    echo ============================================================
    echo                 GAM7 SETUP COMPLETED
    echo ============================================================
) else if "%RESULT%"=="2" (
    echo ============================================================
    echo       GAM7 INSTALLED - PATH CONFLICT NEEDS ATTENTION
    echo ============================================================
) else (
    echo ============================================================
    echo                    GAM7 SETUP FAILED
    echo ============================================================
)

echo.
pause
exit /b %RESULT%

:__PS_PAYLOAD__
#requires -Version 5.1

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Repository = 'GAM-team/GAM'

# ------------------------------------------------------------
# SYSTEM CONFIGURATION
# ------------------------------------------------------------

$NativeArchitecture = $env:PROCESSOR_ARCHITEW6432
if ([string]::IsNullOrWhiteSpace($NativeArchitecture)) {
    $NativeArchitecture = $env:PROCESSOR_ARCHITECTURE
}

if ($NativeArchitecture -match '^(?i:ARM64|AARCH64)$') {
    $ReleaseAssetPattern = 'windows-arm64\.zip$'
    $ArchitectureLabel = 'Windows ARM64'
} else {
    $ReleaseAssetPattern = 'windows-x86_64\.zip$'
    $ArchitectureLabel = 'Windows x86-64'
}

$LocalAppData = $env:LOCALAPPDATA

if ([string]::IsNullOrWhiteSpace($LocalAppData)) {
    $LocalAppData = [Environment]::GetFolderPath(
        [Environment+SpecialFolder]::LocalApplicationData
    )
}

if ([string]::IsNullOrWhiteSpace($LocalAppData)) {
    throw 'Windows did not provide a Local AppData directory.'
}

$UserInstallDirectory = Join-Path $LocalAppData 'Programs\GAM7'
$LogDirectory = Join-Path $LocalAppData 'GAM7-Installer\Logs'

$WorkDirectory = Join-Path ([IO.Path]::GetTempPath()) (
    'GAM7-Setup-' + [guid]::NewGuid().ToString('N')
)

$ZipPath = Join-Path $WorkDirectory 'gam-release.zip'
$ExtractDirectory = Join-Path $WorkDirectory 'Extracted'

$LogPath = $null
$FinalGamPath = $null
$FinalVersion = 'Unknown'
$InstallLatest = $false
$PathConflict = $false
$OAuthStatus = 'Not checked'
$ClientSecretsValid = $false
$InstallDirectory = $null

# ------------------------------------------------------------
# LOGGING
# ------------------------------------------------------------

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    Write-Host $Message -ForegroundColor $Color

    if ($script:LogPath) {
        try {
            $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

            Add-Content -LiteralPath $script:LogPath `
                -Value "[$stamp] $Message" `
                -Encoding UTF8 `
                -ErrorAction Stop
        } catch {
            # Logging must not interrupt installation.
        }
    }
}

function Write-Section {
    param([string]$Text)

    Write-Host ''
    Write-Host ('=' * 68) -ForegroundColor Cyan
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host ('=' * 68) -ForegroundColor Cyan
}

function Read-YesNo {
    param([string]$Prompt)

    do {
        $answer = (Read-Host $Prompt).Trim()

        if ($answer -match '^(?i:Y|YES)$') {
            return $true
        }

        if ($answer -match '^(?i:N|NO)$') {
            return $false
        }

        Write-Host 'Please enter Y or N.' -ForegroundColor Yellow

    } while ($true)
}

# ------------------------------------------------------------
# GAM COMMAND EXECUTION
# ------------------------------------------------------------

function Invoke-Gam {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $oldPreference = $ErrorActionPreference

    try {
        # GAM is an external executable. Its interactive output
        # must remain visible and its prompts must remain usable.
        $ErrorActionPreference = 'Continue'

        & $script:FinalGamPath @Arguments

        $script:GamExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
}

function Get-GamVersion {
    param([string]$Executable)

    if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) {
        return 'Unknown'
    }

    try {
        $output = & $Executable version simple 2>&1 | Out-String

        if ($LASTEXITCODE -ne 0) {
            return 'Unknown'
        }

        $match = [regex]::Match($output, '\d+\.\d+\.\d+')

        if ($match.Success) {
            return $match.Value
        }
    } catch {}

    return 'Unknown'
}

# ------------------------------------------------------------
# PATH FUNCTIONS
# ------------------------------------------------------------

function Normalize-Directory {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ''
    }

    $value = [Environment]::ExpandEnvironmentVariables(
        $Path.Trim().Trim('"')
    )

    try {
        return [IO.Path]::GetFullPath($value).TrimEnd('\')
    } catch {
        return $value.TrimEnd('\')
    }
}

function Test-DirectoryWritable {
    param([string]$Directory)

    try {
        if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
            New-Item -Path $Directory -ItemType Directory -Force `
                -ErrorAction Stop | Out-Null
        }

        $probe = Join-Path $Directory (
            '.gam7-write-test-' + [guid]::NewGuid().ToString('N') + '.tmp'
        )

        [IO.File]::WriteAllText($probe, 'write-test')

        Remove-Item -LiteralPath $probe -Force -ErrorAction Stop

        return $true
    } catch {
        return $false
    }
}

function Add-CurrentUserPath {
    param([string]$Directory)

    $target = Normalize-Directory $Directory

    $oldUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')

    if ($null -eq $oldUserPath) {
        $oldUserPath = ''
    }

    $keptEntries = New-Object System.Collections.Generic.List[string]

    foreach ($entry in ($oldUserPath -split ';')) {
        if ([string]::IsNullOrWhiteSpace($entry)) {
            continue
        }

        if ((Normalize-Directory $entry) -ieq $target) {
            continue
        }

        $keptEntries.Add($entry.Trim())
    }

    $newUserPath = (@($target) + @($keptEntries.ToArray())) -join ';'

    if ($newUserPath.Length -gt 30000) {
        throw 'The current user PATH is too long to safely add GAM.'
    }

    [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')

    $env:Path = "$target;$env:Path"
}

function Get-FirstGamInPath {
    param(
        [string]$MachinePath,
        [string]$UserPath
    )

    foreach ($entry in (($MachinePath + ';' + $UserPath) -split ';')) {
        $directory = Normalize-Directory $entry

        if ([string]::IsNullOrWhiteSpace($directory)) {
            continue
        }

        $candidate = Join-Path $directory 'gam.exe'

        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return [IO.Path]::GetFullPath($candidate)
        }
    }

    return $null
}

function Notify-EnvironmentChange {
    try {
        if (-not ('GAM7EnvironmentBroadcast' -as [type])) {
            Add-Type -ErrorAction Stop -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class GAM7EnvironmentBroadcast {
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr SendMessageTimeout(
        IntPtr hWnd,
        UInt32 Msg,
        IntPtr wParam,
        String lParam,
        UInt32 fuFlags,
        UInt32 uTimeout,
        out IntPtr lpdwResult
    );

    public static void Refresh() {
        IntPtr result;

        SendMessageTimeout(
            new IntPtr(0xffff),
            0x001A,
            IntPtr.Zero,
            "Environment",
            0x0002,
            5000,
            out result
        );
    }
}
'@
        }

        [GAM7EnvironmentBroadcast]::Refresh()
    } catch {
        Write-Log 'Close and reopen your terminal to use the updated PATH.' Yellow
    }
}

# ------------------------------------------------------------
# OAUTH FUNCTIONS
# ------------------------------------------------------------

function Get-GamClientSecretsPath {

    # GAM's normal per-user configuration directory.
    $defaultDirectory = Join-Path $env:USERPROFILE '.gam'

    # GAMCFGDIR can override the normal configuration directory.
    if (-not [string]::IsNullOrWhiteSpace($env:GAMCFGDIR)) {
        $configuredDirectory = [Environment]::ExpandEnvironmentVariables(
            $env:GAMCFGDIR
        )
    } else {
        $configuredDirectory = $defaultDirectory
    }

    # Check GAM's configured directory first, then its default.
    $candidates = @(
        (Join-Path $configuredDirectory 'client_secrets.json'),
        (Join-Path $defaultDirectory 'client_secrets.json')
    ) | Select-Object -Unique

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    # When no file exists, use the configured directory.
    return Join-Path $configuredDirectory 'client_secrets.json'
}

function Test-GamClientSecrets {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }

    try {
        $json = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop |
            ConvertFrom-Json -ErrorAction Stop

        $client = $json.installed

        if (-not $client) {
            $client = $json.web
        }

        if (-not $client) {
            return $false
        }

        if ([string]::IsNullOrWhiteSpace([string]$client.client_id)) {
            return $false
        }

        if ([string]::IsNullOrWhiteSpace([string]$client.client_secret)) {
            return $false
        }

        return $true
    } catch {
        return $false
    }
}

function Invoke-GamOAuthSetup {

    $script:OAuthStatus = 'Setup pending'

    Write-Section '[6/6] Checking Google authorization'

    Write-Log 'Checking Google authorization for the current Windows user.' Cyan

    $clientSecretsPath = Get-GamClientSecretsPath

    Write-Host ''
    Write-Host 'OAuth configuration:' -ForegroundColor Cyan
    Write-Host "  Windows account: $env:USERNAME"
    Write-Host "  GAM executable: $script:FinalGamPath"
    Write-Host "  Client credentials: $clientSecretsPath"
    Write-Host ''

    # FIRST: Ask GAM whether authorization already works.
    # This avoids unnecessary project setup for existing users.

    Write-Log 'Checking existing GAM OAuth authorization...' Cyan

    Invoke-Gam -Arguments @('oauth', 'verify')

    if ($script:GamExitCode -eq 0) {
        $script:OAuthStatus = 'Verified'
        Write-Log 'Existing Google OAuth authorization is verified.' Green
        return
    }

    Write-Log 'Google OAuth authorization is not currently verified.' Yellow

    # SECOND: Check whether client credentials already exist.

    $script:ClientSecretsValid = Test-GamClientSecrets `
        -Path $clientSecretsPath

    if (-not $script:ClientSecretsValid) {

        Write-Host ''
        Write-Host '============================================================' -ForegroundColor Yellow
        Write-Host ' GOOGLE CLOUD PROJECT CONFIGURATION' -ForegroundColor Yellow
        Write-Host '============================================================' -ForegroundColor Yellow
        Write-Host ''
        Write-Host 'GAM does not have valid Google OAuth client credentials.'
        Write-Host ''
        Write-Host 'Choose how you want to configure Google Cloud:'
        Write-Host ''
        Write-Host '  1. Create a NEW Google Cloud project.'
        Write-Host '  2. Use an EXISTING Google Cloud project.'
        Write-Host '  3. Skip Google authorization for now.'
        Write-Host ''

        do {
            $projectChoice = (Read-Host 'Select an option [1/2/3]').Trim()

            if ($projectChoice -notin @('1', '2', '3')) {
                Write-Host 'Please enter 1, 2, or 3.' -ForegroundColor Yellow
            }

        } until ($projectChoice -in @('1', '2', '3'))

        if ($projectChoice -eq '3') {
            $script:OAuthStatus = 'Setup pending'

            Write-Log 'Google Cloud project configuration was skipped.' Yellow

            return
        }

        # Back up invalid credentials instead of deleting them.
        if (Test-Path -LiteralPath $clientSecretsPath -PathType Leaf) {

            $backupPath = '{0}.backup-{1}' -f `
                $clientSecretsPath, (Get-Date -Format 'yyyyMMdd-HHmmss')

            Copy-Item -LiteralPath $clientSecretsPath `
                -Destination $backupPath -ErrorAction Stop

            Write-Log "Previous credentials backed up to: $backupPath" Yellow
        }

        Write-Host ''

        if ($projectChoice -eq '1') {

            Write-Section 'CREATING A NEW GOOGLE CLOUD PROJECT'

            Write-Host 'GAM will now guide you through creating a project.'
            Write-Host 'You will be asked to authenticate with Google.'
            Write-Host ''

            if (-not (Read-YesNo 'Continue with new project creation? (Y/N)')) {
                $script:OAuthStatus = 'Setup pending'
                return
            }

            Write-Log 'Running GAM create project...' Cyan

            # GAM handles all Google authentication and project prompts.
            Invoke-Gam -Arguments @('create', 'project')

        } else {

            Write-Section 'USING AN EXISTING GOOGLE CLOUD PROJECT'

            Write-Host 'You will need:'
            Write-Host '  - Your existing Google Cloud Project ID.'
            Write-Host '  - A Google account authorized to manage that project.'
            Write-Host ''

            if (-not (Read-YesNo 'Continue with existing project setup? (Y/N)')) {
                $script:OAuthStatus = 'Setup pending'
                return
            }

            Write-Log 'Running GAM use project...' Cyan

            # GAM prompts for the administrator and project ID.
            Invoke-Gam -Arguments @('use', 'project')
        }

        $projectSetupCode = $script:GamExitCode

        Write-Host ''

        # Do not assume that project setup worked just because
        # GAM returned to the installer.

        $script:ClientSecretsValid = Test-GamClientSecrets `
            -Path $clientSecretsPath

        if (-not $script:ClientSecretsValid) {

            $script:OAuthStatus = 'Project setup incomplete'

            Write-Log "Project initialization did not create valid credentials." Red
            Write-Log "Expected file: $clientSecretsPath" Yellow
            Write-Log "GAM project command exit code: $projectSetupCode" Yellow

            Write-Host ''
            Write-Host 'Project initialization did not complete.' -ForegroundColor Yellow
            Write-Host 'Check the GAM messages above and resolve any Google Cloud errors.'
            Write-Host ''

            return
        }

        Write-Log 'Google OAuth client credentials successfully created.' Green
    }

    # THIRD: Credentials exist, but OAuth may still need authorization.

    if (-not $script:ClientSecretsValid) {
        $script:OAuthStatus = 'Setup pending'
        return
    }

    Write-Section 'GOOGLE OAUTH AUTHORIZATION'

    Write-Host ''
    Write-Host 'GAM has valid client credentials.'
    Write-Host 'The next step is to authorize your Google Workspace account.'
    Write-Host ''
    Write-Host 'GAM will display its API scope selection menu.'
    Write-Host 'You will then complete authorization in your browser.'
    Write-Host ''

    # When the user just initialized a project, continue automatically.
    # Otherwise ask before changing existing OAuth credentials.

    if ($projectChoice -notin @('1', '2')) {

        if (-not (Read-YesNo 'Run GAM OAuth authorization now? (Y/N)')) {
            $script:OAuthStatus = 'Setup pending'
            Write-Log 'OAuth authorization was skipped.' Yellow
            return
        }
    } else {

        if (-not (Read-YesNo 'Start Google OAuth authorization now? (Y/N)')) {
            $script:OAuthStatus = 'Setup pending'
            Write-Log 'OAuth authorization was skipped.' Yellow
            return
        }
    }

    Write-Host ''
    Write-Log 'Starting interactive GAM OAuth authorization...' Cyan

    # This command is intentionally run directly in the console.
    # Do not pipe or capture its interactive input/output.

    Invoke-Gam -Arguments @('oauth', 'create')

    $oauthCreateCode = $script:GamExitCode

    if ($oauthCreateCode -ne 0) {

        $script:OAuthStatus = 'Authorization incomplete'

        Write-Log "GAM oauth create returned exit code $oauthCreateCode." Yellow

        return
    }

    # FOURTH: Verify authorization after browser authentication.

    Write-Host ''
    Write-Log 'Verifying Google OAuth authorization...' Cyan

    Invoke-Gam -Arguments @('oauth', 'verify')

    if ($script:GamExitCode -eq 0) {

        $script:OAuthStatus = 'Verified'

        Write-Log 'Google OAuth authorization successfully verified.' Green

    } else {

        $script:OAuthStatus = 'Verification failed'

        Write-Log 'GAM OAuth authorization completed, but verification failed.' Yellow
        Write-Log 'Review the GAM output above.' Yellow
    }
}

# ------------------------------------------------------------
# MAIN INSTALLATION
# ------------------------------------------------------------

try {

    # Create log directory.
    try {
        New-Item -Path $LogDirectory -ItemType Directory -Force `
            -ErrorAction Stop | Out-Null
    } catch {
        $LogDirectory = Join-Path ([IO.Path]::GetTempPath()) 'GAM7-Installer-Logs'

        New-Item -Path $LogDirectory -ItemType Directory -Force `
            -ErrorAction Stop | Out-Null
    }

    $LogPath = Join-Path $LogDirectory (
        'GAM7-Setup-{0:yyyyMMdd-HHmmss}.log' -f (Get-Date)
    )

    Set-Content -LiteralPath $LogPath `
        -Value 'GAM7 installer log. OAuth credentials and interactive authentication are not transcript-recorded.' `
        -Encoding UTF8

    # Prepare temporary working directories.
    New-Item -Path $WorkDirectory -ItemType Directory -Force | Out-Null
    New-Item -Path $ExtractDirectory -ItemType Directory -Force | Out-Null

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Section 'GAM7 SETUP'

    Write-Log 'Setting up GAM7 for the current Windows user.' Cyan
    Write-Log "Windows account: $env:USERDOMAIN\$env:USERNAME" Gray

    if (-not [Environment]::Is64BitOperatingSystem) {
        throw 'Official GAM Windows packages require 64-bit Windows.'
    }

    # --------------------------------------------------------
    # STEP 1: FIND EXISTING GAM
    # --------------------------------------------------------

    Write-Section '[1/6] Checking for an existing GAM installation'

    $whereExe = Join-Path $env:SystemRoot 'System32\where.exe'
    $pathHits = @()

    if (Test-Path -LiteralPath $whereExe) {

        $whereOutput = & $whereExe gam.exe 2>$null

        foreach ($line in $whereOutput) {
            $candidate = ([string]$line).Trim()

            if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
                $pathHits += $candidate
            }
        }
    }

    $knownDirectories = @(
        $UserInstallDirectory,
        (Join-Path $LocalAppData 'GAM7'),
        (Join-Path $LocalAppData 'GAM'),
        'C:\GAM7',
        'C:\GAM'
    )

    $candidateDirectories = New-Object System.Collections.Generic.List[string]

    foreach ($hit in $pathHits) {
        try {
            $candidateDirectories.Add((Split-Path -Parent $hit))
        } catch {}
    }

    foreach ($directory in $knownDirectories) {
        if ($directory) {
            $candidateDirectories.Add($directory)
        }
    }

    $ExistingGam = $null
    $ExistingDirectory = $null

    foreach ($directory in ($candidateDirectories | Select-Object -Unique)) {

        if ([string]::IsNullOrWhiteSpace($directory)) {
            continue
        }

        $candidateExe = Join-Path $directory 'gam.exe'

        if (Test-Path -LiteralPath $candidateExe -PathType Leaf) {
            $ExistingGam = $candidateExe
            $ExistingDirectory = $directory
            break
        }
    }

    $CurrentVersion = 'Unknown'

    if ($ExistingGam) {

        $CurrentVersion = Get-GamVersion -Executable $ExistingGam

        Write-Log "Existing GAM: $ExistingGam" Green
        Write-Log "Installed version: $CurrentVersion" Gray

    } else {

        Write-Log 'GAM is not currently installed.' Yellow
    }

    # --------------------------------------------------------
    # STEP 2: CHECK GITHUB
    # --------------------------------------------------------

    Write-Section '[2/6] Checking the latest GAM7 release'

    $LatestVersion = 'Unknown'
    $asset = $null
    $release = $null

    $headers = @{
        'User-Agent' = 'GAM7-OneClick-Installer'
        'Accept' = 'application/vnd.github+json'
    }

    try {

        $release = Invoke-RestMethod `
            -Uri "https://api.github.com/repos/$Repository/releases/latest" `
            -Headers $headers `
            -TimeoutSec 30 `
            -ErrorAction Stop

        if (-not $release -or -not $release.assets) {
            throw 'GitHub returned no downloadable release assets.'
        }

        $latestMatch = [regex]::Match(
            [string]$release.tag_name,
            '\d+\.\d+\.\d+'
        )

        if (-not $latestMatch.Success) {
            throw "Could not identify the version in GitHub tag '$($release.tag_name)'."
        }

        $LatestVersion = $latestMatch.Value

        $asset = $release.assets |
            Where-Object { $_.name -match $ReleaseAssetPattern } |
            Select-Object -First 1

        if (-not $asset -or -not $asset.browser_download_url) {
            throw "GitHub does not contain the official $ArchitectureLabel release ZIP."
        }

        Write-Log "Latest version: $LatestVersion" Green

    } catch {

        if ($ExistingGam) {

            Write-Log "Unable to check GitHub: $($_.Exception.Message)" Yellow

            if (Read-YesNo 'Continue using the existing GAM installation? (Y/N)') {
                $LatestVersion = 'Unknown'
            } else {
                throw 'Setup cancelled because the latest GAM release could not be checked.'
            }

        } else {

            throw "Cannot install GAM without accessing GitHub. $($_.Exception.Message)"
        }
    }

    # --------------------------------------------------------
    # STEP 3: DETERMINE INSTALLATION STATUS
    # --------------------------------------------------------

    Write-Section '[3/6] Checking whether installation or update is needed'

    if ($LatestVersion -ne 'Unknown') {

        if (-not $ExistingGam) {

            $InstallLatest = $true

        } elseif ($CurrentVersion -eq 'Unknown') {

            Write-Log 'Could not identify the installed GAM version.' Yellow

            $InstallLatest = Read-YesNo "Replace it with GAM $LatestVersion? (Y/N)"

        } else {

            $installedVersion = [version]$CurrentVersion
            $latestVersionObject = [version]$LatestVersion

            if ($installedVersion -ge $latestVersionObject) {

                $InstallLatest = $false

                Write-Log 'The installed GAM version is already current.' Green

            } else {

                Write-Log "Update available: $CurrentVersion -> $LatestVersion" Yellow

                $InstallLatest = Read-YesNo 'Install the update? (Y/N)'
            }
        }
    }

    if (-not $ExistingGam -and -not $InstallLatest) {
        throw 'No GAM installation exists and no new installation was selected.'
    }

    # --------------------------------------------------------
    # STEP 4: DOWNLOAD AND INSTALL
    # --------------------------------------------------------

    if ($InstallLatest) {

        Write-Section '[4/6] Downloading and installing GAM7'

        Write-Log "Downloading GAM $LatestVersion..." Cyan

        Invoke-WebRequest `
            -Uri $asset.browser_download_url `
            -OutFile $ZipPath `
            -UseBasicParsing `
            -Headers @{ 'User-Agent' = 'GAM7-OneClick-Installer' } `
            -TimeoutSec 240 `
            -ErrorAction Stop

        if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
            throw 'GAM ZIP download was not created.'
        }

        $downloadedLength = (Get-Item -LiteralPath $ZipPath).Length

        if ($downloadedLength -lt 1000000) {
            throw 'Downloaded GAM ZIP is unexpectedly small.'
        }

        if ($asset.size -and ($downloadedLength -ne [long]$asset.size)) {
            throw "Downloaded ZIP size does not match GitHub's reported size."
        }

        if ($asset.digest -and ([string]$asset.digest -match '^sha256:([0-9a-fA-F]{64})$')) {

            $expectedHash = $Matches[1].ToLowerInvariant()

            $actualHash = (
                Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256
            ).Hash.ToLowerInvariant()

            if ($actualHash -ne $expectedHash) {
                throw 'GAM ZIP SHA-256 verification failed.'
            }

            Write-Log 'Download SHA-256 verification successful.' Green

        } else {

            Write-Log 'Download size verification successful.' Green
        }

        Expand-Archive `
            -LiteralPath $ZipPath `
            -DestinationPath $ExtractDirectory `
            -Force

        $stagedExe = Get-ChildItem `
            -LiteralPath $ExtractDirectory `
            -Filter 'gam.exe' `
            -File `
            -Recurse |
            Select-Object -First 1

        if (-not $stagedExe) {
            throw 'The downloaded archive does not contain gam.exe.'
        }

        $stagedVersion = Get-GamVersion -Executable $stagedExe.FullName

        if ($stagedVersion -eq 'Unknown') {
            throw 'The extracted GAM executable failed its version test.'
        }

        if ($stagedVersion -ne $LatestVersion) {
            throw "Extracted version $stagedVersion does not match release $LatestVersion."
        }

        Write-Log "Downloaded GAM $stagedVersion successfully." Green

        $InstallDirectory = $null

        if ($ExistingGam -and (Test-DirectoryWritable -Directory $ExistingDirectory)) {

            $InstallDirectory = $ExistingDirectory

        } elseif (Test-DirectoryWritable -Directory $UserInstallDirectory) {

            $InstallDirectory = $UserInstallDirectory

            if ($ExistingGam) {
                Write-Log "Using new installation directory: $InstallDirectory" Yellow
            } else {
                Write-Log "Installing for current user: $InstallDirectory" Green
            }

        } else {

            throw "No writable GAM installation directory is available."
        }

        $runningGam = Get-Process -Name 'gam' -ErrorAction SilentlyContinue

        if ($runningGam) {
            throw 'A GAM process is currently running. Close it and retry.'
        }

        Write-Log "Installing GAM files to: $InstallDirectory" Cyan

        $robocopyExe = Join-Path $env:SystemRoot 'System32\robocopy.exe'

        if (-not (Test-Path -LiteralPath $robocopyExe -PathType Leaf)) {
            throw 'Windows robocopy.exe was not found.'
        }

        $robocopyArgs = @(
            $stagedExe.DirectoryName,
            $InstallDirectory,
            '/E',
            '/R:2',
            '/W:2',
            '/COPY:DAT',
            '/DCOPY:DAT',
            '/XF',
            'gam.cfg',
            'client_secrets.json',
            'oauth2.txt',
            'oauth2service.json',
            'extra_args.txt',
            '/NFL',
            '/NDL',
            '/NJH',
            '/NJS',
            '/NP'
        )

        & $robocopyExe @robocopyArgs

        $copyCode = $LASTEXITCODE

        if ($copyCode -ge 8) {
            throw "GAM file installation failed. Robocopy exit code: $copyCode"
        }

        $FinalGamPath = Join-Path $InstallDirectory 'gam.exe'

        if (-not (Test-Path -LiteralPath $FinalGamPath -PathType Leaf)) {
            throw 'GAM executable is missing after installation.'
        }

        $FinalVersion = Get-GamVersion -Executable $FinalGamPath

        if ($FinalVersion -ne $stagedVersion) {
            throw 'Installed GAM version verification failed.'
        }

        Write-Log "Installed GAM $FinalVersion successfully." Green

    } else {

        $FinalGamPath = $ExistingGam
        $InstallDirectory = $ExistingDirectory
        $FinalVersion = $CurrentVersion

        Write-Log 'Keeping the existing GAM installation.' Green
    }

    # --------------------------------------------------------
    # STEP 5: CONFIGURE PATH
    # --------------------------------------------------------

    Write-Section '[5/6] Configuring and verifying PATH'

    if (-not $FinalGamPath -or -not (Test-Path -LiteralPath $FinalGamPath -PathType Leaf)) {
        throw 'Selected GAM executable does not exist.'
    }

    $verifyOutput = & $FinalGamPath version simple 2>&1 | Out-String
    $verifyCode = $LASTEXITCODE

    if ($verifyCode -ne 0) {
        throw "GAM failed its final version test. $verifyOutput"
    }

    $verifyMatch = [regex]::Match($verifyOutput, '\d+\.\d+\.\d+')

    if (-not $verifyMatch.Success) {
        throw 'GAM version could not be identified during final verification.'
    }

    $FinalVersion = $verifyMatch.Value

    Add-CurrentUserPath -Directory $InstallDirectory

    Notify-EnvironmentChange

    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')

    $firstPathGam = Get-FirstGamInPath `
        -MachinePath $machinePath `
        -UserPath $userPath

    if ($firstPathGam -and (
        (Normalize-Directory (Split-Path -Parent $firstPathGam)) -ine
        (Normalize-Directory $InstallDirectory)
    )) {

        $PathConflict = $true

        Write-Log "PATH conflict: Another GAM installation appears first: $firstPathGam" Yellow

    } elseif (-not $firstPathGam) {

        $PathConflict = $true

        Write-Log 'PATH verification failed. Windows did not resolve gam.exe.' Yellow

    } else {

        Write-Log 'PATH configured and verified for the current Windows user.' Green
    }

    Write-Log "Verified executable: $FinalGamPath" Green
    Write-Log "Verified version: $FinalVersion" Green

    # --------------------------------------------------------
    # STEP 6: GOOGLE OAUTH
    # --------------------------------------------------------

    Invoke-GamOAuthSetup

    # --------------------------------------------------------
    # FINAL SUMMARY
    # --------------------------------------------------------

    Write-Section 'SETUP SUMMARY'

    Write-Log "GAM version: $FinalVersion" Green
    Write-Log "Install folder: $InstallDirectory" Green
    Write-Log "Executable: $FinalGamPath" Green

    Write-Log "Client credentials: $(if ($ClientSecretsValid) { 'Valid' } else { 'Not verified by installer' })" Gray

    Write-Log "OAuth status: $OAuthStatus" $(
        if ($OAuthStatus -eq 'Verified') {
            [ConsoleColor]::Green
        } else {
            [ConsoleColor]::Yellow
        }
    )

    Write-Log "Log file: $LogPath" DarkGray

    if ($PathConflict) {

        Write-Log 'GAM is installed, but a PATH conflict needs attention.' Yellow

        exit 2
    }

    if ($OAuthStatus -ne 'Verified') {

        Write-Log 'GAM is installed, but Google OAuth setup is incomplete.' Yellow
        Write-Log 'Run this installer again when you are ready to complete authorization.' Yellow

    } else {

        Write-Log 'GAM7 is installed and Google OAuth authorization is verified.' Green
    }

    exit 0

} catch {

    $message = $_.Exception.Message

    Write-Log "ERROR: $message" Red

    if ($LogPath) {
        Write-Log "Log file: $LogPath" Yellow
    }

    exit 1

} finally {

    if ($WorkDirectory -and (Test-Path -LiteralPath $WorkDirectory)) {

        Remove-Item -LiteralPath $WorkDirectory `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }
}
