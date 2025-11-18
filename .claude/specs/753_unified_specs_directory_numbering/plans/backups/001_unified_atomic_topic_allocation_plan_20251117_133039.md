# Implementation Plan: Unified Atomic Topic Allocation

## Plan Metadata
- **Spec Topic**: 753_unified_specs_directory_numbering
- **Plan Number**: 001
- **Created**: 2025-11-17
- **Complexity**: Medium (4 command migrations + documentation + testing)
- **Risk Level**: Low (backward compatible, proven solution exists)
- **Research Report**: /home/benjamin/.config/.claude/specs/753_unified_specs_directory_numbering/reports/001_directory_numbering_analysis.md

## Executive Summary

This plan migrates all commands that create specs/ directories to use atomic topic allocation via `allocate_and_create_topic()` from unified-location-detection.sh. This eliminates race conditions that cause directory numbering collisions (40-60% collision rate under concurrent load) and inconsistent numbering.

**Key Changes**:
- Migrate 3 high-risk commands: /research-plan, /fix, /research-report
- Migrate 1 medium-risk command: /research
- Update documentation to reflect unified approach
- Add comprehensive testing for concurrent allocation
- Add .gitignore rule for lock files

**Impact**:
- **Collision Rate**: 40-60% → 0% (elimination of race conditions)
- **Predictability**: Sequential numbering without gaps (under normal usage)
- **Performance**: +10ms overhead per allocation (acceptable for human-driven workflows)
- **Maintainability**: Centralized allocation logic in single library

## Context

### Problem Statement

The research report identified three different directory numbering strategies used across 5 commands:
1. **Strategy 1 (Unsafe)**: Count + increment pattern with no locking - used by /research-plan, /fix, /research-report
2. **Strategy 2 (Partially Safe)**: Locked calculation but separate creation - used by /research
3. **Strategy 3 (Safe)**: Atomic allocation under lock - used by /plan

This inconsistency leads to:
- Race conditions between topic number calculation and directory creation
- 40-60% collision rate when multiple processes run concurrently
- Unpredictable directory numbering (gaps: 16→21, jumps: 24→730)
- Potential data loss from directory conflicts

### Current Implementation Analysis

**Unsafe Pattern (Strategy 1)**:
```bash
# Used by /research-plan (line 157-158), /fix (line 149-150), /research-report (line 156-157)
TOPIC_NUMBER=$(find "${CLAUDE_PROJECT_DIR}/.claude/specs" -maxdepth 1 -type d -name '[0-9]*_*' 2>/dev/null | wc -l | xargs)
TOPIC_NUMBER=$((TOPIC_NUMBER + 1))
mkdir -p "${SPECS_DIR}/${TOPIC_NUMBER}_${TOPIC_SLUG}"
```

**Race Condition Timeline**:
```
T0: Process A calculates TOPIC_NUMBER=26
T1: Process B calculates TOPIC_NUMBER=26 (A hasn't created directory yet)
T2: Process A creates 026_workflow_a
T3: Process B creates 026_workflow_b (COLLISION!)
```

**Safe Pattern (Strategy 3)**:
```bash
# Used by /plan (line 180)
TOPIC_DIR=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_SLUG")
TOPIC_NUMBER=$(basename "$TOPIC_DIR" | grep -oE '^[0-9]+')
```

**Atomic Operation**: Lock held through both number calculation AND directory creation, eliminating race window.

### Solution Overview

Standardize all commands on `allocate_and_create_topic()` from unified-location-detection.sh:

**Benefits**:
1. **Zero Collisions**: 100% collision-free operation under concurrent load (verified with 1000 parallel allocations)
2. **Predictable Numbering**: Sequential allocation without race-induced gaps
3. **Centralized Logic**: Single source of truth for topic allocation
4. **Proven Solution**: Already in production use by /plan command
5. **Minimal Overhead**: ~10ms per allocation (acceptable for workflow commands)

## Implementation Phases

### Phase 1: Preparation and Testing Infrastructure
**Complexity**: Low
**Estimated Effort**: 1-2 hours
**Dependencies**: None

**Objectives**:
1. Create test suite for concurrent topic allocation
2. Verify allocate_and_create_topic() function works correctly
3. Establish baseline metrics for migration validation
4. Create rollback documentation

**Tasks**:

**1.1: Create Concurrent Allocation Test Suite**
- **File**: /home/benjamin/.config/.claude/tests/test_atomic_topic_allocation.sh
- **Purpose**: Verify allocate_and_create_topic() handles concurrent access correctly
- **Test Cases**:
  - Sequential allocation (10 topics, verify 001-010)
  - Concurrent allocation (10 parallel processes, verify no duplicates)
  - Stress test (100 iterations × 10 processes = 1000 allocations)
  - Lock timeout handling
  - Permission failures
  - Specs directory creation on first use

**Implementation**:
```bash
#!/bin/bash
# Test atomic topic allocation under concurrent load

source .claude/lib/unified-location-detection.sh

# Test 1: Sequential allocation
test_sequential_allocation() {
  local test_root="/tmp/test_specs_$$"
  mkdir -p "$test_root"
  trap "rm -rf $test_root" EXIT

  for i in {1..10}; do
    RESULT=$(allocate_and_create_topic "$test_root" "topic_$i")
    TOPIC_NUM="${RESULT%|*}"
    TOPIC_PATH="${RESULT#*|}"

    # Verify number matches expected
    expected=$(printf "%03d" $i)
    if [ "$TOPIC_NUM" != "$expected" ]; then
      echo "FAIL: Expected $expected, got $TOPIC_NUM"
      return 1
    fi
  done

  echo "PASS: Sequential allocation (001-010)"
  return 0
}

# Test 2: Concurrent allocation
test_concurrent_allocation() {
  local test_root="/tmp/test_concurrent_$$"
  mkdir -p "$test_root"
  trap "rm -rf $test_root" EXIT

  # Launch 10 parallel processes
  for i in {1..10}; do
    (allocate_and_create_topic "$test_root" "parallel_$i" > /dev/null) &
  done
  wait

  # Count directories created
  local count=$(ls -1d "$test_root"/[0-9][0-9][0-9]_* 2>/dev/null | wc -l)
  if [ "$count" -ne 10 ]; then
    echo "FAIL: Expected 10 directories, got $count (collision detected)"
    return 1
  fi

  # Check for duplicate numbers
  local duplicates=$(ls -1 "$test_root" | cut -d_ -f1 | sort | uniq -d)
  if [ -n "$duplicates" ]; then
    echo "FAIL: Duplicate numbers found: $duplicates"
    return 1
  fi

  echo "PASS: Concurrent allocation (no collisions)"
  return 0
}

# Test 3: Stress test
test_stress_allocation() {
  local test_root="/tmp/test_stress_$$"
  mkdir -p "$test_root"
  trap "rm -rf $test_root" EXIT

  local start_time=$(date +%s)

  # 1000 allocations (100 iterations × 10 processes)
  for iteration in {1..100}; do
    for proc in {1..10}; do
      (allocate_and_create_topic "$test_root" "stress_${iteration}_${proc}" > /dev/null) &
    done
    wait
  done

  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  # Verify 1000 directories created
  local count=$(ls -1d "$test_root"/[0-9][0-9][0-9]_* 2>/dev/null | wc -l)
  if [ "$count" -ne 1000 ]; then
    echo "FAIL: Expected 1000 directories, got $count (${count}/1000 = $((count * 100 / 1000))% success rate)"
    return 1
  fi

  # Check for duplicates
  local duplicates=$(ls -1 "$test_root" | cut -d_ -f1 | sort | uniq -d | wc -l)
  if [ "$duplicates" -gt 0 ]; then
    echo "FAIL: Found $duplicates duplicate numbers"
    return 1
  fi

  echo "PASS: Stress test (1000 allocations, 0% collision rate, ${duration}s total)"
  return 0
}

# Run all tests
run_all_tests() {
  local failed=0

  echo "=== Atomic Topic Allocation Test Suite ==="
  echo ""

  test_sequential_allocation || ((failed++))
  test_concurrent_allocation || ((failed++))
  test_stress_allocation || ((failed++))

  echo ""
  if [ $failed -eq 0 ]; then
    echo "✓ All tests passed"
    return 0
  else
    echo "✗ $failed test(s) failed"
    return 1
  fi
}

run_all_tests
```

**Success Criteria**:
- All tests pass with 0% collision rate
- Stress test completes in <20 seconds
- No duplicate topic numbers detected

**1.2: Document Rollback Procedure**
- **File**: /home/benjamin/.config/.claude/specs/753_unified_specs_directory_numbering/ROLLBACK.md
- **Purpose**: Provide clear steps to revert changes if issues arise
- **Content**:
  - Git commands to revert each command file
  - Instructions for cleaning up lock files
  - Verification steps to confirm rollback success
  - Contact information for support

**1.3: Verify Baseline Functionality**
- Run current commands to establish baseline behavior
- Document current directory state in specs/
- Take note of any existing gaps or issues
- Capture timing metrics for comparison

**Success Criteria**:
- Test suite created and passing
- Rollback documentation complete
- Baseline metrics captured

---

### Phase 2: Migrate /research-plan Command
**Complexity**: Low
**Estimated Effort**: 30-45 minutes
**Dependencies**: Phase 1 (test infrastructure)

**Objectives**:
1. Replace unsafe count+increment pattern with atomic allocation
2. Add unified-location-detection.sh library sourcing
3. Update variable parsing to extract topic number from result
4. Test concurrent execution
5. Verify backward compatibility

**Tasks**:

**2.1: Add Library Source**
- **File**: /home/benjamin/.config/.claude/commands/research-plan.md
- **Location**: After existing library sources (around line 87)
- **Change**:
```bash
# ADD after other library sources
if ! source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh" 2>&1; then
  echo "ERROR: Failed to source unified-location-detection.sh"
  echo "DIAGNOSTIC: Check library exists at: ${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh"
  exit 1
fi
```

**2.2: Replace Directory Allocation Logic**
- **File**: /home/benjamin/.config/.claude/commands/research-plan.md
- **Location**: Lines 156-159
- **Current Code**:
```bash
TOPIC_SLUG=$(echo "$FEATURE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)
TOPIC_NUMBER=$(find "${CLAUDE_PROJECT_DIR}/.claude/specs" -maxdepth 1 -type d -name '[0-9]*_*' 2>/dev/null | wc -l | xargs)
TOPIC_NUMBER=$((TOPIC_NUMBER + 1))
SPECS_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TOPIC_NUMBER}_${TOPIC_SLUG}"
```

- **New Code**:
```bash
# Generate topic slug from feature description
TOPIC_SLUG=$(echo "$FEATURE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)

# Allocate topic directory atomically
SPECS_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs"
RESULT=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_SLUG")
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to allocate topic directory"
  echo "DIAGNOSTIC: Check permissions on $SPECS_DIR"
  echo "DETAILS: $RESULT"
  exit 1
fi

# Extract topic number and full path from result
TOPIC_NUMBER="${RESULT%|*}"
TOPIC_DIR="${RESULT#*|}"
SPECS_DIR="$TOPIC_DIR"  # Update SPECS_DIR to point to allocated directory
```

**2.3: Update Directory Creation**
- **File**: /home/benjamin/.config/.claude/commands/research-plan.md
- **Location**: After allocation (around line 162-167)
- **Current Code**:
```bash
mkdir -p "$RESEARCH_DIR"
```

- **Change**: Remove or simplify since allocate_and_create_topic() already creates topic root
```bash
# Topic directory already created by allocate_and_create_topic()
# Only need to create subdirectories
RESEARCH_DIR="${SPECS_DIR}/reports"
PLAN_DIR="${SPECS_DIR}/plans"

mkdir -p "$RESEARCH_DIR"
mkdir -p "$PLAN_DIR"
```

**2.4: Test Migration**
- Run concurrent execution test:
```bash
# Launch 10 /research-plan commands simultaneously
for i in {1..10}; do
  (./claude research-plan "test feature $i" &)
done
wait

# Verify 10 sequential directories created
ls -la .claude/specs/ | tail -11

# Verify no duplicate numbers
ls -1 .claude/specs/ | cut -d_ -f1 | sort | uniq -d
# Expected: empty output (no duplicates)
```

**Success Criteria**:
- Command executes without errors
- Concurrent execution creates sequential directories without collisions
- Existing functionality preserved (plans and reports created correctly)
- No duplicate topic numbers

---

### Phase 3: Migrate /fix Command
**Complexity**: Low
**Estimated Effort**: 30-45 minutes
**Dependencies**: Phase 2 (validate pattern with /research-plan)

**Objectives**:
1. Apply same atomic allocation pattern as /research-plan
2. Update debug directory creation to use allocated path
3. Test concurrent execution with multiple fix commands
4. Verify debug reports land in correct directories

**Tasks**:

**3.1: Add Library Source**
- **File**: /home/benjamin/.config/.claude/commands/fix.md
- **Location**: After existing library sources
- **Change**: Same as Phase 2.1

**3.2: Replace Directory Allocation Logic**
- **File**: /home/benjamin/.config/.claude/commands/fix.md
- **Location**: Lines 148-153
- **Current Code**:
```bash
TOPIC_SLUG=$(echo "$ISSUE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)
TOPIC_NUMBER=$(find "${CLAUDE_PROJECT_DIR}/.claude/specs" -maxdepth 1 -type d -name '[0-9]*_*' 2>/dev/null | wc -l | xargs)
TOPIC_NUMBER=$((TOPIC_NUMBER + 1))
SPECS_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TOPIC_NUMBER}_${TOPIC_SLUG}"
RESEARCH_DIR="${SPECS_DIR}/reports"
DEBUG_DIR="${SPECS_DIR}/debug"
```

- **New Code**:
```bash
# Generate topic slug from issue description
TOPIC_SLUG=$(echo "$ISSUE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)

# Allocate topic directory atomically
SPECS_ROOT="${CLAUDE_PROJECT_DIR}/.claude/specs"
RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_SLUG")
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to allocate topic directory"
  echo "DIAGNOSTIC: Check permissions on $SPECS_ROOT"
  exit 1
fi

# Extract topic number and full path from result
TOPIC_NUMBER="${RESULT%|*}"
SPECS_DIR="${RESULT#*|}"

# Define subdirectories
RESEARCH_DIR="${SPECS_DIR}/reports"
DEBUG_DIR="${SPECS_DIR}/debug"
```

**3.3: Update Directory Creation**
- **File**: /home/benjamin/.config/.claude/commands/fix.md
- **Location**: Lines 155-156
- **Current Code**:
```bash
mkdir -p "$RESEARCH_DIR"
mkdir -p "$DEBUG_DIR"
```

- **Change**: Keep as-is (still need subdirectories, but topic root already exists)
```bash
# Create subdirectories (topic root already created atomically)
mkdir -p "$RESEARCH_DIR"
mkdir -p "$DEBUG_DIR"
```

**3.4: Test Migration**
- Run concurrent /fix commands
- Verify debug reports created in correct locations
- Check for collision-free execution

**Success Criteria**:
- Concurrent execution creates unique topic directories
- Debug reports land in correct directories
- No duplicate topic numbers
- Fix workflow completes successfully

---

### Phase 4: Migrate /research-report Command
**Complexity**: Low
**Estimated Effort**: 30-45 minutes
**Dependencies**: Phase 3 (validate pattern consistency)

**Objectives**:
1. Apply atomic allocation pattern to /research-report
2. Update report directory path handling
3. Test concurrent execution
4. Verify reports created in correct locations

**Tasks**:

**4.1: Add Library Source**
- **File**: /home/benjamin/.config/.claude/commands/research-report.md
- **Location**: After existing library sources
- **Change**: Same pattern as Phase 2.1 and 3.1

**4.2: Replace Directory Allocation Logic**
- **File**: /home/benjamin/.config/.claude/commands/research-report.md
- **Location**: Lines 155-158
- **Current Code**:
```bash
TOPIC_SLUG=$(echo "$WORKFLOW_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)
TOPIC_NUMBER=$(find "${CLAUDE_PROJECT_DIR}/.claude/specs" -maxdepth 1 -type d -name '[0-9]*_*' 2>/dev/null | wc -l | xargs)
TOPIC_NUMBER=$((TOPIC_NUMBER + 1))
RESEARCH_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TOPIC_NUMBER}_${TOPIC_SLUG}/reports"
```

- **New Code**:
```bash
# Generate topic slug from workflow description
TOPIC_SLUG=$(echo "$WORKFLOW_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)

# Allocate topic directory atomically
SPECS_ROOT="${CLAUDE_PROJECT_DIR}/.claude/specs"
RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_SLUG")
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to allocate topic directory"
  echo "DIAGNOSTIC: Check permissions on $SPECS_ROOT"
  exit 1
fi

# Extract topic number and full path from result
TOPIC_NUMBER="${RESULT%|*}"
TOPIC_DIR="${RESULT#*|}"
RESEARCH_DIR="${TOPIC_DIR}/reports"
```

**4.3: Update Directory Creation**
- **File**: /home/benjamin/.config/.claude/commands/research-report.md
- **Location**: Around line 161
- **Current Code**:
```bash
mkdir -p "$RESEARCH_DIR"
```

- **Change**: Keep as-is (creates reports subdirectory)
```bash
# Create reports subdirectory (topic root already created atomically)
mkdir -p "$RESEARCH_DIR"
```

**4.4: Test Migration**
- Run concurrent /research-report commands
- Verify reports created correctly
- Check for sequential numbering

**Success Criteria**:
- Concurrent execution produces unique directories
- Reports created in correct locations
- No collisions or duplicate numbers
- Research workflow completes successfully

---

### Phase 5: Migrate /research Command
**Complexity**: Medium
**Estimated Effort**: 45-60 minutes
**Dependencies**: Phase 4 (validate pattern with all high-risk commands)

**Objectives**:
1. Replace get_next_topic_number() + mkdir pattern with allocate_and_create_topic()
2. Update hierarchical research directory creation
3. Test multi-subtopic research workflows
4. Verify OVERVIEW.md creation in correct locations

**Tasks**:

**5.1: Analyze Current Implementation**
- **File**: /home/benjamin/.config/.claude/commands/research.md
- **Location**: Lines 101-135
- **Current Pattern**: Uses get_next_topic_number() which locks during calculation but has race window before mkdir
- **Issue**: Race condition between number calculation and directory creation

**5.2: Add Library Source**
- **File**: /home/benjamin/.config/.claude/commands/research.md
- **Location**: After topic-utils.sh source (around line 102)
- **Change**:
```bash
source .claude/lib/topic-utils.sh

# Add unified location detection for atomic allocation
if ! source .claude/lib/unified-location-detection.sh 2>&1; then
  echo "ERROR: Failed to source unified-location-detection.sh"
  exit 1
fi
```

**5.3: Replace Allocation Logic**
- **File**: /home/benjamin/.config/.claude/commands/research.md
- **Location**: Lines 227-235 (approximate, based on research report)
- **Current Code**:
```bash
# Calculate topic metadata
TOPIC_NUM=$(get_next_topic_number "$SPECS_ROOT")
TOPIC_NAME=$(sanitize_topic_name "$RESEARCH_TOPIC")
TOPIC_DIR="${SPECS_ROOT}/${TOPIC_NUM}_${TOPIC_NAME}"

# Create topic root directory
mkdir -p "$TOPIC_DIR"
```

- **New Code**:
```bash
# Generate sanitized topic name
TOPIC_NAME=$(sanitize_topic_name "$RESEARCH_TOPIC")

# Allocate topic directory atomically
RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_NAME")
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to allocate topic directory"
  echo "DIAGNOSTIC: Check permissions on $SPECS_ROOT"
  exit 1
fi

# Extract topic number and path
TOPIC_NUM="${RESULT%|*}"
TOPIC_DIR="${RESULT#*|}"
```

**5.4: Update Hierarchical Research Directory Creation**
- **File**: /home/benjamin/.config/.claude/commands/research.md
- **Location**: After topic allocation
- **Verify**: Hierarchical research subdirectory pattern still works correctly
- **Pattern**: `reports/NNN_research/` with numbered subtopic reports and OVERVIEW.md

**5.5: Test Migration**
- Run /research command with multi-subtopic workflow
- Verify hierarchical directory structure created correctly
- Test concurrent /research invocations
- Verify OVERVIEW.md created in correct location

**Success Criteria**:
- Atomic allocation eliminates race window
- Hierarchical research directories created correctly
- Concurrent execution produces unique topic numbers
- OVERVIEW.md synthesis works as expected
- No duplicate topic numbers

---

### Phase 6: Documentation Updates
**Complexity**: Low
**Estimated Effort**: 1-2 hours
**Dependencies**: Phases 2-5 (all commands migrated)

**Objectives**:
1. Update directory-protocols.md with atomic allocation standard
2. Document lock file location and lifecycle
3. Update command-specific guides
4. Create migration guide for future commands

**Tasks**:

**6.1: Update Directory Protocols Documentation**
- **File**: /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md
- **Location**: After Topic Directories section (around line 66)
- **Add New Section**:

```markdown
### Atomic Topic Allocation

All commands that create topic directories MUST use atomic allocation to prevent race conditions and ensure sequential numbering.

**Standard Pattern**:
```bash
# 1. Source unified location detection library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh"

# 2. Generate sanitized topic name (max 50 chars, snake_case)
TOPIC_SLUG=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | \
             sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | \
             sed 's/^_//;s/_$//' | cut -c1-50)

# 3. Atomically allocate topic directory
RESULT=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_SLUG")
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to allocate topic directory"
  exit 1
fi

# 4. Extract topic number and path
TOPIC_NUMBER="${RESULT%|*}"
TOPIC_PATH="${RESULT#*|}"
```

**Why Atomic Allocation?**

The `allocate_and_create_topic()` function holds an exclusive file lock through BOTH topic number calculation AND directory creation. This eliminates the race condition that occurs with the count-then-create pattern.

**Race Condition (Unsafe Pattern)**:
```
Time  Process A              Process B
T0    count dirs → 25
T1                           count dirs → 25
T2    calc next → 26
T3                           calc next → 26
T4    mkdir 026_a
T5                           mkdir 026_b (COLLISION!)
```

**Atomic Operation (Safe Pattern)**:
```
Time  Process A                        Process B
T0    [LOCK] count → 25, calc → 26
T1                                     [WAITING FOR LOCK]
T2    mkdir 026_a [UNLOCK]
T3                                     [LOCK] count → 26, calc → 27
T4                                     mkdir 027_b [UNLOCK]
```

**Performance**: Atomic allocation adds ~10ms overhead per topic creation due to lock contention. This is acceptable for human-driven workflow commands.

**Lock File**: `${specs_root}/.topic_number.lock`
- Created automatically on first allocation
- Never deleted (persists for subsequent allocations)
- Empty file (<1KB, gitignored)
- Lock released automatically when process exits

**Concurrency Guarantee**: Tested with 1000 concurrent allocations, 0% collision rate.

**See**: [Unified Location Detection API](../reference/library-api.md#allocate_and_create_topic) for complete function documentation.
```

**6.2: Add .gitignore Rule**
- **File**: /home/benjamin/.config/.claude/specs/.gitignore
- **Change**: Add lock file pattern
```gitignore
# Topic number allocation lock file
.topic_number.lock
```

**6.3: Update Command Reference Documentation**
- **File**: /home/benjamin/.config/.claude/docs/reference/command-reference.md
- **Update**: Add note about atomic allocation to /plan, /research-plan, /fix, /research-report, /research command descriptions
- **Pattern**: "Uses atomic topic allocation to prevent race conditions"

**6.4: Create Migration Guide**
- **File**: /home/benjamin/.config/.claude/docs/guides/atomic-allocation-migration.md
- **Purpose**: Document migration pattern for future commands
- **Sections**:
  - Overview of race condition problem
  - Standard migration steps
  - Before/after code examples
  - Testing checklist
  - Common pitfalls and solutions

**Success Criteria**:
- Documentation updated with atomic allocation standard
- Lock file gitignored
- Migration guide created for future reference
- All command references updated

---

### Phase 7: Integration Testing
**Complexity**: Medium
**Estimated Effort**: 1-2 hours
**Dependencies**: Phases 2-6 (all migrations and documentation complete)

**Objectives**:
1. Test concurrent execution of mixed commands
2. Verify sequential numbering across all commands
3. Test edge cases (permissions, lock timeouts, full disk)
4. Validate backward compatibility with existing directories

**Tasks**:

**7.1: Create Integration Test Suite**
- **File**: /home/benjamin/.config/.claude/tests/test_command_topic_allocation.sh
- **Purpose**: Test all commands together under concurrent load
- **Test Scenarios**:

```bash
#!/bin/bash
# Integration test for atomic topic allocation across all commands

# Test 1: Mixed command concurrent execution
test_mixed_commands() {
  echo "Test: Mixed command concurrent execution"

  # Launch 5 different commands simultaneously
  (./claude research-plan "test feature 1" &)
  (./claude fix "test bug 1" &)
  (./claude research-report "test research 1" &)
  (./claude research "test topic 1" &)
  (./claude plan "test plan 1" &)

  wait

  # Verify 5 unique directories created
  NEW_DIRS=$(ls -1t .claude/specs/ | head -5)
  UNIQUE_NUMS=$(echo "$NEW_DIRS" | cut -d_ -f1 | sort -u | wc -l)

  if [ "$UNIQUE_NUMS" -ne 5 ]; then
    echo "FAIL: Expected 5 unique topic numbers, got $UNIQUE_NUMS"
    return 1
  fi

  echo "PASS: All 5 commands created unique directories"
  return 0
}

# Test 2: Sequential numbering verification
test_sequential_numbering() {
  echo "Test: Sequential numbering"

  # Get current max topic number
  MAX_BEFORE=$(ls -1 .claude/specs/ | cut -d_ -f1 | sort -n | tail -1)

  # Create 3 topics sequentially
  ./claude plan "test sequential 1"
  ./claude plan "test sequential 2"
  ./claude plan "test sequential 3"

  # Verify numbers are sequential
  MAX_AFTER=$(ls -1 .claude/specs/ | cut -d_ -f1 | sort -n | tail -1)
  EXPECTED=$((10#$MAX_BEFORE + 3))

  if [ $((10#$MAX_AFTER)) -ne $EXPECTED ]; then
    echo "FAIL: Expected $EXPECTED, got $MAX_AFTER"
    return 1
  fi

  echo "PASS: Sequential numbering verified"
  return 0
}

# Test 3: High concurrency stress test
test_high_concurrency() {
  echo "Test: High concurrency (50 parallel commands)"

  MAX_BEFORE=$(ls -1 .claude/specs/ | cut -d_ -f1 | sort -n | tail -1)

  # Launch 50 commands (10 of each type)
  for i in {1..10}; do
    (./claude plan "concurrent test $i" &)
    (./claude research-plan "concurrent feature $i" &)
    (./claude fix "concurrent bug $i" &)
    (./claude research-report "concurrent report $i" &)
    (./claude research "concurrent topic $i" &)
  done
  wait

  # Verify 50 unique directories created
  MAX_AFTER=$(ls -1 .claude/specs/ | cut -d_ -f1 | sort -n | tail -1)
  EXPECTED=$((10#$MAX_BEFORE + 50))

  # Count new directories
  NEW_COUNT=$(ls -1 .claude/specs/ | wc -l)
  EXPECTED_COUNT=$(($(echo $MAX_BEFORE | wc -l) + 50))

  # Check for duplicates in last 50
  DUPLICATES=$(ls -1t .claude/specs/ | head -50 | cut -d_ -f1 | sort | uniq -d)

  if [ -n "$DUPLICATES" ]; then
    echo "FAIL: Duplicate numbers found: $DUPLICATES"
    return 1
  fi

  echo "PASS: High concurrency (50 commands, 0% collision rate)"
  return 0
}

# Test 4: Edge case - permission denied
test_permission_denied() {
  echo "Test: Permission denied handling"

  # Create read-only specs directory
  TEST_SPECS="/tmp/readonly_specs_$$"
  mkdir -p "$TEST_SPECS"
  chmod 444 "$TEST_SPECS"

  # Attempt allocation (should fail gracefully)
  RESULT=$(allocate_and_create_topic "$TEST_SPECS" "test_topic" 2>&1)
  EXIT_CODE=$?

  # Cleanup
  chmod 755 "$TEST_SPECS"
  rm -rf "$TEST_SPECS"

  if [ $EXIT_CODE -eq 0 ]; then
    echo "FAIL: Should have failed with permission denied"
    return 1
  fi

  echo "PASS: Permission denied handled correctly"
  return 0
}

# Run all integration tests
run_integration_tests() {
  local failed=0

  echo "=== Command Topic Allocation Integration Tests ==="
  echo ""

  test_mixed_commands || ((failed++))
  test_sequential_numbering || ((failed++))
  test_high_concurrency || ((failed++))
  test_permission_denied || ((failed++))

  echo ""
  if [ $failed -eq 0 ]; then
    echo "✓ All integration tests passed"
    return 0
  else
    echo "✗ $failed integration test(s) failed"
    return 1
  fi
}

run_integration_tests
```

**7.2: Test Backward Compatibility**
- Verify existing spec directories still accessible
- Test that old and new commands can coexist
- Verify existing plans/reports/debug artifacts readable

**7.3: Performance Benchmarking**
- Measure allocation time before and after migration
- Compare concurrent execution performance
- Document overhead in specs/753.../debug/performance_analysis.md

**7.4: Edge Case Testing**
- Test with full disk (should fail gracefully)
- Test with corrupted lock file (should handle or recreate)
- Test with very long topic names (should truncate to 50 chars)
- Test with special characters in descriptions (should sanitize)

**Success Criteria**:
- All integration tests pass
- 0% collision rate under concurrent load
- Performance overhead <20ms per allocation
- Graceful error handling for all edge cases
- Backward compatibility confirmed

---

### Phase 8: Validation and Cleanup
**Complexity**: Low
**Estimated Effort**: 1 hour
**Dependencies**: Phase 7 (all testing complete)

**Objectives**:
1. Verify all commands migrated successfully
2. Clean up test artifacts
3. Commit changes with comprehensive commit message
4. Document lessons learned

**Tasks**:

**8.1: Final Verification Checklist**
- [ ] All 5 commands source unified-location-detection.sh
- [ ] All 5 commands use allocate_and_create_topic()
- [ ] No commands use count+increment pattern
- [ ] Documentation updated and accurate
- [ ] Tests passing with 0% collision rate
- [ ] Lock file gitignored
- [ ] No breaking changes to existing functionality

**8.2: Code Review**
- Review all changed command files for consistency
- Verify error handling follows project standards
- Check variable naming conventions
- Ensure diagnostic messages are helpful

**8.3: Clean Up Test Artifacts**
- Remove any temporary test directories
- Clean up /tmp/test_* directories
- Remove test topic directories from specs/
- Keep integration tests in .claude/tests/

**8.4: Git Commit**
- Stage all changed files
- Create comprehensive commit message
- Include reference to spec 753
- Document breaking changes (none expected)

**Commit Message Template**:
```
feat(753): unify specs directory numbering with atomic allocation

Migrate all commands to use allocate_and_create_topic() from
unified-location-detection.sh to eliminate race conditions and
ensure sequential topic numbering.

Changes:
- /research-plan: Replace count+increment with atomic allocation
- /fix: Replace count+increment with atomic allocation
- /research-report: Replace count+increment with atomic allocation
- /research: Replace get_next_topic_number() with atomic allocation
- Documentation: Add atomic allocation standard to directory-protocols.md
- Tests: Add concurrent allocation integration tests

Impact:
- Collision rate: 40-60% → 0%
- Performance: +10ms per allocation (acceptable)
- Sequential numbering: Guaranteed under normal usage

Testing:
- 1000 concurrent allocations: 0% collision rate
- Mixed command execution: All unique directories
- Backward compatibility: Verified with existing specs

Closes #753
```

**8.5: Document Lessons Learned**
- **File**: /home/benjamin/.config/.claude/specs/753_unified_specs_directory_numbering/summaries/001_implementation_summary.md
- **Content**:
  - What went well
  - Challenges encountered
  - Metrics and measurements
  - Recommendations for future migrations

**Success Criteria**:
- All verification checks pass
- Clean git commit with comprehensive message
- Test artifacts cleaned up
- Summary documentation complete

---

## Phase Dependencies

```
Phase 1: Preparation
    ↓
Phase 2: /research-plan ──┐
    ↓                     │
Phase 3: /fix ────────────┤
    ↓                     ├─→ Phase 6: Documentation
Phase 4: /research-report │        ↓
    ↓                     │   Phase 7: Integration Testing
Phase 5: /research ───────┘        ↓
                              Phase 8: Validation
```

**Parallel Execution Opportunities**:
- Phases 2-5 can be executed in parallel after Phase 1 completes (each migrates a different command)
- Phase 6 can start after any command is migrated (incremental documentation updates)

**Critical Path**: Phase 1 → Phase 5 → Phase 7 → Phase 8

**Estimated Total Time**: 6-9 hours (includes testing and documentation)

---

## Rollback Plan

If critical issues arise during or after migration:

**Immediate Rollback** (per command):
```bash
# Revert specific command file
git checkout HEAD -- .claude/commands/research-plan.md

# Test command functionality
./claude research-plan "rollback test"

# Verify directory creation works
ls -la .claude/specs/ | tail -1
```

**Full Rollback** (all changes):
```bash
# Identify commit before migration
git log --oneline | grep "feat(753)"

# Revert entire migration
git revert <commit-hash>

# Verify all commands work
./claude plan "rollback verification"
```

**Lock File Cleanup** (if needed):
```bash
# Remove lock file (harmless, will be recreated)
rm .claude/specs/.topic_number.lock

# Verify no impact on existing directories
ls -la .claude/specs/
```

**Data Safety**:
- Topic directories are never deleted during migration
- Existing artifacts (plans/reports/debug) are not modified
- Lock file is separate from content (can be safely deleted)
- Worst case: Manual renumbering of colliding directories

---

## Testing Strategy

### Unit Testing
- Test allocate_and_create_topic() in isolation (Phase 1)
- Test each command individually after migration (Phases 2-5)
- Test error handling and edge cases (Phase 7)

### Integration Testing
- Test mixed command concurrent execution (Phase 7)
- Test sequential numbering across commands (Phase 7)
- Test backward compatibility with existing directories (Phase 7)

### Stress Testing
- 1000 concurrent allocations (Phase 1)
- 50 parallel mixed commands (Phase 7)
- Sustained load testing (optional)

### Performance Testing
- Measure allocation time before/after migration
- Compare concurrent execution performance
- Monitor lock contention under high load

### Acceptance Criteria
- [ ] 0% collision rate under concurrent load
- [ ] Sequential numbering verified across all commands
- [ ] Performance overhead <20ms per allocation
- [ ] All existing functionality preserved
- [ ] Documentation complete and accurate
- [ ] All tests passing

---

## Risk Assessment

### Low Risk
- **Backward Compatibility**: Atomic allocation uses same numbering logic, just with locking
- **Data Loss**: No existing data modified, only creation process changed
- **Performance**: 10ms overhead acceptable for human-driven workflows

### Medium Risk
- **Lock Contention**: Under high concurrent load (50+ simultaneous commands), lock wait time could be noticeable
  - **Mitigation**: Commands are human-driven, not automated batch processes
  - **Monitoring**: Add timing instrumentation to detect excessive wait times

### Minimal Risk
- **Lock File Corruption**: Lock file could become corrupted or stuck
  - **Mitigation**: flock automatically releases on process exit
  - **Recovery**: Lock file can be safely deleted and recreated

### Zero Risk
- **Breaking Changes**: None (same API, same directory format)
- **Git Conflicts**: Each command file modified independently

---

## Success Metrics

### Primary Metrics
1. **Collision Rate**: Target 0% (currently 40-60%)
2. **Sequential Numbering**: Target 100% sequential (currently has gaps)
3. **Performance Overhead**: Target <20ms (currently 1-2ms, acceptable increase)

### Secondary Metrics
1. **Test Pass Rate**: Target 100%
2. **Documentation Coverage**: Target 100% (all commands documented)
3. **Code Consistency**: Target 100% (all commands use same pattern)

### Verification
```bash
# Verify collision rate
# Run 100 concurrent allocations, check for duplicates
for i in {1..100}; do
  (./claude plan "test $i" &)
done
wait
ls -1 .claude/specs/ | cut -d_ -f1 | sort | uniq -d | wc -l
# Expected: 0

# Verify sequential numbering
# Create 10 sequential topics, verify numbers
MAX_BEFORE=$(ls -1 .claude/specs/ | cut -d_ -f1 | sort -n | tail -1)
for i in {1..10}; do
  ./claude plan "sequential test $i"
done
MAX_AFTER=$(ls -1 .claude/specs/ | cut -d_ -f1 | sort -n | tail -1)
DIFF=$((10#$MAX_AFTER - 10#$MAX_BEFORE))
echo "Created $DIFF directories (expected: 10)"
# Expected: 10

# Verify performance overhead
time ./claude plan "performance test"
# Expected: Total time includes allocation (<20ms overhead)
```

---

## Maintenance Notes

### Future Command Development
All new commands that create topic directories MUST use atomic allocation:

```bash
# Required pattern for new commands
source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh"
RESULT=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_SLUG")
TOPIC_NUMBER="${RESULT%|*}"
TOPIC_PATH="${RESULT#*|}"
```

### Monitoring
- Monitor lock file size (should remain <1KB)
- Monitor allocation timing (should remain <20ms)
- Watch for collision reports (should remain 0)

### Troubleshooting
**Lock File Issues**:
```bash
# Check lock file exists
ls -la .claude/specs/.topic_number.lock

# Check lock file permissions
stat .claude/specs/.topic_number.lock

# If stuck, safe to delete (will be recreated)
rm .claude/specs/.topic_number.lock
```

**Performance Issues**:
```bash
# Add timing instrumentation
time_start=$(date +%s%N)
RESULT=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_SLUG")
time_end=$(date +%s%N)
time_ms=$(( (time_end - time_start) / 1000000 ))
echo "Allocation took: ${time_ms}ms"
# If >50ms consistently, investigate lock contention
```

---

## References

### Source Files
- Research Report: /home/benjamin/.config/.claude/specs/753_unified_specs_directory_numbering/reports/001_directory_numbering_analysis.md
- Atomic Allocation Library: /home/benjamin/.config/.claude/lib/unified-location-detection.sh
- Example Implementation: /home/benjamin/.config/.claude/commands/plan.md (lines 180-189)

### Commands to Migrate
1. /research-plan: /home/benjamin/.config/.claude/commands/research-plan.md (lines 156-159)
2. /fix: /home/benjamin/.config/.claude/commands/fix.md (lines 148-153)
3. /research-report: /home/benjamin/.config/.claude/commands/research-report.md (lines 155-158)
4. /research: /home/benjamin/.config/.claude/commands/research.md (lines 227-235 approximate)
5. /plan: Already migrated (reference implementation)

### Documentation to Update
- Directory Protocols: /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md
- Command Reference: /home/benjamin/.config/.claude/docs/reference/command-reference.md
- Library API: /home/benjamin/.config/.claude/docs/reference/library-api.md

### Testing
- Atomic Allocation Tests: /home/benjamin/.config/.claude/tests/test_atomic_topic_allocation.sh (to be created)
- Integration Tests: /home/benjamin/.config/.claude/tests/test_command_topic_allocation.sh (to be created)
- Existing Tests: /home/benjamin/.config/.claude/tests/test_unified_location_detection.sh (reference)

---

## Appendix A: Code Examples

### Before: Unsafe Count+Increment Pattern
```bash
# Used by /research-plan, /fix, /research-report
TOPIC_SLUG=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | cut -c1-50)
TOPIC_NUMBER=$(find "${SPECS_DIR}" -maxdepth 1 -type d -name '[0-9]*_*' 2>/dev/null | wc -l | xargs)
TOPIC_NUMBER=$((TOPIC_NUMBER + 1))
TOPIC_DIR="${SPECS_DIR}/${TOPIC_NUMBER}_${TOPIC_SLUG}"
mkdir -p "$TOPIC_DIR"
```

**Issues**:
- Race condition between `wc -l` and `mkdir`
- Multiple processes can get same number
- 40-60% collision rate under concurrent load

### After: Atomic Allocation Pattern
```bash
# Unified pattern for all commands
source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh"

TOPIC_SLUG=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | cut -c1-50)

RESULT=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_SLUG")
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to allocate topic directory"
  exit 1
fi

TOPIC_NUMBER="${RESULT%|*}"
TOPIC_DIR="${RESULT#*|}"
```

**Benefits**:
- Atomic operation under exclusive lock
- Zero race conditions
- 0% collision rate under concurrent load
- Centralized allocation logic

---

## Appendix B: Performance Analysis

### Timing Breakdown

**Unsafe Pattern** (no lock):
- Find directories: ~1ms
- Count lines: <1ms
- Increment: <1ms
- Mkdir: ~1ms
- **Total**: ~2ms

**Atomic Pattern** (with lock):
- Lock acquisition: ~0-10ms (depends on contention)
- Find max number: ~1ms
- Calculate next: <1ms
- Mkdir: ~1ms
- Lock release: <1ms
- **Total**: ~10-12ms (typical), up to 100ms (high contention)

### Contention Analysis

**Low Contention** (1-2 concurrent processes):
- Average wait: <1ms
- Overhead: ~10ms total

**Medium Contention** (5-10 concurrent processes):
- Average wait: ~5-20ms
- Overhead: ~15-30ms total

**High Contention** (50+ concurrent processes):
- Average wait: ~20-80ms
- Overhead: ~30-100ms total
- Still acceptable for human-driven workflows

### Performance Recommendations
1. Monitor allocation timing in production
2. Add metrics collection for lock wait times
3. Alert if allocation time exceeds 100ms consistently
4. Consider lock timeout (currently blocks indefinitely)

---

## Appendix C: Testing Checklist

### Pre-Migration Testing
- [ ] Baseline concurrent execution test (current collision rate)
- [ ] Baseline performance metrics (allocation time)
- [ ] Document current directory state
- [ ] Verify test isolation works correctly

### Per-Command Testing (Phases 2-5)
- [ ] Command executes without errors
- [ ] Topic directory created with correct number
- [ ] Subdirectories (reports/, plans/, debug/) created correctly
- [ ] Concurrent execution produces unique directories
- [ ] No duplicate topic numbers
- [ ] Artifacts land in correct locations

### Integration Testing (Phase 7)
- [ ] Mixed commands execute concurrently without collisions
- [ ] Sequential numbering verified across commands
- [ ] 50+ concurrent commands: 0% collision rate
- [ ] 1000 stress test allocations: 0% collision rate
- [ ] Backward compatibility with existing directories
- [ ] Lock file permissions correct
- [ ] Lock file gitignored

### Performance Testing (Phase 7)
- [ ] Allocation time <20ms average
- [ ] High concurrency allocation time <100ms
- [ ] Lock contention events logged
- [ ] No performance degradation over time

### Edge Case Testing (Phase 7)
- [ ] Permission denied: Graceful error
- [ ] Full disk: Graceful error
- [ ] Corrupted lock file: Handle or recreate
- [ ] Very long topic names: Truncate to 50 chars
- [ ] Special characters: Sanitize correctly
- [ ] Empty specs directory: Create with 001
- [ ] Concurrent first allocation: Both get unique numbers

### Final Validation (Phase 8)
- [ ] All commands use atomic allocation
- [ ] No count+increment pattern remaining
- [ ] Documentation complete and accurate
- [ ] Tests passing with 0% collision rate
- [ ] Git commit message comprehensive
- [ ] Lessons learned documented

---

**END OF PLAN**
