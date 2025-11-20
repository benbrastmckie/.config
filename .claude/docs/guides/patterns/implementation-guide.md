# Implementation Guide

**Path**: docs → guides → implementation-guide.md

This guide covers implementation workflows, phase execution, and best practices for executing implementation plans.

## Contents

- [Phase Execution](#phase-execution)
- [Implementation Workflow](#implementation-workflow)

---

# Phase Execution Protocol

This document provides comprehensive documentation for the phase execution protocol used by the /implement command.

**Referenced by**: [implement.md](../../commands/implement.md)

**Contents**:
- Step-by-Step Phase Execution
- Progressive Structure Navigation
- Task Execution and Testing
- Commit Workflow
- Error Handling

---

## Phase Execution Protocol

Execute phases either sequentially (traditional) or in parallel waves (with dependencies).

**Execution Modes**:
- **Sequential**: Execute phases in order (Phase 1, 2, 3, ...) when no dependencies declared
- **Parallel**: Parse dependencies into waves, execute waves sequentially, parallelize phases within waves (>1 phase per wave)

**Wave Execution Flow**:
1. **Wave Initialization**: Identify phases in current wave, log wave execution start
2. **Phase Preparation**: Display phase number, name, tasks for each phase in wave
3. **Complexity Analysis**: Run analyzer, calculate hybrid complexity score (see Step 1.5)
4. **Agent Selection** (using $COMPLEXITY_SCORE from Step 1.5):
   - Direct execution (0-2), code-writer (3-5), code-writer + think (6-7), code-writer + think hard (8-9), code-writer + think harder (10+)
   - Special case overrides: doc-writer (documentation), test-specialist (testing), debug-specialist (debug)
5. **Delegation**: Invoke agent via Task tool with behavioral injection, monitor PROGRESS markers
6. **Testing and Commit**: Execute for all phases in wave (see subsequent sections)

**Pattern Details**: See [Single Agent with Behavioral Injection](command-patterns.md#pattern-single-agent-with-behavioral-injection) for delegation patterns.

### 1.4. Check Expansion Status

Before implementing the phase, check if it's already expanded and display current structure:

```bash
# Detect plan structure level
LEVEL=$(.claude/lib/plan-core-bundle.sh detect_structure_level "$PLAN_PATH")

# Check if current phase is expanded
IS_PHASE_EXPANDED=$(.claude/lib/plan-core-bundle.sh is_phase_expanded "$PLAN_PATH" "$CURRENT_PHASE")
```

**Display Structure Information:**
- **Level 0**: "Plan Structure: Level 0 (all phases inline)"
- **Level 1**: "Plan Structure: Level 1 (Phase X expanded, other phases inline)"
- **Level 2**: "Plan Structure: Level 2 (Phase X with stage expansion)"

This is informational only and helps understand the current plan organization.

### 1.5. Hybrid Complexity Evaluation

Evaluate phase complexity using hybrid approach: threshold-based scoring with agent evaluation for borderline cases (score ≥7 or ≥8 tasks).

**When to Use**:
- **Every phase**: Always evaluate complexity before implementation
- **Borderline cases**: Automatic agent invocation for context-aware analysis
- **Agent triggers**: Threshold score ≥7 OR task count ≥8

**Workflow Overview**:
1. Calculate threshold-based score (complexity-utils.sh)
2. Determine if agent evaluation needed (borderline thresholds)
3. Run hybrid_complexity_evaluation function (may invoke agent)
4. Parse result (final_score, evaluation_method, agent_reasoning)
5. Log evaluation for analytics (unified-logger.sh)
6. Export COMPLEXITY_SCORE for downstream decisions (expansion, agent selection)

**Key Execution Requirements**:

1. **Threshold calculation** (uses complexity-utils.sh):
   ```bash
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/complexity-utils.sh"
   THRESHOLD_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$TASK_LIST")
   TASK_COUNT=$(echo "$TASK_LIST" | grep -c "^- \[ \]" || echo "0")
   ```

2. **Hybrid evaluation with agent fallback**:
   ```bash
   # Determine if agent needed (score ≥7 OR tasks ≥8)
   AGENT_NEEDED="false"
   [ "$THRESHOLD_SCORE" -ge 7 ] || [ "$TASK_COUNT" -ge 8 ] && AGENT_NEEDED="true"

   # Run hybrid evaluation (may invoke complexity_estimator agent)
   EVALUATION_RESULT=$(hybrid_complexity_evaluation "$PHASE_NAME" "$TASK_LIST" "$PLAN_FILE")
   COMPLEXITY_SCORE=$(echo "$EVALUATION_RESULT" | jq -r '.final_score')
   EVALUATION_METHOD=$(echo "$EVALUATION_RESULT" | jq -r '.evaluation_method')  # "threshold", "agent", or "reconciled"
   ```

3. **Logging and analytics**:
   ```bash
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-logger.sh"
   log_complexity_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "$COMPLEXITY_THRESHOLD_HIGH" "$AGENT_NEEDED"

   # Log discrepancy if agent evaluation differed from threshold
   [ "$EVALUATION_METHOD" != "threshold" ] && log_complexity_discrepancy "$PHASE_NAME" "$THRESHOLD_SCORE" "$AGENT_SCORE" "$SCORE_DIFF" "$AGENT_REASONING" "$EVALUATION_METHOD"
   ```

4. **Export for downstream use**:
   ```bash
   export COMPLEXITY_SCORE      # Used by Steps 1.55 (Proactive Expansion) and 1.6 (Agent Selection)
   export EVALUATION_METHOD
   ```

**Quick Example**:
```bash
# Calculate threshold score
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/complexity-utils.sh"
THRESHOLD_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$TASK_LIST")
TASK_COUNT=$(echo "$TASK_LIST" | grep -c "^- \[ \]")

# Run hybrid evaluation (auto-invokes agent if borderline)
EVALUATION_RESULT=$(hybrid_complexity_evaluation "$PHASE_NAME" "$TASK_LIST" "$PLAN_FILE")
COMPLEXITY_SCORE=$(echo "$EVALUATION_RESULT" | jq -r '.final_score')
EVALUATION_METHOD=$(echo "$EVALUATION_RESULT" | jq -r '.evaluation_method')

echo "Complexity Score: $COMPLEXITY_SCORE ($EVALUATION_METHOD)"

# Log and export
log_complexity_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "$COMPLEXITY_THRESHOLD_HIGH" "$([ $THRESHOLD_SCORE -ge 7 ] && echo 'true' || echo 'false')"
export COMPLEXITY_SCORE EVALUATION_METHOD
```

**Expected Impact**: 30% reduction in expansion errors via context-aware evaluation

**Error Handling**: Agent timeout/failure/invalid response → Fallback to threshold score (all fallbacks logged)

### 1.55. Proactive Expansion Check

Before implementation, evaluate if phase should be expanded using agent-based judgment.

**Note**: This step uses the hybrid complexity score ($COMPLEXITY_SCORE) from Step 1.5.

**Evaluation criteria**: Task complexity, scope breadth, interrelationships, parallel work potential, clarity vs detail tradeoff

**If expansion recommended**: Display formatted recommendation with rationale and `/expand phase` command

**If not needed**: Continue silently to implementation

**Relationship to reactive expansion** (Step 3.4):
- **Proactive** (1.55): Before implementation, recommendation only
- **Reactive** (3.4): After implementation, auto-revision via `/revise --auto-mode`

### 1.6. Parallel Wave Execution

For parallel agent invocation patterns, see [Parallel Agent Invocation](command-patterns.md#pattern-parallel-agent-invocation).

**Single Phase Wave**: Execute normally (agent delegation or direct), wait, proceed to testing

**Multi-Phase Wave**:
1. Invoke all phases in parallel using multiple Task tool calls in one message
2. Wait for wave completion, collect results, aggregate progress markers
3. Check for failures: If any failed, stop execution and save checkpoint
4. Proceed to wave testing and commit all changes together

**Parallelism limits**: Max 3 concurrent phases per wave, split into sub-waves if needed

### 2. Implementation
Create or modify the necessary files according to the plan specifications.

**If Agent Delegated**: Use agent's output
**If Direct Execution**: Implement manually following standards

### 3. Testing
Run tests by:
- Looking for test commands in the phase tasks
- Checking for common test patterns (npm test, pytest, make test)
- Running language-specific test commands based on project type

### 3.3. Automatic Debug Integration (if tests fail)

**When to Use Automatic Debug Integration**:
- **Test failures** in any phase during implementation
- **Automatic triggers**: No manual invocation needed
- **Tiered recovery**: 4 escalating levels of error handling

**Quick Overview**:
1. Classify error type and display suggestions (error-handling.sh)
2. Retry transient errors (timeout, busy, locked) with extended timeout
3. Retry tool access errors with reduced toolset fallback
4. Auto-invoke /debug agent for root cause analysis
5. Present user choices: (r)evise, (c)ontinue, (s)kip, (a)bort
6. Execute chosen action and update plan with debugging notes

**Pattern Details**: See [Error Recovery Patterns](command-patterns.md#error-recovery-patterns) for complete tiered recovery workflow.

**Key Execution Requirements**:

1. **Error classification** (uses error-handling.sh):
   ```bash
   source "$CLAUDE_PROJECT_DIR/.claude/lib/core/error-handling.sh"
   ERROR_TYPE=$(detect_error_type "$TEST_OUTPUT")  # → syntax, test_failure, timeout, etc.
   SUGGESTIONS=$(generate_suggestions "$ERROR_TYPE" "$TEST_OUTPUT" "$ERROR_LOCATION")
   ```

2. **Automatic /debug invocation** (Level 4):
   ```bash
   DEBUG_RESULT=$(invoke_slash_command "/debug \"Phase $CURRENT_PHASE failure\" \"$PLAN_PATH\"")
   DEBUG_REPORT_PATH=$(extract_report_path "$DEBUG_RESULT")
   # Fallback: .claude/lib/analyze-error.sh if /debug fails
   ```

3. **User choice actions**:
   - **(r)evise**: Invoke `/revise --auto-mode` with debug findings, retry phase
   - **(c)ontinue**: Mark `[INCOMPLETE]`, add debugging notes, proceed to next phase
   - **(s)kip**: Mark `[SKIPPED]`, add debugging notes, proceed to next phase
   - **(a)bort**: Save checkpoint with debug info, exit for manual intervention

**Quick Example - Tiered Recovery**:
```bash
# Level 1: Classify and suggest
source "$UTILS_DIR/error-handling.sh"
ERROR_TYPE=$(detect_error_type "$TEST_OUTPUT")  # → "syntax"
echo "Error Type: $ERROR_TYPE"
echo "$(generate_suggestions "$ERROR_TYPE" "$TEST_OUTPUT")"

# Level 2: Transient retry (if timeout/busy)
if [ "$ERROR_TYPE" = "timeout" ]; then
  RETRY_META=$(retry_with_timeout "Phase 3 tests" "$ATTEMPT_NUMBER")
  # Retry with extended timeout if SHOULD_RETRY=true
fi

# Level 3: Tool fallback (if tool access error)
if echo "$TEST_OUTPUT" | grep -qi "tool.*failed"; then
  FALLBACK_META=$(retry_with_fallback "Phase 3" "$ATTEMPT_NUMBER")
  # Retry with REDUCED_TOOLSET
fi

# Level 4: Auto-invoke /debug
DEBUG_RESULT=$(invoke_slash_command "/debug \"Phase 3 test failure\" \"plan.md\"")
DEBUG_REPORT_PATH=$(echo "$DEBUG_RESULT" | grep -o 'specs/reports/.*\.md')

# Present choices
echo "Choose: (r)evise, (c)ontinue, (s)kip, (a)bort"
read -p "Action: " USER_CHOICE

case "$USER_CHOICE" in
  r) invoke_slash_command "/revise --auto-mode --context '$REVISION_CONTEXT' '$PLAN_PATH'" ;;
  c) add_debugging_notes "$PLAN_PATH" "$CURRENT_PHASE" "$DEBUG_REPORT_PATH" "Incomplete" ;;
  s) add_debugging_notes "$PLAN_PATH" "$CURRENT_PHASE" "$DEBUG_REPORT_PATH" "Skipped" ;;
  a) save_checkpoint "paused" "$CURRENT_PHASE" "$CURRENT_PHASE"; exit 0 ;;
esac
```

**Error Categories**: syntax, test_failure, file_not_found, import_error, null_error, timeout, permission, unknown

**Helper Function**: `add_debugging_notes(plan_path, phase_num, debug_report_path, root_cause, resolution_status)`
- Creates "#### Debugging Notes" section with date, issue, report link, root cause, resolution
- Appends iterations for repeat failures, escalates after 3+ attempts

**Benefits**: 50% faster debug workflow, 4-level tiered recovery, graceful degradation, clear user choices

### 3.4. Adaptive Planning Detection

**Overview**: See [Adaptive Planning Features](#adaptive-planning-features) section for full details.

**Workflow**:
1. Load checkpoint and check replan limits (max 2 per phase)
2. Detect triggers: Complexity (score >8 or >10 tasks), Test failure pattern (2+ consecutive), Scope drift (manual flag)
3. Build revision context JSON and invoke `/revise --auto-mode`
4. Parse response: Update checkpoint, increment counters, log replan history
5. Loop prevention: Escalate to user if limit reached

**Trigger types**:
- **expand_phase**: Complexity threshold exceeded
- **add_phase**: Test failure pattern detected
- **update_tasks**: Scope drift flagged

### 3.5. Update Debug Resolution (if tests pass for previously-failed phase)
**Check if this phase was previously debugged:**

**Step 1: Check for Debugging Notes**
- Read current phase section in plan
- Look for "#### Debugging Notes" subsection
- Check if it contains "Resolution: Pending"

**Step 2: Update Resolution**
- If debugging notes exist and tests now pass:
  - Use Edit tool to update: `Resolution: Pending` → `Resolution: Applied`
  - Add git commit hash line (will be added after commit)
  - This marks that the debugging led to a successful fix

**Step 3: Add Fix Commit Hash (after git commit)**
- After git commit succeeds
- If resolution was updated: Add commit hash to debugging notes
- Format: `Fix Applied In: [commit-hash]`

**Example:**
```markdown
#### Debugging Notes
- **Date**: 2025-10-03
- **Issue**: Phase failed with null pointer
- **Debug Report**: [../reports/026_debug.md](../../specs/reports/026_debug.md)
- **Root Cause**: Missing null check
- **Resolution**: Applied
- **Fix Applied In**: abc1234
```

### 4. Git Commit
Create a structured commit:
```
feat: implement Phase N - Phase Name

Automated implementation of phase N from implementation plan
All tests passed successfully

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 5. Plan Update (After Git Commit Succeeds)

Update plan files incrementally after each successful phase completion.

**Update Steps**:
1. **Mark tasks complete**: Use Edit tool to change `- [ ]` → `- [x]` in appropriate file based on expansion status
2. **Add completion marker**: Change `### Phase N: Phase Name` → `### Phase N: Phase Name [COMPLETED]`
3. **Verify updates**: Read updated file and verify all phase tasks show `[x]`
4. **Update progress section**: Add/update "## Implementation Progress" with last phase, date, commit, status, resume command

**Level-Aware Updates**: Use progressive utilities (is_phase_expanded, is_stage_expanded) to determine correct file location (Level 0: main plan only, Level 1: phase file or main plan, Level 2: stage file, phase file, or main plan)

**Progress Section Content**: Last completed phase, completion date, git commit hash, status "In Progress (M/N phases complete)", resume instructions `/implement <plan-file> <next-phase-number>`

### 5.5. Automatic Collapse Detection

Automatically evaluate if an expanded phase should be collapsed back to the main plan file after completion.

**Trigger Conditions**: Phase is expanded (separate file) AND phase is completed (all tasks marked [x])

**Collapse Thresholds**: Tasks ≤ 5 AND Complexity < 6.0 (both required, conservative approach)

**Workflow**:
1. Check phase expansion and completion status (plan-core-bundle.sh)
2. Extract metrics: task count, complexity score (complexity-utils.sh)
3. Log evaluation (log_collapse_check for observability)
4. If thresholds met: Build collapse context JSON, invoke `/revise --auto-mode collapse_phase`
5. Update plan path if structure level changed (Level 1 → Level 0)
6. Log collapse invocation (log_collapse_invocation for audit trail)

**Pattern Details**: See [Adaptive Planning Features](#adaptive-planning-features) for collapse workflow integration.

**Logging**: All evaluations logged to `.claude/logs/adaptive-planning.log`

**Non-Blocking**: Collapse failures logged but don't stop implementation

**Edge Cases**: Phase with stages (collapse stages first), incomplete phase (skipped), complex phase (not triggered), structure level change (plan path updated)

### 6. Incremental Summary Generation

Create or update partial summary after each phase completion to track implementation progress.

**Workflow**:
1. Extract specs directory and determine summary path: `[specs-dir]/summaries/NNN_partial.md`
2. Create (first phase) or update (subsequent phases) partial summary using Write/Edit tools
3. Update with status "in_progress", phases completed "M/N", last phase details, commit hash, resume instructions

**Required Content**:
- Metadata: Date started, specs directory, plan link, status, phases completed count
- Progress: Last completed phase (name, date, commit), phases checklist with completion dates
- Resume: Instructions for `/implement [plan-path] M+1` (auto-resume enabled by default)
- Notes: Brief implementation observations

**Template Reference**: See finalized summaries in `specs/summaries/` for structure examples

### 7. Before Starting Next Phase
**Defensive check before proceeding:**

**Step 1: Read Current Plan State**
- Use Read tool to read plan file
- Find previous phase heading

**Step 2: Verify Previous Phase Complete**
- Check that previous phase has `[COMPLETED]` marker
- Check that previous phase tasks are `[x]`

**Step 3: Mark Complete if Missing (Defensive)**
- If previous phase not marked but commit exists: Mark it now
- Log warning about inconsistency
- This ensures plan stays consistent even if previous update failed


---

# Implementation Workflow

This document describes the complete workflow for implementing plans using the /implement command.

**Referenced by**: [implement.md](../../commands/implement.md)

**Contents**:
- Plan Discovery and Validation
- Progressive Structure Navigation
- Phase-by-Phase Execution
- Checkpoint Management
- Completion and Summary

---

## Process

### Utility Initialization

Initialize required utilities for consistent error handling, state management, and logging before beginning implementation.

**When to Initialize**:
- **Before implementation**: Run once at command start
- **Required utilities**: 5 core utilities (error, checkpoint, complexity, logger, agent-registry)
- **Optional**: Progress dashboard if `--dashboard` flag present

**Initialization Overview**:
1. Detect project directory (sets CLAUDE_PROJECT_DIR)
2. Source and verify 5 core utilities
3. Initialize adaptive planning logger
4. Initialize progress dashboard if enabled (terminal capability detection)

**Pattern Details**: See [Standard Logger Setup](command-patterns.md#pattern-standard-logger-setup) for logger initialization patterns.

**Key Execution Requirements**:

1. **Detect project directory**:
   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "$SCRIPT_DIR/../lib/core/detect-project-dir.sh"  # Sets CLAUDE_PROJECT_DIR
   ```

2. **Verify core utilities**:
   ```bash
   UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
   [ -f "$UTILS_DIR/error-handling.sh" ] || { echo "ERROR: error-handling.sh not found"; exit 1; }
   [ -f "$UTILS_DIR/checkpoint-utils.sh" ] || { echo "ERROR: checkpoint-utils.sh not found"; exit 1; }
   [ -f "$UTILS_DIR/complexity-utils.sh" ] || { echo "ERROR: complexity-utils.sh not found"; exit 1; }
   [ -f "$UTILS_DIR/unified-logger.sh" ] || { echo "ERROR: unified-logger.sh not found"; exit 1; }
   [ -f "$UTILS_DIR/# agent-registry-utils.sh (removed)" ] || { echo "ERROR: # agent-registry-utils.sh (removed) not found"; exit 1; }
   ```

3. **Initialize logger** (`.claude/logs/adaptive-planning.log`, 10MB max, 5 files retained):
   ```bash
   source "$UTILS_DIR/unified-logger.sh"
   ```

4. **Initialize dashboard** (optional, with terminal capability detection):
   ```bash
   if [ "$DASHBOARD_FLAG" = "true" ] && [ -f "$UTILS_DIR/progress-dashboard.sh" ]; then
     source "$UTILS_DIR/progress-dashboard.sh"
     TERMINAL_CAPABILITIES=$(detect_terminal_capabilities)
     [ "$(echo "$TERMINAL_CAPABILITIES" | jq -r '.ansi_supported')" = "true" ] && DASHBOARD_ENABLED=true
   fi
   ```

**Quick Example**:
```bash
# Step 1: Detect project
source "$SCRIPT_DIR/../lib/core/detect-project-dir.sh"

# Step 2 & 3: Source utilities and logger
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
for util in error-handling.sh checkpoint-utils.sh complexity-utils.sh unified-logger.sh # agent-registry-utils.sh (removed); do
  [ -f "$UTILS_DIR/$util" ] || { echo "ERROR: $util not found"; exit 1; }
done
source "$UTILS_DIR/adaptive-planning-logger.sh"

# Step 4: Dashboard (optional)
[ "$DASHBOARD_FLAG" = "true" ] && source "$UTILS_DIR/progress-dashboard.sh" && initialize_dashboard "$PLAN_NAME" "$TOTAL_PHASES"
```

**Logging Events**: log_complexity_check, log_test_failure_pattern, log_scope_drift, log_replan_invocation, log_loop_prevention, log_collapse_check

**Dashboard Lifecycle**: initialize_dashboard → update_dashboard_phase (after each phase) → clear_dashboard (on completion)

### Progressive Plan Support

This command supports all three progressive structure levels:

**Step 0: Detect Plan Structure Level**
```bash
# Use adaptive plan parser to detect structure
LEVEL=$(.claude/lib/plan-core-bundle.sh detect_structure_level "$PLAN_PATH")
# Returns: 0 (single-file), 1 (phase-expanded), or 2 (stage-expanded)
```

**Level-Aware Processing**:
- **Level 0**: Single-file processing (all phases inline)
- **Level 1**: Process main plan and expanded phase files
- **Level 2**: Navigate hierarchy (main plan → phase directories → stage files)

**Unified Interface**:
All level-specific differences are abstracted by progressive utilities:
- `is_plan_expanded`: Check if plan has directory structure
- `is_phase_expanded`: Check if specific phase is in separate file
- `is_stage_expanded`: Check if specific stage is in separate file
- `list_expanded_phases`: Get numbers of expanded phases
- `list_expanded_stages`: Get numbers of expanded stages

### Implementation Flow

Let me first locate the implementation plan:

1. **Detect and parse the plan** to identify:
   - Plan structure level (0, 1, or 2) using plan-core-bundle.sh
   - Expanded phases and stages (via progressive parsing utilities)
   - Referenced research reports (if any)
   - Standards file path (if captured in plan metadata)
2. **Discover and load standards**:
   - Find CLAUDE.md files (working directory and subdirectories)
   - Extract Code Standards, Testing Protocols, Documentation Policy
   - Note standards for application during implementation
3. **Check for research reports**:
   - Extract report paths from plan metadata
   - Note reports for summary generation
4. **For each phase**:
   - Display the phase name and tasks
   - Implement changes following discovered standards
   - Run tests using standards-defined test commands
   - Verify compliance with standards before completing
   - Update the plan file with completion markers
   - Create a git commit with a structured message
   - Move to the next phase
5. **After all phases complete**:
   - Generate implementation summary
   - Update referenced reports if needed
   - Link plan and reports in summary

### Step 0.5: Dry-Run Mode Execution (if --dry-run flag present)

Execute preview mode instead of actual implementation when `--dry-run` flag detected. See [Dry-Run Mode](#dry-run-mode-preview-and-validation) for feature details and output examples.

**Execution Workflow**:
1. Parse flag and plan metadata
2. Analyze phases (complexity, agent assignment, duration via hybrid_complexity_evaluation)
3. Generate execution waves (parse-phase-dependencies.sh)
4. Display formatted preview (Unicode box-drawing with waves, phases, agents, files, tests, estimates)
5. Prompt and either exit or continue to normal flow

**Implementation**: Phase analysis uses hybrid_complexity_evaluation(); agent assignment maps complexity to types; duration from # agent-registry-utils.sh (removed); wave display shows sequential/parallel patterns; file/test extraction via regex

