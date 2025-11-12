# /coordinate State Management Patterns Research Report

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: /coordinate command architecture and existing state management patterns in .claude/ infrastructure
- **Report Type**: codebase analysis

## Executive Summary

This research report analyzes state management patterns in the /coordinate command and .claude/ infrastructure, focusing on subprocess isolation constraints, library re-sourcing patterns, and WORKFLOW_SCOPE variable preservation across bash block boundaries.

**Key Findings**:
1. /coordinate is the ONLY orchestration command correctly implementing multi-bash-block architecture with Pattern 4 (re-source libraries in every block)
2. Library pre-initialization (workflow-state-machine.sh:75-76) requires save-before-source workaround to preserve WORKFLOW_DESCRIPTION in /coordinate
3. /supervise uses multi-block architecture but DOES NOT re-source libraries, violating documented best practices
4. /orchestrate avoids subprocess isolation issues by using single-bash-block architecture with agent delegation
5. Defensive recalculation pattern (already used for RESEARCH_COMPLEXITY) can be applied to WORKFLOW_SCOPE for graceful degradation

**Impact**: The 14-line library re-sourcing pattern appears 10 times in /coordinate (140 lines, 8.7% of file), creating maintenance burden and code duplication.

**Recommendations** (prioritized): (1) Document WORKFLOW_SCOPE lifecycle patterns, (2) Add defensive restoration for WORKFLOW_SCOPE, (3) Extract re-sourcing logic to shared snippet (130-line reduction), (4) Standardize /supervise re-sourcing, (5) Consider conditional library initialization (medium risk).

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

**Research Question**: Do /orchestrate and /supervise face the same WORKFLOW_SCOPE preservation challenges?

#### /orchestrate Analysis (581 lines total)

**Structure**: Single bash block architecture (orchestrate.md:64-199)
- Only **ONE bash block** for initialization (no subsequent blocks = no re-sourcing needed)
- All 7 phase handlers use **Task tool invocations** (not bash blocks)
- Variables persist throughout single subprocess lifetime

**WORKFLOW_SCOPE Pattern** (orchestrate.md:86-114):
```bash
# Source state machine library FIRST
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Initialize state machine (calculates WORKFLOW_SCOPE)
sm_init "$WORKFLOW_DESCRIPTION" "orchestrate"

# Save to state file
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
```

**Key Difference**: /orchestrate **does NOT need the save-before-source pattern** because:
1. All work happens in a **single bash block** (no subprocess boundaries)
2. Phase handlers are **agent invocations**, not bash blocks
3. Variables remain in memory for entire command execution

**Error Handling** (orchestrate.md:152-187):
- Uses `export -f handle_state_error` to make function available to subprocesses
- This works in /orchestrate's single-block model but **would fail across /coordinate's bash block boundaries** (functions cannot be exported across subprocess boundaries)

#### /supervise Analysis (421 lines total)

**Structure**: Multi-bash-block architecture (similar to /coordinate but simpler)
- Uses **load_workflow_state()** at start of each state handler (supervise.md:136, 175, 196, 225, 250)
- No re-sourcing of libraries (missing the Pattern 4 re-sourcing blocks)
- Relies on state persistence alone

**WORKFLOW_SCOPE Pattern** (supervise.md:67-82):
```bash
# Source libraries ONCE in initialization block
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

# Initialize state machine
sm_init "$WORKFLOW_DESCRIPTION" "supervise"

# Save to state
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
```

**Key Observation**: /supervise uses **identical pattern to /coordinate** for WORKFLOW_SCOPE:
1. Source libraries → calculate WORKFLOW_SCOPE → save to state
2. Restore from state in subsequent blocks via `load_workflow_state()`
3. **Does NOT re-source libraries** in subsequent blocks (potential bug)

**Critical Finding**: /supervise **does not re-source libraries** in its state handler blocks (supervise.md:136-250). This means:
- Functions from libraries are **NOT available** in blocks 2+
- Relying on `load_workflow_state()` alone (not `sm_transition()`, `handle_state_error()`, etc.)
- This may work if state handlers don't call library functions, but violates Pattern 4 from bash-block-execution-model.md

**Error Handling** (supervise.md:109-118):
- Defines `handle_state_error()` in initialization block
- Uses `export -f handle_state_error` (same as /orchestrate)
- **This will fail in subsequent bash blocks** (functions cannot be exported across subprocess boundaries)

#### Architecture Comparison Summary

| Command | Bash Blocks | Re-sourcing Pattern | WORKFLOW_SCOPE Pattern | Library Functions Available? |
|---------|-------------|---------------------|------------------------|------------------------------|
| /coordinate | 10+ blocks | ✓ Re-source 6 libs every block | Save before source + restore from state | ✓ Yes (via re-sourcing) |
| /orchestrate | 1 block | N/A (single block) | Standard (source → init → save) | ✓ Yes (single process) |
| /supervise | 5+ blocks | ✗ No re-sourcing | Save before source + restore from state | ✗ No (likely bug) |

**Key Insight**: /coordinate is the **ONLY command with correct multi-block architecture**:
- /orchestrate avoids the problem by using single block
- /supervise has the problem but doesn't re-source libraries (incomplete implementation)
- /coordinate correctly implements Pattern 4 (re-source libraries in every block)

### 9. Libraries with WORKFLOW_SCOPE Pre-initialization

**Analysis**: Which libraries pre-initialize variables that could cause timing issues?

**Libraries Found** (via grep):
1. `workflow-state-machine.sh:75-76`:
   ```bash
   WORKFLOW_SCOPE=""
   WORKFLOW_DESCRIPTION=""
   ```

2. Other libraries referencing WORKFLOW_SCOPE:
   - `workflow-scope-detection.sh` - Defines `detect_workflow_scope()` function (no pre-initialization)
   - `overview-synthesis.sh` - Uses WORKFLOW_SCOPE but doesn't initialize
   - `error-handling.sh` - Uses WORKFLOW_SCOPE but doesn't initialize
   - `workflow-initialization.sh` - Uses WORKFLOW_SCOPE but doesn't initialize
   - `unified-logger.sh` - Uses WORKFLOW_SCOPE but doesn't initialize

**Conclusion**: Only **workflow-state-machine.sh** pre-initializes WORKFLOW_SCOPE to empty string, creating the timing issue documented in Finding #3.

### 10. Load Order Optimization Potential

**Current Pattern in /coordinate** (coordinate.md:84-124):
```bash
# Step 1: Save workflow description BEFORE sourcing
SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"
export SAVED_WORKFLOW_DESC

# Step 2: Source libraries (overwrites WORKFLOW_DESCRIPTION to "")
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Step 3: Initialize state machine with SAVED value
sm_init "$SAVED_WORKFLOW_DESC" "coordinate"

# Step 4: Save WORKFLOW_SCOPE to state file
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
```

**Alternative Pattern: Conditional Initialization in Library**

If workflow-state-machine.sh changed from:
```bash
WORKFLOW_SCOPE=""  # Unconditional pre-initialization
```

To:
```bash
# Only initialize if not already set (defensive pattern)
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
```

Then /coordinate could simplify to:
```bash
# Source libraries
source "${LIB_DIR}/workflow-state-machine.sh"

# Initialize (WORKFLOW_SCOPE calculated here)
sm_init "$WORKFLOW_DESCRIPTION" "coordinate"

# Save to state
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
```

**Impact**: Eliminates need for `SAVED_WORKFLOW_DESC` workaround (saves 3 lines per command)

**Tradeoff**: Defensive initialization in library vs. explicit save-before-source pattern in command

## Recommendations

### 1. Adopt Conditional Restoration Pattern for WORKFLOW_SCOPE (Low Risk)

**Problem**: /coordinate uses save-before-source workaround to preserve WORKFLOW_DESCRIPTION across library sourcing.

**Solution**: Apply defensive recalculation pattern (already used for RESEARCH_COMPLEXITY in coordinate.md:422-444) to WORKFLOW_SCOPE in subsequent bash blocks.

**Implementation**:
```bash
# After load_workflow_state() in each bash block:

# Defensive: Restore WORKFLOW_SCOPE if not loaded from state
if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  # Recalculate using same logic as sm_init()
  source "${LIB_DIR}/workflow-scope-detection.sh"
  WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

  # Fallback to default if detection fails
  WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-full-implementation}"
fi
```

**Benefits**:
- Graceful degradation when state persistence fails
- No change to library files needed
- Consistent with existing defensive patterns in /coordinate
- Eliminates dependency on Block 1's save-before-source pattern

**Scope**: ~10 lines added to each of 10 bash blocks in /coordinate (100 lines total)

### 2. Refactor Library Pre-initialization to Conditional Pattern (Medium Risk)

**Problem**: workflow-state-machine.sh unconditionally pre-initializes WORKFLOW_SCOPE="" and WORKFLOW_DESCRIPTION="", overwriting parent process values.

**Solution**: Change library pre-initialization to defensive pattern.

**Implementation** (workflow-state-machine.sh:75-77):
```bash
# Change FROM:
WORKFLOW_SCOPE=""
WORKFLOW_DESCRIPTION=""

# Change TO:
# Only initialize if not already set (allows parent to pre-set values)
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
WORKFLOW_DESCRIPTION="${WORKFLOW_DESCRIPTION:-}"
```

**Benefits**:
- Eliminates need for save-before-source workaround in all commands
- Simplifies initialization blocks by ~3 lines per command
- More intuitive variable lifecycle (set once, persist naturally)

**Risks**:
- Changes shared library behavior (affects /coordinate, /orchestrate, /supervise)
- Requires testing all 3 commands to verify no regressions
- May mask bugs where variables should be unset but aren't

**Scope**: 2-line change in workflow-state-machine.sh, remove workaround from 1 command (/coordinate)

### 3. Standardize Library Re-sourcing Across All Multi-Block Commands (High Priority)

**Problem**: /supervise uses multi-bash-block architecture but does NOT re-source libraries in subsequent blocks, violating Pattern 4 from bash-block-execution-model.md.

**Solution**: Add re-sourcing pattern to /supervise matching /coordinate's implementation.

**Implementation** (supervise.md: add to all state handler blocks):
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
source "${LIB_DIR}/unified-logger.sh"
source "${LIB_DIR}/error-handling.sh"
```

**Benefits**:
- Fixes potential bugs in /supervise where library functions are called but not available
- Standardizes pattern across all orchestration commands
- Aligns with documented best practices in bash-block-execution-model.md

**Risks**:
- /supervise may work currently because it doesn't call library functions in state handlers
- Adding re-sourcing increases command file size by ~70 lines (5 blocks × 14 lines each)

**Scope**: ~70 lines added to /supervise

### 4. Extract Re-sourcing Logic to Shared Snippet (Code Reduction)

**Problem**: /coordinate contains 10 identical 14-line library re-sourcing blocks (140 lines total repetitive code).

**Solution**: Extract re-sourcing logic to shared source-able snippet or library function.

**Implementation**: Create `.claude/lib/source-libraries-snippet.sh`:
```bash
#!/usr/bin/env bash
# Shared library re-sourcing pattern for multi-block commands
# Usage: source "${CLAUDE_PROJECT_DIR}/.claude/lib/source-libraries-snippet.sh"

if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/unified-logger.sh"
source "${LIB_DIR}/verification-helpers.sh"
```

Then in /coordinate bash blocks:
```bash
# FROM (14 lines):
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/unified-logger.sh"
source "${LIB_DIR}/verification-helpers.sh"

# TO (1 line):
source "${CLAUDE_PROJECT_DIR}/.claude/lib/source-libraries-snippet.sh"
```

**Benefits**:
- Reduces /coordinate from 1596 → 1466 lines (130-line reduction, 8% smaller)
- Single source of truth for required libraries
- Easier to add/remove libraries (change 1 file, not 10 blocks)
- Could apply to /supervise when adding re-sourcing (Recommendation #3)

**Risks**:
- Adds one more file to maintain
- Slight indirection (1 source statement that sources 6 libraries)
- CLAUDE_PROJECT_DIR detection happens in snippet, not visible in command

**Scope**: Create 1 new file (15 lines), modify 10 blocks in /coordinate (net -130 lines)

**Note**: File `.claude/lib/source-libraries-snippet.sh` already exists (discovered via grep output), could be enhanced or reused.

### 5. Document WORKFLOW_SCOPE Lifecycle in Architecture Docs (Documentation)

**Problem**: The save-before-source pattern is undocumented and non-obvious to future maintainers.

**Solution**: Add WORKFLOW_SCOPE case study to bash-block-execution-model.md

**Implementation**: Add new section to bash-block-execution-model.md:

```markdown
### Example 3: WORKFLOW_SCOPE Pre-initialization Issue

**Problem**: Library pre-initialization overwrites parent process values.

[... document current pattern, alternatives, tradeoffs ...]
```

**Benefits**:
- Future-proof architecture knowledge
- Helps maintainers understand rationale for save-before-source pattern
- Informs decision between Recommendation #1 (defensive restoration) vs #2 (library changes)

**Scope**: ~50 lines added to bash-block-execution-model.md

### 6. Prioritized Implementation Order

**Recommended sequence** (balancing risk, impact, and dependencies):

1. **Recommendation #5** (Documentation) - **Immediate, no risk**
   - Documents current state and architectural decisions
   - Informs implementation of other recommendations

2. **Recommendation #1** (Defensive Restoration) - **Low risk, immediate benefit**
   - Improves resilience of /coordinate without library changes
   - Can be implemented independently
   - Provides graceful degradation

3. **Recommendation #4** (Extract Re-sourcing Snippet) - **Low risk, code quality benefit**
   - Reduces code duplication in /coordinate
   - Simplifies future re-sourcing additions (e.g., for Recommendation #3)

4. **Recommendation #3** (Standardize /supervise) - **Medium risk, completeness benefit**
   - Fixes potential bugs in /supervise
   - Standardizes pattern across commands
   - Easier with Recommendation #4 completed first

5. **Recommendation #2** (Library Conditional Initialization) - **Medium risk, elegance benefit**
   - Simplifies command code after Recommendations #1-4 prove patterns
   - Can be deferred if save-before-source + defensive restoration works well
   - Requires cross-command testing

## References

- /home/benjamin/.config/.claude/commands/coordinate.md (1596 lines, 10 bash blocks)
- /home/benjamin/.config/.claude/commands/orchestrate.md (581 lines, 1 bash block)
- /home/benjamin/.config/.claude/commands/supervise.md (421 lines, 5+ bash blocks)
- /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md (642 lines)
- /home/benjamin/.config/.claude/lib/state-persistence.sh (341 lines)
- /home/benjamin/.config/.claude/lib/workflow-state-machine.sh (line 75-76: pre-initialization)
- /home/benjamin/.config/.claude/lib/workflow-scope-detection.sh (54 lines)
- /home/benjamin/.config/.claude/lib/workflow-initialization.sh (370 lines)
- /home/benjamin/.config/.claude/lib/unified-logger.sh (references WORKFLOW_SCOPE)
- /home/benjamin/.config/.claude/lib/error-handling.sh (references WORKFLOW_SCOPE)
- /home/benjamin/.config/.claude/lib/overview-synthesis.sh (references WORKFLOW_SCOPE)
