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

## 4. Pre-Flight Integration Setup & Domain Profiles
* On first launch, if no **Primary Domain Profile** is set yet, choose whether this environment is your **Primary (Home) Domain Profile** or if you are temporarily assisting another domain (keeping your Primary slot clean until you return home).
* Open **Tab 1 (`1. Setup`)** to verify connectivity with Active Directory, Microsoft Graph, and Google Workspace (GAM7), and run the 1-click setup scripts if modules or CLI tools need to be installed.
* Use **Switch Graph Account**, **Switch GAM Account**, or **Switch AD Account / Domain** on Tab 1 for separate elevated admin accounts (WAM disabled for Graph).
* Supporting multiple domains or tenants? Use **Switch Domain / Profile** (top-right) or the Tab 1 **Profile** bar to create and switch isolated Domain Profiles, or choose **Switch Cloud Only (Skip AD)** when off-VPN.

