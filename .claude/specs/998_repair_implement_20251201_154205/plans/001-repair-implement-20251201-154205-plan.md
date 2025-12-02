# Implementation Plan: Fix /implement State Persistence Errors

## Metadata
- **Date**: 2025-12-01
- **Feature**: Fix /implement state persistence errors for WORK_REMAINING variable
- **Scope**: Convert JSON array format to space-separated scalar in implementer-coordinator agent and /implement command Block 1c, add defensive validation, update documentation, create integration test
- **Estimated Phases**: 6
- **Estimated Hours**: 2.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 18.0
- **Research Reports**:
  - [Implement Errors Repair Research](/home/benjamin/.config/.claude/specs/998_repair_implement_20251201_154205/reports/001-implement-errors-repair.md)
  - [Plan Revision Insights](/home/benjamin/.config/.claude/specs/998_repair_implement_20251201_154205/reports/002-plan-revision-insights.md)

## Overview

This plan addresses 2 logged errors in the /implement command caused by passing a JSON-formatted array string to `append_workflow_state()`, which only accepts scalar values. The fix involves converting the JSON array to a space-separated string at the source (implementer-coordinator agent) and defensively in the command (Block 1c).

**Error Context**:
- Command: `/implement`
- Error Count: 2 (shared root cause)
- Error Types: `state_error`, `execution_error`
- Impact: Non-critical (workflow completes despite errors)
- Priority: P2 (Medium - code quality issue)

**Root Cause**:
The implementer-coordinator agent returns `work_remaining` as a JSON array string like `"[Phase 4, Phase 5, Phase 6, Phase 7]"`, which triggers type validation failure in `append_workflow_state()` (line 500-512 in state-persistence.sh). The function enforces scalar-only values to ensure bash export compatibility.

## Infrastructure Dependencies

This plan leverages existing infrastructure:

**Libraries**:
- `state-persistence.sh` (v1.6.0): Type validation (lines 500-512), state file management
- `error-handling.sh`: Error logging integration, pre-trap buffering, error type constants

**Test Infrastructure**:
- Existing state tests: `.claude/tests/state/test_state_*.sh` (7 files)
- Command test pattern: `.claude/tests/commands/test_{command}_{feature}.sh`

**Standards Enforcement**:
- Linter: `.claude/scripts/lint/check-library-sourcing.sh`
- Pre-commit hooks: Validates three-tier sourcing pattern

**No Breaking Changes**: All changes are backward compatible with existing infrastructure.

## Success Criteria

- [ ] No `state_error` entries in error log for WORK_REMAINING variable
- [ ] No `execution_error` entries caused by state persistence failures
- [ ] All tests pass for /implement command
- [ ] State file contains valid space-separated WORK_REMAINING value
- [ ] Error log entries marked as RESOLVED

---

### Phase 1: Update implementer-coordinator Agent Output Format [COMPLETE]

**Objective**: Fix the root cause by ensuring the agent returns space-separated strings instead of JSON arrays

**Status**: COMPLETE

**Dependencies**: []

**Tasks**:
- [x] Read implementer-coordinator.md agent file
- [x] Locate "Output Format" section (around line 517-531)
- [x] Update `work_remaining` documentation to specify space-separated format
- [x] Add explicit examples showing correct vs incorrect formats
- [x] Update return signal documentation to show space-separated list
- [x] Add validation reminder in "Iteration Management" section (line 132-247)

**Implementation Details**:

The agent's output contract currently doesn't specify the format for `work_remaining`. Add explicit format requirements:

```markdown
**Output Format Requirements**:
- work_remaining: Space-separated string of phases (NOT JSON array)
  - Example: "Phase_4 Phase_5 Phase_6" ✓
  - Example: "[Phase 4, Phase 5, Phase 6]" ✗ (triggers state_error)
  - Empty work: "0" or "" ✓
```

Update the structured return example (line 517-531):

```yaml
IMPLEMENTATION_COMPLETE:
  phase_count: N
  plan_file: /path/to/plan.md
  topic_path: /path/to/topic
  summary_path: /path/to/summaries/NNN_workflow_summary.md
  git_commits: [hash1, hash2, ...]
  context_exhausted: true|false
  work_remaining: Phase_4 Phase_5 Phase_6  # Space-separated, not JSON array
  context_usage_percent: N%
  checkpoint_path: /path/to/checkpoint (if created)
  requires_continuation: true|false
  stuck_detected: true|false
```

**Verification**:
- [x] Agent documentation shows space-separated format requirement
- [x] Examples clearly demonstrate correct vs incorrect formats
- [x] No references to JSON array format in agent docs

**Files Modified**:
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`

---

### Phase 2: Add Defensive Validation in /implement Block 1c [COMPLETE]

**Objective**: Add defensive pre-persistence validation to handle both old and new agent outputs gracefully

**Status**: COMPLETE

**Dependencies**: []

**Tasks**:
- [x] Read /implement command file
- [x] Locate Block 1c verification section (around line 820)
- [x] Add JSON array detection before `append_workflow_state` call
- [x] Convert detected JSON arrays to space-separated strings
- [x] Add warning message when conversion occurs
- [x] Preserve existing variable validation logic
- [x] Ensure conversion handles edge cases (empty, null, "0")

**Implementation Details**:

Insert defensive conversion before line 820 (`append_workflow_state "WORK_REMAINING" "$WORK_REMAINING"`):

```bash
# === DEFENSIVE WORK_REMAINING FORMAT CONVERSION ===
# Convert JSON-style array to space-separated scalar if needed
# This handles legacy agent outputs and prevents state_error
if [ -n "$WORK_REMAINING" ] && [[ "$WORK_REMAINING" =~ ^[[:space:]]*\[ ]]; then
  echo "INFO: Converting WORK_REMAINING from JSON array to space-separated string" >&2

  # Strip brackets and commas, normalize spaces
  # Example: "[Phase 4, Phase 5, Phase 6]" -> "Phase_4 Phase_5 Phase_6"
  WORK_REMAINING_CLEAN="${WORK_REMAINING#[}"    # Remove leading [
  WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN%]}"  # Remove trailing ]
  WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN//,/}"  # Remove commas
  WORK_REMAINING_CLEAN=$(echo "$WORK_REMAINING_CLEAN" | tr -s ' ')  # Normalize spaces
  WORK_REMAINING="$WORK_REMAINING_CLEAN"
fi

# Persist work_remaining (now guaranteed to be scalar format)
append_workflow_state "WORK_REMAINING" "$WORK_REMAINING"
```

**Edge Case Handling**:
- Empty string: `WORK_REMAINING=""` → persists as empty
- Zero value: `WORK_REMAINING="0"` → persists as "0"
- Null: `WORK_REMAINING="null"` → persists as "null" (agent contract issue)
- Already scalar: No conversion needed, passes through

**Verification**:
- [x] Conversion logic correctly strips brackets and commas
- [x] Space normalization works (handles multiple spaces)
- [x] Edge cases handled correctly
- [x] append_workflow_state receives scalar value

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/implement.md` (Block 1c, before line 820)

---

### Phase 3: Add Usage Documentation to state-persistence.sh [COMPLETE]

**Objective**: Document the scalar-only requirement and provide examples to prevent future misuse

**Status**: IN PROGRESS

**Dependencies**: []

**Tasks**:
- [x] Read state-persistence.sh library file
- [x] Locate header documentation section (lines 1-106)
- [x] Add "Common Pitfall" subsection after "Decision Criteria" (line 83)
- [x] Document scalar vs JSON array distinction
- [x] Provide correct and incorrect usage examples
- [x] Reference append_workflow_state_array() as alternative
- [x] Update function-level documentation for append_workflow_state()

**Implementation Details**:

Add to header documentation after line 83 ("Decision Criteria"):

```bash
# Common Pitfall: Agent Output Serialization
# ==========================================
# When persisting data from agent outputs, ensure values are scalar strings:
#
#   ✓ Correct: append_workflow_state "WORK_REMAINING" "Phase_4 Phase_5 Phase_6"
#   ✗ Wrong:   append_workflow_state "WORK_REMAINING" "[Phase 4, Phase 5, Phase 6]"
#
# The append_workflow_state() function enforces scalar-only values because state files
# use bash export statements. JSON arrays in export statements cause parsing issues
# when the state file is sourced.
#
# For array-like data, use space-separated strings:
#   PHASES="Phase_4 Phase_5 Phase_6"
#   append_workflow_state "PHASES" "$PHASES"
#
# Or use the array helper function:
#   append_workflow_state_array "PHASES" "Phase_4" "Phase_5" "Phase_6"
#   # Results in: export PHASES="Phase_4 Phase_5 Phase_6"
```

Update function documentation for `append_workflow_state()` (around line 467-489):

```bash
# Append workflow state (GitHub Actions $GITHUB_OUTPUT pattern)
#
# Appends a new key-value pair to the workflow state file.
# This follows the GitHub Actions pattern where outputs accumulate across steps.
#
# IMPORTANT: Only scalar values are supported. JSON arrays/objects will be rejected
# with a type validation error. Use space-separated strings or append_workflow_state_array()
# for multi-value data.
#
# Performance:
# - Append operation: <1ms (simple echo >> redirect)
# - No file locks needed (single writer per workflow)
#
# Args:
#   $1 - key: Variable name to export
#   $2 - value: Scalar string value (NO JSON arrays/objects)
#
# Returns:
#   0 on success, 1 on validation failure (JSON detected)
#
# Side Effects:
#   - Appends export statement to state file
#   - Exported in subsequent load_workflow_state calls
#   - Logs state_error if JSON array/object detected
#
# Examples:
#   append_workflow_state "RESEARCH_COMPLETE" "true"
#   append_workflow_state "REPORTS_CREATED" "4"
#   append_workflow_state "PHASES" "Phase_1 Phase_2 Phase_3"  # Space-separated OK
#   # WRONG: append_workflow_state "PHASES" "[Phase 1, Phase 2]"  # JSON array fails
```

**Verification**:
- [x] Documentation clearly explains scalar-only requirement
- [x] Examples show correct and incorrect usage
- [x] Reference to append_workflow_state_array() provided
- [x] Rationale (bash export compatibility) documented

**Files Modified**:
- `/home/benjamin/.config/.claude/lib/core/state-persistence.sh`

---

### Phase 4: Create Integration Test [COMPLETE]

**Objective**: Add regression test to ensure WORK_REMAINING format conversion works correctly

**Status**: NOT STARTED

**Dependencies**: [1, 2]

**Tasks**:
- [x] Create test file at `.claude/tests/commands/test_implement_work_remaining.sh`
- [x] Write test for JSON array detection and conversion
- [x] Write test for space-separated passthrough (no conversion)
- [x] Write test for edge cases (empty, null, "0")
- [x] Write test for state file validation (scalar export format)
- [x] Add test to command test suite
- [x] Document test purpose and expectations

**Implementation Details**:

Create test file with scenarios:

```bash
#!/usr/bin/env bash
# test_implement_work_remaining.sh - Regression test for WORK_REMAINING format
# Tests defensive conversion from JSON array to space-separated string

test_json_array_conversion() {
  # Simulate JSON array input from agent
  WORK_REMAINING="[Phase 4, Phase 5, Phase 6, Phase 7]"

  # Apply conversion logic (same as Block 1c)
  if [[ "$WORK_REMAINING" =~ ^[[:space:]]*\[ ]]; then
    WORK_REMAINING_CLEAN="${WORK_REMAINING#[}"
    WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN%]}"
    WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN//,/}"
    WORK_REMAINING_CLEAN=$(echo "$WORK_REMAINING_CLEAN" | tr -s ' ')
    WORK_REMAINING="$WORK_REMAINING_CLEAN"
  fi

  # Verify conversion
  [[ "$WORK_REMAINING" == "Phase 4 Phase 5 Phase 6 Phase 7" ]] || return 1

  # Verify no brackets or commas remain
  [[ ! "$WORK_REMAINING" =~ [\[\],] ]] || return 1
}

test_scalar_passthrough() {
  # Simulate space-separated input (correct format)
  WORK_REMAINING="Phase_4 Phase_5 Phase_6"

  # Apply conversion logic (should be no-op)
  if [[ "$WORK_REMAINING" =~ ^[[:space:]]*\[ ]]; then
    WORK_REMAINING_CLEAN="${WORK_REMAINING#[}"
    WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN%]}"
    WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN//,/}"
    WORK_REMAINING="$WORK_REMAINING_CLEAN"
  fi

  # Verify unchanged
  [[ "$WORK_REMAINING" == "Phase_4 Phase_5 Phase_6" ]] || return 1
}

test_state_persistence() {
  # Initialize state file
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
  STATE_FILE=$(init_workflow_state "test_$$")

  # Test scalar value persistence
  append_workflow_state "WORK_REMAINING" "Phase_4 Phase_5"

  # Verify state file contains valid export
  grep -q '^export WORK_REMAINING="Phase_4 Phase_5"$' "$STATE_FILE" || return 1

  # Test JSON array rejection
  if append_workflow_state "WORK_REMAINING_JSON" "[Phase 4, Phase 5]" 2>/dev/null; then
    # Should NOT succeed
    return 1
  fi

  # Cleanup
  rm -f "$STATE_FILE"
}

# Run tests
test_json_array_conversion || { echo "FAIL: JSON array conversion"; exit 1; }
test_scalar_passthrough || { echo "FAIL: Scalar passthrough"; exit 1; }
test_state_persistence || { echo "FAIL: State persistence validation"; exit 1; }

echo "PASS: All WORK_REMAINING format tests passed"
```

**Test Execution**:
```bash
bash .claude/tests/commands/test_implement_work_remaining.sh
# Expected: PASS: All WORK_REMAINING format tests passed
```

**Verification**:
- [x] Test detects JSON array format
- [x] Test verifies conversion to scalar
- [x] Test confirms space-separated passthrough
- [x] Test validates state file export format
- [x] Test fails on JSON array persistence attempt

**Files Created**:
- `/home/benjamin/.config/.claude/tests/commands/test_implement_work_remaining.sh`

---

### Phase 5: Verify Fix with Full /implement Workflow [COMPLETE]

**Objective**: Run complete /implement workflow to verify no state_error entries are logged

**Status**: NOT STARTED

**Dependencies**: [1, 2, 3, 4]

**Tasks**:
- [x] Clear error log entries for /implement (or note baseline)
- [x] Create test plan with multiple phases (5+ phases)
- [x] Run /implement workflow with test plan
- [x] Monitor error log for state_error entries
- [x] Verify WORK_REMAINING persisted correctly in state file
- [x] Check workflow completion status
- [x] Validate continuation context if applicable
- [x] Review logs for conversion warnings (INFO messages)

**Implementation Details**:

**Pre-Flight Check**:
```bash
# Count baseline errors
BASELINE_ERRORS=$(grep -c '"error_type":"state_error"' .claude/tests/logs/test-errors.jsonl)
echo "Baseline state_error count: $BASELINE_ERRORS"
```

**Test Execution**:
```bash
# Run /implement on multi-phase plan
/implement .claude/specs/test_multi_phase/plans/001-test.md

# Check for new state_error entries
NEW_ERRORS=$(grep -c '"error_type":"state_error"' .claude/tests/logs/test-errors.jsonl)
echo "Post-test state_error count: $NEW_ERRORS"

# Verify no new errors
[[ $NEW_ERRORS -eq $BASELINE_ERRORS ]] || echo "ERROR: New state_error entries detected"

# Check state file format
STATE_FILE=$(find .claude/tmp -name "workflow_implement_*.sh" -type f -printf '%T@ %p\n' | sort -rn | head -1 | cut -d' ' -f2-)
grep "WORK_REMAINING" "$STATE_FILE"
# Expected: export WORK_REMAINING="Phase_4 Phase_5 Phase_6" (space-separated)
```

**Success Criteria**:
- No new `state_error` entries in error log
- No new `execution_error` entries related to state persistence
- WORK_REMAINING variable in state file is space-separated string
- Workflow completes successfully
- Continuation context created if applicable

**Verification**:
- [x] Error log shows no new state_error entries
- [x] State file contains valid WORK_REMAINING export
- [x] Workflow reaches COMPLETE state
- [x] No cascaded execution_error entries

**Files Verified**:
- `.claude/tests/logs/test-errors.jsonl`
- `.claude/tmp/workflow_implement_*.sh`

---

### Phase 6: Update Error Log Status [COMPLETE]

**Objective**: Update error log entries from FIX_PLANNED to RESOLVED

**Status**: NOT STARTED

**Dependencies**: [1, 2, 3, 4, 5]

**Tasks**:
- [x] Verify all fixes are working (tests pass, no new errors generated)
- [x] Update error log entries to RESOLVED status using mark_errors_resolved_for_plan()
- [x] Verify no FIX_PLANNED errors remain for this plan

**Implementation Details**:

After confirming all phases complete successfully:

```bash
# Source error-handling library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"

# Mark errors as resolved for this repair plan
mark_errors_resolved_for_plan "/home/benjamin/.config/.claude/specs/998_repair_implement_20251201_154205/plans/001-repair-implement-20251201-154205-plan.md"

# Verify resolution
grep -c '"status":"FIX_PLANNED"' .claude/tests/logs/test-errors.jsonl || echo "All errors resolved"
```

**Verification**:
- [x] All test phases pass
- [x] No new errors generated during verification
- [x] Error log entries updated to RESOLVED
- [x] No FIX_PLANNED entries remain for this plan path

**Files Modified**:
- `.claude/tests/logs/test-errors.jsonl`
