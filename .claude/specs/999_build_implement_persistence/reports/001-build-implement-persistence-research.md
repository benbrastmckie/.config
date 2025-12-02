# /build and /implement Persistence Mechanism Research Report

## Metadata
- **Date**: 2025-12-01
- **Agent**: research-specialist
- **Topic**: Build vs Implement command persistence through phase completion
- **Report Type**: codebase analysis

## Executive Summary

The /build command orchestrates subagents iteratively until plans are complete, while /implement stops after phases complete. The key difference is in Block 1c verification: /build uses an **ITERATION DECISION** checkpoint that loops back to Block 1b when continuation is required, whereas /implement proceeds directly to Block 1d (phase update). Both commands share identical iteration detection logic but differ in their response to `requires_continuation` signals from implementer-coordinator.

## Findings

### 1. Common Iteration Infrastructure

Both commands share identical iteration setup and detection code:

**Block 1a - Iteration Variables** (lines 462-476 in both):
```bash
# === ITERATION LOOP VARIABLES ===
# These enable persistent iteration for large plans
ITERATION=1
CONTINUATION_CONTEXT=""
LAST_WORK_REMAINING=""
STUCK_COUNT=0

# Persist iteration variables for cross-block accessibility
append_workflow_state "MAX_ITERATIONS" "$MAX_ITERATIONS"
append_workflow_state "CONTEXT_THRESHOLD" "$CONTEXT_THRESHOLD"
append_workflow_state "ITERATION" "$ITERATION"
append_workflow_state "CONTINUATION_CONTEXT" "$CONTINUATION_CONTEXT"
append_workflow_state "LAST_WORK_REMAINING" "$LAST_WORK_REMAINING"
append_workflow_state "STUCK_COUNT" "$STUCK_COUNT"
```

**Block 1c - Iteration Check Logic** (lines 760-872 in both):
- Both parse `WORK_REMAINING`, `CONTEXT_EXHAUSTED`, `REQUIRES_CONTINUATION` from agent output
- Both use identical completion/continuation logic
- Both update state variables for next iteration
- Both save continuation context to workspace directory

### 2. Critical Difference: Iteration Response

**Location**: End of Block 1c

**BUILD** (/home/benjamin/.config/.claude/commands/build.md:854-859):
```markdown
**ITERATION DECISION**:
- If IMPLEMENTATION_STATUS is "continuing", repeat the Task invocation above with updated ITERATION
- If IMPLEMENTATION_STATUS is "complete", "stuck", or "max_iterations", proceed to phase update block

**EXECUTE NOW**: Parse the phase count and invoke spec-updater agent to mark completed phases in the plan hierarchy.
```

**IMPLEMENT** (/home/benjamin/.config/.claude/commands/implement.md:875-877):
```markdown
**ITERATION DECISION**:
- If IMPLEMENTATION_STATUS is "continuing", repeat the Task invocation above with updated ITERATION
- If IMPLEMENTATION_STATUS is "complete", "stuck", or "max_iterations", proceed to phase update block (Block 1d)
```

**Analysis**: Both commands document the same iteration decision, but the **BUILD** command includes instructional text directing Claude to repeat the Task invocation (Block 1b), while **IMPLEMENT** simply notes the decision point and proceeds to Block 1d.

### 3. The Persistence Mechanism

**How /build achieves persistence**:

1. **Block 1c** (lines 830-853) sets up continuation state:
   ```bash
   if [ "$REQUIRES_CONTINUATION" = "true" ]; then
     echo "Coordinator reports continuation required"

     # Prepare for next iteration
     NEXT_ITERATION=$((ITERATION + 1))
     CONTINUATION_CONTEXT="${BUILD_WORKSPACE}/iteration_${ITERATION}_summary.md"

     echo "Preparing iteration $NEXT_ITERATION..."

     # Update state for next iteration
     append_workflow_state "ITERATION" "$NEXT_ITERATION"
     append_workflow_state "WORK_REMAINING" "$WORK_REMAINING"
     append_workflow_state "CONTINUATION_CONTEXT" "$CONTINUATION_CONTEXT"
     append_workflow_state "IMPLEMENTATION_STATUS" "continuing"
   ```

2. **Markdown instruction** (line 856-857) explicitly directs:
   ```markdown
   - If IMPLEMENTATION_STATUS is "continuing", repeat the Task invocation above with updated ITERATION
   ```

3. **Claude interprets** this instruction and re-executes Block 1b with updated variables

**Why /implement doesn't persist**:

1. **Same state setup** in Block 1c (identical code)
2. **Same markdown instruction** exists (line 875-876)
3. **Missing explicit directive** to loop back - no "EXECUTE NOW" marker after iteration decision
4. **Direct flow** to Block 1d instead of conditional branching

### 4. Block Structure Comparison

**BUILD command blocks**:
- Block 1a: Setup
- Block 1b: Task invocation (implementer-coordinator) ← **Loop target**
- Block 1c: Verification + Iteration decision ← **Loop decision point**
- [Conditional loop back to 1b]
- Block 1d: Phase update (after iterations complete)
- Block 2+: Testing, debug, documentation, completion

**IMPLEMENT command blocks**:
- Block 1a: Setup
- Block 1b: Task invocation (implementer-coordinator) ← **Not revisited**
- Block 1c: Verification + Iteration decision ← **No loop enforcement**
- Block 1d: Phase update (immediately after)
- Block 2: Completion

### 5. Key Code References

**BUILD iteration decision** (/home/benjamin/.config/.claude/commands/build.md:854-860):
```markdown
**ITERATION DECISION**:
- If IMPLEMENTATION_STATUS is "continuing", repeat the Task invocation above with updated ITERATION
- If IMPLEMENTATION_STATUS is "complete", "stuck", or "max_iterations", proceed to phase update block

**EXECUTE NOW**: Parse the phase count and invoke spec-updater agent to mark completed phases in the plan hierarchy.

```bash
set +H 2>/dev/null || true
```

**IMPLEMENT iteration decision** (/home/benjamin/.config/.claude/commands/implement.md:875-879):
```markdown
**ITERATION DECISION**:
- If IMPLEMENTATION_STATUS is "continuing", repeat the Task invocation above with updated ITERATION
- If IMPLEMENTATION_STATUS is "complete", "stuck", or "max_iterations", proceed to phase update block (Block 1d)

## Block 1d: Phase Update
```

**Analysis**: BUILD includes explicit "EXECUTE NOW" directive after the iteration decision for the phase update case, but the iteration loop is implicit in the instruction text. IMPLEMENT transitions directly to Block 1d heading without conditional execution.

### 6. Implementer-Coordinator Return Protocol

Both commands rely on implementer-coordinator returning (lines 565-575 in both):
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

The `requires_continuation` field drives the iteration logic.

### 7. Workspace and Checkpoint Support

**BUILD** (line 479):
```bash
BUILD_WORKSPACE="${CLAUDE_PROJECT_DIR}/.claude/tmp/build_${WORKFLOW_ID}"
```

**IMPLEMENT** (line 478):
```bash
IMPLEMENT_WORKSPACE="${CLAUDE_PROJECT_DIR}/.claude/tmp/implement_${WORKFLOW_ID}"
```

Both create workspace directories for iteration summaries and both support checkpoint resumption (lines 202-249).

## Recommendations

### 1. Add Explicit Iteration Loop to /implement

**Modification Location**: /home/benjamin/.config/.claude/commands/implement.md, after line 872

**Current code**:
```markdown
**ITERATION DECISION**:
- If IMPLEMENTATION_STATUS is "continuing", repeat the Task invocation above with updated ITERATION
- If IMPLEMENTATION_STATUS is "complete", "stuck", or "max_iterations", proceed to phase update block (Block 1d)

## Block 1d: Phase Update
```

**Recommended change**:
```markdown
**ITERATION DECISION**:

Check the IMPLEMENTATION_STATUS from Block 1c iteration check:

**If IMPLEMENTATION_STATUS is "continuing"**: Loop back to Block 1b with updated iteration context.

**EXECUTE NOW**: The implementer-coordinator reported work remaining and context available. Repeat the Task invocation from Block 1b with updated variables:
- ITERATION = ${NEXT_ITERATION}
- CONTINUATION_CONTEXT = ${IMPLEMENT_WORKSPACE}/iteration_${ITERATION}_summary.md
- WORK_REMAINING = [from agent output]

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization (iteration ${NEXT_ITERATION}/${MAX_ITERATIONS})"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    You are executing the implementation phase for: implement workflow

    **Input Contract (Hard Barrier Pattern)**:
    - plan_path: $PLAN_FILE
    - topic_path: $TOPIC_PATH
    - summaries_dir: ${TOPIC_PATH}/summaries/
    - continuation_context: ${CONTINUATION_CONTEXT}
    - iteration: ${NEXT_ITERATION}

    [... rest of Task prompt identical to Block 1b ...]
  "
}

After the Task returns, **proceed to Block 1c verification** to check for further continuation needs.

---

**If IMPLEMENTATION_STATUS is "complete", "stuck", or "max_iterations"**: Proceed to Block 1d.

## Block 1d: Phase Update
```

### 2. Alternative: Add Iteration Loop Block Between 1c and 1d

Create a new **Block 1c-loop** that conditionally invokes based on IMPLEMENTATION_STATUS:

```bash
# Load state and check IMPLEMENTATION_STATUS
load_workflow_state "$WORKFLOW_ID" false

if [ "$IMPLEMENTATION_STATUS" = "continuing" ]; then
  echo "=== Iteration ${NEXT_ITERATION}/${MAX_ITERATIONS} Required ==="
  echo "Work remaining: $WORK_REMAINING"
  echo "Context available: $((100 - CONTEXT_USAGE_PERCENT))%"
  echo ""

  # Update iteration counter
  ITERATION="$NEXT_ITERATION"

  # Proceed to Block 1b Task invocation
  # (Block 1b would need to be reachable from here)
fi

# If not continuing, fall through to Block 1d
```

**Issue**: This approach requires bash blocks to conditionally skip subsequent markdown blocks, which is not cleanly supported in the command execution model.

### 3. Use Hard Barrier Pattern with Loop Enforcement

Add explicit loop enforcement similar to hard barrier verification:

**After Block 1c** (before current iteration decision):

```markdown
## Block 1c-decision: Iteration Loop Enforcement

**CRITICAL DECISION POINT**: This block determines whether to continue iterating or proceed to completion.

**EXECUTE NOW**: Check iteration status and conditionally loop or proceed.

```bash
# Load state from Block 1c
load_workflow_state "$WORKFLOW_ID" false

IMPLEMENTATION_STATUS="${IMPLEMENTATION_STATUS:-complete}"
NEXT_ITERATION="${NEXT_ITERATION:-1}"
MAX_ITERATIONS="${MAX_ITERATIONS:-5}"

echo "=== Iteration Decision Point ==="
echo "Status: $IMPLEMENTATION_STATUS"
echo "Next iteration: ${NEXT_ITERATION}/${MAX_ITERATIONS}"
echo ""

# Persist decision for verification
append_workflow_state "LOOP_DECISION" "$IMPLEMENTATION_STATUS"

if [ "$IMPLEMENTATION_STATUS" = "continuing" ]; then
  echo "DECISION: Continue to iteration $NEXT_ITERATION"
  echo "Returning to Block 1b invocation..."
  append_workflow_state "NEXT_BLOCK" "1b"
else
  echo "DECISION: Proceed to phase update"
  append_workflow_state "NEXT_BLOCK" "1d"
fi
```

**Conditional Block Selection**: After decision block, use markdown instructions to guide Claude:

```markdown
**If LOOP_DECISION is "continuing"**: Return to Block 1b above and re-execute Task invocation with updated ITERATION.

**If LOOP_DECISION is NOT "continuing"**: Proceed to Block 1d below.

## Block 1d: Phase Update
```

## References

- /home/benjamin/.config/.claude/commands/build.md:462-476 (iteration variables setup)
- /home/benjamin/.config/.claude/commands/build.md:760-872 (iteration check logic)
- /home/benjamin/.config/.claude/commands/build.md:854-860 (iteration decision and loop instruction)
- /home/benjamin/.config/.claude/commands/implement.md:462-476 (identical iteration variables setup)
- /home/benjamin/.config/.claude/commands/implement.md:760-872 (identical iteration check logic)
- /home/benjamin/.config/.claude/commands/implement.md:875-879 (iteration decision without loop enforcement)
- /home/benjamin/.config/.claude/agents/implementer-coordinator.md (agent return protocol with requires_continuation)

## Architectural Insight

The difference is **not in code** but in **markdown instruction interpretation**. Both commands have identical bash logic for detecting continuation needs. The /build command succeeds in looping because its markdown structure **strongly directs Claude to repeat Block 1b** when continuation is required, while /implement's markdown simply **documents the decision** and proceeds linearly to Block 1d.

The fix requires making the iteration loop **architecturally explicit** rather than relying on implicit interpretation of decision text.
