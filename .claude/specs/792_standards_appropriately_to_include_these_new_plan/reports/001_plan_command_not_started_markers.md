# Plan Command [NOT STARTED] Metadata Markers Research Report

## Metadata
- **Date**: 2025-11-18
- **Agent**: research-specialist
- **Topic**: Plan command modifications to include [NOT STARTED] markers in metadata
- **Report Type**: codebase analysis

## Executive Summary

The /plan command delegates plan creation to the plan-architect agent, which uses a standard template (plan-architect.md:508-586) that generates phase headings without status markers. To add [NOT STARTED] markers during plan creation, the plan template in the plan-architect agent needs to be updated to include `[NOT STARTED]` in each phase heading. The /build command can then update these markers to [IN PROGRESS] and [COMPLETE] as phases execute. This requires modifications to the plan-architect.md agent template and corresponding updates to workflow-phases-planning.md documentation.

## Findings

### 1. Plan Creation Workflow in /plan Command

**File**: `/home/benjamin/.config/.claude/commands/plan.md`

The /plan command orchestrates plan creation through three blocks:

1. **Block 1 (lines 26-183)**: Setup and research invocation
   - Captures feature description and complexity
   - Invokes research-specialist agent
   - Creates report directory at `${TOPIC_PATH}/reports`

2. **Block 2 (lines 185-292)**: Plan creation
   - Verifies research artifacts exist
   - Calculates plan path as `${PLANS_DIR}/${PLAN_NUMBER}_$(echo "$TOPIC_NAME" | cut -c1-40)_plan.md`
   - **Key invocation** (lines 271-292): Invokes plan-architect agent with Task

   ```markdown
   Task {
     subagent_type: "general-purpose"
     description: "Create implementation plan for ${FEATURE_DESCRIPTION} with mandatory file creation"
     prompt: "
       Read and follow ALL behavioral guidelines from:
       ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md
       ...
       Execute planning according to behavioral guidelines and return completion signal:
       PLAN_CREATED: ${PLAN_PATH}
     "
   }
   ```

3. **Block 3 (lines 294-365)**: Verification and completion
   - Verifies plan file exists and has substantial content (>500 bytes)
   - Transitions state machine to COMPLETE

**Gap Identified**: The /plan command itself does not generate the plan content - it delegates entirely to the plan-architect agent. Therefore, [NOT STARTED] markers must be added in the plan-architect.md template.

### 2. Plan-Architect Agent Template Structure

**File**: `/home/benjamin/.config/.claude/agents/plan-architect.md`

The plan-architect agent uses a standard template for plan creation (lines 508-586):

```markdown
## Plan Templates

### Standard Feature Implementation

```markdown
# [Feature] Implementation Plan

## Metadata
- **Date**: YYYY-MM-DD
- **Feature**: [Name]
- **Scope**: [Brief description]
- **Estimated Phases**: [N]
- **Estimated Hours**: [H]
- **Standards File**: /path/to/CLAUDE.md
- **Research Reports**:
  - [Report 1 Title](../reports/001_report_name.md)
  ...

## Implementation Phases

### Phase 1: Foundation
dependencies: []

**Objective**: [Goal]
**Complexity**: Low

Tasks:
- [ ] Task 1 (file: path/to/file.ext)
- [ ] Task 2

Testing:
```bash
# Test command
```

### Phase 2: [Next Phase]
dependencies: [1]

**Objective**: [Goal]
**Complexity**: Medium

Tasks:
- [ ] Task 1
- [ ] Task 2
```

**Current State**: Phase headings are formatted as `### Phase N: [Name]` without any status marker.

**Target State**: Phase headings should be `### Phase N: [Name] [NOT STARTED]`

### 3. Metadata Section Generation

The plan-architect agent generates the Metadata section with these fields (lines 513-523):

- Date
- Feature
- Scope
- Estimated Phases
- Estimated Hours
- Standards File
- Structure Level (added per lines 261-262)
- Complexity Score (added per lines 261-262)
- Research Reports

**Observation**: There is no "Phase Status" field in metadata. Status is tracked on individual phase headings, not in the metadata block. This is the correct approach as it allows per-phase status visibility.

### 4. Phase Format Requirements

**File**: `/home/benjamin/.config/.claude/agents/plan-architect.md` (lines 282-288)

Each phase must include:
- **Objective**: Clear goal for the phase
- **Complexity**: Low/Medium/High estimate
- **Tasks**: Checkboxes `- [ ]` for /implement compatibility
- **Testing**: Specific test commands or approaches
- **Expected Duration**: Time estimate

The phase heading format is `### Phase N: Name` (line 545, 561) but does not specify status markers.

### 5. Status Marker Integration Points

From the existing research report (`001_plan_metadata_update_research.md`), status markers are applied:

**Current Markers**:
- `[COMPLETE]` - Added by `add_complete_marker()` in checkbox-utils.sh after phase completion
- `[IN PROGRESS]` - To be added by `add_in_progress_marker()` when phase begins

**Proposed Marker**:
- `[NOT STARTED]` - Should be added during plan creation by plan-architect agent

**Marker Lifecycle**:
```
Plan Creation:        ### Phase 1: Setup [NOT STARTED]
Build Phase Start:    ### Phase 1: Setup [IN PROGRESS]
Build Phase End:      ### Phase 1: Setup [COMPLETE]
```

### 6. Documentation Standards Analysis

**File**: `/home/benjamin/.config/.claude/docs/reference/workflow-phases-planning.md`

The workflow-phases-planning.md shows expected plan format (lines 141-175):

```markdown
## Plan Structure

Expected plan format:

```markdown
# Implementation Plan: [Feature Name]

## Overview
[Summary of implementation approach]

## Phases

### Phase 1: Core Infrastructure
- **Dependencies**: []
- **Tasks**:
  - [ ] Create base module
  - [ ] Setup configuration
```

**Gap**: No status markers shown in the documentation. Documentation needs updating to show `[NOT STARTED]` markers.

### 7. Existing Plan Examples

**File**: `/home/benjamin/.config/.claude/specs/792_standards_appropriately_to_include_these_new_plan/plans/001_standards_appropriately_to_include_these_plan.md`

Current phase format (lines 98-141):

```markdown
### Phase 1: Core Library Functions
dependencies: []

**Objective**: Create the new progress marker functions in checkbox-utils.sh

**Complexity**: Medium

Tasks:
- [ ] Add `add_in_progress_marker()` function to checkbox-utils.sh
...
```

The existing plan does NOT have `[NOT STARTED]` markers on phase headings. This confirms the feature needs to be added.

### 8. Checkbox-Utils Library Patterns

**File**: `/home/benjamin/.config/.claude/lib/checkbox-utils.sh`

The library provides functions for marker management:

- `add_complete_marker()` (lines 335-361): Adds `[COMPLETE]` to phase heading
- `mark_phase_complete()` (lines 176-266): Marks checkboxes as complete

**Pattern for add_complete_marker**:
```bash
awk -v phase="$phase_num" '
  /^### Phase / {
    phase_field = $3
    gsub(/:/, "", phase_field)
    if (phase_field == phase) {
      # Remove existing markers
      gsub(/\s*\[(COMPLETE|IN PROGRESS|BLOCKED|SKIPPED)\]/, "")
      # Add COMPLETE marker
      sub(/$/, " [COMPLETE]")
    }
    print
    next
  }
  { print }
'
```

This pattern should be extended to handle `[NOT STARTED]` markers when adding other status markers.

## Recommendations

### 1. Update Plan-Architect Agent Template

**File**: `/home/benjamin/.config/.claude/agents/plan-architect.md` (lines 545-569)

Change the plan template to include `[NOT STARTED]` markers on phase headings:

**From**:
```markdown
### Phase 1: Foundation
dependencies: []
```

**To**:
```markdown
### Phase 1: Foundation [NOT STARTED]
dependencies: []
```

This ensures all newly created plans have explicit status markers from creation.

### 2. Add Template Instruction for [NOT STARTED]

**File**: `/home/benjamin/.config/.claude/agents/plan-architect.md`

Add explicit instruction in the Phase Format section (after line 288):

```markdown
### Phase Heading Format
Phase headings must include `[NOT STARTED]` status marker:
- Format: `### Phase N: Name [NOT STARTED]`
- The /build command will update this to `[IN PROGRESS]` and `[COMPLETE]`
- All four status markers are: [NOT STARTED], [IN PROGRESS], [COMPLETE], [BLOCKED]
```

### 3. Update Documentation Standards

**File**: `/home/benjamin/.config/.claude/docs/reference/workflow-phases-planning.md` (lines 141-175)

Update the expected plan format to show `[NOT STARTED]` markers:

```markdown
### Phase 1: Core Infrastructure [NOT STARTED]
- **Dependencies**: []
- **Tasks**:
  - [ ] Create base module
  - [ ] Setup configuration

### Phase 2: Main Feature [NOT STARTED]
- **Dependencies**: ["Phase 1"]
- **Tasks**:
  - [ ] Implement core logic
```

### 4. Extend Checkbox-Utils for NOT STARTED Handling

**File**: `/home/benjamin/.config/.claude/lib/checkbox-utils.sh`

Update the marker removal patterns in `add_complete_marker()` and the proposed `add_in_progress_marker()` to recognize `[NOT STARTED]`:

```bash
# Update regex to include NOT STARTED
gsub(/\s*\[(COMPLETE|IN PROGRESS|BLOCKED|SKIPPED|NOT STARTED)\]/, "")
```

### 5. Add Plan Validation for Status Markers

**File**: `/home/benjamin/.config/.claude/commands/build.md`

Add validation in Block 1 that verifies phase headings have status markers. If a plan lacks markers (legacy plan), add `[NOT STARTED]` markers automatically:

```bash
# Check for status markers in phase headings
if ! grep -q "\[NOT STARTED\]\|\[IN PROGRESS\]\|\[COMPLETE\]" "$PLAN_FILE"; then
  echo "WARN: Plan has no status markers, adding [NOT STARTED] to all phases"
  add_not_started_markers "$PLAN_FILE"
fi
```

### 6. Create Comprehensive Documentation

As recommended in the existing research report, create `/home/benjamin/.config/.claude/docs/reference/plan-progress-tracking.md` and include the complete marker lifecycle:

```markdown
## Status Marker Lifecycle

| Marker | Applied By | When |
|--------|------------|------|
| `[NOT STARTED]` | plan-architect | Plan creation |
| `[IN PROGRESS]` | build command | Phase execution start |
| `[COMPLETE]` | build command | Phase execution end |
| `[BLOCKED]` | build command | Dependencies failed |
| `[SKIPPED]` | manual | Phase intentionally skipped |
```

## References

### Files Analyzed

- `/home/benjamin/.config/.claude/commands/plan.md` (lines 1-375) - /plan command implementation
- `/home/benjamin/.config/.claude/agents/plan-architect.md` (lines 1-832) - Plan architect agent with template
- `/home/benjamin/.config/.claude/docs/reference/workflow-phases-planning.md` (lines 1-226) - Planning phase documentation
- `/home/benjamin/.config/.claude/specs/792_standards_appropriately_to_include_these_new_plan/plans/001_standards_appropriately_to_include_these_plan.md` (lines 1-378) - Existing plan example
- `/home/benjamin/.config/.claude/specs/792_standards_appropriately_to_include_these_new_plan/reports/001_plan_metadata_update_research.md` (lines 1-489) - Previous research on progress tracking
- `/home/benjamin/.config/.claude/lib/checkbox-utils.sh` (lines 1-413) - Checkbox update utilities

### Key Line References

- **Plan creation delegation**: plan.md:271-292 (Task invocation to plan-architect)
- **Plan template section**: plan-architect.md:508-586 (Standard Feature Implementation template)
- **Phase format requirements**: plan-architect.md:282-288
- **Metadata fields**: plan-architect.md:513-523
- **Documentation plan format**: workflow-phases-planning.md:141-175
- **Marker removal pattern**: checkbox-utils.sh:335-361 (add_complete_marker)

## Implementation Status

- **Status**: Research Complete
- **Plan**: [001_standards_appropriately_to_include_these_plan.md](../plans/001_standards_appropriately_to_include_these_plan.md)
- **Implementation**: Pending - requires plan revision to add new phase for /plan command modifications
- **Date**: 2025-11-18
