# Changelog

All notable additions and milestones for **Security Incident Response Automator** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.68] - 2026-11-19

### Fixed
- **Automatic Startup `Update Available` Header Badge (`Start-StartupUpdateCheckAsync` / `Invoke-ApplyStartupUpdateCheckResultSafe`):**
  - Fixed a PowerShell 5.1 WinForms `Timer.Tick` scope bug where `Start-StartupUpdateCheckAsync` stored its completion handler in a local scriptblock (`$applyResult`) that became `$null` once `Start-StartupUpdateCheckAsync` returned, causing the background tick handler to throw and silently swallow the exception before updating the header button.
  - Elevated completion handling to a named script-level function (`Invoke-ApplyStartupUpdateCheckResultSafe`), tracked `$script:startupUpdateRetryTimer` at script scope for reliable disposal, set `$ProgressPreference = 'SilentlyContinue'` inside `$script:GitHubUpdateWorkerScript` so background HTTP checks never stall on progress records, and switched release probing to `/releases?per_page=1` to match the Web Companion. As a result, **`Update Available`** renders automatically on launch without needing a manual click whenever GitHub has a newer version or commit.

## [1.1.67] - 2026-11-19

### Changed & Clarified
- **Break-Glass Reset Box 1 & Box 2 Clarity, Alignment & Typography (`Show-MasterPassphraseDialogSafe` / `MasterPassphraseModal.tsx`):**
  - **Explicit Master Passphrase Wipe Notice:** Updated Break-Glass Box 1's single red warning sentence to explicitly state that **your Master Passphrase** is also permanently wiped alongside all domain profiles, Active Directory credentials, Microsoft Graph sessions, and Google GAM7 profiles from the computer.
  - **`Continue?` Question Mark & Right Alignment:** Renamed `Continue` to **`Continue?`** and moved it right-aligned immediately next to the **`Yes`** / **`No`** buttons in both the Windows Forms console (`$lblContinue1` `MiddleRight`) and Web Companion (`justify-end gap-3`).
  - **Larger Prompt Typography on Both Boxes:** Increased text and button sizes by 1 step across both Break-Glass Box 1 (`Confirm Break-Glass Reset`) and Break-Glass Box 2 (`Are you sure?`) for clear readability.

### Fixed & Audited
- **Password Reset Next-Logon Flag (`Set-ADPasswordSafe` / `Show-PasswordResetCustomDialog`):** Wired `[bool]$RequireChangeAtLogon` through to `Set-ADPasswordSafe` so the dialog's *"Force password change at next logon"* checkbox actually controls `pwdLastSet` (`0` vs `-1`), and escaped `$SamAccount` with `ConvertTo-LdapFilterValueSafe` inside `Set-ADPasswordSafe`.
- **Microsoft Graph App-Only Error Propagation (`Invoke-GraphMailboxRestSafe`):** Re-threw legitimate non-401 API errors (such as `404 UserNotFound` on secondary proxy aliases) instead of falling through into unexpected interactive delegated sign-in prompts.
- **Domain Switcher `Purge Saved` Confirmation (`$btnPurgeDlgCred`):** Added an explicit **`Are you sure?`** confirmation dialog before purging saved AD credentials inside `Show-DomainSwitcher`.
- **Profile-Scoped GAM7 Installer & Reset Base Refresh (`$btnRunGamSetup` / `Remove-GlobalMasterPassphraseAndPurgeAllSafe`):** Scoped `$env:GAMCFGDIR` to the active profile directory before launching the GAM7 setup batch installer and refreshed `$script:BaseDefaultGamCfgDir` after setup or Break-Glass reset.
- **Empty Audit Export & DataGridView Theme Headers (`$btnExportAudit` / `Apply-AppTheme`):** Added in-memory audit row/header fallback when `AuditLog.csv` does not exist yet on disk, and set `$g.EnableHeadersVisualStyles = $false` across all DataGridViews so Dark/Light column header themes render faithfully on Windows.
- **Web Companion Update Probe & Profile Sync (`updateVersion.ts` / `CredentialHealthPanel.tsx`):** Switched startup release checks from `/releases/latest` to `/releases?per_page=1` to eliminate harmless `404` console noise when no formal GitHub Release exists yet, and ensured `CredentialHealthPanel` syncs dynamically with custom profiles.

## [1.1.66] - 2026-11-19

### Added, Changed & Fixed
- **Tab 1 `Purge Saved Creds` Confirmation Dialog (`IncidentResponse-Automator.ps1` & `CredentialHealthPanel.tsx`):**
  - Added an explicit **"Are you sure?"** confirmation dialog (`Yes` / `No`) before purging the local encrypted AD credential vault (`ad_cred.dpapi.json` / Web Crypto envelope) and resetting the circuit breaker on Tab 1 (`1. Setup`). The purge action only executes if confirmed.
- **Scrollable Tab 1 Setup & Multi-Domain Reference (`$tabDiag` / `$grpDiagGuide` / `App.tsx`):**
  - Enabled `AutoScroll = $true` on Tab 1 (`$tabDiag`) and upgraded `$lblDiagGuide` inside **"Integration Setup & Multi-Domain Switching Reference"** to a borderless scrollable `TextBox` (`ScrollBars = Vertical`) paired with `overflow-y-auto max-h-96` on the Web Companion card so setup instructions are never cut off when the window is not full-screen.
- **Smooth Light/Dark Theme Cross-Fade Transition (`Invoke-ThemeCrossFadeTransitionSafe` / `src/index.css`):**
  - Added a bitmap overlay opacity cross-fade animation (~240ms) in the PowerShell WinForms console and CSS View Transitions (`360ms cubic-bezier(0.22, 1, 0.36, 1)`) in the Web Companion when toggling between Light and Dark modes.
- **Complete Break-Glass Wipe (Profiles + AD + Microsoft Graph + Google GAM7) & Two-Box Red Warning (`Remove-GlobalMasterPassphraseAndPurgeAllSafe` / `MasterPassphraseModal.tsx`):**
  - Upgraded **`Remove Passphrase & All Creds`** so emergency break-glass reset permanently wipes **all Domain Profiles (`Profiles\`, `Profiles.json`, `LastDomainConnection.json`), all AD DPAPI vaults, `MasterVault.dpapi.json`, `MailboxAuditorApp.json`, Microsoft Graph sessions & MSAL caches (`Disconnect-MgGraph`, `.mg`, `MicrosoftGraphSetup`), and Google GAM7 OAuth/config files (`oauth2.txt`, `oauth2service.json`, `client_secrets.json`, `gam.cfg`, `gamcache`) without deleting `gam.exe`**, then resets in-memory profiles back to clean default state.
  - Replaced the single warning dialog with a clean two-box flow:
    - **Box 1:** Displays **one concise warning sentence in red text** stating that all profiles, AD, Graph, and GAM7 data will be wiped from the computer, with a bottom **`Continue`** label and **`Yes`** / **`No`** buttons.
    - **Box 2 (Separate Confirmation Box):** Prompts **`Are you sure?`** with **`Yes`** / **`No`** before executing the wipe.
- **Instant Startup `Update Available` Badge & Reliable `Update & Restart` Persistence (`$GitHubUpdateWorkerScript` / `updateVersion.ts`):**
  - Fixed startup update probing to compare **both** `/releases/latest` and `main/VERSION` (via commit SHA + uncached GitHub Contents API, picking whichever version is higher) with extended concurrency resilience and automatic transient retry so **`Update Available`** appears automatically on launch whenever a newer release or commit exists.
  - Fixed **`Update & Restart`** returning on the old version by downloading from immutable commit SHA / uncached API URLs, validating that the downloaded `.ps1`'s `$script:AppVersion` is strictly greater than the installed version, adding a 30-attempt file-lock retry loop in `$swapScript` (for both `.exe` and `.ps1`), and syncing sibling `IncidentResponse-Automator.ps1`, `VERSION`, and `CHANGELOG.md` files alongside compiled executables.

## [1.1.65] - 2026-11-18

### Added & Fixed
- **Action-First Prompt Cleanup & Dual-Channel Update Detection Foundation:** Refined prompt `"Continue"` button labels and updated `checkGitHubLatestVersion` / updater plumbing to evaluate `main/VERSION` alongside GitHub Releases.

## [1.1.64] - 2026-11-18

### Added & Improved
- **Smooth Theme Cross-Fade Animation (`src/index.css`):**
  - Added CSS View Transition keyframes (`::view-transition-old(root)` and `::view-transition-new(root)`) with a 360ms `cubic-bezier(0.22, 1, 0.36, 1)` transition for butter-smooth visual cross-fading when toggling between Light and Dark modes (supporting `prefers-reduced-motion`).
- **Comprehensive Break-Glass & Complete System Wipe (`MasterPassphraseModal.tsx` & `credentialVault.ts`):**
  - Upgraded **"Remove Passphrase & All Creds"** (Break-Glass Reset) to thoroughly eradicate all stored trace data from the computer: AD credential vaults, domain profiles (`Profiles.json`), GAM7 OAuth credential folders (`Profiles\<id>\gam`), and Microsoft Graph / Entra ID session contexts (`Profiles\<id>\graph`, `Profiles\<id>\mg`, and user `.mg\MgContext.json`).
- **Two-Step Red Warning Confirmation Flow:**
  - Clicking the wipe/reset button now triggers a two-step confirmation dialog:
    - **Step 1:** Displays a single red warning sentence explaining that all profiles, AD credentials, Microsoft Graph contexts, and Google Workspace GAM7 profiles will be wiped from the computer, with a **"Continue"** button and "No".
    - **Step 2:** Clicking "Continue" prompts **"Are you sure you want to delete all profiles and credentials?"** before executing the complete system wipe.

## [1.1.63] - 2026-11-18

### Changed & Improved
- **Action-First `Master Passphrase` Dialog (`Show-MasterPassphraseDialogSafe` / `MasterPassphraseModal`):**
  - Replaced the static multi-box form with contextual step views so **only the input field(s) needed for your chosen action appear**:
    - **Not Configured:** Displays only the 2 fields required to enable a passphrase (`New` + `Confirm`).
    - **Active Menu (`0` textboxes):** Opens to an action menu (`Change Passphrase`, `Remove Passphrase`, `Remove Passphrase & All Creds`, `Close`).
    - **Change Passphrase:** Reveals the 3 required inputs (`Current`, `New`, `Confirm`) + `Back`.
    - **`Remove Passphrase`:** Reveals **only 1 input** (`Current Master Passphrase`) + `Back`, then shows the explanatory confirmation warning before keeping saved AD credentials under DPAPI `CurrentUser` / device key.
    - **`Remove Passphrase & All Creds` (Break-Glass Reset):** Requires **0 inputs** — opens directly to the wipe confirmation warning so forgotten passphrases can be reset cleanly.
- **Action-First First-Time Primary Profile Setup (`Show-PrimaryProfilePromptSafe` / `PrimaryProfileModal`):**
  - Step 1 displays only the detected environment and choice buttons (`Yes - Set as My Primary Profile`, `No - Assisting Another Domain` / `No - Stay on Current Profile`, `Later`) with **0 textboxes**.
  - Clicking **Yes** or **No** advances to Step 2 with **only the single contextual profile name input** (`Primary Profile Name:` or `Temporary / Assisting Profile Name:`), plus `Back`, `Later`, and the matching confirm button.
- **Reliable GAM7 Config Discovery & Profile Affinity (`Resolve-BaseDefaultGamConfigDirSafe` / `Invoke-GamCliSafe`):**
  - Resolves Default GAM7 config reliably across User/Machine `GAMCFGDIR`, `~/.gam`, `~/GAMConfig`, `%LOCALAPPDATA%\GAM7`, `C:\GAMConfig`, and the `gam.exe` folder while ignoring stale inherited profile `GAMCFGDIR` values across restarts, never forcing an empty `.gam` folder over a working GAM installation, and keeping the active profile sticky on equal network probe matches.

## [1.1.62] - 2026-11-18

### Added & Improved
- **Reliable Startup Unjoined-Domain Auto-Detect & Unified AD + Graph + GAM7 Login (`Start-StartupADAutoConnectAsync` / `Invoke-StartupUnifiedPreflightSafe`):**
  - Fixed a WinForms `Timer.Add_Tick` script-scope closure issue in `Start-StartupADAutoConnectAsync` by elevating completion handling to `Invoke-ApplyStartupDiscoveryResultSafe`.
  - On launch, the automator probes all configured Domain Profiles in parallel (prioritizing plugged-in active NIC DNS suffixes even on non-domain-joined workstations), silently unseals the matching profile's DPAPI-encrypted AD credentials, connects to Active Directory (`$script:targetDomain` / `$script:adSessionCred`), and runs `Invoke-StartupUnifiedPreflightSafe` to automatically initialize **Active Directory**, **Microsoft Graph**, and **Google GAM7** together while **remaining cleanly on Tab 1 (`1. Setup`)**.
- **Global Application-Wide `Master Passphrase` Button & 2-Attempt Startup Security Gate (`Show-MasterPassphraseDialogSafe` / `Show-StartupMasterPassphraseGateSafe`):**
  - **Top-Right Header Placement:** Added the **`Master Passphrase`** button immediately to the right of the GitHub button in the top-right header (`$btnMasterPassphrase` in `IncidentResponse-Automator.ps1`; `Master Passphrase` button + modal in `src/App.tsx` and `MasterPassphraseModal.tsx`).
  - **Streamlined Global Passphrase Management:** Replaced per-profile vault passphrase checkboxes with a single optional application-wide Master Passphrase covering all Domain Profiles:
    - **Set / Change:** Configure a new passphrase or update it (requires current passphrase), re-encrypting all saved profile vaults.
    - **`Remove Passphrase`:** Requires verifying the current passphrase and presents a detailed confirmation warning explaining both what happens (saved vaults revert to machine/user-only DPAPI `CurrentUser` / device Web CryptoKey without a startup prompt) and why you should keep a passphrase protecting Domain Admin credentials.
    - **`Remove Passphrase & All Creds` (Break-Glass Reset):** Does **not** require the current passphrase—intended for emergency use if forgotten—and presents a full confirmation warning explaining that proceeding permanently wipes all stored AD credentials across every profile and resets saved vault state back to default.
  - **2-Attempt Startup Gate:** When a Master Passphrase is enabled, opening the application prompts immediately before any domain probing or login; attempt #1 wrong entry warns (`1 attempt remaining before the application closes`), and attempt #2 failure (or Cancel/Exit) cleanly closes the console. When no passphrase is configured, the console opens and auto-connects directly.

## [1.1.61] - 2026-11-18

### Added & Improved
- **Event Triage Full Search & Highlighting Across Results and Clicked Log Details (Tab 4 / Companion UI):**
  - **Expanded Search Scope:** Typing into the **Tab 4 (`4. Event Triage`)** search filter now matches across **both** the result grid columns (`Timestamp`, `Source`, `Event Code`, `Severity`, `Host/IP`, `Summary`) **and** the clicked log's detail fields (`Recommended Decision` / `Recommendation`, `What It Means`, and `Raw Telemetry`).
  - **Result Columns & Clicked Log Detail Highlighting (`IncidentResponse-Automator.ps1`):** Expanded `$gridEvents.Add_CellPainting` across columns `1..5` (`Source`, `Code`, `Severity`, `Host/IP`, `Summary`) and upgraded `$txtEventDecision` to a `RichTextBox` (`DetectUrls = $false`) driven by `Update-EventDecisionDetailBox`, dynamically highlighting every match in both the table cells and the clicked log detail pane in real time (and preserving highlight spans across Dark/Light mode toggles).
  - **Web Companion Full Highlighting (`src/lib/eventCatalog.ts` & `src/App.tsx`):** Updated `filterSecurityEvents` to include `recommendation` and `severity`, and applied `<HighlightedText>` across every table cell (`Source`, `Code`, `Severity`, `Summary`) and all clicked log detail fields (`Code`, `Summary`, `Meaning`, `Recommendation`).

### Security
- **Comprehensive Codebase Security Audit & Hardening:**
  - **Sensitive Memory Buffer Scrubbing:** Zeroed raw DPAPI plaintext byte buffers (`[Array]::Clear`) and secret object strings immediately after `PSCredential` hydration (`Unprotect-ProfileADCredentialSafe`) and cleared client secret variables (`$secretText`, `$plainSecret`, `$tokenBody['client_secret']`) after token exchange in `Ensure-GraphMailboxAuditorAppSafe`.
  - **Single-User NTFS ACLs for Graph Auditor Secret (`MailboxAuditorApp.json`):** Applied `Set-StrictUserFileAclSafe` when writing `MailboxAuditorApp.json`.
  - **RFC 4515 LDAP Filter Escaping (`ConvertTo-LdapFilterValueSafe`):** Escaped `\`, `*`, `(`, `)`, and `\0` characters in exact-match `sAMAccountName` LDAP filters inside `Set-ADAccountEnableSafe`, `Set-ADExtendedLockdownSafe`, and `Get-UserSecurityEventsSafe`.
  - **CSV Formula Injection Neutralization (`Format-CsvSafeField`):** Prefixed leading `=`, `+`, `-`, `@`, and tab characters with a leading single quote (`'`) to prevent spreadsheet DDE/formula execution on export.
  - **Trusted HTTPS Updater & Link Guards:** Validated `refName` (`^[A-Za-z0-9._/-]+$`, no `..`) and restricted GitHub download URLs to `https://github.com/...` and `https://*.githubusercontent.com/...` in `Show-UpdateCheckWindow`, and enforced `https` URI validation before invoking `Start-Process` on `$txtLogUpd.Add_LinkClicked`.
  - **Web Companion IndexedDB Key Cleanup:** Updated `CredentialHealthPanel` to delete the IndexedDB AES-GCM `CryptoKey` alongside encrypted vault ciphertext when the 1-strike circuit breaker purges rotated credentials.

## [1.1.60] - 2026-11-18

### Added & Improved
- **Event Triage Catalog Dynamic Search Highlighting (Tab 4 / Companion UI):**
  - **Dynamic Summary Highlighting:** Typing into the **Tab 4 (`4. Event Triage`)** search filter dynamically highlights all case-insensitive matched substrings directly within the **Summary** column (`Plain-English Meaning`) in real time, preserving original casing and escaping regex metacharacters cleanly across Dark Mode and Light Mode.
  - **Windows Console Tab 4 Filter & GDI+ Cell Highlighting (`IncidentResponse-Automator.ps1`):** Added a live `$txtEventSearch` (`Filter:`) textbox to `$grpEventHeader` that filters pulled events and the built-in **View Event Guide** dictionary as you type (`Render-SecurityEventsGrid`), paired with custom GDI+ `CellPainting` match highlighting inside the Summary column (`colEvMeaning`).
  - **Web Companion Filter Highlighting (`src/lib/eventCatalog.ts` & `src/App.tsx`):** Extracted pure `splitHighlightSegments` helper (with `node:test` coverage) and added live `<mark>` highlight rendering plus a one-click clear button inside Tab 4 Event Triage.

## [1.1.59] - 2026-11-18

### Added & Improved
- **Encrypted Per-Profile Active Directory Credential Vault (`ad_cred.dpapi.json`):**
  - **Machine & User Locked Persistence (Windows DPAPI `CurrentUser`):** Domain Admin credentials saved per Domain Profile are encrypted via `System.Security.Cryptography.ProtectedData` (`DataProtectionScope::CurrentUser`) with per-profile + per-user-SID entropy and locked with explicit current-user NTFS ACLs (`Set-StrictUserFileAclSafe`), so encrypted blobs only decrypt on the exact Windows workstation and user account where they were configured.
  - **Optional Vault Master Passphrase Layer:** Supports wrapping the DPAPI vault with an additional user-defined Master Passphrase derived via PBKDF2 (150,000 iterations) + AES-256-CBC + HMAC-SHA256 authentication (`New-AesPassphraseEnvelopeSafe` / `Open-AesPassphraseEnvelopeSafe`).
  - **Domain Switcher & Web Vault Companion:** Added save/passphrase/purge controls in `Show-DomainSwitcher`, plus a **Web Crypto API (`window.crypto.subtle`)** AES-GCM-256 + PBKDF2 SHA-256 / non-extractable local `CryptoKey` vault in the browser companion.
- **Zero-Credential Network Domain Detection & Profile Auto-Connect:**
  - Non-blocking background DNS SRV (`_ldap._tcp.dc._msdcs.<domain>`) + async 700ms TCP port `389`/`636` pre-checks (`Start-StartupADAutoConnectAsync` / `Test-ADDomainNetworkReachableSafe`) discover which configured Domain Profile is reachable on the current network without freezing the UI or sending any credentials when offline or on another network.
  - Automatically switches to the matching reachable Domain Profile and connects AD using its saved vault (or integrated Windows auth) when safe.
- **Tab 1 (`1. Setup`) Credential Health Diagnostic Panel & Zero-Lockout Circuit Breaker:**
  - Added the **Credential Health & Encrypted AD Vault (`$grpCredHealth`)** diagnostic panel with **Validate Credential Health**, **Detect Network & Auto-Connect**, **Configure Saved AD Creds...**, and **Purge Saved Creds**.
  - **Anti-Lockout Safeguards (`Invoke-ValidateStoredADCredentialHealthSafe`):** Maintains non-secret health metadata (`ad_cred_health.json`); when domain-joined to the target domain, checks AD `pwdLastSet`, `badPwdCount`, `lockoutTime`, and `lockoutThreshold` over ambient Windows Kerberos *before* ever binding with the stored password—auto-purging stale secrets with **0 failed logon attempts** if the password rotated. Enforces a strict **1-Strike Circuit Breaker** for cross-domain/remote targets so any rejected logon immediately wipes the local secret and prevents lockout loops on relaunch.

## [1.1.58] - 2026-11-17

### Changed & Improved
- **Automatic Startup GitHub Update Check & Dynamic Header Version Badge (`Start-StartupUpdateCheckAsync`):**
  - The console now automatically checks GitHub (`releases/latest` with commit-SHA-busted `VERSION` fallback) asynchronously in the background when the application loads without blocking startup or pre-flight checks.
  - Replaced the static **"Check for Updates"** header button label with a live status label (`Update-HeaderUpdateButtonState`):
    - Displays **`v<version>`** (e.g., `v1.1.58`) when you are running the latest version (or when offline/unreachable, with explanatory hover tooltip).
    - Displays **`Update Available`** with theme-aware amber/gold highlight styling in both Dark Mode and Light Mode whenever a newer version is published on GitHub.
  - Clicking the button continues to open the full **Check for Updates** dialog (`Show-UpdateCheckWindow`) with **View Changelog**, **Update & Restart**, and local `PS2EXE` rebuild functionality unchanged, and running a manual check inside the dialog also refreshes the header button label.

## [1.1.57] - 2026-11-12

### Changed & Improved
- **Symmetric Tab 3 (`3. Deep Isolation`) Cloud Persistence Eradication Controls & Tooltips:**
  - Standardized the 5 red cloud persistence wipe buttons on **Tab 3 (`3. Deep Isolation`)** so Microsoft 365 (Entra ID) and Google Workspace (GAM7) use clean, symmetric naming and include detailed hover tooltips explaining every sub-item wiped:
    1. **Wipe Entra 2FA Methods** (`-Scope EntraMfa`): Removes registered non-password Entra authentication factors (Microsoft Authenticator, Phone/SMS, FIDO2 security keys, Software OATH tokens, Temporary Access Passes, and Email methods).
    2. **Wipe Entra OAuth Grants** (`-Scope EntraOAuth`): Revokes Entra ID refresh tokens (`revokeSignInSessions`) and deletes all delegated third-party OAuth 2.0 application permission grants (`oauth2PermissionGrants`).
    3. **Wipe Google 2FA Methods** (`-Scope GoogleTwoStep`): Runs `gam user <id> turnoff2sv` + `gam user <id> signout` to turn off Google 2-Step Verification (Authenticator, prompts, security keys) and invalidate 10-digit backup verification codes.
    4. **Wipe Google OAuth Grants** (`-Scope GoogleTokens`): Runs `gam user <id> deprovision` + `gam user <id> signout` to revoke all third-party Google OAuth application grants, 16-character Application-Specific Passwords (ASPs), and active session cookies.
    5. **Wipe All (Entra + GAM7)** (`-Scope All`): Sequentially executes all 4 cloud persistence wipe actions above in a single click.
- **Entra Temporary Access Pass Eradication:** Added `temporaryAccessPassAuthenticationMethod` (`temporaryAccessPassMethods`) to `Invoke-WipeCloudMfaAndTokensSafe` so **Wipe Entra 2FA Methods** also purges active Temporary Access Passes.
- **Full-Screen & High-DPI Prompt Scaling and Wrapped Label Layout Fixes (`Invoke-ApplyModalResponsiveScale`):**
  - Added unified `Invoke-ApplyModalResponsiveScale` across all modal prompts (`Show-PrimaryProfilePromptSafe`, `Show-NewDomainProfileModal`, `Show-DomainSwitcher`, Profile Rename dialog, `Show-ChangelogWindow`, `Show-UpdateCheckWindow`, and `Show-PasswordResetCustomDialog`) using `ClientSize`-based bounds, proportional `GraphicsUnit::Pixel` font caching, and `TextRenderer::MeasureText` dynamic height expansion so wrapped text never clips in full-screen or high-DPI views.
  - Expanded wrapped integration status and header label bounds on **Tab 1 (`1. Setup`)**, **Tab 2 (`2. Containment`)**, **Tab 3 (`3. Deep Isolation`)**, and **Tab 4 (`4. Event Triage`)**, escaped literal `&&` ampersands in `GroupBox` titles (`Directory & Cloud Integration Status`, `Live Integration Verification & Account Setup / Switching`, `Real-Time Action Log & Diagnostics`, etc.), removed unused `Show-ConsoleWindowSafe` dead code, and aligned the Developer Navigation Index line numbers.
- **Top-Right GitHub Repository Icon (`$btnGitHub`):** Added a theme-aware vector GitHub icon button directly to the right of `[ Light Mode ]` / `[ Dark Mode ]` in the header bar that opens `https://github.com/mkstewart88/Security-Incident-Helper` in the default browser on click.
- **Consistent UI & Documentation Wording:** Standardized all tab references, event triage recommendations, control identifiers, and GitHub companion documentation across all 5 tabs.

## [1.1.56] - 2026-11-12

### Changed & Improved
- **Tab 1 (`1. Setup`) Service-Column Alignment:** Reorganized the 3x3 integration button grid so each identity provider occupies its own vertical column:
  - **Column 1 (Active Directory):** **Test Active Directory** (Row 1) | **Install RSAT (Optional)** (Row 2) | **Switch AD Account / Domain** (Row 3)
  - **Column 2 (Microsoft Graph):** **Test Microsoft Graph** (Row 1) | **1. Setup Microsoft Graph** (Row 2) | **Switch Graph Account** (Row 3)
  - **Column 3 (Google GAM7):** **Test Google GAM7** (Row 1) | **2. Setup Google GAM7** (Row 2) | **Switch GAM Account** (Row 3)
- **Full 5-Button Cloud Persistence Eradication Split on Tab 3 (`3. Deep Isolation`):**
  - Expanded the red cloud persistence wipe controls into 5 dedicated buttons covering Entra ID 2FA methods, Entra OAuth grants, Google 2FA methods, Google OAuth grants, and Wipe All (Entra + GAM7).

## [1.1.55] - 2026-11-12

### Added
- **Granular Tab 3 Cloud Persistence Wipe Actions:**
  - Separated the monolithic **Wipe Cloud MFA Methods, OAuth App Grants, App Passwords & Backup Codes** button on **Tab 3 (`3. Deep Isolation`)** into four dedicated actions:
    - **Wipe Entra MFA Methods** (removes non-password MFA registrations: Authenticator, Phone, FIDO2, TAP)
    - **Wipe Entra OAuth Grants** (revokes Entra refresh tokens and third-party OAuth permission grants)
    - **Wipe Google ASPs & 2SV** (runs `gam user <id> deprovision` to clear app-specific passwords, 2SV backup codes & OAuth tokens)
    - **Wipe All (Entra + GAM7)** (executes all three cloud eradication steps sequentially)

### Changed & Fixed
- **Tab 1 (`1. Setup`) Service-Row Grid Alignment:** Reorganized the 3x3 button matrix so each identity provider sits on its own row:
  - Row 1 (Active Directory): **Test Active Directory** | **Install RSAT (Optional)** | **Switch AD Account / Domain**
  - Row 2 (Microsoft Graph): **Test Microsoft Graph** | **1. Setup Microsoft Graph** | **Switch Graph Account**
  - Row 3 (Google GAM7): **Test Google GAM7** | **2. Setup Google GAM7** | **Switch GAM Account**
- **Consolidated Domain & Profile Switching on Tab 1:** Removed the redundant top-bar **Switch Domain / Profile** button from the global header; domain and profile switching is unified via **Tab 1 (`1. Setup`)** (`Manage / AD...` and **Switch AD Account / Domain**).
- **WinForms Ampersand Mnemonic Fix:** Disabled mnemonic `&` shortcut swallowing (`UseMnemonic = $false`) on WinForms buttons and labels so labels such as **Audit M365 & Gmail Rules**, **Wipe Google ASPs & 2SV**, and **Expire AD Account & Restrict Workstations** render `&` literally instead of an underscore.
- **PowerShell 5.1 Compatibility & Runtime Hardening:** Converted 293 conditional subexpression assignments (`= (if ...)` -> `= $(if ...)`), eliminated non-ASCII UTF-8 em-dash quotes, converted child setup here-strings to single-quoted `@' ... '@` templates, and upgraded `Launch-IncidentAutomator.bat` pre-flight AST validation.

## [1.1.54] - 2026-11-12

### Added
- **Multi-Domain Profile Manager (Zero-Friction Single-Domain + Multi-Tenant Switching):**
  - **First-Launch Primary Profile Prompt:** If no Primary Domain Profile is configured yet, prompts on startup whether the current environment is your **Primary (Home) Domain Profile** or if you are temporarily assisting another domain—keeping the clean Primary slot untouched until you return to your home domain.
  - **Seamless Default Mode:** Single-domain technicians stay on their Primary Domain Profile using standard `%USERPROFILE%\.gam` and `%LOCALAPPDATA%\MicrosoftGraphSetup` directories with zero extra steps or prompts.
  - **Isolated Domain Profiles (`%LOCALAPPDATA%\IncidentResponse-Automator\Profiles\<id>`):** Technicians supporting multiple corporate or client domains/tenants can create, rename, set as Primary, switch, and delete named Domain Profiles from the Profile bar on **Tab 1 (`1. Setup`)**.
  - **Isolated GAM7 & Microsoft Graph Per Profile:** Each Domain Profile maintains its own `GAMCFGDIR` (`gam.cfg`, `client_secrets.json`, `oauth2.txt`), `IR_GRAPH_SETUP_DIR` (`Setup.log`, `MailboxAuditorApp.json`), and `MgContext.json` snapshot while preserving cached MSAL tokens across domains so switching back and forth requires no re-authentication after initial setup.
  - **Cloud-Only Switching:** Added **Switch Cloud Only (Skip AD)** in the Domain Profile Switcher for off-VPN or cloud-only triage when an on-prem Domain Controller is unreachable.
- **Dual-Account Admin Support & Tab 1 Account Switchers:**
  - Added `Set-MgGraphOption -DisableLoginByWAM $true` to `Setup-MicrosoftGraph.bat` and **Switch Graph Account** so elevated admin accounts stay decoupled from the workstation's primary Windows user session.
  - Added **Switch Graph Account**, **Switch GAM Account**, and **Switch AD Account / Domain** controls on Tab 1 (`1. Setup`), and automatically clears previously loaded user workspace state when switching profiles.

## [1.1.53] - 2026-11-12

### Added
- **Local EXE Auto-Recompilation on Update (`Show-UpdateCheckWindow`):**
  - When running as compiled `IncidentResponse.exe` without a `.exe` asset on GitHub Releases, **Update & Restart** now downloads the updated `IncidentResponse-Automator.ps1` directly from GitHub, validates PowerShell syntax, compiles `IncidentResponse.exe.new` locally via `PS2EXE` inside the application folder, verifies the PE (`MZ`) header, hot-swaps the executable, and restarts automatically.

### Improved & Fixed
- **SentinelOne-Friendly Hot-Swap & GitHub Cache/Encoding Fixes:**
  - Replaced `-EncodedCommand` swap invocation with clean `-File` scripts staged in the application directory.
  - Added UTF-8 `byte[]` decoding (`$decodeWebContent`) for GitHub API `raw+json` `VERSION` and `CHANGELOG.md` responses in Windows PowerShell 5.1 and resolved the latest `main` commit SHA to bypass the 5-minute `raw.githubusercontent.com` CDN cache.

---

## [1.1.52] - 2026-11-12

### Changed
- Testing Update Feature

---

## [1.1.51] - 2026-11-12

### Added
- **GitHub Self-Updater & Release Notes Viewer (`Show-UpdateCheckWindow` & `Show-ChangelogWindow`):**
  - Added **[Check for Updates]** button to the top console header alongside theme toggle and domain switcher controls, supporting both Light Mode and Dark Mode.
  - Queries GitHub Releases (`releases/latest`) with automatic `VERSION` fallback, displays a colorized status log (`RichTextBox` with clickable repository URLs, green status text when running the latest version, and red status text when an update is available), and disables **Update & Restart** until a newer version is confirmed.
  - Added **[View Changelog]** dialog displaying GitHub release notes or local `CHANGELOG.md` history separately from the update status feed.
  - Implemented verified hot-swap self-replacement for both `Launch-IncidentAutomator.bat` (`.ps1` syntax-validated via PowerShell `Parser::ParseFile`) and compiled `IncidentResponse.exe` (`MZ` PE-header validated) with automatic restart.

### Fixed
- **Microsoft Graph Silent Session Restoration for Delegated Admins:**
  - Updated `Invoke-VerifyGraph`, `Ensure-MgGraphSessionActive`, `Invoke-RevokeMgUserSignInSessionSafe`, and `Invoke-GraphMailboxRestSafe` to silently attach to the cached `CurrentUser` MSAL session and prevent `DeviceCodeCredential` `NullReferenceException` errors on fresh workstations without App-Only registration.
- **Update Dialog Button & Syntax Fixes:**
  - Restored closing block and `ShowDialog` call in `Show-DomainSwitcher` and disabled WinForms mnemonic parsing (`UseMnemonic = $false`) so the **Update & Restart** button displays its ampersand literally.

---

## [1.1.5] - 2026-11-05

### Added
- **Dynamic Multi-Domain Auto-Discovery Engine (`Get-DiscoveredLocalDomainSafe`):**
  - Integrated native Win32/ADSI domain discovery capable of enumerating the current workstation's primary joined domain, forest root domain, and DNS suffix search list.
  - Added dedicated **[Auto-Detect Domain]** button to the Domain & DC Switcher dialog, allowing seamless domain migration for technicians servicing multiple client environments without requiring manual registry edits.
- **Unified Light Mode & Dark Mode Dynamic Theme Engine:**
  - Extended runtime color transformation across the entire application interface, including the top header console panel, title, sub-label, domain switcher, real-time action log, rule inspector, and deciphered event intelligence boxes.
  - Provides high-contrast light theme and dark theme with one-click toggling.
- **Stateful Event Catalog & Query Persistence:**
  - Added state caching to the Security Event Triage deck, enabling incident responders to inspect the comprehensive **Event Code Guide** reference catalog and return directly to previously pulled live events without re-querying domain controllers or cloud endpoints.

---

## [1.1.0] - 2026-11-04

### Added
- **5-Tab Structured Incident Response Architecture (`IncidentResponse-Automator.ps1`):**
  - Modularized the native Windows Forms interface into an intuitive five-stage containment lifecycle:
    - **Tab 1 (`1. Setup`):** Live pre-flight integration status, diagnostic validation tests, and 1-click automated setup script launchers.
    - **Tab 2 (`2. Containment`):** Multi-attribute target user lookup, 4 live security status cards, safety verification gate, and primary containment deck.
    - **Tab 3 (`3. Deep Isolation`):** Comprehensive account isolation deck and mailbox forwarding rules auditor with one-click remediation.
    - **Tab 4 (`4. Event Triage`):** Multi-source security event triage engine querying Active Directory, Microsoft Entra ID, and Google Workspace with plain-English decoders.
    - **Tab 5 (`5. Audit Trail`):** Searchable, filterable compliance audit log recorded locally with CSV field escaping.
- **Instant Microsoft Entra ID Sign-In Blocking (`Set-MgUserSignInEnabledSafe`):**
  - Direct REST patching of `accountEnabled = $false` on `/v1.0/users/{id}` via Microsoft Graph, immediately closing the 30-minute Entra Connect synchronization window when an on-premises account is disabled.
- **Google Workspace Account Suspension (`Set-GamUserSuspendedSafe`):**
  - Orchestration of Google Admin SDK Directory API via GAM7 to suspend user accounts and verify state with multi-pass convergence verification.
- **Persistent Cloud MFA, OAuth Grant, App Password & Backup Code Deprovisioning (`Invoke-WipeCloudMfaAndTokensSafe`):**
  - Simultaneous cloud eviction revoking Microsoft Entra refresh tokens, deleting third-party OAuth2 permission grants, removing SMS/TOTP/FIDO authentication methods, and purging Google application-specific passwords and two-step verification backup codes.
- **Mailbox Forwarding, Auto-Redirect & Hide-Hole Inbox Rules Auditor (`Get-UserForwardingAndInboxRulesSafe` & `Disable-OrRemoveForwardingRuleSafe`):**
  - Deep inspection of Microsoft 365 inbox rules and Google Workspace Gmail forwarding addresses/filters, flagging external exfiltration, stealth auto-delete, and hide-hole routing with one-click single or bulk remediation.
- **Active Directory `accountExpires` KDC Hard-Lock & `userWorkstations` Lockdown (`Set-ADExtendedLockdownSafe`):**
  - Writes elapsed FileTime timestamps to `accountExpires` to force immediate Kerberos KDC ticket rejection (`0x12: KDC_ERR_CLIENT_REVOKED`) and restricts `userWorkstations` to sentinel hostnames to prevent interactive or network logon across the enterprise.
- **Multi-Source Security Event Triage Engine (`Get-UserSecurityEventsSafe` & `Get-DecodedEventIntelligence`):**
  - Real-time ingestion and plain-English decoding of Windows Domain Controller events (4624, 4625, 4740, 4768, 4769, 4771, 4776, 4720-4738, 4648, 4778, 4779), Microsoft Entra ID sign-in telemetry, and Google Workspace security audit records.
- **Single-Threaded Apartment (`-STA`) Auto-Enforcement:**
  - Embedded self-relaunch logic ensuring the script automatically runs in `-STA` mode regardless of whether executed from PowerShell, batch launcher, or compiled executable.

---

## [1.0.5] - 2026-11-03

### Added
- **Multi-Attribute Cloud Identity Candidate Resolver (`Resolve-UserCloudIdentities`):**
  - Correlates on-premises Active Directory accounts with cloud tenants across `userPrincipalName`, `mail`, `sAMAccountName`, and `proxyAddresses` (both primary `SMTP:` and secondary `smtp:` aliases), ensuring reliable session revocation in non-contiguous hybrid namespaces.
- **Live Multi-Provider Security Status Telemetry:**
  - Real-time status cards displaying Active Directory Password Age, Microsoft 365 / Entra Session State, Google Workspace Session State, and Active Directory Account Status.
- **Compliance Audit Trail Engine:**
  - Structured local logging to `C:\ProgramData\IncidentResponse-Automator\AuditLog.csv` with real-time text searching, status filtering, and dedicated inspection dialog.
- **Embedded Self-Extracting Setup Batch Scripts:**
  - Base64-encoded deployment payloads for `Setup-MicrosoftGraph.bat`, `Setup-GoogleWorkspace-GAM.bat`, and `Setup-RSAT-ActiveDirectory.bat` embedded directly within the main script for completely self-contained distribution.

---

## [1.0.0] - 2026-11-02

### Added
- **Core Native Windows Incident Containment Console (`IncidentResponse-Automator.ps1`):**
  - Windows Forms application written in native PowerShell 5.1 / .NET Framework 4.8.
- **Dual-Engine Active Directory Management:**
  - Complete support for user querying, password resets, force password change at logon (`pwdLastSet = 0`), and account disablement using either RSAT Active Directory cmdlets or native .NET `System.DirectoryServices` (LDAP/ADSI).
- **Microsoft Graph Session Revocation:**
  - Interactive device authentication and one-click session invalidation for Microsoft 365, Outlook, Teams, and mobile clients.
- **Google Workspace Session Revocation:**
  - One-click termination of active Google Workspace web cookies and mobile device sessions via GAM7 CLI.
- **Domain & Domain Controller Switcher:**
  - Interactive credential dialog supporting explicit Domain Controller FQDN/IP addresses and alternative administrative credentials for non-domain-joined management stations.
- **Responsive Layout & High-DPI Scaling Engine:**
  - Proportional coordinate calculation and pixel-safe font caching supporting 1080p, 1440p, 4K, and high-DPI workstation displays.
