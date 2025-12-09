# Root Cause Analysis: Lean-Implement Coordinator Delegation Failure

**Date**: 2025-12-09
**Analysis Type**: Root cause analysis for debug workflow
**Complexity**: 2
**Status**: Complete

---

## Executive Summary

The `/lean-implement` command switches from coordinating lean-coordinator subagent delegation to performing direct proof work with the primary agent after the coordinator completes Phase 1 with partial success. The root cause is a **missing hard barrier after Block 1c verification** that should enforce strict delegation but instead allows the primary agent to interpret partial results as a signal to continue work directly.

**Key Finding**: After the lean-coordinator returns with `work_remaining` populated, the command flow **bypasses the iteration decision logic** and the primary agent immediately begins reading files, analyzing proofs, and calling MCP tools directly—activities that should only occur within coordinator/implementer agents.

---

## Investigation Summary

### Key Files Analyzed

1. **lean-implement-output.md** (lines 28-114): Shows coordinator invocation → partial success → primary agent takeover
2. **lean-implement.md** (lines 1-1453): Command structure with Block 1a/1a-classify/1b/1c/2
3. **lean-coordinator.md** (lines 1-952): Coordinator responsibilities and wave-based orchestration
4. **lean-implementer.md** (lines 1-827): Implementer proof workflow
5. **Plan 001** (lines 1-1010): Original refactor plan showing Phase 0-7 complete, Phase 8-9-10 deferred
6. **Plan 002** (lines 1-719): Deferred phases plan for wave-based delegation and plan revision

### Timeline of Events (from lean-implement-output.md)

1. **Line 28**: Primary agent invokes lean-coordinator via Task tool for Phase 1 ✅ CORRECT
2. **Lines 31-33**: lean-coordinator executes successfully (29 tool uses, 5m 34s duration) ✅ CORRECT
3. **Lines 42-44**: Coordinator returns partial success: "4/5 theorems proven but main deduction_theorem needs complex induction proof completed" ⚠️ EXPECTED
4. **Lines 48-56**: Primary agent reads DeductionTheorem.lean file directly ❌ DELEGATION VIOLATION
5. **Lines 58-67**: Primary agent reads Derivation.lean and analyzes proof structure ❌ DELEGATION VIOLATION
6. **Lines 69-70**: Primary agent states "Let me implement the deduction theorem properly" ❌ DELEGATION VIOLATION
7. **Lines 72-106**: Primary agent calls lean_goal, lean_multi_attempt MCP tools and performs Edit operations directly ❌ DELEGATION VIOLATION

---

## Root Cause Identification

### Primary Root Cause: Missing Hard Barrier After Block 1c

**Location**: `/lean-implement.md` Block 1c (lines 862-1221)

**Problem**: Block 1c performs hard barrier verification (summary file existence, size check) and parses continuation signals, but **does not enforce a return to Block 1b for re-delegation when work_remaining is non-empty**.

**Expected Behavior**:
```markdown
## Block 1c: Verification & Continuation Decision

[Parse summary...]
[Validate work_remaining...]

if [ -n "$WORK_REMAINING_NEW" ]; then
  echo "**ITERATION LOOP**: Return to Block 1b with updated state"
  # PRIMARY AGENT MUST NOT PROCEED TO DIRECT WORK
  # HARD BARRIER: ONLY COORDINATORS PERFORM IMPLEMENTATION
fi
```

**Actual Behavior**:
The primary agent observes the coordinator's partial success and `work_remaining` field, but instead of returning to Block 1b for re-delegation, it proceeds to:
1. Read Lean files directly
2. Analyze proof structures
3. Call lean_goal and lean_multi_attempt MCP tools
4. Edit Lean files with proof implementations

**Evidence from Output**:
- **Line 35-36**: "Let me check the summary file that was created and verify the status" → Primary agent acknowledging coordinator completion
- **Line 42-46**: Primary agent reads summary, interprets partial status, decides to "check the current state" → NO delegation signal
- **Line 48-70**: Primary agent performs 3 Read operations + analysis → Coordinator/implementer responsibilities
- **Line 106**: Primary agent performs Edit operation → Implementer-only responsibility

### Contributing Factor 1: Iteration Decision Logic Position

**Location**: Block 1c (lines 1161-1220)

**Problem**: The iteration decision logic appears at the END of Block 1c, after all parsing and validation. However, the command documentation states:
```markdown
echo "**ITERATION LOOP**: Return to Block 1b with updated state"
```

This suggests the loop should return BEFORE the primary agent can perform any additional operations.

**Gap**: No explicit exit or jump mechanism after the iteration decision that would prevent the primary agent from continuing to Block 2 or performing ad-hoc work.

### Contributing Factor 2: Coordinator Return Signal Ambiguity

**Location**: lean-coordinator.md output signal (lines 707-756)

**Coordinator Output Signal** (from summary file):
```yaml
coordinator_type: lean
summary_brief: "Completed Wave 1-2 (Phase 1,2) with 15 theorems. Context: 72%. Next: Continue Wave 3."
phases_completed: [1, 2]
theorem_count: 15
work_remaining: Phase_3 Phase_4
context_exhausted: false
context_usage_percent: 72
requires_continuation: true
```

**Ambiguity**: The `work_remaining` field clearly indicates incomplete work, but the command's interpretation logic does not treat this as a **mandatory re-delegation signal**.

**Expected Interpretation**:
- `work_remaining` non-empty → MUST invoke coordinator again (return to Block 1b)
- `requires_continuation: true` → MUST NOT allow primary agent to perform implementation

**Actual Interpretation**:
- Primary agent reads these fields but does not enforce delegation
- No hard barrier prevents primary agent from continuing to direct work

### Contributing Factor 3: Phase-Based vs Wave-Based Execution

**Location**: Plan 001 Phase 9 (lines 725-831) - NOT IMPLEMENTED

**Original Design Intent**: Transform from per-phase routing to **full plan delegation with wave-based parallel execution**.

**Current State**: Per-phase routing implemented (Phase 0-7 complete), but **wave-based delegation NOT implemented** (Phase 9 deferred to Plan 002).

**Impact on Delegation**:
- Current design: Command routes one phase at a time → Coordinator executes one phase → Returns to command
- Intended design: Command delegates full plan → Coordinator calculates waves → Coordinator orchestrates all waves → Returns when complete or context exhausted

**Gap**: The per-phase routing creates multiple "return points" where the primary agent regains control. Each return point is an opportunity for the delegation pattern to break if the hard barrier is not enforced.

---

## Critical Gap Analysis

### Gap 1: No Hard Barrier Enforcement After Coordinator Return

**Standard Pattern** (from hierarchical-agents-overview.md):
```markdown
## Hard Barrier Pattern

Coordinators MUST be invoked, primary agent MUST NOT perform implementation:

if [ condition ]; then
  # Invoke coordinator
  Task { ... }
  # After return: PRIMARY AGENT STOPS HERE
  exit 0  # or return to dispatch loop
fi
```

**Actual Implementation** (lean-implement.md Block 1c):
```bash
# Parse coordinator output
# Validate summary
# Determine continuation

if [ "$REQUIRES_CONTINUATION" = "true" ]; then
  # Update state for next iteration
  echo "**ITERATION LOOP**: Return to Block 1b"
else
  echo "Proceeding to Block 1d (phase marker recovery)..."
fi
```

**Missing Component**: No exit, return, or jump after the echo statement. The command continues to execute subsequent operations, allowing the primary agent to perform work.

### Gap 2: Block 1c Does Not Validate Delegation Contract

**Location**: Block 1c hard barrier verification (lines 907-962)

**Current Validation**:
1. Summary file exists ✅
2. Summary file size > 100 bytes ✅
3. No TASK_ERROR signal in summary ✅

**Missing Validation**:
4. ❌ Primary agent has NOT called any MCP tools directly
5. ❌ Primary agent has NOT edited any Lean files
6. ❌ Primary agent has NOT performed implementation work
7. ❌ Coordinator output signal is well-formed (required fields present)

**Recommendation**: Add delegation contract validation that asserts:
- Primary agent tool usage = [Bash, Read (summary only), Grep (logs only)]
- No Edit, lean_goal, lean_multi_attempt, or other implementer-specific tools used by primary agent

### Gap 3: Iteration Loop Does Not Return to Block 1b

**Location**: Block 1c iteration decision (lines 1161-1220)

**Expected Flow**:
```
Block 1b (Coordinator Invocation)
  ↓
  Coordinator executes with Task tool
  ↓
Block 1c (Verification)
  ↓
  Parse work_remaining
  ↓
  if work_remaining non-empty:
    ↺ LOOP BACK TO Block 1b (re-invoke coordinator)
  else:
    → Block 2 (Completion Summary)
```

**Actual Flow**:
```
Block 1b (Coordinator Invocation)
  ↓
  Coordinator executes with Task tool
  ↓
Block 1c (Verification)
  ↓
  Parse work_remaining
  ↓
  if work_remaining non-empty:
    echo "Return to Block 1b" (NO ACTUAL RETURN)
    ↓
    Primary agent continues to direct work ❌
```

**Gap**: The iteration loop logic does not actually loop. It only updates state variables and prints a message, but execution continues linearly.

---

## Why Phase 8-9 Deferral Contributed to the Issue

### Phase 8: Coordinator-Triggered Plan Revision (DEFERRED)

**Intended Behavior**: When lean-coordinator encounters blocking dependencies (partial theorems), it should trigger `/revise` command via Task delegation, update the plan, and recalculate waves.

**Impact of Deferral**: Without automated plan revision, the coordinator returns with `theorems_partial` populated, and the primary agent observes this as a signal that **manual intervention is needed**. The primary agent interprets "partial success" as "I should help complete this work" rather than "I should re-invoke the coordinator with updated context."

### Phase 9: Wave-Based Full Plan Delegation (DEFERRED)

**Intended Behavior**: Command delegates the **entire plan** to lean-coordinator, which calculates waves, orchestrates parallel execution, and only returns when:
1. All waves complete
2. Context threshold exceeded (checkpoint saved)
3. Max iterations reached

**Impact of Deferral**: Current per-phase routing creates multiple coordinator invocation cycles. Each cycle is a potential point where the primary agent can "take over" if the hard barrier is not enforced. With full plan delegation, the coordinator would maintain control for the entire workflow duration, eliminating the gap.

**From Plan 002** (lines 109-170):
> Refactor /lean-implement command from sequential per-phase routing to full plan delegation with wave-based parallel execution, achieving 40-60% time savings for plans with independent phases.

**Risk Noted in Plan 002** (lines 661-677):
> ### Risk 2: Coordinator Invocation Failure (HIGH)
> **Description**: Full plan delegation changes coordinator input contract
> **Mitigation**:
> - Hard barrier validation (fail-fast if summary not created)
> - Error return protocol with TASK_ERROR format
> - Input contract validation for all required fields

This risk is currently UNMITIGATED because Phase 9 is not implemented.

---

## Triggering Conditions

The delegation failure occurs when:

1. **Partial Success from Coordinator**: Coordinator returns with `theorems_partial` field populated (some theorems incomplete)
2. **Work Remaining Non-Empty**: `work_remaining` field contains phase identifiers
3. **Requires Continuation True**: `requires_continuation: true` signal present
4. **No Hard Barrier After Block 1c**: Command does not exit or return to Block 1b after parsing continuation signals
5. **Primary Agent Continues Execution**: Without explicit loop or exit, execution proceeds linearly

---

## Evidence of Delegation Pattern Violation

### Standards Reference

**From CLAUDE.md** (hierarchical_agent_architecture section):
> Coordinators are model-invoked autonomous capabilities that Claude automatically uses when relevant needs are detected. Unlike commands (user-invoked) or agents (task delegation), coordinators enable autonomous composition and progressive discovery.

**From hierarchical-agents-coordination.md**:
> **Hard Barrier Pattern**: Coordinators MUST be invoked, primary agent MUST NOT perform implementation work.

### Violation Instances in lean-implement-output.md

| Line | Primary Agent Action | Expected Agent | Violation Type |
|------|---------------------|----------------|----------------|
| 48-49 | Read(Logos/Core/Metalogic/DeductionTheorem.lean) | lean-implementer | File reading for proof analysis |
| 58-59 | Read(Logos/Core/ProofSystem/Derivation.lean) | lean-implementer | Dependency analysis |
| 61-67 | Analysis: "The key insight is that to prove the deduction theorem, we need induction..." | lean-implementer | Proof strategy design |
| 72-80 | lean_goal MCP tool call | lean-implementer | Proof goal extraction (MCP) |
| 82-94 | lean_multi_attempt MCP tool call | lean-implementer | Tactic exploration (MCP) |
| 106-108 | Edit(Logos/Core/Metalogic/DeductionTheorem.lean) with 291 additions | lean-implementer | Proof implementation |

**Total Violations**: 6 distinct instances across 5 tool categories (Read, Analysis, lean_goal, lean_multi_attempt, Edit)

**Context Exhaustion**: By line 106, the primary agent has consumed significant context budget performing work that should have been delegated to lean-implementer via lean-coordinator.

---

## Impact Analysis

### Immediate Impact

1. **Context Window Exhaustion**: Primary agent consumes 200k context budget performing direct implementation work instead of delegating to subagents with fresh context
2. **Workflow Failure**: Command eventually runs out of context and halts, unable to complete remaining phases
3. **Coordinator Underutilization**: lean-coordinator's wave-based orchestration and parallel execution capabilities are bypassed

### Long-Term Impact

1. **Scalability Limitation**: Per-phase routing with primary agent involvement prevents efficient multi-phase workflows
2. **No Parallelization**: Without wave-based delegation (Phase 9), independent phases cannot execute in parallel (40-60% time savings missed)
3. **Manual Intervention Required**: User must checkpoint/resume or manually fix partial proofs instead of automated coordinator retry

---

## Recommended Fixes

### Fix 1: Enforce Hard Barrier After Block 1c (HIGH PRIORITY)

**Location**: Block 1c, after iteration decision (line ~1220)

**Add Exit Enforcement**:
```bash
# === ITERATION DECISION ===
if [ "$REQUIRES_CONTINUATION" = "true" ] && [ -n "$WORK_REMAINING_NEW" ]; then
  NEXT_ITERATION=$((ITERATION + 1))

  # Update state for next iteration
  append_workflow_state "ITERATION" "$NEXT_ITERATION"
  append_workflow_state "WORK_REMAINING" "$WORK_REMAINING_NEW"

  echo "**ITERATION LOOP**: Returning to Block 1b for re-delegation"

  # HARD BARRIER: PRIMARY AGENT STOPS HERE
  # MUST NOT PROCEED TO DIRECT IMPLEMENTATION WORK
  # Execution will resume at Block 1b on next agent invocation
  exit 0
fi
```

**Rationale**: The `exit 0` ensures the primary agent terminates after updating state for the next iteration. The command framework will resume at Block 1b when the next iteration begins.

### Fix 2: Add Delegation Contract Validation (MEDIUM PRIORITY)

**Location**: Block 1c, after hard barrier verification (line ~962)

**Add Primary Agent Tool Usage Audit**:
```bash
# === VALIDATE DELEGATION CONTRACT ===
# Primary agent MUST NOT perform implementation work
# Allowed tools: Bash (orchestration), Read (summary only), Grep (logs only)
# Prohibited tools: Edit, lean_goal, lean_multi_attempt, lean_build

PRIMARY_AGENT_TOOLS=$(grep -E "^● (Edit|lean-lsp|Update)\(" "$WORKFLOW_LOG" | wc -l)

if [ "$PRIMARY_AGENT_TOOLS" -gt 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Delegation contract violation: Primary agent performed $PRIMARY_AGENT_TOOLS implementation operations" \
    "bash_block_1c" \
    "$(jq -n --arg tools "$PRIMARY_AGENT_TOOLS" '{prohibited_tool_uses: $tools}')"

  echo "ERROR: Delegation contract violation detected" >&2
  echo "  Primary agent used implementation tools that should be delegated to coordinators" >&2
  exit 1
fi

echo "[OK] Delegation contract validated: No implementation work by primary agent"
```

**Rationale**: This validation ensures the primary agent has not performed any implementation work that should have been delegated. It provides early detection of delegation pattern violations.

### Fix 3: Implement Wave-Based Full Plan Delegation (HIGH PRIORITY - Phase 9)

**Location**: Plan 002, Phase 9 (lines 109-449)

**Recommendation**: Prioritize Phase 9 implementation to eliminate per-phase routing and enforce full plan delegation.

**Key Changes**:
1. Block 1a: Pass full plan to coordinator (not single phase)
2. lean-coordinator: Integrate dependency-analyzer.sh for wave calculation
3. lean-coordinator: Implement wave execution loop with parallel Task invocations
4. Block 1c: Only parse coordinator return signal once (when all waves complete or context exhausted)

**Benefit**: Eliminates multiple return points where primary agent can take over. Coordinator maintains control for entire workflow duration.

### Fix 4: Add Coordinator Output Signal Validation (LOW PRIORITY)

**Location**: Block 1c, after summary parsing (line ~1054)

**Validate Required Fields**:
```bash
# === VALIDATE COORDINATOR OUTPUT SIGNAL ===
REQUIRED_FIELDS="coordinator_type summary_brief phases_completed work_remaining context_usage_percent requires_continuation"

for field in $REQUIRED_FIELDS; do
  if ! grep -q "^${field}:" "$LATEST_SUMMARY"; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Coordinator output missing required field: $field" \
      "bash_block_1c" \
      "$(jq -n --arg field "$field" --arg coord "$COORDINATOR_NAME" \
         '{missing_field: $field, coordinator: $coord}')"

    echo "ERROR: Coordinator output signal malformed" >&2
    exit 1
  fi
done

echo "[OK] Coordinator output signal validated: All required fields present"
```

**Rationale**: Ensures coordinator output conforms to the contract, preventing ambiguous signals that might lead to delegation failures.

---

## Testing Recommendations

### Test Case 1: Partial Success Re-Delegation

**Setup**:
1. Lean plan with 3 phases
2. Phase 1: 5 theorems (coordinator proves 4/5, returns partial success)
3. Phase 2-3: Dependent on Phase 1 completion

**Expected Behavior**:
1. Iteration 1: lean-coordinator invoked for Phase 1, returns `work_remaining: Phase_1` (1 theorem incomplete)
2. Block 1c: Parse continuation signals, **EXIT** with `exit 0` after updating state
3. Iteration 2: Resume at Block 1b, re-invoke lean-coordinator with `continuation_context`
4. lean-coordinator: Complete remaining theorem, return `work_remaining: Phase_2 Phase_3`
5. Block 1c: Verify all Phase 1 theorems complete, continue to next phase

**Validation**:
- Primary agent NEVER calls lean_goal, lean_multi_attempt, or Edit tools
- All implementation work performed by lean-implementer (via lean-coordinator)
- Iteration loop correctly returns to Block 1b on each continuation

### Test Case 2: Context Threshold Checkpoint Save

**Setup**:
1. Set `CONTEXT_THRESHOLD=50` for testing
2. Lean plan with 10 phases
3. Simulate high context usage after Phase 5

**Expected Behavior**:
1. Iterations 1-5: Coordinator completes phases 1-5
2. Iteration 5: `context_usage_percent=65` exceeds threshold
3. Block 1c: Save checkpoint, set `requires_continuation=false`
4. Block 1c: EXIT with `exit 0` (halt workflow)
5. User resumes with `--resume=<checkpoint>` flag
6. Iteration 6: Resume at Block 1b with fresh context, continue phases 6-10

**Validation**:
- Checkpoint saved when threshold exceeded
- Workflow halts cleanly (no context exhaustion crash)
- Resume restores all state correctly

### Test Case 3: Delegation Contract Violation Detection

**Setup**:
1. Inject mock primary agent tool usage (Edit, lean_goal) into workflow log
2. Run Block 1c delegation contract validation

**Expected Behavior**:
1. Validation detects prohibited tool usage
2. Error logged with `validation_error` type
3. Command exits with error code 1
4. Clear error message indicates delegation violation

**Validation**:
- Validation catches all prohibited tool categories
- Error message identifies specific tools used
- Error logged to errors.jsonl with structured data

---

## Related Issues and Context

### Issue 1: Phase 8 Plan Revision Deferral

**From Plan 001** (lines 638-723):
> Phase 8: Implement Coordinator-Triggered Plan Revision Workflow [IN PROGRESS]
>
> **Deferral Note**: This phase requires significant lean-coordinator behavioral changes and is an enhancement feature rather than core functionality.

**Impact**: Without automated plan revision, partial success scenarios (like Phase 1 with 4/5 theorems proven) do not trigger plan updates. The primary agent may interpret this as a signal to "help complete" rather than "revise plan and re-delegate."

**Recommendation**: Implement Phase 8 in conjunction with Fix 1 to ensure partial success triggers either:
- Automated plan revision (Phase 8), OR
- Re-delegation with continuation context (Fix 1)

### Issue 2: Phase 9 Wave-Based Delegation Deferral

**From Plan 002** (lines 1-46):
> This plan implements the three deferred phases from spec 047: coordinator-triggered plan revision (Phase 8), wave-based full plan delegation (Phase 9), and comprehensive integration testing (Phase 10).

**Impact**: Per-phase routing creates multiple "handoff points" between primary agent and coordinators. Each handoff is an opportunity for delegation to break if hard barriers are not enforced.

**Recommendation**: Prioritize Phase 9 implementation to:
1. Eliminate per-phase routing
2. Enforce single coordinator invocation per workflow
3. Enable wave-based parallel execution (40-60% time savings)

---

## Conclusion

The root cause of the delegation failure is a **missing hard barrier after Block 1c verification** that allows the primary agent to continue execution after a coordinator returns with partial success. The command correctly invokes lean-coordinator via Task delegation (Block 1b), and the coordinator correctly returns structured output signals (summary file with `work_remaining` populated). However, the iteration decision logic in Block 1c does not enforce a strict return to Block 1b for re-delegation.

**Critical Fix**: Add `exit 0` after iteration decision when `requires_continuation=true` to enforce the hard barrier pattern and prevent primary agent from performing implementation work.

**Strategic Fix**: Implement Phase 9 (wave-based full plan delegation) from Plan 002 to eliminate per-phase routing and reduce the number of primary agent handoffs.

**Validation Fix**: Add delegation contract validation to detect and block primary agent tool usage that violates the coordinator pattern.

---

## Appendices

### Appendix A: Command Block Structure

**From lean-implement.md**:
```
Block 1a: Setup & Phase Classification (lines 48-418)
Block 1a-classify: Phase Classification and Routing Map Construction (lines 420-651)
Block 1b: Route to Coordinator [HARD BARRIER] (lines 653-848)
Block 1c: Verification & Continuation Decision (lines 862-1221)
Block 1d: Phase Marker Management (DELEGATED TO COORDINATORS) (lines 1223-1235)
Block 2: Completion & Summary (lines 1237-1453)
```

### Appendix B: Coordinator Output Signal Contract

**From lean-coordinator.md** (lines 707-756):
```yaml
PROOF_COMPLETE:
  coordinator_type: lean
  summary_path: /path/to/summaries/NNN_proof_summary.md
  summary_brief: "Completed Wave 1-2 (Phase 1,2) with 15 theorems. Context: 72%. Next: Continue Wave 3."
  phases_completed: [1, 2]
  theorem_count: N
  plan_file: /path/to/plan.md
  lean_file: /path/to/file.lean
  topic_path: /path/to/topic
  context_exhausted: true|false
  work_remaining: Phase_4 Phase_5 Phase_6  # Space-separated string
  context_usage_percent: N%
  checkpoint_path: /path/to/checkpoint (if created)
  requires_continuation: true|false
  stuck_detected: true|false
```

### Appendix C: Delegation Pattern Standards

**From CLAUDE.md** (hierarchical_agent_architecture section):
> **Hard Barrier Pattern**: Coordinators MUST be invoked, primary agent MUST NOT perform implementation work. The primary agent's role is orchestration only—routing phases to coordinators, parsing return signals, managing iteration state, and enforcing checkpoints.

---

**Report Status**: Complete
**Next Steps**: Share with user, recommend Fix 1 as immediate hotfix, recommend Phase 9 as strategic solution
