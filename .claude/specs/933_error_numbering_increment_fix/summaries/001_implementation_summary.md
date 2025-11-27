# Error Numbering Increment Fix - Implementation Summary

## Work Status
Completion: 3/3 phases (100%)

## Overview

This implementation fixes the topic directory numbering collision bug (Spec 933) by refactoring `initialize_workflow_paths()` in `workflow-initialization.sh` to use the atomic `allocate_and_create_topic()` function from `unified-location-detection.sh`.

## Problem Statement

The numbered directory infrastructure used a non-atomic three-step pattern that caused race conditions:
1. `get_or_create_topic_number()` - Calculate topic number (released lock)
2. Path construction (gap where collision could occur)
3. `create_topic_structure()` - Create directory

This resulted in duplicate-numbered directories (820, 822, 923) when concurrent workflows allocated topics.

## Solution Implemented

Replaced the three-step pattern with a single atomic call:
```bash
allocation_result=$(allocate_and_create_topic "$specs_root" "$topic_name")
topic_num="${allocation_result%|*}"
topic_path="${allocation_result#*|}"
```

The `allocate_and_create_topic()` function holds exclusive file lock through BOTH number calculation AND directory creation, eliminating race conditions.

## Completed Phases

### Phase 1: Core Fix - Refactor initialize_workflow_paths() [COMPLETE]
- Added sourcing of `unified-location-detection.sh` for `allocate_and_create_topic()` function
- Replaced non-atomic pattern at lines 477, 549, 569 with atomic allocation
- Preserved `research-and-revise` branch (reuses existing directories, no new allocation needed)
- Preserved idempotent behavior for exact topic name matches
- Maintained exported variable compatibility (`TOPIC_PATH`, `TOPIC_NUM`, etc.)

### Phase 2: Test Verification [COMPLETE]
- All 13 existing atomic allocation tests pass
- Added new Test 14: "Increment past duplicate numbers (Spec 933 bug)"
  - Simulates production bug scenario (923_topic_a and 923_topic_b)
  - Verifies next allocation is 925 (past all duplicates)
- Full topic-naming test suite validated (integration, fallback, filename generation)

### Phase 3: Documentation and Cleanup [COMPLETE]
- Updated `topic-utils.sh` header with deprecation notice
- Added deprecation comments to `get_next_topic_number()` function
- Added deprecation comments to `get_or_create_topic_number()` function
- Documented other callers for future cleanup:
  - `template-integration.sh` - Contains separate local implementation (not sourced)
  - Test files - Check function existence only (infrastructure testing)

## Files Modified

1. **`.claude/lib/workflow/workflow-initialization.sh`**
   - Added sourcing of `unified-location-detection.sh`
   - Replaced non-atomic topic allocation with atomic `allocate_and_create_topic()` call
   - Updated diagnostic messages to reference atomic function
   - Removed unreachable dead code block

2. **`.claude/lib/plan/topic-utils.sh`**
   - Added file-level deprecation notice
   - Added function-level deprecation comments to:
     - `get_next_topic_number()`
     - `get_or_create_topic_number()`

3. **`.claude/tests/topic-naming/test_atomic_topic_allocation.sh`**
   - Added Test 14: `test_increment_past_duplicates()`
   - Updated `run_all_tests()` to include new test

## Test Results

```
=== Atomic Topic Allocation Test Suite ===
PASS: Sequential allocation (000-009)
PASS: Concurrent allocation (10 parallel, no collisions)
PASS: Stress test (100 allocations, 10 parallel) (0% collision rate)
PASS: Lock file creation
PASS: Empty specs directory (first topic = 000)
PASS: Existing directories (increment from max)
PASS: Topic path format (NNN_name)
PASS: Return format (number|path)
PASS: Directory creation verification
PASS: Concurrent first allocation (race for 000)
PASS: Rollover from 999 to 000
PASS: Collision detection after rollover
PASS: Multiple consecutive collisions
PASS: Increment past duplicate numbers (Spec 933 bug)

=== Test Summary ===
Passed: 14
Failed: 0
```

## Commands Automatically Fixed

All 7 directory-creating commands now use atomic allocation via `initialize_workflow_paths()`:
1. `/plan` - research-and-plan workflow
2. `/research` - research-only workflow
3. `/debug` - debug workflow
4. `/errors` - error analysis workflow
5. `/optimize-claude` - optimization workflow
6. `/setup` - setup workflow
7. `/repair` - repair workflow

## Remaining Work

None - all phases complete.

## Future Cleanup (Not in Scope)

- `template-integration.sh` has its own local implementation of `get_next_topic_number()` and `get_or_create_topic_dir()` - should be migrated to use atomic function in separate refactoring effort

## References

- Research Report: `.claude/specs/933_error_numbering_increment_fix/reports/001-error-numbering-research.md`
- Infrastructure Report: `.claude/specs/933_error_numbering_increment_fix/reports/001_numbered_directory_infrastructure.md`
- Plan: `.claude/specs/933_error_numbering_increment_fix/plans/001-error-numbering-increment-fix-plan.md`
