# Implementation Plan: Task #38

- **Task**: 38 - Update TODO.md insertion for dependency order
- **Status**: [NOT STARTED]
- **Effort**: 1-2 hours
- **Dependencies**: None
- **Research Inputs**: specs/038_update_todomd_insertion_dependency_order/reports/research-001.md
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: meta

## Overview

Modify the TODO.md insertion logic in meta-builder-agent.md Stage 6 to use batch insertion instead of individual prepends. Currently, Task 37's topological sorting ensures foundational tasks are created first, but the prepend-each pattern causes the most dependent task to appear at the top of TODO.md. This plan changes the insertion to build all task entries in sorted order and insert them as a single batch, preserving the foundational-first ordering.

### Research Integration

Research report research-001.md recommends Approach 2 (batch insertion) because:
- Aligns with "foundational first" narrative from topological sorting
- Tasks are inserted in creation order (clear mental model)
- Future-proof for dependency visualization (Task 39)

## Goals & Non-Goals

**Goals**:
- Change TODO.md insertion from prepend-each to batch insertion in sorted order
- Ensure foundational tasks (lower numbers) appear higher in TODO.md file
- Maintain consistency with single-task creation commands (which still prepend)

**Non-Goals**:
- Modify single-task commands (/task, /learn) - these correctly prepend single tasks
- Change state.json ordering - unaffected by TODO.md changes
- Implement dependency visualization (Task 39)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Batch insertion edge cases | M | L | Test with 0, 1, N tasks; verify empty dependency_map handling |
| Documentation inconsistency | L | M | Review and update all Stage 6 references for batch semantics |
| Existing behavior regression | M | L | Verify single-task prepend pattern unchanged elsewhere |

## Implementation Phases

### Phase 1: Update Stage 6 CreateTasks Documentation [NOT STARTED]

**Goal**: Modify the TODO.md update instructions in Stage 6 to specify batch insertion semantics

**Tasks**:
- [ ] Read meta-builder-agent.md lines 747-757 (Stage 6: Status Updates section)
- [ ] Replace "Prepend task entry to ## Tasks section" with batch insertion instructions
- [ ] Add explanation that batch preserves topological order (foundational first)
- [ ] Specify that the batch as a whole is prepended (before existing tasks)

**Timing**: 30 minutes

**Files to modify**:
- `.claude/agents/meta-builder-agent.md` - Stage 6 Status Updates section (lines 747-757)

**Verification**:
- Stage 6 instructions clearly describe batch building and single insertion
- No references to "prepend each task" remain in Stage 6

---

### Phase 2: Add Batch Building Implementation Pattern [NOT STARTED]

**Goal**: Add concrete implementation guidance for building the task entry batch

**Tasks**:
- [ ] Add pseudocode/pattern after the task creation loop (lines 502-515)
- [ ] Show building all entries in a markdown block ordered by sorted_indices
- [ ] Show single insertion after ## Tasks heading
- [ ] Document that this preserves foundational-first ordering

**Timing**: 30 minutes

**Files to modify**:
- `.claude/agents/meta-builder-agent.md` - After CreateTasks loop section (around line 515)

**Verification**:
- Implementation pattern shows batch building with loop over sorted_indices
- Pattern shows single insertion operation
- Comment explains why batch insertion preserves order

---

### Phase 3: Update DeliverSummary Stage Documentation [NOT STARTED]

**Goal**: Ensure Stage 7 DeliverSummary reflects correct task ordering in output

**Tasks**:
- [ ] Review DeliverSummary section (lines 541-567)
- [ ] Verify "Suggested Order" guidance matches batch insertion behavior
- [ ] Update any references that imply reversed ordering
- [ ] Confirm note about topological ordering is accurate

**Timing**: 15 minutes

**Files to modify**:
- `.claude/agents/meta-builder-agent.md` - Interview Stage 7 DeliverSummary (lines 541-567)

**Verification**:
- DeliverSummary output reflects tasks in correct dependency order
- "Suggested Order" guidance aligns with actual TODO.md file order

---

### Phase 4: Verification and Edge Case Testing [NOT STARTED]

**Goal**: Verify the changes work correctly through manual review

**Tasks**:
- [ ] Read complete modified meta-builder-agent.md to verify consistency
- [ ] Verify edge cases are handled in documentation:
  - Tasks with no internal dependencies (all foundational)
  - Single task (no batch needed)
  - Mixed internal and external dependencies
- [ ] Confirm no conflicting instructions remain

**Timing**: 15 minutes

**Files to modify**:
- None (verification only)

**Verification**:
- All Stage 6 references use batch insertion semantics
- Edge cases documented or handled gracefully
- No conflicting prepend-each instructions remain in batch creation context

## Testing & Validation

- [ ] Review full meta-builder-agent.md for Stage 6 consistency
- [ ] Verify Stage 7 DeliverSummary aligns with insertion behavior
- [ ] Confirm single-task commands (/task, /learn) not affected
- [ ] Edge cases documented: empty deps, single task, external deps only

## Artifacts & Outputs

- plans/implementation-001.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (on completion)
- Modified: .claude/agents/meta-builder-agent.md

## Rollback/Contingency

If changes cause issues with meta-builder-agent task creation:
1. Revert meta-builder-agent.md to previous git commit
2. Single-task behavior remains unaffected (separate code paths)
3. Re-analyze with research report for alternative approach (reverse iteration)
