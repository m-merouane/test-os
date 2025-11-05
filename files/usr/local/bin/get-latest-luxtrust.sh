#!/usr/bin/bash
set -euo pipefail

PROJECT_ID="LuxTrustPublic%2Fmiddleware"

# Get file list from GitLab
FILES=$(curl -s "https://gitlab.com/api/v4/projects/${PROJECT_ID}/repository/tree?ref=main")

# Find the Fedora 64bit file
LATEST_FILE=$(echo "$FILES" | jq -r '.[] | select(.name | contains("Fedora_64bit.tar.gz")) | .name')

if [ -z "$LATEST_FILE" ]; then
    echo "ERROR: Could not find Luxtrust Fedora middleware" >&2
    exit 1
fi

# Extract version number
VERSION=$(echo "$LATEST_FILE" | grep -oP '\d+\.\d+\.\d+')

# Output: VERSION|FILENAME
echo "$VERSION|$LATEST_FILE"
