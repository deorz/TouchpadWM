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

echo "app bundle contains executable and accessory metadata"
