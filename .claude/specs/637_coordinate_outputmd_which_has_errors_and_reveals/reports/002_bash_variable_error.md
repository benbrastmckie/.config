# Bash Variable Indirection Error in workflow-initialization.sh

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: Bash variable indirection error at line 330 in workflow-initialization.sh
- **Report Type**: codebase analysis

## Executive Summary

The error "!var_name: unbound variable" at workflow-initialization.sh:330 is caused by using indirect expansion (`${!var_name}`) with `set -u` flag when the target variable doesn't exist. The current uncommitted change reverted from nameref pattern back to indirect expansion, but this creates the exact problem that the nameref pattern was intended to solve. However, the issue is NOT with the syntax choice but with bash's subprocess isolation model - the `set -u` flag was removed from line 21 but indirect expansion still triggers "unbound variable" errors when variables don't exist, regardless of the pattern used.

## Findings

### 1. Current Error Context

**Location**: `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:330`

**Error Message**: `!var_name: unbound variable`

**Code Section** (lines 324-332):
```bash
reconstruct_report_paths_array() {
  REPORT_PATHS=()
  for i in $(seq 0 $((REPORT_PATHS_COUNT - 1))); do
    local var_name="REPORT_PATH_$i"
    # Use indirect expansion instead of nameref to avoid "unbound variable" with set -u
    # ${!var_name} expands to the value of the variable whose name is in $var_name
    REPORT_PATHS+=("${!var_name}")
  done
}
```

**Root Cause**: The function expects variables like `REPORT_PATH_0`, `REPORT_PATH_1`, etc. to exist, but when they don't exist and indirect expansion is attempted, bash reports "unbound variable" error.

### 2. History of Changes

**Commit cb1f887f** (2025-11-05):
- **Title**: "feat(594): complete Phase 2 - Fix Indirect Variable References in Library Files"
- **Change**: Replaced `${!var_name}` with nameref pattern (`local -n path_ref="$var_name"`)
- **Reason**: "Replace bash indirect variable expansion (${!varname}) with nameref pattern to eliminate 'bash: !: command not found' errors during library sourcing"
- **Result**: Fixed history expansion errors but introduced new issue with `set -u`

**Current Uncommitted Change**:
- **Change**: Reverted nameref back to indirect expansion
- **Comment**: "Use indirect expansion instead of nameref to avoid 'unbound variable' with set -u"
- **Problem**: This comment is misleading - indirect expansion actually CAUSES the unbound variable error, not prevents it

### 3. Technical Analysis: Indirect Expansion vs Nameref

**Test Results** (from `/tmp/test_indirect.sh`):

```bash
# Test 1: Indirect expansion with defined variable
var_name="REPORT_PATH_0"
export REPORT_PATH_0="test_value"
echo "${!var_name}"
# Result: ✓ SUCCESS - outputs "test_value"

# Test 2: Indirect expansion with undefined variable
var_name="NONEXISTENT_VAR"
echo "${!var_name}"
# Result: ✗ FAILURE - "/tmp/test_indirect.sh: line 11: !var_name: unbound variable"

# Test 3: Nameref pattern
test_nameref() {
  local var_name="REPORT_PATH_1"
  export REPORT_PATH_1="nameref_test"
  local -n path_ref="$var_name"
  echo "$path_ref"
}
# Result: ✓ SUCCESS - outputs "nameref_test"

# Test 4: Nameref with undefined variable
test_nameref_undefined() {
  local var_name="UNDEFINED_VAR"
  local -n path_ref="$var_name"
  echo "$path_ref"
}
# Result: ✗ FAILURE - "bash: warning: path_ref: circular name reference"
```

**Key Finding**: BOTH patterns fail with undefined variables, but in different ways:
- Indirect expansion: "!var_name: unbound variable" error
- Nameref: "circular name reference" warning (when variable doesn't exist)

### 4. The Real Problem: Missing Context

**Critical Discovery**: The error occurs because `REPORT_PATH_N` variables are expected to be set BEFORE calling `reconstruct_report_paths_array()`, but the bash subprocess isolation model means these variables must be explicitly loaded from state files.

**From Bash Block Execution Model documentation** (`/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md`):

> Each bash block runs in a completely separate process
> - Process ID (`$$`) changes between blocks
> - All environment variables reset (exports lost)
> - Only files written to disk persist across blocks

**The Pattern That Should Be Used** (from same documentation, lines 233-248):
```bash
# In each bash block:

# 1. Re-source library (functions lost across block boundaries)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

# 2. Load workflow state
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# 3. Update state
append_workflow_state "CURRENT_STATE" "research"
append_workflow_state "REPORT_COUNT" "3"
```

### 5. The Array Export Pattern

**From workflow-initialization.sh** (lines 293-302):
```bash
# Export arrays (requires bash 4.2+ for declare -g)
# Note: Arrays must be re-declared in calling script
# Workaround: Use REPORT_PATHS_COUNT and individual REPORT_PATH_N variables
export REPORT_PATHS_COUNT="${#report_paths[@]}"
# Use C-style for loop to avoid history expansion errors
# The ${!array[@]} syntax triggers "!: command not found" in some bash contexts
array_length=${#report_paths[@]}
for ((i=0; i<array_length; i++)); do
  export "REPORT_PATH_$i=${report_paths[$i]}"
done
```

**Comment Analysis**: The comment "Arrays must be re-declared in calling script" acknowledges that bash arrays don't survive subprocess boundaries via export alone.

### 6. Related Documentation

**Spec 620** (bash history expansion errors):
- Fixed 6 issues including process ID patterns, variable scoping, trap handlers
- Result: 100% test pass rate achieved
- Key lesson: "Code review alone is insufficient for bash block sequences"

**Spec 630** (state persistence):
- Fixed report path loss across blocks
- Implemented state-persistence.sh library
- Result: 40+ fixes applied

**Spec 636** (workflow initialization variable error):
- Report: `/home/benjamin/.config/.claude/specs/636_001_coordinate_improvementsmd_appears_to_have/reports/002_workflow_initialization_variable_error.md`
- Identified WORKFLOW_DESCRIPTION overwriting issue
- Recommended save-before-source pattern

## Recommendations

### 1. Use Defensive Checks Before Variable Access

Add existence check before attempting indirect expansion or nameref:

```bash
reconstruct_report_paths_array() {
  REPORT_PATHS=()
  for i in $(seq 0 $((REPORT_PATHS_COUNT - 1))); do
    local var_name="REPORT_PATH_$i"

    # Defensive check: verify variable exists before accessing
    if [ -z "${!var_name+x}" ]; then
      echo "WARNING: $var_name not set, skipping" >&2
      continue
    fi

    # Safe to use indirect expansion now
    REPORT_PATHS+=("${!var_name}")
  done
}
```

**Explanation**: `${!var_name+x}` expands to "x" if the variable exists (even if empty), or nothing if undefined. This allows checking existence without triggering "unbound variable" error.

### 2. Ensure State Loading Before Array Reconstruction

The calling code must load state before reconstructing arrays:

```bash
# Load workflow state (restores REPORT_PATH_0, REPORT_PATH_1, etc.)
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# NOW safe to reconstruct array
reconstruct_report_paths_array
```

### 3. Consider Alternative: JSON-Based Array Persistence

Replace individual `REPORT_PATH_N` exports with JSON array:

```bash
# Save (in initialize_workflow_paths)
REPORT_PATHS_JSON=$(printf '%s\n' "${report_paths[@]}" | jq -R . | jq -s .)
export REPORT_PATHS_JSON

# Load (in calling script)
if [ -n "${REPORT_PATHS_JSON:-}" ]; then
  mapfile -t REPORT_PATHS < <(echo "$REPORT_PATHS_JSON" | jq -r '.[]')
fi
```

**Advantages**:
- Single variable to track (not N+1 variables)
- No index-based reconstruction needed
- Survives state persistence more reliably
- Already used in coordinate.md (line 403)

### 4. Update Error Messages and Comments

**Current comment is misleading** (line 328-329):
```bash
# Use indirect expansion instead of nameref to avoid "unbound variable" with set -u
```

**Should say**:
```bash
# Use indirect expansion (simpler than nameref, compatible with all bash versions)
# Note: Variables must be loaded from state before calling this function
```

### 5. Remove `set -u` or Use Conditional Logic

**Current state** (line 21):
```bash
set -eo pipefail  # Removed -u flag to allow ${VAR:-} pattern in sourcing scripts
```

**Options**:
1. Keep `set -u` removed (current approach, allows graceful degradation)
2. Add existence checks everywhere (verbose but explicit)
3. Use subshells with `set +u` for specific operations

**Recommendation**: Keep `set -u` removed for libraries, but use existence checks in critical paths.

## References

- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:324-332` - Function with error
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md` - Subprocess isolation patterns
- `/home/benjamin/.config/.claude/specs/620_fix_coordinate_bash_history_expansion_errors/reports/003_bash_variable_scoping_diagnostic.md` - Variable scoping analysis
- `/home/benjamin/.config/.claude/specs/630_fix_coordinate_report_paths_state_persistence/reports/003_nameref_fix.md` - Previous nameref fix attempt
- Git commit cb1f887f - Original nameref introduction
- Git diff HEAD - Current uncommitted reversion
