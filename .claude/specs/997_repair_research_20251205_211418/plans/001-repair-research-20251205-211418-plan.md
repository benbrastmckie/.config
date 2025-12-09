# Implementation Plan: Fix /research Command Error Patterns

## Metadata
- **Date**: 2025-12-05
- **Feature**: Fix 7 error patterns in /research command affecting 24+ logged errors
- **Status**: [COMPLETE]
- **Estimated Hours**: 8-12 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [Error Analysis Report](../reports/001-research-errors-repair.md)
- **Complexity**: 3 (multiple files, agent updates, library changes)
- **Error Log Query**: --command /research
- **Total Errors Addressed**: 24 errors across 6 patterns

## Overview

This plan addresses 7 critical error patterns identified in /research command error log analysis:
1. **Lazy directory creation** (38% of errors) - Find commands failing on non-existent directories
2. **Hard barrier validation for topic naming agent** (33% of errors) - Agent output contract violations
3. **PATH MISMATCH validation logic** (8% of errors) - False positives when PROJECT_DIR under HOME
4. **Library sourcing fail-fast handlers** (13% of errors) - Exit code 127 from undefined functions
5. **Research report section validation** (8% of errors) - Missing "## Findings" sections
6. **STATE_FILE validation in sm_transition** (4% of errors) - State transitions without initialization
7. **History expansion error investigation** (workflow output analysis) - Bash history expansion despite set +H

The research report shows these patterns account for 100% of logged /research errors over 15 days.

## Success Criteria

1. All 7 error patterns eliminated from future /research command executions
2. /research command successfully completes with:
   - Topic directories created before find operations
   - Agent output validation enforcing hard barriers
   - Path validation handling PROJECT_DIR under HOME correctly
   - Library sourcing with fail-fast verification
   - Research reports containing required sections
   - State transitions only after proper initialization
   - No history expansion errors in bash blocks
3. Error log entries updated from FIX_PLANNED to RESOLVED
4. Integration tests pass for /research command with edge cases
5. No new errors generated during repair implementation

## Phases

### Phase 1: Implement Lazy Directory Creation Pattern [COMPLETE]

**Priority**: Critical (38% of errors)
**Effort**: Low
**Files Modified**:
- `.claude/commands/research.md`

**Tasks**:
- [x] Locate all find command usages in /research command
- [x] Add `mkdir -p "$RESEARCH_DIR"` before find operations for report counting
- [x] Add `mkdir -p "$SUMMARIES_DIR"` before summary counting operations
- [x] Use defensive default (0) if directory creation fails
- [x] Add error logging if mkdir fails
- [x] Verify find commands execute successfully after mkdir

**Validation**:
- Run /research command and verify no "exit code 1" errors on find commands
- Check error log for elimination of execution_error type at line 219
- Test with non-existent topic directories to ensure lazy creation

**Acceptance Criteria**:
- All find command errors (9 errors) eliminated
- Directory structure created automatically before any file operations
- Graceful handling of mkdir failures with logged errors

---

### Phase 2: Fix PATH MISMATCH Validation Logic [COMPLETE]

**Priority**: High (8% of errors, false positives)
**Effort**: Low
**Files Modified**:
- `.claude/commands/research.md`
- `.claude/lib/workflow/validation-utils.sh` (if validation logic is centralized)

**Tasks**:
- [x] Locate PATH MISMATCH validation code in /research command
- [x] Update conditional to recognize PROJECT_DIR under HOME as valid
- [x] Implement pattern: `if [[ "$STATE_FILE" == *"$HOME"* ]] && [[ "$STATE_FILE" != *"$CLAUDE_PROJECT_DIR"* ]]`
- [x] Add test cases for validation logic:
  - STATE_FILE under PROJECT_DIR (valid) - `/home/user/.config/.claude/tmp/file.sh`
  - STATE_FILE directly under HOME (invalid) - `/home/user/.claude/tmp/file.sh` when PROJECT_DIR is `/project`
  - STATE_FILE outside both (invalid) - `/tmp/file.sh`
- [x] Add inline comment explaining HOME vs PROJECT_DIR validation
- [x] Update error message to clarify validation logic

**Validation**:
- Test /research command with CLAUDE_PROJECT_DIR=~/.config
- Verify no PATH MISMATCH errors logged
- Test with invalid paths and verify errors are still caught

**Acceptance Criteria**:
- No false positive PATH MISMATCH errors (2 errors eliminated)
- Validation still catches actual path mismatches
- Clear error messages when validation fails

---

### Phase 3: Enforce Library Sourcing with Fail-Fast Handlers [COMPLETE]

**Priority**: High (13% of errors)
**Effort**: Low
**Files Modified**:
- `.claude/commands/research.md`

**Tasks**:
- [x] Review all library sourcing statements in /research command
- [x] Add fail-fast handler pattern after each source:
  ```bash
  source "$CLAUDE_LIB/workflow/state-persistence.sh" 2>/dev/null || {
    echo "Error: Cannot load state-persistence library" >&2
    exit 1
  }
  ```
- [x] Add function availability checks for critical functions:
  - `append_workflow_state`
  - `load_workflow_state`
  - `sm_transition`
  - `log_command_error`
- [x] Use pattern:
  ```bash
  type append_workflow_state >/dev/null 2>&1 || {
    echo "Error: append_workflow_state function not defined" >&2
    exit 1
  }
  ```
- [x] Add error logging for library sourcing failures
- [x] Document which libraries and functions are required

**Validation**:
- Test with missing library files (temporarily rename)
- Verify fail-fast behavior with clear error messages
- Test with corrupted library files (syntax errors)
- Verify no exit code 127 errors in subsequent runs

**Acceptance Criteria**:
- All library sourcing failures detected immediately (3 errors eliminated)
- Clear error messages indicating which library/function is missing
- No exit code 127 (command not found) errors in error log

---

### Phase 4: Add Hard Barrier Validation for Topic Naming Agent [COMPLETE]

**Priority**: High (33% of errors)
**Effort**: Medium
**Files Modified**:
- `.claude/commands/research.md`
- `.claude/agents/topic-naming-agent.md`

**Tasks**:
- [x] Review current topic-naming-agent invocation in /research command
- [x] Add hard barrier validation after agent Task invocation:
  - Check output file exists at expected path
  - Verify output file contains valid topic name
  - Capture agent stderr if available
- [x] Add timeout handling for agent execution (30 second default)
- [x] Replace silent fallback to "no_name" with explicit error logging
- [x] Add agent output contract verification:
  - Output file must exist
  - Output must be single line
  - Output must match topic name pattern (alphanumeric + underscores)
- [x] Update topic-naming-agent.md behavioral guidelines:
  - Explicitly require output file creation
  - Document expected output path format
  - Add self-validation before returning
- [x] Add error context when agent fails:
  - Agent execution time
  - Output file path checked
  - Whether agent produced any output
  - Stderr content if available

**Validation**:
- Test /research command with various prompts
- Verify topic names are semantic (not "no_name")
- Test agent failure scenarios (invalid output, missing file)
- Verify error logging includes detailed context
- Check error log for elimination of agent_error with context "agent_no_output_file"

**Acceptance Criteria**:
- All topic naming agent failures detected immediately (8 errors eliminated)
- No silent fallbacks to "no_name" directory
- Agent failures logged with detailed error context
- Agent behavioral guidelines updated with explicit requirements

---

### Phase 5: Add STATE_FILE Validation in sm_transition [COMPLETE]

**Priority**: Medium (4% of errors)
**Effort**: Low
**Files Modified**:
- `.claude/lib/workflow/workflow-state-machine.sh`

**Tasks**:
- [x] Locate sm_transition function in workflow-state-machine.sh
- [x] Add defensive check at function start:
  ```bash
  function sm_transition() {
    local target_state="$1"

    if [[ -z "$STATE_FILE" ]]; then
      log_command_error "state_error" \
        "STATE_FILE not set during sm_transition - load_workflow_state not called" \
        "{\"target_state\": \"$target_state\", \"caller\": \"${BASH_SOURCE[1]}:${BASH_LINENO[0]}\"}"
      return 1
    fi
    # ... rest of function
  }
  ```
- [x] Add similar validation to other state machine functions that require STATE_FILE
- [x] Document STATE_FILE initialization requirement in function docstring
- [x] Add unit tests for sm_transition with unset STATE_FILE

**Validation**:
- Test sm_transition without calling load_workflow_state first
- Verify clear error message with caller context
- Test normal workflow with proper initialization
- Check error log for descriptive state_error messages

**Acceptance Criteria**:
- STATE_FILE validation prevents uninitialized state transitions (1 error eliminated)
- Error messages include caller context for debugging
- Function docstrings document initialization requirements

---

### Phase 6: Add Research Report Section Validation [COMPLETE]

**Priority**: Medium (8% of errors)
**Effort**: Medium
**Files Modified**:
- `.claude/agents/research-specialist.md`
- `.claude/commands/research.md`

**Tasks**:
- [x] Update research-specialist.md behavioral guidelines:
  - Add explicit "## Findings" section requirement
  - Document complete report structure with all required sections
  - Add section ordering requirements
  - Include section template in guidelines
- [x] Add agent-side self-validation before returning:
  - Check for presence of "## Findings" section
  - Verify section is non-empty
  - Log warning if validation fails
- [x] Add orchestrator-side validation in /research command:
  - After agent completes, verify report file exists
  - Check for required sections: Findings, Summary, References
  - Log validation_error if sections missing
  - Provide clear error message indicating which sections are missing
- [x] Create report section template for agent context
- [x] Add integration test for report structure validation

**Validation**:
- Run /research command and inspect generated report structure
- Verify "## Findings" section is present and non-empty
- Test agent with prompts that might produce incomplete reports
- Check error log for elimination of "missing required Findings section" errors

**Acceptance Criteria**:
- All research reports contain required "## Findings" section (2 errors eliminated)
- Agent behavioral guidelines clearly document section requirements
- Orchestrator validates report structure and logs errors for missing sections
- Report template provided to agent for consistency

---

### Phase 7: Investigate and Fix History Expansion Error [COMPLETE]

**Priority**: Medium (workflow output shows error despite set +H)
**Effort**: Medium
**Files Modified**:
- `.claude/commands/research.md`

**Tasks**:
- [x] Review workflow output error at line 215: "!: command not found"
- [x] Locate bash blocks in /research command around line 215
- [x] Search for exclamation marks in strings, variables, or commands
- [x] Check for nested shell invocations (subshells, command substitution)
- [x] Verify `set +H` placement at start of all bash blocks
- [x] Consider alternative approaches:
  - Use single quotes for strings containing `!`
  - Escape exclamation marks in double-quoted strings
  - Move `set +H` to global scope if possible
- [x] Add explicit verification: `set +H; shopt -u histexpand`
- [x] Test bash blocks in isolation to reproduce error
- [x] Add inline comments explaining history expansion prevention
- [x] Document any patterns that trigger history expansion despite `set +H`

**Validation**:
- Run /research command with various prompts containing special characters
- Search error log for "!: command not found" errors
- Verify `set +H` is effective in all bash blocks
- Test with inputs that historically triggered history expansion

**Acceptance Criteria**:
- No history expansion errors in bash execution
- `set +H` and `shopt -u histexpand` applied consistently
- Exclamation marks in strings handled correctly
- Documentation added for history expansion prevention patterns

---

### Phase 8: Integration Testing and Validation [COMPLETE]

**Priority**: Critical (validate all fixes together)
**Effort**: Low
**Files Modified**: None (testing phase)
**Dependencies**: Phases 1-7 (all previous fixes must be complete)

**Tasks**:
- [x] Create comprehensive integration test suite for /research command:
  - Test with non-existent topic directories (Phase 1)
  - Test with PROJECT_DIR under HOME (Phase 2)
  - Test with missing library files (Phase 3)
  - Test topic naming agent output validation (Phase 4)
  - Test state transitions without initialization (Phase 5)
  - Test report section validation (Phase 6)
  - Test inputs with special characters for history expansion (Phase 7)
- [x] Run /research command with previous failure scenarios:
  - Use prompts from error log timestamps
  - Replicate directory structures that caused errors
  - Test edge cases identified in research report
- [x] Monitor error log during testing:
  - Verify no new errors generated
  - Check that error types from patterns 1-6 are eliminated
  - Validate error messages are descriptive when failures occur
- [x] Verify all 24 logged errors would be prevented by fixes:
  - 9 execution_error (Pattern 2) - eliminated by Phase 1
  - 8 agent_error (Pattern 1) - eliminated by Phase 4
  - 2 validation_error (Pattern 3) - eliminated by Phase 2
  - 3 state_error (Pattern 6) - eliminated by Phase 3
  - 2 validation_error (Pattern 4) - eliminated by Phase 6
- [x] Document any new error patterns discovered during testing
- [x] Create regression test cases for future validation

**Validation**:
- All integration tests pass
- No errors in error log from test executions
- /research command completes successfully for all test cases
- Error messages are clear and actionable when validation fails

**Acceptance Criteria**:
- Zero /research command errors during comprehensive integration testing
- All 7 error patterns confirmed eliminated
- Regression test suite created for future changes
- Documentation updated with testing procedures

---

### Phase 9: Update Error Log Status [COMPLETE]

**Priority**: Required (final phase)
**Effort**: Low
**Dependencies**: Phases 1-8 (all fixes verified working)

**Objective**: Update error log entries from FIX_PLANNED to RESOLVED

**Tasks**:
- [x] Verify all fixes are working (tests pass, no new errors generated)
- [x] Update error log entries to RESOLVED status using mark_errors_resolved_for_plan function
- [x] Verify no FIX_PLANNED errors remain for this plan
- [x] Document resolution in plan metadata
- [x] Update TODO.md to mark repair task as complete

**Validation**:
- Query error log: `/errors --status FIX_PLANNED --query`
- Verify all entries related to this plan are RESOLVED
- No FIX_PLANNED entries remain for patterns 1-7

**Acceptance Criteria**:
- All 24 error log entries marked RESOLVED
- Error log query confirms status updates
- Plan metadata documents successful completion

## Implementation Notes

### Error Pattern Summary
| Pattern | Frequency | Priority | Effort | Phase |
|---------|-----------|----------|--------|-------|
| Find command errors (Pattern 2) | 38% (9 errors) | Critical | Low | 1 |
| Topic naming agent failures (Pattern 1) | 33% (8 errors) | High | Medium | 4 |
| Library sourcing errors (Pattern 6) | 13% (3 errors) | High | Low | 3 |
| PATH MISMATCH false positives (Pattern 3) | 8% (2 errors) | High | Low | 2 |
| Missing Findings section (Pattern 4) | 8% (2 errors) | Medium | Medium | 6 |
| STATE_FILE not set (Pattern 5) | 4% (1 error) | Medium | Low | 5 |
| History expansion error | N/A (output analysis) | Medium | Medium | 7 |

### Implementation Priority Order
1. **Week 1** (Immediate): Phases 1, 2, 3 - High impact, low effort (59% of errors)
2. **Week 2** (Short-term): Phases 4, 6 - High impact, medium effort (41% of errors)
3. **Week 3** (Medium-term): Phases 5, 7 - Lower frequency, defensive improvements
4. **Final**: Phases 8, 9 - Integration testing and error log updates

### Phase Dependencies
- Phase 8 depends on Phases 1-7 (all fixes must be implemented before integration testing)
- Phase 9 depends on Phase 8 (error log updates only after verification)
- Phases 1-7 are independent and can be implemented in parallel

### Files Requiring Updates
1. `.claude/commands/research.md` - Phases 1, 2, 3, 4, 6, 7 (primary fix target)
2. `.claude/agents/research-specialist.md` - Phase 6 (report section requirements)
3. `.claude/agents/topic-naming-agent.md` - Phase 4 (output contract enforcement)
4. `.claude/lib/workflow/workflow-state-machine.sh` - Phase 5 (STATE_FILE validation)
5. `.claude/lib/workflow/validation-utils.sh` - Phase 2 (if path validation centralized)

### Standards Compliance
- All fixes follow three-tier library sourcing pattern with fail-fast handlers
- Path validation follows patterns from Code Standards (PROJECT_DIR under HOME handling)
- Agent updates follow hierarchical agent architecture communication protocols
- Error logging follows centralized error logging standards
- All changes maintain clean-break development approach (no backwards compatibility wrappers)

### Testing Strategy
- Unit tests for library functions (Phase 5 - sm_transition validation)
- Integration tests for /research command with edge cases (Phase 8)
- Regression tests for all 7 error patterns (Phase 8)
- Manual testing with previous failure scenarios from error log

### Rollback Plan
If any phase introduces regressions:
1. Revert specific phase changes (git revert)
2. Re-run integration tests (Phase 8)
3. Document regression in error log
4. Create new repair plan for regression fix

## References

- [Error Analysis Report](../reports/001-research-errors-repair.md) - Complete error pattern analysis
- [Error Handling Pattern](.claude/docs/concepts/patterns/error-handling.md) - Error logging standards
- [Directory Protocols](.claude/docs/concepts/directory-protocols.md) - Topic directory structure
- [Code Standards - Path Validation](.claude/docs/reference/standards/code-standards.md#path-validation-patterns) - Path validation patterns
- [Agent Communication Protocols](.claude/docs/concepts/hierarchical-agents-communication.md) - Agent output contracts
- [Command Authoring Standards](.claude/docs/reference/standards/command-authoring.md) - Bash block patterns

## Completion Signal

PLAN_CREATED: /home/benjamin/.config/.claude/specs/997_repair_research_20251205_211418/plans/001-repair-research-20251205-211418-plan.md
