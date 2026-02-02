# Analysis: Status Tracking Enhancement Requirements

**Analyzed**: 2025-12-14
**Scope**: Planner and Implementer agents, plan template
**Type**: Feature enhancement

## Overview

The requirement is to add granular status tracking to implementation plans, where:
1. Planner creates plans with `[NOT STARTED]` status markers
2. Implementer updates status markers as work progresses
3. Status markers appear in both metadata and phase headers

## Current State

### Planner Agent (planner.md)
**Lines 58-147**: Defines plan format with:
- Metadata status field: `draft | approved | in_progress | completed`
- No phase-level status tracking
- No `[NOT STARTED]` initial status

### Implementer Agent (implementer.md)
**Lines 19-61**: Implementation process with:
- No plan modification instructions
- No status update requirements
- Reads plan but doesn't update it

### Plan Template (plan-template.md)
**Lines 7-111**: Template structure with:
- Single status field in metadata
- No phase headers with status markers
- No status tracking mechanism

## Required Changes

### 1. Planner Agent Modifications

**Location**: `agent/subagents/nvim/planner.md`

#### Change 1.1: Update plan_format section (lines 58-147)
Add status markers to:
- Metadata: Change initial status to `[NOT STARTED]`
- Phase headers: Add `[NOT STARTED]` after each phase title

**Before**:
```markdown
**Status**: draft | approved | in_progress | completed

## Implementation Steps

### Step 1: [Step Title]
```

**After**:
```markdown
**Status**: [NOT STARTED]

## Implementation Steps [NOT STARTED]

### Step 1: [Step Title] [NOT STARTED]
```

#### Change 1.2: Add status tracking instructions
**Location**: New section after `<plan_format>`

Add instructions for:
- Initial status is always `[NOT STARTED]`
- Status markers on metadata and all phase headers
- List of valid status values

### 2. Implementer Agent Modifications

**Location**: `agent/subagents/nvim/implementer.md`

#### Change 2.1: Add status update process
**Location**: New section after `<implementation_process>`

Add:
- Read plan file before starting
- Update metadata status to `[IN PROGRESS]`
- Update phase status as work proceeds
- Write updated plan back to file

#### Change 2.2: Update implementation_process
**Location**: Lines 19-61

Add status update steps:
- Before starting: Update plan status to `[IN PROGRESS]`
- For each phase: Update phase header status
- On completion: Update to `[COMPLETED]`
- On blocking issue: Update to `[BLOCKED]`
- On skip: Update to `[SKIPPED]`

#### Change 2.3: Add plan modification instructions
**Location**: New `<plan_modification>` section

Define:
- How to read the plan file
- How to update status markers
- How to write back to file
- When to update (before each phase, on completion, on block)

### 3. Plan Template Modifications

**Location**: `context/templates/plan-template.md`

#### Change 3.1: Update metadata status
**Line 12**: Change from:
```markdown
**Status**: draft | approved | in_progress | completed
```

To:
```markdown
**Status**: [NOT STARTED]
```

#### Change 3.2: Add status to phase headers
Add `[NOT STARTED]` to all phase headers:
- Line 18: `## Prerequisites [NOT STARTED]`
- Line 29: `## Implementation Steps [NOT STARTED]`
- Line 59: `## Configuration Options [NOT STARTED]`
- Line 66: `## Keybindings [NOT STARTED]`
- Line 72: `## Testing Plan [NOT STARTED]`
- Line 86: `## Documentation Updates [NOT STARTED]`
- Line 94: `## Rollback Plan [NOT STARTED]`

### 4. Reviser Agent Modifications

**Location**: `agent/subagents/nvim/reviser.md`

#### Change 4.1: Preserve status tracking
**Location**: Lines 85-122 (revised_plan_format)

Ensure revised plans:
- Reset status to `[NOT STARTED]` for new revision
- Preserve revision history
- Document that status resets on revision

### 5. Documentation Updates

#### Change 5.1: Update ARCHITECTURE.md
Add section explaining status tracking system

#### Change 5.2: Update README.md
Add note about plan status tracking

#### Change 5.3: Create new process document
**Location**: `context/processes/status-tracking.md`

Document:
- Status values and meanings
- When statuses change
- How implementer updates plans
- How to interpret status markers

## Status Values

### Metadata Status
- `[NOT STARTED]` - Plan created but implementation not begun
- `[IN PROGRESS]` - Implementation underway
- `[BLOCKED]` - Implementation blocked by issue
- `[COMPLETED]` - Implementation finished
- `[SKIPPED]` - Implementation skipped (with reason)

### Phase Status
- `[NOT STARTED]` - Phase not yet begun
- `[IN PROGRESS]` - Phase currently being worked on
- `[BLOCKED]` - Phase blocked by issue
- `[COMPLETED]` - Phase finished
- `[SKIPPED]` - Phase skipped (with reason)

## Implementation Approach

### Phase 1: Update Templates and Planner
1. Update plan template with status markers
2. Update planner agent to use new format
3. Update planner instructions for status initialization

### Phase 2: Update Implementer
1. Add plan file reading capability
2. Add status update logic
3. Add plan file writing capability
4. Update implementation process to include status updates

### Phase 3: Update Reviser
1. Ensure status resets on revision
2. Document status reset behavior

### Phase 4: Update Documentation
1. Update ARCHITECTURE.md
2. Update README.md
3. Create status-tracking.md process document

## Edge Cases

### Case 1: Partial Implementation
If implementer stops mid-phase:
- Last updated phase shows `[IN PROGRESS]`
- Subsequent phases remain `[NOT STARTED]`
- Metadata shows `[IN PROGRESS]`

### Case 2: Blocking Issue
If implementer encounters blocking issue:
- Current phase marked `[BLOCKED]`
- Metadata marked `[BLOCKED]`
- Implementer stops and reports

### Case 3: Skipped Phase
If phase is intentionally skipped:
- Phase marked `[SKIPPED]`
- Reason documented in implementation notes
- Subsequent phases continue

### Case 4: Plan Revision During Implementation
If plan revised while in progress:
- New plan version created
- Status resets to `[NOT STARTED]`
- Previous plan retains its status

## Testing Requirements

### Test 1: Planner Creates Plan with Status
Verify planner creates plan with:
- Metadata: `[NOT STARTED]`
- All phase headers: `[NOT STARTED]`

### Test 2: Implementer Updates Status
Verify implementer:
- Updates metadata to `[IN PROGRESS]` on start
- Updates phase headers as work proceeds
- Writes changes back to plan file

### Test 3: Status Persistence
Verify status updates persist:
- Read plan file after implementer runs
- Confirm status markers updated
- Confirm file format preserved

### Test 4: Blocking Scenario
Verify blocking behavior:
- Implementer encounters issue
- Updates status to `[BLOCKED]`
- Stops and reports

## Related Files

- `agent/subagents/nvim/planner.md` - Planner agent
- `agent/subagents/nvim/implementer.md` - Implementer agent
- `agent/subagents/nvim/reviser.md` - Reviser agent
- `context/templates/plan-template.md` - Plan template
- `ARCHITECTURE.md` - System architecture
- `README.md` - System overview

## Recommendations

1. **Start with template**: Update plan template first as reference
2. **Update planner next**: Ensure new plans use new format
3. **Implement status updates**: Add implementer capability
4. **Test thoroughly**: Verify status tracking works end-to-end
5. **Document clearly**: Ensure users understand status system
