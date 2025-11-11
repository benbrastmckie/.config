# /coordinate State Management Patterns Research Report

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: /coordinate command architecture and existing state management patterns in .claude/ infrastructure
- **Report Type**: codebase analysis

## Executive Summary

[Research in progress - comprehensive analysis of subprocess isolation patterns, library re-sourcing, and WORKFLOW_SCOPE persistence across bash block boundaries]

## Findings

### 1. Bash Block Execution Model and Subprocess Isolation

**Key Discovery**: Each bash block in `/coordinate` runs as a separate subprocess (documented in `.claude/docs/concepts/bash-block-execution-model.md`), creating fundamental constraints for state management.

**Process Architecture** (bash-block-execution-model.md:14-33):
```
Claude Code Session
    ↓
Command Execution (coordinate.md)
    ↓
┌────────── Bash Block 1 ──────────┐
│ PID: 12345                       │
│ - Source libraries               │
│ - Initialize state               │
│ - Save to files                  │
│ - Exit subprocess                │
└──────────────────────────────────┘
    ↓ (subprocess terminates)
┌────────── Bash Block 2 ──────────┐
│ PID: 12346 (NEW PROCESS)        │
│ - Re-source libraries            │
│ - Load state from files          │
│ - Process data                   │
│ - Exit subprocess                │
└──────────────────────────────────┘
```

**Critical Constraints** (bash-block-execution-model.md:42-48):
- Process ID (`$$`) changes between blocks
- All environment variables reset (exports lost)
- All bash functions lost (must re-source libraries)
- Trap handlers fire at block exit, not workflow exit
- **Files are the ONLY reliable cross-block communication channel**

### 2. /coordinate Library Re-sourcing Pattern

**Current Pattern** (coordinate.md:256-270, repeated 10 times across all state handlers):
```bash
# Re-source libraries (functions lost across bash block boundaries)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/unified-logger.sh"  # Provides emit_progress and logging functions
source "${LIB_DIR}/verification-helpers.sh"
```

**Observation**: This exact 14-line pattern appears at the start of **every bash block** in `/coordinate` (10 state handler blocks total), consuming ~140 lines of repetitive code.

**Why Re-sourcing is Necessary** (bash-block-execution-model.md:309-347):
All 6 libraries provide functions that are lost across subprocess boundaries. Missing any library causes "command not found" errors:

| Library | Functions Lost Without Re-sourcing | Impact |
|---------|-----------------------------------|--------|
| unified-logger.sh | `emit_progress`, `display_brief_summary` | Missing progress markers (degraded UX) |
| workflow-state-machine.sh | `sm_transition`, `sm_init` | State transitions fail, workflow halts |
| state-persistence.sh | `load_workflow_state`, `append_workflow_state` | Cannot restore state across blocks |
| error-handling.sh | `handle_state_error` | Unhandled errors, unclear failure messages |
| verification-helpers.sh | `verify_file_created` | Missing verification checkpoints |
| workflow-initialization.sh | `reconstruct_report_paths_array` | Cannot reconstruct arrays from state |

### 3. WORKFLOW_SCOPE Variable Persistence Pattern

**Initialization** (coordinate.md:84-124):
```bash
# CRITICAL: Save workflow description BEFORE sourcing libraries
# Libraries pre-initialize WORKFLOW_DESCRIPTION="" which overwrites parent value
SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"
export SAVED_WORKFLOW_DESC

# Source state machine and state persistence libraries
source "${LIB_DIR}/workflow-state-machine.sh"

# Initialize state machine (use SAVED value, not overwritten variable)
sm_init "$SAVED_WORKFLOW_DESC" "coordinate"

# Save state machine configuration to workflow state
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
append_workflow_state "TERMINAL_STATE" "$TERMINAL_STATE"
append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"
```

**Key Pattern**: `WORKFLOW_SCOPE` is:
1. **Calculated** by `sm_init()` in workflow-state-machine.sh (workflow-state-machine.sh:86-133)
2. **Pre-initialized to empty string** in library file (workflow-state-machine.sh:75: `WORKFLOW_SCOPE=""`)
3. **Saved to state file** via `append_workflow_state()` in Block 1 (coordinate.md:127)
4. **Restored from state file** via `load_workflow_state()` in subsequent blocks (coordinate.md:276, 416, etc.)

**Problem**: The library pre-initialization (`WORKFLOW_SCOPE=""`) happens when the library is sourced, BEFORE `sm_init()` calculates the actual value. This creates a timing issue where variables can be overwritten.

### 4. State Persistence Library Architecture

**File**: `.claude/lib/state-persistence.sh`

**Pattern**: GitHub Actions-style state files ($GITHUB_OUTPUT, $GITHUB_STATE)

**Key Functions**:
- `init_workflow_state()` (state-persistence.sh:115-142): Creates state file in Block 1 only
- `load_workflow_state()` (state-persistence.sh:168-182): Sources state file in Blocks 2+
- `append_workflow_state()` (state-persistence.sh:207-217): Appends key-value pairs to state file

**State File Format** (state-persistence.sh:131-135):
```bash
export CLAUDE_PROJECT_DIR="/path/to/project"
export WORKFLOW_ID="coordinate_1234567890"
export STATE_FILE="/path/to/project/.claude/tmp/workflow_1234567890.sh"
```

**Critical Insight**: State file is a **bash script containing export statements**, sourced in subsequent blocks to restore variables.

### 5. Conditional State Restoration Pattern

**Discovery** (coordinate.md:422-444):
```bash
# Defensive: Restore RESEARCH_COMPLEXITY if not loaded from state
# This can happen if workflow state doesn't persist properly across bash blocks
if [ -z "${RESEARCH_COMPLEXITY:-}" ]; then
  # Recalculate from WORKFLOW_DESCRIPTION (same logic as initial calculation)
  RESEARCH_COMPLEXITY=2

  if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"; then
    RESEARCH_COMPLEXITY=3
  fi

  # ... (additional complexity calculations)
fi

# Defensive: Restore USE_HIERARCHICAL_RESEARCH if not loaded from state
if [ -z "${USE_HIERARCHICAL_RESEARCH:-}" ]; then
  USE_HIERARCHICAL_RESEARCH=$([ $RESEARCH_COMPLEXITY -ge 4 ] && echo "true" || echo "false")
fi
```

**Pattern**: /coordinate uses **defensive recalculation** when variables aren't restored from state:
- Check if variable is empty (`[ -z "${VAR:-}" ]`)
- If empty, recalculate using original logic
- This provides graceful degradation when state persistence fails

**Applicability to WORKFLOW_SCOPE**: This pattern could be applied to restore `WORKFLOW_SCOPE` if it's not loaded from state, avoiding the need to save it before library sourcing.

### 6. Library Source Guards Pattern

**Pattern** (state-persistence.sh:9-12):
```bash
# Source guard: Prevent multiple sourcing
if [ -n "${STATE_PERSISTENCE_SOURCED:-}" ]; then
  return 0
fi
export STATE_PERSISTENCE_SOURCED=1
```

**Purpose**: Allows safe re-sourcing in every bash block without performance penalty or duplicate execution.

**Observation**: All 6 libraries sourced by /coordinate use this pattern:
- workflow-state-machine.sh:20-23
- state-persistence.sh:9-12
- workflow-initialization.sh:16-19
- (verified via pattern, not exhaustive line-by-line check)

**Implication**: Re-sourcing libraries is **designed to be safe** and expected behavior.

### 7. WORKFLOW_SCOPE Usage Patterns in /coordinate

**Analysis of all WORKFLOW_SCOPE references** (coordinate.md):

1. **Line 127**: Save to state: `append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"`
2. **Line 134-147**: Conditional library loading based on scope
3. **Line 168**: Pass to initialization: `initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"`
4. **Line 226**: Display to user: `echo "  Scope: $WORKFLOW_SCOPE"`
5. **Lines 621-657**: Determine next state transition (research complete → plan or complete)
6. **Lines 730, 742, 830, 893, 906, 926, 953, 968**: Branching logic for planning/revision workflows

**Critical Observation**: `WORKFLOW_SCOPE` is used **throughout the entire command**, not just in initialization. It must be reliably available in every bash block.

**Current Restoration**: Via `load_workflow_state()` in each block (coordinate.md:276, 416, 695, 821, 1029, 1099, 1172, 1292, 1360, 1480, 1546)

### 8. Comparison with Other Orchestration Commands

**Research Question**: Do /orchestrate and /supervise face the same challenges?

[TO DO: Examine /orchestrate and /supervise for similar patterns]

## Recommendations

[TO DO: Synthesize findings into actionable recommendations]

## References

- /home/benjamin/.config/.claude/commands/coordinate.md (1596 lines)
- /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md (642 lines)
- /home/benjamin/.config/.claude/lib/state-persistence.sh (341 lines)
- /home/benjamin/.config/.claude/lib/workflow-state-machine.sh (150 lines analyzed)
- /home/benjamin/.config/.claude/lib/workflow-initialization.sh (370 lines)
