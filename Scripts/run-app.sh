#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
app_path=$("$repo_root/Scripts/build-app.sh" "${1:-debug}")
open "$app_path"
