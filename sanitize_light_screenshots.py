import subprocess
import os

images = [
    ('public/assets/aistudio/image_a90a8aff.png', 'docs/screenshots/tab1-integrations-setup-light.png', True),
    ('public/assets/aistudio/image_77e11a60.png', 'docs/screenshots/tab2-incident-containment-light.png', False),
    ('public/assets/aistudio/image_fe314dbd.png', 'docs/screenshots/tab3-deep-isolation-mailbox-rules-light.png', False),
    ('public/assets/aistudio/image_b89c8020.png', 'docs/screenshots/tab4-security-event-triage-light.png', False),
    ('public/assets/aistudio/image_15c1cd51.png', 'docs/screenshots/tab5-forensic-audit-trail-light.png', False),
]

font_name = 'Noto-Sans-Regular'

for src, dst, is_tab1 in images:
    cmd = ['convert', src]
    
    # 1. Erase old subheader completely (y=68 to y=96)
    cmd.extend([
        '-fill', '#f1f5f9', '-draw', 'rectangle 18,68 520,96',
        '-font', font_name, '-pointsize', '11', '-fill', '#475569',
        '-draw', "text 20,84 'Domain: contoso.com | Operator: contoso\\secops.admin'"
    ])

    # 2. Erase Tab 1 Integration Status box completely (y=170 to y=285)
    if is_tab1:
        cmd.extend([
            '-fill', '#ffffff', '-draw', 'rectangle 30,170 950,285',
            '-font', font_name, '-pointsize', '11', '-fill', '#334155',
            '-draw', "text 42,192 'Active Directory: Checking connection mode...'",
            '-draw', "text 42,216 'Microsoft Graph SDK Auth: Checking...'",
            '-draw', "text 42,240 'Google Apps Manager (GAM7): Checking...'"
        ])

    # 3. Erase Real-Time Action Log box completely (y=778 to y=892)
    cmd.extend([
        '-fill', '#ffffff', '-draw', 'rectangle 30,778 950,892',
        '-font', font_name, '-pointsize', '11', '-fill', '#0f172a',
        '-draw', "text 40,798 '[2026-11-05 10:18:02] [INFO] Incident Response Automator GUI loaded. Running Pre-Flight Verification...'"
    ])

    cmd.append(dst)
    print(f"Processing {src} -> {dst}...")
    subprocess.check_call(cmd)

print("Sanitization completed successfully.")
