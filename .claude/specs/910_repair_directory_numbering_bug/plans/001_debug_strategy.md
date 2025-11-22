# Debug Strategy Plan: Directory Numbering Bug Fix

## Metadata
- **Date**: 2025-11-21
- **Feature**: Fix topic directory numbering to prevent 4-digit anomalies
- **Scope**: topic-utils.sh, workflow-initialization.sh
- **Estimated Phases**: 3
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Research Reports**:
  - [Root Cause Analysis](../reports/001_root_cause_analysis.md)

## Overview

This plan addresses the directory numbering bug where `/repair` created `1039_build_errors_repair` instead of `910_build_errors_repair`. The fix involves:
1. Expanding glob patterns to detect any numeric prefix
2. Adding validation to ensure 3-digit format
3. Implementing defensive state isolation

## Success Criteria

- [ ] All numeric-prefix directories detected (not just 3-digit)
- [ ] Topic numbers validated to be exactly 3 digits
- [ ] State isolation prevents variable leakage
- [ ] Existing tests pass
- [ ] New test covers edge case detection

## Phase 1: Pattern Enhancement

**Objective**: Update `get_next_topic_number` to detect ALL numeric-prefix directories

### Stage 1.1: Update Glob Pattern

**File**: `.claude/lib/plan/topic-utils.sh`
**Lines**: 28-31

**Current Code**:
```bash
max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
  sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
  sort -n | tail -1)
```

**Updated Code**:
```bash
# Use extended pattern to match ANY numeric prefix (1+ digits)
max_num=$(ls -1d "${specs_root}"/[0-9]*_* 2>/dev/null | \
  grep -E '/[0-9]+_' | \
  sed 's/.*\/\([0-9]\+\)_.*/\1/' | \
  sort -n | tail -1)
```

### Stage 1.2: Update Idempotent Check Pattern

**File**: `.claude/lib/plan/topic-utils.sh`
**Lines**: 54-55

**Current Code**:
```bash
existing=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_"${topic_name}" 2>/dev/null | head -1 || echo "")
```

**Updated Code**:
```bash
# Match any numeric prefix for the given topic name
existing=$(ls -1d "${specs_root}"/[0-9]*_"${topic_name}" 2>/dev/null | head -1 || echo "")
```

### Stage 1.3: Update Number Extraction

**File**: `.claude/lib/plan/topic-utils.sh`
**Lines**: 58-59

**Current Code**:
```bash
basename "$existing" | sed 's/^\([0-9][0-9][0-9]\)_.*/\1/'
```

**Updated Code**:
```bash
# Extract any-length numeric prefix
basename "$existing" | sed 's/^\([0-9]\+\)_.*/\1/'
```

## Phase 2: Validation Layer

**Objective**: Add validation to catch invalid topic numbers before directory creation

### Stage 2.1: Add Number Validation Function

**File**: `.claude/lib/plan/topic-utils.sh`
**Location**: After `get_next_topic_number` function

**New Function**:
```bash
# validate_topic_number: Ensure topic number is valid 3-digit format
#
# Arguments:
#   $1 - topic_num: The topic number to validate
#
# Returns:
#   0 if valid (001-999)
#   1 if invalid
#
validate_topic_number() {
  local topic_num="$1"

  # Must be exactly 3 digits
  if ! echo "$topic_num" | grep -Eq '^[0-9]{3}$'; then
    echo "ERROR: Topic number must be exactly 3 digits, got: $topic_num" >&2
    return 1
  fi

  # Must be in valid range (001-999)
  local num_value=$((10#$topic_num))
  if [ "$num_value" -lt 1 ] || [ "$num_value" -gt 999 ]; then
    echo "ERROR: Topic number out of range (1-999): $topic_num" >&2
    return 1
  fi

  return 0
}
```

### Stage 2.2: Integrate Validation in get_next_topic_number

**File**: `.claude/lib/plan/topic-utils.sh`
**Lines**: 33-38 (replace existing increment logic)

**Updated Code**:
```bash
if [ -z "$max_num" ]; then
  echo "001"
else
  local next_num=$((10#$max_num + 1))

  # Check for overflow
  if [ "$next_num" -gt 999 ]; then
    echo "ERROR: Topic number would exceed 999 (max: $max_num, next: $next_num)" >&2
    echo "HINT: Archive old specs to free up numbers" >&2
    return 1
  fi

  printf "%03d" "$next_num"
fi
```

### Stage 2.3: Add Validation in workflow-initialization.sh

**File**: `.claude/lib/workflow/workflow-initialization.sh`
**Location**: After line 477 (after topic_num assignment)

**New Code**:
```bash
# Validate topic number format (defensive check)
if ! validate_topic_number "$topic_num" 2>/dev/null; then
  echo "ERROR: Generated invalid topic number: $topic_num" >&2
  if declare -f log_command_error >/dev/null 2>&1; then
    log_command_error \
      "${COMMAND_NAME:-/unknown}" \
      "${WORKFLOW_ID:-unknown}" \
      "${USER_ARGS:-}" \
      "validation_error" \
      "Invalid topic number generated" \
      "initialize_workflow_paths" \
      "$(jq -n --arg num "$topic_num" --arg name "$topic_name" \
         '{topic_num: $num, topic_name: $name}')"
  fi
  return 1
fi
```

## Phase 3: State Isolation

**Objective**: Prevent variable leakage between workflow invocations

### Stage 3.1: Add Defensive Unset

**File**: `.claude/lib/workflow/workflow-initialization.sh`
**Location**: Before line 477 (before topic_num calculation)

**New Code**:
```bash
# Defensive: Clear any pre-existing topic variables to prevent state leakage
unset topic_num topic_name topic_path 2>/dev/null || true
```

### Stage 3.2: Add Source Guard Reset Option

**File**: `.claude/lib/workflow/workflow-initialization.sh`
**Location**: At top of initialize_workflow_paths function

**New Code**:
```bash
# Allow forced re-initialization for testing
if [ "${FORCE_REINIT:-}" = "1" ]; then
  unset WORKFLOW_INITIALIZATION_SOURCED 2>/dev/null || true
fi
```

### Stage 3.3: Add Unit Test

**File**: `.claude/tests/unit/test_topic_numbering.sh` (new file)

```bash
#!/usr/bin/env bash
# Test topic number generation and validation

set -e

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

source "$(dirname "$0")/../../lib/plan/topic-utils.sh"

echo "=== Test: get_next_topic_number ==="

# Test empty directory
result=$(get_next_topic_number "$TEST_DIR")
[ "$result" = "001" ] || { echo "FAIL: Expected 001, got $result"; exit 1; }
echo "PASS: Empty directory returns 001"

# Test with existing directories
mkdir -p "$TEST_DIR/001_test"
mkdir -p "$TEST_DIR/002_test"
result=$(get_next_topic_number "$TEST_DIR")
[ "$result" = "003" ] || { echo "FAIL: Expected 003, got $result"; exit 1; }
echo "PASS: Increments correctly"

# Test with 4-digit anomaly (regression test for bug)
mkdir -p "$TEST_DIR/1039_anomaly"
result=$(get_next_topic_number "$TEST_DIR")
# Should return 1040 (detects the 4-digit directory) or fail gracefully
if [ "$result" = "1040" ] || [ -z "$result" ]; then
  echo "PASS: Detects 4-digit directories"
else
  echo "FAIL: Did not detect 4-digit directory, got $result"
  exit 1
fi

echo "=== Test: validate_topic_number ==="

# Valid numbers
validate_topic_number "001" || { echo "FAIL: 001 should be valid"; exit 1; }
validate_topic_number "999" || { echo "FAIL: 999 should be valid"; exit 1; }
echo "PASS: Valid numbers accepted"

# Invalid numbers
validate_topic_number "1039" 2>/dev/null && { echo "FAIL: 1039 should be invalid"; exit 1; }
validate_topic_number "0" 2>/dev/null && { echo "FAIL: 0 should be invalid"; exit 1; }
validate_topic_number "abc" 2>/dev/null && { echo "FAIL: abc should be invalid"; exit 1; }
echo "PASS: Invalid numbers rejected"

echo ""
echo "All tests passed!"
```

## Implementation Order

1. **Phase 1** (Pattern Enhancement) - Must be first to detect existing anomalies
2. **Phase 2** (Validation Layer) - Prevents future invalid numbers
3. **Phase 3** (State Isolation) - Defensive measure against root cause

## Rollback Plan

If issues arise:
1. Revert topic-utils.sh to previous version
2. Revert workflow-initialization.sh changes
3. Manually fix any incorrectly numbered directories

## Testing Strategy

1. Run existing test suite: `./run_all_tests.sh`
2. Run new unit test: `bash .claude/tests/unit/test_topic_numbering.sh`
3. Manual verification: Run `/repair` and verify correct numbering
