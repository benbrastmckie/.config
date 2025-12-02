# TODO.md Update Pattern Analysis

## Summary

The TODO.md update mechanism across commands has an inconsistency where 5 commands use a broken pattern that silently fails, while 3 commands use the correct `trigger_todo_update()` function.

## Problem Statement

When commands like `/plan` complete and attempt to update TODO.md, the update silently fails. This causes newly created plans to not appear in TODO.md until a manual `/todo` run.

## Root Cause Analysis

### Broken Pattern (5 commands affected)

The following pattern is used by `/plan`, `/build`, `/implement`, `/revise`, and `/research`:

```bash
bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true
echo "✓ Updated TODO.md"
```

**Why it fails**:
1. `.claude/commands/todo.md` is a markdown file, not an executable bash script
2. Attempting to execute a markdown file with bash causes a syntax error
3. The `2>/dev/null || true` suppresses all errors, making failure invisible
4. The success message is printed regardless of actual outcome

### Correct Pattern (3 commands use this)

The following pattern is used by `/repair`, `/errors`, and `/debug`:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
  echo "ERROR: Failed to source todo-functions.sh" >&2
  exit 1
}
# ... later in the code ...
trigger_todo_update "reason for update"
```

This correctly:
1. Sources the todo-functions.sh library
2. Uses the `trigger_todo_update()` function which handles the update properly

## Affected Commands

| Command | File | Line | Pattern | Status |
|---------|------|------|---------|--------|
| /plan | commands/plan.md | 1508 | `bash -c...todo.md` | BROKEN |
| /build | commands/build.md | 347, 1061 | `bash -c...todo.md` | BROKEN |
| /implement | commands/implement.md | 346, 1058 | `bash -c...todo.md` | BROKEN |
| /revise | commands/revise.md | 1292 | `bash -c...todo.md` | BROKEN |
| /research | commands/research.md | 1235 | `bash -c...todo.md` | BROKEN |
| /repair | commands/repair.md | 1460 | `trigger_todo_update()` | Working |
| /errors | commands/errors.md | 723-724 | `trigger_todo_update()` | Working |
| /debug | commands/debug.md | 1485, 1488 | `trigger_todo_update()` | Working |

## Implementation Context

### Recent Refactor (991_commands_todo_tracking_refactor)

The implementation summary from `991_commands_todo_tracking_refactor` shows that `/repair`, `/errors`, and `/debug` were updated to use the delegation pattern with `trigger_todo_update()`. However, the remaining 5 commands were not updated.

From the summary:
> Successfully implemented TODO.md integration for /repair, /errors, and /debug commands using the delegation pattern.

The scope was limited to those 3 commands, leaving the other 5 with the broken pattern.

### trigger_todo_update() Function

Located in `.claude/lib/todo/todo-functions.sh` (lines 1113-1133):

```bash
trigger_todo_update() {
  local reason="${1:-TODO.md update}"

  # Delegate to /todo command silently (suppress output)
  if bash -c "cd \"${CLAUDE_PROJECT_DIR}\" && /todo" >/dev/null 2>&1; then
    echo "✓ Updated TODO.md ($reason)"
    return 0
  else
    # Non-blocking: log warning but don't fail command
    echo "WARNING: Failed to update TODO.md ($reason)" >&2
    return 0  # Return success to avoid blocking parent command
  fi
}
```

**Note**: This function also has a potential issue - it tries to run `/todo` directly which may not work in all contexts. However, it does provide proper error handling and non-blocking behavior.

## Required Changes

### For Each Affected Command

1. **Add library sourcing** (if not already present):
   ```bash
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
     echo "ERROR: Failed to source todo-functions.sh" >&2
     exit 1
   }
   ```

2. **Replace broken pattern** with:
   ```bash
   trigger_todo_update "descriptive reason"
   ```

### Specific Changes by Command

| Command | Reason String |
|---------|---------------|
| /plan | `"plan created"` |
| /build | `"build phase completed"` |
| /implement | `"implementation phase completed"` |
| /revise | `"plan revised"` |
| /research | `"research report created"` |

## Testing Strategy

1. **Unit Test**: Verify `trigger_todo_update()` is called after artifact creation
2. **Integration Test**: Run each command and verify TODO.md is updated
3. **Regression Test**: Ensure existing TODO.md content is preserved (Backlog, Saved sections)

## Success Criteria

- [ ] All 5 affected commands source `todo-functions.sh`
- [ ] All 5 affected commands use `trigger_todo_update()` with descriptive reason
- [ ] No silent failures - warnings are logged on update failure
- [ ] TODO.md reflects newly created plans/reports after command completion
- [ ] Existing TODO.md sections (Backlog, Saved) are preserved

## Risk Assessment

**Risk Level**: Low

- Changes are isolated to TODO.md update logic
- Non-blocking design prevents command failures
- Existing working pattern in 3 commands serves as template
- No changes to core command functionality

## References

- Implementation Summary: `.claude/specs/991_commands_todo_tracking_refactor/summaries/001-implementation-summary.md`
- TODO Functions Library: `.claude/lib/todo/todo-functions.sh`
- TODO Organization Standards: `.claude/docs/reference/standards/todo-organization-standards.md`
