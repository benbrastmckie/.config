# Failing Tests Analysis Report

## Metadata
- **Date**: 2025-11-26
- **Agent**: research-specialist
- **Topic**: Fix all failing tests to achieve 100% pass rate
- **Report Type**: codebase analysis

## Executive Summary

Analysis of 26 failing tests (out of 113 total) reveals systematic infrastructure issues rather than isolated test bugs. Key findings: (1) Missing library files preventing test execution (convert-core.sh, topic-decomposition.sh, parse-template.sh), (2) Agent behavioral compliance violations (research, plan-architect not following STEP protocols), (3) Path resolution bugs in test isolation, (4) Standards compliance gaps (error handling, library version checking), and (5) Empty directory creation violations. Primary remediation path involves fixing library import paths, implementing missing agent behavioral protocols, and enforcing lazy directory creation patterns.

## Findings

### Category 1: Test Path Resolution Failures (8 tests)

**Pattern**: Tests use relative paths (`../lib/...`) that fail when test directory structure differs from expected.

**Failed Tests**:
- `test_convert_docs_concurrency` (line 20: `../lib/convert/convert-core.sh`)
- `test_convert_docs_edge_cases` (line 20: `../lib/convert/convert-core.sh`)
- `test_convert_docs_parallel` (line 20: `../lib/convert/convert-core.sh`)
- `test_empty_directory_detection` (line 15: `../lib/core/unified-location-detection.sh`)
- `test_system_wide_location` (line 475: `.claude/.claude/lib/...` - double .claude prefix)
- `test_report_multi_agent_pattern` (line 16: `../lib/plan/topic-decomposition.sh`)
- `test_template_system` (line 20: `../lib/plan/parse-template.sh`)
- `test_topic_decomposition` (line 9: `../lib/plan/topic-decomposition.sh`)

**Root Cause**: Tests moved from `.claude/tests/features/lib/` to `.claude/tests/features/<category>/` but still use `../lib/` paths. Actual libraries are at `.claude/lib/`.

**Evidence**:
- Library files exist: `/home/benjamin/.config/.claude/lib/convert/convert-core.sh` (confirmed)
- Library files exist: `/home/benjamin/.config/.claude/lib/plan/topic-decomposition.sh` (confirmed)
- Library files exist: `/home/benjamin/.config/.claude/lib/plan/parse-template.sh` (confirmed)
- Test path: `/home/benjamin/.config/.claude/tests/features/convert-docs/test_convert_docs_concurrency.sh:20`
- Test expects: `$(dirname "${BASH_SOURCE[0]}")/../lib/convert/convert-core.sh`
- Test resolves to: `/home/benjamin/.config/.claude/tests/features/lib/convert/convert-core.sh` (does not exist)
- Should resolve to: `/home/benjamin/.config/.claude/lib/convert/convert-core.sh`

### Category 2: Test Execution Logic Failures (4 tests)

**Pattern**: Tests pass partial checks but fail to execute main test logic, exiting with "TEST_FAILED" after setup.

**Failed Tests**:
- `test_plan_architect_revision_mode` - Passes 1 check, then "TEST_FAILED" (no actual revision mode test executed)
- `test_revise_error_recovery` - Passes setup, then "TEST_FAILED" (no recovery test executed)
- `test_revise_long_prompt` - Passes setup, then "TEST_FAILED" (no long prompt test executed)
- `test_revise_preserve_completed` - Passes setup, then "TEST_FAILED" (no preservation test executed)
- `test_revise_small_plan` - Passes setup, then "TEST_FAILED" (no workflow test executed)

**Root Cause**: Tests create fixtures successfully but lack actual test execution code. Either incomplete test implementation or missing subagent invocation infrastructure.

**Evidence**:
- `/home/benjamin/.config/.claude/tests/agents/test_plan_architect_revision_mode.sh:1-100` - Only validates agent file structure, no actual revision test
- `/home/benjamin/.config/.claude/tests/commands/test_revise_small_plan.sh:1-100` - Only creates fixtures, no /revise invocation

### Category 3: Standards Compliance Failures (2 tests)

**Pattern**: Tests validate command files against standards and find violations.

**Failed Tests**:
- `test_bash_error_compliance` - `/research` missing `setup_bash_error_trap()` at line 438 (Block 2)
- `test_compliance_remediation_phase7` - Multiple commands missing error handling patterns, library version checking, troubleshooting sections (8% compliance)

**Root Cause**: Commands not updated to match evolved standards for error handling and documentation.

**Evidence**:
- `/home/benjamin/.config/.claude/commands/research.md:438` - Block 2 missing error trap setup
- Other commands (plan, build, debug, repair, revise) have traps: `/home/benjamin/.config/.claude/commands/plan.md:176`
- Phase 7 compliance requirements not met: error handling patterns, TROUBLESHOOTING sections, library version checks

### Category 4: Bash Syntax Errors (2 tests)

**Pattern**: Tests contain bash syntax violations that prevent execution.

**Failed Tests**:
- `test_command_remediation` - Line 468: `local: can only be used in a function`
- `test_path_canonicalization_allocation` - Passes symlink test but exits with TEST_FAILED (likely similar syntax issue)

**Root Cause**: Variable declarations outside function scope or incorrect bash context.

**Evidence**:
- `/home/benjamin/.config/.claude/tests/features/commands/test_command_remediation.sh:468` - `local` used at top level

### Category 5: Error Logging Integration Failures (3 tests)

**Pattern**: Tests for error logging integration fail because error capture is not working.

**Failed Tests**:
- `test_bash_error_integration` - 0% capture rate (10/10 tests failed), errors not logged
- `test_research_err_trap` - 0/6 tests pass, "ERROR_LOG_FILE_NOT_FOUND"
- `test_convert_docs_error_logging` - Validation error not logged despite test setup

**Root Cause**: Error logging infrastructure not properly integrated or test environment not configured correctly for error capture.

**Evidence**:
- Test output: "Error not found in log" (errors not being captured)
- Test output: "ERROR_LOG_FILE_NOT_FOUND" (log file path not resolved)
- Expected: 90%+ capture rate, Actual: 0%

### Category 6: Empty Directory Violations (3 tests)

**Pattern**: Tests detect pre-created empty directories violating lazy creation standards.

**Failed Tests**:
- `test_no_empty_directories` - 8 empty artifact directories detected
- `test_plan_progress_markers` - Cannot mark complete with incomplete tasks
- `test_topic_slug_validation` - Command not found: `extract_significant_words`

**Root Cause**: Commands or tests creating directories without writing files, violating lazy creation pattern.

**Evidence**:
- Empty directories: `.claude/specs/repair_plans_standards_analysis/reports` (and 7 others)
- Violation: "Directories should be created ONLY when files are written"
- Fix: "Ensure agents call ensure_artifact_directory() before writing files"

### Category 7: Agent File Location Failures (2 tests)

**Pattern**: Tests cannot find agent files in expected locations.

**Failed Tests**:
- `validate_executable_doc_separation` - 3 validations failed (guide file cross-references)
- `validate_no_agent_slash_commands` - No agent files found in `.claude/agents/`

**Root Cause**: Agent files moved or test expectations incorrect for current directory structure.

**Evidence**:
- Test expects agents at: `.claude/agents/`
- Test reports: "ERROR: No agent files found in .claude/agents/"

### Category 8: Function Availability Failures (1 test)

**Pattern**: Test cannot find required functions that should be available.

**Failed Tests**:
- `test_topic_slug_validation` - `extract_significant_words: command not found`

**Root Cause**: Function not exported or sourcing order incorrect.

## Recommendations

### Priority 1: Fix Path Resolution (8 tests, ~31% of failures)

**Action**: Update all test files in `.claude/tests/features/<category>/` to use absolute paths or proper relative paths.

**Pattern to replace**:
```bash
# WRONG (current)
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/convert/convert-core.sh"

# RIGHT (fix)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"  # Up to .claude/
LIB_PATH="$CLAUDE_ROOT/lib/convert/convert-core.sh"
```

**Files to fix**:
- `.claude/tests/features/convert-docs/test_convert_docs_concurrency.sh:20`
- `.claude/tests/features/convert-docs/test_convert_docs_edge_cases.sh:20`
- `.claude/tests/features/convert-docs/test_convert_docs_parallel.sh:20`
- `.claude/tests/features/location/test_empty_directory_detection.sh:15`
- `.claude/tests/features/specialized/test_report_multi_agent_pattern.sh:16`
- `.claude/tests/features/specialized/test_template_system.sh:20`
- `.claude/tests/features/specialized/test_topic_decomposition.sh:9`
- `.claude/tests/integration/test_system_wide_location.sh` (fix double .claude prefix)

**Expected Impact**: 8 tests fixed, 77% → 84% pass rate

### Priority 2: Complete Test Implementations (4 tests, ~15% of failures)

**Action**: Add actual test execution logic to tests that only create fixtures.

**Tests needing completion**:
1. `test_plan_architect_revision_mode` - Add plan revision invocation and validation
2. `test_revise_error_recovery` - Add error recovery scenario execution
3. `test_revise_long_prompt` - Add long prompt workflow execution
4. `test_revise_preserve_completed` - Add phase preservation validation
5. `test_revise_small_plan` - Add /revise command invocation

**Pattern**: Tests should follow 3-phase structure:
1. Setup fixtures (✓ already done)
2. Execute command/agent (✗ missing)
3. Validate results (✗ missing)

**Expected Impact**: 4-5 tests fixed, 84% → 88% pass rate

### Priority 3: Fix Standards Compliance (2 tests, ~8% of failures)

**Action**: Add missing error handling and documentation to commands.

**Specific fixes**:
1. `/research` command - Add `setup_bash_error_trap()` at line 438 (Block 2 start)
2. All commands - Add Phase 7 compliance requirements:
   - Error handling patterns
   - TROUBLESHOOTING sections
   - Library version checking
   - DIAGNOSTIC sections

**Pattern**:
```bash
# Add to /research Block 2 (after line 438):
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

**Expected Impact**: 2 tests fixed, 88% → 90% pass rate

### Priority 4: Fix Bash Syntax Errors (2 tests, ~8% of failures)

**Action**: Move `local` declarations inside functions or use regular variable declarations.

**Files to fix**:
- `.claude/tests/features/commands/test_command_remediation.sh:468`
- `.claude/tests/integration/test_path_canonicalization_allocation.sh` (investigate)

**Pattern**:
```bash
# WRONG
local success_rate=$((TESTS_PASSED * 100 / TESTS_RUN))

# RIGHT (option 1: inside function)
calculate_rates() {
  local success_rate=$((TESTS_PASSED * 100 / TESTS_RUN))
  echo "$success_rate"
}

# RIGHT (option 2: global variable)
success_rate=$((TESTS_PASSED * 100 / TESTS_RUN))
```

**Expected Impact**: 2 tests fixed, 90% → 92% pass rate

### Priority 5: Investigate Error Logging Integration (3 tests, ~12% of failures)

**Action**: Debug why error logging is not capturing errors in test environment.

**Investigation steps**:
1. Verify `ERROR_LOG_FILE` path is set correctly in test isolation
2. Check if error-handling.sh is sourced with correct `CLAUDE_PROJECT_DIR`
3. Validate test setup initializes error logging
4. Review test isolation patterns - may need `CLAUDE_PROJECT_DIR` override

**Tests affected**:
- `test_bash_error_integration`
- `test_research_err_trap`
- `test_convert_docs_error_logging`

**Note**: This is complex and may require refactoring test infrastructure. Consider marking as "known issue" if fix is non-trivial.

**Expected Impact**: 0-3 tests fixed (uncertain), 92% → 95% pass rate (best case)

### Priority 6: Fix Empty Directory Violations (3 tests, ~12% of failures)

**Action**: Clean up existing empty directories and fix code creating them.

**Immediate fix**:
```bash
# Remove existing empty directories
rm -rf .claude/specs/repair_plans_standards_analysis/reports
rm -rf .claude/specs/20251122_commands_docs_standards_review/reports
rm -rf .claude/specs/20251122_commands_docs_standards_review/plans
# ... (and 5 more)
```

**Root cause fix**: Audit commands/agents for premature directory creation:
- Search for `mkdir -p` calls not followed by immediate file writes
- Ensure all agents use `ensure_artifact_directory()` before Write tool
- Add pre-commit hook to detect empty directories

**Expected Impact**: 1-2 tests fixed, 95% → 97% pass rate

### Priority 7: Fix Agent File Discovery (2 tests, ~8% of failures)

**Action**: Investigate agent file location expectations vs reality.

**Investigation**:
1. Verify agents actually exist at `.claude/agents/`
2. Update test expectations if agents moved
3. Fix cross-reference validation logic

**Tests affected**:
- `validate_executable_doc_separation`
- `validate_no_agent_slash_commands`

**Expected Impact**: 1-2 tests fixed, 97% → 99% pass rate

### Priority 8: Fix Function Exports (1 test, ~4% of failures)

**Action**: Export `extract_significant_words` function or fix sourcing order.

**File**: Likely in `.claude/lib/plan/topic-utils.sh` or similar

**Expected Impact**: 1 test fixed, 99% → 100% pass rate

### Summary of Remediation Path

**Recommended order** (maximize impact per effort):
1. **Fix path resolution** (Priority 1) - Simple regex replacement, 8 tests
2. **Fix bash syntax** (Priority 4) - Move local declarations, 2 tests
3. **Add error traps** (Priority 3) - One-line addition to /research, 1-2 tests
4. **Complete test implementations** (Priority 2) - Moderate effort, 4-5 tests
5. **Clean empty directories** (Priority 6) - Simple cleanup, 1-2 tests
6. **Fix agent discovery** (Priority 7) - Investigation required, 1-2 tests
7. **Fix function exports** (Priority 8) - Quick export addition, 1 test
8. **Error logging integration** (Priority 5) - Complex, defer if needed, 0-3 tests

**Expected result**: Priorities 1-4 achieve 90%+ pass rate (22/26 tests fixed). Full remediation targets 100% pass rate.

## References

### Test Files Analyzed
- `/home/benjamin/.config/.claude/tests/features/convert-docs/test_convert_docs_concurrency.sh:20` - Path resolution failure
- `/home/benjamin/.config/.claude/tests/features/convert-docs/test_convert_docs_edge_cases.sh:1-50` - Path resolution failure
- `/home/benjamin/.config/.claude/tests/features/convert-docs/test_convert_docs_parallel.sh:1-50` - Path resolution failure
- `/home/benjamin/.config/.claude/tests/features/location/test_empty_directory_detection.sh:15` - Path resolution failure
- `/home/benjamin/.config/.claude/tests/features/specialized/test_report_multi_agent_pattern.sh:16` - Path resolution failure
- `/home/benjamin/.config/.claude/tests/features/specialized/test_template_system.sh:20` - Path resolution failure
- `/home/benjamin/.config/.claude/tests/features/specialized/test_topic_decomposition.sh:9` - Path resolution failure
- `/home/benjamin/.config/.claude/tests/agents/test_plan_architect_revision_mode.sh:1-100` - Incomplete test implementation
- `/home/benjamin/.config/.claude/tests/commands/test_revise_small_plan.sh:1-100` - Incomplete test implementation
- `/home/benjamin/.config/.claude/tests/features/commands/test_command_remediation.sh:468` - Bash syntax error (local outside function)

### Command Files Analyzed
- `/home/benjamin/.config/.claude/commands/research.md:438` - Missing error trap setup
- `/home/benjamin/.config/.claude/commands/plan.md:176` - Has error trap (reference example)
- `/home/benjamin/.config/.claude/commands/build.md:318` - Has error trap (reference example)

### Library Files Verified
- `/home/benjamin/.config/.claude/lib/convert/convert-core.sh` - Exists, 43KB
- `/home/benjamin/.config/.claude/lib/plan/topic-decomposition.sh` - Exists, 2.2KB
- `/home/benjamin/.config/.claude/lib/plan/parse-template.sh` - Exists, 4.5KB
- `/home/benjamin/.config/.claude/lib/core/unified-location-detection.sh` - Referenced by tests

### Standards Documentation
- `/home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md:1-325` - Testing standards
- `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md` - Directory creation anti-patterns

### Test Output
- Test run output: 87/113 tests passing (77% pass rate)
- Failed tests: 26 total across 8 categories
- Empty directories detected: 8 locations

## Implementation Status
- **Status**: Planning In Progress
- **Plan**: [../plans/001-fix-failing-tests-coverage-plan.md](../plans/001-fix-failing-tests-coverage-plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-26
