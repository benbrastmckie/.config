# /coordinate Command Refactoring and Optimization Implementation Plan

## Metadata
- **Date**: 2025-11-13
- **Feature**: Refactor /coordinate command for improved efficiency, robustness, and maintainability
- **Scope**: Performance optimization, error handling enhancements, test coverage expansion, architectural consolidation
- **Estimated Phases**: 7
- **Estimated Hours**: 24
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 156.0
- **Research Reports**:
  - [Architecture and Design](../reports/001_topic1.md)
  - [Implementation Patterns](../reports/002_topic2.md)
  - [Testing and Validation](../reports/003_topic3.md)
  - [Performance Analysis](../reports/004_topic4.md)

## Overview

This refactoring plan addresses performance bottlenecks, architectural inconsistencies, and test coverage gaps identified through comprehensive research of the /coordinate command and its supporting infrastructure. The implementation builds on proven state machine architecture (48.9% code reduction achieved), state persistence patterns (67% performance improvement), and verification checkpoint patterns (100% file creation reliability) to deliver targeted optimizations yielding 200ms initialization overhead reduction, enhanced error diagnostics, and comprehensive failure scenario testing.

Primary objectives:
1. Consolidate bash blocks to eliminate 200ms library re-sourcing overhead
2. Implement consistent state file loading to save 30ms redundant git operations
3. Extend source guards to all libraries for architectural consistency
4. Expand test coverage for failure scenarios and concurrent workflows
5. Enhance error handling diagnostics with performance monitoring
6. Document performance budgets and optimization patterns

## Research Summary

**Architecture and Design** (Report 001):
- 8-state machine architecture with validated transitions achieves 48.9% code reduction
- Subprocess isolation requires fixed semantic filenames and save-before-source patterns
- 12+ mandatory verification checkpoints per workflow ensure 100% file creation reliability
- GitHub Actions-style state persistence with selective file-based caching (7 critical items)
- Two-step workflow capture pattern prevents positional parameter issues

**Implementation Patterns** (Report 002):
- Wave-based parallel execution delivers 40-60% time savings for independent phases
- Three-tier agent architecture (orchestrator → coordinators → workers) with 95.6% context reduction
- Four-step library sourcing order (Standard 15) prevents variable resets and ensures error handling availability
- Phase 0 path pre-calculation achieves 85% token reduction vs agent-based location detection
- Hierarchical supervision threshold at 4+ topics justified by 95.6% context reduction

**Testing and Validation** (Report 003):
- 101 test files with 12+ /coordinate-specific suites achieve 100% file creation reliability
- Verification helpers library provides concise checkpoint pattern (90% token reduction on success)
- Test coverage gaps: failure scenarios, concurrent workflows, performance regression, error message validation
- Integration tests cover state machine transitions, cross-block persistence, wave-based execution
- Current reliability: 100% file creation, 100% bootstrap, >90% agent delegation, zero unbound variables

**Performance Analysis** (Report 004):
- Phase 0 library-based location detection: 85% context reduction (75,600 → 11,000 tokens), 25x speedup
- State persistence caching: 67% improvement (6ms → 2ms CLAUDE_PROJECT_DIR detection)
- LLM classification: 98%+ accuracy, 500ms latency (2% of eliminated 25s baseline)
- Identified optimizations: bash block consolidation (save 200ms), consistent state loading (save 30ms), extended source guards (architectural consistency)
- Test suite: 409 tests across 81 suites, 127 state machine tests at 100% pass rate

## Success Criteria

- [ ] Initialization overhead reduced by 200ms (bash block consolidation)
- [ ] State file loading consistently applied (30ms saved per workflow)
- [ ] Source guards extended to all 5 core libraries
- [ ] Test coverage expanded: failure scenarios (mock agents), concurrent workflows (10+ simultaneous), performance regression (baseline assertions)
- [ ] Error diagnostics enhanced with classification latency monitoring
- [ ] Performance budgets documented in state-based orchestration documentation
- [ ] Zero regression in file creation reliability (maintain 100%)
- [ ] Zero new unbound variable errors introduced
- [ ] All new code follows Standard 15 (library sourcing order) and Standard 0 (verification checkpoints)

## Technical Design

### Architecture

**Bash Block Consolidation Pattern**:
```bash
# Single consolidated bash block replaces 8 separate blocks
set -euo pipefail

# Load all libraries once (50ms, not 8 × 50ms = 400ms)
source_all_required_libraries

# Execute state machine lifecycle via function calls (no subprocess boundaries)
while ! sm_is_terminal; do
  case "$CURRENT_STATE" in
    research) execute_research_phase ;;  # Invokes agents via Task tool
    plan) execute_plan_phase ;;
    implement) execute_implement_phase ;;
    test) execute_test_phase ;;
    debug) execute_debug_phase ;;
    document) execute_document_phase ;;
  esac
done
```

**State Loading Consistency Pattern**:
```bash
# Apply to all blocks after initialization
load_workflow_state "$WORKFLOW_ID"  # Restores CLAUDE_PROJECT_DIR from state
# Skip redundant git rev-parse (saved 6ms)

# Existing pattern to remove:
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
```

**Source Guard Extension Pattern**:
```bash
# Add to library-sourcing.sh and unified-location-detection.sh
if [ -n "${LIBRARY_SOURCING_SOURCED:-}" ]; then
  return 0
fi
export LIBRARY_SOURCING_SOURCED=1
```

### Component Interactions

1. **coordinate.md** → Refactored to single bash block execution model
2. **library-sourcing.sh, unified-location-detection.sh** → Add source guards
3. **workflow-state-machine.sh** → Add classification latency monitoring in sm_init()
4. **Test infrastructure** → New mock agents, enhanced test suites
5. **Documentation** → Performance budgets in state-based-orchestration-overview.md

### Error Handling Strategy

- Maintain fail-fast philosophy: detect configuration errors immediately
- Enhance diagnostics with classification latency warnings (>2000ms alerts)
- Add performance regression detection via baseline assertions in tests
- Validate mock agent error paths with comprehensive troubleshooting output

## Implementation Phases

### Phase 1: Bash Block Consolidation
dependencies: []

**Objective**: Refactor /coordinate to single bash block execution model, eliminating 200ms library re-sourcing overhead

**Complexity**: High

**Tasks**:
- [ ] Analyze current 8-block structure in coordinate.md (lines 18-2118)
- [ ] Design state handler functions: execute_research_phase(), execute_plan_phase(), execute_implement_phase(), execute_test_phase(), execute_debug_phase(), execute_document_phase()
- [ ] Create single consolidated bash block with while loop driving state machine
- [ ] Move verification checkpoints into state handler functions (maintain 12+ checkpoints)
- [ ] Preserve agent invocation patterns via Task tool (no regression to parallelization)
- [ ] Update state persistence calls to use single workflow state file
- [ ] Verify no subprocess isolation issues (all functions in same bash context)
- [ ] Test state transitions work correctly within single block
- [ ] Measure initialization overhead reduction (target: 200ms saved)

**Testing**:
```bash
# Run coordinate-specific test suites
/home/benjamin/.config/.claude/tests/test_coordinate_all.sh

# Verify state machine operations
/home/benjamin/.config/.claude/tests/test_state_machine.sh

# Validate bash block execution model compatibility
/home/benjamin/.config/.claude/tests/test_coordinate_bash_block_fixes_integration.sh

# Performance validation
time /coordinate "test workflow for performance baseline"
```

**Expected Duration**: 6 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(699): complete Phase 1 - Bash Block Consolidation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Consistent State File Loading
dependencies: [1]

**Objective**: Implement consistent load_workflow_state() calls before CLAUDE_PROJECT_DIR detection in all relevant code paths

**Complexity**: Medium

**Tasks**:
- [ ] Audit all git rev-parse calls in coordinate.md (lines 107, 297, 432, 658, 747 from Report 004)
- [ ] Add load_workflow_state() before CLAUDE_PROJECT_DIR detection in consolidated bash block
- [ ] Remove redundant git rev-parse fallback patterns (state file loading should always succeed after init)
- [ ] Update error handling for state file load failures (fail-fast with diagnostic)
- [ ] Verify CLAUDE_PROJECT_DIR restoration from state file in all code paths
- [ ] Add verification checkpoint after state loading (verify_state_variable "CLAUDE_PROJECT_DIR")
- [ ] Test state persistence across workflow execution
- [ ] Measure performance improvement (target: 30ms saved, 5 calls × 6ms)

**Testing**:
```bash
# State persistence validation
/home/benjamin/.config/.claude/tests/test_state_persistence.sh

# Cross-block synchronization (if multi-block paths remain)
/home/benjamin/.config/.claude/tests/test_coordinate_synchronization.sh

# State variable verification
/home/benjamin/.config/.claude/tests/test_coordinate_state_variables.sh
```

**Expected Duration**: 3 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(699): complete Phase 2 - Consistent State File Loading`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Extended Source Guards
dependencies: [1]

**Objective**: Add source guard pattern to library-sourcing.sh and unified-location-detection.sh for architectural consistency

**Complexity**: Low

**Tasks**:
- [ ] Add source guard to library-sourcing.sh (file: /home/benjamin/.config/.claude/lib/library-sourcing.sh)
- [ ] Add source guard to unified-location-detection.sh (file: /home/benjamin/.config/.claude/lib/unified-location-detection.sh)
- [ ] Use pattern from workflow-state-machine.sh:20-24 as template
- [ ] Test libraries source correctly with guards in place
- [ ] Verify idempotent re-sourcing behavior (safe to source multiple times)
- [ ] Update library sourcing documentation in bash-block-execution-model.md

**Testing**:
```bash
# Test library re-sourcing behavior
source /home/benjamin/.config/.claude/lib/library-sourcing.sh
source /home/benjamin/.config/.claude/lib/library-sourcing.sh  # Should be no-op

# Verify guard variables exported
echo "${LIBRARY_SOURCING_SOURCED:-not_set}"
echo "${UNIFIED_LOCATION_DETECTION_SOURCED:-not_set}"
```

**Expected Duration**: 1 hour

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(699): complete Phase 3 - Extended Source Guards`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Enhanced Failure Scenario Testing
dependencies: [1, 2]

**Objective**: Expand test coverage for agent failure modes, error recovery, and edge cases

**Complexity**: High

**Tasks**:
- [ ] Create mock-agent-timeout.md in /home/benjamin/.config/.claude/tests/mocks/ (simulates timeout, no output)
- [ ] Create mock-agent-crash.md in /home/benjamin/.config/.claude/tests/mocks/ (exits with error code)
- [ ] Create mock-agent-incomplete.md in /home/benjamin/.config/.claude/tests/mocks/ (creates file with placeholder content)
- [ ] Create test_coordinate_error_recovery_comprehensive.sh test suite
- [ ] Add test cases: test_agent_timeout_recovery(), test_agent_crash_recovery(), test_agent_incomplete_output()
- [ ] Verify error handling triggers verification checkpoint failures
- [ ] Verify diagnostic output contains expected troubleshooting sections
- [ ] Verify state machine does not transition on agent failure
- [ ] Test concurrent workflow safety (10+ simultaneous /coordinate invocations)
- [ ] Add performance regression baseline tests to test_coordinate_basic.sh

**Testing**:
```bash
# Run comprehensive error recovery tests
/home/benjamin/.config/.claude/tests/test_coordinate_error_recovery_comprehensive.sh

# Run concurrent workflow tests
/home/benjamin/.config/.claude/tests/test_concurrent_workflows.sh

# Validate all coordinate tests pass
/home/benjamin/.config/.claude/tests/test_coordinate_all.sh
```

**Expected Duration**: 5 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(699): complete Phase 4 - Enhanced Failure Scenario Testing`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Classification Performance Monitoring
dependencies: [1, 2]

**Objective**: Add performance monitoring for LLM-based workflow classification with alerting for API degradation

**Complexity**: Medium

**Tasks**:
- [ ] Add classification latency instrumentation to sm_init() in workflow-state-machine.sh (around line 346)
- [ ] Capture CLASSIFY_START and CLASSIFY_END timestamps (nanosecond precision via date +%s%N)
- [ ] Calculate CLASSIFY_MS latency
- [ ] Append classification latency to workflow state: append_workflow_state "CLASSIFY_LATENCY_MS" "$CLASSIFY_MS"
- [ ] Add warning for high latency (>2000ms indicates API issues): emit to stderr
- [ ] Update coordinate.md to display classification performance in verbose mode
- [ ] Test classification monitoring with mock slow API responses
- [ ] Document classification performance expectations in state-based-orchestration-overview.md

**Testing**:
```bash
# Test classification with normal latency
/coordinate "test workflow classification performance"

# Verify latency logged to state file
cat /home/benjamin/.config/.claude/tmp/workflow_*.sh | grep CLASSIFY_LATENCY_MS

# Test warning for high latency (mock API delay)
# Expect: "WARNING: Classification latency high (XXXX ms)" to stderr
```

**Expected Duration**: 2 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(699): complete Phase 5 - Classification Performance Monitoring`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Error Diagnostic Enhancement
dependencies: [4]

**Objective**: Improve error message quality and validate diagnostic output completeness in test suite

**Complexity**: Low

**Tasks**:
- [ ] Add diagnostic output validation to test_verification_helpers.sh
- [ ] Create test_diagnostic_output_completeness() test case
- [ ] Verify error messages contain: "Expected path:", "Directory Analysis:", "TROUBLESHOOTING:", "Command:"
- [ ] Add assert_contains() helper function if not already available
- [ ] Test all verification checkpoint failure paths produce comprehensive diagnostics
- [ ] Update verification-helpers.sh documentation with diagnostic format specification
- [ ] Verify diagnostic output readable by users (not just machine-parseable)

**Testing**:
```bash
# Trigger verification failures and validate diagnostic output
/home/benjamin/.config/.claude/tests/test_verification_helpers.sh

# Validate coordinate error handling produces diagnostics
/home/benjamin/.config/.claude/tests/test_coordinate_error_fixes.sh
```

**Expected Duration**: 2 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(699): complete Phase 6 - Error Diagnostic Enhancement`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 7: Documentation and Performance Budget Formalization
dependencies: [1, 2, 3, 5]

**Objective**: Document performance budgets, optimization patterns, and refactoring outcomes in project documentation

**Complexity**: Low

**Tasks**:
- [ ] Add "Performance Budgets" section to /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md
- [ ] Document initialization overhead budget: target <100ms, measured 50ms (post-consolidation)
- [ ] Document context window budget: target <30% usage, measured 62% (15,600/25,000 tokens)
- [ ] Document classification latency budget: target <1000ms, measured ~500ms LLM mode
- [ ] Update coordinate-command-guide.md with bash block consolidation pattern
- [ ] Document refactoring outcomes: 200ms initialization saved, 30ms state loading saved, architectural consistency achieved
- [ ] Update CLAUDE.md testing protocols with new mock agent testing approach
- [ ] Add performance regression testing guidelines to testing protocols
- [ ] Cross-reference optimization patterns from Report 004 recommendations

**Testing**:
```bash
# Validate documentation links
/home/benjamin/.config/.claude/scripts/validate-links-quick.sh

# Verify CLAUDE.md parses correctly
grep -c "Performance Budgets" /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md
```

**Expected Duration**: 3 hours

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(699): complete Phase 7 - Documentation and Performance Budget Formalization`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 8: Integration Testing and Validation
dependencies: [1, 2, 3, 4, 5, 6, 7]

**Objective**: Comprehensive end-to-end validation of all refactoring changes with zero regression verification

**Complexity**: Medium

**Tasks**:
- [ ] Run full test suite: /home/benjamin/.config/.claude/tests/run_all_tests.sh
- [ ] Verify 100% file creation reliability maintained (no regression)
- [ ] Verify zero unbound variable errors (test_coordinate_state_variables.sh passes)
- [ ] Run end-to-end workflow test: e2e_orchestrate_full_workflow.sh
- [ ] Measure and document final performance metrics (initialization overhead, state loading consistency, classification latency)
- [ ] Validate all 12+ verification checkpoints still present and functional
- [ ] Test concurrent workflow safety (10+ simultaneous invocations)
- [ ] Verify agent delegation patterns unchanged (>90% delegation rate maintained)
- [ ] Create refactoring summary report documenting achievements vs targets
- [ ] Update this implementation plan with "COMPLETED" status

**Testing**:
```bash
# Comprehensive test execution
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh

# Expected: Zero regressions, all coordinate tests pass, performance improvements validated

# Performance validation
time /coordinate "comprehensive end-to-end test workflow"

# Expected: <300ms initialization, 100% file creation reliability, zero errors
```

**Expected Duration**: 2 hours

**Phase 8 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(699): complete Phase 8 - Integration Testing and Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- Test individual library functions: source guards, state loading, classification monitoring
- Mock agent behavior testing: timeout, crash, incomplete output scenarios
- Verification helper diagnostic output validation
- Performance baseline assertions for initialization overhead

### Integration Testing
- State machine lifecycle testing within consolidated bash block
- Cross-component state persistence validation
- Wave-based parallel execution compatibility after bash block consolidation
- End-to-end workflow testing with all refactored components

### Performance Testing
- Initialization overhead measurement (target: 200ms reduction)
- State loading consistency validation (target: 30ms reduction)
- Classification latency monitoring (target: <1000ms, alert >2000ms)
- Concurrent workflow stress testing (10+ simultaneous invocations)

### Regression Testing
- File creation reliability: maintain 100%
- Unbound variable detection: maintain zero errors
- Agent delegation rate: maintain >90%
- Bootstrap reliability: maintain 100% fail-fast behavior

### Test Coverage Goals
- Failure scenarios: 100% (timeout, crash, incomplete output)
- Concurrent workflows: 100% (10+ simultaneous tested)
- Performance regression: 100% (baseline assertions in all coordinate tests)
- Diagnostic output: 100% (expected sections validated)

## Documentation Requirements

### Documentation Updates
- [ ] state-based-orchestration-overview.md: Add "Performance Budgets" section with targets and measurements
- [ ] coordinate-command-guide.md: Document bash block consolidation pattern and migration guidance
- [ ] bash-block-execution-model.md: Update with source guard pattern documentation
- [ ] CLAUDE.md Testing Protocols: Add mock agent testing approach and performance regression guidelines
- [ ] Implementation plan summary: Create refactoring outcomes report

### Documentation Standards
- Follow timeless writing standards (no "new" or "previously" markers)
- Use relative paths for all internal markdown links
- Provide concrete examples with code snippets
- Cross-reference research reports and performance validation data
- Document rationale for architectural decisions

## Dependencies

### External Dependencies
- Claude API (Haiku model for LLM-based classification)
- Git (for CLAUDE_PROJECT_DIR detection via rev-parse)
- jq (for JSON parsing in state persistence and classification)
- Existing test infrastructure (run_all_tests.sh, 101 test files)

### Internal Dependencies
- workflow-state-machine.sh: State enumeration, transitions, classification
- state-persistence.sh: GitHub Actions-style state file management
- verification-helpers.sh: Concise checkpoint pattern (90% token reduction)
- library-sourcing.sh: Four-step sourcing order (Standard 15)
- unified-location-detection.sh: Phase 0 path pre-calculation

### Phase Dependencies
- Phase 2 depends on Phase 1 (bash block consolidation enables consistent state loading)
- Phase 3 independent (can run in parallel with Phase 2)
- Phase 4 depends on Phases 1-2 (mock agents test refactored error handling)
- Phase 5 depends on Phases 1-2 (monitoring integrated into consolidated block)
- Phase 6 depends on Phase 4 (diagnostic validation requires failure test infrastructure)
- Phase 7 depends on Phases 1, 2, 3, 5 (documents all optimization outcomes)
- Phase 8 depends on all phases (comprehensive validation)

**Wave-Based Execution Opportunity**:
- Wave 1: Phase 1 (foundation)
- Wave 2: Phases 2, 3 (both depend on Phase 1, independent of each other - parallel execution possible)
- Wave 3: Phases 4, 5 (both depend on Phases 1-2, independent of each other - parallel execution possible)
- Wave 4: Phase 6 (depends on Phase 4)
- Wave 5: Phase 7 (depends on Phases 1, 2, 3, 5)
- Wave 6: Phase 8 (integration validation)

## Notes

### Complexity Score Calculation
```
Score = Base(refactor=5) + Tasks/2 + Files*3 + Integrations*5
      = 5 + (60/2) + (8*3) + (6*5)
      = 5 + 30 + 24 + 30
      = 89.0

Note: Score <50 suggests Tier 1 (single file), but refactoring complexity
and multi-component integration justify keeping plan consolidated at Level 0
with potential expansion if needed.
```

### Refactoring Philosophy Alignment
This refactoring follows clean-break, fail-fast approach:
- No backward compatibility layers (consolidated bash block replaces all 8 blocks)
- No deprecation warnings (old pattern removed immediately)
- No archives beyond git history (git log documents migration)
- Fail-fast validation ensures immediate error detection (no silent degradation)

### Performance Targets
- Initialization overhead: 300ms → 100ms (200ms reduction via bash block consolidation)
- State loading: 30ms saved (consistent load_workflow_state usage)
- Context usage: Maintain <30% budget (currently 62%, within acceptable range)
- File creation reliability: Maintain 100% (zero regression tolerance)

### Risk Mitigation
- High-risk Phase 1 (bash block consolidation) validated through comprehensive test suite
- Subprocess isolation constraints documented in bash-block-execution-model.md
- Rollback strategy: git revert available for each phase commit
- Performance regression detected via baseline assertions in tests
