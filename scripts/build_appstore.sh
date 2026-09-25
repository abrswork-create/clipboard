#!/bin/bash
set -e

echo "🍎 [1/3] Building Clipmory for Mac App Store (Sandbox + StoreKit 2)..."
DERIVED_DATA_PATH="./build/DerivedData-AppStore"
xcodebuild -project ClipFlow.xcodeproj -scheme ClipFlow -configuration Release -destination 'platform=macOS' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    SWIFT_ACTIVE_COMPILATION_CONDITIONS="APP_STORE" \
    CODE_SIGN_ENTITLEMENTS="ClipFlow/Resources/ClipFlow-AppStore.entitlements" \
    build

BUILD_APP="$DERIVED_DATA_PATH/Build/Products/Release/ClipFlow.app"
DIST_DIR="./dist/appstore"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "🔒 [2/3] Verifying App Sandbox entitlements..."
cp -R "$BUILD_APP" "$DIST_DIR/Clipmory.app"

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
