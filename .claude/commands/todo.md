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

### Sections and Classification

TODO.md is organized into seven sections following strict hierarchy as defined in [TODO Organization Standards](../.claude/docs/reference/standards/todo-organization-standards.md):

| Section | Purpose | Checkbox | Auto-Updated | Preservation Policy |
|---------|---------|----------|--------------|---------------------|
| **In Progress** | Active implementation | `[x]` | Yes | Regenerated from plan status |
| **Not Started** | Planned but not begun | `[ ]` | Yes | Regenerated from plan status |
| **Research** | Research-only projects (no plans) | `[ ]` | Yes | Auto-detected from directory scan |
| **Saved** | Intentionally demoted items | `[ ]` | No | **Preserved** (manual curation) |
| **Backlog** | Manual prioritization queue | `[ ]` | No | **Preserved** (manual curation) |
| **Abandoned** | Intentionally discontinued | `[x]` or `[~]` | Yes | Regenerated from plan status |
| **Completed** | Successfully finished | `[x]` | Yes | **Regenerated** with today's date |

**Status Classification Algorithm**:

Plans are classified using a two-tier algorithm:
1. **Primary**: Check plan metadata `Status:` field for explicit values (COMPLETE, IN PROGRESS, NOT STARTED, SUPERSEDED, ABANDONED)
2. **Fallback**: Analyze phase completion markers if Status field is missing or ambiguous

**Research Section Auto-Detection**:

The Research section is auto-populated from research-only directories:
- Directory has `reports/` subdirectory with markdown files
- Directory has NO `plans/` subdirectory (or plans/ is empty)
- Entry links to topic directory (not plan file)
- Title and description extracted from first report file
- Typical sources: `/research` and `/errors` command outputs

**Saved Section Preservation Policy**:

The Saved section is manually curated for intentional item demotion:
- Items moved here manually when temporarily deprioritized
- Content is **never regenerated** - preserved verbatim
- Useful for "not abandoned but not active" items
- Distinguishes from permanent abandonment

**Backlog Preservation Policy**:

The Backlog section is manually curated and **never regenerated**. When /todo updates TODO.md:
- Existing Backlog content is extracted and preserved verbatim
- Structure within Backlog is user-defined (categories, priorities, etc.)
- /todo only updates the other auto-updated sections based on plan classification

**Completed Section Behavior**:

The Completed section is **completely regenerated** each time /todo runs:
- All entries are grouped under the current date
- Historical completion dates are not preserved
- Previous Completed section content is replaced
- This ensures Completed section reflects current classification results

**Related Artifacts**:

Each plan entry includes related artifacts as indented bullets:
- Reports: Analysis and research documents from the plan's topic
- Summaries: Implementation summaries documenting completion status
- Format: `  - [Report|Summary]: {relative-path}`

See [TODO Organization Standards](../.claude/docs/reference/standards/todo-organization-standards.md) for complete specification.

### Clean Mode
When invoked with `--clean` flag, identifies all cleanup-eligible projects (Completed and Abandoned sections) and directly removes them after creating a git commit. Recovery is possible via git revert. No age threshold applied. Note: Superseded entries are merged into Abandoned section per 7-section standards.

## Options

- `--clean` - Directly remove cleanup-eligible projects (Completed, Abandoned) after git commit
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

# === DETECT MIGRATION NEED (6-section to 7-section) ===
TODO_MIGRATION_NEEDED="false"
if [ -f "$TODO_PATH" ]; then
  # Check if TODO.md is missing Research or Saved sections
  if ! grep -q "^## Research" "$TODO_PATH" || ! grep -q "^## Saved" "$TODO_PATH"; then
    TODO_MIGRATION_NEEDED="true"
    echo "Detected old 6-section format - migration required"
    echo "Missing sections: Research and/or Saved"
    echo ""
  fi
fi

# === BACKUP EXISTING TODO.MD ===
if [ -f "$TODO_PATH" ]; then
  if [ "$TODO_MIGRATION_NEEDED" = "true" ]; then
    # Create migration backup
    cp "$TODO_PATH" "${TODO_PATH}.pre-migration-backup"
    echo "Created migration backup: ${TODO_PATH}.pre-migration-backup"
    echo "Recovery: cp ${TODO_PATH}.pre-migration-backup $TODO_PATH"
  else
    # Standard backup
    cp "$TODO_PATH" "${TODO_PATH}.backup"
    echo "Backed up existing TODO.md"
  fi
fi

# === PERSIST MIGRATION FLAG ===
append_workflow_state "TODO_MIGRATION_NEEDED" "$TODO_MIGRATION_NEEDED"

echo ""
echo "TODO.md generation ready"
echo "Proceeding to write file..."
```

## Block 4: Write TODO.md File

**EXECUTE NOW**: Write the generated TODO.md content to file.

Based on the classified plans from todo-analyzer, generate the TODO.md content with proper section organization:

1. Read classified plans from Block 2 output
2. Auto-detect research-only directories (reports/ but no plans/)
3. Group plans by section (In Progress, Not Started, Research, Saved, Backlog, Abandoned, Completed)
4. Preserve existing Backlog and Saved section content
5. Generate entries with proper checkbox conventions
6. Include related artifacts (reports, summaries) as indented bullets
7. Write to TODO.md (or display if --dry-run)

Generate the TODO.md content following the standards in `.claude/docs/reference/standards/todo-organization-standards.md`:

- Section order: In Progress -> Not Started -> Research -> Saved -> Backlog -> Abandoned -> Completed
- Checkboxes: [ ] for Not Started/Research/Saved/Backlog, [x] for In Progress/Completed/Abandoned, [~] for Superseded (merged into Abandoned)
- Entry format: `- [checkbox] **{Title}** - {Description} [{path}]`
- Research entries link to directory: `[.claude/specs/NNN_topic/]`
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

If CLEAN_MODE is true, instead of updating TODO.md, directly remove all projects marked as cleanup-eligible (Completed and Abandoned sections) after creating a mandatory git commit for recovery. TODO.md is NOT modified during cleanup - it reflects the current filesystem state after next scan. Note: Superseded entries are now merged into Abandoned section per 7-section standards.

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

  # Parse TODO.md sections directly (section-based cleanup)
  TODO_PATH="${CLAUDE_PROJECT_DIR}/.claude/TODO.md"
  if [ -f "$TODO_PATH" ]; then
    ELIGIBLE_PROJECTS=$(parse_todo_sections "$TODO_PATH")
    ELIGIBLE_COUNT=$(echo "$ELIGIBLE_PROJECTS" | jq 'length')

    echo "Eligible projects: $ELIGIBLE_COUNT"
    echo ""

    if [ "$ELIGIBLE_COUNT" -gt 0 ]; then
      echo "Cleanup candidates (grouped by section):"
      echo ""

      # Display entries grouped by section
      for section in "Completed" "Abandoned" "Superseded"; do
        SECTION_PROJECTS=$(echo "$ELIGIBLE_PROJECTS" | jq -c "[.[] | select(.section == \"$section\")]")
        SECTION_COUNT=$(echo "$SECTION_PROJECTS" | jq 'length')

        if [ "$SECTION_COUNT" -gt 0 ]; then
          echo "$section ($SECTION_COUNT projects):"

          # Display first 10 entries per section
          echo "$SECTION_PROJECTS" | jq -r '.[:10][] | "  - \(.topic_name)"'

          # If more than 10, show count of remaining
          if [ "$SECTION_COUNT" -gt 10 ]; then
            REMAINING=$((SECTION_COUNT - 10))
            echo "  ... ($REMAINING more)"
          fi
          echo ""
        fi
      done
    else
      echo "No cleanup candidates found."
      echo "All projects are either In Progress, Not Started, or in Backlog."
    fi

    echo ""
    echo "To execute cleanup (with git commit), run: /todo --clean"
    exit 0
  else
    echo "ERROR: TODO.md not found at $TODO_PATH" >&2
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

# === PARSE TODO.md SECTIONS FOR CLEANUP ===
# Section-based cleanup: Reads directly from TODO.md sections (Completed, Abandoned, Superseded)
# This honors manual categorization in TODO.md rather than relying on plan file classification
TODO_PATH="${CLAUDE_PROJECT_DIR}/.claude/TODO.md"
if [ ! -f "$TODO_PATH" ]; then
  log_command_error "file_error" "TODO.md not found: $TODO_PATH" "Block4b:FileCheck"
  echo "ERROR: TODO.md not found at $TODO_PATH" >&2
  exit 1
fi

ELIGIBLE_PROJECTS=$(parse_todo_sections "$TODO_PATH")
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

### Block 4c: Regenerate TODO.md After Cleanup (Clean Mode)

**EXECUTE AFTER Block 4b completes**: Regenerate TODO.md to reflect current filesystem state.

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

# === RESTORE STATE ===
STATE_FILE=$(ls -t ~/.claude/data/state/todo_*.state 2>/dev/null | head -1)
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE" 2>/dev/null || {
    log_command_error "state_error" "Failed to restore state from $STATE_FILE" "Block4c:StateRestore"
    echo "ERROR: Failed to restore state" >&2
    exit 1
  }
else
  log_command_error "state_error" "State file not found" "Block4c:StateRestore"
  echo "ERROR: State file not found" >&2
  exit 1
fi

# === REGENERATE TODO.MD ===
# After cleanup removes directories, rescan filesystem and regenerate TODO.md
# This ensures TODO.md only contains entries for existing projects

TODO_PATH="${CLAUDE_PROJECT_DIR}/.claude/TODO.md"

# Only regenerate if cleanup removed projects
if [ "${REMOVED_COUNT:-0}" -gt 0 ]; then
  echo ""
  echo "Regenerating TODO.md to reflect current filesystem state..."

  # Extract and preserve Backlog section before regeneration
  EXISTING_BACKLOG=$(extract_backlog_section "$TODO_PATH")

  # Rescan project directories
  SPECS_ROOT="${CLAUDE_PROJECT_DIR}/.claude/specs"
  SCANNED_PROJECTS=$(scan_project_directories "$SPECS_ROOT")
  SCANNED_COUNT=$(echo "$SCANNED_PROJECTS" | jq 'length')

  echo "Found $SCANNED_COUNT remaining projects"

  # Save scanned projects to temporary file for classification
  TEMP_DISCOVERED="${CLAUDE_PROJECT_DIR}/.claude/tmp/todo_rescan_${WORKFLOW_ID}.json"
  echo "$SCANNED_PROJECTS" > "$TEMP_DISCOVERED"

  # Save temp file path for Block 4c-2 (todo-analyzer invocation)
  persist_state TEMP_DISCOVERED TODO_PATH REMOVED_COUNT SCANNED_COUNT

  echo "✓ Projects rescanned, ready for classification"
else
  echo ""
  echo "No projects removed, skipping TODO.md regeneration"

  # Persist state for Block 5 even when skipping
  persist_state TODO_PATH REMOVED_COUNT SKIPPED_COUNT FAILED_COUNT ELIGIBLE_COUNT COMMIT_HASH
fi

echo "<!-- checkpoint: todo_rescan_complete -->"
```

### Block 4c-2: Classify Remaining Projects (Clean Mode)

**CRITICAL BARRIER**: This block MUST invoke todo-analyzer via Task tool if cleanup removed projects.
**EXECUTE IF REMOVED_COUNT > 0**: Invoke todo-analyzer to classify remaining projects after cleanup.

Task {
  subagent_type: "general-purpose"
  model: "haiku"
  description: "Classify remaining projects after cleanup"
  prompt: |
    Read and follow ALL instructions in: .claude/agents/todo-analyzer.md

    **YOUR TASK**: Classify status for ALL remaining plans after cleanup.

    Input Files:
    - Plans File: ${TEMP_DISCOVERED}

    Output File:
    - Classified Results: ${CLAUDE_PROJECT_DIR}/.claude/tmp/todo_classified_rescan_${WORKFLOW_ID}.json

    **EXECUTION STEPS**:
    1. Read the plans file at ${TEMP_DISCOVERED} (JSON array of remaining plans)
    2. For EACH plan in the array:
       a. Read the plan file using Read tool
       b. Extract metadata (title, status, description, phases)
       c. Classify status using algorithm in todo-analyzer.md
       d. Determine TODO.md section (Completed, In Progress, Not Started, Superseded, Abandoned)
    3. Build a JSON array of ALL classified results
    4. Write the complete array to ${CLAUDE_PROJECT_DIR}/.claude/tmp/todo_classified_rescan_${WORKFLOW_ID}.json

    **OUTPUT FORMAT**:
    Write JSON array to output file with this structure:
    [
      {
        "topic_name": "027_auth_implementation",
        "plan_path": ".claude/specs/027_auth_implementation/plans/027_auth_implementation.md",
        "status": "in_progress",
        "title": "Authentication System",
        "description": "Brief description",
        "phases_complete": 2,
        "phases_total": 5
      },
      ...
    ]

    IMPORTANT: Process ALL plans and write complete results array.
}

### Block 4c-3: Generate and Write TODO.md (Clean Mode)

**EXECUTE AFTER Block 4c-2 completes**: Generate TODO.md content and write file.

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

# === RESTORE STATE ===
STATE_FILE=$(ls -t ~/.claude/data/state/todo_*.state 2>/dev/null | head -1)
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE" 2>/dev/null || {
    log_command_error "state_error" "Failed to restore state from $STATE_FILE" "Block4c3:StateRestore"
    echo "ERROR: Failed to restore state" >&2
    exit 1
  }
else
  log_command_error "state_error" "State file not found" "Block4c3:StateRestore"
  echo "ERROR: State file not found" >&2
  exit 1
fi

# === GENERATE AND WRITE TODO.MD ===
# Only execute if projects were removed in Block 4b
if [ "${REMOVED_COUNT:-0}" -gt 0 ]; then
  TODO_PATH="${CLAUDE_PROJECT_DIR}/.claude/TODO.md"
  CLASSIFIED_RESULTS="${CLAUDE_PROJECT_DIR}/.claude/tmp/todo_classified_rescan_${WORKFLOW_ID}.json"

  # Verify classified results exist
  if [ ! -f "$CLASSIFIED_RESULTS" ]; then
    log_command_error "file_error" "Classified results not found: $CLASSIFIED_RESULTS" "Block4c3:FileCheck"
    echo "ERROR: Classified results file not found" >&2
    exit 1
  fi

  # Extract and preserve Backlog section
  EXISTING_BACKLOG=$(extract_backlog_section "$TODO_PATH")

  # Generate TODO.md content
  TODO_CONTENT=$(generate_todo_content "$(cat "$CLASSIFIED_RESULTS")" "$EXISTING_BACKLOG")

  # Write TODO.md
  echo "$TODO_CONTENT" > "$TODO_PATH"

  echo "✓ TODO.md regenerated successfully"
  echo "✓ Removed stale entries for deleted projects"
else
  echo ""
  echo "No projects removed, skipping TODO.md regeneration"
fi

# === PERSIST STATE FOR BLOCK 5 ===
persist_state TODO_PATH REMOVED_COUNT SKIPPED_COUNT FAILED_COUNT ELIGIBLE_COUNT COMMIT_HASH

echo "<!-- checkpoint: todo_regeneration_complete -->"
```

### Block 5: Standardized Completion Output (Clean Mode)

**EXECUTE AFTER Block 4c-3 completes**: Generate 4-section console summary with execution results.

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
  SUMMARY_TEXT="Removed ${REMOVED_COUNT:-0} eligible projects after git commit ${COMMIT_HASH:0:8}. TODO.md regenerated to reflect current filesystem state. Skipped ${SKIPPED_COUNT:-0} projects with uncommitted changes. Failed: ${FAILED_COUNT:-0}."

  TODO_PATH="${TODO_PATH:-${CLAUDE_PROJECT_DIR}/.claude/TODO.md}"
  ARTIFACTS="  📝 Git Commit: $COMMIT_HASH
  ✓ Removed: ${REMOVED_COUNT:-0} projects
  📄 TODO.md: $TODO_PATH (updated)
  ⚠ Skipped: ${SKIPPED_COUNT:-0} projects (uncommitted changes)
  ✗ Failed: ${FAILED_COUNT:-0} projects"

  NEXT_STEPS="  • Review TODO.md sections (In Progress, Not Started, Backlog)
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
