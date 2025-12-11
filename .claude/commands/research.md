---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
argument-hint: <workflow-description> [--file <path>] [--complexity 1-4]
description: Research-only workflow - Creates comprehensive research reports without planning or implementation
command-type: primary
dependent-agents:
  - research-coordinator
  - research-specialist
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
documentation: See .claude/docs/guides/commands/research-command-guide.md for complete usage guide
---

# /research - Research-Only Workflow Command

YOU ARE EXECUTING a research-only workflow that creates comprehensive research reports without planning or implementation phases.

**Workflow Type**: research-only
**Terminal State**: research (after research phase complete)
**Expected Output**: Research reports in .claude/specs/NNN_topic/reports/

**Architecture**: 3-block optimized design (95% context reduction via coordinator delegation)
- Block 1 (239 lines): Argument capture, state initialization, state persistence
- Block 1b (Task invocation): Topic naming agent (hard barrier pattern)
- Block 1c (225 lines): Topic path initialization, decomposition, report path pre-calculation
- Block 2 (Task invocation): Research coordination (specialist or coordinator routing)
- Block 2b (172 lines): Hard barrier validation, partial success handling
- Block 3 (140 lines): State transition, console summary, completion

**Note**: Block 1 was split into 3 sub-blocks (1, 1b, 1c) to prevent bash preprocessing bugs that occur when blocks exceed 400 lines. See .claude/specs/010_research_conform_standards/ for refactoring details.

## Block 1: Setup and Path Pre-Calculation

**EXECUTE NOW**: The user invoked `/research "<workflow-description>"`. This block performs complete setup:
1. Capture and validate arguments
2. Initialize state machine
3. Invoke topic-naming-agent
4. Decompose topics (for complexity >= 3)
5. Pre-calculate report paths

In the **bash block below**, replace `YOUR_WORKFLOW_DESCRIPTION_HERE` with the actual workflow description (keeping the quotes).

**Example**: If user ran `/research "authentication patterns in codebase"`, change:
- FROM: `echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "$TEMP_FILE"`
- TO: `echo "authentication patterns in codebase" > "$TEMP_FILE"`

Execute this bash block with your substitution:

```bash
# === PREPROCESSING SAFETY ===
set +H 2>/dev/null || true  # Disable history expansion
set +o histexpand 2>/dev/null || true
set -e  # Fail-fast per code-standards.md

# === PRE-TRAP ERROR BUFFER ===
declare -a _EARLY_ERROR_BUFFER=()

# === CAPTURE WORKFLOW DESCRIPTION ===
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/research_arg_$(date +%s%N).txt"
# SUBSTITUTE THE WORKFLOW DESCRIPTION IN THE LINE BELOW
echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/research_arg_path.txt"

# === READ AND VALIDATE ===
WORKFLOW_DESCRIPTION=$(cat "$TEMP_FILE" 2>/dev/null || echo "")

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description is empty" >&2
  echo "Usage: /research \"<workflow description>\"" >&2
  exit 1
fi

# Parse optional --complexity flag (default: 2 for research-only)
DEFAULT_COMPLEXITY=2
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"

if [[ "$WORKFLOW_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  WORKFLOW_DESCRIPTION=$(echo "$WORKFLOW_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi

echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"
COMPLEXITY_VALID=$?
if [ $COMPLEXITY_VALID -ne 0 ]; then
  echo "ERROR: Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" >&2
  exit 1
fi

# Parse optional --file flag for long prompts
ORIGINAL_PROMPT_FILE_PATH=""
if [[ "$WORKFLOW_DESCRIPTION" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  ORIGINAL_PROMPT_FILE_PATH="${BASH_REMATCH[1]}"
  # Convert to absolute path if relative
  [[ "${ORIGINAL_PROMPT_FILE_PATH:-}" = /* ]]
  IS_ABSOLUTE_PATH=$?
  if [ $IS_ABSOLUTE_PATH -ne 0 ]; then
    ORIGINAL_PROMPT_FILE_PATH="$(pwd)/${ORIGINAL_PROMPT_FILE_PATH:-}"
  fi
  # Validate file exists
  if [ ! -f "${ORIGINAL_PROMPT_FILE_PATH:-}" ]; then
    echo "ERROR: Prompt file not found: ${ORIGINAL_PROMPT_FILE_PATH:-}" >&2
    exit 1
  fi
  # Read file content into WORKFLOW_DESCRIPTION
  WORKFLOW_DESCRIPTION=$(cat "${ORIGINAL_PROMPT_FILE_PATH:-}")
  if [ -z "$WORKFLOW_DESCRIPTION" ]; then
    echo "WARNING: Prompt file is empty: ${ORIGINAL_PROMPT_FILE_PATH:-}" >&2
  fi
elif [[ "$WORKFLOW_DESCRIPTION" =~ --file ]]; then
  echo "ERROR: --file flag requires a path argument" >&2
  exit 1
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

# === SOURCE LIBRARIES (Three-Tier Pattern) ===
# Tier 1: Critical Foundation (fail-fast required)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/library-version-check.sh" || exit 1

# Tier 2: Workflow Support (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || true
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || true

# Tier 3: Helper utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load validation-utils.sh" >&2
  exit 1
}

# Verify library versions
check_library_requirements "$(cat <<'EOF'
workflow-state-machine.sh: ">=2.0.0"
state-persistence.sh: ">=1.5.0"
EOF
)" || exit 1

# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists

# === SETUP EARLY BASH ERROR TRAP ===
setup_bash_error_trap "/research" "research_early_$(date +%s)" "early_init"
_flush_early_errors

# === INITIALIZE STATE ===
WORKFLOW_TYPE="research-only"
TERMINAL_STATE="research"
COMMAND_NAME="/research"
USER_ARGS="$WORKFLOW_DESCRIPTION"
export COMMAND_NAME USER_ARGS

WORKFLOW_ID="research_$(date +%s%N)"
export WORKFLOW_ID

# === UPDATE BASH ERROR TRAP WITH ACTUAL VALUES ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Initialize workflow state file
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE

if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "Failed to initialize workflow state file" \
    "bash_block_1" \
    "$(jq -n --arg path "${STATE_FILE:-UNDEFINED}" '{expected_path: $path}')"
  echo "ERROR: Failed to initialize workflow state" >&2
  exit 1
fi

sm_init "$WORKFLOW_DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "[]" 2>&1
SM_INIT_EXIT=$?
if [ $SM_INIT_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State machine initialization failed" \
    "bash_block_1" \
    "$(jq -n --arg type "$WORKFLOW_TYPE" --argjson complexity "$RESEARCH_COMPLEXITY" \
       '{workflow_type: $type, complexity: $complexity}')"
  echo "ERROR: State machine initialization failed" >&2
  exit 1
fi

# === TRANSITION TO RESEARCH ===
sm_transition "$STATE_RESEARCH" 2>&1
SM_TRANSITION_EXIT=$?
if [ $SM_TRANSITION_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to RESEARCH failed" \
    "bash_block_1" \
    "$(jq -n --arg state "$STATE_RESEARCH" '{target_state: $state}')"
  echo "ERROR: State transition to RESEARCH failed" >&2
  exit 1
fi

# === PRE-CALCULATE TOPIC NAME FILE PATH (Hard Barrier Pattern) ===
TOPIC_NAME_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt"
mkdir -p "$(dirname "$TOPIC_NAME_FILE")" 2>/dev/null || true

# Persist for topic-naming-agent
TOPIC_NAMING_INPUT_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_naming_input_${WORKFLOW_ID}.txt"
echo "$WORKFLOW_DESCRIPTION" > "$TOPIC_NAMING_INPUT_FILE"

# === DETERMINE MULTI-TOPIC MODE ===
USE_MULTI_TOPIC="false"
TOPIC_COUNT=1

if [ "${RESEARCH_COMPLEXITY:-2}" -ge 3 ]; then
  USE_MULTI_TOPIC="true"
  if [ "${RESEARCH_COMPLEXITY:-2}" -eq 3 ]; then
    TOPIC_COUNT=3
  else
    TOPIC_COUNT=4
  fi
fi

# Check for conjunctions if complexity < 3
if [ "$USE_MULTI_TOPIC" = "false" ]; then
  if echo "$WORKFLOW_DESCRIPTION" | grep -qiE " and | or |, .+ and |, .+ or "; then
    USE_MULTI_TOPIC="true"
    TOPIC_COUNT=2
    echo "Detected multi-topic pattern in description"
  fi
fi

# === PERSIST STATE FOR BLOCK 2 ===
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "USER_ARGS" "$USER_ARGS"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"
append_workflow_state "WORKFLOW_DESCRIPTION" "$WORKFLOW_DESCRIPTION"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
append_workflow_state "USE_MULTI_TOPIC" "$USE_MULTI_TOPIC"
append_workflow_state "TOPIC_COUNT" "$TOPIC_COUNT"
append_workflow_state "TOPIC_NAME_FILE" "$TOPIC_NAME_FILE"
append_workflow_state "TOPIC_NAMING_INPUT_FILE" "$TOPIC_NAMING_INPUT_FILE"
append_workflow_state "ORIGINAL_PROMPT_FILE_PATH" "${ORIGINAL_PROMPT_FILE_PATH:-}"

echo ""
echo "=== Research Workflow Setup ==="
echo "  Complexity: $RESEARCH_COMPLEXITY"
echo "  Multi-topic mode: $USE_MULTI_TOPIC"
echo "  Target topic count: $TOPIC_COUNT"
echo "  Topic name file: $TOPIC_NAME_FILE"
echo ""
echo "CHECKPOINT: Block 1 setup complete, ready for topic-naming-agent"
```

## Block 1b: Topic Name Generation (Hard Barrier Invocation)

**EXECUTE NOW**: USE the Task tool to invoke the topic-naming-agent for semantic topic directory naming.

Task {
  subagent_type: "general"
  description: "Generate semantic topic directory name"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md

    You are generating a topic directory name for: /research command

    **Input Contract (Hard Barrier Pattern)**:
    - Output Path: ${TOPIC_NAME_FILE}
    - User Prompt: ${WORKFLOW_DESCRIPTION}
    - Command Name: /research

    **CRITICAL**: You MUST write the topic name to the EXACT path specified above.
    The orchestrator has pre-calculated this path and will validate it exists after you return.
    Do NOT derive or calculate your own path.

    Execute topic naming according to behavioral guidelines:
    1. Generate semantic topic name from user prompt
    2. Validate format (^[a-z0-9_]{5,40}$)
    3. Write topic name to the Output Path specified above using Write tool
    4. Return completion signal: TOPIC_NAME_GENERATED: <generated_name>

    If you encounter an error, return:
    TASK_ERROR: <error_type> - <error_message>
  "
}

## Block 1c: Topic Path Initialization and Path Pre-Calculation

**EXECUTE NOW**: Parse topic name, initialize workflow paths, decompose topics (if multi-topic), and pre-calculate report paths.

```bash
# === PREPROCESSING SAFETY ===
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e

# === DETECT PROJECT DIRECTORY ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

export CLAUDE_PROJECT_DIR

# === RESTORE STATE ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
STATE_FILE=$(discover_latest_state_file "research")
[ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ] || exit 1
source "$STATE_FILE"  # WORKFLOW_ID restored

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Failed to restore WORKFLOW_ID" >&2
  exit 1
fi

STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi

# === SOURCE LIBRARIES (Three-Tier Pattern) ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || true

COMMAND_NAME="/research"
USER_ARGS="${WORKFLOW_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

echo ""
echo "=== Topic Path Initialization ==="
echo ""

# === PARSE TOPIC NAME FROM AGENT OUTPUT ===
TOPIC_NAME="no_name_error"
NAMING_STRATEGY="fallback"

if [ -f "$TOPIC_NAME_FILE" ]; then
  TOPIC_NAME=$(cat "$TOPIC_NAME_FILE" 2>/dev/null | tr -d '\n' | tr -d ' ')

  if [ -z "$TOPIC_NAME" ]; then
    NAMING_STRATEGY="agent_empty_output"
    TOPIC_NAME="no_name_error"
  else
    echo "$TOPIC_NAME" | grep -Eq '^[a-z0-9_]{5,40}$'
    IS_VALID=$?
    if [ $IS_VALID -ne 0 ]; then
      log_command_error \
        "$COMMAND_NAME" \
        "$WORKFLOW_ID" \
        "$USER_ARGS" \
        "validation_error" \
        "Topic naming agent returned invalid format" \
        "bash_block_1c" \
        "$(jq -n --arg name "$TOPIC_NAME" '{invalid_name: $name}')"
      NAMING_STRATEGY="validation_failed"
      TOPIC_NAME="no_name_error"
    else
      NAMING_STRATEGY="llm_generated"
    fi
  fi
else
  NAMING_STRATEGY="agent_no_output_file"
fi

rm -f "$TOPIC_NAME_FILE" 2>/dev/null || true

echo "Topic name: $TOPIC_NAME (strategy: $NAMING_STRATEGY)"

# === INITIALIZE WORKFLOW PATHS ===
CLASSIFICATION_JSON=$(jq -n --arg slug "$TOPIC_NAME" '{topic_directory_slug: $slug}')

initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "research-only" "$RESEARCH_COMPLEXITY" "$CLASSIFICATION_JSON"
INIT_EXIT=$?
if [ $INIT_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Failed to initialize workflow paths" \
    "bash_block_1c" \
    "$(jq -n --arg desc "$WORKFLOW_DESCRIPTION" '{description: $desc}')"
  echo "ERROR: Failed to initialize workflow paths" >&2
  exit 1
fi

RESEARCH_DIR="${TOPIC_PATH}/reports"
mkdir -p "$RESEARCH_DIR" 2>/dev/null || true

echo "Research directory: $RESEARCH_DIR"

# === ARCHIVE PROMPT FILE (if --file was used) ===
ARCHIVED_PROMPT_PATH=""
if [ -n "${ORIGINAL_PROMPT_FILE_PATH:-}" ] && [ -f "${ORIGINAL_PROMPT_FILE_PATH:-}" ]; then
  mkdir -p "${TOPIC_PATH}/prompts"
  ARCHIVED_PROMPT_PATH="${TOPIC_PATH}/prompts/$(basename "${ORIGINAL_PROMPT_FILE_PATH:-}")"
  mv "${ORIGINAL_PROMPT_FILE_PATH:-}" "$ARCHIVED_PROMPT_PATH"
  echo "Prompt file archived: $ARCHIVED_PROMPT_PATH"
fi

# === TOPIC DECOMPOSITION (for complexity >= 3) ===
echo ""
echo "=== Topic Decomposition ==="
echo ""

declare -a TOPICS_ARRAY=()
if [ "$USE_MULTI_TOPIC" = "true" ]; then
  echo "Decomposing research request into $TOPIC_COUNT topics..."

  # Simple decomposition based on conjunctions and commas
  IFS=',' read -ra PARTS <<< "$WORKFLOW_DESCRIPTION"
  for part in "${PARTS[@]}"; do
    IFS=' and ' read -ra SUB_PARTS <<< "$part"
    for subpart in "${SUB_PARTS[@]}"; do
      IFS=' or ' read -ra SUB_SUB_PARTS <<< "$subpart"
      for topic in "${SUB_SUB_PARTS[@]}"; do
        topic=$(echo "$topic" | xargs)
        if [ -n "$topic" ] && [ ${#TOPICS_ARRAY[@]} -lt "$TOPIC_COUNT" ]; then
          TOPICS_ARRAY+=("$topic")
        fi
      done
    done
  done

  # If decomposition produced fewer topics, use single topic
  if [ ${#TOPICS_ARRAY[@]} -lt 2 ]; then
    echo "Decomposition produced ${#TOPICS_ARRAY[@]} topics, using single-topic mode"
    USE_MULTI_TOPIC="false"
    TOPICS_ARRAY=("$WORKFLOW_DESCRIPTION")
  else
    echo "Decomposed into ${#TOPICS_ARRAY[@]} topics:"
    for i in $(seq 0 $((${#TOPICS_ARRAY[@]} - 1))); do
      echo "  $((i+1)). ${TOPICS_ARRAY[$i]}"
    done
  fi
else
  TOPICS_ARRAY=("$WORKFLOW_DESCRIPTION")
  echo "Using single-topic mode (complexity ${RESEARCH_COMPLEXITY:-2})"
fi

# === PRE-CALCULATE REPORT PATHS ===
echo ""
echo "Pre-calculating report paths..."

EXISTING_REPORTS=$(find "$RESEARCH_DIR" -name '[0-9][0-9][0-9]-*.md' 2>/dev/null | wc -l || echo 0)
EXISTING_REPORTS=$(echo "$EXISTING_REPORTS" | tr -d '\n' | tr -d ' ')
EXISTING_REPORTS=${EXISTING_REPORTS:-0}
[[ "$EXISTING_REPORTS" =~ ^[0-9]+$ ]] || EXISTING_REPORTS=0

START_NUM=$((EXISTING_REPORTS + 1))

declare -a REPORT_PATHS_ARRAY=()
for i in $(seq 0 $((${#TOPICS_ARRAY[@]} - 1))); do
  TOPIC="${TOPICS_ARRAY[$i]}"
  REPORT_NUM=$(printf "%03d" $((START_NUM + i)))

  # Generate slug from topic (max 40 chars, kebab-case)
  REPORT_SLUG=$(echo "$TOPIC" | head -c 40 | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

  if [ -z "$REPORT_SLUG" ]; then
    REPORT_SLUG="research-topic-$((i+1))"
  fi

  REPORT_PATH="${RESEARCH_DIR}/${REPORT_NUM}-${REPORT_SLUG}.md"
  REPORT_PATHS_ARRAY+=("$REPORT_PATH")

  echo "  $REPORT_NUM: $REPORT_PATH"
done

# === PERSIST FOR BLOCK 2 ===
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "TOPIC_NAME" "$TOPIC_NAME"
append_workflow_state "USE_MULTI_TOPIC" "$USE_MULTI_TOPIC"
append_workflow_state "ARCHIVED_PROMPT_PATH" "${ARCHIVED_PROMPT_PATH:-}"

# Save topics and paths (pipe-separated for state file)
TOPICS_LIST=$(printf "%s|" "${TOPICS_ARRAY[@]}")
TOPICS_LIST="${TOPICS_LIST%|}"
append_workflow_state "TOPICS_LIST" "$TOPICS_LIST"

REPORT_PATHS_LIST=$(printf "%s|" "${REPORT_PATHS_ARRAY[@]}")
REPORT_PATHS_LIST="${REPORT_PATHS_LIST%|}"
append_workflow_state "REPORT_PATHS_LIST" "$REPORT_PATHS_LIST"

# For single-topic backward compatibility
REPORT_PATH="${REPORT_PATHS_ARRAY[0]}"
append_workflow_state "REPORT_PATH" "$REPORT_PATH"

echo ""
echo "CHECKPOINT: Block 1 complete"
echo "  Topics: ${#TOPICS_ARRAY[@]}"
echo "  Report paths: ${#REPORT_PATHS_ARRAY[@]}"
echo "  Ready for: coordinator invocation (Block 2)"
```

## Block 2: Research Coordination [CRITICAL BARRIER]

**HARD BARRIER - Research Coordination**

**CRITICAL BARRIER**: This block MUST invoke research-coordinator (for multi-topic) or research-specialist (for single-topic) via Task tool. The Task invocation is MANDATORY and CANNOT be bypassed. Block 2 verification will FAIL if reports are not created by the subagent.

**Routing Decision**:
- **Complexity < 3 (single-topic)**: Invoke research-specialist directly
- **Complexity >= 3 (multi-topic)**: Invoke research-coordinator for parallel execution

**EXECUTE NOW**: USE the Task tool to invoke the appropriate research agent based on complexity level.

**For SINGLE-TOPIC research (complexity < 3)**:

Task {
  subagent_type: "general"
  description: "Research topic: ${WORKFLOW_DESCRIPTION}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent.

    **CRITICAL - Hard Barrier Pattern**:
    REPORT_PATH=${REPORT_PATH}

    **Research Topic**: ${WORKFLOW_DESCRIPTION}

    Follow all steps in research-specialist.md:
    1. STEP 1: Verify absolute report path received
    2. STEP 2: Create report file FIRST (before research)
    3. STEP 3: Conduct research and update report incrementally
    4. STEP 4: Verify file exists and return: REPORT_CREATED: ${REPORT_PATH}
  "
}

**For MULTI-TOPIC research (complexity >= 3)**:

Task {
  subagent_type: "general"
  description: "Coordinate multi-topic research for ${WORKFLOW_DESCRIPTION}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    You are coordinating research for: research workflow

    **Input Contract (Hard Barrier Pattern - Mode 2: Pre-Decomposed)**:
    - research_request: ${WORKFLOW_DESCRIPTION}
    - research_complexity: ${RESEARCH_COMPLEXITY}
    - report_dir: ${RESEARCH_DIR}
    - topic_path: ${TOPIC_PATH}
    - topics: ${TOPICS_LIST}
    - report_paths: ${REPORT_PATHS_LIST}
    - Workflow Type: research-only
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
    - Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}

    **CRITICAL**: Topics and report paths have been pre-calculated.
    Use Mode 2 (Pre-Decomposed) - parse TOPICS_LIST and REPORT_PATHS_LIST (pipe-separated).

    Execute research planning:
    1. Parse topics and report_paths from pipe-separated lists.
    2. Create an invocation plan file with the topics and pre-calculated report paths.
    3. Validate the invocation plan file.
    4. Return the invocation plan metadata to the primary agent as a completion signal. Do NOT invoke the research-specialist agent yourself.

    Return completion signal:
    RESEARCH_COMPLETE: {REPORT_COUNT}
    reports: [JSON array of report metadata]
    total_findings: {N}
    total_recommendations: {N}
  "
}

## Block 2b: Hard Barrier Validation and Brief Summary Parsing

**EXECUTE NOW**: Validate reports exist and parse coordinator/specialist return signal.

```bash
# === PREPROCESSING SAFETY ===
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e

# === PRE-TRAP ERROR BUFFER ===
declare -a _EARLY_ERROR_BUFFER=()

# === DETECT PROJECT DIRECTORY ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

export CLAUDE_PROJECT_DIR

# === RESTORE STATE ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
STATE_FILE=$(discover_latest_state_file "research")
[ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ] || exit 1
source "$STATE_FILE"  # WORKFLOW_ID restored

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Failed to restore WORKFLOW_ID" >&2
  exit 1
fi

STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi

# === SOURCE LIBRARIES ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

COMMAND_NAME="/research"
USER_ARGS="${WORKFLOW_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
_flush_early_errors

echo ""
echo "=== Hard Barrier Validation (Brief Summary Parsing) ==="
echo ""

# === PARSE REPORT PATHS ===
IFS='|' read -ra REPORT_PATHS_ARRAY <<< "$REPORT_PATHS_LIST"
EXPECTED_COUNT=${#REPORT_PATHS_ARRAY[@]}

echo "Expected $EXPECTED_COUNT report file(s):"
for path in "${REPORT_PATHS_ARRAY[@]}"; do
  echo "  - $path"
done
echo ""

# === VALIDATE REPORTS (PARTIAL SUCCESS MODE) ===
CREATED_COUNT=0
FAILED_REPORTS=()
TOTAL_SIZE=0

for REPORT_PATH in "${REPORT_PATHS_ARRAY[@]}"; do
  echo -n "Validating: $(basename "$REPORT_PATH")... "

  if [ ! -f "$REPORT_PATH" ]; then
    echo "MISSING"
    FAILED_REPORTS+=("$REPORT_PATH")
    continue
  fi

  REPORT_SIZE=$(wc -c < "$REPORT_PATH" 2>/dev/null || echo 0)
  if [ "$REPORT_SIZE" -lt 100 ]; then
    echo "TOO SMALL ($REPORT_SIZE bytes)"
    FAILED_REPORTS+=("$REPORT_PATH")
    continue
  fi

  TOTAL_SIZE=$((TOTAL_SIZE + REPORT_SIZE))
  CREATED_COUNT=$((CREATED_COUNT + 1))
  echo "OK ($REPORT_SIZE bytes)"
done

echo ""

# === PARTIAL SUCCESS MODE (>=50% threshold) ===
SUCCESS_PERCENT=$((CREATED_COUNT * 100 / EXPECTED_COUNT))
PARTIAL_SUCCESS="false"

if [ $CREATED_COUNT -eq 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Research agent failed to create any reports (0% success)" \
    "bash_block_2b" \
    "$(jq -n --argjson expected "$EXPECTED_COUNT" --argjson created 0 \
       '{expected_reports: $expected, created_reports: $created, success_percent: 0}')"

  echo "ERROR: HARD BARRIER FAILED - No reports created" >&2
  echo "This indicates the research agent did not execute correctly." >&2
  exit 1

elif [ $SUCCESS_PERCENT -lt 50 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Research partial success below threshold (<50%)" \
    "bash_block_2b" \
    "$(jq -n --argjson expected "$EXPECTED_COUNT" --argjson created "$CREATED_COUNT" \
             --argjson percent "$SUCCESS_PERCENT" \
       '{expected_reports: $expected, created_reports: $created, success_percent: $percent, threshold: 50}')"

  echo "ERROR: Partial success below threshold ($SUCCESS_PERCENT% < 50%)" >&2
  echo "Created $CREATED_COUNT of $EXPECTED_COUNT reports" >&2
  echo "Failed reports:" >&2
  for failed in "${FAILED_REPORTS[@]}"; do
    echo "  - $failed" >&2
  done
  exit 1

elif [ $CREATED_COUNT -lt $EXPECTED_COUNT ]; then
  PARTIAL_SUCCESS="true"
  echo "WARNING: Partial success - $CREATED_COUNT of $EXPECTED_COUNT reports ($SUCCESS_PERCENT%)"
  echo "Missing reports:"
  for failed in "${FAILED_REPORTS[@]}"; do
    echo "  - $failed"
  done
  echo ""
  echo "Continuing with available reports (>=50% threshold met)"
  echo ""
fi

# === SUCCESS OUTPUT ===
if [ "$PARTIAL_SUCCESS" = "true" ]; then
  echo "[OK] Partial validation passed: $CREATED_COUNT/$EXPECTED_COUNT reports ($TOTAL_SIZE bytes total)"
else
  echo "[OK] All reports validated: $CREATED_COUNT files ($TOTAL_SIZE bytes total)"
fi

# === PERSIST VALIDATION RESULTS ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1

append_workflow_state "CREATED_COUNT" "$CREATED_COUNT"
append_workflow_state "EXPECTED_COUNT" "$EXPECTED_COUNT"
append_workflow_state "SUCCESS_PERCENT" "$SUCCESS_PERCENT"
append_workflow_state "PARTIAL_SUCCESS" "$PARTIAL_SUCCESS"
append_workflow_state "TOTAL_SIZE" "$TOTAL_SIZE"

echo ""
echo "CHECKPOINT: Block 2 validation complete"
echo "  Reports: $CREATED_COUNT/$EXPECTED_COUNT"
echo "  Success: $SUCCESS_PERCENT%"
echo "  Ready for: completion (Block 3)"
```

## Block 3: Verification and Completion

**EXECUTE NOW**: Complete workflow and generate console summary:

```bash
# === PREPROCESSING SAFETY ===
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e

# === PRE-TRAP ERROR BUFFER ===
declare -a _EARLY_ERROR_BUFFER=()

# === DETECT PROJECT DIRECTORY ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

export CLAUDE_PROJECT_DIR

# === LOAD STATE ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
STATE_FILE=$(discover_latest_state_file "research")
[ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ] || exit 1
source "$STATE_FILE"  # WORKFLOW_ID restored

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: WORKFLOW_ID not found" >&2
  exit 1
fi

# === SOURCE LIBRARIES (Three-Tier Pattern) ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1

# Validate and load workflow state
WORKFLOW_ID=$(validate_workflow_id "$WORKFLOW_ID" "research")
export WORKFLOW_ID

load_workflow_state "$WORKFLOW_ID" false

# Validate critical variables
validate_state_restoration "COMMAND_NAME" "USER_ARGS" "RESEARCH_DIR" "CREATED_COUNT" || {
  echo "ERROR: State restoration failed - critical variables missing" >&2
  exit 1
}

# === SETUP ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
_flush_early_errors

# === COMPLETE WORKFLOW ===
sm_transition "$STATE_COMPLETE" 2>&1
SM_TRANSITION_EXIT=$?
if [ $SM_TRANSITION_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to COMPLETE failed" \
    "bash_block_3" \
    "$(jq -n --arg state "$STATE_COMPLETE" '{target_state: $state}')"
  echo "ERROR: State transition to COMPLETE failed" >&2
  exit 1
fi

save_completed_states_to_state
SAVE_EXIT=$?
if [ $SAVE_EXIT -ne 0 ]; then
  log_command_error "state_error" "Failed to persist state transitions" \
    "$(jq -n --arg file "${STATE_FILE:-unknown}" '{state_file: $file}')"
  echo "ERROR: State persistence failed" >&2
  exit 1
fi

# === CONSOLE SUMMARY ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/summary-formatting.sh" 2>/dev/null || {
  echo "ERROR: Failed to load summary-formatting library" >&2
  exit 1
}

# Build summary text based on partial/full success
if [ "$PARTIAL_SUCCESS" = "true" ]; then
  SUMMARY_TEXT="Researched ${CREATED_COUNT} of ${EXPECTED_COUNT} topics (${SUCCESS_PERCENT}% success). Some topics failed but threshold met. Review available reports for research findings."
else
  SUMMARY_TEXT="Analyzed codebase and created $CREATED_COUNT research report(s). Research provides foundation for creating implementation plan with evidence-based strategy selection."
fi

# Build topics section (if multi-topic)
TOPICS_SECTION=""
if [ "$USE_MULTI_TOPIC" = "true" ]; then
  IFS='|' read -ra TOPICS_ARRAY <<< "$TOPICS_LIST"
  for i in $(seq 0 $((${#TOPICS_ARRAY[@]} - 1))); do
    TOPIC="${TOPICS_ARRAY[$i]}"
    TOPICS_SECTION="${TOPICS_SECTION}  - Topic $((i+1)): ${TOPIC:0:50}
"
  done
fi

# Build artifacts section
ARTIFACTS="  Reports: $RESEARCH_DIR/ ($CREATED_COUNT files, $TOTAL_SIZE bytes)"

# Build next steps
NEXT_STEPS="  - Review reports: ls -lh $RESEARCH_DIR/
  - Create implementation plan: /create-plan \"${WORKFLOW_DESCRIPTION}\"
  - Run /todo to update TODO.md (adds research to tracking)"

# Print standardized summary
print_artifact_summary "Research" "$SUMMARY_TEXT" "$TOPICS_SECTION" "$ARTIFACTS" "$NEXT_STEPS"

# Emit completion reminder
echo ""
echo "Next Step: Run /todo to update TODO.md with this research"
echo ""

# === RETURN REPORT_CREATED SIGNAL ===
LATEST_REPORT=$(ls -t "$RESEARCH_DIR"/*.md 2>/dev/null | head -1)
if [ -n "$LATEST_REPORT" ] && [ -f "$LATEST_REPORT" ]; then
  echo ""
  echo "RESEARCH_COMPLETE: $CREATED_COUNT"
  echo "  report_dir: $RESEARCH_DIR"
  echo "  latest_report: $LATEST_REPORT"
  echo ""
fi

# === CLEANUP ===
# State files cleaned up by state-persistence library TTL mechanism

exit 0
```

---

**Architecture Summary**:

This optimized 3-block architecture achieves:
- **95% context reduction**: Coordinator passes metadata only (110 tokens per report vs 2,500)
- **66% state overhead reduction**: 3 blocks vs 9 blocks (165 lines vs 495 lines)
- **40-60% time savings**: Parallel research execution for multi-topic

**Block Responsibilities**:
1. **Block 1**: Complete setup - argument capture, state init, topic naming, decomposition, path pre-calculation
2. **Block 2**: Coordination - agent invocation (single or multi-topic), hard barrier validation, partial success handling
3. **Block 3**: Completion - state transition, console summary, cleanup

**Routing Logic**:
- **Complexity < 3**: Direct research-specialist invocation (single-topic, backward compatible)
- **Complexity >= 3**: research-coordinator invocation (multi-topic, parallel execution)

**Partial Success Mode**:
- **<50% success**: Exit 1 with error
- **>=50% success**: Continue with warning, report available findings
- **100% success**: Normal completion

**Troubleshooting**:

- **Research fails**: Check research-specialist/coordinator agent output for errors
- **No reports created**: Verify workflow description is clear and actionable
- **State machine errors**: Ensure library versions compatible (workflow-state-machine.sh >=2.0.0)
- **Partial success**: Review warning messages, check for transient failures
- **Path mismatch**: Ensure CLAUDE_PROJECT_DIR detection before STATE_FILE path construction
