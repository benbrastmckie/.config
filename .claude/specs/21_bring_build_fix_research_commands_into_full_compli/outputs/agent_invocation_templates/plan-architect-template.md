# Plan-Architect Agent Invocation Template

## Purpose

This template provides the standard pattern for invoking the plan-architect agent using the Task tool with behavioral injection. Use this template for all plan-architect invocations in workflow commands.

## Template

```markdown
Task {
  subagent_type: "plan-architect"
  description: "Create implementation plan for [feature/requirement]"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are creating an implementation plan for: [workflow name]

    Input:
    - Feature Description: [feature description]
    - Output Path: [plan file path]
    - Research Reports: [JSON array of report paths]
    - Workflow Type: [workflow type]
    - Operation Mode: [new plan creation | plan revision]

    Execute planning according to behavioral guidelines and return completion signal:
    PLAN_CREATED: ${PLAN_PATH}
}
```

## Usage Example (from /research-plan command)

```markdown
Task {
  subagent_type: "plan-architect"
  description: "Create implementation plan for $FEATURE_DESCRIPTION"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are creating an implementation plan for: research-plan workflow

    Input:
    - Feature Description: $FEATURE_DESCRIPTION
    - Output Path: $PLAN_PATH
    - Research Reports: $REPORT_PATHS_JSON
    - Workflow Type: research-and-plan
    - Operation Mode: new plan creation

    Execute planning according to behavioral guidelines and return completion signal:
    PLAN_CREATED: ${PLAN_PATH}
}
```

## Verification Pattern

After agent invocation, add mandatory verification:

```bash
# MANDATORY VERIFICATION
echo "Verifying plan artifacts..."

if [ ! -f "$PLAN_PATH" ]; then
  echo "ERROR: Planning phase failed to create plan file" >&2
  echo "DIAGNOSTIC: Expected file: $PLAN_PATH" >&2
  echo "SOLUTION: Check plan-architect agent behavioral file compliance" >&2
  exit 1
fi

FILE_SIZE=$(wc -c < "$PLAN_PATH")
if [ "$FILE_SIZE" -lt 500 ]; then
  echo "ERROR: Plan file too small ($FILE_SIZE bytes)" >&2
  echo "DIAGNOSTIC: Plan file may be incomplete or empty" >&2
  exit 1
fi

echo "✓ Planning phase complete (plan: $PLAN_PATH)"
```

## Key Principles

1. **Behavioral Injection**: Reference agent file, don't duplicate procedures
2. **Context Only**: Inject workflow-specific parameters (feature, reports, paths)
3. **Completion Signal**: Agent returns `PLAN_CREATED: ${path}` signal
4. **Mandatory Verification**: Always verify plan file existence and minimum size
5. **Operation Mode**: Specify whether creating new plan or revising existing

## Commands Using This Template

- `/research-plan` (1 instance - new plan creation)
- `/research-revise` (2 instances - plan revision workflow)
- `/fix` (1 instance - debugging plan creation)

Total: 4 instances across 3 commands
