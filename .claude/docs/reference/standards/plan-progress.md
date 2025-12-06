# Plan Progress Tracking

This document describes the plan progress tracking system that provides visibility into phase execution status throughout the implementation lifecycle.

## Overview

Plan progress tracking uses status markers on phase headings to indicate execution state. Phase headings can use either h2 format (`## Phase N: Name`) or h3 format (`### Phase N: Name`). Both formats are fully supported. This system enables:

- Visual tracking of implementation progress
- Clear identification of current work
- Automatic state management by /implement command
- Legacy plan compatibility
- Flexible heading level (h2 or h3)

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
| `[BLOCKED]` | /implement command | Phase cannot proceed due to failures |
| `[SKIPPED]` | User/Agent | Phase intentionally skipped |

## Visual Example

### H3 Format (Standard)

#### Plan Creation (by /plan command)

```markdown
### Phase 1: Setup [NOT STARTED]
### Phase 2: Implementation [NOT STARTED]
### Phase 3: Testing [NOT STARTED]
```

#### During Phase 1 Execution

```markdown
### Phase 1: Setup [IN PROGRESS]
### Phase 2: Implementation [NOT STARTED]
### Phase 3: Testing [NOT STARTED]
```

#### After All Phases Complete

```markdown
### Phase 1: Setup [COMPLETE]
### Phase 2: Implementation [COMPLETE]
### Phase 3: Testing [COMPLETE]
```

### H2 Format (Alternative)

#### Plan Creation

```markdown
## Phase 1: Setup [NOT STARTED]
## Phase 2: Implementation [NOT STARTED]
## Phase 3: Testing [NOT STARTED]
```

#### During Phase 1 Execution

```markdown
## Phase 1: Setup [IN PROGRESS]
## Phase 2: Implementation [NOT STARTED]
## Phase 3: Testing [NOT STARTED]
```

#### After All Phases Complete

```markdown
## Phase 1: Setup [COMPLETE]
## Phase 2: Implementation [COMPLETE]
## Phase 3: Testing [COMPLETE]
```

**Note**: Both h2 and h3 formats are fully supported. Heading level is flexible and can be chosen based on document structure preferences.

## Implementation Functions

The following functions in `checkbox-utils.sh` manage progress markers:

### Core Functions

#### `remove_status_marker(plan_path, phase_num)`

Removes any status marker from a phase heading. Works with both h2 and h3 formats.

```bash
remove_status_marker "$PLAN_FILE" "1"
# Before (h3): ### Phase 1: Setup [IN PROGRESS]
# After:       ### Phase 1: Setup
# Before (h2): ## Phase 1: Setup [IN PROGRESS]
# After:       ## Phase 1: Setup
```

#### `add_in_progress_marker(plan_path, phase_num)`

Adds [IN PROGRESS] marker, automatically removing any existing marker. Works with both h2 and h3 formats.

```bash
add_in_progress_marker "$PLAN_FILE" "1"
# Before (h3): ### Phase 1: Setup [NOT STARTED]
# After:       ### Phase 1: Setup [IN PROGRESS]
# Before (h2): ## Phase 1: Setup [NOT STARTED]
# After:       ## Phase 1: Setup [IN PROGRESS]
```

#### `add_complete_marker(plan_path, phase_num)`

Adds [COMPLETE] marker, automatically removing any existing marker. Works with both h2 and h3 formats.

```bash
add_complete_marker "$PLAN_FILE" "1"
# Before (h3): ### Phase 1: Setup [IN PROGRESS]
# After:       ### Phase 1: Setup [COMPLETE]
# Before (h2): ## Phase 1: Setup [IN PROGRESS]
# After:       ## Phase 1: Setup [COMPLETE]
```

#### `add_not_started_markers(plan_path)`

Adds [NOT STARTED] to all phases without status markers. Used for legacy plan compatibility. Works with both h2 and h3 formats.

```bash
add_not_started_markers "$PLAN_FILE"
# Before (h3): ### Phase 1: Setup
# After:       ### Phase 1: Setup [NOT STARTED]
# Before (h2): ## Phase 1: Setup
# After:       ## Phase 1: Setup [NOT STARTED]
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

### /implement and /implement Commands

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
# View current phase status (works with both h2 and h3)
grep -E "^##+ Phase" plan.md

# Count completed phases
grep -c "\[COMPLETE\]" plan.md

# Find current phase
grep "\[IN PROGRESS\]" plan.md
```

### Manual Status Updates

While typically managed by /implement, markers can be updated manually:

```bash
source .claude/lib/plan/checkbox-utils.sh
add_in_progress_marker "plan.md" "3"
```

## Phase Counting Standard

### Required Regex Pattern

All phase counting operations MUST use the following regex pattern with digit requirement:

```bash
# Count total phases (CORRECT - requires digit)
grep -c "^### Phase [0-9]" "$PLAN_FILE"

# Count completed phases (CORRECT - requires digit)
grep -c "^### Phase [0-9].*\[COMPLETE\]" "$PLAN_FILE"

# Check phase existence (CORRECT - requires digit)
grep -q "^### Phase [0-9]" "$PLAN_FILE"
```

**NEVER use**:
```bash
# BUGGY - matches false positives like "### Phase Routing Summary"
grep -c "^### Phase" "$PLAN_FILE"
```

### Pattern Components

| Component | Purpose | Example Match | Example Non-Match |
|-----------|---------|---------------|-------------------|
| `^` | Line start anchor | `### Phase 1:` | `  ### Phase 1:` (indented) |
| `###` | H3 heading marker | `### Phase 1:` | `## Phase 1:` (h2) |
| ` Phase ` | Literal text with spaces | `### Phase 1:` | `### Phases` |
| `[0-9]` | **Digit requirement** (critical) | `### Phase 1:`, `### Phase 12:` | `### Phase N:`, `### Phase Routing` |

### Why Digit Requirement is Critical

The digit requirement `[0-9]` prevents false positives from non-phase headings:

**False Positive Examples** (matched by buggy pattern `^### Phase`):
- `### Phase Routing Summary` - Summary section header
- `### Phase N: [Example Template]` - Template placeholder text
- `### Phase Dependencies` - Dependencies section header
- `### Phase Classification` - Documentation header

**Real-World Bug Example**:

In implementation execution, the buggy pattern `^### Phase` counted 6 "phases" instead of 3:
- 3 real phases: `### Phase 1:`, `### Phase 2:`, `### Phase 3:`
- 2 false positives: `### Phase Routing Summary` (appeared twice in plan)
- 1 false positive: `### Phase N:` (template example)

This incorrect count triggered the recovery loop to process non-existent phases 4-6, causing:
- Error messages about missing phases
- Failed checkpoint validation
- Prevented plan status updates from executing
- Recovery loop processing phantom phases

### Enforcement Requirements

**Command Authors** must use the digit requirement pattern:
- ✅ `grep -c "^### Phase [0-9]"` - Correct
- ❌ `grep -c "^### Phase"` - Prohibited (causes false positives)

**Authoritative Implementation**: The pattern `^### Phase [0-9]` is defined in `.claude/lib/plan/checkbox-utils.sh` (lines 672, 684) which serves as the canonical reference for all phase counting operations.

**Files Using Correct Pattern** (as of 2025-12-04):
- checkbox-utils.sh (authoritative library)
- plan-architect.md (agent)
- todo-functions.sh (library)
- lean-plan.md (command)
- create-plan.md (command)
- phase-classifier.sh (library)
- revise.md (command)
- implement.md (command) - **Updated 2025-12-04**
- lean-build.md (command) - **Updated 2025-12-04**
- lean-implement.md (command) - **Updated 2025-12-04**
- cleanup-plan-architect.md (agent) - **Updated 2025-12-04**

### Alternative Patterns for Advanced Use Cases

**Flexible Heading Level** (matches both h2 and h3):
```bash
# Matches both "## Phase 1:" and "### Phase 1:"
grep -c "^##+ Phase [0-9]" "$PLAN_FILE"
```

**Specific Phase Number**:
```bash
# Match only Phase 2
grep -q "^### Phase 2:" "$PLAN_FILE"
```

**Phase Range** (two-digit phases):
```bash
# Match phases 10-99
grep -c "^### Phase [1-9][0-9]" "$PLAN_FILE"
```

**Any Valid Phase** (comprehensive):
```bash
# Match phases 0-9, 10-99, 100+
grep -c "^### Phase [0-9]\+" "$PLAN_FILE"
```

## Best Practices

1. **Always use plan-architect**: Ensure new plans have `[NOT STARTED]` markers
2. **Let /implement manage transitions**: Avoid manual marker updates during builds
3. **Check for legacy plans**: The /implement command handles this automatically
4. **Use markers for visibility**: Quickly identify current work status
5. **Choose heading level consistently**: Use either h2 or h3 format throughout a plan (mixing is supported but not recommended)

## Heading Format Support

All checkbox-utils.sh functions use dynamic pattern matching (`^##+ Phase`) that matches both h2 (`##`) and h3 (`###`) formats. The phase number field position is identical in both formats ($3), so field extraction logic is unified.

**Pattern Matching**:
```bash
# Regex pattern matches both formats
/^##+ Phase /  # Matches both "## Phase" and "### Phase"
```

**Field Extraction**:
```
## Phase 1: Setup [NOT STARTED]
   $1    $2  $3
   ##    Phase  1:

### Phase 1: Setup [NOT STARTED]
    $1     $2  $3
    ###    Phase  1:
```

Both formats have phase number in field $3, enabling unified processing.

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

- [Build Command Guide](../guides/commands/implement-command-guide.md) - Complete implement workflow
- [Workflow Phases Planning](workflow-phases-planning.md) - Phase structure standards
- [Checkbox Utils Library](library-api-utilities.md) - Full function reference
