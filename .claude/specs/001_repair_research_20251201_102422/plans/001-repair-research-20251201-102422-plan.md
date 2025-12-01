# /research Command Error Fixes Implementation Plan

## Metadata
- **Date**: 2025-12-01
- **Revised**: 2025-12-01 (incorporated infrastructure research findings)
- **Feature**: Fix /research command errors and prevent cascading failures
- **Scope**: Commands, topic naming agent synchronization (focused scope)
- **Estimated Phases**: 4
- **Estimated Hours**: 5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 50 (Medium - 4 phases, ~15 tasks, 4 files, 2 integrations)
- **Structure Level**: 0
- **Research Reports**:
  - [001-research-errors-repair.md](../reports/001-research-errors-repair.md)
  - [002-infrastructure-standards-research.md](../reports/002-infrastructure-standards-research.md)

## Overview

This plan addresses the root causes of `/research` command failures identified in the error analysis report. The primary issue is:

1. **Topic naming agent WORKFLOW_ID mismatch** - Agent writes to wrong output file path due to variable expansion timing issues

The fix applies the **Hard Barrier Pattern** documented in `.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md` - pre-calculating paths before agent invocation and validating via hard barriers after.

**Note**: Research into existing infrastructure (report 002) found that:
- The existing `append_workflow_state` function already has error handling (returns 1 if STATE_FILE not set)
- Three-tier sourcing is already mandatory and enforced by linter/pre-commit
- TEST_PHASE_OPTIONAL for /build is a separate issue and removed from this plan's scope

## Research Summary

### Error Analysis (report 001):

- **26 errors analyzed** covering 11/30 to 12/01
- **Pattern 1**: Topic naming agent output file missing (6 errors, 23%)
- **Pattern 2**: State restoration missing critical variables (6 errors, 23%)
- **Pattern 4**: Execution errors exit code 127 (4 errors, 15%)

Key finding: The topic naming agent received WORKFLOW_ID `research_1748745028` but the orchestrator used `research_1764612993` - a 191-day gap indicating cached/stale values.

### Infrastructure Research (report 002):

Key findings that simplified this plan:
1. `append_workflow_state` already returns 1 on missing STATE_FILE - use inline fallback instead of wrapper
2. Hard Barrier Pattern documentation (lines 74-166) shows exact implementation pattern
3. Three-tier sourcing is mandatory per code-standards.md - no new requirements needed
4. PATH MISMATCH bug (HOME vs CLAUDE_PROJECT_DIR) may be root cause of exit 127 - add diagnostic

## Success Criteria

- [ ] `/research` command completes successfully without topic naming fallback
- [ ] State variables persist correctly across all bash blocks
- [ ] No exit code 127 errors related to `append_workflow_state`
- [ ] Error log shows 0 new `agent_no_output_file` fallback events
- [ ] Standards validation passes: `bash .claude/scripts/validate-all-standards.sh --sourcing`

## Technical Design

### Architecture Changes

1. **Apply Hard Barrier Pattern to Topic Naming**
   - Reference: `.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md` (Template 1)
   - Orchestrator calculates exact output file path BEFORE invoking topic-naming-agent
   - Path passed as literal text in Task prompt (not variable reference)
   - Hard barrier validation AFTER agent returns (file MUST exist at pre-calculated path)

2. **Defensive State Persistence (Inline Fallback)**
   - Use existing `append_workflow_state` with inline fallback:
     ```bash
     append_workflow_state "VAR" "$val" || echo "export VAR=\"$val\"" >> "$STATE_FILE"
     ```
   - Add explicit `export STATE_FILE` immediately after `init_workflow_state`
   - Verify STATE_FILE uses CLAUDE_PROJECT_DIR (not HOME) to prevent PATH MISMATCH

### Files to Modify

| File | Change Type | Description |
|------|-------------|-------------|
| `.claude/commands/research.md` | Edit | Apply Hard Barrier Pattern to topic naming |
| `.claude/commands/plan.md` | Edit | Apply Hard Barrier Pattern to topic naming |
| `.claude/agents/topic-naming-agent.md` | Edit | Add output path contract in behavioral guidelines |

## Implementation Phases

### Phase 1: Apply Hard Barrier Pattern to /research [COMPLETE]
dependencies: []

**Objective**: Pre-calculate topic name file path and apply Hard Barrier Pattern to topic-naming-agent invocation in research.md

**Complexity**: Medium

**Reference**: [Hard Barrier Pattern](../../docs/concepts/patterns/hard-barrier-subagent-delegation.md) - Template 1

Tasks:
- [x] Add Block 1b: Pre-calculate topic name file path
  ```bash
  TOPIC_NAME_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt"
  append_workflow_state "TOPIC_NAME_FILE" "$TOPIC_NAME_FILE" || echo "export TOPIC_NAME_FILE=\"$TOPIC_NAME_FILE\"" >> "$STATE_FILE"
  ```
- [x] Update Block 1b-exec Task prompt to pass path as literal contract:
  ```
  **Input Contract (Hard Barrier Pattern)**:
  - Output Path: ${TOPIC_NAME_FILE}

  **CRITICAL**: You MUST write to the EXACT path specified above.
  ```
- [x] Add Block 1c: Hard barrier validation
  ```bash
  if [ ! -f "$TOPIC_NAME_FILE" ]; then
    log_command_error "agent_error" "topic-naming-agent failed to create output file" "$TOPIC_NAME_FILE"
    exit 1
  fi
  ```
- [x] Add `export STATE_FILE` immediately after `init_workflow_state` in Block 1a
- [x] Add PATH MISMATCH diagnostic: verify STATE_FILE uses CLAUDE_PROJECT_DIR (not HOME)

Testing:
```bash
# Run /research and verify no fallback to no_name_error
/research "test hard barrier pattern" --complexity 1

# Verify topic_name file created at expected path
ls -la .claude/tmp/topic_name_research_*.txt
```

**Expected Duration**: 1.5 hours

### Phase 2: Apply Hard Barrier Pattern to /plan [COMPLETE]
dependencies: [1]

**Objective**: Apply same Hard Barrier Pattern to topic-naming-agent invocation in plan.md

**Complexity**: Low

Tasks:
- [x] Add Block 1b: Pre-calculate topic name file path (same pattern as Phase 1)
- [x] Update Task prompt with explicit output path contract
- [x] Add Block 1c: Hard barrier validation with error logging
- [x] Add `export STATE_FILE` after `init_workflow_state`

Testing:
```bash
# Run /plan and verify no fallback to no_name_error
/plan "test plan topic naming" --complexity 1

# Verify topic_name file created at expected path
ls -la .claude/tmp/topic_name_plan_*.txt
```

**Expected Duration**: 1 hour

### Phase 3: Update Topic Naming Agent Contract [COMPLETE]
dependencies: []

**Objective**: Add explicit output path contract to topic-naming-agent behavioral guidelines

**Complexity**: Low

Tasks:
- [x] Add "Output Path Contract" section to topic-naming-agent.md:
  ```markdown
  ## Output Path Contract

  **CRITICAL**: The orchestrator provides an explicit output path in the Task prompt.
  You MUST write your output to the EXACT path specified - do not derive or calculate
  your own path. The orchestrator will validate this file exists after you return.
  ```
- [x] Remove any default/fallback path calculation from agent
- [x] Add completion signal requirement: `TOPIC_NAME_CREATED: ${OUTPUT_PATH}`

Testing:
```bash
# Manual test: Verify agent uses provided path
# Check topic-naming-agent output for "TOPIC_NAME_CREATED:" signal
```

**Expected Duration**: 0.5 hours

### Phase 4: Standards Verification and Error Log Update [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Verify fixes comply with standards and update error log status

Tasks:
- [x] Run standards validation:
  ```bash
  bash .claude/scripts/validate-all-standards.sh --sourcing
  bash .claude/scripts/validate-all-standards.sh --conditionals
  ```
- [x] Verify no new linter violations introduced
- [x] Run `/research` and `/plan` with test prompts to verify no errors
- [x] Update error log entries to RESOLVED status:
  ```bash
  source .claude/lib/core/error-handling.sh
  RESOLVED_COUNT=$(mark_errors_resolved_for_plan "${PLAN_PATH}")
  echo "Resolved $RESOLVED_COUNT error log entries"
  ```

**Expected Duration**: 1 hour

## Testing Strategy

### Unit Tests
- Test inline fallback pattern with and without STATE_FILE set
- Test path calculation determinism across bash blocks

### Integration Tests
- Run `/research "test topic"` and verify no fallback to `000_no_name_error` directory
- Run `/plan "test topic"` and verify no fallback to `000_no_name_error` directory
- Verify topic_name files created at expected paths in `.claude/tmp/`

### Validation Commands
```bash
# After implementation, verify no new topic naming failures
tail -f .claude/data/logs/errors.jsonl | jq 'select(.error_message | contains("topic naming"))'

# Verify no new exit code 127 errors
grep -c "exit code 127" .claude/data/logs/errors.jsonl

# Verify standards compliance
bash .claude/scripts/validate-all-standards.sh --sourcing
```

## Documentation Requirements

- No new documentation required (using existing Hard Barrier Pattern documentation)
- Update topic-naming-agent.md with output path contract section

## Dependencies

- **topic-naming-agent.md**: Must be updated with explicit output path contract
- **Hard Barrier Pattern**: Reference documentation at `.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md`

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Inline fallback pattern differs from existing calls | Use exact pattern from workflow-state-machine.sh (lines 456-461) |
| Topic naming agent ignores new contract | Hard barrier validation ensures failure detection with error logging |
| PATH MISMATCH bug not caught | Add explicit diagnostic in Block 1a to validate STATE_FILE path uses CLAUDE_PROJECT_DIR |

## Revision History

- **2025-12-01**: Initial plan created from error analysis
- **2025-12-01**: Revised based on infrastructure research (report 002) - simplified from 5 phases to 4 phases, removed TEST_PHASE_OPTIONAL (out of scope), referenced existing Hard Barrier Pattern documentation
