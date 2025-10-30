# Plan 528: Shim Removal - Analysis and Simplified Approach

## Executive Summary

The original plan (001) was based on outdated research and proposed 28-36 hours of work across 6 phases for what is actually a 1-2 hour task. After comprehensive codebase analysis, a simplified plan (002) has been created that aligns with the project's clean-break, fail-fast philosophy.

## Research Findings (2025-10-29)

### What We Discovered

**Location Libraries** (Already Consolidated):
- unified-location-detection.sh (14,992 bytes) **IS the consolidated library**
- Contains all location detection functions
- Legacy YAML converter already removed (commit 374942c3)
- No consolidation work needed

**Shim Status** (Much Smaller Than Assumed):
- artifact-operations.sh has **22 references** (not 77)
  - 10 source statements in 5 command files
  - 12 references in 7 test files
- 2 commands already migrated (research.md, coordinate.md)
- Real migration: ~12 files to update

**Configuration Architecture** (Different Than Proposed):
- Uses CLAUDE.md sections + environment variables
- No config.json pattern exists in codebase
- Proposed JSON schema doesn't fit existing architecture

**Test Baseline**:
- 58/77 tests passing
- Infrastructure already in place

## Problems with Original Plan (001)

### 1. Overestimated Scope (18x Inflation)
- **Assumed**: 77 references, 6 phases, 28-36 hours, 11 weeks
- **Actual**: 22 references, 1 phase, 1-2 hours, single session
- **Root Cause**: Research counted documentation references as code

### 2. Proposed Redundant Work
- **Phase 3**: Location library consolidation (already complete)
- **Phase 4**: config.json schema (doesn't fit architecture)
- **Phase 1**: Test infrastructure (already exists)

### 3. Violated Clean-Break Philosophy
- 60-day deprecation windows
- Backward compatibility aliases
- 7-14 day verification monitoring
- Rollback archives
- Migration tracking spreadsheets

### 4. Over-Engineering
- 3 batches for 12 files
- Spreadsheet tracking for find-and-replace
- Separate documentation update phase
- Complexity scores for grep operations

## New Approach (002)

### Single Phase Plan

**File**: `002_simplified_shim_removal_plan.md`

**Scope**: Update 22 references, delete shim, done

**Duration**: 1-2 hours

**Philosophy**:
- Clean break: Delete shim immediately after migration
- Fail fast: Bash errors are immediate and obvious
- No backward compatibility
- Git history is the only archive

### Tasks

1. Find all references: `grep -rn "artifact-operations.sh" .claude/`
2. Update 5 command files to use split libraries directly
3. Update 7 test files
4. Run test suite (maintain ≥58/77 baseline)
5. Delete artifact-operations.sh (no archive)
6. Git commit

### What's NOT Included

- No deprecation warnings or compatibility layers
- No verification monitoring periods
- No migration tracking spreadsheets
- No separate documentation phase
- No rollback archives (git history provides this)
- No batched migrations (just update the files)

## CLAUDE.md Update

Added explicit "Clean-Break and Fail-Fast Approach" section to Development Philosophy:

**Clean Break**:
- Delete obsolete code immediately
- No deprecation warnings or transition periods
- Configuration describes what it is, not what it was

**Fail Fast**:
- Missing files produce immediate bash errors
- Tests pass or fail immediately
- Breaking changes break loudly

**Avoid Cruft**:
- No historical commentary
- No backward compatibility layers
- Use git commits, not tracking spreadsheets

## Metrics Comparison

| Aspect | Original Plan (001) | Simplified Plan (002) |
|--------|--------------------|-----------------------|
| Phases | 6 | 1 |
| Estimated Time | 28-36 hours | 1-2 hours |
| Timeline | 11 weeks | 1 session |
| References to Update | 77 (wrong) | 22 (accurate) |
| Files to Modify | 82+ | 12 |
| Backward Compatibility | Extensive | None |
| Verification Windows | 7-14 days | Immediate (test suite) |
| Migration Batches | 3 | 0 (just do it) |
| Rollback Archives | Yes | No (git history) |
| Documentation Phase | Separate | Inline |

## Implementation Recommendation

**Execute**: Plan 002 (simplified approach)

**Archive**: Plan 001 (historical record of over-engineering)

**Rationale**:
- Aligns with clean-break philosophy
- Accurate scope based on codebase analysis
- Economical and efficient
- Fail-fast error handling
- No unnecessary cruft

## Files in This Directory

- `001_create_a_detailed_implementation_plan_to_remove_al_plan.md` - Original 6-phase plan (outdated)
- `001_expanded_phases_archive/` - Expanded phase files (archived)
- `002_simplified_shim_removal_plan.md` - **Recommended plan** (1-2 hours)
- `README.md` - This analysis document

## Next Steps

1. Review simplified plan (002)
2. Execute single phase: Update references → Delete shim → Test → Commit
3. Mark Plan 523 Phases 3-6 as complete
4. Update Plan 519 status (Phase 2 shim creation already complete)

## Lessons Learned

**For Future Planning**:
1. Verify current state before proposing work
2. Count actual code references, not documentation
3. Don't invent infrastructure mid-refactor
4. Follow clean-break philosophy (no compatibility cruft)
5. 12 files don't need enterprise migration patterns
6. Git history IS the archive mechanism

**Red Flags for Over-Engineering**:
- Deprecation windows for internal code
- Migration tracking spreadsheets
- Verification monitoring periods
- Batching trivial updates
- Creating shadow archives
- Separate documentation phases
