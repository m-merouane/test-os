# Check Luxtrust status
check-luxtrust:
    #!/usr/bin/bash
    echo "╔═══════════════════════════════════════════════╗"
    echo "║   Luxtrust Middleware Status                  ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo ""

    # Check if installed
    echo "📦 Installed packages:"
    GEMALTO=$(rpm -qa | grep -i gemalto || echo "  ❌ Gemalto: Not installed")
    LUXTRUST=$(rpm -qa | grep -i luxtrust-middleware || echo "  ❌ LuxTrust: Not installed")

    if [ "$GEMALTO" != "  ❌ Gemalto: Not installed" ]; then
        echo "  ✓ $GEMALTO"
    else
        echo "$GEMALTO"
    fi

    if [ "$LUXTRUST" != "  ❌ LuxTrust: Not installed" ]; then
        echo "  ✓ $LUXTRUST"
    else
        echo "$LUXTRUST"
    fi

    echo ""
    echo "🌐 Latest available version:"
    RESULT=$(/usr/bin/get-latest-luxtrust.sh 2>&1)
    if [ $? -eq 0 ]; then
        VERSION=$(echo "$RESULT" | cut -d'|' -f1)
        echo "  Version: $VERSION"

        # Compare versions
        if echo "$LUXTRUST" | grep -q "$VERSION"; then
            echo "  ✓ You have the latest version"
        elif [ "$LUXTRUST" = "  ❌ LuxTrust: Not installed" ]; then
            echo "  ⚠️  Not installed - run: just install-luxtrust"
        else
            echo "  ⚠️  Update available - run: just update-luxtrust"
        fi
    else
        echo "  ❌ Unable to check (network issue?)"
    fi

    echo ""
    echo "📝 Recent installation log:"
    tail -n 3 /var/log/luxtrust-installations.log 2>/dev/null || echo "  No installations logged yet"

# Download and install latest Luxtrust (works for initial install AND updates)
update-luxtrust:
    #!/usr/bin/bash
    set -euo pipefail

    echo "╔═══════════════════════════════════════════════╗"
    echo "║   Luxtrust Middleware Auto-Installer          ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo ""

    # Get latest version info
    echo "🔍 Checking for latest version..."
    RESULT=$(/usr/bin/get-latest-luxtrust.sh)
    VERSION=$(echo "$RESULT" | cut -d'|' -f1)
    FILENAME=$(echo "$RESULT" | cut -d'|' -f2)

    echo "✓ Latest version: $VERSION"
    echo ""

    # Check current installation
    CURRENT=$(rpm -qa | grep luxtrust-middleware || echo "none")
    if [ "$CURRENT" != "none" ]; then
        echo "Current installation: $CURRENT"
        echo ""
        read -p "Continue with update? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled"
            exit 0
        fi
    else
        echo "ℹ️  No current installation detected - performing initial installation"
    fi

    # Download
    DOWNLOAD_URL="https://gitlab.com/LuxTrustPublic/middleware/-/raw/main/${FILENAME}"
    DOWNLOAD_PATH="/tmp/luxtrust-${VERSION}.tar.gz"

    echo ""
    echo "📥 Downloading from GitLab..."
    if ! curl -L --progress-bar -o "$DOWNLOAD_PATH" "$DOWNLOAD_URL"; then
        echo "❌ Download failed"
        exit 1
    fi

    echo ""
    echo "🔧 Installing Luxtrust Middleware $VERSION..."
    echo ""

    # Run installation script
    sudo /usr/bin/install-luxtrust.sh "$DOWNLOAD_PATH"

    # Cleanup
    rm -f "$DOWNLOAD_PATH"

# Install Luxtrust from a downloaded file
install-luxtrust FILE_PATH="":
    #!/usr/bin/bash
    set -euo pipefail

    # If no file specified, look in Downloads
    if [ -z "{{FILE_PATH}}" ]; then
        echo "Looking for Luxtrust in ~/Downloads/..."
        FILE_PATH=$(ls -t ~/Downloads/LuxTrust_Middleware_*_Fedora_64bit.tar.gz 2>/dev/null | head -1)

        if [ -z "$FILE_PATH" ]; then
            echo "❌ No Luxtrust file found in ~/Downloads/"
            echo ""
            echo "Usage:"
            echo "  just install-luxtrust /path/to/file.tar.gz"
            echo "  OR download to ~/Downloads/ and run: just install-luxtrust"
            echo ""
            echo "To download latest automatically: just update-luxtrust"
            exit 1
        fi

        echo "✓ Found: $(basename $FILE_PATH)"
    else
        FILE_PATH="{{FILE_PATH}}"

        if [ ! -f "$FILE_PATH" ]; then
            echo "❌ File not found: $FILE_PATH"
            exit 1
        fi
    fi

    echo ""
    sudo /usr/bin/install-luxtrust.sh "$FILE_PATH"
