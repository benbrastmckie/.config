# Spec 678 Plan Revision: Phase 0 and Concurrent Execution Improvements

## What Changed

The implementation plan has been **revised and extended** to address three additional issues discovered during user review:

### New Issues Addressed

1. **Phase 0 Pre-Allocation Tension** (Architectural Improvement)
   - **Problem**: Hardcoded 4-path allocation regardless of RESEARCH_COMPLEXITY
   - **Impact**: Creates "4 vs 2" diagnostic confusion, exports 2-3 unused variables per workflow
   - **Solution**: Haiku-first classification enables dynamic allocation (1-4 paths exactly)

2. **Concurrent Execution Vulnerability** (Critical Bug)
   - **Problem**: Fixed filename `coordinate_workflow_desc.txt` can be overwritten
   - **Impact**: Multiple /coordinate commands in same repo race condition
   - **Solution**: WORKFLOW_ID-based filename prevents conflicts

3. **Workflow Capture Performance** (Performance Issue)
   - **Problem**: Part 1 takes 45 seconds and 2.5k tokens for simple file write
   - **Impact**: Slow initialization, unnecessary token consumption
   - **Investigation**: Root cause identified (Claude Code routing), optimization opportunities documented

## Plan Changes Summary

### Metadata Updates
- **Phases**: 5 → 6 (added Phase 3 for dynamic allocation)
- **Estimated Hours**: 8-10 → 10-13 hours
- **Complexity Score**: 45.0 → 52.0
- **New Research Report**: 002_phase0_and_capture_improvements.md

### New Success Criteria (2 added)
- [x] Zero hardcoded path counts - dynamic allocation matches RESEARCH_COMPLEXITY exactly
- [x] Concurrent execution safe - WORKFLOW_ID-based temp filenames prevent overwrites

### Architecture Changes

**Before** (Original Plan):
```
sm_init() determines WORKFLOW_SCOPE and RESEARCH_COMPLEXITY
  ↓
workflow-initialization.sh allocates 4 paths (hardcoded)
  ↓
coordinate.md uses 2 paths (creates confusion)
```

**After** (Revised Plan):
```
sm_init() determines WORKFLOW_SCOPE and RESEARCH_COMPLEXITY
  ↓ returns RESEARCH_COMPLEXITY
workflow-initialization.sh(RESEARCH_COMPLEXITY) allocates exact count
  ↓
coordinate.md uses all allocated paths (perfect match)
```

### New Phases Added/Modified

**Phase 1**: Enhanced
- Add sm_init() return value (RESEARCH_COMPLEXITY)
- Export complexity for path allocation

**Phase 2**: Enhanced  
- Add comprehensive classification integration

**Phase 3**: **NEW** - Dynamic Path Allocation
- Modify workflow-initialization.sh to accept RESEARCH_COMPLEXITY parameter
- Remove hardcoded REPORT_PATHS_COUNT=4
- Implement dynamic for-loop allocation (1 to $RESEARCH_COMPLEXITY)

**Phase 4**: **NEW** - Fix Concurrent Execution
- Replace fixed filename with WORKFLOW_ID-based
- Add cleanup logic (delete temp file after reading)
- Test concurrent /coordinate invocations

**Phase 5-6**: Renumbered from original Phases 4-5

## Files Modified (3 new)

**Original Plan** (5 files):
1. workflow-llm-classifier.sh
2. workflow-scope-detection.sh
3. coordinate.md (pattern matching removal)
4. Test files
5. Documentation

**Revised Plan** (+3 files = 8 total):
6. workflow-state-machine.sh (sm_init returns RESEARCH_COMPLEXITY)
7. workflow-initialization.sh (dynamic allocation)
8. coordinate.md (temp file fix - separate from pattern matching)

## Effort Impact

| Aspect | Original | Revised | Delta |
|--------|----------|---------|-------|
| **Phases** | 5 | 6 | +1 |
| **Estimated Hours** | 8-10h | 10-13h | +2-3h |
| **Files Modified** | 5 | 8 | +3 |
| **Test Cases** | 22 | 25+ | +3+ |
| **Complexity Score** | 45.0 | 52.0 | +7.0 |

Additional effort is primarily from:
- Phase 3: Dynamic path allocation implementation (1.5h)
- Phase 4: Concurrent execution fix and testing (1h)
- Additional test cases for new functionality (0.5h)

## Key Benefits of Revision

### 1. Eliminates Architectural Tension Entirely
**Before**: "We accept 2-3 unused variables per workflow as acceptable overhead"  
**After**: Zero unused variables, perfect capacity/usage match

### 2. Enables True Concurrent Execution
**Before**: Running 2 /coordinate commands simultaneously causes race condition  
**After**: Each workflow has unique temp file, fully concurrent-safe

### 3. Cleaner Diagnostics
**Before**: "Saved 4 report paths" when only 2 used (confusing)  
**After**: "Allocated 2 report paths" matching actual usage (clear)

### 4. Better Architecture
**Before**: Allocate capacity, hope it matches usage  
**After**: Determine requirements first, allocate exactly

## Backward Compatibility

**Maintained**:
- detect_workflow_scope() wrapper still works
- All existing callers continue to function
- State file format unchanged (REPORT_PATHS_COUNT still exported)

**New Capability**:
- RESEARCH_COMPLEXITY now available earlier in workflow
- Can be used for other optimization decisions

## Testing Additions

**New Test Cases** (3+):
1. Concurrent execution test (2 /coordinate commands simultaneously)
2. Dynamic allocation test (verify 1, 2, 3, 4 paths allocated correctly)
3. WORKFLOW_ID uniqueness test (verify temp filenames don't collide)

**Enhanced Test Cases**:
- Phase 0 optimization tests now verify dynamic allocation
- State persistence tests verify RESEARCH_COMPLEXITY early availability

## Documentation Updates

**New Sections** (4 locations):
1. **coordinate-command-guide.md**: Add "Haiku-First Classification" section
2. **phase-0-optimization.md**: Update with dynamic allocation pattern
3. **bash-block-execution-model.md**: Add WORKFLOW_ID-based temp file pattern
4. **CLAUDE.md**: Update Phase 0 description to reflect dynamic allocation

## Migration Notes

### For Existing Workflows
- **No changes required**: Existing workflows continue to work
- **Benefit**: Future workflows automatically use improved architecture

### For Developers
- **workflow-initialization.sh callers**: Must pass RESEARCH_COMPLEXITY parameter
- **sm_init() callers**: Can now use returned RESEARCH_COMPLEXITY value
- **Backward compatibility**: Default behavior maintained if parameter omitted

## Risks and Mitigations

| Risk | Probability | Mitigation |
|------|-------------|------------|
| Dynamic allocation bugs | Low | Comprehensive testing (25+ cases) |
| Breaking existing callers | Very Low | Default parameters maintain compatibility |
| Concurrent execution edge cases | Low | Atomic file operations, unique WORKFLOW_ID |
| Performance regression | Very Low | Dynamic allocation faster (fewer exports) |

## Next Steps

1. **Review Revised Plan**: Read updated plan at `plans/001_comprehensive_classification_implementation.md`
2. **Review Research Report**: Read `reports/002_phase0_and_capture_improvements.md` for detailed analysis
3. **Approve Changes**: Confirm 10-13 hour estimate and 6-phase approach acceptable
4. **Execute Implementation**: Run `/implement plans/001_comprehensive_classification_implementation.md`

## Questions for Review

1. **Scope Expansion OK?**: Original 8-10h → Revised 10-13h acceptable?
2. **Dynamic Allocation Priority**: Should this be implemented now or deferred to separate spec?
3. **Concurrent Execution**: Is WORKFLOW_ID-based approach preferred over JJJ auto-increment?
4. **Performance Investigation**: Should we investigate Part 1 slowness further or accept as Claude Code limitation?

---

**Revision Date**: 2025-11-12  
**Original Plan**: 001_comprehensive_classification_implementation.md (Revision 0)  
**Revised Plan**: 001_comprehensive_classification_implementation.md (Revision 1)  
**Research Reports Used**: 001, 002  
**Status**: Ready for implementation
