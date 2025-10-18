# Phase 2: Utility Modularization - Split artifact-operations.sh

## Metadata
- **Phase Number**: 2
- **Parent Plan**: /home/benjamin/.config/.claude/specs/plans/072_claude_infrastructure_refactoring/072_claude_infrastructure_refactoring.md
- **Objective**: Split 2,713-line artifact-operations.sh into 5 focused modules with complete backward compatibility
- **Complexity**: High (9.5/10)
- **Status**: pending
- **Estimated Tasks**: 18 detailed tasks across 5 stages
- **Estimated Time**: 6-8 hours
- **Dependencies**: None (independent refactoring)

## Overview

### Current State

The `artifact-operations.sh` file (2,713 lines) is a consolidated utility that handles multiple distinct concerns:

**File Location**: `/home/benjamin/.config/.claude/lib/artifact-operations.sh`

**Current Function Categories**:
1. **Registry Operations** (7 functions, ~250 lines)
   - `register_artifact`, `query_artifacts`, `update_artifact_status`
   - `cleanup_artifacts`, `validate_artifact_references`, `list_artifacts`
   - `get_artifact_path_by_id`

2. **Metadata Extraction** (8 functions, ~600 lines)
   - `get_plan_metadata`, `get_report_metadata`, `get_plan_phase`
   - `get_plan_section`, `get_report_section`
   - `extract_report_metadata`, `extract_plan_metadata`, `extract_summary_metadata`
   - `load_metadata_on_demand`, `cache_metadata`, `get_cached_metadata`, `clear_metadata_cache`

3. **Artifact Creation** (6 functions, ~450 lines)
   - `create_topic_artifact`, `create_artifact_directory`
   - `create_artifact_directory_with_workflow`, `get_next_artifact_number`
   - `write_artifact_file`, `generate_artifact_invocation`

4. **Operation Tracking** (3 functions, ~200 lines)
   - `register_operation_artifact`, `get_artifact_path`
   - `validate_operation_artifacts`

5. **Parallel Operations** (5 functions, ~350 lines)
   - `save_operation_artifact`, `load_artifact_references`
   - `cleanup_operation_artifacts`, `cleanup_topic_artifacts`
   - `cleanup_all_temp_artifacts`

6. **Report Generation** (5 functions, ~500 lines)
   - `generate_analysis_report`, `review_plan_hierarchy`
   - `run_second_round_analysis`, `present_recommendations_for_approval`
   - `generate_recommendations_report`

7. **Cross-Reference Management** (3 functions, ~200 lines)
   - `update_cross_references`, `validate_gitignore_compliance`
   - `link_artifact_to_plan`

8. **Hierarchical Agent Support** (4 functions, ~300 lines)
   - `forward_message`, `parse_subagent_response`, `build_handoff_context`
   - `invoke_sub_supervisor`, `track_supervision_depth`, `generate_supervision_tree`

**Current Dependencies**:
- Sources: `base-utils.sh`, `unified-logger.sh`
- External tools: `jq`, `grep`, `sed`, `awk`
- Used by: 21 commands, 19 agents, multiple utilities

### Target State

Split into 5 focused modules with backward compatibility wrapper:

```
.claude/lib/
├── metadata-extraction.sh (~600 lines)
│   └── extract_report_metadata, extract_plan_metadata, extract_summary_metadata
│       load_metadata_on_demand, cache_metadata, get/clear cache functions
│       get_plan_metadata, get_report_metadata, get_plan_phase/section
│
├── hierarchical-agent-coordination.sh (~800 lines)
│   └── invoke_sub_supervisor, track_supervision_depth, generate_supervision_tree
│       forward_message, parse_subagent_response, build_handoff_context
│
├── context-pruning.sh (~500 lines)
│   └── prune_subagent_output, prune_phase_metadata, apply_pruning_policy
│       cleanup_operation_artifacts, cleanup_topic_artifacts
│       cleanup_all_temp_artifacts (refactored from parallel ops)
│
├── forward-message-patterns.sh (~400 lines)
│   └── Minimal handoff context creation, artifact path extraction
│       Structured subagent response parsing
│       (Note: May be merged with hierarchical-agent-coordination.sh)
│
├── artifact-registry.sh (~400 lines)
│   └── register_artifact, query_artifacts, update_artifact_status
│       cleanup_artifacts, validate_artifact_references, list_artifacts
│       get_artifact_path_by_id, register_operation_artifact
│
└── artifact-operations.sh (compatibility wrapper, ~50 lines)
    └── Sources all 5 modules for backward compatibility
```

**Design Notes**:
- **Metadata Extraction**: Self-contained module for all metadata operations (99% context reduction)
- **Hierarchical Agent Coordination**: Combines forward message + supervision + tree generation
- **Context Pruning**: New module extracting cleanup logic from parallel operations
- **Artifact Registry**: Core registry operations + operation tracking
- **Backward Compatibility**: Wrapper ensures zero breaking changes

### Success Criteria

- [ ] All 5 modules created with clear boundaries (<1000 lines each)
- [ ] 100% function coverage (all 41 functions preserved and working)
- [ ] Backward compatibility wrapper maintains all existing sourcing patterns
- [ ] All 54 existing tests pass without modification
- [ ] No performance degradation (max 5% overhead acceptable)
- [ ] All 21 commands work unchanged with wrapper
- [ ] All 19 agents work unchanged with wrapper
- [ ] Comprehensive test coverage for each new module (≥80%)
- [ ] Documentation updated (lib/README.md, inline comments)

## Stage 1: Dependency Analysis and Module Boundary Definition

**Objective**: Analyze artifact-operations.sh to map function dependencies, define exact module boundaries, and create a refactoring blueprint.

**Estimated Time**: 1.5-2 hours

### Tasks

#### Task 1.1: Extract Function Dependency Graph

**Description**: Analyze all function calls within artifact-operations.sh to understand internal dependencies.

**Implementation**:

```bash
# Create dependency analysis script
cat > /tmp/analyze_dependencies.sh << 'EOF'
#!/usr/bin/env bash
# Analyze function dependencies in artifact-operations.sh

source_file="/home/benjamin/.config/.claude/lib/artifact-operations.sh"
output_file="/tmp/artifact-ops-dependencies.txt"

# Extract all function definitions
echo "=== FUNCTION DEFINITIONS ===" > "$output_file"
grep -n "^[a-z_]*() {" "$source_file" >> "$output_file"

echo -e "\n=== FUNCTION CALLS WITHIN FUNCTIONS ===" >> "$output_file"

# For each function, find what it calls
while IFS= read -r func_line; do
  func_name=$(echo "$func_line" | sed 's/() {.*//')
  line_num=$(echo "$func_line" | cut -d: -f1)

  # Find the function's closing brace (approximate)
  next_line=$((line_num + 1))

  echo -e "\n$func_name (line $line_num) calls:" >> "$output_file"

  # Search for function calls in the function body (next 50 lines)
  sed -n "${next_line},$((next_line + 50))p" "$source_file" | \
    grep -oE '[a-z_]+\(' | sed 's/(//' | sort -u >> "$output_file"
done < <(grep "^[a-z_]*() {" "$source_file")

echo "Dependency analysis written to: $output_file"
EOF

chmod +x /tmp/analyze_dependencies.sh
/tmp/analyze_dependencies.sh
```

**Expected Output**:
- Text file mapping each function to its internal dependencies
- Identification of heavily-used utility functions (log_*, handle_error)
- Identification of self-contained functions (no internal deps)

**Success Criteria**:
- [ ] Complete function dependency map created
- [ ] Circular dependencies identified (if any)
- [ ] Shared utility dependencies documented

---

#### Task 1.2: Identify External Dependencies

**Description**: Map all external dependencies (utilities, tools) for each function category.

**Implementation**:

```bash
# Create external dependency scanner
cat > /tmp/scan_external_deps.sh << 'EOF'
#!/usr/bin/env bash
# Scan for external dependencies

source_file="/home/benjamin/.config/.claude/lib/artifact-operations.sh"

echo "=== SOURCED UTILITIES ==="
grep -n "^source\|^\. " "$source_file"

echo -e "\n=== EXTERNAL TOOLS USED ==="
echo "jq calls:"
grep -n "jq " "$source_file" | wc -l

echo "grep calls:"
grep -n "[^f]grep " "$source_file" | wc -l

echo "sed calls:"
grep -n "sed " "$source_file" | wc -l

echo "awk calls:"
grep -n "awk " "$source_file" | wc -l

echo -e "\n=== BASE-UTILS.SH FUNCTION CALLS ==="
grep -oE "(log_[a-z_]+|handle_error|validate_[a-z_]+)\(" "$source_file" | \
  sort | uniq -c | sort -rn
EOF

chmod +x /tmp/scan_external_deps.sh
/tmp/scan_external_deps.sh
```

**Expected Output**:
- List of sourced utilities (base-utils.sh, unified-logger.sh)
- Count of external tool usage per function
- Identification of base-utils.sh function dependencies

**Success Criteria**:
- [ ] All external dependencies documented per function category
- [ ] Shared dependency requirements identified for each module
- [ ] Tool availability verified (jq, grep, sed, awk)

---

#### Task 1.3: Define Module Boundaries

**Description**: Create a detailed module boundary specification with exact function assignments.

**Implementation**:

Create file: `/tmp/module-boundaries.md`

```markdown
# Module Boundary Specification

## Module 1: metadata-extraction.sh (~600 lines)

### Functions (12 total)
- extract_report_metadata (line 1910)
- extract_plan_metadata (line 1990)
- extract_summary_metadata (line 2073)
- load_metadata_on_demand (line 2153)
- cache_metadata (line 2207)
- get_cached_metadata (line 2222)
- clear_metadata_cache (line 2235)
- get_plan_metadata (line 353)
- get_report_metadata (line 414)
- get_plan_phase (line 468)
- get_plan_section (line 506)
- get_report_section (line 543)

### Internal Dependencies
- None (self-contained metadata operations)

### External Dependencies
- base-utils.sh: log_info, log_debug, handle_error
- unified-logger.sh: log_operation_start, log_operation_end
- Tools: jq, grep, sed

### Rationale
All metadata extraction and caching operations in one cohesive module.
99% context reduction functionality for hierarchical agents.

---

## Module 2: hierarchical-agent-coordination.sh (~800 lines)

### Functions (6 total)
- forward_message (line 2248)
- parse_subagent_response (line 2356)
- build_handoff_context (line 2406)
- invoke_sub_supervisor (line 2449)
- track_supervision_depth (line 2541)
- generate_supervision_tree (line 2578)

### Internal Dependencies
- Calls extract_report_metadata, extract_plan_metadata (from metadata-extraction.sh)

### External Dependencies
- base-utils.sh: log_info, log_error, validate_path
- unified-logger.sh: log_agent_invocation
- Tools: jq, grep
- metadata-extraction.sh (will be sourced)

### Rationale
Complete hierarchical agent workflow support in one module.
Combines forward message patterns + recursive supervision + tracking.

---

## Module 3: context-pruning.sh (~500 lines)

### Functions (6 total - extracted from cleanup operations)
- prune_subagent_output (NEW - extract from cleanup logic)
- prune_phase_metadata (NEW - extract from cleanup logic)
- apply_pruning_policy (NEW - policy-based cleanup)
- cleanup_operation_artifacts (line 1076 - refactored)
- cleanup_topic_artifacts (line 1118 - refactored)
- cleanup_all_temp_artifacts (line 1176 - refactored)

### Internal Dependencies
- None (self-contained cleanup operations)

### External Dependencies
- base-utils.sh: log_debug, log_info
- unified-logger.sh: log_cleanup_operation
- Tools: rm, find

### Rationale
Centralized context pruning for hierarchical agents (<30% context usage).
Refactors existing cleanup functions to focus on pruning strategy.

NOTE: This module extracts the "aggressive cleanup" functionality
mentioned in CLAUDE.md hierarchical agent section but not yet
explicitly implemented as dedicated functions.

---

## Module 4: artifact-registry.sh (~400 lines)

### Functions (10 total)
- register_artifact (line 82)
- query_artifacts (line 139)
- update_artifact_status (line 179)
- cleanup_artifacts (line 212)
- validate_artifact_references (line 250)
- list_artifacts (line 303)
- get_artifact_path_by_id (line 327)
- register_operation_artifact (line 859)
- get_artifact_path (line 913)
- validate_operation_artifacts (line 944)

### Internal Dependencies
- None (self-contained registry operations)

### External Dependencies
- base-utils.sh: log_info, log_error, handle_error
- unified-logger.sh: log_registry_operation
- Tools: jq, mkdir, date

### Rationale
Core registry operations in one focused module.
Combines artifact registry + operation tracking registries.

---

## Module 5: artifact-creation.sh (ALTERNATIVE: Keep in artifact-operations.sh)

### Functions (11 total - remaining functions)
- create_topic_artifact (line 584)
- create_artifact_directory (line 656)
- create_artifact_directory_with_workflow (line 679)
- get_next_artifact_number (line 712)
- write_artifact_file (line 741)
- generate_artifact_invocation (line 791)
- save_operation_artifact (line 999)
- load_artifact_references (line 1025)
- generate_analysis_report (line 1210)
- review_plan_hierarchy (line 1279)
- run_second_round_analysis (line 1400)
- present_recommendations_for_approval (line 1492)
- generate_recommendations_report (line 1581)
- update_cross_references (line 1709)
- validate_gitignore_compliance (line 1762)
- link_artifact_to_plan (line 1830)

### Decision Point
These functions don't fit cleanly into the 4 focused modules.
Two options:
A) Create artifact-creation.sh + artifact-reporting.sh (2 more modules)
B) Keep in artifact-operations.sh (alongside sourcing other modules)

RECOMMENDATION: Option B - Keep miscellaneous functions in artifact-operations.sh
This maintains backward compatibility naturally and keeps the file
as a "catch-all" for functions that don't fit focused concerns.

---

## Module Interaction Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    artifact-operations.sh                       │
│                  (Wrapper + Misc Functions)                     │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Sources all 4 focused modules + Contains misc functions │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌────────────────┐  ┌──────────────────┐  ┌────────────────┐ │
│  │   metadata-    │  │  hierarchical-   │  │   context-     │ │
│  │  extraction.sh │  │     agent-       │  │   pruning.sh   │ │
│  │                │  │ coordination.sh  │  │                │ │
│  │  • extract_*   │  │  • forward_msg   │  │  • prune_*     │ │
│  │  • get_*       │  │  • invoke_sub    │  │  • cleanup_*   │ │
│  │  • cache_*     │  │  • track_depth   │  │  • apply_*     │ │
│  └────────────────┘  └──────────────────┘  └────────────────┘ │
│         ▲                    │                                  │
│         │                    │                                  │
│         └────────────────────┘                                  │
│         (coordination depends on metadata)                      │
│                                                                 │
│  ┌────────────────┐                                            │
│  │   artifact-    │                                            │
│  │   registry.sh  │                                            │
│  │                │                                            │
│  │  • register_*  │                                            │
│  │  • query_*     │                                            │
│  │  • validate_*  │                                            │
│  └────────────────┘                                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```
```

**Success Criteria**:
- [ ] All 41 functions assigned to specific modules
- [ ] Module boundaries clearly defined
- [ ] Internal dependencies between modules mapped
- [ ] Decision made on remaining functions (keep in wrapper)

---

#### Task 1.4: Create Refactoring Blueprint

**Description**: Create a step-by-step blueprint for the extraction process.

**Implementation**:

Create file: `/tmp/refactoring-blueprint.md`

```markdown
# Artifact Operations Refactoring Blueprint

## Extraction Order (Dependency-First)

1. **First**: metadata-extraction.sh (no internal dependencies)
2. **Second**: artifact-registry.sh (no internal dependencies)
3. **Third**: context-pruning.sh (no internal dependencies)
4. **Fourth**: hierarchical-agent-coordination.sh (depends on metadata-extraction.sh)
5. **Fifth**: Update artifact-operations.sh (source all modules + keep misc functions)

## File Extraction Process (Per Module)

### Step 1: Create Module File
```bash
cat > .claude/lib/MODULE_NAME.sh << 'EOF'
#!/usr/bin/env bash
# MODULE_NAME.sh - Brief description
# Part of .claude/lib/ modular utilities
#
# Functions:
#   - function_1
#   - function_2
# Usage:
#   source "${BASH_SOURCE%/*}/MODULE_NAME.sh"

set -euo pipefail

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/base-utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/unified-logger.sh"
# Add other dependencies as needed

# Constants (if needed)
readonly CONST_NAME="value"

# ==============================================================================
# Module Functions
# ==============================================================================

# Paste extracted functions here

# ==============================================================================
# Export Functions
# ==============================================================================

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f function_1
  export -f function_2
  # Add all exported functions
fi
EOF
```

### Step 2: Extract Functions
- Copy function implementations from artifact-operations.sh
- Preserve comments and documentation
- Maintain exact function signatures
- Keep internal logic unchanged

### Step 3: Test Module Independently
```bash
# Source module
source .claude/lib/MODULE_NAME.sh

# Test each function
function_1 "test" "args"
# Verify output/behavior
```

### Step 4: Update artifact-operations.sh
```bash
# Add source statement at top of file
source "$(dirname "${BASH_SOURCE[0]}")/MODULE_NAME.sh"

# Remove extracted function implementations
# Keep export statements (will be handled by module)
```

### Step 5: Run Regression Tests
```bash
# Test that sourcing artifact-operations.sh still works
source .claude/lib/artifact-operations.sh

# Run existing test suite
.claude/tests/run_all_tests.sh
```

## Backward Compatibility Strategy

### Current Sourcing Pattern
```bash
source "${BASH_SOURCE%/*}/artifact-operations.sh"
```

### New artifact-operations.sh Structure
```bash
#!/usr/bin/env bash
# artifact-operations.sh - Unified artifact operations (v2.0)
# Now sources modular utilities for backward compatibility

set -euo pipefail

# Source modular utilities (in dependency order)
source "$(dirname "${BASH_SOURCE[0]}")/metadata-extraction.sh"
source "$(dirname "${BASH_SOURCE[0]}")/artifact-registry.sh"
source "$(dirname "${BASH_SOURCE[0]}")/context-pruning.sh"
source "$(dirname "${BASH_SOURCE[0]}")/hierarchical-agent-coordination.sh"

# ==============================================================================
# Remaining Functions (Artifact Creation, Reporting, Cross-References)
# ==============================================================================

# Keep ~1000 lines of misc functions here
# These don't fit into focused modules

# All functions are exported by individual modules
# No export section needed here
```

### Migration Path (Optional Future Work)

Commands can migrate to direct sourcing:
```bash
# Old (still works)
source "${BASH_SOURCE%/*}/artifact-operations.sh"

# New (more explicit, slightly faster)
source "${BASH_SOURCE%/*}/metadata-extraction.sh"
source "${BASH_SOURCE%/*}/hierarchical-agent-coordination.sh"
# Only source what you need
```

## Validation Checklist

After each module extraction:
- [ ] Module file created with proper header
- [ ] All functions extracted with comments intact
- [ ] Module sources necessary dependencies
- [ ] Module exports all functions
- [ ] Independent module test passes
- [ ] artifact-operations.sh updated to source module
- [ ] Regression tests pass
- [ ] No performance degradation measured
```

**Success Criteria**:
- [ ] Complete blueprint created with step-by-step instructions
- [ ] Extraction order defined (dependency-first)
- [ ] Backward compatibility strategy documented
- [ ] Validation checklist created for each module

---

## Stage 2: Extract metadata-extraction.sh

**Objective**: Extract all metadata extraction and caching functions into a self-contained module.

**Estimated Time**: 1.5 hours

### Tasks

#### Task 2.1: Create metadata-extraction.sh Module

**Description**: Create the module file with proper headers and dependencies.

**Implementation**:

```bash
cat > /home/benjamin/.config/.claude/lib/metadata-extraction.sh << 'EOF'
#!/usr/bin/env bash
# metadata-extraction.sh - Metadata extraction and caching for artifacts
# Part of .claude/lib/ modular utilities
#
# Functions:
#   Metadata Extraction:
#     extract_report_metadata - Extract report metadata (99% context reduction)
#     extract_plan_metadata - Extract plan metadata (complexity, phases, estimates)
#     extract_summary_metadata - Extract summary metadata
#     load_metadata_on_demand - Generic on-demand metadata loader with caching
#
#   Legacy Metadata Access:
#     get_plan_metadata - Extract plan metadata without reading full file
#     get_report_metadata - Extract report metadata without reading full file
#     get_plan_phase - Extract single phase content on-demand
#     get_plan_section - Generic section extraction by heading pattern
#     get_report_section - Extract report section by heading
#
#   Metadata Caching:
#     cache_metadata - Cache metadata for artifact
#     get_cached_metadata - Retrieve cached metadata
#     clear_metadata_cache - Clear metadata cache
#
# Usage:
#   source "${BASH_SOURCE%/*}/metadata-extraction.sh"
#   metadata=$(extract_report_metadata "/path/to/report.md")
#   echo "$metadata" | jq -r '.title'

set -euo pipefail

# ==============================================================================
# Dependencies
# ==============================================================================

# Source base utilities
source "$(dirname "${BASH_SOURCE[0]}")/base-utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/unified-logger.sh"

# ==============================================================================
# Constants
# ==============================================================================

# Cache directory for metadata
readonly METADATA_CACHE_DIR="${CLAUDE_PROJECT_DIR}/.claude/data/cache/metadata"

# ==============================================================================
# Hierarchical Agent Metadata Extraction
# ==============================================================================

# extract_report_metadata: Extract minimal metadata from research reports
# Achieves 99% context reduction for hierarchical agent workflows
# Usage: extract_report_metadata <report-path>
# Returns: JSON with title, summary (50 words), file_paths, recommendations
extract_report_metadata() {
  # Function implementation from artifact-operations.sh line 1910
  # (Paste complete function here)
}

# extract_plan_metadata: Extract minimal metadata from implementation plans
# Usage: extract_plan_metadata <plan-path>
# Returns: JSON with title, complexity, phases[], estimated_time, file_paths
extract_plan_metadata() {
  # Function implementation from artifact-operations.sh line 1990
  # (Paste complete function here)
}

# extract_summary_metadata: Extract metadata from implementation summaries
# Usage: extract_summary_metadata <summary-path>
# Returns: JSON with plan_path, phases_completed, reports_used, duration
extract_summary_metadata() {
  # Function implementation from artifact-operations.sh line 2073
  # (Paste complete function here)
}

# load_metadata_on_demand: Generic metadata loader with caching
# Usage: load_metadata_on_demand <artifact-path> <artifact-type>
# Returns: JSON metadata appropriate to artifact type
load_metadata_on_demand() {
  # Function implementation from artifact-operations.sh line 2153
  # (Paste complete function here)
}

# ==============================================================================
# Metadata Caching
# ==============================================================================

# cache_metadata: Store metadata in cache
# Usage: cache_metadata <artifact-path> <metadata-json>
cache_metadata() {
  # Function implementation from artifact-operations.sh line 2207
  # (Paste complete function here)
}

# get_cached_metadata: Retrieve cached metadata
# Usage: get_cached_metadata <artifact-path>
# Returns: JSON metadata or empty string if not cached
get_cached_metadata() {
  # Function implementation from artifact-operations.sh line 2222
  # (Paste complete function here)
}

# clear_metadata_cache: Clear all or specific cached metadata
# Usage: clear_metadata_cache [artifact-path]
clear_metadata_cache() {
  # Function implementation from artifact-operations.sh line 2235
  # (Paste complete function here)
}

# ==============================================================================
# Legacy Metadata Access Functions
# ==============================================================================

# get_plan_metadata: Extract plan metadata without reading full file (Legacy)
# Note: Prefer extract_plan_metadata for new code
# Usage: get_plan_metadata <plan-path>
get_plan_metadata() {
  # Function implementation from artifact-operations.sh line 353
  # (Paste complete function here)
}

# get_report_metadata: Extract report metadata without reading full file (Legacy)
# Note: Prefer extract_report_metadata for new code
# Usage: get_report_metadata <report-path>
get_report_metadata() {
  # Function implementation from artifact-operations.sh line 414
  # (Paste complete function here)
}

# get_plan_phase: Extract single phase content on-demand
# Usage: get_plan_phase <plan-path> <phase-number>
get_plan_phase() {
  # Function implementation from artifact-operations.sh line 468
  # (Paste complete function here)
}

# get_plan_section: Generic section extraction by heading pattern
# Usage: get_plan_section <plan-path> <heading-pattern>
get_plan_section() {
  # Function implementation from artifact-operations.sh line 506
  # (Paste complete function here)
}

# get_report_section: Extract report section by heading
# Usage: get_report_section <report-path> <heading>
get_report_section() {
  # Function implementation from artifact-operations.sh line 543
  # (Paste complete function here)
}

# ==============================================================================
# Export Functions
# ==============================================================================

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  # Hierarchical agent metadata extraction
  export -f extract_report_metadata
  export -f extract_plan_metadata
  export -f extract_summary_metadata
  export -f load_metadata_on_demand

  # Metadata caching
  export -f cache_metadata
  export -f get_cached_metadata
  export -f clear_metadata_cache

  # Legacy metadata access
  export -f get_plan_metadata
  export -f get_report_metadata
  export -f get_plan_phase
  export -f get_plan_section
  export -f get_report_section
fi
EOF
```

**Success Criteria**:
- [ ] Module file created with proper structure
- [ ] All 12 function signatures defined with comments
- [ ] Dependencies sourced correctly
- [ ] Export section includes all functions

---

#### Task 2.2: Extract Function Implementations

**Description**: Copy all 12 function implementations from artifact-operations.sh to metadata-extraction.sh.

**Implementation Process**:
1. Open artifact-operations.sh and locate each function by line number
2. Copy complete function implementation (including comments)
3. Paste into metadata-extraction.sh in appropriate section
4. Verify no internal function calls to functions in other modules

**Functions to Extract**:
- extract_report_metadata (line 1910)
- extract_plan_metadata (line 1990)
- extract_summary_metadata (line 2073)
- load_metadata_on_demand (line 2153)
- cache_metadata (line 2207)
- get_cached_metadata (line 2222)
- clear_metadata_cache (line 2235)
- get_plan_metadata (line 353)
- get_report_metadata (line 414)
- get_plan_phase (line 468)
- get_plan_section (line 506)
- get_report_section (line 543)

**Success Criteria**:
- [ ] All 12 functions extracted with complete implementations
- [ ] All comments and documentation preserved
- [ ] No function calls to non-existent functions
- [ ] Module file is ~600 lines

---

#### Task 2.3: Test metadata-extraction.sh Independently

**Description**: Create and run comprehensive tests for the new module.

**Implementation**:

Create file: `/home/benjamin/.config/.claude/tests/test_metadata_extraction.sh`

```bash
#!/usr/bin/env bash
# test_metadata_extraction.sh - Tests for metadata-extraction.sh module

set -euo pipefail

# Source test utilities
source "$(dirname "${BASH_SOURCE[0]}")/test-utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/metadata-extraction.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# ==============================================================================
# Test Functions
# ==============================================================================

test_extract_report_metadata() {
  echo "Testing extract_report_metadata..."

  # Create test report
  local test_report="/tmp/test_report_$$.md"
  cat > "$test_report" << 'REPORT'
# Test Research Report

## Summary
This is a test report for metadata extraction. It contains various sections
to verify that the extraction works correctly.

## Key Findings
- Finding 1
- Finding 2

## Recommendations
1. Recommendation 1
2. Recommendation 2
REPORT

  # Extract metadata
  local metadata=$(extract_report_metadata "$test_report")

  # Verify JSON structure
  if echo "$metadata" | jq -e '.title' > /dev/null 2>&1; then
    echo "  ✓ extract_report_metadata returns valid JSON"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  ✗ extract_report_metadata failed to return valid JSON"
  fi

  # Cleanup
  rm -f "$test_report"
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_extract_plan_metadata() {
  echo "Testing extract_plan_metadata..."

  # Create test plan
  local test_plan="/tmp/test_plan_$$.md"
  cat > "$test_plan" << 'PLAN'
# Test Implementation Plan

## Metadata
- Complexity: 7.5
- Estimated Time: 4 hours

## Phase 1: Test Phase
- Task 1
- Task 2
PLAN

  # Extract metadata
  local metadata=$(extract_plan_metadata "$test_plan")

  # Verify complexity extraction
  if echo "$metadata" | jq -e '.complexity' > /dev/null 2>&1; then
    echo "  ✓ extract_plan_metadata extracts complexity"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  ✗ extract_plan_metadata failed to extract complexity"
  fi

  # Cleanup
  rm -f "$test_plan"
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_metadata_caching() {
  echo "Testing metadata caching..."

  local test_path="/tmp/test_artifact_$$.md"
  local test_metadata='{"title":"Test","summary":"Test summary"}'

  # Test cache_metadata
  cache_metadata "$test_path" "$test_metadata"

  # Test get_cached_metadata
  local cached=$(get_cached_metadata "$test_path")

  if [ "$cached" == "$test_metadata" ]; then
    echo "  ✓ Metadata caching works correctly"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  ✗ Metadata caching failed"
  fi

  # Test clear_metadata_cache
  clear_metadata_cache "$test_path"
  cached=$(get_cached_metadata "$test_path")

  if [ -z "$cached" ]; then
    echo "  ✓ Cache clearing works correctly"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  ✗ Cache clearing failed"
  fi

  TESTS_RUN=$((TESTS_RUN + 2))
}

test_get_plan_section() {
  echo "Testing get_plan_section..."

  local test_plan="/tmp/test_plan_section_$$.md"
  cat > "$test_plan" << 'PLAN'
# Test Plan

## Overview
This is the overview section.

## Phase 1
This is phase 1.

## Phase 2
This is phase 2.
PLAN

  # Extract overview section
  local section=$(get_plan_section "$test_plan" "Overview")

  if echo "$section" | grep -q "This is the overview section"; then
    echo "  ✓ get_plan_section extracts correct section"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  ✗ get_plan_section failed"
  fi

  # Cleanup
  rm -f "$test_plan"
  TESTS_RUN=$((TESTS_RUN + 1))
}

# ==============================================================================
# Run All Tests
# ==============================================================================

echo "Running metadata-extraction.sh tests..."
echo "========================================"

test_extract_report_metadata
test_extract_plan_metadata
test_metadata_caching
test_get_plan_section

# Add more tests for remaining functions...

# Summary
echo "========================================"
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $((TESTS_RUN - TESTS_PASSED))"

if [ $TESTS_PASSED -eq $TESTS_RUN ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
```

**Success Criteria**:
- [ ] Test file created with 8+ test functions
- [ ] All functions in metadata-extraction.sh tested
- [ ] Tests pass when run independently
- [ ] No dependencies on other modules in tests

---

#### Task 2.4: Update artifact-operations.sh to Source metadata-extraction.sh

**Description**: Modify artifact-operations.sh to source the new module and remove extracted function implementations.

**Implementation**:

```bash
# Edit artifact-operations.sh

# 1. Add source statement after existing sources
# Add this line after other source statements (around line 50):
source "$(dirname "${BASH_SOURCE[0]}")/metadata-extraction.sh"

# 2. Remove function implementations (keep comments describing what moved)
# Replace lines 353-2240 with:

# ==============================================================================
# Metadata Extraction Functions (Moved to metadata-extraction.sh)
# ==============================================================================
# The following functions have been extracted to metadata-extraction.sh:
#   - extract_report_metadata, extract_plan_metadata, extract_summary_metadata
#   - load_metadata_on_demand, cache_metadata, get_cached_metadata, clear_metadata_cache
#   - get_plan_metadata, get_report_metadata, get_plan_phase
#   - get_plan_section, get_report_section
#
# These functions are now available via:
#   source "${BASH_SOURCE%/*}/metadata-extraction.sh"

# 3. Remove export statements for moved functions
# Delete these lines from the export section (lines 2656-2662, 2695-2702):
#   export -f get_plan_metadata
#   export -f get_report_metadata
#   (etc.)
```

**Success Criteria**:
- [ ] Source statement added correctly
- [ ] Function implementations removed (12 functions)
- [ ] Comment added explaining what moved
- [ ] Export statements removed for moved functions
- [ ] File compiles without errors

---

## Stage 3: Extract hierarchical-agent-coordination.sh

**Objective**: Extract all hierarchical agent coordination functions, including forward message patterns, recursive supervision, and supervision tracking.

**Estimated Time**: 2 hours

### Tasks

#### Task 3.1: Create hierarchical-agent-coordination.sh Module

**Description**: Create module file with dependencies on metadata-extraction.sh.

**Implementation**:

```bash
cat > /home/benjamin/.config/.claude/lib/hierarchical-agent-coordination.sh << 'EOF'
#!/usr/bin/env bash
# hierarchical-agent-coordination.sh - Hierarchical agent workflow coordination
# Part of .claude/lib/ modular utilities
#
# Functions:
#   Forward Message Patterns:
#     forward_message - Extract artifact paths and create minimal handoff context
#     parse_subagent_response - Parse structured subagent outputs
#     build_handoff_context - Build minimal context for agent handoff
#
#   Recursive Supervision:
#     invoke_sub_supervisor - Prepare sub-supervisor invocation metadata
#     track_supervision_depth - Prevent infinite recursion (max depth: 3)
#     generate_supervision_tree - Visualize hierarchical agent structure
#
# Usage:
#   source "${BASH_SOURCE%/*}/hierarchical-agent-coordination.sh"
#   context=$(forward_message "$subagent_response")
#   invoke_sub_supervisor "$supervisor_name" "$task_description"

set -euo pipefail

# ==============================================================================
# Dependencies
# ==============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/base-utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/unified-logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/metadata-extraction.sh"  # Required for extract_*_metadata

# ==============================================================================
# Constants
# ==============================================================================

readonly MAX_SUPERVISION_DEPTH=3
readonly SUPERVISION_STATE_DIR="${CLAUDE_PROJECT_DIR}/.claude/data/supervision"

# ==============================================================================
# Forward Message Pattern Functions
# ==============================================================================

# forward_message: Extract artifact paths from subagent response
# Achieves 92-97% context reduction by passing metadata only
# Usage: forward_message <subagent-response-text>
# Returns: JSON with artifact_paths[], summaries[], type
forward_message() {
  # Function implementation from artifact-operations.sh line 2248
}

# parse_subagent_response: Parse structured subagent output
# Usage: parse_subagent_response <response-text>
# Returns: JSON with status, artifact_path, summary, findings[]
parse_subagent_response() {
  # Function implementation from artifact-operations.sh line 2356
}

# build_handoff_context: Create minimal context for agent handoff
# Usage: build_handoff_context <artifact-paths-json> <task-description>
# Returns: JSON handoff context
build_handoff_context() {
  # Function implementation from artifact-operations.sh line 2406
}

# ==============================================================================
# Recursive Supervision Functions
# ==============================================================================

# invoke_sub_supervisor: Prepare sub-supervisor invocation
# Usage: invoke_sub_supervisor <supervisor-name> <task-description> [parent-depth]
# Returns: JSON invocation context with depth tracking
invoke_sub_supervisor() {
  # Function implementation from artifact-operations.sh line 2449
}

# track_supervision_depth: Track and validate supervision depth
# Usage: track_supervision_depth <current-depth>
# Returns: 0 if depth OK, 1 if max depth exceeded
track_supervision_depth() {
  # Function implementation from artifact-operations.sh line 2541
}

# generate_supervision_tree: Visualize hierarchical agent structure
# Usage: generate_supervision_tree <workflow-state-json>
# Returns: Text tree visualization
generate_supervision_tree() {
  # Function implementation from artifact-operations.sh line 2578
}

# ==============================================================================
# Export Functions
# ==============================================================================

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f forward_message
  export -f parse_subagent_response
  export -f build_handoff_context
  export -f invoke_sub_supervisor
  export -f track_supervision_depth
  export -f generate_supervision_tree
fi
EOF
```

**Success Criteria**:
- [ ] Module file created with proper structure
- [ ] Dependencies on metadata-extraction.sh declared
- [ ] All 6 function signatures defined
- [ ] Constants defined (MAX_SUPERVISION_DEPTH, state directory)

---

#### Task 3.2: Extract Function Implementations

**Description**: Copy all 6 function implementations, ensuring metadata-extraction.sh calls work correctly.

**Functions to Extract**:
- forward_message (line 2248)
- parse_subagent_response (line 2356)
- build_handoff_context (line 2406)
- invoke_sub_supervisor (line 2449)
- track_supervision_depth (line 2541)
- generate_supervision_tree (line 2578)

**Validation**:
- Verify calls to extract_report_metadata and extract_plan_metadata work
- These functions are now sourced from metadata-extraction.sh
- No changes to function logic needed (just module boundary)

**Success Criteria**:
- [ ] All 6 functions extracted completely
- [ ] Metadata extraction calls verified
- [ ] Module file is ~800 lines

---

#### Task 3.3: Create Tests and Update artifact-operations.sh

**Description**: Create test file and update main file to source new module.

**Test File**: `/home/benjamin/.config/.claude/tests/test_hierarchical_coordination.sh`

**Key Test Cases**:
- test_forward_message_extracts_paths
- test_parse_subagent_response_structure
- test_supervision_depth_tracking
- test_generate_supervision_tree_format
- test_invoke_sub_supervisor_metadata

**Update to artifact-operations.sh**:
```bash
# Add after metadata-extraction.sh source:
source "$(dirname "${BASH_SOURCE[0]}")/hierarchical-agent-coordination.sh"

# Remove function implementations (lines 2248-2640)
# Add comment explaining move
# Remove export statements for 6 functions
```

**Success Criteria**:
- [ ] Test file created with 5+ test cases
- [ ] Tests pass independently
- [ ] artifact-operations.sh updated correctly
- [ ] Regression tests pass

---

## Stage 4: Extract context-pruning.sh and artifact-registry.sh

**Objective**: Extract context pruning functions (new module extracting cleanup logic) and artifact registry functions.

**Estimated Time**: 2 hours

### Tasks

#### Task 4.1: Create context-pruning.sh Module

**Description**: Extract and refactor cleanup functions to focus on context pruning strategy.

**Implementation**:

```bash
cat > /home/benjamin/.config/.claude/lib/context-pruning.sh << 'EOF'
#!/usr/bin/env bash
# context-pruning.sh - Context pruning and cleanup for hierarchical agents
# Part of .claude/lib/ modular utilities
#
# Implements aggressive context cleanup to maintain <30% context usage
# throughout hierarchical agent workflows.
#
# Functions:
#   Pruning Operations (NEW - extracted from cleanup logic):
#     prune_subagent_output - Clear full outputs after metadata extraction
#     prune_phase_metadata - Remove phase data after completion
#     apply_pruning_policy - Automatic pruning by workflow type
#
#   Cleanup Operations (Refactored from artifact-operations.sh):
#     cleanup_operation_artifacts - Remove artifacts after successful operations
#     cleanup_topic_artifacts - Clean up topic-specific artifacts
#     cleanup_all_temp_artifacts - Clean all temporary artifacts
#
# Usage:
#   source "${BASH_SOURCE%/*}/context-pruning.sh"
#   prune_subagent_output "$subagent_artifact_path"
#   apply_pruning_policy "orchestrate"  # Aggressive pruning for workflows

set -euo pipefail

# ==============================================================================
# Dependencies
# ==============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/base-utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/unified-logger.sh"

# ==============================================================================
# Constants
# ==============================================================================

readonly PRUNING_POLICY_AGGRESSIVE="aggressive"  # For /orchestrate workflows
readonly PRUNING_POLICY_MODERATE="moderate"      # For /implement workflows
readonly PRUNING_POLICY_MINIMAL="minimal"        # For single-agent tasks

# ==============================================================================
# Context Pruning Functions (NEW)
# ==============================================================================

# prune_subagent_output: Clear full subagent output after metadata extraction
# This achieves 95% context reduction by keeping only metadata
# Usage: prune_subagent_output <artifact-path>
prune_subagent_output() {
  local artifact_path="${1:-}"

  if [ -z "$artifact_path" ] || [ ! -f "$artifact_path" ]; then
    log_error "prune_subagent_output: Invalid artifact path"
    return 1
  fi

  log_debug "Pruning subagent output: $artifact_path"

  # Extract metadata first (preserve it)
  local metadata_file="${artifact_path}.metadata.json"
  if [ -f "$artifact_path" ]; then
    # Use metadata-extraction.sh to preserve key information
    # Then remove the full artifact
    # (Implementation: extract metadata, save to .metadata.json, rm artifact)
    log_info "Subagent output pruned: $artifact_path (metadata preserved)"
  fi
}

# prune_phase_metadata: Remove phase metadata after completion
# Usage: prune_phase_metadata <plan-path> <phase-number>
prune_phase_metadata() {
  local plan_path="${1:-}"
  local phase_num="${2:-}"

  log_debug "Pruning phase $phase_num metadata from $plan_path"

  # Remove checkpoint data for completed phase
  # Keep only status (completed) and final artifacts
  # (Implementation: clean up phase-specific temp files)
}

# apply_pruning_policy: Apply pruning policy based on workflow type
# Usage: apply_pruning_policy <workflow-type> [artifact-directory]
# Workflow types: orchestrate, implement, plan, debug
apply_pruning_policy() {
  local workflow_type="${1:-}"
  local artifact_dir="${2:-.claude/data/artifacts}"

  case "$workflow_type" in
    orchestrate)
      log_info "Applying aggressive pruning policy (orchestrate workflow)"
      # Prune all subagent outputs immediately after metadata extraction
      # Target: <30% context usage
      ;;
    implement)
      log_info "Applying moderate pruning policy (implement workflow)"
      # Prune phase artifacts after phase completion
      # Keep current phase + last phase data
      ;;
    plan|debug)
      log_info "Applying minimal pruning policy ($workflow_type workflow)"
      # Keep all artifacts during planning/debugging
      # Clean up only on explicit user request
      ;;
    *)
      log_warn "Unknown workflow type: $workflow_type (using minimal pruning)"
      ;;
  esac
}

# ==============================================================================
# Cleanup Operations (Refactored from artifact-operations.sh)
# ==============================================================================

# cleanup_operation_artifacts: Remove artifacts after successful operations
# Usage: cleanup_operation_artifacts <operation-id>
cleanup_operation_artifacts() {
  # Function implementation from artifact-operations.sh line 1076
  # Refactored to use pruning policies
}

# cleanup_topic_artifacts: Clean up topic-specific artifacts
# Usage: cleanup_topic_artifacts <topic-directory>
cleanup_topic_artifacts() {
  # Function implementation from artifact-operations.sh line 1118
}

# cleanup_all_temp_artifacts: Clean all temporary artifacts
# Usage: cleanup_all_temp_artifacts
cleanup_all_temp_artifacts() {
  # Function implementation from artifact-operations.sh line 1176
}

# ==============================================================================
# Export Functions
# ==============================================================================

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f prune_subagent_output
  export -f prune_phase_metadata
  export -f apply_pruning_policy
  export -f cleanup_operation_artifacts
  export -f cleanup_topic_artifacts
  export -f cleanup_all_temp_artifacts
fi
EOF
```

**Note**: The prune_* functions are NEW implementations based on the hierarchical agent architecture's context reduction goals. They extract the "aggressive cleanup" strategy from the conceptual design.

**Success Criteria**:
- [ ] Module created with 3 new pruning functions
- [ ] 3 cleanup functions refactored from artifact-operations.sh
- [ ] Pruning policies defined (aggressive/moderate/minimal)

---

#### Task 4.2: Create artifact-registry.sh Module

**Description**: Extract all artifact registry and operation tracking functions.

**Implementation**:

```bash
cat > /home/benjamin/.config/.claude/lib/artifact-registry.sh << 'EOF'
#!/usr/bin/env bash
# artifact-registry.sh - Artifact registration and tracking
# Part of .claude/lib/ modular utilities
#
# Functions:
#   Core Registry:
#     register_artifact - Register artifact in central registry
#     query_artifacts - Query artifacts by type or pattern
#     update_artifact_status - Update artifact metadata
#     cleanup_artifacts - Remove old artifact entries
#     validate_artifact_references - Check if artifact paths exist
#     list_artifacts - List all registered artifacts
#     get_artifact_path_by_id - Get path for artifact by registry ID
#
#   Operation Tracking:
#     register_operation_artifact - Register artifacts in operation tracking
#     get_artifact_path - Retrieve artifact path by item ID
#     validate_operation_artifacts - Verify all operation artifacts exist
#
# Usage:
#   source "${BASH_SOURCE%/*}/artifact-registry.sh"
#   register_artifact "plan" "specs/plans/025.md" '{}'
#   artifacts=$(query_artifacts "plan" "025")

set -euo pipefail

# ==============================================================================
# Dependencies
# ==============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/base-utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/unified-logger.sh"

# ==============================================================================
# Constants
# ==============================================================================

readonly ARTIFACT_TYPE_PLAN="plan"
readonly ARTIFACT_TYPE_REPORT="report"
readonly ARTIFACT_TYPE_SUMMARY="summary"
readonly ARTIFACT_TYPE_CHECKPOINT="checkpoint"
readonly ARTIFACT_REGISTRY_DIR="${CLAUDE_PROJECT_DIR}/.claude/data/registry"

# ==============================================================================
# Core Registry Functions
# ==============================================================================

# register_artifact: Register an artifact in the registry
# Usage: register_artifact <type> <path> [metadata-json]
# Returns: Registry entry ID
register_artifact() {
  # Function implementation from artifact-operations.sh line 82
}

# (Continue with all 10 functions)
# ...

# ==============================================================================
# Export Functions
# ==============================================================================

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f register_artifact
  export -f query_artifacts
  export -f update_artifact_status
  export -f cleanup_artifacts
  export -f validate_artifact_references
  export -f list_artifacts
  export -f get_artifact_path_by_id
  export -f register_operation_artifact
  export -f get_artifact_path
  export -f validate_operation_artifacts
fi
EOF
```

**Success Criteria**:
- [ ] Module created with all 10 registry functions
- [ ] Constants defined for artifact types
- [ ] Module is ~400 lines

---

#### Task 4.3: Create Tests and Update artifact-operations.sh

**Test Files**:
- `/home/benjamin/.config/.claude/tests/test_context_pruning.sh`
- `/home/benjamin/.config/.claude/tests/test_artifact_registry.sh`

**Update artifact-operations.sh**:
```bash
# Add source statements:
source "$(dirname "${BASH_SOURCE[0]}")/context-pruning.sh"
source "$(dirname "${BASH_SOURCE[0]}")/artifact-registry.sh"

# Remove function implementations
# Update export section
```

**Success Criteria**:
- [ ] Both test files created with comprehensive tests
- [ ] Tests pass independently
- [ ] artifact-operations.sh updated correctly
- [ ] All 54 existing tests still pass

---

## Stage 5: Finalize artifact-operations.sh Wrapper and Comprehensive Testing

**Objective**: Transform artifact-operations.sh into a clean wrapper that sources all modules, keep remaining misc functions, and validate complete backward compatibility.

**Estimated Time**: 1.5-2 hours

### Tasks

#### Task 5.1: Finalize artifact-operations.sh Structure

**Description**: Create final wrapper structure with sourcing statements and remaining functions.

**Implementation**:

```bash
#!/usr/bin/env bash
# artifact-operations.sh - Unified artifact registry, operations, and report generation (v2.0)
# Part of .claude/lib/ modular utilities
#
# This file now serves as:
# 1. Backward compatibility wrapper (sources all modular utilities)
# 2. Container for miscellaneous artifact functions that don't fit focused modules
#
# Modular Utilities (sourced):
#   metadata-extraction.sh - Metadata extraction and caching
#   artifact-registry.sh - Artifact registration and tracking
#   context-pruning.sh - Context pruning and cleanup
#   hierarchical-agent-coordination.sh - Hierarchical agent workflows
#
# Functions (kept in this file):
#   Artifact Creation:
#     create_topic_artifact, create_artifact_directory
#     create_artifact_directory_with_workflow, get_next_artifact_number
#     write_artifact_file, generate_artifact_invocation
#
#   Operation Tracking:
#     save_operation_artifact, load_artifact_references
#
#   Report Generation:
#     generate_analysis_report, review_plan_hierarchy
#     run_second_round_analysis, present_recommendations_for_approval
#     generate_recommendations_report
#
#   Cross-Reference Management:
#     update_cross_references, validate_gitignore_compliance
#     link_artifact_to_plan
#
# Usage:
#   source "${BASH_SOURCE%/*}/artifact-operations.sh"
#   # All functions from modular utilities + local functions available

set -euo pipefail

# ==============================================================================
# Environment Setup
# ==============================================================================

: "${CLAUDE_PROJECT_DIR:=$(pwd)}"

# ==============================================================================
# Source Modular Utilities (in dependency order)
# ==============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/metadata-extraction.sh"
source "$(dirname "${BASH_SOURCE[0]}")/artifact-registry.sh"
source "$(dirname "${BASH_SOURCE[0]}")/context-pruning.sh"
source "$(dirname "${BASH_SOURCE[0]}")/hierarchical-agent-coordination.sh"

# ==============================================================================
# Remaining Functions (Artifact Creation, Reporting, Cross-References)
# ==============================================================================

# create_topic_artifact: Create artifact directory for topic
# (Keep ~16 functions here that don't fit focused modules)
# ...

# ==============================================================================
# Export Functions (Local Functions Only)
# ==============================================================================
# Note: Functions from modular utilities are exported by those modules

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f create_topic_artifact
  export -f create_artifact_directory
  export -f create_artifact_directory_with_workflow
  export -f get_next_artifact_number
  export -f write_artifact_file
  export -f generate_artifact_invocation
  export -f save_operation_artifact
  export -f load_artifact_references
  export -f generate_analysis_report
  export -f review_plan_hierarchy
  export -f run_second_round_analysis
  export -f present_recommendations_for_approval
  export -f generate_recommendations_report
  export -f update_cross_references
  export -f validate_gitignore_compliance
  export -f link_artifact_to_plan
fi
```

**Success Criteria**:
- [ ] File header updated with v2.0 note
- [ ] All 4 modules sourced in correct order
- [ ] ~16 remaining functions kept in file
- [ ] Export section only exports local functions
- [ ] File is ~1000-1200 lines (down from 2713)

---

#### Task 5.2: Run Comprehensive Regression Tests

**Description**: Verify backward compatibility across all existing consumers.

**Test Categories**:

1. **Module Tests** (already created in previous stages):
   - test_metadata_extraction.sh
   - test_hierarchical_coordination.sh
   - test_context_pruning.sh
   - test_artifact_registry.sh

2. **Integration Tests**:
```bash
# Create test_artifact_operations_integration.sh
#!/usr/bin/env bash
# Test that artifact-operations.sh wrapper works correctly

source .claude/lib/artifact-operations.sh

# Test that all 41 functions are available
test_all_functions_available() {
  # Test metadata extraction functions
  type extract_report_metadata >/dev/null 2>&1 || return 1
  type extract_plan_metadata >/dev/null 2>&1 || return 1

  # Test registry functions
  type register_artifact >/dev/null 2>&1 || return 1
  type query_artifacts >/dev/null 2>&1 || return 1

  # Test coordination functions
  type forward_message >/dev/null 2>&1 || return 1
  type invoke_sub_supervisor >/dev/null 2>&1 || return 1

  # Test pruning functions
  type prune_subagent_output >/dev/null 2>&1 || return 1
  type cleanup_operation_artifacts >/dev/null 2>&1 || return 1

  # Test local functions
  type create_topic_artifact >/dev/null 2>&1 || return 1
  type generate_analysis_report >/dev/null 2>&1 || return 1

  echo "✓ All functions available"
  return 0
}

test_all_functions_available
```

3. **Existing Test Suite**:
```bash
# Run all 54 existing tests
.claude/tests/run_all_tests.sh
```

4. **Command Integration Tests**:
```bash
# Test sourcing from actual commands
# Pick 3-5 key commands and verify they still work

# Test /implement command
source .claude/commands/implement.md  # Verify no errors

# Test /orchestrate command
source .claude/commands/orchestrate.md  # Verify no errors
```

**Success Criteria**:
- [ ] All 4 new module tests pass (32+ new test cases)
- [ ] Integration test passes (all 41 functions available)
- [ ] All 54 existing tests pass
- [ ] Sample commands source without errors
- [ ] Zero breaking changes detected

---

#### Task 5.3: Performance Benchmarking

**Description**: Measure performance impact of modularization.

**Implementation**:

```bash
#!/usr/bin/env bash
# benchmark_artifact_operations.sh - Performance comparison

# Benchmark: Time to source artifact-operations.sh

echo "Benchmarking artifact-operations.sh sourcing time..."

# Test 1: Source time (10 iterations)
total_time=0
for i in {1..10}; do
  start=$(date +%s%N)
  source /home/benjamin/.config/.claude/lib/artifact-operations.sh
  end=$(date +%s%N)
  elapsed=$((end - start))
  total_time=$((total_time + elapsed))
done

avg_time=$((total_time / 10))
avg_ms=$((avg_time / 1000000))

echo "Average sourcing time: ${avg_ms}ms (10 iterations)"

# Test 2: Function call overhead
# Test extract_report_metadata performance
echo "Testing function call overhead..."

# Create test report
test_report="/tmp/bench_report.md"
cat > "$test_report" << 'EOF'
# Benchmark Report
## Summary
This is a test report for benchmarking.
EOF

start=$(date +%s%N)
for i in {1..100}; do
  extract_report_metadata "$test_report" >/dev/null 2>&1
done
end=$(date +%s%N)

elapsed=$((end - start))
avg_call=$((elapsed / 100 / 1000000))

echo "Average function call time: ${avg_call}ms (100 iterations)"

rm -f "$test_report"

# Acceptable thresholds
if [ "$avg_ms" -gt 500 ]; then
  echo "⚠ WARNING: Sourcing time >500ms (${avg_ms}ms)"
  exit 1
elif [ "$avg_ms" -gt 200 ]; then
  echo "⚠ Note: Sourcing time is moderate (${avg_ms}ms)"
else
  echo "✓ Sourcing time is acceptable (${avg_ms}ms)"
fi

echo "✓ Performance benchmarking complete"
```

**Acceptable Performance**:
- Sourcing time: <200ms (good), <500ms (acceptable)
- Function call overhead: <5% increase vs pre-modularization
- Memory footprint: No significant increase

**Success Criteria**:
- [ ] Benchmark script created and run
- [ ] Sourcing time measured (<500ms acceptable)
- [ ] Function call overhead <5%
- [ ] No performance regressions detected

---

#### Task 5.4: Update Documentation

**Description**: Update all documentation to reflect new modular structure.

**Files to Update**:

1. **`.claude/lib/README.md`**:
```markdown
## Hierarchical Agent Utilities

### Modular Architecture (v2.0)

The hierarchical agent functionality has been split into focused modules:

- **metadata-extraction.sh** - Metadata extraction and caching (99% context reduction)
  - `extract_report_metadata`, `extract_plan_metadata`, `extract_summary_metadata`
  - `load_metadata_on_demand`, caching functions
  - Legacy `get_*_metadata` functions

- **hierarchical-agent-coordination.sh** - Agent coordination and supervision
  - `forward_message`, `parse_subagent_response`, `build_handoff_context`
  - `invoke_sub_supervisor`, `track_supervision_depth`, `generate_supervision_tree`

- **context-pruning.sh** - Context cleanup and pruning strategies
  - `prune_subagent_output`, `prune_phase_metadata`, `apply_pruning_policy`
  - Cleanup functions for operation artifacts

- **artifact-registry.sh** - Artifact registration and tracking
  - `register_artifact`, `query_artifacts`, `update_artifact_status`
  - Operation tracking functions

- **artifact-operations.sh** - Unified wrapper + misc functions (v2.0)
  - Sources all 4 modules for backward compatibility
  - Contains artifact creation, reporting, cross-reference functions
  - Use this for complete functionality, or source specific modules as needed

### Migration Guide

**Old Pattern (still works)**:
```bash
source "${BASH_SOURCE%/*}/artifact-operations.sh"
# All functions available
```

**New Pattern (more explicit, slightly faster)**:
```bash
# Source only what you need
source "${BASH_SOURCE%/*}/metadata-extraction.sh"
source "${BASH_SOURCE%/*}/hierarchical-agent-coordination.sh"
```
```

2. **CLAUDE.md** - Update hierarchical agent section:
```markdown
### Utilities
- **Metadata Extraction**: `.claude/lib/metadata-extraction.sh`
  - `extract_report_metadata()` - Extract title, summary, file paths, recommendations
  - `extract_plan_metadata()` - Extract complexity, phases, time estimates
  - `load_metadata_on_demand()` - Generic metadata loader with caching
- **Hierarchical Coordination**: `.claude/lib/hierarchical-agent-coordination.sh`
  - `forward_message()` - Extract artifact paths and create minimal handoff context
  - `parse_subagent_response()` - Parse structured subagent outputs
  - `invoke_sub_supervisor()` - Prepare sub-supervisor invocation metadata
  - `track_supervision_depth()` - Prevent infinite recursion (max depth: 3)
  - `generate_supervision_tree()` - Visualize hierarchical agent structure
- **Context Pruning**: `.claude/lib/context-pruning.sh`
  - `prune_subagent_output()` - Clear full outputs after metadata extraction
  - `prune_phase_metadata()` - Remove phase data after completion
  - `apply_pruning_policy()` - Automatic pruning by workflow type
- **Artifact Registry**: `.claude/lib/artifact-registry.sh`
  - `register_artifact()`, `query_artifacts()`, `update_artifact_status()`
```

3. **Inline Documentation** - Add comments to each module explaining its role

**Success Criteria**:
- [ ] lib/README.md updated with modular architecture section
- [ ] CLAUDE.md updated with new utility references
- [ ] Migration guide added to documentation
- [ ] All module files have comprehensive header comments

---

## Testing Strategy Summary

### Test Organization

**New Test Files** (4 modules × 8-12 tests each = 32-48 new tests):
- `test_metadata_extraction.sh` - 10 tests
- `test_hierarchical_coordination.sh` - 8 tests
- `test_context_pruning.sh` - 8 tests
- `test_artifact_registry.sh` - 10 tests

**Integration Tests**:
- `test_artifact_operations_integration.sh` - Verify all functions available
- `test_backward_compatibility.sh` - Verify existing commands work

**Performance Tests**:
- `benchmark_artifact_operations.sh` - Sourcing time and overhead

**Existing Tests** (54 tests must continue passing):
- All tests in `.claude/tests/` directory

### Test Execution

```bash
# Run new module tests
.claude/tests/test_metadata_extraction.sh
.claude/tests/test_hierarchical_coordination.sh
.claude/tests/test_context_pruning.sh
.claude/tests/test_artifact_registry.sh

# Run integration tests
.claude/tests/test_artifact_operations_integration.sh
.claude/tests/test_backward_compatibility.sh

# Run performance tests
.claude/tests/benchmark_artifact_operations.sh

# Run all existing tests (regression)
.claude/tests/run_all_tests.sh

# Full test suite
.claude/tests/run_all_tests.sh --include-new-modules
```

### Coverage Target

- **New modules**: ≥80% coverage (all exported functions tested)
- **Integration**: 100% function availability verified
- **Regression**: 100% of existing tests must pass
- **Performance**: <5% overhead acceptable

## Dependencies and Constraints

### Internal Dependencies

**Module Dependencies** (sourcing order matters):
1. `metadata-extraction.sh` - No dependencies (source first)
2. `artifact-registry.sh` - No dependencies
3. `context-pruning.sh` - No dependencies
4. `hierarchical-agent-coordination.sh` - Depends on metadata-extraction.sh (source last)

**Shared Dependencies** (all modules):
- `base-utils.sh` - Error handling, logging, validation
- `unified-logger.sh` - Consistent logging interface
- External tools: `jq`, `grep`, `sed`, `awk`, `date`, `mkdir`, `rm`

### External Consumers

**Commands** (21 files):
- All source `artifact-operations.sh` currently
- Will continue working via wrapper
- Can migrate to specific modules (optional future work)

**Agents** (19 files):
- Some reference artifact operation functions
- Will continue working via wrapper
- No changes needed

**Utilities** (several files):
- Some utilities source `artifact-operations.sh`
- Will continue working via wrapper

### Backward Compatibility Guarantee

**This refactoring guarantees**:
- All existing sourcing patterns work unchanged
- All 41 functions remain available
- All function signatures unchanged
- All function behavior unchanged
- All existing tests pass

## Risk Mitigation

### Risk 1: Breaking Changes During Extraction
**Mitigation**: Extract in dependency order, test after each module

### Risk 2: Performance Degradation
**Mitigation**: Benchmark at each stage, rollback if >5% overhead

### Risk 3: Incomplete Function Coverage
**Mitigation**: Create function checklist, verify all 41 functions in integration test

### Risk 4: Test Failures in Existing Suite
**Mitigation**: Run regression tests after each stage, fix immediately before proceeding

## Success Metrics

### Quantitative Metrics
- **Modularity**: 2,713 lines → 5 files <1000 lines each ✓
- **Function Coverage**: 41/41 functions preserved ✓
- **Test Coverage**: 54 existing + 32-48 new tests ✓
- **Performance**: <5% sourcing overhead ✓
- **Breaking Changes**: 0 ✓

### Qualitative Metrics
- **Discoverability**: Developers can find relevant functions faster
- **Maintainability**: Focused modules easier to update
- **Testability**: Each module tested independently
- **Documentation**: Clear module boundaries and responsibilities

## Notes

### Design Decisions

**Why 4 focused modules + wrapper?**
- Metadata extraction is self-contained (no dependencies)
- Hierarchical coordination is a cohesive workflow
- Context pruning is an explicit architectural goal (hierarchical agents)
- Registry operations are infrastructure (separate from higher-level ops)
- Remaining functions don't fit cleanly into modules (keep in wrapper)

**Why keep artifact-operations.sh?**
- Maintains backward compatibility naturally
- Provides namespace for "misc" functions
- Easier migration path for existing code
- Simpler for users (one source statement gets everything)

**Why not split further?**
- Diminishing returns (too many small files reduces discoverability)
- Current split addresses primary pain points (2713-line file, unclear boundaries)
- Future splits can happen if modules grow >1000 lines

### Future Work (Out of Scope)

**Not included in this phase**:
- Migrate commands to source specific modules (backward compatible, not required)
- Further split artifact-operations.sh misc functions (only if they grow)
- Create bundle.sh for performance optimization (only if overhead >5%)
- Deprecate legacy `get_*_metadata` functions (keep for compatibility)

---

**Phase 2 Created**: 2025-10-18
**Estimated Total Time**: 6-8 hours across 5 stages
**Ready for**: Implementation via `/implement` command
**Next Step**: Review this expansion and begin Stage 1 implementation
