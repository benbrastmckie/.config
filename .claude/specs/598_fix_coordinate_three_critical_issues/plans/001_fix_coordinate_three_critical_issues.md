# Fix /coordinate Three Critical Issues

## Metadata
- **Date**: 2025-11-05
- **Feature**: Fix three critical /coordinate issues preventing full-implementation workflows
- **Scope**: Add missing library, complete stateless recalculation pattern, fix phase execution list
- **Estimated Phases**: 3
- **Complexity**: Low-Medium (3/10)
- **Estimated Total Time**: 30-45 minutes
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Related Specs**:
  - Spec 597 (stateless recalculation pattern - completed)
  - Specs 582-594 (variable persistence research)
- **Reference Files**:
  - Console output: /home/benjamin/.config/.claude/specs/coordinate_output.md (lines 75-77, 100-103, 132-139)
  - Previous fix: /home/benjamin/.config/.claude/specs/597_fix_coordinate_variable_persistence/plans/002_fix_coordinate_variable_persistence_revised.md

## Overview

The /coordinate command has three interconnected issues preventing full-implementation workflows from executing beyond Phase 2:

1. **Issue 1: Exit Code 127 - Missing Library Functions**
   - Functions `should_synthesize_overview()`, `get_synthesis_skip_reason()`, and `calculate_overview_path()` are undefined
   - Root cause: `overview-synthesis.sh` library not included in any REQUIRED_LIBS array
   - Impact: Phase 1 Research overview synthesis fails with "command not found" errors

2. **Issue 2: PHASES_TO_EXECUTE Unbound Variable**
   - Variable set in Block 1 but not recalculated in subsequent bash blocks
   - Root cause: Incomplete stateless recalculation pattern from spec 597
   - Impact: `should_run_phase()` function fails when checking phase execution permissions

3. **Issue 3: Wrong Phase List for full-implementation**
   - Current value: `"0,1,2,3,4"` (missing phase 6)
   - Correct value: `"0,1,2,3,4,6"` (per documentation at line 427)
   - Impact: Even if Issue 2 is fixed, Phase 3 would be skipped incorrectly

## Root Cause Analysis

### Issue 1: Missing Library in REQUIRED_LIBS Arrays

**File**: `.claude/commands/coordinate.md` lines 649-692

**Problem**: The conditional library loading logic defines 4 library sets (research-only, research-and-plan, full-implementation, debug-only) but none include `overview-synthesis.sh`:

```bash
# Current code (INCOMPLETE)
case "$WORKFLOW_SCOPE" in
  research-only)
    REQUIRED_LIBS=(
      "workflow-detection.sh"
      "unified-logger.sh"
      "unified-location-detection.sh"
      # MISSING: overview-synthesis.sh
    )
    ;;
  research-and-plan)
    REQUIRED_LIBS=(
      "workflow-detection.sh"
      "unified-logger.sh"
      "unified-location-detection.sh"
      "metadata-extraction.sh"
      "checkpoint-utils.sh"
      # MISSING: overview-synthesis.sh
    )
    ;;
  # ... full-implementation and debug-only also missing it
esac
```

**Why It's Needed**: Phase 1 Research (lines 1222-1283) calls these functions to determine if OVERVIEW.md synthesis should occur based on workflow scope.

### Issue 2: Incomplete Stateless Recalculation

**File**: `.claude/commands/coordinate.md` lines 904-936 (Block 3)

**Problem**: Spec 597 added recalculation for `WORKFLOW_DESCRIPTION` and `WORKFLOW_SCOPE` but did NOT add the derived variable `PHASES_TO_EXECUTE` that depends on `WORKFLOW_SCOPE`.

**Current Block 3 Code** (lines 904-936):
```bash
# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Re-initialize workflow variables (added by spec 597)
WORKFLOW_DESCRIPTION="$1"

# Inline scope detection (50 lines of logic)
WORKFLOW_SCOPE="research-and-plan"  # Default
# ... detection logic ...

# MISSING: PHASES_TO_EXECUTE calculation based on WORKFLOW_SCOPE
# This variable is used by should_run_phase() throughout the workflow
```

**What's Missing**: The `case` statement that maps `WORKFLOW_SCOPE` to `PHASES_TO_EXECUTE` (exists in Block 1 lines 607-626 but not in Block 3).

**Impact Chain**:
1. Block 3 recalculates `WORKFLOW_SCOPE` correctly
2. Block 3 does NOT recalculate `PHASES_TO_EXECUTE`
3. Phase 1 executes (doesn't check `should_run_phase`)
4. Phase 2 executes (doesn't check `should_run_phase`)
5. Phase 2 completion check calls `should_run_phase 3` (line 1469)
6. Function tries to use undefined `PHASES_TO_EXECUTE`
7. Error: "PHASES_TO_EXECUTE: unbound variable" at workflow-detection.sh:182

### Issue 3: Wrong Phase List Value

**File**: `.claude/commands/coordinate.md` line 617 (Block 1)

**Problem**: The phase list for full-implementation workflows is missing phase 6 (Documentation).

**Current Code** (line 617):
```bash
full-implementation)
  PHASES_TO_EXECUTE="0,1,2,3,4"  # WRONG: missing phase 6
  SKIP_PHASES="5"                # Phase 5 conditional
  ;;
```

**Documentation Says** (line 427):
```bash
full-implementation)
  PHASES_TO_EXECUTE="0,1,2,3,4,6"  # CORRECT: includes phase 6
  ;;
```

**Comment Says** (line 618):
```bash
# Phase 5 conditional on test failures, Phase 6 always
```

**Inconsistency**: Comment says "Phase 6 always" but code doesn't include it.

**Why This Matters**: Even if Issues 1 and 2 are fixed, `should_run_phase 3` would check if "3" is in "0,1,2,3,4,6" and proceed correctly. But without phase 6 in the list, Phase 6 (Documentation) would be skipped.

## How Issues Are Connected

```
Issue 1 (Missing library)
  └─→ Phase 1 bash exit 127
  └─→ Workflow continues after fallback (lines 79-84)

Issue 2 (Unbound variable)
  └─→ Phase 2 completion check fails
  └─→ should_run_phase 3 errors

Issue 3 (Wrong phase list)
  └─→ Even if Issue 2 fixed, phase list still wrong
  └─→ Phase 6 would be skipped
  └─→ Workflow would still be incomplete
```

All three issues must be fixed for full-implementation workflows to execute correctly.

## Success Criteria

- [x] overview-synthesis.sh added to all 4 REQUIRED_LIBS arrays
- [x] PHASES_TO_EXECUTE mapping logic duplicated to Block 3 after WORKFLOW_SCOPE detection
- [x] full-implementation phase list corrected to "0,1,2,3,4,6" in both blocks
- [x] All 4 workflow types execute without "command not found" or "unbound variable" errors
- [x] Full-implementation workflow executes all phases: 0, 1, 2, 3, 4, 6
- [x] Orchestration test suite passes (12/12 tests)
- [x] Console output clean (no grep matches for "unbound\|command not found")

## Implementation Phases

### Phase 1: Add overview-synthesis.sh to REQUIRED_LIBS Arrays [COMPLETED]

**Objective**: Include overview-synthesis.sh in conditional library loading for all workflow types.

**Complexity**: Low (1/10)

**Files Modified**: `.claude/commands/coordinate.md`

**Line Range**: 649-692

Tasks:
- [x] Add `"overview-synthesis.sh"` to research-only REQUIRED_LIBS array (after line 655)
- [x] Add `"overview-synthesis.sh"` to research-and-plan REQUIRED_LIBS array (after line 665)
- [x] Add `"overview-synthesis.sh"` to full-implementation REQUIRED_LIBS array (after line 678)
- [x] Add `"overview-synthesis.sh"` to debug-only REQUIRED_LIBS array (after line 689)
- [x] Update library count comments to reflect new totals (4, 6, 9, 7 respectively)

**Before** (research-only example, line 652-656):
```bash
research-only)
  # Minimal set: 3 libraries for simple research workflows
  REQUIRED_LIBS=(
    "workflow-detection.sh"
    "unified-logger.sh"
    "unified-location-detection.sh"
  )
  ;;
```

**After** (research-only example):
```bash
research-only)
  # Minimal set: 4 libraries for simple research workflows
  REQUIRED_LIBS=(
    "workflow-detection.sh"
    "unified-logger.sh"
    "unified-location-detection.sh"
    "overview-synthesis.sh"
  )
  ;;
```

**Apply Same Change To**:
- research-and-plan (lines 658-667): 5→6 libraries
- full-implementation (lines 669-680): 8→9 libraries
- debug-only (lines 682-691): 6→7 libraries

**Testing**:
```bash
# Test library availability after Phase 0
/coordinate "research test topic" 2>&1 | grep "should_synthesize_overview: command not found"
# Expected: No matches (function defined)

# Verify all 4 scopes load the library
for scope in "research-only" "research-and-plan" "full-implementation" "debug-only"; do
  echo "Testing $scope..."
  # Extract workflow description that triggers each scope and test
done
```

**Validation**:
- [ ] Phase 1 overview synthesis section (lines 1222-1283) executes without "command not found" errors
- [ ] `should_synthesize_overview()` callable in all 4 workflow types
- [ ] `get_synthesis_skip_reason()` callable when skipping synthesis
- [ ] `calculate_overview_path()` callable when creating overview

---

### Phase 2: Complete Stateless Recalculation in Block 3 [COMPLETED]

**Objective**: Add PHASES_TO_EXECUTE calculation to Block 3, completing the stateless recalculation pattern from spec 597.

**Complexity**: Low (2/10)

**Files Modified**: `.claude/commands/coordinate.md`

**Line Range**: 904-936 (Block 3, STEP 0.6)

**Pattern Source**: Spec 597 established the stateless recalculation pattern. This phase extends it to include ALL derived variables.

Tasks:
- [x] Locate Block 3 after WORKFLOW_SCOPE recalculation (after line 936)
- [x] Duplicate PHASES_TO_EXECUTE mapping logic from Block 1 (lines 607-626)
- [x] Add 25 lines of case statement mapping WORKFLOW_SCOPE to PHASES_TO_EXECUTE
- [x] Export PHASES_TO_EXECUTE for use by should_run_phase() in subsequent blocks
- [x] Add comment explaining why duplication is necessary (Bash tool isolation)
- [x] Update PHASES_TO_EXECUTE values to include corrected full-implementation list (see Phase 3)

**Current Block 3 Code** (lines 904-936, simplified):
```bash
# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Re-initialize workflow variables (spec 597 addition)
WORKFLOW_DESCRIPTION="$1"

# Inline scope detection (50 lines)
WORKFLOW_SCOPE="research-and-plan"  # Default
# ... detection logic ...
# ... WORKFLOW_SCOPE calculated correctly ...

# ──────────────────────────────────────────────────────────────────
# CURRENTLY MISSING: PHASES_TO_EXECUTE calculation
# ──────────────────────────────────────────────────────────────────

# Source workflow-initialization.sh
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh"
else
  echo "ERROR: workflow-initialization.sh not found"
  exit 1
fi

# Call initialization function (uses PHASES_TO_EXECUTE but it's undefined!)
if ! initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"; then
  echo "ERROR: Workflow initialization failed"
  exit 1
fi
```

**Add After Line 936** (after WORKFLOW_SCOPE detection, before workflow-initialization.sh sourcing):
```bash
# ────────────────────────────────────────────────────────────────────
# Re-calculate PHASES_TO_EXECUTE (Bash tool isolation GitHub #334, #2508)
# Exports from Block 1 don't persist. Apply stateless recalculation pattern.
# This mapping MUST stay synchronized with Block 1 lines 607-626.
# ────────────────────────────────────────────────────────────────────

# Map scope to phase execution list (duplicate from Block 1)
case "$WORKFLOW_SCOPE" in
  research-only)
    PHASES_TO_EXECUTE="0,1"
    SKIP_PHASES="2,3,4,5,6"
    ;;
  research-and-plan)
    PHASES_TO_EXECUTE="0,1,2"
    SKIP_PHASES="3,4,5,6"
    ;;
  full-implementation)
    PHASES_TO_EXECUTE="0,1,2,3,4,6"  # CORRECTED: includes phase 6
    SKIP_PHASES=""  # Phase 5 conditional on test failures
    ;;
  debug-only)
    PHASES_TO_EXECUTE="0,1,5"
    SKIP_PHASES="2,3,4,6"
    ;;
esac

export PHASES_TO_EXECUTE SKIP_PHASES

# Defensive validation
if [ -z "${PHASES_TO_EXECUTE:-}" ]; then
  echo "ERROR: PHASES_TO_EXECUTE not set after scope detection"
  echo "  WORKFLOW_SCOPE: $WORKFLOW_SCOPE"
  exit 1
fi

# ────────────────────────────────────────────────────────────────────
# Continue with workflow initialization (now variables are defined)
# ────────────────────────────────────────────────────────────────────
```

**Code Duplication Justification** (per spec 585, 597):
- Duplication: ~25 lines (case statement + exports + validation)
- Performance: <1ms (simple string operations)
- Alternative considered: File-based state (rejected - adds complexity)
- Pattern: Stateless recalculation is the recommended approach for Bash tool isolation

**Testing**:
```bash
# Test Phase 2 completion check (should NOT error)
/coordinate "implement test feature" 2>&1 | grep -A5 "Phase 2 complete"
# Expected: No "unbound variable" errors

# Test should_run_phase function availability
/coordinate "implement test feature" 2>&1 | grep "PHASES_TO_EXECUTE: unbound"
# Expected: No matches

# Verify all 4 workflow types set PHASES_TO_EXECUTE correctly
# (Manual inspection of debug output if needed)
```

**Validation**:
- [ ] PHASES_TO_EXECUTE defined in Block 3 after WORKFLOW_SCOPE detection
- [ ] should_run_phase() calls succeed in Phase 2 completion check (line 1469)
- [ ] No "unbound variable" errors in workflow-detection.sh line 182
- [ ] Defensive validation catches missing PHASES_TO_EXECUTE if case statement fails

---

### Phase 3: Correct full-implementation Phase List in Both Blocks [COMPLETED]

**Objective**: Fix the PHASES_TO_EXECUTE value for full-implementation workflows to include phase 6 (Documentation).

**Complexity**: Trivial (1/10)

**Files Modified**: `.claude/commands/coordinate.md`

**Line Ranges**:
- Block 1: Line 617 (original definition)
- Block 3: New code from Phase 2 (stateless recalculation)

Tasks:
- [x] Update Block 1 full-implementation case (line 617): Change `"0,1,2,3,4"` to `"0,1,2,3,4,6"`
- [x] Update Block 3 full-implementation case (Phase 2 new code): Use corrected value `"0,1,2,3,4,6"`
- [x] Verify comment alignment: "Phase 5 conditional, Phase 6 always" matches code
- [x] Update documentation example (line 427) if needed (already correct there)

**Current Block 1 Code** (line 615-620):
```bash
full-implementation)
  PHASES_TO_EXECUTE="0,1,2,3,4"  # WRONG: missing phase 6
  SKIP_PHASES=""  # Phase 5 conditional on test failures, Phase 6 always
  ;;
```

**Corrected Block 1 Code**:
```bash
full-implementation)
  PHASES_TO_EXECUTE="0,1,2,3,4,6"  # CORRECT: includes phase 6 (Documentation)
  SKIP_PHASES=""  # Phase 5 conditional on test failures, Phase 6 always
  ;;
```

**Block 3 Code** (from Phase 2, ensure it uses corrected value):
```bash
full-implementation)
  PHASES_TO_EXECUTE="0,1,2,3,4,6"  # CORRECTED: includes phase 6
  SKIP_PHASES=""  # Phase 5 conditional on test failures
  ;;
```

**Why Phase 6 is Required**:
- Phase 6 creates implementation summary (workflow-level documentation)
- Summary links research reports, plan, implementation artifacts, and test results
- Required for `/coordinate` to be a complete end-to-end workflow
- Conditional execution: Only runs if `IMPLEMENTATION_OCCURRED="true"` (set in Phase 3)

**Testing**:
```bash
# Test full-implementation workflow phase sequence
/coordinate "implement test feature" 2>&1 | grep "PROGRESS:" | grep -E "Phase [0-6]"
# Expected: See progress markers for phases 0, 1, 2, 3, 4, 6 (not 5 unless tests fail)

# Verify Phase 6 executes
/coordinate "implement test feature" 2>&1 | grep "Phase 6: Documentation"
# Expected: Phase 6 section found in output

# Check for premature exit after Phase 2
/coordinate "implement test feature" 2>&1 | grep "Workflow complete: research-and-plan"
# Expected: No matches (should continue to implementation)
```

**Validation**:
- [ ] Block 1 full-implementation case includes phase 6 in PHASES_TO_EXECUTE
- [ ] Block 3 full-implementation case includes phase 6 in PHASES_TO_EXECUTE
- [ ] should_run_phase 3 returns true (phase 3 in list)
- [ ] should_run_phase 6 returns true (phase 6 in list)
- [ ] Full-implementation workflows execute through Phase 6
- [ ] Summary file created in specs/{topic}/summaries/ directory

---

## Testing Strategy

### Unit Tests (Per Phase)

**Phase 1 Testing**:
```bash
# Test 1.1: Verify library loading
cd /home/benjamin/.config
/coordinate "research test topic" 2>&1 | tee /tmp/coord_test_p1.log

# Check for function availability
grep -q "should_synthesize_overview: command not found" /tmp/coord_test_p1.log
if [ $? -eq 0 ]; then echo "FAIL: Function still missing"; else echo "PASS: Function available"; fi

# Test 1.2: Verify overview synthesis logic executes
grep -q "Skipping overview synthesis" /tmp/coord_test_p1.log || grep -q "Creating research overview" /tmp/coord_test_p1.log
if [ $? -eq 0 ]; then echo "PASS: Synthesis check executed"; else echo "FAIL: Synthesis check skipped"; fi
```

**Phase 2 Testing**:
```bash
# Test 2.1: Verify PHASES_TO_EXECUTE defined
cd /home/benjamin/.config
/coordinate "implement test feature" 2>&1 | tee /tmp/coord_test_p2.log

# Check for unbound variable errors
grep -q "PHASES_TO_EXECUTE: unbound variable" /tmp/coord_test_p2.log
if [ $? -eq 0 ]; then echo "FAIL: Variable still unbound"; else echo "PASS: Variable defined"; fi

# Test 2.2: Verify should_run_phase calls succeed
grep -q "Phase 2.*Planning" /tmp/coord_test_p2.log && grep -q "Phase 3.*Implementation" /tmp/coord_test_p2.log
if [ $? -eq 0 ]; then echo "PASS: Phase checks working"; else echo "FAIL: Phase checks failed"; fi
```

**Phase 3 Testing**:
```bash
# Test 3.1: Verify phase 6 in execution list
cd /home/benjamin/.config
/coordinate "implement test feature" 2>&1 | tee /tmp/coord_test_p3.log

# Check for Phase 6 execution
grep -q "Phase 6: Documentation" /tmp/coord_test_p3.log
if [ $? -eq 0 ]; then echo "PASS: Phase 6 executed"; else echo "FAIL: Phase 6 skipped"; fi

# Test 3.2: Verify no premature exit
grep -q "Workflow complete: research-and-plan" /tmp/coord_test_p3.log
if [ $? -eq 0 ]; then echo "FAIL: Premature exit"; else echo "PASS: Continued to implementation"; fi
```

### Integration Tests (All Phases Combined)

**Test Suite**: Run orchestration test suite
```bash
cd /home/benjamin/.config
bash .claude/tests/test_orchestration_commands.sh --command coordinate

# Expected: 12/12 tests pass (same as spec 597 baseline)
```

**Workflow Type Tests**: Test all 4 workflow types end-to-end
```bash
# Test research-only
/coordinate "research bash patterns in codebase"
# Expected: Phases 0, 1 execute; OVERVIEW.md created (≥2 reports)

# Test research-and-plan
/coordinate "research authentication to plan refactor"
# Expected: Phases 0, 1, 2 execute; plan created; no OVERVIEW.md

# Test full-implementation (CRITICAL)
/coordinate "implement OAuth2 authentication for API"
# Expected: Phases 0, 1, 2, 3, 4, 6 execute; summary created

# Test debug-only
/coordinate "fix token refresh bug in auth.js"
# Expected: Phases 0, 1, 5 execute; debug report created
```

**Error Regression Tests**: Verify all 3 original errors are fixed
```bash
# Regression Test 1: Exit code 127
/coordinate "research test" 2>&1 | grep -c "Exit code 127"
# Expected: 0 (no occurrences)

# Regression Test 2: Unbound variable
/coordinate "implement test" 2>&1 | grep -c "PHASES_TO_EXECUTE: unbound variable"
# Expected: 0 (no occurrences)

# Regression Test 3: Premature exit
/coordinate "implement test feature" 2>&1 | grep -c "Workflow complete: research-and-plan"
# Expected: 0 for full-implementation workflow (should say "full-implementation" if it exits early)
```

### Acceptance Criteria Validation

Run all success criteria checks:
```bash
# 1. overview-synthesis.sh in REQUIRED_LIBS (manual inspection)
grep -A10 "research-only)" /home/benjamin/.config/.claude/commands/coordinate.md | grep "overview-synthesis.sh"
# Expected: Match found

# 2. PHASES_TO_EXECUTE in Block 3 (manual inspection)
grep -A30 "STEP 0.6" /home/benjamin/.config/.claude/commands/coordinate.md | grep "PHASES_TO_EXECUTE="
# Expected: Case statement found with 4 workflow types

# 3. full-implementation includes phase 6 (manual inspection)
grep -A2 "full-implementation)" /home/benjamin/.config/.claude/commands/coordinate.md | grep "0,1,2,3,4,6"
# Expected: 2 matches (Block 1 and Block 3)

# 4-7. Workflow execution tests (see Integration Tests above)
```

## Documentation Requirements

### Update coordinate.md Command Documentation

**Section**: "Bash Tool Limitations → Export Persistence" (lines 2250-2300)

**Add Example**:
```markdown
### Example: Derived Variables Require Recalculation

Not only source variables (WORKFLOW_DESCRIPTION) but also DERIVED variables (PHASES_TO_EXECUTE) must be recalculated:

```bash
# Block 1: Calculate source and derived variables
WORKFLOW_SCOPE="full-implementation"  # Source variable
PHASES_TO_EXECUTE="0,1,2,3,4,6"       # Derived from WORKFLOW_SCOPE

# Block 3: Recalculate BOTH
WORKFLOW_SCOPE="full-implementation"  # Recalculate source  ✓
PHASES_TO_EXECUTE="0,1,2,3,4,6"       # Recalculate derived ✓
```

Forgetting to recalculate derived variables is a common error that causes "unbound variable" failures.
```

### Update CLAUDE.md Standards Reference

**Section**: "Command Architecture Standards"

**Add Note**:
```markdown
### Standard 13 Extension: Derived Variables

When applying the stateless recalculation pattern (Standard 13), ensure ALL derived variables are recalculated, not just source variables:

- Source variable: WORKFLOW_SCOPE (detected from user input)
- Derived variable: PHASES_TO_EXECUTE (mapped from WORKFLOW_SCOPE)
- Pattern: Both must be recalculated in each bash block that uses them

See spec 598 for complete example.
```

### Create Troubleshooting Entry

**File**: `.claude/docs/troubleshooting/coordinate-common-issues.md` (create if doesn't exist)

**Content**:
```markdown
# /coordinate Common Issues

## Issue: "command not found" for overview-synthesis functions

**Symptoms**:
- `bash: line 18: should_synthesize_overview: command not found`
- Occurs in Phase 1 Research overview synthesis section

**Root Cause**: overview-synthesis.sh library not loaded

**Fix**: Ensure overview-synthesis.sh is in REQUIRED_LIBS array for your workflow scope

**Resolution**: Fixed in spec 598

## Issue: "PHASES_TO_EXECUTE: unbound variable"

**Symptoms**:
- Error at workflow-detection.sh line 182
- Occurs when calling should_run_phase() function
- Typically appears at phase transition boundaries

**Root Cause**: PHASES_TO_EXECUTE not recalculated in subsequent bash blocks

**Fix**: Add PHASES_TO_EXECUTE mapping case statement to Block 3

**Resolution**: Fixed in spec 598

## Issue: Full-implementation workflow stops after Phase 2

**Symptoms**:
- Workflow detected as "full-implementation" in Phase 0
- Phases 0, 1, 2 execute successfully
- Workflow exits with "Workflow complete: research-and-plan phase"
- Suggests running /implement manually instead of continuing

**Root Cause**: Combination of missing PHASES_TO_EXECUTE variable and incorrect phase list value

**Fix**:
1. Recalculate PHASES_TO_EXECUTE in Block 3
2. Correct full-implementation value to include phase 6: "0,1,2,3,4,6"

**Resolution**: Fixed in spec 598
```

## Dependencies

**External Dependencies**: None (internal refactor only)

**Library Dependencies**:
- overview-synthesis.sh: Already exists at `/home/benjamin/.config/.claude/lib/overview-synthesis.sh`
- workflow-detection.sh: Already exists and exports should_run_phase()
- All other required libraries: Already included in current REQUIRED_LIBS arrays

**Testing Dependencies**:
- Orchestration test suite: `/home/benjamin/.config/.claude/tests/test_orchestration_commands.sh`
- Test passes: Baseline 12/12 from spec 597

**Spec Dependencies**:
- Spec 597: Establishes stateless recalculation pattern (completed)
- Spec 585: Research validating stateless recalculation approach (completed)

## Rollback Plan

If issues occur after implementation:

```bash
# Rollback command
cd /home/benjamin/.config
git checkout HEAD -- .claude/commands/coordinate.md

# Verify rollback
git diff .claude/commands/coordinate.md
# Expected: No differences from HEAD
```

**Rollback Safety**:
- Single file modified: `.claude/commands/coordinate.md`
- No library changes (overview-synthesis.sh already exists)
- No test changes (using existing test suite)
- Clean git state allows instant rollback

**Validation After Rollback**:
```bash
# Verify baseline still works
bash .claude/tests/test_orchestration_commands.sh --command coordinate
# Expected: Same pass/fail as before implementation
```

## Implementation Checklist

### Pre-Implementation
- [ ] Read spec 597 implementation (stateless recalculation pattern)
- [ ] Review console output (coordinate_output.md) to understand error manifestation
- [ ] Backup coordinate.md (or verify git clean state)
- [ ] Review REQUIRED_LIBS arrays (lines 649-692)
- [ ] Review Block 1 PHASES_TO_EXECUTE mapping (lines 607-626)
- [ ] Review Block 3 variable recalculation (lines 904-936)

### Phase 1 Implementation
- [ ] Add overview-synthesis.sh to research-only REQUIRED_LIBS
- [ ] Add overview-synthesis.sh to research-and-plan REQUIRED_LIBS
- [ ] Add overview-synthesis.sh to full-implementation REQUIRED_LIBS
- [ ] Add overview-synthesis.sh to debug-only REQUIRED_LIBS
- [ ] Update library count comments (3→4, 5→6, 8→9, 6→7)
- [ ] Test Phase 1: Run research workflow, verify no "command not found"

### Phase 2 Implementation
- [ ] Locate insertion point in Block 3 (after line 936, after WORKFLOW_SCOPE detection)
- [ ] Copy PHASES_TO_EXECUTE case statement from Block 1 (lines 607-626)
- [ ] Paste into Block 3 with "stateless recalculation" header comment
- [ ] Add export statements for PHASES_TO_EXECUTE and SKIP_PHASES
- [ ] Add defensive validation (check PHASES_TO_EXECUTE not empty)
- [ ] Update full-implementation case to use corrected value "0,1,2,3,4,6"
- [ ] Test Phase 2: Run implement workflow, verify no "unbound variable"

### Phase 3 Implementation
- [ ] Update Block 1 full-implementation case (line 617): "0,1,2,3,4" → "0,1,2,3,4,6"
- [ ] Verify Block 3 full-implementation case (from Phase 2) uses "0,1,2,3,4,6"
- [ ] Verify comment alignment ("Phase 6 always" matches code)
- [ ] Test Phase 3: Run full-implementation workflow, verify Phase 6 executes

### Post-Implementation
- [ ] Run orchestration test suite (expect 12/12 pass)
- [ ] Test all 4 workflow types (research-only, research-and-plan, full-implementation, debug-only)
- [ ] Verify all 3 error patterns are resolved (exit 127, unbound variable, premature exit)
- [ ] Update documentation (coordinate.md, CLAUDE.md, troubleshooting guide)
- [ ] Commit with detailed message referencing spec 598
- [ ] Update spec 598 status to "COMPLETE"

## Time Breakdown Estimate

- **Phase 1**: 10 minutes (4 array additions + testing)
- **Phase 2**: 15 minutes (case statement duplication + validation + testing)
- **Phase 3**: 5 minutes (2 line changes + testing)
- **Integration Testing**: 5 minutes (test suite + workflow type tests)
- **Documentation**: 5 minutes (3 doc updates)
- **Commit**: 2 minutes (detailed message)

**Total**: 42 minutes (within 30-45 minute estimate)

## Notes

### Why This Plan Differs from Spec 597

Spec 597 fixed WORKFLOW_DESCRIPTION and WORKFLOW_SCOPE persistence but was INCOMPLETE. It missed the derived variable PHASES_TO_EXECUTE that depends on WORKFLOW_SCOPE.

**Spec 597 Scope** (completed):
- Added WORKFLOW_DESCRIPTION="$1" to Block 3
- Added WORKFLOW_SCOPE detection logic to Block 3
- Result: 12/12 tests pass

**Spec 598 Scope** (this plan):
- Extends spec 597 by adding PHASES_TO_EXECUTE to Block 3
- Fixes missing library that spec 597 didn't address
- Corrects phase list value that spec 597 didn't notice
- Result: Full-implementation workflows work end-to-end

### Code Duplication Justification

This plan introduces ~25 lines of duplicated code (PHASES_TO_EXECUTE case statement appears in both Block 1 and Block 3).

**Alternatives Considered**:
1. File-based state: Rejected (adds complexity, spec 585 research)
2. Single large block: Rejected (triggers code transformation >400 lines, spec 582)
3. Refactor to library: Rejected (doesn't solve root cause, spec 594)

**Accepted Approach**:
- Stateless recalculation with code duplication
- Performance: <1ms overhead per variable
- Maintainability: Clear pattern, comment explains why
- Proven: Spec 585, 597 validation

### Testing Coverage Gap

The orchestration test suite (12 tests) does NOT currently test:
- Full Phase 1 execution with overview synthesis
- Phase 2 completion checks with should_run_phase
- Full-implementation workflow end-to-end

**Recommendation**: Add integration tests for full workflow execution in future spec (out of scope for this fix).

### Historical Context

This issue exists because:
1. Spec 596 introduced conditional library loading but omitted overview-synthesis.sh
2. Spec 597 fixed variable persistence but only for source variables, not derived variables
3. Full-implementation phase list was wrong from initial implementation (missing phase 6)

All three issues were independently introduced and independently fixable, but compound to prevent full-implementation workflows from working.

---

**END OF PLAN**
