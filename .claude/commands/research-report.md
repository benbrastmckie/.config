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

```bash
WORKFLOW_DESCRIPTION="$1"

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description required"
  echo "USAGE: /research-report <workflow-description>"
  echo "EXAMPLE: /research-report \"authentication patterns in codebase\""
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
WORKFLOW_TYPE="research-only"
TERMINAL_STATE="research"
COMMAND_NAME="research-report"

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
TOPIC_SLUG=$(echo "$WORKFLOW_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)
TOPIC_NUMBER=$(find "${CLAUDE_PROJECT_DIR}/.claude/specs" -maxdepth 1 -type d -name '[0-9]*_*' 2>/dev/null | wc -l | xargs)
TOPIC_NUMBER=$((TOPIC_NUMBER + 1))
RESEARCH_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TOPIC_NUMBER}_${TOPIC_SLUG}/reports"

# Create research directory
mkdir -p "$RESEARCH_DIR"
```

Task {
  subagent_type: "research-specialist"
  description: "Research $WORKFLOW_DESCRIPTION"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are conducting research for: research-report workflow

    Input:
    - Research Topic: $WORKFLOW_DESCRIPTION
    - Research Complexity: $RESEARCH_COMPLEXITY
    - Output Directory: $RESEARCH_DIR
    - Workflow Type: research-only

    Execute research according to behavioral guidelines and return completion signal:
    REPORT_CREATED: ${REPORT_PATH}
}

```bash
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
echo "✓ Research phase complete ($REPORT_COUNT reports created)"
echo ""

# Persist completed state (call after every sm_transition) with return code verification
if ! save_completed_states_to_state 2>&1; then
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi
```

## Part 4: Completion & Cleanup

```bash
# Research-only workflow: terminate after research with return code verification
if ! sm_transition "$STATE_COMPLETE" 2>&1; then
  echo "ERROR: State transition to COMPLETE failed" >&2
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
