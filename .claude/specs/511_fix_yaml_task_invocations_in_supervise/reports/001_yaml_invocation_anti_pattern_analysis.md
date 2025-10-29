# YAML-Style Task Invocation Anti-Pattern Analysis

## Metadata
- **Date**: 2025-10-28
- **Scope**: Fix 3 YAML-style Task invocations in supervise.md Phase 5 (debug section) to achieve 12/12 test pass rate
- **Primary File**: `.claude/commands/supervise.md`
- **Lines Affected**: 1440, 1599, 1696
- **Test Failure**: "Agent invocation pattern: supervise.md - Anti-patterns detected"
- **Target**: 12/12 tests passing (currently 11/12)

## Executive Summary

The /supervise command contains 3 YAML-style Task invocations in Phase 5 (Debug section) that violate Standard 11 (Imperative Agent Invocation Pattern). These invocations use the `Task { ... }` syntax without preceding imperative instructions, causing the validation script to flag them as documentation-only blocks rather than executable instructions. While the rest of /supervise uses the correct imperative pattern (`**EXECUTE NOW**: USE the Task tool...`), these 3 invocations in the debug iteration loop were likely missed during the Phase 2 refactoring.

**Impact**: 1/12 test failures, preventing 100% compliance with Command Architecture Standards.
**Complexity**: Low - straightforward pattern replacement
**Risk**: Very low - fixing aligns with proven patterns used throughout rest of command
**Estimated Fix Time**: 30-45 minutes

## Problem Statement

### Current Test Results
```
Test Suite 1: Agent Invocation Patterns
----------------------------------------
✓ Agent invocation pattern: coordinate.md
✓ Agent invocation pattern: research.md
✗ Agent invocation pattern: supervise.md
  Error: Anti-patterns detected (run validation script for details)

Test Summary: 11/12 passing (91.7%)
```

### Validation Script Output
```bash
$ .claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md

[Check 1] Detecting YAML-style Task blocks (excluding documentation)...
  ❌ VIOLATION: YAML-style Task blocks found (not in documentation)
     Task invocations should use imperative bullet-point pattern
     Example: **EXECUTE NOW**: USE the Task tool with these parameters:

1440:  Task {
1599:  Task {
1696:  Task {
```

## Root Cause Analysis

### Why YAML Pattern is Anti-Pattern

From [Command Architecture Standards - Standard 11](../../docs/reference/command_architecture_standards.md#standard-11):

**Problem**: Documentation-only YAML blocks create a 0% agent delegation rate because they appear as code examples rather than executable instructions.

**Evidence from Historical Fixes**:
- **Spec 438** (2025-10-24): /supervise fix - 7 YAML blocks caused 0% delegation rate
- **Spec 495** (2025-10-27): /coordinate and /research fixes - 12 YAML blocks caused 0% delegation, all output went to TODO files instead of proper locations

### Pattern Comparison

**❌ WRONG - YAML-Style (Documentation-Only)**:
```markdown
  Task {
    subagent_type: "general-purpose"
    description: "Analyze test failures - iteration $iteration"
    prompt: "..."
  }
```

**Why it fails**:
1. Lacks imperative instruction signaling immediate execution
2. Looks like syntax example or template
3. Claude may interpret as documentation and skip execution
4. No explicit "EXECUTE NOW" or "USE the Task tool" directive

**✅ CORRECT - Imperative Bullet-Point Pattern**:
```markdown
**EXECUTE NOW**: USE the Task tool with these parameters:

- subagent_type: "general-purpose"
- description: "Analyze test failures - iteration $iteration"
- prompt: |
    ...
```

**Why it works**:
1. **EXECUTE NOW** clearly signals immediate action
2. **USE the Tool** explicitly names the tool to invoke
3. Bullet-point format indicates parameters to pass
4. No ambiguity about whether this is documentation vs execution

### Locations of Violations

All 3 violations are in Phase 5 (Debug section) during the debug iteration loop:

**Violation 1: Line 1440 - Debug Analysis Invocation**
```markdown
  # Invoke debug-analyst agent
  Task {
    subagent_type: "general-purpose"
    description: "Analyze test failures - iteration $iteration"
    prompt: "..."
  }
```
**Context**: Inside `for iteration in 1 2 3` loop, analyzing test failures

**Violation 2: Line 1599 - Fix Application Invocation**
```markdown
  # Invoke code-writer to apply fixes
  Task {
    subagent_type: "general-purpose"
    description: "Apply debug fixes - iteration $iteration"
    prompt: "..."
  }
```
**Context**: Same loop, applying fixes from debug analysis

**Violation 3: Line 1696 - Test Re-run Invocation**
```markdown
  # Re-run tests (invoke test-specialist again)
  Task {
    subagent_type: "general-purpose"
    description: "Re-run tests after fixes"
    prompt: "..."
  }
```
**Context**: Same loop, re-running tests to verify fixes

## Impact Assessment

### Current State
- **Test Pass Rate**: 11/12 (91.7%)
- **Compliance**: Non-compliant with Standard 11
- **Functional Impact**: Likely minimal - invocations may still work due to context, but not guaranteed
- **Delegation Rate**: Potentially reduced in Phase 5 debug iterations

### After Fix
- **Test Pass Rate**: 12/12 (100%) ✓
- **Compliance**: Fully compliant with Standard 11 ✓
- **Functional Impact**: Guaranteed agent delegation ✓
- **Delegation Rate**: >90% maintained across all phases ✓

### Risk Analysis

**Risk of NOT fixing**: Low-Medium
- Test suite shows non-compliance
- Potential for 0% delegation in debug phase (historical precedent)
- Inconsistency with rest of command (maintenance confusion)

**Risk of fixing**: Very Low
- Simple pattern replacement
- Proven pattern used successfully throughout rest of supervise.md
- Same pattern used in /coordinate, /research (both passing tests)
- No behavioral changes - only syntax clarification

## Correct Pattern Examples from supervise.md

The correct imperative pattern is already used in Phases 1-4 of supervise.md:

### Example 1: Phase 1 - Research Agent (Line ~655)
```markdown
**EXECUTE NOW**: USE the Task tool for EACH research topic (1 to $RESEARCH_COUNT) with these parameters:

- subagent_type: "general-purpose"
- description: "Research [insert topic name] with mandatory artifact creation"
- prompt: |
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md
    ...
```

### Example 2: Phase 2 - Planning Agent (Line ~948)
```markdown
**EXECUTE NOW**: USE the Task tool with these parameters:

- subagent_type: "general-purpose"
- description: "Create implementation plan with mandatory file creation"
- prompt: |
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md
    ...
```

### Example 3: Phase 4 - Testing Agent (Line ~1311)
```markdown
**EXECUTE NOW**: USE the Task tool with these parameters:

- subagent_type: "general-purpose"
- description: "Run comprehensive test suite"
- prompt: |
    Read and follow ALL behavioral guidelines from: .claude/agents/test-specialist.md
    ...
```

**Pattern Consistency**: Phases 1-4 ALL use `**EXECUTE NOW**: USE the Task tool...` - Phase 5 should match.

## Recommended Solution

### Transformation Pattern

For each of the 3 violations, apply this transformation:

**Before**:
```markdown
  # [Comment describing invocation]
  Task {
    subagent_type: "[type]"
    description: "[description]"
    prompt: "
      [prompt content]
    "
  }
```

**After**:
```markdown
  # [Comment describing invocation]
  **EXECUTE NOW**: USE the Task tool with these parameters:

  - subagent_type: "[type]"
  - description: "[description]"
  - prompt: |
      [prompt content - note: change from " to | for multiline]
```

### Specific Changes Required

**Change 1 (Line 1440)**: Debug Analyst Invocation
- Replace: `Task {` → `**EXECUTE NOW**: USE the Task tool with these parameters:`
- Replace: `subagent_type:` → `- subagent_type:`
- Replace: `description:` → `- description:`
- Replace: `prompt: "` → `- prompt: |`
- Remove: closing `}` and trailing `"`

**Change 2 (Line 1599)**: Code Writer Invocation
- Same transformation as Change 1

**Change 3 (Line 1696)**: Test Re-run Invocation
- Same transformation as Change 1

### Validation

After applying changes, verify with:
```bash
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md
# Expected: No violations found

.claude/tests/test_orchestration_commands.sh
# Expected: 12/12 tests passing
```

## Implementation Complexity

### Complexity Rating: **Low**

**Reasons**:
1. **Straightforward Pattern**: Mechanical replacement following clear rules
2. **No Logic Changes**: Only syntax transformation, no behavioral modifications
3. **Proven Pattern**: Target pattern already used 10+ times in same file
4. **Small Scope**: Only 3 invocations to fix
5. **Clear Validation**: Automated test confirms success

### Estimated Duration
- **Research**: 15 minutes (complete via this report)
- **Implementation**: 15-20 minutes (3 replacements)
- **Testing**: 5-10 minutes (run validation + test suite)
- **Total**: 35-45 minutes

### Prerequisites
- None - all information in this report
- No external dependencies
- No coordination with other changes needed

## Testing Strategy

### Pre-Implementation Baseline
```bash
# Capture current state
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md > /tmp/before.txt
.claude/tests/test_orchestration_commands.sh > /tmp/tests_before.txt
```

### Post-Implementation Validation
```bash
# Verify fixes
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md
# Expected: "✓ No YAML-style Task blocks found"

# Run full test suite
.claude/tests/test_orchestration_commands.sh
# Expected: "Total tests run: 12, Passed: 12"

# Verify file size unchanged (only whitespace/formatting)
wc -l .claude/commands/supervise.md
# Expected: ~1,941 lines (±5 lines for formatting)
```

### Regression Prevention
- Test 1: Verify delegation rate maintained (>90%)
- Test 2: Verify bootstrap sequence still passes
- Test 3: Verify all utility scripts executable
- Test 4: Manual smoke test - run /supervise with simple workflow

## Historical Context

### Related Fixes

**Spec 438** (2025-10-24): /supervise YAML invocation fix
- Fixed 7 YAML blocks in Phases 1-4
- Result: 0% → >90% delegation rate
- These 3 Phase 5 blocks were likely overlooked in that fix

**Spec 495** (2025-10-27): /coordinate and /research YAML fixes
- Fixed 9 invocations in /coordinate
- Fixed 3 invocations in /research
- Evidence: Files created in correct locations after fix (not TODO.md)
- Pattern: Same transformation we're applying here

**Spec 507** (2025-10-28): /supervise improvements (Phases 0-6)
- Phase 1 baseline: Noted 1 known issue (these YAML invocations)
- Phase 2: Did not address Phase 5 YAML blocks (focused on fail-fast)
- Phase 6: Documented issue as out-of-scope for that spec

### Why These Were Missed

1. **Phase 5 Complexity**: Debug section has conditional logic (iteration loop)
2. **Spec 438 Scope**: May have focused on main flow (Phases 1-4)
3. **Spec 507 Scope**: Explicitly excluded YAML fixes (noted as future work)

### Lessons Learned

**Prevention**: Validation script catches all YAML blocks - use it before committing
**Detection**: Automated tests surface issues immediately
**Resolution**: Clear transformation pattern makes fixes straightforward

## Recommendations

### Immediate Actions (This Spec)
1. ✅ Create this research report documenting issue
2. Create implementation plan with 3-task structure
3. Apply transformations to lines 1440, 1599, 1696
4. Run validation script to confirm 0 violations
5. Run test suite to confirm 12/12 passing
6. Commit with message: `fix(511): Replace YAML-style Task invocations with imperative pattern in Phase 5`

### Follow-Up Actions (Future)
1. **Pre-Commit Hook**: Add validation script to git pre-commit hook
2. **CI/CD Integration**: Run test_orchestration_commands.sh in CI pipeline
3. **Documentation**: Update supervise-phases.md with imperative pattern requirement
4. **Code Review**: Check for YAML blocks in all new agent invocations

### Quality Gates
- [ ] Validation script shows 0 violations
- [ ] Test suite shows 12/12 passing
- [ ] Delegation rate >90% maintained
- [ ] File size within ±10 lines of current (1,941)
- [ ] Git commit follows conventional commit format

## References

### Key Files
- **Main File**: `.claude/commands/supervise.md` (lines 1440, 1599, 1696)
- **Validation Script**: `.claude/lib/validate-agent-invocation-pattern.sh`
- **Test Suite**: `.claude/tests/test_orchestration_commands.sh`
- **Standards**: `.claude/docs/reference/command_architecture_standards.md#standard-11`
- **Pattern Guide**: `.claude/docs/guides/imperative-language-guide.md`

### Related Specs
- **Spec 438**: /supervise YAML fix (Phases 1-4)
- **Spec 495**: /coordinate and /research YAML fixes
- **Spec 497**: Unified orchestration improvements
- **Spec 507**: /supervise improvements (Phases 0-6)

### Validation Commands
```bash
# Check for YAML violations
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md

# Run full test suite
.claude/tests/test_orchestration_commands.sh

# Check file size
wc -l .claude/commands/supervise.md
```

## Conclusion

Fixing the 3 YAML-style Task invocations in /supervise Phase 5 is a straightforward, low-risk change that will:
1. Achieve 12/12 test pass rate (100% compliance)
2. Eliminate anti-pattern violations
3. Ensure consistent agent delegation across all phases
4. Align Phase 5 with proven patterns from Phases 1-4

The transformation is mechanical, well-documented, and takes ~35-45 minutes to complete with validation. This fix completes the /supervise improvement work started in Spec 507 and brings the command to full Standard 11 compliance.
