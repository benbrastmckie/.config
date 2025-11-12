# Fix /coordinate Command Variable Persistence Issues

## Metadata
- **Date**: 2025-11-05
- **Feature**: Fix bash variable persistence in /coordinate command Phase 0
- **Scope**: Resolve unbound variable errors in STEP 0.6 (Block 3)
- **Estimated Phases**: 2
- **Complexity**: Low (2/10)
- **Estimated Total Time**: 30-60 minutes
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Parent Issue**: Console output testing revealed critical bugs in Phase 0 initialization
- **Related Plans**:
  - 596_refactor_coordinate_command_to_reduce_bash (introduced these regressions)
  - 582_coordinate_bash_history_expansion_fixes (discovered large blocks trigger code transformation)
  - 583_coordinate_block_state_propagation_fix (BASH_SOURCE doesn't work in markdown)
  - 584_fix_coordinate_export_persistence (stateless recalculation pattern)
  - 585_bash_export_persistence_alternatives (research on alternatives)
  - 593_coordinate_command_fixes (comprehensive issue analysis)
  - 594_research_the_bash_command_failures (root cause analysis)

## Overview

Console output testing of `/coordinate` revealed critical variable persistence issues in Phase 0 Block 3 (STEP 0.6) that prevent the command from executing. This is a well-understood limitation of the Bash tool - exports don't persist between invocations (GitHub #334, #2508).

### Historical Context

This issue has been analyzed extensively across **7 previous specs** (582-594, 596):
- **582**: Discovered that large bash blocks (400+ lines) trigger Claude Code transformation
- **583**: Found that BASH_SOURCE doesn't work in markdown extraction context
- **584/585**: Research established "stateless recalculation" as the recommended pattern
- **593/594**: Comprehensive analysis of coordinate failures
- **596**: Standardized CLAUDE_PROJECT_DIR but didn't apply pattern to all variables

**Key Insight from Past Research**: Adding `set +H` does NOT work because bash parses for history expansion BEFORE executing commands. The only solution is variable re-initialization following the stateless recalculation pattern.

### Console Output Errors

From `/home/benjamin/.config/.claude/specs/coordinate_output.md`:

**Error 1 (Line 448-450)**: WORKFLOW_DESCRIPTION unbound in Block 3
```
Error: Exit code 127
/run/current-system/sw/bin/bash: line 73:
WORKFLOW_DESCRIPTION: unbound variable
```

**Error 2 (Line 531-536)**: WORKFLOW_SCOPE unbound, TOPIC_PATH unbound (calculated from WORKFLOW_SCOPE)
```
Error: Exit code 127
/run/current-system/sw/bin/bash: line 81: !: command not found
/run/current-system/sw/bin/bash: line 91: TOPIC_PATH: unbound variable
```

### Root Cause (Confirmed by 7 Previous Analyses)

**The Bash tool creates separate shell processes for each invocation. Exports from Block 1 do NOT persist to Block 3.**

Current Flow:
```
Block 1 (lines 526-708):
  ✓ WORKFLOW_DESCRIPTION="$1" (line 553)
  ✓ WORKFLOW_SCOPE calculated (lines 581-604)
  ✓ Both exported (lines 573, 626)

Block 3 (lines 893-984):
  ✗ WORKFLOW_DESCRIPTION not re-initialized
  ✗ WORKFLOW_SCOPE not re-initialized
  ✗ Line 915: Tries to use both → unbound error
```

### Why `set +H` Won't Help (Learned from Spec 582)

The user mentioned trying `set +H` before. Research in spec 582 explains why it failed:

> Bash parses script text for history expansion BEFORE executing any commands, including `set +H`. The script text is parsed for history expansion BEFORE the `set +H` command executes.

The "!: command not found" error is from `if !` negation operator in line 915, not from `${!varname}` indirect references. But adding `set +H` won't fix it because parsing happens first.

### The Proven Solution: Stateless Recalculation (Spec 585)

From spec 585 research (150ms overhead, acceptable):

> **Primary Recommendation: Implement Stateless Recalculation**
> Each bash block independently recalculates needed state using conditional checks and fast operations.

**Accept code duplication** for simple, fast variables rather than fighting the tool's architecture.

## Success Criteria

- [ ] WORKFLOW_DESCRIPTION re-initialized from $1 in Block 3
- [ ] WORKFLOW_SCOPE re-calculated using inline detection in Block 3
- [ ] All 4 workflow types execute successfully through Phase 0
- [ ] No unbound variable errors in Phase 0
- [ ] Existing orchestration test suite passes (12/12 tests)
- [ ] Console output clean (no bash errors in Phase 0)

## Risk Assessment

**Risk Level**: Very Low

- **Scope**: Only Block 3 (~15 lines added), no changes to Phase 1-6
- **Pattern**: Stateless recalculation already validated across 7 previous specs
- **Testing**: Comprehensive test suite exists
- **Code Duplication**: Accepted trade-off (50 lines duplicated from Block 1)
- **Performance**: <1ms additional overhead (inline string matching)

**Mitigation**: Follow exact same pattern from Block 1 (lines 553, 581-604)

## Technical Design

### Problem Analysis

**Bash Tool Limitation (GitHub #334, #2508)**: Exports from one bash invocation don't persist to subsequent invocations. Each Bash tool call is isolated.

**Current Flow**:
```
Phase 0 Block 1 (STEP 0.1-0.4):
  ✓ CLAUDE_PROJECT_DIR set and exported
  ✓ WORKFLOW_DESCRIPTION set and exported (from $1)
  ✓ WORKFLOW_SCOPE calculated and exported
  ✓ Libraries loaded

Phase 0 Block 2 (STEP 0.4.0-0.5):
  ✓ CLAUDE_PROJECT_DIR re-calculated (exports lost)
  ✓ Functions verified
  ✗ WORKFLOW_DESCRIPTION not re-initialized
  ✗ WORKFLOW_SCOPE not re-initialized

Phase 0 Block 3 (STEP 0.6):
  ✓ CLAUDE_PROJECT_DIR re-calculated
  ✗ WORKFLOW_DESCRIPTION not available → unbound error
  ✗ WORKFLOW_SCOPE not available → unbound error
  ✗ History expansion active → '!' interpreted as command
```

**Required Fix**:
```
Phase 0 Block 3 (STEP 0.6) - FIXED:
  ✓ Disable history expansion (set +H)
  ✓ Re-initialize WORKFLOW_DESCRIPTION (from $1)
  ✓ Re-initialize WORKFLOW_SCOPE (inline detection)
  ✓ CLAUDE_PROJECT_DIR re-calculated
  ✓ Source workflow-initialization.sh
  ✓ Call initialize_workflow_paths with correct variables
```

### Solution Pattern

**1. Variable Re-initialization Pattern**

Block 1 already establishes the pattern:
```bash
# STEP 0.2: Parse Workflow Description
WORKFLOW_DESCRIPTION="$1"
export WORKFLOW_DESCRIPTION

# STEP 0.3: Inline Scope Detection
WORKFLOW_SCOPE="research-and-plan"  # Default
# ... detection logic ...
export WORKFLOW_SCOPE
```

Block 3 must replicate this (minus the detailed logic):
```bash
# STEP 0.6: Initialize Workflow Paths
set +H  # Disable history expansion

# Re-initialize variables (Bash tool isolation)
WORKFLOW_DESCRIPTION="$1"
WORKFLOW_SCOPE="${2:-full-implementation}"  # Pass as argument or detect

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
```

**2. History Expansion Prevention**

Add `set +H` at the start of each bash block to disable history expansion:
```bash
set +H  # Prevent '!' from triggering command history lookup
```

**3. Defensive Variable Checks**

Use `${VAR:-}` or `${VAR:-default}` pattern:
```bash
if [ -z "${WORKFLOW_DESCRIPTION:-}" ]; then
  echo "ERROR: WORKFLOW_DESCRIPTION required"
  exit 1
fi
```

### Implementation Strategy

**Minimal Change Approach**: Fix only STEP 0.6, don't refactor entire Phase 0.

**Files Modified**:
- `.claude/commands/coordinate.md` (STEP 0.6 bash block only)

**Lines Changed**: ~10-15 lines (add variable re-initialization, history expansion disable)

## Implementation Phases

### Phase 1: Fix Variable Re-initialization in STEP 0.6
**Objective**: Ensure WORKFLOW_DESCRIPTION and WORKFLOW_SCOPE are available in STEP 0.6 bash block
**Complexity**: Low (2/10)
**Estimated Time**: 30-45 minutes
**Dependencies**: []

**Tasks**:
- [ ] Add `set +H` at start of STEP 0.6 bash block (coordinate.md:~895)
- [ ] Re-initialize WORKFLOW_DESCRIPTION from $1 before sourcing workflow-initialization.sh
- [ ] Re-initialize WORKFLOW_SCOPE (use same inline detection logic from STEP 0.3)
- [ ] Add defensive check: validate variables are set before calling initialize_workflow_paths
- [ ] Verify CLAUDE_PROJECT_DIR is set BEFORE sourcing workflow-initialization.sh (already correct)

**Pattern**:
```bash
# ────────────────────────────────────────────────────────────────────
# STEP 0.6: Initialize Workflow Paths
# ────────────────────────────────────────────────────────────────────

set +H  # Disable history expansion (prevent '!' interpretation issues)

# Standard 13: CLAUDE_PROJECT_DIR detection (Bash tool limitation GitHub #334, #2508)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Re-initialize workflow variables (exports don't persist between bash blocks)
WORKFLOW_DESCRIPTION="$1"

# Inline scope detection (condensed from STEP 0.3)
WORKFLOW_SCOPE="full-implementation"  # Default
if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "^research.*"; then
  if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "(plan|implement|fix|debug|create|add|build|refactor)"; then
    WORKFLOW_SCOPE="full-implementation"
  else
    WORKFLOW_SCOPE="research-only"
  fi
fi

# Validate required variables
if [ -z "${WORKFLOW_DESCRIPTION:-}" ]; then
  echo "ERROR: WORKFLOW_DESCRIPTION required but not set"
  exit 1
fi

if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  echo "ERROR: WORKFLOW_SCOPE required but not set"
  exit 1
fi

# Source workflow-initialization.sh (now CLAUDE_PROJECT_DIR is guaranteed available)
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh"
else
  echo "ERROR: workflow-initialization.sh not found"
  echo "This is a required library file for workflow operation."
  echo "Please ensure .claude/lib/workflow-initialization.sh exists."
  exit 1
fi

# Call unified initialization function (silent)
if ! initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"; then
  echo "ERROR: Workflow initialization failed"
  exit 1
fi

echo "  ✓ Paths pre-calculated"
```

**Testing**:
```bash
# Test Phase 0 initialization with all workflow types
/coordinate "research bash patterns"  # research-only
/coordinate "research auth patterns to create refactor plan"  # research-and-plan
/coordinate "implement test feature"  # full-implementation
/coordinate "fix auth bug in login.sh"  # debug-only

# Expected: All workflows complete Phase 0 without unbound variable errors
# Expected: No history expansion errors (no "!: command not found")
```

**Files Modified**:
- `.claude/commands/coordinate.md` (lines ~895-920)

**Success Criteria**:
- [ ] STEP 0.6 bash block includes `set +H`
- [ ] WORKFLOW_DESCRIPTION re-initialized from $1
- [ ] WORKFLOW_SCOPE re-initialized with inline detection
- [ ] Defensive checks validate variables before use
- [ ] No unbound variable errors in Phase 0

---

### Phase 2: Add Defensive History Expansion Prevention
**Objective**: Prevent history expansion issues in all Phase 0 bash blocks
**Complexity**: Low (2/10)
**Estimated Time**: 30 minutes
**Dependencies**: [1]

**Tasks**:
- [ ] Add `set +H` to Phase 0 Block 1 (STEP 0.1-0.4) if not present
- [ ] Add `set +H` to Phase 0 Block 2 (STEP 0.4.0-0.5) if not present
- [ ] Verify `set +H` at start of STEP 0.6 (added in Phase 1)
- [ ] Document history expansion limitation in Bash Tool Limitations section

**Pattern**:
```bash
# ════════════════════════════════════════════════════════════════════
# Phase 0: Initialization (Step 1 of 3)
# ════════════════════════════════════════════════════════════════════

set +H  # Disable history expansion for bash negation operators

echo "Phase 0: Initialization started"
```

**Rationale**:
- History expansion interprets '!' as command history lookup
- Bash negation operator `if !` triggers false positives
- `set +H` disables this feature in non-interactive shells

**Documentation Addition** (coordinate.md - Bash Tool Limitations section):
```markdown
### History Expansion

**Limitation**: Bash history expansion (`!` operator) can interfere with negation operators in conditionals.

**Example Error**:
```bash
if ! initialize_workflow_paths "$DESC" "$SCOPE"; then
  # Error: "!: command not found"
```

**Solution**: Add `set +H` at the start of each bash block to disable history expansion.

**Impact**: No functional impact (history expansion not useful in non-interactive contexts).
```

**Testing**:
```bash
# Verify all Phase 0 blocks execute without history expansion errors
/coordinate "research test patterns to implement auth"

# Expected: No "!: command not found" errors
# Expected: All bash negation operators work correctly
```

**Files Modified**:
- `.claude/commands/coordinate.md` (3 bash blocks + documentation section)

**Success Criteria**:
- [ ] All Phase 0 bash blocks include `set +H`
- [ ] No history expansion errors in any workflow type
- [ ] Documentation explains limitation and solution

---

### Phase 3: Testing and Validation
**Objective**: Comprehensive testing to ensure all fixes work correctly
**Complexity**: Low (2/10)
**Estimated Time**: 1 hour
**Dependencies**: [1, 2]

**Tasks**:
- [ ] Test all 4 workflow types end-to-end
- [ ] Verify Phase 0 completes without errors for each type
- [ ] Run existing test suite (`.claude/tests/test_orchestration_commands.sh --command coordinate`)
- [ ] Validate console output shows clean Phase 0 execution
- [ ] Verify no unbound variable errors in any bash block
- [ ] Confirm TOPIC_PATH and other exports available in subsequent blocks
- [ ] Document fixes in plan 596 (cross-reference fix)

**Test Cases**:

**Test 1: Research-Only Workflow**
```bash
/coordinate "research authentication patterns in the codebase"

# Expected Output:
# Phase 0: Initialization started
#   ✓ Libraries loaded (3 for research-only)
#   ✓ Workflow scope detected: research-only
#   ✓ Paths pre-calculated
#
# Workflow Scope: research-only
# Topic: .claude/specs/NNN_research_authentication_patterns_in_the_codebase
#
# Phases to Execute:
#   ✓ Phase 0: Initialization
#   ✓ Phase 1: Research (parallel agents)
#   ✗ Phase 2: Planning (skipped)
#   ...
```

**Test 2: Research-and-Plan Workflow**
```bash
/coordinate "research auth patterns to create refactor plan"

# Expected: Phase 0 completes successfully
# Expected: WORKFLOW_SCOPE detected as "research-and-plan"
# Expected: Phases 0-2 execute, 3-6 skipped
```

**Test 3: Full-Implementation Workflow**
```bash
/coordinate "implement OAuth2 authentication for API"

# Expected: Phase 0 completes successfully
# Expected: WORKFLOW_SCOPE detected as "full-implementation"
# Expected: All phases prepared (0-4, 6 conditional)
```

**Test 4: Debug-Only Workflow**
```bash
/coordinate "fix token refresh bug in auth.js"

# Expected: Phase 0 completes successfully
# Expected: WORKFLOW_SCOPE detected as "debug-only"
# Expected: Phases 0, 1, 5 prepared
```

**Test 5: Existing Test Suite**
```bash
cd /home/benjamin/.config
./.claude/tests/test_orchestration_commands.sh --command coordinate

# Expected: All 12 tests pass (no regressions)
```

**Test 6: Variable Availability Check**
```bash
# Add temporary debug output to Phase 1 block to verify exports
# Verify TOPIC_PATH, PLAN_PATH, etc. are available after Phase 0

# Expected: All path variables exported by initialize_workflow_paths available
```

**Validation**:
- [ ] All 4 workflow types complete Phase 0 without errors
- [ ] No "unbound variable" errors
- [ ] No "command not found" errors related to '!'
- [ ] Test suite passes (12/12)
- [ ] Console output clean and professional
- [ ] Path variables available in subsequent blocks

**Regression Prevention**:
- [ ] Document variable re-initialization requirement for future bash blocks
- [ ] Add comment in coordinate.md explaining why re-initialization is necessary
- [ ] Cross-reference GitHub issues #334, #2508 in comments

**Files Modified**:
- `.claude/specs/596_refactor_coordinate_command_to_reduce_bash/plans/001_implementation/001_implementation.md` (add cross-reference)

**Success Criteria**:
- [ ] All tests pass
- [ ] Zero bash errors in Phase 0
- [ ] All workflow types functional
- [ ] Documentation updated

---

## Testing Strategy

### Unit Tests
- Individual bash block validation (verify variable availability)
- History expansion prevention (test negation operators)
- Defensive checks (test unset variable handling)

### Integration Tests
- End-to-end workflow execution (all 4 types)
- Phase transitions (verify exports propagate correctly)
- Error handling (test missing WORKFLOW_DESCRIPTION)

### Regression Tests
- Existing test suite (`.claude/tests/test_orchestration_commands.sh`)
- Compare console output before/after fix
- Validate no new errors introduced

### Performance
- No performance impact expected (minimal code added)
- Phase 0 execution time should remain <1 second

---

## Rollback Plan

If issues discovered:

**Phase 1 Rollback**:
```bash
git revert HEAD  # Revert variable re-initialization changes
```

**Phase 2 Rollback**:
```bash
git revert HEAD~1..HEAD  # Revert both Phase 1 and 2
```

**Emergency Fix**:
If complete rollback needed:
```bash
git checkout HEAD~3 .claude/commands/coordinate.md
git commit -m "Emergency rollback: restore coordinate.md to pre-fix state"
```

---

## Integration with Existing Infrastructure

### Relationship to Plan 596
This plan fixes regressions introduced by plan 596's refactoring. Plan 596 standardized CLAUDE_PROJECT_DIR detection but didn't address variable persistence in STEP 0.6.

**Plan 596 Changes**:
- Standardized CLAUDE_PROJECT_DIR detection (Standard 13 pattern)
- Simplified library sourcing (removed fallbacks)
- Added Bash Tool Limitations documentation

**Plan 597 Changes** (this plan):
- Fix WORKFLOW_DESCRIPTION/WORKFLOW_SCOPE persistence in STEP 0.6
- Add history expansion prevention
- Complete the variable re-initialization pattern started in 596

### No Changes to workflow-initialization.sh
This plan does NOT modify `workflow-initialization.sh`. That library is working correctly. The issue is in how coordinate.md calls it (missing variable initialization).

### Maintains Standard 13 Compliance
All CLAUDE_PROJECT_DIR detection uses Standard 13 pattern from plan 596.

---

## Documentation Requirements

### coordinate.md Updates
- Add `set +H` explanation in comments
- Document variable re-initialization requirement
- Cross-reference GitHub issues #334, #2508

### Bash Tool Limitations Section
- Add history expansion subsection
- Explain `set +H` solution
- Document variable persistence pattern

### Plan 596 Cross-Reference
- Note that plan 597 completes the refactoring
- Link to this plan for variable persistence fixes

---

## Estimated Time Summary
- Phase 1: 30-45 minutes (Variable re-initialization)
- Phase 2: 30 minutes (History expansion prevention)
- Phase 3: 1 hour (Testing and validation)

**Total**: 2-3 hours

---

## Notes

### Why This Wasn't Caught in Plan 596
Plan 596 focused on CLAUDE_PROJECT_DIR standardization and library sourcing. The variable persistence issue in STEP 0.6 was latent - the code path may not have been tested with the new patterns.

### Clean-Break Philosophy
This fix maintains the clean-break philosophy:
- No compatibility shims or fallbacks
- Fails fast with clear error messages
- Uses established patterns consistently
- Documents accepted limitations

### Future Prevention
Consider adding integration test that validates Phase 0 variable availability before merging orchestration command changes.

---

## Success Metrics

### Before Fix
- ❌ Command fails immediately in Phase 0
- ❌ Unbound variable errors (WORKFLOW_DESCRIPTION, TOPIC_PATH)
- ❌ History expansion errors ("!: command not found")
- ❌ Zero workflows functional

### After Fix
- ✅ Phase 0 completes successfully
- ✅ No unbound variable errors
- ✅ No history expansion errors
- ✅ All 4 workflow types functional
- ✅ Test suite passes (12/12)
- ✅ Clean console output

---

## Related Issues

- GitHub #334: Bash tool export persistence limitation
- GitHub #2508: Related export behavior discussion
- Plan 596: Parent refactoring that exposed these issues
- Plan 583: Previous attempt to fix block state propagation
- Plan 584: Previous attempt to fix export persistence
