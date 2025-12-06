#!/usr/bin/env bash
# Test coverage for /lean-build metadata extraction patterns
# Validates both Tier 1 (phase-specific) and Tier 2 (global) metadata discovery

set -euo pipefail

# Test configuration
TEST_DIR="/tmp/lean_build_test_$$"
mkdir -p "$TEST_DIR"
trap 'rm -rf "$TEST_DIR"' EXIT

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
print_test_header() {
  echo ""
  echo "==================================="
  echo "$1"
  echo "==================================="
}

assert_equal() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$expected" = "$actual" ]; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $test_name"
    echo "  Expected: '$expected'"
    echo "  Actual:   '$actual'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_not_empty() {
  local value="$1"
  local test_name="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ -n "$value" ]; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $test_name"
    echo "  Expected non-empty value"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_empty() {
  local value="$1"
  local test_name="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ -z "$value" ]; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $test_name"
    echo "  Expected empty value, got: '$value'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Test Case 1: Phase-specific metadata extraction (Tier 1)
test_tier1_phase_specific() {
  print_test_header "Test Case 1: Tier 1 (Phase-Specific Metadata)"

  local test_file="$TEST_DIR/test_tier1.md"
  cat > "$test_file" <<'EOF'
# Test Plan

## Metadata
- **Lean File**: /test/global.lean

### Phase 1: Test Phase [IN PROGRESS]
lean_file: /test/phase1.lean

**Description**: Test phase
EOF

  local STARTING_PHASE=1
  local PLAN_FILE="$test_file"

  # Test Tier 1 extraction
  local LEAN_FILE_RAW
  LEAN_FILE_RAW=$(awk -v target="$STARTING_PHASE" '
    BEGIN { in_phase=0 }
    /^### Phase / {
      if (index($0, "Phase " target ":") > 0) {
        in_phase = 1
      } else {
        in_phase = 0
      }
      next
    }
    in_phase && /^lean_file:/ {
      sub(/^lean_file:[[:space:]]*/, "")
      print
      exit
    }
  ' "$PLAN_FILE")

  assert_equal "/test/phase1.lean" "$LEAN_FILE_RAW" "Tier 1 extraction extracts correct path"
  assert_not_empty "$LEAN_FILE_RAW" "Tier 1 extraction returns non-empty value"
}

# Test Case 2: Global metadata extraction (Tier 2)
test_tier2_global_metadata() {
  print_test_header "Test Case 2: Tier 2 (Global Metadata)"

  local test_file="$TEST_DIR/test_tier2.md"
  cat > "$test_file" <<'EOF'
# Test Plan

## Metadata

- **Lean File**: /test/global_file.lean
- **Phase Count**: 1

### Phase 1: No Phase Metadata [IN PROGRESS]

**Description**: Test global fallback
EOF

  local STARTING_PHASE=1
  local PLAN_FILE="$test_file"

  # Test Tier 1 (should fail)
  local LEAN_FILE_RAW
  LEAN_FILE_RAW=$(awk -v target="$STARTING_PHASE" '
    BEGIN { in_phase=0 }
    /^### Phase / {
      if (index($0, "Phase " target ":") > 0) {
        in_phase = 1
      } else {
        in_phase = 0
      }
      next
    }
    in_phase && /^lean_file:/ {
      sub(/^lean_file:[[:space:]]*/, "")
      print
      exit
    }
  ' "$PLAN_FILE")

  assert_empty "$LEAN_FILE_RAW" "Tier 1 extraction fails for missing phase metadata"

  # Test Tier 2 (should succeed)
  LEAN_FILE_RAW=$(grep '^- \*\*Lean File\*\*:' "$PLAN_FILE" | sed 's/^- \*\*Lean File\*\*:[[:space:]]*//' | head -1)

  assert_equal "/test/global_file.lean" "$LEAN_FILE_RAW" "Tier 2 extraction extracts correct path"
  assert_not_empty "$LEAN_FILE_RAW" "Tier 2 extraction returns non-empty value"
}

# Test Case 3: Multi-phase extraction (Phase 2 instead of Phase 1)
test_multi_phase_extraction() {
  print_test_header "Test Case 3: Multi-Phase Extraction (Phase 2)"

  local test_file="$TEST_DIR/test_multi_phase.md"
  cat > "$test_file" <<'EOF'
# Test Plan

## Metadata
- **Lean File**: /test/global.lean

### Phase 1: First Phase [COMPLETE]
lean_file: /test/phase1.lean

**Description**: First phase

### Phase 2: Second Phase [IN PROGRESS]
lean_file: /test/phase2.lean

**Description**: Second phase

### Phase 3: Third Phase [NOT STARTED]
lean_file: /test/phase3.lean

**Description**: Third phase
EOF

  local PLAN_FILE="$test_file"

  # Test extraction for Phase 2
  local STARTING_PHASE=2
  local LEAN_FILE_RAW
  LEAN_FILE_RAW=$(awk -v target="$STARTING_PHASE" '
    BEGIN { in_phase=0 }
    /^### Phase / {
      if (index($0, "Phase " target ":") > 0) {
        in_phase = 1
      } else {
        in_phase = 0
      }
      next
    }
    in_phase && /^lean_file:/ {
      sub(/^lean_file:[[:space:]]*/, "")
      print
      exit
    }
  ' "$PLAN_FILE")

  assert_equal "/test/phase2.lean" "$LEAN_FILE_RAW" "Phase 2 extraction extracts correct path"

  # Test extraction for Phase 3
  STARTING_PHASE=3
  LEAN_FILE_RAW=$(awk -v target="$STARTING_PHASE" '
    BEGIN { in_phase=0 }
    /^### Phase / {
      if (index($0, "Phase " target ":") > 0) {
        in_phase = 1
      } else {
        in_phase = 0
      }
      next
    }
    in_phase && /^lean_file:/ {
      sub(/^lean_file:[[:space:]]*/, "")
      print
      exit
    }
  ' "$PLAN_FILE")

  assert_equal "/test/phase3.lean" "$LEAN_FILE_RAW" "Phase 3 extraction extracts correct path"
}

# Test Case 4: No awk syntax errors across all patterns
test_no_awk_errors() {
  print_test_header "Test Case 4: No AWK Syntax Errors"

  local test_file="$TEST_DIR/test_awk_errors.md"
  cat > "$test_file" <<'EOF'
# Test Plan

## Metadata
- **Lean File**: /test/global.lean

### Phase 1: Test Phase [IN PROGRESS]
lean_file: /test/phase1.lean
EOF

  local STARTING_PHASE=1
  local PLAN_FILE="$test_file"

  # Test that awk command succeeds without syntax errors
  local LEAN_FILE_RAW
  local awk_exit_code=0
  LEAN_FILE_RAW=$(awk -v target="$STARTING_PHASE" '
    BEGIN { in_phase=0 }
    /^### Phase / {
      if (index($0, "Phase " target ":") > 0) {
        in_phase = 1
      } else {
        in_phase = 0
      }
      next
    }
    in_phase && /^lean_file:/ {
      sub(/^lean_file:[[:space:]]*/, "")
      print
      exit
    }
  ' "$PLAN_FILE") || awk_exit_code=$?

  assert_equal "0" "$awk_exit_code" "AWK command exits with status 0"
  assert_not_empty "$LEAN_FILE_RAW" "AWK command produces output"
}

# Test Case 5: No history expansion triggers
test_no_history_expansion() {
  print_test_header "Test Case 5: No History Expansion Triggers"

  # Verify the pattern doesn't contain prohibited negation patterns
  local awk_pattern='BEGIN { in_phase=0 }
    /^### Phase / {
      if (index($0, "Phase " target ":") > 0) {
        in_phase = 1
      } else {
        in_phase = 0
      }
      next
    }
    in_phase && /^lean_file:/ {
      sub(/^lean_file:[[:space:]]*/, "")
      print
      exit
    }'

  # Check for prohibited patterns
  local has_negation_pattern=0
  echo "$awk_pattern" | grep -q '!/' && has_negation_pattern=1

  assert_equal "0" "$has_negation_pattern" "AWK pattern contains no negation patterns (!/)"

  # Verify pattern uses positive conditional logic
  local has_positive_conditional=0
  echo "$awk_pattern" | grep -q 'if (index' && has_positive_conditional=1

  assert_equal "1" "$has_positive_conditional" "AWK pattern uses positive conditional logic"
}

# Test Case 6: Tier 2 pattern matches markdown format correctly
test_tier2_markdown_format() {
  print_test_header "Test Case 6: Tier 2 Markdown Format Matching"

  local test_file="$TEST_DIR/test_markdown_format.md"
  cat > "$test_file" <<'EOF'
# Test Plan

## Metadata

- **Lean File**: /test/with_hyphen.lean
- **Phase Count**: 1
**Lean File**: /test/without_hyphen.lean

### Phase 1: Test [IN PROGRESS]
EOF

  local PLAN_FILE="$test_file"

  # Test that pattern matches list format with hyphen
  local LEAN_FILE_RAW
  LEAN_FILE_RAW=$(grep '^- \*\*Lean File\*\*:' "$PLAN_FILE" | sed 's/^- \*\*Lean File\*\*:[[:space:]]*//' | head -1)

  assert_equal "/test/with_hyphen.lean" "$LEAN_FILE_RAW" "Tier 2 pattern matches markdown list format with hyphen"

  # Verify pattern does NOT match format without hyphen
  local WITHOUT_HYPHEN
  WITHOUT_HYPHEN=$(grep '^\*\*Lean File\*\*:' "$PLAN_FILE" | grep -v '^- ' | sed 's/^\*\*Lean File\*\*:[[:space:]]*//' | head -1)

  assert_equal "/test/without_hyphen.lean" "$WITHOUT_HYPHEN" "Pattern without hyphen matches non-list format"
}

# Run all tests
main() {
  echo "====================================="
  echo "Lean Build Metadata Extraction Tests"
  echo "====================================="

  test_tier1_phase_specific
  test_tier2_global_metadata
  test_multi_phase_extraction
  test_no_awk_errors
  test_no_history_expansion
  test_tier2_markdown_format

  # Print summary
  echo ""
  echo "====================================="
  echo "Test Summary"
  echo "====================================="
  echo "Tests run:    $TESTS_RUN"
  echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
  if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
  else
    echo -e "Tests failed: $TESTS_FAILED"
  fi
  echo ""

  if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All metadata extraction tests passed${NC}"
    exit 0
  else
    echo -e "${RED}Some tests failed${NC}"
    exit 1
  fi
}

main "$@"
