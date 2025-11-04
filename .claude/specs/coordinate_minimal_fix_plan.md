# Implementation Plan: Minimal Fix for /coordinate Command Issues

## Metadata

- **Created**: 2025-11-04
- **Type**: Bug Fix (Minimal/Revert-Based Approach)
- **Complexity**: 3/10 (Simple - based on known working baseline)
- **Estimated Time**: 30-60 minutes
- **Dependencies**: None
- **Testing Required**: Yes (validation against b507502ad1e0 baseline)

## Executive Summary

This plan takes a minimal, revert-based approach to fixing the `/coordinate` command issues. Since commit b507502ad1e0 worked better, we'll analyze what changed since then and apply only the essential fixes needed to restore functionality.

**Key Insight**: Recent "fix" commits (f761f1de, f198f2c5) changed STEP 0 library sourcing but didn't address the fundamental issue: each bash block runs in an isolated subprocess.

## Analysis of Changes Since b507502ad1e0

### What Changed

**Commit f761f1de** (2025-11-04): "Apply library sourcing fix to /coordinate"
- Replaced `${BASH_SOURCE[0]}` with `CLAUDE_PROJECT_DIR` detection
- Added git-based project directory detection
- Enhanced error diagnostics

**The Problem**: This only fixed STEP 0 library sourcing, but STEP 2 and later phases still can't access the sourced functions because they run in separate bash subprocesses.

### Root Cause (Unchanged Since b507502ad1e0)

Both the old and new versions have the same architectural issue:
- STEP 0 sources libraries in one bash block
- STEP 2+ run in separate bash blocks (isolated subprocesses)
- Functions sourced in STEP 0 are NOT available in STEP 2+

**This issue existed even at b507502ad1e0**, but the user reports it "seemed to work better" then.

## Hypothesis

The user may have experienced better behavior at b507502ad1e0 because:

1. **Different execution path**: Perhaps the command failed faster/cleaner at that point
2. **Manual intervention**: The old `${BASH_SOURCE[0]}` approach might have allowed manual fixes
3. **Workflow detection**: The workflow detection bug (Pattern 2 before Pattern 3) may have caused different phase execution

## Minimal Fix Strategy

Instead of the complex 4-phase plan, we'll take a **surgical approach**:

### Option A: Revert + Minimal Fixes (Recommended)

1. **Revert to b507502ad1e0 baseline** for coordinate.md
2. **Add library sourcing to STEP 2 only** (the critical failure point)
3. **Test workflow detection** with user's prompt
4. **Iterate** if additional blocks need sourcing

**Rationale**: Start from known working state, add minimal changes, validate incrementally

### Option B: Targeted Fixes to Current Version

1. **Keep current CLAUDE_PROJECT_DIR approach** in STEP 0
2. **Add library sourcing to STEP 2** (and any other critical blocks)
3. **Fix workflow detection priority** (swap Pattern 2 and Pattern 3)
4. **Test** end-to-end

**Rationale**: If the CLAUDE_PROJECT_DIR change is actually better, keep it but fix the subprocess isolation issue

## Recommended Plan: Option A + Validation

### Phase 1: Baseline Comparison (10 minutes)

**Objective**: Understand exactly what worked at b507502ad1e0

**Tasks**:
- [ ] Extract coordinate.md at b507502ad1e0
- [ ] Compare STEP 0, STEP 2, and Phase 1 implementations
- [ ] Identify any other differences besides library sourcing
- [ ] Document findings

**Validation**:
- [ ] Clear understanding of what changed
- [ ] Decision point: Revert or patch forward?

### Phase 2: Minimal Fix Implementation (15-20 minutes)

**Objective**: Apply smallest possible fix to restore functionality

**Approach A (Revert-Based)**:
```bash
# 1. Revert coordinate.md to b507502ad1e0 baseline
git show b507502ad1e0:.claude/commands/coordinate.md > /tmp/coordinate-baseline.md
cp /tmp/coordinate-baseline.md .claude/commands/coordinate.md

# 2. Add library sourcing to STEP 2 only
# (Edit coordinate.md, add sourcing before detect_workflow_scope call)
```

**Approach B (Patch-Forward)**:
```bash
# 1. Keep current version
# 2. Add library sourcing to STEP 2
# (Edit coordinate.md, add sourcing before detect_workflow_scope call)
```

**STEP 2 Fix** (Add to both approaches):
```bash
STEP 2: Detect workflow scope

```bash
# Source libraries for workflow detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-sourcing.sh"
source_required_libraries "workflow-detection.sh" || exit 1

WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
```

**Validation**:
- [ ] STEP 2 can successfully call detect_workflow_scope
- [ ] No "command not found" errors
- [ ] Workflow scope detection works

### Phase 3: Integration Testing (10-15 minutes)

**Objective**: Verify the minimal fix actually works

**Test Cases**:
1. **User's exact prompt**: "research...then create and implement a plan..."
   - Expected: Should detect workflow scope without errors
   - Expected scope: Either research-and-plan or full-implementation (depends on Pattern order)

2. **Simple research prompt**: "research API patterns"
   - Expected: research-only workflow

3. **Implementation prompt**: "implement OAuth2"
   - Expected: full-implementation workflow

**Validation**:
- [ ] All 3 test cases execute without subprocess errors
- [ ] Workflow scope detection completes successfully
- [ ] Progress markers emit correctly

### Phase 4: Iterate if Needed (10-15 minutes)

**Objective**: Add library sourcing to additional blocks if failures occur

**Contingency**: If Phase 1 agent invocations fail:
- Add library sourcing to Phase 1 execution check bash block
- Follow same pattern as STEP 2 fix

**Contingency**: If Phase 2 planning fails:
- Add library sourcing to Phase 2 execution check bash block

**Pattern**: Only add sourcing where actually needed (fail-fast, iterate)

## Workflow Detection Fix (If Needed)

**Issue**: Pattern 2 (research-and-plan) checked before Pattern 3 (full-implementation)

**Fix**: If testing shows workflow detection is wrong:
```bash
# Edit .claude/lib/workflow-detection.sh
# Move Pattern 3 (lines 66-72) to before Pattern 2 (lines 58-64)
```

**Validation**: Test user's prompt, should detect "full-implementation" if it contains "implement"

## Success Criteria

### Functional Requirements
- [ ] `/coordinate` executes without "command not found" errors
- [ ] Workflow scope detection works for all 4 workflow types
- [ ] User's exact prompt classified correctly
- [ ] Research agents invoked successfully

### Minimal Scope
- [ ] Only critical blocks have library sourcing (not all 38)
- [ ] No unnecessary changes to working code
- [ ] Clear understanding of what was fixed and why

### User Experience
- [ ] Command works as well as or better than b507502ad1e0
- [ ] Error messages are clear if failures occur
- [ ] Performance is acceptable

## Comparison with Existing Plan

### Existing Plan (coordinate_fixes_implementation_plan.md)
- **Phases**: 4 (2-3 hours)
- **Scope**: Comprehensive fix + test suite + documentation
- **Approach**: Add library sourcing to ~12 blocks + reorder patterns

### This Plan (Minimal Fix)
- **Phases**: 4 (30-60 minutes)
- **Scope**: Minimal changes to restore functionality
- **Approach**: Start from working baseline, add only what's needed

**When to Use This Plan**: When you want quick restoration of functionality and iterative refinement

**When to Use Existing Plan**: When you want comprehensive testing and long-term reliability

## Decision Points

### Decision 1: Revert or Patch Forward?

**Revert (Approach A)**:
- Pros: Known working baseline, minimal risk
- Cons: Loses CLAUDE_PROJECT_DIR improvements from f761f1de

**Patch Forward (Approach B)**:
- Pros: Keeps recent improvements, incremental fix
- Cons: Unknown if other changes broke things

**Recommendation**: Start with Approach B (patch forward), fall back to Approach A if issues persist

### Decision 2: Fix Workflow Detection Now or Later?

**Fix Now**:
- Pros: Comprehensive solution, user's prompt works correctly
- Cons: Additional testing needed

**Fix Later**:
- Pros: Minimal scope, focus on library sourcing only
- Cons: User's prompt may still detect wrong workflow type

**Recommendation**: Test first, fix workflow detection only if it's actually causing problems

### Decision 3: How Many Blocks Need Library Sourcing?

**Minimal (Recommended)**:
- Only STEP 2 initially
- Add to other blocks if they fail (iterative)

**Comprehensive**:
- Add to all 12 blocks upfront (like existing plan)

**Recommendation**: Minimal approach - fail fast, iterate, learn what's actually needed

## Testing Strategy

### Unit Test: STEP 2 Library Sourcing
```bash
# Test that STEP 2 can call detect_workflow_scope
echo 'research and implement OAuth2' | /coordinate
# Should not see "command not found" error
```

### Integration Test: Full Workflow
```bash
# Test user's exact prompt
/coordinate "research my current configuration and then conduct research online for how to provide a elegant configuration given the plugins I am using. then create and implement a plan to fix this problem."

# Expected:
# - No subprocess errors
# - Workflow scope detected (either research-and-plan or full-implementation)
# - Research phase attempts to execute
```

### Regression Test: Baseline Behavior
```bash
# Compare behavior with b507502ad1e0
# Document any differences in:
# - Error messages
# - Execution flow
# - Artifact creation
```

## Rollback Plan

### If Minimal Fix Fails
1. Revert coordinate.md to b507502ad1e0: `git show b507502ad1e0:.claude/commands/coordinate.md > .claude/commands/coordinate.md`
2. Document what didn't work
3. Consider using existing comprehensive plan instead

**Rollback Time**: <2 minutes

### If Workflow Detection Fails
1. Revert workflow-detection.sh changes
2. Use manual workflow scope specification (if command supports it)

**Rollback Time**: <1 minute

## Post-Implementation

### If Successful
- [ ] Document what blocks actually needed library sourcing
- [ ] Consider whether comprehensive plan is still needed
- [ ] Monitor for any additional subprocess errors

### If Unsuccessful
- [ ] Fall back to existing comprehensive plan
- [ ] Document why minimal approach didn't work
- [ ] Consider architectural changes (single bash block, wrapper script, etc.)

## Risk Assessment

### Risk 1: Minimal Fix Insufficient
**Likelihood**: Medium | **Impact**: Low
**Mitigation**: Existing comprehensive plan is ready as fallback

### Risk 2: Breaking Other Functionality
**Likelihood**: Low | **Impact**: Medium
**Mitigation**: Fast rollback available, changes are localized

### Risk 3: Workflow Detection Still Broken
**Likelihood**: Medium | **Impact**: Low
**Mitigation**: Can fix workflow detection separately in Phase 4

## Files to Modify

### Approach A (Revert-Based)
- `.claude/commands/coordinate.md` (revert to b507502ad1e0, then patch STEP 2)

### Approach B (Patch-Forward)
- `.claude/commands/coordinate.md` (add library sourcing to STEP 2)

### If Workflow Detection Needs Fixing
- `.claude/lib/workflow-detection.sh` (reorder Pattern 2 and 3)

## Estimated Timeline

- **Phase 1** (Baseline Comparison): 10 minutes
- **Phase 2** (Minimal Fix): 15-20 minutes
- **Phase 3** (Integration Testing): 10-15 minutes
- **Phase 4** (Iteration): 10-15 minutes (if needed)

**Total**: 30-60 minutes

**Comparison**: Existing plan estimates 2-3 hours

## Conclusion

This minimal fix plan offers a lightweight, iterative approach to restoring `/coordinate` functionality based on the known working baseline at b507502ad1e0. By adding library sourcing only where needed and testing incrementally, we can achieve quick restoration with minimal risk.

If the minimal approach proves insufficient, the existing comprehensive plan (coordinate_fixes_implementation_plan.md) provides a robust fallback with full test coverage and documentation.

**Recommended Action**: Proceed with Phase 1 to understand baseline differences, then decide between Approach A (revert) or Approach B (patch forward) based on findings.

---

**Next Steps**: Review this plan and choose implementation approach, or proceed directly with Phase 1 baseline comparison.
