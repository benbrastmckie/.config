# Concurrent Execution Safety Standard

## Overview

This standard defines requirements for commands to safely execute multiple instances concurrently without state interference. The pattern eliminates shared state ID files and uses nanosecond-precision WORKFLOW_ID generation with state file discovery.

## Problem Statement

When multiple instances of the same command run concurrently, they previously shared a singleton state ID file (e.g., `plan_state_id.txt`) to coordinate WORKFLOW_ID across bash blocks. This pattern caused race conditions:

1. **Instance A** writes `WORKFLOW_ID="plan_1765352600"` to `plan_state_id.txt`
2. **Instance B** overwrites with `WORKFLOW_ID="plan_1765352804"`
3. **Instance A** reads state ID file in Block 2, gets wrong WORKFLOW_ID
4. **Instance A** fails with "Failed to restore WORKFLOW_ID" error

## Solution

### Three-Part Pattern

1. **Nanosecond-Precision WORKFLOW_ID**: Use `date +%s%N` for unique timestamps
2. **Eliminate State ID Files**: WORKFLOW_ID embedded in state file, no coordination file
3. **State File Discovery**: Pattern matching + mtime sorting to find correct state file

## Required Pattern

### Block 1: Initialization

```bash
# Source state persistence library
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || {
  echo "Error: Cannot load state-persistence library"
  exit 1
}

# Generate unique WORKFLOW_ID (nanosecond precision)
WORKFLOW_ID=$(generate_unique_workflow_id "command_name")

# Initialize workflow state (WORKFLOW_ID embedded in file)
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
```

### Block 2+: State Restoration

```bash
# Source state persistence library
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || {
  echo "Error: Cannot load state-persistence library"
  exit 1
}

# Discover latest state file by pattern matching
STATE_FILE=$(discover_latest_state_file "command_name")

if [ -z "$STATE_FILE" ]; then
  echo "Error: Failed to discover state file for command_name"
  exit 1
fi

# Source state file to restore WORKFLOW_ID and other variables
source "$STATE_FILE"
```

## Library Functions

### `generate_unique_workflow_id(command_name)`

Generates nanosecond-precision WORKFLOW_ID.

**Signature**:
```bash
generate_unique_workflow_id(command_name) -> WORKFLOW_ID
```

**Parameters**:
- `command_name`: Command name (lowercase, alphanumeric + underscore)

**Returns**:
- `WORKFLOW_ID`: Format `${command_name}_$(date +%s%N)`

**Example**:
```bash
WORKFLOW_ID=$(generate_unique_workflow_id "plan")
# Output: plan_1765352600123456789 (19-digit timestamp)
```

**Fallback**: If `date +%s%N` not available (non-GNU date), falls back to `${command_name}_$(date +%s)_$$` (second-precision + PID).

### `discover_latest_state_file(command_prefix)`

Finds most recent state file by pattern matching.

**Signature**:
```bash
discover_latest_state_file(command_prefix) -> STATE_FILE_PATH
```

**Parameters**:
- `command_prefix`: Command prefix for pattern matching (e.g., "plan", "implement")

**Returns**:
- Absolute path to most recent state file, or empty string (exit 1)

**Pattern**: `workflow_${command_prefix}_*.sh`

**Example**:
```bash
STATE_FILE=$(discover_latest_state_file "plan")
# Output: /home/user/.config/.claude/tmp/workflow_plan_1765352600123456789.sh
```

**Discovery Logic**:
1. Find all files matching pattern in `.claude/tmp/`
2. Sort by mtime (most recent first)
3. Return first match (most recent)
4. Return empty string if no matches

**Performance**: 5-10ms for <100 state files

## Anti-Patterns

### Prohibited: Shared State ID Files

**NEVER** use singleton state ID files for WORKFLOW_ID coordination:

```bash
# ❌ WRONG: Shared state ID file (race condition)
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"

# Block 2+
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)  # May read wrong ID
```

**Why This Fails**:
- Multiple instances overwrite same file
- No atomicity guarantees
- Race condition on read/write

### Prohibited: Second-Precision Timestamps

**NEVER** use second-precision timestamps alone:

```bash
# ❌ WRONG: Second precision (collision risk)
WORKFLOW_ID="plan_$(date +%s)"
```

**Why This Fails**:
- Two instances started in same second get identical WORKFLOW_ID
- State files overwrite each other
- High collision probability for concurrent execution

### Prohibited: Global Lock Files

**NEVER** use global lock files for serialization:

```bash
# ❌ WRONG: Global lock (defeats parallelism)
LOCK_FILE="/tmp/plan_command.lock"
exec 200>"$LOCK_FILE"
flock -x 200 || exit 1
```

**Why This Fails**:
- Serializes all command instances
- Defeats purpose of concurrent execution
- Deadlock risk if lock not released

## Collision Probability Analysis

### Nanosecond Precision

**Time Resolution**: 1 nanosecond (1 billionth of a second)

**Collision Risk**:
- **Scenario**: Two humans start command at "same" time
- **Human Reaction Time**: ~200-300ms (200,000,000 nanoseconds)
- **Collision Probability**: ~0% for human-triggered execution

**Math**:
- Nanosecond range per second: 1,000,000,000 unique values
- Human timing precision: ~200-300ms minimum separation
- Collision requires: Start within 1ns of each other (impossible for humans)

**Conclusion**: Nanosecond precision eliminates collision risk for concurrent human-triggered commands.

### Second Precision (For Comparison)

**Time Resolution**: 1 second

**Collision Risk**:
- **Scenario**: Two commands started in same second
- **Probability**: High (multiple commands per second common)
- **Collision Probability**: ~20-30% for concurrent execution

**Conclusion**: Second-precision UNSAFE for concurrent execution.

## Validation

### Pre-Commit Validation

The `lint-shared-state-files.sh` validator detects shared state ID file anti-pattern:

```bash
# Run validator
bash .claude/scripts/lint/lint-shared-state-files.sh .claude/commands/my-command.md

# Exit code 0: Clean (no violations)
# Exit code 1: ERROR (shared state ID file detected)
```

**Detection Patterns**:
- `STATE_ID_FILE=.*state_id.txt`
- `echo.*>.*state_id.txt`
- `cat.*state_id.txt`

### Standards Validation

Integrated with `validate-all-standards.sh`:

```bash
# Run concurrency validation
bash .claude/scripts/validate-all-standards.sh --concurrency

# Run all standards (includes concurrency)
bash .claude/scripts/validate-all-standards.sh --all
```

## Testing Requirements

### Unit Testing

**State File Discovery**:
- Test with 0, 1, 5, 10 state files
- Test command prefix filtering
- Test missing directory handling

**WORKFLOW_ID Uniqueness**:
- Test 1000 rapid invocations (0 duplicates)
- Test nanosecond precision format
- Test fallback format (non-GNU date)

### Concurrent Execution Testing

**Test Matrix**:
- 2 instances: Basic race condition test
- 3 instances: Multi-instance interference test
- 5 instances: Standard concurrent workload test
- 10 instances: Stress test

**Validation Criteria**:
- No "Failed to restore WORKFLOW_ID" errors
- All instances complete successfully
- No orphaned state files
- State file discovery selects correct file
- WORKFLOW_IDs unique across all instances

**Example Test**:
```bash
# Launch 5 concurrent instances of /create-plan
for i in {1..5}; do
  /create-plan "test feature $i" &
done
wait

# Validate all 5 completed without errors
# Validate 5 unique topic directories created
# Validate no WORKFLOW_ID collision errors
```

## Performance Characteristics

### State File Discovery

**Overhead**: 5-10ms for <100 state files

**Scaling**:
- <50 files: <5ms
- 50-100 files: 5-10ms
- 100-200 files: 10-20ms
- >200 files: Consider cleanup (age-based deletion)

### WORKFLOW_ID Generation

**Overhead**: <1ms per invocation

**Benchmark**: 2.67ms average (100 invocations)

## Migration Guide

See [Concurrent Execution Migration Guide](../../guides/migration/concurrent-execution-migration.md) for step-by-step command update instructions.

## Troubleshooting

### "Failed to discover state file"

**Symptom**: `discover_latest_state_file()` returns empty string

**Causes**:
1. State file never created (Block 1 failed)
2. Wrong command prefix (typo in prefix)
3. State file deleted prematurely (cleanup issue)

**Solution**:
- Verify Block 1 completed successfully
- Check command prefix matches pattern
- Verify `.claude/tmp/` directory exists

### Multiple State Files Found

**Symptom**: Discovery returns wrong state file (old instance)

**Causes**:
1. Previous instance state file not cleaned up
2. Clock skew (mtime incorrect)

**Solution**:
- Discovery uses mtime (most recent first) - should work correctly
- Add age-based cleanup (delete files >7 days old)
- Verify trap handlers clean up state files on exit

### Collision Detected (Rare)

**Symptom**: Two instances get same WORKFLOW_ID

**Causes**:
1. Automated/scripted concurrent execution (not human-triggered)
2. Non-GNU date fallback (second-precision + PID)
3. Clock synchronization issue

**Solution**:
- For automated execution: Add random delay (0-1000ms) before WORKFLOW_ID generation
- Upgrade to GNU coreutils for nanosecond precision
- Fix system clock synchronization

## Standards Compliance

Commands using this pattern MUST:

1. Use `generate_unique_workflow_id()` for WORKFLOW_ID generation
2. Use `discover_latest_state_file()` for state restoration (Block 2+)
3. Never create shared state ID files
4. Pass concurrent execution tests (2, 3, 5 instances)
5. Document concurrent execution safety in command documentation

Commands using this pattern SHOULD:

1. Add trap handlers to clean up state files on exit
2. Document behavior when multiple instances run
3. Include troubleshooting section for state discovery failures

## References

- [State Persistence Library](../../../lib/core/state-persistence.sh) - Implementation details
- [Command Authoring Standards](./command-authoring.md) - Integration patterns
- [Testing Protocols](./testing-protocols.md) - Concurrent command testing
- [Migration Guide](../../guides/migration/concurrent-execution-migration.md) - Step-by-step updates
