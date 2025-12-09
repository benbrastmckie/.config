# /create-plan Command Error Analysis Report

## Metadata
- **Date**: 2025-12-09
- **Agent**: repair-analyst
- **Error Count**: 20 errors analyzed (filtered by /create-plan command)
- **Time Range**: 2025-12-05 to 2025-12-09
- **Report Type**: Error Log Analysis
- **Workflow Output**: /home/benjamin/.config/.claude/output/create-plan-output.md

## Executive Summary

Analysis of `/create-plan` command errors reveals **4 distinct error patterns** with a common root cause: **state machine lifecycle management issues** across bash block boundaries. The most recent workflow (plan_1765315557) completed successfully (plan created with 27,397 bytes) but logged state management warnings due to Block 3's completion code not properly loading workflow state before attempting state transitions.

**Key Findings**:
1. Block 3 completion code attempts `sm_transition` without calling `load_workflow_state` first
2. State machine auto-initialization fallback masks the problem but generates warning logs
3. The actual workflow functionality works correctly (artifacts created) despite warnings
4. RESEARCH_DIR state variable sometimes points to older spec directories during validation

**Impact Assessment**: Low severity - workflows complete successfully but generate confusing warning logs.

## Error Patterns

### Pattern 1: STATE_FILE Not Set Before sm_transition (8 occurrences)

**Error Message**: `STATE_FILE not set during sm_transition - load_workflow_state not called`

**Affected Workflows**:
- plan_1765315557 (most recent - goose.nvim recipe execution)
- plan_1765265600 (interactive testing standards)
- plan_1765227200 (todo command revision)

**Root Cause**: Block 3 of `/create-plan` command sources libraries but does not call `load_workflow_state()` before attempting `sm_transition("$STATE_COMPLETE")`. The state machine requires STATE_FILE to be set via `load_workflow_state()` before any transitions.

**Stack Trace Pattern**:
```
source: sm_transition
stack: ["698 sm_transition workflow-state-machine.sh"]
context: {target_state: "complete", diagnostic: "Call load_workflow_state before sm_transition"}
```

**Code Location**: `.claude/commands/create-plan.md` Block 3 (completion block)

---

### Pattern 2: sm_transition Auto-Initialization Warning (8 occurrences)

**Error Message**: `sm_transition attempting auto-initialization`

**Relationship**: This warning always follows Pattern 1 errors - it's the auto-recovery mechanism.

**Root Cause**: When `sm_transition()` detects STATE_FILE is not set, it attempts auto-initialization as a fallback. This works but generates a warning log entry.

**Context Pattern**:
```json
{
  "target_state": "complete",
  "auto_init": true
}
```

**Impact**: Auto-initialization succeeds (workflow completes) but creates unnecessary log noise.

---

### Pattern 3: REPORT_PATHS_STRING State Variable Not Restored (2 occurrences)

**Error Message**: `REPORT_PATHS_STRING not restored from Block 1d-topics state`

**Affected Workflows**:
- plan_1765245039
- plan_1765272657

**Root Cause**: Block 1f validation code references `REPORT_PATHS_STRING` but this variable is persisted using `append_workflow_state_bulk` which uses a different key format than expected.

**Context Pattern**:
```json
{
  "report_paths_string": "missing"
}
```

**Code Location**: `.claude/commands/create-plan.md` Block 1f validation

---

### Pattern 4: Agent Artifact Creation Failures (3 occurrences)

**Error Message**: `Agent failed to create research report after 10s` or `Agent failed to create topics JSON`

**Affected Workflows**:
- plan_1765264648 (exit 127 error fix)
- plan_1765243312 (lean-plan orchestrator debug)
- plan_1765238615 (topic detection)

**Root Cause**: Research-specialist or topic-detection agents sometimes fail to create expected artifacts due to:
1. Agent timeout before file creation
2. Agent writing to incorrect path (path mismatch)
3. Agent not using Write tool as required by hard barrier pattern

**Context Pattern**:
```json
{
  "artifact_type": "research report",
  "error": "file_not_found",
  "max_attempts": 10
}
```

---

## Root Cause Analysis

### Primary Root Cause: Block 3 State Loading Gap

The completion block (Block 3) of `/create-plan` does not follow the correct state machine lifecycle:

**Current Code Pattern** (Block 3):
```bash
# Sources libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"

# MISSING: load_workflow_state "$WORKFLOW_ID" false

# Attempts transition without loaded state
sm_transition "$STATE_COMPLETE"  # FAILS: STATE_FILE not set
```

**Required Pattern**:
```bash
# Sources libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"

# REQUIRED: Load state before any transitions
load_workflow_state "$WORKFLOW_ID" false

# Now transition works correctly
sm_transition "$STATE_COMPLETE"
```

### Secondary Root Cause: State Variable Key Mismatch

The `append_workflow_state_bulk` function uses heredoc format:
```bash
append_workflow_state_bulk <<EOF
REPORT_PATHS_STRING=value1 value2 value3
EOF
```

But Block 1f validation expects the variable to be directly accessible after sourcing the state file. The heredoc format may not properly escape space-separated values.

### Contributing Factor: RESEARCH_DIR State Drift

The workflow output shows RESEARCH_DIR sometimes points to an older spec directory (047 instead of 049). This suggests:
1. State file contamination from previous workflow runs
2. WORKFLOW_ID collision or reuse
3. State file not being cleaned up properly between runs

## Recommendations

### Fix 1: Add load_workflow_state to Block 3 (HIGH PRIORITY)

**Location**: `.claude/commands/create-plan.md` Block 3

**Change**: Add `load_workflow_state "$WORKFLOW_ID" false` after library sourcing and before any `sm_transition` calls.

**Expected Outcome**: Eliminates Pattern 1 and Pattern 2 errors entirely.

---

### Fix 2: Fix REPORT_PATHS_STRING Persistence (MEDIUM PRIORITY)

**Location**: `.claude/commands/create-plan.md` Block 1d-topics

**Change**: Use `append_workflow_state "REPORT_PATHS_STRING" "$REPORT_PATHS_STRING"` instead of bulk append for this specific variable, or ensure proper quoting in heredoc.

**Expected Outcome**: Eliminates Pattern 3 errors.

---

### Fix 3: Extend Agent Artifact Timeout (LOW PRIORITY)

**Location**: `.claude/lib/workflow/validation-utils.sh` `validate_agent_artifact` function

**Change**: Increase default timeout from 10s to 30s for research reports, or add retry logic.

**Expected Outcome**: Reduces Pattern 4 errors (agent timeouts).

---

### Fix 4: State File Cleanup on Workflow Start (LOW PRIORITY)

**Location**: `.claude/commands/create-plan.md` Block 1a

**Change**: Add explicit cleanup of stale state files with same WORKFLOW_ID prefix before initialization.

**Expected Outcome**: Prevents RESEARCH_DIR state drift.

## Implementation Priority

| Fix | Priority | Effort | Impact |
|-----|----------|--------|--------|
| Fix 1: load_workflow_state | HIGH | Low (1 line) | Eliminates 16/20 errors |
| Fix 2: REPORT_PATHS_STRING | MEDIUM | Low (1 line) | Eliminates 2/20 errors |
| Fix 3: Agent timeout | LOW | Medium | Reduces 3/20 errors |
| Fix 4: State cleanup | LOW | Medium | Prevents state drift |

## References

### Error Log Entries Analyzed
- `/home/benjamin/.config/.claude/data/logs/errors.jsonl` (20 entries filtered by command=/create-plan)

### Workflow Output Analyzed
- `/home/benjamin/.config/.claude/output/create-plan-output.md` (243 lines)

### Code Files to Modify
- `.claude/commands/create-plan.md` - Block 3 completion code
- `.claude/lib/workflow/validation-utils.sh` - Agent artifact timeout (optional)

### Related Documentation
- `.claude/docs/concepts/hierarchical-agents-troubleshooting.md`
- `.claude/docs/reference/standards/command-authoring.md`
