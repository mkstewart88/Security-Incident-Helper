# DISCLAIMER, TERMS OF USE & LIMITATION OF LIABILITY

**USE ENTIRELY AT YOUR OWN RISK. THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OR MAINTENANCE OF ANY KIND.**

**IT IS 100% THE USER'S RESPONSIBILITY TO READ AND AUDIT THE SOURCE CODE BEFORE EXECUTING.**

---

### 1. ABSOLUTE & COMPREHENSIVE DISCLAIMER OF ALL LIABILITY

Under no circumstances, under no legal theory (whether in contract, tort, negligence, strict liability, product liability, statute, or otherwise), and under no jurisdiction shall the author(s), copyright holder(s), repository owner(s), maintainer(s), publisher(s), or contributor(s) be held responsible, liable, or subject to any claims, damages, or legal actions whatsoever by you, your employer, your clients, your organization, or any third party.

**THE AUTHOR IS NOT RESPONSIBLE FOR ANYTHING HAPPENING AS A RESULT OF SOMEONE USING THIS TOOL. THIS DISCLAIMER APPLIES TO ANY AND ALL ACTIONS, OPERATIONS, EVENTS, OUTCOMES, ERRORS, DEFECTS, OR CONSEQUENCES THIS SOFTWARE COULD POSSIBLY PERFORM, TRIGGER, INITIATE, OR CAUSE—WHETHER DIRECT, INDIRECT, FORESEEABLE, UNFORESEEABLE, INTENDED, UNINTENDED, OR ARISING FROM DEFECTS, BUGS, OR OPERATOR ERROR.**

This includes, without any limitation whatsoever:

* **ANY Active Directory or Identity Operation:** Any password reset, credential modification, account disablement, account enablement, account expiration (`accountExpires`), workstation restriction (`LogonWorkstations` / `userWorkstations`), account lockout, account unlock, attribute alteration, group change, user state modification, replication failure, directory corruption, or authentication breakdown on ANY account (standard users, service accounts, administrative accounts, VIP/executive accounts, or system principals).
* **ANY Cloud Tenant, Session, Token, or Mailbox Operation:** Any Microsoft 365 / Entra ID refresh token revocation (`Revoke-MgUserSignInSession`), Entra ID sign-in block/unblock (`accountEnabled`), Google Workspace session signout (`gam user <upn> signout`), Google Workspace user suspension/unsuspension (`gam update user <upn> suspended on/off`), Google Workspace deprovisioning (`gam user <upn> deprovision`), OAuth permission grant deletion, MFA method removal, app password or backup code wipe, inbox/forwarding rule modification or deletion, Gmail filter removal, API call, or cloud directory state change against ANY tenant or user account.
* **ANY Machine, Server, or Workstation Operation:** Any PowerShell execution, event log query, module installation, RSAT capability modification, registry update, environment variable modification, process termination, or hardware/OS state change against ANY machine (domain controllers, database servers, enterprise clusters, hypervisors, cloud instances, member servers, or user endpoints).
* **ANY Network or Service Impact:** Any connection attempt, LDAP/ADSI RootDSE query, Kerberos request, Event Log RPC query, Microsoft Graph REST call, Google Admin SDK request, DNS lookup, network congestion, firewall trip, or EDR/SIEM alert.
* **ANY Business, Financial, or Operational Loss:** Any data loss, email loss, data corruption, database downtime, lost revenue, interrupted business operations, regulatory penalties, compliance breaches, security incidents, loss of goodwill, termination of employment, or administrative overhead.

Any examples mentioned anywhere in this documentation or code are strictly non-exhaustive illustrations. **The author(s), maintainer(s), repository owner(s), and contributor(s) are NOT responsible for ANYTHING at all that occurs before, during, or after accessing, inspecting, compiling, executing, modifying, or distributing this software.**

---

### 2. COMPLETE USER RESPONSIBILITY TO READ THE CODE BEFORE EXECUTING

* **The user, operator, and system owner assume 100% of all risk.**
* Administrative and incident containment utilities running against Windows Active Directory, Microsoft Entra ID, and Google Workspace possess immense power.
* **It is the user's sole and exclusive responsibility to read, inspect, audit, and understand the source code (`IncidentResponse-Automator.ps1`, `Launch-IncidentAutomator.bat`, `Compile-To-EXE.cmd`, and all `Setup-*.bat` scripts) before executing it.**
* If you have not read the code or do not understand what a line of code does, **do not run it**.
* You are solely responsible for testing in a non-production environment and determining suitability, safety, and compliance with your organization's policies, security controls, and change management procedures.

---

### 3. NO RESPONSIBILITY FOR UPDATING OR MAINTAINING THIS APPLICATION

* **The author is NOT responsible for updating, patching, or maintaining this application.**
* This software is released on a strict **"as-is, take it or leave it"** basis with **zero maintenance obligation** and **no SLA**.
* The author has not certified, validated, or guaranteed this software for any particular environment, operating system build, or use case.
* The author is under **zero obligation** to provide technical support, answer inquiries, investigate bugs, provide security updates, or maintain compatibility with future versions of Windows, Active Directory, Microsoft Graph, or GAM7.
* Issues, pull requests, or questions submitted on GitHub or elsewhere may be reviewed, unanswered, or ignored at the author's sole discretion.

---

### 4. OPEN USE, FORKING & FOR-PROFIT SHOUT-OUT POLICY

* **Anyone can use or fork this project** under the terms of the [Apache License, Version 2.0](LICENSE).
* **For-Profit / Commercial Use:** If anyone uses this project (or any part of it) for profit or commercial purposes, they simply need to leave a shout-out on the GitHub repository first (via GitHub Issues or Discussions), **and they do NOT need to wait for a reply or approval before proceeding**.

---

### 5. GOVERNING ACKNOWLEDGEMENT

By accessing, downloading, viewing, forking, compiling, executing, or distributing this code or its binaries, you explicitly acknowledge and agree that:

1. You have read and accepted this entire disclaimer.
2. You understand it is your responsibility to read the code before executing it.
3. You assume full and exclusive liability for all outcomes and use this tool 100% at your own risk.
4. You waive and release any and all legal claims, demands, lawsuits, and remedies against the author(s) and contributor(s), in full compliance with Sections 7 and 8 of the Apache License, Version 2.0.
