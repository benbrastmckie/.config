# Implementation Plan: Lean-Implement Coordinator Delegation Optimization

## Metadata

**Date**: 2025-12-09
**Feature**: Optimize /lean-implement delegation to protect primary agent context through metadata-only passing and proper hard barriers
**Status**: [COMPLETE]
**Estimated Hours**: 6-10 hours
**Standards File**: /home/benjamin/.config/CLAUDE.md
**Research Reports**:
- [Lean-Implement Output Analysis](/home/benjamin/.config/.claude/specs/051_lean_implement_coordinator_delegation/reports/001-lean-implement-output-analysis.md)
- [Root Cause Analysis](/home/benjamin/.config/.claude/specs/051_lean_implement_coordinator_delegation/reports/001-root-cause-analysis.md)
- [Context Delegation Strategies](/home/benjamin/.config/.claude/specs/051_lean_implement_coordinator_delegation/reports/002-context-delegation-strategies.md)
- [Lean Coordinator Architecture](/home/benjamin/.config/.claude/specs/051_lean_implement_coordinator_delegation/reports/003-lean-coordinator-architecture.md)
- [Performance Improvement Plan](/home/benjamin/.config/.claude/specs/051_lean_implement_coordinator_delegation/reports/004-performance-improvement-plan.md)

---

## Overview

The /lean-implement command currently suffers from context window exhaustion because the primary agent reads agent behavioral files (1,374+ lines) and parses full summary files (2,000+ tokens) instead of delegating properly. Research identified three critical issues:

1. **Primary agent reads agent files**: Consumes ~4,700 tokens before delegation
2. **Full summary file parsing**: Consumes ~2,000 tokens instead of ~80 tokens
3. **Missing hard barrier enforcement**: Primary agent performs implementation work after coordinator returns with partial success

This plan implements metadata-only context passing (95% reduction) and hard barrier enforcement to achieve 75% primary agent context reduction and enable 10+ iterations (vs 3-4 currently).

---

## Success Criteria

- [ ] Primary agent context consumption reduced by 75% (from ~8,000 to ~2,000 tokens)
- [ ] No Read operations on agent behavioral files in primary agent execution
- [ ] Summary parsing uses only structured metadata (80 tokens vs 2,000+ tokens)
- [ ] Hard barrier enforced: `exit 0` after iteration decision prevents implementation work
- [ ] Delegation contract validation detects prohibited tool usage
- [ ] Max iterations increased from 3-4 to 10+
- [ ] All existing tests pass (backward compatibility maintained)

---

## Phase 1: Remove Agent File Reads from Primary Agent [COMPLETE]

**Objective**: Eliminate all agent behavioral file reads from the primary agent by passing paths to coordinators and having them read their own behavioral guidelines.

**Context**: Research shows the primary agent reads lean-coordinator.md (1,174 lines) and implementer-coordinator.md (200 lines), consuming ~4,700 tokens before delegation. The hierarchical agent architecture specifies coordinators should read their own behavioral files.

### Tasks

- [ ] Audit lean-implement.md for all Read operations on agent files
- [ ] Remove agent file read instructions from Block 1b coordinator prompt construction
- [ ] Update coordinator prompts to include "Read and follow ALL behavioral guidelines from: ${AGENT_PATH}"
- [ ] Verify lean-coordinator.md and implementer-coordinator.md have no dependencies on primary agent reading them
- [ ] Add comment documenting that coordinators read their own behavioral files

### Files Modified

- `/home/benjamin/.config/.claude/commands/lean-implement.md` (Block 1b)

### Validation

```bash
# Test that primary agent does not read agent files
/lean-implement <test-plan.md> 2>&1 | grep -c "Read.*agents/"
# Expected: 0 (no agent file reads)

# Verify coordinator still executes correctly
# Expected: Coordinator completes wave execution, returns summary
```

### Success Criteria

- [ ] Zero Read operations on .claude/agents/*.md files in primary agent output
- [ ] Coordinator prompts include explicit "Read and follow" instruction with agent file path
- [ ] Coordinators successfully read their own behavioral files and execute workflows
- [ ] No behavioral changes in coordinator execution (same output signals)

---

## Phase 2: Implement Brief Summary Parsing [COMPLETE]

**Objective**: Parse only structured metadata lines (lines 1-10) from coordinator summary files instead of reading entire files, reducing context consumption from ~2,000 tokens to ~80 tokens.

**Context**: Coordinators return YAML-structured metadata at the top of summary files. Current implementation greps entire files. Research recommends extracting only metadata fields using `head` to limit file reads.

### Tasks

- [ ] Create `parse_brief_summary()` function in Block 1c that extracts only metadata lines
- [ ] Implement metadata field extraction for: coordinator_type, summary_brief, phases_completed, work_remaining, context_usage_percent, requires_continuation
- [ ] Replace all full-file grep patterns with head-based extraction
- [ ] Add fallback to full file parsing with warning for backward compatibility with legacy coordinators
- [ ] Verify all state variables populated correctly from metadata-only parsing
- [ ] Add validation that required metadata fields are present

### Implementation Pattern

```bash
parse_brief_summary() {
  local summary_file="$1"

  # Extract only structured metadata (first 10 lines contain all required fields)
  local metadata_section
  metadata_section=$(head -10 "$summary_file" 2>/dev/null || echo "")

  # Parse individual fields from metadata section
  COORDINATOR_TYPE=$(echo "$metadata_section" | grep "^coordinator_type:" | sed 's/^coordinator_type:[[:space:]]*//' | tr -d ' ' | head -1)
  SUMMARY_BRIEF=$(echo "$metadata_section" | grep "^summary_brief:" | sed 's/^summary_brief:[[:space:]]*//' | tr -d '"' | head -1)
  PHASES_COMPLETED=$(echo "$metadata_section" | grep "^phases_completed:" | sed 's/^phases_completed:[[:space:]]*//' | tr -d '[],"' | head -1)
  WORK_REMAINING=$(echo "$metadata_section" | grep "^work_remaining:" | sed 's/^work_remaining:[[:space:]]*//' | head -1)
  CONTEXT_USAGE_PERCENT=$(echo "$metadata_section" | grep "^context_usage_percent:" | sed 's/^context_usage_percent:[[:space:]]*//' | tr -d '%' | head -1)
  REQUIRES_CONTINUATION=$(echo "$metadata_section" | grep "^requires_continuation:" | sed 's/^requires_continuation:[[:space:]]*//' | tr -d ' ' | head -1)

  # Validation: Check required fields present
  if [ -z "$COORDINATOR_TYPE" ] || [ -z "$REQUIRES_CONTINUATION" ]; then
    echo "WARNING: Coordinator output missing required metadata fields, falling back to full file parsing" >&2
    return 1
  fi

  return 0
}
```

### Files Modified

- `/home/benjamin/.config/.claude/commands/lean-implement.md` (Block 1c, lines 1064-1100)

### Validation

```bash
# Test that brief parsing extracts all required fields
# Mock a coordinator summary with structured metadata
# Run parse_brief_summary function
# Verify all variables populated correctly

# Measure context reduction
# Before: grep entire file (~2000 tokens)
# After: head -10 + metadata extraction (~80 tokens)
# Expected: 96% reduction
```

### Success Criteria

- [ ] `parse_brief_summary()` function extracts all required metadata fields
- [ ] Context consumption for summary parsing reduced to ~80 tokens
- [ ] Fallback to full file parsing works for legacy coordinators (with warning)
- [ ] All state variables (work_remaining, context_usage_percent, etc.) populated correctly
- [ ] Required field validation detects malformed coordinator output

---

## Phase 3: Enforce Hard Barrier After Iteration Decision [COMPLETE]

**Objective**: Add `exit 0` after iteration decision in Block 1c when `requires_continuation=true` to prevent primary agent from performing implementation work, enforcing the delegation contract.

**Context**: Root cause analysis shows the primary agent continues to direct implementation work after coordinator returns with partial success because there's no hard barrier (exit) after the iteration decision logic.

### Tasks

- [ ] Locate iteration decision logic in Block 1c (around line 1200)
- [ ] Add `exit 0` enforcement after state update when `requires_continuation=true`
- [ ] Add clear comment explaining hard barrier prevents primary agent implementation work
- [ ] Update state persistence to save iteration context for resume
- [ ] Verify workflow resumes correctly at Block 1b on next iteration
- [ ] Test that primary agent does NOT perform any Edit, lean_goal, or lean_multi_attempt operations after coordinator returns

### Implementation Pattern

```bash
# === ITERATION DECISION ===
if [ "$REQUIRES_CONTINUATION" = "true" ] && [ -n "$WORK_REMAINING_NEW" ]; then
  NEXT_ITERATION=$((ITERATION + 1))

  # Update state for next iteration
  append_workflow_state "ITERATION" "$NEXT_ITERATION"
  append_workflow_state "WORK_REMAINING" "$WORK_REMAINING_NEW"
  append_workflow_state "CONTINUATION_CONTEXT" "$SUMMARY_BRIEF"

  echo "**ITERATION LOOP**: Returning to Block 1b for coordinator re-delegation"
  echo "  Next iteration: $NEXT_ITERATION"
  echo "  Work remaining: $WORK_REMAINING_NEW"
  echo ""

  # HARD BARRIER: PRIMARY AGENT STOPS HERE
  # MUST NOT PROCEED TO DIRECT IMPLEMENTATION WORK
  # The coordinator is responsible for ALL implementation work
  # Execution will resume at Block 1b on next agent invocation
  exit 0
fi

# If no continuation required, proceed to completion summary
echo "All phases complete or context threshold exceeded"
```

### Files Modified

- `/home/benjamin/.config/.claude/commands/lean-implement.md` (Block 1c, iteration decision section)

### Validation

```bash
# Test Case 1: Partial Success Re-Delegation
# Setup: Plan with 3 phases, coordinator completes Phase 1 with 4/5 theorems
# Expected: Block 1c exits with code 0, workflow resumes at Block 1b on next iteration

# Test Case 2: Primary Agent Tool Usage Audit
# After coordinator returns, verify primary agent has NOT used:
# - Edit tool
# - lean_goal MCP tool
# - lean_multi_attempt MCP tool
# - lean-lsp MCP tool
```

### Success Criteria

- [ ] `exit 0` added after iteration decision when `requires_continuation=true`
- [ ] State persistence saves all iteration context (next iteration number, work_remaining, continuation_context)
- [ ] Workflow resumes correctly at Block 1b on subsequent iterations
- [ ] Primary agent performs ZERO implementation operations after coordinator returns
- [ ] Delegation contract validation (Phase 4) detects no violations

---

## Phase 4: Add Delegation Contract Validation [COMPLETE]

**Objective**: Implement automated validation in Block 1c that detects and blocks primary agent tool usage violations (Edit, lean_goal, lean_multi_attempt, lean-lsp).

**Context**: The `validate_delegation_contract()` function exists in lean-implement.md but is not called during workflow execution. This validation provides defense-in-depth to detect delegation pattern violations.

### Tasks

- [ ] Review existing `validate_delegation_contract()` function (lines 32-108)
- [ ] Add workflow log capture to track primary agent tool usage
- [ ] Call `validate_delegation_contract()` in Block 1c after coordinator returns
- [ ] Log validation errors with structured error data
- [ ] Add bypass flag for testing/debugging (`--skip-delegation-validation`)
- [ ] Document that validation runs after hard barrier as defense-in-depth

### Implementation Pattern

```bash
# Block 1c: After parsing coordinator output, before iteration decision

# === VALIDATE DELEGATION CONTRACT ===
# Primary agent MUST NOT perform implementation work after coordinator delegation
# This validation provides defense-in-depth (hard barrier exit is primary enforcement)

WORKFLOW_LOG="${CLAUDE_PROJECT_DIR}/.claude/output/lean-implement-output.md"

if [ -f "$WORKFLOW_LOG" ] && [ "${SKIP_DELEGATION_VALIDATION:-false}" != "true" ]; then
  echo "Validating delegation contract..."

  if ! validate_delegation_contract "$WORKFLOW_LOG"; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "delegation_error" \
      "Primary agent performed implementation work (delegation contract violation)" \
      "bash_block_1c" \
      "$(jq -n --arg log "$WORKFLOW_LOG" '{workflow_log: $log}')"

    echo "ERROR: Delegation contract violation detected" >&2
    echo "  Primary agent used prohibited tools (Edit, lean_goal, lean_multi_attempt, lean-lsp)" >&2
    echo "  See validation output above for details" >&2
    exit 1
  fi

  echo "[OK] Delegation contract validated: No prohibited tool usage"
else
  echo "WARNING: Delegation contract validation skipped (no workflow log or validation disabled)" >&2
fi
```

### Files Modified

- `/home/benjamin/.config/.claude/commands/lean-implement.md` (Block 1c, after coordinator output parsing)

### Validation

```bash
# Test Case 1: Clean Delegation (No Violations)
# Run /lean-implement with proper delegation
# Expected: Validation passes, no errors logged

# Test Case 2: Simulated Violation
# Inject mock Edit/lean_goal tool usage into workflow log
# Run validation
# Expected: Validation fails, error logged with tool counts

# Test Case 3: Bypass Flag
# Run /lean-implement --skip-delegation-validation
# Expected: Validation skipped, warning logged
```

### Success Criteria

- [ ] `validate_delegation_contract()` called in Block 1c after coordinator returns
- [ ] Validation detects Edit, lean_goal, lean_multi_attempt, lean-lsp tool usage
- [ ] Errors logged with structured data (tool counts, workflow log path)
- [ ] Bypass flag (`--skip-delegation-validation`) works for testing
- [ ] Clean delegation workflows pass validation (zero false positives)

---

## Phase 5: Convert Task Pseudo-Code to Real Invocations [COMPLETE]

**Objective**: Replace the pseudo-code `Task { }` block in lean-implement.md with explicit `**EXECUTE NOW**: USE the Task tool` directive to ensure mandatory delegation.

**Context**: The command currently includes instructional pseudo-code at the end of Block 1b that may not trigger actual Task tool invocation. Research recommends explicit invocation directives following the pattern from /create-plan.

### Tasks

- [ ] Locate pseudo-code Task block in Block 1b (lines 937-942)
- [ ] Replace pseudo-code with explicit invocation directive
- [ ] Ensure prompt construction uses coordinator file path instead of reading content
- [ ] Add comment documenting mandatory delegation pattern
- [ ] Verify Task tool is invoked by checking output logs
- [ ] Test that coordinator receives all required input parameters

### Implementation Pattern

Replace this (lines 937-942):
```markdown
Task {
  subagent_type: "general-purpose"
  model: "sonnet"
  description: "${COORDINATOR_DESCRIPTION}"
  prompt: "${COORDINATOR_PROMPT}"
}
```

With this:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the selected coordinator.

**HARD BARRIER**: Coordinator delegation is MANDATORY (no conditionals, no bypass).
The primary agent MUST NOT perform implementation work directly.

You MUST use the Task tool with these EXACT parameters:

- **subagent_type**: "general-purpose"
- **model**: "opus-4.5"  # Coordinators require Opus for complex orchestration
- **description**: "${COORDINATOR_DESCRIPTION}"
- **prompt**:
    ```
    Read and follow ALL behavioral guidelines from:
    ${COORDINATOR_AGENT_PATH}

    **Input Contract**:
    - plan_path: ${PLAN_FILE}
    - lean_file_path: ${PRIMARY_LEAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - artifact_paths:
        summaries: ${SUMMARIES_DIR}
        outputs: ${OUTPUTS_DIR}
    - current_phase: ${CURRENT_PHASE}
    - iteration: ${ITERATION}
    - max_iterations: ${MAX_ITERATIONS}
    - context_threshold: ${CONTEXT_THRESHOLD}
    - continuation_context: ${CONTINUATION_CONTEXT:-null}

    Execute ${COORDINATOR_TYPE} coordination workflow and return structured output signal.
    ```

**CRITICAL**: The coordinator MUST create a summary file in ${SUMMARIES_DIR}/.
The orchestrator will validate the summary exists after you return.
```

### Files Modified

- `/home/benjamin/.config/.claude/commands/lean-implement.md` (Block 1b, lines 932-942)

### Validation

```bash
# Verify Task tool invocation appears in output
/lean-implement <plan.md> 2>&1 | grep -c "Task("
# Expected: 1-2 (one per coordinator invocation)

# Verify coordinator receives correct input parameters
# Check coordinator output/summary for:
# - plan_path populated
# - artifact_paths correct
# - iteration number correct
```

### Success Criteria

- [ ] Pseudo-code Task block replaced with explicit invocation directive
- [ ] Prompt includes "Read and follow" instruction for coordinator to read its own behavioral file
- [ ] All input contract parameters passed correctly (plan_path, artifact_paths, etc.)
- [ ] Task tool invocation visible in workflow output logs
- [ ] Coordinator executes successfully with new prompt format

---

## Phase 6: Add Context Budget Monitoring [COMPLETE]

**Objective**: Add optional context budget tracking to primary agent for proactive context management and debugging.

**Context**: This is a low-priority enhancement that provides visibility into primary agent context consumption. Useful for validating the 75% reduction target and debugging future context issues.

### Tasks

- [ ] Add context budget constants to Block 1a
- [ ] Create `track_context_usage()` function
- [ ] Add context tracking calls after major operations (plan read, summary parse)
- [ ] Log warnings when budget threshold exceeded
- [ ] Add budget summary to completion output
- [ ] Make tracking optional via environment variable

### Implementation Pattern

```bash
# Block 1a: Add context budget constants
PRIMARY_CONTEXT_BUDGET=${LEAN_IMPLEMENT_CONTEXT_BUDGET:-5000}  # tokens
CURRENT_CONTEXT=0

track_context_usage() {
  local operation="$1"
  local estimated_tokens="$2"

  CURRENT_CONTEXT=$((CURRENT_CONTEXT + estimated_tokens))

  echo "Context: $operation (+$estimated_tokens tokens, total: $CURRENT_CONTEXT/$PRIMARY_CONTEXT_BUDGET)" >&2

  if [ "$CURRENT_CONTEXT" -gt "$PRIMARY_CONTEXT_BUDGET" ]; then
    echo "WARNING: Primary agent context budget exceeded ($CURRENT_CONTEXT/$PRIMARY_CONTEXT_BUDGET tokens)" >&2
  fi
}

# Usage in Block 1a-classify
track_context_usage "plan_read" 1500

# Usage in Block 1c
track_context_usage "summary_parse_brief" 80
```

### Files Modified

- `/home/benjamin/.config/.claude/commands/lean-implement.md` (Block 1a, Block 1c)

### Validation

```bash
# Run with context tracking enabled
LEAN_IMPLEMENT_CONTEXT_BUDGET=3000 /lean-implement <plan.md> 2>&1 | grep "Context:"

# Verify tracking output shows:
# - plan_read: ~1500 tokens
# - summary_parse_brief: ~80 tokens (after Phase 2)
# - Total: <2000 tokens (75% reduction achieved)
```

### Success Criteria

- [ ] Context budget tracking added to major operations
- [ ] Warnings logged when budget exceeded
- [ ] Tracking output shows token consumption per operation
- [ ] Total primary agent context <2,000 tokens (75% reduction validated)
- [ ] Tracking can be disabled via environment variable

---

## Phase 7: Integration Testing and Validation [COMPLETE]

**Objective**: Comprehensive testing of all optimizations to ensure 75% context reduction, 10+ iteration capability, and backward compatibility.

**Context**: This phase validates all improvements work together correctly and achieve the target performance metrics without breaking existing functionality.

### Test Cases

#### Test 1: Agent File Read Elimination
```bash
# Verify zero agent file reads by primary agent
/lean-implement specs/test/plans/simple-lean-plan.md 2>&1 > /tmp/test-output.txt
grep -c "Read.*agents/" /tmp/test-output.txt
# Expected: 0

# Verify coordinator still reads its own behavioral file
grep -c "Read.*lean-coordinator.md" /tmp/test-output.txt  # Should be in coordinator section
# Expected: 1 (from coordinator, not primary agent)
```

#### Test 2: Brief Summary Parsing
```bash
# Create mock coordinator summary with structured metadata
cat > /tmp/mock-summary.md <<'EOF'
coordinator_type: lean
summary_brief: "Wave 1 complete, 5 theorems proven, 72% context"
phases_completed: [1, 2]
work_remaining: Phase_3 Phase_4
context_usage_percent: 72
requires_continuation: true

[Full detailed content below - should NOT be parsed...]
EOF

# Run parse_brief_summary function
source .claude/commands/lean-implement.md
parse_brief_summary /tmp/mock-summary.md

# Verify variables populated correctly
[ "$COORDINATOR_TYPE" = "lean" ] && echo "PASS: coordinator_type"
[ "$CONTEXT_USAGE_PERCENT" = "72" ] && echo "PASS: context_usage_percent"
[ "$REQUIRES_CONTINUATION" = "true" ] && echo "PASS: requires_continuation"
```

#### Test 3: Hard Barrier Enforcement
```bash
# Run workflow with plan that triggers partial success
/lean-implement specs/test/plans/partial-success-plan.md

# Verify exit 0 occurs after iteration decision
echo $?  # Expected: 0

# Verify primary agent does NOT perform implementation work
grep -E "(Edit|lean_goal|lean_multi_attempt)" /tmp/test-output.txt | grep -v "Task("
# Expected: No matches (all implementation work delegated)
```

#### Test 4: Delegation Contract Validation
```bash
# Inject mock violation into workflow log
echo "● Edit(/path/to/file.lean)" >> /tmp/mock-workflow-log.md

# Run validation
source .claude/commands/lean-implement.md
validate_delegation_contract /tmp/mock-workflow-log.md
echo $?  # Expected: 1 (failure)

# Check error output includes tool counts
# Expected: "Edit calls: 1"
```

#### Test 5: Context Reduction Measurement
```bash
# Enable context tracking
LEAN_IMPLEMENT_CONTEXT_BUDGET=5000 /lean-implement <plan.md> 2>&1 | tee /tmp/context-log.txt

# Extract total context usage
grep "total:" /tmp/context-log.txt | tail -1

# Expected: <2000 tokens (75% reduction from 8000 baseline)
```

#### Test 6: Iteration Improvement
```bash
# Run multi-phase plan with context threshold
/lean-implement --max-iterations=15 specs/test/plans/multi-phase-lean-plan.md

# Count iterations before context exhaustion
grep -c "ITERATION LOOP" /tmp/test-output.txt

# Expected: 10+ iterations (vs 3-4 baseline)
```

#### Test 7: Backward Compatibility
```bash
# Test with legacy coordinator that doesn't include summary_brief field
# Should fall back to full file parsing with warning

# Expected:
# - WARNING: "Coordinator output missing summary_brief field, falling back to full file parsing"
# - Workflow completes successfully
# - State variables populated correctly
```

### Tasks

- [ ] Create test plan with simple Lean phases (3 phases, 5 theorems per phase)
- [ ] Create test plan with partial success scenario (coordinator proves 4/5 theorems)
- [ ] Run Test 1: Agent file read elimination
- [ ] Run Test 2: Brief summary parsing with mock data
- [ ] Run Test 3: Hard barrier enforcement with partial success plan
- [ ] Run Test 4: Delegation contract validation with mock violations
- [ ] Run Test 5: Context reduction measurement
- [ ] Run Test 6: Iteration improvement with multi-phase plan
- [ ] Run Test 7: Backward compatibility with legacy coordinator
- [ ] Validate all existing test suites pass
- [ ] Document any breaking changes or migration requirements

### Files Modified

- `/home/benjamin/.config/.claude/specs/051_lean_implement_coordinator_delegation/test/` (new test directory)

### Success Criteria

- [ ] All 7 test cases pass
- [ ] Primary agent context <2,000 tokens (75% reduction validated)
- [ ] Max iterations 10+ (vs 3-4 baseline)
- [ ] Zero agent file reads by primary agent
- [ ] Summary parsing uses 80 tokens (vs 2,000+ baseline)
- [ ] Hard barrier prevents implementation work
- [ ] Delegation contract validation detects violations
- [ ] Backward compatibility maintained for legacy coordinators
- [ ] All existing test suites pass (no regressions)

---

## Phase 8: Documentation Updates [COMPLETE]

**Objective**: Update command documentation, architectural guides, and examples to reflect the optimized delegation pattern.

**Context**: Several documentation files need updates to reflect the new metadata-only passing pattern and hard barrier enforcement.

### Tasks

- [ ] Update lean-implement command guide with new delegation pattern
- [ ] Document brief summary parsing format and fields
- [ ] Update hierarchical agents examples to include lean-implement pattern
- [ ] Add troubleshooting guide for delegation contract violations
- [ ] Document context budget monitoring usage
- [ ] Update CLAUDE.md lean_implement_coordinator_delegation section
- [ ] Add migration guide for custom coordinators

### Files Modified

- `/home/benjamin/.config/.claude/docs/guides/commands/lean-implement-command-guide.md`
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md`
- `/home/benjamin/.config/CLAUDE.md` (add section for this optimization)
- `/home/benjamin/.config/.claude/docs/troubleshooting/delegation-contract-violations.md` (new file)

### Documentation Sections

#### 1. Brief Summary Format Documentation
```markdown
## Coordinator Output Signal Format

Coordinators MUST return structured metadata at the top of summary files (lines 1-10):

```yaml
coordinator_type: lean|software
summary_brief: "80-token summary of work completed and next steps"
phases_completed: [1, 2, 3]
work_remaining: Phase_4 Phase_5 Phase_6
context_usage_percent: 72
requires_continuation: true|false
context_exhausted: true|false
```

The primary agent parses ONLY these metadata lines (80 tokens) instead of reading the full summary file (2,000+ tokens), achieving 96% context reduction.
```

#### 2. Delegation Contract Troubleshooting
```markdown
## Troubleshooting Delegation Contract Violations

**Symptom**: Error message "Delegation contract violation detected"

**Cause**: Primary agent performed implementation work instead of delegating to coordinators

**Prohibited Tools** (primary agent must NOT use these):
- Edit - File editing
- lean_goal - Lean proof state inspection
- lean_multi_attempt - Lean proof attempts
- lean-lsp - Lean language server operations

**Resolution**:
1. Verify hard barrier enforcement is present (exit 0 after iteration decision)
2. Check workflow log for prohibited tool usage
3. Ensure coordinators are invoked via Task tool (not bypassed)
4. Review coordinator output signal for requires_continuation field
```

### Success Criteria

- [ ] Command guide updated with delegation pattern details
- [ ] Brief summary format documented with field specifications
- [ ] Hierarchical agents examples include lean-implement as Example 9
- [ ] Troubleshooting guide covers common delegation issues
- [ ] Context budget monitoring usage documented
- [ ] Migration guide available for custom coordinators
- [ ] All documentation links valid (pass link validation)

---

## Dependencies

### External Dependencies
- lean-coordinator.md agent (no changes needed)
- implementer-coordinator.md agent (no changes needed)
- dependency-analyzer.sh (used by coordinators)
- validate-all-standards.sh (for testing)

### Internal Dependencies
- Block 1a artifact path pre-calculation (already implemented)
- State persistence for iteration context (already implemented)
- Error logging infrastructure (already implemented)
- Hard barrier exit pattern (already implemented in Block 1c line 1292)

### Library Requirements
- error-handling.sh >=1.0.0
- state-persistence.sh >=1.6.0
- workflow-state-machine.sh >=2.0.0

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Coordinator fails to read behavioral file | Low | High | Test with explicit paths in multiple scenarios |
| Brief parsing misses critical fields | Medium | Medium | Comprehensive field validation + fallback to full parsing |
| Task invocation syntax incorrect | Low | High | Use proven patterns from /create-plan and /lean-plan |
| Context budget too aggressive | Low | Low | Make budget configurable via environment variable |
| Breaking changes for custom coordinators | Medium | Medium | Maintain backward compatibility + migration guide |
| Hard barrier breaks resumption | Low | High | Thorough testing of state persistence across iterations |

---

## Rollback Plan

If critical issues arise during implementation:

1. **Phase 1-2 Rollback**: Revert to reading agent files and full summary parsing
   - Restore previous Block 1b agent file read logic
   - Remove `parse_brief_summary()` function
   - Fall back to full grep patterns

2. **Phase 3 Rollback**: Remove hard barrier exit
   - Comment out `exit 0` after iteration decision
   - Document reason for rollback in code comments

3. **Phase 4 Rollback**: Disable delegation contract validation
   - Set `SKIP_DELEGATION_VALIDATION=true` by default
   - Keep validation function for future use

4. **Full Rollback**: Restore from git history
   - Identify last known good commit before changes
   - `git revert <commit-range>` to undo all changes
   - Run full test suite to verify restoration

---

## Performance Metrics (Target vs Baseline)

| Metric | Baseline | Target | Improvement |
|--------|----------|--------|-------------|
| Primary agent context | ~8,000 tokens | ~2,000 tokens | 75% reduction |
| Agent file reads | 1,374 lines (~4,700 tokens) | 0 lines (0 tokens) | 100% elimination |
| Summary parsing | ~2,000 tokens | ~80 tokens | 96% reduction |
| Max iterations | 3-4 | 10+ | 2.5-3.5x increase |
| Context per iteration | ~25,000 tokens | ~8,000 tokens | 68% reduction |
| Coordinator overhead | N/A | <20% | Per spec |

---

## Timeline Estimate

- **Phase 1** (Agent file reads): 1.5 hours
- **Phase 2** (Brief summary): 1.5 hours
- **Phase 3** (Hard barrier): 1 hour
- **Phase 4** (Delegation validation): 1 hour
- **Phase 5** (Task pseudo-code): 0.5 hours
- **Phase 6** (Context budget): 1 hour
- **Phase 7** (Integration testing): 2 hours
- **Phase 8** (Documentation): 1.5 hours

**Total**: 10 hours (conservative estimate with testing buffer)
**Optimistic**: 6 hours (if no issues encountered)

---

## Notes

- This plan builds on existing infrastructure (hard barrier exit, state persistence, error logging) rather than introducing new architectural patterns
- Backward compatibility maintained via fallback parsing for legacy coordinators
- Validation function provides defense-in-depth but hard barrier exit is primary enforcement mechanism
- Context budget monitoring is optional enhancement for debugging (not required for core functionality)
- All improvements align with hierarchical agent architecture standards documented in CLAUDE.md
