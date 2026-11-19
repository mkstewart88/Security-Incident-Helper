================================================================================
SECURITY INCIDENT RESPONSE AUTOMATOR - OPERATOR USER GUIDE (v1.1.69)
================================================================================

OVERVIEW:
A domain-agnostic incident containment console and forensic security triage
utility for hybrid enterprise environments spanning Active Directory Domain
Services (AD DS), Microsoft Entra ID (Microsoft 365), and Google Workspace.

Engineered for Cybersecurity Analysts, System Administrators, and Incident
Responders to isolate compromised accounts, revoke active authentication
sessions, neutralize malicious mailbox forwarding rules, and triage multi-source
security events from a unified native Windows interface.

================================================================================
SYSTEM REQUIREMENTS:
================================================================================
- Operating System: Windows 10 (1809+), Windows 11, Windows Server 2016+
- PowerShell Runtime: Windows PowerShell 5.1 (Enforces Single-Threaded Apartment)
- .NET Framework: .NET Framework 4.8 or 4.8.1
- Network Access: LDAP TCP 389/636 to Domain Controller, HTTPS 443 outbound
- Microsoft 365 SDK: Microsoft.Graph.Authentication & Microsoft.Graph.Users
- Google Workspace CLI: Google Apps Manager 7 (GAM7 v7.50+)

================================================================================
DEPLOYMENT & LAUNCH OPTIONS:
================================================================================

OPTION 1: BATCH LAUNCHER (RECOMMENDED)
  Double-click "Launch-IncidentAutomator.bat" in Windows Explorer or execute from
  an elevated command prompt. Unblocks files and enforces -STA mode.

OPTION 2: DIRECT POWERSHELL EXECUTION
  powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\IncidentResponse-Automator.ps1

OPTION 3: COMPILE TO STANDALONE BINARY (.EXE)
  Double-click "Compile-To-EXE.cmd" to validate syntax and compile the script
  and embedded setup payloads into a standalone portable "IncidentResponse.exe".

================================================================================
OPERATOR USER GUIDE:
================================================================================

STEP 1: PRE-FLIGHT VERIFICATION & INTEGRATION SETUP (TAB 1)
  On first launch, if no Primary Domain Profile is configured yet, a startup
  prompt lets you designate your environment as your Primary (Home) Domain
  Profile or configure a temporary assisting profile while keeping your Primary
  slot reserved.

  1. Open Tab 1 ("1. Setup").
  2. Use the top Profile bar ("Switch Profile", "+ New Profile", "Manage / AD...")
     to switch between or create isolated Domain Profiles.
  3. Review the connection badges for Active Directory, Microsoft Graph, and
     Google Workspace (GAM7).
  4. Use the three service columns to test, set up, or switch accounts:
     - Active Directory: "Test Active Directory" | "Install RSAT (Optional)" |
       "Switch AD Account / Domain"
     - Microsoft Graph:  "Test Microsoft Graph"  | "1. Setup Microsoft Graph" |
       "Switch Graph Account"
     - Google GAM7:      "Test Google GAM7"      | "2. Setup Google GAM7" |
       "Switch GAM Account"

STEP 2: DOMAIN PROFILES, SAVED CREDENTIALS & MASTER PASSPHRASE
  1. Click "Manage / AD..." (or "Switch AD Account / Domain") to open the
     profile and AD switcher.
  2. Select an existing profile or use "+ New", "Set Primary", "Rename", or
     "Delete" to manage isolated environments.
  3. Click "Auto-Detect Domain" to discover the workstation domain or active
     network DNS suffix, or enter a target domain FQDN or DC hostname/IP.
  4. Check "Use alternate Domain Admin credentials" when authenticating from a
     non-domain workstation or elevated admin account. Optionally save
     credentials in the encrypted Windows DPAPI vault for automatic startup
     connection.
  5. Click "Connect & Switch Profile" to verify AD connectivity and switch
     profiles, or "Switch Cloud Only (Skip AD)" for off-VPN cloud triage.
  6. Use Tab 1's "Credential Health & Encrypted AD Vault" panel to run
     "Validate Credential Health", "Detect Network & Auto-Connect",
     "Configure Saved AD Creds...", or "Purge Saved Creds".
  7. Optional Master Passphrase: Click "Master Passphrase" in the top-right
     header to set an application-wide passphrase protecting all saved Domain
     Profiles. When enabled, the console prompts for your passphrase on launch
     before connecting. From the Master Passphrase menu you can:
     - Change Passphrase: Update the active passphrase after confirming the
       current one.
     - Remove Passphrase: Disable the startup lock after confirming your
       current passphrase while keeping saved DPAPI domain credentials intact.
     - Remove Passphrase & All Creds: Emergency break-glass reset (requires no
       passphrase if forgotten). Displays a red warning explaining everything
       that will be wiped (Master Passphrase, Domain Profiles, AD credentials,
       Microsoft Graph sessions, and Google GAM7 profiles) followed by a final
       "Are you sure?" confirmation before clearing stored credentials.
  8. Updates & Changelog: The top-right header badge checks GitHub
     automatically on launch, showing "v<version>" when current or
     "Update Available" when a newer release exists. Click it anytime to view
     the changelog, check for updates, or update and restart.

STEP 3: SEARCHING & VERIFYING COMPROMISED IDENTITIES (TAB 2)
  1. Open Tab 2 ("2. Containment").
  2. Enter the user's name, username, or email address (minimum 3 characters)
     and press Enter or click "Find Users".
  3. Select the target account from the results list to populate the four live
     status cards (Password Age, 365 / Entra ID Status, Google Workspace Status,
     and AD Account Status).
  4. Verify user details and check the safety lock box:
     [X] I confirm I have selected the correct user (Unlocks Actions Deck)

STEP 4: EXECUTING PRIMARY CONTAINMENT ACTIONS (TAB 2)
  - 1. Reset Password: Opens the password reset dialog with custom entry or
    random 16-character generation and optional next-logon password change.
  - 2. Revoke 365 Sessions: Invalidates active Microsoft 365 / Entra ID refresh
    tokens across Outlook, Teams, OneDrive, and mobile clients.
  - 3. Revoke Google Sessions: Terminates active Google Workspace browser
    cookies and mobile app sessions.
  - 4. Disable Account: Disables the Active Directory account with immediate
    read-back verification.
  - Run Full Playbook (1-Click): Executes all four containment steps
    sequentially with verification between each stage.

STEP 5: DEEP ACCOUNT ISOLATION & MAILBOX RULES AUDITOR (TAB 3)
  1. Open Tab 3 ("3. Deep Isolation").
  2. "Block Entra Sign-In (Instant)": Disables cloud sign-in directly in Entra
     ID without waiting for directory synchronization.
  3. "Suspend Google User (GAM7)": Suspends the user account in Google Admin SDK.
  4. Cloud Persistence Eradication (run individually or all together):
     - "Wipe Entra 2FA Methods": Removes non-password Entra MFA methods
       (Authenticator, Phone/SMS, FIDO2, Software OATH, Temporary Access Pass,
       and Email).
     - "Wipe Entra OAuth Grants": Revokes Entra refresh tokens and deletes
       third-party OAuth permission grants.
     - "Wipe Google 2FA Methods": Turns off Google 2-Step Verification (2FA)
       enrollments, security keys, and backup codes.
     - "Wipe Google OAuth Grants": Revokes third-party Google OAuth app grants,
       Application-Specific Passwords, and backup codes.
     - "Wipe All (Entra + GAM7)": Executes all four cloud wipes sequentially.
  5. "Expire AD Account & Restrict Workstations": Expires the AD account
     timestamp to invalidate active Kerberos TGTs (0x12) and locks
     userWorkstations to INCIDENT-LOCK.
  6. Mailbox Rules Auditor: Click "Audit M365 & Gmail Rules" to scan Microsoft
     365 inbox rules and Gmail forwarding/filters. Suspicious external forwards
     and stealth-delete rules are flagged for single-rule ("Disable Rule",
     "Delete Rule") or bulk ("Disable Suspicious") remediation.

STEP 6: TRIAGING MULTI-SOURCE SECURITY EVENTS (TAB 4)
  1. Open Tab 4 ("4. Event Triage").
  2. Click "Pull Events (AD + Entra + Google)" to query Domain Controller
     security logs, Entra ID sign-in events, and Google login reports.
  3. Filter by source or severity dropdowns, or type in the "Filter:" search
     box to match across both the results table and the selected event details
     with live text highlighting.
  4. Select any event to read its plain-English explanation, recommended
     response decision, and raw telemetry.
  5. Click "View Event Guide" to browse and search the built-in security code
     dictionary offline, then click "Show Pulled Events" to return to pulled
     query results.

STEP 7: COMPLIANCE AUDIT TRAIL (TAB 5)
  1. Open Tab 5 ("5. Audit Trail").
  2. All containment operations are logged locally to:
     C:\ProgramData\IncidentResponse-Automator\AuditLog.csv
  3. Search or filter logs by status (SUCCESS, PARTIAL, FAILED).
  4. Double-click or click "Inspect Selected Entry" to view complete details.
  5. Click "Export to CSV..." to generate a sanitized compliance report.

================================================================================
COMPANION DOCUMENTATION:
================================================================================
- QUICK_START.md / QUICK_START.txt : Fast launch & initial setup checklist
- README.md / README.txt           : Operator user guide & visual walkthrough
- README-extended.md / .txt        : Technical architecture & API reference
- CHANGELOG.md                     : Release history and version changes
- SECURITY.md                      : Security model, network & as-is policy
- DISCLAIMER.md / NOTICE / LICENSE : Legal terms, Apache 2.0 & liability waiver

================================================================================
PERMISSIVE COMMERCIAL USE, FORKING & SHOUT-OUT POLICY:
================================================================================
- OPEN USE & FORKING: Anyone is free to use, copy, modify, merge, publish,
  distribute, sublicense, and/or fork this application under the Apache License 2.0.
- COMMERCIAL / FOR-PROFIT USE: Anyone is permitted to sell, commercialize, or
  incorporate any part of this software into a paid product or service, subject
  only to leaving a quick public shout-out or repository attribution on this project's
  official GitHub repository. You do NOT need to wait for approval before proceeding.

================================================================================
LEGAL DISCLAIMER & NO MAINTENANCE OBLIGATION:
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
