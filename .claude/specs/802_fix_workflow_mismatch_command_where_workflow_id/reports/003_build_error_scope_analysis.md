# Build Error Scope Analysis

## Summary

The build errors in `/home/benjamin/.config/.claude/build-output.md` occurred while running `/build` command (for spec 804), not `/plan`. Analysis shows:

1. **Errors are caused by the same STATE_FILE capture bug** that plan 802 addresses
2. **Plan 802 currently scopes only to plan.md** but build.md has identical bug
3. **Minimal revision required**: Expand scope to also fix build.md

## Error Analysis

### Errors from build-output.md

```
ERROR: State transition to DOCUMENT failed
ERROR: Invalid transition: implement → document
Valid transitions from implement: test
```

These errors indicate:
- State didn't persist from `implement` → `test` phase
- Subsequent transition to `document` failed because state machine thought it was still at `implement`

### Root Cause Confirmation

In `build.md` line 199:
```bash
init_workflow_state "$WORKFLOW_ID"  # STATE_FILE not captured
```

Lines 215-218 then call:
```bash
append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"
append_workflow_state "PLAN_FILE" "$PLAN_FILE"
...
```

These fail silently because `STATE_FILE` is never set, so state doesn't persist between bash blocks.

## Plan 802 Current Scope

Plan 802 correctly identifies and fixes this issue **for plan.md only**:
- Phase 1: Fix STATE_FILE capture in plan.md Block 1 (lines 140-146)
- Phase 2: Add defensive validation
- Phase 3: Testing

## Required Revision

Plan 802 should be expanded to also fix build.md since:
1. The build errors came from `/build` command, not `/plan`
2. Build.md has the identical bug at line 199
3. Fixing only plan.md won't resolve the observed errors

### Minimal Changes Needed

1. **Expand Scope** in Overview to include build.md
2. **Add Phase 1.5 or modify Phase 1** to also fix build.md:199
   - Change: `init_workflow_state "$WORKFLOW_ID"`
   - To: `STATE_FILE=$(init_workflow_state "$WORKFLOW_ID"); export STATE_FILE`
3. **Update Success Criteria** to include build.md verification
4. **Update Testing** to test both /plan and /build commands

### Alternative: Separate Spec

Could create spec 803 specifically for build.md, but:
- Duplicates same research
- Same fix pattern
- Delays resolution of observed errors

**Recommendation**: Expand plan 802 scope to include build.md

## Conclusion

Plan 802's technical approach is correct - it just needs expanded scope to fix both plan.md and build.md. The build errors will not be resolved if only plan.md is fixed.
