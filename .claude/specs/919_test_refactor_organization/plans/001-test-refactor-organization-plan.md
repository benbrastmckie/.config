# Test Refactor Organization Implementation Plan

## Metadata
- **Date**: 2025-11-21
- **Feature**: Test suite refactoring and organization improvements
- **Scope**: .claude/tests/ directory restructuring, test standardization, coverage improvement
- **Estimated Phases**: 6
- **Estimated Hours**: 14
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 170 (Tier 2 eligible, created as Level 0)
- **Research Reports**:
  - [Test Refactor Analysis](../reports/001_test_refactor_analysis.md)
  - [Deprecated Tests Analysis](../../920_deprecated_tests_cleanup_analysis/reports/001_deprecated_tests_analysis.md)

## Overview

This plan addresses the test infrastructure issues identified in the research analysis. The .claude/tests/ directory contains 98 test files (294 individual tests) with several organizational and maintainability issues requiring systematic refactoring:

1. **27 tests report "0 tests"** due to inconsistent output patterns not matching the test runner's `✓ PASS` grep pattern
2. **14 empty README files** across test subdirectories need documentation
3. **Topic-naming test overlap** - 7 files with redundant test coverage for `sanitize_topic_name`
4. **54% of libraries (26/48)** lack dedicated unit tests
5. **Cleanup artifacts** (backup files, logs) need removal
6. **2 Python tests** not integrated into the test runner

The goal is to standardize test output patterns, consolidate overlapping tests, improve coverage for critical libraries, and clean up obsolete artifacts while maintaining the existing 100% suite pass rate.

## Research Summary

Key findings from the [Test Refactor Analysis](../reports/001_test_refactor_analysis.md):

- **Test runner limitation**: Uses `grep -c "✓ PASS"` pattern, missing tests using `echo "PASS"` or colored output
- **Topic-naming overlap**: `sanitize_topic_name` function tested in 7 different files with 60+ redundant test calls
- **Critical untested libraries**: artifact-registry.sh, base-utils.sh, complexity-utils.sh, summary-formatting.sh
- **Coverage report outdated**: COVERAGE_REPORT.md from 2025-10-06 shows 7 suites vs current 41+
- **Python tests isolated**: test_agent_correlation.py and test_complexity_baseline.py not executed by run_all_tests.sh

**Critical Update** from [Deprecated Tests Analysis](../../920_deprecated_tests_cleanup_analysis/reports/001_deprecated_tests_analysis.md):

- **4 topic-naming tests should be REMOVED** (testing deprecated `sanitize_topic_name()` features that were never implemented):
  - `test_topic_name_sanitization.sh` - tests `strip_artifact_references()` which doesn't exist
  - `test_topic_naming.sh` - tests enhanced stopwords/length limits never implemented
  - `test_directory_naming_integration.sh` - tests deprecated sanitization function
  - `test_semantic_slug_commands.sh` - uses wrong library source path
- **3 topic-naming tests need PATH FIXES** (broken paths but test current functionality):
  - `test_topic_naming_agent.sh` - uses `.claude/.claude/lib` instead of `.claude/lib`
  - `test_topic_naming_fallback.sh` - same path bug
  - `test_topic_naming_integration.sh` - same path bug
- **Root cause**: Tests were written for enhanced `sanitize_topic_name()` that was replaced by LLM-based `topic-naming-agent`

Recommended approach: Create shared test helper library with standardized output functions, remove deprecated tests, fix path resolution in remaining tests.

## Success Criteria

- [ ] All 98 test files use standardized output patterns (✓ PASS / ✗ FAIL format)
- [ ] Test runner accurately reports individual test counts (no "0 tests" false negatives)
- [ ] Topic-naming tests reduced from 11 to 7 files (remove 4 deprecated tests for never-implemented features)
- [ ] Topic-naming test path bugs fixed (3 files with `.claude/.claude/lib` bug)
- [ ] Unit test coverage for critical libraries increased from 46% to 60%+
- [ ] All 14 empty README files populated with documentation
- [ ] Python tests integrated into test runner (optional via --python flag)
- [ ] COVERAGE_REPORT.md updated with current statistics
- [ ] No backup files, investigation logs, or obsolete artifacts in tests directory
- [ ] All existing tests continue to pass (maintain 100% suite pass rate)

## Technical Design

### Test Helper Library Architecture

Create a shared test helper library that all tests can source for consistent output:

```
tests/
├── lib/
│   └── test-helpers.sh        # Shared output functions (new)
├── run_all_tests.sh           # Update to count new patterns (modify)
└── [existing test directories]
```

**test-helpers.sh API**:
```bash
# Core output functions
pass() { echo "✓ PASS: $1"; ((TESTS_PASSED++)); }
fail() { echo "✗ FAIL: $1"; ((TESTS_FAILED++)); return 1; }
skip() { echo "⊘ SKIP: $1"; ((TESTS_SKIPPED++)); }

# Test lifecycle
setup_test() { # Initialize counters }
teardown_test() { # Report summary }

# Assertion helpers
assert_equals() { # Compare values }
assert_contains() { # Substring check }
assert_file_exists() { # File existence }
```

### Test Cleanup Strategy (Revised per Deprecated Tests Analysis)

**Topic-naming tests to REMOVE** (testing never-implemented features):
1. `test_topic_name_sanitization.sh` - tests `strip_artifact_references()` which doesn't exist
2. `test_topic_naming.sh` - tests enhanced stopwords/length limits never implemented
3. `test_directory_naming_integration.sh` - tests deprecated sanitization with wrong library
4. `test_semantic_slug_commands.sh` - uses wrong library source path (`.claude/.claude/lib`)

**Topic-naming tests to FIX** (path resolution bug):
1. `test_topic_naming_agent.sh` - fix `.claude/.claude/lib` → `.claude/lib`
2. `test_topic_naming_fallback.sh` - same path fix
3. `test_topic_naming_integration.sh` - same path fix

**Post-cleanup structure** (11 → 7 files):
- `test_topic_naming_agent.sh` (LLM agent tests, validates `validate_topic_name_format()`)
- `test_topic_naming_fallback.sh` (fallback scenarios, format validation edge cases)
- `test_topic_naming_integration.sh` (agent file structure, command integration)
- `test_atomic_topic_allocation.sh` (topic number allocation)
- `test_command_topic_allocation.sh` (command integration)
- `test_topic_slug_validation.sh` (slug format validation)
- `test_topic_filename_generation.sh` (filename patterns)

### Coverage Improvement Priority

**High priority** (critical paths, no tests):
1. `lib/core/base-utils.sh` - Core utilities used everywhere
2. `lib/artifact/artifact-registry.sh` - Artifact tracking
3. `lib/plan/complexity-utils.sh` - Complexity calculation for /plan

**Medium priority** (integration-tested only):
4. `lib/core/summary-formatting.sh` - Output formatting
5. `lib/workflow/argument-capture.sh` - CLI argument handling

## Implementation Phases

### Phase 1: Test Helper Library Foundation [COMPLETE]
dependencies: []

**Objective**: Create shared test helper library with standardized output functions

**Complexity**: Low

Tasks:
- [x] Create `/home/benjamin/.config/.claude/tests/lib/` directory
- [x] Create `/home/benjamin/.config/.claude/tests/lib/test-helpers.sh` with core functions (pass, fail, skip)
- [x] Add assertion helper functions (assert_equals, assert_contains, assert_file_exists)
- [x] Add test lifecycle functions (setup_test, teardown_test)
- [x] Add counter management (TESTS_PASSED, TESTS_FAILED, TESTS_SKIPPED)
- [x] Create `/home/benjamin/.config/.claude/tests/lib/README.md` documenting the API

Testing:
```bash
# Verify test-helpers.sh loads correctly
source .claude/tests/lib/test-helpers.sh
pass "test1" && pass "test2" && fail "test3"
echo "Passed: $TESTS_PASSED, Failed: $TESTS_FAILED"
# Expected: Passed: 2, Failed: 1
```

**Expected Duration**: 1.5 hours

---

### Phase 2: Standardize Test Output Patterns [COMPLETE]
dependencies: [1]

**Objective**: Update 27 tests with non-standard output to use test-helpers.sh

**Complexity**: Medium

Tasks:
- [x] Update `/home/benjamin/.config/.claude/tests/features/compliance/test_agent_validation.sh` to source test-helpers.sh
- [x] Update `/home/benjamin/.config/.claude/tests/features/compliance/test_argument_capture.sh` to use standardized output
- [x] Update `/home/benjamin/.config/.claude/tests/state/test_checkpoint_parallel_ops.sh` - replace colored echo with pass/fail
- [x] Update `/home/benjamin/.config/.claude/tests/features/convert-docs/test_convert_docs_*.sh` (5 files) to use test-helpers.sh
- [x] Update `/home/benjamin/.config/.claude/tests/features/specialized/test_parallel_*.sh` (4 files) to use standardized output
- [x] Update remaining 14 tests with non-standard output patterns
- [x] Verify test runner now counts all individual tests correctly

Testing:
```bash
# Run full test suite and verify counts
./run_all_tests.sh 2>&1 | grep "Total:"
# Verify no suites report "0 tests passed"
./run_all_tests.sh 2>&1 | grep "0 tests passed" | wc -l
# Expected: 0
```

**Expected Duration**: 3 hours

---

### Phase 3: Remove Deprecated Topic-Naming Tests [COMPLETE]
dependencies: [1]

**Objective**: Remove tests for deprecated `sanitize_topic_name()` features that were never implemented, and fix path bugs in remaining tests

**Complexity**: Low

**Background**: The deprecated tests analysis revealed that 4 topic-naming tests were written for an enhanced `sanitize_topic_name()` implementation that was planned but replaced by the LLM-based `topic-naming-agent`. These tests reference functions (`strip_artifact_references()`, enhanced stopwords, etc.) that were never implemented in the actual library.

**Tasks - Remove Deprecated Tests** (4 files):
- [x] Remove `/home/benjamin/.config/.claude/tests/topic-naming/test_topic_name_sanitization.sh` (tests non-existent `strip_artifact_references()`)
- [x] Remove `/home/benjamin/.config/.claude/tests/topic-naming/test_topic_naming.sh` (tests enhanced stopwords/length limits never implemented)
- [x] Remove `/home/benjamin/.config/.claude/tests/topic-naming/test_directory_naming_integration.sh` (tests deprecated sanitization)
- [x] Remove `/home/benjamin/.config/.claude/tests/topic-naming/test_semantic_slug_commands.sh` (wrong library source path)

**Tasks - Fix Path Bugs** (3 files):
- [x] Fix `/home/benjamin/.config/.claude/tests/topic-naming/test_topic_naming_agent.sh` path:
  - Change: `source "$PROJECT_ROOT/.claude/lib/plan/topic-utils.sh"`
  - To: `source "$PROJECT_ROOT/lib/plan/topic-utils.sh"`
- [x] Fix `/home/benjamin/.config/.claude/tests/topic-naming/test_topic_naming_fallback.sh` (same path fix)
- [x] Fix `/home/benjamin/.config/.claude/tests/topic-naming/test_topic_naming_integration.sh` (same path fix)

**Tasks - Verification**:
- [x] Update topic-naming/README.md with current structure (7 remaining files)
- [x] Run topic-naming tests to verify remaining tests pass
- [x] Verify no references to removed tests remain in other files

Testing:
```bash
# Verify deprecated tests are removed
ls .claude/tests/topic-naming/test_topic_name_sanitization.sh 2>&1 | grep -q "No such file" && echo "PASS: Removed"
ls .claude/tests/topic-naming/test_topic_naming.sh 2>&1 | grep -q "No such file" && echo "PASS: Removed"

# Run remaining topic-naming tests
./run_all_tests.sh --category topic-naming
# Expected: 7 files, all passing

# Verify path fix works
bash .claude/tests/topic-naming/test_topic_naming_agent.sh
# Expected: Tests execute without "Cannot load topic-utils library" error
```

**Expected Duration**: 1 hour

---

### Phase 4: Add Unit Tests for Critical Libraries [COMPLETE]
dependencies: [1]

**Objective**: Improve test coverage for critical untested libraries from 46% to 60%+

**Complexity**: High

Tasks:
- [x] Create `/home/benjamin/.config/.claude/tests/unit/test_base_utils.sh` for lib/core/base-utils.sh
- [x] Test base-utils functions: color output, path utilities, string helpers
- [x] Create `/home/benjamin/.config/.claude/tests/unit/test_artifact_registry.sh` for lib/artifact/artifact-registry.sh
- [x] Test artifact functions: registration, lookup, path resolution
- [x] Create `/home/benjamin/.config/.claude/tests/unit/test_complexity_utils.sh` for lib/plan/complexity-utils.sh
- [x] Test complexity functions: score calculation, tier determination
- [x] Create `/home/benjamin/.config/.claude/tests/unit/test_summary_formatting.sh` for lib/core/summary-formatting.sh
- [x] Test formatting functions: console output, progress indicators
- [x] Ensure all new tests use test-helpers.sh

Testing:
```bash
# Run new unit tests
./run_all_tests.sh --category unit
# Verify coverage increase
./run_all_tests.sh 2>&1 | grep "Coverage:"
# Expected: >60% library coverage
```

**Expected Duration**: 3.5 hours

---

### Phase 5: Cleanup and Documentation [COMPLETE]
dependencies: [2, 3, 4]

**Objective**: Remove obsolete artifacts and populate empty README files

**Complexity**: Low

Tasks:
- [x] Remove `/home/benjamin/.config/.claude/tests/test_coordinate_synchronization.sh.bak`
- [x] Remove `/home/benjamin/.config/.claude/tests/baseline_test_results.log`
- [x] Remove `/home/benjamin/.config/.claude/tests/phase7_test_results.log`
- [x] Remove `/home/benjamin/.config/.claude/tests/success_validation.log`
- [x] Remove `/home/benjamin/.config/.claude/tests/ab_disagreement_report.txt`
- [x] Remove `/home/benjamin/.config/.claude/tests/investigation_log.md`
- [x] Clean up `/home/benjamin/.config/.claude/tests/logs/test-errors.jsonl.backup_*` files
- [x] Populate `/home/benjamin/.config/.claude/tests/unit/README.md` with category documentation
- [x] Populate `/home/benjamin/.config/.claude/tests/integration/README.md`
- [x] Populate `/home/benjamin/.config/.claude/tests/state/README.md`
- [x] Populate `/home/benjamin/.config/.claude/tests/progressive/README.md`
- [x] Populate `/home/benjamin/.config/.claude/tests/topic-naming/README.md`
- [x] Populate `/home/benjamin/.config/.claude/tests/classification/README.md`
- [x] Populate remaining empty README files (features/, utilities/, fixtures/)

Testing:
```bash
# Verify no backup files remain
find .claude/tests -name "*.bak" -o -name "*backup*" | wc -l
# Expected: 0

# Verify no empty READMEs
find .claude/tests -name "README.md" -empty | wc -l
# Expected: 0
```

**Expected Duration**: 2 hours

---

### Phase 6: Python Integration and Coverage Report [COMPLETE]
dependencies: [4, 5]

**Objective**: Integrate Python tests and update coverage documentation

**Complexity**: Medium

Tasks:
- [x] Update `/home/benjamin/.config/.claude/tests/run_all_tests.sh` to support `--python` flag
- [x] Add Python test discovery to run_all_tests.sh (pytest or direct execution)
- [x] Document Python test requirements in tests/README.md
- [x] Regenerate `/home/benjamin/.config/.claude/tests/COVERAGE_REPORT.md` with current statistics
- [x] Update library-to-test mapping in COVERAGE_REPORT.md
- [x] Document new test categories and file counts
- [x] Add coverage percentage by category
- [x] Run full test suite and verify all tests pass

Testing:
```bash
# Run with Python tests
./run_all_tests.sh --python
# Expected: All shell and Python tests execute

# Verify coverage report accuracy
wc -l .claude/tests/COVERAGE_REPORT.md
# Expected: Updated with current statistics (>400 lines)
```

**Expected Duration**: 2 hours

---

## Testing Strategy

### Test Validation Approach

1. **Baseline Capture**: Run `./run_all_tests.sh` before changes and capture baseline_test_results.log
2. **Incremental Testing**: After each phase, run relevant test category to verify no regressions
3. **Output Pattern Verification**: Grep for non-standard patterns after Phase 2 completion
4. **Coverage Calculation**: Count library files with matching test files before/after Phase 4
5. **Final Validation**: Full test suite run after all phases, compare to baseline

### Test Commands

```bash
# Full test suite
./run_all_tests.sh

# Category-specific
./run_all_tests.sh --category unit
./run_all_tests.sh --category integration
./run_all_tests.sh --category topic-naming

# Pattern verification
grep -r "echo.*PASS" .claude/tests/ --include="*.sh" | grep -v "✓ PASS"

# Coverage check
ls .claude/lib/**/*.sh | wc -l  # Total libraries
ls .claude/tests/unit/test_*.sh | wc -l  # Unit tests
```

### Success Metrics

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| Suites with 0 tests | 27 | 0 | 0 |
| Topic-naming files | 11 | 7 | 7 |
| Topic-naming path bugs | 3 | 0 | 0 |
| Library coverage | 46% | 60%+ | >=60% |
| Empty READMEs | 14 | 0 | 0 |
| Cleanup artifacts | 10+ | 0 | 0 |

## Documentation Requirements

### Files to Update

1. **tests/README.md**: Add test helper library documentation, update category descriptions
2. **tests/COVERAGE_REPORT.md**: Regenerate with current statistics and mappings
3. **tests/lib/README.md**: Document test-helpers.sh API (new file)
4. **Category READMEs** (14 files): Populate with purpose, patterns, examples

### Documentation Standards

- Follow [Documentation Standards](../.claude/docs/reference/standards/documentation-standards.md)
- Use template from main tests/README.md structure
- Include: purpose, test patterns, running instructions, file list
- No emojis in file content

## Dependencies

### Prerequisites

- Bash 4.0+ for associative arrays in test-helpers.sh
- Python 3.8+ for Python test execution (Phase 6)
- pytest (optional) for Python test runner

### External Dependencies

- None (all tests are self-contained)

### Internal Dependencies

- All tests depend on lib/ libraries being functional
- test-helpers.sh will be sourced by all updated tests
- run_all_tests.sh drives test discovery and execution

## Risk Mitigation

### Technical Risks

1. **Test regression during standardization**: Mitigate by running category tests after each file update
2. **Merge conflicts in consolidation**: Backup files before merging, use archive for removed files
3. **Python integration complexity**: Make --python flag optional, document requirements clearly

### Rollback Strategy

- All removed files archived to `.claude/archive/tests/`
- Git history preserves original test content
- test-helpers.sh is additive (existing tests work without it)

---

**Note**: This plan has complexity score 170 (Tier 2 eligible). If phases become too detailed during implementation, consider using `/expand phase [N]` to create detailed phase files.
