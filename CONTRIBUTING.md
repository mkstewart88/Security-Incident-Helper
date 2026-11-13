# Forking & Technical Guide

## Static Code Release Notice
This repository is published as a static, standalone code release on an **"as-is"** basis. The author does not actively maintain this repository, triage issues, or accept pull requests. 

If you wish to modify, extend, or adapt this project for your environment, you are encouraged to **fork the repository** and maintain your own version.

---

## Free Use, Forking & Commercial Shout-Out Policy

1. **Anyone Can Use or Fork This Project:**
   * You are free to download, use, fork, modify, and redistribute this software under the terms of the [Apache License, Version 2.0](LICENSE).
2. **Commercial & For-Profit Use:**
   * If you sell, commercialize, or incorporate any part of this software into a paid product or service, you simply need to leave a public shout-out or repository attribution on this project's official GitHub repository (e.g., via GitHub Issues or Discussions).
   * **You do NOT need to wait for a reply or permission before proceeding.**
3. **No Maintenance Obligation & Absolute User Responsibility:**
   * The author is **not responsible for updating, patching, or maintaining** this software.
   * The author is **not responsible for any consequences, damages, or outcomes** resulting from running this tool. It is 100% the user's sole responsibility to read, audit, and understand all source code before executing it. See [DISCLAIMER.md](DISCLAIMER.md).

---

## Technical Architecture Reference for Forks

If you are developing or customizing your own fork, the following architectural design patterns apply:

### 1. Dual Active Directory Engine Support
* Active Directory operations (`Query-ADUsersSafe`, `Set-ADPasswordSafe`, `Set-ADAccountEnableSafe`, `Set-ADExtendedLockdownSafe`, `Get-ADDomainSafe`) are built to support both the optional RSAT `ActiveDirectory` PowerShell module and native .NET Framework directory services (`System.DirectoryServices.DirectoryEntry` and `DirectorySearcher`).
* Workstations are not assumed to be domain-joined; explicit server and credential configurations (`$script:targetServer`, `$script:adCredential`) from **Switch Domain / Profile** must be respected.

### 2. Multi-Pass Verification
* Directory writes re-query Active Directory to confirm attribute commitment.
* Microsoft Graph operations verify `Get-MgContext` scopes and return objects.
* Google Workspace GAM7 commands verify process exit code (`$LASTEXITCODE -eq 0`) and directory state.

### 3. Source Encoding & Standalone Execution
* Windows PowerShell 5.1 reads scripts without a UTF-8 BOM using the system ANSI codepage (Windows-1252). Avoid multi-byte Unicode characters in GUI labels to prevent display corruption.
* Batch scripts (`Setup-*.bat`, `Launch-IncidentAutomator.bat`, `Compile-To-EXE.cmd`) use standard CRLF line endings.
* Embedded Base64 strings in `IncidentResponse-Automator.ps1` mirror the standalone batch files to enable single-binary execution when compiled via `Compile-To-EXE.cmd`.

### 4. Direct Network Communication
* Network communication is strictly direct between the executing workstation and your designated Active Directory Domain Controller (LDAP/Kerberos) and official cloud provider endpoints (Microsoft Graph and Google APIs).
* The application does not include third-party telemetry, tracking, or cloud database dependencies.

---

## Building & Testing Locally

1. **Launch Directly:**
   * Double-click `Launch-IncidentAutomator.bat` or run:
     ```powershell
     powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\IncidentResponse-Automator.ps1
     ```
2. **Compile to Standalone Binary:**
   * Double-click `Compile-To-EXE.cmd` to validate syntax and compile `IncidentResponse.exe` using `PS2EXE`.
