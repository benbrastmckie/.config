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
| `[NOT STARTED]` | plan-architect agent | Plan creation |
| `[IN PROGRESS]` | /build command | Phase execution begins |
| `[COMPLETE]` | /build command | Phase execution ends successfully |
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

### /build Command

The build command manages marker transitions:

1. **Startup**: Sources `checkbox-utils.sh`
2. **Legacy Detection**: Adds `[NOT STARTED]` to unmarked phases
3. **Phase Start**: Calls `add_in_progress_marker()` for starting phase
4. **Phase Complete**: Calls `add_complete_marker()` for finished phases

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
