#!/bin/bash
set -euo pipefail

NAME="Purble"
BUNDLE_ID="com.purble.app"   # change to your own reverse-domain id
VERSION="1.0"

cd "$(dirname "$0")"

echo "==> Building release binary"
swift build -c release
BIN="$(swift build -c release --show-bin-path)/$NAME"

echo "==> Assembling $NAME.app"
APP="dist/$NAME.app"
rm -rf dist
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$NAME"
cp bin/7zz "$APP/Contents/Resources/7zz"
chmod +x "$APP/Contents/Resources/7zz"
if [ -f AppIcon.icns ]; then
  cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
else
  echo "   (no AppIcon.icns in project root, app will use the generic icon)"
fi
[ -f bin/License.txt ] && cp bin/License.txt "$APP/Contents/Resources/7-Zip-License.txt" \
  || echo "   (no bin/License.txt, add 7-Zip's license before publishing)"

cat > "$APP/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$NAME</string>
    <key>CFBundleDisplayName</key><string>$NAME</string>
    <key>CFBundleExecutable</key><string>$NAME</string>
        <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
EOF

echo "==> Signing (ad-hoc)"
xattr -cr "$APP"
codesign --force --sign - "$APP/Contents/Resources/7zz"
codesign --force --sign - "$APP"

echo "==> Zipping"
ditto -c -k --keepParent "$APP" "dist/$NAME.zip"

echo "Done: dist/$NAME.app and dist/$NAME.zip"