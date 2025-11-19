# Comprehensive Output Formatting Refactor Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: Output Formatting Refactor (Options A, B, C Combined)
- **Scope**: Block consolidation, output suppression, and state persistence standardization across workflow commands
- **Estimated Phases**: 5
- **Estimated Hours**: 12-16
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 48
- **Research Reports**:
  - [State Machine Option Compatibility](../reports/001_state_machine_option_compatibility.md)
  - [Output Formatting Revised](../../773_build_command_is_working_great_yielding_sample_out/reports/002_output_formatting_revised.md)

## Overview

This plan implements a comprehensive clean-break refactor that combines three complementary approaches to reduce output noise in workflow commands:

- **Option A**: Block consolidation - reduce bash blocks from 6-11 to 2-3 per command
- **Option B**: Output suppression - redirect intermediate output, single summary lines
- **Option C**: Leverage existing state-persistence.sh infrastructure (already implemented)

The state machine infrastructure (`state-persistence.sh` and `workflow-state-machine.sh`) already provides superior context-based variable persistence. This refactor focuses on consistent adoption and structural improvements that reduce Claude Code display noise by 70%+.

## Research Summary

Key findings from research reports:

**From State Machine Option Compatibility Report**:
- state-persistence.sh provides `init_workflow_state()`, `load_workflow_state()`, and `append_workflow_state()` with proper escaping and 67% faster operations
- coordinate.md has 40+ append_workflow_state calls, proving mature adoption
- Option C (context-based persistence) is already fully implemented - focus on consistent usage

**From Output Formatting Revised Report**:
- Core problem is architectural: too many bash blocks, each displaying truncated content
- Cannot change Claude Code display behavior - must reduce block count
- Option B output suppression can be applied incrementally with minimal risk
- Option A block consolidation provides 67% reduction (6 blocks to 2)

Recommended approach: Progressive consolidation (Option D from report) - apply Options B and C first, then Option A for highest-value commands.

## Success Criteria
- [ ] All workflow commands use state-persistence.sh consistently (init/load/append pattern)
- [ ] Block count reduced by 50%+ for primary commands (research, build, plan)
- [ ] Output noise reduced by 50%+ via suppression patterns
- [ ] Zero regressions in workflow functionality
- [ ] All commands pass existing test suites
- [ ] Create workflow-init.sh consolidation library
- [ ] Document standardized patterns for future commands

## Technical Design

### Architecture Overview

The refactor introduces a unified initialization pattern via `workflow-init.sh` that consolidates:
1. Project directory detection (CLAUDE_PROJECT_DIR)
2. Library sourcing (state-persistence.sh, workflow-state-machine.sh)
3. State machine initialization
4. State file creation with cleanup traps

```
workflow-init.sh
├── init_workflow() - One-time initialization (Block 1)
│   ├── Detect CLAUDE_PROJECT_DIR (cached)
│   ├── Source required libraries (suppressed)
│   ├── Initialize state machine
│   └── Create state file with trap cleanup
└── load_workflow_context() - Load state (Block 2+)
    └── Source state file if exists
```

### Block Consolidation Pattern

**Before** (6 blocks):
```
Block 1: Capture arguments
Block 2: Validate arguments
Block 3: Initialize state machine
Block 4: Allocate topic directory
Block 5: Verify artifacts
Block 6: Complete workflow
```

**After** (2-3 blocks):
```
Block 1: Setup (capture, validate, init, allocate)
Block 2: Execute (main workflow logic)
Block 3: Cleanup (verify, complete)
```

### Output Suppression Pattern

```bash
# Suppress library sourcing
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh" 2>/dev/null

# Redirect diagnostics to log file
DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"
if ! operation; then
  echo "ERROR: Operation failed (see $DEBUG_LOG)" >&2
  echo "[$(date)] Details..." >> "$DEBUG_LOG"
  exit 1
fi

# Single summary line per block
echo "Setup complete: $WORKFLOW_ID"
```

### State Persistence Standardization

All commands must follow this pattern:

```bash
# Block 1: Initialize
WORKFLOW_ID="command_$(date +%s)"
init_workflow_state "$WORKFLOW_ID"
sm_init "$description" "$command" "$workflow_type" "$complexity" "[]"

# Block 2+: Load
load_workflow_state "$WORKFLOW_ID" false

# Append state as needed
append_workflow_state "KEY" "value"
```

## Implementation Phases

### Phase 1: Create workflow-init.sh Library
**Dependencies**: []

**Objective**: Create centralized initialization library to reduce boilerplate and consolidate common setup patterns.

**Complexity**: Medium
**Estimated Time**: 2-3 hours

**Tasks**:
- [ ] Create `/home/benjamin/.config/.claude/lib/workflow-init.sh` library file
- [ ] Implement `init_workflow()` function that handles:
  - CLAUDE_PROJECT_DIR detection (cached)
  - Library sourcing (state-persistence.sh, workflow-state-machine.sh)
  - State machine initialization via sm_init
  - State file creation with EXIT trap cleanup
- [ ] Implement `load_workflow_context()` function for subsequent blocks
- [ ] Add output suppression to all library sourcing (2>/dev/null)
- [ ] Add error handling with debug log output pattern
- [ ] Export WORKFLOW_ID, STATE_FILE, CLAUDE_PROJECT_DIR
- [ ] Write unit tests for workflow-init.sh functions

**Testing**:
```bash
# Test initialization
source .claude/lib/workflow-init.sh
result=$(init_workflow "test" "Test description")
[ -n "$WORKFLOW_ID" ] || echo "FAIL: WORKFLOW_ID not set"
[ -f "$STATE_FILE" ] || echo "FAIL: STATE_FILE not created"

# Run unit tests
.claude/tests/test_workflow_init.sh
```

---

### Phase 2: Audit and Standardize State Persistence Usage
**Dependencies**: [1]

**Objective**: Ensure all workflow commands use state-persistence.sh consistently with proper init/load/append patterns.

**Complexity**: Low
**Estimated Time**: 2-3 hours

**Tasks**:
- [ ] Audit `/home/benjamin/.config/.claude/commands/research.md` for state persistence usage
- [ ] Audit `/home/benjamin/.config/.claude/commands/build.md` for state persistence usage
- [ ] Audit `/home/benjamin/.config/.claude/commands/plan.md` for state persistence usage
- [ ] Audit `/home/benjamin/.config/.claude/commands/debug.md` for state persistence usage
- [ ] Create audit report documenting current state persistence patterns per command
- [ ] Identify any commands using ad-hoc context persistence (non-standard patterns)
- [ ] Update commands to use workflow-init.sh where beneficial
- [ ] Ensure init_workflow_state is called BEFORE sm_init in all commands
- [ ] Verify STATE_FILE is properly set before any append_workflow_state calls

**Testing**:
```bash
# Verify each command initializes state correctly
grep -n "init_workflow_state\|load_workflow_state\|append_workflow_state" .claude/commands/*.md

# Run each command with trace to verify state file creation
bash -x .claude/commands/research.md "test topic" 2>&1 | grep STATE_FILE
```

---

### Phase 3: Apply Output Suppression (Option B)
**Dependencies**: [1]

**Objective**: Reduce stdout noise by 50% via systematic output suppression across all workflow commands.

**Complexity**: Low
**Estimated Time**: 2-3 hours

**Tasks**:
- [ ] Add `2>/dev/null` to all `source` commands for library loading in research.md
- [ ] Add `2>/dev/null` to all `source` commands for library loading in build.md
- [ ] Add `2>/dev/null` to all `source` commands for library loading in plan.md
- [ ] Add `2>/dev/null` to all `source` commands for library loading in debug.md
- [ ] Replace verbose DIAGNOSTIC/POSSIBLE CAUSES/TROUBLESHOOTING blocks with single error line + log file
- [ ] Create debug log pattern: `DEBUG_LOG="${HOME}/.claude/tmp/workflow_debug.log"`
- [ ] Add single summary line at end of each bash block (e.g., "Setup complete")
- [ ] Redirect `mkdir -p` operations to suppress success output
- [ ] Test that errors still visible on stderr while normal output suppressed

**Testing**:
```bash
# Count output lines before/after
/research "test topic" 2>&1 | wc -l
# Target: 50% reduction in line count

# Verify errors still visible
/research "invalid/path" 2>&1 | grep -i error
# Should show error message
```

---

### Phase 4: Block Consolidation Pilot - /research Command
**Dependencies**: [2, 3]

**Objective**: Consolidate /research command from 6 blocks to 2-3 blocks as pilot implementation.

**Complexity**: High
**Estimated Time**: 3-4 hours

**Tasks**:
- [ ] Document current block structure of /home/benjamin/.config/.claude/commands/research.md
- [ ] Design consolidated block structure:
  - Block 1: Setup (capture args, validate, source libraries, init state machine, allocate topic)
  - Block 2: Execute (invoke research agents, handle results)
  - Block 3: Cleanup (verify artifacts, complete workflow)
- [ ] Refactor research.md to use workflow-init.sh for Block 1 setup
- [ ] Consolidate argument capture and validation into Block 1
- [ ] Consolidate topic allocation and state initialization into Block 1
- [ ] Ensure proper variable export between blocks via state file
- [ ] Preserve all existing functionality during consolidation
- [ ] Add context file persistence pattern for variables needed across blocks
- [ ] Test complete workflow: `/research "authentication patterns"`

**Testing**:
```bash
# Count bash blocks before/after
grep -c '```bash' .claude/commands/research.md
# Target: 3 blocks (down from 6+)

# Full workflow test
/research "test authentication patterns"
# Verify: reports created, state file cleaned up

# Regression test
.claude/tests/test_research_command.sh
```

---

### Phase 5: Apply Block Consolidation to Primary Commands
**Dependencies**: [4]

**Objective**: Apply proven consolidation patterns from /research pilot to /build and /plan commands.

**Complexity**: High
**Estimated Time**: 4-5 hours

**Tasks**:
- [ ] Apply workflow-init.sh pattern to /home/benjamin/.config/.claude/commands/build.md
- [ ] Consolidate build.md blocks following research.md pattern
- [ ] Apply workflow-init.sh pattern to /home/benjamin/.config/.claude/commands/plan.md
- [ ] Consolidate plan.md blocks following research.md pattern
- [ ] Update any command-specific initialization logic to work with workflow-init.sh
- [ ] Ensure all consolidated commands maintain proper state persistence across blocks
- [ ] Test build command: `/build <test-plan>`
- [ ] Test plan command: `/plan "test feature"`
- [ ] Document lessons learned and patterns for future consolidation
- [ ] Update command architecture documentation with consolidation patterns
- [ ] NOTE: Leave /coordinate command for future phase (1,800+ lines, most complex)

**Testing**:
```bash
# Block count verification
grep -c '```bash' .claude/commands/build.md
grep -c '```bash' .claude/commands/plan.md
# Target: 3-4 blocks each

# Full workflow tests
/build <test-plan-path>
/plan "test feature description"

# Regression tests
.claude/tests/test_build_command.sh
.claude/tests/test_plan_command.sh
```

---

## Testing Strategy

### Overall Approach

1. **Unit Tests**: Test workflow-init.sh library functions in isolation
2. **Integration Tests**: Test each command's full workflow
3. **Regression Tests**: Run existing test suites to verify no regressions
4. **Output Verification**: Measure block count and line count reduction

### Test Commands
```bash
# Unit tests
.claude/tests/test_workflow_init.sh

# Integration tests
.claude/tests/test_research_command.sh
.claude/tests/test_build_command.sh
.claude/tests/test_plan_command.sh
.claude/tests/test_debug_command.sh

# Full suite
.claude/tests/run_all_tests.sh
```

### Success Metrics
- All existing tests pass (0 regressions)
- Block count reduced by 50%+ (target: 6 -> 3)
- Output line count reduced by 50%+ (measure before/after)
- State persistence patterns consistent across all commands

## Documentation Requirements

- [ ] Update `/home/benjamin/.config/.claude/docs/reference/library-api.md` with workflow-init.sh API
- [ ] Add workflow-init.sh usage examples to command documentation
- [ ] Document output suppression patterns in code-standards.md
- [ ] Update state-based-orchestration-overview.md with consolidation patterns
- [ ] Create troubleshooting guide for common consolidation issues

## Dependencies

### External Dependencies
- Existing state-persistence.sh library (fully implemented)
- Existing workflow-state-machine.sh library (fully implemented)
- Bash 4.0+ (for associative arrays if needed)

### Prerequisites
- Research reports reviewed and understood
- Current command behavior documented
- Test suites running and passing

### Phase Dependencies for Wave-Based Execution

```
Wave 1: Phase 1 (workflow-init.sh library)
Wave 2: Phases 2, 3 (parallel - audit and suppression are independent)
Wave 3: Phase 4 (research pilot - requires audit and suppression complete)
Wave 4: Phase 5 (apply to other commands - requires pilot complete)
```

**Time Savings**: With wave-based execution, Phases 2 and 3 can run in parallel (40% time savings for that wave).

## Risks and Mitigations

### Risk 1: Breaking Existing Functionality
**Mitigation**: Run full test suite after each phase. Keep original commands backed up.

### Risk 2: State File Issues Across Blocks
**Mitigation**: Use proven state-persistence.sh patterns. Ensure init before sm_init.

### Risk 3: Output Suppression Hiding Errors
**Mitigation**: Only suppress to /dev/null for success output. Keep stderr visible.

### Risk 4: Consolidation Creates Overly Complex Blocks
**Mitigation**: Target 50-100 lines per block. Split if blocks become unwieldy.

## Notes

**Why Not Option C Implementation**: The state-persistence.sh library already provides superior functionality to the Option C proposal in the output formatting report. Focus is on consistent adoption, not new infrastructure.

**Future Work**: The /coordinate command (1,800+ lines) is intentionally excluded from this plan due to its complexity. It should be addressed in a separate plan after patterns are proven on simpler commands.

**Expansion Hint**: This plan has complexity score 48, approaching Tier 2 threshold. If phases prove more complex during implementation, use `/expand-phase` to extract detailed task files.
