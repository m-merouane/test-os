#!/usr/bin/bash
set -euo pipefail

echo "Setting up Luxtrust automation and daily reboot..."

# Make scripts executable
chmod +x /usr/bin/get-latest-luxtrust.sh
chmod +x /usr/bin/install-luxtrust.sh
chmod +x /usr/bin/monitor-luxtrust-updates.sh
chmod +x /usr/bin/evening-reminder.sh
chmod +x /usr/bin/smart-reboot.sh
chmod +x /usr/bin/enroll-freeipa.sh  # ← Add this

# Create necessary directories
mkdir -p /var/cache /var/log /var/lib

# Create initial log files
touch /var/log/luxtrust-monitor.log
touch /var/log/luxtrust-installations.log
touch /var/log/daily-reboot.log
chmod 644 /var/log/luxtrust-*.log /var/log/daily-reboot.log

# Enable timers
systemctl enable luxtrust-monitor.timer
systemctl enable daily-reboot.timer
systemctl enable evening-reminder.timer

echo "✓ Luxtrust automation configured"
echo "✓ Smart daily reboot enabled"
echo "✓ Evening reminder enabled (11 PM)"
echo "✓ FreeIPA enrollment available: just enroll-freeipa"

## How It Works Now:

### Daily Schedule:

#10:00 AM - Luxtrust monitoring checks for updates
#           If found: downloads, installs, stages

#00:00 AM - AUTOMATIC REBOOT (every single night)
#           - Applies any staged rpm-ostree updates
#           - Applies Luxtrust updates
#           - Fresh start for next day

#08:00 AM - Employees arrive to fully updated, rebooted PCs
