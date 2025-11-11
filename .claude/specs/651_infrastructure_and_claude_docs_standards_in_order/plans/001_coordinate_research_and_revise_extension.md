# /coordinate Research-and-Revise Workflow Extension Implementation Plan

## Metadata
- **Date**: 2025-11-10
- **Feature**: Extend /coordinate command to support research-and-revise workflows
- **Scope**: Add new workflow type detection, create revision-specialist agent, integrate into /coordinate planning phase
- **Estimated Phases**: 6
- **Estimated Hours**: 12
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 42.0
- **Research Reports**:
  - [/coordinate Architecture Analysis](/home/benjamin/.config/.claude/specs/651_infrastructure_and_claude_docs_standards_in_order/reports/001_coordinate_architecture_analysis.md)
  - [/revise Command and Agent Analysis](/home/benjamin/.config/.claude/specs/651_infrastructure_and_claude_docs_standards_in_order/reports/002_revise_command_and_agent_analysis.md)

## Executive Summary

This plan extends the /coordinate command to support research-and-revise workflows by creating a revision-specialist agent that can be invoked when users want to research topics and revise existing plans. The implementation follows the behavioral injection pattern established by research-specialist and plan-architect agents, adds a new workflow scope pattern to workflow-scope-detection.sh, and modifies the planning phase handler in coordinate.md to branch between plan creation (new plans) and plan revision (existing plans).

**Key Design Principles**:
- Extend existing patterns (don't reinvent)
- Leverage workflow-scope-detection.sh for detecting revision workflows
- Use behavioral injection pattern for agent invocation
- Maintain fail-fast verification checkpoints
- Follow state machine architecture

**Success Validation**: research-and-revise workflow successfully detected → revision-specialist agent creates backup and applies research-informed changes → plan file updated with revision history → verification checkpoint confirms success

## Research Summary

**From 001_coordinate_architecture_analysis.md**:
- /coordinate uses state machine with 8 states (initialize → research → plan → implement → test → debug → document → complete)
- Workflow scope detection library supports 4 workflow types via pattern matching (research-only, research-and-plan, full-implementation, debug-only)
- Planning state handler invokes plan-architect agent via Task tool with behavioral injection
- Extension point identified at workflow-scope-detection.sh lines 23-44 (pattern matching section)
- Mandatory verification checkpoints enforce 100% file creation reliability

**From 002_revise_command_and_agent_analysis.md**:
- /revise command currently executes revision logic directly (violates behavioral injection pattern)
- No revision-specialist agent exists yet (opportunity to create one)
- /revise supports dual modes (interactive + auto-mode) with JSON context
- Revision types: expand_phase, add_phase, update_tasks, collapse_phase, custom
- Backup creation mandatory before modifications (timestamped backups in backups/ directory)
- Revision history tracking required (date, type, reason)

**Recommended Approach**:
1. Create revision-specialist agent following research-specialist template (STEP-based execution, 35+ completion criteria)
2. Add research-and-revise workflow pattern to workflow-scope-detection.sh
3. Modify /coordinate planning phase to detect workflow scope and branch to revision-specialist when research-and-revise detected
4. Add plan discovery logic to find most recent plan in topic directory
5. Maintain backward compatibility (existing workflows unchanged)

## Success Criteria

- [ ] New workflow scope "research-and-revise" detected by workflow-scope-detection.sh
- [ ] Revision-specialist agent created at .claude/agents/revision-specialist.md
- [ ] Agent follows STEP-based execution pattern (5 steps minimum)
- [ ] Agent creates backups before modifications (mandatory verification)
- [ ] Agent updates revision history with date/type/reason
- [ ] /coordinate planning phase detects research-and-revise scope and invokes revision-specialist
- [ ] Plan discovery logic finds most recent plan in topic directory
- [ ] Verification checkpoint confirms plan file updated (100% reliability)
- [ ] All tests pass (create test_revision_specialist.sh)
- [ ] Documentation complete (revision-specialist-agent-guide.md)
- [ ] Zero breaking changes to existing workflows (backward compatibility)

## Technical Design

### Architecture Overview

```
User Command: /coordinate "research authentication patterns and revise 042 plan"
     ↓
workflow-scope-detection.sh
     ↓ (detects: research-and-revise)
     ↓
STATE_INITIALIZE
     ↓ (pre-calculates: TOPIC_PATH, REPORT_PATHS, discovers: EXISTING_PLAN_PATH)
     ↓
STATE_RESEARCH
     ↓ (invokes: research-specialist agents × N)
     ↓ (creates: research reports)
     ↓
STATE_PLAN (modified handler)
     ↓
     ├─ if WORKFLOW_SCOPE = "research-and-plan"
     │    ├─ invoke: plan-architect agent
     │    └─ creates: new plan file
     │
     └─ if WORKFLOW_SCOPE = "research-and-revise"
          ├─ invoke: revision-specialist agent
          │    ├─ STEP 1: Receive and validate (plan path, research reports, revision context)
          │    ├─ STEP 2: Create backup FIRST (backups/<plan>_YYYYMMDD_HHMMSS.md)
          │    ├─ STEP 3: Analyze research reports (Read tool)
          │    ├─ STEP 4: Apply revisions (Edit tool with research-informed changes)
          │    └─ STEP 5: Update revision history and verify
          │
          └─ updates: existing plan file
     ↓
STATE_COMPLETE (terminal state for research-and-revise)
```

### Component Interactions

**1. Workflow Scope Detection** (workflow-scope-detection.sh extension):
```bash
# New pattern matching logic (after line 44)
if echo "$workflow_description" | grep -Eiq "(research|analyze).*(and |then |to ).*(revise|update.*plan|modify.*plan)"; then
  scope="research-and-revise"
fi
```

**2. Plan Discovery Logic** (workflow-initialization.sh extension):
```bash
# For research-and-revise, discover most recent plan in topic
if [ "$workflow_scope" = "research-and-revise" ]; then
  EXISTING_PLAN=$(find "$topic_path/plans" -name "*.md" -type f -print0 |
                  xargs -0 ls -t | head -1)

  if [ -z "$EXISTING_PLAN" ]; then
    echo "ERROR: research-and-revise requires existing plan but none found" >&2
    return 1
  fi

  export EXISTING_PLAN_PATH="$EXISTING_PLAN"
  append_workflow_state "EXISTING_PLAN_PATH" "$EXISTING_PLAN"
fi
```

**3. Revision-Specialist Agent** (.claude/agents/revision-specialist.md):
```markdown
STEP 1: Receive and validate revision parameters
  - Plan path (absolute)
  - Research report paths (array)
  - Revision context (optional structured data)
  - Project standards file

STEP 2: Create backup FIRST (mandatory verification checkpoint)
  - Backup directory: <plan-dir>/backups/
  - Filename: <plan-name>_YYYYMMDD_HHMMSS.md
  - Verify backup created before proceeding

STEP 3: Analyze research reports
  - Read all provided research reports
  - Extract key findings and recommendations
  - Identify plan sections needing updates

STEP 4: Apply revisions to plan
  - Use Edit tool (not Write - preserving existing content)
  - Preserve completed phases (marked [COMPLETED])
  - Update technical design based on research
  - Add new phases/tasks if research suggests complexity
  - Maintain /implement compatibility (checkbox format)

STEP 5: Update revision history and verify
  - Add entry to "## Revision History" section
  - Record: date, revision type, research reports used, key changes
  - Verify plan file updated successfully
  - Return: REVISION_COMPLETED: <plan-path>
```

**4. Planning Phase Handler** (coordinate.md modification):
```bash
# Determine planning vs revision based on workflow scope
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  # Branch to revision-specialist agent
  Task {
    subagent_type: "general-purpose"
    description: "Revise existing plan based on research findings"
    timeout: 180000
    prompt: "
      Read and follow ALL behavioral guidelines from:
      /home/benjamin/.config/.claude/agents/revision-specialist.md

      **Workflow-Specific Context**:
      - Existing Plan Path: $EXISTING_PLAN_PATH (absolute)
      - Research Reports: ${REPORT_PATHS[@]}
      - Revision Scope: $WORKFLOW_DESCRIPTION
      - Project Standards: /home/benjamin/.config/CLAUDE.md
      - Backup Required: true

      Execute revision following all guidelines in behavioral file.
      Return: REVISION_COMPLETED: $EXISTING_PLAN_PATH
    "
  }
else
  # Existing branch: invoke plan-architect for new plans
  Task {
    subagent_type: "general-purpose"
    description: "Create implementation plan guided by research reports"
    # ... existing plan-architect invocation ...
  }
fi
```

### State Machine Integration

**Terminal State Mapping** (workflow-state-machine.sh):
```bash
case "$WORKFLOW_SCOPE" in
  research-only)
    TERMINAL_STATE="$STATE_RESEARCH"
    ;;
  research-and-plan)
    TERMINAL_STATE="$STATE_PLAN"
    ;;
  research-and-revise)
    TERMINAL_STATE="$STATE_PLAN"  # Same terminal as research-and-plan
    ;;
  full-implementation)
    TERMINAL_STATE="$STATE_COMPLETE"
    ;;
  debug-only)
    TERMINAL_STATE="$STATE_DEBUG"
    ;;
esac
```

**State Transition**: No new states needed - research-and-revise uses same state sequence as research-and-plan (initialize → research → plan → complete), just different behavior in planning phase.

### Verification and Error Handling

**Mandatory Verification Checkpoints**:

1. **Workflow Scope Detection** (workflow-scope-detection.sh):
   - Verify pattern matching returns valid scope
   - Fallback to "research-and-plan" on ambiguity

2. **Plan Discovery** (workflow-initialization.sh):
   - Verify existing plan found in topic directory
   - Fail-fast error if research-and-revise invoked with no existing plan
   - Log discovered plan path for transparency

3. **Backup Creation** (revision-specialist agent):
   - Verify backup file created before any modifications
   - Fail-fast if backup creation fails (permission issues, disk space)
   - Log backup path for recovery

4. **Plan Revision** (revision-specialist agent):
   - Verify plan file exists after revision
   - Verify revision history section updated
   - Verify no syntax errors introduced (parse plan structure)

5. **Planning Phase Handler** (/coordinate):
   - Verify REVISION_COMPLETED signal received from agent
   - Verify plan file exists and is readable
   - Verify file size increased (content added, not truncated)

**Error Handling Patterns**:

```bash
# Plan discovery error
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ] && [ -z "$EXISTING_PLAN_PATH" ]; then
  handle_state_error "research-and-revise workflow requires existing plan but none found in $TOPIC_PATH/plans" 1
fi

# Backup creation error (in revision-specialist agent)
if [ ! -f "$BACKUP_PATH" ]; then
  echo "CRITICAL ERROR: Backup creation failed"
  echo "  Expected: $BACKUP_PATH"
  exit 1
fi

# Revision verification error (in coordinate.md)
if [ ! -f "$EXISTING_PLAN_PATH" ]; then
  handle_state_error "Revision specialist failed to update plan file" 1
fi
```

### Backward Compatibility

**Existing Workflows Unchanged**:
- research-only: No changes (initialize → research → complete)
- research-and-plan: No changes (initialize → research → plan → complete)
- full-implementation: No changes (initialize → research → plan → implement → test → [debug] → document → complete)
- debug-only: No changes (initialize → research → debug → complete)

**Pattern Matching Priority**: New research-and-revise pattern checked AFTER existing patterns to avoid false matches (specific patterns before general patterns).

**State Machine Compatibility**: No new states added, only new terminal state mapping for research-and-revise (maps to existing STATE_PLAN).

## Implementation Phases

### Phase 1: Workflow Scope Detection Extension
dependencies: []

**Objective**: Add research-and-revise pattern to workflow-scope-detection.sh enabling /coordinate to detect revision workflows

**Complexity**: Low

**Tasks**:
- [x] Read current workflow-scope-detection.sh implementation (file: /home/benjamin/.config/.claude/lib/workflow-scope-detection.sh)
- [x] Add research-and-revise pattern matching logic after line 44
- [x] Pattern: `(research|analyze).*(and |then |to ).*(revise|update.*plan|modify.*plan)`
- [x] Set scope="research-and-revise" when pattern matches
- [x] Update pattern matching order (specific before general to avoid false matches)
- [x] Add inline comments explaining research-and-revise pattern
- [x] Export function for use in coordinate.md

**Testing**:
```bash
# Test workflow scope detection
source .claude/lib/workflow-scope-detection.sh

# Test cases
SCOPE1=$(detect_workflow_scope "research authentication patterns and revise existing plan")
[ "$SCOPE1" = "research-and-revise" ] && echo "✓ Test 1 passed" || echo "✗ Test 1 failed"

SCOPE2=$(detect_workflow_scope "research auth patterns to update 042 plan")
[ "$SCOPE2" = "research-and-revise" ] && echo "✓ Test 2 passed" || echo "✗ Test 2 failed"

SCOPE3=$(detect_workflow_scope "research auth and create plan")
[ "$SCOPE3" = "research-and-plan" ] && echo "✓ Test 3 passed (no false positive)" || echo "✗ Test 3 failed"
```

**Expected Duration**: 1 hour

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(651): complete Phase 1 - Workflow Scope Detection Extension`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

[COMPLETED]

### Phase 2: Plan Discovery Logic Implementation
dependencies: [1]

**Objective**: Add plan discovery logic to workflow-initialization.sh for finding most recent plan in topic directory when research-and-revise workflow detected

**Complexity**: Low

**Tasks**:
- [x] Read current workflow-initialization.sh implementation (file: /home/benjamin/.config/.claude/lib/workflow-initialization.sh)
- [x] Add plan discovery logic after line 256 (after plan_path calculation section)
- [x] Implement find command to locate most recent .md file in $topic_path/plans/
- [x] Add error handling if no existing plan found (fail-fast with clear message)
- [x] Export EXISTING_PLAN_PATH for use in coordinate.md planning phase
- [x] Add EXISTING_PLAN_PATH to workflow state persistence (append_workflow_state call)
- [x] Add inline comments explaining discovery logic and rationale

**Testing**:
```bash
# Create test topic directory with mock plan
mkdir -p /tmp/test_topic/plans
echo "# Test Plan" > /tmp/test_topic/plans/001_test.md
sleep 1
echo "# Test Plan 2" > /tmp/test_topic/plans/002_test.md

# Test discovery logic
source .claude/lib/workflow-initialization.sh
TOPIC_PATH="/tmp/test_topic"
WORKFLOW_SCOPE="research-and-revise"

# Should find most recent plan (002_test.md)
# Call discovery logic and verify EXISTING_PLAN_PATH set correctly

# Cleanup
rm -rf /tmp/test_topic
```

**Expected Duration**: 1.5 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 2 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(651): complete Phase 2 - Plan Discovery Logic Implementation`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

[COMPLETED]

### Phase 3: Revision-Specialist Agent Creation
dependencies: []

**Objective**: Create revision-specialist agent behavioral file following research-specialist pattern with STEP-based execution, backup creation, and revision history tracking

**Complexity**: High

**Tasks**:
- [x] Create new agent file: .claude/agents/revision-specialist.md
- [x] Add frontmatter metadata (allowed-tools: Read, Write, Edit, Bash, Task)
- [x] Add agent description and role clarity section
- [x] Implement STEP 1: Receive and validate revision parameters (plan path, research reports, revision context)
- [x] Implement STEP 1.5: Verify parent directory exists (use ensure_artifact_directory)
- [x] Implement STEP 2: Create backup FIRST (mandatory verification checkpoint)
- [x] Add backup path calculation logic (backups/<plan-name>_YYYYMMDD_HHMMSS.md)
- [x] Add backup verification using Bash tool (test -f check)
- [x] Implement STEP 3: Analyze research reports (Read tool to extract findings)
- [x] Implement STEP 4: Apply revisions to plan (Edit tool, preserve completed phases)
- [x] Add logic to identify sections needing updates (Technical Design, phases, tasks)
- [x] Add revision type handling (research-informed, complexity-driven, scope-expansion)
- [x] Implement STEP 5: Update revision history section
- [x] Add revision history entry template (date, type, research reports, key changes)
- [x] Add final verification checkpoint (plan file exists, size increased, parseable)
- [x] Add completion criteria section (35+ criteria following research-specialist pattern)
- [x] Add return format specification (REVISION_COMPLETED: <absolute-path>)

**Testing**:
```bash
# Test revision-specialist agent via Task tool
# Create test plan and research report
mkdir -p /tmp/test_revision/plans /tmp/test_revision/reports
cat > /tmp/test_revision/plans/001_test.md <<'EOF'
# Test Plan
## Metadata
- Date: 2025-11-10
## Technical Design
Old design here.
## Revision History
None yet.
EOF

cat > /tmp/test_revision/reports/001_research.md <<'EOF'
# Research Report
## Recommendations
Use new pattern XYZ.
EOF

# Invoke revision-specialist agent and verify:
# - Backup created in /tmp/test_revision/plans/backups/
# - Plan updated with new technical design
# - Revision history section updated
```

**Expected Duration**: 4 hours

<!-- PROGRESS CHECKPOINT -->
After completing the first 5 tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

<!-- PROGRESS CHECKPOINT -->
After completing tasks 6-10:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

<!-- PROGRESS CHECKPOINT -->
After completing tasks 11-15:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 3 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(651): complete Phase 3 - Revision-Specialist Agent Creation`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

[COMPLETED]

### Phase 4: /coordinate Planning Phase Handler Modification
dependencies: [1, 2, 3]

**Objective**: Modify /coordinate planning phase to detect workflow scope and branch between plan-architect (new plans) and revision-specialist (existing plans)

**Complexity**: Medium

**Tasks**:
- [x] Read current /coordinate planning phase handler (file: /home/benjamin/.config/.claude/commands/coordinate.md, lines 687-760)
- [x] Add workflow scope detection conditional (if WORKFLOW_SCOPE = research-and-revise)
- [x] Implement revision-specialist invocation branch using Task tool
- [x] Add behavioral file reference: /home/benjamin/.config/.claude/agents/revision-specialist.md
- [x] Pass workflow-specific context (EXISTING_PLAN_PATH, REPORT_PATHS, WORKFLOW_DESCRIPTION, CLAUDE.md)
- [x] Add completion signal detection (REVISION_COMPLETED: <path>)
- [x] Add mandatory verification checkpoint (verify plan file exists and updated)
- [x] Preserve existing plan-architect branch for research-and-plan workflows
- [x] Add inline comments explaining branching logic
- [x] Update transition logic to handle both branches (transition to STATE_COMPLETE in both cases)

**Testing**:
```bash
# Integration test with full /coordinate workflow
/coordinate "research async patterns and revise 015 plan"

# Expected flow:
# 1. Scope detected: research-and-revise
# 2. STATE_INITIALIZE: Plan discovery finds specs/015_async/plans/001_*.md
# 3. STATE_RESEARCH: Research reports created
# 4. STATE_PLAN: Revision-specialist invoked (not plan-architect)
# 5. Backup created, plan updated, revision history added
# 6. STATE_COMPLETE: Workflow terminates
```

**Expected Duration**: 2 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 4 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(651): complete Phase 4 - /coordinate Planning Phase Handler Modification`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

[COMPLETED]

### Phase 5: State Machine Integration and Testing
dependencies: [4]

**Objective**: Integrate research-and-revise workflow into state machine terminal state mapping and create comprehensive test suite

**Complexity**: Medium

**Tasks**:
- [x] Read current workflow-state-machine.sh implementation (file: /home/benjamin/.config/.claude/lib/workflow-state-machine.sh, lines 104-121)
- [x] Add research-and-revise case to terminal state mapping
- [x] Set TERMINAL_STATE="$STATE_PLAN" for research-and-revise (same as research-and-plan)
- [x] Verify no new states needed (research-and-revise uses existing state sequence)
- [x] Create test file: .claude/tests/test_revision_specialist.sh
- [x] Add test cases for workflow scope detection (research-and-revise pattern matching)
- [x] Add test cases for plan discovery logic (find most recent plan)
- [x] Add test cases for backup creation (timestamped backups in backups/ directory)
- [x] Add test cases for revision history updates (date, type, reason present)
- [x] Add test cases for completion signal format (REVISION_COMPLETED: <path>)
- [x] Add integration test for full /coordinate research-and-revise workflow
- [x] Add negative test cases (no existing plan, backup creation failure, invalid research reports)
- [x] Run complete test suite and verify 100% pass rate

**Testing**:
```bash
# Run revision specialist test suite
.claude/tests/test_revision_specialist.sh

# Expected output:
# ✓ Test 1: Workflow scope detection (research-and-revise pattern)
# ✓ Test 2: Plan discovery (finds most recent plan)
# ✓ Test 3: Backup creation (timestamped backup in backups/)
# ✓ Test 4: Revision history update (date/type/reason present)
# ✓ Test 5: Completion signal (REVISION_COMPLETED format)
# ✓ Test 6: Integration test (full /coordinate workflow)
# ✓ Test 7: Negative test (no existing plan found)
# All tests passed: 7/7
```

**Expected Duration**: 2 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 5 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(651): complete Phase 5 - State Machine Integration and Testing`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

[COMPLETED]

### Phase 6: Documentation and Validation
dependencies: [5]

**Objective**: Create comprehensive documentation for revision-specialist agent and validate complete implementation against success criteria

**Complexity**: Low

**Tasks**:
- [ ] Create revision-specialist agent guide: .claude/docs/guides/revision-specialist-agent-guide.md
- [ ] Add agent overview and capabilities section
- [ ] Add revision workflow section (research → revise → verify)
- [ ] Add revision types reference (research-informed, complexity-driven, scope-expansion)
- [ ] Add backup and recovery procedures section
- [ ] Add integration examples (/coordinate, /implement, manual invocation)
- [ ] Add troubleshooting section (common failures and solutions)
- [ ] Update /coordinate command guide with research-and-revise workflow documentation (file: .claude/docs/guides/coordinate-command-guide.md)
- [ ] Update CLAUDE.md project commands section with research-and-revise workflow reference
- [ ] Validate all success criteria met (11 criteria from Success Criteria section)
- [ ] Run complete test suite one final time (.claude/tests/run_all_tests.sh)
- [ ] Create implementation summary documenting changes and metrics

**Testing**:
```bash
# Validate documentation exists and is complete
test -f .claude/docs/guides/revision-specialist-agent-guide.md || echo "✗ Guide missing"
grep -q "revision types reference" .claude/docs/guides/revision-specialist-agent-guide.md || echo "✗ Section missing"

# Validate CLAUDE.md updated
grep -q "research-and-revise" CLAUDE.md || echo "✗ CLAUDE.md not updated"

# Run complete test suite
.claude/tests/run_all_tests.sh

# Expected: All tests pass (including new revision-specialist tests)
```

**Expected Duration**: 1.5 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(651): complete Phase 6 - Documentation and Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Tests

**Workflow Scope Detection** (.claude/tests/test_workflow_scope_detection.sh):
- Test research-and-revise pattern matching (various keyword combinations)
- Test pattern priority (specific before general)
- Test fallback to research-and-plan on ambiguity
- Test backward compatibility (existing patterns still work)

**Plan Discovery Logic** (.claude/tests/test_plan_discovery.sh):
- Test finding most recent plan in topic directory
- Test error handling when no plans exist
- Test handling multiple plans (selects newest by mtime)
- Test absolute path returned (not relative)

**Revision-Specialist Agent** (.claude/tests/test_revision_specialist.sh):
- Test backup creation (timestamped, correct directory)
- Test revision history updates (date, type, reason)
- Test research report analysis (findings extracted)
- Test plan modifications (Edit tool, preserve completed phases)
- Test completion signal format (REVISION_COMPLETED: <path>)
- Test error handling (backup failure, invalid plan path)

### Integration Tests

**Full /coordinate Workflow** (.claude/tests/test_coordinate_research_and_revise.sh):
- Test end-to-end research-and-revise workflow
- Test state transitions (initialize → research → plan → complete)
- Test agent invocations (research-specialist × N, revision-specialist × 1)
- Test artifact creation (research reports, backup, updated plan)
- Test verification checkpoints (100% file creation reliability)

### Regression Tests

**Backward Compatibility** (.claude/tests/test_coordinate_backward_compat.sh):
- Test research-only workflow still works (no changes)
- Test research-and-plan workflow still works (no changes)
- Test full-implementation workflow still works (no changes)
- Test debug-only workflow still works (no changes)

### Performance Tests

**Workflow Execution Time** (baseline measurements):
- Research-and-revise workflow < research-and-plan workflow (revision faster than creation)
- Plan discovery overhead < 100ms (find command efficient)
- Backup creation overhead < 50ms (cp command efficient)

### Coverage Requirements

**Target Coverage**: ≥80% for new code, ≥60% baseline
- workflow-scope-detection.sh: 100% (all branches tested)
- plan discovery logic: 100% (all error paths tested)
- revision-specialist agent: ≥80% (STEP 1-5 execution paths)
- /coordinate planning phase handler: ≥80% (both branches tested)

## Documentation Requirements

### Agent Documentation

**Revision-Specialist Agent Guide** (.claude/docs/guides/revision-specialist-agent-guide.md):
- Agent overview and capabilities
- STEP-based execution process (STEP 1-5 detailed)
- Revision types reference (research-informed, complexity-driven, scope-expansion)
- Backup and recovery procedures (where backups stored, how to restore)
- Integration examples (/coordinate, /implement, manual Task invocation)
- Troubleshooting guide (common failures: backup creation, invalid plan, missing research reports)
- Completion criteria reference (35+ criteria with explanations)

### Command Documentation

**Update /coordinate Command Guide** (.claude/docs/guides/coordinate-command-guide.md):
- Add "Research-and-Revise Workflow" section
- Document workflow scope detection pattern
- Document plan discovery logic (how most recent plan selected)
- Document revision-specialist invocation (inputs, outputs, verification)
- Add usage example: `/coordinate "research auth patterns and revise 042 plan"`
- Add troubleshooting section (no existing plan found, revision failure)

### Project Standards

**Update CLAUDE.md** (section: project_commands):
- Add research-and-revise to workflow types list (5 total workflows now)
- Document revision-specialist agent in orchestration section
- Add reference to revision-specialist-agent-guide.md

### Testing Documentation

**Test Suite Documentation** (.claude/tests/README.md update):
- Document test_revision_specialist.sh (purpose, test cases, expected output)
- Document test_coordinate_research_and_revise.sh (integration test)
- Add troubleshooting section for test failures

## Dependencies

### External Dependencies

**None** - This implementation uses only existing libraries and tools:
- workflow-scope-detection.sh (extending existing patterns)
- workflow-initialization.sh (extending existing logic)
- workflow-state-machine.sh (extending terminal state mapping)
- Task tool (existing agent invocation mechanism)
- Read/Write/Edit/Bash tools (existing agent toolset)

### Internal Dependencies

**Phase Dependencies** (for parallel execution):
- Phase 1: No dependencies (can start immediately)
- Phase 2: Depends on Phase 1 (needs workflow scope detection)
- Phase 3: No dependencies (can run parallel with Phase 1-2)
- Phase 4: Depends on Phases 1, 2, 3 (needs all components complete)
- Phase 5: Depends on Phase 4 (needs integration complete for testing)
- Phase 6: Depends on Phase 5 (needs tests passing for validation)

**Parallel Execution Opportunities**:
- Wave 1: Phase 1 + Phase 3 (independent work)
- Wave 2: Phase 2 (depends on Phase 1)
- Wave 3: Phase 4 (depends on Phases 1, 2, 3)
- Wave 4: Phase 5 (depends on Phase 4)
- Wave 5: Phase 6 (depends on Phase 5)

**Estimated Time Savings**: ~20% (Phase 3 runs parallel with Phase 1-2, saving 2 hours)

### Prerequisite Knowledge

**Required Understanding**:
- State machine architecture (STATE_INITIALIZE, STATE_RESEARCH, STATE_PLAN, etc.)
- Behavioral injection pattern (Task tool invocation with behavioral file reference)
- Verification checkpoint pattern (mandatory file creation verification)
- Bash subprocess isolation (functions lost across bash blocks, need re-sourcing)
- STEP-based agent execution (STEP 1 → STEP 2 → ... → return signal)

**Reference Documentation**:
- /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md
- /home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md
- /home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md
- /home/benjamin/.config/.claude/agents/research-specialist.md (template reference)

## Revision History

Initial plan created: 2025-11-10
