#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

swift_command=${QUALITY_SWIFT:-swift}
developer_dir=${DEVELOPER_DIR:-$(xcode-select -p)}
llvm_cov=${QUALITY_LLVM_COV:-"$developer_dir/Toolchains/XcodeDefault.xctoolchain/usr/bin/llvm-cov"}
minimum_line_coverage=${QUALITY_MIN_LINE_COVERAGE:-80}
coverage_exclusions='/\.build/|/Tests/|/Sources/TouchpadWMSpike/MultitouchBridge\.swift$|/Sources/TouchpadWMSpike/main\.swift$'

"$swift_command" package plugin lint-source-code --target TouchpadWMSpike
"$swift_command" package plugin lint-source-code --target TouchpadWMSpikeTests
"$swift_command" build
"$swift_command" test --enable-code-coverage

profile_data=${QUALITY_PROFILE_DATA:-$(find .build -name default.profdata -type f -print -quit)}
test_binary=${QUALITY_TEST_BINARY:-$(find .build -path '*TouchpadWMPackageTests.xctest/Contents/MacOS/TouchpadWMPackageTests' -type f -print -quit)}

if [[ -z "$profile_data" || -z "$test_binary" ]]; then
  echo "ERROR: SwiftPM coverage artifacts were not found." >&2
  exit 1
fi

"$llvm_cov" export "$test_binary" -instr-profile "$profile_data" --ignore-filename-regex "$coverage_exclusions" | python3 -c '
import json
import sys

minimum = float(sys.argv[1])
report = json.load(sys.stdin)
totals = report["data"][0]["totals"]["lines"]
count = totals["count"]
covered = totals["covered"]
coverage = 100 * covered / count if count else 100.0
print(f"Line coverage: {coverage:.2f}% ({covered}/{count})")
if coverage < minimum:
    raise SystemExit(f"ERROR: line coverage is below the required {minimum:.0f}%.")
' "$minimum_line_coverage"
