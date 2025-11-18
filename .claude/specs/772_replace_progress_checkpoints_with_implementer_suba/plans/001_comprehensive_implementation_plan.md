# Replace PROGRESS CHECKPOINTs with Automated Plan Updates Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: Replace PROGRESS CHECKPOINTs with implementer subagent plan updates, git commits, and summary-based continuation
- **Scope**: Create implementation-executor agent, remove PROGRESS CHECKPOINT insertion code, add summary generation with work remaining status, implement continuation invocation for persistence through context exhaustion
- **Estimated Phases**: 6
- **Estimated Hours**: 14
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Progress Checkpoint Research](/home/benjamin/.config/.claude/specs/772_replace_progress_checkpoints_with_implementer_suba/reports/001_progress_checkpoint_research.md)
  - [Continuation Patterns Research](/home/benjamin/.config/.claude/specs/772_replace_progress_checkpoints_with_implementer_suba/reports/002_continuation_patterns_research.md)
- **Structure Level**: 0
- **Complexity Score**: 78.5

## Overview

This implementation replaces manual PROGRESS CHECKPOINT reminders with automated plan updates and git commits by the implementer subagent, with persistence through summary-based continuation. The key architectural changes are:

1. Creating the missing `implementation-executor.md` agent that implementer-coordinator already references
2. Implementing summary generation with **Work Status and Work Remaining sections at the top** for immediate visibility
3. Adding a **continuation invocation loop** in build.md that passes previous summaries to new executor instances
4. Enabling **persistence through context exhaustion** by detecting at 70% threshold and generating handoff summaries

When an implementation-executor exits without completing the plan (due to context exhaustion or other reasons), another instance is invoked with the previous summary as context to continue the implementation. This ensures work is never lost and provides clear documentation of progress and remaining tasks.

## Research Summary

### From Progress Checkpoint Research (Report 001)

- **PROGRESS CHECKPOINTs** are currently inserted by plan-architect.md (lines 115-172, STEP 2.5) and plan-structure-manager.md (lines 151-238, 433-456) as HTML comments reminding implementers to manually update plan files
- **implementation-executor.md agent does not exist** but is referenced by implementer-coordinator at lines 145, 168 - this is the missing piece that should perform automatic updates
- **spec-updater agent** provides `mark_phase_complete` and `propagate_checkbox_update` functions for hierarchy synchronization (lines 377-410)
- **Git commit pattern** follows format: `feat(NNN): complete Phase N - [Phase Name]`
- **Summary template** is documented in workflow-phases.md (lines 729-849) but no summaries currently exist

### From Continuation Patterns Research (Report 002)

- **Summary format with Work Remaining section**: Work Status at the VERY TOP with completion percentage, continuation required flag, and specific incomplete tasks prominently displayed for immediate visibility
- **Continuation invocation pattern**: Build.md implements continuation loop (MAX_ITERATIONS=5), parses executor return for work_remaining and summary_path, re-invokes executor with continuation_context parameter
- **Context exhaustion detection**: 70% threshold (consistent with existing implementer-coordinator pattern at line 467), trigger summary generation BEFORE exhaustion, return structured signal with context_exhausted: true
- **Detection points**: After each phase completion, after large file operations, after test output capture

Recommended approach: Create implementation-executor as the execution engine with automatic plan updates, git commits, context exhaustion detection at 70% threshold, and summary generation with Work Remaining at top. Build.md implements continuation loop for persistence through multiple executor instances.

## Success Criteria

- [ ] implementation-executor.md agent created with complete execution, update, and continuation logic
- [ ] PROGRESS CHECKPOINT insertion code removed from plan-architect.md (STEP 2.5)
- [ ] PROGRESS CHECKPOINT insertion code removed from plan-structure-manager.md (STEP 3.5, templates)
- [ ] implementer-coordinator.md updated to handle context_exhausted signal and structured returns
- [ ] Automatic plan file updates working (tasks marked with [x])
- [ ] Automatic git commits created after each phase completion
- [ ] Summary generated with Work Status and Work Remaining sections at TOP of file
- [ ] Summary states "100% complete" OR lists specific remaining tasks
- [ ] Context exhaustion detected at 70% threshold and triggers summary generation
- [ ] build.md implements continuation loop with MAX_ITERATIONS=5
- [ ] Previous summary passed as continuation_context to new executor instances
- [ ] Executor reads previous summary to determine exact resume point
- [ ] Structured return format includes work_remaining field
- [ ] All tests passing for new functionality
- [ ] Existing workflows continue to function correctly

## Technical Design

### Architecture Overview

```
/build workflow
    |
    v
build.md (with continuation loop)
    |
    |-- Iteration 1 (fresh start)
    |-- Iteration 2..N (with continuation_context if previous incomplete)
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
    |-- Monitor context usage (70% threshold)
    |-- Return structured completion report
    |
    v
(if all phases complete OR context exhaustion)
    |
    v
Generate summary with Work Status at TOP
    |
    v
(if work_remaining > 0)
    |
    v
build.md re-invokes with previous summary as context
```

### Component Interactions

1. **build.md** enters continuation loop (MAX_ITERATIONS=5), invokes **implementer-coordinator** with plan path, artifact paths, and optional continuation_context
2. **implementer-coordinator** analyzes dependencies, builds wave structure, invokes **implementation-executor** per phase (parallel per wave)
3. **implementation-executor** executes tasks, updates plan, commits, monitors context usage, returns structured report
4. **implementer-coordinator** aggregates results, handles context_exhausted signals, generates summary with Work Status at top
5. **build.md** parses return for work_remaining - if > 0, re-invokes with previous summary as continuation_context
6. Loop continues until work_remaining=0 OR MAX_ITERATIONS reached (error on timeout)

### Return Signal Changes

Current: `IMPLEMENTATION_COMPLETE: {PHASE_COUNT}`

New structured return:
```yaml
IMPLEMENTATION_COMPLETE:
  phase_count: N
  summary_path: /path/to/summaries/NNN_workflow_summary.md
  git_commits: [hash1, hash2, ...]
  context_exhausted: true|false
  work_remaining: 0|[list of incomplete phases]
```

### Summary Format with Work Remaining

Summaries must follow this structure with Work Status at the TOP:

```markdown
# Implementation Summary: [Feature Name]

## Work Status
**Completion**: [XX]% complete
**Continuation Required**: [Yes/No]

### Work Remaining
[ONLY if incomplete - placed prominently for immediate visibility]
- [ ] Phase N: [Phase Name] - [specific remaining tasks]
- [ ] Phase M: [Phase Name] - [specific remaining tasks]

### Continuation Instructions
[ONLY if incomplete]
To continue implementation:
1. Re-invoke implementation-executor with this summary as context
2. Start from Phase N, task [specific task number]
3. All previous work is committed and verified

## Metadata
- **Date**: YYYY-MM-DD HH:MM
- **Executor Instance**: [N of M]
- **Context Exhaustion**: [Yes/No]
- **Phases Completed**: [N/M]
- **Git Commits**: [list of hashes]

## Completed Work Details
[Standard summary content for completed phases...]
```

**Key Design Decision**: Work Status at the top ensures build.md immediately sees whether continuation is needed without parsing the entire summary.

## Implementation Phases

### Phase 1: Create Implementation Executor Agent
dependencies: []

**Objective**: Create the missing implementation-executor.md agent with automatic plan updates, context exhaustion detection, and summary generation with Work Remaining sections

**Complexity**: High

Tasks:
- [x] Create `/home/benjamin/.config/.claude/agents/implementation-executor.md` with proper YAML frontmatter (allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task)
- [x] Define agent role as single-phase executor with automatic plan updates and continuation support
- [x] Implement task execution workflow with progress tracking
- [x] Add plan file update logic using Edit tool to mark tasks with [x]
- [x] Add spec-updater invocation for hierarchy propagation
- [x] Add test execution for phase-specific tests
- [x] Add git commit creation with standardized message format: `feat(NNN): complete Phase N - [Phase Name]`
- [x] Implement context exhaustion detection at 70% threshold (track cumulative output, check after each phase, after large file ops, after test output)
- [x] Add summary generation with Work Status section at TOP of file
- [x] Implement Work Remaining section format with specific incomplete tasks
- [x] Add Continuation Instructions section with exact resume point (phase number, task number)
- [x] Implement continuation_context parameter handling to resume from previous summary
- [x] Define structured return format with work_remaining field:
  ```yaml
  PHASE_COMPLETE:
    status: success|partial|failed
    tasks_completed: N
    tests_passing: true|false
    commit_hash: [hash]
    context_exhausted: true|false
    work_remaining: 0|[list of incomplete tasks]
  ```
- [x] Document behavioral guidelines for context exhaustion graceful exit
- [x] Add examples for fresh start vs continuation invocation

Testing:
```bash
# Verify agent file exists and has valid structure
test -f /home/benjamin/.config/.claude/agents/implementation-executor.md
grep -q "allowed-tools:" /home/benjamin/.config/.claude/agents/implementation-executor.md
grep -q "description:" /home/benjamin/.config/.claude/agents/implementation-executor.md
grep -q "context_exhausted" /home/benjamin/.config/.claude/agents/implementation-executor.md
grep -q "work_remaining" /home/benjamin/.config/.claude/agents/implementation-executor.md
grep -q "Work Status" /home/benjamin/.config/.claude/agents/implementation-executor.md
grep -q "continuation_context" /home/benjamin/.config/.claude/agents/implementation-executor.md
```

**Expected Duration**: 5 hours

### Phase 2: Remove PROGRESS CHECKPOINT Insertion Code
dependencies: []

**Objective**: Remove PROGRESS CHECKPOINT insertion logic from plan-architect and plan-structure-manager

**Complexity**: Medium

Tasks:
- [x] Edit `/home/benjamin/.config/.claude/agents/plan-architect.md` to remove STEP 2.5 (lines 115-172)
- [x] Remove task-level checkpoint template from plan-architect.md (lines 152-159)
- [x] Remove phase completion checklist template from plan-architect.md (lines 162-169)
- [x] Remove checkpoint injection algorithm from plan-architect.md (lines 143-150)
- [x] Update verification checklist in plan-architect.md to remove checkpoint references
- [x] Edit `/home/benjamin/.config/.claude/agents/plan-structure-manager.md` to remove STEP 3.5 (lines 151-238)
- [x] Remove task-level reminder template from plan-structure-manager.md (lines 162-169)
- [x] Remove phase completion checklist template from plan-structure-manager.md (lines 171-194)
- [x] Remove stage completion checklist templates from plan-structure-manager.md (lines 433-456)
- [x] Remove reminder injection commands from plan-structure-manager.md (lines 201-238)
- [x] Update quality checklist in plan-structure-manager.md to remove checkpoint references
- [x] Renumber subsequent steps after removal (STEP 3 becomes STEP 2.5, etc.)

Testing:
```bash
# Verify PROGRESS CHECKPOINT code is removed
! grep -q "PROGRESS CHECKPOINT" /home/benjamin/.config/.claude/agents/plan-architect.md
! grep -q "PROGRESS CHECKPOINT" /home/benjamin/.config/.claude/agents/plan-structure-manager.md
! grep -q "STEP 2.5.*Progress" /home/benjamin/.config/.claude/agents/plan-architect.md
! grep -q "STEP 3.5.*Progress" /home/benjamin/.config/.claude/agents/plan-structure-manager.md
```

**Expected Duration**: 2 hours

### Phase 3: Add Summary Generation Logic with Work Remaining Format
dependencies: [1]

**Objective**: Implement summary generation with Work Status at TOP, specific Work Remaining tasks, and 100% completion validation

**Complexity**: Medium

Tasks:
- [x] Add summary generation function to implementation-executor.md with Work Status at TOP
- [x] Implement Work Remaining section format template:
  ```markdown
  ## Work Status
  **Completion**: [XX]% complete
  **Continuation Required**: [Yes/No]

  ### Work Remaining
  - [ ] Phase N: [Phase Name] - [specific task 1]
  - [ ] Phase N: [Phase Name] - [specific task 2]

  ### Continuation Instructions
  To continue: re-invoke with this summary as continuation_context
  Resume from Phase N, task M
  ```
- [x] Implement 100% complete validation - only state "100% complete" when ALL tasks have [x]
- [x] Use workflow-phases.md summary template (lines 729-849) as basis for Completed Work Details
- [x] Implement summary path calculation: `{topic_path}/summaries/NNN_workflow_summary.md`
- [x] Add summary metadata population (date, topic, duration, phases, executor instance number)
- [x] Add phase completion details to summary
- [x] Add git commits list to summary
- [x] Add files modified tracking to summary
- [x] Create context checkpoint summary variant triggered at 70% threshold
- [x] Ensure Continuation Instructions include exact resume point (phase number, task description)
- [x] Add summary path to structured return from implementation-executor

Testing:
```bash
# Verify summary template sections exist in implementation-executor
grep -q "Work Status" /home/benjamin/.config/.claude/agents/implementation-executor.md
grep -q "Work Remaining" /home/benjamin/.config/.claude/agents/implementation-executor.md
grep -q "Continuation Instructions" /home/benjamin/.config/.claude/agents/implementation-executor.md
grep -q "100% complete" /home/benjamin/.config/.claude/agents/implementation-executor.md
grep -q "summaries/" /home/benjamin/.config/.claude/agents/implementation-executor.md
```

**Expected Duration**: 2 hours

### Phase 4: Add Continuation Invocation Loop to Build Command
dependencies: [1, 3]

**Objective**: Implement continuation loop in build.md that re-invokes executor with previous summary when work remains

**Complexity**: High

Tasks:
- [x] Add continuation loop to `/home/benjamin/.config/.claude/commands/build.md` Part 4 with MAX_ITERATIONS=5
- [x] Implement loop structure:
  ```bash
  ITERATION=0
  while [ work_remaining > 0 ] && [ ITERATION < MAX_ITERATIONS ]; do
    if ITERATION > 0: pass previous_summary as continuation_context
    invoke implementer-coordinator
    parse return for work_remaining, summary_path
    ITERATION++
  done
  ```
- [x] Add error handling for MAX_ITERATIONS reached without completion (timeout error to user)
- [x] Parse implementer-coordinator return for work_remaining and summary_path fields
- [x] Pass continuation_context parameter to implementer-coordinator when continuing
- [x] Add summary display to user in build.md completion output
- [x] Update return signal documentation in build.md
- [x] Update `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` executor invocation to match new interface
- [x] Update expected return format in implementer-coordinator to include structured results with work_remaining
- [x] Add summary path aggregation logic to implementer-coordinator
- [x] Update result aggregation to track git commits across all phases
- [x] Add handling of context_exhausted signal from implementation-executor
- [x] Re-invoke implementation-executor with continuation_context when context exhaustion detected
- [x] Update final return format to include summary_path and work_remaining fields

Testing:
```bash
# Verify continuation loop in build.md
grep -q "MAX_ITERATIONS" /home/benjamin/.config/.claude/commands/build.md
grep -q "continuation_context" /home/benjamin/.config/.claude/commands/build.md
grep -q "work_remaining" /home/benjamin/.config/.claude/commands/build.md

# Verify updated return formats in implementer-coordinator
grep -q "summary_path" /home/benjamin/.config/.claude/agents/implementer-coordinator.md
grep -q "work_remaining" /home/benjamin/.config/.claude/agents/implementer-coordinator.md
grep -q "context_exhausted" /home/benjamin/.config/.claude/agents/implementer-coordinator.md
grep -q "continuation_context" /home/benjamin/.config/.claude/agents/implementer-coordinator.md
```

**Expected Duration**: 3 hours

### Phase 5: Update Implementer Coordinator for Context Exhaustion Handling
dependencies: [1, 3]

**Objective**: Update implementer-coordinator to handle context_exhausted signal and re-invoke executor with continuation

**Complexity**: Medium

Tasks:
- [x] Update `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` to detect context_exhausted from executor return
- [x] Add logic to re-invoke implementation-executor with continuation_context when context exhausted
- [x] Implement continuation_context parameter in executor invocation:
  ```markdown
  Input:
  - plan_path: $PLAN_FILE
  - topic_path: $TOPIC_PATH
  - continuation_context: $PREVIOUS_SUMMARY_PATH  # Optional, for continuation
  - iteration: $ITERATION
  ```
- [x] Add executor instance tracking (N of M)
- [x] Update wave execution loop to check for context exhaustion after each phase
- [x] Add summary generation trigger when all phases complete OR context exhausted
- [x] Ensure partial completion summaries include exact resume point
- [x] Update result aggregation to merge across continuation instances
- [x] Add handling for graceful exit with handoff summary

Testing:
```bash
# Verify context exhaustion handling in implementer-coordinator
grep -q "context_exhausted" /home/benjamin/.config/.claude/agents/implementer-coordinator.md
grep -q "continuation_context" /home/benjamin/.config/.claude/agents/implementer-coordinator.md
grep -q "iteration" /home/benjamin/.config/.claude/agents/implementer-coordinator.md
```

**Expected Duration**: 2 hours

### Phase 6: Testing and Documentation
dependencies: [1, 2, 3, 4, 5]

**Objective**: Verify all components work together including continuation loop, and update documentation

**Complexity**: Low

Tasks:
- [ ] Create unit test for implementation-executor plan update logic
- [ ] Create unit test for context exhaustion detection at 70% threshold
- [ ] Create unit test for summary generation with Work Status at top
- [ ] Create integration test for full workflow with summary generation
- [ ] Test continuation loop with simulated context exhaustion
- [ ] Test that new executor instance reads previous summary and resumes from correct point
- [ ] Verify summary states "100% complete" only when all tasks have [x]
- [ ] Test git commit creation with proper message format
- [ ] Test spec-updater hierarchy propagation
- [ ] Verify MAX_ITERATIONS error handling (timeout error to user)
- [ ] Verify existing plans without PROGRESS CHECKPOINTs work correctly
- [ ] Update CLAUDE.md if needed with new workflow documentation
- [ ] Update relevant .claude/docs files with new continuation architecture
- [ ] Create example of new workflow in action showing continuation scenario

Testing:
```bash
# Run test suite
cd /home/benjamin/.config && bash .claude/run_all_tests.sh
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Tests

1. **implementation-executor plan update test**: Verify Edit tool correctly marks tasks with [x]
2. **summary generation test**: Verify summary file created with Work Status at TOP
3. **context exhaustion test**: Verify 70% threshold triggers summary creation
4. **Work Remaining format test**: Verify incomplete summaries have proper Work Remaining section
5. **100% complete validation test**: Verify "100% complete" only when all tasks have [x]
6. **continuation_context parsing test**: Verify executor correctly reads previous summary and determines resume point

### Integration Tests

1. **Full workflow test**: Execute /build with test plan, verify:
   - All tasks marked complete in plan file
   - Git commits created with correct messages
   - Summary generated in summaries/ directory with Work Status at TOP
   - Structured return includes all expected fields including work_remaining

2. **Continuation loop test**: Simulate context exhaustion, verify:
   - Summary generated with Work Remaining section listing specific incomplete tasks
   - build.md continuation loop re-invokes with previous summary
   - New executor instance reads summary and resumes from correct phase/task
   - Final summary shows "100% complete" after successful continuation

3. **MAX_ITERATIONS timeout test**: Verify error handling when max iterations reached without completion

4. **Parallel execution test**: Verify wave-based execution with multiple parallel phases

### Regression Tests

1. Verify existing plans without PROGRESS CHECKPOINTs continue to work
2. Verify implementer-coordinator wave-based orchestration unchanged
3. Verify spec-updater hierarchy updates still function

## Documentation Requirements

### Files to Update

1. **CLAUDE.md**: No changes required (references /build workflow which is being enhanced)
2. **implementer-coordinator.md**: Update behavioral guidelines with new executor interface and context exhaustion handling
3. **build.md**: Update Part 4 documentation with new continuation loop and return format
4. **workflow-phases.md**: Add reference to automatic summary generation and Work Remaining format

### New Documentation

1. **implementation-executor.md**: Comprehensive agent documentation including:
   - Context exhaustion detection at 70% threshold
   - Summary generation with Work Status at TOP
   - Work Remaining section format
   - Continuation Instructions format
   - continuation_context parameter handling
   - Structured return format with work_remaining field

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

1. **build.md** implements continuation loop, invokes implementer-coordinator with optional continuation_context
2. **implementer-coordinator.md** invokes implementation-executor per phase, handles context_exhausted signals
3. **implementation-executor.md** detects context exhaustion, generates summaries with Work Remaining, returns structured format
4. **spec-updater.md** handles hierarchy propagation
5. **workflow-phases.md** provides summary template (Work Status at TOP pattern)

## Risks and Mitigations

### Risk 1: Breaking existing workflows
**Mitigation**: Phase 2 removes CHECKPOINTs but doesn't change plan structure; Phase 4 and 5 updates are additive; comprehensive testing in Phase 6

### Risk 2: Summary generation path conflicts
**Mitigation**: Use consistent numbering pattern matching plan number; verify path doesn't exist before creation

### Risk 3: Context exhaustion false positives
**Mitigation**: Use conservative 70% threshold; log context usage for monitoring; allow user override

### Risk 4: Git commit failures
**Mitigation**: implementation-executor handles commit failures gracefully; reports error without blocking workflow

### Risk 5: Infinite continuation loop
**Mitigation**: MAX_ITERATIONS=5 limit with clear error message to user; track iteration count in summary metadata

### Risk 6: Previous summary corruption
**Mitigation**: Validate summary format before parsing; fall back to plan checkboxes for progress if summary unreadable; error message guides user to manual intervention

### Risk 7: Executor fails to resume from correct point
**Mitigation**: Continuation Instructions include exact phase number and task description; executor validates resume point against plan checkboxes

## Notes

- Phase dependencies enable parallel execution: Phases 1 and 2 can run in parallel (Wave 1)
- Phases 3, 4, and 5 depend on Phase 1 (Phases 4 and 5 can run in parallel in Wave 2)
- Phase 6 depends on all prior phases (Wave 3)
- Estimated time savings from parallelization: ~30% (14 hours sequential vs ~10 hours parallel)

Wave Execution Plan:
- **Wave 1**: Phase 1 (5h) || Phase 2 (2h) = 5h elapsed
- **Wave 2**: Phase 3 (2h) || Phase 4 (3h) || Phase 5 (2h) = 3h elapsed
- **Wave 3**: Phase 6 (2h) = 2h elapsed
- **Total with parallelization**: ~10 hours
