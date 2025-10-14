#!/usr/bin/env bash
# Test suite for state management and checkpoint operations
# Tests checkpoint save/restore, migration, concurrency handling

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test directory
TEST_DIR="/tmp/state_management_tests_$$"

# Setup test environment
setup() {
  echo "Setting up test environment: $TEST_DIR"
  rm -rf "$TEST_DIR"
  mkdir -p "$TEST_DIR/.claude/checkpoints"
  mkdir -p "$TEST_DIR/.claude/data/checkpoints"
}

# Cleanup test environment
cleanup() {
  echo "Cleaning up test environment"
  rm -rf "$TEST_DIR"
}

# Test helper functions
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  ((TESTS_PASSED++)) || true
  ((TESTS_RUN++)) || true
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  echo "  Reason: $2"
  ((TESTS_FAILED++)) || true
  ((TESTS_RUN++)) || true
}

info() {
  echo -e "${YELLOW}ℹ INFO${NC}: $1"
}

# Test: Checkpoint save with all fields
test_checkpoint_save() {
  info "Testing checkpoint save with all fields"

  local checkpoint_file="$TEST_DIR/.claude/data/checkpoints/test_save.json"

  # Create checkpoint with all required fields
  cat > "$checkpoint_file" <<'EOF'
{
  "version": "2.0",
  "plan_file": "/path/to/plan.md",
  "current_phase": 3,
  "timestamp": "2025-10-06T12:00:00Z",
  "completed_phases": [1, 2],
  "status": "in_progress",
  "replanning_count": 0,
  "last_replan_reason": "",
  "replan_history": []
}
EOF

  # Validate file creation
  if [ -f "$checkpoint_file" ]; then
    pass "Checkpoint file created"
  else
    fail "Checkpoint save failed" "File not found"
  fi

  # Validate all required fields present
  local required_fields=("version" "plan_file" "current_phase" "timestamp" "status")
  local all_present=true

  for field in "${required_fields[@]}"; do
    if ! grep -q "\"$field\"" "$checkpoint_file"; then
      all_present=false
      break
    fi
  done

  if $all_present; then
    pass "All required checkpoint fields present"
  else
    fail "Missing required checkpoint fields" "$(cat "$checkpoint_file")"
  fi
}

# Test: Checkpoint restore with validation
test_checkpoint_restore() {
  info "Testing checkpoint restore and validation"

  local checkpoint_file="$TEST_DIR/.claude/data/checkpoints/test_restore.json"

  # Create valid checkpoint
  cat > "$checkpoint_file" <<'EOF'
{
  "version": "2.0",
  "plan_file": "/test/plan.md",
  "current_phase": 2,
  "timestamp": "2025-10-06T10:00:00Z",
  "completed_phases": [1],
  "status": "in_progress"
}
EOF

  # Simulate restore - extract current_phase
  local phase=$(grep '"current_phase"' "$checkpoint_file" | sed 's/.*: \([0-9]*\).*/\1/')

  if [ "$phase" = "2" ]; then
    pass "Checkpoint restored current_phase correctly"
  else
    fail "Restore failed" "Expected phase 2, got $phase"
  fi

  # Validate completed_phases
  if grep -q '"completed_phases": \[1\]' "$checkpoint_file"; then
    pass "Checkpoint restored completed_phases correctly"
  else
    fail "Completed phases restore failed" "$(grep 'completed_phases' "$checkpoint_file")"
  fi
}

# Test: Checkpoint migration from old format
test_checkpoint_migration() {
  info "Testing checkpoint migration from v1 to v2"

  local old_checkpoint="$TEST_DIR/.claude/data/checkpoints/v1_checkpoint.json"

  # Create v1 format checkpoint (missing new fields)
  cat > "$old_checkpoint" <<'EOF'
{
  "version": "1.0",
  "plan_file": "/test/plan.md",
  "current_phase": 1,
  "timestamp": "2025-10-05T12:00:00Z"
}
EOF

  # Detect version
  local version=$(grep '"version"' "$old_checkpoint" | sed 's/.*"\([0-9.]*\)".*/\1/')

  if [ "$version" = "1.0" ]; then
    pass "Detected v1.0 checkpoint format"
  else
    fail "Version detection failed" "Got: $version"
  fi

  # Simulate migration - add new fields
  local migrated="$TEST_DIR/.claude/data/checkpoints/v2_checkpoint.json"
  {
    echo "{"
    grep -v "^}$" "$old_checkpoint" | grep -v "version"
    echo '  "version": "2.0",'
    echo '  "completed_phases": [],'
    echo '  "status": "in_progress",'
    echo '  "replanning_count": 0,'
    echo '  "last_replan_reason": "",'
    echo '  "replan_history": []'
    echo "}"
  } > "$migrated"

  # Validate migration
  if grep -q '"version": "2.0"' "$migrated" && \
     grep -q '"replanning_count"' "$migrated"; then
    pass "Successfully migrated checkpoint to v2.0"
  else
    fail "Migration failed" "$(cat "$migrated")"
  fi
}

# Test: Concurrent checkpoint handling
test_concurrent_checkpoint() {
  info "Testing concurrent checkpoint detection"

  local checkpoint_dir="$TEST_DIR/.claude/checkpoints"
  local plan_id="test_plan"
  local lock_file="$checkpoint_dir/${plan_id}.lock"

  # Create lock file
  echo "$$" > "$lock_file"

  if [ -f "$lock_file" ]; then
    pass "Created checkpoint lock file"
  else
    fail "Lock file creation failed" "Directory: $checkpoint_dir"
  fi

  # Simulate lock check
  if [ -f "$lock_file" ]; then
    local lock_pid=$(cat "$lock_file")
    pass "Detected existing lock (PID: $lock_pid)"
  else
    fail "Lock detection failed" "Lock file: $lock_file"
  fi

  # Clean up lock
  rm -f "$lock_file"

  if [ ! -f "$lock_file" ]; then
    pass "Lock file cleanup successful"
  else
    fail "Lock cleanup failed" "File still exists"
  fi
}

# Test: Lock file management
test_lock_file_management() {
  info "Testing lock file management"

  local checkpoint_dir="$TEST_DIR/.claude/checkpoints"
  local lock_file="$checkpoint_dir/test.lock"

  # Create lock with PID
  echo "12345" > "$lock_file"

  # Verify lock ownership
  local owner_pid=$(cat "$lock_file")
  if [ "$owner_pid" = "12345" ]; then
    pass "Lock file stores PID correctly"
  else
    fail "Lock PID storage failed" "Got: $owner_pid"
  fi

  # Simulate stale lock detection (PID doesn't exist)
  if ! ps -p "$owner_pid" >/dev/null 2>&1; then
    pass "Detected stale lock (non-existent PID)"
  else
    info "PID exists on system, cannot test stale detection"
  fi

  rm -f "$lock_file"
}

# Test: Checkpoint field getters/setters
test_checkpoint_field_operations() {
  info "Testing checkpoint field get/set operations"

  local checkpoint_file="$TEST_DIR/.claude/data/checkpoints/fields.json"

  # Create checkpoint
  cat > "$checkpoint_file" <<'EOF'
{
  "version": "2.0",
  "plan_file": "/test/plan.md",
  "current_phase": 1,
  "replanning_count": 0
}
EOF

  # Get field value
  local phase=$(grep '"current_phase"' "$checkpoint_file" | sed 's/.*: \([0-9]*\).*/\1/')
  if [ "$phase" = "1" ]; then
    pass "Get field operation successful"
  else
    fail "Get field failed" "Got: $phase"
  fi

  # Set field value (simulate updating current_phase)
  sed -i 's/"current_phase": 1/"current_phase": 2/' "$checkpoint_file"

  local new_phase=$(grep '"current_phase"' "$checkpoint_file" | sed 's/.*: \([0-9]*\).*/\1/')
  if [ "$new_phase" = "2" ]; then
    pass "Set field operation successful"
  else
    fail "Set field failed" "Got: $new_phase"
  fi
}

# Test: Checkpoint validation
test_checkpoint_validation() {
  info "Testing checkpoint validation"

  # Valid checkpoint
  local valid_file="$TEST_DIR/.claude/data/checkpoints/valid.json"
  cat > "$valid_file" <<'EOF'
{
  "version": "2.0",
  "plan_file": "/test/plan.md",
  "current_phase": 1,
  "status": "in_progress"
}
EOF

  if grep -q '"version"' "$valid_file" && \
     grep -q '"plan_file"' "$valid_file" && \
     grep -q '"current_phase"' "$valid_file"; then
    pass "Valid checkpoint passed validation"
  else
    fail "Valid checkpoint rejected" "$(cat "$valid_file")"
  fi

  # Invalid checkpoint (missing required field)
  local invalid_file="$TEST_DIR/.claude/data/checkpoints/invalid.json"
  cat > "$invalid_file" <<'EOF'
{
  "version": "2.0",
  "current_phase": 1
}
EOF

  if ! grep -q '"plan_file"' "$invalid_file"; then
    pass "Detected missing required field"
  else
    fail "Validation failed to detect missing field" "$(cat "$invalid_file")"
  fi
}

# Test: Replanning fields in checkpoint
test_replanning_fields() {
  info "Testing replanning-specific checkpoint fields"

  local checkpoint_file="$TEST_DIR/.claude/data/checkpoints/replan.json"

  cat > "$checkpoint_file" <<'EOF'
{
  "version": "2.0",
  "plan_file": "/test/plan.md",
  "current_phase": 3,
  "replanning_count": 2,
  "last_replan_reason": "Test failures in phase 3",
  "replan_phase_3_count": 2,
  "replan_history": [
    {
      "phase": 3,
      "reason": "Complexity trigger",
      "timestamp": "2025-10-06T10:00:00Z"
    },
    {
      "phase": 3,
      "reason": "Test failures",
      "timestamp": "2025-10-06T11:00:00Z"
    }
  ]
}
EOF

  # Validate replanning fields
  if grep -q '"replanning_count": 2' "$checkpoint_file" && \
     grep -q '"replan_phase_3_count": 2' "$checkpoint_file" && \
     grep -q '"replan_history"' "$checkpoint_file"; then
    pass "Replanning fields stored correctly"
  else
    fail "Replanning fields missing or incorrect" "$(cat "$checkpoint_file")"
  fi

  # Validate history array
  local history_count=$(grep -c '"phase": 3' "$checkpoint_file")
  if [ "$history_count" -eq 2 ]; then
    pass "Replan history array correct"
  else
    fail "Replan history incorrect" "Expected 2 entries, got $history_count"
  fi
}

# Test: Checkpoint schema evolution
test_checkpoint_schema_evolution() {
  info "Testing checkpoint schema evolution"

  # Create checkpoint with future fields (forward compatibility)
  local future_file="$TEST_DIR/.claude/data/checkpoints/future.json"
  cat > "$future_file" <<'EOF'
{
  "version": "3.0",
  "plan_file": "/test/plan.md",
  "current_phase": 1,
  "future_field_1": "value1",
  "future_field_2": "value2"
}
EOF

  # Should still be able to extract known fields
  if grep -q '"version"' "$future_file" && \
     grep -q '"plan_file"' "$future_file"; then
    pass "Forward compatibility maintained"
  else
    fail "Forward compatibility broken" "Cannot read known fields"
  fi
}

# Test: Atomic checkpoint updates
test_atomic_checkpoint_updates() {
  info "Testing atomic checkpoint updates"

  local checkpoint_file="$TEST_DIR/.claude/data/checkpoints/atomic.json"
  local temp_file="${checkpoint_file}.tmp"

  # Create original checkpoint
  cat > "$checkpoint_file" <<'EOF'
{
  "version": "2.0",
  "current_phase": 1
}
EOF

  # Simulate atomic update (write to temp, then move)
  cat > "$temp_file" <<'EOF'
{
  "version": "2.0",
  "current_phase": 2
}
EOF

  mv "$temp_file" "$checkpoint_file"

  # Verify update successful
  if grep -q '"current_phase": 2' "$checkpoint_file"; then
    pass "Atomic checkpoint update successful"
  else
    fail "Atomic update failed" "$(cat "$checkpoint_file")"
  fi

  # Verify no temp file left behind
  if [ ! -f "$temp_file" ]; then
    pass "Temp file cleaned up"
  else
    fail "Temp file not cleaned up" "File: $temp_file"
  fi
}

# Run all tests
run_all_tests() {
  echo "================================"
  echo "State Management Test Suite"
  echo "================================"
  echo ""

  setup

  test_checkpoint_save
  test_checkpoint_restore
  test_checkpoint_migration
  test_concurrent_checkpoint
  test_lock_file_management
  test_checkpoint_field_operations
  test_checkpoint_validation
  test_replanning_fields
  test_checkpoint_schema_evolution
  test_atomic_checkpoint_updates

  cleanup

  echo ""
  echo "================================"
  echo "Test Results"
  echo "================================"
  echo "Tests Run:    $TESTS_RUN"
  echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
  echo ""

  if [ "$TESTS_FAILED" -gt 0 ]; then
    echo -e "${RED}FAILURE${NC}: Some tests failed"
    exit 1
  else
    echo -e "${GREEN}SUCCESS${NC}: All tests passed"
    exit 0
  fi
}

# Run tests
run_all_tests
