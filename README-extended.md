# Security Incident Response Automator — Extended Technical Manual

[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20%7C%20Server-0078D6?logo=windows)](https://microsoft.com)
[![PowerShell: 5.1+](https://img.shields.io/badge/PowerShell-5.1%20%7C%207.x-5391FE?logo=powershell)](https://learn.microsoft.com/powershell/)
[![Framework: .NET 4.8+](https://img.shields.io/badge/.NET%20Framework-4.8%2B-512BD4?logo=dotnet)](https://dotnet.microsoft.com)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Version: 1.1.53](https://img.shields.io/badge/Version-1.1.53-emerald.svg)](CHANGELOG.md)

### Exhaustive Architectural Specification & Control-by-Control Engineering Reference
**Target Audience:** Cybersecurity Engineers, SOC Leads, Systems Architects, and Security Developers

---

## Table of Contents
1. [Architectural Overview & Identity Surface Matrix](#1-architectural-overview--identity-surface-matrix)
2. [Multi-Attribute Identity Candidate Resolution Engine](#2-multi-attribute-identity-candidate-resolution-engine)
3. [Exhaustive Button & Control Technical Reference](#3-exhaustive-button--control-technical-reference)
   - [Top Header Controls & Theme Engine](#top-header-controls--theme-engine)
   - [Tab 1: Integrations & Pre-Flight Setup](#tab-1-integrations--pre-flight-setup)
   - [Tab 2: Containment & Live Telemetry Deck](#tab-2-containment--live-telemetry-deck)
   - [Tab 3: Deep Isolation & Mailbox Security Rules Auditor](#tab-3-deep-isolation--mailbox-security-rules-auditor)
   - [Tab 4: Multi-Source Security Event Triage & Decoder](#tab-4-multi-source-security-event-triage--decoder)
   - [Tab 5: Forensic Compliance Audit Trail](#tab-5-forensic-compliance-audit-trail)
4. [Active Directory Internal Mechanics & Wire Protocols](#4-active-directory-internal-mechanics--wire-protocols)
5. [Microsoft Graph REST Endpoints & Token Invalidation Mechanics](#5-microsoft-graph-rest-endpoints--token-invalidation-mechanics)
6. [Google Workspace Admin SDK & GAM7 CLI Orchestration](#6-google-workspace-admin-sdk--gam7-cli-orchestration)
7. [High-DPI Responsive Scaling & Pixel Font Cache Engine](#7-high-dpi-responsive-scaling--pixel-font-cache-engine)
8. [Permissive Commercial Use, Forking & Shout-Out Terms](#8-permissive-commercial-use-forking--shout-out-terms)
9. [Legal Disclaimer & No Maintenance Obligation](#9-legal-disclaimer--no-maintenance-obligation)

---

## 1. Architectural Overview & Identity Surface Matrix

**Security Incident Response Automator** operates as a native Windows Forms administrative utility hosted within a single-threaded apartment (`-STA`) Windows PowerShell 5.1 / .NET Framework 4.8 runtime. It orchestrates identity operations directly across three heterogeneous authentication and directory surfaces without intermediate proxy servers, telemetry collectors, or cloud databases:

```
+---------------------------------------------------------------------------------+
|                        Incident Response Automator                              |
|                          (WinForms / .NET 4.8)                                  |
+-------------------+-----------------------------+-------------------------------+
         |                                        |                               |
    LDAP / Kerberos                              HTTPS                           HTTPS / CLI
         v                                        v                               v
+-------------------+                 +-----------------------+       +-----------------------+
|  Active Directory |                 |  Microsoft Entra ID   |       |   Google Workspace    |
|   Domain Services |                 |  (Microsoft Graph API)|       |  (GAM7 / Admin SDK)   |
+-------------------+                 +-----------------------+       +-----------------------+
  - pwdLastSet                          - RevokeSignInSessions          - gam signout
  - userAccountControl                  - accountEnabled = false        - update suspended on/off
  - accountExpires                      - Delete OAuth Grants           - deprovision (MFA/ASPs)
  - userWorkstations                    - Delete Removable Auth         - Audit Gmail Forwarding
  - DC Security Event Logs              - Audit Inbox Rules             - Audit Login Reports
```

### Identity Protocol Matrix
| Provider | Communication Channel | Primary Protocols / APIs | Authentication Mode | Required Permissions / Scopes |
| :--- | :--- | :--- | :--- | :--- |
| **Active Directory** | Direct LAN/VPN to Domain Controller | LDAP (TCP 389), LDAPS (TCP 636), Kerberos (TCP 88), RPC (TCP 135/49152+) | Integrated Kerberos / Explicit `PSCredential` | Domain Admins or Account Operators |
| **Microsoft Entra ID** | Direct WAN to `graph.microsoft.com` | HTTPS TLS 1.2 / 1.3 REST API | Delegated OAuth 2.0 Bearer Token | `User.RevokeSessions.All`, `Directory.AccessAsUser.All`, `User.ReadWrite.All`, `MailboxSettings.ReadWrite`, `AuditLog.Read.All`, `IdentityRiskEvent.Read.All` |
| **Google Workspace** | Direct WAN to Google APIs via `gam.exe` | Google Admin SDK Directory API, Gmail Settings API, Reports API | Google OAuth 2.0 Service Account / User Consent | Super Admin or Delegated Workspace Administrator |

---

## 2. Multi-Attribute Identity Candidate Resolution Engine

In modern hybrid enterprises, on-premises Active Directory accounts rarely possess identical identifiers to their cloud counterparts:
* **Internal Active Directory UPNs:** `alex.morgan@corp.internal` or `amorgan@ad.domain.local`
* **Cloud Routable UPNs:** `alex.morgan@contoso.com`
* **Legacy sAMAccountNames:** `am8001` or `amorgan`
* **Proxy Addresses / Aliases:** `smtp:alexm@contoso.com`, `SMTP:alex.morgan@contoso.com`

### Resolution Workflow (`Resolve-UserCloudIdentities`)
1. **LDAP Attribute Extraction:** When a target user is selected from Active Directory, the engine extracts `sAMAccountName`, `userPrincipalName`, `mail`, and every entry in the `proxyAddresses` multi-valued attribute.
2. **Candidate Array Compilation:** Both primary (`SMTP:`) and secondary (`smtp:`) aliases are parsed. Any non-routable internal suffixes (`.local`, `.lan`, `.internal`, `.corp`) are cataloged, and routable domain candidates are prioritized.
3. **Microsoft Graph OData Querying:** The resolver submits an optimized OData query to Microsoft Graph:
   ```http
   GET /v1.0/users?$filter=userPrincipalName eq '{id}' or mail eq '{id}' or onPremisesSamAccountName eq '{sam}'
   ```
4. **Google Workspace Candidate Probing:** GAM evaluates identity candidates sequentially (`alex.morgan@contoso.com`, `am8001@contoso.com`, etc.) against the Admin Directory API until an active Google Workspace account is positively confirmed.
5. **Session Pinning:** Once correlated, the unique identifiers are pinned into `$script:targetGraphUser` and `$script:targetGamUser` to ensure all subsequent cloud commands target the exact verified account.

---

## 3. Exhaustive Button & Control Technical Reference

### Top Header Controls & Theme Engine

#### `[ Light Mode ]` / `[ Dark Mode ]` (`$btnThemeToggle`)
* **Underlying Function:** `Apply-AppTheme([bool]$Dark)`
* **Mechanics:** Inverts `$script:isDark`. Traverses the visual tree and applies color styles:
  * Form background: `#0f172a` (Dark) vs `#f8fafc` (Light)
  * Header panel: `#0f172a` (Dark) vs `#f1f5f9` (Light)
  * Title and subtext: `#ffffff` / `#94a3b8` (Dark) vs `#0f172a` / `#475569` (Light)
  * Action and decision text boxes (`$txtLog`, `$txtRuleDecision`, `$txtEventDecision`): `#020617` / `#e2e8f0` (Dark) vs `#ffffff` / `#0f172a` (Light)
  * DataGridView cells, headers, and alternating row backgrounds are restyled dynamically without losing current selection or scroll position.

#### `Switch Domain / DC` (`$btnSwitchDomain`)
* **Underlying Function:** `Show-DomainSwitcher`
* **Mechanics:** Displays a modal dialog permitting operators on non-domain-joined management stations to target an alternate domain or specific Domain Controller.
* **Modal Controls:**
  * **`[Auto-Detect Domain]` (`$btnDlgDetect`):** Executes `Get-DiscoveredLocalDomainSafe`. Uses Win32 `System.DirectoryServices.ActiveDirectory.Domain::GetComputerDomain()` and IP Global Properties (`GetIPGlobalProperties().DomainName`) to determine the joined network domain and auto-populates `$txtDlgDomain`.
  * **`Domain Name` (`$txtDlgDomain`):** FQDN of target Active Directory domain. The last connected domain is persisted to `remembered_domain.json`.
  * **`Domain Controller (Optional)` (`$txtDlgServer`):** Explicit hostname or IP address of the target Domain Controller.
  * **`Operator Credentials` (`$txtDlgUser`, `$txtDlgPass`):** Explicit administrative credentials held exclusively in volatile memory as a `System.Management.Automation.PSCredential` object.
  * **`Verify & Connect` (`$btnDlgConnect`):** Executes an LDAP RootDSE query against the specified server. Upon success, updates `$script:targetDomain`, `$script:targetServer`, and `$script:adCredential`.

---

### Tab 1: Integrations & Pre-Flight Setup

#### `Test Active Directory` (`$btnTestAD`)
* **Underlying Function:** `Invoke-VerifyAD`
* **Mechanics:** Initiates a live connection to `LDAP://<targetServer>/RootDSE`. Validates `defaultNamingContext` and checks Kerberos/LDAP authentication. Returns domain name, DC name, and binding response time.

#### `Test Microsoft Graph` (`$btnTestM365`)
* **Underlying Function:** `Invoke-VerifyGraph`
* **Mechanics:** Calls `Get-MgContext`. Validates active delegated access tokens, verifies required scopes (`User.RevokeSessions.All`, `Directory.AccessAsUser.All`), and executes a lightweight probe against `/v1.0/organization` to confirm tenant connectivity.

#### `Test Google GAM7` (`$btnTestGoogle`)
* **Underlying Function:** `Invoke-VerifyGAM`
* **Mechanics:** Validates existence of `gam.exe` at `C:\GAM7\gam.exe` or `%LOCALAPPDATA%\Programs\GAM7\gam.exe`. Verifies presence of `oauth2.txt` and executes `gam oauth verify`.

#### `1. Setup Microsoft Graph` (`$btnSetupM365`)
* **Underlying Function:** `Launch-SetupScript` targeting `Setup-MicrosoftGraph.bat`
* **Mechanics:** Executes the embedded Base64 payload or standalone batch file. Uses PowerShell Gallery to install lightweight SDK modules (`Microsoft.Graph.Authentication`, `Microsoft.Graph.Users`, `Microsoft.Graph.Users.Actions`) and triggers device code authentication (`Connect-MgGraph -UseDeviceAuthentication`).

#### `2. Setup Google GAM7` (`$btnSetupGAM`)
* **Underlying Function:** `Launch-SetupScript` targeting `Setup-GoogleWorkspace-GAM.bat`
* **Mechanics:** Downloads the verified release of GAM7 from GitHub, validates SHA-256 hash, creates installation folders, and initiates Google Cloud project authorization and OAuth consent.

#### `3. Install RSAT (Optional)` (`$btnSetupRSAT`)
* **Underlying Function:** `Launch-SetupScript` targeting `Setup-RSAT-ActiveDirectory.bat`
* **Mechanics:** Invokes Windows DISM / Capabilities to install the optional `Rsat.ActiveDirectory.DS-LDS.Tools` feature without requiring installation media.

---

### Tab 2: Containment & Live Telemetry Deck

#### `Find Users` (`$btnSearch`)
* **Underlying Function:** `Execute-UserSearch`
* **Mechanics:** Evaluates `$txtSearch.Text` (enforcing a 3-character minimum). Executes an Ambiguous Name Resolution (ANR) LDAP filter:
  ```ldap
  (|(anr={search})(sAMAccountName={search}*)(userPrincipalName={search}*)(mail={search}*)(proxyAddresses=smtp:*{search}*))
  ```
  Returns matching directory entries and populates `$lstResults`.

#### `Refresh Sessions` (`$btnRefreshUserSessions`)
* **Underlying Function:** `Get-UserActiveSessionTelemetry`
* **Mechanics:** Re-queries Active Directory (`pwdLastSet`, `userAccountControl`), Microsoft Graph (`signInSessionsValidFromDateTime`), and GAM7 (`gam info user`) to refresh the 4 live status cards.

#### `Safety Checkbox` (`$chkConfirmUser`)
* **Mechanics:** Hardware interlock pattern. Toggling state enables/disables the Action Decks across Tab 2 and Tab 3, preventing accidental execution against unintended accounts.

#### `1. Reset Password` (`$btnResetPass`)
* **Underlying Function:** `Set-ADPasswordSafe`
* **Mechanics:** Displays an inline reset box. Invokes `DirectoryEntry.Invoke("SetPassword", @($Password))`. Sets `pwdLastSet = 0` (forcing password change at next logon). Re-queries LDAP to verify the attribute write succeeded.

#### `2. Revoke 365 Sessions` (`$btnRevoke365`)
* **Underlying Function:** `Invoke-GraphUserRevokeSignInSessionsSafe`
* **Mechanics:** Sends an HTTP POST to `/v1.0/users/{id}/revokeSignInSessions`. Verifies that the returned JSON payload indicates `value = true`.

#### `3. Revoke Google Sessions` (`$btnRevokeGoogle`)
* **Underlying Function:** `Invoke-GamUserSignoutSafe`
* **Mechanics:** Executes `gam user <id> signout`. Inspects process return code (`$LASTEXITCODE -eq 0`) and validates token revocation in Google Workspace.

#### `4. Disable Account` / `Enable Account` (`$btnDisableAcct`)
* **Underlying Function:** `Set-ADAccountEnableSafe`
* **Mechanics:** Reads `userAccountControl` bitmask. Toggles `ADS_UF_ACCOUNTDISABLE (0x0002)`. Writes the updated integer value via LDAP and performs an immediate read-back to verify state.

#### `Run Full Playbook (1-Click)` (`$btnRunPlaybook`)
* **Underlying Function:** Orchestrated sequential execution of Actions 1, 2, 3, and 4 with verification gates between each step.

---

### Tab 3: Deep Isolation & Mailbox Security Rules Auditor

#### `Block Entra Sign-In (Instant)` / `Unblock Entra` (`$btnBlockEntra`)
* **Underlying Function:** `Set-MgUserSignInEnabledSafe`
* **Mechanics:** Submits a PATCH request to Microsoft Graph:
  ```http
  PATCH /v1.0/users/{id}
  Content-Type: application/json

  {"accountEnabled": false}
  ```
  Immediately severs cloud authentication, eliminating the 30-minute Azure AD Connect replication window.

#### `Suspend Google User (GAM 7)` / `Unsuspend Google` (`$btnSuspendGoogle`)
* **Underlying Function:** `Set-GamUserSuspendedSafe`
* **Mechanics:** Executes `gam update user <id> suspended on`. Performs a 3-pass convergence loop querying `gam info user <id>` with regex matching to verify suspension across Google directory clusters.

#### `Wipe Cloud MFA Methods, OAuth App Grants, App Passwords Backup Codes` (`$btnWipeCloudTokens`)
* **Underlying Function:** `Invoke-WipeCloudMfaAndTokensSafe`
* **Mechanics:**
  1. Revokes Entra ID refresh tokens.
  2. Enumerates `/v1.0/users/{id}/oauth2PermissionGrants` and deletes all delegated consent entries.
  3. Enumerates `/v1.0/users/{id}/authentication/methods` and issues DELETE requests against phone, TOTP, and FIDO methods.
  4. Executes `gam user <id> deprovision` to revoke Google application passwords, 2SV backup codes, and authorized apps.

#### `Expire AD Account Restrict Workstations` (`$btnLockADWorkstations`)
* **Underlying Function:** `Set-ADExtendedLockdownSafe`
* **Mechanics:** Sets `accountExpires` to `DateTime.UtcNow.AddMinutes(-5).ToFileTime()`, triggering Kerberos KDC error `0x12`. Writes sentinel string `INCIDENT-LOCK` to `userWorkstations` to invalidate NTLM network logons.

#### `Audit M365 Gmail Rules` (`$btnAuditRules`)
* **Underlying Function:** `Get-UserForwardingAndInboxRulesSafe`
* **Mechanics:** Queries Microsoft Graph `/v1.0/users/{id}/mailFolders/inbox/messageRules` and executes `gam user <id> show forward` and `gam user <id> show filters`. Parses actions for external forwards, stealth deletes, and hidden folder moves, populating `$gridRules`.

#### `Disable Rule` / `Delete Rule` / `Disable Suspicious`
* **Underlying Function:** `Disable-OrRemoveForwardingRuleSafe`
* **Mechanics:** Issues PATCH or DELETE requests against Microsoft Graph inbox rules or executes `gam user <id> delete forward` / `delete filter <id>`.

---

### Tab 4: Multi-Source Security Event Triage & Decoder

#### `Pull Events (AD + Entra + Google)` (`$btnPullEvents`)
* **Underlying Function:** `Get-UserSecurityEventsSafe`
* **Mechanics:**
  * Queries Active Directory Domain Controller Security Event Logs via `Get-WinEvent` with XPath filters for Event IDs 4624, 4625, 4740, 4768, 4769, 4771, 4776, 4720-4738.
  * Queries Microsoft Graph `/v1.0/auditLogs/signIns` and `/v1.0/identityProtection/riskDetections`.
  * Executes `gam report login user <id>`.
  * Ingests, normalizes, and passes records into `$gridEvents`.

#### `View Event Guide` (`$btnLoadReferenceCatalog`) & `Show Pulled Events` (`$btnRestorePulledEvents`)
* **Mechanics:** State-preserving view toggle. Loads the complete built-in security dictionary into `$gridEvents` for offline reference. Clicking **Show Pulled Events** restores the previously pulled query cache without initiating network traffic.

---

### Tab 5: Forensic Compliance Audit Trail

#### `Refresh Audit Trail` (`$btnRefreshAudit`)
* **Mechanics:** Reads `C:\ProgramData\IncidentResponse-Automator\AuditLog.csv`, parses headers, and binds rows to `$gridAudit`.

#### `Export to CSV...` (`$btnExportAudit`)
* **Mechanics:** Opens a `SaveFileDialog` allowing the operator to export a sanitized, timestamped audit report.

#### `Inspect Selected Entry` (`$btnViewAuditDetail`)
* **Mechanics:** Opens a modal dialog displaying full raw verification details, target identifiers, and operator context.

---

## 4. Active Directory Internal Mechanics & Wire Protocols

### Kerberos KDC Hard-Lock Protocol Details
When a user authenticates in an Active Directory domain, the Kerberos Key Distribution Center (KDC) issues a Ticket Granting Ticket (TGT) typically valid for **10 hours**. Changing the user's password invalidates the password hash (`unicodePwd`), preventing *new* TGT requests. However, existing TGTs remain valid for requesting service tickets (`KRB_TGS_REQ`) until expiry.

To immediately neutralize existing TGTs without requiring a domain-wide `krbtgt` password reset:
1. The automator sets `accountExpires` to an elapsed UTC timestamp:
   ```powershell
   $pastTime = [DateTime]::UtcNow.AddMinutes(-5).ToFileTime()
   $entry.Properties["accountExpires"].Value = $pastTime
   $entry.CommitChanges()
   ```
2. When the compromised client presents its existing TGT to the KDC, the KDC inspects the account's directory attributes.
3. Because `accountExpires` is elapsed, the KDC terminates ticket evaluation and returns:
   `0x12: KDC_ERR_CLIENT_REVOKED (Clients credentials have been revoked)`

---

## 5. Microsoft Graph REST Endpoints & Token Invalidation Mechanics

### Refresh Token Revocation
* **HTTP Endpoint:** `POST https://graph.microsoft.com/v1.0/users/{id}/revokeSignInSessions`
* **STS Behavior:** Microsoft Entra Security Token Service updates `signInSessionsValidFromDateTime` to the current UTC timestamp.
* **OAuth Evaluation:** Subsequent refresh requests fail with `AADSTS50173: The provided grant has expired or is revoked`. Continuous Access Evaluation (CAE) clients terminate access within seconds.

---

## 6. Google Workspace Admin SDK & GAM7 CLI Orchestration

* **Session Termination:** `gam user <upn> signout` calls the Directory API to invalidate user cookies and OAuth refresh tokens.
* **Account Suspension:** `gam update user <upn> suspended on` freezes mailbox access and API interaction.
* **Credential Deprovisioning:** `gam user <upn> deprovision` clears application-specific passwords, 2-Step Verification backup codes, and third-party authorized scopes.

---

## 7. High-DPI Responsive Scaling & Pixel Font Cache Engine

To guarantee consistent rendering across standard 1080p, 1440p, and 4K displays:
* The layout engine establishes a baseline client coordinate space ($874 \times 868$).
* On form resize, child controls are recalculated via proportional scaling factors ($X$ and $Y$).
* Font sizes are cached in `$script:pixelFontCache` using quantized half-point steps, eliminating GDI font handle leaks and preventing blurry text under Windows DPI virtualization.

---

## 8. Permissive Commercial Use, Forking & Shout-Out Terms

* **Open Use & Forking:** Free for any individual or organization to use, fork, adapt, and distribute under the [Apache License, Version 2.0](LICENSE).
* **For-Profit / Commercial Integration:** Any party is explicitly permitted to incorporate this software or any portion of its source code into commercial or paid software, services, or hardware solutions. The sole condition is leaving a public shout-out or repository attribution on this project's official GitHub repository (e.g. via GitHub Issues or Discussions). **No permission or reply is required before proceeding.**

---

## 9. Legal Disclaimer & No Maintenance Obligation

* **Use Entirely at Your Own Risk:** Provided strictly "AS IS" without warranty or condition of any kind.
* **Mandatory User Code Review:** High-privilege administrative utilities must be audited before deployment. **It is 100% the user's sole responsibility to read, inspect, audit, and understand the source code before execution.**
* **Zero Liability:** The author(s), contributor(s), and maintainer(s) assume zero liability for any damages, downtime, directory corruption, or data loss whatsoever.
* **No Maintenance Obligation:** The author is under zero obligation to update, patch, maintain, or support this application.

For complete legal terms, refer to [DISCLAIMER.md](DISCLAIMER.md), [NOTICE](NOTICE), and [LICENSE](LICENSE).
