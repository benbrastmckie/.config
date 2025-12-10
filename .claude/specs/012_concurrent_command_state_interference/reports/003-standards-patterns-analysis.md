# Standards and Patterns Analysis for Concurrent-Safe Commands

**Research Date**: 2025-12-10
**Topic**: Standards and patterns for concurrent-safe commands
**Status**: IN PROGRESS

## Research Objective

Research existing patterns and propose new standards for command isolation and concurrent execution safety in the .claude/ system.

## Initial Research Steps

1. Analyze existing standards documentation in .claude/docs/reference/standards/
2. Review state-persistence.sh implementation patterns
3. Examine command-authoring.md for current guidance
4. Analyze concrete failure examples from create-plan-output files
5. Identify gaps and propose new standards

## Research Findings

### 1. Current State Management Architecture

#### State Persistence Library (`state-persistence.sh`)

**Location**: `.claude/lib/core/state-persistence.sh` (v1.6.0, ~1041 lines)

**Key Functions**:
- `init_workflow_state(workflow_id)` - Creates state file in `.claude/tmp/workflow_${workflow_id}.sh`
- `load_workflow_state(workflow_id)` - Sources state file to restore variables
- `append_workflow_state(key, value)` - Appends bash export statements
- `validate_state_file_path()` - Validates STATE_FILE path consistency

**State File Pattern**:
```bash
# State files created at:
${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh

# Content format (bash-sourceable):
export CLAUDE_PROJECT_DIR="/path/to/project"
export WORKFLOW_ID="command_timestamp"
export STATE_FILE="/path/to/state/file.sh"
```

**Critical Issues Identified**:

1. **WORKFLOW_ID Persistence Pattern** (Lines 426-437 in state-persistence.sh):
   - Commands save WORKFLOW_ID to **shared singleton file**: `${HOME}/.claude/tmp/command_state_id.txt`
   - No command-specific namespacing
   - Last writer wins - concurrent commands overwrite each other's IDs
   - Example from `/create-plan` output line 83-84:
     ```
     cat /home/benjamin/.config/.claude/tmp/plan_state_id.txt
     plan_1765352804  # Different ID than expected plan_1765352600
     ```

2. **State File Path Construction** (Lines 12-25, 318):
   - State files always use pattern: `.claude/tmp/workflow_${WORKFLOW_ID}.sh`
   - If WORKFLOW_ID is overwritten, subsequent blocks look for wrong state file
   - From `/create-plan` output line 209: `ERROR: Failed to restore WORKFLOW_ID`

3. **No Isolation Mechanism**:
   - No file locking on state files
   - No collision detection between concurrent commands
   - No unique temp directory per command invocation

#### Current Workflow ID Allocation Pattern

**From command-authoring.md** (Lines 426-437):
```bash
# Block 1: Save ID
WORKFLOW_ID="workflow_$(date +%s)"
echo "$WORKFLOW_ID" > "${HOME}/.claude/tmp/workflow_state_id.txt"

# Block 2: Load ID
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/workflow_state_id.txt")
```

**Problem**: All commands use same singleton file name pattern:
- `/create-plan` uses: `plan_state_id.txt`
- `/research` uses: `research_state_id.txt`
- `/implement` uses: `implement_state_id.txt`

But when multiple instances of **same command** run concurrently (e.g., two `/create-plan`), they share the **same state ID file**.

### 2. Concrete Failure Analysis

#### Evidence from Output Files

**Failure Scenario 1**: `/create-plan` output (lines 73-89)
```
● Bash(set +H  # CRITICAL: Disable history expansion…)
  ⎿  Error: Exit code 1
     ERROR: Failed to restore WORKFLOW_ID

● Bash(cat /home/benjamin/.config/.claude/tmp/plan_state_id.txt)
  ⎿ plan_1765352804  # WRONG ID - this was from another /create-plan
    -rw-r--r-- 1 benjamin users 16 Dec  9 23:46 plan_state_id.txt
```

**Timeline Reconstruction**:
1. Command A: Block 1 writes `plan_1765352600` to `plan_state_id.txt`
2. Command B: Block 1 writes `plan_1765352804` to `plan_state_id.txt` (overwrites A)
3. Command A: Block 2 reads `plan_1765352804` (wrong ID!)
4. Command A: Looks for `workflow_plan_1765352804.sh` (doesn't exist)
5. Command A: Fails with "Failed to restore WORKFLOW_ID"

**Failure Scenario 2**: `/create-plan` output-2 (lines 164-221)
- Similar pattern with state ID changing from `plan_1765352571` to `plan_1765352600`
- Topic naming agent succeeded, but state was lost due to ID file overwrite
- Fallback to `no_name_error` directory due to corrupted state

#### Error Classification

**Error Type**: `state_error` - State persistence failure
**Severity**: P0 - Blocks workflow execution
**Frequency**: Occurs whenever 2+ instances of same command run concurrently
**Impact**:
- Workflow cannot complete
- User sees "Failed to restore WORKFLOW_ID"
- Artifacts may be partially created or orphaned

### 3. Existing Standards Gap Analysis

#### Command Authoring Standards (`command-authoring.md`)

**Current Coverage**:
- ✅ Subprocess isolation (line 346-407)
- ✅ State persistence patterns (line 409-543)
- ✅ Path validation patterns (line 954-1041)
- ❌ **NO concurrent execution safety guidance**
- ❌ **NO command isolation requirements**
- ❌ **NO state file collision prevention**

**Relevant Sections**:
1. **State Persistence Patterns** (lines 409-543):
   - Documents current pattern using shared state ID files
   - No warnings about concurrent execution issues
   - No isolation requirements

2. **Path Validation Patterns** (lines 954-1041):
   - Validates PROJECT_DIR vs HOME consistency
   - Doesn't address concurrent command path conflicts

3. **Argument Capture Patterns** (lines 640-774):
   - Documents timestamp-based temp file pattern for argument capture
   - **Good pattern**: Uses `$(date +%s%N)` for nanosecond-level uniqueness
   - But not applied to state ID files

#### State Persistence Library Documentation

**Current Documentation** (Lines 1-126 in state-persistence.sh):
- Documents GitHub Actions-style state pattern
- Describes performance characteristics
- Lists decision criteria for file-based state
- **Missing**: Concurrent execution considerations
- **Missing**: Command isolation requirements
- **Missing**: State file collision scenarios

#### Testing Standards

**Test Isolation Standard** (`.claude/docs/reference/standards/test-isolation.md`):
- Covers test-specific isolation
- Does NOT cover command-level isolation
- Does NOT address concurrent command execution

### 4. Related System Patterns

#### Positive Pattern: Argument Capture Timestamp Safety

**From command-authoring.md** (lines 769-773):
```bash
# Concurrent execution safety for temp files
TEMP_FILE="${HOME}/.claude/tmp/command_$(date +%s%N).txt"
```

**Key Feature**: Nanosecond-precision timestamp prevents collisions

**Why This Works**:
- `date +%s%N` provides nanosecond precision (e.g., 1765352600123456789)
- Extremely unlikely collision even with concurrent invocations
- No shared state between commands

#### Parallel Execution Pattern: Research Coordinator

**From hierarchical-agents-examples.md** (Example 7):
- Research coordinator invokes multiple research-specialist agents in parallel
- Each agent writes to pre-calculated unique path
- Hard barrier pattern prevents coordinator from proceeding until all reports exist
- **Key Insight**: Pre-calculation of unique paths prevents conflicts

**Pattern Structure**:
1. Coordinator calculates N unique report paths (before parallel execution)
2. Passes unique path to each specialist agent
3. Each specialist writes to its own path (no collision risk)
4. Hard barrier validates all N reports exist

**Relevance**: Shows successful parallel agent execution without state interference

### 5. Proposed Solutions Analysis

#### Solution A: Process-Unique State ID Files

**Approach**: Include process PID in state ID filename

**Pattern**:
```bash
# Current (collision-prone):
STATE_ID_FILE="${HOME}/.claude/tmp/plan_state_id.txt"

# Proposed (collision-safe):
STATE_ID_FILE="${HOME}/.claude/tmp/plan_state_id_$$.txt"
```

**Pros**:
- Simple change (1-2 line modification per command)
- No shared state between concurrent invocations
- Works with existing subprocess isolation model

**Cons**:
- Each bash block has different `$$` (separate subprocess)
- Would need to use WORKFLOW_ID in filename instead
- Requires state ID to be known before creating state ID file (chicken-egg problem)

#### Solution B: Atomic State File Creation

**Approach**: Use `mktemp` for unique state file allocation

**Pattern**:
```bash
# Block 1: Atomic unique state file creation
STATE_FILE=$(mktemp "${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_plan_XXXXXX.sh")
WORKFLOW_ID=$(basename "$STATE_FILE" .sh | sed 's/workflow_//')

# Store WORKFLOW_ID in unique location
echo "$WORKFLOW_ID" > "${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id_${WORKFLOW_ID}.txt"
```

**Pros**:
- Atomic allocation via `mktemp` (kernel-level uniqueness guarantee)
- No collision risk
- WORKFLOW_ID derived from state file (single source of truth)

**Cons**:
- Changes WORKFLOW_ID format (from `plan_timestamp` to `plan_XXXXXX`)
- May break existing tooling that expects timestamp format
- Requires updates to all commands

#### Solution C: Command-Instance Namespacing

**Approach**: Add instance counter to state ID file pattern

**Pattern**:
```bash
# Block 1: Atomic instance allocation
INSTANCE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_instances.txt"
(
  flock -x 200  # Exclusive lock
  INSTANCE=$(($(cat "$INSTANCE_FILE" 2>/dev/null || echo 0) + 1))
  echo "$INSTANCE" > "$INSTANCE_FILE"
  echo "$INSTANCE"
) 200>"${INSTANCE_FILE}.lock"

WORKFLOW_ID="plan_$(date +%s)_${INSTANCE}"
STATE_ID_FILE="${HOME}/.claude/tmp/plan_state_id_${INSTANCE}.txt"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"
```

**Pros**:
- Preserves timestamp in WORKFLOW_ID
- Explicit instance tracking
- File locking prevents race conditions

**Cons**:
- Complex implementation (flock, instance counter maintenance)
- Requires cleanup of stale instance files
- May not be portable (flock availability)

#### Solution D: Nanosecond-Precision State ID Files

**Approach**: Use nanosecond timestamp in state ID filename (like argument capture pattern)

**Pattern**:
```bash
# Block 1: Nanosecond-precision WORKFLOW_ID
WORKFLOW_ID="plan_$(date +%s%N)"
STATE_ID_FILE="${HOME}/.claude/tmp/plan_state_id_${WORKFLOW_ID}.txt"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"

# Block 2+: Load from unique state ID file
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/plan_state_id_${WORKFLOW_ID}.txt")
# Problem: WORKFLOW_ID not known yet in Block 2!
```

**Fatal Flaw**: Chicken-egg problem
- Block 2 needs WORKFLOW_ID to construct state ID file path
- But WORKFLOW_ID is stored IN the state ID file
- Cannot read file without knowing ID, cannot know ID without reading file

**Resolution**: Store WORKFLOW_ID in **two places**:
1. In unique state ID file (for recovery/debugging)
2. In state file itself (read once, persist across blocks)

### 6. Recommended Solution

#### Hybrid Approach: Nanosecond-Precision + State File Self-Containment

**Core Principles**:
1. **Unique allocation**: Use `date +%s%N` for nanosecond-precision WORKFLOW_ID
2. **Self-contained state**: State file is **only** source of WORKFLOW_ID after Block 1
3. **No singleton files**: Eliminate shared state ID files entirely
4. **Backward compatible**: Minimal changes to command structure

**Implementation Pattern**:

```bash
# === Block 1: State Initialization ===
set +H

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1

# Generate unique WORKFLOW_ID with nanosecond precision
WORKFLOW_ID="plan_$(date +%s%N)"

# Create state file (no singleton state ID file needed)
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
append_workflow_state "COMMAND_NAME" "create-plan"
append_workflow_state "USER_ARGS" "$*"

# Store state file path for discovery by subsequent blocks
# Use nanosecond-precision filename to prevent collision
DISCOVERY_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/.plan_discovery_$(date +%s%N).txt"
echo "$STATE_FILE" > "$DISCOVERY_FILE"
trap "rm -f '$STATE_FILE' '$DISCOVERY_FILE'" EXIT

echo "Workflow initialized: $WORKFLOW_ID"
echo "State file: $STATE_FILE"
```

```bash
# === Block 2+: State Restoration ===
set +H

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1

# Discover latest state file (sorted by mtime)
STATE_FILE=$(find "${CLAUDE_PROJECT_DIR}/.claude/tmp" -name "workflow_plan_*.sh" \
  -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: No state file found for plan command" >&2
  exit 1
fi

# Load state (WORKFLOW_ID restored from state file)
source "$STATE_FILE"

# Validate critical variables
if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: WORKFLOW_ID not found in state file" >&2
  exit 1
fi

echo "State restored: $WORKFLOW_ID"
```

**Key Changes**:
1. **No state ID files**: Eliminated `plan_state_id.txt` entirely
2. **State file discovery**: Subsequent blocks discover state file by pattern + mtime
3. **Nanosecond precision**: WORKFLOW_ID uses `%N` suffix for uniqueness
4. **Self-contained**: All state in single state file (no external lookups)

**Collision Prevention**:
- Nanosecond-precision WORKFLOW_ID: 1-billion unique IDs per second
- State file name includes unique ID: `.claude/tmp/workflow_plan_1765352600123456789.sh`
- No shared singleton files between concurrent invocations

**Backward Compatibility**:
- State file format unchanged (still bash-sourceable exports)
- State file location unchanged (`.claude/tmp/`)
- WORKFLOW_ID format extended (timestamp → timestamp with nanoseconds)

**Limitations**:
- Assumes concurrent commands execute >1ns apart (extremely safe assumption)
- Relies on `date +%s%N` availability (GNU coreutils requirement)
- Discovery by mtime may select wrong file if system clock skews backward

### 7. Standards Documentation Gaps

#### Missing Standards

**1. Concurrent Command Execution Safety Standard**

Should document:
- WORKFLOW_ID uniqueness requirements
- State file collision prevention patterns
- Discovery mechanisms for subsequent blocks
- Testing requirements for concurrent execution

**2. Command Isolation Requirements**

Should document:
- No shared singleton state files
- Unique temp file naming conventions
- Process-specific resource allocation
- Cleanup and orphaned resource prevention

**3. State Persistence Anti-Patterns**

Should document:
- ❌ Shared state ID files (current pattern)
- ❌ Timestamp-only WORKFLOW_ID (second-precision insufficient)
- ❌ Global state files modified by multiple commands
- ✅ Nanosecond-precision unique identifiers
- ✅ Self-contained state files with discovery mechanism

#### Documentation Update Locations

**1. Command Authoring Standards** (`.claude/docs/reference/standards/command-authoring.md`)

Add new section:
```markdown
## Concurrent Execution Safety

Commands MUST support concurrent execution without state interference.

### WORKFLOW_ID Uniqueness
- Use nanosecond-precision timestamps: `command_$(date +%s%N)`
- No shared state ID files between concurrent invocations

### State File Isolation
- State files MUST be uniquely named per invocation
- Subsequent blocks MUST discover state file (not rely on singleton lookup)
- Pattern: `.claude/tmp/workflow_${WORKFLOW_ID}.sh`

### Prohibited Patterns
❌ Shared state ID files: `${HOME}/.claude/tmp/command_state_id.txt`
❌ Second-precision WORKFLOW_ID: `command_$(date +%s)`
❌ Global lockfiles for serialization (defeats parallelization)
```

**2. State Persistence Library** (`.claude/lib/core/state-persistence.sh`)

Update header documentation (lines 1-126):
```bash
# Concurrent Execution Safety:
# - WORKFLOW_ID MUST use nanosecond precision: command_$(date +%s%N)
# - State files are uniquely named per invocation
# - No shared state ID files (singleton pattern removed)
# - Subsequent blocks discover state file via pattern matching + mtime
```

**3. Testing Standards** (`.claude/docs/reference/standards/testing-protocols.md`)

Add section:
```markdown
## Concurrent Command Testing

Commands MUST include tests for concurrent execution safety:

1. **State Isolation Test**: Launch 2+ instances simultaneously, verify no WORKFLOW_ID collision
2. **File System Race Test**: Verify state file creation/discovery under concurrent load
3. **Cleanup Test**: Verify no orphaned state files after concurrent execution
```

### 8. Migration Strategy

#### Phase 1: Update State Persistence Library (Low Risk)

**Changes**:
1. Add `discover_latest_state_file()` utility function
2. Add `generate_unique_workflow_id()` with nanosecond precision
3. Update documentation to discourage shared state ID files

**Backward Compatibility**: Existing commands continue working

#### Phase 2: Update High-Priority Commands (Medium Risk)

**Target Commands**:
- `/create-plan` (most affected by concurrent execution)
- `/research` (same issue as /create-plan)
- `/implement` (less critical but should be updated)

**Changes per Command**:
1. Replace `WORKFLOW_ID="command_$(date +%s)"` with `$(date +%s%N)`
2. Remove state ID file write/read logic
3. Add state file discovery in Block 2+
4. Update tests to verify concurrent execution

**Testing**:
- Concurrent execution test: Launch 5 instances of same command
- Verify all complete without state interference
- Check no orphaned state files remain

#### Phase 3: Document New Standards (Low Risk)

**Updates**:
1. command-authoring.md: Add "Concurrent Execution Safety" section
2. state-persistence.sh: Update header with isolation guidance
3. testing-protocols.md: Add concurrent execution test requirements
4. Add migration guide for existing commands

#### Phase 4: Deprecate Old Pattern (Low Risk)

**Actions**:
1. Add linter to detect shared state ID file pattern
2. Add WARNING when old pattern detected
3. Create automated migration script
4. Update all remaining commands

### 9. Testing Requirements

#### Unit Tests

**test_workflow_id_uniqueness.sh**:
```bash
# Launch 10 concurrent state initializations
# Verify all WORKFLOW_IDs are unique
# Verify no collisions in state file creation
```

**test_state_file_discovery.sh**:
```bash
# Create multiple state files with different timestamps
# Verify discovery mechanism selects correct file
# Test edge cases (missing files, corrupted files, empty directory)
```

#### Integration Tests

**test_concurrent_create_plan.sh**:
```bash
# Launch 3 concurrent /create-plan invocations
# Verify all complete successfully
# Verify no "Failed to restore WORKFLOW_ID" errors
# Verify 3 distinct topic directories created
```

**test_concurrent_research.sh**:
```bash
# Launch 2 concurrent /research invocations
# Verify both create reports independently
# Verify no state interference
```

#### Regression Tests

**test_backward_compatibility.sh**:
```bash
# Verify old timestamp-format WORKFLOW_IDs still load correctly
# Test state file migration scenario
# Verify no breaking changes to existing workflows
```

### 10. Performance Considerations

#### Nanosecond Timestamp Overhead

**Command**: `date +%s%N`
**Performance**: <1ms (negligible)
**Comparison**: `date +%s` also <1ms (no meaningful difference)

#### State File Discovery Overhead

**Command**: `find .claude/tmp -name "workflow_plan_*.sh" -printf '%T@ %p\n' | sort -rn | head -1`
**Performance**: ~5-10ms for <100 state files
**Mitigation**: State files cleaned up on command exit (trap handler)

**Scaling Concerns**:
- If `.claude/tmp/` accumulates thousands of state files, discovery may slow
- Solution: Periodic cleanup of state files >24h old
- Alternative: Use `.plan_discovery_*.txt` files instead of pattern matching

#### Collision Probability Analysis

**Current Pattern** (second-precision):
- Collision probability: 100% if 2 commands start within same second
- Realistic scenario: User launches 2 terminals, runs `/create-plan` in both

**Proposed Pattern** (nanosecond-precision):
- Collision probability: ~0% for human-triggered concurrent execution
- Requires 2 commands to start within 1 nanosecond (physically impossible for manual invocation)
- Even with automated concurrent launches, <1% collision risk

### 11. Rollout Risk Assessment

#### Low-Risk Changes
✅ Adding `discover_latest_state_file()` utility function (new function, no impact)
✅ Documentation updates (no code changes)
✅ Adding concurrent execution tests (new tests, no impact)

#### Medium-Risk Changes
⚠️ Changing WORKFLOW_ID format (`%s` → `%s%N`) - affects downstream parsing
⚠️ Removing state ID files - changes command structure significantly
⚠️ State file discovery logic - may select wrong file under edge cases

#### High-Risk Changes
❌ Bulk migration of all commands simultaneously - high regression risk
❌ Changing state file path format - breaks in-flight workflows

#### Recommended Rollout Strategy

**Stage 1**: Update `/create-plan` only
- Most affected by concurrent execution issue
- Test thoroughly before expanding to other commands
- Monitor for 1 week in production

**Stage 2**: Update `/research` and `/implement`
- Similar usage patterns to `/create-plan`
- Leverage learnings from Stage 1

**Stage 3**: Update remaining commands
- Lower priority (less concurrent usage)
- Automated migration script by this point

**Stage 4**: Deprecate old pattern
- Add linter enforcement
- Update all documentation

## Summary

### Root Cause
Concurrent commands share singleton state ID files (e.g., `plan_state_id.txt`), causing WORKFLOW_ID overwrites and state restoration failures.

### Impact
- Blocks workflow completion when 2+ instances of same command run simultaneously
- User sees "Failed to restore WORKFLOW_ID" errors
- Affects `/create-plan`, `/research`, and other commands using state persistence

### Recommended Solution
1. Use nanosecond-precision WORKFLOW_ID: `command_$(date +%s%N)`
2. Eliminate shared state ID files
3. Implement state file discovery mechanism for subsequent blocks
4. Update command-authoring.md with concurrent execution safety standards

### Migration Priority
- **P0**: Update `/create-plan` (highest user impact)
- **P1**: Update `/research` (same issue)
- **P2**: Update remaining commands
- **P3**: Add linter enforcement

### Documentation Gaps
- No concurrent execution safety guidance in command-authoring.md
- No isolation requirements in state-persistence.sh
- No concurrent execution tests in testing-protocols.md

### Next Steps
1. Create concurrent execution safety standard document
2. Implement nanosecond-precision WORKFLOW_ID in `/create-plan`
3. Add concurrent execution test suite
4. Document migration guide for remaining commands

