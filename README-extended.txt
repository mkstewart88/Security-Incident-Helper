================================================================================
SECURITY INCIDENT RESPONSE AUTOMATOR - EXTENDED TECHNICAL MANUAL (v1.1.68)
================================================================================

ARCHITECTURAL SPECIFICATION & EXHAUSTIVE CONTROL-BY-CONTROL ENGINEERING REFERENCE
Target Audience: Cybersecurity Engineers, SOC Leads, Systems Architects, SecOps

================================================================================
1. ARCHITECTURAL OVERVIEW & IDENTITY SURFACES
================================================================================
Security Incident Response Automator is a native Windows Forms administrative
application written in native Windows PowerShell 5.1 and .NET Framework 4.8.
It manages three distinct authentication and identity surfaces directly:

1. ON-PREMISES ACTIVE DIRECTORY DOMAIN SERVICES (AD DS):
   Communicates directly with Domain Controllers over LDAP (TCP 389), LDAPS
   (TCP 636), and Kerberos (TCP 88) using native .NET System.DirectoryServices
   without requiring RSAT cmdlets (while automatically leveraging RSAT if present).

2. MICROSOFT ENTRA ID (MICROSOFT 365 & AZURE AD):
   Communicates directly with the Microsoft Graph REST API over HTTPS TLS 1.2/1.3
   via official Microsoft.Graph SDK sub-modules.

3. GOOGLE WORKSPACE:
   Orchestrates Google Admin SDK Directory, Gmail Settings, and Reports APIs
   via the standalone GAM7 CLI (Google Apps Manager v7.50+).

Zero third-party middleware, cloud relay services, or telemetry agents are used.
All operations execute directly from the administrator's workstation to your own
domain controllers and official vendor endpoints.

================================================================================
2. MULTI-ATTRIBUTE IDENTITY RESOLVER (Resolve-UserCloudIdentities)
================================================================================
In enterprise environments, on-premises Active Directory accounts frequently
diverge from cloud user principal names:
- On-Premises UPN: alex.morgan@corp.internal or amorgan@ad.domain.local
- Cloud Routable UPN: alex.morgan@contoso.com
- sAMAccountName: am8001 or amorgan
- ProxyAddresses: SMTP:alex.morgan@contoso.com, smtp:alexm@contoso.com

When a user is selected:
1. The resolver compiles an array of candidates from sAMAccountName, UPN, mail,
   and all proxyAddresses.
2. In Microsoft Graph, it submits an OData filter:
   /v1.0/users?$filter=userPrincipalName eq '{id}' or mail eq '{id}' or onPremisesSamAccountName eq '{sam}'
3. In Google Workspace, GAM validates candidates sequentially against the Admin
   Directory API until an active identity is confirmed.
4. Confirmed cloud identifiers are pinned into the session context.

================================================================================
3. COMPLETE CONTROL-BY-CONTROL & BUTTON TECHNICAL REFERENCE
================================================================================

TOP HEADER BAR:
- Update Status Button ($btnCheckUpdates: "v<version>" / "Update Available") &
  View Changelog ($btnViewChangelog):
  On startup ($form.Add_Shown), Start-StartupUpdateCheckAsync runs an
  asynchronous background check ($ProgressPreference = 'SilentlyContinue', with
  script-scoped retry timer $script:startupUpdateRetryTimer) via
  Get-GitHubUpdateStatusSafe comparing BOTH GitHub releases?per_page=1 and
  commit-SHA-busted main/VERSION (picking whichever is higher). When complete,
  the WinForms timer calls Invoke-ApplyStartupUpdateCheckResultSafe ->
  Update-HeaderUpdateButtonState, immediately rendering "v<version>"
  (e.g., v1.1.68) when up to date/offline or "Update Available" automatically on
  launch whenever a newer version or main commit exists. Clicking opens
  Show-UpdateCheckWindow (enforcing trusted github.com/githubusercontent.com
  HTTPS URLs & ref checks) for Check for Updates, View Changelog, and Update &
  Restart (uncached commit-SHA download, AST + post-download AppVersion check,
  optional local PS2EXE compilation with MZ header check, and a 30-attempt
  file-lock retry loop updating sibling files before relaunch).
- [ Light Mode ] / [ Dark Mode ] ($btnThemeToggle -> Invoke-ThemeCrossFadeTransitionSafe):
  Captures a client snapshot overlay, applies Apply-AppTheme($Dark) cleanly
  underneath, and smoothly fades overlay opacity (~240ms) across all panels,
  headers, action logs, decision boxes, inputs, and data grids.
- GitHub Repository Icon ($btnGitHub):
  Positioned immediately to the right of [ Light Mode ] / [ Dark Mode ].
  Renders a DPI-aware vector GitHub mark and launches
  https://github.com/mkstewart88/Security-Incident-Helper in the default browser.
- Master Passphrase ($btnMasterPassphrase -> Show-MasterPassphraseDialogSafe /
  Show-StartupMasterPassphraseGateSafe):
  Positioned immediately to the right of $btnGitHub. Manages an optional global
  application-wide passphrase (MasterVault.dpapi.json) applied to all saved
  Domain Profiles using an action-first panel flow: when unset, shows 2 boxes
  (New + Confirm); when active, opens to $pnlMenu (0 boxes) with Change
  Passphrase (3 boxes: Current/New/Confirm), "Remove Passphrase" (1 box: Current
  -> "Continue" prompt & why-keep warning keeping DPAPI vaults), and break-glass
  "Remove Passphrase & All Creds" (0 boxes, no passphrase needed if forgotten;
  enlarged Box 1 single red sentence explicitly covering your Master Passphrase,
  Domain Profiles, AD creds, Graph sessions, and GAM7 profiles + right-aligned
  "Continue?" beside Yes/No -> enlarged Box 2 "Are you sure?" Yes/No, calling
  Remove-GlobalMasterPassphraseAndPurgeAllSafe to permanently wipe
  MasterVault.dpapi.json, all Domain Profiles, AD DPAPI vaults,
  MailboxAuditorApp.json, Microsoft Graph sessions/caches, and Google GAM7
  OAuth/config files while preserving gam.exe). When enabled, startup enforces
  a 2-attempt gate before probing or sign-in.

TAB 1: INTEGRATIONS & PRE-FLIGHT SETUP
- Scrollability & Reference Box ($tabDiag.AutoScroll = $true, $lblDiagGuide):
  Tab 1 enables AutoScroll and uses a vertically scrollable read-only TextBox
  inside $grpDiagGuide ("Integration Setup & Multi-Domain Switching Reference")
  so wrapped guidance text is never clipped in non-fullscreen windows.
- Active Profile Bar ($cmbDiagProfile, Switch Profile $btnDiagSwitchProfile,
  + New Profile $btnDiagNewProfile, Manage / AD... $btnDiagManageProfiles) &
  Show-PrimaryProfilePromptSafe:
  Prompts on first launch if no Primary Domain Profile is configured yet using
  Step 1 ($pnlChoice, 0 textboxes) and Step 2 ($pnlNameInput, single contextual
  $txtSelectedName box matching the chosen Primary vs Assisting action),
  allowing technicians to reserve their clean Primary slot if currently assisting
  another domain. Manages isolated Domain Profiles stored in Profiles.json and
  %LOCALAPPDATA%\IncidentResponse-Automator\Profiles\<id> (with ad_cred.dpapi.json
  encrypted via DPAPI CurrentUser + optional AES-256 Master Passphrase and
  single-user NTFS ACLs, plus ad_cred_health.json tracking zero-lockout state).
  - Profile Controls in Show-DomainSwitcher: $cmbProf, + New ($btnNewProf),
    Set Primary ($btnSetPrimaryProf), Rename ($btnRenameProf), Delete ($btnDelProf),
    Auto-Detect Domain ($btnAutoDetect), Save AD Creds ($chkSaveCred),
    Purge Saved ($btnPurgeDlgCred, protected by an "Are you sure?" prompt),
    Connect & Switch Profile ($btnConnect), and Switch Cloud Only (Skip AD)
    ($btnCloudOnly). Saved vaults automatically
    bind to the global Master Passphrase when configured in the top header.
- Credential Health & Encrypted AD Vault Panel ($grpCredHealth):
  - Validate Credential Health ($btnValidateCredHealth -> Invoke-ValidateStoredADCredentialHealthSafe):
    Runs zero-credential network reachability check (NIC DNS suffixes + DNS SRV +
    700ms TCP 389/636), Kerberos pre-bind pwdLastSet/badPwdCount/lockoutTime audit,
    and 1-strike circuit-breaker validation.
  - Detect Network & Auto-Connect ($btnAutoConnectProfile / Start-StartupADAutoConnectAsync /
    Invoke-ApplyStartupDiscoveryResultSafe / Invoke-StartupUnifiedPreflightSafe):
    Probes configured profile domains asynchronously without UI freeze (even on
    plugged-in unjoined networks), auto-connects AD via saved vault credentials,
    and runs unified preflight across Active Directory + Microsoft Graph + GAM7
    while staying cleanly on Tab 1.
  - Configure Saved AD Creds... ($btnManageSavedCred) & Purge Saved Creds
    ($btnPurgeSavedCred, protected by an "Are you sure?" modal Yes/No prompt).
- Column 1 (Active Directory, X=15):
  - Test Active Directory ($btnTestAD, Row 1): Performs live LDAP RootDSE bind.
  - Install RSAT (Optional) ($btnRunRsatSetup, Row 2): Runs Setup-RSAT-ActiveDirectory.bat
    to install RSAT Active Directory tools via Windows Capabilities (DISM).
  - Switch AD Account / Domain ($btnSwitchAdAcct, Row 3): Opens Show-DomainSwitcher.
- Column 2 (Microsoft Graph, X=278):
  - Test Microsoft Graph ($btnTestM365, Row 1): Restores active profile MgContext.json,
    calls Get-MgContext, checks scopes, and probes /organization.
  - 1. Setup Microsoft Graph ($btnRunGraphSetup, Row 2): Runs Setup-MicrosoftGraph.bat
    using active IR_GRAPH_SETUP_DIR and Set-MgGraphOption -DisableLoginByWAM $true.
  - Switch Graph Account ($btnSwitchGraphAcct, Row 3): Runs Disconnect-MgGraph and
    device-code authentication with WAM disabled for dual-account admins.
- Column 3 (Google GAM7, X=546):
  - Test Google GAM7 ($btnTestGoogle, Row 1): Verifies gam.exe, oauth2.txt inside active
    profile GAMCFGDIR, and runs gam oauth verify.
  - 2. Setup Google GAM7 ($btnRunGamSetup, Row 2): Scopes GAMCFGDIR to the
    active profile and runs Setup-GoogleWorkspace-GAM.bat to install GAM7 and
    authorize Google Cloud OAuth in active GAMCFGDIR.
  - Switch GAM Account ($btnSwitchGamAcct, Row 3): Runs gam oauth delete + create + verify
    scoped to the active profile GAMCFGDIR.

TAB 2: INCIDENT CONTAINMENT DECK
- Find Users ($btnLookup): Queries AD (Query-ADUsersSafe) using Ambiguous Name Resolution (ANR) filter:
  (|(anr={search})(sAMAccountName={search}*)(userPrincipalName={search}*)(mail={search}*)(proxyAddresses=smtp:*{search}*))
- Refresh Sessions ($btnRefreshUserSessions): Re-queries AD, Graph, and GAM7 to
  refresh Password Age, 365/Entra Status, Google Status, and AD Account Status.
- Safety Checkbox ($chkVerified): Hardware interlock preventing containment actions
  until the operator explicitly verifies the target identity.
- 1. Reset Password ($btnResetPass): Opens Show-PasswordResetCustomDialog, sets password via
  LDAP DirectoryEntry.Invoke("SetPassword"), enforces pwdLastSet = 0 or -1 per RequireChangeAtLogon,
  and verifies via LDAP read-back.
- 2. Revoke 365 Sessions ($btnRevoke365): Calls Invoke-RevokeMgUserSignInSessionSafe
  (POST /v1.0/users/{id}/revokeSignInSessions) to invalidate refresh tokens.
- 3. Revoke Google Sessions ($btnRevokeGoogle): Executes gam user <id> signout,
  terminating active web cookies and mobile device sessions.
- 4. Disable Account / Enable Account ($btnEmergencyLock): Modifies userAccountControl
  bitmask (ADS_UF_ACCOUNTDISABLE = 0x0002) with immediate LDAP read-back verification.
- Run Full Playbook (1-Click) ($btnContainAll): Executes Actions 1, 2, 3, and 4
  sequentially with verification gates between each step.

TAB 3: DEEP ISOLATION & MAILBOX RULES AUDITOR
- Block Entra Sign-In (Instant) ($btnBlockEntraSignIn): Issues HTTP PATCH to Microsoft Graph
  /v1.0/users/{id} with {"accountEnabled": false}, closing the 30-minute sync gap.
- Suspend Google User (GAM7) ($btnSuspendGoogle): Runs gam update user <id> suspended on
  with 3-pass convergence verification via gam info user.
- Wipe Entra 2FA Methods ($btnWipeEntraMfa, -Scope EntraMfa): Enumerates and
  deletes non-password Entra authentication methods (SMS, Authenticator, FIDO2, OATH, TAP, Email).
- Wipe Entra OAuth Grants ($btnWipeEntraOAuth, -Scope EntraOAuth): Revokes Entra
  refresh tokens and deletes delegated OAuth2 permission grants.
- Wipe Google 2FA Methods ($btnWipeGoogle2fa, -Scope GoogleTwoStep): Runs
  gam user <id> turnoff2sv to turn off Google 2-Step Verification (2FA) enrollments,
  security keys, and backup codes.
- Wipe Google OAuth Grants ($btnWipeGoogleTokens, -Scope GoogleTokens): Runs
  gam user <id> deprovision to revoke 3rd-party Google OAuth grants, App-Specific
  Passwords (ASPs), and 2SV backup codes.
- Wipe All (Entra + GAM7) ($btnWipeCloudMfa, -Scope All): Executes all four
  cloud persistence wipe steps sequentially.
- Expire AD Account & Restrict Workstations ($btnExpireAdNow): Sets accountExpires
  to past FileTime (causing Kerberos KDC error 0x12) and sets userWorkstations to INCIDENT-LOCK.
- Audit M365 & Gmail Rules ($btnAuditForwardingRules): Inspects Graph inbox messageRules and GAM7
  Gmail forwarding/filters, flagging external forwards and stealth deletes.
- Disable Rule / Enable Rule / Delete Rule / Disable Suspicious: Remediates rogue inbox rules via Graph/GAM7.

TAB 4: MULTI-SOURCE SECURITY EVENT TRIAGE
- Pull Events (AD + Entra + Google) ($btnPullSecurityEvents): Queries DC security event logs
  (4624, 4625, 4740, 4768, 4769, 4771, 4776, 4720-4738), Entra sign-in logs, and GAM reports.
- View Event Guide ($btnLoadReferenceCatalog): Loads the complete built-in security
  dictionary for offline event lookup.
- Show Pulled Events ($btnRestorePulledEvents): Restores previous query results
  instantly without re-querying domain controllers or APIs.
- Live Filter ($txtEventSearch) & Full Result/Detail Highlighting: Searches across
  Timestamp, Source, EventCode, Severity, HostOrIP, Meaning, Decision, and RawDetail
  as you type, using GDI+ CellPainting across columns 1..5 (Source, Code, Severity,
  Host/IP, Summary) plus Update-EventDecisionDetailBox RichTextBox highlighting
  inside the clicked event detail panel ($txtEventDecision, DetectUrls = $false).

TAB 5: FORENSIC COMPLIANCE AUDIT TRAIL
- Refresh Audit Trail ($btnRefreshAudit): Reads C:\ProgramData\IncidentResponse-Automator\AuditLog.csv.
- Export to CSV... ($btnExportAudit): Exports sanitized audit records for compliance reporting.
- Inspect Selected Entry ($btnViewAuditDetail): Displays full raw verification details.

================================================================================
4. ACTIVE DIRECTORY PROTOCOL MECHANICS
================================================================================
KERBEROS KDC HARD-LOCK:
When accountExpires is set to a past FileTime:
1. Compromised client presents existing, unexpired Ticket Granting Ticket (TGT) to KDC.
2. KDC inspects the target account record in Active Directory.
3. Because accountExpires is in the past, KDC terminates ticket evaluation and returns:
   0x12: KDC_ERR_CLIENT_REVOKED (Clients credentials have been revoked)
This neutralizes all Kerberos service ticket requests across the domain without
requiring a domain-wide krbtgt password reset.

WORKSTATION RESTRICTION (userWorkstations):
The userWorkstations attribute is set to "INCIDENT-LOCK". When network or interactive
logon is attempted via NTLM or Kerberos, Domain Controllers reject authentication with:
STATUS_INVALID_WORKSTATION (0xC0000070).

================================================================================
5. CLOUD TOKEN INVALIDATION MECHANICS
================================================================================
MICROSOFT ENTRA ID:
Calling /v1.0/users/{id}/revokeSignInSessions updates signInSessionsValidFromDateTime
in the Microsoft Entra Security Token Service (STS). Subsequent refresh token requests
fail with:
AADSTS50173: The provided grant has expired or is revoked.
Continuous Access Evaluation (CAE) clients terminate access within seconds to minutes.
Set-MgGraphOption -DisableLoginByWAM $true keeps elevated admin tokens decoupled from
the daily Windows session, and non-default Domain Profiles isolate IR_GRAPH_SETUP_DIR
and MgContext.json under %LOCALAPPDATA%\IncidentResponse-Automator\Profiles\<id>.

GOOGLE WORKSPACE:
Executing gam user <upn> signout terminates web session cookies and mobile sync.
Executing gam user <upn> deprovision revokes all application-specific passwords,
2-Step Verification backup codes, and authorized third-party OAuth app grants.
Primary profiles use standard %USERPROFILE%\.gam; additional Domain Profiles
automatically isolate GAMCFGDIR under %LOCALAPPDATA%\IncidentResponse-Automator\Profiles\<id>\gam.

================================================================================
6. HIGH-DPI RESPONSIVE SCALING ENGINE
================================================================================
- Baseline coordinate grid: 874 x 868.
- Dynamic proportional scaling (Update-ResponsiveLayout) calculates X and Y scalar ratios on form resize.
- All modal prompts invoke Invoke-ApplyModalResponsiveScale (ClientSize bounds, 1.0x-1.45x scaling,
  UseMnemonic = $false, literal GroupBox && labels, and TextRenderer::MeasureText wrapped-label expansion).
- Pixel-safe font caching quantizes half-point steps in $script:pixelFontCache using GraphicsUnit::Pixel,
  preventing GDI handle exhaustion and clipped text under 1080p, 1440p, 4K, and full-screen DPI modes.

================================================================================
7. PERMISSIVE COMMERCIAL USE, FORKING & SHOUT-OUT TERMS
================================================================================
- OPEN USE & FORKING: Anyone is free to use, copy, modify, merge, publish,
  distribute, sublicense, and/or fork this application under the Apache License 2.0.
- COMMERCIAL / FOR-PROFIT USE: Anyone is permitted to sell, commercialize, or
  incorporate any part of this software into a paid product or service, subject
  only to leaving a quick public shout-out or repository attribution on this project's
  official GitHub repository. You do NOT need to wait for approval before proceeding.

================================================================================
8. LEGAL DISCLAIMER & NO MAINTENANCE OBLIGATION
================================================================================
- USE ENTIRELY AT YOUR OWN RISK: This software is provided strictly "AS IS" without
  warranty of any kind.
- MANDATORY USER CODE REVIEW: It is 100% the user's sole responsibility to read,
  inspect, audit, and understand the source code before executing it.
- ZERO LIABILITY: The author(s), contributor(s), and maintainer(s) assume zero
  liability for any damages, downtime, directory corruption, or data loss whatsoever.
- NO MAINTENANCE OBLIGATION: The author is not responsible for updating, patching,
  supporting, or maintaining this application.
See DISCLAIMER.md, NOTICE, and LICENSE for complete legal terms.
================================================================================
