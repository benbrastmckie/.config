# /coordinate Command: Subprocess Isolation Fix Plan

## Metadata
- **Date**: 2025-11-07
- **Issue**: Bash subprocess isolation causes library functions to be unavailable
- **Severity**: CRITICAL - Command fails immediately at Phase 1
- **Root Cause**: Bash Tool subprocess isolation - each invocation runs in fresh subprocess
- **Files Affected**: `.claude/commands/coordinate.md`

## Executive Summary

The /coordinate command fails immediately when entering Phase 1 because bash functions sourced in Phase 0 are not available in Phase 1 due to subprocess isolation. The Bash tool runs each invocation in a separate subprocess that does not inherit functions or non-exported variables from previous invocations.

**Key Finding**: Only 1 out of 19 bash blocks (Phase 0 Step 1) properly sources libraries before using them. The remaining 18 blocks either:
1. Don't source libraries at all (16 blocks)
2. Source libraries AFTER calling functions that need them (2 blocks)

**Solution**: Implement a systematic library sourcing pattern at the beginning of every bash block that needs library functions.

## Error Trace Analysis

### Error 1: `should_run_phase: command not found` (Line 46)

**Location**: Phase 1 Research bash block (coordinate.md:343-381)

**Console Output**:
```
● Bash(should_run_phase 1 || {
        echo "⏭️  Skipping Phase 1 (Research)"…)
  ⎿ ⏭️  Skipping Phase 1 (Research)
    /run/current-system/sw/bin/bash: line 44: should_run_phase: command not found
```

**Code Analysis**:
```bash
# Line 343: START OF BASH BLOCK
```bash
should_run_phase 1 || {        # Line 344: ❌ Function not available!
  echo "⏭️  Skipping Phase 1 (Research)"
  display_brief_summary         # Line 346: ❌ Also not available!
  exit 0
}

if command -v emit_progress &>/dev/null; then
  emit_progress "1" "..."       # Line 351: ❌ Also not available!
fi

# ... 25 lines later ...

# Line 377-378: ✅ Libraries finally sourced - TOO LATE!
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-sourcing.sh"
source_required_libraries || exit 1
```

**Why it fails**:
1. Function `should_run_phase()` was defined in Phase 0 Step 1 by sourcing workflow-detection.sh
2. Phase 1 runs in a NEW subprocess that does not inherit functions from Phase 0
3. Function is called BEFORE libraries are sourced in this block

### Error 2: `emit_progress: command not found` (Line 101)

**Console Output**:
```
● Bash(# Set up environment variables from previous initialization
      WORKFLOW_SCOPE="research-and-plan"…)
  ⎿  Error: Exit code 127
     /run/current-system/sw/bin/bash: line 83: emit_progress: command not found
```

**Why it fails**:
Claude manually sourced workflow-detection.sh in a previous bash block to fix Error 1, but the NEXT bash block (a new subprocess) doesn't have unified-logger.sh sourced, so `emit_progress()` is not available.

### Error 3: Phase 0 Step 2 function verification fails

**Location**: Phase 0 Step 2 bash block (coordinate.md:117-225)

**Code Analysis**:
```bash
# Line 117: START OF BASH BLOCK
# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# NO LIBRARY SOURCING HERE!

# Verify critical functions
case "$WORKFLOW_SCOPE" in
  research-and-plan|debug-only|full-implementation)
    REQUIRED_FUNCTIONS=("should_run_phase" "emit_progress" ...)  # ❌ None of these exist!
    ;;
esac

for func in "${REQUIRED_FUNCTIONS[@]}"; do
  if ! command -v "$func" >/dev/null 2>&1; then
    MISSING_FUNCTIONS+=("$func")  # ❌ ALL will be reported as missing
  fi
done
```

**Why it fails**:
- This bash block attempts to VERIFY that functions exist
- But it never SOURCES the libraries that define those functions
- Result: All functions are reported as missing, but execution continues (non-fatal)

## Root Cause: Bash Tool Subprocess Isolation

### How the Bash Tool Works

Each `USE the Bash tool:` invocation creates a FRESH subprocess:

```
┌─────────────────────────────────────────────────────────┐
│ Bash Tool Invocation 1 (Phase 0 Step 1)                │
│                                                         │
│ 1. Sources libraries                                    │
│ 2. Defines functions: should_run_phase(), emit_progress│
│ 3. Exports variables: WORKFLOW_SCOPE, TOPIC_PATH       │
│ 4. Subprocess EXITS                                     │
└─────────────────────────────────────────────────────────┘
                            ↓
              Functions are LOST (not inherited)
              Variables are LOST (except exported ones)
                            ↓
┌─────────────────────────────────────────────────────────┐
│ Bash Tool Invocation 2 (Phase 0 Step 2)                │
│                                                         │
│ 1. Fresh subprocess - NO functions available           │
│ 2. Variables: Only EXPORTED vars from parent available │
│ 3. Tries to call should_run_phase() → ❌ NOT FOUND     │
└─────────────────────────────────────────────────────────┘
```

### What Gets Inherited Between Subprocesses

| Item | Inherited? | Notes |
|------|-----------|-------|
| Exported variables (`export FOO=bar`) | ✅ YES | Available in child processes |
| Non-exported variables (`FOO=bar`) | ❌ NO | Lost when subprocess exits |
| Functions (`function foo() {}`) | ❌ NO | Never inherited, even with `export -f` |
| Sourced libraries | ❌ NO | Must be re-sourced in each subprocess |

### Why Phase 0 Step 1 Variables Are Not Available

**Phase 0 Step 1 exports these variables**:
```bash
export CLAUDE_PROJECT_DIR
export LIB_DIR
export WORKFLOW_DESCRIPTION
export WORKFLOW_SCOPE
export PHASES_TO_EXECUTE
export SKIP_PHASES
```

**BUT Phase 1 tries to use**:
```bash
echo "$WORKFLOW_DESCRIPTION"  # This SHOULD work (exported)
should_run_phase 1             # This FAILS (function not exported)
emit_progress "1" "..."        # This FAILS (function not exported)
```

**Reality**: Even though variables are exported, many bash blocks RE-INITIALIZE them from scratch instead of using exported values, leading to potential inconsistencies.

## Complete Analysis of All 19 Bash Blocks

### Phase 0: Initialization

| Block | Line | Library Sourcing | Functions Used | Status |
|-------|------|------------------|----------------|--------|
| **Step 1** | 21-113 | ✅ COMPLETE | - | ✅ WORKS |
| **Step 2** | 115-225 | ❌ NONE | should_run_phase, emit_progress, save_checkpoint, restore_checkpoint, display_brief_summary (defined inline), transition_to_phase (defined inline) | ❌ FAILS verification, defines functions inline |
| **Step 3** | 227-316 | ✅ RE-SOURCES | detect_workflow_scope, initialize_workflow_paths, emit_progress, reconstruct_report_paths_array | ⚠️ WORKS but redundant sourcing |

### Phase 1: Research

| Block | Line | Library Sourcing | Functions Used | Status |
|-------|------|------------------|----------------|--------|
| **Research Start** | 341-381 | ⚠️ TOO LATE (line 377) | should_run_phase (344), display_brief_summary (346), emit_progress (351, 380), source_required_libraries (378) | ❌ FIRST CRITICAL FAILURE |
| **Verification** | 406-457 | ❌ NONE | emit_progress, verify_file_created, save_checkpoint, store_phase_metadata | ❌ FAILS |
| **Overview Synthesis** | 492-523 | ❌ NONE | verify_file_created, emit_progress | ❌ FAILS (conditional) |

### Phase 2: Planning

| Block | Line | Library Sourcing | Functions Used | Status |
|-------|------|------------------|----------------|--------|
| **Planning Start** | 530-589 | ❌ NONE | should_run_phase, display_brief_summary, emit_progress | ❌ FAILS |
| **Verification** | 591-654 | ❌ NONE | verify_file_created, emit_progress, save_checkpoint, store_phase_metadata, apply_pruning_policy | ❌ FAILS |

### Phase 3: Wave-Based Implementation

| Block | Line | Library Sourcing | Functions Used | Status |
|-------|------|------------------|----------------|--------|
| **Implementation Start** | 660-734 | ❌ NONE | should_run_phase, emit_progress, analyze_dependencies | ❌ FAILS |
| **Verification** | 736-786 | ❌ NONE | verify_file_created, emit_progress, save_checkpoint, store_phase_metadata, apply_pruning_policy | ❌ FAILS |

### Phase 4: Testing

| Block | Line | Library Sourcing | Functions Used | Status |
|-------|------|------------------|----------------|--------|
| **Testing Start** | 792-828 | ❌ NONE | should_run_phase, emit_progress | ❌ FAILS |
| **Verification** | 830-870 | ❌ NONE | emit_progress, save_checkpoint, store_phase_metadata | ❌ FAILS |

### Phase 5: Debug (Conditional)

| Block | Line | Library Sourcing | Functions Used | Status |
|-------|------|------------------|----------------|--------|
| **Debug Start** | 876-911 | ❌ NONE | emit_progress | ❌ FAILS |
| **Debug Iteration 1** | 913-945 | ❌ NONE | emit_progress, verify_file_created | ❌ FAILS |
| **Debug Iteration 2** | 947-975 | ❌ NONE | emit_progress | ❌ FAILS |
| **Debug Iteration 3** | 977-1010 | ❌ NONE | emit_progress, store_phase_metadata | ❌ FAILS |

### Phase 6: Documentation (Conditional)

| Block | Line | Library Sourcing | Functions Used | Status |
|-------|------|------------------|----------------|--------|
| **Documentation Start** | 1016-1053 | ❌ NONE | emit_progress, display_brief_summary | ❌ FAILS |
| **Verification** | 1055-1090 | ❌ NONE | verify_file_created, emit_progress, store_phase_metadata, prune_workflow_metadata, display_brief_summary | ❌ FAILS |

### Summary Statistics

- **Total bash blocks**: 19
- **Blocks with proper library sourcing**: 1 (5%)
- **Blocks with late library sourcing**: 1 (5%)
- **Blocks with redundant library sourcing**: 1 (5%)
- **Blocks with NO library sourcing**: 16 (84%)
- **Blocks that will fail**: 18 (95%)

## Required Functions by Phase

### Core Workflow Functions (workflow-detection.sh)
- `should_run_phase()` - Check if phase should execute based on PHASES_TO_EXECUTE
- Used in: Phase 1, 2, 3, 4 start blocks

### Progress Logging Functions (unified-logger.sh)
- `emit_progress()` - Log progress messages
- Used in: ALL blocks after Phase 0 Step 1

### Checkpoint Functions (checkpoint-utils.sh)
- `save_checkpoint()` - Save workflow state
- `restore_checkpoint()` - Restore workflow state
- `store_phase_metadata()` - Store phase completion metadata
- Used in: All verification blocks

### Verification Functions (verification-helpers.sh)
- `verify_file_created()` - Verify file was created at expected path
- Used in: All verification blocks (Phase 1, 2, 3, 4, 5, 6)

### Context Management Functions (context-pruning.sh)
- `apply_pruning_policy()` - Prune context after phase completion
- `prune_workflow_metadata()` - Prune workflow-level metadata
- Used in: Phase 2, 3, 6 verification blocks

### Workflow Initialization Functions (workflow-initialization.sh)
- `initialize_workflow_paths()` - Calculate all artifact paths
- `reconstruct_report_paths_array()` - Rebuild REPORT_PATHS array
- Used in: Phase 0 Step 3

### Overview Synthesis Functions (overview-synthesis.sh)
- `should_synthesize_overview()` - Determine if overview should be created
- `calculate_overview_path()` - Calculate overview file path
- `get_synthesis_skip_reason()` - Get reason for skipping synthesis
- Used in: Phase 1 overview block

### Helper Functions (defined inline in Phase 0 Step 2, but need to be in ALL blocks)
- `display_brief_summary()` - Display workflow completion summary
- `transition_to_phase()` - Transition between phases with checkpoint

## Solution: Systematic Library Sourcing Pattern

### Standard Library Sourcing Block

Add this to the **BEGINNING** of every bash block (except Phase 0 Step 1):

```bash
# ============================================================================
# LIBRARY SOURCING (required for subprocess isolation)
# ============================================================================

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Determine workflow scope (use exported value or default)
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-research-and-plan}"

# Source library-sourcing.sh
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
if [ ! -f "$LIB_DIR/library-sourcing.sh" ]; then
  echo "ERROR: library-sourcing.sh not found" >&2
  exit 1
fi
source "$LIB_DIR/library-sourcing.sh"

# Define required libraries based on scope
case "$WORKFLOW_SCOPE" in
  research-only)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "verification-helpers.sh")
    ;;
  research-and-plan)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "verification-helpers.sh")
    ;;
  full-implementation)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "dependency-analyzer.sh" "context-pruning.sh" "error-handling.sh" "verification-helpers.sh")
    ;;
  debug-only)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "error-handling.sh" "verification-helpers.sh")
    ;;
esac

# Source required libraries
if ! source_required_libraries "${REQUIRED_LIBS[@]}"; then
  echo "ERROR: Failed to source required libraries for scope: $WORKFLOW_SCOPE" >&2
  exit 1
fi

# Define helper functions
display_brief_summary() {
  echo ""
  echo "✓ Workflow complete: $WORKFLOW_SCOPE"
  case "$WORKFLOW_SCOPE" in
    research-only)
      local report_count=${#REPORT_PATHS[@]}
      echo "Created $report_count research reports in: $TOPIC_PATH/reports/"
      ;;
    research-and-plan)
      local report_count=${#REPORT_PATHS[@]}
      echo "Created $report_count reports + 1 plan in: $TOPIC_PATH/"
      echo "→ Run: /implement $PLAN_PATH"
      ;;
    full-implementation)
      echo "Implementation complete. Summary: $SUMMARY_PATH"
      ;;
    debug-only)
      echo "Debug analysis complete: $DEBUG_REPORT"
      ;;
    *)
      echo "Workflow artifacts available in: $TOPIC_PATH"
      ;;
  esac
  echo ""
}

transition_to_phase() {
  local from_phase="$1"
  local to_phase="$2"
  local artifacts_json="${3:-{}}"

  if command -v emit_progress >/dev/null 2>&1; then
    emit_progress "$from_phase" "Phase $from_phase complete, transitioning to Phase $to_phase"
  fi

  if command -v save_checkpoint >/dev/null 2>&1; then
    save_checkpoint "coordinate" "phase_${from_phase}" "$artifacts_json" &
    local checkpoint_pid=$!
  fi

  if command -v store_phase_metadata >/dev/null 2>&1; then
    store_phase_metadata "phase_${from_phase}" "complete" "$artifacts_json"
  fi

  if command -v apply_pruning_policy >/dev/null 2>&1; then
    apply_pruning_policy "phase_${from_phase}" "$WORKFLOW_SCOPE"
  fi

  [ -n "${checkpoint_pid:-}" ] && wait $checkpoint_pid 2>/dev/null || true

  if command -v emit_progress >/dev/null 2>&1; then
    emit_progress "$to_phase" "Phase $to_phase starting"
  fi
}

# ============================================================================
# END LIBRARY SOURCING
# ============================================================================
```

### Optimization: Create Reusable Library Sourcing File

Instead of repeating 80+ lines in every bash block, create a single reusable sourcing script:

**File**: `.claude/lib/coordinate-subprocess-init.sh`

```bash
#!/bin/bash
# coordinate-subprocess-init.sh
# Reusable initialization for /coordinate bash subprocesses
#
# USAGE: source "${CLAUDE_PROJECT_DIR}/.claude/lib/coordinate-subprocess-init.sh"

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Determine workflow scope (use exported value or default)
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-research-and-plan}"

# Source library-sourcing.sh
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
if [ ! -f "$LIB_DIR/library-sourcing.sh" ]; then
  echo "ERROR: library-sourcing.sh not found" >&2
  return 1
fi
source "$LIB_DIR/library-sourcing.sh"

# Define required libraries based on scope
case "$WORKFLOW_SCOPE" in
  research-only)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "verification-helpers.sh")
    ;;
  research-and-plan)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "verification-helpers.sh")
    ;;
  full-implementation)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "dependency-analyzer.sh" "context-pruning.sh" "error-handling.sh" "verification-helpers.sh")
    ;;
  debug-only)
    REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "error-handling.sh" "verification-helpers.sh")
    ;;
esac

# Source required libraries
if ! source_required_libraries "${REQUIRED_LIBS[@]}"; then
  echo "ERROR: Failed to source required libraries for scope: $WORKFLOW_SCOPE" >&2
  return 1
fi

# Define helper functions
display_brief_summary() {
  echo ""
  echo "✓ Workflow complete: $WORKFLOW_SCOPE"
  case "$WORKFLOW_SCOPE" in
    research-only)
      local report_count=${#REPORT_PATHS[@]}
      echo "Created $report_count research reports in: $TOPIC_PATH/reports/"
      ;;
    research-and-plan)
      local report_count=${#REPORT_PATHS[@]}
      echo "Created $report_count reports + 1 plan in: $TOPIC_PATH/"
      echo "→ Run: /implement $PLAN_PATH"
      ;;
    full-implementation)
      echo "Implementation complete. Summary: $SUMMARY_PATH"
      ;;
    debug-only)
      echo "Debug analysis complete: $DEBUG_REPORT"
      ;;
    *)
      echo "Workflow artifacts available in: $TOPIC_PATH"
      ;;
  esac
  echo ""
}

transition_to_phase() {
  local from_phase="$1"
  local to_phase="$2"
  local artifacts_json="${3:-{}}"

  if command -v emit_progress >/dev/null 2>&1; then
    emit_progress "$from_phase" "Phase $from_phase complete, transitioning to Phase $to_phase"
  fi

  if command -v save_checkpoint >/dev/null 2>&1; then
    save_checkpoint "coordinate" "phase_${from_phase}" "$artifacts_json" &
    local checkpoint_pid=$!
  fi

  if command -v store_phase_metadata >/dev/null 2>&1; then
    store_phase_metadata "phase_${from_phase}" "complete" "$artifacts_json"
  fi

  if command -v apply_pruning_policy >/dev/null 2>&1; then
    apply_pruning_policy "phase_${from_phase}" "$WORKFLOW_SCOPE"
  fi

  [ -n "${checkpoint_pid:-}" ] && wait $checkpoint_pid 2>/dev/null || true

  if command -v emit_progress >/dev/null 2>&1; then
    emit_progress "$to_phase" "Phase $to_phase starting"
  fi
}
```

**Then in each bash block, use just 3 lines**:

```bash
# Initialize subprocess environment (libraries + helper functions)
source "${CLAUDE_PROJECT_DIR:=$(git rev-parse --show-toplevel 2>/dev/null || pwd)}/.claude/lib/coordinate-subprocess-init.sh"

# Rest of bash block code...
```

## Implementation Plan

### Phase 1: Create Reusable Sourcing Script (RECOMMENDED)

1. Create `.claude/lib/coordinate-subprocess-init.sh` with the content above
2. Test the script in isolation:
   ```bash
   WORKFLOW_SCOPE=research-and-plan source /home/benjamin/.config/.claude/lib/coordinate-subprocess-init.sh
   # Verify functions are available
   command -v should_run_phase && echo "✓ should_run_phase"
   command -v emit_progress && echo "✓ emit_progress"
   ```

### Phase 2: Fix Critical Blocks (Minimal Viable Fix)

Fix these 3 blocks to get research-and-plan workflows working:

1. **Phase 1 Research Start** (line 341-381)
   - Add sourcing at line 344 (BEFORE `should_run_phase`)
   - Remove redundant sourcing at lines 377-378

2. **Phase 1 Verification** (line 406-457)
   - Add sourcing at line 407

3. **Phase 2 Planning Start** (line 530-589)
   - Add sourcing at line 531

### Phase 3: Fix All Remaining Blocks (Complete Fix)

Systematically add sourcing to all 16 remaining bash blocks:

| Priority | Block | Line | Reason |
|----------|-------|------|--------|
| HIGH | Phase 2 Verification | 591 | Complete research-and-plan workflows |
| HIGH | Verification Helpers | 317 | Used by all verification blocks |
| MEDIUM | Phase 0 Step 2 | 115 | Fix function verification |
| MEDIUM | Phase 1 Overview | 492 | Conditional research-only workflows |
| MEDIUM | Phase 3 Implementation Start | 660 | Full-implementation workflows |
| MEDIUM | Phase 3 Verification | 736 | Full-implementation workflows |
| MEDIUM | Phase 4 Testing Start | 792 | Full-implementation workflows |
| MEDIUM | Phase 4 Verification | 830 | Full-implementation workflows |
| LOW | Phase 5 blocks (4 blocks) | 876-1010 | Conditional debug workflows |
| LOW | Phase 6 blocks (2 blocks) | 1016-1090 | Conditional documentation |

### Phase 4: Optimize Phase 0 Step 3

Phase 0 Step 3 currently re-sources libraries and re-initializes variables. This is redundant since we're now sourcing in every block. Consider:

**Option A**: Keep as-is (defensive programming, works correctly)
**Option B**: Simplify to just use sourcing script like other blocks
**Option C**: Remove entirely if Step 2 is enhanced

Recommendation: **Option A** - keep as-is for now, revisit after other blocks are fixed

## Testing Plan

### Unit Tests

1. **Test sourcing script**:
   ```bash
   WORKFLOW_SCOPE=research-and-plan source /home/benjamin/.config/.claude/lib/coordinate-subprocess-init.sh
   for func in should_run_phase emit_progress verify_file_created save_checkpoint display_brief_summary transition_to_phase; do
     command -v "$func" && echo "✓ $func" || echo "✗ $func MISSING"
   done
   ```

2. **Test each scope**:
   ```bash
   for scope in research-only research-and-plan full-implementation debug-only; do
     echo "Testing scope: $scope"
     WORKFLOW_SCOPE=$scope source /home/benjamin/.config/.claude/lib/coordinate-subprocess-init.sh
     echo "✓ $scope sourcing successful"
   done
   ```

### Integration Tests

1. **Phase 1 only** (after minimal viable fix):
   ```bash
   # Create a simple test workflow that only triggers Phase 1
   /coordinate "research best practices for bash scripting"
   ```
   **Expected**: Phase 1 completes without "command not found" errors

2. **Research-and-plan workflow** (after Phase 2 complete):
   ```bash
   /coordinate "research and plan implementation of a simple feature"
   ```
   **Expected**: Phases 1-2 complete successfully, plan file created

3. **Full workflow** (after all fixes):
   ```bash
   /coordinate "research, plan, and implement a test feature"
   ```
   **Expected**: All phases complete successfully

### Regression Tests

After applying fixes, verify that:
- Phase 0 still works correctly
- All exported variables are still available
- Checkpoint/resume functionality works
- All workflow scopes (research-only, research-and-plan, full-implementation, debug-only) work

## Specific Code Changes Required

### Change 1: Create coordinate-subprocess-init.sh

**File**: `.claude/lib/coordinate-subprocess-init.sh`
**Action**: CREATE NEW FILE
**Content**: See "Optimization: Create Reusable Library Sourcing File" section above

### Change 2: Phase 1 Research Start (CRITICAL)

**File**: `.claude/commands/coordinate.md`
**Line**: 341-381

**BEFORE**:
```bash
USE the Bash tool:

```bash
should_run_phase 1 || {
  echo "⏭️  Skipping Phase 1 (Research)"
  display_brief_summary
  exit 0
}

if command -v emit_progress &>/dev/null; then
  emit_progress "1" "Phase 1: Research (parallel agent invocation)"
fi

# Determine research complexity (1-4 topics)
RESEARCH_COMPLEXITY=2

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"; then
  RESEARCH_COMPLEXITY=3
fi

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "multi-.*system|cross-.*platform|distributed|microservices"; then
  RESEARCH_COMPLEXITY=4
fi

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "^(fix|update|modify).*(one|single|small)"; then
  RESEARCH_COMPLEXITY=1
fi

echo "Research Complexity Score: $RESEARCH_COMPLEXITY topics"

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-sourcing.sh"
source_required_libraries || exit 1

emit_progress "1" "Invoking $RESEARCH_COMPLEXITY research agents in parallel"
```

**AFTER**:
```bash
USE the Bash tool:

```bash
# Initialize subprocess environment (libraries + helper functions)
source "${CLAUDE_PROJECT_DIR:=$(git rev-parse --show-toplevel 2>/dev/null || pwd)}/.claude/lib/coordinate-subprocess-init.sh"

should_run_phase 1 || {
  echo "⏭️  Skipping Phase 1 (Research)"
  display_brief_summary
  exit 0
}

emit_progress "1" "Phase 1: Research (parallel agent invocation)"

# Determine research complexity (1-4 topics)
RESEARCH_COMPLEXITY=2

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"; then
  RESEARCH_COMPLEXITY=3
fi

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "multi-.*system|cross-.*platform|distributed|microservices"; then
  RESEARCH_COMPLEXITY=4
fi

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "^(fix|update|modify).*(one|single|small)"; then
  RESEARCH_COMPLEXITY=1
fi

echo "Research Complexity Score: $RESEARCH_COMPLEXITY topics"

emit_progress "1" "Invoking $RESEARCH_COMPLEXITY research agents in parallel"
```

**Changes**:
1. ✅ Added sourcing at the very beginning
2. ✅ Removed redundant `if command -v emit_progress` check (function is always available after sourcing)
3. ✅ Removed redundant CLAUDE_PROJECT_DIR detection (done in sourcing script)
4. ✅ Removed manual library sourcing (done in sourcing script)

### Change 3: Phase 1 Verification (CRITICAL)

**File**: `.claude/commands/coordinate.md`
**Line**: 406-457

**BEFORE**:
```bash
USE the Bash tool:

```bash
emit_progress "1" "All research agents invoked - awaiting completion"

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Source verification helpers
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh"
else
  echo "ERROR: verification-helpers.sh not found"
  exit 1
fi

# Verify all research reports created
echo -n "Verifying research reports ($RESEARCH_COMPLEXITY): "
```

**AFTER**:
```bash
USE the Bash tool:

```bash
# Initialize subprocess environment (libraries + helper functions)
source "${CLAUDE_PROJECT_DIR:=$(git rev-parse --show-toplevel 2>/dev/null || pwd)}/.claude/lib/coordinate-subprocess-init.sh"

emit_progress "1" "All research agents invoked - awaiting completion"

# Verify all research reports created
echo -n "Verifying research reports ($RESEARCH_COMPLEXITY): "
```

**Changes**:
1. ✅ Added sourcing at the beginning
2. ✅ Removed redundant CLAUDE_PROJECT_DIR detection
3. ✅ Removed manual verification-helpers.sh sourcing (included in init script)

### Change 4-19: Apply Same Pattern to All Remaining Blocks

For ALL other bash blocks (15 remaining), apply the same transformation:

1. Add sourcing line at the VERY BEGINNING:
   ```bash
   # Initialize subprocess environment (libraries + helper functions)
   source "${CLAUDE_PROJECT_DIR:=$(git rev-parse --show-toplevel 2>/dev/null || pwd)}/.claude/lib/coordinate-subprocess-init.sh"
   ```

2. Remove any redundant:
   - `if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then ... fi` blocks
   - `source "${CLAUDE_PROJECT_DIR}/.claude/lib/*` lines
   - `if command -v function_name` checks before using functions

## Success Criteria

- ✅ coordinate-subprocess-init.sh passes unit tests
- ✅ Phase 1 executes without "command not found" errors
- ✅ Phase 2 executes without errors
- ✅ Complete research-and-plan workflow succeeds
- ✅ All workflow scopes work correctly
- ✅ No regressions in Phase 0 functionality
- ✅ Checkpoint/resume functionality preserved

## Recommendations

1. **Create the sourcing script first** - This makes all subsequent changes trivial (1-2 lines per block)

2. **Test incrementally** - After fixing 2-3 blocks, test to ensure the pattern works

3. **Use version control** - Commit after each phase of fixes with clear commit messages:
   - "feat: create coordinate-subprocess-init.sh for library sourcing"
   - "fix: add subprocess init to Phase 1 Research blocks"
   - "fix: add subprocess init to Phase 2 Planning blocks"
   - etc.

4. **Document the pattern** - Update `.claude/docs/guides/coordinate-command-guide.md` to explain:
   - Why every bash block needs sourcing
   - How to use coordinate-subprocess-init.sh
   - Troubleshooting subprocess isolation issues

5. **Consider extracting to pattern** - This subprocess isolation issue likely affects other multi-bash-block commands. Consider:
   - Creating a general "command-subprocess-init.sh" pattern
   - Documenting in command development guide
   - Applying to /orchestrate, /implement, etc. if they have similar issues

## Related Documentation

- Console Output: `/home/benjamin/.config/.claude/specs/coordinate_output.md`
- Command File: `.claude/commands/coordinate.md`
- Command Guide: `.claude/docs/guides/coordinate-command-guide.md`
- Library Sourcing: `.claude/lib/library-sourcing.sh`
- Workflow Detection: `.claude/lib/workflow-detection.sh`

## Appendix: Quick Reference

### Commands Affected by This Issue

Any command with multiple bash blocks potentially has this issue:
- `/coordinate` (19 blocks) - CONFIRMED AFFECTED
- `/orchestrate` - needs audit
- `/implement` - needs audit
- `/supervise` - needs audit

### Libraries and Their Key Functions

- **workflow-detection.sh**: should_run_phase()
- **unified-logger.sh**: emit_progress()
- **checkpoint-utils.sh**: save_checkpoint(), restore_checkpoint(), store_phase_metadata()
- **verification-helpers.sh**: verify_file_created()
- **context-pruning.sh**: apply_pruning_policy(), prune_workflow_metadata()
- **workflow-initialization.sh**: initialize_workflow_paths(), reconstruct_report_paths_array()
- **overview-synthesis.sh**: should_synthesize_overview(), calculate_overview_path(), get_synthesis_skip_reason()

### Exported Variables from Phase 0 Step 1

```bash
export CLAUDE_PROJECT_DIR
export LIB_DIR
export WORKFLOW_DESCRIPTION
export WORKFLOW_SCOPE
export PHASES_TO_EXECUTE
export SKIP_PHASES
```

These SHOULD be available in all subsequent bash blocks, but due to re-initialization in some blocks, they may be inconsistent. The sourcing script preserves `WORKFLOW_SCOPE` via `${WORKFLOW_SCOPE:-research-and-plan}`.
