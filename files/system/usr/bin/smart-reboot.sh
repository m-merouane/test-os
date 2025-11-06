#!/usr/bin/bash

LOG_FILE="/var/log/daily-reboot.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Get current hour (0-23)
CURRENT_HOUR=$(date +%H)

# Only reboot if it's between 11 PM (23) and 6 AM (06)
# This handles both the scheduled midnight reboot AND catch-up reboots
if [ "$CURRENT_HOUR" -ge 23 ] || [ "$CURRENT_HOUR" -lt 6 ]; then
    log "Nighttime reboot: Initiating reboot now"
    systemctl reboot
else
    log "Daytime hours detected (${CURRENT_HOUR}:00) - scheduling reboot for midnight instead"

    # Cancel any existing scheduled reboots
    shutdown -c 2>/dev/null || true

    # Schedule for midnight
    shutdown -r 00:00 "Daily maintenance reboot"

    log "Reboot scheduled for midnight (00:00)"
fi
