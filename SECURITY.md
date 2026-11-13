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
- **Active Directory Credentials:** Uses the current Windows logon session (Kerberos/Integrated authentication) on domain-joined workstations. When authenticating with alternate credentials or connecting from a non-domain workstation via **Switch Domain / Profile**, explicit Domain Admin credentials are held only in memory (`PSCredential`) for the duration of the process and are never written to disk. Non-secret connection and profile metadata (domain FQDN, server/DC, username hint, and isolated profile paths) are stored in `Profiles.json` and `LastDomainConnection.json` under `%LOCALAPPDATA%\IncidentResponse-Automator` (with `%USERPROFILE%\.incident-response` backup).
- **Microsoft Graph Scopes & Dual-Account Isolation:** Uses delegated permissions managed by the Microsoft Graph SDK under `-ContextScope CurrentUser` with `Set-MgGraphOption -DisableLoginByWAM $true` so elevated admin accounts remain decoupled from the workstation's daily Windows account. Optionally creates a tenant-local Entra App Registration (`IncidentResponse-Automator-MailboxAuditor`) whose secret is encrypted locally using Windows DPAPI (`ConvertFrom-SecureString`) inside the active profile's `IR_GRAPH_SETUP_DIR`.
- **Google Workspace OAuth & Profile Isolation:** Uses the local GAM7 configuration (`client_secrets.json`, `oauth2.txt`, and `oauth2service.json`). Single-domain Primary profiles use `%USERPROFILE%\.gam` and `%LOCALAPPDATA%\MicrosoftGraphSetup`; additional **Domain Profiles** isolate `GAMCFGDIR` and `IR_GRAPH_SETUP_DIR` per profile under `%LOCALAPPDATA%\IncidentResponse-Automator\Profiles\<id>`.

### 3. Safeguards Against Accidental Containment & Log Integrity
- **Scoped User Lookup & Multi-Attribute Correlation:** User search requires a minimum of 3 characters and queries targeted LDAP attributes (`anr`, `sAMAccountName`, `userPrincipalName`, `mail`, `proxyAddresses`), correlating routable cloud identities before invoking Microsoft Graph or GAM7.
- **Mandatory Identity Verification Gate:** Both the Primary Containment Deck (`Tab 2`) and the Extended Lockdown & Rule Remediation Deck (`Tab 3`) remain disabled until a target user is selected and the operator explicitly checks the identity confirmation checkbox on Tab 2.
- **Pre-Action Account Link Verification:** Before executing cloud or directory actions, the application verifies that the required integration is linked and authenticated, prompting the operator to check **Tab 1 (`1. Setup`)** if setup is incomplete.
- **Post-Execution Read-Back:** Password resets, AD account enable/disable, AD `accountExpires`/`userWorkstations` lockdown, Entra `accountEnabled` sign-in blocks, and GAM7 user suspensions re-query the target directory/API object to confirm the change took effect.
- **CSV Audit Log Sanitization:** All fields written to `C:\ProgramData\IncidentResponse-Automator\AuditLog.csv` are stripped of embedded carriage returns/newlines and properly quote-escaped to prevent log corruption or CSV injection.

---

## Security Notice & Self-Patching Policy

This repository is published strictly as an unmaintained, static code release. There is no active security team, bug bounty program, or maintenance SLA:

1. **No Guaranteed Vulnerability Response:** The author does not monitor or patch reported security issues.
2. **Do Not Submit Confidential Data:** Never submit private credentials, internal domain names, network IPs, or proprietary logs in public GitHub issues or discussions.
3. **User Responsibility to Patch:** Organizations and operators deploying this software are 100% responsible for reading the code, identifying vulnerabilities, and implementing their own security controls or fixes in their local copies or forks.
