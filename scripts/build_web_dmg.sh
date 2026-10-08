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

# Create Applications symlink for drag-and-drop
ln -s /Applications "$DIST_DIR/staging/Applications"

echo "💿 [3/4] Creating Clipmory.dmg..."
hdiutil create -volname "Clipmory" -srcfolder "$DIST_DIR/staging" -ov -format UDZO "$DIST_DIR/Clipmory.dmg" > /dev/null

if [ -n "$DEV_ID" ]; then
    codesign --force --timestamp --sign "$DEV_ID" "$DIST_DIR/Clipmory.dmg" 2>/dev/null || true
fi

ditto -c -k --sequesterRsrc --keepParent "$DIST_DIR/staging/Clipmory.app" "$DIST_DIR/Clipmory.zip"

if [ -d "../../website" ]; then
    echo "🌐 [4/4] Copying to website folder..."
    cp "$DIST_DIR/Clipmory.dmg" "../../website/Clipmory.dmg"
    cp "$DIST_DIR/Clipmory.zip" "../../website/Clipmory.zip"
fi

# Automatically update /Applications so local testing always runs the latest build
rm -rf /Applications/Clipmory.app 2>/dev/null || true
cp -R "$DIST_DIR/staging/Clipmory.app" /Applications/Clipmory.app 2>/dev/null || true

echo "✅ Web build complete! DMG and ZIP available at:"
echo "   - $DIST_DIR/Clipmory.dmg"
echo "   - ../../website/Clipmory.dmg"
