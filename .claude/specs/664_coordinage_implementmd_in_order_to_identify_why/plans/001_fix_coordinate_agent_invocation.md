# Fix /coordinate Workflow Scope Detection and Documentation

## Metadata
- **Date**: 2025-11-11
- **Feature**: Correct /coordinate workflow scope detection to prevent fallback to /implement invocation
- **Scope**: Workflow scope detection bug fix and documentation clarification
- **Estimated Phases**: 4
- **Estimated Hours**: 6
- **Structure Level**: 0
- **Complexity Score**: 24.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Coordinate Implementation Analysis](/home/benjamin/.config/.claude/specs/664_coordinage_implementmd_in_order_to_identify_why/reports/001_coordinate_implementation_analysis.md)
  - [Agent Invocation Standards](/home/benjamin/.config/.claude/specs/664_coordinage_implementmd_in_order_to_identify_why/reports/002_agent_invocation_standards.md)
  - [Implementer-Coordinator Capabilities](/home/benjamin/.config/.claude/specs/664_coordinage_implementmd_in_order_to_identify_why/reports/003_implementer_coordinator_capabilities.md)

## Overview

The /coordinate command ALREADY correctly uses Task tool with implementer-coordinator agent (Standard 11 compliant). However, research report 001 revealed a transcript showing scope detection failure where "implement <plan>" was detected as "research-and-plan" instead of "full-implementation", causing a fallback invocation. This plan fixes the workflow scope detection logic and adds clarity documentation to prevent future confusion.

**Key Finding**: The coordinage_implement.md file is an execution TRANSCRIPT (not the command implementation) showing a scope detection bug. The actual coordinate.md command file uses proper behavioral injection at lines 1169-1200.

## Research Summary

**Report 001 - Coordinate Implementation Analysis**:
- coordinage_implement.md is an execution transcript, NOT the command implementation
- Shows scope detection failure: "implement <plan>" detected as "research-and-plan"
- Actual coordinate.md uses proper Task tool invocation with implementer-coordinator agent
- Fallback SlashCommand invocation was emergency workaround for scope bug

**Report 002 - Agent Invocation Standards**:
- Standard 11 requires imperative agent invocation via Task tool
- Command chaining via SlashCommand causes 12.5x context bloat (5000+ vs 400 lines)
- /coordinate already complies 100% with Standard 11 pattern
- Verification checkpoints ensure 100% file creation reliability

**Report 003 - Implementer-Coordinator Capabilities**:
- Haiku-tier agent for deterministic wave-based parallel execution
- Receives pre-calculated paths from Phase 0 optimization
- Orchestrates multiple implementation-executor subagents in parallel
- Achieves 40-60% time savings through wave-based execution
- /coordinate correctly passes all 6 artifact paths via behavioral injection

## Success Criteria
- [x] Workflow scope detection correctly identifies "implement <plan-path>" as full-implementation
- [x] All scope detection test cases pass (research-only, research-and-plan, full-implementation, research-and-revise, debug-only) - 20/20 tests passing
- [x] Documentation clarifies that coordinage_*.md files are transcripts, not implementations
- [ ] No SlashCommand fallback logic exists in coordinate.md
- [ ] Verification tests confirm coordinate.md maintains Standard 11 compliance

## Technical Design

### Architecture

**Current State** (CORRECT):
```
/coordinate → sm_init → workflow-scope-detection.sh → detect_workflow_scope()
          ↓
    STATE_IMPLEMENT → Task tool → implementer-coordinator.md → wave execution
```

**Problem**: detect_workflow_scope() fails to detect "implement <plan>" pattern correctly

**Solution**: Enhance workflow-scope-detection.sh with explicit plan path detection

### Scope Detection Algorithm Enhancement

Current algorithm relies on keyword matching. Need to add:

1. **Plan Path Detection**: If workflow description contains path to .md file in specs/*/plans/, classify as full-implementation
2. **Explicit Keyword Priority**: "implement" keyword should override ambiguous patterns
3. **Fallback Order**: plan-path → explicit-keyword → pattern-matching → default

### Component Integration

- **workflow-scope-detection.sh**: Enhanced detection logic (primary change)
- **coordinate.md**: No changes needed (already correct)
- **Documentation**: Clarify transcript vs implementation distinction

## Implementation Phases

### Phase 1: Enhance Workflow Scope Detection [COMPLETED]
dependencies: []

**Objective**: Fix scope detection to correctly identify "implement <plan>" patterns as full-implementation

**Complexity**: Medium

**Tasks**:
- [x] Read current workflow-scope-detection.sh implementation (file: .claude/lib/workflow-scope-detection.sh)
- [x] Identify detect_workflow_scope() function logic
- [x] Add plan path pattern detection: if workflow_desc contains "specs/.*/plans/.*\.md", return "full-implementation"
- [x] Add explicit "implement" keyword check with higher priority than ambiguous patterns
- [x] Reorder detection logic: 1) revise-patterns 2) plan-path 3) research-only 4) explicit-keywords 5) pattern-matching
- [x] Debug logging already exists for scope detection rationale

**Testing**:
```bash
# Test scope detection with various patterns
bash .claude/lib/workflow-scope-detection.sh "implement specs/661_auth/plans/001_implementation.md"
# Expected: full-implementation

bash .claude/lib/workflow-scope-detection.sh "plan authentication feature"
# Expected: research-and-plan

bash .claude/lib/workflow-scope-detection.sh "research async patterns"
# Expected: research-only

bash .claude/lib/workflow-scope-detection.sh "revise specs/027_auth/plans/001_plan.md based on feedback"
# Expected: research-and-revise
```

**Expected Duration**: 2 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (scope detection tests for all 4 patterns)
- [ ] Git commit created: `feat(664): complete Phase 1 - Enhance Workflow Scope Detection`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Add Scope Detection Tests [COMPLETED]
dependencies: [1]

**Objective**: Create comprehensive test suite for workflow scope detection edge cases

**Complexity**: Low

**Tasks**:
- [x] Create test file: .claude/tests/test_workflow_scope_detection.sh
- [x] Test case 1: "implement <plan-path>" → full-implementation
- [x] Test case 2: "plan <feature>" → research-and-plan
- [x] Test case 3: "research <topic>" → research-only
- [x] Test case 4: "revise <plan> with <changes>" → research-and-revise
- [x] Test case 5: "debug <issue>" → debug-only
- [x] Test case 6: Ambiguous input → default to research-and-plan (not full-implementation)
- [x] Add assertions for each test case using existing test framework pattern
- [x] Test automatically discovered by .claude/tests/run_all_tests.sh (20 tests total)

**Testing**:
```bash
# Run new scope detection tests
bash .claude/tests/test_workflow_scope_detection.sh

# Run full test suite
bash .claude/tests/run_all_tests.sh
```

**Expected Duration**: 1.5 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (all 6+ scope detection tests)
- [ ] Git commit created: `feat(664): complete Phase 2 - Add Scope Detection Tests`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Update Documentation - Clarify Transcript vs Implementation [COMPLETED]
dependencies: [2]

**Objective**: Add documentation explaining that coordinage_*.md files are execution transcripts, not command implementations

**Complexity**: Low

**Tasks**:
- [x] Read .claude/docs/guides/coordinate-command-guide.md
- [x] Add section "Transcript Files vs Command Implementation" explaining:
  - coordinage_*.md files are execution logs/transcripts
  - coordinate.md is the actual command implementation
  - Transcripts may show error conditions (like scope detection failures)
  - Transcripts should not be used as reference for correct patterns
- [x] Add comprehensive troubleshooting guidance for scope detection failures with debug logging
- [x] Updated workflow scope detection documentation with priority order (1-5)
- [x] Cross-reference Standard 11 compliance verification with code examples
- [x] Add examples of correct workflow invocations for all 5 scope types

**Testing**:
```bash
# Verify documentation renders correctly
cat .claude/docs/guides/coordinate-command-guide.md | grep -A 10 "Transcript Files"
```

**Expected Duration**: 1.5 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (documentation validation - no broken links)
- [ ] Git commit created: `docs(664): complete Phase 3 - Clarify Transcript vs Implementation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Verification and Regression Testing
dependencies: [1, 2, 3]

**Objective**: Verify all changes work correctly and coordinate.md still complies with Standard 11

**Complexity**: Medium

**Tasks**:
- [ ] Run full test suite: bash .claude/tests/run_all_tests.sh
- [ ] Verify coordinate.md still uses Task tool (not SlashCommand) for implementer-coordinator invocation
- [ ] Verify no fallback SlashCommand logic exists in coordinate.md: `grep -n "SlashCommand" .claude/commands/coordinate.md` (should return no matches)
- [ ] Verify scope detection correctly handles all test cases from Phase 2
- [ ] Test actual /coordinate invocation with "implement <plan-path>" pattern
- [ ] Verify implementer-coordinator receives all 6 artifact paths correctly
- [ ] Check that sm_init correctly detects full-implementation scope
- [ ] Run Standard 11 compliance validation: bash .claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md
- [ ] Verify no regression in existing /coordinate functionality

**Testing**:
```bash
# Full regression test suite
bash .claude/tests/run_all_tests.sh

# Standard 11 compliance check
bash .claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md

# Actual workflow test (if safe)
# /coordinate implement .claude/specs/664_*/plans/001_*.md
```

**Expected Duration**: 1 hour

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (full test suite, Standard 11 validation)
- [ ] Git commit created: `test(664): complete Phase 4 - Verification and Regression Testing`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Tests
- Workflow scope detection function tests (6+ test cases)
- Plan path pattern matching tests
- Keyword priority tests

### Integration Tests
- /coordinate command with "implement <plan>" pattern
- State machine initialization with detected scope
- Artifact path injection verification

### Regression Tests
- Existing /coordinate test suite (all must still pass)
- Standard 11 compliance validation
- No SlashCommand usage verification

### Performance Tests
- Scope detection should complete in <100ms
- No performance regression in coordinate initialization

## Documentation Requirements

### Files to Update
1. **.claude/docs/guides/coordinate-command-guide.md**
   - Add "Transcript Files vs Command Implementation" section
   - Update "Common Issues" with scope detection troubleshooting
   - Add examples of correct workflow invocations

2. **.claude/lib/workflow-scope-detection.sh**
   - Add inline comments explaining detection algorithm
   - Document priority order for pattern matching

3. **This Plan File**
   - Mark phases complete as they finish
   - Update with any implementation discoveries

### Documentation Standards
- Follow CLAUDE.md documentation policy
- No historical commentary ("previously", "new", etc.)
- Clear, present-focused language
- Include code examples where helpful

## Dependencies

### External Dependencies
- workflow-scope-detection.sh must exist (.claude/lib/)
- workflow-state-machine.sh must correctly call detect_workflow_scope()
- Test framework infrastructure (.claude/tests/)

### Internal Dependencies
- Phase 2 depends on Phase 1 (need enhanced detection to test)
- Phase 3 independent (can run in parallel with Phase 2)
- Phase 4 depends on Phases 1, 2, 3 (verification requires all changes)

**Note**: Phases 2 and 3 can execute in parallel for 25% time savings (implement using wave-based execution)

## Risk Assessment

### Low Risk
- Documentation updates (Phase 3)
- Test additions (Phase 2)

### Medium Risk
- Scope detection logic changes (Phase 1)
  - Mitigation: Comprehensive test coverage, regression testing
  - Fallback: Detection defaults to full-implementation (safe default)

### High Risk
- None (coordinate.md requires NO changes, already correct)

## Rollback Strategy

If scope detection changes cause issues:
1. Revert workflow-scope-detection.sh to previous version
2. Tests will fail but coordinate.md remains functional
3. Scope detection defaults to full-implementation (safe fallback)
4. No user-facing impact (same behavior as before)

## Performance Targets

- Scope detection: <100ms (no regression from current)
- Test suite: <5 seconds total
- Documentation build: <1 second

## Completion Checklist

- [ ] All 4 phases completed
- [ ] All tests passing (unit + integration + regression)
- [ ] Documentation updated and reviewed
- [ ] Standard 11 compliance verified (coordinate.md)
- [ ] No SlashCommand usage in coordinate.md
- [ ] Scope detection correctly handles "implement <plan>" pattern
- [ ] Git commits created for each phase
- [ ] Implementation summary created
