# Implementation Plan: Status Tracking Enhancement

**Plan ID**: 001_status_tracking_implementation.md
**Project**: [001_status_tracking_enhancement](../../../specs/001_status_tracking_enhancement/)
**Created**: 2025-12-14
**Status**: [NOT STARTED]

## Overview

Implement granular status tracking for implementation plans by adding status markers to plan metadata and phase headers. The planner agent will create plans with `[NOT STARTED]` status, and the implementer agent will update these markers as work progresses through `[IN PROGRESS]`, `[BLOCKED]`, `[SKIPPED]`, or `[COMPLETED]` states.

## Prerequisites

### Research Reports
- [001_analysis.md](../reports/001_analysis.md) - Comprehensive analysis of required changes

### Dependencies
- None (internal system enhancement)

### Existing Code Understanding
- `agent/subagents/nvim/planner.md` - Current plan format definition
- `agent/subagents/nvim/implementer.md` - Current implementation process
- `context/templates/plan-template.md` - Current plan template

## Implementation Steps [NOT STARTED]

### Step 1: Update Plan Template [NOT STARTED]

**File**: `/home/benjamin/.config/.opencode/context/templates/plan-template.md`
**Action**: modify

Update the plan template to include status markers in metadata and all phase headers.

**Changes**:

1. Update metadata status (line 12):
```markdown
**Status**: [NOT STARTED]
```

2. Add status markers to all phase headers:
```markdown
## Prerequisites [NOT STARTED]

## Implementation Steps [NOT STARTED]

### Step 1: [Step Title] [NOT STARTED]

### Step 2: [Step Title] [NOT STARTED]

## Configuration Options [NOT STARTED]

## Keybindings [NOT STARTED]

## Testing Plan [NOT STARTED]

## Documentation Updates [NOT STARTED]

## Rollback Plan [NOT STARTED]
```

**Validation**: 
- Read the updated template file
- Verify all phase headers have `[NOT STARTED]` markers
- Verify metadata status is `[NOT STARTED]`

### Step 2: Update Planner Agent - Plan Format [NOT STARTED]

**File**: `/home/benjamin/.config/.opencode/agent/subagents/nvim/planner.md`
**Action**: modify

Update the `<plan_format>` section (lines 58-147) to include status markers.

**Changes**:

Replace the plan format section with:

```markdown
<plan_format>
  # Implementation Plan: [Feature Name]
  
  **Plan ID**: NNN_plan_name.md
  **Project**: [Link to project directory]
  **Created**: YYYY-MM-DD
  **Status**: [NOT STARTED]
  
  ## Overview [NOT STARTED]
  
  What this plan implements and the expected outcome.
  
  ## Prerequisites [NOT STARTED]
  
  ### Research Reports
  - [Report Name](../reports/NNN_report.md) - Key findings used
  
  ### Dependencies
  - Plugin dependencies
  - External tool dependencies
  
  ### Existing Code Understanding
  - Files that must be understood before implementation
  
  ## Implementation Steps [NOT STARTED]
  
  ### Step 1: [Step Title] [NOT STARTED]
  
  **File**: `path/to/file.lua`
  **Action**: create | modify | delete
  
  Description of what to do.
  
  ```lua
  -- Code to add or modify
  ```
  
  **Validation**: How to verify this step succeeded
  
  ### Step 2: [Step Title] [NOT STARTED]
  
  [Continue pattern...]
  
  ## Configuration Options [NOT STARTED]
  
  | Option | Type | Default | Description |
  |--------|------|---------|-------------|
  
  ## Keybindings [NOT STARTED]
  
  | Key | Mode | Action | Location |
  |-----|------|--------|----------|
  
  ## Testing Plan [NOT STARTED]
  
  ### Manual Testing
  1. Test step 1
  2. Test step 2
  
  ### Expected Behaviors
  - Behavior 1
  - Behavior 2
  
  ### Edge Cases
  - Edge case 1
  - Edge case 2
  
  ## Documentation Updates [NOT STARTED]
  
  ### README Files
  - `path/to/README.md` - What to add/update
  
  ### Central Documentation
  - `docs/FILE.md` - What to add/update
  
  ## Rollback Plan [NOT STARTED]
  
  Steps to undo this implementation if needed.
  
  ## Estimated Effort
  
  - Implementation: X hours
  - Testing: X hours
  - Documentation: X hours
  
  ## Related
  
  - [Research Reports](../reports/)
  - [Previous Plans](./NNN_previous.md) (if revision)
</plan_format>
```

**Validation**:
- Read the updated planner.md file
- Verify plan_format section includes all status markers
- Verify format matches template

### Step 3: Add Status Tracking Documentation to Planner [NOT STARTED]

**File**: `/home/benjamin/.config/.opencode/agent/subagents/nvim/planner.md`
**Action**: modify

Add a new section after `<plan_format>` (after line 147) to document status tracking.

**Changes**:

Insert new section:

```markdown
<status_tracking>
  <initial_status>
    All plans are created with [NOT STARTED] status in:
    - Metadata status field
    - All phase headers (Overview, Prerequisites, Implementation Steps, etc.)
    - Individual step headers within Implementation Steps
  </initial_status>
  
  <status_values>
    - [NOT STARTED]: Plan/phase/step not yet begun
    - [IN PROGRESS]: Currently being worked on (set by implementer)
    - [BLOCKED]: Blocked by issue (set by implementer)
    - [COMPLETED]: Finished (set by implementer)
    - [SKIPPED]: Intentionally skipped with reason (set by implementer)
  </status_values>
  
  <implementer_responsibility>
    The implementer agent is responsible for updating status markers
    as work progresses. The planner only sets initial [NOT STARTED] status.
  </implementer_responsibility>
</status_tracking>
```

**Validation**:
- Verify new section is present after plan_format
- Verify all status values are documented

### Step 4: Update Planner Instructions [NOT STARTED]

**File**: `/home/benjamin/.config/.opencode/agent/subagents/nvim/planner.md`
**Action**: modify

Add instruction about status initialization to the `<instructions>` section (after line 282).

**Changes**:

Add new instruction:

```markdown
  <instruction id="9">
    Initialize all status markers to [NOT STARTED] in metadata and phase headers
  </instruction>
```

**Validation**:
- Verify instruction is added to instructions section
- Verify instruction numbering is correct

### Step 5: Update Implementer Agent - Add Status Update Process [NOT STARTED]

**File**: `/home/benjamin/.config/.opencode/agent/subagents/nvim/implementer.md`
**Action**: modify

Add new section after `<implementation_process>` (after line 61) to define status update process.

**Changes**:

Insert new section:

```markdown
<status_update_process>
  <overview>
    The implementer is responsible for updating plan status markers as work
    progresses. This provides real-time visibility into implementation progress.
  </overview>
  
  <update_timing>
    <on_start>
      Before beginning implementation:
      1. Read the plan file
      2. Update metadata status to [IN PROGRESS]
      3. Write updated plan back to file
    </on_start>
    
    <during_implementation>
      As each phase/step is started:
      1. Update phase/step header to [IN PROGRESS]
      2. Write updated plan to file
      
      As each phase/step is completed:
      1. Update phase/step header to [COMPLETED]
      2. Write updated plan to file
    </during_implementation>
    
    <on_blocking>
      If blocked by an issue:
      1. Update current phase/step to [BLOCKED]
      2. Update metadata status to [BLOCKED]
      3. Write updated plan to file
      4. Stop and report the blocking issue
    </on_blocking>
    
    <on_skip>
      If a phase/step is intentionally skipped:
      1. Update phase/step header to [SKIPPED]
      2. Document reason in implementation notes
      3. Write updated plan to file
      4. Continue with next phase/step
    </on_skip>
    
    <on_completion>
      When all steps are complete:
      1. Verify all phases show [COMPLETED] or [SKIPPED]
      2. Update metadata status to [COMPLETED]
      3. Write final updated plan to file
    </on_completion>
  </update_timing>
  
  <file_operations>
    <read_plan>
      Use read tool to load the plan file before starting
    </read_plan>
    
    <update_status>
      Use edit tool to update status markers:
      - Find exact status marker text (e.g., "[NOT STARTED]")
      - Replace with new status (e.g., "[IN PROGRESS]")
      - Update one marker at a time for precision
    </update_status>
    
    <write_plan>
      Status updates are written immediately via edit tool
    </write_plan>
  </file_operations>
</status_update_process>
```

**Validation**:
- Verify new section is present after implementation_process
- Verify all update scenarios are covered

### Step 6: Update Implementer Implementation Process [NOT STARTED]

**File**: `/home/benjamin/.config/.opencode/agent/subagents/nvim/implementer.md`
**Action**: modify

Update the `<implementation_process>` section (lines 19-61) to include status updates.

**Changes**:

Replace the implementation_process section with:

```markdown
<implementation_process>
  <step id="1">
    <action>Read and understand the plan</action>
    <details>
      Review the entire plan before starting implementation
    </details>
  </step>
  
  <step id="2">
    <action>Update plan status to IN PROGRESS</action>
    <details>
      Read plan file and update metadata status from [NOT STARTED] to [IN PROGRESS]
    </details>
  </step>
  
  <step id="3">
    <action>Verify prerequisites</action>
    <details>
      Ensure all dependencies and prerequisites are met
    </details>
  </step>
  
  <step id="4">
    <action>Execute steps in order with status updates</action>
    <details>
      For each phase/step:
      1. Update phase/step status to [IN PROGRESS]
      2. Execute the step as specified
      3. Validate the step
      4. Update phase/step status to [COMPLETED]
      5. Continue to next step
    </details>
  </step>
  
  <step id="5">
    <action>Handle blocking issues</action>
    <details>
      If blocked:
      1. Update current phase/step to [BLOCKED]
      2. Update metadata to [BLOCKED]
      3. Stop and report issue
    </details>
  </step>
  
  <step id="6">
    <action>Run testing plan</action>
    <details>
      Execute manual testing steps from the plan
    </details>
  </step>
  
  <step id="7">
    <action>Update final status and report completion</action>
    <details>
      Update metadata status to [COMPLETED] and confirm ready for review
    </details>
  </step>
</implementation_process>
```

**Validation**:
- Verify implementation_process includes status update steps
- Verify blocking scenario is included

### Step 7: Update Implementer Instructions [NOT STARTED]

**File**: `/home/benjamin/.config/.opencode/agent/subagents/nvim/implementer.md`
**Action**: modify

Add instructions about status updates to the `<instructions>` section (after line 247).

**Changes**:

Add new instructions:

```markdown
  <instruction id="9">
    Update plan metadata status to [IN PROGRESS] before starting implementation
  </instruction>
  <instruction id="10">
    Update phase/step status markers as work progresses
  </instruction>
  <instruction id="11">
    Update status to [BLOCKED] if encountering blocking issues
  </instruction>
  <instruction id="12">
    Update status to [COMPLETED] when all work is finished
  </instruction>
  <instruction id="13">
    Write status updates to plan file immediately using edit tool
  </instruction>
```

**Validation**:
- Verify all status update instructions are added
- Verify instruction numbering is correct

### Step 8: Update Reviser Agent - Status Reset [NOT STARTED]

**File**: `/home/benjamin/.config/.opencode/agent/subagents/nvim/reviser.md`
**Action**: modify

Update the `<revised_plan_format>` section (lines 85-122) to document status reset.

**Changes**:

Update the format to include status reset note:

```markdown
<revised_plan_format>
  # Implementation Plan: [Feature Name]
  
  **Plan ID**: NNN_plan_name.md (incremented from previous)
  **Project**: [Link to project directory]
  **Created**: YYYY-MM-DD
  **Revision of**: [Link to previous plan version]
  **Status**: [NOT STARTED]
  
  ## Revision Summary
  
  ### Changes from Previous Version
  - Change 1: Description
  - Change 2: Description
  
  ### Reason for Revision
  Brief explanation of why revision was needed.
  
  ### Status Reset
  All status markers have been reset to [NOT STARTED] for this revision.
  The previous plan version retains its final status.
  
  ---
  
  [Rest of plan follows standard plan format with [NOT STARTED] status markers]
  
  ## Overview [NOT STARTED]
  ...
  
  ## Prerequisites [NOT STARTED]
  ...
  
  ## Implementation Steps [NOT STARTED]
  ...
  
  ## Revision History
  
  | Version | Date | Changes | Final Status |
  |---------|------|---------|--------------|
  | 001 | YYYY-MM-DD | Initial plan | [COMPLETED]/[BLOCKED]/etc |
  | 002 | YYYY-MM-DD | [This revision] - Summary | [NOT STARTED] |
</revised_plan_format>
```

**Validation**:
- Verify status reset is documented
- Verify revision history includes final status column

### Step 9: Add Status Reset Instruction to Reviser [NOT STARTED]

**File**: `/home/benjamin/.config/.opencode/agent/subagents/nvim/reviser.md`
**Action**: modify

Add instruction about status reset to the `<instructions>` section (after line 221).

**Changes**:

Add new instruction:

```markdown
  <instruction id="9">
    Reset all status markers to [NOT STARTED] in the revised plan
  </instruction>
  <instruction id="10">
    Document the status reset in the Revision Summary section
  </instruction>
  <instruction id="11">
    Include final status of previous version in revision history table
  </instruction>
```

**Validation**:
- Verify status reset instructions are added
- Verify instruction numbering is correct

### Step 10: Create Status Tracking Process Documentation [NOT STARTED]

**File**: `/home/benjamin/.config/.opencode/context/processes/status-tracking.md`
**Action**: create

Create comprehensive documentation for the status tracking system.

**Content**:

```markdown
# Status Tracking Process

Process for tracking implementation progress through status markers in plans.

## Overview

Implementation plans use status markers to track progress at both the plan level (metadata) and phase level (section headers). The planner creates plans with `[NOT STARTED]` status, and the implementer updates these markers as work progresses.

```
┌─────────────────────────────────────────────────────────────┐
│                    Plan Created                              │
│              All status: [NOT STARTED]                       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Implementation Begins                           │
│         Metadata status: [IN PROGRESS]                       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Phase-by-Phase Execution                        │
│   Each phase: [NOT STARTED] → [IN PROGRESS] → [COMPLETED]   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Implementation Complete                         │
│         Metadata status: [COMPLETED]                         │
└─────────────────────────────────────────────────────────────┘
```

## Status Values

### Metadata Status
Located in plan header after "Status:" field.

| Status | Meaning | Set By |
|--------|---------|--------|
| `[NOT STARTED]` | Plan created but not begun | Planner |
| `[IN PROGRESS]` | Implementation underway | Implementer |
| `[BLOCKED]` | Implementation blocked by issue | Implementer |
| `[COMPLETED]` | Implementation finished | Implementer |

### Phase Status
Located in phase header (e.g., "## Prerequisites [NOT STARTED]").

| Status | Meaning | Set By |
|--------|---------|--------|
| `[NOT STARTED]` | Phase not yet begun | Planner |
| `[IN PROGRESS]` | Phase currently being worked on | Implementer |
| `[BLOCKED]` | Phase blocked by issue | Implementer |
| `[COMPLETED]` | Phase finished | Implementer |
| `[SKIPPED]` | Phase intentionally skipped | Implementer |

## Workflow

### Plan Creation (Planner)
1. Planner creates plan from template
2. All status markers set to `[NOT STARTED]`
3. Plan saved to specs/NNN_project/plans/

### Implementation Start (Implementer)
1. Implementer reads plan file
2. Updates metadata status to `[IN PROGRESS]`
3. Writes updated plan to file

### Phase Execution (Implementer)
For each phase:
1. Update phase header to `[IN PROGRESS]`
2. Execute phase steps
3. Validate phase completion
4. Update phase header to `[COMPLETED]`

### Blocking Scenario (Implementer)
If blocked:
1. Update current phase to `[BLOCKED]`
2. Update metadata to `[BLOCKED]`
3. Stop implementation
4. Report blocking issue

### Skip Scenario (Implementer)
If phase skipped:
1. Update phase header to `[SKIPPED]`
2. Document reason in notes
3. Continue to next phase

### Completion (Implementer)
1. Verify all phases `[COMPLETED]` or `[SKIPPED]`
2. Update metadata to `[COMPLETED]`
3. Report completion to reviewer

## Plan Revision

When a plan is revised:
1. New plan version created (incremented number)
2. All status markers reset to `[NOT STARTED]`
3. Previous plan retains its final status
4. Revision history documents previous status

## Reading Status

### Check Overall Progress
Look at metadata status:
- `[NOT STARTED]` - Not begun
- `[IN PROGRESS]` - Work underway
- `[BLOCKED]` - Issue encountered
- `[COMPLETED]` - Finished

### Check Detailed Progress
Look at phase headers:
- Count `[COMPLETED]` phases
- Identify `[IN PROGRESS]` phase (current work)
- Note any `[BLOCKED]` or `[SKIPPED]` phases

### Example

```markdown
**Status**: [IN PROGRESS]

## Prerequisites [COMPLETED]
## Implementation Steps [IN PROGRESS]
### Step 1: Create file [COMPLETED]
### Step 2: Add code [IN PROGRESS]
### Step 3: Test [NOT STARTED]
## Testing Plan [NOT STARTED]
## Documentation Updates [NOT STARTED]
```

This shows:
- Overall: In progress
- Prerequisites: Done
- Implementation: Step 2 in progress
- Testing and docs: Not started

## Best Practices

### For Implementers
1. Update status immediately when starting/completing phases
2. Be specific about blocking issues
3. Document reasons for skipped phases
4. Keep status markers synchronized with actual progress

### For Reviewers
1. Check status markers match implementation state
2. Verify `[COMPLETED]` phases are actually complete
3. Investigate `[BLOCKED]` or `[SKIPPED]` phases
4. Confirm metadata status reflects overall state

## Related

- [New Plugin Workflow](new-plugin-workflow.md) - Uses status tracking
- [Troubleshooting Workflow](troubleshooting-workflow.md) - Uses status tracking
```

**Validation**:
- Verify file is created
- Verify all status values are documented
- Verify workflow is clear

### Step 11: Update ARCHITECTURE.md [NOT STARTED]

**File**: `/home/benjamin/.config/.opencode/ARCHITECTURE.md`
**Action**: modify

Add section about status tracking to the architecture documentation.

**Changes**:

Add new section after "Data Flow" section (around line 150):

```markdown
## Status Tracking

### Overview

Implementation plans include granular status tracking at both the plan level and phase level, providing real-time visibility into implementation progress.

### Status Markers

**Metadata Status**: Single status in plan header
- `[NOT STARTED]` - Plan created
- `[IN PROGRESS]` - Implementation underway
- `[BLOCKED]` - Blocked by issue
- `[COMPLETED]` - Implementation finished

**Phase Status**: Status in each section header
- `[NOT STARTED]` - Phase not begun
- `[IN PROGRESS]` - Phase being worked on
- `[BLOCKED]` - Phase blocked
- `[COMPLETED]` - Phase finished
- `[SKIPPED]` - Phase skipped

### Responsibility

- **Planner**: Sets all status to `[NOT STARTED]`
- **Implementer**: Updates status as work progresses
- **Reviser**: Resets status to `[NOT STARTED]` on revision

### Status Flow

```
[NOT STARTED] → [IN PROGRESS] → [COMPLETED]
                       ↓
                  [BLOCKED]
                       ↓
                  [SKIPPED]
```

### Benefits

- Real-time progress visibility
- Clear indication of blocking issues
- Detailed phase-level tracking
- Historical record in completed plans
```

**Validation**:
- Verify section is added to ARCHITECTURE.md
- Verify status flow diagram is included

### Step 12: Update README.md [NOT STARTED]

**File**: `/home/benjamin/.config/.opencode/README.md`
**Action**: modify

Add note about status tracking to the README.

**Changes**:

Add to the "Workflows" section (around line 50):

```markdown
### Status Tracking

All implementation plans include status markers:
- **Plan Status**: Overall progress in metadata
- **Phase Status**: Individual section progress

Status values:
- `[NOT STARTED]` - Not yet begun
- `[IN PROGRESS]` - Currently working
- `[BLOCKED]` - Blocked by issue
- `[COMPLETED]` - Finished
- `[SKIPPED]` - Intentionally skipped

The implementer updates these markers as work progresses, providing real-time visibility into implementation status.

See [Status Tracking Process](context/processes/status-tracking.md) for details.
```

**Validation**:
- Verify section is added to README
- Verify link to process documentation is correct

## Configuration Options [NOT STARTED]

No configuration options for this enhancement.

## Keybindings [NOT STARTED]

No keybindings for this enhancement.

## Testing Plan [NOT STARTED]

### Manual Testing

1. **Test Planner Creates Plan with Status**
   - Create a new plan using planner agent
   - Verify metadata shows `[NOT STARTED]`
   - Verify all phase headers show `[NOT STARTED]`
   - Verify individual steps show `[NOT STARTED]`

2. **Test Implementer Updates Status**
   - Start implementation of a test plan
   - Verify metadata updates to `[IN PROGRESS]`
   - Verify phase headers update as work proceeds
   - Verify final status is `[COMPLETED]`

3. **Test Status Persistence**
   - After implementer updates status
   - Read plan file directly
   - Verify status markers are updated in file
   - Verify file format is preserved

4. **Test Blocking Scenario**
   - Create plan with intentional blocking issue
   - Run implementer
   - Verify status updates to `[BLOCKED]`
   - Verify implementer stops and reports

5. **Test Plan Revision**
   - Create and partially implement a plan
   - Revise the plan
   - Verify new plan has `[NOT STARTED]` status
   - Verify old plan retains its status

### Expected Behaviors

- Planner creates plans with all `[NOT STARTED]` markers
- Implementer updates metadata to `[IN PROGRESS]` on start
- Implementer updates phase headers as work proceeds
- Status updates persist in plan file
- Blocking issues result in `[BLOCKED]` status
- Completed implementations show `[COMPLETED]` status
- Revised plans reset to `[NOT STARTED]`

### Edge Cases

- **Partial Implementation**: Last updated phase shows `[IN PROGRESS]`, rest show `[NOT STARTED]`
- **Multiple Blocks**: Each blocked phase marked individually
- **All Skipped**: Metadata can be `[COMPLETED]` even if phases `[SKIPPED]`
- **Revision During Implementation**: New plan resets, old plan keeps status

## Documentation Updates [NOT STARTED]

### README Files
- `/home/benjamin/.config/.opencode/README.md` - Add status tracking section

### Central Documentation
- `/home/benjamin/.config/.opencode/ARCHITECTURE.md` - Add status tracking section

### Process Documentation
- `/home/benjamin/.config/.opencode/context/processes/status-tracking.md` - Create new process doc

## Rollback Plan [NOT STARTED]

If status tracking causes issues:

1. **Revert Template**
   - Restore original plan-template.md from git
   - Remove status markers

2. **Revert Planner**
   - Restore original planner.md from git
   - Remove status tracking sections

3. **Revert Implementer**
   - Restore original implementer.md from git
   - Remove status update process

4. **Revert Reviser**
   - Restore original reviser.md from git
   - Remove status reset documentation

5. **Remove Documentation**
   - Delete context/processes/status-tracking.md
   - Revert ARCHITECTURE.md changes
   - Revert README.md changes

6. **Clean Existing Plans**
   - Manually remove status markers from any created plans
   - Or leave them as harmless annotations

## Estimated Effort

- Implementation: 2-3 hours
- Testing: 1 hour
- Documentation: 1 hour
- **Total**: 4-5 hours

## Related

- [Research Reports](../reports/)
- [001_analysis.md](../reports/001_analysis.md) - Detailed analysis
