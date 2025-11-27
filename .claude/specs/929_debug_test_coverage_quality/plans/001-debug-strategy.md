# Test Coverage Quality Debug Strategy

## Metadata
- **Date**: 2025-11-23
- **Feature**: Debug and fix test coverage quality issues post-refactor
- **Scope**: Fix failing tests, path resolution bugs, corrupted code, deprecated test references
- **Estimated Phases**: 5
- **Estimated Hours**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 85 (Tier 2 eligible, created as Level 0)
- **Workflow Type**: debug-only
- **Research Reports**:
  - [Test Coverage Quality Analysis](/home/benjamin/.config/.claude/specs/929_debug_test_coverage_quality/reports/001_test_analysis.md)
- **Related Plan**: [Test Refactor Organization](/home/benjamin/.config/.claude/specs/919_test_refactor_organization/plans/001-test-refactor-organization-plan.md)

## Overview

Following implementation of the test refactor organization plan (spec 919), test suite analysis reveals **55 of 102 test suites failing** (54% failure rate). This debug strategy addresses the root causes identified in the research analysis:

1. **Incorrect Library Path Resolution** (20 files) - Tests use `$SCRIPT_DIR/../lib` expecting `.claude/lib` but resolving to `tests/lib`
2. **Corrupted PROJECT_ROOT Assignment** (4 files) - Malformed code with multiple concatenated assignments
3. **Double .claude Path Issue** (5 files) - Tests use `$PROJECT_ROOT/.claude/` when PROJECT_ROOT already resolves to `.claude`
4. **Tests for Deprecated/Removed Functionality** (3 files) - Tests reference features that were removed
5. **Tests for Non-Existent Agents** (2 files) - References to archived/renamed agent files

The goal is to fix all failing tests through systematic repair of path resolution patterns, correction of corrupted code, and removal/archiving of obsolete tests.

## Research Summary

Key findings from the [Test Coverage Quality Analysis](../reports/001_test_analysis.md):

- **54% failure rate**: 55 of 102 test suites failing after refactor implementation
- **Primary root cause**: Path resolution pattern `$SCRIPT_DIR/../lib` resolves to `tests/lib` instead of `.claude/lib`
- **Working pattern identified**: Tests using `git rev-parse --show-toplevel` or walking up to find `.claude` directory work correctly
- **Corrupted files**: 4 files have malformed PROJECT_ROOT assignments with syntax like `cd: too many arguments`
- **Deprecated tests**: 3 files test `parse-phase-dependencies.sh` and other removed functionality

Recommended approach: Standardize path detection using git-based or walk-up pattern, fix corrupted files, archive deprecated tests.

## Success Criteria

- [ ] All 55 currently failing test suites pass
- [ ] 20 files with incorrect library path resolution fixed using standardized pattern
- [ ] 4 files with corrupted PROJECT_ROOT assignment repaired
- [ ] 5 files with double .claude path issue corrected
- [ ] 3 deprecated tests archived with documentation
- [ ] 2 tests referencing non-existent agents updated or archived
- [ ] Full test suite achieves 90%+ pass rate (target: 100%)
- [ ] No regressions in previously passing tests

## Technical Design

### Standardized Path Detection Pattern

All tests should use this pattern for consistent path resolution:

```bash
# Standard path detection for all tests
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Option A: Git-based (preferred when in git repo)
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  # Option B: Walk-up pattern
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi

# Libraries are in .claude/lib
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"
```

### Issue Categories and Fix Approaches

| Category | Files | Fix Approach |
|----------|-------|--------------|
| Wrong lib path | 20 | Replace `$SCRIPT_DIR/../lib` with standardized pattern |
| Corrupted PROJECT_ROOT | 4 | Delete malformed line, insert standardized pattern |
| Double .claude path | 5 | Change `$PROJECT_ROOT/.claude/` to `$PROJECT_ROOT/` |
| Deprecated tests | 3 | Archive to `.claude/archive/tests/deprecated/` |
| Non-existent agents | 2 | Update agent references or archive |

## Implementation Phases

### Phase 1: Fix Corrupted PROJECT_ROOT Files [COMPLETE]
dependencies: []

**Objective**: Repair 4 files with malformed PROJECT_ROOT assignments that cause immediate syntax errors

**Complexity**: Low

**Root Cause**: Line 20 (or similar) contains malformed code like:
```bash
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)" pwd)"
```

Tasks:
- [x] Fix `/home/benjamin/.config/.claude/tests/features/compliance/test_agent_validation.sh` (line 20)
  - Replace corrupted PROJECT_ROOT with standardized git-based pattern
  - Update library source paths to use `$CLAUDE_LIB`
- [x] Fix `/home/benjamin/.config/.claude/tests/features/compliance/test_bash_command_fixes.sh` (line 8)
  - Replace corrupted PROJECT_ROOT with standardized pattern
- [x] Fix `/home/benjamin/.config/.claude/tests/features/commands/test_command_remediation.sh` (line 28)
  - Replace corrupted PROJECT_ROOT with standardized pattern
- [x] Fix `/home/benjamin/.config/.claude/tests/features/specialized/test_optimize_claude_enhancements.sh` (line 8)
  - Replace corrupted PROJECT_ROOT with standardized pattern
- [x] Run fixed tests individually to verify syntax errors resolved

Testing:
```bash
# Verify each file no longer has syntax errors
bash -n .claude/tests/features/compliance/test_agent_validation.sh
bash -n .claude/tests/features/compliance/test_bash_command_fixes.sh
bash -n .claude/tests/features/commands/test_command_remediation.sh
bash -n .claude/tests/features/specialized/test_optimize_claude_enhancements.sh

# Run each test to verify execution
bash .claude/tests/features/compliance/test_agent_validation.sh
```

**Expected Duration**: 1 hour

---

### Phase 2: Fix Incorrect Library Path Resolution [COMPLETE]
dependencies: [1]

**Objective**: Update 20 files using incorrect `$SCRIPT_DIR/../lib` pattern to use standardized git-based detection

**Complexity**: Medium

**Root Cause**: Tests use relative path `$SCRIPT_DIR/../lib` which resolves to `tests/lib` instead of `.claude/lib`

Tasks - Classification Tests:
- [x] Fix `/home/benjamin/.config/.claude/tests/classification/test_scope_detection.sh` (line 44)
  - Replace `LIB_DIR=$(cd "$SCRIPT_DIR/../lib" && pwd)` with standardized pattern
- [x] Fix `/home/benjamin/.config/.claude/tests/classification/test_workflow_detection.sh` (line 9)

Tasks - Unit Tests:
- [x] Fix `/home/benjamin/.config/.claude/tests/unit/test_llm_classifier.sh` (line 44)
- [x] Fix `/home/benjamin/.config/.claude/tests/unit/test_git_commit_utils.sh` (line 11)

Tasks - State Tests:
- [x] Fix `/home/benjamin/.config/.claude/tests/state/test_state_machine_persistence.sh` (line 56)
- [x] Fix `/home/benjamin/.config/.claude/tests/state/test_checkpoint_parallel_ops.sh` (line 9)
- [x] Fix `/home/benjamin/.config/.claude/tests/state/test_smart_checkpoint_resume.sh` (line 9)

Tasks - Integration Tests:
- [x] Fix `/home/benjamin/.config/.claude/tests/integration/test_workflow_scope_detection.sh` (line 44)

Tasks - Progressive Tests:
- [x] Fix `/home/benjamin/.config/.claude/tests/progressive/test_parallel_expansion.sh` (line 9)
- [x] Fix `/home/benjamin/.config/.claude/tests/progressive/test_parallel_collapse.sh` (line 9)
- [x] Fix `/home/benjamin/.config/.claude/tests/progressive/test_plan_progress_markers.sh` (lines 12-13)

Tasks - Topic-Naming Tests:
- [x] Fix `/home/benjamin/.config/.claude/tests/topic-naming/test_topic_slug_validation.sh` (line 44)
- [x] Fix `/home/benjamin/.config/.claude/tests/topic-naming/test_topic_filename_generation.sh` (line 44)

Tasks - Feature Tests:
- [x] Fix `/home/benjamin/.config/.claude/tests/features/location/test_detect_project_dir.sh` (multiple lines)
- [x] Fix `/home/benjamin/.config/.claude/tests/features/commands/test_orchestration_commands.sh` (multiple lines)
- [x] Fix `/home/benjamin/.config/.claude/tests/features/specialized/test_error_recovery.sh` (line 9)
- [x] Fix `/home/benjamin/.config/.claude/tests/features/specialized/test_partial_success.sh` (line 9)
- [x] Fix `/home/benjamin/.config/.claude/tests/features/specialized/test_progress_dashboard.sh` (line 23)
- [x] Fix `/home/benjamin/.config/.claude/tests/features/specialized/test_overview_synthesis.sh` (line 10)
- [x] Fix `/home/benjamin/.config/.claude/tests/features/specialized/test_library_references.sh` (line 10)

Testing:
```bash
# Test each category after fixes
bash .claude/tests/classification/test_scope_detection.sh
bash .claude/tests/classification/test_workflow_detection.sh

# Run category tests
./run_all_tests.sh 2>&1 | grep -E "(classification|unit|state|integration)" | head -20
```

**Expected Duration**: 2.5 hours

---

### Phase 3: Fix Double .claude Path Issues [COMPLETE]
dependencies: [1]

**Objective**: Correct 5 files where tests use `$PROJECT_ROOT/.claude/` when PROJECT_ROOT already resolves to `.claude`

**Complexity**: Low

**Root Cause**: When PROJECT_ROOT is set to the `.claude` directory itself, adding `.claude/` creates invalid paths like `.claude/.claude/`

Tasks:
- [x] Fix `/home/benjamin/.config/.claude/tests/unit/test_test_executor_behavioral_compliance.sh`
  - Change `$PROJECT_ROOT/.claude/agents/test-executor.md` to `$PROJECT_ROOT/agents/test-executor.md`
  - Or change PROJECT_ROOT detection to point to parent (config directory)
- [x] Fix `/home/benjamin/.config/.claude/tests/integration/test_workflow_init.sh`
  - Update path references to avoid double `.claude` prefix
- [x] Fix `/home/benjamin/.config/.claude/tests/utilities/lint_error_suppression.sh`
  - Update `$PROJECT_ROOT/.claude/commands` to proper path
- [x] Fix `/home/benjamin/.config/.claude/tests/features/compliance/test_agent_validation.sh`
  - Update `$PROJECT_ROOT/.claude/agents` reference (after Phase 1 fixes)
- [x] Fix `/home/benjamin/.config/.claude/tests/features/commands/test_command_remediation.sh`
  - Update `$PROJECT_ROOT/.claude/commands` reference (after Phase 1 fixes)

Testing:
```bash
# Verify paths resolve correctly
bash -c '
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
echo "Project dir: $CLAUDE_PROJECT_DIR"
ls -la "$CLAUDE_PROJECT_DIR/.claude/agents/test-executor.md" 2>/dev/null && echo "Path OK"
'

# Run affected tests
bash .claude/tests/unit/test_test_executor_behavioral_compliance.sh
bash .claude/tests/integration/test_workflow_init.sh
```

**Expected Duration**: 1 hour

---

### Phase 4: Archive Deprecated and Non-Existent Agent Tests [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Archive tests for deprecated functionality and update tests referencing non-existent agents

**Complexity**: Low

**Root Cause**:
- `test_parallel_waves.sh` tests `parse-phase-dependencies.sh` which was removed
- `test_offline_classification.sh` references wrong path for `workflow-llm-classifier.sh`
- `test_agent_validation.sh` tests `plan-structure-manager.md` which doesn't exist

Tasks - Archive Deprecated Tests:
- [x] Create archive directory: `/home/benjamin/.config/.claude/archive/tests/deprecated/`
- [x] Archive `/home/benjamin/.config/.claude/tests/features/specialized/test_parallel_waves.sh`
  - Move to archive with comment noting it tested removed `parse-phase-dependencies.sh`
- [x] Archive or fix `/home/benjamin/.config/.claude/tests/classification/test_offline_classification.sh`
  - If `workflow-llm-classifier.sh` exists at different path, fix the path
  - If functionality removed, archive the test

Tasks - Update Agent Reference Tests:
- [x] Update `/home/benjamin/.config/.claude/tests/features/compliance/test_agent_validation.sh`
  - Change `plan-structure-manager.md` reference to an existing agent
  - Or make the test skip gracefully if agent not found (current behavior)
- [x] Verify skip behavior works correctly when agent not found

Tasks - Documentation:
- [x] Create `/home/benjamin/.config/.claude/archive/tests/deprecated/README.md`
  - Document reason for archival for each test
  - Note date and related spec/plan

Testing:
```bash
# Verify deprecated tests archived
ls .claude/archive/tests/deprecated/

# Verify test_agent_validation.sh skips gracefully
bash .claude/tests/features/compliance/test_agent_validation.sh
# Expected: SKIP message, exit 0

# Run remaining tests in affected categories
./run_all_tests.sh 2>&1 | grep "features/specialized"
```

**Expected Duration**: 1.5 hours

---

### Phase 5: Validation and Full Test Suite Verification [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Run full test suite, verify all fixes, document any remaining issues

**Complexity**: Low

Tasks:
- [x] Run full test suite: `./run_all_tests.sh`
- [x] Capture pass/fail counts and compare to baseline (55 failing -> target 0 failing)
- [x] Identify any remaining failures not addressed in previous phases
- [x] For any new failures:
  - Document root cause
  - Create fix if simple (<15 min)
  - Add to follow-up task list if complex
- [x] Verify no regressions in previously passing tests (47 tests should still pass)
- [x] Update `/home/benjamin/.config/.claude/tests/COVERAGE_REPORT.md` with new statistics
- [x] Create summary of changes made and tests fixed

Testing:
```bash
# Full test suite
./run_all_tests.sh 2>&1 | tee test_results.log

# Count results
grep -c "PASSED" test_results.log
grep -c "FAILED" test_results.log

# Verify improvement
# Before: 55 failing (54% failure rate)
# Target: <10 failing (<10% failure rate)
# Ideal: 0 failing (100% pass rate)
```

**Expected Duration**: 2 hours

---

## Testing Strategy

### Incremental Validation

After each phase:
1. Run syntax check on modified files: `bash -n <file>`
2. Run individual test to verify fix: `bash <file>`
3. Run category tests if multiple files in same category modified
4. Track pass/fail counts for comparison

### Test Commands

```bash
# Full suite
./run_all_tests.sh

# Category-specific
./run_all_tests.sh 2>&1 | grep -A2 "classification"
./run_all_tests.sh 2>&1 | grep -A2 "unit"
./run_all_tests.sh 2>&1 | grep -A2 "state"
./run_all_tests.sh 2>&1 | grep -A2 "integration"
./run_all_tests.sh 2>&1 | grep -A2 "features"

# Individual test
bash .claude/tests/path/to/test.sh

# Syntax validation
bash -n .claude/tests/path/to/test.sh
```

### Success Metrics

| Metric | Before | Target | Validation |
|--------|--------|--------|------------|
| Test suites failing | 55 | 0 | `./run_all_tests.sh` |
| Corrupted files | 4 | 0 | `bash -n` on each file |
| Wrong lib path | 20 | 0 | Grep for old pattern |
| Double .claude path | 5 | 0 | Grep for `.claude/.claude` |
| Deprecated tests | 3 | Archived | Check archive directory |

## Documentation Requirements

### Files to Update

1. **tests/COVERAGE_REPORT.md**: Update with new pass rates and fix documentation
2. **archive/tests/deprecated/README.md**: Document archived tests and reasons

### No New Documentation Required

This is a debug/fix plan - focus on code fixes, not new documentation.

## Dependencies

### Prerequisites

- Access to all test files in `/home/benjamin/.config/.claude/tests/`
- Git repository access for `git rev-parse` pattern
- Bash 4.0+ for consistent script execution

### External Dependencies

None - all fixes are internal to the test infrastructure.

### Internal Dependencies

- Tests depend on `.claude/lib/` libraries being present
- Path resolution fixes depend on project structure remaining consistent

## Risk Mitigation

### Technical Risks

1. **Fix causes new failures**: Mitigate by testing each file individually before batch changes
2. **Pattern doesn't work in all contexts**: Use git-based pattern as primary, walk-up as fallback
3. **Archived tests needed later**: Keep in archive (not deleted), document reason for archival

### Rollback Strategy

- Git history preserves all original test files
- Archived tests can be restored from archive directory
- Each phase is independent - can roll back individual phases

---

**Note**: This plan has complexity score 85 (Tier 2 eligible). If any phase becomes too detailed during implementation, consider using `/expand phase [N]` to create detailed phase files.
