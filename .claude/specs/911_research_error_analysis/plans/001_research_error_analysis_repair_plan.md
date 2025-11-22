# /research Command Error Repair Plan

## Metadata
- **Date**: 2025-11-21
- **Feature**: /research command error fixes
- **Scope**: Fix 3 identified error patterns from error analysis report
- **Estimated Phases**: 3
- **Estimated Hours**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 16 (Tier 1: single file)
- **Structure Level**: 0
- **Research Reports**:
  - [Error Analysis Report](../reports/001_error_report.md)

## Overview

This repair plan addresses three error patterns identified in the `/research` command error analysis report:

1. **Benign /etc/bashrc sourcing errors** (exit code 127) - verify filtering works
2. **Workflow state return error** at error-handling.sh:384 - add error context
3. **Research topics array validation error** - review and potentially downgrade severity

All fixes are LOW-RISK and focus on improving error handling clarity without breaking existing functionality.

## Research Summary

Key findings from the error analysis report:

- **Benign Error Filtering**: The `_is_benign_bash_error()` function already exists and should filter `/etc/bashrc` errors with exit code 127. The logged error suggests either the filter is not catching this case or the error is being logged before the filter check.
- **Return 1 at Line 384**: The error originated from `log_error_context()` function's parameter setup, not an actual failure. This is likely a stack trace artifact.
- **Research Topics Fallback**: The fallback behavior is working correctly (graceful degradation), so the validation_error severity may be inappropriate - should be downgraded to a warning.

Recommended approach: Verify existing filters work, add contextual logging, and adjust severity levels.

## Success Criteria

- [ ] `/etc/bashrc` sourcing errors with exit code 127 are properly filtered (not logged)
- [ ] Error-handling.sh return statements have clear context in error logs
- [ ] Research topics fallback uses warning level instead of error level
- [ ] All existing /research functionality remains intact
- [ ] No regression in other commands that use these libraries

## Technical Design

### Architecture Overview

The error logging system uses a centralized approach with:
- `_is_benign_bash_error()` - Filter function for benign system errors
- `_log_bash_error()` - ERR trap handler that logs errors
- `log_command_error()` - Main error logging function

### Design Decisions

1. **Filter Verification**: Add test case to ensure `. /etc/bashrc` with exit 127 triggers benign filter
2. **Context Enhancement**: No code change needed at line 384 - it's already within `log_error_context()`
3. **Severity Downgrade**: Change `log_command_error` call in workflow-initialization.sh from `validation_error` to emit warning to stderr only (no JSON logging)

## Implementation Phases

### Phase 1: Verify and Test Benign Error Filtering [COMPLETE]
dependencies: []

**Objective**: Confirm that `/etc/bashrc` sourcing errors with exit code 127 are properly filtered by existing `_is_benign_bash_error()` function.

**Complexity**: Low

**Tasks**:
- [x] Review `_is_benign_bash_error()` function in `/home/benjamin/.config/.claude/lib/core/error-handling.sh` (lines 1244-1313)
- [x] Verify the `. /etc/bashrc` command pattern is covered by case statement (line 1258)
- [x] Check that exit code 127 filtering applies to bashrc-related commands (lines 1263-1270)
- [x] Create unit test to verify filter catches: `_is_benign_bash_error ". /etc/bashrc" 127`
- [x] Add test case for `/etc/bashrc` path pattern: `_is_benign_bash_error "/etc/bashrc" 127`

**Testing**:
```bash
# Test benign error filter directly
cd /home/benjamin/.config
source .claude/lib/core/error-handling.sh
_is_benign_bash_error ". /etc/bashrc" 127 && echo "PASS: Filtered" || echo "FAIL: Not filtered"
_is_benign_bash_error "source /etc/bashrc" 127 && echo "PASS: Filtered" || echo "FAIL: Not filtered"
```

**Expected Duration**: 1 hour

---

### Phase 2: Review Return Statement Error Context [COMPLETE]
dependencies: [1]

**Objective**: Investigate the line 384 return statement error and determine if additional context logging is needed.

**Complexity**: Low

**Tasks**:
- [x] Read context around line 384 in `/home/benjamin/.config/.claude/lib/core/error-handling.sh`
- [x] Confirm line 384 is within `log_error_context()` function (lines 379-404)
- [x] Determine if this is a false positive (function setup code, not actual error)
- [x] Verify `_is_benign_bash_error` catches `return 1` from library files (lines 1274-1292)
- [x] If filter is working: Document as known benign pattern in troubleshooting docs
- [x] If filter is NOT working: Add specific case for error-handling.sh returns

**Analysis Required**:
The error log shows:
```json
{
  "line": 384,
  "exit_code": 1,
  "command": "return 1"
}
```

Line 384 in error-handling.sh is:
```bash
  local context_data="${4:-{}}"
```

This is a parameter assignment, NOT a `return 1` statement. The error may be a stack trace issue where the ERR trap caught a return from a called function.

**Testing**:
```bash
# Test that return 1 from library files is filtered
cd /home/benjamin/.config
source .claude/lib/core/error-handling.sh
_is_benign_bash_error "return 1" 1 && echo "PASS: Return filtered" || echo "FAIL: Return not filtered"
```

**Expected Duration**: 0.5 hours

---

### Phase 3: Downgrade Research Topics Fallback Severity [COMPLETE]
dependencies: [1]

**Objective**: Change research topics empty array handling from error logging to warning-only stderr output.

**Complexity**: Low

**Tasks**:
- [x] Edit `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` lines 169-182
- [x] Remove `log_command_error` call for empty research_topics (this logs to JSON)
- [x] Keep the stderr warning message: `echo "WARNING: research_topics empty..." >&2`
- [x] Add comment explaining why this is warning-level (fallback works correctly)
- [x] Verify fallback slug generation still works after change

**Before** (lines 169-182):
```bash
if [ "$research_topics" = "[]" ] || [ -z "$research_topics" ] || [ "$research_topics" = "null" ]; then
    # Log warning (not error) for fallback scenario
    if declare -f log_command_error >/dev/null 2>&1; then
      log_command_error \
        "${COMMAND_NAME:-/unknown}" \
        "${WORKFLOW_ID:-unknown}" \
        "${USER_ARGS:-}" \
        "validation_error" \
        "research_topics array empty or missing - using fallback defaults" \
        "validate_and_generate_filename_slugs" \
        "$(jq -n --arg result "$classification_result" --arg topics "$research_topics" \
           '{classification_result: $result, research_topics: $topics, action: "using_fallback"}')"
    fi
    echo "WARNING: research_topics empty - generating fallback slugs" >&2
```

**After**:
```bash
if [ "$research_topics" = "[]" ] || [ -z "$research_topics" ] || [ "$research_topics" = "null" ]; then
    # WARNING only (not error): Fallback behavior works correctly
    # LLM classification agent sometimes returns valid topic_directory_slug with empty research_topics
    # This is handled gracefully by generating sequential fallback slugs
    echo "WARNING: research_topics empty - generating fallback slugs" >&2
```

**Testing**:
```bash
# Run /research with a prompt that might trigger empty topics
# Verify no validation_error appears in error log after fix
tail -5 /home/benjamin/.config/.claude/data/logs/errors.jsonl | jq 'select(.error_type == "validation_error")'
```

**Expected Duration**: 1 hour

---

### Phase 4: Validation and Documentation [COMPLETE]
dependencies: [2, 3]

**Objective**: Verify all fixes work together and document the changes.

**Complexity**: Low

**Tasks**:
- [x] Run full test suite for error-handling library
- [x] Execute `/research` command with test query
- [x] Verify error log does not contain new benign errors
- [x] Run unit test file: `/home/benjamin/.config/.claude/tests/unit/test_benign_error_filter.sh`
- [x] Update troubleshooting documentation if needed

**Testing**:
```bash
# Verify no new errors logged after fixes
cd /home/benjamin/.config
ERROR_COUNT_BEFORE=$(wc -l < .claude/data/logs/errors.jsonl 2>/dev/null || echo 0)
# (Run /research test here)
ERROR_COUNT_AFTER=$(wc -l < .claude/data/logs/errors.jsonl 2>/dev/null || echo 0)
echo "New errors: $((ERROR_COUNT_AFTER - ERROR_COUNT_BEFORE))"
```

**Expected Duration**: 0.5 hours

## Testing Strategy

### Unit Tests
- Test `_is_benign_bash_error()` with all bashrc-related patterns
- Test filter with various exit codes (1, 127)
- Test return statement filtering from library paths

### Integration Tests
- Run `/research` command end-to-end
- Verify error log does not contain filtered error types
- Check stderr for appropriate warning messages

### Regression Tests
- Verify other commands (`/build`, `/plan`, `/debug`) still work
- Check that real errors are still logged properly

## Documentation Requirements

- Update `/home/benjamin/.config/.claude/docs/troubleshooting/exit-code-127-command-not-found.md` if new patterns discovered
- Add inline comments explaining severity downgrade rationale
- No new documentation files needed (fixes are internal)

## Dependencies

- **Required Libraries**:
  - `.claude/lib/core/error-handling.sh` - Main error handling with benign filter
  - `.claude/lib/workflow/workflow-initialization.sh` - Research topics validation
- **Test Infrastructure**:
  - `.claude/tests/unit/test_benign_error_filter.sh` - Unit test file for filter

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Filter too aggressive | Low | Medium | Keep existing patterns, only verify |
| Real errors suppressed | Low | High | Test with intentional errors |
| Workflow regression | Very Low | Medium | Run full test suite after changes |

## Rollback Plan

All changes are isolated to two files:
1. `error-handling.sh` - Test-only changes (unit tests), no production code changes unless filter needs fix
2. `workflow-initialization.sh` - Single code block change (removable)

If issues arise:
```bash
git checkout .claude/lib/workflow/workflow-initialization.sh
```
