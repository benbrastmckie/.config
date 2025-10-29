# Fix YAML-Style Task Invocations Implementation Plan

## Metadata
- **Date**: 2025-10-28
- **Feature**: Replace 3 YAML-style Task invocations with imperative pattern in supervise.md Phase 5
- **Scope**: Fix Standard 11 compliance violations to achieve 12/12 test pass rate
- **Estimated Phases**: 3
- **Estimated Hours**: 0.5-0.75 hours (30-45 minutes)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - .claude/specs/511_fix_yaml_task_invocations_in_supervise/reports/001_yaml_invocation_anti_pattern_analysis.md

## Overview

The /supervise command contains 3 YAML-style Task invocations in Phase 5 (Debug section, lines 1440, 1599, 1696) that violate Standard 11 (Imperative Agent Invocation Pattern). These cause test_orchestration_commands.sh to fail with "Anti-patterns detected", resulting in 11/12 test pass rate. This plan fixes all 3 violations by transforming them to the imperative bullet-point pattern (`**EXECUTE NOW**: USE the Task tool...`) already used successfully in Phases 1-4 of the same file.

**Current State**: 11/12 tests passing (91.7%)
**Target State**: 12/12 tests passing (100%) ✓
**Risk**: Very Low - mechanical transformation using proven pattern
**Complexity**: Low - straightforward pattern replacement

## Research Summary

From research report 001_yaml_invocation_anti_pattern_analysis.md:

**Why YAML Pattern Fails**:
- Documentation-only YAML blocks (`Task { ... }`) appear as syntax examples rather than executable instructions
- Historical evidence: Spec 438 and 495 showed 0% delegation rate with YAML blocks
- Missing imperative directive ("EXECUTE NOW") causes Claude to skip execution

**Correct Pattern** (already used in Phases 1-4):
```markdown
**EXECUTE NOW**: USE the Task tool with these parameters:

- subagent_type: "general-purpose"
- description: "[description]"
- prompt: |
    [prompt content]
```

**Locations to Fix**:
1. Line 1440: Debug analyst invocation (inside debug iteration loop)
2. Line 1599: Code writer invocation (fix application)
3. Line 1696: Test re-run invocation (verification)

## Success Criteria

- [x] All 3 YAML-style invocations replaced with imperative pattern
- [x] Validation script shows 0 violations: `.claude/lib/validate-agent-invocation-pattern.sh`
- [x] Test suite shows 12/12 passing: `.claude/tests/test_orchestration_commands.sh`
- [x] File size within ±10 lines of current (1,941 lines)
- [x] Delegation rate >90% maintained
- [x] Git commit follows conventional commit format

## Technical Design

### Transformation Pattern

For each YAML-style invocation, apply this mechanical transformation:

**Before (YAML-style - WRONG)**:
```markdown
  # Comment
  Task {
    subagent_type: "type"
    description: "desc"
    prompt: "
      content
    "
  }
```

**After (Imperative - CORRECT)**:
```markdown
  # Comment
  **EXECUTE NOW**: USE the Task tool with these parameters:

  - subagent_type: "type"
  - description: "desc"
  - prompt: |
      content
```

### Key Changes Per Invocation

1. **Add imperative header**: `**EXECUTE NOW**: USE the Task tool with these parameters:`
2. **Convert to bullet points**: `subagent_type:` → `- subagent_type:`
3. **Change prompt delimiter**: `prompt: "` → `- prompt: |` (YAML block scalar)
4. **Remove YAML braces**: Delete opening `{` and closing `}`
5. **Remove trailing quotes**: Delete `"` after prompt content

### File Structure (Unchanged)

- Modified File: `.claude/commands/supervise.md`
- Lines Affected: 1440-1545 (Invocation 1), 1599-1680 (Invocation 2), 1696-1721 (Invocation 3)
- No new files created
- No deletions

## Implementation Phases

### Phase 1: Fix First YAML Invocation (Line 1440)
**Objective**: Replace debug-analyst invocation with imperative pattern

**Complexity**: Low

Tasks:
- [x] Read supervise.md lines 1435-1550 to get full context
- [x] Identify exact start/end of Task block (lines 1440-1545)
- [x] Apply transformation pattern:
  - Add `**EXECUTE NOW**: USE the Task tool with these parameters:` before `Task {`
  - Convert `subagent_type:` to `- subagent_type:`
  - Convert `description:` to `- description:`
  - Convert `prompt: "` to `- prompt: |`
  - Remove closing `}` and trailing `"`
- [x] Verify indentation preserved (2 spaces for bash context)
- [x] Run validation script to check this invocation fixed

Testing:
```bash
# Verify transformation
grep -A 10 "debug-analyst" .claude/commands/supervise.md | head -15

# Check validation (should show 2 remaining violations)
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md
# Expected: Lines 1599, 1696 still flagged
```

**Expected Duration**: 10-15 minutes

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Invocation 1 transformed correctly
- [x] Validation shows 2 remaining violations (down from 3)
- [x] No syntax errors introduced

### Phase 2: Fix Second and Third YAML Invocations (Lines 1599, 1696)
**Objective**: Replace code-writer and test re-run invocations with imperative pattern

**Complexity**: Low

Tasks:
- [x] Read supervise.md lines 1594-1685 (code-writer context)
- [x] Apply same transformation to line 1599 invocation:
  - Add imperative header
  - Convert to bullet points
  - Change prompt delimiter to `|`
  - Remove braces and quotes
- [x] Read supervise.md lines 1691-1725 (test re-run context)
- [x] Apply same transformation to line 1696 invocation:
  - Add imperative header
  - Convert to bullet points
  - Change prompt delimiter to `|`
  - Remove braces and quotes
- [x] Verify all 3 invocations now use consistent pattern

Testing:
```bash
# Verify all transformations
grep -B 2 "EXECUTE NOW" .claude/commands/supervise.md | grep -A 1 "debug\|code-writer\|test-specialist"

# Validation should show 0 violations
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md
# Expected: ✓ No YAML-style Task blocks found
```

**Expected Duration**: 10-15 minutes

**Phase 2 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Invocations 2 and 3 transformed correctly
- [x] Validation shows 0 violations
- [x] All 3 invocations use identical pattern structure

### Phase 3: Validation and Testing
**Objective**: Verify all tests pass and no regressions introduced

**Complexity**: Low

Tasks:
- [x] Run full test suite: `.claude/tests/test_orchestration_commands.sh`
- [x] Verify 12/12 tests passing (up from 11/12)
- [x] Verify file size within expected range (1,941 ±10 lines)
- [x] Check git diff to ensure only targeted lines changed
- [x] Verify no whitespace-only changes introduced
- [x] Create git commit with conventional commit message

Testing:
```bash
# Full test suite
cd .claude/tests
./test_orchestration_commands.sh

# Expected output:
# Total tests run: 12
# Passed: 12
# Failed: 0
# ✓ All tests passed

# File size check
wc -l .claude/commands/supervise.md
# Expected: 1,941 ±10 lines (formatting may add/remove a few lines)

# Git diff review
git diff .claude/commands/supervise.md | head -50
# Verify only lines 1440, 1599, 1696 areas changed
```

**Expected Duration**: 10-15 minutes

**Phase 3 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Test suite shows 12/12 passing ✓
- [x] Validation script shows 0 violations ✓
- [x] File size within acceptable range
- [x] Git commit created: `fix(511): Replace YAML-style Task invocations with imperative pattern in Phase 5`

## Testing Strategy

### Pre-Implementation Baseline
```bash
# Capture current state
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md 2>&1 | tee /tmp/validation_before.txt
# Expected: 3 violations at lines 1440, 1599, 1696

.claude/tests/test_orchestration_commands.sh 2>&1 | tee /tmp/tests_before.txt
# Expected: 11/12 passing, 1 failure (Agent invocation pattern: supervise.md)
```

### Post-Implementation Validation
```bash
# Verify all fixes
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md
# Expected: ✓ No YAML-style Task blocks found

# Run full test suite
cd .claude/tests && ./test_orchestration_commands.sh
# Expected: Total tests run: 12, Passed: 12, Failed: 0

# Verify file integrity
wc -l .claude/commands/supervise.md
# Expected: ~1,941 lines (±5 for formatting)

# Check git diff statistics
git diff --stat .claude/commands/supervise.md
# Expected: Small number of insertions/deletions (transformation overhead)
```

### Regression Prevention
1. **Delegation Rate Test**: Verify test_orchestration_commands.sh "Delegation rate check: supervise.md" passes
2. **Bootstrap Test**: Verify "Bootstrap sequence: supervise" passes
3. **Utility Scripts Test**: Verify all utility scripts remain executable
4. **Manual Smoke Test**: (Optional) Run `/supervise "simple research task"` to verify Phase 5 debug works

## Documentation Requirements

### Updated Files
- `.claude/commands/supervise.md` - 3 invocations transformed to imperative pattern

### No Documentation Updates Needed
- Transformation is internal implementation detail
- Pattern already documented in Command Architecture Standards (Standard 11)
- Research report serves as record of why/how fix was applied

### Git Commit Message
```
fix(511): Replace YAML-style Task invocations with imperative pattern in Phase 5

Fixed 3 YAML-style Task blocks in supervise.md Phase 5 (debug section) that violated
Standard 11 (Imperative Agent Invocation Pattern). Transformed to imperative bullet-point
pattern already used in Phases 1-4.

Changes:
- Line 1440: Debug analyst invocation - added "EXECUTE NOW" directive
- Line 1599: Code writer invocation - added "EXECUTE NOW" directive
- Line 1696: Test re-run invocation - added "EXECUTE NOW" directive

Result:
- Test suite: 11/12 → 12/12 passing (100% compliance)
- Validation: 3 violations → 0 violations
- Standard 11 compliance: Fully compliant
- Pattern consistency: All phases use imperative pattern

Part of spec 511 - completes /supervise improvement work from spec 507.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Dependencies

### External Dependencies
None - self-contained fix within single file

### Internal Dependencies
- **supervise.md**: File being modified
- **validate-agent-invocation-pattern.sh**: Validation script (already exists)
- **test_orchestration_commands.sh**: Test suite (already exists)

### Standards Dependencies
- Command Architecture Standards (Standard 11) - reference only, not modified
- Imperative Language Guide - reference only, not modified

## Risk Assessment

### Risk Level: **Very Low**

**Reasons**:
1. **Mechanical Transformation**: Simple pattern replacement with clear rules
2. **Proven Pattern**: Target pattern used successfully 10+ times in same file
3. **Small Scope**: Only 3 invocations affected
4. **Automated Validation**: Scripts immediately detect success/failure
5. **Easy Rollback**: Git backup available if issues arise

### Potential Risks and Mitigations

**Risk 1: Incorrect Transformation**
- Likelihood: Very Low
- Impact: Medium (test failure)
- Mitigation: Validation script catches immediately, phase-by-phase testing

**Risk 2: Whitespace/Indentation Issues**
- Likelihood: Low
- Impact: Low (cosmetic)
- Mitigation: Preserve exact indentation from original, git diff review

**Risk 3: Breaking Phase 5 Debug Functionality**
- Likelihood: Very Low (transformation doesn't change behavior)
- Impact: Medium (debug phase fails)
- Mitigation: Same pattern works in Phases 1-4, test suite validates

### Rollback Plan

If issues arise:
```bash
# Restore from git
git checkout -- .claude/commands/supervise.md

# Or restore from backup
cp .claude/commands/supervise.md.backup-20251028 .claude/commands/supervise.md
```

## Notes

### Historical Context

This fix completes the YAML invocation cleanup work:
- **Spec 438** (2025-10-24): Fixed Phases 1-4 (7 invocations)
- **Spec 495** (2025-10-27): Fixed /coordinate (9) and /research (3)
- **Spec 507** (2025-10-28): Phases 0-6 improvements, noted Phase 5 YAML issue as out-of-scope
- **Spec 511** (2025-10-28): This plan - fixes remaining Phase 5 violations (3 invocations)

### Why These Were Missed in Spec 507

Phase 5 (Debug) was not the focus of Spec 507, which prioritized:
- Phase 0: Bash error fixes and output formatting
- Phase 2: Fail-fast error handling
- Phase 3: Documentation extraction
- Phase 4: Context pruning

The YAML invocations in Phase 5 were documented as a known issue but deferred for separate fix (this spec).

### Pattern Consistency

After this fix, ALL agent invocations in /supervise will use the imperative pattern:
- Phase 1: Research agents (multiple) ✓
- Phase 2: Planning agent ✓
- Phase 3: Implementation agent ✓
- Phase 4: Testing agent ✓
- Phase 5: Debug agents (3 in loop) ← **Fixed by this plan**
- Phase 6: Documentation agent ✓

### Future Prevention

To prevent YAML pattern regressions:
1. **Pre-Commit Hook**: Add validation script to git hooks
2. **CI/CD**: Run test_orchestration_commands.sh in continuous integration
3. **Code Review**: Check for `Task {` pattern in reviews
4. **Documentation**: Update supervise-phases.md to emphasize imperative pattern

## Implementation Checklist

Before starting:
- [x] Research report read and understood
- [x] Transformation pattern clear
- [x] Validation script tested and working
- [x] Backup of supervise.md exists (.backup-20251028)

During implementation:
- [x] Phase 1 complete and validated
- [x] Phase 2 complete and validated
- [x] Phase 3 complete and validated

After completion:
- [x] All tests passing (12/12)
- [x] Validation shows 0 violations
- [x] Git commit created
- [x] Plan marked complete

## Success Metrics

**Target Metrics** (ALL must be met):
- ✅ Test pass rate: 12/12 (100%)
- ✅ Validation violations: 0
- ✅ File size: 1,941 ±10 lines
- ✅ Delegation rate: >90%
- ✅ Bootstrap test: Passing
- ✅ Implementation time: <1 hour

**Achieved on**: 2025-10-28

This plan completes the /supervise command improvement work and achieves full Standard 11 compliance across all orchestration commands.
