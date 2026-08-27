#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_fake_toolchain() {
  mkdir -p "$tmpdir/bin"
  cat > "$tmpdir/bin/swift" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >> "$QUALITY_LOG"
EOF
  cat > "$tmpdir/bin/llvm-cov" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >> "$QUALITY_LOG"
printf '%s\n' "$QUALITY_COVERAGE_JSON"
EOF
  chmod +x "$tmpdir/bin/swift" "$tmpdir/bin/llvm-cov"
  : > "$tmpdir/test-binary"
  : > "$tmpdir/default.profdata"
}

run_gate() {
  QUALITY_LOG="$tmpdir/commands.log" \
  QUALITY_SWIFT="$tmpdir/bin/swift" \
  QUALITY_LLVM_COV="$tmpdir/bin/llvm-cov" \
  QUALITY_TEST_BINARY="$tmpdir/test-binary" \
  QUALITY_PROFILE_DATA="$tmpdir/default.profdata" \
  "$repo_root/Scripts/quality.sh"
}

make_fake_toolchain
export QUALITY_LOG="$tmpdir/commands.log"
export QUALITY_COVERAGE_JSON='{"data":[{"totals":{"lines":{"count":10,"covered":8}}}]}'
run_gate

grep -Fx 'package plugin lint-source-code --target TouchpadWM' "$QUALITY_LOG"
grep -Fx 'package plugin lint-source-code --target TouchpadWMTests' "$QUALITY_LOG"
grep -Fx 'package plugin lint-source-code --target TouchpadWMSpike' "$QUALITY_LOG"
grep -Fx 'package plugin lint-source-code --target TouchpadWMSpikeTests' "$QUALITY_LOG"
grep -Fx 'build' "$QUALITY_LOG"
grep -Fx 'test --enable-code-coverage' "$QUALITY_LOG"
grep -F 'export ' "$QUALITY_LOG" | grep -F -- '-instr-profile ' | grep -F -- '--ignore-filename-regex ' | grep -F -- '/Tests/' | grep -F -- 'MultitouchBridge\.swift' | grep -F -- 'main\.swift' | grep -F -- 'TouchpadWMApp\.swift' | grep -F -- 'SettingsView\.swift' | grep -F -- 'AccessibilityWindowService\.swift'

echo 'quality gate accepts exactly 80% line coverage'

: > "$QUALITY_LOG"
export QUALITY_COVERAGE_JSON='{"data":[{"totals":{"lines":{"count":10,"covered":7}}}]}'
if run_gate; then
  echo 'quality gate accepted insufficient line coverage' >&2
  exit 1
fi

echo 'quality gate rejects line coverage below 80%'
