#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

configuration=${1:-debug}
swift build --configuration "$configuration" --product TouchpadWM >&2
bin_path=$(swift build --configuration "$configuration" --show-bin-path)
app_path="$bin_path/TouchpadWM.app"

rm -rf "$app_path"
mkdir -p "$app_path/Contents/MacOS"
cp "$bin_path/TouchpadWM" "$app_path/Contents/MacOS/TouchpadWM"

# TouchpadWM links against runtime frameworks (e.g. the multitouch bridge's
# OpenMultitouchSupportXCF.framework) resolved via an @loader_path rpath, which SwiftPM
# satisfies by placing them next to the built executable. Mirror that layout inside the bundle
# so dyld can still find them relative to Contents/MacOS/TouchpadWM.
shopt -s nullglob
for framework in "$bin_path"/*.framework; do
  cp -R "$framework" "$app_path/Contents/MacOS/"
done
shopt -u nullglob

cat > "$app_path/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>TouchpadWM</string>
  <key>CFBundleIdentifier</key>
  <string>com.touchpadwm.app</string>
  <key>CFBundleName</key>
  <string>Touchpad WM</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST

echo "$app_path"
