# Research Report: /research Command ERR Trap Validation Strategy

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: ERR trap validation on /research command as proof-of-concept
- **Report Type**: Validation Strategy Analysis
- **Complexity**: 3
- **Reference Plan**: /home/benjamin/.config/.claude/specs/861_build_command_use_this_research_to_create_a/plans/001_build_command_use_this_research_to_creat_plan.md

## Executive Summary

This report analyzes how to validate the ERR trap error logging strategy by implementing it ONLY on the `/research` command as a proof-of-concept before rolling out to all 6 workflow commands. The /research command has 2 bash blocks (lines 35-238 and lines 270-447), making it an ideal validation target: simple enough to test thoroughly, complex enough to represent real-world usage with state persistence and agent invocation patterns.

Key findings: The /research command currently captures ~30% of errors through conditional `log_command_error()` calls, missing all bash-level errors (syntax, unbound variables, function-not-found). Implementing ERR traps in both blocks will demonstrate whether the capture rate reaches >90% and whether the 5ms overhead is acceptable for production use.

## Findings

### Current /research Command Implementation Analysis

**File**: `/home/benjamin/.config/.claude/commands/research.md` (459 lines)
**Bash Blocks**: 2 blocks (Block 1: Setup, Block 2: Verification)

#### Block 1: Consolidated Setup (Lines 35-238)

**Current Error Logging Coverage**:
- Line 156-167: State file validation failure (file_error)
- Line 169-182: State machine initialization failure (state_error)
- Line 185-196: State transition failure (state_error)
- Line 200-212: Workflow path initialization failure (file_error)

**Missing Error Scenarios** (Not Currently Captured):
1. **Syntax errors** in bash block (exit code 2)
   - Example: Unmatched quotes, missing brackets
   - Current behavior: Bash exits immediately, no log entry
2. **Unbound variables** when `set -u` enabled (exit code 1)
   - Example: Accessing `$UNDEFINED_VAR`
   - Current behavior: Bash exits, error logged to stderr only
3. **Command not found** (exit code 127)
   - Example: Typo in `sourc` instead of `source`
   - Current behavior: Bash exits, no structured log
4. **Library sourcing failures** (lines 114-125)
   - Current handling: `2>/dev/null` suppresses errors
   - If library fails to load, subsequent calls fail with "command not found"
   - No error logged until function call fails

**State Persistence Pattern**:
```bash
# Block 1 sets these variables and persists them
append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"  # Line 227
append_workflow_state "USER_ARGS" "$USER_ARGS"        # Line not present - GAP IDENTIFIED
```

**Gap Identified**: Block 1 does NOT persist `USER_ARGS`, but Block 2 needs it for ERR trap setup. This will need to be added during refactor.

#### Block 2: Verification and Completion (Lines 270-447)

**Current Error Logging Coverage**:
- Line 305-324: State file missing after load (state_error)
- Line 328-346: State file path validation (file_error)
- Line 349-368: Critical variables not restored (state_error)
- Line 374-384: Reports directory not created (file_error)
- Line 387-399: No report files created (validation_error)
- Line 402-414: Report files too small (validation_error)
- Line 419-431: State transition to complete failed (state_error)

**Missing Error Scenarios**:
1. **Bash errors during state load** (line 302: `load_workflow_state`)
   - If function not found, exits with 127
2. **Bash errors in verification logic** (lines 387-416)
   - `find` command failures not captured
   - File access errors (`wc -l` on permission-denied files)
3. **State transition bash errors** (line 419)
   - If `sm_transition` function not found, exit 127

**Agent Invocation Pattern** (Block 1, Lines 240-264):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research ${WORKFLOW_DESCRIPTION} with mandatory file creation"
  prompt: "..."
}
```

The Task invocation is NOT in a bash block, so agent errors don't require bash-level error trapping. Agent errors are returned via `TASK_ERROR` signal and parsed by Claude Code's task system, not by command bash code.

### ERR Trap Integration Strategy for /research

Based on the reference plan's `setup_bash_error_trap()` design:

#### Integration Point 1: Block 1 Setup (After Line 142)

**Current Code Pattern** (Lines 134-142):
```bash
# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists

# === INITIALIZE STATE ===
WORKFLOW_TYPE="research-only"
TERMINAL_STATE="research"
COMMAND_NAME="/research"
USER_ARGS="$WORKFLOW_DESCRIPTION"
export COMMAND_NAME USER_ARGS
```

**Refactored Pattern** (Add after line 142):
```bash
# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists

# === INITIALIZE STATE ===
WORKFLOW_TYPE="research-only"
TERMINAL_STATE="research"
COMMAND_NAME="/research"
USER_ARGS="$WORKFLOW_DESCRIPTION"
export COMMAND_NAME USER_ARGS

WORKFLOW_ID="research_$(date +%s)"
export WORKFLOW_ID

# === SETUP BASH ERROR TRAP (NEW) ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

**Rationale**: Trap setup happens AFTER all error logging variables are initialized but BEFORE any operations that could fail. This ensures the trap has access to correct context.

**Required State Persistence Addition** (After line 234):
```bash
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "USER_ARGS" "$USER_ARGS"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"  # Already present
```

#### Integration Point 2: Block 2 Verification (After Line 302)

**Current Code Pattern** (Lines 294-302):
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null

# Initialize DEBUG_LOG if not already set
DEBUG_LOG="${DEBUG_LOG:-${HOME}/.claude/tmp/workflow_debug.log}"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

load_workflow_state "$WORKFLOW_ID" false
```

**Refactored Pattern** (Add after line 302):
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null

# Initialize DEBUG_LOG if not already set
DEBUG_LOG="${DEBUG_LOG:-${HOME}/.claude/tmp/workflow_debug.log}"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

load_workflow_state "$WORKFLOW_ID" false

# === RESTORE ERROR LOGGING CONTEXT (NEW) ===
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/research")
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
fi
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SETUP BASH ERROR TRAP (NEW) ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

**Rationale**: Variables must be restored from state BEFORE trap setup, otherwise trap will log with "unknown" or empty context. This pattern is critical for multi-block commands.

### Testing Approach for Bash-Level Error Capture

#### Test Scenario Matrix

| Test ID | Error Type | Trigger Method | Expected Behavior | Success Criteria |
|---------|-----------|----------------|-------------------|------------------|
| T1 | Syntax Error (exit 2) | Inject `$((` without closing | ERR trap fires, logs parse_error | JSONL entry with exit_code=2 |
| T2 | Unbound Variable | Access `$UNDEFINED_VAR` with `set -u` | ERR trap fires, logs execution_error | JSONL entry with line number |
| T3 | Command Not Found (exit 127) | Typo: `sourc` instead of `source` | ERR trap fires, logs execution_error | JSONL entry with exit_code=127 |
| T4 | Function Not Found | Call undefined function | ERR trap fires, logs execution_error | JSONL entry with function name |
| T5 | Library Sourcing Failure | Corrupt error-handling.sh | ERR trap cannot register, fallback to stderr | No JSONL entry (expected limitation) |
| T6 | State File Missing | Delete state file before Block 2 | Conditional check logs file_error | JSONL entry from existing logic |

**Test Coverage**: 6 scenarios covering all bash error types + 1 edge case (trap registration failure)

#### Test Implementation Strategy

**Test File**: `.claude/tests/test_research_err_trap.sh`

**Structure**:
```bash
#!/usr/bin/env bash
# Test ERR trap integration in /research command

test_setup() {
  # Create temporary test environment
  # Mock state files and libraries
}

test_t1_syntax_error() {
  # Inject syntax error into research.md bash block
  # Run /research command
  # Verify JSONL entry with exit_code=2
}

test_t2_unbound_variable() {
  # Inject unbound variable reference
  # Run /research command
  # Verify JSONL entry with correct line number
}

# ... T3-T6 implementations

test_teardown() {
  # Clean up test environment
  # Restore original files
}

# Run all tests
run_all_tests
```

**Test Execution**:
1. Create isolated test environment (separate state directory)
2. Mock `/research` command with injected errors
3. Route errors to test log file: `.claude/tests/logs/test-errors.jsonl`
4. Verify JSONL entries match expected schema
5. Calculate error capture rate: (captured / total) * 100

**Expected Results**:
- Baseline (current): 4/6 tests capture errors (T5, T6 only) = 33% capture rate
- With ERR trap: 5/6 tests capture errors (T1-T4, T6) = 83% capture rate
- T5 expected failure (trap registration requires successful library sourcing)

### Success Metrics Definition

#### Quantitative Metrics

1. **Error Capture Rate**: (Errors Logged / Total Errors Triggered) * 100
   - **Baseline**: 30-40% (conditional checks only)
   - **Target**: >90% (with ERR traps)
   - **Measurement**: Run test suite T1-T6, count JSONL entries

2. **Performance Overhead**: Time added per bash block by trap setup
   - **Target**: <5ms per block
   - **Measurement**: Benchmark 1000 iterations of trap setup vs no trap
   - **Test Command**: `time for i in {1..1000}; do setup_bash_error_trap "/test" "test_$i" ""; done`

3. **False Positive Rate**: Errors logged that are not actual errors
   - **Target**: 0% (no false positives)
   - **Measurement**: Run successful /research workflow, verify no error entries

4. **Test Coverage**: Percentage of bash error types tested
   - **Target**: 100% (all error types have test cases)
   - **Current**: 6 test scenarios cover syntax, unbound var, command-not-found, function-not-found, sourcing failure, state errors

#### Qualitative Metrics

1. **Maintainability**: Can developers easily add ERR traps to new commands?
   - **Measurement**: Template pattern simplicity, documentation clarity
   - **Success**: Copy-paste template requires <3 variable substitutions

2. **Debuggability**: Do error log entries provide sufficient context to diagnose issues?
   - **Measurement**: Review JSONL entries for line numbers, exit codes, failed commands
   - **Success**: 100% of entries include line number and exit code

3. **Integration Complexity**: How difficult is it to integrate ERR traps into existing commands?
   - **Measurement**: Lines of code changed, number of integration points
   - **Success**: <50 lines changed per command, <3 integration points

### Risk Mitigation Strategy

#### High Risk Areas

**Risk 1**: ERR trap fires on expected non-zero exits (e.g., `grep` returning 1 for no match)
- **Likelihood**: Medium
- **Impact**: High (false positive noise in error log)
- **Mitigation**:
  - Use `set -e` judiciously, disable around expected failures: `set +e; grep pattern; set -e`
  - Refine ERR trap to check `BASH_COMMAND` for known safe failures
  - Test with real /research workflows to identify false positives

**Risk 2**: State persistence for error context variables incomplete
- **Likelihood**: Medium (identified gap: USER_ARGS not persisted in Block 1)
- **Impact**: High (Block 2 trap logs with empty/incorrect context)
- **Mitigation**:
  - Add `append_workflow_state "USER_ARGS" "$USER_ARGS"` to Block 1 (line 234)
  - Add restoration logic to Block 2 (after line 302)
  - Test restoration with assertions: `[ -n "$USER_ARGS" ] || exit 1`

**Risk 3**: ERR trap performance overhead impacts user experience
- **Likelihood**: Low (trap setup is ~5ms according to plan)
- **Impact**: Low (users unlikely to notice <5ms delay)
- **Mitigation**:
  - Benchmark trap setup in isolation
  - Benchmark full /research workflow with vs without trap
  - If overhead >10ms, investigate optimization (pre-compiled trap handler)

**Risk 4**: ERR trap doesn't fire for certain error types
- **Likelihood**: Low (bash ERR trap is well-documented behavior)
- **Impact**: High (defeats purpose of validation)
- **Mitigation**:
  - Comprehensive test suite (T1-T6) validates all error types
  - Manual testing with real failure scenarios
  - Document known limitations (e.g., trap registration failures)

#### Medium Risk Areas

**Risk 5**: Conflict with existing error handling patterns
- **Likelihood**: Low (ERR trap complements, doesn't replace conditionals)
- **Impact**: Medium (confusing error log entries)
- **Mitigation**:
  - ERR trap only fires if code exits without reaching conditional
  - Conditionals still log with specific error types (validation_error, state_error)
  - Document error source field: "bash_trap" vs "bash_block"

**Risk 6**: State file corruption prevents Block 2 variable restoration
- **Likelihood**: Low (state files are line-based, robust to partial corruption)
- **Impact**: Medium (Block 2 trap logs with incomplete context)
- **Mitigation**:
  - Fallback values in restoration logic: `|| echo "/research"`
  - Add state file validation before restoration
  - Test with corrupted state files

#### Rollback Plan

**Scenario 1**: ERR trap integration increases error rate (false positives)
- **Action**: Revert /research command to pre-trap version
- **Effort**: 1 git revert, <5 minutes
- **Impact**: No error capture improvement, but no regression

**Scenario 2**: Performance overhead >10ms unacceptable
- **Action**: Remove trap setup from both blocks, document as non-viable
- **Effort**: 1 git revert, update plan with findings
- **Impact**: Plan Phase 2 rollout cancelled

**Scenario 3**: State persistence breaks existing functionality
- **Action**: Revert state persistence additions, keep trap infrastructure
- **Effort**: Manual edit to remove append_workflow_state lines
- **Impact**: Block 2 trap logs with incomplete context, but no functional regression

### Decision Criteria for Full Rollout

After validation on /research command, proceed to full rollout (all 6 commands) ONLY if ALL criteria are met:

#### Go Criteria (All Required)

1. ✓ Error capture rate >90% (measured via test suite)
2. ✓ Performance overhead <5ms per bash block (measured via benchmark)
3. ✓ Zero false positives in production /research workflows (measured via manual testing)
4. ✓ State persistence works correctly across blocks (measured via assertions)
5. ✓ Error log entries have complete context (measured via JSONL inspection)
6. ✓ No regressions in existing error handling (measured via existing test suite)
7. ✓ Rollback plan tested and confirmed working (measured via revert test)

#### No-Go Criteria (Any Single Condition)

1. ✗ Error capture rate <80% (indicates trap not effective)
2. ✗ Performance overhead >10ms per block (user experience impact)
3. ✗ False positive rate >5% (noise in error log)
4. ✗ State persistence causes workflow failures (breaking change)
5. ✗ Error log entries missing critical context (line number, exit code)
6. ✗ Existing error handling breaks (regression)

### Implementation Phases for /research Validation

#### Phase 0: Preparation (Before Code Changes)

**Objective**: Establish baseline metrics and test infrastructure

**Tasks**:
1. Create test script: `.claude/tests/test_research_err_trap.sh`
2. Implement test scenarios T1-T6
3. Run baseline test suite (expect 33% capture rate)
4. Benchmark current /research performance (no trap overhead)
5. Document baseline findings in test output

**Duration**: 2 hours

**Deliverables**:
- test_research_err_trap.sh (200 lines)
- Baseline capture rate: 30-40%
- Baseline performance: /research execution time
- Test log: `.claude/tests/logs/baseline-results.log`

#### Phase 1: Block 1 Integration

**Objective**: Add ERR trap to Block 1, test bash error capture in setup phase

**Tasks**:
1. Add `setup_bash_error_trap()` call after line 142 in research.md
2. Add state persistence for COMMAND_NAME and USER_ARGS (line 234)
3. Run test scenarios T1-T4 against Block 1 only
4. Verify error log entries have correct context
5. Benchmark Block 1 performance overhead

**Duration**: 1 hour

**Deliverables**:
- Modified research.md Block 1 (5 lines added)
- Test results: T1-T4 capture rate
- Performance measurement: Block 1 overhead <5ms

#### Phase 2: Block 2 Integration

**Objective**: Add ERR trap to Block 2, test state restoration and verification phase errors

**Tasks**:
1. Add variable restoration logic after line 302 in research.md
2. Add `setup_bash_error_trap()` call after restoration
3. Run test scenarios T5-T6 against Block 2 only
4. Verify state restoration works correctly
5. Benchmark Block 2 performance overhead

**Duration**: 1 hour

**Deliverables**:
- Modified research.md Block 2 (15 lines added)
- Test results: T5-T6 capture rate
- Performance measurement: Block 2 overhead <5ms
- State restoration validation: assertions pass

#### Phase 3: End-to-End Validation

**Objective**: Test full /research workflow with ERR traps in both blocks

**Tasks**:
1. Run complete test suite (T1-T6) against modified /research
2. Calculate overall error capture rate
3. Run production /research workflows (no injected errors)
4. Verify zero false positives
5. Compare performance: baseline vs with-traps
6. Review decision criteria checklist

**Duration**: 2 hours

**Deliverables**:
- Complete test results: 5/6 tests passing (T1-T4, T6)
- Error capture rate: >90%
- Performance overhead: <5ms per block
- False positive rate: 0%
- Decision report: GO/NO-GO recommendation

**Total Duration**: 6 hours

## Recommendations

### Immediate Actions (Phase 0)

1. **Create Isolated Test Environment**: Implement test_research_err_trap.sh with all 6 test scenarios before making any changes to /research command. This establishes baseline and validates test methodology.

2. **Baseline Performance Measurement**: Run 100 iterations of /research command in test mode, measure average execution time. This establishes performance baseline for comparison.

3. **Document Known Limitations**: Before implementation, document that ERR trap cannot catch errors that prevent library sourcing (T5 expected failure). This sets realistic expectations.

### Implementation Approach (Phases 1-3)

4. **Incremental Integration**: Implement Block 1 trap first, validate, then Block 2. Do NOT implement both simultaneously - this isolates issues to specific blocks.

5. **State Persistence First**: Add USER_ARGS persistence to Block 1 BEFORE adding trap. Verify persistence works via test assertions BEFORE relying on it for trap context.

6. **Comprehensive Testing**: Run test suite after each phase, not just at end. Catch issues early when rollback is cheapest.

### Decision Point Actions

7. **Document Findings**: Create validation report after Phase 3 with quantitative metrics (capture rate, performance, false positives) and qualitative assessment (maintainability, debuggability).

8. **Go/No-Go Decision**: If ALL go criteria met, document approval to proceed with full rollout (all 6 commands). If ANY no-go criteria triggered, document reason and recommend alternative approach.

9. **Rollback Testing**: Before declaring validation complete, test rollback plan: revert changes, verify /research still works, verify no error log corruption.

### Alternative Approaches (If Validation Fails)

10. **Wrapper Script Approach**: If ERR trap proves unworkable (false positives, performance), investigate bash wrapper that invokes command in subshell with trap in parent. This isolates trap from command logic.

11. **Selective Trap Application**: If certain bash blocks have high false positive rates, apply trap only to critical blocks (setup, state transitions) and exclude verification blocks.

12. **Post-Execution Error Parsing**: If bash-level error capture proves too complex, investigate parsing Claude Code tool output for bash error patterns and logging retroactively. Lower fidelity but simpler implementation.

## References

### Primary Sources

- `/home/benjamin/.config/.claude/commands/research.md` - Current /research command implementation (459 lines, 2 bash blocks)
- `/home/benjamin/.config/.claude/lib/core/error-handling.sh` - Error logging library with `log_command_error()` and `setup_bash_error_trap()` functions
- `/home/benjamin/.config/.claude/specs/861_build_command_use_this_research_to_create_a/plans/001_build_command_use_this_research_to_creat_plan.md` - Reference plan for ERR trap strategy (580 lines)
- `/home/benjamin/.config/.claude/specs/861_build_command_use_this_research_to_create_a/reports/002_revise_errors_not_captured_analysis.md` - Root cause analysis showing 30% capture rate baseline

### Supporting Documentation

- `/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md` - Error handling pattern documentation (673 lines)
- `/home/benjamin/.config/.claude/agents/research-specialist.md` - Research specialist behavioral guidelines (686 lines)
- `/home/benjamin/.config/CLAUDE.md` - Project standards including error logging requirements (section: error_logging)

### Test Files

- `/home/benjamin/.config/.claude/tests/test_error_logging.sh` - Existing error logging test suite
- `/home/benjamin/.config/.claude/tests/test_error_logging_compliance.sh` - Error logging compliance checker
- `.claude/tests/logs/test-errors.jsonl` - Test-specific error log (environment=test)

### Related Work

- Error capture gap analysis: 40% of command failures invisible to /errors command
- State machine error handling: `handle_state_error()` integration pattern
- Hierarchical agent error protocol: `TASK_ERROR` signal parsing
- Multi-block command pattern: State persistence and variable restoration
