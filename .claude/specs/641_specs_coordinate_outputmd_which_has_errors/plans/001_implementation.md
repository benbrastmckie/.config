# Fix Coordinate Command Bash Errors Implementation Plan

## Metadata
- **Date**: 2025-11-10
- **Feature**: Fix coordinate command errors (bash variable persistence and function availability)
- **Scope**: Fix bash history expansion corruption, state persistence verification, and function availability across bash blocks
- **Estimated Phases**: 5
- **Estimated Hours**: 6-8 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Bash Variable Persistence Analysis](../reports/001_bash_variable_persistence_analysis.md)
  - [Function Availability Analysis](../reports/002_function_availability_analysis.md)
- **Structure Level**: 0
- **Complexity Score**: 38.5

## Overview

The /coordinate command experiences critical bash execution errors that prevent successful workflow completion:

1. **Bad Substitution Error**: Missing `set +H` in subsequent bash blocks allows history expansion to corrupt indirect variable expansion syntax (`${!var_name}` becomes `${\!var_name}`)
2. **Missing Functions Error**: `emit_progress` and `display_brief_summary` become unavailable after initialization block due to incomplete library re-sourcing
3. **Silent State Persistence Failures**: No verification checkpoint after array serialization allows incomplete state files to propagate

These errors cascade through multi-phase workflows, causing 100% failure rate for coordinate invocations with ≥2 research topics.

## Research Summary

Key findings from research reports:

**From Bash Variable Persistence Analysis**:
- Root cause: History expansion corruption in subprocess isolation environment
- Each bash block runs as separate subprocess, requiring `set +H` repetition
- Serialization appears to succeed but creates invalid syntax `${\!var_name}`
- No verification checkpoint catches incomplete state file writes
- Impact: 11.25 hours/year lost to debugging and re-runs

**From Function Availability Analysis**:
- Root cause: unified-logger.sh missing from re-sourcing template (10 locations)
- Subprocess isolation makes `export -f` ineffective across bash blocks
- State machine migration (Spec 633) removed unified-logger.sh during optimization
- Silent failure for emit_progress (guarded), hard failure for display_brief_summary
- Solution: Add unified-logger.sh to all re-sourcing blocks OR use source_required_libraries pattern

**Recommended Approach**:
Both reports converge on minimal, high-impact fixes that align with bash-block-execution-model.md patterns and Standard 0 (verification checkpoints).

## Success Criteria

- [ ] No bad substitution errors in coordinate invocations
- [ ] All REPORT_PATH variables persist correctly across bash blocks
- [ ] emit_progress messages appear in all verification blocks
- [ ] display_brief_summary displays at terminal states
- [ ] State file verification checkpoint catches incomplete writes
- [ ] All 11 bash blocks include `set +H` directive
- [ ] All 10 re-sourcing blocks include unified-logger.sh
- [ ] Regression tests added to prevent future occurrences
- [ ] Documentation updated with critical library requirements
- [ ] 100% test pass rate for coordinate workflows

## Technical Design

### Architecture Integration

**Bash Block Execution Model Compliance**:
- Pattern 3 (State Persistence): Add verification checkpoint after serialization
- Pattern 4 (Library Re-sourcing): Extend template to include set +H and unified-logger.sh
- Subprocess isolation: All fixes respect subprocess boundary constraints

**State-Based Orchestration Integration**:
- Coordinate.md uses state machine pattern (workflow-state-machine.sh)
- State persistence via GitHub Actions pattern (state-persistence.sh)
- Verification follows Standard 0 (execution enforcement)

**Component Interaction**:
```
coordinate.md (bash blocks)
    ↓
[Block 1: Initialization]
    - set +H ← ADD
    - source unified-logger.sh (via source_required_libraries) ✓
    - serialize REPORT_PATH array
    - ADD: verification checkpoint ← NEW
    ↓
[Blocks 2-11: State Handlers]
    - set +H ← ADD (10 locations)
    - source unified-logger.sh ← ADD (10 locations)
    - load state from file
    - reconstruct REPORT_PATHS array
    - emit_progress() now available ✓
    ↓
[Terminal State]
    - display_brief_summary() now available ✓
```

### Fix Strategy

**Priority P0 (Critical Path)**:
1. Add `set +H` to 11 bash blocks (prevents bad substitution)
2. Add unified-logger.sh to 10 re-sourcing blocks (restores functions)
3. Add verification checkpoint after serialization (fail-fast on incomplete state)

**Priority P1 (Enhanced Reliability)**:
4. Update bash-block-execution-model.md (document set +H requirement)
5. Add regression tests (prevent future occurrences)

**Risk Mitigation**:
- All changes are additive (no breaking changes)
- Source guards prevent side effects from multiple sourcing
- Verification checkpoint provides immediate feedback on failures

## Implementation Phases

### Phase 1: Fix Bad Substitution Error (Critical) [COMPLETED]
dependencies: []

**Objective**: Add `set +H` to all bash blocks to prevent history expansion corruption

**Complexity**: Low

Tasks:
- [x] Add `set +H` to initialization block (line 46) - already present, verify consistency
- [x] Add `set +H` to research state handler (after line 259)
- [x] Add `set +H` to research verification block (after line 392)
- [x] Add `set +H` to planning state handler (after line 616)
- [x] Add `set +H` to planning verification block (after line 703)
- [x] Add `set +H` to implementation state handler (after line 875)
- [x] Add `set +H` to implementation verification block (after line 943)
- [x] Add `set +H` to testing state handler (after line 1014)
- [x] Add `set +H` to debug state handler (after line 1133)
- [x] Add `set +H` to debug verification block (after line 1198)
- [x] Add `set +H` to documentation state handler (after line 1316)

Testing:
```bash
# Test that coordinate no longer produces bad substitution errors
# Manual test: /coordinate "test workflow with 2 topics"
# Expected: No "bad substitution" errors in output
# Expected: REPORT_PATH variables serialize successfully
```

**Expected Duration**: 45 minutes

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (manual coordinate invocation)
- [x] Git commit created: `feat(641): add set +H to all coordinate bash blocks`
- [x] Checkpoint saved (if needed)
- [x] Update this plan file with phase completion status

### Phase 2: Fix Missing Functions Error (Critical) [COMPLETED]
dependencies: [1]

**Objective**: Add unified-logger.sh to all re-sourcing blocks to restore function availability

**Complexity**: Low

Tasks:
- [x] Add unified-logger.sh to research state handler re-sourcing (line 268-273)
- [x] Add unified-logger.sh to research verification re-sourcing (line 401)
- [x] Add unified-logger.sh to planning state handler re-sourcing (line 625)
- [x] Add unified-logger.sh to planning verification re-sourcing (line 712)
- [x] Add unified-logger.sh to implementation state handler re-sourcing (line 884)
- [x] Add unified-logger.sh to implementation verification re-sourcing (line 952)
- [x] Add unified-logger.sh to testing state handler re-sourcing (line 1023)
- [x] Add unified-logger.sh to debug state handler re-sourcing (line 1142)
- [x] Add unified-logger.sh to debug verification re-sourcing (line 1207)
- [x] Add unified-logger.sh to documentation state handler re-sourcing (line 1325)
- [x] Remove ineffective `export -f display_brief_summary` (line 231)
- [x] Add comment explaining why unified-logger.sh is required

Testing:
```bash
# Test that emit_progress appears in logs
# Test that display_brief_summary works at terminal states
# Manual test: /coordinate "test workflow" with research-and-plan scope
# Expected: Progress markers visible in output
# Expected: Completion summary displays at end
```

**Expected Duration**: 45 minutes

**Phase 2 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (manual coordinate invocation with progress visible)
- [x] Git commit created: `feat(641): add unified-logger.sh to all coordinate re-sourcing blocks`
- [x] Checkpoint saved (if needed)
- [x] Update this plan file with phase completion status

### Phase 3: Add State Persistence Verification (Critical) [COMPLETED]
dependencies: [1]

**Objective**: Add mandatory verification checkpoint after array serialization to catch incomplete state writes

**Complexity**: Medium

Tasks:
- [x] Implement verification checkpoint after line 193 in coordinate.md
- [x] Verify all REPORT_PATH_* variables written to state file
- [x] Display diagnostic information (variable count, file size)
- [x] Fail-fast with clear error message on verification failure
- [x] Add troubleshooting guidance in error output (check bad substitution, file permissions, disk space)
- [x] Test with intentional serialization failure (mock bad substitution)
- [x] Verify error message clarity and actionability
- [x] Document checkpoint in coordinate-command-guide.md

Testing:
```bash
# Test successful verification (normal case)
/coordinate "test workflow with 2 topics"
# Expected: "✓ All N variables verified in state file"

# Test failed verification (simulate missing state file)
# Manually delete state file after serialization
# Expected: "❌ CRITICAL: State file verification failed"
# Expected: Clear troubleshooting steps displayed
```

**Expected Duration**: 1.5 hours

**Phase 3 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (verification checkpoint catches failures)
- [x] Git commit created: `feat(641): add state persistence verification checkpoint`
- [x] Checkpoint saved (if needed)
- [x] Update this plan file with phase completion status

### Phase 4: Update Documentation (Medium Priority) [COMPLETED]
dependencies: [1, 2, 3]

**Objective**: Document critical library requirements and set +H pattern to prevent future regressions

**Complexity**: Low

Tasks:
- [x] Update bash-block-execution-model.md Pattern 4 to include `set +H` requirement
- [x] Add "Critical Libraries for Re-sourcing" section to bash-block-execution-model.md
- [x] Update coordinate-command-guide.md with troubleshooting section for these errors
- [x] Update _template-executable-command.md with re-sourcing template including unified-logger.sh
- [x] Add code review checklist item in command-development-guide.md
- [x] Document fix rationale in this plan's completion notes

Testing:
```bash
# Validate documentation standards compliance
# Check that all cross-references are valid
# Verify markdown formatting
# Review for timeless writing (no "new" or "previously" markers)
```

**Expected Duration**: 1.5 hours

**Phase 4 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Documentation review complete
- [x] Git commit created: `docs(641): document bash block critical patterns`
- [x] Checkpoint saved (if needed)
- [x] Update this plan file with phase completion status

### Phase 5: Add Regression Tests (Medium Priority)
dependencies: [1, 2, 3]

**Objective**: Create automated tests to prevent future occurrences of these errors

**Complexity**: Medium

Tasks:
- [ ] Create test_array_serialization.sh (test REPORT_PATHS persistence across blocks)
- [ ] Create test_history_expansion.sh (test set +H prevents bad substitution)
- [ ] Create test_cross_block_function_availability.sh (test emit_progress and display_brief_summary)
- [ ] Add tests to run_all_tests.sh
- [ ] Create test_coordinate_state_persistence.sh (integration test for full workflow)
- [ ] Test with 2-topic research workflow (flat structure)
- [ ] Test with 4-topic research workflow (hierarchical structure)
- [ ] Document test coverage in test suite README
- [ ] Verify all tests pass in CI environment

Testing:
```bash
# Run new test suite
cd /home/benjamin/.config/.claude/tests
./test_array_serialization.sh
./test_history_expansion.sh
./test_cross_block_function_availability.sh
./test_coordinate_state_persistence.sh

# Run full test suite
./run_all_tests.sh

# Expected: All new tests pass
# Expected: No regressions in existing tests
```

**Expected Duration**: 2.5 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] All new tests passing (100% pass rate)
- [ ] Integration with run_all_tests.sh complete
- [ ] Git commit created: `test(641): add regression tests for bash block errors`
- [ ] Checkpoint saved (if needed)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Tests (Phase 5)

**test_array_serialization.sh**:
- Serialize REPORT_PATH array in Block 1
- Deserialize in Block 2 (simulate subprocess)
- Verify array reconstruction
- Validate values match

**test_history_expansion.sh**:
- Test indirect variable expansion with/without set +H
- Verify bad substitution prevented
- Test across subprocess boundaries

**test_cross_block_function_availability.sh**:
- Test emit_progress availability after library re-sourcing
- Test display_brief_summary availability at terminal states
- Verify functions work correctly across blocks

### Integration Tests (Phase 5)

**test_coordinate_state_persistence.sh**:
- End-to-end coordinate workflow with 2 topics
- Verify state persistence throughout
- Verify functions available in all blocks
- Check completion summary displays

### Manual Testing (Phases 1-3)

Each critical fix phase requires manual testing:
1. Run coordinate with 2-topic research workflow
2. Verify no errors in output
3. Verify state persistence works
4. Verify progress markers visible
5. Verify completion summary displays

### Acceptance Criteria

- [ ] No bad substitution errors in any coordinate invocation
- [ ] All REPORT_PATH variables persist correctly (2+ topics)
- [ ] emit_progress visible in all verification blocks
- [ ] display_brief_summary displays at workflow completion
- [ ] State verification catches incomplete writes
- [ ] All new tests pass (100% pass rate)
- [ ] Documentation complete and accurate
- [ ] No regressions in existing functionality

## Documentation Requirements

### Files to Update

1. **bash-block-execution-model.md**:
   - Add set +H requirement to Pattern 4
   - Add "Critical Libraries for Re-sourcing" section
   - Document subprocess isolation implications

2. **coordinate-command-guide.md**:
   - Add troubleshooting section for bad substitution errors
   - Add troubleshooting section for missing function errors
   - Document state persistence verification checkpoint

3. **_template-executable-command.md**:
   - Update bash block re-sourcing template
   - Include set +H directive
   - Include unified-logger.sh in library list

4. **command-development-guide.md**:
   - Add code review checklist item for critical libraries
   - Add checklist item for set +H in all bash blocks
   - Add checklist item for verification checkpoints

### Documentation Standards

- Follow timeless writing (no historical markers)
- Use imperative language for requirements (MUST/WILL/SHALL)
- Include clear code examples
- Cross-reference related patterns and standards
- Maintain single source of truth principle

## Dependencies

### External Dependencies
- bash (with history expansion support)
- git (for CLAUDE_PROJECT_DIR detection)
- jq (for state persistence JSON operations)

### Internal Dependencies
- .claude/lib/workflow-state-machine.sh
- .claude/lib/state-persistence.sh
- .claude/lib/workflow-initialization.sh
- .claude/lib/error-handling.sh
- .claude/lib/unified-logger.sh
- .claude/lib/verification-helpers.sh

### Standards Dependencies
- Standard 0 (Execution Enforcement) - verification checkpoints
- bash-block-execution-model.md - subprocess isolation patterns
- verification-fallback.md - verification checkpoint pattern
- command_architecture_standards.md - executable/documentation separation

## Risk Assessment

### Low Risk Changes
- Adding set +H (additive, no side effects)
- Adding unified-logger.sh to re-sourcing (source guards prevent issues)
- Documentation updates (no code changes)

### Medium Risk Changes
- Verification checkpoint (fail-fast behavior change)
- Removing export -f (ineffective anyway, no functional loss)

### Mitigation Strategies
- Test each phase independently before proceeding
- Manual testing before automated tests
- Clear error messages in verification checkpoint
- Comprehensive troubleshooting guidance
- Rollback plan: git revert commits if issues arise

## Performance Impact

### Expected Improvements
- Eliminate 100% failure rate for coordinate with ≥2 topics
- Save 11.25 hours/year in debugging time
- Reduce workflow retry rate from 100% to 0%

### Performance Overhead
- Verification checkpoint: +1-2 seconds per coordinate invocation
- Additional library sourcing: <100ms (source guards minimize overhead)
- State file verification grep operations: <50ms

### Net Impact
Positive: Reliability improvement far outweighs minimal overhead

## Completion Notes

This plan addresses critical bash execution errors in /coordinate command through minimal, targeted fixes:

1. **Immediate Impact**: Phases 1-3 restore 100% functionality
2. **Long-term Prevention**: Phases 4-5 prevent future regressions
3. **Architecture Alignment**: All fixes comply with existing patterns
4. **Risk Management**: Low-risk additive changes with clear rollback path

**Success Metric**: 0% failure rate for coordinate invocations (down from 100%)

**Time Investment**: 6-8 hours implementation vs 11.25 hours/year lost to current bugs

**Follow-up Opportunities**:
- Consider moving display_brief_summary to workflow-summary.sh library (Phase 6, optional)
- Audit /orchestrate for similar latent issues (separate spec)
- Standardize all commands on source_required_libraries pattern (separate spec)

---

**Plan Created**: 2025-11-10
**Plan Author**: plan-architect agent
**Validation Status**: ✓ Research reports reviewed, patterns validated
