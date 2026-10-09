# Build and Install Rule

When the user asks to build and/or install the app:
1. Always terminate any running Clipmory process first (`pkill -x Clipmory 2>/dev/null || true`).
2. Always remove the existing old version completely: `rm -rf /Applications/Clipmory.app`.
3. Copy/install the fresh build cleanly into `/Applications/Clipmory.app`.
