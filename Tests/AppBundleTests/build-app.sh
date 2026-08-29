#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$repo_root"

Scripts/build-app.sh debug
app=.build/arm64-apple-macosx/debug/TouchpadWM.app

[[ -x "$app/Contents/MacOS/TouchpadWM" ]]
plutil -extract CFBundleExecutable raw "$app/Contents/Info.plist" | grep -Fx TouchpadWM
plutil -extract CFBundlePackageType raw "$app/Contents/Info.plist" | grep -Fx APPL
plutil -extract LSUIElement raw "$app/Contents/Info.plist" | grep -Fx true
codesign --verify --deep --strict "$app"
codesign --display --verbose=4 "$app" 2>&1 | grep -Fx 'Identifier=com.touchpadwm.app'

echo "app bundle contains executable, accessory metadata, and a stable code identity"
