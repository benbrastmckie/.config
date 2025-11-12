---
allowed-tools: Task, TodoWrite, Bash, Read
---

# /supervise - Multi-Agent Workflow Orchestration (State Machine)

YOU ARE THE WORKFLOW ORCHESTRATOR using state machine architecture for clean multi-agent delegation.

**Documentation**: See `.claude/docs/guides/supervise-guide.md` and `.claude/docs/reference/supervise-phases.md`

**EXECUTION MODEL**: State-driven orchestration (States: initialize → research → plan → implement → test → debug → document → complete)

**CRITICAL RULES**:
- Use ONLY Task tool for agent invocations (NEVER SlashCommand)
- Pre-calculate all paths before agent invocations
- Verify outputs at mandatory checkpoints
- Forward agent metadata (not full summaries)

---

## State Machine Initialization

## CRITICAL: Argument Substitution Required

**BEFORE calling the Bash tool**, you MUST perform argument substitution:

**Step 1**: Identify the workflow description argument from the user's command
- The user invoked: `/supervise "<workflow-description>"`
- Extract the `<workflow-description>` text

**Step 2**: In the bash block below, find this line:
```bash
WORKFLOW_DESCRIPTION="$1"
```

**Step 3**: Replace `"$1"` with the actual quoted workflow description:
```bash
WORKFLOW_DESCRIPTION="<actual workflow description goes here>"
```

**Example**: If user ran `/supervise "implement user authentication"`, change:
- FROM: `WORKFLOW_DESCRIPTION="$1"`
- TO: `WORKFLOW_DESCRIPTION="implement user authentication"`

**Why**: The Bash tool cannot receive positional parameters. You must do the substitution yourself.

**Now execute** the bash block WITH THE SUBSTITUTION APPLIED:

```bash
echo "=== State Machine Workflow Orchestration ==="

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Parse workflow description
WORKFLOW_DESCRIPTION="$1"

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description required"
  echo "Usage: /supervise \"<workflow description>\""
  exit 1
fi

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

# Initialize workflow state
STATE_FILE=$(init_workflow_state "supervise_$$")
trap "rm -f '$STATE_FILE'" EXIT

append_workflow_state "WORKFLOW_ID" "supervise_$$"

# Initialize state machine
sm_init "$WORKFLOW_DESCRIPTION" "supervise"

append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
append_workflow_state "TERMINAL_STATE" "$TERMINAL_STATE"
append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"

# Source unified location detection
source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh"

# Pre-calculate paths
LOCATION_JSON=$(perform_location_detection "$WORKFLOW_DESCRIPTION" "false")

if command -v jq &>/dev/null; then
  TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
  REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
  PLANS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.plans')
  SUMMARIES_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.summaries')
else
  TOPIC_PATH=$(echo "$LOCATION_JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  REPORTS_DIR="${TOPIC_PATH}/reports"
  PLANS_DIR="${TOPIC_PATH}/plans"
  SUMMARIES_DIR="${TOPIC_PATH}/summaries"
fi

# Save to state
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "REPORTS_DIR" "$REPORTS_DIR"
append_workflow_state "PLANS_DIR" "$PLANS_DIR"
append_workflow_state "SUMMARIES_DIR" "$SUMMARIES_DIR"

# Error handling
handle_state_error() {
  local error_message="$1"
  echo ""
  echo "ERROR in state '$CURRENT_STATE': $error_message"
  echo "Workflow: $WORKFLOW_DESCRIPTION"
  append_workflow_state "FAILED_STATE" "$CURRENT_STATE"
  append_workflow_state "LAST_ERROR" "$error_message"
  exit 1
}
export -f handle_state_error

# Transition to research
sm_transition "$STATE_RESEARCH"

echo "State Machine Initialized:"
echo "  Scope: $WORKFLOW_SCOPE"
echo "  Current State: $CURRENT_STATE"
echo "  Topic: $TOPIC_PATH"
```

---

## State Handler: Research

USE the Bash tool:

```bash
load_workflow_state "supervise_$$"

if [ "$CURRENT_STATE" = "$TERMINAL_STATE" ]; then
  echo "✓ Workflow complete"
  exit 0
fi

if [ "$CURRENT_STATE" != "$STATE_RESEARCH" ]; then
  handle_state_error "Expected research state"
fi

# Determine complexity
RESEARCH_COMPLEXITY=2
[[ "$WORKFLOW_DESCRIPTION" =~ (fix|update|modify).*(one|single|small) ]] && RESEARCH_COMPLEXITY=1
[[ "$WORKFLOW_DESCRIPTION" =~ integrate|migration|refactor|architecture ]] && RESEARCH_COMPLEXITY=3

echo "Research: $RESEARCH_COMPLEXITY topics"
```

**EXECUTE NOW**: USE the Task tool for research-specialist (invoke $RESEARCH_COMPLEXITY times in parallel):

Task {
  subagent_type: "general-purpose"
  description: "Research [topic]"
  timeout: 300000
  prompt: "
    Read: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    Topic: [specific topic name]
    Output: [pre-calculated reports directory]/[001-00N]_[topic].md
    Standards: [project CLAUDE.md path]

    Return: REPORT_CREATED: [absolute path to created report]
  "
}

USE the Bash tool:

```bash
load_workflow_state "supervise_$$"

case "$WORKFLOW_SCOPE" in
  research-only)
    sm_transition "$STATE_COMPLETE"
    echo "✓ Research complete"
    exit 0
    ;;
  *)
    sm_transition "$STATE_PLAN"
    ;;
esac
```

---

## State Handler: Planning

USE the Bash tool:

```bash
load_workflow_state "supervise_$$"

if [ "$CURRENT_STATE" != "$STATE_PLAN" ]; then
  handle_state_error "Expected plan state"
fi

echo "Planning state"
```

**EXECUTE NOW**: USE the Task tool for plan-architect:

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  timeout: 300000
  prompt: "
    Read: ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    Workflow: [workflow description from user]
    Reports: [pre-calculated reports directory]/*.md
    Output: [pre-calculated plans directory]/001_implementation.md

    Return: PLAN_CREATED: [absolute path to created plan]
  "
}

USE the Bash tool:

```bash
load_workflow_state "supervise_$$"

PLAN_PATH="${PLANS_DIR}/001_implementation.md"
[ ! -f "$PLAN_PATH" ] && handle_state_error "Plan not created"

append_workflow_state "PLAN_PATH" "$PLAN_PATH"

case "$WORKFLOW_SCOPE" in
  research-and-plan)
    sm_transition "$STATE_COMPLETE"
    echo "✓ Planning complete"
    exit 0
    ;;
  *)
    sm_transition "$STATE_IMPLEMENT"
    ;;
esac
```

---

## State Handler: Implementation

USE the Bash tool:

```bash
load_workflow_state "supervise_$$"

if [ "$CURRENT_STATE" != "$STATE_IMPLEMENT" ]; then
  handle_state_error "Expected implement state"
fi

echo "Implementation state"
```

**EXECUTE NOW**: USE the Task tool for implementer-coordinator:

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation"
  timeout: 600000
  prompt: "
    Read: ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md
    
    Plan: $PLAN_PATH
    
    Return: IMPLEMENTATION_COMPLETE
  "
}

USE the Bash tool:

```bash
load_workflow_state "supervise_$$"

sm_transition "$STATE_TEST"
```

---

## State Handler: Testing

USE the Bash tool:

```bash
load_workflow_state "supervise_$$"

if [ "$CURRENT_STATE" != "$STATE_TEST" ]; then
  handle_state_error "Expected test state"
fi

echo "Testing state"
```

**EXECUTE NOW**: USE the Task tool for test-specialist:

Task {
  subagent_type: "general-purpose"
  description: "Run comprehensive tests"
  timeout: 300000
  prompt: "
    Read: ${CLAUDE_PROJECT_DIR}/.claude/agents/test-specialist.md
    
    Plan: $PLAN_PATH
    
    Return: TESTS_COMPLETE: pass|fail
  "
}

USE the Bash tool:

```bash
load_workflow_state "supervise_$$"

# Parse test result (simplified - production would extract from agent)
TEST_RESULT="pass"

if [ "$TEST_RESULT" = "pass" ]; then
  sm_transition "$STATE_DOCUMENT"
else
  sm_transition "$STATE_DEBUG"
fi
```

---

## State Handler: Debug (Conditional)

USE the Bash tool:

```bash
load_workflow_state "supervise_$$"

if [ "$CURRENT_STATE" != "$STATE_DEBUG" ]; then
  handle_state_error "Expected debug state"
fi

echo "Debug state"
```

**EXECUTE NOW**: USE the Task tool for debug-analyst:

Task {
  subagent_type: "general-purpose"
  description: "Analyze failures"
  timeout: 300000
  prompt: "
    Read: ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md
    
    Plan: $PLAN_PATH
    Output: ${TOPIC_PATH}/debug/001_debug.md
    
    Return: DEBUG_COMPLETE
  "
}

USE the Bash tool:

```bash
load_workflow_state "supervise_$$"

sm_transition "$STATE_COMPLETE"
echo "Debug complete - manual fixes required"
```

---

## State Handler: Documentation

USE the Bash tool:

```bash
load_workflow_state "supervise_$$"

if [ "$CURRENT_STATE" != "$STATE_DOCUMENT" ]; then
  handle_state_error "Expected document state"
fi

echo "Documentation state"
```

**EXECUTE NOW**: USE the Task tool for doc-writer:

Task {
  subagent_type: "general-purpose"
  description: "Create summary"
  timeout: 300000
  prompt: "
    Read: ${CLAUDE_PROJECT_DIR}/.claude/agents/doc-writer.md

    Plan: [implementation plan path]
    Reports: [research reports directory]/*.md
    Output: [summaries directory]/001_summary.md

    Return: DOCUMENTATION_COMPLETE: [absolute path to summary]
  "
}

USE the Bash tool:

```bash
load_workflow_state "supervise_$$"

sm_transition "$STATE_COMPLETE"

echo ""
echo "✓ Workflow Complete"
echo "  Topic: $TOPIC_PATH"
echo "  Plan: $PLAN_PATH"
echo "  Summary: ${SUMMARIES_DIR}/001_summary.md"
```

---

## Workflow Complete

State machine reached terminal state. All artifacts available in topic directory.
