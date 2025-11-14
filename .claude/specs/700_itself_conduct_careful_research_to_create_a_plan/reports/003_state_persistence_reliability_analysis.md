# State File Persistence and Recovery Failures - Root Cause Analysis

## Metadata
- **Date**: 2025-11-13
- **Agent**: research-specialist
- **Topic**: State file persistence and coordinate_state_id.txt file creation/recovery failures
- **Report Type**: codebase analysis
- **Complexity Level**: 4

## Executive Summary

The state persistence failures in `/coordinate` stem from a **path inconsistency** between where the state ID file is created (`${HOME}/.claude/tmp/`) and where the workflow state file is created (`${CLAUDE_PROJECT_DIR}/.claude/tmp/`). When `$HOME` differs from `$CLAUDE_PROJECT_DIR` (as in this system where `HOME=/home/benjamin` and `CLAUDE_PROJECT_DIR=/home/benjamin/.config`), subsequent bash blocks fail to locate the state ID file, resulting in a workflow ID mismatch (917810 vs coordinate_1763061699) and critical state loss. The subprocess isolation model exacerbates this by preventing environment variable persistence across bash blocks, making file-based state management the only viable approach but requiring absolute consistency in path resolution.

## Findings

### 1. Root Cause: Path Inconsistency Between State Files

**Primary Issue**: Two different base paths used for temp file storage

**Evidence**:
- **State ID file location** (coordinate.md:148): `COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"`
- **Workflow state file location** (state-persistence.sh:129): `STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"`

**Actual paths in this system**:
```bash
HOME=/home/benjamin
CLAUDE_PROJECT_DIR=/home/benjamin/.config

State ID file: /home/benjamin/.claude/tmp/coordinate_state_id.txt
Workflow state: /home/benjamin/.config/.claude/tmp/workflow_coordinate_1763061699.sh
```

**Failure mechanism** (coordinage_implement.md:145-161):
1. Block 1: State ID file created successfully at `${HOME}/.claude/tmp/coordinate_state_id.txt`
2. Block 1: Workflow state file created at `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_coordinate_1763061699.sh`
3. Block 2: Attempts to read state ID from `${HOME}/.claude/tmp/coordinate_state_id.txt`
4. Block 2: File not found (doesn't exist in Block 2's bash subprocess)
5. Block 2: Falls back to generating workflow ID `917810` (using `$$` which is different PID)
6. Block 2: Attempts to load `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_917810.sh`
7. Block 2: State file not found → CRITICAL ERROR

### 2. Subprocess Isolation Constraints

**Architectural constraint** (bash-block-execution-model.md:1-50):
- Each bash block runs as **separate subprocess** (not subshell)
- Process ID (`$$`) changes between blocks (12345 → 12346)
- All environment variables reset (exports lost)
- All bash functions lost (must re-source libraries)
- **Only files written to disk persist across blocks**

**Impact on state persistence**:
- Environment variables like `COORDINATE_STATE_ID_FILE` do NOT persist
- Each bash block re-initializes `COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"` independently
- File-based state is the ONLY communication channel between blocks

**Validation** (bash-block-execution-model.md:74-100):
```bash
# Block 1: PID = 12345, creates file
echo "$$" > /tmp/pid_block_1.txt

# Block 2: PID = 12346, different process
echo "$$" > /tmp/pid_block_2.txt

PID1 != PID2  # ✓ CONFIRMED: Separate subprocesses
```

### 3. Pattern Analysis: Fixed Semantic Filename Pattern

**Recommended pattern** (bash-block-execution-model.md:163-191):
- Use fixed, semantically meaningful filenames (not `$$`-based)
- Save workflow ID to fixed location file: `coordinate_state_id.txt`
- Subsequent blocks read workflow ID from fixed file

**Current implementation** (coordinate.md:146-149):
```bash
# Block 1: Generate and save workflow ID
WORKFLOW_ID="coordinate_$(date +%s)"
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"
```

**Pattern compliance**: ✓ Uses fixed semantic filename
**Path consistency**: ✗ Uses `${HOME}` instead of `${CLAUDE_PROJECT_DIR}`

### 4. State Persistence Library Implementation

**init_workflow_state function** (state-persistence.sh:115-142):
```bash
init_workflow_state() {
  local workflow_id="${1:-$$}"

  # Detect CLAUDE_PROJECT_DIR
  if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    export CLAUDE_PROJECT_DIR
  fi

  # Create state file in CLAUDE_PROJECT_DIR
  mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/tmp"
  STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"

  cat > "$STATE_FILE" <<EOF
export CLAUDE_PROJECT_DIR="$CLAUDE_PROJECT_DIR"
export WORKFLOW_ID="$workflow_id"
export STATE_FILE="$STATE_FILE"
EOF

  echo "$STATE_FILE"
}
```

**Key observation**: Library consistently uses `${CLAUDE_PROJECT_DIR}` for state file location

**load_workflow_state function** (state-persistence.sh:185-227):
```bash
load_workflow_state() {
  local workflow_id="${1:-$$}"
  local is_first_block="${2:-false}"
  local state_file="${CLAUDE_PROJECT_DIR:-$HOME}/.claude/tmp/workflow_${workflow_id}.sh"

  if [ -f "$state_file" ]; then
    source "$state_file"
    return 0
  else
    if [ "$is_first_block" = "true" ]; then
      # Expected: Initialize gracefully
      init_workflow_state "$workflow_id" >/dev/null
      return 1
    else
      # CRITICAL ERROR: State file should exist but doesn't
      echo "❌ CRITICAL ERROR: Workflow state file not found" >&2
      # ... diagnostic output ...
      return 2
    fi
  fi
}
```

**Fallback behavior**: Uses `${CLAUDE_PROJECT_DIR:-$HOME}` (defaults to HOME if CLAUDE_PROJECT_DIR unset)

### 5. Recovery Mechanism Success

**Successful recovery** (coordinage_implement.md:196-203):
```bash
# Manual recovery by hardcoding known workflow ID
WORKFLOW_ID="coordinate_1763061699"  # From initialization block output
load_workflow_state "$WORKFLOW_ID"

# State successfully restored:
#   Workflow ID: coordinate_1763061699
#   Workflow Scope: full-implementation
```

**Why recovery worked**:
1. Bypassed failed state ID file read
2. Used known workflow ID directly
3. Loaded state file from correct location (`${CLAUDE_PROJECT_DIR}/.claude/tmp/`)

**Lesson**: State file itself is reliable once correct workflow ID is known; the failure is in the ID file discovery mechanism

### 6. Verification Checkpoint Analysis

**Verification implementation** (coordinate.md:151-154):
```bash
verify_file_created "$COORDINATE_STATE_ID_FILE" "State ID file" "Initialization" || {
  handle_state_error "CRITICAL: State ID file not created at $COORDINATE_STATE_ID_FILE" 1
}
```

**Verification function** (verification-helpers.sh:73-100):
- Checks file exists: `[ -f "$file_path" ]`
- Checks file non-empty: `[ -s "$file_path" ]`
- Returns 0 on success, 1 on failure

**Checkpoint passed in Block 1**: File was created successfully at `${HOME}/.claude/tmp/`
**Problem**: Verification doesn't detect path inconsistency with downstream state file usage

### 7. Error Pattern Timeline

**Initialization block (Block 1)** (coordinage_implement.md:91-96):
```
STATE_FILE=/home/benjamin/.config/.claude/tmp/workflow_coordinate_1763061699.sh
WORKFLOW_ID=coordinate_1763061699
```
✓ Success: State file created at CLAUDE_PROJECT_DIR location

**Research phase block (Block 2)** (coordinage_implement.md:145-161):
```
cat: /home/benjamin/.claude/tmp/coordinate_state_id.txt: No such file or directory
Expected state file: /home/benjamin/.config/.claude/tmp/workflow_917810.sh
Workflow ID: 917810
```
✗ Failure: State ID file not found, generated new workflow ID using $$

**Root cause chain**:
1. State ID file created at `${HOME}/.claude/tmp/` (not accessible in Block 2 subprocess)
2. State ID file read fails in Block 2
3. Fallback generates new workflow ID using $$ (different PID = 917810)
4. Attempts to load non-existent workflow_917810.sh
5. Critical error: "Workflow state file not found"

### 8. Directory Structure Observations

**HOME/.claude/tmp contents** (verified 2025-11-13):
```
/home/benjamin/.claude/tmp/coordinate_state_id.txt (22 bytes)
/home/benjamin/.claude/tmp/coordinate_workflow_desc_*.txt (18 files)
```
- Workflow description files accumulate (no cleanup)
- State ID file present and current

**CLAUDE_PROJECT_DIR/.claude/tmp contents**:
```
/home/benjamin/.config/.claude/tmp/workflow_coordinate_1763063015.sh (1036 bytes)
/home/benjamin/.config/.claude/tmp/workflow_test_*.sh (numerous test files)
```
- Workflow state files present
- Test state files from test suite runs

**Key insight**: Two separate `.claude/tmp/` directories exist simultaneously, causing state file fragmentation

## Recommendations

### 1. Standardize on CLAUDE_PROJECT_DIR for All Temp Files (CRITICAL)

**Problem**: Mixing `${HOME}` and `${CLAUDE_PROJECT_DIR}` creates unreliable state discovery

**Solution**: Use `${CLAUDE_PROJECT_DIR}/.claude/tmp/` consistently for all workflow temp files

**Implementation**:
```bash
# coordinate.md:148 - CHANGE FROM:
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"

# TO:
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
```

**Also update**: All bash blocks that reference this file (lines 392, 657, 950, 1112, etc.)

**Rationale**:
- Matches state-persistence.sh pattern (uses CLAUDE_PROJECT_DIR)
- Ensures state ID file and workflow state file in same directory tree
- Eliminates HOME vs CLAUDE_PROJECT_DIR ambiguity
- Works correctly when HOME != CLAUDE_PROJECT_DIR (as in this system)

### 2. Detect CLAUDE_PROJECT_DIR Before Creating State ID File (CRITICAL)

**Problem**: State ID file created before CLAUDE_PROJECT_DIR is detected

**Solution**: Initialize CLAUDE_PROJECT_DIR at very start of Part 2 (before line 148)

**Implementation** (coordinate.md after line 60):
```bash
# Standard 13: CLAUDE_PROJECT_DIR detection (MOVED TO TOP)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# NOW create state ID file using CLAUDE_PROJECT_DIR
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
```

**Current code**: CLAUDE_PROJECT_DIR detection happens at line 62 (AFTER state ID file path is set)
**Fixed code**: Detection happens BEFORE state ID file path construction

### 3. Add Path Consistency Verification Checkpoint (HIGH PRIORITY)

**Problem**: Verification confirms file created but doesn't check path consistency

**Solution**: Add diagnostic verification after state ID file creation

**Implementation** (coordinate.md after line 154):
```bash
# VERIFICATION CHECKPOINT: State ID file path consistency
if [[ "$COORDINATE_STATE_ID_FILE" != "${CLAUDE_PROJECT_DIR}/.claude/tmp/"* ]]; then
  echo "WARNING: State ID file path inconsistency detected" >&2
  echo "  State ID file: $COORDINATE_STATE_ID_FILE" >&2
  echo "  Expected prefix: ${CLAUDE_PROJECT_DIR}/.claude/tmp/" >&2
  echo "  This may cause state recovery failures in subsequent blocks" >&2
  handle_state_error "State ID file path must use CLAUDE_PROJECT_DIR" 1
fi
```

**Benefit**: Fail-fast detection of path inconsistency before workflow proceeds

### 4. Update Workflow Description File Handling (MEDIUM PRIORITY)

**Problem**: Workflow description files also use `${HOME}/.claude/tmp/` creating fragmentation

**Solution**: Migrate workflow description temp files to CLAUDE_PROJECT_DIR

**Implementation** (coordinate.md:36-41):
```bash
# CHANGE FROM:
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
WORKFLOW_TEMP_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc_$(date +%s%N).txt"
echo "$WORKFLOW_TEMP_FILE" > "${HOME}/.claude/tmp/coordinate_workflow_desc_path.txt"

# TO:
# Detect CLAUDE_PROJECT_DIR early (Part 1)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/tmp" 2>/dev/null || true
WORKFLOW_TEMP_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_workflow_desc_$(date +%s%N).txt"
echo "$WORKFLOW_TEMP_FILE" > "${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_workflow_desc_path.txt"
```

**Also update**: Lines 69-75 to use CLAUDE_PROJECT_DIR

### 5. Document Path Resolution Standard (MEDIUM PRIORITY)

**Problem**: No explicit standard for temp file base paths

**Solution**: Document in CLAUDE.md and bash-block-execution-model.md

**Content addition** (CLAUDE.md testing_protocols section):
```markdown
### Temp File Path Standards
[Used by: all orchestration commands]

**Standard**: All workflow temp files MUST use `${CLAUDE_PROJECT_DIR}/.claude/tmp/` as base path

**Rationale**:
- Subprocess isolation requires file-based state persistence
- State files must be accessible across bash blocks
- HOME may differ from CLAUDE_PROJECT_DIR (e.g., ~/.config setups)
- Consistency prevents state discovery failures

**Prohibited patterns**:
- `${HOME}/.claude/tmp/` for workflow state (may differ from project location)
- `/tmp/workflow_$$.sh` (PID changes across subprocess boundaries)
- Relative paths `../tmp/state.sh` (working directory may change)

**Example**:
```bash
# ✓ CORRECT
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"

# ✗ WRONG
STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
STATE_ID_FILE="/tmp/state_$$.txt"
```
```

### 6. Implement Cleanup Mechanism for Orphaned Temp Files (LOW PRIORITY)

**Problem**: Workflow description files accumulate (18 files observed)

**Solution**: Add cleanup logic to remove files older than 24 hours

**Implementation** (new utility script):
```bash
#!/usr/bin/env bash
# .claude/lib/cleanup-temp-files.sh
# Remove workflow temp files older than 24 hours

TEMP_DIR="${CLAUDE_PROJECT_DIR}/.claude/tmp"

# Remove old workflow description files
find "$TEMP_DIR" -name "coordinate_workflow_desc_*.txt" -mtime +1 -delete

# Remove old workflow state files (but not current workflow)
current_state_id=$(cat "${TEMP_DIR}/coordinate_state_id.txt" 2>/dev/null || echo "")
find "$TEMP_DIR" -name "workflow_coordinate_*.sh" -mtime +1 | while read -r file; do
  if [[ ! "$file" =~ $current_state_id ]]; then
    rm -f "$file"
  fi
done
```

**Integration**: Call from coordinate.md initialization or EXIT trap

### 7. Enhance load_workflow_state Diagnostics (LOW PRIORITY)

**Problem**: Error message doesn't mention state ID file location

**Solution**: Add state ID file path to diagnostic output

**Implementation** (state-persistence.sh:215-220):
```bash
echo "TROUBLESHOOTING:" >&2
echo "  1. Check if first bash block called init_workflow_state()" >&2
echo "  2. Verify state ID file exists: ${COORDINATE_STATE_ID_FILE:-${HOME}/.claude/tmp/coordinate_state_id.txt}" >&2
echo "  3. Verify state ID file path uses CLAUDE_PROJECT_DIR: ${CLAUDE_PROJECT_DIR}/.claude/tmp/" >&2
echo "  4. Check tmp directory permissions: ls -la ${CLAUDE_PROJECT_DIR:-$HOME}/.claude/tmp/" >&2
```

**Benefit**: Faster root cause identification during debugging

## References

### Primary Code Locations
- `/home/benjamin/.config/.claude/commands/coordinate.md:148-161` - State ID file creation and verification
- `/home/benjamin/.config/.claude/commands/coordinate.md:392-400` - State ID file loading (Block 2)
- `/home/benjamin/.config/.claude/lib/state-persistence.sh:115-142` - init_workflow_state function
- `/home/benjamin/.config/.claude/lib/state-persistence.sh:185-227` - load_workflow_state function
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh:73-100` - verify_file_created function

### Documentation
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:1-50` - Subprocess isolation architecture
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:163-191` - Fixed semantic filename pattern
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:199-224` - Save-before-source pattern

### Error Instances
- `/home/benjamin/.config/.claude/specs/coordinage_implement.md:145-161` - State file not found error (Block 2)
- `/home/benjamin/.config/.claude/specs/coordinage_implement.md:183-192` - State ID file path verification
- `/home/benjamin/.config/.claude/specs/coordinage_implement.md:196-203` - Successful manual recovery

### System Paths
- State ID file (created): `/home/benjamin/.claude/tmp/coordinate_state_id.txt`
- State ID file (expected): `/home/benjamin/.config/.claude/tmp/coordinate_state_id.txt`
- Workflow state file: `/home/benjamin/.config/.claude/tmp/workflow_coordinate_1763061699.sh`
- Failed lookup: `/home/benjamin/.config/.claude/tmp/workflow_917810.sh`

## Appendix: Test Case for Validation

```bash
#!/usr/bin/env bash
# Test case: Verify state ID file path consistency

# Setup
export CLAUDE_PROJECT_DIR="/home/benjamin/.config"
export HOME="/home/benjamin"

# Simulate Block 1 (OLD CODE)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
echo "test_workflow_123" > "$COORDINATE_STATE_ID_FILE"

# Simulate Block 2 (tries to load from HOME location)
if [ -f "${HOME}/.claude/tmp/coordinate_state_id.txt" ]; then
  WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
  STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
  echo "✓ Old code: Found state ID at HOME location"
  echo "  But state file is at: $STATE_FILE"
else
  echo "✗ Old code: State ID file not found (subprocess isolation)"
fi

# Simulate Block 1 (NEW CODE - FIXED)
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/tmp"
echo "test_workflow_456" > "$COORDINATE_STATE_ID_FILE"

# Simulate Block 2 (loads from CLAUDE_PROJECT_DIR location)
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt" ]; then
  WORKFLOW_ID=$(cat "${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt")
  STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
  echo "✓ New code: Found state ID at CLAUDE_PROJECT_DIR location"
  echo "  State file location: $STATE_FILE"
  echo "  Path consistency: VERIFIED"
else
  echo "✗ New code: State ID file not found (should not happen)"
fi
```

**Expected output**:
```
✓ Old code: Found state ID at HOME location
  But state file is at: /home/benjamin/.config/.claude/tmp/workflow_test_workflow_123.sh
✓ New code: Found state ID at CLAUDE_PROJECT_DIR location
  State file location: /home/benjamin/.config/.claude/tmp/workflow_test_workflow_456.sh
  Path consistency: VERIFIED
```
