# Error Logging and --file Flag Enhancement Implementation Plan

## Metadata
- **Date**: 2025-11-23
- **Feature**: Improve error logging throughout commands with --file flag for /repair, integrating with existing infrastructure
- **Scope**: Enhance /repair command --file flag to pass workflow output files to repair-analyst for comprehensive error analysis
- **Estimated Phases**: 4
- **Estimated Hours**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 39.5
- **Research Reports**:
  - [Error Logging File Flag Integration Research](../reports/001-error-logging-file-flag-integration.md)

## Overview

The `/repair` command currently has a `--file` flag that appends file content to the error description, but this underutilizes the flag's potential. The repair-analyst agent only reads `errors.jsonl` and misses actual runtime errors visible in workflow output files. This plan implements enhancements to pass workflow output files to the repair-analyst agent for comprehensive error analysis.

## Research Summary

Key findings from the research report:

1. **Gap Identified**: The `--file` flag appends content to ARGS_STRING but doesn't pass the file path separately to repair-analyst, preventing the agent from analyzing runtime errors in workflow output files
2. **Root Cause of /repair Failures**: The repair-analyst agent only reads `errors.jsonl`, missing path mismatch bugs and runtime errors that only appear in workflow output
3. **Existing Pattern**: The --file flag pattern is consistent across /plan, /debug, /research, and /repair commands
4. **Solution Approach**: Pass WORKFLOW_OUTPUT_FILE to repair-analyst agent prompt, update agent to read and analyze the file

Recommended approach: Minimal, targeted modifications to /repair command and repair-analyst agent to enable workflow output file analysis.

## Success Criteria

- [x] `/repair --file <workflow-output.md>` passes the file path to repair-analyst agent
- [x] repair-analyst agent reads and analyzes workflow output files when provided
- [x] Error context includes CLAUDE_PROJECT_DIR and HOME for path-related errors
- [x] Documentation updated to explain enhanced --file usage for workflow output analysis
- [x] Existing --file functionality preserved (backward compatible)
- [x] Tests verify workflow output analysis works correctly

## Technical Design

### Architecture Overview

```
/repair command
    │
    ├── Block 1: Parse --file flag
    │   └── Store WORKFLOW_OUTPUT_FILE in workflow state
    │
    ├── Task: Invoke repair-analyst
    │   └── Include WORKFLOW_OUTPUT_FILE in agent prompt context
    │
    └── repair-analyst agent
        ├── Read errors.jsonl (existing)
        └── Read WORKFLOW_OUTPUT_FILE if provided (new)
```

### Key Changes

1. **repair.md Block 1**: Persist `WORKFLOW_OUTPUT_FILE` separately from ARGS_STRING
2. **repair.md Task invocation**: Add `WORKFLOW_OUTPUT_FILE` to agent prompt context
3. **repair-analyst.md**: Add Step 3.5 to read and analyze workflow output file
4. **error-handling.sh**: Add HOME and CLAUDE_PROJECT_DIR to context for state/file errors

### Integration Points

- `/repair` command (repair.md)
- repair-analyst agent (agents/repair-analyst.md)
- error-handling.sh library (log_command_error function)
- repair-command-guide.md documentation

## Implementation Phases

### Phase 1: /repair Command Enhancement [COMPLETE]
dependencies: []

**Objective**: Modify /repair to persist WORKFLOW_OUTPUT_FILE and pass it to repair-analyst agent

**Complexity**: Low

Tasks:
- [x] Edit repair.md Block 1 to persist WORKFLOW_OUTPUT_FILE separately from ARGS_STRING (file: .claude/commands/repair.md, lines 77-97)
- [x] Edit repair.md Block 1 to add `append_workflow_state "WORKFLOW_OUTPUT_FILE" "$ORIGINAL_PROMPT_FILE_PATH"` after --file parsing
- [x] Edit repair.md Task invocation to include WORKFLOW_OUTPUT_FILE in prompt context (file: .claude/commands/repair.md, lines 471-491)
- [x] Verify Block 2 loads WORKFLOW_OUTPUT_FILE from state for agent invocation

Testing:
```bash
# Test that WORKFLOW_OUTPUT_FILE is persisted correctly
/repair --file .claude/research-output.md --type state_error
# Verify workflow state contains WORKFLOW_OUTPUT_FILE path
```

**Expected Duration**: 2 hours

### Phase 2: repair-analyst Agent Enhancement [COMPLETE]
dependencies: [1]

**Objective**: Modify repair-analyst to read and analyze workflow output files when provided

**Complexity**: Medium

Tasks:
- [x] Edit repair-analyst.md STEP 3 section to add workflow output file analysis (file: .claude/agents/repair-analyst.md, lines 126-198)
- [x] Add conditional logic: "If WORKFLOW_OUTPUT_FILE is provided and exists, read and analyze it"
- [x] Add pattern detection for runtime errors in workflow output (path mismatches, state file errors, bash execution errors)
- [x] Update Report Structure Template to include "Workflow Output Analysis" section when applicable
- [x] Update Completion Criteria to verify workflow output was analyzed if provided

Testing:
```bash
# Manually invoke repair-analyst with workflow output file path
# Verify report includes "Workflow Output Analysis" section
# Verify path mismatch patterns are detected
```

**Expected Duration**: 3 hours

### Phase 3: Error Context Enhancement [COMPLETE]
dependencies: [1]

**Objective**: Add environment context to error log entries for path-related debugging

**Complexity**: Low

Tasks:
- [x] Edit log_command_error function in error-handling.sh (file: .claude/lib/core/error-handling.sh, lines 410-514)
- [x] Add HOME and CLAUDE_PROJECT_DIR to context JSON for state_error and file_error types
- [x] Ensure context enhancement doesn't break existing error log parsing
- [x] Update error-handling pattern documentation if needed

Testing:
```bash
# Source error-handling.sh
# Call log_command_error with state_error type
# Verify output includes home and claude_project_dir in context
cat .claude/tests/logs/test-errors.jsonl | jq -r 'select(.error_type=="state_error") | .context'
```

**Expected Duration**: 1.5 hours

### Phase 4: Documentation and Testing [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Update documentation and add integration tests

**Complexity**: Low

Tasks:
- [x] Edit repair-command-guide.md to document enhanced --file usage (file: .claude/docs/guides/commands/repair-command-guide.md)
- [x] Add usage example: `/repair --file .claude/research-output.md --type state_error`
- [x] Document that --file now enables workflow output analysis (not just additional context)
- [x] Add integration test for --file with workflow output file (file: .claude/tests/integration/test_repair_workflow_output.sh)
- [x] Verify all existing /repair tests still pass

Testing:
```bash
# Run repair command tests
bash .claude/tests/features/commands/test_repair_*.sh
# Run integration tests
bash .claude/tests/integration/test_repair_*.sh
# Verify documentation renders correctly
```

**Expected Duration**: 1.5 hours

## Testing Strategy

### Unit Tests
- Verify WORKFLOW_OUTPUT_FILE persisted to state
- Verify log_command_error adds environment context for path errors
- Verify repair-analyst reads workflow output file when provided

### Integration Tests
- End-to-end: `/repair --file research-output.md` produces report with workflow output analysis
- Backward compatibility: `/repair --since 1h` works without --file
- Error handling: `/repair --file nonexistent.md` handles missing file gracefully

### Validation Commands
```bash
# Test Phase 1: State persistence
/repair --file .claude/tmp/test-output.md --dry-run 2>&1 | grep WORKFLOW_OUTPUT_FILE

# Test Phase 2: Agent analysis
# Requires manual inspection of repair-analyst report

# Test Phase 3: Error context
source .claude/lib/core/error-handling.sh
CLAUDE_TEST_MODE=1 log_command_error "/test" "test_123" "" "state_error" "Test" "test" "{}"
cat .claude/tests/logs/test-errors.jsonl | tail -1 | jq .context

# Test Phase 4: Documentation
cat .claude/docs/guides/commands/repair-command-guide.md | grep -A5 "workflow output"
```

## Documentation Requirements

- Update repair-command-guide.md with enhanced --file usage
- Update error-handling.md pattern documentation if context structure changes
- No new documentation files needed (update existing)

## Dependencies

### External Dependencies
- None

### Internal Dependencies
- state-persistence.sh: load_workflow_state, append_workflow_state
- error-handling.sh: log_command_error
- workflow-state-machine.sh: State persistence across blocks

### Prerequisites
- Understanding of --file flag pattern from research report
- Familiarity with repair-analyst agent protocol

## Risk Assessment

### Low Risk
- Changes are additive (new functionality)
- Backward compatible (existing --file usage preserved)
- Contained to specific files

### Mitigation
- Test existing /repair functionality after each phase
- Use existing --file pattern as template
- Incremental changes with verification at each step
