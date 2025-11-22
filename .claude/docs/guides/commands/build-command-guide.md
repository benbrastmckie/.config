# /build Command - Complete Guide

**Executable**: `.claude/commands/build.md`

**Quick Start**: Run `/build [plan-file] [starting-phase]` - executes implementation plan with automated testing and debugging.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Usage Examples](#usage-examples)
4. [Advanced Topics](#advanced-topics)
5. [Troubleshooting](#troubleshooting)
6. [See Also](#see-also)

---

## Overview

### Purpose

The `/build` command executes existing implementation plans through a complete build-from-plan workflow: implementation → testing → conditional debugging/documentation. It automates the implementation process using the implementer-coordinator agent, runs tests, and handles failures through debugging or success through documentation.

### When to Use

- **Executing implementation plans**: When you have an existing plan file and want to implement it
- **Resuming interrupted work**: Auto-resumes from checkpoints when no plan specified
- **Iterative development**: Supports starting from specific phases for incremental work
- **Automated workflows**: Integrates testing and debugging into implementation

### When NOT to Use

- **Creating new plans**: Use `/plan` or `/plan` instead
- **Research-only tasks**: Use `/research` for investigation without implementation
- **Bug investigation**: Use `/debug` for debug-focused workflows
- **Plan revision**: Use `/revise` or `/revise` to modify existing plans

---

## Architecture

### Design Principles

1. **State Machine Foundation**: Uses workflow-state-machine.sh v2.0+ for reliable state transitions
2. **Agent Delegation**: Delegates implementation to implementer-coordinator agent with behavioral injection
3. **Fail-Fast Verification**: Comprehensive return code verification prevents silent failures
4. **Auto-Resume Support**: Checkpoint-based resumption for interrupted workflows
5. **Conditional Branching**: Test results determine debug vs documentation path

### Patterns Used

- **State-Based Orchestration**: (state-based-orchestration-overview.md) Manages workflow through explicit states
- **Behavioral Injection**: (behavioral-injection.md) Separates orchestration from agent behavior
- **Fail-Fast Verification**: (Standard 0) Mandatory verification after agent invocations
- **Checkpoint Management**: (checkpoint-utils.sh) Enables workflow resumption

### Workflow States

```
┌─────────────┐
│  IMPLEMENT  │ ← Starting state
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    TEST     │
└──────┬──────┘
       │
       ├─ Tests Pass ──▶ ┌────────────┐
       │                 │  DOCUMENT  │
       │                 └─────┬──────┘
       │                       │
       └─ Tests Fail ───▶ ┌─────────┐  │
                          │  DEBUG  │  │
                          └────┬────┘  │
                               │       │
                               ▼       ▼
                          ┌─────────────┐
                          │  COMPLETE   │
                          └─────────────┘
```

### Integration Points

- **State Machine**: workflow-state-machine.sh (>=2.0.0) for state management
- **Checkpointing**: checkpoint-utils.sh for workflow resumption
- **Implementation**: implementer-coordinator agent for phase execution
- **Debugging**: debug-analyst agent for test failure investigation
- **Testing**: Auto-detects test frameworks (npm test, pytest, run_all_tests.sh)

### Subprocess Isolation Architecture

The /build command uses multiple bash blocks, each running as a **separate subprocess**. This architectural constraint requires careful library management.

**Why Subprocess Isolation Matters**:

```
┌─────────────────────────────┐
│ Bash Block 1 (PID: 12345)   │
│ - Source libraries          │
│ - Initialize state machine  │
│ - Functions available here  │
└─────────────────────────────┘
           │
           │ SUBPROCESS TERMINATES
           │ All functions/variables LOST
           ▼
┌─────────────────────────────┐
│ Bash Block 2 (PID: 12346)   │
│ - Must RE-SOURCE libraries  │
│ - Must RELOAD state         │
│ - Functions NOT inherited   │
└─────────────────────────────┘
```

**Three-Tier Sourcing Pattern**:

Each bash block in /build follows this sourcing pattern:

```bash
# Tier 1: Critical Foundation (fail-fast required)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Tier 2: Workflow Support (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh" 2>/dev/null || true

# Tier 3: Command-Specific (optional)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || true
```

**State Flow Across Blocks**:

```
Block 1: Initialize               Block 2: Execute              Block 3: Complete
┌──────────────────────┐         ┌──────────────────────┐      ┌──────────────────────┐
│ sm_init()            │         │ load_workflow_state()│      │ load_workflow_state()│
│ append_workflow_state│         │ (restores state)     │      │ (restores state)     │
│ (persist to file)    │────────▶│ process_phases()     │─────▶│ display_summary()    │
│                      │  FILE   │ save_completed_states│ FILE │ cleanup_temp_files() │
└──────────────────────┘  I/O    └──────────────────────┘  I/O └──────────────────────┘
```

**Key Principle**: Files are the ONLY reliable cross-block communication channel.

**Common Failure Pattern (Fixed)**:
```bash
# Block 1: Initialize state machine
source workflow-state-machine.sh
sm_init "build" "plan.md"  # Works

# Block 2: WRONG - library not re-sourced
save_completed_states_to_state  # EXIT 127: command not found

# Block 2: CORRECT - re-source before use
source workflow-state-machine.sh
save_completed_states_to_state  # Works
```

**See Also**:
- [Bash Block Execution Model](../../concepts/bash-block-execution-model.md) - Complete subprocess isolation documentation
- [Exit Code 127 Troubleshooting](../../troubleshooting/exit-code-127-command-not-found.md) - Diagnostic flowchart

### Data Flow

1. **Input**: Plan file path (or auto-detect from checkpoints/recent plans)
2. **State Initialization**: sm_init() with workflow_type="build"
3. **Implementation Phase**: implementer-coordinator executes plan phases
4. **Testing Phase**: Run tests and capture exit code
5. **Conditional Branch**:
   - Tests pass → Document phase → Complete
   - Tests fail → Debug phase → Complete (manual retry needed)
6. **Output**: Implemented features with git commits per phase

### Phase Update Mechanism

After the implementer-coordinator completes all phases, the build command automatically marks phases as complete in the plan file:

1. **Checkbox Updates**: All task checkboxes in completed phases are marked `[x]`
2. **[COMPLETE] Markers**: Phase headings receive `[COMPLETE]` suffix (e.g., `### Phase 1: Setup [COMPLETE]`)
3. **Hierarchy Synchronization**: Updates propagate to phase files and stage files in expanded plans (Level 1/2)
4. **Verification**: Checkbox consistency is verified after updates

**Implementation Details**:
- Uses `checkbox-utils.sh` functions: `mark_phase_complete()`, `add_complete_marker()`, `verify_checkbox_consistency()`
- Fallback to spec-updater agent if direct updates fail
- Phase completion status persisted to workflow state for recovery

**Plan File Before**:
```markdown
### Phase 1: Setup

Tasks:
- [ ] Create project structure
- [ ] Initialize dependencies
```

**Plan File After**:
```markdown
### Phase 1: Setup [COMPLETE]

Tasks:
- [x] Create project structure
- [x] Initialize dependencies
```

### Progress Tracking During Execution

The build command provides real-time visibility into phase execution through status markers:

**Marker Lifecycle**:
```
[NOT STARTED] --> [IN PROGRESS] --> [COMPLETE]
```

**How it Works**:

1. **Plan Creation**: When /plan creates a plan, all phases have `[NOT STARTED]` markers
2. **Build Start**: First phase is marked `[IN PROGRESS]` when build begins
3. **Phase Completion**: As each phase completes, markers transition:
   - Current phase: `[IN PROGRESS]` -> `[COMPLETE]`
   - Next phase: `[NOT STARTED]` -> `[IN PROGRESS]`

**Visual Progress Example**:

```markdown
# During Phase 2 execution:
### Phase 1: Setup [COMPLETE]
### Phase 2: Implementation [IN PROGRESS]
### Phase 3: Testing [NOT STARTED]

# After Phase 2 completes:
### Phase 1: Setup [COMPLETE]
### Phase 2: Implementation [COMPLETE]
### Phase 3: Testing [IN PROGRESS]
```

**Legacy Plan Support**:
Plans created without status markers receive automatic `[NOT STARTED]` markers when /build runs, ensuring all plans benefit from progress tracking.

**Related**: See [Plan Progress Tracking](../reference/standards/plan-progress.md) for complete documentation of the marker system and utility functions.

---

## Usage Examples

### Example 1: Basic Usage (Execute Most Recent Plan)

```bash
/build
```

**Expected Output**:
```
=== Build-from-Plan Workflow ===

PROGRESS: No plan file specified, searching for incomplete plans...
✓ Auto-detected most recent plan: 001_auth_implementation.md
Plan: /home/user/.config/.claude/specs/123_auth/plans/001_auth_implementation.md
Starting Phase: 1

✓ State machine initialized

=== Phase 1: Implementation ===

EXECUTE NOW: USE the Task tool to invoke implementer-coordinator agent
...
✓ Implementation phase complete

=== Phase 2: Testing ===

Running tests: npm test
...
✓ Tests passed

=== Phase 3: Documentation ===
...
✓ Documentation phase complete

=== Build Complete ===

Workflow Type: build
Implementation: ✓ Complete
Testing: ✓ Passed
```

**Explanation**:
Auto-detects the most recent plan file and executes all phases from beginning to end. Creates git commits for completed phases.

### Example 2: Execute Specific Plan from Phase 3

```bash
/build .claude/specs/123_auth/plans/001_auth_implementation.md 3
```

**Expected Output**:
```
=== Build-from-Plan Workflow ===

Plan: .claude/specs/123_auth/plans/001_auth_implementation.md
Starting Phase: 3

✓ State machine initialized

=== Phase 3: Implementation ===
...
```

**Explanation**:
Executes specific plan starting from phase 3 (skipping phases 1-2). Useful for resuming after manual interruption or completing remaining phases.

### Example 3: Dry-Run Mode

```bash
/build --dry-run
```

**Expected Output**:
```
=== DRY-RUN MODE: Preview Only ===

Plan: 001_auth_implementation.md
Starting Phase: 1

Phases would be executed by implementer-coordinator agent
Test results would determine debug vs documentation path
```

**Explanation**:
Preview mode shows what would be executed without making changes. Useful for validating plan discovery and phase detection.

### Example 4: Auto-Resume from Checkpoint

```bash
/build
```

**Expected Output**:
```
=== Build-from-Plan Workflow ===

PROGRESS: No plan file specified, searching for incomplete plans...
✓ Auto-resuming from checkpoint: Phase 4
  Plan: 001_auth_implementation.md

Plan: /home/user/.config/.claude/specs/123_auth/plans/001_auth_implementation.md
Starting Phase: 4

✓ State machine initialized

=== Phase 4: Implementation ===
...
```

**Explanation**:
Automatically resumes from checkpoint if found (<24 hours old). Enables workflow continuation after interruptions.

### Example 5: Test Failure Path

```bash
/build
```

**Expected Output**:
```
...
=== Phase 2: Testing ===

Running tests: npm test

  FAIL  src/auth.test.js
    ✕ validates JWT tokens (23 ms)

✗ Tests failed (exit code: 1)

=== Phase 3: Debug (Tests Failed) ===

EXECUTE NOW: USE the Task tool to invoke debug-analyst agent

Workflow-Specific Context:
- Test Command: npm test
- Test Exit Code: 1
- Workflow Type: build
- Test Output: Available above in execution log

NOTE: After debug, you may re-run /build to retry tests

=== Build Complete ===

Workflow Type: build
Implementation: ✓ Complete
Testing: ✗ Failed (debugged)

Re-run after applying fixes: /build $PLAN_FILE
```

**Explanation**:
When tests fail, automatically transitions to debug phase. Debug-analyst investigates failures and provides analysis. User must apply fixes and re-run.

---

## Advanced Topics

### Persistence Behavior (Iteration Loop)

The `/build` command supports persistent iteration for large plans (10+ phases). This enables executing plans that exceed single-invocation context limits through automatic continuation.

#### How Iteration Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    /build Iteration Loop                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Iteration 1                Iteration 2                         │
│   ┌─────────────┐           ┌─────────────┐                     │
│   │ Phases 1-4  │──────────▶│ Phases 5-8  │──────────▶ ...      │
│   │ (complete)  │  summary  │ (complete)  │  summary            │
│   └─────────────┘           └─────────────┘                     │
│         │                         │                              │
│         ▼                         ▼                              │
│   work_remaining: 5-12     work_remaining: 9-12                 │
│                                                                  │
│   Context check:           Context check:                        │
│   ~60% (continue)          ~85% (continue)                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

#### Configuration Options

| Flag | Default | Description |
|------|---------|-------------|
| `--max-iterations` | 5 | Maximum iterations before halt |
| `--context-threshold` | 90 | Context percentage threshold for graceful halt |
| `--resume` | - | Resume from checkpoint file |

**Examples**:
```bash
# Allow more iterations for very large plans
/build plan.md --max-iterations=8

# More aggressive context threshold (halt earlier)
/build plan.md --context-threshold=80

# Resume from checkpoint
/build --resume ~/.claude/data/checkpoints/build_123_iteration_3.json
```

#### Context Threshold Halt

When estimated context usage reaches the threshold (default 90%), /build:

1. Saves a resumption checkpoint with iteration state
2. Displays resumption instructions
3. Exits cleanly (code 0)

**Checkpoint Contents** (v2.1 schema):
```json
{
  "version": "2.1",
  "plan_path": "/path/to/plan.md",
  "iteration": 3,
  "max_iterations": 5,
  "continuation_context": "/path/to/iteration_2_summary.md",
  "work_remaining": "phase_8,phase_9,phase_10",
  "context_estimate": 185000,
  "halt_reason": "context_threshold"
}
```

**Resumption**:
```bash
# Resume from checkpoint
/build --resume ~/.claude/data/checkpoints/build_123_iteration_3.json

# Or manually specify starting phase
/build plan.md 8
```

#### Stuck Detection

If `work_remaining` is unchanged for 2 consecutive iterations, /build detects a stuck state:

**Symptoms**:
- Same phases remain incomplete across iterations
- Progress stalled despite multiple attempts

**Behavior**:
- Logs stuck error to error log
- Halts with error message
- Creates checkpoint for manual intervention

**Recovery**:
1. Review stuck phases in plan file
2. Check for blocking issues (dependencies, failures)
3. Manually resolve blocking issues
4. Resume with `/build --resume <checkpoint>`

#### Context Estimation Formula

The context estimate is a heuristic calculation:

```
estimated_tokens = base(20k)
                 + completed_phases * 15k
                 + remaining_phases * 12k
                 + continuation_context * 5k
```

**Tuning**: If context halts occur too early, increase `--context-threshold`. If overflows occur, decrease threshold.

### Performance Considerations

**Checkpoint Optimization**:
- Checkpoints saved after each phase completion
- Stale checkpoint detection (<24 hours) prevents incorrect resumption
- Delete checkpoint manually: `rm ~/.claude/data/checkpoints/build_checkpoint.json`

**Test Framework Detection**:
- Automatically detects: npm test, pytest, run_all_tests.sh
- Extraction from plan: searches for test command patterns
- Manual specification: modify TEST_COMMAND in plan file

**Commit Granularity**:
- One commit per completed phase
- Git commit messages reference phase number and name
- Enables easy rollback to specific implementation stages

### Customization

**Starting Phase Override**:
```bash
/build plan.md 5  # Start from phase 5
```

**Checkpoint Behavior**:
- Create `.claude/data/checkpoints/` directory for checkpoint isolation
- Checkpoint validity period: 24 hours (hardcoded)
- Future: Add `--ignore-checkpoint` flag for forced fresh starts

**Test Command Override**:
Edit plan file to include explicit test command:
```markdown
Testing:
\`\`\`bash
npm test -- --coverage
\`\`\`
```

### Integration with Other Workflows

**Research → Plan → Build Chain**:
```bash
/plan "implement user authentication"  # Creates plan
/build                                          # Auto-detects and executes plan
```

**Plan → Build → PR Chain**:
```bash
/plan "add API rate limiting"
/build
gh pr create --title "Add API rate limiting"
```

**Iterative Development**:
```bash
/build plan.md 1    # Implement phase 1
# Manual testing/review
/build plan.md 2    # Continue with phase 2
```

**Debug Loop**:
```bash
/build              # Tests fail, debug phase runs
# Apply fixes manually
/build              # Retry from test phase (checkpoint resumes)
```

---

## Troubleshooting

### Common Issues

#### Issue 1: No Plan File Found

**Symptoms**:
- Error: "No plan file found in specs/*/plans/"
- Occurs when running `/build` without arguments

**Cause**:
No plan files exist in `.claude/specs/*/plans/` directories.

**Solution**:
```bash
# Create a plan first
/plan "feature description"
# Or /plan "feature description"

# Then run build
/build
```

#### Issue 2: State Machine Initialization Failed

**Symptoms**:
- Error: "State machine initialization failed"
- Diagnostic shows library version incompatibility

**Cause**:
Workflow-state-machine.sh version <2.0.0 or missing library dependencies.

**Solution**:
```bash
# Check library version
cat .claude/lib/workflow/workflow-state-machine.sh | grep "VERSION="

# If version <2.0.0, update library
# (Follow library update process)

# Verify state persistence library exists
ls .claude/lib/core/state-persistence.sh
```

#### Issue 3: Checkpoint Stale or Corrupted

**Symptoms**:
- Warning: "Checkpoint stale (>24h), searching for recent plan..."
- Auto-resume fails with checkpoint error

**Cause**:
Checkpoint file is older than 24 hours or corrupted JSON.

**Solution**:
```bash
# Remove stale checkpoint
rm ~/.claude/data/checkpoints/build_checkpoint.json

# Run build fresh
/build plan.md
```

#### Issue 4: Git Changes Not Detected

**Symptoms**:
- Warning: "No changes detected (implementation may have been no-op)"
- No git commits found

**Cause**:
Implementer-coordinator agent didn't create file changes, or git repository not initialized.

**Solution**:
```bash
# Verify git repository
git status

# Check if implementation actually made changes
git diff

# If no changes, review agent output for errors
# Agent may have encountered issues during implementation
```

#### Issue 5: Test Framework Not Detected

**Symptoms**:
- Note: "No explicit test command found in plan"
- Tests skipped entirely

**Cause**:
No package.json, pytest.ini, or run_all_tests.sh found, and plan doesn't specify test command.

**Solution**:
Add test command to plan file:
```markdown
### Phase N: Testing

\`\`\`bash
npm test
\`\`\`
```

Or create run_all_tests.sh:
```bash
#!/bin/bash
# Add test commands here
pytest tests/
```

#### Issue 6: Tests Fail But No Debug Output

**Symptoms**:
- Tests fail with exit code >0
- Debug phase invoked but no useful analysis

**Cause**:
Debug-analyst agent may need test output context or specific test framework knowledge.

**Solution**:
```bash
# Run tests manually to see full output
npm test --verbose

# Review test output for specific failures
# Apply fixes based on error messages

# Re-run build
/build plan.md 2  # Resume from test phase
```

#### Issue 7: Reviewing Error Logs Before Retry

**Symptoms**:
- Build fails repeatedly with similar errors
- Unclear which phase or component is causing failures
- Need to understand error patterns before retry

**Cause**:
Multiple build attempts with similar failures may indicate systemic issues that require investigation.

**Solution**:
Use `/errors` command to review error history before retrying:

```bash
# Check recent /build errors
/errors --command /build --limit 5

# Review errors for specific workflow
/errors --workflow-id build_20251019_153045

# Check for error patterns
/errors --summary

# Investigate specific error types (e.g., state, agent, validation)
/errors --type state_error --limit 10
```

This helps identify:
- Whether the error is a new issue or recurring pattern
- Which phase or agent is failing most frequently
- If recent environmental changes are causing failures

After understanding the error pattern, apply appropriate fixes before retry.

**See Also**: [/errors Command Guide](errors-command-guide.md), [Debug Command Guide](debug-command-guide.md)

#### Issue 8: Phase Updates Not Applied to Plan File

**Symptoms**:
- Build completes but plan file still shows unchecked tasks `[ ]`
- No `[COMPLETE]` markers on phase headings
- Warning: "Phase update failed (will use fallback)"

**Cause**:
- checkbox-utils.sh not found or failed to source
- Phase heading format doesn't match expected pattern `### Phase N:`
- File permission issues preventing updates

**Solution**:
```bash
# Verify checkbox-utils.sh exists
ls -la .claude/lib/plan/checkbox-utils.sh

# Test checkbox functions manually
source .claude/lib/plan/checkbox-utils.sh
mark_phase_complete "/path/to/plan.md" 1

# Check file permissions
ls -la /path/to/plan.md

# Manually add [COMPLETE] marker if needed
sed -i 's/^### Phase 1:/### Phase 1: [COMPLETE]/g' /path/to/plan.md
```

#### Issue 8: Phase Hierarchy Not Synchronized

**Symptoms**:
- Main plan shows phase complete but phase file shows tasks incomplete
- verify_checkbox_consistency() warns about mismatches

**Cause**:
Expanded plan structure (Level 1/2) with phase files that weren't updated during mark_phase_complete.

**Solution**:
```bash
# Verify plan structure
source .claude/lib/plan/checkbox-utils.sh

# Check for expanded phase files
ls .claude/specs/*/plans/*/phase_*.md

# Manually propagate updates
for phase_file in .claude/specs/topic/plans/planname/phase_*.md; do
  sed -i 's/^- \[ \]/- [x]/g' "$phase_file"
done

# Verify consistency
verify_checkbox_consistency "/path/to/plan.md" 1
```

### Debug Mode

The `/build` command doesn't have a specific debug flag, but you can enable verbose output:

```bash
# Enable bash debugging
set -x
/build plan.md
set +x
```

**Checkpoint Inspection**:
```bash
# View checkpoint contents
cat ~/.claude/data/checkpoints/build_checkpoint.json | jq .

# Check checkpoint age
stat ~/.claude/data/checkpoints/build_checkpoint.json
```

**State Machine Inspection**:
```bash
# View state file
cat ~/.claude/data/state/workflow_state.json | jq .

# Check current state
cat ~/.claude/data/state/workflow_state.json | jq '.current_state'
```

### Getting Help

- Check [Command Reference](../reference/standards/command-reference.md) for quick syntax
- Review [State-Based Orchestration](../architecture/state-based-orchestration-overview.md) for workflow details
- See related commands: `/implement`, `/coordinate`, `/debug`
- Review [Adaptive Planning Guide](../workflows/adaptive-planning-guide.md) for plan structure

---

## See Also

- [State-Based Orchestration Overview](../architecture/state-based-orchestration-overview.md)
- [Implementer-Coordinator Agent](../../agents/implementer-coordinator.md)
- [Debug-Analyst Agent](../../agents/debug-analyst.md)
- [Checkpoint Utils Reference](../../lib/workflow/checkpoint-utils.sh)
- [Command Reference](../reference/standards/command-reference.md)
- Related Commands: `/implement`, `/coordinate`, `/debug`, `/plan`
