# Repair Error Status Refactor Implementation Plan

## Metadata
- **Date**: 2025-11-23
- **Feature**: /repair command error log status updates and --file flag standardization
- **Scope**: Extend error log schema, add status update functions, standardize --file flag, integrate error-plan linkage
- **Estimated Phases**: 4
- **Estimated Hours**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 39 (Tier 1)
- **Structure Level**: 0
- **Research Reports**:
  - [Repair Command Refactor Research](../reports/001-repair-command-refactor-research.md)

## Overview

This plan implements systematic improvements to the /repair command workflow to enable bidirectional tracking between error logs and repair plans. Currently, when /repair creates a plan to fix errors, the original error log entries remain unchanged with no indication that a fix is in progress. This refactor extends the error log schema to include status tracking (`ERROR`, `FIX_PLANNED`, `RESOLVED`) and plan references, enabling selective updates to only those errors addressed by a specific repair plan.

Additionally, the plan standardizes the --file flag across commands by replacing the non-existent `--report` flag reference in /errors with the standard `--file` flag pattern used by /plan, /debug, /research, and /revise commands.

## Research Summary

Key findings from the research report:

1. **Schema Gap**: Current error log entries have no `status` or `repair_plan_path` fields - only logging, not lifecycle management
2. **Flag Inconsistency**: /errors command (line 557) suggests `--report` flag, but /repair never implemented it; standard is `--file`
3. **Missing Functions**: error-handling.sh needs `update_error_status()` and `mark_errors_fix_planned()` functions
4. **Selective Update Requirement**: Must preserve filter criteria from analysis phase to update only matching errors
5. **97 Error Entries**: Production log shows predominantly execution_error (52), agent_error (12), validation_error (11)

Recommended approach: Extend schema with backward compatibility, add update functions, integrate status updates into /repair workflow Block 3.5.

## Success Criteria

- [ ] Error log entries include `status` field (default: "ERROR") for new entries
- [ ] Error log entries include `repair_plan_path` field when fix is planned
- [ ] `update_error_status()` function exists and correctly updates individual entries
- [ ] `mark_errors_fix_planned()` function updates all matching errors based on filters
- [ ] /repair command updates error status to "FIX_PLANNED" after plan creation
- [ ] /repair command links matching errors to the created plan path
- [ ] /errors command references `--file` flag instead of `--report`
- [ ] /errors command supports `--status` filter for querying by status
- [ ] Existing error logs remain readable (backward compatibility)
- [ ] All tests pass for error-handling.sh library

## Technical Design

### Architecture Changes

```
Error Log Entry (Extended Schema)
┌────────────────────────────────────────────────────────────┐
│ {                                                          │
│   "timestamp": "...",                                      │
│   "command": "/build",                                     │
│   "error_type": "state_error",                            │
│   "error_message": "...",                                 │
│   ... existing fields ...,                                │
│   "status": "ERROR|FIX_PLANNED|RESOLVED",    [NEW]        │
│   "repair_plan_path": "/path/to/plan.md",    [NEW]        │
│   "status_updated_at": "2025-11-23T..."      [NEW]        │
│ }                                                          │
└────────────────────────────────────────────────────────────┘
```

### Workflow Integration

```
/repair Command Flow (Extended)
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│ Block 1     │     │ Block 2      │     │ Block 3      │
│ Setup       │────>│ Research     │────>│ Plan         │
│ Filters     │     │ Analysis     │     │ Creation     │
└─────────────┘     └──────────────┘     └──────────────┘
                                                │
                                                v
                                         ┌──────────────┐
                                         │ Block 3.5    │ [NEW]
                                         │ Update Error │
                                         │ Status       │
                                         └──────────────┘
                                                │
                                                v
                                         ┌──────────────┐
                                         │ Block 4      │
                                         │ Summary      │
                                         └──────────────┘
```

### Key Design Decisions

1. **Backward Compatibility**: New fields are optional; old entries without status default to "ERROR" when queried
2. **In-Place Updates**: Use temporary file + atomic rename pattern to update JSONL entries safely
3. **Filter Preservation**: Store original filter criteria in workflow state for selective updates
4. **Selective Updates Only**: Update errors matching the original /repair filters, not all errors

## Implementation Phases

### Phase 1: Schema Extension and Update Functions [COMPLETE]
dependencies: []

**Objective**: Extend error log schema and add update functions to error-handling.sh

**Complexity**: Medium

Tasks:
- [x] Update `log_command_error()` in `/home/benjamin/.config/.claude/lib/core/error-handling.sh` to add `status` field (default: "ERROR")
- [x] Add `status_updated_at` field placeholder (null for new entries)
- [x] Create `update_error_status()` function to update a single error entry by workflow_id and timestamp
- [x] Create `mark_errors_fix_planned()` function to bulk update errors matching filter criteria
- [x] Implement atomic file update pattern (temp file + rename) for JSONL modifications
- [x] Add backward compatibility handling in `query_errors()` for entries missing status field
- [x] Update `recent_errors()` function to display status field when present

**Implementation Details**:
```bash
# New function signature
update_error_status() {
  local workflow_id="${1:-}"
  local timestamp="${2:-}"
  local new_status="${3:-}"  # ERROR|FIX_PLANNED|RESOLVED
  local repair_plan_path="${4:-}"
  # Update entry matching workflow_id + timestamp
}

# Bulk update function signature
mark_errors_fix_planned() {
  local filter_args="${1:-}"  # --command, --type, --since filters
  local plan_path="${2:-}"
  # Update all matching entries with FIX_PLANNED status and plan path
}
```

Testing:
```bash
# Run error-handling unit tests
bash .claude/tests/unit/test_error_logging.sh

# Verify backward compatibility with existing logs
jq 'select(.status == null) | .status = "ERROR"' .claude/data/logs/errors.jsonl
```

**Expected Duration**: 2.5 hours

### Phase 2: Flag Standardization [COMPLETE]
dependencies: [1]

**Objective**: Replace `--report` reference with standard `--file` flag and add to /repair

**Complexity**: Low

Tasks:
- [x] Update `/home/benjamin/.config/.claude/commands/errors.md` line 557 to use `--file` instead of `--report`
- [x] Add `--file` flag parsing to `/home/benjamin/.config/.claude/commands/repair.md` Block 1 (following debug.md pattern lines 111-155)
- [x] Update `/home/benjamin/.config/.claude/docs/guides/commands/repair-command-guide.md` with `--file` flag documentation
- [x] Update `/home/benjamin/.config/.claude/commands/README.md` to include /repair in `--file` flag examples if missing

**Implementation Pattern** (from debug.md):
```bash
# Parse optional --file flag for long prompts
if [[ "$ARGS_STRING" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  ORIGINAL_PROMPT_FILE_PATH="${BASH_REMATCH[1]}"
  # Convert to absolute path if relative
  [[ "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]
  IS_ABSOLUTE_PATH=$?
  if [ $IS_ABSOLUTE_PATH -ne 0 ]; then
    ORIGINAL_PROMPT_FILE_PATH="$(pwd)/$ORIGINAL_PROMPT_FILE_PATH"
  fi
fi
```

Testing:
```bash
# Verify /errors output mentions --file
grep -q "\-\-file" .claude/commands/errors.md

# Verify /repair has --file flag parsing
grep -q "ORIGINAL_PROMPT_FILE_PATH" .claude/commands/repair.md
```

**Expected Duration**: 1 hour

### Phase 3: Workflow Integration [COMPLETE]
dependencies: [1, 2]

**Objective**: Integrate error status updates into /repair command workflow

**Complexity**: Medium

Tasks:
- [x] Add filter preservation to Block 1 - persist ERROR_COMMAND, ERROR_TYPE, ERROR_SINCE to workflow state
- [x] Create Block 3.5 in `/home/benjamin/.config/.claude/commands/repair.md` after plan creation
- [x] In Block 3.5: Source error-handling.sh and load persisted filter criteria
- [x] In Block 3.5: Call `mark_errors_fix_planned()` with original filters and plan path
- [x] In Block 3.5: Count updated errors and persist ERRORS_UPDATED count to state
- [x] Update Block 3 (now Block 4) summary to include updated error count

**Block 3.5 Structure**:
```bash
# === UPDATE ERROR LOG STATUS ===
echo "Updating error log entries..."

# Build filter arguments from persisted state
FILTER_ARGS=""
[ -n "$ERROR_COMMAND" ] && FILTER_ARGS="$FILTER_ARGS --command $ERROR_COMMAND"
[ -n "$ERROR_TYPE" ] && FILTER_ARGS="$FILTER_ARGS --type $ERROR_TYPE"
[ -n "$ERROR_SINCE" ] && FILTER_ARGS="$FILTER_ARGS --since $ERROR_SINCE"

# Mark matching errors as FIX_PLANNED
ERRORS_UPDATED=$(mark_errors_fix_planned "$FILTER_ARGS" "$PLAN_PATH")

echo "Updated $ERRORS_UPDATED error entries with FIX_PLANNED status"
append_workflow_state "ERRORS_UPDATED" "$ERRORS_UPDATED"
```

Testing:
```bash
# Run repair state transition test
bash .claude/tests/integration/test_repair_state_transitions.sh

# Verify error entries are updated after /repair
/errors --status FIX_PLANNED --limit 5
```

**Expected Duration**: 2.5 hours

### Phase 4: Query Enhancement and Documentation [COMPLETE]
dependencies: [3]

**Objective**: Add `--status` filter to /errors and update all documentation

**Complexity**: Low

Tasks:
- [x] Add `--status` filter argument parsing to `/home/benjamin/.config/.claude/commands/errors.md`
- [x] Update `query_errors()` function to support `--status` filter
- [x] Update `/home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md` with `--status` filter documentation
- [x] Add examples showing error lifecycle: `/errors --status ERROR`, `/errors --status FIX_PLANNED`
- [x] Update summary output in Block 3 to show status breakdown

**Implementation** (errors.md):
```bash
# Parse --status filter
if [[ "$ARGS_STRING" =~ --status[[:space:]]+([^[:space:]]+) ]]; then
  STATUS_FILTER="${BASH_REMATCH[1]}"
  ARGS_STRING=$(echo "$ARGS_STRING" | sed 's/--status[[:space:]]*[^[:space:]]*//' | xargs)
fi
```

Testing:
```bash
# Test status filter
/errors --status ERROR --limit 5
/errors --status FIX_PLANNED --limit 5

# Verify documentation updates
grep -q "\-\-status" .claude/commands/errors.md
grep -q "FIX_PLANNED" .claude/docs/guides/commands/errors-command-guide.md
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Tests
- Test `update_error_status()` with valid and invalid inputs
- Test `mark_errors_fix_planned()` with various filter combinations
- Test backward compatibility with entries missing status field
- Test atomic file update pattern for data integrity

### Integration Tests
- Test full /repair workflow creates plan AND updates error status
- Test /errors --status filter returns only matching entries
- Test error status persists across workflow state reloads

### Regression Tests
- Verify existing error log queries continue to work
- Verify existing /repair workflows complete successfully
- Verify test log isolation (test errors don't pollute production log)

### Manual Validation
1. Create test errors: Run a command that logs errors
2. Run /repair with filters: `/repair --command /build --since 1h`
3. Verify plan created and errors marked: `/errors --status FIX_PLANNED`
4. Verify plan path in error entries: Check JSONL directly

## Documentation Requirements

### Files to Update
- `/home/benjamin/.config/.claude/commands/README.md` - Add --status flag to /errors section
- `/home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md` - Document --status filter, error lifecycle
- `/home/benjamin/.config/.claude/docs/guides/commands/repair-command-guide.md` - Document --file flag, error status updates
- `/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md` - Document extended schema and lifecycle

### Documentation Standards
- Follow existing documentation format
- Include code examples for new features
- Update any references to `--report` flag to `--file`

## Dependencies

### External Dependencies
- `jq` - JSON processing (already required)
- Atomic file operations via temp file + mv

### Internal Dependencies
- error-handling.sh library (being modified)
- state-persistence.sh (for filter preservation)
- workflow-state-machine.sh (no changes needed)

### Backward Compatibility
- Existing error log entries remain valid
- Queries handle missing status field gracefully (default to "ERROR")
- No breaking changes to existing command interfaces

## Risk Assessment

### Low Risk
- Flag standardization (--file) - straightforward string replacement
- Documentation updates - no code impact

### Medium Risk
- JSONL file modification - mitigated by atomic update pattern
- Filter preservation across blocks - mitigated by existing state persistence

### Mitigation Strategies
- Always use temp file + atomic rename for JSONL updates
- Add validation that entries match expected schema before updates
- Include rollback instructions if update fails mid-operation

## Notes

- **Expansion Hint**: Complexity score 39 is below the 50 threshold for phase expansion. This plan is appropriately sized for single-file structure.
- **Test Isolation**: All testing should use test error log (`.claude/tests/logs/test-errors.jsonl`) to avoid polluting production data.
- **Status Values**: Using simple string values (ERROR, FIX_PLANNED, RESOLVED) rather than numeric codes for human readability in JSONL.
