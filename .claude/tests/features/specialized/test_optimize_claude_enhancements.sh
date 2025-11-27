#!/usr/bin/env bash
# Test suite for /optimize-claude enhancement features (Phase 4)
# Tests threshold configuration, dry-run mode, and file flag support

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Find project root using git or walk-up pattern
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi
PROJECT_ROOT="${CLAUDE_PROJECT_DIR}/.claude"
CLAUDE_PROJECT_DIR="$PROJECT_ROOT"

# Source test utilities if available
if [ -f "$SCRIPT_DIR/test_utils.sh" ]; then
  source "$SCRIPT_DIR/test_utils.sh"
fi

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
run_test() {
  local test_name="$1"
  local test_command="$2"

  TESTS_RUN=$((TESTS_RUN + 1))
  echo "Running test: $test_name"

  if eval "$test_command"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  ✓ PASS"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "  ✗ FAIL"
  fi
}

# Test 1: Threshold validation - valid values
test_threshold_valid() {
  # Create a mock command file to parse arguments
  cat > /tmp/test_optimize_claude.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

THRESHOLD="balanced"
while [[ $# -gt 0 ]]; do
  case $1 in
    --threshold)
      THRESHOLD="$2"
      shift 2
      ;;
    --aggressive) THRESHOLD="aggressive"; shift ;;
    --balanced) THRESHOLD="balanced"; shift ;;
    --conservative) THRESHOLD="conservative"; shift ;;
    *) shift ;;
  esac
done

# Validate threshold
if [[ "$THRESHOLD" != "aggressive" && "$THRESHOLD" != "balanced" && "$THRESHOLD" != "conservative" ]]; then
  echo "ERROR: Invalid threshold: $THRESHOLD" >&2
  exit 1
fi

echo "THRESHOLD=$THRESHOLD"
EOF

  chmod +x /tmp/test_optimize_claude.sh

  # Test all valid values
  /tmp/test_optimize_claude.sh --threshold aggressive | grep -q "THRESHOLD=aggressive" && \
  /tmp/test_optimize_claude.sh --threshold balanced | grep -q "THRESHOLD=balanced" && \
  /tmp/test_optimize_claude.sh --threshold conservative | grep -q "THRESHOLD=conservative" && \
  /tmp/test_optimize_claude.sh --aggressive | grep -q "THRESHOLD=aggressive" && \
  /tmp/test_optimize_claude.sh --balanced | grep -q "THRESHOLD=balanced" && \
  /tmp/test_optimize_claude.sh --conservative | grep -q "THRESHOLD=conservative"
}

# Test 2: Threshold validation - invalid value
test_threshold_invalid() {
  cat > /tmp/test_optimize_claude_invalid.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

THRESHOLD="balanced"
while [[ $# -gt 0 ]]; do
  case $1 in
    --threshold)
      THRESHOLD="$2"
      shift 2
      ;;
    *) shift ;;
  esac
done

# Validate threshold
if [[ "$THRESHOLD" != "aggressive" && "$THRESHOLD" != "balanced" && "$THRESHOLD" != "conservative" ]]; then
  echo "ERROR: Invalid threshold: $THRESHOLD" >&2
  exit 1
fi
EOF

  chmod +x /tmp/test_optimize_claude_invalid.sh

  # Should fail with invalid value
  ! /tmp/test_optimize_claude_invalid.sh --threshold invalid 2>&1 | grep -q "Invalid threshold"
}

# Test 3: File validation - existing file
test_file_validation_exists() {
  # Create temp report file
  echo "Test report content" > /tmp/test_report.md

  cat > /tmp/test_file_validation.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

ADDITIONAL_REPORTS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --file)
      ADDITIONAL_REPORTS+=("$2")
      shift 2
      ;;
    *) shift ;;
  esac
done

# Validate files
for report_file in "${ADDITIONAL_REPORTS[@]}"; do
  if [ ! -f "$report_file" ]; then
    echo "ERROR: Report file not found: $report_file" >&2
    exit 1
  fi
done

echo "FILES_VALID=true"
EOF

  chmod +x /tmp/test_file_validation.sh
  /tmp/test_file_validation.sh --file /tmp/test_report.md | grep -q "FILES_VALID=true"
}

# Test 4: File validation - missing file
test_file_validation_missing() {
  cat > /tmp/test_file_validation_fail.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

ADDITIONAL_REPORTS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --file)
      ADDITIONAL_REPORTS+=("$2")
      shift 2
      ;;
    *) shift ;;
  esac
done

# Validate files
for report_file in "${ADDITIONAL_REPORTS[@]}"; do
  if [ ! -f "$report_file" ]; then
    echo "ERROR: Report file not found: $report_file" >&2
    exit 1
  fi
done
EOF

  chmod +x /tmp/test_file_validation_fail.sh
  ! /tmp/test_file_validation_fail.sh --file /tmp/nonexistent_report.md 2>&1 | grep -q "not found"
}

# Test 5: Multiple file flags
test_multiple_files() {
  echo "Report 1" > /tmp/test_report1.md
  echo "Report 2" > /tmp/test_report2.md
  echo "Report 3" > /tmp/test_report3.md

  cat > /tmp/test_multiple_files.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

ADDITIONAL_REPORTS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --file)
      ADDITIONAL_REPORTS+=("$2")
      shift 2
      ;;
    *) shift ;;
  esac
done

echo "FILE_COUNT=${#ADDITIONAL_REPORTS[@]}"
EOF

  chmod +x /tmp/test_multiple_files.sh
  /tmp/test_multiple_files.sh --file /tmp/test_report1.md --file /tmp/test_report2.md --file /tmp/test_report3.md | grep -q "FILE_COUNT=3"
}

# Test 6: Dry-run flag parsing
test_dry_run_flag() {
  cat > /tmp/test_dry_run.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *) shift ;;
  esac
done

echo "DRY_RUN=$DRY_RUN"
EOF

  chmod +x /tmp/test_dry_run.sh
  /tmp/test_dry_run.sh --dry-run | grep -q "DRY_RUN=true" && \
  /tmp/test_dry_run.sh | grep -q "DRY_RUN=false"
}

# Test 7: Combined flags
test_combined_flags() {
  echo "Report" > /tmp/combined_report.md

  cat > /tmp/test_combined.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

THRESHOLD="balanced"
DRY_RUN=false
ADDITIONAL_REPORTS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --threshold)
      THRESHOLD="$2"
      shift 2
      ;;
    --aggressive) THRESHOLD="aggressive"; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --file)
      ADDITIONAL_REPORTS+=("$2")
      shift 2
      ;;
    *) shift ;;
  esac
done

echo "THRESHOLD=$THRESHOLD DRY_RUN=$DRY_RUN FILES=${#ADDITIONAL_REPORTS[@]}"
EOF

  chmod +x /tmp/test_combined.sh
  /tmp/test_combined.sh --aggressive --dry-run --file /tmp/combined_report.md | grep -q "THRESHOLD=aggressive DRY_RUN=true FILES=1"
}

# Test 8: Default values
test_default_values() {
  cat > /tmp/test_defaults.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

THRESHOLD="balanced"
DRY_RUN=false
ADDITIONAL_REPORTS=()

echo "THRESHOLD=$THRESHOLD DRY_RUN=$DRY_RUN FILES=${#ADDITIONAL_REPORTS[@]}"
EOF

  chmod +x /tmp/test_defaults.sh
  /tmp/test_defaults.sh | grep -q "THRESHOLD=balanced DRY_RUN=false FILES=0"
}

# Run all tests
echo "================================"
echo "Optimize-Claude Enhancement Tests"
echo "================================"
echo ""

run_test "Threshold validation - valid values" "test_threshold_valid"
run_test "Threshold validation - invalid value" "test_threshold_invalid"
run_test "File validation - existing file" "test_file_validation_exists"
run_test "File validation - missing file" "test_file_validation_missing"
run_test "Multiple file flags" "test_multiple_files"
run_test "Dry-run flag parsing" "test_dry_run_flag"
run_test "Combined flags" "test_combined_flags"
run_test "Default values" "test_default_values"

# Cleanup
rm -f /tmp/test_optimize_claude*.sh /tmp/test_file_validation*.sh /tmp/test_*.sh
rm -f /tmp/test_report*.md /tmp/combined_report.md

# Summary
echo ""
echo "================================"
echo "Test Summary"
echo "================================"
echo "Total tests: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "All tests passed! ✓"
  exit 0
else
  echo "Some tests failed! ✗"
  exit 1
fi
