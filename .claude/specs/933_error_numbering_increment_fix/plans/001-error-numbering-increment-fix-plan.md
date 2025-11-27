# Error Numbering Increment Fix Implementation Plan

## Metadata
- **Date**: 2025-11-23
- **Feature**: Fix topic directory numbering collision bug
- **Scope**: Replace non-atomic topic numbering with collision-safe atomic allocation in shared library
- **Estimated Phases**: 3
- **Estimated Hours**: 3
- **Structure Level**: 0
- **Complexity Score**: 23.0 (fix=3 + tasks:8/2=4 + files:2*3=6 + integrations:2*5=10)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Research Reports**:
  - [Error Numbering Research](../reports/001-error-numbering-research.md)
  - [Numbered Directory Infrastructure Research](../reports/001_numbered_directory_infrastructure.md)

## Overview

The numbered directory infrastructure uses a **three-library system** for topic directory creation:

1. **`topic-utils.sh`** - Basic numbering functions (`get_next_topic_number()`, `get_or_create_topic_number()`) - **deprecated for new code**
2. **`unified-location-detection.sh`** - Atomic allocation via `allocate_and_create_topic()` with file locking and collision detection
3. **`workflow-initialization.sh`** - Orchestration layer via `initialize_workflow_paths()` that all 7 directory-creating commands use

The bug is in `initialize_workflow_paths()` which currently uses the non-atomic `get_or_create_topic_number()` from `topic-utils.sh` (line 477) followed by separate `create_topic_structure()` call (line 569). This two-step pattern creates race conditions and duplicate-numbered directories.

A proper atomic solution already exists in `unified-location-detection.sh` as the `allocate_and_create_topic()` function (lines 247-305), which:
1. Acquires exclusive file lock via `.topic_number.lock`
2. Finds max topic number
3. Checks for collisions with `ls -d "${specs_root}/${topic_number}_"*`
4. Increments until unique
5. Creates directory inside lock
6. Returns pipe-delimited result: `"topic_number|topic_path"`

**The Fix**: Refactor `initialize_workflow_paths()` to use `allocate_and_create_topic()` internally. This ensures all 7 commands (`/plan`, `/research`, `/debug`, `/errors`, `/optimize-claude`, `/setup`, `/repair`) automatically inherit atomic numbering without individual command changes.

## Research Summary

### From Error Numbering Research Report (001-error-numbering-research.md):
- **Root Cause**: `get_next_topic_number()` in `topic-utils.sh:25-41` assumes `max + 1` is unique without verification
- **Evidence**: 3 duplicate-numbered directory pairs found (820, 822, 923)
- **Timeline**: 923_error_analysis_research and 923_subagent_converter_skill_strategy created 25 minutes apart
- **All 7 directory-creating commands** use `initialize_workflow_paths()` which contains the bug

### From Numbered Directory Infrastructure Research Report (001_numbered_directory_infrastructure.md):
- **Three-Library System**: Identified the correct library hierarchy (`topic-utils.sh` -> `unified-location-detection.sh` -> `workflow-initialization.sh`)
- **Standardized Pattern**: `/plan` and `/research` both use the same `initialize_workflow_paths()` function with classification JSON
- **Atomic Function**: `allocate_and_create_topic()` at `unified-location-detection.sh:247-305` provides proper collision detection with file locking
- **Key Insight**: Fix `initialize_workflow_paths()` once, and all 7 commands automatically benefit - NO individual command changes required

Recommended approach based on research: Refactor `initialize_workflow_paths()` in `workflow-initialization.sh` to use `allocate_and_create_topic()` instead of the separate `get_or_create_topic_number()` and `create_topic_structure()` calls.

## Success Criteria
- [ ] No duplicate topic numbers can be created when multiple commands run simultaneously
- [ ] Existing tests in `test_atomic_topic_allocation.sh` continue to pass (13/13 tests)
- [ ] Topic numbering correctly increments past highest existing directory
- [ ] Backward compatibility maintained for all 7 directory-creating commands
- [ ] Test validates collision detection (already exists in test suite)

## Technical Design

### Three-Library System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    topic-utils.sh (DEPRECATED)                  │
│  - get_next_topic_number()      [lines 25-41]                   │
│  - get_or_create_topic_number() [lines 50-65]                   │
│  - validate_topic_name_format() [lines 91-115]                  │
│  - create_topic_structure()     [lines 126-139]                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (deprecated, use instead)
┌─────────────────────────────────────────────────────────────────┐
│              unified-location-detection.sh (ATOMIC)             │
│  - allocate_and_create_topic()  [lines 247-305] ← CORRECT FN    │
│  - get_next_topic_number()      [lines 186-215] (with lock)     │
│  - sanitize_topic_name()        [lines 364-377]                 │
│  - ensure_artifact_directory()  [lines 400-411]                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (calls internally)
┌─────────────────────────────────────────────────────────────────┐
│           workflow-initialization.sh (ORCHESTRATION)            │
│  - initialize_workflow_paths()  [lines 379-810] ← FIX HERE      │
│  - validate_topic_directory_slug() [lines 287-333]              │
│  - Currently calls get_or_create_topic_number() at line 477     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (used by all 7 commands)
┌─────────────────────────────────────────────────────────────────┐
│                   Directory-Creating Commands                   │
│  /plan, /research, /debug, /errors, /optimize-claude,          │
│  /setup, /repair                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Current Architecture (Buggy)

In `workflow-initialization.sh`:
```bash
# Line 477: Non-atomic number calculation
topic_num=$(get_or_create_topic_number "$specs_root" "$topic_name")

# Line 549: Separate path construction (gap where collision can occur)
topic_path="${specs_root}/${topic_num}_${topic_name}"

# Line 569: Separate directory creation
create_topic_structure "$topic_path"
```

**Problem**: These three steps are NOT atomic. Between calculating the number and creating the directory, another process can allocate the same number.

### Target Architecture (Fixed)

In `workflow-initialization.sh`, replace lines 477-569 pattern with:
```bash
# Single atomic call - allocation AND directory creation inside file lock
allocation_result=$(allocate_and_create_topic "$specs_root" "$topic_name")
topic_num="${allocation_result%|*}"
topic_path="${allocation_result#*|}"

# Directory already created inside the lock - no separate create_topic_structure() call needed
```

### allocate_and_create_topic() Implementation (Reference)

From `unified-location-detection.sh:247-305`:
```bash
allocate_and_create_topic() {
  local specs_root="$1"
  local topic_name="$2"

  # Acquire exclusive lock
  (
    flock -x 200

    # Find max topic number
    local max_num topic_number
    max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | ...)
    topic_number=$(printf "%03d" $((10#$max_num + 1)))

    # Collision detection loop (handles rollover and duplicates)
    while ls -d "${specs_root}/${topic_number}_"* 2>/dev/null | grep -q .; do
      topic_number=$(printf "%03d" $(( (10#$topic_number + 1) % 1000 )))
    done

    # Create directory INSIDE lock
    local topic_path="${specs_root}/${topic_number}_${topic_name}"
    mkdir -p "$topic_path"

    # Return pipe-delimited result
    echo "${topic_number}|${topic_path}"

  ) 200>"${specs_root}/.topic_number.lock"
}
```

### Function Sourcing

`allocate_and_create_topic()` is defined in `unified-location-detection.sh` which is already sourced by `workflow-initialization.sh` via the standard three-tier sourcing pattern.

### research-and-revise Mode

The `research-and-revise` workflow scope (lines 507-546) does NOT create new directories - it reuses existing plan's topic directory. This code path should remain unchanged and is NOT affected by this fix.

## Implementation Phases

### Phase 1: Core Fix - Refactor initialize_workflow_paths() [COMPLETE]
dependencies: []

**Objective**: Refactor `initialize_workflow_paths()` in `workflow-initialization.sh` to use the atomic `allocate_and_create_topic()` function from `unified-location-detection.sh`

**Complexity**: Low

**Key Files**:
- `workflow-initialization.sh` (lines 379-810) - `initialize_workflow_paths()` function to modify
- `unified-location-detection.sh` (lines 247-305) - `allocate_and_create_topic()` function to use

Tasks:
- [x] In `workflow-initialization.sh`, locate the non-atomic topic allocation pattern:
  - Line 477: `topic_num=$(get_or_create_topic_number "$specs_root" "$topic_name")`
  - Line 549: `topic_path="${specs_root}/${topic_num}_${topic_name}"`
  - Line 569: `create_topic_structure "$topic_path"`
- [x] Verify `unified-location-detection.sh` is already sourced (check library imports at top of file)
- [x] Replace the three-step pattern with single atomic call:
  ```bash
  # Replace lines 477, 549, 569 pattern with:
  allocation_result=$(allocate_and_create_topic "$specs_root" "$topic_name")
  topic_num="${allocation_result%|*}"
  topic_path="${allocation_result#*|}"
  # No separate create_topic_structure() call needed - directory created atomically
  ```
- [x] Preserve the `research-and-revise` branch (lines 507-546) which reuses existing directories - this code path should NOT be modified
- [x] Ensure exported variables (`TOPIC_PATH`, `TOPIC_NUM`, etc.) are still set correctly for downstream command usage
- [x] Verify idempotent behavior is preserved for exact topic name matches (handled by `allocate_and_create_topic()`)

Testing:
```bash
# Run atomic allocation test suite
bash .claude/tests/topic-naming/test_atomic_topic_allocation.sh
```

**Expected Duration**: 1.5 hours

### Phase 2: Test Verification [COMPLETE]
dependencies: [1]

**Objective**: Verify fix works correctly with existing test infrastructure and add regression test

**Complexity**: Low

Tasks:
- [x] Run full topic-naming test suite to ensure no regressions
- [x] Run atomic topic allocation tests (13 tests for concurrent/collision scenarios)
- [x] Create manual integration test: Run `/errors` and `/plan` simultaneously to verify no collision
- [x] Verify existing duplicate directories (820, 822, 923) don't affect new number calculation
- [x] Add test case for increment-past-duplicates scenario to `test_atomic_topic_allocation.sh`:
  ```bash
  test_increment_past_duplicates() {
    local test_name="Increment past duplicate numbers"
    local test_root="/tmp/test_dups_$$"

    # Setup: simulate existing duplicates like production bug (923_topic_a and 923_topic_b)
    mkdir -p "$test_root/923_topic_a"
    mkdir -p "$test_root/923_topic_b"  # duplicate number!
    mkdir -p "$test_root/924_topic_c"

    # Execute: allocate next topic using atomic function
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh"
    local result
    result=$(allocate_and_create_topic "$test_root" "new_topic")
    local topic_num="${result%|*}"

    # Verify: next topic is 925 (past all duplicates)
    if [ "$topic_num" = "925" ]; then
      pass "$test_name"
    else
      fail "$test_name - Expected 925, got $topic_num"
    fi

    rm -rf "$test_root"
  }
  ```
- [x] Test that all 7 commands (`/plan`, `/research`, `/debug`, `/errors`, `/optimize-claude`, `/setup`, `/repair`) create directories with unique numbers

Testing:
```bash
# Full topic-naming test suite
bash .claude/tests/topic-naming/test_atomic_topic_allocation.sh
bash .claude/tests/topic-naming/test_topic_naming_integration.sh

# Verify all topic-naming tests pass
bash .claude/tests/run_all_tests.sh --filter topic-naming
```

**Expected Duration**: 1 hour

### Phase 3: Documentation and Cleanup [COMPLETE]
dependencies: [1, 2]

**Objective**: Update documentation and mark deprecated functions

**Complexity**: Low

Tasks:
- [x] Update function comment in `workflow-initialization.sh` at the modified code block to document atomic allocation pattern:
  ```bash
  # Uses allocate_and_create_topic() for atomic topic directory creation
  # This prevents race conditions and duplicate topic numbers
  # See unified-location-detection.sh:247-305 for implementation details
  ```
- [x] Mark `get_or_create_topic_number()` in `topic-utils.sh` (lines 50-65) as deprecated:
  ```bash
  # DEPRECATED: Use allocate_and_create_topic() from unified-location-detection.sh instead
  # This function is retained for backward compatibility but should not be used in new code
  ```
- [x] Mark `get_next_topic_number()` in `topic-utils.sh` (lines 25-41) as deprecated with same comment
- [x] Update header comment in `topic-utils.sh` to note atomic allocation preference
- [x] Verify no other code paths call the deprecated functions directly:
  ```bash
  grep -r "get_or_create_topic_number\|get_next_topic_number" .claude/lib/ .claude/commands/ --include="*.sh" --include="*.md"
  ```
- [x] If any other callers found, document them for future cleanup (but do NOT modify in this phase)

Testing:
```bash
# Search for deprecated function usage
grep -r "get_or_create_topic_number\|get_next_topic_number" .claude/lib/ .claude/commands/ --include="*.sh" --include="*.md"

# Verify documentation is updated
grep -A3 "allocate_and_create_topic" .claude/lib/workflow/workflow-initialization.sh
```

**Expected Duration**: 0.5 hours

## Testing Strategy

### Unit Testing
- Existing test suite `test_atomic_topic_allocation.sh` covers:
  - Sequential allocation (000-009)
  - Concurrent allocation (10 parallel, no collisions)
  - Stress test (100 allocations)
  - Lock file creation
  - Empty specs directory first topic
  - Existing directories increment from max
  - Collision detection after rollover
  - Multiple consecutive collisions
  - **NEW**: Increment-past-duplicates scenario (simulating production bug)

### Integration Testing
- Run `/errors --summary` and `/plan "test"` simultaneously in two terminals
- Verify resulting directories have unique numbers
- Verify all 7 directory-creating commands work correctly after fix

### Regression Testing
- Run all topic-naming tests: `bash .claude/tests/run_all_tests.sh --filter topic-naming`
- Verify `initialize_workflow_paths()` still exports correct variables for downstream command usage

## Documentation Requirements

- [ ] Update `topic-utils.sh` header comment to mark deprecated functions
- [ ] Add inline comment at fix location in `workflow-initialization.sh` explaining atomic allocation pattern
- [ ] Document the three-library system hierarchy in code comments

## Dependencies

### Internal (Three-Library System)
- `unified-location-detection.sh` (lines 247-305) - provides atomic `allocate_and_create_topic()` function
- `workflow-initialization.sh` (lines 379-810) - `initialize_workflow_paths()` orchestration function to modify
- `topic-utils.sh` - deprecated functions remain for backward compatibility

### External
- None (all functionality is internal bash)

### Commands Affected (Automatically Fixed)
All 7 commands use `initialize_workflow_paths()` and will automatically benefit from this fix:
1. `/plan` - research-and-plan workflow
2. `/research` - research-only workflow
3. `/debug` - debug workflow
4. `/errors` - error analysis workflow
5. `/optimize-claude` - optimization workflow
6. `/setup` - setup workflow
7. `/repair` - repair workflow

## Risk Assessment

### Low Risk
- **Atomic function already tested**: `allocate_and_create_topic()` has comprehensive test coverage (13 tests)
- **Single-point fix**: Only modifying `initialize_workflow_paths()` in `workflow-initialization.sh` - all 7 commands automatically benefit
- **Backward compatible**: No changes to command interfaces or exported variable names
- **Function already exists**: Using proven atomic function from `unified-location-detection.sh`

### Mitigation
- Run full test suite before and after change
- Test concurrent execution manually to verify fix
- Verify exported variables (`TOPIC_PATH`, `TOPIC_NUM`) remain correct
- Keep deprecated functions in `topic-utils.sh` for any unknown callers
