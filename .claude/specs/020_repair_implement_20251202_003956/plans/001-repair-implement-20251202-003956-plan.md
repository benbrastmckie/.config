# Implementation Plan: /implement Command Error Fixes

## Metadata
- **Date**: 2025-12-02T01:04:41Z (revised)
- **Feature**: /implement command error fixes
- **Status**: [IN PROGRESS]
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Plan ID**: 001-repair-implement-20251202-003956-plan
- **Created**: 2025-12-02T00:39:56Z
- **Type**: repair
- **Complexity**: 2 (Medium)
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/020_repair_implement_20251202_003956/reports/001-implement-errors-repair.md
  - /home/benjamin/.config/.claude/specs/020_repair_implement_20251202_003956/reports/002-standards-conformance-analysis.md
- **Estimated Duration**: 13-18 hours (6 phases)
- **Phase Count**: 6

## Executive Summary

This repair plan addresses 3 logged /implement command errors and 4 broader systemic issues affecting 125 errors project-wide (13.3% of total logged errors). The plan implements fixes for: (1) state persistence JSON validation failures blocking 23 errors across 6 commands, (2) implementer-coordinator agent summary creation failures (1 /implement error, 4 project-wide), (3) ERR trap noise from cascading errors inflating log by 20-30%, and (4) state machine initialization gaps causing 9 errors. Fixes apply clean-break development principles with no deprecation periods for internal tooling changes.

## Problem Statement

### Current Issues
1. **State Persistence JSON Validation Failure**: Commands storing structured metadata (WORK_REMAINING, ERROR_FILTERS) fail with "Type validation failed: JSON detected" at state-persistence.sh line 412. Affects 23 errors across /implement, /repair, /plan, /revise, /build. Root cause: Type system enforces plain text but commands need JSON for complex data structures.

2. **Agent Summary Creation Failure**: implementer-coordinator agent completes execution without creating expected summary file, causing hard barrier verification failure. Affects 1 /implement error (workflow_id implement_1764653796), 4 project-wide. Root cause: Insufficient diagnostics to determine if file created elsewhere vs not at all.

3. **ERR Trap Noise**: Bash ERR trap logs execution context for expected validation failures, creating duplicate error log entries for single underlying issues. Contributes to 93 execution_error entries (9.9% of total). Root cause: No distinction between unexpected errors vs expected validation failures.

4. **State Machine Initialization Gaps**: Commands call sm_transition before load_workflow_state, causing "STATE_FILE not set" errors. Affects 9 errors. Root cause: Missing initialization guards in state machine entry points.

### Success Criteria
- [ ] State persistence accepts JSON values for allowlisted keys (WORK_REMAINING, *_JSON, ERROR_FILTERS) - validated by test_implement_error_handling.sh::test_json_state_persistence
- [ ] Hard barrier diagnostics report file location mismatches vs complete absence - validated by test_implement_error_handling.sh::test_hard_barrier_diagnostics
- [ ] ERR trap suppressed for validation functions using SUPPRESS_ERR_TRAP flag - validated by test_implement_error_handling.sh::test_err_trap_suppression
- [ ] sm_transition auto-initializes state machine if STATE_FILE unset - validated by test_implement_error_handling.sh::test_state_machine_auto_init
- [ ] All existing tests pass with no regressions - validated by bash .claude/tests/run_all_tests.sh
- [ ] New integration tests cover all 4 error patterns - validated by test_implement_error_handling.sh (4 test cases)
- [ ] Error log entries for this repair marked RESOLVED - verified by /errors --query --filter "repair_plan=.../001-repair-implement-20251202-003956-plan.md AND status=FIX_PLANNED"

## Dependencies

### External Dependencies
- Error handling library (/home/benjamin/.config/.claude/lib/core/error-handling.sh)
- State persistence library (/home/benjamin/.config/.claude/lib/core/state-persistence.sh)
- Workflow state machine library (/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh)
- Implement command (/home/benjamin/.config/.claude/commands/implement.md)

### Related Work
- Repair plan 998_repair_implement_20251201_154205 (FIX_PLANNED for JSON validation - coordinate to avoid conflicts)
- Hard barrier subagent delegation pattern documentation

### Standards Compliance
- Three-tier sourcing pattern for all bash blocks (see [code-standards.md#mandatory-bash-block-sourcing-pattern](.claude/docs/reference/standards/code-standards.md#mandatory-bash-block-sourcing-pattern))
- Error logging integration for all command changes (see [error-handling.md#logging-integration-in-commands](.claude/docs/concepts/patterns/error-handling.md#logging-integration-in-commands))
- Clean-break development (no deprecation periods) (see [clean-break-development.md](.claude/docs/reference/standards/clean-break-development.md))
- Output suppression with 2>/dev/null while preserving error handling (see [output-formatting.md#output-suppression-patterns](.claude/docs/reference/standards/output-formatting.md#output-suppression-patterns))
- Test isolation standards (see [testing-protocols.md#test-isolation-standards](.claude/docs/reference/standards/testing-protocols.md#test-isolation-standards))

### Error Context Persistence (All Phases)

Multi-block commands must maintain error logging context across bash blocks per [error-handling.md#state-persistence-integration](.claude/docs/concepts/patterns/error-handling.md#state-persistence-integration):

**Block 1: Initialize and Persist**
```bash
# Set command metadata for error logging
COMMAND_NAME="/implement"
WORKFLOW_ID="implement_$(date +%s)"
USER_ARGS="$*"
export COMMAND_NAME USER_ARGS

# Initialize workflow state (automatically persists variables)
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
```

**Blocks 2+: Restore and Use**
```bash
# Load workflow state (automatically restores COMMAND_NAME, USER_ARGS, WORKFLOW_ID)
load_workflow_state "$WORKFLOW_ID" false

# Validate critical variables restored
validate_state_restoration "COMMAND_NAME" "USER_ARGS" "WORKFLOW_ID" || {
  echo "ERROR: State restoration failed" >&2
  exit 1
}

# Variables now available for error logging
log_command_error "error_type" "message" "context_details"
```

This pattern ensures error logs have complete workflow context regardless of which bash block encounters errors.

### Checkpoint Reporting Format

All phase verification blocks should use standard 3-line checkpoint format per [output-formatting.md#checkpoint-reporting-format](.claude/docs/reference/standards/output-formatting.md#checkpoint-reporting-format):

```bash
echo "[CHECKPOINT] Phase name complete"
echo "Context: KEY1=value1, KEY2=value2, KEY3=value3"
echo "Ready for: Next action description"
```

**Example** (Phase 1 verification):
```bash
echo "[CHECKPOINT] JSON allowlist implementation complete"
echo "Context: PHASE=1, FILES_MODIFIED=1, TESTS_PASSING=true"
echo "Ready for: Phase 2 hard barrier diagnostics"
```

**Guideline**: Include only variables relevant to workflow state or debugging (workflow ID, phase number, file counts, feature flags).

## Implementation Phases

### Phase 1: Implement JSON State Value Allowlist [COMPLETE]
**Objective**: Modify state-persistence.sh to allow JSON values for specific metadata keys while maintaining validation for others

**Rationale**: Resolves 23 errors (2.4% of total) affecting 6 commands including /implement. Highest impact-to-effort ratio (High priority, Low effort).

**Files Modified**:
- /home/benjamin/.config/.claude/lib/core/state-persistence.sh

**Changes**:
1. Locate append_workflow_state function (line 412 area) with JSON validation logic
2. Add JSON key allowlist before validation:
   ```bash
   # Keys permitted to store JSON values
   local -a json_allowed_keys=(
     "WORK_REMAINING"
     "ERROR_FILTERS"
     "COMPLETED_STATES_JSON"
     "REPORT_PATHS_JSON"
     "RESEARCH_TOPICS_JSON"
     "PHASE_DEPENDENCIES_JSON"
   )
   ```
3. Modify type validation logic to check allowlist:
   ```bash
   # Check if key ends with _JSON or is in allowlist
   local allow_json=false
   if [[ "$key" =~ _JSON$ ]]; then
     allow_json=true
   else
     for allowed_key in "${json_allowed_keys[@]}"; do
       if [[ "$key" == "$allowed_key" ]]; then
         allow_json=true
         break
       fi
     done
   fi

   # Skip JSON detection check if key is allowlisted
   if [[ "$allow_json" == false ]] && [[ "$value" =~ ^[\[\{] ]]; then
     log_command_error "state_error" "Type validation failed: JSON detected" "key=$key, value=$value"
     return 1
   fi
   ```
4. Update append_workflow_state inline documentation to reference JSON-enabled keys

**Testing**:
- Unit test: Store JSON array in WORK_REMAINING, verify no state_error logged
- Unit test: Store JSON object in custom_JSON key, verify acceptance
- Unit test: Store JSON in non-allowlisted key, verify rejection with error
- Integration test: Run /implement with WORK_REMAINING containing phase array
- Regression test: Verify existing plain text state values still work

**Validation**:
- Check error log: No new state_error entries with "JSON detected" for allowlisted keys
- Verify state file integrity: JSON values stored as-is, parseable by jq
- Confirm 23 historical errors would now succeed (review error contexts)

**Dependencies**: None (self-contained library change)

**Estimated Duration**: 2-3 hours

---

### Phase 2: Enhance Hard Barrier Diagnostics [COMPLETE]
**Objective**: Upgrade hard barrier verification to provide better diagnostics when expected files are not found

**Rationale**: Improves debugging for 30 agent errors project-wide. Reveals whether files created at wrong location vs not at all, accelerating root cause identification for implementer-coordinator failures.

**Files Modified**:
- /home/benjamin/.config/.claude/commands/implement.md (hard barrier verification block)
- /home/benjamin/.config/.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md (pattern documentation)

**Changes**:
1. Enhance hard barrier verification in /implement command (bash_block_1c area):
   ```bash
   # Enhanced hard barrier verification with diagnostics
   if [[ ! -f "$expected_summary_path" ]]; then
     echo "❌ Hard barrier verification failed: Summary file not found"
     echo "Expected: $expected_summary_path"

     # Search for file in parent and topic directories
     local summary_name=$(basename "$expected_summary_path")
     local topic_dir=$(dirname "$(dirname "$expected_summary_path")")
     local found_files=$(find "$topic_dir" -name "$summary_name" 2>/dev/null || true)

     if [[ -n "$found_files" ]]; then
       echo "Found at alternate location(s):"
       echo "$found_files"
       log_command_error "agent_error" "implementer-coordinator created file at wrong location" \
         "expected=$expected_summary_path, found=$found_files"
     else
       echo "Not found anywhere in topic directory: $topic_dir"
       log_command_error "agent_error" "implementer-coordinator failed to create summary file" \
         "expected=$expected_summary_path, topic_dir=$topic_dir"
     fi

     # Check if agent actually executed (tool use count > 0)
     if [[ -f "$STATE_FILE" ]]; then
       local tool_uses=$(grep "AGENT_TOOL_USES" "$STATE_FILE" 2>/dev/null | cut -d= -f2 || echo "0")
       echo "Agent tool uses: $tool_uses"
       if [[ "$tool_uses" == "0" ]]; then
         echo "⚠️  Warning: Agent may have failed silently (no tool uses recorded)"
       fi
     fi

     return 1
   fi
   ```

2. Update hard-barrier-subagent-delegation.md pattern documentation:
   - Add "Enhanced Diagnostics" section with search strategy examples
   - Document diagnostic output format for location mismatches
   - Add troubleshooting guide: "File not found" vs "File at wrong location" vs "Agent silent failure"

**Testing**:
- Mock test: Agent creates summary in parent dir instead of summaries/ subdir, verify diagnostic reports location
- Mock test: Agent creates no file, verify diagnostic reports "not found anywhere"
- Mock test: Agent executes with 0 tool uses, verify warning about silent failure
- Integration test: Run /implement with plan requiring summary, verify diagnostics on failure

**Validation**:
- Enhanced diagnostics output includes expected path, alternate locations (if found), agent tool use count
- Error log entries include diagnostic context (found= vs topic_dir=)
- Pattern documentation updated with examples

**Dependencies**: Phase 1 (state persistence for AGENT_TOOL_USES tracking)

**Estimated Duration**: 3-4 hours

---

### Phase 3: Suppress ERR Trap for Expected Validation Failures [COMPLETE]
**Objective**: Add granular control to ERR trap logging to reduce noise from expected validation failures

**Rationale**: 93 execution_error entries (9.9% of total) create noise in error log. Many cascade from legitimate validation failures. Improves signal-to-noise ratio by 20-30%.

**Files Modified**:
- /home/benjamin/.config/.claude/lib/core/error-handling.sh (ERR trap handler)
- /home/benjamin/.config/.claude/lib/core/state-persistence.sh (validation functions)
- /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md (pattern documentation)

**Changes**:
1. Add suppression flag to error-handling.sh ERR trap:
   ```bash
   # ERR trap handler (line 466 area)
   bash_trap() {
     local exit_code=$?
     local line_number=$1

     # Check suppression flag
     if [[ "${SUPPRESS_ERR_TRAP:-0}" == "1" ]]; then
       SUPPRESS_ERR_TRAP=0  # Reset flag
       return 0
     fi

     # Existing trap logic for unexpected errors
     log_command_error "execution_error" \
       "Bash error at line $line_number: exit code $exit_code" \
       "line=$line_number, exit_code=$exit_code, command=$BASH_COMMAND"
   }
   ```

2. Update validation functions in state-persistence.sh to set suppression flag:
   ```bash
   append_workflow_state() {
     # ... existing validation logic ...

     if [[ "$allow_json" == false ]] && [[ "$value" =~ ^[\[\{] ]]; then
       SUPPRESS_ERR_TRAP=1  # Suppress cascading ERR trap
       log_command_error "state_error" "Type validation failed: JSON detected" "key=$key, value=$value"
       return 1
     fi

     # ... other validations with SUPPRESS_ERR_TRAP=1 before return 1 ...
   }
   ```

3. Update error-handling.md pattern documentation:
   - Add "ERR Trap Suppression" section with flag usage examples
   - Document when to suppress (validation failures) vs when not to (unexpected errors)
   - Add best practices: Always reset flag after use, only suppress in library functions

**Testing**:
- Unit test: Validation function returns 1, verify SUPPRESS_ERR_TRAP prevents execution_error log entry
- Unit test: Unexpected error (not validation), verify execution_error logged normally
- Unit test: Suppression flag resets after use, subsequent errors logged
- Integration test: Run command with validation failure, verify only state_error logged (not execution_error)

**Validation**:
- Error log contains single state_error entry for validation failures (not state_error + execution_error)
- Unexpected errors still generate execution_error entries
- Historical error log analysis: ~20-30% reduction in execution_error count if applied retroactively

**Dependencies**: Phase 1 (state persistence validation changes)

**Estimated Duration**: 2-3 hours

---

### Phase 4: Add State Machine Initialization Guard [NOT STARTED]
**Objective**: Make sm_transition self-healing by auto-initializing state machine if STATE_FILE is unset

**Rationale**: Prevents 9 "STATE_FILE not set" errors by making state machine robust to initialization gaps in command authoring.

**Files Modified**:
- /home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh (sm_transition function)
- /home/benjamin/.config/.claude/scripts/validate-all-standards.sh (add linter check)
- /home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md (update standards)

**Changes**:
1. Add initialization guard to sm_transition function:
   ```bash
   sm_transition() {
     local new_state="$1"

     # Auto-initialize if STATE_FILE unset
     if [[ -z "${STATE_FILE:-}" ]]; then
       echo "⚠️  Warning: Auto-initializing state machine (load_workflow_state not called explicitly)" >&2
       log_command_error "state_error" "sm_transition called before initialization" \
         "context=auto-initializing, new_state=$new_state"

       # Attempt auto-initialization
       if ! load_workflow_state 2>/dev/null; then
         log_command_error "state_error" "Auto-initialization failed" "new_state=$new_state"
         return 1
       fi
     fi

     # ... existing transition logic ...
   }
   ```

2. Add linter check to validate-all-standards.sh:
   ```bash
   # Check for commands calling sm_transition before load_workflow_state
   check_state_machine_initialization() {
     local files=$(find .claude/commands -name "*.md" -type f)
     local violations=0

     for file in $files; do
       # Extract bash blocks and check for sm_transition before load_workflow_state
       # Warn if pattern detected (not error, since auto-init now handles it)
       if grep -q "sm_transition" "$file" && ! grep -B50 "sm_transition" "$file" | grep -q "load_workflow_state"; then
         echo "WARNING: $file calls sm_transition without explicit load_workflow_state (relies on auto-init)"
         ((violations++))
       fi
     done

     return $violations
   }
   ```

3. Update command-authoring.md standards:
   - Document explicit load_workflow_state in Block 0 as best practice
   - Note auto-initialization fallback exists but shouldn't be relied upon
   - Add example showing proper initialization pattern

**Testing**:
- Unit test: Call sm_transition with STATE_FILE unset, verify auto-initialization succeeds and warning logged
- Unit test: Auto-initialization fails (no state file), verify error logged and return 1
- Integration test: Create command without load_workflow_state, verify sm_transition works with warning
- Linter test: Run new check on commands/, verify warnings for missing initialization

**Validation**:
- Commands without explicit initialization still work (with warning)
- Error log contains state_error for auto-init attempts (for monitoring)
- Linter identifies commands relying on auto-init (for cleanup)
- 9 historical "STATE_FILE not set" errors would now auto-recover

**Dependencies**: None (independent state machine enhancement)

**Estimated Duration**: 2-3 hours

---

### Phase 5: Create Integration Test Suite [NOT STARTED]
**Objective**: Add integration tests covering all 4 error patterns to prevent regression

**Rationale**: Validates fixes for Phases 1-4, prevents recurrence of resolved issues, documents expected behavior for edge cases.

**Files Created**:
- /home/benjamin/.config/.claude/tests/commands/test_implement_error_handling.sh

**Changes**:
1. Create test suite with 4 test cases:
   ```bash
   #!/usr/bin/env bash
   # Integration tests for /implement error handling fixes

   # Test 1: JSON values in WORK_REMAINING don't cause state errors
   test_json_state_persistence() {
     # Setup: Create state file with JSON array in WORK_REMAINING
     # Execute: append_workflow_state WORK_REMAINING "[Phase 4, Phase 5]"
     # Assert: No state_error logged, state file contains JSON value
   }

   # Test 2: Hard barrier diagnostics report file location mismatches
   test_hard_barrier_diagnostics() {
     # Setup: Mock implementer-coordinator creating file at wrong location
     # Execute: Hard barrier verification
     # Assert: Error log contains "created file at wrong location" with found= path
   }

   # Test 3: ERR trap suppressed for validation failures
   test_err_trap_suppression() {
     # Setup: Trigger validation failure (invalid state transition)
     # Execute: Capture error log entries
     # Assert: Only state_error logged, no execution_error cascade
   }

   # Test 4: State machine auto-initialization on missing STATE_FILE
   test_state_machine_auto_init() {
     # Setup: Unset STATE_FILE variable
     # Execute: sm_transition to new state
     # Assert: Warning logged, state_error logged, transition succeeds
   }
   ```

2. Add test suite to CI pipeline:
   - Update validate-all-standards.sh to run test_implement_error_handling.sh
   - Add test results to validation summary

**Testing**:
- Run test suite in isolation, verify all 4 tests pass
- Run test suite in CI pipeline, verify integration with validate-all-standards.sh
- Verify test failures produce actionable error messages

**Validation**:
- All 4 test cases pass with Phase 1-4 fixes in place
- Test failures clearly indicate which fix regressed
- CI pipeline includes test suite in validation

**Dependencies**: Phases 1-4 (tests validate all fixes)

**Estimated Duration**: 3-4 hours

---

### Phase 6: Update Error Log Status [NOT STARTED]
**Objective**: Mark all errors addressed by this repair plan as RESOLVED in error log

**Rationale**: Required for repair plans - updates error tracking to reflect completed fixes, enables verification that no FIX_PLANNED errors remain.

**Files Modified**:
- /home/benjamin/.config/.claude/data/logs/errors.jsonl (via mark_errors_resolved_for_plan)

**Changes**:
1. Verify all fixes working:
   ```bash
   # Run complete test suite
   bash .claude/scripts/validate-all-standards.sh --all
   bash .claude/tests/commands/test_implement_error_handling.sh

   # Verify no new errors logged during testing
   /errors --since 1h --command /implement --status ERROR
   ```

2. Update error log entries to RESOLVED status:
   ```bash
   # Source error handling library
   source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || {
     echo "Error: Cannot load error-handling library"
     exit 1
   }

   # Mark errors resolved for this plan
   local plan_path="/home/benjamin/.config/.claude/specs/020_repair_implement_20251202_003956/plans/001-repair-implement-20251202-003956-plan.md"
   mark_errors_resolved_for_plan "$plan_path"

   # Verify no FIX_PLANNED errors remain for this plan
   local remaining_errors=$(/errors --query --filter "repair_plan=$plan_path AND status=FIX_PLANNED" | wc -l)
   if [[ "$remaining_errors" -gt 0 ]]; then
     echo "⚠️  Warning: $remaining_errors errors still marked FIX_PLANNED for this plan"
     /errors --query --filter "repair_plan=$plan_path AND status=FIX_PLANNED"
   else
     echo "✅ All errors for this plan marked RESOLVED"
   fi
   ```

**jq Filter Safety**: When querying errors.jsonl, use explicit parentheses for pipe operations in boolean context per [testing-protocols.md#jq-filter-safety](.claude/docs/reference/standards/testing-protocols.md#jq-filter-safety):

```bash
# CORRECT: Parentheses around pipe operation
local remaining_errors=$(jq -r 'select(.repair_plan == "'"$plan_path"'" and (.status | contains("FIX_PLANNED")))' \
  .claude/data/logs/errors.jsonl | wc -l)
```

Common pitfall:
```bash
# WRONG: Boolean result piped to contains()
jq 'select(.field == "value" and .message | contains("pattern"))'
# TypeError: boolean and string cannot have containment checked
```

**Testing**:
- Query error log before update: Count errors with status=FIX_PLANNED for this plan
- Run mark_errors_resolved_for_plan
- Query error log after update: Verify count=0 for FIX_PLANNED, count increased for RESOLVED
- Verify error log JSON structure intact (valid JSONL)

**Validation**:
- Error log entries for workflow IDs implement_1764630912 and implement_1764653796 have status=RESOLVED
- Error log entries include resolution_metadata with plan_path and timestamp
- No FIX_PLANNED errors remain for this repair plan
- Error log file integrity maintained (parseable by /errors command)

**Dependencies**: Phases 1-5 (all fixes must be complete and tested)

**Estimated Duration**: 1 hour

## Testing Strategy

### Test Isolation Requirements

All tests MUST use isolation patterns to prevent production directory pollution per [testing-protocols.md#test-isolation-standards](.claude/docs/reference/standards/testing-protocols.md#test-isolation-standards).

**Required Pattern**:
```bash
#!/usr/bin/env bash
# test_implement_error_handling.sh

# Setup isolation
TEST_ROOT="/tmp/test_isolation_$$"
mkdir -p "$TEST_ROOT/.claude/specs"
mkdir -p "$TEST_ROOT/.claude/data/logs"
export CLAUDE_SPECS_ROOT="$TEST_ROOT/.claude/specs"
export CLAUDE_PROJECT_DIR="$TEST_ROOT"
export CLAUDE_TEST_MODE=1  # Route errors to test-errors.jsonl

# Cleanup trap
trap 'rm -rf "$TEST_ROOT"' EXIT

# Run tests with isolation active
test_json_state_persistence() {
  # Test implementation...
}

# Execute tests
test_json_state_persistence
test_hard_barrier_diagnostics
test_err_trap_suppression
test_state_machine_auto_init
```

**Validation**: Test runner detects production directory pollution pre/post test execution.

### Test Discovery and Execution

Tests follow standard .claude/ test patterns per [testing-protocols.md#test-discovery](.claude/docs/reference/standards/testing-protocols.md#test-discovery):

**Test File Structure**:
- **Location**: .claude/tests/commands/test_implement_error_handling.sh
- **Pattern**: test_*.sh naming convention
- **Framework**: Bash test framework (existing .claude/tests/ patterns)

**Test Execution**:
```bash
# Run single test file
bash .claude/tests/commands/test_implement_error_handling.sh

# Run all tests via test runner
bash .claude/tests/run_all_tests.sh

# Run specific test function
bash .claude/tests/commands/test_implement_error_handling.sh test_json_state_persistence
```

**Auto-Discovery**: All test_*.sh files in .claude/tests/ are auto-discovered by CI validation pipeline.

**Coverage Threshold**: 80% for new code paths (allowlist logic, diagnostics, suppression, auto-init).

### Unit Tests
- **Phase 1**: State persistence JSON allowlist (3 tests)
- **Phase 3**: ERR trap suppression flag (3 tests)
- **Phase 4**: State machine auto-initialization (2 tests)

### Integration Tests
- **Phase 2**: Hard barrier diagnostics with mock agent (3 tests)
- **Phase 4**: State machine linter check (1 test)
- **Phase 5**: Complete error handling test suite (4 tests)

### Regression Tests
- **Phase 1**: Existing state persistence tests with plain text values
- **Phases 1-4**: All existing command tests (verify no breakage)

### Test Coverage Requirements
- All 4 error patterns covered by automated tests
- All new code paths (allowlist check, diagnostics, suppression, auto-init) exercised
- Integration with existing error handling library validated

## Rollback Plan

### Rollback Execution Pattern

All rollbacks use git commit hash discovery to ensure correct restoration point per [backup-policy.md](.claude/docs/reference/templates/backup-policy.md):

**General Rollback Template**:
```bash
# Find commit hash before changes
BACKUP_COMMIT=$(git log --oneline <file_path> | \
  grep -E "before.*Phase N|backup.*<file_name>" | head -1 | awk '{print $1}')

if [ -z "$BACKUP_COMMIT" ]; then
  echo "ERROR: Cannot find backup commit for <file_name>"
  echo "Manual recovery required - review git log"
  exit 1
fi

# Restore file from backup commit
git checkout $BACKUP_COMMIT -- <file_path>

# Verify restoration
git diff HEAD <file_path>

# Commit rollback
git add <file_path>
git commit -m "rollback: Revert Phase N changes (<file_name>)"
```

**Verification**: After rollback, run validation suite to confirm system stability:
```bash
bash .claude/scripts/validate-all-standards.sh --all
bash .claude/tests/run_all_tests.sh
```

### Phase 1 Rollback [COMPLETE]
- Revert state-persistence.sh to previous version (no allowlist)
- Risk: Low (isolated library change, well-tested)
- Recovery:
  ```bash
  BACKUP_COMMIT=$(git log --oneline .claude/lib/core/state-persistence.sh | grep -E "before.*JSON|backup.*state-persistence" | head -1 | awk '{print $1}')
  git checkout $BACKUP_COMMIT -- .claude/lib/core/state-persistence.sh
  git diff HEAD .claude/lib/core/state-persistence.sh
  ```

### Phase 2 Rollback [COMPLETE]
- Revert implement.md hard barrier block to previous version
- Risk: Low (enhanced diagnostics only, doesn't change behavior)
- Recovery:
  ```bash
  BACKUP_COMMIT=$(git log --oneline .claude/commands/implement.md | grep -E "before.*diagnostics|backup.*implement" | head -1 | awk '{print $1}')
  git checkout $BACKUP_COMMIT -- .claude/commands/implement.md
  git diff HEAD .claude/commands/implement.md
  ```

### Phase 3 Rollback [COMPLETE]
- Revert error-handling.sh ERR trap changes
- Revert state-persistence.sh validation flag additions
- Risk: Low (flag defaults to 0, backward compatible)
- Recovery:
  ```bash
  BACKUP_COMMIT=$(git log --oneline .claude/lib/core/error-handling.sh | grep -E "before.*ERR trap|backup.*error-handling" | head -1 | awk '{print $1}')
  git checkout $BACKUP_COMMIT -- .claude/lib/core/error-handling.sh .claude/lib/core/state-persistence.sh
  git diff HEAD .claude/lib/core/error-handling.sh .claude/lib/core/state-persistence.sh
  ```

### Phase 4 Rollback
- Revert workflow-state-machine.sh auto-init guard
- Remove linter check from validate-all-standards.sh
- Risk: Medium (changes core state machine behavior)
- Recovery:
  ```bash
  BACKUP_COMMIT=$(git log --oneline .claude/lib/workflow/workflow-state-machine.sh | grep -E "before.*auto-init|backup.*workflow-state-machine" | head -1 | awk '{print $1}')
  git checkout $BACKUP_COMMIT -- .claude/lib/workflow/workflow-state-machine.sh .claude/scripts/validate-all-standards.sh
  git diff HEAD .claude/lib/workflow/workflow-state-machine.sh .claude/scripts/validate-all-standards.sh
  ```

### Phase 5 Rollback
- Remove test suite file
- Revert validate-all-standards.sh CI integration
- Risk: None (only affects testing, not production code)
- Recovery:
  ```bash
  git rm .claude/tests/commands/test_implement_error_handling.sh
  BACKUP_COMMIT=$(git log --oneline .claude/scripts/validate-all-standards.sh | grep -E "before.*test integration" | head -1 | awk '{print $1}')
  git checkout $BACKUP_COMMIT -- .claude/scripts/validate-all-standards.sh
  ```

### Phase 6 Rollback
- Restore error log backup
- Risk: Low (non-destructive update via append, backup available)
- Recovery:
  ```bash
  # List available backups
  ls -lh .claude/data/logs/errors.jsonl.backup_*
  # Restore most recent backup before Phase 6
  LATEST_BACKUP=$(ls -t .claude/data/logs/errors.jsonl.backup_* | head -1)
  cp "$LATEST_BACKUP" .claude/data/logs/errors.jsonl
  # Verify restoration
  /errors --since 1h --summary
  ```

## Documentation Updates

### Code Documentation
- **state-persistence.sh**: Inline comments for JSON allowlist logic
- **error-handling.sh**: Inline comments for ERR trap suppression
- **workflow-state-machine.sh**: Inline comments for auto-initialization guard

### Pattern Documentation
- **hard-barrier-subagent-delegation.md**: Enhanced diagnostics section with examples
- **error-handling.md**: ERR trap suppression best practices

### Standards Documentation
- **command-authoring.md**: State machine initialization best practices (explicit load_workflow_state in Block 0)

### README.md Updates

Update directory README.md files to reflect changes per [documentation-standards.md#readme-requirements](.claude/docs/reference/standards/documentation-standards.md#readme-requirements):

1. **.claude/lib/core/README.md**:
   - Add JSON allowlist feature documentation to state-persistence.sh module entry
   - Include example usage of JSON-enabled keys (WORK_REMAINING, ERROR_FILTERS, *_JSON)
   - Document allowlist extension pattern for future keys

2. **.claude/lib/workflow/README.md**:
   - Document auto-initialization guard in workflow-state-machine.sh module entry
   - Note auto-init warning behavior and recommended explicit initialization pattern
   - Add troubleshooting guidance for STATE_FILE not set errors

3. **.claude/tests/commands/README.md**:
   - Add test_implement_error_handling.sh to test inventory
   - List 4 test cases with brief descriptions:
     - test_json_state_persistence: Validates JSON allowlist
     - test_hard_barrier_diagnostics: Validates enhanced error reporting
     - test_err_trap_suppression: Validates trap noise reduction
     - test_state_machine_auto_init: Validates self-healing initialization
   - Document test isolation requirements for this suite

4. **.claude/docs/concepts/patterns/error-handling.md**:
   - Already listed in Pattern Documentation section
   - Add ERR trap suppression example with SUPPRESS_ERR_TRAP flag
   - Document when to suppress (validation failures) vs when not to (unexpected errors)

5. **.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md**:
   - Already listed in Pattern Documentation section
   - Add enhanced diagnostics example showing location mismatch vs file absence
   - Document diagnostic output format for troubleshooting

### Reference Documentation
- No reference doc updates required (internal library changes only)

## Risk Assessment

### High Risk
- None identified (all changes backward compatible with rollback plans)

### Medium Risk
- **Phase 4 Auto-Initialization**: Changes core state machine behavior, could mask initialization bugs in commands
  - Mitigation: Linter warns about missing initialization, encourages explicit calls
  - Mitigation: Auto-init logs warning + error for monitoring

### Low Risk
- **Phase 1 JSON Allowlist**: Could allow malformed JSON to corrupt state files
  - Mitigation: Limited to specific keys (allowlist), not global permission
  - Mitigation: Existing state file parsing already handles JSON (jq validation possible)
- **Phase 3 ERR Trap Suppression**: Could suppress legitimate errors if flag not reset
  - Mitigation: Flag auto-resets in trap handler after use
  - Mitigation: Only library functions set flag (controlled usage)

## Success Metrics

### Error Reduction
- [ ] 23 state_error entries for JSON validation eliminated (100% reduction)
- [ ] 1 agent_error entry for implementer-coordinator summary creation resolved
- [ ] 93 execution_error entries reduced by 20-30% (cascading trap noise)
- [ ] 9 state_error entries for STATE_FILE unset eliminated (auto-recovery)

### Code Quality
- [ ] All phases pass unit + integration tests
- [ ] No regressions in existing test suite
- [ ] Linter checks pass for all modified files
- [ ] Error log integrity maintained (valid JSONL)

### Documentation Quality
- [ ] Pattern docs updated with examples (hard-barrier-subagent-delegation.md, error-handling.md)
- [ ] Standards docs updated with best practices (command-authoring.md)
- [ ] Inline code comments explain non-obvious logic

### Repair Completion
- [ ] All error log entries for this plan marked RESOLVED
- [ ] No FIX_PLANNED errors remain for plan path
- [ ] Error log includes resolution_metadata with plan reference

## Timeline

| Phase | Duration | Dependencies | Deliverables |
|-------|----------|--------------|--------------|
| Phase 1: JSON Allowlist | 2-3 hours | None | Updated state-persistence.sh, unit tests |
| Phase 2: Hard Barrier Diagnostics | 3-4 hours | Phase 1 | Updated implement.md, pattern docs, integration tests |
| Phase 3: ERR Trap Suppression | 2-3 hours | Phase 1 | Updated error-handling.sh, state-persistence.sh, pattern docs, unit tests |
| Phase 4: State Machine Guard | 2-3 hours | None | Updated workflow-state-machine.sh, linter, standards docs, unit tests |
| Phase 5: Integration Tests | 3-4 hours | Phases 1-4 | New test suite, CI integration |
| Phase 6: Error Log Update | 1 hour | Phases 1-5 | Updated error log with RESOLVED status |
| **Total** | **13-18 hours** | | **6 phases, 16 test cases, 5 doc updates** |

## Notes

### Coordination with Existing Repair Plans
- **Plan 998_repair_implement_20251201_154205**: Has FIX_PLANNED status for same JSON validation issue (Pattern 1)
- **Action**: Review plan 998 before implementing Phase 1 to avoid duplicate/conflicting fixes
- **Resolution**: If plan 998 already implemented JSON allowlist, skip Phase 1 and proceed with Phases 2-6

### Clean-Break Development Application
- All changes apply clean-break principles (internal tooling, no deprecation)
- State persistence allowlist: Unified implementation, no compatibility wrappers
- ERR trap suppression: New flag system, no legacy trap handlers
- State machine auto-init: Guard added to entry point, no dual initialization paths

### Testing Protocol Compliance
- Unit tests follow isolation standards (mock external dependencies)
- Integration tests use real commands/agents in test environment
- Coverage threshold: 80% for new code paths (allowlist, diagnostics, suppression, auto-init)
- Test discovery: All tests in .claude/tests/commands/ auto-discovered by CI

### Error Logging Integration
- All phases log errors using log_command_error for queryable tracking
- Phase 6 uses mark_errors_resolved_for_plan per repair workflow standards
- Error types: state_error (Phases 1, 4), agent_error (Phase 2), execution_error (Phase 3)

### Output Formatting Compliance
- Hard barrier diagnostics (Phase 2) use console summary format with emoji markers
- ERR trap suppression (Phase 3) reduces bash block output noise
- State machine auto-init (Phase 4) logs single warning line (not verbose diagnostics)
