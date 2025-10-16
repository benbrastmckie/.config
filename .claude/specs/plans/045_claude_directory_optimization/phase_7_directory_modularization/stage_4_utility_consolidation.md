# Stage 4: Consolidate Utility Libraries

## Metadata
- **Stage Number**: 4
- **Parent Phase**: phase_7_directory_modularization
- **Phase Number**: 7
- **Objective**: Consolidate overlapping utility functions and extract reusable templates from checkpoint-utils.sh
- **Complexity**: Medium
- **Status**: PENDING
- **Estimated Time**: 3-4 hours

## Overview

This stage consolidates overlapping functionality across utility libraries to reduce duplication and improve maintainability. The primary consolidation merges artifact-utils.sh (878 lines) and auto-analysis-utils.sh (1,755 lines) into a single artifact-management.sh (~1,200 lines), eliminating ~1,433 lines of duplicate code. Additionally, checkpoint-utils.sh patterns are extracted to a reusable template (~100 lines).

The consolidation requires updating 9+ commands that currently source these utilities, but the result is a cleaner utility library with consistent interfaces and reduced maintenance burden.

## Detailed Tasks

### Task 1: Inventory Functions in artifact-utils.sh and auto-analysis-utils.sh

**Objective**: Create complete function inventory to identify duplicates, overlaps, and unique functions in both utility files.

**Implementation Steps**:

1. **Extract all function definitions** from artifact-utils.sh:
```bash
cd /home/benjamin/.config/.claude/lib
grep -n "^[a-zA-Z_][a-zA-Z0-9_]*\s*()" artifact-utils.sh | cut -d: -f2 | sort > /tmp/artifact_functions.txt

# Count functions
wc -l /tmp/artifact_functions.txt
# Expected: ~30-40 functions

# Display categorized view
cat /tmp/artifact_functions.txt
```

2. **Extract all function definitions** from auto-analysis-utils.sh:
```bash
grep -n "^[a-zA-Z_][a-zA-Z0-9_]*\s*()" auto-analysis-utils.sh | cut -d: -f2 | sort > /tmp/auto_analysis_functions.txt

# Count functions
wc -l /tmp/auto_analysis_functions.txt
# Expected: ~60-70 functions
```

3. **Identify duplicate function names**:
```bash
# Find functions defined in both files
comm -12 /tmp/artifact_functions.txt /tmp/auto_analysis_functions.txt > /tmp/duplicate_functions.txt

wc -l /tmp/duplicate_functions.txt
# Expected: 10-15 duplicate functions

cat /tmp/duplicate_functions.txt
```

Expected duplicates:
- `validate_plan_path()`
- `extract_plan_number()`
- `get_specs_directory()`
- `create_report_path()`
- `validate_report_format()`
- `parse_metadata()`

4. **Create comprehensive function inventory**:
```bash
cat > /tmp/function_inventory.md << 'EOF'
# Utility Function Inventory

## artifact-utils.sh Functions (878 lines)

### Plan Management (8 functions)
- validate_plan_path() - Verify plan file/directory exists
- extract_plan_number() - Get NNN from plan path
- get_plan_file() - Find main plan file (handles L0/L1/L2)
- list_all_plans() - Find all plans in specs/
- get_plan_metadata() - Extract metadata section
- update_plan_marker() - Add [COMPLETED] markers
- get_incomplete_plans() - Find plans with incomplete phases
- detect_plan_structure() - Determine L0/L1/L2

### Report Management (6 functions)
- create_report_path() - Generate report path with numbering
- validate_report_format() - Check report has required sections
- get_specs_directory() - Find specs/ directory upward
- list_reports_by_topic() - Find reports in specs/reports/{topic}/
- extract_report_metadata() - Get metadata from report
- link_report_to_plan() - Add cross-reference to plan

### Summary Management (4 functions)
- create_summary_path() - Generate summary path
- validate_summary_format() - Check summary structure
- update_summary_progress() - Increment phase completion
- finalize_summary() - Convert partial → final

### Metadata Parsing (6 functions)
- parse_metadata() - Extract metadata block
- get_metadata_field() - Get specific field value
- update_metadata_field() - Modify field value
- validate_metadata_format() - Check required fields
- extract_date() - Parse date field
- extract_references() - Get report/plan references

### File Operations (4 functions)
- safe_file_write() - Write with atomic operation
- backup_file() - Create .backup copy
- atomic_move() - Move with safety check
- verify_file_integrity() - Check file not corrupted

## auto-analysis-utils.sh Functions (1,755 lines)

### Artifact Analysis (12 functions)
- analyze_plan_complexity() - Calculate plan metrics
- analyze_phase_distribution() - Phase size analysis
- analyze_report_coverage() - Report topic coverage
- analyze_summary_completeness() - Check summary fields
- calculate_file_size_metrics() - Size distribution analysis
- detect_plan_patterns() - Common plan structures
- identify_refactoring_opportunities() - Suggest improvements
- analyze_cross_references() - Validate links
- detect_orphaned_artifacts() - Find unreferenced files
- analyze_test_coverage() - Test presence analysis
- calculate_implementation_velocity() - Phase completion rate
- generate_metrics_report() - Aggregate all metrics

### Plan Operations (8 functions - DUPLICATES)
- validate_plan_path() - [DUPLICATE] Verify plan exists
- extract_plan_number() - [DUPLICATE] Get NNN
- get_specs_directory() - [DUPLICATE] Find specs/
- get_plan_metadata() - Similar to artifact-utils version
- list_all_plans() - Similar to artifact-utils version
- get_plan_file() - [DUPLICATE] Find main plan
- detect_plan_structure() - [DUPLICATE] L0/L1/L2 detection
- get_incomplete_plans() - [DUPLICATE] Find incomplete

### Report Operations (4 functions - DUPLICATES)
- create_report_path() - [DUPLICATE] Generate path
- validate_report_format() - [DUPLICATE] Check structure
- list_reports_by_topic() - [DUPLICATE] Find reports
- parse_metadata() - [DUPLICATE] Extract metadata

### Metrics Collection (10 functions)
- collect_plan_metrics() - Gather plan statistics
- collect_report_metrics() - Gather report statistics
- collect_summary_metrics() - Gather summary statistics
- aggregate_metrics() - Combine all metrics
- calculate_averages() - Mean, median, mode
- detect_outliers() - Identify unusual metrics
- generate_trend_data() - Time-series analysis
- export_metrics_json() - Output JSON format
- export_metrics_csv() - Output CSV format
- visualize_metrics() - Generate ASCII charts

### Auto-Analysis (8 functions)
- auto_analyze_codebase() - Full codebase scan
- suggest_next_tasks() - AI-powered suggestions
- detect_code_smells() - Quality issues
- recommend_refactoring() - Specific improvements
- estimate_complexity() - Complexity scoring
- predict_implementation_time() - Time estimates
- analyze_dependencies() - Dependency graphs
- generate_analysis_report() - Comprehensive report

## Consolidation Strategy

### Keep from artifact-utils.sh
- Plan/Report/Summary Management (simpler, focused implementations)
- Metadata Parsing (well-tested, reliable)
- File Operations (atomic safety operations)

### Keep from auto-analysis-utils.sh
- Artifact Analysis (unique functionality)
- Metrics Collection (comprehensive metrics)
- Auto-Analysis (AI-powered analysis)

### Merge Strategy for Duplicates
| Function | Keep From | Reason |
|----------|-----------|--------|
| validate_plan_path() | artifact-utils | Simpler, faster |
| extract_plan_number() | artifact-utils | Regex cleaner |
| get_specs_directory() | artifact-utils | Fewer dependencies |
| create_report_path() | artifact-utils | Atomic numbering |
| validate_report_format() | auto-analysis | More comprehensive checks |
| parse_metadata() | artifact-utils | Handles more formats |
| get_plan_metadata() | artifact-utils | Cleaner parsing |
| list_all_plans() | auto-analysis | Better sorting |

### New Consolidated File: artifact-management.sh

**Structure** (~1,200 lines):
1. Plan Management (300 lines) - Best functions from both
2. Report Management (250 lines) - Best functions from both
3. Summary Management (150 lines) - From artifact-utils
4. Metadata Parsing (200 lines) - From artifact-utils
5. Artifact Analysis (200 lines) - From auto-analysis
6. Metrics Collection (100 lines) - From auto-analysis
EOF

cat /tmp/function_inventory.md
```

5. **Document line savings**:
```bash
ARTIFACT_LINES=878
AUTO_ANALYSIS_LINES=1755
TOTAL_BEFORE=$((ARTIFACT_LINES + AUTO_ANALYSIS_LINES))  # 2,633 lines

CONSOLIDATED_LINES=1200

REDUCTION=$((TOTAL_BEFORE - CONSOLIDATED_LINES))  # 1,433 lines
PERCENTAGE=$((REDUCTION * 100 / TOTAL_BEFORE))    # 54% reduction

echo "Consolidation Impact:"
echo "  Before: $TOTAL_BEFORE lines (2 files)"
echo "  After: $CONSOLIDATED_LINES lines (1 file)"
echo "  Savings: $REDUCTION lines ($PERCENTAGE% reduction)"
```

**Expected Result**: Complete function inventory documented, consolidation strategy defined, ~1,433 lines to be saved.

### Task 2: Create Consolidated artifact-management.sh

**Objective**: Merge the best implementations from both utilities into a single, well-organized file.

**Implementation Steps**:

1. **Create file header** with comprehensive documentation:
```bash
cat > /home/benjamin/.config/.claude/lib/artifact-management.sh << 'EOF'
#!/bin/bash
# artifact-management.sh
#
# Consolidated artifact management utilities for Claude Code.
#
# This file consolidates functionality from:
# - artifact-utils.sh (plan/report/summary management, metadata parsing, file operations)
# - auto-analysis-utils.sh (artifact analysis, metrics collection, auto-analysis)
#
# Usage:
#   source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-management.sh"
#
# Function Categories:
#   1. Plan Management (validate, extract, list, update)
#   2. Report Management (create, validate, link)
#   3. Summary Management (create, update, finalize)
#   4. Metadata Parsing (parse, extract, update)
#   5. File Operations (safe writes, backups, atomic operations)
#   6. Artifact Analysis (complexity, coverage, patterns)
#   7. Metrics Collection (statistics, aggregation, export)
#
# Migration Notes:
#   - Replaces: artifact-utils.sh, auto-analysis-utils.sh
#   - Update all source commands to use this file
#   - Deprecated functions marked with # DEPRECATED comments
#   - Breaking changes: None (interface-compatible with both old files)

set -euo pipefail

# ============================================================================
# SECTION 1: PLAN MANAGEMENT
# ============================================================================

# validate_plan_path <plan-path>
#
# Validates that a plan path exists (file or directory).
# Returns 0 if valid, 1 if invalid.
#
# Source: artifact-utils.sh (simpler implementation)
validate_plan_path() {
  local plan_path=$1

  if [ -f "$plan_path" ]; then
    # Level 0: Single file
    return 0
  elif [ -d "$plan_path" ]; then
    # Level 1/2: Directory
    # Check for main plan file
    local plan_name=$(basename "$plan_path")
    if [ -f "$plan_path/${plan_name}.md" ]; then
      return 0
    else
      echo "ERROR: Main plan file not found in directory: $plan_path" >&2
      return 1
    fi
  else
    echo "ERROR: Plan path does not exist: $plan_path" >&2
    return 1
  fi
}

# extract_plan_number <plan-path>
#
# Extracts the three-digit plan number (NNN) from a plan path.
# Returns the number or empty string if not found.
#
# Source: artifact-utils.sh (cleaner regex)
extract_plan_number() {
  local plan_path=$1
  local basename=$(basename "$plan_path" .md)

  # Extract NNN from "NNN_plan_name" or "NNN_plan_name.md"
  if [[ "$basename" =~ ^([0-9]{3})_ ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo ""
  fi
}

# get_specs_directory <starting-path>
#
# Finds the specs/ directory by searching upward from starting path.
# Returns absolute path to specs/ or empty string if not found.
#
# Source: artifact-utils.sh (fewer dependencies)
get_specs_directory() {
  local current_path=${1:-$(pwd)}

  while [ "$current_path" != "/" ]; do
    if [ -d "$current_path/specs" ]; then
      echo "$current_path/specs"
      return 0
    fi
    current_path=$(dirname "$current_path")
  done

  echo ""
  return 1
}

# get_plan_file <plan-path>
#
# Returns the absolute path to the main plan file, handling all structure levels.
#
# Source: artifact-utils.sh (handles L0/L1/L2)
get_plan_file() {
  local plan_path=$1

  if [ -f "$plan_path" ]; then
    # Level 0: Plan is a file
    realpath "$plan_path"
  elif [ -d "$plan_path" ]; then
    # Level 1/2: Plan is a directory
    local plan_name=$(basename "$plan_path")
    local main_plan="$plan_path/${plan_name}.md"

    if [ -f "$main_plan" ]; then
      realpath "$main_plan"
    else
      echo "ERROR: Main plan file not found: $main_plan" >&2
      return 1
    fi
  else
    echo "ERROR: Invalid plan path: $plan_path" >&2
    return 1
  fi
}

# list_all_plans <specs-directory>
#
# Lists all plan paths (both L0 files and L1/L2 directories) in specs/plans/.
# Returns paths sorted by modification time (most recent first).
#
# Source: auto-analysis-utils.sh (better sorting)
list_all_plans() {
  local specs_dir=$1
  local plans_dir="$specs_dir/plans"

  if [ ! -d "$plans_dir" ]; then
    echo ""
    return 1
  fi

  # Find L0 plans (files)
  find "$plans_dir" -maxdepth 1 -type f -name "[0-9][0-9][0-9]_*.md" -printf "%T@ %p\n" | sort -rn | cut -d' ' -f2

  # Find L1/L2 plans (directories)
  find "$plans_dir" -maxdepth 1 -type d -name "[0-9][0-9][0-9]_*" -printf "%T@ %p\n" | sort -rn | cut -d' ' -f2
}

# [Additional plan management functions: get_plan_metadata, update_plan_marker,
#  get_incomplete_plans, detect_plan_structure - implementations from artifact-utils.sh]
# ... (continue with remaining 4 functions in this section)

# ============================================================================
# SECTION 2: REPORT MANAGEMENT
# ============================================================================

# create_report_path <specs-dir> <topic> <report-name>
#
# Generates the next available report path with incremental numbering.
# Returns absolute path to new report file.
#
# Source: artifact-utils.sh (atomic numbering)
create_report_path() {
  local specs_dir=$1
  local topic=$2
  local report_name=$3

  local reports_dir="$specs_dir/reports/$topic"
  mkdir -p "$reports_dir"

  # Find next available number
  local max_num=0
  for file in "$reports_dir"/[0-9][0-9][0-9]_*.md; do
    if [ -f "$file" ]; then
      local num=$(basename "$file" | grep -oP '^\d{3}')
      if [ "$num" -gt "$max_num" ]; then
        max_num=$num
      fi
    fi
  done

  local next_num=$(printf "%03d" $((max_num + 1)))
  local report_path="$reports_dir/${next_num}_${report_name}.md"

  echo "$report_path"
}

# validate_report_format <report-path>
#
# Validates that a report has required sections (Metadata, Overview, Analysis).
# Returns 0 if valid, 1 if invalid.
#
# Source: auto-analysis-utils.sh (more comprehensive checks)
validate_report_format() {
  local report_path=$1

  if [ ! -f "$report_path" ]; then
    echo "ERROR: Report file not found: $report_path" >&2
    return 1
  fi

  # Check required sections
  local has_metadata=$(grep -c "^## Metadata" "$report_path")
  local has_overview=$(grep -c "^## Overview" "$report_path")
  local has_analysis=$(grep -c "^## Analysis\|^## Findings" "$report_path")

  if [ "$has_metadata" -eq 0 ]; then
    echo "ERROR: Report missing ## Metadata section" >&2
    return 1
  fi

  if [ "$has_overview" -eq 0 ]; then
    echo "ERROR: Report missing ## Overview section" >&2
    return 1
  fi

  if [ "$has_analysis" -eq 0 ]; then
    echo "ERROR: Report missing ## Analysis or ## Findings section" >&2
    return 1
  fi

  return 0
}

# [Additional report management functions: list_reports_by_topic,
#  extract_report_metadata, link_report_to_plan]
# ... (continue with remaining 3 functions)

# ============================================================================
# SECTION 3: SUMMARY MANAGEMENT
# ============================================================================

# [4 functions from artifact-utils.sh: create_summary_path,
#  validate_summary_format, update_summary_progress, finalize_summary]
# ... (implementation details)

# ============================================================================
# SECTION 4: METADATA PARSING
# ============================================================================

# [6 functions from artifact-utils.sh: parse_metadata, get_metadata_field,
#  update_metadata_field, validate_metadata_format, extract_date,
#  extract_references]
# ... (implementation details)

# ============================================================================
# SECTION 5: FILE OPERATIONS
# ============================================================================

# [4 functions from artifact-utils.sh: safe_file_write, backup_file,
#  atomic_move, verify_file_integrity]
# ... (implementation details)

# ============================================================================
# SECTION 6: ARTIFACT ANALYSIS
# ============================================================================

# [12 functions from auto-analysis-utils.sh: analyze_plan_complexity,
#  analyze_phase_distribution, analyze_report_coverage,
#  analyze_summary_completeness, calculate_file_size_metrics,
#  detect_plan_patterns, identify_refactoring_opportunities,
#  analyze_cross_references, detect_orphaned_artifacts,
#  analyze_test_coverage, calculate_implementation_velocity,
#  generate_metrics_report]
# ... (implementation details)

# ============================================================================
# SECTION 7: METRICS COLLECTION
# ============================================================================

# [10 functions from auto-analysis-utils.sh: collect_plan_metrics,
#  collect_report_metrics, collect_summary_metrics, aggregate_metrics,
#  calculate_averages, detect_outliers, generate_trend_data,
#  export_metrics_json, export_metrics_csv, visualize_metrics]
# ... (implementation details)

# ============================================================================
# INITIALIZATION
# ============================================================================

# Verify required dependencies
if ! command -v jq &> /dev/null; then
  echo "WARNING: jq not found. Some functions may not work." >&2
fi

# Set default environment variables if not set
: "${CLAUDE_PROJECT_DIR:=$(pwd)}"

# Export functions for subshells (if needed)
# export -f validate_plan_path extract_plan_number ...

EOF

chmod +x artifact-management.sh
```

2. **Implement all function bodies** (complete the file):
This step involves copying the best implementation for each function from the inventory.

3. **Add deprecation notices** to old files:
```bash
# Add to top of artifact-utils.sh
cat > artifact-utils.sh.header << 'EOF'
#!/bin/bash
# DEPRECATED: This file has been consolidated into artifact-management.sh
#
# Migration: Update source commands:
#   OLD: source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-utils.sh"
#   NEW: source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-management.sh"
#
# This file is maintained for backward compatibility but will be removed in a future release.
# All new development should use artifact-management.sh.

echo "WARNING: artifact-utils.sh is deprecated. Use artifact-management.sh instead." >&2
EOF

# Prepend to artifact-utils.sh (temporarily keep for compatibility)
cat artifact-utils.sh.header artifact-utils.sh > artifact-utils.sh.tmp
mv artifact-utils.sh.tmp artifact-utils.sh
```

4. **Verify consolidated file**:
```bash
wc -l artifact-management.sh  # Should be ~1,200 lines
bash -n artifact-management.sh  # Check syntax
```

**Expected Result**: Consolidated artifact-management.sh created with ~1,200 lines, deprecation notices added to old files.

### Task 3: Extract Checkpoint Template Pattern from checkpoint-utils.sh

**Objective**: Extract reusable checkpoint template pattern to reduce boilerplate in checkpoint-utils.sh.

**Implementation Steps**:

1. **Analyze checkpoint-utils.sh** for repeated patterns:
```bash
cd /home/benjamin/.config/.claude/lib
wc -l checkpoint-utils.sh  # 769 lines

# Find repeated JSON template construction
grep -n "CHECKPOINT.*{" checkpoint-utils.sh | head -10
```

Expected pattern (repeated ~5 times):
```bash
CHECKPOINT=$(cat <<EOF
{
  "workflow_description": "$WORKFLOW",
  "plan_path": "$PLAN_PATH",
  "current_phase": $CURRENT_PHASE,
  "total_phases": $TOTAL_PHASES,
  "status": "$STATUS",
  ...
}
EOF
)
```

2. **Create checkpoint-template.sh**:
```bash
cat > checkpoint-template.sh << 'EOF'
#!/bin/bash
# checkpoint-template.sh
#
# Reusable checkpoint data structure templates.
#
# Usage:
#   source "$CLAUDE_PROJECT_DIR/.claude/lib/checkpoint-template.sh"
#   CHECKPOINT=$(generate_checkpoint_template "implement" "$PLAN_PATH" "$CURRENT_PHASE" ...)
#
# Provides:
#   - generate_checkpoint_template() - Base checkpoint structure
#   - add_checkpoint_field() - Add optional field
#   - merge_checkpoint_extensions() - Merge custom fields

set -euo pipefail

# generate_checkpoint_template <workflow> <plan-path> <current-phase> <total-phases> <status>
#
# Generates base checkpoint JSON structure with required fields.
#
# Arguments:
#   $1 - Workflow name (implement, orchestrate, etc.)
#   $2 - Plan path (absolute)
#   $3 - Current phase number
#   $4 - Total phases
#   $5 - Status (in_progress, complete, failed)
#
# Returns: JSON string
generate_checkpoint_template() {
  local workflow=$1
  local plan_path=$2
  local current_phase=$3
  local total_phases=$4
  local status=$5

  cat <<EOF
{
  "workflow_description": "$workflow",
  "plan_path": "$plan_path",
  "plan_number": "$(basename "$plan_path" | grep -oP '^\d{3}')",
  "current_phase": $current_phase,
  "total_phases": $total_phases,
  "status": "$status",
  "created_at": "$(date -Iseconds)",
  "last_updated": "$(date -Iseconds)",
  "version": "1.0"
}
EOF
}

# add_checkpoint_field <checkpoint-json> <field-name> <field-value>
#
# Adds a field to existing checkpoint JSON.
#
# Arguments:
#   $1 - Existing checkpoint JSON
#   $2 - Field name
#   $3 - Field value (will be JSON-encoded)
#
# Returns: Updated JSON string
add_checkpoint_field() {
  local checkpoint=$1
  local field_name=$2
  local field_value=$3

  echo "$checkpoint" | jq --arg key "$field_name" --arg val "$field_value" '. + {($key): $val}'
}

# merge_checkpoint_extensions <base-checkpoint> <extensions-json>
#
# Merges custom fields from extensions JSON into base checkpoint.
#
# Arguments:
#   $1 - Base checkpoint JSON
#   $2 - Extensions JSON (object with custom fields)
#
# Returns: Merged JSON string
merge_checkpoint_extensions() {
  local base=$1
  local extensions=$2

  echo "$base" | jq --argjson ext "$extensions" '. + $ext'
}

# Example Usage:
#
# # Create base checkpoint
# BASE=$(generate_checkpoint_template "implement" "$PLAN_PATH" 3 5 "in_progress")
#
# # Add adaptive planning fields
# EXTENSIONS='{"phase_replan_count": {"1": 0, "2": 1}, "test_failure_history": []}'
# CHECKPOINT=$(merge_checkpoint_extensions "$BASE" "$EXTENSIONS")
#
# # Save checkpoint
# save_checkpoint "implement" "$CHECKPOINT"

EOF

chmod +x checkpoint-template.sh
```

3. **Update checkpoint-utils.sh** to use template:
```bash
# Add near top of checkpoint-utils.sh
echo '
# Source checkpoint template utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/checkpoint-template.sh"
' >> checkpoint-utils.sh.new

# Update save_checkpoint function to use template
# Replace manual JSON construction with:
#   BASE=$(generate_checkpoint_template "$WORKFLOW" "$PLAN_PATH" ...)
#   CHECKPOINT=$(merge_checkpoint_extensions "$BASE" "$CUSTOM_FIELDS")
```

4. **Calculate line savings**:
```bash
ORIGINAL_LINES=769
# Template extraction removes ~100 lines of repeated JSON construction
# Template file is ~100 lines
# Net savings: ~0 lines (but improved maintainability)

# The value is in:
# - Consistency (all checkpoints use same base structure)
# - Extensibility (easy to add fields)
# - Validation (template enforces required fields)
```

**Expected Result**: checkpoint-template.sh created (~100 lines), checkpoint-utils.sh refactored to use template, improved maintainability.

### Task 4: Update Commands to Source Consolidated Utilities

**Objective**: Update 9+ commands to source artifact-management.sh instead of artifact-utils.sh or auto-analysis-utils.sh.

**Implementation Steps**:

1. **Identify commands using old utilities**:
```bash
cd /home/benjamin/.config/.claude/commands
grep -l "artifact-utils.sh\|auto-analysis-utils.sh" *.sh *.md 2>/dev/null

# Expected commands:
# implement.sh, orchestrate.sh, plan.sh, revise.sh, debug.sh,
# report.sh, list.sh, analyze.sh, refactor.sh
```

2. **Create update script**:
```bash
cat > /tmp/update_utility_sources.sh << 'EOF'
#!/bin/bash
# Update commands to use consolidated artifact-management.sh

COMMANDS_DIR="/home/benjamin/.config/.claude/commands"
OLD_UTILS=("artifact-utils.sh" "auto-analysis-utils.sh")
NEW_UTIL="artifact-management.sh"

for cmd_file in "$COMMANDS_DIR"/*.sh; do
  if grep -q "artifact-utils.sh\|auto-analysis-utils.sh" "$cmd_file"; then
    echo "Updating: $(basename "$cmd_file")"

    # Replace source statements
    sed -i 's|source.*artifact-utils\.sh|source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-management.sh"|g' "$cmd_file"
    sed -i 's|source.*auto-analysis-utils\.sh|source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-management.sh"|g' "$cmd_file"

    # Remove duplicate source lines (if both utilities were sourced)
    awk '!seen[$0]++' "$cmd_file" > "$cmd_file.tmp"
    mv "$cmd_file.tmp" "$cmd_file"

    echo "  ✓ Updated $(basename "$cmd_file")"
  fi
done

echo "All commands updated to use $NEW_UTIL"
EOF

chmod +x /tmp/update_utility_sources.sh
bash /tmp/update_utility_sources.sh
```

3. **Verify updates**:
```bash
# Check that old utilities are no longer sourced
for cmd in implement.sh orchestrate.sh plan.sh; do
  if grep -q "artifact-utils.sh\|auto-analysis-utils.sh" "$cmd"; then
    echo "ERROR: $cmd still sources old utilities"
  else
    echo "✓ $cmd updated"
  fi
done

# Check that new utility is sourced
for cmd in implement.sh orchestrate.sh plan.sh; do
  if grep -q "artifact-management.sh" "$cmd"; then
    echo "✓ $cmd sources artifact-management.sh"
  else
    echo "ERROR: $cmd missing artifact-management.sh source"
  fi
done
```

4. **Test command functionality** (smoke tests):
```bash
# Test implement command help
./implement.sh --help 2>&1 | head -5

# Test plan command with list operation
./plan.sh --list 2>&1 | head -5

# Verify no errors about missing functions
```

**Expected Result**: All commands updated to use artifact-management.sh, old utility sources removed, commands functional.

### Task 5: Create lib/README.md with Function Inventory

**Objective**: Document all utility functions with usage examples and cross-references.

**Implementation Steps**:

1. **Create comprehensive lib/README.md**:
```bash
cat > /home/benjamin/.config/.claude/lib/README.md << 'EOF'
# Claude Code Utility Library

This directory contains shared utility functions used across commands and agents.

## Utility Files

### artifact-management.sh (1,200 lines)
**Purpose**: Consolidated artifact management (plans, reports, summaries, metadata)

**Replaces**: `artifact-utils.sh`, `auto-analysis-utils.sh`

**Function Categories**:
- Plan Management (8 functions): validate, extract, list, update
- Report Management (6 functions): create, validate, link
- Summary Management (4 functions): create, update, finalize
- Metadata Parsing (6 functions): parse, extract, update
- File Operations (4 functions): safe writes, backups, atomic operations
- Artifact Analysis (12 functions): complexity, coverage, patterns
- Metrics Collection (10 functions): statistics, aggregation, export

**Usage**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-management.sh"

# Validate plan path
validate_plan_path "$PLAN_PATH" || exit 1

# Extract plan number
PLAN_NUM=$(extract_plan_number "$PLAN_PATH")

# List all plans
PLANS=$(list_all_plans "$SPECS_DIR")
```

**Used By**: implement, orchestrate, plan, revise, debug, report, list, analyze, refactor

---

### checkpoint-utils.sh (769 lines)
**Purpose**: Checkpoint management for workflow state persistence

**Functions**:
- `save_checkpoint(workflow, data)` - Save checkpoint JSON
- `load_checkpoint(workflow)` - Load checkpoint JSON
- `delete_checkpoint(workflow)` - Remove checkpoint
- `list_checkpoints()` - List all checkpoints
- `check_safe_resume_conditions(checkpoint)` - Verify auto-resume safety
- `migrate_checkpoint_schema(checkpoint)` - Update old checkpoints

**Usage**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/checkpoint-utils.sh"

# Save checkpoint
CHECKPOINT='{"workflow":"implement", "plan_path":"...", "current_phase":3}'
save_checkpoint "implement" "$CHECKPOINT"

# Load checkpoint
CHECKPOINT=$(load_checkpoint "implement")
CURRENT_PHASE=$(echo "$CHECKPOINT" | jq -r '.current_phase')
```

**Used By**: implement, orchestrate, revise

---

### checkpoint-template.sh (100 lines)
**Purpose**: Reusable checkpoint JSON templates

**Functions**:
- `generate_checkpoint_template(workflow, plan_path, phase, total, status)` - Base structure
- `add_checkpoint_field(checkpoint, field, value)` - Add field
- `merge_checkpoint_extensions(base, extensions)` - Merge custom fields

**Usage**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/checkpoint-template.sh"

# Create base checkpoint
BASE=$(generate_checkpoint_template "implement" "$PLAN_PATH" 3 5 "in_progress")

# Add custom fields
EXTENSIONS='{"test_failure_history": [], "phase_replan_count": {}}'
CHECKPOINT=$(merge_checkpoint_extensions "$BASE" "$EXTENSIONS")
```

**Used By**: checkpoint-utils.sh (internal), implement, orchestrate

---

### complexity-utils.sh (879 lines)
**Purpose**: Phase and plan complexity analysis

**Functions**:
- `calculate_phase_complexity(phase_name, task_list)` - Threshold scoring
- `hybrid_complexity_evaluation(phase, tasks, plan)` - Agent-based evaluation
- `detect_complexity_keywords(text)` - Keyword analysis
- `estimate_implementation_time(complexity_score)` - Time estimates

**Usage**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh"

# Calculate complexity
COMPLEXITY=$(calculate_phase_complexity "$PHASE_NAME" "$TASK_LIST")
echo "Complexity: $COMPLEXITY"

# Hybrid evaluation (may invoke agent)
RESULT=$(hybrid_complexity_evaluation "$PHASE_NAME" "$TASK_LIST" "$PLAN_FILE")
SCORE=$(echo "$RESULT" | jq -r '.final_score')
```

**Used By**: implement, plan, expand, revise

---

### error-utils.sh (879 lines)
**Purpose**: Error classification, recovery strategies, retry logic

**Functions**:
- `detect_error_type(output)` - Classify error
- `generate_suggestions(error_type, output)` - Recovery suggestions
- `retry_with_backoff(operation, max_attempts)` - Exponential backoff
- `format_error_report(error_type, output, context)` - Structured reporting

**Usage**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/error-utils.sh"

# Classify error
ERROR_TYPE=$(detect_error_type "$TEST_OUTPUT")
echo "Error type: $ERROR_TYPE"

# Get recovery suggestions
SUGGESTIONS=$(generate_suggestions "$ERROR_TYPE" "$TEST_OUTPUT")
echo "$SUGGESTIONS"
```

**Used By**: implement, orchestrate, debug, test

---

### adaptive-planning-logger.sh (356 lines)
**Purpose**: Logging for adaptive planning events

**Functions**:
- `log_complexity_check(phase, score, threshold, agent_invoked)` - Log complexity evaluation
- `log_replan_invocation(phase, trigger, old_structure, new_structure)` - Log replan
- `log_loop_prevention(phase, count, action)` - Log loop prevention
- `query_replan_history()` - Query past replans

**Usage**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/adaptive-planning-logger.sh"

# Log complexity check
log_complexity_check 2 9.5 8.0 "true"

# Log replan
log_replan_invocation 2 "complexity" "inline" "expanded"
```

**Used By**: implement, revise

---

### parse-adaptive-plan.sh (1,164 lines)
**Purpose**: Progressive plan parsing (L0/L1/L2)

**Functions**:
- `detect_structure_level(plan_path)` - Returns 0, 1, or 2
- `is_phase_expanded(plan_path, phase_num)` - Check if phase in separate file
- `is_stage_expanded(phase_path, stage_num)` - Check if stage in separate file
- `get_phase_file_path(plan_path, phase_num)` - Get correct file path
- `list_expanded_phases(plan_path)` - List expanded phase numbers

**Usage**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/parse-adaptive-plan.sh"

# Detect structure level
LEVEL=$(detect_structure_level "$PLAN_PATH")
echo "Structure: Level $LEVEL"

# Get phase file
PHASE_FILE=$(get_phase_file_path "$PLAN_PATH" 2)
PHASE_CONTENT=$(cat "$PHASE_FILE")
```

**Used By**: implement, plan, expand, collapse, revise

---

## Function Cross-Reference

### Most Used Functions (10+)

| Function | File | Used By (count) |
|----------|------|-----------------|
| validate_plan_path | artifact-management.sh | 12 commands |
| extract_plan_number | artifact-management.sh | 11 commands |
| save_checkpoint | checkpoint-utils.sh | 8 commands |
| load_checkpoint | checkpoint-utils.sh | 8 commands |
| calculate_phase_complexity | complexity-utils.sh | 7 commands |
| detect_error_type | error-utils.sh | 7 commands |
| detect_structure_level | parse-adaptive-plan.sh | 6 commands |
| get_specs_directory | artifact-management.sh | 6 commands |

### Function Dependencies

```
artifact-management.sh
  └─ uses: jq, realpath, find

checkpoint-utils.sh
  └─ uses: checkpoint-template.sh, jq, date

complexity-utils.sh
  └─ uses: artifact-management.sh, jq, Task tool (for agent invocation)

error-utils.sh
  └─ uses: jq

parse-adaptive-plan.sh
  └─ uses: artifact-management.sh, jq, grep
```

## Migration Guide

### From artifact-utils.sh / auto-analysis-utils.sh

**Old Code**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-utils.sh"
source "$CLAUDE_PROJECT_DIR/.claude/lib/auto-analysis-utils.sh"

validate_plan_path "$PLAN_PATH"
analyze_plan_complexity "$PLAN_PATH"
```

**New Code**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-management.sh"

validate_plan_path "$PLAN_PATH"
analyze_plan_complexity "$PLAN_PATH"
```

**Breaking Changes**: None (interface-compatible)

## Adding New Utilities

When creating new utility files:

1. **File naming**: Use `kebab-case-utils.sh` format
2. **Header comment**: Document purpose, usage, functions
3. **Function documentation**: Use `# function_name <args>` format with description
4. **Error handling**: Use `set -euo pipefail`, return non-zero on errors
5. **Dependencies**: Minimize external dependencies, document required commands
6. **Testing**: Create corresponding `test_*.sh` file in `.claude/tests/`

## Testing Utilities

Test files located in `.claude/tests/`:
- `test_artifact_management.sh` - Tests artifact-management.sh functions
- `test_checkpoint_utils.sh` - Tests checkpoint operations
- `test_complexity_utils.sh` - Tests complexity calculations
- `test_error_utils.sh` - Tests error classification and recovery
- `test_parse_adaptive_plan.sh` - Tests plan parsing

Run all utility tests:
```bash
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh | grep -E "artifact|checkpoint|complexity|error|parse"
```

EOF
```

2. **Verify README**:
```bash
wc -l lib/README.md  # Should be ~250 lines
head -50 lib/README.md | tail -20  # Check formatting
```

**Expected Result**: Comprehensive lib/README.md created with function inventory, usage examples, cross-references.

## Testing Strategy

### Unit Tests

**Test consolidated utility functions**:
```bash
cd /home/benjamin/.config/.claude/tests

# Test artifact-management.sh
source ../lib/artifact-management.sh
validate_plan_path "specs/plans/001_test.md" && echo "PASS" || echo "FAIL"

# Test checkpoint-template.sh
source ../lib/checkpoint-template.sh
CHECKPOINT=$(generate_checkpoint_template "test" "/path/to/plan" 1 5 "in_progress")
echo "$CHECKPOINT" | jq . && echo "PASS" || echo "FAIL"
```

**Test command updates**:
```bash
# Verify commands source new utility correctly
for cmd in implement orchestrate plan; do
  bash -n "../commands/${cmd}.sh" && echo "PASS: $cmd syntax OK" || echo "FAIL: $cmd syntax error"
done
```

### Integration Tests

**Test command functionality with consolidated utilities**:
```bash
# Run existing test suite to verify no regressions
./run_all_tests.sh 2>&1 | tee consolidation_test_results.log

# Compare against baseline from Stage 1
diff baseline_test_results.log consolidation_test_results.log
```

### Verification Commands

```bash
# Consolidated utility exists and has expected size
wc -l ../lib/artifact-management.sh | awk '{if($1 < 1100 || $1 > 1300) print "FAIL: size"; else print "PASS"}'

# Checkpoint template exists
[ -f ../lib/checkpoint-template.sh ] && echo "PASS" || echo "FAIL"

# Old utilities have deprecation notices
grep -q "DEPRECATED" ../lib/artifact-utils.sh && echo "PASS" || echo "FAIL"

# All commands updated
COMMANDS_WITH_OLD_UTILS=$(grep -l "artifact-utils.sh\|auto-analysis-utils.sh" ../commands/*.sh 2>/dev/null | wc -l)
[ "$COMMANDS_WITH_OLD_UTILS" -eq 0 ] && echo "PASS: All commands updated" || echo "FAIL: $COMMANDS_WITH_OLD_UTILS commands still use old utilities"

# lib/README.md exists
[ -f ../lib/README.md ] && wc -l ../lib/README.md && echo "PASS" || echo "FAIL"
```

## Success Criteria

Stage 4 is complete when:
- [ ] Function inventory documented for artifact-utils.sh and auto-analysis-utils.sh
- [ ] artifact-management.sh created (~1,200 lines) consolidating both utilities
- [ ] Duplicate functions merged (best implementation selected per function)
- [ ] checkpoint-template.sh created (~100 lines) with reusable patterns
- [ ] 9+ commands updated to source artifact-management.sh (old sources removed)
- [ ] Deprecation notices added to artifact-utils.sh and auto-analysis-utils.sh
- [ ] lib/README.md created with comprehensive function inventory and usage examples
- [ ] All tests pass (no regressions from consolidation)
- [ ] ~1,433 lines saved (54% reduction from 2,633 to 1,200 lines)

## Dependencies

### Prerequisites
- Stages 1-3 complete (shared documentation files created)
- artifact-utils.sh (878 lines) and auto-analysis-utils.sh (1,755 lines) exist
- checkpoint-utils.sh (769 lines) exists
- Commands currently source old utilities

### Enables
- Stage 5 (documentation can reference consolidated utilities)
- Future utility development (clear patterns established)
- Reduced maintenance burden (single source of truth for artifact operations)

## Risk Mitigation

### High Risk Items
- **Function interface changes**: Breaking changes could affect all commands
- **Merge conflicts**: Different implementations may have subtle behavioral differences
- **Test regressions**: Consolidation may introduce bugs

### Mitigation Strategies
- **Interface compatibility**: Keep all function signatures unchanged (no breaking changes)
- **Incremental testing**: Test each function after merge, not all at once
- **Git safety**: Commit after each major step (inventory, consolidation, command updates)
- **Rollback plan**: Keep old utilities with deprecation notices (easy rollback if needed)

### Edge Cases
- **Commands sourcing both utilities**: Detect and remove duplicate source lines
- **Functions with same name, different behavior**: Document differences, choose best
- **Functions not in use**: Mark as deprecated, consider removing in future

## Notes

### Design Decisions

**Why consolidate artifact-utils and auto-analysis-utils?**
High overlap (~50% duplicate functions), both manage artifacts, consolidation reduces maintenance burden and ensures consistency.

**Why extract checkpoint-template.sh?**
Repeated JSON construction in checkpoint-utils.sh (~100 lines of boilerplate), template pattern improves maintainability and consistency.

**Why keep old utilities with deprecation notices?**
Enables gradual migration, provides fallback if consolidation introduces regressions, can be removed in future release.

### Efficiency Tips

- Create function inventory first (informs consolidation strategy)
- Test consolidated file incrementally (don't wait until all functions merged)
- Update commands in batch script (consistent, repeatable)
- Document as you go (lib/README.md serves as consolidation guide)

### Future Considerations

After Stage 4:
- artifact-utils.sh and auto-analysis-utils.sh can be removed entirely (after 1-2 release cycles)
- Additional utility consolidation opportunities may emerge (consider merging related utilities)
- Checkpoint template pattern could be applied to other utilities with repeated structures
