# Research Report: /create-plan Task Delegation Failure

## Summary

The `/create-plan` command is not delegating substantive work to subagents as designed. Instead of invoking the Task tool to spawn research-specialist and plan-architect agents, the orchestrating Claude instance performs all work directly. This defeats the primary design goal of preserving context window by offloading work to subagents.

## Root Cause

### The `Task { ... }` Pseudo-Syntax Problem

The command file uses a pseudo-code syntax that looks like:

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION}"
  prompt: "..."
}
```

**Why This Fails**:

1. **Not Actual Tool Syntax**: The `Task { ... }` block is NOT Claude Code's XML tool invocation syntax. It's pseudo-code that resembles YAML or structured notation.

2. **Interpreted as Documentation**: Claude reads this as instructional text describing what SHOULD happen, similar to how it would read a README example.

3. **Helpful Override**: When Claude sees the directive and understands what needs to be done, it naturally helps by doing the work directly rather than spawning a subagent.

4. **No Enforcement Mechanism**: There's nothing that FORCES Claude to call the Task tool. The "Hard Barrier" verification blocks only check for artifacts AFTER the point where delegation should have occurred.

### Evidence from Output

Examining `/home/benjamin/.config/.claude/output/create-plan-output.md`:

1. **Line 42**: "Now let me invoke the research-specialist agent to conduct the research:"
2. **Lines 44-52**: But instead of Task tool invocation, Claude directly uses Read tool to examine files
3. **Lines 54-59**: Claude performs analysis directly ("Now I understand the issue...")
4. **Lines 62-98**: Claude directly creates directories and writes reports/plans using Bash and Write tools

The Task tool was never actually invoked despite the command file's instructions.

## Technical Analysis

### Command File Structure (create-plan.md)

The command file has three `Task { ... }` blocks at:
- Line 402: topic-naming-agent
- Line 853: research-specialist agent
- Line 1203: plan-architect agent

All three use the same non-functional pseudo-syntax pattern.

### Documented Standard (command-authoring.md)

The command-authoring.md documentation at lines 94-166 explicitly addresses this problem:

> "Commands using this pattern will NOT invoke agents... This pseudo-syntax is not recognized by Claude Code... No execution directive tells the LLM to use the Task tool... Variables inside will not be interpolated..."

Despite this documentation, the create-plan.md command file still uses the prohibited pattern.

### Why Other Commands May Work

Looking at other commands that use the same `Task { ... }` pattern (repair.md, debug.md, research.md), they appear to use identical syntax. If some work correctly, it may be due to:

1. **Model variance**: Different Claude instances may interpret directives differently
2. **Context priming**: Previous successful delegations may influence behavior
3. **Stochastic behavior**: Non-deterministic model output
4. **Prompt sensitivity**: Subtle wording differences affecting interpretation

## Model Upgrade Consideration

The user asked about upgrading the model used by /create-plan.

### Current State
- The command uses `subagent_type: "general-purpose"` which inherits the default model
- No explicit model specification in Task invocations

### Analysis
- **Won't fix the root cause**: Even a more capable model (Sonnet/Opus vs Haiku) won't fix the delegation failure because the fundamental issue is that Task tool is never invoked
- **May improve quality**: Once delegation works, specifying `model: "sonnet"` for complex research/planning subagents could improve output quality
- **Latency tradeoff**: More capable models are slower; Haiku is faster for simpler tasks like topic-naming

### Recommendation
Fix the delegation issue first. Then consider:
- Use `model: "haiku"` for topic-naming-agent (simple task, speed matters)
- Use `model: "sonnet"` for research-specialist and plan-architect (complex analysis benefits from capability)

## Affected Files

| File | Line Numbers | Issue |
|------|--------------|-------|
| `.claude/commands/create-plan.md` | 402, 853, 1203 | Task pseudo-syntax not triggering actual invocation |
| `.claude/docs/reference/standards/command-authoring.md` | 94-166 | Documents correct pattern but commands don't follow it |

## Conclusion

The `/create-plan` command fails to delegate work to subagents because the `Task { ... }` pseudo-syntax is not recognized as an actual tool invocation directive. The command needs architectural changes to enforce actual Task tool usage, not just instructional text that describes what should happen.
