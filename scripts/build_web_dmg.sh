#!/bin/bash
set -e

echo "🚀 [1/4] Building Clipmory (Direct Web / DMG Release)..."
DERIVED_DATA_PATH="./build/DerivedData-Web"
xcodebuild -project Clipmory.xcodeproj -scheme Clipmory -configuration Release -destination 'generic/platform=macOS' ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO -derivedDataPath "$DERIVED_DATA_PATH" build

BUILD_APP=$(find "$DERIVED_DATA_PATH/Build/Products/Release" -maxdepth 1 -name "*.app" | head -n 1)
DIST_DIR="./dist/web"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/staging"

echo "📦 [2/4] Packaging Clipmory.app..."
cp -R "$BUILD_APP" "$DIST_DIR/staging/Clipmory.app"
cp "Clipmory/Resources/AppIcon.icns" "$DIST_DIR/staging/Clipmory.app/Contents/Resources/AppIcon.icns"

# Detect Developer ID Application certificate in Keychain (fallback to local ad-hoc)
DEV_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -n 1 | sed -n 's/.*"\(.*\)".*/\1/p')

if [ -n "$DEV_ID" ]; then
    echo "🔐 Signing with Developer ID: $DEV_ID"
    # Sign embedded frameworks first
    if [ -d "$DIST_DIR/staging/Clipmory.app/Contents/Frameworks" ]; then
        find "$DIST_DIR/staging/Clipmory.app/Contents/Frameworks" -name "*.framework" -o -name "*.dylib" | while read -r item; do
            codesign --force --timestamp --options runtime --sign "$DEV_ID" "$item" 2>/dev/null || true
        done
    fi
    codesign -o runtime --timestamp --entitlements "Clipmory/Resources/Clipmory.entitlements" --force --deep --sign "$DEV_ID" "$DIST_DIR/staging/Clipmory.app"
else
    echo "ℹ️  Developer ID Application not in Keychain yet; signing locally with ad-hoc signature (-)"
    codesign -o runtime --entitlements "Clipmory/Resources/Clipmory.entitlements" --force --deep --sign - "$DIST_DIR/staging/Clipmory.app"
fi

echo "💿 [3/4] Creating styled Clipmory.dmg..."
# Generate / verify DMG background assets if needed
if [ ! -f "Clipmory/Resources/DMG/background.tiff" ]; then
    python3 scripts/generate_dmg_assets.py
fi

# Prepare DMG visual styling assets (.background, .DS_Store, VolumeIcon)
mkdir -p "$DIST_DIR/staging/.background"
cp "Clipmory/Resources/DMG/background.tiff" "$DIST_DIR/staging/.background/background.tiff"
if [ -f "Clipmory/Resources/DMG/ds_store" ]; then
    cp "Clipmory/Resources/DMG/ds_store" "$DIST_DIR/staging/.DS_Store"
fi
cp "Clipmory/Resources/AppIcon.icns" "$DIST_DIR/staging/.VolumeIcon.icns"
SetFile -a C "$DIST_DIR/staging" 2>/dev/null || true

if command -v create-dmg &>/dev/null; then
    rm -f "$DIST_DIR/staging/Applications"
    create-dmg \
      --volname "Clipmory" \
      --volicon "Clipmory/Resources/AppIcon.icns" \
      --background "Clipmory/Resources/DMG/background.tiff" \
      --window-pos 200 120 \
      --window-size 660 420 \
      --icon-size 130 \
      --text-size 13 \
      --icon "Clipmory.app" 175 205 \
      --hide-extension "Clipmory.app" \
      --app-drop-link 485 205 \
      --no-internet-enable \
      --overwrite \
      "$DIST_DIR/Clipmory.dmg" \
      "$DIST_DIR/staging"
else
    ln -sf /Applications "$DIST_DIR/staging/Applications"
    hdiutil create -volname "Clipmory" -srcfolder "$DIST_DIR/staging" -ov -format UDZO "$DIST_DIR/Clipmory.dmg" > /dev/null
fi

if [ -n "$DEV_ID" ]; then
    codesign --force --timestamp --sign "$DEV_ID" "$DIST_DIR/Clipmory.dmg" 2>/dev/null || true
fi

ditto -c -k --sequesterRsrc --keepParent "$DIST_DIR/staging/Clipmory.app" "$DIST_DIR/Clipmory.zip"

# Generate and cryptographically sign Sparkle appcast.xml
SPARKLE_BIN=$(find "./build" -name "sign_update" 2>/dev/null | head -n 1)
if [ -f "scripts/sparkle_priv.key" ] && [ -n "$SPARKLE_BIN" ]; then
    echo "✨ Generating Sparkle appcast.xml with EdDSA cryptographic signature..."
    SIGN_OUTPUT=$("$SPARKLE_BIN" -f "scripts/sparkle_priv.key" "$DIST_DIR/Clipmory.zip")
    ED_SIG=$(echo "$SIGN_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')
    ZIP_LEN=$(stat -f%z "$DIST_DIR/Clipmory.zip")
    APP_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$DIST_DIR/staging/Clipmory.app/Contents/Info.plist")
    BUILD_NUM=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$DIST_DIR/staging/Clipmory.app/Contents/Info.plist")
    PUB_DATE=$(date -R 2>/dev/null || date +"%a, %d %b %Y %H:%M:%S %z")

    cat <<EOF > "$DIST_DIR/appcast.xml"
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>Clipmory</title>
        <link>https://clipmory.app/</link>
        <description>Clipmory Updates</description>
        <language>en</language>
        <item>
            <title>Clipmory $APP_VERSION</title>
            <pubDate>$PUB_DATE</pubDate>
            <sparkle:version>$BUILD_NUM</sparkle:version>
            <sparkle:shortVersionString>$APP_VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
            <enclosure url="https://clipmory.app/Clipmory.zip"
                       sparkle:edSignature="$ED_SIG"
                       length="$ZIP_LEN"
                       type="application/octet-stream" />
        </item>
    </channel>
</rss>
EOF
    echo "✅ appcast.xml generated (Version: $APP_VERSION, Build: $BUILD_NUM)"
fi

if [ -d "../../website" ]; then
    echo "🌐 [4/4] Copying to website folder..."
    cp "$DIST_DIR/Clipmory.dmg" "../../website/Clipmory.dmg"
    cp "$DIST_DIR/Clipmory.zip" "../../website/Clipmory.zip"
    if [ -f "$DIST_DIR/appcast.xml" ]; then
        cp "$DIST_DIR/appcast.xml" "../../website/appcast.xml"
        echo "📄 Copied appcast.xml to ../../website/appcast.xml"
    fi
fi

# Automatically clean up old version and install the new one into /Applications
echo "🔄 Installing fresh Clipmory.app into /Applications..."
pkill -x Clipmory 2>/dev/null || true
sleep 0.5
rm -rf /Applications/Clipmory.app
cp -R "$DIST_DIR/staging/Clipmory.app" /Applications/Clipmory.app
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -R /Applications/Clipmory.app 2>/dev/null || true
echo "✨ Successfully replaced /Applications/Clipmory.app with the latest build."

echo "✅ Web build complete! Artifacts available at:"
echo "   - $DIST_DIR/Clipmory.dmg"
echo "   - $DIST_DIR/Clipmory.zip"
echo "   - $DIST_DIR/appcast.xml"
if [ -d "../../website" ]; then
    echo "   - ../../website/appcast.xml"
fi
