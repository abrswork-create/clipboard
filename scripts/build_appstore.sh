#!/bin/bash
set -e

echo "🍎 [1/3] Building Clipmory for Mac App Store (Sandbox + StoreKit 2)..."
DERIVED_DATA_PATH="./build/DerivedData-AppStore"
xcodebuild -project ClipFlow.xcodeproj -scheme ClipFlow -configuration Release -destination 'platform=macOS' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    SWIFT_ACTIVE_COMPILATION_CONDITIONS="APP_STORE" \
    CODE_SIGN_ENTITLEMENTS="ClipFlow/Resources/ClipFlow-AppStore.entitlements" \
    OTHER_LDFLAGS='$(inherited) -Xlinker -weak_framework -Xlinker Sparkle' \
    build

BUILD_APP=$(find "$DERIVED_DATA_PATH/Build/Products/Release" -maxdepth 1 -name "*.app" | head -n 1)
DIST_DIR="./dist/appstore"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "🔒 [2/3] Preparing App Store build & stripping Sparkle updater..."
cp -R "$BUILD_APP" "$DIST_DIR/Clipmory.app"

# Remove Sparkle (Prohibited in App Store; App Store handles all updates natively)
rm -rf "$DIST_DIR/Clipmory.app/Contents/Frameworks/Sparkle.framework"
/usr/libexec/PlistBuddy -c "Delete :SUFeedURL" "$DIST_DIR/Clipmory.app/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Delete :SUEnableAutomaticChecks" "$DIST_DIR/Clipmory.app/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Delete :SUScheduledCheckInterval" "$DIST_DIR/Clipmory.app/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Delete :SUPublicEDKey" "$DIST_DIR/Clipmory.app/Contents/Info.plist" 2>/dev/null || true

# Re-sign stripped bundle for local sandbox testing
codesign --force --sign - --entitlements "ClipFlow/Resources/ClipFlow-AppStore.entitlements" "$DIST_DIR/Clipmory.app"
codesign -d --entitlements :- "$DIST_DIR/Clipmory.app"

ditto -c -k --sequesterRsrc --keepParent "$DIST_DIR/Clipmory.app" "$DIST_DIR/Clipmory-AppStore.zip"

echo "✅ [3/3] App Store build ready at:"
echo "   - $DIST_DIR/Clipmory.app"
echo "   - $DIST_DIR/Clipmory-AppStore.zip"
echo ""
echo "👉 To upload to App Store Connect / TestFlight:"
echo "   1. Open ClipFlow.xcodeproj in Xcode."
echo "   2. Select Product > Archive (with your Apple Developer Team ID selected)."
echo "   3. Click 'Distribute App' > 'App Store Connect'."
