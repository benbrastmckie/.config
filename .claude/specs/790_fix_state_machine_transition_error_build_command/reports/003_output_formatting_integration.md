# Output Formatting Integration Research Report

## Metadata
- **Date**: 2025-11-18
- **Agent**: research-specialist
- **Topic**: Output formatting integration for spec 790 state machine transition fix
- **Report Type**: pattern recognition and integration analysis

## Executive Summary

The spec 778 comprehensive output formatting refactor introduces key patterns for block consolidation, output suppression, and standardized messaging that should be integrated into the spec 790 state transition fix. The primary patterns include: workflow-init.sh library for centralized initialization, 2>/dev/null suppression for library sourcing, single summary lines per block, and DEBUG_LOG redirection for verbose diagnostics. The spec 790 plan should adopt these patterns in its error messaging and state validation output to ensure consistency with the evolving infrastructure standards.

## Findings

### Output Formatting Patterns from Spec 778

#### Pattern 1: Output Suppression for Library Sourcing
**Location**: spec 778 plan lines 94-108

The spec 778 plan establishes a standard pattern for suppressing library sourcing output:

```bash
# Suppress library sourcing
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh" 2>/dev/null

# Redirect diagnostics to log file
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
if ! operation; then
  echo "ERROR: Operation failed (see $DEBUG_LOG)" >&2
  echo "[$(date)] Details..." >> "$DEBUG_LOG"
  exit 1
fi

# Single summary line per block
echo "Setup complete: $WORKFLOW_ID"
```

**Integration Point for Spec 790**: The state validation code in Phases 1 and 2 should redirect verbose diagnostic output (WHICH/WHAT/WHERE blocks) to the DEBUG_LOG rather than stderr, with a single summary error line visible to the user.

#### Pattern 2: Block Consolidation Structure
**Location**: spec 778 plan lines 74-90

The spec 778 plan defines a target block structure:

**Before** (6 blocks):
```
Block 1: Capture arguments
Block 2: Validate arguments
Block 3: Initialize state machine
Block 4: Allocate topic directory
Block 5: Verify artifacts
Block 6: Complete workflow
```

**After** (2-3 blocks):
```
Block 1: Setup (capture, validate, init, allocate)
Block 2: Execute (main workflow logic)
Block 3: Cleanup (verify, complete)
```

**Integration Point for Spec 790**: While spec 790 is a bug fix (not block consolidation), the state validation additions should be structured to enable future consolidation. Each validation block should be self-contained and could be extracted into a function.

#### Pattern 3: Centralized Workflow Initialization
**Location**: spec 778 plan lines 54-71 and 129-160

The workflow-init.sh library pattern:

```bash
# workflow-init.sh provides:
# - init_workflow() - One-time initialization (Block 1)
#   ├── Detect CLAUDE_PROJECT_DIR (cached)
#   ├── Source required libraries (suppressed)
#   ├── Initialize state machine
#   └── Create state file with trap cleanup
# - load_workflow_context() - Load state (Block 2+)
#   └── Source state file if exists
```

**Integration Point for Spec 790**: The state validation pattern in Phase 1 could leverage workflow-init.sh if it's available. The validation function should check for the library and use it when present.

#### Pattern 4: Single Summary Line Per Block
**Location**: spec 778 plan line 107

Every bash block should end with a single summary line indicating completion status:

```bash
echo "Setup complete: $WORKFLOW_ID"
```

**Integration Point for Spec 790**: The DEBUG output lines in spec 790 Phase 1 (e.g., `echo "DEBUG: Loaded state: $CURRENT_STATE"`) should be converted to either:
- Suppressed output (to DEBUG_LOG) for verbose details
- Single summary line for user feedback

### Current Spec 790 Output Patterns

#### Current Error Message Format (Spec 790 lines 96-126)

The spec 790 plan uses a verbose WHICH/WHAT/WHERE format:

```bash
echo "ERROR: State file path not set" >&2
echo "WHICH: load_workflow_state" >&2
echo "WHAT: STATE_FILE variable empty after load" >&2
echo "WHERE: Block 2, testing phase initialization" >&2
exit 1
```

**Issue**: This produces 4+ lines of output per error, which contradicts the output suppression goals of spec 778.

#### Current Debug Output (Spec 790 line 126)

```bash
echo "DEBUG: Loaded state: $CURRENT_STATE"
```

**Issue**: Debug output should be conditional or redirected to DEBUG_LOG.

### Recommended Integration Patterns

#### Integration Pattern 1: Hybrid Error Output

Combine the structured error information with output suppression:

```bash
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"

# Log verbose details
{
  echo "[$(date)] ERROR: State file path not set"
  echo "WHICH: load_workflow_state"
  echo "WHAT: STATE_FILE variable empty after load"
  echo "WHERE: Block 2, testing phase initialization"
} >> "$DEBUG_LOG"

# Single error line to user
echo "ERROR: State file path not set (see $DEBUG_LOG for details)" >&2
exit 1
```

**Benefit**: Preserves detailed debugging information while reducing output noise.

#### Integration Pattern 2: Conditional Debug Output

```bash
if [ "${DEBUG:-}" = "1" ] || [ "${VERBOSE:-}" = "1" ]; then
  echo "DEBUG: Loaded state: $CURRENT_STATE"
else
  # Single summary for production
  echo "State validated: $CURRENT_STATE"
fi
```

**Benefit**: Allows verbose output when needed while keeping default output clean.

#### Integration Pattern 3: Library Sourcing Consistency

Ensure all library sourcing in spec 790 additions follows the suppression pattern:

```bash
# Instead of:
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

# Use:
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh" 2>/dev/null
```

#### Integration Pattern 4: Progress/Checkpoint Reporting

The spec 778 plan (Phase 1, line 147) mentions using checkpoint patterns. Spec 790 could adopt:

```bash
# After successful state validation
echo "Block 2: State validated (${CURRENT_STATE})"
```

This follows the single summary line pattern while providing useful progress indication.

### Files Analyzed

1. **Spec 778 Plan**: /home/benjamin/.config/.claude/specs/778_doesnt_the_state_machine_provide_something_similar/plans/001_comprehensive_output_formatting_refactor.md
   - Lines 54-71: Architecture overview
   - Lines 74-90: Block consolidation pattern
   - Lines 94-108: Output suppression pattern
   - Lines 112-125: State persistence standardization
   - Lines 129-160: Phase 1 workflow-init.sh tasks

2. **Spec 790 Plan**: /home/benjamin/.config/.claude/specs/790_fix_state_machine_transition_error_build_command/plans/001_fix_state_machine_transition_error_build_plan.md
   - Lines 96-126: State validation pattern (Phase 1)
   - Lines 152-193: Predecessor state validation (Phase 2)
   - Lines 228-330: Test template (Phase 3)

### Output Directory Analysis

The outputs directory for spec 778 was not found at the expected location (`/home/benjamin/.config/.claude/specs/778_doesnt_the_state_machine_provide_something_similar/outputs/`), suggesting spec 778 may still be in progress or outputs are tracked elsewhere. The plan itself (001_comprehensive_output_formatting_refactor.md) serves as the primary reference for patterns.

## Recommendations

### Recommendation 1: Adopt Hybrid Error Output Pattern

**Priority**: High
**Phase**: 1 and 2 of spec 790

Update the error message format in Phases 1 and 2 to use the hybrid pattern:

```bash
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"

# Detailed log
{
  echo "[$(date)] ERROR: State file path not set"
  echo "WHICH: load_workflow_state"
  echo "WHAT: STATE_FILE variable empty after load"
  echo "WHERE: Block 2, testing phase initialization"
} >> "$DEBUG_LOG"

# User-facing summary
echo "ERROR: State file path not set (see $DEBUG_LOG)" >&2
exit 1
```

**Rationale**: Preserves structured debugging while aligning with output suppression goals from spec 778.

### Recommendation 2: Add DEBUG_LOG Initialization

**Priority**: High
**Phase**: All phases of spec 790

Add DEBUG_LOG initialization at the start of each block or in a shared pattern:

```bash
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null
```

**Rationale**: Required infrastructure for hybrid error output pattern.

### Recommendation 3: Convert Debug Output to Conditional

**Priority**: Medium
**Phase**: 1 of spec 790

Change line 126 pattern from unconditional debug to conditional:

```bash
# Instead of:
echo "DEBUG: Loaded state: $CURRENT_STATE"

# Use:
[ "${DEBUG:-}" = "1" ] && echo "DEBUG: Loaded state: $CURRENT_STATE"
echo "State validated: $CURRENT_STATE"
```

**Rationale**: Maintains single summary line pattern while preserving debug capability.

### Recommendation 4: Add Library Sourcing Suppression

**Priority**: Medium
**Phase**: 3 of spec 790 (test template)

Ensure test template uses suppressed library sourcing:

```bash
# Lines 271-273 of spec 790 plan should use:
source "$test_dir/.claude/lib/state-persistence.sh" 2>/dev/null
source "$test_dir/.claude/lib/workflow-state-machine.sh" 2>/dev/null
source "$test_dir/.claude/lib/checkpoint-utils.sh" 2>/dev/null
```

**Rationale**: Test output should also follow output suppression patterns for consistency.

### Recommendation 5: Consider workflow-init.sh Integration

**Priority**: Low (future enhancement)
**Phase**: Future revision

Once workflow-init.sh is implemented (spec 778 Phase 1), spec 790's state validation could be refactored to use it:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-init.sh" 2>/dev/null
load_workflow_context "$WORKFLOW_ID"  # Handles validation internally
```

**Rationale**: Reduces duplication and leverages centralized infrastructure.

### Recommendation 6: Align Troubleshooting Output

**Priority**: Medium
**Phase**: 2 of spec 790

The TROUBLESHOOTING blocks (lines 166-170, 178-181) should also be redirected to DEBUG_LOG:

```bash
# Log troubleshooting steps to file
{
  echo "TROUBLESHOOTING:"
  echo "1. Check Block 3 for errors (debug/document phase)"
  echo "2. Verify state file contains expected transitions"
  echo "3. Check for history expansion errors in previous blocks"
} >> "$DEBUG_LOG"

# User-facing summary
echo "ERROR: Invalid predecessor state (see $DEBUG_LOG for troubleshooting)" >&2
```

**Rationale**: Maintains helpful troubleshooting information without cluttering user output.

## References

- /home/benjamin/.config/.claude/specs/778_doesnt_the_state_machine_provide_something_similar/plans/001_comprehensive_output_formatting_refactor.md:54-71 (Architecture overview)
- /home/benjamin/.config/.claude/specs/778_doesnt_the_state_machine_provide_something_similar/plans/001_comprehensive_output_formatting_refactor.md:74-90 (Block consolidation)
- /home/benjamin/.config/.claude/specs/778_doesnt_the_state_machine_provide_something_similar/plans/001_comprehensive_output_formatting_refactor.md:94-108 (Output suppression)
- /home/benjamin/.config/.claude/specs/778_doesnt_the_state_machine_provide_something_similar/plans/001_comprehensive_output_formatting_refactor.md:112-125 (State persistence)
- /home/benjamin/.config/.claude/specs/778_doesnt_the_state_machine_provide_something_similar/plans/001_comprehensive_output_formatting_refactor.md:129-160 (Phase 1 tasks)
- /home/benjamin/.config/.claude/specs/790_fix_state_machine_transition_error_build_command/plans/001_fix_state_machine_transition_error_build_plan.md:96-126 (State validation)
- /home/benjamin/.config/.claude/specs/790_fix_state_machine_transition_error_build_command/plans/001_fix_state_machine_transition_error_build_plan.md:152-193 (Predecessor validation)
- /home/benjamin/.config/.claude/specs/790_fix_state_machine_transition_error_build_command/plans/001_fix_state_machine_transition_error_build_plan.md:228-330 (Test template)

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_fix_state_machine_transition_error_build_plan.md](../plans/001_fix_state_machine_transition_error_build_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-18
- **Revision Note**: All output formatting patterns integrated into revised plan (hybrid error output, DEBUG_LOG, conditional debug, library suppression)
