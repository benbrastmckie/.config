# /lean-implement Command Guide

The `/lean-implement` command provides hybrid implementation capabilities for plans containing both Lean theorem proving and software implementation phases. It intelligently routes each phase to the appropriate coordinator agent.

## Overview

When working on Lean formalization projects, plans often contain a mix of:
- **Lean phases**: Theorem proving, proof verification, Mathlib integration
- **Software phases**: Test harness setup, documentation, tooling

The `/lean-implement` command automatically classifies each phase and routes it to the appropriate coordinator:
- **lean-coordinator**: For theorem proving using lean-lsp-mcp tools
- **implementer-coordinator**: For software implementation using standard development tools

## Syntax

```bash
/lean-implement <plan-file> [starting-phase] [--mode=MODE] [--max-iterations=N] [--dry-run]
```

### Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `plan-file` | Path to implementation plan (required) | - |
| `starting-phase` | Phase number to start from | 1 |
| `--mode=MODE` | Execution mode (see below) | auto |
| `--max-iterations=N` | Maximum iteration loops | 5 |
| `--context-threshold=N` | Context usage % before checkpoint | 90 |
| `--dry-run` | Preview classification without executing | false |

### Execution Modes

| Mode | Description |
|------|-------------|
| `auto` | Automatically detect phase type and route appropriately (default) |
| `lean-only` | Execute only Lean phases, skip software phases |
| `software-only` | Execute only software phases, skip Lean phases |

## Phase Classification

The command uses a 3-tier detection algorithm with explicit `implementer:` field support:

### Tier 1: Explicit Implementer Field (Strongest Signal)

Phases can explicitly specify which coordinator to use:

```markdown
### Phase 1: Prove Modal Axioms [NOT STARTED]
implementer: lean
lean_file: /path/to/Modal.lean

Tasks:
- [ ] Prove theorem_K
- [ ] Prove theorem_T
```

Valid `implementer:` values:
- `lean`: Route to lean-coordinator
- `software`: Route to implementer-coordinator

Invalid values trigger a warning and default to `software`.

### Tier 2: lean_file Metadata (Backward Compatibility)

If a phase contains `lean_file:` metadata without explicit `implementer:`, it is classified as a Lean phase:

```markdown
### Phase 1: Prove Modal Axioms [NOT STARTED]
lean_file: /path/to/Modal.lean
```

### Tier 3: Keyword and Extension Analysis (Legacy Fallback)

If no explicit metadata, the algorithm analyzes content:

**Lean Indicators**:
- File extensions: `.lean`
- Keywords: `theorem`, `lemma`, `sorry`, `tactic`, `mathlib`
- Patterns: `prove theorem`, `lean_goal`, `lean_build`

**Software Indicators**:
- File extensions: `.ts`, `.js`, `.py`, `.sh`, `.md`, `.json`
- Keywords: `implement`, `create`, `write tests`, `setup`, `configure`, `deploy`

**Default**: Phases without clear indicators are classified as "software" (conservative approach).

## Examples

### Basic Usage

```bash
# Execute mixed plan with automatic routing
/lean-implement .claude/specs/028_modal_logic/plans/001-modal-proofs.md

# Start from specific phase
/lean-implement plan.md 3

# Preview classification without executing
/lean-implement plan.md --dry-run
```

### Mode Filtering

```bash
# Execute only Lean phases (skip software)
/lean-implement plan.md --mode=lean-only

# Execute only software phases (skip Lean)
/lean-implement plan.md --mode=software-only
```

### Iteration Control

```bash
# Allow more iterations for complex plans
/lean-implement plan.md --max-iterations=10

# Lower context threshold for earlier checkpoints
/lean-implement plan.md --context-threshold=80
```

## Plan Format

Plans should use standard phase format with optional `lean_file:` metadata:

```markdown
# Modal Logic Implementation Plan

## Metadata
- **Date**: 2025-12-04
- **Feature**: Modal Logic Formalization
- **Status**: [NOT STARTED]

## Implementation Phases

### Phase 1: Prove K Axiom [NOT STARTED]
lean_file: /home/user/project/Modal.lean

**Objective**: Prove the K axiom of modal logic

Tasks:
- [ ] Define modal operators
- [ ] Prove theorem_K using intro/apply tactics

### Phase 2: Create Test Harness [NOT STARTED]

**Objective**: Build test infrastructure for proof verification

Tasks:
- [ ] Create test_modal_proofs.py
- [ ] Add CI integration

### Phase 3: Prove T Axiom [NOT STARTED]
lean_file: /home/user/project/Modal.lean

**Objective**: Prove the T axiom (reflexivity)

Tasks:
- [ ] Prove theorem_T using decidability
```

## Routing Map

The command builds a routing map that tracks:
- Phase number
- Phase type (lean/software)
- Lean file path (for Lean phases)
- Implementer name (coordinator to invoke)

Example routing map (stored in workspace):
```
1:lean:/home/user/project/Modal.lean:lean-coordinator
2:software:none:implementer-coordinator
3:lean:/home/user/project/Modal.lean:lean-coordinator
```

The enhanced format includes the coordinator name for explicit routing and better diagnostics.

## Hard Barrier Pattern

The `/lean-implement` command uses a **hard barrier pattern** to enforce mandatory coordinator delegation and prevent implementation work from being performed directly by the orchestrator.

### Architecture

**Block 1b: Coordinator Routing [HARD BARRIER]**
- Determines coordinator name based on phase type
- Persists `COORDINATOR_NAME` to workflow state
- Invokes appropriate coordinator via Task tool (no conditionals)

**Block 1c: Verification Checkpoint [HARD BARRIER]**
- **MUST** validate summary file exists in summaries directory
- **MUST** validate summary file size ≥ 100 bytes
- **MUST** parse TASK_ERROR signals from coordinator
- **FAILS FAST** if coordinator did not create summary (delegation bypass detected)

### Error Messages

If the hard barrier detects delegation bypass:

```
ERROR: HARD BARRIER FAILED - Summary not created by lean-coordinator
Expected: Summary file in /path/to/summaries/
```

Enhanced diagnostics search alternate locations and provide detailed error context.

### Benefits

1. **Architectural Enforcement**: Runtime validation ensures delegation happens
2. **Clear Diagnostics**: Error messages include coordinator name and search results
3. **Fail-Fast Behavior**: Delegation failures detected immediately, not silently ignored
4. **Context Protection**: Prevents orchestrator context exhaustion from direct implementation work

## Coordinator Integration

### lean-coordinator

For Lean phases, the command invokes lean-coordinator with:
- `lean_file_path`: Extracted from phase metadata
- `plan_path`: Original plan file for progress tracking
- `max_attempts`: Default 3 for theorem proving
- `iteration`: Per-Lean-phase iteration counter

### implementer-coordinator

For software phases, the command invokes implementer-coordinator with:
- `plan_path`: Original plan file
- `continuation_context`: Previous iteration summary if continuing
- `iteration`: Per-software-phase iteration counter

## Hybrid Coordinator Architecture

The `/lean-implement` command uses a **dual coordinator architecture** that routes phases to domain-specific coordinators based on phase type (lean vs software). This enables optimized workflows for each domain while maintaining unified progress tracking.

### Coordinator Output Contract

Both coordinators return enhanced output signals with context-efficient fields:

**lean-coordinator Return Signal**:
```yaml
PROOF_COMPLETE:
  coordinator_type: "lean"
  summary_path: /path/to/summary.md
  summary_brief: "Completed Wave 1-2 (Phase 1,2) with 15 theorems. Context: 72%. Next: Continue Wave 3."
  phases_completed: [1, 2]
  theorem_count: 15
  work_remaining: Phase_3 Phase_4
  context_exhausted: false
  requires_continuation: true
```

**implementer-coordinator Return Signal**:
```yaml
IMPLEMENTATION_COMPLETE:
  coordinator_type: "software"
  summary_path: /path/to/summary.md
  summary_brief: "Completed Wave 1 (Phase 3,4) with 25 tasks. Context: 65%. Next: Continue Wave 2."
  phases_completed: [3, 4]
  phase_count: 2
  git_commits: [hash1, hash2]
  work_remaining: Phase_5 Phase_6
  context_exhausted: false
  requires_continuation: true
```

### Brief Summary Return Pattern

The command implements a **96% context reduction strategy** by parsing brief summaries from coordinator return signals instead of reading full summary files:

**Traditional Approach** (Context-Expensive):
```bash
# Read entire summary file (~2,000 tokens per iteration)
SUMMARY=$(cat "$SUMMARY_PATH")
```

**Brief Summary Approach** (Context-Efficient):
```bash
# Parse brief summary from return signal (~80 tokens)
SUMMARY_BRIEF=$(grep "^summary_brief:" "$RETURN_SIGNAL" | sed 's/^summary_brief:[[:space:]]*//')
COORDINATOR_TYPE=$(grep "^coordinator_type:" "$RETURN_SIGNAL")
PHASES_COMPLETED=$(grep "^phases_completed:" "$RETURN_SIGNAL")
```

**Context Reduction**: 80 tokens (return signal) vs 2,000 tokens (full summary) = **96% reduction**

### Benefits

1. **Domain-Specific Optimization**: Each coordinator uses specialized tools (lean-lsp-mcp for proofs, standard dev tools for software)
2. **Unified Metrics**: Aggregates theorems proven (lean) and git commits (software) in single completion report
3. **Context Preservation**: Brief summary pattern preserves orchestrator context window for implementation work
4. **Backward Compatibility**: Fallback parsing supports legacy summaries without new fields
5. **Parallel Execution**: Wave-based orchestration executes independent phases concurrently

## Progress Tracking

Both coordinators use checkbox utilities to track progress:

1. Phase marked `[IN PROGRESS]` when execution starts
2. Individual tasks marked `[x]` as completed
3. Phase marked `[COMPLETE]` when all tasks done
4. Plan metadata status updated to `[COMPLETE]` when all phases done

## Iteration Management

The command supports multi-iteration execution:

1. **Context Monitoring**: Tracks context usage percentage
2. **Checkpoint Creation**: Saves state when context threshold exceeded
3. **Continuation**: Resumes from checkpoint in next iteration
4. **Stuck Detection**: Halts if work remaining unchanged for 2 iterations

## Output Signals

### IMPLEMENTATION_COMPLETE

Emitted when all work is done:
```
IMPLEMENTATION_COMPLETE:
  plan_file: /path/to/plan.md
  topic_path: /path/to/topic
  summary_path: /path/to/summary.md
  total_phases: 5
  lean_phases_completed: 2
  software_phases_completed: 3
  theorems_proven: 10
  execution_mode: auto
  iterations_used: 2
  work_remaining: 0
```

## Context Management

The `/lean-implement` command includes advanced context management features to handle long-running workflows gracefully.

### Context Aggregation

The command tracks context usage across iterations and saves checkpoints when thresholds are exceeded:

1. **Context Monitoring**: Coordinators report `context_usage_percent` in each summary
2. **Threshold Checking**: Compares usage against `CONTEXT_THRESHOLD` (default: 90%)
3. **Checkpoint Creation**: Automatically saves workflow state when threshold exceeded
4. **Graceful Halt**: Stops execution with clear message and checkpoint path

### Configuration Options

Set environment variables or command-line flags:

```bash
# Set custom context threshold (default: 90)
/lean-implement plan.md --context-threshold=80

# Increase max iterations (default: 5)
/lean-implement plan.md --max-iterations=10
```

### Checkpoint Resume

When a checkpoint is saved due to context threshold:

```bash
# Review checkpoint
cat ~/.claude/data/checkpoints/lean_implement_<workflow_id>.json

# Resume from last phase
/lean-implement plan.md <last_phase_number>
```

The checkpoint contains:
- Plan path and topic path
- Current iteration count
- Work remaining (phase list)
- Context usage percentage
- Halt reason: `context_threshold_exceeded`

### Context Reduction Metrics

The brief summary parsing pattern provides significant context savings:

| Approach | Tokens/Iteration | 5 Iterations | Reduction |
|----------|------------------|--------------|-----------|
| Full file parsing | 2,000 | 10,000 | - |
| Brief summary parsing | 80 | 400 | 96% |

**Cumulative Savings**: 9,600 tokens saved per 5-iteration workflow

## Troubleshooting

### Continuation Plans

**Problem**: Phase number extraction fails with non-contiguous phase numbers.

**Example**: Plan with phases 5, 7, 9 (continuation from previous implementation).

**Root Cause**: Legacy code used `seq 1 $TOTAL_PHASES` which assumes contiguous numbering.

**Solution**: The command now extracts actual phase numbers from plan file:
```bash
# Direct grep extraction handles non-contiguous phases
PHASE_NUMBERS=$(grep -oE "^### Phase ([0-9]+):" "$PLAN_FILE" | grep -oE "[0-9]+" | sort -n)
```

This enables continuation plans where only incomplete phases remain.

### Context Threshold Exceeded

**Problem**: Command halts with "Context threshold exceeded - checkpoint saved".

**Meaning**: The workflow accumulated high context usage and saved state to prevent exhaustion.

**Resolution**:
1. Review checkpoint: `cat ~/.claude/data/checkpoints/lean_implement_*.json`
2. Check work remaining in checkpoint
3. Resume from last phase: `/lean-implement plan.md <phase_num>`
4. Or increase threshold: `/lean-implement plan.md --context-threshold=95`

### Hard Barrier Failures

**Problem**: `HARD BARRIER FAILED - Summary not created by <coordinator-name>`

**Root Cause**: The coordinator did not create a summary file, indicating delegation bypass or coordinator failure.

**Diagnostic Steps**:
1. Check the alternate location search results in error output
2. Review coordinator output for TASK_ERROR signals
3. Check error log: `/errors --command /lean-implement --since 1h`
4. Verify summaries directory is writable

**Solution**:
- If coordinator crashed: Fix the underlying issue and retry
- If summary in wrong location: Check coordinator implementation
- If no summary at all: Coordinator delegation failed (architectural bug)

### Phase Misclassified

**Problem**: A phase is routed to the wrong coordinator.

**Solution**: Add explicit `implementer:` field for precise routing:
```markdown
### Phase N: Name [NOT STARTED]
implementer: lean
lean_file: /path/to/file.lean
```

Or use `lean_file:` metadata for backward compatibility:
```markdown
### Phase N: Name [NOT STARTED]
lean_file: /path/to/file.lean
```

### Lean Coordinator Fails

**Problem**: lean-coordinator returns error.

**Possible Causes**:
1. lean-lsp-mcp not installed: `uvx --from lean-lsp-mcp --help`
2. Lean file not found: Check `lean_file:` path is correct
3. Not a Lean project: Verify `lakefile.toml` or `lakefile.lean` exists

### Software Coordinator Fails

**Problem**: implementer-coordinator returns error.

**Possible Causes**:
1. Plan format invalid: Check phase headings
2. Summaries directory not writable
3. Previous iteration checkpoint corrupted

### Stuck Detection Triggered

**Problem**: Command halts with "stuck detected" error.

**Solution**:
1. Check summary for incomplete work
2. Manually complete blocking tasks
3. Restart from checkpoint

### Debug Logging

Check workflow debug log for detailed diagnostics:
```bash
cat ~/.claude/tmp/workflow_debug.log
```

Check error log for structured errors:
```bash
/errors --command /lean-implement --since 1h
```

## Related Commands

- `/lean-build`: Lean-only theorem proving (no software phases)
- `/implement`: Software-only implementation (no Lean phases)
- `/lean-plan`: Create Lean-specific plans with proof strategies
- `/create-plan`: Create general implementation plans
- `/test`: Run tests after implementation

## Architecture

```
/lean-implement
    |
    +-- Block 1a: Setup & State Initialization
    |
    +-- Block 1a-classify: Phase Classification
    |       |
    |       +-- detect_phase_type() [Tier 1: lean_file metadata]
    |       +-- detect_phase_type() [Tier 2: keyword/extension]
    |       +-- build_routing_map()
    |
    +-- Block 1b: Coordinator Routing [HARD BARRIER]
    |       |
    |       +-- If lean: Task -> lean-coordinator (Opus 4.5)
    |       +-- If software: Task -> implementer-coordinator (Haiku 4.5)
    |
    +-- Block 1c: Verification & Continuation Decision
    |       |
    |       +-- Validate summary exists
    |       +-- Parse work_remaining, context_exhausted
    |       +-- Iteration loop or proceed to completion
    |
    +-- Block 1d: Phase Marker Recovery
    |       |
    |       +-- Validate [COMPLETE] markers
    |       +-- Recover missing markers
    |
    +-- Block 2: Completion & Summary
            |
            +-- Aggregate metrics
            +-- Display console summary
            +-- Emit IMPLEMENTATION_COMPLETE
```

## Technical Details

### Workflow Type

The command uses the `implement-only` workflow type for state machine orchestration. This workflow type:
- Implements all phases without running test suites
- Terminates at `STATE_IMPLEMENT` (does not transition to testing/debugging)
- Shares workflow semantics with `/implement` command
- Is independent of phase routing (Lean vs software classification is an implementation detail)

The hybrid routing logic (lean-coordinator vs implementer-coordinator) operates within the implementation scope and does not require a separate workflow type enum.
