# Comprehensive Haiku-Based Workflow Classification Implementation Plan

## Metadata
- **Date**: 2025-11-12
- **Feature**: Comprehensive haiku-based workflow classification with Phase 0 optimization
- **Scope**: Replace all pattern matching with single haiku call, eliminate Phase 0 pre-allocation tension, fix concurrent execution
- **Estimated Phases**: 6
- **Estimated Hours**: 10-13
- **Structure Level**: 0
- **Complexity Score**: 52.0 (calculation: 32 tasks × 1.0 + 6 phases × 5.0 + 11.5 hours × 0.5 + 5 dependencies × 2.0)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Current State Analysis](../reports/001_current_state_analysis.md)
  - [Phase 0 and Capture Improvements](../reports/002_phase0_and_capture_improvements.md)

## Overview

This plan implements comprehensive haiku-based classification to eliminate all pattern matching for workflow classification. Currently, Spec 670 replaced pattern matching for WORKFLOW_SCOPE detection, but RESEARCH_COMPLEXITY calculation still uses grep-based patterns (coordinate.md lines 402-414). This plan extends haiku integration to provide both scope and complexity in a single LLM call, along with descriptive subtopic names.

**Key Goals**:
1. Single haiku invocation returns: workflow_type, research_complexity, and subtopics array
2. Zero pattern matching for any classification dimension
3. Descriptive subtopic names in agent prompts (not "Topic N")
4. Fix diagnostic message confusion (4 paths saved vs 2 used)
5. Eliminate Phase 0 pre-allocation tension (fixed capacity vs dynamic usage)
6. Fix workflow description capture for concurrent execution safety
7. Maintain 100% backward compatibility for non-coordinate callers

## Research Summary

From [Current State Analysis Report](../reports/001_current_state_analysis.md):

**Root Cause of Issue 676**: Diagnostic message at coordinate.md:258 says "Saved 4 report paths" (capacity) but only RESEARCH_COMPLEXITY=2 paths are actually used. This is architecturally correct (Phase 0 pre-allocation) but causes user confusion. Solution: Update message to clarify capacity vs usage.

**Gap Analysis - Spec 670 Incompleteness**: Spec 670 successfully integrated haiku for WORKFLOW_SCOPE but did not extend to RESEARCH_COMPLEXITY or subtopic identification. This was by design (incremental deployment), not an oversight. Pattern matching still exists at coordinate.md:402-414 for complexity calculation.

From [Phase 0 and Capture Improvements Report](../reports/002_phase0_and_capture_improvements.md):

**Phase 0 Pre-Allocation Tension**: Current architecture allocates 4 paths before determining RESEARCH_COMPLEXITY, causing capacity/usage mismatch. Solution: Move complexity determination to sm_init (before path allocation), then dynamically allocate exact count needed. Eliminates unused variable exports entirely.

**Workflow Description Capture Issues**: Fixed filename `coordinate_workflow_desc.txt` creates concurrent execution risk and 45s initialization overhead. Solution: Use WORKFLOW_ID-based filename (`coordinate_workflow_desc_${WORKFLOW_ID}.txt`) for concurrency safety. Consider passing description directly to sm_init to eliminate temp file entirely.

**Implementation Approach**: Enhance `workflow-llm-classifier.sh` prompt to request comprehensive classification, update `sm_init()` to return RESEARCH_COMPLEXITY, modify `initialize_workflow_paths()` for dynamic allocation, fix temp file handling in coordinate.md. Single haiku call replaces two classification operations and enables just-in-time path allocation.

**Performance**: Expected ≤500ms for single haiku call (vs ~400ms + pattern matching overhead currently). Context reduction: 95%+ via metadata extraction maintained. Phase 0 optimization (85% token reduction) preserved with improved architecture.

## Success Criteria

- [ ] Zero pattern matching for workflow classification (scope or complexity) in any file
- [ ] Haiku returns comprehensive JSON with workflow_type, research_complexity, and subtopics
- [ ] RESEARCH_COMPLEXITY set by sm_init() during initialization (not calculated later)
- [ ] Descriptive subtopic names used in research agent prompts (not generic "Topic N")
- [ ] Diagnostic message clarifies capacity vs usage (Issue 676 resolved)
- [ ] Zero hardcoded path counts - dynamic allocation matches RESEARCH_COMPLEXITY exactly
- [ ] Concurrent execution safe - WORKFLOW_ID-based temp filenames prevent overwrites
- [ ] All 25+ test cases passing (100% test coverage including new Phase 0 tests)
- [ ] Clean break: All calls updated to classify_workflow_comprehensive() (zero references to old function name)
- [ ] Performance: Single haiku call ≤500ms (measured in tests)
- [ ] Fallback mode: Regex + heuristic complexity calculation when haiku fails
- [ ] Documentation updated (4 files: coordinate guide, LLM pattern, CLAUDE.md, phase-0 guide)

## Technical Design

### Architecture

**Revised Sequence (Haiku-First Classification)**:

```
┌────────────────────────────────────────────────────────────┐
│ coordinate.md: Workflow Capture (lines 18-40)             │
├────────────────────────────────────────────────────────────┤
│ FIXED: Use WORKFLOW_ID-based filename                     │
│ echo "$DESC" > coordinate_workflow_desc_${WORKFLOW_ID}.txt│
│ Prevents concurrent execution conflicts                   │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ coordinate.md: State Machine Initialization (lines 47-153)│
├────────────────────────────────────────────────────────────┤
│ sm_init("$SAVED_WORKFLOW_DESC", "coordinate")             │
│   ├─ CALLS: classify_workflow_comprehensive() [NEW]      │
│   │   ├─ Haiku prompt: Request all 3 dimensions          │
│   │   ├─ Response: {workflow_type, complexity, topics}   │
│   │   └─ Fallback: Regex scope + heuristic complexity    │
│   ├─ EXTRACTS: workflow_type → WORKFLOW_SCOPE            │
│   ├─ EXTRACTS: research_complexity → RESEARCH_COMPLEXITY │
│   ├─ EXTRACTS: subtopics → RESEARCH_TOPICS array         │
│   ├─ RETURNS: RESEARCH_COMPLEXITY for path allocation    │
│   └─ EXPORTS: All 3 variables to workflow state          │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ workflow-initialization.sh: Dynamic Path Allocation       │
├────────────────────────────────────────────────────────────┤
│ initialize_workflow_paths(RESEARCH_COMPLEXITY) [ENHANCED] │
│   ├─ Input: RESEARCH_COMPLEXITY (1-4)                    │
│   ├─ Allocate EXACTLY $RESEARCH_COMPLEXITY paths         │
│   ├─ Export REPORT_PATH_0 through REPORT_PATH_N-1        │
│   └─ Export REPORT_PATHS_COUNT = RESEARCH_COMPLEXITY     │
│ NO unused variables, perfect capacity/usage match        │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ coordinate.md: Research Phase (lines 340-436)             │
├────────────────────────────────────────────────────────────┤
│ ❌ DELETE: Pattern matching section (lines 402-414)      │
│ ✅ USE: $RESEARCH_COMPLEXITY from workflow state          │
│ ✅ USE: $RESEARCH_TOPICS array for descriptive names      │
└────────────────────────────────────────────────────────────┘
```

**Key Architectural Improvement**: Complexity determination moves BEFORE path allocation, enabling dynamic allocation that exactly matches usage. This eliminates the fixed-capacity (4) vs dynamic-usage (1-4) tension documented in Report 002.

### Enhanced Haiku Prompt Schema

**Request Format** (workflow-llm-classifier.sh):
```json
{
  "task": "classify_workflow_comprehensive",
  "description": "<workflow description>",
  "valid_scopes": ["research-only", "research-and-plan", ...],
  "instructions": "Return: workflow_type, research_complexity (1-4), subtopics array with descriptive names"
}
```

**Response Format**:
```json
{
  "workflow_type": "research-and-plan",
  "confidence": 0.92,
  "research_complexity": 2,
  "subtopics": [
    "Authentication patterns in existing codebase",
    "Security best practices for auth implementation"
  ],
  "reasoning": "User wants to research authentication (2 subtopics) then create plan"
}
```

### State Machine Integration

**New State Variables** (exported in sm_init):
- `WORKFLOW_SCOPE` (existing)
- `RESEARCH_COMPLEXITY` (NEW)
- `RESEARCH_TOPICS_JSON` (NEW - JSON array for bash block persistence)

**Clean Break - No Wrapper**:
Code analysis shows zero non-coordinate callers for detect_workflow_scope() in production code (all references are in .backup files, test files, or documentation). Following clean-break philosophy: delete detect_workflow_scope() entirely, replace all calls with classify_workflow_comprehensive(). No deprecation period needed.

### Fallback Logic

When haiku fails or returns low confidence:
1. Use `classify_workflow_regex()` for scope (existing Spec 670 fallback)
2. Use `infer_complexity_from_keywords()` for complexity (NEW heuristic function)
3. Generate generic topic names: "Topic 1", "Topic 2", etc.

## Implementation Phases

### Phase 1: Enhance Haiku Classifier Library
dependencies: []

**Objective**: Extend workflow-llm-classifier.sh to support comprehensive classification

**Complexity**: Medium

**Tasks**:
- [ ] Update `build_llm_classifier_input()` to add classification_type parameter (file: .claude/lib/workflow-llm-classifier.sh:90-123)
- [ ] Enhance JSON prompt to request research_complexity and subtopics fields (file: .claude/lib/workflow-llm-classifier.sh:100-122)
- [ ] Update `parse_llm_classifier_response()` to extract new fields: research_complexity, subtopics (file: .claude/lib/workflow-llm-classifier.sh:182-230)
- [ ] Add validation: research_complexity must be 1-4, subtopics array must match complexity count (file: .claude/lib/workflow-llm-classifier.sh:205-230)
- [ ] Create `classify_workflow_llm_comprehensive()` function as new entry point (file: .claude/lib/workflow-llm-classifier.sh, new function after line 82)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test enhanced prompt with haiku model
cd .claude/tests
./test_llm_classifier.sh --test-comprehensive
# Expected: 12 test cases covering comprehensive classification
```

**Expected Duration**: 2 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(678): complete Phase 1 - Enhanced Haiku Classifier Library`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 2: Add Comprehensive Classification Function
dependencies: [1]

**Objective**: Create classify_workflow_comprehensive() in workflow-scope-detection.sh

**Complexity**: Medium

**Tasks**:
- [ ] Create `classify_workflow_comprehensive()` function (file: .claude/lib/workflow-scope-detection.sh, add after line 115)
- [ ] Implement hybrid mode: Try haiku first, fallback to regex + heuristic (file: .claude/lib/workflow-scope-detection.sh, new function)
- [ ] Create `infer_complexity_from_keywords()` fallback function (file: .claude/lib/workflow-scope-detection.sh, new function after classify_workflow_comprehensive)
- [ ] Implement complexity calculation using same patterns as coordinate.md:402-414 (file: .claude/lib/workflow-scope-detection.sh)
- [ ] Create `generate_generic_topics()` helper for fallback mode (file: .claude/lib/workflow-scope-detection.sh, new function)
- [ ] Add `fallback_comprehensive_classification()` wrapper combining regex + heuristic (file: .claude/lib/workflow-scope-detection.sh)
- [ ] Delete detect_workflow_scope() function entirely - clean break (file: .claude/lib/workflow-scope-detection.sh)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test comprehensive classification with fallback
cd .claude/tests
./test_scope_detection.sh --test-comprehensive-mode
# Expected: 10 test cases for comprehensive classification + fallback
```

**Expected Duration**: 2.5 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(678): complete Phase 2 - Comprehensive Classification Function`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 3: Integrate with State Machine (Return RESEARCH_COMPLEXITY)
dependencies: [2]

**Objective**: Update sm_init() to return RESEARCH_COMPLEXITY for use in path allocation

**Complexity**: High

**Tasks**:
- [ ] Replace detect_workflow_scope() call with classify_workflow_comprehensive() in sm_init() (file: .claude/lib/workflow-state-machine.sh:140-180)
- [ ] Parse JSON response to extract workflow_type, research_complexity, subtopics (file: .claude/lib/workflow-state-machine.sh)
- [ ] Add validation: Check all fields present, complexity in 1-4 range, subtopics array not empty (file: .claude/lib/workflow-state-machine.sh)
- [ ] CRITICAL: Make sm_init() return RESEARCH_COMPLEXITY value (echo before return 0) (file: .claude/lib/workflow-state-machine.sh)
- [ ] Export RESEARCH_COMPLEXITY as global variable (file: .claude/lib/workflow-state-machine.sh)
- [ ] Serialize RESEARCH_TOPICS to RESEARCH_TOPICS_JSON for state persistence (file: .claude/lib/workflow-state-machine.sh)
- [ ] Add fallback handling: If haiku fails, use regex + heuristic and log warning (file: .claude/lib/workflow-state-machine.sh)
- [ ] Add diagnostic output: Log scope, complexity, and topics after initialization (file: .claude/lib/workflow-state-machine.sh)
- [ ] Update any other references to detect_workflow_scope() in workflow-state-machine.sh (search and replace)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test state machine integration
cd .claude/tests
./test_state_machine.sh --test-comprehensive-init
# Expected: sm_init sets all 3 variables correctly AND returns RESEARCH_COMPLEXITY
```

**Expected Duration**: 2 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(678): complete Phase 3 - State Machine Integration with Return Value`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 4: Dynamic Path Allocation Enhancement
dependencies: [3]

**Objective**: Update workflow-initialization.sh to allocate paths dynamically based on RESEARCH_COMPLEXITY

**Complexity**: Medium

**Tasks**:
- [ ] Modify `initialize_workflow_paths()` signature to accept RESEARCH_COMPLEXITY parameter (file: .claude/lib/workflow-initialization.sh:318)
- [ ] Replace hardcoded loop `for i in 1 2 3 4` with dynamic `for i in $(seq 1 $RESEARCH_COMPLEXITY)` (file: .claude/lib/workflow-initialization.sh:329-344)
- [ ] Update path export loop to only export allocated paths (file: .claude/lib/workflow-initialization.sh:337-342)
- [ ] Change `export REPORT_PATHS_COUNT=4` to `export REPORT_PATHS_COUNT=$RESEARCH_COMPLEXITY` (file: .claude/lib/workflow-initialization.sh:344)
- [ ] Update function documentation to reflect dynamic allocation behavior (file: .claude/lib/workflow-initialization.sh:320-328)
- [ ] Add validation: Ensure RESEARCH_COMPLEXITY is 1-4 range before allocation (file: .claude/lib/workflow-initialization.sh)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test dynamic path allocation
cd .claude/tests
./test_workflow_initialization.sh --test-dynamic-allocation
# Expected: Test that 2-complexity workflows allocate exactly 2 paths
```

**Expected Duration**: 1.5 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(678): complete Phase 4 - Dynamic Path Allocation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 5: Update coordinate.md (Pattern Removal & Temp File Fix)
dependencies: [4]

**Objective**: Remove pattern matching, fix temp file handling, integrate dynamic allocation

**Complexity**: Medium

**Tasks**:
- [ ] Fix Part 1 temp file to use WORKFLOW_ID-based filename (file: .claude/commands/coordinate.md:36-37)
- [ ] Update Part 2 to read WORKFLOW_ID and construct filename (file: .claude/commands/coordinate.md:65)
- [ ] Capture RESEARCH_COMPLEXITY return value from sm_init() call (file: .claude/commands/coordinate.md:153)
- [ ] Pass RESEARCH_COMPLEXITY to initialize_workflow_paths() call (file: .claude/commands/coordinate.md:160)
- [ ] Save RESEARCH_COMPLEXITY to workflow state in initialization block (file: .claude/commands/coordinate.md:174-177)
- [ ] Save RESEARCH_TOPICS_JSON to workflow state in initialization block (file: .claude/commands/coordinate.md:174-177)
- [ ] Delete pattern matching section entirely (file: .claude/commands/coordinate.md:402-414, DELETE 13 lines)
- [ ] Add comment explaining RESEARCH_COMPLEXITY loaded from state (file: .claude/commands/coordinate.md:402, replace deleted section)
- [ ] Update diagnostic message at line 258 to clarify capacity matches usage (file: .claude/commands/coordinate.md:258)
- [ ] Replace generic topic names with descriptive names from RESEARCH_TOPICS array (file: .claude/commands/coordinate.md:485-490)
- [ ] Add state load for RESEARCH_TOPICS_JSON and reconstruct array (file: .claude/commands/coordinate.md:418-420, new code)
- [ ] Add cleanup of temp file after reading (optional nice-to-have) (file: .claude/commands/coordinate.md:68)

**Testing**:
```bash
# Test coordinate command with comprehensive classification
cd .claude/tests
./test_coordinate_comprehensive.sh
# Expected: 15 test cases for end-to-end coordinate workflow
```

**Expected Duration**: 2 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(678): complete Phase 5 - coordinate.md Integration and Temp File Fix`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 6: Testing and Documentation
dependencies: [5]

**Objective**: Comprehensive testing and documentation updates

**Complexity**: Medium

**Tasks**:
- [ ] Create comprehensive test suite with 25+ test cases (file: .claude/tests/test_comprehensive_classification.sh, new file)
- [ ] Test haiku classification for all workflow types (5 tests)
- [ ] Test complexity determination (1-4 topics, 4 tests)
- [ ] Test subtopic name extraction (3 tests)
- [ ] Test fallback mode when haiku fails (4 tests)
- [ ] Test clean break: verify zero references to detect_workflow_scope() in production code (3 tests)
- [ ] Test dynamic path allocation (3 tests - verify exact count matches complexity)
- [ ] Test concurrent execution safety (3 tests - verify WORKFLOW_ID-based filenames)
- [ ] Test coordinate.md integration end-to-end (3 tests)
- [ ] Update test files to use classify_workflow_comprehensive() instead of detect_workflow_scope() (file: .claude/tests/*.sh, global update)
- [ ] Update coordinate-command-guide.md with comprehensive classification section (file: .claude/docs/guides/coordinate-command-guide.md, add section)
- [ ] Update llm-classification-pattern.md with comprehensive examples (file: .claude/docs/concepts/patterns/llm-classification-pattern.md, add section)
- [ ] Update phase-0-optimization.md with dynamic allocation approach (file: .claude/docs/guides/phase-0-optimization.md, add section)
- [ ] Update CLAUDE.md workflow classification description (file: CLAUDE.md, update state_based_orchestration section)
- [ ] Update documentation references to detect_workflow_scope() to use classify_workflow_comprehensive() (file: .claude/docs/**/*.md, global update)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Run complete test suite
cd .claude/tests
./run_all_tests.sh
# Expected: All tests passing, including 25+ new comprehensive classification tests
```

**Expected Duration**: 2.5 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(678): complete Phase 6 - Testing and Documentation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Unit Testing
- Test each function in isolation with mock inputs
- Cover success paths, error paths, and edge cases
- Validate JSON schema compliance for haiku responses

### Integration Testing
- Test sm_init() with comprehensive classification
- Test coordinate.md workflow with descriptive topic names
- Test fallback mode when haiku unavailable

### Clean Break Testing
- Verify zero references to detect_workflow_scope() remain in production code
- Verify all test files updated to use classify_workflow_comprehensive()
- Verify all documentation updated with new function name
- Test existing workflows still function correctly with new function
- Validate state persistence across bash block boundaries

### Performance Testing
- Measure haiku classification latency (target: ≤500ms)
- Compare single comprehensive call vs two separate calls
- Validate Phase 0 optimization maintained (85% token reduction)

### Test Coverage Requirements
- 100% coverage for new functions (classify_workflow_comprehensive, infer_complexity_from_keywords, generate_generic_topics)
- 100% coverage for enhanced functions (build_llm_classifier_input, parse_llm_classifier_response)
- End-to-end coverage for coordinate.md workflow (research phase invocation with descriptive topics)

## Documentation Requirements

### User-Facing Documentation
- Update `/coordinate` command guide with comprehensive classification explanation
- Add examples showing descriptive subtopic names in agent prompts
- Document fallback behavior when haiku unavailable

### Developer Documentation
- Update LLM classification pattern with comprehensive classification examples
- Document enhanced haiku prompt schema and response format
- Add architectural diagrams showing single-call classification flow

### Standards Updates
- Update CLAUDE.md state-based orchestration section
- Document new environment variables (RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON)
- Add comprehensive classification to workflow scope detection pattern documentation

## Dependencies

### External Dependencies
- Haiku 4.5 model availability (Claude API)
- jq for JSON parsing (already required)
- Bash 4.0+ for array operations

### Internal Dependencies
- workflow-llm-classifier.sh (Phase 1 output feeds Phase 2)
- workflow-scope-detection.sh (Phase 2 output feeds Phase 3)
- workflow-state-machine.sh (Phase 3 output feeds Phase 4)
- coordinate.md (consumes all previous phases)

### Phase Dependencies
Phase 1 must complete before Phase 2 (enhanced classifier is prerequisite)
Phase 2 must complete before Phase 3 (comprehensive function is prerequisite)
Phase 3 must complete before Phase 4 (state machine exports needed by coordinate.md)
Phase 4 must complete before Phase 5 (end-to-end tests require coordinate.md changes)

**Note**: Phase dependencies enable parallel execution when using `/implement`.
- Empty `[]` or omitted = no dependencies (runs in first wave)
- `[1]` = depends on Phase 1 (runs after Phase 1 completes)
- `[1, 2]` = depends on Phases 1 and 2 (runs after both complete)
- Phases with same dependencies can run in parallel

## Risk Management

### Technical Risks
1. **Haiku latency variability**: Mitigation - timeout after 10s, fallback to regex + heuristic
2. **JSON schema drift**: Mitigation - strict validation with jq, fail-fast on malformed responses
3. **Breaking existing references**: Mitigation - comprehensive grep to find all detect_workflow_scope() calls, update in single commit
4. **State persistence failures**: Mitigation - defensive JSON handling, graceful degradation

### Process Risks
1. **Test coverage gaps**: Mitigation - 22 comprehensive test cases covering all code paths
2. **Documentation drift**: Mitigation - update docs in Phase 5 before completion
3. **Performance regression**: Mitigation - measure latency, validate ≤500ms target

## Rollback Strategy

If comprehensive classification causes issues:
1. Revert the single commit containing all changes (clean break means single atomic commit)
2. Git history contains the old detect_workflow_scope() function for reference
3. No compatibility shims to maintain - rollback is complete reversion

Rollback time estimate: 5 minutes (single git revert command)
Rollback validation: Run existing test suite, verify all tests passing

**Clean Break Advantage**: Single commit with all changes (function replacement + test updates + documentation updates) means rollback is trivial - just revert one commit. No gradual migration complexity.

## Performance Targets

- **Haiku classification latency**: ≤500ms (single comprehensive call)
- **Fallback overhead**: ≤50ms (regex + heuristic calculation)
- **State persistence overhead**: ≤10ms (JSON serialization for 3 variables)
- **Total initialization overhead**: ≤600ms (includes comprehensive classification)

Baseline comparison (current):
- detect_workflow_scope: ~400ms (haiku for scope only)
- Pattern matching: ~5ms (grep-based complexity)
- Total current: ~405ms

Expected improvement: Single 500ms call replaces 405ms + eliminates pattern matching false positives

## Success Metrics

### Functional Metrics
- Zero pattern matching for any workflow classification dimension
- 100% test coverage (22/22 tests passing)
- Descriptive topic names in all research agent prompts
- Issue 676 diagnostic confusion resolved

### Quality Metrics
- Zero regressions in existing workflows
- Clean break: Zero references to old function name in production code
- All test files updated to new function in same commit
- All documentation updated to new function in same commit
- Fallback mode works reliably when haiku unavailable

### Performance Metrics
- Haiku classification ≤500ms (95th percentile)
- Phase 0 optimization maintained (85% token reduction)
- No increase in total initialization overhead

## Notes

This implementation follows clean-break philosophy:
- Delete pattern matching entirely (no deprecation period)
- Fail-fast on invalid haiku responses (no silent fallbacks to old behavior)
- Use descriptive names throughout (no legacy "Topic N" placeholders)

The diagnostic message fix (Issue 676) is a quick win that can be cherry-picked independently if needed.

---

## Revision History

### Revision 2 - 2025-11-12

- **Date**: 2025-11-12
- **Type**: clean-break refactoring
- **Research Reports Used**:
  - [Current State Analysis](../reports/001_current_state_analysis.md) - Confirmed zero non-coordinate callers
  - [Phase 0 and Capture Improvements](../reports/002_phase0_and_capture_improvements.md) - Architectural context
- **Key Changes**:
  - **Removed Backward Compatibility**: Deleted all references to detect_workflow_scope() wrapper function
  - **Success Criteria Update**: Changed "Backward compatibility: detect_workflow_scope() wrapper still works" to "Clean break: All calls updated to classify_workflow_comprehensive()"
  - **Technical Design Update**: Replaced wrapper code example with "Clean Break - No Wrapper" explanation citing zero external callers
  - **Phase 2 Enhancement**: Added task to delete detect_workflow_scope() function entirely
  - **Phase 3 Enhancement**: Added task to update any other references in workflow-state-machine.sh
  - **Phase 6 Enhancement**: Added tasks to update test files and documentation references globally
  - **Testing Strategy**: Changed "Backward Compatibility Testing" to "Clean Break Testing" with verification of zero old function references
  - **Risk Management**: Changed risk #3 from "Backward compatibility breakage" to "Breaking existing references" with mitigation via comprehensive grep
  - **Rollback Strategy**: Simplified from gradual migration to single atomic commit reversion (5 minutes vs 30 minutes)
  - **Quality Metrics**: Added clean break verification criteria
- **Rationale**: Code analysis (grep of entire codebase) revealed zero non-coordinate callers for detect_workflow_scope() in production code. All references found were in .backup files, test files, or documentation. User prefers clean-break philosophy per CLAUDE.md: "delete obsolete code immediately after migration, no deprecation warnings, no compatibility shims." The wrapper is unnecessary technical debt. Clean break enables simpler rollback (single commit revert) and eliminates ongoing maintenance burden.
- **Backup**: /home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/plans/backups/001_comprehensive_classification_implementation_20251112_125215.md

### Revision 1 - 2025-11-12

- **Date**: 2025-11-12
- **Type**: research-informed
- **Research Reports Used**:
  - [Current State Analysis](../reports/001_current_state_analysis.md) - Root cause analysis of Issue 676 and Spec 670 gap analysis
  - [Phase 0 and Capture Improvements](../reports/002_phase0_and_capture_improvements.md) - Phase 0 pre-allocation tension, workflow capture performance, concurrent execution risks
- **Key Changes**:
  - **Phase 0 Architecture Overhaul**: Added Phase 4 to implement dynamic path allocation based on RESEARCH_COMPLEXITY returned from sm_init, eliminating fixed-capacity (4) vs dynamic-usage (1-4) tension
  - **sm_init Return Value**: Enhanced Phase 3 to make sm_init() return RESEARCH_COMPLEXITY for use in path allocation (critical architectural change)
  - **Workflow Capture Fix**: Added temp file handling improvements to Phase 5 (WORKFLOW_ID-based filenames for concurrent execution safety)
  - **Phase Reorganization**: Original Phase 4 became Phase 5, original Phase 5 became Phase 6
  - **Success Criteria Expansion**: Added zero hardcoded path counts, concurrent execution safety, 25+ tests (up from 22)
  - **Complexity Score Update**: Increased from 45.0 to 52.0 (32 tasks vs 22, 6 phases vs 5, 11.5 hours vs 9)
  - **Technical Design Enhancement**: Updated architecture diagram to show haiku-first sequence with complexity determination before path allocation
- **Rationale**: Report 002 revealed that current Phase 0 pre-allocation creates architectural tension by allocating paths before determining complexity. Moving complexity determination to sm_init enables just-in-time dynamic allocation that exactly matches usage, eliminating unused variable exports and resolving the capacity/usage mismatch confusion. The workflow capture fix addresses concurrent execution risks and potential performance optimization opportunities.
- **Backup**: /home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/plans/backups/001_comprehensive_classification_implementation_20251112_123726.md
