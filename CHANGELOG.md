# Changelog

All notable changes to **Security Incident Response Automator** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.69] - 2026-11-19

### Changed
- Testing updater functionality.

## [1.1.68] - 2026-11-19

### Fixed
- **Startup Update Detection (`Start-StartupUpdateCheckAsync`):** Replaced the timer callback's local scriptblock reference with a script-level completion handler (`Invoke-ApplyStartupUpdateCheckResultSafe`), tracked retry timers at script scope, set `$ProgressPreference = 'SilentlyContinue'` in the background worker, and switched release queries to `/releases?per_page=1` so the **`Update Available`** header badge updates automatically on launch.

## [1.1.67] - 2026-11-19

### Changed
- **Break-Glass Reset Dialogs:** Updated the warning text to explicitly state that the Master Passphrase is also wiped, changed **`Continue`** to **`Continue?`** right-aligned beside **`Yes`** / **`No`**, and increased text and button sizes across both confirmation dialogs.

### Fixed
- **Active Directory Password Reset (`Set-ADPasswordSafe`):** Wired `[bool]$RequireChangeAtLogon` so the next-logon password change option sets `pwdLastSet` accurately, and applied RFC 4515 LDAP filter escaping to `$SamAccount`.
- **Microsoft Graph Error Handling (`Invoke-GraphMailboxRestSafe`):** Re-threw non-401 App-Only API errors instead of falling back to interactive delegated prompts.
- **Domain Switcher Credential Purge:** Added an **`Are you sure?`** confirmation dialog to **`Purge Saved`** inside `Show-DomainSwitcher`.
- **GAM7 Setup Scoping:** Scoped `GAMCFGDIR` to the active profile before running the GAM7 setup batch script and refreshed `$script:BaseDefaultGamCfgDir` afterward.
- **Audit Export & Grid Themes:** Added an in-memory/header fallback for CSV exports when `AuditLog.csv` does not yet exist on disk, and disabled `EnableHeadersVisualStyles` so Dark and Light grid column header colors render correctly.
- **Web Companion Update Probe & Profile Sync:** Switched release polling to `/releases?per_page=1` to eliminate `404` responses when no GitHub Release is published, and synced `CredentialHealthPanel` dynamically with custom profiles.

## [1.1.66] - 2026-11-19

### Added
- **Tab 1 Credential Purge Confirmation:** Added an **`Are you sure?`** confirmation dialog before executing **`Purge Saved Creds`**.
- **Scrollable Tab 1 Reference Layout:** Enabled scrolling on Tab 1 and its Integration Setup reference box so content remains accessible on non-fullscreen displays.
- **Theme Cross-Fade Transition:** Added a smooth cross-fade animation when switching between Dark Mode and Light Mode.
- **Expanded Break-Glass Reset Wipe:** Updated **`Remove Passphrase & All Creds`** to clear Domain Profiles, AD DPAPI vaults, `MasterVault.dpapi.json`, `MailboxAuditorApp.json`, Microsoft Graph sessions/caches, and Google GAM7 config/OAuth files (preserving `gam.exe`), gated behind a two-step red warning and final confirmation dialog.

### Fixed
- **Updater Version Persistence & Startup Probing:** Updated GitHub checks to compare both Releases and `main/VERSION` via uncached commit SHA URLs, added post-download version validation, and added a 30-attempt file-lock retry loop during self-replacement.

## [1.1.65] - 2026-11-18

### Changed
- Refined prompt button labels and added dual-channel (`Releases` + `main/VERSION`) update detection plumbing.

## [1.1.64] - 2026-11-18

### Added
- Added CSS View Transitions for smooth Light/Dark theme toggling and multi-provider wipe groundwork in the companion preview.

## [1.1.63] - 2026-11-18

### Changed
- **Contextual Master Passphrase & Primary Profile Prompts:** Converted both dialogs to action-first flows that show only the input fields required for the selected operation.

### Fixed
- **GAM7 Config Discovery & Profile Affinity:** Improved base `GAMCFGDIR` resolution across environment variables and standard install paths without inheriting stale profile paths or overriding working setups with empty directories.

## [1.1.62] - 2026-11-18

### Added
- **Global Master Passphrase & Startup Gate:** Consolidated passphrase protection into a single optional app-wide Master Passphrase in the top-right header with a 2-attempt startup lock and break-glass recovery.

### Fixed
- **Startup Unjoined-Domain Auto-Connect:** Fixed a WinForms `Timer.Add_Tick` scope issue in `Start-StartupADAutoConnectAsync` and prioritized active NIC DNS suffixes so reachable domain profiles connect across AD, Microsoft Graph, and GAM7 automatically on launch.

## [1.1.61] - 2026-11-18

### Added
- **Expanded Event Triage Search & Highlighting:** Extended Tab 4 live search and text highlighting to cover both result grid columns and clicked event detail panels (`RichTextBox`).

### Security
- Zeroed raw decrypted DPAPI buffers and client secret variables after use.
- Enforced single-user NTFS ACLs on `MailboxAuditorApp.json`.
- Added RFC 4515 LDAP filter escaping (`ConvertTo-LdapFilterValueSafe`) and CSV formula-injection neutralization (`Format-CsvSafeField`).
- Restricted self-updater downloads and clickable log links strictly to validated `https://` GitHub endpoints.
- Cleaned up IndexedDB `CryptoKey` entries when the web companion circuit breaker purges rotated credentials.

## [1.1.60] - 2026-11-18

### Added
- Added real-time Event Triage search filtering with live match highlighting in the Summary column.

## [1.1.59] - 2026-11-18

### Added
- **Encrypted Per-Profile AD Credential Vault:** Added Windows DPAPI (`CurrentUser`) encrypted AD credential persistence (`ad_cred.dpapi.json`) with optional passphrase wrapping and Web Crypto AES-256-GCM support in the companion preview.
- **Zero-Credential Network Probe & Auto-Connect:** Added non-blocking DNS SRV + async TCP `389`/`636` domain detection on launch.
- **Credential Health Panel & Anti-Lockout Safeguards:** Added Tab 1 credential diagnostics, Kerberos pre-bind password-age checks, and a 1-strike circuit breaker to purge rotated/invalid secrets before causing account lockouts.

## [1.1.58] - 2026-11-17

### Changed
- Added non-blocking startup update probing and replaced the static header button text with a dynamic **`v<version>`** / **`Update Available`** status indicator.

## [1.1.57] - 2026-11-12

### Changed
- **Tab 3 Cloud Persistence Controls:** Standardized the 5 cloud persistence wipe buttons and tooltips across Microsoft Entra ID and Google Workspace (including Entra Temporary Access Pass removal).
- **High-DPI Modal Scaling & UI Polish:** Added `Invoke-ApplyModalResponsiveScale`, fixed literal `&` rendering in headers/groups, removed dead code, and added a top-right GitHub repository shortcut icon.

## [1.1.56] - 2026-11-12

### Changed
- Reorganized the Tab 1 integration matrix into vertical service columns (Active Directory, Microsoft Graph, Google GAM7) and finalized the 5-button Tab 3 cloud persistence wipe layout.

## [1.1.55] - 2026-11-12

### Added
- Split Tab 3 cloud persistence actions into separate Entra MFA, Entra OAuth, Google 2FA, Google OAuth, and Wipe All buttons.

### Fixed
- Consolidated domain/profile switching into Tab 1, disabled WinForms `&` mnemonic swallowing (`UseMnemonic = $false`), and hardened PowerShell 5.1 compatibility.

## [1.1.54] - 2026-11-12

### Added
- **Multi-Domain Profile Manager:** Added first-launch Primary Profile setup, isolated per-profile `GAMCFGDIR` and Microsoft Graph storage, off-VPN cloud-only switching, and `DisableLoginByWAM $true` support for dual-account admins.

## [1.1.53] - 2026-11-12

### Added
- Added local `PS2EXE` executable recompilation during **Update & Restart** when running as a compiled `.exe`.

### Fixed
- Switched self-update hot-swap execution to staged `-File` scripts, added UTF-8 decoding for GitHub API responses, and resolved `main` commit SHAs to bypass CDN caches.

## [1.1.52] - 2026-11-12

### Changed
- Testing update feature.

## [1.1.51] - 2026-11-12

### Added
- Added the GitHub self-updater, release notes / changelog viewer (`Show-UpdateCheckWindow` and `Show-ChangelogWindow`), and hot-swap restart workflow for `.ps1` and `.exe` builds.

### Fixed
- Added silent `CurrentUser` MSAL session restoration for Microsoft Graph and fixed minor dialog/mnemonic issues.

## [1.1.5] - 2026-11-05

### Added
- Added automatic domain discovery (`Get-DiscoveredLocalDomainSafe`), unified Dark/Light mode theming across controls, and cached Event Guide toggling on Tab 4.

## [1.1.0] - 2026-11-04

### Added
- Introduced the 5-tab WinForms console architecture (`Setup`, `Containment`, `Deep Isolation`, `Event Triage`, `Audit Trail`).
- Added instant Entra ID sign-in blocking, GAM7 suspension with convergence checks, cloud MFA/OAuth wiping, mailbox forwarding rules auditing, Kerberos `accountExpires` hard-locking, multi-source event decoding, and `-STA` auto-enforcement.

## [1.0.5] - 2026-11-03

### Added
- Added multi-attribute cloud identity resolution (`Resolve-UserCloudIdentities`), live telemetry cards, and local CSV compliance audit logging (`C:\ProgramData\IncidentResponse-Automator\AuditLog.csv`).
