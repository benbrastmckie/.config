# Command Patterns Quick Reference

Quick reference guide for common command development patterns in `.claude/commands/`.

## Purpose

This document provides copy-paste templates for implementing standard patterns across command files. For detailed rationale and context, see [Command Authoring Standards](standards/command-authoring.md).

## Target Audience

- Command developers implementing new slash commands
- Developers refactoring existing commands for uniformity
- Anyone needing quick pattern examples

## Navigation

- **Parent**: [Reference Documentation](README.md)
- **Related**: [Command Authoring Standards](standards/command-authoring.md)
- **Related**: [Output Formatting Standards](standards/output-formatting.md)

---

## Table of Contents

1. [Argument Capture Pattern](#argument-capture-pattern)
2. [State Initialization Pattern](#state-initialization-pattern)
3. [Agent Delegation Pattern](#agent-delegation-pattern)
4. [Checkpoint Reporting Pattern](#checkpoint-reporting-pattern)
5. [Validation Patterns](#validation-patterns)
6. [Complete Command Template](#complete-command-template)

---

## Argument Capture Pattern

### 2-Block Argument Capture (Standard)

**Block 1: Mechanical Capture**

```markdown
## Block 1: Capture User Argument

**EXECUTE NOW**: Capture the user-provided argument.

Replace `YOUR_DESCRIPTION_HERE` with the actual argument value:

```bash
set +H
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/COMMANDNAME_arg_$(date +%s%N).txt"
echo "YOUR_DESCRIPTION_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/COMMANDNAME_arg_path.txt"
echo "Argument captured to $TEMP_FILE"
```
\```

**Block 2: Validation and Parsing**

```markdown
## Block 2: Validate and Parse Argument

**EXECUTE NOW**: Read the captured argument and validate:

```bash
set +H
# Read argument from temp file
PATH_FILE="${HOME}/.claude/tmp/COMMANDNAME_arg_path.txt"
if [ -f "$PATH_FILE" ]; then
  TEMP_FILE=$(cat "$PATH_FILE")
else
  TEMP_FILE="${HOME}/.claude/tmp/COMMANDNAME_arg.txt"  # Legacy fallback
fi

if [ -f "$TEMP_FILE" ]; then
  DESCRIPTION=$(cat "$TEMP_FILE")
else
  echo "ERROR: Argument file not found" >&2
  echo "Usage: /COMMANDNAME \"<description>\"" >&2
  exit 1
fi

if [ -z "$DESCRIPTION" ]; then
  echo "ERROR: Argument is empty" >&2
  exit 1
fi

# Parse flags if applicable
DRY_RUN=false
COMPLEXITY=2
if echo "$DESCRIPTION" | grep -q '\--dry-run'; then
  DRY_RUN=true
  DESCRIPTION=$(echo "$DESCRIPTION" | sed 's/--dry-run//g')
fi
if echo "$DESCRIPTION" | grep -Eq '\--complexity [0-9]'; then
  COMPLEXITY=$(echo "$DESCRIPTION" | grep -oE '\--complexity [0-9]' | awk '{print $2}')
  DESCRIPTION=$(echo "$DESCRIPTION" | sed 's/--complexity [0-9]//g')
fi

# Clean whitespace
DESCRIPTION=$(echo "$DESCRIPTION" | xargs)

echo "Description: $DESCRIPTION"
[ "$DRY_RUN" = true ] && echo "Dry run: enabled"
echo "Complexity: $COMPLEXITY"
```
\```

**Substitutions**:
- Replace `COMMANDNAME` with your command name (e.g., `research`, `plan`)
- Replace `YOUR_DESCRIPTION_HERE` with actual substitution marker
- Adjust flag parsing to match your command's flags

**Reference**: [Command Authoring Standards - Argument Capture](standards/command-authoring.md#argument-capture-patterns)

---

## State Initialization Pattern

### Workflow State Machine Initialization

```markdown
## Setup: Initialize Workflow State

**EXECUTE NOW**: Initialize state machine and allocate workflow ID:

```bash
set +H
# Source required libraries with fail-fast
source "${CLAUDE_PROJECT_DIR}/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Initialize error log
ensure_error_log_exists

# Initialize state machine
COMMAND_NAME="/COMMANDNAME"
WORKFLOW_TYPE="WORKFLOW_TYPE"  # e.g., research-only, research-and-plan, full-implementation

sm_init "$DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE"
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: State machine initialization failed" >&2
  exit 1
fi

# Allocate workflow ID
WORKFLOW_ID=$(allocate_workflow_id)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: Failed to allocate workflow ID" >&2
  exit 1
fi

# Persist workflow state
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID" || exit 1
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME" || exit 1
append_workflow_state "DESCRIPTION" "$DESCRIPTION" || exit 1

# Save workflow ID to fixed location
echo "$WORKFLOW_ID" > "${HOME}/.claude/tmp/workflow_state_id.txt"

echo "Workflow initialized: $WORKFLOW_ID"
```
\```

**Substitutions**:
- Replace `COMMANDNAME` with your command name
- Replace `WORKFLOW_TYPE` with appropriate type (research-only, research-and-plan, full-implementation, debug-only)

**Reference**: [Command Authoring Standards - State Persistence](standards/command-authoring.md#state-persistence-patterns)

---

## Agent Delegation Pattern

### Hard Barrier Pattern (Pre-Calculate Paths)

```markdown
## Phase N: Delegate to AGENT_NAME

**EXECUTE NOW**: Delegate to AGENT_NAME agent with pre-calculated paths.

```bash
set +H
# Load workflow state
source "${CLAUDE_PROJECT_DIR}/lib/core/state-persistence.sh" 2>/dev/null || exit 1
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/workflow_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# Pre-calculate output paths (hard barrier pattern)
TOPIC_DIR="${CLAUDE_PROJECT_DIR}/specs/${TOPIC_NUMBER}_${TOPIC_NAME}"
REPORT_DIR="${TOPIC_DIR}/reports"
REPORT_PATH="${REPORT_DIR}/001_REPORT_NAME.md"

# Persist paths for validation
append_workflow_state "REPORT_PATH" "$REPORT_PATH" || exit 1

echo "[CHECKPOINT] Pre-calculation complete"
echo "Context: WORKFLOW_ID=${WORKFLOW_ID}, REPORT_PATH=${REPORT_PATH}"
echo "Ready for: Agent delegation"
```
\```

**EXECUTE NOW**: USE the Task tool to invoke the AGENT_NAME agent.

Task {
  subagent_type: "general-purpose"
  description: "ACTION_DESCRIPTION with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/agents/AGENT_FILE.md

    **Workflow-Specific Context**:
    - Context Variable 1: ${VAR1}
    - Context Variable 2: ${VAR2}
    - Output Path: ${REPORT_PATH}

    Execute ACTION per behavioral guidelines.
    Return: SIGNAL_NAME: ${REPORT_PATH}
  "
}

**Substitutions**:
- Replace `AGENT_NAME` with agent display name (e.g., Research Specialist)
- Replace `AGENT_FILE` with agent file name (e.g., research-specialist)
- Replace `ACTION_DESCRIPTION` with brief description
- Replace `REPORT_NAME` with output filename
- Replace `VAR1`, `VAR2` with actual context variables
- Replace `ACTION` with action verb (e.g., research, plan, implement)
- Replace `SIGNAL_NAME` with completion signal (e.g., REPORT_CREATED, PLAN_CREATED)

**Reference**: [Hard Barrier Subagent Delegation Pattern](../concepts/patterns/hard-barrier-subagent-delegation.md)

### Agent Delegation - Task Invocation Templates

#### Standard Task Invocation

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the [AGENT_NAME] agent.

Task {
  subagent_type: "general-purpose"
  description: "[Brief description] with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/[agent-file].md

    **Workflow-Specific Context**:
    - [Context Variable 1]: ${VAR1}
    - [Context Variable 2]: ${VAR2}
    - Output Path: ${OUTPUT_PATH}

    Execute [action] per behavioral guidelines.
    Return: [SIGNAL_NAME]: ${OUTPUT_PATH}
  "
}
```

#### Iteration Loop Invocation

For commands that re-invoke agents in iteration loops (e.g., `/implement`):

```markdown
## Block 5: Initial Invocation

**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Implement phase ${STARTING_PHASE}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Input Contract**:
    - plan_path: ${PLAN_PATH}
    - topic_path: ${TOPIC_PATH}
    - iteration: ${ITERATION}

    Execute implementation per behavioral guidelines.
    Return: IMPLEMENTATION_COMPLETE: ${SUMMARY_PATH}
  "
}

## Block 7: Iteration Loop Re-Invocation

```bash
if [ "$WORK_REMAINING" != "0" ]; then
  ITERATION=$((ITERATION + 1))
  echo "Iteration $ITERATION required"
fi
```

**EXECUTE NOW**: USE the Task tool to re-invoke implementer-coordinator for iteration ${ITERATION}.

Task {
  subagent_type: "general-purpose"
  description: "Continue implementation (iteration ${ITERATION})"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Input Contract**:
    - plan_path: ${PLAN_PATH}
    - topic_path: ${TOPIC_PATH}
    - iteration: ${ITERATION}
    - continuation_context: ${CONTINUATION_SUMMARY}

    Execute implementation per behavioral guidelines.
    Return: IMPLEMENTATION_COMPLETE: ${SUMMARY_PATH}
  "
}
```

**Key Points**:
- Both invocation points (initial and loop) require separate imperative directives
- Iteration number and continuation context passed to agent

#### Conditional Invocation

For commands that conditionally invoke agents based on runtime state:

```markdown
```bash
COVERAGE=$(get_coverage_percentage)
THRESHOLD=80

if [ "$COVERAGE" -lt "$THRESHOLD" ]; then
  echo "Coverage ${COVERAGE}% below threshold ${THRESHOLD}% - re-running tests"
fi
```

**EXECUTE IF** coverage below threshold: USE the Task tool to invoke test-executor.

Task {
  subagent_type: "general-purpose"
  description: "Run test suite (iteration ${TEST_ITERATION})"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-executor.md

    **Workflow-Specific Context**:
    - Plan Path: ${PLAN_PATH}
    - Coverage Target: ${THRESHOLD}%
    - Current Coverage: ${COVERAGE}%
    - Test Iteration: ${TEST_ITERATION}

    Execute test suite per behavioral guidelines.
    Return: TESTS_COMPLETE: ${TEST_SUMMARY_PATH}
  "
}
```

**Alternative Pattern** (explicit conditional):

```bash
if [ "$COVERAGE" -lt "$THRESHOLD" ]; then
  echo "Coverage insufficient - invoking test-executor"
fi
```

**EXECUTE NOW**: USE the Task tool to invoke test-executor.

Task { ... }
```

#### Multiple Sequential Agents

For commands that invoke multiple agents in sequence:

```markdown
## Block 3a: Research Phase

**EXECUTE NOW**: USE the Task tool to invoke research-specialist.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${TOPIC}
    - Output Path: ${REPORT_PATH}

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}

## Block 3b: Planning Phase

**EXECUTE NOW**: USE the Task tool to invoke plan-architect.

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan from research"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Research Report: ${REPORT_PATH}
    - Plan Output Path: ${PLAN_PATH}

    Execute planning per behavioral guidelines.
    Return: PLAN_CREATED: ${PLAN_PATH}
  "
}
```

**Key Point**: Each agent invocation requires its own imperative directive - don't use single directive for multiple Task blocks

---

## Checkpoint Reporting Pattern

### Standard Checkpoint Format

```bash
echo "[CHECKPOINT] Phase NAME complete"
echo "Context: KEY1=${VALUE1}, KEY2=${VALUE2}, KEY3=${VALUE3}"
echo "Ready for: NEXT_ACTION"
```

**Examples**:

```bash
# After setup
echo "[CHECKPOINT] Setup phase complete"
echo "Context: WORKFLOW_ID=${WORKFLOW_ID}, TOPIC_DIR=${TOPIC_DIR}"
echo "Ready for: Agent delegation"

# After validation
echo "[CHECKPOINT] Validation complete"
echo "Context: PLAN_FILE=${PLAN_FILE}, PHASE_COUNT=${PHASE_COUNT}"
echo "Ready for: Implementation execution"

# After state transition
echo "[CHECKPOINT] Phase 1 complete"
echo "Context: REPORTS_CREATED=${REPORT_COUNT}, NEXT_PHASE=2"
echo "Ready for: Planning phase"
```

**Guidelines**:
- First line: `[CHECKPOINT]` marker + phase name + "complete"
- Second line: "Context:" + comma-separated KEY=VALUE pairs
- Third line: "Ready for:" + human-readable next action
- Include only variables needed by subsequent blocks or for debugging

**Reference**: [Output Formatting Standards - Checkpoint Reporting](standards/output-formatting.md#checkpoint-reporting-format)

---

## Validation Patterns

### Using validation-utils.sh Library

```markdown
## Validation Block

**EXECUTE NOW**: Validate prerequisites and artifacts:

```bash
set +H
# Source validation library
source "${CLAUDE_PROJECT_DIR}/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Failed to source validation-utils.sh" >&2
  exit 1
}

# Validate workflow prerequisites
validate_workflow_prerequisites || exit 1

# Validate agent artifacts
validate_agent_artifact "$REPORT_PATH" 100 "research report" || exit 1
validate_agent_artifact "$PLAN_PATH" 500 "implementation plan" || exit 1

# Validate paths
validate_absolute_path "$TOPIC_DIR" true || exit 1
validate_absolute_path "$OUTPUT_DIR" false || exit 1

echo "Validation complete"
```
\```

**Function Reference**:

| Function | Purpose | Usage |
|----------|---------|-------|
| `validate_workflow_prerequisites()` | Check required workflow functions | `validate_workflow_prerequisites \|\| exit 1` |
| `validate_agent_artifact(path, min_size, type)` | Check agent output exists | `validate_agent_artifact "$PATH" 100 "report" \|\| exit 1` |
| `validate_absolute_path(path, check_exists)` | Validate path format | `validate_absolute_path "$PATH" true \|\| exit 1` |

**Benefits**:
- Reduces validation boilerplate from 15-25 lines to 3-5 lines
- Automatic error logging integration
- Consistent error messages across commands

**Reference**: [Validation Utils Library](../../lib/workflow/validation-utils.sh)

---

## Complete Command Template

### Minimal Command Structure

```markdown
# Command Name

Brief description of what the command does.

## Block 1: Capture and Setup

**EXECUTE NOW**: Capture argument and initialize workflow:

```bash
set +H
# Argument capture
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/COMMAND_arg_$(date +%s%N).txt"
echo "YOUR_DESCRIPTION_HERE" > "$TEMP_FILE"

# Read and validate
DESCRIPTION=$(cat "$TEMP_FILE")
if [ -z "$DESCRIPTION" ]; then
  echo "ERROR: Description required" >&2
  exit 1
fi

# Source libraries with fail-fast
source "${CLAUDE_PROJECT_DIR}/lib/workflow/workflow-state-machine.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/lib/core/state-persistence.sh" 2>/dev/null || exit 1

# Initialize state machine
COMMAND_NAME="/COMMAND"
WORKFLOW_TYPE="TYPE"
sm_init "$DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE" || exit 1

# Allocate workflow ID
WORKFLOW_ID=$(allocate_workflow_id) || exit 1
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID" || exit 1

echo "[CHECKPOINT] Setup complete"
echo "Context: WORKFLOW_ID=${WORKFLOW_ID}"
echo "Ready for: Execution"
```
\```

## Block 2: Execute Workflow

**EXECUTE NOW**: Execute main workflow logic:

```bash
set +H
# Load state
source "${CLAUDE_PROJECT_DIR}/lib/core/state-persistence.sh" 2>/dev/null || exit 1
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/workflow_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# Main workflow logic here
# ...

echo "[CHECKPOINT] Execution complete"
echo "Context: WORKFLOW_ID=${WORKFLOW_ID}, RESULT=${RESULT}"
echo "Ready for: Completion"
```
\```

## Block 3: Complete Workflow

**EXECUTE NOW**: Finalize and output summary:

```bash
set +H
# Load state
source "${CLAUDE_PROJECT_DIR}/lib/core/state-persistence.sh" 2>/dev/null || exit 1
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/workflow_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# Transition to complete state
source "${CLAUDE_PROJECT_DIR}/lib/workflow/workflow-state-machine.sh" 2>/dev/null || exit 1
sm_transition "complete" || exit 1

# Console summary
cat << EOF
=== Command Complete ===

Summary: Brief description of what was accomplished and why it matters.

Artifacts:
  📄 Output: /absolute/path/to/output.md

Next Steps:
  • Review output: cat /absolute/path/to/output.md
  • Next command: /next-command
EOF
```
\```

**Substitutions**:
- Replace `COMMAND` with command name
- Replace `TYPE` with workflow type
- Add actual workflow logic in Block 2
- Customize console summary with actual paths

---

## Related Documentation

### Standards
- [Command Authoring Standards](standards/command-authoring.md) - Complete command development standards
- [Output Formatting Standards](standards/output-formatting.md) - Output suppression and formatting
- [Code Standards](standards/code-standards.md) - General coding conventions

### Concepts
- [Bash Block Execution Model](../concepts/bash-block-execution-model.md) - Subprocess isolation patterns
- [Hard Barrier Pattern](../concepts/patterns/hard-barrier-subagent-delegation.md) - Agent delegation best practices

### Guides
- [Command Development Fundamentals](../guides/development/command-development/command-development-fundamentals.md) - Detailed development guide

---

**Last Updated**: 2025-12-01
**Spec Reference**: 998_commands_uniformity_enforcement
