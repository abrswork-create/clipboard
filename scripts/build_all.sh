#!/bin/bash
set -e

echo "========================================================"
echo "🚀 Building ALL Clipmory Distributions (Web & App Store)"
echo "========================================================"
echo ""

# 1. Build Direct Web / DMG Release
./scripts/build_web_dmg.sh

echo ""
echo "--------------------------------------------------------"
echo ""

# 2. Build Mac App Store Release (Sandbox + StoreKit 2)
./scripts/build_appstore.sh

echo ""
echo "========================================================"
echo "🎉 ALL BUILDS COMPLETED SUCCESSFULLY!"
echo "========================================================"
echo ""
echo "📁 Output Files:"
echo "   1. Web DMG (for your site):"
echo "      - dist/web/Clipmory.dmg"
echo "      - ../../website/Clipmory.dmg"
echo ""
echo "   2. App Store Target (for Apple submission):"
echo "      - dist/appstore/Clipmory.app"
echo "========================================================"
