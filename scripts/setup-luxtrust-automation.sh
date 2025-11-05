#!/usr/bin/bash
set -euo pipefail

echo "Setting up Luxtrust automation..."

# Make scripts executable
chmod +x /usr/local/bin/get-latest-luxtrust.sh
chmod +x /usr/local/bin/install-luxtrust.sh
chmod +x /usr/local/bin/monitor-luxtrust-updates.sh

# Create necessary directories
mkdir -p /var/cache /var/log /var/lib

# Create initial log file
touch /var/log/luxtrust-monitor.log
touch /var/log/luxtrust-installations.log
chmod 644 /var/log/luxtrust-*.log

# Enable the timer (but don't start - will start on next boot)
systemctl enable luxtrust-monitor.timer

echo "✓ Luxtrust automation configured"
echo "  - Daily monitoring enabled"
echo "  - Auto-install on first boot enabled"
echo "  - Timer will run daily at 10:00 AM"
