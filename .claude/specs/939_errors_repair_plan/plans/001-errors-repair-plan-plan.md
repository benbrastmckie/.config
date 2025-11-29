# /plan Errors Repair Implementation Plan

## Metadata
- **Date**: 2025-11-29
- **Feature**: Repair /plan command errors from error log analysis
- **Scope**: Fix agent failures, library sourcing issues, state management, environment portability, and validation errors
- **Estimated Phases**: 6
- **Estimated Hours**: 12
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 42.0
- **Research Reports**:
  - [Error Analysis Report 001](../reports/001_error_analysis.md)
  - [Error Analysis Report 001-error-report](../reports/001-error-report.md)
  - [Console Output Error Analysis Report 002](../reports/002_plan_console_output_errors_analysis.md)

## Overview

This repair plan addresses 23 logged errors from the `/plan` command spanning November 21-24, 2025, plus 8 console error occurrences from actual /plan command executions. Analysis reveals four primary failure modes: agent output file failures (47%, 11 logged errors), bash execution errors (39%, 9 logged errors + 4 console errors), state management failures (25%, 2 console errors with critical state file mismatch finding), validation errors (9%, 2 logged errors), and parse errors (4%, 1 logged error).

**Critical Finding**: Console analysis revealed that workflows use a shared state file path, causing concurrent workflows to overwrite each other's state (WORKFLOW_ID mismatch: plan_1764450496 in state file when current workflow is plan_1764450069). This state file mismatch is a root cause for 37.5% of console errors.

The plan implements targeted fixes for each root cause while following the project's error status tracking workflow, with enhanced focus on state file scoping, library sourcing compliance, and early-exit validation patterns.

## Research Summary

Three research reports analyzed 23 logged errors and 8 console output error occurrences:

**Agent Failures (47% of logged errors)**:
- Test agent timeout failures (7 errors): Agent not creating expected output files within 1s timeout
- Topic naming agent failures (4 errors): LLM-based Haiku agent failing with "agent_no_output_file" fallback

**Bash Execution Errors (39% of logged errors, 50% of console errors)**:
- Missing /etc/bashrc file (5 logged errors): Hardcoded sourcing of non-existent file (exit code 127)
- Undefined append_workflow_state function (3 logged errors): State persistence library not properly sourced
- validate_workflow_id command not found (2 console errors): Function called before library sourcing
- FEATURE_DESCRIPTION unbound variable (2 console errors): Variable referenced before initialization
- Generic execution failures (1 logged error): Upstream validation issues

**State Management Failures (25% of console errors, newly identified)**:
- PLAN_PATH not found in state (1 console error): State file read failure
- Failed to restore WORKFLOW_ID for validation (1 console error): State validation failure
- State file mismatch (critical finding): Console output 1 shows WORKFLOW_ID="plan_1764450496" in state file but current workflow is plan_1764450069, indicating shared state file causing conflicts between concurrent workflows

**Data Quality Errors (13% of logged errors)**:
- Empty research_topics arrays (2 validation errors, 1 parse error): Agent returning incomplete classification results

**Key Findings from Console Analysis (Report 002)**:
- 37.5% of console errors relate to state file operations (PLAN_PATH missing, WORKFLOW_ID mismatch, validate_workflow_id unavailable)
- State file mismatch is a **critical root cause**: workflows overwrite each other's state when using shared state file path
- Cascading error chains: library sourcing failures trigger multiple downstream errors (validate_workflow_id not found → local keyword error → exit_code unbound)
- Graceful degradation observed: console output 1 completed successfully despite state errors via manual intervention

The reports recommend a prioritized fix strategy focusing on high-impact improvements: **state file scoping** (eliminates state conflicts), **library sourcing compliance** (prevents cascading failures, addresses 62.5% of console errors), **environment portability** (22% logged error reduction), and **agent reliability enhancements** (47% logged error reduction).

## Success Criteria
- [ ] Zero /etc/bashrc sourcing errors (eliminate 5 errors, 22% reduction)
- [ ] Zero append_workflow_state undefined function errors (eliminate 3 errors, 13% reduction)
- [ ] Zero validate_workflow_id command not found errors (eliminate 2 errors from console outputs)
- [ ] Zero FEATURE_DESCRIPTION unbound variable errors (eliminate 2 errors from console outputs)
- [ ] Zero state file mismatch errors (WORKFLOW_ID validation prevents reading wrong workflow state)
- [ ] Concurrent /plan workflows run without state file conflicts (workflow-specific state files)
- [ ] All critical functions have early-exit availability checks after library sourcing
- [ ] Agent output validation captures stdout/stderr for debugging (11 agent errors become debuggable)
- [ ] Topic naming agent has retry logic with exponential backoff (4 errors become recoverable)
- [ ] research_topics validation allows optional fields (eliminate 3 errors, 13% reduction)
- [ ] All bash blocks in /plan command pass sourcing compliance linter
- [ ] Error log shows zero FIX_PLANNED errors for this repair plan after implementation
- [ ] At least 48-hour verification period with no error recurrence before marking RESOLVED

## Technical Design

### Architecture Overview

The repair plan targets five subsystems within the /plan command workflow:

1. **Environment Initialization Layer**: Replace hardcoded /etc/bashrc sourcing with conditional multi-path fallback
2. **Library Sourcing Layer**: Enforce three-tier sourcing pattern with fail-fast handlers for state-persistence.sh
3. **State Management Layer**: Implement workflow-specific state file scoping, WORKFLOW_ID validation, and concurrent workflow isolation
4. **Agent Invocation Layer**: Add stdout/stderr capture, output validation, and retry logic for all agent calls
5. **Data Validation Layer**: Update agent response schema validation to handle optional fields gracefully

### Component Interactions

```
/plan command initialization
  |
  ├─> [Phase 1] Environment Setup (conditional bashrc sourcing)
  |     └─> Graceful degradation if files missing
  |
  ├─> [Phase 2] Library Sourcing & State Management
  |     ├─> Source state-persistence.sh with fail-fast handlers
  |     ├─> Early-exit function availability checks
  |     ├─> Workflow-specific state file creation (workflow_plan_NNNN.sh)
  |     ├─> WORKFLOW_ID validation before state reads
  |     ├─> State file locking for concurrent workflow isolation
  |     └─> Variable initialization before use (FEATURE_DESCRIPTION)
  |
  ├─> [Phase 3] Agent Invocation (topic naming, classification)
  |     ├─> stdout/stderr capture
  |     ├─> Output file validation
  |     └─> Retry logic with exponential backoff
  |
  └─> [Phase 4] Response Validation (research_topics optional)
        └─> Schema validation with default generation
```

### Standards Compliance

- **Three-tier sourcing pattern**: All bash blocks source Tier 1 libraries (state-persistence.sh, error-handling.sh) with fail-fast handlers
- **Error logging integration**: All fixes update error log status (FIX_IN_PROGRESS → FIX_DEPLOYED → RESOLVED)
- **Clean-break development**: Replace broken patterns entirely, no backward compatibility wrappers
- **Output formatting**: Suppress library sourcing with `2>/dev/null` while preserving error handlers

## Implementation Phases

### Phase 1: Fix Environment Portability Issues [COMPLETE]
dependencies: []

**Objective**: Eliminate /etc/bashrc sourcing errors by implementing conditional multi-path fallback

**Complexity**: Low

Tasks:
- [x] Search codebase for all hardcoded `. /etc/bashrc` or `source /etc/bashrc` occurrences (file: .claude/commands/plan.md, .claude/lib/core/*.sh)
- [x] Replace with conditional sourcing pattern: `[ -f /etc/bashrc ] && . /etc/bashrc 2>/dev/null || true`
- [x] Alternatively implement multi-path fallback: `/etc/bashrc`, `/etc/bash.bashrc`, `~/.bashrc`
- [x] Verify graceful degradation on systems without any bashrc files
- [x] Document environment file sourcing strategy in code comments

Testing:
```bash
# Test on system without /etc/bashrc
rm /etc/bashrc 2>/dev/null || true
bash .claude/commands/plan.md <<< "test feature description"
# Should not produce exit code 127 errors

# Verify no new errors logged
tail -1 .claude/data/logs/errors.jsonl | jq -r '.error_type, .error_message'
```

**Expected Duration**: 1 hour

---

### Phase 2: Fix Library Sourcing Compliance and State Management [COMPLETE]
dependencies: [1]

**Objective**: Ensure state-persistence.sh is properly sourced before append_workflow_state usage, add state file scoping, and implement early-exit validation

**Complexity**: High

Tasks:
- [x] Audit all bash blocks in .claude/commands/plan.md for library sourcing order
- [x] Add state-persistence.sh sourcing at top of each bash block: `source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || { echo "Error: Cannot load state library"; exit 1; }`
- [x] Add early-exit function availability checks after library sourcing: verify critical functions (validate_workflow_id, append_workflow_state, get_state_var) are available before proceeding
- [x] Implement function availability validation loop:
  ```bash
  for func in validate_workflow_id append_workflow_state get_state_var; do
    type -t "$func" >/dev/null 2>&1 || { echo "Error: Required function '$func' not available"; exit 1; }
  done
  ```
- [x] Add WORKFLOW_ID validation before reading state file: verify WORKFLOW_ID in state matches current workflow to detect state file mismatches
- [x] Implement workflow-specific state file path scoping: use workflow-scoped filenames (e.g., workflow_plan_NNNNNNNNNN.sh) instead of shared state file
- [x] Add state file locking mechanism to prevent race conditions when multiple /plan workflows run concurrently
- [x] Verify CLAUDE_LIB environment variable is set in all execution contexts
- [x] Add fail-fast handlers for all Tier 1 library sourcing (error-handling.sh, workflow-state-machine.sh)
- [x] Run sourcing compliance linter: `bash .claude/scripts/validate-all-standards.sh --sourcing`
- [x] Fix any linter violations identified

Testing:
```bash
# Test library sourcing order
bash .claude/commands/plan.md <<< "test feature description"

# Verify append_workflow_state is called successfully (no exit 127)
grep -c "append_workflow_state" .claude/data/logs/errors.jsonl | grep -q "^0$" || echo "FAIL: Still have sourcing errors"

# Run linter to verify compliance
bash .claude/scripts/validate-all-standards.sh --sourcing --files .claude/commands/plan.md
# Should exit 0 with no ERROR-level violations

# Test state file isolation with concurrent workflows
/plan "authentication feature" &
WORKFLOW_1_PID=$!
sleep 2  # Stagger start
/plan "logging feature" &
WORKFLOW_2_PID=$!
wait $WORKFLOW_1_PID $WORKFLOW_2_PID

# Verify no state file mismatch errors
grep -c "state file mismatch" .claude/data/logs/errors.jsonl | grep -q "^0$" || echo "FAIL: State file conflicts detected"

# Test WORKFLOW_ID validation
# Start workflow and verify state file contains correct WORKFLOW_ID
WORKFLOW_ID=$(grep "^export WORKFLOW_ID=" .claude/tmp/workflow_plan_*.sh | head -1 | cut -d= -f2 | tr -d '"')
echo "State file WORKFLOW_ID: $WORKFLOW_ID"
# Should match the actual workflow being executed
```

**Expected Duration**: 4 hours

---

### Phase 3: Enhance Agent Output Validation [COMPLETE]
dependencies: [2]

**Objective**: Add stdout/stderr capture and detailed error reporting for agent invocations

**Complexity**: High

Tasks:
- [x] Identify all agent invocation points in .claude/commands/plan.md (test-agent, topic naming agent, classification agent)
- [x] Create temporary files for stdout/stderr capture: `AGENT_STDOUT=$(mktemp)` and `AGENT_STDERR=$(mktemp)`
- [x] Modify agent invocations to redirect: `invoke_agent > "$AGENT_STDOUT" 2> "$AGENT_STDERR"`
- [x] Add validation after agent execution: `[ -f "$EXPECTED_OUTPUT_FILE" ] || log_agent_failure`
- [x] Implement log_agent_failure function that logs captured stdout/stderr to error log
- [x] Add agent execution timing: `START_TIME=$(date +%s)` before invocation, calculate duration after
- [x] Add cleanup trap: `trap 'rm -f "$AGENT_STDOUT" "$AGENT_STDERR"' EXIT`
- [x] Test with intentional agent failure to verify error context is captured

Testing:
```bash
# Test agent failure scenario
# Temporarily rename agent file to trigger failure
mv .claude/agents/topic-naming-agent.md .claude/agents/topic-naming-agent.md.backup
bash .claude/commands/plan.md <<< "test feature description"

# Verify error log contains stdout/stderr context
tail -1 .claude/data/logs/errors.jsonl | jq -r '.error_details' | grep -q "agent_stdout\|agent_stderr" && echo "PASS: Context captured" || echo "FAIL: No context"

# Restore agent file
mv .claude/agents/topic-naming-agent.md.backup .claude/agents/topic-naming-agent.md
```

**Expected Duration**: 3 hours

---

### Phase 4: Implement Agent Retry Logic [COMPLETE]
dependencies: [3]

**Objective**: Add retry mechanism with exponential backoff for transient agent failures

**Complexity**: Medium

Tasks:
- [x] Create retry_agent_invocation function with parameters: max_retries=2, base_delay=2s
- [x] Implement exponential backoff: delay = base_delay * (2 ^ attempt_number)
- [x] Wrap topic naming agent invocation in retry logic
- [x] Wrap classification agent invocation in retry logic
- [x] Log retry attempts with context: `log_command_error "agent_retry" "Retrying agent (attempt $ATTEMPT/$MAX_RETRIES)"`
- [x] Add health check before first invocation: verify agent file exists and is readable
- [x] Test retry logic with simulated transient failures

Testing:
```bash
# Test retry logic with intermittent failure
# Create wrapper script that fails first time, succeeds second time
cat > /tmp/flaky_agent.sh << 'EOF'
#!/bin/bash
if [ ! -f /tmp/agent_attempt_marker ]; then
  touch /tmp/agent_attempt_marker
  exit 1  # Fail first attempt
fi
rm /tmp/agent_attempt_marker
echo "success"  # Succeed second attempt
EOF
chmod +x /tmp/flaky_agent.sh

# Run retry logic
retry_agent_invocation /tmp/flaky_agent.sh
# Should succeed after 1 retry

# Verify retry was logged
grep -c "agent_retry" .claude/data/logs/errors.jsonl
# Should show at least 1 retry log entry
```

**Expected Duration**: 2 hours

---

### Phase 5: Fix Agent Response Schema Validation [COMPLETE]
dependencies: [2]

**Objective**: Update validation to handle optional research_topics field gracefully

**Complexity**: Low

Tasks:
- [x] Locate classification agent response parsing in .claude/commands/plan.md
- [x] Update validation to check only topic_directory_slug as required field
- [x] Make research_topics optional: `RESEARCH_TOPICS=$(echo "$RESULT" | jq -r '.research_topics // []')`
- [x] Implement default research topics generation if array is empty: generate 3 topics from feature description using word extraction
- [x] Update agent prompt to include example response with all fields (topic_directory_slug, research_topics)
- [x] Add JSON schema validation using jq before parsing
- [x] Remove parse_error logging for empty research_topics (it's now expected)

Testing:
```bash
# Test with classification result containing empty research_topics
CLASSIFICATION_RESULT='{"topic_directory_slug": "test_feature", "research_topics": []}'

# Parse and validate
SLUG=$(echo "$CLASSIFICATION_RESULT" | jq -r '.topic_directory_slug')
TOPICS=$(echo "$CLASSIFICATION_RESULT" | jq -r '.research_topics // []')

# Should not log validation_error or parse_error
[ -n "$SLUG" ] && echo "PASS: Slug extracted" || echo "FAIL: Missing slug"

# Verify default topics generation
[ "$(echo "$TOPICS" | jq length)" -eq 0 ] && echo "Generating defaults..." || echo "Using provided topics"
```

**Expected Duration**: 1 hour

---

### Phase 6: Update Error Log Status [COMPLETE]
dependencies: [1, 2, 3, 4, 5]

**Objective**: Update error log entries from FIX_PLANNED to RESOLVED

**Complexity**: Low

Tasks:
- [x] Verify all fixes are working (tests pass, no new errors generated)
- [x] Update error log entries to RESOLVED status:
  ```bash
  source .claude/lib/core/error-handling.sh
  RESOLVED_COUNT=$(mark_errors_resolved_for_plan "${PLAN_PATH}")
  echo "Resolved $RESOLVED_COUNT error log entries"
  ```
- [x] Verify no FIX_PLANNED errors remain for this plan:
  ```bash
  REMAINING=$(query_errors --status FIX_PLANNED | jq -r '.repair_plan_path' | grep -c "$(basename "$(dirname "$(dirname "${PLAN_PATH}")")" )" || echo "0")
  [ "$REMAINING" -eq 0 ] && echo "All errors resolved" || echo "WARNING: $REMAINING errors still FIX_PLANNED"
  ```
- [x] Run /plan command with test feature description to verify no errors logged
- [x] Monitor error log for 48 hours to confirm no recurrence before final RESOLVED status

Testing:
```bash
# Verify error status updates
source .claude/lib/core/error-handling.sh
query_errors --status RESOLVED | jq -r 'select(.repair_plan_path | contains("939_errors_repair_plan")) | .error_id' | wc -l
# Should show count matching original 23 errors

# Test /plan command end-to-end
bash .claude/commands/plan.md <<< "test authentication feature"
# Should complete without errors

# Check error log for new entries
ERROR_COUNT=$(tail -20 .claude/data/logs/errors.jsonl | jq -r 'select(.command == "/plan") | .error_type' | wc -l)
[ "$ERROR_COUNT" -eq 0 ] && echo "PASS: No new errors" || echo "FAIL: $ERROR_COUNT new errors logged"
```

**Expected Duration**: 1 hour

## Testing Strategy

### Unit Testing
- Test each fix in isolation using bash script execution
- Verify error conditions are handled gracefully (missing files, undefined functions)
- Test with both success and failure scenarios for agent invocations

### Integration Testing
- Run /plan command end-to-end with real feature descriptions
- Test on systems with and without /etc/bashrc to verify portability
- Verify error log entries are created/updated correctly throughout workflow

### Validation Testing
- Run all sourcing compliance linters: `bash .claude/scripts/validate-all-standards.sh --sourcing`
- Verify no ERROR-level violations in .claude/commands/plan.md
- Query error log for /plan errors: `/errors --command /plan --since 48h`
- Confirm zero new errors during 48-hour verification period

### Test Commands
```bash
# Pre-implementation baseline
/errors --command /plan --since 7d --summary

# Post-implementation verification
bash .claude/scripts/validate-all-standards.sh --sourcing --files .claude/commands/plan.md
/errors --command /plan --since 48h --summary

# Agent validation
bash .claude/commands/plan.md <<< "complex feature description with many details to test topic naming agent"

# Stress test
for i in {1..10}; do
  bash .claude/commands/plan.md <<< "test feature $i"
done
grep -c '"command":"/plan"' .claude/data/logs/errors.jsonl
```

## Documentation Requirements

### Code Comments
- Add inline comments explaining conditional bashrc sourcing rationale (file: .claude/commands/plan.md)
- Document workflow-specific state file path scoping mechanism (file: .claude/commands/plan.md)
- Explain WORKFLOW_ID validation logic and state file mismatch detection (file: .claude/commands/plan.md)
- Document early-exit function availability check pattern (file: .claude/commands/plan.md)
- Document retry logic parameters and backoff calculation (file: .claude/commands/plan.md)
- Explain research_topics optional field handling (file: .claude/commands/plan.md)

### Standards Updates
- Document environment file sourcing strategy in Code Standards (file: .claude/docs/reference/standards/code-standards.md)
- Add state file scoping pattern for concurrent workflow isolation (file: .claude/docs/reference/standards/code-standards.md or state management docs)
- Document early-exit function availability validation pattern (file: .claude/docs/reference/standards/code-standards.md)
- Add agent retry pattern to Error Handling Pattern docs (file: .claude/docs/concepts/patterns/error-handling.md)
- Update agent invocation best practices with stdout/stderr capture (file: .claude/docs/concepts/hierarchical-agents-communication.md)

### Troubleshooting Guide Updates
- Add "Missing append_workflow_state function" to common errors (file: .claude/docs/troubleshooting/common-errors.md if exists)
- Document agent output file failures and debugging steps (file: .claude/docs/troubleshooting/agent-failures.md if exists)

## Dependencies

### External Dependencies
- jq (JSON processing): Required for agent response parsing and validation
- bash 4.0+: Required for associative arrays in retry logic
- mktemp: Required for creating temporary stdout/stderr capture files

### Internal Dependencies
- .claude/lib/core/state-persistence.sh: Must be sourced before workflow state functions
- .claude/lib/core/error-handling.sh: Required for error logging and status updates
- .claude/lib/core/unified-location-detection.sh: Required for artifact directory creation
- .claude/agents/topic-naming-agent.md: Must be present and invocable
- .claude/scripts/validate-all-standards.sh: Required for sourcing compliance validation

### Pre-requisites
- CLAUDE_LIB environment variable must be set correctly
- Error log file must exist: .claude/data/logs/errors.jsonl
- Write permissions to .claude/commands/plan.md for implementing fixes
- Read permissions to all agent files for validation

## Risk Mitigation

### Risk 1: Breaking Existing Functionality
- **Mitigation**: Test all changes in isolation before integration
- **Rollback Plan**: Keep backup of original .claude/commands/plan.md before modifications
- **Verification**: Run full /plan workflow after each phase to detect regressions early

### Risk 2: Agent Retry Logic Causing Delays
- **Mitigation**: Keep max_retries=2 and base_delay=2s to limit total retry time to ~6s max
- **Monitoring**: Log all retry attempts to detect if retries are frequent (indicates upstream issues)
- **Adjustment**: If retries become common, investigate root cause rather than increasing retry limit

### Risk 3: State File Scoping Breaking Existing Workflows
- **Mitigation**: Implement backward-compatible state file discovery (check workflow-specific path first, fall back to legacy shared path)
- **Verification**: Test with workflows that expect legacy state file behavior to ensure graceful migration
- **Rollback Plan**: Keep legacy state file path logic as fallback option if workflow-specific scoping causes issues

### Risk 4: Concurrent Workflow Locking Causing Deadlocks
- **Mitigation**: Implement timeout-based lock acquisition (max 30s wait) with clear error messaging
- **Monitoring**: Log all lock acquisitions and releases to detect potential deadlock patterns
- **Adjustment**: If lock timeouts occur frequently, investigate workflow overlap patterns and adjust locking granularity

### Risk 5: Incomplete Error Log Status Updates
- **Mitigation**: Use transaction-like pattern - verify all errors updated before marking RESOLVED
- **Verification**: Query error log for FIX_PLANNED status before and after updates
- **Fallback**: Manual error status updates via error-handling.sh functions if automated update fails

## Estimated Effort

- **Total Hours**: 12 hours
- **Complexity Distribution**:
  - Low complexity: 3 hours (Phases 1, 5, 6)
  - Medium complexity: 2 hours (Phase 4)
  - High complexity: 7 hours (Phases 2, 3)
- **Verification Period**: 48 hours after implementation (monitoring only, no active work)
- **Documentation**: Included in phase estimates
- **Effort Increase Rationale**: Phase 2 complexity increased from Medium to High due to addition of state file scoping, WORKFLOW_ID validation, concurrent workflow locking, and early-exit checks (added 2 hours to original 2-hour estimate)
