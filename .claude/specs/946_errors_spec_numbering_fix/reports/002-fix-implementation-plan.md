# Fix Implementation Plan: Spec Numbering Collision Prevention

## Metadata
- **Date**: 2025-11-24
- **Analyst**: research-specialist
- **Related Report**: 001-numbering-collision-root-cause.md
- **Complexity**: 3
- **Type**: research-and-plan

## Summary

Implement comprehensive fixes to prevent duplicate topic number allocation in the specs directory. The root cause is likely specs_root path inconsistency causing different processes to use different lock files, breaking atomicity guarantees. The fix involves canonicalizing paths, adding verification, and improving observability.

## Problem Statement

Two directories with number 923 were created 25 minutes apart:
- `923_error_analysis_research` (2025-11-23 17:28:06)
- `923_subagent_converter_skill_strategy` (2025-11-23 17:53:13)

This violates the sequential numbering guarantee documented in directory-protocols.md and indicates a race condition despite the atomic allocation mechanism.

## Standards Compliance

This fix must conform to:

### 1. Directory Protocols (.claude/docs/concepts/directory-protocols.md)

**Lines 120-196: Atomic Topic Allocation**
- MUST use atomic allocation for all topic creation
- MUST prevent race conditions via exclusive file locking
- MUST detect and resolve number collisions
- MUST provide sequential numbering starting from 000

**Lines 177-179: Numbering Behavior**
- First topic: 000 (not 001)
- After 999, wrap to 000 with collision detection
- If all 1000 numbers exhausted, return error

**Lines 181-184: Lock File**
- Location: `${specs_root}/.topic_number.lock`
- Never deleted (persists for subsequent allocations)
- Empty file (<1KB, gitignored)
- Lock released automatically when process exits

### 2. Code Standards (.claude/docs/reference/standards/code-standards.md)

**Path Handling**
- Use canonical absolute paths for all directory operations
- Validate all path inputs before use
- Handle symlinks by resolving to real paths

**Error Handling**
- Validate pre-conditions before critical operations
- Log errors with full context (paths, values, state)
- Provide actionable error messages with diagnostic info

### 3. Error Logging Standards (.claude/docs/concepts/patterns/error-handling.md)

**Centralized Logging**
- Log all allocation failures to .claude/data/logs/errors.jsonl
- Include workflow_id, command_name, error context
- Use error type: "state_error" for allocation failures

### 4. Clean-Break Development (.claude/docs/reference/standards/clean-break-development.md)

**No Backward Compatibility**
- Remove deprecated code paths (no compatibility wrappers)
- Update all callers to new behavior atomically
- No feature flags or transition periods

## Fix Strategy

### Phase 1: Path Canonicalization

**File**: .claude/lib/core/unified-location-detection.sh

**Changes**:
1. Add `canonicalize_path()` helper function using `readlink -f`
2. Update `allocate_and_create_topic()` to canonicalize specs_root on entry
3. Validate specs_root is absolute path (starts with `/`)

**Rationale**: Ensures all processes use identical specs_root paths, preventing multiple lock files.

### Phase 2: Collision Detection Enhancement

**File**: .claude/lib/core/unified-location-detection.sh

**Changes**:
1. Log when collision detection loop executes (for observability)
2. Add max_num verification: log if max_num doesn't match actual directory scan
3. Add post-creation verification: scan for duplicates after mkdir

**Rationale**: Provides diagnostic data for future issues and catches allocation bugs immediately.

### Phase 3: Lock File Validation

**File**: .claude/lib/core/unified-location-detection.sh

**Changes**:
1. Check for multiple `.topic_number.lock` files in specs tree
2. Warn if lock files found in unexpected locations
3. Include lock file path in all error messages

**Rationale**: Detects specs_root inconsistency issues before they cause collisions.

### Phase 4: Error Logging Integration

**File**: .claude/lib/core/unified-location-detection.sh

**Changes**:
1. Source error-handling.sh library (with suppression for standalone use)
2. Log allocation failures with full context:
   - specs_root (canonical path)
   - topic_name
   - max_num found
   - topic_number allocated
   - collision loop iterations
3. Log successful allocations at DEBUG level (for audit trail)

**Rationale**: Enables `/errors` command to track and analyze allocation issues.

### Phase 5: Verification and Testing

**File**: .claude/tests/integration/test_atomic_topic_allocation.sh (new)

**Test Coverage**:
1. Concurrent allocation (1000 parallel processes)
   - Verify 0% collision rate
   - Verify sequential numbering
   - Verify all allocations logged

2. Path canonicalization
   - Test with relative paths
   - Test with symlinks
   - Test with trailing slashes
   - Verify all resolve to same canonical path

3. Collision detection
   - Create directory manually with next number
   - Verify allocation skips to next available
   - Verify collision logged

4. Lock file validation
   - Create lock files in multiple locations
   - Verify warning issued
   - Verify canonical path used for lock

5. Error logging
   - Trigger allocation failure
   - Verify logged to errors.jsonl
   - Verify error contains all diagnostic context

**Success Criteria**:
- All tests pass with 100% reliability
- No race conditions under concurrent load
- All allocations logged with complete context

## Implementation Details

### canonicalize_path() Function

```bash
# canonicalize_path(path)
# Purpose: Resolve path to absolute canonical form
# Arguments: $1 - path to canonicalize
# Returns: Absolute canonical path on stdout
# Exit codes: 0 on success, 1 if path doesn't exist
canonicalize_path() {
  local path="$1"

  if [ ! -e "$path" ]; then
    # Path doesn't exist - try to canonicalize parent
    local parent=$(dirname "$path")
    if [ -e "$parent" ]; then
      local parent_canonical=$(readlink -f "$parent")
      echo "${parent_canonical}/$(basename "$path")"
      return 0
    else
      echo "ERROR: Cannot canonicalize non-existent path: $path" >&2
      return 1
    fi
  fi

  readlink -f "$path"
}
```

### allocate_and_create_topic() Updates

**Before** (current code):
```bash
allocate_and_create_topic() {
  local specs_root="$1"
  local topic_name="$2"
  local lockfile="${specs_root}/.topic_number.lock"

  mkdir -p "$specs_root"
  # ... rest of function
```

**After** (fixed code):
```bash
allocate_and_create_topic() {
  local specs_root="$1"
  local topic_name="$2"

  # Phase 1: Canonicalize specs_root to prevent path inconsistencies
  specs_root=$(canonicalize_path "$specs_root") || {
    echo "ERROR: Failed to canonicalize specs_root: $1" >&2
    return 1
  }

  # Validate specs_root is absolute path
  if [[ "$specs_root" != /* ]]; then
    echo "ERROR: specs_root must be absolute path: $specs_root" >&2
    return 1
  fi

  local lockfile="${specs_root}/.topic_number.lock"

  # Phase 3: Validate lock file uniqueness
  local lock_count=$(find "$specs_root" -name ".topic_number.lock" 2>/dev/null | wc -l)
  if [ "$lock_count" -gt 1 ]; then
    echo "WARNING: Multiple lock files found in specs tree, possible path inconsistency" >&2
    echo "  Lock file: $lockfile" >&2
    echo "  Count found: $lock_count" >&2
  fi

  mkdir -p "$specs_root"

  # Phase 4: Source error logging (with suppression for standalone use)
  if declare -f log_command_error >/dev/null 2>&1; then
    # Error logging available - use it
    local ENABLE_ERROR_LOGGING=1
  else
    local ENABLE_ERROR_LOGGING=0
  fi

  # ... continue with lock acquisition
```

### Collision Detection Logging

**Add after line 273** (in allocate_and_create_topic):
```bash
# Phase 2: Log max_num for observability
if [ $ENABLE_ERROR_LOGGING -eq 1 ]; then
  # Log at DEBUG level (won't pollute error reports)
  echo "DEBUG: allocate_and_create_topic: max_num=$max_num, next=$topic_number" >&2
fi
```

**Update collision loop** (lines 280-287):
```bash
local collision_count=0
local attempts=0
while ls -d "${specs_root}/${topic_number}_"* >/dev/null 2>&1 && [ $attempts -lt 1000 ]; do
  # Phase 2: Log collision for observability
  if [ $ENABLE_ERROR_LOGGING -eq 1 ]; then
    echo "DEBUG: Topic number collision detected: $topic_number already exists" >&2
  fi

  ((collision_count++))
  local next_num=$(( (10#$topic_number + 1) % 1000 ))
  topic_number=$(printf "%03d" "$next_num")
  topic_path="${specs_root}/${topic_number}_${topic_name}"
  ((attempts++))
done

# Phase 2: Log collision count
if [ $collision_count -gt 0 ] && [ $ENABLE_ERROR_LOGGING -eq 1 ]; then
  echo "DEBUG: Resolved $collision_count collisions, allocated: $topic_number" >&2
fi
```

### Post-Creation Verification

**Add after line 298** (after mkdir):
```bash
# Phase 2: Verify no duplicate numbers exist
local duplicate_count=$(ls -1d "${specs_root}/${topic_number}_"* 2>/dev/null | wc -l)
if [ "$duplicate_count" -gt 1 ]; then
  # CRITICAL: Duplicate number detected despite atomic allocation!
  if [ $ENABLE_ERROR_LOGGING -eq 1 ]; then
    log_command_error \
      "${COMMAND_NAME:-/allocate_topic}" \
      "${WORKFLOW_ID:-unknown}" \
      "" \
      "state_error" \
      "Duplicate topic number detected after atomic allocation" \
      "allocate_and_create_topic" \
      "$(jq -n \
        --arg specs_root "$specs_root" \
        --arg topic_num "$topic_number" \
        --arg topic_name "$topic_name" \
        --argjson dup_count "$duplicate_count" \
        '{specs_root: $specs_root, topic_number: $topic_num, topic_name: $topic_name, duplicate_count: $dup_count}')"
  fi

  # List duplicates for manual investigation
  echo "ERROR: Duplicate topic numbers detected!" >&2
  echo "  Number: $topic_number" >&2
  echo "  Count: $duplicate_count" >&2
  echo "  Directories:" >&2
  ls -1d "${specs_root}/${topic_number}_"* >&2

  # Continue anyway (don't fail - directory was created successfully)
  # Let user investigate and fix manually
fi
```

### Success Logging

**Add after verification** (before return):
```bash
# Phase 4: Log successful allocation (DEBUG level)
if [ $ENABLE_ERROR_LOGGING -eq 1 ]; then
  echo "DEBUG: Successfully allocated topic: ${topic_number}_${topic_name}" >&2
  echo "  Canonical specs_root: $specs_root" >&2
  echo "  Lock file: $lockfile" >&2
fi
```

## Testing Plan

### Test 1: Concurrent Allocation Safety

**File**: .claude/tests/integration/test_concurrent_topic_allocation.sh

```bash
#!/bin/bash
# Test concurrent topic allocation for race conditions

source .claude/lib/core/unified-location-detection.sh

# Create temporary specs directory
TEMP_SPECS=$(mktemp -d)
trap "rm -rf $TEMP_SPECS" EXIT

# Launch 100 concurrent allocations with different names
for i in {1..100}; do
  (
    allocate_and_create_topic "$TEMP_SPECS" "test_topic_$i" >/dev/null
  ) &
done

# Wait for all to complete
wait

# Verify: Exactly 100 directories created
DIR_COUNT=$(ls -1d "$TEMP_SPECS"/[0-9][0-9][0-9]_* 2>/dev/null | wc -l)
if [ "$DIR_COUNT" -ne 100 ]; then
  echo "FAIL: Expected 100 directories, found $DIR_COUNT"
  exit 1
fi

# Verify: No duplicate numbers
NUMBERS=$(ls -1d "$TEMP_SPECS"/[0-9][0-9][0-9]_* | sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | sort)
UNIQUE_NUMBERS=$(echo "$NUMBERS" | uniq)
if [ "$NUMBERS" != "$UNIQUE_NUMBERS" ]; then
  echo "FAIL: Duplicate numbers detected:"
  echo "$NUMBERS" | uniq -d
  exit 1
fi

echo "PASS: 100 concurrent allocations, 0 collisions"
```

### Test 2: Path Canonicalization

**File**: .claude/tests/unit/test_path_canonicalization.sh

```bash
#!/bin/bash
# Test path canonicalization with relative paths, symlinks, trailing slashes

source .claude/lib/core/unified-location-detection.sh

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

SPECS_DIR="$TEMP_DIR/specs"
mkdir -p "$SPECS_DIR"

# Create symlink to specs
ln -s "$SPECS_DIR" "$TEMP_DIR/specs_link"

# Test 1: Absolute path
RESULT1=$(allocate_and_create_topic "$SPECS_DIR" "test1")
PATH1="${RESULT1#*|}"

# Test 2: Symlink path
RESULT2=$(allocate_and_create_topic "$TEMP_DIR/specs_link" "test2")
PATH2="${RESULT2#*|}"

# Test 3: Path with trailing slash
RESULT3=$(allocate_and_create_topic "$SPECS_DIR/" "test3")
PATH3="${RESULT3#*|}"

# Verify all use same canonical parent
PARENT1=$(dirname "$PATH1")
PARENT2=$(dirname "$PATH2")
PARENT3=$(dirname "$PATH3")

if [ "$PARENT1" != "$PARENT2" ] || [ "$PARENT1" != "$PARENT3" ]; then
  echo "FAIL: Paths not canonicalized to same parent"
  echo "  Absolute: $PARENT1"
  echo "  Symlink: $PARENT2"
  echo "  Trailing slash: $PARENT3"
  exit 1
fi

# Verify sequential numbering (000, 001, 002)
NUM1="${RESULT1%|*}"
NUM2="${RESULT2%|*}"
NUM3="${RESULT3%|*}"

if [ "$NUM1" != "000" ] || [ "$NUM2" != "001" ] || [ "$NUM3" != "002" ]; then
  echo "FAIL: Sequential numbering broken"
  echo "  Got: $NUM1, $NUM2, $NUM3"
  echo "  Expected: 000, 001, 002"
  exit 1
fi

echo "PASS: Path canonicalization works correctly"
```

### Test 3: Collision Detection

**File**: .claude/tests/unit/test_collision_detection.sh

```bash
#!/bin/bash
# Test collision detection and skipping behavior

source .claude/lib/core/unified-location-detection.sh

TEMP_SPECS=$(mktemp -d)
trap "rm -rf $TEMP_SPECS" EXIT

# Create directories 000, 001, 003 (skip 002)
mkdir -p "$TEMP_SPECS/000_initial"
mkdir -p "$TEMP_SPECS/001_second"
mkdir -p "$TEMP_SPECS/003_fourth"

# Allocate new topic - should skip to 002 (not 004)
RESULT=$(allocate_and_create_topic "$TEMP_SPECS" "test_collision")
TOPIC_NUM="${RESULT%|*}"

if [ "$TOPIC_NUM" != "002" ]; then
  echo "FAIL: Expected allocation of 002 (filling gap), got $TOPIC_NUM"
  exit 1
fi

# Create 002 manually
mkdir -p "$TEMP_SPECS/002_manual"

# Allocate another - should skip to 004
RESULT2=$(allocate_and_create_topic "$TEMP_SPECS" "test_after_collision")
TOPIC_NUM2="${RESULT2%|*}"

if [ "$TOPIC_NUM2" != "004" ]; then
  echo "FAIL: Expected collision detection to skip to 004, got $TOPIC_NUM2"
  exit 1
fi

echo "PASS: Collision detection and gap filling work correctly"
```

## Rollout Plan

### Phase 1: Implementation (Day 1)
1. Implement canonicalize_path() helper
2. Update allocate_and_create_topic() with all phases
3. Add comprehensive error logging
4. Update documentation

### Phase 2: Testing (Day 1-2)
1. Write and run all unit tests
2. Write and run integration tests
3. Test with 1000 concurrent allocations
4. Verify error logging integration

### Phase 3: Validation (Day 2)
1. Deploy to development environment
2. Monitor error logs for allocation issues
3. Run `/errors --type state_error` to verify no new collisions
4. Manual verification of sequential numbering

### Phase 4: Production Deployment (Day 3)
1. Commit changes to main branch
2. Update CLAUDE.md with new guarantees
3. Create summary document for users
4. Monitor for one week for any issues

## Success Criteria

1. **Zero Collisions**: No duplicate topic numbers under any conditions
2. **Path Consistency**: All specs_root values resolve to same canonical path
3. **Observability**: All allocations logged with complete diagnostic context
4. **Test Coverage**: 100% of edge cases covered by automated tests
5. **Performance**: No regression in allocation speed (<50ms per allocation)

## Migration Notes

This fix has no backward compatibility concerns because:
- No API changes to allocate_and_create_topic() signature
- All changes internal to the function
- No deprecated code paths to maintain
- Existing directories unaffected (retroactive verification not needed)

The only user-visible change is improved error messages and logging.

## References

- **Root Cause Report**: 001-numbering-collision-root-cause.md
- **Atomic Allocation Function**: .claude/lib/core/unified-location-detection.sh:247-305
- **Directory Protocols**: .claude/docs/concepts/directory-protocols.md:120-196
- **Code Standards**: .claude/docs/reference/standards/code-standards.md
- **Error Logging Pattern**: .claude/docs/concepts/patterns/error-handling.md
- **Clean-Break Standard**: .claude/docs/reference/standards/clean-break-development.md
