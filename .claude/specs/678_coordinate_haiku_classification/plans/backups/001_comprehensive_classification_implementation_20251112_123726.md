# Comprehensive Haiku-Based Workflow Classification Implementation Plan

## Metadata
- **Date**: 2025-11-12
- **Feature**: Comprehensive haiku-based workflow classification
- **Scope**: Replace all pattern matching with single haiku call for both WORKFLOW_SCOPE and RESEARCH_COMPLEXITY
- **Estimated Phases**: 5
- **Estimated Hours**: 8-10
- **Structure Level**: 0
- **Complexity Score**: 45.0 (calculation: 22 tasks × 1.0 + 5 phases × 5.0 + 9 hours × 0.5 + 5 dependencies × 2.0)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Current State Analysis](../reports/001_current_state_analysis.md)

## Overview

This plan implements comprehensive haiku-based classification to eliminate all pattern matching for workflow classification. Currently, Spec 670 replaced pattern matching for WORKFLOW_SCOPE detection, but RESEARCH_COMPLEXITY calculation still uses grep-based patterns (coordinate.md lines 402-414). This plan extends haiku integration to provide both scope and complexity in a single LLM call, along with descriptive subtopic names.

**Key Goals**:
1. Single haiku invocation returns: workflow_type, research_complexity, and subtopics array
2. Zero pattern matching for any classification dimension
3. Descriptive subtopic names in agent prompts (not "Topic N")
4. Fix diagnostic message confusion (4 paths saved vs 2 used)
5. Maintain 100% backward compatibility for non-coordinate callers

## Research Summary

From [Current State Analysis Report](../reports/001_current_state_analysis.md):

**Root Cause of Issue 676**: Diagnostic message at coordinate.md:258 says "Saved 4 report paths" (capacity) but only RESEARCH_COMPLEXITY=2 paths are actually used. This is architecturally correct (Phase 0 pre-allocation) but causes user confusion. Solution: Update message to clarify capacity vs usage.

**Gap Analysis - Spec 670 Incompleteness**: Spec 670 successfully integrated haiku for WORKFLOW_SCOPE but did not extend to RESEARCH_COMPLEXITY or subtopic identification. This was by design (incremental deployment), not an oversight. Pattern matching still exists at coordinate.md:402-414 for complexity calculation.

**Implementation Approach**: Enhance `workflow-llm-classifier.sh` prompt to request comprehensive classification, update `sm_init()` to extract all fields, delete pattern matching section from coordinate.md, use descriptive topic names in agent prompts. Single haiku call replaces two classification operations.

**Performance**: Expected ≤500ms for single haiku call (vs ~400ms + pattern matching overhead currently). Context reduction: 95%+ via metadata extraction maintained.

## Success Criteria

- [ ] Zero pattern matching for workflow classification (scope or complexity) in any file
- [ ] Haiku returns comprehensive JSON with workflow_type, research_complexity, and subtopics
- [ ] RESEARCH_COMPLEXITY set by sm_init() during initialization (not calculated later)
- [ ] Descriptive subtopic names used in research agent prompts (not generic "Topic N")
- [ ] Diagnostic message clarifies capacity vs usage (Issue 676 resolved)
- [ ] All 22 test cases passing (100% test coverage)
- [ ] Backward compatibility: detect_workflow_scope() wrapper still works for non-coordinate callers
- [ ] Performance: Single haiku call ≤500ms (measured in tests)
- [ ] Fallback mode: Regex + heuristic complexity calculation when haiku fails
- [ ] Documentation updated (3 files: coordinate guide, LLM pattern, CLAUDE.md)

## Technical Design

### Architecture

```
┌────────────────────────────────────────────────────────────┐
│ coordinate.md: Initialization (lines 47-153)              │
├────────────────────────────────────────────────────────────┤
│ sm_init("$SAVED_WORKFLOW_DESC", "coordinate")             │
│   ├─ CALLS: classify_workflow_comprehensive() [NEW]      │
│   │   ├─ Haiku prompt: Request all 3 dimensions          │
│   │   ├─ Response: {workflow_type, complexity, topics}   │
│   │   └─ Fallback: Regex scope + heuristic complexity    │
│   ├─ EXTRACTS: workflow_type → WORKFLOW_SCOPE            │
│   ├─ EXTRACTS: research_complexity → RESEARCH_COMPLEXITY │
│   ├─ EXTRACTS: subtopics → RESEARCH_TOPICS array         │
│   └─ EXPORTS: All 3 variables to workflow state          │
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

**Backward Compatibility Wrapper**:
```bash
# Keep detect_workflow_scope() for non-coordinate callers
detect_workflow_scope() {
  local result=$(classify_workflow_comprehensive "$1")
  echo "$result" | jq -r '.workflow_type'
}
```

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

### Phase 3: Integrate with State Machine
dependencies: [2]

**Objective**: Update sm_init() to use comprehensive classification and export all variables

**Complexity**: High

**Tasks**:
- [ ] Replace `detect_workflow_scope()` call with `classify_workflow_comprehensive()` in sm_init() (file: .claude/lib/workflow-state-machine.sh:140-180)
- [ ] Parse JSON response to extract workflow_type, research_complexity, subtopics (file: .claude/lib/workflow-state-machine.sh)
- [ ] Add validation: Check all fields present, complexity in 1-4 range, subtopics array not empty (file: .claude/lib/workflow-state-machine.sh)
- [ ] Export RESEARCH_COMPLEXITY as global variable (file: .claude/lib/workflow-state-machine.sh)
- [ ] Serialize RESEARCH_TOPICS to RESEARCH_TOPICS_JSON for state persistence (file: .claude/lib/workflow-state-machine.sh)
- [ ] Add fallback handling: If haiku fails, use regex + heuristic and log warning (file: .claude/lib/workflow-state-machine.sh)
- [ ] Add diagnostic output: Log scope, complexity, and topics after initialization (file: .claude/lib/workflow-state-machine.sh)

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
# Expected: sm_init sets all 3 variables correctly
```

**Expected Duration**: 2 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(678): complete Phase 3 - State Machine Integration`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 4: Update coordinate.md
dependencies: [3]

**Objective**: Remove pattern matching and use state-provided values

**Complexity**: Low

**Tasks**:
- [ ] Save RESEARCH_COMPLEXITY to workflow state in initialization block (file: .claude/commands/coordinate.md:174-177)
- [ ] Save RESEARCH_TOPICS_JSON to workflow state in initialization block (file: .claude/commands/coordinate.md:174-177)
- [ ] Delete pattern matching section entirely (file: .claude/commands/coordinate.md:402-414, DELETE 13 lines)
- [ ] Add comment explaining RESEARCH_COMPLEXITY loaded from state (file: .claude/commands/coordinate.md:402, replace deleted section)
- [ ] Update diagnostic message at line 258 to clarify capacity vs usage (file: .claude/commands/coordinate.md:258)
- [ ] Replace generic topic names with descriptive names from RESEARCH_TOPICS array (file: .claude/commands/coordinate.md:485-490)
- [ ] Add state load for RESEARCH_TOPICS_JSON and reconstruct array (file: .claude/commands/coordinate.md:418-420, new code)

**Testing**:
```bash
# Test coordinate command with comprehensive classification
cd .claude/tests
./test_coordinate_comprehensive.sh
# Expected: 12 test cases for end-to-end coordinate workflow
```

**Expected Duration**: 1.5 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(678): complete Phase 4 - coordinate.md Pattern Matching Removal`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 5: Testing and Documentation
dependencies: [4]

**Objective**: Comprehensive testing and documentation updates

**Complexity**: Medium

**Tasks**:
- [ ] Create comprehensive test suite with 22 test cases (file: .claude/tests/test_comprehensive_classification.sh, new file)
- [ ] Test haiku classification for all workflow types (5 tests)
- [ ] Test complexity determination (1-4 topics, 4 tests)
- [ ] Test subtopic name extraction (3 tests)
- [ ] Test fallback mode when haiku fails (4 tests)
- [ ] Test backward compatibility wrapper detect_workflow_scope() (3 tests)
- [ ] Test coordinate.md integration end-to-end (3 tests)
- [ ] Update coordinate-command-guide.md with comprehensive classification section (file: .claude/docs/guides/coordinate-command-guide.md, add section)
- [ ] Update llm-classification-pattern.md with comprehensive examples (file: .claude/docs/concepts/patterns/llm-classification-pattern.md, add section)
- [ ] Update CLAUDE.md workflow classification description (file: CLAUDE.md, update state_based_orchestration section)

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
# Expected: All tests passing, including 22 new comprehensive classification tests
```

**Expected Duration**: 2 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(678): complete Phase 5 - Testing and Documentation`
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

### Backward Compatibility Testing
- Verify detect_workflow_scope() wrapper works for non-coordinate callers
- Test existing workflows still function correctly
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
3. **Backward compatibility breakage**: Mitigation - maintain detect_workflow_scope() wrapper
4. **State persistence failures**: Mitigation - defensive JSON handling, graceful degradation

### Process Risks
1. **Test coverage gaps**: Mitigation - 22 comprehensive test cases covering all code paths
2. **Documentation drift**: Mitigation - update docs in Phase 5 before completion
3. **Performance regression**: Mitigation - measure latency, validate ≤500ms target

## Rollback Strategy

If comprehensive classification causes issues:
1. Revert coordinate.md:402-414 to original pattern matching (13-line block)
2. Keep Spec 670 haiku integration for WORKFLOW_SCOPE (already proven stable)
3. Comment out RESEARCH_COMPLEXITY export in sm_init()
4. Remove comprehensive classification functions (keep detect_workflow_scope wrapper)

Rollback time estimate: 30 minutes
Rollback validation: Run existing test suite, verify all tests passing

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
- 100% backward compatibility maintained
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
