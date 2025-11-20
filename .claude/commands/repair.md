---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob, Write
argument-hint: [--since TIME] [--type TYPE] [--command CMD] [--severity LEVEL] [--complexity 1-4]
description: Research error patterns and create implementation plan to fix them
command-type: primary
dependent-agents:
  - repair-analyst
  - plan-architect
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
documentation: See .claude/docs/guides/commands/repair-command-guide.md for complete usage guide
---

# /repair - Error Analysis and Repair Planning Workflow Command

YOU ARE EXECUTING an error analysis workflow that reads error logs, groups them by patterns, identifies root causes, and creates an implementation plan to fix them.

**Workflow Type**: research-and-plan
**Terminal State**: plan (after planning phase complete)
**Expected Output**: Error analysis reports + fix implementation plan in .claude/specs/NNN_topic/

## Block 1: Consolidated Setup

**EXECUTE NOW**: The user invoked `/repair` with optional filters. Parse arguments and initialize workflow.

Execute this bash block:

```bash
set +H  # CRITICAL: Disable history expansion

# === CAPTURE ERROR FILTERS ===
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/repair_arg_$(date +%s%N).txt"
# SUBSTITUTE THE FULL COMMAND ARGUMENTS IN THE LINE BELOW (if user provided filters)
echo "error analysis and repair" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/repair_arg_path.txt"

# === READ AND PARSE ARGUMENTS ===
ARGS_STRING=$(cat "$TEMP_FILE" 2>/dev/null || echo "error analysis and repair")

# Parse optional flags
ERROR_SINCE=""
ERROR_TYPE=""
ERROR_COMMAND=""
ERROR_SEVERITY=""

if [[ "$ARGS_STRING" =~ --since[[:space:]]+([^[:space:]]+) ]]; then
  ERROR_SINCE="${BASH_REMATCH[1]}"
  ARGS_STRING=$(echo "$ARGS_STRING" | sed 's/--since[[:space:]]*[^[:space:]]*//' | xargs)
fi

if [[ "$ARGS_STRING" =~ --type[[:space:]]+([^[:space:]]+) ]]; then
  ERROR_TYPE="${BASH_REMATCH[1]}"
  ARGS_STRING=$(echo "$ARGS_STRING" | sed 's/--type[[:space:]]*[^[:space:]]*//' | xargs)
fi

if [[ "$ARGS_STRING" =~ --command[[:space:]]+([^[:space:]]+) ]]; then
  ERROR_COMMAND="${BASH_REMATCH[1]}"
  ARGS_STRING=$(echo "$ARGS_STRING" | sed 's/--command[[:space:]]*[^[:space:]]*//' | xargs)
fi

if [[ "$ARGS_STRING" =~ --severity[[:space:]]+([^[:space:]]+) ]]; then
  ERROR_SEVERITY="${BASH_REMATCH[1]}"
  ARGS_STRING=$(echo "$ARGS_STRING" | sed 's/--severity[[:space:]]*[^[:space:]]*//' | xargs)
fi

# Parse --complexity flag (default: 2 for error analysis)
DEFAULT_COMPLEXITY=2
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"

if [[ "$ARGS_STRING" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  ARGS_STRING=$(echo "$ARGS_STRING" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi

if ! echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"; then
  echo "ERROR: Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" >&2
  exit 1
fi

# Create error filters JSON
ERROR_FILTERS=$(jq -n \
  --arg since "$ERROR_SINCE" \
  --arg type "$ERROR_TYPE" \
  --arg command "$ERROR_COMMAND" \
  --arg severity "$ERROR_SEVERITY" \
  '{since: $since, type: $type, command: $command, severity: $severity}')

# Create description for workflow
ERROR_DESCRIPTION="error analysis and repair"
if [ -n "$ERROR_TYPE" ]; then
  ERROR_DESCRIPTION="$ERROR_TYPE errors repair"
elif [ -n "$ERROR_COMMAND" ]; then
  ERROR_DESCRIPTION="$ERROR_COMMAND errors repair"
fi

# === DETECT PROJECT DIRECTORY ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

export CLAUDE_PROJECT_DIR

# === SOURCE LIBRARIES ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/library-version-check.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || {
  echo "ERROR: Failed to source unified-location-detection.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-initialization.sh" >&2
  exit 1
}

# Verify library versions
check_library_requirements "$(cat <<'EOF'
workflow-state-machine.sh: ">=2.0.0"
state-persistence.sh: ">=1.5.0"
EOF
)" || exit 1

# === INITIALIZE STATE ===
WORKFLOW_TYPE="research-and-plan"
TERMINAL_STATE="plan"
COMMAND_NAME="repair"

WORKFLOW_ID="repair_$(date +%s)"
STATE_ID_FILE="${HOME}/.claude/tmp/repair_state_id.txt"
mkdir -p "$(dirname "$STATE_ID_FILE")"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"
export WORKFLOW_ID

# Capture state file path for append_workflow_state
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE

# Validate state file creation
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to initialize workflow state" >&2
  exit 1
fi

if ! sm_init "$ERROR_DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "[]" 2>&1; then
  echo "ERROR: State machine initialization failed" >&2
  exit 1
fi

# === TRANSITION TO RESEARCH AND SETUP PATHS ===
if ! sm_transition "$STATE_RESEARCH" 2>&1; then
  echo "ERROR: State transition to RESEARCH failed" >&2
  exit 1
fi

# Initialize workflow paths (uses fallback slug generation)
if ! initialize_workflow_paths "$ERROR_DESCRIPTION" "research-and-plan" "$RESEARCH_COMPLEXITY" ""; then
  echo "ERROR: Failed to initialize workflow paths" >&2
  exit 1
fi

SPECS_DIR="$TOPIC_PATH"
RESEARCH_DIR="${TOPIC_PATH}/reports"
PLANS_DIR="${TOPIC_PATH}/plans"
mkdir -p "$RESEARCH_DIR"
mkdir -p "$PLANS_DIR"

# === PERSIST FOR BLOCK 2 ===
append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"
append_workflow_state "SPECS_DIR" "$SPECS_DIR"
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"
append_workflow_state "PLANS_DIR" "$PLANS_DIR"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "TOPIC_NAME" "$TOPIC_NAME"
append_workflow_state "TOPIC_NUM" "$TOPIC_NUM"
append_workflow_state "ERROR_DESCRIPTION" "$ERROR_DESCRIPTION"
append_workflow_state "ERROR_FILTERS" "$ERROR_FILTERS"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"

echo "Setup complete: $WORKFLOW_ID (research-and-plan, complexity: $RESEARCH_COMPLEXITY)"
echo "Research directory: $RESEARCH_DIR"
echo "Plans directory: $PLANS_DIR"
```

**EXECUTE NOW**: USE the Task tool to invoke the repair-analyst agent.

Task {
  subagent_type: "general-purpose"
  description: "Analyze error logs and create report with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/repair-analyst.md

    You are conducting error analysis for: repair workflow

    **Workflow-Specific Context**:
    - Error Filters: ${ERROR_FILTERS}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Output Directory: ${RESEARCH_DIR}
    - Workflow Type: research-and-plan
    - Error Log Path: ${CLAUDE_PROJECT_DIR}/.claude/data/logs/errors.jsonl

    Execute error analysis according to behavioral guidelines and return completion signal:
    REPORT_CREATED: [path to created report]
  "
}

## Block 2: Research Verification and Planning Setup

**EXECUTE NOW**: Verify research artifacts and prepare for planning:

```bash
set +H  # CRITICAL: Disable history expansion

# === LOAD STATE ===
STATE_ID_FILE="${HOME}/.claude/tmp/repair_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

# Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi
export CLAUDE_PROJECT_DIR

source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null

load_workflow_state "$WORKFLOW_ID" false

# === VERIFY RESEARCH ARTIFACTS ===
echo "Verifying research artifacts..."

if [ ! -d "$RESEARCH_DIR" ]; then
  echo "ERROR: Research phase failed to create reports directory" >&2
  exit 1
fi

if [ -z "$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null)" ]; then
  echo "ERROR: Research phase failed to create report files" >&2
  exit 1
fi

UNDERSIZED_FILES=$(find "$RESEARCH_DIR" -name '*.md' -type f -size -100c 2>/dev/null)
if [ -n "$UNDERSIZED_FILES" ]; then
  echo "ERROR: Research report(s) too small (< 100 bytes)" >&2
  exit 1
fi

REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null | wc -l)
append_workflow_state "REPORT_COUNT" "$REPORT_COUNT"

echo "Research verified: $REPORT_COUNT reports"
echo ""

# === TRANSITION TO PLAN ===
if ! sm_transition "$STATE_PLAN" 2>&1; then
  echo "ERROR: State transition to PLAN failed" >&2
  exit 1
fi

echo "=== Phase 2: Planning ==="
echo ""

# === PREPARE PLAN PATH ===
PLAN_NUMBER="001"
PLAN_FILENAME="${PLAN_NUMBER}_$(echo "$TOPIC_NAME" | cut -c1-40)_plan.md"
PLAN_PATH="${PLANS_DIR}/${PLAN_FILENAME}"

# Collect research report paths
REPORT_PATHS=$(find "$RESEARCH_DIR" -name '*.md' -type f | sort)
REPORT_PATHS_JSON=$(echo "$REPORT_PATHS" | jq -R . | jq -s .)

# === PERSIST FOR BLOCK 3 ===
append_workflow_state "PLAN_PATH" "$PLAN_PATH"
append_workflow_state "REPORT_PATHS_JSON" "$REPORT_PATHS_JSON"

save_completed_states_to_state 2>/dev/null

echo "Plan will be created at: $PLAN_PATH"
echo "Using $REPORT_COUNT research reports"
```

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for ${ERROR_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are creating an implementation plan for: repair workflow

    **Workflow-Specific Context**:
    - Feature Description: ${ERROR_DESCRIPTION}
    - Output Path: ${PLAN_PATH}
    - Research Reports: ${REPORT_PATHS_JSON}
    - Workflow Type: research-and-plan
    - Operation Mode: new plan creation

    Execute planning according to behavioral guidelines and return completion signal:
    PLAN_CREATED: ${PLAN_PATH}
  "
}

## Block 3: Plan Verification and Completion

**EXECUTE NOW**: Verify plan artifacts and complete workflow:

```bash
set +H  # CRITICAL: Disable history expansion

# === LOAD STATE ===
STATE_ID_FILE="${HOME}/.claude/tmp/repair_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

# Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi
export CLAUDE_PROJECT_DIR

source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null

load_workflow_state "$WORKFLOW_ID" false

# === VERIFY PLAN ARTIFACTS ===
echo "Verifying plan artifacts..."

if [ ! -f "$PLAN_PATH" ]; then
  echo "ERROR: Planning phase failed to create plan file" >&2
  exit 1
fi

FILE_SIZE=$(wc -c < "$PLAN_PATH")
if [ "$FILE_SIZE" -lt 500 ]; then
  echo "ERROR: Plan file too small ($FILE_SIZE bytes)" >&2
  exit 1
fi

echo "Plan verified: $FILE_SIZE bytes"
echo ""

# === COMPLETE WORKFLOW ===
if ! sm_transition "$STATE_COMPLETE" 2>&1; then
  echo "ERROR: State transition to COMPLETE failed" >&2
  exit 1
fi

save_completed_states_to_state 2>/dev/null

# === OUTPUT SUMMARY ===
echo "=== Error Analysis and Planning Complete ==="
echo ""
echo "Workflow Type: research-and-plan"
echo "Specs Directory: $SPECS_DIR"
echo "Error Analysis Reports: $REPORT_COUNT reports in $RESEARCH_DIR"
echo "Fix Implementation Plan: $PLAN_PATH"
echo ""
echo "Next Steps:"
echo "- Review plan: cat $PLAN_PATH"
echo "- Implement fixes: /build $PLAN_PATH"
```
