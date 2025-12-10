# Debug Strategy: Subagent Phase Update Contract Gap

## Metadata
- **Date**: 2025-12-09
- **Feature**: Fix phase marker updates in /lean-implement delegation chain
- **Status**: [IN PROGRESS]
- **Estimated Hours**: 3-5 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Root Cause Analysis](../reports/001-root-cause-analysis.md)
- **Complexity Score**: 24.5
- **Structure Level**: 0

## Overview

This debug strategy addresses the contract gap in the /lean-implement workflow where subagents (lean-coordinator and lean-implementer) fail to update phase markers in real-time. The root cause analysis identified that /lean-implement Block 1b does not include progress tracking instructions in the coordinator Task prompt, despite lean-coordinator expecting these instructions per its behavioral guidelines (lines 314-334).

## Research Summary

The root cause analysis revealed a three-layer delegation chain with a critical contract gap:

1. **Layer 1 (Orchestrator)**: `/lean-implement` correctly delegates marker management to coordinators (Block 1d, lines 1373-1385)
2. **Layer 2 (Coordinator)**: `lean-coordinator` expects progress tracking instructions in input prompt (lines 314-334) but never receives them
3. **Layer 3 (Worker)**: `lean-implementer` has marker update capability (STEP 0/STEP 9) but conditions never met because plan_path/phase_number parameters not provided

The recommended fix is to add progress tracking instructions to the coordinator Task prompt in /lean-implement Block 1b.

## Success Criteria
- [ ] Root cause verified by examining actual Task invocation in lean-implement Block 1b
- [ ] Fix implemented by adding progress tracking instructions to coordinator prompt
- [ ] Test plan executed showing real-time marker transitions during /lean-implement execution
- [ ] All three test cases pass (fresh execution, partial resume, marker recovery)
- [ ] Documentation updated to reflect contract requirements

## Technical Design

### Verification Approach

Confirm root cause by:
1. Reading /lean-implement Block 1b (lines 842-896) to locate coordinator prompt construction
2. Verifying absence of progress tracking instructions in COORDINATOR_PROMPT variable
3. Cross-referencing with lean-coordinator expectations (lines 314-334)
4. Documenting exact line ranges where instructions should be added

### Implementation Approach

Add progress tracking instructions after the continuation_context line (line 876) in Block 1b:

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

### Testing Approach

Three test cases to validate fix:

1. **Test Case 1: Fresh Plan Execution**
   - Create minimal 3-phase Lean plan
   - Execute with `/lean-implement plan.md`
   - Monitor markers during execution: `watch -n 2 'grep "^### Phase" plan.md'`
   - Verify real-time transitions: [NOT STARTED] → [IN PROGRESS] → [COMPLETE]

2. **Test Case 2: Partial Execution Resume**
   - Execute plan that exceeds context threshold (triggers checkpoint)
   - Resume with `/lean-implement --resume=checkpoint.json`
   - Verify continued phases show [IN PROGRESS] markers
   - Verify completed phases retain [COMPLETE] markers

3. **Test Case 3: Graceful Degradation**
   - Temporarily rename checkbox-utils.sh to simulate unavailable library
   - Execute plan
   - Verify execution continues without fatal errors
   - Verify warning messages about unavailable progress tracking
   - Restore checkbox-utils.sh and verify normal operation

## Implementation Phases

### Phase 1: Root Cause Verification [COMPLETE]
dependencies: []

**Objective**: Confirm the exact location and nature of the missing progress tracking instructions.

**Complexity**: Low

**Tasks**:
- [x] Read /lean-implement.md Block 1b (lines 842-896) to examine COORDINATOR_PROMPT construction
- [x] Verify absence of progress tracking instructions in the prompt template
- [x] Read lean-coordinator.md lines 314-334 to confirm expected instruction format
- [x] Document exact line number where instructions should be inserted (after line 876)
- [x] Create verification report documenting findings

**Testing**:
```bash
# Verify Block 1b structure
grep -A 50 "## Block 1b: Lean Coordinator Delegation" .claude/commands/lean-implement.md | grep -E "(COORDINATOR_PROMPT|continuation_context|progress_tracking)"

# Verify coordinator expectations
grep -A 20 "Progress Tracking Instruction Forwarding" .claude/agents/lean-coordinator.md
```

**Expected Duration**: 0.5 hours

### Phase 2: Implement Progress Tracking Instructions [COMPLETE]
dependencies: [1]

**Objective**: Add progress tracking instructions to coordinator Task prompt in /lean-implement Block 1b.

**Complexity**: Medium

**Tasks**:
- [x] Locate insertion point in /lean-implement.md after line 876 (continuation_context)
- [x] Add progress_tracking metadata section with enabled flag and paths
- [x] Add "Progress Tracking Instructions" section with 4-step process
- [x] Verify instruction format matches lean-coordinator expectations (lines 314-334)
- [x] Ensure graceful degradation note included for unavailable checkbox-utils
- [x] Validate bash variable substitution syntax (${PLAN_FILE}, ${CLAUDE_PROJECT_DIR})

**Testing**:
```bash
# Verify instructions added correctly
grep -A 20 "progress_tracking:" .claude/commands/lean-implement.md

# Verify instruction format matches coordinator expectations
diff <(grep -A 10 "Progress Tracking Instructions" .claude/commands/lean-implement.md | sed 's/PLAN_FILE/plan_path/g') \
     <(grep -A 10 "Progress Tracking Instructions" .claude/agents/lean-coordinator.md)

# Validate no syntax errors in bash block
bash -n .claude/commands/lean-implement.md 2>&1 | grep -i error
```

**Expected Duration**: 1 hour

### Phase 3: Test Fresh Plan Execution [COMPLETE]
dependencies: [2]

**Objective**: Validate real-time marker updates during fresh plan execution.

**Complexity**: Medium

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test-results.txt", "marker-timeline.log"]

**Tasks**:
- [x] Create minimal test plan: 3 Lean phases with simple theorems
- [x] Execute plan with `/lean-implement test-plan.md`
- [x] Monitor markers in parallel: `watch -n 2 'grep "^### Phase" test-plan.md' > marker-timeline.log &`
- [x] Validate marker transitions appear in timeline log
- [x] Parse timeline log to confirm sequence: [NOT STARTED] → [IN PROGRESS] → [COMPLETE]
- [x] Archive timeline log as test artifact

**Validation**:
```bash
# Create test plan with 3 simple phases
cat > /tmp/test-phase-markers.md <<'EOF'
# Test Phase Marker Updates

## Metadata
- **Date**: 2025-12-09
- **Status**: [IN PROGRESS]

## Implementation Phases

### Phase 1: Simple Theorem [COMPLETE]
dependencies: []
Tasks:
- [x] Prove: theorem test1 : True := trivial

### Phase 2: Another Theorem [COMPLETE]
dependencies: [1]
Tasks:
- [x] Prove: theorem test2 : 1 + 1 = 2 := rfl

### Phase 3: Final Theorem [COMPLETE]
dependencies: [2]
Tasks:
- [x] Prove: theorem test3 : ∀ n : Nat, n = n := fun n => rfl
EOF

# Execute plan and capture marker timeline
(watch -n 2 'date; grep "^### Phase" /tmp/test-phase-markers.md' > /tmp/marker-timeline.log &)
WATCH_PID=$!

/lean-implement /tmp/test-phase-markers.md
EXIT_CODE=$?

# Kill watch process
kill $WATCH_PID 2>/dev/null

# Validate transitions occurred
test $EXIT_CODE -eq 0 || exit 1

# Check timeline log shows marker transitions
grep -q "\[IN PROGRESS\]" /tmp/marker-timeline.log || exit 1
grep -q "\[COMPLETE\]" /tmp/marker-timeline.log || exit 1

# Verify final state: all phases complete
COMPLETE_COUNT=$(grep -c "\[COMPLETE\]" /tmp/test-phase-markers.md)
test $COMPLETE_COUNT -eq 3 || exit 1

echo "✓ Test Case 1: Fresh plan execution marker updates validated"
```

**Expected Duration**: 1.5 hours

### Phase 4: Test Partial Execution Resume [IN PROGRESS]
dependencies: [3]

**Objective**: Validate marker persistence and resume behavior with checkpoint continuation.

**Complexity**: High

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["checkpoint.json", "resume-results.txt"]

**Tasks**:
- [ ] Create plan with 6 phases to exceed context threshold
- [ ] Execute plan until checkpoint triggered (max-iterations=2)
- [ ] Verify checkpoint.json created with partial completion state
- [ ] Validate phases 1-2 marked [COMPLETE], phases 3-6 still [NOT STARTED]
- [ ] Resume execution with `--resume=checkpoint.json`
- [ ] Verify phases 3-4 transition to [IN PROGRESS] then [COMPLETE]
- [ ] Validate phases 1-2 retain [COMPLETE] markers (no regression)

**Validation**:
```bash
# Create 6-phase plan to trigger checkpoint
cat > /tmp/test-resume-markers.md <<'EOF'
# Test Resume Marker Persistence

## Metadata
- **Date**: 2025-12-09
- **Status**: [IN PROGRESS]

## Implementation Phases

### Phase 1: Foundation [COMPLETE]
dependencies: []
Tasks:
- [x] Prove: theorem resume1 : True := trivial

### Phase 2: Layer 2 [COMPLETE]
dependencies: [1]
Tasks:
- [x] Prove: theorem resume2 : 1 = 1 := rfl

### Phase 3: Layer 3 [COMPLETE]
dependencies: [2]
Tasks:
- [x] Prove: theorem resume3 : 2 = 2 := rfl

### Phase 4: Layer 4 [IN PROGRESS]
dependencies: [3]
Tasks:
- [ ] Prove: theorem resume4 : 3 = 3 := rfl

### Phase 5: Layer 5 [IN PROGRESS]
dependencies: [4]
Tasks:
- [ ] Prove: theorem resume5 : 4 = 4 := rfl

### Phase 6: Final [NOT STARTED]
dependencies: [5]
Tasks:
- [ ] Prove: theorem resume6 : 5 = 5 := rfl
EOF

# Execute with limited iterations to force checkpoint
/lean-implement /tmp/test-resume-markers.md --max-iterations=2
CHECKPOINT_EXISTS=$?

# Verify checkpoint created
test -f .claude/specs/*/checkpoints/checkpoint.json || exit 1

# Capture partial completion state
COMPLETE_AFTER_CHECKPOINT=$(grep -c "\[COMPLETE\]" /tmp/test-resume-markers.md)
test $COMPLETE_AFTER_CHECKPOINT -ge 1 || exit 1
test $COMPLETE_AFTER_CHECKPOINT -lt 6 || exit 1

echo "Checkpoint state: $COMPLETE_AFTER_CHECKPOINT phases complete"

# Resume execution
/lean-implement --resume=.claude/specs/*/checkpoints/checkpoint.json
RESUME_EXIT=$?

test $RESUME_EXIT -eq 0 || exit 1

# Validate final state: all phases complete
FINAL_COMPLETE=$(grep -c "\[COMPLETE\]" /tmp/test-resume-markers.md)
test $FINAL_COMPLETE -eq 6 || exit 1

# Verify no marker regressions (phases don't go backward)
! grep -q "\[COMPLETE\].*\[IN PROGRESS\]" /tmp/test-resume-markers.md || exit 1

echo "✓ Test Case 2: Resume marker persistence validated"
```

**Expected Duration**: 2 hours

### Phase 5: Test Graceful Degradation [IN PROGRESS]
dependencies: [3]

**Objective**: Verify execution continues without fatal errors when checkbox-utils unavailable.

**Complexity**: Low

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["degradation-test.log"]

**Tasks**:
- [ ] Create backup of checkbox-utils.sh
- [ ] Temporarily rename checkbox-utils.sh to simulate unavailable library
- [ ] Execute simple 2-phase plan
- [ ] Capture stderr output to verify warning messages emitted
- [ ] Validate plan execution completes successfully (exit code 0)
- [ ] Verify markers NOT updated (remain [NOT STARTED]) due to unavailable library
- [ ] Restore checkbox-utils.sh from backup
- [ ] Re-execute same plan to verify markers now update correctly

**Validation**:
```bash
# Backup checkbox-utils.sh
cp .claude/lib/plan/checkbox-utils.sh .claude/lib/plan/checkbox-utils.sh.backup

# Simulate unavailable library
mv .claude/lib/plan/checkbox-utils.sh .claude/lib/plan/checkbox-utils.sh.disabled

# Create simple test plan
cat > /tmp/test-degradation.md <<'EOF'
# Test Graceful Degradation

## Metadata
- **Date**: 2025-12-09
- **Status**: [IN PROGRESS]

## Implementation Phases

### Phase 1: Test Degradation [COMPLETE]
dependencies: []
Tasks:
- [x] Prove: theorem degrade1 : True := trivial

### Phase 2: Verify Warnings [COMPLETE]
dependencies: [1]
Tasks:
- [x] Prove: theorem degrade2 : 1 = 1 := rfl
EOF

# Execute plan and capture warnings
/lean-implement /tmp/test-degradation.md 2> /tmp/degradation-warnings.log
EXIT_CODE=$?

# Verify execution succeeded despite unavailable library
test $EXIT_CODE -eq 0 || exit 1

# Verify warning messages emitted
grep -q "Progress tracking unavailable" /tmp/degradation-warnings.log || exit 1

# Verify markers NOT updated (library unavailable)
COMPLETE_DEGRADED=$(grep -c "\[COMPLETE\]" /tmp/test-degradation.md)
test $COMPLETE_DEGRADED -eq 0 || exit 1

echo "✓ Graceful degradation: execution succeeded without marker updates"

# Restore library
mv .claude/lib/plan/checkbox-utils.sh.disabled .claude/lib/plan/checkbox-utils.sh

# Re-execute to verify normal marker updates
/lean-implement /tmp/test-degradation.md
NORMAL_EXIT=$?

test $NORMAL_EXIT -eq 0 || exit 1

# Verify markers NOW updated (library restored)
COMPLETE_NORMAL=$(grep -c "\[COMPLETE\]" /tmp/test-degradation.md)
test $COMPLETE_NORMAL -eq 2 || exit 1

echo "✓ Test Case 3: Graceful degradation validated"
```

**Expected Duration**: 1 hour

## Testing Strategy

All test phases use automated validation with programmatic exit code checks. No manual verification required. Test artifacts (timeline logs, checkpoints, warning logs) are archived for debugging if tests fail.

### Test Execution Order
1. Phase 3: Fresh execution (baseline validation)
2. Phase 5: Graceful degradation (error handling validation)
3. Phase 4: Partial resume (complex state persistence validation)

### Success Criteria
- All bash validation blocks exit with code 0
- No manual intervention required during test execution
- Test artifacts generated for forensic analysis if failures occur

## Documentation Requirements

After implementation and testing, update the following documentation:

1. **lean-implement.md**:
   - Add comment in Block 1b explaining progress tracking instructions
   - Reference lean-coordinator contract requirements (lines 314-334)

2. **lean-coordinator.md**:
   - Add validation note confirming /lean-implement now provides instructions
   - Update example Task invocation to show actual instruction format

3. **lean-implementer.md**:
   - Add troubleshooting section for marker update failures
   - Document conditions when STEP 0 and STEP 9 execute vs skip

4. **Root cause analysis report**:
   - Add "Implementation Status" section with plan link
   - Mark status as "Fix Implemented" after Phase 2 completion

## Dependencies

- checkbox-utils.sh library must be available at `.claude/lib/plan/checkbox-utils.sh`
- /lean-implement command must support plan-based execution mode
- lean-coordinator must have Task tool access for subagent invocations
- Test plans require valid Lean 4 syntax (minimal theorems for validation)

## Risk Management

### Risk 1: Backward Compatibility
**Mitigation**: Progress tracking instructions are additive (non-breaking). Coordinators already expect these instructions per behavioral guidelines, so adding them fulfills existing contract.

### Risk 2: Performance Impact
**Impact**: ~200 tokens added per coordinator invocation
**Mitigation**: Minimal context cost for significant UX improvement (real-time progress visibility)

### Risk 3: Checkbox-utils Unavailable
**Mitigation**: Implementer already has graceful degradation logic (STEP 0 lines 109-111). Test Case 3 validates this behavior.

### Risk 4: Test Plan Lean Syntax Errors
**Mitigation**: Use trivial theorems with known-correct syntax (True := trivial, n = n := rfl). These are guaranteed to compile in Lean 4.
