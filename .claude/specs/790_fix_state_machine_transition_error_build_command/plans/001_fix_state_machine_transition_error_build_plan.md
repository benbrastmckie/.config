# Fix State Machine Transition Error in Build Command Implementation Plan

## Metadata
- **Date**: 2025-11-18
- **Feature**: Fix state machine transition error (implement -> complete)
- **Scope**: Build command state transitions across all 4 bash blocks
- **Estimated Phases**: 4
- **Estimated Hours**: 3.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 15
- **Research Reports**:
  - [State Machine Transition Error Analysis](../reports/001_state_machine_transition_error.md)
  - [Standards Compliance Review](../reports/002_standards_compliance_review.md)
  - [Output Formatting Integration](../reports/003_output_formatting_integration.md)

## Overview

The build command encounters an invalid state transition error "Invalid transition: implement -> complete" because Block 4 attempts to transition directly from "implement" to "complete" without going through the required intermediate states ("test" and "document"). The state machine requires the path: initialize -> implement -> test -> document -> complete. This fix ensures all bash blocks properly transition through the required states, with standards-compliant error handling, testing, and defensive programming patterns.

**Integration with Spec 778 Output Formatting**: This implementation adopts the output formatting patterns from spec 778 (comprehensive output formatting refactor), including:
- Hybrid error output (detailed logs to DEBUG_LOG, summary to user)
- Conditional debug output controlled by DEBUG environment variable
- Library sourcing suppression with 2>/dev/null
- Single summary line per block for progress indication

## Research Summary

Key findings from research reports:

**From State Machine Transition Error Analysis**:
- **State Transition Table**: The workflow-state-machine.sh (lines 55-64) only allows `implement -> test`, not `implement -> complete`
- **Root Cause**: The state file correctly persists CURRENT_STATE after each transition, but Block 4 fails because Block 2 (test transition) and Block 3 (document transition) may not complete successfully
- **Evidence**: Build output shows "!: command not found" error before Block 3 completes, suggesting history expansion issues caused early termination
- **Solution**: Ensure all intermediate state transitions are properly called in each block

**From Standards Compliance Review**:
- **Error Context**: Current error messages lack WHICH/WHAT/WHERE structure per defensive-programming.md
- **Testing**: No automated test file specified; standards require `.claude/tests/test_*.sh` with isolation patterns
- **Shell Scripts**: Missing `set -e` for fail-fast behavior per code-standards.md
- **State Validation**: Should align with documented troubleshooting patterns from state-orchestration-overview.md

**From Output Formatting Integration**:
- **Hybrid Error Output**: Detailed WHICH/WHAT/WHERE to DEBUG_LOG, single summary to stderr
- **DEBUG_LOG Pattern**: `${HOME}/.claude/tmp/workflow_debug.log` for verbose diagnostics
- **Conditional Debug**: Use `[ "${DEBUG:-}" = "1" ]` for verbose output
- **Library Suppression**: All library sourcing with `2>/dev/null`

Recommended approach: Add missing `sm_transition` calls, hybrid error output with DEBUG_LOG, proper test isolation, and fail-fast behavior.

## Success Criteria

- [x] Build command completes full workflow without state transition errors
- [x] State transitions follow valid path: initialize -> implement -> test -> document -> complete
- [x] All bash blocks properly load and persist workflow state
- [x] Error handling uses hybrid pattern (detailed to DEBUG_LOG, summary to user)
- [x] Automated test file created with isolation patterns per testing protocols
- [x] All blocks use `set -e` for fail-fast behavior per code standards
- [x] Tests pass for the build workflow (both automated and manual execution)
- [x] Output follows single summary line pattern from spec 778

## Technical Design

### Architecture Overview

The build command uses 4 bash blocks that share state through a state file:

```
Block 1: Setup (initialize -> implement)
    |
    v
Block 2: Testing (implement -> test)
    |
    v
Block 3: Debug/Doc (test -> debug OR test -> document)
    |
    v
Block 4: Complete (document/debug -> complete)
```

### Current Issue

Block 2 transitions to "test" at line 410, and Block 3 transitions to "document" at line 522. However, if Block 3 fails early due to bash errors, the CURRENT_STATE remains at "test" or "implement", causing Block 4's transition to "complete" to fail.

### Solution Design

1. Add state validation after load_workflow_state in each block with hybrid error output
2. Ensure Block 4 can only complete from valid predecessor states (document or debug)
3. Add defensive error handling for history expansion issues
4. Add `set -e` for fail-fast behavior in all blocks
5. Create automated test suite with proper isolation patterns
6. Use DEBUG_LOG for detailed diagnostics per spec 778 patterns

### Output Formatting Integration

Per spec 778 patterns, all error output follows this structure:

```bash
# Initialize DEBUG_LOG
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

# Hybrid error output pattern
{
  echo "[$(date)] ERROR: State restoration failed"
  echo "WHICH: load_workflow_state"
  echo "WHAT: CURRENT_STATE not properly restored"
  echo "WHERE: Block 2, testing phase initialization"
} >> "$DEBUG_LOG"

echo "ERROR: State restoration failed (see $DEBUG_LOG for details)" >&2
exit 1
```

## Implementation Phases

### Phase 1: Add State Validation After Load [COMPLETE]
dependencies: []

**Objective**: Add explicit validation that CURRENT_STATE was properly loaded from the state file in Blocks 2, 3, and 4 with hybrid error output pattern

**Complexity**: Low

Tasks:
- [x] Add `set -e` for fail-fast behavior at the start of each block after history expansion disabling (file: .claude/commands/build.md, Blocks 1-4)
- [x] Add DEBUG_LOG initialization at the start of each block (file: .claude/commands/build.md, Blocks 1-4)
- [x] Add state validation function after load_workflow_state in Block 2 (file: .claude/commands/build.md, after line 396)
- [x] Add state validation function after load_workflow_state in Block 3 (file: .claude/commands/build.md, after line 497)
- [x] Add state validation function after load_workflow_state in Block 4 (file: .claude/commands/build.md, after line 597)
- [x] Use conditional debug output for state load confirmation

**Block Initialization Pattern (Spec 778 Compliant)**:
```bash
#!/usr/bin/env bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e  # Fail-fast per code-standards.md

# DEBUG_LOG initialization per spec 778
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

# ... rest of block
```

**Validation Pattern (Hybrid Error Output)**:
```bash
load_workflow_state "$WORKFLOW_ID" false

# Validate state file exists and was loaded
if [ -z "$STATE_FILE" ]; then
  # Detailed log to DEBUG_LOG
  {
    echo "[$(date)] ERROR: State file path not set"
    echo "WHICH: load_workflow_state"
    echo "WHAT: STATE_FILE variable empty after load"
    echo "WHERE: Block 2, testing phase initialization"
  } >> "$DEBUG_LOG"
  # Summary to user
  echo "ERROR: State file path not set (see $DEBUG_LOG)" >&2
  exit 1
fi

if [ ! -f "$STATE_FILE" ]; then
  # Detailed log to DEBUG_LOG
  {
    echo "[$(date)] ERROR: State file not found"
    echo "WHICH: load_workflow_state"
    echo "WHAT: File does not exist at expected path"
    echo "WHERE: Block 2, testing phase initialization"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  # Summary to user
  echo "ERROR: State file not found (see $DEBUG_LOG)" >&2
  exit 1
fi

# Validate state was loaded
if [ -z "${CURRENT_STATE:-}" ] || [ "$CURRENT_STATE" = "initialize" ]; then
  # Detailed log to DEBUG_LOG
  {
    echo "[$(date)] ERROR: State restoration failed"
    echo "WHICH: load_workflow_state"
    echo "WHAT: CURRENT_STATE not properly restored (expected: previous state, got: ${CURRENT_STATE:-empty})"
    echo "WHERE: Block 2, testing phase initialization"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  # Summary to user
  echo "ERROR: State restoration failed (see $DEBUG_LOG)" >&2
  exit 1
fi

# Conditional debug output per spec 778
[ "${DEBUG:-}" = "1" ] && echo "DEBUG: Loaded state: $CURRENT_STATE" >&2
# Single summary line
echo "Block 2: State validated ($CURRENT_STATE)"
```

Testing:
```bash
# Run automated test suite (created in Phase 3)
.claude/tests/test_build_state_transitions.sh

# Manual test: Run /build with a plan and observe state load messages
# Verify state is correctly loaded in each block
# Check DEBUG_LOG for detailed diagnostics if errors occur
```

**Expected Duration**: 45 minutes

### Phase 2: Ensure Block 4 Validates Predecessor State [COMPLETE]
dependencies: [1]

**Objective**: Ensure Block 4 only transitions to complete from valid predecessor states (document or debug), not from test or implement, using hybrid error output

**Complexity**: Low

Tasks:
- [x] Add predecessor state validation in Block 4 before sm_transition to complete (file: .claude/commands/build.md, line 599)
- [x] If CURRENT_STATE is "test" or "implement", fail with hybrid error output (summary to user, details to DEBUG_LOG)
- [x] Use consistent formatting pattern from spec 778

**Validation Pattern (Hybrid Error Output)**:
```bash
# Validate we are in a valid predecessor state for complete
case "$CURRENT_STATE" in
  document|debug)
    # Valid - can transition to complete
    ;;
  test)
    # Detailed log to DEBUG_LOG
    {
      echo "[$(date)] ERROR: Invalid predecessor state for completion"
      echo "WHICH: sm_transition to complete"
      echo "WHAT: Cannot transition to complete from test state - Block 3 did not execute"
      echo "WHERE: Block 4, workflow completion"
      echo "CURRENT_STATE: $CURRENT_STATE"
      echo ""
      echo "TROUBLESHOOTING:"
      echo "1. Check Block 3 for errors (debug/document phase)"
      echo "2. Verify state file contains expected transitions"
      echo "3. Check for history expansion errors in previous blocks"
    } >> "$DEBUG_LOG"
    # Summary to user
    echo "ERROR: Invalid predecessor state - Block 3 did not complete (see $DEBUG_LOG)" >&2
    exit 1
    ;;
  implement)
    # Detailed log to DEBUG_LOG
    {
      echo "[$(date)] ERROR: Invalid predecessor state for completion"
      echo "WHICH: sm_transition to complete"
      echo "WHAT: Cannot transition to complete from implement state - Blocks 2 and 3 did not execute"
      echo "WHERE: Block 4, workflow completion"
      echo "CURRENT_STATE: $CURRENT_STATE"
      echo ""
      echo "TROUBLESHOOTING:"
      echo "1. Check Block 2 for errors (testing phase)"
      echo "2. Check Block 3 for errors (debug/document phase)"
      echo "3. Verify state file contains expected transitions"
    } >> "$DEBUG_LOG"
    # Summary to user
    echo "ERROR: Invalid predecessor state - Blocks 2 and 3 did not complete (see $DEBUG_LOG)" >&2
    exit 1
    ;;
  *)
    # Detailed log to DEBUG_LOG
    {
      echo "[$(date)] ERROR: Unexpected predecessor state"
      echo "WHICH: sm_transition to complete"
      echo "WHAT: Unrecognized state before completion"
      echo "WHERE: Block 4, workflow completion"
      echo "CURRENT_STATE: $CURRENT_STATE"
    } >> "$DEBUG_LOG"
    # Summary to user
    echo "ERROR: Unexpected predecessor state '$CURRENT_STATE' (see $DEBUG_LOG)" >&2
    exit 1
    ;;
esac
```

Testing:
```bash
# Run automated test suite
.claude/tests/test_build_state_transitions.sh

# Manual test: Run /build and verify Block 4 validates state
# Test by artificially skipping Block 3 to confirm error is caught
# Verify DEBUG_LOG contains full troubleshooting information
```

**Expected Duration**: 30 minutes

### Phase 3: Create Automated Test Suite [COMPLETE]
dependencies: [1]

**Objective**: Create automated test file with proper isolation patterns per testing protocols and spec 778 output formatting

**Complexity**: Medium

Tasks:
- [x] Create test file at `.claude/tests/test_build_state_transitions.sh`
- [x] Implement test isolation using CLAUDE_SPECS_ROOT override pattern per testing-protocols.md
- [x] Add cleanup trap to ensure test directory removal on all exit paths
- [x] Use library sourcing suppression pattern (2>/dev/null) per spec 778
- [x] Add test cases for:
  - Successful state transitions through all blocks
  - State validation after load (missing state file)
  - State validation after load (corrupt state file)
  - Predecessor state validation in Block 4 (from implement - should fail)
  - Predecessor state validation in Block 4 (from test - should fail)
  - Predecessor state validation in Block 4 (from document - should pass)
  - History expansion handling (strings with exclamation marks)
- [x] Add regression test to prevent future state transition errors

**Test Template (Standards and Spec 778 Compliant)**:
```bash
#!/usr/bin/env bash
# Test: Build command state transitions
# Coverage: State machine transition validation for build workflow

set -e

# Test isolation pattern per testing-protocols.md
setup_test_environment() {
  local test_dir
  test_dir="$(mktemp -d)"
  export CLAUDE_SPECS_ROOT="$test_dir"
  export CLAUDE_PROJECT_DIR="$test_dir"

  # Create minimal test structure
  mkdir -p "$test_dir/.claude/lib"
  mkdir -p "$test_dir/.claude/tmp"

  # Copy required libraries - with suppression per spec 778
  cp /home/benjamin/.config/.claude/lib/state-persistence.sh "$test_dir/.claude/lib/"
  cp /home/benjamin/.config/.claude/lib/workflow-state-machine.sh "$test_dir/.claude/lib/"
  cp /home/benjamin/.config/.claude/lib/checkpoint-utils.sh "$test_dir/.claude/lib/"

  echo "$test_dir"
}

cleanup() {
  if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
  unset CLAUDE_SPECS_ROOT CLAUDE_PROJECT_DIR
}

trap cleanup EXIT

# Test: Valid state transitions
test_valid_state_transitions() {
  local test_dir
  test_dir=$(setup_test_environment)
  TEST_DIR="$test_dir"

  # Source libraries with suppression per spec 778
  source "$test_dir/.claude/lib/state-persistence.sh" 2>/dev/null
  source "$test_dir/.claude/lib/workflow-state-machine.sh" 2>/dev/null

  # Initialize workflow
  init_workflow_state "test_workflow"
  sm_init

  # Test transitions
  sm_transition "$STATE_IMPLEMENT" || { echo "FAIL: initialize -> implement"; return 1; }
  sm_transition "$STATE_TEST" || { echo "FAIL: implement -> test"; return 1; }
  sm_transition "$STATE_DOCUMENT" || { echo "FAIL: test -> document"; return 1; }
  sm_transition "$STATE_COMPLETE" || { echo "FAIL: document -> complete"; return 1; }

  echo "PASS: Valid state transitions"
  return 0
}

# Test: Invalid transition (implement -> complete)
test_invalid_implement_to_complete() {
  local test_dir
  test_dir=$(setup_test_environment)
  TEST_DIR="$test_dir"

  # Source libraries with suppression per spec 778
  source "$test_dir/.claude/lib/state-persistence.sh" 2>/dev/null
  source "$test_dir/.claude/lib/workflow-state-machine.sh" 2>/dev/null

  # Initialize workflow
  init_workflow_state "test_workflow"
  sm_init
  sm_transition "$STATE_IMPLEMENT"

  # Attempt invalid transition - should fail
  if sm_transition "$STATE_COMPLETE" 2>/dev/null; then
    echo "FAIL: implement -> complete should have failed"
    return 1
  fi

  echo "PASS: Invalid transition correctly rejected"
  return 0
}

# Test: Invalid transition (test -> complete)
test_invalid_test_to_complete() {
  local test_dir
  test_dir=$(setup_test_environment)
  TEST_DIR="$test_dir"

  # Source libraries with suppression per spec 778
  source "$test_dir/.claude/lib/state-persistence.sh" 2>/dev/null
  source "$test_dir/.claude/lib/workflow-state-machine.sh" 2>/dev/null

  # Initialize workflow
  init_workflow_state "test_workflow"
  sm_init
  sm_transition "$STATE_IMPLEMENT"
  sm_transition "$STATE_TEST"

  # Attempt invalid transition - should fail
  if sm_transition "$STATE_COMPLETE" 2>/dev/null; then
    echo "FAIL: test -> complete should have failed"
    return 1
  fi

  echo "PASS: Invalid transition test -> complete correctly rejected"
  return 0
}

# Run all tests
main() {
  local failed=0

  echo "Running state transition tests..."

  test_valid_state_transitions || ((failed++))
  test_invalid_implement_to_complete || ((failed++))
  test_invalid_test_to_complete || ((failed++))

  echo ""
  if [ "$failed" -gt 0 ]; then
    echo "FAILED: $failed test(s) failed"
    exit 1
  fi

  echo "All tests passed"
  exit 0
}

main "$@"
```

Testing:
```bash
# Run the test suite
.claude/tests/test_build_state_transitions.sh

# Verify test isolation (no production directories created)
ls -la ~/.claude/specs/ | grep -v "790_"
```

**Expected Duration**: 45 minutes

### Phase 4: Strengthen History Expansion Handling [COMPLETE]
dependencies: [1]

**Objective**: Ensure history expansion is fully disabled in all bash blocks to prevent "!: command not found" errors

**Complexity**: Low

Tasks:
- [x] Move `set +H` to very first line of each bash block before any other commands (verify Blocks 1-4)
- [x] Add fallback `set +o histexpand 2>/dev/null || true` after `set +H` in all blocks
- [x] Add `set -e` after history expansion disabling for fail-fast behavior
- [x] Add DEBUG_LOG initialization immediately after
- [x] Verify no exclamation marks in double-quoted strings could trigger history expansion

**Pattern**:
```bash
#!/usr/bin/env bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e  # Fail-fast per code-standards.md

# DEBUG_LOG initialization per spec 778
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

# ... rest of block
```

Testing:
```bash
# Run automated test suite
.claude/tests/test_build_state_transitions.sh

# Manual test: Run /build with a plan that has exclamation marks in filenames
# Verify no "!: command not found" errors appear
```

**Expected Duration**: 30 minutes

## Testing Strategy

### Automated Testing
- **Test File**: `.claude/tests/test_build_state_transitions.sh`
- **Test Runner**: `.claude/tests/run_all_tests.sh` (includes new test)
- **Coverage Target**: >=80% for modified code paths

### Test Isolation
Per testing-protocols.md (lines 200-235):
```bash
export CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"
export CLAUDE_PROJECT_DIR="/tmp/test_specs_$$"
mkdir -p "$CLAUDE_SPECS_ROOT"
trap cleanup EXIT
```

### Unit Testing
- Verify each block handles missing/corrupt state file gracefully
- Verify state validation catches incorrect predecessor states
- Verify history expansion is fully disabled
- Verify error messages use hybrid output pattern (summary to user, details to DEBUG_LOG)

### Integration Testing
- Run complete /build workflow from Block 1 to Block 4
- Verify state transitions follow valid path
- Verify build-output.md shows successful completion
- Verify DEBUG_LOG contains detailed diagnostics when errors occur

### Regression Testing
- Test case for original bug: implement -> complete transition attempt
- Verify error message provides actionable troubleshooting via DEBUG_LOG

### Manual Verification
```bash
# Set up test isolation per testing-protocols.md
export CLAUDE_SPECS_ROOT="/tmp/manual_test_$$"
export CLAUDE_PROJECT_DIR="/tmp/manual_test_$$"
mkdir -p "$CLAUDE_SPECS_ROOT"

# Clean any existing state
rm -f ~/.claude/tmp/build_state_*.txt
rm -f ~/.claude/tmp/workflow_*.sh

# Run build with existing plan
/build .claude/specs/790_fix_state_machine_transition_error_build_command/plans/001_*.md

# Verify completion message shows:
# === Build Complete ===
# (no ERROR messages)

# Check DEBUG_LOG for any verbose diagnostics
cat ~/.claude/tmp/workflow_debug.log

# Cleanup
rm -rf "/tmp/manual_test_$$"
unset CLAUDE_SPECS_ROOT CLAUDE_PROJECT_DIR
```

## Documentation Requirements

- Update build command troubleshooting section in `.claude/docs/guides/build-command-guide.md` with state transition debugging guidance
- Add state file validation troubleshooting steps
- Document DEBUG_LOG location for verbose diagnostics
- No new documentation files needed (this is a bug fix)
- All documentation updates must follow:
  - Internal link conventions (relative paths)
  - No emojis in file content
  - CommonMark specification

## Dependencies

- workflow-state-machine.sh >=2.0.0 (already in use)
- state-persistence.sh >=1.5.0 (already in use)
- checkpoint-utils.sh (already in use)
- spec 778 output formatting patterns (adopted in this plan)
- No external dependencies

## Risk Assessment

### Low Risk
- Changes are defensive additions (validation, error handling)
- No changes to core state machine logic
- All existing functionality preserved
- Automated tests ensure non-regression
- Hybrid error output reduces user-facing noise while preserving diagnostics

### Mitigation
- Use DEBUG environment variable for verbose output (removable after verification)
- Test with existing plan files to verify backward compatibility
- Automated test suite with isolation prevents production pollution
- DEBUG_LOG provides full diagnostics for troubleshooting without cluttering user output
