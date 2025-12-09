# Research Report: Hard Barrier Pattern Implementation in lean-plan

**Date**: 2025-12-08
**Topic**: Hard Barrier Pattern Implementation in lean-plan
**Research Specialist**: research-specialist
**Status**: COMPLETED

## Executive Summary

Analysis of /lean-plan command reveals three critical issues preventing proper Hard Barrier Pattern implementation and error logging integration. These issues cause validation failures and malformed error log entries.

## Critical Issues Found

### Issue 1: Incorrect `log_command_error` Signature (HIGH SEVERITY)

**Location**: `.claude/commands/lean-plan.md`, Block 1d-topics (lines 916-922)

The current code uses an incorrect 3-parameter signature:
```bash
log_command_error "validation_error" \
  "Report path is not absolute" \
  "REPORT_FILE=$REPORT_FILE must start with / for Hard Barrier Pattern"
```

**Required 7-parameter signature** (per error-handling.sh):
```bash
log_command_error \
  "$COMMAND_NAME" \
  "$WORKFLOW_ID" \
  "$USER_ARGS" \
  "validation_error" \
  "Report path is not absolute" \
  "bash_block_1d_topics" \
  "$(jq -n --arg path "$REPORT_FILE" '{report_file: $path}')"
```

**Same issue exists**:
- Block 1f at lines 1081-1083
- Block 1f at lines 1121-1123

### Issue 2: Missing `setup_bash_error_trap` Parameters (MEDIUM SEVERITY)

**Location**: Line 872 - called without parameters

**Current**:
```bash
setup_bash_error_trap
```

**Fix**: Add workflow context parameters:
```bash
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "${USER_ARGS:-}"
```

### Issue 3: Missing Error Logging Context Restoration (MEDIUM SEVERITY)

After sourcing the state file at line 859, error logging context variables may be lost.

**Fix**: Add explicit context restoration after state load:
```bash
# After line 859 (source "$LEAN_PLAN_STATE")
COMMAND_NAME="${COMMAND_NAME:-/lean-plan}"
USER_ARGS="${USER_ARGS:-$FEATURE_DESCRIPTION}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID
```

## Impact Analysis

Without these fixes, the Hard Barrier Pattern validation in Block 1d-topics will:

1. **Fail to log errors properly** to errors.jsonl (wrong parameter count)
2. **Produce malformed log entries** if errors occur (missing required fields)
3. **Lose workflow context** in ERR trap scenarios (missing trap parameters)

## Recommendations

1. **CRITICAL**: Update all `log_command_error` calls to use 7-parameter signature
2. **HIGH**: Add parameters to `setup_bash_error_trap` call at line 872
3. **MEDIUM**: Add error logging context restoration after state file sourcing
4. **VALIDATION**: Test error logging by triggering validation failures intentionally

## References

- Error Handling Library: `.claude/lib/core/error-handling.sh`
- Command File: `.claude/commands/lean-plan.md`
- Error Logging Standards: `.claude/docs/reference/standards/error-logging.md`
