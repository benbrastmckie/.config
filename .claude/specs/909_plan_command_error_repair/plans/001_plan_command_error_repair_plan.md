# /plan Command Error Repair Implementation Plan

## Metadata
- **Date**: 2025-11-21
- **Feature**: /plan command error repair - fixing exit code 127 bash sourcing failures, state file naming inconsistency, and topic naming agent reliability issues
- **Scope**: Error handling infrastructure, agent output validation, benign error filtering, state file path standardization
- **Estimated Phases**: 6
- **Estimated Hours**: 12
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0 (expansion not anticipated - discrete fixes)
- **Complexity Score**: 48.5
- **Research Reports**:
  - [Error Analysis Report (908 spec)](../../908_plan_error_analysis/reports/001_plan_error_report.md)
  - [Plan Revision Analysis](../reports/002_plan_revision_analysis.md)

## Overview

This plan addresses 14 production errors logged for the `/plan` command (21 total, excluding 7 intentional test errors). The error distribution shows:
- **Exit code 127 (52.4%)**: Primarily from `/etc/bashrc` sourcing failures and `append_workflow_state` function not found
- **Agent errors (42.9%)**: Topic naming agent not creating output files reliably
- **Parse errors (4.8%)**: Classification result parsing failures
- **State file path errors**: `state_plan_*.sh` vs `workflow_plan_*.sh` naming inconsistency

The root causes have been identified:
1. `/etc/bashrc` sourcing errors are already filtered by the benign error filter in `error-handling.sh`, but some edge cases are still being logged
2. `append_workflow_state` "not found" errors indicate state-persistence.sh functions are not available when called in some execution contexts
3. Topic naming agent (Haiku model) timeout/reliability issues causing fallback to `no_name`
4. Classification agent returning incomplete JSON results
5. State file naming convention inconsistency between initialization (`workflow_plan_*.sh`) and lookup (`state_plan_*.sh`)

## Research Summary

Key findings from the error analysis report:

1. **Exit code 127 dominance**: 7 of 21 errors (33%) are exit code 127, split between `/etc/bashrc` sourcing (4) and `append_workflow_state` not found (3)
2. **Topic naming agent failures**: 6 errors (29%) from the Haiku agent not writing output files
3. **Existing filter inadequacy**: The `_is_benign_bash_error` function in error-handling.sh already filters `/etc/bashrc` errors, but some still get logged, suggesting the filter runs AFTER the error is captured
4. **Temporal clustering**: Errors cluster around active development sessions, not distributed uniformly

Recommended approach: Fix the error filtering to run earlier in the trap, improve topic naming agent timeout handling, and add function existence validation before calling state persistence functions.

## Success Criteria

- [ ] Exit code 127 errors from `/etc/bashrc` sourcing are not logged (filter working correctly)
- [ ] `append_workflow_state` function availability is validated before use
- [ ] State file path naming is consistent (`workflow_*.sh` everywhere)
- [ ] Topic naming agent output validation has retry logic with configurable timeout
- [ ] Classification result parsing handles missing/empty fields gracefully
- [ ] Error log noise reduced by >50% for production `/plan` executions (excluding intentional test errors)
- [ ] All existing tests pass after changes
- [ ] No new error types introduced

## Technical Design

### Architecture Overview

The fix involves three main components:

```
                    +-----------------------+
                    |   /plan Command       |
                    +-----------------------+
                              |
          +-------------------+-------------------+
          |                   |                   |
          v                   v                   v
+-------------------+ +-------------------+ +-------------------+
| error-handling.sh | | state-persistence | | topic-naming-agent|
| (Trap filtering)  | | (Function check)  | | (Output retry)    |
+-------------------+ +-------------------+ +-------------------+
          |                   |                   |
          v                   v                   v
+-------------------+ +-------------------+ +-------------------+
| Benign filter     | | validate_library  | | validate_agent    |
| runs at trap      | | _functions()      | | _output_with_retry|
| entry point       | | before use        | | (existing)        |
+-------------------+ +-------------------+ +-------------------+
```

### Key Design Decisions

1. **Filter location**: Move benign error check to earliest possible point in trap handler
2. **Function validation**: Use existing `validate_library_functions` before calling state persistence
3. **Agent retry**: Leverage existing `validate_agent_output_with_retry` with appropriate timeout
4. **Classification fallback**: Add default values for missing JSON fields

## Implementation Phases

### Phase 1: Improve Benign Error Filtering [COMPLETE]

**Dependencies**: []
**Risk**: Low
**Estimated Time**: 2 hours

**Objective**: Ensure `/etc/bashrc` sourcing errors and similar benign failures are filtered before being logged.

**Analysis**: The error analysis shows 4 occurrences of `/etc/bashrc` sourcing errors being logged despite the filter. Investigation needed to determine if these are logged BEFORE the filter runs or if the filter pattern doesn't match.

**Tasks**:
- [x] Analyze error log to confirm exact failed_command format for bashrc errors
- [x] Review `_is_benign_bash_error` function patterns in `error-handling.sh` (lines 1240-1269)
- [x] Verify filter is called at start of `_log_bash_error` (line 1287) - already in place
- [x] Test if issue is in EXIT trap handler `_log_bash_exit` - check line 1328
- [x] Add unit test to verify benign error filter works for all bashrc patterns
- [x] Verify filter works on NixOS where `/etc/bashrc` doesn't exist

**Testing**:
```bash
# Test benign error filter with simulated bashrc sourcing
cd /home/benjamin/.config && bash .claude/tests/unit/test_benign_error_filter.sh
```

---

### Phase 2: State Persistence Function Validation [COMPLETE]

**Dependencies**: [1]
**Risk**: Medium
**Estimated Time**: 2 hours

**Objective**: Ensure state persistence functions are validated as available before being called.

**Analysis**: 3 errors show `append_workflow_state` not found (exit 127). The `validate_library_functions` utility exists in state-persistence.sh (lines 514-566) but may not be called consistently.

**Tasks**:
- [x] Audit all bash blocks in `/plan` command for state-persistence function calls
- [x] Verify `validate_library_functions "state-persistence"` is called in Block 1a (line 150)
- [x] Add validation call to Block 1c before `append_workflow_state` calls (lines 521-534)
- [x] Add validation call to Block 2 before `append_workflow_state` calls (lines 760, 795-796)
- [x] Add validation call to Block 3 after library sourcing (line 871-882)
- [x] Create fallback behavior if validation fails (log error and exit gracefully)
- [x] Add defensive check before each `append_workflow_state` call:
  ```bash
  if declare -f append_workflow_state >/dev/null 2>&1; then
    append_workflow_state "KEY" "value"
  else
    echo "WARNING: append_workflow_state not available" >&2
  fi
  ```

**Testing**:
```bash
# Test that validation catches missing functions
cd /home/benjamin/.config && bash -c '
  source .claude/lib/core/state-persistence.sh 2>/dev/null || true
  validate_library_functions "state-persistence" && echo "PASS" || echo "FAIL"
'
```

---

### Phase 3: Topic Naming Agent Reliability [COMPLETE]

**Dependencies**: [1]
**Risk**: Medium
**Estimated Time**: 2 hours

**Objective**: Improve topic naming agent output reliability with better timeout handling and retry logic.

**Analysis**: 6 errors (29%) from topic naming agent failures. The agent is Haiku-based with <3s expected response time. Current validation uses `validate_agent_output_with_retry` with 2s timeout and 3 retries. Issues may be:
1. Haiku agent timing out before writing file
2. Write tool failing silently
3. Race condition between agent completion and validation

**Tasks**:
- [x] Review topic-naming-agent.md for output requirements (Step 4, lines 133-181)
- [x] Review `validate_agent_output_with_retry` implementation in error-handling.sh
- [x] Increase timeout from 2s to 5s for Haiku agent (allows full completion)
- [x] Add logging to capture WHY agent failed (timeout vs empty vs missing file)
- [x] Update Block 1b validation call in plan.md (line 341):
  ```bash
  # From: validate_agent_output_with_retry "topic-naming-agent" "$TOPIC_NAME_FILE" "validate_topic_name_format" 2 3
  # To:   validate_agent_output_with_retry "topic-naming-agent" "$TOPIC_NAME_FILE" "validate_topic_name_format" 5 3
  ```
- [x] Add diagnostic output when falling back to `no_name`:
  ```bash
  if [ "$TOPIC_NAME" = "no_name" ]; then
    echo "DEBUG: Topic naming agent fallback reason: $NAMING_STRATEGY" >&2
    echo "DEBUG: Expected file: $TOPIC_NAME_FILE" >&2
    ls -la "${HOME}/.claude/tmp/topic_name_"* 2>/dev/null || echo "DEBUG: No topic name files found" >&2
  fi
  ```

**Testing**:
```bash
# Test topic naming agent timeout behavior
cd /home/benjamin/.config && bash -c '
  WORKFLOW_ID="test_$(date +%s)"
  TOPIC_NAME_FILE="${HOME}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt"
  # Simulate agent writing output
  echo "test_topic_name" > "$TOPIC_NAME_FILE"
  # Validate
  source .claude/lib/core/error-handling.sh 2>/dev/null
  validate_agent_output "topic-naming-agent" "$TOPIC_NAME_FILE" 5 && echo "PASS" || echo "FAIL"
  rm -f "$TOPIC_NAME_FILE"
'
```

---

### Phase 4: Classification Result Parsing Hardening [COMPLETE]

**Dependencies**: [2]
**Risk**: Low
**Estimated Time**: 1.5 hours

**Objective**: Handle missing or empty fields in classification JSON gracefully.

**Analysis**: 1 parse error from `research_topics array empty or missing`. This indicates the classification agent returned valid JSON but with incomplete data.

**Tasks**:
- [x] Locate classification result parsing in workflow-initialization.sh
- [x] Add validation for `research_topics` field presence and non-empty
- [x] Add default fallback values when fields are missing:
  ```bash
  RESEARCH_TOPICS=$(echo "$CLASSIFICATION_JSON" | jq -r '.research_topics // ["general_analysis"]')
  ```
- [x] Add warning log when using fallback (not error, since we can continue)
- [x] Update `validate_and_generate_filename_slugs` function to handle edge cases
- [x] Add unit test for classification parsing with missing fields

**Testing**:
```bash
# Test classification parsing with missing fields
cd /home/benjamin/.config && bash -c '
  # Test with empty research_topics
  CLASSIFICATION_JSON='\''{"topic_directory_slug": "test_topic", "research_topics": []}'\''
  echo "$CLASSIFICATION_JSON" | jq -r '\''.research_topics // ["general_analysis"]'\''
'
```

---

### Phase 5: State File Path Standardization [COMPLETE]

**Dependencies**: [2]
**Risk**: Medium
**Estimated Time**: 2 hours

**Objective**: Standardize state file naming convention to prevent path lookup failures.

**Analysis**: The error output shows "State file not found: /home/benjamin/.claude/tmp/state_plan_*.sh" but the actual file is named `workflow_plan_*.sh`. This naming inconsistency causes workflow failures.

**Tasks**:
- [x] Audit state file initialization in `init_workflow_state()` (state-persistence.sh)
- [x] Audit state file lookup patterns in `/plan` command bash blocks
- [x] Standardize to use `workflow_*.sh` naming everywhere:
  - Initialization: `workflow_${COMMAND}_${WORKFLOW_ID}.sh`
  - Lookup: Same pattern
- [x] Update `STATE_ID_FILE` reference in plan.md:
  ```bash
  # From: STATE_ID_FILE="${HOME}/.claude/tmp/state_plan_*.txt"
  # To:   STATE_ID_FILE="${HOME}/.claude/tmp/plan_state_id.txt"
  ```
- [x] Verify `load_workflow_state()` uses consistent path
- [x] Add debug logging for state file path resolution
- [x] Update any hardcoded `state_` prefixes to `workflow_`

**Testing**:
```bash
# Test state file naming consistency
cd /home/benjamin/.config && bash -c '
  source .claude/lib/core/state-persistence.sh 2>/dev/null || exit 1
  WORKFLOW_ID="test_$(date +%s)"
  STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
  echo "Created: $STATE_FILE"
  # Verify the file exists where we expect it
  ls -la "$STATE_FILE" && echo "PASS" || echo "FAIL"
  rm -f "$STATE_FILE"
'
```

---

### Phase 6: Integration Testing and Validation [COMPLETE]

**Dependencies**: [1, 2, 3, 4, 5]
**Risk**: Low
**Estimated Time**: 2.5 hours

**Objective**: Verify all fixes work together and error rates are reduced.

**Analysis**: Final validation phase to ensure fixes are effective and no regressions introduced.

**Tasks**:
- [x] Run existing test suite to verify no regressions:
  ```bash
  cd /home/benjamin/.config && bash .claude/tests/utilities/run-tests.sh
  ```
- [x] Execute `/plan` command with test input to generate logs
- [x] Verify error log does not contain benign `/etc/bashrc` errors
- [x] Verify `append_workflow_state` errors are eliminated or logged with context
- [x] Verify state file path lookups succeed consistently
- [x] Verify topic naming agent fallback includes diagnostic info
- [x] Monitor error log for 24 hours after deployment
- [x] Document changes in troubleshooting guide
- [x] Update metrics baseline: count production errors only (exclude 7 test errors)

**Testing**:
```bash
# Full integration test
cd /home/benjamin/.config && bash -c '
  ERROR_LOG=".claude/data/logs/errors.jsonl"

  # Run /plan command (manual test)
  echo "Run: /plan \"test integration of error handling fixes\""
  echo "Then check production errors only:"
  echo "jq -s '\''[.[] | select(.command=="/plan") | select(.workflow_id | startswith(\"test_\") | not)] | length'\'' $ERROR_LOG"
'
```

## Testing Strategy

### Unit Tests
Each phase includes inline tests that verify individual component behavior:
1. Benign error filter pattern matching
2. Library function validation
3. State file path naming consistency
4. Agent output timeout handling
5. JSON parsing with missing fields

### Integration Tests
- End-to-end `/plan` command execution
- Error log analysis for noise reduction
- Fallback behavior verification
- State file lifecycle (create, lookup, load)

### Acceptance Criteria
- Error log noise reduced by >50% for production executions (excluding 7 test errors)
- No regression in existing functionality
- All bash blocks follow three-tier sourcing pattern
- State file naming uses consistent `workflow_*.sh` pattern

## Documentation Requirements

- [ ] Update `.claude/docs/troubleshooting/plan-command-errors.md` with new diagnostics
- [ ] Add inline comments explaining benign error filter logic
- [ ] Document topic naming agent timeout configuration
- [ ] Document state file naming convention (`workflow_${COMMAND}_${ID}.sh`)

## Dependencies

### External Dependencies
- jq (JSON parsing) - already installed
- bash 4.0+ (associative arrays, process substitution) - verified

### Internal Dependencies
- state-persistence.sh v1.5.0+ (required for validate_library_functions)
- error-handling.sh (benign error filter, agent output validation)
- workflow-initialization.sh (classification parsing)

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Filter too aggressive | Hides real errors | Add verbose mode for debugging |
| Timeout too long | Slow command execution | Make configurable via env var |
| Fallback hides issues | Mask agent problems | Add diagnostic logging |
| Breaking existing behavior | Command failures | Run full test suite |
| State file path refactor breaks workflows | Workflow failures | Update all consumers atomically |
| Metrics exclude valid errors | Under-counting | Clearly document test error patterns |

## Rollback Plan

If issues arise after implementation:
1. Revert error-handling.sh changes (benign filter)
2. Revert plan.md timeout changes
3. Revert state-persistence.sh naming changes
4. Monitor error log for improvements/regressions
5. Re-analyze error patterns if needed

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-21 | 1.0 | Initial plan created |
| 2025-11-21 | 1.1 | Added Phase 5 (state file path standardization), updated error counts to exclude test errors, fixed research report links, standardized phase header format per directory-protocols.md |
