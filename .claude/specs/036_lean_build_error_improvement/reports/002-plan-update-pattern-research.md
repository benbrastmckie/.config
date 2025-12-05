# Plan Update Pattern Research for /lean-build Enhancement

## Research Date
2025-12-03

## Research Topic
Analysis of how /implement command instructs its implementer subagents to keep plan phases updated during execution, and how this pattern should be applied to /lean-build command for lean-coordinator and lean-implementer subagents.

## Executive Summary

The /implement command has a well-established pattern for instructing its implementer-coordinator and implementation-executor subagents to update plan file status markers in real-time as phases progress. This research documents:

1. The specific instructions and patterns used in /implement
2. The checkbox-utils.sh library functions utilized
3. The delegation pattern from command → coordinator → executor
4. How this should be adapted for /lean-build → lean-coordinator → lean-implementer

**Key Finding**: /implement uses explicit "Progress Tracking Instructions" in the Task invocation prompt that tells subagents to source checkbox-utils.sh and call specific marker functions before and after each phase. This pattern is missing from /lean-build's Task invocations to lean-coordinator.

## Research Objectives

1. **Primary**: Identify the exact pattern /implement uses to instruct its subagents to update plan markers
2. **Secondary**: Document the checkbox-utils.sh functions used for progress tracking
3. **Tertiary**: Determine how to adapt this pattern for /lean-build's architecture
4. **Validation**: Ensure the pattern supports both file-based and plan-based modes

## Findings

### Finding 1: /implement Task Invocation Pattern

**Source**: `/home/benjamin/.config/.claude/commands/implement.md` lines 538-543

The /implement command includes explicit "Progress Tracking Instructions" in its Task invocation to implementer-coordinator:

```markdown
Progress Tracking Instructions:
- Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
- Before starting each phase: add_in_progress_marker '$PLAN_FILE' <phase_num>
- After completing each phase: mark_phase_complete '$PLAN_FILE' <phase_num> && add_complete_marker '$PLAN_FILE' <phase_num>
- This creates visible progress: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]
```

**Analysis**:
- These instructions are passed directly in the Task prompt (lines 507-566 in implement.md)
- The instructions are clear, imperative directives
- They specify the exact library to source
- They specify the exact functions to call and when
- They explain the expected status progression
- This pattern appears in BOTH the initial invocation (Block 1b) and the iteration loop re-invocation (lines 1005-1009)

### Finding 2: Implementer-Coordinator Agent Compliance

**Source**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` lines 337-349

The implementer-coordinator agent's behavioral guidelines acknowledge these instructions but note that actual marker updates are optional:

```markdown
3. **Validate Phase Markers** (Optional):
   - Check if phase heading has [COMPLETE] marker for successful phases
   - If phase_marker_updated: false, log warning but do not fail
   - Trust Block 1d recovery in /implement command to fix missing markers
```

**Key Insight**: The coordinator treats progress markers as OPTIONAL because:
1. Block 1d in /implement performs recovery for missing markers
2. The verification block (Block 1c) validates summary creation, not markers
3. Missing markers are non-fatal warnings, not errors

This "defensive orchestration" pattern means the command itself has recovery mechanisms, so subagent failures don't break the workflow.

### Finding 3: Lean-Implementer Already Has Progress Tracking

**Source**: `/home/benjamin/.config/.claude/agents/lean-implementer.md` lines 44-48 and 619-642

The lean-implementer agent ALREADY has progress tracking capability documented:

```markdown
### 6. Real-Time Progress Tracking
- Mark phases [IN PROGRESS] at start of theorem proving
- Update markers to [COMPLETE] after successful proof completion
- Enable real-time progress visibility via plan file inspection
- Gracefully degrade if progress tracking unavailable (non-fatal)
```

And there's a complete STEP 0 and STEP 9 for progress tracking initialization and completion.

**Critical Discovery**: The lean-implementer agent has full support for progress tracking, but it's not being triggered because:
1. The /lean-build command doesn't pass progress tracking instructions in the Task invocation
2. The lean-coordinator doesn't forward these instructions to lean-implementer
3. The current invocation pattern in lean-build.md (lines 378-417) lacks the "Progress Tracking Instructions" section

### Finding 4: Checkbox-Utils.sh Function Reference

**Pattern Used in /implement**:

| Function | Purpose | When Called |
|----------|---------|-------------|
| `add_not_started_markers` | Add [NOT STARTED] to phases lacking status | Once on legacy plan detection |
| `add_in_progress_marker` | Mark phase as [IN PROGRESS] | Before phase execution begins |
| `mark_phase_complete` | Mark all tasks [x] in phase | After phase execution completes |
| `add_complete_marker` | Add [COMPLETE] to phase heading | After phase execution completes |
| `update_plan_status` | Update plan metadata status field | At workflow start and completion |
| `verify_phase_complete` | Check if all tasks [x] in phase | During recovery (Block 1d) |
| `check_all_phases_complete` | Check if all phases have [COMPLETE] | During recovery (Block 1d) |

**Key Pattern**:
- `add_in_progress_marker` is called ONCE per phase at START
- `mark_phase_complete && add_complete_marker` is called ONCE per phase at END
- This creates atomic transitions: [NOT STARTED] → [IN PROGRESS] → [COMPLETE]

### Finding 5: /lean-build Current State

**Source**: `/home/benjamin/.config/.claude/commands/lean-build.md` lines 378-417

The current lean-coordinator Task invocation LACKS progress tracking instructions:

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Wave-based Lean theorem proving orchestration for ${LEAN_FILE}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md

    **Input Contract**:
    - lean_file_path: ${LEAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - artifact_paths: ...
    - max_attempts: ${MAX_ATTEMPTS}
    - plan_path: ${PLAN_FILE:-}
    - execution_mode: ${EXECUTION_MODE}
    - starting_phase: ${STARTING_PHASE:-1}
    - continuation_context: ${CONTINUATION_CONTEXT:-null}
    - max_iterations: ${MAX_ITERATIONS}

    Execute wave-based proof orchestration for mode: ${EXECUTION_MODE}

    **CRITICAL**: You MUST create a proof summary in ${SUMMARIES_DIR}/
    The orchestrator will validate the summary exists after you return.

    Return: ORCHESTRATION_COMPLETE
    summary_path: /path/to/summary
    phases_completed: [...]
    work_remaining: 0 or phase identifiers
    context_exhausted: true|false
    context_usage_percent: N%
    checkpoint_path: /path/to/checkpoint (if created)
    requires_continuation: true|false
    stuck_detected: false
  "
}
```

**Missing Section**: No "Progress Tracking Instructions" equivalent to /implement's pattern.

### Finding 6: Lean-Coordinator Delegation Pattern

**Source**: `/home/benjamin/.config/.claude/agents/lean-coordinator.md` lines 295-412

The lean-coordinator delegates to lean-implementer with phase_number extraction:

```bash
# Extract phase_number for current theorem
phase_num=$(echo "$theorem_obj" | jq -r '.phase_number // 0')

# Pass to lean-implementer for progress marker updates
# - If phase_num > 0: Enable progress tracking (mark [IN PROGRESS] → [COMPLETE])
# - If phase_num = 0: File-based mode, skip progress tracking
```

**Key Insight**: The coordinator ALREADY extracts and passes phase_number to the implementer. This means the infrastructure exists, but the instructions are missing.

### Finding 7: Current Invocation in /lean-build

**Source**: `/home/benjamin/.config/.claude/commands/lean-build.md` Block 1b (lines 374-418)

The Task invocation is missing progress tracking instructions that would tell lean-coordinator:
1. How to source checkbox-utils.sh
2. When to call progress marker functions
3. How to pass these instructions to lean-implementer
4. What the expected status progression should be

## Comparison Analysis

### /implement Pattern (Working)

```markdown
Task {
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Input Contract**: [...]

    Progress Tracking Instructions:
    - Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
    - Before starting each phase: add_in_progress_marker '$PLAN_FILE' <phase_num>
    - After completing each phase: mark_phase_complete '$PLAN_FILE' <phase_num> && add_complete_marker '$PLAN_FILE' <phase_num>
    - This creates visible progress: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]

    Execute all implementation phases according to the plan.
  "
}
```

### /lean-build Pattern (Missing Progress Tracking)

```markdown
Task {
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md

    **Input Contract**: [...]

    Execute wave-based proof orchestration for mode: ${EXECUTION_MODE}

    **CRITICAL**: You MUST create a proof summary in ${SUMMARIES_DIR}/
    The orchestrator will validate the summary exists after you return.

    Return: ORCHESTRATION_COMPLETE [...]
  "
}
```

**Gap**: No "Progress Tracking Instructions" section.

## Recommendations

### Recommendation 1: Add Progress Tracking Instructions to /lean-build Block 1b

**Location**: `/home/benjamin/.config/.claude/commands/lean-build.md` Block 1b (after line 403)

**Proposed Addition**:

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Wave-based Lean theorem proving orchestration for ${LEAN_FILE}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md

    You are executing the proof orchestration phase for: lean-build workflow

    **Input Contract**:
    - lean_file_path: ${LEAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - artifact_paths:
      - plans: ${CLAUDE_PROJECT_DIR}/.claude/specs/$(basename ${TOPIC_PATH})/plans
      - summaries: ${SUMMARIES_DIR}
      - outputs: ${TOPIC_PATH}/outputs
      - checkpoints: ${CLAUDE_PROJECT_DIR}/.claude/data/checkpoints
    - max_attempts: ${MAX_ATTEMPTS}
    - plan_path: ${PLAN_FILE:-}
    - execution_mode: ${EXECUTION_MODE}
    - starting_phase: ${STARTING_PHASE:-1}
    - continuation_context: ${CONTINUATION_CONTEXT:-null}
    - max_iterations: ${MAX_ITERATIONS}

    **Progress Tracking Instructions** (plan-based mode only):
    - Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
    - Before proving each theorem phase: add_in_progress_marker '$PLAN_FILE' <phase_num>
    - After completing each theorem proof: mark_phase_complete '$PLAN_FILE' <phase_num> && add_complete_marker '$PLAN_FILE' <phase_num>
    - This creates visible progress: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]
    - Note: Progress tracking gracefully degrades if unavailable (non-fatal)
    - File-based mode: Skip progress tracking (phase_num = 0)

    Execute wave-based proof orchestration for mode: ${EXECUTION_MODE}

    For file-based mode: Coordinator should auto-generate single-phase wave structure
    For plan-based mode: Coordinator analyzes dependencies and builds wave structure

    **CRITICAL**: You MUST create a proof summary in ${SUMMARIES_DIR}/
    The orchestrator will validate the summary exists after you return.

    Return: ORCHESTRATION_COMPLETE
    summary_path: /path/to/summary
    phases_completed: [...]
    work_remaining: 0 or phase identifiers
    context_exhausted: true|false
    context_usage_percent: N%
    checkpoint_path: /path/to/checkpoint (if created)
    requires_continuation: true|false
    stuck_detected: false
  "
}
```

**Key Changes**:
1. Added "Progress Tracking Instructions" section after Input Contract
2. Instructions are conditional on plan-based mode
3. Mirrors /implement's pattern exactly
4. Added note about graceful degradation (aligns with lean-implementer's existing behavior)
5. Added note about file-based mode skipping (phase_num = 0)

### Recommendation 2: Update Lean-Coordinator to Forward Instructions

**Location**: `/home/benjamin/.config/.claude/agents/lean-coordinator.md` parallel implementer invocations (lines 326-412)

**Proposed Enhancement**:

The lean-coordinator should include progress tracking instructions in its Task invocations to lean-implementer:

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Prove theorem_add_comm"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/lean-implementer.md

    You are proving theorem in Phase 1: theorem_add_comm

    Input:
    - lean_file_path: /path/to/Theorems.lean
    - theorem_tasks: [{"name": "theorem_add_comm", "line": 42, "phase_number": 1}]
    - plan_path: /path/to/specs/028_lean/plans/001-lean-plan.md
    - rate_limit_budget: 1
    - execution_mode: "plan-based"
    - wave_number: 1
    - phase_number: 1
    - continuation_context: null

    **Progress Tracking Instructions** (plan-based mode only):
    - Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
    - At proof start: add_in_progress_marker '$PLAN_PATH' $PHASE_NUMBER
    - At proof completion: mark_phase_complete '$PLAN_PATH' $PHASE_NUMBER && add_complete_marker '$PLAN_PATH' $PHASE_NUMBER
    - Expected progression: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]
    - If library unavailable: Gracefully degrade (non-fatal)

    Process assigned theorem, prioritize lean_local_search, respect rate limit budget.
    Update plan file with progress markers ([IN PROGRESS] → [COMPLETE]).

    Return THEOREM_BATCH_COMPLETE signal with:
    - theorems_completed, theorems_partial, tactics_used, mathlib_theorems
    - context_exhausted: true|false
    - work_remaining: 0 or list of incomplete theorems
}
```

**Rationale**: The lean-implementer already has STEP 0 and STEP 9 for progress tracking, but it needs explicit instructions to trigger them.

### Recommendation 3: Add Plan File Sourcing to /lean-build Block 1a

**Location**: `/home/benjamin/.config/.claude/commands/lean-build.md` Block 1a (around line 153)

The /lean-build command already sources checkbox-utils.sh at line 153:

```bash
# Source checkbox utilities for plan support
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || {
  echo "ERROR: Failed to source checkbox-utils.sh" >&2
  exit 1
}
```

**Issue**: This sourcing only happens in plan-based mode (inside the `if [[ "$INPUT_FILE" == *.md ]]` block).

**Recommendation**: Keep current sourcing location (it's correct) and ensure plan_path variable is properly passed to coordinator.

### Recommendation 4: Verify Phase Marker Validation in Block 1d

**Location**: `/home/benjamin/.config/.claude/commands/lean-build.md` Block 1d (lines 574-692)

The /lean-build command already has Block 1d for phase marker validation and recovery. This mirrors /implement's pattern:

```bash
### Phase 2: Fix Grep Pattern (Tier 2 Metadata) [NOT STARTED]
# Recovery: Find phases with all checkboxes complete but missing [COMPLETE] marker
RECOVERED_COUNT=0
for phase_num in $(seq 1 "$TOTAL_PHASES"); do
  # Check if phase already has [COMPLETE] marker
  if grep -q "^### Phase ${phase_num}:.*\[COMPLETE\]" "$PLAN_FILE"; then
    continue  # Already marked
  fi

  # Check if all tasks in phase are complete (no [ ] checkboxes)
  if verify_phase_complete "$PLAN_FILE" "$phase_num" 2>/dev/null; then
    echo "Recovering Phase $phase_num (all tasks complete but marker missing)..."

    # Mark all tasks complete (idempotent operation)
    mark_phase_complete "$PLAN_FILE" "$phase_num" 2>/dev/null || {
      echo "  ⚠ Task marking failed for Phase $phase_num" >&2
    }

    # Add [COMPLETE] marker to phase heading
    if add_complete_marker "$PLAN_FILE" "$phase_num" 2>/dev/null; then
      echo "  ✓ [COMPLETE] marker added"
      ((RECOVERED_COUNT++))
    else
      echo "  ⚠ [COMPLETE] marker failed for Phase $phase_num" >&2
    fi
  fi
done
```

**Status**: Already implemented correctly. No changes needed.

## Implementation Guidance

### Phase Sequencing

Based on the existing plan (001-lean-build-error-improvement-plan.md), the progress tracking enhancement should be added as a NEW phase after the current 6 phases:

**Suggested New Phase**:

```markdown
### Phase 7: Add Progress Tracking Instructions to Subagent Invocations [NOT STARTED]
dependencies: [1, 2, 3, 4, 5, 6]

**Objective**: Enhance /lean-build command to instruct lean-coordinator and lean-implementer subagents to update plan file progress markers in real-time, mirroring /implement command's pattern.

**Complexity**: Low

**Tasks**:
- [ ] Add "Progress Tracking Instructions" section to lean-coordinator Task invocation in Block 1b
- [ ] Include conditional guidance for plan-based vs file-based mode
- [ ] Add note about graceful degradation if checkbox-utils.sh unavailable
- [ ] Update lean-coordinator.md to document progress tracking instruction forwarding pattern
- [ ] Verify lean-implementer.md STEP 0 and STEP 9 are triggered by new instructions
- [ ] Test progress marker updates during actual /lean-build execution
- [ ] Verify Block 1d recovery still functions correctly

**Testing**:
```bash
# Create test plan with phases
cat > /tmp/test_lean_progress.md <<'EOF'
# Test Lean Plan

## Metadata
- **Lean File**: /path/to/Test.lean

### Phase 1: Prove theorem_add [NOT STARTED]
lean_file: /path/to/Test.lean

**Tasks**:
- [ ] Prove theorem_add

### Phase 2: Prove theorem_mul [NOT STARTED]
lean_file: /path/to/Test.lean

**Tasks**:
- [ ] Prove theorem_mul
EOF

# Execute /lean-build with plan
/lean-build /tmp/test_lean_progress.md

# Verify progress markers updated
grep -c "Phase.*\[IN PROGRESS\]" /tmp/test_lean_progress.md  # Expect 0 (should transition to COMPLETE)
grep -c "Phase.*\[COMPLETE\]" /tmp/test_lean_progress.md     # Expect 2 (both phases marked)

# Cleanup
rm /tmp/test_lean_progress.md
```

**Expected Duration**: 45 minutes
```

### Integration Points

1. **/lean-build Block 1b** (command → coordinator delegation):
   - Add progress tracking instructions to Task invocation prompt
   - Pass PLAN_FILE and CLAUDE_PROJECT_DIR variables explicitly

2. **lean-coordinator.md** (coordinator → implementer delegation):
   - Document that coordinator should forward progress instructions to implementer
   - Update parallel implementer invocation examples (lines 326-412)
   - Add guidance about when to skip (file-based mode, phase_num=0)

3. **lean-implementer.md** (implementer execution):
   - No changes needed (STEP 0 and STEP 9 already exist)
   - Verify PLAN_PATH and PHASE_NUMBER variables are used correctly

4. **/lean-build Block 1d** (recovery):
   - No changes needed (already mirrors /implement's pattern)

## Risk Assessment

### Low Risk

**Scope**: Instructions are additive (new section in Task prompt)
**Impact**: Enables real-time progress visibility without breaking existing behavior
**Rollback**: Simple removal of "Progress Tracking Instructions" section

### Mitigation Strategies

**Pre-deployment**:
1. Test with plan-based mode (verify markers update)
2. Test with file-based mode (verify no errors from missing plan)
3. Test with checkpoint-utils.sh unavailable (verify graceful degradation)
4. Verify Block 1d recovery still works (missing markers are recovered)

**Post-deployment**:
1. Monitor /errors logs for new progress tracking failures
2. Test with multi-file plans (verify per-file marker updates)
3. Verify iteration loop preserves progress markers across continuations

## Conclusion

The /implement command's progress tracking pattern is well-established and can be directly adapted to /lean-build with minimal changes:

1. **Add Progress Tracking Instructions section** to /lean-build Block 1b Task invocation
2. **Document instruction forwarding** in lean-coordinator.md behavioral guidelines
3. **Verify existing infrastructure** (lean-implementer STEP 0/9, Block 1d recovery) works correctly

The lean-implementer agent already has full support for progress tracking built in (STEP 0 initialization and STEP 9 completion), so the primary change is adding the instructions that trigger this existing capability.

This enhancement will provide:
- Real-time visibility into proof progress via plan file inspection
- Consistent progress tracking across /implement and /lean-build workflows
- Graceful degradation when checkbox-utils.sh unavailable (non-fatal)
- Automatic recovery of missing markers via Block 1d (defensive orchestration)

## Appendices

### Appendix A: Function Call Sequence

**Successful Phase Execution**:

```
1. Command Block 1a:
   - source checkbox-utils.sh
   - add_not_started_markers (if legacy plan)
   - add_in_progress_marker (for starting phase)
   - update_plan_status "IN PROGRESS"

2. Coordinator receives instructions:
   - source checkbox-utils.sh
   - add_in_progress_marker <phase_num> (before delegation)

3. Implementer receives instructions:
   - source checkbox-utils.sh (STEP 0)
   - add_in_progress_marker <phase_num> (STEP 0)
   - [... proof work ...]
   - mark_phase_complete <phase_num> (STEP 9)
   - add_complete_marker <phase_num> (STEP 9)

4. Command Block 1d:
   - verify_phase_complete (recovery check)
   - add_complete_marker (if missing)
   - check_all_phases_complete
   - update_plan_status "COMPLETE" (if all done)
```

### Appendix B: Checkbox-Utils.sh Function Signatures

```bash
add_not_started_markers() {
  local plan_file="$1"
  # Adds [NOT STARTED] to phases lacking status markers
}

add_in_progress_marker() {
  local plan_file="$1"
  local phase_num="$2"
  # Replaces [NOT STARTED] with [IN PROGRESS] in phase heading
}

mark_phase_complete() {
  local plan_file="$1"
  local phase_num="$2"
  # Marks all [ ] tasks as [x] in phase
}

add_complete_marker() {
  local plan_file="$1"
  local phase_num="$2"
  # Replaces [IN PROGRESS] with [COMPLETE] in phase heading
}

verify_phase_complete() {
  local plan_file="$1"
  local phase_num="$2"
  # Returns 0 if all tasks [x], 1 otherwise
}

check_all_phases_complete() {
  local plan_file="$1"
  # Returns 0 if all phases have [COMPLETE], 1 otherwise
}

update_plan_status() {
  local plan_file="$1"
  local status="$2"  # "IN PROGRESS" or "COMPLETE"
  # Updates plan metadata "Status: [STATUS]" field
}
```

### Appendix C: Variable Passing Pattern

**From /lean-build to lean-coordinator**:

```bash
# Block 1b Task invocation variables
PLAN_FILE="${PLAN_FILE:-}"                  # Empty string if file-based mode
EXECUTION_MODE="${EXECUTION_MODE}"          # "file-based" or "plan-based"
STARTING_PHASE="${STARTING_PHASE:-1}"      # Phase number or 1 if file-based
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR}" # Absolute path to .claude parent
```

**From lean-coordinator to lean-implementer**:

```bash
# Parallel implementer invocation variables
PLAN_PATH="$PLAN_FILE"                     # Passed from coordinator input
PHASE_NUMBER="$phase_num"                  # Extracted from theorem_tasks[].phase_number
EXECUTION_MODE="$EXECUTION_MODE"           # Forwarded from coordinator input
CLAUDE_PROJECT_DIR="$CLAUDE_PROJECT_DIR"   # Forwarded from coordinator input
```

**Key Pattern**: All paths are absolute, all variables are passed explicitly in Task prompt, no reliance on state persistence for progress tracking.

## References

- `/home/benjamin/.config/.claude/commands/implement.md` - Source of truth for progress tracking pattern
- `/home/benjamin/.config/.claude/commands/lean-build.md` - Target command for enhancement
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` - Coordinator progress tracking behavior
- `/home/benjamin/.config/.claude/agents/lean-coordinator.md` - Lean coordinator delegation pattern
- `/home/benjamin/.config/.claude/agents/lean-implementer.md` - Implementer progress tracking capability (STEP 0/9)
- `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh` - Progress tracking library functions
- `/home/benjamin/.config/.claude/specs/036_lean_build_error_improvement/plans/001-lean-build-error-improvement-plan.md` - Existing improvement plan

## Research Completion Signal

REPORT_CREATED: /home/benjamin/.config/.claude/specs/036_lean_build_error_improvement/reports/002-plan-update-pattern-research.md
