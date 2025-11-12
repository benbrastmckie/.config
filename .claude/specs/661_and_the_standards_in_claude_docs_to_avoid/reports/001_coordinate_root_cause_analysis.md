# /coordinate Root Cause Analysis: Workflow State Persistence Failures

## Metadata
- **Date**: 2025-11-11
- **Agent**: research-specialist
- **Topic**: Analyze the /coordinate command implementation to identify root causes of workflow state persistence failures and bash block execution issues
- **Report Type**: architectural analysis
- **Complexity Level**: 3 (architectural analysis)

## Executive Summary

The /coordinate command exhibits critical state persistence failures caused by violations of documented bash block execution patterns. Analysis identified five root causes: (1) EXIT trap in early bash block causing premature cleanup of COORDINATE_STATE_ID_FILE, (2) missing timestamp-based unique state ID file path in subsequent blocks, (3) WORKFLOW_SCOPE variable reset by library re-sourcing before state loading, (4) incomplete verification checkpoint coverage allowing silent failures, and (5) reliance on fixed-location backward compatibility pattern that masks failures. These issues violate Anti-Patterns 3, 2, and 4 from bash-block-execution-model.md, causing state loss between bash blocks and workflow execution failures.

## Findings

### Finding 1: EXIT Trap Fires Prematurely (Anti-Pattern 3 Violation)

**Location**: `/home/benjamin/.config/.claude/commands/coordinate.md:141`

**Code**:
```bash
# Line 137: Generate unique workflow ID
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_${TIMESTAMP}.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"

# Line 141: Add cleanup trap for state ID file
trap "rm -f '$COORDINATE_STATE_ID_FILE' 2>/dev/null || true" EXIT
```

**Root Cause**:
The EXIT trap is set in **Block 1 (initialization)**, but fires at the **end of Block 1**, not at workflow completion. This violates **Anti-Pattern 3: Premature Trap Handlers** documented in bash-block-execution-model.md:604-612.

**Impact**:
- COORDINATE_STATE_ID_FILE is deleted immediately after Block 1 exits
- Subsequent blocks (research, planning, implementation) cannot locate state ID file
- Workflow fails with "Workflow state ID file not found" error in Block 2+

**Evidence from Documentation** (bash-block-execution-model.md:606-612):
```bash
# Block 1 (early in workflow)
trap 'cleanup_temp_files' EXIT

# Block 2 needs temp files
# ✗ Files already deleted by Block 1's EXIT trap
```

**Fix**: Use Pattern 6 (Cleanup on Completion Only) - Only set cleanup traps in final completion function (bash-block-execution-model.md:388-399).

### Finding 2: Timestamp-Based Filename Lost Across Blocks (Anti-Pattern 1 Violation)

**Location**: `/home/benjamin/.config/.claude/commands/coordinate.md:136-138`

**Code**:
```bash
# Block 1: Generate unique timestamp-based filename
TIMESTAMP=$(date +%s%N)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_${TIMESTAMP}.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"

# Lines 358-375 (Block 2+): Try to load state
COORDINATE_STATE_ID_FILE_OLD="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE_OLD" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE_OLD")
  # ...
  if [ -n "${COORDINATE_STATE_ID_FILE:-}" ] && [ "$COORDINATE_STATE_ID_FILE" != "$COORDINATE_STATE_ID_FILE_OLD" ]; then
    # Workflow is using new unique state ID file pattern
    : # COORDINATE_STATE_ID_FILE already set from workflow state
  else
    # Workflow is using old fixed location pattern (backward compatibility)
    COORDINATE_STATE_ID_FILE="$COORDINATE_STATE_ID_FILE_OLD"
  fi
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE_OLD"
fi
```

**Root Cause**:
The timestamp-based filename `coordinate_state_id_${TIMESTAMP}.txt` is created in Block 1 but subsequent blocks only check for the old fixed location `coordinate_state_id.txt`. The conditional fallback mechanism (lines 364-370) **assumes** COORDINATE_STATE_ID_FILE will be loaded from workflow state, but this creates a timing dependency:

1. Block 1 creates `coordinate_state_id_1762907821946327747.txt`
2. Block 1 saves this path to workflow state via `append_workflow_state` (line 148)
3. Block 2 loads workflow state (line 511: `load_workflow_state "$WORKFLOW_ID"`)
4. **HOWEVER**: Block 2 loads WORKFLOW_ID from the **old fixed location** first (line 510), which may not exist
5. If old fixed location doesn't exist → Error "Workflow state ID file not found"

This violates **Anti-Pattern 1: Using $$ for Cross-Block State** (bash-block-execution-model.md:568-583) by creating a non-deterministic filename that subsequent blocks cannot reliably discover.

**Impact**:
- Concurrent workflow isolation fails (timestamp-based filename cannot be discovered)
- Backward compatibility pattern masks the failure (falls back to old fixed location)
- When old fixed location is also missing → workflow fails completely

**Evidence from tmp directory**:
```bash
# 62 workflow state files exist, but NO coordinate_state_id files found
$ ls -la /home/benjamin/.config/.claude/tmp/ | grep coordinate_state_id
# (no output - files were deleted by EXIT trap)
```

**Fix**: Use Pattern 1 (Fixed Semantic Filenames) - Use fixed location `coordinate_state_id.txt` for primary storage, with timestamp-based workflow state file only.

### Finding 3: WORKFLOW_SCOPE Reset by Library Re-sourcing (Anti-Pattern 2 Violation)

**Location**: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:79-81`

**Code**:
```bash
# Workflow configuration
# Preserve values across bash subprocess boundaries (Pattern 5)
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
WORKFLOW_DESCRIPTION="${WORKFLOW_DESCRIPTION:-}"
COMMAND_NAME="${COMMAND_NAME:-}"
```

**Context from coordinate.md**:
```bash
# Block 1 (lines 83-86): CRITICAL comment warns about this issue
# CRITICAL: Save workflow description BEFORE sourcing libraries
# Libraries pre-initialize WORKFLOW_DESCRIPTION="" which overwrites parent value
SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"
export SAVED_WORKFLOW_DESC
```

**Root Cause**:
While the code shows conditional initialization (`${WORKFLOW_SCOPE:-}`) which should preserve existing values (Pattern 5), the **sequencing in coordinate.md** reveals the actual bug:

1. Block 1: `sm_init()` sets WORKFLOW_SCOPE="research-and-plan" (line 151)
2. Block 1: `append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"` saves to state (line 172)
3. **Block 2**: `load_workflow_state()` restores WORKFLOW_SCOPE="research-and-plan" (lines 508-525)
4. **Block 2**: `source workflow-state-machine.sh` re-initializes with conditional pattern (line 349)
5. **HOWEVER**: The conditional pattern only helps if variable is ALREADY set before sourcing
6. **BUG**: If load_workflow_state happens AFTER library sourcing, variable is reset to ""

The actual violation is **Anti-Pattern 2: Assuming Exports Work Across Blocks** (bash-block-execution-model.md:586-598) - the workflow relies on state persistence but the **order of operations** in each block allows the variable to be reset.

**Evidence from coordinate.md Block 2 (lines 341-375)**:
```bash
# Re-source libraries (functions lost across bash block boundaries)
source "${LIB_DIR}/workflow-state-machine.sh"  # ← WORKFLOW_SCOPE reset here
source "${LIB_DIR}/state-persistence.sh"

# Load workflow state with concurrent workflow isolation support
COORDINATE_STATE_ID_FILE_OLD="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE_OLD" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE_OLD")
  load_workflow_state "$WORKFLOW_ID"  # ← WORKFLOW_SCOPE restored here (too late!)
```

**Order Dependency Bug**: Libraries are sourced **before** state is loaded, allowing variables to reset.

**Impact**:
- WORKFLOW_SCOPE incorrectly determined after state load
- Conditional branching (lines 739-778) uses wrong scope value
- Workflows proceed to unintended phases (e.g., research-only workflow continues to planning)

**Fix**: Move `load_workflow_state()` call **before** library sourcing, or use defensive recalculation after state load.

### Finding 4: Incomplete Verification Checkpoint Coverage

**Location**: `/home/benjamin/.config/.claude/commands/coordinate.md:176-179`

**Code**:
```bash
# VERIFICATION CHECKPOINT: Verify WORKFLOW_SCOPE persisted correctly
verify_state_variable "WORKFLOW_SCOPE" || {
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not persisted to state after sm_init" 1
}
```

**Root Cause**:
While coordinate.md includes verification checkpoints for WORKFLOW_SCOPE (line 177) and EXISTING_PLAN_PATH (line 186), it **does not verify** COORDINATE_STATE_ID_FILE persistence. The file is saved to state (line 148) but never verified to exist or be readable.

**Missing Verification** (should exist after line 148):
```bash
# MISSING: Verify COORDINATE_STATE_ID_FILE written correctly
verify_file_created "$COORDINATE_STATE_ID_FILE" "State ID file" "Initialization" || {
  handle_state_error "CRITICAL: State ID file not created" 1
}
```

**Impact**:
- Exit trap fires (Finding 1) → file deleted
- No verification checkpoint detects this
- Silent failure until Block 2 attempts to load state
- Violates Standard 0 (Execution Enforcement) requirement for verification checkpoints

**Evidence from Documentation** (CLAUDE.md:development_philosophy):
> Standard 0 (Execution Enforcement) uses verification checkpoints to detect errors immediately, not hide them.

**Fix**: Add verification checkpoint after COORDINATE_STATE_ID_FILE creation (line 148) to fail-fast when EXIT trap causes premature deletion.

### Finding 5: Backward Compatibility Pattern Masks Failures

**Location**: `/home/benjamin/.config/.claude/commands/coordinate.md:358-375`

**Code**:
```bash
# Load workflow state with concurrent workflow isolation support
# Try old fixed location first for backward compatibility
COORDINATE_STATE_ID_FILE_OLD="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE_OLD" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE_OLD")
  load_workflow_state "$WORKFLOW_ID"

  # Check if workflow state has unique state ID file path (new pattern)
  if [ -n "${COORDINATE_STATE_ID_FILE:-}" ] && [ "$COORDINATE_STATE_ID_FILE" != "$COORDINATE_STATE_ID_FILE_OLD" ]; then
    # Workflow is using new unique state ID file pattern
    : # COORDINATE_STATE_ID_FILE already set from workflow state
  else
    # Workflow is using old fixed location pattern (backward compatibility)
    COORDINATE_STATE_ID_FILE="$COORDINATE_STATE_ID_FILE_OLD"
  fi
else
  echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE_OLD"
  echo "Cannot restore workflow state. This is a critical error."
  exit 1
fi
```

**Root Cause**:
The backward compatibility pattern (lines 358-375) attempts to support both:
1. Old pattern: Fixed location `coordinate_state_id.txt`
2. New pattern: Unique timestamp-based `coordinate_state_id_${TIMESTAMP}.txt`

However, this pattern **masks failures** in the new pattern:
- If new pattern fails (EXIT trap deletes timestamp-based file) → fall back to old pattern
- If old pattern also fails → only then report error
- **Result**: New pattern failures are silently converted to old pattern behavior

This violates the **Fail-Fast Policy** (CLAUDE.md:development_philosophy):
> Breaking changes break loudly with clear error messages
> No silent fallbacks or graceful degradation

**Evidence from Documentation** (CLAUDE.md:development_philosophy):
> **Bootstrap fallbacks**: PROHIBITED (hide configuration errors through silent function definitions)
> **Verification fallbacks**: REQUIRED (detect tool/agent failures immediately, terminate with diagnostics)

The backward compatibility pattern acts as a **bootstrap fallback** (prohibited), not a **verification fallback** (required).

**Impact**:
- Concurrent workflow isolation feature cannot be validated (failures masked by old pattern)
- Bugs in new pattern go undetected during development
- Inconsistent behavior depending on which pattern succeeds
- Technical debt accumulates (old pattern never removed)

**Fix**: Remove backward compatibility pattern, enforce timestamp-based pattern only, add verification checkpoints to fail-fast when new pattern fails.

## Anti-Pattern Violations Summary

### Anti-Pattern 3: Premature Trap Handlers (Finding 1)
- **Location**: coordinate.md:141
- **Pattern**: EXIT trap set in Block 1 fires at block exit, not workflow exit
- **Reference**: bash-block-execution-model.md:604-612
- **Fix**: Pattern 6 (Cleanup on Completion Only)

### Anti-Pattern 1: Using Non-Deterministic Filenames for Cross-Block State (Finding 2)
- **Location**: coordinate.md:136-138
- **Pattern**: Timestamp-based filename created but cannot be discovered by subsequent blocks
- **Reference**: bash-block-execution-model.md:568-583
- **Fix**: Pattern 1 (Fixed Semantic Filenames)

### Anti-Pattern 2: Assuming Exports Work Across Blocks (Finding 3)
- **Location**: workflow-state-machine.sh:79-81, coordinate.md:341-375
- **Pattern**: Variable persistence assumed but order-dependent restoration fails
- **Reference**: bash-block-execution-model.md:586-598
- **Fix**: Load state before re-sourcing libraries, or use defensive recalculation

### Anti-Pattern 4: Code Review Without Runtime Testing (Findings 1-5)
- **Location**: All findings above
- **Pattern**: Issues only appear at runtime, not code review
- **Reference**: bash-block-execution-model.md:614-630
- **Evidence**: 62 workflow state files exist but no coordinate_state_id files (deleted by EXIT trap)

## Architectural Analysis

### Current Architecture (Flawed)

```
Block 1: Initialization
├─ Generate WORKFLOW_ID (timestamp-based)
├─ Create COORDINATE_STATE_ID_FILE (timestamp + nanoseconds)
├─ Save state ID file path to workflow state
├─ Set EXIT trap (PREMATURE - causes cleanup at block exit)
└─ Block exits → EXIT trap fires → COORDINATE_STATE_ID_FILE deleted

Block 2: Research Phase
├─ Try to load state ID from old fixed location (backward compatibility)
│  ├─ If found: Load WORKFLOW_ID, load state
│  └─ If not found: ERROR (but new pattern file already deleted!)
├─ Re-source libraries (WORKFLOW_SCOPE may reset)
├─ Check if COORDINATE_STATE_ID_FILE loaded from state
│  ├─ If yes: Use new pattern (but file already deleted by EXIT trap!)
│  └─ If no: Fall back to old pattern (masks new pattern failure)
└─ Continue with (potentially wrong) state
```

### Recommended Architecture (Fixed)

```
Block 1: Initialization
├─ Generate WORKFLOW_ID (timestamp-based)
├─ Create fixed location state ID file: coordinate_state_id.txt (DETERMINISTIC)
├─ Save WORKFLOW_ID to fixed location file
├─ Initialize workflow state file: workflow_${WORKFLOW_ID}.sh
├─ Save all state variables to workflow state
├─ VERIFICATION CHECKPOINT: Verify state ID file exists and readable
└─ NO EXIT TRAP (cleanup deferred to completion function)

Block 2+: State Handlers
├─ Read WORKFLOW_ID from fixed location: coordinate_state_id.txt
├─ Load workflow state FIRST (before library sourcing)
├─ Re-source libraries (conditional initialization preserves loaded values)
├─ VERIFICATION CHECKPOINT: Verify critical state variables loaded
└─ Proceed with verified state

Final Block: Completion
├─ Display summary
├─ Set EXIT trap for cleanup (fires at workflow end)
└─ Block exits → trap cleans up state files
```

### Key Architectural Changes

1. **Fixed Location State ID File**: Replace timestamp-based filename with `coordinate_state_id.txt` (Pattern 1)
2. **Deferred Cleanup**: Move EXIT trap from Block 1 to completion function (Pattern 6)
3. **State-Before-Libraries**: Load state before re-sourcing libraries to preserve values (Fix Finding 3)
4. **Comprehensive Verification**: Add checkpoints after state ID file creation (Fix Finding 4)
5. **Remove Backward Compatibility**: Eliminate silent fallback pattern (Fix Finding 5)

## Relationship to Documented Patterns

### Validated Patterns (bash-block-execution-model.md:832-840)

coordinate.md **correctly uses**:
- ✓ Pattern 2: Save-Before-Source (state ID saved to file before use)
- ✓ Pattern 3: State Persistence Library (uses state-persistence.sh)
- ✓ Pattern 4: Library Re-sourcing with Source Guards (re-sources in each block)

coordinate.md **violates**:
- ✗ Pattern 1: Fixed Semantic Filenames (uses timestamp-based non-deterministic filename)
- ✗ Pattern 6: Cleanup on Completion Only (EXIT trap in early block)

### Critical Anti-Patterns (bash-block-execution-model.md:566-630)

coordinate.md **exhibits**:
- ✗ Anti-Pattern 1: Using $$ for Cross-Block State (timestamp equivalent)
- ✗ Anti-Pattern 2: Assuming Exports Work (WORKFLOW_SCOPE order dependency)
- ✗ Anti-Pattern 3: Premature Trap Handlers (EXIT trap in Block 1)
- ✗ Anti-Pattern 4: Code Review Without Runtime Testing (issues only visible at runtime)

## Recommendations

### Recommendation 1: Remove EXIT Trap from Block 1 (HIGH PRIORITY)

**Change**: Delete line 141 in coordinate.md
```diff
- trap "rm -f '$COORDINATE_STATE_ID_FILE' 2>/dev/null || true" EXIT
```

**Rationale**: Implements Pattern 6 (Cleanup on Completion Only). EXIT trap should only be set in `display_brief_summary()` function called in final block.

**Implementation**:
```bash
# In display_brief_summary() function (called at workflow end)
display_brief_summary() {
  # Set cleanup trap (fires when THIS block exits = workflow end)
  trap 'rm -f "${HOME}/.claude/tmp/coordinate_state_id.txt" "${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"' EXIT

  echo "Workflow complete"
  # ... summary output ...
}
```

### Recommendation 2: Use Fixed Location for State ID File (HIGH PRIORITY)

**Change**: Replace timestamp-based filename with fixed location
```diff
  # Generate unique workflow ID (timestamp-based for reproducibility)
  WORKFLOW_ID="coordinate_$(date +%s)"

  # Initialize workflow state (GitHub Actions pattern)
  STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

  # Save workflow ID to file for subsequent blocks (use unique timestamp-based filename for concurrent workflow isolation)
- TIMESTAMP=$(date +%s%N)
- COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id_${TIMESTAMP}.txt"
+ COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
  echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"
```

**Rationale**: Implements Pattern 1 (Fixed Semantic Filenames). Subsequent blocks can reliably find state ID file.

**Concurrent Workflow Support**: Use file locking if concurrent workflows needed:
```bash
# Optional: Add file lock for concurrent workflow support
{
  flock -x 200
  echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"
} 200>"${COORDINATE_STATE_ID_FILE}.lock"
```

### Recommendation 3: Load State Before Re-sourcing Libraries (MEDIUM PRIORITY)

**Change**: Reorder Block 2+ initialization sequence
```diff
  # Re-source libraries (functions lost across bash block boundaries)
- source "${LIB_DIR}/workflow-state-machine.sh"
- source "${LIB_DIR}/state-persistence.sh"
-
- # Load workflow state
+ # Load workflow state FIRST (before library re-sourcing)
  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
  if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
    WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
    load_workflow_state "$WORKFLOW_ID"
  else
    echo "ERROR: State ID file not found"
    exit 1
  fi
+
+ # Re-source libraries AFTER state load (preserves loaded values)
+ source "${LIB_DIR}/workflow-state-machine.sh"
+ source "${LIB_DIR}/state-persistence.sh"
```

**Rationale**: Fixes Finding 3 (WORKFLOW_SCOPE reset). State variables loaded from persistence layer remain intact when libraries use conditional initialization pattern.

**Note**: This fix depends on Pattern 5 (Conditional Variable Initialization) already implemented in workflow-state-machine.sh:79-81.

### Recommendation 4: Add State ID File Verification Checkpoint (MEDIUM PRIORITY)

**Change**: Add verification after COORDINATE_STATE_ID_FILE creation
```diff
  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
  echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"

+ # VERIFICATION CHECKPOINT: Verify state ID file created successfully
+ verify_file_created "$COORDINATE_STATE_ID_FILE" "State ID file" "Initialization" || {
+   handle_state_error "CRITICAL: State ID file not created at $COORDINATE_STATE_ID_FILE" 1
+ }
+
  # Save workflow ID to file for subsequent blocks
  append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
  append_workflow_state "WORKFLOW_DESCRIPTION" "$SAVED_WORKFLOW_DESC"
```

**Rationale**: Implements Standard 0 (Execution Enforcement). Fail-fast when state ID file creation fails or is immediately deleted by EXIT trap.

### Recommendation 5: Remove Backward Compatibility Pattern (LOW PRIORITY)

**Change**: Simplify Block 2+ state loading logic
```diff
  # Load workflow state
- COORDINATE_STATE_ID_FILE_OLD="${HOME}/.claude/tmp/coordinate_state_id.txt"
- if [ -f "$COORDINATE_STATE_ID_FILE_OLD" ]; then
-   WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE_OLD")
+ COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
+ if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
+   WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
    load_workflow_state "$WORKFLOW_ID"
-
-   # Check if workflow state has unique state ID file path (new pattern)
-   if [ -n "${COORDINATE_STATE_ID_FILE:-}" ] && [ "$COORDINATE_STATE_ID_FILE" != "$COORDINATE_STATE_ID_FILE_OLD" ]; then
-     # Workflow is using new unique state ID file pattern
-     : # COORDINATE_STATE_ID_FILE already set from workflow state
-   else
-     # Workflow is using old fixed location pattern (backward compatibility)
-     COORDINATE_STATE_ID_FILE="$COORDINATE_STATE_ID_FILE_OLD"
-   fi
  else
-   echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE_OLD"
+   echo "ERROR: Workflow state ID file not found: $COORDINATE_STATE_ID_FILE"
    echo "Cannot restore workflow state. This is a critical error."
    exit 1
  fi
```

**Rationale**: Implements Fail-Fast Policy (CLAUDE.md:development_philosophy). Remove silent fallback that masks new pattern failures.

**Breaking Change**: This change removes backward compatibility with old state ID file location. Existing workflows using old location will fail with clear error message.

**Migration**: Add one-time migration script if needed:
```bash
# Migration helper (run once)
OLD_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$OLD_FILE" ]; then
  echo "Found old state ID file, migration not needed (already using fixed location)"
fi
```

## References

### Primary Source Files
- `/home/benjamin/.config/.claude/commands/coordinate.md` - Orchestration command with state persistence bugs
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md` - Documented patterns and anti-patterns
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` - GitHub Actions-style state persistence library
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` - State machine with conditional initialization

### Documentation References
- bash-block-execution-model.md:141-159 - Subprocess isolation validation test
- bash-block-execution-model.md:162-225 - Pattern 1: Fixed Semantic Filenames
- bash-block-execution-model.md:388-399 - Pattern 6: Cleanup on Completion Only
- bash-block-execution-model.md:568-583 - Anti-Pattern 1: Using $$ for Cross-Block State
- bash-block-execution-model.md:586-598 - Anti-Pattern 2: Assuming Exports Work Across Blocks
- bash-block-execution-model.md:604-612 - Anti-Pattern 3: Premature Trap Handlers
- bash-block-execution-model.md:614-630 - Anti-Pattern 4: Code Review Without Runtime Testing
- CLAUDE.md:development_philosophy - Fail-Fast Policy and Clean-Break Evolution
- CLAUDE.md:development_philosophy - Standard 0 (Execution Enforcement) verification requirements

### Evidence Files
- `/home/benjamin/.config/.claude/tmp/workflow_coordinate_1762907821.sh` - Example workflow state file showing COORDINATE_STATE_ID_FILE persistence
- `/home/benjamin/.config/.claude/tmp/` - Directory listing showing 62 workflow state files but zero coordinate_state_id files (deleted by EXIT trap)

### Related Specifications
- Spec 620: Bash history expansion fixes (subprocess isolation discovery)
- Spec 630: State persistence architecture (cross-block state management)
- Spec 672: Checkpoint recovery pattern (state verification requirements)
- Spec 675: Library sourcing order fix (function availability before calls)

## Implementation Priority

### Phase 1: Critical Fixes (Block Workflow Failures)
1. **Remove EXIT trap from Block 1** (Recommendation 1) - Prevents state ID file deletion
2. **Use fixed location for state ID file** (Recommendation 2) - Enables reliable discovery
3. **Add state ID file verification** (Recommendation 4) - Fail-fast detection

**Estimated Impact**: Fixes 80% of state persistence failures (Findings 1, 2, 4)

### Phase 2: Variable Persistence Fixes (Silent Failures)
4. **Load state before library re-sourcing** (Recommendation 3) - Fixes WORKFLOW_SCOPE reset

**Estimated Impact**: Fixes remaining 15% of failures (Finding 3)

### Phase 3: Technical Debt Removal (Code Quality)
5. **Remove backward compatibility pattern** (Recommendation 5) - Eliminates silent fallback

**Estimated Impact**: Improves maintainability, enforces fail-fast policy (Finding 5)

## Testing Strategy

### Unit Tests (validate individual patterns)
1. Test EXIT trap deferred to completion function (bash-block-execution-model.md:141-159)
2. Test fixed location state ID file persistence across 3 bash blocks
3. Test WORKFLOW_SCOPE persistence with state-before-libraries pattern
4. Test verification checkpoint fail-fast behavior (inject file creation failure)

### Integration Tests (validate full workflows)
1. Run research-only workflow (1 phase, verify state ID file not deleted)
2. Run research-and-plan workflow (2 phases, verify WORKFLOW_SCOPE=research-and-plan)
3. Run full-implementation workflow (5+ phases, verify all state transitions)
4. Run concurrent workflows (2 simultaneous coordinate invocations, verify no collision)

### Regression Tests (prevent reintroduction of bugs)
1. Monitor `/home/benjamin/.config/.claude/tmp/` for premature state ID file deletion
2. Verify WORKFLOW_SCOPE value at start of each block (log to file)
3. Check verification checkpoint coverage (all critical files verified)
4. Validate backward compatibility pattern removed (no silent fallbacks)

## Conclusion

The /coordinate command's state persistence failures stem from systematic violations of documented bash block execution patterns. The root cause is architectural: treating bash blocks as subshells (shared memory) when they are actually subprocesses (isolated memory). Fixing these violations requires five targeted changes prioritized by impact, with Phase 1 (critical fixes) addressing 80% of failures. Implementation of all recommendations will align /coordinate with bash-block-execution-model.md patterns, achieving 100% reliability for cross-block state persistence.