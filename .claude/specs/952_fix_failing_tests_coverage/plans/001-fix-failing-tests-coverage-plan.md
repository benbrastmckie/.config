# Fix Failing Tests to Achieve 100% Pass Rate - Implementation Plan

## Metadata
- **Date**: 2025-11-26
- **Feature**: Test Suite Remediation
- **Scope**: Fix all 26 failing tests to achieve 100% pass rate (from 77% to 100%)
- **Estimated Phases**: 8
- **Estimated Hours**: 18
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Structure Level**: 0
- **Complexity Score**: 78.0
- **Research Reports**:
  - [Failing Tests Analysis](/home/benjamin/.config/.claude/specs/952_fix_failing_tests_coverage/reports/001_failing_tests_analysis.md)

## Overview

The test suite currently has a 77% pass rate (87/113 tests passing, 26 failing). Analysis reveals systematic infrastructure issues rather than isolated bugs: (1) Missing library file paths preventing test execution, (2) Incomplete test implementations, (3) Standards compliance violations, (4) Bash syntax errors, (5) Error logging integration gaps, (6) Empty directory creation violations, (7) Agent file location mismatches, and (8) Function export issues.

This plan systematically addresses all failure categories in dependency order, prioritizing high-impact/low-effort fixes first to rapidly improve pass rates, then addressing complex infrastructure issues. The goal is 100% test pass rate with high-quality, maintainable tests following systematic standards.

## Research Summary

Analysis of 26 failing tests reveals 8 distinct failure categories:

1. **Test Path Resolution Failures (8 tests, 31%)**: Tests use relative paths (`../lib/...`) that fail because test directory structure changed. Libraries exist but tests resolve to wrong paths.

2. **Test Execution Logic Failures (4 tests, 15%)**: Tests create fixtures successfully but lack actual test execution code - only setup phases complete, no actual workflow validation.

3. **Standards Compliance Failures (2 tests, 8%)**: `/research` command missing error trap setup at line 438; commands missing Phase 7 compliance requirements (error handling, TROUBLESHOOTING sections, library version checks).

4. **Bash Syntax Errors (2 tests, 8%)**: `local` variable declarations used outside function scope causing execution failures.

5. **Error Logging Integration Failures (3 tests, 12%)**: Error capture not working in test environment - 0% capture rate despite proper setup, `ERROR_LOG_FILE` path resolution issues.

6. **Empty Directory Violations (3 tests, 12%)**: 8 empty artifact directories detected violating lazy creation pattern - directories created without file writes.

7. **Agent File Location Failures (2 tests, 8%)**: Tests cannot find agent files at `.claude/agents/` - location mismatch or incorrect test expectations.

8. **Function Availability Failures (1 test, 4%)**: `extract_significant_words` function not exported/available when test needs it.

Recommended remediation order prioritizes impact-per-effort: path resolution (8 tests, simple regex fix) → bash syntax (2 tests, move declarations) → standards compliance (2 tests, add error traps) → complete implementations (4 tests, moderate effort) → infrastructure fixes (remaining 10 tests).

## Success Criteria

- [ ] All 113 tests pass (100% pass rate, up from 77%)
- [ ] Test path resolution uses absolute or proper relative paths
- [ ] All test implementations complete (setup + execution + validation phases)
- [ ] Commands comply with error handling and documentation standards
- [ ] No bash syntax errors in test files
- [ ] Error logging properly integrated in test environment
- [ ] No empty directories violating lazy creation pattern
- [ ] Agent file discovery works correctly
- [ ] All required functions properly exported
- [ ] Test suite runs cleanly with no warnings
- [ ] All tests follow systematic testing protocols from `.claude/docs/reference/standards/testing-protocols.md`

## Technical Design

### Architecture

The remediation follows a phased approach ordered by dependency and impact:

**Phase 1-3: Quick Wins (18 tests)** - Fix path resolution, bash syntax, and standards compliance issues. These are simple mechanical fixes with high impact.

**Phase 4: Moderate Complexity (4 tests)** - Complete test implementations by adding execution and validation logic.

**Phase 5-7: Infrastructure Fixes (4 tests)** - Address empty directory violations, agent discovery, and function exports.

**Phase 8: Complex Investigation (3 tests)** - Debug error logging integration issues that may require test infrastructure refactoring.

### Component Interactions

1. **Test Path Resolution** → All test categories depend on correct library loading
2. **Standards Compliance** → Enables error logging integration tests
3. **Test Implementations** → Validates agent behavioral compliance
4. **Infrastructure Fixes** → Supports long-term test maintainability

### Testing Strategy Integration

Each phase includes verification that fixes don't break existing passing tests. After each phase, run full test suite to verify cumulative pass rate improvement.

## Implementation Phases

### Phase 1: Fix Test Path Resolution [COMPLETE]
dependencies: []

**Objective**: Update 8 test files to use correct absolute or proper relative paths to library files.

**Complexity**: Low

Tasks:
- [x] Update convert-docs tests path resolution (`test_convert_docs_concurrency.sh:20`, `test_convert_docs_edge_cases.sh:20`, `test_convert_docs_parallel.sh:20`)
- [x] Update location test path resolution (`test_empty_directory_detection.sh:15`)
- [x] Update specialized tests path resolution (`test_report_multi_agent_pattern.sh:16`, `test_template_system.sh:20`, `test_topic_decomposition.sh:9`)
- [x] Fix double `.claude` prefix in integration test (`test_system_wide_location.sh:475`)
- [x] Replace pattern `../lib/` with proper path calculation: `CLAUDE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"; LIB_PATH="$CLAUDE_ROOT/lib/..."`
- [x] Verify all library files resolve correctly after changes

Testing:
```bash
# Run affected tests
bash .claude/tests/features/convert-docs/test_convert_docs_concurrency.sh
bash .claude/tests/features/convert-docs/test_convert_docs_edge_cases.sh
bash .claude/tests/features/convert-docs/test_convert_docs_parallel.sh
bash .claude/tests/features/location/test_empty_directory_detection.sh
bash .claude/tests/features/specialized/test_report_multi_agent_pattern.sh
bash .claude/tests/features/specialized/test_template_system.sh
bash .claude/tests/features/specialized/test_topic_decomposition.sh
bash .claude/tests/integration/test_system_wide_location.sh

# Verify pass rate improvement
bash .claude/scripts/run-all-tests.sh | grep "Pass Rate"
# Expected: 84% (95/113 tests passing)
```

**Expected Duration**: 2 hours

### Phase 2: Fix Bash Syntax Errors [COMPLETE]
dependencies: []

**Objective**: Fix `local` variable declarations outside function scope in 2 test files.

**Complexity**: Low

Tasks:
- [x] Move `local` declaration inside function in `test_command_remediation.sh:468`
- [x] Investigate and fix syntax issue in `test_path_canonicalization_allocation.sh`
- [x] Verify no other test files have similar syntax violations
- [x] Run shellcheck on all test files to catch additional syntax issues

Testing:
```bash
# Run affected tests
bash .claude/tests/features/commands/test_command_remediation.sh
bash .claude/tests/integration/test_path_canonicalization_allocation.sh

# Verify syntax with shellcheck
shellcheck .claude/tests/features/commands/test_command_remediation.sh
shellcheck .claude/tests/integration/test_path_canonicalization_allocation.sh

# Verify pass rate improvement
bash .claude/scripts/run-all-tests.sh | grep "Pass Rate"
# Expected: 86% (97/113 tests passing)
```

**Expected Duration**: 1 hour

### Phase 3: Fix Standards Compliance [COMPLETE]
dependencies: []

**Objective**: Add missing error handling and documentation to commands to meet Phase 7 compliance requirements.

**Complexity**: Low

Tasks:
- [x] Add `setup_bash_error_trap()` call to `/research` command at line 438 (Block 2 start)
- [x] Verify error-handling.sh is sourced in `/research` command
- [x] Add TROUBLESHOOTING sections to commands missing them (identify via test output)
- [x] Add library version checking patterns where missing
- [x] Update commands to include DIAGNOSTIC sections
- [x] Run compliance validation to verify fixes

Testing:
```bash
# Run affected compliance tests
bash .claude/tests/features/error-handling/test_bash_error_compliance.sh
bash .claude/tests/features/commands/test_compliance_remediation_phase7.sh

# Verify /research error trap works
bash .claude/commands/research.md # Should initialize error trap

# Verify pass rate improvement
bash .claude/scripts/run-all-tests.sh | grep "Pass Rate"
# Expected: 88% (99/113 tests passing)
```

**Expected Duration**: 2 hours

### Phase 4: Complete Test Implementations [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Add execution and validation logic to 5 incomplete test files that only have setup phases.

**Complexity**: Medium

Tasks:
- [ ] Complete `test_plan_architect_revision_mode.sh` - Add plan revision invocation and validation (verify PLAN_REVISED signal, metadata updates, completed phase preservation)
- [ ] Complete `test_revise_error_recovery.sh` - Add error recovery scenario execution (test invalid input handling, backup restoration)
- [ ] Complete `test_revise_long_prompt.sh` - Add long prompt workflow execution (test with >2000 char revision description)
- [ ] Complete `test_revise_preserve_completed.sh` - Add phase preservation validation (verify [COMPLETE] phases unchanged after revision)
- [ ] Complete `test_revise_small_plan.sh` - Add /revise command invocation (test end-to-end workflow)
- [ ] Ensure all tests follow 3-phase structure: Setup (✓) → Execute (add) → Validate (add)
- [ ] Add proper assertion checks for expected vs actual results

Testing:
```bash
# Run completed tests individually
bash .claude/tests/agents/test_plan_architect_revision_mode.sh
bash .claude/tests/commands/test_revise_error_recovery.sh
bash .claude/tests/commands/test_revise_long_prompt.sh
bash .claude/tests/commands/test_revise_preserve_completed.sh
bash .claude/tests/commands/test_revise_small_plan.sh

# Verify pass rate improvement
bash .claude/scripts/run-all-tests.sh | grep "Pass Rate"
# Expected: 92% (104/113 tests passing)
```

**Expected Duration**: 4 hours

### Phase 5: Fix Empty Directory Violations [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Clean up 8 empty artifact directories and fix code that creates them prematurely.

**Complexity**: Low

Tasks:
- [ ] Remove 8 empty directories: `.claude/specs/repair_plans_standards_analysis/reports`, `.claude/specs/20251122_commands_docs_standards_review/reports`, `.claude/specs/20251122_commands_docs_standards_review/plans`, and 5 others
- [ ] Search codebase for `mkdir -p` calls not followed by immediate file writes
- [ ] Ensure all agents use `ensure_artifact_directory()` before Write tool invocations
- [ ] Audit recent commands/agents for premature directory creation patterns
- [ ] Add pre-commit hook check to detect future empty directories (optional enhancement)

Testing:
```bash
# Run empty directory detection test
bash .claude/tests/features/location/test_no_empty_directories.sh

# Verify no empty artifact directories
find .claude/specs -type d -empty | wc -l
# Expected: 0

# Verify pass rate improvement
bash .claude/scripts/run-all-tests.sh | grep "Pass Rate"
# Expected: 93% (105/113 tests passing)
```

**Expected Duration**: 2 hours

### Phase 6: Fix Agent File Discovery [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Resolve agent file location mismatches in 2 validation tests.

**Complexity**: Low

Tasks:
- [ ] Verify agent files actually exist at `.claude/agents/` directory
- [ ] If agents exist, fix test discovery logic in `validate_no_agent_slash_commands.sh`
- [ ] If agents moved, update test expectations to correct location
- [ ] Fix cross-reference validation logic in `validate_executable_doc_separation.sh`
- [ ] Verify guide file cross-references resolve correctly
- [ ] Update test documentation with correct agent file paths

Testing:
```bash
# Verify agents exist
ls -la .claude/agents/

# Run affected validation tests
bash .claude/tests/validation/validate_no_agent_slash_commands.sh
bash .claude/tests/validation/validate_executable_doc_separation.sh

# Verify pass rate improvement
bash .claude/scripts/run-all-tests.sh | grep "Pass Rate"
# Expected: 95% (107/113 tests passing)
```

**Expected Duration**: 1 hour

### Phase 7: Fix Function Export Issues [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Export `extract_significant_words` function so `test_topic_slug_validation.sh` can access it.

**Complexity**: Low

Tasks:
- [ ] Locate `extract_significant_words` function definition (likely in `.claude/lib/plan/topic-utils.sh`)
- [ ] Add `export -f extract_significant_words` after function definition
- [ ] Verify function is sourced before test invocation
- [ ] Test function availability in subshell context
- [ ] Run test to verify function now accessible

Testing:
```bash
# Source the library and verify export
source .claude/lib/plan/topic-utils.sh
type extract_significant_words
# Should show: "extract_significant_words is a function"

# Run affected test
bash .claude/tests/features/specialized/test_topic_slug_validation.sh

# Verify pass rate improvement
bash .claude/scripts/run-all-tests.sh | grep "Pass Rate"
# Expected: 96% (108/113 tests passing)
```

**Expected Duration**: 1 hour

### Phase 8: Investigate Error Logging Integration [NOT STARTED]
dependencies: [3]

**Objective**: Debug error logging integration failures in test environment (3 tests with 0% error capture rate).

**Complexity**: High

Tasks:
- [ ] Investigate `ERROR_LOG_FILE` path resolution in test isolation environment
- [ ] Verify error-handling.sh sourcing uses correct `CLAUDE_PROJECT_DIR` in tests
- [ ] Check if test setup properly initializes error logging infrastructure
- [ ] Review test isolation patterns - determine if `CLAUDE_PROJECT_DIR` override needed
- [ ] Test error capture in isolated test environment vs normal command execution
- [ ] Fix `test_bash_error_integration.sh` - Currently 0/10 tests pass, errors not logged
- [ ] Fix `test_research_err_trap.sh` - Currently 0/6 tests pass, ERROR_LOG_FILE_NOT_FOUND
- [ ] Fix `test_convert_docs_error_logging.sh` - Validation errors not logged
- [ ] If fix requires significant test infrastructure refactoring, document as "known issue" and defer
- [ ] Ensure 90%+ error capture rate after fixes

Testing:
```bash
# Run error logging integration tests
bash .claude/tests/features/error-handling/test_bash_error_integration.sh
bash .claude/tests/features/error-handling/test_research_err_trap.sh
bash .claude/tests/features/convert-docs/test_convert_docs_error_logging.sh

# Check error capture rate
# Expected: 9/10 or 10/10 tests pass (90%+ capture rate)

# Verify ERROR_LOG_FILE exists and is writable in test context
echo "Test log entry" >> "$ERROR_LOG_FILE" && echo "SUCCESS" || echo "FAILED"

# Verify pass rate improvement
bash .claude/scripts/run-all-tests.sh | grep "Pass Rate"
# Expected: 100% (113/113 tests passing) OR 97% if deferred as known issue
```

**Expected Duration**: 5 hours

**Note**: This phase is complex and may require significant refactoring. If investigation reveals fundamental test infrastructure issues, consider:
1. Documenting as "known issue" with detailed root cause analysis
2. Creating separate GitHub issue for test infrastructure improvements
3. Deferring fix to future sprint while achieving 97% pass rate on other categories

## Testing Strategy

### Overall Approach

1. **Incremental Verification**: After each phase, run full test suite to verify cumulative pass rate improvement and ensure no regressions.

2. **Isolated Testing**: Test each fixed file individually before running full suite to catch phase-specific issues early.

3. **Coverage Validation**: Use test output to verify fixes address root causes, not just symptoms.

4. **Regression Prevention**: After achieving 100% pass rate, run test suite 3 times to ensure stability.

### Test Commands

```bash
# Individual test execution
bash .claude/tests/features/<category>/<test_file>.sh

# Full test suite
bash .claude/scripts/run-all-tests.sh

# Test suite with detailed output
bash .claude/scripts/run-all-tests.sh --verbose

# Filter by category
bash .claude/scripts/run-all-tests.sh --category features

# Check specific failure types
grep "TEST_FAILED" .claude/tests/**/*.sh
```

### Success Criteria Per Phase

- **Phase 1**: 84% pass rate (8 tests fixed)
- **Phase 2**: 86% pass rate (2 tests fixed)
- **Phase 3**: 88% pass rate (2 tests fixed)
- **Phase 4**: 92% pass rate (4 tests fixed)
- **Phase 5**: 93% pass rate (1 test fixed)
- **Phase 6**: 95% pass rate (2 tests fixed)
- **Phase 7**: 96% pass rate (1 test fixed)
- **Phase 8**: 100% pass rate (3 tests fixed) OR 97% if deferred

### Quality Metrics

- All tests follow 3-phase structure (Setup → Execute → Validate)
- All test files pass shellcheck linting
- All tests have clear failure messages
- All tests clean up fixtures after execution
- Test execution time <5 minutes for full suite

## Documentation Requirements

### Test Documentation Updates

- [ ] Update `.claude/docs/reference/standards/testing-protocols.md` with path resolution patterns for test files
- [ ] Document test isolation requirements for error logging integration
- [ ] Add examples of 3-phase test structure (Setup → Execute → Validate)
- [ ] Document common test failure patterns and remediation strategies

### Standards Documentation Updates

- [ ] Update `.claude/docs/reference/standards/code-standards.md` with bash syntax best practices (local variable scope)
- [ ] Document lazy directory creation pattern enforcement
- [ ] Add function export requirements for test-accessible utilities

### Command Documentation Updates

- [ ] Document error trap integration pattern for all commands (reference `/research` fix)
- [ ] Update compliance checklist with Phase 7 requirements

### README Updates

- [ ] Update `.claude/tests/README.md` with current pass rate (100%) and recent fixes
- [ ] Add troubleshooting section for common test failures
- [ ] Document test running commands and expected output

## Dependencies

### External Dependencies

- shellcheck (for bash syntax validation)
- bash 4.0+ (for test execution)
- Error logging infrastructure (error-handling.sh library)

### Internal Dependencies

- `.claude/lib/core/unified-location-detection.sh` - Used by tests for path resolution
- `.claude/lib/convert/convert-core.sh` - Required by convert-docs tests
- `.claude/lib/plan/topic-decomposition.sh` - Required by specialized tests
- `.claude/lib/plan/parse-template.sh` - Required by template tests
- `.claude/lib/core/error-handling.sh` - Required by error logging tests

### Phase Dependencies

- Phase 4 depends on Phases 1-3 (path resolution, syntax fixes, standards compliance must be working for test implementations)
- Phase 8 depends on Phase 3 (error trap integration must be complete before debugging error logging)
- Phases 5, 6, 7 are independent and can run in parallel with Phase 4

### Prerequisite Verification

Before starting implementation:
- [ ] Verify all library files exist and are accessible
- [ ] Confirm test runner script works correctly
- [ ] Ensure development environment has required bash version
- [ ] Verify shellcheck is available for syntax validation

## Risk Management

### Technical Risks

1. **Risk**: Phase 8 error logging integration may require extensive test infrastructure refactoring
   - **Mitigation**: Time-box investigation to 5 hours; document as "known issue" if fundamental architecture changes needed
   - **Fallback**: Achieve 97% pass rate without Phase 8; create separate ticket for test infrastructure improvements

2. **Risk**: Path resolution fixes may break in different execution contexts
   - **Mitigation**: Use absolute path calculation pattern that works from any directory; test from multiple working directories
   - **Verification**: Run tests from `.claude/`, project root, and arbitrary directories

3. **Risk**: Fixing one test category may introduce regressions in passing tests
   - **Mitigation**: Run full test suite after each phase; use git commits per phase for easy rollback
   - **Verification**: Monitor pass rate never decreases between phases

### Process Risks

1. **Risk**: Time estimates may be optimistic for complex infrastructure issues
   - **Mitigation**: Priorities 1-4 are well-understood mechanical fixes; defer uncertain work (Phase 8) to end
   - **Contingency**: +5 hours buffer for unexpected issues

2. **Risk**: Test failures may reveal deeper architectural issues
   - **Mitigation**: Document root causes; escalate if systemic design changes needed
   - **Decision Point**: After Phase 4, assess if remaining issues warrant architecture review

## Rollback Plan

Each phase uses git commits for easy rollback:

```bash
# After Phase N completes successfully
git add .
git commit -m "Phase N: <description> - Pass rate: X%"

# If Phase N+1 introduces regressions
git revert HEAD  # Rollback to Phase N
```

## Notes

- **Progressive Disclosure**: Plan starts with Level 0 (single file). If complexity grows during implementation, use `/expand` command to create phase subdirectories.

- **Complexity Score Calculation**:
  - Tasks: 42 × 1.0 = 42.0
  - Phases: 8 × 5.0 = 40.0
  - Hours: 18 × 0.5 = 9.0
  - Dependencies: 7 × 2.0 = 14.0
  - **Total: 105.0** (High complexity, but kept at Level 0 for initial execution)

- **Expansion Hint**: Given complexity score >50, consider using `/expand phase <plan-path> <phase-number>` if individual phases become too detailed during implementation.

- **Parallel Execution**: Phases 5, 6, 7 can run in parallel (all depend on 1, 2, 3 but are independent of each other).
