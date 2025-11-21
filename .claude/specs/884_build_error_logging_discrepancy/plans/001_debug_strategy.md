# Build Error Logging Discrepancy - System-Wide Debug Strategy

## Metadata
- **Date**: 2025-11-20 (Revised: 2025-11-20)
- **Issue Type**: Debug (Root Cause Analysis + Fix)
- **Scope**: System-wide error logging gaps affecting 7 commands (13 call sites) where bash-level errors don't trigger traps
- **Estimated Phases**: 5
- **Estimated Hours**: 8-10 hours (expanded from 4-6 hours)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Research Reports**:
  - [Error Logging Gap Analysis](/home/benjamin/.config/.claude/specs/884_build_error_logging_discrepancy/reports/001_error_logging_gap_analysis.md)
  - [Command-Wide Error Handling Analysis](/home/benjamin/.config/.claude/specs/884_build_error_logging_discrepancy/reports/002_command_analysis.md)

## Overview

The /errors command reported zero errors for workflow `build_1763704235`, yet the build output shows multiple errors. Investigation revealed this is **NOT an isolated /build issue but a SYSTEMIC problem affecting 7 commands** (build, debug, plan, repair, research, revise, and orchestrator commands). The root cause is twofold:

1. **Execution Context Gap**: Bash error traps (ERR/EXIT) only fire on process termination, but Claude's bash tool intercepts errors without terminating the process
2. **Critical Missing Function**: All 7 affected commands call the non-existent function `save_completed_states_to_state` (13 total call sites), which fails with exit code 127 "command not found"

## Research Summary

**Report 1 - Error Logging Gap Analysis**: Identified the execution context boundary where bash traps fail to capture errors that don't cause process termination.

**Report 2 - Command Analysis (CRITICAL EXPANSION)**: Revealed the true scope:

**System-Wide Impact Statistics**:
- **7 commands affected**: build.md, debug.md, plan.md, repair.md, research.md, revise.md, and 3 orchestrator commands (expand, collapse, convert-docs)
- **13 call sites**: All invoking non-existent `save_completed_states_to_state` function
- **0 function validation sites**: No command validates library functions exist after sourcing
- **102 error logging sites**: 69% of commands (9/13) have comprehensive error logging
- **40 explicit exit checks**: Good defensive pattern adoption across 10 commands

**Critical Discovery**: `save_completed_states_to_state` DOES NOT EXIST in state-persistence.sh library. Only these functions exist:
- `init_workflow_state`
- `load_workflow_state`
- `append_workflow_state`
- `save_json_checkpoint`
- `load_json_checkpoint`

All 13 call sites currently fail with exit code 127, and while error handling catches the failure, the intended functionality (persisting completed states) never succeeds.

**Gaps Identified**:
- Non-existent function called 13 times across 7 commands
- Zero function validation after library sourcing (all 6 state-persistence commands affected)
- Errors in Claude's bash tool that don't terminate process (60-70% of errors)
- Orchestrator commands (expand, collapse, convert-docs) have exit checks but no error logging (31% coverage gap)

## Success Criteria

- [ ] Non-existent `save_completed_states_to_state` function replaced/removed across all 13 call sites
- [ ] All 7 affected commands validate library functions after sourcing
- [ ] All errors visible in command outputs appear in error log
- [ ] `/errors --workflow-id <id>` returns accurate error entries for all commands
- [ ] Error logging coverage reaches 90%+ for critical operations across ALL commands
- [ ] Orchestrator commands (expand, collapse, convert-docs) integrate error logging
- [ ] Test suite confirms error logging for all commands and error types
- [ ] Documentation updated with system-wide error logging best practices and validation patterns

## Technical Design

### Root Cause Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Claude Bash Tool Execution Layer                             │
│  - Intercepts errors before bash traps execute               │
│  - Displays "Error: Exit code N" but continues               │
│  - Bash process doesn't terminate → traps don't fire         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Bash Script Layer (build.md)                                 │
│  - ERR trap: setup_bash_error_trap (only fires on exit)     │
│  - EXIT trap: _log_bash_exit (only fires on exit)           │
│  - Gap: Errors that don't cause exit are never logged       │
└─────────────────────────────────────────────────────────────┘
```

### Solution Strategy: Multi-Layered Error Coverage

**Layer 1: Defensive Function Validation**
- Validate library functions exist before calling
- Early failure with explicit error logging
- Prevents "command not found" at runtime

**Layer 2: Explicit Error Checks After Critical Operations**
- Check exit codes after all state operations
- Log errors explicitly before propagating
- Covers cases where traps don't fire

**Layer 3: Wrapper Function for Common Patterns**
- Create `execute_with_logging()` wrapper in error-handling.sh
- Standardize error capture and logging
- Reduce boilerplate in commands

### Critical Operation Sites (System-Wide Analysis)

From command analysis report, **13 sites across 7 commands** calling non-existent function:

**Commands with `save_completed_states_to_state` calls**:
1. **/build command** (3 sites):
   - Line 543, 956, 1170

2. **/debug command** (3 sites):
   - Line 686, 918, 1128

3. **/plan command** (2 sites):
   - Line 678, 894

4. **/repair command** (2 sites):
   - Line 455, 646

5. **/research command** (1 site):
   - Line 621

6. **/revise command** (2 sites):
   - Line 598, 861

**Commands needing function validation** (6 commands using state-persistence.sh):
- build.md, debug.md, plan.md, repair.md, research.md, revise.md

**Commands needing error logging** (3 orchestrator commands):
- expand.md (7 exit checks, 0 error logging calls)
- collapse.md (likely similar pattern)
- convert-docs.md (minimal logging)

**Priority Order**:
1. **CRITICAL**: Fix/remove non-existent function (13 sites)
2. **HIGH**: Add function validation (6 commands)
3. **MEDIUM**: Add error logging to orchestrators (3 commands)
4. **LOW**: Wrapper function for standardization (benefits all)

## Implementation Phases

### Phase 0: Fix Non-Existent Function (CRITICAL) [NOT STARTED]
dependencies: []

**Objective**: Replace or remove all 13 call sites of non-existent `save_completed_states_to_state` function

**Complexity**: Medium (requires understanding state persistence intent)

**Tasks**:
- [ ] Investigate state-persistence.sh library to understand intended API for saving completed states
- [ ] Determine if `save_completed_states_to_state` should:
  - Be implemented as new function in state-persistence.sh (if functionality needed)
  - Be replaced with existing `append_workflow_state` calls (if state already persisted)
  - Be removed entirely (if it's a no-op)
- [ ] Review existing state persistence patterns in commands to understand intended behavior
- [ ] **Decision Point**: Choose implementation approach based on investigation
- [ ] **If implementing new function**: Add to state-persistence.sh with proper export
- [ ] **If using existing API**: Document correct pattern for replacing calls
- [ ] Replace/remove function calls in all 7 affected commands (13 sites total):
  - [ ] build.md: Lines 543, 956, 1170 (3 sites)
  - [ ] debug.md: Lines 686, 918, 1128 (3 sites)
  - [ ] plan.md: Lines 678, 894 (2 sites)
  - [ ] repair.md: Lines 455, 646 (2 sites)
  - [ ] research.md: Line 621 (1 site)
  - [ ] revise.md: Lines 598, 861 (2 sites)
- [ ] Verify error handling blocks remain intact after function fix

**Testing**:
```bash
# Test 1: Verify function exists (if implemented)
source .claude/lib/core/state-persistence.sh
type save_completed_states_to_state || echo "Function not found"

# Test 2: Run each affected command and verify no "command not found" errors
/build <test-plan> 2>&1 | grep -i "command not found"
/debug "test issue" 2>&1 | grep -i "command not found"
/plan "test feature" 2>&1 | grep -i "command not found"
# ... repeat for all 7 commands

# Test 3: Verify state persistence works correctly
# Check state files are created/updated as expected
cat .claude/data/state/workflow_*.json

# Test 4: Verify no exit code 127 errors in logs
/errors --type execution_error --since 1h | grep "127"
# Expected: No results (or only from other sources)
```

**Expected Duration**: 2-3 hours

**Priority Justification**: This is the ROOT CAUSE of the original error. All 13 sites currently fail with exit code 127, causing both error logging failures and functional failures (state not being persisted). MUST be fixed before other improvements.

---

### Phase 1: System-Wide Function Validation [NOT STARTED]
dependencies: [0]

**Objective**: Add defensive validation to ensure library functions exist after sourcing across all 6 state-persistence commands

**Complexity**: Low

**Tasks**:
- [ ] Add function validation helper to error-handling.sh:
  ```bash
  validate_required_functions() {
    local required_functions="$1"
    local missing_functions=""
    for func in $required_functions; do
      if ! type "$func" &>/dev/null; then
        missing_functions="$missing_functions $func"
      fi
    done
    if [ -n "$missing_functions" ]; then
      log_command_error \
        "${COMMAND_NAME:-unknown}" \
        "${WORKFLOW_ID:-unknown}" \
        "${USER_ARGS:-}" \
        "dependency_error" \
        "Missing required functions:$missing_functions" \
        "function_validation" \
        "$(jq -n --arg funcs "$missing_functions" '{missing_functions: $funcs}')"
      echo "ERROR: Missing functions:$missing_functions" >&2
      exit 1
    fi
  }
  ```
- [ ] Export `validate_required_functions` in error-handling.sh (file: /home/benjamin/.config/.claude/lib/core/error-handling.sh, line ~1340)
- [ ] Add validation to ALL 6 commands using state-persistence.sh after library sourcing:
  - [ ] build.md: Add validation in bash blocks (validate functions based on Phase 0 decision)
  - [ ] debug.md: Add validation after sourcing
  - [ ] plan.md: Add validation after sourcing
  - [ ] repair.md: Add validation after sourcing
  - [ ] research.md: Add validation after sourcing
  - [ ] revise.md: Add validation after sourcing
- [ ] Validation pattern (adjust function list based on Phase 0 outcome):
  ```bash
  # After sourcing state-persistence.sh
  validate_required_functions "init_workflow_state load_workflow_state append_workflow_state [save_completed_states_to_state if implemented]"
  ```
- [ ] Test validation with missing function scenario across all commands

**Testing**:
```bash
# Test 1: Simulate missing function
# Temporarily rename function in state-persistence.sh
# Run each command and verify error is logged immediately

# Test 2: Verify errors appear in /errors command for each command
/errors --type dependency_error --since 5m

# Test 3: Test all 6 commands
for cmd in build debug plan repair research revise; do
  echo "Testing /$cmd..."
  /$cmd <test-args> 2>&1 | grep -i "missing function" && echo "✓ Validation working"
done

# Expected: All commands catch missing functions early with explicit error logging
```

**Expected Duration**: 2.5 hours (expanded from 1.5 hours for system-wide rollout)

---

### Phase 2: Error Logging for Orchestrator Commands [NOT STARTED]
dependencies: [1]

**Objective**: Extend error logging to orchestrator commands (expand, collapse, convert-docs) to close 31% coverage gap

**Complexity**: Medium

**Tasks**:
- [ ] Analyze expand.md for error logging integration:
  - 7 explicit exit code checks exist
  - 0 log_command_error calls currently
  - Need to source error-handling.sh and add logging
- [ ] Add error-handling.sh to expand.md:
  ```bash
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
    echo "ERROR: Cannot load error-handling library" >&2
    exit 1
  }
  ensure_error_log_exists
  ```
- [ ] Wrap all 7 exit code checks in expand.md with log_command_error:
  ```bash
  OPERATION_EXIT=$?
  if [ $OPERATION_EXIT -ne 0 ]; then
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "execution_error" "Operation failed" "operation_context"
    echo "ERROR: Operation failed" >&2
    exit 1
  fi
  ```
- [ ] Repeat for collapse.md (likely similar pattern to expand.md)
- [ ] Repeat for convert-docs.md (minimal logging currently, add comprehensive coverage)
- [ ] Set workflow metadata for each command:
  ```bash
  COMMAND_NAME="/expand"  # or /collapse, /convert-docs
  WORKFLOW_ID="expand_$(date +%s)"
  USER_ARGS="$*"
  ```

**Testing**:
```bash
# Test 1: Trigger failures in each orchestrator command
/expand <invalid-phase-path> 2>&1
/errors --command /expand --limit 5
# Expected: Errors logged and queryable

# Test 2: Test all orchestrator commands
for cmd in expand collapse convert-docs; do
  echo "Testing /$cmd error logging..."
  /$cmd <invalid-args> 2>&1
  /errors --command /$cmd --since 5m
done

# Test 3: Verify coverage improvement
# Count commands with error logging: before 9/13 (69%), target 12/13 (92%)
grep -l "log_command_error" .claude/commands/*.md | wc -l
# Expected: 12 commands
```

**Expected Duration**: 2.5 hours

**Priority Justification**: Orchestrator commands are critical workflow tools. Current 69% coverage is inadequate. Expanding to 92% provides comprehensive error tracking across system.

---

### Phase 3: Wrapper Function and Refactoring [NOT STARTED]
dependencies: [2]

**Objective**: Create reusable wrapper function to standardize error logging pattern across all commands

**Complexity**: Medium

**Tasks**:
- [ ] Add `execute_with_logging()` wrapper to error-handling.sh:
  ```bash
  # execute_with_logging: Execute command with automatic error logging
  # Usage: execute_with_logging "operation_name" command [args...]
  # Returns: Command exit code
  # Effect: Logs error if command fails, returns exit code
  execute_with_logging() {
    local operation="$1"
    shift
    local output
    local exit_code

    output=$("$@" 2>&1)
    exit_code=$?

    if [ $exit_code -ne 0 ]; then
      log_command_error \
        "${COMMAND_NAME:-unknown}" \
        "${WORKFLOW_ID:-unknown}" \
        "${USER_ARGS:-}" \
        "execution_error" \
        "$operation failed: $(echo "$output" | head -1)" \
        "execute_wrapper" \
        "$(jq -n --argjson code "$exit_code" --arg op "$operation" \
           '{exit_code: $code, operation: $op}')"
      echo "$output" >&2
    fi

    return $exit_code
  }
  ```
- [ ] Export `execute_with_logging` in error-handling.sh
- [ ] Identify high-value refactoring candidates across all commands:
  - State persistence operations (after Phase 0 fix)
  - Library sourcing validation calls
  - Critical operation sequences
- [ ] Refactor 10-15 sites across multiple commands to demonstrate pattern:
  - [ ] build.md: 2-3 sites
  - [ ] debug.md: 2-3 sites
  - [ ] plan.md: 2 sites
  - [ ] repair.md: 2 sites
  - [ ] expand.md: 2 sites
  ```bash
  # Before:
  critical_operation
  OP_EXIT=$?
  if [ $OP_EXIT -ne 0 ]; then
    log_command_error ...
    exit 1
  fi

  # After:
  execute_with_logging "Critical operation" critical_operation || exit 1
  ```
- [ ] Document wrapper usage in error-handling.md pattern guide
- [ ] Add wrapper examples to code-standards.md

**Testing**:
```bash
# Test 1: Use wrapper with successful operation
execute_with_logging "Test operation" echo "success"
# Expected: No error logged, returns 0

# Test 2: Use wrapper with failing operation
execute_with_logging "Test operation" false
# Expected: Error logged, returns 1

# Test 3: Verify error appears in /errors
/errors --type execution_error --limit 1

# Test 4: Test wrapper across multiple commands
for cmd in build debug plan repair expand; do
  # Run command using wrapper pattern
  # Verify errors logged correctly
done
```

**Expected Duration**: 2 hours (expanded from 1.5 hours for multi-command refactoring)

---

### Phase 4: System-Wide Test Suite and Validation [NOT STARTED]
dependencies: [3]

**Objective**: Verify fix completeness across all commands and create comprehensive test coverage

**Complexity**: Medium

**Tasks**:
- [ ] Create comprehensive test suite (file: /home/benjamin/.config/.claude/tests/test_error_logging_coverage.sh):
  - Test command not found scenario (Phase 0 fix validation)
  - Test syntax error scenario
  - Test state operation failure
  - Test missing library function (Phase 1 validation)
  - Test orchestrator command errors (Phase 2 validation)
  - Test wrapper function error capture (Phase 3 validation)
  - Verify all errors appear in /errors output
- [ ] Create automated test for all 13 commands:
  ```bash
  # Test each command's error logging
  test_commands=(build debug plan repair research revise expand collapse convert-docs setup optimize-claude errors errors)
  for cmd in "${test_commands[@]}"; do
    test_command_error_logging "/$cmd"
  done
  ```
- [ ] Run comprehensive test suite and verify 90%+ coverage across all commands:
  ```bash
  bash .claude/tests/test_error_logging_coverage.sh
  ```
- [ ] Measure error logging coverage improvement:
  ```bash
  # Before: 69% (9/13 commands)
  # After: Target 92% (12/13 commands, excluding errors.md query-only)
  grep -l "log_command_error" .claude/commands/*.md | wc -l
  ```
- [ ] Validate no regression in existing error logging (run existing test suite)

**Testing**:
```bash
# Test 1: Reproduce original issue
# Use same build that triggered the bug
# Verify errors now appear in /errors output
/build <original-plan>
/errors --workflow-id build_*

# Test 2: Coverage measurement across all commands
# Test build, debug, plan, repair, research, revise
for cmd in build debug plan repair research revise; do
  echo "Testing /$cmd..."
  /$cmd <test-args> 2>&1 | tee /tmp/${cmd}_output.log
  VISIBLE_ERRORS=$(grep -c "Error:" /tmp/${cmd}_output.log || echo 0)
  LOGGED_ERRORS=$(/errors --command /$cmd --since 5m | wc -l)
  COVERAGE=$(echo "scale=2; $LOGGED_ERRORS / $VISIBLE_ERRORS * 100" | bc)
  echo "$cmd coverage: $COVERAGE%"
done

# Test 3: Different error types across commands
# Command not found: verify logged (should not occur after Phase 0)
# Syntax error: verify logged
# State error: verify logged
# Missing function: verify logged (should fail fast with Phase 1)
# Orchestrator errors: verify logged (Phase 2)

# Test 4: Error queryability
/errors --type execution_error --since 1h
/errors --type state_error --since 1h
/errors --type dependency_error --since 1h
/errors --command /build --limit 10
/errors --command /expand --limit 10
# All queries should return accurate results
```

**Expected Duration**: 2.5 hours (expanded from 1.5 hours for system-wide validation)

---

### Phase 5: Documentation and Rollout [NOT STARTED]
dependencies: [4]

**Objective**: Document system-wide error logging patterns and create rollout plan for other projects

**Complexity**: Low

**Tasks**:
- [ ] Update error-handling pattern documentation (.claude/docs/concepts/patterns/error-handling.md):
  - Add "Common Pitfalls" section describing trap limitations
  - Add "Execution Context Boundary" section explaining Claude bash tool behavior
  - Add "Best Practices" section with wrapper function examples
  - Add "Function Validation Pattern" section (Phase 1)
  - Add "Testing Error Logging" section with validation approach
  - Add "System-Wide Rollout Checklist" for future commands
- [ ] Update CLAUDE.md error logging section:
  - Reference new validation patterns
  - Add quick reference for function validation
  - Add wrapper function usage examples
  - Update error logging coverage statistics (69% → 92%)
- [ ] Update code-standards.md:
  - Add mandatory function validation after library sourcing
  - Add error logging requirements for all commands
  - Add wrapper function usage patterns
- [ ] Create debug report documenting the fix (file: /home/benjamin/.config/.claude/specs/884_build_error_logging_discrepancy/debug/001_fix_summary.md):
  - Original issue description
  - Root cause analysis
  - System-wide impact (7 commands, 13 call sites)
  - Implementation phases summary
  - Before/after metrics (coverage, error counts)
  - Lessons learned
  - Rollout checklist for other projects
- [ ] Create command author guide:
  - "How to Add Error Logging to New Commands"
  - Function validation template
  - Error check patterns
  - Wrapper function examples
  - Testing checklist

**Testing**:
```bash
# Test 1: Verify documentation completeness
# Check all patterns are documented
# Check examples are runnable
# Check cross-references are valid

# Test 2: Validate command author guide
# Create test command following guide
# Verify it has proper error logging
# Verify it passes test suite

# Test 3: Final validation
# Run all commands with intentional errors
# Verify 90%+ coverage maintained
# Verify /errors command returns accurate data
```

**Expected Duration**: 2 hours

---

## Testing Strategy

### Unit Testing
- Test `validate_required_functions` with various function availability scenarios across all 6 state-persistence commands
- Test `execute_with_logging` wrapper with successful and failing operations
- Test error log entry format and queryability for all error types
- Test Phase 0 fix: verify function exists or calls removed correctly

### Integration Testing
- Run ALL 7 affected commands with intentional errors and verify logging:
  - /build, /debug, /plan, /repair, /research, /revise (state-persistence commands)
  - /expand, /collapse, /convert-docs (orchestrator commands)
- Test error recovery and continuation scenarios across commands
- Verify /errors command returns accurate results for all commands
- Test cross-command error queries (e.g., all state_error types across commands)

### Regression Testing
- Run existing test suite to ensure no breaking changes
- Test normal execution (no errors) for all 13 commands completes successfully
- Verify backward compatibility with existing error logging (9 commands already have it)
- Validate no performance degradation from additional validation/logging

### System-Wide Coverage Measurement
```bash
# Measure error logging coverage across all commands
# Target: 92% (12/13 commands, excluding errors.md query-only)

# Before fix: 69% (9/13 commands)
BEFORE_COVERAGE=$(grep -l "log_command_error" .claude/commands/*.md | wc -l)
echo "Commands with error logging before: $BEFORE_COVERAGE/13"

# After fix: Target 92%
AFTER_COVERAGE=$(grep -l "log_command_error" .claude/commands/*.md | wc -l)
echo "Commands with error logging after: $AFTER_COVERAGE/13"

# Test each command individually
for cmd in build debug plan repair research revise expand collapse convert-docs; do
  echo "Testing /$cmd error logging coverage..."
  /$cmd <test-with-errors> 2>&1 | tee /tmp/${cmd}_output.log
  VISIBLE_ERRORS=$(grep -c "Error:" /tmp/${cmd}_output.log || echo 0)
  LOGGED_ERRORS=$(/errors --command /$cmd --since 5m | wc -l)
  if [ $VISIBLE_ERRORS -gt 0 ]; then
    COVERAGE=$(echo "scale=2; $LOGGED_ERRORS / $VISIBLE_ERRORS * 100" | bc)
    echo "  $cmd coverage: $COVERAGE% ($LOGGED_ERRORS/$VISIBLE_ERRORS errors logged)"
  fi
done

# Overall target: 90%+ coverage for each command
```

## Documentation Requirements

### Updated Library Files
1. **error-handling.sh**: Add `validate_required_functions` and `execute_with_logging` wrapper
2. **state-persistence.sh**: Fix/implement `save_completed_states_to_state` (if Phase 0 determines it's needed)

### Updated Command Files (13 total)
**Critical Updates (7 commands - Phase 0 & 1)**:
1. **build.md**: Replace 3 function call sites, add validation
2. **debug.md**: Replace 3 function call sites, add validation
3. **plan.md**: Replace 2 function call sites, add validation
4. **repair.md**: Replace 2 function call sites, add validation
5. **research.md**: Replace 1 function call site, add validation
6. **revise.md**: Replace 2 function call sites, add validation

**Error Logging Additions (3 commands - Phase 2)**:
7. **expand.md**: Add error-handling.sh sourcing, wrap 7 exit checks
8. **collapse.md**: Add error-handling.sh sourcing, add logging
9. **convert-docs.md**: Add error-handling.sh sourcing, add logging

**Refactoring (5 commands - Phase 3)**:
10-14. Refactor 10-15 sites across build, debug, plan, repair, expand to use wrapper function

### Updated Documentation Files
1. **error-handling.md**: Document trap limitations, execution context boundary, best practices, validation patterns, wrapper usage
2. **code-standards.md**: Add mandatory function validation and error logging requirements
3. **CLAUDE.md**: Update error logging quick reference with validation patterns and coverage statistics

### New Files
1. **test_error_logging_coverage.sh**: Comprehensive test suite for error logging validation across all commands
2. **001_fix_summary.md**: Debug report documenting the system-wide fix
3. **command-author-error-logging-guide.md**: Guide for adding error logging to new commands

### Documentation Content
- **Scope expansion**: From single command (/build) to system-wide (7 commands, 13 call sites)
- **Root cause**: Non-existent function + trap execution context boundary
- **Trap scope limitations**: Bash traps only fire on process termination
- **Claude bash tool behavior**: Error interception without termination
- **Function validation pattern**: Validate after library sourcing
- **Wrapper function usage**: Standardize error logging across commands
- **System-wide rollout**: 69% → 92% coverage improvement
- **Error logging best practices**: For command authors
- **Testing approach**: System-wide validation and coverage measurement

## Dependencies

### Internal Dependencies
- error-handling.sh library (exists)
- state-persistence.sh library (exists)
- /errors command (exists)
- Test framework (exists)

### External Dependencies
- None

### Prerequisite Knowledge
- Bash trap behavior and limitations
- Claude bash tool execution model
- JSONL error log format
- State-based orchestration architecture

## Risk Assessment

### Implementation Risks

**Risk 1: System-Wide Scope (HIGH → Mitigated)**
- Original plan focused on /build only, now affects 7 commands
- Mitigation: Phased rollout (Phase 0 critical fix → Phase 1 validation → Phase 2 expansion)
- Mitigation: Comprehensive testing in Phase 4 before documentation rollout
- Impact: Higher complexity but better long-term system reliability

**Risk 2: Breaking Changes from Phase 0 (MEDIUM)**
- Removing/replacing non-existent function may break workflows
- Mitigation: All 13 call sites currently fail anyway (exit code 127), so fix improves status quo
- Mitigation: Phase 0 investigates correct approach before making changes
- Impact: Commands currently broken, fix can only improve situation

**Risk 3: Performance Impact (LOW)**
- Adding function validation and explicit error checks across all commands
- Mitigation: Validation runs once per bash block (minimal overhead)
- Mitigation: Wrapper function adds single function call (negligible)
- Impact: Estimated <5% performance degradation for error paths only

**Risk 4: Incomplete Coverage (LOW → Mitigated by Phase 4)**
- May miss some error scenarios not identified in analysis
- Mitigation: Phase 4 comprehensive testing validates 90%+ coverage
- Mitigation: Command analysis report identified specific sites needing fixes
- Impact: Coverage improves from ~30% to 90%+ (measured improvement)

**Risk 5: Regression in Existing Commands (LOW)**
- Changes to 9 commands with existing error logging may break patterns
- Mitigation: Regression testing in Phase 4 validates no breaking changes
- Mitigation: Phase 3 wrapper is additive (doesn't remove existing patterns)
- Impact: Backward compatibility maintained

### Rollback Plan

If implementation causes issues, phased rollback:

**Phase 0 Issues**:
- Revert function replacements, investigate alternative approach
- Document the function as "known issue" until proper fix identified

**Phase 1-2 Issues**:
1. Revert Phase 3 wrapper refactoring (keep explicit checks)
2. Revert Phase 2 orchestrator logging (if specific issues arise)
3. Keep Phase 1 validation (defensive programming, low risk)
4. Keep Phase 0 fix (critical issue, must be resolved)

**Phase 3+ Issues**:
- Wrapper function is optional optimization, safe to revert
- Keep Phases 0-2 (core fixes with high value)
- Document limitations and continue with partial implementation

**Full Rollback** (only if critical system failure):
1. Revert all command changes
2. Revert library changes
3. Keep documentation updates (learning value)
4. Create new plan with different approach

## Success Metrics

### Quantitative Metrics

**Command Coverage** (Primary Metric):
- Before: 69% (9/13 commands with error logging)
- Target: 92% (12/13 commands, excluding errors.md query-only)
- Measured by: `grep -l "log_command_error" .claude/commands/*.md | wc -l`

**Error Logging Coverage per Command** (Secondary Metric):
- Before: ~30% (errors occur but not logged due to trap gaps)
- Target: 90%+ for each command
- Measured by: Visible errors vs. logged errors for each command

**Critical Function Issue** (Phase 0 Success):
- Before: 13 call sites fail with exit code 127
- Target: 0 call sites fail with "command not found"
- Measured by: `grep -r "save_completed_states_to_state" .claude/commands/*.md`

**Function Validation** (Phase 1 Success):
- Before: 0/6 state-persistence commands validate functions
- Target: 6/6 commands validate functions after sourcing
- Measured by: `grep -l "validate_required_functions" .claude/commands/*.md | wc -l`

**Error Type Distribution** (Queryability):
- False negative rate: Target <5% (errors occur but not logged)
- Error log query accuracy: Target 100% (all logged errors queryable via /errors)
- Cross-command queries work correctly (e.g., all state_error types)

### Qualitative Metrics
- Developer confidence in error log system
- Ease of debugging failures across all commands (not just /build)
- User trust in /errors command
- Command author ability to add error logging following documented patterns

### System-Wide Validation Approach
```bash
# Validate across all affected commands
for cmd in build debug plan repair research revise expand collapse convert-docs; do
  echo "=== Testing /$cmd ==="

  # Run with known errors
  /$cmd <test-with-errors> 2>&1 | tee /tmp/${cmd}_output.log

  # Count visible vs. logged errors
  VISIBLE_ERRORS=$(grep -c "Error:" /tmp/${cmd}_output.log || echo 0)
  LOGGED_ERRORS=$(/errors --command /$cmd --since 5m | wc -l)

  if [ $VISIBLE_ERRORS -gt 0 ]; then
    COVERAGE=$(echo "scale=2; $LOGGED_ERRORS / $VISIBLE_ERRORS * 100" | bc)
    echo "Coverage: $COVERAGE% ($LOGGED_ERRORS/$VISIBLE_ERRORS)"

    # Validate against target
    if (( $(echo "$COVERAGE >= 90" | bc -l) )); then
      echo "✓ PASS: Coverage meets 90% target"
    else
      echo "✗ FAIL: Coverage below 90% target"
    fi
  fi
done

# Overall system metrics
echo ""
echo "=== System-Wide Metrics ==="
COMMANDS_WITH_LOGGING=$(grep -l "log_command_error" .claude/commands/*.md | wc -l)
echo "Commands with error logging: $COMMANDS_WITH_LOGGING/13 (target: 12)"

COMMANDS_WITH_VALIDATION=$(grep -l "validate_required_functions" .claude/commands/*.md | wc -l)
echo "Commands with function validation: $COMMANDS_WITH_VALIDATION/6 (target: 6)"

MISSING_FUNCTION_CALLS=$(grep -r "save_completed_states_to_state" .claude/commands/*.md | wc -l)
echo "Non-existent function calls: $MISSING_FUNCTION_CALLS (target: 0)"

# Target: All metrics meet or exceed targets
```

## Next Steps

After completing this system-wide debug strategy:

1. **Validate Full Implementation**: Run comprehensive test suite across all 13 commands
2. **Monitor Error Logs**: Use /errors command to track error patterns across system
3. **Create Monitoring Dashboard** (Future Enhancement): Dashboard showing real-time error logging coverage metrics
4. **Automated Testing in CI/CD** (Future Enhancement): Add error logging coverage validation to continuous integration
5. **Command Author Education**: Share command-author-error-logging-guide.md with team
6. **Apply to Other Projects**: Use rollout checklist to extend patterns to other .claude/ systems
7. **Periodic Review**: Quarterly review of error logging coverage to maintain 90%+ target

## Notes

### Key Insights from Research

**From Report 1 (Error Logging Gap Analysis)**:
- Bash traps only fire on process termination
- Claude's bash tool intercepts errors without terminating
- ~60-70% of errors currently go unlogged
- Execution context boundary prevents trap firing

**From Report 2 (Command Analysis - CRITICAL)**:
- **System-wide issue**: 7 commands affected (not just /build)
- **13 call sites**: All calling non-existent `save_completed_states_to_state`
- **0 validation**: No command validates library functions after sourcing
- **69% baseline coverage**: 9/13 commands have error logging (target: 92%)
- **Function doesn't exist**: Not in state-persistence.sh library

### Scope Evolution

**Original Assumption**: Isolated /build command issue with bash traps
**Reality Discovered**: System-wide architectural gap affecting:
- 7 commands with non-existent function calls (13 sites)
- 6 commands missing function validation
- 3 orchestrator commands missing error logging
- All commands affected by trap execution context boundary

**Plan Revision**: Expanded from 4 phases (4-6 hours) to 5 phases (8-10 hours) to address full scope

### Design Decisions

- **Why Phase 0 first?**: Critical non-existent function is ROOT CAUSE of error logging failures
- **Why system-wide Phase 1?**: Function validation prevents future "command not found" errors across all commands
- **Why orchestrator focus in Phase 2?**: Closes 31% coverage gap (69% → 92%)
- **Why wrapper in Phase 3?**: Reduces boilerplate across 10+ commands, standardizes pattern
- **Why comprehensive testing in Phase 4?**: System-wide changes require system-wide validation
- **Why documentation phase?**: Patterns must be transferable to future commands and projects

### Implementation Priorities

1. **CRITICAL (Phase 0)**: Fix non-existent function - all 13 sites currently broken
2. **HIGH (Phase 1)**: Add function validation - prevents future runtime failures
3. **MEDIUM (Phase 2)**: Extend logging to orchestrators - improves coverage to 92%
4. **LOW (Phase 3)**: Wrapper refactoring - reduces technical debt, optional optimization
5. **VALIDATION (Phase 4-5)**: Testing and documentation - ensures sustainable solution

### Future Enhancements
- Consider output scraping as supplementary coverage (research Solution 2 from Report 1)
- Explore bash tool modifications for native error logging (research Solution 3 from Report 1)
- Create error logging linter to validate new commands during development
- Automated coverage monitoring dashboard
- CI/CD integration for error logging validation
