# Current Library Loading Patterns Research Report

## Metadata
- **Date**: 2025-10-29
- **Agent**: research-specialist
- **Topic**: Current Library Loading Patterns in .claude/ System
- **Report Type**: codebase analysis
- **Overview**: [OVERVIEW.md](./OVERVIEW.md)

## Executive Summary

The .claude/ system currently uses two distinct library loading patterns: a centralized `source_required_libraries()` function (library-sourcing.sh) that loads 7 core libraries automatically, and direct individual sourcing scattered across commands. Analysis reveals significant redundancy: /coordinate passes 6 libraries already loaded by the core function, causing double-sourcing and timeouts. No memoization exists to prevent re-sourcing. The 7 core libraries have minimal internal dependencies, making them suitable for lazy loading optimization.

## Findings

### 1. Current Library Loading Architecture

**Primary Loading Mechanism**: `library-sourcing.sh` (82 lines)

The system provides a centralized function `source_required_libraries()` that:
- Automatically sources 7 core libraries (hardcoded in lines 39-47)
- Accepts optional additional libraries as arguments (line 50-52)
- Provides fail-fast error handling with detailed diagnostics
- **No memoization**: Libraries can be sourced multiple times without detection

**Core Libraries** (always loaded by `source_required_libraries()`):
1. `workflow-detection.sh` - Workflow scope detection functions
2. `error-handling.sh` - Error handling utilities
3. `checkpoint-utils.sh` - Checkpoint save/restore operations
4. `unified-logger.sh` - Progress logging utilities
5. `unified-location-detection.sh` - Project structure detection
6. `metadata-extraction.sh` - Report/plan metadata extraction
7. `context-pruning.sh` - Context management utilities

Reference: `/home/benjamin/.config/.claude/lib/library-sourcing.sh:39-47`

### 2. Library Loading Patterns Across Commands

**Pattern Analysis** (from 22 command files):

**Pattern A: Unified Loading** (2 commands)
- Uses `source_required_libraries()` function
- Commands: `/coordinate`, `/supervise`
- Example: `/supervise` (line 233) - sources core 7 with no additional libraries
- Example: `/coordinate` (line 539) - sources core 7 + 7 additional (6 duplicates!)

**Pattern B: Individual Sourcing** (15+ commands)
- Direct `source` statements for each library needed
- Commands: `/implement`, `/plan`, `/research`, `/expand`, `/collapse`, others
- Typical pattern: Source `detect-project-dir.sh` first, then individual utilities
- No deduplication or memoization

**Pattern C: Hybrid** (5 commands)
- Mix of function-based and individual sourcing
- Example: `/implement` sources utilities individually after project detection
- Example: `/orchestrate` sources error-handling and other utilities directly

Reference: Grep results from `/home/benjamin/.config/.claude/commands/*.md`

### 3. Library Usage Frequency

**Top 10 Most Sourced Libraries** (across all commands):

1. `detect-project-dir.sh` - 8 occurrences (standalone sourcing)
2. `checkbox-utils.sh` - 5 occurrences
3. `artifact-operations.sh` - 5 occurrences (3 + 2 variants)
4. `plan-core-bundle.sh` - 4 occurrences
5. `context-metrics.sh` - 4 occurrences
6. `template-integration.sh` - 3 occurrences
7. `unified-location-detection.sh` - 2+ occurrences (plus 7 via core)
8. `error-handling.sh` - 2+ occurrences (plus 7 via core)
9. `metadata-extraction.sh` - 2+ occurrences (plus 7 via core)
10. `checkpoint-utils.sh` - 2+ occurrences (plus 7 via core)

**Key Insight**: The 7 core libraries are sourced at least 7 times each (via `source_required_libraries()`), plus additional individual sourcing in some commands.

Reference: Bash command output showing frequency counts

### 4. Redundant Sourcing Problem

**Critical Issue in /coordinate** (line 539):

```bash
if ! source_required_libraries "dependency-analyzer.sh" "context-pruning.sh" "checkpoint-utils.sh" "unified-location-detection.sh" "workflow-detection.sh" "unified-logger.sh" "error-handling.sh"; then
  exit 1
fi
```

**Problem Analysis**:
- `source_required_libraries()` internally sources 7 core libraries (lines 39-47)
- /coordinate then passes 7 additional library names as arguments
- 6 of these 7 are duplicates of the core libraries already sourced
- Result: 6 libraries sourced twice (workflow-detection, error-handling, checkpoint-utils, unified-logger, unified-location-detection, context-pruning)
- Only `dependency-analyzer.sh` is truly new

**Impact**:
- Timeout issues in /coordinate execution
- Unnecessary overhead (each library sources its dependencies)
- No protection against future duplicate sourcing

Reference: `/home/benjamin/.config/.claude/specs/518_coordinate_timeout_investigation/plans/001_implement_lazy_library_loading.md:23-30`

### 5. Dependency Chain Analysis

**Internal Library Dependencies** (from Grep analysis):

Several libraries have their own sourcing dependencies:

**Base Utilities Cascade**:
- `base-utils.sh` - Sourced by 10+ libraries (checkbox-utils, agent-discovery, agent-schema-validator, artifact-registry, timestamp-utils, metadata-extraction, unified-logger, artifact-creation, etc.)
- Creates implicit dependency tree

**Complex Dependency Examples**:

1. `unified-logger.sh` (lines 26-27):
   - Sources `base-utils.sh`
   - Sources `timestamp-utils.sh`

2. `metadata-extraction.sh` (lines 8-9):
   - Sources `base-utils.sh`
   - Sources `unified-logger.sh` (which sources base-utils again!)

3. `checkpoint-utils.sh` (lines 17-18):
   - Sources `detect-project-dir.sh`
   - Sources `timestamp-utils.sh`

4. `auto-analysis-utils.sh` (lines 10-17):
   - Sources `plan-core-bundle.sh`
   - Sources `json-utils.sh`
   - Sources `error-handling.sh`
   - Sources `agent-invocation.sh`
   - Sources `analysis-pattern.sh`
   - Sources `artifact-registry.sh`
   - **6 dependencies in one library!**

**Key Insight**: No bash protection against re-sourcing. If `base-utils.sh` is sourced by library A, then library B sources library A, `base-utils.sh` is executed multiple times.

Reference: Grep output from `/home/benjamin/.config/.claude/lib/*.sh`

### 6. No Memoization Pattern Currently Exists

**Current library-sourcing.sh Implementation** (lines 56-68):

```bash
for lib in "${libraries[@]}"; do
  local lib_path="${claude_root}/lib/${lib}"

  if [[ ! -f "$lib_path" ]]; then
    failed_libraries+=("$lib (expected at: $lib_path)")
    continue
  fi

  # shellcheck disable=SC1090
  if ! source "$lib_path" 2>/dev/null; then
    failed_libraries+=("$lib (source failed)")
  fi
done
```

**Observations**:
- No check for previously sourced libraries
- No global state tracking (no `_SOURCED_LIBRARIES` cache)
- No idempotent behavior
- Each call to `source_required_libraries()` re-sources all libraries

**Bash Limitation**: Bash `source` command has no built-in idempotency. Re-sourcing executes all code again.

Reference: `/home/benjamin/.config/.claude/lib/library-sourcing.sh:56-68`

### 7. Library Sourcing Performance Impact

**Estimated Costs** (per library source operation):

- Average library size: 200-500 lines
- Sourcing time: 10-50ms per library (disk I/O + parsing + execution)
- 7 core libraries: ~70-350ms first load
- Duplicate sourcing: Additional 60-300ms (6 libraries in /coordinate)

**Timeout Context**:
- /coordinate experiences timeouts (>2 minutes)
- Redundant library sourcing contributes to startup overhead
- Wave-based parallel execution delays due to initialization time

**Amplification with Nested Dependencies**:
- If library A sources base-utils.sh (20ms)
- And library B sources base-utils.sh (20ms)
- And library C sources base-utils.sh (20ms)
- Base-utils.sh executed 3 times = 60ms (should be 20ms)

Reference: `/home/benjamin/.config/.claude/specs/518_coordinate_timeout_investigation/plans/001_implement_lazy_library_loading.md`

### 8. Library Organization Patterns

**Three Library Categories Observed**:

**Category 1: Core Orchestration Libraries** (7 libraries)
- Always needed by orchestration commands
- Hardcoded in `library-sourcing.sh`
- Minimal internal dependencies
- Examples: workflow-detection, error-handling, unified-logger

**Category 2: Specialized Feature Libraries** (20+ libraries)
- Needed by specific commands only
- Sourced individually or passed as optional args
- Examples: plan-core-bundle, complexity-utils, artifact-operations
- Often have heavier dependency chains

**Category 3: Base Utility Libraries** (5-7 libraries)
- Sourced as dependencies by other libraries
- Examples: base-utils, timestamp-utils, detect-project-dir
- Not directly sourced by commands (usually)

**Pattern Insight**: Category 1 libraries are good candidates for lazy loading with memoization (frequently needed, low internal dependencies).

### 9. Command-Specific Library Usage Patterns

**High-Dependency Commands**:

1. `/implement` - Sources 8+ libraries individually
   - detect-project-dir, error-handling, checkpoint-utils, complexity-utils, adaptive-planning-logger, checkbox-utils, artifact-operations, context-metrics

2. `/plan` - Sources 7+ libraries individually
   - detect-project-dir, complexity-utils, artifact-operations, context-metrics, template-integration, unified-location-detection, checkbox-utils

3. `/research` - Sources 5 libraries directly
   - topic-decomposition, artifact-creation, template-integration, metadata-extraction, overview-synthesis

**Low-Dependency Commands**:

1. `/supervise` - Uses `source_required_libraries()` only (7 core)
2. `/test`, `/test-all` - Minimal or no library loading

**Observation**: Commands using individual sourcing would benefit from memoization if multiple commands run in same session.

Reference: Grep analysis of command files

## Recommendations

### 1. Implement Memoization Pattern in library-sourcing.sh

**Priority**: HIGH (solves /coordinate timeout directly)

**Approach**: Add global associative array `_SOURCED_LIBRARIES` to track sourced libraries.

**Benefits**:
- Idempotent library loading (safe to call multiple times)
- Eliminates duplicate sourcing (/coordinate passes 6 duplicate libraries)
- Minimal code change (add cache check in loop)
- O(1) lookup performance (associative array)

**Implementation**:
```bash
declare -g -A _SOURCED_LIBRARIES

source_required_libraries() {
  # ... existing setup ...

  for lib in "${libraries[@]}"; do
    # NEW: Memoization check
    if [[ -n "${_SOURCED_LIBRARIES[$lib]}" ]]; then
      continue  # Skip already-sourced library
    fi

    # ... existing sourcing logic ...

    # NEW: Mark as sourced on success
    _SOURCED_LIBRARIES[$lib]=1
  done
}
```

**Risk Mitigation**: Failed sources NOT added to cache (allows retry).

Reference: Implementation plan Phase 1

### 2. Standardize All Commands to Use source_required_libraries()

**Priority**: MEDIUM (improves consistency)

**Rationale**: 15+ commands use individual sourcing. Migrating to centralized function provides:
- Automatic memoization benefits
- Consistent error handling
- Self-documenting dependencies (explicit library list)

**Approach**:
1. Keep explicit library lists for documentation
2. Rely on memoization to skip duplicates
3. Update command development guide

**Example Migration**:
```bash
# Before (individual sourcing)
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"
source "$UTILS_DIR/error-handling.sh"
source "$UTILS_DIR/checkpoint-utils.sh"

# After (unified with memoization)
source_required_libraries "detect-project-dir.sh" "error-handling.sh" "checkpoint-utils.sh"
# Core 7 + these 3 (detect-project-dir already sourced? skip it!)
```

**Note**: Not critical for single-command execution, but valuable for multi-command workflows.

### 3. Add Utility Functions for Debugging

**Priority**: LOW (developer experience improvement)

**Functions to Add**:
- `is_library_sourced(lib)` - Check if library in cache
- `list_sourced_libraries()` - Display all sourced libraries
- `clear_library_cache()` - Reset cache (testing only)

**Use Case**: Debugging library loading issues, verifying memoization behavior.

Reference: Implementation plan Phase 2

### 4. Document Library Dependency Graph

**Priority**: LOW (long-term maintenance)

**Rationale**: Understanding dependency chains helps:
- Optimize library loading order
- Identify circular dependencies
- Plan future refactoring

**Deliverable**: Diagram showing which libraries source which dependencies.

**Example**:
```
unified-logger.sh
  ├── base-utils.sh
  └── timestamp-utils.sh
      └── base-utils.sh (duplicate!)
```

### 5. Consider Lazy Loading for Specialized Libraries

**Priority**: LOW (future optimization)

**Scope**: Category 2 libraries (specialized features)

**Approach**: Load libraries on-demand when specific functions first called, not at command startup.

**Example**:
```bash
# Lazy load complexity-utils only when needed
analyze_complexity() {
  if [[ -z "${_SOURCED_LIBRARIES[complexity-utils.sh]}" ]]; then
    source_required_libraries "complexity-utils.sh"
  fi
  # ... complexity analysis logic ...
}
```

**Benefits**: Faster command startup for simple workflows.

**Trade-offs**: More complex code, runtime errors if lazy load fails.

## References

### Primary Files Analyzed

1. `/home/benjamin/.config/.claude/lib/library-sourcing.sh` - Lines 1-82 (main sourcing function)
2. `/home/benjamin/.config/.claude/commands/coordinate.md` - Line 539 (redundant sourcing issue)
3. `/home/benjamin/.config/.claude/commands/supervise.md` - Line 233 (clean usage pattern)
4. `/home/benjamin/.config/.claude/commands/implement.md` - Lines 410-425 (individual sourcing pattern)
5. `/home/benjamin/.config/.claude/specs/518_coordinate_timeout_investigation/plans/001_implement_lazy_library_loading.md` - Full file (context and solution design)

### Library Files with Internal Dependencies

6. `/home/benjamin/.config/.claude/lib/unified-logger.sh` - Lines 26-27 (sources base-utils, timestamp-utils)
7. `/home/benjamin/.config/.claude/lib/metadata-extraction.sh` - Lines 8-9 (sources base-utils, unified-logger)
8. `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` - Lines 17-18 (sources detect-project-dir, timestamp-utils)
9. `/home/benjamin/.config/.claude/lib/auto-analysis-utils.sh` - Lines 10-17 (sources 6 dependencies)
10. `/home/benjamin/.config/.claude/lib/artifact-registry.sh` - Lines 8-9 (sources base-utils, unified-logger)

### Command Files Analyzed (22 total)

11. `/home/benjamin/.config/.claude/commands/*.md` - All commands analyzed via Grep for sourcing patterns
12. Grep output showing 30+ different library sourcing statements across commands
13. Frequency analysis showing detect-project-dir.sh sourced 8 times, checkbox-utils.sh 5 times, etc.

### Supporting Documentation

14. Project standards: `/home/benjamin/.config/CLAUDE.md` - Testing protocols, code standards, development workflow
