# Windows version of tool/setup.sh — generates platform folders and applies
# Fusion's native tweaks. Run from PowerShell:  ./tool/setup.ps1
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

Write-Host '> Generating platform folders (existing files are kept)...'
flutter create . --project-name fusion --org com.razornext --platforms android,ios

$manifest = 'android/app/src/main/AndroidManifest.xml'
if (Test-Path $manifest) {
  Write-Host '> Patching AndroidManifest.xml...'
  $xml = Get-Content $manifest -Raw
  if ($xml -notmatch 'android.permission.INTERNET') {
    $xml = $xml -replace '(<manifest[^>]*>)', "`$1`n    <uses-permission android:name=`"android.permission.INTERNET`"/>"
  }
  if ($xml -notmatch 'android:scheme="https"') {
    $queries = "    <queries>`n        <intent>`n            <action android:name=`"android.intent.action.VIEW`" />`n            <data android:scheme=`"https`" />`n        </intent>`n    </queries>`n</manifest>"
    $xml = $xml -replace '</manifest>', $queries
  }
  if ($xml -notmatch 'android.permission.USE_BIOMETRIC') {
    $xml = $xml -replace '(<manifest[^>]*>)', "`$1`n    <uses-permission android:name=`"android.permission.USE_BIOMETRIC`"/>"
  }
  $xml = $xml -replace 'android:label="fusion"', 'android:label="Fusion"'
  Set-Content -Path $manifest -Value $xml -NoNewline
}

# local_auth needs a FragmentActivity and AppCompat window themes.
Get-ChildItem -Path 'android/app/src/main' -Recurse -Filter 'MainActivity.kt' | ForEach-Object {
  $kt = Get-Content $_.FullName -Raw
  Set-Content -Path $_.FullName -Value ($kt -replace '\bFlutterActivity\b', 'FlutterFragmentActivity') -NoNewline
}
foreach ($styles in 'android/app/src/main/res/values/styles.xml', 'android/app/src/main/res/values-night/styles.xml') {
  if (Test-Path $styles) {
    $s = Get-Content $styles -Raw
    $s = $s -replace 'parent="@android:style/Theme.Light.NoTitleBar"', 'parent="Theme.AppCompat.Light.NoActionBar"'
    $s = $s -replace 'parent="@android:style/Theme.Black.NoTitleBar"', 'parent="Theme.AppCompat.NoActionBar"'
    Set-Content -Path $styles -Value $s -NoNewline
  }
}

$plist = 'ios/Runner/Info.plist'
if ((Test-Path $plist) -and -not (Select-String -Path $plist -Pattern 'NSFaceIDUsageDescription' -Quiet)) {
  Write-Host '> Adding the Face ID usage description...'
  $p = Get-Content $plist -Raw
  $p = $p -replace '(<key>LSRequiresIPhoneOS</key>\s*<true/>)', "`$1`n`t<key>NSFaceIDUsageDescription</key>`n`t<string>Unlock your Fusion vault with Face ID.</string>"
  Set-Content -Path $plist -Value $p -NoNewline
}

Write-Host '> Fetching packages...'
flutter pub get
Write-Host 'Done. Run:  flutter run'
