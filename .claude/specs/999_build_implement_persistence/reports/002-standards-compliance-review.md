# Standards Compliance Review: Build-Implement Persistence Plan

## Metadata

- **Date**: 2025-12-01
- **Reviewer**: research-specialist agent
- **Plan File**: /home/benjamin/.config/.claude/specs/999_build_implement_persistence/plans/001-build-implement-persistence-plan.md
- **Review Type**: Standards compliance verification
- **Complexity**: 2

## Executive Summary

This report reviews the implementation plan for /implement command persistence enhancement against project standards documented in .claude/docs/reference/standards/. The plan proposes adding markdown-based conditional iteration logic to match /build command's proven pattern.

**Overall Assessment**: Plan is largely compliant with project standards, with minor enhancements recommended in 4 areas.

**Critical Findings**:
- No blocking issues identified
- Plan follows established patterns from /build command
- Testing strategy is comprehensive
- Documentation requirements are met

**Recommended Enhancements**:
1. Add explicit error logging integration to iteration loop
2. Include checkpoint format compliance in Phase 4 validation
3. Document edge case for empty CONTINUATION_CONTEXT
4. Add integration test for checkpoint resumption during iteration

## Plan Overview Analysis

### Proposed Changes

The plan adds a conditional markdown block between Block 1c (verification) and Block 1d (phase update) that:

1. Checks IMPLEMENTATION_STATUS from state
2. Conditionally loops back to Block 1b when status is "continuing"
3. Explicitly re-invokes implementer-coordinator Task with updated variables
4. Re-verifies in Block 1c after each iteration
5. Allows flow to Block 1d only when status is terminal (complete/stuck/max_iterations)

**Pattern Source**: Matches /build command's proven iteration pattern (lines 854-859 per plan)

### Standards Coverage

Plan explicitly references these standards:
- Command authoring standards (Task invocation, execution directives)
- Output formatting (consolidated blocks, suppressed output)
- Testing protocols (integration tests, coverage targets)
- Code standards (bash block patterns)

## Standards Compliance Analysis

### 1. Command Authoring Standards Compliance

**Standard Document**: /home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md

#### 1.1 Execution Directive Requirements

**Status**: COMPLIANT

**Evidence from Plan**:
- Phase 1 includes "EXECUTE NOW" directive in conditional block (line 87)
- Follows established /build pattern with explicit imperative instruction
- No bare code blocks without execution directives

**Standard Reference**: Lines 28-66 of command-authoring.md require all bash blocks preceded by explicit execution directive

**Plan Quote**:
> **EXECUTE NOW**: The implementer-coordinator reported work remaining and sufficient context. Repeat the Task invocation from Block 1b with updated iteration variables

#### 1.2 Task Tool Invocation Patterns

**Status**: COMPLIANT

**Evidence from Plan**:
- Task invocation uses correct pattern (no code block wrapper)
- Includes "USE the Task tool" imperative instruction (line 87)
- Inline prompt with variable interpolation
- Completion signal requirement specified

**Standard Reference**: Lines 93-166 of command-authoring.md prohibit Task {} pseudo-syntax wrapped in code blocks

**Plan Quote**:
> Task {
>   subagent_type: "general-purpose"
>   description: "Execute implementation plan..."
>   prompt: "
>     Read and follow ALL behavioral guidelines from:
>     ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

**Compliance Notes**:
- No ` ```yaml ` wrapper (correct)
- Imperative instruction present (correct)
- Variables interpolated directly (correct)

#### 1.3 Subprocess Isolation Requirements

**Status**: COMPLIANT (via existing Block 1a/1b/1c implementation)

**Evidence**:
- Plan acknowledges subprocess isolation in design decisions
- References existing Block 1a library re-sourcing (no changes needed)
- Iteration loop uses state variables from Block 1c

**Standard Reference**: Lines 169-231 of command-authoring.md require library re-sourcing in every block

**Plan Assumption**: Block 1a/1b/1c already follow three-tier sourcing pattern (verified via existing /implement command)

#### 1.4 State Persistence Patterns

**Status**: COMPLIANT

**Evidence from Plan**:
- Plan uses state variables set by Block 1c (NEXT_ITERATION, CONTINUATION_CONTEXT, WORK_REMAINING)
- References state persistence in Phase 2 validation (line 247)
- Acknowledges state machine variables used across blocks

**Standard Reference**: Lines 232-273 of command-authoring.md require file-based state communication

**Plan Quote**:
> Verify state persistence calls in Block 1c save variables used in loop (lines 842-845)

**Enhancement Recommendation**: Add explicit verification that iteration variables are persisted in Block 1c before conditional block reads them.

#### 1.5 Argument Capture Patterns

**Status**: N/A (not changed by plan)

**Evidence**: Plan does not modify existing argument capture in Block 1a

#### 1.6 Output Suppression Requirements

**Status**: COMPLIANT

**Evidence from Plan**:
- Phase 1 explicitly requires following output formatting standards (line 217)
- Plan references consolidated blocks and suppressed output (line 48)

**Standard Reference**: Lines 681-901 of command-authoring.md require output suppression and block consolidation

**Plan Quote**:
> Verify block follows output formatting standards (consolidated blocks, suppressed output)

#### 1.7 Prohibited Patterns (if ! and elif !)

**Status**: COMPLIANT

**Evidence**: Plan's conditional block uses markdown instruction, not bash conditionals

**Standard Reference**: Lines 1100-1193 of command-authoring.md prohibit negation in bash conditionals due to history expansion

**Compliance Notes**: Plan avoids bash conditionals entirely by using markdown-based control flow (correct approach)

### 2. Output Formatting Standards Compliance

**Standard Document**: /home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md

#### 2.1 Output Suppression Patterns

**Status**: COMPLIANT

**Evidence from Plan**:
- Phase 1 task includes verification that block follows output formatting standards (line 217)
- References suppressed output in success criteria (line 48)

**Standard Reference**: Lines 40-206 of output-formatting.md require suppression of success messages, library sourcing, directory operations

**Enhancement Recommendation**: Add specific guidance to suppress iteration loop progress messages (e.g., "Iteration 2 starting...") unless DEBUG mode enabled

#### 2.2 Block Consolidation Patterns

**Status**: COMPLIANT

**Evidence from Plan**:
- Plan adds conditional iteration block inline (no new bash blocks)
- Maintains existing 5-block structure (1a, 1b, 1c, 1d, 2)
- Does not fragment execution into excessive blocks

**Standard Reference**: Lines 208-260 of output-formatting.md target 2-3 bash blocks maximum

**Plan Structure**:
- Block 1a: Setup (existing)
- Block 1b: Execute (modified to be repeatable)
- Block 1c: Verify (existing)
- Conditional markdown block: Iteration decision (NEW - no bash block)
- Block 1d: Phase update (existing)
- Block 2: Completion (existing)

**Compliance Notes**: Conditional block is markdown-only (not a bash block), so total bash block count remains 5 (within acceptable range for complex workflows)

#### 2.3 Checkpoint Reporting Format

**Status**: NEEDS ENHANCEMENT

**Finding**: Plan does not explicitly address checkpoint format compliance

**Standard Reference**: Lines 277-497 of output-formatting.md specify checkpoint format requirements

**Required Checkpoint Format**:
```bash
echo "[CHECKPOINT] {Phase Name} complete"
echo "Context: {KEY}={VALUE}, {KEY}={VALUE}"
echo "Ready for: {Next Action}"
```

**Enhancement Recommendation**: Add checkpoint compliance verification to Phase 4 validation:
- Verify iteration checkpoints follow 3-line format
- Include ITERATION, CONTINUATION_CONTEXT in Context line
- Specify "Ready for: Next iteration" or "Ready for: Phase update"

#### 2.4 Comment Standards (WHAT Not WHY)

**Status**: COMPLIANT

**Evidence from Plan**:
- Phase 1 includes verification step for output formatting standards (line 217)
- Plan does not propose adding WHY-style comments

**Standard Reference**: Lines 499-543 of output-formatting.md require WHAT not WHY comments

**Compliance Notes**: Conditional block uses markdown instructions (documentation), not bash comments, so this standard applies minimally

#### 2.5 Console Summary Standards

**Status**: COMPLIANT (via existing Block 2 implementation)

**Evidence**: Plan does not modify console summary format in Block 2

**Standard Reference**: Lines 587-849 of output-formatting.md specify 4-section console summary format

**Assumption**: Existing /implement Block 2 already complies with console summary standards

### 3. Code Standards Compliance

**Standard Document**: /home/benjamin/.config/.claude/docs/reference/standards/code-standards.md

#### 3.1 Bash Block Sourcing Pattern

**Status**: COMPLIANT (via existing implementation)

**Evidence**: Plan does not modify library sourcing in existing blocks

**Standard Reference**: Lines 34-87 of code-standards.md require three-tier sourcing pattern

**Assumption**: Existing Block 1a/1b/1c already implement three-tier sourcing

#### 3.2 Error Logging Requirements

**Status**: NEEDS ENHANCEMENT

**Finding**: Plan does not explicitly integrate error logging into iteration loop

**Standard Reference**: Lines 88-161 of code-standards.md require centralized error logging

**Required Error Types for Iteration Loop**:
- `state_error`: ITERATION variable not restored from state
- `agent_error`: implementer-coordinator iteration timeout
- `execution_error`: Iteration loop exceeded max iterations

**Enhancement Recommendation**: Add Phase 1 task to integrate error logging:
```bash
# In conditional block after detecting continuation
if [ "$IMPLEMENTATION_STATUS" = "continuing" ]; then
  # Log iteration start
  append_workflow_state "ITERATION_START_TIME" "$(date +%s)"

  # If iteration exceeds max, log before halt
  if [ "$NEXT_ITERATION" -gt "$MAX_ITERATIONS" ]; then
    log_command_error "/implement" "$WORKFLOW_ID" "$USER_ARGS" \
      "execution_error" "Max iterations exceeded" "iteration_loop" \
      "$(jq -n --arg iter "$NEXT_ITERATION" --arg max "$MAX_ITERATIONS" \
         '{iteration: $iter, max_iterations: $max}')"
  fi
fi
```

**Plan Impact**: Minor - add error logging to Phase 1 implementation tasks

#### 3.3 Output Suppression Patterns

**Status**: COMPLIANT (cross-reference with Section 2.1)

**Evidence**: Covered in Output Formatting Standards section above

#### 3.4 Directory Creation Anti-Patterns

**Status**: COMPLIANT (not applicable)

**Evidence**: Plan does not create directories (only modifies control flow)

#### 3.5 Executable/Documentation Separation

**Status**: COMPLIANT

**Evidence from Plan**:
- Phase 4 includes updating implement-command-guide.md with iteration behavior documentation (line 316)
- Keeps implementation in implement.md (executable)
- Documents behavior in guide file (documentation)

**Standard Reference**: Lines 277-299 of code-standards.md require separation of executable logic from comprehensive documentation

**Plan Quote**:
> Update /implement command guide (file: /home/benjamin/.config/.claude/docs/guides/commands/implement-command-guide.md):
>   - Add section on iteration behavior

### 4. Testing Protocols Compliance

**Standard Document**: /home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md

#### 4.1 Test Discovery

**Status**: COMPLIANT

**Evidence from Plan**:
- Phase 3 creates integration test file at standard location: .claude/tests/integration/test_implement_iteration.sh (line 272)

**Standard Reference**: Lines 10-23 of testing-protocols.md specify .claude/tests/ location with test_*.sh pattern

#### 4.2 Coverage Requirements

**Status**: COMPLIANT

**Evidence from Plan**:
- Phase 3 specifies coverage target: "100% of iteration decision paths" (line 362)
- Exceeds baseline 60% and modified code 80% thresholds

**Standard Reference**: Lines 34-39 of testing-protocols.md require ≥80% for modified code, ≥60% baseline

**Plan Quote**:
> **Coverage Target**: 100% of iteration decision paths

#### 4.3 Test Writing Responsibility

**Status**: COMPLIANT

**Evidence from Plan**:
- Phase 3 writes tests during implementation (not during test execution)
- Follows implement-then-test separation pattern

**Standard Reference**: Lines 40-72 of testing-protocols.md require tests written during implementation phases

**Compliance Notes**: Plan creates test file in Phase 3 (implementation), to be executed later via test runner

#### 4.4 Test Isolation Standards

**Status**: NEEDS ENHANCEMENT

**Finding**: Plan does not explicitly address test isolation patterns

**Standard Reference**: Lines 306-368 of testing-protocols.md require environment overrides to prevent production directory pollution

**Required Test Isolation Pattern**:
```bash
# In test_implement_iteration.sh setup
TEST_ROOT="/tmp/test_isolation_$$"
mkdir -p "$TEST_ROOT/.claude/specs"
export CLAUDE_SPECS_ROOT="$TEST_ROOT/.claude/specs"
export CLAUDE_PROJECT_DIR="$TEST_ROOT"

trap 'rm -rf "$TEST_ROOT"' EXIT
```

**Enhancement Recommendation**: Add Phase 3 task to verify test file includes proper isolation:
- Set CLAUDE_SPECS_ROOT and CLAUDE_PROJECT_DIR to temporary directories
- Register cleanup trap
- Validate no production directory pollution after test run

**Common Mistake to Avoid** (per lines 317-342 of testing-protocols.md):
```bash
# WRONG: Only CLAUDE_SPECS_ROOT set, CLAUDE_PROJECT_DIR points to production
export CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"
export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"  # This causes pollution!

# CORRECT: Both variables point to temporary directories
export CLAUDE_SPECS_ROOT="$TEST_ROOT/.claude/specs"
export CLAUDE_PROJECT_DIR="$TEST_ROOT"
```

#### 4.5 Integration Test Structure

**Status**: COMPLIANT

**Evidence from Plan**:
- Phase 3 specifies 3 test cases (multi-iteration, single-iteration, max iterations)
- Includes cleanup logic (line 291)
- Documents test execution verification (lines 294-303)

**Standard Reference**: Lines 41-72 of testing-protocols.md require integration tests for complex workflows

**Plan Test Cases**:
1. Multi-iteration completion (verify looping)
2. Single-iteration backward compatibility
3. Max iterations safety (verify halt)

**Enhancement Recommendation**: Add 4th test case for checkpoint resumption during iteration (verify resumption picks up correct iteration counter)

### 5. Documentation Standards Compliance

**Standard Document**: /home/benjamin/.config/.claude/docs/reference/standards/documentation-standards.md

#### 5.1 README Requirements

**Status**: N/A (not applicable)

**Evidence**: Plan does not create new directories requiring READMEs

#### 5.2 Documentation Format Standards

**Status**: COMPLIANT

**Evidence from Plan**:
- Phase 4 includes guide updates with iteration behavior documentation (line 316)
- Follows standard guide structure (explains WHAT and WHY)

**Standard Reference**: Lines 335-384 of documentation-standards.md specify format standards

#### 5.3 Documentation Updates

**Status**: COMPLIANT

**Evidence from Plan**:
- Phase 4 updates implement-command-guide.md (line 316)
- Updates CLAUDE.md command reference if needed (line 321)

**Standard Reference**: Lines 397-432 of documentation-standards.md require updates when changing functionality

**Plan Quote**:
> Update /implement command guide (file: /home/benjamin/.config/.claude/docs/guides/commands/implement-command-guide.md):
>   - Add section on iteration behavior
>   - Document IMPLEMENTATION_STATUS states
>   - Explain continuation context mechanism

## Cross-Standard Integration Analysis

### Interaction: Command Authoring + Output Formatting

**Integration Point**: Conditional markdown block execution

**Standards Involved**:
- Command Authoring: Requires execution directive for Task invocation
- Output Formatting: Requires suppressed interim output, single summary per block

**Plan Compliance**:
- Conditional block includes "EXECUTE NOW" directive (command authoring ✓)
- No verbose iteration logging proposed (output formatting ✓)

**Enhancement Opportunity**: Clarify that iteration counter should only be displayed in checkpoint format, not as separate echo statements

### Interaction: Code Standards + Testing Protocols

**Integration Point**: Error logging in iteration loop

**Standards Involved**:
- Code Standards: Require error logging for all error exit points
- Testing Protocols: Require test isolation to prevent production pollution

**Plan Compliance**:
- Testing: Phase 3 creates integration test (✓)
- Error Logging: Not explicitly integrated into iteration loop (needs enhancement)

**Enhancement Recommendation**: Add error logging integration task to Phase 1 (see Section 3.2 above)

### Interaction: Command Authoring + State Persistence

**Integration Point**: Variable availability across conditional block boundaries

**Standards Involved**:
- Command Authoring: Subprocess isolation requires state persistence
- State Persistence: File-based communication between blocks

**Plan Compliance**:
- Phase 2 includes state variable validation (line 247)
- Acknowledges state persistence in design (line 173)

**Verification Needed**: Ensure Block 1c persists ALL variables used in conditional block:
- NEXT_ITERATION
- CONTINUATION_CONTEXT
- WORK_REMAINING
- IMPLEMENTATION_STATUS
- CLAUDE_PROJECT_DIR
- PLAN_FILE
- TOPIC_PATH
- MAX_ITERATIONS
- CONTEXT_THRESHOLD

**Plan Quote**:
> Verify state persistence calls in Block 1c save variables used in loop (lines 842-845)

## Gap Analysis

### Critical Gaps (Must Fix Before Implementation)

**None identified**

### Recommended Enhancements (Should Address)

1. **Error Logging Integration** (Section 3.2)
   - Add error logging to iteration loop
   - Log max_iterations exceeded condition
   - Log agent timeout during iteration

2. **Test Isolation Compliance** (Section 4.4)
   - Add test isolation verification to Phase 3
   - Ensure CLAUDE_PROJECT_DIR and CLAUDE_SPECS_ROOT both set
   - Verify cleanup trap registered

3. **Checkpoint Format Compliance** (Section 2.3)
   - Add checkpoint format validation to Phase 4
   - Verify 3-line checkpoint structure
   - Include iteration variables in Context line

4. **Edge Case: Empty CONTINUATION_CONTEXT** (Section 4.5)
   - Add test case for checkpoint resumption during iteration
   - Verify iteration counter restoration
   - Document behavior when continuation context missing

### Optional Improvements (Nice to Have)

1. **Iteration Telemetry**
   - Log iteration count and context usage to enable future optimization
   - Track average iterations per plan complexity score
   - Create metrics for stuck detection tuning

2. **Dynamic Iteration Limit**
   - Allow plans to specify custom MAX_ITERATIONS in metadata
   - Override via --max-iterations flag (already supported)
   - Document best practices for iteration limit selection

3. **Explicit Iteration Checkpoints**
   - Add checkpoint after each iteration completes
   - Format: `[CHECKPOINT] Iteration N complete`
   - Include WORK_REMAINING summary in checkpoint

## Standards Reference Matrix

| Plan Section | Standard Document | Section | Compliance Status |
|--------------|------------------|---------|-------------------|
| Phase 1: Conditional Block | command-authoring.md | Execution Directive Requirements | COMPLIANT |
| Phase 1: Task Invocation | command-authoring.md | Task Tool Invocation Patterns | COMPLIANT |
| Phase 1: Output Suppression | output-formatting.md | Output Suppression Patterns | COMPLIANT |
| Phase 2: Variable Validation | command-authoring.md | State Persistence Patterns | COMPLIANT |
| Phase 3: Integration Test | testing-protocols.md | Test Discovery | COMPLIANT |
| Phase 3: Coverage Target | testing-protocols.md | Coverage Requirements | COMPLIANT |
| Phase 3: Test Isolation | testing-protocols.md | Test Isolation Standards | NEEDS ENHANCEMENT |
| Phase 4: Documentation | documentation-standards.md | Documentation Updates | COMPLIANT |
| Phase 4: Validation Scripts | code-standards.md | Enforcement | COMPLIANT |
| Error Logging Integration | code-standards.md | Error Logging Requirements | NEEDS ENHANCEMENT |
| Checkpoint Format | output-formatting.md | Checkpoint Reporting Format | NEEDS ENHANCEMENT |

## Recommendations Summary

### High Priority (Address Before Implementation)

1. **Add Error Logging Integration** (Phase 1)
   - Integrate log_command_error for max_iterations condition
   - Log agent_error if implementer-coordinator times out during iteration
   - Add state_error if iteration variables not restored

2. **Add Test Isolation Verification** (Phase 3)
   - Verify test file sets CLAUDE_PROJECT_DIR and CLAUDE_SPECS_ROOT
   - Add cleanup trap registration
   - Document isolation pattern in test header

3. **Add Checkpoint Format Validation** (Phase 4)
   - Verify iteration checkpoints follow 3-line format
   - Include ITERATION and CONTINUATION_CONTEXT in Context line
   - Document checkpoint examples in guide update

### Medium Priority (Address During Implementation)

4. **Add Checkpoint Resumption Test Case** (Phase 3)
   - Test case 4: Verify checkpoint resumption during iteration
   - Ensure iteration counter restored correctly
   - Validate continuation context path preserved

### Low Priority (Future Enhancement)

5. **Document Empty CONTINUATION_CONTEXT Behavior**
   - What happens if continuation context file doesn't exist?
   - Should iteration proceed or fail?
   - Add to troubleshooting section in guide

## Compliance Verification Checklist

Use this checklist during implementation to ensure standards compliance:

### Phase 1: Conditional Iteration Block
- [ ] Conditional block includes "EXECUTE NOW" directive
- [ ] Task invocation has no code block wrapper
- [ ] Imperative instruction precedes Task invocation
- [ ] Variables interpolated inline (not via external files)
- [ ] Completion signal requirement specified
- [ ] Error logging integrated for max_iterations condition
- [ ] Output suppression verified (no verbose iteration logging)

### Phase 2: Variable Validation
- [ ] All state variables identified (NEXT_ITERATION, CONTINUATION_CONTEXT, etc.)
- [ ] State persistence calls verified in Block 1c
- [ ] Variable references in conditional block match state variables
- [ ] No undefined variables in Task prompt

### Phase 3: Integration Test
- [ ] Test file located at .claude/tests/integration/test_implement_iteration.sh
- [ ] Test isolation pattern implemented (CLAUDE_SPECS_ROOT, CLAUDE_PROJECT_DIR)
- [ ] Cleanup trap registered
- [ ] 3 core test cases implemented (multi-iteration, single-iteration, max-iterations)
- [ ] Checkpoint resumption test case added
- [ ] Coverage target ≥80% verified

### Phase 4: Documentation and Validation
- [ ] implement-command-guide.md updated with iteration behavior section
- [ ] IMPLEMENTATION_STATUS states documented
- [ ] Continuation context mechanism explained
- [ ] Example multi-iteration execution shown
- [ ] CLAUDE.md command reference updated (if needed)
- [ ] Validation scripts executed (sourcing, conditionals)
- [ ] Checkpoint format compliance verified
- [ ] Smoke test performed

## Conclusion

The implementation plan demonstrates strong compliance with project standards across all major categories:

- **Command Authoring**: Follows proven patterns from /build command
- **Output Formatting**: Maintains clean output with proper suppression
- **Code Standards**: Aligns with bash block patterns and state persistence
- **Testing Protocols**: Comprehensive integration test strategy
- **Documentation**: Clear guide updates planned

**Critical Path Enhancements**: 3 recommended enhancements identified (error logging, test isolation, checkpoint format) are straightforward to implement and will bring plan to full compliance.

**Risk Assessment**: Low risk - plan follows established /build pattern which has proven successful in production. Enhancements address edge cases and improve observability.

**Recommendation**: APPROVE plan with incorporation of high-priority enhancements during Phase 1 implementation.

---

REPORT_CREATED: /home/benjamin/.config/.claude/specs/999_build_implement_persistence/reports/002-standards-compliance-review.md
