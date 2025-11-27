# Research Report: /build Command Subagent Bypass Analysis

## Metadata
- **Date**: 2025-11-26
- **Research Topic**: Why /build command is bypassing subagent delegation
- **Related**: Original plan for /revise subagent delegation refactor
- **Evidence**: /home/benjamin/.config/.claude/build-output.md

## Executive Summary

The `/build` command exhibits the same subagent bypass behavior as `/revise`. When examining `build-output.md`, the primary orchestrator performed all implementation work directly instead of delegating to the `implementer-coordinator` subagent. This is a systemic issue affecting the orchestrator command architecture, not isolated to `/revise`.

## Root Cause Analysis

### Problem Statement

The `/build` command output shows the orchestrator:
1. Reading the plan file directly (lines 18-20)
2. Exploring codebase patterns directly (lines 26-99)
3. Writing files directly (line 105: `Write(.claude/hooks/post-buffer-opener.sh)`)
4. Updating settings directly (line 188: `Update(.claude/settings.local.json)`)
5. Never invoking `Task(implementer-coordinator)` despite command structure defining it

### Root Cause: Non-Executable Task Pseudo-Code

The Task invocations in command files use a pseudo-code format:

```
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan..."
  prompt: "..."
}
```

This format:
1. **Looks like documentation** - Not valid markdown code block or executable syntax
2. **Is interpreted as guidance** - Claude treats it as helpful context, not mandatory action
3. **Lacks enforcement mechanism** - No bash block immediately follows that verifies Task was invoked
4. **Allows optimization bypass** - When the orchestrator has all necessary tools (Read, Write, Edit, Bash), it may decide doing the work directly is "more efficient"

### Evidence from build-output.md

```
Line 14: "Now I need to invoke the implementer-coordinator agent to execute the
          implementation plan. Let me read the plan first..."
Line 18: Read(.claude/specs/.../plans/001_...plan.md)
Line 22: "Now I have a complete understanding of the plan..."
Line 26: "Now let me check existing hooks..."
```

The orchestrator acknowledged the need to invoke the subagent but then proceeded to do the work itself. This indicates the Task pseudo-code format does not create a hard barrier.

### Comparison: /plan vs /build

| Aspect | /plan (Working) | /build (Broken) |
|--------|-----------------|-----------------|
| Task invocations | 3 (topic-naming, research, plan-architect) | 1 (implementer-coordinator) |
| Invocation success rate | 100% (all 3 invoked) | 0% (0 of 1 invoked) |
| Execution complexity | Lower (research + plan creation) | Higher (multi-phase implementation) |
| Orchestrator behavior | Delegated correctly | Bypassed subagent |

The difference suggests that when the work complexity is higher and the orchestrator has the tools to do it, it's more likely to bypass delegation.

### Contributing Factors

1. **Complex task description**: The implementer-coordinator prompt contains detailed instructions that the orchestrator interprets as "what to do" rather than "what to delegate"

2. **Allowed tools overlap**: `/build` has `allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob` - all tools needed to do implementation directly

3. **No verification checkpoint**: Unlike `/plan` which has bash verification blocks after each Task invocation, `/build` structure allows continuation without verifying Task was called

4. **Iteration loop structure**: The build command has an iteration check block that assumes AGENT_WORK_REMAINING will be set by the subagent, but when no subagent runs, this variable is empty causing fallback logic to run

## Implications for Plan Revision

The original plan to refactor `/revise` is correct in its approach, but needs expansion to:

1. **Document that /build has the same problem** - This is not a /revise-only issue
2. **Prioritize /build fix alongside /revise** - Both commands need the same structural fix
3. **Establish a pattern for all orchestrator commands** - Create reusable hard barrier pattern
4. **Add verification for /build** - Implement the same Setup -> Execute -> Verify pattern

## Recommended Plan Additions

### New Phase 0: Audit All Orchestrator Commands

Before fixing individual commands, audit which commands have subagent bypass risk:
- `/build` - CONFIRMED bypass issue
- `/revise` - CONFIRMED bypass issue
- `/plan` - Working but should be verified
- `/research` - Should be audited
- `/debug` - Should be audited
- `/repair` - Should be audited

### New Phase 7: Apply Pattern to /build

After completing /revise refactor, apply the same pattern to /build:
- Split implementation phase into Setup -> Execute -> Verify
- Add mandatory Task invocation barrier
- Add verification that implementer-coordinator actually ran

### Hard Barrier Pattern (Reusable)

The fix pattern should be extracted into documentation for all orchestrators:

```markdown
## Phase N: [Task Name]

### Block Na: Setup
```bash
# Pre-execution setup
# Persist variables for subagent
# Add BARRIER_CHECKPOINT marker
echo "BARRIER: Ready for [subagent] invocation"
```

### Block Nb: Execute (MANDATORY TASK INVOCATION)

**CRITICAL BARRIER**: The following Task invocation is MANDATORY. The verification block below WILL FAIL if this Task is not executed.

Task {
  subagent_type: "general-purpose"
  ...
}

### Block Nc: Verify
```bash
# VERIFICATION: Task invocation occurred
# Check for artifacts that subagent should have created
if [ ! -f "$EXPECTED_ARTIFACT" ]; then
  echo "ERROR: [subagent] did not create required artifact" >&2
  echo "DIAGNOSTIC: Task invocation may have been bypassed" >&2
  exit 1
fi
```
```

This pattern makes bypass impossible because:
1. Setup block ends with barrier checkpoint
2. Execute block has CRITICAL BARRIER label
3. Verify block fails if subagent artifacts missing

## Conclusions

1. The subagent bypass issue is **systemic** across orchestrator commands
2. The fix approach in the current plan is **correct**
3. The plan scope should be **expanded** to include /build
4. A **reusable pattern** should be documented for all orchestrators
5. The root cause is **structural** (pseudo-code format, no verification)
6. The solution is **architectural** (hard barriers, mandatory verification)

## Next Steps

1. Revise plan to add /build fix phases
2. Create shared hard barrier pattern documentation
3. Implement fixes for both /revise and /build
4. Audit remaining orchestrator commands
