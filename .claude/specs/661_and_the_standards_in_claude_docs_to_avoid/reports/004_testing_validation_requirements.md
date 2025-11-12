# Testing and Validation Requirements for Coordinate Command Fixes

## Metadata
- **Date**: 2025-11-11
- **Agent**: research-specialist
- **Topic**: Testing and validation requirements for coordinate command bash block execution fixes
- **Report Type**: codebase analysis
- **Complexity Level**: 2

## Executive Summary

The coordinate command has extensive test coverage (105 test files, 10 coordinate-specific) but lacks targeted tests for two critical bash block execution fixes: (1) STATE_ID_FILE persistence across bash block boundaries using EXIT traps, and (2) library sourcing order ensuring state-persistence.sh loads before dependent libraries. Existing tests validate state persistence, library sourcing order, and bash block isolation but don't specifically test the subprocess EXIT trap timing issue or the cumulative effect of library loading sequence. Eight new test cases are required to maintain 100% reliability, focusing on EXIT trap behavior, file persistence verification, and library re-sourcing patterns across bash blocks.

## Findings

### Current Test Infrastructure

**Test Location**: `/home/benjamin/.config/.claude/tests/`
**Test Runner**: `/home/benjamin/.config/.claude/tests/run_all_tests.sh`
**Total Test Files**: 105 bash test scripts

**Test Pattern Discovery**:
- Naming convention: `test_*.sh` for unit/integration tests
- Validation scripts: `validate_*.sh` for standards compliance
- All tests discoverable via `find "$TEST_DIR" -name "test_*.sh"` (run_all_tests.sh:34)

**Test Categories Relevant to Coordinate Fixes**:
1. **State Persistence**: `test_state_persistence.sh` (18 tests)
2. **Library Sourcing**: `test_library_sourcing_order.sh` (4 tests)
3. **Bash Block Isolation**: `test_cross_block_function_availability.sh` (3 tests)
4. **Concurrent Workflows**: `test_concurrent_workflows.sh` (state ID isolation)
5. **Coordinate Error Fixes**: `test_coordinate_error_fixes.sh` (31 tests including Phase 1-3 defensive patterns)

**Test Coverage Target**: ≥80% for modified code, ≥60% baseline (CLAUDE.md:74)

### Coordinate Command Tests

**10 Coordinate-Specific Test Files Found**:
1. `test_coordinate_basic.sh` - Basic functionality (6 tests)
2. `test_coordinate_error_fixes.sh` - Error handling (31 tests)
3. `test_coordinate_waves.sh` - Wave-based parallel execution
4. `test_coordinate_delegation.sh` - Agent delegation patterns
5. `test_coordinate_standards.sh` - Standard 11 compliance
6. `test_coordinate_synchronization.sh` - Concurrent workflow isolation
7. `test_coordinate_verification.sh` - Verification checkpoint testing
8. `test_state_persistence_coordinate.sh` - Coordinate-specific state tests
9. `verify_coordinate_standard11.sh` - Validation script for agent invocation patterns
10. `test_coordinate_all.sh` - Comprehensive test suite

**Key Test Coverage from test_coordinate_error_fixes.sh**:
- JSON parsing (empty arrays, malformed JSON recovery) - Tests 1-3 (lines 44-142)
- State file verification (missing files, content validation) - Tests 4-6 (lines 146-238)
- State transitions (initialize → research → plan → implement) - Test 5 (lines 165-203)
- Phase 1: Defensive array reconstruction - Tests 11-14 (lines 406-523)
- Phase 2: COMPLETED_STATES persistence - Tests 15-18 (lines 532-670)
- Phase 3: Fail-fast state validation - Tests 19-22 (lines 676-831)

**What's Tested Well**:
- State persistence across subprocess boundaries (Test 14, line 286)
- Multiple workflow isolation (Test 15, line 307)
- Array serialization/deserialization patterns
- Fail-fast behavior when state files missing

### Bash Block Execution Model Documentation

**Critical Documentation**: `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md`

**Key Findings from Documentation**:
- Each bash block runs as **separate subprocess** (not subshell)
- Process ID (`$$`) changes between blocks (lines 40-42)
- Environment variables reset - exports lost (line 41)
- Bash functions lost - must re-source libraries (line 42)
- **Trap handlers fire at block exit, not workflow exit** (line 43) ⚠️
- Only files written to disk persist across blocks (lines 55-58)

**Validation Test Pattern** (lines 74-145):
```bash
# Test demonstrates:
1. Process IDs differ between blocks
2. Environment variables lost across blocks
3. Files are ONLY reliable cross-block communication
```

**Related Tests Found**:
- `test_cross_block_function_availability.sh` - Validates library re-sourcing (100 lines)
- `test_phase2_caching.sh` - Tests bash block caching patterns
- `test_history_expansion.sh` - Tests set +H for history expansion issues
- `test_array_serialization.sh` - Tests array persistence patterns

### State Persistence Tests

**File**: `test_state_persistence.sh` (405 lines, 18 tests)

**Test Coverage Analysis**:
1. **init_workflow_state creates file** (Test 1, line 58)
2. **State file contains CLAUDE_PROJECT_DIR** (Test 2, line 71)
3. **State file contains WORKFLOW_ID** (Test 3, line 83)
4. **load_workflow_state restores variables** (Test 4, line 96)
5. **Graceful degradation for missing files** (Test 5, line 116)
6. **append_workflow_state adds variables** (Test 6, line 138)
7. **Multiple append accumulation** (Test 7, line 152)
8. **save_json_checkpoint creates file** (Test 8, line 173)
9. **Atomic write cleanup** (Test 9, line 191)
10. **load_json_checkpoint reads data** (Test 10, line 212)
11. **Graceful degradation for missing checkpoints** (Test 11, line 231)
12. **append_jsonl_log creates log** (Test 12, line 246)
13. **JSONL accumulates entries** (Test 13, line 264)
14. **State persists across subprocess boundaries** (Test 14, line 285) ⭐
15. **Multiple workflows isolated** (Test 15, line 307)
16. **Error handling - append without init** (Test 16, line 336)
17. **Error handling - checkpoint without init** (Test 17, line 350)
18. **Performance - caching benefit** (Test 18, line 362)

**Critical Test for Fixes** (Test 14, lines 285-303):
```bash
# Simulates subprocess (new bash invocation)
RESULT=$(bash -c "
  source '${PROJECT_ROOT}/.claude/lib/state-persistence.sh'
  load_workflow_state '$TEST_WORKFLOW_ID' >/dev/null 2>&1
  echo \"\${SUBPROCESS_TEST:-missing}\"
")
```
This validates state file survival but **does NOT test EXIT trap timing**.

### Library Sourcing Order Tests

**File**: `test_library_sourcing_order.sh` (179 lines, 4 tests)

**Test Coverage**:
1. **verify_state_variable sourced before first call** (line 33)
   - Checks verification-helpers.sh sourced before usage
   - Validates source line < first call line

2. **Source guards present** (line 63)
   - Checks ERROR_HANDLING_SOURCED guard exists
   - Checks VERIFICATION_HELPERS_SOURCED guard exists

3. **Early sourcing** (line 86)
   - Validates error-handling.sh sourced < line 150
   - Validates verification-helpers.sh sourced < line 150

4. **Dependency order** (line 112)
   - state-persistence.sh BEFORE error-handling.sh
   - state-persistence.sh BEFORE verification-helpers.sh

**What's Missing**: Tests don't verify **cumulative sourcing effect** across bash blocks or test re-sourcing patterns in subsequent blocks.

### Test Coverage Gaps

**Gap 1: EXIT Trap Timing in First Bash Block**
- **Issue**: COORDINATE_STATE_ID_FILE created with EXIT trap that fires when first bash block exits (coordinate.md:137-141)
- **Current Testing**: No test validates file survives first bash block exit
- **Why Critical**: Subprocess isolation means EXIT trap fires immediately, not at workflow end
- **Location**: coordinate.md:137: `trap "rm -f '$COORDINATE_STATE_ID_FILE' 2>/dev/null || true" EXIT`

**Gap 2: State ID File Persistence Pattern**
- **Issue**: State ID file must persist after first block for subsequent blocks to load workflow state
- **Current Testing**: test_state_persistence.sh:285 tests subprocess survival but doesn't test EXIT trap interaction
- **Why Critical**: File must exist when second bash block runs (coordinate.md:358-375)

**Gap 3: Library Re-sourcing Across Bash Blocks**
- **Issue**: Libraries must be re-sourced in EVERY bash block with correct order
- **Current Testing**: test_library_sourcing_order.sh tests first block only, not subsequent blocks
- **Why Critical**: Functions lost across subprocess boundaries (bash-block-execution-model.md:42)
- **Pattern**: coordinate.md:340-350, 490-500, 795-805 (repeated re-sourcing blocks)

**Gap 4: Library Sourcing Order in Subsequent Blocks**
- **Issue**: state-persistence.sh must load BEFORE workflow-state-machine.sh in all blocks
- **Current Testing**: test_library_sourcing_order.sh:112-134 checks first initialization only
- **Why Critical**: workflow-state-machine.sh depends on state persistence functions
- **Example**: coordinate.md:349-350 sources both but order must be validated

**Gap 5: Verification Checkpoint After Library Sourcing**
- **Issue**: Verification checkpoints should validate library functions available before use
- **Current Testing**: No tests validate verification runs after complete library initialization
- **Why Critical**: Fail-fast if libraries not sourced correctly

**Gap 6: COORDINATE_STATE_ID_FILE Backward Compatibility**
- **Issue**: Code supports both old fixed location and new timestamp-based location (coordinate.md:358-375)
- **Current Testing**: No test validates fallback to old location works
- **Why Critical**: Maintains compatibility during transition period

**Gap 7: State File Not Found Error Handling**
- **Issue**: Should produce clear diagnostic when state ID file missing (coordinate.md:372-375)
- **Current Testing**: test_state_persistence.sh:116 tests graceful degradation but not coordinate-specific error messages
- **Why Critical**: 100% reliability requires informative error messages

**Gap 8: Cross-Block State Variable Availability**
- **Issue**: Variables saved in first block must be available in subsequent blocks
- **Current Testing**: Generic test exists but not coordinate-specific variable set (WORKFLOW_SCOPE, REPORT_PATHS, WORKFLOW_ID)
- **Why Critical**: Coordinate uses specific variables that must persist

## Recommendations

### Recommendation 1: Create Dedicated Bash Block EXIT Trap Test

**Priority**: CRITICAL
**File**: Create new `test_coordinate_exit_trap_timing.sh`

Add targeted test validating EXIT trap behavior in subprocess isolation context:
```bash
# Test that EXIT trap doesn't fire until bash block completes
# Validates state ID file survives first block exit
test_exit_trap_timing() {
  # Block 1: Create file with EXIT trap
  bash -c '
    FILE="/tmp/test_exit_trap_$$.txt"
    echo "data" > "$FILE"
    trap "rm -f \"$FILE\"" EXIT
    echo "$FILE"
  ' > /tmp/exit_trap_file_path.txt

  # Verify file was deleted by EXIT trap
  FILE_PATH=$(cat /tmp/exit_trap_file_path.txt)
  if [ ! -f "$FILE_PATH" ]; then
    pass "EXIT trap fired at bash block exit"
  else
    fail "EXIT trap did not fire"
  fi
}
```

**Rationale**: Existing tests don't validate EXIT trap timing in subprocess context (bash-block-execution-model.md:43).

### Recommendation 2: Add State ID File Persistence Validation

**Priority**: CRITICAL
**File**: Extend `test_coordinate_error_fixes.sh`

Add test case validating COORDINATE_STATE_ID_FILE survives bash block boundaries:
```bash
test_state_id_file_persistence_across_blocks() {
  # Simulate first bash block (initialization)
  WORKFLOW_ID="test_workflow_$$"
  TIMESTAMP=$(date +%s%N)
  STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_${TIMESTAMP}.txt"

  # Block 1: Create state ID file (simulates coordinate.md:137-141)
  bash -c "
    echo \"$WORKFLOW_ID\" > \"$STATE_ID_FILE\"
    # Don't set EXIT trap here - test persistence without trap
  "

  # Block 2: Verify file still exists for subsequent block load
  if [ -f "$STATE_ID_FILE" ]; then
    LOADED_ID=$(cat "$STATE_ID_FILE")
    if [ "$LOADED_ID" = "$WORKFLOW_ID" ]; then
      pass "State ID file persisted across bash block boundary"
    fi
  else
    fail "State ID file missing in subsequent block"
  fi

  rm -f "$STATE_ID_FILE"
}
```

**Rationale**: Addresses Gap 2 - validates fix for state ID file persistence pattern.

### Recommendation 3: Multi-Block Library Re-sourcing Test

**Priority**: HIGH
**File**: Extend `test_cross_block_function_availability.sh`

Add test validating library functions available across multiple bash blocks:
```bash
test_multi_block_library_availability() {
  # Block 1: Source libraries
  bash -c '
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

    # Verify functions available in block 1
    command -v init_workflow_state || exit 1
    command -v sm_init || exit 1
    echo "block1_success"
  ' > /tmp/block1_result.txt

  # Block 2: Re-source libraries (simulates coordinate.md:340-350)
  bash -c '
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

    # Verify functions available in block 2
    command -v init_workflow_state || exit 1
    command -v sm_init || exit 1
    echo "block2_success"
  ' > /tmp/block2_result.txt

  if grep -q "block1_success" /tmp/block1_result.txt && \
     grep -q "block2_success" /tmp/block2_result.txt; then
    pass "Libraries available across multiple bash blocks"
  else
    fail "Library re-sourcing failed"
  fi
}
```

**Rationale**: Addresses Gap 3 - validates libraries must be re-sourced in every block.

### Recommendation 4: Library Sourcing Order Validation in All Blocks

**Priority**: HIGH
**File**: Extend `test_library_sourcing_order.sh`

Add test validating sourcing order in subsequent bash blocks:
```bash
test_subsequent_block_sourcing_order() {
  # Check all bash block re-sourcing sections in coordinate.md
  COORDINATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/commands/coordinate.md"

  # Find all "Re-source critical libraries" sections
  BLOCK_NUMBERS=$(grep -n "Re-source critical libraries" "$COORDINATE_FILE" | cut -d: -f1)

  violations=0
  for line_num in $BLOCK_NUMBERS; do
    # Extract 10 lines after "Re-source critical libraries"
    block=$(sed -n "${line_num},$((line_num + 10))p" "$COORDINATE_FILE")

    # Find line numbers for each library within this block
    state_persist_line=$(echo "$block" | grep -n "state-persistence.sh" | cut -d: -f1 | head -1)
    state_machine_line=$(echo "$block" | grep -n "workflow-state-machine.sh" | cut -d: -f1 | head -1)

    if [ -n "$state_persist_line" ] && [ -n "$state_machine_line" ]; then
      if [ "$state_persist_line" -gt "$state_machine_line" ]; then
        echo "  ✗ Block at line $line_num: state-persistence.sh AFTER workflow-state-machine.sh"
        violations=$((violations + 1))
      fi
    fi
  done

  if [ "$violations" -eq 0 ]; then
    pass "All bash blocks maintain correct library sourcing order"
  else
    fail "Found $violations sourcing order violations"
  fi
}
```

**Rationale**: Addresses Gap 4 - validates correct order in ALL bash blocks, not just first initialization.

### Recommendation 5: Backward Compatibility Test for State ID File

**Priority**: MEDIUM
**File**: Extend `test_coordinate_error_fixes.sh`

Add test validating fallback to old fixed location:
```bash
test_state_id_backward_compatibility() {
  # Test old fixed location pattern (coordinate.md:358-375)
  OLD_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
  WORKFLOW_ID="test_workflow_$$"

  # Create state ID file at old location
  echo "$WORKFLOW_ID" > "$OLD_STATE_ID_FILE"

  # Create workflow state
  STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
  append_workflow_state "TEST_VAR" "test_value"

  # Simulate loading in subsequent block (should find old location)
  bash -c "
    source .claude/lib/state-persistence.sh
    OLD_FILE=\"${HOME}/.claude/tmp/coordinate_state_id.txt\"
    if [ -f \"\$OLD_FILE\" ]; then
      WF_ID=\$(cat \"\$OLD_FILE\")
      load_workflow_state \"\$WF_ID\" >/dev/null 2>&1
      echo \"\${TEST_VAR:-missing}\"
    fi
  " > /tmp/compat_test_result.txt

  if grep -q "test_value" /tmp/compat_test_result.txt; then
    pass "Backward compatibility with old state ID location"
  else
    fail "Old state ID location fallback failed"
  fi

  rm -f "$OLD_STATE_ID_FILE" "$STATE_FILE"
}
```

**Rationale**: Addresses Gap 6 - validates transition compatibility.

### Recommendation 6: Enhanced Error Message Validation

**Priority**: MEDIUM
**File**: Extend `test_coordinate_error_fixes.sh`

Add test validating diagnostic error messages:
```bash
test_missing_state_id_error_message() {
  # Remove any existing state ID files
  rm -f "${HOME}/.claude/tmp/coordinate_state_id*.txt"

  # Simulate error condition (coordinate.md:372-375)
  ERROR_OUTPUT=$(bash -c '
    COORDINATE_STATE_ID_FILE_OLD="${HOME}/.claude/tmp/coordinate_state_id.txt"
    if [ ! -f "$COORDINATE_STATE_ID_FILE_OLD" ]; then
      echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE_OLD"
      echo "Cannot restore workflow state. This is a critical error."
      exit 1
    fi
  ' 2>&1 || echo "error_occurred")

  if echo "$ERROR_OUTPUT" | grep -q "ERROR: Workflow state ID file not found" && \
     echo "$ERROR_OUTPUT" | grep -q "Cannot restore workflow state"; then
    pass "Clear diagnostic error message when state ID missing"
  else
    fail "Error message missing or unclear"
  fi
}
```

**Rationale**: Addresses Gap 7 - validates informative error messages for 100% reliability.

### Recommendation 7: Coordinate-Specific Variable Persistence Test

**Priority**: HIGH
**File**: Create new `test_coordinate_state_variables.sh`

Add test validating coordinate-specific variables persist:
```bash
test_coordinate_variables_across_blocks() {
  WORKFLOW_ID="test_coordinate_vars_$$"

  # Block 1: Initialize with coordinate-specific variables
  bash -c "
    source .claude/lib/state-persistence.sh
    STATE_FILE=\$(init_workflow_state \"$WORKFLOW_ID\")
    append_workflow_state \"WORKFLOW_SCOPE\" \"research-and-plan\"
    append_workflow_state \"TOPIC_PATH\" \"/tmp/test_topic\"
    append_workflow_state \"WORKFLOW_ID\" \"$WORKFLOW_ID\"

    # Save report paths array
    echo \"export REPORT_PATH_0='/tmp/report1.md'\" >> \"\$STATE_FILE\"
    echo \"export REPORT_PATH_1='/tmp/report2.md'\" >> \"\$STATE_FILE\"
    echo \"export REPORT_PATHS_COUNT=2\" >> \"\$STATE_FILE\"
  "

  # Block 2: Load and verify all variables available
  RESULT=$(bash -c "
    source .claude/lib/state-persistence.sh
    load_workflow_state \"$WORKFLOW_ID\" >/dev/null 2>&1

    echo \"WORKFLOW_SCOPE=\${WORKFLOW_SCOPE:-missing}\"
    echo \"TOPIC_PATH=\${TOPIC_PATH:-missing}\"
    echo \"WORKFLOW_ID=\${WORKFLOW_ID:-missing}\"
    echo \"REPORT_PATH_0=\${REPORT_PATH_0:-missing}\"
    echo \"REPORT_PATHS_COUNT=\${REPORT_PATHS_COUNT:-missing}\"
  ")

  if echo "$RESULT" | grep -q "WORKFLOW_SCOPE=research-and-plan" && \
     echo "$RESULT" | grep -q "TOPIC_PATH=/tmp/test_topic" && \
     echo "$RESULT" | grep -q "REPORT_PATHS_COUNT=2"; then
    pass "Coordinate-specific variables persisted across blocks"
  else
    fail "Coordinate variables not available in subsequent block"
  fi

  # Cleanup
  rm -f "${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
}
```

**Rationale**: Addresses Gap 8 - validates actual coordinate workflow variables persist correctly.

### Recommendation 8: Integration Test for Complete Fix

**Priority**: CRITICAL
**File**: Create new `test_coordinate_bash_block_fixes_integration.sh`

Add end-to-end integration test covering both fixes:
```bash
test_complete_bash_block_fix_integration() {
  WORKFLOW_ID="test_integration_$$"
  TIMESTAMP=$(date +%s%N)
  STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_${TIMESTAMP}.txt"

  # Block 1: Initialization with state ID file (NO EXIT trap)
  bash -c "
    set -euo pipefail
    CLAUDE_PROJECT_DIR=\"\$(git rev-parse --show-toplevel)\"
    LIB_DIR=\"\${CLAUDE_PROJECT_DIR}/.claude/lib\"

    # Source libraries IN ORDER
    source \"\${LIB_DIR}/state-persistence.sh\"
    source \"\${LIB_DIR}/workflow-state-machine.sh\"

    # Create state ID file
    echo \"$WORKFLOW_ID\" > \"$STATE_ID_FILE\"

    # Initialize workflow state
    STATE_FILE=\$(init_workflow_state \"$WORKFLOW_ID\")
    append_workflow_state \"COORDINATE_STATE_ID_FILE\" \"$STATE_ID_FILE\"
    append_workflow_state \"WORKFLOW_SCOPE\" \"research-and-plan\"

    echo \"block1_complete\"
  "

  # Block 2: Load state and verify (simulates subsequent bash block)
  RESULT=$(bash -c "
    set -euo pipefail
    CLAUDE_PROJECT_DIR=\"\$(git rev-parse --show-toplevel)\"
    LIB_DIR=\"\${CLAUDE_PROJECT_DIR}/.claude/lib\"

    # Re-source libraries IN SAME ORDER
    source \"\${LIB_DIR}/state-persistence.sh\"
    source \"\${LIB_DIR}/workflow-state-machine.sh\"

    # Load state ID file
    if [ -f \"$STATE_ID_FILE\" ]; then
      WF_ID=\$(cat \"$STATE_ID_FILE\")
      load_workflow_state \"\$WF_ID\" >/dev/null 2>&1

      # Verify variables available
      if [ \"\${WORKFLOW_SCOPE:-}\" = \"research-and-plan\" ] && \
         [ \"\${COORDINATE_STATE_ID_FILE:-}\" = \"$STATE_ID_FILE\" ]; then
        echo \"block2_complete\"
      else
        echo \"block2_variables_missing\"
      fi
    else
      echo \"state_id_file_missing\"
    fi
  ")

  if echo "$RESULT" | grep -q "block2_complete"; then
    pass "Complete bash block fix integration test"
  else
    fail "Integration test failed: $RESULT"
  fi

  # Cleanup
  rm -f "$STATE_ID_FILE"
  rm -f "${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
}
```

**Rationale**: Validates both fixes work together in realistic coordinate workflow scenario.

## Test Case Requirements

### State ID File Persistence Fix

**Fix Location**: `/home/benjamin/.config/.claude/commands/coordinate.md:137-141`

**Problem**: EXIT trap fires at bash block exit (subprocess termination), not workflow end, deleting state ID file needed by subsequent blocks.

**Required Test Cases**:
1. **Exit Trap Timing** (Recommendation 1)
   - Validates EXIT trap fires at bash block exit
   - File: `test_coordinate_exit_trap_timing.sh`
   - Coverage: bash-block-execution-model.md:43

2. **State ID File Persistence** (Recommendation 2)
   - Validates state ID file survives first bash block
   - File: `test_coordinate_error_fixes.sh` (extend)
   - Coverage: coordinate.md:137-141, 358-375

3. **Backward Compatibility** (Recommendation 5)
   - Validates fallback to old fixed location
   - File: `test_coordinate_error_fixes.sh` (extend)
   - Coverage: coordinate.md:358-375

4. **Error Message Clarity** (Recommendation 6)
   - Validates diagnostic messages when file missing
   - File: `test_coordinate_error_fixes.sh` (extend)
   - Coverage: coordinate.md:372-375

### Library Sourcing Order Fix

**Fix Location**: `/home/benjamin/.config/.claude/commands/coordinate.md:340-350, 490-500, 795-805`

**Problem**: Libraries must be re-sourced in every bash block with correct dependency order (state-persistence.sh before workflow-state-machine.sh).

**Required Test Cases**:
1. **Multi-Block Library Availability** (Recommendation 3)
   - Validates functions available across all bash blocks
   - File: `test_cross_block_function_availability.sh` (extend)
   - Coverage: coordinate.md:340-350 (all re-sourcing blocks)

2. **Sourcing Order in All Blocks** (Recommendation 4)
   - Validates correct order in subsequent blocks
   - File: `test_library_sourcing_order.sh` (extend)
   - Coverage: All bash blocks with library re-sourcing

3. **Coordinate Variables Persistence** (Recommendation 7)
   - Validates coordinate-specific variables persist
   - File: `test_coordinate_state_variables.sh` (new)
   - Coverage: WORKFLOW_SCOPE, REPORT_PATHS, WORKFLOW_ID

4. **Integration Test** (Recommendation 8)
   - Validates complete fix end-to-end
   - File: `test_coordinate_bash_block_fixes_integration.sh` (new)
   - Coverage: Both fixes working together

### Validation Checkpoints

**Checkpoint 1: Test Creation Verification**
- All 8 test cases implemented
- Test files follow naming convention (test_*.sh)
- Tests discoverable by run_all_tests.sh

**Checkpoint 2: Test Execution Verification**
```bash
# Run new tests individually
.claude/tests/test_coordinate_exit_trap_timing.sh
.claude/tests/test_coordinate_bash_block_fixes_integration.sh

# Run all coordinate tests
.claude/tests/test_coordinate_all.sh

# Run full test suite
.claude/tests/run_all_tests.sh
```

**Checkpoint 3: Coverage Validation**
- New tests cover all 8 identified gaps
- Existing tests still pass (zero regression)
- Coverage meets ≥80% target for modified code

**Checkpoint 4: Reliability Validation**
- 100% file creation reliability maintained
- Fail-fast error detection works correctly
- Diagnostic messages clear and actionable

**Success Criteria**:
- [ ] All 8 new test cases implemented
- [ ] All new tests pass (100%)
- [ ] All existing coordinate tests pass (zero regression)
- [ ] Coverage ≥80% for bash block execution fixes
- [ ] Integration test validates both fixes work together
- [ ] Documentation updated in test files explaining what's tested and why

## References

**Primary Implementation Files**:
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 137-141, 340-350, 358-375, 490-500, 795-805)
- `/home/benjamin/.config/.claude/specs/661_and_the_standards_in_claude_docs_to_avoid/plans/001_coordinate_revision_fixes.md`

**Test Infrastructure**:
- `/home/benjamin/.config/.claude/tests/run_all_tests.sh` (line 34: test discovery)
- `/home/benjamin/.config/.claude/tests/test_coordinate_error_fixes.sh` (858 lines, 31 tests)
- `/home/benjamin/.config/.claude/tests/test_state_persistence.sh` (405 lines, 18 tests)
- `/home/benjamin/.config/.claude/tests/test_library_sourcing_order.sh` (179 lines, 4 tests)
- `/home/benjamin/.config/.claude/tests/test_cross_block_function_availability.sh` (100+ lines, 3 tests)

**Documentation References**:
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md` (lines 1-150: subprocess isolation)
- `/home/benjamin/.config/CLAUDE.md` (lines 60-98: Testing Protocols)

**Library Dependencies**:
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` (state file management)
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (depends on state-persistence.sh)
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh` (verification functions)
- `/home/benjamin/.config/.claude/lib/error-handling.sh` (error handling functions)

**Related Research**:
- `/home/benjamin/.config/.claude/specs/661_and_the_standards_in_claude_docs_to_avoid/reports/001_coordinate_command_outputs_analysis.md`
- `/home/benjamin/.config/.claude/specs/661_and_the_standards_in_claude_docs_to_avoid/reports/002_coordinate_revise_outputs_analysis.md`
- `/home/benjamin/.config/.claude/specs/661_and_the_standards_in_claude_docs_to_avoid/reports/003_infrastructure_standards_compatibility.md`
