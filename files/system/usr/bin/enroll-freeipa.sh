#!/usr/bin/bash
set -euo pipefail

# FreeIPA Enrollment Script
# Run this after first boot to join the domain

echo "╔════════════════════════════════════════════════╗"
echo "║   FreeIPA Domain Enrollment                    ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# Configuration
DOMAIN="homelab.lan"
REALM="HOMELAB.LAN"
IPA_SERVER="ipa.homelab.lan"

echo "Domain: $DOMAIN"
echo "Server: $IPA_SERVER"
echo ""

# Prompt for admin credentials
read -p "FreeIPA admin username [admin]: " ADMIN_USER
ADMIN_USER=${ADMIN_USER:-admin}

read -sp "FreeIPA admin password: " ADMIN_PASSWORD
echo ""
echo ""

if [ -z "$ADMIN_PASSWORD" ]; then
    echo "❌ Password cannot be empty"
    exit 1
fi

echo "Enrolling to FreeIPA..."
echo ""

# Enroll
if sudo ipa-client-install \
    --domain="$DOMAIN" \
    --realm="$REALM" \
    --server="$IPA_SERVER" \
    --principal="$ADMIN_USER" \
    --password="$ADMIN_PASSWORD" \
    --mkhomedir \
    --unattended \
    --enable-dns-updates \
    --no-ntp; then

    echo ""
    echo "✓ Successfully enrolled to FreeIPA"
    echo ""

    # Configure sudo for admins
    echo "Configuring sudo access..."
    echo "%admins@$DOMAIN ALL=(ALL) ALL" | sudo tee /etc/sudoers.d/ipa-admins >/dev/null
    sudo chmod 440 /etc/sudoers.d/ipa-admins

    echo "✓ Configuration complete"
    echo ""
    echo "⚠️  Please reboot the system"
    echo "   After reboot, users can log in with: username@$DOMAIN"
else
    echo ""
    echo "❌ Enrollment failed"
    echo "   Check network connectivity to $IPA_SERVER"
    exit 1
fi
