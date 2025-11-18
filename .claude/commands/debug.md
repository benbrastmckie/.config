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
documentation: See .claude/docs/guides/debug-command-guide.md for complete usage guide
---

# /debug - Debug-Focused Workflow Command

YOU ARE EXECUTING a debug-focused workflow that investigates issues through research, creates a debug strategy plan, and performs root cause analysis with fixes.

**Workflow Type**: debug-only
**Terminal State**: debug (after debug analysis complete)
**Expected Output**: Debug reports, strategy plan, and root cause analysis

## Part 1: Capture Issue Description

**EXECUTE NOW**: Capture and validate the issue description:

```bash
set +H  # CRITICAL: Disable history expansion
ISSUE_DESCRIPTION="$1"

if [ -z "$ISSUE_DESCRIPTION" ]; then
  echo "ERROR: Issue description required"
  echo "USAGE: /debug <issue-description>"
  echo "EXAMPLE: /debug \"investigate authentication timeout errors in production logs\""
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

**EXECUTE NOW**: Initialize state machine and source required libraries:

```bash
set +H  # CRITICAL: Disable history expansion
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
# 4. Unified location detection for atomic topic allocation
if ! source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh" 2>&1; then
  echo "ERROR: Failed to source unified-location-detection.sh"
  echo "DIAGNOSTIC: Check library exists at: ${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh"
  exit 1
fi

# Verify library versions
check_library_requirements "$(cat <<'EOF'
workflow-state-machine.sh: ">=2.0.0"
state-persistence.sh: ">=1.5.0"
EOF
)" || exit 1

# Hardcode workflow type
WORKFLOW_TYPE="debug-only"
TERMINAL_STATE="debug"
COMMAND_NAME="debug"

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

**EXECUTE NOW**: Transition to research state and allocate topic directory:

```bash
set +H  # CRITICAL: Disable history expansion
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh"

# Transition to research state with return code verification
if ! sm_transition "$STATE_RESEARCH" 2>&1; then
  echo "ERROR: State transition to RESEARCH failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: $(sm_current_state 2>/dev/null || echo 'unknown')" >&2
  echo "  - Attempted Transition: → RESEARCH" >&2
  echo "  - Workflow Type: debug-only" >&2
  echo "  - Issue: $ISSUE_DESCRIPTION" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - State machine not initialized properly" >&2
  echo "  - Workflow type misconfigured" >&2
  echo "  - State file corruption" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  - Verify sm_init called with debug-only workflow type" >&2
  echo "  - Check ~/.claude/data/state/ for corruption" >&2
  exit 1
fi
echo "=== Phase 1: Research (Issue Investigation) ==="
echo ""

# Generate topic slug from issue description
TOPIC_SLUG=$(echo "$ISSUE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)

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
SPECS_DIR="${RESULT#*|}"

# Define subdirectories
RESEARCH_DIR="${SPECS_DIR}/reports"
DEBUG_DIR="${SPECS_DIR}/debug"

# Create subdirectories (topic root already created atomically)
mkdir -p "$RESEARCH_DIR"
mkdir -p "$DEBUG_DIR"

# Persist variables for next block and agent
echo "SPECS_DIR=$SPECS_DIR" > "${HOME}/.claude/tmp/debug_state_$$.txt"
echo "RESEARCH_DIR=$RESEARCH_DIR" >> "${HOME}/.claude/tmp/debug_state_$$.txt"
echo "DEBUG_DIR=$DEBUG_DIR" >> "${HOME}/.claude/tmp/debug_state_$$.txt"
echo "ISSUE_DESCRIPTION=$ISSUE_DESCRIPTION" >> "${HOME}/.claude/tmp/debug_state_$$.txt"
echo "RESEARCH_COMPLEXITY=$RESEARCH_COMPLEXITY" >> "${HOME}/.claude/tmp/debug_state_$$.txt"
```

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research root cause for $ISSUE_DESCRIPTION"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are conducting research for: debug workflow (root cause analysis)

    Input:
    - Research Topic: Root cause analysis for: $ISSUE_DESCRIPTION
    - Research Complexity: $RESEARCH_COMPLEXITY
    - Output Directory: $RESEARCH_DIR
    - Workflow Type: debug-only
    - Context Mode: root cause analysis

    Execute research according to behavioral guidelines.

    Return: REPORT_CREATED: {report_path}
  "
}

**EXECUTE NOW**: Verify research artifacts were created:

```bash
set +H  # CRITICAL: Disable history expansion
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

# Load state from previous block
source "${HOME}/.claude/tmp/debug_state_$$.txt" 2>/dev/null || true

# MANDATORY VERIFICATION
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

# CHECKPOINT REPORTING
echo ""
echo "CHECKPOINT: Research phase complete"
echo "- Workflow type: debug-only"
echo "- Issue: $ISSUE_DESCRIPTION"
echo "- Reports created: $REPORT_COUNT in $RESEARCH_DIR"
echo "- All files verified: ✓"
echo "- Proceeding to: Planning phase"
echo ""

# Persist variables across bash blocks (subprocess isolation)
append_workflow_state "SPECS_DIR" "$SPECS_DIR"
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"
append_workflow_state "DEBUG_DIR" "$DEBUG_DIR"
append_workflow_state "REPORT_COUNT" "$REPORT_COUNT"
append_workflow_state "ISSUE_DESCRIPTION" "$ISSUE_DESCRIPTION"

# Persist completed state with return code verification
if ! save_completed_states_to_state 2>&1; then
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi
```

## Part 4: Planning Phase (Debug Strategy)

**EXECUTE NOW**: Transition to planning state and prepare for plan creation:

```bash
set +H  # CRITICAL: Disable history expansion
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# Load state from previous block
source "${HOME}/.claude/tmp/debug_state_$$.txt" 2>/dev/null || true

# Load workflow state from Part 3 (subprocess isolation)
load_workflow_state "${WORKFLOW_ID:-$$}" false

# Re-export state machine variables (restored by load_workflow_state)
export CURRENT_STATE
export TERMINAL_STATE
export WORKFLOW_SCOPE
export RESEARCH_COMPLEXITY
export RESEARCH_TOPICS_JSON

# Transition to plan state with return code verification
if ! sm_transition "$STATE_PLAN" 2>&1; then
  echo "ERROR: State transition to PLAN failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: $(sm_current_state 2>/dev/null || echo 'unknown')" >&2
  echo "  - Attempted Transition: → PLAN" >&2
  echo "  - Workflow Type: debug-only" >&2
  echo "  - Reports created: $REPORT_COUNT" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Research phase did not complete" >&2
  echo "  - No reports created (check REPORT_COUNT)" >&2
  echo "  - State not persisted after research" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  - Check research checkpoint output" >&2
  echo "  - Verify reports exist in $RESEARCH_DIR" >&2
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

# Persist additional state for agent
echo "PLAN_PATH=$PLAN_PATH" >> "${HOME}/.claude/tmp/debug_state_$$.txt"
echo "REPORT_PATHS_JSON='$REPORT_PATHS_JSON'" >> "${HOME}/.claude/tmp/debug_state_$$.txt"
```

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Create debug strategy plan for $ISSUE_DESCRIPTION"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are creating a debug strategy plan for: debug workflow

    Input:
    - Feature Description: Debug strategy for: $ISSUE_DESCRIPTION
    - Output Path: $PLAN_PATH
    - Research Reports: $REPORT_PATHS_JSON
    - Workflow Type: debug-only
    - Plan Mode: debug strategy

    Execute planning according to behavioral guidelines.

    Return: PLAN_CREATED: {plan_path}
  "
}

**EXECUTE NOW**: Verify plan artifacts were created:

```bash
set +H  # CRITICAL: Disable history expansion
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

# Load state from previous block
source "${HOME}/.claude/tmp/debug_state_$$.txt" 2>/dev/null || true

# MANDATORY VERIFICATION
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

# CHECKPOINT REPORTING
echo ""
echo "CHECKPOINT: Planning phase complete"
echo "- Plan file: $PLAN_PATH"
echo "- Plan size: $(wc -c < "$PLAN_PATH") bytes"
echo "- Research reports used: $REPORT_COUNT"
echo "- All verifications: ✓"
echo "- Proceeding to: Debug phase"
echo ""

# Persist variables for Part 5 (subprocess isolation)
append_workflow_state "PLANS_DIR" "$PLANS_DIR"
append_workflow_state "PLAN_PATH" "$PLAN_PATH"
append_workflow_state "REPORT_PATHS_JSON" "$REPORT_PATHS_JSON"

# Persist completed state with return code verification
if ! save_completed_states_to_state 2>&1; then
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi
```

## Part 5: Debug Phase (Root Cause Analysis)

**EXECUTE NOW**: Transition to debug state and prepare for root cause analysis:

```bash
set +H  # CRITICAL: Disable history expansion
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# Load state from previous block
source "${HOME}/.claude/tmp/debug_state_$$.txt" 2>/dev/null || true

# Load workflow state from Part 4 (subprocess isolation)
load_workflow_state "${WORKFLOW_ID:-$$}" false

# Re-export state machine variables (restored by load_workflow_state)
export CURRENT_STATE
export TERMINAL_STATE
export WORKFLOW_SCOPE
export RESEARCH_COMPLEXITY
export RESEARCH_TOPICS_JSON

# Transition to debug state with return code verification
if ! sm_transition "$STATE_DEBUG" 2>&1; then
  echo "ERROR: State transition to DEBUG failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: $(sm_current_state 2>/dev/null || echo 'unknown')" >&2
  echo "  - Attempted Transition: → DEBUG" >&2
  echo "  - Workflow Type: debug-only" >&2
  echo "  - Plan file: $PLAN_PATH" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Planning phase did not complete" >&2
  echo "  - Plan file missing or invalid" >&2
  echo "  - State not persisted after planning" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  - Check planning checkpoint output" >&2
  echo "  - Verify plan exists: $PLAN_PATH" >&2
  exit 1
fi
echo "=== Phase 3: Debug (Root Cause Analysis) ==="
echo ""
```

**EXECUTE NOW**: USE the Task tool to invoke the debug-analyst agent.

Task {
  subagent_type: "general-purpose"
  description: "Root cause analysis for $ISSUE_DESCRIPTION"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    You are conducting root cause analysis for: debug workflow

    Input:
    - Issue Description: $ISSUE_DESCRIPTION
    - Debug Strategy Plan: $PLAN_PATH
    - Research Reports: $REPORT_PATHS_JSON
    - Debug Directory: $DEBUG_DIR
    - Workflow Type: debug-only

    Execute root cause analysis according to behavioral guidelines.

    Return: DEBUG_COMPLETE: {analysis_path}
  "
}

**EXECUTE NOW**: Verify debug artifacts were created:

```bash
set +H  # CRITICAL: Disable history expansion
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

# Load state from previous block
source "${HOME}/.claude/tmp/debug_state_$$.txt" 2>/dev/null || true

# MANDATORY VERIFICATION
echo "Verifying debug artifacts..."

if [ ! -d "$DEBUG_DIR" ]; then
  echo "WARNING: Debug directory not created" >&2
fi

# Check for any debug artifacts (logs, analysis files)
DEBUG_ARTIFACT_COUNT=$(find "$DEBUG_DIR" -type f 2>/dev/null | wc -l)

if [ "$DEBUG_ARTIFACT_COUNT" -eq 0 ]; then
  echo "NOTE: No debug artifacts created (analysis may be in plan or reports)"
fi

# CHECKPOINT REPORTING
echo ""
echo "CHECKPOINT: Debug phase complete"
echo "- Debug artifacts: $DEBUG_ARTIFACT_COUNT in $DEBUG_DIR"
echo "- Analysis complete: ✓"
echo "- All verifications: ✓"
echo "- Proceeding to: Completion"
echo ""

# Persist variables for Part 6 (subprocess isolation)
append_workflow_state "DEBUG_ARTIFACT_COUNT" "$DEBUG_ARTIFACT_COUNT"

# Persist completed state with return code verification
if ! save_completed_states_to_state 2>&1; then
  echo "ERROR: Failed to persist completed state" >&2
  exit 1
fi
```

## Part 6: Completion & Cleanup

**EXECUTE NOW**: Complete workflow and cleanup state:

```bash
set +H  # CRITICAL: Disable history expansion
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# Load state from previous block
source "${HOME}/.claude/tmp/debug_state_$$.txt" 2>/dev/null || true

# Load workflow state from Part 5 (subprocess isolation)
load_workflow_state "${WORKFLOW_ID:-$$}" false

# Re-export state machine variables (restored by load_workflow_state)
export CURRENT_STATE
export TERMINAL_STATE
export WORKFLOW_SCOPE
export RESEARCH_COMPLEXITY
export RESEARCH_TOPICS_JSON

# Debug-only workflow: terminate after debug phase with return code verification
if ! sm_transition "$STATE_COMPLETE" 2>&1; then
  echo "ERROR: State transition to COMPLETE failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: $(sm_current_state 2>/dev/null || echo 'unknown')" >&2
  echo "  - Attempted Transition: → COMPLETE" >&2
  echo "  - Workflow Type: debug-only" >&2
  echo "  - Terminal State: complete" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Debug phase did not complete" >&2
  echo "  - State not persisted properly" >&2
  echo "  - Terminal state misconfigured" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  - Check debug checkpoint output" >&2
  echo "  - Verify workflow_type is debug-only" >&2
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

# Cleanup temp state file
rm -f "${HOME}/.claude/tmp/debug_state_$$.txt"

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
/debug "authentication timeout errors in production"

# Higher complexity investigation
/debug "intermittent database connection failures --complexity 3"

# Performance issue
/debug "API endpoint latency exceeds 2s on POST /api/users"
```
