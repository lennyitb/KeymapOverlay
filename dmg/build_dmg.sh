#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="KeymapOverlay"
DMG_NAME="${APP_NAME}.dmg"
OUTPUT_DIR="${PROJECT_DIR}/dmg/output"

# Find the built .app — prefer Release, fall back to Debug
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
APP_PATH=$(find "$DERIVED_DATA" -path "*/${APP_NAME}-*/Build/Products/Release/${APP_NAME}.app" -maxdepth 5 2>/dev/null | head -1)
if [ -z "$APP_PATH" ]; then
    APP_PATH=$(find "$DERIVED_DATA" -path "*/${APP_NAME}-*/Build/Products/Debug/${APP_NAME}.app" -maxdepth 5 2>/dev/null | head -1)
fi

if [ -z "$APP_PATH" ]; then
    echo "Error: Could not find ${APP_NAME}.app in DerivedData. Build the app in Xcode first."
    exit 1
fi

echo "Using app: $APP_PATH"

mkdir -p "$OUTPUT_DIR"
rm -f "${OUTPUT_DIR}/${DMG_NAME}"

create-dmg \
    --volname "$APP_NAME" \
    --volicon "${SCRIPT_DIR}/volume_icon.icns" \
    --background "${SCRIPT_DIR}/background.png" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 80 \
    --icon "$APP_NAME.app" 180 200 \
    --app-drop-link 480 200 \
    --hide-extension "$APP_NAME.app" \
    --no-internet-enable \
    "${OUTPUT_DIR}/${DMG_NAME}" \
    "$APP_PATH"

echo ""
echo "DMG created: ${OUTPUT_DIR}/${DMG_NAME}"
