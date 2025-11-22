# Implementation Plan: /research Command Error Analysis Repair

## Metadata
- **Title**: Repair /research Command Benign Error Filtering
- **Description**: Fix infrastructure-level error logging issues affecting /research and all commands
- **Complexity**: 2 (Medium - multiple independent fixes with diagnostics required)
- **Created**: 2025-11-21
- **Source Error Report**: `.claude/specs/911_research_error_analysis/reports/001_error_report.md`
- **Source Repair Analysis**: `.claude/specs/913_911_research_error_analysis_repair/reports/001_repair_analysis.md`
- **Estimated Effort**: 4-8 hours total

---

## Executive Summary

The /research command logged 2 errors that represent infrastructure-level issues affecting all commands:

1. **Exit Code 127**: Benign `/etc/bashrc` sourcing error is not being filtered despite existing filter logic
2. **Exit Code 1**: Intentional `return 1` statements from error-handling.sh are being logged as errors

Root cause analysis indicates the benign error filter exists but is either not being invoked, receiving different input than expected, or has pattern matching issues. This plan takes a diagnostic-first approach to identify the exact failure mechanism before implementing fixes.

**Expected Impact**: Fixing these issues will eliminate 50%+ of noise errors across ALL commands (not just /research).

---

## Phase 1: Debug and Diagnose

**Objective**: Identify why the benign error filter is not catching known benign patterns

**Dependencies**: None (starting phase)

### Stage 1.1: Add Diagnostic Logging to Filter

**Description**: Insert temporary debug logging to capture actual command strings reaching the filter function.

**Implementation**:
1. Locate `_is_benign_bash_error()` function in `/home/benjamin/.config/.claude/lib/core/error-handling.sh`
2. Add diagnostic output to capture:
   - Exact command string received (`$1`)
   - Exit code received (`$2`)
   - Whether function returns true/false
3. Add diagnostic to `_log_bash_exit()` to confirm filter is being called

**Files**:
- `.claude/lib/core/error-handling.sh` - Add temporary DEBUG lines

**Verification**:
- [ ] Diagnostic code compiles (no syntax errors)
- [ ] Running `source .claude/lib/core/error-handling.sh` succeeds

### Stage 1.2: Trigger Test Scenario

**Description**: Run a minimal test to capture diagnostic output.

**Implementation**:
1. Create a minimal test bash block that triggers the benign error
2. Capture stderr to see diagnostic output
3. Document the actual values received by the filter

**Files**:
- None (manual test execution)

**Verification**:
- [ ] Diagnostic output captured showing actual command strings
- [ ] Clear understanding of why filter is not matching

### Stage 1.3: Analyze Results and Document Root Cause

**Description**: Compare diagnostic output to filter patterns and document exact failure point.

**Implementation**:
1. Compare captured command string to filter patterns
2. Identify discrepancy (whitespace, quoting, partial string, etc.)
3. Document root cause in debug notes

**Expected Findings** (hypotheses to validate):
- Command string may have different whitespace than pattern expects
- `$BASH_COMMAND` captured by trap may differ from test patterns
- Filter may be operating on partial command string
- Filter may not be called at all for certain code paths

**Success Criteria for Phase 1**:
- [ ] Root cause of filter bypass identified with evidence
- [ ] Exact command string discrepancy documented
- [ ] Clear fix path determined

---

## Phase 2: Implement Fixes

**Objective**: Update filter patterns and add library-origin filtering

**Dependencies**: Phase 1 complete (need diagnostic data to inform fixes)

### Stage 2.1: Fix Benign Error Pattern Matching

**Description**: Update `_is_benign_bash_error()` patterns based on diagnostic findings.

**Implementation**:
1. Update pattern matching to handle actual command string format
2. Add additional patterns if needed for edge cases
3. Remove diagnostic logging added in Phase 1

**Files**:
- `.claude/lib/core/error-handling.sh` - Update `_is_benign_bash_error()` function

**Code Changes** (will be refined after Phase 1):
```bash
# Expected pattern update location: lines 1244-1287
# Update pattern matching based on diagnostic findings
```

**Verification**:
- [ ] Unit tests pass: `bash .claude/tests/unit/test_benign_error_filter.sh`
- [ ] Filter correctly matches actual command strings from production

### Stage 2.2: Filter Intentional Return Statements from Core Libraries

**Description**: Add logic to exclude `return 1` statements originating from error-handling.sh itself.

**Implementation**:
1. Add check in `_log_bash_exit()` for errors originating from core libraries
2. Skip logging when:
   - Command is `return 1` or similar return statements
   - Source file is a core library (error-handling.sh, state-persistence.sh, etc.)
3. Consider using `BASH_SOURCE` array to identify library-origin errors

**Files**:
- `.claude/lib/core/error-handling.sh` - Update `_log_bash_exit()` function

**Code Pattern**:
```bash
# In _log_bash_exit():
# Check if error originates from core library
local source_file="${BASH_SOURCE[1]:-}"
if [[ "$failed_command" == "return "* ]] && [[ "$source_file" == *"/lib/core/"* ]]; then
  # Skip logging - intentional failure propagation from core library
  return
fi
```

**Verification**:
- [ ] Intentional returns from libraries no longer logged as errors
- [ ] Actual errors from libraries still logged appropriately

### Stage 2.3: Clean Up Diagnostic Code

**Description**: Remove all temporary diagnostic logging added in Phase 1.

**Implementation**:
1. Remove all DEBUG lines from error-handling.sh
2. Verify no performance impact from changes
3. Run linter to ensure code standards compliance

**Files**:
- `.claude/lib/core/error-handling.sh` - Remove DEBUG lines

**Verification**:
- [ ] No DEBUG output in normal operation
- [ ] All linters pass: `bash .claude/scripts/validate-all-standards.sh --sourcing`

**Success Criteria for Phase 2**:
- [ ] Benign /etc/bashrc errors filtered (exit code 127)
- [ ] Library return statements not logged as errors
- [ ] All existing tests still pass
- [ ] No regressions in error logging for actual errors

---

## Phase 3: Verify and Validate

**Objective**: Confirm fixes work across all affected commands

**Dependencies**: Phase 2 complete

### Stage 3.1: Run Unit Tests

**Description**: Execute all unit tests for error handling.

**Implementation**:
1. Run benign error filter tests
2. Run error logging tests
3. Verify no regressions

**Commands**:
```bash
bash .claude/tests/unit/test_benign_error_filter.sh
bash .claude/scripts/validate-all-standards.sh --all
```

**Verification**:
- [ ] All unit tests pass
- [ ] All validators pass

### Stage 3.2: Integration Test Across Commands

**Description**: Test fix effectiveness across multiple commands.

**Implementation**:
1. Run `/research` command with test input
2. Run `/plan` command with test input
3. Run `/build --dry-run` command
4. Check error log for absence of benign errors

**Test Commands**:
```bash
# Run commands that previously generated errors
/research "test research"
/plan "test plan" --complexity 1

# Check error log - should have no new benign errors
tail -20 .claude/data/logs/errors.jsonl | grep -c "etc/bashrc"
# Expected: 0
```

**Verification**:
- [ ] No new `/etc/bashrc` errors in log after running commands
- [ ] No new `return 1` library errors in log
- [ ] Actual errors still logged correctly

### Stage 3.3: Document Changes

**Description**: Update relevant documentation with changes made.

**Implementation**:
1. Update error handling documentation if filter behavior changed
2. Add notes to error-handling.sh inline comments
3. Create implementation summary

**Files**:
- `.claude/specs/913_911_research_error_analysis_repair/summaries/001_implementation_summary.md`

**Verification**:
- [ ] Implementation summary documents all changes
- [ ] Inline comments updated in modified code

**Success Criteria for Phase 3**:
- [ ] All tests pass
- [ ] No benign errors logged during command execution
- [ ] Implementation documented

---

## Rollback Procedures

### Phase 1 Rollback [COMPLETE]
- Remove any diagnostic code added to error-handling.sh
- Revert to previous version: `git checkout HEAD -- .claude/lib/core/error-handling.sh`

### Phase 2 Rollback [COMPLETE]
- If filter changes cause issues: `git checkout HEAD -- .claude/lib/core/error-handling.sh`
- If partial fix needed: Revert only specific function changes

### Full Rollback
```bash
# Reset error-handling.sh to last known good state
git checkout HEAD -- .claude/lib/core/error-handling.sh

# Verify rollback
bash .claude/tests/unit/test_benign_error_filter.sh
```

---

## Success Criteria Summary

| Phase | Criteria | Measurement |
|-------|----------|-------------|
| Phase 1 | Root cause identified | Documented evidence of why filter fails |
| Phase 2 | Filters updated | Zero benign errors in test runs |
| Phase 3 | Cross-command validation | All commands run without logging noise |

**Overall Success**: Zero `/etc/bashrc` exit code 127 errors and zero library `return 1` errors logged after running /research, /plan, /build, /debug commands.

---

## Estimated Timeline

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1 | 1-2 hours | None |
| Phase 2 | 2-4 hours | Phase 1 |
| Phase 3 | 1-2 hours | Phase 2 |
| **Total** | **4-8 hours** | Sequential |

---

## References

- Original Error Report: `.claude/specs/911_research_error_analysis/reports/001_error_report.md`
- Repair Analysis: `.claude/specs/913_911_research_error_analysis_repair/reports/001_repair_analysis.md`
- Error Handling Library: `.claude/lib/core/error-handling.sh`
- Benign Error Filter Tests: `.claude/tests/unit/test_benign_error_filter.sh`
- Error Log: `.claude/data/logs/errors.jsonl`
