# Standards Compliance Review for Build Command Fix Plan

## Metadata
- **Date**: 2025-11-18
- **Agent**: research-specialist
- **Topic**: Plan revision insights for: review the standards in .claude/docs/ to ensure implementation aligns with those standards
- **Report Type**: standards compliance analysis

## Executive Summary

The implementation plan for fixing the state machine transition error in the build command is largely sound but has several gaps with established standards. Key issues include: incomplete error context formatting (missing WHICH/WHAT/WHERE structure), insufficient test coverage specification, missing test isolation patterns, and deviation from defensive programming standards. The plan should incorporate structured error messages, explicit test file creation with isolation patterns, and proper state validation using project conventions.

## Findings

### 1. Error Context Standards Gap

**Standard Reference**: `.claude/docs/concepts/patterns/defensive-programming.md` (lines 306-381)

The plan proposes adding error messages like:
```bash
echo "ERROR: CURRENT_STATE not properly restored from state file" >&2
echo "Expected: Previous block's state, Got: ${CURRENT_STATE:-empty}" >&2
```

**Non-Compliance**: The established pattern requires WHICH/WHAT/WHERE structure:
```bash
echo "ERROR: State restoration failed"
echo "WHICH: load_workflow_state"
echo "WHAT: CURRENT_STATE not restored from state file"
echo "WHERE: Block 2, testing phase setup"
```

### 2. Testing Standards Gaps

**Standard Reference**: `.claude/docs/reference/testing-protocols.md` (lines 1-236)

**Issue 2a - No Test File Specification**: The plan mentions "Manual test" approaches but doesn't specify creation of automated tests. Standards require:
- Test Location: `.claude/tests/`
- Test Pattern: `test_*.sh` (Bash test scripts)
- Coverage Target: 80% for modified code

**Issue 2b - Missing Test Isolation**: The plan doesn't address test isolation, which is required per testing-protocols.md (lines 200-235):
```bash
# Required pattern
export CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"
mkdir -p "$CLAUDE_SPECS_ROOT"
trap cleanup EXIT
```

**Issue 2c - No Regression Tests**: Standards require regression tests for all bug fixes (line 37).

### 3. State Validation Pattern Inconsistency

**Standard Reference**: `.claude/docs/architecture/state-based-orchestration-overview.md` (lines 1474-1518)

The plan proposes custom validation in Phase 1:
```bash
if [ -z "${CURRENT_STATE:-}" ] || [ "$CURRENT_STATE" = "initialize" ]; then
```

**Better Pattern**: The state orchestration documentation shows standard troubleshooting patterns for state file issues (lines 1500-1518) that use `init_workflow_state`/`load_workflow_state` order validation. The plan should align with documented patterns.

### 4. Code Standards Alignment

**Standard Reference**: `.claude/docs/reference/code-standards.md` (lines 1-84)

**Issue 4a - Shell Scripts**: Per line 17, "Follow ShellCheck recommendations, use bash -e for error handling". The plan doesn't address adding `set -e` to affected blocks.

**Issue 4b - Error Handling**: Per line 8, error handling should use "structured error messages (WHICH/WHAT/WHERE)". Current plan uses unstructured format.

### 5. Defensive Programming Gaps

**Standard Reference**: `.claude/docs/concepts/patterns/defensive-programming.md`

**Issue 5a - Return Code Verification** (lines 159-231): The plan adds error handling for `sm_transition` but doesn't wrap all critical operations with return code checks.

**Issue 5b - Input Validation** (lines 15-77): The state validation proposed could be enhanced with standard input validation patterns for environment variables.

### 6. Positive Compliance Areas

The plan correctly addresses:
- State machine transition table structure (aligns with state-orchestration-overview.md lines 219-232)
- History expansion disabling pattern (`set +H`)
- State persistence library usage (`state-persistence.sh`, `workflow-state-machine.sh`)
- Proper use of `sm_transition` function for validated transitions

## Recommendations

### 1. Refactor Error Messages to WHICH/WHAT/WHERE Format

**Location**: All error message additions in Phases 1-3

Transform error messages to match standards:
```bash
# Phase 1 state validation error
echo "ERROR: State restoration failed" >&2
echo "WHICH: load_workflow_state" >&2
echo "WHAT: CURRENT_STATE not properly restored (expected: previous state, got: ${CURRENT_STATE:-empty})" >&2
echo "WHERE: Block 2, testing phase initialization" >&2

# Phase 2 predecessor validation error
echo "ERROR: Invalid predecessor state for completion" >&2
echo "WHICH: sm_transition to complete" >&2
echo "WHAT: Current state '$CURRENT_STATE' cannot transition to complete" >&2
echo "WHERE: Block 4, workflow completion" >&2
```

### 2. Add Explicit Test Suite Creation

**New Task for Phase 1 or 2**: Create test file `.claude/tests/test_build_state_transitions.sh`

The test should include:
- Test isolation pattern with `CLAUDE_SPECS_ROOT` override
- Test cases for:
  - Successful state transitions through all blocks
  - State validation after load
  - Predecessor state validation in Block 4
  - History expansion handling
- Cleanup traps
- Coverage target verification

### 3. Add `set -e` for Fail-Fast Behavior

**Modification**: Add to all bash blocks (Blocks 1-4)

```bash
#!/usr/bin/env bash
set +H 2>/dev/null || true  # Disable history expansion
set +o histexpand 2>/dev/null || true
set -e  # Exit on first error (fail-fast)
```

This aligns with code standards line 17: "use bash -e for error handling"

### 4. Enhance State Validation with Standard Pattern

**Modification to Phase 1**: Align with documented troubleshooting pattern

```bash
# From state-orchestration-overview.md lines 1500-1518
load_workflow_state "$WORKFLOW_ID" false

# Enhanced validation matching documented pattern
if [ -z "$STATE_FILE" ]; then
  echo "ERROR: State file path not set" >&2
  echo "WHICH: load_workflow_state" >&2
  echo "WHAT: STATE_FILE variable empty after load" >&2
  echo "WHERE: Block state initialization" >&2
  exit 1
fi

if [ ! -f "$STATE_FILE" ]; then
  echo "WARNING: State file not found, reinitializing" >&2
  init_workflow_state "$WORKFLOW_ID"
fi
```

### 5. Add Test Isolation to Testing Strategy

**Addition to Testing Strategy section**:

```bash
# Test with isolation overrides
test_build_state_transitions() {
  local test_dir
  test_dir="$(mktemp -d)"
  export CLAUDE_SPECS_ROOT="$test_dir"
  export CLAUDE_PROJECT_DIR="$test_dir"

  trap "rm -rf '$test_dir'; unset CLAUDE_SPECS_ROOT CLAUDE_PROJECT_DIR" EXIT

  # Create minimal test structure
  mkdir -p "$test_dir/.claude/lib"
  mkdir -p "$test_dir/.claude/tmp"

  # Copy required libraries
  cp /home/benjamin/.config/.claude/lib/state-persistence.sh "$test_dir/.claude/lib/"
  cp /home/benjamin/.config/.claude/lib/workflow-state-machine.sh "$test_dir/.claude/lib/"

  # Run test scenarios
  # ...
}
```

### 6. Update Documentation Requirements

The plan mentions updating troubleshooting sections. Ensure updates follow:
- Code standards internal link conventions (lines 55-83)
- No emojis in file content (line 10)
- CommonMark specification (line 14)

## References

- `/home/benjamin/.config/.claude/docs/reference/code-standards.md` (lines 1-84)
- `/home/benjamin/.config/.claude/docs/reference/testing-protocols.md` (lines 1-236)
- `/home/benjamin/.config/.claude/docs/concepts/directory-organization.md` (lines 1-276)
- `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md` (lines 1-1766)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/defensive-programming.md` (lines 1-456)
- `/home/benjamin/.config/.claude/commands/build.md` (lines 380-669)
- `/home/benjamin/.config/.claude/specs/790_fix_state_machine_transition_error_build_command/plans/001_fix_state_machine_transition_error_build_plan.md` (lines 1-224)

## Implementation Status
- **Status**: Plan Revised
- **Plan**: [../plans/001_fix_state_machine_transition_error_build_plan.md](../plans/001_fix_state_machine_transition_error_build_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-18
- **Revision Note**: All recommendations incorporated into revised plan (WHICH/WHAT/WHERE errors, test isolation, fail-fast behavior)
