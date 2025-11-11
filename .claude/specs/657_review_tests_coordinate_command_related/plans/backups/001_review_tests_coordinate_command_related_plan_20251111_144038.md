# Implementation Plan: Coordinate Command Test Coverage Improvements

## Metadata
- **Date**: 2025-11-11
- **Feature**: Test Coverage Improvements for /coordinate Command and Related Infrastructure
- **Scope**: Update failing tests, add missing coverage, improve test organization
- **Estimated Phases**: 7
- **Estimated Hours**: 24
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Test Coverage Analysis](../reports/001_coordinate_test_coverage.md)
  - [Testing Best Practices](../reports/002_testing_best_practices.md)
- **Structure Level**: 0
- **Complexity Score**: 82.0

## Overview

This plan addresses test coverage gaps and outdated tests for the /coordinate command and related state machine infrastructure. The test suite currently has ~92% pass rate (115/125+ tests) but requires updates to align with recent architectural changes (state-based orchestration, behavioral injection pattern).

**Primary Goals**:
1. Fix 10 failing tests caused by architectural migrations
2. Add 35-50 new tests for missing coverage areas
3. Improve test organization and isolation
4. Establish performance regression testing

**Based on Research**:
- Report 001 identifies 4 failing test files and 5 major coverage gaps
- Report 002 provides testing patterns for state machines, subprocess isolation, and verification checkpoints
- Current pass rate: 92% → Target: 98%+ with expanded coverage

## Research Summary

Key findings from research reports:

**Test Coverage Analysis (Report 001)**:
- 15 test files, 3,407 lines, ~100+ test cases
- Core strengths: State machine (100%), workflow detection (100%), error handling (100%)
- Failures: Agent delegation pattern (6 tests), wave execution (2 tests), standards compliance (2 tests)
- Missing: State handler tests, integration tests, performance benchmarks

**Testing Best Practices (Report 002)**:
- 86 test files across codebase with 73% assertion coverage
- Subprocess isolation patterns validated through bash block execution model
- Verification checkpoint architecture achieves 100% file creation reliability
- Performance claims (67% improvement) lack automated benchmarking

**Recommended Approach**:
- Priority 1: Fix failing tests (3 hours) - Quick wins
- Priority 2: Add state handler and library integration tests (10-14 hours)
- Priority 3: Long-term enhancements (integration tests, benchmarks) (18-26 hours)

## Success Criteria

- [ ] All 10 failing tests updated to pass (100% pass rate for existing tests)
- [ ] 35-50 new tests added covering state handlers, verification failures, integration
- [ ] Performance regression testing established with baseline measurements
- [ ] Test isolation improved (unique temp directories, cleanup traps)
- [ ] Fixtures directory created with reusable test data
- [ ] Test execution time remains <60 seconds for full suite
- [ ] Coverage measurement integrated (target: ≥80% for modified code)
- [ ] All tests follow standardized assertion patterns (pass/fail/skip functions)

## Technical Design

### Architecture Changes Required

**Test Structure Updates**:
- Update grep patterns from "Phase N" to "State Handler: <name>"
- Update library sourcing checks from `source` to REQUIRED_LIBS array entries
- Update imperative marker checks to accept "EXECUTE NOW" OR "YOU MUST"
- Add state handler test suite (new file: test_coordinate_state_handlers.sh)

**Test Organization Improvements**:
- Create fixtures directory: `.claude/tests/fixtures/coordinate/`
- Implement test isolation with unique temp directories
- Add cleanup traps for test artifacts
- Standardize test counter patterns across all files

**Performance Testing Infrastructure**:
- New benchmark suite: `test_state_persistence_performance.sh`
- Baseline establishment: `.claude/tests/benchmarks/baseline.json`
- Regression detection: Fail if >20% performance degradation

**Integration Test Framework**:
- New suite: `test_coordinate_e2e_integration.sh`
- Full workflow tests (research-only, full-implementation)
- Hierarchical supervisor coordination tests
- Cross-library integration tests

### Component Interactions

```
┌─────────────────────────────────────────────────────────┐
│                  Test Suite Architecture                 │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  Unit Tests              Integration Tests               │
│  ├─ test_state_machine   ├─ test_coordinate_e2e         │
│  ├─ test_state_persist   ├─ test_cross_library          │
│  ├─ test_workflow_detect └─ test_hierarchical_super     │
│  └─ test_coordinate_*                                    │
│                                                           │
│  Performance Tests       Validation Tests                │
│  ├─ test_*_performance   ├─ validate_coordinate         │
│  └─ benchmarks/          └─ validate_state_machine      │
│                                                           │
│  Fixtures                Test Utilities                  │
│  ├─ coordinate/          ├─ assert functions             │
│  ├─ state_files/         ├─ cleanup functions           │
│  └─ workflow_descs/      └─ isolation helpers           │
└─────────────────────────────────────────────────────────┘
```

## Implementation Phases

### Phase 0: Preparation and Analysis
dependencies: []

**Objective**: Analyze current test failures and prepare test environment
**Complexity**: Low
**Expected Duration**: 2 hours

Tasks:
- [ ] Run full test suite and document all failing tests (file: `.claude/tests/test_coordinate_all.sh`)
- [ ] Create test failure report with expected vs actual output
- [ ] Review architectural changes causing test failures (docs: `.claude/docs/architecture/state-based-orchestration-overview.md`)
- [ ] Set up test development environment with debug logging
- [ ] Create backup copies of test files before modification

Testing:
```bash
cd .claude/tests && bash test_coordinate_all.sh > test_output_baseline.txt 2>&1
```

**Phase 0 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(657): complete Phase 0 - Preparation and Analysis`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 1: Fix Failing Agent Delegation Tests
dependencies: [0]

**Objective**: Update test_coordinate_delegation.sh to align with state handler architecture
**Complexity**: Medium
**Expected Duration**: 2 hours

Tasks:
- [ ] Update grep patterns from "Phase 1.*Research" to "State Handler: Research" (file: `.claude/tests/test_coordinate_delegation.sh`, line 87)
- [ ] Update Task invocation checks to look within state handler sections (line 88)
- [ ] Update behavioral file reference checks for all 6 state handlers (lines 90-120)
- [ ] Add tests for completion signal documentation (REPORT_CREATED:, PLAN_CREATED:)
- [ ] Verify all agent delegation tests pass (6 tests total)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
cd .claude/tests && bash test_coordinate_delegation.sh
# Expected: 12/12 tests passing (currently 6/12)
```

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(657): complete Phase 1 - Fix Failing Agent Delegation Tests`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Fix Wave Execution and Standards Tests
dependencies: [0]

**Objective**: Update library sourcing patterns and imperative marker checks
**Complexity**: Low
**Expected Duration**: 1 hour

Tasks:
- [ ] Update test_coordinate_waves.sh: Change from `source.*dependency-analyzer.sh` to REQUIRED_LIBS array check (file: `.claude/tests/test_coordinate_waves.sh`, line 84)
- [ ] Test for conditional sourcing logic in /coordinate.md
- [ ] Update test_coordinate_standards.sh: Accept "EXECUTE NOW" OR "YOU MUST" markers (file: `.claude/tests/test_coordinate_standards.sh`, line 109)
- [ ] Update expected file size range if needed (currently 1,500-3,000 lines)
- [ ] Verify wave execution tests pass (11 tests)
- [ ] Verify standards tests pass (14+ tests)

Testing:
```bash
cd .claude/tests && bash test_coordinate_waves.sh
cd .claude/tests && bash test_coordinate_standards.sh
# Expected: All tests passing
```

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(657): complete Phase 2 - Fix Wave Execution and Standards Tests`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Revise State Persistence Test and Improve Isolation
dependencies: [0]

**Objective**: Fix subprocess isolation test and add test isolation improvements
**Complexity**: Medium
**Expected Duration**: 2 hours

Tasks:
- [ ] Update test_state_persistence.sh Test 14: Document as expected failure or invert to test isolation (file: `.claude/tests/test_state_persistence.sh`, line 147-157)
- [ ] Add comment explaining bash subprocess isolation constraint from Bash Block Execution Model
- [ ] Create test isolation helper functions (file: `.claude/tests/test_helpers.sh`)
- [ ] Implement unique temp directory pattern: `TEST_DIR=$(mktemp -d -t test_$$_XXXXXX)`
- [ ] Add cleanup trap template: `trap "rm -rf $TEST_DIR" EXIT`
- [ ] Update 3 existing test files to use isolation pattern as examples
- [ ] Create isolation pattern documentation (file: `.claude/docs/guides/testing-patterns.md`, append)

Testing:
```bash
cd .claude/tests && bash test_state_persistence.sh
# Expected: 18/18 tests passing (Test 14 inverted or documented)
```

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(657): complete Phase 3 - Revise State Persistence Test and Improve Isolation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Create State Handler Test Suite
dependencies: [1]

**Objective**: Add comprehensive tests for individual state handlers
**Complexity**: High
**Expected Duration**: 5 hours

Tasks:
- [ ] Create new test file: `.claude/tests/test_coordinate_state_handlers.sh`
- [ ] Add test structure with setup, library sourcing, cleanup
- [ ] Test Suite 1: Research state handler (5 tests)
  - [ ] Task tool invocation present
  - [ ] Behavioral file reference (research-specialist.md)
  - [ ] Completion signal documentation
  - [ ] State transition to plan or complete
  - [ ] Error handling for agent failures
- [ ] Test Suite 2: Plan state handler (5 tests)
  - [ ] Task tool invocation for plan-architect.md
  - [ ] Plan path pre-calculation
  - [ ] PLAN_CREATED: completion signal
  - [ ] State transition to implement
  - [ ] Error handling for planning failures
- [ ] Test Suite 3: Implement state handler (6 tests)
  - [ ] Wave-based parallel execution setup
  - [ ] Implementer-coordinator agent reference
  - [ ] Dependency analysis integration
  - [ ] State transition to test
  - [ ] Checkpoint save after implementation
  - [ ] Error handling for implementation failures

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Test Suite 4: Test state handler (4 tests)
  - [ ] Test command execution
  - [ ] Conditional transition (test → debug vs test → document)
  - [ ] Test result parsing
  - [ ] Error handling for test failures
- [ ] Test Suite 5: Debug state handler (3 tests)
  - [ ] Debug-analyst agent reference
  - [ ] State transition to implement (for fixes)
  - [ ] Error handling
- [ ] Test Suite 6: Document state handler (3 tests)
  - [ ] Documentation update process
  - [ ] State transition to complete
  - [ ] Error handling
- [ ] Add test runner integration to test_coordinate_all.sh

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
cd .claude/tests && bash test_coordinate_state_handlers.sh
# Expected: 26 new tests passing
```

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(657): complete Phase 4 - Create State Handler Test Suite`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Add Verification Checkpoint and Library Integration Tests
dependencies: [2]

**Objective**: Test verification checkpoint failures and library integration
**Complexity**: Medium
**Expected Duration**: 4 hours

Tasks:
- [ ] Create new test file: `.claude/tests/test_verification_failures.sh`
- [ ] Add 5 verification failure tests (based on Report 002, lines 215-327):
  - [ ] Partial file write detection
  - [ ] Permission denied scenario
  - [ ] Disk full simulation
  - [ ] State file format corruption
  - [ ] Verification timeout handling
- [ ] Create new test file: `.claude/tests/test_library_integration.sh`
- [ ] Add 3 library integration tests:
  - [ ] workflow-scope-detection.sh integration
  - [ ] unified-logger.sh (emit_progress) integration
  - [ ] verification-helpers.sh (verify_state_variables) integration
- [ ] Create fixtures directory: `.claude/tests/fixtures/coordinate/`
- [ ] Add fixture subdirectories:
  - [ ] workflow_descriptions/ (5 sample workflow descriptions)
  - [ ] state_files/ (3 valid, 2 malformed state files)
  - [ ] sample_outputs/ (agent output examples)
- [ ] Update test files to use fixtures instead of hardcoded data

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
cd .claude/tests && bash test_verification_failures.sh
cd .claude/tests && bash test_library_integration.sh
# Expected: 8 new tests passing
```

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(657): complete Phase 5 - Add Verification Checkpoint and Library Integration Tests`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Create Integration and Performance Test Suites
dependencies: [4, 5]

**Objective**: Add end-to-end integration tests and performance benchmarks
**Complexity**: High
**Expected Duration**: 6 hours

Tasks:
- [ ] Create new test file: `.claude/tests/test_coordinate_e2e_integration.sh`
- [ ] Add 3 end-to-end integration tests (based on Report 002, lines 449-585):
  - [ ] Full coordinate workflow with state transitions
  - [ ] Hierarchical supervisor state coordination
  - [ ] Cross-library integration (state-machine + checkpoint-utils + state-persistence)
- [ ] Create new test file: `.claude/tests/test_state_persistence_performance.sh`
- [ ] Add 3 performance benchmark tests (based on Report 002, lines 335-442):
  - [ ] State operation speed (init, load, append) with baseline comparison
  - [ ] Large state file load test (100+ variables)
  - [ ] Concurrent state access test (10 parallel writes)
- [ ] Establish performance baselines:
  - [ ] Create `.claude/tests/benchmarks/` directory
  - [ ] Run benchmarks on current codebase
  - [ ] Save results to `baseline.json`
  - [ ] Document baseline metrics (init: 2ms, load: 2ms, append: <1ms)
- [ ] Add performance regression detection logic (fail if >20% degradation)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Create new test file: `.claude/tests/test_subprocess_edge_cases.sh`
- [ ] Add 5 subprocess isolation edge case tests (based on Report 002, lines 587-748):
  - [ ] History expansion isolation
  - [ ] Array serialization roundtrip
  - [ ] Nested subprocess trap interaction
  - [ ] Library re-sourcing with modified functions
  - [ ] Working directory isolation
- [ ] Update test_coordinate_all.sh to include new test files
- [ ] Verify full test suite runs in <60 seconds

Testing:
```bash
cd .claude/tests && bash test_coordinate_e2e_integration.sh
cd .claude/tests && bash test_state_persistence_performance.sh
cd .claude/tests && bash test_subprocess_edge_cases.sh
cd .claude/tests && bash test_coordinate_all.sh
# Expected: 11 new tests passing, <60 second runtime
```

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(657): complete Phase 6 - Create Integration and Performance Test Suites`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 7: Documentation and Validation
dependencies: [6]

**Objective**: Document test improvements and validate complete test suite
**Complexity**: Medium
**Expected Duration**: 2 hours

Tasks:
- [ ] Update `.claude/docs/guides/testing-patterns.md`:
  - [ ] Add state handler testing patterns section
  - [ ] Add verification checkpoint failure testing section
  - [ ] Add performance regression testing section
  - [ ] Add test isolation best practices
- [ ] Create validation script: `.claude/tests/validate_coordinate_compliance.sh`
  - [ ] Check architectural standards compliance
  - [ ] Verify all state handlers have tests
  - [ ] Verify test isolation patterns used
  - [ ] Generate compliance report
- [ ] Update CLAUDE.md Testing Protocols section if needed
- [ ] Run full test suite and generate final report:
  - [ ] Total tests: ~150+ (up from ~100+)
  - [ ] Pass rate: 100% (up from 92%)
  - [ ] Coverage areas: Unit, integration, performance, edge cases
  - [ ] Execution time: <60 seconds
- [ ] Create test improvement summary document (file: `.claude/specs/657_review_tests_coordinate_command_related/summaries/001_test_improvements_summary.md`)
- [ ] Document remaining recommended improvements (long-term enhancements from Report 001)

Testing:
```bash
cd .claude/tests && bash validate_coordinate_compliance.sh
cd .claude/tests && bash test_coordinate_all.sh
# Expected: All tests passing, compliance validation successful
```

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(657): complete Phase 7 - Documentation and Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- All new test functions use standardized assertion patterns (pass/fail/skip)
- Each test file has setup/teardown with cleanup traps
- Tests isolated with unique temp directories
- Fixtures used for reusable test data

### Integration Testing
- End-to-end workflow tests cover full state machine lifecycle
- Cross-library integration tests validate component interactions
- Hierarchical supervisor tests validate coordination patterns

### Performance Testing
- Baseline establishment for state persistence operations
- Regression detection with 20% tolerance threshold
- Concurrent access testing validates thread safety
- Large state file testing validates scalability

### Test Organization
```
.claude/tests/
├── test_coordinate_all.sh           # Master test runner
├── test_coordinate_basic.sh         # Structure tests (existing)
├── test_coordinate_delegation.sh    # Agent delegation (updated)
├── test_coordinate_waves.sh         # Wave execution (updated)
├── test_coordinate_standards.sh     # Standards compliance (updated)
├── test_coordinate_state_handlers.sh    # NEW: State handler tests
├── test_verification_failures.sh        # NEW: Verification tests
├── test_library_integration.sh          # NEW: Library integration
├── test_coordinate_e2e_integration.sh   # NEW: E2E integration
├── test_state_persistence_performance.sh # NEW: Performance
├── test_subprocess_edge_cases.sh        # NEW: Edge cases
├── test_helpers.sh                      # NEW: Test utilities
├── validate_coordinate_compliance.sh    # NEW: Validation
├── fixtures/
│   └── coordinate/
│       ├── workflow_descriptions/
│       ├── state_files/
│       └── sample_outputs/
└── benchmarks/
    └── baseline.json
```

### Coverage Goals
- Existing tests: 100% pass rate (fix 10 failing tests)
- New tests: 35-50 tests added
- Total coverage: ≥80% for modified code
- Integration coverage: 3 major workflows
- Performance coverage: 3 benchmark areas

## Documentation Requirements

### Files to Update
1. `.claude/docs/guides/testing-patterns.md` - Add new testing patterns
2. `.claude/docs/guides/coordinate-command-guide.md` - Reference test improvements
3. `CLAUDE.md` - Update Testing Protocols section if needed

### New Documentation
1. Test improvement summary (in summaries/ directory)
2. Validation compliance report (generated by validation script)
3. Performance baseline documentation (in benchmarks/ directory)

### Documentation Standards
- Follow CommonMark specification
- Use Unicode box-drawing for diagrams
- Include code examples with syntax highlighting
- No emojis in documentation
- Timeless writing style (avoid "new" or historical markers)

## Dependencies

### Internal Dependencies
- `.claude/lib/workflow-state-machine.sh` - State machine library
- `.claude/lib/state-persistence.sh` - State persistence library
- `.claude/lib/workflow-detection.sh` - Workflow scope detection
- `.claude/commands/coordinate.md` - /coordinate command implementation

### External Dependencies
- bash 4.0+ (for associative arrays)
- jq (for JSON parsing in tests)
- mktemp (for temporary directories)
- grep with PCRE support (for pattern matching)

### Test Execution Dependencies
- No external network access required
- No containerization required (tests run in local filesystem)
- Temporary files cleaned up via traps

## Risk Mitigation

**Risk 1: Test Updates Break Existing Functionality**
- Mitigation: Create backup copies of all test files before modification
- Mitigation: Run tests incrementally, commit after each phase
- Mitigation: Maintain git history for easy rollback

**Risk 2: Performance Tests Introduce Flakiness**
- Mitigation: Use 20% tolerance for performance regressions (not strict equality)
- Mitigation: Run benchmarks multiple times and average results
- Mitigation: Document baseline environment specifications

**Risk 3: Test Isolation Failures**
- Mitigation: Use unique temp directories with $$ PID in name
- Mitigation: Implement cleanup traps in all test files
- Mitigation: Verify cleanup with post-test filesystem checks

**Risk 4: Subprocess Edge Case Tests Are Environment-Dependent**
- Mitigation: Document bash version requirements (4.0+)
- Mitigation: Use feature detection for bash capabilities
- Mitigation: Skip tests gracefully if environment doesn't support them

## Notes

**Expansion Hint**: This plan has a complexity score of 82.0, which is above the threshold (50) for potential expansion. Consider using `/expand phase <phase-number>` during implementation if any phase becomes too complex or task count exceeds 10.

**Parallel Execution**: Phases 1, 2, 3 have no dependencies on each other (all depend only on Phase 0) and can potentially be executed in parallel for time savings.

**Test Execution Time**: Goal is to keep full test suite under 60 seconds despite adding 35-50 new tests. Focus on efficient test design and parallel test execution where possible.

**Coverage Measurement**: Consider integrating bashcov or kcov for code coverage reporting in future iterations (not included in this plan to maintain scope).
