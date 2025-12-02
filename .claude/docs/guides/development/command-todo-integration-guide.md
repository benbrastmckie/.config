# Command-TODO Integration Guide

## Overview

This guide documents the manual TODO.md update workflow used by commands that create or modify plans and reports. Commands display completion reminders to prompt users to manually run `/todo` for TODO.md updates.

**Key Principle**: Commands do not automatically update TODO.md. Users manually run `/todo` after command completion based on clear reminder messages.

## Architectural Constraint

**Why No Automatic Updates**: Slash commands (like `/todo`) are markdown files processed by Claude Code's runtime environment. They cannot be invoked from bash blocks using `bash -c '/todo'` or similar mechanisms. This architectural constraint makes automatic TODO.md updates from bash blocks impossible without runtime changes to Claude Code itself.

Previous attempts to work around this constraint (specs 991, 997, 015) failed because they addressed symptoms (error handling, documentation) rather than the root cause (architectural impossibility).

## Scope

Nine commands implement the manual reminder pattern:

| Command | Artifact Type | Reminder Location |
|---------|--------------|-------------------|
| `/build` | Build completion | Completion summary |
| `/plan` | New plan | Completion summary |
| `/research` | Research report | Completion summary |
| `/debug` | Debug report | Completion summary |
| `/repair` | Repair plan | Completion summary |
| `/errors` | Error analysis | Completion summary |
| `/revise` | Revised plan | Completion summary |
| `/test` | Test results | Completion summary |
| `/implement` | Implementation summary | Completion summary |

## Manual Reminder Pattern

All commands use the same standardized reminder pattern:

### Pattern: Completion Reminder

Commands display this reminder immediately before exit:

```bash
# Emit completion reminder
echo ""
echo "📋 Next Step: Run /todo to update TODO.md with this [artifact-type]"
echo ""
```

### Integration with Next Steps

Commands also include the manual step in their "Next Steps" section:

```bash
NEXT_STEPS="  • Review [artifact]: cat $ARTIFACT_PATH
  • [Command-specific action]
  • Run /todo to update TODO.md (adds [artifact] to tracking)"
```

## Implementation Examples

### Example 1: /plan Command

```bash
# Build next steps
NEXT_STEPS="  • Review plan: cat $PLAN_PATH
  • Begin implementation: /build $PLAN_PATH
  • Review research: ls -lh $RESEARCH_DIR/
  • Run /todo to update TODO.md (adds plan to tracking)"

# Print standardized summary (no phases for plan command)
print_artifact_summary "Plan" "$SUMMARY_TEXT" "" "$ARTIFACTS" "$NEXT_STEPS"

# Emit completion reminder
echo ""
echo "📋 Next Step: Run /todo to update TODO.md with this plan"
echo ""

# === RETURN PLAN_CREATED SIGNAL ===
if [ -n "$PLAN_PATH" ] && [ -f "$PLAN_PATH" ]; then
  echo ""
  echo "PLAN_CREATED: $PLAN_PATH"
  echo ""
fi

exit 0
```

### Example 2: /build Command

```bash
# Build next steps
if [ "$TESTS_PASSED" = "true" ]; then
  NEXT_STEPS="  • Review summary: cat $LATEST_SUMMARY
  • Check git commits: git log --oneline -5
  • Review plan updates: cat $PLAN_FILE
  • Run /todo to update TODO.md (adds completed plan to tracking)"
else
  NEXT_STEPS="  • Review debug output: cat $LATEST_SUMMARY
  • Fix remaining issues and re-run: /build $PLAN_FILE
  • Check test failures: see summary for details
  • Run /todo to update TODO.md when complete"
fi

# Print standardized summary
print_artifact_summary "Build" "$SUMMARY_TEXT" "$PHASES" "$ARTIFACTS" "$NEXT_STEPS"

# Emit completion reminder
echo ""
echo "📋 Next Step: Run /todo to update TODO.md with this build"
echo ""

# === RETURN IMPLEMENTATION_COMPLETE SIGNAL ===
if [ -n "$LATEST_SUMMARY" ] && [ -f "$LATEST_SUMMARY" ]; then
  echo ""
  echo "IMPLEMENTATION_COMPLETE"
  echo "  summary_path: $LATEST_SUMMARY"
  echo "  plan_path: $PLAN_FILE"
  echo ""
fi
```

### Example 3: /research Command

```bash
# Build next steps
NEXT_STEPS="  • Review reports: ls -lh $RESEARCH_DIR/
  • Create implementation plan: /plan \"${WORKFLOW_DESCRIPTION}\"
  • Run full workflow: /coordinate \"${WORKFLOW_DESCRIPTION}\"
  • Run /todo to update TODO.md (adds research to tracking)"

# Print standardized summary (no phases for research command)
print_artifact_summary "Research" "$SUMMARY_TEXT" "" "$ARTIFACTS" "$NEXT_STEPS"

# Emit completion reminder
echo ""
echo "📋 Next Step: Run /todo to update TODO.md with this research"
echo ""

# === RETURN REPORT_CREATED SIGNAL ===
LATEST_REPORT=$(ls -t "$RESEARCH_DIR"/*.md 2>/dev/null | head -1)
if [ -n "$LATEST_REPORT" ] && [ -f "$LATEST_REPORT" ]; then
  echo ""
  echo "REPORT_CREATED: $LATEST_REPORT"
  echo ""
fi

exit 0
```

## Anti-Patterns (Do NOT Use)

### Anti-Pattern 1: Automatic Invocation (Broken)

```bash
# ❌ DOES NOT WORK - bash blocks cannot invoke slash commands
if bash -c '/todo' >/dev/null 2>&1; then
  echo "TODO.md updated"
fi
```

### Anti-Pattern 2: Function Call (Removed)

```bash
# ❌ REMOVED - trigger_todo_update() function no longer exists
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh"
trigger_todo_update "plan created"
```

### Anti-Pattern 3: Direct TODO.md Modification

```bash
# ❌ VIOLATES SINGLE SOURCE OF TRUTH
# Never modify TODO.md directly - let /todo command handle regeneration
echo "- [ ] My plan" >> .claude/TODO.md
```

## User Workflow

When commands complete, users see clear guidance:

```
═══════════════════════════════════════════════════════
PLAN CREATION COMPLETE
═══════════════════════════════════════════════════════

## Summary
Created implementation plan with 5 phases (estimated 4-6 hours).

## Artifacts
  📊 Reports: /path/to/reports/ (3 files)
  📄 Plan: /path/to/plan.md

## Next Steps
  • Review plan: cat /path/to/plan.md
  • Begin implementation: /build /path/to/plan.md
  • Review research: ls -lh /path/to/reports/
  • Run /todo to update TODO.md (adds plan to tracking)

📋 Next Step: Run /todo to update TODO.md with this plan

PLAN_CREATED: /path/to/plan.md
```

Users then manually run:
```bash
/todo
```

This regenerates TODO.md to include the new artifact.

## Benefits of Manual Workflow

1. **Honest Implementation**: Respects architectural constraints rather than fighting them
2. **Clear User Guidance**: Explicit reminders make the workflow obvious
3. **No Silent Failures**: Eliminates broken automatic update attempts that fail silently
4. **Fast Execution**: `/todo` runs quickly (1-2 seconds), minimal friction
5. **Single Source of Truth**: All TODO.md logic remains in `/todo` command
6. **Maintainable**: Simple pattern, easy to understand and modify

## Migration from Automatic Pattern

If migrating a command from the old automatic pattern:

### Step 1: Remove trigger_todo_update() Call

```bash
# REMOVE THIS:
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
  echo "WARNING: Failed to source todo-functions.sh for TODO.md update" >&2
}
if type trigger_todo_update &>/dev/null; then
  trigger_todo_update "reason"
fi
```

### Step 2: Add Reminder to Next Steps

```bash
# ADD THIS to NEXT_STEPS variable:
NEXT_STEPS="  • [existing steps]
  • Run /todo to update TODO.md (adds [artifact] to tracking)"
```

### Step 3: Add Standalone Reminder

```bash
# ADD THIS before exit or return signal:
echo ""
echo "📋 Next Step: Run /todo to update TODO.md with this [artifact]"
echo ""
```

## Troubleshooting

### TODO.md Not Updating

**Problem**: User reports TODO.md doesn't show new plan/report.

**Solution**: User forgot to run `/todo` manually. Check command output for reminder message.

### Stale TODO.md Content

**Problem**: TODO.md shows outdated information.

**Solution**: Run `/todo` to regenerate from current project state. The command scans all plan files and rebuilds TODO.md from scratch.

### Users Want Automatic Updates

**Problem**: Users request automatic TODO.md updates.

**Solution**: Explain architectural constraint. Fast `/todo` execution (1-2 seconds) keeps manual step minimal. If Claude Code runtime adds callback/signal support in the future, automatic updates could be revisited.

## Testing

Commands should verify:

1. **Reminder Present**: Check that completion output includes "📋 Next Step: Run /todo to update TODO.md"
2. **Next Steps Includes /todo**: Verify NEXT_STEPS variable mentions running /todo
3. **No trigger_todo_update Calls**: Ensure command doesn't call removed function
4. **No Direct TODO.md Modification**: Confirm command never writes to .claude/TODO.md directly

Example test:
```bash
# Test reminder message present
OUTPUT=$(/plan "test feature" 2>&1)
if echo "$OUTPUT" | grep -q "Run /todo to update TODO.md"; then
  echo "✓ PASS: Reminder present"
else
  echo "✗ FAIL: Missing reminder"
fi

# Test no trigger_todo_update calls
if ! grep -q "trigger_todo_update" .claude/commands/plan.md; then
  echo "✓ PASS: No trigger_todo_update calls"
else
  echo "✗ FAIL: Found trigger_todo_update call"
fi
```

## Standards Compliance

This pattern complies with:

- **Clean-Break Development Standard**: Complete removal of broken pattern, no deprecation period
- **Output Formatting Standards**: Reminder uses emoji marker and clear formatting
- **Documentation Standards**: No historical commentary, reflects current implementation only

## See Also

- [TODO Command Guide](../commands/todo-command-guide.md)
- [TODO Library README](../../lib/todo/README.md)
- [Clean-Break Development Standard](../../reference/standards/clean-break-development.md)
- [Output Formatting Standards](../../reference/standards/output-formatting.md)
