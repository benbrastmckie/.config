# Fix /supervise Command Critical Bug - Implementation Plan

## Metadata
- **Date**: 2025-10-25
- **Feature**: Fix critical undefined function bug and early exit conditions in /supervise command
- **Scope**: Bug fix with diagnostic improvements and test coverage
- **Estimated Phases**: 6
- **Estimated Hours**: 4-6 hours
- **Structure Level**: 0
- **Complexity Score**: 32.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Investigation Overview](../reports/001_supervise_command_failure_investigation_research/OVERVIEW.md)
  - [TODO.md Output Behavior Analysis](../reports/001_supervise_command_failure_investigation_research/002_todo_md_output_behavior_analysis.md)
  - [Subagent Execution Failure Root Cause](../reports/001_supervise_command_failure_investigation_research/003_subagent_execution_failure_root_cause.md)

## Overview

The /supervise command has a **CRITICAL BUG**: the function `display_brief_summary` (previously named `display_completion_summary`) is called at 4 locations (lines 693, 967, 1764, 1846) but is never defined anywhere in the codebase. This causes bash "command not found" errors at workflow completion for ALL workflow types (research-only, research-and-plan, full-implementation, debug-only).

Additionally, the command has 7 early exit conditions in Phase 0 that can prevent agent execution entirely, along with brittle failure modes that need diagnostic improvements for better debugging.

**Design Decision**: Use `display_brief_summary` name to emphasize concise, focused output that saves user time and directs attention to key artifacts without verbose details.

**Good News**: Agent delegation patterns are already correct (code fence priming effect resolved in spec 469).

## Research Summary

Key findings from research reports:

**From OVERVIEW.md**:
- Critical undefined function bug affects all 4 workflow types
- Function called at 4 completion points but never defined
- Agent delegation patterns are correct (100% delegation rate post-spec 469)
- 7 early exit conditions identified that prevent agent execution

**From TODO.md Output Behavior Analysis**:
- `display_brief_summary` function completely undefined (was `display_completion_summary` in error messages)
- Should display concise workflow completion summary with key artifact paths only
- Must handle 4 workflow scopes with brief, focused output for each
- Access to all required variables confirmed (WORKFLOW_SCOPE, TOPIC_PATH, etc.)
- Goal: Save user time with short summary that focuses attention on next steps

**From Subagent Execution Failure Root Cause**:
- Library sourcing failures cause immediate exit (lines 224-275)
- Missing workflow description terminates before agents (lines 451-457)
- Project root/location detection failures block execution (lines 542-574)
- Directory creation failures prevent workflow start (lines 599-611)
- Workflow scope misdetection causes incorrect phase skipping
- Verification checkpoint failures can terminate workflows mid-execution

**Recommended Approach**: Implement missing function with proper case handling for all workflow types, add function existence checks after library sourcing, improve diagnostic output for early exit conditions, and add comprehensive test coverage.

## Success Criteria

- [ ] `display_brief_summary` function implemented with concise output for all 4 workflow types
- [ ] Brief summary focuses user attention with ≤5 lines per workflow type
- [ ] Function existence checks added after library sourcing
- [ ] Diagnostic output added for all 7 early exit conditions
- [ ] Graceful degradation implemented for library sourcing failures
- [ ] Integration tests added for brief summary functionality
- [ ] All existing tests continue to pass (45/45 integration tests)
- [ ] Manual testing confirms brief, focused output for each workflow type
- [ ] TODO.md file cleaned up and gitignored

## Technical Design

### Architecture Decisions

**1. Function Location**: Implement `display_brief_summary` inline in supervise.md after line 449 (before first use at line 693) rather than in a library file. This keeps workflow-specific output formatting with the command logic.

**2. Brief Output Design**: Output should be concise (≤5 lines per workflow type) to save user time and focus attention:
- **One-line header**: "✓ Workflow complete"
- **Artifact count summary**: "Created N reports + 1 plan in [path]"
- **Next step**: Single action user should take
- **No file lists**: User can explore topic directory themselves
- **No verbose formatting**: Simple, readable text

**3. Case-Based Implementation**: Use bash `case` statement to handle 4 workflow types with brief output for each:
- `research-only`: Show topic path, report count, suggest review
- `research-and-plan`: Show topic path, report + plan count, suggest implement
- `full-implementation`: Show topic path, summary path, suggest review summary
- `debug-only`: Show topic path, debug report, suggest review

**3. Error Handling Strategy**: Add function existence verification after library sourcing (line 276) with clear error messages to prevent similar issues in future.

**4. Diagnostic Approach**: Add diagnostic output before each early exit showing all relevant variable states for debugging.

**5. Graceful Degradation**: Improve library sourcing to provide fallback implementations instead of hard exits where feasible.

### Component Interactions

```
┌──────────────────────────────────────────────────────────┐
│ supervise.md Phase 0 (Setup & Validation)                │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  1. Library Sourcing (lines 224-275)                     │
│     ├─→ Add fallback for missing libraries               │
│     └─→ Add function existence checks                    │
│                                                           │
│  2. Argument Validation (lines 451-457)                  │
│     └─→ Add diagnostic output before exit                │
│                                                           │
│  3. Project Detection (lines 542-545)                    │
│     └─→ Add diagnostic output with env info              │
│                                                           │
│  4. Location Calculation (lines 566-574)                 │
│     └─→ Add diagnostic output with metadata              │
│                                                           │
│  5. Directory Creation (lines 599-611)                   │
│     └─→ Enhanced fallback diagnostics                    │
│                                                           │
└──────────────────────────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────┐
│ display_brief_summary (NEW - after line 449)            │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  Input: $WORKFLOW_SCOPE, $TOPIC_PATH, artifact counts    │
│                                                           │
│  Logic:                                                   │
│    case $WORKFLOW_SCOPE in                               │
│      research-only)      → "✓ N reports in [path]"      │
│      research-and-plan)  → "✓ N reports + plan in..."   │
│      full-implementation)→ "✓ See summary: [path]"      │
│      debug-only)         → "✓ Debug report: [path]"     │
│    esac                                                   │
│                                                           │
│  Output: ≤5 lines total (brief, focused)                 │
│                                                           │
└──────────────────────────────────────────────────────────┘
                        │
                        ▼
          Called at 4 completion points:
          - Line 693 (research-only exit)
          - Line 967 (research-and-plan exit)
          - Line 1764 (skip documentation exit)
          - Line 1846 (final completion)
```

## Implementation Phases

### Phase 1: Implement display_brief_summary Function (CRITICAL)
dependencies: []

**Objective**: Implement the missing `display_brief_summary` function with concise output (≤5 lines) for all 4 workflow types to save user time and focus attention

**Complexity**: Medium

**Priority**: CRITICAL - This is a blocking bug affecting all /supervise executions

Tasks:
- [x] Read supervise.md to understand current state and variable context (file: .claude/commands/supervise.md, lines 629-649 for path variables)
- [x] Verify required variables available: WORKFLOW_SCOPE, TOPIC_PATH, REPORT_PATHS[], PLAN_PATH, SUMMARY_PATH, DEBUG_REPORT
- [x] Implement `display_brief_summary` function after line 449 in supervise.md with BRIEF output:
  - Single-line header: "✓ Workflow complete: [type]"
  - Artifact count summary (not file lists): "Created N reports in [topic_path]"
  - Next step action: "→ Review artifacts in [path]" or "→ Run: /implement [plan]"
  - Maximum 5 lines total output
  - No verbose formatting, no separator lines, no detailed file listings
  - Case statement handling all 4 workflow scopes with appropriate brevity
- [x] Add function comments emphasizing brief output design goal
- [x] Verify function syntax with bash -n (no-execute mode)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Test function syntax
bash -n .claude/commands/supervise.md

# Verify function is defined with brief output
grep -A 30 "^display_brief_summary()" .claude/commands/supervise.md

# Check all 4 case branches exist
grep -E "(research-only|research-and-plan|full-implementation|debug-only)" .claude/commands/supervise.md

# Verify output is brief (≤5 lines per case)
# Manual check: Count lines in each case branch
```

**Expected Duration**: 1 hour

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (bash syntax check passes)
- [x] Brief output verified (≤5 lines per workflow type)
- [ ] Git commit created: `fix(supervise): implement display_brief_summary for concise output`
- [ ] Update this plan file with phase completion status

---

### Phase 2: Add Function Existence Checks (HIGH)
dependencies: [1]

**Objective**: Add verification that required functions exist after library sourcing to prevent similar issues in future

**Complexity**: Low

**Priority**: HIGH - Prevents future undefined function bugs

Tasks:
- [x] Add function existence check block after line 276 (after all library sourcing) in supervise.md
- [x] Check for `display_brief_summary` function existence using `command -v`
- [x] Check for other critical functions: `detect_workflow_scope`, `should_run_phase`, `emit_progress`, `save_phase_checkpoint`, `load_phase_checkpoint`, `retry_with_backoff`
- [x] Provide clear error message with bug report instructions on failure
- [x] Use exit code 1 for function verification failures
- [x] Add comments explaining purpose of verification checks

Testing:
```bash
# Test function existence check logic
bash -c 'command -v display_brief_summary >/dev/null 2>&1 && echo "Found" || echo "Not found"'

# Verify error messages are clear and actionable
grep -A 5 "function.*not defined" .claude/commands/supervise.md
```

**Expected Duration**: 30 minutes

**Phase 2 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (verification checks work correctly)
- [ ] Git commit created: `feat(supervise): add function existence verification checks`
- [ ] Update this plan file with phase completion status

---

### Phase 3: Add Diagnostic Output for Early Exit Conditions (MEDIUM)
dependencies: [2]

**Objective**: Add diagnostic output before each early exit condition to improve debugging when Phase 0 exits

**Complexity**: Medium

**Priority**: MEDIUM - Improves debugging experience

Tasks:
- [x] Add diagnostic output before workflow description validation exit (lines 451-457)
  - Show usage message and example workflow descriptions
- [x] Add diagnostic output before project root detection exit (lines 542-545)
  - Show PROJECT_ROOT value, current directory, git repo status
- [x] Add diagnostic output before location metadata exit (lines 566-574)
  - Show LOCATION, TOPIC_NUM, TOPIC_NAME values
  - Show PROJECT_ROOT, SPECS_ROOT, WORKFLOW_DESCRIPTION
- [x] Add diagnostic output before directory creation exit (lines 599-611)
  - Show TOPIC_PATH, parent directory status, permissions
  - Show fallback attempt details
- [x] Add workflow scope detection logging after line 502
  - Show detected scope, description, phases to execute/skip
- [x] Format diagnostic output consistently with clear labels and spacing

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Test diagnostic output by triggering failures in safe environment

# Test missing workflow description
echo '/supervise ""' | claude-code 2>&1 | grep -A 5 "DIAGNOSTIC INFO"

# Test location metadata (requires mocking)
# Verify diagnostic blocks are present in code
grep -c "DIAGNOSTIC INFO:" .claude/commands/supervise.md
# Expected: 4 occurrences
```

**Expected Duration**: 1.5 hours

**Phase 3 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (diagnostic output formatting verified)
- [ ] Git commit created: `feat(supervise): add diagnostic output for early exit conditions`
- [ ] Update this plan file with phase completion status

---

### Phase 4: Improve Graceful Degradation for Library Sourcing (MEDIUM)
dependencies: [2]

**Objective**: Improve library sourcing to provide fallback behavior instead of hard exits where feasible

**Complexity**: Medium

**Priority**: MEDIUM - Improves resilience

Tasks:
- [ ] Analyze which libraries can have fallback implementations (workflow-detection.sh has simple fallback)
- [ ] Implement fallback for workflow-detection.sh sourcing failure
  - Provide simple `detect_workflow_scope()` fallback that returns "full-implementation"
  - Log warning about missing library and fallback usage
- [ ] Keep hard exits for critical libraries (error-handling.sh, checkpoint-utils.sh)
- [ ] Add comments explaining fallback strategy and limitations
- [ ] Document fallback behavior in command header
- [ ] Test that fallback mode works for basic workflows

Testing:
```bash
# Test fallback behavior by temporarily renaming library
mv .claude/lib/workflow-detection.sh .claude/lib/workflow-detection.sh.backup

# Run command - should use fallback
/supervise "test workflow with fallback" 2>&1 | grep "WARNING.*fallback"

# Restore library
mv .claude/lib/workflow-detection.sh.backup .claude/lib/workflow-detection.sh
```

**Expected Duration**: 1 hour

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (fallback mode works correctly)
- [ ] Git commit created: `feat(supervise): add graceful degradation for library sourcing`
- [ ] Update this plan file with phase completion status

---

### Phase 5: Add Integration Tests for Brief Summary (LOW)
dependencies: [1, 2]

**Objective**: Add comprehensive integration tests for brief summary functionality across all workflow types

**Complexity**: Medium

**Priority**: LOW - Test coverage for regression prevention

Tasks:
- [ ] Create test file `.claude/tests/test_supervise_brief_summary.sh`
- [ ] Add test scaffolding with setup/teardown functions
- [ ] Implement test for research-only workflow brief output
  - Verify "✓ Workflow complete" present
  - Verify output is ≤5 lines
  - Verify topic path displayed
  - Verify no verbose file listings
- [ ] Implement test for research-and-plan workflow brief output
  - Verify brief artifact count summary
  - Verify "→" next step action present
  - Verify output is ≤5 lines
- [ ] Implement test for full-implementation workflow brief output
  - Verify summary path displayed
  - Verify brief next step action
  - Verify output is ≤5 lines
- [ ] Implement test for debug-only workflow brief output
  - Verify debug report path displayed
  - Verify output is ≤5 lines
- [ ] Add test for function existence verification
  - Mock missing function scenario
  - Verify error message content
- [ ] Add test to integration test suite runner
- [ ] Run full test suite to ensure no regressions

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Run new brief summary tests
.claude/tests/test_supervise_brief_summary.sh

# Run full integration test suite
.claude/tests/run_all_tests.sh

# Verify test coverage
grep -c "^test_" .claude/tests/test_supervise_brief_summary.sh
# Expected: ≥5 test functions

# Verify brevity requirement (output ≤5 lines per workflow)
# Manual verification in test implementation
```

**Expected Duration**: 1.5 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (new tests pass, no regressions in existing 45 tests)
- [ ] Brevity verified (all outputs ≤5 lines)
- [ ] Git commit created: `test(supervise): add integration tests for brief summary output`
- [ ] Update this plan file with phase completion status

---

### Phase 6: Cleanup TODO.md and Update Gitignore (LOW)
dependencies: [5]

**Objective**: Clean up misplaced TODO.md file and prevent future TODO.md files in specs root

**Complexity**: Low

**Priority**: LOW - Housekeeping

Tasks:
- [ ] Check current status of `.claude/specs/TODO.md` (marked as deleted in git status)
- [ ] Verify file is removed from working tree
- [ ] If file still exists, determine if content should be archived or deleted
- [ ] Update `.gitignore` to prevent future TODO.md files in specs root:
  - Add `.claude/specs/TODO.md` entry
  - Add `.claude/specs/TODO*.md` pattern
- [ ] Commit gitignore changes
- [ ] Document cleanup in commit message

Testing:
```bash
# Verify TODO.md is removed
test ! -f .claude/specs/TODO.md && echo "✓ Removed" || echo "✗ Still exists"

# Verify gitignore pattern
grep "TODO.*.md" .gitignore

# Test gitignore pattern works
touch .claude/specs/TODO_test.md
git status --ignored | grep TODO_test.md
rm .claude/specs/TODO_test.md
```

**Expected Duration**: 15 minutes

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (gitignore pattern works correctly)
- [ ] Git commit created: `chore(supervise): cleanup TODO.md and update gitignore`
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Overall Test Approach

**1. Unit Testing**: Test individual components in isolation
- Function syntax validation with `bash -n`
- Function existence checks
- Case statement coverage for all workflow types
- Brief output verification (≤5 lines per case)
- Diagnostic output formatting

**2. Integration Testing**: Test workflow execution end-to-end
- Research-only workflow brief summary (`.claude/tests/test_supervise_brief_summary.sh`)
- Research-and-plan workflow brief summary
- Full-implementation workflow brief summary
- Debug-only workflow brief summary
- Early exit diagnostics (triggered failures)
- Output brevity verification (≤5 lines per workflow)

**3. Regression Testing**: Ensure existing functionality preserved
- Run full integration test suite (45 tests in `run_all_tests.sh`)
- Verify all existing tests continue to pass
- No changes to agent delegation behavior (100% delegation rate maintained)

**4. Manual Testing**: Human verification of output quality
- Test each workflow type with real topics
- Verify brief summary is readable and focused (≤5 lines)
- Confirm output saves user time without verbose details
- Check diagnostic output is helpful for debugging
- Confirm error messages are clear and actionable

### Test Coverage Goals

- [ ] 100% coverage of `display_brief_summary` case branches (4 workflow types)
- [ ] Brief output verification (all outputs ≤5 lines)
- [ ] 100% coverage of early exit diagnostic blocks (7 exit conditions)
- [ ] 100% coverage of function existence checks (4 critical functions)
- [ ] Existing integration test coverage maintained (45/45 tests passing)
- [ ] Manual verification of all 4 workflow types with brevity check

### Test Execution Order

1. **Phase 1**: Syntax validation, function definition check
2. **Phase 2**: Function existence verification tests
3. **Phase 3**: Diagnostic output presence verification
4. **Phase 4**: Fallback behavior tests
5. **Phase 5**: Full integration test suite
6. **Phase 6**: Gitignore pattern verification

### Acceptance Criteria for Testing

All tests must pass with:
- 0 syntax errors in bash scripts
- All integration tests passing (45/45 existing + new brief summary tests)
- Manual testing confirms brief, focused output (≤5 lines per workflow)
- Output saves user time without verbose details
- No regressions in agent delegation behavior
- Clear error messages for all failure conditions

## Documentation Requirements

### Files to Update

**1. supervise.md Command File**:
- Add function documentation header for `display_brief_summary` emphasizing concise output design
- Document required functions in command header (after line 3)
- Add comments explaining brief output strategy (≤5 lines per workflow)
- Add comments explaining diagnostic output strategy
- Document fallback behavior for library sourcing

**2. Test Documentation**:
- Add test file header to `test_supervise_brief_summary.sh`
- Document brevity requirement (≤5 lines) in test file comments
- Document test coverage in test file comments
- Update `.claude/tests/README.md` if exists

**3. This Implementation Plan**:
- Update completion checkboxes as phases are completed
- Add any discovered issues or deviations from plan
- Mark final completion status

### Documentation Standards

Follow CLAUDE.md documentation policy:
- Clear, concise language
- Code examples with syntax highlighting
- No emojis in file content (use text symbols only)
- No historical commentary (present-focused documentation)

## Dependencies

### External Dependencies
- Bash 4.0+ (for array support in REPORT_PATHS)
- Existing library files:
  - `.claude/lib/workflow-detection.sh` (with fallback)
  - `.claude/lib/error-handling.sh` (critical)
  - `.claude/lib/checkpoint-utils.sh` (critical)
  - `.claude/lib/unified-logger.sh`
  - `.claude/lib/topic-utils.sh`
  - `.claude/lib/detect-project-dir.sh`

### Internal Dependencies
- No changes to agent templates required (already correct)
- No changes to library files required (function implemented inline)
- Existing test infrastructure (`.claude/tests/run_all_tests.sh`)

### Phase Dependencies
- Phase 2 depends on Phase 1 (function must exist before checking existence)
- Phase 3 can run in parallel with Phase 2 (independent changes)
- Phase 4 can run in parallel with Phase 2 (independent changes)
- Phase 5 depends on Phases 1 and 2 (tests require function and checks)
- Phase 6 can run in parallel with all others (independent cleanup)

**Wave-based Execution**:
- **Wave 1**: Phase 1 (critical function implementation)
- **Wave 2**: Phases 2, 3, 4 (can run in parallel - 40% time savings)
- **Wave 3**: Phase 5 (depends on Wave 2 completion)
- **Wave 4**: Phase 6 (independent cleanup)

See [Parallel Execution Pattern](.claude/docs/concepts/patterns/parallel-execution.md) for wave-based implementation details.

## Risk Assessment

### High Risk Items
1. **Function implementation errors** could break all workflows → Mitigate with syntax validation and comprehensive testing
2. **Variable access issues** if variables not available at completion points → Mitigate by verifying variable availability before implementation

### Medium Risk Items
1. **Diagnostic output verbosity** could clutter output → Mitigate with concise, structured formatting
2. **Fallback behavior** could mask real issues → Mitigate with clear warning messages when fallbacks used

### Low Risk Items
1. **Gitignore pattern** could be too broad → Mitigate with specific pattern testing
2. **Test coverage gaps** could miss edge cases → Mitigate with manual testing of all workflow types

## Rollback Strategy

If critical issues are discovered:

1. **Immediate Rollback**: `git revert` the Phase 1 commit (function implementation)
2. **Partial Rollback**: Keep diagnostic improvements (Phases 3-4) but revert function changes
3. **Testing Rollback**: Disable new tests if they cause issues, keep fixes in place

## Estimated Effort Summary

- **Phase 1**: 1 hour (CRITICAL)
- **Phase 2**: 30 minutes (HIGH)
- **Phase 3**: 1.5 hours (MEDIUM)
- **Phase 4**: 1 hour (MEDIUM)
- **Phase 5**: 1.5 hours (LOW)
- **Phase 6**: 15 minutes (LOW)

**Total Estimated Time**: 5.75 hours (~6 hours with testing overhead)

**Complexity Score Calculation**:
```
Score = (tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)
Score = (32 × 1.0) + (6 × 5.0) + (6 × 0.5) + (0 × 2.0)
Score = 32 + 30 + 3 + 0 = 65.0
```

**Note**: Complexity score is 65.0 (≥50), suggesting this could be expanded to Level 1 (phase directory) during implementation if needed. Use `/expand` command if phases become too complex during execution.

---

## Revision History

### 2025-10-25 - Revision 1
**Changes**: Renamed function from `display_completion_summary` to `display_brief_summary` and revised output design to be concise (≤5 lines per workflow type)

**Reason**: User requested brief, focused output to save time and direct attention to key artifacts without verbose details

**Modified Phases**:
- Phase 1: Function name changed to `display_brief_summary`, output specification revised for brevity (≤5 lines), removed verbose file listings and detailed formatting
- Phase 2: Updated function existence checks to use new name
- Phase 5: Test file renamed to `test_supervise_brief_summary.sh`, added brevity verification (≤5 lines per workflow)
- All phases: Updated references from `display_completion_summary` to `display_brief_summary`

**Design Changes**:
- Output format: Single-line header + artifact count + next step (≤5 lines total)
- No file listings: Users explore topic directory themselves
- No verbose formatting: Simple, readable text only
- Focus: Save user time and direct attention

---

**Plan Status**: Ready for Implementation (Revised)
**Next Action**: Execute Phase 1 (critical brief summary function implementation)
