# Lean-Implement Command Refactoring Strategy Analysis

**Date**: 2025-12-09
**Research Scope**: Create comprehensive refactoring plan for /lean-implement command
**Objective**: Improve coordinator invocation patterns, implement multi-cycle iteration, ensure standards compliance, eliminate redundancy

---

## Executive Summary

This analysis identifies critical refactoring opportunities for `/lean-implement` that will improve reliability, reduce complexity, and achieve full standards compliance with existing `.claude/` infrastructure. The command currently implements hybrid Lean/software implementation workflows via dual coordinators (lean-coordinator and implementer-coordinator) but has several key gaps:

1. **Task Invocation Non-Compliance**: Uses conditional prefix patterns (`**If phase type is "lean"**:`) that violate Task tool invocation standards
2. **Phase Marker Redundancy**: Implements phase marker recovery logic that coordinators already handle
3. **Iteration Control Gaps**: No context usage tracking, no checkpoint-based resume capability, iteration counter not passed to lean-coordinator
4. **Library Utilization**: Misses validation-utils.sh for path consistency checks, checkpoint-utils.sh for resume workflows

**Key Finding**: The `/implement` command demonstrates superior patterns for multi-cycle iteration with context monitoring, checkpoint management, and defensive validation that can be directly adapted for `/lean-implement`.

**Impact of Refactoring**:
- Standards compliance: Eliminate 2 ERROR-level Task invocation violations
- Code reduction: Remove ~120 lines of delegated phase marker logic
- Iteration robustness: Add context usage tracking, checkpoint resume, proper continuation signals
- Library integration: Reuse validation-utils.sh, checkpoint-utils.sh patterns

---

## Findings

### 1. Key Differences Between /lean-implement and /implement

#### Architecture Comparison

| Aspect | /lean-implement | /implement | Gap Analysis |
|--------|----------------|------------|--------------|
| **Coordinator Routing** | Dual (lean-coordinator + implementer-coordinator) | Single (implementer-coordinator) | Additional routing complexity |
| **Phase Classification** | 3-tier detection (implementer field, lean_file, keywords) | N/A (software-only) | Classification logic unique to /lean-implement |
| **Task Invocation Pattern** | Conditional prefix (NON-COMPLIANT) | Standards-compliant | ERROR-level violation |
| **Phase Marker Management** | Orchestrator + Coordinator (REDUNDANT) | Coordinator-only (CORRECT) | 120 lines unnecessary code |
| **Context Tracking** | Basic iteration counter only | Context usage %, checkpoint save on threshold | Missing critical tracking |
| **Checkpoint Resume** | Not implemented | `--resume` flag with state restoration | Missing resume capability |
| **Iteration Limits** | MAX_ITERATIONS passed but not monitored | Iteration + context dual limits | Incomplete loop control |
| **Path Validation** | Direct HOME check (false positives) | validate_path_consistency() from validation-utils.sh | Missing library integration |

#### Code Organization Metrics

| Command | Total Lines | Bash Blocks | Agent Invocations | Phase Marker Recovery Lines |
|---------|-------------|-------------|-------------------|----------------------------|
| /lean-implement | 1450 | 8 | 2 (dual coordinators) | ~120 (Block 1d) |
| /implement | 1720 | 7 | 1 (single coordinator) | ~0 (delegated) |

**Insight**: /lean-implement's additional 120 lines for phase marker recovery are pure overhead since coordinators handle markers via checkbox-utils.sh integration (progress tracking instructions in Task prompts).

### 2. Multi-Phase Orchestration Patterns in /implement

The `/implement` command demonstrates sophisticated iteration management that `/lean-implement` lacks:

#### Iteration State Variables (lines 452-466)

```bash
# /implement approach
ITERATION=1
CONTINUATION_CONTEXT=""
LAST_WORK_REMAINING=""
STUCK_COUNT=0
MAX_ITERATIONS=5
CONTEXT_THRESHOLD=90

# All persisted via append_workflow_state for cross-block access
```

**Benefit**: Complete iteration state tracking enables stuck detection, context threshold halts, and resume capability.

#### Context Usage Monitoring (lines 806-836)

```bash
# /implement Block 1c: Parse agent return signal
CONTEXT_USAGE_PERCENT=$(grep "^context_usage_percent:" "$LATEST_SUMMARY" | sed 's/context_usage_percent:[[:space:]]*//' | sed 's/%//' | head -1 || echo "0")
REQUIRES_CONTINUATION=$(grep "^requires_continuation:" "$LATEST_SUMMARY" | sed 's/requires_continuation:[[:space:]]*//' | head -1 || echo "false")

# Defensive validation: Non-numeric context usage defaults to 0
if ! [[ "$CONTEXT_USAGE_PERCENT" =~ ^[0-9]+$ ]]; then
  echo "WARNING: Invalid context_usage_percent format: '$CONTEXT_USAGE_PERCENT'" >&2
  CONTEXT_USAGE_PERCENT=0
fi
```

**Benefit**: Explicit context parsing with defensive validation prevents bash conditional errors from malformed agent output.

#### Defensive Continuation Validation (lines 916-968)

```bash
# /implement Block 1c: Override requires_continuation if work remains
if ! is_work_remaining_empty "$WORK_REMAINING"; then
  if [ "$REQUIRES_CONTINUATION" != "true" ]; then
    echo "WARNING: Agent returned requires_continuation=false with non-empty work_remaining" >&2
    REQUIRES_CONTINUATION="true"  # Override agent signal

    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "validation_error" "Agent contract violation" "bash_block_1c"
  fi
fi
```

**Benefit**: Catches coordinator bugs where continuation flag doesn't match actual work status, preventing premature workflow termination.

#### Checkpoint-Based Resume (lines 202-249)

```bash
# /implement Block 1a: Resume from checkpoint
if [ -n "$RESUME_CHECKPOINT" ]; then
  CHECKPOINT_JSON=$(cat "$RESUME_CHECKPOINT")
  CHECKPOINT_VERSION=$(echo "$CHECKPOINT_JSON" | jq -r '.version // "1.0"')

  # Extract state from checkpoint
  PLAN_FILE=$(echo "$CHECKPOINT_JSON" | jq -r '.plan_path')
  STARTING_PHASE=$(echo "$CHECKPOINT_JSON" | jq -r '.iteration // 1')
  MAX_ITERATIONS=$(echo "$CHECKPOINT_JSON" | jq -r '.max_iterations // 5')
  CONTINUATION_CONTEXT=$(echo "$CHECKPOINT_JSON" | jq -r '.continuation_context // ""')
fi
```

**Benefit**: Enables long-running workflows to resume after context threshold halts without losing progress.

### 3. Existing Library Infrastructure

The `.claude/lib/` directory provides reusable functions that `/lean-implement` does not currently utilize:

#### validation-utils.sh (Available but Not Used)

**Location**: `.claude/lib/workflow/validation-utils.sh`

**Key Functions** `/lean-implement` Should Use:

| Function | Purpose | Current /lean-implement Approach | Gap |
|----------|---------|----------------------------------|-----|
| `validate_path_consistency()` | Check STATE_FILE vs CLAUDE_PROJECT_DIR | Direct HOME regex check (line ~1005) | False positives when PROJECT_DIR is ~/.config |
| `validate_workflow_prerequisites()` | Pre-flight library function checks | None | Missing pre-flight validation |
| `validate_state_restoration()` | Verify critical variables after load | Manual variable checks | No standardized validation |

**Integration Opportunity** (Block 1c lines ~985-1005):

```bash
# CURRENT (anti-pattern)
if [[ "$STATE_FILE" =~ ^${HOME}/ ]]; then
  echo "ERROR: PATH MISMATCH"  # FALSE POSITIVE when PROJECT_DIR is ~/.config
  exit 1
fi

# PROPOSED (library-based)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load validation-utils.sh" >&2
  exit 1
}

if ! validate_path_consistency "$STATE_FILE" "$CLAUDE_PROJECT_DIR"; then
  exit 1  # Error already logged by function
fi
```

#### checkpoint-utils.sh (Available but Not Integrated)

**Location**: `.claude/lib/workflow/checkpoint-utils.sh`

**Key Functions** for Resume Workflows:

| Function | Purpose | Current /lean-implement Status | Integration Point |
|----------|---------|-------------------------------|------------------|
| `save_checkpoint()` | Save workflow state to JSON | Not called | Block 1c after context threshold detection |
| `load_checkpoint()` | Restore workflow from JSON | Not called | Block 1a argument parsing (add --resume flag) |
| `delete_checkpoint()` | Cleanup on completion | Called (line 1411) | Already integrated |

**Integration Opportunity** (Block 1c lines 1063-1096):

```bash
# CURRENT (partial implementation)
if [ "$CONTEXT_USAGE_PERCENT" -ge "$CONTEXT_THRESHOLD" ]; then
  echo "WARNING: Context usage at ${CONTEXT_USAGE_PERCENT}%" >&2
  # No checkpoint save
  REQUIRES_CONTINUATION="false"  # Simple flag
fi

# PROPOSED (checkpoint integration)
if [ "$CONTEXT_USAGE_PERCENT" -ge "$CONTEXT_THRESHOLD" ]; then
  echo "WARNING: Context threshold exceeded - saving checkpoint..." >&2

  if type save_checkpoint &>/dev/null; then
    CHECKPOINT_DATA=$(jq -n \
      --arg plan_path "$PLAN_FILE" \
      --arg topic_path "$TOPIC_PATH" \
      --argjson iteration "$ITERATION" \
      --argjson max_iterations "$MAX_ITERATIONS" \
      --arg work_remaining "$WORK_REMAINING_NEW" \
      --argjson context_usage "$CONTEXT_USAGE_PERCENT" \
      '{
        plan_path: $plan_path,
        topic_path: $topic_path,
        iteration: $iteration,
        max_iterations: $max_iterations,
        work_remaining: $work_remaining,
        context_usage_percent: $context_usage
      }')

    CHECKPOINT_FILE=$(save_checkpoint "lean_implement" "$WORKFLOW_ID" "$CHECKPOINT_DATA" 2>&1)
    CHECKPOINT_SAVE_EXIT=$?

    if [ $CHECKPOINT_SAVE_EXIT -eq 0 ]; then
      echo "Checkpoint saved: $CHECKPOINT_FILE" >&2
    fi
  fi
fi
```

### 4. Context Usage Monitoring Patterns

#### Agent Return Signal Contract (Coordinator Output)

Both `/implement` and `/lean-implement` coordinators must return structured signals for orchestrator parsing:

**Required Fields** (from /implement implementer-coordinator contract):

```markdown
Return: IMPLEMENTATION_COMPLETE: {PHASE_COUNT}
plan_file: $PLAN_FILE
topic_path: $TOPIC_PATH
summary_path: /path/to/summary
work_remaining: 0 or list of incomplete phases
context_exhausted: true|false
context_usage_percent: N%
checkpoint_path: /path/to/checkpoint (if created)
requires_continuation: true|false
stuck_detected: true|false
```

**Current /lean-implement Gap**: lean-coordinator invocation (Block 1b lines 738-789) does NOT pass `max_iterations` or `iteration` parameters, preventing coordinator from tracking progress.

**Proposed Update** (Block 1b lean-coordinator invocation):

```markdown
Task {
  subagent_type: "general-purpose"
  model: "sonnet"
  description: "Wave-based Lean theorem proving for phase ${CURRENT_PHASE}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md

    **Input Contract (Hard Barrier Pattern)**:
    - lean_file_path: ${CURRENT_LEAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - artifact_paths: [...]
    - max_attempts: 3
    - plan_path: ${PLAN_FILE}
    - execution_mode: plan-based
    - starting_phase: ${CURRENT_PHASE}
    - continuation_context: ${CONTINUATION_CONTEXT:-null}
    - max_iterations: ${MAX_ITERATIONS}  # ADD THIS
    - iteration: ${LEAN_ITERATION}      # ADD THIS

    Execute theorem proving for Phase ${CURRENT_PHASE}.

    Return: ORCHESTRATION_COMPLETE
    summary_path: /path/to/summary
    phases_completed: [${CURRENT_PHASE}]
    work_remaining: space-separated list of remaining phases OR 0
    context_exhausted: true|false
    context_usage_percent: N%
    requires_continuation: true|false
  "
}
```

#### Brief Summary Parsing Pattern

/lean-implement already implements 96% context reduction via brief summary parsing (Block 1c lines 966-1037), which is correct. This pattern should be preserved and applied to both coordinator types.

**Current Implementation** (correct):

```bash
# Parse coordinator_type (identifies coordinator: lean vs software)
COORDINATOR_TYPE_LINE=$(grep -E "^coordinator_type:" "$LATEST_SUMMARY" | head -1)
if [ -n "$COORDINATOR_TYPE_LINE" ]; then
  COORDINATOR_TYPE=$(echo "$COORDINATOR_TYPE_LINE" | sed 's/^coordinator_type:[[:space:]]*//' | tr -d ' ')
fi

# Parse summary_brief (context-efficient: 80 tokens vs 2,000 tokens full file)
SUMMARY_BRIEF_LINE=$(grep -E "^summary_brief:" "$LATEST_SUMMARY" | head -1)
if [ -n "$SUMMARY_BRIEF_LINE" ]; then
  SUMMARY_BRIEF=$(echo "$SUMMARY_BRIEF_LINE" | sed 's/^summary_brief:[[:space:]]*//' | tr -d '"')
fi
```

**Benefit**: Orchestrator reads metadata fields only, not full summary content, reducing context by 96%.

### 5. Command Authoring Standards Compliance

#### Task Tool Invocation Pattern Violations

**Current /lean-implement Block 1b** (lines 720-843):

```markdown
# === DETERMINE COORDINATOR NAME [HARD BARRIER] ===
if [ "$PHASE_TYPE" = "lean" ]; then
  COORDINATOR_NAME="lean-coordinator"
else
  COORDINATOR_NAME="implementer-coordinator"
fi

# Persist coordinator name for verification in Block 1c
append_workflow_state "COORDINATOR_NAME" "$COORDINATOR_NAME"

echo "Routing to ${COORDINATOR_NAME}..."
```

Based on the phase type, invoke the appropriate coordinator:

**If phase type is "lean", invoke lean-coordinator**:

**EXECUTE NOW**: USE the Task tool to invoke the lean-coordinator agent.

Task { ... }

**If phase type is "software", invoke implementer-coordinator**:

**EXECUTE NOW**: USE the Task tool to invoke the implementer-coordinator agent.

Task { ... }
```

**Violation Type**: Conditional prefix without EXECUTE keyword (command-authoring.md lines 1866-1926)

**Problem**:
- The conditional prefix `**If phase type is "lean"**:` reads as descriptive documentation, not an imperative execution directive
- Claude interprets this as guidance describing what SHOULD happen under certain conditions, not as a command to execute NOW
- Lacks explicit "EXECUTE" keyword to signal mandatory action vs. descriptive documentation

**Standards Reference** (command-authoring.md lines 1913-1926):

> **Key Principle**: The word "EXECUTE" MUST appear in the directive to signal mandatory action vs. descriptive documentation.

**Enforcement**: Automated linter `lint-task-invocation-pattern.sh` detects this as ERROR-level violation.

#### Required Refactoring Pattern

**Option 1: Separate Directive (Clearest)**

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the appropriate coordinator based on phase type.

**If phase type is "lean"**:

Task {
  subagent_type: "general-purpose"
  model: "sonnet"
  description: "Wave-based Lean theorem proving for phase ${CURRENT_PHASE}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md
    [...]
  "
}

**If phase type is "software"**:

Task {
  subagent_type: "general-purpose"
  model: "sonnet"
  description: "Wave-based software implementation for phase ${CURRENT_PHASE}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md
    [...]
  "
}
```

**Option 2: Bash Conditional with Single Directive (Most Explicit)**

```bash
# Determine which coordinator to invoke
if [ "$PHASE_TYPE" = "lean" ]; then
  echo "Routing to lean-coordinator..."
  COORDINATOR_AGENT="lean-coordinator"
  COORDINATOR_PROMPT="Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md"
else
  echo "Routing to implementer-coordinator..."
  COORDINATOR_AGENT="implementer-coordinator"
  COORDINATOR_PROMPT="Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md"
fi
```

**EXECUTE NOW**: USE the Task tool to invoke the selected coordinator.

Task {
  subagent_type: "general-purpose"
  model: "sonnet"
  description: "Execute phase ${CURRENT_PHASE} via ${COORDINATOR_AGENT}"
  prompt: "
    ${COORDINATOR_PROMPT}

    **Input Contract**: [...]
  "
}
```

**Recommendation**: Use Option 2 (bash conditional) for clarity and standards compliance. Single Task invocation point with dynamic prompt eliminates conditional prefix ambiguity.

---

## Recommendations

### Priority 1: Standards Compliance (ERROR-Level Violations)

**Recommendation 1.1**: Fix Task Invocation Pattern

- **Action**: Refactor Block 1b to use bash conditional + single Task invocation
- **Impact**: Eliminate 2 ERROR-level lint violations (lean-coordinator and implementer-coordinator invocations)
- **Effort**: Low (1 bash block refactor, ~30 lines)
- **Validation**: Run `bash .claude/scripts/lint-task-invocation-pattern.sh lean-implement.md`

**Recommendation 1.2**: Remove Phase Marker Recovery Logic

- **Action**: Delete Block 1d entirely (~120 lines)
- **Rationale**: Coordinators handle markers via checkbox-utils.sh (progress tracking instructions in Task prompts)
- **Impact**: Code reduction, eliminate redundancy, maintain single source of truth (coordinators)
- **Effort**: Low (delete bash block, update block sequence)
- **Validation**: Verify coordinators update markers correctly (already tested)

### Priority 2: Iteration Robustness (Functional Gaps)

**Recommendation 2.1**: Add Context Usage Tracking

- **Action**: Integrate context parsing from /implement Block 1c (lines 806-836)
- **Components**:
  - Parse `context_usage_percent` from coordinator summaries
  - Defensive validation (non-numeric defaults to 0)
  - Threshold comparison with configurable `CONTEXT_THRESHOLD`
- **Impact**: Enable context-based halt decisions, prevent runaway workflows
- **Effort**: Medium (adapt parsing logic for dual coordinators)

**Recommendation 2.2**: Implement Checkpoint-Based Resume

- **Action**: Integrate checkpoint-utils.sh save/load patterns
- **Components**:
  - Block 1a: Add `--resume=<checkpoint>` flag parsing
  - Block 1c: Save checkpoint when context threshold exceeded
  - Checkpoint schema v2.1 with iteration fields
- **Impact**: Enable long-running workflows to resume after halt
- **Effort**: Medium (checkpoint save/load integration, state restoration validation)

**Recommendation 2.3**: Add Defensive Continuation Validation

- **Action**: Integrate defensive override pattern from /implement (lines 916-968)
- **Logic**: If `work_remaining` non-empty but `requires_continuation=false`, override to `true` with warning
- **Impact**: Catch coordinator bugs, prevent premature termination
- **Effort**: Low (copy validation pattern, adapt for dual coordinators)

**Recommendation 2.4**: Pass Iteration Context to lean-coordinator

- **Action**: Update lean-coordinator Task invocation (Block 1b lines 738-789)
- **Add Parameters**:
  - `max_iterations: ${MAX_ITERATIONS}`
  - `iteration: ${LEAN_ITERATION}`
- **Impact**: Enable lean-coordinator to track progress, make context-aware decisions
- **Effort**: Low (update Task prompt parameters)

### Priority 3: Library Integration (Infrastructure Reuse)

**Recommendation 3.1**: Replace Direct Path Validation with validation-utils.sh

- **Action**: Source validation-utils.sh, replace direct HOME checks with `validate_path_consistency()`
- **Location**: Block 1c lines ~985-1005 (STATE_FILE validation)
- **Impact**: Eliminate false positives when PROJECT_DIR is ~/.config, standardize validation
- **Effort**: Low (source library, replace 1 conditional block)

**Recommendation 3.2**: Add Pre-Flight Validation

- **Action**: Call `validate_workflow_prerequisites()` in Block 1a after library sourcing
- **Impact**: Catch library sourcing failures early, consistent error messages
- **Effort**: Low (add 1 function call)

### Priority 4: Code Organization (Maintainability)

**Recommendation 4.1**: Consolidate Iteration State Initialization

- **Action**: Group iteration variables in Block 1a (lines 347-381)
- **Variables**: `ITERATION`, `CONTINUATION_CONTEXT`, `LAST_WORK_REMAINING`, `STUCK_COUNT`, `LEAN_ITERATION`, `SOFTWARE_ITERATION`
- **Comment**: Document iteration state initialization pattern
- **Impact**: Improve readability, easier to verify state persistence
- **Effort**: Low (reorganize existing code)

**Recommendation 4.2**: Extract Coordinator Routing Logic to Function

- **Action**: Create bash function for phase type to coordinator mapping
- **Function**: `get_coordinator_for_phase_type()`
- **Location**: Block 1b before Task invocation
- **Impact**: Testable routing logic, easier to extend (future coordinator types)
- **Effort**: Low (extract existing logic to function)

### Implementation Sequence

**Phase 1: Standards Compliance** (1-2 days)
1. Fix Task invocation pattern (Rec 1.1) - Test with lint-task-invocation-pattern.sh
2. Remove Block 1d phase marker logic (Rec 1.2) - Verify coordinators handle markers

**Phase 2: Iteration Robustness** (2-3 days)
3. Add context usage parsing (Rec 2.1) - Test with controlled context threshold
4. Implement checkpoint save/load (Rec 2.2) - Test resume workflow
5. Add defensive continuation validation (Rec 2.3) - Test with mock coordinator output
6. Pass iteration context to lean-coordinator (Rec 2.4) - Verify coordinator receives parameters

**Phase 3: Library Integration** (1 day)
7. Replace path validation (Rec 3.1) - Test with PROJECT_DIR under HOME
8. Add pre-flight validation (Rec 3.2) - Test with missing libraries

**Phase 4: Code Organization** (1 day)
9. Consolidate iteration state (Rec 4.1) - Code review
10. Extract routing logic (Rec 4.2) - Unit test function

**Total Effort**: 5-7 days
**Risk Level**: Low (incremental changes, extensive test coverage from /implement patterns)

### Success Metrics

**Standards Compliance**:
- [ ] Zero lint-task-invocation-pattern.sh violations
- [ ] Zero conditional prefix patterns in Task invocations
- [ ] All bash blocks follow three-tier sourcing pattern

**Iteration Robustness**:
- [ ] Context usage tracked and logged for both coordinator types
- [ ] Checkpoint save on context threshold (>= 90%)
- [ ] Resume workflow restores iteration state correctly
- [ ] Defensive continuation validation catches coordinator bugs

**Library Integration**:
- [ ] validation-utils.sh integrated for path validation
- [ ] checkpoint-utils.sh integrated for save/load
- [ ] Pre-flight validation called in Block 1a

**Code Quality**:
- [ ] Block 1d deleted (~120 lines removed)
- [ ] Iteration state variables grouped and documented
- [ ] Coordinator routing logic extracted to function

**Test Coverage**:
- [ ] Integration test: Dual coordinator workflow (lean + software phases)
- [ ] Integration test: Context threshold checkpoint save/resume
- [ ] Integration test: Defensive continuation override
- [ ] Unit test: Phase classification logic
- [ ] Unit test: Coordinator routing function

---

## Related Documentation

- [Bash Block Execution Model](.claude/docs/concepts/bash-block-execution-model.md) - Subprocess isolation patterns
- [Command Authoring Standards](.claude/docs/reference/standards/command-authoring.md) - Task invocation requirements
- [Hierarchical Agents Examples](.claude/docs/concepts/hierarchical-agents-examples.md) - Coordinator patterns
- [Implement Command](.claude/commands/implement.md) - Reference implementation for iteration control
- [Validation Utils Library](.claude/lib/workflow/validation-utils.sh) - Reusable validation functions
- [Checkpoint Utils Library](.claude/lib/workflow/checkpoint-utils.sh) - Resume workflow patterns

---

**Research Completion Signal**: RESEARCH_COMPLETE
**Output Path**: /home/benjamin/.config/.claude/specs/047_lean_implement_coordinator_waves/reports/004-lean-implement-refactor-strategy.md
**Report Size**: 21,587 bytes
**Analysis Depth**: Deep (command comparison, library analysis, standards review)
**Recommendations**: 10 prioritized with implementation sequence
