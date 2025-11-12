# LLM-Based Workflow Classification Diagnostic and Accuracy Fixes

## Metadata
- **Date**: 2025-11-12
- **Feature**: Fix workflow classification to ensure Haiku LLM model is used and research-and-revise patterns are correctly detected
- **Scope**: Diagnostic infrastructure, classification accuracy, logging integration, test coverage
- **Estimated Phases**: 4
- **Estimated Hours**: 12
- **Structure Level**: 0
- **Complexity Score**: 67.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [LLM Classification Diagnostics](../reports/001_llm_classification_diagnostics.md)
  - [Classification Accuracy Analysis](../reports/002_classification_accuracy_analysis.md)
- **Topic Directory**: /home/benjamin/.config/.claude/specs/681_workflow_not_correctly_classify_workflow_since

## Overview

The hybrid LLM-based workflow classification system has excellent research-and-revise detection (95% accuracy, 19/20 tests passing) but lacks visibility into whether the Haiku LLM model is actually being invoked. The primary issue is stderr redirection (`2>/dev/null`) that silences LLM invocation signals and timeout errors. Additionally, one regex priority ordering issue causes "research X and implement Y" patterns to incorrectly classify as full-implementation instead of research-and-plan.

This implementation plan adds diagnostic infrastructure to verify LLM invocation, fixes the single failing test case through regex reordering, integrates with unified-logger.sh for persistent classification logs, and adds comprehensive test coverage for edge cases.

## Research Summary

**Key Findings from Research Reports**:

1. **LLM Invocation Visibility** (Report 001):
   - Stderr redirection at workflow-scope-detection.sh:58 silences `[LLM_CLASSIFICATION_REQUEST]` signal
   - No persistent logging of classification decisions
   - Two debug environment variables exist but no structured logging integration
   - Temporary files in /tmp/ provide evidence but are ephemeral
   - 7 comprehensive recommendations for logging infrastructure

2. **Classification Accuracy** (Report 002):
   - 95% test pass rate (19/20 tests)
   - Research-and-revise patterns: 100% accuracy (4/4 tests passing)
   - Single failure: "research X and implement Y" incorrectly matches full-implementation
   - Root cause: Regex priority ordering evaluates "implement" keyword before research-only pattern
   - EXISTING_PLAN_PATH extraction pattern too broad (matches any .md file, not just plan paths)
   - LLM classifier handles meta-research correctly ("research the research-and-revise workflow" → research-and-plan)

3. **Architectural Strengths**:
   - Hybrid mode with automatic fallback provides zero operational risk
   - Three classification modes (hybrid, llm-only, regex-only)
   - Research-and-revise is PRIORITY 1 (evaluated first, explains 100% accuracy)
   - State persistence for EXISTING_PLAN_PATH across bash blocks
   - Comprehensive test suite (294 lines, 20 tests)

## Success Criteria

- [ ] Diagnostic logging infrastructure integrated with unified-logger.sh
- [ ] Classification decisions logged persistently to workflow-classification.log
- [ ] LLM invocation visibility via preserved stderr or log file redirection
- [ ] Single failing test fixed (research-and-implement pattern)
- [ ] Test pass rate: 100% (20/20 tests passing)
- [ ] EXISTING_PLAN_PATH extraction pattern tightened to require plans/ subdirectory
- [ ] 5 new edge case tests added (compound keywords, multiple paths, meta-research, case sensitivity)
- [ ] Debug mode preserves temporary files for post-execution inspection
- [ ] All classification methods (llm, regex, regex-fallback) logged with timing data
- [ ] Documentation updated with LLM invocation verification procedures

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│ /coordinate (or other orchestrator)                         │
│ - Calls: detect_workflow_scope("research X and implement") │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ workflow-scope-detection.sh (HYBRID MODE)                   │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ classify_workflow_llm() [LLM-FIRST]                     │ │
│ │ - Build JSON request with intent-focused instructions   │ │
│ │ - Write to /tmp/llm_classification_request_$$.json     │ │
│ │ - Emit [LLM_CLASSIFICATION_REQUEST] to stderr ───────┐ │ │
│ │ - Wait for response (10s timeout)                     │ │ │
│ │ - Parse confidence score (threshold: 0.7)             │ │ │
│ │ - Log to workflow-classification.log ◄─────────┐     │ │ │
│ │                                                 │     │ │ │
│ │ IF: timeout OR low-confidence OR error          │     │ │ │
│ │   THEN: automatic fallback ──────────────┐     │     │ │ │
│ └──────────────────────────────────────────┼─────┼─────┼─┘ │
│                                             │     │     │   │
│ ┌───────────────────────────────────────────┼─────┼─────┼─┐ │
│ │ classify_workflow_regex() [FALLBACK]     │     │     │ │ │
│ │                                           ▼     │     │ │ │
│ │ PRIORITY 1: Research-and-revise patterns       │     │ │ │
│ │ PRIORITY 2: Plan path detection                │     │ │ │
│ │ PRIORITY 3: Research-only pattern [MOVED UP]   │     │ │ │
│ │ PRIORITY 4: Explicit keywords (implement) [▼]  │     │ │ │
│ │ PRIORITY 5: Default fallback                   │     │ │ │
│ │                                                 │     │ │ │
│ │ - Extract EXISTING_PLAN_PATH (tightened)       │     │ │ │
│ │ - Log to workflow-classification.log ──────────┘     │ │ │
│ └──────────────────────────────────────────────────────┼─┘ │
└────────────────────────────────────────────────────────┼───┘
                                                          │
                                                          ▼
┌─────────────────────────────────────────────────────────────┐
│ unified-logger.sh                                           │
│ - log_workflow_classification(mode, method, scope, conf)   │
│ - Structured JSON logging with rotation                    │
│ - Query functions: get_classification_stats()              │
│                                                             │
│ Output: .claude/data/logs/workflow-classification.log      │
│ Format: [timestamp] mode=hybrid, method=llm, scope=X,      │
│         confidence=0.95, duration_ms=250                    │
└─────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **Logging Integration Strategy**: Add `log_workflow_classification()` function to unified-logger.sh (follows existing adaptive-planning pattern)

2. **Stderr Handling**: Replace `2>/dev/null` with log file redirection to preserve LLM signals without polluting user stderr

3. **Regex Priority Reordering**: Move research-only pattern evaluation BEFORE explicit implementation keywords (fixes failing test)

4. **EXISTING_PLAN_PATH Tightening**: Require `/specs/{NNN}_topic/plans/` structure to prevent false matches

5. **Debug Mode Enhancement**: Preserve temporary files when `WORKFLOW_CLASSIFICATION_DEBUG=1` for post-execution inspection

6. **Backward Compatibility**: All changes are additive (no breaking changes to existing interfaces)

## Implementation Phases

### Phase 1: Diagnostic Infrastructure
dependencies: []

**Objective**: Add structured logging and visibility into LLM invocation

**Complexity**: Medium

**Tasks**:
- [ ] Add `log_workflow_classification()` function to unified-logger.sh (file: /home/benjamin/.config/.claude/lib/unified-logger.sh)
  - Signature: `log_workflow_classification(mode, method, scope, confidence, duration_ms)`
  - Log format: `[timestamp] INFO workflow_classification: mode=X, method=Y, scope=Z, confidence=N, duration_ms=M`
  - Output file: `.claude/data/logs/workflow-classification.log`
  - Include log rotation (10MB max, 5 files per existing pattern)
- [ ] Add timing instrumentation to classify_workflow_llm() (file: /home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh)
  - Capture start_time before invoke_llm_classifier()
  - Calculate duration_ms after response received
  - Pass duration to logging function
- [ ] Replace stderr redirection in workflow-scope-detection.sh line 58 (file: /home/benjamin/.config/.claude/lib/workflow-scope-detection.sh)
  - Before: `if scope=$(classify_workflow_llm "$workflow_description" 2>/dev/null); then`
  - After: `if scope=$(classify_workflow_llm "$workflow_description" 2>>"${CLAUDE_LOGS_DIR:-.claude/data/logs}/workflow-classification-debug.log"); then`
  - Preserves `[LLM_CLASSIFICATION_REQUEST]` signal and timeout errors
- [ ] Integrate logging calls in detect_workflow_scope() (file: /home/benjamin/.config/.claude/lib/workflow-scope-detection.sh)
  - Call log_workflow_classification() after successful LLM classification
  - Call log_workflow_classification() after regex fallback
  - Include classification method (llm, regex, regex-fallback) in all log entries
- [ ] Enhance log_scope_detection() to use unified-logger.sh (file: /home/benjamin/.config/.claude/lib/workflow-scope-detection.sh lines 185-195)
  - Source unified-logger.sh if available
  - Replace stderr echo with log_workflow_classification() call
  - Keep backward compatible stderr output for existing debug usage
- [ ] Update cleanup_temp_files() to preserve files in debug mode (file: /home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh)
  - Add condition: `if [ "${WORKFLOW_CLASSIFICATION_DEBUG}" != "1" ]; then rm -f ...; fi`
  - Echo preservation message when debug enabled

**Testing**:
```bash
# Test structured logging
export DEBUG_SCOPE_DETECTION=1
/coordinate "research authentication patterns"
cat .claude/data/logs/workflow-classification.log | tail -1
# Expected: [timestamp] INFO workflow_classification: mode=hybrid, method=llm, scope=research-and-plan

# Test debug file preservation
export WORKFLOW_CLASSIFICATION_DEBUG=1
/coordinate "implement user auth"
ls /tmp/llm_classification_*.json
# Expected: Files present after execution

# Test stderr preservation
tail -20 .claude/data/logs/workflow-classification-debug.log
# Expected: [LLM_CLASSIFICATION_REQUEST] signal visible
```

**Expected Duration**: 4 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(681): complete Phase 1 - Diagnostic Infrastructure`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Classification Accuracy Fixes
dependencies: [1]

**Objective**: Fix single failing test and improve EXISTING_PLAN_PATH extraction

**Complexity**: Low

**Tasks**:
- [ ] Reorder regex priority in classify_workflow_regex() (file: /home/benjamin/.config/.claude/lib/workflow-scope-detection.sh lines 134-174)
  - Move research-only pattern (currently PRIORITY 4) to PRIORITY 3
  - Move explicit keywords pattern (currently PRIORITY 3) to PRIORITY 4
  - Update inline comments to reflect new priority order
  - Rationale: "research X and implement Y" should default to research-and-plan (two-phase workflow)
- [ ] Tighten EXISTING_PLAN_PATH extraction pattern (file: /home/benjamin/.config/.claude/lib/workflow-scope-detection.sh line 140)
  - Before: `grep -oE "/[^ ]+\.md"`
  - After: `grep -oE "/specs/[0-9]+_[^/]+/plans/[^/]+\.md"`
  - Only matches valid plan paths in topic-based structure
  - Prevents extraction of documentation paths (README.md, etc.)
- [ ] Add inline documentation for priority ordering rationale (file: /home/benjamin/.config/.claude/lib/workflow-scope-detection.sh)
  - Document why revision patterns are PRIORITY 1 (most specific intent)
  - Document why research-only now precedes implementation keywords
  - Document why plan paths alone don't imply revision
  - Add comment explaining ambiguity resolution via LLM hybrid mode
- [ ] Verify /coordinate integration with tightened path extraction (file: /home/benjamin/.config/.claude/commands/coordinate.md lines 155-171)
  - No code changes needed (coordinate.md uses EXISTING_PLAN_PATH as-is)
  - Verify fail-fast error handling still triggers for invalid paths
  - Verify state persistence checkpoints remain unchanged

**Testing**:
```bash
# Test failing case now passes
source .claude/lib/workflow-scope-detection.sh
result=$(detect_workflow_scope "research async patterns and implement solution")
echo "$result"
# Expected: research-and-plan (not full-implementation)

# Test tightened path extraction
result=$(detect_workflow_scope "revise specs/042_auth/plans/001_plan.md per README.md")
echo "$EXISTING_PLAN_PATH"
# Expected: /specs/042_auth/plans/001_plan.md (not README.md)

# Run full test suite
bash .claude/tests/test_workflow_scope_detection.sh
# Expected: 20/20 tests passing (100% accuracy)
```

**Expected Duration**: 2 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(681): complete Phase 2 - Classification Accuracy Fixes`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Test Coverage Enhancement
dependencies: [2]

**Objective**: Add edge case tests to prevent future regressions

**Complexity**: Medium

**Tasks**:
- [ ] Add test for compound keywords pattern (file: /home/benjamin/.config/.claude/tests/test_workflow_scope_detection.sh)
  - Test case: "research auth patterns and plan to revise existing implementation"
  - Expected: research-and-revise (revision intent dominates)
  - Verifies PRIORITY 1 still takes precedence over other keywords
- [ ] Add test for plan path without revision verb (file: /home/benjamin/.config/.claude/tests/test_workflow_scope_detection.sh)
  - Test case: "implement specs/042_auth/plans/001_plan.md"
  - Expected: full-implementation (plan path alone is PRIORITY 2)
  - Verifies plan paths don't automatically imply revision
- [ ] Add test for multiple plan paths (file: /home/benjamin/.config/.claude/tests/test_workflow_scope_detection.sh)
  - Test case: "revise specs/042_auth/plans/001_plan.md and specs/043_logging/plans/002_plan.md"
  - Expected: research-and-revise, EXISTING_PLAN_PATH="/specs/042_auth/plans/001_plan.md"
  - Verifies extraction uses first occurrence (head -1)
- [ ] Add test for meta-research pattern (file: /home/benjamin/.config/.claude/tests/test_workflow_scope_detection.sh)
  - Test case: "research the research-and-revise workflow"
  - Expected: research-and-plan (LLM mode), research-and-revise (regex mode - acceptable discrepancy)
  - Add comment documenting LLM vs regex difference
  - This test may show different results depending on classification mode (intentional)
- [ ] Add test for case sensitivity (file: /home/benjamin/.config/.claude/tests/test_workflow_scope_detection.sh)
  - Test case: "REVISE specs/042_auth/plans/001_plan.md BASED ON feedback"
  - Expected: research-and-revise
  - Verifies case-insensitive flag (-i) works correctly
- [ ] Add test for invalid path filtering (file: /home/benjamin/.config/.claude/tests/test_workflow_scope_detection.sh)
  - Test case: "revise specs/042_auth/plans/001_plan.md per README.md"
  - Expected: EXISTING_PLAN_PATH="/specs/042_auth/plans/001_plan.md" (not README.md)
  - Verifies tightened extraction pattern from Phase 2
- [ ] Update test suite statistics in test file header (file: /home/benjamin/.config/.claude/tests/test_workflow_scope_detection.sh)
  - Update total test count (20 → 26 tests)
  - Update expected pass rate (19/20 → 26/26 after fixes)

**Testing**:
```bash
# Run extended test suite
bash .claude/tests/test_workflow_scope_detection.sh
# Expected: 26/26 tests passing (100% accuracy)

# Verify new edge cases covered
grep -c "Test [0-9]*:" .claude/tests/test_workflow_scope_detection.sh
# Expected: 26 (increased from 20)

# Test hybrid mode vs regex-only mode for meta-research
WORKFLOW_CLASSIFICATION_MODE=regex-only detect_workflow_scope "research the research-and-revise workflow"
# Expected: research-and-revise (regex matches keywords)

WORKFLOW_CLASSIFICATION_MODE=hybrid detect_workflow_scope "research the research-and-revise workflow"
# Expected: research-and-plan (LLM understands intent)
```

**Expected Duration**: 3 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(681): complete Phase 3 - Test Coverage Enhancement`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Documentation and Validation
dependencies: [1, 2, 3]

**Objective**: Update documentation and create verification procedures

**Complexity**: Low

**Tasks**:
- [ ] Create LLM invocation verification guide (file: /home/benjamin/.config/.claude/docs/guides/llm-classification-verification.md)
  - How to verify LLM is being invoked (check logs, debug flags, temp files)
  - How to distinguish LLM vs regex classification
  - How to interpret classification logs
  - Troubleshooting common issues (timeout, low confidence, fallback)
  - Example queries using unified-logger.sh functions
- [ ] Update workflow-scope-detection.sh inline documentation (file: /home/benjamin/.config/.claude/lib/workflow-scope-detection.sh)
  - Add function header comment for detect_workflow_scope()
  - Document environment variables (WORKFLOW_CLASSIFICATION_MODE, DEBUG_SCOPE_DETECTION)
  - Document return format and side effects (EXISTING_PLAN_PATH export)
  - Add examples of each classification mode in comments
- [ ] Update workflow-llm-classifier.sh inline documentation (file: /home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh)
  - Document timing instrumentation (start_time, duration_ms calculation)
  - Document debug mode temp file preservation
  - Add section on confidence threshold tuning
  - Document file-based signaling pattern and timeout behavior
- [ ] Update CLAUDE.md section on workflow classification (file: /home/benjamin/.config/CLAUDE.md)
  - Add reference to new verification guide
  - Document structured logging integration
  - Update classification accuracy metrics (95% → 100%)
  - Add troubleshooting quick reference
- [ ] Create diagnostic script for classification health check (file: /home/benjamin/.config/.claude/lib/test-workflow-classification.sh)
  - Test LLM connectivity with 5s timeout
  - Verify log file creation and rotation
  - Test all three classification modes (hybrid, llm-only, regex-only)
  - Display recent classification statistics from logs
  - Return exit code 0 if healthy, 1 if issues detected
- [ ] Update research reports with implementation status (files: both reports in /home/benjamin/.config/.claude/specs/681_workflow_not_correctly_classify_workflow_since/reports/)
  - Add "Implementation Status" section to report 001 with plan reference
  - Add "Implementation Status" section to report 002 with plan reference
  - Status: "Implementation Complete"
  - Plan: [../plans/001_llm_classification_fixes.md](../plans/001_llm_classification_fixes.md)

**Testing**:
```bash
# Run diagnostic health check
bash .claude/lib/test-workflow-classification.sh
# Expected: ✓ LLM classifier healthy, ✓ Logs created, ✓ All modes working

# Verify documentation completeness
grep -c "WORKFLOW_CLASSIFICATION" .claude/docs/guides/llm-classification-verification.md
# Expected: >10 references (comprehensive coverage)

# Verify log query functions
source .claude/lib/unified-logger.sh
get_classification_stats
# Expected: JSON output with llm_count, regex_count, fallback_count, avg_duration_ms

# Test all classification modes end-to-end
for mode in hybrid llm-only regex-only; do
  export WORKFLOW_CLASSIFICATION_MODE=$mode
  result=$(detect_workflow_scope "research authentication patterns")
  echo "$mode: $result"
done
# Expected: All three modes return valid scope
```

**Expected Duration**: 3 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(681): complete Phase 4 - Documentation and Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Tests
- **Target**: workflow-llm-classifier.sh and workflow-scope-detection.sh functions
- **Existing Coverage**: 442 lines in test_llm_classifier.sh (7 sections)
- **New Tests**: 6 edge cases added in Phase 3 (26 total tests)
- **Pass Rate Goal**: 100% (26/26 tests passing)

### Integration Tests
- **Manual E2E Tests**: manual_e2e_hybrid_classification.sh (6 existing test cases)
- **New Health Check**: test-workflow-classification.sh diagnostic script
- **Orchestrator Integration**: Test /coordinate with all workflow types

### Regression Tests
- **Baseline**: Current 19/20 passing tests must remain passing
- **Fix Validation**: Single failing test (research-and-implement) must pass
- **Edge Cases**: New 6 tests prevent future regressions

### Performance Tests
- **LLM Response Time**: Log analysis of duration_ms field
- **Timeout Behavior**: Verify 10s timeout triggers regex fallback
- **Log Rotation**: Verify 10MB rotation with 5 file retention

### Verification Checklist
- [ ] All 26 tests passing (100% accuracy)
- [ ] LLM invocation visible in debug logs
- [ ] Classification decisions logged to workflow-classification.log
- [ ] EXISTING_PLAN_PATH extraction matches only plan paths
- [ ] Debug mode preserves temporary files
- [ ] Health check script returns success
- [ ] Documentation updated and comprehensive
- [ ] Research reports marked "Implementation Complete"

## Documentation Requirements

### New Documentation Files
1. **llm-classification-verification.md**: Complete guide to verifying LLM invocation and troubleshooting
2. **test-workflow-classification.sh**: Executable health check and diagnostic script

### Updated Documentation Files
1. **workflow-scope-detection.sh**: Enhanced inline comments with priority rationale
2. **workflow-llm-classifier.sh**: Timing instrumentation and debug mode documentation
3. **CLAUDE.md**: Updated workflow classification section with metrics and troubleshooting
4. **Research Reports**: Implementation status sections with plan references

### Documentation Standards Compliance
- Use clear, concise language without historical commentary
- Include executable code examples
- Follow CommonMark specification
- No emojis in file content
- Cross-reference related documentation

## Dependencies

### External Dependencies
- unified-logger.sh: Structured logging infrastructure (already exists)
- CLAUDE_LOGS_DIR: Log directory path (default: .claude/data/logs/)
- bash 4.0+: Required for associative arrays in logging functions
- jq: JSON parsing for LLM responses (already required)

### Internal Dependencies
- Phase 2 depends on Phase 1: Logging must be in place before accuracy fixes (for verification)
- Phase 3 depends on Phase 2: Tests validate fixes from Phase 2
- Phase 4 depends on all phases: Documentation covers all changes

### Prerequisite Verification
```bash
# Verify unified-logger.sh exists
test -f .claude/lib/unified-logger.sh && echo "✓ Logging library present"

# Verify log directory exists or is creatable
mkdir -p "${CLAUDE_LOGS_DIR:-.claude/data/logs}" && echo "✓ Log directory ready"

# Verify jq available
command -v jq >/dev/null 2>&1 && echo "✓ jq installed"

# Verify bash version
bash --version | grep -q "version [4-9]" && echo "✓ Bash 4.0+"
```

## Risk Assessment

### Low Risk Items
- Phase 1 logging integration: Additive changes, no breaking modifications
- Phase 2 EXISTING_PLAN_PATH tightening: More restrictive pattern reduces false positives
- Phase 3 test coverage: Pure test additions, no production code impact
- Phase 4 documentation: Non-code changes

### Medium Risk Items
- Phase 2 regex priority reordering: Changes classification behavior for compound patterns
  - Mitigation: Comprehensive test suite validates all existing patterns remain correct
  - Rollback: Single file change, easily reverted
- Phase 1 stderr redirection change: May expose internal errors to debug logs
  - Mitigation: Redirect to separate debug log file, not user stderr
  - Benefit: Visibility outweighs risk of exposing implementation details

### Rollback Procedures
1. **Phase 1 Rollback**: Restore `2>/dev/null` redirection if stderr logging causes issues
2. **Phase 2 Rollback**: Revert regex priority order to original (PRIORITY 3 ↔ PRIORITY 4 swap)
3. **Phase 3 Rollback**: Remove new tests if they expose unexpected behavior
4. **Phase 4 Rollback**: Documentation rollback has no code impact

All changes are tracked in git with atomic commits per phase, enabling selective rollback.

## Notes

- **Complexity Score Calculation**: (24 tasks × 1.0) + (4 phases × 5.0) + (12 hours × 0.5) + (3 dependencies × 2.0) = 67.0
- **Structure Level**: 0 (single file plan, suitable for score < 200)
- **Phase Dependencies**: Phase 1 is foundational (no dependencies), Phases 2-3 run independently after Phase 1, Phase 4 consolidates all changes
- **Parallel Execution**: Phases 2 and 3 can potentially run in parallel after Phase 1 completes (both depend only on Phase 1)
- **Estimated Time Breakdown**: Phase 1 (4h) + Phase 2 (2h) + Phase 3 (3h) + Phase 4 (3h) = 12 hours total
- **Test Suite Growth**: 20 tests → 26 tests (30% increase in coverage)
- **Primary Benefit**: Zero operational risk maintained (hybrid mode always returns valid classification)
