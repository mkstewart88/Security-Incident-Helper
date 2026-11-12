# Changelog

All notable additions and milestones for **Security Incident Response Automator** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.53] - 2026-11-12

### Added
- **Local EXE Auto-Recompilation on Update (`Show-UpdateCheckWindow`):**
  - When running as compiled `IncidentResponse.exe` without a `.exe` asset on GitHub Releases, **Update & Restart** now downloads the updated `IncidentResponse-Automator.ps1` directly from GitHub, validates PowerShell syntax, compiles `IncidentResponse.exe.new` locally via `PS2EXE` inside the application folder, verifies the PE (`MZ`) header, hot-swaps the executable, and restarts automatically.

### Improved & Fixed
- **SentinelOne-Friendly Hot-Swap & GitHub Cache/Encoding Fixes:**
  - Replaced `-EncodedCommand` swap invocation with clean `-File` scripts staged in the application directory.
  - Added UTF-8 `byte[]` decoding (`$decodeWebContent`) for GitHub API `raw+json` `VERSION` and `CHANGELOG.md` responses in Windows PowerShell 5.1 and resolved the latest `main` commit SHA to bypass the 5-minute `raw.githubusercontent.com` CDN cache.

---

## [1.1.52] - 2026-11-12

### Changed
- Testing Update Feature

---

## [1.1.51] - 2026-11-12

### Added
- **GitHub Self-Updater & Release Notes Viewer (`Show-UpdateCheckWindow` & `Show-ChangelogWindow`):**
  - Added **[Check for Updates]** button to the top console header alongside theme toggle and domain switcher controls, supporting both Light Mode and Dark Mode.
  - Queries GitHub Releases (`releases/latest`) with automatic `VERSION` fallback, displays a colorized status log (`RichTextBox` with clickable repository URLs, green status text when running the latest version, and red status text when an update is available), and disables **Update & Restart** until a newer version is confirmed.
  - Added **[View Changelog]** dialog displaying GitHub release notes or local `CHANGELOG.md` history separately from the update status feed.
  - Implemented verified hot-swap self-replacement for both `Launch-IncidentAutomator.bat` (`.ps1` syntax-validated via PowerShell `Parser::ParseFile`) and compiled `IncidentResponse.exe` (`MZ` PE-header validated) with automatic restart.

### Fixed
- **Microsoft Graph Silent Session Restoration for Delegated Admins:**
  - Updated `Invoke-VerifyGraph`, `Ensure-MgGraphSessionActive`, `Invoke-RevokeMgUserSignInSessionSafe`, and `Invoke-GraphMailboxRestSafe` to silently attach to the cached `CurrentUser` MSAL session and prevent `DeviceCodeCredential` `NullReferenceException` errors on fresh workstations without App-Only registration.
- **Update Dialog Button & Syntax Fixes:**
  - Restored closing block and `ShowDialog` call in `Show-DomainSwitcher` and disabled WinForms mnemonic parsing (`UseMnemonic = $false`) so the **Update & Restart** button displays its ampersand literally.

---

## [1.1.5] - 2026-11-05

### Added
- **Dynamic Multi-Domain Auto-Discovery Engine (`Get-DiscoveredLocalDomainSafe`):**
  - Integrated native Win32/ADSI domain discovery capable of enumerating the current workstation's primary joined domain, forest root domain, and DNS suffix search list.
  - Added dedicated **[Auto-Detect Domain]** button to the Domain & DC Switcher dialog, allowing seamless domain migration for technicians servicing multiple client environments without requiring manual registry edits.
- **Unified Light Mode & Dark Mode Dynamic Theme Engine:**
  - Extended runtime color transformation across the entire application interface, including the top header console panel, title, sub-label, domain switcher, real-time action log, rule inspector, and deciphered event intelligence boxes.
  - Provides high-contrast light theme and dark theme with one-click toggling.
- **Stateful Event Catalog & Query Persistence:**
  - Added state caching to the Security Event Triage deck, enabling incident responders to inspect the comprehensive **Event Code Guide** reference catalog and return directly to previously pulled live events without re-querying domain controllers or cloud endpoints.

---

## [1.1.0] - 2026-11-04

### Added
- **5-Tab Structured Incident Response Architecture (`IncidentResponse-Automator.ps1`):**
  - Modularized the native Windows Forms interface into an intuitive five-stage containment lifecycle:
    - **Tab 1 (`1. Setup`):** Live pre-flight integration status, diagnostic validation tests, and 1-click automated setup script launchers.
    - **Tab 2 (`2. Containment`):** Multi-attribute target user lookup, 4 live security status cards, safety verification gate, and primary containment deck.
    - **Tab 3 (`3. Deep Isolation`):** Comprehensive account isolation deck and mailbox forwarding rules auditor with one-click remediation.
    - **Tab 4 (`4. Event Triage`):** Multi-source security event triage engine querying Active Directory, Microsoft Entra ID, and Google Workspace with plain-English decoders.
    - **Tab 5 (`5. Audit Trail`):** Searchable, filterable compliance audit log recorded locally with CSV field escaping.
- **Instant Microsoft Entra ID Sign-In Blocking (`Set-MgUserSignInEnabledSafe`):**
  - Direct REST patching of `accountEnabled = $false` on `/v1.0/users/{id}` via Microsoft Graph, immediately closing the 30-minute Entra Connect synchronization window when an on-premises account is disabled.
- **Google Workspace Account Suspension (`Set-GamUserSuspendedSafe`):**
  - Orchestration of Google Admin SDK Directory API via GAM7 to suspend user accounts and verify state with multi-pass convergence verification.
- **Persistent Cloud MFA, OAuth Grant, App Password & Backup Code Deprovisioning (`Invoke-WipeCloudMfaAndTokensSafe`):**
  - Simultaneous cloud eviction revoking Microsoft Entra refresh tokens, deleting third-party OAuth2 permission grants, removing SMS/TOTP/FIDO authentication methods, and purging Google application-specific passwords and two-step verification backup codes.
- **Mailbox Forwarding, Auto-Redirect & Hide-Hole Inbox Rules Auditor (`Get-UserForwardingAndInboxRulesSafe` & `Disable-OrRemoveForwardingRuleSafe`):**
  - Deep inspection of Microsoft 365 inbox rules and Google Workspace Gmail forwarding addresses/filters, flagging external exfiltration, stealth auto-delete, and hide-hole routing with one-click single or bulk remediation.
- **Active Directory `accountExpires` KDC Hard-Lock & `userWorkstations` Lockdown (`Set-ADExtendedLockdownSafe`):**
  - Writes elapsed FileTime timestamps to `accountExpires` to force immediate Kerberos KDC ticket rejection (`0x12: KDC_ERR_CLIENT_REVOKED`) and restricts `userWorkstations` to sentinel hostnames to prevent interactive or network logon across the enterprise.
- **Multi-Source Security Event Triage Engine (`Get-UserSecurityEventsSafe` & `Get-DecodedEventIntelligence`):**
  - Real-time ingestion and plain-English decoding of Windows Domain Controller events (4624, 4625, 4740, 4768, 4769, 4771, 4776, 4720-4738, 4648, 4778, 4779), Microsoft Entra ID sign-in telemetry, and Google Workspace security audit records.
- **Single-Threaded Apartment (`-STA`) Auto-Enforcement:**
  - Embedded self-relaunch logic ensuring the script automatically runs in `-STA` mode regardless of whether executed from PowerShell, batch launcher, or compiled executable.

---

## [1.0.5] - 2026-11-03

### Added
- **Multi-Attribute Cloud Identity Candidate Resolver (`Resolve-UserCloudIdentities`):**
  - Correlates on-premises Active Directory accounts with cloud tenants across `userPrincipalName`, `mail`, `sAMAccountName`, and `proxyAddresses` (both primary `SMTP:` and secondary `smtp:` aliases), ensuring reliable session revocation in non-contiguous hybrid namespaces.
- **Live Multi-Provider Security Status Telemetry:**
  - Real-time status cards displaying Active Directory Password Age, Microsoft 365 / Entra Session State, Google Workspace Session State, and Active Directory Account Status.
- **Compliance Audit Trail Engine:**
  - Structured local logging to `C:\ProgramData\IncidentResponse-Automator\AuditLog.csv` with real-time text searching, status filtering, and dedicated inspection dialog.
- **Embedded Self-Extracting Setup Batch Scripts:**
  - Base64-encoded deployment payloads for `Setup-MicrosoftGraph.bat`, `Setup-GoogleWorkspace-GAM.bat`, and `Setup-RSAT-ActiveDirectory.bat` embedded directly within the main script for completely self-contained distribution.

---

## [1.0.0] - 2026-11-02

### Added
- **Core Native Windows Incident Containment Console (`IncidentResponse-Automator.ps1`):**
  - Windows Forms application written in native PowerShell 5.1 / .NET Framework 4.8.
- **Dual-Engine Active Directory Management:**
  - Complete support for user querying, password resets, force password change at logon (`pwdLastSet = 0`), and account disablement using either RSAT Active Directory cmdlets or native .NET `System.DirectoryServices` (LDAP/ADSI).
- **Microsoft Graph Session Revocation:**
  - Interactive device authentication and one-click session invalidation for Microsoft 365, Outlook, Teams, and mobile clients.
- **Google Workspace Session Revocation:**
  - One-click termination of active Google Workspace web cookies and mobile device sessions via GAM7 CLI.
- **Domain & Domain Controller Switcher:**
  - Interactive credential dialog supporting explicit Domain Controller FQDN/IP addresses and alternative administrative credentials for non-domain-joined management stations.
- **Responsive Layout & High-DPI Scaling Engine:**
  - Proportional coordinate calculation and pixel-safe font caching supporting 1080p, 1440p, 4K, and high-DPI workstation displays.
