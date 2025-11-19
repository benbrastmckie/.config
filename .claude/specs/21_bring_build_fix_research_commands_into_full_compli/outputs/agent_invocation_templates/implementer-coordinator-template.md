# Implementer-Coordinator Agent Invocation Template

## Purpose

This template provides the standard pattern for invoking the implementer-coordinator agent using the Task tool with behavioral injection. Use this template for wave-based parallel implementation execution.

## Template

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    You are executing the implementation phase for: [workflow name]

    Input:
    - plan_path: [absolute path to plan file]
    - topic_path: [topic directory path]
    - artifact_paths:
      - reports: [reports directory path]
      - plans: [plans directory path]
      - summaries: [summaries directory path]
      - debug: [debug directory path]
      - outputs: [outputs directory path]
      - checkpoints: [checkpoints directory path]

    Workflow-Specific Context:
    - Starting Phase: [phase number or 1]
    - Workflow Type: [full-implementation | build]
    - Execution Mode: wave-based (parallel where possible)

    Execute all implementation phases according to the plan, following wave-based
    execution with dependency analysis.

    Return completion signal in format:
    IMPLEMENTATION_COMPLETE: {PHASE_COUNT}
}
```

## Usage Example (from /build command)

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    You are executing the implementation phase for: build workflow

    Input:
    - plan_path: $PLAN_PATH
    - topic_path: $TOPIC_PATH
    - artifact_paths:
      - reports: ${TOPIC_PATH}/reports/
      - plans: ${TOPIC_PATH}/plans/
      - summaries: ${TOPIC_PATH}/summaries/
      - debug: ${TOPIC_PATH}/debug/
      - outputs: ${TOPIC_PATH}/outputs/
      - checkpoints: ${HOME}/.claude/data/checkpoints/

    Workflow-Specific Context:
    - Starting Phase: ${STARTING_PHASE:-1}
    - Workflow Type: full-implementation
    - Execution Mode: wave-based (parallel where possible)

    Execute all implementation phases according to the plan, following wave-based
    execution with dependency analysis.

    Return completion signal in format:
    IMPLEMENTATION_COMPLETE: {PHASE_COUNT}
}
```

## Verification Pattern

After agent invocation, add mandatory verification:

```bash
# MANDATORY VERIFICATION
echo "Verifying implementation completion..."

# Check for completion signal
if ! echo "$IMPLEMENTATION_OUTPUT" | grep -q "IMPLEMENTATION_COMPLETE:"; then
  echo "ERROR: Implementation did not complete successfully" >&2
  echo "DIAGNOSTIC: No completion signal found in output" >&2
  exit 1
fi

# Extract phase count
PHASES_COMPLETED=$(echo "$IMPLEMENTATION_OUTPUT" | grep "IMPLEMENTATION_COMPLETE:" | sed 's/.*IMPLEMENTATION_COMPLETE: //')

echo "✓ Implementation complete ($PHASES_COMPLETED phases executed)"
```

## Key Principles

1. **Behavioral Injection**: Reference agent file, don't duplicate orchestration logic
2. **Context Only**: Inject paths and workflow configuration
3. **Wave-Based Execution**: Agent analyzes dependencies and executes in parallel waves
4. **Completion Signal**: Agent returns `IMPLEMENTATION_COMPLETE: {count}` signal
5. **Artifact Paths**: Provide all directory paths for outputs, debug, checkpoints

## Commands Using This Template

- `/build` (1 instance - full implementation workflow)

Total: 1 instance across 1 command
