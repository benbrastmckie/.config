# Implementation Plan: /lean-plan Hard Barrier and Checkpoint Enforcement

## Metadata

**Date**: 2025-12-09
**Feature**: Add hard barrier validation and checkpoint enforcement to /lean-plan command
**Status**: [SUPERSEDED]
**Estimated Hours**: 3-5 hours
**Standards File**: /home/benjamin/.config/CLAUDE.md
**Research Reports**: [Nested Task Claims Analysis](../reports/001-nested-task-claims-analysis.md)

## Superseded Notice

**This plan was superseded by [068_lean_plan_wave_optimization](../../068_lean_plan_wave_optimization/plans/001-lean-plan-wave-optimization-plan.md) on 2025-12-09.**

Plan 068 implemented all the hard barrier and checkpoint enforcement features proposed in this plan, plus additional wave optimization features. Specifically:

| Feature from Plan 997 | Implementation in Plan 068 |
|----------------------|---------------------------|
| Trace file creation in research-coordinator | ✅ Implemented: Lines 344-365 in research-coordinator.md create `.invocation-trace.log` |
| Hard barrier validation after coordinator Task | ✅ Implemented: Block 1e-validate + Block 1f in lean-plan.md |
| Fatal error if no reports created | ✅ Implemented: Block 1f with 50% threshold validation |
| Unit tests for hard barrier enforcement | ✅ Implemented: Phase 5 integration tests |
| Documentation updates | ✅ Implemented: lean-plan-command-guide.md updated |

**DO NOT IMPLEMENT THIS PLAN** - all features are already in production via Plan 068.

---

## Original Overview (Historical Reference)

Add hard barrier validation and checkpoint enforcement to `/lean-plan` command to match `/implement`'s proven nested Task pattern. Research has confirmed that nested Task invocation works (contrary to 063 plan claims). This plan adds: 1) Trace file creation in research-coordinator to prove execution, 2) Hard barrier validation block after coordinator Task returns, 3) Fatal error if no reports created.

**CRITICAL**: This plan explicitly does NOT implement Pattern A (library extraction) from the 063 plan, as research shows that approach would create architectural inconsistency with the working `/implement` command.

## Success Criteria

- [ ] research-coordinator creates invocation trace file at start of execution
- [ ] research-coordinator logs each specialist Task invocation to trace file
- [ ] /lean-plan has hard barrier validation block after coordinator Task returns
- [ ] Hard barrier validates trace file exists (fatal error if missing)
- [ ] Hard barrier validates research reports created (fatal error if zero reports)
- [ ] All existing /lean-plan tests pass with new validation
- [ ] New test validates hard barrier enforcement (trace file missing scenario)
- [ ] New test validates hard barrier enforcement (zero reports scenario)

## Implementation Phases

### Phase 1: Add Checkpoint Trace File to research-coordinator [NOT STARTED]

**Objective**: Modify research-coordinator agent to create trace file proving Task execution occurred.

**Tasks**:
- [ ] Read research-coordinator.md to locate STEP 3 (specialist invocation loop)
- [ ] Add trace file creation at start of STEP 3: `echo "COORDINATOR_START: $(date)" > "$REPORT_DIR/.invocation-trace.log"`
- [ ] Add specialist invocation logging after each Task tool call: `echo "SPECIALIST_INVOKED: topic_$i at $(date)" >> "$REPORT_DIR/.invocation-trace.log"`
- [ ] Add completion marker at end of STEP 3: `echo "COORDINATOR_COMPLETE: $(date)" >> "$REPORT_DIR/.invocation-trace.log"`
- [ ] Verify trace file path uses correct REPORT_DIR variable from agent context

**Dependencies**: None

**Validation**:
- [ ] Trace file creation uses absolute paths from agent context
- [ ] Trace file captures: start timestamp, each specialist invocation, completion timestamp
- [ ] Trace file location is accessible to /lean-plan command for validation

### Phase 2: Add Hard Barrier Validation Block to /lean-plan [NOT STARTED]

**Objective**: Add Block 1f validation after research-coordinator Task invocation in /lean-plan command.

**Tasks**:
- [ ] Read lean-plan.md to locate Block 1e-exec (research-coordinator Task invocation)
- [ ] Insert new Block 1f immediately after Block 1e-exec
- [ ] Validate trace file exists: `[ ! -f "$RESEARCH_DIR/.invocation-trace.log" ]` → fatal error
- [ ] Count created reports: `CREATED_REPORTS=$(ls "$RESEARCH_DIR"/[0-9][0-9][0-9]-*.md 2>/dev/null | wc -l)`
- [ ] Validate reports exist: `[ "$CREATED_REPORTS" -eq 0 ]` → fatal error
- [ ] Add descriptive error messages for both failure modes
- [ ] Update block consolidation count in lean-plan.md header

**Dependencies**: Phase 1 (trace file must be created by coordinator)

**Validation**:
- [ ] Block 1f uses correct variable names ($RESEARCH_DIR matches coordinator's $REPORT_DIR)
- [ ] Fatal errors exit with non-zero status code
- [ ] Error messages clearly distinguish trace file missing vs zero reports created
- [ ] Block follows output suppression standards (2>/dev/null on non-critical commands)

### Phase 3: Add Unit Tests for Hard Barrier Enforcement [NOT STARTED]

**Objective**: Create tests validating hard barrier catches delegation failures.

**Tasks**:
- [ ] Create test file: `.claude/tests/commands/test_lean_plan_hard_barrier.sh`
- [ ] Add test case: trace file missing scenario (coordinator Task skipped)
- [ ] Add test case: zero reports created scenario (coordinator failed silently)
- [ ] Add test case: successful execution scenario (trace file + reports present)
- [ ] Mock research-coordinator to simulate each scenario
- [ ] Verify exit codes: 1 for failures, 0 for success
- [ ] Verify error messages match expected patterns
- [ ] Add tests to .claude/tests/commands/README.md

**Dependencies**: Phase 2 (hard barrier validation must exist)

**Validation**:
- [ ] Tests run non-interactively (automation_type: automated)
- [ ] Tests use temporary directories for isolation
- [ ] Tests clean up artifacts on completion
- [ ] Test output follows JUnit XML format for CI integration

### Phase 4: Integration Testing with Existing /lean-plan Tests [NOT STARTED]

**Objective**: Verify new validation doesn't break existing /lean-plan functionality.

**Tasks**:
- [ ] Run existing /lean-plan test suite: `bash .claude/tests/commands/test_lean_plan_delegation.sh`
- [ ] Verify all existing tests pass with new hard barrier validation
- [ ] Check for false positives (valid executions rejected)
- [ ] Check for false negatives (invalid executions accepted)
- [ ] Update test fixtures if needed to include trace files
- [ ] Document any behavioral changes in .claude/tests/commands/README.md

**Dependencies**: Phase 3 (new tests must exist)

**Validation**:
- [ ] Zero test failures in existing test suite
- [ ] No new warnings or deprecation notices
- [ ] Test execution time increase < 10% (hard barrier adds minimal overhead)
- [ ] Coverage report shows new validation blocks executed

### Phase 5: Documentation Updates [NOT STARTED]

**Objective**: Document hard barrier pattern and rationale for rejecting Pattern A.

**Tasks**:
- [ ] Update .claude/docs/guides/commands/lean-plan-command-guide.md with hard barrier explanation
- [ ] Add troubleshooting section: "Trace file missing" error resolution
- [ ] Add troubleshooting section: "No reports created" error resolution
- [ ] Update hierarchical-agents-examples.md Example 8 with hard barrier pattern
- [ ] Document why Pattern A was rejected (architectural inconsistency with /implement)
- [ ] Add cross-reference to implement.md for pattern consistency
- [ ] Update TODO.md to mark 063 plan as superseded

**Dependencies**: Phase 4 (implementation must be complete and tested)

**Validation**:
- [ ] Documentation includes code examples from actual implementation
- [ ] Troubleshooting steps are actionable (specific commands to run)
- [ ] Cross-references use correct relative paths
- [ ] No historical commentary (follows writing standards)

## Testing Strategy

### Unit Tests
- Trace file creation (research-coordinator)
- Hard barrier validation logic (trace file missing)
- Hard barrier validation logic (zero reports)
- Successful execution path

### Integration Tests
- Full /lean-plan execution with research-coordinator delegation
- Backwards compatibility with existing test suite
- Error propagation to /lean-plan command
- Trace file cleanup on workflow completion

### Manual Validation
- Run /lean-plan on real Lean project to verify end-to-end flow
- Intentionally break trace file creation to trigger hard barrier
- Intentionally break report creation to trigger hard barrier
- Verify error messages are clear and actionable

## Dependencies

### Internal Dependencies
- Phase 2 depends on Phase 1 (trace file must exist before validation)
- Phase 3 depends on Phase 2 (tests validate hard barrier logic)
- Phase 4 depends on Phase 3 (integration tests run after unit tests)
- Phase 5 depends on Phase 4 (documentation reflects tested implementation)

### External Dependencies
- research-coordinator.md agent file (modified in Phase 1)
- lean-plan.md command file (modified in Phase 2)
- hierarchical-agents-examples.md (updated in Phase 5)

## Rollback Plan

### If Hard Barrier Causes False Positives
1. Add debug flag to /lean-plan: `--skip-hard-barrier` for troubleshooting
2. Log validation state to debug file before fatal exit
3. Adjust validation thresholds (e.g., warn instead of fatal for first iteration)

### If Trace File Path Issues
1. Use fallback location: `$CLAUDE_PROJECT_DIR/.claude/tmp/lean-plan-trace.log`
2. Document path resolution logic in lean-plan-command-guide.md
3. Add path validation before trace file check

### If Integration Tests Fail
1. Revert Phase 1 and Phase 2 changes
2. Isolate failing test case
3. Add test case to Phase 3 before re-implementing
4. Use feature flag to enable hard barrier incrementally

## Notes

### Pattern A Rejection Rationale
Research conclusively shows nested Task invocation works (proven by `/implement` command using 3 levels). Pattern A (library extraction) would create architectural inconsistency:
- `/implement`: Primary → Coordinator (Task) → Specialists (nested Task)
- `/lean-plan` with Pattern A: Primary sources library → Specialists (Task)

This plan maintains consistency by keeping the nested Task pattern and adding enforcement mechanisms.

### Alignment with /implement Pattern
The `/implement` command uses:
1. Nested Task invocation (primary → implementer-coordinator → implementation-executor)
2. Brief summary parsing for context reduction
3. Hard barriers implicit in wave-based execution

This plan adds explicit hard barriers to `/lean-plan` following the same architectural principles.

### Trace File Design
The `.invocation-trace.log` file serves as proof-of-execution, not a data structure. Contents:
```
COORDINATOR_START: 2025-12-09 14:23:45
SPECIALIST_INVOKED: topic_1 at 2025-12-09 14:23:47
SPECIALIST_INVOKED: topic_2 at 2025-12-09 14:24:12
SPECIALIST_INVOKED: topic_3 at 2025-12-09 14:24:38
COORDINATOR_COMPLETE: 2025-12-09 14:25:01
```

This is sufficient for hard barrier validation. More sophisticated monitoring should use the error logging system.
