#!/usr/bin/bash
set -euo pipefail

TARBALL_PATH="$1"
AUTO_MODE="${2:-false}"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

if [ ! -f "$TARBALL_PATH" ]; then
    log "ERROR: File not found: $TARBALL_PATH"
    exit 1
fi

# Extract version
VERSION=$(basename "$TARBALL_PATH" | grep -oP '\d+\.\d+\.\d+')
log "Installing Luxtrust Middleware version $VERSION"

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

log "Extracting to $TEMP_DIR..."
tar -xzf "$TARBALL_PATH" -C "$TEMP_DIR"

cd "$TEMP_DIR"

# Find the RPMs
GEMALTO_RPM=$(ls Gemalto_Middleware_*.rpm 2>/dev/null | head -1)
LUXTRUST_RPM=$(ls luxtrust-middleware-*.rpm 2>/dev/null | head -1)

if [ -z "$GEMALTO_RPM" ] || [ -z "$LUXTRUST_RPM" ]; then
    log "ERROR: Could not find required RPMs"
    log "Contents:"
    ls -la
    exit 1
fi

log "Found RPMs:"
log "  - Gemalto: $GEMALTO_RPM"
log "  - LuxTrust: $LUXTRUST_RPM"

# Check current installation
CURRENT_GEMALTO=$(rpm -qa | grep -i gemalto || echo "none")
CURRENT_LUXTRUST=$(rpm -qa | grep -i luxtrust-middleware || echo "none")

log "Current installation:"
log "  - Gemalto: $CURRENT_GEMALTO"
log "  - LuxTrust: $CURRENT_LUXTRUST"

# Install in correct order
log ""
log "Step 1: Installing Gemalto Middleware..."
if ! rpm-ostree install "$TEMP_DIR/$GEMALTO_RPM"; then
    log "ERROR: Failed to install Gemalto middleware"
    exit 1
fi

log "Step 2: Installing LuxTrust Middleware..."
if ! rpm-ostree install "$TEMP_DIR/$LUXTRUST_RPM"; then
    log "ERROR: Failed to install LuxTrust middleware"
    exit 1
fi

log ""
log "✓ Luxtrust Middleware $VERSION staged successfully"
log ""

# Log the installation
LOG_FILE="/var/log/luxtrust-installations.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Installed version $VERSION (Gemalto: $GEMALTO_RPM, LuxTrust: $LUXTRUST_RPM)" | sudo tee -a "$LOG_FILE" > /dev/null

if [ "$AUTO_MODE" = "true" ]; then
    log "⚠️  System will reboot automatically in 60 seconds..."
    log "   (Cancel with: sudo shutdown -c)"
    sudo shutdown -r +1 "Luxtrust middleware installed, rebooting..."
else
    log "⚠️  REBOOT REQUIRED to activate Luxtrust Middleware"
    log "   Run: systemctl reboot"
fi
