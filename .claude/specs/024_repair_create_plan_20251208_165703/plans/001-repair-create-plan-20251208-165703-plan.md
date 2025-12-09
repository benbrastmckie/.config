# /create-plan Errors Repair Implementation Plan

## Metadata
- **Date**: 2025-12-08
- **Feature**: Fix /create-plan command errors from state persistence and agent validation issues
- **Status**: [COMPLETE]
- **Estimated Hours**: 4-6 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [create-plan errors repair](/home/benjamin/.config/.claude/specs/024_repair_create_plan_20251208_165703/reports/001-create-plan-errors-repair.md)

## Overview

This plan addresses 5 distinct error patterns in /create-plan command identified through error log analysis (14 total errors over 5 days). The issues stem from missing library sourcing, terminal state persistence, incomplete variable restoration, agent artifact validation timing, and overly strict section validation.

**Root Causes**:
1. **Missing three-tier sourcing** in Block 1d-topics-auto-validate (exit code 127)
2. **Terminal state persistence** blocking new workflow initialization (36% of errors)
3. **Incomplete state variable restoration** for PLAN_PATH between blocks
4. **Hard barrier timing** issues with agent artifact validation
5. **Inflexible validation** for research report section headers

**Success Criteria**:
- All Pattern 1 errors eliminated (exit code 127 for append_workflow_state)
- Terminal state transitions handled gracefully (workflow restart or state reset)
- PLAN_PATH variable persisted and restored correctly across blocks
- Agent artifacts validated with proper completion verification
- Research report validation accepts flexible section headers

## Implementation Phases

### Phase 1: Fix Missing Library Sourcing in Block 1d-topics-auto-validate [COMPLETE]

**Objective**: Add three-tier sourcing pattern for state-persistence.sh in Block 1d-topics-auto-validate to eliminate exit code 127 errors.

**Context**: Pattern 1 analysis shows append_workflow_state called without sourcing state-persistence.sh library, causing "command not found" error at line 288.

**Tasks**:
- [x] Locate Block 1d-topics-auto-validate in /create-plan command (around line 998)
- [x] Add state-persistence.sh sourcing after error-handling.sh
- [x] Use fail-fast pattern: `source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || { echo "ERROR: Cannot load state-persistence library" >&2; exit 1; }`
- [x] Add pre-flight function validation: `validate_library_functions "state-persistence" || exit 1`
- [x] Verify append_workflow_state calls appear AFTER library sourcing
- [x] Test with complexity >= 3 workflow to trigger topic detection block

**Validation**:
- Block 1d-topics-auto-validate sources state-persistence.sh before append_workflow_state calls
- Pre-flight validation catches missing functions early
- No exit code 127 errors for state persistence functions
- Error log shows no new execution_error entries for this block

**Files Modified**:
- `.claude/commands/create-plan.md` (Block 1d-topics-auto-validate bash block)

**Estimated Time**: 1 hour

---

### Phase 2: Implement State File Cleanup at Workflow Initialization [COMPLETE]

**Objective**: Add state file cleanup logic in Block 1a to handle terminal state persistence from previous workflow runs.

**Context**: Pattern 2 shows 4 errors (29%) from terminal state "complete" blocking new workflow initialization. State machine prevents transitions from terminal states, but stale state files persist across invocations.

**Tasks**:
- [x] Add state file detection in Block 1a after WORKFLOW_ID generation
- [x] Check if state file exists: `[ -f "${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh" ]`
- [x] Source existing state file to read CURRENT_STATE
- [x] Detect terminal states: `TERMINAL_STATES=("complete" "abandoned")`
- [x] If CURRENT_STATE is terminal, delete state file or reinitialize
- [x] Log state cleanup action to error log for monitoring
- [x] Leverage idempotent state transitions pattern from idempotent-state-transitions.md
- [x] Test with workflow that previously reached "complete" state

**Implementation Approach**:
```bash
# After WORKFLOW_ID generation in Block 1a
EXISTING_STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$EXISTING_STATE_FILE" ]; then
  source "$EXISTING_STATE_FILE" 2>/dev/null || true
  if [[ "${CURRENT_STATE:-}" =~ ^(complete|abandoned)$ ]]; then
    echo "Cleaning stale terminal state: $CURRENT_STATE"
    rm -f "$EXISTING_STATE_FILE"
  fi
fi
```

**Validation**:
- Workflows with existing "complete" state files start successfully
- Terminal state detection logs cleanup action
- No "cannot transition from terminal state" errors in error log
- State machine transitions from "initialize" normally

**Files Modified**:
- `.claude/commands/create-plan.md` (Block 1a bash block)

**Estimated Time**: 1.5 hours

---

### Phase 3: Verify PLAN_PATH State Persistence [COMPLETE]

**Objective**: Audit and fix PLAN_PATH variable persistence across bash blocks to eliminate missing variable errors.

**Context**: Pattern 3 shows PLAN_PATH not restored from Block 2 state, blocking Block 3 execution. This indicates incomplete append_workflow_state or restore_workflow_state implementation.

**Tasks**:
- [x] Search for PLAN_PATH assignment in Block 2 of /create-plan
- [x] Verify append_workflow_state "PLAN_PATH" "$PLAN_PATH" exists after assignment
- [x] Check state-persistence.sh is sourced in Block 2 before append_workflow_state
- [x] Verify Block 3 sources state file before reading PLAN_PATH
- [x] Add validation check in Block 3: `[ -n "${PLAN_PATH:-}" ] || { echo "ERROR: PLAN_PATH missing"; exit 1; }`
- [x] Add diagnostic logging for PLAN_PATH restoration
- [x] Test full workflow to verify PLAN_PATH available in all blocks

**Validation**:
- PLAN_PATH variable persisted in Block 2 state file
- Block 3 restores PLAN_PATH correctly from state
- Validation check catches missing PLAN_PATH early
- No "PLAN_PATH not restored" errors in error log

**Files Modified**:
- `.claude/commands/create-plan.md` (Blocks 2 and 3 bash blocks)

**Estimated Time**: 1 hour

---

### Phase 4: Add Agent Artifact Verification with Retry Logic [COMPLETE]

**Objective**: Implement polling verification for agent artifacts before hard barrier validation to handle agent completion timing.

**Context**: Pattern 4 shows 3 errors (21%) from agent artifacts not found at validation time. Hard barrier runs before agent completes file creation, or agent fails silently.

**Tasks**:
- [x] Identify agent artifact validation points in /create-plan (topic-naming, topic-detection, research-coordinator)
- [x] Add polling verification with 1s interval, max 10 attempts
- [x] Check agent Task tool completion signal before validation
- [x] Implement exponential backoff for agent file polling
- [x] Add error logging when agent fails without creating artifact
- [x] Surface agent stderr output for debugging
- [x] Test with slow network conditions to verify retry logic

**Implementation Approach**:
```bash
# Agent artifact polling (after Task tool invocation)
MAX_ATTEMPTS=10
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  if [ -f "$ARTIFACT_PATH" ]; then
    break
  fi
  ATTEMPT=$((ATTEMPT + 1))
  sleep 1
done

if [ ! -f "$ARTIFACT_PATH" ]; then
  log_command_error "..." "agent_error" "Agent artifact not created after ${MAX_ATTEMPTS}s"
  exit 1
fi
```

**Validation**:
- Agent artifacts validated with 10-second timeout
- Retry logic handles delayed agent file creation
- Agent stderr output surfaced in error logs
- No "file_not_found" errors for agent artifacts

**Files Modified**:
- `.claude/commands/create-plan.md` (Block 1b-exec, Block 1d-topics-auto-exec validation sections)

**Estimated Time**: 1.5 hours

---

### Phase 5: Update Research Report Section Validation [COMPLETE]

**Objective**: Modify Block 1f validation to accept flexible section headers (Executive Summary, Findings, Analysis) instead of hardcoded "## Findings".

**Context**: Pattern 5 shows validation expects "## Findings" but research-coordinator creates "## Executive Summary" instead, causing validation failures.

**Tasks**:
- [x] Locate Block 1f research report validation in /create-plan
- [x] Find exact match pattern for "## Findings" section
- [x] Replace with flexible regex: `^## (Findings|Executive Summary|Analysis)`
- [x] Document standard section names in research-coordinator.md behavioral file
- [x] Update validation error message to list accepted section headers
- [x] Add test case with "## Executive Summary" report format
- [x] Verify validation accepts all three section header variants

**Implementation Change**:
```bash
# Before (overly strict)
if ! grep -q "^## Findings" "$REPORT_FILE"; then
  echo "ERROR: Research report missing required ## Findings section"
fi

# After (flexible)
if ! grep -qE "^## (Findings|Executive Summary|Analysis)" "$REPORT_FILE"; then
  echo "ERROR: Research report missing required findings section (accepts: Findings, Executive Summary, Analysis)"
fi
```

**Validation**:
- Validation accepts "## Executive Summary" format
- Validation accepts "## Findings" format
- Validation accepts "## Analysis" format
- No validation_error log entries for valid reports
- Error message lists all accepted section header formats

**Files Modified**:
- `.claude/commands/create-plan.md` (Block 1f validation bash block)
- `.claude/agents/research-coordinator.md` (document standard section names)

**Estimated Time**: 0.5 hours

---

### Phase 6: Add State Persistence Linting to Pre-Commit Hooks [COMPLETE]

**Objective**: Create linter to detect state persistence function calls without proper sourcing, preventing future Pattern 1 errors.

**Context**: Exit code 127 errors indicate missing library sourcing. Pre-commit linting catches this at development time before commit.

**Tasks**:
- [x] Create `.claude/scripts/check-state-persistence-sourcing.sh` linter script
- [x] Scan bash blocks for append_workflow_state, restore_workflow_state, init_workflow_state calls
- [x] Verify `source "$CLAUDE_LIB/core/state-persistence.sh"` appears before function calls
- [x] Check validate_library_functions "state-persistence" pre-flight validation
- [x] Add to validate-all-standards.sh with ERROR severity
- [x] Integrate with pre-commit hooks
- [x] Test linter on /create-plan command (should pass after Phase 1 fix)
- [x] Add documentation to enforcement-mechanisms.md

**Linter Logic**:
1. Extract all bash blocks from command markdown files
2. Find function calls: `grep -E "(append_workflow_state|restore_workflow_state|init_workflow_state)"`
3. For each block with function calls, verify sourcing appears earlier in same block
4. Report ERROR if function called without sourcing in same block
5. Report WARNING if pre-flight validation missing

**Validation**:
- Linter detects missing state-persistence.sh sourcing
- Pre-commit hook blocks commits with sourcing violations
- validate-all-standards.sh --sourcing category includes state persistence
- Documentation updated with new linter details

**Files Created**:
- `.claude/scripts/check-state-persistence-sourcing.sh` (new linter script)

**Files Modified**:
- `.claude/scripts/validate-all-standards.sh` (add state persistence check)
- `.claude/docs/reference/standards/enforcement-mechanisms.md` (document new linter)

**Estimated Time**: 1.5 hours

---

### Phase 7: Update Error Log Status [COMPLETE]

**Objective**: Mark all 14 analyzed errors as RESOLVED in error log after implementing fixes.

**Context**: Error log tracks resolution status for analyzed errors. Once fixes deployed and validated, update error entries to prevent re-analysis.

**Tasks**:
- [x] Query errors with /errors command: `--command /create-plan --since 2025-12-04 --limit 20`
- [x] Extract error IDs or timestamps for 14 errors in repair-analyst report
- [x] Add resolution status field to errors.jsonl schema (if not exists)
- [x] Update error entries with status=RESOLVED and resolution_date=2025-12-08
- [x] Add resolution notes referencing this repair plan
- [x] Verify /errors command filters resolved errors by default
- [x] Document error resolution workflow in errors-command-guide.md

**Implementation**:
```bash
# Mark errors as resolved (example)
jq -c --arg cmd "/create-plan" --arg since "2025-12-04T00:00:00Z" --arg status "RESOLVED" \
  'select(.command == $cmd and .timestamp >= $since) | .status = $status | .resolved_date = "2025-12-08"' \
  .claude/data/logs/errors.jsonl > .claude/tmp/errors_updated.jsonl
mv .claude/tmp/errors_updated.jsonl .claude/data/logs/errors.jsonl
```

**Validation**:
- All 14 errors from 2025-12-04 to 2025-12-09 marked as RESOLVED
- /errors --command /create-plan shows no unresolved errors
- Resolution notes reference this repair plan path
- Workflow documented in errors-command-guide.md

**Files Modified**:
- `.claude/data/logs/errors.jsonl` (update error status)
- `.claude/docs/guides/commands/errors-command-guide.md` (document resolution workflow)

**Estimated Time**: 0.5 hours

---

## Dependencies

### Phase Dependencies
- Phase 3 depends on Phase 1 (state-persistence.sh must be sourced before append_workflow_state)
- Phase 7 depends on Phases 1-6 (errors marked resolved after fixes validated)
- All other phases are independent and can be executed in parallel

### External Dependencies
- Workflow state machine library (workflow-state-machine.sh >= 2.0.0)
- State persistence library (state-persistence.sh >= 1.5.0)
- Error handling library (error-handling.sh)
- Validation utilities library (validation-utils.sh)

## Testing Strategy

### Unit Tests
- Test state-persistence.sh sourcing validation in isolated bash blocks
- Test terminal state detection and cleanup logic
- Test PLAN_PATH persistence and restoration
- Test agent artifact polling with simulated delays
- Test research report validation with all section header variants

### Integration Tests
- Run full /create-plan workflow with complexity 1 (single topic)
- Run full /create-plan workflow with complexity 3 (multi-topic with agent detection)
- Run /create-plan with existing terminal state file (test cleanup)
- Run /create-plan with slow agent (test retry logic)
- Run /create-plan with "Executive Summary" report format (test flexible validation)

### Error Log Verification
- Query error log after each test: `/errors --command /create-plan --since 1h`
- Verify no new execution_error, state_error, agent_error, or validation_error entries
- Verify error patterns from repair-analyst report no longer occur
- Monitor for regression across 5-10 workflow runs

## Rollback Plan

If fixes introduce regressions:

1. **Phase 1 Rollback**: Remove state-persistence.sh sourcing from Block 1d-topics-auto-validate
2. **Phase 2 Rollback**: Remove state file cleanup logic from Block 1a
3. **Phase 3 Rollback**: Revert PLAN_PATH validation changes
4. **Phase 4 Rollback**: Remove agent artifact retry logic, restore direct validation
5. **Phase 5 Rollback**: Restore exact match for "## Findings" section
6. **Phase 6 Rollback**: Disable new linter in pre-commit hooks

Each phase can be rolled back independently due to minimal cross-phase coupling.

## Success Metrics

### Quantitative Metrics
- 0 exit code 127 errors for state persistence functions (down from 1, 7% of errors)
- 0 terminal state transition errors (down from 4, 29% of errors)
- 0 PLAN_PATH restoration errors (down from 1, 7% of errors)
- 0 agent artifact validation errors (down from 3, 21% of errors)
- 0 section validation errors (down from 1, 7% of errors)
- Total error reduction: 14 errors -> 0 errors (100% reduction)

### Qualitative Metrics
- /create-plan workflows complete successfully without intervention
- Error messages provide clear diagnostic information
- State machine handles edge cases gracefully (terminal states, missing variables)
- Agent integration is robust to timing variations
- Validation is flexible enough for actual report formats

### Monitoring Period
- Monitor error log for 7 days after deployment
- Track /create-plan success rate across 20+ invocations
- Collect feedback on improved error diagnostics
- Verify pre-commit linter catches sourcing violations during development

## Notes

### Critical Path Items
1. **Phase 1** is highest priority (CRITICAL) - blocks workflow execution completely
2. **Phase 2** is high priority - affects 36% of errors, workflow restart reliability
3. **Phase 4** is high priority - affects 21% of errors, agent integration reliability

### Low-Risk Optimizations
- Phase 5 (flexible validation) is low-effort, low-risk enhancement
- Phase 6 (linting) is preventative measure, doesn't fix existing bugs
- Phase 7 (error log update) is administrative cleanup

### Implementation Order Recommendation
1. Phase 1 (critical blocking issue)
2. Phase 2 (high-impact state management)
3. Phase 3 (variable persistence)
4. Phase 4 (agent reliability)
5. Phase 5 (validation flexibility)
6. Phase 6 (preventative linting)
7. Phase 7 (administrative cleanup)
