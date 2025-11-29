# Error Capture Trap Timing Implementation Plan

## Metadata
- **Date**: 2025-11-27
- **Feature**: Comprehensive Error Capture for Bash Error Trap Timing Gaps
- **Scope**: Fix all timing gaps where errors escape logging across ALL commands (/plan, /build, /debug, /research, /revise, /errors, /repair)
- **Estimated Phases**: 7
- **Estimated Hours**: 24
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 68.5
- **Research Reports**:
  - [Error Capture Trap Timing Analysis](/home/benjamin/.config/.claude/specs/955_error_capture_trap_timing/reports/001-error-capture-analysis.md)
  - [Command Error Capture Gap Analysis](/home/benjamin/.config/.claude/specs/955_error_capture_trap_timing/reports/002-command-error-capture-comparison.md)

## Overview

The /errors command failed to capture a critical "FEATURE_DESCRIPTION: unbound variable" error because it occurred in a timing gap before the bash error trap was fully initialized. Analysis of all 7 commands (/plan, /build, /debug, /research, /revise, /errors, /repair) reveals that every command shares identical error capture gaps because they use copy-pasted error trap initialization patterns.

This plan addresses five critical failure points identified across ALL commands:

1. **Before error-handling.sh is sourced** - No trap capability exists (17-21 line gap in all commands)
2. **Before setup_bash_error_trap is called** - Functions available but trap not set (49-105 line gap in /debug and /errors)
3. **During state file sourcing** - set +u/set -u transitions lose error context (40-68 line gap across all Block 2+ sections)
4. **During library function validation** - Benign filtering masks real failures (affects 6/7 commands)
5. **Between bash blocks** - Trap metadata becomes stale, WORKFLOW_ID mismatch (3-6 vulnerability windows per command)

The implementation will create reusable library functions that all commands can use, ensuring errors are captured in errors.jsonl regardless of timing, with comprehensive testing across all command templates.

## Research Summary

Key findings from comprehensive command analysis across all 7 commands:

**Five Critical Failure Modes (Universal Across ALL Commands)**:
- **Failure Mode 1**: Library sourcing errors before trap exists (17-21 line gaps across all commands)
- **Failure Mode 2**: Early trap with stale metadata or NO early trap (105-line gap in /errors, 49-line gap in /debug)
- **Failure Mode 3**: Unbound variables during state restoration (40-68 line gaps in Block 2+ across all commands)
- **Failure Mode 4**: Function-not-found errors filtered as benign (affects 6/7 commands using validate_library_functions)
- **Failure Mode 5**: Trap not re-set between bash blocks (1-5 vulnerability windows per command)

**Root Causes (Systemic Copy-Paste Pattern)**:
- Error trap uses string interpolation at SET time, not EXECUTION time (metadata baked in)
- Library sourcing uses `2>/dev/null` suppression across all commands, hiding syntax/permission errors
- Benign error filtering too aggressive in error-handling.sh (filters ALL returns from /lib/ directories)
- State restoration happens BEFORE trap re-set in Block 2+ (40-68 lines unprotected per command)
- No validation that WORKFLOW_ID was successfully restored between blocks
- Identical vulnerability pattern copy-pasted to all 7 commands

**Commands Affected**:
- `/plan` - 3 blocks, 68-line Block 2 gap (most frequently used)
- `/build` - 4 blocks, 62-line Block 2 gap
- `/debug` - 6 blocks, 40-line Block 2 gap, NO early trap (49-line gap!)
- `/research` - 2 blocks, 59-line Block 2 gap
- `/revise` - 4+ blocks, 40-line Block 2 gap
- `/errors` - 2 blocks, NO early trap (105-line gap!), ironically most vulnerable
- `/repair` - 3+ blocks

**Recommended Solutions** (7 recommendations, now applied universally):
1. Pre-trap error buffering library functions (reusable across all commands)
2. Remove overly aggressive benign filtering in error-handling.sh (single fix affects all commands)
3. Add state restoration validation with defensive trap setup (template pattern for all commands)
4. Create _source_with_diagnostics helper function (replaces 2>/dev/null in all commands)
5. Implement workflow ID validation and fallback (template pattern for all Block 2+ sections)
6. Add block boundary markers for observability (optional enhancement)
7. Create comprehensive error trap test suite covering all commands

## Success Criteria

**Library Function Success**:
- [ ] Pre-trap error buffer functions (_buffer_early_error, _flush_early_errors) implemented in error-handling.sh
- [ ] Defensive trap setup functions implemented for Block 2+ initialization
- [ ] _source_with_diagnostics helper function replaces all `2>/dev/null` suppression
- [ ] Benign error filtering refined to whitelist-only approach in error-handling.sh
- [ ] Workflow ID validation functions implemented in state-persistence.sh

**Multi-Command Coverage Success**:
- [ ] All 7 commands updated with new error capture patterns (/plan, /build, /debug, /research, /revise, /errors, /repair)
- [ ] Block 1 early trap added to /debug and /errors (currently missing)
- [ ] Block 2+ defensive trap pattern applied to all multi-block commands
- [ ] Library sourcing uses _source_with_diagnostics in all commands
- [ ] State restoration uses defensive initialization in all commands with Block 2+

**Error Capture Success**:
- [ ] All library sourcing errors captured in errors.jsonl (even before trap fully initialized)
- [ ] Unbound variable errors during state restoration captured with correct context
- [ ] Library validation failures (validate_library_functions) logged, not filtered as benign
- [ ] Errors between bash blocks captured with correct workflow metadata
- [ ] WORKFLOW_ID corruption/loss detected and recovered with fallback IDs
- [ ] No errors.jsonl entries with workflow_id="unknown" for recoverable failures

**Testing Success**:
- [ ] Test suite validates all 5 failure modes across all 7 commands
- [ ] Integration test reproduces original FEATURE_DESCRIPTION error and verifies capture
- [ ] Per-command error capture tests pass for all 7 commands
- [ ] Regression tests confirm no existing error capture breaks

## Technical Design

### Architecture Overview

**Three-Layer Error Capture Strategy**:

**Layer 1: Pre-Trap Error Buffering**
- Array-based error buffer created at TOP of every bash block (before any sourcing)
- `_buffer_early_error()` function captures errors with timestamp, line, code, message
- `_flush_early_errors()` transfers buffered errors to errors.jsonl after trap initialized
- Solves: Failure Modes 1, 5 (errors before trap exists or between blocks)

**Layer 2: Defensive Trap Setup**
- Minimal ERR/EXIT traps set BEFORE library sourcing in Block 2+
- Print diagnostic messages to stderr (visible even if logging fails)
- Full trap re-set AFTER library sourcing and state restoration
- Solves: Failure Mode 5 (68-line vulnerability window in Block 2)

**Layer 3: Enhanced Benign Filtering**
- Replace blanket filtering of library return statements
- Whitelist SPECIFIC safe functions (classify_error, suggest_recovery, etc.)
- Log validation failures (validate_library_functions returns)
- Solves: Failure Mode 4 (validation errors masked)

### Component Interactions

```
Bash Block Start
    ↓
[Pre-Trap Buffer] ← _buffer_early_error() stores errors
    ↓
Source Libraries (with enhanced diagnostics)
    ↓
[Defensive Trap] ← Minimal trap active during sourcing
    ↓
Load/Restore State (with validation)
    ↓
[Full Trap Setup] ← setup_bash_error_trap with validated metadata
    ↓
[Flush Buffer] ← Transfer early errors to errors.jsonl
    ↓
Execute Command Logic
```

### State Flow Between Blocks

**Block 1 (Initialization)**:
1. Pre-trap buffer created
2. Libraries sourced (errors buffered)
3. Early trap set (temporary metadata)
4. WORKFLOW_ID created and persisted to STATE_ID_FILE
5. Full trap set (real metadata)
6. Buffer flushed to errors.jsonl

**Block 2+ (State Restoration)**:
1. Pre-trap buffer created
2. Defensive trap set (minimal, before sourcing)
3. Libraries sourced (defensive trap active)
4. State restoration with validation (WORKFLOW_ID, COMMAND_NAME, etc.)
5. WORKFLOW_ID validated (format check, fallback generation if corrupt)
6. Full trap set with restored metadata
7. Buffer flushed to errors.jsonl

### Metadata Validation

**WORKFLOW_ID Validation Pattern**:
```bash
# Read from state file
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

# Validate format (e.g., plan_1234567890)
if ! [[ "$WORKFLOW_ID" =~ ^[a-z_]+_[0-9]+$ ]]; then
  WORKFLOW_ID="${COMMAND_NAME}_$(date +%s)_recovered"
  log_early_error "Invalid workflow ID" "{...}"
fi
```

**State Restoration Validation**:
```bash
validate_state_restoration() {
  local required_vars=("$@")
  local missing=()

  for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
      missing+=("$var")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    echo "ERROR: State restoration incomplete: ${missing[*]}" >&2
    return 1
  fi
  return 0
}
```

## Implementation Phases

### Phase 1: Create Pre-Trap Error Buffering Infrastructure [COMPLETE]
dependencies: []

**Objective**: Implement early error buffering that captures errors BEFORE error-handling.sh is available

**Complexity**: Medium

Tasks:
- [x] Create `_buffer_early_error()` function in error-handling.sh (lib/core/error-handling.sh:~100)
- [x] Create `_flush_early_errors()` function in error-handling.sh (lib/core/error-handling.sh:~150)
- [x] Add `declare -a _EARLY_ERROR_BUFFER=()` to top of error-handling.sh (line ~10)
- [x] Implement buffer entry format: "timestamp|line|code|message" (ISO8601 timestamp)
- [x] Implement buffer flush to log_command_error with "initialization_error" type
- [x] Add buffer size limit (max 100 entries to prevent memory issues)
- [x] Test buffer functions in isolation (unit tests)

Testing:
```bash
# Unit test for buffer functions
bash .claude/tests/unit/test_error_buffer.sh

# Verify buffer captures errors before trap
bash .claude/tests/integration/test_pre_trap_errors.sh
```

**Expected Duration**: 3 hours

### Phase 2: Implement Defensive Trap Setup Pattern [COMPLETE]
dependencies: [1]

**Objective**: Add minimal traps BEFORE library sourcing in all bash blocks to catch sourcing failures

**Complexity**: Medium

Tasks:
- [x] Create `_setup_defensive_trap()` function in error-handling.sh (lib/core/error-handling.sh:~200)
- [x] Implement minimal ERR trap: `trap 'echo "ERROR: Library sourcing failed at line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR`
- [x] Implement minimal EXIT trap: `trap 'if [ $? -ne 0 ]; then echo "ERROR: Block initialization failed" >&2; fi' EXIT`
- [x] Create `_clear_defensive_trap()` function to remove minimal traps before full trap setup
- [x] Document defensive trap pattern in error-handling.sh header comments
- [x] Add inline examples showing when to use defensive traps

Testing:
```bash
# Test defensive trap catches sourcing errors
bash .claude/tests/integration/test_defensive_trap_sourcing.sh

# Verify defensive trap doesn't interfere with full trap
bash .claude/tests/integration/test_trap_transition.sh
```

**Expected Duration**: 2 hours

### Phase 3: Refine Benign Error Filtering [COMPLETE]
dependencies: [1]

**Objective**: Remove overly aggressive benign filtering to ensure validation failures are logged

**Complexity**: Low

Tasks:
- [x] Modify `_is_benign_bash_error()` in error-handling.sh (lines 1626-1644)
- [x] Replace blanket filtering of library return statements with whitelist approach
- [x] Create whitelist of safe functions: classify_error, suggest_recovery, detect_error_type, extract_location
- [x] Extract caller function name: `local caller_func=$(caller 1 | awk '{print $2}')`
- [x] Log non-whitelisted library returns (validate_library_functions failures now logged)
- [x] Update error-handling.sh documentation to explain new filtering logic
- [x] Add comment explaining why specific functions are whitelisted

Testing:
```bash
# Test validation failures are now logged
bash .claude/tests/integration/test_validation_error_logging.sh

# Test whitelisted functions still filtered correctly
bash .claude/tests/integration/test_benign_filter_whitelist.sh
```

**Expected Duration**: 2 hours

### Phase 4: Enhance Library Sourcing Diagnostics [COMPLETE]
dependencies: [2]

**Objective**: Replace `2>/dev/null` suppression with diagnostic wrapper that captures and reports sourcing errors

**Complexity**: Medium

Tasks:
- [x] Create `_source_with_diagnostics()` function in error-handling.sh (lib/core/error-handling.sh:~250)
- [x] Capture stderr to temporary file during sourcing
- [x] Report sourcing errors with full context (path, exit code, stderr output)
- [x] Buffer sourcing errors using `_buffer_early_error()` (trap may not exist yet)
- [x] Clean up temporary stderr files after sourcing
- [x] Add sourcing error examples to error-handling.sh documentation
- [x] Update all commands to use `_source_with_diagnostics()` wrapper (Phase 5 task)

Testing:
```bash
# Test sourcing diagnostics capture syntax errors
bash .claude/tests/integration/test_sourcing_syntax_error.sh

# Test sourcing diagnostics capture permission errors
bash .claude/tests/integration/test_sourcing_permission_error.sh

# Test sourcing diagnostics capture file-not-found errors
bash .claude/tests/integration/test_sourcing_not_found.sh
```

**Expected Duration**: 3 hours

### Phase 5: Implement Workflow ID Validation and State Restoration Checks [COMPLETE]
dependencies: [1, 3]

**Objective**: Validate WORKFLOW_ID format and implement fallback generation to prevent metadata loss

**Complexity**: Medium

Tasks:
- [x] Create `validate_workflow_id()` function in state-persistence.sh (lib/core/state-persistence.sh:~100)
- [x] Implement format validation regex: `^[a-z_]+_[0-9]+$`
- [x] Generate fallback WORKFLOW_ID on validation failure: `${COMMAND_NAME}_$(date +%s)_recovered`
- [x] Log validation failures using `log_early_error()` (before full trap active)
- [x] Create `validate_state_restoration()` function in state-persistence.sh (lib/core/state-persistence.sh:~150)
- [x] Check required variables exist after load_workflow_state: COMMAND_NAME, WORKFLOW_ID, STATE_FILE
- [x] Report missing variables with descriptive error messages
- [x] Update state-persistence.sh documentation with validation requirements

Testing:
```bash
# Test WORKFLOW_ID validation detects invalid formats
bash .claude/tests/unit/test_workflow_id_validation.sh

# Test fallback generation works correctly
bash .claude/tests/integration/test_workflow_id_fallback.sh

# Test state restoration validation detects missing variables
bash .claude/tests/integration/test_state_restoration_validation.sh
```

**Expected Duration**: 3 hours

### Phase 6: Apply Error Capture Fixes to /plan and /research Commands [COMPLETE]
dependencies: [1, 2, 3, 4, 5]

**Objective**: Update /plan and /research commands as pilot implementation, validate pattern works

**Complexity**: Medium

Tasks:
- [x] Update /plan.md Block 1 (lines 118-176):
  - [x] Add pre-trap buffer initialization at top: `declare -a _EARLY_ERROR_BUFFER=()`
  - [x] Replace library sourcing (lines 120-135) with `_source_with_diagnostics()` wrapper
  - [x] Keep early trap at line 159 (already exists)
  - [x] Add buffer flush after full trap setup: `_flush_early_errors()`
- [x] Update /plan.md Block 2 (lines 610-679):
  - [x] Add defensive trap before library sourcing (line 610)
  - [x] Replace library sourcing with `_source_with_diagnostics()` wrapper
  - [x] Add WORKFLOW_ID validation after STATE_ID_FILE read
  - [x] Add state restoration validation after load_workflow_state
  - [x] Re-set trap with restored metadata AFTER state restoration
- [x] Update /research.md Block 1 (lines 119-152) with same Block 1 pattern
- [x] Update /research.md Block 2 (lines 475-534) with same Block 2 pattern
- [x] Document changes inline (explain new error capture approach)

Testing:
```bash
# Test pilot commands capture errors in all timing windows
bash .claude/tests/commands/test_plan_error_capture.sh
bash .claude/tests/commands/test_research_error_capture.sh

# Integration test: Reproduce original FEATURE_DESCRIPTION error
bash .claude/tests/integration/test_feature_description_error.sh
```

**Expected Duration**: 3 hours

### Phase 7: Apply Error Capture Fixes to Remaining Commands [COMPLETE]
dependencies: [6]

**Objective**: Roll out validated pattern to remaining 5 commands

**Complexity**: High

Tasks:
- [x] Update /build.md (4 blocks):
  - [x] Block 1 (lines 76-100): Add pre-trap buffer, _source_with_diagnostics, buffer flush
  - [x] Block 1c/2/3 (multiple Block 2+ sections): Add defensive trap, validation, trap re-set
- [x] Update /debug.md (6 blocks, NO early trap currently):
  - [x] Block 1 (lines 190-252): Add early trap at line ~220 (CRITICAL FIX)
  - [x] Block 1 (lines 190-203): Add pre-trap buffer, _source_with_diagnostics
  - [x] Blocks 2-6: Add defensive trap pattern to all subsequent blocks
- [x] Update /revise.md (4+ blocks):
  - [x] Block 1 (lines 276-293): Add pre-trap buffer, _source_with_diagnostics
  - [x] Block 4a (lines 392-432): Add defensive trap, validation
- [x] Update /errors.md (2 blocks, NO early trap currently):
  - [x] Block 1 (lines 171-281): Add early trap at line ~200 (CRITICAL FIX - 105-line gap!)
  - [x] Block 1: Add pre-trap buffer, _source_with_diagnostics
  - [x] Block 2: Add defensive trap pattern
- [x] Update /repair.md (3+ blocks):
  - [x] Block 1 (lines 142-177): Add pre-trap buffer, _source_with_diagnostics
  - [x] Block 2+ sections: Add defensive trap pattern
- [x] Create command update summary document listing all changes
- [x] Update command documentation headers explaining error capture enhancements

Testing:
```bash
# Test each command captures errors in all timing windows
bash .claude/tests/commands/test_build_error_capture.sh
bash .claude/tests/commands/test_debug_error_capture.sh
bash .claude/tests/commands/test_revise_error_capture.sh
bash .claude/tests/commands/test_errors_error_capture.sh
bash .claude/tests/commands/test_repair_error_capture.sh

# Full suite regression test
bash .claude/tests/integration/test_all_commands_error_capture.sh
```

**Expected Duration**: 6 hours

## Testing Strategy

### Unit Tests
- Pre-trap buffer functions (_buffer_early_error, _flush_early_errors)
- Workflow ID validation (validate_workflow_id)
- State restoration validation (validate_state_restoration)
- Benign error filtering whitelist logic
- _source_with_diagnostics helper function

### Integration Tests (Per Failure Mode)
- **Failure Mode 1**: Error capture before trap initialization (library sourcing errors)
- **Failure Mode 2**: Early trap metadata staleness (errors logged with wrong workflow_id)
- **Failure Mode 3**: Error capture during state restoration (unbound variables)
- **Failure Mode 4**: Validation error logging (validate_library_functions failures)
- **Failure Mode 5**: Trap metadata refresh between blocks (workflow_id consistency)

### Per-Command Integration Tests
- `/plan` - Test all 5 failure modes across 3 blocks
- `/build` - Test all 5 failure modes across 4 blocks
- `/debug` - Test all 5 failure modes across 6 blocks (verify early trap added)
- `/research` - Test all 5 failure modes across 2 blocks
- `/revise` - Test all 5 failure modes across 4+ blocks
- `/errors` - Test all 5 failure modes across 2 blocks (verify early trap added)
- `/repair` - Test all 5 failure modes across 3+ blocks

### Regression Tests
- Reproduce original FEATURE_DESCRIPTION unbound variable error
- Verify error appears in errors.jsonl with correct metadata
- Confirm workflow_id is NOT "unknown" for recoverable failures
- Validate error context (line number, command) is accurate
- Verify existing error logging continues to work (no breakage)

### Test Coverage Requirements
- All 5 failure modes must have dedicated test coverage FOR EACH COMMAND
- All new functions (buffer, validation, diagnostics) must have unit tests
- All 7 modified commands must have integration tests
- Minimum 90% code coverage for error-handling.sh changes
- Full regression suite passes (existing error capture not broken)

## Documentation Requirements

### Update Existing Documentation
- [ ] Update /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md with new error capture patterns
- [ ] Add "Pre-Trap Error Buffering" section explaining buffer workflow and universal applicability
- [ ] Add "Defensive Trap Setup" section with Block 2+ pattern for all commands
- [ ] Add "Workflow ID Validation" section with format requirements
- [ ] Add "Multi-Command Error Capture" section explaining systemic fix approach
- [ ] Update error-handling.sh inline comments with new function documentation
- [ ] Update state-persistence.sh inline comments for validation functions

### Create New Documentation
- [ ] Create troubleshooting guide for error capture gaps (docs/troubleshooting/error-capture-gaps.md)
- [ ] Document all 5 failure modes with examples from each command
- [ ] Create decision tree for choosing error capture strategy
- [ ] Create command update summary (specs/955_*/summaries/command-changes-summary.md)
  - [ ] List all changes per command
  - [ ] Include before/after line number comparisons
  - [ ] Document critical fixes (/debug early trap, /errors early trap)

### Update Standards
- [ ] Update Code Standards to require pre-trap buffering in all bash blocks across all commands
- [ ] Add requirement for defensive trap setup in Block 2+ for all multi-block commands
- [ ] Add requirement for WORKFLOW_ID validation after state restoration in all commands
- [ ] Mandate _source_with_diagnostics usage instead of `2>/dev/null` suppression
- [ ] Add command template standards documenting required error capture patterns

## Dependencies

### External Dependencies
- error-handling.sh library (will be modified with new functions)
- state-persistence.sh library (will be modified with validation functions)
- All 7 command templates (will be updated to use new infrastructure):
  - /plan.md (pilot command, updated in Phase 6)
  - /research.md (pilot command, updated in Phase 6)
  - /build.md (updated in Phase 7)
  - /debug.md (updated in Phase 7, requires early trap addition)
  - /revise.md (updated in Phase 7)
  - /errors.md (updated in Phase 7, requires early trap addition - CRITICAL)
  - /repair.md (updated in Phase 7)

### Prerequisites
- Existing error logging infrastructure must remain functional during changes
- Backward compatibility: Old error log entries must remain parseable
- No breaking changes to log_command_error() function signature
- Phased rollout: Pilot commands (/plan, /research) validated before remaining commands
- Test suite must validate each command individually and collectively

### Integration Points
- /errors command (must continue to parse new error log entries, including new error types)
- /repair command (must handle new error types: initialization_error, validation_error, state_restoration_error)
- Test suite validation scripts (must validate new error patterns across all commands)
- Command templates (all 7 commands share identical error capture infrastructure)

## Risk Management

### Technical Risks

**Risk 1: Pre-Trap Buffer Memory Overhead**
- **Impact**: High error volume could exhaust buffer memory
- **Mitigation**: Implement 100-entry buffer limit with overflow warning
- **Rollback**: Remove buffer if memory issues occur, revert to trap-only approach

**Risk 2: Defensive Trap Interference**
- **Impact**: Minimal trap could interfere with full trap setup
- **Mitigation**: Test trap transition thoroughly, clear defensive trap before full setup
- **Rollback**: Remove defensive trap if conflicts occur

**Risk 3: Workflow ID Validation False Positives**
- **Impact**: Valid IDs rejected by regex, unnecessary fallback generation
- **Mitigation**: Test regex against real workflow ID patterns, allow broader format if needed
- **Rollback**: Relax validation regex if too restrictive

**Risk 4: Library Sourcing Diagnostic Overhead**
- **Impact**: Temporary file creation slows down command initialization
- **Mitigation**: Use mktemp for efficient temporary file handling, clean up immediately
- **Rollback**: Revert to 2>/dev/null if performance degrades significantly

### Deployment Strategy

**Phase 1-3 (Low Risk)**:
- Deploy to error-handling.sh library (buffer functions, benign filtering)
- Test in isolation before command updates
- No user-facing changes yet
- Rollback: Revert error-handling.sh if functions broken

**Phase 4-5 (Medium Risk)**:
- Deploy state-persistence.sh changes (validation functions)
- Deploy _source_with_diagnostics helper function
- Test with mock commands in isolation
- Monitor error logs for new patterns
- Rollback: Revert library changes if validation breaks

**Phase 6 (Medium Risk - Pilot Commands)**:
- Deploy /plan and /research updates (2 commands)
- Validate pattern works correctly in production commands
- Monitor errors.jsonl for new error types
- Collect feedback from test suite
- Rollback: Revert only /plan and /research if issues found

**Phase 7 (High Risk - Full Rollout)**:
- Deploy remaining 5 commands incrementally (1-2 per deployment)
- Priority order:
  1. /errors (CRITICAL - ironically most vulnerable)
  2. /debug (CRITICAL - missing early trap)
  3. /build (high usage)
  4. /repair (medium usage)
  5. /revise (medium usage)
- Monitor errors.jsonl for unexpected entries after each deployment
- Keep rollback commits ready for each command
- Pause rollout if any command shows issues

**Rollback Triggers**:
- Existing error capture breaks (regression test failures)
- New error capture causes command failures
- Performance degradation > 10% (library sourcing overhead)
- errors.jsonl corruption or format issues

## Notes

### Key Implementation Insights

**Why Pre-Trap Buffering Instead of Earlier Trap Setup?**
- Can't set trap before error-handling.sh is sourced (trap handler functions don't exist)
- Buffering is the ONLY way to capture errors in lines 1-135 of bash blocks across all commands
- Buffer flush transfers errors to proper logging infrastructure once available
- Universal solution: Same code works for all 7 commands

**Why Defensive Trap Only in Block 2+?**
- Block 1 has early trap at line ~159 in most commands (covers most initialization)
- Exception: /debug and /errors have NO early trap (49-105 line gaps!)
- Block 2+ starts with NEW bash environment (trap NOT inherited)
- 40-68 line windows (varies by command) are unprotected without defensive trap
- All multi-block commands need defensive trap pattern

**Why Whitelist for Benign Filtering?**
- Blacklist approach ("filter ALL library returns") was too aggressive across all commands
- Whitelist approach ("filter ONLY known-safe functions") is more conservative
- Validation failures are real errors, not benign conditions
- Single fix in error-handling.sh affects all 7 commands (systemic improvement)

**Why WORKFLOW_ID Validation Required?**
- STATE_ID_FILE can be corrupted, deleted, or have permissions changed
- Empty WORKFLOW_ID causes errors to be logged as workflow_id="unknown"
- Makes errors unsearchable via `/errors --workflow-id`
- Fallback generation preserves searchability even when state file corrupted
- Pattern applies to all commands with Block 2+ (6 out of 7 commands)

**Why Phased Rollout (Pilot + Full)?**
- Commands share identical error capture code (copy-paste pattern)
- Validating pattern with 2 commands (/plan, /research) proves it works
- Reduces risk of breaking all 7 commands simultaneously
- Allows testing multi-block patterns (both commands have Block 2)
- Critical commands (/errors, /debug) deployed first in Phase 7 due to missing early traps

### Testing Priorities

**Critical Tests** (Must Pass for Deployment):
1. Original FEATURE_DESCRIPTION error now captured (reproduction test in /plan)
2. All 5 failure modes covered by dedicated tests for EACH command
3. No workflow_id="unknown" entries for recoverable failures across all commands
4. Error context (line number, command) accurate in all timing windows
5. Pilot commands (/plan, /research) pass all tests before Phase 7 rollout
6. Critical commands (/errors, /debug) early trap additions work correctly

**Important Tests** (Should Pass for Quality):
1. Library sourcing errors show full diagnostics (syntax error line, permission details)
2. Validation failures logged with correct error type in all 6 commands using validate_library_functions
3. Buffer overflow handled gracefully (warning logged, oldest entries preserved)
4. Trap transition (defensive → full) doesn't lose errors across all multi-block commands
5. WORKFLOW_ID validation and fallback work across all Block 2+ commands

**Nice-to-Have Tests** (Improve Confidence):
1. Block boundary markers visible in logs for all commands
2. Error log analysis correlates errors with bash blocks per command
3. Performance benchmarks (ensure no significant slowdown across 7 commands)
4. Command-specific edge cases (e.g., /debug with 6 blocks, /errors with 2 blocks)

### Expansion Hint

This plan has a complexity score of 68.5 (Medium-High complexity). If implementation becomes more complex than expected during Phase 6 (pilot commands) or Phase 7 (full rollout), consider:

**Phase 6 Expansion**: Use `/expand phase 6` to break /plan and /research updates into separate stages (one per command)

**Phase 7 Expansion**: Use `/expand phase 7` to break the 5-command rollout into individual stages:
- Stage 1: /errors command update (CRITICAL - most vulnerable)
- Stage 2: /debug command update (CRITICAL - 6 blocks)
- Stage 3: /build command update (4 blocks)
- Stage 4: /repair command update (3+ blocks)
- Stage 5: /revise command update (4+ blocks)

This allows more granular tracking and easier rollback if issues arise with specific commands.
