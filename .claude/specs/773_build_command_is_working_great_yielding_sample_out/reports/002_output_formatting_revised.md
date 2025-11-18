# Output Formatting Improvements - Revised Research Report

## Metadata
- **Date**: 2025-11-17
- **Report Type**: Post-implementation analysis and revised recommendations
- **Prior Report**: 001_output_formatting_improvements.md
- **Status**: Revision after failed implementation

## Executive Summary

The original implementation of Options 3+5 from report 001 failed due to fundamental misunderstandings about how Claude Code displays bash blocks. The implementation introduced bugs (`set -uo pipefail` causing unbound variable errors, broken variable persistence between blocks) and achieved no meaningful output improvement. This revised report documents lessons learned and proposes alternative approaches that address the actual constraints.

**Key Finding**: The core problem is architectural, not cosmetic. The output noise comes from having too many separate bash blocks, each re-executing boilerplate code. No amount of output formatting can fix this - the solution requires reducing the number of blocks and consolidating operations.

## Post-Mortem: Why the Original Implementation Failed

### Failure 1: Misunderstanding Claude Code Display Behavior

**What we assumed**: Option 5 stated we could change bash block descriptions from `Bash(set +H  # CRITICAL...)` to `Bash(Initializing build workflow)`.

**Reality**: Claude Code displays the first few lines of the actual bash block content, not a configurable description parameter. The `# Description:` comment we added was just another line that Claude Code displayed - followed by `set +H`.

**Result**: Output looked like:
```
● Bash(# Description: Capture research workflow arguments
      set +H…)
```

This is no better than before - just added another line.

### Failure 2: Library Strict Mode Breaks Calling Scripts

**What we did**: Added `set -uo pipefail` to output-utils.sh (line 44) to ensure robust error handling.

**Reality**: When a library sets `set -u` (treat unset variables as errors), it breaks any calling script that uses variables before they're set. The research.md workflow crashed with:
```
/run/current-system/sw/bin/bash: line 117: RESEARCH_COMPLEXITY: unbound variable
```

**Lesson**: Libraries should NEVER set shell options that affect the calling environment. Let the calling script control error handling.

### Failure 3: Subprocess Variable Isolation

**What we assumed**: Variables set in Part 2's bash block would be available in Part 3's bash block.

**Reality**: Each bash block in a markdown command file runs in a separate subprocess. Variables do not persist. The implementation needed explicit file-based persistence between blocks, which was incomplete.

**Result**: Variables like `$WORKFLOW_DESCRIPTION` and `$RESEARCH_COMPLEXITY` were undefined in subsequent blocks.

### Failure 4: Added Complexity Without Benefit

**What we created**:
- New library file (output-utils.sh, 193 lines)
- Modified 4 command files (research.md, build.md, plan.md, coordinate.md)
- Added emit_status/emit_detail/emit_debug functions
- Added detect_project_dir() with caching

**What we achieved**: Nothing. The output was actually worse due to the bugs introduced.

**Lesson**: Don't add abstraction layers unless they solve the actual problem. The emit_* functions only help if someone sets DEBUG=1/2, which adds friction without addressing the core display issue.

## Revised Understanding of the Problem

### The Real Issues

1. **Too many bash blocks** - Each workflow command has 6-11 separate bash blocks, each displayed as a truncated item in Claude Code
2. **Each block re-executes boilerplate** - Project detection, library sourcing repeated 6-11 times per workflow
3. **Verbose inline diagnostics** - DIAGNOSTIC/POSSIBLE CAUSES/TROUBLESHOOTING blocks print 10+ lines for each potential error
4. **No output suppression** - Every operation emits output, creating noise

### What We Cannot Change

- **Claude Code display behavior** - It will always show the first few lines of each bash block
- **Subprocess isolation** - Each bash block is a separate process
- **The need for `set +H`** - History expansion must be disabled in each block

### What We Can Change

- **Number of bash blocks** - Consolidate operations
- **Output volume per block** - Suppress intermediate output
- **Where diagnostics go** - Write to file instead of stdout
- **Boilerplate repetition** - Move to library functions called once

## Revised Recommendations

### Option A: Block Consolidation (High Impact, Medium Effort)

**Goal**: Reduce bash blocks from 7+ to 2-3 per workflow command.

**Approach**:
Restructure each workflow command to have:
1. **Block 1: Setup** - All initialization in one block
2. **Block 2: Execute** - Main workflow execution
3. **Block 3: Cleanup** - Completion and state persistence

**Implementation**:

Create `workflow-init.sh` library function:
```bash
# workflow-init.sh
init_workflow() {
  local workflow_type="$1"
  local workflow_description="$2"

  # Detect project directory (cached)
  if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  fi
  export CLAUDE_PROJECT_DIR

  # Source all libraries (order matters)
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
  # ... other libraries

  # Initialize state machine
  WORKFLOW_ID="${workflow_type}_$(date +%s)"
  init_workflow_state "$WORKFLOW_ID"
  sm_init "$workflow_description" "$workflow_type" ...

  # Persist to context file for subsequent blocks
  local context_file="${HOME}/.claude/tmp/${WORKFLOW_ID}_context.sh"
  declare -p CLAUDE_PROJECT_DIR WORKFLOW_ID > "$context_file"
  echo "$context_file"
}
```

**Before** (research.md):
```
Part 1: Capture arguments          → Block 1
Part 2: Validate arguments         → Block 2
Part 3: Initialize state machine   → Block 3
Part 3: Allocate topic directory   → Block 4
Part 3: Verify artifacts           → Block 5
Part 4: Complete workflow          → Block 6
```

**After** (research.md):
```
Block 1: Setup (capture args, validate, init state machine, allocate topic)
Block 2: Verify and complete (verify artifacts, complete workflow)
```

**Output reduction**: 6 blocks → 2 blocks = 67% fewer truncated displays

**Strengths**:
- Directly addresses the visual noise problem
- Less boilerplate repetition
- Simpler command file structure

**Weaknesses**:
- Requires significant refactoring of all command files
- Longer individual bash blocks
- Less granular error isolation

**Estimated time**: 6-8 hours

### Option B: Output Suppression (Medium Impact, Low Effort)

**Goal**: Reduce noise within existing structure by suppressing intermediate output.

**Approach**:
1. Redirect non-essential operations to `/dev/null`
2. Emit single summary line per bash block
3. Write verbose diagnostics to log file

**Implementation**:

```bash
# Suppress intermediate output
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh" 2>/dev/null

# Write diagnostics to log file, not stdout
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
if ! sm_transition "$STATE_RESEARCH"; then
  echo "ERROR: State transition failed" >&2
  echo "[$(date)] State transition to RESEARCH failed" >> "$DEBUG_LOG"
  echo "  Current state: $(sm_current_state)" >> "$DEBUG_LOG"
  echo "  See $DEBUG_LOG for details" >&2
  exit 1
fi

# Single summary line per block
echo "Research phase initialized"
```

**Diagnostic pattern change**:

**Before**:
```bash
echo "ERROR: State transition to RESEARCH failed" >&2
echo "DIAGNOSTIC Information:" >&2
echo "  - Current State: $(sm_current_state)" >&2
echo "  - Attempted Transition: → RESEARCH" >&2
echo "POSSIBLE CAUSES:" >&2
echo "  - State machine not initialized properly" >&2
echo "  - Workflow type misconfigured" >&2
echo "TROUBLESHOOTING:" >&2
echo "  - Verify sm_init called successfully" >&2
exit 1
```

**After**:
```bash
echo "ERROR: State transition failed (see ~/.claude/tmp/workflow_debug.log)" >&2
{
  echo "[$(date)] State transition to RESEARCH failed"
  echo "Current: $(sm_current_state), Target: RESEARCH"
  echo "Causes: state machine not initialized, workflow type wrong"
} >> "$DEBUG_LOG"
exit 1
```

**Output reduction**: ~50% less stdout noise, full diagnostics still available

**Strengths**:
- Minimal structural changes
- Easy to implement incrementally
- Diagnostics still available when needed

**Weaknesses**:
- Doesn't reduce number of bash blocks
- Claude Code still shows truncated blocks
- Requires checking log file for debugging

**Estimated time**: 2-3 hours

### Option C: Context-Based Variable Persistence (Low Impact, Critical for Any Approach)

**Goal**: Proper variable passing between bash blocks.

**Approach**:
Use a structured context file that each block loads and saves.

**Implementation**:

```bash
# At end of each bash block - SAVE
CONTEXT_FILE="${HOME}/.claude/tmp/workflow_context_$$.sh"
{
  echo "WORKFLOW_ID='$WORKFLOW_ID'"
  echo "WORKFLOW_DESCRIPTION='$WORKFLOW_DESCRIPTION'"
  echo "RESEARCH_COMPLEXITY='$RESEARCH_COMPLEXITY'"
  echo "RESEARCH_DIR='$RESEARCH_DIR'"
} > "$CONTEXT_FILE"

# At start of next bash block - LOAD
set +H
CONTEXT_FILE="${HOME}/.claude/tmp/workflow_context_$$.sh"
if [ -f "$CONTEXT_FILE" ]; then
  source "$CONTEXT_FILE"
fi
```

**Note**: `$$` gives the parent shell PID which is consistent across blocks in the same command execution.

**Strengths**:
- Reliable variable persistence
- Works with any number of blocks
- Simple to implement

**Weaknesses**:
- Adds boilerplate to each block
- Temp files need cleanup

**Estimated time**: 1-2 hours

### Option D: Progressive Consolidation (Recommended)

**Goal**: Incremental improvement without risky big-bang refactor.

**Approach**:
Combine Options B and C first, then Option A for highest-value commands.

**Phase 1** (2-3 hours):
- Implement Option C (context-based persistence) across all commands
- Implement Option B (output suppression) across all commands
- Test with `/research` command first

**Phase 2** (3-4 hours):
- Consolidate `/research` from 6 blocks to 2-3 blocks (Option A)
- Verify no regressions
- Document patterns learned

**Phase 3** (4-6 hours):
- Apply consolidation to `/build` and `/plan`
- Leave `/coordinate` for later (most complex)

**Total time**: 9-13 hours (phased over multiple sessions)

## Comparison Matrix

| Option | Block Reduction | Output Reduction | Complexity | Risk | Time |
|--------|----------------|------------------|------------|------|------|
| A: Consolidation | 67% | 60% | High | Medium | 6-8h |
| B: Suppression | 0% | 50% | Low | Low | 2-3h |
| C: Persistence | 0% | 0% | Low | Low | 1-2h |
| D: Progressive | 67% | 70% | Medium | Low | 9-13h |

## Recommendations

### Primary Recommendation: Option D (Progressive Consolidation)

**Rationale**:
1. Addresses root cause (too many bash blocks) while managing risk
2. Provides immediate improvements (Phase 1) before big refactor
3. Uses `/research` as pilot to validate approach before broader rollout
4. Aligns with user's stated preference for simplicity and incremental progress

### Do NOT Do

1. **Add new abstraction layers** - emit_status/emit_detail/emit_debug pattern added complexity without benefit
2. **Set shell options in libraries** - `set -uo pipefail` broke calling scripts
3. **Assume Option 5 works** - We cannot control Claude Code's bash block display
4. **Try to make bash blocks "look nice"** - Focus on having fewer blocks, not prettier blocks

### Key Success Metrics

1. **Block count per command**: Target 2-3 (down from 6-11)
2. **Lines of output per block**: Target 1-2 summary lines
3. **Error visibility**: Full stack traces still available in debug log
4. **No regressions**: Workflows complete successfully

## References

### Lessons Learned
- Original implementation in this session (reverted)
- Post-mortem analysis above

### Best Practices Sources
- Command Line Interface Guidelines (clig.dev) - Signal-to-noise ratio
- Stack Overflow - Bash subprocess variable passing patterns
- CLI Design Best Practices (codyaray.com) - Verbosity control

### Files to Modify
- `.claude/commands/research.md` - Pilot command
- `.claude/commands/build.md` - Primary command
- `.claude/commands/plan.md` - Secondary command
- `.claude/lib/` - New workflow-init.sh library (Option A only)
