================================================================================
SECURITY INCIDENT RESPONSE AUTOMATOR - EXTENDED TECHNICAL MANUAL (v1.1.5)
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
- [ Light Mode ] / [ Dark Mode ] ($btnThemeToggle):
  Invokes Apply-AppTheme($Dark). Dynamically recolors all forms, headers,
  action logs, decision boxes, input controls, and data grids without reloading.
- Switch Domain / DC ($btnSwitchDomain):
  Opens modal dialog for non-domain-joined management stations.
  - [Auto-Detect Domain]: Runs Get-DiscoveredLocalDomainSafe to query local
    machine domain membership and DNS suffix lists.
  - Target Domain: Domain FQDN (remembered across sessions).
  - Domain Controller (Optional): Explicit DC hostname or IP.
  - Operator Credentials: Validated in-memory as System.Management.Automation.PSCredential.
  - Verify & Connect: Executes LDAP RootDSE handshake to confirm connectivity.

TAB 1: INTEGRATIONS & PRE-FLIGHT SETUP
- Test Active Directory ($btnTestAD): Performs live LDAP RootDSE bind.
- Test Microsoft Graph ($btnTestM365): Calls Get-MgContext, checks scopes, probes /organization.
- Test Google GAM7 ($btnTestGoogle): Verifies gam.exe, oauth2.txt, runs gam oauth verify.
- 1. Setup Microsoft Graph ($btnSetupM365): Runs Setup-MicrosoftGraph.bat to install
  lightweight Graph modules and trigger device code authentication.
- 2. Setup Google GAM7 ($btnSetupGAM): Runs Setup-GoogleWorkspace-GAM.bat to install
  GAM7 and authorize Google Cloud project OAuth credentials.
- 3. Install RSAT (Optional) ($btnSetupRSAT): Runs Setup-RSAT-ActiveDirectory.bat to
  install RSAT Active Directory tools via Windows Capabilities (DISM).

TAB 2: INCIDENT CONTAINMENT DECK
- Find Users ($btnSearch): Queries AD using Ambiguous Name Resolution (ANR) filter:
  (|(anr={search})(sAMAccountName={search}*)(userPrincipalName={search}*)(mail={search}*)(proxyAddresses=smtp:*{search}*))
- Refresh Sessions ($btnRefreshUserSessions): Re-queries AD, Graph, and GAM7 to
  refresh Password Age, 365/Entra Status, Google Status, and AD Account Status.
- Safety Checkbox ($chkConfirmUser): Hardware interlock preventing containment actions
  until the operator explicitly verifies the target identity.
- 1. Reset Password ($btnResetPass): Sets password via LDAP DirectoryEntry.Invoke("SetPassword"),
  sets pwdLastSet = 0 (forcing change at next logon), and verifies via LDAP read-back.
- 2. Revoke 365 Sessions ($btnRevoke365): Sends HTTP POST to Microsoft Graph
  /v1.0/users/{id}/revokeSignInSessions, invalidating refresh tokens.
- 3. Revoke Google Sessions ($btnRevokeGoogle): Executes gam user <id> signout,
  terminating active web cookies and mobile device sessions.
- 4. Disable Account / Enable Account ($btnDisableAcct): Modifies userAccountControl
  bitmask (ADS_UF_ACCOUNTDISABLE = 0x0002) with immediate LDAP read-back verification.
- Run Full Playbook (1-Click) ($btnRunPlaybook): Executes Actions 1, 2, 3, and 4
  sequentially with verification gates between each step.

TAB 3: DEEP ISOLATION & MAILBOX RULES AUDITOR
- Block Entra Sign-In (Instant) ($btnBlockEntra): Issues HTTP PATCH to Microsoft Graph
  /v1.0/users/{id} with {"accountEnabled": false}, closing the 30-minute sync gap.
- Suspend Google User (GAM 7) ($btnSuspendGoogle): Runs gam update user <id> suspended on
  with 3-pass convergence verification via gam info user.
- Wipe Cloud MFA Methods & Rogue Grants ($btnWipeCloudTokens): Revokes Entra refresh
  tokens, deletes OAuth2 permission grants, deletes non-password authentication
  methods (SMS, TOTP, FIDO), and executes gam user <id> deprovision.
- Expire AD Account Restrict Workstations ($btnLockADWorkstations): Sets accountExpires
  to past FileTime (causing Kerberos KDC error 0x12) and sets userWorkstations to INCIDENT-LOCK.
- Audit M365 Gmail Rules ($btnAuditRules): Inspects Graph inbox messageRules and GAM7
  Gmail forwarding/filters, flagging external forwards and stealth deletes.
- Disable Rule / Delete Rule / Disable Suspicious: Remediates rogue inbox rules via Graph/GAM7.

TAB 4: MULTI-SOURCE SECURITY EVENT TRIAGE
- Pull Events (AD + Entra + Google) ($btnPullEvents): Queries DC security event logs
  (4624, 4625, 4740, 4768, 4769, 4771, 4776, 4720-4738), Entra sign-in logs, and GAM reports.
- View Event Guide ($btnLoadReferenceCatalog): Loads the complete built-in security
  dictionary for offline event lookup.
- Show Pulled Events ($btnRestorePulledEvents): Restores previous query results
  instantly without re-querying domain controllers or APIs.

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

GOOGLE WORKSPACE:
Executing gam user <upn> signout terminates web session cookies and mobile sync.
Executing gam user <upn> deprovision revokes all application-specific passwords,
2-Step Verification backup codes, and authorized third-party OAuth app grants.

================================================================================
6. HIGH-DPI RESPONSIVE SCALING ENGINE
================================================================================
- Baseline coordinate grid: 874 x 868.
- Dynamic proportional scaling on form resize calculates X and Y scalar ratios.
- Pixel-safe font caching quantizes half-point steps in $script:pixelFontCache,
  preventing GDI handle exhaustion and blurry virtualization on 1080p, 1440p, and 4K displays.

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
