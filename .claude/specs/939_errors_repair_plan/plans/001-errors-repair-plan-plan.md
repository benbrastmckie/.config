# /plan Errors Repair Implementation Plan

## Metadata
- **Date**: 2025-11-23
- **Feature**: Repair /plan command error patterns
- **Scope**: Fix 6 identified error patterns affecting /plan command reliability
- **Estimated Phases**: 4
- **Estimated Hours**: 12
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 44.5
- **Research Reports**:
  - [Error Analysis Report](../reports/001_error_analysis.md)

## Overview

This plan addresses 6 error patterns identified in the `/plan` command error analysis, totaling 23 errors over a 3-day period. The most critical issues are topic naming agent reliability (17% of errors) and library sourcing order issues (13% of errors), while benign environment errors (52%) pollute the error logs and reduce signal-to-noise ratio.

**Goals**:
1. Eliminate production errors from topic naming agent failures
2. Fix library sourcing order to prevent `append_workflow_state` exit 127 errors
3. Filter benign bashrc/profile sourcing errors from error logs
4. Make research_topics validation optional in classification parsing
5. Enable filtering of test workflow errors in /errors command

## Research Summary

The error analysis report identified the following patterns requiring fixes:

- **Pattern 1 (30%)**: Test agent validation failures - expected test behavior, low priority
- **Pattern 2 (17%)**: Topic naming agent failures - production impact, high priority
- **Pattern 3 (22%)**: Bashrc sourcing errors (exit 127) - benign, filter needed
- **Pattern 4 (13%)**: Missing workflow state functions - high priority
- **Pattern 5 (9%)**: Research topics parsing errors - medium priority
- **Pattern 6 (9%)**: Generic validation/execution errors - symptoms of upstream issues

**Root Causes**:
1. Topic naming agent reliability - no retry logic, poor timeout handling
2. Library sourcing order dependencies - state-persistence.sh not sourced early enough
3. Benign errors polluting logs - no filtering for environment-specific errors

## Success Criteria

- [ ] Topic naming agent failures reduced to <2% of /plan errors (from 17%)
- [ ] Zero `append_workflow_state` exit 127 errors in production
- [ ] Bashrc sourcing errors (exit 127 with `. /etc/bashrc`) filtered from logs
- [ ] research_topics validation gracefully handles empty arrays
- [ ] Test workflow errors can be filtered from /errors reports
- [ ] All existing tests pass after changes
- [ ] New unit tests added for benign error filtering patterns

## Technical Design

### Architecture Overview

The repair involves modifications to 4 key subsystems:

```
error-handling.sh          - Add bashrc filtering to _is_benign_bash_error()
                           - Add test workflow ID filtering support

topic-utils.sh             - Add retry logic for topic naming
unified-location-detection.sh - Ensure robust fallback for naming failures

plan.md                    - Audit library sourcing order
                           - Add defensive function existence checks

errors.md                  - Add --exclude-tests flag for filtering
```

### Key Design Decisions

1. **Retry Strategy**: 3 retries with 2s exponential backoff (2s, 4s, 8s) for topic naming agent
2. **Fallback Naming**: Use timestamp-based naming (`no_name_<timestamp>`) when retries exhausted
3. **Benign Filter Location**: Add patterns to `_is_benign_bash_error()` in error-handling.sh
4. **Test Workflow ID Convention**: Prefix test workflow IDs with `test_` for filtering

## Implementation Phases

### Phase 1: Benign Error Filtering [NOT STARTED]
dependencies: []

**Objective**: Filter bashrc/profile sourcing errors and test workflow errors from logs

**Complexity**: Low

Tasks:
- [ ] Add `. /etc/bashrc` pattern to _is_benign_bash_error() in `.claude/lib/core/error-handling.sh`
- [ ] Add `source /etc/bashrc` pattern to benign error filter
- [ ] Add `source ~/.bashrc` pattern to benign error filter
- [ ] Add `. /etc/bash.bashrc` pattern to benign error filter
- [ ] Update test_benign_error_filter.sh with tests for new patterns
- [ ] Run existing benign error filter tests to verify no regressions

Testing:
```bash
# Run benign error filter unit tests
bash /home/benjamin/.config/.claude/tests/unit/test_benign_error_filter.sh
```

**Expected Duration**: 2 hours

### Phase 2: Library Sourcing Order Audit [NOT STARTED]
dependencies: []

**Objective**: Fix library sourcing order in /plan command to prevent exit 127 errors

**Complexity**: Medium

Tasks:
- [ ] Audit all bash blocks in `.claude/commands/plan.md` for sourcing order
- [ ] Identify any bash blocks missing state-persistence.sh sourcing
- [ ] Add defensive `type -t append_workflow_state` check before calling workflow functions
- [ ] Verify CLAUDE_LIB path is set correctly in all code paths before library sourcing
- [ ] Add function existence validation using `validate_library_functions` utility
- [ ] Test sourcing order changes manually with a test /plan invocation

Testing:
```bash
# Verify function existence check pattern works
bash -c '
source /home/benjamin/.config/.claude/lib/core/state-persistence.sh 2>/dev/null || exit 1
type -t append_workflow_state >/dev/null 2>&1 && echo "Function exists" || echo "Function missing"
'
```

**Expected Duration**: 3 hours

### Phase 3: Topic Naming Agent Reliability [NOT STARTED]
dependencies: [1, 2]

**Objective**: Implement retry logic and timeout handling for topic naming agent

**Complexity**: Medium

Tasks:
- [ ] Locate topic naming invocation code in `.claude/lib/core/unified-location-detection.sh`
- [ ] Add retry loop (3 attempts) with exponential backoff (2s, 4s, 8s) around agent invocation
- [ ] Implement 30s timeout for each agent invocation attempt
- [ ] Add logging of retry attempts for debugging (non-error, info level)
- [ ] Implement fallback to timestamp-based naming when retries exhausted
- [ ] Update validate_topic_name_format() error messages to indicate retry exhaustion
- [ ] Add unit test for retry mechanism (mocked agent failures)

Testing:
```bash
# Run topic naming integration tests
bash /home/benjamin/.config/.claude/tests/topic-naming/test_topic_naming_integration.sh
bash /home/benjamin/.config/.claude/tests/topic-naming/test_topic_naming_agent.sh
```

**Expected Duration**: 4 hours

### Phase 4: Classification Validation and Test Filtering [NOT STARTED]
dependencies: [1]

**Objective**: Make research_topics optional and add test workflow filtering

**Complexity**: Low

Tasks:
- [ ] Locate research_topics validation in classification parsing code
- [ ] Update validation to check for topic_directory_slug only (not require research_topics)
- [ ] Add default research topic generation from slug if array is empty
- [ ] Add `--exclude-tests` flag to `.claude/commands/errors.md`
- [ ] Implement workflow ID prefix filtering (exclude `test_*` workflows)
- [ ] Update /errors command documentation with new flag
- [ ] Add test for --exclude-tests filtering behavior

Testing:
```bash
# Run classification tests
bash /home/benjamin/.config/.claude/tests/classification/test_scope_detection.sh
# Manual test of --exclude-tests flag
/errors --since 1h --exclude-tests
```

**Expected Duration**: 3 hours

## Testing Strategy

### Unit Tests
1. **Benign Error Filter Tests**: Verify new patterns are correctly filtered
2. **Topic Naming Retry Tests**: Mock agent failures to verify retry behavior
3. **Classification Validation Tests**: Verify empty research_topics handling

### Integration Tests
1. **End-to-End /plan Test**: Run `/plan "test feature"` and verify no errors logged
2. **Topic Naming Fallback Test**: Trigger naming failure and verify fallback naming
3. **Error Filtering Test**: Verify bashrc errors not appearing in error logs

### Regression Tests
- All existing tests in `.claude/tests/` must pass
- Run `bash /home/benjamin/.config/.claude/tests/run_all_tests.sh` before and after changes

## Documentation Requirements

- [ ] Update `.claude/docs/troubleshooting/plan-command-errors.md` with new error patterns
- [ ] Update `.claude/docs/guides/commands/errors-command-guide.md` with --exclude-tests flag
- [ ] Update `.claude/docs/concepts/patterns/error-handling.md` with benign filter patterns

## Dependencies

### External Dependencies
- None (all changes are internal to .claude/ system)

### Internal Dependencies
- error-handling.sh (benign error filter changes)
- state-persistence.sh (function existence checks)
- unified-location-detection.sh (topic naming retry logic)
- plan.md (sourcing order audit)
- errors.md (test filtering flag)

### Prerequisites
- Current tests pass (baseline validation)
- Error logs accessible for verification
