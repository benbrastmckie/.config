# Repair Research Command Path Mismatch - Implementation Plan

## Metadata
- **Date**: 2025-11-23
- **Feature**: Fix PATH MISMATCH bug in workflow commands
- **Scope**: State file path consistency across workflow commands
- **Estimated Phases**: 4
- **Estimated Hours**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 35.5 (fix=3 + 16 tasks/2 + 8 files*3 + 1 integration*5)
- **Research Reports**:
  - [Gap Analysis Report](../reports/001-repair-research-gap-analysis.md)

## Overview

The /research command (and several other workflow commands) fails due to a PATH MISMATCH bug:
- **Block 1a** creates state file at `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh` via `init_workflow_state()`
- **Block 1c** looks for state file at `${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh` (hardcoded)
- When `HOME=/home/benjamin` and `CLAUDE_PROJECT_DIR=/home/benjamin/.config`, the paths differ and state file is not found

This plan fixes the path mismatch in all affected commands and adds validation to prevent recurrence.

## Research Summary

From the gap analysis report (001-repair-research-gap-analysis.md):

1. **Root Cause**: Inconsistent path construction - `state-persistence.sh:init_workflow_state()` uses `${CLAUDE_PROJECT_DIR}` but Block 1c of /research hardcodes `${HOME}` path
2. **Scope**: Bug affects `/research`, `/plan`, `/errors`, `/debug`, `/repair`, `/revise`, `/setup`, `/optimize-claude` commands (8 files total)
3. **Correct Pattern**: `/build` command correctly uses `${CLAUDE_PROJECT_DIR}/.claude/tmp/` - use as reference
4. **Fix Strategy**: Replace `${HOME}/.claude/tmp/workflow_` with `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_` AFTER project detection

## Success Criteria
- [ ] All 8 affected commands use consistent `${CLAUDE_PROJECT_DIR}/.claude/tmp/` path pattern
- [ ] `/research` command completes without "State file not found" error
- [ ] Path validation function detects mismatched STATE_FILE paths at runtime
- [ ] No regressions in `/build` command (already correct)
- [ ] State files created and read from same directory

## Technical Design

### Problem Analysis
```
init_workflow_state() in state-persistence.sh:156:
  STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"

Block 1c in research.md:273:
  STATE_FILE="${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"

When HOME=/home/benjamin and CLAUDE_PROJECT_DIR=/home/benjamin/.config:
  - Created at: /home/benjamin/.config/.claude/tmp/workflow_research_XXX.sh
  - Looked for: /home/benjamin/.claude/tmp/workflow_research_XXX.sh
  - Result: "State file not found" error
```

### Solution Architecture
1. **Primary Fix**: Update all bash blocks that construct STATE_FILE paths to use `${CLAUDE_PROJECT_DIR}` instead of `${HOME}`
2. **Ordering Fix**: Ensure CLAUDE_PROJECT_DIR is detected BEFORE constructing STATE_FILE path
3. **Validation**: Add `validate_state_file_path()` function to detect mismatches at runtime
4. **Pattern Enforcement**: Use `load_workflow_state()` where possible instead of manual path construction

### Files to Modify
| File | Lines | Change Type |
|------|-------|-------------|
| research.md | 273, 282, 319 | Replace ${HOME} with ${CLAUDE_PROJECT_DIR} |
| plan.md | 299, 373, 337, 390, 446, 501 | Replace ${HOME} with ${CLAUDE_PROJECT_DIR} |
| errors.md | 357, 361, 453 | Replace ${HOME} with ${CLAUDE_PROJECT_DIR} |
| debug.md | 445, 381, 561, 866, etc. | Replace ${HOME} with ${CLAUDE_PROJECT_DIR} |
| repair.md | 330, 334, 502, 772 | Replace ${HOME} with ${CLAUDE_PROJECT_DIR} |
| revise.md | 431, etc. | Replace ${HOME} with ${CLAUDE_PROJECT_DIR} |
| setup.md | 394, etc. | Replace ${HOME} with ${CLAUDE_PROJECT_DIR} |
| optimize-claude.md | 268, etc. | Replace ${HOME} with ${CLAUDE_PROJECT_DIR} |
| state-persistence.sh | (add function) | Add validate_state_file_path() |

## Implementation Phases

### Phase 1: Fix /research Command (Primary Target) [COMPLETE]
dependencies: []

**Objective**: Fix the PATH MISMATCH in /research command - the most critical fix

**Complexity**: Low

Tasks:
- [x] Fix Block 1c STATE_FILE path (research.md:273): Change `STATE_FILE="${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"` to `STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"`
- [x] Fix Block 1c TOPIC_NAMING_INPUT_FILE path (research.md:282): Change to use `${CLAUDE_PROJECT_DIR}`
- [x] Fix Block 1c TOPIC_NAME_FILE path (research.md:319): Change to use `${CLAUDE_PROJECT_DIR}`
- [x] Verify CLAUDE_PROJECT_DIR detection happens before STATE_FILE construction (lines 293-306 run before line 273 after reorder)
- [x] Move STATE_FILE construction after CLAUDE_PROJECT_DIR detection block

Testing:
```bash
# Test /research command with mismatched HOME/CLAUDE_PROJECT_DIR
cd /home/benjamin/.config
/research "test path mismatch fix"
# Expected: No "State file not found" error
# Expected: Research completes successfully
```

**Expected Duration**: 1 hour

### Phase 2: Fix Remaining Affected Commands [COMPLETE]
dependencies: [1]

**Objective**: Apply same fix pattern to all other affected commands

**Complexity**: Medium

Tasks:
- [x] Fix /plan command (plan.md): Update lines 299, 337, 373, 390, 446, 501 to use `${CLAUDE_PROJECT_DIR}`
- [x] Fix /errors command (errors.md): Update lines 357, 361, 453 to use `${CLAUDE_PROJECT_DIR}`
- [x] Fix /debug command (debug.md): Update all `${HOME}/.claude/tmp/` occurrences to use `${CLAUDE_PROJECT_DIR}`
- [x] Fix /repair command (repair.md): Update lines 330, 334, 502, 772 to use `${CLAUDE_PROJECT_DIR}`
- [x] Fix /revise command (revise.md): Update line 431 and similar to use `${CLAUDE_PROJECT_DIR}`
- [x] Fix /setup command (setup.md): Update lines 394 and similar to use `${CLAUDE_PROJECT_DIR}`
- [x] Fix /optimize-claude command (optimize-claude.md): Update line 268 and similar to use `${CLAUDE_PROJECT_DIR}`

Testing:
```bash
# Test each command individually
cd /home/benjamin/.config
/plan "test fix" && echo "plan: OK"
/debug "test issue" && echo "debug: OK"
/repair && echo "repair: OK"
# Expected: No "State file not found" errors in any command
```

**Expected Duration**: 2 hours

### Phase 3: Add Path Validation Function [COMPLETE]
dependencies: [1]

**Objective**: Add runtime validation to detect and prevent path mismatches

**Complexity**: Low

Tasks:
- [x] Add `validate_state_file_path()` function to state-persistence.sh:
```bash
# Validate state file path consistency
# Usage: validate_state_file_path "$WORKFLOW_ID"
# Returns: 0 if path is correct, 1 if mismatch detected
validate_state_file_path() {
  local workflow_id="$1"
  local expected_path="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"

  if [ -n "${STATE_FILE:-}" ] && [ "$STATE_FILE" != "$expected_path" ]; then
    echo "ERROR: STATE_FILE path mismatch" >&2
    echo "  Current: $STATE_FILE" >&2
    echo "  Expected: $expected_path" >&2
    echo "  CLAUDE_PROJECT_DIR: ${CLAUDE_PROJECT_DIR:-UNSET}" >&2
    echo "  HOME: ${HOME:-UNSET}" >&2
    return 1
  fi
  return 0
}
```
- [x] Export the function for use in command bash blocks
- [x] Add inline comment documenting the correct path pattern

Testing:
```bash
# Test validation function
source /home/benjamin/.config/.claude/lib/core/state-persistence.sh
CLAUDE_PROJECT_DIR="/home/benjamin/.config"
STATE_FILE="/home/benjamin/.claude/tmp/workflow_test.sh"  # Wrong path
validate_state_file_path "test"
# Expected: Returns 1 with error message showing mismatch
```

**Expected Duration**: 1 hour

### Phase 4: Verification and Documentation [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Comprehensive testing and documentation of the fix

**Complexity**: Low

Tasks:
- [x] Run full integration test of /research command
- [x] Verify /build command still works (no regression)
- [x] Document the correct path pattern in state-persistence.sh header comments
- [x] Add troubleshooting note to research.md about path mismatch symptom
- [x] Clean up any orphaned state files from testing

Testing:
```bash
# Full integration test
cd /home/benjamin/.config
echo "Testing /research..."
/research "integration test after path fix"

# Verify state files are in correct location
ls -la /home/benjamin/.config/.claude/tmp/workflow_*.sh

# Verify no state files in wrong location
ls -la /home/benjamin/.claude/tmp/workflow_*.sh 2>/dev/null && echo "WARNING: Old state files exist" || echo "Good: No orphaned state files"
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Tests
- Validate `validate_state_file_path()` detects mismatches correctly
- Verify path construction produces correct results in isolation

### Integration Tests
- Run /research command end-to-end in environment where HOME != CLAUDE_PROJECT_DIR
- Run /build command to verify no regression
- Run each fixed command to verify state persistence works

### Regression Tests
- Ensure /build command (already correct) continues to work
- Verify state files are created and loaded from same location

## Documentation Requirements
- [ ] Update state-persistence.sh header comments with correct path pattern
- [ ] Add inline comments in fixed commands explaining the path requirement
- [ ] Update troubleshooting section in research.md

## Dependencies
- state-persistence.sh library (already exists)
- Git repository context for CLAUDE_PROJECT_DIR detection
- No external dependencies

## Risk Assessment

### Low Risk
- The fix is straightforward string replacement (${HOME} -> ${CLAUDE_PROJECT_DIR})
- /build command already uses correct pattern - proven to work
- Changes are localized to path construction lines

### Mitigation
- Phase 1 fixes most critical command first (/research)
- Validation function in Phase 3 provides runtime detection of future regressions
- Each command tested individually before moving to next

## Notes
- The /build command correctly uses `${CLAUDE_PROJECT_DIR}` - use as reference implementation
- The state-persistence.sh library functions (init_workflow_state, load_workflow_state) already use correct paths
- The bug is in manual STATE_FILE path construction in command bash blocks that bypass library functions
