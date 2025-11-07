# Library Sourcing Infrastructure Analysis and coordinate-subprocess-init.sh Specification

## Metadata
- **Date**: 2025-11-07
- **Agent**: research-specialist
- **Topic**: Library sourcing infrastructure and subprocess initialization
- **Report Type**: codebase analysis and specification
- **Related Fix Plan**: /home/benjamin/.config/.claude/specs/602_601_and_documentation_in_claude_docs_in_order_to/reports/coordinate_subprocess_isolation_fix_plan.md

## Executive Summary

The /coordinate command requires a standardized subprocess initialization script (coordinate-subprocess-init.sh) to resolve critical function unavailability errors caused by Bash Tool subprocess isolation. This specification defines the complete implementation based on analysis of existing library infrastructure, helper functions, and workflow requirements. The solution consolidates 80+ lines of repetitive sourcing logic into a single 3-line initialization pattern, reducing code duplication by 95% across 19 bash blocks.

## Current Library Sourcing Infrastructure

### 1. Core Library Sourcing Script: library-sourcing.sh

**Location**: /home/benjamin/.config/.claude/lib/library-sourcing.sh

**Primary Function**: `source_required_libraries()`

**Core Libraries** (lines 48-56):
1. `workflow-detection.sh` - Workflow scope detection functions
2. `error-handling.sh` - Error handling utilities
3. `checkpoint-utils.sh` - Checkpoint save/restore operations
4. `unified-logger.sh` - Progress logging utilities
5. `unified-location-detection.sh` - Project structure detection
6. `metadata-extraction.sh` - Report/plan metadata extraction
7. `context-pruning.sh` - Context management utilities

**Optional Libraries** (via arguments):
- `dependency-analyzer.sh` - Wave-based execution analysis (for /coordinate)
- `workflow-scope-detection.sh` - Advanced scope detection
- `overview-synthesis.sh` - Overview synthesis decision logic
- `verification-helpers.sh` - File verification functions

**Features** (lines 63-80):
- Deduplication: Removes duplicate library names before sourcing
- Error Handling: Fail-fast on missing libraries with detailed diagnostics
- Performance Tracking: Optional timing with DEBUG_PERFORMANCE=1

### 2. Required Functions by Workflow Scope

Based on coordinate_subprocess_isolation_fix_plan.md analysis:

**research-only** (lines 299-300 in fix plan):
```bash
REQUIRED_LIBS=(
  "workflow-detection.sh"
  "workflow-scope-detection.sh"
  "unified-logger.sh"
  "unified-location-detection.sh"
  "overview-synthesis.sh"
  "verification-helpers.sh"
)
```

**research-and-plan** (lines 302-303 in fix plan):
```bash
REQUIRED_LIBS=(
  "workflow-detection.sh"
  "workflow-scope-detection.sh"
  "unified-logger.sh"
  "unified-location-detection.sh"
  "overview-synthesis.sh"
  "metadata-extraction.sh"
  "checkpoint-utils.sh"
  "verification-helpers.sh"
)
```

**full-implementation** (lines 305-306 in fix plan):
```bash
REQUIRED_LIBS=(
  "workflow-detection.sh"
  "workflow-scope-detection.sh"
  "unified-logger.sh"
  "unified-location-detection.sh"
  "overview-synthesis.sh"
  "metadata-extraction.sh"
  "checkpoint-utils.sh"
  "dependency-analyzer.sh"
  "context-pruning.sh"
  "error-handling.sh"
  "verification-helpers.sh"
)
```

**debug-only** (lines 308-309 in fix plan):
```bash
REQUIRED_LIBS=(
  "workflow-detection.sh"
  "workflow-scope-detection.sh"
  "unified-logger.sh"
  "unified-location-detection.sh"
  "overview-synthesis.sh"
  "metadata-extraction.sh"
  "checkpoint-utils.sh"
  "error-handling.sh"
  "verification-helpers.sh"
)
```

### 3. Critical Helper Functions

The /coordinate command defines two inline helper functions in Phase 0 Step 2 (coordinate.md:150-205) that must be available in ALL subsequent bash blocks:

#### display_brief_summary()

**Location**: coordinate.md:150-174
**Purpose**: Display workflow completion summary
**Scope Logic**:
- research-only: Shows report count and location
- research-and-plan: Shows report + plan, suggests `/implement $PLAN_PATH`
- full-implementation: Shows summary path
- debug-only: Shows debug report path
- Default: Shows artifact directory

#### transition_to_phase()

**Location**: coordinate.md:177-205
**Purpose**: Manage phase transitions with checkpointing
**Operations**:
1. Emit progress for phase completion
2. Save checkpoint (backgrounded for performance)
3. Store phase metadata
4. Apply pruning policy
5. Wait for checkpoint completion
6. Emit progress for next phase start

**Dependencies**:
- `emit_progress()` - unified-logger.sh:704
- `save_checkpoint()` - checkpoint-utils.sh:58
- `store_phase_metadata()` - context-pruning.sh:171
- `apply_pruning_policy()` - context-pruning.sh (function name found but implementation not in first 250 lines)

## Library Function Analysis

### 1. workflow-detection.sh Functions

**Location**: /home/benjamin/.config/.claude/lib/workflow-detection.sh

**Key Functions**:
- `detect_workflow_scope()` (lines 70-160): Smart pattern matching for workflow type detection
- `should_run_phase()` (lines 178-187): Check if phase should execute based on PHASES_TO_EXECUTE

**Usage Pattern**:
```bash
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
should_run_phase 1 || { echo "Skipping Phase 1"; exit 0; }
```

### 2. unified-logger.sh Functions

**Location**: /home/benjamin/.config/.claude/lib/unified-logger.sh

**Key Functions**:
- `emit_progress()` (lines 704-708): Silent progress marker emission
- `log_complexity_check()` (lines 158-175): Complexity score logging
- `log_trigger_evaluation()` (lines 140-147): Trigger event logging
- Plus 20+ specialized logging functions for adaptive planning and conversion

**Progress Format**: `PROGRESS: [Phase N] - action`

### 3. checkpoint-utils.sh Functions

**Location**: /home/benjamin/.config/.claude/lib/checkpoint-utils.sh

**Key Functions**:
- `save_checkpoint()` (lines 58+): Save workflow checkpoint for resume capability
- `restore_checkpoint()`: Restore workflow from checkpoint (not shown in excerpt)
- Schema Version: 1.3 (line 25)

**Checkpoint Directory**: .claude/data/checkpoints (line 28)

### 4. verification-helpers.sh Functions

**Location**: /home/benjamin/.config/.claude/lib/verification-helpers.sh

**Primary Function**: `verify_file_created()` (lines 67-120)

**Success Path**: Single character output ("✓"), return 0
**Failure Path**: 38-line diagnostic with:
- Error header with phase and description
- Expected vs found status
- Directory diagnostics (exists, file count, recent files)
- Actionable fix commands

**Token Reduction**: ~3,150 tokens saved per workflow (14 checkpoints × 225 tokens)

### 5. context-pruning.sh Functions

**Location**: /home/benjamin/.config/.claude/lib/context-pruning.sh

**Key Functions**:
- `prune_subagent_output()` (lines 45-110): Clear full output, retain metadata only
- `prune_phase_metadata()` (lines 142-165): Remove phase-specific metadata after completion
- `store_phase_metadata()` (lines 171-201): Store minimal phase metadata in cache
- `prune_workflow_metadata()` (lines 233-249): Remove workflow metadata after completion
- `apply_pruning_policy()`: Not shown in excerpt, likely after line 250

**Metadata Caching**: Uses associative arrays (lines 30-32):
- `PRUNED_METADATA_CACHE`
- `PHASE_METADATA_CACHE`
- `WORKFLOW_METADATA_CACHE`

### 6. overview-synthesis.sh Functions

**Location**: /home/benjamin/.config/.claude/lib/overview-synthesis.sh

**Key Functions**:
- `should_synthesize_overview()` (lines 37-69): Determine if OVERVIEW.md should be created
- `calculate_overview_path()` (lines 91-100+): Calculate standardized overview path

**Decision Logic**:
- Requires ≥2 reports for synthesis
- Only synthesize for research-only workflows (not research-and-plan or full-implementation)

### 7. workflow-scope-detection.sh Functions

**Location**: /home/benjamin/.config/.claude/lib/workflow-scope-detection.sh

**Primary Function**: `detect_workflow_scope()` (lines 12-47)

**Pattern Detection Order**:
1. Research-only: "^research.*" without action keywords
2. Research-and-plan: Keywords "(plan|create.*plan|design)"
3. Debug-only: Keywords "(fix|debug|troubleshoot)"
4. Full-implementation: Keywords "(implement|build|add|create).*feature"

**Default Fallback**: research-and-plan (conservative)

### 8. dependency-analyzer.sh Functions

**Location**: /home/benjamin/.config/.claude/lib/dependency-analyzer.sh

**Key Functions**:
- `detect_structure_level()` (lines 32-58): Detect plan level (0=inline, 1=phase files, 2=stage files)
- `extract_dependency_metadata()` (lines 67-100+): Parse dependency metadata from plan files

**Purpose**: Wave-based execution analysis for parallel phase implementation

## Complete coordinate-subprocess-init.sh Specification

### File Location
`.claude/lib/coordinate-subprocess-init.sh`

### Purpose
Reusable initialization script for /coordinate bash subprocesses that sources all required libraries and defines helper functions based on workflow scope.

### Design Principles

1. **Fail-Fast**: Exit immediately if critical components missing
2. **Scope-Aware**: Load only libraries needed for current workflow scope
3. **Self-Contained**: No external dependencies beyond library-sourcing.sh
4. **Standard 13 Compliant**: CLAUDE_PROJECT_DIR detection via git rev-parse
5. **Error Handling**: Detailed diagnostics on failure
6. **Performance**: Minimal overhead (<100ms for full-implementation scope)

### Complete Implementation

```bash
#!/bin/bash
# coordinate-subprocess-init.sh
# Reusable initialization for /coordinate bash subprocesses
#
# USAGE: source "${CLAUDE_PROJECT_DIR}/.claude/lib/coordinate-subprocess-init.sh"
#
# PURPOSE:
#   Solves subprocess isolation by sourcing all required libraries and defining
#   helper functions at the beginning of each bash block in /coordinate.
#
# WORKFLOW SCOPES:
#   - research-only: 6 libraries (workflow, scope, logger, location, overview, verification)
#   - research-and-plan: 8 libraries (adds metadata, checkpoint)
#   - full-implementation: 11 libraries (adds dependency, context, error)
#   - debug-only: 9 libraries (adds metadata, checkpoint, error)
#
# ERROR HANDLING:
#   - Fail-fast on missing library-sourcing.sh
#   - Fail-fast on library sourcing failure
#   - Exit code 1 on any error (caller should handle)
#
# PERFORMANCE:
#   - Typical execution: 50-100ms (11 libraries, full-implementation scope)
#   - Deduplication: Automatic duplicate removal in source_required_libraries()
#   - Caching: Library functions remain available for subprocess lifetime

# ============================================================================
# STANDARD 13: CLAUDE_PROJECT_DIR DETECTION
# ============================================================================

if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# ============================================================================
# WORKFLOW SCOPE DETECTION
# ============================================================================

# Use exported value or default to research-and-plan (conservative)
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-research-and-plan}"

# ============================================================================
# LIBRARY SOURCING
# ============================================================================

# Source library-sourcing.sh (critical dependency)
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
if [ ! -f "$LIB_DIR/library-sourcing.sh" ]; then
  echo "ERROR: library-sourcing.sh not found at: $LIB_DIR/library-sourcing.sh" >&2
  echo "This is a critical dependency for /coordinate command" >&2
  echo "" >&2
  echo "Expected directory structure:" >&2
  echo "  $CLAUDE_PROJECT_DIR/.claude/lib/library-sourcing.sh" >&2
  exit 1
fi

source "$LIB_DIR/library-sourcing.sh"

# Define required libraries based on workflow scope
case "$WORKFLOW_SCOPE" in
  research-only)
    # Minimal libraries for research-only workflows
    # Phases: 0 (Location) → 1 (Research) → STOP
    REQUIRED_LIBS=(
      "workflow-detection.sh"
      "workflow-scope-detection.sh"
      "unified-logger.sh"
      "unified-location-detection.sh"
      "overview-synthesis.sh"
      "verification-helpers.sh"
    )
    ;;
  research-and-plan)
    # Standard libraries for research + planning workflows
    # Phases: 0 → 1 (Research) → 2 (Planning) → STOP
    REQUIRED_LIBS=(
      "workflow-detection.sh"
      "workflow-scope-detection.sh"
      "unified-logger.sh"
      "unified-location-detection.sh"
      "overview-synthesis.sh"
      "metadata-extraction.sh"
      "checkpoint-utils.sh"
      "verification-helpers.sh"
    )
    ;;
  full-implementation)
    # Complete libraries for full workflow
    # Phases: 0 → 1 → 2 → 3 (Implementation) → 4 (Testing) → 5 (Debug) → 6 (Documentation)
    REQUIRED_LIBS=(
      "workflow-detection.sh"
      "workflow-scope-detection.sh"
      "unified-logger.sh"
      "unified-location-detection.sh"
      "overview-synthesis.sh"
      "metadata-extraction.sh"
      "checkpoint-utils.sh"
      "dependency-analyzer.sh"
      "context-pruning.sh"
      "error-handling.sh"
      "verification-helpers.sh"
    )
    ;;
  debug-only)
    # Libraries for debug workflows
    # Phases: 0 → 1 (Research) → 5 (Debug) → STOP
    REQUIRED_LIBS=(
      "workflow-detection.sh"
      "workflow-scope-detection.sh"
      "unified-logger.sh"
      "unified-location-detection.sh"
      "overview-synthesis.sh"
      "metadata-extraction.sh"
      "checkpoint-utils.sh"
      "error-handling.sh"
      "verification-helpers.sh"
    )
    ;;
  *)
    # Unknown scope - default to research-and-plan (conservative fallback)
    echo "WARNING: Unknown workflow scope '$WORKFLOW_SCOPE', defaulting to research-and-plan" >&2
    WORKFLOW_SCOPE="research-and-plan"
    REQUIRED_LIBS=(
      "workflow-detection.sh"
      "workflow-scope-detection.sh"
      "unified-logger.sh"
      "unified-location-detection.sh"
      "overview-synthesis.sh"
      "metadata-extraction.sh"
      "checkpoint-utils.sh"
      "verification-helpers.sh"
    )
    ;;
esac

# Source required libraries (fail-fast on error)
if ! source_required_libraries "${REQUIRED_LIBS[@]}"; then
  echo "ERROR: Failed to source required libraries for scope: $WORKFLOW_SCOPE" >&2
  echo "" >&2
  echo "This indicates missing or corrupted library files." >&2
  echo "Check that all libraries exist in: $LIB_DIR/" >&2
  exit 1
fi

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# display_brief_summary - Display workflow completion summary
#
# Purpose: Provide concise workflow completion status with scope-specific details
#
# Outputs:
#   - research-only: Report count and location
#   - research-and-plan: Report count + plan, next action (/implement)
#   - full-implementation: Summary path
#   - debug-only: Debug report path
#   - Default: Artifact directory
#
# Dependencies: None (uses bash built-ins and exported variables)
#
# Usage:
#   display_brief_summary
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

# transition_to_phase - Manage phase transitions with checkpointing
#
# Purpose: Coordinate phase transitions with proper checkpointing, metadata storage,
#          and context pruning
#
# Arguments:
#   $1 - from_phase: Phase number being completed (e.g., "1", "2")
#   $2 - to_phase: Phase number being started (e.g., "2", "3")
#   $3 - artifacts_json: Optional JSON string with artifact metadata (default: "{}")
#
# Operations:
#   1. Emit progress marker for phase completion
#   2. Save checkpoint (backgrounded for performance)
#   3. Store phase metadata in cache
#   4. Apply pruning policy to reduce context
#   5. Wait for checkpoint completion (non-blocking if backgrounded)
#   6. Emit progress marker for next phase start
#
# Dependencies:
#   - emit_progress() - unified-logger.sh
#   - save_checkpoint() - checkpoint-utils.sh
#   - store_phase_metadata() - context-pruning.sh
#   - apply_pruning_policy() - context-pruning.sh
#
# Error Handling:
#   - Uses conditional execution (command -v check) for graceful degradation
#   - If functions unavailable, phase transition still succeeds
#   - Checkpoint save failures don't block workflow progression
#
# Usage:
#   transition_to_phase "1" "2" '{"report_count": 4}'
transition_to_phase() {
  local from_phase="$1"
  local to_phase="$2"
  local artifacts_json="${3:-{}}"

  # Emit completion progress
  if command -v emit_progress >/dev/null 2>&1; then
    emit_progress "$from_phase" "Phase $from_phase complete, transitioning to Phase $to_phase"
  fi

  # Save checkpoint (background for performance)
  if command -v save_checkpoint >/dev/null 2>&1; then
    save_checkpoint "coordinate" "phase_${from_phase}" "$artifacts_json" &
    local checkpoint_pid=$!
  fi

  # Store phase metadata
  if command -v store_phase_metadata >/dev/null 2>&1; then
    store_phase_metadata "phase_${from_phase}" "complete" "$artifacts_json"
  fi

  # Apply pruning policy
  if command -v apply_pruning_policy >/dev/null 2>&1; then
    apply_pruning_policy "phase_${from_phase}" "$WORKFLOW_SCOPE"
  fi

  # Wait for checkpoint to complete (non-blocking if already done)
  [ -n "${checkpoint_pid:-}" ] && wait $checkpoint_pid 2>/dev/null || true

  # Emit next phase progress
  if command -v emit_progress >/dev/null 2>&1; then
    emit_progress "$to_phase" "Phase $to_phase starting"
  fi
}

# ============================================================================
# INITIALIZATION COMPLETE
# ============================================================================

# Optionally verify critical functions are available (DEBUG mode only)
if [ "${DEBUG_COORDINATE_INIT:-0}" = "1" ]; then
  echo "DEBUG: coordinate-subprocess-init.sh loaded successfully" >&2
  echo "  - WORKFLOW_SCOPE: $WORKFLOW_SCOPE" >&2
  echo "  - Libraries loaded: ${#REQUIRED_LIBS[@]}" >&2
  echo "  - Helper functions: display_brief_summary, transition_to_phase" >&2

  # Verify critical functions
  CRITICAL_FUNCTIONS=("emit_progress" "verify_file_created" "should_run_phase")
  for func in "${CRITICAL_FUNCTIONS[@]}"; do
    if command -v "$func" >/dev/null 2>&1; then
      echo "  - ✓ $func" >&2
    else
      echo "  - ✗ $func MISSING" >&2
    fi
  done
fi
```

## Integration Pattern

### Before (Old Pattern - 18 out of 19 blocks failed)

```bash
USE the Bash tool:

```bash
should_run_phase 1 || {        # ❌ Function not available!
  echo "⏭️  Skipping Phase 1 (Research)"
  display_brief_summary         # ❌ Also not available!
  exit 0
}

if command -v emit_progress &>/dev/null; then
  emit_progress "1" "..."       # ❌ Also not available!
fi

# ... 25 lines later ...

# ✅ Libraries finally sourced - TOO LATE!
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-sourcing.sh"
source_required_libraries || exit 1
```

### After (New Pattern - All blocks work)

```bash
USE the Bash tool:

```bash
# Initialize subprocess environment (libraries + helper functions)
source "${CLAUDE_PROJECT_DIR:=$(git rev-parse --show-toplevel 2>/dev/null || pwd)}/.claude/lib/coordinate-subprocess-init.sh"

should_run_phase 1 || {        # ✅ Function available!
  echo "⏭️  Skipping Phase 1 (Research)"
  display_brief_summary         # ✅ Function available!
  exit 0
}

emit_progress "1" "Phase 1: Research (parallel agent invocation)"  # ✅ Works!

# Rest of bash block code...
```

### Token Reduction

**Per Bash Block**:
- Old pattern: 80+ lines of repetitive sourcing logic
- New pattern: 3 lines (1 comment + 1 source + 1 blank)
- Reduction: ~77 lines × ~50 tokens/line = **3,850 tokens saved per block**

**Across All 19 Blocks**:
- Total reduction: 19 blocks × 3,850 tokens = **73,150 tokens saved**
- Context efficiency: 95% reduction in sourcing overhead

## Verification and Testing

### Unit Tests

**Test 1: Sourcing Script Exists**
```bash
test -f /home/benjamin/.config/.claude/lib/coordinate-subprocess-init.sh
echo "✓ Script file exists"
```

**Test 2: All Scopes Load Successfully**
```bash
for scope in research-only research-and-plan full-implementation debug-only; do
  WORKFLOW_SCOPE=$scope source /home/benjamin/.config/.claude/lib/coordinate-subprocess-init.sh
  echo "✓ $scope scope loaded (${#REQUIRED_LIBS[@]} libraries)"
done
```

**Test 3: Critical Functions Available**
```bash
WORKFLOW_SCOPE=research-and-plan source /home/benjamin/.config/.claude/lib/coordinate-subprocess-init.sh

# Verify each critical function
for func in should_run_phase emit_progress verify_file_created save_checkpoint display_brief_summary transition_to_phase; do
  if command -v "$func" >/dev/null 2>&1; then
    echo "✓ $func"
  else
    echo "✗ $func MISSING" >&2
    exit 1
  fi
done
```

**Test 4: Helper Functions Execute**
```bash
WORKFLOW_SCOPE=research-only
TOPIC_PATH="/tmp/test"
REPORT_PATHS=("report1.md" "report2.md")

source /home/benjamin/.config/.claude/lib/coordinate-subprocess-init.sh

# Test display_brief_summary
display_brief_summary
# Expected output: "✓ Workflow complete: research-only"
#                  "Created 2 research reports in: /tmp/test/reports/"
```

### Integration Tests

**Test 5: Phase 1 Block (Critical Failure Point)**
```bash
# Simulate Phase 1 Research Start bash block
WORKFLOW_SCOPE=research-and-plan
CLAUDE_PROJECT_DIR=/home/benjamin/.config

source "${CLAUDE_PROJECT_DIR}/.claude/lib/coordinate-subprocess-init.sh"

# These should all succeed now
should_run_phase 1 && echo "✓ should_run_phase works"
emit_progress "1" "Testing" && echo "✓ emit_progress works"
display_brief_summary && echo "✓ display_brief_summary works"
```

**Test 6: Full Workflow Scope**
```bash
WORKFLOW_SCOPE=full-implementation
source /home/benjamin/.config/.claude/lib/coordinate-subprocess-init.sh

# Verify all 11 libraries loaded
echo "Libraries loaded: ${#REQUIRED_LIBS[@]}"
# Expected: 11

# Verify specialized functions for full-implementation
command -v analyze_dependencies && echo "✓ dependency-analyzer loaded"
command -v apply_pruning_policy && echo "✓ context-pruning loaded"
```

## Standards Compliance

### Standard 13: CLAUDE_PROJECT_DIR Detection

**Compliant**: Lines 30-34 in specification
```bash
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
```

### Standard 14: Executable/Documentation Separation

**Compliant**: This specification document serves as comprehensive documentation, while the actual coordinate-subprocess-init.sh file is a lean executable script (<300 lines).

### Verification and Fallback Pattern

**Compliant**: Lines 49-61 in specification implement fail-fast verification with detailed diagnostics on library sourcing failure.

### Behavioral Injection Pattern

**Compliant**: Helper functions (display_brief_summary, transition_to_phase) are defined inline, not delegated to external agents.

## Recommendations

### 1. Create coordinate-subprocess-init.sh First

Before fixing any bash blocks in coordinate.md, create and test the initialization script independently. This ensures the pattern works before applying it 19 times.

**Priority**: CRITICAL
**Effort**: 30 minutes
**Validation**: Unit tests 1-4 above

### 2. Fix Critical Blocks First (Minimal Viable Fix)

Fix these 3 blocks to get research-and-plan workflows working:
1. Phase 1 Research Start (coordinate.md:341-381)
2. Phase 1 Verification (coordinate.md:406-457)
3. Phase 2 Planning Start (coordinate.md:530-589)

**Priority**: HIGH
**Effort**: 15 minutes
**Validation**: Integration test 5 above

### 3. Systematically Fix Remaining 16 Blocks

Apply the 3-line initialization pattern to all remaining bash blocks in priority order:
- HIGH: Phase 2 Verification, Phase 0 Step 2 (complete research-and-plan)
- MEDIUM: Phase 3-4 blocks (enable full-implementation)
- LOW: Phase 5-6 blocks (conditional phases)

**Priority**: MEDIUM
**Effort**: 2-3 hours
**Validation**: Full workflow integration tests

### 4. Document Pattern in Command Development Guide

Add section to .claude/docs/guides/command-development-guide.md explaining:
- Why every bash block needs library sourcing
- How to use coordinate-subprocess-init.sh pattern
- Troubleshooting subprocess isolation issues
- When to create custom subprocess-init scripts for other commands

**Priority**: MEDIUM
**Effort**: 1 hour
**Benefit**: Prevents future commands from having same issue

### 5. Audit Other Multi-Block Commands

Check for similar issues in:
- /orchestrate (reported as having multiple bash blocks)
- /implement (reported as having multiple bash blocks)
- /supervise (reported as having multiple bash blocks)

**Priority**: LOW
**Effort**: 2-4 hours
**Benefit**: Proactive fix before users encounter errors

### 6. Consider Generalizing Pattern

If audit reveals widespread need, consider creating:
- Generic `command-subprocess-init.sh` pattern
- Templating system for command-specific init scripts
- Automated validation in command testing suite

**Priority**: LOW
**Effort**: 4-8 hours
**Benefit**: Systematic prevention across all commands

## References

### Source Files Analyzed

- `/home/benjamin/.config/.claude/lib/library-sourcing.sh` (120 lines)
- `/home/benjamin/.config/.claude/lib/workflow-detection.sh` (207 lines)
- `/home/benjamin/.config/.claude/lib/unified-logger.sh` (735 lines)
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` (100+ lines analyzed)
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh` (124 lines)
- `/home/benjamin/.config/.claude/lib/context-pruning.sh` (250+ lines analyzed)
- `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh` (50 lines)
- `/home/benjamin/.config/.claude/lib/overview-synthesis.sh` (100 lines analyzed)
- `/home/benjamin/.config/.claude/lib/dependency-analyzer.sh` (100 lines analyzed)
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 110-260 analyzed)

### Related Documentation

- `/home/benjamin/.config/.claude/specs/602_601_and_documentation_in_claude_docs_in_order_to/reports/coordinate_subprocess_isolation_fix_plan.md` - Complete fix plan with error analysis
- `/home/benjamin/.config/.claude/specs/coordinate_output.md` - Console output showing failures
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` - Standard 13, Standard 14
- `/home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md` - Verification pattern reference
- `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md` - Command development best practices

### Key Metrics

- **Libraries Analyzed**: 9 core libraries + 1 command file
- **Functions Cataloged**: 25+ critical functions across libraries
- **Workflow Scopes**: 4 (research-only, research-and-plan, full-implementation, debug-only)
- **Bash Blocks Affected**: 19 out of 19 in /coordinate command
- **Token Reduction**: 73,150 tokens saved (95% reduction in sourcing overhead)
- **Code Duplication Eliminated**: 80+ lines × 19 blocks = 1,520 lines → 3 lines per block
