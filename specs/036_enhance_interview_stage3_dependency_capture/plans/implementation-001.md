# Implementation Plan: Task #36

- **Task**: 36 - Enhance interview Stage 3 dependency capture
- **Status**: [NOT STARTED]
- **Effort**: 1-2 hours
- **Dependencies**: Task #35 (dependencies field schema)
- **Research Inputs**: [specs/036_enhance_interview_stage3_dependency_capture/reports/research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: meta
- **Lean Intent**: false

## Overview

This plan enhances the meta-builder-agent.md Interview Stage 3 (IdentifyUseCases) to explicitly capture dependency relationships between tasks being created. The current implementation mentions "dependency order" in Question 4 but lacks structured prompts and validation. This change adds Question 5 for dependency capture with three modes (no dependencies, linear chain, custom), validation logic (self-reference, valid index, circular detection), and support for external dependencies on existing tasks.

### Research Integration

Key findings from research-001.md:
- Current Stage 3 has implicit dependency capture but no structured AskUserQuestion
- State-management.md (task 35) now documents the `dependencies` array field schema
- Validation requires: self-reference check, valid task index check, circular dependency detection
- Need to handle both internal dependencies (between new tasks) and external dependencies (on existing tasks)

## Goals & Non-Goals

**Goals**:
- Add structured Question 5 for explicit dependency capture after task list collection
- Implement AskUserQuestion JSON specification with three dependency modes
- Add validation logic description for self-reference, valid index, and circular detection
- Add external dependency handling for tasks depending on existing tasks in state.json
- Update capture variables documentation to include dependency_map

**Non-Goals**:
- Topological sorting for task number assignment (task 37)
- TODO.md insertion ordering by dependencies (task 38)
- Dependency graph visualization (task 39)
- Changes to Stage 5 (ReviewAndConfirm) or Stage 6 (CreateTasks) beyond documentation

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| User confusion with dependency syntax | Medium | Medium | Provide clear examples in AskUserQuestion context field |
| Circular dependency detection complexity | Low | Low | Use simple pseudocode; actual implementation is agent's responsibility |
| External dependency validation errors | Low | Low | Graceful fallback: warn but allow, validate at Stage 5 |

## Implementation Phases

### Phase 1: Add Question 5 for Dependency Capture [NOT STARTED]

**Goal:** Insert structured dependency capture question into Stage 3 after Question 4

**Tasks:**
- [ ] Add Question 5 AskUserQuestion JSON block after line 256 (Question 4 capture)
- [ ] Define three dependency mode options: "No dependencies", "Linear chain", "Custom"
- [ ] Add context field with dependency example
- [ ] Add follow-up question for "Custom" mode with format specification

**Timing:** 30 minutes

**Files to modify:**
- `.claude/agents/meta-builder-agent.md` - Insert Question 5 after line 256-260

**Verification:**
- Question 5 follows consistent JSON structure as Questions 1-4
- Three options are clearly described
- Context field provides concrete example

---

### Phase 2: Add Validation Logic Description [NOT STARTED]

**Goal:** Document validation requirements that the agent must perform after dependency capture

**Tasks:**
- [ ] Add "Dependency Validation" subsection after Question 5 capture
- [ ] Document self-reference check (task cannot depend on itself)
- [ ] Document valid index check (referenced tasks must exist in task_list)
- [ ] Document circular dependency detection with error message format
- [ ] Add pseudocode for validation function

**Timing:** 30 minutes

**Files to modify:**
- `.claude/agents/meta-builder-agent.md` - Add validation subsection after Question 5

**Verification:**
- All three validation rules are documented
- Error message formats are specified
- Pseudocode is clear and implementable

---

### Phase 3: Add External Dependency Handling [NOT STARTED]

**Goal:** Enable tasks to depend on existing tasks already in state.json

**Tasks:**
- [ ] Add optional Question 5b for external dependencies
- [ ] Define AskUserQuestion JSON for external dependency capture
- [ ] Add guidance for validating external task numbers against state.json
- [ ] Document how external dependencies are merged with internal dependencies

**Timing:** 20 minutes

**Files to modify:**
- `.claude/agents/meta-builder-agent.md` - Add external dependency question after validation

**Verification:**
- External dependency capture is clearly optional
- Validation against state.json is documented
- Merge strategy is clear (internal + external combined)

---

### Phase 4: Update Capture Variables [NOT STARTED]

**Goal:** Document all new capture variables for dependency tracking

**Tasks:**
- [ ] Add dependency_map capture variable documentation
- [ ] Add external_dependencies capture variable documentation
- [ ] Update existing Capture section to include new variables
- [ ] Ensure Stage 5 (ReviewAndConfirm) and Stage 6 (CreateTasks) reference these variables

**Timing:** 15 minutes

**Files to modify:**
- `.claude/agents/meta-builder-agent.md` - Update capture documentation in Stage 3

**Verification:**
- Capture section lists: task_list[], dependency_map{}, external_dependencies{}
- Data structures are clearly defined
- Referenced in Stage 5/6 appropriately

---

### Phase 5: Verification and Testing [NOT STARTED]

**Goal:** Validate changes maintain consistent agent structure and functionality

**Tasks:**
- [ ] Review full Stage 3 section for internal consistency
- [ ] Verify Question numbering is sequential (Questions 3, 4, 5, 5b)
- [ ] Confirm Stage 5 can display dependencies correctly with new data
- [ ] Test agent structure with manual review

**Timing:** 15 minutes

**Files to modify:**
- None (verification only)

**Verification:**
- Stage 3 flows logically from Question 3 through Question 5b
- No broken references to other stages
- Interview patterns are consistent with existing style

## Testing & Validation

- [ ] Stage 3 contains Question 5 with proper AskUserQuestion JSON structure
- [ ] Validation logic covers all three checks: self-reference, valid index, circular
- [ ] External dependency capture is optional and clearly marked
- [ ] Capture variables are fully documented
- [ ] No regression in existing Question 3 and Question 4 functionality

## Artifacts & Outputs

- `.claude/agents/meta-builder-agent.md` - Updated with dependency capture enhancements
- `specs/036_enhance_interview_stage3_dependency_capture/plans/implementation-001.md` - This plan
- `specs/036_enhance_interview_stage3_dependency_capture/summaries/implementation-summary-YYYYMMDD.md` - Completion summary

## Rollback/Contingency

If implementation causes issues with meta-builder-agent:
1. Revert changes to meta-builder-agent.md using git
2. Review which specific section caused the issue
3. Apply changes incrementally with validation between phases
