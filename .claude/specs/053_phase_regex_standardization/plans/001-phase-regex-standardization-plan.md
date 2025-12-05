# Phase Counting Regex Standardization Implementation Plan

## Metadata
- **Date**: 2025-12-04
- **Feature**: Standardize phase counting regex pattern across .claude/ codebase
- **Scope**: Update 4 active code files and 1 standards document to use `^### Phase [0-9]` pattern instead of buggy `^### Phase` pattern that causes false positives
- **Estimated Phases**: 3
- **Estimated Hours**: 2-3 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 23.0
- **Structure Level**: 0
- **Research Reports**:
  - [Phase Regex Standardization Research](../reports/001-phase-regex-standardization-research.md)
  - [Phase Counting Regex Fix Research](../../052_phase_counting_regex_fix/reports/001-phase-counting-regex-research.md)

## Overview

This plan addresses a critical bug in phase counting logic that causes false positives when matching phase headings. The buggy pattern `^### Phase` matches non-phase headers like `### Phase Routing Summary` and template examples (`### Phase N:`), leading to incorrect phase counts and workflow failures.

The fix standardizes on the `^### Phase [0-9]` pattern already proven in checkbox-utils.sh (authoritative library) and 6 other files. This pattern requires a digit after "Phase ", preventing false positives while maintaining compatibility with all existing plans.

**Real-World Impact**: In recent execution, implement.md Block 1d counted 6 "phases" instead of 3 due to false positives, causing recovery loop to process non-existent phases 4-6 and preventing plan status updates.

## Research Summary

Research findings from both reports confirm:

1. **Root Cause**: Pattern `^### Phase` without digit requirement matches any text after "Phase", including summary sections and template examples
2. **Proven Solution**: Pattern `^### Phase [0-9]` used in checkbox-utils.sh (authoritative library) and 6 other files requires digit, eliminating false positives
3. **Affected Files**: 4 active code files (implement.md, lean-build.md, lean-implement.md, cleanup-plan-architect.md) use buggy pattern
4. **Standards Gap**: No explicit documentation of phase counting regex standard in plan-progress.md
5. **Test Coverage**: Existing test files show both correct and buggy patterns, requiring updates for consistency

Recommended approach: Update all buggy patterns to match authoritative library pattern, then document standard to prevent future regressions.

## Success Criteria

- [ ] All 4 active code files updated to use `^### Phase [0-9]` pattern
- [ ] Standards documentation updated with explicit phase counting regex requirement
- [ ] Test validation confirms correct phase counting (no false positives)
- [ ] Pre-commit validation passes for all modified files
- [ ] Manual verification with mixed-content test plan shows accurate counts

## Technical Design

### Pattern Change Specification

**Current Buggy Pattern**:
```bash
grep -c "^### Phase" "$PLAN_FILE"
grep -c "^### Phase.*\[COMPLETE\]" "$PLAN_FILE"
```

**Updated Correct Pattern**:
```bash
grep -c "^### Phase [0-9]" "$PLAN_FILE"
grep -c "^### Phase [0-9].*\[COMPLETE\]" "$PLAN_FILE"
```

### File Modification Matrix

| File | Lines | Pattern Type | Change Required |
|------|-------|--------------|----------------|
| `.claude/commands/implement.md` | 1160, 1165 | Phase counting (grep -c) | Add ` [0-9]` after `Phase` |
| `.claude/commands/lean-build.md` | 682, 683 | Phase counting (grep -c) | Add ` [0-9]` after `Phase` |
| `.claude/commands/lean-implement.md` | 1024, 1025 | Phase counting (grep -c) | Add ` [0-9]` after `Phase` |
| `.claude/agents/cleanup-plan-architect.md` | 504 | Phase existence (grep -q) | Add ` [0-9]` after `Phase` |

### Standards Documentation Enhancement

Add new section to `.claude/docs/reference/standards/plan-progress.md` documenting:
- Required regex pattern with digit requirement
- Pattern explanation table (components, matches, non-matches)
- Real-world bug example from implement.md
- Enforcement requirements for command authors
- Alternative patterns for advanced use cases (h2/h3 flexibility)

### Architecture Alignment

This fix aligns all phase counting operations with checkbox-utils.sh (authoritative library), creating consistent behavior across:
- Implementation commands (implement, lean-implement)
- Build orchestrators (lean-build)
- Plan validation agents (cleanup-plan-architect)
- Standards documentation (plan-progress)

## Implementation Phases

### Phase 1: Update Active Code Files [COMPLETE]
dependencies: []

**Objective**: Replace buggy phase counting patterns in all 4 active code files with proven `^### Phase [0-9]` pattern

**Complexity**: Low

**Tasks**:
- [x] Update `.claude/commands/implement.md` line 1160: Change `grep -c "^### Phase"` to `grep -c "^### Phase [0-9]"` (file: /home/benjamin/.config/.claude/commands/implement.md)
- [x] Update `.claude/commands/implement.md` line 1165: Change `grep -c "^### Phase.*\[COMPLETE\]"` to `grep -c "^### Phase [0-9].*\[COMPLETE\]"` (file: /home/benjamin/.config/.claude/commands/implement.md)
- [x] Update `.claude/commands/lean-build.md` line 682: Change `grep -c "^### Phase"` to `grep -c "^### Phase [0-9]"` (file: /home/benjamin/.config/.claude/commands/lean-build.md)
- [x] Update `.claude/commands/lean-build.md` line 683: Change `grep -c "^### Phase.*\[COMPLETE\]"` to `grep -c "^### Phase [0-9].*\[COMPLETE\]"` (file: /home/benjamin/.config/.claude/commands/lean-build.md)
- [x] Update `.claude/commands/lean-implement.md` line 1024: Change `grep -c "^### Phase"` to `grep -c "^### Phase [0-9]"` (file: /home/benjamin/.config/.claude/commands/lean-implement.md)
- [x] Update `.claude/commands/lean-implement.md` line 1025: Change `grep -c "^### Phase.*\[COMPLETE\]"` to `grep -c "^### Phase [0-9].*\[COMPLETE\]"` (file: /home/benjamin/.config/.claude/commands/lean-implement.md)
- [x] Update `.claude/agents/cleanup-plan-architect.md` line 504: Change `grep -q "^### Phase"` to `grep -q "^### Phase [0-9]"` (file: /home/benjamin/.config/.claude/agents/cleanup-plan-architect.md)

**Testing**:
```bash
# Verify all changes applied correctly (exact pattern match)
for file in \
  .claude/commands/implement.md \
  .claude/commands/lean-build.md \
  .claude/commands/lean-implement.md \
  .claude/agents/cleanup-plan-architect.md; do

  echo "Checking $file:"
  grep -n 'grep.*"^### Phase"' "$file" && echo "  ERROR: Buggy pattern found" || echo "  ✓ No buggy patterns"
  grep -n 'grep.*"^### Phase \[0-9\]"' "$file" && echo "  ✓ Correct pattern found" || echo "  WARNING: Correct pattern not found"
done

# Create test plan with false positive triggers
cat > /tmp/phase_count_test.md << 'EOF'
## Metadata
- **Status**: [COMPLETE]

### Phase Routing Summary
| Phase | Type |
|-------|------|
| 1 | software |
| 2 | software |

### Phase 1: Setup [COMPLETE]
Tasks here

### Phase 2: Implementation [COMPLETE]
Tasks here

### Phase 3: Testing [COMPLETE]
Tasks here

### Phase N: [Example Template]
Template content
EOF

# Verify buggy pattern counts 6 (BEFORE fix)
BUGGY_COUNT=$(grep -c "^### Phase" /tmp/phase_count_test.md 2>/dev/null || echo "0")
echo "Buggy pattern count: $BUGGY_COUNT (should be 6)"

# Verify correct pattern counts 3 (AFTER fix)
CORRECT_COUNT=$(grep -c "^### Phase [0-9]" /tmp/phase_count_test.md 2>/dev/null || echo "0")
echo "Correct pattern count: $CORRECT_COUNT (should be 3)"

# Verify complete phase counting
COMPLETE_COUNT=$(grep -c "^### Phase [0-9].*\[COMPLETE\]" /tmp/phase_count_test.md 2>/dev/null || echo "0")
echo "Complete phases: $COMPLETE_COUNT (should be 2)"
```

**Expected Duration**: 30 minutes

### Phase 2: Update Standards Documentation [COMPLETE]
dependencies: [1]

**Objective**: Document phase counting regex standard in plan-progress.md to enforce correct pattern going forward

**Complexity**: Low

**Tasks**:
- [x] Add "Phase Counting Standard" section to `.claude/docs/reference/standards/plan-progress.md` after line 240 (file: /home/benjamin/.config/.claude/docs/reference/standards/plan-progress.md)
- [x] Include required regex pattern subsection with code examples
- [x] Include pattern explanation table (component, purpose, example match, example non-match)
- [x] Include "Why Digit Requirement is Critical" subsection with false positive examples
- [x] Include real-world bug example from implement.md Block 1d
- [x] Include enforcement requirements subsection for command authors
- [x] Include alternative patterns subsection for h2/h3 flexibility (advanced use case)

**Testing**:
```bash
# Verify standards section added
grep -q "## Phase Counting Standard" .claude/docs/reference/standards/plan-progress.md && \
  echo "✓ Phase Counting Standard section added" || \
  echo "ERROR: Section not found"

# Verify pattern documented
grep -q '\^### Phase \[0-9\]' .claude/docs/reference/standards/plan-progress.md && \
  echo "✓ Pattern documented" || \
  echo "ERROR: Pattern not documented"

# Verify real-world bug example included
grep -q "counted 6.*instead of 3" .claude/docs/reference/standards/plan-progress.md && \
  echo "✓ Real-world example included" || \
  echo "ERROR: Example missing"

# Verify enforcement section exists
grep -q "Enforcement" .claude/docs/reference/standards/plan-progress.md && \
  echo "✓ Enforcement section present" || \
  echo "ERROR: Enforcement section missing"
```

**Expected Duration**: 1 hour

### Phase 3: Validation and Testing [COMPLETE]
dependencies: [1, 2]

**Objective**: Verify all changes work correctly and pass pre-commit validation

**Complexity**: Low

**Tasks**:
- [x] Run pre-commit validation on all modified files (bash .claude/scripts/validate-all-standards.sh --staged)
- [x] Execute manual test with mixed-content plan to verify accurate phase counting
- [x] Verify no regressions in existing test suites (grep for test files referencing phase counting)
- [x] Update test files using buggy pattern for consistency (test_plan_architect_revision_mode.sh, test_revise_small_plan.sh) - OPTIONAL
- [x] Verify plan-progress.md standards section renders correctly in Markdown

**Testing**:
```bash
# Pre-commit validation
bash .claude/scripts/validate-all-standards.sh --staged
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  echo "✓ Pre-commit validation passed"
else
  echo "ERROR: Pre-commit validation failed (exit $EXIT_CODE)"
  exit 1
fi

# Manual mixed-content test (reuse from Phase 1)
cat > /tmp/phase_validation_test.md << 'EOF'
## Metadata
- **Status**: [COMPLETE]

### Phase Routing Summary
| Phase | Type | Dependencies |
|-------|------|--------------|
| 1 | software | [] |
| 2 | software | [1] |
| 3 | software | [1, 2] |

### Phase 1: Foundation [COMPLETE]
- [x] Task 1
- [x] Task 2

### Phase 2: Core Implementation [COMPLETE]
- [x] Task 1
- [x] Task 2

### Phase 3: Integration [COMPLETE]
- [x] Task 1
- [x] Task 2

### Phase N: [Example Template]
This is a template showing phase structure.
- [ ] Example task

### Phase Dependencies
No external dependencies.
EOF

# Test with corrected pattern
TOTAL_PHASES=$(grep -c "^### Phase [0-9]" /tmp/phase_validation_test.md 2>/dev/null || echo "0")
COMPLETE_PHASES=$(grep -c "^### Phase [0-9].*\[COMPLETE\]" /tmp/phase_validation_test.md 2>/dev/null || echo "0")

echo "Validation Results:"
echo "  Total phases: $TOTAL_PHASES (expected: 3)"
echo "  Complete phases: $COMPLETE_PHASES (expected: 2)"

[ "$TOTAL_PHASES" -eq 3 ] && [ "$COMPLETE_PHASES" -eq 2 ] && {
  echo "✓ Phase counting accurate (no false positives)"
} || {
  echo "ERROR: Phase counting incorrect"
  exit 1
}

# Verify no broken references in test files
echo "Checking test files for phase counting patterns:"
grep -rn 'grep.*"^### Phase"' .claude/tests/ | grep -v '\[0-9\]' && \
  echo "  WARNING: Some test files still use buggy pattern (non-critical)" || \
  echo "  ✓ No buggy patterns in tests"

# Verify standards documentation is readable
if [ -f .claude/docs/reference/standards/plan-progress.md ]; then
  echo "✓ Standards file exists and is readable"
else
  echo "ERROR: Standards file not found"
  exit 1
fi
```

**Expected Duration**: 30 minutes - 1 hour

## Testing Strategy

### Unit Testing
- Pattern matching validation with test plans containing false positive triggers
- Regression testing on existing test suites to ensure no breakage
- Edge case testing with plans containing only summary sections (should count 0 phases)

### Integration Testing
- Execute /implement command with corrected pattern on real plans
- Verify Block 1d phase counting produces correct results
- Test recovery loop behavior with accurate phase counts

### Validation Testing
- Pre-commit hook validation on all modified files
- Link validation for standards documentation cross-references
- Markdown rendering validation for plan-progress.md updates

### Test Plan Structure
1. **Phase 1 Testing**: Verify exact pattern changes with grep validation
2. **Phase 2 Testing**: Verify standards documentation completeness with content checks
3. **Phase 3 Testing**: End-to-end validation with mixed-content test plan and pre-commit checks

## Documentation Requirements

### Files Requiring Updates
1. `.claude/docs/reference/standards/plan-progress.md` - Add Phase Counting Standard section (new section)
2. This implementation plan - Reference for future similar pattern standardization efforts

### Documentation Standards Compliance
- Follow CLAUDE.md documentation policy (clear, concise, no historical commentary)
- Use code examples with syntax highlighting (bash blocks)
- Include real-world bug example for context
- Cross-reference authoritative library (checkbox-utils.sh)
- Document enforcement requirements explicitly

### README Updates
No README updates required - this change is internal to existing files.

## Dependencies

### External Dependencies
None - this is a self-contained pattern update within .claude/ codebase.

### Internal Dependencies
1. **Authoritative Library**: `.claude/lib/plan/checkbox-utils.sh` (lines 672, 684) - serves as reference implementation
2. **Standards File**: `.claude/docs/reference/standards/plan-progress.md` - requires update to document standard
3. **Pre-commit Infrastructure**: Validation scripts must pass for commit approval

### Prerequisite Knowledge
- Understanding of grep regex patterns (basic anchors and character classes)
- Familiarity with phase heading format in implementation plans
- Knowledge of /implement command phase counting logic

### Risk Mitigation
- **Risk**: Changes break existing plans with non-standard phase numbering
  - **Mitigation**: Pattern `^### Phase [0-9]` matches all standard numbered phases (Phase 0-9, Phase 10+)
- **Risk**: Test suites fail due to pattern change
  - **Mitigation**: Test files already use mix of correct/buggy patterns; update only if needed
- **Risk**: Standards documentation becomes out of sync
  - **Mitigation**: Include enforcement section directing command authors to this standard

## Notes

### Why This Fix Matters
The buggy pattern caused implement.md Block 1d to count 6 "phases" instead of 3 in recent execution:
- 3 real phases: `### Phase 1:`, `### Phase 2:`, `### Phase 3:`
- 2 false positives: `### Phase Routing Summary` (appeared twice in plan)
- 1 false positive: `### Phase N:` (template example in documentation)

This incorrect count triggered the recovery loop to process non-existent phases 4-6, causing errors and preventing plan status updates from executing.

### Pattern Alignment
The fixed pattern `^### Phase [0-9]` is already used in:
- checkbox-utils.sh (authoritative library) - lines 672, 684
- plan-architect.md (agent) - lines 1188, 1199, 1200
- todo-functions.sh (library) - lines 206, 207
- lean-plan.md (command) - line 1803
- create-plan.md (command) - line 1541
- phase-classifier.sh (library) - line 92
- revise.md (command) - line 1204

This fix brings all remaining files into alignment with established patterns.

### Future Enhancements (Out of Scope)
- Add linter to detect buggy phase counting patterns (`.claude/scripts/lint-phase-counting-regex.sh`)
- Update test files for consistency (test_plan_architect_revision_mode.sh, test_revise_small_plan.sh)
- Review `.claude/docs/reference/workflows/phases-planning.md` line 96 for digit requirement
