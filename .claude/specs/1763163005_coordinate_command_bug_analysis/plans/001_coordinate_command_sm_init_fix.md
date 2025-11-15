# /coordinate Command sm_init Bug Fix - Implementation Plan

## Metadata
- **Date**: 2025-11-14
- **Feature**: Fix /coordinate command sm_init parameter mismatch bug
- **Scope**: Add Phase 0.1 workflow classification before sm_init call
- **Estimated Phases**: 5
- **Estimated Hours**: 4
- **Structure Level**: 0
- **Complexity Score**: 38.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Comprehensive Overview](../reports/001_coordinate_command_bug_analysis/OVERVIEW.md)
  - [Root Cause Analysis - SM Init Premature Invocation](../reports/001_coordinate_command_bug_analysis/001_root_cause_analysis_sm_init_premature_invocation.md)
  - [Workflow-Classifier Agent Integration Pattern](../reports/001_coordinate_command_bug_analysis/002_workflow_classifier_agent_integration_pattern.md)
  - [Behavioral Injection Standards Compliance Fix](../reports/001_coordinate_command_bug_analysis/003_behavioral_injection_standards_compliance_fix.md)

## Overview

The /coordinate command fails with 100% failure rate due to a breaking change in `sm_init()` signature (commit ce1d29a1). The function was refactored from 2 parameters to 5 parameters to accept pre-computed classification from the workflow-classifier agent, but the /coordinate command was not updated to invoke the agent before calling sm_init().

**Root Cause**: Breaking library change without atomic caller updates (Phases 1-3 complete, Phases 4-5 incomplete)

**Solution**: Add Phase 0.1 agent invocation block before sm_init call, parse classification JSON, pass 5 parameters to sm_init, and add workflow-llm-classifier.sh to REQUIRED_LIBS arrays.

## Research Summary

Key findings from research reports:

**Root Cause Analysis** (Report 001):
- sm_init() signature changed from 2 to 5 parameters in commit ce1d29a1 (2025-11-14 16:35)
- /coordinate command NOT updated with new invocation pattern
- Clean-break philosophy: no backward compatibility shims
- Blast radius: All 3 orchestration commands affected (/coordinate, /orchestrate, /supervise)

**Integration Pattern** (Report 002):
- workflow-classifier agent (530 lines) performs 4-step semantic classification
- Task tool invocation with imperative language ("EXECUTE NOW")
- Returns CLASSIFICATION_COMPLETE: {JSON} with workflow_type, research_complexity, research_topics
- <5s classification time (Haiku model)

**Standards Compliance** (Report 003):
- /coordinate currently complies with Standards 0, 11, 14, 15
- Missing workflow-llm-classifier.sh in REQUIRED_LIBS arrays (4 locations)
- Must maintain Standard 11 imperative agent invocation pattern
- Verification checkpoints already correct (Standard 0)

## Success Criteria

- [ ] Phase 0.1 classification block added before sm_init call
- [ ] Agent invocation uses Task tool with imperative language (Standard 11)
- [ ] Classification JSON parsed with fail-fast verification
- [ ] sm_init called with 5 parameters (workflow_type, research_complexity, research_topics_json)
- [ ] workflow-llm-classifier.sh added to all 4 REQUIRED_LIBS arrays
- [ ] All 5 workflow types tested and working (research-only, research-and-plan, research-and-revise, full-implementation, debug-only)
- [ ] Standards 0, 11, 14, 15 compliance maintained
- [ ] Zero regression in agent delegation rate (>90%)
- [ ] Zero regression in file creation reliability (100%)

## Technical Design

### Architecture Changes

**Before** (BROKEN):
```
/coordinate → sm_init(desc, cmd) → INTERNAL classification (DELETED) → ERROR
```

**After** (FIXED):
```
/coordinate → Phase 0.1: workflow-classifier agent → Parse JSON → sm_init(desc, cmd, type, complexity, topics) → SUCCESS
```

### Component Modifications

1. **New Phase 0.1** (lines 138-162): Invoke workflow-classifier agent via Task tool
2. **Modified sm_init call** (line 167): Pass 5 parameters instead of 2
3. **Updated REQUIRED_LIBS** (lines 233, 236, 239, 242): Add workflow-llm-classifier.sh
4. **Existing verification** (lines 174-188): Keep unchanged (already correct)

### Standards Alignment

- **Standard 0 (Execution Enforcement)**: Verification checkpoints after classification parsing
- **Standard 11 (Imperative Agent Invocation)**: "EXECUTE NOW: USE the Task tool" directive
- **Standard 14 (Executable/Documentation Separation)**: +60 lines within 1,200 orchestrator limit
- **Standard 15 (Library Sourcing Order)**: Explicit workflow-llm-classifier.sh dependency

## Implementation Phases

### Phase 1: Add Phase 0.1 Workflow Classification Block
dependencies: []

**Objective**: Insert agent invocation block before sm_init call with JSON parsing and verification

**Complexity**: Medium

**Tasks**:
- [ ] Create backup of coordinate.md: `cp .claude/commands/coordinate.md .claude/commands/coordinate.md.backup-$(date +%Y%m%d-%H%M%S)`
- [ ] Insert Phase 0.1 header comment after line 138 (file: .claude/commands/coordinate.md)
- [ ] Add Task tool invocation block with imperative directive "EXECUTE NOW: USE the Task tool"
- [ ] Add agent behavioral file reference: `${CLAUDE_PROJECT_DIR}/.claude/agents/workflow-classifier.md`
- [ ] Inject workflow context: `SAVED_WORKFLOW_DESC` and command name "coordinate"
- [ ] Add completion signal requirement: `CLASSIFICATION_COMPLETE: {JSON}`
- [ ] Insert bash block for classification JSON parsing using grep and jq
- [ ] Add verification checkpoints for workflow_type, research_complexity, research_topics (Standard 0)
- [ ] Export classification variables for sm_init consumption
- [ ] Verify Phase 0.1 block is self-contained and follows behavioral injection pattern

**Testing**:
```bash
# Verify Phase 0.1 syntax
bash -n .claude/commands/coordinate.md

# Test classification with simple description
/coordinate "research authentication patterns"
# Expected: Agent returns CLASSIFICATION_COMPLETE with workflow_type="research-only"
```

**Expected Duration**: 45 minutes

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (Phase 0.1 syntax valid)
- [ ] Git commit created: `feat(coordinate): add Phase 0.1 workflow-classifier agent invocation`
- [ ] Update this plan file with phase completion status

---

### Phase 2: Modify sm_init Call to Pass 5 Parameters
dependencies: [1]

**Objective**: Update sm_init invocation to pass pre-computed classification from Phase 0.1

**Complexity**: Low

**Tasks**:
- [ ] Locate sm_init call at line 167 (file: .claude/commands/coordinate.md)
- [ ] Replace 2-parameter call with 5-parameter call: `sm_init "$SAVED_WORKFLOW_DESC" "coordinate" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "$RESEARCH_TOPICS_JSON"`
- [ ] Update error message to show classification parameters for debugging
- [ ] Remove obsolete reference to WORKFLOW_CLASSIFICATION_MODE=regex-only (deleted in Phase 3 of ce1d29a1)
- [ ] Update comment to reference Spec 1763161992 Phase 2
- [ ] Verify existing verification checkpoints (lines 174-188) remain unchanged

**Testing**:
```bash
# Test sm_init parameter passing
/coordinate "implement user login with OAuth"
# Expected: sm_init succeeds with 5 parameters, no validation errors
```

**Expected Duration**: 15 minutes

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (sm_init accepts 5 parameters)
- [ ] Git commit created: `feat(coordinate): update sm_init call to 5-parameter signature`
- [ ] Update this plan file with phase completion status

---

### Phase 3: Add workflow-llm-classifier.sh to REQUIRED_LIBS Arrays
dependencies: [1, 2]

**Objective**: Fix Standard 15 compliance by explicitly listing workflow-llm-classifier.sh dependency

**Complexity**: Low

**Tasks**:
- [ ] Locate REQUIRED_LIBS array for research-only scope at line 233 (file: .claude/commands/coordinate.md)
- [ ] Add "workflow-llm-classifier.sh" to research-only REQUIRED_LIBS array
- [ ] Locate REQUIRED_LIBS array for research-and-plan/revise scope at line 236
- [ ] Add "workflow-llm-classifier.sh" to research-and-plan/revise REQUIRED_LIBS array
- [ ] Locate REQUIRED_LIBS array for full-implementation scope at line 239
- [ ] Add "workflow-llm-classifier.sh" to full-implementation REQUIRED_LIBS array
- [ ] Locate REQUIRED_LIBS array for debug-only scope at line 242
- [ ] Add "workflow-llm-classifier.sh" to debug-only REQUIRED_LIBS array
- [ ] Verify insertion maintains alphabetical or logical ordering

**Testing**:
```bash
# Test library sourcing for all workflow scopes
/coordinate "research authentication"  # research-only
/coordinate "research and create plan for authentication"  # research-and-plan
/coordinate "implement authentication with tests"  # full-implementation
/coordinate "debug authentication race condition"  # debug-only
# Expected: No "command not found" errors for workflow-llm-classifier.sh functions
```

**Expected Duration**: 15 minutes

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (all 4 workflow scopes source library correctly)
- [ ] Git commit created: `fix(coordinate): add workflow-llm-classifier.sh to REQUIRED_LIBS (Standard 15)`
- [ ] Update this plan file with phase completion status

---

### Phase 4: Integration Testing - All Workflow Types
dependencies: [1, 2, 3]

**Objective**: Verify all 5 workflow types classify correctly and sm_init succeeds

**Complexity**: Medium

**Tasks**:
- [ ] Create test script: `.claude/tests/test_coordinate_sm_init_fix.sh`
- [ ] Test research-only workflow: `/coordinate "research authentication patterns"`
- [ ] Verify workflow_type="research-only", complexity=1, topics array length=1
- [ ] Test research-and-plan workflow: `/coordinate "research OAuth patterns and create implementation plan"`
- [ ] Verify workflow_type="research-and-plan", complexity=2, topics array length=2
- [ ] Test research-and-revise workflow: `/coordinate "research new session patterns and update plan specs/042_auth/plans/001_*.md"`
- [ ] Verify workflow_type="research-and-revise", complexity=2, EXISTING_PLAN_PATH set
- [ ] Test full-implementation workflow: `/coordinate "implement complete authentication system with OAuth, sessions, and testing"`
- [ ] Verify workflow_type="full-implementation", complexity=4, topics array length=4
- [ ] Test debug-only workflow: `/coordinate "debug session timeout race condition in auth module"`
- [ ] Verify workflow_type="debug-only", complexity=2, topics array focused on root cause
- [ ] Verify classification time <5s for all tests
- [ ] Verify sm_init succeeds with 0 exit code for all tests
- [ ] Verify WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON exported correctly

**Testing**:
```bash
# Run comprehensive test suite
bash .claude/tests/test_coordinate_sm_init_fix.sh

# Manual verification
/coordinate "research authentication patterns and implement OAuth login with tests"
# Expected:
# 1. Classification completes in <5s
# 2. workflow_type="full-implementation"
# 3. research_complexity=3
# 4. research_topics array has 3 topics (auth patterns, OAuth, testing)
# 5. sm_init succeeds
# 6. Command proceeds to research phase
```

**Expected Duration**: 1 hour

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (15/15 test cases: 5 workflow types × 3 verification points)
- [ ] Git commit created: `test(coordinate): add sm_init fix integration tests`
- [ ] Update this plan file with phase completion status

---

### Phase 5: Regression Testing - Standards Compliance
dependencies: [1, 2, 3, 4]

**Objective**: Verify Standards 0, 11, 14, 15 compliance maintained without regressions

**Complexity**: Low

**Tasks**:
- [ ] Run Standard 0 verification: Check all verification checkpoints execute (file: .claude/commands/coordinate.md, lines 151-154, 174-186, 213-216)
- [ ] Run Standard 11 verification: Validate agent invocation uses imperative pattern (search for "EXECUTE NOW")
- [ ] Run Standard 14 verification: Check file size within orchestrator limit (1,200 lines): `wc -l .claude/commands/coordinate.md`
- [ ] Run Standard 15 verification: Verify library sourcing order maintained (state-machine → persistence → error-handling → verification → workflow-llm-classifier)
- [ ] Test agent delegation rate: Verify >90% for research phase (should invoke research-specialist agent)
- [ ] Test file creation reliability: Verify 100% for all artifact types (reports, plans, debug)
- [ ] Test error handling: Verify fail-fast on classification parsing errors
- [ ] Test error handling: Verify fail-fast on sm_init parameter validation errors
- [ ] Document any deviations from baseline metrics

**Testing**:
```bash
# Standard 0: Verification checkpoints
/coordinate "research test" 2>&1 | grep "VERIFICATION CHECKPOINT"
# Expected: 3+ verification checkpoints execute

# Standard 11: Imperative agent invocation
grep -c "EXECUTE NOW" .claude/commands/coordinate.md
# Expected: ≥2 (Phase 0.1 + existing agent invocations)

# Standard 14: File size limit
wc -l .claude/commands/coordinate.md
# Expected: <1,200 lines (1,084 + 60 = 1,144 lines, within limit)

# Standard 15: Library sourcing order
head -150 .claude/commands/coordinate.md | grep "source.*\.sh" | nl
# Expected: workflow-state-machine.sh first, then state-persistence.sh, etc.

# Agent delegation rate
/coordinate "research three topics" 2>&1 | grep -c "research-sub-supervisor"
# Expected: ≥1 (hierarchical supervision for 3+ topics)

# File creation reliability
/coordinate "research and plan authentication" 2>&1 | grep "REPORT_CREATED\|PLAN_CREATED"
# Expected: 100% creation rate (2/2 files created)
```

**Expected Duration**: 1 hour

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (all standards compliance checks pass)
- [ ] Git commit created: `test(coordinate): verify standards compliance post-fix`
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Unit Testing
- Phase 0.1 classification JSON parsing (jq validation)
- sm_init parameter validation (5 required parameters)
- Library sourcing (workflow-llm-classifier.sh availability)

### Integration Testing
- 5 workflow types × 3 orchestration commands = 15 test cases
- Classification accuracy (workflow_type matches intent)
- State machine initialization (exports verified)
- End-to-end workflow execution (research → plan → implement)

### Regression Testing
- Standards 0, 11, 14, 15 compliance maintained
- Agent delegation rate >90%
- File creation reliability 100%
- Performance: Classification <5s, no timeouts

### Test Coverage
- **Target**: 95% (critical path coverage)
- **Focus Areas**: Agent invocation, JSON parsing, error handling

## Documentation Requirements

### Code Comments
- Phase 0.1 header explaining workflow-classifier integration
- sm_init call comment referencing Spec 1763161992
- REQUIRED_LIBS comment explaining transitive dependency

### Command Guide Updates
- `.claude/docs/guides/coordinate-command-guide.md`: Add Phase 0.1 classification section
- Document workflow-classifier agent integration pattern
- Add troubleshooting section for classification failures

### Standards Updates
- No changes required (pattern already documented in Standard 11)

### Changelog
- Add entry documenting sm_init breaking change fix
- Reference commit ce1d29a1 as original breaking change
- Document Phases 4-5 completion

## Dependencies

### External Dependencies
- workflow-classifier agent (`.claude/agents/workflow-classifier.md`) - EXISTS
- workflow-state-machine.sh (refactored sm_init) - EXISTS
- workflow-llm-classifier.sh (parsing utilities) - EXISTS
- error-handling.sh (handle_state_error) - EXISTS
- verification-helpers.sh (verify_state_variable) - EXISTS

### Internal Dependencies
- Phase 2 depends on Phase 1 (classification variables must exist before sm_init)
- Phase 3 depends on Phases 1-2 (library needed for classification parsing)
- Phase 4 depends on Phases 1-3 (all changes in place before testing)
- Phase 5 depends on Phase 4 (regression testing after integration testing)

### Blocking Issues
- None (all required components exist)

## Risk Assessment

### Technical Risks
- **Low**: Agent classification accuracy (<98%)
  - Mitigation: Agent tested with 34 comprehensive tests (100% pass rate)
- **Low**: JSON parsing failures
  - Mitigation: Fail-fast verification with clear error messages
- **Low**: Performance degradation (classification >5s)
  - Mitigation: Haiku model optimized for <5s response time

### Process Risks
- **Medium**: Regression in other orchestration commands
  - Mitigation: Apply same fix pattern to /orchestrate and /supervise (future work)
- **Low**: Standards compliance regression
  - Mitigation: Comprehensive regression testing in Phase 5

## Rollback Plan

If fix introduces regressions:

1. **Immediate Rollback**: `git revert <commit-hash>` for each phase commit
2. **Restore Backup**: `cp .claude/commands/coordinate.md.backup-* .claude/commands/coordinate.md`
3. **Alternative Approach**: Add backward-compatible transition period in sm_init
4. **Escalation**: Document issue and create new research report

## Performance Metrics

### Baseline (Before Fix)
- Classification time: N/A (100% failure rate)
- sm_init success rate: 0%
- Orchestration completion rate: 0%

### Target (After Fix)
- Classification time: <5s (Haiku model)
- sm_init success rate: 100%
- Orchestration completion rate: 100%
- Agent delegation rate: >90% (maintained)
- File creation reliability: 100% (maintained)

### Measurement
- Classification time: Measure agent Task tool duration
- Success rates: Test with 15 workflow type combinations
- Delegation rate: Count Task tool invocations in logs
- File creation: Verify all artifacts created at expected paths

## Future Enhancements

1. **Apply Fix to Other Commands** (2 hours):
   - Update /orchestrate command (same pattern)
   - Update /supervise command (same pattern)

2. **Create Migration Script** (1 hour):
   - Automated pattern detection in commands
   - Bulk update for sm_init calls project-wide

3. **Add Pre-Commit Hook** (30 minutes):
   - Detect function signature changes
   - Validate caller parameter counts match

4. **Contract Testing** (1 hour):
   - Library function signature tests
   - Command invocation pattern tests

## References

### Research Reports
- [OVERVIEW.md](../reports/001_coordinate_command_bug_analysis/OVERVIEW.md) - Comprehensive analysis (1,021 lines)
- [001_root_cause_analysis_sm_init_premature_invocation.md](../reports/001_coordinate_command_bug_analysis/001_root_cause_analysis_sm_init_premature_invocation.md) - Timeline and git history (501 lines)
- [002_workflow_classifier_agent_integration_pattern.md](../reports/001_coordinate_command_bug_analysis/002_workflow_classifier_agent_integration_pattern.md) - Integration pattern (824 lines)
- [003_behavioral_injection_standards_compliance_fix.md](../reports/001_coordinate_command_bug_analysis/003_behavioral_injection_standards_compliance_fix.md) - Standards compliance (report not fully read)

### Source Files
- `.claude/commands/coordinate.md` (1,084 lines) - Primary file to modify
- `.claude/lib/workflow-state-machine.sh` (lines 334-399) - Refactored sm_init function
- `.claude/agents/workflow-classifier.md` (530 lines) - Agent behavioral file
- `.claude/lib/workflow-llm-classifier.sh` - Parsing and validation utilities

### Documentation
- `.claude/docs/reference/command_architecture_standards.md` - Standards 0, 11, 14, 15
- `.claude/docs/concepts/patterns/behavioral-injection.md` - Agent invocation pattern
- `.claude/docs/guides/coordinate-command-guide.md` - Command usage guide

### Related Commits
- ce1d29a1 (2025-11-14 16:35) - Breaking change commit (sm_init refactor)
- 2c182d4c - Removed regex classification
- 56406289 - Removed auto-fallback
- 14a268b6 - Semantic filename persistence

## Notes

This plan addresses the incomplete migration from Spec 1763161992 (Phases 1-3 complete, Phases 4-5 incomplete). The fix maintains the project's clean-break philosophy while completing the command updates required by the breaking change.

**Key Decision**: No backward compatibility shim added to sm_init (maintains fail-fast philosophy). Commands must invoke workflow-classifier agent before sm_init.

**Scope Limitation**: This plan fixes /coordinate only. /orchestrate and /supervise require separate fixes using the same pattern (estimated 2 additional hours).

**Priority**: Critical (P0) - Complete orchestration outage affecting all multi-agent workflows. Fix should be applied immediately.
