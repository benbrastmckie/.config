# /coordinate Command Size Tracking

## Target Budget
- **Minimum**: 2,500 lines
- **Maximum**: 3,000 lines
- **Baseline** (/supervise): 2,177 lines

## Size Budget by Phase

| Phase | Description | Expected Change | Running Total |
|-------|-------------|-----------------|---------------|
| 1 | Foundation and Baseline | Baseline + metadata | 2,180 lines |
| 2 | Standards Compliance Fixes | -200 lines (behavioral extraction) | ~1,980 lines |
| 3 | Wave-Based Implementation | +200 lines (wave execution) | ~2,180 lines |
| 4 | Clear Error Handling | -100 lines (remove retry/fallback) | ~2,080 lines |
| 5 | Context Reduction | -50 lines (library references) | ~2,030 lines |
| 6 | Integration Testing | No file changes | ~2,030 lines |
| 7 | Documentation | Header additions only (~20 lines) | ~2,050 lines |

**Final Estimate**: ~2,050 lines (well within 2,500-3,000 target)

## Phase 1 Baseline Metrics

**Date**: 2025-10-27

**Initial Measurements**:
- File: `.claude/commands/coordinate.md`
- Line count: 2,180 lines (copied from /supervise with 3 lines added for metadata)
- Baseline: 2,177 lines (/supervise)
- Added: 3 lines (argument-hint, description, dependent-commands metadata)

**Verification**:
- ✓ File exists and is parseable
- ✓ All /supervise references updated to /coordinate
- ✓ Command description mentions wave-based execution
- ✓ Line count within expected baseline range (2,000-2,500)

**Status**: Phase 1 complete, size budget healthy with ~820-970 lines available for additions
