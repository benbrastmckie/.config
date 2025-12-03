# /implement Command Guide

## Overview

The `/implement` command executes implementation-only workflows - transforming plans into working code and tests without running the test suite. It delegates to the implementer-coordinator agent for multi-phase plan execution with iteration management and context-aware continuation.

**Purpose**: Write code AND tests (but do not execute tests)
**Workflow Type**: implement-only
**Terminal State**: IMPLEMENT (with option to continue to COMPLETE)
**Prerequisites**: Existing implementation plan file
**Output**: Implementation summary with Testing Strategy section

## Key Characteristics

### What /implement Does
- Executes implementation phases from a plan
- Writes code according to plan specifications
- Writes tests during Testing phases (but does NOT execute them)
- Creates implementation summary with Testing Strategy section
- Manages iteration when context limits are reached
- Updates phase checkboxes as work completes
- Updates phase status markers ([IN PROGRESS] and [COMPLETE]) in real-time
- Persists state for handoff to /test command

### What /implement Does NOT Do
- Execute tests (use `/test` for test execution)
- Debug test failures (use `/test` which invokes debug-analyst)
- Measure coverage (testing infrastructure written, not run)

## Usage

### Syntax

```bash
/implement [plan-file] [starting-phase] [--dry-run] [--max-iterations=N] [--context-threshold=N]
```

### Arguments

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `plan-file` | Path | Required | Absolute or relative path to implementation plan |
| `starting-phase` | Number | 1 | Phase number to start execution from |
| `--dry-run` | Flag | false | Simulate execution without actual changes |
| `--max-iterations` | Number | 5 | Maximum iterations before forcing completion |
| `--context-threshold` | Number | 90 | Context usage % triggering iteration |

### Examples

**Basic execution** (start from Phase 0):
```bash
/implement .claude/specs/042_auth/plans/001-auth-plan.md
```

**Resume from specific phase**:
```bash
/implement .claude/specs/042_auth/plans/001-auth-plan.md 3
```

**Custom iteration limits**:
```bash
/implement plan.md --max-iterations=10 --context-threshold=85
```

**Dry run** (validate without changes):
```bash
/implement plan.md --dry-run
```

## Workflow Architecture

### Block Structure

The `/implement` command follows a 5-block architecture:

```
Block 1a: Implementation Setup
  - Argument capture (2-block pattern)
  - Library sourcing (three-tier)
  - Pre-flight validation
  - State machine initialization
  - State transition to IMPLEMENT
  ↓
Block 1b: Implementer-Coordinator Invocation [CRITICAL BARRIER]
  - Calculate summary output path
  - Invoke implementer-coordinator agent
  - Hard barrier pattern (setup → execute → verify)
  ↓
Block 1c: Implementation Verification
  - Verify summary file exists
  - Verify summary size ≥100 bytes
  - Parse iteration metadata
  - Determine continuation needs
  ↓
Block 1d: Phase Update
  - Update plan checkboxes (mark_phase_complete)
  - Persist completed states
  - Update plan status if complete
  ↓
Block 2: Completion
  - State transition to COMPLETE
  - Console summary (4-section format)
  - IMPLEMENTATION_COMPLETE signal
  - State file preservation (for /test)
  - Checkpoint cleanup
```

### State Transitions

```
INITIALIZE → IMPLEMENT → COMPLETE
```

**Terminal States**:
- `IMPLEMENT`: Implementation complete, testing not executed
- `COMPLETE`: Full workflow complete (optional, allows chaining)

### Real-Time Progress Tracking

The `/implement` command provides real-time visibility into phase execution through automatic status marker updates. As the implementation-executor agent processes each phase, it updates the plan file with status markers that users can observe during execution.

**Phase Status Markers**:
- `[NOT STARTED]`: Phase has not begun execution (initial state)
- `[IN PROGRESS]`: Phase is currently executing (set at phase start)
- `[COMPLETE]`: Phase execution finished (set at phase end)

**How It Works**:

1. **Phase Start**: When implementation-executor begins a phase, it calls `add_in_progress_marker()` to update the phase heading with `[IN PROGRESS]`
2. **Task Execution**: During execution, task checkboxes update from `[ ]` to `[x]` as tasks complete
3. **Phase End**: After all tasks complete, the executor calls `add_complete_marker()` to update the phase heading with `[COMPLETE]`
4. **Validation**: Block 1d validates all phases have `[COMPLETE]` markers and recovers any missing markers

**Real-Time Monitoring**:

During implementation execution, you can monitor progress in real-time:

```bash
# Start implementation in one terminal
/implement plan.md

# Watch progress in another terminal
watch -n 2 'grep "^### Phase" plan.md'

# Example output during execution:
### Phase 1: Setup Database [COMPLETE]
### Phase 2: Implement API [IN PROGRESS]
### Phase 3: Add Tests [NOT STARTED]
### Phase 4: Documentation [NOT STARTED]
```

**Marker Update Behavior**:

- **Non-Fatal**: Marker update failures do not block implementation work (logged as warnings)
- **Recovery**: Block 1d detects missing markers and recovers them using `verify_phase_complete()`
- **Parallel-Safe**: Each executor updates independent phase headings (no race conditions)
- **Performance**: Marker updates add <100ms overhead per phase (negligible)

### Agent Delegation

**Agent**: `implementer-coordinator.md`

**Input Contract**:
```yaml
plan_path: /path/to/plan.md
topic_path: /path/to/topic
summaries_dir: /path/to/summaries
artifact_paths: {...}
continuation_context: /path/to/previous-summary.md (optional)
iteration: 1 (or N for continuations)
```

**Return Signal**:
```yaml
IMPLEMENTATION_COMPLETE:
  summary_path: /path/to/summary.md
  plan_file: /path/to/plan.md
  work_remaining: 0 (or list of incomplete phases)
  context_exhausted: false
  context_usage_percent: 85%
  requires_continuation: false
  next_command: "/test /path/to/plan.md"
```

## Iteration Behavior

### Multi-Iteration Execution

The `/implement` command automatically loops through multiple iterations when large plans exceed context limits. This ensures complete plan execution without manual intervention.

**Iteration Decision Logic**:

After each implementer-coordinator invocation (Block 1b), the verification block (Block 1c) checks the agent's return signal:

```yaml
requires_continuation: true|false
work_remaining: "Phase 4 Phase 5 Phase 6" or "0"
context_usage_percent: 85
```

Based on this signal, the command determines the `IMPLEMENTATION_STATUS`:

- **continuing**: Work remains and context available → Loop back to Block 1b
- **complete**: All phases done → Proceed to Block 1d
- **stuck**: Work remaining unchanged across iterations → Halt and report
- **max_iterations**: Iteration limit reached → Halt and report

### IMPLEMENTATION_STATUS States

| Status | Condition | Action |
|--------|-----------|--------|
| `continuing` | `requires_continuation=true` AND work remaining | Execute next iteration |
| `complete` | `work_remaining=0` or `requires_continuation=false` | Proceed to completion |
| `stuck` | Same `work_remaining` for 2+ iterations | Halt with stuck detection |
| `max_iterations` | `ITERATION > MAX_ITERATIONS` | Halt at iteration limit |

### Iteration Loop Flow

When `IMPLEMENTATION_STATUS=continuing`, the command:

1. **Increments iteration counter**: `NEXT_ITERATION = ITERATION + 1`
2. **Saves continuation context**: Copies current summary to `iteration_${ITERATION}_summary.md`
3. **Updates state variables**: Persists `ITERATION`, `CONTINUATION_CONTEXT`, `WORK_REMAINING`
4. **Loads updated state**: Bash block loads state file to get new `ITERATION` value
5. **Validates iteration limit**: Ensures `ITERATION ≤ MAX_ITERATIONS`
6. **Re-invokes coordinator**: Repeats Task invocation with updated iteration parameters
7. **Verifies completion**: Returns to Block 1c to check for further continuation

**Example Multi-Iteration Execution**:

```
Iteration 1/5: Implement Phases 1-3 (context usage: 85%)
  → Status: continuing, work_remaining: "Phase 4 Phase 5 Phase 6"

Iteration 2/5: Implement Phases 4-5 (context usage: 80%)
  → Status: continuing, work_remaining: "Phase 6"

Iteration 3/5: Implement Phase 6 (context usage: 40%)
  → Status: complete, work_remaining: "0"
```

### Continuation Context Mechanism

Each iteration receives the previous iteration's summary as continuation context:

```yaml
continuation_context: ${IMPLEMENT_WORKSPACE}/iteration_${PREV_ITERATION}_summary.md
```

This enables the coordinator to:
- Resume from the exact completion point
- Maintain awareness of prior work
- Avoid re-implementing completed phases
- Track cumulative progress

**Context Handoff**:
1. Iteration 1 completes → Summary saved as `iteration_1_summary.md`
2. Iteration 2 starts → Receives `iteration_1_summary.md` as continuation context
3. Iteration 2 completes → Summary saved as `iteration_2_summary.md`
4. Iteration 3 starts → Receives `iteration_2_summary.md` as continuation context

### Max Iterations Configuration

Default: `MAX_ITERATIONS=5`

Override via command argument:
```bash
/implement plan.md --max-iterations=10
```

**When Max Iterations Reached**:
- Command halts with `IMPLEMENTATION_STATUS=max_iterations`
- Console shows: `"Max iterations (5) reached. Work remaining: Phase 7 Phase 8"`
- User can resume with `/implement plan.md 7` to continue from Phase 7
- Or increase limit: `/implement plan.md --max-iterations=10`

### Stuck Detection

The coordinator tracks `LAST_WORK_REMAINING` across iterations. If `WORK_REMAINING` is unchanged for 2+ consecutive iterations:

```
Iteration 3: work_remaining="Phase 7 Phase 8"
Iteration 4: work_remaining="Phase 7 Phase 8" (unchanged)
  → STUCK_DETECTED=true
  → IMPLEMENTATION_STATUS=stuck
```

**Stuck Handling**:
- Command halts with stuck detection message
- User investigates why phases aren't progressing
- Common causes: Missing dependencies, invalid phase structure, insufficient instructions

### Checkpoint Format for Iterations

During iteration loops, checkpoints follow the standard 3-line format:

```
[CHECKPOINT] Iteration 2 of 5
Context: ITERATION=2, CONTINUATION_CONTEXT=/path/to/iteration_1_summary.md, WORK_REMAINING=Phase 4 Phase 5
Ready for: Next iteration (Block 1b Task invocation)
```

**Line 1**: Checkpoint marker with current iteration count
**Line 2**: Context line includes `ITERATION`, `CONTINUATION_CONTEXT`, and `WORK_REMAINING` variables
**Line 3**: Ready for line specifies next step (either "Next iteration" or "Phase update")

### Single-Iteration Backward Compatibility

Small plans that complete in one iteration flow unchanged:

```
Block 1a (Setup) → Block 1b (Execute) → Block 1c (Verify) → Block 1d (Update) → Block 2 (Complete)
```

No iteration loop occurs because Block 1c sets `IMPLEMENTATION_STATUS=complete` on first check.

**Example Single-Iteration Flow**:
```
Plan: 3 phases, estimated 2 hours
Iteration 1: All phases complete (context usage: 40%)
  → Status: complete, work_remaining: "0"
  → Skip iteration loop, proceed to Block 1d
```

## Test Writing Responsibility

### Tests Written, Not Executed

A critical distinction: `/implement` WRITES tests during Testing phases but does NOT execute them. This separation enables:

1. **Focused Implementation**: Code and tests written together
2. **Deferred Execution**: Tests run separately via `/test`
3. **Iterative Testing**: Run tests multiple times without reimplementing
4. **Independent Debugging**: Fix tests without touching implementation

### Testing Phases

Plans include Testing phases where implementer-coordinator writes test files:

```markdown
## Phase 2: Testing
dependencies: [0, 1]

**Tasks**:
- [ ] Write unit tests for auth module
- [ ] Write integration tests for login flow
- [ ] Create test fixtures and mocks
```

During this phase:
- Test files are created
- Test infrastructure is set up
- Coverage targets are documented
- Tests are NOT executed

### Testing Strategy Section

Every `/implement` summary includes a Testing Strategy section documenting:

```markdown
## Testing Strategy

- **Test Files**: /path/to/tests/test_auth.sh, /path/to/tests/test_login.sh
- **Test Execution Requirements**: bash /path/to/tests/run_all.sh
- **Expected Tests**: 12
- **Coverage Target**: 80%
- **Test Framework**: bash (or pytest, jest, etc.)
- **Coverage Measurement**: kcov /path/to/tests (or coverage.py, etc.)
```

This section enables `/test` to execute tests without manual configuration.

## Integration with /test

### Summary-Based Handoff

The workflow handoff from `/implement` to `/test` uses the implementation summary:

```
/implement → creates summary → /test reads summary
```

**Handoff Methods**:

1. **Auto-discovery** (recommended):
```bash
/implement plan.md
# Produces: summaries/001-implementation-summary.md

/test plan.md
# Auto-discovers latest summary from plan's topic directory
```

2. **Explicit handoff**:
```bash
/implement plan.md
# Produces: summaries/001-implementation-summary.md

/test --file summaries/001-implementation-summary.md
# Explicitly loads summary
```

### State File Persistence

`/implement` creates a state file for `/test` to load:

```bash
# Created by /implement
${TOPIC_PATH}/.state/implement_state.sh

# Variables:
PLAN_FILE="/path/to/plan.md"
TOPIC_PATH="/path/to/topic"
IMPLEMENTATION_STATUS="complete"
ITERATION=1
LATEST_SUMMARY="/path/to/summary.md"
```

This state file is optional - `/test` can run without it using summary-based context.

### Chaining Commands

Sequential execution pattern:

```bash
/implement plan.md && /test plan.md
```

This pattern:
1. Runs `/implement` to write code and tests
2. If successful, runs `/test` to execute tests
3. `/test` auto-discovers the summary created by `/implement`
4. Full workflow: plan → implementation → testing → completion

## Iteration Management

### Multi-Iteration Workflows

Large or complex plans may require multiple iterations due to context limits:

```
Iteration 1: Phases 0-3 (context: 85%)
  ↓ REQUIRES_CONTINUATION: true
Iteration 2: Phases 4-6 (context: 78%)
  ↓ REQUIRES_CONTINUATION: false
COMPLETE
```

### Continuation Mechanism

When `REQUIRES_CONTINUATION: true`:

1. **Block 1c** detects continuation need
2. **Continuation context** created (summary from current iteration)
3. **Next iteration** invoked automatically (if below max iterations)
4. **Implementer-coordinator** receives continuation context
5. **Cumulative progress** maintained across iterations

### Iteration Limits

**Max Iterations** (default: 5):
- Prevents infinite loops
- Configurable via `--max-iterations` flag
- If reached, implementation completes with warning

**Context Threshold** (default: 90%):
- Triggers iteration before context exhaustion
- Configurable via `--context-threshold` flag
- Lower threshold = more aggressive iteration

## Checkpoint Resumption

### Workflow Interruption

If `/implement` is interrupted (manual stop, crash, timeout):

1. **Checkpoint file** created: `.claude/tmp/implement_checkpoint_*.json`
2. **State preserved**: current phase, iteration, context
3. **Recovery command** displayed: `/implement --resume checkpoint.json`

### Resume Pattern

```bash
# After interruption
/implement --resume .claude/tmp/implement_checkpoint_12345.json

# Or let command auto-discover latest checkpoint
/implement plan.md
# (automatically detects and offers to resume)
```

## Error Handling

### Common Errors

**Plan File Not Found**:
```
ERROR: Plan file not found: /path/to/plan.md
```
→ Solution: Verify path is correct and file exists

**Pre-flight Validation Failed**:
```
ERROR: Required function 'append_workflow_state' not found
```
→ Solution: Library sourcing failed, check .claude/lib/ exists

**Summary Verification Failed**:
```
ERROR: implementer-coordinator did not create summary file
```
→ Solution: Hard barrier failure, check agent logs for root cause

**State Transition Failed**:
```
ERROR: State transition to IMPLEMENT failed
```
→ Solution: State machine error, check workflow type configuration

### Error Logging Integration

All errors logged to `.claude/tests/logs/test-errors.jsonl`:

```bash
# View recent /implement errors
/errors --command /implement --since 1h --summary

# Analyze error patterns
/repair --command /implement --complexity 2
```

## Phase Checkbox Updates

### Automatic Checkbox Management

As phases complete, checkboxes are updated via `checkbox-utils`:

**Before**:
```markdown
## Phase 0: Setup
- [ ] Task 1
- [ ] Task 2
```

**After**:
```markdown
## Phase 0: Setup [COMPLETE]
- [x] Task 1
- [x] Task 2
```

### Update Mechanism

1. **Block 1c** parses completion signal from agent
2. **Block 1d** calls `mark_phase_complete(plan_file, phase_num)`
3. **Checkboxes** updated in place
4. **Phase status** appended: `[COMPLETE]`
5. **State persisted** for next iteration

### Plan Status Update

When all phases complete:
```markdown
## Metadata
- **Status**: [COMPLETE]
```

## Console Summary Format

### 4-Section Structure

```
═══════════════════════════════════════════════════════
IMPLEMENTATION COMPLETE
═══════════════════════════════════════════════════════

## Summary
Completed implementation of N phases (including test writing).
Run /test to execute test suite.

## Phases Completed
- Phase 0: Setup (COMPLETE)
- Phase 1: Implementation (COMPLETE)
- Phase 2: Testing (COMPLETE)

## Artifacts
- Plan: /path/to/plan.md
- Summary: /path/to/summary.md
- State: /path/to/.state/implement_state.sh

## Next Steps
• Review implementation: cat /path/to/summary.md
• Run tests: /test /path/to/plan.md
• Run tests with summary: /test --file /path/to/summary.md
```

## Examples

### Example 1: Simple Plan

```bash
# Create simple auth plan
cat > auth-plan.md <<EOF
## Phase 0: Auth Module
- [ ] Create auth.sh with login function
- [ ] Add password validation

## Phase 1: Testing
- [ ] Write test_auth.sh
EOF

# Execute implementation
/implement auth-plan.md

# Output:
# - auth.sh created
# - test_auth.sh created (not executed)
# - summary with Testing Strategy

# Run tests
/test auth-plan.md
```

### Example 2: Complex Plan with Iterations

```bash
# Large plan with many phases
/implement large-feature-plan.md --max-iterations=10

# Iteration 1: Phases 0-4 (85% context)
# Iteration 2: Phases 5-8 (78% context)
# Iteration 3: Phases 9-12 (65% context)
# COMPLETE

# All summaries preserved:
# - 001-iteration-1-summary.md
# - 002-iteration-2-summary.md
# - 003-iteration-3-summary.md

# Run tests using final summary
/test large-feature-plan.md
```

### Example 3: Testing Phase

```bash
# Plan with explicit Testing phase
cat > feature-plan.md <<EOF
## Phase 0: Core Implementation
- [ ] Implement feature.sh

## Phase 1: Testing
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] Create test fixtures
EOF

# Implementation writes tests
/implement feature-plan.md

# Summary includes:
# ## Testing Strategy
# - Test Files: tests/test_feature.sh, tests/integration_test.sh
# - Test Command: bash tests/run_all.sh

# Execute tests
/test feature-plan.md
```

## Troubleshooting

### Issue: Summary Not Created

**Symptoms**: Block 1c fails with "Summary file not found"

**Causes**:
- Agent invocation failed
- Hard barrier verification failed
- Permissions issue in summaries directory

**Solutions**:
1. Check agent logs for errors
2. Verify summaries directory exists and is writable
3. Review plan for malformed phases
4. Check `/errors --command /implement`

### Issue: Iteration Loop Never Ends

**Symptoms**: Command runs through max iterations without completing

**Causes**:
- Plan too complex for iteration approach
- Context threshold too conservative
- Work estimation incorrect

**Solutions**:
1. Increase `--max-iterations` limit
2. Lower `--context-threshold` to iterate more aggressively
3. Split plan into smaller plans
4. Review plan complexity score

### Issue: Phase Checkboxes Not Updating

**Symptoms**: Plan shows `[ ]` after completion

**Causes**:
- `checkbox-utils` library not available
- Plan file permissions read-only
- Checkbox format non-standard

**Solutions**:
1. Verify `checkbox-utils.sh` exists
2. Check plan file is writable
3. Ensure checkboxes follow `- [ ]` format
4. Fallback to `spec-updater` if checkbox-utils fails

### Issue: State File Not Found by /test

**Symptoms**: `/test` warns "No implementation state file found"

**Causes**:
- `/implement` did not complete
- State file deleted manually
- Topic path mismatch

**Solutions**:
1. Re-run `/implement` to completion
2. Use explicit `--file` flag with summary
3. Verify topic path derivation is correct
4. State file is optional - `/test` can proceed without it

### Issue: Phase Markers Not Updating During Execution

**Symptoms**: Phase headings remain `[NOT STARTED]` or `[IN PROGRESS]` after phase completes

**Causes**:
- Executor marker update failure (non-fatal, logs warning)
- Plan file write permissions issue
- Phase heading format non-standard
- Concurrent writes from parallel executors (rare)

**Solutions**:

1. **Check Real-Time Status**:
   ```bash
   # Monitor phase status during execution
   watch -n 2 'grep "^### Phase" /path/to/plan.md'
   ```

2. **Verify Block 1d Recovery**:
   Block 1d automatically detects and recovers missing markers. After implementation completes, check output for:
   ```
   ✓ All phases marked complete by executors
   # OR
   ⚠ Recovered 2 missing [COMPLETE] markers (Phase 2, Phase 4)
   ```

3. **Manual Recovery**:
   If Block 1d did not recover markers, manually add them:
   ```bash
   # Source checkbox utilities
   source .claude/lib/plan/checkbox-utils.sh

   # Add [COMPLETE] marker to phase with all tasks done
   add_complete_marker "/path/to/plan.md" <phase_number>

   # Verify all phases complete
   verify_checkbox_consistency "/path/to/plan.md"
   ```

4. **Check Permissions**:
   ```bash
   # Verify plan file is writable
   ls -l /path/to/plan.md

   # Fix permissions if needed
   chmod u+w /path/to/plan.md
   ```

5. **Review Agent Logs**:
   Check for marker update warnings in agent output or error logs

**Note**: Missing markers are cosmetic issues that do not affect implementation correctness. Block 1d ensures final plan state is accurate even if real-time updates fail.

## Best Practices

### 1. Plan Structure

- Include explicit Testing phases for test writing
- Group related tests in single phase
- Document coverage targets in plan metadata

### 2. Iteration Management

- Use default max iterations (5) for most plans
- Lower context threshold (85%) for aggressive iteration
- Monitor iteration count - if >3, consider splitting plan

### 3. Testing Strategy

- Always include Testing Strategy in summary
- Document test commands explicitly
- Specify coverage measurement approach
- List all test files with absolute paths

### 4. Workflow Chaining

- Chain `/implement` and `/test` for complete workflow
- Use auto-discovery (don't specify --file unless needed)
- Review implementation summary before running tests

### 5. Error Recovery

- Enable error logging from start
- Use `/errors` to diagnose issues
- Preserve checkpoint files for recovery
- Review agent return signals for debugging

## See Also

- [/test Command Guide](./test-command-guide.md) - Test execution and debugging
- [Implement-Test Workflow](../workflows/implement-test-workflow.md) - End-to-end workflow patterns
- [Testing Protocols](../../reference/standards/testing-protocols.md) - Test writing standards
- [Command Authoring](../../reference/standards/command-authoring.md) - Command implementation patterns
