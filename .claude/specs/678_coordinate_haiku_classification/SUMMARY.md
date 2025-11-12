# Spec 678: Comprehensive Haiku-Based Workflow Classification - Summary

## Quick Links

- **Research Report**: [reports/001_current_state_analysis.md](reports/001_current_state_analysis.md)
- **Implementation Plan**: [plans/001_comprehensive_classification_implementation.md](plans/001_comprehensive_classification_implementation.md)

## Executive Summary

This specification addresses two issues in the `/coordinate` command:

1. **Issue 676 Diagnostic Confusion**: "Saved 4 report paths" message when only 2 are used
2. **Spec 670 Incomplete Integration**: Haiku model determines WORKFLOW_SCOPE but not RESEARCH_COMPLEXITY

**Root Cause**: Spec 670 successfully integrated haiku for scope detection but left complexity calculation using pattern matching (coordinate.md:402-414).

**Solution**: Extend haiku integration to provide comprehensive classification in a single call:
- workflow_type (scope) 
- research_complexity (1-4)
- subtopics array (descriptive names)

## Key Findings from Research

### Issue 676: Not a Bug

The "4 vs 2 report paths" discrepancy is **architecturally correct**:
- Phase 0 pre-allocates 4 paths for performance (85% token reduction)
- Phase 1 only uses RESEARCH_COMPLEXITY paths (typically 2)
- **Problem**: Misleading diagnostic message
- **Fix**: Update message to clarify "capacity: 4, will use: 2"

### Issue 670: Intentionally Scoped

Spec 670 integration is **complete for its scope** but doesn't cover:
- Research complexity calculation
- Subtopic identification
- Comprehensive classification

This was by design (incremental deployment), not an oversight.

### Pattern Matching Still Exists

**Location**: `coordinate.md` lines 402-414

```bash
# Current pattern matching (to be deleted):
RESEARCH_COMPLEXITY=2

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|refactor"; then
  RESEARCH_COMPLEXITY=3
fi
# ... more patterns ...
```

**Problem**: Same false-positive vulnerability that Spec 670 fixed for scope detection.

**Example Failure**:
```
Input: "research the refactor command"
Pattern: RESEARCH_COMPLEXITY=3 (FALSE - matches "refactor")
Expected: RESEARCH_COMPLEXITY=1 (simple research, not refactoring)
```

## Implementation Plan Overview

### Scope

**Files to Modify** (5 files, ~110 lines total):
1. `.claude/lib/workflow-llm-classifier.sh` - Enhance prompt + parsing (+30/-10)
2. `.claude/lib/workflow-scope-detection.sh` - Add comprehensive function (+50/-20)
3. `.claude/commands/coordinate.md` - Delete pattern matching, fix diagnostic (+30/-23)

**New Functions** (3):
1. `classify_workflow_comprehensive()` - Returns JSON with all dimensions
2. `fallback_comprehensive_classification()` - Regex + heuristic fallback
3. `infer_complexity_from_keywords()` - Heuristic complexity (moves existing patterns)

**Testing**: 22 test cases across 4 test files

### Phase Breakdown

| Phase | Objective | Effort | Key Deliverable |
|-------|-----------|--------|-----------------|
| 1 | Enhance haiku classifier | 2h | Extended JSON schema in classifier |
| 2 | Add comprehensive function | 2.5h | classify_workflow_comprehensive() |
| 3 | Integrate with state machine | 2h | sm_init() extracts all fields |
| 4 | Update coordinate.md | 1.5h | Pattern matching deleted |
| 5 | Testing & documentation | 2h | 22/22 tests passing |

**Total**: 8-10 hours

### Key Benefits

1. **Single Haiku Call**: Replaces scope detection + complexity calculation with one operation
2. **Zero Pattern Matching**: Complete elimination of grep-based classification
3. **Descriptive Topics**: "Authentication patterns" instead of "Topic 1"
4. **Backward Compatible**: Existing callers continue to work
5. **Better Accuracy**: LLM semantic understanding vs keyword matching

## Architecture Changes

### Before (Current)

```
Initialization:
  sm_init() → haiku determines WORKFLOW_SCOPE
Research Phase:
  Pattern matching determines RESEARCH_COMPLEXITY
  Generic topic names ("Topic 1", "Topic 2")
```

### After (Proposed)

```
Initialization:
  sm_init() → haiku determines ALL:
    - WORKFLOW_SCOPE
    - RESEARCH_COMPLEXITY  
    - RESEARCH_TOPICS (descriptive array)
Research Phase:
  Load from state (no pattern matching)
  Use descriptive topic names from haiku
```

## Haiku Integration Example

### Request
```json
{
  "workflow_description": "research auth patterns and create plan",
  "classification_type": "full",
  "determine_workflow_type": true,
  "determine_research_complexity": true,
  "identify_subtopics": true
}
```

### Response
```json
{
  "workflow_type": "research-and-plan",
  "research_complexity": 2,
  "subtopics": [
    "Authentication patterns in existing codebase",
    "Security best practices for auth implementation"
  ],
  "confidence": 0.92,
  "reasoning": "User wants to research auth (2 topics) then create plan"
}
```

### State Machine Integration
```bash
# sm_init() extracts:
WORKFLOW_SCOPE="research-and-plan"
RESEARCH_COMPLEXITY=2
RESEARCH_TOPICS=(
  "Authentication patterns in existing codebase"
  "Security best practices for auth implementation"
)
```

## Success Criteria (10 metrics)

- [ ] Zero pattern matching for classification
- [ ] Haiku returns comprehensive JSON
- [ ] RESEARCH_COMPLEXITY set by sm_init()
- [ ] Descriptive subtopic names in prompts
- [ ] Diagnostic message clarified (Issue 676)
- [ ] All 22 test cases passing
- [ ] Backward compatibility maintained
- [ ] Performance: ≤500ms single call
- [ ] Fallback mode working
- [ ] Documentation updated (3 files)

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Haiku latency variable | Medium | Low | 10s timeout with fallback |
| JSON schema drift | Low | Medium | Strict validation with jq |
| Backward compat break | Low | High | Wrapper function maintained |
| State persistence fail | Low | Medium | Defensive JSON handling |

## Rollback Strategy

If issues arise:
1. Revert coordinate.md pattern matching (13 lines)
2. Keep Spec 670 scope detection (proven stable)
3. Comment out new exports
4. Remove comprehensive functions

**Rollback time**: 30 minutes

## Performance Expectations

**Current** (Spec 670 + pattern matching):
- Haiku call for scope: ~400ms
- Pattern matching: ~5ms
- Total: ~405ms

**Proposed** (comprehensive):
- Single haiku call: ~450-500ms
- Pattern matching: 0ms
- Total: ~450-500ms

**Net**: ~10-20% slower but eliminates false positives and provides descriptive topics

## Next Steps

1. **Review Plan**: Read [implementation plan](plans/001_comprehensive_classification_implementation.md) in detail
2. **Approve Scope**: Confirm 5-phase approach is acceptable
3. **Execute**: Run `/implement plans/001_comprehensive_classification_implementation.md`
4. **Verify**: Test with actual workflows to validate haiku classification accuracy

## Questions for Review

1. **Scope**: Is 8-10 hour effort acceptable for this enhancement?
2. **Backward Compatibility**: Should we maintain detect_workflow_scope() wrapper permanently or deprecate eventually?
3. **Fallback Strategy**: Is regex + heuristic fallback acceptable or should we fail fast when haiku unavailable?
4. **Performance**: Is ~50ms additional latency acceptable for descriptive topics and better accuracy?
5. **Testing**: Are 22 test cases sufficient or should we add more edge case coverage?

---

**Status**: Ready for implementation
**Estimated Start**: Immediate (all research complete)
**Estimated Completion**: 1-2 days (depends on testing thoroughness)
