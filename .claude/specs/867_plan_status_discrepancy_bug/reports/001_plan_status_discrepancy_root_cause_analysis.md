# Plan Status Discrepancy Root Cause Analysis

## Metadata
- **Date**: 2025-11-20
- **Topic**: 867_plan_status_discrepancy_bug
- **Workflow**: Debug (Root Cause Analysis)
- **Research Complexity**: 3
- **Related Plan**: /home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/001_leaderac_command_nvim_order_check_that_t_plan/001_leaderac_command_nvim_order_check_that_t_plan.md
- **Related Summary**: /home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/summaries/002_phase_1_foundation_partial_implementation.md

## Implementation Status

- **Status**: Plan Revised (Clean-Break Approach)
- **Plan**: [../plans/001_debug_strategy.md](../plans/001_debug_strategy.md)
- **Implementation**: [Will be updated by build command]
- **Date**: 2025-11-20

## Executive Summary

**Problem**: Plan file reports all phases as `[COMPLETE]` when summary file clearly indicates only 15% completion (Phase 1A complete, 85% remaining).

**Root Cause**: Phase status markers (`[COMPLETE]`) are added to plan files without validation that all phase tasks are actually complete. The infrastructure lacks synchronization between:
1. Individual task checkboxes (`- [x]` markers)
2. Phase status markers (`### Phase N: Name [COMPLETE]`)
3. Summary file work status reporting

**Impact**: Critical - Plan files misrepresent implementation status, breaking the single source of truth principle and causing confusion about actual work completion.

**Fix Complexity**: Medium - Requires adding validation logic to existing infrastructure without breaking current workflows.

## Problem Statement

### Symptom
The plan file at `/home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/001_leaderac_command_nvim_order_check_that_t_plan/001_leaderac_command_nvim_order_check_that_t_plan.md` shows:

```markdown
### Phase 1: Foundation - Modular Architecture [COMPLETE]
### Phase 2: Add Missing Permanent Artifacts [COMPLETE]
### Phase 3: Integration and Atomic Cutover [COMPLETE]
### Phase 4: Polish and Documentation [COMPLETE]
```

However, the summary file at `/home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/summaries/002_phase_1_foundation_partial_implementation.md` clearly states:

```markdown
## Work Status
**Completion: 15%** (Directory structure + Registry module complete)
...
### Phase 1 (Foundation - Modular Architecture) [IN PROGRESS]
- **Completed**: 15% (Registry module + tests)
- **Remaining**: 85% (9 modules + tests + integration)
```

### Expected Behavior
Phase status markers should only be marked `[COMPLETE]` when:
1. ALL tasks in the phase have `- [x]` checkboxes
2. Phase tests have passed
3. Git commit has been created
4. No work remains in that phase

## Root Cause Analysis

### 1. Status Marker Infrastructure

**Location**: `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh`

The checkbox utilities library provides these functions:
- `add_complete_marker(plan_path, phase_num)` - Adds `[COMPLETE]` marker to phase heading
- `verify_phase_complete(plan_path, phase_num)` - Checks if all tasks in phase are complete
- `check_all_phases_complete(plan_path)` - Checks if all phases have `[COMPLETE]` marker

**Key Finding**: The `add_complete_marker()` function does NOT call `verify_phase_complete()` before adding the marker. It simply adds the marker unconditionally.

```bash
# From checkbox-utils.sh line 472
add_complete_marker() {
  local plan_path="$1"
  local phase_num="$2"

  # First remove any existing status marker
  remove_status_marker "$plan_path" "$phase_num"

  # Add [COMPLETE] marker to phase heading
  # NO VALIDATION THAT TASKS ARE ACTUALLY COMPLETE
  local temp_file=$(mktemp)
  awk -v phase="$phase_num" '
    /^### Phase / {
      phase_field = $3
      gsub(/:/, "", phase_field)
      if (phase_field == phase && !/\[COMPLETE\]/) {
        sub(/$/, " [COMPLETE]")
      }
      print
      next
    }
    { print }
  ' "$plan_path" > "$temp_file"

  mv "$temp_file" "$plan_path"
  return 0
}
```

### 2. How Status Markers Are Applied

**Build Command Integration**: `/home/benjamin/.config/.claude/commands/build.md`

The build command calls `add_complete_marker()` after phase execution:

```bash
# Line 437-438
if add_complete_marker "$PLAN_FILE" "$phase_num" 2>/dev/null; then
  echo "Phase $phase_num marked as [COMPLETE]"
fi
```

**Implementation-Executor Agent**: `/home/benjamin/.config/.claude/agents/implementation-executor.md`

The implementation-executor agent:
1. Executes tasks within a phase
2. Marks individual tasks with `- [x]` using Edit tool
3. Invokes spec-updater to propagate checkbox updates
4. Creates git commit if tests pass
5. Returns `PHASE_COMPLETE` report

**Critical Gap**: The agent returns a `PHASE_COMPLETE` report even when context exhaustion occurs mid-phase. The report includes `context_exhausted: true` and `work_remaining: [list]`, but the calling code may still mark the phase as `[COMPLETE]`.

### 3. Summary File Work Status

**Implementation-Executor Summary Generation**: Lines 154-198

The implementation-executor generates summaries with accurate work status:

```markdown
## Work Status
**Completion**: [XX]% complete
**Continuation Required**: [Yes/No]

### Work Remaining
[ONLY if incomplete - placed prominently for immediate visibility]
- [ ] Phase N: [Phase Name] - [specific task description]
```

**Key Requirement** (Line 209):
> ONLY state "100% complete" when ALL tasks in ALL phases have [x]

**Reality**: Summary files correctly report partial completion, but plan files incorrectly show `[COMPLETE]` markers.

### 4. The Disconnection

There is NO synchronization mechanism that:
1. Reads summary file work status
2. Compares it to plan file phase markers
3. Removes `[COMPLETE]` markers from incomplete phases
4. Validates task checkboxes match status markers

**Standards Documentation**: `/home/benjamin/.config/.claude/docs/reference/standards/plan-progress.md`

The plan progress standards document describes the status marker lifecycle but does NOT require validation before applying `[COMPLETE]`:

```markdown
### /build Command

1. **Phase Start**: Calls `add_in_progress_marker()` for starting phase
2. **Phase Complete**: Calls `add_complete_marker()` for finished phases
```

No mention of calling `verify_phase_complete()` before `add_complete_marker()`.

## Why This Happened

### Timeline of Events

1. **Phase 1 Execution Started**: Implementation-executor began working on Phase 1
2. **Partial Work Completed**: Registry module and tests completed (15%)
3. **Context Exhaustion**: Executor detected 70% context usage
4. **Summary Generated**: Summary correctly reported 15% completion with work remaining
5. **Status Marker Added**: Someone/something called `add_complete_marker()` for Phase 1
6. **Phases 2-4 Marked**: All subsequent phases also marked `[COMPLETE]`

### Probable Cause

Looking at the plan file structure, this appears to be a **Level 1** plan (phases in separate files). The status markers may have been:

1. **Manually added** by someone reviewing the plan structure
2. **Added by a script** that didn't check task completion
3. **Carried over** from a plan template that had `[COMPLETE]` markers
4. **Added by an agent** that misunderstood the completion state

The fact that ALL phases show `[COMPLETE]` (not just Phase 1) suggests this was a bulk operation, not incremental marking during execution.

### Infrastructure Gap

The real issue is that the infrastructure **allows** this to happen. There's no validation layer that:
- Prevents `add_complete_marker()` when tasks are incomplete
- Warns when summary file contradicts plan markers
- Validates status markers on plan file operations

## Impact Assessment

### Severity: CRITICAL

**User Impact**:
- Users cannot trust plan file status markers
- Must read summary files to understand actual progress
- Risk of resuming work from wrong point
- Confusion about what's actually been done

**System Impact**:
- Breaks single source of truth principle
- Plan files misrepresent implementation state
- Summary files become the only reliable source
- Status markers lose their purpose

**Workflow Impact**:
- `/build` command may skip phases thinking they're complete
- Auto-resume logic may miscalculate starting phase
- Progress tracking dashboards show incorrect status

### Affected Components

1. **checkbox-utils.sh** - Core status marker functions lack validation
2. **build.md** - Calls `add_complete_marker()` without verification
3. **implementation-executor.md** - Returns completion status but doesn't validate markers
4. **spec-updater.md** - Propagates markers without validation
5. **Plan files** - Display incorrect status
6. **Summary files** - Only reliable source of truth (currently)

## Proposed Solution

### Design Principles

1. **Validation Before Marking**: Never add `[COMPLETE]` without verifying all tasks are done
2. **Summary as Source of Truth**: Summary work status overrides plan markers if conflict exists
3. **Backward Compatibility**: Don't break existing workflows
4. **Clear Error Messages**: When validation fails, explain why
5. **Integration Points**: Minimal changes to existing infrastructure

### Solution Architecture

#### Component 1: Enhanced `add_complete_marker()` Function

**File**: `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh`

**Changes**:
```bash
add_complete_marker() {
  local plan_path="$1"
  local phase_num="$2"
  local force="${3:-false}"  # Optional force flag for manual overrides

  if [[ ! -f "$plan_path" ]]; then
    error "Plan file not found: $plan_path"
    return 1
  fi

  # VALIDATION: Check if phase is actually complete (unless forced)
  if [[ "$force" != "true" ]]; then
    if ! verify_phase_complete "$plan_path" "$phase_num"; then
      # Get count of incomplete tasks
      local incomplete_count
      incomplete_count=$(awk -v phase="$phase_num" '
        /^### Phase / {
          phase_field = $3
          gsub(/:/, "", phase_field)
          if (phase_field == phase) {
            in_phase = 1
          } else if (in_phase) {
            in_phase = 0
          }
          next
        }
        /^## / && in_phase {
          in_phase = 0
          next
        }
        in_phase && /^[[:space:]]*- \[[ ]\]/ {
          count++
        }
        END { print count+0 }
      ' "$plan_path")

      if type warn &>/dev/null; then
        warn "Cannot mark Phase $phase_num as COMPLETE: $incomplete_count tasks remain incomplete"
        warn "Use 'add_complete_marker \$plan_path $phase_num true' to force (not recommended)"
      else
        echo "WARNING: Cannot mark Phase $phase_num as COMPLETE: $incomplete_count tasks incomplete" >&2
      fi
      return 1
    fi
  fi

  # Validation passed or forced - proceed with marker addition
  remove_status_marker "$plan_path" "$phase_num"

  local temp_file=$(mktemp)
  awk -v phase="$phase_num" '
    /^### Phase / {
      phase_field = $3
      gsub(/:/, "", phase_field)
      if (phase_field == phase && !/\[COMPLETE\]/) {
        sub(/$/, " [COMPLETE]")
      }
      print
      next
    }
    { print }
  ' "$plan_path" > "$temp_file"

  mv "$temp_file" "$plan_path"
  return 0
}
```

**Benefits**:
- Prevents false `[COMPLETE]` markers
- Provides clear error messages
- Maintains backward compatibility with force flag
- Uses existing `verify_phase_complete()` function

#### Component 2: Status Validation Utility

**File**: `/home/benjamin/.config/.claude/lib/plan/status-validation.sh` (NEW)

**Purpose**: Validate plan status against summary files and task checkboxes

```bash
#!/usr/bin/env bash
# status-validation.sh
#
# Validates plan file status markers against actual task completion
# and summary file work status

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/base-utils.sh"
source "$SCRIPT_DIR/checkbox-utils.sh"

# Validate all phase status markers in a plan file
# Returns: 0 if all valid, 1 if inconsistencies found
validate_plan_status() {
  local plan_path="$1"

  if [[ ! -f "$plan_path" ]]; then
    error "Plan file not found: $plan_path"
    return 1
  fi

  # Extract all phase numbers and their status markers
  local inconsistent=0

  while IFS=: read -r phase_line; do
    # Extract phase number
    local phase_num=$(echo "$phase_line" | sed -E 's/### Phase ([0-9]+).*/\1/')

    # Check if marked COMPLETE
    if echo "$phase_line" | grep -q "\[COMPLETE\]"; then
      # Verify tasks are actually complete
      if ! verify_phase_complete "$plan_path" "$phase_num"; then
        local incomplete_count
        incomplete_count=$(awk -v phase="$phase_num" '
          /^### Phase / {
            phase_field = $3
            gsub(/:/, "", phase_field)
            if (phase_field == phase) {
              in_phase = 1
            } else if (in_phase) {
              in_phase = 0
            }
            next
          }
          /^## / && in_phase {
            in_phase = 0
            next
          }
          in_phase && /^[[:space:]]*- \[[ ]\]/ {
            count++
          }
          END { print count+0 }
        ' "$plan_path")

        warn "Phase $phase_num marked [COMPLETE] but has $incomplete_count incomplete tasks"
        inconsistent=1
      fi
    fi
  done < <(grep "^### Phase [0-9]" "$plan_path")

  return $inconsistent
}

# Synchronize plan status with summary file work status
# Returns: 0 on success, 1 on failure
sync_status_with_summary() {
  local plan_path="$1"
  local summary_path="$2"

  if [[ ! -f "$summary_path" ]]; then
    warn "Summary file not found: $summary_path (skipping sync)"
    return 0
  fi

  # Parse work remaining from summary
  local work_remaining_section
  work_remaining_section=$(awk '
    /^### Work Remaining/ { in_section=1; next }
    /^### / && in_section { exit }
    in_section && /^- \[ \] Phase [0-9]+:/ { print }
  ' "$summary_path")

  if [[ -z "$work_remaining_section" ]]; then
    # No work remaining - all phases should be complete
    return 0
  fi

  # Extract incomplete phase numbers from work remaining
  local incomplete_phases
  incomplete_phases=$(echo "$work_remaining_section" | \
    sed -E 's/^- \[ \] Phase ([0-9]+):.*/\1/' | \
    sort -u)

  # For each incomplete phase, ensure it's not marked COMPLETE
  while read -r phase_num; do
    [[ -z "$phase_num" ]] && continue

    # Check if phase is marked COMPLETE in plan
    if grep -q "^### Phase $phase_num:.*\[COMPLETE\]" "$plan_path"; then
      log "Removing incorrect [COMPLETE] marker from Phase $phase_num (work remaining per summary)"
      remove_status_marker "$plan_path" "$phase_num"
      add_in_progress_marker "$plan_path" "$phase_num"
    fi
  done <<< "$incomplete_phases"

  return 0
}

# Fix status markers in a plan file
# Removes COMPLETE markers from incomplete phases
fix_plan_status() {
  local plan_path="$1"

  if [[ ! -f "$plan_path" ]]; then
    error "Plan file not found: $plan_path"
    return 1
  fi

  echo "Validating and fixing status markers in: $(basename "$plan_path")"

  local fixed_count=0

  while IFS=: read -r phase_line; do
    local phase_num=$(echo "$phase_line" | sed -E 's/### Phase ([0-9]+).*/\1/')

    if echo "$phase_line" | grep -q "\[COMPLETE\]"; then
      if ! verify_phase_complete "$plan_path" "$phase_num"; then
        log "Removing incorrect [COMPLETE] marker from Phase $phase_num"
        remove_status_marker "$plan_path" "$phase_num"
        add_in_progress_marker "$plan_path" "$phase_num"
        ((fixed_count++))
      fi
    fi
  done < <(grep "^### Phase [0-9]" "$plan_path")

  if [[ $fixed_count -gt 0 ]]; then
    echo "Fixed $fixed_count incorrect status markers"
  else
    echo "All status markers are accurate"
  fi

  return 0
}

export -f validate_plan_status
export -f sync_status_with_summary
export -f fix_plan_status
```

#### Component 3: Build Command Integration

**File**: `/home/benjamin/.config/.claude/commands/build.md`

**Change at Line 437-438**:

```bash
# OLD (no validation):
if add_complete_marker "$PLAN_FILE" "$phase_num" 2>/dev/null; then
  echo "Phase $phase_num marked as [COMPLETE]"
fi

# NEW (with validation):
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/status-validation.sh" 2>/dev/null

if add_complete_marker "$PLAN_FILE" "$phase_num" 2>/dev/null; then
  echo "Phase $phase_num marked as [COMPLETE]"
else
  # Validation failed - phase has incomplete tasks
  echo "NOTE: Phase $phase_num has incomplete tasks - keeping status as [IN PROGRESS]"
  # Ensure it's marked IN PROGRESS (not COMPLETE)
  add_in_progress_marker "$PLAN_FILE" "$phase_num" 2>/dev/null || true
fi
```

#### Component 4: Status Repair Command

**File**: `/home/benjamin/.config/.claude/commands/fix-plan-status.md` (NEW)

**Purpose**: Command to repair incorrect status markers in plans

```markdown
---
allowed-tools: Bash, Read, Edit, Grep, Glob
argument-hint: [plan-file]
description: Fix incorrect status markers in plan files by validating against task completion
command-type: utility
---

# /fix-plan-status - Plan Status Repair Command

Validates and repairs status markers in plan files that don't match actual task completion.

## Usage

```bash
/fix-plan-status [plan-file]
```

If no plan file specified, finds most recent plan in specs/ directory.

## What It Does

1. Reads plan file and extracts all phase status markers
2. For each phase marked [COMPLETE], verifies all tasks have [x] checkboxes
3. If incomplete tasks found, removes [COMPLETE] and adds [IN PROGRESS]
4. Reports number of fixes applied

## Example

```bash
$ /fix-plan-status specs/859_topic/plans/001_plan.md

Validating and fixing status markers in: 001_plan.md
Removing incorrect [COMPLETE] marker from Phase 1
Removing incorrect [COMPLETE] marker from Phase 2
Removing incorrect [COMPLETE] marker from Phase 3
Removing incorrect [COMPLETE] marker from Phase 4
Fixed 4 incorrect status markers
```

## Implementation

Execute this bash block:

```bash
set -e

# Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

export CLAUDE_PROJECT_DIR

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/base-utils.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/status-validation.sh" 2>/dev/null

# Parse arguments
PLAN_FILE="${1:-}"

if [ -z "$PLAN_FILE" ]; then
  # Auto-detect most recent plan
  PLAN_FILE=$(find "$CLAUDE_PROJECT_DIR/.claude/specs" -path "*/plans/*_plan.md" -type f -exec ls -t {} + 2>/dev/null | head -1)

  if [ -z "$PLAN_FILE" ]; then
    echo "ERROR: No plan file found in specs/*/plans/" >&2
    exit 1
  fi

  echo "Auto-detected plan: $(basename "$PLAN_FILE")"
fi

if [ ! -f "$PLAN_FILE" ]; then
  echo "ERROR: Plan file not found: $PLAN_FILE" >&2
  exit 1
fi

# Fix status markers
fix_plan_status "$PLAN_FILE"
```
```

#### Component 5: Documentation Updates

**File**: `/home/benjamin/.config/.claude/docs/reference/standards/plan-progress.md`

**Add section after "Implementation Functions"**:

```markdown
## Status Marker Validation

### Validation Requirement

As of 2025-11-20, the `add_complete_marker()` function validates that all tasks in a phase are actually complete before adding the `[COMPLETE]` marker.

**Validation Logic**:
1. Calls `verify_phase_complete()` to check all checkboxes
2. If incomplete tasks found, refuses to add marker
3. Provides warning with count of incomplete tasks
4. Returns error code 1 (marker not added)

**Force Override**:
```bash
# Normal usage (validates):
add_complete_marker "$PLAN_FILE" "1"  # May fail if tasks incomplete

# Force override (skips validation):
add_complete_marker "$PLAN_FILE" "1" true  # Always succeeds (not recommended)
```

**When to Use Force**:
- Manual plan cleanup
- Intentionally skipping incomplete phases
- Test/demo plans

**When NOT to Use Force**:
- Normal /build workflows
- Automated processes
- Production implementations

### Status Repair

If plan files have incorrect status markers:

```bash
# Automatic repair
/fix-plan-status plan.md

# Manual validation
source .claude/lib/plan/status-validation.sh
validate_plan_status "plan.md"

# Sync with summary file
sync_status_with_summary "plan.md" "summaries/001_summary.md"
```

### Best Practices

1. **Let validation work**: Don't force-override unless necessary
2. **Check warnings**: If `add_complete_marker()` fails, investigate why
3. **Trust summaries**: If summary shows work remaining, phase isn't complete
4. **Use repair command**: Run `/fix-plan-status` if markers seem wrong
5. **Validate before merging**: Always check status markers match task completion
```

## Implementation Phases

### Phase 1: Immediate Fix (Current Plan)
**Duration**: 1 hour

1. Create `/fix-plan-status` command
2. Run on affected plan: `specs/859_*/plans/001_*_plan.md`
3. Verify status markers corrected
4. Document the issue and fix

### Phase 2: Enhanced Validation (Short-term)
**Duration**: 3 hours

1. Update `add_complete_marker()` with validation logic
2. Create `status-validation.sh` library
3. Update build command integration
4. Test with existing plans
5. Update documentation

### Phase 3: Systematic Prevention (Long-term)
**Duration**: 2 hours

1. Add validation to spec-updater agent
2. Add validation to implementation-executor agent
3. Create validation tests
4. Add to pre-commit hooks (optional)
5. Monitor for regressions

## Testing Strategy

### Test Cases

1. **Valid COMPLETE Marker**
   - Phase with all tasks `[x]`
   - `add_complete_marker()` succeeds
   - Marker added successfully

2. **Invalid COMPLETE Marker**
   - Phase with incomplete tasks `[ ]`
   - `add_complete_marker()` fails
   - Warning message displayed
   - No marker added

3. **Force Override**
   - Phase with incomplete tasks
   - `add_complete_marker(plan, phase, true)` succeeds
   - Marker added despite incomplete tasks

4. **Status Repair**
   - Plan with incorrect COMPLETE markers
   - `fix_plan_status()` removes incorrect markers
   - Adds IN PROGRESS markers instead

5. **Summary Sync**
   - Plan has COMPLETE, summary shows work remaining
   - `sync_status_with_summary()` removes COMPLETE
   - Adds IN PROGRESS for affected phases

### Regression Tests

Create test suite at `/home/benjamin/.config/.claude/tests/test_status_validation.sh`:

```bash
#!/usr/bin/env bash
# Test status validation functions

test_add_complete_marker_with_validation() {
  # Create test plan with incomplete tasks
  # Call add_complete_marker
  # Assert: Returns 1 (failure)
  # Assert: No COMPLETE marker added
}

test_fix_plan_status() {
  # Create plan with incorrect COMPLETE markers
  # Call fix_plan_status
  # Assert: COMPLETE markers removed
  # Assert: IN PROGRESS markers added
}

test_sync_with_summary() {
  # Create plan with COMPLETE, summary with work remaining
  # Call sync_status_with_summary
  # Assert: COMPLETE removed, IN PROGRESS added
}
```

## Rollout Plan

### Step 1: Immediate Repair (Today)
- Create and run `/fix-plan-status` on affected plan
- Verify status markers now match summary file
- Document the issue in this report

### Step 2: Infrastructure Update (This Week)
- Implement enhanced `add_complete_marker()` with validation
- Create `status-validation.sh` library
- Update build command integration
- Test with existing workflows

### Step 3: Documentation (This Week)
- Update plan-progress.md with validation requirements
- Add troubleshooting section
- Update build-command-guide.md
- Add examples to relevant guides

### Step 4: Testing (Next Week)
- Create comprehensive test suite
- Run regression tests on existing plans
- Monitor for validation failures in production
- Adjust thresholds if needed

### Step 5: Monitoring (Ongoing)
- Track validation failures in error logs
- Review false positives/negatives
- Adjust validation logic as needed
- Update documentation based on learnings

## Success Criteria

1. **Correctness**: Status markers only added when tasks are actually complete
2. **Clarity**: Clear error messages when validation fails
3. **Compatibility**: Existing workflows continue working
4. **Reliability**: Plan files become single source of truth again
5. **Usability**: Users can trust status markers

## Risks and Mitigations

### Risk: Breaking Existing Workflows
**Mitigation**: Add validation only to new calls; existing force flag allows overrides

### Risk: False Validation Failures
**Mitigation**: Use existing `verify_phase_complete()` function that's already battle-tested

### Risk: Summary File Conflicts
**Mitigation**: Summary sync is optional tool, not automatic; users control when to use it

### Risk: Performance Impact
**Mitigation**: Validation is simple AWK script, adds <10ms per phase

## Related Issues

This bug is related to but distinct from:
- Checkbox propagation in hierarchical plans (working correctly)
- Summary file generation (working correctly)
- Plan metadata status field (separate from phase markers)

The issue is specifically about **phase status markers** not being validated before application.

## Conclusion

The root cause is clear: status markers are added without validation. The fix is straightforward: add validation logic to the marker functions.

The infrastructure exists (`verify_phase_complete()`), it just isn't being called. Adding this call with appropriate error handling will prevent future occurrences while maintaining backward compatibility.

**Immediate Action**: Run `/fix-plan-status` on the affected plan to correct current status.

**Long-term Solution**: Implement validation in `add_complete_marker()` to prevent future occurrences.
