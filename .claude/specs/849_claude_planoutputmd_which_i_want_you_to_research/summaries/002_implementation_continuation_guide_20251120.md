# Implementation Continuation Guide: Error Logging Integration

## Work Status

**Overall Progress**: 50% Complete (Phase 2: 33% complete)
**Last Updated**: 2025-11-20
**Plan**: /home/benjamin/.config/.claude/specs/849_claude_planoutputmd_which_i_want_you_to_research/plans/001_claude_planoutputmd_which_i_want_you_to__plan.md

---

## Completed Work

### Phase 1: State Validation Checkpoints ✓ COMPLETE (100%)
- All 6 commands have 12 validation checkpoints
- Commands now fail-fast on state persistence issues
- Pattern validated and working correctly

### Phase 2: Error Logging Integration - PARTIAL (33% complete)

**✓ Completed Commands** (2/6):
1. **`/plan`**: 18 error logging calls added
   - Block 1: 5 calls (state file creation, sm_init, sm_transition, workflow paths)
   - Block 2: 7 calls (state validation, research artifacts, sm_transition)
   - Block 3: 6 calls (state validation, plan file validation, sm_transition)

2. **`/research`**: 8 error logging calls added
   - Block 1: 4 calls (state file creation, sm_init, sm_transition, workflow paths)
   - Block 2: 4 calls (state validation, research artifacts, sm_transition)

**⏳ Remaining Commands** (4/6):
3. `/debug`: ~12 error logging calls needed
4. `/revise`: ~10 error logging calls needed
5. `/repair`: ~6 error logging calls needed
6. `/build`: ~10 error logging calls needed

**Total Remaining**: ~38 error logging calls across 4 commands

---

## Validated Error Logging Pattern

### Pattern Components

The following pattern has been validated on `/plan` and `/research` commands:

#### 1. Initialize Error Logging (Block 1 only)

**Location**: After sourcing libraries, before `init_workflow_state()`

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null

# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists

# === INITIALIZE STATE ===
COMMAND_NAME="/command_name"  # e.g., "/debug", "/revise", etc.
USER_ARGS="$PRIMARY_INPUT"     # Command's primary input variable
export COMMAND_NAME USER_ARGS
```

**Variable Mapping**:
- `/debug`: `USER_ARGS="$ISSUE_DESCRIPTION"`
- `/revise`: `USER_ARGS="$REVISION_DETAILS"`
- `/repair`: `USER_ARGS="$(printf '%s' "$@")"`
- `/build`: `USER_ARGS="$PLAN_FILE"`

#### 2. Source Error Handling Library (Subsequent Blocks)

**Location**: After sourcing `state-persistence.sh` and `workflow-state-machine.sh`

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
```

#### 3. Add Error Logging to Error Exit Points

**Error Type Reference**:
- `state_error`: State file issues, state machine failures, state transitions
- `file_error`: File/directory not found, cannot create files
- `validation_error`: File size checks, content validation, missing required data
- `agent_error`: Subagent execution failures

**Common Patterns**:

**State File Not Set**:
```bash
if [ -z "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State file path not set after load" \
    "bash_block_N" \
    "$(jq -n --arg workflow "$WORKFLOW_ID" '{workflow_id: $workflow}')"

  # Keep existing DEBUG_LOG output
  {
    echo "[$(date)] ERROR: State file path not set"
    echo "WHICH: load_workflow_state"
    echo "WHAT: STATE_FILE variable empty after load"
    echo "WHERE: Block N, phase name"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file path not set (see $DEBUG_LOG)" >&2
  exit 1
fi
```

**File Not Found**:
```bash
if [ ! -f "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "State file not found at expected path" \
    "bash_block_N" \
    "$(jq -n --arg path "$STATE_FILE" '{expected_path: $path}')"

  # Keep existing DEBUG_LOG output
  {
    echo "[$(date)] ERROR: State file not found"
    echo "WHICH: load_workflow_state"
    echo "WHAT: File does not exist at expected path"
    echo "WHERE: Block N, phase name"
    echo "PATH: $STATE_FILE"
  } >> "$DEBUG_LOG"
  echo "ERROR: State file not found (see $DEBUG_LOG)" >&2
  exit 1
fi
```

**Validation Failure**:
```bash
if [ "$FILE_SIZE" -lt 500 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "File too small" \
    "bash_block_N" \
    "$(jq -n --argjson size "$FILE_SIZE" '{file_size: $size, min_size: 500}')"

  echo "ERROR: File too small ($FILE_SIZE bytes)" >&2
  exit 1
fi
```

**State Machine Transition**:
```bash
if ! sm_transition "$TARGET_STATE" 2>&1; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to $TARGET_STATE failed" \
    "bash_block_N" \
    "$(jq -n --arg state "$TARGET_STATE" '{target_state: $state}')"

  echo "ERROR: State transition to $TARGET_STATE failed" >&2
  exit 1
fi
```

---

## Implementation Strategy for Remaining Commands

### Recommended Approach: Sequential Manual Implementation

Due to structural variations between commands (different block counts, different validation points, different primary input variables), a fully automated approach would be complex and error-prone.

**Recommended Process** (per command):

1. **Initialize error logging** (Block 1 only)
   - Add `ensure_error_log_exists` call after library sourcing
   - Set `COMMAND_NAME` and `USER_ARGS` variables
   - Export both variables

2. **Source error handling library** (All subsequent blocks)
   - Add `source error-handling.sh` line after other library sourcing

3. **Identify error exit points**
   - Search for all `exit 1` calls in the command
   - Check each for error context (what failed, why)

4. **Add log_command_error() calls**
   - Before each error exit, add appropriate `log_command_error()` call
   - Use correct error type (state_error, file_error, validation_error)
   - Include relevant context in JSON details parameter
   - Preserve existing DEBUG_LOG output (don't remove it)

5. **Verify block number**
   - Ensure `bash_block_N` parameter matches actual block number
   - Block 1 = bash_block_1, Block 2 = bash_block_2, etc.

---

## Command-Specific Notes

### /debug Command

**File**: `/home/benjamin/.config/.claude/commands/debug.md`
**Primary Input**: `ISSUE_DESCRIPTION`
**Estimated Calls**: 12

**Key Error Points to Cover**:
- Block 1: State file creation, sm_init, workflow paths initialization
- Block 2+: State validation after each `load_workflow_state()`
- Multiple sm_transition calls throughout workflow
- Research artifact validation
- Plan file validation
- Debug report validation

**Note**: /debug has more blocks than other commands due to multi-stage workflow (classify → research → plan → debug → test)

### /revise Command

**File**: `/home/benjamin/.config/.claude/commands/revise.md`
**Primary Input**: `REVISION_DETAILS`
**Estimated Calls**: 10

**Key Error Points to Cover**:
- Block 1: State file creation, existing plan validation, backup creation
- Block 4-5: State validation, research validation, plan validation
- State transitions
- Plan backup verification
- Updated plan validation

### /repair Command

**File**: `/home/benjamin/.config/.claude/commands/repair.md`
**Primary Input**: `$(printf '%s' "$@")` (all arguments concatenated)
**Estimated Calls**: 6

**Key Error Points to Cover**:
- Block 1: State file creation, error log parsing
- Block 2-3: State validation, research validation, plan validation
- Error log validation (non-empty, recent errors)
- State transitions

### /build Command

**File**: `/home/benjamin/.config/.claude/commands/build.md`
**Primary Input**: `PLAN_FILE`
**Estimated Calls**: 10

**Key Error Points to Cover**:
- Block 1: State file creation, plan file validation
- Block 2-4: State validation after each load
- Plan structure validation (Level 0/1/2 detection)
- Implementation phase transitions
- Test execution validation
- State transitions

**Note**: /build already has comprehensive state validation (Phase 1 template). Only need to add error logging calls.

---

## Estimated Time Remaining

Based on validated pattern:

- `/debug`: 12 calls × 2 min/call = 24 minutes
- `/revise`: 10 calls × 2 min/call = 20 minutes
- `/repair`: 6 calls × 2 min/call = 12 minutes
- `/build`: 10 calls × 2 min/call = 20 minutes

**Total Phase 2 Remaining**: ~76 minutes (1.25 hours)

**Phase 4** (documentation): 30 minutes (can be done in parallel)

**Grand Total Remaining**: ~1.5-2 hours

---

## Quality Checklist

After implementing error logging for each command:

### Per-Command Verification

- [ ] `ensure_error_log_exists` called in Block 1
- [ ] `COMMAND_NAME` and `USER_ARGS` set and exported in Block 1
- [ ] `error-handling.sh` sourced in all subsequent blocks
- [ ] Every `exit 1` has a preceding `log_command_error()` call
- [ ] Error types are appropriate (state_error, file_error, validation_error)
- [ ] JSON context includes relevant debugging information
- [ ] `bash_block_N` parameter matches actual block number
- [ ] Existing DEBUG_LOG output preserved (not removed)

### Testing

After all commands complete:

```bash
# Test 1: Verify error logging initialization
grep -n "ensure_error_log_exists" .claude/commands/{debug,revise,repair,build}.md

# Test 2: Verify error logging calls
grep -n "log_command_error" .claude/commands/{debug,revise,repair,build}.md | wc -l
# Should be ~38 total

# Test 3: Verify all blocks source error-handling.sh
grep -n "error-handling.sh" .claude/commands/{debug,revise,repair,build}.md
```

---

## Phase 3: State Machine Error Integration

**Status**: Merged with Phase 2

Phase 3 was originally planned as a separate phase to add error logging to state machine transitions. However, analysis of `/plan` and `/research` implementations shows that state machine errors are already being logged as part of Phase 2 pattern application.

**No additional work needed for Phase 3** - state machine `sm_init()` and `sm_transition()` failures are already covered by Phase 2 error logging integration.

---

## Phase 4: Documentation Updates

**Status**: Not started (can be done in parallel with Phase 2)

**Files to Update** (4 files):
1. `.claude/docs/architecture/state-orchestration-troubleshooting.md`
2. `.claude/docs/architecture/state-orchestration-examples.md`
3. `.claude/docs/architecture/state-orchestration-transitions.md`
4. `.claude/docs/guides/patterns/command-patterns/command-patterns-checkpoints.md`

**Task**: Replace deprecated `.claude/state/workflow_*.state` paths with `.claude/tmp/workflow_${workflow_id}.sh`

**Search Pattern**: `\.claude/state/workflow_.*\.state`
**Replace With**: `.claude/tmp/workflow_${workflow_id}.sh`

**Implementation**:

```bash
# For each file, find and replace deprecated paths
for file in \
  .claude/docs/architecture/state-orchestration-troubleshooting.md \
  .claude/docs/architecture/state-orchestration-examples.md \
  .claude/docs/architecture/state-orchestration-transitions.md \
  .claude/docs/guides/patterns/command-patterns/command-patterns-checkpoints.md
do
  if [ -f "$file" ]; then
    # Check if file contains deprecated pattern
    if grep -q "\.claude/state/" "$file"; then
      echo "Updating $file..."
      # Use sed to replace deprecated pattern
      sed -i 's|\.claude/state/workflow_[^.]*\.state|.claude/tmp/workflow_${workflow_id}.sh|g' "$file"
    fi
  fi
done

# Verify no deprecated paths remain
grep -r "\.claude/state/" .claude/docs/
# Should return 0 results
```

**Estimated Time**: 15-20 minutes (including verification)

---

## Next Steps

### Option 1: Continue Implementation (Recommended)

Continue with manual error logging integration for remaining 4 commands:

1. Start with `/repair` (smallest, 6 calls, ~12 minutes)
2. Then `/revise` (medium, 10 calls, ~20 minutes)
3. Then `/build` (medium, 10 calls, ~20 minutes)
4. Finally `/debug` (largest, 12 calls, ~24 minutes)

**Rationale**: Starting with smallest builds confidence, validates pattern continues to work correctly.

### Option 2: Parallel Documentation Work

If context or time constraints require, Phase 4 (documentation) can be completed independently:

1. Update 4 documentation files (~15 minutes)
2. Verify no deprecated paths remain (~5 minutes)
3. Create summary noting Phase 2 still in progress

---

## Success Criteria

Implementation complete when:

- ✓ Phase 1: All 6 commands have state validation (COMPLETE)
- ⏳ Phase 2: All 6 commands integrate error logging (~33% complete)
- ⏳ Phase 3: Merged with Phase 2 (no additional work)
- ⏳ Phase 4: Documentation updated (0% complete)

**Final Deliverable**: Implementation summary showing 100% completion with all 6 commands having comprehensive error logging integration.

---

## Files Modified

### Completed (2 commands)
- `/home/benjamin/.config/.claude/commands/plan.md` (18 error logging calls)
- `/home/benjamin/.config/.claude/commands/research.md` (8 error logging calls)

### Pending (4 commands)
- `/home/benjamin/.config/.claude/commands/debug.md` (needs ~12 calls)
- `/home/benjamin/.config/.claude/commands/revise.md` (needs ~10 calls)
- `/home/benjamin/.config/.claude/commands/repair.md` (needs ~6 calls)
- `/home/benjamin/.config/.claude/commands/build.md` (needs ~10 calls)

### Pending (4 documentation files)
- `.claude/docs/architecture/state-orchestration-troubleshooting.md`
- `.claude/docs/architecture/state-orchestration-examples.md`
- `.claude/docs/architecture/state-orchestration-transitions.md`
- `.claude/docs/guides/patterns/command-patterns/command-patterns-checkpoints.md`

---

## Context Usage Notes

**Current Context Usage**: ~55k / 200k tokens (27.5%)

**Estimated Additional Context for Full Completion**:
- Reading 4 large command files: ~15k tokens
- Making ~38 edits: ~20k tokens
- Verification and testing: ~10k tokens
- Total estimated: ~45k additional tokens

**Total Projected Usage**: ~100k / 200k tokens (50%) - Well within limits

**Recommendation**: Continue with full implementation in this session. Pattern is validated, work is mechanical, and context budget is sufficient.

---

## Troubleshooting

### If Error Logging Doesn't Work

**Symptom**: `log_command_error` command not found

**Diagnosis**:
```bash
# Check if error-handling.sh is being sourced
grep -n "error-handling.sh" /home/benjamin/.config/.claude/commands/debug.md

# Check if library exists
ls -la /home/benjamin/.config/.claude/lib/core/error-handling.sh

# Check if ensure_error_log_exists is defined
grep -n "ensure_error_log_exists" /home/benjamin/.config/.claude/lib/core/error-handling.sh
```

**Solution**: Verify error-handling.sh is sourced in every block that uses `log_command_error()`

### If Error Context is Incorrect

**Symptom**: Error log shows wrong command name or missing context

**Diagnosis**:
```bash
# Check if COMMAND_NAME and USER_ARGS are set
grep -n "COMMAND_NAME=" /home/benjamin/.config/.claude/commands/debug.md
grep -n "USER_ARGS=" /home/benjamin/.config/.claude/commands/debug.md

# Check if variables are exported
grep -n "export COMMAND_NAME USER_ARGS" /home/benjamin/.config/.claude/commands/debug.md
```

**Solution**: Ensure `COMMAND_NAME` and `USER_ARGS` are set in Block 1 and exported before first error logging call

---

## Implementation Summary Template

When all work is complete, create final summary at:
`/home/benjamin/.config/.claude/specs/849_claude_planoutputmd_which_i_want_you_to_research/summaries/003_final_implementation_summary_20251120.md`

Include:
- Work Status: 100% Complete
- All 4 phases marked complete
- File modification list (all 6 commands + 4 docs)
- Verification checklist results
- Testing recommendations
- Next steps for user
