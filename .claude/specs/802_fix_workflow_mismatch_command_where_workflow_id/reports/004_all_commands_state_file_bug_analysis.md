# All Commands STATE_FILE Bug Analysis

## Summary

Analysis of all commands in `.claude/commands/` reveals that **5 commands** have the same STATE_FILE capture bug. The current plan (802) only addresses 2 of them (plan.md and build.md).

## Commands Affected

| Command | Line | Current Code | Status |
|---------|------|--------------|--------|
| plan.md | 146 | `init_workflow_state "$WORKFLOW_ID"` | In plan (Phase 1) |
| build.md | 199 | `init_workflow_state "$WORKFLOW_ID"` | In plan (Phase 1) |
| debug.md | 144 | `init_workflow_state "$WORKFLOW_ID"` | **NOT in plan** |
| research.md | 145 | `init_workflow_state "$WORKFLOW_ID"` | **NOT in plan** |
| revise.md | 249 | `init_workflow_state "$WORKFLOW_ID"` | **NOT in plan** |

## Required Fix for Each

All commands need the same fix pattern:

```bash
# Current (buggy)
init_workflow_state "$WORKFLOW_ID"

# Fixed
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE
```

## Impact of Not Fixing All Commands

If only plan.md and build.md are fixed:
- `/debug` will have state persistence failures
- `/research` will have state persistence failures
- `/revise` will have state persistence failures

All three commands use `append_workflow_state()` after initialization, which requires STATE_FILE to be set.

## Recommendation

**Revise plan 802 to include all 5 commands** in Phase 1:

1. **plan.md:146** - already included
2. **build.md:199** - already included
3. **debug.md:144** - ADD to plan
4. **research.md:145** - ADD to plan
5. **revise.md:249** - ADD to plan

This ensures comprehensive fix without needing separate specifications.

## Additional Considerations

### Testing Impact
Phase 3 testing should verify all 5 commands work correctly after fix.

### Time Estimate
Adding 3 more commands to Phase 1 adds approximately 0.5 hours:
- Current estimate: 2.5 hours
- Revised estimate: 3 hours

### Risk Assessment
- **Low Risk**: Same fix pattern for all commands
- **High Value**: Fixes state persistence across entire command suite
- **Consistency**: All commands use identical pattern
