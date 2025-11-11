# Implementation Plan: Hybrid Workflow Classification System

**Plan ID**: 670-001
**Created**: 2025-11-11
**Status**: Ready for Review
**Complexity**: 7.5/10
**Estimated Time**: 3-4 weeks (development) + 4-6 weeks (rollout)

**Related Documents**:
- Current Analysis: `../../workflow_scope_detection_analysis.md`
- LLM Research: `../reports/001_llm_based_classification_research.md`
- Comparative Analysis: `../reports/002_comparative_analysis_and_synthesis.md`
- Architecture: `../reports/003_implementation_architecture.md`

---

## Executive Summary

**Problem**: Current regex-based workflow classification has 8% false positive rate on edge cases. Example: "research the research-and-revise workflow" incorrectly classified as `research-and-revise` instead of `research-and-plan`.

**Solution**: Hybrid classification system using Claude Haiku 4.5 for semantic understanding with automatic regex fallback.

**Benefits**:
- 98%+ accuracy (vs 92% current)
- Zero operational risk (regex fallback)
- Negligible cost ($0.03/month)
- 100% backward compatible

**Approach**: 5-phase implementation with progressive rollout (alpha → beta → gamma → production).

---

## Table of Contents

1. [Problem Analysis](#problem-analysis)
2. [Solution Overview](#solution-overview)
3. [Implementation Phases](#implementation-phases)
4. [Phase Dependencies](#phase-dependencies)
5. [Testing Strategy](#testing-strategy)
6. [Risk Mitigation](#risk-mitigation)
7. [Success Criteria](#success-criteria)
8. [Rollback Plan](#rollback-plan)

---

## Problem Analysis

### Current Failure Mode

**File**: `.claude/lib/workflow-scope-detection.sh:54`

**Pattern**:
```bash
elif echo "$workflow_description" | grep -Eiq "(research|analyze).*(and |then |to ).*(revise|update.*plan|modify.*plan)"; then
  scope="research-and-revise"
```

**Issue**: Pattern matches when discussing workflow types (false positive), not just requesting them.

**Example**:
```
Input: "research the research-and-revise workflow to understand misclassification"
Regex: research-and-revise ❌ (FALSE POSITIVE)
Expected: research-and-plan ✓ (user wants to research and create plan)
```

### Impact

- **User Confusion**: Wrong workflow scope leads to error messages about missing plan paths
- **Workflow Failure**: `/coordinate` expects different inputs based on scope
- **Maintenance Burden**: Adding more regex patterns increases complexity and fragility

### Root Cause

Regex cannot distinguish between:
1. **Requesting** a workflow type: "research X and revise plan Y"
2. **Discussing** a workflow type: "research why it detected research-and-revise"

Solution requires semantic understanding (LLM) instead of pattern matching.

---

## Solution Overview

### Architecture

```
User Input → detect_workflow_scope_v2()
                │
                ├─→ [hybrid mode] LLM Classifier (Haiku 4.5)
                │       │
                │       ├─→ [confidence >= 0.7] Return LLM result
                │       └─→ [confidence < 0.7] Fallback to regex
                │
                ├─→ [llm-only mode] LLM Classifier (no fallback)
                │
                └─→ [regex-only mode] Regex Classifier (current)
```

### Integration with Existing Infrastructure

**Dual Library Architecture** (per infrastructure analysis):
- `workflow-scope-detection.sh` (101 lines): Used by /coordinate (state machine architecture)
- `workflow-detection.sh` (206 lines): Used by /supervise (phase-based architecture)
- Both libraries will receive v2 wrapper functions for consistent hybrid classification

**State Machine Integration** (per .claude/lib/workflow-state-machine.sh):
- `sm_init()` function (lines 89-142) sources detection library and calls detect_workflow_scope()
- Maps scope to terminal states: research-only → STATE_RESEARCH, research-and-plan → STATE_PLAN, etc.
- Hybrid classifier must maintain this integration pattern

**Standards Compliance**:
- Standard 13 (Project Directory Detection): Use CLAUDE_PROJECT_DIR for all paths
- Standard 14 (Executable/Documentation Separation): Separate implementation from comprehensive guide

### Key Components

1. **New Library**: `.claude/lib/workflow-llm-classifier.sh` (~200 lines)
   - `classify_workflow_llm()` - Invoke Haiku via Task tool
   - `parse_llm_classifier_response()` - Validate JSON output
   - `build_llm_classifier_input()` - Build classification prompt

2. **Modified Library**: `.claude/lib/workflow-scope-detection.sh` (+50 lines)
   - `detect_workflow_scope_v2()` - Hybrid entry point (NEW)
   - `detect_workflow_scope()` - Regex-only (UNCHANGED)

3. **Modified Library**: `.claude/lib/workflow-state-machine.sh` (+5 lines)
   - `sm_init()` - Call v2 instead of v1 (maintain scope-to-state mapping pattern)

4. **Test Suite**: `.claude/tests/` (+250 lines across 2 new + 1 modified file)
   - `test_llm_classifier.sh` - Unit tests
   - `test_scope_detection_ab.sh` - A/B testing
   - `test_scope_detection.sh` - Integration tests (modified)

### Configuration

**Environment Variables**:
- `WORKFLOW_CLASSIFICATION_MODE`: `hybrid` (default), `llm-only`, `regex-only`
- `WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD`: `0.7` (default)
- `WORKFLOW_CLASSIFICATION_TIMEOUT`: `10` (seconds, default)
- `WORKFLOW_CLASSIFICATION_DEBUG`: `0` (default), `1` (verbose logging)

---

## Implementation Phases

### Phase 0: Pre-Implementation (Research Complete ✓)

**Status**: COMPLETE
**Duration**: 2 days (already done)

**Artifacts Created**:
- ✓ Current implementation analysis
- ✓ LLM-based classification research
- ✓ Comparative analysis and synthesis
- ✓ Implementation architecture document

**Tasks**: None remaining

---

### Phase 1: Core LLM Classifier Library

**Duration**: 3-4 days
**Complexity**: 6/10
**Dependencies**: None

**Objective**: Create standalone LLM classifier library with comprehensive tests.

#### Tasks

<parameter name="content">**1.1 Create workflow-llm-classifier.sh** [~200 lines]

Create `.claude/lib/workflow-llm-classifier.sh` with functions:
- `classify_workflow_llm()` - Main entry point
- `build_llm_classifier_input()` - Build JSON payload
- `invoke_llm_classifier()` - Call AI assistant via file-based signaling
- `parse_llm_classifier_response()` - Validate JSON response
- `log_classification_result()` - Structured logging

**Files**:
- CREATE `.claude/lib/workflow-llm-classifier.sh`

**Reference**: Architecture Section 2.1

**Standards Compliance**:
- Use Standard 13 (Project Directory Detection) pattern for CLAUDE_PROJECT_DIR
- Follow Standard 14 (Executable/Documentation Separation) with separate guide file
- Apply bash-block-execution-model.md patterns for subprocess isolation

**Acceptance Criteria**:
- [ ] All functions implemented with full error handling
- [ ] Input validation for all functions
- [ ] Confidence threshold checking
- [ ] Structured logging integration
- [ ] Debug logging support
- [ ] JSDoc-style comments for all functions
- [ ] CLAUDE_PROJECT_DIR detection following Standard 13 pattern

---

**1.2 Create Unit Test Suite** [~150 lines]

Create `.claude/tests/test_llm_classifier.sh` with tests for:
- Input validation (empty, long, special characters)
- JSON building and escaping
- Response parsing (valid, invalid, malformed)
- Confidence threshold logic
- Timeout behavior (mocked)
- Error handling paths

**Files**:
- CREATE `.claude/tests/test_llm_classifier.sh`

**Reference**: Architecture Section 8.1

**Acceptance Criteria**:
- [ ] 30+ unit tests covering all functions
- [ ] Mock LLM responses for testing
- [ ] 90%+ code coverage of workflow-llm-classifier.sh
- [ ] All tests pass
- [ ] Test isolation (no real API calls)

---

**1.3 Implement AI Assistant Integration** [~50 lines]

Implement file-based signaling for AI assistant to process classification requests:
- Write request JSON to `/tmp/llm_classification_request_$$.json`
- Signal to AI assistant via stderr message
- Wait for response at `/tmp/llm_classification_response_$$.json`
- Timeout after 10 seconds

**Files**:
- MODIFY `.claude/lib/workflow-llm-classifier.sh` (function: `invoke_llm_classifier()`)

**Reference**: Architecture Section 3.1 Option A

**Acceptance Criteria**:
- [ ] Request/response file protocol documented
- [ ] Timeout mechanism working
- [ ] Cleanup of temp files on success/failure
- [ ] Unique file naming (PID-based) prevents collisions
- [ ] Integration test with AI assistant response

---

**1.4 Validate Library in Isolation** [manual testing]

Test library functions independently before integration:
```bash
# Test 1: Basic classification
source .claude/lib/workflow-llm-classifier.sh
result=$(classify_workflow_llm "research auth patterns and create plan")
echo "$result" | jq .

# Test 2: Timeout behavior
WORKFLOW_CLASSIFICATION_TIMEOUT=1 \
  result=$(classify_workflow_llm "test description")

# Test 3: Confidence threshold
WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD=0.9 \
  result=$(classify_workflow_llm "ambiguous description")
```

**Acceptance Criteria**:
- [ ] Successful classification returns valid JSON
- [ ] Low confidence triggers fallback (return code 1)
- [ ] Timeout triggers fallback
- [ ] Malformed responses handled gracefully
- [ ] Debug logging shows all decision points

---

### Phase 2: Hybrid Classifier Integration

**Duration**: 2-3 days
**Complexity**: 5/10
**Dependencies**: Phase 1 complete

**Objective**: Integrate LLM classifier with existing regex classifier to create hybrid system.

#### Tasks

**2.1 Create detect_workflow_scope_v2()** [~80 lines]

Add `detect_workflow_scope_v2()` function to `.claude/lib/workflow-scope-detection.sh`:
- Check `WORKFLOW_CLASSIFICATION_MODE` environment variable
- Route to LLM, regex, or hybrid based on mode
- Handle fallback from LLM to regex in hybrid mode
- Support JSON and string output formats (backward compat)
- Log classification method and confidence

**Files**:
- MODIFY `.claude/lib/workflow-scope-detection.sh`
- MODIFY `.claude/lib/workflow-detection.sh` (add v2 wrapper for /supervise compatibility)

**Reference**: Architecture Section 2.2.1, Infrastructure Report Section 1 (Dual Library Architecture)

**Integration Pattern**:
- Both workflow-scope-detection.sh and workflow-detection.sh receive v2 wrapper functions
- Shared LLM logic in workflow-llm-classifier.sh enables code reuse
- Maintains existing state machine integration pattern (sm_init → detect_workflow_scope → scope-to-state mapping)

**Acceptance Criteria**:
- [ ] Hybrid mode invokes LLM first, falls back to regex
- [ ] LLM-only mode fails fast on LLM error
- [ ] Regex-only mode bypasses LLM entirely
- [ ] String output format for backward compatibility
- [ ] JSON output format includes confidence and method
- [ ] Source LLM classifier library on init
- [ ] v2 wrapper added to BOTH detection libraries

---

**2.2 Update sm_init() to Use v2** [~5 lines]

Modify `.claude/lib/workflow-state-machine.sh:sm_init()` to call `detect_workflow_scope_v2()` instead of v1:
```bash
# OLD:
WORKFLOW_SCOPE=$(detect_workflow_scope "$workflow_description")

# NEW:
if command -v detect_workflow_scope_v2 &>/dev/null; then
  WORKFLOW_SCOPE=$(detect_workflow_scope_v2 "$workflow_description")
else
  WORKFLOW_SCOPE=$(detect_workflow_scope "$workflow_description")
fi
```

**Files**:
- MODIFY `.claude/lib/workflow-state-machine.sh` (function: `sm_init()`)

**Acceptance Criteria**:
- [ ] v2 used when available
- [ ] Graceful fallback to v1 if v2 not available
- [ ] No breaking changes to sm_init() interface
- [ ] Existing callers unaffected

---

**2.3 Create Integration Test Suite** [~100 lines]

Add integration tests to `.claude/tests/test_scope_detection.sh`:
- Environment variable behavior (hybrid/llm-only/regex-only modes)
- Fallback scenarios (timeout, low confidence, API error)
- Backward compatibility (v1 still works)
- Output format switching (string vs JSON)
- /coordinate integration (sm_init uses v2)

**Files**:
- MODIFY `.claude/tests/test_scope_detection.sh`

**Reference**: Architecture Section 8.2

**Acceptance Criteria**:
- [ ] 20+ integration tests added
- [ ] All modes tested (hybrid, llm-only, regex-only)
- [ ] Fallback scenarios verified
- [ ] Backward compatibility confirmed (v1 tests still pass)
- [ ] Mock LLM responses for deterministic testing

---

**2.4 End-to-End Integration Test** [manual testing]

Test complete /coordinate workflow with hybrid classifier:
```bash
# Test 1: Problematic case (from issue)
WORKFLOW_CLASSIFICATION_DEBUG=1 \
  /coordinate "research the research-and-revise workflow misclassification issue"
# Expected: Scope = research-and-plan (not research-and-revise)

# Test 2: Normal case
/coordinate "research authentication patterns and create implementation plan"
# Expected: Scope = research-and-plan

# Test 3: Revise case
/coordinate "Revise the plan at specs/042_auth/plans/001_plan.md based on new requirements"
# Expected: Scope = research-and-revise

# Test 4: Fallback case (force timeout)
WORKFLOW_CLASSIFICATION_TIMEOUT=0 \
  /coordinate "research auth patterns"
# Expected: Scope = research-and-plan, method = regex-fallback
```

**Acceptance Criteria**:
- [ ] All test cases produce correct scope
- [ ] Problematic case fixed (no longer misclassified)
- [ ] Debug logs show classification method used
- [ ] Fallback transparent to user
- [ ] Workflow completes successfully in all cases

---

### Phase 3: Testing and Quality Assurance

**Duration**: 3-4 days
**Complexity**: 6/10
**Dependencies**: Phase 2 complete

**Objective**: Comprehensive testing with A/B comparison and edge case validation.

#### Tasks

**3.1 Create A/B Testing Framework** [~100 lines]

Create `.claude/tests/test_scope_detection_ab.sh`:
- Run both LLM and regex classifiers on same test dataset
- Identify disagreements
- Generate human review report
- Track agreement rate over time

**Files**:
- CREATE `.claude/tests/test_scope_detection_ab.sh`

**Reference**: Architecture Section 8.3

**Acceptance Criteria**:
- [ ] 40+ test cases covering:
  - Straightforward cases (both should agree)
  - Edge cases (LLM should be more accurate)
  - Ambiguous cases (document disagreements)
- [ ] Disagreement report generation
- [ ] Human review workflow documented
- [ ] Agreement rate calculation (target: 95%+)

---

**3.2 Run A/B Testing Campaign** [manual testing]

Execute A/B tests with real-world workflow descriptions:
- Collect 50+ workflow descriptions from recent /coordinate usage
- Run A/B test framework
- Review disagreements manually
- Document correct classifications
- Update test dataset with reviewed cases

**Acceptance Criteria**:
- [ ] 50+ real descriptions tested
- [ ] Agreement rate measured and documented
- [ ] All disagreements reviewed by human
- [ ] Test dataset updated with human-validated correct classifications
- [ ] Edge cases where LLM outperforms regex documented

---

**3.3 Edge Case Testing** [~50 lines + manual]

Create comprehensive edge case test suite:
- Quoted keywords: "research the 'implement' command"
- Negation: "don't revise the plan, create a new one"
- Multiple actions: "research X, plan Y, and implement Z"
- Ambiguous intent: "look into the coordinate output"
- Long descriptions: 500+ word descriptions
- Special characters: Unicode, emojis, markdown

**Files**:
- MODIFY `.claude/tests/test_scope_detection.sh` (add edge case section)

**Acceptance Criteria**:
- [ ] 15+ edge case tests
- [ ] LLM handles all edge cases correctly
- [ ] Regex fallback behavior documented for each case
- [ ] No crashes or errors on malformed input

---

**3.4 Performance Benchmarking** [~30 lines]

Create performance benchmark script:
- Measure p50/p95/p99 latency for LLM classifier
- Measure fallback rate over time
- Track API cost per classification
- Compare latency vs regex (baseline)

**Files**:
- CREATE `.claude/tests/bench_workflow_classification.sh`

**Acceptance Criteria**:
- [ ] Latency benchmark script created
- [ ] p50 < 300ms, p95 < 600ms, p99 < 1000ms
- [ ] Fallback rate < 20% in testing
- [ ] Cost per classification: ~$0.00003
- [ ] Performance acceptable for command startup phase

---

**3.5 Regression Testing** [automated]

Run full existing test suite to ensure no regressions:
```bash
./run_all_tests.sh
```

**Baseline Test Results** (from infrastructure analysis):
- Current passing: 56/58 tests (96.6% pass rate)
- Test files: test_workflow_scope_detection.sh and test_workflow_detection.sh
- Known limitations: 10+ edge cases not covered

**Acceptance Criteria**:
- [ ] All existing tests pass (56/58 baseline maintained or improved)
- [ ] No breaking changes to existing functionality
- [ ] Backward compatibility verified (all 56 passing tests still pass)
- [ ] Zero regressions in /coordinate workflow
- [ ] Edge cases from infrastructure analysis added to test suite

---

### Phase 4: Alpha Rollout (Developer Testing)

**Duration**: 1-2 weeks
**Complexity**: 4/10
**Dependencies**: Phase 3 complete

**Objective**: Deploy to developer machines for real-world validation.

#### Tasks

**4.1 Developer Documentation** [~200 lines]

Create comprehensive developer guide:
- How hybrid classifier works
- Environment variable configuration
- Debugging classification issues
- Troubleshooting common problems
- How to opt-in to alpha testing

**Files**:
- CREATE `.claude/docs/guides/hybrid-classification-alpha.md`

**Acceptance Criteria**:
- [ ] Architecture diagram included
- [ ] Configuration examples provided
- [ ] Debugging workflow documented
- [ ] Troubleshooting section complete
- [ ] Opt-in instructions clear

---

**4.2 Alpha Deployment** [configuration]

Deploy hybrid classifier to developer machines:
- Enable via environment variable: `WORKFLOW_CLASSIFICATION_MODE=hybrid`
- Enable debug logging by default: `WORKFLOW_CLASSIFICATION_DEBUG=1`
- Set up monitoring dashboard (if available)

**Acceptance Criteria**:
- [ ] Developers can opt-in easily (add to shell profile)
- [ ] Debug logs visible for troubleshooting
- [ ] No production traffic affected
- [ ] Rollback instructions documented

---

**4.3 Developer Feedback Collection** [2 weeks]

Collect feedback from alpha testers:
- Survey: classification accuracy, latency, ease of use
- Bug reports: any crashes, errors, or unexpected behavior
- Feature requests: missing functionality or improvements
- Disagreement review: manual review of classification results

**Acceptance Criteria**:
- [ ] 10+ alpha testers recruited
- [ ] 50+ real classifications collected
- [ ] Survey responses collected (target: 80% satisfaction)
- [ ] Zero critical bugs reported
- [ ] Fallback rate < 30% (if higher, investigate)

---

**4.4 Alpha Review and Adjustments** [2-3 days]

Review alpha results and make adjustments:
- Analyze collected metrics (latency, fallback rate, accuracy)
- Fix any bugs discovered during alpha
- Adjust confidence threshold if needed (currently 0.7)
- Update prompt engineering if accuracy issues found

**Acceptance Criteria**:
- [ ] All critical bugs fixed
- [ ] High priority bugs fixed or documented
- [ ] Confidence threshold tuned (if needed)
- [ ] Prompt engineering validated
- [ ] Go/no-go decision for beta rollout

---

### Phase 5: Production Rollout and Monitoring

**Duration**: 4-6 weeks (gradual rollout)
**Complexity**: 5/10
**Dependencies**: Phase 4 complete + go decision

**Objective**: Gradual production rollout with continuous monitoring.

#### Tasks

**5.1 Beta Rollout (Internal Testing)** [2 weeks]

Deploy to internal testing environment:
- Opt-in for early adopters
- A/B testing enabled (log disagreements)
- Monitoring dashboard active

**Acceptance Criteria**:
- [ ] 5+ early adopters recruited
- [ ] 100+ classifications collected
- [ ] Agreement rate > 90%
- [ ] Fallback rate < 25%
- [ ] p95 latency < 700ms
- [ ] Positive feedback from early adopters

---

**5.2 Gamma Rollout (Subset of Production)** [2 weeks]

Enable for 25% of /coordinate invocations:
- Sampling-based rollout (random 25%)
- Full monitoring and alerting active
- Weekly disagreement review meetings

**Acceptance Criteria**:
- [ ] 200+ production classifications collected
- [ ] Agreement rate > 92%
- [ ] Fallback rate < 20%
- [ ] p95 latency < 600ms
- [ ] Error rate < 1%
- [ ] Human review confirms LLM correct >95% of time

---

**5.3 Full Production Rollout** [ongoing]

Change default to hybrid mode:
- Update library default: `WORKFLOW_CLASSIFICATION_MODE=hybrid`
- Users can opt-out with `WORKFLOW_CLASSIFICATION_MODE=regex-only`
- Continuous monitoring
- Monthly quality review

**Acceptance Criteria**:
- [ ] Smooth transition with zero complaints
- [ ] Fallback rate stable < 15%
- [ ] Agreement rate > 95%
- [ ] p95 latency < 500ms
- [ ] Error rate < 0.5%
- [ ] Monthly review process established

---

**5.4 Documentation Finalization** [~500 lines total]

Update all relevant documentation:
- `/coordinate` command guide
- Library API reference
- CLAUDE.md (main config)
- Testing documentation
- Troubleshooting guide
- Pattern documentation (new file)

**Files**:
- MODIFY `.claude/docs/guides/coordinate-command-guide.md`
- MODIFY `.claude/docs/reference/library-api.md`
- MODIFY `CLAUDE.md`
- MODIFY `.claude/tests/README.md`
- MODIFY `.claude/docs/guides/orchestration-troubleshooting.md`
- CREATE `.claude/docs/concepts/patterns/llm-classification-pattern.md`

**Reference**: Architecture Section 11, Standards Report Section on Architectural Patterns Catalog

**Standards Compliance**:
- Follow Standard 14 (Executable/Documentation Separation) pattern
- Ensure single source of truth principle (Diataxis framework)
- Add to Architectural Patterns catalog with performance metrics
- Follow timeless writing standards (no historical markers)

**Acceptance Criteria**:
- [ ] All documentation updated and accurate
- [ ] Examples tested and working
- [ ] Troubleshooting guide complete
- [ ] Pattern documentation comprehensive (following pattern template)
- [ ] No outdated information remaining
- [ ] Pattern added to authoritative patterns catalog

---

**5.5 Post-Launch Monitoring** [ongoing]

Set up continuous monitoring:
- Classification metrics dashboard
- Alerting rules (fallback rate, error rate, latency)
- Weekly review of disagreements
- Monthly quality report

**Acceptance Criteria**:
- [ ] Metrics dashboard deployed (if infrastructure available)
- [ ] Alerting rules configured
- [ ] On-call runbook created
- [ ] Incident response plan documented
- [ ] Monthly review process scheduled

---

### Phase 6: Standards Review and Updates (Optional)

**Duration**: 1-2 days
**Complexity**: 3/10
**Dependencies**: Phase 5 complete (production stable)

**Objective**: Review and update .claude/docs/ standards based on learnings from implementation.

#### Tasks

**6.1 Review Architectural Standards** [1 day]

Review `.claude/docs/reference/command_architecture_standards.md` (2,325 lines - AUTHORITATIVE):
- Does hybrid classification pattern warrant a new standard?
- Should we document LLM invocation patterns?
- Are there best practices to codify?
- Review compliance with existing Standards 0, 11, 13, 14

**Specific Standards to Consider**:
- **Standard 0 (Execution Enforcement)**: Does hybrid classifier need imperative language updates?
- **Standard 11 (Imperative Agent Invocation)**: Does LLM invocation via Task tool follow this pattern?
- **Standard 13 (Project Directory Detection)**: Verify CLAUDE_PROJECT_DIR usage in new library
- **Standard 14 (Executable/Documentation Separation)**: Verify guide file created for workflow-llm-classifier.sh

**Acceptance Criteria**:
- [ ] Standards document reviewed (all 15 standards)
- [ ] Compliance verified for Standards 0, 11, 13, 14
- [ ] Recommendations documented
- [ ] Team discussion scheduled (if updates needed)

---

**6.2 Update Standards (If Needed)** [1 day]

If standards updates identified:
- Draft proposed standard updates
- Get team feedback
- Update standards document
- Update compliance validation scripts
- Add hybrid classification pattern to Architectural Patterns catalog

**Files** (if applicable):
- MODIFY `.claude/docs/reference/command_architecture_standards.md`
- MODIFY `.claude/lib/validate-*.sh` (compliance validators)
- VERIFY `.claude/docs/concepts/patterns/llm-classification-pattern.md` (added in Phase 5.4)

**Acceptance Criteria**:
- [ ] Standards updated with team consensus
- [ ] Rationale documented (following clean-break philosophy)
- [ ] Compliance validation updated
- [ ] All commands still compliant
- [ ] Pattern properly cataloged in authoritative patterns directory

---

## Phase Dependencies

**Dependency Graph**:

```
Phase 0 (Research)
    │
    └──> Phase 1 (Core Library)
            │
            └──> Phase 2 (Integration)
                    │
                    └──> Phase 3 (Testing & QA)
                            │
                            └──> Phase 4 (Alpha Rollout)
                                    │
                                    ├──> Phase 5 (Production Rollout)
                                    │       │
                                    │       └──> Phase 6 (Standards Review)
                                    │
                                    └──> [ROLLBACK if issues]
```

**Critical Path**: Phase 0 → 1 → 2 → 3 → 4 → 5 (6-7 weeks minimum)

**Parallel Opportunities**:
- Phase 3.1 (A/B framework) can start during Phase 2 (integration)
- Phase 5.4 (documentation) can be drafted during Phase 4 (alpha)

---

## Testing Strategy

### Test Coverage Goals

| Component | Target Coverage | Test Count |
|-----------|-----------------|------------|
| workflow-llm-classifier.sh | 90%+ | 30+ |
| detect_workflow_scope_v2() | 95%+ | 20+ |
| Integration with /coordinate | 100% | 10+ |
| Edge cases | N/A | 15+ |
| A/B testing | N/A | 50+ real descriptions |

### Test Pyramid

```
       /\
      /  \     E2E Tests (10)
     /    \    - Full /coordinate workflow
    /------\   - Real AI assistant integration
   /        \
  /  INTEG.  \ Integration Tests (20)
 /            \ - detect_workflow_scope_v2()
/   UNIT (30)  \ - Fallback scenarios
----------------
Unit Tests (30)
- workflow-llm-classifier.sh functions
- Mock LLM responses
- Error handling
```

### Testing Phases

1. **Unit Testing** (Phase 1): Test functions in isolation with mocks
2. **Integration Testing** (Phase 2): Test library integration and fallback
3. **A/B Testing** (Phase 3): Compare LLM vs regex on real data
4. **Alpha Testing** (Phase 4): Real-world usage by developers
5. **Beta Testing** (Phase 5.1): Internal users, monitoring enabled
6. **Gamma Testing** (Phase 5.2): Subset of production traffic
7. **Production Monitoring** (Phase 5.3+): Continuous quality validation

---

## Risk Mitigation

### Risk Matrix

| Risk | Likelihood | Impact | Mitigation | Owner |
|------|------------|--------|------------|-------|
| LLM API outage | Medium | Low | Automatic regex fallback | System |
| High fallback rate (>50%) | Medium | Medium | Alert + investigate, can rollback | Oncall |
| Latency > 1s (p95) | Low | Medium | Reduce timeout, optimize prompt | Dev |
| Cost overrun | Very Low | Low | Negligible cost ($0.03/mo) | N/A |
| Backward compat break | Low | High | Comprehensive testing, v1 preserved | Dev |
| Classification errors | Medium | Medium | A/B testing, human review | Team |
| Rollback needed | Low | Low | Environment variable toggle | Oncall |

### Mitigation Strategies

**1. API Outage**:
- Detection: Timeout after 10 seconds
- Mitigation: Automatic fallback to regex
- Impact: Zero (transparent to user)

**2. High Fallback Rate**:
- Detection: Alert if > 50% for 1 hour
- Mitigation: Investigate LLM API health, adjust threshold
- Escalation: Switch to regex-only if > 80% for 15 min

**3. Performance Issues**:
- Detection: p95 latency > 1s alert
- Mitigation: Reduce timeout from 10s to 5s
- Escalation: Rollback to regex-only if > 2s

**4. Backward Compatibility**:
- Prevention: Comprehensive test suite (existing + new)
- Prevention: Preserve v1 function unchanged
- Validation: All existing tests must pass

**5. Classification Errors**:
- Detection: A/B testing disagreement rate
- Mitigation: Human review of disagreements
- Correction: Update prompt engineering or test dataset

---

## Success Criteria

### Phase 1 Success Criteria
- [ ] All functions implemented with error handling
- [ ] 30+ unit tests pass (90%+ coverage)
- [ ] Library works in isolation
- [ ] No API calls in tests (mocked)

### Phase 2 Success Criteria
- [ ] detect_workflow_scope_v2() works in all modes
- [ ] sm_init() uses v2
- [ ] 20+ integration tests pass
- [ ] Backward compatibility verified (v1 tests still pass)
- [ ] /coordinate completes successfully with hybrid classifier

### Phase 3 Success Criteria
- [ ] A/B testing framework operational
- [ ] 50+ real descriptions tested
- [ ] Agreement rate > 90%
- [ ] All edge cases documented
- [ ] Performance benchmarks acceptable (p95 < 800ms)

### Phase 4 Success Criteria
- [ ] 10+ developers using alpha
- [ ] 50+ classifications collected
- [ ] 80%+ satisfaction rate
- [ ] Zero critical bugs
- [ ] Fallback rate < 30%
- [ ] Go decision for beta

### Phase 5 Success Criteria
- [ ] Beta: 100+ classifications, 90%+ agreement, <25% fallback
- [ ] Gamma: 200+ classifications, 92%+ agreement, <20% fallback
- [ ] Production: Stable metrics, <15% fallback, <0.5% error rate
- [ ] All documentation complete
- [ ] Monitoring and alerting operational

### Phase 6 Success Criteria
- [ ] Standards reviewed
- [ ] Updates proposed (if needed)
- [ ] Team consensus achieved
- [ ] Compliance validated

---

## Rollback Plan

### Immediate Rollback (Zero Downtime)

**Trigger**: Critical issue detected (error rate > 10%, fallback rate > 80%, user complaints)

**Action**:
```bash
# Per-user rollback
export WORKFLOW_CLASSIFICATION_MODE=regex-only

# Global rollback (library-level)
# Edit .claude/lib/workflow-scope-detection.sh:
# Change default from "hybrid" to "regex-only"
```

**Timeline**: < 1 minute

### Planned Rollback

**Trigger**: Go/no-go decision at end of Phase 4 (alpha) or Phase 5.1 (beta)

**Action**:
1. Communicate rollback decision to team
2. Document lessons learned
3. Plan remediation (if applicable)
4. Set default to regex-only
5. Keep hybrid mode available for future retry

**Timeline**: 1 week notice

### Rollback Testing

**Validate rollback procedure works**:
```bash
# Test 1: Verify hybrid mode works
WORKFLOW_CLASSIFICATION_MODE=hybrid
result=$(detect_workflow_scope_v2 "test")

# Test 2: Rollback to regex-only
WORKFLOW_CLASSIFICATION_MODE=regex-only
result=$(detect_workflow_scope_v2 "test")

# Test 3: Verify no breaking changes
unset WORKFLOW_CLASSIFICATION_MODE
result=$(detect_workflow_scope "test")
```

**Acceptance Criteria**:
- [ ] Rollback procedure documented
- [ ] Rollback tested in alpha
- [ ] Zero downtime during rollback
- [ ] Users can opt-out easily

---

## Appendix: Task Checklist Summary

### Phase 1: Core Library (4 tasks)
- [ ] 1.1 Create workflow-llm-classifier.sh
- [ ] 1.2 Create unit test suite
- [ ] 1.3 Implement AI assistant integration
- [ ] 1.4 Validate library in isolation

### Phase 2: Integration (4 tasks)
- [ ] 2.1 Create detect_workflow_scope_v2()
- [ ] 2.2 Update sm_init() to use v2
- [ ] 2.3 Create integration test suite
- [ ] 2.4 End-to-end integration test

### Phase 3: Testing & QA (5 tasks)
- [ ] 3.1 Create A/B testing framework
- [ ] 3.2 Run A/B testing campaign
- [ ] 3.3 Edge case testing
- [ ] 3.4 Performance benchmarking
- [ ] 3.5 Regression testing

### Phase 4: Alpha Rollout (4 tasks)
- [ ] 4.1 Developer documentation
- [ ] 4.2 Alpha deployment
- [ ] 4.3 Developer feedback collection (2 weeks)
- [ ] 4.4 Alpha review and adjustments

### Phase 5: Production Rollout (5 tasks)
- [ ] 5.1 Beta rollout (2 weeks)
- [ ] 5.2 Gamma rollout (2 weeks)
- [ ] 5.3 Full production rollout
- [ ] 5.4 Documentation finalization
- [ ] 5.5 Post-launch monitoring (ongoing)

### Phase 6: Standards Review (2 tasks - optional)
- [ ] 6.1 Review architectural standards
- [ ] 6.2 Update standards (if needed)

**Total Tasks**: 24 (22 required + 2 optional)

---

## Appendix: File Change Summary

### New Files (3 files, ~450 lines)
- `.claude/lib/workflow-llm-classifier.sh` (~200 lines)
- `.claude/tests/test_llm_classifier.sh` (~150 lines)
- `.claude/tests/test_scope_detection_ab.sh` (~100 lines)

### Modified Files (4 files, ~155 lines added)
- `.claude/lib/workflow-scope-detection.sh` (+50 lines)
- `.claude/lib/workflow-state-machine.sh` (+5 lines)
- `.claude/tests/test_scope_detection.sh` (+100 lines)
- `.claude/tests/run_all_tests.sh` (+3 lines to include new tests)

### Documentation (6 files, ~565 lines)
- `.claude/docs/guides/coordinate-command-guide.md` (~150 lines)
- `.claude/docs/reference/library-api.md` (~80 lines)
- `.claude/docs/concepts/patterns/llm-classification-pattern.md` (~200 lines, new file)
- `CLAUDE.md` (~10 lines)
- `.claude/tests/README.md` (~50 lines)
- `.claude/docs/guides/orchestration-troubleshooting.md` (~60 lines)

**Total Lines of Code**: ~595 lines (excluding documentation)
**Total Lines of Documentation**: ~565 lines

---

## Appendix: Estimated Timeline

**Development**: 3-4 weeks
- Phase 1: 4 days
- Phase 2: 3 days
- Phase 3: 4 days
- Buffer: 5 days

**Rollout**: 4-6 weeks
- Phase 4 (Alpha): 2 weeks
- Phase 5.1 (Beta): 2 weeks
- Phase 5.2 (Gamma): 2 weeks
- Phase 5.3 (Production): Immediate after gamma success

**Total**: 7-10 weeks (conservative estimate)

**Fast-Track Option**: 5-6 weeks (if alpha/beta phases shortened)

---

---

## Revision History

### Revision 1 - 2025-11-11
- **Date**: 2025-11-11
- **Type**: research-informed
- **Research Reports Used**:
  - `/home/benjamin/.config/.claude/specs/670_workflow_classification_improvement/reports/001_claude_docs_standards.md` - Claude Docs Standards and Architectural Guidelines Report
  - `/home/benjamin/.config/.claude/specs/670_workflow_classification_improvement/reports/002_claude_infrastructure_analysis.md` - .claude/ Infrastructure Analysis: Workflow Classification Implementation
- **Key Changes**:
  - Added "Integration with Existing Infrastructure" section to Solution Overview documenting dual library architecture, state machine integration, and standards compliance
  - Enhanced Phase 1 Task 1.1 with Standards 13 and 14 compliance requirements and bash-block-execution-model patterns
  - Enhanced Phase 2 Task 2.1 to include v2 wrapper for workflow-detection.sh (dual library support) and state machine integration pattern
  - Updated Phase 3 Task 3.5 with baseline test results (56/58 passing tests) from infrastructure analysis
  - Enhanced Phase 5 Task 5.4 with Standard 14 compliance, Diataxis framework references, and architectural patterns catalog integration
  - Enhanced Phase 6 Tasks 6.1-6.2 with specific Standards 0, 11, 13, 14 review requirements and pattern catalog verification
- **Rationale**: Research revealed comprehensive architectural standards and existing infrastructure patterns that must be followed for successful integration. Changes ensure hybrid classifier aligns with established Command Architecture Standards (15 standards), state-based orchestration patterns, and dual library architecture serving both /coordinate and /supervise commands.
- **Backup**: `/home/benjamin/.config/.claude/specs/670_workflow_classification_improvement/plans/backups/001_hybrid_classification_implementation_20251111_145517.md`

---

**End of Implementation Plan**

**Next Steps**:
1. Review this plan with team
2. Get approval for Phase 1 implementation
3. Assign developer resources
4. Schedule kickoff meeting
5. Begin Phase 1 (Core Library development)

**Questions? See**:
- Architecture: `../reports/003_implementation_architecture.md`
- Research: `../reports/001_llm_based_classification_research.md`
- Analysis: `../../workflow_scope_detection_analysis.md`
- Standards: `../reports/001_claude_docs_standards.md` (NEW)
- Infrastructure: `../reports/002_claude_infrastructure_analysis.md` (NEW)
