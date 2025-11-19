# Research-Specialist Agent Invocation Template

## Purpose

This template provides the standard pattern for invoking the research-specialist agent using the Task tool with behavioral injection. Use this template for all research-specialist invocations in workflow commands.

## Template

```markdown
Task {
  subagent_type: "research-specialist"
  description: "Research [topic/feature/requirement]"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are conducting research for: [workflow name]

    Input:
    - Research Topic: [topic description]
    - Research Complexity: [1-4]
    - Output Directory: [report directory path]
    - Workflow Type: [workflow type]

    Execute research according to behavioral guidelines and return completion signal:
    REPORT_CREATED: ${REPORT_PATH}
}
```

## Usage Example (from /research-report command)

```markdown
Task {
  subagent_type: "research-specialist"
  description: "Research $FEATURE_DESCRIPTION"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are conducting research for: research-report workflow

    Input:
    - Research Topic: $FEATURE_DESCRIPTION
    - Research Complexity: $RESEARCH_COMPLEXITY
    - Output Directory: $RESEARCH_DIR
    - Workflow Type: research-report

    Execute research according to behavioral guidelines and return completion signal:
    REPORT_CREATED: ${REPORT_PATH}
}
```

## Verification Pattern

After agent invocation, add mandatory verification:

```bash
# MANDATORY VERIFICATION
echo ""
echo "Verifying research artifacts..."

if [ ! -d "$RESEARCH_DIR" ]; then
  echo "ERROR: Research phase failed to create reports directory" >&2
  echo "DIAGNOSTIC: Expected directory: $RESEARCH_DIR" >&2
  exit 1
fi

if [ -z "$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null)" ]; then
  echo "ERROR: Research phase failed to create report files" >&2
  echo "DIAGNOSTIC: Directory exists but no .md files found: $RESEARCH_DIR" >&2
  exit 1
fi

REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null | wc -l)
echo "✓ Research phase complete ($REPORT_COUNT reports created)"
```

## Key Principles

1. **Behavioral Injection**: Reference agent file, don't duplicate procedures
2. **Context Only**: Inject workflow-specific parameters, not behavioral patterns
3. **Completion Signal**: Agent returns `REPORT_CREATED: ${path}` signal
4. **Mandatory Verification**: Always verify artifacts after invocation
5. **Fail-Fast**: Exit immediately on verification failure

## Commands Using This Template

- `/research-report` (1 instance)
- `/research-plan` (2 instances - complexity ≥4 uses supervisor)
- `/research-revise` (1 instance)
- `/fix` (1 instance - root cause analysis)

Total: 5 instances across 4 commands
