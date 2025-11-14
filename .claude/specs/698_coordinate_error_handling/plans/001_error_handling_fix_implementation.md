# Error Handling Fix Implementation Plan

**Document Type**: Implementation Plan
**Status**: Ready for Implementation
**Created**: 2025-11-13
**Related Spec**: 698_coordinate_error_handling
**Research Report**: [001_error_handling_root_cause_analysis.md](../reports/001_error_handling_root_cause_analysis.md)

---

## Executive Summary

This plan addresses critical error handling vulnerabilities in `/coordinate` and `/orchestrate` commands where `sm_init()` return codes are not checked, allowing execution to continue with uninitialized variables. The fix involves adding return code checks, removing output redirection that hides errors, adding verification checkpoints, improving error messages, and creating comprehensive tests to prevent regression.

**Complexity**: Low (straightforward return code checks)
**Risk**: Low (adding safety checks, not removing functionality)
**Estimated Time**: 2-3 hours
**Test Coverage**: High (unit tests, integration tests, failure mode tests)

---

## Research Report References

- **Root Cause Analysis**: [001_error_handling_root_cause_analysis.md](../reports/001_error_handling_root_cause_analysis.md)
  - Lines 166-167: `/coordinate` sm_init() vulnerability
  - Lines 380-398: `/orchestrate` sm_init() vulnerability
  - Lines 439-549: Recommended fix strategies
  - Lines 550-856: Testing recommendations and prevention guidelines

---

## Project Standards Integration

### Relevant Standards

1. **Standard 0 (Execution Enforcement)** - CLAUDE.md:277-283
   - All critical operations require return code verification
   - MANDATORY VERIFICATION checkpoints for critical state initialization
   - Fail-fast error handling (no silent failures)

2. **Fail-Fast Policy** - CLAUDE.md:211-215
   - Missing files produce immediate, obvious bash errors
   - Breaking changes break loudly with clear error messages
   - No silent fallbacks or graceful degradation

3. **Bash Block Execution Model** - bash-block-execution-model.md
   - Export assumptions must be verified (Pattern 5:287-369)
   - Cross-block state requires file-based persistence
   - Libraries must be sourced before function calls (Pattern 4:456-526)

4. **Error Handling Library** - error-handling.sh
   - `handle_state_error()` function for consistent error reporting
   - Error classification and recovery suggestions
   - State machine context in error messages

### Testing Protocols

- **Test Location**: `.claude/tests/`
- **Test Pattern**: `test_*.sh` (Bash test scripts)
- **Coverage Target**: ≥80% for modified code
- **Test Categories**: Command integration, state management, error handling

---

## Phase 0: Pre-Work and Analysis Verification

**Objective**: Verify analysis findings and create backups before making changes.

### Tasks

1. **Verify Vulnerability Exists in coordinate.md**
   - Location: `/home/benjamin/.config/.claude/commands/coordinate.md:166`
   - Expected pattern: `sm_init "$SAVED_WORKFLOW_DESC" "coordinate" >/dev/null`
   - Confirm no return code check present

2. **Verify Vulnerability Exists in orchestrate.md**
   - Location: `/home/benjamin/.config/.claude/commands/orchestrate.md:109`
   - Expected pattern: `sm_init "$WORKFLOW_DESCRIPTION" "orchestrate"`
   - Confirm no return code check present

3. **Create Backups**
   ```bash
   # Backup coordinate.md
   cp /home/benjamin/.config/.claude/commands/coordinate.md \
      /home/benjamin/.config/.claude/commands/coordinate.md.backup-$(date +%Y%m%d-%H%M%S)

   # Backup orchestrate.md
   cp /home/benjamin/.config/.claude/commands/orchestrate.md \
      /home/benjamin/.config/.claude/commands/orchestrate.md.backup-$(date +%Y%m%d-%H%M%S)
   ```

4. **Verify Test Infrastructure**
   - Check test runner exists: `.claude/tests/run_all_tests.sh`
   - Identify existing error handling tests
   - Document baseline test pass rate

### Success Criteria

- [ ] Both vulnerabilities confirmed at specified line numbers
- [ ] Backup files created with timestamps
- [ ] Test infrastructure verified operational
- [ ] Baseline metrics documented

### Rollback Procedure

If verification fails or unexpected conditions found:
1. Do not proceed with implementation
2. Update research report with new findings
3. Revise plan based on actual code state

---

## Phase 1: Fix coordinate.md sm_init() Call

**Objective**: Add return code checking and error handling to `/coordinate` command.

### Code Changes

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
**Line**: 166

**Before**:
```bash
# Initialize state machine (use SAVED value, not overwritten variable)
# CRITICAL: Call sm_init to export WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
# Do NOT use command substitution $() as it creates subshell that doesn't export to parent
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" >/dev/null
# Variables now available via export (not command substitution)
```

**After**:
```bash
# Initialize state machine (use SAVED value, not overwritten variable)
# CRITICAL: Call sm_init to export WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
# Do NOT use command substitution $() as it creates subshell that doesn't export to parent
if ! sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1; then
  handle_state_error "State machine initialization failed (workflow classification error). Check network connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline development." 1
fi
# Variables now available via export (verified by successful sm_init return code check above)
```

### Changes Explained

1. **Wrap in `if ! ... then` conditional** - Checks return code
2. **Remove `>/dev/null` redirection** - Shows critical error messages
3. **Change to `2>&1`** - Captures both stdout and stderr for visibility
4. **Call `handle_state_error()` on failure** - Consistent error handling
5. **Provide actionable error message** - Includes troubleshooting guidance
6. **Update comment** - Reflects verification requirement

### Rationale

- Consistent with other error handling in coordinate.md (lines 226, 244)
- Uses existing `handle_state_error()` function from error-handling.sh
- Follows fail-fast philosophy (CLAUDE.md:211-215)
- Error message provides offline development workaround

### Success Criteria

- [ ] Code changes applied exactly as specified
- [ ] No syntax errors introduced
- [ ] Command still sources error-handling.sh before sm_init() call (line 122)
- [ ] Comment updated to reflect verification

### Testing

Run manual test with simulated failure:
```bash
# Force LLM classification failure
export WORKFLOW_CLASSIFICATION_MODE=llm-only
unset ANTHROPIC_API_KEY

# Invoke /coordinate
/coordinate "test workflow description"

# Expected: Immediate error with clear message, exit code 1
# Should NOT reach line 244 (initialize_workflow_paths)
```

---

## Phase 2: Fix orchestrate.md sm_init() Call

**Objective**: Add return code checking and error handling to `/orchestrate` command.

### Code Changes

**File**: `/home/benjamin/.config/.claude/commands/orchestrate.md`
**Line**: 109

**Before**:
```bash
# Initialize state machine
sm_init "$WORKFLOW_DESCRIPTION" "orchestrate"

# Save state machine configuration
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
```

**After**:
```bash
# Initialize state machine
if ! sm_init "$WORKFLOW_DESCRIPTION" "orchestrate" 2>&1; then
  handle_state_error "State machine initialization failed (workflow classification error). Check network connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline development." 1
fi

# Save state machine configuration (verified by successful sm_init return code check above)
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
```

### Changes Explained

1. **Wrap in `if ! ... then` conditional** - Checks return code
2. **Keep stderr/stdout visible** - No output redirection (already correct)
3. **Add `2>&1` for consistency** - Ensures all output visible
4. **Call `handle_state_error()` on failure** - Consistent error handling
5. **Add explanatory comment** - Documents verification

### Rationale

- Matches pattern used in coordinate.md (consistency)
- Uses existing `handle_state_error()` function defined at line 152
- Prevents access to uninitialized `$WORKFLOW_SCOPE` variable
- orchestrate.md already shows errors (no >/dev/null), just missing check

### Success Criteria

- [ ] Code changes applied exactly as specified
- [ ] No syntax errors introduced
- [ ] `handle_state_error()` function available (defined at line 152)
- [ ] Comment added for clarity

### Testing

Run manual test with simulated failure:
```bash
# Force LLM classification failure
export WORKFLOW_CLASSIFICATION_MODE=llm-only
unset ANTHROPIC_API_KEY

# Invoke /orchestrate
/orchestrate "test workflow description"

# Expected: Immediate error with clear message, exit code 1
# Should NOT reach line 112 (append_workflow_state for WORKFLOW_SCOPE)
```

---

## Phase 3: Add Verification Checkpoints for Exported Variables

**Objective**: Add explicit verification that critical variables are exported after successful `sm_init()`.

### Code Changes

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
**Location**: After line 167 (after successful sm_init)

**Add**:
```bash
# VERIFICATION CHECKPOINT: Verify critical variables exported by sm_init
# Standard 0 (Execution Enforcement): Critical state initialization must be verified
if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not exported by sm_init despite successful return code (library bug)" 1
fi

if [ -z "${RESEARCH_COMPLEXITY:-}" ]; then
  handle_state_error "CRITICAL: RESEARCH_COMPLEXITY not exported by sm_init despite successful return code (library bug)" 1
fi

if [ -z "${RESEARCH_TOPICS_JSON:-}" ]; then
  handle_state_error "CRITICAL: RESEARCH_TOPICS_JSON not exported by sm_init despite successful return code (library bug)" 1
fi

echo "✓ State machine variables verified: WORKFLOW_SCOPE=$WORKFLOW_SCOPE, RESEARCH_COMPLEXITY=$RESEARCH_COMPLEXITY"
```

**File**: `/home/benjamin/.config/.claude/commands/orchestrate.md`
**Location**: After line 109 (after successful sm_init)

**Add**:
```bash
# VERIFICATION CHECKPOINT: Verify critical variables exported by sm_init
# Standard 0 (Execution Enforcement): Critical state initialization must be verified
if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not exported by sm_init despite successful return code (library bug)" 1
fi

echo "✓ State machine variables verified: WORKFLOW_SCOPE=$WORKFLOW_SCOPE"
```

### Rationale

- Detects library-level bugs where sm_init() returns 0 but fails to export
- Provides clear distinction between classification failure (Phase 1-2) and export failure (Phase 3)
- Follows Standard 0 (Execution Enforcement) for critical operations
- Uses defensive programming (verify assumptions)

### Success Criteria

- [ ] Verification checkpoints added after successful sm_init()
- [ ] Clear error messages distinguish export failures from classification failures
- [ ] Success message shows actual variable values for debugging

### Testing

Run test with mock sm_init() that returns 0 but doesn't export:
```bash
# Mock sm_init in test environment
sm_init() {
  # Simulate success without exporting variables
  return 0
}

# Invoke /coordinate
/coordinate "test workflow description"

# Expected: Verification checkpoint catches missing export
# Error: "CRITICAL: WORKFLOW_SCOPE not exported by sm_init..."
```

---

## Phase 4: Improve Error Messages with Troubleshooting Steps

**Objective**: Enhance error messages in workflow-state-machine.sh to provide actionable guidance.

### Code Changes

**File**: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`
**Line**: 371-376 (sm_init function error handling)

**Before**:
```bash
else
  # Fail-fast: No automatic fallback (lines 371-376)
  echo "CRITICAL ERROR: Comprehensive classification failed" >&2
  echo "  Workflow Description: $workflow_desc" >&2
  echo "  Suggestion: Check network connection, increase WORKFLOW_CLASSIFICATION_TIMEOUT, or use regex-only mode" >&2
  return 1
fi
```

**After**:
```bash
else
  # Fail-fast: No automatic fallback (clean-break approach from Spec 688 Phase 3)
  echo "CRITICAL ERROR: Comprehensive classification failed" >&2
  echo "  Workflow Description: $workflow_desc" >&2
  echo "  Classification Mode: ${WORKFLOW_CLASSIFICATION_MODE:-llm-only}" >&2
  echo "" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  1. Check network connection (LLM classification requires API access)" >&2
  echo "  2. Increase timeout: export WORKFLOW_CLASSIFICATION_TIMEOUT=60" >&2
  echo "  3. Use offline mode: export WORKFLOW_CLASSIFICATION_MODE=regex-only" >&2
  echo "  4. Check API credentials if using external classification service" >&2
  echo "" >&2
  return 1
fi
```

### Changes Explained

1. **Show current classification mode** - User knows what mode failed
2. **Numbered troubleshooting steps** - Clear, actionable guidance
3. **Separate sections with blank lines** - Improved readability
4. **Specific commands to run** - Copy-paste ready solutions
5. **Context comment** - References Spec 688 for future maintainers

### Rationale

- Error messages are first line of defense for users
- Numbered steps reduce cognitive load
- Showing current mode helps diagnose configuration issues
- Follows research report recommendation (lines 488-519)

### Success Criteria

- [ ] Error message includes current classification mode
- [ ] Troubleshooting steps numbered 1-4
- [ ] Commands are copy-paste ready
- [ ] Error still goes to stderr (>&2)

### Testing

Trigger error and verify message format:
```bash
# Force classification failure
export WORKFLOW_CLASSIFICATION_MODE=llm-only
unset ANTHROPIC_API_KEY

# Should see improved error message with troubleshooting steps
/coordinate "test workflow"
```

---

## Phase 5: Add Comprehensive Tests for Failure Modes

**Objective**: Create test suite to prevent regression and validate all error paths.

### Test File 1: Unit Tests for sm_init() Return Code Checking

**File**: `/home/benjamin/.config/.claude/tests/test_sm_init_error_handling.sh`

```bash
#!/usr/bin/env bash
# Test sm_init() error handling in coordinate and orchestrate commands
# Spec 698: Error handling fixes for classification failures

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${SCRIPT_DIR}/test_helpers.sh"

# Test suite metadata
TEST_SUITE="sm_init Error Handling"
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

echo "=== $TEST_SUITE ==="
echo ""

# ==============================================================================
# Test 1: sm_init() Failure Causes Immediate Exit in /coordinate
# ==============================================================================

test_coordinate_sm_init_failure_exits_immediately() {
  echo "Test 1: /coordinate sm_init() failure causes immediate exit"

  # Setup: Force classification failure
  export WORKFLOW_CLASSIFICATION_MODE=llm-only
  unset ANTHROPIC_API_KEY

  # Create test workflow description file
  mkdir -p "${HOME}/.claude/tmp"
  WORKFLOW_TEMP_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc_test_$$.txt"
  echo "test workflow description" > "$WORKFLOW_TEMP_FILE"
  echo "$WORKFLOW_TEMP_FILE" > "${HOME}/.claude/tmp/coordinate_workflow_desc_path.txt"

  # Execute coordinate bash block 2 (initialization) and capture output
  OUTPUT=$(bash -c '
    set -euo pipefail
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    export CLAUDE_PROJECT_DIR

    # Source libraries
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"

    # Read workflow description
    COORDINATE_DESC_FILE=$(cat "${HOME}/.claude/tmp/coordinate_workflow_desc_path.txt")
    WORKFLOW_DESCRIPTION=$(cat "$COORDINATE_DESC_FILE")
    SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"

    # Attempt sm_init (should fail and call handle_state_error)
    if ! sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1; then
      handle_state_error "State machine initialization failed" 1
    fi

    echo "REACHED_AFTER_SM_INIT"
  ' 2>&1 || true)

  # Verify: Should NOT reach line after sm_init
  if echo "$OUTPUT" | grep -q "REACHED_AFTER_SM_INIT"; then
    test_failed "Execution continued after sm_init failure (return code not checked)"
    return 1
  fi

  # Verify: Error message should be present
  if echo "$OUTPUT" | grep -q "State machine initialization failed"; then
    test_passed
    return 0
  else
    test_failed "Error message not found in output"
    return 1
  fi
}

# ==============================================================================
# Test 2: sm_init() Failure Causes Immediate Exit in /orchestrate
# ==============================================================================

test_orchestrate_sm_init_failure_exits_immediately() {
  echo "Test 2: /orchestrate sm_init() failure causes immediate exit"

  # Setup: Force classification failure
  export WORKFLOW_CLASSIFICATION_MODE=llm-only
  unset ANTHROPIC_API_KEY

  # Execute orchestrate initialization block
  OUTPUT=$(bash -c '
    set -euo pipefail
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    export CLAUDE_PROJECT_DIR

    WORKFLOW_DESCRIPTION="test workflow"

    # Source libraries
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"

    # Attempt sm_init (should fail and call handle_state_error)
    if ! sm_init "$WORKFLOW_DESCRIPTION" "orchestrate" 2>&1; then
      handle_state_error "State machine initialization failed" 1
    fi

    echo "REACHED_AFTER_SM_INIT"
  ' 2>&1 || true)

  # Verify: Should NOT reach line after sm_init
  if echo "$OUTPUT" | grep -q "REACHED_AFTER_SM_INIT"; then
    test_failed "Execution continued after sm_init failure"
    return 1
  fi

  # Verify: Error message should be present
  if echo "$OUTPUT" | grep -q "State machine initialization failed"; then
    test_passed
    return 0
  else
    test_failed "Error message not found in output"
    return 1
  fi
}

# ==============================================================================
# Test 3: sm_init() Success Exports Required Variables
# ==============================================================================

test_sm_init_success_exports_variables() {
  echo "Test 3: sm_init() success exports required variables"

  # Setup: Use regex-only mode (reliable offline)
  export WORKFLOW_CLASSIFICATION_MODE=regex-only

  # Execute sm_init and check exports
  OUTPUT=$(bash -c '
    set -euo pipefail
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    export CLAUDE_PROJECT_DIR

    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    # Call sm_init
    sm_init "research authentication patterns" "coordinate"

    # Check exports
    if [ -z "${WORKFLOW_SCOPE:-}" ]; then
      echo "ERROR: WORKFLOW_SCOPE not exported"
      exit 1
    fi

    if [ -z "${RESEARCH_COMPLEXITY:-}" ]; then
      echo "ERROR: RESEARCH_COMPLEXITY not exported"
      exit 1
    fi

    if [ -z "${RESEARCH_TOPICS_JSON:-}" ]; then
      echo "ERROR: RESEARCH_TOPICS_JSON not exported"
      exit 1
    fi

    echo "SUCCESS: All variables exported"
    echo "  WORKFLOW_SCOPE=$WORKFLOW_SCOPE"
    echo "  RESEARCH_COMPLEXITY=$RESEARCH_COMPLEXITY"
  ' 2>&1)

  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ] && echo "$OUTPUT" | grep -q "SUCCESS: All variables exported"; then
    test_passed
    return 0
  else
    test_failed "Variables not exported correctly: $OUTPUT"
    return 1
  fi
}

# ==============================================================================
# Test 4: Verification Checkpoints Detect Missing Exports
# ==============================================================================

test_verification_checkpoints_detect_missing_exports() {
  echo "Test 4: Verification checkpoints detect missing exports"

  # Mock sm_init that returns 0 but doesn't export
  OUTPUT=$(bash -c '
    set -euo pipefail
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    export CLAUDE_PROJECT_DIR

    source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"

    # Mock sm_init (returns success without exporting)
    sm_init() {
      return 0
    }

    # Call mock sm_init
    if ! sm_init "test" "coordinate" 2>&1; then
      echo "ERROR: sm_init failed"
      exit 1
    fi

    # Verification checkpoint (should catch missing export)
    if [ -z "${WORKFLOW_SCOPE:-}" ]; then
      echo "CHECKPOINT_CAUGHT_MISSING_EXPORT"
      exit 1
    fi

    echo "CHECKPOINT_MISSED_ISSUE"
  ' 2>&1 || true)

  if echo "$OUTPUT" | grep -q "CHECKPOINT_CAUGHT_MISSING_EXPORT"; then
    test_passed
    return 0
  else
    test_failed "Verification checkpoint did not catch missing export"
    return 1
  fi
}

# ==============================================================================
# Test 5: Error Messages Include Troubleshooting Steps
# ==============================================================================

test_error_messages_include_troubleshooting() {
  echo "Test 5: Error messages include troubleshooting steps"

  # Setup: Force classification failure
  export WORKFLOW_CLASSIFICATION_MODE=llm-only
  unset ANTHROPIC_API_KEY

  # Attempt classification
  OUTPUT=$(bash -c '
    set -euo pipefail
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    export CLAUDE_PROJECT_DIR

    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    sm_init "test workflow" "coordinate"
  ' 2>&1 || true)

  # Verify error message contains troubleshooting section
  if echo "$OUTPUT" | grep -q "TROUBLESHOOTING:"; then
    test_passed
    return 0
  else
    test_failed "Error message missing TROUBLESHOOTING section: $OUTPUT"
    return 1
  fi
}

# ==============================================================================
# Test 6: Offline Mode (regex-only) Works Without Network
# ==============================================================================

test_offline_mode_works_without_network() {
  echo "Test 6: Offline mode (regex-only) works without network"

  # Setup: Use regex-only mode, no API key
  export WORKFLOW_CLASSIFICATION_MODE=regex-only
  unset ANTHROPIC_API_KEY

  # Execute classification
  OUTPUT=$(bash -c '
    set -euo pipefail
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    export CLAUDE_PROJECT_DIR

    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    sm_init "research authentication patterns" "coordinate"

    echo "CLASSIFICATION_SUCCESS: WORKFLOW_SCOPE=$WORKFLOW_SCOPE"
  ' 2>&1)

  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ] && echo "$OUTPUT" | grep -q "CLASSIFICATION_SUCCESS"; then
    test_passed
    return 0
  else
    test_failed "Regex-only mode failed: $OUTPUT"
    return 1
  fi
}

# ==============================================================================
# Run All Tests
# ==============================================================================

run_test test_coordinate_sm_init_failure_exits_immediately
run_test test_orchestrate_sm_init_failure_exits_immediately
run_test test_sm_init_success_exports_variables
run_test test_verification_checkpoints_detect_missing_exports
run_test test_error_messages_include_troubleshooting
run_test test_offline_mode_works_without_network

# Print summary
echo ""
echo "=== Test Summary ==="
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All tests passed"
  exit 0
else
  echo "✗ $TESTS_FAILED test(s) failed"
  exit 1
fi
```

### Test File 2: Integration Tests

**File**: `/home/benjamin/.config/.claude/tests/test_coordinate_error_recovery.sh`

```bash
#!/usr/bin/env bash
# Integration tests for /coordinate error recovery
# Spec 698: Verify end-to-end error handling behavior

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TEST_SUITE="Coordinate Error Recovery Integration"
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

echo "=== $TEST_SUITE ==="
echo ""

# ==============================================================================
# Test 1: Classification Failure Shows Helpful Error
# ==============================================================================

test_classification_failure_shows_helpful_error() {
  echo "Test 1: Classification failure shows helpful error with recovery steps"

  # Force LLM classification failure
  export WORKFLOW_CLASSIFICATION_MODE=llm-only
  unset ANTHROPIC_API_KEY

  # Note: Cannot invoke /coordinate directly in test, would need coordination
  # with main Claude Code session. This test validates the error message format.

  # Simulate the error path
  OUTPUT=$(bash -c '
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    sm_init "test workflow" "coordinate" 2>&1 || true
  ')

  # Verify error message components
  CHECKS_PASSED=0

  if echo "$OUTPUT" | grep -q "CRITICAL ERROR"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  fi

  if echo "$OUTPUT" | grep -q "TROUBLESHOOTING:"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  fi

  if echo "$OUTPUT" | grep -q "WORKFLOW_CLASSIFICATION_MODE"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  fi

  if [ $CHECKS_PASSED -eq 3 ]; then
    echo "  ✓ Error message contains all required components"
    test_passed
    return 0
  else
    echo "  ✗ Error message missing components ($CHECKS_PASSED/3 found)"
    test_failed "Incomplete error message"
    return 1
  fi
}

# ==============================================================================
# Test 2: User Can Recover by Switching to regex-only Mode
# ==============================================================================

test_user_can_recover_with_regex_mode() {
  echo "Test 2: User can recover by switching to regex-only mode"

  # Attempt 1: Fail with LLM mode
  export WORKFLOW_CLASSIFICATION_MODE=llm-only
  unset ANTHROPIC_API_KEY

  OUTPUT1=$(bash -c '
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    sm_init "research auth patterns" "coordinate" 2>&1 || echo "ATTEMPT1_FAILED"
  ')

  if ! echo "$OUTPUT1" | grep -q "ATTEMPT1_FAILED"; then
    test_failed "First attempt should have failed"
    return 1
  fi

  # Attempt 2: Succeed with regex mode (following troubleshooting advice)
  export WORKFLOW_CLASSIFICATION_MODE=regex-only

  OUTPUT2=$(bash -c '
    CLAUDE_PROJECT_DIR="'"$PROJECT_ROOT"'"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"

    sm_init "research auth patterns" "coordinate" 2>&1 && echo "ATTEMPT2_SUCCESS"
  ')

  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ] && echo "$OUTPUT2" | grep -q "ATTEMPT2_SUCCESS"; then
    echo "  ✓ User successfully recovered using regex-only mode"
    test_passed
    return 0
  else
    echo "  ✗ Recovery with regex-only mode failed"
    test_failed "Regex mode recovery failed"
    return 1
  fi
}

# Run tests
run_test test_classification_failure_shows_helpful_error
run_test test_user_can_recover_with_regex_mode

# Summary
echo ""
echo "=== Test Summary ==="
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All integration tests passed"
  exit 0
else
  echo "✗ $TESTS_FAILED test(s) failed"
  exit 1
fi
```

### Success Criteria

- [ ] Both test files created and executable
- [ ] All 6 unit tests pass
- [ ] Both integration tests pass
- [ ] Tests run successfully via `./run_all_tests.sh`
- [ ] Test coverage ≥80% for error handling paths

### Testing

Run test suite:
```bash
cd /home/benjamin/.config/.claude/tests

# Run new test files
bash test_sm_init_error_handling.sh
bash test_coordinate_error_recovery.sh

# Run full test suite
bash run_all_tests.sh
```

---

## Phase 6: Update Documentation to Prevent Regression

**Objective**: Document the error handling pattern to prevent future regressions.

### Documentation Updates

#### Update 1: Bash Block Execution Model

**File**: `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md`
**Section**: After Pattern 5 (line 369)

**Add**:

```markdown
### Pattern 6: Return Code Verification for Critical Functions

**Problem**: Bash functions can fail without causing script exit unless explicitly checked.

**Solution**: Always check return codes for critical initialization functions.

**Critical Functions Requiring Checks**:
- `sm_init()` - State machine initialization
- `initialize_workflow_paths()` - Path allocation
- `source_required_libraries()` - Library loading
- `classify_workflow_comprehensive()` - Workflow classification
- Any function that exports state variables

**Pattern**:
```bash
# ❌ ANTI-PATTERN: No return code check
sm_init "$WORKFLOW_DESC" "coordinate" >/dev/null
# Execution continues even if sm_init fails

# ✓ RECOMMENDED: Explicit return code check with error handling
if ! sm_init "$WORKFLOW_DESC" "coordinate" 2>&1; then
  handle_state_error "State machine initialization failed" 1
fi

# ✓ ALTERNATIVE: Compound operator (for simple cases)
sm_init "$WORKFLOW_DESC" "coordinate" || exit 1
```

**Rationale**:
- `set -euo pipefail` does NOT exit on function failures (only simple commands)
- Output redirection (`>/dev/null`) hides critical error messages
- Silent failures lead to unbound variable errors later in execution
- Explicit checks enable fail-fast error handling (CLAUDE.md development philosophy)

**Example from Spec 698**:

Without return code check, `sm_init()` classification failure allowed execution to continue with uninitialized `RESEARCH_COMPLEXITY`, causing unbound variable error 78 lines later. Adding explicit check caught error immediately at line 166 instead of line 244.

**When to Use**:
- Any function that initializes critical state variables
- Functions called in orchestration command initialization blocks
- Library functions that export variables to parent scope
- Operations with complex failure modes (network, file I/O, external APIs)

**Related Standards**:
- Standard 0 (Execution Enforcement) - CLAUDE.md:277-283
- Fail-Fast Policy - CLAUDE.md:211-215
- Verification and Fallback Pattern - verification-fallback.md
```

#### Update 2: Coordinate Command Guide

**File**: `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md`
**Section**: Troubleshooting (add new subsection)

**Add**:

```markdown
### Classification Failures

**Symptom**: Error message "CRITICAL ERROR: Comprehensive classification failed"

**Root Cause**: LLM-based classification requires network access and may fail due to:
- No network connection
- API credentials not set
- Classification timeout (default: 30s)
- API service unavailable

**Solution**: Use offline regex-only mode for development:

```bash
# Set classification mode to regex-only (no network required)
export WORKFLOW_CLASSIFICATION_MODE=regex-only

# Run coordinate command
/coordinate "research authentication patterns"
```

**Alternative Solutions**:

1. **Increase timeout** (for slow connections):
   ```bash
   export WORKFLOW_CLASSIFICATION_TIMEOUT=60
   ```

2. **Check API credentials** (if using external service):
   ```bash
   echo $ANTHROPIC_API_KEY  # Should show key, not empty
   ```

3. **Check network connectivity**:
   ```bash
   curl -I https://api.anthropic.com  # Should return 200 OK
   ```

**Prevention**:

Set default mode in shell profile for offline development:
```bash
# Add to ~/.bashrc or ~/.zshrc
export WORKFLOW_CLASSIFICATION_MODE=regex-only
```

**Related**: See [LLM Classification Pattern](../concepts/patterns/llm-classification-pattern.md) for complete classification mode documentation.
```

#### Update 3: Command Architecture Standards

**File**: `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md`
**Location**: Add new standard after Standard 15

**Add**:

```markdown
## Standard 16: Critical Function Return Code Verification

**Requirement**: All critical initialization functions MUST have their return codes checked.

**Rationale**: Bash `set -euo pipefail` does not exit on function failures, only simple command failures. Silent function failures lead to incomplete state initialization and delayed errors.

**Critical Functions** (non-exhaustive list):
- `sm_init()` - State machine initialization (exports WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON)
- `initialize_workflow_paths()` - Path allocation (exports TOPIC_PATH, PLAN_PATH, REPORT_PATHS)
- `source_required_libraries()` - Library loading (makes functions available)
- `classify_workflow_comprehensive()` - Workflow classification (network-dependent)

**Required Pattern**:

```bash
# Inline error handling (RECOMMENDED for orchestration commands)
if ! critical_function arg1 arg2 2>&1; then
  handle_state_error "critical_function failed: description" 1
fi

# Compound operator (ACCEPTABLE for simple commands)
critical_function arg1 arg2 || exit 1
```

**Prohibited Patterns**:

```bash
# ✗ WRONG: No return code check
critical_function arg1 arg2

# ✗ WRONG: Output redirection hides errors
critical_function arg1 arg2 >/dev/null

# ✗ WRONG: Redirect stdout only (stderr still visible but return code ignored)
critical_function arg1 arg2 1>/dev/null
```

**Verification Checkpoints**:

After successful critical function call, verify exported variables:

```bash
if ! sm_init "$WORKFLOW_DESC" "coordinate" 2>&1; then
  handle_state_error "State machine initialization failed" 1
fi

# VERIFICATION: Ensure critical variables exported
if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not exported despite successful return code" 1
fi
```

**Related Standards**:
- Standard 0: Execution Enforcement (verification checkpoints)
- Standard 15: Library Sourcing Order (function availability)

**Historical Context**: Discovered in Spec 698 where missing return code check in `/coordinate` and `/orchestrate` commands allowed `sm_init()` classification failures to silently proceed, causing unbound variable errors 78 lines later instead of immediate fail-fast behavior.

**Test Requirements**: All commands using critical functions must include unit tests for failure paths (see `.claude/tests/test_sm_init_error_handling.sh` for template).
```

### Success Criteria

- [ ] Pattern 6 added to bash-block-execution-model.md
- [ ] Troubleshooting section added to coordinate-command-guide.md
- [ ] Standard 16 added to command_architecture_standards.md
- [ ] All links and cross-references valid
- [ ] Examples are copy-paste ready

---

## Phase 7: Verify No Other Orchestration Commands Affected

**Objective**: Audit all orchestration commands for the same vulnerability.

### Commands to Audit

1. `/coordinate` - **FIXED in Phase 1**
2. `/orchestrate` - **FIXED in Phase 2**
3. `/supervise` - **CHECK NOW**
4. `/implement` - **CHECK NOW** (uses state machine)

### Audit Procedure

For each command:

1. **Search for `sm_init` calls**:
   ```bash
   grep -n "sm_init" /home/benjamin/.config/.claude/commands/supervise.md
   grep -n "sm_init" /home/benjamin/.config/.claude/commands/implement.md
   ```

2. **Check return code handling**:
   - Line before: Is there `if !` or `||`?
   - Line after: Is there error handling?
   - Is output redirected with `>/dev/null`?

3. **Document findings**:
   - Command name
   - Line number of `sm_init` call
   - Whether return code is checked
   - Whether fix is needed

4. **Apply fix if needed**:
   - Use same pattern from Phase 1-2
   - Add verification checkpoints
   - Update tests

### Expected Results

Based on research report (lines 356-409):

- `/coordinate` - Vulnerable (fixed in Phase 1)
- `/orchestrate` - Vulnerable (fixed in Phase 2)
- `/supervise` - Unknown (need to audit)
- `/implement` - Unknown (need to audit)

### Success Criteria

- [ ] All orchestration commands audited
- [ ] Findings documented
- [ ] All vulnerabilities fixed (if found)
- [ ] Tests updated for any additional fixes

### Rollback Procedure

If new vulnerabilities found:
1. Apply same fix pattern from Phase 1-2
2. Add to test suite (Phase 5)
3. Update documentation (Phase 6)
4. Re-run full test suite

---

## Integration Testing

After all phases complete, run comprehensive integration tests.

### Test Scenarios

#### Scenario 1: LLM Classification Failure (Primary Bug)

```bash
# Setup
export WORKFLOW_CLASSIFICATION_MODE=llm-only
unset ANTHROPIC_API_KEY

# Test /coordinate
/coordinate "research authentication patterns"

# Expected Result:
# - Immediate error at sm_init() call (line 166)
# - Clear error message with troubleshooting steps
# - Exit code 1
# - Does NOT reach line 244 (unbound variable error)
```

#### Scenario 2: Successful Classification (Regression Test)

```bash
# Setup
export WORKFLOW_CLASSIFICATION_MODE=regex-only

# Test /coordinate
/coordinate "research authentication patterns"

# Expected Result:
# - sm_init() succeeds
# - WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON exported
# - Verification checkpoints pass
# - Workflow proceeds to research phase
```

#### Scenario 3: Recovery After Failure

```bash
# Attempt 1: Fail with LLM mode
export WORKFLOW_CLASSIFICATION_MODE=llm-only
unset ANTHROPIC_API_KEY
/coordinate "test workflow"
# Expected: Error with troubleshooting steps

# Attempt 2: Follow troubleshooting advice
export WORKFLOW_CLASSIFICATION_MODE=regex-only
/coordinate "test workflow"
# Expected: Success
```

#### Scenario 4: All Orchestration Commands

Repeat Scenario 1 and 2 for:
- `/coordinate` ✓
- `/orchestrate` ✓
- `/supervise` (if uses sm_init)
- `/implement` (if uses sm_init)

### Success Criteria

- [ ] All 4 scenarios pass for all affected commands
- [ ] No unbound variable errors
- [ ] Error messages clear and actionable
- [ ] Recovery workflow works as documented
- [ ] Test suite passes (run_all_tests.sh)

---

## Rollback Procedures

### Complete Rollback (All Phases)

If critical issues discovered after deployment:

```bash
# Restore from backups
cp /home/benjamin/.config/.claude/commands/coordinate.md.backup-TIMESTAMP \
   /home/benjamin/.config/.claude/commands/coordinate.md

cp /home/benjamin/.config/.claude/commands/orchestrate.md.backup-TIMESTAMP \
   /home/benjamin/.config/.claude/commands/orchestrate.md

# Revert library changes
cd /home/benjamin/.config
git checkout HEAD -- .claude/lib/workflow-state-machine.sh

# Remove test files (if causing issues)
rm -f .claude/tests/test_sm_init_error_handling.sh
rm -f .claude/tests/test_coordinate_error_recovery.sh

# Revert documentation
git checkout HEAD -- \
  .claude/docs/concepts/bash-block-execution-model.md \
  .claude/docs/guides/coordinate-command-guide.md \
  .claude/docs/reference/command_architecture_standards.md

# Verify tests still pass
cd .claude/tests
bash run_all_tests.sh
```

### Partial Rollback (Per Phase)

**Phase 1 only**:
```bash
git checkout HEAD -- .claude/commands/coordinate.md
```

**Phase 2 only**:
```bash
git checkout HEAD -- .claude/commands/orchestrate.md
```

**Phase 4 only**:
```bash
git checkout HEAD -- .claude/lib/workflow-state-machine.sh
```

**Phase 5 only** (remove new tests):
```bash
rm -f .claude/tests/test_sm_init_error_handling.sh
rm -f .claude/tests/test_coordinate_error_recovery.sh
```

**Phase 6 only** (revert docs):
```bash
git checkout HEAD -- .claude/docs/concepts/bash-block-execution-model.md
git checkout HEAD -- .claude/docs/guides/coordinate-command-guide.md
git checkout HEAD -- .claude/docs/reference/command_architecture_standards.md
```

### Rollback Decision Criteria

Rollback if:
- Tests fail after changes (>10% regression)
- New errors introduced in working workflows
- Performance degradation >20%
- Existing functionality broken

Do NOT rollback if:
- Error messages changed (expected)
- Classification failures now caught (expected)
- Test coverage increased (expected)

---

## Success Metrics

### Reliability Metrics

- **Before**: 100% failure rate when LLM classification fails
- **After**: 0% failure rate (immediate error with recovery guidance)

### Error Detection Metrics

- **Before**: Error detected 78 lines after root cause (line 244)
- **After**: Error detected at root cause (line 166)

### User Experience Metrics

- **Before**: Cryptic "unbound variable" error
- **After**: Clear error with 4-step troubleshooting guide

### Test Coverage Metrics

- **Before**: 0 tests for classification failure modes
- **After**: 8 tests (6 unit + 2 integration)

### Documentation Metrics

- **Before**: Pattern not documented
- **After**: 3 documentation updates (bash-block-execution-model.md, coordinate-command-guide.md, command_architecture_standards.md)

---

## Dependencies

### External Dependencies

None - All fixes are self-contained within existing infrastructure.

### Internal Dependencies

- **error-handling.sh**: Must be sourced before sm_init() call (already present)
- **verification-helpers.sh**: Required for verification checkpoints (already present)
- **workflow-state-machine.sh**: Contains sm_init() function (will be updated in Phase 4)
- **state-persistence.sh**: Required for state management (already present)

### Dependency Verification

Before implementation:
```bash
# Verify all required libraries exist
ls -la /home/benjamin/.config/.claude/lib/error-handling.sh
ls -la /home/benjamin/.config/.claude/lib/verification-helpers.sh
ls -la /home/benjamin/.config/.claude/lib/workflow-state-machine.sh
ls -la /home/benjamin/.config/.claude/lib/state-persistence.sh

# Verify handle_state_error() function exists
grep -n "handle_state_error()" /home/benjamin/.config/.claude/lib/error-handling.sh
```

---

## Completion Criteria

### Code Changes Complete

- [ ] coordinate.md updated (Phase 1)
- [ ] orchestrate.md updated (Phase 2)
- [ ] Verification checkpoints added (Phase 3)
- [ ] workflow-state-machine.sh error messages improved (Phase 4)
- [ ] All code changes syntax-checked

### Testing Complete

- [ ] 6 unit tests pass (Phase 5)
- [ ] 2 integration tests pass (Phase 5)
- [ ] Full test suite passes (run_all_tests.sh)
- [ ] Manual integration scenarios pass (all 4)
- [ ] Regression tests pass (existing functionality)

### Documentation Complete

- [ ] bash-block-execution-model.md updated (Phase 6)
- [ ] coordinate-command-guide.md updated (Phase 6)
- [ ] command_architecture_standards.md updated (Phase 6)
- [ ] All links and cross-references validated

### Verification Complete

- [ ] All orchestration commands audited (Phase 7)
- [ ] No additional vulnerabilities found
- [ ] Backups created and verified
- [ ] Rollback procedures tested

### Metrics Achieved

- [ ] 0% failure rate for classification errors (from 100%)
- [ ] Errors detected at root cause (line 166, not 244)
- [ ] Test coverage ≥80% for error paths
- [ ] All success metrics documented

---

## Post-Implementation

### Follow-Up Tasks

1. **Monitor for 2 weeks**:
   - Watch for new error reports related to classification
   - Collect feedback on error message clarity
   - Check if users successfully use regex-only mode

2. **Create Standard Operating Procedure**:
   - Document how to diagnose classification failures
   - Add to orchestration troubleshooting guide
   - Update onboarding documentation

3. **Consider Enhancements** (Future Work):
   - Automatic retry with exponential backoff for transient failures
   - Fallback to regex mode after LLM timeout (with user confirmation)
   - Telemetry for classification success rates

### Knowledge Transfer

Share learnings:
- Present findings at team meeting (if applicable)
- Update command development guide with lessons learned
- Add to code review checklist: "Are return codes checked for critical functions?"

---

## Appendix A: Code Snippet Reference

### Correct sm_init() Pattern

```bash
# Standard pattern for all orchestration commands
if ! sm_init "$WORKFLOW_DESCRIPTION" "coordinate" 2>&1; then
  handle_state_error "State machine initialization failed (workflow classification error). Check network connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline development." 1
fi

# Verification checkpoint
if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not exported by sm_init" 1
fi
```

### Error Message Template

```bash
echo "CRITICAL ERROR: Operation failed" >&2
echo "  Context: $CONTEXT_INFO" >&2
echo "  Mode: $CURRENT_MODE" >&2
echo "" >&2
echo "TROUBLESHOOTING:" >&2
echo "  1. Action step 1" >&2
echo "  2. Action step 2" >&2
echo "  3. Action step 3" >&2
echo "" >&2
```

### Test Template

```bash
test_function_name() {
  echo "Test N: Description"

  # Setup
  export TEST_VAR=value

  # Execute
  OUTPUT=$(bash -c 'command_to_test' 2>&1 || true)

  # Verify
  if echo "$OUTPUT" | grep -q "EXPECTED_STRING"; then
    test_passed
    return 0
  else
    test_failed "Reason"
    return 1
  fi
}
```

---

## Appendix B: Related Specifications

- **Spec 688**: Clean-break update removing hybrid mode (context for fail-fast design)
- **Spec 620**: Bash block execution model discovery (subprocess isolation)
- **Spec 630**: State persistence architecture (cross-block state management)
- **Spec 678**: Comprehensive workflow classification (classification system design)

---

## Appendix C: References

### CLAUDE.md Sections

- **Standard 0 (Execution Enforcement)**: Lines 277-283
- **Fail-Fast Policy**: Lines 211-215
- **Development Philosophy**: Lines 185-233
- **Testing Protocols**: Lines 61-98
- **Code Standards**: Lines 100-183

### Documentation Files

- **bash-block-execution-model.md**: Subprocess isolation patterns
- **coordinate-command-guide.md**: Command usage and troubleshooting
- **command_architecture_standards.md**: Formal architectural requirements
- **error-handling.sh**: Error handling utilities
- **verification-helpers.sh**: Verification checkpoint utilities

### Research Report

- **001_error_handling_root_cause_analysis.md**: Complete root cause analysis, fix strategies, testing recommendations, prevention guidelines

---

**END OF PLAN**

PLAN_CREATED: /home/benjamin/.config/.claude/specs/698_coordinate_error_handling/plans/001_error_handling_fix_implementation.md
