# /todo Error Logging Enhancement Implementation Plan

## Metadata
- **Date**: 2025-12-01
- **Feature**: Enhance /todo error logging with dual trap setup and pre-trap buffering
- **Scope**: Fix 79-line error coverage gap in /todo command, align with /build, /plan, /repair patterns
- **Estimated Phases**: 4
- **Estimated Hours**: 3.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 28.5
- **Research Reports**:
  - [/todo Error Logging Analysis](/home/benjamin/.config/.claude/specs/996_todo_error_logging_improve/reports/001-todo-error-logging-analysis.md)

## Overview

The /todo command currently has a 79-line coverage gap (lines 123-202) where errors are not captured by the error logging trap. Research analysis shows /build, /plan, and /repair commands use a **dual trap setup pattern** (early trap with placeholder values + late trap with actual WORKFLOW_ID) to ensure continuous error coverage from line 1 onwards. This plan implements the same pattern in /todo, adding pre-trap error buffering and validation to match best practices.

## Research Summary

Key findings from error logging analysis:

1. **Dual Trap Setup Pattern**: /build, /plan, /repair call `setup_bash_error_trap` immediately after sourcing error-handling.sh (with placeholder values), then call it again after WORKFLOW_ID is available. /todo only calls it once, leaving a 79-line gap.

2. **Pre-Trap Error Buffering**: error-handling.sh provides `_buffer_early_error()` and `_flush_early_errors()` functions to capture errors before trap is active. /build and /plan use this; /todo does not.

3. **Root Cause of Recent Failure**: The escaped negation error (`[[ \! ... ]]`) occurred during argument parsing before the trap was active (line 202). Exit code 2 (syntax error) would have been captured if early trap was set up.

4. **Consistent Initialization Pattern**: All commands follow the same 3-step pattern (source error-handling.sh, call ensure_error_log_exists, call setup_bash_error_trap), but /todo lacks the early trap call that others have.

Recommended approach: Add dual trap setup to /todo following /build's pattern (highest maturity implementation).

## Success Criteria

- [ ] Early trap setup added immediately after error-handling.sh sourcing
- [ ] Late trap update preserves existing WORKFLOW_ID integration
- [ ] Pre-trap error buffering enabled with _flush_early_errors call
- [ ] Post-trap validation confirms trap is active
- [ ] No errors occur during /todo execution with --clean flag
- [ ] All error coverage gaps eliminated (verified via error injection test)
- [ ] Implementation matches /build, /plan, /repair patterns exactly

## Technical Design

### Architecture Overview

**Current /todo Error Logging Flow** (BEFORE):
```
Line 123: set +H
Lines 123-168: Argument parsing (NO ERROR COVERAGE)
Line 169: Source error-handling.sh
Lines 170-192: Variable initialization (NO ERROR COVERAGE)
Line 193: ensure_error_log_exists
Lines 194-201: Set COMMAND_NAME, WORKFLOW_ID, USER_ARGS
Line 202: setup_bash_error_trap (FIRST AND ONLY TRAP)
Lines 203+: Normal execution (FULL ERROR COVERAGE)
```

**Enhanced /todo Error Logging Flow** (AFTER):
```
Line 123: set +H
Lines 123-168: Argument parsing (STILL NO COVERAGE - before sourcing)
Line 169: Source error-handling.sh
Line 175: setup_bash_error_trap (EARLY TRAP - placeholder values)
Line 176: _flush_early_errors (buffer any pre-source errors)
Line 177: Trap validation check (NEW)
Lines 178-201: Variable initialization (FULL ERROR COVERAGE)
Line 202: ensure_error_log_exists
Lines 203-210: Set COMMAND_NAME, WORKFLOW_ID, USER_ARGS
Line 211: setup_bash_error_trap (LATE TRAP - actual values)
Lines 212+: Normal execution (FULL ERROR COVERAGE)
```

**Improvement**: Coverage gap reduced from 79 lines to 0 lines (post-sourcing).

### Component Changes

**File**: /home/benjamin/.config/.claude/commands/todo.md

**Change 1**: Add early trap setup after error-handling.sh sourcing
- Location: After line 174 (immediately after sourcing block)
- Pattern: `setup_bash_error_trap "/todo" "todo_early_$(date +%s)" "early_init"`

**Change 2**: Add pre-trap error buffer flush
- Location: Immediately after early trap setup
- Pattern: `_flush_early_errors`

**Change 3**: Add trap validation check
- Location: After early trap setup and flush
- Pattern: Validate ERR trap is active with grep check

**Change 4**: Update late trap call with proper context
- Location: Existing line 202 (will shift to ~line 211 after insertions)
- Pattern: Preserve existing `setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"`

### Standards Alignment

- **Error Logging Standards**: Implements dual trap pattern documented in .claude/docs/concepts/patterns/error-handling.md
- **Code Standards**: Follows three-tier sourcing pattern (error-handling.sh is Tier 1 library)
- **Output Formatting Standards**: Error suppression on sourcing line (`2>/dev/null`) preserves quiet initialization
- **Clean-Break Development**: No deprecated code paths - directly replaces single trap with dual trap

### Risk Mitigation

**Risk 1**: Early trap with placeholder values may cause confusion in error logs
- Mitigation: Use descriptive workflow ID (`todo_early_$(date +%s)`) and args (`early_init`)
- Verification: Check errors.jsonl for clear distinction between early/late trap entries

**Risk 2**: Trap validation check may fail silently if grep patterns change
- Mitigation: Use exact pattern from error-handling.sh (`_log_bash_error`)
- Verification: Add test that intentionally triggers error after validation

**Risk 3**: Pre-trap buffer flush may duplicate errors if buffering logic changes
- Mitigation: Follow /build's implementation exactly (tested in production)
- Verification: Error injection test confirms no duplicate log entries

## Implementation Phases

### Phase 1: Add Early Trap Setup [COMPLETE]
dependencies: []

**Objective**: Insert early trap call immediately after error-handling.sh sourcing to begin error coverage

**Complexity**: Low

**Tasks**:
- [x] Read /todo command file to identify exact insertion point (after line 174)
- [x] Insert early trap setup: `setup_bash_error_trap "/todo" "todo_early_$(date +%s)" "early_init"`
- [x] Verify bash syntax with `bash -n` check
- [x] Confirm line numbers match research report expectations

**Testing**:
```bash
# Syntax validation
bash -n .claude/commands/todo.md

# Line count verification (should increase by 1)
grep -n "setup_bash_error_trap" .claude/commands/todo.md
```

**Expected Duration**: 0.5 hours

### Phase 2: Add Pre-Trap Error Buffering and Validation [COMPLETE]
dependencies: [1]

**Objective**: Enable pre-trap error buffering and validate trap is active

**Complexity**: Low

**Tasks**:
- [x] Insert `_flush_early_errors` call immediately after early trap setup
- [x] Insert trap validation check:
  ```bash
  if ! trap -p ERR | grep -q "_log_bash_error"; then
    echo "ERROR: ERR trap not active - error logging will fail" >&2
    exit 1
  fi
  ```
- [x] Update comments to document dual trap pattern and rationale
- [x] Verify line number shift (late trap call should move to ~line 211)

**Testing**:
```bash
# Verify flush function exists
grep -q "_flush_early_errors" .claude/lib/core/error-handling.sh

# Verify trap validation pattern
grep -n "trap -p ERR" .claude/commands/todo.md
```

**Expected Duration**: 0.75 hours

### Phase 3: Integration Testing with Error Injection [COMPLETE]
dependencies: [2]

**Objective**: Verify error logging captures errors in previously uncovered window

**Complexity**: Medium

**Tasks**:
- [x] Create test script that simulates errors during argument parsing window
- [x] Inject deliberate error after early trap but before late trap (test coverage)
- [x] Run /todo with error injection and verify errors.jsonl contains entry
- [x] Check error log entry has correct command_name ("/todo"), workflow_id (early or late)
- [x] Verify no duplicate error entries from buffer flushing
- [x] Test normal /todo execution (no errors) produces no spurious log entries

**Testing**:
```bash
# Error injection test
# (Create temporary test version of /todo with injected error)
INJECTED_LINE="exit 99  # TEST ERROR INJECTION"
sed "180i $INJECTED_LINE" .claude/commands/todo.md > /tmp/todo_test.md
bash /tmp/todo_test.md --clean 2>&1 | tee /tmp/todo_test_output.log

# Verify error logged
grep -q "exit_code.*99" .claude/tests/logs/test-errors.jsonl

# Verify workflow ID present
grep "todo_early_" .claude/tests/logs/test-errors.jsonl

# Clean up test artifacts
rm /tmp/todo_test.md /tmp/todo_test_output.log
```

**Expected Duration**: 1.5 hours

### Phase 4: Documentation and Validation [COMPLETE]
dependencies: [3]

**Objective**: Document changes and validate alignment with other commands

**Complexity**: Low

**Tasks**:
- [x] Add inline comments explaining dual trap pattern in /todo
- [x] Update .claude/docs/concepts/patterns/error-handling.md if pattern is not documented
- [x] Compare /todo trap setup with /build, /plan, /repair (verify exact pattern match)
- [x] Add this plan to /todo's implementation artifacts section (if exists)
- [x] Run /todo --clean in production to verify no regressions

**Testing**:
```bash
# Pattern alignment check
diff -u \
  <(grep -A5 "setup_bash_error_trap" .claude/commands/build.md | head -n 10) \
  <(grep -A5 "setup_bash_error_trap" .claude/commands/todo.md | head -n 10)

# Production smoke test
/todo --clean
echo "Exit code: $?"  # Should be 0
```

**Expected Duration**: 0.75 hours

## Testing Strategy

### Overall Approach

**Unit Testing**: Verify each trap setup call individually
- Early trap: Check trap is active after line 175
- Late trap: Check trap is updated after line 211
- Buffer flush: Verify _flush_early_errors is called

**Integration Testing**: Verify error coverage across full lifecycle
- Error injection at line 180 (between early and late trap)
- Error injection at line 210 (after late trap)
- Normal execution (no errors) produces clean logs

**Regression Testing**: Ensure no impact on existing functionality
- Run /todo --clean on production .claude/TODO.md
- Verify output format unchanged
- Verify exit code remains 0 on success

### Success Criteria

- [ ] Early trap captures errors in lines 175-210 (previously uncovered window)
- [ ] Late trap captures errors in lines 211+ (existing coverage maintained)
- [ ] Pre-trap buffer flush prevents error loss before sourcing
- [ ] Trap validation fails fast if setup is broken
- [ ] No duplicate error log entries
- [ ] No regressions in /todo functionality

## Documentation Requirements

### Files to Update

1. **/.claude/commands/todo.md**: Add inline comments explaining dual trap pattern
2. **/.claude/docs/concepts/patterns/error-handling.md**: Document dual trap setup as best practice (if not already documented)

### Documentation Content

**Inline Comments** (in /todo):
```bash
# Early trap setup: Capture errors during initialization before WORKFLOW_ID is available.
# This follows the dual trap pattern used by /build, /plan, and /repair commands.
# The trap will be updated later with actual workflow context (see late trap setup below).
setup_bash_error_trap "/todo" "todo_early_$(date +%s)" "early_init"

# Flush any errors that occurred before error-handling.sh was sourced.
_flush_early_errors

# Validate trap is active - fail fast if error logging is broken.
if ! trap -p ERR | grep -q "_log_bash_error"; then
  echo "ERROR: ERR trap not active - error logging will fail" >&2
  exit 1
fi
```

**Pattern Documentation** (in error-handling.md, if not exists):
- Dual trap setup pattern explanation
- When to use early vs late trap
- How to choose placeholder values for early trap
- Why pre-trap buffering is important

## Dependencies

### External Dependencies
- error-handling.sh library (already sourced)
- grep command (trap validation)
- date command (early workflow ID generation)

### Internal Dependencies
- None (changes are isolated to /todo command)

### Blocking Issues
- None identified

## Complexity Calculation

```
Score = Base(enhance) + Tasks/2 + Files*3 + Integrations*5
Score = 7 + 11/2 + 1*3 + 0*5
Score = 7 + 5.5 + 3 + 0
Score = 15.5

Tier Selection: Score <50 → Tier 1 (single file)
```

**Rationale**: This is an enhancement to existing error logging infrastructure with 11 specific implementation tasks, modifying 1 file (/todo command), and no external integrations. Complexity is low-medium, suitable for single-file plan structure.
