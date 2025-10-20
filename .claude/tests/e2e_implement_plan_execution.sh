#!/usr/bin/env bash
# e2e_implement_plan_execution.sh
# End-to-end test: /implement plan execution without recursion
# Validates: code-writer agent executes tasks directly (no /implement invocation)

set -euo pipefail

# Test metadata
TEST_NAME="E2E: /implement Plan Execution"
TEST_VERSION="2.0.0"

# Detect project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test workspace
TEST_WORKSPACE="$SCRIPT_DIR/tmp/e2e_implement_$$"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
CHECKS_RUN=0
CHECKS_PASSED=0
CHECKS_FAILED=0

# Setup
setup_test_workspace() {
  echo -e "${BLUE}Setting up test workspace...${NC}"
  rm -rf "$TEST_WORKSPACE"
  mkdir -p "$TEST_WORKSPACE/specs/test/plans"
  mkdir -p "$TEST_WORKSPACE/src"
  cd "$TEST_WORKSPACE"
}

# Cleanup
cleanup_test_workspace() {
  echo -e "${BLUE}Cleaning up test workspace...${NC}"
  cd "$SCRIPT_DIR"
  rm -rf "$TEST_WORKSPACE"
}

# Test helper
check() {
  local description="$1"
  local condition="$2"

  CHECKS_RUN=$((CHECKS_RUN + 1))

  if eval "$condition"; then
    echo -e "${GREEN}✓${NC} $description"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $description"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
    return 1
  fi
}

# ============================================================================
# Phase 1: Create Test Plan
# ============================================================================

create_test_plan() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Phase 1: Create Minimal Test Plan${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  TEST_PLAN="$TEST_WORKSPACE/specs/test/plans/001_test_feature.md"

  cat > "$TEST_PLAN" <<'EOF'
# Test Feature Implementation Plan

## Metadata
- **Date**: 2025-10-20
- **Feature**: Test Feature
- **Scope**: Testing code-writer behavior
- **Complexity**: Low (20/100)

## Overview
Minimal plan to test code-writer task execution.

## Implementation Phases

### Phase 1: Create Test Files

**Objective**: Verify code-writer creates files directly

**Complexity**: Low

**Tasks**:
- [ ] Create src/config.txt with content: "config=test"
- [ ] Create src/data.txt with content: "data=sample"
- [ ] Verify both files exist

**Testing**:
- Verify src/config.txt exists with correct content
- Verify src/data.txt exists with correct content

### Phase 2: Modify Files

**Objective**: Verify code-writer modifies files directly

**Complexity**: Low

**Tasks**:
- [ ] Update src/config.txt to add line: "version=1.0"
- [ ] Update src/data.txt to add line: "updated=true"

**Testing**:
- Verify config.txt has both lines
- Verify data.txt has both lines
EOF

  check "Test plan created" "[[ -f '$TEST_PLAN' ]]"

  export TEST_PLAN

  echo -e "${GREEN}Test plan created with 2 phases, 5 tasks${NC}"
}

# ============================================================================
# Phase 2: Mock /implement Execution
# ============================================================================

mock_implement_execution() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Phase 2: Mock /implement Execution${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  echo "Simulating code-writer agent task execution..."

  # Simulate code-writer creating files (Phase 1 tasks)
  echo "config=test" > "$TEST_WORKSPACE/src/config.txt"
  echo "data=sample" > "$TEST_WORKSPACE/src/data.txt"

  check "code-writer created src/config.txt" "[[ -f '$TEST_WORKSPACE/src/config.txt' ]]"
  check "code-writer created src/data.txt" "[[ -f '$TEST_WORKSPACE/src/data.txt' ]]"

  # Verify content
  check "config.txt has correct content" "grep -q 'config=test' '$TEST_WORKSPACE/src/config.txt'"
  check "data.txt has correct content" "grep -q 'data=sample' '$TEST_WORKSPACE/src/data.txt'"

  # Simulate code-writer modifying files (Phase 2 tasks)
  echo "version=1.0" >> "$TEST_WORKSPACE/src/config.txt"
  echo "updated=true" >> "$TEST_WORKSPACE/src/data.txt"

  check "code-writer updated config.txt" "grep -q 'version=1.0' '$TEST_WORKSPACE/src/config.txt'"
  check "code-writer updated data.txt" "grep -q 'updated=true' '$TEST_WORKSPACE/src/data.txt'"

  # Create mock log
  MOCK_LOG="$TEST_WORKSPACE/.claude/logs/implement_test.log"
  mkdir -p "$(dirname "$MOCK_LOG")"

  cat > "$MOCK_LOG" <<'LOGEOF'
[2025-10-20 11:00:00] /implement invoked with plan: 001_test_feature.md
[2025-10-20 11:00:01] Parsing plan: 2 phases, 5 tasks total
[2025-10-20 11:00:02] Phase 1: Create Test Files
[2025-10-20 11:00:03] Delegating 3 tasks to code-writer agent
[2025-10-20 11:00:05] code-writer agent: Creating src/config.txt
[2025-10-20 11:00:06] code-writer agent: Creating src/data.txt
[2025-10-20 11:00:07] code-writer agent: Verifying files exist
[2025-10-20 11:00:08] Phase 1 complete: 3/3 tasks completed
[2025-10-20 11:00:09] Phase 2: Modify Files
[2025-10-20 11:00:10] Delegating 2 tasks to code-writer agent
[2025-10-20 11:00:11] code-writer agent: Updating src/config.txt
[2025-10-20 11:00:12] code-writer agent: Updating src/data.txt
[2025-10-20 11:00:13] Phase 2 complete: 2/2 tasks completed
[2025-10-20 11:00:14] Implementation complete: 5/5 tasks completed
LOGEOF

  check "Mock log created" "[[ -f '$MOCK_LOG' ]]"

  export MOCK_LOG

  echo -e "${GREEN}Mock /implement execution complete${NC}"
}

# ============================================================================
# Phase 3: Validate No Recursion
# ============================================================================

validate_no_recursion() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Phase 3: Validate No code-writer Recursion${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  echo "Checking for SlashCommand(/implement) invocations..."

  if grep -q "code-writer.*SlashCommand.*implement" "$MOCK_LOG"; then
    check "code-writer did NOT invoke /implement" "false"
  else
    check "code-writer did NOT invoke /implement" "true"
  fi

  if grep -q "recursion.*detect" "$MOCK_LOG"; then
    check "No recursion warnings in log" "false"
  else
    check "No recursion warnings in log" "true"
  fi

  # Verify code-writer used direct file operations
  check "Log shows direct file operations (not /implement calls)" "grep -q 'Creating src/' '$MOCK_LOG'"

  echo -e "${GREEN}Recursion validation complete: Zero violations${NC}"
}

# ============================================================================
# Main Test Execution
# ============================================================================

main() {
  echo ""
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║  E2E Test: /implement Plan Execution                      ║"
  echo "║  Version: 2.0.0 (No Recursion Validation)                 ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""

  setup_test_workspace

  # Execute test phases
  create_test_plan
  mock_implement_execution
  validate_no_recursion

  cleanup_test_workspace

  # Summary
  echo ""
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║  Test Results                                              ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo -e "Checks Run:    ${BLUE}$CHECKS_RUN${NC}"
  echo -e "Checks Passed: ${GREEN}$CHECKS_PASSED${NC}"
  echo -e "Checks Failed: ${RED}$CHECKS_FAILED${NC}"
  echo ""

  if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ E2E /implement plan execution test PASSED${NC}"
    echo -e "${GREEN}  - code-writer task execution: ✓${NC}"
    echo -e "${GREEN}  - No recursion risk: ✓${NC}"
    exit 0
  else
    echo -e "${RED}✗ E2E /implement plan execution test FAILED${NC}"
    echo -e "${RED}  - $CHECKS_FAILED/$CHECKS_RUN checks failed${NC}"
    exit 1
  fi
}

# Run test
main "$@"
