---
allowed-tools: Task, TodoWrite, Read, Bash
argument-hint: <workflow-description> [--parallel] [--sequential] [--create-pr] [--dry-run]
description: Coordinate subagents through end-to-end development workflows (state machine architecture)
command-type: primary
dependent-commands: research, plan, implement, debug, test, document, github-specialist
---

<!-- ═══════════════════════════════════════════════════════════════ -->
<!-- CRITICAL ARCHITECTURAL PATTERN - DO NOT VIOLATE                 -->
<!-- ═══════════════════════════════════════════════════════════════ -->
<!-- /orchestrate MUST NEVER invoke other slash commands             -->
<!-- FORBIDDEN TOOLS: SlashCommand                                   -->
<!-- REQUIRED PATTERN: Task tool → Specialized agents                -->
<!-- ═══════════════════════════════════════════════════════════════ -->

# Multi-Agent Workflow Orchestration (State Machine)

YOU MUST orchestrate a 7-phase development workflow by delegating to specialized subagents.

**Documentation**: See `.claude/docs/guides/orchestrate-command-guide.md`

**YOUR ROLE**: Workflow orchestrator (NOT executor)
- Use ONLY Task tool to invoke specialized agents
- Coordinate agents, verify outputs, manage checkpoints
- Forward agent results without re-summarization

**EXECUTION MODEL**: Pure orchestration with state machine (States: initialize → research → plan → implement → test → debug → document → complete)

---

## State Machine Initialization

## CRITICAL: Argument Substitution Required

**BEFORE calling the Bash tool**, you MUST perform argument substitution:

**Step 1**: Identify arguments from the user's command
- The user invoked: `/orchestrate "<workflow-description>" [options]`
- Extract the workflow description and any option flags

**Step 2**: In the bash block below, find these lines:
```bash
WORKFLOW_DESCRIPTION="$1"
WORKFLOW_OPTIONS="$2 $3 $4"
```

**Step 3**: Replace with actual values:
```bash
WORKFLOW_DESCRIPTION="<actual description>"
WORKFLOW_OPTIONS="<actual options or empty>"
```

**Example**: If user ran `/orchestrate "implement auth" --parallel --create-pr`, change:
- FROM: `WORKFLOW_DESCRIPTION="$1"`
- TO: `WORKFLOW_DESCRIPTION="implement auth"`
- FROM: `WORKFLOW_OPTIONS="$2 $3 $4"`
- TO: `WORKFLOW_OPTIONS="--parallel --create-pr "`

**Why**: The Bash tool cannot receive positional parameters. You must substitute them yourself.

**Now execute** the bash block WITH THE SUBSTITUTION APPLIED:

```bash
echo "=== State Machine Orchestration (Pure Agent Delegation) ==="
echo ""

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Parse workflow description and options
WORKFLOW_DESCRIPTION="$1"
WORKFLOW_OPTIONS="$2 $3 $4"

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description required"
  echo "Usage: /orchestrate \"<workflow description>\" [--parallel] [--sequential] [--create-pr] [--dry-run]"
  exit 1
fi

export WORKFLOW_DESCRIPTION WORKFLOW_OPTIONS

# Source state machine and state persistence libraries
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

if [ ! -f "${LIB_DIR}/workflow-state-machine.sh" ]; then
  echo "ERROR: workflow-state-machine.sh not found"
  exit 1
fi
source "${LIB_DIR}/workflow-state-machine.sh"

if [ ! -f "${LIB_DIR}/state-persistence.sh" ]; then
  echo "ERROR: state-persistence.sh not found"
  exit 1
fi
source "${LIB_DIR}/state-persistence.sh"

# Initialize workflow state (GitHub Actions pattern)
STATE_FILE=$(init_workflow_state "orchestrate_$$")
trap "rm -f '$STATE_FILE'" EXIT

# Save workflow ID
append_workflow_state "WORKFLOW_ID" "orchestrate_$$"

# Initialize state machine
sm_init "$WORKFLOW_DESCRIPTION" "orchestrate"

# Save state machine configuration
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
append_workflow_state "TERMINAL_STATE" "$TERMINAL_STATE"
append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"

# Source unified location detection
if [ ! -f "${LIB_DIR}/unified-location-detection.sh" ]; then
  echo "ERROR: unified-location-detection.sh not found"
  exit 1
fi
source "${LIB_DIR}/unified-location-detection.sh"

# Perform location detection
LOCATION_JSON=$(perform_location_detection "$WORKFLOW_DESCRIPTION" "false")

# Extract topic directory paths
if command -v jq &>/dev/null; then
  TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
  TOPIC_NUMBER=$(echo "$LOCATION_JSON" | jq -r '.topic_number')
  TOPIC_NAME=$(echo "$LOCATION_JSON" | jq -r '.topic_name')
  ARTIFACT_REPORTS=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
  ARTIFACT_PLANS=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.plans')
  ARTIFACT_SUMMARIES=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.summaries')
else
  TOPIC_PATH=$(echo "$LOCATION_JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  TOPIC_NUMBER=$(echo "$LOCATION_JSON" | grep -o '"topic_number": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  TOPIC_NAME=$(echo "$LOCATION_JSON" | grep -o '"topic_name": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  ARTIFACT_REPORTS="${TOPIC_PATH}/reports"
  ARTIFACT_PLANS="${TOPIC_PATH}/plans"
  ARTIFACT_SUMMARIES="${TOPIC_PATH}/summaries"
fi

# Save to workflow state
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "TOPIC_NUMBER" "$TOPIC_NUMBER"
append_workflow_state "TOPIC_NAME" "$TOPIC_NAME"
append_workflow_state "ARTIFACT_REPORTS" "$ARTIFACT_REPORTS"
append_workflow_state "ARTIFACT_PLANS" "$ARTIFACT_PLANS"
append_workflow_state "ARTIFACT_SUMMARIES" "$ARTIFACT_SUMMARIES"

# Define error handling helper
handle_state_error() {
  local error_message="$1"
  local current_state="${CURRENT_STATE:-unknown}"
  local exit_code="${2:-1}"

  echo ""
  echo "ERROR in state '$current_state': $error_message"
  echo ""
  echo "State Machine Context:"
  echo "  Workflow: $WORKFLOW_DESCRIPTION"
  echo "  Scope: $WORKFLOW_SCOPE"
  echo "  Current State: $current_state"
  echo "  Terminal State: $TERMINAL_STATE"
  echo ""

  # Save failed state
  append_workflow_state "FAILED_STATE" "$current_state"
  append_workflow_state "LAST_ERROR" "$error_message"

  # Increment retry counter
  RETRY_COUNT_VAR="RETRY_COUNT_${current_state}"
  # Use eval for indirect variable expansion (safe: variable name is constructed from known state)
  # Alternative ${!VAR} syntax fails with history expansion errors
  RETRY_COUNT=$(eval echo "\${${RETRY_COUNT_VAR}:-0}")
  RETRY_COUNT=$((RETRY_COUNT + 1))
  append_workflow_state "$RETRY_COUNT_VAR" "$RETRY_COUNT"

  if [ $RETRY_COUNT -ge 2 ]; then
    echo "Max retries (2) reached for state '$current_state'"
    exit $exit_code
  else
    echo "Retry $RETRY_COUNT/2 available"
    exit $exit_code
  fi
}
export -f handle_state_error

# Transition to research state
sm_transition "$STATE_RESEARCH"

echo ""
echo "State Machine Initialized:"
echo "  Scope: $WORKFLOW_SCOPE"
echo "  Current State: $CURRENT_STATE"
echo "  Terminal State: $TERMINAL_STATE"
echo "  Topic: $TOPIC_PATH"
echo ""
```

---

## State Handler: Research

**State**: Execute when `CURRENT_STATE == "research"`

USE the Bash tool:

```bash
load_workflow_state "orchestrate_$$"

# Check terminal state
if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  echo "✓ Workflow complete at terminal state: $TERMINAL_STATE"
  exit 0
fi

# Verify state
if [ "$CURRENT_STATE" != "$STATE_RESEARCH" ]; then
  handle_state_error "Expected state 'research' but current state is '$CURRENT_STATE'" 1
fi

# Determine research complexity
RESEARCH_COMPLEXITY=2

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "^(fix|update|modify).*(one|single|small)"; then
  RESEARCH_COMPLEXITY=1
fi

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"; then
  RESEARCH_COMPLEXITY=3
fi

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "multi-.*system|cross-.*platform|distributed|microservices"; then
  RESEARCH_COMPLEXITY=4
fi

echo "Research State: Invoking $RESEARCH_COMPLEXITY research agents in parallel"
```

**EXECUTE NOW**: USE the Task tool to invoke research-specialist agents (1 to $RESEARCH_COMPLEXITY in parallel):

Task {
  subagent_type: "general-purpose"
  description: "Research [topic] with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    Research Topic: [specific topic]
    Report Path: ${ARTIFACT_REPORTS}/[001-00X]_[topic].md
    Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md

    Return: REPORT_CREATED: [absolute path]
  "
}

USE the Bash tool:

```bash
load_workflow_state "orchestrate_$$"

echo "✓ Research agents invoked - verifying outputs..."

# Determine next state based on workflow scope
case "$WORKFLOW_SCOPE" in
  research-only)
    sm_transition "$STATE_COMPLETE"
    append_workflow_state "CURRENT_STATE" "$STATE_COMPLETE"
    echo "✓ Research-only workflow complete"
    exit 0
    ;;
  *)
    sm_transition "$STATE_PLAN"
    append_workflow_state "CURRENT_STATE" "$STATE_PLAN"
    ;;
esac

echo "Research complete → Planning"
```

---

## State Handler: Planning

**State**: Execute when `CURRENT_STATE == "plan"`

USE the Bash tool:

```bash
load_workflow_state "orchestrate_$$"

# Check terminal state
if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  echo "✓ Workflow complete"
  exit 0
fi

# Verify state
if [ "$CURRENT_STATE" != "$STATE_PLAN" ]; then
  handle_state_error "Expected state 'plan' but current state is '$CURRENT_STATE'" 1
fi

echo "Planning State: Creating implementation plan"
```

**EXECUTE NOW**: USE the Task tool to invoke plan-architect:

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan guided by research"
  timeout: 300000
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    Workflow Description: $WORKFLOW_DESCRIPTION
    Research Reports: ${ARTIFACT_REPORTS}/*.md
    Plan Output: ${ARTIFACT_PLANS}/001_implementation.md

    Create detailed implementation plan.
    Return: PLAN_CREATED: [absolute path]
  "
}

USE the Bash tool:

```bash
load_workflow_state "orchestrate_$$"

PLAN_PATH="${ARTIFACT_PLANS}/001_implementation.md"

if [ ! -f "$PLAN_PATH" ]; then
  handle_state_error "Plan file not created at: $PLAN_PATH" 1
fi

echo "✓ Plan verified: $PLAN_PATH"
append_workflow_state "PLAN_PATH" "$PLAN_PATH"

# Determine next state
case "$WORKFLOW_SCOPE" in
  research-and-plan)
    sm_transition "$STATE_COMPLETE"
    append_workflow_state "CURRENT_STATE" "$STATE_COMPLETE"
    echo "✓ Research-and-plan workflow complete"
    exit 0
    ;;
  *)
    sm_transition "$STATE_IMPLEMENT"
    append_workflow_state "CURRENT_STATE" "$STATE_IMPLEMENT"
    ;;
esac

echo "Planning complete → Implementation"
```

---

## State Handler: Implementation

**State**: Execute when `CURRENT_STATE == "implement"`

USE the Bash tool:

```bash
load_workflow_state "orchestrate_$$"

if [ "$CURRENT_STATE" != "$STATE_IMPLEMENT" ]; then
  handle_state_error "Expected state 'implement' but current state is '$CURRENT_STATE'" 1
fi

echo "Implementation State: Executing plan with wave-based parallelism"
```

**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator:

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation with wave-based parallel execution"
  timeout: 600000
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    Plan File: $PLAN_PATH
    Workflow Options: $WORKFLOW_OPTIONS

    Execute implementation with:
    - Wave-based parallel execution for independent phases
    - Automated testing after each wave
    - Git commits for completed phases

    Return: IMPLEMENTATION_COMPLETE: [summary]
  "
}

USE the Bash tool:

```bash
load_workflow_state "orchestrate_$$"

echo "✓ Implementation complete"
append_workflow_state "IMPLEMENTATION_OCCURRED" "true"

sm_transition "$STATE_TEST"
append_workflow_state "CURRENT_STATE" "$STATE_TEST"

echo "Implementation complete → Testing"
```

---

## State Handler: Testing

**State**: Execute when `CURRENT_STATE == "test"`

USE the Bash tool:

```bash
load_workflow_state "orchestrate_$$"

if [ "$CURRENT_STATE" != "$STATE_TEST" ]; then
  handle_state_error "Expected state 'test' but current state is '$CURRENT_STATE'" 1
fi

echo "Testing State: Running comprehensive test suite"
```

**EXECUTE NOW**: USE the Task tool to invoke test-specialist:

Task {
  subagent_type: "general-purpose"
  description: "Execute comprehensive test suite"
  timeout: 300000
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-specialist.md

    Test all implementations from: $PLAN_PATH
    Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md

    Run comprehensive tests and report results.
    Return: TESTS_COMPLETE: pass|fail [details]
  "
}

USE the Bash tool:

```bash
load_workflow_state "orchestrate_$$"

# Parse test result from agent response
# In production, this would extract from agent output
TEST_RESULT="pass"  # Placeholder

append_workflow_state "TEST_RESULT" "$TEST_RESULT"

if [ "$TEST_RESULT" = "pass" ]; then
  echo "✓ All tests passed"
  sm_transition "$STATE_DOCUMENT"
  append_workflow_state "CURRENT_STATE" "$STATE_DOCUMENT"
  echo "Testing complete → Documentation"
else
  echo "❌ Tests failed"
  sm_transition "$STATE_DEBUG"
  append_workflow_state "CURRENT_STATE" "$STATE_DEBUG"
  echo "Testing failed → Debug"
fi
```

---

## State Handler: Debug (Conditional)

**State**: Execute when `CURRENT_STATE == "debug"`

USE the Bash tool:

```bash
load_workflow_state "orchestrate_$$"

if [ "$CURRENT_STATE" != "$STATE_DEBUG" ]; then
  handle_state_error "Expected state 'debug' but current state is '$CURRENT_STATE'" 1
fi

echo "Debug State: Analyzing test failures"
```

**EXECUTE NOW**: USE the Task tool to invoke debug-analyst:

Task {
  subagent_type: "general-purpose"
  description: "Analyze test failures and propose fixes"
  timeout: 300000
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    Analyze test failures from implementation.
    Create debug report at: ${TOPIC_PATH}/debug/001_debug_report.md

    Return: DEBUG_COMPLETE: [report path]
  "
}

USE the Bash tool:

```bash
load_workflow_state "orchestrate_$$"

echo "✓ Debug analysis complete"

# In production workflow, user would fix issues and re-run
sm_transition "$STATE_COMPLETE"
append_workflow_state "CURRENT_STATE" "$STATE_COMPLETE"

echo "Debug analysis complete. Manual fixes required."
echo "Re-run workflow after fixes."
```

---

## State Handler: Documentation

**State**: Execute when `CURRENT_STATE == "document"`

USE the Bash tool:

```bash
load_workflow_state "orchestrate_$$"

if [ "$CURRENT_STATE" != "$STATE_DOCUMENT" ]; then
  handle_state_error "Expected state 'document' but current state is '$CURRENT_STATE'" 1
fi

echo "Documentation State: Creating summary and updating docs"
```

**EXECUTE NOW**: USE the Task tool to invoke doc-writer:

Task {
  subagent_type: "general-purpose"
  description: "Create implementation summary and update documentation"
  timeout: 300000
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/doc-writer.md

    Create summary: ${ARTIFACT_SUMMARIES}/001_implementation_summary.md
    Plan: $PLAN_PATH
    Reports: ${ARTIFACT_REPORTS}/*.md

    Update all relevant documentation.
    Return: DOCUMENTATION_COMPLETE: [summary path]
  "
}

USE the Bash tool:

```bash
load_workflow_state "orchestrate_$$"

echo "✓ Documentation complete"

sm_transition "$STATE_COMPLETE"
append_workflow_state "CURRENT_STATE" "$STATE_COMPLETE"

echo ""
echo "✓ Workflow Complete"
echo "  Topic: $TOPIC_PATH"
echo "  Plan: $PLAN_PATH"
echo "  Summary: ${ARTIFACT_SUMMARIES}/001_implementation_summary.md"
echo ""
```

---

## Workflow Completion

State machine has reached `STATE_COMPLETE`. All workflow artifacts are available in the topic directory.
