# Implementation Plan: Project-Isolated Spec Numbering with Rollover

## Plan Metadata
- **Spec Topic**: 755_project_isolated_spec_numbering
- **Plan Number**: 001
- **Created**: 2025-11-17
- **Complexity**: Low (core algorithm change + testing)
- **Risk Level**: Low (backward compatible, no data modification)
- **Research Report**: /home/benjamin/.config/.claude/specs/755_project_isolated_spec_numbering/reports/001_root_cause_analysis.md

## Executive Summary

This plan implements project-isolated spec numbering that:
1. Starts from **000** (not 001) in each project
2. Rolls over to **000** when exceeding 999
3. Handles collisions when rolling over by finding next available number

The fix is localized to two functions in `unified-location-detection.sh` and requires updates to ensure all projects use the current version.

## Context

### Problem Statement

Cross-project numbering contamination occurred when:
1. Logos project continued numbering from config project (679, 680 instead of 010)
2. Environment variable `CLAUDE_PROJECT_DIR` leaked between sessions
3. Logos had outdated command version without atomic allocation

### User Requirements

1. **Start from 000**: First topic in each project should be `000_topic_name`
2. **Rollover at 1000**: After 999, next topic should be 000 (with collision handling)
3. **Project isolation**: Each project maintains independent numbering

### Current Implementation

```bash
# unified-location-detection.sh:193-198
if [ -z "$max_num" ]; then
  echo "001"  # USER WANTS: "000"
else
  printf "%03d" $((10#$max_num + 1))  # USER WANTS: modulo 1000
fi
```

## Implementation Phases

### Phase 1: Implement Rollover and Zero-Start
**Complexity**: Low
**Estimated Effort**: 30-45 minutes
**Dependencies**: None

**Objectives**:
1. Change initial topic number from 001 to 000
2. Implement modulo-based rollover at 1000
3. Add collision detection when rolling over
4. Update both `get_next_topic_number()` and `allocate_and_create_topic()`

**Tasks**:

**1.1: Update `get_next_topic_number()` Function**
- **File**: /home/benjamin/.config/.claude/lib/unified-location-detection.sh
- **Location**: Lines 175-203
- **Current Code**:
```bash
get_next_topic_number() {
  local specs_root="$1"
  local lockfile="${specs_root}/.topic_number.lock"

  mkdir -p "$specs_root"

  {
    flock -x 200 || return 1

    local max_num
    max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
      sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
      sort -n | tail -1)

    if [ -z "$max_num" ]; then
      echo "001"
    else
      printf "%03d" $((10#$max_num + 1))
    fi

  } 200>"$lockfile"
}
```

- **New Code**:
```bash
get_next_topic_number() {
  local specs_root="$1"
  local lockfile="${specs_root}/.topic_number.lock"

  mkdir -p "$specs_root"

  {
    flock -x 200 || return 1

    local max_num
    max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
      sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
      sort -n | tail -1)

    # Handle empty directory (first topic starts at 000)
    if [ -z "$max_num" ]; then
      echo "000"
    else
      # Increment with rollover at 1000 (999 -> 000)
      local next_num=$(( (10#$max_num + 1) % 1000 ))
      printf "%03d" "$next_num"
    fi

  } 200>"$lockfile"
}
```

**1.2: Update `allocate_and_create_topic()` Function**
- **File**: /home/benjamin/.config/.claude/lib/unified-location-detection.sh
- **Location**: Lines 235-276
- **Changes**:
  1. Start from 000 instead of 001
  2. Implement rollover at 1000
  3. Add collision detection with retry loop

- **New Code**:
```bash
allocate_and_create_topic() {
  local specs_root="$1"
  local topic_name="$2"
  local lockfile="${specs_root}/.topic_number.lock"

  mkdir -p "$specs_root"

  {
    flock -x 200 || return 1

    # Find maximum existing topic number
    local max_num
    max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
      sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
      sort -n | tail -1)

    # Calculate next topic number with rollover
    local topic_number
    if [ -z "$max_num" ]; then
      topic_number="000"
    else
      # Increment with rollover at 1000 (999 -> 000)
      local next_num=$(( (10#$max_num + 1) % 1000 ))
      topic_number=$(printf "%03d" "$next_num")
    fi

    # Construct topic path
    local topic_path="${specs_root}/${topic_number}_${topic_name}"

    # Handle collision when rolling over (find next available)
    local attempts=0
    while [ -d "$topic_path" ] && [ $attempts -lt 1000 ]; do
      # Directory exists (rolled over to existing number)
      next_num=$(( (10#$topic_number + 1) % 1000 ))
      topic_number=$(printf "%03d" "$next_num")
      topic_path="${specs_root}/${topic_number}_${topic_name}"
      ((attempts++))
    done

    if [ $attempts -ge 1000 ]; then
      echo "ERROR: All 1000 topic numbers exhausted in $specs_root" >&2
      return 1
    fi

    # Create topic directory INSIDE LOCK (atomic operation)
    mkdir -p "$topic_path" || {
      echo "ERROR: Failed to create topic directory: $topic_path" >&2
      return 1
    }

    # Return pipe-delimited result for parsing
    echo "${topic_number}|${topic_path}"

  } 200>"$lockfile"
}
```

**Success Criteria**:
- First topic in empty specs directory is 000
- After 999, next topic is 000 (or next available if 000 exists)
- Collision detection prevents overwriting existing directories

---

### Phase 2: Update Documentation
**Complexity**: Low
**Estimated Effort**: 15-30 minutes
**Dependencies**: Phase 1

**Objectives**:
1. Update library header documentation
2. Document rollover behavior
3. Document collision handling

**Tasks**:

**2.1: Update Library Header**
- **File**: /home/benjamin/.config/.claude/lib/unified-location-detection.sh
- **Location**: Lines 1-68 (header comments)
- **Add**:
```bash
# Numbering Behavior:
#   - First topic: 000 (not 001)
#   - Rollover: 999 -> 000 (modulo 1000)
#   - Collision handling: If rolled-over number exists, find next available
#   - Full exhaustion: Error if all 1000 numbers used (rare edge case)
```

**2.2: Update Directory Protocols Documentation**
- **File**: /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md
- **Add section**: Numbering behavior with rollover explanation

**Success Criteria**:
- Documentation reflects new behavior
- Rollover and collision handling documented

---

### Phase 3: Testing
**Complexity**: Low
**Estimated Effort**: 30-45 minutes
**Dependencies**: Phase 1

**Objectives**:
1. Test zero-start behavior
2. Test rollover behavior
3. Test collision detection
4. Test full exhaustion error

**Tasks**:

**3.1: Create/Update Test Suite**
- **File**: /home/benjamin/.config/.claude/tests/test_atomic_topic_allocation.sh
- **Add test cases**:

```bash
# Test: First topic starts at 000
test_zero_start() {
  local test_root="/tmp/test_zero_start_$$"
  mkdir -p "$test_root"
  trap "rm -rf $test_root" RETURN

  RESULT=$(allocate_and_create_topic "$test_root" "first_topic")
  TOPIC_NUM="${RESULT%|*}"

  if [ "$TOPIC_NUM" != "000" ]; then
    echo "FAIL: Expected 000, got $TOPIC_NUM"
    return 1
  fi

  echo "PASS: First topic starts at 000"
  return 0
}

# Test: Rollover from 999 to 000
test_rollover() {
  local test_root="/tmp/test_rollover_$$"
  mkdir -p "$test_root"
  trap "rm -rf $test_root" RETURN

  # Create topic 999
  mkdir -p "$test_root/999_existing"

  RESULT=$(allocate_and_create_topic "$test_root" "after_999")
  TOPIC_NUM="${RESULT%|*}"

  if [ "$TOPIC_NUM" != "000" ]; then
    echo "FAIL: Expected 000 after 999, got $TOPIC_NUM"
    return 1
  fi

  echo "PASS: Rollover from 999 to 000"
  return 0
}

# Test: Collision detection after rollover
test_collision_detection() {
  local test_root="/tmp/test_collision_$$"
  mkdir -p "$test_root"
  trap "rm -rf $test_root" RETURN

  # Create topics 999 and 000
  mkdir -p "$test_root/999_existing"
  mkdir -p "$test_root/000_existing"

  RESULT=$(allocate_and_create_topic "$test_root" "collision_test")
  TOPIC_NUM="${RESULT%|*}"

  if [ "$TOPIC_NUM" != "001" ]; then
    echo "FAIL: Expected 001 (skip collision), got $TOPIC_NUM"
    return 1
  fi

  echo "PASS: Collision detection skips to 001"
  return 0
}

# Test: Multiple consecutive collisions
test_multiple_collisions() {
  local test_root="/tmp/test_multi_collision_$$"
  mkdir -p "$test_root"
  trap "rm -rf $test_root" RETURN

  # Create topics 999, 000, 001, 002
  mkdir -p "$test_root/999_existing"
  mkdir -p "$test_root/000_existing"
  mkdir -p "$test_root/001_existing"
  mkdir -p "$test_root/002_existing"

  RESULT=$(allocate_and_create_topic "$test_root" "multi_collision")
  TOPIC_NUM="${RESULT%|*}"

  if [ "$TOPIC_NUM" != "003" ]; then
    echo "FAIL: Expected 003 (skip collisions), got $TOPIC_NUM"
    return 1
  fi

  echo "PASS: Multiple collision detection finds 003"
  return 0
}
```

**3.2: Run Test Suite**
- Execute all tests
- Verify 100% pass rate
- Document any edge cases discovered

**Success Criteria**:
- All tests pass
- Zero-start, rollover, and collision detection verified
- Edge cases handled correctly

---

## Phase Dependencies

```
Phase 1: Core Implementation
    |
    +---> Phase 2: Documentation
    |
    +---> Phase 3: Testing
```

Phases 2 and 3 can run in parallel after Phase 1.

**Estimated Total Time**: 1-2 hours

---

## Testing Strategy

### Unit Tests
- Zero-start behavior (first topic = 000)
- Sequential allocation (000, 001, 002, ...)
- Rollover at 1000 (999 -> 000)
- Collision detection (skip existing numbers)
- Multiple consecutive collisions
- Full exhaustion error (1000 topics)

### Integration Tests
- Concurrent allocation with rollover
- Mixed existing numbers (gaps in sequence)
- Cross-project isolation (separate specs directories)

### Acceptance Criteria
- [ ] First topic number is 000
- [ ] Rollover from 999 to 000 works correctly
- [ ] Collision detection finds next available number
- [ ] Error on full exhaustion (all 1000 numbers used)
- [ ] Existing tests still pass
- [ ] Documentation updated

---

## Risk Assessment

### Low Risk
- **Backward Compatibility**: Existing directories unaffected (only new allocations change)
- **Data Safety**: No modification or deletion of existing data
- **Performance**: Collision loop adds minimal overhead (0ms in normal use)

### Edge Cases
- **Full Exhaustion**: Unlikely (1000 topics per project) but handled with clear error
- **Concurrent Rollover**: Lock prevents race conditions during collision detection

---

## Success Metrics

1. **Zero-Start**: First topic is 000 (not 001)
2. **Rollover**: 999 -> 000 with collision detection
3. **All Tests Pass**: Including new rollover tests
4. **Documentation Complete**: Updated with new behavior

---

## Maintenance Notes

### Future Enhancements
1. **Project Sync**: Mechanism to detect/update outdated command versions in other projects
2. **Numbering Reset**: Command to reset numbering in a project (delete and renumber)
3. **Archive Old Topics**: Move topics to archive/ when approaching exhaustion

### Monitoring
- Watch for exhaustion errors (unlikely but possible)
- Monitor collision frequency (should be rare, only after rollover)

---

## References

- Research Report: /home/benjamin/.config/.claude/specs/755_project_isolated_spec_numbering/reports/001_root_cause_analysis.md
- Core Library: /home/benjamin/.config/.claude/lib/unified-location-detection.sh
- Related Plan: /home/benjamin/.config/.claude/specs/753_unified_specs_directory_numbering/plans/001_unified_atomic_topic_allocation_plan.md
- Test Suite: /home/benjamin/.config/.claude/tests/test_atomic_topic_allocation.sh

---

**END OF PLAN**
