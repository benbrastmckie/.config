# Debug Strategy: /research-plan Command Bash Execution Model Fix

## Metadata
- **Date**: 2025-11-17
- **Feature**: Fix /research-plan command bash syntax errors
- **Scope**: Refactor command to use Task-based execution model aligned with /fix and /build patterns
- **Estimated Phases**: 4
- **Estimated Hours**: 6-8
- **Structure Level**: 0
- **Complexity Score**: 72.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Root Cause Analysis: Bash Syntax Errors](../reports/001_root_cause_analysis.md)

## Overview

The /research-plan command fails with bash syntax errors when processing multi-line feature descriptions. The root cause is a fundamental misalignment between the command's implementation and Claude Code's bash block execution model. The command embeds complex multi-line bash code in markdown blocks, which Claude Code attempts to execute via `eval`, causing catastrophic variable substitution and escaping failures.

**Goals**:
1. Refactor /research-plan to use Task-based execution model (proven pattern from /fix and /build)
2. Remove complex bash blocks causing eval failures
3. Align command structure with working commands
4. Ensure multi-line feature descriptions execute without errors
5. Maintain state machine integration and workflow functionality

## Research Summary

Key findings from root cause analysis report:

**Problem Identification**:
- Bash blocks in /research-plan (lines 26-59, 63-174, 134-174, 195-239, 244-263) are treated as executable code
- Claude Code executes these via `eval`, causing multi-line code to collapse and variables to become malformed
- Multi-line feature descriptions with special characters ([]{}, paths, newlines) trigger escaping cascade
- Error pattern: `syntax error near unexpected token 'then'` and `syntax error near unexpected token 'do'`

**Working Pattern from /fix and /build**:
- Minimal bash blocks for argument parsing only (10-20 lines)
- Task blocks delegate all complex logic to subagents
- Simple variable passing via environment exports
- No multi-line control structures in bash blocks
- No complex state machine initialization in bash

**Architectural Insight**:
- Bash blocks = documentation that requires explicit execution
- Task blocks = actual execution mechanism for complex workflows
- Variable scope isolation between bash blocks requires state persistence utilities

**Recommended Approach**:
1. Reduce bash blocks to minimal argument parsing (Part 1)
2. Use Task block for state machine initialization and directory setup
3. Keep existing Task blocks for research and planning phases
4. Simplify verification blocks to single-line checks or Task delegation

## Success Criteria

- [ ] /research-plan executes successfully with simple feature descriptions
- [ ] /research-plan executes successfully with multi-line feature descriptions containing special characters
- [ ] /research-plan executes successfully with feature descriptions containing file paths
- [ ] No bash syntax errors in command output
- [ ] Research reports created in correct directory structure
- [ ] Implementation plan created based on research reports
- [ ] State machine transitions work correctly (init → research → plan → complete)
- [ ] All existing functionality preserved (complexity flags, auto-detection, checkpoints)
- [ ] Command aligns with /fix and /build architectural patterns
- [ ] Tests pass for command execution with various input types

## Technical Design

### Current Architecture (Broken)
```
/research-plan command structure:
├── Part 1: Argument parsing (bash block) ✓ Works
├── Part 2: State machine init (bash block) ✗ FAILS on multi-line input
│   ├── Project directory detection (complex while loop)
│   ├── Library sourcing
│   ├── sm_init call with variable substitution
│   └── Directory creation
├── Part 3: Research phase
│   ├── State transition (bash block) ✗ FAILS
│   ├── Directory setup (bash block)
│   └── Task block (research-specialist) ✓ Works
├── Part 4: Planning phase
│   ├── State transition (bash block) ✗ FAILS
│   ├── Plan path calculation (bash block)
│   └── Task block (plan-architect) ✓ Works
└── Part 5: Completion (bash block) ✗ FAILS
```

### Target Architecture (Fixed)
```
/research-plan command structure:
├── Part 1: Minimal argument parsing (bash block) ✓ Simple, safe
├── Part 2: Initialization Task (NEW)
│   ├── Project directory detection
│   ├── Library sourcing
│   ├── State machine initialization
│   └── Directory creation
├── Part 3: Research phase
│   ├── Minimal state transition (bash block or Task)
│   └── Task block (research-specialist) ✓ Existing
├── Part 4: Planning phase
│   ├── Minimal state transition (bash block or Task)
│   └── Task block (plan-architect) ✓ Existing
└── Part 5: Completion Task (NEW)
    ├── State transition to complete
    └── Completion summary output
```

**Key Changes**:
1. Extract state machine initialization from bash block → Task block
2. Simplify state transitions to single-line calls or Task delegation
3. Move directory setup logic to initialization Task
4. Preserve existing Task blocks (research, planning)
5. Use working patterns from /fix command (reference implementation)

### Component Interactions

```
User Input → Part 1 (bash) → Part 2 (Task) → Part 3 (Task) → Part 4 (Task) → Part 5 (Task)
              ↓                  ↓              ↓              ↓              ↓
         Parse args        Initialize SM    Research        Plan         Complete
         Export vars       Setup dirs       Create reports  Create plan  Cleanup
```

**Data Flow**:
- Part 1: Capture FEATURE_DESCRIPTION, RESEARCH_COMPLEXITY (bash variables)
- Part 2: Initialize state machine, persist SPECS_DIR, RESEARCH_DIR, PLANS_DIR
- Part 3: Load state, execute research, persist REPORT_COUNT
- Part 4: Load state, execute planning, persist PLAN_PATH
- Part 5: Load state, finalize workflow, output summary

## Implementation Phases

### Phase 1: Create Backup and Setup Test Environment
dependencies: []

**Objective**: Prepare safe testing environment and create command backup
**Complexity**: Low

Tasks:
- [ ] Create backup of current /research-plan command (file: .claude/commands/research-plan.md)
- [ ] Copy to .claude/commands/research-plan.md.backup with timestamp
- [ ] Create test feature descriptions file with edge cases (file: .claude/specs/26_*/test_inputs.txt)
- [ ] Document test cases: simple, multi-line, special chars, file paths
- [ ] Set up test execution script for automated validation

Testing:
```bash
# Verify backup created
ls -la .claude/commands/research-plan.md.backup

# Verify test inputs file created
cat .claude/specs/26_*/test_inputs.txt
```

**Expected Duration**: 0.5 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(026): complete Phase 1 - Create Backup and Setup Test Environment`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Refactor Part 1 (Argument Parsing) to Minimal Pattern
dependencies: [1]

**Objective**: Simplify argument parsing to match /fix command pattern
**Complexity**: Low

Tasks:
- [ ] Review /fix command Part 1 (lines 26-54) as reference pattern (file: .claude/commands/fix.md)
- [ ] Reduce /research-plan Part 1 to essential argument parsing only
- [ ] Keep: FEATURE_DESCRIPTION capture, --complexity flag parsing, validation
- [ ] Remove: Any complex control flow, multi-line blocks
- [ ] Export variables for Task block access: FEATURE_DESCRIPTION, RESEARCH_COMPLEXITY
- [ ] Add echo statements for workflow header (simple output only)
- [ ] Verify regex patterns are properly escaped (no eval issues)

Testing:
```bash
# Test simple argument parsing
/research-plan "simple test"

# Test complexity flag parsing
/research-plan "test --complexity 3"

# Verify variables exported correctly (check command output)
```

**Expected Duration**: 1 hour

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(026): complete Phase 2 - Refactor Part 1 (Argument Parsing) to Minimal Pattern`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Create Part 2 Initialization Task Block
dependencies: [2]

**Objective**: Extract state machine initialization to Task block following /fix pattern
**Complexity**: High

Tasks:
- [ ] Create new Task block for initialization (insert after Part 1 bash block)
- [ ] Set subagent_type to "general-purpose"
- [ ] Move project directory detection logic to Task prompt
- [ ] Move library sourcing logic to Task prompt (state-persistence.sh, workflow-state-machine.sh, etc.)
- [ ] Move sm_init call to Task with proper variable interpolation
- [ ] Move directory creation (SPECS_DIR, RESEARCH_DIR, PLANS_DIR) to Task
- [ ] Use append_workflow_state for variable persistence (as in original)
- [ ] Add diagnostic echo statements for debugging
- [ ] Ensure Task returns success signal: INIT_COMPLETE: ${SPECS_DIR}

**Task Block Template** (reference from /fix):
```
Task {
  subagent_type: "general-purpose"
  description: "Initialize research-plan workflow state machine"
  prompt: |
    Initialize state machine for research-plan workflow.

    Input:
    - Feature Description: $FEATURE_DESCRIPTION
    - Research Complexity: $RESEARCH_COMPLEXITY
    - Command Name: research-plan
    - Workflow Type: research-and-plan

    Steps:
    1. Detect CLAUDE_PROJECT_DIR using git or .claude/ directory search
    2. Source required libraries (state-persistence.sh, workflow-state-machine.sh, etc.)
    3. Verify library versions (workflow-state-machine.sh >=2.0.0)
    4. Initialize state machine with sm_init
    5. Create specs directory structure
    6. Persist variables using append_workflow_state

    Return completion signal:
    INIT_COMPLETE: ${SPECS_DIR}
}
```

Testing:
```bash
# Test initialization with simple description
/research-plan "test feature"

# Verify SPECS_DIR created
ls -la .claude/specs/

# Verify state machine initialized (check for state file)
ls -la ~/.claude/data/state/
```

**Expected Duration**: 2-3 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(026): complete Phase 3 - Create Part 2 Initialization Task Block`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Simplify State Transitions and Verification Blocks
dependencies: [3]

**Objective**: Reduce bash complexity in Parts 3-5 (research, planning, completion phases)
**Complexity**: Medium

Tasks:
- [ ] Review Part 3 (Research phase) bash blocks (lines 134-174, 195-239)
- [ ] Simplify state transition to single sm_transition call (no complex error handling in bash)
- [ ] Move verification logic to Task block or reduce to file existence checks only
- [ ] Keep CHECKPOINT reporting (simple echo statements)
- [ ] Review Part 4 (Planning phase) bash blocks (lines 244-263, 297-333)
- [ ] Apply same simplification pattern to planning phase
- [ ] Review Part 5 (Completion) bash block (lines 337-373)
- [ ] Simplify to state transition + summary output only
- [ ] Remove complex multi-line diagnostic blocks (move to Task if needed)
- [ ] Ensure all bash blocks are <30 lines and single-purpose

**Simplification Pattern**:
```bash
# Before (complex):
if ! sm_transition "$STATE_RESEARCH" 2>&1; then
  echo "ERROR: State transition to RESEARCH failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  # ... 15 lines of diagnostics ...
  exit 1
fi

# After (simple):
sm_transition "$STATE_RESEARCH" || { echo "ERROR: State transition to RESEARCH failed"; exit 1; }
```

Testing:
```bash
# Test full workflow with simple input
/research-plan "simple feature test"

# Test full workflow with multi-line input
/research-plan "multi-line feature
with special chars: []{}
and paths: /home/test/file.txt"

# Verify all phases complete successfully
ls -la .claude/specs/*/reports/
ls -la .claude/specs/*/plans/
```

**Expected Duration**: 2-3 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(026): complete Phase 4 - Simplify State Transitions and Verification Blocks`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing (Per Phase)
- Phase 1: Verify backup created, test inputs documented
- Phase 2: Test argument parsing with various input patterns
- Phase 3: Test state machine initialization in isolation
- Phase 4: Test each workflow phase independently

### Integration Testing (End-to-End)
After all phases complete:

**Test Suite**:
1. **Simple Feature Description**:
   - Input: `"implement user authentication"`
   - Expected: Reports created, plan created, no errors

2. **Multi-line Feature Description**:
   - Input: `"implement feature\nwith multiple lines\nand details"`
   - Expected: Reports created, plan created, no bash syntax errors

3. **Special Characters**:
   - Input: `"fix issues with brackets [] braces {} and parentheses ()"`
   - Expected: No escaping errors, successful execution

4. **File Paths**:
   - Input: `"refactor /home/user/project/src/auth.lua and /home/user/project/tests/auth_spec.lua"`
   - Expected: Paths preserved correctly, no path parsing errors

5. **Complexity Flag**:
   - Input: `"research topic --complexity 4"`
   - Expected: Complexity parsed correctly, flag removed from description

6. **Edge Case: Very Long Description (>200 chars)**:
   - Input: Long feature description with multiple sentences
   - Expected: No truncation, successful execution

### Regression Testing
- Verify /fix command still works (no unintended changes)
- Verify /build command still works (no unintended changes)
- Verify state machine persistence across bash block boundaries

### Success Metrics
- All 6 integration tests pass without bash syntax errors
- Command executes in <5 minutes for complexity 3
- Research reports contain >1000 bytes (comprehensive)
- Implementation plan contains >2000 bytes (detailed)
- Zero eval errors in command output

## Documentation Requirements

### Command Documentation
- [ ] Update .claude/commands/research-plan.md header with refactor notes
- [ ] Add "Architectural Changes" section documenting Task-based execution model
- [ ] Update troubleshooting section with new error patterns (if any)

### Research Report Updates
- [ ] Update root cause analysis report with "Implementation Status" section
- [ ] Link to this debug strategy plan (bidirectional linking)
- [ ] Mark report status as "Fix In Progress"

### Standards Documentation
- [ ] Document bash block best practices in .claude/docs/ (if not already documented)
- [ ] Add example of Task-based execution model pattern
- [ ] Reference this fix as case study for command refactoring

### CLAUDE.md Updates (if needed)
- [ ] No updates required (existing standards already support this pattern)

## Dependencies

### External Dependencies
- None (all refactoring uses existing utilities and patterns)

### Internal Dependencies
- state-persistence.sh (>=1.5.0) - already required
- workflow-state-machine.sh (>=2.0.0) - already required
- Existing /fix and /build commands as reference implementations

### Library Requirements
- No new library requirements
- Existing library versions sufficient

## Risk Management

### Technical Risks

**Risk 1: Task block variable scoping differs from bash blocks**
- **Mitigation**: Use append_workflow_state and load_workflow_state utilities (proven pattern)
- **Fallback**: Explicit environment variable exports in bash before Task blocks

**Risk 2: State machine initialization in Task may not persist correctly**
- **Mitigation**: Follow exact pattern from /fix command (lines 58-122)
- **Testing**: Verify state file created in ~/.claude/data/state/ after init

**Risk 3: Multi-line feature descriptions may still cause issues in Task prompt interpolation**
- **Mitigation**: Use heredoc syntax for Task prompts (proven safe for multi-line strings)
- **Testing**: Dedicated test case with newlines, special chars, quotes

### Implementation Risks

**Risk 4: Refactoring may break existing workflows mid-execution**
- **Mitigation**: Create backup, implement changes incrementally, commit after each phase
- **Rollback**: Restore from .claude/commands/research-plan.md.backup if critical failure

**Risk 5: Testing may not cover all edge cases**
- **Mitigation**: Comprehensive test suite (6 integration tests) covering known failure modes
- **Monitoring**: Watch for new error patterns in real-world usage post-deployment

## Rollback Procedure

If critical failures occur:

1. **Immediate Rollback**:
   ```bash
   cp .claude/commands/research-plan.md.backup .claude/commands/research-plan.md
   ```

2. **Verify Rollback**:
   ```bash
   /research-plan "simple test"
   ```

3. **Document Failure**:
   - Create new debug report in .claude/specs/26_*/debug/
   - Capture error output
   - Identify which phase caused the issue

4. **Incremental Fix**:
   - Fix identified issue in isolation
   - Re-test before applying to full command

## Notes

- This refactor follows the "clean-break" philosophy from CLAUDE.md writing standards
- No historical commentary will be added to the refactored command file
- The backup file serves as historical reference if needed
- All changes align with existing architectural patterns (no new patterns introduced)
- Success depends on strict adherence to Task-based execution model proven in /fix and /build

## Appendix: Reference Implementations

### /fix Command Part 2 (Bash Block Pattern)
See /home/benjamin/.config/.claude/commands/fix.md lines 58-122

### /build Command Part 1 (Argument Parsing Pattern)
See /home/benjamin/.config/.claude/commands/build.md lines 26-148

### Working Task Block Example (from /fix)
See /home/benjamin/.config/.claude/commands/fix.md lines 159-177
