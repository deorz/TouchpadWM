#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

app_path=$("$repo_root/Scripts/build-app.sh" release)

# Sign nested bundle-format items (frameworks) explicitly before signing the app itself:
# codesign requires any immediate .framework/.bundle subitem to already carry its own signature,
# even without --deep.
shopt -s nullglob
for nested in "$app_path"/Contents/MacOS/*.framework; do
  codesign --force --sign - "$nested" >&2
done
shopt -u nullglob

codesign --force --sign - "$app_path" >&2

zip_path="${app_path%.app}.zip"
rm -f "$zip_path"
ditto -c -k --sequesterRsrc --keepParent "$app_path" "$zip_path" >&2

echo "$zip_path"
