# Shim Removal Implementation Plan

## Metadata
- **Date**: 2025-10-29
- **Feature**: Systematic removal of backward-compatibility shims from Neovim configuration
- **Scope**: Remove 4 identified shims/compatibility layers to improve code quality and maintainability
- **Estimated Phases**: 6
- **Estimated Hours**: 16-20 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 68.0
- **Research Reports**:
  - [Shim Inventory and Categorization](../reports/001_shim_inventory_and_categorization_research.md)
  - [Shim Dependencies and Impact Analysis](../reports/002_shim_dependencies_and_impact_analysis_research.md)
  - [Shim Removal Strategy and Best Practices](../reports/003_shim_removal_strategy_and_best_practices_research.md)

## Overview

This plan implements a phased approach to removing backward-compatibility shims and legacy compatibility layers from the Claude Code infrastructure. The goal is to eliminate technical debt while maintaining system stability through comprehensive testing, gradual migration, and rollback safety.

Based on research findings, we have identified 4 active shims/compatibility layers:
1. **artifact-operations.sh** - Primary backward-compatibility shim (77 command references, scheduled removal 2026-01-01)
2. **unified-location-detection.sh legacy functions** - Unused YAML converter (0 active callers)
3. **error-handling.sh function aliases** - Permanent compatibility layer (15 command references)
4. **unified-logger.sh rotation wrappers** - Minimal compatibility functions

The implementation follows a low-risk-first approach, prioritizing unused/low-impact removals before tackling the primary shim with 77 references.

## Research Summary

### Key Findings from Research Reports:

**From Shim Inventory Report (001)**:
- 5 compatibility mechanisms identified (1 planned but deferred)
- artifact-operations.sh is the only full file-level shim requiring migration
- 3 function-level compatibility wrappers serve different purposes
- Shims fall into 3 categories: file-level, function-level, format compatibility

**From Dependencies Analysis Report (002)**:
- artifact-operations.sh has 10 direct command imports + 12 test references
- No circular dependencies detected (clean separation)
- Low removal risk if migration completed properly
- Commands already migrated (research.md, coordinate.md) serve as examples

**From Strategy Report (003)**:
- Project demonstrates mature deprecation practices (30-90 day windows, explicit warnings)
- Best practice: Test-first approach with 80% coverage requirement
- Safe removal order: low-usage → clear replacements → multi-dependency
- Rollback capability essential throughout migration
- Industry standard: 3-year deprecation for widely-used features (adapted to 60-90 days for internal tooling)

### Recommended Approach:
1. Remove unused legacy functions immediately (zero risk)
2. Document permanent compatibility layers (no removal needed)
3. Migrate artifact-operations.sh references systematically (77 references over 60 days)
4. Maintain comprehensive test coverage (≥80%) throughout
5. Preserve rollback capability at every phase

## Success Criteria

- [ ] All unused legacy functions removed without breaking tests
- [ ] artifact-operations.sh migration completed (77 command references updated)
- [ ] artifact-operations.sh shim removed successfully by 2026-01-01
- [ ] Test suite passing rate maintained ≥baseline (current: 57/76 passing)
- [ ] No production errors for 14 days post-removal
- [ ] All documentation updated to reflect current implementation
- [ ] Migration progress tracked and documented
- [ ] Rollback procedures tested and validated

## Technical Design

### Architecture Overview

The shim removal follows a prioritized, incremental approach:

```
Priority 1 (Immediate - Phase 1)
└─> unified-location-detection.sh legacy functions
    - Remove generate_legacy_location_context() (36 lines, 0 callers)
    - Zero risk, immediate cleanup

Priority 2 (Document Only - Phase 2)
└─> Permanent compatibility layers
    - error-handling.sh function aliases (for /supervise compatibility)
    - unified-logger.sh rotation wrappers
    - No removal, just documentation

Priority 3 (Gradual Migration - Phases 3-5)
└─> artifact-operations.sh (PRIMARY SHIM)
    ├─> Phase 3: Test baseline + migration infrastructure
    ├─> Phase 4: Batch migration (5 commands, 77 references)
    └─> Phase 5: Shim removal + verification
```

### Migration Strategy for artifact-operations.sh

**Current State**:
- Shim sources: artifact-creation.sh + artifact-registry.sh
- 10 direct imports across 5 commands
- 12 test file references
- 60+ documentation references

**Target State**:
- All commands import split libraries directly
- Tests verify split libraries (not shim)
- Documentation shows canonical pattern
- Shim file deleted

**Migration Pattern**:
```bash
# OLD (DEPRECATED)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"

# NEW (CANONICAL)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-registry.sh"
```

### Rollback Safety

Each phase includes:
1. Pre-phase backup creation
2. Incremental changes with git commits
3. Test validation after each batch
4. 14-day verification window
5. Documented rollback procedure

### Risk Mitigation

**Low-Risk Removals (Phase 1)**:
- 0 active callers verified
- Immediate test validation
- Trivial rollback if needed

**High-Risk Migration (Phases 3-5)**:
- Batch updates (10-15 references per batch)
- Test suite execution after each batch
- Rollback to previous commit if tests fail
- 60-day migration window (2025-10-29 to 2026-01-01)

## Implementation Phases

### Phase 1: Remove Unused Legacy Functions
dependencies: []

**Objective**: Remove zero-risk legacy compatibility functions with no active callers

**Complexity**: Low

**Tasks**:
- [ ] Verify zero callers for generate_legacy_location_context() (grep search)
- [ ] Create backup of unified-location-detection.sh
- [ ] Remove lines 381-416 from unified-location-detection.sh (legacy YAML converter)
- [ ] Update library documentation (line count, function list)
- [ ] Run full test suite to verify no breakage
- [ ] Git commit: `refactor: Remove unused legacy YAML converter from unified-location-detection.sh`
- [ ] Monitor for 48 hours for any issues

**Testing**:
```bash
# Verify no references exist
grep -rn "generate_legacy_location_context" .claude/

# Run test suite
cd .claude/tests && ./run_all_tests.sh

# Expected: All tests pass (57/76 baseline maintained)
```

**Expected Duration**: 1 hour

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `refactor: Remove unused legacy YAML converter from unified-location-detection.sh`
- [ ] Update this plan file with phase completion status

---

### Phase 2: Document Permanent Compatibility Layers
dependencies: [1]

**Objective**: Clarify which compatibility layers are permanent vs temporary, no code removal

**Complexity**: Low

**Tasks**:
- [ ] Create SHIMS.md manifest at .claude/lib/SHIMS.md
- [ ] Document error-handling.sh function aliases (permanent, for /supervise compatibility)
- [ ] Document unified-logger.sh rotation wrappers (permanent, minimal overhead)
- [ ] Document artifact-operations.sh (temporary, scheduled removal 2026-01-01)
- [ ] Add "Compatibility Layers" section to .claude/lib/README.md
- [ ] Distinguish temporary shims vs permanent compatibility layers
- [ ] Update command-development-guide.md with shim lifecycle policy
- [ ] Git commit: `docs: Document compatibility layer types and lifecycle policy`

**Testing**:
```bash
# Verify documentation completeness
test -f .claude/lib/SHIMS.md || echo "ERROR: SHIMS.md not created"
grep -q "Compatibility Layers" .claude/lib/README.md || echo "ERROR: README section missing"

# No functional tests needed (documentation only)
```

**Expected Duration**: 2 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] SHIMS.md manifest created and complete
- [ ] README.md updated with compatibility layers section
- [ ] Git commit created: `docs: Document compatibility layer types and lifecycle policy`
- [ ] Update this plan file with phase completion status

---

### Phase 3: Establish Test Baseline and Migration Infrastructure
dependencies: [1, 2]

**Objective**: Create comprehensive test coverage and migration tracking before artifact-operations.sh migration

**Complexity**: Medium

**Tasks**:
- [ ] Run full test suite with artifact-operations.sh present (establish baseline)
- [ ] Document current passing rate and coverage (baseline: 57/76 tests)
- [ ] Create migration tracking spreadsheet (commands, tests, docs)
- [ ] Identify all 77 references requiring migration (10 commands + 12 tests + 55 docs)
- [ ] Create test_artifact_operations_migration.sh (verify split library equivalence)
- [ ] Test split library imports work correctly (artifact-creation.sh + artifact-registry.sh)
- [ ] Verify functions available after direct import (create_topic_artifact, register_artifact, etc.)
- [ ] Document migration batches (5 batches of 15-20 references each)
- [ ] Create rollback procedure document
- [ ] Git commit: `test: Add migration test suite for artifact-operations.sh removal`

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Establish baseline
cd .claude/tests && ./run_all_tests.sh | tee baseline_results.txt

# Test split library imports
source .claude/lib/artifact-creation.sh
source .claude/lib/artifact-registry.sh
type create_topic_artifact || echo "ERROR: Function not found"
type register_artifact || echo "ERROR: Function not found"

# Run migration test
./test_artifact_operations_migration.sh
# Expected: All assertions pass
```

**Expected Duration**: 3 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `test: Add migration test suite for artifact-operations.sh removal`
- [ ] Baseline test results documented
- [ ] Migration tracking spreadsheet created
- [ ] Update this plan file with phase completion status

---

### Phase 4: Batch Migration of artifact-operations.sh References
dependencies: [3]

**Objective**: Systematically migrate all 77 references from artifact-operations.sh to split libraries

**Complexity**: High

**Tasks**:
- [ ] **Batch 1: Commands (debug.md, orchestrate.md)** - 3 references total
  - [ ] Update debug.md lines 203, 381 (2 source statements)
  - [ ] Update orchestrate.md line 609 (1 source statement)
  - [ ] Run test suite after batch 1
  - [ ] Git commit: `refactor(batch-1): Migrate debug.md and orchestrate.md to split artifact libraries`
- [ ] **Batch 2: Commands (implement.md, plan.md)** - 5 references total
  - [ ] Update implement.md lines 965, 1098 (2 source statements)
  - [ ] Update plan.md lines 144, 464, 548 (3 source statements)
  - [ ] Run test suite after batch 2
  - [ ] Git commit: `refactor(batch-2): Migrate implement.md and plan.md to split artifact libraries`

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] **Batch 3: Commands (list.md) + Test Files** - 9 references total
  - [ ] Update list.md lines 62, 101 (2 source statements)
  - [ ] Update test_report_multi_agent_pattern.sh line 10
  - [ ] Update test_shared_utilities.sh line 344
  - [ ] Update test_command_integration.sh lines 612, 684, 705
  - [ ] Update verify_phase7_baselines.sh line 91
  - [ ] Update test_library_references.sh line 56
  - [ ] Run test suite after batch 3
  - [ ] Git commit: `refactor(batch-3): Migrate list.md and test files to split artifact libraries`
- [ ] **Batch 4: Documentation (High-Priority)** - 20 references
  - [ ] Update .claude/lib/README.md (mark migration complete)
  - [ ] Update command-development-guide.md examples
  - [ ] Update 18 specification files with find/replace
  - [ ] Run documentation link checker
  - [ ] Git commit: `docs(batch-4): Update high-priority documentation to show split library pattern`
- [ ] **Batch 5: Documentation (Remaining)** - 35 references
  - [ ] Bulk find/replace across remaining specification files
  - [ ] Update code examples in archived plans
  - [ ] Verify no broken references remain
  - [ ] Git commit: `docs(batch-5): Complete documentation migration to split library pattern`

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Update migration tracking spreadsheet (mark all batches complete)
- [ ] Verify zero references to artifact-operations.sh remain (grep search)
- [ ] Run comprehensive test suite (all tests must pass)
- [ ] Document migration completion date

**Testing**:
```bash
# After each batch
cd .claude/tests && ./run_all_tests.sh
# Expected: Baseline passing rate maintained (57/76)

# After all batches complete
grep -rn "source.*artifact-operations.sh" .claude/ | grep -v "\.git" | wc -l
# Expected: 0 references remaining

# Verify split library imports
grep -rn "source.*artifact-creation.sh" .claude/commands/ | wc -l
# Expected: 5 command files

# Final comprehensive test
./run_all_tests.sh
# Expected: All tests pass
```

**Expected Duration**: 6-8 hours (spread over 5-7 days for monitoring between batches)

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created for each batch (5 commits total)
- [ ] Zero references to artifact-operations.sh remain
- [ ] Migration tracking spreadsheet shows 100% completion
- [ ] Update this plan file with phase completion status

---

### Phase 5: Remove artifact-operations.sh Shim
dependencies: [4]

**Objective**: Delete shim file after successful migration and verification period

**Complexity**: Medium

**Tasks**:
- [ ] Wait for 14-day verification period post-migration (2025-11-15 to 2025-11-29)
- [ ] Monitor for deprecation warnings during verification period (should be zero)
- [ ] Verify no production errors occurred
- [ ] Create final backup of artifact-operations.sh
- [ ] Archive shim to .claude/archive/lib/artifact-operations.sh (historical reference)
- [ ] Delete artifact-operations.sh from .claude/lib/
- [ ] Update library README.md (remove shim entry, update library count)
- [ ] Update SHIMS.md manifest (mark shim as removed)
- [ ] Run full test suite post-removal
- [ ] Git commit: `refactor: Remove artifact-operations.sh shim after successful migration`
- [ ] Monitor for 48 hours post-removal

**Testing**:
```bash
# Verify shim deleted
test ! -f .claude/lib/artifact-operations.sh || echo "ERROR: Shim still exists"

# Verify archive exists
test -f .claude/archive/lib/artifact-operations.sh || echo "ERROR: Archive missing"

# Run full test suite
cd .claude/tests && ./run_all_tests.sh
# Expected: All tests pass (baseline maintained)

# Verify split libraries work
source .claude/lib/artifact-creation.sh
source .claude/lib/artifact-registry.sh
type create_topic_artifact && echo "SUCCESS: Functions available"

# Monitor for errors
# (Manual monitoring over 48 hours)
```

**Expected Duration**: 2 hours (excluding 14-day verification wait)

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `refactor: Remove artifact-operations.sh shim after successful migration`
- [ ] 14-day verification period completed without issues
- [ ] Shim file deleted and archived
- [ ] Update this plan file with phase completion status

---

### Phase 6: Final Validation and Documentation
dependencies: [5]

**Objective**: Comprehensive validation and documentation updates post-removal

**Complexity**: Low

**Tasks**:
- [ ] Run comprehensive test suite (validate all tests still pass)
- [ ] Verify test passing rate ≥ baseline (57/76)
- [ ] Update CHANGELOG.md with shim removal entries
- [ ] Update Development Workflow documentation
- [ ] Review and update command-development-guide.md (remove shim references)
- [ ] Validate library documentation accuracy
- [ ] Create migration completion report (before/after metrics)
- [ ] Document lessons learned for future shim removals
- [ ] Archive migration tracking spreadsheet
- [ ] Git commit: `docs: Finalize documentation after shim removal completion`
- [ ] Mark implementation plan complete

**Testing**:
```bash
# Final comprehensive validation
cd .claude/tests && ./run_all_tests.sh | tee final_results.txt

# Compare with baseline
diff baseline_results.txt final_results.txt
# Expected: No regression in passing rate

# Verify no shim references remain
grep -rn "artifact-operations" .claude/ | grep -v ".git" | grep -v "archive"
# Expected: Only historical references in specs/reports

# Documentation validation
.claude/scripts/validate-documentation.sh
# Expected: All links valid, no broken references
```

**Expected Duration**: 2 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `docs: Finalize documentation after shim removal completion`
- [ ] Migration completion report created
- [ ] All success criteria met
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Pre-Implementation Testing
- Establish baseline test passing rate (current: 57/76 = 75%)
- Document all passing tests
- Create test matrix for each shim removal
- Verify rollback procedures work

### Phase-Level Testing
- Run full test suite after each phase
- Validate no regression from baseline
- Test rollback procedure for each phase
- Document any test failures immediately

### Migration Testing (Phase 4)
- Test after each batch (5 batches)
- Verify split library imports work
- Validate function availability
- Check for "command not found" errors
- Maintain passing rate ≥75%

### Post-Removal Testing (Phase 5-6)
- Comprehensive test suite execution
- 48-hour monitoring period
- Production error rate tracking
- Performance regression checks

### Coverage Requirements
- Modified code: ≥80% coverage
- Existing code: ≥60% baseline
- Critical paths: 100% coverage
  - Artifact creation functions
  - Artifact registry operations
  - Command source statement resolution

### Test Commands
```bash
# Full test suite
cd .claude/tests && ./run_all_tests.sh

# Specific test suites
./test_shared_utilities.sh
./test_command_integration.sh
./test_library_references.sh

# Migration-specific tests
./test_artifact_operations_migration.sh
```

## Documentation Requirements

### Files Requiring Updates

**Primary Documentation**:
- .claude/lib/README.md - Library listing, migration guide removal
- .claude/lib/SHIMS.md - New manifest file creation
- .claude/docs/guides/command-development-guide.md - Remove shim examples
- .claude/docs/concepts/development-workflow.md - Update artifact patterns

**Reference Documentation**:
- CHANGELOG.md - Document shim removals
- .claude/commands/README.md - Update command patterns
- Migration completion report (new file)

**Code Examples** (60+ files):
- Update specification files showing artifact-operations.sh usage
- Replace with split library pattern in all examples
- Update historical documentation (mark as historical)

### Documentation Standards
- Follow timeless documentation approach (no historical markers in main docs)
- Migration timeline in CHANGELOG.md only
- Code examples show current canonical pattern
- Archive historical documentation appropriately

## Dependencies

### External Dependencies
None. All changes are internal to .claude/ directory structure.

### Internal Dependencies

**Phase Dependencies**:
- Phase 2 depends on Phase 1 (establish pattern)
- Phase 3 depends on Phases 1-2 (build on documentation)
- Phase 4 depends on Phase 3 (requires test infrastructure)
- Phase 5 depends on Phase 4 (requires complete migration)
- Phase 6 depends on Phase 5 (final validation)

**Library Dependencies**:
- artifact-creation.sh depends on: base-utils.sh, unified-logger.sh, artifact-registry.sh
- artifact-registry.sh depends on: base-utils.sh, unified-logger.sh
- No circular dependencies exist

**Command Dependencies**:
- 5 commands currently depend on artifact-operations.sh (will be migrated)
- 2 commands already use split libraries directly (serve as examples)

### Rollback Dependencies
- Git history (primary rollback mechanism)
- Backup files (secondary rollback mechanism)
- Test suite (validation after rollback)
- 14-day verification windows (catch issues before permanent removal)

## Risk Assessment

### Low-Risk Changes (Phase 1)
- **Risk**: Very Low
- **Impact**: Zero (unused functions)
- **Mitigation**: Immediate test validation

### Medium-Risk Changes (Phases 2-3)
- **Risk**: Low
- **Impact**: Documentation only (Phase 2), test infrastructure (Phase 3)
- **Mitigation**: No production code changes in these phases

### High-Risk Changes (Phases 4-5)
- **Risk**: Medium
- **Impact**: 77 references, 5 commands, 7 test files
- **Mitigation**:
  - Batch updates (15-20 refs per batch)
  - Test after each batch
  - 14-day verification window
  - Rollback capability maintained
  - Examples exist (research.md, coordinate.md)

### Critical Success Factors
- Test suite passing rate maintained ≥75%
- No production errors during verification periods
- Clean rollback capability at every phase
- Gradual migration prevents cascading failures
- Comprehensive documentation prevents confusion

## Timeline

### Week 1 (2025-10-29 to 2025-11-04)
- Complete Phases 1-3
- Establish test baseline
- Create migration infrastructure

### Weeks 2-3 (2025-11-05 to 2025-11-18)
- Execute Phase 4 (batch migration)
- 1-2 batches per week
- Monitor after each batch

### Weeks 4-5 (2025-11-19 to 2025-12-02)
- Complete Phase 4 (remaining batches)
- Begin 14-day verification period

### Weeks 6-7 (2025-12-03 to 2025-12-16)
- Complete verification period
- Execute Phase 5 (shim removal)
- Monitor for 48 hours

### Week 8 (2025-12-17 to 2025-12-23)
- Execute Phase 6 (final validation)
- Complete documentation updates
- Archive migration artifacts

**Total Duration**: 8 weeks (aligns with scheduled shim removal date of 2026-01-01)

**Slack Time**: 1 week buffer before 2026-01-01 deadline

## Rollback Procedures

### Immediate Rollback (if tests fail)
```bash
# Rollback current batch
git log --oneline -5  # Identify commit to revert
git revert <commit-hash>
git commit -m "rollback: Revert batch N migration due to test failures"

# Verify rollback
cd .claude/tests && ./run_all_tests.sh
# Expected: Tests return to passing state
```

### Phase-Level Rollback
```bash
# Rollback entire phase
git log --oneline -10  # Find phase start commit
git revert <commit-range>  # Revert all commits in phase
./run_all_tests.sh  # Validate rollback
```

### Emergency Rollback (critical production issues)
```bash
# Fast rollback without validation
git revert <commit-hash> --no-edit
git push origin <branch>

# Post-rollback validation
./run_all_tests.sh
# Document issue in migration tracking spreadsheet
```

### Rollback Decision Criteria
- Test passing rate drops >5% below baseline
- Production error rate increases
- Cascading failures detected
- Critical command becomes non-functional
- Team confidence lost in migration

## Success Metrics

### Quantitative Metrics
- [ ] Test passing rate ≥75% (current baseline: 57/76)
- [ ] Zero references to artifact-operations.sh after migration
- [ ] Migration completion: 77/77 references updated (100%)
- [ ] Zero production errors during 14-day verification
- [ ] Documentation updates: 60+ files updated
- [ ] Timeline adherence: Complete by 2026-01-01

### Qualitative Metrics
- [ ] Code quality improved (cleaner imports)
- [ ] Maintainability enhanced (no shim overhead)
- [ ] Team confidence in split library pattern
- [ ] Clear migration process documented for future shims
- [ ] Rollback procedures tested and validated

### Completion Criteria
- [ ] All 6 phases completed successfully
- [ ] All success criteria met
- [ ] Test suite passing at ≥baseline rate
- [ ] Documentation accurate and complete
- [ ] Migration artifacts archived appropriately
- [ ] Lessons learned documented
