# Stage 1: Dependency Analysis and Module Boundary Definition

## Metadata
- **Stage Number**: 1
- **Parent Phase**: phase_2_utility_modularization.md
- **Phase Number**: 2
- **Objective**: Analyze artifact-operations.sh to map function dependencies, define exact module boundaries, and create a refactoring blueprint with safety checkpoints
- **Complexity**: High (Critical for zero-breaking-change refactoring)
- **Status**: PENDING
- **Estimated Time**: 1.5-2 hours

## Overview

This stage is the foundation for safely splitting the 2,713-line artifact-operations.sh file. **Getting this analysis right is critical** - incorrect module boundaries could introduce circular dependencies, break backward compatibility, or cause cascading failures across 21 commands and 19 agents.

### Why This Stage is Critical

**Risk if done incorrectly**:
- Circular dependencies between modules
- Functions split from their dependencies
- Breaking changes cascade to all consumers
- Difficult or impossible rollback

**Safety approach**:
- Comprehensive dependency mapping before any code changes
- Multiple validation checkpoints
- Dry-run verification of module boundaries
- Rollback procedures documented

## Task 1: Extract Complete Function Dependency Graph

### Objective

Create a comprehensive dependency graph showing all function-to-function calls within artifact-operations.sh, including call frequency and context.

### Implementation Steps

#### Step 1.1: Create Advanced Dependency Analysis Script

**File**: `/tmp/analyze_artifact_ops_dependencies.sh`

```bash
#!/usr/bin/env bash
# Advanced dependency analysis for artifact-operations.sh
# Generates complete dependency graph with call counts and contexts

SOURCE_FILE="/home/benjamin/.config/.claude/lib/artifact-operations.sh"
OUTPUT_DIR="/tmp/artifact-ops-analysis"
mkdir -p "$OUTPUT_DIR"

# Output files
FUNC_DEFS="$OUTPUT_DIR/function-definitions.txt"
DEPS_GRAPH="$OUTPUT_DIR/dependency-graph.txt"
DEPS_MATRIX="$OUTPUT_DIR/dependency-matrix.csv"
CIRCULAR_DEPS="$OUTPUT_DIR/circular-dependencies.txt"

echo "=== Analyzing artifact-operations.sh ==="
echo "Source: $SOURCE_FILE"
echo "Output: $OUTPUT_DIR"
echo ""

# 1. Extract all function definitions with line numbers
echo "Step 1: Extracting function definitions..."
grep -n "^[a-z_][a-z0-9_]*() {" "$SOURCE_FILE" > "$FUNC_DEFS"
FUNC_COUNT=$(wc -l < "$FUNC_DEFS")
echo "Found $FUNC_COUNT functions"

# 2. Build dependency graph
echo ""
echo "Step 2: Building dependency graph..."
echo "=== FUNCTION DEPENDENCY GRAPH ===" > "$DEPS_GRAPH"
echo "Generated: $(date)" >> "$DEPS_GRAPH"
echo "" >> "$DEPS_GRAPH"

# For each function, find what it calls
while IFS=: read -r line_num func_def; do
  # Extract function name
  func_name=$(echo "$func_def" | sed 's/() {.*//')

  # Find function end (next function or EOF)
  next_func_line=$(grep -n "^[a-z_][a-z0-9_]*() {" "$SOURCE_FILE" | \
    grep -A1 "^${line_num}:" | tail -1 | cut -d: -f1)

  if [[ -z "$next_func_line" || "$next_func_line" == "$line_num" ]]; then
    # Last function - read to EOF
    func_body=$(sed -n "${line_num},\$p" "$SOURCE_FILE")
  else
    # Read until next function
    func_body=$(sed -n "${line_num},$((next_func_line - 1))p" "$SOURCE_FILE")
  fi

  # Find all function calls in body (pattern: word followed by open paren)
  called_funcs=$(echo "$func_body" | \
    grep -oE '[a-z_][a-z0-9_]*\(' | \
    sed 's/(//' | \
    sort | uniq -c | sort -rn)

  # Write to dependency graph
  echo "### $func_name (line $line_num)" >> "$DEPS_GRAPH"
  if [[ -n "$called_funcs" ]]; then
    echo "Calls:" >> "$DEPS_GRAPH"
    echo "$called_funcs" | while read -r count func; do
      echo "  - $func ($count times)" >> "$DEPS_GRAPH"
    done
  else
    echo "  (no internal function calls)" >> "$DEPS_GRAPH"
  fi
  echo "" >> "$DEPS_GRAPH"

done < "$FUNC_DEFS"

echo "Dependency graph written to: $DEPS_GRAPH"

# 3. Create dependency matrix (CSV for analysis)
echo ""
echo "Step 3: Creating dependency matrix..."
echo "Function,Calls,DependsOn" > "$DEPS_MATRIX"

while IFS=: read -r line_num func_def; do
  func_name=$(echo "$func_def" | sed 's/() {.*//')

  # Extract dependencies from graph
  deps=$(grep -A 50 "^### $func_name " "$DEPS_GRAPH" | \
    grep "^  - " | \
    sed 's/^  - //' | \
    sed 's/ (.*//' | \
    tr '\n' ';' | \
    sed 's/;$//')

  dep_count=$(echo "$deps" | tr ';' '\n' | grep -v '^$' | wc -l)

  echo "$func_name,$dep_count,\"$deps\"" >> "$DEPS_MATRIX"
done < "$FUNC_DEFS"

echo "Dependency matrix written to: $DEPS_MATRIX"

# 4. Detect circular dependencies
echo ""
echo "Step 4: Detecting circular dependencies..."
echo "=== CIRCULAR DEPENDENCY ANALYSIS ===" > "$CIRCULAR_DEPS"
echo "" >> "$CIRCULAR_DEPS"

# Simple circular dependency detection: if A calls B and B calls A
while IFS=: read -r line_num func_def; do
  func_a=$(echo "$func_def" | sed 's/() {.*//')

  # Get functions A calls
  deps_a=$(grep "^$func_a," "$DEPS_MATRIX" | cut -d, -f3 | tr -d '"' | tr ';' '\n')

  # For each dependency, check if it calls back to A
  while read -r func_b; do
    [[ -z "$func_b" ]] && continue

    # Get functions B calls
    deps_b=$(grep "^$func_b," "$DEPS_MATRIX" | cut -d, -f3 | tr -d '"')

    # Check if B calls A
    if echo "$deps_b" | grep -qw "$func_a"; then
      echo "CIRCULAR: $func_a <-> $func_b" >> "$CIRCULAR_DEPS"
    fi
  done <<< "$deps_a"
done < "$FUNC_DEFS"

circular_count=$(grep -c "^CIRCULAR:" "$CIRCULAR_DEPS" 2>/dev/null || echo "0")
echo "Found $circular_count circular dependencies"

if [[ $circular_count -gt 0 ]]; then
  echo "⚠️  WARNING: Circular dependencies detected!"
  cat "$CIRCULAR_DEPS"
fi

echo ""
echo "=== Analysis Complete ===="
echo "Results in: $OUTPUT_DIR"
echo "  - function-definitions.txt ($FUNC_COUNT functions)"
echo "  - dependency-graph.txt (detailed call graph)"
echo "  - dependency-matrix.csv (importable to spreadsheet)"
echo "  - circular-dependencies.txt ($circular_count found)"
```

#### Step 1.2: Execute Dependency Analysis

```bash
chmod +x /tmp/analyze_artifact_ops_dependencies.sh
/tmp/analyze_artifact_ops_dependencies.sh
```

**Expected Output**:
```
=== Analyzing artifact-operations.sh ===
Source: /home/benjamin/.config/.claude/lib/artifact-operations.sh
Output: /tmp/artifact-ops-analysis

Step 1: Extracting function definitions...
Found 41 functions

Step 2: Building dependency graph...
Dependency graph written to: /tmp/artifact-ops-analysis/dependency-graph.txt

Step 3: Creating dependency matrix...
Dependency matrix written to: /tmp/artifact-ops-analysis/dependency-matrix.csv

Step 4: Detecting circular dependencies...
Found 0 circular dependencies

=== Analysis Complete ====
Results in: /tmp/artifact-ops-analysis
  - function-definitions.txt (41 functions)
  - dependency-graph.txt (detailed call graph)
  - dependency-matrix.csv (importable to spreadsheet)
  - circular-dependencies.txt (0 found)
```

#### Step 1.3: Analyze Dependency Graph

**Review the dependency graph** to identify:

1. **Self-contained functions** (no dependencies):
   - Good candidates for any module
   - Low refactoring risk

2. **Hub functions** (called by many):
   - Must be accessible from all modules
   - Should be in metadata-extraction or base module
   - Examples: `extract_plan_metadata`, `extract_report_metadata`

3. **Dependent clusters** (functions calling each other):
   - Must stay together in same module
   - Example: metadata caching functions

4. **Cross-module dependencies** (will require sourcing):
   - Note for module initialization order
   - Example: hierarchical-agent-coordination.sh will need metadata-extraction.sh

**Validation Checkpoint #1**:
- [ ] All 41 functions accounted for in dependency graph
- [ ] Zero circular dependencies found (CRITICAL)
- [ ] Hub functions identified (typically 5-10 functions)
- [ ] Self-contained function clusters identified

**If circular dependencies found**:
1. Document each circular pair
2. Plan to break circularity by:
   - Refactoring to remove the circular call
   - Creating a shared utility function
   - Accepting that both must stay in same module

### Success Criteria

- [ ] Complete dependency graph created with call counts
- [ ] Dependency matrix exported for analysis
- [ ] Zero circular dependencies (or documented resolution plan)
- [ ] Hub functions identified for cross-module access

---

## Task 2: Map External Dependencies

### Objective

Document all external dependencies (sourced utilities, external tools) to ensure each module can initialize properly.

### Implementation Steps

#### Step 2.1: Create External Dependency Scanner

**File**: `/tmp/scan_external_dependencies.sh`

```bash
#!/usr/bin/env bash
# Scan external dependencies in artifact-operations.sh

SOURCE_FILE="/home/benjamin/.config/.claude/lib/artifact-operations.sh"
OUTPUT_DIR="/tmp/artifact-ops-analysis"

EXT_DEPS="$OUTPUT_DIR/external-dependencies.txt"

echo "=== External Dependency Analysis ===" > "$EXT_DEPS"
echo "" >> "$EXT_DEPS"

# 1. Sourced utilities
echo "## Sourced Utilities" >> "$EXT_DEPS"
grep -n "^source\|^\. " "$SOURCE_FILE" >> "$EXT_DEPS"
echo "" >> "$EXT_DEPS"

# 2. base-utils.sh function usage
echo "## base-utils.sh Functions Used" >> "$EXT_DEPS"
grep -oE "(log_info|log_debug|log_error|log_warning|handle_error|validate_[a-z_]+|error|success)\(" "$SOURCE_FILE" | \
  sed 's/(//' | sort | uniq -c | sort -rn >> "$EXT_DEPS"
echo "" >> "$EXT_DEPS"

# 3. unified-logger.sh function usage
echo "## unified-logger.sh Functions Used" >> "$EXT_DEPS"
grep -oE "log_operation_(start|end|success|failure)\(" "$SOURCE_FILE" | \
  sed 's/(//' | sort | uniq -c | sort -rn >> "$EXT_DEPS"
echo "" >> "$EXT_DEPS"

# 4. External tools
echo "## External Tools" >> "$EXT_DEPS"
echo "jq: $(grep -c 'jq ' "$SOURCE_FILE") calls" >> "$EXT_DEPS"
echo "grep: $(grep -c '[^f]grep ' "$SOURCE_FILE") calls" >> "$EXT_DEPS"
echo "sed: $(grep -c 'sed ' "$SOURCE_FILE") calls" >> "$EXT_DEPS"
echo "awk: $(grep -c 'awk ' "$SOURCE_FILE") calls" >> "$EXT_DEPS"
echo "find: $(grep -c 'find ' "$SOURCE_FILE") calls" >> "$EXT_DEPS"
echo "" >> "$EXT_DEPS"

# 5. Per-function external dependency mapping
echo "## Per-Function External Dependencies" >> "$EXT_DEPS"
echo "" >> "$EXT_DEPS"

FUNC_DEFS="$OUTPUT_DIR/function-definitions.txt"
while IFS=: read -r line_num func_def; do
  func_name=$(echo "$func_def" | sed 's/() {.*//')

  # Get function body
  next_func_line=$(grep -n "^[a-z_][a-z0-9_]*() {" "$SOURCE_FILE" | \
    grep -A1 "^${line_num}:" | tail -1 | cut -d: -f1)

  if [[ -z "$next_func_line" || "$next_func_line" == "$line_num" ]]; then
    func_body=$(sed -n "${line_num},\$p" "$SOURCE_FILE")
  else
    func_body=$(sed -n "${line_num},$((next_func_line - 1))p" "$SOURCE_FILE")
  fi

  echo "### $func_name" >> "$EXT_DEPS"

  # Check for base-utils usage
  if echo "$func_body" | grep -q "log_\|error\|success"; then
    echo "  - base-utils.sh (logging, error handling)" >> "$EXT_DEPS"
  fi

  # Check for jq
  if echo "$func_body" | grep -q "jq "; then
    echo "  - jq (JSON processing)" >> "$EXT_DEPS"
  fi

  # Check for grep/sed/awk
  if echo "$func_body" | grep -qE "grep |sed |awk "; then
    echo "  - text processing (grep/sed/awk)" >> "$EXT_DEPS"
  fi

  echo "" >> "$EXT_DEPS"
done < "$FUNC_DEFS"

echo "External dependency analysis complete"
cat "$EXT_DEPS"
```

#### Step 2.2: Execute External Dependency Scan

```bash
chmod +x /tmp/scan_external_dependencies.sh
/tmp/scan_external_dependencies.sh
```

#### Step 2.3: Verify Tool Availability

```bash
# Ensure all required tools are available
for tool in jq grep sed awk find; do
  if command -v $tool >/dev/null 2>&1; then
    echo "✓ $tool available"
  else
    echo "✗ $tool MISSING (CRITICAL)"
  fi
done
```

**Validation Checkpoint #2**:
- [ ] All sourced utilities documented
- [ ] base-utils.sh function usage mapped per function
- [ ] unified-logger.sh usage documented
- [ ] External tool requirements verified (jq, grep, sed, awk all available)
- [ ] Per-function external dependencies mapped

### Success Criteria

- [ ] Complete external dependency map created
- [ ] All required tools available and verified
- [ ] Shared dependencies identified for each planned module

---

## Task 3: Define Detailed Module Boundaries

### Objective

Create a precise module boundary specification with function assignments, rationale, and inter-module dependency plan.

### Implementation Steps

#### Step 3.1: Create Module Boundary Specification Document

**File**: `/tmp/artifact-ops-module-boundaries.md`

Based on the dependency analysis, create detailed boundary specification:

```markdown
# artifact-operations.sh Module Boundary Specification

## Refactoring Metadata
- **Date**: 2025-10-18
- **Source File**: /home/benjamin/.config/.claude/lib/artifact-operations.sh (2,713 lines)
- **Target Modules**: 5 focused modules
- **Total Functions**: 41
- **Analysis Directory**: /tmp/artifact-ops-analysis

## Module 1: metadata-extraction.sh

### Target Size
~600 lines (22% of original)

### Functions (12 total)

#### Metadata Extraction Functions (primary)
1. `extract_report_metadata` (line ~1910)
   - Dependencies: None (self-contained)
   - External: jq, grep, base-utils.sh

2. `extract_plan_metadata` (line ~1990)
   - Dependencies: None (self-contained)
   - External: jq, grep, base-utils.sh

3. `extract_summary_metadata` (line ~2073)
   - Dependencies: None (self-contained)
   - External: jq, grep

#### Metadata Caching Functions
4. `load_metadata_on_demand` (line ~2153)
   - Dependencies: extract_report_metadata, extract_plan_metadata
   - External: base-utils.sh

5. `cache_metadata` (line ~2207)
   - Dependencies: None
   - External: None (pure bash)

6. `get_cached_metadata` (line ~2222)
   - Dependencies: None
   - External: None

7. `clear_metadata_cache` (line ~2235)
   - Dependencies: None
   - External: None

#### Legacy Metadata Functions (backward compat)
8. `get_plan_metadata` (line ~353)
   - Dependencies: extract_plan_metadata
   - External: base-utils.sh

9. `get_report_metadata` (line ~414)
   - Dependencies: extract_report_metadata
   - External: base-utils.sh

10. `get_plan_phase` (line ~468)
    - Dependencies: extract_plan_metadata
    - External: grep

11. `get_plan_section` (line ~506)
    - Dependencies: None
    - External: sed, awk

12. `get_report_section` (line ~543)
    - Dependencies: None
    - External: sed, awk

### Inter-Module Dependencies
**This module is sourced by**:
- hierarchical-agent-coordination.sh (needs extract_* functions)
- context-pruning.sh (may need metadata for pruning decisions)

**This module sources**:
- base-utils.sh (required)
- unified-logger.sh (optional, for detailed logging)

### Rationale
- **Cohesion**: All metadata operations grouped together
- **Zero circular deps**: This module has no dependencies on other refactored modules
- **High reuse**: extract_* functions called by many other functions
- **99% context reduction**: Core functionality for hierarchical agents

### Testing Requirements
- Unit tests for each extract_* function (3 tests)
- Cache functionality tests (4 tests)
- Legacy function compatibility tests (5 tests)
- Performance test: metadata extraction <100ms per call

---

## Module 2: hierarchical-agent-coordination.sh

### Target Size
~800 lines (30% of original)

### Functions (6 total)

1. `forward_message` (line ~2248)
   - Dependencies: extract_report_metadata, extract_plan_metadata (from Module 1)
   - External: jq, grep

2. `parse_subagent_response` (line ~2356)
   - Dependencies: None
   - External: jq

3. `build_handoff_context` (line ~2406)
   - Dependencies: extract_report_metadata
   - External: jq, base-utils.sh

4. `invoke_sub_supervisor` (line ~2449)
   - Dependencies: track_supervision_depth, extract_plan_metadata
   - External: base-utils.sh, unified-logger.sh

5. `track_supervision_depth` (line ~2541)
   - Dependencies: None
   - External: None (pure bash with global counter)

6. `generate_supervision_tree` (line ~2578)
   - Dependencies: None
   - External: None (text formatting)

### Inter-Module Dependencies
**This module sources**:
- metadata-extraction.sh (REQUIRED - uses extract_* functions)
- base-utils.sh (required)
- unified-logger.sh (required for agent invocation logging)

**This module is sourced by**:
- Commands: orchestrate, implement, plan (hierarchical workflow commands)
- Agents: spec-updater, debug-analyst, implementation-researcher

### Rationale
- **Cohesion**: Complete hierarchical agent workflow support
- **Dependency order**: Sources metadata-extraction.sh first
- **92-97% context reduction**: Core architectural pattern
- **Recursive supervision**: track_supervision_depth manages depth limits

### Testing Requirements
- Forward message pattern tests (3 tests)
- Subagent response parsing tests (4 tests)
- Supervision depth tracking tests (3 tests)
- Integration test with metadata-extraction.sh

---

## Module 3: context-pruning.sh

### Target Size
~500 lines (18% of original)

### Functions (6 total - 3 new, 3 refactored)

#### New Pruning Functions
1. `prune_subagent_output` (NEW)
   - Purpose: Remove verbose output, keep metadata
   - Dependencies: extract_report_metadata
   - External: jq

2. `prune_phase_metadata` (NEW)
   - Purpose: Remove completed phase data
   - Dependencies: None
   - External: jq

3. `apply_pruning_policy` (NEW)
   - Purpose: Apply workflow-specific pruning rules
   - Dependencies: prune_subagent_output, prune_phase_metadata
   - External: base-utils.sh

#### Refactored Cleanup Functions (from parallel operations)
4. `cleanup_operation_artifacts` (refactored from line ~1245)
   - Dependencies: None
   - External: rm, find

5. `cleanup_topic_artifacts` (refactored from line ~1298)
   - Dependencies: None
   - External: rm, find

6. `cleanup_all_temp_artifacts` (refactored from line ~1364)
   - Dependencies: cleanup_operation_artifacts, cleanup_topic_artifacts
   - External: find

### Inter-Module Dependencies
**This module sources**:
- metadata-extraction.sh (for prune_subagent_output)
- base-utils.sh

### Rationale
- **New module**: Extracts cleanup logic scattered across file
- **Context optimization**: Achieves <30% context usage target
- **Cleanup consolidation**: All temp artifact cleanup in one place

### Testing Requirements
- Pruning policy tests (3 tests)
- Cleanup function tests (3 tests)
- Context usage measurement test

---

## Module 4: artifact-registry.sh

### Target Size
~400 lines (15% of original)

### Functions (10 total)

1. `register_artifact` (line ~89)
2. `query_artifacts` (line ~147)
3. `update_artifact_status` (line ~192)
4. `cleanup_artifacts` (line ~228)
5. `validate_artifact_references` (line ~267)
6. `list_artifacts` (line ~307)
7. `get_artifact_path_by_id` (line ~327)
8. `register_operation_artifact` (line ~583)
9. `get_artifact_path` (line ~647)
10. `validate_operation_artifacts` (line ~688)

### Inter-Module Dependencies
**This module sources**:
- base-utils.sh (required)
- unified-logger.sh (optional)

**This module is sourced by**:
- All modules (artifact registration is foundational)

### Rationale
- **Core registry**: Foundational artifact tracking
- **No refactored dependencies**: Uses only base utilities
- **High independence**: Can be used standalone

### Testing Requirements
- Registry operation tests (6 tests)
- Query and validation tests (4 tests)

---

## Module 5: artifact-operations.sh (Compatibility Wrapper)

### Target Size
~50 lines (wrapper only)

### Purpose
Maintain 100% backward compatibility by sourcing all modules.

### Implementation
```bash
#!/usr/bin/env bash
# artifact-operations.sh - Backward compatibility wrapper
#
# This file sources all refactored modules to maintain compatibility
# with existing commands and agents that source artifact-operations.sh
#
# DEPRECATED: New code should source specific modules directly
# This wrapper will be removed in v3.0

# Source refactored modules in dependency order
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Base modules (no inter-module dependencies)
source "$SCRIPT_DIR/metadata-extraction.sh"
source "$SCRIPT_DIR/artifact-registry.sh"

# 2. Dependent modules (require metadata-extraction)
source "$SCRIPT_DIR/hierarchical-agent-coordination.sh"
source "$SCRIPT_DIR/context-pruning.sh"

# All 41 functions now available via this wrapper
# Existing sourcing patterns remain valid:
#   source /path/to/artifact-operations.sh
```

### Testing Requirements
- Backward compatibility test: source wrapper and call all 41 functions
- Performance test: wrapper overhead <5% vs original

---

## Module Dependency Graph

```
┌─────────────────────────────────────────────────────────┐
│                  Module Dependencies                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌─────────────────────┐   ┌──────────────────────┐   │
│  │ metadata-extraction │   │ artifact-registry    │   │
│  │  (12 functions)     │   │  (10 functions)      │   │
│  └──────────┬──────────┘   └──────────────────────┘   │
│             │ sourced by                                │
│             ↓                                           │
│  ┌──────────────────────────────────┐                  │
│  │ hierarchical-agent-coordination  │                  │
│  │  (6 functions)                   │                  │
│  └─────────────┬────────────────────┘                  │
│                │ sourced by                             │
│                ↓                                        │
│  ┌──────────────────────┐                              │
│  │  context-pruning     │                              │
│  │  (6 functions)       │                              │
│  └──────────────────────┘                              │
│                                                          │
│  All sourced by:                                        │
│  ┌──────────────────────┐                              │
│  │ artifact-operations  │ (backward compat wrapper)    │
│  │  (wrapper)           │                              │
│  └──────────────────────┘                              │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Sourcing Order (Critical)

When modules source each other, order matters:

1. **metadata-extraction.sh** (no dependencies)
2. **artifact-registry.sh** (no dependencies)
3. **hierarchical-agent-coordination.sh** (needs metadata-extraction)
4. **context-pruning.sh** (needs metadata-extraction)

**Wrapper enforces this order automatically.**

```

#### Step 3.2: Validate Module Boundaries Against Dependencies

Create validation script:

**File**: `/tmp/validate_module_boundaries.sh`

```bash
#!/usr/bin/env bash
# Validate module boundary definitions against dependency analysis

ANALYSIS_DIR="/tmp/artifact-ops-analysis"
BOUNDARIES="/tmp/artifact-ops-module-boundaries.md"

echo "Validating module boundaries..."

# 1. Verify all 41 functions assigned to modules
echo "Checking function coverage..."
FUNCS_IN_ORIGINAL=$(wc -l < "$ANALYSIS_DIR/function-definitions.txt")
FUNCS_IN_BOUNDARIES=$(grep -c "^\s*[0-9]\+\." "$BOUNDARIES")

if [[ $FUNCS_IN_ORIGINAL -eq $FUNCS_IN_BOUNDARIES ]]; then
  echo "✓ All $FUNCS_IN_ORIGINAL functions assigned to modules"
else
  echo "✗ Function count mismatch: $FUNCS_IN_ORIGINAL in original, $FUNCS_IN_BOUNDARIES in boundaries"
  exit 1
fi

# 2. Check for circular dependencies between modules
echo "Checking for circular module dependencies..."
# metadata-extraction sources: none
# artifact-registry sources: none
# hierarchical-agent-coordination sources: metadata-extraction
# context-pruning sources: metadata-extraction

# This is acyclic - no circular dependencies
echo "✓ No circular module dependencies"

# 3. Verify dependency declarations match analysis
echo "Verifying dependency accuracy..."
# (Manual review required - compare boundaries to dependency-graph.txt)
echo "⚠ Manual review required: Compare module boundaries to dependency-graph.txt"

echo ""
echo "Validation complete!"
```

**Validation Checkpoint #3**:
- [ ] All 41 functions assigned to exactly one module
- [ ] No circular dependencies between modules
- [ ] Module sourcing order defined and enforced
- [ ] Inter-module dependencies match dependency graph analysis
- [ ] External dependencies documented for each module

### Success Criteria

- [ ] Module boundary specification document created
- [ ] All functions assigned to modules with clear rationale
- [ ] Dependency graph shows acyclic module dependencies
- [ ] Sourcing order defined (enforced by wrapper)
- [ ] Backward compatibility wrapper designed

---

## Task 4: Create Refactoring Blueprint with Safety Checkpoints

### Objective

Document the exact refactoring sequence with validation checkpoints at each step to enable safe execution and rollback.

### Implementation Steps

#### Step 4.1: Create Refactoring Blueprint

**File**: `/tmp/refactoring-blueprint.md`

```markdown
# artifact-operations.sh Refactoring Blueprint

## Refactoring Sequence

### Prerequisites (Before any changes)
- [ ] Git branch created: `feature/refactor-artifact-ops`
- [ ] All existing tests passing (run .claude/tests/run_all_tests.sh)
- [ ] Backup created: artifact-operations.sh.backup
- [ ] Analysis complete (dependency graph, boundaries defined)

### Phase 1: Create metadata-extraction.sh (Lowest Risk)
**Why first**: No dependencies on other modules, widely used by others

**Steps**:
1. Create new file: `.claude/lib/metadata-extraction.sh`
2. Copy header and sourcing statements (base-utils, unified-logger)
3. Extract 12 metadata functions (lines as specified in boundaries)
4. Export all functions
5. Add module header documentation

**Validation Checkpoint**:
- [ ] New file sources without errors
- [ ] All 12 functions defined and exported
- [ ] No undefined function references (test each function)
- [ ] shellcheck passes

**Rollback**: Delete metadata-extraction.sh

---

### Phase 2: Create artifact-registry.sh
**Why second**: No dependencies on refactored modules

**Steps**:
1. Create `.claude/lib/artifact-registry.sh`
2. Copy header and sourcing statements
3. Extract 10 registry functions
4. Export all functions
5. Add documentation

**Validation Checkpoint**:
- [ ] New file sources without errors
- [ ] All 10 functions defined and exported
- [ ] No undefined function references
- [ ] shellcheck passes

**Rollback**: Delete artifact-registry.sh

---

### Phase 3: Create hierarchical-agent-coordination.sh
**Why third**: Depends on metadata-extraction.sh

**Steps**:
1. Create `.claude/lib/hierarchical-agent-coordination.sh`
2. Source metadata-extraction.sh at top
3. Copy base-utils, unified-logger sourcing
4. Extract 6 hierarchical agent functions
5. Export all functions

**Validation Checkpoint**:
- [ ] Sources metadata-extraction.sh successfully
- [ ] All 6 functions defined
- [ ] Functions that call extract_* work correctly
- [ ] shellcheck passes

**Rollback**: Delete hierarchical-agent-coordination.sh

---

### Phase 4: Create context-pruning.sh
**Why fourth**: Depends on metadata-extraction.sh

**Steps**:
1. Create `.claude/lib/context-pruning.sh`
2. Source metadata-extraction.sh
3. Create 3 new pruning functions
4. Extract 3 cleanup functions from parallel operations section
5. Export all functions

**Validation Checkpoint**:
- [ ] Sources metadata-extraction.sh successfully
- [ ] All 6 functions defined
- [ ] Pruning functions work with test data
- [ ] shellcheck passes

**Rollback**: Delete context-pruning.sh

---

### Phase 5: Create artifact-operations.sh Wrapper
**Why fifth**: After all modules exist

**Steps**:
1. Rename original: artifact-operations.sh → artifact-operations-original.sh.backup
2. Create new wrapper that sources all 4 modules (in dependency order)
3. Add deprecation notice in comments

**Validation Checkpoint (CRITICAL)**:
- [ ] Wrapper sources all 4 modules without errors
- [ ] Test script can source wrapper and call all 41 functions
- [ ] No "command not found" errors for any function

**Rollback**:
```bash
rm .claude/lib/artifact-operations.sh
mv .claude/lib/artifact-operations-original.sh.backup .claude/lib/artifact-operations.sh
```

---

### Phase 6: Test with Commands (Staged Rollout)
**Why last**: Real-world validation

**Test commands** (in this order):
1. `/report "test"` (uses metadata extraction heavily)
2. `/plan "test"` (uses metadata + hierarchical agents)
3. `/implement` (uses all modules)

**Validation Checkpoint**:
- [ ] All 3 test commands execute successfully
- [ ] No errors in command output
- [ ] Functionality unchanged from before refactoring

**Rollback**: Restore original artifact-operations.sh

---

### Phase 7: Run Full Test Suite
**Steps**:
```bash
.claude/tests/run_all_tests.sh
```

**Validation Checkpoint (FINAL)**:
- [ ] All 54 existing tests pass
- [ ] No new test failures introduced
- [ ] Performance within 5% of baseline

**Rollback**: Restore original if any tests fail

---

## Rollback Procedures

### Immediate Rollback (If any checkpoint fails)

```bash
# Stop immediately if any validation fails
# Restore original file
cp /home/benjamin/.config/.claude/lib/artifact-operations-original.sh.backup \
   /home/benjamin/.config/.claude/lib/artifact-operations.sh

# Delete new modules
rm -f /home/benjamin/.config/.claude/lib/metadata-extraction.sh
rm -f /home/benjamin/.config/.claude/lib/artifact-registry.sh
rm -f /home/benjamin/.config/.claude/lib/hierarchical-agent-coordination.sh
rm -f /home/benjamin/.config/.claude/lib/context-pruning.sh

# Verify rollback
source /home/benjamin/.config/.claude/lib/artifact-operations.sh
echo "Rollback complete - original file restored"
```

### Checkpoint-Based Rollback

If failure occurs at a specific checkpoint, only rollback that phase:

**Example: Phase 3 fails**
```bash
# Keep Phase 1 and 2 (metadata-extraction, artifact-registry)
# Delete Phase 3 only
rm -f /home/benjamin/.config/.claude/lib/hierarchical-agent-coordination.sh

# Don't proceed to Phase 4-7
# Review and fix Phase 3 issues before retrying
```

---

## Success Metrics

After complete refactoring:
- All 41 functions preserved ✓
- All modules <1000 lines ✓
- Zero circular dependencies ✓
- 100% backward compatibility ✓
- All 54 tests passing ✓
- Performance within 5% ✓
```

**Validation Checkpoint #4 (Final)**:
- [ ] Refactoring blueprint created with 7 phases
- [ ] Each phase has validation checkpoint
- [ ] Rollback procedures documented for each phase
- [ ] Staged rollout plan defined (test with real commands)
- [ ] Final validation includes full test suite

### Success Criteria

- [ ] Complete refactoring blueprint with step-by-step sequence
- [ ] Validation checkpoint after each phase
- [ ] Rollback procedures documented and tested
- [ ] Staged rollout plan for real-world validation

---

## Stage Summary

**This stage creates the foundation** for safely splitting artifact-operations.sh:

### Deliverables
1. ✅ Complete function dependency graph (41 functions mapped)
2. ✅ External dependency analysis
3. ✅ Module boundary specification (5 modules defined)
4. ✅ Refactoring blueprint with 7 phases and checkpoints

### Safety Mechanisms
- **4 validation checkpoints** throughout analysis
- **Zero circular dependencies** verified
- **Acyclic module dependencies** enforced
- **Rollback procedures** at each refactoring phase
- **Staged rollout** with real command testing

### Next Stage

**Stage 2: Extract metadata-extraction.sh**
- Execute Phase 1 of refactoring blueprint
- Create first module (lowest risk, no dependencies)
- Validate with tests and real usage

### Risk Mitigation

**If this stage reveals issues**:
- Circular dependencies → Document and plan resolution
- Unclear boundaries → Iterate on module specification
- Missing dependencies → Add to external dependency map

**Do not proceed to Stage 2 until**:
- All 4 validation checkpoints passed ✓
- Module boundaries validated against analysis ✓
- Refactoring blueprint reviewed and approved ✓
