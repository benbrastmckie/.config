# Debug-Analyst Agent Invocation Template

## Purpose

This template provides the standard pattern for invoking the debug-analyst agent using the Task tool with behavioral injection. Use this template for debugging and root cause analysis phases.

## Template

```markdown
Task {
  subagent_type: "debug-analyst"
  description: "Debug and analyze [issue/failure]"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    You are conducting debugging analysis for: [workflow name]

    Input:
    - Issue Description: [description of failure or issue]
    - Failed Phase: [phase identifier or number]
    - Test Output: [path to test output or error log]
    - Debug Directory: [debug directory path]
    - Workflow Type: [workflow type]

    Execute debugging analysis according to behavioral guidelines and return completion signal:
    DEBUG_COMPLETE: ${DEBUG_REPORT_PATH}
}
```

## Usage Example (from /build command - debugging phase)

```markdown
Task {
  subagent_type: "debug-analyst"
  description: "Debug failed implementation phase"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    You are conducting debugging analysis for: build workflow

    Input:
    - Issue Description: Phase ${FAILED_PHASE} tests failed with ${FAILURE_COUNT} errors
    - Failed Phase: $FAILED_PHASE
    - Test Output: ${TOPIC_PATH}/outputs/test_phase_${FAILED_PHASE}.txt
    - Debug Directory: ${TOPIC_PATH}/debug/
    - Workflow Type: build-debug

    Execute debugging analysis according to behavioral guidelines and return completion signal:
    DEBUG_COMPLETE: ${DEBUG_REPORT_PATH}
}
```

## Usage Example (from /fix command - root cause analysis)

```markdown
Task {
  subagent_type: "debug-analyst"
  description: "Analyze root cause of $ISSUE_DESCRIPTION"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    You are conducting root cause analysis for: fix workflow

    Input:
    - Issue Description: $ISSUE_DESCRIPTION
    - Research Reports: $RESEARCH_REPORTS_JSON
    - Debug Directory: ${TOPIC_PATH}/debug/
    - Workflow Type: fix-debug

    Execute root cause analysis according to behavioral guidelines and return completion signal:
    DEBUG_COMPLETE: ${DEBUG_REPORT_PATH}
}
```

## Verification Pattern

After agent invocation, add mandatory verification:

```bash
# MANDATORY VERIFICATION
echo "Verifying debug artifacts..."

if [ ! -d "$DEBUG_DIR" ]; then
  echo "ERROR: Debug phase failed to create debug directory" >&2
  echo "DIAGNOSTIC: Expected directory: $DEBUG_DIR" >&2
  exit 1
fi

if [ -z "$(find "$DEBUG_DIR" -name '*.md' 2>/dev/null)" ]; then
  echo "ERROR: Debug phase failed to create debug report" >&2
  echo "DIAGNOSTIC: Directory exists but no .md files found: $DEBUG_DIR" >&2
  exit 1
fi

DEBUG_REPORT=$(find "$DEBUG_DIR" -name '*.md' -type f | head -1)
echo "✓ Debug analysis complete (report: $DEBUG_REPORT)"
```

## Key Principles

1. **Behavioral Injection**: Reference agent file, don't duplicate analysis procedures
2. **Context Only**: Inject failure details, test outputs, issue descriptions
3. **Completion Signal**: Agent returns `DEBUG_COMPLETE: ${path}` signal
4. **Mandatory Verification**: Always verify debug report creation
5. **Workflow Type**: Specify context (build-debug vs fix-debug)

## Commands Using This Template

- `/build` (1 instance - debugging failed implementation phases)
- `/fix` (1 instance - root cause analysis)

Total: 2 instances across 2 commands
