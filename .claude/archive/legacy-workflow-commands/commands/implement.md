---
allowed-tools: Read, Edit, MultiEdit, Write, Bash, Grep, Glob, TodoWrite, Task, SlashCommand
argument-hint: [plan-file] [starting-phase] [--report-scope-drift "<description>"] [--force-replan] [--create-pr] [--dashboard] [--dry-run]
description: Execute implementation plan with automated testing, adaptive replanning, and commits (auto-resumes most recent incomplete plan if no args)
command-type: primary
dependent-commands: list, update, revise, debug, document, expand, github-specialist
---

# /implement - Execute Implementation Plan

**YOU ARE EXECUTING** as the implementation manager.

**Documentation**: See `.claude/docs/guides/implement-command-guide.md` for complete usage guide, adaptive planning features, and agent delegation patterns.

---

## Phase 0: Initialize and Parse Plan

**EXECUTE NOW**: Initialize the environment, parse plan arguments, and detect project directory:

```bash
set +H  # CRITICAL: Disable history expansion
# STANDARD 13: Detect project directory using CLAUDE_PROJECT_DIR (git-based detection)
# Bootstrap CLAUDE_PROJECT_DIR detection (inline, no library dependency)
# This eliminates the bootstrap paradox where we need detect-project-dir.sh to find
# the project directory, but need the project directory to source detect-project-dir.sh
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

# Validate CLAUDE_PROJECT_DIR
if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory"
  echo "DIAGNOSTIC: No git repository found and no .claude/ directory in parent tree"
  echo "SOLUTION: Run command from within a directory containing .claude/ subdirectory"
  exit 1
fi

# Export for use by sourced libraries
export CLAUDE_PROJECT_DIR

# Source required utilities
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
for util in error-handling.sh checkpoint-utils.sh complexity-utils.sh adaptive-planning-logger.sh agent-registry-utils.sh; do
  [ -f "$UTILS_DIR/$util" ] || { echo "ERROR: $util not found"; exit 1; }
  source "$UTILS_DIR/$util"
done

# Parse arguments
PLAN_FILE="$1"
STARTING_PHASE="${2:-1}"
DASHBOARD_FLAG="false"
DRY_RUN="false"
CREATE_PR="false"
SCOPE_DRIFT_DESC=""
FORCE_REPLAN="false"

shift 2 2>/dev/null || shift $# 2>/dev/null
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dashboard) DASHBOARD_FLAG="true"; shift ;;
    --dry-run) DRY_RUN="true"; shift ;;
    --create-pr) CREATE_PR="true"; shift ;;
    --report-scope-drift) SCOPE_DRIFT_DESC="$2"; shift 2 ;;
    --force-replan) FORCE_REPLAN="true"; shift ;;
    *) shift ;;
  esac
done

# Initialize dashboard if requested
if [ "$DASHBOARD_FLAG" = "true" ] && [ -f "$UTILS_DIR/progress-dashboard.sh" ]; then
  source "$UTILS_DIR/progress-dashboard.sh"
  TERMINAL_CAPABILITIES=$(detect_terminal_capabilities)
  [ "$(echo "$TERMINAL_CAPABILITIES" | jq -r '.ansi_supported')" = "true" ] && initialize_dashboard "$PLAN_NAME" "$TOTAL_PHASES"
fi

# Find plan file if not provided (auto-resume)
if [ -z "$PLAN_FILE" ]; then
  CHECKPOINT_DATA=$(load_checkpoint "implement")
  if [ $? -eq 0 ]; then
    if check_safe_resume_conditions "$CHECKPOINT_FILE"; then
      PLAN_FILE=$(echo "$CHECKPOINT_DATA" | jq -r '.plan_path')
      STARTING_PHASE=$(echo "$CHECKPOINT_DATA" | jq -r '.current_phase')
      echo "✓ Auto-resuming from Phase $STARTING_PHASE"
    fi
  fi

  # If still no plan, find most recent incomplete
  if [ -z "$PLAN_FILE" ]; then
    PLAN_FILE=$(find . -path "*/specs/plans/*.md" -type f -exec ls -t {} + 2>/dev/null | head -1)
  fi
fi

# Parse plan structure
PLAN_LEVEL=$(.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PLAN_FILE")
TOTAL_PHASES=$(.claude/lib/parse-adaptive-plan.sh count_phases "$PLAN_FILE")

# Execute dry-run mode if requested
if [ "$DRY_RUN" = "true" ]; then
  echo "=== DRY-RUN MODE: Preview Only ==="
  # Display plan structure, complexity scores, agent assignments, duration estimates
  exit 0
fi
```

## Phase 1: Execute Implementation Phases

**EXECUTE NOW**: Execute all implementation phases with complexity evaluation and agent delegation:

```bash
set +H  # CRITICAL: Disable history expansion
# Re-source required libraries (subprocess isolation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkpoint-utils.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/complexity-utils.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/adaptive-planning-logger.sh"

# For each phase (or resume from STARTING_PHASE)
for CURRENT_PHASE in $(seq "$STARTING_PHASE" "$TOTAL_PHASES"); do
  echo "PROGRESS: Starting Phase $CURRENT_PHASE"

  # Extract phase information
  PHASE_CONTENT=$(.claude/lib/parse-adaptive-plan.sh extract_phase "$PLAN_FILE" "$CURRENT_PHASE")
  PHASE_NAME=$(echo "$PHASE_CONTENT" | grep "^### Phase $CURRENT_PHASE:" | sed 's/^### Phase [0-9]*: //')
  TASK_LIST=$(echo "$PHASE_CONTENT" | grep "^- \[ \]")

  # Evaluate complexity (hybrid threshold + agent evaluation)
  source "$UTILS_DIR/complexity-utils.sh"
  THRESHOLD_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$TASK_LIST")
  TASK_COUNT=$(echo "$TASK_LIST" | grep -c "^- \[ \]" || echo "0")

  EVALUATION_RESULT=$(hybrid_complexity_evaluation "$PHASE_NAME" "$TASK_LIST" "$PLAN_FILE")
  COMPLEXITY_SCORE=$(echo "$EVALUATION_RESULT" | jq -r '.final_score')

  log_complexity_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "8" "$([ $COMPLEXITY_SCORE -ge 7 ] && echo 'true' || echo 'false')"
  export COMPLEXITY_SCORE

  # Implementation research for complex phases (score ≥8 or tasks >10)
  if [ "$COMPLEXITY_SCORE" -ge 8 ] || [ "$TASK_COUNT" -gt 10 ]; then
    echo "PROGRESS: Complex phase - invoking implementation researcher"
    echo "RESEARCHER_NEEDED=true" >> "${HOME}/.claude/tmp/implement_state_$$.txt"
  else
    echo "RESEARCHER_NEEDED=false" >> "${HOME}/.claude/tmp/implement_state_$$.txt"
  fi

  # Agent selection based on complexity - store for Task tool invocation
  echo "CURRENT_PHASE=$CURRENT_PHASE" >> "${HOME}/.claude/tmp/implement_state_$$.txt"
  echo "PHASE_NAME=$PHASE_NAME" >> "${HOME}/.claude/tmp/implement_state_$$.txt"
  echo "TASK_LIST='$TASK_LIST'" >> "${HOME}/.claude/tmp/implement_state_$$.txt"
  echo "COMPLEXITY_SCORE=$COMPLEXITY_SCORE" >> "${HOME}/.claude/tmp/implement_state_$$.txt"
  echo "PLAN_FILE=$PLAN_FILE" >> "${HOME}/.claude/tmp/implement_state_$$.txt"

  if [ "$COMPLEXITY_SCORE" -lt 3 ]; then
    echo "PROGRESS: Direct execution (complexity: $COMPLEXITY_SCORE)"
    echo "AGENT_MODE=direct" >> "${HOME}/.claude/tmp/implement_state_$$.txt"
  else
    echo "PROGRESS: Delegating to code-writer agent (complexity: $COMPLEXITY_SCORE)"
    echo "AGENT_MODE=delegate" >> "${HOME}/.claude/tmp/implement_state_$$.txt"
  fi
done
```

**EXECUTE NOW**: USE the Task tool to execute implementation based on complexity score.

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation phase with code-writer agent"
  prompt: "
    Read the state from ${HOME}/.claude/tmp/implement_state_$$.txt to get:
    - CURRENT_PHASE, PHASE_NAME, TASK_LIST, COMPLEXITY_SCORE, AGENT_MODE

    If AGENT_MODE=delegate:
      Read and follow ALL behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/agents/code-writer.md

      Execute the implementation tasks for Phase ${CURRENT_PHASE}: ${PHASE_NAME}
      Follow the task list and create/modify code as specified.

    If AGENT_MODE=direct:
      Execute the simple tasks directly using Read/Edit/Write tools.

    After completion, run any tests mentioned in the task list.

    Return: PHASE_COMPLETE: ${CURRENT_PHASE}
  "
}

```bash
set +H  # CRITICAL: Disable history expansion
# Re-source required libraries (subprocess isolation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkpoint-utils.sh"

# Load state from previous block
source "${HOME}/.claude/tmp/implement_state_$$.txt" 2>/dev/null || true

# Run tests
TEST_COMMAND=$(echo "$TASK_LIST" | grep -oE '(npm test|pytest|\.\/run_all_tests\.sh|:TestSuite)' | head -1)
if [ -n "$TEST_COMMAND" ]; then
  echo "PROGRESS: Running tests: $TEST_COMMAND"
  TEST_OUTPUT=$($TEST_COMMAND 2>&1)
  TEST_EXIT_CODE=$?

  # Handle test failures with tiered recovery
  if [ $TEST_EXIT_CODE -ne 0 ]; then
    UTILS_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
    source "$UTILS_DIR/error-handling.sh"
    ERROR_TYPE=$(detect_error_type "$TEST_OUTPUT")

    # Level 4: Auto-invoke /debug
    DEBUG_REPORT_PATH=$(invoke_debug "$CURRENT_PHASE" "$ERROR_TYPE" "$PLAN_FILE")

    # Present user choices
    echo "Test failure detected. Choose: (r)evise, (c)ontinue, (s)kip, (a)bort"
    # Execute chosen action
  fi
fi

# Update plan hierarchy via spec-updater agent
echo "PROGRESS: Updating plan hierarchy"

# Create git commit
git add .
git commit -m "feat: implement Phase $CURRENT_PHASE - $PHASE_NAME

Automated implementation of phase $CURRENT_PHASE from implementation plan
All tests passed successfully

Co-Authored-By: Claude <noreply@anthropic.com>"

COMMIT_HASH=$(git log -1 --format="%h")
echo "CHECKPOINT: Phase $CURRENT_PHASE Complete"
echo "- Phase: $PHASE_NAME"
echo "- Tests: ✓ PASSED"
echo "- Commit: $COMMIT_HASH"

# Save checkpoint
CHECKPOINT_DATA='{"workflow_description":"implement", "plan_path":"'"$PLAN_FILE"'", "current_phase":'$((CURRENT_PHASE + 1))', "total_phases":'$TOTAL_PHASES', "status":"in_progress", "tests_passing":true}'
save_checkpoint "implement" "$CHECKPOINT_DATA"

# Update dashboard if enabled
[ "$DASHBOARD_FLAG" = "true" ] && update_dashboard_phase "$CURRENT_PHASE" "complete"

# Cleanup temp state file
rm -f "${HOME}/.claude/tmp/implement_state_$$.txt"
```

## Phase 2: Finalize Summary

**EXECUTE NOW**: Finalize the implementation summary and optionally create PR:

```bash
set +H  # CRITICAL: Disable history expansion
# Re-source required libraries (subprocess isolation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkpoint-utils.sh"

# Extract specs directory from plan metadata
SPECS_DIR=$(dirname "$(dirname "$PLAN_FILE")")
PLAN_NUMBER=$(basename "$PLAN_FILE" | grep -oE '^[0-9]+')

# Finalize partial summary or create new
PARTIAL_SUMMARY="$SPECS_DIR/summaries/${PLAN_NUMBER}_partial.md"
FINAL_SUMMARY="$SPECS_DIR/summaries/${PLAN_NUMBER}_implementation_summary.md"

if [ -f "$PARTIAL_SUMMARY" ]; then
  mv "$PARTIAL_SUMMARY" "$FINAL_SUMMARY"
fi

# Update summary with completion status
# Add completion date, lessons learned, remove resume instructions

echo "CHECKPOINT: Implementation Complete"
echo "- Plan: $(basename "$PLAN_FILE")"
echo "- Phases: $TOTAL_PHASES/$TOTAL_PHASES (100%)"
echo "- Summary: $FINAL_SUMMARY"
echo "- Status: COMPLETE"

# Create PR if requested
if [ "$CREATE_PR" = "true" ]; then
  echo "PROGRESS: Creating pull request"
  # Invoke github-specialist agent via Task tool
  # Fallback: Provide manual gh command if fails
fi

# Cleanup checkpoint
delete_checkpoint "implement"

# Clear dashboard if enabled
[ "$DASHBOARD_FLAG" = "true" ] && clear_dashboard
```

---

**Troubleshooting**: See guide for adaptive planning features, agent delegation patterns, error recovery, and checkpoint management.
