# Checkbox Utils Phase Heading Support Implementation Plan

## Metadata
- **Date**: 2025-12-03
- **Feature**: Add dual heading format support (## Phase and ### Phase) to checkbox-utils.sh with backwards compatibility
- **Status**: [COMPLETE]
- **Estimated Hours**: 3-5 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Checkbox Utils Phase Heading Analysis](../reports/001-checkbox-utils-phase-heading-analysis.md)
- **Complexity Score**: 42
- **Structure Level**: 0 (single file plan)

## Overview

The checkbox-utils.sh library currently hardcodes `### Phase` (h3) heading patterns in AWK scripts and grep commands, causing silent failures when processing plans that use `## Phase` (h2) format. Research shows 5 newer plans use h2 format while 10+ use the standard h3 format. This plan implements dynamic heading level detection to support both formats while maintaining full backwards compatibility.

**Problem Statement**: AWK patterns like `/^### Phase /` and grep patterns like `^### Phase [0-9]` only match h3 headings, silently failing on h2 headings. Functions return success (exit 0) without applying status markers, making diagnosis difficult.

**Solution Approach**: Update all 6 AWK patterns and 3 grep patterns to use `^##+ Phase` regex, which matches both h2 and h3 headings dynamically. Field extraction logic remains unchanged since phase number occupies same field position in both formats.

**Impact**:
- Fixes silent failures in 5 existing plans using h2 format
- Enables flexible heading format for plan-architect agent
- Maintains full backwards compatibility with h3 format plans
- No API changes - all function signatures remain identical

## Implementation Phases

### Phase 1: Core Library Updates [COMPLETE]
dependencies: []

**Objective**: Update all hardcoded heading patterns in checkbox-utils.sh to support both h2 and h3 formats

**Complexity**: Medium (6 AWK patterns + 3 grep patterns requiring careful regex updates)

**Tasks**:
- [x] Update AWK pattern in `mark_phase_complete()` line 204 from `/^### Phase /` to `/^##+ Phase /`
- [x] Update AWK pattern in `mark_phase_complete()` line 249 from `/^### Phase /` to `/^##+ Phase /`
- [x] Update AWK pattern in `remove_status_marker()` line 420 from `/^### Phase /` to `/^##+ Phase /`
- [x] Update AWK pattern in `add_in_progress_marker()` line 454 from `/^### Phase /` to `/^##+ Phase /`
- [x] Update AWK pattern in `add_complete_marker()` line 493 from `/^### Phase /` to `/^##+ Phase /`
- [x] Update AWK pattern in `verify_phase_complete()` line 564 from `/^### Phase /` to `/^##+ Phase /`
- [x] Update AWK pattern in `add_not_started_markers()` line 523 from `/^### Phase [0-9]+:/` to `/^##+ Phase [0-9]+:/`
- [x] Update grep pattern in `add_not_started_markers()` line 538 from `^### Phase` to `^##+ Phase`
- [x] Update grep pattern in `check_all_phases_complete()` line 665 from `^### Phase [0-9]` to `^##+ Phase [0-9]`
- [x] Update grep pattern in `check_all_phases_complete()` line 673 from `^### Phase [0-9].*\[COMPLETE\]` to `^##+ Phase [0-9].*\[COMPLETE\]`
- [x] Verify field extraction logic still works (phase number is always $3 for both h2 and h3)
- [x] Source library and run shellcheck validation

**Success Criteria**:
- All 9 pattern locations updated to use `^##+ Phase` regex
- Field extraction (`$3` for phase number) remains functional
- No AWK syntax errors introduced
- Shellcheck passes with no new warnings
- Library sources without errors

**Artifacts**:
- Modified: `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh`

### Phase 2: Test Suite Enhancement [COMPLETE]
dependencies: [1]

**Objective**: Add comprehensive test coverage for both h2 and h3 heading formats with backwards compatibility validation

**Complexity**: Medium (requires test fixtures for both formats and mixed scenarios)

**Tasks**:
- [x] Create test fixture with h2 format plan (`test_plan_h2.md`) in `test_plan_progress_markers.sh`
- [x] Create test fixture with h3 format plan (`test_plan_h3.md`) in `test_plan_progress_markers.sh`
- [x] Add test case: "Verify add_in_progress_marker works with ## Phase format"
- [x] Add test case: "Verify add_complete_marker works with ## Phase format"
- [x] Add test case: "Verify add_not_started_markers works with ## Phase format"
- [x] Add test case: "Verify mark_phase_complete works with ## Phase format"
- [x] Add test case: "Verify verify_phase_complete works with ## Phase format"
- [x] Add test case: "Verify check_all_phases_complete works with ## Phase format"
- [x] Add test case: "Verify backwards compatibility - all functions work with ### Phase format"
- [x] Add test case: "Verify grep patterns count phases correctly for both formats"
- [x] Update `test_implement_progress_tracking.sh` to test with h2 format plan
- [x] Run full test suite and verify all tests pass

**Success Criteria**:
- New test cases added for all 6 primary functions (add_in_progress_marker, add_complete_marker, add_not_started_markers, mark_phase_complete, verify_phase_complete, check_all_phases_complete)
- Backwards compatibility verified with h3 format tests
- All existing tests continue to pass (no regressions)
- Test coverage for both formats documented in test output
- Integration tests pass with h2 format plans

**Artifacts**:
- Modified: `/home/benjamin/.config/.claude/tests/progressive/test_plan_progress_markers.sh`
- Modified: `/home/benjamin/.config/.claude/tests/integration/test_implement_progress_tracking.sh`

### Phase 3: Documentation Updates [COMPLETE]
dependencies: [2]

**Objective**: Update all documentation to reflect dual heading format support and clarify format flexibility

**Complexity**: Low (documentation updates with clear examples)

**Tasks**:
- [x] Update `/home/benjamin/.config/.claude/docs/reference/standards/plan-progress.md` to document both h2 and h3 support
- [x] Add examples showing both `## Phase` and `### Phase` formats in plan-progress.md
- [x] Clarify that heading level is flexible (h2 or h3) in plan-progress.md
- [x] Update `/home/benjamin/.config/.claude/lib/plan/README.md` to document heading level flexibility
- [x] Add usage examples for both formats in library README
- [x] Update function documentation in checkbox-utils.sh header comments to mention dual format support
- [x] Document that `^##+ Phase` regex matches both h2 and h3 headings dynamically
- [x] Add troubleshooting note for mixed-format plans (not recommended but supported)

**Success Criteria**:
- plan-progress.md updated with dual format documentation
- Library README includes examples for both formats
- Function header comments clarified
- No historical commentary added (clean-break development standard)
- Documentation follows documentation standards (no emoji, UTF-8 only, CommonMark spec)

**Artifacts**:
- Modified: `/home/benjamin/.config/.claude/docs/reference/standards/plan-progress.md`
- Modified: `/home/benjamin/.config/.claude/lib/plan/README.md`
- Modified: `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh` (header comments)

### Phase 4: Integration Validation [COMPLETE]
dependencies: [3]

**Objective**: Validate changes work correctly with real plans and all consumer commands/agents

**Complexity**: Low (manual validation with existing plans)

**Tasks**:
- [x] Test checkbox-utils.sh functions on existing h2 format plan (spec 026)
- [x] Test checkbox-utils.sh functions on existing h3 format plan (spec 999)
- [x] Verify implementation-executor agent works with h2 format plans
- [x] Verify spec-updater agent works with h2 format plans
- [x] Run `/implement` command on h2 format test plan and verify progress markers update correctly
- [x] Run `/build` command on h2 format test plan and verify all phases marked complete
- [x] Verify no regressions with h3 format plans (test with legacy plan)
- [x] Check error handling - ensure no silent failures on malformed headings
- [x] Run all integration tests in `.claude/tests/integration/` directory
- [x] Verify plan-architect agent continues to create h3 format by default (no changes needed)

**Success Criteria**:
- All 5 existing h2 format plans process correctly
- All 10+ existing h3 format plans process correctly (no regressions)
- implementation-executor and spec-updater agents work with both formats
- /implement and /build commands work with both formats
- All integration tests pass
- No silent failures observed
- Error handling graceful for malformed headings

**Artifacts**:
- Test output logs showing successful validation
- Confirmation that both formats work in production

## Testing Strategy

### Unit Tests
**Location**: `/home/benjamin/.config/.claude/tests/progressive/test_plan_progress_markers.sh`

**Scope**: Test all checkbox-utils.sh functions with both h2 and h3 format fixtures

**Test Cases**:
1. **H2 Format Support**:
   - `add_in_progress_marker()` updates `## Phase 1` correctly
   - `add_complete_marker()` updates `## Phase 1` correctly
   - `add_not_started_markers()` adds markers to `## Phase` headings
   - `mark_phase_complete()` marks all tasks in h2 phase
   - `verify_phase_complete()` validates h2 phase completion
   - `check_all_phases_complete()` counts h2 phases correctly

2. **H3 Format Backwards Compatibility**:
   - All functions continue to work with `### Phase` headings
   - No regressions in existing behavior
   - Field extraction logic unchanged

3. **Edge Cases**:
   - Mixed h2/h3 format in same plan (not recommended but should work)
   - Malformed headings (e.g., `# Phase` or `#### Phase`)
   - Missing status markers
   - Duplicate status markers

**Fixtures**:
```markdown
# test_plan_h2.md
## Phase 1: Setup [COMPLETE]
- [x] Task 1
- [x] Task 2

## Phase 2: Implementation [COMPLETE]
- [x] Task 3

# test_plan_h3.md
### Phase 1: Setup [COMPLETE]
- [x] Task 1
- [x] Task 2

### Phase 2: Implementation [COMPLETE]
- [x] Task 3
```

### Integration Tests
**Location**: `/home/benjamin/.config/.claude/tests/integration/test_implement_progress_tracking.sh`

**Scope**: Test end-to-end workflows with both heading formats

**Test Cases**:
1. Create h2 format plan and run `/implement` - verify markers update
2. Create h3 format plan and run `/implement` - verify no regressions
3. Test plan hierarchy updates with h2 format
4. Test spec-updater agent with h2 format plans

### Manual Validation Tests
**Location**: Existing production plans

**Test Plans**:
- H2 Format: `/home/benjamin/.config/.claude/specs/026_lean_command_orchestrator_implementation/plans/001-lean-command-orchestrator-implementation-plan.md`
- H3 Format: `/home/benjamin/.config/.claude/specs/999_build_implement_persistence/plans/001-build-implement-persistence-plan.md`

**Validation Steps**:
1. Source checkbox-utils.sh
2. Call each function on both test plans
3. Verify status markers applied correctly
4. Verify no silent failures
5. Check error messages for invalid input

## Technical Design

### Pattern Matching Approach

**Current Pattern** (H3 only):
```awk
/^### Phase / {
  phase_field = $3
  gsub(/:/, "", phase_field)
  # Process phase...
}
```

**Updated Pattern** (H2 and H3):
```awk
/^##+ Phase / {
  phase_field = $3
  gsub(/:/, "", phase_field)
  # Process phase...
}
```

**Regex Explanation**:
- `^##+` matches 2 or more `#` characters at line start
- Matches both `## Phase` (h2) and `### Phase` (h3)
- Future-proof for h4+ if ever needed
- Same field position ($3) for phase number in both formats

### Field Extraction Logic

**Both formats have identical field positions**:
```
## Phase 1: Setup [COMPLETE]
   $1    $2  $3
   ##    Phase  1:

### Phase 1: Setup [COMPLETE]
    $1     $2  $3
    ###    Phase  1:
```

Therefore, existing field extraction logic (`$3` for phase number) requires no changes.

### Grep Pattern Updates

**Current Pattern**:
```bash
grep -c "^### Phase [0-9]" "$plan_path"
```

**Updated Pattern**:
```bash
grep -c "^##+ Phase [0-9]" "$plan_path"
```

Note: `grep -E` (extended regex) may be required for `+` quantifier. Alternative: use `^## Phase [0-9]` or `^### Phase [0-9]` (both) with multiple grep calls if basic regex doesn't support `+`.

**Recommended Approach**: Use `grep -E` for extended regex support:
```bash
grep -E -c "^##+ Phase [0-9]" "$plan_path"
```

### Error Handling

**Current Behavior**: Functions silently succeed (exit 0) when patterns don't match, leaving plans unchanged.

**Improved Behavior** (out of scope for this plan):
- Same behavior maintained (backwards compatible)
- Future enhancement could add warnings for unmatched patterns
- Error handling improvements tracked separately

### Standards Compliance

This implementation aligns with all project standards:

1. **Code Standards**:
   - Three-tier sourcing pattern: checkbox-utils.sh sources base-utils.sh and plan-core-bundle.sh (Tier 2)
   - Clean-break development: No compatibility wrappers, unified implementation
   - Shellcheck validation required

2. **Testing Protocols**:
   - Unit tests in `tests/progressive/`
   - Integration tests in `tests/integration/`
   - Manual validation with production plans
   - Backwards compatibility validation

3. **Documentation Policy**:
   - Update standards documentation (plan-progress.md)
   - Update library README
   - No historical commentary
   - UTF-8 only, no emoji

4. **Clean-Break Development**:
   - No deprecation period needed (internal library change)
   - Unified implementation (single regex pattern for both formats)
   - Delete old pattern, replace with new pattern atomically

## Risk Assessment

### Low Risk
- **Field extraction unchanged**: Phase number field position identical for both formats
- **Regex well-tested**: `##+` is standard regex, widely supported
- **No API changes**: All function signatures remain identical
- **Backwards compatible**: Existing h3 plans unaffected

### Medium Risk
- **Grep extended regex**: May need `-E` flag for `+` quantifier (easily tested)
- **AWK compatibility**: `##+` should work in all AWK implementations (verify with testing)
- **Edge cases**: Mixed h2/h3 format in same plan (unusual but should work)

### Mitigation Strategies
- Comprehensive test suite with both formats
- Manual validation on production plans
- Shellcheck validation before deployment
- Integration test suite validation
- Rollback plan: Revert to original patterns if failures detected

## Dependencies

### External Dependencies
- None (internal library change only)

### Internal Dependencies
- `base-utils.sh` (already sourced by checkbox-utils.sh)
- `plan-core-bundle.sh` (already sourced by checkbox-utils.sh)
- AWK (standard Unix utility)
- grep with extended regex support (standard on Linux/macOS)

### Consumer Impact
- **implementation-executor agent**: No changes required, benefits from fix
- **spec-updater agent**: No changes required, benefits from fix
- **Plan-architect agent**: No changes required (continues creating h3 format)
- **/implement command**: No changes required
- **/build command**: No changes required

All consumers benefit from fix without requiring updates.

## Completion Criteria

### Phase 1 Complete [COMPLETE]
- [x] All 9 pattern locations updated to `^##+ Phase`
- [x] Shellcheck validation passes
- [x] Library sources without errors
- [x] Field extraction verified functional

### Phase 2 Complete [COMPLETE]
- [x] Test fixtures created for both h2 and h3 formats
- [x] 10+ new test cases added covering all functions
- [x] All tests pass (no regressions)
- [x] Integration tests updated and passing

### Phase 3 Complete [COMPLETE]
- [x] plan-progress.md updated with dual format documentation
- [x] Library README updated with examples
- [x] Function header comments updated
- [x] Documentation follows standards (no emoji, UTF-8, CommonMark)

### Phase 4 Complete [COMPLETE]
- [x] Manual validation successful on 5+ h2 plans
- [x] Manual validation successful on 10+ h3 plans (no regressions)
- [x] implementation-executor and spec-updater agents validated
- [x] /implement and /build commands validated with both formats
- [x] All integration tests pass
- [x] No silent failures observed in production testing

### Plan Complete
- All phases marked [COMPLETE]
- All 42 tasks completed
- All tests passing
- Documentation updated
- No regressions detected
- Both h2 and h3 formats fully supported in production
