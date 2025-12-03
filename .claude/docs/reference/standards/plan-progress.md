# Plan Progress Tracking

This document describes the plan progress tracking system that provides visibility into phase execution status throughout the implementation lifecycle.

## Overview

Plan progress tracking uses status markers on phase headings to indicate execution state. This system enables:

- Visual tracking of implementation progress
- Clear identification of current work
- Automatic state management by /build command
- Legacy plan compatibility

## Status Marker Lifecycle

Plans progress through three primary states:

```
[NOT STARTED] --> [IN PROGRESS] --> [COMPLETE]
```

### Marker Descriptions

| Marker | Applied By | When Applied |
|--------|------------|--------------|
| `[NOT STARTED]` | plan-architect agent (plan creation) or /implement Block 1a (legacy compatibility) | Plan creation or initialization |
| `[IN PROGRESS]` | implementation-executor agent (STEP 1) | Phase execution begins |
| `[COMPLETE]` | implementation-executor agent (STEP 3) or /implement Block 1d (recovery) | Phase execution ends successfully |
| `[BLOCKED]` | /build command | Phase cannot proceed due to failures |
| `[SKIPPED]` | User/Agent | Phase intentionally skipped |

## Visual Example

### Plan Creation (by /plan command)

```markdown
### Phase 1: Setup [NOT STARTED]
### Phase 2: Implementation [NOT STARTED]
### Phase 3: Testing [NOT STARTED]
```

### During Phase 1 Execution

```markdown
### Phase 1: Setup [IN PROGRESS]
### Phase 2: Implementation [NOT STARTED]
### Phase 3: Testing [NOT STARTED]
```

### After Phase 1 Completes

```markdown
### Phase 1: Setup [COMPLETE]
### Phase 2: Implementation [IN PROGRESS]
### Phase 3: Testing [NOT STARTED]
```

### After Phase 2 Completes

```markdown
### Phase 1: Setup [COMPLETE]
### Phase 2: Implementation [COMPLETE]
### Phase 3: Testing [IN PROGRESS]
```

### After All Phases Complete

```markdown
### Phase 1: Setup [COMPLETE]
### Phase 2: Implementation [COMPLETE]
### Phase 3: Testing [COMPLETE]
```

## Implementation Functions

The following functions in `checkbox-utils.sh` manage progress markers:

### Core Functions

#### `remove_status_marker(plan_path, phase_num)`

Removes any status marker from a phase heading.

```bash
remove_status_marker "$PLAN_FILE" "1"
# Before: ### Phase 1: Setup [IN PROGRESS]
# After:  ### Phase 1: Setup
```

#### `add_in_progress_marker(plan_path, phase_num)`

Adds [IN PROGRESS] marker, automatically removing any existing marker.

```bash
add_in_progress_marker "$PLAN_FILE" "1"
# Before: ### Phase 1: Setup [NOT STARTED]
# After:  ### Phase 1: Setup [IN PROGRESS]
```

#### `add_complete_marker(plan_path, phase_num)`

Adds [COMPLETE] marker, automatically removing any existing marker.

```bash
add_complete_marker "$PLAN_FILE" "1"
# Before: ### Phase 1: Setup [IN PROGRESS]
# After:  ### Phase 1: Setup [COMPLETE]
```

#### `add_not_started_markers(plan_path)`

Adds [NOT STARTED] to all phases without status markers. Used for legacy plan compatibility.

```bash
add_not_started_markers "$PLAN_FILE"
# Before: ### Phase 1: Setup
# After:  ### Phase 1: Setup [NOT STARTED]
```

### Hierarchy Functions

#### `propagate_progress_marker(plan_path, phase_num, status)`

Propagates status changes through Level 1/2 plan hierarchies.

```bash
propagate_progress_marker "$PLAN_FILE" "2" "IN PROGRESS"
# Updates both phase_2.md and main plan file
```

## Integration Points

### /plan Command

The plan-architect agent includes `[NOT STARTED]` markers when generating plans:

```markdown
### Phase 1: Foundation [NOT STARTED]
dependencies: []

**Objective**: [Goal]
**Complexity**: Low
```

### /implement and /build Commands

Both commands initialize and validate progress markers:

1. **Block 1a (Setup)**: Sources `checkbox-utils.sh` and calls `add_not_started_markers()` for legacy plan compatibility
2. **Block 1d (Validation)**: Validates all phases have `[COMPLETE]` markers and recovers any missing markers

### implementation-executor Agent

The implementation-executor agent is responsible for real-time marker updates during phase execution:

**Phase Start (STEP 1)**:
```bash
# Source checkbox utilities
source "$CLAUDE_LIB/plan/checkbox-utils.sh" 2>/dev/null || {
    echo "Warning: Cannot load checkbox-utils.sh, progress tracking disabled"
    PROGRESS_TRACKING_ENABLED=false
}

# Mark phase in progress
if [[ "$PROGRESS_TRACKING_ENABLED" != "false" ]]; then
    add_in_progress_marker "$PLAN_FILE" "$PHASE_NUM" 2>/dev/null || {
        echo "Warning: Failed to mark Phase $PHASE_NUM as [IN PROGRESS]"
    }
fi
```

**Phase End (STEP 3)**:
```bash
# Mark phase complete
if [[ "$PROGRESS_TRACKING_ENABLED" != "false" ]]; then
    add_complete_marker "$PLAN_FILE" "$PHASE_NUM" 2>/dev/null || {
        echo "Warning: Failed to mark Phase $PHASE_NUM as [COMPLETE]"
        # Fallback to legacy mark_phase_complete (updates checkboxes only)
        mark_phase_complete "$PLAN_FILE" "$PHASE_NUM" 2>/dev/null || true
    }
fi
```

**Error Handling**:
- Marker update failures are non-fatal (logged as warnings)
- Execution continues even if marker updates fail
- Block 1d recovery ensures final plan state is correct

## Legacy Plan Compatibility

Plans created before progress tracking receive automatic marker addition:

```bash
# Detection in build.md
if grep -qE "^### Phase [0-9]+:" "$PLAN_FILE" && \
   ! grep -qE "^### Phase.*\[(NOT STARTED|IN PROGRESS|COMPLETE)\]" "$PLAN_FILE"; then
  add_not_started_markers "$PLAN_FILE"
fi
```

This ensures all plans benefit from progress tracking without manual updates.

## Usage Patterns

### Monitoring Progress

```bash
# View current phase status
grep "^### Phase" plan.md

# Count completed phases
grep -c "\[COMPLETE\]" plan.md

# Find current phase
grep "\[IN PROGRESS\]" plan.md
```

### Manual Status Updates

While typically managed by /build, markers can be updated manually:

```bash
source .claude/lib/plan/checkbox-utils.sh
add_in_progress_marker "plan.md" "3"
```

## Best Practices

1. **Always use plan-architect**: Ensure new plans have `[NOT STARTED]` markers
2. **Let /build manage transitions**: Avoid manual marker updates during builds
3. **Check for legacy plans**: The /build command handles this automatically
4. **Use markers for visibility**: Quickly identify current work status

## Troubleshooting

### Missing Markers

If phases lack status markers:

```bash
source .claude/lib/plan/checkbox-utils.sh
add_not_started_markers "plan.md"
```

### Duplicate Markers

The `remove_status_marker()` function is called automatically before adding new markers, preventing duplicates.

### Marker Not Updating

Verify checkbox-utils.sh is sourced correctly:

```bash
source .claude/lib/plan/checkbox-utils.sh
type add_in_progress_marker  # Should show function
```

## Related Documentation

- [Build Command Guide](../guides/commands/build-command-guide.md) - Complete build workflow
- [Workflow Phases Planning](workflow-phases-planning.md) - Phase structure standards
- [Checkbox Utils Library](library-api-utilities.md) - Full function reference
