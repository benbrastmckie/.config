---
allowed-tools: Read, Edit, MultiEdit, Write, Bash, Grep, Glob, TodoWrite, Task, SlashCommand
argument-hint: [plan-file] [starting-phase] [--report-scope-drift "<description>"] [--force-replan] [--create-pr] [--dashboard] [--dry-run]
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
- **Adaptive Logging**: Uses `.claude/lib/unified-logger.sh` for trigger evaluation logging
- **Error Handling**: Uses `.claude/lib/error-handling.sh` for error classification and recovery

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

## Progress Dashboard (Optional)

Enable real-time visual progress tracking with the `--dashboard` flag:

```bash
/implement specs/plans/025_plan.md --dashboard
```

**Features**:
- **Real-time ANSI rendering**: Visual dashboard with Unicode box-drawing
- **Phase progress**: See all phases with status icons (✓ Complete, → In Progress, ⬚ Pending)
- **Progress bar**: Visual representation of completion percentage
- **Time tracking**: Elapsed time and estimated remaining duration
- **Test results**: Last test status with pass/fail indicator
- **Wave information**: Shows parallel execution waves when using dependency-based execution

**Terminal Requirements**:
- **Supported**: xterm, xterm-256color, screen, tmux, kitty, alacritty, most modern terminals
- **Unsupported**: dumb terminals, non-interactive shells, terminals without ANSI support

**Graceful Fallback**:
When terminal doesn't support ANSI codes, automatically falls back to traditional `PROGRESS:` markers without requiring any action.

**Dashboard Layout Example**:
```
┌─────────────────────────────────────────────────────────────┐
│ Implementation Progress: User Authentication Feature         │
├─────────────────────────────────────────────────────────────┤
│ Phase 1: Foundation ............................ ✓ Complete  │
│ Phase 2: Core Implementation ................... ✓ Complete  │
│ Phase 3: Testing & Validation .................. → In Progress│
│ Phase 4: Documentation ......................... ⬚ Pending    │
│ Phase 5: Cleanup ............................... ⬚ Pending    │
├─────────────────────────────────────────────────────────────┤
│ Progress: [████████████████░░░░░░░░░░░░] 60% (3/5 phases)   │
│ Elapsed: 14m 32s  |  Estimated Remaining: ~10m              │
├─────────────────────────────────────────────────────────────┤
│ Current Task: Running integration tests                     │
│ Last Test: test_auth_flow.lua ..................... ✓ PASS   │
└─────────────────────────────────────────────────────────────┘
```

**Implementation Details**:
The dashboard uses `.claude/lib/progress-dashboard.sh` utility which provides:
- Multi-layer terminal capability detection (TERM env, tput, interactive check)
- In-place ANSI updates without scrolling
- Performance-optimized rendering (minimal redraws)
- Support for both sequential and parallel (wave-based) execution

## Dry-Run Mode (Preview and Validation)

Preview execution plan without making changes using the `--dry-run` flag.

**Usage**: `/implement specs/plans/025_plan.md --dry-run` or combine with `--dashboard` for visual preview

**Analysis Performed**:
1. Plan parsing (structure, phases, tasks, dependencies)
2. Complexity evaluation (hybrid complexity scores per phase)
3. Agent assignments (which agents invoked for each phase)
4. Duration estimation (agent-registry metrics)
5. File/test analysis (affected files and tests)
6. Execution preview (wave-based order with parallelism)
7. Confirmation prompt (proceed or exit)

**Output Preview** (displays Unicode box-drawing with plan structure, waves, phase details, complexity scores, agent types, files, tests, duration estimates, execution summary)

**Use Cases**: Validation, time estimation, resource planning, dependency verification, file impact assessment, team coordination

**Scope**:
- Analyzes: Plan structure, complexity scores, agent assignments, duration, affected files/tests, execution waves
- Does NOT: Create/modify files, run tests, create git commits, invoke agents

**Duration Estimation**: Uses `.claude/lib/agent-registry-utils.sh` for historical performance data (agent execution time per complexity point, success rates, retry probabilities, parallel execution efficiency, test execution estimates)

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

The implementation workflow coordinates plan discovery, progressive structure navigation, phase-by-phase execution with adaptive planning, checkpoint management, testing, and commit workflow.

**See**: [Implementation Workflow](shared/implementation-workflow.md) for comprehensive step-by-step process documentation.

**Quick Reference**: Discover plan → Detect structure level → Load checkpoint (if resuming) → Execute phases sequentially or in parallel → Test → Commit → Update checkpoint → Generate summary

## Parallel Execution with Dependencies

Analyze phase dependencies to enable parallel execution in waves.

**Dependency Analysis Workflow**:
1. **Parse dependencies**: Use `parse-phase-dependencies.sh` to generate execution waves (format: `WAVE_1:1`, `WAVE_2:2 3`, etc.)
2. **Group phases**: Each wave contains parallelizable phases, waves execute sequentially
3. **Execute waves**: Single-phase waves run normally, multi-phase waves invoke multiple agents simultaneously (multiple Task calls in one message)
4. **Error handling**: Fail-fast on phase failure, preserve checkpoint, report successes/failures, allow resume from failed wave

**Parallel Execution Safety**: Max 3 concurrent phases per wave, fail-fast behavior, checkpoint after each wave, aggregate test results

**Dependency Format**: Phases declare dependencies in header (`dependencies: [1, 2]`). Empty array or omitted = no dependencies (wave 1). Circular dependencies detected and rejected.

## Phase Execution Protocol

The phase execution protocol defines the step-by-step workflow for executing each phase: task execution, testing, adaptive planning triggers, commit workflow, plan hierarchy updates, and error handling.

**See**: [Phase Execution Protocol](shared/phase-execution.md) for comprehensive details on all execution steps and workflows.

**Quick Reference**: For each phase → Read phase file → Execute tasks sequentially → Run tests after each task → Check adaptive triggers → Create git commit → **Update plan hierarchy** → Update checkpoints → Move to next phase

### Plan Hierarchy Update After Phase Completion

After successfully completing a phase (tests passing and git commit created), update the plan hierarchy to ensure all parent/grandparent plan files reflect completion status.

**When to Update**:
- After git commit succeeds for the phase
- Before saving the checkpoint
- For all hierarchy levels (Level 0, Level 1, Level 2)

**Update Workflow**:

1. **Invoke Spec-Updater Agent**:
   ```
   Task {
     subagent_type: "general-purpose"
     description: "Update plan hierarchy after Phase N completion"
     prompt: |
       Read and follow the behavioral guidelines from:
       /home/benjamin/.config/.claude/agents/spec-updater.md

       You are acting as a Spec Updater Agent.

       Update plan hierarchy checkboxes after Phase ${PHASE_NUM} completion.

       Plan: ${PLAN_PATH}
       Phase: ${PHASE_NUM}
       All tasks in this phase have been completed.

       Steps:
       1. Source checkbox utilities: source .claude/lib/checkbox-utils.sh
       2. Mark phase complete: mark_phase_complete "${PLAN_PATH}" ${PHASE_NUM}
       3. Verify consistency: verify_checkbox_consistency "${PLAN_PATH}" ${PHASE_NUM}
       4. Report: List all files updated (stage → phase → main plan)

       Expected output:
       - Confirmation of hierarchy update
       - List of updated files
       - Verification status
   }
   ```

2. **Validate Update Success**:
   - Check agent response for successful completion
   - Verify all hierarchy levels updated
   - Confirm no consistency errors

3. **Handle Update Failures**:
   - If hierarchy update fails: Log error and escalate to user
   - Do NOT proceed to checkpoint save if update fails
   - Preserve phase completion in working directory
   - User can manually fix hierarchy and resume

4. **Update Checkpoint State**:
   Add `hierarchy_updated` field to checkpoint data:
   ```bash
   CHECKPOINT_DATA='{
     "workflow_description":"implement",
     "plan_path":"'$PLAN_PATH'",
     "current_phase":'$NEXT_PHASE',
     "total_phases":'$TOTAL_PHASES',
     "status":"in_progress",
     "tests_passing":true,
     "hierarchy_updated":true,
     "replan_count":'$REPLAN_COUNT'
   }'
   save_checkpoint "implement" "$CHECKPOINT_DATA"
   ```

**Hierarchy Levels**:
- **Level 0** (single file): Update checkboxes in main plan only
- **Level 1** (expanded phases): Update phase file + main plan
- **Level 2** (stage expansion): Update stage file + phase file + main plan

**Error Handling**:
- Hierarchy update failures are non-fatal but logged
- User notified if parent plans couldn't be updated
- Phase still marked complete in deepest level file
- Can be manually synced later using checkbox-utils.sh

**Graceful Degradation**:
If spec-updater agent is unavailable, fall back to direct checkbox-utils.sh calls:
```bash
source .claude/lib/checkbox-utils.sh
mark_phase_complete "$PLAN_PATH" "$PHASE_NUM"
verify_checkbox_consistency "$PLAN_PATH" "$PHASE_NUM"
```

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

When tests fail, use error-handling.sh for systematic error analysis and recovery:

**Step 1: Capture Error Output**
```bash
# Capture test failure output
TEST_ERROR_OUTPUT=$(run_tests 2>&1)
TEST_EXIT_CODE=$?
```

**Step 2: Classify Error Type**
```bash
# Use error-handling.sh to classify the error
source "$CLAUDE_PROJECT_DIR/.claude/lib/error-handling.sh"

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
# Use error-handling.sh to format a structured error report
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

### 1-3. Finalize Summary File Using Uniform Structure

**Step 1: Source Required Utilities**
```bash
source .claude/lib/artifact-operations.sh
source .claude/lib/template-integration.sh
```

**Step 2: Extract Topic Directory from Plan Path**
```bash
# Explicit path extraction from plan file path
# Example: specs/042_auth/plans/001_plan.md → specs/042_auth
PLAN_DIR=$(dirname "$PLAN_PATH")      # Get directory containing plan file
TOPIC_DIR=$(dirname "$PLAN_DIR")      # Get parent directory (topic directory)

# This works for all structure levels:
# Level 0: specs/042_auth/plans/001_plan.md → specs/042_auth
# Level 1: specs/042_auth/plans/001_plan/001_plan.md → specs/042_auth/plans/001_plan → ...
# (For Level 1+, need to navigate up appropriately)
```

**Step 3: Create or Update Summary Using Utility**
```bash
# Check for partial summary first
PARTIAL_SUMMARY="${TOPIC_DIR}/summaries/${PLAN_NUM}_partial.md"

if [ -f "$PARTIAL_SUMMARY" ]; then
  # Finalize existing partial summary
  FINAL_SUMMARY="${TOPIC_DIR}/summaries/${PLAN_NUM}_implementation_summary.md"
  mv "$PARTIAL_SUMMARY" "$FINAL_SUMMARY"
  # Update status and completion fields in file
else
  # Create new summary using uniform structure
  SUMMARY_PATH=$(create_topic_artifact "$TOPIC_DIR" "summaries" "implementation_summary_${PLAN_NUM}" "$SUMMARY_CONTENT")
  # Creates: ${TOPIC_DIR}/summaries/NNN_implementation_summary.md
fi
```

**Benefits of Uniform Structure**:
- Summary in same topic directory as plan
- Easy cross-referencing: `../summaries/NNN_*.md` from plan
- Consistent numbering matches plan number
- Single utility manages all artifact creation

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

This command executes implementation directly using its own tools (Read, Edit, Write, Bash, TodoWrite) for performance, context preservation, and predictable behavior. For complex implementations requiring specialized agents, use `/orchestrate` instead.

## Checkpoint Detection and Resume

For checkpoint management patterns, see [Checkpoint Management Patterns](../docs/command-patterns.md#checkpoint-management-patterns).

**When to Use Checkpoints**:
- **Automatic saves**: After each phase completion with git commit
- **Auto-resume**: 90% of resumes happen automatically without prompts
- **Safety checks**: 5 conditions verified before auto-resume

**Workflow Overview**:
1. Check for existing checkpoint (load_checkpoint)
2. Evaluate auto-resume safety conditions (5 checks)
3. Auto-resume if safe, otherwise show interactive prompt with reason
4. Save checkpoint after each phase (atomic save operations)
5. Cleanup on completion or archive on failure

**Pattern Details**: See [Checkpoint Management Patterns](../docs/command-patterns.md#checkpoint-management-patterns) for complete workflow including safety checks, schema migration, and error handling.

**Key Execution Requirements**:

1. **Load checkpoint** (uses checkpoint-utils.sh):
   ```bash
   source "$CLAUDE_PROJECT_DIR/.claude/lib/checkpoint-utils.sh"
   CHECKPOINT_DATA=$(load_checkpoint "implement")
   CHECKPOINT_EXISTS=$?

   [ $CHECKPOINT_EXISTS -eq 0 ] && PLAN_PATH=$(echo "$CHECKPOINT_DATA" | jq -r '.plan_path')
   ```

2. **Smart auto-resume with safety checks**:
   ```bash
   if check_safe_resume_conditions "$CHECKPOINT_FILE"; then
     # Auto-resume silently (90% of cases)
     log_checkpoint_auto_resume "$CURRENT_PHASE" "implement"
   else
     # Show interactive prompt with reason
     SKIP_REASON=$(get_skip_reason "$CHECKPOINT_FILE")
     echo "⚠ Cannot auto-resume: $SKIP_REASON"
     # Offer: (r)esume, (s)tart fresh, (v)iew, (d)elete
   fi
   ```

3. **Save checkpoint after phase**:
   ```bash
   CHECKPOINT_DATA='{"workflow_description":"implement", "plan_path":"'$PLAN_PATH'", "current_phase":'$NEXT_PHASE', "total_phases":'$TOTAL_PHASES', "status":"in_progress", "tests_passing":true, "replan_count":'$REPLAN_COUNT'}'
   save_checkpoint "implement" "$CHECKPOINT_DATA"
   ```

**Quick Example - Auto-Resume Flow**:
```bash
# Check for checkpoint
CHECKPOINT_DATA=$(load_checkpoint "implement")

if [ $? -eq 0 ]; then
  # Evaluate 5 safety conditions
  if check_safe_resume_conditions "$CHECKPOINT_FILE"; then
    # All safety conditions met → Auto-resume (no prompt)
    CURRENT_PHASE=$(echo "$CHECKPOINT_DATA" | jq -r '.current_phase')
    echo "✓ Auto-resuming from Phase $CURRENT_PHASE"
  else
    # Safety condition failed → Interactive prompt with specific reason
    echo "⚠ Cannot auto-resume: $(get_skip_reason "$CHECKPOINT_FILE")"
    # Prompt user for manual decision
  fi
fi

# After each phase completes
save_checkpoint "implement" "$CHECKPOINT_DATA"  # Atomic save

# On completion
delete_checkpoint "implement"  # Cleanup
```

**Auto-Resume Safety Conditions**:
1. Tests passing in last run (tests_passing = true)
2. No recent errors (last_error = null)
3. Checkpoint age < 7 days
4. Plan file not modified since checkpoint
5. Status = "in_progress"

**Checkpoint State Fields**: workflow_description, plan_path, current_phase, total_phases, completed_phases, status, tests_passing, hierarchy_updated, replan_count, phase_replan_count, replan_history

**Benefits**: Smart auto-resume (90% automatic), 5-condition safety checks, clear feedback on skip reason, schema migration, atomic saves, consistent naming, built-in validation

Let me start by finding your implementation plan.
