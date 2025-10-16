# Reduce Implementation Interruptions Implementation Plan

## Metadata
- **Date**: 2025-10-10
- **Plan Location**: /home/benjamin/.config/.claude/037_reduce_implementation_interruptions/
- **Feature**: Reduce implementation interruptions through agent-based complexity evaluation and smart workflow improvements
- **Scope**: /implement and /orchestrate command workflow redesign, CLAUDE.md configuration updates, complexity evaluation system
- **Estimated Phases**: 7
- **Structure Level**: 1
- **Expanded Phases**: [2, 4]
- **Implementation Status**: Not started (plan only, no code changes yet)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: /home/benjamin/.config/.claude/specs/reports/031_reducing_implementation_interruptions.md
- **Specs Directory**: /home/benjamin/.config/.claude/specs/

## ✅ Pre-Implementation Status: READY

**Updated**: 2025-10-12

This plan has been revised to reflect the current state of the `.claude/` directory after recent optimizations. All line numbers, file structures, and implementation details have been updated to match the actual codebase.

### Changes Since Original Plan
- Updated all line number references in CLAUDE.md to reflect current structure
- Updated implement.md step references to match current workflow (868 lines total)
- Updated orchestrate.md checkpoint references (1953 lines total)
- Verified current utilities and library structure
- Confirmed agent registry and command structure

## Overview

This plan implements a comprehensive redesign of the `/implement` and `/orchestrate` command workflows to minimize user interruptions while preserving necessary interaction points. The core changes replace magic-number threshold-based complexity checks with pure agent-based evaluation, move expansion/contraction review to post-planning (pre-implementation), implement automatic debug invocation for test failures, and add smart checkpoint auto-resume capabilities.

**Commands Affected**: `/implement` and `/orchestrate` (both have similar checkpoint resume interruptions)

### Key Architectural Changes

1. **Agent-Based Complexity Evaluation**: Replace all threshold-based checks (magic numbers) with the existing `complexity_estimator.md` agent for contextual, intelligent analysis
2. **Post-Planning Review**: Move expansion/contraction evaluation from reactive (during implementation) to proactive (after planning, before implementation)
3. **Automatic Debug Integration**: When tests fail, automatically invoke `/debug` and present user with choice to run `/revise` using debug findings
4. **Smart Auto-Resume**: Eliminate unnecessary checkpoint prompts by auto-resuming when safe (tests passing, no errors, recent, plan unmodified)
5. **Careful Mode Configuration**: Add boolean flag to control whether to always show recommendations or only show high-confidence ones

## Success Criteria

- [ ] All FIX comments from report 031 addressed
- [ ] No magic numbers or keyword-based thresholds in complexity evaluation
- [ ] Expansion/contraction review happens once after plan creation, before implementation
- [ ] Test failures trigger automatic /debug invocation with user choice prompt
- [ ] Checkpoint resume is automatic when safe conditions met
- [ ] Careful mode configuration documented and functional
- [ ] All tests pass after each phase
- [ ] Clean-break refactor with no legacy patterns

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        /implement Workflow                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Load Plan → Auto-Resume Check (if checkpoint exists)       │
│     ├─ Safe conditions? → Auto-resume silently                 │
│     └─ Unsafe conditions? → Interactive prompt                 │
│                                                                 │
│  2. Post-Planning Complexity Review (NEW - Step 1.6)           │
│     ├─ Invoke complexity_estimator agent                       │
│     ├─ Analyze ALL phases for expansion/collapse needs         │
│     ├─ No recommendations? → Proceed silently                  │
│     └─ Has recommendations? → Present summary + get approval   │
│                                                                 │
│  3. Implementation Loop (per phase)                            │
│     ├─ Display phase info                                      │
│     ├─ Complexity analysis for agent selection                 │
│     ├─ Implement phase                                         │
│     ├─ Run tests                                               │
│     │   ├─ Pass? → Commit and continue                         │
│     │   └─ Fail? → Auto /debug + present choice               │
│     └─ Update plan                                             │
│                                                                 │
│  4. Completion                                                 │
│     └─ Generate summary, cleanup checkpoint                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

Removed from workflow:
  × Step 1.55: Proactive expansion check (per-phase)
  × Step 3.4: Reactive expansion after phase completion
  × Step 5.5: Automatic collapse detection after completion
```

### Agent-Based Complexity Analysis Pattern

```javascript
// Context building for complexity_estimator agent
{
  "parent_plan_context": {
    "overview": "<plan overview>",
    "goals": "<plan goals>",
    "constraints": "<plan constraints>"
  },
  "current_structure_level": 0,  // or 1, 2
  "items_to_analyze": [
    {
      "item_id": "phase_1",
      "item_name": "Phase Name",
      "content": "<phase description and tasks>"
    }
  ]
}

// Expected response format
[
  {
    "item_id": "phase_1",
    "item_name": "Phase Name",
    "complexity_level": 7,  // 1-10 scale
    "reasoning": "Detailed contextual rationale",
    "recommendation": "expand|skip|collapse|keep",
    "confidence": "high|medium|low"
  }
]
```

### Careful Mode Behavior

```yaml
careful_mode: true
  # Always present expansion/contraction recommendations for approval
  # Conservative approach - user sees all agent recommendations

careful_mode: false
  # Only present high-confidence recommendations
  # Medium/low confidence recommendations logged but not displayed
  # Streamlined workflow for experienced users
```

### Smart Auto-Resume Logic

```bash
# Safe auto-resume conditions (ALL must be true)
tests_passing: true
last_error: null
checkpoint_age: < 7 days
plan_modification_time: before checkpoint creation

# If ALL conditions met: Auto-resume silently with log message
# If ANY condition fails: Interactive prompt (existing behavior)
```

## Implementation Phases

### Phase 1: Configuration Updates and Foundation
**Objective**: Update CLAUDE.md configuration, remove thresholds, add careful mode
**Complexity**: Low

Tasks:
- [ ] Read current CLAUDE.md "Adaptive Planning Configuration" section (lines 210-251)
- [ ] Remove "Adaptive Planning Configuration" section with threshold values
- [ ] Add new "Careful Mode Configuration" section after "Adaptive Planning" section (after line 239)
- [ ] Document careful_mode: true (default, conservative) and false (streamlined)
- [ ] Update "Adaptive Planning" section (lines 210-239) to reference agent-based evaluation (no thresholds)
- [ ] Remove all references to magic number thresholds (currently at lines 217: "score >8 or >10 tasks")
- [ ] Add note: "Complexity evaluation performed exclusively by complexity_estimator agent"
- [ ] Update documentation to reflect new workflow: plan → complexity review → implement
- [ ] Verify "Development Workflow" section (lines 252-265) aligns with new approach

Testing:
```bash
# Verify CLAUDE.md updated correctly
grep -i "threshold.*8\|threshold.*10" /home/benjamin/.config/CLAUDE.md
# Should NOT find any magic number thresholds

grep "careful_mode" /home/benjamin/.config/CLAUDE.md
# Should find careful mode documentation

# Verify Adaptive Planning Configuration section removed
grep -A 5 "Adaptive Planning Configuration" /home/benjamin/.config/CLAUDE.md
# Should NOT find this section
```

Expected outcome: Clean configuration with careful mode flag, no threshold values, agent-based evaluation documented

### Phase 2: Post-Planning Complexity Review (Step 1.6) (High)
**Objective**: Add new Step 1.6 to /implement for post-planning, pre-implementation complexity review
**Status**: PENDING

**Summary**: Introduces agent-based post-planning complexity review as new Step 1.6 in /implement workflow. Invokes complexity_estimator agent once after plan loading to analyze all phases, displays recommendations only when present and significant, and provides clear user interaction for applying expansions/collapses before implementation begins.

For detailed tasks and implementation, see [Phase 2 Details](phase_2_post_planning_complexity_review.md)

### Phase 3: Remove Reactive Expansion/Collapse Logic
**Objective**: Remove Steps 1.55, 3.4, and 5.5 from /implement
**Complexity**: Medium

Tasks:
- [ ] Read implement.md Step 1.55 "Proactive Expansion Check" (lines 274-287)
- [ ] Delete entire Step 1.55 section including documentation and code logic
- [ ] Read implement.md Step 3.4 "Adaptive Planning Detection" (lines 322-337)
- [ ] Preserve test failure pattern detection (Trigger 2: "2+ consecutive test failures")
- [ ] Preserve scope drift detection (Trigger 3: "manual flag --report-scope-drift")
- [ ] Remove Trigger 1 (complexity threshold: "score >8 or >10 tasks")
- [ ] Update trigger list in Step 3.4 to remove complexity detection trigger
- [ ] Update Step 3.4 header to "Test Failure and Scope Drift Detection"
- [ ] Read implement.md Step 5.5 "Automatic Collapse Detection" (lines 428-555)
- [ ] Delete entire Step 5.5 section (128 lines of collapse logic)
- [ ] Update step numbering: Step 6 (line 556) becomes Step 5.5
- [ ] Update step numbering: Step 7 (line 611) becomes Step 5.6
- [ ] Remove all references to complexity threshold checks in implementation flow
- [ ] Verify no magic number comparisons (>8, >10) remain in adaptive planning logic

Testing:
```bash
# Grep for removed patterns
grep -i "expansion threshold\|task count threshold" .claude/commands/implement.md
# Should return no results

grep -i "step 1.55" .claude/commands/implement.md
# Should return no results

grep -i "automatic collapse detection" .claude/commands/implement.md
# Should return no results

# Verify step renumbering
grep "^### [567]\." .claude/commands/implement.md
# Should show: 5.5, 5.6 (not 5.5, 6, 7)
```

Expected outcome: Clean removal of reactive expansion/collapse, test failure detection preserved, correct step numbering

### Phase 4: Automatic Debug Integration for Test Failures (High)
**Objective**: Modify test failure handling to automatically invoke /debug and present user choice
**Status**: PENDING

**Summary**: Streamlines test failure workflow by automatically invoking /debug when tests fail (Step 3.3 of /implement), parsing debug output to extract root cause, and presenting user with four clear choices: (r)evise with debug findings, (c)ontinue anyway, (s)kip phase, or (a)bort. Eliminates the "should I run debug?" interruption while preserving user control over next steps.

For detailed tasks and implementation, see [Phase 4 Details](phase_4_automatic_debug_integration.md)

### Phase 5: Smart Checkpoint Auto-Resume for /implement
**Objective**: Implement intelligent auto-resume logic to eliminate unnecessary checkpoint prompts in /implement
**Complexity**: Medium

Tasks:
- [ ] Read implement.md "Checkpoint Detection and Resume" section (lines 851-868)
- [ ] Locate checkpoint loading logic (Step 1 in checkpoint workflow)
- [ ] Review current checkpoint state fields (line 863-866): workflow_description, plan_path, current_phase, total_phases, completed_phases, status, tests_passing, replan_count, phase_replan_count, replan_history
- [ ] Add checkpoint metadata evaluation before interactive resume prompt (Step 2)
- [ ] Extract: tests_passing, last_error, created_at, plan_modification_time from checkpoint
- [ ] Calculate checkpoint age: current_time - created_at
- [ ] Compare plan file modification time vs checkpoint creation time
- [ ] Implement safe auto-resume logic: tests_passing=true AND last_error=null AND age<7days AND plan_unmodified
- [ ] If ALL safe conditions met: Auto-resume with log message, skip interactive prompt
- [ ] Log decision: "Auto-resuming from Phase N (all safety conditions met)"
- [ ] If ANY condition fails: Show existing interactive prompt (Step 2)
- [ ] Add brief context to prompt: "Auto-resume skipped: <reason>"
- [ ] Update checkpoint save logic (Step 4: "Save after each phase") to include plan_modification_time
- [ ] Ensure checkpoint metadata complete for future auto-resume evaluations
- [ ] Update checkpoint documentation to describe auto-resume conditions

Testing:
```bash
# Test auto-resume with safe checkpoint (recent, tests passing, plan unchanged)
# Test interactive prompt with stale checkpoint (>7 days old)
# Test interactive prompt with failed tests
# Test interactive prompt with modified plan
# Test interactive prompt with errors in checkpoint
# Verify log messages for auto-resume decisions
```

Expected outcome: Zero interruption for safe resumes, interactive only when necessary

### Phase 6: Smart Checkpoint Auto-Resume for /orchestrate
**Objective**: Apply same intelligent auto-resume logic to /orchestrate command
**Complexity**: Medium

Tasks:
- [ ] Read orchestrate.md checkpoint detection section (lines 1884-1908)
- [ ] Locate checkpoint loading logic: "Step 1: Check for Existing Checkpoint" (line 1884-1890)
- [ ] Review "Step 2: Interactive Resume Prompt" (lines 1893-1908)
- [ ] Apply identical auto-resume logic from Phase 5
- [ ] Extract orchestrate checkpoint metadata: workflow_state, completed_phases, current_phase
- [ ] Review checkpoint data structure mentioned in line 309-311, 561, 671, 770, 773, 785, 801, 1019, 1035, 1077, 1094, 1422
- [ ] Add workflow-specific checks: no failed phases, all completed phases have passing tests
- [ ] Calculate checkpoint age: current_time - checkpoint.created_at
- [ ] Implement safe auto-resume conditions:
  - completed_phases all have tests_passing=true (if applicable)
  - last_phase_status != "failed"
  - checkpoint_age < 7 days
  - workflow_state.status != "escalated"
- [ ] If ALL safe conditions met: Auto-resume workflow from next phase, skip interactive prompt
- [ ] Log decision: "Auto-resuming workflow from Phase [next_phase] (all safety conditions met)"
- [ ] If ANY condition fails: Show existing interactive prompt (lines 1898-1908)
- [ ] Add brief context to prompt: "Auto-resume skipped: <reason>"
- [ ] Update checkpoint save logic throughout orchestrate workflow (search for "save_checkpoint" references)
- [ ] Ensure workflow_state includes sufficient metadata for auto-resume evaluation
- [ ] Update orchestrate checkpoint documentation (line 1663-1689)

Testing:
```bash
# Test auto-resume with safe orchestrate checkpoint (recent, no failures)
# Test interactive prompt with failed phase in checkpoint
# Test interactive prompt with stale orchestrate checkpoint (>7 days)
# Test interactive prompt with escalated workflow status
# Verify log messages for orchestrate auto-resume decisions
# Verify workflow correctly resumes from next incomplete phase
```

Expected outcome: Zero interruption for safe orchestrate resumes, preserves multi-phase workflow state

### Phase 7: Documentation and Testing
**Objective**: Update all documentation to reflect new workflow and verify comprehensive testing for both commands
**Complexity**: Medium

Tasks:

**implement.md Documentation:**
- [ ] Read implement.md full documentation sections (868 lines total)
- [ ] Update "Adaptive Planning Features" section (lines 17-56) to remove threshold language
- [ ] Replace threshold documentation with agent-based complexity evaluation description
- [ ] Add "Post-Planning Complexity Review" section documenting new Step 1.6
- [ ] Add "Automatic Debug Integration" section documenting test failure workflow
- [ ] Add "Smart Checkpoint Auto-Resume" section documenting auto-resume logic
- [ ] Update "Process" section (line 80) to reflect new workflow sequence
- [ ] Remove all mentions of "proactive expansion check" from documentation
- [ ] Update "Checkpoint Detection and Resume" section (lines 851-868) with auto-resume details
- [ ] Add careful_mode flag to command argument-hint (line 3) if applicable
- [ ] Update examples to show new workflow without interruptions

**orchestrate.md Documentation:**
- [ ] Read orchestrate.md documentation sections (1953 lines total)
- [ ] Update "Checkpoint Management" overview (line 20) to mention auto-resume
- [ ] Update checkpoint detection documentation (lines 1884-1908) to describe auto-resume logic
- [ ] Add "Smart Auto-Resume Conditions" subsection before "Step 2: Interactive Resume Prompt"
- [ ] Document orchestrate-specific safety checks (workflow status, phase completion)
- [ ] Update checkpoint restoration flow to show auto-resume path
- [ ] Update "Checkpoint Management Patterns" reference (line 1663) with auto-resume details
- [ ] Add note about when interactive prompts still appear (failures, stale checkpoints, etc.)
- [ ] Update examples to show transparent auto-resume behavior

**Test Cases:**
- [ ] Create test cases for /implement:
  - Test 1: Post-planning review with no recommendations
  - Test 2: Post-planning review with expansion recommendations
  - Test 3: Test failure → auto debug → revise choice
  - Test 4: Checkpoint auto-resume (safe conditions)
  - Test 5: Checkpoint interactive prompt (unsafe conditions)
- [ ] Create test cases for /orchestrate:
  - Test 6: Orchestrate auto-resume with safe multi-phase checkpoint
  - Test 7: Orchestrate interactive prompt with failed phase
  - Test 8: Orchestrate interactive prompt with stale checkpoint
- [ ] Run all existing /implement tests to ensure no regressions
- [ ] Run all existing /orchestrate tests (if any) to ensure no regressions
- [ ] Update CHANGELOG or implementation notes if required

Testing:
```bash
# Run test suite
cd /home/benjamin/.config/.claude/tests
./test_adaptive_planning.sh
./test_command_integration.sh

# Verify implement command with real plan
# Check for interruptions during implementation
# Verify only expected interaction points remain

# Verify orchestrate command with real workflow
# Check for checkpoint auto-resume in multi-phase workflows
# Verify interactive prompts only appear when necessary
```

Expected outcome: Complete, accurate documentation for both commands; all tests passing; verified workflows

## Testing Strategy

### Unit Testing
- Test complexity_estimator agent invocation and response parsing
- Test safe auto-resume condition evaluation
- Test /debug invocation and result handling
- Test user choice handling for all branches

### Integration Testing
- End-to-end test: Create plan → implement with complexity review → complete
- Test failure path: Implement → test fails → auto debug → revise → continue
- Checkpoint resume: Start implementation → interrupt → resume (auto and interactive)

### Regression Testing
- Verify existing /implement functionality preserved
- Test with Level 0, Level 1, Level 2 plan structures
- Verify adaptive planning logging still works
- Ensure test failure pattern detection still functions

### Coverage Requirements
- All new code paths tested
- All user interaction branches tested
- Error handling tested (agent failures, invalid responses)
- Edge cases: empty plan, single-phase plan, complex multi-phase plan

## Dependencies

### Required Components
- `complexity_estimator.md` agent (already exists)
- `/debug` command (already exists)
- `/revise --auto-mode` (already exists)
- Checkpoint utilities: `.claude/lib/checkpoint-utils.sh`
- Adaptive planning logger: `.claude/lib/adaptive-planning-logger.sh`

### External Dependencies
- None (all components are internal)

### Configuration Dependencies
- CLAUDE.md must support careful_mode configuration (added in Phase 1)
- Checkpoint schema must support plan_modification_time (added in Phase 5)

## Risk Assessment

### High Risk
- **Breaking existing implementations**: Removing reactive expansion logic could affect users mid-implementation
  - Mitigation: Clean-break approach, comprehensive testing
- **Agent invocation failures**: complexity_estimator agent might fail or return invalid JSON
  - Mitigation: Graceful error handling, fallback to continue without review

### Medium Risk
- **Auto-resume false positives**: Auto-resume when it shouldn't
  - Mitigation: Conservative conditions (ALL must be true), extensive testing
- **User confusion with new workflow**: Different from current behavior
  - Mitigation: Clear documentation, informative log messages

### Low Risk
- **Performance impact**: Agent invocation adds latency
  - Mitigation: Single invocation per implementation (post-planning), acceptable overhead

## Migration Notes

### Breaking Changes
1. **No more reactive expansion**: Plans won't automatically expand mid-implementation
2. **Threshold configuration removed**: CLAUDE.md complexity thresholds no longer used
3. **Checkpoint resume behavior changed**: Auto-resume replaces some interactive prompts

### User Impact
- **Positive**: Fewer interruptions, clearer workflow, better debug integration
- **Neutral**: Different interaction points (post-planning vs. mid-implementation)
- **Minimal**: Existing plans continue to work, no data migration needed

### Rollback Plan
If issues arise:
1. Revert implement.md to previous version
2. Restore CLAUDE.md threshold configuration
3. Document specific issues for future refinement

## Notes

### Design Rationale
- **Agent-based evaluation**: Contextual intelligence superior to magic numbers
- **Post-planning review**: Single review point before work begins, not during
- **Automatic debug**: Preserves debugging but eliminates prompt to run it
- **Smart auto-resume**: Respects user's workflow state, resumes when safe

### Future Enhancements
- Could add careful_mode to command-line flags: `/implement --careful-mode`
- Could expand auto-resume conditions with more sophisticated analysis
- Could provide debug report summary in-line without requiring user to open file

### Alignment with Project Philosophy
- **Clean-break refactor**: Removes threshold-based logic entirely
- **Present-focused documentation**: Documents current workflow only
- **System coherence**: All commands work together harmoniously (debug, revise, implement)
- **Maintainability**: Simpler logic, clearer responsibilities

## Revision History

### 2025-10-12 - Revision 2
**Changes**: Comprehensive update to reflect current codebase state after optimization work
**Reason**: Plan contained outdated line numbers, step references, and file structures that no longer matched the actual `.claude/` directory implementation
**Modifications**:
- Removed "Pre-Implementation Requirements" blocker - plan is now ready for implementation
- **Phase 1**: Updated CLAUDE.md line references (210-251 current vs 176-212 old)
- **Phase 3**: Updated implement.md references:
  - Step 1.55 (lines 274-287, was 438-512)
  - Step 3.4 (lines 322-337, was 654-845)
  - Step 5.5 (lines 428-555, was 331-457)
  - Corrected step renumbering (6→5.5, 7→5.6)
- **Phase 5**: Updated implement.md checkpoint section (lines 851-868, was 862-945)
- **Phase 6**: Updated orchestrate.md checkpoint section (lines 1884-1908, was 2405-2474)
- **Phase 7**: Updated documentation references with current line counts (implement.md: 868 lines, orchestrate.md: 1953 lines)
- Verified current utility library structure (.claude/lib/)
- Verified current agent registry and command structure
- Updated all testing grep patterns to match current file structure

**Impact**: Plan now accurately reflects the current codebase and can be implemented without conflicts

### 2025-10-10 - Revision 1
**Changes**: Extended plan to include `/orchestrate` command
**Reason**: User identified similar checkpoint resume interruptions in `/orchestrate` command that should receive the same smart auto-resume treatment
**Modifications**:
- Updated scope from "6 phases" to "7 phases"
- Split Phase 5 into Phase 5 (implement) and Phase 6 (orchestrate) for smart auto-resume
- Updated Phase 7 (formerly Phase 6) documentation tasks to cover both commands
- Added orchestrate-specific safety checks: workflow status, phase completion states
- Added orchestrate-specific test cases (tests 6-8)

**Impact**: Both `/implement` and `/orchestrate` will benefit from identical interruption reduction improvements
