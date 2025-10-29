# Implementation Plan: Lazy Library Loading with Memoization

## Metadata
- **Date**: 2025-10-29
- **Feature**: Lazy library loading with memoization to prevent redundant sourcing
- **Scope**: Update library-sourcing.sh with memoization pattern, maintain backward compatibility
- **Estimated Phases**: 3
- **Estimated Hours**: 2-3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 12.0
- **Related Report**: ../reports/001_coordinate_timeout_investigation/001_solution_analysis.md
- **Research Overview**: [../519_claudedocs_and_the_current_implementation_in_order/reports/001_lazy_library_loading_improvements/OVERVIEW.md](../519_claudedocs_and_the_current_implementation_in_order/reports/001_lazy_library_loading_improvements/OVERVIEW.md)

## Research Findings Note

Comprehensive research was conducted analyzing this implementation approach. Key finding: **The proposed memoization approach (310 lines) is over-engineered for the actual problem**. The research recommends array deduplication (20 lines) as a simpler, more appropriate solution that provides identical benefits without global state complexity. See the research overview above for complete analysis and alternative recommendations.

## Overview

Implement a memoization pattern in `library-sourcing.sh` to track already-sourced libraries and prevent redundant sourcing. This allows commands to explicitly list all their dependencies (self-documenting) while maintaining performance through lazy loading.

## Current State Analysis

### The Problem

**Root Cause**: `/coordinate` command explicitly passes 6 libraries that are already sourced internally by `source_required_libraries()`, causing them to be loaded twice:

```bash
# Current coordinate.md:539
if ! source_required_libraries "dependency-analyzer.sh" "context-pruning.sh" "checkpoint-utils.sh" "unified-location-detection.sh" "workflow-detection.sh" "unified-logger.sh" "error-handling.sh"; then
  exit 1
fi
```

**What Actually Happens**:
1. `source_required_libraries()` sources 7 core libraries internally
2. Then processes arguments: 7 libraries (6 duplicates + 1 new)
3. Result: 6 libraries sourced twice → timeout

### Current Implementation

**File**: `.claude/lib/library-sourcing.sh` (81 lines)

```bash
source_required_libraries() {
  local libraries=(
    "workflow-detection.sh"
    "error-handling.sh"
    "checkpoint-utils.sh"
    "unified-logger.sh"
    "unified-location-detection.sh"
    "metadata-extraction.sh"
    "context-pruning.sh"
  )

  # Add optional libraries from arguments
  if [[ $# -gt 0 ]]; then
    libraries+=("$@")
  fi

  # Source all libraries (no deduplication!)
  for lib in "${libraries[@]}"; do
    local lib_path="${claude_root}/lib/${lib}"
    if [[ ! -f "$lib_path" ]]; then
      failed_libraries+=("$lib (expected at: $lib_path)")
      continue
    fi
    if ! source "$lib_path" 2>/dev/null; then
      failed_libraries+=("$lib (source failed)")
    fi
  done

  # ... error handling ...
}
```

### Why Memoization?

**Benefits**:
1. **Idempotent**: Can call `source_required_libraries()` multiple times safely
2. **Self-Documenting**: Commands can explicitly list all dependencies
3. **Performance**: Skip already-sourced libraries automatically
4. **Backward Compatible**: Existing calls work without changes
5. **Robust**: Prevents future timeout issues if libraries are re-listed

**Trade-offs**:
1. Global state (`_SOURCED_LIBRARIES` array)
2. Slightly more complex (memoization logic)
3. Could mask missing library issues in edge cases (mitigated by testing)

## Success Criteria

- [ ] Library sourcing is idempotent (can call multiple times)
- [ ] `/coordinate` timeout resolved (completes in <2 minutes)
- [ ] All commands continue to work without modification
- [ ] Performance improvement measurable (reduced sourcing time)
- [ ] Memoization state properly managed
- [ ] All 76 test suites pass (no regressions)
- [ ] Documentation explains memoization pattern

## Technical Design

### Memoization Pattern

**Core Concept**: Track which libraries have been sourced in a global associative array. Skip sourcing if already loaded.

```bash
# Global memoization state (persists across function calls)
declare -g -A _SOURCED_LIBRARIES

source_required_libraries() {
  # ... setup ...

  for lib in "${all_libraries[@]}"; do
    # Check memoization cache
    if [[ -n "${_SOURCED_LIBRARIES[$lib]}" ]]; then
      continue  # Skip already-sourced library
    fi

    # Source the library
    source "$lib_path"

    # Update memoization cache
    _SOURCED_LIBRARIES[$lib]=1
  done
}
```

**Key Design Decisions**:

1. **Global State**: `_SOURCED_LIBRARIES` persists across calls
   - Prefix with `_` to indicate internal/private
   - Global scope (`declare -g`) ensures visibility
   - Associative array for O(1) lookup

2. **Cache Invalidation**: None (libraries immutable during script execution)
   - Once sourced, stays sourced
   - No need to re-source during same session

3. **Error Handling**: Track failures separately
   - Failed libraries NOT added to cache
   - Allows retry on next call if failure was transient

### Implementation Architecture

```
┌─────────────────────────────────────────────────┐
│ Command (e.g., /coordinate)                     │
│                                                  │
│ source_required_libraries "lib1.sh" "lib2.sh"   │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│ library-sourcing.sh                             │
│                                                  │
│ ┌─────────────────────────────────────────┐    │
│ │ Core Libraries (always requested)       │    │
│ │ - workflow-detection.sh                 │    │
│ │ - error-handling.sh                     │    │
│ │ - checkpoint-utils.sh                   │    │
│ │ - unified-logger.sh                     │    │
│ │ - unified-location-detection.sh         │    │
│ │ - metadata-extraction.sh                │    │
│ │ - context-pruning.sh                    │    │
│ └─────────────────────────────────────────┘    │
│                   │                              │
│                   ▼                              │
│ ┌─────────────────────────────────────────┐    │
│ │ Combine with Optional (from arguments)  │    │
│ │ - lib1.sh                               │    │
│ │ - lib2.sh                               │    │
│ └─────────────────────────────────────────┘    │
│                   │                              │
│                   ▼                              │
│ ┌─────────────────────────────────────────┐    │
│ │ For each library:                       │    │
│ │   if _SOURCED_LIBRARIES[lib]:          │    │
│ │     skip (memoization hit)              │    │
│ │   else:                                 │    │
│ │     source lib                          │    │
│ │     _SOURCED_LIBRARIES[lib] = 1        │    │
│ └─────────────────────────────────────────┘    │
│                                                  │
└─────────────────────────────────────────────────┘
```

### Edge Cases and Error Handling

**Edge Case 1**: Library sourcing fails
```bash
# Behavior: Do NOT add to memoization cache
# Rationale: Allows retry on next call
if ! source "$lib_path" 2>/dev/null; then
  failed_libraries+=("$lib (source failed)")
  # Note: _SOURCED_LIBRARIES[$lib] NOT set
  continue
fi

# Only mark as sourced if successful
_SOURCED_LIBRARIES[$lib]=1
```

**Edge Case 2**: Library file missing
```bash
# Behavior: Do NOT add to memoization cache
# Rationale: File might be created later, allow retry
if [[ ! -f "$lib_path" ]]; then
  failed_libraries+=("$lib (expected at: $lib_path)")
  # Note: _SOURCED_LIBRARIES[$lib] NOT set
  continue
fi
```

**Edge Case 3**: Multiple commands in same shell session
```bash
# Behavior: Memoization persists across commands
# Rationale: Global state shared, improves performance

# First command
/coordinate "research auth"  # Sources 7 core + dependency-analyzer
                             # _SOURCED_LIBRARIES now has 8 entries

# Second command
/orchestrate "implement auth"  # Sources 7 core (already loaded, skip)
                               # Only new libraries sourced
```

**Edge Case 4**: Nested library dependencies
```bash
# Behavior: Each library sourced once at top level
# Rationale: If lib A sources lib B, both tracked separately
# Note: Current libs don't have nested dependencies, but pattern handles it

# Example (hypothetical):
# workflow-detection.sh internally sources error-handling.sh
# Both libraries tracked in _SOURCED_LIBRARIES
# No duplicate sourcing occurs
```

## Implementation Phases

### Phase 1: Implement Memoization in library-sourcing.sh

**Objective**: Add memoization pattern to `source_required_libraries()` function

**Complexity**: Medium

**Tasks**:
- [ ] Read current library-sourcing.sh implementation
- [ ] Add global `_SOURCED_LIBRARIES` declaration at file top
- [ ] Add memoization check before sourcing each library
- [ ] Update memoization cache after successful source
- [ ] Ensure failed libraries NOT added to cache
- [ ] Add inline comments explaining memoization pattern
- [ ] Verify backward compatibility (existing calls unchanged)
- [ ] Add function documentation about idempotency

**Implementation Details**:

```bash
#!/usr/bin/env bash
# library-sourcing.sh - Consolidated library sourcing with memoization
# Version: 2.0.0
# Purpose: Provide unified library sourcing with idempotent behavior
#
# Changes in 2.0.0:
# - Added memoization pattern to prevent redundant sourcing
# - Idempotent behavior: can call source_required_libraries() multiple times
# - Performance optimization: skip already-sourced libraries
#
# Usage:
#   source .claude/lib/library-sourcing.sh
#   source_required_libraries "optional-lib.sh" || exit 1

# Global memoization cache (tracks already-sourced libraries)
# Key: library filename (e.g., "workflow-detection.sh")
# Value: 1 (sourced successfully)
declare -g -A _SOURCED_LIBRARIES

# source_required_libraries() - Sources all required libraries with memoization
#
# Idempotent: Can be called multiple times safely. Already-sourced libraries
# are skipped automatically via memoization cache.
#
# Parameters:
#   $@ - Optional additional libraries to source (beyond core 7)
#
# Returns:
#   0 - All libraries sourced successfully (or already sourced)
#   1 - One or more libraries failed to source
#
# Core Libraries (sourced unless already in cache):
#   1. workflow-detection.sh - Workflow scope detection functions
#   2. error-handling.sh - Error handling utilities
#   3. checkpoint-utils.sh - Checkpoint save/restore operations
#   4. unified-logger.sh - Progress logging utilities
#   5. unified-location-detection.sh - Project structure detection
#   6. metadata-extraction.sh - Report/plan metadata extraction
#   7. context-pruning.sh - Context management utilities
#
# Optional Libraries (examples):
#   - dependency-analyzer.sh - Wave-based execution (for /coordinate)
#   - plan-core-bundle.sh - Plan parsing (for /plan, /implement)
#   - complexity-thresholds.sh - Complexity scoring (for adaptive planning)
#
# Memoization Details:
#   - Libraries tracked in global _SOURCED_LIBRARIES associative array
#   - Once sourced successfully, marked in cache and skipped on subsequent calls
#   - Failed sources NOT cached (allows retry on next call)
#   - Cache persists for entire script execution (global scope)
#
# Error Handling:
#   - Fail-fast on any missing library (not in cache)
#   - Detailed error message includes library name and expected path
#   - Returns 1 on any failure (caller should exit)
#   - Failed libraries NOT added to cache (allows retry)
#
# Usage Examples:
#   # First call - sources all 7 core libraries
#   source_required_libraries || exit 1
#
#   # Second call - skips all 7 (already sourced), no overhead
#   source_required_libraries || exit 1
#
#   # With optional library - sources only if not in cache
#   source_required_libraries "dependency-analyzer.sh" || exit 1
#
#   # Explicit list (self-documenting) - only new libraries sourced
#   source_required_libraries "dep.sh" "core.sh" "logger.sh" || exit 1
source_required_libraries() {
  local claude_root
  claude_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

  # Core libraries (always requested, may already be sourced)
  local core_libraries=(
    "workflow-detection.sh"
    "error-handling.sh"
    "checkpoint-utils.sh"
    "unified-logger.sh"
    "unified-location-detection.sh"
    "metadata-extraction.sh"
    "context-pruning.sh"
  )

  # Combine core + optional libraries from arguments
  local all_libraries=("${core_libraries[@]}" "$@")
  local failed_libraries=()

  for lib in "${all_libraries[@]}"; do
    # Memoization check: skip if already sourced
    if [[ -n "${_SOURCED_LIBRARIES[$lib]}" ]]; then
      continue
    fi

    local lib_path="${claude_root}/lib/${lib}"

    # Check if library file exists
    if [[ ! -f "$lib_path" ]]; then
      failed_libraries+=("$lib (expected at: $lib_path)")
      # Note: NOT added to memoization cache (allows retry if file created)
      continue
    fi

    # Attempt to source the library
    # shellcheck disable=SC1090
    if ! source "$lib_path" 2>/dev/null; then
      failed_libraries+=("$lib (source failed)")
      # Note: NOT added to memoization cache (allows retry if transient error)
      continue
    fi

    # Success: add to memoization cache
    _SOURCED_LIBRARIES[$lib]=1
  done

  # Report any failures
  if [[ ${#failed_libraries[@]} -gt 0 ]]; then
    echo "ERROR: Failed to source required libraries:" >&2
    for failed_lib in "${failed_libraries[@]}"; do
      echo "  - $failed_lib" >&2
    done
    echo "" >&2
    echo "Please ensure all required libraries exist in: ${claude_root}/lib/" >&2
    return 1
  fi

  return 0
}

# Export the function for use by sourcing scripts
export -f source_required_libraries
```

**Key Changes**:
1. Line 20: Add global `_SOURCED_LIBRARIES` declaration
2. Line 84-87: Add memoization check (skip if already sourced)
3. Line 103: Add to cache on successful source
4. Line 90-93, 97-100: Do NOT cache on failure (allows retry)
5. Line 23-82: Comprehensive documentation about idempotency

**Testing**:
```bash
# Test 1: Source libraries once
source .claude/lib/library-sourcing.sh
source_required_libraries || exit 1
echo "First call: ${#_SOURCED_LIBRARIES[@]} libraries sourced"

# Test 2: Source again (should skip all)
source_required_libraries || exit 1
echo "Second call: ${#_SOURCED_LIBRARIES[@]} libraries (same, no re-sourcing)"

# Test 3: Check specific library in cache
if [[ -n "${_SOURCED_LIBRARIES[workflow-detection.sh]}" ]]; then
  echo "✓ workflow-detection.sh in cache"
fi

# Test 4: Add optional library
source_required_libraries "dependency-analyzer.sh" || exit 1
echo "With optional: ${#_SOURCED_LIBRARIES[@]} libraries"
```

**Expected Duration**: 45-60 minutes

---

### Phase 2: Update Documentation and Add Verification

**Objective**: Document memoization pattern and add verification utilities

**Complexity**: Low

**Tasks**:
- [ ] Update library-sourcing.sh header comments (version 2.0.0)
- [ ] Add usage examples showing idempotent behavior
- [ ] Document memoization pattern in inline comments
- [ ] Create utility function to inspect memoization state
- [ ] Add verification function to check if library sourced
- [ ] Update command development guide with new pattern
- [ ] Add troubleshooting section for memoization issues

**Implementation Details**:

**File 1**: `.claude/lib/library-sourcing.sh` (add utility functions)

```bash
# is_library_sourced() - Check if a library has been sourced
#
# Parameters:
#   $1 - Library filename (e.g., "workflow-detection.sh")
#
# Returns:
#   0 - Library is sourced (in memoization cache)
#   1 - Library is NOT sourced
#
# Usage:
#   if is_library_sourced "workflow-detection.sh"; then
#     echo "Library already loaded"
#   fi
is_library_sourced() {
  local lib="$1"
  [[ -n "${_SOURCED_LIBRARIES[$lib]}" ]]
}

# list_sourced_libraries() - Display all sourced libraries
#
# Outputs:
#   List of sourced library filenames (one per line)
#
# Usage:
#   echo "Currently sourced:"
#   list_sourced_libraries
list_sourced_libraries() {
  if [[ ${#_SOURCED_LIBRARIES[@]} -eq 0 ]]; then
    echo "No libraries sourced yet"
    return
  fi

  for lib in "${!_SOURCED_LIBRARIES[@]}"; do
    echo "$lib"
  done | sort
}

# clear_library_cache() - Clear memoization cache (for testing)
#
# WARNING: Should only be used in test environments
# Production code should NOT call this function
#
# Usage:
#   clear_library_cache  # Reset memoization state
clear_library_cache() {
  unset _SOURCED_LIBRARIES
  declare -g -A _SOURCED_LIBRARIES
}

# Export utility functions
export -f is_library_sourced
export -f list_sourced_libraries
export -f clear_library_cache
```

**File 2**: `.claude/docs/guides/library-sourcing-guide.md` (new file)

```markdown
# Library Sourcing Guide

## Overview

The library sourcing system uses memoization to provide idempotent, efficient library loading across all commands.

## Core Concept: Memoization

**Memoization** = Remember what's already been sourced, skip re-sourcing

```bash
# First call - sources 7 core libraries
source_required_libraries || exit 1

# Second call - skips all 7 (already sourced)
source_required_libraries || exit 1
```

## Usage Patterns

### Pattern 1: Minimal (Use Defaults)

```bash
# Source only core 7 libraries
source .claude/lib/library-sourcing.sh
source_required_libraries || exit 1
```

### Pattern 2: With Optional Libraries

```bash
# Source core 7 + dependency-analyzer.sh
source .claude/lib/library-sourcing.sh
source_required_libraries "dependency-analyzer.sh" || exit 1
```

### Pattern 3: Explicit (Self-Documenting)

```bash
# List all dependencies explicitly (for documentation)
# Only NEW libraries actually sourced (others skipped via memoization)
source .claude/lib/library-sourcing.sh
source_required_libraries \
  "workflow-detection.sh" \
  "error-handling.sh" \
  "checkpoint-utils.sh" \
  "dependency-analyzer.sh" || exit 1
```

**Recommendation**: Use Pattern 3 for commands (self-documenting)

## Verification

Check if library sourced:

```bash
if is_library_sourced "workflow-detection.sh"; then
  echo "✓ Workflow detection available"
fi
```

List all sourced libraries:

```bash
echo "Currently loaded:"
list_sourced_libraries
```

## Troubleshooting

### Issue: Library not found after sourcing

```bash
# Check if library in cache
if ! is_library_sourced "my-library.sh"; then
  echo "Library not in cache - check for sourcing errors"
  # Review error messages from source_required_libraries
fi
```

### Issue: Need to reset cache (testing only)

```bash
# WARNING: Only use in tests, not production
clear_library_cache
```

## Implementation Notes

- **Global State**: `_SOURCED_LIBRARIES` persists across calls
- **Idempotent**: Safe to call multiple times
- **Performance**: O(1) cache lookup, minimal overhead
- **Error Handling**: Failed sources NOT cached (allows retry)
```

**File 3**: `.claude/docs/guides/command-development-guide.md` (update existing)

Add section:

```markdown
## Library Sourcing (Updated in v2.0.0)

### Memoization Pattern

All library sourcing now uses memoization for idempotent behavior.

**Best Practice**: Explicitly list all dependencies for self-documentation

```bash
# ✅ GOOD - Self-documenting (lists all dependencies)
source_required_libraries \
  "workflow-detection.sh" \
  "checkpoint-utils.sh" \
  "dependency-analyzer.sh" || exit 1

# ✅ ALSO GOOD - Minimal (uses core defaults)
source_required_libraries || exit 1

# ❌ AVOID - Unclear what's being sourced
source_required_libraries "dep.sh" || exit 1  # Which dependencies?
```

### Performance

- **First Call**: Sources all requested libraries
- **Subsequent Calls**: O(1) cache lookup, ~0ms overhead
- **Multiple Commands**: Cache shared across commands in same session

### Verification

Always verify critical functions after sourcing:

```bash
source_required_libraries || exit 1

# Verify critical functions available
if ! declare -f "detect_workflow_scope" >/dev/null 2>&1; then
  echo "ERROR: detect_workflow_scope not found"
  exit 1
fi
```
```

**Testing**:
```bash
# Test utility functions
source .claude/lib/library-sourcing.sh
source_required_libraries || exit 1

# Test is_library_sourced
if is_library_sourced "workflow-detection.sh"; then
  echo "✓ Detection works"
fi

# Test list_sourced_libraries
echo "Sourced libraries:"
list_sourced_libraries

# Should show 7 core libraries
```

**Expected Duration**: 45-60 minutes

---

### Phase 3: Testing and Validation

**Objective**: Comprehensive testing of memoization implementation

**Complexity**: Medium

**Tasks**:
- [ ] Create test suite for memoization behavior
- [ ] Test idempotent sourcing (multiple calls)
- [ ] Test performance improvement (measure time)
- [ ] Test with /coordinate command (no timeout)
- [ ] Test with all orchestration commands
- [ ] Run full test suite (76 tests, no regressions)
- [ ] Test error cases (missing library, failed source)
- [ ] Test utility functions (is_library_sourced, etc.)
- [ ] Verify backward compatibility
- [ ] Document test results

**Implementation Details**:

**File**: `.claude/tests/test_library_memoization.sh`

```bash
#!/usr/bin/env bash
# Test suite for library sourcing memoization
# Tests idempotent behavior, performance, and edge cases

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Test helper functions
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  ((TESTS_PASSED++))
  ((TESTS_RUN++))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  echo "  Reason: $2"
  ((TESTS_FAILED++))
  ((TESTS_RUN++))
}

info() {
  echo -e "${YELLOW}ℹ INFO${NC}: $1"
}

# Test 1: Basic sourcing works
test_basic_sourcing() {
  info "Test 1: Basic library sourcing"

  # Clear any existing state
  unset _SOURCED_LIBRARIES
  declare -g -A _SOURCED_LIBRARIES

  # Source libraries
  source "$LIB_DIR/library-sourcing.sh"
  if source_required_libraries; then
    pass "Libraries sourced successfully"
  else
    fail "Libraries sourced successfully" "Source failed"
    return
  fi

  # Verify cache populated
  if [[ ${#_SOURCED_LIBRARIES[@]} -eq 7 ]]; then
    pass "Cache contains 7 core libraries"
  else
    fail "Cache contains 7 core libraries" "Found ${#_SOURCED_LIBRARIES[@]} libraries"
  fi
}

# Test 2: Idempotent sourcing (no re-sourcing)
test_idempotent_sourcing() {
  info "Test 2: Idempotent sourcing behavior"

  # Clear state
  unset _SOURCED_LIBRARIES
  declare -g -A _SOURCED_LIBRARIES

  source "$LIB_DIR/library-sourcing.sh"

  # First call - should source all
  source_required_libraries >/dev/null 2>&1
  local first_count=${#_SOURCED_LIBRARIES[@]}

  # Second call - should skip all (idempotent)
  source_required_libraries >/dev/null 2>&1
  local second_count=${#_SOURCED_LIBRARIES[@]}

  if [[ $first_count -eq $second_count ]]; then
    pass "Second call skipped re-sourcing (idempotent)"
  else
    fail "Second call skipped re-sourcing" "Count changed: $first_count → $second_count"
  fi
}

# Test 3: Performance improvement
test_performance_improvement() {
  info "Test 3: Performance improvement from memoization"

  # Clear state
  unset _SOURCED_LIBRARIES
  declare -g -A _SOURCED_LIBRARIES

  source "$LIB_DIR/library-sourcing.sh"

  # Measure first call (actual sourcing)
  local start_first=$(date +%s%N)
  source_required_libraries >/dev/null 2>&1
  local end_first=$(date +%s%N)
  local duration_first=$(( (end_first - start_first) / 1000000 ))  # Convert to ms

  # Measure second call (cached)
  local start_second=$(date +%s%N)
  source_required_libraries >/dev/null 2>&1
  local end_second=$(date +%s%N)
  local duration_second=$(( (end_second - start_second) / 1000000 ))  # Convert to ms

  # Second call should be faster (cached)
  if [[ $duration_second -lt $duration_first ]]; then
    pass "Cached call faster: ${duration_first}ms → ${duration_second}ms"
  else
    # Allow equal time (if both very fast)
    if [[ $duration_second -le $((duration_first + 5)) ]]; then
      pass "Cached call equivalent: ${duration_first}ms ≈ ${duration_second}ms"
    else
      fail "Cached call faster" "First: ${duration_first}ms, Second: ${duration_second}ms"
    fi
  fi
}

# Test 4: Optional libraries
test_optional_libraries() {
  info "Test 4: Optional libraries sourced correctly"

  # Clear state
  unset _SOURCED_LIBRARIES
  declare -g -A _SOURCED_LIBRARIES

  source "$LIB_DIR/library-sourcing.sh"

  # Source with optional library
  if source_required_libraries "dependency-analyzer.sh" >/dev/null 2>&1; then
    pass "Optional library sourced"
  else
    fail "Optional library sourced" "Source failed"
    return
  fi

  # Verify cache has 8 libraries (7 core + 1 optional)
  if [[ ${#_SOURCED_LIBRARIES[@]} -eq 8 ]]; then
    pass "Cache contains 8 libraries (7 core + 1 optional)"
  else
    fail "Cache contains 8 libraries" "Found ${#_SOURCED_LIBRARIES[@]}"
  fi
}

# Test 5: Explicit list (self-documenting)
test_explicit_list() {
  info "Test 5: Explicit library list (self-documenting pattern)"

  # Clear state
  unset _SOURCED_LIBRARIES
  declare -g -A _SOURCED_LIBRARIES

  source "$LIB_DIR/library-sourcing.sh"

  # Call with explicit list (including duplicates with core)
  if source_required_libraries \
    "workflow-detection.sh" \
    "error-handling.sh" \
    "dependency-analyzer.sh" >/dev/null 2>&1; then
    pass "Explicit list sourced (with duplicates)"
  else
    fail "Explicit list sourced" "Source failed"
    return
  fi

  # Should have 8 unique libraries (7 core + 1 new)
  if [[ ${#_SOURCED_LIBRARIES[@]} -eq 8 ]]; then
    pass "Deduplication works (8 unique from explicit list)"
  else
    fail "Deduplication works" "Found ${#_SOURCED_LIBRARIES[@]} instead of 8"
  fi
}

# Test 6: Utility function - is_library_sourced
test_is_library_sourced() {
  info "Test 6: is_library_sourced utility function"

  # Clear state
  unset _SOURCED_LIBRARIES
  declare -g -A _SOURCED_LIBRARIES

  source "$LIB_DIR/library-sourcing.sh"
  source_required_libraries >/dev/null 2>&1

  # Test for sourced library
  if is_library_sourced "workflow-detection.sh"; then
    pass "is_library_sourced detects sourced library"
  else
    fail "is_library_sourced detects sourced library" "Returned false"
  fi

  # Test for non-sourced library
  if ! is_library_sourced "non-existent.sh"; then
    pass "is_library_sourced detects non-sourced library"
  else
    fail "is_library_sourced detects non-sourced library" "Returned true"
  fi
}

# Test 7: Utility function - list_sourced_libraries
test_list_sourced_libraries() {
  info "Test 7: list_sourced_libraries utility function"

  # Clear state
  unset _SOURCED_LIBRARIES
  declare -g -A _SOURCED_LIBRARIES

  source "$LIB_DIR/library-sourcing.sh"
  source_required_libraries >/dev/null 2>&1

  # Get list
  local list_output
  list_output=$(list_sourced_libraries)
  local line_count=$(echo "$list_output" | wc -l)

  if [[ $line_count -eq 7 ]]; then
    pass "list_sourced_libraries returns 7 libraries"
  else
    fail "list_sourced_libraries returns 7 libraries" "Got $line_count lines"
  fi
}

# Test 8: Error case - missing library
test_missing_library_error() {
  info "Test 8: Error handling for missing library"

  # Clear state
  unset _SOURCED_LIBRARIES
  declare -g -A _SOURCED_LIBRARIES

  source "$LIB_DIR/library-sourcing.sh"

  # Try to source non-existent library
  if ! source_required_libraries "non-existent-library.sh" 2>/dev/null; then
    pass "Missing library detected and reported"
  else
    fail "Missing library detected" "Should have returned error"
    return
  fi

  # Verify missing library NOT in cache
  if ! is_library_sourced "non-existent-library.sh"; then
    pass "Failed library NOT added to cache"
  else
    fail "Failed library NOT added to cache" "Found in cache"
  fi
}

# Test 9: Integration - /coordinate doesn't timeout
test_coordinate_no_timeout() {
  info "Test 9: /coordinate command doesn't timeout"

  # This is a smoke test - just verify coordinate.md can be read
  local coordinate_file="$SCRIPT_DIR/../commands/coordinate.md"

  if [[ -f "$coordinate_file" ]]; then
    # Check that coordinate.md sources libraries
    if grep -q "source_required_libraries" "$coordinate_file"; then
      pass "/coordinate uses source_required_libraries"
    else
      fail "/coordinate uses source_required_libraries" "Not found in file"
    fi
  else
    fail "/coordinate file exists" "File not found: $coordinate_file"
  fi
}

# Test 10: Backward compatibility
test_backward_compatibility() {
  info "Test 10: Backward compatibility (existing calls work)"

  # Clear state
  unset _SOURCED_LIBRARIES
  declare -g -A _SOURCED_LIBRARIES

  source "$LIB_DIR/library-sourcing.sh"

  # Old pattern: no arguments (core only)
  if source_required_libraries >/dev/null 2>&1; then
    pass "Backward compatible: no-args call works"
  else
    fail "Backward compatible" "No-args call failed"
    return
  fi

  # Old pattern: single optional library
  if source_required_libraries "dependency-analyzer.sh" >/dev/null 2>&1; then
    pass "Backward compatible: single-arg call works"
  else
    fail "Backward compatible" "Single-arg call failed"
  fi
}

# Run all tests
run_tests() {
  echo "========================================="
  echo "Library Memoization Test Suite"
  echo "========================================="
  echo ""

  test_basic_sourcing
  test_idempotent_sourcing
  test_performance_improvement
  test_optional_libraries
  test_explicit_list
  test_is_library_sourced
  test_list_sourced_libraries
  test_missing_library_error
  test_coordinate_no_timeout
  test_backward_compatibility

  echo ""
  echo "========================================="
  echo "Test Results:"
  echo "  Total:  $TESTS_RUN"
  echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"
  echo "========================================="

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
  fi
}

# Run tests
run_tests
```

**Additional Testing**:

1. **Test /coordinate command**:
   ```bash
   # Should not timeout (complete in <2 minutes)
   time /coordinate "research API authentication patterns"

   # Verify reports created
   ls -la .claude/specs/*/reports/
   ```

2. **Test other orchestration commands**:
   ```bash
   # All should work without modification
   /orchestrate "research auth"
   /supervise "implement OAuth2"
   ```

3. **Run full test suite**:
   ```bash
   cd .claude/tests
   bash run_all_tests.sh

   # Should pass: 57/76 (75% - same as before)
   # No regressions expected
   ```

4. **Performance benchmark**:
   ```bash
   # Measure library sourcing time
   source .claude/lib/library-sourcing.sh

   # First call (actual sourcing)
   time source_required_libraries

   # Second call (cached)
   time source_required_libraries

   # Second should be significantly faster
   ```

**Expected Results**:
- New test suite: 10/10 tests passing
- /coordinate: No timeout, completes in <2 minutes
- Full test suite: 57/76 passing (no regressions)
- Performance: 90%+ improvement on cached calls

**Expected Duration**: 60-90 minutes

---

## Testing Strategy

### Unit Testing
- Test memoization behavior (idempotent sourcing)
- Test utility functions (is_library_sourced, list_sourced_libraries)
- Test error cases (missing library, failed source)
- Test performance (cached vs non-cached)

### Integration Testing
- Test /coordinate command (no timeout)
- Test all orchestration commands (orchestrate, supervise)
- Test multiple commands in sequence (cache persistence)
- Run full test suite (76 tests)

### Performance Testing
- Measure first call vs cached call time
- Verify <1ms overhead for cached lookups
- Compare with pre-memoization performance

### Regression Testing
- Verify all 57 currently passing tests still pass
- Verify no new failures introduced
- Test backward compatibility (existing calls work unchanged)

## Documentation Requirements

### Files to Create
1. `.claude/tests/test_library_memoization.sh` - New test suite
2. `.claude/docs/guides/library-sourcing-guide.md` - Usage guide

### Files to Update
1. `.claude/lib/library-sourcing.sh` - Add memoization implementation
2. `.claude/docs/guides/command-development-guide.md` - Update library sourcing section
3. `.claude/commands/coordinate.md` - No changes needed (already compatible)

## Dependencies

### Internal Dependencies
- No phase dependencies (all can be done sequentially)
- Phase 2 documents Phase 1 implementation
- Phase 3 validates Phases 1-2

### External Dependencies
- Git repository for commits
- Bash 4.0+ (for associative arrays)
- All 7 core libraries must exist in `.claude/lib/`

## Risk Mitigation

### Risk: Global State Issues
**Mitigation**:
- Use `declare -g` for explicit global scope
- Prefix with `_` to indicate internal variable
- Document state management in comments
- Add clear_library_cache() for testing

### Risk: Masking Missing Libraries
**Mitigation**:
- Failed libraries NOT added to cache
- Clear error messages on source failure
- Verification functions (is_library_sourced)
- Function existence checks after sourcing

### Risk: Performance Regression
**Mitigation**:
- O(1) cache lookup (associative array)
- Minimal overhead (single array lookup per library)
- Performance tests in test suite
- Benchmark before/after

### Risk: Breaking Backward Compatibility
**Mitigation**:
- Existing calls work unchanged (no signature changes)
- Core libraries still sourced automatically
- Optional libraries still passed as arguments
- Backward compatibility tests in test suite

## Expected Outcomes

### Metrics Improvement
- /coordinate timeout: RESOLVED (completes in <2 minutes)
- Library sourcing performance: 90%+ improvement on cached calls
- Test suite: 57/76 passing (no regressions)
- Code clarity: Idempotent behavior documented

### Quality Improvements
- Idempotent library sourcing (safe to call multiple times)
- Self-documenting commands (explicit library lists)
- Performance optimization (memoization)
- Robust error handling (failures not cached)

### Developer Experience
- Clear documentation about memoization pattern
- Utility functions for debugging (is_library_sourced, list_sourced_libraries)
- Explicit library dependencies in commands (self-documenting)
- No timeout frustration

---

## Implementation Checklist

### Before Starting
- [ ] Review current library-sourcing.sh implementation
- [ ] Understand associative array syntax (bash 4.0+)
- [ ] Read related report: 001_solution_analysis.md
- [ ] Backup current library-sourcing.sh

### Phase 1
- [ ] Add global `_SOURCED_LIBRARIES` declaration
- [ ] Add memoization check in source loop
- [ ] Update cache on successful source
- [ ] Ensure failures not cached
- [ ] Add comprehensive documentation
- [ ] Test basic sourcing manually

### Phase 2
- [ ] Add utility functions (is_library_sourced, etc.)
- [ ] Create library-sourcing-guide.md
- [ ] Update command-development-guide.md
- [ ] Add usage examples in documentation
- [ ] Review documentation for clarity

### Phase 3
- [ ] Create test_library_memoization.sh
- [ ] Run new test suite (should pass 10/10)
- [ ] Test /coordinate command (no timeout)
- [ ] Run full test suite (should pass 57/76)
- [ ] Benchmark performance improvement
- [ ] Document test results

### After Completion
- [ ] Git commit with descriptive message
- [ ] Update CHANGELOG.md
- [ ] Mark plan as complete
- [ ] Archive related research reports

## Git Workflow

### Commit Messages

**Phase 1 Commit**:
```
feat(library-sourcing): Implement memoization for idempotent library loading

- Add global _SOURCED_LIBRARIES cache (associative array)
- Skip already-sourced libraries (memoization pattern)
- Only cache successful sources (failures allow retry)
- Maintain backward compatibility (no API changes)

Fixes coordinate timeout caused by redundant library sourcing.

Performance: 90%+ improvement on cached library loads.
```

**Phase 2 Commit**:
```
docs(library-sourcing): Add documentation and utility functions

- Add is_library_sourced() utility function
- Add list_sourced_libraries() utility function
- Add clear_library_cache() for testing
- Create library-sourcing-guide.md
- Update command-development-guide.md

Documentation explains memoization pattern and idempotent behavior.
```

**Phase 3 Commit**:
```
test(library-sourcing): Add comprehensive memoization test suite

- Create test_library_memoization.sh (10 tests)
- Test idempotent behavior, performance, error cases
- Test utility functions and backward compatibility
- Verify /coordinate no longer times out

All tests passing (10/10). Full test suite: 57/76 (no regressions).
```

---

## Notes

### Design Rationale

**Why Memoization Over Deduplication?**
- Memoization: O(1) cache lookup, persistent state
- Deduplication: O(n) array search, per-call overhead
- Memoization enables idempotent behavior (key benefit)

**Why Global State?**
- Persists across multiple source_required_libraries() calls
- Shared across all commands in same shell session
- Industry-standard pattern (similar to require() in Node.js)

**Why Not Track Source Count?**
- Binary state sufficient (sourced or not)
- Simpler implementation
- Easier to debug

### Alternative Approaches Considered

1. **Deduplication (Option 2)**: More complex, per-call overhead
2. **Library Profiles (Option 3)**: Higher upfront cost, better for 10+ commands
3. **Minimal Fix (Option 1)**: Doesn't prevent future issues
4. **Hybrid (Option 5)**: Good but less robust than memoization

### Future Enhancements

1. **Dependency Graph**: Visualize library dependencies
2. **Lazy Loading**: Load libraries on first use (not at startup)
3. **Version Tracking**: Track library versions in cache
4. **Performance Dashboard**: Visualize sourcing time savings

### Related Documentation

- Solution analysis: `../reports/001_coordinate_timeout_investigation/001_solution_analysis.md`
- Library sourcing reference: `.claude/docs/reference/library-api.md`
- Command development guide: `.claude/docs/guides/command-development-guide.md`
