# Research Report: Orchestrator Mode vs Direct Invocation Patterns

## Metadata
- **Date**: 2025-12-09
- **Research Topic**: Pattern A (Orchestrator Mode) vs Pattern B (Direct Specialist Invocation) tradeoffs
- **Research Complexity**: 2
- **Standards File**: /home/benjamin/.config/CLAUDE.md

## Executive Summary

This research investigates whether Pattern A (Orchestrator Mode - loading coordinator logic as a library) is architecturally feasible and compares it against Pattern B (Direct Specialist Invocation - skipping coordinator layer entirely). Based on industry patterns from Anthropic, Google ADK, Microsoft Azure, and other multi-agent frameworks, **both patterns are valid and widely used**, with distinct tradeoffs.

**Key Finding**: The architectural choice between Pattern A and Pattern B depends on whether the coordinator layer provides value beyond task routing. If coordinators add meaningful orchestration logic (parallelization, result aggregation, error recovery), Pattern A preserves this value. If coordinators are purely routing layers, Pattern B simplifies architecture without loss.

## Findings

### Pattern A: Orchestrator Mode (Coordinator as Library)

**Description**: Load coordinator logic inline as a sourced library rather than spawning it as a subprocess. The primary agent executes coordinator logic directly, then invokes specialists via Task tool.

```bash
# Pattern A implementation
source "${PROJECT_DIR}/.claude/lib/coordination/research-orchestrator.sh"
SPECIALIST_TASKS=$(orchestrate_research_tasks "$TOPICS" "$REPORT_PATHS")
for task in $SPECIALIST_TASKS; do
  Task { ... specialist invocation ... }
done
```

**Industry Support**: This pattern aligns with multiple established approaches:

1. **Google ADK's AgentTool Pattern**: Google's Agent Development Kit supports wrapping agents as callable tools. When nested invocation is limited, the parent agent can "inline" coordination logic while explicitly invoking child agents as tools.

2. **Anthropic's Synchronous Lead Agent**: Anthropic's multi-agent research system uses a "lead agent coordinating pattern" where the lead agent "analyzes queries, develops strategy, and spawns subagents." The lead maintains control rather than delegating to an intermediate coordinator subprocess.

3. **Microsoft's Magentic Manager**: Azure's architecture patterns describe a "magentic manager agent" that coordinates specialized agents directly without deep nesting.

**Advantages**:
- **Preserves Coordinator Logic**: All parallelization, error handling, and aggregation logic remains functional
- **Eliminates Nesting Depth**: Reduces from 2 levels (primary → coordinator → specialist) to 1 level (primary w/coordinator logic → specialist)
- **Deterministic Execution**: Coordinator logic runs as code, not LLM interpretation
- **Token Efficiency**: No LLM tokens spent on coordinator reasoning - only specialist work

**Disadvantages**:
- **Code Duplication Risk**: Coordinator logic must be extracted to reusable library
- **Increased Primary Complexity**: Primary agent script becomes larger
- **Testing Overhead**: Library extraction requires additional test coverage
- **Maintenance Burden**: Two representations (library for inline, agent for standalone) must stay synchronized

### Pattern B: Direct Specialist Invocation (Skip Coordinator)

**Description**: Command calculates topics/paths directly and invokes specialists without any coordinator layer.

```bash
# Pattern B implementation
for i in "${!TOPICS[@]}"; do
  Task {
    prompt: "Read research-specialist.md and research: ${TOPICS[$i]}"
  }
done
```

**Industry Support**: This pattern also has strong precedent:

1. **Simple Parallel Execution**: Many frameworks support direct parallel invocation without coordination layers. As IBM's orchestration guide notes, "code-based orchestration makes tasks more deterministic and predictable."

2. **Flat Hierarchies**: Microsoft Azure Architecture Center recommends "limiting group chat orchestration to three or fewer agents" and notes that "managing conversation flow and preventing infinite loops require careful attention." Flat architectures avoid this complexity.

3. **CrewAI Task Delegation**: CrewAI supports direct task assignment to specialized agents without requiring intermediate coordinators.

**Advantages**:
- **Architectural Simplicity**: Fewer moving parts, easier to understand
- **Reduced Latency**: No coordinator processing step
- **Direct Control**: Command has full visibility into specialist invocations
- **Easier Debugging**: Fewer layers to trace through

**Disadvantages**:
- **Lost Orchestration Logic**: Parallelization decisions, result aggregation, and cross-specialist coordination must be reimplemented in each command
- **Code Duplication**: Each command needing multi-specialist coordination repeats the orchestration pattern
- **Limited Reuse**: Coordinator improvements don't propagate to all commands automatically
- **Scaling Concerns**: Complex multi-topic research requires inline complexity growth

### Critical Factor: Nested Invocation Support

The choice between patterns depends on whether nested Task invocation (coordinator invoking specialist) is supported in the execution environment.

**Industry Findings on Nesting**:

1. **Google ADK**: Supports hierarchical delegation through multiple levels. Documentation shows "three-tier example where a ReportWriter agent calls ResearchAssistant tool, which itself invokes WebSearch and Summarizer tools."

2. **Microsoft Agent Framework**: "Workflows can be nested or combined to create more complex processes." However, they caution: "avoiding an infinite handoff loop or avoiding excessive bouncing between agents is challenging."

3. **Anthropic Research System**: Uses "limited nesting rather than arbitrary recursion." Lead agent spawns 3-5 subagents in parallel, but subagents "cannot directly coordinate with each other or steer peer agents."

**Key Insight**: Most frameworks support **shallow nesting (2-3 levels)** but discourage deep recursion. The constraint in the lean-plan scenario (coordinator → specialist = depth 2) is within typical supported limits.

### Decision Matrix

| Factor | Pattern A (Orchestrator) | Pattern B (Direct) |
|--------|--------------------------|-------------------|
| **Nesting depth required** | 1 level (inline coordinator) | 1 level (direct) |
| **Coordinator logic preserved** | Yes (as library) | No (reimplemented) |
| **Implementation effort** | Medium (extract library) | Low (remove layer) |
| **Long-term maintainability** | Higher (reusable) | Lower (code duplication) |
| **Debugging complexity** | Medium | Low |
| **Token overhead** | Lowest (no coordinator LLM) | Low |

### Recommendation Based on Research

**If coordinator provides meaningful value** (parallel orchestration, result aggregation, error recovery, topic decomposition):
- **Choose Pattern A** (Orchestrator Mode)
- Extract coordinator logic to library
- Preserve all orchestration capabilities
- Eliminates nesting while keeping value

**If coordinator is purely routing** (just passes topics to specialists):
- **Choose Pattern B** (Direct Specialist Invocation)
- Remove unnecessary indirection
- Commands invoke specialists directly
- Simpler architecture, less maintenance

**For the lean-plan case specifically**:
The research-coordinator provides meaningful value:
- Multi-topic decomposition
- Parallel specialist invocation
- Result aggregation with metadata extraction
- Hard barrier enforcement for report validation

**Therefore: Pattern A is recommended** for lean-plan to preserve this orchestration logic while eliminating the nested Task constraint.

## Sources

- [Multi-agent systems - Agent Development Kit (Google)](https://google.github.io/adk-docs/agents/multi-agents/)
- [How we built our multi-agent research system (Anthropic)](https://www.anthropic.com/engineering/multi-agent-research-system)
- [AI Agent Orchestration Patterns - Azure Architecture Center (Microsoft)](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns)
- [What is LLM Orchestration? (IBM)](https://www.ibm.com/think/topics/llm-orchestration)
- [Orchestrating multiple agents - OpenAI Agents SDK](https://openai.github.io/openai-agents-python/multi_agent/)
- [Agent Orchestration Patterns (Dynamiq)](https://www.getdynamiq.ai/post/agent-orchestration-patterns-in-multi-agent-systems-linear-and-adaptive-approaches-with-dynamiq)
- [LLM Orchestration in 2025: Frameworks + Best Practices](https://orq.ai/blog/llm-orchestration)
- [Choosing the right orchestration pattern for multi agent systems (Kore.ai)](https://www.kore.ai/blog/choosing-the-right-orchestration-pattern-for-multi-agent-systems)
- [Architectures for Multi-Agent Systems (Galileo)](https://galileo.ai/blog/architectures-for-multi-agent-systems)
- [Patterns for Building Production Grade Agentic AI (Medium)](https://dr-arsanjani.medium.com/patterns-for-agentic-ai-in-multi-agent-systems-patterns-1-4-f4c952bfc123)

## Implementation Notes

### Pattern A Implementation Path

1. Create library: `.claude/lib/coordination/research-orchestrator.sh`
2. Extract from research-coordinator.md:
   - Topic decomposition logic
   - Parallel invocation generation
   - Result aggregation functions
3. Update lean-plan to source library and execute specialists directly
4. Keep research-coordinator.md as documentation (or for standalone use if nesting works elsewhere)

### Pattern B Implementation Path

1. Inline topic decomposition in lean-plan command
2. Generate specialist Task invocations directly
3. Remove research-coordinator invocation
4. Implement result aggregation inline
5. Deprecate research-coordinator agent

### Hybrid Approach (Alternative)

Test Task nesting first (Phase 1-2 of the plan). If nesting works, keep current architecture. If not, implement Pattern A as the minimal change that preserves coordinator value.
