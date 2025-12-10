# Root Cause Analysis: Subagents Not Updating Phase Markers

## Executive Summary

**Root Cause**: Phase marker updates are delegated to coordinators but not consistently implemented across the delegation chain. The lean-implementer is responsible for marker updates but lacks explicit progress tracking instructions in the Task invocation from lean-coordinator.

**Impact**: Plan files show `[NOT STARTED]` markers even after theorems are proven, causing confusion about actual completion status.

**Severity**: Medium - Affects user visibility but does not block execution

**Implementation Status**: FIX IMPLEMENTED (2025-12-09)
- Fix Location: `/home/benjamin/.config/.claude/commands/lean-implement.md` (Block 1b, lines 877-884)
- Implementation Plan: `/home/benjamin/.config/.claude/specs/062_subagent_phase_update_debug/plans/001-debug-strategy.md`
- Status: Progress tracking instructions added to lean-coordinator Task prompt

## Investigation Summary

### Plan Executed
- **Plan**: `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/.claude/specs/059_modal_theorems_s5_completion/plans/001-modal-theorems-s5-completion-plan.md`
- **Command**: `/lean-implement`
- **Output**: `/home/benjamin/.config/.claude/output/lean-implement-output.md`

### Observed Behavior
From the output log (lines 86-91):
```
Given that the lean phases have partial completion
(Phase 1 complete, Phase 2 blocked on a fundamental
limitation, Phases 3-4 partial), let me now handle
Phase 5 (the software/documentation phase).
```

This indicates work was completed but markers were not updated in real-time.

## Delegation Chain Analysis

### Layer 1: Primary Orchestrator (`/lean-implement`)

**Responsibility**: Route plan execution to appropriate coordinator

**Marker Handling**: Block 1d explicitly states marker management is **DELEGATED TO COORDINATORS**

From `lean-implement.md` lines 1373-1385:
```markdown
## Block 1d: Phase Marker Management (DELEGATED TO COORDINATORS)

**NOTE**: Phase marker validation and recovery has been removed from the orchestrator.

**Coordinator Responsibility**: Phase marker management (adding [IN PROGRESS]
and [COMPLETE] markers) is handled by coordinators (lean-coordinator and
implementer-coordinator) as part of their workflow.

**Rationale**:
- Eliminates redundant marker recovery logic in orchestrator
- Reduces context consumption (saved ~120 lines of bash code)
- Maintains single source of truth (coordinators control markers)
- Simplifies orchestrator to pure routing and validation
```

**Status**: ✅ Correctly delegates responsibility to coordinators

### Layer 2: Wave Coordinator (`lean-coordinator`)

**Responsibility**: Orchestrate parallel lean-implementer invocations with dependency analysis

**Marker Handling**: Lines 314-334 describe "Progress Tracking Instruction Forwarding"

From `lean-coordinator.md` lines 314-334:
```markdown
#### Progress Tracking Instruction Forwarding

When /lean-build provides Progress Tracking Instructions in the input prompt,
the coordinator MUST forward these instructions to each lean-implementer invocation:

**Instructions Received from /lean-build** (plan-based mode only):
```markdown
Progress Tracking Instructions (plan-based mode only):
- Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
- Before proving each theorem phase: add_in_progress_marker '${PLAN_FILE}' <phase_num>
- After completing each theorem proof: mark_phase_complete '${PLAN_FILE}' <phase_num>
  && add_complete_marker '${PLAN_FILE}' <phase_num>
- This creates visible progress: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]
- Note: Progress tracking gracefully degrades if unavailable (non-fatal)
- File-based mode: Skip progress tracking (phase_num = 0)
```

**Forwarding Pattern**:
1. Include progress tracking instructions in each lean-implementer Task prompt
2. Replace `<phase_num>` with actual phase number from theorem metadata
3. Skip if `execution_mode=file-based` or `phase_number=0`
4. Instructions are informational only (non-blocking if checkbox-utils unavailable)
```

**Critical Issue Found**: The lean-coordinator expects progress tracking instructions to be provided in its INPUT from the calling command, but when I examine the actual Task invocation in the output log (lines 48-49), the prompt does NOT include these instructions.

From `lean-implement-output.md` lines 48-49:
```
● Task(Wave-based full plan theorem proving orchestration)
  ⎿  Done (38 tool uses · 135.6k tokens · 11m 28s)
```

The Task description is generic and does not contain explicit progress tracking instructions.

**Status**: ❌ **ROOT CAUSE IDENTIFIED** - Coordinator does not receive progress tracking instructions from `/lean-implement`

### Layer 3: Proof Worker (`lean-implementer`)

**Responsibility**: Execute individual theorem proofs and update plan markers

**Marker Handling**: STEP 0 (lines 135-160) and STEP 9 (lines 621-642) implement progress tracking

From `lean-implementer.md` lines 135-160 (STEP 0):
```bash
# Source checkbox-utils.sh for progress tracking (non-fatal)
source "$CLAUDE_LIB/plan/checkbox-utils.sh" 2>/dev/null || {
  echo "Warning: Progress tracking unavailable (checkbox-utils.sh not found)" >&2
}

# Extract plan_path and phase_number from input contract
PLAN_PATH="$5"  # From input contract (empty string if file-based mode)
PHASE_NUMBER="$6"  # From input contract (0 if file-based mode)

# Mark phase IN PROGRESS if plan-based mode and library available
if [ -n "$PLAN_PATH" ] && [ "$PHASE_NUMBER" -gt 0 ] && type add_in_progress_marker &>/dev/null; then
  add_in_progress_marker "$PLAN_PATH" "$PHASE_NUMBER" 2>/dev/null || {
    echo "Warning: Failed to add [IN PROGRESS] marker for phase $PHASE_NUMBER" >&2
  }
  echo "Progress tracking enabled for phase $PHASE_NUMBER"
else
  echo "Progress tracking skipped (file-based mode or library unavailable)"
fi
```

From `lean-implementer.md` lines 621-642 (STEP 9):
```bash
# Mark phase COMPLETE if plan-based mode and library available
if [ -n "$PLAN_PATH" ] && [ "$PHASE_NUMBER" -gt 0 ] && type add_complete_marker &>/dev/null; then
  add_complete_marker "$PLAN_PATH" "$PHASE_NUMBER" 2>/dev/null || {
    echo "Warning: add_complete_marker validation failed, trying fallback" >&2
    # Fallback to mark_phase_complete (force marking)
    if type mark_phase_complete &>/dev/null; then
      mark_phase_complete "$PLAN_PATH" "$PHASE_NUMBER" 2>/dev/null || {
        echo "Warning: All marker methods failed for phase $PHASE_NUMBER" >&2
      }
    fi
  }
  echo "Progress marker updated: Phase $PHASE_NUMBER marked COMPLETE"
else
  echo "Progress tracking skipped (file-based mode or library unavailable)"
fi
```

**Status**: ✅ Correctly implements marker updates IF provided with plan_path and phase_number

## Root Cause Identification

### Missing Link: `/lean-implement` → `lean-coordinator` Contract

The `/lean-implement` command (Block 1b, lines 842-896) builds the coordinator prompt but **DOES NOT INCLUDE progress tracking instructions**.

From `lean-implement.md` lines 857-896:
```markdown
# Build lean-coordinator full-plan prompt
COORDINATOR_PROMPT="Read and follow ALL behavioral guidelines from:
  ${COORDINATOR_AGENT}

  **Input Contract (Hard Barrier Pattern)**:
  - plan_path: ${PLAN_FILE}
  - lean_file_path: ${PRIMARY_LEAN_FILE}
  - topic_path: ${TOPIC_PATH}
  - execution_mode: full-plan
  - routing_map_path: ${ROUTING_MAP_FILE}
  - artifact_paths:
    - plans: ${TOPIC_PATH}/plans/
    - summaries: ${SUMMARIES_DIR}
    - outputs: ${OUTPUTS_DIR}
    - debug: ${DEBUG_DIR}
    - checkpoints: ${CHECKPOINTS_DIR}
  - iteration: ${ITERATION}
  - max_iterations: ${MAX_ITERATIONS}
  - context_threshold: ${CONTEXT_THRESHOLD}
  - continuation_context: ${CONTINUATION_CONTEXT:-null}

  **Workflow Instructions**:
  1. Analyze plan dependencies via dependency-analyzer.sh
  2. Calculate wave structure with parallelization metrics
  3. Execute waves sequentially with parallel lean-implementer invocations per wave
  4. Wait for ALL implementers in Wave N before starting Wave N+1 (hard barrier)
  5. Aggregate results and return ORCHESTRATION_COMPLETE signal

  **Expected Output Signal**:
  - summary_brief: 80-token summary for context efficiency
  - waves_completed: Number of waves finished
  - total_waves: Total waves in plan
  - phases_completed: List of phase numbers completed
  - work_remaining: List of phase numbers still incomplete
  - context_usage_percent: Estimated context usage (0-100)
  - requires_continuation: Boolean indicating if more work remains
  - parallelization_metrics: Time savings percentage, parallel phases count

  **CRITICAL**: Create wave execution summary in ${SUMMARIES_DIR}/
  The orchestrator will validate the summary exists after you return."
```

**Missing Section**: The prompt does NOT include:
```markdown
**Progress Tracking Instructions** (plan-based mode):
- Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
- For each lean-implementer invocation, include progress tracking instructions in Task prompt
- Forward instructions: Before proving theorem → add_in_progress_marker
- Forward instructions: After completing theorem → mark_phase_complete && add_complete_marker
- Phase markers create visible progress: [NOT STARTED] → [IN PROGRESS] → [COMPLETE]
- Progress tracking gracefully degrades if checkbox-utils unavailable (non-fatal)
```

### Why This Matters

1. **lean-coordinator** expects progress tracking instructions (per lines 314-334 of its behavioral guidelines)
2. `/lean-implement` does NOT provide these instructions in the coordinator Task prompt
3. **lean-implementer** has the capability to update markers (STEP 0 and STEP 9) but relies on receiving instructions via the coordinator
4. Without instructions, the coordinator does not forward progress tracking details to implementers
5. Result: Implementers complete work but markers remain `[NOT STARTED]`

## Verification in Actual Execution

From the output log, I can see:

**Line 48-49**: Coordinator invoked with generic description:
```
● Task(Wave-based full plan theorem proving orchestration)
```

**Lines 94-95**: Software phase invoked separately:
```
● Task(Execute software phase 5 documentation) Sonnet 4.5
```

**Lines 120-128**: Final status shows work completed but markers not updated during execution:
```
| Phase 1 | ✓ COMPLETE | 7 De Morgan law theorems proven in Propositional.lean
| Phase 2 | ⚠️ BLOCKED | diamond_mono_imp NOT VALID (fundamental modal logic limitation)
| Phase 3 | PARTIAL    | diamond_disj_iff structure documented, needs formula alignment
| Phase 4 | PARTIAL    | 2/4 theorems pre-proven, 2 blocked on conditional monotonicity
| Phase 5 | ✓ COMPLETE | Documentation updated (IMPLEMENTATION_STATUS, SORRY_REGISTRY, CLAUDE.md)
```

The markers were updated in the FINAL SUMMARY but not in REAL-TIME during wave execution.

## Secondary Issue: Phase Marker Management Delegation

From `/lean-implement.md` lines 1373-1385, the orchestrator explicitly delegates marker management to coordinators:

```markdown
**NOTE**: Phase marker validation and recovery has been removed from the orchestrator.

**Coordinator Responsibility**: Phase marker management (adding [IN PROGRESS]
and [COMPLETE] markers) is handled by coordinators (lean-coordinator and
implementer-coordinator) as part of their workflow.
```

However, the coordinators lack explicit bash blocks for marker management. The assumption is that implementers will handle this, but:

1. Coordinators do not invoke bash directly (they only use Task, Read, Bash tools for orchestration)
2. Implementers have the capability but require explicit instructions
3. The contract between orchestrator → coordinator does not specify marker requirements
4. The contract between coordinator → implementer does not include progress tracking instructions

## Comparison with Working Pattern

From the plan file metadata (lines 67-74), I can see the expected pattern:

```markdown
### Phase Routing Summary
| Phase | Type | Implementer Agent |
|-------|------|-------------------|
| 1 | lean | lean-implementer |
| 2 | lean | lean-implementer |
| 3 | lean | lean-implementer |
| 4 | lean | lean-implementer |
| 5 | software | implementer-coordinator |
```

In the `/implement` command (which handles software phases), progress tracking is likely handled differently. Let me check if there's a similar gap in the implementer-coordinator or if software phases have a different pattern.

However, the core issue remains: **The lean workflow delegation chain does not propagate progress tracking instructions from orchestrator to coordinator to implementer.**

## Root Cause Summary

### Primary Issue: Missing Progress Tracking Instructions in Coordinator Invocation

**Location**: `/lean-implement.md` Block 1b (lines 842-896)

**Problem**: The Task prompt for lean-coordinator does NOT include progress tracking instructions that the coordinator expects to forward to lean-implementers.

**Expected Pattern**:
```
/lean-implement (orchestrator)
  → Provides progress tracking instructions in Task prompt
  → lean-coordinator (wave orchestrator)
    → Forwards instructions to each lean-implementer Task prompt
    → lean-implementer (proof worker)
      → Executes marker updates (STEP 0: [IN PROGRESS], STEP 9: [COMPLETE])
```

**Actual Pattern**:
```
/lean-implement (orchestrator)
  → MISSING: Does not provide progress tracking instructions
  → lean-coordinator (wave orchestrator)
    → Has no instructions to forward
    → lean-implementer (proof worker)
      → Skips marker updates (conditions not met: no plan_path or phase_number provided)
```

### Secondary Issue: Ambiguous Marker Management Responsibility

**Location**: `/lean-implement.md` Block 1d (lines 1373-1385)

**Problem**: Orchestrator explicitly delegates marker management to coordinators but:
1. Coordinators don't have direct marker update logic (they coordinate via Task tool)
2. Implementers have the capability but require explicit input contract parameters
3. The contract gaps prevent the capability from being exercised

## Recommended Fix

### Solution 1: Add Progress Tracking Instructions to Coordinator Prompt (Preferred)

**Modify**: `/lean-implement.md` Block 1b, lines 857-896

**Add after line 876** (after continuation_context line):
```markdown
  - progress_tracking:
      enabled: true
      plan_file: ${PLAN_FILE}
      checkbox_utils_path: ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh

  **Progress Tracking Instructions** (CRITICAL for real-time markers):
  When invoking lean-implementer subagents via Task tool:
  1. Include plan_path parameter: ${PLAN_FILE}
  2. Include phase_number parameter: Extract from theorem metadata
  3. Include these instructions in each lean-implementer Task prompt:
     - Before proving theorem: add_in_progress_marker '${PLAN_FILE}' <phase_num>
     - After completing proof: mark_phase_complete '${PLAN_FILE}' <phase_num> && add_complete_marker '${PLAN_FILE}' <phase_num>
     - Progress markers: [NOT STARTED] → [IN PROGRESS] → [COMPLETE]
     - Graceful degradation if checkbox-utils unavailable (non-fatal)
```

### Solution 2: Add Marker Update Bash Block to Coordinator (Alternative)

**Modify**: `lean-coordinator.md` STEP 4 Wave Execution Loop

**Add after line 532** (after wave completion):
```bash
# Update phase markers after wave completion
if [ -n "$plan_path" ] && [ "${#wave_phases[@]}" -gt 0 ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || {
    echo "Warning: Progress tracking unavailable" >&2
  }

  for phase_num in "${wave_phases[@]}"; do
    if type add_complete_marker &>/dev/null; then
      add_complete_marker "$plan_path" "$phase_num" 2>/dev/null || {
        mark_phase_complete "$plan_path" "$phase_num" 2>/dev/null || true
      }
      echo "Phase $phase_num marker updated to [COMPLETE]"
    fi
  done
fi
```

### Solution 3: Hybrid Approach (Most Robust)

Implement both Solution 1 and Solution 2:
1. Primary: Implementers update markers in real-time (Solution 1)
2. Backup: Coordinator validates and fixes missing markers after wave completion (Solution 2)

This provides defense-in-depth: if implementers fail to update markers (e.g., checkbox-utils unavailable), the coordinator can perform recovery.

## Testing Strategy

### Test Case 1: Fresh Plan Execution
1. Create plan with 3 Lean phases
2. Run `/lean-implement plan.md`
3. During execution, run `grep -E "^\### Phase [0-9]+" plan.md` to check real-time markers
4. Verify markers transition: `[NOT STARTED]` → `[IN PROGRESS]` → `[COMPLETE]`

### Test Case 2: Partial Execution Resume
1. Execute plan that exceeds context threshold (triggers checkpoint)
2. Resume with `/lean-implement --resume=checkpoint.json`
3. Verify continued phases show `[IN PROGRESS]` markers
4. Verify completed phases retain `[COMPLETE]` markers

### Test Case 3: Marker Recovery Validation
1. Manually corrupt markers (change `[COMPLETE]` back to `[NOT STARTED]`)
2. Re-run plan
3. Verify coordinator/implementer detects and fixes incorrect markers

## Impact Assessment

### User Experience Impact
- **Before Fix**: Users cannot see real-time progress (must wait for final summary)
- **After Fix**: Users can monitor progress via `cat plan.md | grep "### Phase"` during execution

### Performance Impact
- **Minimal**: Adding instructions to Task prompt adds ~200 tokens per coordinator invocation
- **Benefit**: Real-time visibility reduces user anxiety during long-running proof sessions

### Backward Compatibility
- **None**: Adding instructions to coordinator prompt is non-breaking (coordinators already expect these per their behavioral guidelines)
- **Graceful Degradation**: If checkbox-utils.sh unavailable, implementers skip marker updates (non-fatal)

## Conclusion

The root cause is a **contract gap** in the delegation chain:

1. `/lean-implement` does not provide progress tracking instructions to `lean-coordinator`
2. `lean-coordinator` expects to receive these instructions and forward them to `lean-implementer`
3. `lean-implementer` has the capability to update markers but never receives the necessary parameters

**Fix**: Add progress tracking instructions to the coordinator Task prompt in `/lean-implement` Block 1b.

**Priority**: Medium (affects visibility but not functionality)

**Effort**: Low (20-30 lines added to coordinator prompt template)

**Testing**: 3 test cases covering fresh execution, resume, and recovery scenarios

## References

- Plan File: `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/.claude/specs/059_modal_theorems_s5_completion/plans/001-modal-theorems-s5-completion-plan.md`
- Output Log: `/home/benjamin/.config/.claude/output/lean-implement-output.md`
- Command Spec: `/home/benjamin/.config/.claude/commands/lean-implement.md` (Block 1b: lines 842-896, Block 1d: lines 1373-1385)
- Coordinator Spec: `/home/benjamin/.config/.claude/agents/lean-coordinator.md` (lines 314-334: Progress Tracking Instruction Forwarding)
- Implementer Spec: `/home/benjamin/.config/.claude/agents/lean-implementer.md` (STEP 0: lines 135-160, STEP 9: lines 621-642)
