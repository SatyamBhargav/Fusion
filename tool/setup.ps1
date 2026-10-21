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
  $xml = $xml -replace 'android:label="fusion"', 'android:label="Fusion"'
  Set-Content -Path $manifest -Value $xml -NoNewline
}

Write-Host '> Fetching packages...'
flutter pub get
Write-Host 'Done. Run:  flutter run'
