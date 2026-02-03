# Implementation Plan: Task #40

- **Task**: 40 - Standardize multi-task creation patterns
- **Status**: [NOT STARTED]
- **Effort**: 6-8 hours
- **Dependencies**: None
- **Research Inputs**: [specs/040_standardize_multi_task_creation_patterns/reports/research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**:
  - .claude/context/core/formats/plan-format.md
  - .claude/context/core/standards/status-markers.md
  - .claude/context/core/system/artifact-management.md
  - .claude/context/core/standards/tasks.md
- **Type**: meta

## Overview

This task standardizes multi-task creation patterns across 5 commands/agents: /learn, /meta, /review, /errors, and /task --review. The research identified best practices in dependency declaration, topological sorting (Kahn's algorithm), batch insertion, and interactive selection that should be documented and applied consistently. The implementation creates a standard documentation file, then updates each multi-task creator to reference and follow the standard. No shared utility library is created (commands/agents use inline implementations appropriate to their context).

### Research Integration

Key findings from research-001.md:
- /meta has the most sophisticated patterns (7-stage interview, Kahn's sorting, DAG visualization)
- /learn and /review have good interactive selection but limited dependency support
- /errors has automatic task creation without interactive selection
- /task --review uses simple numbered selection with parent_task linking
- 8 core components identified for standardization

## Goals & Non-Goals

**Goals**:
- Create authoritative standard documentation for multi-task creation
- Document required vs optional components clearly
- Ensure all multi-task creators reference the standard
- Add dependency support to commands that lack it (/review, /errors)
- Provide implementation checklist for future multi-task creators

**Non-Goals**:
- Creating a shared bash library (commands/agents have different execution contexts)
- Forcing identical implementations (allow context-appropriate variations)
- Retrofitting DAG visualization to all commands (only /meta needs it)
- Changing /meta patterns (it's the reference implementation)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Standard too prescriptive | Medium | Medium | Define required vs optional components clearly |
| Breaking existing commands | High | Low | Update documentation only, minimal code changes |
| Scope creep into refactoring | Medium | Medium | Focus on documentation, defer code changes to follow-up tasks |

## Implementation Phases

### Phase 1: Create Standard Documentation [NOT STARTED]

**Goal**: Create the authoritative multi-task creation standard document

**Tasks**:
- [ ] Create `.claude/docs/reference/standards/multi-task-creation-standard.md`
- [ ] Define required components (selection, confirmation, state updates)
- [ ] Define optional components (grouping, dependency declaration, sorting, visualization)
- [ ] Include implementation checklist from research
- [ ] Add code examples for each pattern (from /meta as reference)
- [ ] Document state.json dependencies schema

**Timing**: 2 hours

**Files to create**:
- `.claude/docs/reference/standards/multi-task-creation-standard.md`

**Verification**:
- Document exists with all 8 components documented
- Required vs optional components clearly distinguished
- Implementation checklist complete

---

### Phase 2: Update /learn Documentation [NOT STARTED]

**Goal**: Update /learn command to reference and comply with the standard

**Tasks**:
- [ ] Add Standards Reference section pointing to multi-task-creation-standard.md
- [ ] Document current compliance level (interactive selection, topic grouping)
- [ ] Add NOTE about dependency limitations (internal only: learn-it -> fix-it)
- [ ] Consider adding external dependency support (document as future enhancement)

**Timing**: 45 minutes

**Files to modify**:
- `.claude/commands/learn.md` - Add standards reference
- `.claude/skills/skill-learn/SKILL.md` - Add standards reference

**Verification**:
- Both files reference the standard
- Compliance level documented
- Limitations noted

---

### Phase 3: Update /review Documentation [NOT STARTED]

**Goal**: Update /review command to reference standard and note gaps

**Tasks**:
- [ ] Add Standards Reference section
- [ ] Document current compliance (tier-based selection, grouping)
- [ ] Document gaps: no dependency support between created tasks
- [ ] Add TODO for future dependency support enhancement

**Timing**: 45 minutes

**Files to modify**:
- `.claude/commands/review.md` - Add standards reference and gaps

**Verification**:
- File references the standard
- Gaps clearly documented with enhancement TODO

---

### Phase 4: Update /errors Documentation [NOT STARTED]

**Goal**: Update /errors command to reference standard and note gaps

**Tasks**:
- [ ] Add Standards Reference section
- [ ] Document current compliance (automatic task creation from patterns)
- [ ] Document gaps: no interactive selection, no dependency support
- [ ] Add rationale: automatic mode is intentional for error triage workflow

**Timing**: 30 minutes

**Files to modify**:
- `.claude/commands/errors.md` - Add standards reference

**Verification**:
- File references the standard
- Gaps documented with rationale

---

### Phase 5: Update /task --review Documentation [NOT STARTED]

**Goal**: Update /task command's --review mode to reference standard

**Tasks**:
- [ ] Add Standards Reference section to --review mode documentation
- [ ] Document current compliance (numbered selection, parent_task linking)
- [ ] Document gap: no topological sorting for follow-up tasks

**Timing**: 30 minutes

**Files to modify**:
- `.claude/commands/task.md` - Add standards reference to --review section

**Verification**:
- --review mode references the standard
- Compliance documented

---

### Phase 6: Update /meta as Reference Implementation [NOT STARTED]

**Goal**: Mark /meta and meta-builder-agent as the reference implementation

**Tasks**:
- [ ] Add prominent note that /meta is the reference implementation
- [ ] Add Standards Reference section linking to multi-task-creation-standard.md
- [ ] Verify all 8 components are implemented and documented

**Timing**: 30 minutes

**Files to modify**:
- `.claude/commands/meta.md` - Add reference implementation note
- `.claude/agents/meta-builder-agent.md` - Add reference implementation note

**Verification**:
- Both files marked as reference implementation
- All 8 components verified present

---

### Phase 7: Update CLAUDE.md with Standard Reference [NOT STARTED]

**Goal**: Add multi-task creation standard to project configuration index

**Tasks**:
- [ ] Add new section to CLAUDE.md: "Multi-Task Creation Standards"
- [ ] Reference multi-task-creation-standard.md
- [ ] List which commands use multi-task creation
- [ ] Add quick reference for required components

**Timing**: 30 minutes

**Files to modify**:
- `.claude/CLAUDE.md` - Add multi-task creation section

**Verification**:
- Section exists in CLAUDE.md
- Standard properly referenced
- Commands listed

---

### Phase 8: Validation and Summary [NOT STARTED]

**Goal**: Validate all changes and create implementation summary

**Tasks**:
- [ ] Verify all files reference the standard correctly
- [ ] Verify standard document is complete and accurate
- [ ] Run any linting/validation scripts
- [ ] Create implementation summary

**Timing**: 30 minutes

**Files to create**:
- `specs/040_standardize_multi_task_creation_patterns/summaries/implementation-summary-{DATE}.md`

**Verification**:
- All 5 multi-task creators reference the standard
- Standard document complete
- Summary created

## Testing & Validation

- [ ] All modified files pass markdown linting
- [ ] All internal links are valid
- [ ] Standard document contains all 8 components from research
- [ ] Each multi-task creator has Standards Reference section
- [ ] CLAUDE.md includes new section

## Artifacts & Outputs

- `.claude/docs/reference/standards/multi-task-creation-standard.md` - Primary deliverable
- Updated documentation for 5 commands/agents
- Updated CLAUDE.md with standard reference
- `specs/040_standardize_multi_task_creation_patterns/summaries/implementation-summary-{DATE}.md`

## Rollback/Contingency

All changes are documentation-only and additive. Rollback is straightforward:
1. Revert the new standard file creation
2. Revert documentation updates to each command/agent
3. Revert CLAUDE.md section addition

No behavioral changes to commands, so no risk of breaking functionality.
