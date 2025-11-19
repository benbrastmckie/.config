# Plan Metadata Update Patterns Research Report

## Metadata
- **Date**: 2025-11-18
- **Agent**: research-specialist
- **Topic**: Plan metadata updates during /build command execution
- **Report Type**: codebase analysis

## Executive Summary

The /build command already has partial infrastructure for updating plan metadata with `[COMPLETE]` markers and checkbox updates, but lacks `[IN PROGRESS]` status tracking. The checkbox-utils.sh library provides `mark_phase_complete()` and `add_complete_marker()` functions, and the build command invokes these after implementation phases complete. However, there is no mechanism to mark phases as `[IN PROGRESS]` when they begin execution, and documentation standards in .claude/docs/ do not currently specify these progress tracking patterns.

## Findings

### 1. Current /build Command Implementation

**File**: `/home/benjamin/.config/.claude/commands/build.md`

The /build command already includes phase update functionality (lines 303-371):

```bash
# Mark phases complete using checkbox-utils.sh
for phase_num in $(seq 1 "$COMPLETED_PHASE_COUNT"); do
  echo "Marking Phase $phase_num complete..."

  # Try to mark phase complete using checkbox-utils.sh
  if mark_phase_complete "$PLAN_FILE" "$phase_num" 2>/dev/null; then
    echo "  Checkboxes marked complete"

    # Add [COMPLETE] marker to phase heading
    if add_complete_marker "$PLAN_FILE" "$phase_num" 2>/dev/null; then
      echo "  [COMPLETE] marker added"
    fi
  fi
done
```

**Gap Identified**: No `[IN PROGRESS]` markers are added when phases begin execution. The command only marks completion after all phases finish.

### 2. Checkbox-Utils Library Functions

**File**: `/home/benjamin/.config/.claude/lib/checkbox-utils.sh`

Key functions available:

1. **mark_phase_complete()** (lines 176-266): Marks all checkboxes in a phase as `[x]`
2. **add_complete_marker()** (lines 335-361): Adds `[COMPLETE]` to phase heading
3. **verify_phase_complete()** (lines 364-402): Verifies all tasks in phase are checked
4. **verify_checkbox_consistency()** (lines 128-173): Verifies hierarchy synchronization

**Missing Functions**:
- `add_in_progress_marker()`: To add `[IN PROGRESS]` to active phase
- `remove_progress_marker()`: To remove markers when status changes
- `update_phase_status()`: Generic function for any status marker

### 3. Existing Plan Metadata Structure

**File**: `/home/benjamin/.config/.claude/specs/790_fix_state_machine_transition_error_build_command/plans/001_fix_state_machine_transition_error_build_plan.md`

Current metadata pattern (lines 1-16):
```markdown
# Fix State Machine Transition Error in Build Command Implementation Plan

## Metadata
- **Date**: 2025-11-18
- **Feature**: Fix state machine transition error (implement -> complete)
- **Scope**: Build command state transitions across all 4 bash blocks
- **Estimated Phases**: 4
- **Estimated Hours**: 3.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 15
- **Research Reports**:
  - [State Machine Transition Error Analysis](../reports/001_state_machine_transition_error.md)
```

**Phase Structure** (lines 117-131):
```markdown
### Phase 1: Add State Validation After Load [COMPLETE]
dependencies: []

**Objective**: Add explicit validation that CURRENT_STATE was properly loaded

**Complexity**: Low

Tasks:
- [x] Add `set -e` for fail-fast behavior...
```

**Observation**: The `[COMPLETE]` marker is already used in phase headings. The infrastructure exists but needs to be extended for `[IN PROGRESS]` tracking.

### 4. Documentation Standards Analysis

**File**: `/home/benjamin/.config/.claude/docs/guides/build-command-guide.md` (lines 104-135)

The build-command-guide.md already documents the phase update mechanism:

```markdown
### Phase Update Mechanism

After the implementer-coordinator completes all phases, the build command automatically marks phases as complete in the plan file:

1. **Checkbox Updates**: All task checkboxes in completed phases are marked `[x]`
2. **[COMPLETE] Markers**: Phase headings receive `[COMPLETE]` suffix (e.g., `### Phase 1: Setup [COMPLETE]`)
3. **Hierarchy Synchronization**: Updates propagate to phase files and stage files in expanded plans (Level 1/2)
4. **Verification**: Checkbox consistency is verified after updates
```

**Gap**: No documentation for `[IN PROGRESS]` markers or when to apply them during execution.

### 5. Related Standards Documentation

**File**: `/home/benjamin/.config/.claude/docs/reference/workflow-phases-planning.md` (lines 141-175)

Documents expected plan format with checkbox structure but no mention of progress status markers:

```markdown
### Phase 1: Core Infrastructure
- **Dependencies**: []
- **Tasks**:
  - [ ] Create base module
  - [ ] Setup configuration

### Phase 2: Main Feature
- **Dependencies**: ["Phase 1"]
- **Tasks**:
  - [ ] Implement core logic
```

**File**: `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md`

Comprehensive artifact organization but no specific guidance on plan progress tracking patterns.

### 6. Existing Progress Tracking Research

**File**: `/home/benjamin/.config/.claude/specs/23_in_addition_to_committing_changes_after_phases_are/reports/002_plan_structure_and_update_mechanisms.md`

Prior research already proposed the pattern (lines 682-727):

```markdown
## [COMPLETE] Heading Markers

### Current Usage

**Not Currently Implemented** in /build command.

### Proposed Implementation

**Phase Heading Markers**:
```markdown
### Phase 1: Setup [COMPLETE]
### Phase 2: Implementation [IN_PROGRESS]
### Phase 3: Testing
```
```

This report also proposes the `update_phase_heading_status()` function (lines 698-718):

```bash
update_phase_heading_status() {
  local plan_file="$1"
  local phase_num="$2"
  local status="$3"  # COMPLETE, IN_PROGRESS, BLOCKED, SKIPPED

  # Remove existing status markers first
  sed -i "s/^### Phase ${phase_num}: \[.*\]/### Phase ${phase_num}:/" "$plan_file"

  # Add new status marker
  sed -i "s/^### Phase ${phase_num}:/### Phase ${phase_num}: [${status}]/" "$plan_file"
}
```

### 7. Parent Plan Update Patterns

The codebase supports hierarchical plan updates (Level 0/1/2):

**Level 0**: Single file - direct updates to main plan
**Level 1**: Phase expansion - updates to phase files + main plan
**Level 2**: Stage expansion - updates to stage files + phase files + main plan

The `propagate_checkbox_update()` function (checkbox-utils.sh lines 72-126) handles this propagation automatically when given the plan path and phase number.

### 8. Implementation Integration Points

**Before Phase Execution** (should add IN PROGRESS):
- Location: After implementer-coordinator agent invocation, before actual phase work begins
- File: build.md Block 1, line 200-239 (Task invocation to implementer-coordinator)

**After Phase Completion** (already adds COMPLETE):
- Location: Post-implementation checkbox update block
- File: build.md lines 303-371

**Missing**: The implementer-coordinator agent should update plan status to `[IN PROGRESS]` as it begins each phase.

## Recommendations

### 1. Extend checkbox-utils.sh with Progress Marker Functions

Add to `/home/benjamin/.config/.claude/lib/checkbox-utils.sh`:

```bash
# Add [IN PROGRESS] marker to phase heading
# Usage: add_in_progress_marker <plan_path> <phase_num>
add_in_progress_marker() {
  local plan_path="$1"
  local phase_num="$2"

  if [[ ! -f "$plan_path" ]]; then
    error "Plan file not found: $plan_path"
  fi

  # Remove any existing status markers first
  local temp_file=$(mktemp)
  awk -v phase="$phase_num" '
    /^### Phase / {
      phase_field = $3
      gsub(/:/, "", phase_field)
      if (phase_field == phase) {
        # Remove existing markers
        gsub(/\s*\[(COMPLETE|IN PROGRESS|BLOCKED|SKIPPED)\]/, "")
        # Add IN PROGRESS marker
        sub(/$/, " [IN PROGRESS]")
      }
      print
      next
    }
    { print }
  ' "$plan_path" > "$temp_file"

  mv "$temp_file" "$plan_path"
  return 0
}

# Remove status marker from phase heading
# Usage: remove_status_marker <plan_path> <phase_num>
remove_status_marker() {
  local plan_path="$1"
  local phase_num="$2"

  local temp_file=$(mktemp)
  awk -v phase="$phase_num" '
    /^### Phase / {
      phase_field = $3
      gsub(/:/, "", phase_field)
      if (phase_field == phase) {
        gsub(/\s*\[(COMPLETE|IN PROGRESS|BLOCKED|SKIPPED)\]/, "")
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

### 2. Update /build Command for Progress Tracking

Modify `/home/benjamin/.config/.claude/commands/build.md` to mark phases as `[IN PROGRESS]` when they begin:

**In Block 1** (before implementer-coordinator invocation):
```bash
# Source checkbox utilities for progress tracking
source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkbox-utils.sh" 2>/dev/null

# Mark starting phase as IN PROGRESS
add_in_progress_marker "$PLAN_FILE" "$STARTING_PHASE"
```

**In implementer-coordinator agent prompt** (add instruction):
```markdown
**Progress Tracking**:
- Before starting each phase: source checkbox-utils.sh && add_in_progress_marker "$PLAN_PATH" $PHASE_NUM
- After completing each phase: mark_phase_complete and add_complete_marker
- Update parent plans if structure level > 0
```

### 3. Document Plan Metadata Update Standards

Create or update documentation in `/home/benjamin/.config/.claude/docs/reference/`:

**New File**: `plan-progress-tracking.md`

```markdown
# Plan Progress Tracking Standards

## Phase Status Markers

Plans support four status markers for phase headings:

| Marker | Meaning | When Applied |
|--------|---------|--------------|
| `[IN PROGRESS]` | Phase currently executing | Start of phase implementation |
| `[COMPLETE]` | Phase successfully finished | All tasks completed and verified |
| `[BLOCKED]` | Phase cannot proceed | Dependencies failed or blocked |
| `[SKIPPED]` | Phase intentionally skipped | Manual decision to skip |

## Usage Patterns

### Before Phase Execution
```bash
source .claude/lib/checkbox-utils.sh
add_in_progress_marker "$PLAN_FILE" "$PHASE_NUM"
```

### After Phase Completion
```bash
mark_phase_complete "$PLAN_FILE" "$PHASE_NUM"
add_complete_marker "$PLAN_FILE" "$PHASE_NUM"
```

### Hierarchy Updates

For Level 1/2 plans, status markers should be updated at all levels:
- Main plan phase summary
- Expanded phase file (if exists)

## Visual Example

```markdown
### Phase 1: Setup [COMPLETE]
- [x] Create project structure
- [x] Initialize dependencies

### Phase 2: Implementation [IN PROGRESS]
- [x] Create core module
- [ ] Add error handling

### Phase 3: Testing
- [ ] Unit tests
- [ ] Integration tests
```

## Implementation Functions

- `add_in_progress_marker()` - Mark phase as in progress
- `add_complete_marker()` - Mark phase as complete
- `remove_status_marker()` - Clear any status marker
- `mark_phase_complete()` - Mark all checkboxes in phase as complete
```

### 4. Update build-command-guide.md

Add to the Phase Update Mechanism section in `/home/benjamin/.config/.claude/docs/guides/build-command-guide.md`:

```markdown
### Progress Tracking During Execution

The build command tracks phase progress with status markers:

1. **[IN PROGRESS]**: Added to phase heading when phase begins execution
2. **[COMPLETE]**: Replaces IN PROGRESS when phase finishes successfully

**Workflow**:
```
### Phase 1: Setup              (not started)
### Phase 2: Implementation     (not started)

/build starts Phase 1:
### Phase 1: Setup [IN PROGRESS]
### Phase 2: Implementation

Phase 1 completes:
### Phase 1: Setup [COMPLETE]
### Phase 2: Implementation [IN PROGRESS]

Phase 2 completes:
### Phase 1: Setup [COMPLETE]
### Phase 2: Implementation [COMPLETE]
```
```

### 5. Add Tests for Progress Tracking

Create test file at `/home/benjamin/.config/.claude/tests/test_plan_progress_markers.sh`:

```bash
#!/usr/bin/env bash
# Test: Plan progress marker functions
# Coverage: IN PROGRESS and COMPLETE markers on phase headings

set -e

# Test isolation
setup_test_environment() {
  local test_dir=$(mktemp -d)
  export CLAUDE_PROJECT_DIR="$test_dir"
  mkdir -p "$test_dir/.claude/lib"
  cp /home/benjamin/.config/.claude/lib/checkbox-utils.sh "$test_dir/.claude/lib/"
  echo "$test_dir"
}

cleanup() {
  [ -n "${TEST_DIR:-}" ] && rm -rf "$TEST_DIR"
}
trap cleanup EXIT

test_add_in_progress_marker() {
  TEST_DIR=$(setup_test_environment)
  source "$TEST_DIR/.claude/lib/checkbox-utils.sh" 2>/dev/null

  # Create test plan
  cat > "$TEST_DIR/test_plan.md" <<'EOF'
### Phase 1: Setup

Tasks:
- [ ] Task 1
EOF

  add_in_progress_marker "$TEST_DIR/test_plan.md" "1"

  if grep -q "\[IN PROGRESS\]" "$TEST_DIR/test_plan.md"; then
    echo "PASS: add_in_progress_marker"
  else
    echo "FAIL: add_in_progress_marker"
    return 1
  fi
}

test_replace_in_progress_with_complete() {
  TEST_DIR=$(setup_test_environment)
  source "$TEST_DIR/.claude/lib/checkbox-utils.sh" 2>/dev/null

  # Create test plan with IN PROGRESS
  cat > "$TEST_DIR/test_plan.md" <<'EOF'
### Phase 1: Setup [IN PROGRESS]

Tasks:
- [ ] Task 1
EOF

  add_complete_marker "$TEST_DIR/test_plan.md" "1"

  if grep -q "\[COMPLETE\]" "$TEST_DIR/test_plan.md" && ! grep -q "\[IN PROGRESS\]" "$TEST_DIR/test_plan.md"; then
    echo "PASS: replace IN PROGRESS with COMPLETE"
  else
    echo "FAIL: replace IN PROGRESS with COMPLETE"
    return 1
  fi
}

main() {
  local failed=0
  echo "Running plan progress marker tests..."

  test_add_in_progress_marker || ((failed++))
  test_replace_in_progress_with_complete || ((failed++))

  if [ "$failed" -gt 0 ]; then
    echo "FAILED: $failed test(s)"
    exit 1
  fi
  echo "All tests passed"
}

main "$@"
```

## References

### Files Analyzed

- `/home/benjamin/.config/.claude/commands/build.md` - Build command implementation (lines 1-898)
- `/home/benjamin/.config/.claude/lib/checkbox-utils.sh` - Checkbox update utilities (lines 1-413)
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` - State persistence library (lines 1-499)
- `/home/benjamin/.config/.claude/specs/790_fix_state_machine_transition_error_build_command/plans/001_fix_state_machine_transition_error_build_plan.md` - Example plan with metadata structure (lines 1-591)
- `/home/benjamin/.config/.claude/docs/guides/build-command-guide.md` - Build command documentation (lines 1-599)
- `/home/benjamin/.config/.claude/docs/reference/workflow-phases-planning.md` - Planning workflow documentation (lines 1-226)
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` - Directory organization standards (lines 1-300)
- `/home/benjamin/.config/.claude/specs/23_in_addition_to_committing_changes_after_phases_are/reports/002_plan_structure_and_update_mechanisms.md` - Prior research on plan update mechanisms (lines 1-973)

### Key Line References

- **Build command phase updates**: build.md:303-371
- **add_complete_marker function**: checkbox-utils.sh:335-361
- **mark_phase_complete function**: checkbox-utils.sh:176-266
- **Proposed update_phase_heading_status**: 002_plan_structure_and_update_mechanisms.md:698-718
- **Plan metadata example**: 001_fix_state_machine_transition_error_build_plan.md:1-16
- **Phase update documentation**: build-command-guide.md:104-135

## Implementation Status

- **Status**: Planning Complete
- **Plan**: [001_standards_appropriately_to_include_these_plan.md](../plans/001_standards_appropriately_to_include_these_plan.md)
- **Implementation**: Pending
- **Date**: 2025-11-18
