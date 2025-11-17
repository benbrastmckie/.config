---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob, Write
argument-hint: <feature-description>
description: Research and create new implementation plan workflow
command-type: primary
dependent-agents:
  - research-specialist
  - research-sub-supervisor
  - plan-architect
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
documentation: See .claude/docs/guides/research-plan-command-guide.md for complete usage guide
---

# /research-plan - Research-and-Plan Workflow Command

YOU ARE EXECUTING a research-and-plan workflow that creates comprehensive research reports and then generates a new implementation plan based on those findings.

**Workflow Type**: research-and-plan
**Terminal State**: plan (after planning phase complete)
**Expected Output**: Research reports + implementation plan in .claude/specs/NNN_topic/

## Part 1: Capture Feature Description

```bash
FEATURE_DESCRIPTION="$1"

if [ -z "$FEATURE_DESCRIPTION" ]; then
  echo "ERROR: Feature description required"
  echo "USAGE: /research-plan <feature-description>"
  echo "EXAMPLE: /research-plan \"implement user authentication with JWT tokens\""
  exit 1
fi

# Parse optional --complexity flag (default: 3 for research-and-plan)
DEFAULT_COMPLEXITY=3
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"

# Support both embedded and explicit flag formats:
# - Embedded: /research-plan "description --complexity 4"
# - Explicit: /research-plan --complexity 4 "description"
if [[ "$FEATURE_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  # Strip flag from feature description
  FEATURE_DESCRIPTION=$(echo "$FEATURE_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi

# Validation: reject invalid complexity values
if ! echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"; then
  echo "ERROR: Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" >&2
  exit 1
fi

echo "=== Research-and-Plan Workflow ==="
echo "Feature: $FEATURE_DESCRIPTION"
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

# Source libraries in dependency order (Standard 15)
# 1. State machine foundation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
# 2. Library version checking
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-version-check.sh"
# 3. Error handling
source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"

# Verify library versions (fail-fast if incompatible)
check_library_requirements "$(cat <<'EOF'
workflow-state-machine.sh: ">=2.0.0"
state-persistence.sh: ">=1.5.0"
EOF
)" || exit 1

# Hardcode workflow type (replaces LLM classification)
WORKFLOW_TYPE="research-and-plan"
TERMINAL_STATE="plan"
COMMAND_NAME="research-plan"

# Initialize state machine with 5 parameters and return code verification
# Parameters: description, command_name, workflow_type, research_complexity, research_topics_json
if ! sm_init \
  "$FEATURE_DESCRIPTION" \
  "$COMMAND_NAME" \
  "$WORKFLOW_TYPE" \
  "$RESEARCH_COMPLEXITY" \
  "[]" 2>&1; then  # Empty topics JSON array (populated during research)
  echo "ERROR: State machine initialization failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Feature Description: $FEATURE_DESCRIPTION" >&2
  echo "  - Command Name: $COMMAND_NAME" >&2
  echo "  - Workflow Type: $WORKFLOW_TYPE" >&2
  echo "  - Research Complexity: $RESEARCH_COMPLEXITY" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Library version incompatibility (require workflow-state-machine.sh >=2.0.0)" >&2
  echo "  - State file corruption in ~/.claude/data/state/" >&2
  exit 1
fi

echo "✓ State machine initialized"
echo ""
```

## Part 3: Research Phase Execution

```bash
# Transition to research state with return code verification
if ! sm_transition "$STATE_RESEARCH" 2>&1; then
  echo "ERROR: State transition to RESEARCH failed" >&2
  exit 1
fi
echo "=== Phase 1: Research ==="
echo ""

# Pre-calculate research directory path
TOPIC_SLUG=$(echo "$FEATURE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)
TOPIC_NUMBER=$(find "${CLAUDE_PROJECT_DIR}/.claude/specs" -maxdepth 1 -type d -name '[0-9]*_*' 2>/dev/null | wc -l | xargs)
TOPIC_NUMBER=$((TOPIC_NUMBER + 1))
SPECS_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TOPIC_NUMBER}_${TOPIC_SLUG}"
RESEARCH_DIR="${SPECS_DIR}/reports"
PLANS_DIR="${SPECS_DIR}/plans"

# Create directories
mkdir -p "$RESEARCH_DIR"
mkdir -p "$PLANS_DIR"

# IMPERATIVE AGENT INVOCATION
echo "EXECUTE NOW: USE the Task tool to invoke research-specialist agent"
echo ""
echo "YOU MUST:"
echo "1. Read and follow ALL behavioral guidelines from: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md"
echo "2. Return completion signal: REPORT_CREATED: \${REPORT_PATH}"
echo ""
echo "Workflow-Specific Context:"
echo "- Research Complexity: $RESEARCH_COMPLEXITY"
echo "- Feature Description: $FEATURE_DESCRIPTION"
echo "- Output Directory: $RESEARCH_DIR"
echo "- Workflow Type: research-and-plan"
echo ""

# Hierarchical supervision for complexity ≥4
if [ "$RESEARCH_COMPLEXITY" -ge 4 ]; then
  echo "NOTE: Hierarchical supervision mode (complexity ≥4)"
  echo "Invoke research-sub-supervisor agent to coordinate multiple sub-agents"
  echo "Supervisor Agent: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-sub-supervisor.md"
fi

# FAIL-FAST VERIFICATION (no fallback, exit 1 on failure)
echo ""
echo "Verifying research artifacts..."

if [ ! -d "$RESEARCH_DIR" ]; then
  echo "ERROR: Research phase failed to create reports directory" >&2
  echo "DIAGNOSTIC: Expected directory: $RESEARCH_DIR" >&2
  exit 1
fi

if [ -z "$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null)" ]; then
  echo "ERROR: Research phase failed to create report files" >&2
  echo "DIAGNOSTIC: Directory exists but no .md files found: $RESEARCH_DIR" >&2
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
echo "✓ Research phase complete ($REPORT_COUNT reports created)"
echo ""

# Persist completed state with return code verification
if ! save_completed_states_to_state 2>&1; then
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi
```

## Part 4: Planning Phase Execution

```bash
# Transition to plan state with return code verification
if ! sm_transition "$STATE_PLAN" 2>&1; then
  echo "ERROR: State transition to PLAN failed" >&2
  exit 1
fi
echo "=== Phase 2: Planning ==="
echo ""

# Pre-calculate plan path
PLAN_NUMBER="001"
PLAN_FILENAME="${PLAN_NUMBER}_$(echo "$TOPIC_SLUG" | cut -c1-40)_plan.md"
PLAN_PATH="${PLANS_DIR}/${PLAN_FILENAME}"

# Collect research report paths
REPORT_PATHS=$(find "$RESEARCH_DIR" -name '*.md' -type f | sort)
REPORT_PATHS_JSON=$(echo "$REPORT_PATHS" | jq -R . | jq -s .)

# IMPERATIVE AGENT INVOCATION
echo "EXECUTE NOW: USE the Task tool to invoke plan-architect agent"
echo ""
echo "YOU MUST:"
echo "1. Read and follow ALL behavioral guidelines from: ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md"
echo "2. Use Write tool to create plan at: $PLAN_PATH"
echo "3. Return completion signal: PLAN_CREATED: \${PLAN_PATH}"
echo ""
echo "Workflow-Specific Context:"
echo "- Feature Description: $FEATURE_DESCRIPTION"
echo "- Output Path: $PLAN_PATH"
echo "- Research Reports: $REPORT_PATHS_JSON"
echo "- Workflow Type: research-and-plan"
echo "- Operation Mode: new plan creation"
echo ""

# FAIL-FAST VERIFICATION (no fallback, exit 1 on failure)
echo "Verifying plan artifacts..."

if [ ! -f "$PLAN_PATH" ]; then
  echo "ERROR: Planning phase failed to create plan file" >&2
  echo "DIAGNOSTIC: Expected file: $PLAN_PATH" >&2
  echo "SOLUTION: Check plan-architect agent behavioral file compliance" >&2
  exit 1
fi

FILE_SIZE=$(wc -c < "$PLAN_PATH")
if [ "$FILE_SIZE" -lt 500 ]; then
  echo "ERROR: Plan file too small ($FILE_SIZE bytes)" >&2
  echo "DIAGNOSTIC: Plan file may be incomplete or empty" >&2
  exit 1
fi

echo "✓ Planning phase complete (plan: $PLAN_PATH)"
echo ""

# Persist completed state with return code verification
if ! save_completed_states_to_state 2>&1; then
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi
```

## Part 5: Completion & Cleanup

```bash
# Research-and-plan workflow: terminate after planning with return code verification
if ! sm_transition "$STATE_COMPLETE" 2>&1; then
  echo "ERROR: State transition to COMPLETE failed" >&2
  exit 1
fi

echo "=== Research-and-Plan Complete ==="
echo ""
echo "Workflow Type: research-and-plan"
echo "Specs Directory: $SPECS_DIR"
echo "Research Reports: $REPORT_COUNT reports in $RESEARCH_DIR"
echo "Implementation Plan: $PLAN_PATH"
echo ""
echo "Next Steps:"
echo "- Review plan: cat $PLAN_PATH"
echo "- Implement plan: /implement $PLAN_PATH"
echo "- Use /build to execute implementation phases"
echo ""

exit 0
```

---

**Troubleshooting**:

- **Research fails**: Check research-specialist agent behavioral file compliance
- **Planning fails**: Check plan-architect agent behavioral file (`.claude/agents/plan-architect.md`)
- **Plan file empty**: Verify feature description is clear and research reports exist
- **State machine errors**: Ensure library versions compatible (workflow-state-machine.sh >=2.0.0)
