#!/bin/bash
set -e

APP_NAME="${APP_NAME:-Tempo}"
BUNDLE_ID="${BUNDLE_ID:-com.samirpatil.Tempo}"
DEPLOY_TARGET="${DEPLOY_TARGET:-13.0}"

echo "📦 Loading environment..."
if [ -f .env ]; then
  set -a # automatically export all variables
  source .env
  set +a
fi

BUILD_DIR="build"

echo "🧹 Cleaning..."
rm -rf build dmg_* ${APP_NAME}_*.dmg ${APP_NAME}_*.zip

mkdir -p ${BUILD_DIR}

echo "🔨 Compiling Swift for arm64 (Apple Silicon)..."
swiftc \
  -sdk $(xcrun --show-sdk-path --sdk macosx) \
  -target arm64-apple-macosx${DEPLOY_TARGET} \
  -parse-as-library \
  -framework Cocoa \
  -framework SwiftUI \
  -framework AVFoundation \
  -framework CoreImage \
  -framework ImageIO \
  Tempo/*.swift Tempo/Models/*.swift Tempo/Processing/*.swift Tempo/Services/*.swift Tempo/Views/*.swift \
  -o ${BUILD_DIR}/${APP_NAME}_arm64

echo "🔨 Compiling Swift for x86_64 (Intel)..."
swiftc \
  -sdk $(xcrun --show-sdk-path --sdk macosx) \
  -target x86_64-apple-macosx${DEPLOY_TARGET} \
  -parse-as-library \
  -framework Cocoa \
  -framework SwiftUI \
  -framework AVFoundation \
  -framework CoreImage \
  -framework ImageIO \
  Tempo/*.swift Tempo/Models/*.swift Tempo/Processing/*.swift Tempo/Services/*.swift Tempo/Views/*.swift \
  -o ${BUILD_DIR}/${APP_NAME}_x86_64

package_app() {
    local ARCH_BIN=$1
    local SUFFIX=$2
    
    echo ""
    echo "======================================"
    echo "🚀 Packaging ${APP_NAME} for ${SUFFIX}..."
    echo "======================================"
    
    local ARCH_BUILD_DIR="${BUILD_DIR}/${SUFFIX}"
    local APP_DIR="${ARCH_BUILD_DIR}/${APP_NAME}.app"
    local DMG_DIR="dmg_${SUFFIX}"
    local DMG_NAME="${APP_NAME}_${SUFFIX}.dmg"
    
    mkdir -p ${ARCH_BUILD_DIR}
    mkdir -p ${APP_DIR}/Contents/MacOS
    mkdir -p ${APP_DIR}/Contents/Resources
    
    cp ${ARCH_BIN} ${APP_DIR}/Contents/MacOS/${APP_NAME}
    
    echo "📋 Creating Info.plist..."
    cat > ${APP_DIR}/Contents/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>${APP_NAME}</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIconName</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>${BUNDLE_ID}</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>${APP_NAME}</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>2.0.0</string>
	<key>CFBundleVersion</key>
	<string>2</string>
	<key>LSMinimumSystemVersion</key>
	<string>${DEPLOY_TARGET}</string>
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
		<dict>
			<key>CFBundleTypeName</key>
			<string>Image</string>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
			<key>LSHandlerRank</key>
			<string>Alternate</string>
			<key>LSItemContentTypes</key>
			<array>
				<string>public.jpeg</string>
				<string>public.png</string>
				<string>public.heic</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
EOF

    echo "🎨 Compiling Assets..."
    xcrun actool Tempo/Assets.xcassets \
      --compile ${APP_DIR}/Contents/Resources \
      --platform macosx \
      --minimum-deployment-target ${DEPLOY_TARGET} \
      --app-icon AppIcon \
      --output-partial-info-plist ${BUILD_DIR}/partial_${SUFFIX}.plist 2>/dev/null

    echo "📦 Creating PkgInfo..."
    echo "APPL????" > ${APP_DIR}/Contents/PkgInfo

    echo "🔏 Signing..."
    SIGN_OK=false
    for attempt in 1 2 3; do
        if [ -n "$SIGN_IDENTITY" ]; then
            if codesign \
                --force \
                --deep \
                --timestamp \
                --options runtime \
                --sign "${SIGN_IDENTITY}" \
                --entitlements Tempo/Tempo.entitlements \
                ${APP_DIR}; then
                SIGN_OK=true
                break
            fi
        else
            if codesign --force --deep --sign - --entitlements Tempo/Tempo.entitlements ${APP_DIR}; then
                SIGN_OK=true
                break
            fi
        fi
        echo "⚠️  Signing attempt ${attempt} failed (timestamp server unreachable?), retrying in 3s..."
        sleep 3
    done
    if [ "$SIGN_OK" = false ]; then
        echo "❌ Signing failed after 3 attempts."
        exit 1
    fi

    echo "🔍 Verifying..."
    codesign --verify --deep --strict ${APP_DIR}

    echo "🗜️ Creating ZIP..."
    local ZIP_NAME="${APP_NAME}_${SUFFIX}.zip"
    ditto -ck --rsrc --sequesterRsrc --keepParent ${APP_DIR} ${ZIP_NAME}
    echo "✅ ZIP: ${ZIP_NAME}"

    echo "📂 Preparing DMG..."
    mkdir -p ${DMG_DIR}
    cp -R ${APP_DIR} ${DMG_DIR}/
    ln -s /Applications ${DMG_DIR}/Applications

    echo "💿 Creating DMG..."
    hdiutil create \
      -volname "${APP_NAME} ${SUFFIX}" \
      -srcfolder ${DMG_DIR} \
      -ov \
      -format UDZO \
      ${DMG_NAME}

    echo "🔏 Signing DMG..."
    if [ -n "$SIGN_IDENTITY" ]; then
        codesign \
          --force \
          --sign "${SIGN_IDENTITY}" \
          ${DMG_NAME}
    else
        codesign --force --sign - ${DMG_NAME}
    fi

    echo "📤 Notarizing DMG..."
    if [ -n "$NOTARY_PROFILE" ]; then
        if xcrun notarytool submit ${DMG_NAME} \
          --keychain-profile "${NOTARY_PROFILE}" \
          --wait; then
            echo "📎 Stapling DMG..."
            xcrun stapler staple ${DMG_NAME}
        else
            echo "⚠️  Notarization failed. Continuing build without notarization."
        fi
    else
        echo "⚠️  Skipping Notarization because NOTARY_PROFILE is not set."
    fi

    echo "🧼 Removing quarantine from DMG..."
    xattr -cr ${DMG_NAME}

    echo "🧼 Cleanup..."
    rm -rf ${DMG_DIR}
    
    echo "✅ Finished ${SUFFIX}: ${DMG_NAME}"
}

package_app "${BUILD_DIR}/${APP_NAME}_arm64" "Silicon"
package_app "${BUILD_DIR}/${APP_NAME}_x86_64" "Intel"

echo ""
echo "🎉 ALL BUILDS COMPLETE"
