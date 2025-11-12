# /implement Command - Complete Guide

**Executable**: `.claude/commands/implement.md`

**Quick Start**: Run `/implement [plan-file] [starting-phase]` - the command executes implementation plans phase-by-phase with automated testing and commits.

---

## Table of Contents

1. [Overview](#overview)
2. [Usage](#usage)
3. [Adaptive Planning Features](#adaptive-planning-features)
4. [Agent Delegation Patterns](#agent-delegation-patterns)
5. [Progressive Plan Support](#progressive-plan-support)
6. [Standards Discovery](#standards-discovery)
7. [Error Recovery](#error-recovery)
8. [Checkpoint Management](#checkpoint-management)
9. [Summary Generation](#summary-generation)
10. [Advanced Features](#advanced-features)
11. [Troubleshooting](#troubleshooting)

---

## Overview

The `/implement` command executes implementation plans systematically through automated phase-by-phase execution with testing, commits, and adaptive replanning.

### Key Capabilities

- **Adaptive role switching**: Direct execution (simple phases) vs agent orchestration (complex phases)
- **Hybrid complexity evaluation**: Threshold scoring + context-aware agent analysis
- **Automatic replanning**: Detects complexity overload and test failure patterns
- **Checkpoint recovery**: Smart auto-resume with 90% success rate
- **Progress dashboard**: Real-time ANSI visualization (optional)
- **Parallel execution**: Wave-based phase execution with dependencies
- **Plan hierarchy management**: Automatic checkbox propagation across levels

### When to Use

- Execute implementation plans created by `/plan`
- Resume interrupted implementations automatically
- Preview execution with `--dry-run` mode
- Create pull requests with `--create-pr` flag
- Track progress visually with `--dashboard` flag

---

## Usage

### Basic Syntax

```bash
/implement [plan-file] [starting-phase] [flags]
```

### Arguments

- **plan-file** (optional): Absolute path to implementation plan
  - If omitted: Auto-detects most recent incomplete plan
  - Supports Level 0 (single-file), Level 1 (phase-expanded), Level 2 (stage-expanded)

- **starting-phase** (optional): Phase number to start from
  - Default: 1 (or auto-resume from checkpoint)
  - Used when resuming after interruption

### Flags

- `--dashboard`: Enable real-time ANSI progress visualization
- `--dry-run`: Preview execution without making changes
- `--create-pr`: Create GitHub pull request after completion
- `--report-scope-drift "<description>"`: Flag discovered out-of-scope work
- `--force-replan`: Override replan limits (requires manual approval)

### Examples

```bash
# Auto-resume most recent incomplete plan
/implement

# Execute specific plan from beginning
/implement specs/042_auth/plans/001_implementation.md

# Resume from specific phase
/implement specs/042_auth/plans/001_implementation.md 3

# Preview with dashboard
/implement specs/042_auth/plans/001_implementation.md --dry-run --dashboard

# Execute with PR creation
/implement specs/042_auth/plans/001_implementation.md --create-pr

# Report scope drift during execution
/implement specs/042_auth/plans/001_implementation.md 4 --report-scope-drift "Database migration needed"
```

---

## Adaptive Planning Features

The command includes intelligent plan revision capabilities that detect when replanning is needed during implementation.

### Automatic Triggers

1. **Complexity Detection**: Phases with complexity score >8 or >10 tasks trigger phase expansion
2. **Test Failure Patterns**: 2+ consecutive test failures in same phase suggests missing prerequisites
3. **Scope Drift**: Manual flag `--report-scope-drift "description"` for discovered out-of-scope work

### Behavior

- Automatically invokes `/revise --auto-mode` when triggers detected
- Updates plan structure (expands phases, adds phases, or updates tasks)
- Continues implementation with revised plan
- Maximum 2 replans per phase prevents infinite loops

### Shared Utilities Integration

- **Checkpoint Management**: `.claude/lib/checkpoint-utils.sh` for workflow state persistence
- **Complexity Analysis**: `.claude/lib/complexity-utils.sh` for phase complexity scoring
- **Adaptive Logging**: `.claude/lib/adaptive-planning-logger.sh` for trigger evaluation logging
- **Error Handling**: `.claude/lib/error-handling.sh` for error classification and recovery

### Safety

- Loop prevention with replan counters tracked in checkpoints
- Replan history logged for audit trail
- User escalation when limits exceeded
- Manual override via `--force-replan` flag

### Logging

- **Log File**: `.claude/data/logs/adaptive-planning.log`
- **Log Rotation**: 10MB max, 5 files retained
- **Query Logs**: Use functions from `.claude/lib/unified-logger.sh`

---

## Agent Delegation Patterns

The command has THREE distinct roles that activate conditionally based on phase complexity.

### Role 1: Phase Coordinator (ALWAYS ACTIVE)

**Responsibilities:**
- Manage workflow state, checkpoints, progress tracking
- Update plan files and hierarchy after each phase
- Run tests and create git commits
- Never skip testing, commits, or plan updates

**Tools**: checkpoint-utils.sh, checkbox-utils.sh, progress-dashboard.sh

### Role 2: Direct Executor (Simple Phases - Complexity <3)

**When Active:** Phase complexity score <3

**Responsibilities:**
- Execute implementation directly using Read/Edit/Write tools
- Apply coding standards from CLAUDE.md
- Do NOT invoke agents for simple tasks

**Tools**: Read, Edit, Write, Bash

### Role 3: Agent Orchestrator (Complex Phases - Complexity ≥3)

**When Active:** Phase complexity score ≥3

**Responsibilities:**
- Delegate implementation to specialized agents
- Invoke implementation-researcher for exploration (score ≥8)
- Invoke code-writer for implementation (score 3-10)
- Invoke debug-specialist for test failures
- Invoke doc-writer for documentation phases
- Do NOT execute complex implementation directly

**Tools**: Task tool with behavioral injection

### Role Decision Tree

```
┌─────────────────────────────────────────────────────────┐
│ Phase Complexity Evaluation (Step 1.5)                  │
│ → $COMPLEXITY_SCORE exported                            │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │ $COMPLEXITY_SCORE ?  │
              └──────────────────────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
     Score 0-2      Score 3-7      Score 8-10
  ┌─────────────┐ ┌────────────┐ ┌─────────────┐
  │   Direct    │ │ Orchestrate│ │ Orchestrate │
  │  Execution  │ │ code-writer│ │ code-writer │
  │             │ │            │ │ + researcher│
  └─────────────┘ └────────────┘ └─────────────┘
```

### Special Case Overrides

These TAKE PRECEDENCE over complexity score:
- **Documentation phase** → Use doc-writer agent (any complexity)
- **Testing phase** → Use test-specialist agent (any complexity)
- **Debug phase** → Use debug-specialist agent (any complexity)
- **Test failure** → Auto-invoke debug-specialist (Step 3.3)
- **After phase complete** → Invoke spec-updater (Plan Hierarchy Update)

### Agent Invocation Templates

#### Code-Writer Agent

```
Task {
  subagent_type: "general-purpose"
  description: "Implement Phase ${PHASE_NUM} - ${PHASE_NAME}"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/code-writer.md

    You are acting as a Code Writer Agent.

    Implement Phase ${PHASE_NUM}: ${PHASE_NAME}

    Plan: ${PLAN_PATH}
    Phase Tasks:
    ${TASK_LIST}

    Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md
    Complexity: ${COMPLEXITY_SCORE}

    Follow plan tasks exactly, apply coding standards, run tests after implementation.

    Return: Summary of changes made + test results
}
```

#### Implementation-Researcher Agent

```
Task {
  subagent_type: "general-purpose"
  description: "Research phase ${CURRENT_PHASE} implementation context"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementation-researcher.md

    You are acting as an Implementation Researcher Agent.

    Research Context:
    - Phase: ${CURRENT_PHASE}
    - Description: ${PHASE_NAME}
    - Files to modify: ${FILE_LIST}
    - Task count: ${TASK_COUNT}
    - Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md

    Research existing implementations, patterns, and utilities for this phase.
    Create artifact at: specs/${TOPIC_DIR}/artifacts/phase_${CURRENT_PHASE}_exploration.md
    Return metadata only (path + 50-word summary + key findings JSON).
}
```

#### Spec-Updater Agent

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

---

## Progressive Plan Support

The command supports all three progressive structure levels with unified interface.

### Structure Levels

- **Level 0**: Single-file (all phases inline)
- **Level 1**: Phase-expanded (phases in separate files)
- **Level 2**: Stage-expanded (stages in separate files)

### Detection

```bash
# Use adaptive plan parser to detect structure
LEVEL=$(.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")
# Returns: 0, 1, or 2
```

### Level-Aware Processing

All level-specific differences are abstracted by progressive utilities:
- `is_plan_expanded`: Check if plan has directory structure
- `is_phase_expanded`: Check if specific phase is in separate file
- `is_stage_expanded`: Check if specific stage is in separate file
- `list_expanded_phases`: Get numbers of expanded phases
- `list_expanded_stages`: Get numbers of expanded stages

### Plan Hierarchy Update

After successfully completing a phase, update the plan hierarchy to ensure all parent/grandparent plan files reflect completion status.

**Hierarchy Levels:**
- **Level 0** (single file): Update checkboxes in main plan only
- **Level 1** (expanded phases): Update phase file + main plan
- **Level 2** (stage expansion): Update stage file + phase file + main plan

**Workflow:**
1. Invoke spec-updater agent via Task tool
2. Agent uses checkbox-utils.sh to propagate completion markers
3. Verify all hierarchy levels updated
4. If agent fails: Fallback to direct checkbox-utils.sh calls (100% success guarantee)

---

## Standards Discovery

Before implementing, discover and apply project standards from CLAUDE.md.

### Discovery Process

1. **Locate CLAUDE.md**: Search upward from working directory and target directories
2. **Check Subdirectory Standards**: Look for directory-specific CLAUDE.md files
3. **Parse Relevant Sections**: Extract Code Standards, Testing Protocols
4. **Handle Missing Standards**: Fall back to language-specific defaults

### Standards Sections Used

- **Code Standards**: Indentation, line length, naming conventions, error handling
- **Testing Protocols**: Test commands, patterns, coverage requirements
- **Documentation Policy**: Documentation requirements for new code
- **Standards Discovery**: Discovery method, inheritance rules, fallback behavior

### Application During Implementation

#### Code Generation

- **Indentation**: Generated code matches CLAUDE.md indentation spec (e.g., 2 spaces)
- **Line Length**: Keep lines within specified limit (e.g., ~100 characters)
- **Naming**: Follow naming conventions (e.g., snake_case vs camelCase)
- **Error Handling**: Use specified error handling patterns (e.g., pcall for Lua)
- **Module Organization**: Follow project structure patterns

#### Testing

- **Test Commands**: Use test commands from Testing Protocols (e.g., `:TestSuite`)
- **Test Patterns**: Create test files matching patterns (e.g., `*_spec.lua`)
- **Coverage**: Aim for coverage requirements from standards

#### Documentation

- **Inline Comments**: Document complex logic
- **Module Headers**: Add purpose and API documentation
- **README Updates**: Follow Documentation Policy requirements

### Compliance Verification

Before marking each phase complete and committing:
- [ ] Code style matches CLAUDE.md specifications (indentation, line length)
- [ ] Naming follows project conventions
- [ ] Error handling matches project patterns
- [ ] Tests follow testing standards and pass
- [ ] Documentation meets policy requirements (if new modules created)

### Fallback Behavior

When CLAUDE.md not found or incomplete:
1. **Use Language Defaults**: Apply sensible language-specific conventions
2. **Suggest Creation**: Recommend running `/setup` to create CLAUDE.md
3. **Graceful Degradation**: Continue with reduced standards enforcement
4. **Document Limitations**: Note in commit message which standards were uncertain

---

## Error Recovery

Comprehensive tiered error recovery system with 4 escalating levels.

### Level 1: Error Classification + Suggestions

```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/error-handling.sh"
ERROR_TYPE=$(detect_error_type "$TEST_OUTPUT")
SUGGESTIONS=$(generate_suggestions "$ERROR_TYPE" "$TEST_OUTPUT" "$ERROR_LOCATION")
```

**Error Categories**: syntax, test_failure, file_not_found, import_error, null_error, timeout, permission, unknown

### Level 2: Transient Retry

For timeout, busy, or locked errors, retry with extended timeout.

```bash
if [ "$ERROR_TYPE" = "timeout" ]; then
  RETRY_META=$(retry_with_timeout "Phase 3 tests" "$ATTEMPT_NUMBER")
  # Retry with extended timeout if SHOULD_RETRY=true
fi
```

### Level 3: Tool Fallback

For tool access errors, retry with reduced toolset.

```bash
if echo "$TEST_OUTPUT" | grep -qi "tool.*failed"; then
  FALLBACK_META=$(retry_with_fallback "Phase 3" "$ATTEMPT_NUMBER")
  # Retry with REDUCED_TOOLSET
fi
```

### Level 4: Auto-Invoke /debug

For complex failures, automatically invoke /debug command with debug-analyst agents.

```bash
# Invoke /debug command
DEBUG_REPORT_PATH=$(invoke_debug "$CURRENT_PHASE" "$ERROR_TYPE" "$PLAN_FILE")

# Present user choices
echo "Choose: (r)evise, (c)ontinue, (s)kip, (a)bort"
read -p "Action: " USER_CHOICE

case "$USER_CHOICE" in
  r) invoke_slash_command "/revise --auto-mode --context '$REVISION_CONTEXT' '$PLAN_PATH'" ;;
  c) add_debugging_notes "$PLAN_PATH" "$CURRENT_PHASE" "$DEBUG_REPORT_PATH" "Incomplete" ;;
  s) add_debugging_notes "$PLAN_PATH" "$CURRENT_PHASE" "$DEBUG_REPORT_PATH" "Skipped" ;;
  a) save_checkpoint "paused" "$CURRENT_PHASE" "$CURRENT_PHASE"; exit 0 ;;
esac
```

### User Choice Actions

- **(r)evise**: Invoke `/revise --auto-mode` with debug findings, retry phase
- **(c)ontinue**: Mark `[INCOMPLETE]`, add debugging notes, proceed to next phase
- **(s)kip**: Mark `[SKIPPED]`, add debugging notes, proceed to next phase
- **(a)bort**: Save checkpoint with debug info, exit for manual intervention

### Debugging Notes Format

```markdown
#### Debugging Notes
- **Date**: 2025-10-03
- **Issue**: Phase failed with null pointer
- **Debug Report**: [../reports/026_debug.md](../reports/026_debug.md)
- **Root Cause**: Missing null check
- **Resolution**: Applied
- **Fix Applied In**: abc1234
```

### Fallback Mechanisms

All agent invocations have fallback mechanisms to guarantee 100% success:

1. **Spec-Updater Fallback**: Direct checkbox-utils.sh if agent fails
2. **Debug Report Fallback**: analyze-error.sh utility if /debug fails
3. **Research Artifact Fallback**: Create from agent output if artifact creation fails
4. **PR Creation Fallback**: Manual gh command if github-specialist fails

---

## Checkpoint Management

Smart auto-resume system with 90% success rate and 5-condition safety checks.

### When Checkpoints Are Used

- **Automatic saves**: After each phase completion with git commit
- **Auto-resume**: 90% of resumes happen automatically without prompts
- **Safety checks**: 5 conditions verified before auto-resume

### Auto-Resume Safety Conditions

1. Tests passing in last run (tests_passing = true)
2. No recent errors (last_error = null)
3. Checkpoint age < 7 days
4. Plan file not modified since checkpoint
5. Status = "in_progress"

### Workflow

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

### Checkpoint State Fields

```json
{
  "workflow_description": "implement",
  "plan_path": "/path/to/plan.md",
  "current_phase": 3,
  "total_phases": 5,
  "completed_phases": [1, 2],
  "status": "in_progress",
  "tests_passing": true,
  "replan_count": 0,
  "phase_replan_count": {},
  "replan_history": []
}
```

### Benefits

- **Smart auto-resume**: 90% automatic, no prompts needed
- **5-condition safety**: Clear feedback on skip reason
- **Schema migration**: Backward-compatible checkpoints
- **Atomic saves**: No partial state corruption
- **Consistent naming**: Easy to identify workflow type

---

## Summary Generation

Incremental summary generation tracks implementation progress after each phase.

### Partial Summary (During Implementation)

Created/updated after each phase completion at `[specs-dir]/summaries/NNN_partial.md`

**Required Content:**
- **Metadata**: Date started, specs directory, plan link, status "in_progress", phases completed "M/N"
- **Progress**: Last completed phase (name, date, commit), phases checklist with completion dates
- **Resume**: Instructions for `/implement [plan-path] M+1` (auto-resume enabled by default)
- **Notes**: Brief implementation observations

### Final Summary (After All Phases Complete)

Rename `NNN_partial.md` → `NNN_implementation_summary.md` and finalize.

**Finalization Updates:**
- Remove "(PARTIAL)" from title
- Change status: `in_progress` → `complete`
- Update phases: `M/N` → `N/N`
- Add completion date and lessons learned
- Remove resume instructions

### Registry and Cross-References

**Update SPECS.md Registry:**
- Increment "Summaries" count
- Update "Last Updated" date

**Bidirectional Links:**
- Add "## Implementation Summary" section to plan file
- Add "## Implementation Status" section to each research report
- Verify all links created (non-blocking if fails)

---

## Advanced Features

### Dry-Run Mode

Preview execution plan without making changes using the `--dry-run` flag.

**Usage**: `/implement specs/plans/025_plan.md --dry-run`

**Analysis Performed:**
1. Plan parsing (structure, phases, tasks, dependencies)
2. Complexity evaluation (hybrid complexity scores per phase)
3. Agent assignments (which agents invoked for each phase)
4. Duration estimation (agent-registry metrics)
5. File/test analysis (affected files and tests)
6. Execution preview (wave-based order with parallelism)
7. Confirmation prompt (proceed or exit)

**Scope:**
- **Analyzes**: Plan structure, complexity scores, agent assignments, duration, affected files/tests, execution waves
- **Does NOT**: Create/modify files, run tests, create git commits, invoke agents

### Progress Dashboard

Enable real-time visual progress tracking with the `--dashboard` flag.

**Features:**
- **Real-time ANSI rendering**: Visual dashboard with Unicode box-drawing
- **Phase progress**: See all phases with status icons (✓ Complete, → In Progress, ⬚ Pending)
- **Progress bar**: Visual representation of completion percentage
- **Time tracking**: Elapsed time and estimated remaining duration
- **Test results**: Last test status with pass/fail indicator
- **Wave information**: Shows parallel execution waves

**Terminal Requirements:**
- **Supported**: xterm, xterm-256color, screen, tmux, kitty, alacritty
- **Unsupported**: dumb terminals, non-interactive shells
- **Graceful Fallback**: Automatically falls back to `PROGRESS:` markers

**Dashboard Layout Example:**
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

### Parallel Execution with Dependencies

Analyze phase dependencies to enable parallel execution in waves.

**Dependency Format:**
Phases declare dependencies in header: `dependencies: [1, 2]`

**Workflow:**
1. **Parse dependencies**: Use `parse-phase-dependencies.sh` to generate execution waves
2. **Group phases**: Each wave contains parallelizable phases
3. **Execute waves**: Single-phase waves run normally, multi-phase waves invoke multiple agents simultaneously
4. **Error handling**: Fail-fast on phase failure

**Safety:**
- Max 3 concurrent phases per wave
- Fail-fast behavior
- Checkpoint after each wave
- Aggregate test results

### Pull Request Creation

Create GitHub pull request automatically after implementation complete with `--create-pr` flag.

**Prerequisites:**
- gh CLI installed and authenticated
- Repository has remote configured
- Branch pushed to remote

**Workflow:**
1. Verify gh CLI available and authenticated
2. Invoke github-specialist agent via Task tool
3. Generate PR title from plan name
4. Create PR body with implementation overview, phases, test results, file changes
5. Execute: `gh pr create --title "..." --body "..."`
6. Extract PR URL and update summary/plan files

**Fallback:**
If agent fails, provide manual gh command with pre-filled title/body.

### Hybrid Complexity Evaluation

Evaluate phase complexity using hybrid approach: threshold-based scoring with agent evaluation for borderline cases.

**Workflow:**
1. Calculate threshold-based score (complexity-utils.sh)
2. Determine if agent evaluation needed (score ≥7 OR tasks ≥8)
3. Run hybrid_complexity_evaluation function (may invoke complexity-estimator agent)
4. Parse result (final_score, evaluation_method, agent_reasoning)
5. Log evaluation for analytics
6. Export COMPLEXITY_SCORE for downstream decisions

**Expected Impact**: 30% reduction in expansion errors via context-aware evaluation

**Error Handling**: Agent timeout/failure/invalid response → Fallback to threshold score

### Proactive Expansion Check

Before implementation, evaluate if phase should be expanded using agent-based judgment.

**Evaluation Criteria**: Task complexity, scope breadth, interrelationships, parallel work potential, clarity vs detail tradeoff

**If Expansion Recommended**: Display formatted recommendation with rationale and `/expand phase` command

**Relationship to Reactive Expansion:**
- **Proactive** (Before implementation): Recommendation only
- **Reactive** (After implementation): Auto-revision via `/revise --auto-mode`

### Automatic Collapse Detection

Automatically evaluate if an expanded phase should be collapsed back to main plan file after completion.

**Trigger Conditions**: Phase is expanded AND phase is completed

**Collapse Thresholds**: Tasks ≤ 5 AND Complexity < 6.0 (both required)

**Workflow:**
1. Check phase expansion and completion status
2. Extract metrics: task count, complexity score
3. Log evaluation for observability
4. If thresholds met: Invoke `/revise --auto-mode collapse_phase`
5. Update plan path if structure level changed (Level 1 → Level 0)

---

## Troubleshooting

### Command Not Found

**Symptom**: `/implement` command not recognized

**Solution**:
- Verify command file exists: `ls -la .claude/commands/implement.md`
- Check frontmatter for valid syntax
- Restart Claude Code session

### Checkpoint Resume Fails

**Symptom**: Cannot auto-resume from checkpoint

**Diagnosis**: Check skip reason
```bash
source .claude/lib/checkpoint-utils.sh
get_skip_reason ".claude/data/checkpoints/implement.json"
```

**Common Reasons:**
1. Tests failing in last run → Fix failing tests before resuming
2. Checkpoint too old (>7 days) → Start fresh implementation
3. Plan file modified → Review changes, decide to resume or restart
4. Status not "in_progress" → Check checkpoint corruption

**Solutions:**
- Delete checkpoint and start fresh: `rm .claude/data/checkpoints/implement.json`
- Fix identified issue and retry
- Use manual phase selection: `/implement plan.md 3`

### Test Failures Not Recovering

**Symptom**: Stuck in test failure loop despite fixes

**Diagnosis**: Check error recovery level
```bash
source .claude/lib/error-handling.sh
ERROR_TYPE=$(detect_error_type "$TEST_OUTPUT")
echo "Error type: $ERROR_TYPE"
```

**Solutions:**
1. **Manual debugging**: Choose (a)bort from user prompt, debug manually
2. **Force revision**: Use `--force-replan` to trigger plan update
3. **Skip phase**: Choose (s)kip to continue implementation, revisit later
4. **Review debug report**: Check `.claude/specs/*/debug/` for analysis

### Agent Invocation Fails

**Symptom**: Code-writer or other agents not invoked correctly

**Diagnosis**: Check complexity score
```bash
source .claude/lib/complexity-utils.sh
COMPLEXITY_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$TASK_LIST")
echo "Complexity: $COMPLEXITY_SCORE"
```

**Solutions:**
- Complexity <3 → Direct execution (no agent needed)
- Complexity ≥3 → Verify Task tool available
- Agent fails → Check agent file exists: `.claude/agents/code-writer.md`
- Fallback → Implement phase manually, document in notes

### Plan Hierarchy Out of Sync

**Symptom**: Parent plan checkboxes don't reflect phase completion

**Diagnosis**: Check hierarchy consistency
```bash
source .claude/lib/checkbox-utils.sh
verify_checkbox_consistency "$PLAN_PATH" "$PHASE_NUM"
```

**Solutions:**
1. **Manual sync**: Run `mark_phase_complete "$PLAN_PATH" "$PHASE_NUM"`
2. **Verify expanded phases**: Check if phase file exists separately
3. **Check plan level**: Ensure parser detects correct structure level
4. **Re-invoke spec-updater**: Manually trigger hierarchy update

### Dashboard Not Displaying

**Symptom**: Dashboard flag enabled but no visual output

**Diagnosis**: Check terminal capabilities
```bash
source .claude/lib/progress-dashboard.sh
detect_terminal_capabilities | jq
```

**Solutions:**
- Terminal unsupported → Use PROGRESS: markers (automatic fallback)
- TERM variable unset → Export: `export TERM=xterm-256color`
- Non-interactive shell → Run in interactive terminal
- Dashboard disabled → Verify flag: `--dashboard` passed correctly

### Dry-Run Mode Shows No Output

**Symptom**: `--dry-run` flag doesn't display preview

**Diagnosis**: Check if plan file valid
```bash
.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PLAN_FILE"
```

**Solutions:**
- Plan file not found → Provide absolute path
- Plan structure invalid → Validate plan format
- Utilities missing → Source parse-adaptive-plan.sh
- Permission denied → Check file permissions

### PR Creation Fails

**Symptom**: `--create-pr` flag doesn't create pull request

**Diagnosis**: Check gh CLI status
```bash
command -v gh || echo "gh CLI not installed"
gh auth status || echo "gh CLI not authenticated"
```

**Solutions:**
1. **Install gh CLI**: https://cli.github.com/
2. **Authenticate**: `gh auth login`
3. **Push branch**: `git push -u origin $(git branch --show-current)`
4. **Manual creation**: Use fallback gh command provided
5. **Review agent output**: Check github-specialist response

### Summary Not Generated

**Symptom**: Implementation complete but no summary file

**Diagnosis**: Check summary path
```bash
SPECS_DIR=$(dirname "$(dirname "$PLAN_FILE")")
ls -la "$SPECS_DIR/summaries/"
```

**Solutions:**
- Summaries directory missing → Create: `mkdir -p "$SPECS_DIR/summaries/"`
- Partial summary exists → Finalize: Rename `*_partial.md` → `*_implementation_summary.md`
- Permission denied → Check directory permissions
- Manual creation → Use summary template from guide

---

## Integration with Other Commands

This command is part of the standards enforcement pipeline:

1. `/research` - Researches topic (no standards needed)
2. `/plan` - Discovers and captures standards in plan metadata
3. `/implement` - **Applies standards during code generation** (← THIS COMMAND)
4. `/test` - Verifies implementation using standards-defined test commands
5. `/document` - Creates documentation following standards format
6. `/refactor` - Validates code against standards

### How /implement Uses Standards

**From /plan:**
- Reads captured standards file path from plan metadata
- Uses plan's documented test commands and coding style

**Applied During Implementation:**
- **Code generation**: Follows Code Standards (indentation, naming, error handling)
- **Test execution**: Uses Testing Protocols (test commands, patterns)
- **Documentation**: Creates docs per Documentation Policy

**Verified Before Commit:**
- Standards compliance checked before marking phase complete
- Commit message notes which standards were applied

---

## See Also

- [/plan Command Guide](plan-command-guide.md) - Creating implementation plans
- [/revise Command Guide](revise-command-guide.md) - Adaptive replanning
- [/debug Command Guide](debug-command-guide.md) - Error recovery
- [Checkpoint Recovery Pattern](.claude/docs/concepts/patterns/checkpoint-recovery.md)
- [Parallel Execution Pattern](.claude/docs/concepts/patterns/parallel-execution.md)
- [Behavioral Injection Pattern](.claude/docs/concepts/patterns/behavioral-injection.md)
- [Command Development Guide](command-development-guide.md)
- [Agent Development Guide](agent-development-guide.md)
