# /todo Command Subagent Delegation Refactor Analysis

## Executive Summary

The `/todo` command currently violates architectural standards by performing plan classification work directly in the primary orchestrator agent (Block 4) instead of delegating to the `todo-analyzer` subagent via the Task tool. While the command structure references the `todo-analyzer` agent in frontmatter and includes Task invocation syntax in Block 2b, the actual TODO.md generation happens inline during Block 4, bypassing subagent delegation entirely.

**Key Finding**: The current implementation uses a **pseudo-delegation pattern** where the Task invocation in Block 2b appears valid but the orchestrator performs all TODO.md generation logic directly in Block 4 without consuming the subagent's output.

**Recommended Approach**: Refactor to implement the **Hard Barrier Subagent Delegation Pattern** with explicit Setup → Execute → Verify phases that enforce mandatory delegation and prevent bypass.

---

## Current Implementation Analysis

### Current Architecture Overview

```
Block 1  (Setup)         → Scan directories, discover plans
Block 2a (Setup)         → Initialize classification paths
Block 2b (Execute?)      → Task invocation (pseudo-delegation)
Block 2c (Verify?)       → Verification block exists but minimal
Block 3  (Generate)      → TODO.md generation (ORCHESTRATOR DOES THIS)
Block 4  (Write)         → File write logic (ORCHESTRATOR DOES THIS)
Block 4a-4c (Clean Mode) → Cleanup workflow
```

### Current Delegation Pattern (Block 2b)

The command includes a Task invocation that appears correct:

```markdown
## Block 2b: Status Classification Execution

**CRITICAL BARRIER**: This block MUST invoke todo-analyzer via Task tool.
Verification block (2c) will FAIL if classified results not created.

**EXECUTE NOW**: Invoke todo-analyzer subagent for batch plan classification.

Task {
  subagent_type: "general-purpose"
  model: "haiku"
  description: "Classify plan statuses for TODO.md organization"
  prompt: |
    Read and follow ALL instructions in: .claude/agents/todo-analyzer.md

    **YOUR TASK**: Classify status for ALL plans in the discovered projects file.

    Input Files:
    - Plans File: ${DISCOVERED_PROJECTS}
    - Output File: ${CLASSIFIED_RESULTS}

    [... agent instructions ...]
}
```

**However**: The actual TODO.md generation in Block 4 is performed entirely by the orchestrator, suggesting the subagent output may not be properly consumed or the orchestrator is duplicating the classification logic.

### Current Verification Pattern (Block 2c)

```bash
# Block 2c verifies the classified results file exists
if [ ! -f "$CLASSIFIED_RESULTS" ]; then
  log_command_error ... "Classified results file missing"
  exit 1
fi

# Verifies file size and JSON validity
FILE_SIZE=$(stat -f%z "$CLASSIFIED_RESULTS" ...)
if [ "$FILE_SIZE" -lt 10 ]; then
  log_command_error ... "Classified results file too small"
  exit 1
fi

# Verifies JSON validity
if ! jq empty "$CLASSIFIED_RESULTS" 2>/dev/null; then
  log_command_error ... "Invalid JSON"
  exit 1
fi
```

**Assessment**: Verification checks artifact existence and format but doesn't validate semantic correctness (plan classifications, section assignments).

### Critical Issue: Inline Generation in Block 4

Block 4 is titled "Write TODO.md File" but contains logic to "generate the TODO.md content" suggesting the orchestrator performs the work:

```markdown
## Block 4: Write TODO.md File

**EXECUTE NOW**: Write the generated TODO.md content to file.

Based on the classified plans from todo-analyzer, generate the TODO.md content with proper section organization:

1. Read classified plans from Block 2 output
2. Auto-detect research-only directories (reports/ but no plans/)
3. Group plans by section (In Progress, Not Started, Research, Saved, Backlog, Abandoned, Completed)
4. Preserve existing Backlog and Saved section content
5. Generate entries with proper checkbox conventions
6. Include related artifacts (reports, summaries) as indented bullets
7. Write to TODO.md (or display if --dry-run)
```

**Problem**: This describes orchestrator work that should have been done by the subagent.

---

## Standards Compliance Analysis

### Hard Barrier Subagent Delegation Pattern

**Required Pattern** (from `.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md`):

```
Block N: Phase Name
├── Block Na: Setup
│   ├── State transition (fail-fast gate)
│   ├── Variable persistence (paths, metadata)
│   └── Checkpoint reporting
├── Block Nb: Execute [CRITICAL BARRIER]
│   └── Task invocation (MANDATORY)
└── Block Nc: Verify
    ├── Artifact existence check
    ├── Fail-fast on missing outputs
    └── Error logging with recovery hints
```

**Current /todo Implementation**:
- ✓ Block 2a: Setup pattern exists
- ✓ Block 2b: Task invocation exists (but may not be properly consumed)
- ⚠ Block 2c: Verification exists but insufficient
- ✗ Block 3-4: Orchestrator performs generation work that should be delegated

**Gap**: The hard barrier pattern requires that the orchestrator ONLY verify outputs and handle workflow coordination. All classification and generation logic must be in the subagent.

### Command Authoring Standards Compliance

**Required Patterns** (from `.claude/docs/reference/standards/command-authoring.md`):

1. **Task Tool Invocation**: ✓ Present (Block 2b)
2. **Completion Signal**: ⚠ Agent returns `PLANS_CLASSIFIED:` but orchestrator may not consume it
3. **Fail-Fast Verification**: ⚠ File existence checks present but semantic validation missing
4. **No Inline Work**: ✗ Orchestrator performs TODO.md generation in Block 4

**Finding**: While the command has Task invocation structure, it doesn't fully comply with the delegation enforcement standards.

---

## Comparison with Standard Commands

### /research Command Pattern (Compliant Example)

The `/research` command demonstrates proper hard barrier implementation:

```markdown
## Block 1d: Report Path Pre-Calculation
- Calculates REPORT_PATH before agent invocation
- Persists path to state file

## Block 1d-exec: Research Specialist Invocation
**HARD BARRIER**: This block MUST invoke research-specialist via Task tool.

Task {
  prompt: |
    **Input Contract (Hard Barrier Pattern)**:
    - Report Path: ${REPORT_PATH}

    **CRITICAL**: You MUST create the report file at the EXACT path specified.
}

## Block 1e: Agent Output Validation (Hard Barrier)
- Verifies report file exists at EXACT pre-calculated path
- Validates file size (>100 bytes)
- Validates content (checks for required sections)
- Fail-fast on any validation failure
```

**Key Differences from /todo**:
1. **Pre-calculation**: Path calculated BEFORE agent runs (explicit contract)
2. **Explicit Contract**: Agent receives exact output path as requirement
3. **Semantic Validation**: Checks content structure, not just file existence
4. **No Fallback**: Missing file = hard failure (no orchestrator bypass)

### /plan Command Pattern (Compliant Example)

The `/plan` command shows proper separation:

```markdown
## Block 5a: Plan Revision Setup
- Creates backup before agent runs
- State transition as gate
- Persists backup path

## Block 5b: Plan Revision Execution
**CRITICAL BARRIER**: Must invoke plan-architect via Task tool.

Task {
  prompt: |
    Use Edit tool (NOT Write) to revise the existing plan.
    Return PLAN_REVISED signal when done.
}

## Block 5c: Plan Revision Verification
- Verifies backup still exists
- Verifies plan was modified (timestamp and diff check)
- Fail-fast if plan unchanged
```

**Differences from /todo**:
1. **Artifact Modification**: Verifies plan was changed (not just created)
2. **Multiple Checks**: Timestamp AND content comparison
3. **Clear Contract**: Agent must use Edit tool (explicit requirement)

---

## Root Cause Analysis

### Why Current Implementation Bypasses Delegation

**Evidence from /todo Output** (`.claude/output/todo-output.md`):

```
● Now executing Block 2b - invoking the todo-analyzer subagent:
● Task(Classify plan statuses for TODO.md)
  ⎿  Done (20 tool uses · 131.9k tokens · 1m 8s)

● Now I'll execute Block 3 and Block 4 to generate and write the TODO.md.
  Let me first read the classified results and the current TODO.md to preserve
  the Backlog section:

● Read(.claude/tmp/todo_classified_todo_1764619025.json)
● Read(.claude/TODO.md)

● Now I need to also scan for research-only directories...
```

**Analysis**:
1. ✓ Subagent IS invoked (131.9k tokens, 1m 8s execution)
2. ✓ Classified results ARE created
3. ✗ Orchestrator THEN reads results and performs additional work:
   - Reads classified results JSON
   - Reads current TODO.md
   - Scans for research-only directories
   - Generates TODO.md content

**Problem**: The orchestrator treats subagent output as **input data** for its own generation logic rather than as the **final artifact**.

### Why This Violates Standards

From Hard Barrier Pattern documentation:

> The orchestrator ONLY verifies outputs and handles workflow coordination. All classification and generation logic must be in the subagent.

**Current /todo**: Orchestrator performs TODO.md generation logic using subagent output as raw data.

**Expected Pattern**: Subagent generates complete TODO.md content; orchestrator only writes file.

---

## Refactor Requirements

### Primary Objective

**Migrate TODO.md generation logic from orchestrator (Block 4) to todo-analyzer subagent**.

### Required Changes

#### 1. Subagent Responsibility Expansion

**Current `todo-analyzer` Scope**:
- Classify individual plan status
- Return JSON with status, title, description, phase counts

**New `todo-analyzer` Scope** (expanded):
- Classify all plans in batch (already does this)
- Auto-detect research-only directories
- Preserve existing Backlog and Saved sections
- Generate complete TODO.md markdown content
- Return path to generated TODO.md file

**Agent Output Change**:
- FROM: JSON array of classified plans
- TO: Complete TODO.md file + classification metadata

#### 2. Pre-Calculation Pattern (Like /research)

**Block 2a** should pre-calculate:
- TODO.md output path
- Current TODO.md backup path
- Research directory path for auto-detection
- Backlog/Saved section preservation paths

**Block 2b** Task prompt should provide:
- Input: `DISCOVERED_PROJECTS` JSON file
- Input: Current `TODO.md` (for Backlog/Saved preservation)
- Output: `NEW_TODO_PATH` (pre-calculated)
- Contract: Agent MUST create file at exact output path

#### 3. Enhanced Verification (Block 2c)

**Semantic Validation** (not just existence):
- Verify all 7 sections present (In Progress, Not Started, Research, Saved, Backlog, Abandoned, Completed)
- Verify Backlog section preserved verbatim
- Verify Saved section preserved verbatim
- Verify checkbox conventions correct
- Verify plan count matches discovery count
- Verify no duplicate entries

**Quality Checks**:
- File size > reasonable minimum (e.g., 500 bytes for non-empty specs)
- Valid markdown structure
- All plan paths are valid relative paths
- Research entries link to directories (not files)

#### 4. Orchestrator Role Reduction

**Block 3** (current generation block) should be **eliminated**.

**Block 4** (current write block) should be **simplified** to:
```bash
# Verify TODO.md generated by subagent
if [ ! -f "$NEW_TODO_PATH" ]; then
  log_command_error "verification_error" "TODO.md not generated"
  exit 1
fi

# Backup current TODO.md
if [ -f "$TODO_PATH" ]; then
  cp "$TODO_PATH" "${TODO_PATH}.backup"
fi

# Atomic replace
mv "$NEW_TODO_PATH" "$TODO_PATH"

echo "TODO.md updated successfully"
```

---

## Implementation Plan Outline

### Phase 1: Agent Enhancement

**Objective**: Expand `todo-analyzer` agent to generate complete TODO.md content.

**Tasks**:
1. Update agent behavioral guidelines to include:
   - Backlog/Saved section preservation algorithm
   - Research directory auto-detection logic
   - 7-section markdown generation template
   - Artifact discovery and linking (reports, summaries)
2. Modify agent output format:
   - FROM: JSON array of classifications
   - TO: Complete TODO.md file at pre-calculated path
3. Add agent completion signal:
   - `TODO_GENERATED: ${NEW_TODO_PATH}`
4. Test agent in isolation with sample inputs

**Validation Criteria**:
- Agent can parse existing TODO.md
- Agent preserves Backlog section verbatim
- Agent preserves Saved section verbatim
- Agent generates valid 7-section structure
- Agent follows checkbox conventions
- Agent detects research-only directories
- Agent execution time < 2 minutes (Haiku model)

### Phase 2: Command Refactor

**Objective**: Refactor `/todo` command to enforce hard barrier delegation.

**Tasks**:
1. **Block 2a Enhancement**:
   - Pre-calculate `NEW_TODO_PATH` (temp location)
   - Pre-calculate `BACKUP_TODO_PATH`
   - Detect research directories in advance (optional - could be delegated)
   - Persist all paths to state file

2. **Block 2b Update** (Task Invocation):
   - Update prompt to specify complete TODO.md generation
   - Pass current TODO.md path for Backlog/Saved preservation
   - Pass pre-calculated output path
   - Add explicit contract requirement

3. **Block 2c Enhancement** (Verification):
   - Add semantic validation (7 sections present)
   - Add Backlog/Saved preservation checks
   - Add checkbox convention validation
   - Add plan count reconciliation
   - Add quality checks (file size, markdown validity)

4. **Block 3 Elimination**:
   - Remove generation logic entirely

5. **Block 4 Simplification**:
   - Only file operations (backup, atomic replace)
   - No generation logic
   - Fail-fast on missing output

**Validation Criteria**:
- Command cannot bypass subagent (structural enforcement)
- Verification catches all failure modes
- Orchestrator performs no classification or generation
- Clean mode still works correctly
- Dry-run mode still works correctly

### Phase 3: Clean Mode Adaptation

**Objective**: Ensure clean mode (Blocks 4b-4c) works with new architecture.

**Tasks**:
1. Update Block 4b to use subagent output (if applicable)
2. Update Block 4c (TODO.md regeneration after cleanup) to:
   - Re-invoke todo-analyzer with reduced plan set
   - Use same hard barrier verification
3. Test cleanup workflow end-to-end

**Validation Criteria**:
- Clean mode removes correct directories
- TODO.md regenerated after cleanup
- Backlog/Saved sections preserved through cleanup

### Phase 4: Documentation and Testing

**Tasks**:
1. Update `/todo` command documentation
2. Update `todo-analyzer` agent documentation
3. Create integration tests:
   - Default mode (update TODO.md)
   - Clean mode (with cleanup)
   - Dry-run mode (preview only)
   - Backlog preservation
   - Saved preservation
   - Research auto-detection
4. Update TODO Organization Standards (if needed)

---

## Technical Considerations

### Agent Execution Context

**Current Agent Model**: Haiku 4.5
- **Justification** (from agent frontmatter): "Status classification is fast, deterministic task requiring <2s response time"
- **Current Task**: Plan status classification only

**New Task Scope**: Complete TODO.md generation
- **Complexity Increase**: Moderate (template-based generation)
- **Expected Execution Time**: ~5-15 seconds (still well within Haiku capabilities)
- **Token Usage**: Moderate increase (reading current TODO.md + generating new)

**Recommendation**: Keep Haiku 4.5 model. TODO.md generation is deterministic template work suitable for fast model.

### State Persistence Requirements

**Current State Variables**:
- `WORKFLOW_ID`
- `DISCOVERED_PROJECTS`
- `CLASSIFIED_RESULTS`
- `SPECS_ROOT`
- `TODO_PATH`

**Additional Variables Needed**:
- `NEW_TODO_PATH` (pre-calculated output path)
- `BACKUP_TODO_PATH` (backup location)
- `CURRENT_TODO_PATH` (input for Backlog/Saved preservation)
- `RESEARCH_DIRS` (optional - auto-detected research directories)

**Persistence Pattern**: Use existing `append_workflow_state()` in Block 2a, restore in Block 2c.

### Error Recovery

**New Error Scenarios**:
1. Agent fails to preserve Backlog section
   - **Detection**: Block 2c compares Backlog content
   - **Recovery**: Log error, exit with restoration hint
2. Agent generates invalid 7-section structure
   - **Detection**: Block 2c validates section headers
   - **Recovery**: Log error, restore from backup
3. Agent creates duplicate entries
   - **Detection**: Block 2c checks for duplicate plan paths
   - **Recovery**: Log error, manual review required

**Error Logging Integration**:
- All verification failures log via `log_command_error()`
- Include recovery instructions in error messages
- Preserve backup for manual rollback

---

## Benefits of Refactor

### Architectural Benefits

1. **Standards Compliance**: Aligns with hard barrier delegation pattern used across all other commands
2. **Separation of Concerns**: Clear boundary between orchestration (command) and work (agent)
3. **Reusability**: Agent logic can be reused by other commands (e.g., auto-update TODO.md after /build)
4. **Testability**: Agent can be tested independently of command orchestration

### Operational Benefits

1. **Maintainability**: TODO.md generation logic in one place (agent), not split across blocks
2. **Debuggability**: Clear checkpoints for delegation and verification
3. **Error Recovery**: Explicit verification catches failures before file write
4. **Performance**: Minimal change (agent already invoked, just doing more work)

### Quality Benefits

1. **Consistency**: Same delegation pattern as /research, /plan, /build, etc.
2. **Observability**: Checkpoint markers and error logging
3. **Reliability**: Fail-fast verification prevents partial updates
4. **Documentation**: Agent behavioral guidelines document generation algorithm

---

## Risks and Mitigations

### Risk 1: Agent Complexity Increase

**Concern**: Expanding agent scope might make it harder to maintain.

**Mitigation**:
- Agent already performs batch classification (complex task)
- TODO.md generation is template-based (deterministic)
- Keep agent focused on single responsibility (TODO.md generation)
- Document algorithm clearly in behavioral guidelines

### Risk 2: Backlog/Saved Preservation Failures

**Concern**: Agent might inadvertently modify manually-curated sections.

**Mitigation**:
- Implement explicit preservation algorithm in agent
- Add verification checks in Block 2c (exact content match)
- Test thoroughly with various Backlog/Saved formats
- Document preservation requirements clearly

### Risk 3: Migration Complexity

**Concern**: Refactoring might introduce regressions.

**Mitigation**:
- Keep current command as backup during development
- Create comprehensive test suite before refactor
- Implement in phases (agent first, then command)
- Test each phase independently before integration

### Risk 4: Research Auto-Detection Edge Cases

**Concern**: Auto-detection logic might misclassify directories.

**Mitigation**:
- Document detection rules clearly (reports/ exists, plans/ empty)
- Add validation checks (directory must have markdown files)
- Test with edge cases (empty reports/, stale directories)
- Allow manual override in Backlog section

---

## Related Documentation Review

### Command Authoring Standards

**Relevant Sections**:
- Task Tool Invocation Patterns (Section 2)
- Subprocess Isolation Requirements (Section 3)
- State Persistence Patterns (Section 4)
- Output Suppression Requirements (Section 7)
- Directory Creation (Section 10)

**Key Takeaways**:
- ✓ Current /todo follows subprocess isolation patterns
- ✓ Current /todo uses state persistence correctly
- ⚠ Current /todo has Task invocation but doesn't fully delegate
- ✓ Current /todo follows output suppression patterns

### Hard Barrier Subagent Delegation Pattern

**Relevant Sections**:
- Pattern Structure (Setup → Execute → Verify)
- Implementation Templates (Research, Plan Revision)
- Pattern Requirements (CRITICAL BARRIER label, fail-fast verification)
- Anti-Patterns (merged blocks, soft verification, skip error logging)

**Key Takeaways**:
- /todo has correct structure but insufficient enforcement
- Verification needs semantic checks (not just file existence)
- Orchestrator performs work that should be delegated

### TODO Organization Standards

**Relevant Sections**:
- Section Hierarchy (7 sections)
- Checkbox Conventions
- Entry Format
- Research Section Auto-Detection
- Saved Section Preservation
- Backlog Preservation Policy

**Key Takeaways**:
- Agent must understand 7-section structure
- Backlog/Saved preservation is critical requirement
- Research auto-detection logic must be precise
- Checkbox conventions must be followed exactly

---

## Open Questions for Planning Phase

1. **Agent Output Format**: Should agent write directly to TODO.md or to temp file? (Recommend: temp file with atomic replace in orchestrator)

2. **Research Detection**: Should research directory detection happen in orchestrator (Block 2a) or agent (Block 2b)? (Recommend: agent - keeps logic consolidated)

3. **Artifact Discovery**: Should report/summary discovery happen in orchestrator or agent? (Recommend: agent - it's part of generation logic)

4. **Backup Strategy**: Should backup happen in Block 2a (before agent) or Block 4 (before replace)? (Recommend: Block 4 - only backup if agent succeeds)

5. **Dry-Run Handling**: Should dry-run preview use agent output or skip agent? (Recommend: invoke agent, preview output, skip write)

6. **Error Recovery**: If agent fails, should orchestrator fall back to current logic or fail-fast? (Recommend: fail-fast - no bypass allowed)

7. **Clean Mode Integration**: Should clean mode use same agent or separate invocation? (Recommend: same agent, separate invocation with reduced plan set)

8. **Migration Path**: Should old command be preserved for comparison/rollback? (Recommend: yes, keep backup until refactor proven stable)

---

## Conclusion

The `/todo` command requires refactoring to comply with hard barrier subagent delegation standards. While the command has the structural elements of proper delegation (Task invocation, verification blocks), the orchestrator currently performs TODO.md generation work that should be delegated to the `todo-analyzer` subagent.

**Recommended Approach**:
1. Expand `todo-analyzer` agent to generate complete TODO.md content (not just classification data)
2. Implement pre-calculation pattern for output paths (like `/research` command)
3. Enhance verification to include semantic checks (7-section structure, Backlog/Saved preservation)
4. Eliminate generation logic from orchestrator (reduce Blocks 3-4 to file operations only)
5. Maintain clean mode and dry-run functionality with new architecture

**Expected Benefits**:
- Standards compliance across all commands
- Clear separation of orchestration (command) and work (agent)
- Improved testability and maintainability
- No performance degradation (agent already invoked)

**Next Steps**:
1. Create detailed implementation plan addressing open questions
2. Develop enhanced `todo-analyzer` agent behavioral guidelines
3. Create test suite for agent in isolation
4. Refactor command with hard barrier enforcement
5. Validate end-to-end with integration tests

---

REPORT_CREATED: /home/benjamin/.config/.claude/specs/004_todo_command_subagent_delegation/reports/001-todo-command-subagent-delegation-analysis.md
