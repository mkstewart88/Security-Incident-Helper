================================================================================
SECURITY INCIDENT RESPONSE AUTOMATOR - OPERATOR USER GUIDE (v1.1.57)
================================================================================

OVERVIEW:
A high-performance, domain-agnostic administrative incident containment console
and security forensics triage utility for hybrid enterprise environments
spanning Active Directory Domain Services (AD DS), Microsoft Entra ID
(Microsoft 365), and Google Workspace.

Built for Cybersecurity Analysts, System Administrators, and Incident Responders
to rapidly isolate compromised user accounts, revoke active authentication
sessions, neutralize malicious mailbox forwarding rules, and triage multi-source
security events from a unified, native Windows interface.

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
  an elevated command prompt. Automatically unblocks files and enforces -STA mode.

OPTION 2: DIRECT POWERSHELL EXECUTION
  Execute directly via Windows PowerShell 5.1:
  powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\IncidentResponse-Automator.ps1

OPTION 3: COMPILE TO STANDALONE BINARY (.EXE)
  Double-click "Compile-To-EXE.cmd" to bundle the entire script and its embedded
  batch payloads into a standalone, portable "IncidentResponse.exe" binary via PS2EXE.

================================================================================
OPERATOR STEP-BY-STEP HOW-TO GUIDE:
================================================================================

STEP 1: PRE-FLIGHT VERIFICATION & INTEGRATION SETUP (TAB 1)
  0. First-Launch Primary Profile Prompt: If no Primary Domain Profile is
     configured yet, the app asks whether this environment is your Primary
     (Home) Domain Profile or if you are temporarily assisting another domain
     (keeping the clean Primary slot reserved until you return home).
  1. Open Tab 1 ("1. Setup").
  2. Use the top Profile bar ("Switch Profile", "+ New Profile", "Manage / AD...")
     to switch or create isolated Domain Profiles when supporting multiple domains.
  3. Inspect the live connectivity indicators for Active Directory, Microsoft
     Graph, and Google Workspace (GAM7).
  4. Integration actions are organized into 3 vertical service columns:
     - Column 1 (Active Directory): "Test Active Directory" (Row 1) |
       "Install RSAT (Optional)" (Row 2) | "Switch AD Account / Domain" (Row 3)
     - Column 2 (Microsoft Graph): "Test Microsoft Graph" (Row 1) |
       "1. Setup Microsoft Graph" (Row 2) | "Switch Graph Account" (Row 3)
     - Column 3 (Google GAM7): "Test Google GAM7" (Row 1) |
       "2. Setup Google GAM7" (Row 2) | "Switch GAM Account" (Row 3)

STEP 2: DOMAIN PROFILES & SWITCHING TARGET DOMAINS
  1. On Tab 1 ("1. Setup"), click "Manage / AD..." in the top Profile bar (or
     "Switch AD Account / Domain" in Row 1).
  2. Select an existing Domain Profile or click "+ New" to create an isolated
     profile (AD, Graph, and GAM7 settings), "Set Primary", "Rename", or "Delete".
  3. Click "Auto-Detect Domain" to query the local machine's primary domain, or
     manually enter the target domain FQDN or Domain Controller IP/hostname.
  4. Check "Use alternate Domain Admin credentials" if authenticating with
     another AD account or from a non-domain workstation (held in memory only).
  5. Click "Connect & Switch Profile" to run an LDAP RootDSE handshake and switch,
     or "Switch Cloud Only (Skip AD)" for off-VPN Graph/GAM triage.
  6. Click "Check for Updates" in the header to check GitHub releases, "View
     Changelog", or run "Update & Restart" (auto-recompiles .exe when needed).

STEP 3: SEARCHING & VERIFYING COMPROMISED IDENTITIES (TAB 2)
  1. Open Tab 2 ("2. Containment").
  2. Enter the user's name, username, or email address (minimum 3 characters, e.g.
     alex.morgan@contoso.com or am8001) and press Enter or click "Find Users".
  3. Select the target user from the results list.
  4. The console queries Active Directory, Entra ID, and Google Workspace,
     populating the 4 live security status cards:
     - PASSWORD AGE: Days since password last set.
     - 365 / ENTRA ID STATUS: Live token validity state.
     - GOOGLE WORKSPACE STATUS: Live Google session state.
     - AD ACCOUNT STATUS: Active Directory account state (Active/Disabled/Locked).
  5. Verify user details and check the safety lock box:
     [X] I confirm I have selected the correct user (Unlocks Actions Deck)

STEP 4: EXECUTING PRIMARY CONTAINMENT ACTIONS (TAB 2)
  - 1. Reset Password: Opens an inline password reset dialog. Type a custom
    password or click Generate for a cryptographically secure password. Automatically
    enforces pwdLastSet = 0 so the user must set a new password at next logon.
  - 2. Revoke 365 Sessions: Calls Microsoft Graph /revokeSignInSessions,
    invalidating all active refresh tokens across Outlook, Teams, and mobile apps.
  - 3. Revoke Google Sessions: Runs "gam user <id> signout", terminating active
    web browser cookies and mobile app sessions.
  - 4. Disable Account: Sets the account disabled flag in Active Directory with
    immediate LDAP read-back verification.
  - Run Full Playbook (1-Click): Sequentially executes and verifies all four
    containment steps in under 10 seconds.

STEP 5: APPLYING DEEP ACCOUNT ISOLATION (TAB 3)
  1. Open Tab 3 ("3. Deep Isolation").
  2. "Block Entra Sign-In (Instant)": Directly patches accountEnabled = false on
     Microsoft Graph, blocking cloud access immediately without waiting for directory sync.
  3. "Suspend Google User": Freezes the user account in Google Admin SDK.
  4. Granular Cloud Persistence Wipe Buttons (5 Symmetric Red Controls):
     - "Wipe Entra 2FA Methods": Removes non-password Entra 2FA methods
       (Authenticator, Phone/SMS, FIDO2, Software OATH, Temporary Access Pass, Email).
     - "Wipe Entra OAuth Grants": Revokes Entra refresh tokens & 3rd-party OAuth grants.
     - "Wipe Google 2FA Methods": Runs "gam user <id> turnoff2sv" to turn off
       Google 2-Step Verification (2FA) enrollments, security keys & backup codes.
     - "Wipe Google OAuth Grants": Runs "gam user <id> deprovision" to revoke
       3rd-party Google OAuth app grants, App-Specific Passwords & backup codes.
     - "Wipe All (Entra + GAM7)": Executes all four cloud wipes sequentially.
  5. "Expire AD Account & Restrict Workstations": Sets accountExpires to the past
     (forcing Kerberos KDC error 0x12) and locks userWorkstations to INCIDENT-LOCK.

STEP 6: AUDITING & REMEDIATING MAILBOX RULES (TAB 3)
  1. On Tab 3, click "Audit M365 & Gmail Rules".
  2. The auditor inspects all inbox message rules and forwarding configurations.
  3. Rules flagging external forwarding, auto-redirection, or stealth auto-deletion
     are highlighted as HIGH RISK or SUSPICIOUS.
  4. Select a rule to inspect its conditions, then click "Disable Rule", "Delete Rule",
     or click "Disable Suspicious" to neutralize all rogue rules in one action.

STEP 7: TRIAGING MULTI-SOURCE SECURITY EVENTS (TAB 4)
  1. Open Tab 4 ("4. Event Triage").
  2. Click "Pull Events (AD + Entra + Google)" to query Domain Controller security
     logs, Entra sign-in audit logs, and Google login reports.
  3. Filter results by source or severity using the dropdown selectors.
  4. Select any event to read its plain-English explanation and recommended decision.
  5. Click "View Event Code Guide" to browse the complete built-in dictionary of
     security event codes. Click "Show Pulled Events" to return to your query results.

STEP 8: COMPLIANCE AUDIT TRAIL (TAB 5)
  1. Open Tab 5 ("5. Audit Trail").
  2. All containment operations are logged locally to:
     C:\ProgramData\IncidentResponse-Automator\AuditLog.csv
  3. Filter logs by typing in the search box or selecting a status filter.
  4. Double-click or click "Inspect Selected Entry" to view complete verification details.
  5. Click "Export to CSV..." to generate an incident report for compliance audits.

================================================================================
AVAILABLE COMPANION DOCUMENTATION FILES:
================================================================================
- QUICK_START.md / QUICK_START.txt : Rapid deployment & launch options
- README.md / README.txt           : Complete operator manual & visual walkthrough
- README-extended.md / .txt        : In-depth technical architecture & API reference
- CHANGELOG.md                     : Release history and feature timeline
- DISCLAIMER.md / NOTICE / LICENSE : Legal terms, Apache 2.0 license & liability waiver
- SECURITY.md                      : Security model, network architecture & self-patching policy

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
