---
allowed-tools: Task, Write, Glob, Bash, Read
description: Scan specs directories and update TODO.md with current project status
argument-hint: [--clean] [--dry-run]
command-type: utility
dependent-agents:
  - todo-analyzer
library-requirements:
  - error-handling.sh: ">=1.0.0"
  - unified-location-detection.sh: ">=1.0.0"
  - todo-functions.sh: ">=1.0.0"
documentation: See .claude/docs/guides/commands/todo-command-guide.md for complete usage guide
---

# /todo Command

**YOUR ROLE**: Scan specs/ directories and update .claude/TODO.md with current project status.

**YOU MUST** determine the operation mode based on flags provided:
- **Default Mode** (no --clean flag): Scan projects and update TODO.md
- **Clean Mode** (--clean flag): Directly remove cleanup-eligible projects (Completed, Abandoned, Superseded) after git commit

## Usage

```
/todo [options]
```

## Modes

### Default Mode (Update TODO.md)
When invoked without `--clean` flag, scans all specs/ directories, classifies plan status, and updates TODO.md.

### Clean Mode
When invoked with `--clean` flag, identifies all cleanup-eligible projects (Completed, Abandoned, and Superseded sections) and directly removes them after creating a git commit. Recovery is possible via git revert. No age threshold applied.

## Options

- `--clean` - Directly remove cleanup-eligible projects (Completed, Abandoned, Superseded) after git commit
- `--dry-run` - Preview changes without modifying files (no git commit, no directory removal)

## Examples

```bash
# Update TODO.md with current project status
/todo

# Preview changes without modifying files
/todo --dry-run

# Directly remove completed projects after git commit
/todo --clean

# Preview cleanup (shows eligible projects without removing)
/todo --clean --dry-run
```

## EXECUTE NOW: Block 1 - Setup and Discovery

```bash
set +H  # CRITICAL: Disable history expansion
set -e  # Fail-fast per code-standards.md

# === PRE-TRAP ERROR BUFFER ===
declare -a _EARLY_ERROR_BUFFER=()

# === PARSE ARGUMENTS ===
CLEAN_MODE="false"
DRY_RUN="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --clean)
      CLEAN_MODE="true"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

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
  _EARLY_ERROR_BUFFER+=("validation_error|Project directory not found or unset|CLAUDE_PROJECT_DIR environment variable must be set")
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
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || {
  echo "ERROR: Failed to source unified-location-detection.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}

# Tier 2: Command-Specific (graceful degradation)
# NOTE: /todo is a utility command - does NOT require workflow-state-machine.sh
# Research state machine (sm_init/sm_transition) is only for research workflows
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
  echo "ERROR: Failed to source todo-functions.sh" >&2
  exit 1
}

# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists

# Generate workflow ID
WORKFLOW_ID="todo_$(date +%s)"
COMMAND_NAME="/todo"
USER_ARGS="$([ "$CLEAN_MODE" = "true" ] && echo "--clean")$([ "$DRY_RUN" = "true" ] && echo " --dry-run")"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === LOCATE TODO.MD AND SPECS ROOT ===
SPECS_ROOT="${CLAUDE_SPECS_ROOT:-${CLAUDE_PROJECT_DIR}/.claude/specs}"
TODO_PATH="${CLAUDE_PROJECT_DIR}/.claude/TODO.md"

if [ ! -d "$SPECS_ROOT" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "file_error" "Specs directory not found: $SPECS_ROOT" \
    "Block1:SpecsValidation" \
    '{"expected_dir":"'"$SPECS_ROOT"'"}'
  echo "ERROR: Specs directory not found: $SPECS_ROOT" >&2
  exit 1
fi

# === SCAN PROJECTS ===
echo "=== /todo Command ==="
echo ""
echo "Mode: $([ "$CLEAN_MODE" = "true" ] && echo "Clean" || echo "Update")"
echo "Dry Run: $DRY_RUN"
echo ""
echo "Scanning projects..."

# Collect topic directories
TOPICS=$(scan_project_directories)
TOPIC_COUNT=$(echo "$TOPICS" | grep -c "^" || echo "0")

echo "Found $TOPIC_COUNT topic directories"
echo ""

# Store discovered projects for next block
DISCOVERED_PROJECTS="${CLAUDE_PROJECT_DIR}/.claude/tmp/todo_projects_${WORKFLOW_ID}.json"
mkdir -p "$(dirname "$DISCOVERED_PROJECTS")"

# Initialize JSON array
echo "[]" > "$DISCOVERED_PROJECTS"

# Process each topic to find plans
PROJECT_INDEX=0
while IFS= read -r topic; do
  [ -z "$topic" ] && continue

  # Find plans in this topic
  PLANS=$(find_plans_in_topic "$topic")
  while IFS= read -r plan_path; do
    [ -z "$plan_path" ] && continue
    [ ! -f "$plan_path" ] && continue

    # Get topic path
    TOPIC_PATH=$(get_topic_path "$topic")

    # Store for batch processing
    jq --arg path "$plan_path" --arg topic "$TOPIC_PATH" --arg name "$topic" \
       '. += [{"plan_path": $path, "topic_path": $topic, "topic_name": $name}]' \
       "$DISCOVERED_PROJECTS" > "${DISCOVERED_PROJECTS}.tmp"
    mv "${DISCOVERED_PROJECTS}.tmp" "$DISCOVERED_PROJECTS"

    PROJECT_INDEX=$((PROJECT_INDEX + 1))
  done <<< "$PLANS"
done <<< "$TOPICS"

echo "Found $PROJECT_INDEX plan files to analyze"
echo ""

# === NOTE: /todo is a utility command ===
# Utility commands do NOT use the research state machine (sm_init/sm_transition)
# State machine is for research workflows: research-only, research-and-plan, full-implementation
# Error handling is already configured via setup_bash_error_trap above

# Output for next block
echo "WORKFLOW_ID=$WORKFLOW_ID"
echo "SPECS_ROOT=$SPECS_ROOT"
echo "TODO_PATH=$TODO_PATH"
echo "DISCOVERED_PROJECTS=$DISCOVERED_PROJECTS"
echo "CLEAN_MODE=$CLEAN_MODE"
echo "DRY_RUN=$DRY_RUN"
```

## Block 2a: Status Classification Setup

```bash
set +H  # CRITICAL: Disable history expansion
set -e  # Fail-fast per code-standards.md

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
export CLAUDE_PROJECT_DIR

# === SOURCE LIBRARIES (Three-Tier Pattern) ===
# Tier 1: Critical Foundation (fail-fast required)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}

# NOTE: /todo is a utility command - does NOT use research state machine (sm_init/sm_transition)

# === PRE-CALCULATE PATHS ===
# Pre-calculate paths for todo-analyzer subagent
CLASSIFIED_RESULTS="${CLAUDE_PROJECT_DIR}/.claude/tmp/todo_classified_${WORKFLOW_ID}.json"
mkdir -p "$(dirname "$CLASSIFIED_RESULTS")"

# Initialize results file
echo "[]" > "$CLASSIFIED_RESULTS"

# === PERSIST VARIABLES ===
# Persist variables for Block 2c verification
append_workflow_state "DISCOVERED_PROJECTS" "$DISCOVERED_PROJECTS"
append_workflow_state "CLASSIFIED_RESULTS" "$CLASSIFIED_RESULTS"
append_workflow_state "SPECS_ROOT" "$SPECS_ROOT"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"

echo ""
echo "=== Status Classification Setup ==="
echo "Discovered projects: $DISCOVERED_PROJECTS"
echo "Classification output: $CLASSIFIED_RESULTS"
echo ""
echo "[CHECKPOINT] Setup complete - ready for todo-analyzer invocation"
```

## Block 2b: Status Classification Execution

**CRITICAL BARRIER**: This block MUST invoke todo-analyzer via Task tool.
Verification block (2c) will FAIL if classified results not created.

**EXECUTE NOW**: Invoke todo-analyzer subagent for batch plan classification.

The todo-analyzer must process ALL plans discovered in Block 1. Read the plans file at ${DISCOVERED_PROJECTS}, classify each plan's status, and write results to ${CLASSIFIED_RESULTS}.

Task {
  subagent_type: "general-purpose"
  model: "haiku"
  description: "Classify plan statuses for TODO.md organization"
  prompt: |
    Read and follow ALL instructions in: .claude/agents/todo-analyzer.md

    **YOUR TASK**: Classify status for ALL plans in the discovered projects file.

    Input Files:
    - Plans File: ${DISCOVERED_PROJECTS}
    - Specs Root: ${SPECS_ROOT}
    - Output File: ${CLASSIFIED_RESULTS}

    **EXECUTION STEPS**:
    1. Read the plans file at ${DISCOVERED_PROJECTS} (JSON array of discovered plans)
    2. For EACH plan in the array:
       a. Read the plan file using Read tool
       b. Extract metadata (title, status, description, phases)
       c. Classify status using algorithm in todo-analyzer.md
       d. Determine TODO.md section (Completed, In Progress, Not Started, Superseded, Abandoned)
    3. Build a JSON array of ALL classified results
    4. Write the complete array to ${CLASSIFIED_RESULTS}

    **OUTPUT FORMAT**:
    Write a JSON array to ${CLASSIFIED_RESULTS} with this structure:
    [
      {
        "plan_path": "/absolute/path/to/plan.md",
        "topic_path": "/absolute/path/to/topic",
        "topic_name": "NNN_topic_name",
        "title": "Plan Title",
        "description": "Brief description (max 100 chars)",
        "status": "completed|in_progress|not_started|superseded|abandoned",
        "phases_complete": <number>,
        "phases_total": <number>,
        "section": "Completed|In Progress|Not Started|Superseded|Abandoned"
      },
      ...
    ]

    **RETURN SIGNAL**:
    After writing the results file, return:
    PLANS_CLASSIFIED: ${CLASSIFIED_RESULTS}
    plan_count: <number of plans classified>
}

## Block 2c: Status Classification Verification

```bash
set +H  # CRITICAL: Disable history expansion
set -e  # Fail-fast per code-standards.md

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
export CLAUDE_PROJECT_DIR

# === SOURCE LIBRARIES ===
# Re-source libraries (subprocess isolation requires re-sourcing)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}

# === RESTORE PERSISTED VARIABLES ===
# Restore variables persisted in Block 2a
STATE_FILE=$(ls -t ~/.claude/data/state/todo_*.state 2>/dev/null | head -1)
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE" 2>/dev/null || true
else
  # State file not found - log error with proper signature
  COMMAND_NAME="/todo"
  WORKFLOW_ID="todo_unknown"
  USER_ARGS=""
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "state_error" "State file not found - cannot restore variables" \
    "Block2c:StateRestore" \
    '{"expected_pattern":"~/.claude/data/state/todo_*.state"}'
  echo "ERROR: State file not found" >&2
  exit 1
fi

echo ""
echo "=== Status Classification Verification ==="
echo ""

# === VERIFY CLASSIFIED RESULTS FILE EXISTS ===
if [ ! -f "$CLASSIFIED_RESULTS" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "verification_error" "Classified results file not found: $CLASSIFIED_RESULTS" \
    "Block2c:Verification" \
    '{"expected_file":"'"$CLASSIFIED_RESULTS"'","recovery":"Re-run /todo command"}'
  echo "ERROR: VERIFICATION FAILED - Classified results file missing" >&2
  echo "Expected: $CLASSIFIED_RESULTS" >&2
  echo "Recovery: Re-run /todo command, check todo-analyzer agent logs" >&2
  exit 1
fi

# === VERIFY FILE SIZE ===
FILE_SIZE=$(stat -f%z "$CLASSIFIED_RESULTS" 2>/dev/null || stat -c%s "$CLASSIFIED_RESULTS" 2>/dev/null || echo "0")
if [ "$FILE_SIZE" -lt 10 ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "verification_error" "Classified results file is too small: $FILE_SIZE bytes" \
    "Block2c:Verification" \
    '{"file":"'"$CLASSIFIED_RESULTS"'","size":'"$FILE_SIZE"',"minimum":10}'
  echo "ERROR: VERIFICATION FAILED - Classified results file is empty or too small" >&2
  echo "File: $CLASSIFIED_RESULTS" >&2
  echo "Size: $FILE_SIZE bytes (expected > 10)" >&2
  echo "Recovery: Verify todo-analyzer completed successfully, check for errors" >&2
  exit 1
fi

# === VERIFY JSON VALIDITY ===
if ! jq empty "$CLASSIFIED_RESULTS" 2>/dev/null; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "verification_error" "Classified results file contains invalid JSON" \
    "Block2c:Verification" \
    '{"file":"'"$CLASSIFIED_RESULTS"'"}'
  echo "ERROR: VERIFICATION FAILED - Invalid JSON in classified results" >&2
  echo "File: $CLASSIFIED_RESULTS" >&2
  echo "Recovery: Check todo-analyzer output format, validate JSON syntax" >&2
  exit 1
fi

# === COUNT CLASSIFIED PLANS ===
PLAN_COUNT=$(jq 'length' "$CLASSIFIED_RESULTS" 2>/dev/null || echo "0")
if [ "$PLAN_COUNT" -eq 0 ]; then
  # This is a warning, not an error - empty specs/ directory is valid
  echo "WARNING: No plans classified (empty result set)" >&2
  echo "This may be normal if specs/ directory has no plans" >&2
fi

# === PERSIST PLAN COUNT ===
append_workflow_state "PLAN_COUNT" "$PLAN_COUNT"

echo "Classified results verified: $CLASSIFIED_RESULTS"
echo "Plan count: $PLAN_COUNT"
echo ""
echo "[CHECKPOINT] Verification complete - $PLAN_COUNT plans classified"
```

## Block 3: Generate TODO.md

**EXECUTE NOW**: Generate the updated TODO.md content based on classified plans.

```bash
set +H  # CRITICAL: Disable history expansion
set -e  # Fail-fast

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
export CLAUDE_PROJECT_DIR

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || exit 1

# === RESTORE STATE ===
# Restore variables from Block 2c
STATE_FILE=$(ls -t ~/.claude/data/state/todo_*.state 2>/dev/null | head -1)
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE" 2>/dev/null || true
else
  COMMAND_NAME="/todo"
  WORKFLOW_ID="todo_unknown"
  USER_ARGS=""
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "state_error" "State file not found - cannot restore variables" \
    "Block3:StateRestore" \
    '{"expected_pattern":"~/.claude/data/state/todo_*.state"}'
  echo "ERROR: State file not found" >&2
  exit 1
fi

# NOTE: /todo is a utility command - does NOT use research state machine (sm_transition)

TODO_PATH="${CLAUDE_PROJECT_DIR}/.claude/TODO.md"

echo ""
echo "=== Generating TODO.md ==="
echo ""

# === VERIFY CLASSIFIED RESULTS AVAILABLE ===
# Fail-fast if classified results missing (hard barrier enforcement)
if [ ! -f "$CLASSIFIED_RESULTS" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "verification_error" "Classified results file not found: $CLASSIFIED_RESULTS" \
    "Block3:Verification" \
    '{"expected_file":"'"$CLASSIFIED_RESULTS"'"}'
  echo "ERROR: Classified results file missing" >&2
  echo "Expected: $CLASSIFIED_RESULTS" >&2
  echo "Recovery: Re-run /todo command, verify Block 2c completed successfully" >&2
  exit 1
fi

echo "Reading classified plans from: $CLASSIFIED_RESULTS"
echo "TODO.md path: $TODO_PATH"
echo ""

# === BACKUP EXISTING TODO.MD ===
if [ -f "$TODO_PATH" ]; then
  cp "$TODO_PATH" "${TODO_PATH}.backup"
  echo "Backed up existing TODO.md"
fi

echo ""
echo "TODO.md generation ready"
echo "Proceeding to write file..."
```

## Block 4: Write TODO.md File

**EXECUTE NOW**: Write the generated TODO.md content to file.

Based on the classified plans from todo-analyzer, generate the TODO.md content with proper section organization:

1. Read classified plans from Block 2 output
2. Group plans by section (In Progress, Not Started, Backlog, Superseded, Abandoned, Completed)
3. Preserve existing Backlog section content
4. Generate entries with proper checkbox conventions
5. Include related artifacts (reports, summaries) as indented bullets
6. Write to TODO.md (or display if --dry-run)

Generate the TODO.md content following the standards in `.claude/docs/reference/standards/todo-organization-standards.md`:

- Section order: In Progress -> Not Started -> Backlog -> Superseded -> Abandoned -> Completed
- Checkboxes: [ ] for Not Started, [x] for In Progress/Completed/Abandoned, [~] for Superseded
- Entry format: `- [checkbox] **{Title}** - {Description} [{path}]`
- Artifacts as indented bullets under each plan
- Date grouping for Completed section

If --dry-run is set, display the generated content instead of writing.

```bash
set +H  # CRITICAL: Disable history expansion
set -e  # Fail-fast

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
export CLAUDE_PROJECT_DIR

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || exit 1

# === RESTORE STATE ===
STATE_FILE=$(ls -t ~/.claude/data/state/todo_*.state 2>/dev/null | head -1)
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE" 2>/dev/null || true
else
  COMMAND_NAME="/todo"
  WORKFLOW_ID="todo_unknown"
  USER_ARGS=""
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "state_error" "State file not found - cannot restore variables" \
    "Block4:StateRestore" \
    '{"expected_pattern":"~/.claude/data/state/todo_*.state"}'
  echo "ERROR: State file not found" >&2
  exit 1
fi

# NOTE: /todo is a utility command - does NOT use research state machine (sm_transition)

TODO_PATH="${CLAUDE_PROJECT_DIR}/.claude/TODO.md"
DRY_RUN="${DRY_RUN:-false}"

echo ""
echo "=== Writing TODO.md ==="
echo ""

# Verify classified results still available
if [ ! -f "$CLASSIFIED_RESULTS" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "file_error" "Classified results file not found: $CLASSIFIED_RESULTS" \
    "Block4:Verification" \
    '{"expected_file":"'"$CLASSIFIED_RESULTS"'"}'
  echo "ERROR: Classified results file missing" >&2
  exit 1
fi

if [ "$DRY_RUN" = "true" ]; then
  echo "[DRY RUN] Would write to: $TODO_PATH"
  echo "Preview of changes would be shown here"
else
  echo "TODO.md updated successfully"
  echo "Path: $TODO_PATH"
fi

echo ""
echo "TODO_UPDATED"
echo "  path: $TODO_PATH"
echo "  dry_run: $DRY_RUN"
```

## Clean Mode (--clean flag)

If CLEAN_MODE is true, instead of updating TODO.md, directly remove all projects marked as cleanup-eligible (Completed, Abandoned, and Superseded sections) after creating a mandatory git commit for recovery. TODO.md is NOT modified during cleanup - it reflects the current filesystem state after next scan.

### Block 4a: Dry-Run Preview (Clean Mode)

**EXECUTE IF CLEAN_MODE=true AND DRY_RUN=true**: Preview cleanup candidates without executing removal.

```bash
set +H  # CRITICAL: Disable history expansion
set -e  # Fail-fast per code-standards.md

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
export CLAUDE_PROJECT_DIR

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || exit 1

# === RESTORE STATE ===
STATE_FILE=$(ls -t ~/.claude/data/state/todo_*.state 2>/dev/null | head -1)
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE" 2>/dev/null || true
else
  echo "ERROR: State file not found" >&2
  exit 1
fi

# Check if dry-run mode for clean
if [ "$CLEAN_MODE" = "true" ] && [ "$DRY_RUN" = "true" ]; then
  echo ""
  echo "=== Cleanup Preview (Dry Run) ==="
  echo ""

  # Filter eligible projects using filter_completed_projects()
  if [ -f "$CLASSIFIED_RESULTS" ]; then
    CLASSIFIED_JSON=$(cat "$CLASSIFIED_RESULTS")
    ELIGIBLE_PROJECTS=$(filter_completed_projects "$CLASSIFIED_JSON")
    ELIGIBLE_COUNT=$(echo "$ELIGIBLE_PROJECTS" | jq 'length')

    echo "Eligible projects: $ELIGIBLE_COUNT"
    echo ""

    if [ "$ELIGIBLE_COUNT" -gt 0 ]; then
      echo "Cleanup candidates (would be archived):"

      # Display project list with titles
      echo "$ELIGIBLE_PROJECTS" | jq -r '.[] | "  - \(.topic_name): \(.title // "Untitled")"' | head -20

      # If more than 20, show count of remaining
      if [ "$ELIGIBLE_COUNT" -gt 20 ]; then
        REMAINING=$((ELIGIBLE_COUNT - 20))
        echo "  ... ($REMAINING more)"
      fi
    else
      echo "No cleanup candidates found."
      echo "All projects are either In Progress, Not Started, or in Backlog."
    fi

    echo ""
    echo "To execute cleanup (with git commit), run: /todo --clean"
    exit 0
  else
    echo "ERROR: Classified results not found" >&2
    exit 1
  fi
fi
```

### Block 4b: Direct Cleanup Execution (Clean Mode)

**EXECUTE IF CLEAN_MODE=true AND DRY_RUN=false**: Directly remove eligible projects after git commit.

```bash
set +H  # CRITICAL: Disable history expansion
set -e  # Fail-fast per code-standards.md

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
export CLAUDE_PROJECT_DIR

# === THREE-TIER LIBRARY SOURCING ===
# Tier 1: Core libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "Error: Cannot load error-handling library" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "Error: Cannot load state-persistence library" >&2
  exit 1
}

# Tier 3: Domain libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
  echo "Error: Cannot load todo-functions library" >&2
  exit 1
}

# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists
COMMAND_NAME="/todo"
WORKFLOW_ID="todo_cleanup_$(date +%s)"
USER_ARGS="--clean"

# === RESTORE STATE ===
STATE_FILE=$(ls -t ~/.claude/data/state/todo_*.state 2>/dev/null | head -1)
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE" 2>/dev/null || {
    log_command_error "state_error" "Failed to restore state from $STATE_FILE" "Block4b:StateRestore"
    echo "ERROR: Failed to restore state" >&2
    exit 1
  }
else
  log_command_error "state_error" "State file not found" "Block4b:StateRestore"
  echo "ERROR: State file not found" >&2
  exit 1
fi

# === FILTER ELIGIBLE PROJECTS ===
if [ ! -f "$CLASSIFIED_RESULTS" ]; then
  log_command_error "file_error" "Classified results file not found: $CLASSIFIED_RESULTS" "Block4b:FileCheck"
  echo "ERROR: Classified results not found" >&2
  exit 1
fi

CLASSIFIED_JSON=$(cat "$CLASSIFIED_RESULTS")
ELIGIBLE_PROJECTS=$(filter_completed_projects "$CLASSIFIED_JSON")
ELIGIBLE_COUNT=$(echo "$ELIGIBLE_PROJECTS" | jq 'length')

# === EXIT IF NO ELIGIBLE PROJECTS ===
if [ "$ELIGIBLE_COUNT" -eq 0 ]; then
  echo "No cleanup candidates found."
  echo "All projects are either In Progress, Not Started, or in Backlog."

  # Persist state for Block 5
  REMOVED_COUNT=0
  SKIPPED_COUNT=0
  FAILED_COUNT=0
  COMMIT_HASH=""
  persist_state REMOVED_COUNT SKIPPED_COUNT FAILED_COUNT COMMIT_HASH ELIGIBLE_COUNT

  exit 0
fi

echo "Found $ELIGIBLE_COUNT cleanup-eligible projects"
echo ""

# === EXECUTE CLEANUP REMOVAL ===
# This function creates git commit, verifies status, removes directories
if ! execute_cleanup_removal "$ELIGIBLE_PROJECTS" "${CLAUDE_PROJECT_DIR}/.claude/specs"; then
  log_command_error "execution_error" "Cleanup removal failed" "Block4b:ExecuteCleanup" \
    "{\"eligible_count\":$ELIGIBLE_COUNT}"
  echo "ERROR: Cleanup execution failed" >&2
  exit 1
fi

# === PERSIST STATE FOR BLOCK 5 ===
# execute_cleanup_removal sets: COMMIT_HASH, REMOVED_COUNT, SKIPPED_COUNT, FAILED_COUNT
persist_state COMMIT_HASH REMOVED_COUNT SKIPPED_COUNT FAILED_COUNT ELIGIBLE_COUNT

echo "<!-- checkpoint: cleanup_execution_complete -->"
```

### Block 5: Standardized Completion Output (Clean Mode)

**EXECUTE AFTER Block 4b completes**: Generate 4-section console summary with execution results.

```bash
set +H  # CRITICAL: Disable history expansion
set -e  # Fail-fast per code-standards.md

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
export CLAUDE_PROJECT_DIR

# === THREE-TIER LIBRARY SOURCING ===
# Tier 1: Core libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "Error: Cannot load error-handling library" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "Error: Cannot load state-persistence library" >&2
  exit 1
}

# Tier 2: Workflow libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/summary-formatting.sh" 2>/dev/null || {
  echo "Error: Cannot load summary-formatting library" >&2
  exit 1
}

# === RESTORE STATE ===
STATE_FILE=$(ls -t ~/.claude/data/state/todo_*.state 2>/dev/null | head -1)
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE" 2>/dev/null || true
fi

# === GENERATE 4-SECTION CONSOLE SUMMARY ===
if [ -z "$COMMIT_HASH" ]; then
  # No cleanup executed (no eligible projects)
  SUMMARY_TEXT="No cleanup performed. Found 0 eligible projects."
  ARTIFACTS="  No artifacts generated"
  NEXT_STEPS="  • Rescan projects: /todo
  • Check project statuses in TODO.md"
else
  # Cleanup executed
  SUMMARY_TEXT="Removed ${REMOVED_COUNT:-0} eligible projects after git commit ${COMMIT_HASH:0:8}. Skipped ${SKIPPED_COUNT:-0} projects with uncommitted changes. Failed: ${FAILED_COUNT:-0}."

  ARTIFACTS="  📝 Git Commit: $COMMIT_HASH
  ✓ Removed: ${REMOVED_COUNT:-0} projects
  ⚠ Skipped: ${SKIPPED_COUNT:-0} projects (uncommitted changes)
  ✗ Failed: ${FAILED_COUNT:-0} projects"

  NEXT_STEPS="  • Rescan projects: /todo
  • Review changes: git show $COMMIT_HASH
  • View commit log: git log --oneline -5
  • Recovery (if needed): git revert $COMMIT_HASH"
fi

# Print standardized summary
print_artifact_summary "/todo --clean" "$SUMMARY_TEXT" "" "$ARTIFACTS" "$NEXT_STEPS"

# === EMIT COMPLETION SIGNAL ===
echo ""
echo "CLEANUP_COMPLETED: removed=${REMOVED_COUNT:-0} skipped=${SKIPPED_COUNT:-0} failed=${FAILED_COUNT:-0} commit=${COMMIT_HASH:-none}"
echo ""

exit 0
```

## Completion (Default Mode)

After successful TODO.md update (default mode without --clean):

```bash
set +H  # CRITICAL: Disable history expansion
set -e  # Fail-fast per code-standards.md

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
export CLAUDE_PROJECT_DIR

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/summary-formatting.sh" 2>/dev/null || exit 1

# === RESTORE STATE ===
STATE_FILE=$(ls -t ~/.claude/data/state/todo_*.state 2>/dev/null | head -1)
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE" 2>/dev/null || true
fi

TODO_PATH="${CLAUDE_PROJECT_DIR}/.claude/TODO.md"

# === GENERATE 4-SECTION CONSOLE SUMMARY ===
SUMMARY_TEXT="Scanned $PROJECT_INDEX project directories and updated TODO.md with current status. Projects organized by status: In Progress, Not Started, Backlog, Superseded, Abandoned, Completed."

ARTIFACTS="  📄 TODO.md: $TODO_PATH"

NEXT_STEPS="  • Review changes: cat $TODO_PATH
  • Generate cleanup plan: /todo --clean
  • Preview cleanup: /todo --clean --dry-run"

# Print standardized summary
print_artifact_summary "/todo" "$SUMMARY_TEXT" "" "$ARTIFACTS" "$NEXT_STEPS"

# === EMIT COMPLETION SIGNAL ===
echo ""
echo "TODO_UPDATED: $TODO_PATH"
echo ""

exit 0
```

## Troubleshooting

- **No specs directory**: Ensure `.claude/specs/` exists
- **Empty TODO.md**: Check if plans have valid Status metadata
- **Missing artifacts**: Reports/summaries discovered via Glob patterns
- **Backup location**: Previous TODO.md saved to `TODO.md.backup`
