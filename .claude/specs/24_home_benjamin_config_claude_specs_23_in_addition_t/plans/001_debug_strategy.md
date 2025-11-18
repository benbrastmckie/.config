# Debug Strategy: Fix Plan Compliance Violations

## Metadata
- **Date**: 2025-11-17
- **Type**: debug-only
- **Target Plan**: /home/benjamin/.config/.claude/specs/23_in_addition_to_committing_changes_after_phases_are/plans/001_build_command_plan_updates_and_continuous_execution.md
- **Complexity**: Low (text-only fixes, no code changes)
- **Estimated Effort**: 30-45 minutes
- **Risk**: Low
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/24_home_benjamin_config_claude_specs_23_in_addition_t/reports/001_plan_compliance_audit.md
- **Standards Files**:
  - /home/benjamin/.config/.claude/docs/concepts/writing-standards.md
  - /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md

## Executive Summary

Fix 6 critical compliance violations in the build command implementation plan: missing Standards File metadata field, missing phase dependency declarations (6 phases), and 3 timeless writing policy violations. All fixes are text-only edits requiring no structural changes.

## Audit Summary

The compliance audit identified 6 critical violations requiring immediate correction:

1. **Missing Standards File metadata** - Plan validation requires this field
2. **Missing phase dependencies** - Blocks wave-based parallel execution (6 phases affected)
3. **Timeless writing violation #1** - "(NEW)" marker at line 274
4. **Timeless writing violation #2** - Historical comparison at line 30
5. **Timeless writing violation #3** - "Backward compatibility" migration language at line 929
6. **Inconsistent metadata field** - "Risk Level" should be "Risk"

**Current Compliance**: 80% (28/35 checks passed)
**Target Compliance**: 100% (35/35 checks passed)

## Debug Strategy

### Priority 1: Critical Metadata Fixes (15 minutes)

#### Fix 1.1: Add Missing Standards File Field

**Location**: Line 10 (metadata section, after Dependencies line)

**Current State**:
```markdown
## Metadata
- **Date**: 2025-11-17
- **Complexity**: 7/10
- **Structure Level**: 0
- **Total Phases**: 6
- **Estimated Effort**: 18-22 hours
- **Risk Level**: Medium
- **Dependencies**: checkbox-utils.sh, spec-updater agent, state-persistence.sh, checkpoint-utils.sh
```

**Fix Action**:
Use Edit tool to add Standards File field and correct Risk Level field name:

```markdown
## Metadata
- **Date**: 2025-11-17
- **Complexity**: 7/10
- **Structure Level**: 0
- **Total Phases**: 6
- **Estimated Effort**: 18-22 hours
- **Risk**: Medium
- **Dependencies**: checkbox-utils.sh, spec-updater agent, state-persistence.sh, checkpoint-utils.sh
- **Standards File**: /home/benjamin/.config/CLAUDE.md
```

**Verification**:
- [ ] Standards File field present
- [ ] Field value is absolute path to CLAUDE.md
- [ ] "Risk Level" renamed to "Risk"

#### Fix 1.2: Add Phase Dependencies to All 6 Phases

**Standard**: Each phase must declare dependencies using format from directory-protocols.md (lines 833-853)

**Phases to Update**:
1. Phase 1 (line 34) - Foundation, no dependencies
2. Phase 2 (line 83) - Depends on Phase 1 (context library)
3. Phase 3 (line 158) - Independent verification, no dependencies
4. Phase 4 (line 250) - Depends on Phases 1, 2, 3 (needs all infrastructure)
5. Phase 5 (line 359) - Depends on Phases 1, 4 (needs context lib and loop)
6. Phase 6 (line 449) - Depends on all previous phases (testing)

**Template for Each Phase** (insert after phase heading):
```markdown
### Phase N: [Phase Name]

**Dependencies**: [list]
**Risk**: Low|Medium|High
**Estimated Time**: X hours
**Objective**: [existing objective text]
```

**Specific Dependencies**:
- Phase 1: `**Dependencies**: []` (foundation)
- Phase 2: `**Dependencies**: [1]` (needs context library)
- Phase 3: `**Dependencies**: []` (independent verification)
- Phase 4: `**Dependencies**: [1, 2, 3]` (needs all infrastructure)
- Phase 5: `**Dependencies**: [1, 4]` (needs context lib and continuous loop)
- Phase 6: `**Dependencies**: [1, 2, 3, 4, 5]` (end-to-end testing needs everything)

**Fix Actions** (6 Edit tool calls):
For each phase heading section, use Edit tool to insert dependency metadata.

**Verification**:
- [ ] All 6 phases have Dependencies field
- [ ] All 6 phases have Risk field
- [ ] All 6 phases have Estimated Time field
- [ ] Dependencies are valid phase numbers (no forward/circular deps)
- [ ] Phase metadata appears before Objective line

---

### Priority 2: Timeless Writing Violations (10 minutes)

#### Fix 2.1: Remove "(NEW)" Marker

**Location**: Line 274

**Current Text**:
```markdown
# Part 3-5: Continuous Execution Loop (NEW)
```

**Fix Action**:
Use Edit tool to remove temporal marker:

```markdown
# Part 3-5: Continuous Execution Loop
```

**Standard Violated**: Writing Standards, Banned Patterns - Temporal Markers (lines 79-105)
**Verification**: [ ] No "(NEW)" marker present in plan

---

#### Fix 2.2: Rewrite Historical Comparison

**Location**: Line 30 (Key Findings section)

**Current Text**:
```markdown
**Key Findings**:
...
6. /implement has continuous execution, /build does not
```

**Fix Action**:
Use Edit tool to convert comparison to current state description:

```markdown
**Key Findings**:
...
6. /build command requires continuous execution capability
```

**Standard Violated**: Writing Standards, Present-Focused Writing (lines 49-57)
**Verification**: [ ] No historical comparison present

---

#### Fix 2.3: Replace Migration Language

**Location**: Line 929 (Implementation Notes section)

**Current Text**:
```markdown
### Backward Compatibility

All changes are backward compatible:
- Existing /build usage patterns unchanged
- Auto-resume still works with 24-hour window
- No breaking changes to plan file formats
- Dry-run mode still supported
```

**Fix Action**:
Use Edit tool to replace with present-focused compatibility statement:

```markdown
### Compatibility

The implementation maintains existing /build behavior:
- Command interface unchanged
- Auto-resume works with 24-hour window
- Plan file formats compatible
- Dry-run mode supported
```

**Standard Violated**: Writing Standards, Banned Patterns - Migration Language (lines 140-166)
**Verification**: [ ] No "backward compatibility" phrase present
**Verification**: [ ] Section describes current state, not migration path

---

### Priority 3: Verification and Validation (5 minutes)

#### Verification Checklist

After all fixes applied, verify compliance:

**Metadata Compliance**:
- [ ] Standards File field present in metadata
- [ ] "Risk" field (not "Risk Level") in metadata
- [ ] All 6 phases have Dependencies field
- [ ] All 6 phases have Risk field
- [ ] All 6 phases have Estimated Time field

**Writing Standards Compliance**:
- [ ] No "(NEW)" markers in plan
- [ ] No historical comparisons in Key Findings
- [ ] No "backward compatibility" language
- [ ] All text describes current state (not past/future)

**Phase Dependencies Compliance**:
- [ ] Phase 1: Dependencies = []
- [ ] Phase 2: Dependencies = [1]
- [ ] Phase 3: Dependencies = []
- [ ] Phase 4: Dependencies = [1, 2, 3]
- [ ] Phase 5: Dependencies = [1, 4]
- [ ] Phase 6: Dependencies = [1, 2, 3, 4, 5]

**Final Validation Commands**:
```bash
# Check Standards File present
grep -q "Standards File.*CLAUDE.md" "$PLAN_FILE"

# Check all phases have Dependencies
PHASES_WITH_DEPS=$(grep -c "^\*\*Dependencies\*\*:" "$PLAN_FILE")
[ "$PHASES_WITH_DEPS" -eq 6 ] || echo "ERROR: Only $PHASES_WITH_DEPS phases have dependencies"

# Check no timeless writing violations
! grep -q "(NEW)" "$PLAN_FILE" || echo "ERROR: Found (NEW) marker"
! grep -q "backward compatible" "$PLAN_FILE" || echo "ERROR: Found migration language"

# Check Risk field (not Risk Level)
grep -q "^\- \*\*Risk\*\*:" "$PLAN_FILE" || echo "ERROR: Risk field not found"
! grep -q "Risk Level" "$PLAN_FILE" || echo "ERROR: Still using 'Risk Level'"
```

---

## Implementation Tasks

Execute fixes in priority order to maximize compliance quickly:

### Phase 1: Metadata Fixes

**Dependencies**: []
**Risk**: Low
**Estimated Time**: 15 minutes

- [ ] Read target plan file to verify current metadata structure
- [ ] Edit metadata section: Add Standards File field after Dependencies
- [ ] Edit metadata section: Change "Risk Level" to "Risk"
- [ ] Edit Phase 1 heading: Add Dependencies, Risk, Estimated Time fields
- [ ] Edit Phase 2 heading: Add Dependencies [1], Risk, Estimated Time fields
- [ ] Edit Phase 3 heading: Add Dependencies [], Risk, Estimated Time fields
- [ ] Edit Phase 4 heading: Add Dependencies [1,2,3], Risk, Estimated Time fields
- [ ] Edit Phase 5 heading: Add Dependencies [1,4], Risk, Estimated Time fields
- [ ] Edit Phase 6 heading: Add Dependencies [1,2,3,4,5], Risk, Estimated Time fields
- [ ] Verify all 6 phases have dependency metadata

### Phase 2: Timeless Writing Fixes

**Dependencies**: []
**Risk**: Low
**Estimated Time**: 10 minutes

- [ ] Edit line 274: Remove "(NEW)" from heading
- [ ] Edit line 30: Replace historical comparison with current state description
- [ ] Edit line 929: Replace "Backward Compatibility" section heading with "Compatibility"
- [ ] Edit line 930-934: Rewrite content to describe current state (not migration)
- [ ] Verify no temporal markers remain
- [ ] Verify no migration language remains

### Phase 3: Validation

**Dependencies**: [1, 2]
**Risk**: Low
**Estimated Time**: 5 minutes

- [ ] Run grep validation commands (see Verification Checklist above)
- [ ] Verify metadata compliance (8/8 fields present)
- [ ] Verify phase dependency compliance (6/6 phases)
- [ ] Verify timeless writing compliance (0 violations)
- [ ] Confirm 100% compliance target achieved

---

## Success Criteria

All criteria must be met for debug completion:

### Critical Fixes (Must Pass)
- [ ] Standards File metadata field added
- [ ] All 6 phases have Dependencies field
- [ ] All 6 phases have Risk field
- [ ] All 6 phases have Estimated Time field
- [ ] "(NEW)" marker removed
- [ ] Historical comparison rewritten
- [ ] "Backward Compatibility" section rewritten
- [ ] "Risk Level" renamed to "Risk"

### Validation (Must Pass)
- [ ] Grep validation shows no temporal markers
- [ ] Grep validation shows no migration language
- [ ] All phase dependencies are valid (no circular/forward deps)
- [ ] Metadata section has 8 required fields
- [ ] Plan compliance score: 100% (35/35 checks)

### Documentation
- [ ] This debug strategy file created at correct path
- [ ] All fixes documented with line numbers
- [ ] Verification commands documented
- [ ] Standards references included

---

## Risk Assessment

### Low Risk: Text-Only Edits

**Probability**: 5%
**Impact**: Low

All fixes are simple text edits with no structural changes. Risk of breaking plan structure is minimal.

**Mitigation**:
- Use Read tool before each Edit to verify context
- Use exact old_string matching to prevent unintended changes
- Verify plan structure unchanged after edits

---

## Testing Strategy

### Pre-Fix Validation
1. Read target plan to confirm violations exist
2. Document exact line numbers and content
3. Verify audit report findings match actual plan state

### Post-Fix Validation
1. Run grep commands to verify no violations remain
2. Count phase dependency declarations (should be 6)
3. Verify metadata completeness (should have 8 fields)
4. Confirm plan structure unchanged (still Level 0, 6 phases)

### Compliance Verification
1. Compare against audit report checklist (section 14)
2. Verify all Priority 1 fixes complete
3. Calculate new compliance score (target: 100%)
4. Document remaining issues (if any)

---

## Expected Outcome

**Before Fixes**:
- Compliance: 80% (28/35 checks)
- Critical violations: 6
- Major issues: 2
- Minor issues: 0

**After Fixes**:
- Compliance: 100% (35/35 checks)
- Critical violations: 0
- Major issues: 0
- Minor issues: 0

**Time Investment**: 30 minutes
**Files Modified**: 1 (target plan only)
**Structural Changes**: None (text-only edits)

---

## Completion Signal

After all fixes applied and verified:

```
DEBUG_COMPLETE: /home/benjamin/.config/.claude/specs/23_in_addition_to_committing_changes_after_phases_are/plans/001_build_command_plan_updates_and_continuous_execution.md

Fixes Applied:
- Added Standards File metadata field
- Added phase dependencies to all 6 phases
- Removed 3 timeless writing violations
- Standardized metadata field naming

Compliance: 100% (35/35 checks passed)
```
