# Replace PROGRESS CHECKPOINTs with Automated Plan Updates Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: Replace PROGRESS CHECKPOINTs with implementer subagent plan updates and git commits
- **Scope**: Create implementation-executor agent, remove PROGRESS CHECKPOINT insertion code, add summary generation on completion/context exhaustion
- **Estimated Phases**: 5
- **Estimated Hours**: 12
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Progress Checkpoint Research](/home/benjamin/.config/.claude/specs/772_replace_progress_checkpoints_with_implementer_suba/reports/001_progress_checkpoint_research.md)
- **Structure Level**: 0
- **Complexity Score**: 61.5

## Overview

This implementation replaces manual PROGRESS CHECKPOINT reminders with automated plan updates and git commits by the implementer subagent. The key architectural change is creating the missing `implementation-executor.md` agent that implementer-coordinator already references but doesn't exist. This agent will automatically update plan files, propagate changes via spec-updater, create git commits, and generate summaries on completion or context exhaustion.

## Research Summary

Key findings from the progress checkpoint research:

- **PROGRESS CHECKPOINTs** are currently inserted by plan-architect.md (lines 115-172, STEP 2.5) and plan-structure-manager.md (lines 151-238, 433-456) as HTML comments reminding implementers to manually update plan files
- **implementation-executor.md agent does not exist** but is referenced by implementer-coordinator at lines 145, 168 - this is the missing piece that should perform automatic updates
- **spec-updater agent** provides `mark_phase_complete` and `propagate_checkbox_update` functions for hierarchy synchronization (lines 377-410)
- **Git commit pattern** follows format: `feat(NNN): complete Phase N - [Phase Name]`
- **Summary template** is documented in workflow-phases.md (lines 729-849) but no summaries currently exist
- **Context exhaustion detection** should trigger at 70% threshold with summary checkpoint creation

Recommended approach: Create implementation-executor as the execution engine invoked per phase by implementer-coordinator, responsible for task execution, plan updates, git commits, and summary generation.

## Success Criteria

- [ ] implementation-executor.md agent created with complete execution and update logic
- [ ] PROGRESS CHECKPOINT insertion code removed from plan-architect.md (STEP 2.5)
- [ ] PROGRESS CHECKPOINT insertion code removed from plan-structure-manager.md (STEP 3.5, templates)
- [ ] implementer-coordinator.md updated to properly invoke and receive results from implementation-executor
- [ ] Automatic plan file updates working (tasks marked with [x])
- [ ] Automatic git commits created after each phase completion
- [ ] Summary generated on successful completion of all phases
- [ ] Summary generated on context exhaustion (70% threshold)
- [ ] build.md updated to expect and display summary path
- [ ] All tests passing for new functionality
- [ ] Existing workflows continue to function correctly

## Technical Design

### Architecture Overview

```
/build workflow
    |
    v
implementer-coordinator.md
    |
    |-- (per phase, parallel per wave)
    v
implementation-executor.md (NEW)
    |-- Execute phase tasks
    |-- Update plan file (mark tasks [x])
    |-- Invoke spec-updater for hierarchy propagation
    |-- Run phase tests
    |-- Create git commit
    |-- Return structured completion report
    |
    v
(if all phases complete OR context exhaustion)
    |
    v
Generate summary to summaries/ directory
```

### Component Interactions

1. **build.md** invokes **implementer-coordinator** with plan path and artifact paths
2. **implementer-coordinator** analyzes dependencies, builds wave structure, invokes **implementation-executor** per phase
3. **implementation-executor** executes tasks, updates plan, commits, returns structured report
4. **implementer-coordinator** aggregates results, generates summary on completion
5. **build.md** receives summary path and displays to user

### Return Signal Changes

Current: `IMPLEMENTATION_COMPLETE: {PHASE_COUNT}`

New structured return:
```yaml
IMPLEMENTATION_COMPLETE:
  phase_count: N
  summary_path: /path/to/summaries/NNN_workflow_summary.md
  git_commits: [hash1, hash2, ...]
  context_exhausted: true|false
```

## Implementation Phases

### Phase 1: Create Implementation Executor Agent
dependencies: []

**Objective**: Create the missing implementation-executor.md agent that implementer-coordinator references

**Complexity**: High

Tasks:
- [ ] Create `/home/benjamin/.config/.claude/agents/implementation-executor.md` with proper YAML frontmatter
- [ ] Define agent role as single-phase executor with automatic plan updates
- [ ] Implement task execution workflow with progress tracking
- [ ] Add plan file update logic using Edit tool to mark tasks with [x]
- [ ] Add spec-updater invocation for hierarchy propagation
- [ ] Add test execution for phase-specific tests
- [ ] Add git commit creation with standardized message format
- [ ] Define structured return format with completion details
- [ ] Add context exhaustion detection at 70% threshold
- [ ] Add summary generation trigger logic
- [ ] Document behavioral guidelines and examples

Testing:
```bash
# Verify agent file exists and has valid structure
test -f /home/benjamin/.config/.claude/agents/implementation-executor.md
grep -q "allowed-tools:" /home/benjamin/.config/.claude/agents/implementation-executor.md
grep -q "description:" /home/benjamin/.config/.claude/agents/implementation-executor.md
```

**Expected Duration**: 4 hours

### Phase 2: Remove PROGRESS CHECKPOINT Insertion Code
dependencies: []

**Objective**: Remove PROGRESS CHECKPOINT insertion logic from plan-architect and plan-structure-manager

**Complexity**: Medium

Tasks:
- [ ] Edit `/home/benjamin/.config/.claude/agents/plan-architect.md` to remove STEP 2.5 (lines 115-172)
- [ ] Remove task-level checkpoint template from plan-architect.md (lines 152-159)
- [ ] Remove phase completion checklist template from plan-architect.md (lines 162-169)
- [ ] Remove checkpoint injection algorithm from plan-architect.md (lines 143-150)
- [ ] Update verification checklist in plan-architect.md to remove checkpoint references
- [ ] Edit `/home/benjamin/.config/.claude/agents/plan-structure-manager.md` to remove STEP 3.5 (lines 151-238)
- [ ] Remove task-level reminder template from plan-structure-manager.md (lines 162-169)
- [ ] Remove phase completion checklist template from plan-structure-manager.md (lines 171-194)
- [ ] Remove stage completion checklist templates from plan-structure-manager.md (lines 433-456)
- [ ] Remove reminder injection commands from plan-structure-manager.md (lines 201-238)
- [ ] Update quality checklist in plan-structure-manager.md to remove checkpoint references
- [ ] Renumber subsequent steps after removal (STEP 3 becomes STEP 2.5, etc.)

Testing:
```bash
# Verify PROGRESS CHECKPOINT code is removed
! grep -q "PROGRESS CHECKPOINT" /home/benjamin/.config/.claude/agents/plan-architect.md
! grep -q "PROGRESS CHECKPOINT" /home/benjamin/.config/.claude/agents/plan-structure-manager.md
! grep -q "STEP 2.5.*Progress" /home/benjamin/.config/.claude/agents/plan-architect.md
! grep -q "STEP 3.5.*Progress" /home/benjamin/.config/.claude/agents/plan-structure-manager.md
```

**Expected Duration**: 2 hours

### Phase 3: Add Summary Generation Logic
dependencies: [1]

**Objective**: Implement summary generation on workflow completion and context exhaustion

**Complexity**: Medium

Tasks:
- [ ] Add summary generation function to implementation-executor.md
- [ ] Use workflow-phases.md summary template (lines 729-849) as basis
- [ ] Implement summary path calculation: `{topic_path}/summaries/NNN_workflow_summary.md`
- [ ] Add summary metadata population (date, topic, duration, phases)
- [ ] Add phase completion details to summary
- [ ] Add git commits list to summary
- [ ] Add files modified tracking to summary
- [ ] Add context exhaustion detection and trigger at 70% threshold
- [ ] Create context checkpoint summary variant for continuation
- [ ] Add summary path to structured return from implementation-executor

Testing:
```bash
# Verify summary template sections exist in implementation-executor
grep -q "workflow_summary" /home/benjamin/.config/.claude/agents/implementation-executor.md
grep -q "context_exhausted" /home/benjamin/.config/.claude/agents/implementation-executor.md
grep -q "summaries/" /home/benjamin/.config/.claude/agents/implementation-executor.md
```

**Expected Duration**: 2 hours

### Phase 4: Update Implementer Coordinator and Build Command
dependencies: [1, 3]

**Objective**: Update implementer-coordinator to properly invoke executor and build command to handle summaries

**Complexity**: Medium

Tasks:
- [ ] Update `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` executor invocation to match new interface
- [ ] Update expected return format in implementer-coordinator to include structured results
- [ ] Add summary path aggregation logic to implementer-coordinator
- [ ] Update result aggregation to track git commits across all phases
- [ ] Update final return format to include summary_path field
- [ ] Edit `/home/benjamin/.config/.claude/commands/build.md` Part 4 to parse structured return
- [ ] Update build.md verification to check for summary path
- [ ] Add summary display to user in build.md completion output
- [ ] Update build.md to handle context exhaustion scenario
- [ ] Update return signal documentation in both files

Testing:
```bash
# Verify updated return formats
grep -q "summary_path" /home/benjamin/.config/.claude/agents/implementer-coordinator.md
grep -q "summary_path" /home/benjamin/.config/.claude/commands/build.md
grep -q "IMPLEMENTATION_COMPLETE:" /home/benjamin/.config/.claude/agents/implementer-coordinator.md
```

**Expected Duration**: 2 hours

### Phase 5: Testing and Documentation
dependencies: [1, 2, 3, 4]

**Objective**: Verify all components work together and update documentation

**Complexity**: Low

Tasks:
- [ ] Create unit test for implementation-executor plan update logic
- [ ] Create integration test for full workflow with summary generation
- [ ] Test context exhaustion detection and summary creation
- [ ] Test git commit creation with proper message format
- [ ] Test spec-updater hierarchy propagation
- [ ] Verify existing plans without PROGRESS CHECKPOINTs work correctly
- [ ] Update CLAUDE.md if needed with new workflow documentation
- [ ] Update relevant .claude/docs files with new architecture
- [ ] Create example of new workflow in action

Testing:
```bash
# Run test suite
cd /home/benjamin/.config && bash .claude/run_all_tests.sh
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Tests

1. **implementation-executor plan update test**: Verify Edit tool correctly marks tasks with [x]
2. **summary generation test**: Verify summary file created with correct template
3. **context exhaustion test**: Verify 70% threshold triggers summary creation

### Integration Tests

1. **Full workflow test**: Execute /build with test plan, verify:
   - All tasks marked complete in plan file
   - Git commits created with correct messages
   - Summary generated in summaries/ directory
   - Structured return includes all expected fields

2. **Parallel execution test**: Verify wave-based execution with multiple parallel phases

### Regression Tests

1. Verify existing plans without PROGRESS CHECKPOINTs continue to work
2. Verify implementer-coordinator wave-based orchestration unchanged
3. Verify spec-updater hierarchy updates still function

## Documentation Requirements

### Files to Update

1. **CLAUDE.md**: No changes required (references /build workflow which is being enhanced)
2. **implementer-coordinator.md**: Update behavioral guidelines with new executor interface
3. **build.md**: Update Part 4 documentation with new return format
4. **workflow-phases.md**: Add reference to automatic summary generation

### New Documentation

1. **implementation-executor.md**: Comprehensive agent documentation (created in Phase 1)

## Dependencies

### External Dependencies

- spec-updater.md agent (existing, provides checkbox-utils)
- workflow-state-machine.sh library (existing, for state transitions)
- state-persistence.sh library (existing, for workflow state)

### Prerequisites

- All existing agents must continue functioning
- Git repository must be initialized
- specs/ directory structure must exist

### Integration Points

1. **implementer-coordinator.md** invokes implementation-executor per phase
2. **spec-updater.md** handles hierarchy propagation
3. **build.md** receives and displays summary results
4. **workflow-phases.md** provides summary template

## Risks and Mitigations

### Risk 1: Breaking existing workflows
**Mitigation**: Phase 2 removes CHECKPOINTs but doesn't change plan structure; Phase 4 updates are additive; comprehensive testing in Phase 5

### Risk 2: Summary generation path conflicts
**Mitigation**: Use consistent numbering pattern matching plan number; verify path doesn't exist before creation

### Risk 3: Context exhaustion false positives
**Mitigation**: Use conservative 70% threshold; log context usage for monitoring; allow user override

### Risk 4: Git commit failures
**Mitigation**: implementation-executor handles commit failures gracefully; reports error without blocking workflow

## Notes

- Phase dependencies enable parallel execution: Phases 1 and 2 can run in parallel (Wave 1)
- Phases 3 and 4 depend on Phase 1 (Wave 2)
- Phase 5 depends on all prior phases (Wave 3)
- Estimated time savings from parallelization: ~25% (12 hours sequential vs ~9 hours parallel)
