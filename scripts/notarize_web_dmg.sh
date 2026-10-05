#!/bin/bash
set -e

# ==============================================================================
# Clipmory - Automated Apple Code Signing & Notarization Script
# ==============================================================================
# This script:
# 1. Detects your "Developer ID Application" certificate in Keychain
# 2. Builds Clipmory with Hardened Runtime & secure entitlements
# 3. Codesigns the app and embedded frameworks with a secure Apple timestamp
# 4. Packages the DMG and signs the DMG container
# 5. Submits to Apple Notary Service (xcrun notarytool) and waits for approval
# 6. Cryptographically staples the Apple notarization ticket to the DMG
# 7. Syncs the notarized DMG to the website folder
# ==============================================================================

echo "🔍 [1/6] Detecting Developer ID Application certificate..."

SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -n 1 | sed -n 's/.*"\(.*\)".*/\1/p')

if [ -z "$SIGNING_IDENTITY" ]; then
    echo "❌ Error: No 'Developer ID Application' certificate found in your macOS Keychain."
    echo ""
    echo "💡 How to get it in 30 seconds via Xcode:"
    echo "   1. Open Xcode -> Settings (⌘,) -> Accounts"
    echo "   2. Select your Apple ID: ahelshaba@gmail.com (RMAH9NSZ5G)"
    echo "   3. Click 'Manage Certificates...'"
    echo "   4. Click the '+' button in the bottom-left and choose 'Developer ID Application'"
    echo "   5. Run this script again!"
    exit 1
fi

echo "   ✅ Found Signing Identity: $SIGNING_IDENTITY"

# Notarytool Keychain Profile Name
KEYCHAIN_PROFILE="${NOTARY_PROFILE:-clipmory-notary}"

echo "🔨 [2/6] Building Release binary with Hardened Runtime..."
DERIVED_DATA_PATH="./build/DerivedData-Web"
xcodebuild -project Clipmory.xcodeproj \
    -scheme Clipmory \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    build > /dev/null

BUILD_APP=$(find "$DERIVED_DATA_PATH/Build/Products/Release" -maxdepth 1 -name "*.app" | head -n 1)
DIST_DIR="./dist/web"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/staging"

cp -R "$BUILD_APP" "$DIST_DIR/staging/Clipmory.app"

echo "🔐 [3/6] Deep-signing Clipmory.app with Hardened Runtime & Apple Timestamp..."
# Sign any embedded frameworks first (e.g. Sparkle)
if [ -d "$DIST_DIR/staging/Clipmory.app/Contents/Frameworks" ]; then
    find "$DIST_DIR/staging/Clipmory.app/Contents/Frameworks" -name "*.framework" -o -name "*.dylib" | while read -r item; do
        codesign --force --timestamp --options runtime --sign "$SIGNING_IDENTITY" "$item"
    done
fi

# Sign the main application bundle
codesign --force --deep --timestamp \
    --options runtime \
    --entitlements "Clipmory/Resources/Clipmory.entitlements" \
    --sign "$SIGNING_IDENTITY" \
    "$DIST_DIR/staging/Clipmory.app"

# Verify signature
codesign --verify --deep --strict --verbose=2 "$DIST_DIR/staging/Clipmory.app"
echo "   ✅ Application signature verified."

# Create drag-and-drop link
ln -s /Applications "$DIST_DIR/staging/Applications"

echo "💿 [4/6] Creating & signing Clipmory.dmg..."
DMG_PATH="$DIST_DIR/Clipmory.dmg"
hdiutil create -volname "Clipmory" -srcfolder "$DIST_DIR/staging" -ov -format UDZO "$DMG_PATH" > /dev/null

# Sign the DMG container
codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$DMG_PATH"
echo "   ✅ DMG container signed."

echo "☁️  [5/6] Submitting to Apple Notary Service..."

# Check if keychain profile exists
if ! xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" &>/dev/null; then
    echo "⚠️  Notarytool credentials not found for profile '$KEYCHAIN_PROFILE'."
    echo ""
    echo "👉 Please run this one-time setup command in Terminal with an App-Specific Password:"
    echo "   (Generate an App-Specific Password at https://appleid.apple.com -> Sign-In and Security -> App-Specific Passwords)"
    echo ""
    echo "   xcrun notarytool store-credentials \"$KEYCHAIN_PROFILE\" \\"
    echo "       --apple-id \"ahelshaba@gmail.com\" \\"
    echo "       --team-id \"RMAH9NSZ5G\" \\"
    echo "       --password \"<YOUR-APP-SPECIFIC-PASSWORD>\""
    echo ""
    exit 1
fi

# Submit and wait for Apple's notarization ticket
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$KEYCHAIN_PROFILE" --wait

echo "📎 [6/6] Stapling Apple Notarization Ticket to DMG..."
xcrun stapler staple "$DMG_PATH"
spctl --assess --type open --context context:primary-signature --verbose "$DMG_PATH"

# Create zip copy
ditto -c -k --sequesterRsrc --keepParent "$DIST_DIR/staging/Clipmory.app" "$DIST_DIR/Clipmory.zip"

# Copy to website
if [ -d "../../website" ]; then
    echo "🌐 Copying notarized DMG to website folder..."
    cp "$DMG_PATH" "../../website/Clipmory.dmg"
    cp "$DIST_DIR/Clipmory.zip" "../../website/Clipmory.zip"
fi

# Update local /Applications for testing
rm -rf /Applications/Clipmory.app 2>/dev/null || true
cp -R "$DIST_DIR/staging/Clipmory.app" /Applications/Clipmory.app 2>/dev/null || true

echo ""
echo "🎉 ==========================================================="
echo "🎉 SUCCESS: Clipmory has been fully signed and notarized by Apple!"
echo "🎉 Any Mac can now install and run it without any warnings."
echo "🎉 File ready at: $DMG_PATH"
echo "🎉 ==========================================================="
