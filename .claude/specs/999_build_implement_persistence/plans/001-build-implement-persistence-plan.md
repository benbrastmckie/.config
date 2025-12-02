# /implement Command Persistence Enhancement Implementation Plan

## Metadata
- **Date**: 2025-12-01 (Revised: 2025-12-01)
- **Feature**: Add /build-style persistence to /implement command
- **Scope**: Enhance /implement command to iterate through phases until completion, matching /build behavior
- **Estimated Phases**: 4
- **Estimated Hours**: 5-7 hours (revised from 4-6 hours to include standards compliance enhancements)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 35.0
- **Structure Level**: 0
- **Research Reports**:
  - [/build and /implement Persistence Research](/home/benjamin/.config/.claude/specs/999_build_implement_persistence/reports/001-build-implement-persistence-research.md)
  - [Standards Compliance Review](/home/benjamin/.config/.claude/specs/999_build_implement_persistence/reports/002-standards-compliance-review.md)

## Revision History

### Revision 1 (2025-12-01)
**Reason**: Standards compliance review identified 3 high-priority enhancements

**Changes Made**:
1. **Phase 1 Enhancement**: Added error logging integration for iteration loop
   - Log execution_error when max_iterations exceeded
   - Log agent_error on implementer-coordinator timeout
   - Log state_error when iteration variables not restored
   - Duration increased from 1 hour to 1.5 hours

2. **Phase 3 Enhancement**: Added test isolation verification
   - Implement TEST_ROOT isolation pattern with CLAUDE_SPECS_ROOT and CLAUDE_PROJECT_DIR
   - Add test case 4 for checkpoint resumption during iteration
   - Verify cleanup trap prevents production directory pollution
   - Duration increased from 2-3 hours to 2.5-3 hours

3. **Phase 4 Enhancement**: Added checkpoint format validation
   - Verify iteration checkpoints follow 3-line format
   - Document checkpoint format in command guide
   - Include checkpoint validation in smoke test
   - Duration increased from 1 hour to 1.5 hours

**Total Impact**: Estimated hours revised from 4-6 hours to 5-7 hours

## Overview

The /implement command currently stops after phases complete, while /build orchestrates subagents iteratively until plans are complete. Both commands share identical iteration detection logic, but differ in their response to continuation signals from implementer-coordinator. This plan adds explicit iteration loop enforcement to /implement, making the loop architecturally explicit rather than relying on implicit markdown instruction interpretation.

## Research Summary

Key findings from research analysis:

1. **Common Infrastructure**: Both commands share identical iteration setup (Block 1a) and detection code (Block 1c), including:
   - ITERATION loop variables (ITERATION, CONTINUATION_CONTEXT, LAST_WORK_REMAINING, STUCK_COUNT)
   - State persistence for iteration parameters
   - Identical completion/continuation logic based on implementer-coordinator signals

2. **Critical Difference**: End of Block 1c iteration decision:
   - **BUILD**: Includes "EXECUTE NOW" directive after iteration decision, explicitly directing Claude to loop back to Block 1b
   - **IMPLEMENT**: Documents iteration decision but proceeds directly to Block 1d without conditional execution enforcement

3. **Root Cause**: The difference is NOT in bash code but in markdown instruction interpretation. /build succeeds in looping because its markdown structure strongly directs Claude to repeat Block 1b when continuation is required, while /implement simply documents the decision and flows linearly.

4. **Solution Pattern**: Make iteration loop architecturally explicit through:
   - Conditional markdown instruction that checks IMPLEMENTATION_STATUS
   - Explicit "EXECUTE NOW" directive for continuation case
   - Re-invocation of Block 1b Task with updated iteration variables
   - Verification step before allowing flow to Block 1d

## Success Criteria

- [ ] /implement command loops through multiple iterations when work_remaining exists
- [ ] Iteration decision enforces conditional execution (continuing → loop, complete → proceed)
- [ ] Updated iteration variables (ITERATION, CONTINUATION_CONTEXT) passed to coordinator
- [ ] Existing checkpoint resumption functionality preserved
- [ ] Command maintains backward compatibility with single-iteration plans
- [ ] Block structure follows code standards (consolidated bash blocks, suppressed output)
- [ ] Integration tests verify multi-iteration execution

## Technical Design

### Architecture Overview

The fix adds a conditional markdown block between Block 1c and Block 1d that:

1. **Checks IMPLEMENTATION_STATUS** from Block 1c state
2. **Conditionally loops** back to Block 1b when status is "continuing"
3. **Explicitly re-invokes** implementer-coordinator Task with updated variables
4. **Re-verifies** in Block 1c after each iteration
5. **Allows flow to Block 1d** only when status is "complete", "stuck", or "max_iterations"

### Implementation Strategy

**Option 1: Inline Conditional Markdown Block** (Recommended)

Insert conditional instruction section after Block 1c that explicitly directs Claude's execution path based on IMPLEMENTATION_STATUS. This matches /build's pattern and is the most direct fix.

**Location**: /home/benjamin/.config/.claude/commands/implement.md, lines 875-877

**Current Block 1c Exit**:
```markdown
**ITERATION DECISION**:
- If IMPLEMENTATION_STATUS is "continuing", repeat the Task invocation above with updated ITERATION
- If IMPLEMENTATION_STATUS is "complete", "stuck", or "max_iterations", proceed to phase update block (Block 1d)

## Block 1d: Phase Update
```

**Proposed Enhancement**:
```markdown
**ITERATION DECISION**:

Check the IMPLEMENTATION_STATUS from Block 1c iteration check:

**If IMPLEMENTATION_STATUS is "continuing"**: Work remains and context available. Loop back to Block 1b.

**EXECUTE NOW**: The implementer-coordinator reported work remaining and sufficient context. Repeat the Task invocation from Block 1b with updated iteration variables:

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
    - artifact_paths:
      - reports: ${TOPIC_PATH}/reports/
      - plans: ${TOPIC_PATH}/plans/
      - summaries: ${TOPIC_PATH}/summaries/
      - debug: ${TOPIC_PATH}/debug/
      - outputs: ${TOPIC_PATH}/outputs/
      - checkpoints: ${HOME}/.claude/data/checkpoints/
    - continuation_context: ${CONTINUATION_CONTEXT}
    - iteration: ${NEXT_ITERATION}

    **CRITICAL**: You MUST create implementation summary at ${TOPIC_PATH}/summaries/
    The orchestrator will validate the summary exists after you return.

    Workflow-Specific Context:
    - Starting Phase: ${STARTING_PHASE}
    - Workflow Type: implement-only
    - Execution Mode: wave-based (parallel where possible)
    - Current Iteration: ${NEXT_ITERATION}/${MAX_ITERATIONS}
    - Max Iterations: ${MAX_ITERATIONS}
    - Context Threshold: ${CONTEXT_THRESHOLD}%
    - Continuation Context: ${CONTINUATION_CONTEXT}
    - Work Remaining: ${WORK_REMAINING}

    Progress Tracking Instructions:
    - Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
    - Before starting each phase: add_in_progress_marker '$PLAN_FILE' <phase_num>
    - After completing each phase: mark_phase_complete '$PLAN_FILE' <phase_num> && add_complete_marker '$PLAN_FILE' <phase_num>
    - This creates visible progress: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]

    Execute remaining implementation phases according to the plan.

    IMPORTANT: After completing phases or if context exhaustion detected:
    - Create a summary in summaries/ directory
    - Summary must have Work Status at TOP showing completion percentage
    - Summary MUST include Testing Strategy section with:
      - Test Files Created (list of test files written during Testing phases)
      - Test Execution Requirements (how to run tests, framework used)
      - Coverage Target (expected coverage percentage)
    - Return summary path in completion signal

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
  "
}

After the Task returns, **proceed to Block 1c verification** to check for further continuation needs.

---

**If IMPLEMENTATION_STATUS is "complete", "stuck", or "max_iterations"**: Proceed to Block 1d.

## Block 1d: Phase Update
```

### Key Design Decisions

1. **Markdown-Based Loop Control**: Uses markdown instructions to direct Claude's execution path, matching /build's proven pattern
2. **Explicit Task Re-Invocation**: Full Task invocation block in conditional section ensures all parameters are visible and updated
3. **State Variable Visibility**: Uses state variables (${NEXT_ITERATION}, ${CONTINUATION_CONTEXT}) from Block 1c for updated context
4. **Continuation Context Pass-Through**: Passes iteration summary to next iteration for context continuity
5. **Verification Loop**: After Task returns, explicitly directs back to Block 1c for re-verification
6. **Hard Barrier Preservation**: Maintains hard barrier pattern - Block 1c verification runs after EVERY iteration

### Compatibility Considerations

1. **Backward Compatibility**: Plans that complete in single iteration flow unchanged (IMPLEMENTATION_STATUS = "complete" on first check)
2. **Checkpoint Resumption**: Existing checkpoint logic in Block 1a unaffected (runs before iteration loop)
3. **Max Iterations Safety**: Iteration count enforcement in Block 1c prevents infinite loops
4. **Stuck Detection**: implementer-coordinator's stuck detection preserved (work_remaining unchanged across iterations)

### Alternative Approaches Considered

**Option 2: Bash-Driven Loop Block** - Rejected because:
- Bash blocks cannot conditionally skip markdown sections
- Would require restructuring command execution model
- Less maintainable than markdown-based control flow

**Option 3: External Loop Script** - Rejected because:
- Breaks command self-containment
- Adds deployment complexity
- Harder to debug and maintain

## Implementation Phases

### Phase 1: Add Conditional Iteration Block [COMPLETE]
dependencies: []

**Objective**: Insert conditional markdown block after Block 1c that enforces iteration loop when IMPLEMENTATION_STATUS is "continuing"

**Complexity**: Low

**Tasks**:
- [x] Read current /implement command structure (file: /home/benjamin/.config/.claude/commands/implement.md)
- [x] Locate Block 1c iteration decision section (lines 875-877)
- [x] Create enhanced iteration decision markdown block with:
  - [x] Conditional check for IMPLEMENTATION_STATUS
  - [x] "EXECUTE NOW" directive for continuation case
  - [x] Full Task invocation block with updated variables
  - [x] Explicit return to Block 1c after Task completes
  - [x] Fallthrough to Block 1d for terminal states
- [x] Integrate error logging into iteration loop:
  - [x] Add log_command_error for max_iterations exceeded condition
  - [x] Add log_command_error for agent timeout during iteration
  - [x] Add log_command_error for state restoration failures (ITERATION variable not found)
  - [x] Error types: execution_error (max iterations), agent_error (timeout), state_error (restoration)
- [x] Use Edit tool to replace lines 875-877 with enhanced block
- [x] Verify block follows output formatting standards (consolidated blocks, suppressed output)

**Testing**:
```bash
# Verify markdown structure is valid
grep -A 50 "ITERATION DECISION" /home/benjamin/.config/.claude/commands/implement.md | head -60

# Check for "EXECUTE NOW" directive in continuation case
grep -q "EXECUTE NOW.*continuation" /home/benjamin/.config/.claude/commands/implement.md

# Verify error logging integration
grep -q "log_command_error" /home/benjamin/.config/.claude/commands/implement.md
grep -c "execution_error\|agent_error\|state_error" /home/benjamin/.config/.claude/commands/implement.md
# Expected: 3 error types
```

**Expected Duration**: 1.5 hours

### Phase 2: Validate Iteration Variable Propagation [COMPLETE]
dependencies: [1]

**Objective**: Ensure iteration variables (NEXT_ITERATION, CONTINUATION_CONTEXT, WORK_REMAINING) are correctly passed from Block 1c to repeated Block 1b invocation

**Complexity**: Low

**Tasks**:
- [x] Review Block 1c iteration setup (lines 830-853) to identify state variables set
- [x] Verify new conditional block references correct variable names:
  - [x] ${NEXT_ITERATION} for iteration counter
  - [x] ${CONTINUATION_CONTEXT} for summary path
  - [x] ${WORK_REMAINING} for incomplete phases
  - [x] ${CLAUDE_PROJECT_DIR} for project root
  - [x] ${PLAN_FILE} for plan path
  - [x] ${TOPIC_PATH} for topic directory
  - [x] ${MAX_ITERATIONS} for iteration limit
  - [x] ${CONTEXT_THRESHOLD} for context limit
- [x] Compare variable usage with /build command for consistency (file: /home/benjamin/.config/.claude/commands/build.md, lines 854-859)
- [x] Verify state persistence calls in Block 1c save variables used in loop (lines 842-845)

**Testing**:
```bash
# Extract variable references from new conditional block
grep -oP '\$\{[A-Z_]+\}' /home/benjamin/.config/.claude/commands/implement.md | sort -u > /tmp/loop_vars.txt

# Compare with variables set in Block 1c
grep -A 30 "append_workflow_state" /home/benjamin/.config/.claude/commands/implement.md | grep -oP '"[A-Z_]+"' | sort -u > /tmp/state_vars.txt

# Check for variable mismatches
diff /tmp/loop_vars.txt /tmp/state_vars.txt
```

**Expected Duration**: 1 hour

### Phase 3: Create Integration Test [COMPLETE]
dependencies: [1, 2]

**Objective**: Create integration test that validates multi-iteration execution behavior

**Complexity**: Medium

**Tasks**:
- [x] Create test file: /home/benjamin/.config/.claude/tests/integration/test_implement_iteration.sh
- [x] Implement test isolation pattern:
  - [x] Create TEST_ROOT="/tmp/test_isolation_$$"
  - [x] Set CLAUDE_SPECS_ROOT="$TEST_ROOT/.claude/specs"
  - [x] Set CLAUDE_PROJECT_DIR="$TEST_ROOT"
  - [x] Register cleanup trap: trap 'rm -rf "$TEST_ROOT"' EXIT
  - [x] Verify both variables set to avoid production directory pollution
- [x] Implement test setup:
  - [x] Create test plan with 10 phases (should require 2-3 iterations)
  - [x] Create test topic directory structure in TEST_ROOT
  - [x] Mock implementer-coordinator output for multi-iteration scenario
- [x] Implement test case 1: Multi-iteration completion
  - [x] Invoke /implement on test plan
  - [x] Verify Block 1b invoked multiple times (check iteration counter in state)
  - [x] Verify IMPLEMENTATION_STATUS transitions: continuing → continuing → complete
  - [x] Verify all phases marked [COMPLETE] in plan file
- [x] Implement test case 2: Single-iteration backward compatibility
  - [x] Invoke /implement on small plan (3 phases)
  - [x] Verify single Task invocation
  - [x] Verify IMPLEMENTATION_STATUS = "complete" after first iteration
  - [x] Verify Block 1d runs immediately
- [x] Implement test case 3: Max iterations safety
  - [x] Mock coordinator to always return requires_continuation=true
  - [x] Verify /implement halts at MAX_ITERATIONS
  - [x] Verify IMPLEMENTATION_STATUS = "max_iterations"
- [x] Implement test case 4: Checkpoint resumption during iteration
  - [x] Create checkpoint after first iteration
  - [x] Resume /implement from checkpoint
  - [x] Verify iteration counter restored correctly
  - [x] Verify continuation context path preserved
- [x] Add cleanup verification:
  - [x] Verify TEST_ROOT cleaned up via trap
  - [x] Verify no production directory pollution (ls $CLAUDE_SPECS_ROOT returns test path)

**Testing**:
```bash
# Run integration test
bash /home/benjamin/.config/.claude/tests/integration/test_implement_iteration.sh

# Verify test passes (exit code 0)
echo $?

# Verify test isolation (no production pollution)
[ -d "/tmp/test_isolation_*" ] && echo "ERROR: Test directory not cleaned up"

# Check test coverage
grep -c "test_" /home/benjamin/.config/.claude/tests/integration/test_implement_iteration.sh
# Expected: 4 test cases

# Verify test isolation pattern implemented
grep -q "TEST_ROOT.*test_isolation" /home/benjamin/.config/.claude/tests/integration/test_implement_iteration.sh
grep -q "CLAUDE_SPECS_ROOT.*TEST_ROOT" /home/benjamin/.config/.claude/tests/integration/test_implement_iteration.sh
grep -q "CLAUDE_PROJECT_DIR.*TEST_ROOT" /home/benjamin/.config/.claude/tests/integration/test_implement_iteration.sh
```

**Expected Duration**: 2.5-3 hours

### Phase 4: Documentation and Validation [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Update documentation and perform final validation

**Complexity**: Low

**Tasks**:
- [x] Update /implement command guide (file: /home/benjamin/.config/.claude/docs/guides/commands/implement-command-guide.md):
  - [x] Add section on iteration behavior
  - [x] Document IMPLEMENTATION_STATUS states
  - [x] Explain continuation context mechanism
  - [x] Add example of multi-iteration execution
  - [x] Document checkpoint format for iterations (3-line structure)
  - [x] Include iteration checkpoint example with ITERATION and CONTINUATION_CONTEXT in Context line
- [x] Update CLAUDE.md command reference if needed (file: /home/benjamin/.config/CLAUDE.md)
- [x] Run validation scripts:
  - [x] bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --sourcing
  - [x] bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --conditionals
- [x] Validate checkpoint format compliance:
  - [x] Verify iteration checkpoints follow 3-line format: [CHECKPOINT] line, Context line, Ready for line
  - [x] Verify Context line includes ITERATION and CONTINUATION_CONTEXT variables
  - [x] Verify Ready for line specifies "Next iteration" or "Phase update"
  - [x] Test checkpoint output during iteration loop
- [x] Perform manual smoke test:
  - [x] Create real test plan with 8 phases
  - [x] Run /implement and observe iteration behavior
  - [x] Verify summary created after each iteration
  - [x] Verify continuation context passed between iterations
  - [x] Verify checkpoint format in console output

**Testing**:
```bash
# Validate command structure
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --all

# Verify checkpoint format compliance
grep -A 2 "\[CHECKPOINT\].*Iteration" /home/benjamin/.config/.claude/commands/implement.md
# Expected: 3-line format with Context and Ready for lines

# Run manual smoke test
# (manual execution and observation)

# Verify documentation updated
grep -q "iteration behavior" /home/benjamin/.config/.claude/docs/guides/commands/implement-command-guide.md
grep -q "checkpoint format" /home/benjamin/.config/.claude/docs/guides/commands/implement-command-guide.md
```

**Expected Duration**: 1.5 hours

## Testing Strategy

### Unit Testing

No unit tests required - changes are markdown-based command structure modifications.

### Integration Testing

**Test Suite**: /home/benjamin/.config/.claude/tests/integration/test_implement_iteration.sh

**Test Cases**:
1. **Multi-iteration execution**: Verify looping behavior with large plan
2. **Single-iteration compatibility**: Verify small plans complete in one iteration
3. **Max iterations safety**: Verify iteration limit enforcement
4. **Checkpoint resumption during iteration**: Verify iteration counter and continuation context restored correctly
5. **Test isolation verification**: Verify no production directory pollution

**Coverage Target**: 100% of iteration decision paths

**Test Isolation Requirements**:
- TEST_ROOT="/tmp/test_isolation_$$"
- CLAUDE_SPECS_ROOT="$TEST_ROOT/.claude/specs"
- CLAUDE_PROJECT_DIR="$TEST_ROOT"
- Cleanup trap: trap 'rm -rf "$TEST_ROOT"' EXIT

### Manual Testing

**Smoke Test**:
1. Create test plan with 8-10 phases
2. Run: `/implement /path/to/test/plan.md`
3. Observe console output for iteration messages
4. Verify multiple "Iteration N/M" messages
5. Verify all phases marked [COMPLETE]
6. Verify implementation summary shows 100% completion

**Validation**:
- Check state file after each iteration for ITERATION counter increment
- Verify continuation context file created in workspace
- Confirm Block 1c verification runs after each iteration
- Verify Block 1d runs only after final iteration

## Documentation Requirements

### New Documentation

**File**: /home/benjamin/.config/.claude/docs/guides/commands/implement-command-guide.md

**New Section**: Iteration Behavior

**Content**:
- How iteration decision works
- IMPLEMENTATION_STATUS states (continuing, complete, stuck, max_iterations)
- Continuation context mechanism
- Max iterations configuration
- Stuck detection behavior
- Example multi-iteration execution

### Updated Documentation

**File**: /home/benjamin/.config/CLAUDE.md

**Section**: Command Reference → /implement

**Updates**:
- Add note about multi-iteration support
- Link to iteration behavior documentation

## Dependencies

### Internal Dependencies

- **implementer-coordinator agent**: Must return accurate requires_continuation signal
- **Block 1c verification logic**: Must correctly detect continuation needs
- **State persistence**: Must reliably save/load iteration variables
- **Hard barrier pattern**: Verification must run after every iteration

### External Dependencies

None - changes are self-contained within /implement command

## Risk Assessment

### Technical Risks

1. **Infinite Loop Risk**
   - **Mitigation**: MAX_ITERATIONS enforcement in Block 1c (existing)
   - **Severity**: Low (existing safeguard)

2. **State Persistence Failure**
   - **Mitigation**: State validation in Block 1c (existing)
   - **Severity**: Low (tested infrastructure)

3. **Markdown Parsing Ambiguity**
   - **Mitigation**: Explicit "EXECUTE NOW" directive matches /build pattern
   - **Severity**: Low (proven pattern)

4. **Backward Compatibility Break**
   - **Mitigation**: Single-iteration plans flow unchanged
   - **Severity**: Very Low (design preserves existing behavior)

### Testing Risks

1. **Integration Test Complexity**
   - **Mitigation**: Mock implementer-coordinator output for predictability
   - **Severity**: Medium

2. **Manual Test Time**
   - **Mitigation**: Automate as much validation as possible
   - **Severity**: Low

## Success Metrics

- [ ] /implement successfully loops through multiple iterations on large plans
- [ ] Integration tests pass with 100% coverage of iteration paths
- [ ] Standards validation scripts pass (sourcing, conditionals)
- [ ] Smoke test shows expected iteration behavior
- [ ] Documentation clearly explains iteration mechanism
- [ ] No regressions on single-iteration plans (backward compatibility)

## Notes

### Design Rationale

The markdown-based conditional instruction approach is preferred because:

1. **Proven Pattern**: Matches /build command's working implementation
2. **Minimal Complexity**: No new bash logic or state machine changes
3. **Maintainable**: Conditional logic is explicit and visible in markdown
4. **Debuggable**: Iteration flow is clear from command structure
5. **Self-Contained**: No external scripts or complex state management

### Standards Compliance

This plan has been reviewed against project standards and incorporates the following compliance enhancements:

1. **Error Logging Standards**: Integrated centralized error logging for iteration loop failures (execution_error, agent_error, state_error)
2. **Testing Protocols**: Implemented test isolation pattern to prevent production directory pollution (TEST_ROOT with CLAUDE_SPECS_ROOT and CLAUDE_PROJECT_DIR overrides)
3. **Output Formatting Standards**: Added checkpoint format validation for 3-line structure with iteration context

See [Standards Compliance Review](/home/benjamin/.config/.claude/specs/999_build_implement_persistence/reports/002-standards-compliance-review.md) for detailed analysis.

### Future Enhancements

Consider for future iterations:

1. **Dynamic Iteration Limit**: Allow plans to specify custom MAX_ITERATIONS in metadata
2. **Iteration Telemetry**: Track average iterations per plan for optimization insights
3. **Parallel Iteration**: Support multiple plans iterating concurrently (requires locking)

### Related Specifications

- **Spec 998**: Repair /implement (WORK_REMAINING format conversion) - Related iteration logic
- **Spec 993**: /build command workflow refactor - Source of iteration pattern
- **Hard Barrier Pattern**: /home/benjamin/.config/.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md

---

**Implementation Plan Version**: 1.1
**Created By**: plan-architect agent
**Created**: 2025-12-01
**Last Revised**: 2025-12-01 (Revision 1: Standards compliance enhancements)
**Revised By**: plan-architect agent
