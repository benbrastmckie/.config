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
7. [Research Coordinator Patterns](#research-coordinator-patterns)
   - [Template 6: Topic Decomposition Block](#template-6-topic-decomposition-block-heuristic-based)
   - [Template 7: Topic Detection Agent Invocation](#template-7-topic-detection-agent-invocation-block-automated)
   - [Template 8: Research Coordinator Task Invocation](#template-8-research-coordinator-task-invocation-block)
   - [Template 9: Multi-Report Validation Loop](#template-9-multi-report-validation-loop)
   - [Template 10: Metadata Extraction and Aggregation](#template-10-metadata-extraction-and-aggregation)

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

## Research Coordinator Patterns

### Template 6: Topic Decomposition Block (Heuristic-Based)

```markdown
## Block 1d-topics: Topic Decomposition

**EXECUTE NOW**: Analyze feature description and decompose into research topics:

```bash
set +H
# Source state persistence for saving topics
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Cannot load state-persistence library" >&2
  exit 1
}

# Read state for feature description and complexity
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/workflow_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# Determine topic count based on complexity
case $RESEARCH_COMPLEXITY in
  1|2) TOPIC_COUNT=1 ;;  # Single topic
  3) TOPIC_COUNT=3 ;;    # 2-3 topics
  4) TOPIC_COUNT=4 ;;    # 4-5 topics
  *) TOPIC_COUNT=2 ;;    # Default
esac

# Heuristic decomposition: Check for multi-topic indicators
MULTI_TOPIC_INDICATORS=0
if echo "$FEATURE_DESCRIPTION" | grep -qE '\band\b|\bor\b|,'; then
  ((MULTI_TOPIC_INDICATORS++))
fi
if [ "$RESEARCH_COMPLEXITY" -ge 3 ]; then
  ((MULTI_TOPIC_INDICATORS++))
fi

# If no multi-topic indicators, fall back to single topic
if [ "$MULTI_TOPIC_INDICATORS" -lt 2 ]; then
  TOPIC_COUNT=1
  echo "Single-topic mode: No multi-topic indicators found"
fi

# Simple topic decomposition (split by conjunctions or use full description)
if [ "$TOPIC_COUNT" -eq 1 ]; then
  TOPICS_LIST="$FEATURE_DESCRIPTION"
else
  # Split by " and ", " or ", or commas (heuristic)
  TOPICS_LIST=$(echo "$FEATURE_DESCRIPTION" | sed 's/ and /|/g; s/ or /|/g; s/, /|/g')
fi

# Pre-calculate report paths (hard barrier pattern)
RESEARCH_DIR="${TOPIC_PATH}/reports"
mkdir -p "$RESEARCH_DIR"

# Find existing reports to determine starting number
EXISTING_REPORTS=$(ls "$RESEARCH_DIR"/[0-9][0-9][0-9]-*.md 2>/dev/null | wc -l)
START_NUM=$((EXISTING_REPORTS + 1))

# Calculate paths for each topic
REPORT_PATHS_LIST=""
IFS='|' read -ra TOPICS_ARRAY <<< "$TOPICS_LIST"
for i in "${!TOPICS_ARRAY[@]}"; do
  REPORT_NUM=$(printf "%03d" $((START_NUM + i)))
  TOPIC_SLUG=$(echo "${TOPICS_ARRAY[$i]}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
  REPORT_PATH="${RESEARCH_DIR}/${REPORT_NUM}-${TOPIC_SLUG}.md"

  if [ -z "$REPORT_PATHS_LIST" ]; then
    REPORT_PATHS_LIST="$REPORT_PATH"
  else
    REPORT_PATHS_LIST="${REPORT_PATHS_LIST}|${REPORT_PATH}"
  fi
done

# Persist to state for coordinator and validation
append_workflow_state "TOPICS_LIST" "$TOPICS_LIST"
append_workflow_state "REPORT_PATHS_LIST" "$REPORT_PATHS_LIST"
append_workflow_state "TOPIC_COUNT" "${#TOPICS_ARRAY[@]}"

echo "[CHECKPOINT] Topic decomposition complete"
echo "Context: TOPIC_COUNT=${#TOPICS_ARRAY[@]}, TOPICS_LIST=${TOPICS_LIST}"
echo "Ready for: Research coordinator invocation"
```
\```

**Substitutions**:
- Replace `FEATURE_DESCRIPTION` with actual feature description variable
- Replace `RESEARCH_COMPLEXITY` with complexity level (1-4)
- Replace `TOPIC_PATH` with topic directory path
- Adjust heuristic logic for domain-specific topic patterns

---

### Template 7: Topic Detection Agent Invocation Block (Automated)

```markdown
## Block 1d-topics-auto: Topic Detection Agent Invocation

**EXECUTE NOW**: USE the Task tool to invoke topic-detection-agent for automated decomposition.

Task {
  subagent_type: "specialist"
  description: "Detect and decompose research topics automatically"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-detection-agent.md

    **Input Contract**:
    feature_description: "${FEATURE_DESCRIPTION}"
    research_complexity: ${RESEARCH_COMPLEXITY}
    output_path: ${TOPICS_JSON_PATH}

    Analyze the feature description and identify 2-5 distinct research topics.
    Output topics as JSON array with topic names and scope descriptions.

    Return: TOPICS_DETECTED: ${TOPICS_JSON_PATH}
}
\```

**Follow-up Validation Block**:

```markdown
## Block 1d-topics-parse: Parse Topic Detection Output

**EXECUTE NOW**: Parse topic detection JSON and pre-calculate report paths:

```bash
set +H
# Read state
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/workflow_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# Validate JSON output exists
if [ ! -f "$TOPICS_JSON_PATH" ]; then
  echo "WARNING: Topic detection failed, falling back to heuristic decomposition" >&2
  # Fall back to Template 6 logic
  exit 0
fi

# Parse JSON using jq
TOPICS_LIST=$(jq -r '.topics[] .name' "$TOPICS_JSON_PATH" | paste -sd '|' -)
TOPIC_COUNT=$(jq '.topics | length' "$TOPICS_JSON_PATH")

# Validate topic count
if [ -z "$TOPICS_LIST" ] || [ "$TOPIC_COUNT" -lt 2 ]; then
  echo "WARNING: Topic detection returned <2 topics, falling back to single-topic mode" >&2
  TOPICS_LIST="$FEATURE_DESCRIPTION"
  TOPIC_COUNT=1
fi

# Pre-calculate report paths (same as Template 6)
RESEARCH_DIR="${TOPIC_PATH}/reports"
mkdir -p "$RESEARCH_DIR"
EXISTING_REPORTS=$(ls "$RESEARCH_DIR"/[0-9][0-9][0-9]-*.md 2>/dev/null | wc -l)
START_NUM=$((EXISTING_REPORTS + 1))

REPORT_PATHS_LIST=""
IFS='|' read -ra TOPICS_ARRAY <<< "$TOPICS_LIST"
for i in "${!TOPICS_ARRAY[@]}"; do
  REPORT_NUM=$(printf "%03d" $((START_NUM + i)))
  TOPIC_SLUG=$(echo "${TOPICS_ARRAY[$i]}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
  REPORT_PATH="${RESEARCH_DIR}/${REPORT_NUM}-${TOPIC_SLUG}.md"

  if [ -z "$REPORT_PATHS_LIST" ]; then
    REPORT_PATHS_LIST="$REPORT_PATH"
  else
    REPORT_PATHS_LIST="${REPORT_PATHS_LIST}|${REPORT_PATH}"
  fi
done

# Persist to state
append_workflow_state "TOPICS_LIST" "$TOPICS_LIST"
append_workflow_state "REPORT_PATHS_LIST" "$REPORT_PATHS_LIST"
append_workflow_state "TOPIC_COUNT" "$TOPIC_COUNT"

echo "[CHECKPOINT] Topic detection and parsing complete"
echo "Context: TOPIC_COUNT=${TOPIC_COUNT}, AUTOMATED=true"
echo "Ready for: Research coordinator invocation"
```
\```

**Substitutions**:
- Replace `TOPICS_JSON_PATH` with calculated path to JSON output file
- Replace `FEATURE_DESCRIPTION` with feature description variable
- Replace `RESEARCH_COMPLEXITY` with complexity level
- Replace `TOPIC_PATH` with topic directory path

---

### Template 8: Research Coordinator Task Invocation Block

```markdown
## Block 1e-exec: Research Coordinator Invocation

**CRITICAL BARRIER**: This block MUST invoke research-coordinator via Task tool.
Verification block (1f) will FAIL if reports not created.

**EXECUTE NOW**: USE the Task tool to invoke research-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Coordinate parallel research across multiple topics"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    You are acting as a Research Coordinator Agent with the tools and constraints
    defined in that file.

    **Input Contract (Mode 2: Pre-Decomposed)**:
    research_request: "${FEATURE_DESCRIPTION}"
    research_complexity: ${RESEARCH_COMPLEXITY}
    report_dir: ${RESEARCH_DIR}
    topics: ${TOPICS_LIST}
    report_paths: ${REPORT_PATHS_LIST}

    The topics are pipe-separated (|) strings. Parse and delegate to research-specialist
    for each topic in parallel. Create reports at the pre-calculated paths.

    Return: RESEARCH_COMPLETE: {REPORT_COUNT}
}
\```

**Substitutions**:
- Replace `FEATURE_DESCRIPTION` with feature description
- Replace `RESEARCH_COMPLEXITY` with complexity level
- Replace `RESEARCH_DIR` with reports directory path
- Replace `TOPICS_LIST` with pipe-separated topic list from state
- Replace `REPORT_PATHS_LIST` with pipe-separated report paths from state

**Key Points**:
- Uses Mode 2 contract (Pre-Decomposed) - topics already decomposed
- research-coordinator parses pipe-separated lists
- Coordinator invokes research-specialist in parallel for each topic
- Hard barrier pattern: paths pre-calculated, validation follows

---

### Template 9: Multi-Report Validation Loop

```markdown
## Block 1f: Multi-Report Validation (Hard Barrier)

**EXECUTE NOW**: Validate all research reports were created:

```bash
set +H
# Source validation library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load validation-utils library" >&2
  exit 1
}

# Read state for report paths
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/workflow_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# Parse report paths (pipe-separated)
IFS='|' read -ra REPORT_PATHS_ARRAY <<< "$REPORT_PATHS_LIST"

# Validate each report (hard barrier - fail-fast)
TOTAL_REPORTS=${#REPORT_PATHS_ARRAY[@]}
VALID_REPORTS=0

for REPORT_PATH in "${REPORT_PATHS_ARRAY[@]}"; do
  echo "Validating: $REPORT_PATH"

  # File existence check
  if [ ! -f "$REPORT_PATH" ]; then
    echo "ERROR: Report not found at $REPORT_PATH" >&2
    echo "HARD BARRIER FAILED: research-coordinator did not create all reports" >&2
    exit 1
  fi

  # Minimum size check (100 bytes)
  FILE_SIZE=$(stat -f%z "$REPORT_PATH" 2>/dev/null || stat -c%s "$REPORT_PATH" 2>/dev/null)
  if [ "$FILE_SIZE" -lt 100 ]; then
    echo "ERROR: Report at $REPORT_PATH too small ($FILE_SIZE bytes)" >&2
    exit 1
  fi

  # Content check (must have Findings section)
  if ! grep -q "## Findings" "$REPORT_PATH"; then
    echo "WARNING: Report at $REPORT_PATH missing Findings section" >&2
  fi

  ((VALID_REPORTS++))
done

echo "[CHECKPOINT] Multi-report validation complete"
echo "Context: VALID_REPORTS=${VALID_REPORTS}/${TOTAL_REPORTS}"
echo "Ready for: Metadata extraction"
```
\```

**Substitutions**:
- Replace `REPORT_PATHS_LIST` with state variable containing pipe-separated report paths
- Adjust size threshold (100 bytes) if needed
- Customize content checks for domain-specific section names

**Validation Criteria**:
1. File existence (hard barrier)
2. Minimum size (>100 bytes)
3. Content structure (Findings section)
4. Fail-fast on ANY validation failure

---

### Template 10: Metadata Extraction and Aggregation

```markdown
## Block 1f-metadata: Extract Metadata from Reports

**EXECUTE NOW**: Extract metadata summaries from research reports:

```bash
set +H
# Read state for report paths
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/workflow_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# Parse report paths
IFS='|' read -ra REPORT_PATHS_ARRAY <<< "$REPORT_PATHS_LIST"
IFS='|' read -ra TOPICS_ARRAY <<< "$TOPICS_LIST"

# Extract metadata from each report
METADATA_SUMMARY=""
TOTAL_FINDINGS=0
TOTAL_RECOMMENDATIONS=0

for i in "${!REPORT_PATHS_ARRAY[@]}"; do
  REPORT_PATH="${REPORT_PATHS_ARRAY[$i]}"
  TOPIC="${TOPICS_ARRAY[$i]}"

  # Extract title (first heading or use filename)
  TITLE=$(grep -m 1 "^# " "$REPORT_PATH" | sed 's/^# //' || basename "$REPORT_PATH" .md)

  # Count findings (lines starting with "- " in Findings section)
  FINDINGS_COUNT=$(sed -n '/## Findings/,/^##/p' "$REPORT_PATH" | grep -c "^- " || echo 0)
  TOTAL_FINDINGS=$((TOTAL_FINDINGS + FINDINGS_COUNT))

  # Count recommendations (lines starting with "- " in Recommendations section)
  RECOMMENDATIONS_COUNT=$(sed -n '/## Recommendations/,/^##/p' "$REPORT_PATH" | grep -c "^- " || echo 0)
  TOTAL_RECOMMENDATIONS=$((TOTAL_RECOMMENDATIONS + RECOMMENDATIONS_COUNT))

  # Aggregate metadata (110 tokens per report format)
  METADATA_ENTRY="Topic ${i}: ${TOPIC}\nTitle: ${TITLE}\nFindings: ${FINDINGS_COUNT}\nRecommendations: ${RECOMMENDATIONS_COUNT}\nPath: ${REPORT_PATH}\n"

  if [ -z "$METADATA_SUMMARY" ]; then
    METADATA_SUMMARY="$METADATA_ENTRY"
  else
    METADATA_SUMMARY="${METADATA_SUMMARY}\n${METADATA_ENTRY}"
  fi
done

# Persist aggregated metadata to state
append_workflow_state "METADATA_SUMMARY" "$METADATA_SUMMARY"
append_workflow_state "TOTAL_FINDINGS" "$TOTAL_FINDINGS"
append_workflow_state "TOTAL_RECOMMENDATIONS" "$TOTAL_RECOMMENDATIONS"

echo "[CHECKPOINT] Metadata extraction complete"
echo "Context: TOTAL_FINDINGS=${TOTAL_FINDINGS}, TOTAL_RECOMMENDATIONS=${TOTAL_RECOMMENDATIONS}"
echo "Ready for: Planning phase (metadata-only context)"
```
\```

**Substitutions**:
- Replace `REPORT_PATHS_LIST` and `TOPICS_LIST` with state variables
- Customize metadata extraction logic for domain-specific sections
- Adjust token target (110 tokens/report) if needed

**Metadata Format** (per report):
- Topic: Original topic name
- Title: Extracted from report heading
- Findings: Count of bullet points in Findings section
- Recommendations: Count of bullet points in Recommendations section
- Path: Absolute path to report file

**Context Reduction**:
- Full report: ~2,500 tokens
- Metadata summary: ~110 tokens
- Reduction: 95% (for 3 reports: 7,500 → 330 tokens)

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
