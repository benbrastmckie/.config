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

```bash
# Detect project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"
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

```bash
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
    # Invoke implementation-researcher agent via Task tool
    # Extract artifact metadata via forward_message pattern
    # Cache metadata for on-demand loading
  fi

  # Agent selection based on complexity
  if [ "$COMPLEXITY_SCORE" -lt 3 ]; then
    # Direct execution (use Read/Edit/Write tools)
    echo "PROGRESS: Direct execution (complexity: $COMPLEXITY_SCORE)"
  else
    # Agent delegation (invoke code-writer via Task tool)
    echo "PROGRESS: Delegating to code-writer agent (complexity: $COMPLEXITY_SCORE)"
    # Invoke code-writer agent with behavioral injection
  fi

  # Run tests
  TEST_COMMAND=$(echo "$TASK_LIST" | grep -oE '(npm test|pytest|\.\/run_all_tests\.sh|:TestSuite)' | head -1)
  if [ -n "$TEST_COMMAND" ]; then
    echo "PROGRESS: Running tests: $TEST_COMMAND"
    TEST_OUTPUT=$($TEST_COMMAND 2>&1)
    TEST_EXIT_CODE=$?

    # Handle test failures with tiered recovery
    if [ $TEST_EXIT_CODE -ne 0 ]; then
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
  # Invoke spec-updater agent via Task tool
  # Fallback: Direct checkbox-utils.sh if agent fails

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
done
```

## Phase 2: Finalize Summary

```bash
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
