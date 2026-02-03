# Implementation Plan: Task #35

- **Task**: 35 - Add dependencies field to state.json schema
- **Status**: [COMPLETED]
- **Effort**: 1-2 hours
- **Dependencies**: None
- **Research Inputs**: specs/035_add_dependencies_field_to_state_schema/reports/research-001.md
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: state-management.md, artifact-formats.md
- **Type**: meta
- **Lean Intent**: false

## Overview

This task documents the `dependencies` field in the state-management.md schema. The field is already implemented in state.json for tasks 35-39 but lacks formal documentation. The plan modifies state-management.md in four locations to add field definition, specification, validation requirements, and TODO.md format updates.

### Research Integration

Research confirmed:
1. The `dependencies` field exists in state.json for tasks 35-39 as `array of integers`
2. TODO.md already uses human-readable format: `- **Dependencies**: Task #35, Task #36`
3. Four specific locations in state-management.md need updates (lines 78-98, field table, validation section, TODO.md entry format)
4. Conversion rules: `[]` <-> `None`, `[35]` <-> `Task #35`, `[35, 36]` <-> `Task #35, Task #36`

## Goals & Non-Goals

**Goals**:
- Document the `dependencies` field in state.json schema
- Add field specification with type, default, and description
- Document validation requirements for dependencies
- Update TODO.md entry format documentation

**Non-Goals**:
- Interview capture logic changes (task 36)
- Topological sorting implementation (task 37)
- TODO.md insertion ordering (task 38)
- Dependency visualization (task 39)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Documentation inconsistency | Low | Low | Cross-reference existing implementation |
| Schema ambiguity | Medium | Low | Include concrete examples |

## Implementation Phases

### Phase 1: Update state.json Entry Schema [COMPLETED]

**Goal**: Add dependencies field to the state.json entry example

**Tasks**:
- [ ] Add `"dependencies": [332, 333],` line to state.json Entry example (after line 87)
- [ ] Ensure field placement follows existing pattern (after `last_updated`, before `artifacts`)

**Timing**: 15 minutes

**Files to modify**:
- `.claude/rules/state-management.md` - Lines 78-98, state.json Entry section

**Steps**:
1. Read state-management.md to confirm exact line numbers
2. Insert `"dependencies": [332, 333],` after `"last_updated"` line in the JSON example
3. Verify JSON syntax is valid in the example

**Verification**:
- Example shows dependencies field with sample values
- JSON syntax is valid (commas in correct positions)

---

### Phase 2: Add Field Documentation [COMPLETED]

**Goal**: Add dependencies field to the field specification documentation

**Tasks**:
- [ ] Create new section "### Dependencies Field Schema" after "Completion Fields Schema" section
- [ ] Add field specification table with type, required status, and description
- [ ] Include conversion rules between state.json and TODO.md formats

**Timing**: 20 minutes

**Files to modify**:
- `.claude/rules/state-management.md` - After line 173 (after Completion Fields Schema section)

**Steps**:
1. Add new section header "### Dependencies Field Schema"
2. Add field specification table:
   - Field: `dependencies`
   - Type: `array of integers`
   - Required: No (defaults to `[]`)
   - Description: Task numbers that must complete before this task can start
3. Add conversion rules subsection documenting state.json to TODO.md format mapping

**Verification**:
- Field specification table is complete and accurate
- Conversion rules match existing implementation

---

### Phase 3: Add Validation Requirements [COMPLETED]

**Goal**: Document validation requirements for the dependencies field

**Tasks**:
- [ ] Add validation rules section within Dependencies Field Schema
- [ ] Document valid reference constraint (must exist in active_projects)
- [ ] Document no circular dependencies rule
- [ ] Note that validation is implementation responsibility of meta-builder-agent

**Timing**: 15 minutes

**Files to modify**:
- `.claude/rules/state-management.md` - Within new Dependencies Field Schema section

**Steps**:
1. Add "**Validation Requirements**:" subsection
2. Document three validation rules:
   - Valid References: All task numbers must exist in active_projects
   - No Circular Dependencies: A task cannot depend on itself or create cycles
   - No Self-Reference: Task cannot include its own number in dependencies

**Verification**:
- Validation rules are clear and actionable
- Rules match existing implementation behavior

---

### Phase 4: Update TODO.md Entry Format [COMPLETED]

**Goal**: Add Dependencies line to TODO.md entry format documentation

**Tasks**:
- [ ] Add `- **Dependencies**: Task #{N}, Task #{N} OR None` to TODO.md Entry format
- [ ] Position after Language line, before Started line

**Timing**: 10 minutes

**Files to modify**:
- `.claude/rules/state-management.md` - Lines 64-76, TODO.md Entry section

**Steps**:
1. Locate TODO.md Entry section (lines 64-76)
2. Add Dependencies line after Language line:
   ```markdown
   - **Dependencies**: Task #{N}, Task #{N}  OR  None
   ```
3. Ensure consistent formatting with other fields

**Verification**:
- TODO.md entry format includes Dependencies line
- Format matches existing entries in TODO.md for tasks 35-39

---

## Testing & Validation

- [ ] state.json Entry example includes dependencies field with valid syntax
- [ ] Field specification table is complete with type, required status, description
- [ ] Validation requirements section documents all constraints
- [ ] TODO.md Entry format includes Dependencies line
- [ ] All markdown formatting is correct and consistent

## Artifacts & Outputs

- Modified: `.claude/rules/state-management.md` with four updates:
  1. state.json Entry example with dependencies field
  2. Dependencies Field Schema section with field specification
  3. Validation requirements documentation
  4. TODO.md Entry format with Dependencies line

## Rollback/Contingency

If implementation introduces inconsistencies:
1. Revert state-management.md changes via `git checkout`
2. Review research report for correct format specifications
3. Re-implement with corrections
