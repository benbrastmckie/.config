# Repair Command Error Status Refactor Research Report

## Metadata
- **Date**: 2025-11-23
- **Agent**: research-specialist
- **Topic**: /repair command refactor for error log status updates and --file flag standardization
- **Report Type**: codebase analysis
- **Complexity**: 3
- **Research Scope**: /repair command, error-handling.sh, /errors command, error log structure

## Executive Summary

The /repair command currently lacks the ability to update error log entries with "FIX_PLANNED" status and link them to repair plans. Additionally, the /errors command references a non-existent `--report` flag that should be replaced with the standard `--file` flag used consistently across other commands (/plan, /debug, /research, /revise). This research identifies the current architecture, error log schema, and provides a path forward for implementing selective error status updates tied to specific repair plans.

## Findings

### 1. Current Error Log Structure

The error log at `.claude/data/logs/errors.jsonl` uses a JSONL format with the following schema (from error-handling.sh:483-505):

```json
{
  "timestamp": "2025-11-21T06:02:36Z",
  "environment": "production|test",
  "command": "/build",
  "workflow_id": "build_1763704851",
  "user_args": "...",
  "error_type": "state_error|validation_error|agent_error|parse_error|file_error|timeout_error|execution_error",
  "error_message": "...",
  "source": "bash_trap|...",
  "stack": ["..."],
  "context": {...}
}
```

**Key Observation**: The current schema has NO status field, NO repair_plan field, and NO mechanism to track whether an error has been addressed.

### 2. Current /repair Command Workflow

From `/home/benjamin/.config/.claude/commands/repair.md`:
- **Workflow Type**: research-and-plan (lines 18-21)
- **Terminal State**: plan (after planning phase complete)
- **Two-Phase Design**:
  1. Error Analysis (repair-analyst agent) - creates analysis reports
  2. Fix Planning (plan-architect agent) - creates implementation plan

**Current Gap**: The command creates reports and plans but does NOT update the original error log entries to mark them as addressed.

### 3. Flag Inconsistency Analysis

**Standard `--file` flag pattern** (from debug.md:111-155, plan.md:71-93, research.md:70-92, revise.md:152-185):
```bash
# Parse optional --file flag for long prompts
if [[ "$DESCRIPTION" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  ORIGINAL_PROMPT_FILE_PATH="${BASH_REMATCH[1]}"
  # Convert to absolute path if relative
  [[ "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]
  IS_ABSOLUTE_PATH=$?
  if [ $IS_ABSOLUTE_PATH -ne 0 ]; then
    ORIGINAL_PROMPT_FILE_PATH="$(pwd)/$ORIGINAL_PROMPT_FILE_PATH"
  fi
  # Validate file exists and read content
  ...
fi
```

**Current /errors output** (errors.md:557):
```bash
echo "Use with /repair: /repair --report $REPORT_PATH"
```

**Problem**: The `/errors` command outputs instructions to use `--report` flag with `/repair`, but:
1. `/repair` command does NOT implement a `--report` flag
2. Other commands use `--file` as the standard flag name

### 4. Error Type Distribution from Live Logs

Analysis of `/home/benjamin/.config/.claude/data/logs/errors.jsonl` (97 entries):

| Error Type | Count | Primary Commands Affected |
|------------|-------|--------------------------|
| execution_error | 52 | /build, /plan, /revise |
| agent_error | 12 | /plan, /repair |
| validation_error | 11 | /plan, /convert-docs |
| state_error | 9 | /repair, /build |
| file_error | 6 | /build, /test |
| parse_error | 5 | /plan, /test |

### 5. Relevant Library Functions

From `/home/benjamin/.config/.claude/lib/core/error-handling.sh`:
- `log_command_error()` (lines 414-510): Logs errors to JSONL
- `query_errors()` (lines 605-672): Queries errors with filters
- `rotate_error_log()` (lines 558-588): Rotates large log files
- `ensure_error_log_exists()` (lines 593-599): Creates log file

**Missing Functions Needed**:
- `update_error_status()`: Update status field on specific error entries
- `mark_errors_fix_planned()`: Bulk update errors matching criteria with plan path

### 6. Commands README Documentation

From `/home/benjamin/.config/.claude/commands/README.md` (lines 429-446):
```markdown
### --file

Allows passing a file path containing a longer description or complex requirements.

**Syntax**: `--file <path>`

**Examples**:
/plan --file /path/to/requirements.md
/debug --file /tmp/error-log.md
```

This confirms `--file` is the documented standard, not `--report`.

## Root Cause Analysis

### RC1: Missing Error Status Tracking
- **Issue**: Error log entries have no status field
- **Impact**: Cannot track which errors have repair plans in progress
- **Root Cause**: Original design focused on logging, not lifecycle management
- **Files Affected**: error-handling.sh (log_command_error function)

### RC2: Flag Naming Inconsistency
- **Issue**: /errors suggests `--report`, but standard is `--file`
- **Impact**: User confusion, command failure when following suggested usage
- **Root Cause**: /errors was developed separately without following command standards
- **Files Affected**: errors.md (line 557)

### RC3: No Plan-Error Linkage
- **Issue**: Repair plans don't reference which errors they address
- **Impact**: No traceability between error analysis and fixes
- **Root Cause**: One-way workflow (errors -> plan) without bidirectional linkage
- **Files Affected**: repair.md, repair-analyst.md

## Recommendations

### 1. Extend Error Log Schema (Priority: High, Effort: Medium)
- **Description**: Add `status` and `repair_plan_path` fields to error log entries
- **Rationale**: Enables lifecycle tracking of errors from logging through resolution
- **Implementation**:
  1. Update `log_command_error()` to include `status: "ERROR"` (default)
  2. Add `update_error_status()` function to error-handling.sh
  3. Add `mark_errors_fix_planned()` function for bulk updates
- **Schema Extension**:
```json
{
  ...existing fields...,
  "status": "ERROR|FIX_PLANNED|RESOLVED",
  "repair_plan_path": "/path/to/plan.md",
  "status_updated_at": "2025-11-23T..."
}
```

### 2. Replace --report with --file Flag (Priority: High, Effort: Low)
- **Description**: Standardize /repair command to use `--file` flag
- **Rationale**: Consistency with /plan, /debug, /research, /revise commands
- **Implementation**:
  1. Add `--file` flag parsing to repair.md (following debug.md pattern)
  2. Update errors.md line 557 to reference `--file` instead of `--report`
  3. Update repair-command-guide.md with `--file` documentation
- **Breaking Change**: None - `--report` was never implemented

### 3. Add Error-Plan Linkage to /repair Workflow (Priority: High, Effort: Medium)
- **Description**: After plan creation, update relevant error entries with plan path
- **Rationale**: Creates traceability between errors and their repair plans
- **Implementation**:
  1. Add Block 3.5 to repair.md after plan creation
  2. Query errors using same filters from Block 1
  3. Call new `mark_errors_fix_planned()` function with plan path
  4. Update only errors matching original filter criteria
- **Selective Update Logic**:
```bash
# Only update errors matching the original query filters
if [ -n "$ERROR_COMMAND" ]; then
  FILTER_ARGS="--command $ERROR_COMMAND"
fi
if [ -n "$ERROR_TYPE" ]; then
  FILTER_ARGS="$FILTER_ARGS --type $ERROR_TYPE"
fi
# ... apply same filters used for analysis
mark_errors_fix_planned "$FILTER_ARGS" "$PLAN_PATH"
```

### 4. Add Verification Step to /repair Completion (Priority: Medium, Effort: Low)
- **Description**: Display count of errors marked as FIX_PLANNED in summary
- **Rationale**: User feedback on scope of repair plan
- **Implementation**: Add to Block 3 summary section
- **Example Output**:
```
=== Repair Planning Complete ===
Errors Analyzed: 15
Errors Marked as FIX_PLANNED: 12
Plan Path: .claude/specs/924_.../plans/001_..._plan.md
```

### 5. Update /errors Command Query Capability (Priority: Medium, Effort: Low)
- **Description**: Add `--status` filter to query errors by status
- **Rationale**: Allows filtering for unresolved errors
- **Implementation**: Extend query_errors() function
- **Example Usage**:
```bash
/errors --status ERROR          # Show unresolved errors only
/errors --status FIX_PLANNED    # Show errors with pending plans
```

## Implementation Sequence

**Phase 1**: Schema Extension
- Modify error-handling.sh to add status field
- Add update functions
- Ensure backward compatibility with existing logs

**Phase 2**: Flag Standardization
- Add --file flag to repair.md
- Update errors.md output message
- Update documentation

**Phase 3**: Workflow Integration
- Add error status update block to repair.md
- Implement selective update based on filters
- Add summary output

**Phase 4**: Query Enhancement
- Add --status filter to /errors
- Update errors command documentation

## References

### Files Analyzed
- `/home/benjamin/.config/.claude/commands/repair.md` (925 lines)
- `/home/benjamin/.config/.claude/commands/errors.md` (640 lines)
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 1-200 analyzed)
- `/home/benjamin/.config/.claude/lib/core/error-handling.sh` (1549 lines)
- `/home/benjamin/.config/.claude/docs/guides/commands/repair-command-guide.md` (587 lines)
- `/home/benjamin/.config/.claude/agents/repair-analyst.md` (529 lines)
- `/home/benjamin/.config/.claude/commands/README.md` (lines 429-446 for --file documentation)
- `/home/benjamin/.config/.claude/data/logs/errors.jsonl` (97 entries analyzed)

### Key Line References
- error-handling.sh:414-510 - log_command_error() function
- error-handling.sh:605-672 - query_errors() function
- errors.md:557 - `--report` flag reference (needs change to `--file`)
- debug.md:111-155 - Standard `--file` flag implementation pattern
- repair.md:18-21 - Workflow type and terminal state
- repair-command-guide.md:23-25 - Purpose description

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001-repair-error-status-refactor-plan.md](../plans/001-repair-error-status-refactor-plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-23
