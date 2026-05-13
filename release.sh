#!/bin/bash
set -euo pipefail

APP_NAME="KeymapOverlay"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build/release"
DMG_OUTPUT="$BUILD_DIR/$APP_NAME.dmg"
ZIP_OUTPUT="$BUILD_DIR/$APP_NAME.zip"
APPCAST_PATH="$PROJECT_DIR/appcast.xml"
GITHUB_REPO="lennyitb/KeymapOverlay"
APP_PATH="$PROJECT_DIR/$APP_NAME/$APP_NAME.app"

SPARKLE_BIN="$HOME/Library/Developer/Xcode/DerivedData/$APP_NAME-*/SourcePackages/artifacts/sparkle/Sparkle/bin"
SPARKLE_BIN=$(echo $SPARKLE_BIN)  # expand glob

usage() {
    echo "Usage: $0 <version>"
    echo ""
    echo "Before running this script:"
    echo "  1. Set the version in Xcode (target → General → Version)"
    echo "  2. Archive (Product → Archive)"
    echo "  3. Distribute → Developer ID → Upload (notarize)"
    echo "  4. Once notarization succeeds, Export the notarized app"
    echo "  5. Run this script with the version number"
    echo ""
    echo "Example: $0 1.2.0"
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

VERSION="$1"

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be semver (e.g. 1.2.0)"
    exit 1
fi

for tool in create-dmg gh; do
    if ! command -v "$tool" &>/dev/null; then
        echo "Error: $tool not found. Install it first."
        exit 1
    fi
done

if [ ! -f "$SPARKLE_BIN/sign_update" ]; then
    echo "Error: Sparkle sign_update not found at $SPARKLE_BIN"
    echo "Build the project in Xcode first so SPM downloads Sparkle."
    exit 1
fi

if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH not found."
    echo "Build and export the notarized app in Xcode first."
    exit 1
fi

echo "==> Releasing $APP_NAME v$VERSION"
echo "    Using app: $APP_PATH"
echo ""

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ── 1. Create DMG ────────────────────────────────────────────────────────────
echo "==> Creating DMG..."
create-dmg \
    --volname "$APP_NAME" \
    --volicon "$PROJECT_DIR/dmg/volume_icon.icns" \
    --background "$PROJECT_DIR/dmg/background.png" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 80 \
    --icon "$APP_NAME.app" 180 200 \
    --app-drop-link 480 200 \
    --hide-extension "$APP_NAME.app" \
    --no-internet-enable \
    "$DMG_OUTPUT" \
    "$APP_PATH"
echo "    DMG: $DMG_OUTPUT"

# ── 2. Create ZIP + Sparkle signature ────────────────────────────────────────
echo "==> Creating signed ZIP for Sparkle..."
ditto -c -k --keepParent "$APP_PATH" "$ZIP_OUTPUT"

SIGNATURE=$("$SPARKLE_BIN/sign_update" "$ZIP_OUTPUT" 2>&1)
ED_SIGNATURE=$(echo "$SIGNATURE" | grep 'sparkle:edSignature=' | sed 's/.*sparkle:edSignature="\([^"]*\)".*/\1/')
ZIP_LENGTH=$(stat -f%z "$ZIP_OUTPUT")

if [ -z "$ED_SIGNATURE" ]; then
    echo "Error: Failed to get EdDSA signature from sign_update"
    echo "Output was: $SIGNATURE"
    echo ""
    echo "Make sure your Sparkle EdDSA private key is in the Keychain."
    echo "If you haven't generated one yet, run:"
    echo "  $SPARKLE_BIN/generate_keys"
    exit 1
fi
echo "    Signed: $ED_SIGNATURE"

# ── 3. Generate appcast.xml ──────────────────────────────────────────────────
echo "==> Generating appcast.xml..."
PUB_DATE=$(date -R)
DOWNLOAD_URL="https://github.com/$GITHUB_REPO/releases/download/v$VERSION/$APP_NAME.zip"

cat > "$APPCAST_PATH" << EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>$APP_NAME Changelog</title>
        <language>en</language>
        <item>
            <title>Version $VERSION</title>
            <pubDate>$PUB_DATE</pubDate>
            <sparkle:version>$VERSION</sparkle:version>
            <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
            <enclosure
                url="$DOWNLOAD_URL"
                length="$ZIP_LENGTH"
                type="application/octet-stream"
                sparkle:edSignature="$ED_SIGNATURE"
            />
        </item>
    </channel>
</rss>
EOF
echo "    Appcast written to $APPCAST_PATH"

# ── 4. Create GitHub Release ─────────────────────────────────────────────────
echo "==> Creating GitHub release v$VERSION..."

git add "$APPCAST_PATH"
git commit -m "release v$VERSION"
git tag "v$VERSION"
git push origin main --tags

gh release create "v$VERSION" \
    --title "v$VERSION" \
    --generate-notes \
    "$DMG_OUTPUT#$APP_NAME.dmg (installer)" \
    "$ZIP_OUTPUT#$APP_NAME.zip (auto-update)"

echo ""
echo "==> Done! Released $APP_NAME v$VERSION"
echo "    GitHub: https://github.com/$GITHUB_REPO/releases/tag/v$VERSION"
echo "    Appcast committed and pushed to main."
echo ""
echo "    Users will see the update via Sparkle within their check interval."
