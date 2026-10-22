#!/usr/bin/env bash
# Generates the Android/iOS platform folders around the Dart code and applies
# the few native tweaks Fusion needs. Safe to run more than once.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "› Generating platform folders (existing files are kept)…"
flutter create . --project-name fusion --org com.razornext --platforms android,ios

MANIFEST=android/app/src/main/AndroidManifest.xml
if [ -f "$MANIFEST" ]; then
  echo "› Patching AndroidManifest.xml…"
  # Internet: google_fonts downloads the typefaces on first launch in release builds.
  if ! grep -q 'android.permission.INTERNET' "$MANIFEST"; then
    perl -0pi -e 's|(<manifest[^>]*>)|$1\n    <uses-permission android:name="android.permission.INTERNET"/>|' "$MANIFEST"
  fi
  # Let url_launcher open https links ("Open website" on a login).
  if ! grep -q 'android:scheme="https"' "$MANIFEST"; then
    perl -0pi -e 's|</manifest>|    <queries>\n        <intent>\n            <action android:name="android.intent.action.VIEW" />\n            <data android:scheme="https" />\n        </intent>\n    </queries>\n</manifest>|' "$MANIFEST"
  fi
  # App lock: biometric unlock via local_auth.
  if ! grep -q 'android.permission.USE_BIOMETRIC' "$MANIFEST"; then
    perl -0pi -e 's|(<manifest[^>]*>)|$1\n    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>|' "$MANIFEST"
  fi
  # Friendly launcher name.
  perl -pi -e 's|android:label="fusion"|android:label="Fusion"|' "$MANIFEST"
fi

# local_auth needs a FragmentActivity and AppCompat window themes.
find android/app/src/main -name MainActivity.kt -exec perl -pi -e 's/\bFlutterActivity\b/FlutterFragmentActivity/g' {} +
for STYLES in android/app/src/main/res/values/styles.xml android/app/src/main/res/values-night/styles.xml; do
  if [ -f "$STYLES" ]; then
    perl -pi -e 's|parent="\@android:style/Theme.Light.NoTitleBar"|parent="Theme.AppCompat.Light.NoActionBar"|g; s|parent="\@android:style/Theme.Black.NoTitleBar"|parent="Theme.AppCompat.NoActionBar"|g' "$STYLES"
  fi
done

PLIST=ios/Runner/Info.plist
if [ -f "$PLIST" ]; then
  echo "› Patching Info.plist display name…"
  perl -0pi -e 's|(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)|${1}Fusion${2}|' "$PLIST"
  if ! grep -q 'NSFaceIDUsageDescription' "$PLIST"; then
    echo "› Adding the Face ID usage description…"
    perl -0pi -e 's|(<key>LSRequiresIPhoneOS</key>\s*<true/>)|$1\n\t<key>NSFaceIDUsageDescription</key>\n\t<string>Unlock your Fusion vault with Face ID.</string>|' "$PLIST"
  fi
fi

echo "› Fetching packages…"
flutter pub get

echo "✓ Done. Run:  flutter run"
