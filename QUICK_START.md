# Quick Start Guide

**Security Incident Response Automator** can be launched or compiled in seconds on any Windows workstation.

---

## 1. Quick Launch (Recommended)
1. Double-click **`Launch-IncidentAutomator.bat`** in Windows Explorer.
   *(Or run it from an elevated command prompt).*
2. The batch wrapper automatically unblocks execution, enforces Single-Threaded Apartment (`-STA`) mode, and opens the 5-tab Windows Forms incident console.

---

## 2. Direct PowerShell Execution
If you prefer running the script directly from PowerShell 5.1:
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\IncidentResponse-Automator.ps1
```

---

## 3. Compile to Standalone Portable `.exe`
To package the script and its embedded setup scripts into a single standalone binary:
1. Double-click **`Compile-To-EXE.cmd`**.
2. The script validates syntax and compiles `IncidentResponse-Automator.ps1` into `IncidentResponse.exe` using `PS2EXE`.

---

## 4. Pre-Flight Integration Setup, Domain Profiles & Master Passphrase
* **Global Master Passphrase (Optional):** Click **`Master Passphrase`** in the top-right header (to the right of the GitHub icon). When active, it opens an action menu with 0 textboxes and reveals only the input(s) needed for your chosen action: **Change Passphrase** (`Current` + `New` + `Confirm`), **Remove Passphrase** (only 1 `Current` field + warning explaining why to keep one while preserving saved credentials), or break-glass **Remove Passphrase & All Creds** (0 fields, no passphrase needed if forgotten; wipes all saved credentials back to default). When configured, opening the console prompts for the passphrase (closing automatically after 2 failed attempts); when unset, the console skips the prompt and auto-connects immediately while staying on Tab 1.
* **Automatic Plugged-In Domain Detection & Login:** On launch, the automator detects reachable domains on your active network adapter (even if the PC is not domain-joined), switches to the matching Domain Profile, unlocks its saved DPAPI AD credentials, and automatically connects **Active Directory + Microsoft Graph + Google GAM7**.
* On first launch, if no **Primary Domain Profile** is set yet, choose whether this environment is your **Primary (Home) Domain Profile** or if you are temporarily assisting another domain—then enter only the single profile name box shown for your choice.
* Open **Tab 1 (`1. Setup`)** to verify connectivity with Active Directory, Microsoft Graph, and Google Workspace (GAM7), and run the 1-click setup scripts if modules or CLI tools need to be installed.
* Use **Switch Graph Account**, **Switch GAM Account**, or **Switch AD Account / Domain** on Tab 1 for separate elevated admin accounts (WAM disabled for Graph), and use **Validate Credential Health** or **Detect Network & Auto-Connect** for zero-lockout diagnostics (or **Switch Cloud Only (Skip AD)** when off-VPN).

