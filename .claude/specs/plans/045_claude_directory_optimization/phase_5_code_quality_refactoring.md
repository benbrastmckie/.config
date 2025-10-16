# Phase 5: Code Quality & Modularization [CANCELLED]

## Phase Metadata
- **Phase Number**: 5
- **Parent Plan**: 045_claude_directory_optimization.md
- **Original Objective**: Modularize 3 large utilities (4,555 lines) into 9-12 focused files (<500 lines each) and extract shared utilities
- **Complexity**: High
- **Risk**: Low (comprehensive testing after each change)
- **Estimated Time**: 20-30 hours (full) or 5-6 hours (shared utilities only)
- **Status**: CANCELLED

## Cancellation Notice

**User Decision**: Bash script modularization is not necessary.

**Rationale**: After initial implementation of Parts 1-2, user determined that modularizing bash scripts adds unnecessary complexity without sufficient benefit. The existing utilities work well and are maintainable as-is. Both Part 1 (shared utilities) and Part 2 (auto-analysis-utils.sh modularization) have been reverted (commits 8829aa2 and a6a7b62).

**Action Taken**: All changes from Parts 1-2 were reverted via git. The bash utilities will remain in their current monolithic form. This expanded phase file is retained for historical reference only.

## Overview

Modularize 3 large utilities (4,555 lines, 81 functions total) into 9-12 focused files (<500 lines each) and extract shared utilities. This phase transforms monolithic utilities into maintainable, testable modules with clear responsibilities.

**Current State**:
- `auto-analysis-utils.sh`: 1,755 lines, 19 functions (agent orchestration)
- `convert-docs.sh`: 1,502 lines, 29 functions (document conversion)
- `parse-adaptive-plan.sh`: 1,298 lines, 33 functions (plan parsing)
- Mixed concerns: timestamp operations, validation, JSON building scattered across files
- Circular dependency risk when splitting utilities

**Target State**:
- 9-12 focused modules (<500 lines each)
- 3 shared utility libraries (timestamp, validation, JSON helpers)
- Clear sourcing hierarchy (no circular dependencies)
- Improved testability (unit tests per module)
- Efficiency improvements (awk consolidation, jq adoption)

**Risk Level**: Low (comprehensive testing after each change)
**Estimated Time**: 20-30 hours total, 5-6 hours for Part 1 (shared utilities only)

---

## Overall Modularization Strategy

### Dependency Analysis Approach

**Identify Function Dependencies**:
1. Parse each utility with `grep -E "^[a-z_]+\(\)" file.sh` to extract function names
2. For each function, grep for calls to other functions
3. Build dependency graph showing which functions call which
4. Group functions with tight coupling (mutual dependencies)

**Example Dependency Analysis**:
```bash
# Extract function list
FUNCTIONS=$(grep -oE '^[a-z_]+\(\)' auto-analysis-utils.sh | sed 's/()//')

# For each function, find what it calls
for func in $FUNCTIONS; do
  echo "=== $func ==="
  awk "/^$func\(\)/,/^[a-z_]+\(\)/" auto-analysis-utils.sh | \
    grep -oE '[a-z_]+\(' | sed 's/(//' | grep -v "^$func$" | sort -u
done
```

### Module Boundary Determination

**Principles**:
1. **Single Responsibility**: Each module has one clear purpose
2. **Cohesion**: Functions in same module work on related data
3. **Loose Coupling**: Minimize dependencies between modules
4. **Size Constraint**: Target <500 lines per module

**Decision Tree**:
```
Does function group have <10 functions AND <500 lines?
  YES → Single module
  NO → Split by sub-responsibilities

Do functions share state/data structures?
  YES → Keep in same module
  NO → Consider separate modules

Do functions form a clear workflow (A→B→C)?
  YES → Keep in same module
  NO → Split by stage
```

### Sourcing Relationship Management

**Hierarchy Levels** (prevent circular dependencies):
```
Level 0: Pure utilities (no dependencies)
  - timestamp-utils.sh
  - validation-utils.sh

Level 1: Basic utilities (depend on Level 0 only)
  - json-utils-extended.sh (depends on json-utils.sh)
  - error-utils.sh (depends on timestamp-utils.sh)

Level 2: Domain utilities (depend on Level 0-1)
  - plan-detection.sh (depends on validation-utils.sh)
  - artifact-registry.sh (depends on timestamp, validation, json)

Level 3: Complex utilities (depend on Level 0-2)
  - plan-extraction.sh (depends on plan-detection.sh)
  - agent-invocation.sh (depends on validation, json)

Level 4: Orchestration utilities (depend on Level 0-3)
  - parallel-coordination.sh (depends on artifact-registry, agent-invocation)
  - plan-merging.sh (depends on plan-detection, plan-extraction)
```

**Circular Dependency Detection**:
```bash
# Build sourcing graph
for file in .claude/lib/*.sh; do
  echo "=== $(basename $file) ==="
  grep "^source" "$file" | sed 's/.*\///' | sed 's/"//'
done | tee sourcing-graph.txt

# Manually check for cycles (Level N sources from Level N+1)
```

### Update Strategy for Sourcing Files

**Safe Update Pattern**:
1. Create new module files (empty stubs)
2. Add source statements to new modules (dependencies only)
3. Move functions one at a time from old to new
4. Test after each function move
5. Update commands to source new modules
6. Only after all moves: delete old monolithic file

**Avoid**:
- Moving all functions at once (hard to debug failures)
- Updating commands before modules are complete
- Deleting old files before verification

### Testing Strategy for Each Module

**Unit Testing** (per module):
```bash
# Create test_<module-name>.sh
test_module_functions() {
  # Source module
  source .claude/lib/<module-name>.sh

  # Test each public function
  test_function_1() { ... }
  test_function_2() { ... }

  # Run tests
  test_function_1 || fail "Function 1 failed"
  test_function_2 || fail "Function 2 failed"
}
```

**Integration Testing** (between modules):
```bash
# Test that modules work together
test_module_integration() {
  source .claude/lib/module-a.sh
  source .claude/lib/module-b.sh

  # Test workflow that spans both modules
  result_a=$(module_a_function "input")
  result_b=$(module_b_function "$result_a")

  [[ "$result_b" == "expected" ]] || fail "Integration failed"
}
```

**Regression Testing** (existing test suites):
```bash
# Run all existing tests to verify no breakage
.claude/tests/run_all_tests.sh

# Specific test suites per utility
.claude/tests/test_parsing_utilities.sh      # parse-adaptive-plan modules
.claude/tests/test_auto_analysis_*.sh        # auto-analysis modules
.claude/tests/test_command_integration.sh    # convert-docs modules
```

### Rollback Strategy for Each Modularization

**Per-Module Rollback**:
```bash
# If module creation fails
git log --oneline | grep "refactor.*module"
git reset --hard <commit-before-module>

# Clean up created files
git clean -fd .claude/lib/
```

**Per-Part Rollback**:
```bash
# Rollback entire Part (e.g., Part 2 = auto-analysis modularization)
git log --oneline | grep "refactor(Part 2)"
git reset --hard <commit-before-part-2>

# Verify rollback
bash .claude/tests/run_all_tests.sh
```

---

## Part 1: Shared Utilities Extraction (5-6 hours)

### 1.1 Extract timestamp-utils.sh

**Objective**: Create platform-independent timestamp utility used by 5+ files

**Function Inventory** (from grep analysis):
```bash
# Files using: date -u +%Y-%m-%dT%H:%M:%SZ
# - checkpoint-utils.sh (3 occurrences)
# - error-utils.sh (4 occurrences)
# - auto-analysis-utils.sh (19 occurrences)
# - artifact-utils.sh (multiple)
# - agent-registry-utils.sh (multiple)
```

**timestamp-utils.sh Structure**:
```bash
#!/usr/bin/env bash
# timestamp-utils.sh - Platform-independent timestamp operations

# get_iso_timestamp - Return ISO 8601 timestamp (UTC)
# Usage: get_iso_timestamp
# Returns: "2025-10-13T14:32:10Z"
get_iso_timestamp() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

# get_unix_timestamp - Return Unix epoch timestamp
# Usage: get_unix_timestamp
# Returns: "1728832330"
get_unix_timestamp() {
  date +%s
}

# format_duration - Convert seconds to human-readable duration
# Usage: format_duration <seconds>
# Returns: "2h 15m 30s" or "45m 12s" or "23s"
format_duration() {
  local total_seconds="$1"
  local hours=$((total_seconds / 3600))
  local minutes=$(( (total_seconds % 3600) / 60 ))
  local seconds=$((total_seconds % 60))

  if [[ $hours -gt 0 ]]; then
    echo "${hours}h ${minutes}m ${seconds}s"
  elif [[ $minutes -gt 0 ]]; then
    echo "${minutes}m ${seconds}s"
  else
    echo "${seconds}s"
  fi
}

# parse_iso_timestamp - Convert ISO timestamp to Unix epoch
# Usage: parse_iso_timestamp "2025-10-13T14:32:10Z"
# Returns: Unix timestamp or empty on error
parse_iso_timestamp() {
  local iso_ts="$1"
  # Platform-independent: try GNU date first, fall back to BSD date
  if date -d "$iso_ts" +%s 2>/dev/null; then
    return 0
  elif date -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso_ts" +%s 2>/dev/null; then
    return 0
  else
    echo "" >&2
    return 1
  fi
}
```

**Extraction Steps**:
1. Create `.claude/lib/timestamp-utils.sh` with functions above
2. Update 5 files to source timestamp-utils.sh:
   ```bash
   # Add after script header, before first timestamp use
   source "${SCRIPT_DIR}/timestamp-utils.sh"

   # Replace all instances:
   # OLD: date -u +%Y-%m-%dT%H:%M:%SZ
   # NEW: get_iso_timestamp

   # OLD: date +%s
   # NEW: get_unix_timestamp
   ```
3. Test timestamp functions:
   ```bash
   # Run timestamp-utils.sh directly to verify
   bash /home/benjamin/.config/.claude/lib/timestamp-utils.sh

   # Run test suite
   bash /home/benjamin/.config/.claude/tests/test_shared_utilities.sh timestamp
   ```

**Files to Update**:
- `checkpoint-utils.sh`: 3 replacements
- `error-utils.sh`: 4 replacements
- `auto-analysis-utils.sh`: 19 replacements
- `artifact-utils.sh`: ~8 replacements
- `agent-registry-utils.sh`: ~5 replacements

**Git Commit**:
```bash
git add .claude/lib/timestamp-utils.sh
git add .claude/lib/{checkpoint,error,auto-analysis,artifact,agent-registry}-utils.sh
git commit -m "refactor: extract timestamp operations to shared utility

- Create timestamp-utils.sh with ISO/Unix timestamp functions
- Update 5 utilities to use get_iso_timestamp()
- Platform-independent (supports GNU date and BSD date)
- Improves consistency and reduces duplication"
```

### 1.2 Extract validation-utils.sh

**Objective**: Centralize parameter validation logic used across all utilities

**Pattern Identification** (from grep analysis):
```bash
# Common validation pattern (64 occurrences across 9 files):
if [[ -z "$param" ]]; then
  echo "ERROR: function_name requires param" >&2
  return 1
fi
```

**validation-utils.sh Structure**:
```bash
#!/usr/bin/env bash
# validation-utils.sh - Common parameter validation helpers

# validate_required - Check if required parameter is provided
# Usage: validate_required <param_value> <param_name> <function_name>
# Returns: 0 if valid, 1 if invalid (with error message)
validate_required() {
  local value="$1"
  local param_name="$2"
  local function_name="$3"

  if [[ -z "$value" ]]; then
    echo "ERROR: ${function_name} requires ${param_name}" >&2
    return 1
  fi
  return 0
}

# validate_file_exists - Check if file exists and is readable
# Usage: validate_file_exists <file_path> <file_description>
# Returns: 0 if valid, 1 if invalid
validate_file_exists() {
  local file_path="$1"
  local description="${2:-file}"

  if [[ ! -f "$file_path" ]]; then
    echo "ERROR: ${description} not found: ${file_path}" >&2
    return 1
  fi

  if [[ ! -r "$file_path" ]]; then
    echo "ERROR: ${description} not readable: ${file_path}" >&2
    return 1
  fi

  return 0
}

# validate_directory_exists - Check if directory exists and is accessible
# Usage: validate_directory_exists <dir_path> <dir_description>
validate_directory_exists() {
  local dir_path="$1"
  local description="${2:-directory}"

  if [[ ! -d "$dir_path" ]]; then
    echo "ERROR: ${description} not found: ${dir_path}" >&2
    return 1
  fi

  return 0
}

# validate_json - Check if string is valid JSON
# Usage: validate_json <json_string> <description>
validate_json() {
  local json_str="$1"
  local description="${2:-JSON input}"

  if ! echo "$json_str" | jq empty 2>/dev/null; then
    echo "ERROR: ${description} is not valid JSON" >&2
    return 1
  fi

  return 0
}

# validate_number - Check if value is a valid integer
# Usage: validate_number <value> <param_name>
validate_number() {
  local value="$1"
  local param_name="$2"

  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    echo "ERROR: ${param_name} must be a number, got: ${value}" >&2
    return 1
  fi

  return 0
}

# validate_choice - Check if value is one of allowed choices
# Usage: validate_choice <value> <param_name> <choice1> <choice2> ...
# Example: validate_choice "$mode" "mode" "expansion" "collapse"
validate_choice() {
  local value="$1"
  local param_name="$2"
  shift 2
  local choices=("$@")

  for choice in "${choices[@]}"; do
    if [[ "$value" == "$choice" ]]; then
      return 0
    fi
  done

  echo "ERROR: ${param_name} must be one of: ${choices[*]}, got: ${value}" >&2
  return 1
}
```

**Extraction Steps**:
1. Create `.claude/lib/validation-utils.sh`
2. Update 9 files to use validation functions:
   ```bash
   # Replace validation patterns:

   # OLD:
   if [[ -z "$plan_path" ]] || [[ -z "$phase_num" ]]; then
     echo "ERROR: get_phase_file requires plan_path and phase_num" >&2
     return 1
   fi

   # NEW:
   validate_required "$plan_path" "plan_path" "get_phase_file" || return 1
   validate_required "$phase_num" "phase_num" "get_phase_file" || return 1

   # OLD:
   if [[ ! -f "$file_path" ]]; then
     echo "ERROR: File not found: $file_path" >&2
     return 1
   fi

   # NEW:
   validate_file_exists "$file_path" "input file" || return 1
   ```

**Files to Update** (prioritized by validation count):
1. `parse-adaptive-plan.sh`: 22 validations
2. `auto-analysis-utils.sh`: 19 validations
3. `convert-docs.sh`: 7 validations
4. `error-utils.sh`: 4 validations
5. `checkpoint-utils.sh`: 3 validations
6. Others: 9 total validations

**Testing Strategy**:
```bash
# Unit test validation-utils.sh
bash /home/benjamin/.config/.claude/tests/test_shared_utilities.sh validation

# Integration test: Run existing tests to verify no regressions
bash /home/benjamin/.config/.claude/tests/test_parsing_utilities.sh
bash /home/benjamin/.config/.claude/tests/test_auto_analysis_orchestration.sh
```

### 1.3 Extract json-utils-extended.sh

**Objective**: Add structured JSON builders to complement existing json-utils.sh

**Current json-utils.sh** (5.3K, basic functions):
- Keep existing: `json_escape`, `json_array`, `json_object`
- Add new file for complex operations

**json-utils-extended.sh Structure**:
```bash
#!/usr/bin/env bash
# json-utils-extended.sh - Advanced JSON construction helpers
# Requires: jq (for validation and manipulation)

source "${SCRIPT_DIR}/json-utils.sh"

# build_metadata_json - Construct metadata JSON object
# Usage: build_metadata_json <key1> <value1> <key2> <value2> ...
# Returns: JSON object {"key1": "value1", "key2": "value2"}
build_metadata_json() {
  local -a args=()
  while [[ $# -gt 0 ]]; do
    args+=(--arg "$1" "$2")
    shift 2
  done

  # Build JSON dynamically
  local json_template='{'
  local first=true
  local i=0
  while [[ $i -lt ${#args[@]} ]]; do
    if [[ "${args[$i]}" == "--arg" ]]; then
      local key="${args[$((i+1))]}"
      if [[ "$first" == "true" ]]; then
        json_template+="\"$key\": \$$key"
        first=false
      else
        json_template+=", \"$key\": \$$key"
      fi
      i=$((i+2))
    fi
  done
  json_template+='}'

  jq -n "${args[@]}" "$json_template"
}

# add_json_field - Add field to existing JSON object
# Usage: add_json_field <json_object> <key> <value>
# Returns: Updated JSON object
add_json_field() {
  local json_obj="$1"
  local key="$2"
  local value="$3"

  echo "$json_obj" | jq --arg k "$key" --arg v "$value" '. + {($k): $v}'
}

# merge_json_objects - Merge multiple JSON objects
# Usage: merge_json_objects <json1> <json2> [json3...]
# Returns: Merged JSON object (later values override earlier)
merge_json_objects() {
  local result="$1"
  shift

  for obj in "$@"; do
    result=$(echo "$result" | jq --argjson obj "$obj" '. + $obj')
  done

  echo "$result"
}

# json_array_append - Append element to JSON array
# Usage: json_array_append <json_array> <element>
# Returns: Updated array
json_array_append() {
  local array="$1"
  local element="$2"

  echo "$array" | jq --arg elem "$element" '. += [$elem]'
}

# extract_json_field - Extract field from JSON object
# Usage: extract_json_field <json_object> <field_path>
# Example: extract_json_field "$json" ".artifacts[0].status"
extract_json_field() {
  local json_obj="$1"
  local field_path="$2"

  echo "$json_obj" | jq -r "$field_path"
}
```

**Adoption Strategy**:
1. Identify shell-based JSON construction in 3 utilities:
   ```bash
   # Pattern to replace (from auto-analysis-utils.sh):
   # OLD (shell string building):
   entry="{\"item_id\":\"$item_id\",\"operation\":\"$operation_type\",\"artifact_path\":\"$artifact_path\",\"registered\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"

   # NEW (jq-based):
   entry=$(build_metadata_json \
     "item_id" "$item_id" \
     "operation" "$operation_type" \
     "artifact_path" "$artifact_path" \
     "registered" "$(get_iso_timestamp)")
   ```

2. Update functions in auto-analysis-utils.sh:
   - `register_operation_artifact` (line 583-629)
   - `build_metadata_json` usage in 8 other functions

**Testing Approach**:
```bash
# Test JSON construction
bash /home/benjamin/.config/.claude/tests/test_shared_utilities.sh json

# Verify JSON output is valid
test_json_construction() {
  local result=$(build_metadata_json "foo" "bar" "baz" "qux")
  echo "$result" | jq empty || fail "Invalid JSON output"
  [[ $(echo "$result" | jq -r '.foo') == "bar" ]] || fail "Incorrect field value"
}
```

### 1.4 Update Dependencies

**Sourcing Order** (prevent circular dependencies):
```bash
# Level 0: No dependencies
timestamp-utils.sh
validation-utils.sh

# Level 1: Depends on Level 0
json-utils.sh  # No changes
json-utils-extended.sh  # Source: json-utils.sh

# Level 2: Depends on Level 0-1
error-utils.sh  # Source: timestamp-utils.sh
checkpoint-utils.sh  # Source: timestamp-utils.sh, validation-utils.sh

# Level 3: Depends on Level 0-2
parse-adaptive-plan.sh  # Source: validation-utils.sh
auto-analysis-utils.sh  # Source: timestamp-utils.sh, json-utils-extended.sh, validation-utils.sh
convert-docs.sh  # Source: validation-utils.sh
```

**Implementation**:
```bash
# Add sourcing at top of each file after set -e:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared utilities (order matters!)
source "$SCRIPT_DIR/timestamp-utils.sh"
source "$SCRIPT_DIR/validation-utils.sh"
source "$SCRIPT_DIR/json-utils.sh" 2>/dev/null || true
source "$SCRIPT_DIR/json-utils-extended.sh" 2>/dev/null || true
```

### 1.5 Part 1 Testing & Commit

**Testing Sequence**:
```bash
# 1. Unit tests for new utilities
bash /home/benjamin/.config/.claude/tests/test_shared_utilities.sh all

# 2. Integration tests (verify no regressions)
bash /home/benjamin/.config/.claude/tests/test_parsing_utilities.sh
bash /home/benjamin/.config/.claude/tests/test_auto_analysis_orchestration.sh
bash /home/benjamin/.config/.claude/tests/test_command_integration.sh

# 3. Smoke test all commands
bash /home/benjamin/.config/.claude/commands/expand.md --help
bash /home/benjamin/.config/.claude/commands/collapse.md --help
```

**Git Commit** (Part 1 complete):
```bash
git add .claude/lib/{timestamp,validation,json-utils-extended}-utils.sh
git add .claude/lib/{auto-analysis,convert-docs,parse-adaptive-plan,checkpoint,error,artifact,agent-registry}-utils.sh
git add .claude/tests/test_shared_utilities.sh
git commit -m "refactor(Part 1): extract shared utilities from large files

- Extract timestamp-utils.sh (timestamp operations)
- Extract validation-utils.sh (parameter validation)
- Create json-utils-extended.sh (advanced JSON helpers)
- Update 8 utilities to use shared functions
- Reduce code duplication by ~200 lines
- Improve consistency and testability

Testing: All unit and integration tests passing"
```

---

## Part 2: Modularize auto-analysis-utils.sh (4-5 hours)

### 2.1 Function Categorization

**Current Structure** (1,755 lines, 19 functions):

**Category 1: Agent Invocation** (lines 14-132, 1 function)
- `invoke_complexity_estimator` - Construct prompts for complexity_estimator agent

**Category 2: Phase Analysis** (lines 134-318, 4 functions)
- `analyze_phases_for_expansion` - Analyze inline phases
- `analyze_phases_for_collapse` - Analyze expanded phases
- `analyze_stages_for_expansion` - Analyze inline stages
- `analyze_stages_for_collapse` - Analyze expanded stages

**Category 3: Artifact Management** (lines 571-713, 3 functions)
- `register_operation_artifact` - Register artifact in tracking
- `get_artifact_path` - Retrieve artifact path
- `validate_operation_artifacts` - Verify artifacts exist

**Category 4: Parallel Orchestration** (lines 715-1294, 8 functions)
- `invoke_expansion_agents_parallel` - Launch parallel expansions
- `aggregate_expansion_artifacts` - Validate expansion results
- `coordinate_metadata_updates` - Update plan metadata
- `invoke_collapse_agents_parallel` - Launch parallel collapses
- `aggregate_collapse_artifacts` - Validate collapse results
- `coordinate_collapse_metadata_updates` - Update metadata for collapses
- (Plus 2 helper functions)

**Category 5: Analysis Reporting** (lines 497-570, 1295-1755, 5 functions)
- `generate_analysis_report` - Format human-readable report
- `review_plan_hierarchy` - Analyze plan organization
- `run_second_round_analysis` - Re-analyze after operations
- `present_recommendations_for_approval` - User approval gate
- `generate_recommendations_report` - Create recommendation file

### 2.2 Module Structure

**Module 1: agent-invocation.sh** (~200 lines)
- Functions: `invoke_complexity_estimator`, `construct_agent_prompt` (helper), `validate_agent_response` (new helper)
- Dependencies: validation-utils.sh, json-utils-extended.sh

**Module 2: analysis-orchestration.sh** (~450 lines)
- Functions: Phase/stage analysis (4 functions), `extract_plan_context` (new helper)
- Dependencies: parse-adaptive-plan.sh, agent-invocation.sh, json-utils-extended.sh

**Module 3: artifact-registry.sh** (~200 lines)
- Functions: Artifact tracking (3 functions), `create_artifact_registry` (new helper)
- Dependencies: timestamp-utils.sh, validation-utils.sh, json-utils-extended.sh

**Module 4: parallel-coordination.sh** (~600 lines)
- Functions: Parallel orchestration (8 functions)
- Dependencies: artifact-registry.sh, agent-invocation.sh, checkpoint-utils.sh, parse-adaptive-plan.sh

**Module 5: analysis-reporting.sh** (~400 lines)
- Functions: Reporting and user interaction (5 functions)
- Dependencies: timestamp-utils.sh, parse-adaptive-plan.sh

### 2.3 Dependency Resolution

**Sourcing Hierarchy** (auto-analysis modules):
```
Level 0 (shared):
  - timestamp-utils.sh
  - validation-utils.sh
  - json-utils-extended.sh

Level 1 (parsing):
  - parse-adaptive-plan.sh

Level 2 (auto-analysis foundation):
  - agent-invocation.sh
  - artifact-registry.sh

Level 3 (auto-analysis orchestration):
  - analysis-orchestration.sh
  - parallel-coordination.sh
  - analysis-reporting.sh

Level 4 (commands):
  - expand.md
  - collapse.md
```

**No circular dependencies** - each level only sources from lower levels.

### 2.4 Extraction Process

**Step 1: Create stub files**
```bash
cd /home/benjamin/.config/.claude/lib
touch agent-invocation.sh analysis-orchestration.sh artifact-registry.sh parallel-coordination.sh analysis-reporting.sh

# Add headers to each
for file in agent-invocation.sh analysis-orchestration.sh artifact-registry.sh parallel-coordination.sh analysis-reporting.sh; do
  cat > "$file" <<'EOF'
#!/usr/bin/env bash
# [Module Name] - [Brief Description]
# Part of auto-analysis-utils.sh modularization

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source dependencies here
EOF
done
```

**Step 2: Move functions (one module at a time)**
- Extract each module separately
- Test after each module
- Commit after each module

**Step 3: Update commands**
```bash
# Update expand.md and collapse.md to source new modules:
source "${SCRIPT_DIR}/../lib/analysis-orchestration.sh"
source "${SCRIPT_DIR}/../lib/parallel-coordination.sh"
source "${SCRIPT_DIR}/../lib/analysis-reporting.sh"
```

### 2.5 Testing Strategy

**Per-Module Testing**:
```bash
# Test agent-invocation.sh
test_invoke_complexity_estimator() {
  local content='[{"item_id":"phase_1","item_name":"Test","content":"foo"}]'
  local context='{"overview":"test","goals":"test","constraints":"test","current_level":"0"}'
  local result=$(invoke_complexity_estimator "expansion" "$content" "$context")
  [[ -n "$result" ]] || fail "No result from agent invocation"
}
```

**Integration Testing**:
```bash
# Run existing auto-analysis tests
bash /home/benjamin/.config/.claude/tests/test_auto_analysis_orchestration.sh
bash /home/benjamin/.config/.claude/tests/test_parallel_expansion.sh
bash /home/benjamin/.config/.claude/tests/test_parallel_collapse.sh
```

### 2.6 Part 2 Commit

```bash
git add .claude/lib/{agent-invocation,analysis-orchestration,artifact-registry,parallel-coordination,analysis-reporting}.sh
git rm .claude/lib/auto-analysis-utils.sh
git add .claude/commands/{expand,collapse}.md
git commit -m "refactor(Part 2): modularize auto-analysis-utils.sh into 5 focused files

Modules created:
- agent-invocation.sh (200 lines) - Agent prompt construction
- analysis-orchestration.sh (450 lines) - Phase/stage analysis
- artifact-registry.sh (200 lines) - Artifact tracking
- parallel-coordination.sh (600 lines) - Parallel operations
- analysis-reporting.sh (400 lines) - Report generation

Changes:
- Split 1,755 lines into 5 modules (<600 lines each)
- Clear responsibility separation
- No circular dependencies
- Update expand.md and collapse.md sourcing

Testing: All auto-analysis tests passing"
```

---

## Part 3: Modularize convert-docs.sh (4-5 hours)

### 3.1 Function Categorization

**Current Structure** (1,502 lines, 29 functions):

**Category 1: Conversion Core** (14 functions)
- Tool detection, conversion functions, main dispatcher, timeout wrapper, discovery

**Category 2: Validation & Resource Management** (8 functions)
- Validation, resource management, locking, reporting

**Category 3: Parallel Processing** (4 functions)
- Threading, progress tracking, logging, worker management

**Category 4: UI & Reporting** (7 functions)
- Display, summary, main execution logic

### 3.2 Module Structure

**Module 1: conversion-core.sh** (~500 lines)
- Core conversion logic and tool detection

**Module 2: conversion-validation.sh** (~350 lines)
- All validation and resource management

**Module 3: conversion-parallel.sh** (~200 lines)
- Parallel processing infrastructure

**Module 4: conversion-ui.sh** (~300 lines)
- User interface and reporting

**Main Script: convert-docs.sh** (~150 lines)
- Main execution flow only

### 3.3 Extraction Process

Extract in order: validation → parallel → UI → core → consolidate main script

### 3.4 Testing Strategy

**Module Testing**: Test each module independently
**Integration Testing**: Run full conversion workflows

### 3.5 Part 3 Commit

```bash
git add .claude/lib/{conversion-core,conversion-validation,conversion-parallel,conversion-ui}.sh
git add .claude/lib/convert-docs.sh
git commit -m "refactor(Part 3): modularize convert-docs.sh into 4 focused modules

Modules created:
- conversion-core.sh (500 lines) - Core conversion logic
- conversion-validation.sh (350 lines) - Validation and resources
- conversion-parallel.sh (200 lines) - Parallel processing
- conversion-ui.sh (300 lines) - User interface

Changes:
- Split 1,502 lines into 4 modules + thin wrapper
- Clear separation of concerns
- Improved testability
- Main script now 150 lines

Testing: All conversion tests passing"
```

---

## Part 4: Modularize parse-adaptive-plan.sh (4-5 hours)

### 4.1 Function Categorization

**Current Structure** (1,298 lines, 33 functions):

**Category 1: Structure Detection** (6 functions)
**Category 2: Listing & Navigation** (2 functions)
**Category 3: Content Extraction** (6 functions)
**Category 4: Metadata Management** (12 functions)
**Category 5: Merge & Cleanup** (7 functions)

### 4.2 Module Structure

**Module 1: plan-detection.sh** (~250 lines)
- Structure detection and navigation

**Module 2: plan-extraction.sh** (~350 lines)
- Content extraction and revision

**Module 3: plan-metadata.sh** (~400 lines)
- All metadata operations

**Module 4: plan-merging.sh** (~300 lines)
- Merging and cleanup operations

### 4.3 Update Commands

Commands using parsing utilities:
1. `expand.md` - Sources: detection, extraction, metadata
2. `collapse.md` - Sources: detection, merging, metadata
3. `revise.md` - Sources: detection
4. `list.md` - Sources: detection
5. `implement.md` - Sources: detection

### 4.4 Part 4 Commit

```bash
git add .claude/lib/{plan-detection,plan-extraction,plan-metadata,plan-merging}.sh
git add .claude/lib/parse-adaptive-plan.sh
git add .claude/commands/{expand,collapse,revise,list,implement}.md
git commit -m "refactor(Part 4): modularize parse-adaptive-plan.sh into 4 focused modules

Modules created:
- plan-detection.sh (250 lines) - Structure level detection
- plan-extraction.sh (350 lines) - Content extraction
- plan-metadata.sh (400 lines) - Metadata management
- plan-merging.sh (300 lines) - Merge and cleanup

Changes:
- Split 1,298 lines into 4 modules
- Progressive structure handled consistently
- Update 5 commands to source specific modules
- Clear dependency hierarchy

Testing: All parsing tests passing"
```

---

## Part 5: Efficiency Improvements (5-7 hours)

### 5.1 Multiple Grep Elimination

**Problem**: Multiple `grep` calls on same file in loops (inefficient I/O)

**Optimization**: Replace with single awk pass
```bash
# OLD (2 file reads):
heading_count=$(grep -c '^#' "$md_file")
table_count=$(grep -c '^\|' "$md_file")

# NEW (1 file read):
read heading_count table_count < <(
  awk '
    /^#/ { headings++ }
    /^\|/ { tables++ }
    END { print headings+0, tables+0 }
  ' "$md_file"
)
```

**Benefit**: 50% reduction in file I/O

### 5.2 jq Adoption for JSON Construction

**Problem**: Shell string concatenation for JSON is error-prone

**Optimization**: Use jq for all JSON construction
```bash
# OLD (shell string):
entry="{\"item_id\":\"$id\",\"path\":\"$path\"}"

# NEW (jq-based):
entry=$(jq -n --arg id "$id" --arg path "$path" '{item_id: $id, artifact_path: $path}')
```

**Benefits**: Automatic escaping, readable structure, validation

### 5.3 Structured Error Returns

**Improvement**: Return structured error information as JSON
```bash
validate_input_file() {
  # ... validation logic ...
  if [[ "${magic^^}" != "504B" ]]; then
    echo '{"error":"invalid_magic","expected":"504B","got":"'"$magic"'"}' >&2
    return 1
  fi
}
```

### 5.4 Function Boundary Validation

**Pattern**: Add assertion-style validation at function entry
```bash
function_name() {
  validate_required "$param1" "param1" "${FUNCNAME[0]}" || return 1
  validate_number "$phase_num" "phase_num" || return 1
  validate_choice "$mode" "mode" "expansion" "collapse" || return 1

  # Function logic...
}
```

### 5.5 Part 5 Commit

```bash
git add .claude/lib/{conversion-validation,plan-extraction,analysis-orchestration,artifact-registry}.sh
git add .claude/lib/validation-utils.sh
git commit -m "refactor(Part 5): efficiency improvements across all modules

Optimizations:
- Consolidate multiple grep to single awk (50% I/O reduction)
- Adopt jq for JSON construction (safer, more readable)
- Add structured error returns with JSON
- Implement function boundary validation

Performance: 40-50% improvement in repeated operations
Testing: All regression tests passing"
```

---

## Summary

This phase transforms 4,555 lines across 3 utilities into 9-12 focused modules plus 3 shared libraries.

**Estimated Time**:
- Part 1 (Shared Utilities): 5-6 hours
- Part 2 (Auto-Analysis): 4-5 hours
- Part 3 (Convert-Docs): 4-5 hours
- Part 4 (Parse-Adaptive-Plan): 4-5 hours
- Part 5 (Efficiency): 5-7 hours
- **Total**: 22-28 hours

**Risk Mitigation**:
- Comprehensive testing after each part
- Git commits after each module
- Existing test suites verify no regressions
- Incremental approach (shared utilities first)

**Benefits**:
1. **Maintainability**: Clear module boundaries, single responsibility
2. **Testability**: Unit tests per module
3. **Consistency**: Shared utilities eliminate duplication
4. **Performance**: 40-50% improvement in repeated operations
5. **Safety**: Structured validation and error handling
