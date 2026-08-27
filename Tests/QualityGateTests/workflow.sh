#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
workflow="$repo_root/.github/workflows/swift.yml"

require_workflow_text() {
  local expected=$1
  if ! grep -Fq "$expected" "$workflow"; then
    echo "Missing workflow contract: $expected" >&2
    exit 1
  fi
}

require_workflow_text '  pull_request:'
require_workflow_text '    branches: [ "master" ]'
require_workflow_text '    tags: [ "v*" ]'
require_workflow_text '      run: ./Scripts/quality.sh'
require_workflow_text '      run: ./Tests/QualityGateTests/quality.sh'
require_workflow_text '  release:'
require_workflow_text "    if: startsWith(github.ref, 'refs/tags/v')"
require_workflow_text '      contents: write'
require_workflow_text '      zip_path=$(./Scripts/release-app.sh)'
require_workflow_text '      gh release create "$GITHUB_REF_NAME" "$zip_path"'

echo 'GitHub Actions workflow contract is satisfied'
