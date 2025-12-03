# Research Report: Lean Command Metadata and Phase Header Updates

## Metadata

- **Date**: 2025-12-03
- **Research Complexity**: 3
- **Research Topic**: Improve /lean command to remove lean file metadata requirement and add real-time phase header updates using standard utilities like /implement
- **Report Type**: technical_analysis

## Executive Summary

The /lean command currently has two main limitations compared to /implement:

1. **Mandatory Lean File Metadata**: The command requires a `**Lean File**: /path` metadata field in the plan, failing with validation error if missing. This is overly restrictive since different phases may work on different Lean files.

2. **Missing Real-Time Progress Tracking**: The lean-coordinator and lean-implementer agents do not update phase status markers ([IN PROGRESS], [COMPLETE]) during execution. Progress is only visible after the entire workflow completes.

This report analyzes both issues and provides implementation recommendations based on patterns from /implement.

## Issue 1: Mandatory Lean File Metadata Requirement

### Current Implementation

**File**: `/home/benjamin/.config/.claude/commands/lean.md`
**Lines**: 154-173

```bash
# Extract lean_file_path from plan metadata
# Look for pattern: **Lean File**: /path/to/file.lean or - **Lean File**: /path
LEAN_FILE=$(grep -E "^\*\*Lean File\*\*:|^- \*\*Lean File\*\*:" "$PLAN_FILE" | sed 's/^- \*\*Lean File\*\*:[[:space:]]*//' | sed 's/^\*\*Lean File\*\*:[[:space:]]*//' | head -1)

if [ -z "$LEAN_FILE" ]; then
  echo "ERROR: Plan file missing '**Lean File**: /path' metadata" >&2
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" "Plan missing Lean File metadata" "bash_block" \
    "{\"plan_file\": \"$PLAN_FILE\"}"
  exit 1
fi

if [ ! -f "$LEAN_FILE" ]; then
  echo "ERROR: Lean file not found: $LEAN_FILE" >&2
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "file_error" "Lean file from plan not found: $LEAN_FILE" "bash_block" \
    "{\"plan_file\": \"$PLAN_FILE\", \"lean_file\": \"$LEAN_FILE\"}"
  exit 1
fi
```

### Problem Analysis

1. **Overly Restrictive**: Plans often don't specify a single Lean file because:
   - Different phases may work on different files (e.g., `Axioms.lean`, `Theorems.lean`, `Semantics.lean`)
   - The lean file path may be specified in phase-level tasks, not plan metadata
   - Multi-file Lean projects are common and natural

2. **Workflow Friction**: Users must manually add metadata field to plan before running /lean, even if phase tasks already specify which files to work on

3. **Inconsistent with /implement**: The /implement command doesn't require file metadata - it discovers files from phase tasks dynamically

### Recommended Solution

**Option 1: Make Lean File Metadata Optional with Fallback Discovery**

```bash
# === DETECT EXECUTION MODE ===
EXECUTION_MODE="file-based"  # Default
PLAN_FILE=""
LEAN_FILE=""

if [[ "$INPUT_FILE" == *.md ]]; then
  # Plan file provided
  EXECUTION_MODE="plan-based"
  PLAN_FILE="$INPUT_FILE"

  # Source checkbox utilities for plan support
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || {
    echo "ERROR: Failed to source checkbox-utils.sh" >&2
    exit 1
  }

  # === LEAN FILE DISCOVERY (with fallback) ===
  # Try 1: Extract from plan metadata (optional)
  LEAN_FILE=$(grep -E "^\*\*Lean File\*\*:|^- \*\*Lean File\*\*:" "$PLAN_FILE" | sed 's/^- \*\*Lean File\*\*:[[:space:]]*//' | sed 's/^\*\*Lean File\*\*:[[:space:]]*//' | head -1)

  if [ -z "$LEAN_FILE" ]; then
    # Try 2: Scan phase tasks for .lean file references
    LEAN_FILE=$(grep -oP '(?<=\s)/[^\s]+\.lean' "$PLAN_FILE" | head -1)
  fi

  if [ -z "$LEAN_FILE" ]; then
    # Try 3: Look for .lean files in topic directory
    TOPIC_PATH=$(dirname "$(dirname "$PLAN_FILE")")
    LEAN_FILE=$(find "$TOPIC_PATH" -name "*.lean" -type f | head -1)
  fi

  if [ -z "$LEAN_FILE" ]; then
    echo "ERROR: No Lean file found. Specify via:" >&2
    echo "  1. Plan metadata: **Lean File**: /path/to/file.lean" >&2
    echo "  2. Task description: - [ ] Prove theorem in /path/to/file.lean" >&2
    echo "  3. Topic directory: Place .lean file in topic directory" >&2
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "validation_error" "No Lean file discovered" "bash_block" \
      "{\"plan_file\": \"$PLAN_FILE\", \"topic_path\": \"$TOPIC_PATH\"}"
    exit 1
  fi

  if [ ! -f "$LEAN_FILE" ]; then
    echo "ERROR: Lean file not found: $LEAN_FILE" >&2
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "file_error" "Discovered Lean file not found: $LEAN_FILE" "bash_block" \
      "{\"plan_file\": \"$PLAN_FILE\", \"lean_file\": \"$LEAN_FILE\"}"
    exit 1
  fi

  echo "Execution Mode: plan-based"
  echo "Plan File: $PLAN_FILE"
  echo "Lean File: $LEAN_FILE (discovered)"
```

**Benefits**:
- Backward compatible (metadata still works if present)
- Graceful fallback to task scanning and directory search
- Clear error message with 3 options if discovery fails
- Aligns with /implement's dynamic file discovery pattern

**Option 2: Remove Lean File Requirement Entirely (Aggressive)**

Remove the single-file requirement and pass the plan file to lean-coordinator. The coordinator/implementer agents discover Lean files from phase tasks dynamically.

**Recommendation**: Use **Option 1** for backward compatibility while enabling flexible discovery.

## Issue 2: Missing Real-Time Phase Header Updates

### Current Implementation Gap

**Files Analyzed**:
- `/home/benjamin/.config/.claude/agents/lean-coordinator.md` - No phase marker updates
- `/home/benjamin/.config/.claude/agents/lean-implementer.md` - No phase marker updates

**Observations**:

1. **No Progress Tracking Library Integration**: Neither lean-coordinator nor lean-implementer source `checkbox-utils.sh` or use `add_in_progress_marker()` / `add_complete_marker()` functions

2. **No Real-Time Visibility**: Users cannot `cat plan.md` during execution to see which phases are executing. Progress only visible after workflow completes.

3. **Contrast with /implement Pattern**: The implementation-executor agent (lines 91-103) demonstrates proper integration:

```bash
# Source checkbox-utils.sh library
CLAUDE_LIB="/home/user/.config/.claude/lib"
source "$CLAUDE_LIB/plan/checkbox-utils.sh" 2>/dev/null || {
  echo "Warning: Cannot load checkbox-utils.sh - phase markers will not be updated" >&2
  # Non-fatal - continue execution without marker updates
}

# Mark phase as IN PROGRESS
if type add_in_progress_marker &>/dev/null; then
  add_in_progress_marker "$phase_file_path" "$phase_number" 2>/dev/null || {
    echo "Warning: Failed to add [IN PROGRESS] marker to Phase $phase_number" >&2
  }
fi
```

**After phase completion** (implementation-executor.md lines 189-202):

```bash
# Mark phase as COMPLETE after all tasks done
if type add_complete_marker &>/dev/null; then
  add_complete_marker "$phase_file_path" "$phase_number" 2>/dev/null || {
    echo "Warning: Failed to add [COMPLETE] marker via add_complete_marker" >&2
    # Fallback: Use mark_phase_complete to force update
    if type mark_phase_complete &>/dev/null; then
      mark_phase_complete "$phase_file_path" "$phase_number" 2>/dev/null || {
        echo "Warning: Fallback mark_phase_complete also failed for Phase $phase_number" >&2
      }
    fi
  }
fi
```

### Available Utilities (checkbox-utils.sh)

**File**: `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh`

**Key Functions**:

1. **`add_in_progress_marker(plan_path, phase_num)`** (lines 440-469)
   - Removes existing status marker (NOT STARTED, COMPLETE, BLOCKED)
   - Adds `[IN PROGRESS]` to phase heading
   - Uses awk pattern matching for h2/h3 heading compatibility
   - Returns 0 on success, 1 on failure

2. **`add_complete_marker(plan_path, phase_num)`** (lines 473-508)
   - Validates phase completion via `verify_phase_complete()` before marking
   - Removes existing status marker
   - Adds `[COMPLETE]` to phase heading
   - Returns 0 on success, 1 if incomplete tasks remain

3. **`mark_phase_complete(plan_path, phase_num)`** (lines 188-277)
   - Marks ALL tasks in phase as `[x]` (complete)
   - Supports Level 0 (inline), Level 1 (expanded phases), and Level 2 (stages)
   - Does NOT validate completion - force marks all tasks

4. **`verify_phase_complete(plan_path, phase_num)`** (lines 554-590)
   - Counts unchecked boxes in phase
   - Returns 0 if all checked, 1 if any unchecked
   - Used by `add_complete_marker()` for validation

5. **`propagate_progress_marker(plan_path, phase_num, status)`** (lines 347-404)
   - Propagates status marker to parent plans in Level 1/2 structures
   - Calls appropriate marker function based on status
   - Supports hierarchical plan structures

### Comparison: /implement vs /lean Progress Tracking

| Aspect | /implement (implementation-executor) | /lean (lean-implementer) | Gap |
|--------|--------------------------------------|--------------------------|-----|
| Sources checkbox-utils.sh | Yes (lines 92-96) | No | Missing library integration |
| Marks phase [IN PROGRESS] | Yes (lines 99-103) | No | No start marker |
| Marks phase [COMPLETE] | Yes (lines 190-202) | No | No completion marker |
| Error handling | Non-fatal warnings | N/A | No graceful degradation |
| Fallback on failure | Yes (mark_phase_complete) | N/A | No fallback |
| User visibility | Real-time via `cat plan.md` | Only at end | No progress visibility |

### Root Cause Analysis

**Why are markers missing in /lean?**

1. **lean-coordinator.md** (wave orchestrator):
   - Lines 1-809: No mention of checkbox-utils.sh
   - Lines 287-375: Task invocation for lean-implementer does NOT pass phase_number or plan_path for marker updates
   - Focus on wave orchestration and MCP rate limit coordination, no progress tracking

2. **lean-implementer.md** (theorem prover):
   - Lines 1-726: No mention of checkbox-utils.sh
   - Lines 376-404: Plan update section mentions marking tasks complete, but uses manual approach (not checkbox-utils)
   - Lines 381-404: Manual bash script for phase marker updates, not using standard library
   - No integration with standard progress tracking utilities

**Critical Difference**: /implement's implementation-executor receives `phase_number` and `plan_path` as explicit input parameters. /lean's lean-implementer receives `theorem_tasks` (array of theorems) but no phase tracking context.

### Recommended Solution

**Step 1: Update lean-implementer Input Contract**

Add phase tracking parameters to input contract (lean-implementer.md lines 48-63):

```yaml
lean_file_path: /absolute/path/to/file.lean
topic_path: /absolute/path/to/topic/
artifact_paths:
  summaries: /topic/summaries/
  debug: /topic/debug/
max_attempts: 3  # Maximum proof attempts per theorem
plan_path: ""  # Optional: Path to plan file for progress tracking (empty string if file-based mode)
execution_mode: "file-based"  # "file-based" or "plan-based"
theorem_tasks: []  # Optional: Array of theorem objects to process (empty array = process all sorry markers)
rate_limit_budget: 3  # Optional: Number of external search requests allowed (default: 3)
wave_number: 1  # Optional: Current wave number for progress tracking
phase_number: 1  # NEW: Phase number for progress marker updates (plan-based mode only)
continuation_context: null  # Optional: Path to previous iteration summary
```

**Step 2: Add Progress Tracking Initialization (lean-implementer.md)**

Insert after line 105 (after continuation handling):

```bash
# === PROGRESS TRACKING SETUP (plan-based mode only) ===
if [ -n "$plan_path" ] && [ "$plan_path" != "" ]; then
  # Source checkbox-utils.sh library
  CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"
  source "$CLAUDE_LIB/plan/checkbox-utils.sh" 2>/dev/null || {
    echo "Warning: Cannot load checkbox-utils.sh - phase markers will not be updated" >&2
    # Non-fatal - continue execution without marker updates
  }

  # Mark phase as IN PROGRESS (non-fatal)
  if [ -n "$phase_number" ] && type add_in_progress_marker &>/dev/null; then
    add_in_progress_marker "$plan_path" "$phase_number" 2>/dev/null || {
      echo "Warning: Failed to add [IN PROGRESS] marker to Phase $phase_number" >&2
    }
  fi
fi
```

**Step 3: Add Phase Completion Marker (lean-implementer.md)**

Insert after theorem proving loop completes (after line 404):

```bash
# === MARK PHASE COMPLETE (plan-based mode only) ===
if [ -n "$plan_path" ] && [ "$plan_path" != "" ] && [ -n "$phase_number" ]; then
  # Mark phase as COMPLETE after all theorems processed
  if type add_complete_marker &>/dev/null; then
    add_complete_marker "$plan_path" "$phase_number" 2>/dev/null || {
      echo "Warning: Failed to add [COMPLETE] marker via add_complete_marker" >&2
      # Fallback: Use mark_phase_complete to force update
      if type mark_phase_complete &>/dev/null; then
        mark_phase_complete "$plan_path" "$phase_number" 2>/dev/null || {
          echo "Warning: Fallback mark_phase_complete also failed for Phase $phase_number" >&2
        }
      fi
    }
  fi
fi
```

**Step 4: Update lean-coordinator Invocation**

Modify lean-coordinator.md to pass phase_number to lean-implementer (lines 301-316):

```yaml
Input:
- lean_file_path: /path/to/Theorems.lean
- theorem_tasks: [{"name": "theorem_add_comm", "line": 42, "phase_number": 1}]
- plan_path: /path/to/specs/028_lean/plans/001-lean-plan.md
- rate_limit_budget: 1
- execution_mode: "plan-based"
- wave_number: 1
- phase_number: 1  # NEW: Extract from theorem_tasks[0].phase_number
- continuation_context: null
```

**Step 5: Enhance lean-coordinator Progress Reporting**

Add progress tracking to lean-coordinator.md wave completion (after line 464):

```bash
# === UPDATE PHASE MARKERS ===
# For each completed theorem in wave, check if its phase is fully complete
for phase_num in "${completed_phases[@]}"; do
  if verify_phase_complete "$plan_path" "$phase_num"; then
    add_complete_marker "$plan_path" "$phase_num" 2>/dev/null || {
      echo "Warning: Could not add [COMPLETE] marker to Phase $phase_num" >&2
    }
  fi
done
```

### Expected Behavior After Changes

**Before**:
```markdown
### Phase 1: Prove Commutativity Axioms

- [ ] Prove theorem_add_comm
- [ ] Prove theorem_mul_comm
```

**During Execution** (after lean-implementer starts Phase 1):
```markdown
### Phase 1: Prove Commutativity Axioms [IN PROGRESS]

- [ ] Prove theorem_add_comm
- [ ] Prove theorem_mul_comm
```

**After Phase 1 Complete**:
```markdown
### Phase 1: Prove Commutativity Axioms [COMPLETE]

- [x] Prove theorem_add_comm
- [x] Prove theorem_mul_comm
```

**User Experience**: Users can `cat plan.md` during long proof sessions to see which phases are active and which have completed.

### Error Handling Strategy

Following /implement pattern (implementation-executor.md lines 376-383):

1. **Non-Fatal Failures**: Progress marker updates are cosmetic. Failures should log warnings but NOT block theorem proving.

2. **Graceful Degradation**: If checkbox-utils.sh unavailable, continue without markers.

3. **Fallback Logic**: Use `mark_phase_complete()` if `add_complete_marker()` fails validation.

4. **Recovery**: /lean Block 1d validation-and-recovery (similar to /implement) will detect and fix missing markers after execution.

**Rationale**: Theorem proving is the core functionality. Progress markers are user-facing enhancements. Library failures should not block mathematical work.

## Implementation Complexity Assessment

### Issue 1: Remove Lean File Metadata Requirement

**Complexity**: Low (1-2 hours)

**Changes Required**:
1. Modify /lean command Block 1a (lines 154-173)
2. Add fallback discovery logic (grep tasks, find files)
3. Update error messages with discovery options
4. Test with plans that have/don't have metadata

**Risk**: Low - backward compatible, graceful fallback

### Issue 2: Add Real-Time Phase Header Updates

**Complexity**: Medium (3-4 hours)

**Changes Required**:
1. Update lean-implementer input contract (add phase_number)
2. Add progress tracking initialization in lean-implementer
3. Add completion marker logic in lean-implementer
4. Update lean-coordinator invocation to pass phase_number
5. Add optional marker validation in lean-coordinator
6. Test with Level 0, Level 1, and Level 2 plans
7. Verify non-fatal error handling

**Risk**: Medium - requires careful non-fatal error handling and testing across plan structures

## Dependencies

### Libraries Required
- `checkbox-utils.sh` (already exists, lines 1-697)
- `plan-core-bundle.sh` (dependency of checkbox-utils)
- `base-utils.sh` (dependency of checkbox-utils)

### Functions Used
- `add_in_progress_marker(plan_path, phase_num)` - checkbox-utils.sh line 440
- `add_complete_marker(plan_path, phase_num)` - checkbox-utils.sh line 473
- `mark_phase_complete(plan_path, phase_num)` - checkbox-utils.sh line 188
- `verify_phase_complete(plan_path, phase_num)` - checkbox-utils.sh line 554

### Command Integration Points
- `/lean` command Block 1a: Lean file discovery (lines 154-173)
- `lean-coordinator` agent: Phase number propagation (lines 287-375)
- `lean-implementer` agent: Progress marker updates (initialization + completion)

## Testing Strategy

### Issue 1 Testing

**Test Case 1**: Plan with Lean File metadata (backward compatibility)
```bash
# Plan has: **Lean File**: /path/to/Theorems.lean
/lean plan.md --prove-all
# Expected: Use metadata path (existing behavior)
```

**Test Case 2**: Plan without metadata, tasks reference file
```bash
# Plan has: - [ ] Prove theorem in /path/to/Theorems.lean
/lean plan.md --prove-all
# Expected: Discover from task reference
```

**Test Case 3**: Plan without metadata, .lean file in topic directory
```bash
# Plan has no Lean File reference, but topic dir contains Axioms.lean
/lean plan.md --prove-all
# Expected: Discover from directory scan
```

**Test Case 4**: No Lean file discoverable
```bash
# Plan has no metadata, no task references, no .lean files
/lean plan.md --prove-all
# Expected: Error with 3 discovery options listed
```

### Issue 2 Testing

**Test Case 1**: Level 0 plan (inline phases)
```bash
# Plan has phases inline in single file
/lean plan.md --prove-all
# Expected: [IN PROGRESS] and [COMPLETE] markers appear during execution
```

**Test Case 2**: Level 1 plan (expanded phases)
```bash
# Plan has separate phase_N.md files
/lean plan.md --prove-all
# Expected: Markers appear in both phase files and parent plan
```

**Test Case 3**: checkbox-utils.sh unavailable
```bash
# Simulate library sourcing failure
/lean plan.md --prove-all
# Expected: Warning logged, theorem proving continues without markers
```

**Test Case 4**: add_complete_marker validation fails (incomplete tasks)
```bash
# Plan has phase with incomplete tasks
/lean plan.md --prove-all
# Expected: Fallback to mark_phase_complete, marker added
```

**Test Case 5**: Real-time visibility check
```bash
# During long proof execution, in another terminal:
watch -n 1 "grep -E '^### Phase.*\[(IN PROGRESS|COMPLETE)\]' plan.md"
# Expected: See markers update in real-time as phases execute
```

## Recommendations

### Priority 1: Issue 1 (Lean File Metadata)

**Implement Option 1**: Make metadata optional with fallback discovery

**Rationale**:
- Low complexity, high user value
- Backward compatible
- Aligns with /implement's dynamic file discovery pattern
- Reduces workflow friction

**Timeline**: 1-2 hours

### Priority 2: Issue 2 (Real-Time Progress Tracking)

**Implement full integration** with checkbox-utils.sh in lean-implementer and lean-coordinator

**Rationale**:
- Aligns /lean with /implement's progress visibility
- Enhances user experience for long proof sessions
- Non-fatal error handling ensures robustness
- Enables real-time monitoring via `cat plan.md`

**Timeline**: 3-4 hours

### Combined Approach

Both issues can be addressed in a single implementation cycle with minimal risk:

1. **Phase 1** (2 hours): Remove mandatory Lean File metadata requirement
   - Modify /lean Block 1a with fallback discovery
   - Test backward compatibility

2. **Phase 2** (4 hours): Add real-time progress tracking
   - Update lean-implementer with checkbox-utils integration
   - Update lean-coordinator invocation
   - Test across plan structures
   - Verify non-fatal error handling

**Total Estimated Time**: 6 hours

## References

### Files Analyzed

1. **Commands**:
   - `/home/benjamin/.config/.claude/commands/lean.md` (lines 1-814)
   - `/home/benjamin/.config/.claude/commands/implement.md` (lines 1-1492)

2. **Agents**:
   - `/home/benjamin/.config/.claude/agents/lean-coordinator.md` (lines 1-809)
   - `/home/benjamin/.config/.claude/agents/lean-implementer.md` (lines 1-726)
   - `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` (lines 1-830)
   - `/home/benjamin/.config/.claude/agents/implementation-executor.md` (lines 1-565)

3. **Libraries**:
   - `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh` (lines 1-697)

### Key Patterns Identified

1. **Graceful Degradation**: /implement uses non-fatal error handling for progress markers (implementation-executor.md lines 92-103, 190-202)

2. **Library Integration**: checkbox-utils.sh provides standard functions for phase marker updates (lines 440-508)

3. **Fallback Strategy**: Use mark_phase_complete() if add_complete_marker() validation fails (implementation-executor.md lines 195-200)

4. **Dynamic Discovery**: /implement discovers files from tasks, not mandatory metadata

5. **Recovery Pattern**: Block 1d validates and recovers missing markers after execution (/implement lines 1042-1257, /lean lines 561-679)

## Conclusion

Both issues identified in /lean command are solvable using existing patterns from /implement:

1. **Lean File Metadata**: Make optional with fallback discovery (2 hours, low risk)
2. **Real-Time Progress**: Integrate checkbox-utils.sh in lean-implementer and lean-coordinator (4 hours, medium risk)

The combined implementation effort (6 hours) will bring /lean's user experience in line with /implement's progress visibility and flexibility, while maintaining backward compatibility and robustness through graceful error handling.

REPORT_CREATED: /home/benjamin/.config/.claude/specs/030_lean_metadata_phase_header_update/reports/001_research_report.md
