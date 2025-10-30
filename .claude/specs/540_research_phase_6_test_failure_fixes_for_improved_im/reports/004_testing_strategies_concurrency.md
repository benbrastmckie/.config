# Testing Strategies for Concurrent Operations Research Report

## Metadata
- **Date**: 2025-10-30
- **Agent**: research-specialist
- **Topic**: Testing Strategies for Concurrent Operations
- **Report Type**: codebase analysis + best practices research
- **Complexity Level**: 4

## Executive Summary

Current concurrent testing in `test_system_wide_location.sh` demonstrates partial effectiveness with a critical file locking test failure (3/5 unique topic numbers). Research reveals that race condition testing requires a multi-layered strategy combining stress testing (high iteration counts), deterministic verification checks, timing variations, and comprehensive diagnostics. Best practices from 2025 emphasize that race conditions cannot be eliminated through deterministic unit tests alone but rather require probabilistic stress testing combined with runtime invariant validation and atomic operations using `flock`.

## Findings

### Current Test Implementation Analysis

**File**: `/home/benjamin/.config/.claude/tests/test_system_wide_location.sh`

#### Concurrent Test Pattern (Lines 1072-1240)
The test suite implements 5 concurrent operation tests:
- **Test 3.1**: Parallel orchestrate invocations (3 processes)
- **Test 3.2**: Directory conflict detection (2 processes)
- **Test 3.3**: Subdirectory integrity validation (2 processes)
- **Test 3.4**: File locking verification (5 processes) - **FAILING**
- **Test 3.5**: Performance measurement (3 processes, <3s threshold)

**Current Synchronization Pattern**:
```bash
# Lines 1181-1190: Test 3.4 implementation
for i in {1..5}; do
  (simulate_orchestrate_phase0 "concurrent lock test $i" > "/tmp/concurrent_lock_$i.json") &
  pids+=($!)
done

for pid in "${pids[@]}"; do
  wait "$pid" 2>/dev/null || true
done
```

**Failure Symptoms** (Line 1211):
- Expected: 5 unique topic numbers
- Actual: 3 unique topic numbers (40% collision rate)
- Root cause: Race condition in topic number generation

#### Synchronization Mechanism Analysis

**File**: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` (Lines 129-157)

**Current Implementation**:
```bash
get_next_topic_number() {
  local specs_root="$1"
  local lockfile="${specs_root}/.topic_number.lock"

  {
    flock -x 200 || return 1

    # Find maximum existing topic number
    max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
      sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
      sort -n | tail -1)

    # Increment and format
    printf "%03d" $((10#$max_num + 1))

  } 200>"$lockfile"
}
```

**Critical Gap**: Lock is released BEFORE directory creation completes. Race window exists between:
1. Get next number (001)
2. Release lock
3. Create directory (001_topic/)

If two processes reach step 1 simultaneously, both get "001" before either creates the directory.

#### Test Timing Characteristics

**No explicit timing variations**:
- No `sleep` statements to force race windows
- No `nanosleep` for sub-second timing control
- Relies on natural process scheduling variance

**Verification approach** (Lines 1192-1213):
```bash
# Extract all topic numbers
for i in {1..5}; do
  num=$(jq -r '.topic_number' "/tmp/concurrent_lock_$i.json")
  topic_nums+=("$num")
done

# Check uniqueness
unique_count=$(printf '%s\n' "${topic_nums[@]}" | sort -u | wc -l)
```

**Strengths**:
- Simple uniqueness verification
- Clear pass/fail criteria

**Weaknesses**:
- No diagnostic output showing which numbers collided
- No lockfile inspection to verify lock acquisition
- No timing data to understand race window duration

### Best Practices from Industry Research (2025)

#### Strategy 1: Stress Testing with High Iteration Counts

**Source**: Stack Overflow (top-voted answer)

**Recommendation**: "Run a large number of iterations to increase the statistical likelihood of catching threading issues."

**Application to current test**:
- Current: 5 parallel processes (1 test run)
- Recommended: 10-100 parallel processes OR 50-1000 sequential iterations
- Rationale: Race conditions are probabilistic; more attempts = higher detection probability

**Implementation pattern**:
```bash
# Stress test variant
test_concurrent_stress() {
  local collision_count=0

  for iteration in {1..100}; do
    # Launch 10 parallel processes
    for i in {1..10}; do
      (simulate_orchestrate_phase0 "stress test $iteration-$i" > "/tmp/stress_${iteration}_$i.json") &
    done
    wait

    # Check for collisions in this iteration
    local nums=($(jq -r '.topic_number' /tmp/stress_${iteration}_*.json | sort))
    local unique=$(printf '%s\n' "${nums[@]}" | uniq | wc -l)

    if [ "$unique" -lt 10 ]; then
      ((collision_count++))
      echo "Iteration $iteration: collision detected (${unique}/10 unique)"
    fi
  done

  echo "Collision rate: ${collision_count}/100 iterations"
}
```

#### Strategy 2: Runtime Invariant Checks

**Source**: Stack Overflow (race condition testing discussion)

**Recommendation**: "Introduce run-time checks that verify the protocol invariants are honoured to quantify problems when they occur."

**Invariants for topic number generation**:
1. Topic numbers MUST be sequential (no gaps)
2. Topic numbers MUST be unique (no duplicates)
3. Topic directories MUST exist after generation
4. Lock file MUST exist during critical section

**Implementation pattern**:
```bash
verify_topic_invariants() {
  local specs_root="$1"

  # Invariant 1: Sequential numbering
  local gaps=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* | \
    sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
    awk 'NR>1 {if ($0 != prev+1) print "GAP: " prev " -> " $0} {prev=$0}')

  # Invariant 2: No duplicate directories
  local duplicates=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* | \
    sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
    sort | uniq -d)

  # Report violations
  if [ -n "$gaps" ] || [ -n "$duplicates" ]; then
    echo "INVARIANT VIOLATION:"
    [ -n "$gaps" ] && echo "  Gaps: $gaps"
    [ -n "$duplicates" ] && echo "  Duplicates: $duplicates"
    return 1
  fi

  return 0
}
```

#### Strategy 3: Timing Variations to Force Race Windows

**Source**: Stack Overflow + industry blogs

**Recommendation**: Use "nanosleeps (sleep in the right place greatly increases the chance a race occurs)."

**Critical timing points** for topic number generation:
```bash
# Point A: After lock acquisition, before directory scan
flock -x 200
# <- INSERT SLEEP HERE to delay directory scan
max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_*)

# Point B: After number calculation, before directory creation
printf "%03d" $((10#$max_num + 1))
# <- INSERT SLEEP HERE to widen race window

# Point C: After lock release, before directory creation
# (This is the ACTUAL race window in current implementation)
```

**Implementation pattern**:
```bash
# Timing variation test
test_concurrent_with_timing_variations() {
  local variations=("0" "0.001" "0.01" "0.1")

  for delay in "${variations[@]}"; do
    echo "Testing with ${delay}s delay..."

    # Set delay environment variable (read by get_next_topic_number)
    export TEST_RACE_DELAY="$delay"

    # Run concurrent test
    for i in {1..5}; do
      (simulate_orchestrate_phase0 "timing test $i" > "/tmp/timing_$i.json") &
    done
    wait

    # Check for collisions
    local unique=$(jq -r '.topic_number' /tmp/timing_*.json | sort -u | wc -l)
    echo "  Result: ${unique}/5 unique (delay: ${delay}s)"
  done

  unset TEST_RACE_DELAY
}
```

#### Strategy 4: Comprehensive Diagnostics

**Source**: Multiple sources (GeeksforGeeks, Stack Overflow)

**Recommendation**: "Implementing comprehensive logging around critical sections and shared resources for visibility."

**Diagnostic data to collect**:
1. **Lock acquisition timestamps**: When each process acquires/releases flock
2. **Topic number decisions**: What number each process calculated
3. **Directory creation order**: Timestamp of `mkdir` calls
4. **Collision forensics**: Which processes got duplicate numbers

**Implementation pattern**:
```bash
# Enhanced diagnostic logging
get_next_topic_number_with_diagnostics() {
  local specs_root="$1"
  local lockfile="${specs_root}/.topic_number.lock"
  local logfile="${specs_root}/.topic_generation.log"
  local pid=$$
  local timestamp=$(date +%s%N)

  {
    # Log lock acquisition attempt
    echo "[$timestamp] PID $pid: Attempting lock acquisition" >> "$logfile"

    flock -x 200 || {
      echo "[$timestamp] PID $pid: Lock acquisition FAILED" >> "$logfile"
      return 1
    }

    local lock_acquired=$(date +%s%N)
    echo "[$lock_acquired] PID $pid: Lock ACQUIRED (waited $((lock_acquired - timestamp))ns)" >> "$logfile"

    # Find maximum topic number
    max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
      sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
      sort -n | tail -1)

    local next_num
    [ -z "$max_num" ] && next_num="001" || next_num=$(printf "%03d" $((10#$max_num + 1)))

    echo "[$lock_acquired] PID $pid: Calculated next number: $next_num (max was: ${max_num:-none})" >> "$logfile"

    echo "$next_num"

    local lock_released=$(date +%s%N)
    echo "[$lock_released] PID $pid: Lock RELEASED (held for $((lock_released - lock_acquired))ns)" >> "$logfile"

  } 200>"$lockfile"
}
```

**Analysis commands**:
```bash
# Detect race condition from logs
analyze_race_condition_logs() {
  local logfile="$1"

  echo "=== Lock Acquisition Timeline ==="
  grep "Lock ACQUIRED" "$logfile" | sort

  echo ""
  echo "=== Topic Number Collisions ==="
  grep "Calculated next number" "$logfile" | \
    awk '{print $NF}' | \
    sort | uniq -c | \
    awk '$1 > 1 {print "COLLISION: " $2 " assigned " $1 " times"}'

  echo ""
  echo "=== Lock Hold Durations ==="
  grep "held for" "$logfile" | \
    sed 's/.*held for \([0-9]*\)ns.*/\1/' | \
    awk '{sum+=$1; count++} END {print "Average: " sum/count "ns, Max: " max}'
}
```

#### Strategy 5: Automated Detection Tools

**Source**: Stack Overflow (multiple answers)

**Tools recommended for bash scripts**:
1. **Valgrind DRD**: Thread error detection (C/C++ focus)
2. **ThreadSanitizer**: Data race detector (limited bash support)
3. **ShellCheck**: Static analysis (doesn't catch race conditions)

**Limitation**: Most tools target compiled languages, not interpreted shell scripts.

**Bash-specific approach**: Manual instrumentation + stress testing

### Alternative Testing Approaches

#### Approach 1: Isolated Atomicity Tests

**Test atomic operations separately from full workflow**:
```bash
test_flock_atomicity() {
  local lockfile="/tmp/flock_test.lock"
  local counter_file="/tmp/counter.txt"
  echo "0" > "$counter_file"

  # Launch 100 parallel processes
  for i in {1..100}; do
    (
      {
        flock -x 200 || exit 1

        local count=$(cat "$counter_file")
        count=$((count + 1))
        echo "$count" > "$counter_file"

      } 200>"$lockfile"
    ) &
  done
  wait

  # Verify counter reached 100 (no lost updates)
  local final=$(cat "$counter_file")
  if [ "$final" -eq 100 ]; then
    echo "PASS: flock provided atomicity (100/100)"
  else
    echo "FAIL: Lost updates detected ($final/100)"
  fi
}
```

**Benefits**:
- Isolates locking mechanism from business logic
- High confidence in flock implementation
- Fast execution (<1s for 100 iterations)

#### Approach 2: Checksum-Based Verification

**Use unique markers to detect collisions**:
```bash
test_concurrent_with_checksums() {
  local specs_root="/tmp/checksum_test"
  mkdir -p "$specs_root"

  # Each process writes a unique checksum to its topic directory
  for i in {1..10}; do
    (
      local checksum=$(echo "$RANDOM-$$-$(date +%s%N)" | md5sum | cut -d' ' -f1)
      local location_json=$(perform_location_detection "checksum test $i" "true")
      local topic_path=$(echo "$location_json" | jq -r '.topic_path')

      # Write checksum to marker file
      echo "$checksum" > "${topic_path}/.checksum"
      echo "${topic_path}|${checksum}"
    ) &
  done | sort > /tmp/checksum_results.txt
  wait

  # Analyze results
  echo "=== Collision Analysis ==="
  awk -F'|' '{paths[$1]++; sums[$2]++}
    END {
      for (p in paths) if (paths[p] > 1) print "Path collision: " p " (" paths[p] " times)"
      for (s in sums) if (sums[s] > 1) print "Checksum collision: " s " (IMPOSSIBLE - indicates overwrite)"
    }' /tmp/checksum_results.txt
}
```

#### Approach 3: Separate Concurrent vs Integration Tests

**Current approach mixes concerns**:
- Concurrent execution (test flock)
- Integration (test full workflow)

**Recommendation**: Separate test suites
```bash
# Suite 1: Pure concurrency tests (no business logic)
test_suite_concurrency() {
  test_flock_atomicity
  test_counter_increment_race
  test_file_creation_race
}

# Suite 2: Integration tests (business logic, less concurrency stress)
test_suite_integration() {
  test_report_command_simple
  test_plan_command_complex
  test_orchestrate_workflow
}

# Suite 3: Stress tests (long-running, high iteration)
test_suite_stress() {
  test_1000_sequential_topics
  test_100_parallel_workflows
  test_sustained_load_5min
}
```

### Trade-offs and Balance

#### Thoroughness vs Runtime

**Current**: 50 tests, ~10-15 seconds total runtime
**Stress testing**: 1000+ iterations, 5-30 minutes runtime

**Recommendation**:
- **CI/commit hook**: Current suite (fast feedback)
- **Pre-release gate**: Stress suite (high confidence)
- **Nightly**: Extended stress suite (100,000+ iterations)

#### Determinism vs Coverage

**Deterministic tests**:
- **Pros**: Reproducible failures, easy debugging
- **Cons**: May miss rare race conditions

**Stress tests**:
- **Pros**: Higher coverage of edge cases
- **Cons**: Flaky results, harder to debug

**Recommendation**: Use both
```bash
# Deterministic: Verify flock works at all
test_flock_basic() {
  # Sequential test: Should always pass
  for i in {1..10}; do
    get_next_topic_number "$SPECS_ROOT"
  done
}

# Stress: Find rare race conditions
test_flock_stress() {
  # Parallel test: May occasionally fail
  for iteration in {1..100}; do
    for i in {1..10}; do
      (get_next_topic_number "$SPECS_ROOT") &
    done
    wait
  done
}
```

## Recommendations

### Recommendation 1: Fix Root Cause - Extend Lock Scope

**Problem**: Lock released before directory creation (race window)

**Solution**: Hold lock through directory creation
```bash
get_next_topic_number_atomic() {
  local specs_root="$1"
  local lockfile="${specs_root}/.topic_number.lock"

  {
    flock -x 200 || return 1

    # Calculate next number (inside lock)
    max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
      sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
      sort -n | tail -1)

    next_num=$([ -z "$max_num" ] && echo "001" || printf "%03d" $((10#$max_num + 1)))

    # Create directory BEFORE releasing lock
    mkdir -p "${specs_root}/${next_num}_placeholder" 2>/dev/null || true

    echo "$next_num"

  } 200>"$lockfile"
  # Lock released AFTER directory exists
}
```

**Impact**: Eliminates race condition at source (preventive > detective)

### Recommendation 2: Enhance Test Diagnostics

**Problem**: Test failure provides minimal debugging information

**Solution**: Add comprehensive logging
```bash
test_concurrent_4_file_locking_enhanced() {
  local logfile="/tmp/concurrent_lock_diagnostics_$$.log"

  # Enable diagnostic logging
  export DIAGNOSTIC_MODE=1
  export DIAGNOSTIC_LOG="$logfile"

  # Launch processes
  for i in {1..5}; do
    (simulate_orchestrate_phase0 "lock test $i" > "/tmp/lock_$i.json") &
  done
  wait

  # Analyze results
  local topic_nums=($(jq -r '.topic_number' /tmp/lock_*.json | sort))
  local unique=$(printf '%s\n' "${topic_nums[@]}" | sort -u | wc -l)

  if [ "$unique" -ne 5 ]; then
    echo "FAILURE DIAGNOSTICS:"
    echo "  Assigned numbers: ${topic_nums[*]}"
    echo "  Unique count: $unique"
    echo ""
    echo "  Lock acquisition timeline:"
    grep "Lock ACQUIRED" "$logfile" | sort
    echo ""
    echo "  Number assignments:"
    grep "Calculated next number" "$logfile" | sort
  fi

  unset DIAGNOSTIC_MODE DIAGNOSTIC_LOG
}
```

### Recommendation 3: Implement Stress Test Suite

**Problem**: 5 parallel processes insufficient to catch rare race conditions

**Solution**: Add dedicated stress test script
```bash
# .claude/tests/test_concurrency_stress.sh
#!/usr/bin/env bash
# Extended stress test suite for concurrent operations
# Runtime: ~5 minutes, CI skip flag: SKIP_STRESS_TESTS=1

ITERATIONS=100
PARALLEL_PROCS=10

test_stress_topic_generation() {
  local collision_count=0

  for iter in {1..100}; do
    # Launch 10 parallel processes
    for i in {1..10}; do
      (perform_location_detection "stress $iter-$i" "true" > "/tmp/stress_${iter}_${i}.json") &
    done
    wait

    # Check uniqueness
    local unique=$(jq -r '.topic_number' /tmp/stress_${iter}_*.json | sort -u | wc -l)
    [ "$unique" -lt 10 ] && ((collision_count++))

    # Report progress every 10 iterations
    [ $((iter % 10)) -eq 0 ] && echo "Progress: $iter/100 (collisions: $collision_count)"
  done

  echo "Final collision rate: ${collision_count}/100 ($(( collision_count * 100 / 100 ))%)"

  # Strict threshold: <1% collision rate acceptable
  [ "$collision_count" -le 1 ]
}
```

### Recommendation 4: Add Timing Variation Tests

**Problem**: Tests don't explore different race window timings

**Solution**: Inject configurable delays
```bash
# In unified-location-detection.sh:
get_next_topic_number() {
  local specs_root="$1"
  local lockfile="${specs_root}/.topic_number.lock"

  {
    flock -x 200 || return 1

    max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
      sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
      sort -n | tail -1)

    # Timing variation for testing (no-op in production)
    [ -n "${TEST_RACE_DELAY:-}" ] && sleep "${TEST_RACE_DELAY}"

    [ -z "$max_num" ] && echo "001" || printf "%03d" $((10#$max_num + 1))

  } 200>"$lockfile"
}

# Test suite:
test_timing_variations() {
  for delay in 0 0.001 0.01 0.1; do
    export TEST_RACE_DELAY="$delay"
    test_concurrent_4_file_locking
    unset TEST_RACE_DELAY
  done
}
```

### Recommendation 5: Implement Runtime Invariant Checks

**Problem**: Tests verify end state but not intermediate invariants

**Solution**: Add continuous validation
```bash
# Verify invariants after EVERY test
verify_all_invariants() {
  local specs_root="$1"

  # Invariant 1: Sequential numbering (no gaps)
  local max_topic=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | wc -l)
  local expected=$(printf "%03d" "$max_topic")
  local actual=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
    sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | sort -n | tail -1)

  if [ "$expected" != "$actual" ]; then
    echo "INVARIANT VIOLATION: Gap detected (expected $expected, found $actual)"
    return 1
  fi

  # Invariant 2: No duplicate directories
  local duplicates=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
    sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | sort | uniq -d | wc -l)

  if [ "$duplicates" -gt 0 ]; then
    echo "INVARIANT VIOLATION: Duplicate topic numbers detected"
    return 1
  fi

  return 0
}

# Add to test framework
after_each_test() {
  verify_all_invariants "$TEST_SPECS_ROOT" || {
    echo "CRITICAL: Invariant check failed after test"
    exit 2
  }
}
```

### Recommendation 6: Document "Good" Concurrency Test Characteristics

**Create testing guide** (`.claude/docs/guides/concurrency-testing-guide.md`):

**Good Concurrency Test Checklist**:
- [ ] Tests actual race condition (not just parallel execution)
- [ ] High iteration count (>50 for unit tests, >1000 for stress tests)
- [ ] Clear pass/fail criteria (e.g., "100% unique topic numbers")
- [ ] Comprehensive diagnostics on failure (timestamps, lock acquisition order)
- [ ] Timing variations explored (delays at critical points)
- [ ] Runtime invariant validation (checked after every test)
- [ ] Separate atomic operation tests from integration tests
- [ ] Documented expected behavior and failure modes

**Bad Concurrency Test Anti-Patterns**:
- ❌ Single iteration (race may not occur)
- ❌ Too few parallel processes (<5)
- ❌ No diagnostic output on failure
- ❌ Mixed concerns (testing multiple things simultaneously)
- ❌ Assumes deterministic behavior (race conditions are probabilistic)

## References

### Codebase Files Analyzed
- `/home/benjamin/.config/.claude/tests/test_system_wide_location.sh` (lines 1-1515)
  - Lines 1066-1240: Concurrent execution test group
  - Lines 1178-1217: File locking test (test_concurrent_4)
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` (lines 1-200)
  - Lines 129-157: `get_next_topic_number()` with flock implementation
  - Lines 136-155: Critical section with race window
- `/home/benjamin/.config/.claude/tests/test_checkpoint_parallel_ops.sh` (lines 1-290)
  - Example of simpler concurrent test approach
- `/home/benjamin/.config/.claude/tests/test_parallel_expansion.sh` (lines 1-219)
  - Parallel agent invocation testing pattern

### External Sources
1. Stack Overflow: "How to write tests that check for race conditions?"
   - Key insight: "You cannot unittest race conditions out of a program"
   - Recommendation: Stress testing with high iteration counts
   - URL: https://stackoverflow.com/questions/18771592/

2. Linux Bash: "Use flock to prevent concurrent script execution"
   - Key insight: Atomic operations using flock with file descriptor isolation
   - Pattern: `{ flock -x 200; critical_section; } 200>"$lockfile"`
   - URL: https://www.linuxbash.sh/post/use-flock-to-prevent-concurrent-script-execution

3. Stack Overflow: "Correct locking in shell scripts?"
   - Key insight: Lock must encompass entire critical section (read + write)
   - Anti-pattern: Check-then-act without atomic lock
   - URL: https://unix.stackexchange.com/questions/22044/

4. The Green Report: "Using Stress Tests to Catch Race Conditions"
   - Key insight: Race conditions only emerge under concurrent load
   - Recommendation: Simulate real-world concurrent scenarios
   - URL: https://www.thegreenreport.blog/articles/using-stress-tests-to-catch-race-conditions-in-api-rate-limiting-logic/

5. GeeksforGeeks: "How to fix a Race Condition in an Async Architecture?"
   - Key insight: Atomic operations and comprehensive logging
   - Tools: Runtime invariant checks, lock acquisition logging
   - URL: https://www.geeksforgeeks.org/system-design/how-to-fix-a-race-condition-in-an-async-architecture/

6. DEV Community: "Implementing Concurrency in Shell Scripts"
   - Key insight: Background execution with `&` and `wait` for parallel operations
   - Pattern: Process ID tracking for result collection
   - URL: https://dev.to/siddhantkcode/implementing-concurrency-in-shell-scripts-521o

7. Mindful Chase: "Troubleshooting Subshell and Concurrency Issues in Bash Scripts"
   - Key insight: Subshell variable scope issues in concurrent contexts
   - Recommendation: Use temporary files for inter-process communication
   - URL: https://www.mindfulchase.com/explore/troubleshooting-tips/programming-languages/troubleshooting-subshell-and-concurrency-issues-in-bash-scripts.html

8. Medium (Vladyslav Kekukh): "Why They Ask: What's a Race Condition and How Do You Prevent It?"
   - Key insight: Race conditions are probabilistic, not deterministic
   - Testing strategy: Multiple approaches required (stress + invariants + atomicity)
   - URL: https://medium.com/@vkekukh/whats-a-race-condition-and-how-do-you-prevent-it-b794f480a324
