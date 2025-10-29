# Coordinate Error and Formatting Analysis

## Metadata
- **Date**: 2025-10-28
- **Topic Number**: 510
- **Context**: Analysis of /coordinate command execution error and formatting issues
- **Related Specs**: 508 (Best Practices), 495 (/coordinate anti-pattern fixes), 057 (/supervise robustness)

## Executive Summary

Analysis of `/coordinate` command execution reveals two distinct issues: (1) `emit_progress: command not found` error at line 48 caused by bash code blocks being executed outside of library loading context, and (2) verbose MANDATORY VERIFICATION output that creates cognitive burden through excessive formatting. The root cause is a sequencing problem where inline bash blocks in Phase 0 execute before library sourcing completes, combined with formatting patterns that prioritize visual hierarchy over readability. Fixes require: (a) moving all bash blocks requiring library functions after the library sourcing section, (b) consolidating verification output to single-line format with optional details flag, and (c) standardizing progress markers to use minimal formatting. These changes align with Spec 508 best practices for fail-fast error handling and context reduction.

## Error Analysis

### Issue 1: emit_progress Command Not Found (Critical)

**Location**: Phase 0/Phase 1 boundary, line 48 in coordinate_output.md

**Error Message**:
```
/run/current-system/sw/bin/bash: line 29: emit_progress: command not found
```

**Root Cause Analysis**:

The error occurs because inline bash code blocks in the /coordinate command are being executed by Claude Code's Bash tool BEFORE the library sourcing section (lines 352-388) has been processed. This creates a temporal ordering issue:

**Execution Order** (Current - BROKEN):
1. **Line 23-26**: Phase 0 bash block executes (displays "Workflow Scope Detection")
2. **Line 32-38**: Second bash block attempts to call `emit_progress()` → **FAILS** (function not defined yet)
3. **Lines 352-388**: Library sourcing section processes (defines `emit_progress()`)
4. **Lines 425-431**: Function verification checks (validates emit_progress exists)

**Why This Happens**:

The /coordinate command file contains two types of content:
1. **Markdown documentation** - Read by Claude as instructions
2. **Bash code blocks** (```bash...```) - Executed by Bash tool when Claude encounters them

Claude processes the file sequentially. When it encounters a bash code block at line 32 that calls `emit_progress`, it immediately executes that block via the Bash tool. However, `emit_progress()` won't be defined until line 383 when `source_required_libraries` completes.

**Evidence**:

```bash
# coordinate.md line 32-38 (EXECUTED SECOND, but NEEDS library functions)
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
emit_progress "0" "Workflow scope detected: $WORKFLOW_SCOPE"  # FAILS HERE
```

```bash
# coordinate.md line 383 (EXECUTED AFTER inline bash blocks)
if ! source_required_libraries "dependency-analyzer.sh"; then
  exit 1
fi
```

**Comparison with Working Commands**:

Looking at `/supervise` and `/orchestrate`, they avoid this issue by:
1. Placing ALL bash blocks that use library functions AFTER the library sourcing section
2. Using Phase 0 only for argument validation (no library function calls)
3. Calling `emit_progress` only in Phase 1+ sections (after sourcing complete)

**Example from /supervise** (Working pattern):
```markdown
## Phase 0: Workflow Setup
[Documentation only - no bash blocks calling library functions]

## Shared Utility Functions
[EXECUTION-CRITICAL: Source statements]
```bash
source_required_libraries || exit 1
```

## Phase 1: Research
[First phase that uses emit_progress - after sourcing]
```bash
emit_progress "1" "Starting research"
```

**Priority**: **Critical (High)** - Blocks command execution

### Issue 2: Verbose Verification Output Formatting (Medium)

**Location**: Lines 92-96 in coordinate_output.md

**Current Output**:
```
════════════════════════════════════════
════════════════
  MANDATORY VERIFICATION - Research Repo
… +46 lines (ctrl+o to expand)
```

**Problems Identified**:

1. **Excessive Visual Hierarchy**: 80-character box-drawing for every verification checkpoint creates visual clutter
2. **Line Proliferation**: "MANDATORY VERIFICATION" produces 50+ lines per checkpoint (header + body + footer)
3. **Cognitive Load**: User must mentally filter formatting to extract actual verification results
4. **Context Window Consumption**: Each checkpoint consumes ~500 tokens (400 formatting, 100 content)
5. **Inconsistent with Spec 508**: Best practices emphasize "Silent PROGRESS: markers", not verbose verification

**Spec 508 Alignment Gap**:

From best practices overview (lines 260-268):
```markdown
- **Progress Streaming**: Silent PROGRESS: markers at each phase boundary
  - Format: `PROGRESS: [Phase N] - action_description`
  - Enables external monitoring without verbose output
```

Current verification output violates this by using:
- Visual emphasis (box-drawing) instead of structured markers
- Multi-line headers instead of single-line status
- Embedded details instead of optional expansion

**Comparison with Best Practice**:

**Current** (Verbose - 50+ lines):
```
════════════════════════════════════════════════════════
  MANDATORY VERIFICATION - Research Reports
════════════════════════════════════════════════════════

Verifying research report 1/4...
  Path: /path/to/report1.md
  Expected: File exists with content
  Status: ✓ PASSED (25KB)

Verifying research report 2/4...
  Path: /path/to/report2.md
  Expected: File exists with content
  Status: ✓ PASSED (30KB)

... [46 more lines]

════════════════════════════════════════════════════════
VERIFICATION COMPLETE - 4/4 reports created
════════════════════════════════════════════════════════
```

**Best Practice** (Concise - 1-5 lines):
```
PROGRESS: [Phase 1] - Verifying research reports (4/4)
✓ Verified: 4/4 research reports (total: 112KB)
```

With optional detailed view on error:
```
PROGRESS: [Phase 1] - Verifying research reports (4/4)
✗ Verification failed: 2/4 reports missing

DIAGNOSTIC INFORMATION:
  Report 1: ✗ File not found at /path/to/report1.md
  Report 3: ✗ File empty (0 bytes) at /path/to/report3.md

What to check next:
  1. Verify agent invocation completed: grep "REPORT_CREATED" [agent output]
  2. Check parent directory exists: ls -la /path/to/
  3. Review agent behavioral file: cat .claude/agents/research-specialist.md
```

**Priority**: **Medium** - Doesn't block execution, but degrades user experience and violates standards

## Formatting Issues Deep Dive

### Current Verification Pattern Analysis

**Pattern Distribution Across Commands**:

```bash
# Grep results show 80+ instances of "MANDATORY VERIFICATION"
# Distribution:
# - /orchestrate.md: 15 instances
# - /supervise.md: 8 instances
# - /coordinate.md: 7 instances (before phase 1 changes)
# - Other commands: 50+ instances
```

**Format Characteristics**:

1. **Box-Drawing Headers** (lines 92-93):
   - 80 characters of `═` characters
   - 2 lines per header (top border + title + bottom border)
   - Total: 160 characters of pure formatting

2. **Indented Content** (lines 94-96+):
   - 2-space indentation for all content
   - Multi-line status per item (path + expected + found + status)
   - Total: ~10 lines per verified item

3. **Box-Drawing Footers** (after verification loop):
   - Another 80-character `═` border
   - Summary line
   - Another 80-character `═` border
   - Total: 160 characters + summary

**Token Cost Analysis**:

```
Header:         ~80 tokens (box-drawing + title)
Body (4 items): ~320 tokens (80 tokens × 4 items)
Footer:         ~80 tokens (box-drawing + summary)
Total:          ~480 tokens per verification checkpoint

Context savings with concise format:
Concise:        ~50 tokens (1 line summary + 4 item statuses)
Reduction:      ~430 tokens (90% reduction)
```

**User Experience Impact**:

From coordinate_output.md analysis:
- Line 92-96: Verification section collapsed by default (ctrl+o to expand)
- User sees: "… +46 lines (ctrl+o to expand)"
- **Implication**: Even the terminal interface recognizes this output is too verbose to display

### Comparison with Working Commands

**Pattern in /orchestrate** (lines 2400-2450):
```bash
echo "════════════════════════════════════════════════════════"
echo "**MANDATORY VERIFICATION - Overview Report Created**"
echo "════════════════════════════════════════════════════════"
# ... detailed checks ...
echo "════════════════════════════════════════════════════════"
```

**Same pattern**, but /orchestrate has additional context:
- Used for critical checkpoints only (5-6 per workflow)
- Includes diagnostic commands inline
- Placed strategically at phase boundaries

**Pattern in /supervise** (lines 1100-1150):
```bash
echo "  MANDATORY VERIFICATION - Research Reports"
echo "════════════════════════════════════════════════════════"
# ... checks ...
```

**Slightly more concise** (single-line header), but still verbose

**Best Practice Pattern** (from Spec 508):
```bash
emit_progress "1" "Research complete (4/4 reports created)"
```

**Minimal format** - structured, parseable, silent unless error

### Root Cause: Competing Design Goals

The current verbose verification pattern exists because of competing goals:

1. **Goal: 100% File Creation Reliability** (Spec 495, 057)
   - Achieved through "three-layer defense" (agent prompt + behavioral file + command verification)
   - Requires explicit verification checkpoints
   - ✅ **Success**: 100% file creation rate achieved

2. **Goal: Fail-Fast Error Handling** (Spec 057, 508)
   - Achieved through comprehensive diagnostics on failure
   - Requires detailed error context
   - ✅ **Success**: Clear failure diagnostics with suggested actions

3. **Goal: Context Reduction** (Spec 508)
   - Achieved through metadata-only passing and aggressive pruning
   - Requires minimal output except on error
   - ❌ **Conflict**: Verbose verification contradicts this goal

**Design Tension**:

```
Verification Reliability ← → Context Efficiency
    (100% file creation)       (<30% context usage)
            ↓
    Current: Verbose success output (conflicts with context efficiency)
    Optimal: Concise success, verbose failure (satisfies both)
```

## Best Practices Alignment Analysis

### Spec 508 Standards Compliance

**Standard: Progress Streaming** (Spec 508, line 260-268)

✅ **Compliant**:
- Uses `emit_progress()` function from unified-logger.sh
- Format: `PROGRESS: [Phase N] - action`
- Silent markers (no verbose output)

❌ **Non-Compliant**:
- Verification checkpoints use verbose box-drawing instead of progress markers
- Success output is multi-line (50+ lines) instead of single-line
- No distinction between "everything OK" vs "needs attention"

**Recommendation**: Replace verbose success verification with:
```bash
emit_progress "1" "Verified: 4/4 research reports (112KB total)"
```

Reserve detailed output for failures only.

**Standard: Fail-Fast Error Handling** (Spec 508, line 269-287)

✅ **Compliant**:
- 5-component error messages (what failed, expected, diagnostic, context, action)
- Exit immediately on permanent errors
- Clear diagnostic commands provided

✅ **Compliant**:
- Partial research failure handling (≥50% threshold)
- Single retry for transient errors only

**No conflicts identified** - error handling follows best practices correctly.

**Standard: Context Reduction** (Spec 508, line 246-268)

✅ **Compliant**:
- Metadata extraction after agent invocations (95% reduction)
- Aggressive context pruning between phases (96% reduction)
- Checkpoint-based external state (95% reduction)

❌ **Non-Compliant**:
- Verification output contributes ~2000 tokens per workflow (4 checkpoints × 500 tokens)
- This is ~10% of the 25% context budget (excessive for pass/fail checks)
- Could be reduced to ~200 tokens (10× improvement)

**Recommendation**: Adopt concise verification format to reduce context consumption by 90%.

**Standard: Library Integration** (Spec 508, line 625-650)

❌ **Non-Compliant**:
- Inline bash blocks call library functions BEFORE library sourcing completes
- Creates temporal ordering issue causing `command not found` errors

✅ **Compliant** (once fixed):
- Uses `source_required_libraries()` for consolidated sourcing
- Implements fail-fast on missing libraries
- Verifies required functions after sourcing

**Recommendation**: Move all bash blocks using library functions to AFTER library sourcing section.

### Gap Summary

| Standard | Compliance | Gap Description | Priority |
|----------|-----------|-----------------|----------|
| Progress Streaming | Partial | Verbose verification vs silent progress | Medium |
| Fail-Fast Error Handling | Full | No gaps | N/A |
| Context Reduction | Partial | Excessive verification output (2000 tokens) | Medium |
| Library Integration | Broken | Temporal ordering causes errors | Critical |

## Improvement Opportunities

### High Priority (Critical) - Fix emit_progress Error

**Problem**: Bash blocks calling library functions execute before library sourcing completes.

**Solution**: Restructure command file to ensure library sourcing happens first.

**Implementation**:

**Step 1**: Move library sourcing to Phase 0 (earliest possible point)

```markdown
## Phase 0: Project Location and Path Pre-Calculation

[EXECUTION-CRITICAL: Library sourcing MUST occur before any function calls]

### Step 0: Source Required Libraries

EXECUTE NOW:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/library-sourcing.sh" ]; then
  source "$SCRIPT_DIR/../lib/library-sourcing.sh"
else
  echo "ERROR: Required library not found: library-sourcing.sh"
  exit 1
fi

if ! source_required_libraries "dependency-analyzer.sh"; then
  exit 1
fi

echo "✓ All libraries loaded successfully"
```

### Step 1: Parse Workflow Arguments

EXECUTE NOW:
```bash
WORKFLOW_DESCRIPTION="$1"
if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description required"
  exit 1
fi

emit_progress "0" "Parsing workflow arguments"
```

[Continue with remaining Phase 0 steps...]
```

**Key Changes**:
1. Library sourcing becomes **Step 0** (before any other bash blocks)
2. All subsequent bash blocks can safely call library functions
3. `emit_progress`, `detect_workflow_scope`, etc. guaranteed to be defined

**Validation**:
```bash
# Test that emit_progress is available in Step 1
WORKFLOW_DESCRIPTION="test"
emit_progress "0" "Test message"  # Should succeed
```

**Priority**: **Critical** - Blocks command execution
**Effort**: **Low** (2-3 hours) - Restructure Phase 0 section only
**Risk**: **Low** - Pattern proven in /supervise, /orchestrate

---

### High Priority - Simplify Verification Output Format

**Problem**: Verbose verification output (50+ lines per checkpoint) creates cognitive burden and consumes excessive context.

**Solution**: Adopt concise single-line format for success, verbose format for failures only.

**Implementation**:

**Step 1**: Create verification helper function in coordinate.md

```bash
# verify_file_created - Concise verification with optional verbose failure
#
# Arguments:
#   $1 - file_path
#   $2 - item_description (e.g., "Research report 1/4")
#   $3 - phase_name (e.g., "Phase 1")
#
# Returns:
#   0 - File exists and has content
#   1 - File missing or empty
#
# Output:
#   Success: Single character (✓)
#   Failure: Multi-line diagnostic
verify_file_created() {
  local file_path="$1"
  local item_desc="$2"
  local phase_name="$3"

  if [ -f "$file_path" ] && [ -s "$file_path" ]; then
    echo -n "✓"  # Success - single character, no newline
    return 0
  else
    # Failure - verbose diagnostic
    echo ""
    echo "✗ ERROR [$phase_name]: $item_desc verification failed"
    echo "   Expected: File exists at $file_path"
    [ ! -f "$file_path" ] && echo "   Found: File does not exist" || echo "   Found: File empty"
    echo ""
    echo "DIAGNOSTIC INFORMATION:"
    echo "  - Expected path: $file_path"
    echo "  - Parent directory: $(dirname "$file_path")"

    local dir="$(dirname "$file_path")"
    if [ -d "$dir" ]; then
      echo "  - Directory status: ✓ Exists ($(ls -1 "$dir" 2>/dev/null | wc -l) files)"
    else
      echo "  - Directory status: ✗ Does not exist"
      echo "  - Fix: mkdir -p $dir"
    fi

    return 1
  fi
}
```

**Step 2**: Replace verbose verification sections with concise format

**Before** (50+ lines):
```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Research Reports"
echo "════════════════════════════════════════════════════════"

for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"
  echo "Verifying research report $i/$RESEARCH_COMPLEXITY..."
  echo "  Path: $REPORT_PATH"
  echo "  Expected: File exists with content"

  if [ -f "$REPORT_PATH" ] && [ -s "$REPORT_PATH" ]; then
    FILE_SIZE=$(wc -c < "$REPORT_PATH")
    echo "  Status: ✓ PASSED ($FILE_SIZE bytes)"
  else
    echo "  Status: ✗ FAILED"
    # ... 20+ lines of diagnostics ...
  fi
done

echo "════════════════════════════════════════════════════════"
echo "VERIFICATION COMPLETE - $RESEARCH_COMPLEXITY reports"
echo "════════════════════════════════════════════════════════"
```

**After** (1-5 lines on success, verbose on failure):
```bash
# Concise verification with inline status indicators
echo -n "Verifying research reports ($RESEARCH_COMPLEXITY): "

VERIFICATION_FAILURES=0
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"
  if ! verify_file_created "$REPORT_PATH" "Research report $i/$RESEARCH_COMPLEXITY" "Phase 1"; then
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
  fi
done

# Final summary (single line on success)
if [ $VERIFICATION_FAILURES -eq 0 ]; then
  echo " (all passed)"
  emit_progress "1" "Verified: $RESEARCH_COMPLEXITY/$RESEARCH_COMPLEXITY research reports"
else
  echo ""
  echo "Workflow TERMINATED: Fix verification failures and retry"
  exit 1
fi
```

**Output Examples**:

Success case:
```
Verifying research reports (4): ✓✓✓✓ (all passed)
PROGRESS: [Phase 1] - Verified: 4/4 research reports
```

Failure case (verbose diagnostics):
```
Verifying research reports (4): ✓✓
✗ ERROR [Phase 1]: Research report 3/4 verification failed
   Expected: File exists at /path/to/report3.md
   Found: File does not exist

DIAGNOSTIC INFORMATION:
  - Expected path: /path/to/report3.md
  - Parent directory: /path/to/
  - Directory status: ✓ Exists (2 files)

Workflow TERMINATED: Fix verification failures and retry
```

**Benefits**:
- **Context reduction**: 500 tokens → 50 tokens (90% reduction) on success
- **Cognitive load**: Single line vs 50 lines on success
- **Fail-fast clarity**: Verbose diagnostics still provided on failure
- **Alignment**: Matches Spec 508 "silent progress markers" standard

**Priority**: **High** - Improves UX and reduces context consumption
**Effort**: **Medium** (4-6 hours) - Replace 7 verification checkpoints
**Risk**: **Low** - Preserves diagnostic quality on failure

---

### Medium Priority - Standardize Progress Marker Format

**Problem**: Mixed usage of `emit_progress()` vs echo statements for phase transitions.

**Solution**: Use `emit_progress()` consistently for all phase boundaries and major milestones.

**Implementation**:

**Step 1**: Audit all phase transitions and identify echo statements

```bash
# Find all phase transition echo statements
grep -n "echo.*Phase [0-9]" /home/benjamin/.config/.claude/commands/coordinate.md
```

**Step 2**: Replace echo with emit_progress

**Before**:
```bash
echo "════════════════════════════════════════════════════════"
echo "  Phase 1: Research - Parallel Agent Invocation"
echo "════════════════════════════════════════════════════════"
```

**After**:
```bash
emit_progress "1" "Starting research phase (parallel agent invocation)"
```

**Step 3**: Standardize milestone format

**Current** (inconsistent):
```bash
echo "✓ Verified: $SUCCESSFUL_REPORT_COUNT/$RESEARCH_COMPLEXITY research reports"
emit_progress "1" "Research complete (4/4 reports created)"
echo "Phase 1 Complete: Research artifacts verified"
```

**Standardized** (consistent):
```bash
emit_progress "1" "Verified: $SUCCESSFUL_REPORT_COUNT/$RESEARCH_COMPLEXITY research reports"
emit_progress "1" "Research phase complete"
```

**Benefits**:
- Consistent format across all phase transitions
- Parseable by external monitoring tools
- Aligned with Spec 508 progress streaming standard

**Priority**: **Medium** - Improves consistency
**Effort**: **Low** (1-2 hours) - Simple find/replace
**Risk**: **Minimal** - No functional changes

---

### Low Priority - Extract Verification Function to Library

**Problem**: `verify_file_created()` helper duplicated across multiple verification checkpoints.

**Solution**: Extract to shared library (e.g., `verification-utils.sh`).

**Implementation**:

**Step 1**: Create new library file

```bash
# .claude/lib/verification-utils.sh

#!/usr/bin/env bash
# verification-utils.sh - Shared verification functions for orchestration commands

# verify_file_created - Concise file existence verification
#
# [Function implementation from "High Priority" improvement]
verify_file_created() {
  # ... (see above)
}

# verify_directory_created - Concise directory existence verification
verify_directory_created() {
  local dir_path="$1"
  local item_desc="$2"
  local phase_name="$3"

  if [ -d "$dir_path" ]; then
    echo -n "✓"
    return 0
  else
    echo ""
    echo "✗ ERROR [$phase_name]: $item_desc verification failed"
    echo "   Expected: Directory exists at $dir_path"
    echo "   Found: Directory does not exist"
    echo ""
    echo "DIAGNOSTIC INFORMATION:"
    echo "  - Expected path: $dir_path"
    echo "  - Parent directory: $(dirname "$dir_path")"
    echo "  - Fix: mkdir -p $dir_path"
    return 1
  fi
}

export -f verify_file_created
export -f verify_directory_created
```

**Step 2**: Add to source_required_libraries

```bash
# library-sourcing.sh (add to core libraries list)
local libraries=(
  "workflow-detection.sh"
  "error-handling.sh"
  "checkpoint-utils.sh"
  "unified-logger.sh"
  "unified-location-detection.sh"
  "metadata-extraction.sh"
  "context-pruning.sh"
  "verification-utils.sh"  # NEW
)
```

**Step 3**: Remove inline definition from coordinate.md

**Benefits**:
- Reusable across all orchestration commands (/coordinate, /orchestrate, /supervise)
- Single source of truth for verification logic
- Easier to enhance (e.g., add file size checks, magic number validation)

**Priority**: **Low** - Maintainability improvement, not urgent
**Effort**: **Medium** (3-4 hours) - Create library, update all commands
**Risk**: **Low** - Existing inline definitions remain as fallback during transition

## Code Examples for Recommended Fixes

### Fix 1: Library Sourcing Before Function Calls (Critical)

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`

**Change Location**: Lines 621-742 (Phase 0 section)

**Before** (Broken - causes emit_progress error):
```markdown
## Phase 0: Project Location and Path Pre-Calculation

[EXECUTION-CRITICAL: Path calculation before agent invocations - inline bash required]

**Objective**: Establish topic directory structure and calculate all artifact paths.

### Implementation

STEP 1: Parse workflow description from command arguments

```bash
WORKFLOW_DESCRIPTION="$1"
if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description required"
  exit 1
fi

# Check for existing checkpoint (auto-resume capability)
RESUME_DATA=$(restore_checkpoint "coordinate" 2>/dev/null || echo "")
# ... more code using library functions ...
```

STEP 2: Detect workflow scope

```bash
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")  # FAILS - function not defined yet
emit_progress "0" "Workflow scope detected"  # FAILS - function not defined yet
```

[... later in file ...]

## Shared Utility Functions

**EXECUTE NOW - Source Required Libraries**

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/library-sourcing.sh"
source_required_libraries "dependency-analyzer.sh"
```
```

**After** (Fixed - library sourcing first):
```markdown
## Phase 0: Project Location and Path Pre-Calculation

[EXECUTION-CRITICAL: Library sourcing MUST occur before any function calls]

**Objective**: Establish topic directory structure and calculate all artifact paths.

### STEP 0: Source Required Libraries (MUST BE FIRST)

EXECUTE NOW:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source library-sourcing utilities first
if [ -f "$SCRIPT_DIR/../lib/library-sourcing.sh" ]; then
  source "$SCRIPT_DIR/../lib/library-sourcing.sh"
else
  echo "ERROR: Required library not found: library-sourcing.sh"
  echo ""
  echo "Expected location: $SCRIPT_DIR/../lib/library-sourcing.sh"
  echo ""
  echo "This library provides consolidated library sourcing functions."
  echo ""
  echo "Diagnostic commands:"
  echo "  ls -la $SCRIPT_DIR/../lib/ | grep library-sourcing"
  echo "  cat $SCRIPT_DIR/../lib/library-sourcing.sh"
  echo ""
  echo "Please ensure the library file exists and is readable."
  exit 1
fi

# Source all required libraries using consolidated function
if ! source_required_libraries "dependency-analyzer.sh"; then
  exit 1
fi

echo "✓ All libraries loaded successfully"

# Verify critical functions are defined after library sourcing
REQUIRED_FUNCTIONS=(
  "detect_workflow_scope"
  "should_run_phase"
  "emit_progress"
  "save_checkpoint"
  "restore_checkpoint"
)

MISSING_FUNCTIONS=()
for func in "${REQUIRED_FUNCTIONS[@]}"; do
  if ! command -v "$func" >/dev/null 2>&1; then
    MISSING_FUNCTIONS+=("$func")
  fi
done

if [ ${#MISSING_FUNCTIONS[@]} -gt 0 ]; then
  echo "ERROR: Required functions not defined after library sourcing:"
  for func in "${MISSING_FUNCTIONS[@]}"; do
    echo "  - $func()"
  done
  exit 1
fi

emit_progress "0" "Libraries loaded and verified"
```

### STEP 1: Parse Workflow Arguments

EXECUTE NOW:
```bash
WORKFLOW_DESCRIPTION="$1"

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "DIAGNOSTIC INFO: Missing Workflow Description"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "ERROR: Workflow description required"
  echo ""
  echo "Usage: /coordinate \"<workflow description>\""
  exit 1
fi

emit_progress "0" "Workflow description parsed"
```

### STEP 2: Detect Workflow Scope

EXECUTE NOW:
```bash
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")  # NOW WORKS - function defined

# Map scope to phase execution list
case "$WORKFLOW_SCOPE" in
  research-only)
    PHASES_TO_EXECUTE="0,1"
    ;;
  research-and-plan)
    PHASES_TO_EXECUTE="0,1,2"
    ;;
  full-implementation)
    PHASES_TO_EXECUTE="0,1,2,3,4"
    ;;
  debug-only)
    PHASES_TO_EXECUTE="0,1,5"
    ;;
esac

emit_progress "0" "Workflow scope detected: $WORKFLOW_SCOPE"  # NOW WORKS
echo "Phases to execute: $PHASES_TO_EXECUTE"
```

[Continue with remaining Phase 0 steps...]
```

**Key Changes**:
1. **STEP 0 created**: Library sourcing isolated to first step
2. **Function verification**: Explicit check that required functions exist
3. **emit_progress safe**: Called only after libraries loaded
4. **Clear ordering**: Library loading → function verification → usage

**Testing**:
```bash
# Test command execution
/coordinate "test workflow"

# Expected output:
# ✓ All libraries loaded successfully
# PROGRESS: [Phase 0] - Libraries loaded and verified
# PROGRESS: [Phase 0] - Workflow description parsed
# PROGRESS: [Phase 0] - Workflow scope detected: research-and-plan
# Phases to execute: 0,1,2
```

---

### Fix 2: Concise Verification Output (High Priority)

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`

**Change Location**: Lines 825-890 (Phase 1 verification section)

**Before** (Verbose - 50+ lines):
```markdown
### Mandatory Verification - Research Reports with Auto-Recovery

**VERIFICATION REQUIRED**: All research report files must exist before continuing to Phase 2

STEP 3: Verify ALL research reports created successfully (with single-retry for transient failures)

```bash
VERIFICATION_FAILURES=0
SUCCESSFUL_REPORT_PATHS=()
FAILED_AGENTS=()

for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"
  emit_progress "1" "Verifying research report $i/$RESEARCH_COMPLEXITY"

  if [ -f "$REPORT_PATH" ] && [ -s "$REPORT_PATH" ]; then
    FILE_SIZE=$(wc -c < "$REPORT_PATH")
    [ "$FILE_SIZE" -lt 200 ] || ! grep -q "^# " "$REPORT_PATH" && echo "⚠️  Report $i: $(basename $REPORT_PATH) - warnings detected"
    SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
  else
    echo "  ❌ ERROR [Phase 1, Research]: Report file verification failed"
    echo "     Expected: File exists and has content"
    [ ! -f "$REPORT_PATH" ] && echo "     Found: File does not exist" || echo "     Found: File exists but is empty"
    echo ""
    echo "  DIAGNOSTIC INFORMATION:"
    echo "    - Expected path: $REPORT_PATH"
    echo "    - Agent: research-specialist (agent $i/$RESEARCH_COMPLEXITY)"
    echo ""
    DIR="$(dirname "$REPORT_PATH")"
    if [ -d "$DIR" ]; then
      FILE_COUNT=$(ls -1 "$DIR" 2>/dev/null | wc -l)
      echo "  Directory Status: ✓ Exists ($FILE_COUNT files)"
      [ "$FILE_COUNT" -gt 0 ] && ls -lht "$DIR" | head -6
    else
      echo "  Directory Status: ✗ Does not exist"
      echo "  Fix: mkdir -p $DIR"
    fi
    echo ""
    echo "  Diagnostic Commands:"
    echo "    ls -la $DIR"
    echo "    cat .claude/agents/research-specialist.md | head -50"
    echo ""
    FAILED_AGENTS+=("agent_$i")
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
  fi
done

SUCCESSFUL_REPORT_COUNT=${#SUCCESSFUL_REPORT_PATHS[@]}

if [ $VERIFICATION_FAILURES -gt 0 ]; then
  echo "❌ Workflow terminated: Fix research issues and retry"
  exit 1
fi

echo "✓ Verified: $SUCCESSFUL_REPORT_COUNT/$RESEARCH_COMPLEXITY research reports"
```
```

**After** (Concise - 1-5 lines on success, verbose on failure):
```markdown
### Mandatory Verification - Research Reports

**VERIFICATION REQUIRED**: All research report files must exist before continuing to Phase 2

STEP 3: Verify ALL research reports created successfully

```bash
# Helper function for concise verification
verify_file_created() {
  local file_path="$1"
  local item_desc="$2"
  local phase_name="$3"

  if [ -f "$file_path" ] && [ -s "$file_path" ]; then
    echo -n "✓"  # Success - single character
    return 0
  else
    # Failure - verbose diagnostic
    echo ""
    echo "✗ ERROR [$phase_name]: $item_desc verification failed"
    echo "   Expected: File exists at $file_path"
    [ ! -f "$file_path" ] && echo "   Found: File does not exist" || echo "   Found: File empty"
    echo ""
    echo "DIAGNOSTIC INFORMATION:"
    echo "  - Expected path: $file_path"
    echo "  - Parent directory: $(dirname "$file_path")"

    local dir="$(dirname "$file_path")"
    if [ -d "$dir" ]; then
      local file_count
      file_count=$(ls -1 "$dir" 2>/dev/null | wc -l)
      echo "  - Directory status: ✓ Exists ($file_count files)"
      [ "$file_count" -gt 0 ] && echo "  - Recent files:" && ls -lht "$dir" | head -4
    else
      echo "  - Directory status: ✗ Does not exist"
      echo "  - Fix: mkdir -p $dir"
    fi
    echo ""
    echo "Diagnostic commands:"
    echo "  ls -la $dir"
    echo "  cat .claude/agents/research-specialist.md | head -50"
    echo ""
    return 1
  fi
}

# Concise verification with inline status
echo -n "Verifying research reports ($RESEARCH_COMPLEXITY): "

VERIFICATION_FAILURES=0
SUCCESSFUL_REPORT_PATHS=()

for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"
  if ! verify_file_created "$REPORT_PATH" "Research report $i/$RESEARCH_COMPLEXITY" "Phase 1"; then
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
  else
    SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
  fi
done

SUCCESSFUL_REPORT_COUNT=${#SUCCESSFUL_REPORT_PATHS[@]}

# Final summary
if [ $VERIFICATION_FAILURES -eq 0 ]; then
  echo " (all passed)"  # Completes the "Verifying..." line
  emit_progress "1" "Verified: $SUCCESSFUL_REPORT_COUNT/$RESEARCH_COMPLEXITY research reports"
else
  echo ""
  echo "Workflow TERMINATED: Fix verification failures and retry"
  exit 1
fi

# VERIFICATION REQUIREMENT: YOU MUST NOT proceed to Phase 2 without all reports verified
echo "Verification checkpoint passed - proceeding to research overview"
echo ""
```
```

**Output Comparison**:

Success case (Before - 50+ lines):
```
Verifying research report 1/4...
  Path: /path/to/report1.md
  Expected: File exists with content
  Status: ✓ PASSED (25000 bytes)

Verifying research report 2/4...
  Path: /path/to/report2.md
  Expected: File exists with content
  Status: ✓ PASSED (30000 bytes)

[... 40+ more lines ...]

✓ Verified: 4/4 research reports
```

Success case (After - 2 lines):
```
Verifying research reports (4): ✓✓✓✓ (all passed)
PROGRESS: [Phase 1] - Verified: 4/4 research reports
```

Failure case (After - verbose diagnostics preserved):
```
Verifying research reports (4): ✓✓
✗ ERROR [Phase 1]: Research report 3/4 verification failed
   Expected: File exists at /path/to/report3.md
   Found: File does not exist

DIAGNOSTIC INFORMATION:
  - Expected path: /path/to/report3.md
  - Parent directory: /path/to/
  - Directory status: ✓ Exists (2 files)
  - Recent files:
      -rw-r--r-- 1 user group 25000 Oct 28 10:15 report1.md
      -rw-r--r-- 1 user group 30000 Oct 28 10:16 report2.md

Diagnostic commands:
  ls -la /path/to/
  cat .claude/agents/research-specialist.md | head -50

Workflow TERMINATED: Fix verification failures and retry
```

**Benefits**:
- **Success output**: 50+ lines → 2 lines (96% reduction)
- **Context tokens**: ~500 tokens → ~50 tokens (90% reduction)
- **Failure diagnostics**: Unchanged (still verbose and helpful)
- **User experience**: Immediate visual scan (✓✓✓✓) vs scrolling through multi-line blocks

**Reusability**:
Apply same pattern to:
- Phase 2 verification (plan file)
- Phase 3 verification (implementation artifacts)
- Phase 4 verification (test results)
- Phase 5 verification (debug reports)
- Phase 6 verification (summary file)

Total context savings: 6 checkpoints × 450 tokens saved = 2,700 tokens (~13% of context budget)

---

### Fix 3: Standardize Progress Markers (Medium Priority)

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`

**Change Locations**: Multiple sections (Phase 0-6)

**Pattern to Replace** (inconsistent):
```bash
# Scattered across command file
echo "Phase 1 Complete"
echo "✓ Verified: $COUNT reports"
echo "════════════════════════════════════════════════════════"
echo "  Phase 2: Planning"
echo "════════════════════════════════════════════════════════"
```

**Standardized Pattern** (consistent):
```bash
# All phase transitions use emit_progress
emit_progress "1" "Research phase complete"
emit_progress "1" "Verified: $COUNT/$TOTAL research reports"
emit_progress "2" "Planning phase starting"
```

**Implementation Script**:

```bash
#!/bin/bash
# standardize-progress-markers.sh - Replace echo statements with emit_progress

FILE="/home/benjamin/.config/.claude/commands/coordinate.md"

# Backup original
cp "$FILE" "$FILE.backup-$(date +%Y%m%d_%H%M%S)"

# Phase completion markers
sed -i 's/echo "Phase \([0-9]\) Complete"/emit_progress "\1" "Phase \1 complete"/' "$FILE"

# Box-drawing phase headers (remove and replace with emit_progress)
# This requires manual review as box-drawing sections vary

echo "Manual review required for box-drawing sections:"
grep -n "════.*Phase [0-9]" "$FILE"

echo ""
echo "Replace these sections with:"
echo "  emit_progress \"N\" \"Phase N: [description]\""
```

**Manual Changes Required**:

1. **Phase 0 header** (line ~621):
   ```bash
   # Before
   echo "Phase 0: Project Location and Path Pre-Calculation"

   # After
   emit_progress "0" "Phase 0: Location and path pre-calculation"
   ```

2. **Phase 1 header** (line ~745):
   ```bash
   # Before
   echo "════════════════════════════════════════════════════════"
   echo "  Phase 1: Research - Parallel Agent Invocation"
   echo "════════════════════════════════════════════════════════"

   # After
   emit_progress "1" "Phase 1: Research (parallel agent invocation)"
   ```

3. **Phase 2 header** (line ~970):
   ```bash
   # Before
   echo "════════════════════════════════════════════════════════"
   echo "  Phase 2: Planning - Plan-Architect Agent Invocation"
   echo "════════════════════════════════════════════════════════"

   # After
   emit_progress "2" "Phase 2: Planning (plan-architect invocation)"
   ```

[... repeat for Phases 3-6 ...]

**Benefits**:
- **Consistency**: All phase transitions use same format
- **Parseability**: External tools can monitor via grep "PROGRESS:"
- **Alignment**: Matches Spec 508 progress streaming standard
- **Simplicity**: Single function call vs multi-line echo blocks

## Priority Matrix

| Improvement | Priority | Effort | Impact | Risk | Order |
|-------------|----------|--------|--------|------|-------|
| Fix emit_progress error | Critical | Low (2-3h) | Critical (blocks execution) | Low | 1 |
| Simplify verification output | High | Medium (4-6h) | High (90% context reduction) | Low | 2 |
| Standardize progress markers | Medium | Low (1-2h) | Medium (consistency) | Minimal | 3 |
| Extract verification to library | Low | Medium (3-4h) | Low (maintainability) | Low | 4 |

**Recommended Implementation Sequence**:

1. **Phase 1** (Immediate - 2-3 hours):
   - Fix emit_progress error by restructuring Phase 0 library sourcing
   - Test command execution to verify fix
   - Validate no regressions in Phase 1-6 execution

2. **Phase 2** (Near-term - 4-6 hours):
   - Implement concise verification output format
   - Apply pattern to all 6 verification checkpoints
   - Measure context token reduction (target: 2,700 tokens saved)

3. **Phase 3** (Short-term - 1-2 hours):
   - Standardize progress markers across all phases
   - Remove box-drawing headers in favor of emit_progress
   - Update documentation to reflect new format

4. **Phase 4** (Long-term - 3-4 hours):
   - Extract verify_file_created to verification-utils.sh library
   - Update all orchestration commands to use shared library
   - Deprecate inline verification functions

**Total Effort**: 10-15 hours (prioritized by impact/risk ratio)

## Conclusion

The /coordinate command has two distinct issues requiring different solutions:

1. **Emit_progress error** (Critical): Caused by bash blocks calling library functions before library sourcing completes. Fixed by restructuring Phase 0 to source libraries first. Simple fix (2-3 hours), critical impact.

2. **Verbose verification output** (Medium): Caused by design tension between reliability (100% file creation) and efficiency (<30% context). Fixed by adopting concise success format with verbose failure diagnostics. Moderate effort (4-6 hours), high impact (90% context reduction).

Both fixes align with Spec 508 best practices:
- Library sourcing follows fail-fast bootstrap pattern
- Concise verification matches "silent progress markers" standard
- Preserved verbose diagnostics on failure maintain 100% file creation reliability

Implementation priority: Fix emit_progress error immediately (blocks execution), then apply verification format improvements to reduce context consumption and align with standards.

## References

### Primary Sources
- `/home/benjamin/.config/.claude/specs/coordinate_output.md` - Console output showing errors (lines 47-48, 92-96)
- `/home/benjamin/.config/.claude/specs/508_research_best_practices_for_using_commands_to_run_/reports/001_research_best_practices_for_using_commands_to_run_/OVERVIEW.md` - Best practices reference (lines 260-268, 269-287, 625-650)
- `/home/benjamin/.config/.claude/commands/coordinate.md` - Current /coordinate implementation (2,876 lines)

### Library Files
- `/home/benjamin/.config/.claude/lib/unified-logger.sh` - emit_progress function definition (lines 715-719)
- `/home/benjamin/.config/.claude/lib/library-sourcing.sh` - source_required_libraries implementation (lines 35-81)

### Related Specifications
- **Spec 495** (2025-10-27): /coordinate and /research delegation failures (12 invocations fixed)
- **Spec 057** (2025-10-27): /supervise robustness improvements (32 lines of bootstrap fallbacks removed)
- **Spec 497** (2025-10-27): Unified orchestration improvements
- **Spec 508** (2025-10-28): Best practices for context window preservation (this analysis)

### Comparison Commands
- `/home/benjamin/.config/.claude/commands/supervise.md` - Working library sourcing pattern
- `/home/benjamin/.config/.claude/commands/orchestrate.md` - Verbose verification pattern (similar issues)

### Standards Documentation
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` - Standard 11 (imperative agent invocation)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` - Behavioral injection pattern details
- `/home/benjamin/.config/.claude/docs/guides/orchestration-troubleshooting.md` - Debugging procedures
