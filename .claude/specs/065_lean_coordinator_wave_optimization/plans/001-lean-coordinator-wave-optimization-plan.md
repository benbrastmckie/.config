# Implementation Plan: Lean Coordinator Wave Optimization

## Metadata

- **Date**: 2025-12-09
- **Feature**: Optimize lean-coordinator for plan-driven wave execution without unnecessary analysis overhead
- **Status**: [COMPLETE]
- **Estimated Hours**: 18-24 hours
- **Complexity Score**: 165 (Tier 2)
- **Structure Level**: 1 (Phase files)
- **Estimated Phases**: 10
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Research Report: /lean-implement Command Analysis](../reports/001-lean-implement-analysis.md)
  - [Wave-Based Orchestration Architecture for Lean Coordinator](../reports/002-wave-orchestration-architecture.md)
  - [Research Report: /lean-plan Wave Indicators](../reports/003-lean-plan-wave-indicators.md)
  - [Research Report: Refactoring Strategy & Standards Compliance](../reports/004-refactor-strategy-standards.md)

## Overview

### Problem Statement

The current `/lean-implement` command exhibits a 79.9k token / 2m 51s overhead in the lean-coordinator invocation (report 001, line 5). This overhead is caused by the lean-coordinator performing sequential execution analysis (dependency graph parsing, wave structure calculation) only to conclude "sequential execution is optimal" and defer to lean-implementer. The user has specifically requested that:

1. lean-coordinator should ALWAYS run (no analysis needed to decide whether to use it)
2. Coordinator should rely on plan's dependency indicators for wave structure
3. Sequential execution by default (when no parallel waves indicated in plan)
4. Still create brief summary before completing
5. Ensure /lean-plan indicates waves in a format /lean-implement can consume

### Scope

**In Scope**:
- Remove STEP 2 (Dependency Analysis) from lean-coordinator.md
- Implement plan metadata parsing for wave extraction (dependencies field)
- Default to sequential execution (one phase per wave)
- Add brief summary format (80 tokens vs 2,000 tokens)
- Preserve file-based mode backward compatibility (incremental change pattern)
- Create 35-40 new tests for plan-driven mode
- Maintain all 48 existing tests (100% pass rate)

**Out of Scope**:
- Changes to /lean-plan output format (report 003: current design is architecturally correct)
- Clean-break refactoring (report 004: incremental change required for backward compatibility)
- MCP rate limit budget changes (existing allocation logic preserved)
- File size optimization for lean-coordinator.md (recommended but not required)

### Success Criteria

- [ ] STEP 2 (Dependency Analysis) removed from lean-coordinator workflow
- [ ] Plan metadata parsing extracts `dependencies:` fields correctly
- [ ] Sequential execution works by default (no parallel indicators needed)
- [ ] Brief summary format implemented (≤150 tokens per iteration)
- [ ] File-based mode preserved (no regression in existing workflows)
- [ ] All 48 existing tests pass (100% pass rate)
- [ ] 35-40 new tests created and passing (≥85% coverage)
- [ ] Context reduction achieved (96% reduction: 80 tokens vs 2,000)
- [ ] Documentation updated (lean-coordinator.md, hierarchical-agents-examples.md)

---

## Implementation Phases

### Phase 1: Documentation Preparation [COMPLETE]

**Objective**: Update documentation before code changes to establish contracts and enable validation

**Dependencies**: []

**Tasks**:
- [x] Update lean-coordinator.md: Add backward compatibility notes to STEP 1-2
- [x] Update lean-coordinator.md: Document execution_mode parameter in Input Format section
- [x] Update lean-coordinator.md: Add dual-mode behavior to Output Format section
- [x] Create clean-break-exception comment template for dual-mode support
- [x] Commit documentation updates separately

**Success Criteria**:
- [x] Documentation linter passes (validate-all-standards.sh --links)
- [x] execution_mode parameter documented with clear file-based vs plan-based distinction
- [x] Clean-break exception documented (justification: backward compatibility for /lean-build)
- [x] Changes committed in isolated commit for easy rollback

**Validation**:
```bash
# Run documentation validators
bash .claude/scripts/validate-all-standards.sh --links
bash .claude/scripts/lint/validate-plan-metadata.sh /home/benjamin/.config/.claude/specs/065_lean_coordinator_wave_optimization/plans/001-lean-coordinator-wave-optimization-plan.md

# Verify exit code 0
echo $?
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["validation_output.txt"]

---

### Phase 2: Test Infrastructure Setup [COMPLETE]

**Objective**: Create test scaffolding before implementation to enable TDD workflow

**Dependencies**: [1]

**Tasks**:
- [x] Create test_lean_coordinator_plan_mode.sh with 8 initial tests (stubs)
- [x] Add test_plan_structure_detection (stub, should SKIP)
- [x] Add test_dependency_analysis_invocation (stub, should SKIP)
- [x] Add test_wave_execution_orchestration (stub, should SKIP)
- [x] Add test_phase_number_extraction (stub, should SKIP)
- [x] Add test_progress_tracking_forwarding (stub, should SKIP)
- [x] Add test_file_based_mode_preservation (CRITICAL - verifies no regression)
- [x] Add test_dual_mode_compatibility (stub, should SKIP)
- [x] Add test_blocking_detection_and_revision (stub, should SKIP)
- [x] Run test suite - all tests should SKIP (not implemented yet)
- [x] Commit test scaffolding

**Success Criteria**:
- [x] test_lean_coordinator_plan_mode.sh created in .claude/tests/integration/
- [x] Test suite runs without errors (all SKIP status)
- [x] test_file_based_mode_preservation exists as placeholder for regression check
- [x] Test isolation uses CLAUDE_SPECS_ROOT override pattern
- [x] Cleanup traps implemented for temporary files

**Validation**:
```bash
# Run new test suite
bash .claude/tests/integration/test_lean_coordinator_plan_mode.sh

# Expected: 8/8 SKIP (not implemented)
# Required: 0 errors, all tests in SKIP state
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test_run_output.txt"]

---

### Phase 3: Mode Detection Logic [COMPLETE]

**Objective**: Add execution mode detection without changing core logic (file-based vs plan-based)

**Dependencies**: [2]

**Tasks**:
- [x] Update lean-coordinator.md: Add STEP 0 (Execution Mode Detection) before STEP 1
- [x] Implement execution_mode parameter parsing from input
- [x] Add conditional branch: file-based mode uses original code path
- [x] Add conditional branch: plan-based mode executes STEP 1-2 for dependency analysis
- [x] Update test_file_based_mode_preservation: Verify existing behavior unchanged
- [x] Run all 48 existing tests: Must pass (no regression)
- [x] Commit mode detection logic

**Success Criteria**:
- [x] STEP 0 documented and implemented in lean-coordinator.md
- [x] execution_mode parameter parsed correctly (file-based or plan-based)
- [x] File-based mode bypasses plan parsing (preserves original behavior)
- [x] Plan-based mode proceeds to STEP 1 (plan structure detection)
- [x] test_file_based_mode_preservation passes (1/8 PASS, 7/8 SKIP)
- [x] All 48 existing tests pass (100% pass rate)

**Validation**:
```bash
# Run new test suite
bash .claude/tests/integration/test_lean_coordinator_plan_mode.sh
# Expected: 1/8 PASS (file-based mode), 7/8 SKIP

# Run existing test suites
bash .claude/tests/integration/test_lean_implement_coordinator.sh
# Required: 27/27 PASS (no regression)

bash .claude/tests/integration/test_lean_plan_coordinator.sh
# Required: 21/21 PASS (no regression)
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test_run_output.txt", "regression_test_output.txt"]

---

### Phase 4: Plan Structure Detection Implementation [COMPLETE]

**Objective**: Implement STEP 1 for plan-based mode (detect Level 0 vs Level 1)

**Dependencies**: [3]

**Tasks**:
- [x] Implement plan structure detection: Level 0 (inline) vs Level 1 (phase files)
- [x] Build phase file list based on structure level
- [x] Extract phase numbers from plan/phase files
- [x] Update test_plan_structure_detection: Verify detection logic
- [x] Run test suite: 2/8 PASS expected
- [x] Run all 48 existing tests: Must pass
- [x] Commit plan structure detection

**Success Criteria**:
- [x] Level 0 detection works (inline plan, single file)
- [x] Level 1 detection works (phase files in dedicated directory)
- [x] Phase file list built correctly for both levels
- [x] test_plan_structure_detection passes (2/8 PASS, 6/8 SKIP)
- [x] All 48 existing tests pass (no regression)

**Validation**:
```bash
# Run new test suite
bash .claude/tests/integration/test_lean_coordinator_plan_mode.sh
# Expected: 2/8 PASS, 6/8 SKIP

# Run existing test suites (regression check)
bash .claude/tests/integration/test_lean_implement_coordinator.sh
bash .claude/tests/integration/test_lean_plan_coordinator.sh
# Required: 48/48 PASS total
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test_run_output.txt", "regression_test_output.txt"]

---

### Phase 5: Wave Extraction from Plan Metadata [COMPLETE]

**Objective**: Extract waves from plan's `dependencies:` metadata WITHOUT dependency-analyzer utility

**Dependencies**: [4]

**Tasks**:
- [x] Remove STEP 2 (Dependency Analysis) invocation of dependency-analyzer.sh
- [x] Implement plan metadata parsing for `dependencies:` field per phase
- [x] Build wave groups: Default to sequential (one phase per wave)
- [x] Support parallel wave indicator: `parallel_wave: true` + `wave_id: "identifier"`
- [x] Handle missing metadata gracefully (default to sequential)
- [x] Update test_dependency_analysis_invocation: Verify metadata parsing (rename to test_wave_extraction)
- [x] Run test suite: 3/8 PASS expected
- [x] Run all 48 existing tests: Must pass
- [x] Commit wave extraction logic

**Success Criteria**:
- [x] dependency-analyzer.sh invocation removed from lean-coordinator
- [x] dependencies: [] field parsed correctly (empty array = Wave 1)
- [x] dependencies: [1, 2] field parsed correctly (depends on Phase 1 and 2)
- [x] Sequential waves created by default (one phase per wave)
- [x] Parallel wave detection works when parallel_wave: true + wave_id present
- [x] Missing metadata defaults to sequential (fail-safe)
- [x] test_wave_extraction passes (3/8 PASS, 5/8 SKIP)
- [x] All 48 existing tests pass (no regression)

**Validation**:
```bash
# Run new test suite
bash .claude/tests/integration/test_lean_coordinator_plan_mode.sh
# Expected: 3/8 PASS, 5/8 SKIP

# Run existing test suites (regression check)
bash .claude/tests/integration/test_lean_implement_coordinator.sh
bash .claude/tests/integration/test_lean_plan_coordinator.sh
# Required: 48/48 PASS total
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test_run_output.txt", "regression_test_output.txt"]

---

### Phase 6: Wave Orchestration Execution [COMPLETE]

**Objective**: Implement STEP 4 wave-by-wave execution (highest risk phase)

**Dependencies**: [5]

**Tasks**:
- [x] Implement wave execution loop (iterate over waves sequentially)
- [x] Implement parallel implementer invocation within waves (multiple Task calls)
- [x] Add wave synchronization (hard barrier: wait for all implementers before next wave)
- [x] Preserve MCP rate limit budget allocation logic (3 requests / wave_size)
- [x] Update test_wave_execution_orchestration: Verify wave execution
- [x] Update test_dual_mode_compatibility: Verify no cross-contamination
- [x] Run test suite: 5/8 PASS expected
- [x] Run all 48 existing tests: Must pass
- [x] Commit wave orchestration in isolated branch (critical risk phase)

**Success Criteria**:
- [x] Wave loop executes sequentially (Wave 1 → Wave 2 → Wave 3)
- [x] Parallel invocation works within waves (multiple Task calls in single response)
- [x] Wave synchronization enforced (all implementers complete before next wave)
- [x] MCP rate limit budget distributed correctly (3 requests divided by wave size)
- [x] test_wave_execution_orchestration passes (5/8 PASS, 3/8 SKIP)
- [x] test_dual_mode_compatibility passes
- [x] All 48 existing tests pass (no regression)

**Validation**:
```bash
# Run new test suite
bash .claude/tests/integration/test_lean_coordinator_plan_mode.sh
# Expected: 5/8 PASS, 3/8 SKIP

# Run existing test suites (regression check - CRITICAL)
bash .claude/tests/integration/test_lean_implement_coordinator.sh
bash .claude/tests/integration/test_lean_plan_coordinator.sh
# Required: 48/48 PASS total

# If any failures, rollback Phase 6 commit immediately
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test_run_output.txt", "regression_test_output.txt"]

**Risk Mitigation**:
- Commit wave orchestration in isolated branch
- Run full test suite before merging
- If test failures: rollback to Phase 5, analyze root cause, retry

---

### Phase 7: Brief Summary Format Implementation [COMPLETE]

**Objective**: Implement brief summary format for 96% context reduction (80 tokens vs 2,000)

**Dependencies**: [6]

**Tasks**:
- [x] Implement brief summary generation (≤150 chars, fields on lines 1-8)
- [x] Add metadata fields: coordinator_type, summary_brief, phases_completed, theorem_count
- [x] Add metadata fields: work_remaining, context_exhausted, context_usage_percent, requires_continuation
- [x] Update STEP 5 (Result Aggregation): Create brief summary + full summary file
- [x] Update PROOF_COMPLETE signal: Include summary_brief field (80 tokens)
- [x] Update test suite: Add brief summary parsing validation
- [x] Run test suite: 6/8 PASS expected
- [x] Run all 48 existing tests: Must pass
- [x] Commit brief summary implementation

**Success Criteria**:
- [x] Brief summary generated with all 8 required metadata fields
- [x] summary_brief ≤150 characters (format: "Completed Wave X-Y (Phase A,B) with N theorems. Context: P%. Next: ACTION")
- [x] Full summary file created with metadata fields at top (lines 1-8)
- [x] PROOF_COMPLETE signal includes summary_brief field
- [x] Context reduction achieved (80 tokens vs 2,000 tokens = 96% reduction)
- [x] Test validation passes (6/8 PASS, 2/8 SKIP)
- [x] All 48 existing tests pass (no regression)

**Validation**:
```bash
# Run new test suite
bash .claude/tests/integration/test_lean_coordinator_plan_mode.sh
# Expected: 6/8 PASS, 2/8 SKIP

# Verify context reduction
# Parse summary file: should extract 80 tokens from metadata fields (lines 1-8)
# Full file read: would be ~2,000 tokens (markdown content)
# Reduction: (2000 - 80) / 2000 = 96%

# Run existing test suites (regression check)
bash .claude/tests/integration/test_lean_implement_coordinator.sh
bash .claude/tests/integration/test_lean_plan_coordinator.sh
# Required: 48/48 PASS total
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test_run_output.txt", "regression_test_output.txt", "summary_file_example.md"]

---

### Phase 8: Progress Tracking Integration [COMPLETE]

**Objective**: Add phase_number extraction and progress tracking forwarding to lean-implementer

**Dependencies**: [7]

**Tasks**:
- [x] Extract phase_number from theorem metadata in plan
- [x] Forward progress tracking instructions to lean-implementer invocations
- [x] Handle checkbox-utils unavailability gracefully (non-fatal)
- [x] Update test_phase_number_extraction: Verify extraction logic
- [x] Update test_progress_tracking_forwarding: Verify forwarding
- [x] Run test suite: 8/8 PASS expected (all tests complete)
- [x] Run all 48 existing tests: Must pass
- [x] Commit progress tracking integration

**Success Criteria**:
- [x] phase_number extracted correctly from plan metadata
- [x] Progress tracking instructions forwarded to lean-implementer
- [x] Graceful degradation when checkbox-utils not available (informational output only)
- [x] test_phase_number_extraction passes (8/8 PASS)
- [x] test_progress_tracking_forwarding passes
- [x] All 48 existing tests pass (no regression)

**Validation**:
```bash
# Run new test suite
bash .claude/tests/integration/test_lean_coordinator_plan_mode.sh
# Expected: 8/8 PASS (all tests complete)

# Run existing test suites (regression check)
bash .claude/tests/integration/test_lean_implement_coordinator.sh
bash .claude/tests/integration/test_lean_plan_coordinator.sh
# Required: 48/48 PASS total

# Total test count: 48 existing + 8 new = 56 tests
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test_run_output.txt", "regression_test_output.txt"]

---

### Phase 9: Integration Testing with /lean-implement [COMPLETE]

**Objective**: End-to-end validation with /lean-implement command (both execution modes)

**Dependencies**: [8]

**Tasks**:
- [x] Update /lean-implement command: Add execution_mode detection block
- [x] Add execution_mode parameter to lean-coordinator invocation
- [x] Create test plan with sequential dependencies (file-based mode test)
- [x] Create test plan with parallel wave indicators (plan-based mode test)
- [x] Run /lean-implement in file-based mode: Verify existing behavior
- [x] Run /lean-implement in plan-based mode: Verify wave orchestration
- [x] Verify no production directory pollution (test isolation)
- [x] Run complete test suite: 56+ tests (48 existing + 8 new)
- [x] Measure coverage: ≥85% for new code
- [x] Commit /lean-implement changes

**Success Criteria**:
- [x] execution_mode detection works in /lean-implement command
- [x] File-based mode preserves existing behavior (no regression)
- [x] Plan-based mode uses wave orchestration correctly
- [x] Test isolation prevents production directory pollution
- [x] All 56+ tests pass (100% pass rate)
- [x] Coverage ≥85% for new plan-driven code

**Validation**:
```bash
# Run complete test suite
bash .claude/tests/integration/test_lean_coordinator_plan_mode.sh
bash .claude/tests/integration/test_lean_implement_coordinator.sh
bash .claude/tests/integration/test_lean_plan_coordinator.sh

# Expected: 56+ tests total, 100% pass rate

# Run coverage analysis
bash .claude/scripts/run-coverage.sh .claude/agents/lean-coordinator.md
# Required: ≥85% coverage for new code (plan-driven mode)

# End-to-end test with real /lean-implement invocation
/lean-implement test-plan.md --mode plan-based
# Verify: Wave orchestration, brief summary, no errors
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test_run_output.txt", "coverage_report.txt", "integration_test_output.txt"]

---

### Phase 10: Documentation Finalization [COMPLETE]

**Objective**: Update all documentation with final implementation details

**Dependencies**: [9]

**Tasks**:
- [x] Update hierarchical-agents-examples.md Example 8: Add plan-driven mode subsection
- [x] Update hierarchical-agents-examples.md Example 8: Document execution_mode parameter
- [x] Update hierarchical-agents-examples.md Example 8: Update integration test counts (48 → 56+)
- [x] Update lean-coordinator.md: Finalize STEP 0-5 with implementation details
- [x] Update CHANGELOG.md: Add feature summary for lean-coordinator optimization
- [x] Verify all internal links work (validate-all-standards.sh --links)
- [x] Commit documentation updates

**Success Criteria**:
- [x] hierarchical-agents-examples.md Example 8 updated with plan-driven mode
- [x] execution_mode parameter documented in input contract
- [x] Test counts updated (48 → 56+)
- [x] lean-coordinator.md reflects final implementation
- [x] CHANGELOG.md includes feature summary
- [x] Documentation linter passes (no broken links)

**Validation**:
```bash
# Run documentation validators
bash .claude/scripts/validate-all-standards.sh --links
bash .claude/scripts/lint/validate-readmes.sh

# Verify all validators exit 0
echo $?

# Check link validity
bash .claude/scripts/validate-links-quick.sh .claude/docs/
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["validation_output.txt", "link_check_output.txt"]

---

## Testing Strategy

### Test Coverage Goals

**Baseline Coverage**: ≥60% (project standard)
**Modified Code Coverage**: ≥80% (project standard)
**New Code Coverage**: ≥85% (target for plan-driven mode)

### Test Suites

**Existing Tests** (Must Preserve):
1. test_lean_implement_coordinator.sh: 27 tests (100% pass rate)
2. test_lean_plan_coordinator.sh: 21 tests (100% pass rate)
3. **Total**: 48 tests, 0 failures

**New Tests** (Plan-Driven Mode):
1. test_lean_coordinator_plan_mode.sh: 8 tests
   - test_plan_structure_detection
   - test_wave_extraction (renamed from test_dependency_analysis_invocation)
   - test_wave_execution_orchestration
   - test_phase_number_extraction
   - test_progress_tracking_forwarding
   - test_file_based_mode_preservation (CRITICAL - regression check)
   - test_dual_mode_compatibility
   - test_blocking_detection_and_revision (optional, may defer)

**Test Isolation Pattern**:
```bash
# Use CLAUDE_SPECS_ROOT override
export CLAUDE_SPECS_ROOT="/tmp/lean_coordinator_test_$$"
trap "rm -rf $CLAUDE_SPECS_ROOT" EXIT

# Run tests
bash .claude/tests/integration/test_lean_coordinator_plan_mode.sh
```

### Behavioral Compliance Testing

Following testing-protocols.md Agent Behavioral Compliance section:

1. **File Creation Compliance**: Verify lean-coordinator creates summary at summaries_dir
2. **Completion Signal Format**: Validate PROOF_COMPLETE signal includes all required fields
3. **STEP Structure Validation**: Confirm 5 STEPs present and sequentially numbered (STEP 0-4)
4. **Imperative Language**: Check MUST/WILL/SHALL usage (not should/may/can)
5. **Verification Checkpoints**: Ensure self-validation before PROOF_COMPLETE return

---

## Rollback Strategy

### Per-Phase Rollback

Each phase is isolated in separate git commit for easy rollback:

```bash
# Rollback single phase
git revert <commit-hash>

# Rollback multiple phases
git revert <commit1>..<commitN>
```

### Full Rollback

Revert all 10 phases in reverse order:

```bash
git log --oneline --grep="Phase [0-9]" | tac | awk '{print $1}' | xargs git revert
```

### Emergency Rollback

If critical bug in production:

```bash
git revert $(git log --oneline --since="2025-12-09" --grep="lean-coordinator" --format="%H") --no-commit
git commit -m "EMERGENCY: Revert lean-coordinator plan-driven mode (critical bug)"
```

---

## Risk Assessment

### High-Risk Phases

1. **Phase 6: Wave Orchestration Execution**
   - **Risk**: Complex parallel execution, synchronization barriers
   - **Mitigation**: Extensive testing, isolated commit, full test suite validation
   - **Rollback**: Git revert Phase 6 commit

2. **Phase 5: Wave Extraction**
   - **Risk**: Dependency metadata parsing, wave structure construction
   - **Mitigation**: Defensive parsing, graceful degradation for missing metadata
   - **Rollback**: Git revert Phase 5 commit

### Medium-Risk Phases

1. **Phase 3: Mode Detection Logic**
   - **Risk**: Incorrect mode detection breaks both modes
   - **Mitigation**: Defensive conditionals, explicit error messages, test both modes
   - **Rollback**: Git revert Phase 3 commit

### Low-Risk Phases

1. **Phase 1, 10: Documentation Updates**
   - **Risk**: Minimal - documentation errors don't break code
   - **Mitigation**: Documentation linter validation
   - **Rollback**: Git revert documentation commits

2. **Phase 2: Test Infrastructure**
   - **Risk**: Minimal - tests don't affect production code
   - **Mitigation**: Run test suite before commit
   - **Rollback**: Delete test file

---

## Expected Outcomes

### Performance Metrics

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Startup Overhead | 2-3 tool calls (analysis) | 0 tool calls | Immediate execution |
| Context per Iteration | ~2,000 tokens (full summary) | ~80 tokens (brief) | 96% reduction |
| Iteration Capacity | 3-4 iterations | 10+ iterations | 150-200% increase |
| Wave Detection Time | 5-10 seconds | <1 second | 90% faster |

### Context Efficiency

**Current Flow**:
```
Iteration 1: 2,000 tokens consumed (full summary)
Iteration 2: 2,000 tokens consumed (full summary + continuation)
Iteration 3: 2,000 tokens consumed
Total: 6,000 tokens for 3 iterations
```

**Optimized Flow**:
```
Iteration 1: 80 tokens consumed (brief summary)
Iteration 2: 80 tokens consumed (brief + continuation)
Iteration 3: 80 tokens consumed
...
Iteration 10: 80 tokens consumed
Total: 800 tokens for 10 iterations
```

**Result**: 7.5x more iterations possible in same context budget

---

## Notes

- **User's Specific Request**: lean-coordinator should ALWAYS run (no bypass logic), rely on plan's dependency indicators, default to sequential execution
- **No Changes to /lean-plan**: Current design is architecturally correct (waves inferred from dependencies via topological sort)
- **Incremental Change Pattern**: Backward compatibility required for file-based mode (not clean-break)
- **File Size Risk**: lean-coordinator.md at 1173 lines (~50KB) may exceed 40KB limit - consider applying Standard 14 (Executable/Documentation Separation) in future
