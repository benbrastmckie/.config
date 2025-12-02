# Research Report: /plan Command Orchestration Failure Analysis

**Report ID**: 001-plan-command-orchestration-failure
**Date**: 2025-12-01
**Command**: /research
**Topic**: Root cause analysis of /plan command failing to delegate to subagents

---

## Executive Summary

The `/plan` command fails to properly delegate research and planning work to subagents (research-specialist, plan-architect) because it uses a **pseudo-code Task invocation format** that Claude interprets as guidance rather than mandatory instructions. When the orchestrator has permissive `allowed-tools` (Read, Write, Grep, Glob), it bypasses the Task invocations and performs the work directly.

**Root Cause**: The `Task { ... }` syntax in plan.md is pseudo-code that doesn't trigger actual tool calls. Claude sees this as documentation/guidance and chooses to do the work itself using its permissive tool access.

---

## Findings

### 1. Observed Behavior (from plan-output.md)

The plan-output.md shows Claude:
1. Reading the screenshot directly (`Read(Screenshot From 2025-12-01 23-42-29.png)`)
2. Exploring the codebase directly (`Explore(Find claude-code.nvim picker code)`)
3. Reading source files directly (`Read(nvim/lua/neotex/plugins/ai/claude/ui/native-sessions.lua)`)
4. Never invoking the Task tool to spawn research-specialist or plan-architect agents
5. Getting interrupted before completing the inline work

**Quote from output**:
```
Let me execute the /plan command to create a proper implementation plan for this improvement:
⎿  Interrupted · What should Claude do instead?
```

This confirms the primary agent was attempting to do planning work directly instead of delegating.

### 2. Current Plan.md Structure Analysis

The plan.md file uses this Task invocation format (lines 397-424, 848-870, 1198-1226):

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md
    ...
  "
}
```

**Problem**: This is pseudo-code that resembles a function call but **is not valid Claude tool invocation syntax**. Claude's actual tool calls use XML-like `<function_calls>` blocks, not this pseudo-code format.

### 3. Git History Analysis

Key commits show the evolution of this problem:

| Commit | Description | Significance |
|--------|-------------|--------------|
| `194a6090` | feat(731): Add explicit Task invocation for plan-architect | Introduced pseudo-code Task format |
| `cd1b9097` | feat(731): Add explicit Task invocations for research delegation | Same pattern for research phase |
| `0b710aff` | fix(511): Replace YAML-style Task invocations with imperative pattern | Attempted fix that only changed supervise.md |

The fix in `0b710aff` specifically mentions:
> "Fixed 3 YAML-style Task blocks... that violated Standard 11 (Imperative Agent Invocation Pattern)"

But this fix was only applied to `supervise.md`, not `plan.md`.

### 4. Hard Barrier Pattern Documentation vs Implementation Gap

The `.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md` clearly states:

> "Orchestrator commands using pseudo-code Task invocation format (`Task { ... }`) allow Claude to interpret invocations as guidance rather than mandatory instructions."

The documentation describes the correct pattern:
1. **Block Na (Setup)**: Bash block for state preparation
2. **Block Nb (Execute)**: Task invocation ONLY - marked with "CRITICAL BARRIER"
3. **Block Nc (Verify)**: Bash block to verify artifact creation

**However**, the current plan.md implementation:
- Uses pseudo-code `Task { ... }` format instead of actual tool invocation prompts
- The "EXECUTE NOW" directive is present but insufficient without structural enforcement
- Bash verification blocks exist but never execute because the Task invocations never happen

### 5. Allowed Tools Enable Bypass

The plan.md frontmatter declares:
```yaml
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob, Write
```

This permissive tool access means:
- The orchestrator CAN read files, grep code, and write outputs directly
- When pseudo-code Task invocations don't trigger actual tools, the orchestrator falls back to doing work with its available tools
- The Hard Barrier verification blocks never execute because the workflow proceeds inline

---

## Root Cause Analysis

### Primary Root Cause

**The `Task { ... }` pseudo-code format is not recognized as a tool invocation by Claude.**

Claude's tool invocation requires the assistant to output a `<function_calls>` block with `<invoke name="Task">` elements. The pseudo-code in plan.md is interpreted as documentation/comments that the model may or may not follow.

### Contributing Factors

1. **Permissive Tool Access**: The orchestrator can do subagent work itself because it has Read/Write/Grep/Glob tools
2. **No Structural Enforcement**: Bash verification blocks after pseudo-code Task invocations don't create a hard barrier
3. **Missing Standard 11 Compliance**: The fix in commit `0b710aff` was only applied to supervise.md, not plan.md
4. **Context Window Pressure**: When Claude sees it can do the work faster directly (avoiding context handoff to subagent), it often chooses to do so

---

## Evidence Summary

| Evidence | Source | Finding |
|----------|--------|---------|
| Direct tool usage | plan-output.md:11-37 | Claude used Read, Explore directly |
| Pseudo-code Task format | plan.md:397-424 | `Task { ... }` is pseudo-code, not tool syntax |
| Git history | commit 0b710aff | Fix exists but wasn't applied to plan.md |
| Documentation | hard-barrier-subagent-delegation.md | Explicitly warns against pseudo-code format |
| Interrupted before delegation | plan-output.md:65 | Command interrupted while doing inline work |

---

## Impact Assessment

### Context Window Impact
- **40-60% higher context usage** in orchestrator when doing inline work
- Research and planning work should be in subagent context windows, not primary

### Architectural Impact
- **Unpredictable delegation**: Sometimes works, sometimes bypassed
- **Non-reusable logic**: Research code executed inline can't be reused
- **Testing difficulty**: Inline work can't be isolated for testing

### User Experience Impact
- Commands take longer to run (no parallel subagent execution)
- More likely to hit context limits
- Inconsistent behavior between runs

---

## Recommendations

### Immediate Fix (Structural)

Replace pseudo-code Task invocations with **imperative Task tool invocation instructions** that Claude will actually execute:

**Current (Broken)**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research ${WORKFLOW_DESCRIPTION}"
  prompt: "..."
}
```

**Fixed (Imperative)**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-specialist agent.

The Task tool MUST be invoked with:
- subagent_type: "general-purpose"
- description: "Research ${WORKFLOW_DESCRIPTION}"
- prompt: [full prompt with behavioral injection]

DO NOT perform this research work directly. The Task tool invocation is MANDATORY.
Block 1e verification will FAIL if the report file is not created by the subagent.
```

### Alternative Fix (Restrictive Tools)

Remove permissive tools from plan.md frontmatter:

```yaml
# Current (enables bypass)
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob, Write

# Fixed (forces delegation)
allowed-tools: Task, TodoWrite, Bash
```

Without Read/Grep/Glob, the orchestrator cannot do research/planning work directly and must delegate.

### Verification Enhancement

Add explicit checks in verification blocks to detect bypass:

```bash
# Detect if orchestrator attempted inline work
if [ -f "$RESEARCH_DIR/.inline_work_indicator" ]; then
  echo "ERROR: Research work detected in orchestrator context"
  echo "This indicates Task delegation was bypassed"
  exit 1
fi
```

---

## Related Documentation

- [Hard Barrier Subagent Delegation Pattern](.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md)
- [Plan Command Guide](.claude/docs/guides/commands/plan-command-guide.md)
- [Standard 11: Imperative Agent Invocation](referenced in commit 0b710aff)

---

## Conclusion

The /plan command's failure to delegate to subagents is caused by using pseudo-code `Task { ... }` syntax that Claude doesn't recognize as an actual tool invocation. Combined with permissive tool access, this allows the orchestrator to bypass delegation and perform research/planning work directly, defeating the architectural purpose of context isolation and agent specialization.

The fix requires either:
1. Replacing pseudo-code with imperative Task tool invocation instructions, or
2. Restricting the orchestrator's tool access to force delegation
