# Option B: State Machine Extension for THEN Breakpoint Syntax - Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: THEN Breakpoint Syntax via State Machine Extension
- **Scope**: Add THEN command chaining to /research, /debug, /plan, /revise commands
- **Estimated Phases**: 6
- **Estimated Hours**: 18
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 71.5
- **Research Reports**:
  - [Option B State Machine Implementation](../reports/001_option_b_state_machine_implementation.md)
  - [THEN Breakpoint Syntax Research](../../774_for_the_research_debug_plan_research_and_revise_co/reports/001_then_breakpoint_syntax.md)

## Overview

This plan implements Option B (State Machine Extension with Explicit Phase Transitions) for THEN breakpoint syntax across the /research, /debug, /plan, and /revise workflow commands. The implementation extends the existing state-based orchestration architecture by adding a STATE_THEN_PENDING state, extending state transitions, implementing queuing functions (sm_queue_then_command, sm_has_queued_then, sm_execute_queued_then), adding THEN parsing to argument-capture.sh, updating checkpoint schema to v2.2, and integrating with all four target commands.

### Goals

1. Enable command chaining syntax: `/research "description" THEN /plan`
2. Support artifact context passing between chained commands
3. Maintain backward compatibility with existing workflows
4. Follow existing state machine patterns and checkpoint persistence
5. Provide clear error messages for invalid THEN syntax

### Non-Goals

- Multi-THEN chains (e.g., `/research THEN /plan THEN /implement`)
- THEN with non-workflow commands (e.g., `/build`, `/coordinate`)
- Case-insensitive THEN parsing

## Research Summary

Brief synthesis of key findings from research reports:

- **State Machine Architecture**: The existing workflow-state-machine.sh provides 8 core states with validated transitions. Adding STATE_THEN_PENDING as a 9th state enables formal representation of queued commands (from Option B research).
- **State Persistence Pattern**: Commands use append_workflow_state() for cross-bash-block persistence, which provides the ideal mechanism for storing THEN_NEXT_COMMAND and THEN_NEXT_ARGS (from implementation research).
- **Argument Capture Pattern**: The two-step capture in argument-capture.sh with BASH_REMATCH regex matching provides the integration point for THEN parsing (from syntax research).
- **Completion Flow**: All four target commands (/research, /debug, /plan, /revise) have consistent sm_transition("$STATE_COMPLETE") completion points, enabling uniform THEN integration (from implementation research).

**Recommended approach**: Implement core state machine extensions first, then add THEN parsing to argument-capture.sh, followed by sequential command integration starting with /research as the pilot.

## Success Criteria

- [ ] STATE_THEN_PENDING state added to workflow-state-machine.sh
- [ ] sm_queue_then_command(), sm_has_queued_then(), sm_execute_queued_then() functions implemented
- [ ] State transitions extended to support then_pending from completion-capable states
- [ ] parse_then_syntax() function added to argument-capture.sh
- [ ] Checkpoint schema updated to v2.2 with then_command section
- [ ] /research command supports THEN syntax with proper artifact context passing
- [ ] /debug command supports THEN syntax with debug findings context
- [ ] /plan command supports THEN syntax with plan path context
- [ ] /revise command supports THEN syntax with revision context
- [ ] Unit tests pass for all new state machine functions
- [ ] Integration tests pass for /research THEN /plan workflow
- [ ] Error messages are clear and actionable for invalid THEN usage
- [ ] Backward compatibility verified (commands work without THEN)

## Technical Design

### Architecture Overview

```
User Input: /research "auth patterns" THEN /plan
                     |
                     v
        +------------------------+
        |  argument-capture.sh   |
        |  parse_then_syntax()   |
        +------------------------+
                     |
                     v
        +------------------------+
        |   /research command    |
        | sm_queue_then_command()|
        +------------------------+
                     |
                     v
        +------------------------+
        |  workflow-state-machine |
        |  STATE_THEN_PENDING    |
        +------------------------+
                     |
                     v
        +------------------------+
        |  THEN_EXECUTE signal   |
        |  + artifact context    |
        +------------------------+
```

### Component Interactions

1. **argument-capture.sh**: Parses THEN syntax from user input, extracts description and queued command
2. **workflow-state-machine.sh**: Stores queued command in state, manages STATE_THEN_PENDING transitions
3. **checkpoint-utils.sh**: Persists then_command data in checkpoint schema v2.2
4. **Individual commands**: Queue THEN command after sm_init(), check before completion transition

### Key Design Decisions

1. **Case-sensitive THEN**: Use all-caps THEN as visual delimiter to avoid ambiguity with common English word "then"
2. **State persistence**: Use existing append_workflow_state() pattern for THEN command storage (consistency)
3. **Validation at parse time**: Validate THEN target commands immediately during parse_then_syntax()
4. **THEN_EXECUTE signal**: Commands output signal for Claude to invoke queued command

### Artifact Context Contract

```json
{
  "topic_path": "/path/to/specs/NNN_topic",
  "research_dir": "/path/to/specs/NNN_topic/reports",
  "plan_path": "/path/to/specs/NNN_topic/plans/001_*.md",
  "report_count": 3,
  "previous_command": "/research",
  "workflow_id": "workflow_1731859200"
}
```

## Implementation Phases

### Phase 1: Core State Machine Extensions
dependencies: []

**Objective**: Add STATE_THEN_PENDING state and implement core queuing functions in workflow-state-machine.sh

**Complexity**: Medium

**Tasks**:
- [ ] Add STATE_THEN_PENDING constant after line 48 in workflow-state-machine.sh
- [ ] Extend STATE_TRANSITIONS to allow then_pending from research, plan, debug, document states
- [ ] Add [then_pending] entry to STATE_TRANSITIONS allowing transitions to research, debug, plan, revise
- [ ] Implement sm_queue_then_command() function with command validation
- [ ] Implement sm_has_queued_then() function to check queued state
- [ ] Implement sm_execute_queued_then() function to retrieve and clear queued command
- [ ] Implement sm_get_then_artifact_context() function to build context JSON
- [ ] Export all new functions at end of workflow-state-machine.sh
- [ ] Update library version to 2.1.0

**Testing**:
```bash
# Unit tests for new state machine functions
./run_all_tests.sh test_then_state_machine.sh
```

**Expected Duration**: 3 hours

---

### Phase 2: THEN Parsing in Argument Capture
dependencies: []

**Objective**: Add parse_then_syntax() function to argument-capture.sh for consistent THEN parsing across commands

**Complexity**: Low

**Tasks**:
- [ ] Add parse_then_syntax() function after line 205 in argument-capture.sh
- [ ] Implement BASH_REMATCH regex pattern: `(.+)[[:space:]]THEN[[:space:]]+(/?[a-z-]+)(.*)`
- [ ] Set PARSED_DESCRIPTION, THEN_COMMAND, THEN_ARGS variables
- [ ] Normalize command to ensure leading slash
- [ ] Add validation for THEN target commands (research|debug|plan|revise)
- [ ] Export function and variables
- [ ] Update library version to 1.1.0

**Testing**:
```bash
# Test parse_then_syntax() function
source .claude/lib/argument-capture.sh
parse_then_syntax 'auth patterns THEN /plan'
echo "Description: $PARSED_DESCRIPTION"  # auth patterns
echo "Command: $THEN_COMMAND"            # /plan
echo "Args: $THEN_ARGS"                  # (empty)

# Test with args
parse_then_syntax 'OAuth2 flows --complexity 3 THEN /plan --complexity 4'
echo "Args: $THEN_ARGS"                  # --complexity 4
```

**Expected Duration**: 2 hours

---

### Phase 3: Checkpoint Schema Update
dependencies: []

**Objective**: Update checkpoint schema to v2.2 with then_command section for persistence

**Complexity**: Medium

**Tasks**:
- [ ] Update CHECKPOINT_SCHEMA_VERSION to "2.2" in checkpoint-utils.sh line 25
- [ ] Add then_command section to checkpoint JSON structure in save_checkpoint()
- [ ] Include fields: next_command, next_args, queued, executed, artifact_context
- [ ] Add migration function migrate_v21_to_v22() in checkpoint-migration.sh
- [ ] Ensure migration adds default values for then_command fields
- [ ] Test migration with existing v2.1 checkpoints

**Testing**:
```bash
# Test checkpoint migration
./run_all_tests.sh test_checkpoint_migration.sh

# Manual verification
cat .claude/data/checkpoints/test_checkpoint.json | jq '.then_command'
```

**Expected Duration**: 2 hours

---

### Phase 4: Integrate with /research Command
dependencies: [1, 2]

**Objective**: Add THEN support to /research command as pilot implementation

**Complexity**: Medium

**Tasks**:
- [ ] Source argument-capture.sh in /research command Part 2 bash block
- [ ] Call parse_then_syntax() after reading FEATURE_DESCRIPTION
- [ ] Update FEATURE_DESCRIPTION with PARSED_DESCRIPTION
- [ ] Store PENDING_THEN_COMMAND and PENDING_THEN_ARGS if THEN present
- [ ] After sm_init(), call sm_queue_then_command() if PENDING_THEN_COMMAND set
- [ ] Before sm_transition("$STATE_COMPLETE"), check sm_has_queued_then()
- [ ] If queued, transition to STATE_THEN_PENDING instead of COMPLETE
- [ ] Get artifact context with sm_get_then_artifact_context()
- [ ] Output THEN_EXECUTE signal with command and context
- [ ] Verify backward compatibility (command works without THEN)

**Files to modify**:
- `/home/benjamin/.config/.claude/commands/research.md` (Part 2 after line 65, Part 4 before line 349)

**Testing**:
```bash
# Test THEN syntax
/research "auth patterns" THEN /plan
# Expected: Research completes, outputs THEN_EXECUTE: /plan

# Test backward compatibility
/research "auth patterns"
# Expected: Works as before, no THEN behavior
```

**Expected Duration**: 3 hours

---

### Phase 5: Integrate with /debug, /plan, /revise Commands
dependencies: [1, 2, 4]

**Objective**: Extend THEN support to remaining three commands following /research pattern

**Complexity**: Medium

**Tasks**:
- [ ] Integrate THEN parsing in /debug command (modify debug.md around lines 95, 550)
- [ ] Integrate THEN parsing in /plan command (modify plan.md around lines 115, 488)
- [ ] Integrate THEN parsing in /revise command (modify revise.md around lines 115, 484)
- [ ] Each command: Add parse_then_syntax() call after argument capture
- [ ] Each command: Add sm_queue_then_command() after sm_init()
- [ ] Each command: Add sm_has_queued_then() check before completion
- [ ] Each command: Output THEN_EXECUTE signal if queued
- [ ] Verify artifact context includes command-specific paths
- [ ] Test all four commands with THEN syntax

**Files to modify**:
- `/home/benjamin/.config/.claude/commands/debug.md`
- `/home/benjamin/.config/.claude/commands/plan.md`
- `/home/benjamin/.config/.claude/commands/revise.md`

**Testing**:
```bash
# Test each command
/debug "timeout errors" THEN /plan
/plan "auth system" THEN /revise "add MFA"
/revise "existing plan" THEN /debug "test failures"

# Verify artifact context passing
# Each command should output appropriate context for next command
```

**Expected Duration**: 4 hours

---

### Phase 6: Testing and Documentation
dependencies: [4, 5]

**Objective**: Create comprehensive test suite and update documentation

**Complexity**: Medium

**Tasks**:
- [ ] Create test_then_state_machine.sh in .claude/tests/
- [ ] Add unit tests for sm_queue_then_command() with valid/invalid commands
- [ ] Add unit tests for sm_has_queued_then() before/after queueing
- [ ] Add unit tests for sm_execute_queued_then() with/without queued command
- [ ] Add unit tests for state transitions involving then_pending
- [ ] Add unit tests for parse_then_syntax() with various inputs
- [ ] Add integration test for /research THEN /plan workflow
- [ ] Add integration test for /debug THEN /plan workflow
- [ ] Add error case tests for invalid THEN targets
- [ ] Add checkpoint migration tests
- [ ] Run full test suite and ensure all pass
- [ ] Update state-based-orchestration-overview.md with THEN documentation
- [ ] Add THEN artifact context contract documentation
- [ ] Update command-reference.md with THEN syntax examples

**Files to create**:
- `/home/benjamin/.config/.claude/tests/test_then_state_machine.sh`

**Files to update**:
- `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md`
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md`

**Testing**:
```bash
# Run all tests
./run_all_tests.sh

# Verify test count and coverage
echo "Expected: 20+ new tests for THEN functionality"
```

**Expected Duration**: 4 hours

---

## Testing Strategy

### Unit Testing

Test all new functions in isolation:
- State machine functions with mocked state
- THEN parsing with various input patterns
- Checkpoint migration with test fixtures

### Integration Testing

Test complete workflows:
- `/research "topic" THEN /plan` - Full chain with artifact passing
- Error cases - Invalid THEN targets, missing context
- Backward compatibility - Commands without THEN

### Test Isolation

Follow test isolation standards:
```bash
export CLAUDE_SPECS_ROOT="/tmp/test_then_$$"
export CLAUDE_PROJECT_DIR="/tmp/test_then_$$"
mkdir -p "$CLAUDE_SPECS_ROOT"
```

### Coverage Requirements

- 80% coverage on new code
- All public functions tested
- Error paths tested
- Migration paths tested

## Documentation Requirements

### Files to Update

1. **state-based-orchestration-overview.md**: Add THEN state and transitions documentation
2. **command-reference.md**: Add THEN syntax examples for all four commands
3. **argument-capture.sh header**: Document parse_then_syntax() function

### Documentation Standards

- No emojis in file content
- Follow CommonMark specification
- Include code examples with syntax highlighting
- Update version numbers in library headers

## Dependencies

### Internal Dependencies

- workflow-state-machine.sh (v2.0.0)
- argument-capture.sh (v1.0.0)
- state-persistence.sh (append_workflow_state)
- checkpoint-utils.sh (v2.1 schema)

### External Dependencies

- jq (JSON processing for artifact context)
- bash 4.0+ (for BASH_REMATCH, associative arrays)

### Prerequisites

- Existing state machine architecture operational
- All four target commands using sm_transition()
- Test framework in .claude/tests/

## Risk Mitigation

### Risk: State Machine Corruption

**Mitigation**: Validate THEN targets before queueing, restrict then_pending transitions to valid sources

### Risk: Artifact Context Loss

**Mitigation**: Persist context before transition, include all required paths, validate paths exist

### Risk: Backward Compatibility Break

**Mitigation**: THEN parsing only activates when delimiter present, existing workflows unchanged

### Risk: Checkpoint Incompatibility

**Mitigation**: Migration function adds defaults, extensive migration testing with fixtures

---

## Notes

- This plan uses Level 0 (single file) structure. If complexity increases during implementation, use `/expand` to create phase directories.
- Phase dependencies enable parallel execution: Phases 1-3 can run in parallel, Phase 4 requires 1+2, Phase 5 requires 1+2+4, Phase 6 requires 4+5.
- Estimated time savings with parallel execution: 40% (10.8 hours vs 18 hours sequential).
