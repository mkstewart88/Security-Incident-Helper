# Security Incident Response Automator

[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20%7C%20Server-0078D6?logo=windows)](https://microsoft.com)
[![PowerShell: 5.1+](https://img.shields.io/badge/PowerShell-5.1%20%7C%207.x-5391FE?logo=powershell)](https://learn.microsoft.com/powershell/)
[![Framework: .NET 4.8+](https://img.shields.io/badge/.NET%20Framework-4.8%2B-512BD4?logo=dotnet)](https://dotnet.microsoft.com)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Version: 1.1.5](https://img.shields.io/badge/Version-1.1.5-emerald.svg)](CHANGELOG.md)

A high-performance, domain-agnostic administrative incident containment console and security forensics triage utility for hybrid enterprise environments spanning **Active Directory Domain Services (AD DS)**, **Microsoft Entra ID (Microsoft 365)**, and **Google Workspace**.

Engineered for Cybersecurity Analysts, System Administrators, and Incident Responders to rapidly isolate compromised user accounts, revoke active authentication sessions, neutralize malicious mailbox forwarding rules, and triage multi-source security events from a unified, native Windows interface.

---

## Visual Tour & Interface Overview

The console is organized into five structured tabs corresponding to standard incident response containment stages:

### Tab 1: Integrations & Pre-Flight Setup
Live diagnostic status of all directory and cloud services, with automated one-click installation and verification scripts.

<table>
  <tr>
    <td align="center"><b>Dark Mode</b></td>
    <td align="center"><b>Light Mode</b></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/tab1-integrations-setup.png" alt="Tab 1 Dark Mode" width="480"/></td>
    <td><img src="docs/screenshots/tab1-integrations-setup-light.png" alt="Tab 1 Light Mode" width="480"/></td>
  </tr>
</table>

### Tab 2: Incident Containment Deck
Multi-attribute Active Directory user search, live multi-provider session telemetry, safety lock verification gate, and primary containment actions.

<table>
  <tr>
    <td align="center"><b>Dark Mode</b></td>
    <td align="center"><b>Light Mode</b></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/tab2-incident-containment.png" alt="Tab 2 Dark Mode" width="480"/></td>
    <td><img src="docs/screenshots/tab2-incident-containment-light.png" alt="Tab 2 Light Mode" width="480"/></td>
  </tr>
</table>

### Tab 3: Deep Isolation & Mailbox Forwarding Rules Auditor
Instant cloud sign-in blocking, Google Workspace account suspension, rogue MFA/OAuth grant eviction, Kerberos KDC hard-locking, and mailbox rule exfiltration scanner.

<table>
  <tr>
    <td align="center"><b>Dark Mode</b></td>
    <td align="center"><b>Light Mode</b></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/tab3-deep-isolation-mailbox-rules.png" alt="Tab 3 Dark Mode" width="480"/></td>
    <td><img src="docs/screenshots/tab3-deep-isolation-mailbox-rules-light.png" alt="Tab 3 Light Mode" width="480"/></td>
  </tr>
</table>

### Tab 4: Multi-Source Security Event Triage
Live telemetry ingestion across Domain Controllers, Entra ID sign-in logs, and Google audit records with automated plain-English translation and response recommendations.

<table>
  <tr>
    <td align="center"><b>Dark Mode</b></td>
    <td align="center"><b>Light Mode</b></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/tab4-security-event-triage.png" alt="Tab 4 Dark Mode" width="480"/></td>
    <td><img src="docs/screenshots/tab4-security-event-triage-light.png" alt="Tab 4 Light Mode" width="480"/></td>
  </tr>
</table>

### Tab 5: Forensic Compliance Audit Trail
Filterable, searchable audit logging with CSV field sanitization, recording every administrative operation locally for compliance, forensic verification, and insurance reporting.

<table>
  <tr>
    <td align="center"><b>Dark Mode</b></td>
    <td align="center"><b>Light Mode</b></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/tab5-forensic-audit-trail.png" alt="Tab 5 Dark Mode" width="480"/></td>
    <td><img src="docs/screenshots/tab5-forensic-audit-trail-light.png" alt="Tab 5 Light Mode" width="480"/></td>
  </tr>
</table>

---

## Core Capabilities at a Glance

* **Single-Click Universal Containment:** Reset Active Directory password (with forced change at next logon), invalidate Microsoft 365 OAuth refresh tokens, terminate Google Workspace web/mobile sessions, and disable directory accounts in under 10 seconds.
* **Dual Active Directory Engine:** Operates seamlessly via native .NET `System.DirectoryServices` (LDAP/ADSI over TCP/389 or LDAPS over TCP/636) without requiring Remote Server Administration Tools (RSAT), while automatically leveraging the RSAT `ActiveDirectory` module if present.
* **Multi-Domain Auto-Detection:** Automatically discovers local domain membership, forest roots, and DNS suffix lists, allowing technicians to switch seamlessly between client environments with one click.
* **Deep Account Isolation:**
  * Immediately disables Entra ID sign-in via Microsoft Graph REST API, closing the 30-minute Entra Connect synchronization gap.
  * Suspends Google Workspace accounts via GAM7 CLI with multi-pass convergence verification.
  * Evicts persistent cloud persistence mechanisms: deletes third-party OAuth app grants, wipes SMS/TOTP/FIDO authentication methods, and clears Google app passwords and 2-step verification backup codes.
  * Forces immediate Kerberos KDC ticket invalidation by expiring the AD account timestamp (`0x12: KDC_ERR_CLIENT_REVOKED`) and restricts allowed workstations to sentinel values.
* **Business Email Compromise (BEC) Remediation:** Audits Microsoft 365 inbox message rules and Gmail routing filters, flagging external forwarding targets, stealth deletion, and hide-hole routing with one-click single or bulk remediation.
* **Plain-English Event Decoder:** Pulls real-time security events across Windows Domain Controllers, Entra ID, and Google Workspace, translating obscure error codes into human-readable triage intelligence with recommended incident response steps.
* **Theme Customization:** Instant one-click toggle between High-Contrast Dark Mode and Professional Light Mode across all windows, headers, text controls, and data grids.

---

## Operating System & Prerequisite Requirements

| Component | Minimum Requirement | Recommended |
| :--- | :--- | :--- |
| **Operating System** | Windows 10 (1809+), Windows 11, Windows Server 2016+ | Windows 11 Enterprise / Windows Server 2022 |
| **PowerShell Runtime** | Windows PowerShell 5.1 (Built into Windows) | Windows PowerShell 5.1 (Single-Threaded Apartment `-STA`) |
| **.NET Framework** | .NET Framework 4.8 | .NET Framework 4.8.1 |
| **Active Directory** | LDAP network access to Domain Controller (TCP 389/636) | Domain-joined workstation or Domain Admin credentials |
| **Microsoft 365** | Microsoft Graph PowerShell SDK (`Authentication`, `Users`) | Installed via 1-Click launcher on Tab 1 |
| **Google Workspace** | Google Apps Manager 7 (GAM7 CLI v7.50+) | Installed via 1-Click launcher on Tab 1 |

---

## Deployment & Execution Options

The project is distributed as self-contained source files that can be executed directly or compiled into a standalone Windows binary:

### Option 1: Fast Launch via Batch Wrapper (Recommended)
Double-click `Launch-IncidentAutomator.bat` in Windows Explorer or run from an elevated command prompt:
```cmd
Launch-IncidentAutomator.bat
```
*Automatically unblocks files, enforces Single-Threaded Apartment (`-STA`) execution, and launches the Windows Form interface.*

### Option 2: Direct Execution via PowerShell
Execute directly using Windows PowerShell 5.1:
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\IncidentResponse-Automator.ps1
```

### Option 3: Compile to Standalone Binary (`IncidentResponse.exe`)
To package the entire console and its embedded setup scripts into a single standalone portable executable:
1. Double-click `Compile-To-EXE.cmd`.
2. The script validates PowerShell AST syntax, checks or downloads the `PS2EXE` compilation tool, and generates an optimized `IncidentResponse.exe`.
3. The resulting binary runs natively on any Windows workstation without requiring PowerShell script files or console windows.

---

## Operator Step-by-Step User Guide

### 1. Pre-Flight Verification & Integration Setup (Tab 1)
Upon launch, the application runs automated pre-flight probes:
1. Navigate to **Tab 1 (`1. Setup`)**.
2. Review the connection indicators for **Active Directory**, **Microsoft Graph**, and **Google Workspace (GAM7)**.
3. If an integration displays unverified status:
   * Click **1. Setup Microsoft Graph** to launch the interactive module installer and sign-in flow.
   * Click **2. Setup Google GAM7** to install GAM7 and authorize Google Cloud project credentials.
   * Click **3. Install RSAT (Optional)** if you wish to add native Active Directory cmdlets.
4. Click **Test Active Directory**, **Test Microsoft Graph**, or **Test Google GAM7** at any time to re-verify live connectivity.

### 2. Switching Target Domains or Domain Controllers
If operating from a non-domain-joined laptop or managing multiple school districts/tenants:
1. Click the **Switch Domain / DC** button in the upper-right corner.
2. Click **[Auto-Detect Domain]** to automatically populate the primary joined domain, or type the target Domain FQDN (e.g. `contoso.com`).
3. Optionally specify an explicit Domain Controller IP or hostname.
4. Enter administrative credentials (`DOMAIN\Administrator` and Password) if authenticating from a workgroup workstation.
5. Click **Verify & Connect**. The console verifies LDAP RootDSE connectivity and caches the domain profile.

### 3. Locating and Verifying a Compromised Identity (Tab 2)
1. Navigate to **Tab 2 (`2. Containment`)**.
2. Enter the user's name, username, or email into the search bar (minimum 3 characters, e.g. `alex.morgan@contoso.com` or `am8001`) and press **Enter** or click **Find Users**.
3. Select the correct user from the results list.
4. The console queries Active Directory, Entra ID, and Google Workspace, populating the 4 live security status cards:
   * **PASSWORD AGE:** Number of days since password last set.
   * **365 / ENTRA ID STATUS:** Live token validity state.
   * **GOOGLE WORKSPACE STATUS:** Live Google session state.
   * **AD ACCOUNT STATUS:** Active Directory directory lock and enabled status.
5. Review the user details and check the mandatory confirmation box:
   `[X] I confirm I have selected the correct user (Unlocks Actions Deck)`.

### 4. Executing Containment Actions (Tab 2)
* **1. Reset Password:** Opens an inline reset dialog. Enter a custom password or click **Generate** for a cryptographically random 16-character password. Automatically enforces `pwdLastSet = 0` so the user must select a private password at next logon.
* **2. Revoke 365 Sessions:** Calls Microsoft Graph `/v1.0/users/{id}/revokeSignInSessions`, invalidating all active refresh tokens across Outlook, Teams, OneDrive, and mobile apps.
* **3. Revoke Google Sessions:** Executes `gam user <id> signout`, terminating active web browser cookies and mobile app sessions.
* **4. Disable Account:** Sets the `userAccountControl` disabled flag in Active Directory with immediate LDAP read-back verification.
* **Run Full Playbook (1-Click):** Sequentially executes all four containment steps with full verification in under 10 seconds.

### 5. Applying Deep Account Isolation (Tab 3)
For high-severity or suspected Business Email Compromise (BEC) incidents:
1. Navigate to **Tab 3 (`3. Deep Isolation`)**.
2. **Block Entra Sign-In (Instant):** Directly writes `accountEnabled = false` to Microsoft Graph, blocking cloud access immediately without waiting for directory sync.
3. **Suspend Google User:** Freezes the user account in Google Admin SDK.
4. **Wipe Cloud MFA Methods & Rogue Grants:** Purges non-password MFA registrations (authenticator apps, phone numbers, FIDO keys), revokes third-party OAuth app authorizations, and clears Google app passwords/backup codes.
5. **Expire AD Account & Restrict Workstations:** Sets `accountExpires` to the past (forcing Kerberos KDC error `0x12`) and locks `userWorkstations` to `INCIDENT-LOCK`.

### 6. Auditing and Remediating Mailbox Rules (Tab 3)
1. On **Tab 3**, click **Audit M365 & Gmail Rules**.
2. The auditor inspects all inbox message rules and forwarding configurations.
3. Rules flagging external forwarding, auto-redirection, or stealth auto-deletion are highlighted as `HIGH RISK` or `SUSPICIOUS`.
4. Select a rule to inspect its conditions, then click **Disable Rule**, **Delete Rule**, or click **Disable Suspicious** to neutralize all rogue rules in one action.

### 7. Triaging Security Events (Tab 4)
1. Navigate to **Tab 4 (`4. Event Triage`)**.
2. Click **Pull Events (AD + Entra + Google)** to query Domain Controller security logs, Entra sign-in audit logs, and Google login reports.
3. Filter results by source or severity using the dropdown selectors.
4. Select any event to read its plain-English explanation and recommended incident response decision.
5. Click **View Event Code Guide** to browse the complete built-in dictionary of Windows, Entra, and Google security codes. Click **Show Pulled Events** to return to your query results without re-pulling.

### 8. Reviewing the Compliance Audit Trail (Tab 5)
1. Navigate to **Tab 5 (`5. Audit Trail`)**.
2. All administrative actions executed during the session are logged to `C:\ProgramData\IncidentResponse-Automator\AuditLog.csv`.
3. Filter logs by typing in the search box or selecting a status filter (`SUCCESS`, `PARTIAL`, `FAILED`).
4. Double-click or select an entry and click **Inspect Selected Entry** to view complete timestamp, operator, and API verification details.
5. Click **Export to CSV...** to generate an executive report for cybersecurity insurance or compliance compliance documentation.

---

## Technical Documentation

For a comprehensive technical breakdown detailing internal LDAP queries, RFC 4511 protocol calls, Microsoft Graph REST endpoints, GAM7 commands, security event IDs, and DPI scaling engine internals, please refer to the extended documentation:

* **Quick Start Guide:** [`QUICK_START.md`](QUICK_START.md)
* **Markdown Edition:** [`README-extended.md`](README-extended.md)
* **Plain-Text Edition:** [`README-extended.txt`](README-extended.txt)

---

## Permissive Commercial Use, Forking & Shout-Out Policy

* **Open Use & Forking:** Anyone is free to use, copy, modify, merge, publish, distribute, sublicense, and/or fork this application and its source code under the terms of the [Apache License, Version 2.0](LICENSE).
* **Commercial & For-Profit Use:** Anyone is permitted to sell, commercialize, or incorporate any part of this software into a paid or commercial product or service, subject only to leaving a quick public shout-out or repository attribution on this project's official GitHub repository (e.g. via GitHub Issues or Discussions). **You do NOT need to wait for approval or a response before proceeding.**

---

## Legal Disclaimer & No Maintenance Obligation

* **Use Entirely at Your Own Risk:** This software is provided strictly on an **"AS IS"** and **"AS AVAILABLE"** basis without warranties or conditions of any kind.
* **Mandatory User Code Review:** Administrative and incident containment tools operate with high privileges across enterprise identity providers. **It is 100% the user's sole responsibility to read, inspect, audit, and understand the source code before executing it.**
* **Zero Liability:** The author(s), contributor(s), and maintainer(s) shall have **absolutely zero responsibility or liability** for any damages, losses, system downtime, directory corruption, data loss, or consequences whatsoever resulting from or relating to the execution, use, or modification of this software.
* **No Maintenance Obligation:** The author is under **zero obligation** to update, patch, maintain, or support this application. This software is released on an as-is basis with no SLA.

For complete legal terms and disclaimers, please read [DISCLAIMER.md](DISCLAIMER.md), [NOTICE](NOTICE), and [LICENSE](LICENSE).
