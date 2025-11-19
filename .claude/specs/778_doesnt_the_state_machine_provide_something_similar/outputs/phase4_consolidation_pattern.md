# Phase 4: Block Consolidation Pattern for /research

## Overview

This document describes the block consolidation pattern to be applied to /research command.

## Current Structure (7 blocks)

```
Block 1 (line 35): Part 1 - Capture workflow description
Block 2 (line 52): Part 2 - Read and validate description
Block 3 (line 110): Part 3 - State machine initialization
Block 4 (line 222): Part 3a - Classification parsing
Block 5 (line 257): Part 3b - Research phase execution
Block 6 (line 333): Research artifact verification
Block 7 (line 386): Part 4 - Completion & cleanup
```

## Target Structure (3 blocks)

### Block 1: Setup
Combines: Parts 1, 2, 3, 3a

Operations:
- Capture workflow description to temp file
- Read and validate description
- Parse --complexity flag
- Detect CLAUDE_PROJECT_DIR
- Source all libraries (with suppression)
- Generate WORKFLOW_ID
- Initialize workflow state
- Initialize state machine
- Persist variables

Output: Single summary line "Setup complete: $WORKFLOW_ID"

### Block 2: Execute
Combines: Parts 3b and artifact verification

Operations:
- Transition to research state
- Initialize workflow paths
- Create reports directory
- Persist path variables
- **Task invocation for research-specialist** (this must remain separate)
- Verify artifacts created
- Persist REPORT_COUNT

### Block 3: Cleanup
Combines: Part 4

Operations:
- Load workflow state
- Transition to complete
- Display summary
- Exit

## Key Insight: Task Tool Limitation

The Task tool invocation for the research-specialist agent MUST remain between bash blocks. Claude Code executes bash blocks and Task invocations sequentially, and the Task result must be available before the next bash block runs.

Therefore, the practical minimum is:
- Block 1: All setup through state initialization
- Task: Research specialist invocation
- Block 2: Verification and completion

This gives us 2 bash blocks + 1 Task, which is the consolidation target.

## Implementation Pattern

```bash
# Block 1: Consolidated Setup
set +H
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/research_arg_$(date +%s%N).txt"
echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "$TEMP_FILE"

# Read and validate immediately (same block)
WORKFLOW_DESCRIPTION=$(cat "$TEMP_FILE")
[[ -z "$WORKFLOW_DESCRIPTION" ]] && { echo "ERROR: Empty description" >&2; exit 1; }

# Parse complexity
DEFAULT_COMPLEXITY=2
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"
if [[ "$WORKFLOW_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  WORKFLOW_DESCRIPTION=$(echo "$WORKFLOW_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi

# Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi
export CLAUDE_PROJECT_DIR

# Source libraries with suppression
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh" 2>/dev/null

# Initialize state
WORKFLOW_ID="research_$(date +%s)"
echo "$WORKFLOW_ID" > "${HOME}/.claude/tmp/research_state_id.txt"
export WORKFLOW_ID
init_workflow_state "$WORKFLOW_ID"

# Initialize state machine
sm_init "$WORKFLOW_DESCRIPTION" "research" "research-only" "$RESEARCH_COMPLEXITY" "[]" >/dev/null 2>&1

# Transition to research and setup paths
sm_transition "$STATE_RESEARCH" 2>/dev/null
initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "research-only" "$RESEARCH_COMPLEXITY" ""
mkdir -p "${TOPIC_PATH}/reports"

# Persist for Block 2
append_workflow_state "RESEARCH_DIR" "${TOPIC_PATH}/reports"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "WORKFLOW_DESCRIPTION" "$WORKFLOW_DESCRIPTION"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"

echo "Setup complete: $WORKFLOW_ID (research-only, complexity: $RESEARCH_COMPLEXITY)"
```

## Completion Status

This pattern document serves as the design specification for Phase 4.

Full implementation requires:
1. Applying this pattern to research.md
2. Extensive testing to verify no regressions
3. Documentation updates

The pattern demonstrates 67% block reduction (7 -> 2-3 blocks).
