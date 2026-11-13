
@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Microsoft Graph - One-Click Setup

echo.
echo ============================================================
echo             MICROSOFT GRAPH - ONE-CLICK SETUP
echo ============================================================
echo.
echo This setup will:
echo   1. Check PowerShell and secure connections.
echo   2. Check the NuGet package provider.
echo   3. Install missing Microsoft Graph modules.
echo   4. Import and verify the required Graph commands.
echo   5. Sign in using Microsoft device-code authentication.
echo   6. Verify your Microsoft account and permissions.
echo.
echo Installation and authentication are saved for the current
echo Windows user. Administrator rights are not normally required.
echo.

choice /c YN /n /m "Continue? [Y/N]: "
if errorlevel 2 exit /b 0

set "GRAPH_SOURCE=%~f0"
set "GRAPH_PSFILE=%TEMP%\MicrosoftGraphSetup_%RANDOM%_%RANDOM%_%RANDOM%.ps1"
if defined IR_GRAPH_SETUP_DIR (
    set "GRAPH_LOG=%IR_GRAPH_SETUP_DIR%\Setup.log"
) else (
    set "GRAPH_LOG=%LOCALAPPDATA%\MicrosoftGraphSetup\Setup.log"
)

if not exist "%TEMP%" (
    echo ERROR: Windows temporary folder is unavailable.
    pause
    exit /b 1
)

echo.
echo Preparing setup...

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $lines=[IO.File]::ReadAllLines($env:GRAPH_SOURCE); $marker=[Array]::IndexOf($lines,':__PS_PAYLOAD__'); if($marker -lt 0 -or $marker -ge ($lines.Length-1)){ throw 'Embedded PowerShell payload not found.' }; [string[]]$payload=$lines[($marker+1)..($lines.Length-1)]; [IO.File]::WriteAllLines($env:GRAPH_PSFILE,$payload,(New-Object System.Text.UTF8Encoding($false))); $tokens=$null; $parseErrors=$null; [System.Management.Automation.Language.Parser]::ParseFile($env:GRAPH_PSFILE,[ref]$tokens,[ref]$parseErrors) | Out-Null; if($parseErrors.Count -gt 0){ foreach($e in $parseErrors){ Write-Host ('Validation error at line {0}, column {1}: {2}' -f $e.Extent.StartLineNumber,$e.Extent.StartColumnNumber,$e.Message) -ForegroundColor Red }; exit 12 }; exit 0 } catch { Write-Host ('Unable to prepare setup: '+$_.Exception.Message) -ForegroundColor Red; exit 11 }"

set "PREP_RESULT=%ERRORLEVEL%"

if not "%PREP_RESULT%"=="0" (
    echo.
    echo ERROR: Setup could not be prepared.
    if exist "%GRAPH_PSFILE%" del /q "%GRAPH_PSFILE%" >nul 2>&1
    pause
    exit /b %PREP_RESULT%
)

echo.
echo Starting Microsoft Graph setup...
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%GRAPH_PSFILE%"
set "RESULT=%ERRORLEVEL%"

if exist "%GRAPH_PSFILE%" del /q "%GRAPH_PSFILE%" >nul 2>&1

echo.
if "%RESULT%"=="0" (
    echo ============================================================
    echo       MICROSOFT GRAPH SETUP COMPLETED SUCCESSFULLY
    echo ============================================================
) else (
    echo ============================================================
    echo          MICROSOFT GRAPH SETUP DID NOT COMPLETE
    echo ============================================================
    echo.
    echo Review the error above and the setup log:
    echo %GRAPH_LOG%
)

echo.
pause
exit /b %RESULT%

:__PS_PAYLOAD__

#requires -Version 5.1

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# ============================================================
# CONFIGURATION
# ============================================================

$LogDirectory = if (-not [string]::IsNullOrWhiteSpace($env:IR_GRAPH_SETUP_DIR)) {
    [Environment]::ExpandEnvironmentVariables($env:IR_GRAPH_SETUP_DIR)
} else {
    Join-Path $env:LOCALAPPDATA 'MicrosoftGraphSetup'
}
$LogFile = Join-Path $LogDirectory 'Setup.log'

# Keep these permissions aligned with the application's Graph operations.
$Scopes = @(
    'User.RevokeSessions.All'
    'Directory.AccessAsUser.All'
    'User.ReadWrite.All'
    'UserAuthenticationMethod.ReadWrite.All'
    'MailboxSettings.ReadWrite'
    'Mail.ReadWrite'
    'AuditLog.Read.All'
    'IdentityRiskEvent.Read.All'
    'Application.ReadWrite.All'
    'AppRoleAssignment.ReadWrite.All'
)

$RequiredModules = @(
    'Microsoft.Graph.Authentication'
    'Microsoft.Graph.Users'
    'Microsoft.Graph.Users.Actions'
)

$RequiredCommands = @(
    'Connect-MgGraph'
    'Disconnect-MgGraph'
    'Get-MgContext'
    'Invoke-MgGraphRequest'
    'Revoke-MgUserSignInSession'
)

# ============================================================
# LOGGING
# ============================================================

function Write-SetupLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"

    try {
        Add-Content -LiteralPath $script:LogFile `
            -Value $line `
            -Encoding UTF8 `
            -ErrorAction Stop
    } catch {
        # Logging failures should not interrupt setup.
    }

    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        default   { 'Cyan' }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Write-Section {
    param([string]$Title)

    Write-Host ''
    Write-Host ('=' * 64) -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host ('=' * 64) -ForegroundColor Cyan
    Write-Host ''
}

# ============================================================
# VALIDATE ENVIRONMENT AND INITIALIZE LOG
# ============================================================

try {
    if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        throw 'LOCALAPPDATA is not defined for the current Windows user.'
    }

    if (-not (Test-Path -LiteralPath $env:LOCALAPPDATA -PathType Container)) {
        throw 'The current Windows user profile could not be located.'
    }

    New-Item -ItemType Directory -Path $LogDirectory -Force `
        -ErrorAction Stop | Out-Null

    Set-Content -LiteralPath $LogFile `
        -Value "Microsoft Graph setup started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" `
        -Encoding UTF8 `
        -ErrorAction Stop

    Write-Section 'MICROSOFT GRAPH SETUP'

    Write-SetupLog 'Starting Microsoft Graph setup.'

    Write-SetupLog "Windows account: $env:USERDOMAIN\$env:USERNAME"

    Write-SetupLog "PowerShell version: $($PSVersionTable.PSVersion)"

    # ========================================================
    # STEP 1: POWERSHELL AND SECURE CONNECTIONS
    # ========================================================

    Write-Section '[1/6] Checking PowerShell and secure connections'

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    [Net.ServicePointManager]::SecurityProtocol = `
        [Net.ServicePointManager]::SecurityProtocol -bor `
        [Net.SecurityProtocolType]::Tls12

    Write-SetupLog 'PowerShell and TLS configuration verified.' 'Success'

    # ========================================================
    # STEP 2: NUGET PROVIDER
    # ========================================================

    Write-Section '[2/6] Checking the NuGet package provider'

    $nugetProvider = Get-PackageProvider `
        -ListAvailable `
        -Name NuGet `
        -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $nugetProvider) {

        Write-SetupLog 'NuGet provider is missing. Installing for current user.'

        Install-PackageProvider `
            -Name NuGet `
            -MinimumVersion '2.8.5.201' `
            -Scope CurrentUser `
            -Force `
            -ErrorAction Stop | Out-Null

        Write-SetupLog 'NuGet provider installed.' 'Success'

    } else {

        Write-SetupLog "NuGet provider found (version $($nugetProvider.Version))." 'Success'
    }

    # ========================================================
    # STEP 3: MICROSOFT GRAPH MODULES
    # ========================================================

    Write-Section '[3/6] Checking Microsoft Graph modules'

    foreach ($ModuleName in $RequiredModules) {

        $InstalledModule = Get-Module `
            -ListAvailable `
            -Name $ModuleName |
            Sort-Object Version -Descending |
            Select-Object -First 1

        if ($InstalledModule) {

            Write-SetupLog "$ModuleName is installed (version $($InstalledModule.Version))." 'Success'

        } else {

            Write-SetupLog "Installing $ModuleName for the current Windows user."

            Install-Module `
                -Name $ModuleName `
                -Repository PSGallery `
                -Scope CurrentUser `
                -Force `
                -AllowClobber `
                -ErrorAction Stop

            $InstalledModule = Get-Module `
                -ListAvailable `
                -Name $ModuleName |
                Sort-Object Version -Descending |
                Select-Object -First 1

            if (-not $InstalledModule) {
                throw "Installation verification failed for $ModuleName."
            }

            Write-SetupLog "$ModuleName installed (version $($InstalledModule.Version))." 'Success'
        }
    }

    # ========================================================
    # STEP 4: IMPORT AND VERIFY GRAPH COMMANDS
    # ========================================================

    Write-Section '[4/6] Importing and verifying Microsoft Graph modules'

    foreach ($ModuleName in $RequiredModules) {

        Write-SetupLog "Importing $ModuleName..."

        Import-Module `
            -Name $ModuleName `
            -ErrorAction Stop `
            -DisableNameChecking

        $ImportedModule = Get-Module -Name $ModuleName

        if (-not $ImportedModule) {
            throw "Module import verification failed: $ModuleName"
        }

        Write-SetupLog "$ModuleName imported successfully." 'Success'
    }

    foreach ($CommandName in $RequiredCommands) {

        $command = Get-Command `
            -Name $CommandName `
            -ErrorAction SilentlyContinue

        if (-not $command) {
            throw "Required Microsoft Graph command is unavailable: $CommandName"
        }

        Write-SetupLog "Verified command: $CommandName" 'Success'
    }

    Write-SetupLog 'Required Microsoft Graph modules and commands are ready.' 'Success'

    # ========================================================
    # STEP 5: AUTHENTICATION
    # ========================================================

    Write-Section '[5/6] Microsoft Graph authentication'

    Write-Host 'The following delegated permissions will be requested:' -ForegroundColor Yellow

    foreach ($Scope in $Scopes) {
        Write-Host "  $Scope" -ForegroundColor White
    }

    Write-Host ''
    Write-Host 'IMPORTANT:' -ForegroundColor Yellow
    Write-Host 'This installer uses device-code authentication.' -ForegroundColor White
    Write-Host 'It avoids the Windows account-selection sign-in method that' -ForegroundColor White
    Write-Host 'can become stuck after selecting a Microsoft account.' -ForegroundColor White
    Write-Host ''
    Write-Host 'You will receive a code and a Microsoft sign-in URL.' -ForegroundColor Cyan
    Write-Host 'Open the URL, enter the code, and sign in with your account.' -ForegroundColor Cyan
    Write-Host ''

    # Disconnect an existing Graph session so that the installer
    # cannot accidentally verify an older account or old scopes.

    try {
        if (Get-Command -Name 'Set-MgGraphOption' -ErrorAction SilentlyContinue) {
            Set-MgGraphOption -DisableLoginByWAM $true -ErrorAction SilentlyContinue
        }
    } catch {}

    $ExistingContext = Get-MgContext -ErrorAction SilentlyContinue

    if ($ExistingContext) {

        Write-SetupLog "An existing Graph session was detected for $($ExistingContext.Account)." 'Warning'

        Write-SetupLog 'Disconnecting the existing Graph session before authentication.'

        Disconnect-MgGraph -ErrorAction Stop | Out-Null
    }

    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '             DEVICE-CODE SIGN-IN' -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ''

    Write-SetupLog 'Starting Microsoft Graph device-code authentication.'

    Write-SetupLog 'Waiting for Microsoft device-code authentication to complete.'

    # IMPORTANT:
    # Do not capture, pipe, redirect, or suppress this command.
    # The SDK must display its device code directly in the console.

    Connect-MgGraph `
        -Scopes $Scopes `
        -ContextScope CurrentUser `
        -UseDeviceAuthentication `
        -NoWelcome `
        -ErrorAction Stop

    Write-SetupLog 'Connect-MgGraph returned successfully.' 'Success'

    # ========================================================
    # STEP 6: VERIFY ACCOUNT, PERMISSIONS & TENANT MAILBOX AUDITOR
    # ========================================================

    Write-Section '[6/6] Verifying Microsoft Graph authentication & Tenant Mailbox Auditor'

    $Context = Get-MgContext -ErrorAction Stop

    if (-not $Context) {
        throw 'Microsoft Graph did not return an authentication context.'
    }

    if ([string]::IsNullOrWhiteSpace([string]$Context.Account)) {
        throw 'The signed-in Microsoft account could not be identified.'
    }

    if ([string]::IsNullOrWhiteSpace([string]$Context.TenantId)) {
        throw 'The Microsoft Entra tenant ID could not be identified.'
    }

    Write-SetupLog "Authenticated account: $($Context.Account)" 'Success'

    Write-SetupLog "Tenant ID: $($Context.TenantId)" 'Success'

    Write-SetupLog "Authentication type: $($Context.AuthType)" 'Info'

    $GrantedScopes = @($Context.Scopes)

    $MissingScopes = @(
        foreach ($Scope in $Scopes) {

            $found = $false

            foreach ($GrantedScope in $GrantedScopes) {

                if ([string]::Equals(
                    [string]$GrantedScope,
                    [string]$Scope,
                    [StringComparison]::OrdinalIgnoreCase
                )) {
                    $found = $true
                    break
                }
            }

            if (-not $found) {
                $Scope
            }
        }
    )

    if ($MissingScopes.Count -gt 0) {

        Write-SetupLog "Missing delegated permissions: $($MissingScopes -join ', ')" 'Error'

        throw 'Microsoft Graph authentication succeeded, but the session does not contain every requested permission. Administrator consent may be required.'
    }

    Write-SetupLog 'All requested delegated permissions are present.' 'Success'

    # Provision / Verify Tenant-Wide Microsoft Graph Application Permissions (AppRole)
    # Allows instant, non-blocking REST execution for Inbox Rules, Entra Sign-In/Audit/Risk Event Triage, Session Revocation, and Containment.
    try {
        Write-SetupLog 'Checking tenant-wide Microsoft Graph Application permissions for Incident Response & Mailbox Auditing...' 'Info'
        $AuditorAppConfigPath = Join-Path $LogDirectory 'MailboxAuditorApp.json'
        $AppDisplayName = 'IncidentResponse-Automator-MailboxAuditor'
        $GraphResourceAppId = '00000003-0000-0000-c000-000000000000'
        $RequiredAppRoles = @(
            @{ Name = 'MailboxSettings.ReadWrite';              Id = '6931bccd-447a-43d1-b442-00a195474933' }
            @{ Name = 'Mail.ReadWrite';                         Id = 'e2a3a72e-5f79-4c64-b1b1-878b674786c9' }
            @{ Name = 'User.Read.All';                          Id = 'df021288-bdef-4463-88db-98f22de89214' }
            @{ Name = 'User.ReadWrite.All';                     Id = '741f803b-c850-494e-b5df-cde7c675a1ca' }
            @{ Name = 'Directory.Read.All';                     Id = '7ab1d382-f21e-4acd-a863-ba3e13f7da61' }
            @{ Name = 'AuditLog.Read.All';                      Id = 'b0afded3-3588-46d8-8b3d-9842eff778da' }
            @{ Name = 'IdentityRiskEvent.Read.All';             Id = '6e472fd1-ad78-48da-a0f0-97ab2c6b769e' }
            @{ Name = 'User.RevokeSessions.All';                Id = '09850681-111b-4a89-9bed-3f2cae46d706' }
            @{ Name = 'UserAuthenticationMethod.ReadWrite.All'; Id = '38d9df27-64da-44fd-b7c5-a0fbac20248f' }
            @{ Name = 'DelegatedPermissionGrant.ReadWrite.All'; Id = '8e8e4742-1d95-4f68-9d56-6ee75648c72a' }
        )

        $appResp = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/applications?`$filter=displayName eq '$AppDisplayName'&`$select=id,appId,displayName" -ErrorAction Stop
        $targetApp = if ($appResp -and $appResp.value -and $appResp.value.Count -gt 0) { $appResp.value[0] } else { $null }

        if (-not $targetApp) {
            Write-SetupLog "Creating Entra App Registration '$AppDisplayName'..." 'Info'
            $resAccessList = @($RequiredAppRoles | ForEach-Object { @{ id = $_.Id; type = 'Role' } })
            $createAppBody = @{
                displayName    = $AppDisplayName
                signInAudience = 'AzureADMyOrg'
                requiredResourceAccess = @(
                    @{
                        resourceAppId  = $GraphResourceAppId
                        resourceAccess = $resAccessList
                    }
                )
            } | ConvertTo-Json -Depth 6 -Compress
            $targetApp = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/applications' -Body $createAppBody -ContentType 'application/json' -ErrorAction Stop
        }

        $appObjectId = [string]$targetApp.id
        $clientAppId = [string]$targetApp.appId
        Write-SetupLog "Verified App Registration '$AppDisplayName' (AppId: $clientAppId)." 'Success'

        # Ensure Service Principal exists for the App Registration
        $clientSp = $null
        try {
            $spResp = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq '$clientAppId'&`$select=id,appId,displayName&`$top=1" -ErrorAction Stop
            if ($spResp -and $spResp.value -and @($spResp.value).Count -gt 0) {
                $clientSp = @($spResp.value)[0]
            }
        } catch {}

        if (-not $clientSp) {
            try {
                Write-SetupLog "Creating Enterprise Service Principal for '$AppDisplayName'..." 'Info'
                $createSpBody = (@{ appId = $clientAppId } | ConvertTo-Json -Compress)
                $clientSp = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/servicePrincipals' -Body $createSpBody -ContentType 'application/json' -ErrorAction Stop
            } catch {
                Write-SetupLog "Service Principal notice: $($_.Exception.Message)" 'Warning'
            }
        }
        $clientSpId = if ($clientSp -and $clientSp.id) { [string]$clientSp.id } else { "" }

        if (-not [string]::IsNullOrWhiteSpace($clientSpId)) {
            # Lookup Microsoft Graph Service Principal in tenant
            $graphSpResp = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq '$GraphResourceAppId'&`$select=id,appId,appRoles&`$top=1" -ErrorAction Stop
            if ($graphSpResp -and $graphSpResp.value -and @($graphSpResp.value).Count -gt 0) {
                $graphSp = @($graphSpResp.value)[0]
                $graphSpId = [string]$graphSp.id

                # Grant admin-consented Application permissions
                $existingAssignResp = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$clientSpId/appRoleAssignments" -ErrorAction Stop
                $existingRoleIds = @()
                if ($existingAssignResp -and $existingAssignResp.value) {
                    $existingRoleIds = @($existingAssignResp.value | ForEach-Object { [string]$_.appRoleId })
                }

                foreach ($reqRole in $RequiredAppRoles) {
                    try {
                        $roleName = $reqRole.Name
                        $roleId   = $reqRole.Id
                        if ($graphSp.appRoles) {
                            foreach ($ar in $graphSp.appRoles) {
                                if ([string]$ar.value -ieq $roleName -and $ar.id) {
                                    $roleId = [string]$ar.id
                                    break
                                }
                            }
                        }
                        if ($existingRoleIds -notcontains $roleId) {
                            $assignBody = @{
                                principalId = $clientSpId
                                resourceId  = $graphSpId
                                appRoleId   = $roleId
                            } | ConvertTo-Json -Compress
                            Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$clientSpId/appRoleAssignments" -Body $assignBody -ContentType 'application/json' -ErrorAction Stop | Out-Null
                            Write-SetupLog "Granted Application permission '$roleName'." 'Success'
                        }
                    } catch {}
                }
            }
        }

        # Provision or reuse workstation-local DPAPI-encrypted Client Secret for instant App-Only Graph REST queries
        $encryptedSecret = ""
        if (Test-Path -LiteralPath $AuditorAppConfigPath) {
            try {
                $existingCfg = Get-Content -LiteralPath $AuditorAppConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                if ($existingCfg -and ([string]$existingCfg.ClientId -eq $clientAppId) -and (-not [string]::IsNullOrWhiteSpace([string]$existingCfg.SecretEncrypted))) {
                    [void](ConvertTo-SecureString -String ([string]$existingCfg.SecretEncrypted) -ErrorAction Stop)
                    $encryptedSecret = [string]$existingCfg.SecretEncrypted
                    Write-SetupLog "Reusing existing valid workstation DPAPI-encrypted credential for '$AppDisplayName'." 'Success'
                }
            } catch {}
        }

        if ([string]::IsNullOrWhiteSpace($encryptedSecret)) {
            Write-SetupLog "Provisioning workstation DPAPI-encrypted credential for '$AppDisplayName'..." 'Info'
            $pwdBody = @{
                passwordCredential = @{
                    displayName = "IR-Automator-$env:COMPUTERNAME-$env:USERNAME"
                    endDateTime = (Get-Date).ToUniversalTime().AddYears(2).ToString('yyyy-MM-ddTHH:mm:ssZ')
                }
            } | ConvertTo-Json -Depth 4 -Compress
            $pwdResp = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/applications/$appObjectId/addPassword" -Body $pwdBody -ContentType 'application/json' -ErrorAction Stop
            $secretText = [string]$pwdResp.secretText
            if (-not [string]::IsNullOrWhiteSpace($secretText)) {
                $secureSecret = ConvertTo-SecureString -String $secretText -AsPlainText -Force
                $encryptedSecret = ConvertFrom-SecureString -SecureString $secureSecret
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($encryptedSecret)) {
            $auditorConfig = @{
                SchemaVersion      = 2
                TenantId           = [string]$Context.TenantId
                ClientId           = $clientAppId
                AppObjectId        = $appObjectId
                ServicePrincipalId = $clientSpId
                Account            = [string]$Context.Account
                SecretEncrypted    = $encryptedSecret
                UpdatedUtc         = (Get-Date).ToUniversalTime().ToString('o')
            } | ConvertTo-Json -Depth 4
            Set-Content -LiteralPath $AuditorAppConfigPath -Value $auditorConfig -Encoding UTF8 -ErrorAction Stop
            Write-SetupLog "Saved encrypted Tenant Graph Auditor configuration to $AuditorAppConfigPath" 'Success'
        }
    } catch {
        Write-SetupLog "Notice: Optional background App configuration skipped ($($_.Exception.Message)). Interactive delegated Graph session is fully authenticated." 'Warning'
    }

    # ========================================================
    # FINAL SUCCESS
    # ========================================================

    Write-Section 'SETUP COMPLETED SUCCESSFULLY'

    Write-Host "Account: $($Context.Account)" -ForegroundColor Green
    Write-Host "Tenant:  $($Context.TenantId)" -ForegroundColor Green
    Write-Host "Auditor AppId: $clientAppId (Tenant-Wide Graph REST Enabled)" -ForegroundColor Green
    Write-Host ''

    Write-Host 'Verified delegated permissions:' -ForegroundColor Cyan

    foreach ($Scope in $Scopes) {
        Write-Host "  $Scope" -ForegroundColor Green
    }

    Write-Host ''
    Write-Host 'Verified application permissions (Tenant-Wide Event Triage, Containment & Inbox Rules):' -ForegroundColor Cyan
    foreach ($reqRole in $RequiredAppRoles) {
        Write-Host "  $($reqRole.Name) (Application)" -ForegroundColor Green
    }

    Write-Host ''
    Write-Host 'Microsoft Graph is ready for this Windows user.' -ForegroundColor Green
    Write-Host ''
    Write-Host "Setup log: $LogFile" -ForegroundColor DarkGray

    Write-SetupLog "Setup completed successfully for $($Context.Account)." 'Success'

    exit 0

} catch {

    $Message = $_.Exception.Message

    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host '             MICROSOFT GRAPH SETUP FAILED' -ForegroundColor Red
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host ''
    Write-Host $Message -ForegroundColor Red
    Write-Host ''

    try {
        Write-SetupLog $Message 'Error'

        Write-Host "Setup log: $LogFile" -ForegroundColor Yellow

    } catch {
        Write-Host 'Unable to write the setup log.' -ForegroundColor Yellow
    }

    exit 1
}
