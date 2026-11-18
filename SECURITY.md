# Security Policy & Operational Responsibility

## "As-Is" Release & No Maintenance Obligation

**Security Incident Response Automator** is released strictly **"AS IS"** without warranty, support, or maintenance obligations of any kind:

- **No Maintenance or Update Guarantee:** The author is **not responsible for updating or maintaining** this application. There is no SLA, no guaranteed response time, and no obligation to provide patches, updates, or compatibility fixes for future Windows, Active Directory, Microsoft Graph, or GAM7 releases.
- **Mandatory Code Audit Before Execution:** Because this tool executes high-privilege containment operations against Active Directory, Microsoft Entra ID (Microsoft 365), and Google Workspace, **it is 100% the user's responsibility to read, audit, and understand the source code (`IncidentResponse-Automator.ps1` and all `.bat`/`.cmd` scripts) before executing it** in any environment.
- **Zero Liability:** The author(s) and contributor(s) are **not responsible for anything that happens as a result of someone using this tool**. Use entirely at your own risk. See [DISCLAIMER.md](DISCLAIMER.md) and [NOTICE](NOTICE) for full legal terms.

| Version | Status | Notes |
| :--- | :--- | :--- |
| **1.1.x** | Current Release (`AS-IS`) | 5-Tab Console, Primary Containment, Extended Lockdown, Forwarding Rules Auditor & Event Triage |
| **1.0.x** | Legacy (`AS-IS`) | Initial release series |

---

## Architecture & Security Model

**Security Incident Response Automator** is an administrative incident containment and forensic triage utility that orchestrates actions across on-premises **Active Directory** and cloud identity providers (**Microsoft Entra ID / Microsoft 365** and **Google Workspace**).

### 1. Direct-to-Provider Network Communication (No Third-Party Middleware)
Because this tool performs hybrid containment and event triage across on-premises and cloud directories, it establishes outbound network connections from the administrator's workstation strictly to your own infrastructure and official vendor endpoints:
- **Active Directory (On-Premises / VPN):** Communicates directly with your local or specified Domain Controller over LDAP/ADSI (TCP/UDP 389/636), Active Directory Web Services (TCP 9389 when RSAT is used), and Windows Event Log RPC when querying Domain Controller security events.
- **Microsoft Graph / Entra ID (HTTPS):** Communicates with `https://login.microsoftonline.com` and `https://graph.microsoft.com` via the official `Microsoft.Graph.Authentication` and `Microsoft.Graph.Users.Actions` PowerShell modules. During initial setup, `Setup-MicrosoftGraph.bat` connects to the official PowerShell Gallery (`https://www.powershellgallery.com`) to install the modules.
- **Google Workspace / GAM7 (HTTPS):** Communicates with `https://accounts.google.com` and `https://*.googleapis.com` via `gam.exe`. During initial setup, `Setup-GoogleWorkspace-GAM.bat` downloads the official GAM7 release from `https://github.com/GAM-team/GAM/releases` and verifies its SHA-256 checksum.
- **Zero Third-Party Telemetry or Cloud Relay:** No incident logs, credentials, or user attributes are ever transmitted to any third-party server or analytics service. All compliance audit logs are stored locally on the administrator's workstation at `C:\ProgramData\IncidentResponse-Automator\AuditLog.csv`.

### 2. Credential Storage, Profile Isolation & Scopes
- **Active Directory Credentials, DPAPI Vault, Global Master Passphrase, Memory Zeroing & Anti-Lockout Safeguards:** Uses integrated Windows logon authentication (Kerberos) on domain-joined workstations by default. When authenticating with alternate Domain Admin credentials or connecting from a workgroup PC via Tab 1 (**Switch AD Account / Domain**, **Manage / AD...**, or **Configure Saved AD Creds...**), credentials can either stay ephemeral in volatile memory (`PSCredential`) or be persisted per Domain Profile (`%LOCALAPPDATA%\IncidentResponse-Automator\Profiles\<id>\ad_cred.dpapi.json`) encrypted exclusively to the configured workstation and Windows user SID via **Windows DPAPI (`DataProtectionScope::CurrentUser`)** with per-profile entropy, strict current-user-only NTFS ACLs, and immediate plaintext byte-buffer zeroing (`[Array]::Clear`) after `PSCredential` hydration. An optional **application-wide `Master Passphrase`** (configured via the top-right **`Master Passphrase`** header button and stored in `%LOCALAPPDATA%\IncidentResponse-Automator\MasterVault.json`) protects every saved profile's credentials with PBKDF2 + AES-256-CBC + HMAC-SHA256: when enabled, startup immediately enforces a 2-attempt verification gate before any network probing or sign-in (closing the application cleanly on the second wrong attempt or Cancel), requires verifying the current passphrase to change or run **`Remove Passphrase`** (which keeps saved credentials under DPAPI `CurrentUser` only after an explicit security warning), and offers a break-glass **`Remove Passphrase & All Creds`** recovery path (no passphrase needed if forgotten) that confirms before permanently zeroing/purging all saved AD credentials across every profile back to default. To prevent automated account lockouts during unjoined or multi-network auto-connect, NIC DNS-suffix + zero-credential DNS SRV (`_ldap._tcp.dc._msdcs.<domain>`) + 700ms async TCP `389`/`636` network reachability checks, pre-bind Kerberos `pwdLastSet`/`badPwdCount`/`lockoutTime` inspection, and a **1-Strike Circuit Breaker** automatically purge rotated or rejected credentials (and associated IndexedDB keys in the web companion) before lockouts can occur. Non-secret metadata is stored in `Profiles.json`, `LastDomainConnection.json`, and `ad_cred_health.json`.
- **Microsoft Graph Scopes & Dual-Account Isolation:** Uses delegated permissions managed by the Microsoft Graph SDK under `-ContextScope CurrentUser` with `Set-MgGraphOption -DisableLoginByWAM $true` so elevated admin accounts remain decoupled from the workstation's daily Windows account. Optionally creates a tenant-local Entra App Registration (`IncidentResponse-Automator-MailboxAuditor`) whose secret is encrypted locally using Windows DPAPI (`ConvertFrom-SecureString`) inside `MailboxAuditorApp.json` under strict current-user NTFS ACLs (`Set-StrictUserFileAclSafe`), with intermediate secret buffers cleared immediately after token exchange.
- **Google Workspace OAuth & Profile Isolation:** Uses the local GAM7 configuration (`client_secrets.json`, `oauth2.txt`, and `oauth2service.json`). Single-domain Primary profiles use `%USERPROFILE%\.gam` and `%LOCALAPPDATA%\MicrosoftGraphSetup`; additional **Domain Profiles** isolate `GAMCFGDIR` and `IR_GRAPH_SETUP_DIR` per profile under `%LOCALAPPDATA%\IncidentResponse-Automator\Profiles\<id>`.

### 3. Safeguards Against Accidental Containment, Injection & Updater Integrity
- **Scoped User Lookup, RFC 4515 LDAP Escaping & Multi-Attribute Correlation:** User search requires a minimum of 3 characters and queries targeted LDAP attributes (`anr`, `sAMAccountName`, `userPrincipalName`, `mail`, `proxyAddresses`). Exact-match `sAMAccountName` directory filters escape special LDAP filter metacharacters (`\`, `*`, `(`, `)`, `\0`) via `ConvertTo-LdapFilterValueSafe`.
- **Mandatory Identity Verification Gate:** Both the Primary Containment Deck (`Tab 2`) and the Extended Lockdown & Rule Remediation Deck (`Tab 3`) remain disabled until a target user is selected and the operator explicitly checks the identity confirmation checkbox on Tab 2.
- **Pre-Action Account Link Verification:** Before executing cloud or directory actions, the application verifies that the required integration is linked and authenticated, prompting the operator to check **Tab 1 (`1. Setup`)** if setup is incomplete.
- **Post-Execution Read-Back:** Password resets, AD account enable/disable, AD `accountExpires`/`userWorkstations` lockdown, Entra `accountEnabled` sign-in blocks, and GAM7 user suspensions re-query the target directory/API object to confirm the change took effect.
- **CSV Audit Log & Formula Injection Sanitization:** All fields written to `C:\ProgramData\IncidentResponse-Automator\AuditLog.csv` (and exported CSV reports) strip embedded carriage returns/newlines, escape double quotes, and neutralize spreadsheet formula prefixes (`=`, `+`, `-`, `@`, `\t`) via a leading single quote (`Format-CsvSafeField`).
- **Trusted Updater Downloads & Hyperlink Validation:** GitHub self-update checks validate git ref characters (`^[A-Za-z0-9._/-]+$`, no `..`) and enforce `https://` URLs anchored strictly to `github.com` / `*.githubusercontent.com`, validate downloaded PowerShell AST syntax / `MZ` PE headers before replacement, and require `https://` validation on updater log hyperlinks (`Add_LinkClicked`).

---

## Security Notice & Self-Patching Policy

This repository is published strictly as an unmaintained, static code release. There is no active security team, bug bounty program, or maintenance SLA:

1. **No Guaranteed Vulnerability Response:** The author does not monitor or patch reported security issues.
2. **Do Not Submit Confidential Data:** Never submit private credentials, internal domain names, network IPs, or proprietary logs in public GitHub issues or discussions.
3. **User Responsibility to Patch:** Organizations and operators deploying this software are 100% responsible for reading the code, identifying vulnerabilities, and implementing their own security controls or fixes in their local copies or forks.
