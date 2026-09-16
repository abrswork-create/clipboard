#!/bin/bash
set -e

echo "🚀 [1/4] Building Clipmory (Direct Web / DMG Release)..."
xcodebuild -project ClipFlow.xcodeproj -scheme ClipFlow -configuration Release -destination 'platform=macOS' build > /dev/null

BUILD_APP="/Users/owel/Library/Developer/Xcode/DerivedData/ClipFlow-elmwtrcpaaulkrhjsflimlcgqtrb/Build/Products/Release/ClipFlow.app"
DIST_DIR="./dist/web"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/staging"

echo "📦 [2/4] Packaging Clipmory.app..."
cp -R "$BUILD_APP" "$DIST_DIR/staging/Clipmory.app"

# Sign with hardened runtime & entitlements
codesign -o runtime --entitlements "ClipFlow/Resources/ClipFlow.entitlements" --force --deep --sign - "$DIST_DIR/staging/Clipmory.app"

# Create Applications symlink for drag-and-drop
ln -s /Applications "$DIST_DIR/staging/Applications"

echo "💿 [3/4] Creating Clipmory.dmg..."
hdiutil create -volname "Clipmory" -srcfolder "$DIST_DIR/staging" -ov -format UDZO "$DIST_DIR/Clipmory.dmg" > /dev/null

ditto -c -k --sequesterRsrc --keepParent "$DIST_DIR/staging/Clipmory.app" "$DIST_DIR/Clipmory.zip"

echo "🌐 [4/4] Copying to website folder..."
cp "$DIST_DIR/Clipmory.dmg" "../../website/Clipmory.dmg"
cp "$DIST_DIR/Clipmory.zip" "../../website/Clipmory.zip"

echo "✅ Web build complete! DMG and ZIP available at:"
echo "   - $DIST_DIR/Clipmory.dmg"
echo "   - ../../website/Clipmory.dmg"
