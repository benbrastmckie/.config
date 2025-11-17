# Research-Sub-Supervisor Agent Invocation Template

## Purpose

This template provides the standard pattern for invoking the research-sub-supervisor agent using the Task tool with behavioral injection. Use this template for high-complexity research (complexity ≥4) requiring hierarchical coordination of multiple research-specialist sub-agents.

## Template

```markdown
Task {
  subagent_type: "research-sub-supervisor"
  description: "Coordinate multi-agent research for [topic]"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-sub-supervisor.md

    You are coordinating hierarchical research for: [workflow name]

    Input:
    - Research Topic: [topic description]
    - Research Complexity: [4 only - supervisor used for complexity ≥4]
    - Output Directory: [reports directory path]
    - Workflow Type: [workflow type]
    - Sub-Agent Count: [number of parallel research specialists to coordinate]

    Execute hierarchical research coordination according to behavioral guidelines
    and return completion signal:
    SUPERVISOR_COMPLETE: ${REPORT_COUNT}
}
```

## Usage Example (from /research-plan command - complexity ≥4)

```markdown
Task {
  subagent_type: "research-sub-supervisor"
  description: "Coordinate multi-agent research for $FEATURE_DESCRIPTION"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-sub-supervisor.md

    You are coordinating hierarchical research for: research-plan workflow

    Input:
    - Research Topic: $FEATURE_DESCRIPTION
    - Research Complexity: $RESEARCH_COMPLEXITY
    - Output Directory: $RESEARCH_DIR
    - Workflow Type: research-and-plan
    - Sub-Agent Count: 3-4 (based on complexity decomposition)

    Execute hierarchical research coordination according to behavioral guidelines
    and return completion signal:
    SUPERVISOR_COMPLETE: ${REPORT_COUNT}
}
```

## Conditional Invocation Pattern

The research-sub-supervisor is ONLY invoked when research complexity ≥4:

```bash
if [ "$RESEARCH_COMPLEXITY" -ge 4 ]; then
  echo "NOTE: Hierarchical supervision mode (complexity ≥4)"
  echo "Invoking research-sub-supervisor agent to coordinate multiple sub-agents"

  # Task tool invocation for supervisor
  # (see template above)
else
  # Direct research-specialist invocation for complexity 1-3
  # (see research-specialist-template.md)
fi
```

## Verification Pattern

After agent invocation, add mandatory verification:

```bash
# MANDATORY VERIFICATION
echo "Verifying supervised research artifacts..."

if [ ! -d "$RESEARCH_DIR" ]; then
  echo "ERROR: Supervised research failed to create reports directory" >&2
  echo "DIAGNOSTIC: Expected directory: $RESEARCH_DIR" >&2
  exit 1
fi

if [ -z "$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null)" ]; then
  echo "ERROR: Supervised research failed to create report files" >&2
  echo "DIAGNOSTIC: Directory exists but no .md files found: $RESEARCH_DIR" >&2
  exit 1
fi

REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null | wc -l)

# Complexity ≥4 should produce multiple reports (one per sub-agent + synthesis)
if [ "$REPORT_COUNT" -lt 2 ]; then
  echo "WARNING: Expected multiple reports from supervisor coordination (got $REPORT_COUNT)" >&2
fi

echo "✓ Supervised research complete ($REPORT_COUNT reports created)"
```

## Key Principles

1. **Conditional Invocation**: Only use for complexity ≥4 (hierarchical coordination needed)
2. **Behavioral Injection**: Reference agent file, don't duplicate coordination logic
3. **Sub-Agent Coordination**: Supervisor invokes multiple research-specialist instances
4. **Context Only**: Inject topic, complexity, output paths
5. **Completion Signal**: Agent returns `SUPERVISOR_COMPLETE: ${count}` signal
6. **Multiple Reports**: Expect >1 report (sub-agent reports + synthesis report)

## Commands Using This Template

- `/research-plan` (1 conditional instance - only if complexity ≥4)

Total: 1 conditional instance across 1 command

## Related Templates

- For complexity 1-3, use `research-specialist-template.md` (direct invocation)
- For sub-agent invocations within supervisor, see `research-specialist-template.md`
