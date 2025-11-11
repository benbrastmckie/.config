# Coordinate Revision Workflow Fixes Implementation Plan

## Metadata
- **Date**: 2025-11-11
- **Feature**: Fix coordinate command revision workflow issues
- **Scope**: Minimal targeted fixes for revision detection, path discovery, and verification
- **Estimated Phases**: 3
- **Estimated Hours**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 47.0
- **Research Reports**:
  - [Coordinate Command Outputs Analysis](../reports/001_coordinate_command_outputs_analysis.md)
  - [Coordinate Revise Outputs Analysis](../reports/002_coordinate_revise_outputs_analysis.md)
  - [Infrastructure Standards Compatibility](../reports/003_infrastructure_standards_compatibility.md)

## Overview

Fix three critical issues blocking coordinate revision workflows: (1) workflow scope detection misidentification (research-and-plan vs research-and-revise), (2) report path mismatches between pre-calculated and agent-created paths, and (3) bash syntax errors in verification commands. Implementation focuses on minimal changes to workflow-scope-detection.sh and coordinate.md verification logic, maintaining 100% compatibility with existing infrastructure.

## Research Summary

Key findings from research reports:
- **Scope Detection Gap**: Pattern requires "research|analyze" prefix but revision workflows start with "Revise" (Report 002:113-129)
- **Path Discovery Timing**: Dynamic report discovery runs AFTER verification instead of BEFORE (Report 001:276-295)
- **Bash Syntax Issues**: Complex multiline conditionals with variable substitution fail eval preprocessing (Report 001:228-244)
- **Infrastructure Compliance**: 98.8% standards compliance, no major conflicts or redundancies (Report 003:567)
- **Verification Pattern**: Filesystem fallback pattern available but not applied to revision checkpoints (Report 003:82-103)

Recommended approach: Expand scope detection regex, reorder dynamic discovery before verification, simplify bash command construction using state files.

## Success Criteria

- [ ] Revision workflows correctly detected as "research-and-revise" scope (not "research-and-plan")
- [ ] Dynamic report path discovery executes before verification checkpoints
- [ ] Report path mismatches resolved (topic directory calculations correct)
- [ ] Bash syntax errors eliminated in verification blocks
- [ ] All existing coordinate tests pass (zero regression)
- [ ] Revision workflow integration test added and passing

## Technical Design

### Architecture Decisions

1. **Scope Detection Enhancement**: Expand regex pattern in workflow-scope-detection.sh to recognize "Revise X to Y" patterns (line 38)
2. **Discovery Reordering**: Move dynamic path discovery from coordinate.md:342-362 to execute immediately after research completion, before verification
3. **Bash Simplification**: Replace complex variable substitution with state file pattern for cross-block variable passing
4. **Verification Strengthening**: Apply filesystem fallback pattern from coordinate-state-management.md to revision checkpoints

### Component Interactions

```
User Input: "/coordinate 'Revise plan X to accommodate Y'"
    ↓
workflow-scope-detection.sh:detect_workflow_scope()
    ├→ Enhanced regex recognizes revision pattern
    ├→ Returns: scope="research-and-revise"
    └→ Sets: EXISTING_PLAN_PATH from description
         ↓
coordinate.md:Phase 0 (Initialization)
    ├→ Uses existing plan's topic directory
    ├→ Pre-calculates report paths: 001_topic1.md, 002_topic2.md
    └→ Creates workflow state
         ↓
coordinate.md:Research Phase
    ├→ Invokes 2 research-specialist agents (parallel)
    ├→ Agents create: 001_descriptive_name.md, 002_other_name.md
    └→ Research completes
         ↓
coordinate.md:Dynamic Path Discovery (MOVED BEFORE VERIFICATION)
    ├→ Scans topic/reports/ directory
    ├→ Finds: 001_descriptive_name.md, 002_other_name.md
    ├→ Updates: REPORT_PATHS array with actual filenames
    └→ Saves to workflow state file
         ↓
coordinate.md:Verification Checkpoint (NEW LOCATION)
    ├→ Loads REPORT_PATHS from workflow state
    ├→ Verifies files at discovered paths (SUCCESS)
    └→ Proceeds to revision phase
         ↓
coordinate.md:Revision Phase (scope="research-and-revise")
    ├→ Invokes revision-specialist agent
    ├→ Agent creates backup, modifies plan
    └→ Revision completes
         ↓
coordinate.md:Revision Verification (SIMPLIFIED)
    ├→ Uses state file for BACKUP_PATH persistence
    ├→ Simple diff command (no complex conditionals)
    └→ Reports completion
```

### Integration Points

- **workflow-scope-detection.sh**: Expand regex pattern (1 line change)
- **coordinate.md**: Reorder discovery/verification (block movement, ~50 lines)
- **coordinate.md**: Simplify bash verification (replace 15 lines with 5)
- **state-persistence.sh**: No changes (existing API sufficient)
- **verification-helpers.sh**: Optional enhancement (filesystem fallback function)

## Implementation Phases

### Phase 1: Fix Workflow Scope Detection
dependencies: []

**Objective**: Expand workflow-scope-detection.sh pattern to recognize "Revise X to Y" revision workflows

**Complexity**: Low

**Tasks**:
- [x] Read current pattern in workflow-scope-detection.sh:38-40 (file: /home/benjamin/.config/.claude/lib/workflow-scope-detection.sh)
- [x] Expand regex to recognize revision-first patterns: `(revise|update|modify).*(plan|implementation).*(accommodate|based on|using)` (file: workflow-scope-detection.sh:39)
- [x] Add filesystem-based fallback: when "revise" + path detected, extract topic from existing plan path (file: workflow-scope-detection.sh:41-50)
- [x] Add debug logging for pattern match diagnostics (optional, file: workflow-scope-detection.sh:51-55)

**Testing**:
```bash
# Test revision pattern recognition
source .claude/lib/workflow-scope-detection.sh
result=$(detect_workflow_scope "Revise /path/to/plan.md to accommodate new requirements")
[ "$result" = "research-and-revise" ] || echo "FAIL: Expected research-and-revise, got $result"

# Test existing patterns still work
result=$(detect_workflow_scope "Research auth patterns and create implementation plan")
[ "$result" = "research-and-plan" ] || echo "FAIL: Regression on research-and-plan"
```

**Expected Duration**: 2 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(661): complete Phase 1 - Fix Workflow Scope Detection`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Reorder Dynamic Path Discovery Before Verification
dependencies: [1]

**Objective**: Move dynamic report path discovery to execute before verification checkpoints, ensuring REPORT_PATHS contains actual agent-created filenames

**Complexity**: Medium

**Tasks**:
- [ ] Identify dynamic discovery block location in coordinate.md (currently lines ~342-362) (file: /home/benjamin/.config/.claude/commands/coordinate.md)
- [ ] Identify verification checkpoint locations (research phase: ~489 hierarchical, ~550 flat) (file: coordinate.md)
- [ ] Move discovery block to execute immediately after research agent invocations complete (file: coordinate.md:342-362 → new location before line 489)
- [ ] Update workflow state persistence: save discovered REPORT_PATHS array to state file (file: coordinate.md:360-362)
- [ ] Modify verification checkpoints to load REPORT_PATHS from workflow state instead of using pre-calculated paths (file: coordinate.md:489, 550)
- [ ] Add diagnostic output showing path discovery results (count of files found, paths updated) (file: coordinate.md:358)

**Testing**:
```bash
# Integration test: Run coordinate with revision workflow
/coordinate "Research coordinate fixes and revise existing plan"

# Verify:
# 1. Reports created with descriptive names (not generic 001_topic1.md)
# 2. Discovery block executes and logs paths found
# 3. Verification checkpoint passes using discovered paths
# 4. No "file not found" errors at verification stage

# Check workflow state contains discovered paths
cat ~/.claude/tmp/coordinate_*.workflow_state | grep REPORT_PATHS
```

**Expected Duration**: 2.5 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(661): complete Phase 2 - Reorder Dynamic Path Discovery Before Verification`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Simplify Revision Verification Bash Commands
dependencies: [2]

**Objective**: Replace complex multiline bash conditionals with state file pattern to eliminate syntax errors

**Complexity**: Low

**Tasks**:
- [ ] Identify problematic bash blocks in coordinate.md revision verification (~lines 860-900) (file: /home/benjamin/.config/.claude/commands/coordinate.md)
- [ ] Replace variable substitution pattern with state file persistence (file: coordinate.md:870-880)
- [ ] Use `append_workflow_state "BACKUP_PATH" "$path"` to save backup path after creation (file: coordinate.md:865)
- [ ] Use `BACKUP_PATH=$(load_workflow_state "BACKUP_PATH")` in verification block (file: coordinate.md:875)
- [ ] Simplify diff command: use saved paths from state, no complex conditionals (file: coordinate.md:880)
- [ ] Add revision completion checkpoint with clear diagnostic output (file: coordinate.md:890-895)
- [ ] Update coordinate-command-guide.md with revision verification pattern documentation (file: /home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md:400-420)

**Testing**:
```bash
# Test complete revision workflow end-to-end
/coordinate "Revise documentation plan to accommodate infrastructure changes"

# Verify:
# 1. No bash syntax errors (Exit code 2) in verification blocks
# 2. Backup creation verified automatically
# 3. Diff comparison executes successfully
# 4. Completion report shows backup path and modification status

# Test with plan that requires no changes
# Verify: Reports "Files identical, no revision needed"

# Test with plan that requires changes
# Verify: Reports "Plan updated: X tasks modified"
```

**Expected Duration**: 1.5 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(661): complete Phase 3 - Simplify Revision Verification Bash Commands`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- **Scope Detection**: Test all workflow description patterns (10 test cases covering research-and-plan, research-and-revise, revision-first patterns)
- **Path Discovery**: Test discovery logic with various report naming patterns (descriptive names, numbered patterns, edge cases)
- **State Persistence**: Test BACKUP_PATH save/load across bash blocks using temp workflow state files

### Integration Testing
- **End-to-End Revision Workflow**: Complete workflow from `/coordinate "Revise X to Y"` through backup creation and verification
- **Report Path Mismatch Scenarios**: Test with topic directories containing multiple report files, verify correct file discovery
- **Bash Command Execution**: Test verification blocks execute without syntax errors across multiple subprocess invocations

### Regression Testing
- **Existing Coordinate Tests**: Run `.claude/tests/test_coordinate_*.sh` suite (all tests must pass)
- **State Machine Tests**: Run `.claude/tests/test_state_management.sh` (verify no state transition breaks)
- **Orchestration Tests**: Run `.claude/tests/test_orchestration_commands.sh` (verify coordinate still invocable)

### Coverage Target
- Modified functions: 100% coverage (scope detection, path discovery, verification)
- Integration: All revision workflow paths exercised
- Regression: Zero failures in existing test suite

## Documentation Requirements

### Files to Update
1. **coordinate-command-guide.md**: Add revision workflow patterns section (recommended patterns, current limitations, examples)
2. **workflow-scope-detection.sh**: Add inline comments documenting revised regex patterns and rationale
3. **coordinate.md**: Add architectural reference comments for dynamic discovery reordering decision
4. **CHANGELOG** (if maintained): Document fixes for issues #661 (scope detection, path discovery, bash syntax)

### Documentation Standards
- Follow timeless writing (no "New in 2025" markers per Development Philosophy)
- Use imperative language for requirements (MUST/WILL/SHALL per Imperative Language Guide)
- Include code examples for revision workflow usage patterns
- Cross-reference bash-block-execution-model.md for state file patterns

## Dependencies

### External Dependencies
- None (all fixes contained within existing infrastructure)

### Prerequisites
- workflow-scope-detection.sh exists at /home/benjamin/.config/.claude/lib/workflow-scope-detection.sh
- coordinate.md executable at /home/benjamin/.config/.claude/commands/coordinate.md
- state-persistence.sh library available (provides append_workflow_state, load_workflow_state)
- verification-helpers.sh library available (provides verification checkpoint utilities)

### Blocking Issues
- None identified (all required infrastructure present and functional)

## Risk Assessment

### Low Risk Items
- **Regex Pattern Expansion**: Additive change, existing patterns preserved
- **State File Usage**: Established pattern (bash-block-execution-model.md), zero new risk
- **Documentation Updates**: No code risk

### Medium Risk Items
- **Discovery Block Movement**: Reordering changes execution sequence, requires careful testing
  - Mitigation: Preserve exact code, only change location; add verification logging
- **Verification Checkpoint Changes**: Core fail-fast mechanism, errors must be detected
  - Mitigation: Add comprehensive integration tests before/after changes

### Testing Coverage
- All medium-risk changes covered by integration tests
- Rollback plan: Git revert of Phase 2 if discovery reordering causes issues
- Monitoring: Test suite must pass 100% before proceeding to next phase

## Rollback Plan

### Per-Phase Rollback
- **Phase 1**: `git revert` scope detection commit; workflow detection reverts to original pattern
- **Phase 2**: `git revert` discovery reordering commit; verification uses pre-calculated paths (may fail but won't crash)
- **Phase 3**: `git revert` bash simplification commit; original complex commands restored (may have syntax errors but workflow functional)

### Complete Rollback
```bash
# Revert all three phase commits in reverse order
git log --oneline --grep="feat(661)" -n 3
git revert <phase-3-commit> <phase-2-commit> <phase-1-commit>
```

### Verification After Rollback
```bash
# Run full test suite to verify stable state
.claude/tests/run_all_tests.sh

# Test basic coordinate functionality
/coordinate "Research test topic and create implementation plan"
```

## Performance Considerations

### Expected Impact
- **Scope Detection**: +5ms per workflow (negligible, regex compilation cached)
- **Path Discovery**: -50ms (discovery before verification eliminates retry paths)
- **Bash Execution**: -100ms (simpler commands reduce subprocess spawn overhead)
- **Net Performance**: +45ms improvement per revision workflow

### Monitoring
- No performance monitoring required (changes are optimizations, not degradations)
- If performance regression detected: Profile with `time /coordinate "..."` before/after

## Completion Checklist

- [ ] All 3 phases completed (checkboxes marked [x])
- [ ] All phase tests passing
- [ ] Integration test suite passing (100%)
- [ ] Regression test suite passing (100%)
- [ ] Documentation updated (4 files)
- [ ] Git commits created (3 atomic commits)
- [ ] Rollback plan validated (test git revert on feature branch)
- [ ] Code review requested (if project uses review process)
- [ ] Changes merged to main branch (if applicable)

## Notes

### Design Decisions
- **Minimal Changes Philosophy**: Only fix identified issues, avoid scope creep
- **Infrastructure Reuse**: Zero new libraries, use existing state-persistence and verification patterns
- **Standards Compliance**: Maintain 98.8% compliance score (no regressions from Report 003)

### Future Enhancements (Out of Scope)
- Filesystem fallback function in verification-helpers.sh (Report 003 Recommendation 1) - optimization, not required for fix
- Library re-sourcing consolidation (Report 003 Recommendation 2) - maintenance improvement, not functional requirement
- Explicit "revise" state in state machine (Report 002 Recommendation 4) - architectural enhancement, not bug fix

### References
- Report 001:249-274 (Recommendation 1: Filesystem-based verification)
- Report 002:211-235 (Recommendation 1: Fix scope detection pattern)
- Report 002:237-272 (Recommendation 2: Automated revision verification)
- Report 003:304-353 (Recommendation 1: Strengthen verification with fallback)
