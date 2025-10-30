# Unified Configuration System Implementation Plan (Shim-Free Architecture)

## Metadata
- **Date**: 2025-10-29
- **Feature**: Unified configuration system eliminating shims and consolidating location detection
- **Scope**: Complete shim removal, library consolidation, and unified configuration architecture
- **Estimated Phases**: 6
- **Estimated Hours**: 28-36 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 1
- **Expanded Phases**: [2, 4]
- **Complexity Score**: 142.0
- **Research Reports**:
  - [Shim Removal Plan - Phases 1-6](/home/benjamin/.config/.claude/specs/523_research_all_existing_shims_in_order_to_create_and/plans/001_research_all_existing_shims_in_order_to_create_and_plan.md)
  - [Library Loading Optimization - Phases 1-4 Complete](/home/benjamin/.config/.claude/specs/519_claudedocs_and_the_current_implementation_in_order/plans/001_library_loading_optimization.md)
  - [Shim Inventory Report - 7 Categories, 52 Files](/home/benjamin/.config/.claude/specs/526_research_the_implications_of_removing_all_shims_an/reports/001_topic1.md)
  - [Command Impact Analysis - 1 Primary Shim, 1-2 Hours Migration](/home/benjamin/.config/.claude/specs/526_research_the_implications_of_removing_all_shims_an/reports/002_topic2.md)
  - [Unified Configuration Design - 3 Libraries → 1, JSON Schema](/home/benjamin/.config/.claude/specs/526_research_the_implications_of_removing_all_shims_an/reports/003_topic3.md)
  - [Migration Strategy - 5 Phases, 12 Weeks, Test-First](/home/benjamin/.config/.claude/specs/526_research_the_implications_of_removing_all_shims_an/reports/004_topic4.md)

## Overview

This plan implements a comprehensive unified configuration system for the Claude Code infrastructure, eliminating all temporary shims while consolidating fragmented location detection libraries. The approach synthesizes completed work from two existing implementation plans with new requirements for library consolidation and fail-fast configuration management.

**Key Objectives**:
1. Complete remaining shim removal work (artifact-operations.sh migration)
2. Consolidate 3 location detection libraries into 1 canonical library
3. Implement centralized JSON configuration schema
4. Standardize function signatures with consistent error handling
5. Eliminate compatibility fallbacks (fail-fast error policies)

**Scope Clarification** (from research findings):
- **Only 1 temporary shim** requires removal: artifact-operations.sh (77 references)
- **2 permanent compatibility layers** retained: error-handling.sh aliases, unified-logger.sh wrappers
- **3 location libraries** consolidated: unified-location-detection.sh + topic-utils.sh + detect-project-dir.sh → claude-config.sh
- **Focus**: Unified, economical configuration (not eliminating all compatibility code)

## Research Summary

### Key Findings from Research Reports

**From Shim Inventory Report (001)**:
- Primary shim: artifact-operations.sh (43 references, scheduled removal 2026-01-01)
- 3 location detection libraries with 7+ duplicate function implementations
- 140+ library references across 23 command files (consolidation opportunity)
- Permanent compatibility layers serve different purposes (retain, not remove)

**From Command Impact Analysis (002)**:
- Only 5 commands require migration (debug, list, orchestrate, implement, plan)
- Migration effort: 1-2 hours for all commands and tests
- Failure mode is immediate and obvious (bash source errors, not silent failures)
- Two commands already demonstrate migration pattern (research.md, coordinate.md)

**From Unified Configuration Design (003)**:
- Consolidate unified-location-detection.sh (477 lines) + topic-utils.sh (141 lines) + detect-project-dir.sh (50 lines) → single library (~500 lines, 25% reduction)
- Centralized .claude/config.json for all configuration values
- Standard function signatures with consistent error codes (0/2/3/4)
- Eliminate compatibility fallbacks, implement fail-fast validation

**From Migration Strategy (004)**:
- Mature deprecation system already in place (60-day windows, explicit timelines)
- 5-phase migration strategy: low-risk → high-risk, with 7-14 day verification windows
- Test-first validation achieving 80%+ coverage before removal
- Incremental batch updates (10-20% at a time) with rollback capability

### Integration with Existing Work

**Completed Work from Plan 519 (Library Loading Optimization)**:
- ✅ Phase 1: Array deduplication implemented (timeout fix)
- ✅ Phase 2: artifact-operations.sh shim created (backward compatibility)
- ✅ Phase 3: Deduplication tests passing (58/77 baseline)
- ✅ Phase 4: Documentation complete (library classification)
- ⏸️ Phase 5: Base utilities consolidation DEFERRED

**Completed Work from Plan 523 (Shim Removal)**:
- ✅ Phase 1: Unused legacy functions removed (YAML converter)
- ⏸️ Phase 2: Permanent compatibility layers (scope changed - retain, not remove)
- ⏸️ Phases 3-6: artifact-operations.sh migration (pending)

**This Plan Completes**:
- Phases 3-6 from Plan 523 (artifact-operations.sh removal)
- Phase 5 from Plan 519 (base utilities consolidation - optional)
- New work: Location library consolidation (3 → 1)
- New work: JSON configuration schema implementation
- New work: Function signature standardization

## Success Criteria

**Primary Objectives**:
- [ ] artifact-operations.sh migration complete (77 references updated)
- [ ] artifact-operations.sh shim removed successfully
- [ ] 3 location libraries consolidated into claude-config.sh
- [ ] .claude/config.json schema implemented and validated
- [ ] Function signatures standardized with consistent error codes
- [ ] Test suite passing rate ≥baseline (58/77 minimum)
- [ ] No production errors for 14 days post-removal

**Secondary Objectives**:
- [ ] Base utilities consolidation (3 libraries → 1, deferred from Plan 519)
- [ ] Compatibility fallbacks eliminated (fail-fast error handling)
- [ ] Migration documentation complete with lessons learned
- [ ] Automated shim detection script created

**Quality Metrics**:
- [ ] Test coverage ≥80% for modified code
- [ ] Zero references to deprecated libraries remain
- [ ] Library import statements reduced by 64% (140+ → ~50)
- [ ] 100% elimination of duplicate function implementations

## Technical Design

### Architecture Overview

The unified configuration system follows a layered consolidation approach:

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 1-2: Complete Existing Shim Removal Work             │
│ └─> artifact-operations.sh migration (Plan 523 Phases 3-6) │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 3: Location Library Consolidation                    │
│ unified-location-detection.sh (477 lines)                  │
│ + topic-utils.sh (141 lines)                               │
│ + detect-project-dir.sh (50 lines)                         │
│ → claude-config.sh (~500 lines, 25% reduction)             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 4: Configuration Schema Implementation               │
│ → .claude/config.json (centralized configuration)          │
│ → Standard function signatures (consistent error codes)    │
│ → Fail-fast validation (no compatibility fallbacks)        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 5: Command Migration and Testing                     │
│ → 23 command files updated (140+ library references)       │
│ → Test suite passing (≥80% coverage)                       │
│ → 7-14 day verification window                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 6: Cleanup and Optimization                          │
│ → Deprecated libraries archived                            │
│ → Documentation updated (timeless writing)                 │
│ → Automated detection scripts                              │
└─────────────────────────────────────────────────────────────┘
```

### Consolidation Strategy

**Step 1: Complete artifact-operations.sh Removal** (Phases 3-6 from Plan 523)
- Migrate 10 command references + 12 test references
- Remove shim after 14-day verification
- Archive for rollback capability

**Step 2: Consolidate Location Libraries** (New Work)
- Rename unified-location-detection.sh → claude-config.sh (preserve 477 lines)
- Merge topic-utils.sh functions (4 functions → claude-config.sh)
- Merge detect-project-dir.sh logic (environment variable exports)
- Eliminate 7+ duplicate function implementations

**Step 3: Implement Configuration Schema** (New Work)
- Create .claude/config.json with GitOps pattern
- Migrate hardcoded values from 5+ libraries
- Add JSON parsing to claude-config.sh initialization
- Export standardized environment variables

**Step 4: Standardize Interfaces** (New Work)
- Apply standard function signatures (absolute paths, consistent error codes)
- Implement fail-fast validation (no graceful degradation)
- Add verification checkpoints (mandatory post-operation validation)
- Integrate with error-handling.sh for classification

### Risk Mitigation

**Low-Risk Changes** (Phases 1-2):
- Risk: Very Low
- Impact: Complete existing work, no new functionality
- Mitigation: Follow established migration patterns

**Medium-Risk Changes** (Phase 3):
- Risk: Medium (3 libraries consolidated, 140+ references)
- Impact: All location detection operations
- Mitigation: Incremental batch updates, comprehensive testing, 7-14 day verification

**High-Risk Changes** (Phases 4-5):
- Risk: Medium-High (configuration schema changes, function signature standardization)
- Impact: All commands using configuration libraries
- Mitigation: Dual-write pattern during transition, extensive testing, rollback capability

## Implementation Phases

### Phase 1: Complete Shim Removal Test Infrastructure (From Plan 523 Phase 3)
dependencies: []

**Objective**: Establish test baseline and migration tracking before artifact-operations.sh removal

**Complexity**: Medium

**Tasks**:
- [ ] Run full test suite with artifact-operations.sh present (establish baseline)
- [ ] Document current passing rate (baseline: 58/77 tests = 75%)
- [ ] Create migration tracking spreadsheet (commands: 10, tests: 12, docs: 60+)
- [ ] Identify all 77 references requiring migration (grep search across .claude/)
- [ ] Create test_artifact_operations_migration.sh (verify split library equivalence)
- [ ] Test split library imports work correctly (artifact-creation.sh + artifact-registry.sh + metadata-extraction.sh)
- [ ] Verify functions available after direct import (create_topic_artifact, register_artifact, get_plan_metadata, etc.)
- [ ] Document migration batches (3 batches: commands, tests, documentation)
- [ ] Create rollback procedure document (git revert + archive restoration)
- [ ] Git commit: `test: Add migration test suite for artifact-operations.sh removal`

**Testing**:
```bash
# Establish baseline
cd .claude/tests && ./run_all_tests.sh | tee baseline_results.txt

# Test split library imports
source .claude/lib/artifact-creation.sh
source .claude/lib/artifact-registry.sh
source .claude/lib/metadata-extraction.sh
type create_topic_artifact || echo "ERROR: Function not found"
type register_artifact || echo "ERROR: Function not found"
type get_plan_metadata || echo "ERROR: Function not found"

# Run migration test
./test_artifact_operations_migration.sh
# Expected: All assertions pass
```

**Expected Duration**: 3 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `test: Add migration test suite for artifact-operations.sh removal`
- [ ] Baseline test results documented
- [ ] Migration tracking spreadsheet created
- [ ] Update this plan file with phase completion status

---

### Phase 2: Batch Migration of artifact-operations.sh References (From Plan 523 Phase 4) [See: phase_2_batch_migration_of_artifact_operations_sh_references.md]

**Summary**: Systematically migrate all 77 references from the deprecated `artifact-operations.sh` shim to split libraries (`artifact-creation.sh`, `artifact-registry.sh`, `metadata-extraction.sh`) using a conservative batch-and-test approach.

**Complexity**: 8.5/10 - High risk due to 77 references across commands, tests, and documentation; mitigated by incremental batching

**Tasks**: 3 migration batches (commands, tests, documentation) with per-batch testing and git commits, comprehensive verification, zero-reference validation, migration tracking spreadsheet completion

**Expected Duration**: 1.5-2 hours

---

### Phase 3: Location Library Consolidation
dependencies: [2]

**Objective**: Consolidate 3 location detection libraries into single canonical library

**Complexity**: High

**Tasks**:
- [ ] Rename unified-location-detection.sh → claude-config.sh (preserve all 477 lines)
- [ ] Verify all 8 functions work after rename (detect_project_root, detect_specs_directory, get_next_topic_number, sanitize_topic_name, create_topic_structure, ensure_artifact_directory, perform_location_detection, create_research_subdirectory)
- [ ] Identify duplicate functions across libraries:
  - [ ] get_next_topic_number() (exists in 3 files)
  - [ ] sanitize_topic_name() (exists in 2 files)
  - [ ] create_topic_structure() (exists in 2 files)
- [ ] Add find_matching_topic() from topic-utils.sh to claude-config.sh (only unique function)
- [ ] Add environment variable exports from detect-project-dir.sh (CLAUDE_PROJECT_DIR, etc.)
- [ ] Update library-sourcing.sh to include claude-config.sh in core 7 libraries
- [ ] Create backward-compatibility aliases (topic-utils.sh → claude-config.sh, detect-project-dir.sh → claude-config.sh)
- [ ] Test consolidated library in isolation (source and verify all functions available)
- [ ] Run full test suite with consolidated library
- [ ] Git commit: `refactor: Consolidate location libraries into claude-config.sh`

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test consolidated library
source .claude/lib/claude-config.sh
type detect_project_root || echo "ERROR: Function missing"
type get_next_topic_number || echo "ERROR: Function missing"
type sanitize_topic_name || echo "ERROR: Function missing"
type find_matching_topic || echo "ERROR: Function missing"

# Verify environment variables
[ -n "$CLAUDE_PROJECT_DIR" ] || echo "ERROR: CLAUDE_PROJECT_DIR not set"

# Run full test suite
cd .claude/tests && ./run_all_tests.sh
# Expected: Baseline maintained (≥58/77)
```

**Expected Duration**: 4-5 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `refactor: Consolidate location libraries into claude-config.sh`
- [ ] claude-config.sh contains all functions from 3 source libraries
- [ ] Zero duplicate function implementations remain
- [ ] Backward-compatibility aliases created
- [ ] Update this plan file with phase completion status

---

### Phase 4: Configuration Schema Implementation [See: phase_4_configuration_schema_implementation.md]

**Summary**: Implement centralized JSON configuration system (.claude/config.json) with complete schema documentation, migrate all hardcoded values from 5+ libraries (artifact types, naming conventions, error codes, specs locations), standardize function signatures with consistent error codes and fail-fast validation, integrate with error-handling.sh for proper error classification, and add verification checkpoints to all directory creation operations following Verification and Fallback pattern.

**Complexity**: 9.5/10 - High complexity due to comprehensive schema design, migration of values from multiple libraries, function signature standardization across all operations, error handling integration, and need for extensive testing (unit tests, integration tests, regression tests) with 7-14 day verification window.

**Tasks**: 7 task groups covering schema creation and validation, JSON parsing integration with jq, hardcoded value migration from artifact-creation.sh and topic-utils.sh, environment variable override system (5 variables), function signature standardization (return values, error codes, argument validation), verification checkpoints with fallback patterns, and error-handling.sh integration with retry logic.

**Expected Duration**: 6-8 hours

---

### Phase 5: Command Migration and Verification
dependencies: [4]

**Objective**: Migrate all commands to use claude-config.sh and verify system stability

**Complexity**: High

**Tasks**:
- [ ] **Batch 1: High-priority commands (5 files)** - ~45 minutes
  - [ ] Update orchestrate.md (replace detect-project-dir.sh → claude-config.sh)
  - [ ] Update implement.md (replace detect-project-dir.sh → claude-config.sh)
  - [ ] Update plan.md (replace unified-location-detection.sh → claude-config.sh)
  - [ ] Update research.md (replace topic-utils.sh + detect-project-dir.sh → claude-config.sh)
  - [ ] Update coordinate.md (verify already using correct pattern)
  - [ ] Run test suite after batch 1
  - [ ] Git commit: `refactor(batch-1): Migrate high-priority commands to claude-config.sh`
- [ ] **Batch 2: Remaining commands (18 files)** - ~90 minutes
  - [ ] Identify all remaining commands using location libraries (grep search)
  - [ ] Update source statements (replace all location library imports → claude-config.sh)
  - [ ] Verify function calls still work (no breaking changes)
  - [ ] Run test suite after batch 2
  - [ ] Git commit: `refactor(batch-2): Migrate remaining commands to claude-config.sh`
- [ ] **Batch 3: Test files** - ~30 minutes
  - [ ] Update test files using location libraries
  - [ ] Update existence checks (verify claude-config.sh instead of old libraries)
  - [ ] Run full test suite
  - [ ] Git commit: `refactor(batch-3): Migrate test files to claude-config.sh`
- [ ] Verify zero references to deprecated libraries remain (grep search for topic-utils.sh, detect-project-dir.sh, unified-location-detection.sh)
- [ ] Monitor for 7-14 days (daily test runs, stderr log review)
- [ ] Document verification results (test passing rates, error logs)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# After each batch
cd .claude/tests && ./run_all_tests.sh
# Expected: Baseline maintained (≥58/77)

# After all batches
grep -rn "source.*topic-utils.sh" .claude/ | grep -v "\.git" | grep -v "archive" | wc -l
# Expected: 0 (only backward-compatibility alias should remain)

grep -rn "source.*detect-project-dir.sh" .claude/ | grep -v "\.git" | grep -v "archive" | wc -l
# Expected: 0 (only backward-compatibility alias should remain)

grep -rn "source.*unified-location-detection.sh" .claude/ | grep -v "\.git" | grep -v "archive" | wc -l
# Expected: 0 (file renamed to claude-config.sh)

# Verification window (7-14 days)
for day in {1..14}; do
  ./run_all_tests.sh > "day${day}_report.txt"
  PASS=$(grep -c "PASSED" "day${day}_report.txt")
  echo "Day $day: $PASS/77"
done
```

**Expected Duration**: 2.5-3 hours (migration) + 7-14 days (verification window)

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commits created for each batch (3 commits total)
- [ ] Zero references to deprecated location libraries remain
- [ ] 7-14 day verification window completed without issues
- [ ] Update this plan file with phase completion status

---

### Phase 6: Cleanup and Optimization
dependencies: [5]

**Objective**: Remove deprecated libraries, archive shims, and create automation

**Complexity**: Medium

**Tasks**:
- [ ] Remove artifact-operations.sh shim (after 14-day verification from Phase 2)
- [ ] Archive artifact-operations.sh to .claude/archive/lib/
- [ ] Remove topic-utils.sh (functions merged into claude-config.sh)
- [ ] Remove detect-project-dir.sh (logic merged into claude-config.sh)
- [ ] Archive removed libraries to .claude/archive/lib/
- [ ] Update library README.md (remove deprecated library entries, update count)
- [ ] Update SHIMS.md manifest (mark all shims as removed or retained)
- [ ] Create automated shim detection script (.claude/scripts/detect-deprecated-shims.sh)
- [ ] Update template files with new patterns (show claude-config.sh usage)
- [ ] Document lessons learned (.claude/docs/guides/shim-migration-lessons-learned.md)
- [ ] Update CLAUDE.md (distinguish temporary vs permanent compatibility layers)
- [ ] Run final comprehensive test suite
- [ ] Git commit: `refactor: Complete unified configuration system - remove deprecated libraries`

**Testing**:
```bash
# Verify deprecated libraries removed
test ! -f .claude/lib/artifact-operations.sh || echo "ERROR: Shim still exists"
test ! -f .claude/lib/topic-utils.sh || echo "ERROR: Library still exists"
test ! -f .claude/lib/detect-project-dir.sh || echo "ERROR: Library still exists"

# Verify archives exist
test -f .claude/archive/lib/artifact-operations.sh || echo "ERROR: Archive missing"
test -f .claude/archive/lib/topic-utils.sh || echo "ERROR: Archive missing"
test -f .claude/archive/lib/detect-project-dir.sh || echo "ERROR: Archive missing"

# Run automated detection script
.claude/scripts/detect-deprecated-shims.sh
# Expected: "✓ No deprecated imports found"

# Final comprehensive test
cd .claude/tests && ./run_all_tests.sh
# Expected: All tests pass (≥58/77 baseline maintained)
```

**Expected Duration**: 2-3 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `refactor: Complete unified configuration system - remove deprecated libraries`
- [ ] All deprecated libraries removed and archived
- [ ] Automated detection script created
- [ ] Lessons learned documented
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Pre-Implementation Testing

**Baseline Establishment**:
- Current passing rate: 58/77 tests (75%)
- Run full suite before any changes: `./run_all_tests.sh > baseline_report.txt`
- Document all passing tests
- Create test matrix for each migration batch

### Phase-Level Testing

**After Each Phase**:
- Run full test suite
- Validate no regression from baseline
- Test rollback procedure
- Document any test failures immediately

**Migration Testing** (Phases 2, 5):
- Test after each batch (6 batches total across both phases)
- Verify split library imports work
- Validate function availability
- Check for "command not found" errors
- Maintain passing rate ≥75%

**Integration Testing**:
- End-to-end command workflows (/orchestrate, /implement, /plan, /debug, /list, /research)
- Configuration loading and validation
- Environment variable override behavior
- Error code classification and handling

### Coverage Requirements

Based on CLAUDE.md testing protocols:
- Modified code: ≥80% coverage
- Existing code: ≥60% baseline (currently 75%)
- Critical paths: 100% coverage
  - Location detection functions
  - Configuration loading
  - Artifact operations
  - Error classification

### Test Commands

```bash
# Full test suite
cd .claude/tests && ./run_all_tests.sh

# Specific test suites
./test_artifact_operations_migration.sh
./test_shim_migration.sh
./test_rollback_procedures.sh

# Configuration tests
./test_config_loading.sh
./test_location_detection.sh
```

## Documentation Requirements

### Files Requiring Updates

**Primary Documentation**:
- .claude/lib/README.md - Library listing, consolidation complete
- .claude/lib/SHIMS.md - Update shim manifest (mark removed/retained)
- .claude/docs/guides/command-development-guide.md - New canonical patterns
- CLAUDE.md - Unified configuration section

**Reference Documentation**:
- CHANGELOG.md - Document all removals and consolidations
- .claude/docs/guides/shim-migration-lessons-learned.md - New lessons learned document
- Migration completion report (new file)

**Code Examples** (60+ files):
- Update specification files showing old library usage
- Replace with unified claude-config.sh pattern
- Show .claude/config.json usage examples

### Documentation Standards

Follow timeless documentation approach (per CLAUDE.md Development Philosophy):
- No historical markers in main docs ("previously", "now", "updated")
- Migration timeline in CHANGELOG.md only
- Code examples show current canonical pattern
- Archive historical documentation appropriately

## Dependencies

### External Dependencies

None. All changes are internal to .claude/ directory structure.

### Internal Dependencies

**Phase Dependencies**:
- Phase 2 depends on Phase 1 (test infrastructure)
- Phase 3 depends on Phase 2 (shim removal complete)
- Phase 4 depends on Phase 3 (consolidated library exists)
- Phase 5 depends on Phase 4 (configuration schema implemented)
- Phase 6 depends on Phase 5 (verification complete)

**Library Dependencies**:
- claude-config.sh depends on: base-utils.sh, json-utils.sh, error-handling.sh
- artifact-creation.sh depends on: claude-config.sh (after Phase 5)
- Commands depend on: claude-config.sh (after Phase 5)

### Rollback Dependencies

- Git history (primary rollback mechanism)
- Backup archives (secondary rollback mechanism)
- Test suite (validation after rollback)
- Verification windows (7-14 days before permanent removal)

## Risk Assessment

### Low-Risk Changes (Phase 1)

- **Risk**: Very Low
- **Impact**: Test infrastructure only
- **Mitigation**: No production code changes

### Medium-Risk Changes (Phases 2-3)

- **Risk**: Medium
- **Impact**: 77 references (Phase 2), 140+ references (Phase 3)
- **Mitigation**: Batch updates, test after each batch, 7-14 day verification

### High-Risk Changes (Phases 4-5)

- **Risk**: Medium-High
- **Impact**: All configuration operations, all commands
- **Mitigation**:
  - Backward-compatibility aliases during transition
  - Incremental batch updates
  - Comprehensive testing
  - 7-14 day verification windows
  - Rollback capability maintained

### Critical Success Factors

- Test suite passing rate maintained ≥75%
- No production errors during verification periods
- Clean rollback capability at every phase
- Gradual migration prevents cascading failures
- Comprehensive documentation prevents confusion

## Timeline

### Weeks 1-2 (Phases 1-2)
- Complete shim removal test infrastructure
- Execute artifact-operations.sh batch migration
- Begin 14-day verification window

### Weeks 3-4 (Phase 3)
- Consolidate location libraries
- Create claude-config.sh
- Eliminate duplicate implementations

### Weeks 5-6 (Phase 4)
- Implement .claude/config.json
- Standardize function signatures
- Add fail-fast validation

### Weeks 7-9 (Phase 5)
- Migrate commands in 3 batches
- Monitor verification window (7-14 days)
- Document verification results

### Weeks 10-11 (Phase 6)
- Remove deprecated libraries
- Archive for rollback
- Create automation scripts
- Document lessons learned

**Total Duration**: 11 weeks (aligns with artifact-operations.sh scheduled removal date of 2026-01-01)

**Effort**: 28-36 hours total across all phases

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
# Document issue in migration tracking
```

### Rollback from Archive

```bash
# Restore from archived backups
cp .claude/archive/lib/artifact-operations.sh .claude/lib/
cp .claude/archive/lib/topic-utils.sh .claude/lib/
cp .claude/archive/lib/detect-project-dir.sh .claude/lib/

# Verify restoration
./run_all_tests.sh
```

### Rollback Decision Criteria

**ROLLBACK if**:
- Test passing rate drops >5% below baseline (75%)
- Production error rate increases
- Cascading failures detected
- Critical commands become non-functional
- Team confidence lost in migration

**KEEP CHANGES if**:
- Test passing rate ≥baseline (75%)
- No production errors during verification window
- Commands execute normally
- User feedback positive or neutral

## Success Metrics

### Quantitative Metrics

- [ ] Test passing rate ≥75% (current baseline: 58/77)
- [ ] Zero references to artifact-operations.sh after migration
- [ ] Zero references to topic-utils.sh, detect-project-dir.sh after consolidation
- [ ] Migration completion: 77/77 references updated (Phase 2), 140+/140+ references updated (Phase 5)
- [ ] Zero production errors during verification windows
- [ ] Library import reduction: 140+ → ~50 (64% reduction)
- [ ] Duplicate function elimination: 7+ → 0 (100% reduction)

### Qualitative Metrics

- [ ] Code quality improved (cleaner imports, unified configuration)
- [ ] Maintainability enhanced (no duplicate implementations, centralized config)
- [ ] Team confidence in unified system
- [ ] Clear migration process documented for future refactors
- [ ] Rollback procedures tested and validated

### Completion Criteria

- [ ] All 6 phases completed successfully
- [ ] All success criteria met
- [ ] Test suite passing at ≥baseline rate
- [ ] Documentation accurate and complete
- [ ] Migration artifacts archived appropriately
- [ ] Lessons learned documented
