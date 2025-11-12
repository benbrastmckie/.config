# Fix Coordinate Command Errors and Behavioral Issues - Implementation Plan

## Metadata
- **Date**: 2025-11-10
- **Feature**: Fix coordinate command bash errors and prevent unintended implementation behavior
- **Scope**: Improve workflow scope detection, enforce terminal state validation, strengthen agent behavioral constraints
- **Estimated Phases**: 6
- **Estimated Hours**: 12
- **Structure Level**: 0
- **Complexity Score**: 48.0 (6 phases × 5.0 + 3 files × 3.0 + 12 hours × 0.5 + 3 integrations × 2.0)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Coordinate Command Errors Analysis](../reports/001_coordinate_command_errors_analysis.md)
  - [Coordinate Performance Behavior Analysis](../reports/002_coordinate_performance_behavior_analysis.md)

## Overview

The coordinate command execution revealed in coordinate_output.md shows two critical issues:

1. **Bash Variable Error (RESOLVED)**: REPORT_PATHS_COUNT unbound variable error was already fixed in Spec 637, but the coordinate_output.md shows execution before those fixes were applied.

2. **Behavioral Issue (ACTIVE)**: Agent implemented code changes instead of creating a research report, violating the research-only constraint. Root cause: ambiguous workflow description containing implementation keywords ("integrating", "extending", "making improvements") combined with inadequate scope detection and behavioral enforcement.

This plan addresses the behavioral issue through improved scope detection, terminal state enforcement, and strengthened agent behavioral constraints.

## Research Summary

Key findings from research reports:

**Report 001 (Errors Analysis)**:
- All bash errors shown in coordinate_output.md have been resolved
- REPORT_PATHS_COUNT export added to workflow-initialization.sh
- Defensive checks added to reconstruct_report_paths_array()
- Agent invocation pattern updated to Standard 11 compliance
- 100% verification checkpoint coverage confirmed

**Report 002 (Performance Behavior Analysis)**:
- Workflow description contained implementation keywords ("integrating", "extending", "improving")
- Scope detection incorrectly classified as "research-and-plan" instead of "full-implementation"
- Missing implementation keyword detection in workflow-scope-detection.sh
- Agent violated behavioral constraint by implementing fixes instead of creating report
- Terminal state not enforced - agent bypassed state machine
- No completion signal validation or scope injection in agent prompts

**Recommended Approach**: Implement 6 key improvements to prevent recurrence:
1. Strengthen workflow scope detection with implementation keyword recognition
2. Enforce terminal state validation at state handler entry
3. Clarify research agent behavioral guidelines with explicit error handling
4. Inject workflow scope constraints into agent prompts
5. Add completion signal validation and parsing
6. Improve error recovery with fail-fast diagnostic reporting

## Success Criteria

- [x] Workflow scope detection recognizes implementation keywords ("integrating", "extending", "improving")
- [x] Scope detection correctly classifies workflows with implementation verbs as "full-implementation"
- [x] Terminal state validation added to all state handlers with fail-fast enforcement
- [x] Research agent behavioral file includes explicit error handling guidelines
- [x] Agent prompts include workflow scope context and behavioral constraints
- [x] Completion signal validation added to all agent invocations
- [x] Error recovery creates diagnostic reports instead of allowing implementation
- [x] Test suite validates scope detection with implementation keyword examples
- [x] Validation confirms agent compliance with behavioral constraints
- [x] End-to-end test confirms proper report creation without unintended implementation

## Technical Design

### Architecture Overview

The fix targets three architectural layers:

1. **Workflow Scope Detection Layer** (workflow-scope-detection.sh)
   - Add implementation keyword detection before plan detection
   - Recognize derived implementation verbs ("integrating", "extending", "modifying")
   - Classify ambiguous workflows as "full-implementation" not "research-and-plan"

2. **State Machine Enforcement Layer** (coordinate.md state handlers)
   - Add terminal state validation at entry of each state handler
   - Verify current state matches expected state
   - Exit immediately when terminal state reached
   - Prevent agent bypass of state machine

3. **Agent Behavioral Constraint Layer** (agent prompts + behavioral files)
   - Inject workflow scope context into all agent prompts
   - Add explicit "DO NOT implement" constraints for research agents
   - Validate completion signals match expected format
   - Strengthen error handling guidelines in research-specialist.md

### Component Interactions

```
User Workflow Description
         ↓
[Scope Detection] ← Enhanced with implementation keywords
         ↓
[State Machine Init] ← Stores terminal state
         ↓
[State Handler Entry] ← NEW: Terminal state validation
         ↓
[Agent Invocation] ← NEW: Scope + constraints injected
         ↓
[Agent Execution] ← Follows enhanced behavioral guidelines
         ↓
[Completion Signal] ← NEW: Validated and parsed
         ↓
[Verification Checkpoint] ← Existing: File creation verified
```

### Scope Detection Decision Logic

```
if workflow contains ("integrat", "extend", "improv", "modif", "updat", "chang"):
    if workflow contains ("research" AND "plan"):
        scope = "full-implementation"  # All phases
    elif workflow starts with ("fix", "debug"):
        scope = "debug-only"  # Skip research
    else:
        scope = "full-implementation"  # Default
elif workflow contains ("plan", "create.*plan", "design"):
    scope = "research-and-plan"  # Stop at plan
elif workflow is "^research.*" AND NOT contains action keywords:
    scope = "research-only"  # Stop at research
else:
    scope = "research-and-plan"  # Safe default
```

## Implementation Phases

### Phase 1: Strengthen Workflow Scope Detection
dependencies: []

**Objective**: Add implementation keyword detection to workflow-scope-detection.sh to correctly classify workflows with implementation verbs

**Complexity**: Medium

**Tasks**:
- [ ] Read current workflow-scope-detection.sh implementation (lines 12-47)
- [ ] Add implementation keyword detection pattern before line 36
- [ ] Implementation keywords: "integrat", "extend", "improv", "modif", "updat", "chang", "fix", "build"
- [ ] Add logic: if implementation keywords AND ("research" OR "plan") → scope="full-implementation"
- [ ] Add logic: if starts with ("fix", "debug") → scope="debug-only"
- [ ] Update scope detection order: implementation check → plan check → research-only check
- [ ] Add comments explaining implementation keyword rationale
- [ ] Export updated detect_workflow_scope function

**Testing**:
```bash
# Test implementation keyword detection
cd /home/benjamin/.config
source .claude/lib/workflow-scope-detection.sh

# Should detect as full-implementation (not research-and-plan)
result=$(detect_workflow_scope "research the plan and integrate with existing infrastructure")
echo "Test 1: $result (expect: full-implementation)"

# Should detect as full-implementation
result=$(detect_workflow_scope "research patterns and make necessary improvements")
echo "Test 2: $result (expect: full-implementation)"

# Should detect as research-and-plan (no implementation keywords)
result=$(detect_workflow_scope "research patterns and create implementation plan")
echo "Test 3: $result (expect: research-and-plan)"

# Should detect as research-only
result=$(detect_workflow_scope "research authentication patterns")
echo "Test 4: $result (expect: research-only)"

# Should detect as debug-only
result=$(detect_workflow_scope "fix the authentication bug in login.lua")
echo "Test 5: $result (expect: debug-only)"
```

**Expected Duration**: 1.5 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (5 test cases above)
- [ ] Git commit created: `feat(639): complete Phase 1 - Strengthen Workflow Scope Detection`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 2: Enforce Terminal State Validation
dependencies: []

**Objective**: Add terminal state validation to coordinate.md state handlers to prevent agent bypass

**Complexity**: High

**Tasks**:
- [ ] Read coordinate.md state handler structure (lines 280-830)
- [ ] Create terminal state validation helper function
- [ ] Add validation at entry of research state handler (after line 292)
- [ ] Add validation at entry of planning state handler (after line 655)
- [ ] Add validation at entry of implementation state handler (if exists)
- [ ] Add validation at entry of debug state handler (after line 1065)
- [ ] Add validation at entry of documentation state handler (if exists)
- [ ] Validation logic: check CURRENT_STATE == TERMINAL_STATE, exit with summary if true
- [ ] Validation logic: check CURRENT_STATE == EXPECTED_STATE for handler, fail-fast if mismatch
- [ ] Add clear error messages for state mismatch

**Testing**:
```bash
# Test terminal state enforcement with research-and-plan workflow
cd /home/benjamin/.config
/coordinate "research authentication patterns and create implementation plan (stop before implementation)"

# Expected: Creates reports, creates plan, exits at terminal state
# Should NOT proceed to implementation phase
# Verify output shows: "✓ Terminal state reached for scope: research-and-plan"
```

**Expected Duration**: 2.5 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (terminal state enforcement verified)
- [ ] Git commit created: `feat(639): complete Phase 2 - Enforce Terminal State Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 3: Strengthen Agent Behavioral Constraints
dependencies: []

**Objective**: Update research-specialist.md with explicit error handling guidelines and update agent prompts with scope injection

**Complexity**: Medium

**Tasks**:
- [ ] Read research-specialist.md current behavioral guidelines (lines 1-300)
- [ ] Add "Error Handling During Research" section after line 258
- [ ] Add explicit constraint: "DO NOT implement fixes, even if obvious"
- [ ] Add guidance: "Document errors in report, recommend fixes in report"
- [ ] Add example showing correct vs incorrect error handling behavior
- [ ] Update coordinate.md research agent invocation (lines 368-387)
- [ ] Inject WORKFLOW_SCOPE context into agent prompt
- [ ] Inject TERMINAL_STATE context into agent prompt
- [ ] Inject CURRENT_PHASE context into agent prompt
- [ ] Add explicit constraint: "CRITICAL: This is a $WORKFLOW_SCOPE workflow. DO NOT implement code changes."
- [ ] Add constraint: "CREATE RESEARCH REPORT ONLY. Implementation happens in separate phase."

**Testing**:
```bash
# Test with error scenario - agent should create report, not fix
cd /home/benjamin/.config
# Introduce intentional error in workflow-initialization.sh
# Run coordinate command
# Verify agent creates diagnostic report instead of implementing fix
# Verify report contains error analysis and recommended fixes
# Verify no code modifications occurred
```

**Expected Duration**: 2 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (agent creates report, not fixes)
- [ ] Git commit created: `feat(639): complete Phase 3 - Strengthen Agent Behavioral Constraints`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 4: Add Completion Signal Validation
dependencies: [3]

**Objective**: Parse and validate agent completion signals in coordinate.md to detect behavioral violations

**Complexity**: Medium

**Tasks**:
- [ ] Read coordinate.md verification checkpoint pattern (lines 429-467)
- [ ] Add completion signal parsing after research agent invocation
- [ ] Parse REPORT_CREATED signal from agent response
- [ ] Extract reported path from signal
- [ ] Validate reported path matches expected REPORT_PATH
- [ ] Add warning if completion signal missing or malformed
- [ ] Add warning if reported path differs from expected path
- [ ] Apply same pattern to planning phase verification (after line 733)
- [ ] Apply same pattern to debug phase verification (after line 1199)
- [ ] Log completion signal validation results to adaptive-planning.log

**Testing**:
```bash
# Test completion signal validation
cd /home/benjamin/.config
# Mock agent response without completion signal
# Verify coordinate detects missing signal
# Mock agent response with wrong path
# Verify coordinate detects path mismatch
# Verify warnings logged to adaptive-planning.log
```

**Expected Duration**: 2 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (completion signal validation working)
- [ ] Git commit created: `feat(639): complete Phase 4 - Add Completion Signal Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 5: Improve Error Recovery Strategy
dependencies: [2]

**Objective**: Add fail-fast error handling with diagnostic report creation instead of allowing agent implementation

**Complexity**: Medium

**Tasks**:
- [ ] Read coordinate.md initialization error handling (lines 150-165)
- [ ] Add error report creation helper function
- [ ] Detect initialization failures (workflow_paths, state machine errors)
- [ ] Create diagnostic report at .claude/tmp/coordinate_init_error_$(date +%s).md
- [ ] Include error details, workflow description, scope, timestamp in report
- [ ] Include debug information (library versions, state machine status)
- [ ] Include recommended actions (review library, check exports, re-run workflow)
- [ ] Exit immediately after creating error report (fail-fast)
- [ ] Add similar error handling for research phase failures
- [ ] Add similar error handling for planning phase failures

**Testing**:
```bash
# Test error recovery with initialization failure
cd /home/benjamin/.config
# Temporarily break workflow-initialization.sh
export REPORT_PATHS_COUNT=""  # Simulate missing export
# Run coordinate command
# Verify error report created at .claude/tmp/coordinate_init_error_*.md
# Verify coordinate exited with diagnostic message
# Verify no code modifications occurred
```

**Expected Duration**: 2 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (error recovery creates reports)
- [ ] Git commit created: `feat(639): complete Phase 5 - Improve Error Recovery Strategy`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 6: Integration Testing and Validation
dependencies: [1, 2, 3, 4, 5]

**Objective**: Validate all fixes with end-to-end testing and ensure no regressions

**Complexity**: Low

**Tasks**:
- [ ] Create test script: .claude/tests/test_coordinate_scope_detection.sh
- [ ] Test case 1: Implementation keywords → full-implementation scope
- [ ] Test case 2: Research + plan keywords → research-and-plan scope
- [ ] Test case 3: Pure research → research-only scope
- [ ] Test case 4: Fix/debug keywords → debug-only scope
- [ ] Test case 5: Terminal state enforcement (research-and-plan stops at plan)
- [ ] Test case 6: Agent creates report, not implementation (error scenario)
- [ ] Test case 7: Completion signal validation detects missing signal
- [ ] Test case 8: Error recovery creates diagnostic report
- [ ] Run test suite: bash .claude/tests/test_coordinate_scope_detection.sh
- [ ] Verify all tests pass
- [ ] Run validation: .claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md
- [ ] Update coordinate-command-guide.md with scope detection examples
- [ ] Update coordinate-state-management.md with terminal state enforcement patterns
- [ ] Archive or mark coordinate_output.md as historical

**Testing**:
```bash
# Run complete test suite
cd /home/benjamin/.config
bash .claude/tests/test_coordinate_scope_detection.sh

# Expected: 8/8 tests pass
# Verify no regressions in existing functionality
# Verify scope detection improvements working
# Verify terminal state enforcement working
# Verify agent behavioral constraints working
```

**Expected Duration**: 2 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (8/8 test cases)
- [ ] Git commit created: `feat(639): complete Phase 6 - Integration Testing and Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Unit Testing
- **Scope Detection**: Test workflow-scope-detection.sh with 10+ workflow description examples
- **State Validation**: Mock state transitions and verify terminal state enforcement
- **Signal Parsing**: Test completion signal extraction with various formats

### Integration Testing
- **End-to-End Research Workflow**: Verify report creation without implementation
- **End-to-End Research-Plan Workflow**: Verify terminal state enforcement at plan phase
- **Error Recovery**: Verify diagnostic report creation on initialization failures
- **Agent Compliance**: Verify agents respect behavioral constraints

### Regression Testing
- **Existing Workflows**: Verify no regressions in research-only, full-implementation, debug-only workflows
- **Verification Checkpoints**: Verify all existing checkpoints still function
- **State Persistence**: Verify state file persistence across bash blocks

### Performance Testing
- **Scope Detection**: Should complete in <100ms
- **Terminal State Check**: Should complete in <50ms
- **Completion Signal Parsing**: Should complete in <100ms

## Documentation Requirements

### Updated Files
1. **workflow-scope-detection.sh**: Add inline comments explaining implementation keyword detection
2. **coordinate.md**: Add comments at terminal state validation points
3. **research-specialist.md**: Add "Error Handling During Research" section
4. **coordinate-command-guide.md**: Add section "Workflow Scope Detection Examples"
5. **coordinate-state-management.md**: Add section "Terminal State Enforcement Patterns"

### New Documentation
1. **Test script**: .claude/tests/test_coordinate_scope_detection.sh with comprehensive test cases
2. **Error report template**: Standardized format for initialization error reports

### Cross-References
- Link scope detection guide to behavioral injection pattern
- Link terminal state enforcement to state machine documentation
- Link error recovery to verification-fallback pattern

## Dependencies

### External Dependencies
- None (all changes internal to .claude/ system)

### File Dependencies
- **workflow-scope-detection.sh**: Updated by Phase 1
- **coordinate.md**: Updated by Phases 2, 4, 5
- **research-specialist.md**: Updated by Phase 3
- **coordinate-command-guide.md**: Updated by Phase 6
- **coordinate-state-management.md**: Updated by Phase 6

### Integration Points
- State machine library (workflow-state-machine.sh): Read-only, no changes
- State persistence library (state-persistence.sh): Read-only, no changes
- Verification helpers (verification-helpers.sh): Used, no changes
- Unified logger (unified-logger.sh): Used for completion signal logging

## Risk Mitigation

### Risk 1: Scope Detection Over-Classification
**Risk**: Implementation keywords too broad, classifying too many workflows as full-implementation
**Mitigation**: Conservative keyword list, test with diverse examples, allow override flag
**Rollback**: Revert workflow-scope-detection.sh changes, use default scope

### Risk 2: Terminal State Enforcement Breaks Resumption
**Risk**: Terminal state check prevents checkpoint resume in middle of workflow
**Mitigation**: Check if resuming from checkpoint, skip terminal validation if mid-workflow
**Rollback**: Remove terminal state validation, rely on scope detection only

### Risk 3: Agent Prompt Changes Confuse Models
**Risk**: Added scope constraints change agent behavior unexpectedly
**Mitigation**: Progressive rollout, test with multiple workflow types, log agent responses
**Rollback**: Remove scope injection, use original agent prompts

## Completion Checklist

- [ ] All 6 phases completed with tests passing
- [ ] Scope detection recognizes implementation keywords correctly
- [ ] Terminal state enforcement prevents unwanted implementation
- [ ] Agent behavioral constraints strengthened
- [ ] Completion signal validation working
- [ ] Error recovery creates diagnostic reports
- [ ] Documentation updated with examples and patterns
- [ ] Test suite created and passing (8/8 tests)
- [ ] No regressions in existing workflows
- [ ] Git commits created for each phase
