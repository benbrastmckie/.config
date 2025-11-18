# Output Formatting Improvements Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: Output Formatting Improvements (Options 3 + 5 Combined)
- **Scope**: Refactor bash block descriptions and implement level-aware output functions across workflow commands
- **Estimated Phases**: 6
- **Estimated Hours**: 10-14
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 57.5
- **Research Reports**:
  - [Output Formatting Improvements](../reports/001_output_formatting_improvements.md)

## Overview

This plan implements a combination of Option 3 (Progressive Output Levels) and Option 5 (Command Description Refactor) from the research report to dramatically reduce output noise while maintaining debuggability. The primary goals are:

1. **Option 5**: Refactor bash block descriptions from code snippets to meaningful summaries
2. **Option 3**: Implement level-aware output functions (emit_status, emit_detail, emit_debug)
3. Extract project directory detection to cached library function
4. Default to emit_status level only
5. Target 85%+ output reduction

**Key Focus Areas** (from user requirements):
- Brief meaningful status updates
- No repetitive comments or ugly truncated output
- Remove excessive headers
- Simplicity and clarity paramount

**NOTE**: This refactor may break some standards in .claude/docs/ - we will update these after refactor works error-free.

## Research Summary

Key findings from the output formatting research report:

- **Issue 1**: Repetitive `set +H` comment headers across 7 bash blocks in build.md create visual noise
- **Issue 2**: Redundant 12-line project directory detection code repeated 8+ times adds 100+ lines of redundant output
- **Issue 3**: Verbose diagnostic output (DIAGNOSTIC Information, POSSIBLE CAUSES, TROUBLESHOOTING) is excessive for normal operation
- **Issue 4**: Claude Code truncates bash output with "+ N more lines", making key information invisible
- **Issue 5**: Build.md uses raw echo statements instead of existing unified-logger infrastructure

**Recommended approach**: Combine Option 5 (refactor bash block descriptions to meaningful summaries) with Option 3 (implement emit_status/emit_detail/emit_debug level-aware output). This achieves 85%+ output reduction while maintaining full debuggability through the existing unified-logger.sh infrastructure.

**CRITICAL NOTE from research**: The user wants stack traces for all errors and would like to see them in full if possible. Truncated diagnostic output should still show full error details.

## Success Criteria
- [ ] Output reduced by 85%+ compared to current verbose output
- [ ] All bash blocks in /build show meaningful descriptions in Claude Code display (not code snippets)
- [ ] Project directory detection executed once per workflow (not per bash block)
- [ ] Level-aware output functions available: emit_status, emit_detail, emit_debug
- [ ] Default output level is emit_status (minimal but complete information)
- [ ] Full error stack traces preserved when errors occur
- [ ] /research command refactored successfully without errors (pilot test)
- [ ] /build command refactored successfully without errors
- [ ] Remaining workflow commands refactored (/coordinate, /plan, /debug)
- [ ] All tests pass after refactor

## Technical Design

### Architecture Overview

```
+-------------------+     +-------------------+     +-------------------+
| workflow-commands |     | output-utils.sh   |     | unified-logger.sh |
|   (build.md,      |---->| - emit_status()   |---->| - emit_progress() |
|    research.md)   |     | - emit_detail()   |     | - log functions   |
|                   |     | - emit_debug()    |     |                   |
+-------------------+     | - detect_project()|     +-------------------+
                          +-------------------+
                                    |
                          +-------------------+
                          | CLAUDE_PROJECT_DIR|
                          | cached detection  |
                          +-------------------+
```

### Component Design

#### 1. New Library: output-utils.sh

Create a new library that provides:

1. **emit_status(message)**: Always shown - phase transitions, completion status
2. **emit_detail(message)**: Shown with DEBUG=1 - state machine info, intermediate steps
3. **emit_debug(message)**: Shown with DEBUG=2 - full diagnostics, verbose error info
4. **detect_project_dir()**: Cached project directory detection (run once, return cached)

#### 2. Bash Block Description Pattern

Transform bash blocks from:
```bash
set +H  # CRITICAL: Disable history expansion
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
# ... 50 lines of code
```

To:
```bash
# Description: Initialize build workflow state
# ... actual code (no leading comments)
```

The first comment line becomes the description shown in Claude Code display.

#### 3. Error Handling Pattern

Keep full diagnostic information but structure it for emit_debug level:
```bash
if ! sm_transition "$STATE_IMPLEMENT"; then
  emit_status "ERROR: State transition to IMPLEMENT failed"
  emit_debug "Current State: $(sm_current_state 2>/dev/null || echo 'unknown')"
  emit_debug "Attempted Transition: -> IMPLEMENT"
  emit_debug "Possible causes:"
  emit_debug "  - State machine not initialized properly"
  emit_debug "  - Invalid transition from current state"
  exit 1
fi
```

### Key Design Decisions

1. **Single library file**: output-utils.sh consolidates all output formatting (not multiple libraries)
2. **Cached detection**: detect_project_dir() uses file-based caching (consistent with state-persistence.sh patterns)
3. **No flags**: Default to emit_status level only (per user requirement to avoid flags)
4. **Environment variable control**: DEBUG=1 for details, DEBUG=2 for debug (optional, for troubleshooting)
5. **Pilot with /research**: Test refactor on one command first before rolling out

## Implementation Phases

### Phase 1: Create Output Utilities Library
dependencies: []

**Objective**: Create output-utils.sh with level-aware output functions and cached project detection

**Complexity**: Medium
**Expected Duration**: 2 hours

Tasks:
- [ ] Create /home/benjamin/.config/.claude/lib/output-utils.sh
- [ ] Implement emit_status() function - always outputs to stdout
- [ ] Implement emit_detail() function - outputs only when DEBUG>=1
- [ ] Implement emit_debug() function - outputs only when DEBUG>=2
- [ ] Implement detect_project_dir() with caching (use STATE_FILE pattern)
- [ ] Add source guard to prevent duplicate sourcing
- [ ] Add function exports for use in other scripts
- [ ] Add library version constant (OUTPUT_UTILS_VERSION="1.0.0")
- [ ] Document usage patterns in library header comments

Testing:
```bash
# Test output levels
source .claude/lib/output-utils.sh
emit_status "This should always show"
DEBUG=1 emit_detail "This should show with DEBUG=1"
DEBUG=2 emit_debug "This should show with DEBUG=2"

# Test cached detection
detect_project_dir  # Should cache
detect_project_dir  # Should return cached value
```

### Phase 2: Pilot Test with /research Command
dependencies: [1]

**Objective**: Refactor /research command as pilot to validate approach before broader rollout

**Complexity**: Medium
**Expected Duration**: 2-3 hours

**Rationale**: The user's NOTE in the research report suggests testing on /research first to confirm errors are not created before rolling out to other commands.

Tasks:
- [ ] Read current /research.md to identify all bash blocks (file: /home/benjamin/.config/.claude/commands/research.md)
- [ ] Source output-utils.sh in first bash block after state-persistence.sh
- [ ] Replace Part 1 bash block description: "set +H # CRITICAL..." -> "# Description: Capture research workflow arguments"
- [ ] Replace Part 2 bash block description with "# Description: Read and validate workflow description"
- [ ] Replace Part 3 first bash block description with "# Description: Initialize state machine for research workflow"
- [ ] Replace Part 3 second bash block description with "# Description: Allocate topic directory for research"
- [ ] Replace Part 3 third bash block description with "# Description: Verify research artifacts"
- [ ] Replace Part 4 bash block description with "# Description: Complete research workflow"
- [ ] Replace project directory detection blocks with detect_project_dir() call
- [ ] Replace echo "===" headers with emit_status() calls
- [ ] Replace echo "CHECKPOINT:" blocks with emit_status() calls
- [ ] Replace echo "DIAGNOSTIC Information:" blocks with emit_debug() calls
- [ ] Replace echo "POSSIBLE CAUSES:" blocks with emit_debug() calls
- [ ] Replace echo "TROUBLESHOOTING:" blocks with emit_debug() calls
- [ ] Keep error messages with emit_status() for visibility
- [ ] Test /research with a simple workflow description

Testing:
```bash
# Execute /research command and verify:
# 1. Output is significantly reduced (only status updates visible)
# 2. No errors during execution
# 3. Research report is still created successfully
# 4. With DEBUG=1, detail output is visible
# 5. With DEBUG=2, full diagnostic output is visible
/research "test output formatting improvements"
```

### Phase 3: Refactor /build Command
dependencies: [2]

**Objective**: Apply proven pattern from /research to the primary /build command

**Complexity**: High
**Expected Duration**: 3-4 hours

Tasks:
- [ ] Read current /build.md to identify all 7 bash blocks (file: /home/benjamin/.config/.claude/commands/build.md)
- [ ] Source output-utils.sh in Part 2 bash block after state-persistence.sh
- [ ] Part 1 bash block: Change description to "# Description: Capture build workflow arguments"
- [ ] Part 2 bash block: Change description to "# Description: Read arguments and discover plan file"
- [ ] Part 3 bash block: Change description to "# Description: Initialize state machine for build workflow"
- [ ] Part 4 first bash block: Change description to "# Description: Transition to implementation state"
- [ ] Part 4 second bash block: Change description to "# Description: Verify implementation completion"
- [ ] Part 5 bash block: Change description to "# Description: Run tests and capture results"
- [ ] Part 6 first bash block: Change description to "# Description: Branch to debug or documentation phase"
- [ ] Part 6 debug verification block: Change description to "# Description: Verify debug artifacts"
- [ ] Part 6 documentation block: Change description to "# Description: Update documentation"
- [ ] Part 7 bash block: Change description to "# Description: Complete workflow and cleanup"
- [ ] Replace all project directory detection blocks (8 occurrences) with single detect_project_dir() call
- [ ] Replace all "===" header echo statements with emit_status() calls
- [ ] Replace all "CHECKPOINT:" echo blocks with emit_status() calls
- [ ] Replace all "DIAGNOSTIC Information:" blocks with emit_debug() calls
- [ ] Replace all "POSSIBLE CAUSES:" blocks with emit_debug() calls
- [ ] Replace all "TROUBLESHOOTING:" blocks with emit_debug() calls
- [ ] Preserve error exit codes and stack trace information

Testing:
```bash
# Test build command with an existing plan
/build .claude/specs/773_build_command_is_working_great_yielding_sample_out/plans/001_output_formatting_implementation_plan.md --dry-run

# Verify:
# 1. Dry-run shows minimal output
# 2. Bash block descriptions are meaningful in Claude Code
# 3. No errors during execution
# 4. With DEBUG=1, more detail is visible
```

### Phase 4: Refactor Remaining Commands
dependencies: [3]

**Objective**: Apply output formatting improvements to remaining workflow commands

**Complexity**: Medium
**Expected Duration**: 2-3 hours

Tasks:
- [ ] Refactor /coordinate.md (file: /home/benjamin/.config/.claude/commands/coordinate.md)
  - [ ] Source output-utils.sh
  - [ ] Update all bash block descriptions
  - [ ] Replace project directory detection with detect_project_dir()
  - [ ] Replace echo statements with emit_status/emit_detail/emit_debug
- [ ] Refactor /plan.md (file: /home/benjamin/.config/.claude/commands/plan.md)
  - [ ] Source output-utils.sh
  - [ ] Update all bash block descriptions
  - [ ] Replace project directory detection with detect_project_dir()
  - [ ] Replace echo statements with emit_status/emit_detail/emit_debug
- [ ] Refactor /debug.md (file: /home/benjamin/.config/.claude/commands/debug.md)
  - [ ] Source output-utils.sh
  - [ ] Update all bash block descriptions
  - [ ] Replace project directory detection with detect_project_dir()
  - [ ] Replace echo statements with emit_status/emit_detail/emit_debug
- [ ] Refactor /revise.md if it contains bash blocks (file: /home/benjamin/.config/.claude/commands/revise.md)

Testing:
```bash
# Test each refactored command:
/coordinate "test output" --dry-run
/plan "test feature" --dry-run
/debug "test issue"

# Verify all show meaningful, minimal output
```

### Phase 5: Integration Testing
dependencies: [4]

**Objective**: Comprehensive testing of all refactored commands

**Complexity**: Low
**Expected Duration**: 1-2 hours

Tasks:
- [ ] Run /research with a real workflow description
- [ ] Run /build with an existing plan (full execution, not dry-run)
- [ ] Run /coordinate with a test workflow
- [ ] Run /plan with a test feature description
- [ ] Verify all commands complete without errors
- [ ] Verify output is 85%+ reduced compared to baseline
- [ ] Verify DEBUG=1 shows additional detail
- [ ] Verify DEBUG=2 shows full diagnostic information
- [ ] Verify error messages still show full stack traces
- [ ] Check that all library sourcing is in correct order

Testing:
```bash
# Full integration test
# 1. Capture baseline output count
# 2. Run each command
# 3. Compare output line counts
# 4. Verify functionality preserved

# Test error paths
# 1. Provide invalid input to trigger errors
# 2. Verify error messages are clear
# 3. Verify DEBUG=2 shows full diagnostics
```

### Phase 6: Documentation Update
dependencies: [5]

**Objective**: Update documentation to reflect new output formatting patterns

**Complexity**: Low
**Expected Duration**: 1 hour

**NOTE**: Per user instructions, documentation updates can be deferred if time is limited. The refactor working error-free is the priority.

Tasks:
- [ ] Update .claude/lib/README.md to document output-utils.sh
- [ ] Add output-utils.sh to library dependency order documentation
- [ ] Document emit_status/emit_detail/emit_debug usage patterns
- [ ] Update command documentation to mention DEBUG levels
- [ ] Create example snippets showing the new bash block description pattern
- [ ] Update troubleshooting guides to mention DEBUG=1 and DEBUG=2

Testing:
```bash
# Verify documentation is accurate
# 1. Follow documented usage patterns
# 2. Confirm examples work as described
```

## Testing Strategy

### Unit Testing
- Test each output function in isolation (emit_status, emit_detail, emit_debug)
- Test detect_project_dir() caching behavior
- Test DEBUG level environment variable detection

### Integration Testing
- Test complete workflow execution for each refactored command
- Test error paths to ensure diagnostics are preserved
- Compare output volume before and after refactor

### Acceptance Criteria
- Output reduced by 85%+ for normal operation
- All workflows complete successfully
- Error messages remain informative
- DEBUG=1 shows useful intermediate detail
- DEBUG=2 shows full diagnostic output

## Documentation Requirements

- [ ] Update .claude/lib/README.md with output-utils.sh documentation
- [ ] Add library to standard dependency order in code standards
- [ ] Document DEBUG environment variable usage
- [ ] Update any guides that reference bash block structure

## Dependencies

### Prerequisites
- state-persistence.sh (for caching pattern)
- unified-logger.sh (emit_progress pattern reference)
- base-utils.sh (info, warn, error functions)

### External Dependencies
- None (pure bash implementation)

## Risk Mitigation

### Risk 1: Breaking Existing Functionality
**Mitigation**: Pilot test with /research before rolling out to other commands. Each phase is isolated and testable.

### Risk 2: set +H Removal Causes History Expansion Errors
**Mitigation**: Keep set +H in actual code execution, just remove it from the description comment. The first line comment becomes the description; set +H remains as the actual first executed line.

### Risk 3: Lost Diagnostic Information
**Mitigation**: All diagnostic information is preserved in emit_debug() calls. DEBUG=2 reveals full diagnostics when troubleshooting.

### Risk 4: Complexity in Maintaining Multiple Output Levels
**Mitigation**: Simple implementation with environment variable control. No command-line flags required.

---

**Note**: This plan has a complexity score of 57.5, which exceeds the threshold for phase expansion. Consider using `/expand-phase` during implementation if any phase proves more complex than estimated.
