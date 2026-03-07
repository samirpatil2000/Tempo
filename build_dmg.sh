#!/bin/bash
set -e

APP_NAME="Tempo"
BUNDLE_ID="com.samirpatil.Tempo"
DEPLOY_TARGET="13.0"

echo "🧹 Cleaning up old build..."
rm -rf build
mkdir -p build/${APP_NAME}.app/Contents/MacOS
mkdir -p build/${APP_NAME}.app/Contents/Resources

echo "🔨 Compiling Swift files..."
swiftc \
  -sdk $(xcrun --show-sdk-path --sdk macosx) \
  -target $(uname -m)-apple-macosx${DEPLOY_TARGET} \
  -parse-as-library \
  -framework Cocoa \
  -framework SwiftUI \
  -framework AVFoundation \
  -framework CoreImage \
  Tempo/*.swift Tempo/Models/*.swift Tempo/Processing/*.swift Tempo/Views/*.swift \
  -o build/${APP_NAME}.app/Contents/MacOS/${APP_NAME}

echo "📋 Creating resolved Info.plist..."
cat > build/${APP_NAME}.app/Contents/Info.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>Tempo</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIconName</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>com.samirpatil.Tempo</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>Tempo</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>NSHumanReadableCopyright</key>
	<string>Copyright © 2026. All rights reserved.</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>CFBundleDocumentTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeName</key>
			<string>Video</string>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
			<key>LSHandlerRank</key>
			<string>Alternate</string>
			<key>LSItemContentTypes</key>
			<array>
				<string>public.movie</string>
				<string>public.mpeg-4</string>
				<string>com.apple.quicktime-movie</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
PLIST

echo "🎨 Compiling Assets..."
xcrun actool Tempo/Assets.xcassets \
  --compile build/${APP_NAME}.app/Contents/Resources \
  --platform macosx \
  --minimum-deployment-target ${DEPLOY_TARGET} \
  --app-icon AppIcon \
  --output-partial-info-plist build/partial.plist 2>/dev/null

echo "📦 Writing PkgInfo..."
echo "APPL????" > build/${APP_NAME}.app/Contents/PkgInfo

echo "🔏 Code signing..."
codesign --force --deep --sign - --entitlements Tempo/Tempo.entitlements build/${APP_NAME}.app

echo "🧼 Removing quarantine attribute..."
xattr -cr build/${APP_NAME}.app

echo "💿 Creating DMG..."
# Stage DMG contents with Applications symlink for drag-to-install
mkdir -p build/dmg_staging
rm -rf build/dmg_staging/*
cp -R build/${APP_NAME}.app build/dmg_staging/
ln -sf /Applications build/dmg_staging/Applications

hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder build/dmg_staging \
  -ov \
  -format UDZO \
  build/${APP_NAME}.dmg

rm -rf build/dmg_staging

echo "🧼 Removing quarantine from DMG..."
xattr -cr build/${APP_NAME}.dmg

echo ""
echo "✅ Done! DMG is located at: build/${APP_NAME}.dmg"
echo "   Open the DMG and drag Tempo.app to Applications before running it."
