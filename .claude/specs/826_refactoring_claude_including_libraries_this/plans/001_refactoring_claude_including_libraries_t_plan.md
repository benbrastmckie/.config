# Fix Failing Tests After Library Refactoring - Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Fix 29 failing test suites after .claude/lib/ reorganization
- **Scope**: Update test file paths, fix assertions, repair environment setup
- **Estimated Phases**: 5
- **Estimated Hours**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Structure Level**: 0
- **Complexity Score**: 65.5
- **Research Reports**:
  - [Failing Tests Research](/home/benjamin/.config/.claude/specs/826_refactoring_claude_including_libraries_this/reports/001_failing_tests_research.md)

## Overview

The refactoring commit `fb8680db` reorganized `.claude/lib/` from a flat structure into subdirectories (core/, workflow/, plan/, artifact/, convert/, util/), causing 29 of 81 test suites to fail. This plan addresses all failing tests systematically, grouped by failure category and ordered by dependency.

### Goals
1. Restore all 81 test suites to passing status
2. Ensure path references are consistent with new directory structure
3. Update stale assertions to match current implementation
4. Fix test environment setup issues

## Research Summary

Key findings from the failing tests research:
- **Primary cause**: 15 tests fail due to incorrect library source paths (e.g., `$LIB_DIR/workflow-*.sh` instead of `$LIB_DIR/workflow/workflow-*.sh`)
- **Documentation paths**: 6 tests fail due to guides moved from `.claude/docs/guides/` to `.claude/docs/guides/commands/`
- **Stale assertions**: 10+ tests check for patterns that were modified or removed during refactoring
- **Environment issues**: 5 tests have path construction problems (double `.claude` or missing `.claude` segments)

Recommended approach: Batch update library paths first (highest impact), then fix documentation validation, review stale assertions, and finally address environment setup issues.

## Success Criteria
- [ ] All 81 test suites pass when running `run_all_tests.sh`
- [ ] No test file references old flat library paths
- [ ] Documentation path validation uses correct guide locations
- [ ] All test setup functions construct valid paths
- [ ] Test assertions match current implementation patterns

## Technical Design

### Path Mapping Strategy

The library reorganization follows this pattern:

| Old Path Pattern | New Subdirectory |
|------------------|------------------|
| `workflow-*.sh` | `workflow/` |
| `plan-core-bundle.sh`, `topic-*.sh`, `checkbox-utils.sh`, `complexity-utils.sh`, `auto-analysis-utils.sh`, `parse-template.sh` | `plan/` |
| `overview-synthesis.sh`, `artifact-*.sh`, `substitute-variables.sh`, `template-integration.sh` | `artifact/` |
| `unified-*.sh`, `base-utils.sh`, `detect-project-dir.sh`, `error-handling.sh`, `library-*.sh`, `state-persistence.sh`, `timestamp-utils.sh` | `core/` |
| `convert-*.sh` | `convert/` |
| `git-commit-utils.sh`, `backup-command-file.sh`, `progress-dashboard.sh`, `detect-testing.sh`, etc. | `util/` |

### Fix Approach

1. **Systematic path updates**: Use targeted edits for each affected test file
2. **Validation after each phase**: Run specific test files to verify fixes
3. **Full regression at end**: Run complete test suite to confirm no regressions

## Implementation Phases

### Phase 1: Fix Workflow Library Paths [COMPLETE]
dependencies: []

**Objective**: Update all test files that source workflow libraries from old flat paths

**Complexity**: Low

**Rationale**: Workflow library path issues affect 7 test files and are the most common failure cause. Fixing these first provides immediate progress on ~25% of failures.

Tasks:
- [x] Fix test_workflow_scope_detection.sh line 47: change `$LIB_DIR/workflow-scope-detection.sh` to `$LIB_DIR/workflow/workflow-scope-detection.sh`
- [x] Fix test_scope_detection.sh line 47: change `$LIB_DIR/workflow-scope-detection.sh` to `$LIB_DIR/workflow/workflow-scope-detection.sh`
- [x] Fix test_scope_detection.sh line 379: change `$LIB_DIR/workflow-detection.sh` to `$LIB_DIR/workflow/workflow-detection.sh`
- [x] Fix test_llm_classifier.sh line 47: change `$LIB_DIR/workflow-llm-classifier.sh` to `$LIB_DIR/workflow/workflow-llm-classifier.sh`
- [x] Fix test_topic_filename_generation.sh line 47: change `$LIB_DIR/workflow-llm-classifier.sh` to `$LIB_DIR/workflow/workflow-llm-classifier.sh`
- [x] Fix test_topic_filename_generation.sh line 48: change `$LIB_DIR/workflow-initialization.sh` to `$LIB_DIR/workflow/workflow-initialization.sh`
- [x] Fix test_topic_slug_validation.sh line 48: change `$LIB_DIR/workflow-initialization.sh` to `$LIB_DIR/workflow/workflow-initialization.sh`
- [x] Fix test_offline_classification.sh: change all occurrences of `$LIB_DIR/workflow-llm-classifier.sh` to `$LIB_DIR/workflow/workflow-llm-classifier.sh`
- [x] Fix test_offline_classification.sh: change all occurrences of `$LIB_DIR/workflow-scope-detection.sh` to `$LIB_DIR/workflow/workflow-scope-detection.sh`
- [x] Fix test_cross_block_function_availability.sh: change `$LIB_DIR/workflow-state-machine.sh` to `$LIB_DIR/workflow/workflow-state-machine.sh`

Testing:
```bash
# Run affected workflow tests to verify fixes
cd /home/benjamin/.config
.claude/tests/test_workflow_scope_detection.sh
.claude/tests/test_scope_detection.sh
.claude/tests/test_llm_classifier.sh
.claude/tests/test_topic_filename_generation.sh
.claude/tests/test_offline_classification.sh
.claude/tests/test_cross_block_function_availability.sh
```

**Expected Duration**: 0.5 hours

### Phase 2: Fix Plan and Artifact Library Paths [COMPLETE]
dependencies: []

**Objective**: Update test files sourcing plan and artifact libraries from old flat paths

**Complexity**: Low

**Rationale**: These are independent from Phase 1 and can be done in parallel. Affects 5 test files.

Tasks:
- [x] Fix test_progressive_collapse.sh line 12: change `$LIB_DIR/plan-core-bundle.sh` to `$LIB_DIR/plan/plan-core-bundle.sh`
- [x] Fix test_progressive_expansion.sh line 12: change `$LIB_DIR/plan-core-bundle.sh` to `$LIB_DIR/plan/plan-core-bundle.sh`
- [x] Fix test_parsing_utilities.sh line 12: change `$LIB_DIR/plan-core-bundle.sh` to `$LIB_DIR/plan/plan-core-bundle.sh`
- [x] Fix test_topic_slug_validation.sh line 47: change `$LIB_DIR/topic-utils.sh` to `$LIB_DIR/plan/topic-utils.sh`
- [x] Fix test_overview_synthesis.sh line 11: change `$LIB_DIR/overview-synthesis.sh` to `$LIB_DIR/artifact/overview-synthesis.sh`
- [x] Fix test_template_system.sh line 84: change `$LIB_DIR/parse-template.sh` to `$LIB_DIR/plan/parse-template.sh`

Testing:
```bash
# Run affected plan/artifact tests to verify fixes
cd /home/benjamin/.config
.claude/tests/test_progressive_collapse.sh
.claude/tests/test_progressive_expansion.sh
.claude/tests/test_parsing_utilities.sh
.claude/tests/test_topic_slug_validation.sh
.claude/tests/test_overview_synthesis.sh
.claude/tests/test_template_system.sh
```

**Expected Duration**: 0.5 hours

### Phase 3: Fix Test Environment Path Construction [COMPLETE]
dependencies: [1, 2]

**Objective**: Repair path construction issues in test setup functions that create invalid paths

**Complexity**: Medium

**Rationale**: Depends on Phases 1-2 because these tests may also have library path issues. The environment fixes are more complex as they involve understanding path variable semantics.

Tasks:
- [x] Fix test_workflow_initialization.sh line 72: change `${CLAUDE_ROOT}/.claude/lib/workflow/workflow-initialization.sh` to `${CLAUDE_ROOT}/lib/workflow/workflow-initialization.sh` (CLAUDE_ROOT already includes .claude)
- [x] Verify CLAUDE_ROOT variable definition in test_workflow_initialization.sh setup
- [x] Fix test_workflow_init.sh line 83: change `$PROJECT_ROOT/lib/workflow/workflow-init.sh` to `$PROJECT_ROOT/.claude/lib/workflow/workflow-init.sh`
- [x] Review test_workflow_init.sh lines 83-100 for any other path construction issues
- [x] Scan for any other tests with similar double-.claude or missing-.claude path issues

Testing:
```bash
# Run tests with environment/path issues
cd /home/benjamin/.config
.claude/tests/test_workflow_initialization.sh
.claude/tests/test_workflow_init.sh
```

**Expected Duration**: 0.5 hours

### Phase 4: Fix Documentation Path Validation and Stale Assertions [COMPLETE]
dependencies: [1, 2]

**Objective**: Update documentation path validation and review stale test assertions

**Complexity**: Medium

**Rationale**: Documentation path validation is straightforward, but stale assertions require individual review to determine correct updates.

Tasks:
- [x] Fix validate_executable_doc_separation.sh: update guide path from `.claude/docs/guides/${basename}-command-guide.md` to `.claude/docs/guides/commands/${basename}-command-guide.md`
- [x] Review test_command_topic_allocation.sh assertions for `allocate_and_create_topic` error handling patterns
- [x] Update test_command_topic_allocation.sh assertions to match current implementation
- [x] Remove or update migration guide check in test_command_topic_allocation.sh (atomic-allocation-migration.md was removed)
- [x] Review test_compliance_remediation_phase7.sh expected patterns: `MANDATORY VERIFICATION`, `CHECKPOINT reporting`, `POSSIBLE CAUSES`, `TROUBLESHOOTING`
- [x] Update test_compliance_remediation_phase7.sh assertions to match current command implementations, or document why patterns were intentionally removed
- [x] Verify all 6 affected commands (build.md, debug.md, plan.md, research.md, revise.md, setup.md) reference correct guide paths

Testing:
```bash
# Run validation and compliance tests
cd /home/benjamin/.config
.claude/tests/validate_executable_doc_separation.sh
.claude/tests/test_command_topic_allocation.sh
.claude/tests/test_compliance_remediation_phase7.sh
```

**Expected Duration**: 1.0 hour

### Phase 5: Full Test Suite Verification and Cleanup [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Run complete test suite to verify all fixes and ensure no regressions

**Complexity**: Low

**Rationale**: Final verification phase that depends on all previous fixes being complete.

Tasks:
- [x] Run complete test suite with `run_all_tests.sh`
- [x] Identify any remaining failures not addressed in previous phases
- [x] Fix any newly discovered path issues
- [x] Verify all 81 test suites pass
- [x] Document any tests that need further investigation (if any remain)

Testing:
```bash
# Run full test suite
cd /home/benjamin/.config
.claude/tests/run_all_tests.sh

# Verify passing count
# Expected: 81 passing, 0 failing
```

**Expected Duration**: 0.5 hours

## Testing Strategy

### Phase-Level Testing
Each phase includes targeted testing of affected test files to verify fixes before proceeding.

### Full Regression Testing
Phase 5 runs the complete test suite to ensure:
1. All 29 originally failing tests now pass
2. No previously passing tests have regressed
3. Test infrastructure remains functional

### Test Success Criteria
- Total test suites: 81
- Target passing: 81 (100%)
- Target failing: 0

### Failure Investigation Protocol
If any test continues to fail after fixes:
1. Check error message for specific line/function failure
2. Verify all source paths in the test file are updated
3. Check if test assertions match current implementation
4. Verify test setup creates correct environment

## Documentation Requirements

### During Implementation
- [ ] Add inline comments explaining any non-obvious path fixes
- [ ] Document any tests that test deprecated/removed functionality

### Post-Implementation
- [ ] No README updates required (this is internal test maintenance)
- [ ] Consider adding library path mapping to `.claude/lib/README.md` (recommendation from research)

## Dependencies

### Prerequisites
- Access to all test files in `.claude/tests/`
- Understanding of new library subdirectory structure
- Knowledge of CLAUDE_ROOT and PROJECT_ROOT variable semantics

### External Dependencies
- None (all fixes are within the repository)

### Internal Dependencies
- Phases 1 and 2 are independent (can run in parallel)
- Phase 3 depends on Phases 1 and 2 (tests may have both issues)
- Phase 4 depends on Phases 1 and 2 (tests may have both issues)
- Phase 5 depends on all previous phases

## Risk Assessment

### Low Risk
- **Path updates**: Simple find-and-replace operations with clear patterns
- **Verification**: Each phase has targeted testing

### Medium Risk
- **Stale assertions**: May require understanding of why patterns changed; could need consultation with original implementation decisions

### Mitigation
- Review git history if assertion changes are unclear
- Mark tests as skipped with TODO if unable to determine correct assertion
- Document any intentional pattern removals

## Notes

- This plan addresses test failures only; it does not modify library code
- All path updates follow the mapping established in the refactoring commit
- Phases 1 and 2 can be executed in parallel for efficiency
