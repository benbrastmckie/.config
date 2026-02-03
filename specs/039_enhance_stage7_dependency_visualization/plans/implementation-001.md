# Implementation Plan: Task #39

- **Task**: 39 - Enhance Stage 7 DeliverSummary Dependency Visualization
- **Status**: [COMPLETED]
- **Effort**: 2-3 hours
- **Dependencies**: Task #37 (topological sorting), Task #38 (batch insertion)
- **Research Inputs**: [specs/039_enhance_stage7_dependency_visualization/reports/research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: meta
- **Lean Intent**: false

## Overview

Enhance the Stage 7 DeliverSummary section in meta-builder-agent.md to include ASCII dependency graph visualization and execution order based on actual assigned task numbers. The current DeliverSummary output (lines 583-610) uses generic placeholders and inline dependency mentions, but lacks visual representation of the dependency DAG. This implementation integrates with the topological sorting (Task 37) and batch insertion (Task 38) work to produce clear, actionable output showing dependency relationships between newly created tasks.

### Research Integration

Key findings from research-001.md:
- Current DeliverSummary lacks visual DAG representation and uses generic placeholders
- Data structures available after Stage 6: `task_list[]`, `sorted_indices[]`, `task_number_map{}`, `dependency_map{}`, `external_dependencies{}`
- Recommended approach: complexity detection to choose between simple (linear) and complex (diamond/branch) visualization patterns
- Unicode box-drawing characters are the project standard (per nvim/CLAUDE.md lines 77-121)

## Goals & Non-Goals

**Goals**:
- Add dependency graph visualization to DeliverSummary output
- Show execution order with actual assigned task numbers
- Support both simple (linear chain) and complex (diamond, parallel) dependency patterns
- Handle external dependencies (on existing tasks)
- Follow project Unicode box-drawing standards

**Non-Goals**:
- Interactive graph manipulation
- ANSI color coding (terminal detection complexity)
- Graphviz/DOT output format
- Real-time graph updates

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Complex DAG rendering edge cases | Medium | Medium | Use simple linear format as fallback; test with variety of dependency patterns |
| Box-drawing character rendering issues | Low | Low | Characters are already used throughout codebase; consistent UTF-8 encoding |
| Long task titles overflow | Low | Medium | Truncate titles to 30 characters in graph display |

## Implementation Phases

### Phase 1: Add Complexity Detection Logic [COMPLETED]

**Goal**: Implement logic to determine whether to use simple or complex visualization

**Tasks**:
- [ ] Add complexity detection algorithm after batch insertion section (after line 581)
- [ ] Define criteria: linear chain vs multi-branch/diamond patterns
- [ ] Include helper function documentation for `is_complex_dag()` and `is_linear_chain()`

**Timing**: 30 minutes

**Files to modify**:
- `.claude/agents/meta-builder-agent.md` - Insert after line 581

**Verification**:
- Complexity detection logic is documented with clear criteria
- Algorithm correctly identifies linear vs complex patterns

---

### Phase 2: Add Graph Generation Algorithm [COMPLETED]

**Goal**: Document the ASCII dependency graph generation algorithm

**Tasks**:
- [ ] Add `generate_execution_summary()` function documentation
- [ ] Document linear graph generation (`generate_linear_graph()`)
- [ ] Document layered/complex graph generation (`generate_layered_graph()`)
- [ ] Include handling for external dependencies display

**Timing**: 45 minutes

**Files to modify**:
- `.claude/agents/meta-builder-agent.md` - Insert after complexity detection section

**Verification**:
- Algorithm produces valid ASCII output for sample inputs
- External dependencies are clearly distinguished

---

### Phase 3: Update DeliverSummary Template [COMPLETED]

**Goal**: Replace current DeliverSummary template with enhanced format

**Tasks**:
- [ ] Replace lines 585-610 with new template structure
- [ ] Add task table with columns: #, Task, Depends On, Path
- [ ] Add dependency graph placeholder section
- [ ] Add execution order section with actual task numbers
- [ ] Update Next Steps to reference first foundational task number

**Timing**: 30 minutes

**Files to modify**:
- `.claude/agents/meta-builder-agent.md` - Replace lines 585-610

**Verification**:
- Template includes all required sections
- Placeholders use consistent naming

---

### Phase 4: Add Example Outputs [COMPLETED]

**Goal**: Provide concrete examples of visualization output

**Tasks**:
- [ ] Add Example 1: Linear chain (3 tasks, simple visualization)
- [ ] Add Example 2: Diamond pattern (4 tasks, complex visualization)
- [ ] Add Example 3: External dependencies (task depending on existing #35)
- [ ] Include "Parallel execution possible" annotation where applicable

**Timing**: 30 minutes

**Files to modify**:
- `.claude/agents/meta-builder-agent.md` - Add after updated DeliverSummary template

**Verification**:
- Examples render correctly in markdown
- Each example demonstrates a distinct pattern

---

### Phase 5: Verification and Testing [COMPLETED]

**Goal**: Validate the implementation is complete and correct

**Tasks**:
- [ ] Read modified meta-builder-agent.md and verify structure
- [ ] Check line numbers are consistent after edits
- [ ] Verify Unicode box-drawing characters render correctly
- [ ] Ensure no duplicate sections or broken references
- [ ] Test mental walkthrough of algorithm with sample inputs

**Timing**: 30 minutes

**Files to verify**:
- `.claude/agents/meta-builder-agent.md` - Full file verification

**Verification**:
- All sections are present and well-formed
- No syntax errors in markdown
- Cross-references are accurate

---

## Testing & Validation

- [ ] Verify complexity detection algorithm correctly classifies linear vs complex DAGs
- [ ] Verify graph generation produces valid ASCII for linear chains
- [ ] Verify graph generation produces valid ASCII for diamond patterns
- [ ] Verify external dependencies are displayed with correct notation
- [ ] Verify execution order lists tasks in topological order
- [ ] Verify Next Steps references correct first foundational task number
- [ ] Visual inspection: markdown renders correctly in preview

## Artifacts & Outputs

- `.claude/agents/meta-builder-agent.md` - Enhanced with dependency visualization
- `specs/039_enhance_stage7_dependency_visualization/summaries/implementation-summary-YYYYMMDD.md` - Completion summary

## Rollback/Contingency

If implementation causes issues:
1. Revert meta-builder-agent.md to pre-implementation state via git
2. The existing DeliverSummary output (generic list) remains functional
3. No external dependencies or state changes beyond the agent file
