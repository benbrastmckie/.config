# /todo Command Subagent Delegation Refactor - Implementation Plan

## Metadata
- **Date**: 2025-12-01
- **Feature**: Refactor /todo command to enforce hard barrier subagent delegation pattern
- **Scope**: Migrate TODO.md generation logic from orchestrator to todo-analyzer agent
- **Status**: [COMPLETE]
- **Estimated Phases**: 5
- **Complexity**: 3 (Moderate - Agent expansion + Command refactor + Preservation logic)

## Overview

This plan refactors the `/todo` command to comply with the Hard Barrier Subagent Delegation Pattern used across all other orchestrator commands. Currently, the `/todo` command has a "pseudo-delegation pattern" where the orchestrator performs TODO.md generation work (Block 4) after receiving classification data from the `todo-analyzer` agent. This violates architectural standards requiring that orchestrators ONLY verify outputs and handle workflow coordination - all generation logic must be in the subagent.

**Current Architecture Problem**:
```
Block 1  → Discovery (scan directories, collect plans)
Block 2a → Setup (initialize paths)
Block 2b → Task invocation (classify plans)
Block 2c → Verification (check JSON file exists)
Block 3  → Generation (ORCHESTRATOR generates TODO.md) ← VIOLATION
Block 4  → Write (ORCHESTRATOR writes file) ← VIOLATION
```

**Target Architecture**:
```
Block 1  → Discovery (scan directories, collect plans)
Block 2a → Setup (pre-calculate paths, initialize state)
Block 2b → Task invocation (agent generates complete TODO.md) ← HARD BARRIER
Block 2c → Verification (semantic validation, fail-fast)
Block 3  → File Operations (backup + atomic replace ONLY)
```

**Key Architectural Changes**:
1. **Agent Responsibility Expansion**: `todo-analyzer` generates complete TODO.md content (not just classification JSON)
2. **Pre-Calculation Pattern**: Output paths calculated BEFORE agent runs (like `/research` command)
3. **Enhanced Verification**: Semantic checks (7 sections, Backlog/Saved preservation, checkbox conventions)
4. **Orchestrator Simplification**: Blocks 3-4 reduced to file operations only

## Research Analysis Summary

From research report `/home/benjamin/.config/.claude/specs/004_todo_command_subagent_delegation/reports/001-todo-command-subagent-delegation-analysis.md`:

**Current State**:
- Task invocation exists (Block 2b) but agent returns classification JSON
- Orchestrator reads JSON and performs TODO.md generation in Block 4
- This treats subagent output as input data rather than final artifact

**Standards Violations**:
- Hard Barrier Pattern requires orchestrator ONLY verifies outputs
- Current implementation allows orchestrator to perform generation work
- No semantic validation (only file existence checks)

**Comparison with Compliant Commands**:
- `/research`: Pre-calculates report path, validates content structure
- `/plan`: Pre-calculates plan path, verifies modification occurred
- Both use fail-fast verification with no bypass possible

**Benefits of Refactor**:
- Standards compliance across all commands
- Clear separation of orchestration (command) vs work (agent)
- Improved testability (agent testable independently)
- Reusability (agent logic can be used by other commands)
- No performance degradation (agent already invoked, just does more work)

## Implementation Phases

### Phase 1: Agent Behavioral Guidelines Enhancement [COMPLETE]

**Objective**: Expand `todo-analyzer` agent to generate complete TODO.md content instead of classification JSON.

**Tasks**:

1.1. **Update Agent Input/Output Contract**
   - Change output format from JSON array to complete TODO.md file
   - Add current TODO.md as input (for Backlog/Saved preservation)
   - Add pre-calculated output path as input
   - Document explicit contract requirements

1.2. **Add Backlog/Saved Preservation Algorithm**
   - Extract Backlog section from current TODO.md
   - Extract Saved section from current TODO.md
   - Preserve exact content verbatim (no modifications)
   - Document edge cases (missing sections, malformed content)

1.3. **Add Research Directory Auto-Detection Logic**
   - Scan specs/ for directories with reports/ but no plans/
   - Validate reports/ has markdown files
   - Generate Research entries linking to directories
   - Extract title/description from first report file

1.4. **Add 7-Section Markdown Generation Template**
   - Section order: In Progress → Not Started → Research → Saved → Backlog → Abandoned → Completed
   - Correct checkbox conventions per section
   - Date grouping for Completed section (newest first)
   - Entry format: `- [checkbox] **Title** - Description [path]`
   - Artifact discovery and linking (reports, summaries)

1.5. **Add Artifact Discovery Logic**
   - Use Glob patterns: `specs/{topic}/reports/*.md`, `specs/{topic}/summaries/*.md`
   - Generate indented bullets under each plan entry
   - Format: `- Related reports: [Title](relative/path)`
   - Chronological ordering by filename

1.6. **Update Completion Signal**
   - Change from `PLANS_CLASSIFIED:` to `TODO_GENERATED:`
   - Include output path in signal
   - Include plan count for verification

1.7. **Add Error Handling**
   - Return ERROR_CONTEXT for file operations failures
   - Return TASK_ERROR for validation failures
   - Log all errors with recovery hints

**Deliverables**:
- Updated `.claude/agents/todo-analyzer.md` with expanded behavioral guidelines
- Agent can be tested in isolation with sample inputs
- Agent generates valid 7-section TODO.md structure

**Validation**:
- Agent preserves Backlog section verbatim
- Agent preserves Saved section verbatim
- Agent generates valid 7-section structure
- Agent follows checkbox conventions
- Agent detects research-only directories
- Agent execution time < 15 seconds (Haiku model)

**Dependencies**: None

---

### Phase 2: Command Setup Block Enhancement (Block 2a) [COMPLETE]

**Objective**: Implement pre-calculation pattern for output paths and prepare inputs for agent.

**Tasks**:

2.1. **Add Output Path Pre-Calculation**
   - Calculate `NEW_TODO_PATH` (temp location for generated TODO.md)
   - Calculate `BACKUP_TODO_PATH` (backup of current TODO.md)
   - Validate paths are absolute
   - Document path contract for agent

2.2. **Add Current TODO.md Path Detection**
   - Locate existing TODO.md
   - Handle case where TODO.md doesn't exist (first run)
   - Read current content for Backlog/Saved extraction

2.3. **Persist All Required Variables**
   - Persist `NEW_TODO_PATH`
   - Persist `BACKUP_TODO_PATH`
   - Persist `TODO_PATH` (current location)
   - Persist `DISCOVERED_PROJECTS` (from Block 1)
   - All paths must be absolute

2.4. **Add Checkpoint Reporting**
   - Report all calculated paths
   - Report workflow ID
   - Report project count

**Deliverables**:
- Enhanced Block 2a with path pre-calculation
- All paths persisted to state file
- Checkpoint markers for debugging

**Validation**:
- All paths are absolute
- State file contains all required variables
- Paths are valid and accessible

**Dependencies**: Phase 1 (agent needs to understand path contract)

---

### Phase 3: Command Execute Block Update (Block 2b) [COMPLETE]

**Objective**: Update Task invocation to specify complete TODO.md generation instead of classification JSON.

**Tasks**:

3.1. **Update Task Prompt**
   - Pass current TODO.md path for Backlog/Saved preservation
   - Pass pre-calculated output path (`NEW_TODO_PATH`)
   - Pass discovered projects file
   - Add explicit contract requirement: "You MUST create TODO.md at exact path specified"

3.2. **Update Prompt Instructions**
   - Remove "classify plans" language
   - Add "generate complete TODO.md" language
   - Specify 7-section structure requirement
   - Specify Backlog/Saved preservation requirement
   - Specify Research auto-detection requirement

3.3. **Update Expected Completion Signal**
   - Change from `PLANS_CLASSIFIED:` to `TODO_GENERATED:`
   - Update documentation to reflect new signal

**Deliverables**:
- Updated Block 2b Task invocation
- Agent receives all required inputs
- Explicit contract documented

**Validation**:
- Agent receives correct paths
- Agent understands complete generation requirement
- Completion signal matches expectations

**Dependencies**: Phase 1 (agent must support new behavior), Phase 2 (paths must be pre-calculated)

---

### Phase 4: Command Verification Enhancement (Block 2c) [COMPLETE]

**Objective**: Enhance verification to include semantic checks beyond file existence.

**Tasks**:

4.1. **Add File Existence Verification**
   - Verify `NEW_TODO_PATH` exists
   - Verify file size > 500 bytes (reasonable minimum for non-empty specs)
   - Fail-fast with error logging on missing file

4.2. **Add Semantic Structure Validation**
   - Verify all 7 sections present: In Progress, Not Started, Research, Saved, Backlog, Abandoned, Completed
   - Verify sections in correct order
   - Use grep to check section headers: `^## In Progress`, `^## Not Started`, etc.

4.3. **Add Backlog Preservation Verification**
   - Read Backlog section from `TODO_PATH` (current)
   - Read Backlog section from `NEW_TODO_PATH` (generated)
   - Compare content (must match exactly)
   - Fail-fast if Backlog content modified

4.4. **Add Saved Preservation Verification**
   - Read Saved section from `TODO_PATH` (current)
   - Read Saved section from `NEW_TODO_PATH` (generated)
   - Compare content (must match exactly)
   - Fail-fast if Saved content modified

4.5. **Add Checkbox Convention Validation**
   - Verify In Progress entries use `[x]`
   - Verify Not Started entries use `[ ]`
   - Verify Research entries use `[ ]`
   - Verify Saved entries use `[ ]`
   - Verify Completed entries use `[x]`
   - Verify Abandoned entries use `[x]`

4.6. **Add Plan Count Reconciliation**
   - Count plans in `DISCOVERED_PROJECTS`
   - Count entries in generated TODO.md
   - Warn if counts don't match (not fail-fast - some plans may be in Backlog)

4.7. **Add Quality Checks**
   - Verify markdown validity (basic structure)
   - Verify relative paths are valid
   - Verify no duplicate entries

4.8. **Add Error Logging Integration**
   - Log all verification failures via `log_command_error`
   - Include recovery instructions in error messages
   - Error types: `verification_error`, `validation_error`, `agent_error`

**Deliverables**:
- Enhanced Block 2c with semantic validation
- Fail-fast on all verification failures
- Comprehensive error logging

**Validation**:
- Verification catches missing file
- Verification catches missing sections
- Verification catches Backlog/Saved modifications
- Verification catches checkbox convention violations
- All failures logged with error_type

**Dependencies**: Phase 3 (agent must generate TODO.md), Phase 2 (paths must be available)

---

### Phase 5: Command File Operations Simplification (Block 3-4) [COMPLETE]

**Objective**: Simplify orchestrator Blocks 3-4 to file operations only (no generation logic).

**Tasks**:

5.1. **Eliminate Block 3 (Generation Block)**
   - Remove all TODO.md generation logic from orchestrator
   - Agent now performs this work in Block 2b
   - Delete Block 3 entirely

5.2. **Simplify Block 4 to File Operations Only**
   - Verify `NEW_TODO_PATH` exists (already done in Block 2c, but re-check)
   - Create backup of current TODO.md (if exists)
   - Atomic replace: `mv NEW_TODO_PATH TODO_PATH`
   - Report success

5.3. **Add Backup Strategy**
   - Backup ONLY if agent succeeds (Block 2c passes)
   - Backup filename: `TODO.md.backup.YYYYMMDD_HHMMSS`
   - Keep 5 most recent backups, delete older

5.4. **Handle Dry-Run Mode**
   - Invoke agent to generate TODO.md
   - Preview generated content (read and display)
   - Skip write operation (leave NEW_TODO_PATH for inspection)
   - Report preview location

5.5. **Update Clean Mode (Blocks 4b-4c) Integration**
   - Clean mode: After cleanup, re-invoke todo-analyzer with reduced plan set
   - Use same hard barrier verification
   - Regenerate TODO.md after directories removed

5.6. **Add Error Recovery**
   - If agent fails: fail-fast, log error, no bypass
   - If verification fails: restore from backup
   - If atomic replace fails: keep NEW_TODO_PATH for manual inspection

**Deliverables**:
- Simplified Block 4 (file operations only)
- Block 3 deleted
- Dry-run mode works with new architecture
- Clean mode integration verified

**Validation**:
- No generation logic in orchestrator
- Atomic replace works correctly
- Backup strategy tested
- Dry-run preview works
- Clean mode regeneration works

**Dependencies**: Phase 4 (verification must pass before file operations)

---

## Technical Considerations

### Agent Model Selection

**Current Model**: Haiku 4.5
- **Justification**: Status classification is fast, deterministic task
- **Current Task**: Plan status classification only

**New Task Scope**: Complete TODO.md generation
- **Complexity Increase**: Moderate (template-based generation)
- **Expected Execution Time**: ~5-15 seconds (still well within Haiku capabilities)
- **Token Usage**: Moderate increase (reading current TODO.md + generating new)

**Recommendation**: Keep Haiku 4.5 model. TODO.md generation is deterministic template work suitable for fast model.

### State Persistence Requirements

**Current Variables**:
- `WORKFLOW_ID`
- `DISCOVERED_PROJECTS`
- `CLASSIFIED_RESULTS`
- `SPECS_ROOT`
- `TODO_PATH`

**Additional Variables Needed**:
- `NEW_TODO_PATH` (pre-calculated output path)
- `BACKUP_TODO_PATH` (backup location)
- `CURRENT_TODO_PATH` (input for Backlog/Saved preservation)

**Persistence Pattern**: Use existing `append_workflow_state()` in Block 2a, restore in Block 2c.

### Error Recovery Scenarios

**New Error Scenarios**:
1. Agent fails to preserve Backlog section
   - **Detection**: Block 2c compares Backlog content
   - **Recovery**: Log error, fail-fast, restore from backup

2. Agent generates invalid 7-section structure
   - **Detection**: Block 2c validates section headers
   - **Recovery**: Log error, fail-fast, restore from backup

3. Agent creates duplicate entries
   - **Detection**: Block 2c checks for duplicate plan paths
   - **Recovery**: Log error, manual review required

4. Agent modifies Saved section
   - **Detection**: Block 2c compares Saved content
   - **Recovery**: Log error, fail-fast, restore from backup

**Error Logging Integration**:
- All verification failures log via `log_command_error()`
- Include recovery instructions in error messages
- Preserve backup for manual rollback

### Open Questions Resolution

**Q1. Agent output format: Direct write or temp file?**
- **Answer**: Temp file with atomic replace in orchestrator (Block 4)
- **Rationale**: Preserves current TODO.md until verification passes

**Q2. Research detection: Orchestrator or agent?**
- **Answer**: Agent performs detection
- **Rationale**: Keeps logic consolidated, agent has context of all directories

**Q3. Artifact discovery: Orchestrator or agent?**
- **Answer**: Agent performs discovery
- **Rationale**: Part of generation logic, agent uses Glob tool

**Q4. Backup strategy: Before agent or before replace?**
- **Answer**: Before replace (Block 4)
- **Rationale**: Only backup if agent succeeds and verification passes

**Q5. Dry-run handling: Invoke agent or skip?**
- **Answer**: Invoke agent, preview output, skip write
- **Rationale**: Validates agent behavior, shows what would be written

**Q6. Error recovery: Fallback or fail-fast?**
- **Answer**: Fail-fast (no bypass allowed)
- **Rationale**: Enforces hard barrier pattern, prevents partial updates

**Q7. Clean mode integration: Same agent or separate?**
- **Answer**: Same agent, separate invocation with reduced plan set
- **Rationale**: Reuses same generation logic, maintains consistency

**Q8. Migration path: Preserve old command?**
- **Answer**: Keep backup until refactor proven stable
- **Rationale**: Enables rollback if issues discovered

## Risks and Mitigations

### Risk 1: Agent Complexity Increase

**Concern**: Expanding agent scope might make it harder to maintain.

**Mitigation**:
- Agent already performs batch classification (complex task)
- TODO.md generation is template-based (deterministic)
- Keep agent focused on single responsibility (TODO.md generation)
- Document algorithm clearly in behavioral guidelines
- Add comprehensive test suite

### Risk 2: Backlog/Saved Preservation Failures

**Concern**: Agent might inadvertently modify manually-curated sections.

**Mitigation**:
- Implement explicit preservation algorithm in agent
- Add verification checks in Block 2c (exact content match)
- Test thoroughly with various Backlog/Saved formats
- Document preservation requirements clearly
- Fail-fast on any modification detected

### Risk 3: Migration Complexity

**Concern**: Refactoring might introduce regressions.

**Mitigation**:
- Keep current command as backup during development
- Create comprehensive test suite before refactor
- Implement in phases (agent first, then command)
- Test each phase independently before integration
- Use git branches for incremental commits

### Risk 4: Research Auto-Detection Edge Cases

**Concern**: Auto-detection logic might misclassify directories.

**Mitigation**:
- Document detection rules clearly (reports/ exists, plans/ empty)
- Add validation checks (directory must have markdown files)
- Test with edge cases (empty reports/, stale directories)
- Allow manual override in Backlog section
- Log detection decisions for debugging

## Validation Criteria

### Phase 1 Validation [COMPLETE]
- [x] Agent generates valid TODO.md with 7 sections
- [x] Backlog section preserved verbatim
- [x] Saved section preserved verbatim
- [x] Research directories auto-detected correctly
- [x] Checkbox conventions followed
- [x] Artifact links generated correctly
- [x] Agent execution time < 15 seconds

### Phase 2 Validation [COMPLETE]
- [x] All paths calculated before agent runs
- [x] All paths are absolute
- [x] State file contains all required variables
- [x] Checkpoint reporting works

### Phase 3 Validation [COMPLETE]
- [x] Agent receives correct paths
- [x] Agent understands generation contract
- [x] Completion signal correct

### Phase 4 Validation [COMPLETE]
- [x] File existence check works
- [x] 7-section structure validated
- [x] Backlog preservation verified
- [x] Saved preservation verified
- [x] Checkbox conventions validated
- [x] Plan count reconciliation works
- [x] Error logging works

### Phase 5 Validation [COMPLETE]
- [x] No generation logic in orchestrator
- [x] Atomic replace works
- [x] Backup strategy works
- [x] Dry-run mode works
- [x] Clean mode integration works
- [x] Error recovery works

## Success Metrics

### Architectural Compliance
- [ ] Hard barrier pattern enforced (bypass impossible)
- [ ] Clear separation of orchestrator vs agent responsibilities
- [ ] Consistent with `/research`, `/plan`, `/build` patterns
- [ ] Agent logic reusable by other commands

### Operational Quality
- [ ] No performance degradation (agent execution time < 15s)
- [ ] Error recovery with explicit checkpoints
- [ ] Fail-fast verification prevents partial updates
- [ ] Comprehensive error logging

### Maintainability
- [ ] TODO.md generation logic in one place (agent)
- [ ] Agent testable independently
- [ ] Clear documentation of generation algorithm
- [ ] Validation suite covers all scenarios

## Related Documentation

### Standards and Patterns
- [Hard Barrier Subagent Delegation Pattern](.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md)
- [Command Authoring Standards](.claude/docs/reference/standards/command-authoring.md)
- [TODO Organization Standards](.claude/docs/reference/standards/todo-organization-standards.md)
- [Output Formatting Standards](.claude/docs/reference/standards/output-formatting.md)

### Reference Commands
- `/research` - Pre-calculation pattern example
- `/plan` - Plan revision verification example
- `/build` - Multi-phase hard barrier example

### Research Reports
- [001-todo-command-subagent-delegation-analysis.md](../reports/001-todo-command-subagent-delegation-analysis.md) - Complete analysis of current implementation and refactor requirements

## Implementation Notes

### Execution Order
1. Phase 1: Agent enhancement (can be developed and tested independently)
2. Phase 2: Command setup block (prepares contract for agent)
3. Phase 3: Command execute block (invokes agent with new contract)
4. Phase 4: Command verification (validates agent output)
5. Phase 5: File operations simplification (completes refactor)

### Testing Strategy
- Unit tests for agent in isolation (Phase 1)
- Integration tests for command-agent interaction (Phases 2-4)
- End-to-end tests for complete workflow (Phase 5)
- Regression tests for Backlog/Saved preservation

### Git Strategy
- Feature branch for development: `feature/todo-command-hard-barrier`
- Commit after each phase completion
- Tag stable milestones: `todo-refactor-phase-N`
- Keep backup branch until refactor proven stable

---

**PLAN_CREATED**: /home/benjamin/.config/.claude/specs/004_todo_command_subagent_delegation/plans/001-todo-command-subagent-delegation-plan.md
