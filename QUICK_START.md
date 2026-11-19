# Quick Start Guide

Get **Security Incident Response Automator** running on a Windows workstation or server in just a few minutes.

---

## 1. Prerequisites
* **OS & Runtime:** Windows 10 (1809+), Windows 11, or Windows Server 2016+ with Windows PowerShell 5.1 and .NET Framework 4.8+.
* **Permissions:** Appropriate administrative privileges in **Active Directory**, **Microsoft Entra ID**, and/or **Google Workspace** for the containment actions you plan to run.
* **Network:** Direct access to a Domain Controller (TCP 389/636) and outbound HTTPS (TCP 443) for cloud operations.

---

## 2. Launch or Compile

Choose any of the three launch methods:

* **Option A — Batch Launcher (Recommended):** Double-click **`Launch-IncidentAutomator.bat`** (automatically unblocks files and launches in `-STA` mode).
* **Option B — Direct PowerShell:**
  ```powershell
  powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\IncidentResponse-Automator.ps1
  ```
* **Option C — Standalone `.exe`:** Double-click **`Compile-To-EXE.cmd`** to build a portable `IncidentResponse.exe`.

> **Security Note:** Review `IncidentResponse-Automator.ps1` and the accompanying `.bat`/`.cmd` scripts before running them in production. See [`DISCLAIMER.md`](DISCLAIMER.md).

---

## 3. Initial Setup (Tab 1: `1. Setup`)

1. **Primary Profile Prompt (First Launch):** Choose whether this environment is your **Primary (Home) Domain Profile** or if you are **temporarily assisting another domain**, then enter a profile name.
2. **Test or Install Integrations:** Use the three integration columns on **Tab 1** to verify or install prerequisites:
   * **Active Directory:** Click **Test Active Directory** (or **Switch AD Account / Domain** if authenticating from a non-joined PC or with alternate Domain Admin credentials).
   * **Microsoft Graph:** Click **1. Setup Microsoft Graph** (first time), then **Test Microsoft Graph** or **Switch Graph Account** to sign in with an elevated M365 admin account.
   * **Google GAM7:** Click **2. Setup Google GAM7** (first time), then **Test Google GAM7** or **Switch GAM Account**.
3. **Optional Credential Vault & Master Passphrase:**
   * In **Switch AD Account / Domain** or **Credential Health**, you can optionally save encrypted AD credentials (protected by Windows DPAPI `CurrentUser`) so reachable domain profiles auto-connect at startup.
   * Click **`Master Passphrase`** in the top-right header to require a passphrase on launch across all saved profiles (includes **Change Passphrase**, **Remove Passphrase**, and emergency **`Remove Passphrase & All Creds`** reset).

---

## 4. Basic Incident Containment Workflow

1. **Locate & Verify (`Tab 2: 2. Containment`):** Search by name, username, or email (minimum 3 characters), select the target user, review the four status cards, and check **`I confirm I have selected the correct user`** to unlock containment actions.
2. **Contain (`Tab 2`):** Run individual actions (**Reset Password**, **Revoke 365 Sessions**, **Revoke Google Sessions**, **Disable Account**) or **Run Full Playbook (1-Click)**.
3. **Deep Isolation & BEC Check (`Tab 3: 3. Deep Isolation`):** Block Entra sign-in, suspend Google accounts, wipe persistent MFA methods or OAuth grants, expire Kerberos tickets, and run **Audit M365 & Gmail Rules** to disable suspicious forwarding rules.
4. **Triage & Audit (`Tab 4` & `Tab 5`):** Pull and filter DC, Entra, and Google login events on **Tab 4**, and export local compliance records from **Tab 5**.

For detailed walkthroughs, see [`README.md`](README.md). For engineering details, see [`README-extended.md`](README-extended.md).
