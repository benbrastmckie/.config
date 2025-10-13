---
allowed-tools: Read, Edit, MultiEdit, Write, Bash, Grep, Glob, TodoWrite, Task, SlashCommand
argument-hint: [plan-file] [starting-phase] [--report-scope-drift "<description>"] [--force-replan] [--create-pr]
description: Execute implementation plan with automated testing, adaptive replanning, and commits (auto-resumes most recent incomplete plan if no args)
command-type: primary
dependent-commands: list, update, revise, debug, document, expand, github-specialist
---

# Execute Implementation Plan

I'll help you systematically implement the plan file with automated testing and commits at each phase.

## Plan Information
- **Plan file**: $1 (or I'll find the most recent incomplete plan)
- **Starting phase**: $2 (default: resume from last incomplete phase or 1)

## Adaptive Planning Features

This command includes intelligent plan revision capabilities that detect when replanning is needed during implementation:

**Automatic Triggers:**
1. **Complexity Detection**: Phases with complexity score >8 or >10 tasks trigger phase expansion
2. **Test Failure Patterns**: 2+ consecutive test failures in same phase suggests missing prerequisites
3. **Scope Drift**: Manual flag `--report-scope-drift "description"` for discovered out-of-scope work

**Behavior:**
- Automatically invokes `/revise --auto-mode` when triggers detected
- Updates plan structure (expands phases, adds phases, or updates tasks)
- Continues implementation with revised plan
- Maximum 2 replans per phase prevents infinite loops

**Shared Utilities Integration:**
- **Checkpoint Management**: Uses `.claude/lib/checkpoint-utils.sh` for workflow state persistence
- **Complexity Analysis**: Uses `.claude/lib/complexity-utils.sh` for phase complexity scoring
- **Adaptive Logging**: Uses `.claude/lib/adaptive-planning-logger.sh` for trigger evaluation logging
- **Error Handling**: Uses `.claude/lib/error-utils.sh` for error classification and recovery

These shared utilities provide consistent, tested implementations across all commands.

**Safety:**
- Loop prevention with replan counters tracked in checkpoints
- Replan history logged for audit trail
- User escalation when limits exceeded
- Manual override via `--force-replan` flag

**Example Usage:**
```bash
# Normal implementation (automatic detection enabled)
/implement specs/plans/025_plan.md

# Manual scope drift reporting
/implement specs/plans/025_plan.md 3 --report-scope-drift "Database migration needed before schema changes"

# Force replan despite limit (requires manual approval)
/implement specs/plans/025_plan.md 4 --force-replan
```

## Auto-Resume Feature
If no plan file is provided, I will:
1. Search for the most recently modified implementation plan
2. Check if it has incomplete phases or tasks
3. Resume from the first incomplete phase
4. If all recent plans are complete, show a list to choose from

## Standards Discovery and Application

For standards discovery patterns, see:
- [Upward CLAUDE.md Search](../docs/command-patterns.md#pattern-upward-claudemd-search)
- [Standards Section Extraction](../docs/command-patterns.md#pattern-standards-section-extraction)
- [Standards Application During Code Generation](../docs/command-patterns.md#pattern-standards-application-during-code-generation)
- [Fallback Behavior](../docs/command-patterns.md#pattern-fallback-behavior)

**Implement-specific application**:
- Apply Code Standards during code generation (indentation, naming, error handling)
- Use Testing Protocols for test execution and validation
- Follow Documentation Policy for new modules
- Verify compliance before marking each phase complete
- Document applied standards in commit messages

## Process

### Utility Initialization

Before beginning implementation, initialize all required utilities for consistent error handling, state management, and logging.

**Step 1: Detect Project Directory**
```bash
# Detect project root dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"
# Sets: CLAUDE_PROJECT_DIR
```

**Step 2: Source Shared Utilities**

Use Bash tool to verify utilities are available:
```bash
# Verify and prepare utilities
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"

# Core utilities (required)
[ -f "$UTILS_DIR/error-utils.sh" ] || { echo "ERROR: error-utils.sh not found"; exit 1; }
[ -f "$UTILS_DIR/checkpoint-utils.sh" ] || { echo "ERROR: checkpoint-utils.sh not found"; exit 1; }
[ -f "$UTILS_DIR/complexity-utils.sh" ] || { echo "ERROR: complexity-utils.sh not found"; exit 1; }
[ -f "$UTILS_DIR/adaptive-planning-logger.sh" ] || { echo "ERROR: adaptive-planning-logger.sh not found"; exit 1; }
[ -f "$UTILS_DIR/agent-registry-utils.sh" ] || { echo "ERROR: agent-registry-utils.sh not found"; exit 1; }

echo "✓ All required utilities available"
```

**Step 3: Initialize Logger**

For logger setup pattern, see [Standard Logger Setup](../docs/command-patterns.md#pattern-standard-logger-setup).

```bash
# Initialize adaptive planning logger
source "$UTILS_DIR/adaptive-planning-logger.sh"

# Logger is now available for all subsequent operations
```

**Implement-specific logging events**:
- Complexity threshold evaluations (log_complexity_check)
- Test failure pattern detection (log_test_failure_pattern)
- Scope drift detections (log_scope_drift)
- Replan invocations (log_replan_invocation)
- Loop prevention enforcement (log_loop_prevention)
- Collapse opportunity evaluations (log_collapse_check)

**Log file**: `.claude/logs/adaptive-planning.log` (10MB max, 5 files retained)

**Integration Complete**: All shared utilities are now available for use throughout implementation

### Progressive Plan Support

This command supports all three progressive structure levels:

**Step 0: Detect Plan Structure Level**
```bash
# Use adaptive plan parser to detect structure
LEVEL=$(.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")
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
   - Plan structure level (0, 1, or 2) using parse-adaptive-plan.sh
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

## Parallel Execution with Dependencies

Before executing phases, I will analyze phase dependencies to enable parallel execution:

### Dependency Analysis

**Step 1: Parse Dependencies**
```bash
# Use dependency parser to generate execution waves
WAVES=$(.claude/lib/parse-phase-dependencies.sh "$PLAN_FILE")
```

**Step 2: Group Phases into Waves**
- Parse wave output: `WAVE_1:1`, `WAVE_2:2 3`, `WAVE_3:4`
- Each wave contains phases that can execute in parallel
- Waves execute sequentially (wait for wave completion before next)

**Step 3: Execute Waves**

For each wave:
1. **Single Phase**: Execute normally (sequential)
2. **Multiple Phases**: Execute in parallel
   - Invoke multiple agents simultaneously using multiple Task tool calls in one message
   - Each phase gets its own agent based on complexity analysis
   - Wait for all phases in wave to complete
   - Collect results from all parallel executions

**Step 4: Error Handling**
- If any phase in a wave fails, stop execution
- Preserve checkpoint with partial completion
- Report which phases succeeded and which failed
- User can resume from failed wave

### Parallel Execution Safety

- **Max Parallelism**: Limit to 3 concurrent phases per wave
- **Fail-Fast**: Stop wave execution if any phase fails
- **Checkpoint Preservation**: Save state after each wave
- **Result Collection**: Aggregate test results and file changes from parallel phases

### Dependency Format

Phases declare dependencies in their header:
```markdown
### Phase N: Phase Name
dependencies: [1, 2]  # Depends on phases 1 and 2
```

- Empty array `[]` or omitted = no dependencies (can run in wave 1)
- Multiple dependencies = wait for all to complete
- Circular dependencies are detected and rejected

## Phase Execution Protocol

### Execution Flow

**Sequential Execution** (no dependencies or dependencies: [] omitted):
- Execute phases one by one in order (Phase 1, 2, 3, ...)
- Traditional workflow, fully backward compatible

**Parallel Execution** (with dependency declarations):
- Parse dependencies into execution waves
- Execute each wave sequentially
- Within each wave, execute phases in parallel if wave contains >1 phase
- Wait for wave completion before next wave

For each wave, I will:

### 0. Wave Initialization
- Identify phases in current wave from dependency analysis
- Log: "Executing Wave N with M phase(s): [phase numbers]"

For each phase in the wave, I will prepare:

### 1. Display Phase Information
Show the phase number, name, and all tasks that need to be completed.

### 1.5. Phase Complexity Analysis and Agent Selection

For agent delegation patterns, see [Single Agent with Behavioral Injection](../docs/command-patterns.md#pattern-single-agent-with-behavioral-injection).

**Implement-specific complexity scoring**:

1. **Run complexity analyzer**:
   ```bash
   .claude/lib/analyze-phase-complexity.sh "<phase-name>" "<task-list>"
   ```

2. **Agent selection thresholds**:
   - **Direct execution** (score 0-2): Simple phases
   - **code-writer** (score 3-5): Medium complexity
   - **code-writer + think** (score 6-7): Medium-high complexity
   - **code-writer + think hard** (score 8-9): High complexity
   - **code-writer + think harder** (score 10+): Critical complexity

3. **Special case overrides**:
   - **doc-writer**: Documentation/README phases
   - **test-specialist**: Testing phases
   - **debug-specialist**: Debug/investigation phases

**Delegation workflow**:
- Announce delegation with complexity score
- Invoke agent via Task tool with behavioral injection
- Monitor PROGRESS markers for visibility
- Collect results for testing and commit steps

### 1.4. Check Expansion Status

Before implementing the phase, check if it's already expanded and display current structure:

```bash
# Detect plan structure level
LEVEL=$(.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")

# Check if current phase is expanded
IS_PHASE_EXPANDED=$(.claude/lib/parse-adaptive-plan.sh is_phase_expanded "$PLAN_PATH" "$CURRENT_PHASE")
```

**Display Structure Information:**
- **Level 0**: "Plan Structure: Level 0 (all phases inline)"
- **Level 1**: "Plan Structure: Level 1 (Phase X expanded, other phases inline)"
- **Level 2**: "Plan Structure: Level 2 (Phase X with stage expansion)"

This is informational only and helps understand the current plan organization.

### 1.55. Proactive Expansion Check

Before implementation, evaluate if phase should be expanded using agent-based judgment.

**Evaluation criteria**: Task complexity, scope breadth, interrelationships, parallel work potential, clarity vs detail tradeoff

**If expansion recommended**: Display formatted recommendation with rationale and `/expand phase` command

**If not needed**: Continue silently to implementation

**Relationship to reactive expansion** (Step 3.4):
- **Proactive** (1.55): Before implementation, recommendation only
- **Reactive** (3.4): After implementation, auto-revision via `/revise --auto-mode`

### 1.6. Parallel Wave Execution

For parallel agent invocation patterns, see [Parallel Agent Invocation](../docs/command-patterns.md#pattern-parallel-agent-invocation).

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

### 3.3. Enhanced Error Analysis (if tests fail)

**Workflow**: Use error-utils.sh for comprehensive error analysis and recovery options

**Step 1: Classify Error**
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/error-utils.sh"
ERROR_TYPE=$(classify_error "$TEST_OUTPUT")
```

**Step 2: Generate Suggestions**
```bash
SUGGESTIONS=$(suggest_recovery "$ERROR_TYPE" "$TEST_OUTPUT")
```

**Step 3: Format Report**
```bash
ERROR_REPORT=$(format_error_report "$ERROR_TYPE" "$TEST_OUTPUT" "$CURRENT_PHASE")
echo "$ERROR_REPORT"
```

**Error categories**: syntax, test_failure, file_not_found, import_error, null_error, timeout, permission, unknown

**Graceful degradation**: Document partial progress, suggest `/debug` or manual fixes, save checkpoint with error context

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
- **Debug Report**: [../reports/026_debug.md](../reports/026_debug.md)
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
**Incremental plan updates after each phase:**

**Step 1: Mark Phase Tasks Complete**

Use the Edit tool to mark tasks as complete in the appropriate file:
- **Level 0**: Update tasks in main plan file
- **Level 1**: If phase is expanded, update tasks in phase file; otherwise update in main plan
- **Level 2**: If stage is expanded, update tasks in stage file; otherwise in phase file

**Approach**:
- Use Edit tool to change completed tasks: `- [ ]` → `- [x]`
- Check if phase/stage is expanded using progressive utilities
- Update in appropriate location based on expansion status

**Step 2: Add Phase Completion Marker**

Add completion marker to phase heading:
- **Level 0**: Add `[COMPLETED]` to phase heading in main plan
- **Level 1**: If phase is expanded, add marker to phase file; otherwise to main plan
- **Level 2**: Mark appropriate stage files and phase overview as complete

Use Edit tool to change:
`### Phase N: Phase Name` → `### Phase N: Phase Name [COMPLETED]`

**Step 3: Verify Plan Updated**

Check that tasks are properly marked by reading the updated file and verifying all phase tasks show `[x]`.

**Step 4: Add/Update Implementation Progress Section**
- Use Edit tool to add or update "## Implementation Progress" section
- Place after metadata, before overview
- Include:
  - Last completed phase number and name
  - Completion date
  - Git commit hash
  - Resume instructions: `/implement <plan-file> <next-phase-number>`

**Example Implementation Progress Section:**
```markdown
## Implementation Progress

- **Last Completed Phase**: Phase 2: Core Implementation
- **Date**: 2025-10-03
- **Commit**: abc1234
- **Status**: In Progress (2/5 phases complete)
- **Resume**: `/implement specs/plans/018.md 3`
```

### 5.5. Automatic Collapse Detection

After completing a phase and committing changes, automatically evaluate if an expanded phase should be collapsed back to the main plan file based on complexity heuristics.

**Trigger Conditions:**

Only check phases that meet BOTH criteria:
1. **Phase is expanded** (in a separate file, not inline)
2. **Phase is completed** (all tasks marked [x])

**Detection Logic:**

```bash
# Detect project directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"

# Source structure evaluation utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/structure-eval-utils.sh"
source "$CLAUDE_PROJECT_DIR/.claude/lib/adaptive-planning-logger.sh"

# Check if phase is expanded and completed
IS_PHASE_EXPANDED=$(.claude/lib/parse-adaptive-plan.sh is_phase_expanded "$PLAN_PATH" "$CURRENT_PHASE")
IS_PHASE_COMPLETED=$(grep -q "\[COMPLETED\]" "$PHASE_FILE" && echo "true" || echo "false")

if [ "$IS_PHASE_EXPANDED" = "true" ] && [ "$IS_PHASE_COMPLETED" = "true" ]; then
  # Get phase details for complexity calculation
  PHASE_FILE=$(get_phase_file "$PLAN_PATH" "$CURRENT_PHASE")

  if [ -f "$PHASE_FILE" ]; then
    # Extract phase metrics
    PHASE_CONTENT=$(cat "$PHASE_FILE")
    PHASE_NAME=$(grep "^### Phase $CURRENT_PHASE" "$PHASE_FILE" | head -1 | sed "s/^### Phase $CURRENT_PHASE:* //" | sed 's/ \[.*\]$//')
    TASK_COUNT=$(grep -c "^- \[x\]" "$PHASE_FILE" || echo "0")

    # Calculate complexity score
    COMPLEXITY_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$PHASE_CONTENT")

    # Log collapse check (always, for observability)
    TRIGGERED="false"
    if [ "$TASK_COUNT" -le 5 ] && awk -v s="$COMPLEXITY_SCORE" 'BEGIN {exit !(s < 6.0)}'; then
      TRIGGERED="true"
    fi
    log_collapse_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "6.0" "$TRIGGERED"

    # Check collapse thresholds: tasks ≤ 5 AND complexity < 6.0
    if [ "$TASK_COUNT" -le 5 ]; then
      if awk -v score="$COMPLEXITY_SCORE" 'BEGIN {exit !(score < 6.0)}'; then

        # Build collapse context JSON
        COLLAPSE_CONTEXT=$(cat <<EOF
{
  "revision_type": "collapse_phase",
  "current_phase": $CURRENT_PHASE,
  "reason": "Phase $CURRENT_PHASE completed and now simple ($TASK_COUNT tasks, complexity $COMPLEXITY_SCORE)",
  "suggested_action": "Collapse Phase $CURRENT_PHASE back into main plan",
  "simplicity_metrics": {
    "tasks": $TASK_COUNT,
    "complexity_score": $COMPLEXITY_SCORE,
    "completion": true
  }
}
EOF
)

        # Invoke /revise --auto-mode for automatic collapse
        echo "Triggering auto-collapse for Phase $CURRENT_PHASE (simple after completion)..."
        REVISE_RESULT=$(invoke_slash_command "/revise $PLAN_PATH --auto-mode --context '$COLLAPSE_CONTEXT'")

        # Parse revision result
        REVISE_STATUS=$(echo "$REVISE_RESULT" | jq -r '.status')

        if [ "$REVISE_STATUS" = "success" ]; then
          # Collapse succeeded
          NEW_LEVEL=$(echo "$REVISE_RESULT" | jq -r '.new_structure_level')

          # Log successful collapse invocation
          log_collapse_invocation "$CURRENT_PHASE" "auto" "Phase simple after completion"

          echo "✓ Auto-collapsed Phase $CURRENT_PHASE (structure level now: $NEW_LEVEL)"

          # Update plan path if it changed (Level 1 → Level 0)
          UPDATED_FILE=$(echo "$REVISE_RESULT" | jq -r '.updated_file')
          if [ "$UPDATED_FILE" != "$PLAN_PATH" ]; then
            PLAN_PATH="$UPDATED_FILE"
            echo "  Plan file updated: $PLAN_PATH"
          fi
        else
          # Collapse failed - log but continue
          ERROR_MSG=$(echo "$REVISE_RESULT" | jq -r '.error_message')
          echo "⚠ Auto-collapse failed: $ERROR_MSG"
          echo "  Continuing with expanded structure"
        fi
      fi
    fi
  fi
fi
```

**Collapse Thresholds:**
- **Tasks**: ≤ 5 completed tasks
- **Complexity**: < 6.0 (medium-low complexity)
- **Both Required**: Both thresholds must be met (conservative approach)

**Automatic Actions:**
1. Calculate phase complexity using `calculate_phase_complexity()` from complexity-utils.sh
2. Check if thresholds met (tasks ≤ 5 AND complexity < 6.0)
3. Log collapse check for observability
4. If triggered: Build collapse context JSON and invoke `/revise --auto-mode collapse_phase`
5. Parse response and update plan path if structure level changed
6. Log collapse invocation (auto trigger) for audit trail

**Logging:**
- **collapse_check**: Logs every evaluation (triggered or not)
- **collapse_invocation**: Logs only when collapse executes (trigger=auto)
- **Log file**: `.claude/logs/adaptive-planning.log`

**Non-Blocking:**
- Collapse failures are logged but don't stop implementation
- Phase remains expanded if collapse fails
- Implementation continues to next phase regardless

**Edge Cases:**
- **Phase with stages**: Collapse will fail (must collapse stages first)
- **Incomplete phase**: Skipped silently (not eligible)
- **Complex phase**: Not triggered (stays expanded)
- **Structure level change**: Plan path updated if last expanded phase (Level 1 → Level 0)

### 6. Incremental Summary Generation
**Create or update partial summary after each phase:**

**Step 1: Determine Summary Path**
- Extract specs directory from plan metadata
- Summary path: `[specs-dir]/summaries/NNN_partial.md`
- Number matches plan number

**Step 2: Create or Update Partial Summary**
- If first phase: Use Write tool to create new partial summary
- If subsequent phase: Use Edit tool to update existing partial summary
- Include:
  - Status: "in_progress"
  - Phases completed: "M/N"
  - Last completed phase name and date
  - Last git commit hash
  - Resume instructions

**Partial Summary Template:**
```markdown
# Implementation Summary: [Feature Name] (PARTIAL)

## Metadata
- **Date Started**: [YYYY-MM-DD]
- **Specs Directory**: [path/to/specs/]
- **Summary Number**: [NNN]
- **Plan**: [Link to plan file]
- **Status**: in_progress
- **Phases Completed**: M/N

## Progress

### Last Completed Phase
- **Phase**: Phase M: [Phase Name]
- **Completed**: [YYYY-MM-DD]
- **Commit**: [hash]

### Phases Summary
- [x] Phase 1: [Name] - Completed [date]
- [x] Phase 2: [Name] - Completed [date]
- [ ] Phase 3: [Name] - Pending
- [ ] Phase 4: [Name] - Pending

## Resume Instructions
To continue this implementation:
```
/implement [plan-path] M+1
```

Auto-resume is enabled by default when calling /implement without arguments.

## Implementation Notes
[Brief notes about progress, challenges, or decisions made]
```

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

## Test Detection Patterns

I'll look for and run:
- Commands containing `:lua.*test`
- Commands with `:Test`
- Standard test commands: `npm test`, `pytest`, `make test`
- Project-specific test commands based on configuration files

## Resuming Implementation

If we need to stop and resume later, you can use:
```
/implement <plan-file> <phase-number>
```

This will start from the specified phase number.

## Error Handling and Rollback

### Test Failures

When tests fail, use error-utils.sh for systematic error analysis and recovery:

**Step 1: Capture Error Output**
```bash
# Capture test failure output
TEST_ERROR_OUTPUT=$(run_tests 2>&1)
TEST_EXIT_CODE=$?
```

**Step 2: Classify Error Type**
```bash
# Use error-utils.sh to classify the error
source "$CLAUDE_PROJECT_DIR/.claude/lib/error-utils.sh"

ERROR_TYPE=$(classify_error "$TEST_ERROR_OUTPUT")
# Returns: syntax, test_failure, file_not_found, import_error, null_error, timeout, permission, unknown
```

**Step 3: Generate Recovery Suggestions**
```bash
# Get actionable recovery suggestions based on error type
SUGGESTIONS=$(suggest_recovery "$ERROR_TYPE" "$TEST_ERROR_OUTPUT")
```

**Step 4: Format Error Report**
```bash
# Use error-utils.sh to format a structured error report
ERROR_REPORT=$(format_error_report "$ERROR_TYPE" "$TEST_ERROR_OUTPUT" "$CURRENT_PHASE")
echo "$ERROR_REPORT"
```

**Step 5: Decide Next Action**
- Display formatted error report with suggestions
- Attempt automated fixes for common issues (if applicable)
- Re-run tests after fixes
- Only move forward when tests pass
- If unresolvable: Save checkpoint and escalate to user

### Phase Failure Handling
**What happens when a phase fails:**

**Don't Mark Phase Complete:**
- If phase tests fail: Do NOT mark tasks as `[x]`
- Do NOT add `[COMPLETED]` marker to phase heading
- Do NOT update partial summary with this phase
- Do NOT create git commit

**Preserve Partial Work:**
- Keep code changes in working directory
- Previous phases remain marked complete
- Partial summary reflects only successful phases
- User can debug, fix, and retry the phase

**Retry Failed Phase:**
```
# After fixing issues
/implement <plan-file> <failed-phase-number>
```

**Partial Summary Always Accurate:**
- Partial summary only includes successfully completed phases
- "Phases Completed: M/N" reflects actual progress
- Resume instructions point to first incomplete phase
- Status remains "in_progress" until all phases complete

### Git Commit Failure Handling
If git commit fails after marking phase complete:
- Log error with details
- Preserve partial work (don't rollback code changes)
- Partial summary already reflects completed phase
- Manual intervention required to resolve git issues

## Summary Generation

After completing all phases:

### 1-3. Finalize Summary File

**Workflow**:
- Check for partial summary: `[specs-dir]/summaries/NNN_partial.md`
- If exists: Rename to `NNN_implementation_summary.md` and finalize
- If not: Create new summary from scratch
- Location: Extract specs-dir from plan metadata
- Number: Match plan number (NNN)

**Finalization updates**:
- Remove "(PARTIAL)" from title
- Change status: `in_progress` → `complete`
- Update phases: `M/N` → `N/N`
- Add completion date and lessons learned
- Remove resume instructions

### 4-5. Registry and Cross-References

**Update SPECS.md Registry**:
- Increment "Summaries" count
- Update "Last Updated" date

**Bidirectional links**:
- Add "## Implementation Summary" section to plan file
- Add "## Implementation Status" section to each research report
- Verify all links created (non-blocking if fails)

### 6. Create Pull Request (Optional)

For PR creation workflow, see [Single Agent with Behavioral Injection](../docs/command-patterns.md#pattern-single-agent-with-behavioral-injection).

**Implement-specific PR workflow**:
- Trigger: `--create-pr` flag or CLAUDE.md auto-PR config
- Prerequisites: Check gh CLI installed and authenticated
- Agent: Invoke github-specialist with behavioral injection
- Content: Implementation overview, phases, test results, reports, file changes
- Update: Add PR link to summary and plan files
- Graceful degradation: Provide manual gh command if fails

## Finding the Implementation Plan

### Auto-Detection Logic (when no arguments provided):
```bash
# 1. Find all plans (both files and directories), sorted by modification time
# - Level 0 plans: specs/plans/NNN_*.md
# - Level 1/2 plans: specs/plans/NNN_*/NNN_*.md
find . -path "*/specs/plans/*.md" -type f -exec ls -t {} + 2>/dev/null
find . -path "*/specs/plans/*/*.md" -type f -name "*_*.md" -exec ls -t {} + 2>/dev/null

# 2. For each plan, use progressive parser to check status:
LEVEL=$(.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")

# 3. Select the first incomplete plan
```

### If no plan file provided:
I'll search for the most recent incomplete implementation plan by:
1. Looking in all `specs/plans/` directories for both files and directories
2. Sorting by modification time (most recent first)
3. Detecting structure level using `parse-adaptive-plan.sh detect_structure_level`
4. Checking plan status by reading phase completion markers
5. Selecting the first incomplete plan found
6. Determining the first incomplete phase to resume from

### If a plan file or directory is provided:
I'll use the specified plan directly and:
1. Detect structure level (0, 1, or 2) using parsing utility
2. Read appropriate plan file based on expansion status
3. Check completion status using `[COMPLETED]` markers
4. Find first incomplete phase (if any)
5. Resume from that phase or start from phase 1

### Plan Status Detection:
Check for completion markers in appropriate files:

- **Complete Plan**: All phases have `[COMPLETED]` marker
- **Incomplete Phase**: Phase lacks `[COMPLETED]` marker or has unchecked tasks
- **Level 0**: Check phase headings and task checkboxes in main plan file
- **Level 1**: Check completion markers in expanded phase files and main plan
- **Level 2**: Check completion across stage files, phase files, and main plan

## Integration with Other Commands

### Standards Flow
This command is part of the standards enforcement pipeline:

1. `/report` - Researches topic (no standards needed)
2. `/plan` - Discovers and captures standards in plan metadata
3. `/implement` - **Applies standards during code generation** (← YOU ARE HERE)
4. `/test` - Verifies implementation using standards-defined test commands
5. `/document` - Creates documentation following standards format
6. `/refactor` - Validates code against standards

### How /implement Uses Standards

#### From /plan
- Reads captured standards file path from plan metadata
- Uses plan's documented test commands and coding style

#### Applied During Implementation
- **Code generation**: Follows Code Standards (indentation, naming, error handling)
- **Test execution**: Uses Testing Protocols (test commands, patterns)
- **Documentation**: Creates docs per Documentation Policy

#### Verified Before Commit
- Standards compliance checked before marking phase complete
- Commit message notes which standards were applied

### Example Flow
```
User runs: /plan "Add authentication"
  ↓
/plan discovers CLAUDE.md:
  - Code Standards: snake_case, 2 spaces, pcall
  - Testing: :TestSuite
  ↓
Plan metadata captures: Standards File: CLAUDE.md
  ↓
User runs: /implement auth_plan.md
  ↓
/implement discovers CLAUDE.md + reads plan:
  - Confirms standards
  - Applies during generation
  - Tests with :TestSuite
  - Verifies compliance
  ↓
Generated code follows standards automatically
```

## Agent Usage

This command does not directly invoke specialized agents. Instead, it executes implementation directly using its own tools (Read, Edit, Write, Bash, TodoWrite).

### Potential Agent Integration (Future Enhancement)
While `/implement` currently works autonomously, it could potentially delegate to specialized agents:

- **code-writer**: For complex code generation tasks
  - Would receive plan context and phase requirements
  - Could apply standards more intelligently
  - Would use TodoWrite for task tracking

- **test-specialist**: For test execution and analysis
  - Could provide more detailed test failure diagnostics
  - Would categorize errors more effectively
  - Could suggest fixes for common test failures

- **code-reviewer**: For standards compliance checking
  - Optional pre-commit validation
  - Could run after each phase before marking complete
  - Would provide structured feedback on standards violations

### Current Design Rationale
`/implement` executes directly without agent delegation because:
1. **Performance**: Avoids agent invocation overhead for simple implementations
2. **Context**: Maintains full implementation context across all phases
3. **Control**: Direct execution provides more predictable behavior
4. **Simplicity**: Easier to debug and reason about

For complex, multi-phase implementations requiring specialized expertise, use `/orchestrate` instead, which fully leverages the agent system.

## Checkpoint Detection and Resume

For checkpoint management patterns, see [Checkpoint Management Patterns](../docs/command-patterns.md#checkpoint-management-patterns).

**Implement-specific checkpoint workflow using checkpoint-utils.sh**:

**Step 1: Check for Existing Checkpoint**
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/checkpoint-utils.sh"

# Load most recent implement checkpoint
CHECKPOINT_DATA=$(load_checkpoint "implement")
CHECKPOINT_EXISTS=$?

if [ $CHECKPOINT_EXISTS -eq 0 ]; then
  # Checkpoint found - parse state
  PLAN_PATH=$(echo "$CHECKPOINT_DATA" | jq -r '.plan_path')
  CURRENT_PHASE=$(echo "$CHECKPOINT_DATA" | jq -r '.current_phase')
  TOTAL_PHASES=$(echo "$CHECKPOINT_DATA" | jq -r '.total_phases')
fi
```

**Step 2: Interactive Resume Prompt**
```bash
if [ $CHECKPOINT_EXISTS -eq 0 ]; then
  echo "Found checkpoint: Phase $CURRENT_PHASE/$TOTAL_PHASES"
  echo "Options: (r)esume, (s)tart fresh, (v)iew, (d)elete"
  read -r CHOICE

  case "$CHOICE" in
    r) # Resume from checkpoint
       echo "Resuming from Phase $CURRENT_PHASE"
       ;;
    s) # Start fresh
       delete_checkpoint "implement"
       ;;
    v) # View checkpoint
       view_checkpoint "implement"
       ;;
    d) # Delete and start fresh
       delete_checkpoint "implement"
       ;;
  esac
fi
```

**Step 3: Save Checkpoint After Each Phase**
```bash
# After successful git commit
save_checkpoint "implement" "$CHECKPOINT_DATA"

# Checkpoint data structure
CHECKPOINT_DATA=$(cat <<EOF
{
  "workflow_description": "implement",
  "plan_path": "$PLAN_PATH",
  "current_phase": $NEXT_PHASE,
  "total_phases": $TOTAL_PHASES,
  "completed_phases": [$COMPLETED_PHASES_ARRAY],
  "status": "in_progress",
  "tests_passing": true,
  "replan_count": $REPLAN_COUNT,
  "phase_replan_count": {$PHASE_REPLAN_COUNTS},
  "replan_history": [$REPLAN_HISTORY_ARRAY]
}
EOF
)
```

**Step 4: Cleanup on Completion**
```bash
# On successful completion
delete_checkpoint "implement"

# On failure
archive_checkpoint "implement" "failed"
```

**Checkpoint state fields**:
- workflow_description, plan_path, current_phase, total_phases
- completed_phases, status, tests_passing
- replan_count, phase_replan_count, replan_history (for adaptive planning)

**Benefits of checkpoint-utils.sh**:
- Automatic schema migration for checkpoint format changes
- Atomic save operations prevent corrupted checkpoints
- Consistent checkpoint naming and location
- Built-in validation before loading

Let me start by finding your implementation plan.
