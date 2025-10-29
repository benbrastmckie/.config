# Implementation Plan: /coordinate Error and Formatting Improvements

## Metadata

- **Plan ID**: 510-001
- **Related Spec**: 510_coordinate_error_and_formatting_improvements
- **Input Report**: 001_coordinate_error_formatting_analysis.md
- **Total Complexity**: 6.5/10
- **Estimated Total Time**: 6-8 hours
- **Risk Level**: Low-Medium
- **Priority**: Critical (Phase 1), High (Phase 2), Medium (Phase 3)

## Objectives

Fix critical emit_progress error blocking /coordinate execution and implement concise verification formatting to reduce context consumption while maintaining 100% file creation reliability and fail-fast error handling.

**Success Criteria**:
- /coordinate executes without "command not found" errors
- Verification output is concise (1-2 lines on success, verbose on failure)
- Maintains 100% file creation reliability
- Achieves <25% context usage throughout workflow
- Preserves fail-fast error handling with comprehensive diagnostics

## Overview

The /coordinate command has two distinct issues requiring targeted fixes:

1. **Critical Error** (blocks execution): `emit_progress: command not found` at line 48 caused by bash blocks executing before library sourcing completes
2. **High Priority** (context bloat): Verbose MANDATORY VERIFICATION output producing 50+ lines per checkpoint, consuming ~2000 tokens per workflow

Both issues have clear root causes and proven solutions from working commands (/supervise, /orchestrate). The fixes align with Spec 508 best practices and maintain the command's streamlined architecture.

## Phase 1: Fix Critical emit_progress Error

**Objective**: Restructure Phase 0 to source libraries before any bash blocks call library functions

**Priority**: Critical (blocks command execution)
**Complexity**: 2/10 (simple restructuring, proven pattern)
**Estimated Time**: 2-3 hours
**Risk**: Low (pattern proven in /supervise, /orchestrate)
**Dependencies**: None

### Root Cause Analysis

Current execution order (BROKEN):
1. Line 637-656: Phase 0 bash block executes (parses workflow description)
2. Line 682-708: Second bash block calls `emit_progress()` → **FAILS** (function not defined)
3. Lines 356-388: Library sourcing section processes (defines `emit_progress()`)

The error occurs because Claude processes bash blocks sequentially and executes them immediately via Bash tool, but library functions aren't available until the sourcing section completes.

### Tasks

#### Task 1.1: Relocate Library Sourcing to Phase 0 Beginning
**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
**Lines**: 621-742 (Phase 0 section)

**Actions**:
1. Remove library sourcing section from lines 356-388
2. Create new "STEP 0: Source Required Libraries" at line 626 (immediately after Phase 0 header)
3. Move entire sourcing block (including verification checks) to new STEP 0
4. Add explicit comment: `[EXECUTION-CRITICAL: Library sourcing MUST occur before any function calls]`

**Expected Result**:
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
  exit 1
fi

# Source all required libraries
if ! source_required_libraries "dependency-analyzer.sh"; then
  exit 1
fi

echo "✓ All libraries loaded successfully"

# Verify critical functions are defined
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
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")  # NOW WORKS

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

#### Task 1.2: Update Section References
**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`

**Actions**:
1. Update "Shared Utility Functions" section header to reflect that sourcing now happens in Phase 0
2. Remove redundant sourcing block from lines 350-388
3. Update internal documentation references to point to Phase 0 STEP 0

**Implementation**:
- Update line 350 header: `## Shared Utility Functions` → `## Available Utility Functions`
- Remove bash block at lines 354-388
- Add note: "See Phase 0 STEP 0 for library sourcing implementation"

#### Task 1.3: Validation Testing
**Method**: Manual execution test

**Test Cases**:
1. Test basic execution: `/coordinate "research authentication patterns"`
2. Verify emit_progress works: Check for `PROGRESS: [Phase 0]` markers in output
3. Verify scope detection: Confirm workflow scope detected correctly
4. Test error case: Run with missing library file to verify fail-fast error handling

**Expected Output**:
```
✓ All libraries loaded successfully
PROGRESS: [Phase 0] - Libraries loaded and verified
PROGRESS: [Phase 0] - Workflow description parsed
PROGRESS: [Phase 0] - Workflow scope detected: research-only
Phases to execute: 0,1
```

**Validation Criteria**:
- ✓ No "command not found" errors
- ✓ emit_progress markers appear in output
- ✓ Workflow continues to Phase 1 successfully
- ✓ Error messages clear if library missing

### Risk Mitigation

**Risk 1**: Breaking existing Phase 0 logic
- **Mitigation**: Preserve all existing bash blocks, only reorder them
- **Validation**: Test with multiple workflow types (research-only, full-implementation, debug-only)

**Risk 2**: Function verification failures
- **Mitigation**: Use proven verification pattern from /supervise
- **Validation**: Test with intentionally missing function to verify detection

### Success Criteria

- [ ] emit_progress() available in all Phase 0 bash blocks
- [ ] No "command not found" errors during execution
- [ ] Library sourcing completes before any function calls
- [ ] Verification checks catch missing functions
- [ ] Error messages provide clear diagnostics

---

## Phase 2: Simplify Verification Output Formatting

**Objective**: Implement concise verification format (1-2 lines success, verbose failure) to reduce context consumption by 90%

**Priority**: High (context bloat, user experience degradation)
**Complexity**: 3/10 (straightforward pattern application)
**Estimated Time**: 3-4 hours
**Risk**: Low (preserves diagnostic quality on failure)
**Dependencies**: Phase 1 (requires working emit_progress)

### Root Cause Analysis

Current verification pattern produces 50+ lines per checkpoint:
- 80-character box-drawing headers (top + bottom)
- Multi-line status per verified item
- Redundant "Expected/Found" for every success case
- Total: ~500 tokens per checkpoint × 7 checkpoints = 3,500 tokens (17.5% of budget)

Best practice from Spec 508:
- Single-line success: `Verifying reports (4): ✓✓✓✓ (all passed)`
- Verbose failure: Full diagnostics with suggested actions
- Token savings: 500 → 50 tokens (90% reduction)

### Tasks

#### Task 2.1: Create Inline Verification Helper Function
**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
**Location**: After Phase 0, before Phase 1 (around line 743)

**Actions**:
1. Add section header: `## Verification Helper Functions`
2. Define `verify_file_created()` function inline
3. Document function signature and return values

**Implementation**:
```markdown
## Verification Helper Functions

[EXECUTION-CRITICAL: Helper functions for concise verification - defined inline for immediate availability]

The following helper functions implement concise verification with silent success and verbose failure patterns.

```bash
# verify_file_created - Concise file verification with optional verbose failure
#
# Arguments:
#   $1 - file_path (absolute path to verify)
#   $2 - item_description (e.g., "Research report 1/4")
#   $3 - phase_name (e.g., "Phase 1")
#
# Returns:
#   0 - File exists and has content (prints single ✓ character)
#   1 - File missing or empty (prints verbose diagnostic)
#
# Output:
#   Success: Single character "✓" (no newline)
#   Failure: Multi-line diagnostic with suggested actions
#
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
    [ ! -f "$file_path" ] && echo "   Found: File does not exist" || echo "   Found: File empty (0 bytes)"
    echo ""
    echo "DIAGNOSTIC INFORMATION:"
    echo "  - Expected path: $file_path"
    echo "  - Parent directory: $(dirname "$file_path")"

    local dir="$(dirname "$file_path")"
    if [ -d "$dir" ]; then
      local file_count
      file_count=$(ls -1 "$dir" 2>/dev/null | wc -l)
      echo "  - Directory status: ✓ Exists ($file_count files)"
      if [ "$file_count" -gt 0 ]; then
        echo "  - Recent files:"
        ls -lht "$dir" | head -4
      fi
    else
      echo "  - Directory status: ✗ Does not exist"
      echo "  - Fix: mkdir -p $dir"
    fi
    echo ""
    echo "Diagnostic commands:"
    echo "  ls -la $dir"
    echo "  cat .claude/agents/[agent-name].md | head -50"
    echo ""
    return 1
  fi
}

export -f verify_file_created
```
```

#### Task 2.2: Replace Phase 1 Verification Section
**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
**Lines**: 825-890 (Phase 1 research report verification)

**Actions**:
1. Replace verbose verification loop with concise pattern
2. Use verify_file_created() helper function
3. Preserve partial failure handling (≥50% threshold)
4. Add emit_progress marker after successful verification

**Before** (50+ lines):
```bash
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"
  emit_progress "1" "Verifying research report $i/$RESEARCH_COMPLEXITY"

  if [ -f "$REPORT_PATH" ] && [ -s "$REPORT_PATH" ]; then
    FILE_SIZE=$(wc -c < "$REPORT_PATH")
    echo "  Status: ✓ PASSED ($FILE_SIZE bytes)"
    SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
  else
    echo "  ❌ ERROR [Phase 1, Research]: Report file verification failed"
    # ... 30+ lines of diagnostics ...
  fi
done
```

**After** (5-10 lines):
```bash
# Concise verification with inline status indicators
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

# VERIFICATION REQUIREMENT: Must not proceed without verification
echo "Verification checkpoint passed - proceeding to research overview"
echo ""
```

#### Task 2.3: Apply Pattern to Phase 2 Verification
**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
**Lines**: 1047-1089 (Phase 2 plan file verification)

**Actions**:
1. Replace verbose plan verification with concise pattern
2. Preserve phase count and complexity checks
3. Add emit_progress marker

**Implementation**:
```bash
echo -n "Verifying implementation plan: "

if verify_file_created "$PLAN_PATH" "Implementation plan" "Phase 2"; then
  PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo "0")
  if [ "$PHASE_COUNT" -lt 3 ] || ! grep -q "^## Metadata" "$PLAN_PATH"; then
    echo " (structure warnings)"
    echo "⚠️  Plan: $PHASE_COUNT phases (expected ≥3)"
  else
    echo " ($PHASE_COUNT phases)"
  fi
  emit_progress "2" "Verified: Implementation plan ($PHASE_COUNT phases)"
else
  echo ""
  echo "Workflow TERMINATED: Fix plan creation and retry"
  exit 1
fi
```

#### Task 2.4: Apply Pattern to Phase 3-6 Verification
**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
**Sections**: Phase 3 (implementation), Phase 4 (tests), Phase 5 (debug), Phase 6 (summary)

**Actions**:
1. Phase 3 (lines 1261-1306): Replace implementation artifacts verification
2. Phase 4 (lines 1405-1450): Keep existing format (test results are different)
3. Phase 5 (lines 1515-1531): Replace debug report verification
4. Phase 6 (lines 1682-1710): Replace summary file verification

**Phase 3 Implementation Verification**:
```bash
echo -n "Verifying implementation artifacts: "

if [ -d "$IMPL_ARTIFACTS" ]; then
  ARTIFACT_COUNT=$(find "$IMPL_ARTIFACTS" -type f 2>/dev/null | wc -l)
  echo "✓ ($ARTIFACT_COUNT files)"
  emit_progress "3" "Verified: Implementation artifacts ($ARTIFACT_COUNT files)"
else
  echo ""
  echo "✗ ERROR [Phase 3]: Implementation artifacts directory not created"
  echo "   Expected: Directory exists at $IMPL_ARTIFACTS"
  echo ""
  echo "DIAGNOSTIC INFORMATION:"
  echo "  - Status: $IMPL_STATUS (waves: $WAVES_COMPLETED/$WAVE_COUNT)"
  echo "  - Duration: ${IMPL_MINUTES}m${IMPL_SECONDS}s"
  echo ""
  echo "Workflow TERMINATED."
  exit 1
fi
```

**Phase 5 Debug Report Verification**:
```bash
echo -n "Verifying debug report (iteration $iteration): "

if verify_file_created "$DEBUG_REPORT" "Debug report" "Phase 5"; then
  echo ""
else
  echo ""
  echo "Workflow TERMINATED: Fix debug report creation and retry"
  exit 1
fi
```

**Phase 6 Summary Verification**:
```bash
echo -n "Verifying workflow summary: "

if verify_file_created "$SUMMARY_PATH" "Workflow summary" "Phase 6"; then
  FILE_SIZE=$(wc -c < "$SUMMARY_PATH")
  echo " (${FILE_SIZE} bytes)"
  emit_progress "6" "Verified: Workflow summary created"
else
  echo ""
  echo "Workflow TERMINATED: Fix summary creation and retry"
  exit 1
fi
```

#### Task 2.5: Measure Context Reduction
**Method**: Token counting comparison

**Measurements**:
1. Capture output before changes (verbose format)
2. Capture output after changes (concise format)
3. Calculate token counts using `wc -c` as proxy
4. Verify ≥90% reduction target achieved

**Expected Results**:
- Before: ~3,500 tokens (7 checkpoints × 500 tokens)
- After: ~350 tokens (7 checkpoints × 50 tokens)
- Reduction: 90% (3,150 tokens saved)
- Context budget impact: 15.8% → 1.8% (14% improvement)

### Risk Mitigation

**Risk 1**: Loss of diagnostic quality on failures
- **Mitigation**: Preserve all diagnostic output in failure path
- **Validation**: Test with intentional failures to verify diagnostics present

**Risk 2**: User confusion with minimal output
- **Mitigation**: Clear success indicators (✓✓✓✓ pattern), emit_progress markers
- **Validation**: User acceptance testing with sample workflows

**Risk 3**: Regression in file creation reliability
- **Mitigation**: No changes to verification logic, only output format
- **Validation**: Run test suite to verify 100% creation rate maintained

### Success Criteria

- [ ] Success output reduced from 50+ lines to 1-2 lines
- [ ] Failure output remains verbose with full diagnostics
- [ ] Token reduction ≥90% (3,150+ tokens saved)
- [ ] 100% file creation reliability maintained
- [ ] emit_progress markers consistent across all phases
- [ ] User can quickly scan output for pass/fail status

---

## Phase 3: Standardize Progress Markers and Alignment

**Objective**: Standardize progress marker usage across all phases and ensure full Spec 508 compliance

**Priority**: Medium (consistency and standards alignment)
**Complexity**: 1.5/10 (simple find/replace pattern)
**Estimated Time**: 1-2 hours
**Risk**: Minimal (no functional changes)
**Dependencies**: Phase 1 (requires working emit_progress)

### Root Cause Analysis

Current implementation has inconsistent progress markers:
- Some use emit_progress (correct)
- Some use echo with box-drawing (verbose)
- Some use plain echo (not parseable)
- Total: Mixed patterns reduce parseability and consistency

Spec 508 standard:
- All phase transitions use emit_progress
- Format: `PROGRESS: [Phase N] - action`
- Silent markers (no verbose output)
- Externally parseable via `grep "PROGRESS:"`

### Tasks

#### Task 3.1: Audit Progress Marker Usage
**Method**: Grep analysis

**Actions**:
1. Find all phase transition markers: `grep -n "Phase [0-9]" coordinate.md`
2. Identify echo statements that should use emit_progress
3. Document replacement patterns

**Expected Findings**:
- ~15-20 echo statements to replace
- ~10 box-drawing headers to remove
- ~5 phase completion messages to standardize

#### Task 3.2: Replace Box-Drawing Phase Headers
**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
**Sections**: All phase headers (0-6)

**Pattern Replacements**:

Before:
```bash
echo "════════════════════════════════════════════════════════"
echo "  Phase 1: Research - Parallel Agent Invocation"
echo "════════════════════════════════════════════════════════"
```

After:
```bash
emit_progress "1" "Phase 1: Research (parallel agent invocation)"
```

**Sections to Update**:
1. Phase 0 header (line ~621): `emit_progress "0" "Phase 0: Location and path pre-calculation"`
2. Phase 1 header (line ~745): `emit_progress "1" "Phase 1: Research (parallel agent invocation)"`
3. Phase 2 header (line ~970): `emit_progress "2" "Phase 2: Planning (plan-architect invocation)"`
4. Phase 3 header (line ~1188): `emit_progress "3" "Phase 3: Wave-based implementation"`
5. Phase 4 header (line ~1360): `emit_progress "4" "Phase 4: Testing (test-specialist invocation)"`
6. Phase 5 header (line ~1465): `emit_progress "5" "Phase 5: Debug (conditional execution)"`
7. Phase 6 header (line ~1636): `emit_progress "6" "Phase 6: Documentation (summary creation)"`

#### Task 3.3: Standardize Phase Completion Messages
**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`

**Pattern Replacements**:

Before:
```bash
echo "Phase 1 Complete: Research artifacts verified"
echo "✓ Verified: $COUNT reports"
```

After:
```bash
emit_progress "1" "Phase 1 complete: $COUNT reports verified"
```

**Sections to Update**:
1. Phase 1 completion (line ~945): `emit_progress "1" "Phase 1 complete: Research artifacts verified"`
2. Phase 2 completion (line ~1104): `emit_progress "2" "Phase 2 complete: Planning artifacts verified"`
3. Phase 3 completion (line ~1347): `emit_progress "3" "Phase 3 complete: Implementation verified"`
4. Phase 4 completion (line ~1450): `emit_progress "4" "Phase 4 complete: Test results recorded"`
5. Phase 5 completion (line ~1611): `emit_progress "5" "Phase 5 complete: Debug cycle finished"`
6. Phase 6 completion (line ~1710): `emit_progress "6" "Phase 6 complete: Documentation created"`

#### Task 3.4: Remove Redundant Status Echoes
**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`

**Actions**:
1. Remove duplicate status messages after emit_progress
2. Remove verbose "Phase N Complete" echo statements
3. Keep only emit_progress markers

**Examples**:
```bash
# Remove this pattern:
emit_progress "1" "Research complete"
echo "Phase 1 Complete: Research artifacts verified"  # REMOVE (redundant)

# Keep only:
emit_progress "1" "Phase 1 complete: Research artifacts verified"
```

#### Task 3.5: Validate Progress Marker Consistency
**Method**: Grep validation

**Test Commands**:
```bash
# Check all emit_progress calls follow pattern
grep -n "emit_progress" coordinate.md | grep -v "PROGRESS: \[Phase [0-9]\]"

# Expected: No results (all markers follow standard format)
```

**Validation Criteria**:
- All phase transitions use emit_progress
- No box-drawing headers remain
- Format consistent: `PROGRESS: [Phase N] - action`
- External parseability confirmed

### Risk Mitigation

**Risk 1**: Breaking existing monitoring tools
- **Mitigation**: Preserve PROGRESS: prefix format
- **Validation**: Test with external grep patterns

**Risk 2**: Loss of visual clarity
- **Mitigation**: emit_progress provides consistent structure
- **Validation**: User acceptance testing

### Success Criteria

- [ ] All phase transitions use emit_progress
- [ ] No box-drawing headers remain
- [ ] Format consistent across all 7 phases
- [ ] Externally parseable via `grep "PROGRESS:"`
- [ ] No redundant status messages
- [ ] User can monitor progress programmatically

---

## Dependencies and Sequencing

### Critical Path
```
Phase 1 (Library Sourcing Fix) → Phase 2 (Verification Format) → Phase 3 (Progress Markers)
```

**Rationale**:
1. Phase 1 MUST complete first (unblocks command execution)
2. Phase 2 depends on emit_progress working (from Phase 1)
3. Phase 3 depends on emit_progress working (from Phase 1)
4. Phases 2 and 3 are independent and could run in parallel

### Phase Dependencies
- **Phase 1**: No dependencies (foundation)
- **Phase 2**: Depends on Phase 1 (requires emit_progress)
- **Phase 3**: Depends on Phase 1 (requires emit_progress)

### Parallel Execution Opportunity
Phases 2 and 3 could be implemented in parallel by different developers, but sequential execution is simpler for a single developer and ensures no conflicts.

---

## Testing Strategy

### Test Categories

#### 1. Unit Testing (Phase 1)
**Scope**: Library sourcing and function availability

**Test Cases**:
1. Test emit_progress available after sourcing
2. Test detect_workflow_scope available
3. Test all required functions defined
4. Test error handling when library missing

**Method**: Manual bash execution
**Success Criteria**: All functions available, no "command not found" errors

#### 2. Integration Testing (Phase 2)
**Scope**: Verification format across all phases

**Test Cases**:
1. Test research report verification (success case)
2. Test research report verification (failure case)
3. Test plan verification (success case)
4. Test plan verification (failure case)
5. Test implementation verification
6. Test summary verification

**Method**: Full workflow execution with intentional failures
**Success Criteria**: Success output concise (1-2 lines), failure output verbose

#### 3. Regression Testing (All Phases)
**Scope**: Ensure no existing functionality broken

**Test Cases**:
1. Test research-only workflow
2. Test research-and-plan workflow
3. Test full-implementation workflow
4. Test debug-only workflow
5. Test checkpoint resume
6. Test partial research failure handling

**Method**: Execute all workflow types end-to-end
**Success Criteria**: 100% file creation rate, correct phase execution

#### 4. Performance Testing (Phase 2)
**Scope**: Context reduction measurement

**Test Cases**:
1. Measure token count before changes
2. Measure token count after changes
3. Calculate reduction percentage
4. Verify <25% context usage target

**Method**: Token counting with sample workflows
**Success Criteria**: ≥90% reduction in verification output tokens

### Test Execution Plan

**Phase 1 Testing**:
1. Run `/coordinate "test workflow"` before changes (expect error)
2. Apply Phase 1 changes
3. Run `/coordinate "test workflow"` after changes (expect success)
4. Verify emit_progress markers in output
5. Test error case (missing library)

**Phase 2 Testing**:
1. Run full workflow with all verification checkpoints
2. Capture output and count lines/tokens
3. Intentionally fail one verification (delete expected file)
4. Verify verbose diagnostics appear
5. Compare before/after token counts

**Phase 3 Testing**:
1. Run `grep "PROGRESS:" coordinate_output.log`
2. Verify all phase transitions present
3. Verify format consistent
4. Test external monitoring script

---

## Risk Assessment

### Overall Risk Level: Low-Medium

**Risk Factors**:
1. **Critical Error Fix** (Phase 1): Low risk, proven pattern
2. **Format Changes** (Phase 2): Low risk, preserves diagnostic quality
3. **Progress Markers** (Phase 3): Minimal risk, no functional changes

### Mitigation Strategies

**Strategy 1**: Incremental Implementation
- Complete Phase 1 and validate before Phase 2
- Complete Phase 2 and validate before Phase 3
- Each phase independently testable

**Strategy 2**: Preserve Existing Behavior
- No changes to verification logic (only output format)
- Preserve fail-fast error handling
- Maintain 100% file creation reliability

**Strategy 3**: Comprehensive Testing
- Test all workflow types after each phase
- Validate context reduction metrics
- Confirm diagnostic quality maintained

### Rollback Plan

**If Phase 1 fails**:
- Revert coordinate.md to previous version
- Investigate library sourcing issue
- Consult /supervise pattern for reference

**If Phase 2 fails**:
- Revert verification sections only
- Keep Phase 1 changes (library sourcing)
- Re-evaluate concise format approach

**If Phase 3 fails**:
- Revert progress marker changes only
- Keep Phases 1-2 changes
- Retain mixed format temporarily

---

## Implementation Notes

### Code Quality Standards

**Bash Style**:
- 2-space indentation
- Quote all variables: `"$VARIABLE"`
- Use `[[ ]]` for conditionals (not `[ ]`)
- Explicit error handling: `set -e` or explicit checks

**Documentation**:
- Function signatures with arguments and return values
- Inline comments for non-obvious logic
- Section headers for major blocks

**Testing**:
- Test all success paths
- Test all failure paths
- Verify error messages clear and actionable

### Spec 508 Alignment Checklist

- [x] **Progress Streaming**: emit_progress for all phase transitions
- [x] **Fail-Fast Error Handling**: Preserved in all phases
- [x] **Context Reduction**: 90% reduction in verification output
- [x] **Library Integration**: Sourcing happens before function calls
- [x] **Silent Success Pattern**: Concise output unless error
- [x] **Verbose Failure Pattern**: Full diagnostics on errors

### Performance Targets

**Context Usage** (before → after):
- Research verification: 500 tokens → 50 tokens
- Plan verification: 500 tokens → 50 tokens
- Implementation verification: 500 tokens → 50 tokens
- Test verification: 200 tokens → 200 tokens (unchanged)
- Debug verification: 500 tokens → 50 tokens
- Summary verification: 500 tokens → 50 tokens
- **Total**: 2,700 tokens → 450 tokens (83% reduction)

**Time Savings**:
- Phase 1: No time impact (fixes error)
- Phase 2: ~5% faster (less output processing)
- Phase 3: No time impact (cosmetic changes)

**Reliability**:
- 100% file creation rate (maintained)
- Fail-fast error handling (maintained)
- Diagnostic quality (maintained on failures)

---

## Completion Checklist

### Phase 1: Library Sourcing Fix
- [ ] Library sourcing moved to Phase 0 STEP 0
- [ ] emit_progress available in all Phase 0 bash blocks
- [ ] Function verification checks added
- [ ] Error messages clear and actionable
- [ ] Manual testing passed (all workflow types)
- [ ] No "command not found" errors

### Phase 2: Verification Format
- [ ] verify_file_created() helper function created
- [ ] Phase 1 verification updated (research reports)
- [ ] Phase 2 verification updated (plan file)
- [ ] Phase 3 verification updated (implementation)
- [ ] Phase 5 verification updated (debug report)
- [ ] Phase 6 verification updated (summary file)
- [ ] Context reduction ≥90% achieved
- [ ] Failure diagnostics preserved and tested
- [ ] Token counting measurements documented

### Phase 3: Progress Markers
- [ ] All phase headers use emit_progress
- [ ] Box-drawing headers removed
- [ ] Phase completion messages standardized
- [ ] Redundant echo statements removed
- [ ] Format consistent across all phases
- [ ] External parseability confirmed
- [ ] Grep validation passed

### Overall Validation
- [ ] All workflow types tested (research, plan, implement, debug)
- [ ] 100% file creation reliability maintained
- [ ] Checkpoint resume functionality tested
- [ ] Partial failure handling tested
- [ ] Context usage <25% throughout workflow
- [ ] User acceptance testing passed
- [ ] Documentation updated

---

## Related Specifications

**Primary References**:
- **Spec 508**: Best practices for context window preservation
- **Spec 495**: /coordinate and /research delegation failures (anti-pattern fixes)
- **Spec 057**: /supervise robustness improvements (fail-fast error handling)
- **Spec 497**: Unified orchestration improvements

**Pattern References**:
- [Behavioral Injection Pattern](../../docs/concepts/patterns/behavioral-injection.md)
- [Verification and Fallback Pattern](../../docs/concepts/patterns/verification-fallback.md)
- [Context Management Pattern](../../docs/concepts/patterns/context-management.md)

**Command References**:
- `/supervise` - Working library sourcing pattern (reference implementation)
- `/orchestrate` - Similar verification patterns (could apply same fixes)

---

## Success Metrics

### Quantitative Metrics
- **Error Rate**: 0% (no "command not found" errors)
- **Context Reduction**: ≥90% in verification output (2,700 → 450 tokens)
- **File Creation Rate**: 100% (maintained)
- **Test Pass Rate**: 100% (all workflow types)
- **Time Savings**: 5% faster (reduced output processing)

### Qualitative Metrics
- **User Experience**: Immediate visual scan for pass/fail status
- **Code Quality**: Consistent progress marker format
- **Maintainability**: Single verification helper function (reusable)
- **Standards Alignment**: Full Spec 508 compliance

### Acceptance Criteria
- /coordinate executes without errors
- Verification output concise and scannable
- Diagnostics comprehensive on failures
- Context usage <25% throughout workflow
- User can monitor progress programmatically
- All existing functionality preserved

---

## Post-Implementation Tasks

### Documentation Updates
1. Update /coordinate command documentation
2. Document verification helper function
3. Add examples of new output format
4. Update troubleshooting guide

### Knowledge Sharing
1. Share verification pattern with /orchestrate maintainers
2. Consider extracting verify_file_created to shared library
3. Document Spec 508 alignment achievements

### Future Enhancements
1. Extract verification helper to `.claude/lib/verification-utils.sh` (Low priority)
2. Apply same pattern to /orchestrate command (Separate spec)
3. Consider progress marker parsing tools (External)

---

## Appendix A: Output Format Examples

### Before Changes (Verbose)

```
════════════════════════════════════════════════════════
  MANDATORY VERIFICATION - Research Reports
════════════════════════════════════════════════════════

Verifying research report 1/4...
  Path: /path/to/report1.md
  Expected: File exists with content
  Status: ✓ PASSED (25000 bytes)

Verifying research report 2/4...
  Path: /path/to/report2.md
  Expected: File exists with content
  Status: ✓ PASSED (30000 bytes)

Verifying research report 3/4...
  Path: /path/to/report3.md
  Expected: File exists with content
  Status: ✓ PASSED (28000 bytes)

Verifying research report 4/4...
  Path: /path/to/report4.md
  Expected: File exists with content
  Status: ✓ PASSED (32000 bytes)

════════════════════════════════════════════════════════
VERIFICATION COMPLETE - 4/4 reports created
════════════════════════════════════════════════════════
```

**Analysis**: 24 lines, ~500 tokens

### After Changes (Concise Success)

```
Verifying research reports (4): ✓✓✓✓ (all passed)
PROGRESS: [Phase 1] - Verified: 4/4 research reports
```

**Analysis**: 2 lines, ~50 tokens (90% reduction)

### After Changes (Verbose Failure)

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

**Analysis**: Diagnostics preserved, clear failure indication, actionable guidance

---

## Appendix B: Complexity Justification

### Phase 1 Complexity: 2/10
- Simple structural change (move bash blocks)
- Proven pattern from /supervise
- No algorithm changes
- Clear success criteria

### Phase 2 Complexity: 3/10
- Straightforward pattern application
- Helper function simple (30 lines)
- Apply to 6 verification checkpoints
- Testing straightforward

### Phase 3 Complexity: 1.5/10
- Simple find/replace pattern
- No functional changes
- Cosmetic improvements only
- Low risk

### Total Complexity: 6.5/10
- Moderate overall complexity
- Well-defined scope
- Clear success criteria
- Low risk implementation
