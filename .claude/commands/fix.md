---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
argument-hint: <issue-description>
description: Debug-focused workflow - Root cause analysis and bug fixing
command-type: primary
dependent-agents:
  - research-specialist
  - plan-architect
  - debug-analyst
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
---

# /fix - Debug-Focused Workflow Command

YOU ARE EXECUTING a debug-focused workflow that investigates issues through research, creates a debug strategy plan, and performs root cause analysis with fixes.

**Workflow Type**: debug-only
**Terminal State**: debug (after debug analysis complete)
**Expected Output**: Debug reports, strategy plan, and root cause analysis

## Part 1: Capture Issue Description

```bash
ISSUE_DESCRIPTION="$1"

if [ -z "$ISSUE_DESCRIPTION" ]; then
  echo "ERROR: Issue description required"
  echo "USAGE: /fix <issue-description>"
  echo "EXAMPLE: /fix \"investigate authentication timeout errors in production logs\""
  exit 1
fi

# Parse optional --complexity flag (default: 2 for debug-only)
DEFAULT_COMPLEXITY=2
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"

if [[ "$ISSUE_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  ISSUE_DESCRIPTION=$(echo "$ISSUE_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi

if ! echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"; then
  echo "ERROR: Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" >&2
  exit 1
fi

echo "=== Debug-Focused Workflow ==="
echo "Issue: $ISSUE_DESCRIPTION"
echo "Research Complexity: $RESEARCH_COMPLEXITY"
echo ""
```

## Part 2: State Machine Initialization

```bash
# Detect project directory
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

# Source libraries in dependency order (Standard 15)
# 1. State machine foundation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
# 2. Library version checking
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-version-check.sh"
# 3. Error handling
source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"

# Verify library versions
check_library_requirements "$(cat <<'EOF'
workflow-state-machine.sh: ">=2.0.0"
state-persistence.sh: ">=1.5.0"
EOF
)" || exit 1

# Hardcode workflow type
WORKFLOW_TYPE="debug-only"
TERMINAL_STATE="debug"
COMMAND_NAME="fix"

# Initialize state machine with return code verification
if ! sm_init \
  "$ISSUE_DESCRIPTION" \
  "$COMMAND_NAME" \
  "$WORKFLOW_TYPE" \
  "$RESEARCH_COMPLEXITY" \
  "{}" 2>&1; then
  echo "ERROR: State machine initialization failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Issue Description: $ISSUE_DESCRIPTION" >&2
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

## Part 3: Research Phase (Issue Investigation)

```bash
# Transition to research state with return code verification
if ! sm_transition "$STATE_RESEARCH" 2>&1; then
  echo "ERROR: State transition to RESEARCH failed" >&2
  exit 1
fi
echo "=== Phase 1: Research (Issue Investigation) ==="
echo ""

# Pre-calculate directories
TOPIC_SLUG=$(echo "$ISSUE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)
TOPIC_NUMBER=$(find "${CLAUDE_PROJECT_DIR}/.claude/specs" -maxdepth 1 -type d -name '[0-9]*_*' 2>/dev/null | wc -l | xargs)
TOPIC_NUMBER=$((TOPIC_NUMBER + 1))
SPECS_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TOPIC_NUMBER}_${TOPIC_SLUG}"
RESEARCH_DIR="${SPECS_DIR}/reports"
DEBUG_DIR="${SPECS_DIR}/debug"

mkdir -p "$RESEARCH_DIR"
mkdir -p "$DEBUG_DIR"

# IMPERATIVE AGENT INVOCATION
echo "EXECUTE NOW: USE the Task tool to invoke research-specialist agent"
echo ""
echo "YOU MUST:"
echo "1. Read and follow ALL behavioral guidelines from: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md"
echo "2. Focus research on debugging context (error logs, stack traces, related code)"
echo "3. Return completion signal: REPORT_CREATED: \${REPORT_PATH}"
echo ""
echo "Research Parameters:"
echo "- Complexity: $RESEARCH_COMPLEXITY"
echo "- Topics: Auto-detect from issue description (error analysis, related systems)"
echo "- Issue Description: $ISSUE_DESCRIPTION"
echo "- Output Directory: $RESEARCH_DIR"
echo "- Context: Debug investigation (root cause analysis)"
echo ""

# FAIL-FAST VERIFICATION
echo ""
echo "Verifying research artifacts..."

if [ ! -d "$RESEARCH_DIR" ]; then
  echo "ERROR: Research phase failed to create reports directory" >&2
  echo "DIAGNOSTIC: Expected directory: $RESEARCH_DIR" >&2
  echo "SOLUTION: Check research-specialist agent logs for failures" >&2
  exit 1
fi

# File-level verification (not directory-level)
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

# Persist completed state with return code verification
if ! save_completed_states_to_state 2>&1; then
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi
```

## Part 4: Planning Phase (Debug Strategy)

```bash
# Transition to plan state with return code verification
if ! sm_transition "$STATE_PLAN" 2>&1; then
  echo "ERROR: State transition to PLAN failed" >&2
  exit 1
fi
echo "=== Phase 2: Planning (Debug Strategy) ==="
echo ""

# Pre-calculate plan path
PLANS_DIR="${SPECS_DIR}/plans"
mkdir -p "$PLANS_DIR"
PLAN_NUMBER="001"
PLAN_FILENAME="${PLAN_NUMBER}_debug_strategy.md"
PLAN_PATH="${PLANS_DIR}/${PLAN_FILENAME}"

# Collect research report paths
REPORT_PATHS=$(find "$RESEARCH_DIR" -name '*.md' -type f | sort)
REPORT_PATHS_JSON=$(echo "$REPORT_PATHS" | jq -R . | jq -s .)

# IMPERATIVE AGENT INVOCATION
echo "EXECUTE NOW: USE the Task tool to invoke plan-architect agent"
echo ""
echo "YOU MUST:"
echo "1. Read and follow ALL behavioral guidelines from: ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md"
echo "2. Create DEBUG STRATEGY PLAN (not implementation plan)"
echo "3. Use Write tool to CREATE plan at: $PLAN_PATH"
echo "4. Return completion signal: PLAN_CREATED: \${PLAN_PATH}"
echo ""
echo "Plan Context:"
echo "- Issue Description: $ISSUE_DESCRIPTION"
echo "- Output Path: $PLAN_PATH"
echo "- Research Reports: $REPORT_PATHS_JSON"
echo "- Mode: DEBUG STRATEGY (systematic debugging steps)"
echo ""

# FAIL-FAST VERIFICATION
echo ""
echo "Verifying plan artifacts..."

if [ ! -f "$PLAN_PATH" ]; then
  echo "ERROR: Planning phase failed to create plan file" >&2
  echo "DIAGNOSTIC: Expected file: $PLAN_PATH" >&2
  exit 1
fi

FILE_SIZE=$(wc -c < "$PLAN_PATH")
if [ "$FILE_SIZE" -lt 200 ]; then
  echo "ERROR: Plan file too small ($FILE_SIZE bytes)" >&2
  exit 1
fi

echo "✓ Planning phase complete (strategy: $PLAN_PATH)"
echo ""

# Persist completed state with return code verification
if ! save_completed_states_to_state 2>&1; then
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi
```

## Part 5: Debug Phase (Root Cause Analysis)

```bash
# Transition to debug state with return code verification
if ! sm_transition "$STATE_DEBUG" 2>&1; then
  echo "ERROR: State transition to DEBUG failed" >&2
  exit 1
fi
echo "=== Phase 3: Debug (Root Cause Analysis) ==="
echo ""

# IMPERATIVE AGENT INVOCATION
echo "EXECUTE NOW: USE the Task tool to invoke debug-analyst agent"
echo ""
echo "YOU MUST:"
echo "1. Read and follow ALL behavioral guidelines from: ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md"
echo "2. Perform root cause analysis following debug strategy plan"
echo "3. Create debug artifacts in: $DEBUG_DIR"
echo "4. Return completion signal: DEBUG_COMPLETE: \${ANALYSIS_PATH}"
echo ""
echo "Debug Context:"
echo "- Issue Description: $ISSUE_DESCRIPTION"
echo "- Debug Strategy Plan: $PLAN_PATH"
echo "- Research Reports: $REPORT_PATHS_JSON"
echo "- Debug Artifacts Directory: $DEBUG_DIR"
echo ""

# FAIL-FAST VERIFICATION
echo ""
echo "Verifying debug artifacts..."

if [ ! -d "$DEBUG_DIR" ]; then
  echo "WARNING: Debug directory not created" >&2
fi

# Check for any debug artifacts (logs, analysis files)
DEBUG_ARTIFACT_COUNT=$(find "$DEBUG_DIR" -type f 2>/dev/null | wc -l)

if [ "$DEBUG_ARTIFACT_COUNT" -eq 0 ]; then
  echo "NOTE: No debug artifacts created (analysis may be in plan or reports)"
fi

echo "✓ Debug phase complete (artifacts: $DEBUG_ARTIFACT_COUNT)"
echo ""

# Persist completed state with return code verification
if ! save_completed_states_to_state 2>&1; then
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi
```

## Part 6: Completion & Cleanup

```bash
# Debug-only workflow: terminate after debug phase with return code verification
if ! sm_transition "$STATE_COMPLETE" 2>&1; then
  echo "ERROR: State transition to COMPLETE failed" >&2
  exit 1
fi

echo "=== Debug Workflow Complete ==="
echo ""
echo "Workflow Type: debug-only"
echo "Specs Directory: $SPECS_DIR"
echo "Research Reports: $REPORT_COUNT reports"
echo "Debug Strategy Plan: $PLAN_PATH"
echo "Debug Artifacts: $DEBUG_ARTIFACT_COUNT files"
echo ""
echo "Next Steps:"
echo "- Review debug strategy: cat $PLAN_PATH"
echo "- Review debug artifacts: ls $DEBUG_DIR"
echo "- Apply fixes identified in analysis"
echo "- Re-run tests to verify fix"
echo ""

exit 0
```

---

**Troubleshooting**:

- **Research fails**: Ensure issue description is specific enough for investigation
- **No debug artifacts**: Analysis may be in plan file or reports directory
- **Root cause unclear**: Increase complexity with --complexity 3 or --complexity 4
- **State machine errors**: Ensure library versions compatible (workflow-state-machine.sh >=2.0.0)

**Usage Examples**:

```bash
# Basic debugging
/fix "authentication timeout errors in production"

# Higher complexity investigation
/fix "intermittent database connection failures --complexity 3"

# Performance issue
/fix "API endpoint latency exceeds 2s on POST /api/users"
```
