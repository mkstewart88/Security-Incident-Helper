## Summary of Changes
Describe what this Pull Request adds, fixes, or improves:

## Verification Checklist
- [ ] I have read and agreed to [DISCLAIMER.md](DISCLAIMER.md), [CONTRIBUTING.md](CONTRIBUTING.md), and [LICENSE](LICENSE).
- [ ] All PowerShell and Batch files (`IncidentResponse-Automator.ps1`, `*.bat`, `*.cmd`) contain **pure ASCII** characters (0 non-ASCII bytes) and balanced braces.
- [ ] PowerShell AST syntax check (`[System.Management.Automation.Language.Parser]::ParseFile`) passes with **0 errors**.
- [ ] Active Directory operations support both the `ActiveDirectory` RSAT module and the native `.NET System.DirectoryServices` LDAP fallback.
- [ ] If any `Setup-*.bat` file was modified, its embedded Base64 payload (`$script:Embedded*BatB64`) inside `IncidentResponse-Automator.ps1` was updated to match byte-for-byte.
- [ ] Zero organization-specific domains, real usernames, credentials, or PII are included in this PR.
