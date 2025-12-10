---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
argument-hint: [plan-file] [starting-phase] [--mode=auto|lean-only|software-only] [--max-iterations=N]
description: Hybrid implementation command for mixed Lean/software plans with intelligent phase routing
command-type: primary
subcommands:
  - auto: "Automatically detect phase type and route to appropriate coordinator (default)"
  - lean-only: "Execute only Lean phases (theorem proving)"
  - software-only: "Execute only software phases (implementation)"
dependent-agents:
  - lean-coordinator
  - implementer-coordinator
library-requirements:
  - error-handling.sh: ">=1.0.0"
  - state-persistence.sh: ">=1.6.0"
  - workflow-state-machine.sh: ">=2.0.0"
documentation: See .claude/docs/guides/commands/lean-implement-command-guide.md for usage
---

# /lean-implement - Hybrid Lean/Software Implementation Command

YOU ARE EXECUTING a hybrid implementation workflow that intelligently routes plan phases to appropriate coordinators: lean-coordinator for theorem proving (Lean) phases and implementer-coordinator for software implementation phases.

**Workflow Type**: implement-only
**Expected Input**: Plan file with mixed Lean/software phases
**Expected Output**: Completed implementation with proofs and code

## Delegation Contract Validation

This section defines validation utilities for auditing primary agent tool usage after coordinator delegation returns. The hard barrier (exit 0 after iteration decision) prevents delegation contract violations during normal execution. This validation function provides defense-in-depth for testing and manual auditing.

### validate_delegation_contract()

Parses a workflow execution log and detects prohibited tool patterns that violate the delegation contract (primary agent performing implementation work instead of delegating to coordinators).

**Usage**:
```bash
validate_delegation_contract <workflow_log_file>
```

**Prohibited Tools** (primary agent must NOT use these after coordinator delegation):
- `Edit` - File editing (implementation work)
- `lean_goal` - Lean proof state inspection (theorem proving work)
- `lean_multi_attempt` - Lean proof attempts (theorem proving work)
- `lean-lsp` - Lean language server operations (theorem proving work)

**Allowed Tools** (orchestration and monitoring):
- `Bash` - Orchestration commands
- `Read` - Reading summary files for parsing
- `Grep` - Searching logs for validation
- `Task` - Delegating to subagents (expected behavior)

**Function Definition**:
```bash
validate_delegation_contract() {
  local workflow_log="$1"

  if [ ! -f "$workflow_log" ]; then
    echo "ERROR: Workflow log not found: $workflow_log" >&2
    return 1
  fi

  # Count prohibited tool usage (safe arithmetic with defaults)
  local edit_count=0
  local lean_goal_count=0
  local lean_attempt_count=0
  local lean_lsp_count=0

  edit_count=$(grep -c "^● Edit(" "$workflow_log" 2>/dev/null) || edit_count=0
  lean_goal_count=$(grep -c "^● lean_goal(" "$workflow_log" 2>/dev/null) || lean_goal_count=0
  lean_attempt_count=$(grep -c "^● lean_multi_attempt(" "$workflow_log" 2>/dev/null) || lean_attempt_count=0
  lean_lsp_count=$(grep -c "^● lean-lsp(" "$workflow_log" 2>/dev/null) || lean_lsp_count=0

  local total_violations=$((edit_count + lean_goal_count + lean_attempt_count + lean_lsp_count))

  if [ "$total_violations" -gt 0 ]; then
    echo "Delegation contract violation detected in workflow log" >&2
    echo "  Edit calls: $edit_count" >&2
    echo "  lean_goal calls: $lean_goal_count" >&2
    echo "  lean_multi_attempt calls: $lean_attempt_count" >&2
    echo "  lean-lsp calls: $lean_lsp_count" >&2
    echo "  Total violations: $total_violations" >&2

    # Return structured error data for logging
    local error_details
    error_details=$(jq -n \
      --argjson edit "$edit_count" \
      --argjson lean_goal "$lean_goal_count" \
      --argjson lean_attempt "$lean_attempt_count" \
      --argjson lean_lsp "$lean_lsp_count" \
      --argjson total "$total_violations" \
      '{
        edit_calls: $edit,
        lean_goal_calls: $lean_goal,
        lean_multi_attempt_calls: $lean_attempt,
        lean_lsp_calls: $lean_lsp,
        total_violations: $total
      }')

    echo "ERROR_DETAILS: $error_details" >&2
    return 1
  else
    echo "Delegation contract validated (no prohibited tool usage detected)" >&2
    return 0
  fi
}
```

**Note**: This validation function is currently used for testing and manual auditing. Automated workflow log capture for runtime validation is a future enhancement. The hard barrier enforcement (exit 0 after iteration decision) is the primary mechanism preventing delegation contract violations.

## Phase Classification

The command uses a 2-tier detection algorithm to classify each phase:

### Tier 1: Phase-Specific Metadata (Strongest Signal)
```markdown
### Phase 1: Prove Modal Axioms [NOT STARTED]
lean_file: /path/to/Modal.lean

Tasks:
- [ ] Prove theorem_K
```
If `lean_file:` metadata exists, phase is classified as "lean".

### Tier 2: Keyword and Extension Analysis
- **Lean indicators**: `.lean`, `theorem`, `lemma`, `sorry`, `tactic`, `mathlib`, `lean_`
- **Software indicators**: `.ts`, `.js`, `.py`, `.sh`, `.md`, `implement`, `create`, `write tests`

Default: "software" for ambiguous phases (conservative approach).

## Block 1a: Setup & Phase Classification

**EXECUTE NOW**: The user invoked `/lean-implement [plan-file] [starting-phase] [--mode=auto|lean-only|software-only] [--max-iterations=N]`. This block captures arguments, classifies phases, initializes workflow state, and prepares routing map.

In the **bash block below**, replace `YOUR_LEAN_IMPLEMENT_ARGS_HERE` with the actual arguments.

**Examples**:
- If user ran `/lean-implement plan.md`, change to: `echo "plan.md" > "$TEMP_FILE"`
- If user ran `/lean-implement plan.md 3 --mode=lean-only`, change to: `echo "plan.md 3 --mode=lean-only" > "$TEMP_FILE"`

```bash
# === PREPROCESSING SAFETY ===
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e  # Fail-fast

# === PRE-TRAP ERROR BUFFER ===
declare -a _EARLY_ERROR_BUFFER=()

# DEBUG_LOG initialization
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null

# === CAPTURE LEAN-IMPLEMENT ARGUMENTS ===
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/lean_implement_arg_$(date +%s%N).txt"
# SUBSTITUTE THE LEAN-IMPLEMENT ARGUMENTS IN THE LINE BELOW
echo "YOUR_LEAN_IMPLEMENT_ARGS_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/lean_implement_arg_path.txt"

# === READ AND PARSE ARGUMENTS ===
LEAN_IMPLEMENT_ARGS=$(cat "$TEMP_FILE" 2>/dev/null || echo "")

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

# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists

# === SETUP EARLY BASH ERROR TRAP ===
setup_bash_error_trap "/lean-implement" "lean_implement_early_$(date +%s)" "early_init"

# Flush any early errors
_flush_early_errors

# Tier 2: Workflow Support (graceful degradation)
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" || true
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh" || true
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || true

# Verify library versions
check_library_requirements "$(cat <<'EOF'
workflow-state-machine.sh: ">=2.0.0"
state-persistence.sh: ">=1.5.0"
EOF
)" || exit 1

# === PRE-FLIGHT VALIDATION ===
# Use validation-utils.sh library for workflow prerequisites validation
if ! validate_workflow_prerequisites; then
  echo "FATAL: Pre-flight validation failed - cannot proceed" >&2
  exit 1
fi

# Lean-specific graceful degradation: Check for lake command
if ! command -v lake &>/dev/null; then
  echo "WARNING: lake command not found - Lean theorem proving may be unavailable" >&2
  echo "  To enable Lean support, ensure lake is in PATH" >&2
fi

echo "Pre-flight validation passed"
echo ""

# === PARSE ARGUMENTS ===
read -ra ARGS_ARRAY <<< "$LEAN_IMPLEMENT_ARGS"
PLAN_FILE="${ARGS_ARRAY[0]:-}"
STARTING_PHASE="${ARGS_ARRAY[1]:-1}"
EXECUTION_MODE="auto"  # Default mode
MAX_ITERATIONS=5
CONTEXT_THRESHOLD=90
DRY_RUN="false"

for arg in "${ARGS_ARRAY[@]:1}"; do
  case "$arg" in
    --mode=*) EXECUTION_MODE="${arg#*=}" ;;
    --max-iterations=*) MAX_ITERATIONS="${arg#*=}" ;;
    --context-threshold=*) CONTEXT_THRESHOLD="${arg#*=}" ;;
    --dry-run) DRY_RUN="true" ;;
    [0-9]*) STARTING_PHASE="$arg" ;;
  esac
done

# Validate execution mode
case "$EXECUTION_MODE" in
  auto|lean-only|software-only) ;;
  *)
    echo "ERROR: Invalid mode: $EXECUTION_MODE (must be auto, lean-only, or software-only)" >&2
    exit 1
    ;;
esac

# Validate starting phase is numeric
echo "$STARTING_PHASE" | grep -Eq "^[0-9]+$"
PHASE_VALID=$?
if [ $PHASE_VALID -ne 0 ]; then
  echo "ERROR: Invalid starting phase: $STARTING_PHASE (must be numeric)" >&2
  exit 1
fi

echo "=== Hybrid Lean/Software Implementation Workflow ==="
echo ""

# === VALIDATE PLAN FILE ===
if [ -z "$PLAN_FILE" ]; then
  echo "ERROR: No plan file specified" >&2
  echo "  Usage: /lean-implement <plan-file> [starting-phase] [--mode=auto|lean-only|software-only]" >&2
  exit 1
fi

if [ ! -f "$PLAN_FILE" ]; then
  # Try relative to project directory
  if [ -f "$CLAUDE_PROJECT_DIR/$PLAN_FILE" ]; then
    PLAN_FILE="$CLAUDE_PROJECT_DIR/$PLAN_FILE"
  else
    echo "ERROR: Plan file not found: $PLAN_FILE" >&2
    exit 1
  fi
fi

# Convert to absolute path
PLAN_FILE="$(cd "$(dirname "$PLAN_FILE")" && pwd)/$(basename "$PLAN_FILE")"

echo "Plan File: $PLAN_FILE"

# === EXECUTION MODE INITIALIZATION ===
# Wave-based plan delegation: Pass entire plan to coordinator
# Coordinator analyzes dependencies and executes waves in parallel
# Note: Coordinators expect "plan-based" mode (not "full-plan")
EXECUTION_MODE="plan-based"

echo "Execution Mode: Plan-based delegation with wave-based orchestration"

# Optional: Starting phase override (for manual wave targeting)
# Default: Coordinator auto-detects lowest incomplete phase
if [ -n "${ARGS_ARRAY[1]:-}" ] && [[ "${ARGS_ARRAY[1]}" =~ ^[0-9]+$ ]]; then
  STARTING_PHASE="${ARGS_ARRAY[1]}"
  echo "Starting Phase Override: $STARTING_PHASE (manual specification)"
else
  echo "Starting Phase: Auto-detected by coordinator (lowest incomplete)"
  STARTING_PHASE=""  # Empty signals coordinator to auto-detect
fi

echo "Max Iterations: $MAX_ITERATIONS"
echo "Context Threshold: ${CONTEXT_THRESHOLD}%"
echo ""

# === CONTEXT BUDGET MONITORING (Optional) ===
# Track primary agent context usage for optimization validation
PRIMARY_CONTEXT_BUDGET=${LEAN_IMPLEMENT_CONTEXT_BUDGET:-5000}  # tokens
CURRENT_CONTEXT=0

track_context_usage() {
  local operation="$1"
  local estimated_tokens="$2"

  CURRENT_CONTEXT=$((CURRENT_CONTEXT + estimated_tokens))

  if [ "${LEAN_IMPLEMENT_CONTEXT_TRACKING:-false}" = "true" ]; then
    echo "Context: $operation (+$estimated_tokens tokens, total: $CURRENT_CONTEXT/$PRIMARY_CONTEXT_BUDGET)" >&2

    if [ "$CURRENT_CONTEXT" -gt "$PRIMARY_CONTEXT_BUDGET" ]; then
      echo "WARNING: Primary agent context budget exceeded ($CURRENT_CONTEXT/$PRIMARY_CONTEXT_BUDGET tokens)" >&2
    fi
  fi
}

# === DRY-RUN MODE ===
if [ "$DRY_RUN" = "true" ]; then
  echo "=== DRY-RUN MODE: Preview Only ==="
  echo "Plan: $(basename "$PLAN_FILE")"
  echo "Starting Phase: $STARTING_PHASE"
  echo "Mode: $EXECUTION_MODE"
  echo ""
  echo "Classification preview will be shown in Block 1a-classify"
  exit 0
fi

# === INITIALIZE WORKFLOW STATE ===
WORKFLOW_TYPE="implement-only"
COMMAND_NAME="/lean-implement"
USER_ARGS="$PLAN_FILE"

# Generate unique WORKFLOW_ID with nanosecond precision (concurrent-safe)
WORKFLOW_ID="lean_implement_$(date +%s%N)"

export WORKFLOW_ID COMMAND_NAME USER_ARGS

# Update bash error trap with actual values
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
    "bash_block_1a" \
    "$(jq -n --arg path "${STATE_FILE:-UNDEFINED}" '{expected_path: $path}')"
  echo "ERROR: Failed to initialize workflow state" >&2
  exit 1
fi

# Initialize state machine
sm_init "$PLAN_FILE" "$COMMAND_NAME" "$WORKFLOW_TYPE" "1" "[]" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State machine initialization failed" \
    "bash_block_1a" \
    "$(jq -n --arg type "$WORKFLOW_TYPE" --arg plan "$PLAN_FILE" \
       '{workflow_type: $type, plan_file: $plan}')"
  echo "ERROR: State machine initialization failed" >&2
  exit 1
fi

# Transition to implement state
sm_transition "$STATE_IMPLEMENT" "plan loaded, starting hybrid implementation" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "State transition to IMPLEMENT failed" \
    "bash_block_1a" \
    "$(jq -n --arg state "IMPLEMENT" '{target_state: $state}')"
  echo "ERROR: State transition to IMPLEMENT failed" >&2
  exit 1
fi

# === PRE-CALCULATE ALL ARTIFACT PATHS (Hard Barrier Pattern) ===
# Calculate all artifact paths BEFORE coordinator invocation
# This ensures consistent paths across all coordinators and enables hard barrier validation

TOPIC_PATH=$(dirname "$(dirname "$PLAN_FILE")")

# Artifact directories for coordinator input contract
SUMMARIES_DIR="${TOPIC_PATH}/summaries"
DEBUG_DIR="${TOPIC_PATH}/debug"
OUTPUTS_DIR="${TOPIC_PATH}/outputs"
CHECKPOINTS_DIR="${HOME}/.claude/data/checkpoints"

# Validate all paths are absolute
for PATH_VAR in "$SUMMARIES_DIR" "$DEBUG_DIR" "$OUTPUTS_DIR" "$CHECKPOINTS_DIR"; do
  if [[ ! "$PATH_VAR" =~ ^/ ]]; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Artifact path is not absolute: $PATH_VAR" \
      "bash_block_1a" \
      "$(jq -n --arg path "$PATH_VAR" '{invalid_path: $path}')"
    echo "ERROR: All artifact paths must be absolute (Hard Barrier Pattern)" >&2
    exit 1
  fi
done

# Create artifact directories (lazy creation pattern)
mkdir -p "$SUMMARIES_DIR" "$DEBUG_DIR" "$OUTPUTS_DIR" "$CHECKPOINTS_DIR" 2>/dev/null

# === MARK PLAN IN PROGRESS ===
# Note: Individual phase marking delegated to coordinator (wave-based execution)
if type add_not_started_markers &>/dev/null; then
  if grep -qE "^### Phase [0-9]+:" "$PLAN_FILE" && ! grep -qE "^### Phase [0-9]+:.*\[(NOT STARTED|IN PROGRESS|COMPLETE|BLOCKED|SKIPPED)\]" "$PLAN_FILE"; then
    echo "Legacy plan detected, adding [NOT STARTED] markers..."
    add_not_started_markers "$PLAN_FILE" 2>/dev/null || true
  fi
fi

if type update_plan_status &>/dev/null; then
  if update_plan_status "$PLAN_FILE" "IN PROGRESS" 2>/dev/null; then
    echo "Plan metadata status updated to [IN PROGRESS]"
  fi
fi
echo ""

# === ITERATION LOOP VARIABLES ===
ITERATION=1
CONTINUATION_CONTEXT=""
LAST_WORK_REMAINING=""
STUCK_COUNT=0
LEAN_ITERATION=1
SOFTWARE_ITERATION=1

# Create workspace directory
LEAN_IMPLEMENT_WORKSPACE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_implement_${WORKFLOW_ID}"
mkdir -p "$LEAN_IMPLEMENT_WORKSPACE"

# === PERSIST STATE FOR NEXT BLOCK ===
append_workflow_state "COMMAND_NAME" "${COMMAND_NAME:-}"
append_workflow_state "USER_ARGS" "${USER_ARGS:-}"
append_workflow_state "WORKFLOW_ID" "${WORKFLOW_ID:-}"
append_workflow_state "CLAUDE_PROJECT_DIR" "${CLAUDE_PROJECT_DIR:-}"
append_workflow_state "PLAN_FILE" "${PLAN_FILE:-}"
append_workflow_state "TOPIC_PATH" "${TOPIC_PATH:-}"
append_workflow_state "SUMMARIES_DIR" "${SUMMARIES_DIR:-}"
append_workflow_state "DEBUG_DIR" "${DEBUG_DIR:-}"
append_workflow_state "OUTPUTS_DIR" "${OUTPUTS_DIR:-}"
append_workflow_state "CHECKPOINTS_DIR" "${CHECKPOINTS_DIR:-}"
append_workflow_state "STARTING_PHASE" "${STARTING_PHASE:-}"
append_workflow_state "EXECUTION_MODE" "${EXECUTION_MODE:-}"
append_workflow_state "MAX_ITERATIONS" "${MAX_ITERATIONS:-}"
append_workflow_state "CONTEXT_THRESHOLD" "${CONTEXT_THRESHOLD:-}"
append_workflow_state "ITERATION" "${ITERATION:-}"
append_workflow_state "LEAN_ITERATION" "${LEAN_ITERATION:-}"
append_workflow_state "SOFTWARE_ITERATION" "${SOFTWARE_ITERATION:-}"
append_workflow_state "CONTINUATION_CONTEXT" "${CONTINUATION_CONTEXT:-}"
append_workflow_state "LAST_WORK_REMAINING" "${LAST_WORK_REMAINING:-}"
append_workflow_state "STUCK_COUNT" "${STUCK_COUNT:-}"
append_workflow_state "LEAN_IMPLEMENT_WORKSPACE" "${LEAN_IMPLEMENT_WORKSPACE:-}"

echo "CHECKPOINT: Setup complete"
echo "- State transition: IMPLEMENT [OK]"
echo "- Plan file: $PLAN_FILE"
echo "- Topic path: $TOPIC_PATH"
echo "- Iteration: ${ITERATION}/${MAX_ITERATIONS}"
echo "- Ready for: Phase classification (Block 1a-classify)"
echo ""
```

## Block 1a-classify: Phase Classification and Routing Map Construction

**EXECUTE NOW**: Classify each phase as "lean" or "software" and build routing map.

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e

# === DETECT PROJECT DIRECTORY ===
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
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
fi

# === SOURCE LIBRARIES ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1

# === RESTORE STATE ===
# Discover latest state file
STATE_FILE=$(discover_latest_state_file "lean_implement")
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to discover state file from previous block" >&2
  exit 1
fi

# Restore state from discovered file
source "$STATE_FILE"
COMMAND_NAME="${COMMAND_NAME:-/lean-implement}"
USER_ARGS="${USER_ARGS:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

echo "=== Phase Classification ==="
echo ""

# === PHASE TYPE DETECTION FUNCTION ===
# 2-tier classification algorithm with implementer: field support
detect_phase_type() {
  local phase_content="$1"
  local phase_num="$2"

  # Tier 1: Check for explicit implementer: field (strongest signal)
  local implementer_value=$(echo "$phase_content" | grep -E "^implementer:" | sed 's/^implementer:[[:space:]]*//' | head -1)
  if [ -n "$implementer_value" ]; then
    case "$implementer_value" in
      lean)
        echo "lean"
        return 0
        ;;
      software)
        echo "software"
        return 0
        ;;
      *)
        echo "WARNING: Invalid implementer value '$implementer_value' in phase $phase_num, defaulting to software" >&2
        echo "software"
        return 0
        ;;
    esac
  fi

  # Tier 2: Check for lean_file metadata (backward compatibility)
  if echo "$phase_content" | grep -qE "^lean_file:"; then
    echo "lean"
    return 0
  fi

  # Tier 3: Keyword and extension analysis (legacy fallback)
  # Check software indicators BEFORE .lean extension to prevent false positives
  # (e.g., "Update Perpetuity.lean documentation" should classify as software)
  if echo "$phase_content" | grep -qE '\.(ts|js|py|sh|md|json|yaml|toml)\b'; then
    echo "software"
    return 0
  fi

  if echo "$phase_content" | grep -qiE 'implement\b|create\b|write tests\b|setup\b|configure\b|deploy\b|build\b'; then
    echo "software"
    return 0
  fi

  # Lean indicators: Require proof-related context with .lean extension
  # This prevents documentation tasks from being misclassified as Lean phases
  if echo "$phase_content" | grep -qE '\.(lean)\b'; then
    # Check if phase has proof-related keywords
    if echo "$phase_content" | grep -qiE 'theorem\b|lemma\b|proof\b|sorry\b|tactic\b'; then
      echo "lean"
      return 0
    fi
  fi

  # Pure Lean indicators without file extension
  if echo "$phase_content" | grep -qiE 'mathlib\b|lean_(goal|build|leansearch)'; then
    echo "lean"
    return 0
  fi

  # Default: software (conservative)
  echo "software"
}

# === EXTRACT PHASES FROM PLAN ===
TOTAL_PHASES=$(grep -c "^### Phase [0-9]" "$PLAN_FILE" 2>/dev/null || echo "0")

if [ "$TOTAL_PHASES" -eq 0 ]; then
  echo "ERROR: No phases found in plan file" >&2
  exit 1
fi

echo "Total phases found: $TOTAL_PHASES"
echo ""

# === CLASSIFY EACH PHASE ===
# Build routing map as newline-separated entries: phase_num:type:lean_file
ROUTING_MAP=""
LEAN_PHASES=""
SOFTWARE_PHASES=""
LEAN_COUNT=0
SOFTWARE_COUNT=0

# Extract actual phase numbers from plan (handles non-contiguous phase numbers)
PHASE_NUMBERS=$(grep -oE "^### Phase ([0-9]+):" "$PLAN_FILE" | grep -oE "[0-9]+" | sort -n)

for phase_num in $PHASE_NUMBERS; do
  # Extract phase content (from phase heading to next phase or EOF)
  PHASE_CONTENT=$(awk -v target="$phase_num" '
    BEGIN { in_phase=0; found=0 }
    /^### Phase / {
      if (found) exit
      if (index($0, "Phase " target ":") > 0) {
        in_phase=1
        found=1
        print
        next
      }
    }
    in_phase { print }
  ' "$PLAN_FILE")

  # Check if phase should be skipped based on mode
  if [ -z "$PHASE_CONTENT" ]; then
    echo "  Phase $phase_num: [SKIPPED - no content]"
    continue
  fi

  # Classify phase
  PHASE_TYPE=$(detect_phase_type "$PHASE_CONTENT" "$phase_num")

  # Extract lean_file if present
  LEAN_FILE_PATH=""
  if [ "$PHASE_TYPE" = "lean" ]; then
    LEAN_FILE_PATH=$(echo "$PHASE_CONTENT" | grep -E "^lean_file:" | sed 's/^lean_file:[[:space:]]*//' | head -1)
  fi

  # Determine implementer name for routing map
  if [ "$PHASE_TYPE" = "lean" ]; then
    IMPLEMENTER_NAME="lean-coordinator"
  else
    IMPLEMENTER_NAME="implementer-coordinator"
  fi

  # Apply mode filter
  case "$EXECUTION_MODE" in
    lean-only)
      if [ "$PHASE_TYPE" != "lean" ]; then
        echo "  Phase $phase_num: $PHASE_TYPE [SKIPPED - lean-only mode]"
        continue
      fi
      ;;
    software-only)
      if [ "$PHASE_TYPE" = "lean" ]; then
        echo "  Phase $phase_num: $PHASE_TYPE [SKIPPED - software-only mode]"
        continue
      fi
      ;;
  esac

  # Add to routing map (enhanced format: phase_num:type:lean_file:implementer)
  if [ -n "$ROUTING_MAP" ]; then
    ROUTING_MAP="${ROUTING_MAP}
"
  fi
  ROUTING_MAP="${ROUTING_MAP}${phase_num}:${PHASE_TYPE}:${LEAN_FILE_PATH:-none}:${IMPLEMENTER_NAME}"

  if [ "$PHASE_TYPE" = "lean" ]; then
    LEAN_PHASES="${LEAN_PHASES}${phase_num} "
    LEAN_COUNT=$((LEAN_COUNT + 1))
    echo "  Phase $phase_num: LEAN (file: ${LEAN_FILE_PATH:-auto-detect})"
  else
    SOFTWARE_PHASES="${SOFTWARE_PHASES}${phase_num} "
    SOFTWARE_COUNT=$((SOFTWARE_COUNT + 1))
    echo "  Phase $phase_num: SOFTWARE"
  fi
done

echo ""
echo "Classification Summary:"
echo "  Lean phases ($LEAN_COUNT): ${LEAN_PHASES:-none}"
echo "  Software phases ($SOFTWARE_COUNT): ${SOFTWARE_PHASES:-none}"
echo ""

# Validate at least one phase to execute
if [ "$LEAN_COUNT" -eq 0 ] && [ "$SOFTWARE_COUNT" -eq 0 ]; then
  echo "ERROR: No phases to execute after mode filtering" >&2
  exit 1
fi

# === PERSIST ROUTING MAP ===
# Store routing map in workspace file (newline-separated is safer than shell variables)
echo "$ROUTING_MAP" > "${LEAN_IMPLEMENT_WORKSPACE}/routing_map.txt"

append_workflow_state "TOTAL_PHASES" "${TOTAL_PHASES:-}"
append_workflow_state "LEAN_PHASES" "${LEAN_PHASES% }"
append_workflow_state "SOFTWARE_PHASES" "${SOFTWARE_PHASES% }"
append_workflow_state "LEAN_COUNT" "${LEAN_COUNT:-}"
append_workflow_state "SOFTWARE_COUNT" "${SOFTWARE_COUNT:-}"

echo "CHECKPOINT: Phase classification complete"
echo "- Routing map saved: ${LEAN_IMPLEMENT_WORKSPACE}/routing_map.txt"
echo "- Ready for: Coordinator routing (Block 1b)"
echo ""
```

## Block 1b: Route to Coordinator [HARD BARRIER]

**EXECUTE NOW**: Determine current phase type and invoke appropriate coordinator via Task tool.

This block reads the routing map, determines the next phase to execute, and invokes either lean-coordinator or implementer-coordinator.

**Routing Decision**:
1. Read current phase from routing map
2. If phase type is "lean": Invoke lean-coordinator
3. If phase type is "software": Invoke implementer-coordinator
4. Pass shared context (topic_path, continuation_context, iteration) to coordinator

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e

# === DETECT PROJECT DIRECTORY ===
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
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
fi

# === SOURCE LIBRARIES ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1

# === RESTORE STATE ===
# Discover latest state file
STATE_FILE=$(discover_latest_state_file "lean_implement")
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to discover state file from previous block" >&2
  exit 1
fi

# Restore state from discovered file
source "$STATE_FILE"
COMMAND_NAME="${COMMAND_NAME:-/lean-implement}"
USER_ARGS="${USER_ARGS:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

echo "=== Coordinator Routing (Iteration ${ITERATION}/${MAX_ITERATIONS}) ==="
echo ""

# === READ ROUTING MAP ===
ROUTING_MAP_FILE="${LEAN_IMPLEMENT_WORKSPACE}/routing_map.txt"
if [ ! -f "$ROUTING_MAP_FILE" ]; then
  echo "ERROR: Routing map not found: $ROUTING_MAP_FILE" >&2
  exit 1
fi

ROUTING_MAP=$(cat "$ROUTING_MAP_FILE")

# === DETERMINE PLAN TYPE FROM ROUTING MAP ===
# Classify the entire plan based on phase type distribution
# If all phases are Lean → use lean-coordinator only
# If all phases are software → use implementer-coordinator only
# If mixed → currently unsupported (would require dual coordinator orchestration)

LEAN_PHASE_COUNT=$(grep -c ":lean:" "$ROUTING_MAP_FILE" || echo "0")
SOFTWARE_PHASE_COUNT=$(grep -c ":software:" "$ROUTING_MAP_FILE" || echo "0")
TOTAL_PHASE_COUNT=$(wc -l < "$ROUTING_MAP_FILE")

echo "Plan classification:"
echo "  Lean phases: $LEAN_PHASE_COUNT"
echo "  Software phases: $SOFTWARE_PHASE_COUNT"
echo "  Total phases: $TOTAL_PHASE_COUNT"
echo ""

# Determine plan type
if [ "$LEAN_PHASE_COUNT" -gt 0 ] && [ "$SOFTWARE_PHASE_COUNT" -eq 0 ]; then
  PLAN_TYPE="lean"
  echo "Plan type: Pure Lean (all phases are theorem proving)"
elif [ "$SOFTWARE_PHASE_COUNT" -gt 0 ] && [ "$LEAN_PHASE_COUNT" -eq 0 ]; then
  PLAN_TYPE="software"
  echo "Plan type: Pure Software (all phases are implementation)"
else
  PLAN_TYPE="hybrid"
  echo "Plan type: Hybrid (mixed Lean and software phases)"
  echo "WARNING: Hybrid plans currently delegate to first phase type"
  echo "  Lean phases: Using lean-coordinator"
  echo "  Software phases: Using implementer-coordinator"
  # Default to Lean if mixed
  if [ "$LEAN_PHASE_COUNT" -ge "$SOFTWARE_PHASE_COUNT" ]; then
    PLAN_TYPE="lean"
  else
    PLAN_TYPE="software"
  fi
fi
echo ""

# Persist plan type for continuation
append_workflow_state "PLAN_TYPE" "${PLAN_TYPE:-}"

# === DETERMINE COORDINATOR NAME AND BUILD PROMPT [HARD BARRIER] ===
# Based on plan type, determine which coordinator to invoke for FULL PLAN execution
if [ "$PLAN_TYPE" = "lean" ]; then
  COORDINATOR_NAME="lean-coordinator"
  COORDINATOR_AGENT="${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md"
  COORDINATOR_DESCRIPTION="Wave-based full plan theorem proving orchestration"

  # Extract primary lean file from first lean phase (if any)
  FIRST_LEAN_ENTRY=$(grep ":lean:" "$ROUTING_MAP_FILE" | head -1)
  PRIMARY_LEAN_FILE=$(echo "$FIRST_LEAN_ENTRY" | cut -d: -f3)
  if [ "$PRIMARY_LEAN_FILE" = "none" ] || [ -z "$PRIMARY_LEAN_FILE" ]; then
    PRIMARY_LEAN_FILE="${TOPIC_PATH}/Theorems.lean"  # Fallback
  fi

  # Build lean-coordinator plan-based prompt
  COORDINATOR_PROMPT="Read and follow ALL behavioral guidelines from:
    ${COORDINATOR_AGENT}

    **Input Contract (Hard Barrier Pattern)**:
    - plan_path: ${PLAN_FILE}
    - lean_file_path: ${PRIMARY_LEAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - execution_mode: plan-based
    - routing_map_path: ${ROUTING_MAP_FILE}
    - artifact_paths:
      - plans: ${TOPIC_PATH}/plans/
      - summaries: ${SUMMARIES_DIR}
      - outputs: ${OUTPUTS_DIR}
      - debug: ${DEBUG_DIR}
      - checkpoints: ${CHECKPOINTS_DIR}
    - iteration: ${ITERATION}
    - max_iterations: ${MAX_ITERATIONS}
    - context_threshold: ${CONTEXT_THRESHOLD}
    - continuation_context: ${CONTINUATION_CONTEXT:-null}

    **Progress Tracking Instructions** (plan-based mode only):
    - Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
    - Before proving each theorem phase: add_in_progress_marker '${PLAN_FILE}' <phase_num>
    - After completing each theorem proof: mark_phase_complete '${PLAN_FILE}' <phase_num> && add_complete_marker '${PLAN_FILE}' <phase_num>
    - This creates visible progress: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]
    - Note: Progress tracking gracefully degrades if unavailable (non-fatal)
    - File-based mode: Skip progress tracking (phase_num = 0)

    **Workflow Instructions**:
    1. Analyze plan dependencies via dependency-analyzer.sh
    2. Calculate wave structure with parallelization metrics
    3. Execute waves sequentially with parallel lean-implementer invocations per wave
    4. Wait for ALL implementers in Wave N before starting Wave N+1 (hard barrier)
    5. Aggregate results and return ORCHESTRATION_COMPLETE signal

    **Expected Output Signal**:
    - summary_brief: 80-token summary for context efficiency
    - waves_completed: Number of waves finished
    - total_waves: Total waves in plan
    - phases_completed: List of phase numbers completed
    - work_remaining: List of phase numbers still incomplete
    - context_usage_percent: Estimated context usage (0-100)
    - requires_continuation: Boolean indicating if more work remains
    - parallelization_metrics: Time savings percentage, parallel phases count

    **CRITICAL**: Create wave execution summary in ${SUMMARIES_DIR}/
    The orchestrator will validate the summary exists after you return."
else
  COORDINATOR_NAME="implementer-coordinator"
  COORDINATOR_AGENT="${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md"
  COORDINATOR_DESCRIPTION="Wave-based full plan software implementation orchestration"

  # Build implementer-coordinator plan-based prompt
  COORDINATOR_PROMPT="Read and follow ALL behavioral guidelines from:
    ${COORDINATOR_AGENT}

    **Input Contract (Hard Barrier Pattern)**:
    - plan_path: ${PLAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - summaries_dir: ${SUMMARIES_DIR}
    - execution_mode: plan-based
    - routing_map_path: ${ROUTING_MAP_FILE}
    - artifact_paths:
      - reports: ${TOPIC_PATH}/reports/
      - plans: ${TOPIC_PATH}/plans/
      - summaries: ${SUMMARIES_DIR}
      - debug: ${DEBUG_DIR}
      - outputs: ${OUTPUTS_DIR}
      - checkpoints: ${CHECKPOINTS_DIR}
    - iteration: ${ITERATION}
    - max_iterations: ${MAX_ITERATIONS}
    - context_threshold: ${CONTEXT_THRESHOLD}
    - continuation_context: ${CONTINUATION_CONTEXT:-null}

    **Workflow Instructions**:
    1. Analyze plan dependencies via dependency-analyzer.sh
    2. Calculate wave structure with parallelization metrics
    3. Execute waves sequentially with parallel implementer invocations per wave
    4. Wait for ALL implementers in Wave N before starting Wave N+1 (hard barrier)
    5. Aggregate results and return ORCHESTRATION_COMPLETE signal

    **Expected Output Signal**:
    - summary_brief: 80-token summary for context efficiency
    - waves_completed: Number of waves finished
    - total_waves: Total waves in plan
    - phases_completed: List of phase numbers completed
    - work_remaining: List of phase numbers still incomplete
    - context_usage_percent: Estimated context usage (0-100)
    - requires_continuation: Boolean indicating if more work remains
    - parallelization_metrics: Time savings percentage, parallel phases count

    **CRITICAL**: Create wave execution summary in ${SUMMARIES_DIR}/
    The orchestrator will validate the summary exists after you return."
fi

# Persist coordinator name for verification in Block 1c
append_workflow_state "COORDINATOR_NAME" "${COORDINATOR_NAME:-}"

echo "Routing to ${COORDINATOR_NAME}..."
echo ""
```

**EXECUTE NOW**: USE the Task tool to invoke the selected coordinator.

**HARD BARRIER**: Coordinator delegation is MANDATORY (no conditionals, no bypass).
The orchestrator MUST NOT perform implementation work directly.

You MUST use the Task tool with these EXACT parameters:

- **subagent_type**: "general-purpose"
- **model**: "opus-4.5"
- **description**: "${COORDINATOR_DESCRIPTION}"
- **prompt**: "${COORDINATOR_PROMPT}"

The coordinator MUST create a summary file in ${SUMMARIES_DIR}.
The orchestrator will validate the summary exists after you return.

## Block 1c: Verification & Continuation Decision

**EXECUTE NOW**: Verify coordinator created summary, parse output, determine continuation.

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e

# === DETECT PROJECT DIRECTORY ===
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
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
fi

# === SOURCE LIBRARIES ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1

ensure_error_log_exists

# === RESTORE STATE ===
# Discover latest state file
STATE_FILE=$(discover_latest_state_file "lean_implement")
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to discover state file from previous block" >&2
  exit 1
fi

# Restore state from discovered file
source "$STATE_FILE"
COMMAND_NAME="${COMMAND_NAME:-/lean-implement}"
USER_ARGS="${USER_ARGS:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

echo ""
echo "=== Hard Barrier Verification ==="
echo ""

# === VALIDATE SUMMARY EXISTENCE [HARD BARRIER] ===
LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -mmin -10 2>/dev/null | sort | tail -1)

if [ -z "$LATEST_SUMMARY" ] || [ ! -f "$LATEST_SUMMARY" ]; then
  # Enhanced diagnostics: Search alternate locations
  echo "ERROR: HARD BARRIER FAILED - Summary not created by $COORDINATOR_NAME" >&2
  echo "Expected: Summary file in $SUMMARIES_DIR" >&2
  echo "" >&2
  echo "Alternate location search:" >&2

  # Check topic path root
  ALTERNATE_SUMMARIES=$(find "$TOPIC_PATH" -name "*.md" -type f -mmin -10 2>/dev/null | grep -v "/plans/" | grep -v "/reports/" | head -5)
  if [ -n "$ALTERNATE_SUMMARIES" ]; then
    echo "  Found recent .md files in topic path:" >&2
    echo "$ALTERNATE_SUMMARIES" | sed 's/^/    /' >&2
  else
    echo "  No recent .md files found in topic path" >&2
  fi
  echo "" >&2

  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Coordinator $COORDINATOR_NAME did not create summary file" \
    "bash_block_1c" \
    "$(jq -n --arg coord "$COORDINATOR_NAME" --arg dir "$SUMMARIES_DIR" \
       '{coordinator: $coord, summaries_dir: $dir}')"

  exit 1
fi

SUMMARY_SIZE=$(wc -c < "$LATEST_SUMMARY" 2>/dev/null || echo "0")
if [ "$SUMMARY_SIZE" -lt 100 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Summary file from $COORDINATOR_NAME too small" \
    "bash_block_1c" \
    "$(jq -n --arg coord "$COORDINATOR_NAME" --arg path "$LATEST_SUMMARY" --argjson size "$SUMMARY_SIZE" \
       '{coordinator: $coord, summary_path: $path, size_bytes: $size}')"

  echo "ERROR: HARD BARRIER FAILED - Summary file from $COORDINATOR_NAME too small ($SUMMARY_SIZE bytes)" >&2
  exit 1
fi

echo "[OK] Summary validated: $LATEST_SUMMARY ($SUMMARY_SIZE bytes)"
echo ""

# === PARSE ERROR SIGNALS FROM COORDINATOR ===
# Check if coordinator returned a TASK_ERROR signal in summary
if grep -q "^TASK_ERROR:" "$LATEST_SUMMARY" 2>/dev/null; then
  COORDINATOR_ERROR=$(grep "^TASK_ERROR:" "$LATEST_SUMMARY" | head -1 | sed 's/^TASK_ERROR:[[:space:]]*//')

  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Coordinator failed: $COORDINATOR_ERROR" \
    "bash_block_1c" \
    "$(jq -n --arg coord "$COORDINATOR_NAME" --arg phase "$CURRENT_PHASE" --arg error "$COORDINATOR_ERROR" \
       '{coordinator: $coord, phase: $phase, error_detail: $error}')"

  echo "ERROR: Coordinator $COORDINATOR_NAME failed: $COORDINATOR_ERROR" >&2
  exit 1
fi

# === PARSE COORDINATOR OUTPUT ===
# Brief Summary Pattern: Parse from return signal (stdout) for 96% context reduction
# Fallback to file parsing for backward compatibility with legacy coordinators
WORK_REMAINING_NEW=""
CONTEXT_EXHAUSTED="false"
REQUIRES_CONTINUATION="false"
CONTEXT_USAGE_PERCENT=0
COORDINATOR_TYPE=""
SUMMARY_BRIEF=""
PHASES_COMPLETED=""

# Note: In the current implementation, coordinator output is captured via Task tool
# and return signal fields are embedded in the summary file for simplicity.
# This parsing strategy prioritizes the return signal fields at the top of the file.

if [ -f "$LATEST_SUMMARY" ]; then
  # Parse coordinator_type (identifies coordinator: lean vs software)
  COORDINATOR_TYPE_LINE=$(grep -E "^coordinator_type:" "$LATEST_SUMMARY" | head -1)
  if [ -n "$COORDINATOR_TYPE_LINE" ]; then
    COORDINATOR_TYPE=$(echo "$COORDINATOR_TYPE_LINE" | sed 's/^coordinator_type:[[:space:]]*//' | tr -d ' ')
  fi

  # Parse summary_brief (context-efficient: 80 tokens vs 2,000 tokens full file)
  SUMMARY_BRIEF_LINE=$(grep -E "^summary_brief:" "$LATEST_SUMMARY" | head -1)
  if [ -n "$SUMMARY_BRIEF_LINE" ]; then
    SUMMARY_BRIEF=$(echo "$SUMMARY_BRIEF_LINE" | sed 's/^summary_brief:[[:space:]]*//' | tr -d '"')
  else
    # Fallback to file parsing when summary_brief field is missing (legacy coordinators)
    echo "WARNING: Coordinator output missing summary_brief field, falling back to file parsing" >&2
    SUMMARY_BRIEF=$(head -10 "$LATEST_SUMMARY" | grep "^\*\*Brief\*\*:" | sed 's/^\*\*Brief\*\*:[[:space:]]*//' | head -1)
  fi

  # Parse phases_completed (for progress tracking)
  PHASES_COMPLETED_LINE=$(grep -E "^phases_completed:" "$LATEST_SUMMARY" | head -1)
  if [ -n "$PHASES_COMPLETED_LINE" ]; then
    PHASES_COMPLETED=$(echo "$PHASES_COMPLETED_LINE" | sed 's/^phases_completed:[[:space:]]*//' | tr -d '[],"')
  fi

  # Parse work_remaining with defensive JSON array handling
  WORK_REMAINING_LINE=$(grep -E "^work_remaining:" "$LATEST_SUMMARY" | head -1)
  if [ -n "$WORK_REMAINING_LINE" ]; then
    WORK_REMAINING_NEW=$(echo "$WORK_REMAINING_LINE" | sed 's/^work_remaining:[[:space:]]*//')

    # Defensive parsing: Detect and convert JSON array format to space-separated string
    if [[ "$WORK_REMAINING_NEW" =~ ^[[:space:]]*\[ ]]; then
      echo "INFO: Converting work_remaining from JSON array to space-separated string" >&2
      # Strip brackets, remove commas, normalize whitespace
      WORK_REMAINING_NEW=$(echo "$WORK_REMAINING_NEW" | tr -d '[],"' | tr -s ' ')
    fi

    if [ "$WORK_REMAINING_NEW" = "0" ] || [ -z "$WORK_REMAINING_NEW" ]; then
      WORK_REMAINING_NEW=""
    fi
  fi

  # Parse context_exhausted
  CONTEXT_EXHAUSTED_LINE=$(grep -E "^context_exhausted:" "$LATEST_SUMMARY" | head -1)
  if [ -n "$CONTEXT_EXHAUSTED_LINE" ]; then
    CONTEXT_EXHAUSTED=$(echo "$CONTEXT_EXHAUSTED_LINE" | sed 's/^context_exhausted:[[:space:]]*//')
  fi

  # Parse requires_continuation
  REQUIRES_CONTINUATION_LINE=$(grep -E "^requires_continuation:" "$LATEST_SUMMARY" | head -1)
  if [ -n "$REQUIRES_CONTINUATION_LINE" ]; then
    REQUIRES_CONTINUATION=$(echo "$REQUIRES_CONTINUATION_LINE" | sed 's/^requires_continuation:[[:space:]]*//')
  fi

  # Parse context_usage_percent
  CONTEXT_USAGE_LINE=$(grep -E "^context_usage_percent:" "$LATEST_SUMMARY" | head -1)
  if [ -n "$CONTEXT_USAGE_LINE" ]; then
    CONTEXT_USAGE_PERCENT=$(echo "$CONTEXT_USAGE_LINE" | sed 's/^context_usage_percent:[[:space:]]*//' | sed 's/%//')
  fi
fi

# Display brief summary (no full file read required)
echo "Coordinator: ${COORDINATOR_TYPE:-unknown}"
if [ -n "$SUMMARY_BRIEF" ]; then
  echo "Summary: $SUMMARY_BRIEF"
else
  echo "Summary: No brief summary provided (legacy format)"
fi
echo "Phases completed: ${PHASES_COMPLETED:-none}"
echo "Context usage: ${CONTEXT_USAGE_PERCENT}%"
echo "Work remaining: ${WORK_REMAINING_NEW:-none}"
echo "Requires continuation: $REQUIRES_CONTINUATION"
echo "Full report: $LATEST_SUMMARY"
echo ""

# Context reduction metric: 80 tokens parsed (return signal) vs 2,000 tokens read (full file) = 96% reduction

# Track context usage for summary parsing (optional monitoring)
track_context_usage "summary_parse_brief" 80

# === VALIDATE DELEGATION CONTRACT ===
# Primary agent MUST NOT perform implementation work after coordinator delegation
# This validation provides defense-in-depth (hard barrier exit is primary enforcement)

WORKFLOW_LOG="${CLAUDE_PROJECT_DIR}/.claude/output/lean-implement-output.md"

if [ -f "$WORKFLOW_LOG" ] && [ "${SKIP_DELEGATION_VALIDATION:-false}" != "true" ]; then
  echo "Validating delegation contract..."

  if ! validate_delegation_contract "$WORKFLOW_LOG"; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "delegation_error" \
      "Primary agent performed implementation work (delegation contract violation)" \
      "bash_block_1c" \
      "$(jq -n --arg log "$WORKFLOW_LOG" '{workflow_log: $log}')"

    echo "ERROR: Delegation contract violation detected" >&2
    echo "  Primary agent used prohibited tools (Edit, lean_goal, lean_multi_attempt, lean-lsp)" >&2
    echo "  See validation output above for details" >&2
    exit 1
  fi

  echo "[OK] Delegation contract validated: No prohibited tool usage"
  echo ""
else
  if [ ! -f "$WORKFLOW_LOG" ]; then
    echo "INFO: Delegation contract validation skipped (no workflow log found)" >&2
  else
    echo "INFO: Delegation contract validation skipped (SKIP_DELEGATION_VALIDATION=true)" >&2
  fi
fi

# === DEFENSIVE CONTINUATION VALIDATION ===
# Override requires_continuation if work_remaining non-empty (defensive pattern from /implement)
if [ -n "$WORK_REMAINING_NEW" ] && [ "$WORK_REMAINING_NEW" != "0" ]; then
  if [ "$REQUIRES_CONTINUATION" != "true" ]; then
    echo "WARNING: Agent returned requires_continuation=false with non-empty work_remaining" >&2
    echo "  work_remaining: $WORK_REMAINING_NEW" >&2
    echo "  Overriding to requires_continuation=true (defensive validation)" >&2
    REQUIRES_CONTINUATION="true"

    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Agent contract violation: requires_continuation=false with work_remaining=$WORK_REMAINING_NEW" \
      "bash_block_1c" \
      "$(jq -n --arg coord "$COORDINATOR_NAME" --arg work "$WORK_REMAINING_NEW" \
         '{coordinator: $coord, work_remaining: $work}')"
  fi
fi

# === CONTEXT AGGREGATION ===
# Track cumulative context usage across iterations and compare against threshold
if [[ "$CONTEXT_USAGE_PERCENT" =~ ^[0-9]+$ ]]; then
  # Valid numeric format, check against threshold
  if [ "$CONTEXT_USAGE_PERCENT" -ge "$CONTEXT_THRESHOLD" ]; then
    echo "WARNING: Context usage at ${CONTEXT_USAGE_PERCENT}% (threshold: ${CONTEXT_THRESHOLD}%)" >&2
    echo "  Context threshold exceeded - saving checkpoint..." >&2

    # === CHECKPOINT SAVING ON CONTEXT THRESHOLD EXCEEDED ===
    if type save_checkpoint &>/dev/null; then
      # Build checkpoint data as JSON
      CHECKPOINT_DATA=$(jq -n \
        --arg plan_path "$PLAN_FILE" \
        --arg topic_path "$TOPIC_PATH" \
        --argjson iteration "$ITERATION" \
        --argjson max_iterations "$MAX_ITERATIONS" \
        --arg work_remaining "$WORK_REMAINING_NEW" \
        --argjson context_usage "$CONTEXT_USAGE_PERCENT" \
        --arg halt_reason "context_threshold_exceeded" \
        '{
          plan_path: $plan_path,
          topic_path: $topic_path,
          iteration: $iteration,
          max_iterations: $max_iterations,
          work_remaining: $work_remaining,
          context_usage_percent: $context_usage,
          halt_reason: $halt_reason
        }')

      # Save checkpoint
      CHECKPOINT_FILE=$(save_checkpoint "lean_implement" "$WORKFLOW_ID" "$CHECKPOINT_DATA" 2>&1)
      CHECKPOINT_SAVE_EXIT=$?

      if [ $CHECKPOINT_SAVE_EXIT -eq 0 ] && [ -n "$CHECKPOINT_FILE" ]; then
        echo "Checkpoint saved: $CHECKPOINT_FILE" >&2
        append_workflow_state "CHECKPOINT_PATH" "${CHECKPOINT_FILE:-}"
      else
        echo "WARNING: Failed to save checkpoint (exit code: $CHECKPOINT_SAVE_EXIT)" >&2
      fi
    else
      echo "WARNING: save_checkpoint function not available - checkpoint not saved" >&2
    fi

    # Set flag to trigger halt in iteration decision
    REQUIRES_CONTINUATION="false"
  fi
else
  # Invalid format, log warning but continue
  echo "WARNING: Invalid context_usage_percent format: '$CONTEXT_USAGE_PERCENT' (expected numeric)" >&2
  CONTEXT_USAGE_PERCENT=0
fi

# === STUCK DETECTION ===
if [ -n "$WORK_REMAINING_NEW" ] && [ "$WORK_REMAINING_NEW" = "$LAST_WORK_REMAINING" ]; then
  STUCK_COUNT=$((STUCK_COUNT + 1))
  echo "WARNING: Work remaining unchanged (stuck count: $STUCK_COUNT)" >&2

  if [ "$STUCK_COUNT" -ge 2 ]; then
    echo "ERROR: Stuck detected (no progress for 2 iterations)" >&2
    append_workflow_state "IMPLEMENTATION_STATUS" "stuck"
    append_workflow_state "HALT_REASON" "stuck"
    append_workflow_state "SUMMARY_PATH" "${LATEST_SUMMARY:-}"
    # Continue to Block 1d for phase marker recovery
  fi
else
  STUCK_COUNT=0
fi

# === ITERATION DECISION ===
echo "=== Iteration Decision (${ITERATION}/${MAX_ITERATIONS}) ==="

# Check for context threshold halt (REQUIRES_CONTINUATION set to "false" by checkpoint logic)
if [ "$REQUIRES_CONTINUATION" = "false" ] && [ "$CONTEXT_USAGE_PERCENT" -ge "$CONTEXT_THRESHOLD" ]; then
  echo "Context threshold exceeded - halting workflow"
  echo "  Context usage: ${CONTEXT_USAGE_PERCENT}% (threshold: ${CONTEXT_THRESHOLD}%)"
  echo "  Checkpoint saved for resume"
  append_workflow_state "IMPLEMENTATION_STATUS" "context_threshold_exceeded"
  append_workflow_state "HALT_REASON" "context_threshold_exceeded"
  append_workflow_state "WORK_REMAINING" "${WORK_REMAINING_NEW:-}"
  append_workflow_state "SUMMARY_PATH" "$LATEST_SUMMARY"
  echo "Proceeding to Block 1d (phase marker recovery)..."
elif [ "$REQUIRES_CONTINUATION" = "true" ] && [ -n "$WORK_REMAINING_NEW" ] && [ "$ITERATION" -lt "$MAX_ITERATIONS" ] && [ "$STUCK_COUNT" -lt 2 ]; then
  NEXT_ITERATION=$((ITERATION + 1))
  CONTINUATION_CONTEXT="${LEAN_IMPLEMENT_WORKSPACE}/iteration_${ITERATION}_summary.md"

  echo "Continuing to iteration $NEXT_ITERATION..."
  echo "  Work remaining: $WORK_REMAINING_NEW"
  echo "  Context usage: ${CONTEXT_USAGE_PERCENT}%"

  # Update per-coordinator iteration if applicable
  if [ "$CURRENT_PHASE_TYPE" = "lean" ]; then
    LEAN_ITERATION=$((LEAN_ITERATION + 1))
    append_workflow_state "LEAN_ITERATION" "$LEAN_ITERATION"
  else
    SOFTWARE_ITERATION=$((SOFTWARE_ITERATION + 1))
    append_workflow_state "SOFTWARE_ITERATION" "$SOFTWARE_ITERATION"
  fi

  # Update state for next iteration
  append_workflow_state "ITERATION" "$NEXT_ITERATION"
  append_workflow_state "WORK_REMAINING" "${WORK_REMAINING_NEW:-}"
  append_workflow_state "CONTINUATION_CONTEXT" "$CONTINUATION_CONTEXT"
  append_workflow_state "STUCK_COUNT" "$STUCK_COUNT"
  append_workflow_state "LAST_WORK_REMAINING" "$WORK_REMAINING_NEW"
  append_workflow_state "IMPLEMENTATION_STATUS" "continuing"

  # Save summary for continuation context
  cp "$LATEST_SUMMARY" "$CONTINUATION_CONTEXT" 2>/dev/null || true

  echo ""
  echo "**ITERATION LOOP**: Returning to Block 1b for re-delegation"
  echo ""

  # HARD BARRIER: PRIMARY AGENT STOPS HERE
  # This exit prevents the primary agent from continuing with implementation work
  # that should be delegated to coordinators. Execution resumes at Block 1b on
  # next iteration with the updated state (ITERATION, WORK_REMAINING).
  exit 0
else
  # Work complete or max iterations/stuck
  if [ -z "$WORK_REMAINING_NEW" ] || [ "$WORK_REMAINING_NEW" = "0" ]; then
    echo "All work complete!"
    append_workflow_state "IMPLEMENTATION_STATUS" "complete"
  elif [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
    echo "Max iterations ($MAX_ITERATIONS) reached"
    append_workflow_state "IMPLEMENTATION_STATUS" "max_iterations"
    append_workflow_state "HALT_REASON" "max_iterations"
  fi

  append_workflow_state "WORK_REMAINING" "${WORK_REMAINING_NEW:-}"
  append_workflow_state "SUMMARY_PATH" "$LATEST_SUMMARY"

  echo "Proceeding to Block 1d (phase marker recovery)..."
fi
echo ""
```

## Block 1d: Phase Marker Management (DELEGATED TO COORDINATORS)

**NOTE**: Phase marker validation and recovery has been removed from the orchestrator.

**Coordinator Responsibility**: Phase marker management (adding [IN PROGRESS] and [COMPLETE] markers) is handled by coordinators (lean-coordinator and implementer-coordinator) as part of their workflow. The orchestrator trusts coordinators to update phase markers correctly.

**Rationale**:
- Eliminates redundant marker recovery logic in orchestrator
- Reduces context consumption (saved ~120 lines of bash code)
- Maintains single source of truth (coordinators control markers)
- Simplifies orchestrator to pure routing and validation

If phase markers are missing, check coordinator logs rather than running orchestrator recovery.

## Block 2: Completion & Summary

**EXECUTE NOW**: Display completion summary with aggregated metrics from both coordinator types.

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e

# === DETECT PROJECT DIRECTORY ===
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
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
fi

# === SOURCE LIBRARIES ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh" 2>/dev/null || true
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || true

ensure_error_log_exists

# === RESTORE STATE ===
# Discover latest state file
STATE_FILE=$(discover_latest_state_file "lean_implement")
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to discover state file from previous block" >&2
  exit 1
fi

# Restore state from discovered file
source "$STATE_FILE"
COMMAND_NAME="${COMMAND_NAME:-/lean-implement}"
USER_ARGS="${USER_ARGS:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === COMPLETE WORKFLOW ===
sm_transition "$STATE_COMPLETE" "hybrid implementation complete" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "WARNING: State transition to COMPLETE failed" >&2
fi

if ! save_completed_states_to_state 2>&1; then
  log_command_error \
    "state_error" \
    "Failed to persist COMPLETED_STATES to state file" \
    "bash_block_3 (completion phase)"
  echo "WARNING: Failed to persist COMPLETED_STATES to state file" >&2
fi

# === AGGREGATE METRICS ===
# Use checkbox-utils.sh for completion detection
PLAN_COMPLETE=false
if type check_all_phases_complete &>/dev/null; then
  check_all_phases_complete "$PLAN_FILE" && PLAN_COMPLETE=true || PLAN_COMPLETE=false
fi

# Update plan metadata status if all phases complete
if [ "$PLAN_COMPLETE" = "true" ]; then
  if type update_plan_status &>/dev/null; then
    if update_plan_status "$PLAN_FILE" "COMPLETE" 2>/dev/null; then
      echo "Plan metadata status updated to [COMPLETE]"
    else
      echo "WARNING: Could not update plan metadata status to COMPLETE" >&2
    fi
  fi
fi

# Initialize metric variables
LEAN_SUMMARIES=()
SOFTWARE_SUMMARIES=()
LEAN_PHASES_COMPLETED=0
SOFTWARE_PHASES_COMPLETED=0
THEOREMS_PROVEN=0
GIT_COMMITS_COUNT=0

# Scan summaries directory for coordinator summaries
if [ -d "$SUMMARIES_DIR" ]; then
  while IFS= read -r summary_file; do
    # Skip empty results
    [ -z "$summary_file" ] && continue
    [ ! -f "$summary_file" ] && continue

    # Parse coordinator_type from summary file (first 10 lines for efficiency)
    COORD_TYPE=$(head -10 "$summary_file" 2>/dev/null | grep -E "^coordinator_type:" | sed 's/^coordinator_type:[[:space:]]*//' | tr -d '"' || echo "")

    # Filter by coordinator type and extract metrics
    if [ "$COORD_TYPE" = "lean" ]; then
      LEAN_SUMMARIES+=("$summary_file")
      # Extract theorem count
      THEOREM_COUNT=$(grep -E "^theorem_count:" "$summary_file" 2>/dev/null | sed 's/^theorem_count:[[:space:]]*//' || echo "0")
      THEOREMS_PROVEN=$((THEOREMS_PROVEN + THEOREM_COUNT))
      # Count phases from phases_completed field
      PHASES=$(grep -E "^phases_completed:" "$summary_file" 2>/dev/null | sed 's/^phases_completed:[[:space:]]*//' | tr -d '[],"' | wc -w || echo "0")
      LEAN_PHASES_COMPLETED=$((LEAN_PHASES_COMPLETED + PHASES))
    elif [ "$COORD_TYPE" = "software" ]; then
      SOFTWARE_SUMMARIES+=("$summary_file")
      # Extract git commits count
      GIT_COMMITS=$(grep -E "^git_commits:" "$summary_file" 2>/dev/null | sed 's/^git_commits:[[:space:]]*//' | tr -d '[],"' | wc -w || echo "0")
      GIT_COMMITS_COUNT=$((GIT_COMMITS_COUNT + GIT_COMMITS))
      # Count phases from phases_completed field
      PHASES=$(grep -E "^phases_completed:" "$summary_file" 2>/dev/null | sed 's/^phases_completed:[[:space:]]*//' | tr -d '[],"' | wc -w || echo "0")
      SOFTWARE_PHASES_COMPLETED=$((SOFTWARE_PHASES_COMPLETED + PHASES))
    fi
  done < <(find "$SUMMARIES_DIR" -name "*.md" -type f 2>/dev/null || true)
fi

TOTAL_COMPLETED=$((LEAN_PHASES_COMPLETED + SOFTWARE_PHASES_COMPLETED))

# === CONSOLE SUMMARY ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/summary-formatting.sh" 2>/dev/null || {
  echo "WARNING: Could not load summary formatting library" >&2
}

echo ""
echo "=== Hybrid Implementation Complete ==="
echo ""

# Summary text with metrics
SUMMARY_TEXT="Completed $TOTAL_COMPLETED phases: "
if [ $LEAN_PHASES_COMPLETED -gt 0 ]; then
  SUMMARY_TEXT="${SUMMARY_TEXT}$LEAN_PHASES_COMPLETED Lean ($THEOREMS_PROVEN theorems)"
  [ $SOFTWARE_PHASES_COMPLETED -gt 0 ] && SUMMARY_TEXT="${SUMMARY_TEXT}, "
fi
if [ $SOFTWARE_PHASES_COMPLETED -gt 0 ]; then
  SUMMARY_TEXT="${SUMMARY_TEXT}$SOFTWARE_PHASES_COMPLETED software ($GIT_COMMITS_COUNT commits)"
fi
SUMMARY_TEXT="${SUMMARY_TEXT}. Mode: $EXECUTION_MODE."

# Build phases section with summary file audit trail
PHASES=""
if [ $LEAN_PHASES_COMPLETED -gt 0 ]; then
  PHASES="${PHASES}  Lean phases: $LEAN_PHASES_COMPLETED completed ($THEOREMS_PROVEN theorems)
"
  if [ ${#LEAN_SUMMARIES[@]} -gt 0 ]; then
    PHASES="${PHASES}    Lean summaries:"
    for summary in "${LEAN_SUMMARIES[@]}"; do
      PHASES="${PHASES}
      - $(basename "$summary")"
    done
    PHASES="${PHASES}
"
  fi
fi
if [ $SOFTWARE_PHASES_COMPLETED -gt 0 ]; then
  PHASES="${PHASES}  Software phases: $SOFTWARE_PHASES_COMPLETED completed ($GIT_COMMITS_COUNT commits)
"
  if [ ${#SOFTWARE_SUMMARIES[@]} -gt 0 ]; then
    PHASES="${PHASES}    Software summaries:"
    for summary in "${SOFTWARE_SUMMARIES[@]}"; do
      PHASES="${PHASES}
      - $(basename "$summary")"
    done
    PHASES="${PHASES}
"
  fi
fi

# Build artifacts section
ARTIFACTS="  Plan: $PLAN_FILE"
if [ -n "${SUMMARY_PATH:-}" ] && [ -f "${SUMMARY_PATH:-}" ]; then
  ARTIFACTS="${ARTIFACTS}
  Latest Summary: $SUMMARY_PATH"
fi

# Build next steps
NEXT_STEPS="  Review plan: cat $PLAN_FILE
  Run tests: /test $PLAN_FILE
  Run /todo to update TODO.md"

# Print summary
if type print_artifact_summary &>/dev/null; then
  print_artifact_summary "Hybrid Implementation" "$SUMMARY_TEXT" "$PHASES" "$ARTIFACTS" "$NEXT_STEPS"
else
  echo "Summary: $SUMMARY_TEXT"
  echo ""
  echo "Phases:"
  echo "$PHASES"
  echo ""
  echo "Artifacts:"
  echo "$ARTIFACTS"
  echo ""
  echo "Next Steps:"
  echo "$NEXT_STEPS"
fi

echo ""
echo "Next Step: Run /todo to update TODO.md with this implementation"
echo ""

# === CONTEXT BUDGET SUMMARY (Optional) ===
if [ "${LEAN_IMPLEMENT_CONTEXT_TRACKING:-false}" = "true" ]; then
  echo "=== Context Budget Summary ==="
  echo "Total primary agent context: $CURRENT_CONTEXT tokens"
  echo "Budget: $PRIMARY_CONTEXT_BUDGET tokens"
  BUDGET_PERCENT=$((CURRENT_CONTEXT * 100 / PRIMARY_CONTEXT_BUDGET))
  echo "Usage: ${BUDGET_PERCENT}% of budget"
  if [ "$CURRENT_CONTEXT" -le 2000 ]; then
    echo "Status: EXCELLENT (75% reduction achieved)"
  elif [ "$CURRENT_CONTEXT" -le 3000 ]; then
    echo "Status: GOOD (60%+ reduction)"
  else
    echo "Status: NEEDS OPTIMIZATION"
  fi
  echo ""
fi

# === EMIT COMPLETION SIGNAL ===
echo "IMPLEMENTATION_COMPLETE:"
echo "  plan_file: $PLAN_FILE"
echo "  topic_path: $TOPIC_PATH"
echo "  summary_path: ${SUMMARY_PATH:-}"
echo "  total_phases: $TOTAL_PHASES"
echo "  lean_phases_completed: $LEAN_PHASES_COMPLETED"
echo "  software_phases_completed: $SOFTWARE_PHASES_COMPLETED"
echo "  theorems_proven: $THEOREMS_PROVEN"
echo "  git_commits_count: $GIT_COMMITS_COUNT"
echo "  execution_mode: $EXECUTION_MODE"
echo "  iterations_used: $ITERATION"
echo "  work_remaining: ${WORK_REMAINING:-0}"

# Cleanup
delete_checkpoint "lean_implement" 2>/dev/null || true

exit 0
```

---

## Troubleshooting

### Phase Classification Issues
- **Ambiguous phases**: Default to "software" - add `lean_file:` metadata for explicit Lean classification
- **Wrong classification**: Check Tier 1 (lean_file metadata) and Tier 2 (keywords/extensions)
- **Use DEBUG_LOG**: Check `~/.claude/tmp/workflow_debug.log` for classification decisions

### Coordinator Routing Issues
- **Lean coordinator fails**: Verify lean-lsp-mcp is available, Lean file exists
- **Software coordinator fails**: Check implementer-coordinator agent is accessible
- **Both fail**: Review routing map in workspace directory

### Iteration Issues
- **Stuck detection**: Work remaining unchanged for 2 iterations triggers halt
- **Max iterations**: Increase with `--max-iterations=N`
- **Continuation context**: Check workspace directory for iteration summaries

### Mode Filtering
- `--mode=lean-only`: Skips all software phases
- `--mode=software-only`: Skips all Lean phases
- `--mode=auto`: Executes all phases with automatic routing (default)

## Phase 0 Auto-Detection

As of 2025-12-09, both `/lean-implement` and `/implement` commands automatically detect the lowest incomplete phase when no explicit starting phase is provided.

### How It Works

1. **Scan Plan File**: Extracts all phase numbers from phase headers
2. **Check Completion**: Finds first phase without `[COMPLETE]` marker
3. **Auto-Start**: Uses lowest incomplete phase as starting point
4. **Override**: Explicit phase argument overrides auto-detection

### Examples

```bash
# Plan with Phase 0 incomplete
### Phase 0: Standards Revision [NOT STARTED]
### Phase 1: Implementation [COMPLETE]
### Phase 2: Testing [NOT STARTED]

# Command: /lean-implement plan.md
# Result: Auto-detected starting phase: 0 (lowest incomplete)
```

```bash
# Plan without Phase 0
### Phase 1: Setup [COMPLETE]
### Phase 2: Implementation [NOT STARTED]

# Command: /lean-implement plan.md
# Result: Auto-detected starting phase: 2 (lowest incomplete)
```

```bash
# Explicit override
# Command: /lean-implement plan.md 5
# Result: Uses phase 5 (override auto-detection)
```

### Why This Matters

Before this feature, commands hardcoded `STARTING_PHASE=1`, causing Phase 0 (often Standards Revision phases) to be skipped. This fix ensures all phases are executed in dependency order.

## Checkpoint Resume Workflow

The command supports checkpoint-based resume for long-running implementations that exceed context thresholds.

### Context Monitoring

- **Default Threshold**: 90% context usage
- **Configurable**: `--context-threshold=N` (percentage)
- **Monitoring**: Parses `context_usage_percent` from coordinator summaries
- **Defensive**: Invalid percentages default to 0 with warning

### Checkpoint Save

When context usage >= threshold:

1. Creates checkpoint JSON in `.claude/data/checkpoints/`
2. Saves: plan_path, iteration, max_iterations, work_remaining, context_usage_percent, completed_phases, coordinator_name
3. Schema version: 2.1
4. Emits checkpoint path in output

### Checkpoint Resume

To resume from checkpoint:

```bash
# Save checkpoint when context threshold exceeded
/lean-implement plan.md --context-threshold=80
# Output: Checkpoint saved: /path/to/checkpoint.json

# Resume from checkpoint
/lean-implement --resume=/path/to/checkpoint.json
# Restores: PLAN_FILE, ITERATION, MAX_ITERATIONS, CONTINUATION_CONTEXT, COMPLETED_PHASES
```

### Iteration Control

- **Default**: 5 iterations maximum
- **Configurable**: `--max-iterations=N`
- **Passed to Coordinators**: Both lean-coordinator and implementer-coordinator receive iteration context
- **Prevents Infinite Loops**: Workflow halts at max iterations even if work remaining

## Success Criteria

Workflow is successful if:
- Phase classification correctly identifies Lean vs software phases
- Phase 0 auto-detection finds lowest incomplete phase (including phase 0)
- Appropriate coordinator invoked for each phase type
- Summary created in summaries directory (>100 bytes)
- Phase markers updated ([NOT STARTED] -> [IN PROGRESS] -> [COMPLETE])
- Context usage tracked and checkpoints created when threshold exceeded
- Aggregated metrics from both coordinator types
- IMPLEMENTATION_COMPLETE signal emitted with all metrics
