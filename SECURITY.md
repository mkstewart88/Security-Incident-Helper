# Security Policy & Operational Responsibility

## "As-Is" Release & No Maintenance Obligation

**Security Incident Response Automator** is released strictly **"AS IS"** without warranty, support, or maintenance obligations of any kind:

- **No Maintenance or Update Guarantee:** The author is **not responsible for updating or maintaining** this application. There is no SLA, no guaranteed response time, and no obligation to provide patches, updates, or compatibility fixes for future Windows, Active Directory, Microsoft Graph, or GAM7 releases.
- **Mandatory Code Audit Before Execution:** Because this tool executes high-privilege containment operations against Active Directory, Microsoft Entra ID (Microsoft 365), and Google Workspace, **it is 100% the user's sole responsibility to read, audit, and understand the source code (`IncidentResponse-Automator.ps1` and all `.bat`/`.cmd` scripts) before executing it**.
- **Zero Liability:** The author(s) and contributor(s) assume zero liability for any outcomes resulting from the use of this software. Use entirely at your own risk. See [DISCLAIMER.md](DISCLAIMER.md) and [NOTICE](NOTICE) for complete legal terms.

| Version | Status | Scope |
| :--- | :--- | :--- |
| **1.1.x** | Current Release (`AS-IS`) | 5-Tab Console, Multi-Domain Vault, Isolation, Rules Auditor & Event Triage |
| **1.0.x** | Legacy (`AS-IS`) | Initial release series |

---

## Architecture & Security Model

**Security Incident Response Automator** orchestrates containment and forensic triage directly across on-premises **Active Directory** and cloud identity providers (**Microsoft Entra ID** and **Google Workspace**) with no intermediary servers.

### 1. Direct-to-Provider Network Communication
All outbound connections originate directly from the operator's workstation to your own infrastructure and official vendor endpoints:
- **Active Directory (On-Premises / VPN):** Communicates directly with your Domain Controller over LDAP/ADSI (TCP/UDP 389/636), AD Web Services (TCP 9389 when RSAT is used), and Windows Event Log RPC.
- **Microsoft Graph / Entra ID (HTTPS):** Connects to `https://login.microsoftonline.com` and `https://graph.microsoft.com` using the official `Microsoft.Graph` PowerShell modules (installed from `https://www.powershellgallery.com` during initial setup).
- **Google Workspace / GAM7 (HTTPS):** Connects to `https://accounts.google.com` and `https://*.googleapis.com` via `gam.exe` (downloaded from `https://github.com/GAM-team/GAM/releases` with SHA-256 checksum verification during setup).
- **Zero Third-Party Telemetry:** No logs, credentials, or directory attributes are sent to third-party relays or analytics endpoints. Audit records are written locally to `C:\ProgramData\IncidentResponse-Automator\AuditLog.csv`.

### 2. Credential Storage, Profile Isolation & Anti-Lockout Safeguards
- **Windows DPAPI AD Vault:** Integrated Windows authentication (Kerberos) is used by default on domain-joined systems. Saved alternate Domain Admin credentials are stored per profile (`%LOCALAPPDATA%\IncidentResponse-Automator\Profiles\<id>\ad_cred.dpapi.json`), encrypted exclusively to the workstation and Windows user SID via **Windows DPAPI (`DataProtectionScope::CurrentUser`)** with per-profile entropy, strict current-user NTFS ACLs, and immediate memory scrubbing (`[Array]::Clear`) after `PSCredential` hydration.
- **Optional Global Master Passphrase:** Managed via the top-right **`Master Passphrase`** header button (`MasterVault.dpapi.json`), wrapping saved profile vaults with PBKDF2 + AES-256-CBC + HMAC-SHA256. When enabled, startup enforces a 2-attempt verification gate before any network probing or login. Emergency break-glass (**`Remove Passphrase & All Creds`**) requires a two-step confirmation before wiping the Master Passphrase, Domain Profiles, AD vaults, Graph caches, and GAM7 credentials (preserving `gam.exe`).
- **Anti-Lockout Safeguards:** Non-blocking NIC DNS-suffix + DNS SRV + async TCP `389`/`636` reachability checks verify domain availability before authentication. On joined domains, pre-bind Kerberos checks inspect `pwdLastSet`, `badPwdCount`, and `lockoutTime` before submitting stored passwords; on cross-domain binds, a **1-Strike Circuit Breaker** purges any rejected secret immediately to prevent lockout loops. Non-secret metadata is kept in `Profiles.json`, `LastDomainConnection.json`, and `ad_cred_health.json`.
- **Microsoft Graph Dual-Account Isolation:** Uses delegated permissions (`-ContextScope CurrentUser`) with `Set-MgGraphOption -DisableLoginByWAM $true` so elevated admin logins remain separated from the workstation's daily Windows account. Optional tenant Mailbox Auditor app secrets (`MailboxAuditorApp.json`) are encrypted via DPAPI under current-user NTFS ACLs, with token buffers cleared immediately after exchange.
- **Google Workspace Isolation:** Default/Primary profiles use `%USERPROFILE%\.gam` and `%LOCALAPPDATA%\MicrosoftGraphSetup`; additional Domain Profiles isolate `GAMCFGDIR` and `IR_GRAPH_SETUP_DIR` per profile under `%LOCALAPPDATA%\IncidentResponse-Automator\Profiles\<id>`.

### 3. Safeguards Against Accidental Containment, Injection & Updater Tampering
- **Scoped Lookup & RFC 4515 Escaping:** Directory searches require at least 3 characters; exact-match `sAMAccountName` LDAP filters escape special characters (`\`, `*`, `(`, `)`, `\0`) via `ConvertTo-LdapFilterValueSafe`.
- **Mandatory Verification Interlock:** Containment and isolation controls on Tabs 2 and 3 remain disabled until an operator selects a user and checks the Tab 2 confirmation box.
- **Post-Execution Read-Back:** Password resets, AD disable/enable toggles, `accountExpires` / `userWorkstations` locks, Entra sign-in blocks, and Google suspensions re-query the directory/API to confirm state convergence.
- **CSV Formula Injection Neutralization:** Audit logs and CSV exports strip line breaks, escape quotes, and neutralize spreadsheet formula prefixes (`=`, `+`, `-`, `@`, `\t`) via `Format-CsvSafeField`.
- **Trusted Self-Updater Validation:** Update checks validate git reference characters, restrict downloads strictly to `https://github.com` / `https://*.githubusercontent.com`, validate PowerShell AST syntax and `MZ` PE headers before swapping files, and require `https://` validation on clickable updater log links.

---

## Security Notice & Self-Patching Policy

This repository is published as a static code release with no active security team, bug bounty program, or maintenance SLA:

1. **No Guaranteed Vulnerability Response:** Reported issues may not be monitored or patched.
2. **Never Share Confidential Data:** Do not post credentials, private domain names, internal IPs, or proprietary logs in public GitHub issues or discussions.
3. **Operator Patch Ownership:** Organizations deploying this utility are responsible for auditing the code and applying any required fixes in their own local copies or forks.
