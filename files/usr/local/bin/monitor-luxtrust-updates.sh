#!/usr/bin/bash

CACHE_FILE="/var/cache/luxtrust-latest-version.txt"
LOG_FILE="/var/log/luxtrust-monitor.log"
STATE_FILE="/var/lib/luxtrust-monitor-state"

# ADD THIS FLAG AT THE TOP
AUTO_UPDATE_ENABLED=true  # Set to false to disable auto-updates

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Ensure directories exist
mkdir -p /var/cache /var/log /var/lib

# Get latest version from GitLab
RESULT=$(/usr/local/bin/get-latest-luxtrust.sh 2>&1)

if [ $? -ne 0 ]; then
    log "ERROR: Failed to check for updates: $RESULT"
    exit 1
fi

VERSION=$(echo "$RESULT" | cut -d'|' -f1)
FILENAME=$(echo "$RESULT" | cut -d'|' -f2)

log "Latest version available: $VERSION"

# Check if Luxtrust is installed at all
INSTALLED=$(rpm -qa | grep luxtrust-middleware || echo "none")

if [ "$INSTALLED" = "none" ]; then
    log "WARNING: Luxtrust middleware is NOT installed"

    # Check if we should auto-install
    if [ -f "$STATE_FILE" ]; then
        ATTEMPTS=$(cat "$STATE_FILE")
        if [ "$ATTEMPTS" -ge 3 ]; then
            log "ERROR: Auto-installation failed 3 times, giving up. Manual intervention required."
            # Notify all users
            for user in $(who | awk '{print $1}' | sort -u); do
                USER_DISPLAY=$(who | grep "^$user " | awk '{print $NF}' | tr -d '()' | head -1)
                if [ -n "$USER_DISPLAY" ]; then
                    sudo -u "$user" DISPLAY="$USER_DISPLAY" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $user)/bus" \
                        notify-send \
                        "❌ Luxtrust Installation Failed" \
                        "Automatic installation failed. Please contact IT support." \
                        --urgency=critical \
                        --icon=dialog-error 2>/dev/null
                fi
            done
            exit 1
        fi
    else
        echo "0" > "$STATE_FILE"
    fi

    log "Attempting automatic installation of version $VERSION..."

    # Download
    DOWNLOAD_URL="https://gitlab.com/LuxTrustPublic/middleware/-/raw/main/${FILENAME}"
    DOWNLOAD_PATH="/tmp/luxtrust-auto-${VERSION}.tar.gz"

    if curl -L -s -o "$DOWNLOAD_PATH" "$DOWNLOAD_URL"; then
        log "Download successful"

        # Install with auto-reboot mode
        if /usr/local/bin/install-luxtrust.sh "$DOWNLOAD_PATH" true; then
            log "Installation staged successfully - system will reboot"
            rm -f "$STATE_FILE"  # Reset failure counter
            rm -f "$DOWNLOAD_PATH"
        else
            log "ERROR: Installation failed"
            echo $(($(cat "$STATE_FILE") + 1)) > "$STATE_FILE"
            rm -f "$DOWNLOAD_PATH"
        fi
    else
        log "ERROR: Download failed"
        echo $(($(cat "$STATE_FILE") + 1)) > "$STATE_FILE"
    fi

    exit 0
fi

# Luxtrust is installed - check for updates
if [ -f "$CACHE_FILE" ]; then
    CACHED_VERSION=$(cat "$CACHE_FILE")

    if [ "$VERSION" != "$CACHED_VERSION" ]; then
        log "NEW VERSION DETECTED: $VERSION (current: $CACHED_VERSION)"

        # NEW: Check if auto-update is enabled
        if [ "$AUTO_UPDATE_ENABLED" = true ]; then
            log "AUTO-UPDATE: Enabled - proceeding with automatic update"

            # Download
            DOWNLOAD_URL="https://gitlab.com/LuxTrustPublic/middleware/-/raw/main/${FILENAME}"
            DOWNLOAD_PATH="/tmp/luxtrust-auto-update-${VERSION}.tar.gz"

            log "AUTO-UPDATE: Downloading version $VERSION..."
            if curl -L -s -o "$DOWNLOAD_PATH" "$DOWNLOAD_URL"; then
                log "AUTO-UPDATE: Download successful"

                # Install with auto-reboot mode
                if /usr/local/bin/install-luxtrust.sh "$DOWNLOAD_PATH" true; then
                    log "AUTO-UPDATE: Update staged successfully - system will reboot"

                    # Notify users about impending reboot
                    for user in $(who | awk '{print $1}' | sort -u); do
                        USER_DISPLAY=$(who | grep "^$user " | awk '{print $NF}' | tr -d '()' | head -1)
                        if [ -n "$USER_DISPLAY" ]; then
                            sudo -u "$user" DISPLAY="$USER_DISPLAY" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $user)/bus" \
                                notify-send \
                                "🔄 Luxtrust Auto-Update" \
                                "Updated to version $VERSION. System will reboot in 1 minute." \
                                --urgency=critical \
                                --icon=system-software-update 2>/dev/null
                        fi
                    done

                    rm -f "$DOWNLOAD_PATH"
                else
                    log "AUTO-UPDATE: ERROR - Installation failed"
                    rm -f "$DOWNLOAD_PATH"
