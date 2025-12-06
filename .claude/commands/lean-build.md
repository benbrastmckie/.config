---
allowed-tools: Task, Bash, Read, Grep, Glob
argument-hint: [lean-file | plan-file] [--prove-all | --verify] [--max-attempts=N] [--max-iterations=N]
description: Build proofs for all sorry markers in Lean files using wave-based orchestration
command-type: primary
subcommands:
  - build: "Build proofs for all sorry markers (current)"
  - verify: "Verify existing proofs without modification (future)"
  - prove: "Prove specific theorem by name (future)"
dependent-agents:
  - lean-coordinator
  - lean-implementer
library-requirements:
  - error-handling.sh: ">=1.0.0"
  - state-persistence.sh: ">=1.6.0"
documentation: See .claude/docs/guides/commands/lean-command-guide.md for usage
---

# /lean-build - Lean Theorem Proving Command

YOU ARE EXECUTING a Lean 4 theorem proving workflow that uses the lean-coordinator and lean-implementer agents with lean-lsp-mcp integration to prove theorems, search Mathlib, and verify proofs.

**Workflow Type**: lean-proving
**Expected Input**: Lean file path or plan file
**Expected Output**: Completed proofs with summaries

## Lean File Metadata Format

When using plan-based mode, the /lean-build command uses a **2-tier discovery** mechanism to locate Lean files:

### Tier 1: Phase-Specific Metadata (Preferred)

Specify the Lean file immediately after the phase heading:

```markdown
### Phase 1: Prove Theorems [NOT STARTED]
lean_file: /absolute/path/to/file.lean

**Tasks**:
- [ ] Prove theorem_add
```

**Best Practice**: Use this format for all /lean-plan generated plans. Each phase can target a different Lean file.

### Tier 2: Global Metadata (Fallback)

Specify the Lean file in the metadata section using markdown list format:

```markdown
## Metadata
- **Date**: 2025-12-03
- **Feature**: Modal Logic Proofs
- **Lean File**: /absolute/path/to/file.lean
```

**Format Requirements**:
- Must use markdown list format: `- **Lean File**: /path`
- Must include hyphen prefix and space
- Asterisks mark bold text in markdown

### Discovery Priority

1. **Tier 1 attempted first**: Searches for `lean_file:` after phase heading
2. **Tier 2 fallback**: Searches for `- **Lean File**:` in metadata section
3. **Error if both fail**: Clear error message with format examples

### Troubleshooting

If metadata extraction fails:
- Verify Tier 1 format: `lean_file:` immediately after phase heading (no blank lines)
- Verify Tier 2 format: Markdown list with hyphen prefix `- **Lean File**:`
- Use absolute paths (relative paths may fail)
- Check for typos in `lean_file:` or `**Lean File**` keywords

## Block 1a: Setup & State Initialization

**EXECUTE NOW**: The user invoked `/lean-build [lean-file | plan-file] [--prove-all | --verify] [--max-attempts=N] [--max-iterations=N]`. This block captures arguments, validates Lean project, initializes workflow state, and prepares for coordinator/implementer invocation.

In the **bash block below**, replace `YOUR_LEAN_ARGS_HERE` with the actual lean arguments.

**Examples**:
- If user ran `/lean Test.lean`, change to: `echo "Test.lean" > "$TEMP_FILE"`
- If user ran `/lean plan.md --prove-all --max-iterations=3`, change to: `echo "plan.md --prove-all --max-iterations=3" > "$TEMP_FILE"`

```bash
# === PREPROCESSING SAFETY ===
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e  # Fail-fast

# === CAPTURE LEAN ARGUMENTS ===
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/lean_arg_$(date +%s%N).txt"
# SUBSTITUTE THE LEAN ARGUMENTS IN THE LINE BELOW
echo "YOUR_LEAN_ARGS_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/lean_arg_path.txt"

# === READ AND PARSE ARGUMENTS ===
LEAN_ARGS=$(cat "$TEMP_FILE" 2>/dev/null || echo "")

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

# Source error-handling.sh
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Source state-persistence.sh
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}

# === INITIALIZE WORKFLOW STATE ===
WORKFLOW_ID="lean_$(date +%s)"
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
trap "rm -f '$STATE_FILE'" EXIT

# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists

# Set workflow metadata
COMMAND_NAME="/lean-build"
USER_ARGS="$LEAN_ARGS"

echo "=== Lean Theorem Proving Workflow ==="
echo ""

# === PARSE ARGUMENTS ===
read -ra ARGS_ARRAY <<< "$LEAN_ARGS"
INPUT_FILE="${ARGS_ARRAY[0]:-}"
MODE="--prove-all"  # Default mode
MAX_ATTEMPTS=3      # Default max attempts per theorem
MAX_ITERATIONS=5    # Default max iterations for persistence loop
CONTEXT_THRESHOLD=90  # Default context threshold percentage

for arg in "${ARGS_ARRAY[@]:1}"; do
  case "$arg" in
    --prove-all) MODE="--prove-all" ;;
    --verify) MODE="--verify" ;;
    --max-attempts=*) MAX_ATTEMPTS="${arg#*=}" ;;
    --max-iterations=*) MAX_ITERATIONS="${arg#*=}" ;;
    --context-threshold=*) CONTEXT_THRESHOLD="${arg#*=}" ;;
  esac
done

# === VALIDATE INPUT FILE ===
if [ -z "$INPUT_FILE" ]; then
  echo "ERROR: No Lean file or plan file specified" >&2
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" "No file specified" "bash_block" "{}"
  exit 1
fi

# Resolve to absolute path
if [ ! -f "$INPUT_FILE" ]; then
  # Try relative to current directory
  if [ -f "$CLAUDE_PROJECT_DIR/$INPUT_FILE" ]; then
    INPUT_FILE="$CLAUDE_PROJECT_DIR/$INPUT_FILE"
  else
    echo "ERROR: File not found: $INPUT_FILE" >&2
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "file_error" "File not found: $INPUT_FILE" "bash_block" "{}"
    exit 1
  fi
fi

INPUT_FILE="$(cd "$(dirname "$INPUT_FILE")" && pwd)/$(basename "$INPUT_FILE")"

# === DETECT EXECUTION MODE ===
EXECUTION_MODE="file-based"  # Default
PLAN_FILE=""
LEAN_FILE=""

if [[ "$INPUT_FILE" == *.md ]]; then
  # Plan file provided
  EXECUTION_MODE="plan-based"
  PLAN_FILE="$INPUT_FILE"

  # Source checkbox utilities for plan support
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || {
    echo "ERROR: Failed to source checkbox-utils.sh" >&2
    exit 1
  }

  # === LEAN FILE DISCOVERY (2-TIER PHASE-AWARE WITH MULTI-FILE SUPPORT) ===
  # Tier 1: Phase-specific metadata (lean_file: path/to/file.lean OR file1.lean, file2.lean)
  # Tier 2: Global metadata (**Lean File**: path)
  # NO Tier 3: Directory search removed (non-deterministic)

  LEAN_FILE_RAW=""
  DISCOVERY_METHOD=""

  # Determine starting phase number (for phase-specific discovery)
  STARTING_PHASE=1

  # Tier 1: Extract phase-specific lean_file metadata
  # Pattern:
  #   ### Phase N: Name [STATUS]
  #   lean_file: path/to/file.lean
  #   lean_file: file1.lean, file2.lean, file3.lean  (comma-separated for multiple files)
  LEAN_FILE_RAW=$(awk -v target="$STARTING_PHASE" '
    BEGIN { in_phase=0 }
    /^### Phase / {
      if (index($0, "Phase " target ":") > 0) {
        in_phase = 1
      } else {
        in_phase = 0
      }
      next
    }
    in_phase && /^lean_file:/ {
      sub(/^lean_file:[[:space:]]*/, "")
      print
      exit
    }
  ' "$PLAN_FILE")

  if [ -n "$LEAN_FILE_RAW" ]; then
    DISCOVERY_METHOD="phase_metadata"
    echo "Lean file(s) discovered via phase metadata: $LEAN_FILE_RAW"
  fi

  # Tier 2: Fallback to global metadata
  if [ -z "$LEAN_FILE_RAW" ]; then
    echo "Phase metadata not found, trying global metadata..."
    LEAN_FILE_RAW=$(grep '^- \*\*Lean File\*\*:' "$PLAN_FILE" | sed 's/^- \*\*Lean File\*\*:[[:space:]]*//' | head -1)

    if [ -n "$LEAN_FILE_RAW" ]; then
      DISCOVERY_METHOD="global_metadata"
      echo "Lean file(s) discovered via global metadata: $LEAN_FILE_RAW"
    else
      echo "WARNING: Global metadata extraction failed (check markdown format)" >&2
      echo "  Expected format: '- **Lean File**: /path/to/file.lean'" >&2
    fi
  fi

  # Error if no file found (NO directory search fallback)
  if [ -z "$LEAN_FILE_RAW" ]; then
    echo "ERROR: No Lean file found via metadata" >&2
    echo "" >&2
    echo "Please specify the Lean file using one of these methods:" >&2
    echo "  1. Phase-specific metadata (single file):" >&2
    echo "     ### Phase $STARTING_PHASE: Name [NOT STARTED]" >&2
    echo "     lean_file: /path/to/file.lean" >&2
    echo "" >&2
    echo "  2. Phase-specific metadata (multiple files):" >&2
    echo "     ### Phase $STARTING_PHASE: Name [NOT STARTED]" >&2
    echo "     lean_file: file1.lean, file2.lean, file3.lean" >&2
    echo "" >&2
    echo "  3. Global metadata:" >&2
    echo "     **Lean File**: /path/to/file.lean" >&2
    echo "" >&2
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "validation_error" "No Lean file metadata found" "bash_block" \
      "{\"plan_file\": \"$PLAN_FILE\", \"starting_phase\": $STARTING_PHASE}"
    exit 1
  fi

  # Parse comma-separated files into array
  IFS=',' read -ra LEAN_FILES <<< "$LEAN_FILE_RAW"

  # Trim whitespace from each file path
  for i in "${!LEAN_FILES[@]}"; do
    LEAN_FILES[$i]=$(echo "${LEAN_FILES[$i]}" | xargs)
  done

  # Validate all discovered files exist
  FILE_COUNT=${#LEAN_FILES[@]}
  echo "Discovered $FILE_COUNT Lean file(s) via $DISCOVERY_METHOD"

  for LEAN_FILE_ITEM in "${LEAN_FILES[@]}"; do
    if [ ! -f "$LEAN_FILE_ITEM" ]; then
      echo "ERROR: Lean file not found: $LEAN_FILE_ITEM" >&2
      echo "Discovery method: $DISCOVERY_METHOD" >&2
      log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
        "file_error" "Lean file discovered but not found: $LEAN_FILE_ITEM" "bash_block" \
        "{\"plan_file\": \"$PLAN_FILE\", \"lean_file\": \"$LEAN_FILE_ITEM\", \"discovery_method\": \"$DISCOVERY_METHOD\", \"file_count\": $FILE_COUNT}"
      exit 1
    fi
    echo "  - $LEAN_FILE_ITEM (validated)"
  done

  # Store files array for coordinator invocation (use first file as primary)
  LEAN_FILE="${LEAN_FILES[0]}"
  LEAN_FILES_JSON=$(printf '%s\n' "${LEAN_FILES[@]}" | jq -R . | jq -s .)
  append_workflow_state "LEAN_FILES" "$LEAN_FILES_JSON"
  append_workflow_state "LEAN_FILE_COUNT" "$FILE_COUNT"

  echo "Execution Mode: plan-based"
  echo "Plan File: $PLAN_FILE"
  echo "Lean File: $LEAN_FILE (discovered via $DISCOVERY_METHOD)"

  # === LEGACY PLAN DETECTION ===
  # Add [NOT STARTED] markers to phases without status markers
  if ! grep -q "\[NOT STARTED\]\|\[IN PROGRESS\]\|\[COMPLETE\]" "$PLAN_FILE"; then
    add_not_started_markers "$PLAN_FILE"
  fi

  # === MARK STARTING PHASE AS IN PROGRESS ===
  STARTING_PHASE=1
  add_in_progress_marker "$PLAN_FILE" "$STARTING_PHASE"

  # === UPDATE PLAN METADATA STATUS ===
  update_plan_status "$PLAN_FILE" "IN PROGRESS"

else
  # Lean file provided directly
  LEAN_FILE="$INPUT_FILE"
  echo "Execution Mode: file-based"
  echo "Lean File: $LEAN_FILE"
fi

echo "Mode: $MODE"
echo "Max Attempts: $MAX_ATTEMPTS"
echo ""

# === DETECT LEAN PROJECT ===
LEAN_PROJECT_DIR="$(dirname "$LEAN_FILE")"
while [ "$LEAN_PROJECT_DIR" != "/" ]; do
  if [ -f "$LEAN_PROJECT_DIR/lakefile.toml" ] || [ -f "$LEAN_PROJECT_DIR/lakefile.lean" ]; then
    break
  fi
  LEAN_PROJECT_DIR="$(dirname "$LEAN_PROJECT_DIR")"
done

if [ "$LEAN_PROJECT_DIR" = "/" ]; then
  echo "ERROR: Not a Lean 4 project (no lakefile.toml or lakefile.lean found)" >&2
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" "Not a Lean project" "bash_block" \
    "{\"file\": \"$LEAN_FILE\"}"
  exit 1
fi

echo "Lean Project: $LEAN_PROJECT_DIR"
echo ""

# === VERIFY MCP SERVER AVAILABILITY ===
if ! uvx --from lean-lsp-mcp --help >/dev/null 2>&1; then
  echo "ERROR: lean-lsp-mcp MCP server not available" >&2
  echo "  Install with: uvx --from lean-lsp-mcp" >&2
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "dependency_error" "lean-lsp-mcp not available" "bash_block" "{}"
  exit 1
fi

echo "MCP Server: Available"
echo ""

# === SETUP ARTIFACT PATHS ===
# Determine topic path from Lean file location
TOPIC_PATH="$(dirname "$LEAN_FILE")"

# Use .claude/specs structure if available, otherwise use project directory
if [ -d "$CLAUDE_PROJECT_DIR/.claude/specs" ]; then
  # Extract topic from Lean file path relative to project
  REL_PATH="${LEAN_FILE#$CLAUDE_PROJECT_DIR/}"
  TOPIC_NAME=$(echo "$REL_PATH" | sed 's/[^a-zA-Z0-9_-]/_/g' | cut -c1-50)
  TOPIC_PATH="$CLAUDE_PROJECT_DIR/.claude/specs/lean_$TOPIC_NAME"
  mkdir -p "$TOPIC_PATH/summaries" "$TOPIC_PATH/debug" 2>/dev/null
else
  TOPIC_PATH="$LEAN_PROJECT_DIR"
  mkdir -p "$TOPIC_PATH/.lean_summaries" 2>/dev/null
fi

SUMMARIES_DIR="$TOPIC_PATH/summaries"
DEBUG_DIR="$TOPIC_PATH/debug"

if [ ! -d "$SUMMARIES_DIR" ]; then
  SUMMARIES_DIR="$TOPIC_PATH/.lean_summaries"
  mkdir -p "$SUMMARIES_DIR" 2>/dev/null
fi

if [ ! -d "$DEBUG_DIR" ]; then
  DEBUG_DIR="$TOPIC_PATH"
fi

echo "Topic Path: $TOPIC_PATH"
echo "Summaries Directory: $SUMMARIES_DIR"
echo ""

# === ITERATION LOOP VARIABLES ===
LEAN_WORKSPACE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_${WORKFLOW_ID}"
mkdir -p "$LEAN_WORKSPACE" 2>/dev/null

ITERATION=1
CONTINUATION_CONTEXT=""
WORK_REMAINING=""
STUCK_COUNT=0

# Persist iteration variables to state
append_workflow_state "LEAN_WORKSPACE" "$LEAN_WORKSPACE"
append_workflow_state "ITERATION" "$ITERATION"
append_workflow_state "MAX_ITERATIONS" "$MAX_ITERATIONS"
append_workflow_state "CONTEXT_THRESHOLD" "$CONTEXT_THRESHOLD"
append_workflow_state "CONTINUATION_CONTEXT" "$CONTINUATION_CONTEXT"
append_workflow_state "WORK_REMAINING" "$WORK_REMAINING"
append_workflow_state "STUCK_COUNT" "$STUCK_COUNT"
append_workflow_state "EXECUTION_MODE" "$EXECUTION_MODE"
append_workflow_state "PLAN_FILE" "$PLAN_FILE"
append_workflow_state "LEAN_FILE" "$LEAN_FILE"
append_workflow_state "MODE" "$MODE"
append_workflow_state "MAX_ATTEMPTS" "$MAX_ATTEMPTS"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "SUMMARIES_DIR" "$SUMMARIES_DIR"
append_workflow_state "DEBUG_DIR" "$DEBUG_DIR"

echo "Lean Workspace: $LEAN_WORKSPACE"
echo "Iteration: ${ITERATION}/${MAX_ITERATIONS}"
echo ""
```

## Block 1b: Invoke Lean Coordinator [HARD BARRIER]

**EXECUTE NOW**: USE the Task tool to invoke the lean-coordinator agent.

Task {
  subagent_type: "general-purpose"
  description: "Wave-based Lean theorem proving orchestration for ${LEAN_FILE}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md

    **Input Contract**:
    - lean_file_path: ${LEAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - artifact_paths:
      - plans: ${CLAUDE_PROJECT_DIR}/.claude/specs/$(basename ${TOPIC_PATH})/plans
      - summaries: ${SUMMARIES_DIR}
      - outputs: ${TOPIC_PATH}/outputs
      - checkpoints: ${CLAUDE_PROJECT_DIR}/.claude/data/checkpoints
    - max_attempts: ${MAX_ATTEMPTS}
    - plan_path: ${PLAN_FILE:-}
    - execution_mode: ${EXECUTION_MODE}
    - starting_phase: ${STARTING_PHASE:-1}
    - continuation_context: ${CONTINUATION_CONTEXT:-null}
    - max_iterations: ${MAX_ITERATIONS}

    Execute wave-based proof orchestration for mode: ${EXECUTION_MODE}

    For file-based mode: Coordinator should auto-generate single-phase wave structure
    For plan-based mode: Coordinator analyzes dependencies and builds wave structure

    Progress Tracking Instructions (plan-based mode only):
    - Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
    - Before proving each theorem phase: add_in_progress_marker '${PLAN_FILE}' <phase_num>
    - After completing each theorem proof: mark_phase_complete '${PLAN_FILE}' <phase_num> && add_complete_marker '${PLAN_FILE}' <phase_num>
    - This creates visible progress: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]
    - Note: Progress tracking gracefully degrades if unavailable (non-fatal)
    - File-based mode: Skip progress tracking (phase_num = 0)

    **CRITICAL**: You MUST create a proof summary in ${SUMMARIES_DIR}/
    The orchestrator will validate the summary exists after you return.

    Return: ORCHESTRATION_COMPLETE
    summary_path: /path/to/summary
    phases_completed: [...]
    work_remaining: 0 or phase identifiers
    context_exhausted: true|false
    context_usage_percent: N%
    checkpoint_path: /path/to/checkpoint (if created)
    requires_continuation: true|false
    stuck_detected: false
  "
}

## Block 1c: Verification & Iteration Decision

**EXECUTE NOW**: Verify summary creation, parse agent output, and determine if iteration continuation is needed.

```bash
# === RESTORE STATE ===
load_workflow_state "$WORKFLOW_ID" 2>/dev/null || {
  echo "ERROR: Failed to restore workflow state" >&2
  exit 1
}

# === VALIDATE SUMMARY EXISTENCE ===
SUMMARY_FOUND="false"
SUMMARY_PATH=""

# Check for any recent summary in directory (last 5 minutes)
LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -mmin -5 2>/dev/null | sort | tail -1)

if [ -n "$LATEST_SUMMARY" ] && [ -f "$LATEST_SUMMARY" ] && [ $(stat -c%s "$LATEST_SUMMARY" 2>/dev/null || echo "0") -ge 100 ]; then
  SUMMARY_PATH="$LATEST_SUMMARY"
  SUMMARY_FOUND="true"
  echo "Summary found: $SUMMARY_PATH"
else
  echo "ERROR: Summary file not created or too small (<100 bytes)" >&2
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "agent_error" "Coordinator/implementer did not create summary" "verification_block" \
    "{\"summaries_dir\": \"$SUMMARIES_DIR\"}"
  exit 1
fi

echo ""

# === PARSE OUTPUT SIGNAL ===
# Extract work_remaining, context_exhausted, requires_continuation from summary
WORK_REMAINING_NEW=""
CONTEXT_EXHAUSTED="false"
REQUIRES_CONTINUATION="false"
CONTEXT_USAGE_PERCENT=0

if [ -f "$SUMMARY_PATH" ]; then
  # Parse summary for completion signal
  # Look for "work_remaining: Phase_X Phase_Y" or "work_remaining: 0"
  WORK_REMAINING_LINE=$(grep -E "^work_remaining:|^\*\*Work Remaining\*\*:" "$SUMMARY_PATH" | head -1)
  if [ -n "$WORK_REMAINING_LINE" ]; then
    WORK_REMAINING_NEW=$(echo "$WORK_REMAINING_LINE" | sed 's/^work_remaining:[[:space:]]*//' | sed 's/^\*\*Work Remaining\*\*:[[:space:]]*//')
    if [ "$WORK_REMAINING_NEW" = "0" ] || [ -z "$WORK_REMAINING_NEW" ]; then
      WORK_REMAINING_NEW=""
    fi
  fi

  # Parse context_exhausted field
  CONTEXT_EXHAUSTED_LINE=$(grep -E "^context_exhausted:|^\*\*Context Exhausted\*\*:" "$SUMMARY_PATH" | head -1)
  if [ -n "$CONTEXT_EXHAUSTED_LINE" ]; then
    CONTEXT_EXHAUSTED=$(echo "$CONTEXT_EXHAUSTED_LINE" | sed 's/^context_exhausted:[[:space:]]*//' | sed 's/^\*\*Context Exhausted\*\*:[[:space:]]*//')
  fi

  # Parse requires_continuation field
  REQUIRES_CONTINUATION_LINE=$(grep -E "^requires_continuation:|^\*\*Requires Continuation\*\*:" "$SUMMARY_PATH" | head -1)
  if [ -n "$REQUIRES_CONTINUATION_LINE" ]; then
    REQUIRES_CONTINUATION=$(echo "$REQUIRES_CONTINUATION_LINE" | sed 's/^requires_continuation:[[:space:]]*//' | sed 's/^\*\*Requires Continuation\*\*:[[:space:]]*//')
  fi

  # Parse context_usage_percent
  CONTEXT_USAGE_LINE=$(grep -E "^context_usage_percent:|^\*\*Context Usage\*\*:" "$SUMMARY_PATH" | head -1)
  if [ -n "$CONTEXT_USAGE_LINE" ]; then
    CONTEXT_USAGE_PERCENT=$(echo "$CONTEXT_USAGE_LINE" | sed 's/^context_usage_percent:[[:space:]]*//' | sed 's/^\*\*Context Usage\*\*:[[:space:]]*//' | sed 's/%//')
  fi
fi

echo "Work Remaining: ${WORK_REMAINING_NEW:-none}"
echo "Context Exhausted: $CONTEXT_EXHAUSTED"
echo "Context Usage: ${CONTEXT_USAGE_PERCENT}%"
echo "Requires Continuation: $REQUIRES_CONTINUATION"
echo ""

# === STUCK DETECTION ===
if [ -n "$WORK_REMAINING_NEW" ] && [ "$WORK_REMAINING_NEW" = "$WORK_REMAINING" ]; then
  STUCK_COUNT=$((STUCK_COUNT + 1))
  echo "WARNING: Work remaining unchanged (stuck count: $STUCK_COUNT)" >&2

  if [ "$STUCK_COUNT" -ge 2 ]; then
    echo "ERROR: Stuck detected (no progress for 2 iterations)" >&2
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "execution_error" "Stuck: no progress for 2 iterations" "verification_block" \
      "{\"work_remaining\": \"$WORK_REMAINING_NEW\", \"stuck_count\": $STUCK_COUNT}"

    # Exit to Block 2 for final summary
    append_workflow_state "REQUIRES_CONTINUATION" "false"
    append_workflow_state "SUMMARY_PATH" "$SUMMARY_PATH"
    exit 0
  fi
else
  STUCK_COUNT=0  # Reset stuck counter on progress
fi

# === ITERATION DECISION ===
echo "=== Iteration Decision (${ITERATION}/${MAX_ITERATIONS}) ==="

# Decision logic: Continue if work remaining AND not stuck AND iterations left
if [ "$REQUIRES_CONTINUATION" = "true" ] && [ -n "$WORK_REMAINING_NEW" ] && [ "$ITERATION" -lt "$MAX_ITERATIONS" ]; then
  NEXT_ITERATION=$((ITERATION + 1))
  CONTINUATION_CONTEXT="${LEAN_WORKSPACE}/iteration_${ITERATION}_summary.md"

  echo "Continuing to iteration $NEXT_ITERATION..."
  echo "  - Work remaining: $WORK_REMAINING_NEW"
  echo "  - Context usage: ${CONTEXT_USAGE_PERCENT}%"
  echo ""

  # Update state for next iteration
  append_workflow_state "ITERATION" "$NEXT_ITERATION"
  append_workflow_state "WORK_REMAINING" "$WORK_REMAINING_NEW"
  append_workflow_state "CONTINUATION_CONTEXT" "$CONTINUATION_CONTEXT"
  append_workflow_state "STUCK_COUNT" "$STUCK_COUNT"

  # Copy summary to continuation context
  if [ -f "$SUMMARY_PATH" ]; then
    cp "$SUMMARY_PATH" "$CONTINUATION_CONTEXT" 2>/dev/null || true
    echo "Continuation context saved: $CONTINUATION_CONTEXT"
  fi

  echo ""
  echo "**ITERATION LOOP**: Return to Block 1b with updated state (iteration $NEXT_ITERATION)"
  echo ""

  # Note: You must manually loop back to Block 1b
  # The state has been updated with:
  # - ITERATION = $NEXT_ITERATION
  # - CONTINUATION_CONTEXT = $CONTINUATION_CONTEXT
  # - WORK_REMAINING = $WORK_REMAINING_NEW
  #
  # When you execute Block 1b again, it will load these updated values from state
  exit 0
else
  # Work complete or max iterations reached
  if [ -z "$WORK_REMAINING_NEW" ] || [ "$WORK_REMAINING_NEW" = "0" ]; then
    echo "All work complete!"
  elif [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
    echo "Max iterations ($MAX_ITERATIONS) reached"
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "execution_error" "Max iterations reached with work remaining" "verification_block" \
      "{\"work_remaining\": \"$WORK_REMAINING_NEW\", \"iteration\": $ITERATION}"
  else
    echo "Continuation not required"
  fi

  # Save final summary path to state
  append_workflow_state "SUMMARY_PATH" "$SUMMARY_PATH"
  append_workflow_state "REQUIRES_CONTINUATION" "false"

  echo "Proceeding to Block 1d (phase marker recovery)..."
  echo ""
fi
```

## Block 1d: Phase Marker Validation and Recovery

**EXECUTE NOW**: Validate phase markers and recover any missing [COMPLETE] markers after coordinator/implementer updates. This block only applies to plan-based mode.

**Skip Condition**: If EXECUTION_MODE=file-based, skip directly to Block 2.

```bash
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e  # Fail-fast

# === RESTORE STATE ===
load_workflow_state "$WORKFLOW_ID" 2>/dev/null || {
  echo "ERROR: Failed to restore workflow state" >&2
  exit 1
}

# === SKIP IF FILE-BASED MODE ===
if [ "$EXECUTION_MODE" = "file-based" ]; then
  echo "File-based mode: Skipping phase marker recovery"
  exit 0
fi

# === VALIDATE PLAN FILE EXISTS ===
if [ -z "$PLAN_FILE" ] || [ ! -f "$PLAN_FILE" ]; then
  echo "WARNING: Plan file not found: $PLAN_FILE" >&2
  echo "Skipping phase marker recovery"
  exit 0
fi

echo ""
echo "=== Phase Marker Validation and Recovery ==="
echo ""

# Source checkbox utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || {
  echo "ERROR: Failed to source checkbox-utils.sh" >&2
  exit 1
}

# Count total phases and phases with [COMPLETE] marker
TOTAL_PHASES=$(grep -c "^### Phase [0-9]" "$PLAN_FILE" 2>/dev/null || echo "0")
PHASES_WITH_MARKER=$(grep -c "^### Phase [0-9].*\[COMPLETE\]" "$PLAN_FILE" 2>/dev/null || echo "0")

echo "Plan File: $(basename "$PLAN_FILE")"
echo "Total phases: $TOTAL_PHASES"
echo "Phases with [COMPLETE] marker: $PHASES_WITH_MARKER"
echo ""

if [ "$TOTAL_PHASES" -eq 0 ]; then
  echo "No phases found in plan (unexpected)"
elif [ "$PHASES_WITH_MARKER" -eq "$TOTAL_PHASES" ]; then
  echo "✓ All phases marked complete by coordinator/implementer"
else
  echo "⚠ Detecting phases missing [COMPLETE] marker..."
  echo ""

  # Recovery: Find phases with all checkboxes complete but missing [COMPLETE] marker
  RECOVERED_COUNT=0
  for phase_num in $(seq 1 "$TOTAL_PHASES"); do
    # Check if phase already has [COMPLETE] marker
    if grep -q "^### Phase ${phase_num}:.*\[COMPLETE\]" "$PLAN_FILE"; then
      continue  # Already marked
    fi

    # Check if all tasks in phase are complete (no [ ] checkboxes)
    if verify_phase_complete "$PLAN_FILE" "$phase_num" 2>/dev/null; then
      echo "Recovering Phase $phase_num (all tasks complete but marker missing)..."

      # Mark all tasks complete (idempotent operation)
      mark_phase_complete "$PLAN_FILE" "$phase_num" 2>/dev/null || {
        echo "  ⚠ Task marking failed for Phase $phase_num" >&2
      }

      # Add [COMPLETE] marker to phase heading
      if add_complete_marker "$PLAN_FILE" "$phase_num" 2>/dev/null; then
        echo "  ✓ [COMPLETE] marker added"
        ((RECOVERED_COUNT++))
      else
        echo "  ⚠ [COMPLETE] marker failed for Phase $phase_num" >&2
      fi
    fi
  done

  if [ "$RECOVERED_COUNT" -gt 0 ]; then
    echo ""
    echo "✓ Recovered $RECOVERED_COUNT phase marker(s)"
  else
    echo ""
    echo "No phases needed recovery (partial completion expected)"
  fi
fi

# Verify checkbox consistency
if verify_checkbox_consistency "$PLAN_FILE" 1 2>/dev/null; then
  echo ""
  echo "✓ Checkbox hierarchy synchronized"
else
  echo ""
  echo "⚠ Checkbox hierarchy may need manual verification"
fi

# Check if all phases complete and update plan metadata
if [ "$PHASES_WITH_MARKER" -eq "$TOTAL_PHASES" ] && [ "$TOTAL_PHASES" -gt 0 ]; then
  # All phases complete - update plan metadata status
  if check_all_phases_complete "$PLAN_FILE"; then
    update_plan_status "$PLAN_FILE" "COMPLETE"
    echo "✓ Plan metadata updated to COMPLETE"
  fi
fi

# Persist validation results
append_workflow_state "PHASES_WITH_MARKER" "$PHASES_WITH_MARKER"
append_workflow_state "TOTAL_PHASES" "$TOTAL_PHASES"

echo ""
echo "Phase marker recovery complete"
echo ""
```

## Block 2: Completion & Summary

**EXECUTE NOW**: Display completion summary and emit PROOF_COMPLETE signal.

```bash
# === RESTORE STATE ===
load_workflow_state "$WORKFLOW_ID" 2>/dev/null || {
  echo "WARNING: Could not restore state, using defaults" >&2
}

# === PARSE FINAL METRICS ===
THEOREMS_PROVEN=0
THEOREMS_PARTIAL=0
SORRY_COUNT=0

if [ -f "$SUMMARY_PATH" ]; then
  # Parse summary for metrics
  THEOREMS_PROVEN=$(grep -c "Status.*COMPLETE\|✅" "$SUMMARY_PATH" 2>/dev/null || echo "0")
  THEOREMS_PARTIAL=$(grep -c "Status.*PARTIAL\|⚠" "$SUMMARY_PATH" 2>/dev/null || echo "0")
fi

# Count remaining sorry markers
if [ -n "$LEAN_FILE" ] && [ -f "$LEAN_FILE" ]; then
  SORRY_COUNT=$(grep -c "sorry" "$LEAN_FILE" 2>/dev/null || echo "0")
fi

# === CONSOLE SUMMARY ===
cat << 'EOF'
╔═══════════════════════════════════════════════════════╗
║ LEAN THEOREM PROVING COMPLETE            ║
╠═══════════════════════════════════════════════════════╣
EOF

echo "║ Theorems Proven: $THEOREMS_PROVEN"
echo "║ Theorems Partial: $THEOREMS_PARTIAL"
echo "║ File: $(basename "$LEAN_FILE")"
echo "║ Execution Mode: ${EXECUTION_MODE}"
echo "║ Iterations: ${ITERATION}/${MAX_ITERATIONS}"

if [ "$SORRY_COUNT" -eq 0 ]; then
  echo "║ Status: All proofs complete ✓"
else
  echo "║ Status: $SORRY_COUNT sorry markers remain"
fi

cat << 'EOF'
╠═══════════════════════════════════════════════════════╣
║ Artifacts:                      ║
EOF

echo "║ └─ Summary: $(basename "$SUMMARY_PATH")"

if [ -n "${CONTINUATION_CONTEXT:-}" ] && [ -f "$CONTINUATION_CONTEXT" ]; then
  echo "║ └─ Continuation: $(basename "$CONTINUATION_CONTEXT")"
fi

cat << 'EOF'
╠═══════════════════════════════════════════════════════╣
║ Next Steps:                      ║
║ 1. Review proofs in Lean file             ║
║ 2. Run lean build to verify compilation        ║
║ 3. Check summary for tactic explanations        ║
╚═══════════════════════════════════════════════════════╝
EOF

echo ""

# === EMIT COMPLETION SIGNAL ===
echo "PROOF_COMPLETE:"
echo "  summary_path: $SUMMARY_PATH"
echo "  lean_file: $LEAN_FILE"
echo "  theorems_proven: $THEOREMS_PROVEN"
echo "  theorems_partial: $THEOREMS_PARTIAL"
echo "  sorry_remaining: $SORRY_COUNT"
echo "  iterations_used: $ITERATION"
echo "  execution_mode: $EXECUTION_MODE"

# Cleanup
TEMP_FILE="${HOME}/.claude/tmp/lean_arg_$(date +%s%N).txt"
rm -f "$TEMP_FILE" "${HOME}/.claude/tmp/lean_arg_path.txt" 2>/dev/null

echo ""
echo "Lean workflow complete"
```

## Notes

### Mode-Specific Behavior

**--prove-all (default)**:
- Identifies all theorems with `sorry` markers
- Attempts to prove each theorem using lean-lsp-mcp tools
- Creates summary with all attempted proofs

**--verify**:
- Checks existing proofs without modification (max_attempts=0)
- Runs `lean_build` to verify compilation
- Checks `lean_diagnostic_messages` for errors
- Creates verification summary

### MCP Tool Integration

The lean-implementer agent uses these MCP tools:
- `lean_goal` - Extract proof goals
- `lean_leansearch` - Natural language theorem search
- `lean_loogle` - Type-based theorem search
- `lean_multi_attempt` - Multi-proof screening
- `lean_build` - Project compilation
- `lean_diagnostic_messages` - Error checking

### Error Handling

Errors are logged to `.claude/data/logs/errors.jsonl` with:
- **validation_error**: Invalid arguments, missing files
- **dependency_error**: MCP server not available, not a Lean project
- **agent_error**: lean-implementer failure
- **execution_error**: Proof incomplete, diagnostics errors
- **file_error**: File not found

### Integration with /plan and /test

1. **Create plan**: `/plan "Formalize TM modal axioms in Lean"`
2. **Prove theorems**: `/lean path/to/plan.md --prove-all`
3. **Verify compilation**: `cd project && lake build`

## Success Criteria

Workflow is successful if:
- ✅ lean-implementer agent invoked correctly
- ✅ Summary created in summaries directory (≥100 bytes)
- ✅ Proof completion tracked (theorems_proven count)
- ✅ Diagnostics checked and reported
- ✅ All errors logged to errors.jsonl
