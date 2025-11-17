---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob, Edit
argument-hint: <revision-description-with-plan-path>
description: Research and revise existing implementation plan workflow
command-type: primary
dependent-agents:
  - research-specialist
  - research-sub-supervisor
  - plan-architect
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
---

# /research-revise - Research-and-Revise Workflow Command

YOU ARE EXECUTING a research-and-revise workflow that creates research reports based on new insights and then revises an existing implementation plan.

**Workflow Type**: research-and-revise
**Terminal State**: plan (after plan revision complete)
**Expected Output**: Research reports + revised plan (with backup of original)

## Part 1: Capture Revision Description and Extract Plan Path

```bash
REVISION_DESCRIPTION="$1"

if [ -z "$REVISION_DESCRIPTION" ]; then
  echo "ERROR: Revision description with plan path required"
  echo "USAGE: /research-revise \"revise plan at /path/to/plan.md based on NEW_INSIGHTS\""
  echo "EXAMPLE: /research-revise \"revise plan at .claude/specs/123_auth/plans/001_plan.md based on new security requirements\""
  exit 1
fi

# Parse optional --complexity flag (default: 2 for research-and-revise)
DEFAULT_COMPLEXITY=2
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"

# Support both embedded and explicit flag formats
if [[ "$REVISION_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  # Strip flag from revision description
  REVISION_DESCRIPTION=$(echo "$REVISION_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi

# Validation: reject invalid complexity values
if ! echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"; then
  echo "ERROR: Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" >&2
  exit 1
fi

# Extract existing plan path from revision description
# Matches: /path/to/file.md or ./relative/path.md or ../relative/path.md or .claude/path.md
EXISTING_PLAN_PATH=$(echo "$REVISION_DESCRIPTION" | grep -oE '[./][^ ]+\.md' | head -1)

# Validate plan path exists
if [ -z "$EXISTING_PLAN_PATH" ]; then
  echo "ERROR: No plan path found in revision description" >&2
  echo "USAGE: /research-revise \"revise plan at /path/to/plan.md based on INSIGHTS\"" >&2
  exit 1
fi

if [ ! -f "$EXISTING_PLAN_PATH" ]; then
  echo "ERROR: Existing plan not found: $EXISTING_PLAN_PATH" >&2
  echo "DIAGNOSTIC: Ensure plan file exists before revision" >&2
  exit 1
fi

# Extract revision details (everything after plan path)
REVISION_DETAILS=$(echo "$REVISION_DESCRIPTION" | sed "s|.*$EXISTING_PLAN_PATH||" | xargs)

echo "=== Research-and-Revise Workflow ==="
echo "Existing Plan: $EXISTING_PLAN_PATH"
echo "Revision Details: $REVISION_DETAILS"
echo "Research Complexity: $RESEARCH_COMPLEXITY"
echo ""
```

## Part 2: State Machine Initialization

```bash
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

# Source libraries in correct order
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-version-check.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"

# Verify library versions
check_library_requirements "$(cat <<'EOF'
workflow-state-machine.sh: ">=2.0.0"
state-persistence.sh: ">=1.5.0"
EOF
)" || exit 1

# Hardcode workflow type
WORKFLOW_TYPE="research-and-revise"
TERMINAL_STATE="plan"
COMMAND_NAME="research-revise"

# Initialize state machine
sm_init \
  "$REVISION_DESCRIPTION" \
  "$COMMAND_NAME" \
  "$WORKFLOW_TYPE" \
  "$RESEARCH_COMPLEXITY" \
  "{}"

echo "✓ State machine initialized"
echo ""
```

## Part 3: Research Phase Execution

```bash
# Transition to research state
sm_transition "$STATE_RESEARCH"
echo "=== Phase 1: Research ==="
echo ""

# Derive specs directory from existing plan path
SPECS_DIR=$(dirname "$(dirname "$EXISTING_PLAN_PATH")")
RESEARCH_DIR="${SPECS_DIR}/reports"

# Create research directory if not exists
mkdir -p "$RESEARCH_DIR"

# Generate unique research topic for revision insights
REVISION_TOPIC_SLUG=$(echo "$REVISION_DETAILS" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-30)
REVISION_NUMBER=$(find "$RESEARCH_DIR" -name 'revision_*.md' 2>/dev/null | wc -l | xargs)
REVISION_NUMBER=$((REVISION_NUMBER + 1))

# IMPERATIVE AGENT INVOCATION (Standard 11 compliance)
echo "EXECUTE NOW: USE the Task tool to invoke research-specialist agent"
echo ""
echo "YOU MUST:"
echo "1. Read and follow ALL behavioral guidelines from: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md"
echo "2. Follow Standard 0.5 enforcement (sequential step dependencies)"
echo "3. Return completion signal: REPORT_CREATED: \${REPORT_PATH}"
echo ""
echo "Research Parameters:"
echo "- Complexity: $RESEARCH_COMPLEXITY"
echo "- Topics: Auto-detect from revision details"
echo "- Revision Details: $REVISION_DETAILS"
echo "- Output Directory: $RESEARCH_DIR"
echo "- Context: Plan revision research (focused on new insights)"
echo ""

# Hierarchical supervision for complexity ≥4
if [ "$RESEARCH_COMPLEXITY" -ge 4 ]; then
  echo "NOTE: Hierarchical supervision mode (complexity ≥4)"
  echo "Invoke research-sub-supervisor agent"
fi

# FAIL-FAST VERIFICATION
echo ""
echo "Verifying research artifacts..."

if [ ! -d "$RESEARCH_DIR" ]; then
  echo "ERROR: Research phase failed to create reports directory" >&2
  echo "DIAGNOSTIC: Expected directory: $RESEARCH_DIR" >&2
  exit 1
fi

# Count new reports created (may already have existing reports)
NEW_REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' -type f -newer "$EXISTING_PLAN_PATH" 2>/dev/null | wc -l)

if [ "$NEW_REPORT_COUNT" -eq 0 ]; then
  echo "WARNING: No new research reports created"
  echo "NOTE: Proceeding with plan revision using existing reports"
fi

TOTAL_REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null | wc -l)
echo "✓ Research phase complete (total reports: $TOTAL_REPORT_COUNT, new: $NEW_REPORT_COUNT)"
echo ""

# Persist completed state
save_completed_states_to_state
```

## Part 4: Plan Revision Phase

```bash
# Transition to plan state
sm_transition "$STATE_PLAN"
echo "=== Phase 2: Plan Revision ==="
echo ""

# Create backup before revision
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$(dirname "$EXISTING_PLAN_PATH")/backups"
BACKUP_FILENAME="$(basename "$EXISTING_PLAN_PATH" .md)_${TIMESTAMP}.md"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILENAME"

mkdir -p "$BACKUP_DIR"
cp "$EXISTING_PLAN_PATH" "$BACKUP_PATH"

# FAIL-FAST BACKUP VERIFICATION
if [ ! -f "$BACKUP_PATH" ]; then
  echo "ERROR: Backup creation failed at $BACKUP_PATH" >&2
  exit 1
fi

FILE_SIZE=$(wc -c < "$BACKUP_PATH")
if [ "$FILE_SIZE" -lt 100 ]; then
  echo "ERROR: Backup file too small ($FILE_SIZE bytes)" >&2
  exit 1
fi

echo "✓ Backup created: $BACKUP_PATH"
echo ""

# Collect research report paths
REPORT_PATHS=$(find "$RESEARCH_DIR" -name '*.md' -type f | sort)
REPORT_PATHS_JSON=$(echo "$REPORT_PATHS" | jq -R . | jq -s .)

# IMPERATIVE AGENT INVOCATION (Standard 11 compliance)
echo "EXECUTE NOW: USE the Task tool to invoke plan-architect agent"
echo ""
echo "YOU MUST:"
echo "1. Read and follow ALL behavioral guidelines from: ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md"
echo "2. Follow Standard 0.5 enforcement (sequential step dependencies)"
echo "3. Use Edit tool to REVISE existing plan (preserve completed phases)"
echo "4. Return completion signal: PLAN_REVISED: \${PLAN_PATH}"
echo ""
echo "Plan Revision Context:"
echo "- Existing Plan Path: $EXISTING_PLAN_PATH"
echo "- Backup Path: $BACKUP_PATH"
echo "- Revision Details: $REVISION_DETAILS"
echo "- Research Reports: $REPORT_PATHS_JSON"
echo "- Mode: PLAN REVISION (not new creation)"
echo ""
echo "CRITICAL: REVISE existing plan with new research insights."
echo "Use Edit tool to modify file, preserving ALL completed phases."
echo "Execute revision following all guidelines in behavioral file."
echo ""

# FAIL-FAST VERIFICATION
echo "Verifying plan revision..."

if [ ! -f "$EXISTING_PLAN_PATH" ]; then
  echo "ERROR: Plan file disappeared during revision: $EXISTING_PLAN_PATH" >&2
  echo "DIAGNOSTIC: Restore from backup: $BACKUP_PATH" >&2
  exit 1
fi

# Verify plan was actually modified (must be different from backup)
if cmp -s "$EXISTING_PLAN_PATH" "$BACKUP_PATH"; then
  echo "ERROR: Plan file not modified (identical to backup)" >&2
  echo "DIAGNOSTIC: Plan revision must make changes based on research insights" >&2
  echo "SOLUTION: Review research reports and ensure agent applies revisions" >&2
  exit 1
fi

FILE_SIZE=$(wc -c < "$EXISTING_PLAN_PATH")
if [ "$FILE_SIZE" -lt 500 ]; then
  echo "ERROR: Plan file too small after revision ($FILE_SIZE bytes)" >&2
  echo "DIAGNOSTIC: Plan may have been corrupted, restore from: $BACKUP_PATH" >&2
  exit 1
fi

echo "✓ Plan revision complete: $EXISTING_PLAN_PATH"
echo ""

# Persist completed state
save_completed_states_to_state
```

## Part 5: Completion & Cleanup

```bash
# Research-and-revise workflow: terminate after plan revision
sm_transition "$STATE_COMPLETE"

echo "=== Research-and-Revise Complete ==="
echo ""
echo "Workflow Type: research-and-revise"
echo "Specs Directory: $SPECS_DIR"
echo "Research Reports: $TOTAL_REPORT_COUNT total ($NEW_REPORT_COUNT new)"
echo "Revised Plan: $EXISTING_PLAN_PATH"
echo "Plan Backup: $BACKUP_PATH"
echo ""
echo "Next Steps:"
echo "- Review revised plan: cat $EXISTING_PLAN_PATH"
echo "- Compare with backup: diff $BACKUP_PATH $EXISTING_PLAN_PATH"
echo "- Implement revised plan: /implement $EXISTING_PLAN_PATH"
echo ""

exit 0
```

---

**Troubleshooting**:

- **Plan path not found**: Ensure path format correct (/path/to/plan.md or ./relative/path.md)
- **Backup failed**: Check write permissions in plans/backups/ directory
- **Plan not modified**: Agent may determine no revision needed based on research
- **Plan corrupted**: Restore from backup in plans/backups/ directory
- **State machine errors**: Ensure library versions compatible (workflow-state-machine.sh >=2.0.0)
