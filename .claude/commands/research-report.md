---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
argument-hint: <workflow-description>
description: Research-only workflow - Creates comprehensive research reports without planning or implementation
command-type: primary
dependent-agents:
  - research-specialist
  - research-sub-supervisor
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
documentation: See .claude/docs/guides/research-report-command-guide.md for complete usage guide
---

# /research-report - Research-Only Workflow Command

YOU ARE EXECUTING a research-only workflow that creates comprehensive research reports without planning or implementation phases.

**Workflow Type**: research-only
**Terminal State**: research (after research phase complete)
**Expected Output**: Research reports in .claude/specs/NNN_topic/reports/

## Part 1: Capture Workflow Description

**EXECUTE NOW**: The user invoked `/research-report "<workflow-description>"`. Capture that description.

In the **small bash block below**, replace `YOUR_WORKFLOW_DESCRIPTION_HERE` with the actual workflow description (keeping the quotes).

**Example**: If user ran `/research-report "authentication patterns in codebase"`, change:
- FROM: `echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "$TEMP_FILE"`
- TO: `echo "authentication patterns in codebase" > "$TEMP_FILE"`

Execute this bash block with your substitution:

```bash
set +H  # CRITICAL: Disable history expansion
# SUBSTITUTE THE WORKFLOW DESCRIPTION IN THE LINE BELOW
# CRITICAL: Replace YOUR_WORKFLOW_DESCRIPTION_HERE with the actual workflow description from the user
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
# Use timestamp-based filename for concurrent execution safety
TEMP_FILE="${HOME}/.claude/tmp/research-report_arg_$(date +%s%N).txt"
echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "$TEMP_FILE"
# Save temp file path for Part 2 to read
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/research-report_arg_path.txt"
echo "Workflow description captured to $TEMP_FILE"
```

## Part 2: Read and Validate Workflow Description

**EXECUTE NOW**: Read the captured description and validate:

```bash
set +H  # CRITICAL: Disable history expansion

# Read workflow description from file (written in Part 1)
RESEARCH_REPORT_DESC_PATH_FILE="${HOME}/.claude/tmp/research-report_arg_path.txt"

if [ -f "$RESEARCH_REPORT_DESC_PATH_FILE" ]; then
  RESEARCH_REPORT_DESC_FILE=$(cat "$RESEARCH_REPORT_DESC_PATH_FILE")
else
  # Fallback to legacy fixed filename for backward compatibility
  RESEARCH_REPORT_DESC_FILE="${HOME}/.claude/tmp/research-report_arg.txt"
fi

if [ -f "$RESEARCH_REPORT_DESC_FILE" ]; then
  WORKFLOW_DESCRIPTION=$(cat "$RESEARCH_REPORT_DESC_FILE" 2>/dev/null || echo "")
else
  echo "ERROR: Workflow description file not found: $RESEARCH_REPORT_DESC_FILE"
  echo "This usually means Part 1 (argument capture) didn't execute."
  echo "Usage: /research-report \"<workflow description>\""
  exit 1
fi

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description is empty"
  echo "File exists but contains no content: $RESEARCH_REPORT_DESC_FILE"
  echo "Usage: /research-report \"<workflow description>\""
  exit 1
fi

# Parse optional --complexity flag (default: 2 for research-only)
DEFAULT_COMPLEXITY=2
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"

# Support both embedded and explicit flag formats:
# - Embedded: /research-report "description --complexity 4"
# - Explicit: /research-report --complexity 4 "description"
if [[ "$WORKFLOW_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  # Strip flag from workflow description
  WORKFLOW_DESCRIPTION=$(echo "$WORKFLOW_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi

# Validation: reject invalid complexity values
if ! echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"; then
  echo "ERROR: Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" >&2
  exit 1
fi

echo "=== Research-Only Workflow ==="
echo "Description: $WORKFLOW_DESCRIPTION"
echo "Complexity: $RESEARCH_COMPLEXITY"
echo ""
```

## Part 3: State Machine Initialization

**EXECUTE NOW**: Initialize the state machine and source required libraries:

```bash
set +H  # CRITICAL: Disable history expansion
# Detect project directory (bootstrap pattern)
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  # Fallback: search upward for .claude/ directory
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
  echo "DIAGNOSTIC: No git repository found and no .claude/ directory in parent tree" >&2
  exit 1
fi

export CLAUDE_PROJECT_DIR

# Source libraries in dependency order (Standard 15)
# 1. State machine foundation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
# 2. Library version checking
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-version-check.sh"
# 3. Error handling
source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"
# 4. Unified location detection for atomic topic allocation
if ! source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh" 2>&1; then
  echo "ERROR: Failed to source unified-location-detection.sh"
  echo "DIAGNOSTIC: Check library exists at: ${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh"
  exit 1
fi

# Verify library versions (fail-fast if incompatible)
check_library_requirements "$(cat <<'EOF'
workflow-state-machine.sh: ">=2.0.0"
state-persistence.sh: ">=1.5.0"
EOF
)" || exit 1

# Hardcode workflow type (replaces LLM classification)
WORKFLOW_TYPE="research-only"
TERMINAL_STATE="research"
COMMAND_NAME="research-report"

# Generate deterministic WORKFLOW_ID and persist (fail-fast pattern)
WORKFLOW_ID="research_report_$(date +%s)"
STATE_ID_FILE="${HOME}/.claude/tmp/research_report_state_id.txt"
mkdir -p "$(dirname "$STATE_ID_FILE")"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"
export WORKFLOW_ID

# Initialize workflow state BEFORE sm_init (correct initialization order)
init_workflow_state "$WORKFLOW_ID"

# Initialize state machine with 5 parameters and return code verification
# Parameters: description, command_name, workflow_type, research_complexity, research_topics_json
if ! sm_init \
  "$WORKFLOW_DESCRIPTION" \
  "$COMMAND_NAME" \
  "$WORKFLOW_TYPE" \
  "$RESEARCH_COMPLEXITY" \
  "[]" 2>&1; then  # Empty topics JSON array (populated during research)
  echo "ERROR: State machine initialization failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Workflow Description: $WORKFLOW_DESCRIPTION" >&2
  echo "  - Command Name: $COMMAND_NAME" >&2
  echo "  - Workflow Type: $WORKFLOW_TYPE" >&2
  echo "  - Research Complexity: $RESEARCH_COMPLEXITY" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Library version incompatibility (require workflow-state-machine.sh >=2.0.0)" >&2
  echo "  - State file corruption in ~/.claude/data/state/" >&2
  exit 1
fi

echo "✓ State machine initialized (WORKFLOW_ID: $WORKFLOW_ID)"
echo ""
```

## Part 3: Research Phase Execution

**EXECUTE NOW**: Transition to research state and allocate topic directory:

```bash
set +H  # CRITICAL: Disable history expansion
# Transition to research state with return code verification
if ! sm_transition "$STATE_RESEARCH" 2>&1; then
  echo "ERROR: State transition to RESEARCH failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: $(sm_current_state 2>/dev/null || echo 'unknown')" >&2
  echo "  - Attempted Transition: → RESEARCH" >&2
  echo "  - Workflow Type: research-only" >&2
  echo "  - Research topic: $WORKFLOW_DESCRIPTION" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - State machine not initialized properly" >&2
  echo "  - Workflow type wrong (should be research-only)" >&2
  echo "  - State file corruption" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  - Verify sm_init called successfully" >&2
  echo "  - Check workflow type configuration" >&2
  exit 1
fi
echo "=== Phase 1: Research ==="
echo ""

# Generate topic slug from workflow description
TOPIC_SLUG=$(echo "$WORKFLOW_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)

# Allocate topic directory atomically (eliminates race conditions)
SPECS_ROOT="${CLAUDE_PROJECT_DIR}/.claude/specs"
RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_SLUG")
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to allocate topic directory"
  echo "DIAGNOSTIC: Check permissions on $SPECS_ROOT"
  exit 1
fi

# Extract topic number and full path from result
TOPIC_NUMBER="${RESULT%|*}"
TOPIC_DIR="${RESULT#*|}"
RESEARCH_DIR="${TOPIC_DIR}/reports"

# Create reports subdirectory (topic root already created atomically)
mkdir -p "$RESEARCH_DIR"

# Persist variables across bash blocks (subprocess isolation)
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"
append_workflow_state "TOPIC_SLUG" "$TOPIC_SLUG"
append_workflow_state "TOPIC_NUMBER" "$TOPIC_NUMBER"
append_workflow_state "WORKFLOW_DESCRIPTION" "$WORKFLOW_DESCRIPTION"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
```

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${WORKFLOW_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are conducting research for: research-report workflow

    **Workflow-Specific Context**:
    - Research Topic: ${WORKFLOW_DESCRIPTION}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Output Directory: ${RESEARCH_DIR}
    - Workflow Type: research-only

    Execute research according to behavioral guidelines and return completion signal:
    REPORT_CREATED: [path to created report]
  "
}

**EXECUTE NOW**: Verify research artifacts were created:

```bash
set +H  # CRITICAL: Disable history expansion
# MANDATORY VERIFICATION
echo "Verifying research artifacts..."

if [ ! -d "$RESEARCH_DIR" ]; then
  echo "ERROR: Research phase failed to create reports directory" >&2
  echo "DIAGNOSTIC: Expected directory: $RESEARCH_DIR" >&2
  echo "SOLUTION: Check research-specialist agent logs for failures" >&2
  exit 1
fi

if [ -z "$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null)" ]; then
  echo "ERROR: Research phase failed to create report files" >&2
  echo "DIAGNOSTIC: Directory exists but no .md files found: $RESEARCH_DIR" >&2
  echo "SOLUTION: Check research-specialist agent behavioral file compliance" >&2
  exit 1
fi

# Verify file size (minimum 100 bytes)
UNDERSIZED_FILES=$(find "$RESEARCH_DIR" -name '*.md' -type f -size -100c 2>/dev/null)
if [ -n "$UNDERSIZED_FILES" ]; then
  echo "ERROR: Research report(s) too small (< 100 bytes)" >&2
  echo "DIAGNOSTIC: Files: $UNDERSIZED_FILES" >&2
  exit 1
fi

REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null | wc -l)

# CHECKPOINT REPORTING
echo ""
echo "CHECKPOINT: Research phase complete"
echo "- Workflow type: research-only"
echo "- Research complexity: $RESEARCH_COMPLEXITY"
echo "- Reports created: $REPORT_COUNT in $RESEARCH_DIR"
echo "- All files verified: ✓"
echo "- Proceeding to: Completion"
echo ""

# Persist report count for completion summary
append_workflow_state "REPORT_COUNT" "$REPORT_COUNT"

# Persist completed state (call after every sm_transition) with return code verification
if ! save_completed_states_to_state 2>&1; then
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi
```

## Part 4: Completion & Cleanup

**EXECUTE NOW**: Complete the workflow and display summary:

```bash
set +H  # CRITICAL: Disable history expansion

# Load WORKFLOW_ID from file (fail-fast pattern - no fallback)
STATE_ID_FILE="${HOME}/.claude/tmp/research_report_state_id.txt"
if [ ! -f "$STATE_ID_FILE" ]; then
  echo "ERROR: WORKFLOW_ID file not found: $STATE_ID_FILE" >&2
  echo "DIAGNOSTIC: Part 3 (State Machine Initialization) may not have executed" >&2
  exit 1
fi
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

# Re-source required libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# Load workflow state from Part 3 (subprocess isolation)
load_workflow_state "$WORKFLOW_ID" false

# Research-only workflow: terminate after research with return code verification
if ! sm_transition "$STATE_COMPLETE" 2>&1; then
  echo "ERROR: State transition to COMPLETE failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: $(sm_current_state 2>/dev/null || echo 'unknown')" >&2
  echo "  - Attempted Transition: → COMPLETE" >&2
  echo "  - Workflow Type: research-only" >&2
  echo "  - Terminal State: complete" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Research phase did not complete" >&2
  echo "  - State not persisted after research" >&2
  echo "  - Terminal state misconfigured" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  - Check research checkpoint output" >&2
  echo "  - Verify reports created: $REPORT_COUNT" >&2
  exit 1
fi

echo "=== Research Complete ==="
echo ""
echo "Workflow Type: research-only"
echo "Reports Directory: $RESEARCH_DIR"
echo "Report Count: $REPORT_COUNT"
echo ""
echo "Next Steps:"
echo "- Review reports in: $RESEARCH_DIR"
echo "- Use /research-plan to create implementation plan from research"
echo "- Use /coordinate for full workflow (research + plan + implement)"
echo ""

exit 0
```

---

**Troubleshooting**:

- **Research fails**: Check research-specialist agent behavioral file (`.claude/agents/research-specialist.md`) for compliance issues
- **No reports created**: Verify workflow description is clear and actionable
- **State machine errors**: Ensure library versions are compatible (workflow-state-machine.sh >=2.0.0)
- **Complexity too low**: Use `--complexity 3` or `--complexity 4` for more comprehensive research
