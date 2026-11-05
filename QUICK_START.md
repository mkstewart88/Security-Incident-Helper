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

## 4. Pre-Flight Integration Setup
* Open **Tab 1 (`1. Setup`)** to verify connectivity with Active Directory, Microsoft Graph, and Google Workspace (GAM7).
* Use the 1-click automated setup scripts if any modules or CLI tools need to be installed on the jump host.
