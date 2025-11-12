# Comprehensive Testing Plan for Hybrid Workflow Classification System

## Metadata
- **Date**: 2025-11-12
- **Feature**: Hybrid LLM/Regex Workflow Classification Testing
- **Scope**: Complete test coverage for hybrid classification implementation
- **Estimated Phases**: 5
- **Estimated Hours**: 12-16 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 52.0
- **Research Reports**:
  - [Implementation Analysis](/home/benjamin/.config/.claude/specs/671_670_workflow_classification_improvement_plans_001/reports/001_implementation_analysis.md)
  - [Testing Requirements](/home/benjamin/.config/.claude/specs/671_670_workflow_classification_improvement_plans_001/reports/002_testing_requirements.md)

## Overview

This plan implements comprehensive testing for the hybrid LLM/regex workflow classification system. The implementation has achieved 97%+ accuracy with 106/106 automated tests passing, but critical gaps remain in real LLM integration testing, performance benchmarking, and error recovery scenarios. This plan addresses these gaps through automated mocking frameworks, performance regression suites, and failure injection tests.

## Research Summary

Key findings from research reports:
- **Implementation Status** (Report 001): 569 lines of core implementation (3 libraries), 110 tests across 4 suites, 100% automated test pass rate, 97% A/B agreement rate
- **Current Coverage** (Report 002): 37 unit tests, 31 integration tests, 42 A/B tests, but 2 skipped tests require real LLM integration, no performance benchmarks exist, limited error recovery testing
- **Critical Gaps Identified**: Real LLM integration testing (2 skipped unit tests, 3 pending E2E tests), performance benchmarking (no latency/throughput data), edge case expansion (extreme inputs, concurrent requests)

Recommended approach based on research: Create automated LLM mock framework (Phase 1-2), implement performance benchmarking suite (Phase 3), expand edge case coverage (Phase 4), enhance integration testing (Phase 5).

## Success Criteria

- [ ] All skipped tests converted to automated tests (2 unit tests, 3 E2E tests)
- [ ] LLM mock framework operational with 10+ fixture responses
- [ ] Performance benchmarks established (p50/p95/p99 latency measured)
- [ ] Fallback rate monitoring implemented (<20% target)
- [ ] 15+ new edge case tests added and passing
- [ ] Full /coordinate and /supervise integration tests passing
- [ ] Test coverage documentation complete and published
- [ ] Zero test regressions from baseline (106/106 passing)

## Technical Design

### Architecture

The testing architecture uses a three-tier approach:

**Tier 1: Unit Testing Layer**
- Mock-based LLM classifier tests (no real API calls)
- Fixture-driven response validation
- Isolated function behavior verification

**Tier 2: Integration Testing Layer**
- Hybrid mode workflow testing with mocked LLM
- Fallback mechanism validation
- Mode configuration testing (hybrid/llm-only/regex-only)

**Tier 3: End-to-End Testing Layer**
- Real workflow integration (/coordinate, /supervise)
- Performance benchmarking under load
- Manual LLM integration validation

### Component Interactions

```
┌─────────────────────────────────────────────────────────────┐
│ Test Infrastructure                                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────────┐      ┌────────────────────────┐    │
│  │ Mock Framework    │      │ Fixture Library        │    │
│  │ (mock_llm_*.sh)   │──────│ (llm_responses.json)   │    │
│  └───────────────────┘      └────────────────────────┘    │
│           │                            │                    │
│           └────────────┬───────────────┘                    │
│                        │                                    │
│           ┌────────────▼────────────┐                       │
│           │ Test Suites             │                       │
│           │ - Unit Tests (37+)      │                       │
│           │ - Integration Tests (31+) │                     │
│           │ - A/B Tests (42)        │                       │
│           │ - E2E Tests (6)         │                       │
│           │ - Performance Tests (NEW)│                      │
│           └────────────┬────────────┘                       │
│                        │                                    │
│           ┌────────────▼────────────┐                       │
│           │ Test Utilities          │                       │
│           │ - Assertion Library     │                       │
│           │ - Logging/Reporting     │                       │
│           │ - Cleanup Handlers      │                       │
│           └─────────────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

### Test Data Management

**Fixtures Location**: `/home/benjamin/.config/.claude/tests/fixtures/`
```
fixtures/
├── llm_responses/
│   ├── valid_responses.json       (10+ success scenarios)
│   ├── invalid_responses.json     (8+ error scenarios)
│   ├── edge_cases.json            (15+ edge cases)
│   └── confidence_variations.json (boundary tests)
├── workflow_descriptions.txt      (50+ test descriptions)
└── performance_baselines.json     (latency/throughput targets)
```

## Implementation Phases

### Phase 1: Test Infrastructure Setup
dependencies: []

**Objective**: Create automated LLM mock framework and test fixtures
**Complexity**: Medium
**Estimated Duration**: 2-3 hours

Tasks:
- [ ] Create fixtures directory structure (`/home/benjamin/.config/.claude/tests/fixtures/`)
- [ ] Implement valid_responses.json fixture with 10+ scenarios (high confidence, low confidence, edge cases)
- [ ] Implement invalid_responses.json fixture with 8+ error scenarios (missing fields, invalid scope, malformed JSON)
- [ ] Implement edge_cases.json fixture with 15+ edge cases (quoted keywords, negation, multiple actions)
- [ ] Create workflow_descriptions.txt test dataset (50+ descriptions with expected scopes)
- [ ] Implement mock_llm_classifier.sh mock framework (maps descriptions to fixture responses)
- [ ] Add fixture validation script (verify JSON structure, field types, scope values)
- [ ] Update test_llm_classifier.sh to use mock framework for deterministic testing

Testing:
```bash
# Verify fixture structure
/home/benjamin/.config/.claude/tests/fixtures/validate_fixtures.sh

# Test mock framework
source /home/benjamin/.config/.claude/tests/mocks/mock_llm_classifier.sh
result=$(mock_classify_workflow_llm "research auth patterns")
echo "$result" | jq -e '.scope, .confidence, .reasoning'
```

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (fixture validation script passes)
- [ ] Git commit created: `feat(671): complete Phase 1 - Test Infrastructure Setup`
- [ ] Update this plan file with phase completion status

### Phase 2: LLM Integration Testing
dependencies: [1]

**Objective**: Convert skipped tests to automated tests using mock framework
**Complexity**: Medium
**Estimated Duration**: 3-4 hours

Tasks:
- [ ] Update test_llm_classifier.sh Test 7.2 (timeout behavior) to use mock framework
- [ ] Update test_llm_classifier.sh Test 7.3 (invalid LLM response handling) to use mock framework
- [ ] Create test_llm_integration_manual.sh for real LLM validation (6 manual test cases)
- [ ] Document manual LLM testing procedure in test file header
- [ ] Add confidence threshold boundary tests (0.69, 0.7, 0.71) with fixtures
- [ ] Add semantic understanding tests (quoted keywords, negation, multiple actions)
- [ ] Test file-based signaling protocol with mock response file creation/deletion
- [ ] Verify automatic cleanup of temp files after test completion

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Run updated unit tests
/home/benjamin/.config/.claude/tests/test_llm_classifier.sh

# Verify all tests pass (37/37, 0 skipped)
grep -E "^(PASS|SKIP|FAIL)" test_output.txt | sort | uniq -c

# Run manual integration tests
/home/benjamin/.config/.claude/tests/test_llm_integration_manual.sh
```

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (35 → 37 passing, 0 skipped in test_llm_classifier.sh)
- [ ] Git commit created: `feat(671): complete Phase 2 - LLM Integration Testing`
- [ ] Update this plan file with phase completion status

### Phase 3: Performance Benchmarking Suite
dependencies: [1, 2]

**Objective**: Implement comprehensive performance tests for latency, throughput, fallback rate
**Complexity**: High
**Estimated Duration**: 3-4 hours

Tasks:
- [ ] Create bench_workflow_classification.sh script (200+ lines)
- [ ] Implement latency percentile measurement (p50/p95/p99) for 100 samples
- [ ] Implement fallback rate monitoring (track LLM success vs regex fallback)
- [ ] Implement sequential throughput testing (50 classifications)
- [ ] Implement concurrent throughput testing (5 parallel classifications)
- [ ] Create performance_baselines.json with target metrics (p50<300ms, p95<600ms, p99<1000ms)
- [ ] Add performance regression detection (compare current run to baseline)
- [ ] Add resource monitoring (memory RSS, file handle leaks, CPU usage)
- [ ] Document performance testing procedure in bench script header

Testing:
```bash
# Run full performance benchmark suite
/home/benjamin/.config/.claude/tests/bench_workflow_classification.sh --all

# Expected output:
# p50: 250ms (target: <300ms) ✓
# p95: 550ms (target: <600ms) ✓
# p99: 900ms (target: <1000ms) ✓
# Fallback rate: 12% (target: <20%) ✓
# Throughput: 3.5 classifications/sec

# Run performance regression check
/home/benjamin/.config/.claude/tests/bench_workflow_classification.sh --regression
```

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (benchmark script runs successfully, all targets met)
- [ ] Git commit created: `feat(671): complete Phase 3 - Performance Benchmarking Suite`
- [ ] Update this plan file with phase completion status

### Phase 4: Edge Case Coverage Expansion
dependencies: [1, 2]

**Objective**: Add tests for uncovered edge cases and error scenarios
**Complexity**: Medium
**Estimated Duration**: 2-3 hours

Tasks:
- [ ] Add extremely long input test (10,000+ characters) to test_scope_detection.sh
- [ ] Add newlines/control characters test to test_scope_detection.sh
- [ ] Add concurrent request collision test (simulate same-PID race condition)
- [ ] Add temp file cleanup failure test (readonly filesystem simulation)
- [ ] Add case sensitivity test for WORKFLOW_CLASSIFICATION_MODE (HYBRID vs hybrid)
- [ ] Add file-based signaling edge cases (request write fails, response file corrupted)
- [ ] Add LLM response corruption scenarios (partial JSON, truncated response)
- [ ] Add environment variable edge cases (empty vs unset, invalid values)
- [ ] Update test_scope_detection.sh to run new edge case tests
- [ ] Document all edge cases in test file comments

Testing:
```bash
# Run expanded edge case tests
/home/benjamin/.config/.claude/tests/test_scope_detection.sh

# Verify all edge cases pass gracefully (no crashes)
# Expected: 30 → 38 passing tests (8 new edge cases)

# Run edge case isolation
/home/benjamin/.config/.claude/tests/test_scope_detection.sh --edge-cases-only
```

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (30 → 38+ passing in test_scope_detection.sh)
- [ ] Git commit created: `feat(671): complete Phase 4 - Edge Case Coverage Expansion`
- [ ] Update this plan file with phase completion status

### Phase 5: Integration Testing Enhancement
dependencies: [1, 2, 3, 4]

**Objective**: Validate full workflow integration with /coordinate and /supervise
**Complexity**: High
**Estimated Duration**: 2-3 hours

Tasks:
- [ ] Create test_coordinate_hybrid_integration.sh (full /coordinate workflow with hybrid mode)
- [ ] Create test_supervise_hybrid_integration.sh (full /supervise workflow with hybrid mode)
- [ ] Test state machine initialization with hybrid classification (sm_init validation)
- [ ] Test error propagation through workflow stack (empty input, LLM failure)
- [ ] Verify backward compatibility (function signature unchanged for detect_workflow_scope)
- [ ] Test workflow-detection.sh integration (sourcing, function availability)
- [ ] Test mode switching mid-session (change WORKFLOW_CLASSIFICATION_MODE between calls)
- [ ] Document integration test procedures in test file headers

Testing:
```bash
# Run /coordinate integration test
/home/benjamin/.config/.claude/tests/test_coordinate_hybrid_integration.sh

# Run /supervise integration test
/home/benjamin/.config/.claude/tests/test_supervise_hybrid_integration.sh

# Verify both workflows complete successfully
# Expected: 0 errors, valid scope returned, workflow completes

# Run backward compatibility verification
/home/benjamin/.config/.claude/tests/test_scope_detection.sh --backward-compat-only
```

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (both integration tests pass, backward compatibility verified)
- [ ] Git commit created: `feat(671): complete Phase 5 - Integration Testing Enhancement`
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing Approach
- **Scope**: Individual functions (classify_workflow_llm, parse_llm_classifier_response, build_llm_classifier_input)
- **Method**: Mock-based testing with fixture responses
- **Tools**: bash test framework, jq for JSON validation
- **Coverage Target**: 100% of public functions, 90%+ of branches

### Integration Testing Approach
- **Scope**: Multi-function workflows (hybrid mode, fallback mechanism, mode switching)
- **Method**: Mocked LLM responses, real library integration
- **Tools**: test_scope_detection.sh, mock_llm_classifier.sh
- **Coverage Target**: All three modes (hybrid/llm-only/regex-only), all fallback scenarios

### Performance Testing Approach
- **Scope**: Latency, throughput, fallback rate, resource usage
- **Method**: Statistical measurement over 100+ samples
- **Tools**: bench_workflow_classification.sh, time, ps
- **Targets**: p50<300ms, p95<600ms, p99<1000ms, fallback<20%, no memory leaks

### End-to-End Testing Approach
- **Scope**: Full workflow integration (/coordinate, /supervise)
- **Method**: Real command execution with hybrid classification
- **Tools**: test_coordinate_hybrid_integration.sh, test_supervise_hybrid_integration.sh
- **Coverage Target**: All workflow types (research-and-plan, full-implementation, etc.)

### Regression Testing Strategy
- **Baseline**: 106/106 automated tests passing (current state)
- **Detection**: Performance regression detection (latency >20% increase triggers alert)
- **Prevention**: CI/CD integration (run full test suite before merge)
- **Recovery**: Git bisect to identify regression commit

## Documentation Requirements

### Test Documentation
- [ ] Update `.claude/tests/README.md` with new test files and fixtures
- [ ] Create `.claude/tests/README_hybrid_classification_testing.md` (comprehensive guide)
- [ ] Document fixture structure and how to extend datasets
- [ ] Document manual LLM testing procedure
- [ ] Document performance benchmarking interpretation

### Integration Documentation
- [ ] Update CLAUDE.md hierarchical agent architecture section (add testing details)
- [ ] Update library API reference with testing utilities
- [ ] Document test data management patterns
- [ ] Document CI/CD integration recommendations

### Troubleshooting Documentation
- [ ] Add test failure troubleshooting guide
- [ ] Document common edge case scenarios and expected behavior
- [ ] Document performance debugging procedures
- [ ] Add FAQ section for test infrastructure

## Dependencies

### External Dependencies
- bash ≥4.0 (for associative arrays)
- jq (for JSON parsing and fixture validation)
- awk (for statistical calculations in benchmarks)
- bc (for floating-point arithmetic in performance tests)

### Internal Dependencies
- `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh` (implementation under test)
- `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh` (implementation under test)
- `/home/benjamin/.config/.claude/lib/workflow-detection.sh` (integration layer)
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (state management)

### Test Infrastructure Dependencies
- Test assertion library (part of existing test framework)
- Test logging utilities (part of existing test framework)
- Cleanup handlers (trap-based temp file cleanup)

## Risk Mitigation

### Risk: Real LLM Integration Failures
- **Mitigation**: Mock framework enables deterministic testing without API dependency
- **Fallback**: Manual integration test script documents real LLM validation procedure
- **Detection**: Automated tests catch API changes early

### Risk: Performance Regression
- **Mitigation**: Baseline metrics established with automated regression detection
- **Fallback**: Performance trends tracked over time with alerting on >20% degradation
- **Detection**: CI/CD runs benchmarks on every commit

### Risk: Test Data Staleness
- **Mitigation**: Fixture library versioned with clear update procedures
- **Fallback**: A/B test dataset expandable (currently 42 tests, target 100+)
- **Detection**: Periodic review of test descriptions vs real workflow usage

### Risk: Integration Breaking Changes
- **Mitigation**: Backward compatibility tests verify function signatures unchanged
- **Fallback**: Integration tests catch workflow failures before production
- **Detection**: Full test suite (106+ tests) runs before merge

## Rollback Plan

### Test Infrastructure Rollback
If test infrastructure causes issues:
1. Remove fixtures directory (`rm -rf .claude/tests/fixtures`)
2. Revert mock framework (`git restore .claude/tests/mocks/`)
3. Restore original test files with skipped tests
4. Document rollback reason for future reference

### Performance Testing Rollback
If performance tests cause issues:
1. Remove bench_workflow_classification.sh
2. Remove performance_baselines.json
3. Restore original test suite without performance tests
4. Document performance testing issues

### Full Rollback
If testing plan cannot be completed:
1. Restore baseline test suite (106 tests, 2 skipped)
2. Keep existing test coverage (100% automated test pass rate)
3. Document blocking issues for future resolution
4. Schedule retrospective to identify root causes

## Success Metrics

- **Test Coverage**: 106 → 124+ tests (18+ new tests added)
- **Pass Rate**: 100% automated test pass rate maintained (0 regressions)
- **Skipped Tests**: 2 → 0 skipped tests (all converted to automated)
- **Performance Baselines**: p50/p95/p99 latency measured and documented
- **Fallback Rate**: <20% fallback rate measured and monitored
- **Integration Coverage**: /coordinate and /supervise integration tests passing
- **Documentation Completeness**: All test procedures documented

## Appendix: Test Case Priorities

### P0 (Critical - Must Pass)
- All existing 106 automated tests (maintain 100% pass rate)
- LLM timeout fallback (automatic, transparent, zero operational risk)
- Backward compatibility (detect_workflow_scope signature unchanged)
- Integration with /coordinate and /supervise (workflows complete successfully)

### P1 (High - Should Pass)
- Confidence threshold boundary tests (0.69, 0.7, 0.71)
- Performance targets (p50<300ms, p95<600ms, p99<1000ms)
- Fallback rate monitoring (<20% target)
- Edge case coverage (quoted keywords, negation, multiple actions)

### P2 (Medium - Nice to Have)
- Extremely long input handling (10,000+ characters)
- Concurrent request handling (5 parallel classifications)
- Resource monitoring (memory leaks, file handle leaks)
- Case sensitivity for mode configuration

### P3 (Low - Optional)
- Continuous monitoring infrastructure (optional Phase 6)
- Advanced performance profiling (CPU usage, bash execution time)
- Extended A/B test dataset (42 → 100+ test cases)
- User-facing troubleshooting documentation

## References

### Implementation Files
- `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh` (297 lines) - LLM classifier implementation
- `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh` (198 lines) - Unified hybrid classifier
- `/home/benjamin/.config/.claude/lib/workflow-detection.sh` (74 lines) - /supervise integration

### Existing Test Suites
- `/home/benjamin/.config/.claude/tests/test_llm_classifier.sh` (442 lines, 37 tests, 94.6% pass rate)
- `/home/benjamin/.config/.claude/tests/test_scope_detection.sh` (560 lines, 31 tests, 96.8% pass rate)
- `/home/benjamin/.config/.claude/tests/test_scope_detection_ab.sh` (305 lines, 42 tests, 97.6% agreement)
- `/home/benjamin/.config/.claude/tests/manual_e2e_hybrid_classification.sh` (196 lines, 6 E2E tests)

### Research Reports
- [Implementation Analysis](/home/benjamin/.config/.claude/specs/671_670_workflow_classification_improvement_plans_001/reports/001_implementation_analysis.md) - Current implementation status
- [Testing Requirements](/home/benjamin/.config/.claude/specs/671_670_workflow_classification_improvement_plans_001/reports/002_testing_requirements.md) - Testing gaps and recommendations

### Project Standards
- `/home/benjamin/.config/CLAUDE.md` - Testing protocols, code standards, development philosophy
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` - Standards 0, 13, 14
