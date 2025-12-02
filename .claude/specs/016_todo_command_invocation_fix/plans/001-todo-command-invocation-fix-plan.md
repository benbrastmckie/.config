# TODO Command Invocation Fix - Implementation Plan

## Metadata
- **Date**: 2025-12-02
- **Feature**: Fix trigger_todo_update() to properly invoke /todo command
- **Scope**: Remove broken automatic TODO.md updates, replace with user reminders and manual /todo workflow across 9 commands
- **Status**: [COMPLETE]
- **Estimated Hours**: 4-6 hours
- **Complexity Score**: 47.5
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [TODO Command Invocation Analysis](../reports/001-todo-command-invocation-analysis.md)

## Overview

The `trigger_todo_update()` function attempts to invoke the `/todo` slash command using `bash -c '/todo'`, which fails because slash commands are markdown files processed by Claude Code via the SlashCommand tool, not bash executables. This architectural mismatch causes silent failures across 9 commands that rely on automatic TODO.md updates.

**Goal**: Remove the broken automatic update mechanism, provide clear user guidance through completion reminders, and document the manual `/todo` workflow.

## Research Summary

Based on the research analysis:

**Root Cause**: Bash blocks in slash commands cannot invoke other slash commands - architectural constraint of Claude Code runtime.

**Failed Attempts**: Three previous specifications (991, 997, 015) attempted fixes but never addressed the core invocation issue, only improving error handling and documentation around the broken pattern.

**Solution Rationale**: Rather than fighting architectural constraints with complex workarounds (agent delegation, signal systems, marker files), the research recommends removing automatic updates and making the manual workflow explicit and obvious through enhanced visibility.

**Key Finding**: The function always returns success (0) regardless of outcome, making failures invisible. Combined with stderr suppression in calling commands, users never see warnings about failed updates.

## Success Criteria

- [ ] All 9 commands successfully remove `trigger_todo_update()` calls without breaking
- [ ] All 9 commands display clear reminder to run `/todo` after completion
- [ ] `trigger_todo_update()` function completely removed from `todo-functions.sh`
- [ ] No remaining references to `trigger_todo_update` in codebase (verified via grep)
- [ ] Updated tests pass (trigger_todo_update tests removed, manual workflow tests added)
- [ ] Documentation updated with manual workflow guidance
- [ ] Manual `/todo` workflow tested end-to-end on all 9 commands
- [ ] TODO.md no longer auto-updates after commands (expected behavior)
- [ ] Users receive actionable next-step guidance in all command completion outputs

## Technical Design

### Architecture

**Current (Broken)**:
```
Command → trigger_todo_update() → bash -c '/todo' → FAILS (not executable)
                                   ↓
                              Silent failure (suppressed)
                                   ↓
                              Returns success anyway
```

**New (Honest)**:
```
Command → Completion Summary → Reminder: "Run /todo to update TODO.md"
                                   ↓
                              User runs /todo manually
                                   ↓
                              TODO.md updated correctly
```

### Affected Components

**9 Commands** (all must be updated):
1. `/build` - 2 invocation points (start, completion)
2. `/plan` - 1 invocation point (after plan creation)
3. `/implement` - 2 invocation points (start, completion)
4. `/revise` - 1 invocation point (after revision)
5. `/research` - 1 invocation point (after report creation)
6. `/repair` - 1 invocation point (after repair plan)
7. `/errors` - 1 invocation point (after error analysis)
8. `/debug` - 2 invocation points (after debug report)
9. `/test` - 1 invocation point (after test completion)

**Library**: `.claude/lib/todo/todo-functions.sh`
- Remove `trigger_todo_update()` function definition (lines 1112-1132)
- Remove export statement (line 1471)

**Documentation**:
- `.claude/lib/todo/README.md` - Update function list
- `.claude/docs/guides/development/command-todo-integration-guide.md` - Document new pattern

**Tests**:
- `.claude/tests/lib/test_todo_functions.sh` - Remove trigger_todo_update tests
- Add integration tests for manual workflow

### Reminder Pattern

**Standardized completion reminder** (add to all 9 commands):
```bash
echo ""
echo "📋 Next Step: Run /todo to update TODO.md with this ${ARTIFACT_TYPE}"
echo ""
```

**Integrated in Next Steps section**:
```bash
NEXT_STEPS="  • Review ${ARTIFACT_TYPE}: cat ${ARTIFACT_PATH}
  • Run /todo to update TODO.md (adds ${ARTIFACT_TYPE} to tracking)
  • ${COMMAND_SPECIFIC_NEXT_STEP}"
```

### Clean-Break Approach

Per Clean-Break Development Standard (CLAUDE.md):
- **No deprecation period**: This is internal tooling, immediate removal appropriate
- **No compatibility wrappers**: Function completely removed, not stubbed
- **Atomic migration**: All 9 commands updated in single phase
- **Documentation updated simultaneously**: No references to old pattern remain

## Implementation Phases

### Phase 1: Remove trigger_todo_update() from Commands [COMPLETE]
dependencies: []

**Objective**: Remove all `trigger_todo_update()` invocations and related sourcing from 9 commands, replace with completion reminders

**Complexity**: Medium

**Tasks**:
- [x] Update `/build` command (file: `.claude/commands/build.md`)
  - Remove trigger_todo_update() call at line 347 (start checkpoint)
  - Remove trigger_todo_update() call at line 1061 (completion checkpoint)
  - Add reminder in both completion summaries
- [x] Update `/plan` command (file: `.claude/commands/plan.md`)
  - Remove trigger_todo_update() call at line 1508
  - Add reminder in completion summary
- [x] Update `/implement` command (file: `.claude/commands/implement.md`)
  - Remove trigger_todo_update() call at line 346 (start checkpoint)
  - Remove trigger_todo_update() call at line 1058 (completion checkpoint)
  - Add reminder in both completion summaries
- [x] Update `/revise` command (file: `.claude/commands/revise.md`)
  - Remove trigger_todo_update() call at line 1292
  - Add reminder in completion summary
- [x] Update `/research` command (file: `.claude/commands/research.md`)
  - Remove trigger_todo_update() call at line 1235
  - Add reminder in completion summary
- [x] Update `/repair` command (file: `.claude/commands/repair.md`)
  - Remove trigger_todo_update() call at line 1460
  - Add reminder in completion summary
- [x] Update `/errors` command (file: `.claude/commands/errors.md`)
  - Remove trigger_todo_update() calls at lines 723-724
  - Add reminder in completion summary
- [x] Update `/debug` command (file: `.claude/commands/debug.md`)
  - Remove trigger_todo_update() call at line 1485
  - Remove trigger_todo_update() call at line 1488
  - Add reminder in completion summary
- [x] Update `/test` command (file: `.claude/commands/test.md`)
  - Locate trigger_todo_update() invocation point
  - Remove invocation
  - Add reminder in completion summary
- [x] Verify pattern consistency across all commands (same reminder wording)

**Pattern to Remove**:
```bash
# Source todo-functions.sh for trigger_todo_update()
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
  echo "WARNING: Failed to source todo-functions.sh for TODO.md update" >&2
}

# Trigger TODO.md update (non-blocking)
if type trigger_todo_update &>/dev/null; then
  trigger_todo_update "reason description"
fi
```

**Pattern to Add**:
```bash
# Emit completion reminder
echo ""
echo "📋 Next Step: Run /todo to update TODO.md with this plan/report"
echo ""
```

**Testing**:
```bash
# Verify each command runs without errors
for cmd in build plan implement revise research repair errors debug test; do
  echo "Testing /$cmd command..."
  grep -q "trigger_todo_update" ".claude/commands/${cmd}.md" && echo "ERROR: Found trigger_todo_update in $cmd" || echo "✓ $cmd clean"
done

# Verify reminder present in each command
for cmd in build plan implement revise research repair errors debug test; do
  grep -q "Run /todo to update TODO.md" ".claude/commands/${cmd}.md" && echo "✓ $cmd has reminder" || echo "ERROR: Missing reminder in $cmd"
done
```

**Expected Duration**: 2 hours

### Phase 2: Remove trigger_todo_update() Function from Library [COMPLETE]
dependencies: [1]

**Objective**: Remove function definition and export from todo-functions.sh, eliminating the broken implementation

**Complexity**: Low

**Tasks**:
- [x] Remove `trigger_todo_update()` function definition (file: `.claude/lib/todo/todo-functions.sh`, lines 1112-1132)
- [x] Remove `export -f trigger_todo_update` statement (file: `.claude/lib/todo/todo-functions.sh`, line 1471)
- [x] Verify no other functions in library depend on trigger_todo_update()
- [x] Update library file header comment to reflect function removal
- [x] Run shellcheck on modified library file to ensure no syntax errors

**Testing**:
```bash
# Verify function completely removed
grep -n "trigger_todo_update" .claude/lib/todo/todo-functions.sh && echo "ERROR: Function still present" || echo "✓ Function removed"

# Verify library still sources without errors
source .claude/lib/todo/todo-functions.sh 2>&1 | grep -i error && echo "ERROR: Sourcing failed" || echo "✓ Library sources successfully"

# Verify shellcheck passes
shellcheck .claude/lib/todo/todo-functions.sh || echo "WARNING: Shellcheck issues detected"
```

**Expected Duration**: 0.5 hours

### Phase 3: Update Tests [COMPLETE]
dependencies: [2]

**Objective**: Remove tests for trigger_todo_update(), add tests for manual workflow verification

**Complexity**: Low

**Tasks**:
- [x] Remove trigger_todo_update() unit tests (file: `.claude/tests/lib/test_todo_functions.sh`)
  - Remove `test_trigger_todo_update_success` test
  - Remove `test_trigger_todo_update_failure_graceful` test
- [x] Add integration test for manual workflow (file: `.claude/tests/integration/test_manual_todo_workflow.sh`)
  - Test: TODO.md NOT auto-updated after command execution
  - Test: Reminder message printed in command output
  - Test: Manual `/todo` invocation updates TODO.md correctly
- [x] Add regression test for no remaining references (file: `.claude/tests/integration/test_trigger_todo_removal.sh`)
  - Test: grep finds no "trigger_todo_update" in commands/
  - Test: grep finds no "trigger_todo_update" in tests/
  - Test: All commands execute without sourcing todo-functions.sh for this purpose
- [x] Run full test suite to verify no breaking changes
- [x] Update test documentation with new test descriptions

**Testing**:
```bash
# Run updated tests
bash .claude/tests/lib/test_todo_functions.sh

# Run new integration tests
bash .claude/tests/integration/test_manual_todo_workflow.sh
bash .claude/tests/integration/test_trigger_todo_removal.sh

# Verify no test failures
echo "All tests must pass for phase completion"
```

**Expected Duration**: 1 hour

### Phase 4: Update Documentation [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Update all documentation to reflect manual /todo workflow and removal of automatic updates

**Complexity**: Low

**Tasks**:
- [x] Update library README (file: `.claude/lib/todo/README.md`)
  - Remove trigger_todo_update() from exported functions list
  - Add section: "Manual TODO.md Update Workflow"
  - Document when users should run /todo
  - Add troubleshooting section for stale TODO.md
- [x] Update integration guide (file: `.claude/docs/guides/development/command-todo-integration-guide.md`)
  - Remove all references to trigger_todo_update() pattern
  - Document new completion reminder pattern
  - Add migration guide for command authors
  - Update all code examples to show manual workflow
  - Add "Why No Automatic Updates" section explaining architectural constraints
- [x] Update command documentation (if command-specific docs exist)
  - Search for any command-specific docs mentioning TODO.md updates
  - Update to reflect manual workflow
- [x] Add entry to CHANGELOG (file: `.claude/CHANGELOG.md` or equivalent)
  - Document breaking change (removal of auto-updates)
  - Provide migration guidance for users
  - Reference this specification

**Testing**:
```bash
# Verify no documentation still references trigger_todo_update()
grep -r "trigger_todo_update" .claude/docs/ && echo "ERROR: Docs still reference function" || echo "✓ Docs updated"

# Verify new pattern documented
grep -r "Run /todo to update TODO.md" .claude/docs/ || echo "WARNING: Manual pattern not documented"

# Verify all markdown files are valid
find .claude/docs -name "*.md" -exec markdown-lint {} \;
```

**Expected Duration**: 1 hour

### Phase 5: End-to-End Testing and Validation [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Validate complete removal of trigger_todo_update(), verify manual workflow across all commands, ensure no regressions

**Complexity**: Medium

**Tasks**:
- [x] Test each of 9 commands individually
  - Run command with test input
  - Verify completion reminder printed
  - Verify TODO.md NOT auto-updated
  - Manually run /todo
  - Verify TODO.md correctly updated with command artifact
- [x] Run comprehensive grep search for any remaining references
  - Search commands/ directory
  - Search lib/ directory
  - Search tests/ directory
  - Search docs/ directory
- [x] Run full test suite
  - Execute all unit tests
  - Execute all integration tests
  - Verify 100% pass rate
- [x] Run validation scripts
  - bash .claude/scripts/validate-all-standards.sh --all
  - Verify no ERROR-level violations
- [x] Perform manual workflow testing
  - Create plan with /plan
  - Observe reminder
  - Run /todo
  - Verify plan in TODO.md
  - Repeat for other command types (research, debug, etc.)
- [x] Document any edge cases discovered during testing

**Testing**:
```bash
# Comprehensive reference search
echo "=== Searching for trigger_todo_update references ==="
grep -r "trigger_todo_update" .claude/commands/ && echo "ERROR: Found in commands" || echo "✓ Clean: commands"
grep -r "trigger_todo_update" .claude/lib/ && echo "ERROR: Found in lib" || echo "✓ Clean: lib"
grep -r "trigger_todo_update" .claude/tests/ && echo "ERROR: Found in tests" || echo "✓ Clean: tests"
grep -r "trigger_todo_update" .claude/docs/ && echo "ERROR: Found in docs" || echo "✓ Clean: docs"

# Full test suite
bash .claude/tests/run-all-tests.sh || echo "ERROR: Test failures detected"

# Standards validation
bash .claude/scripts/validate-all-standards.sh --all || echo "ERROR: Standards violations detected"

# Manual workflow end-to-end test
echo "=== Manual Workflow Test ==="
# (Execute manual test steps and verify TODO.md updates)
```

**Expected Duration**: 1.5 hours

## Testing Strategy

### Unit Tests
- Remove trigger_todo_update() specific tests from test_todo_functions.sh
- Verify library sources without errors after function removal
- Ensure no other library functions depend on removed function

### Integration Tests
- Test that commands execute without calling trigger_todo_update()
- Verify TODO.md remains unchanged after command execution (expected behavior)
- Test that reminder messages appear in command output
- Verify manual /todo invocation updates TODO.md correctly
- Test grep finds no remaining references to trigger_todo_update

### Regression Tests
- Run full test suite to ensure no command breakage
- Validate all 9 commands execute successfully without auto-update mechanism
- Verify standards compliance (sourcing patterns, output formatting)
- Check that completion summaries include reminder in correct format

### Manual Testing
- Execute each command type (/plan, /research, /debug, /build, etc.)
- Verify reminder appears in output
- Confirm TODO.md does NOT auto-update
- Run /todo manually
- Verify TODO.md correctly reflects new artifact

## Documentation Requirements

### Files to Update
1. **Library README** (`.claude/lib/todo/README.md`)
   - Remove trigger_todo_update() from function list
   - Add manual workflow documentation
   - Document migration path

2. **Integration Guide** (`.claude/docs/guides/development/command-todo-integration-guide.md`)
   - Complete rewrite of TODO.md update pattern
   - Remove all trigger_todo_update() examples
   - Add completion reminder pattern examples
   - Explain architectural constraints (why no auto-update)

3. **Command Documentation** (command-specific if exists)
   - Update any command docs that mention TODO.md updates
   - Ensure consistency with new manual pattern

4. **CHANGELOG**
   - Document breaking change
   - Provide user migration guidance
   - Link to this specification for details

### Documentation Standards Compliance
- Follow markdown format from CLAUDE.md Documentation Policy
- Use clear, concise language
- Include code examples with syntax highlighting
- No historical commentary (per Writing Standards)
- Update examples to reflect current implementation
- Remove any references to removed functionality

## Dependencies

### Internal Dependencies
- All 9 commands must be updated atomically (Phase 1)
- Library function removal must happen after command updates (Phase 2 depends on Phase 1)
- Tests must be updated after library changes (Phase 3 depends on Phase 2)
- Documentation must reflect actual implementation (Phase 4 depends on all previous phases)

### External Dependencies
- None (self-contained refactor within .claude/ directory)

### File Dependencies
- Commands depend on library sourcing (three-tier pattern from Code Standards)
- Tests depend on command implementation
- Documentation depends on actual implementation patterns

## Risk Assessment

### Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Users forget to run /todo | Medium | Low | Clear reminders in all command outputs, document in Next Steps |
| TODO.md becomes stale | Medium | Low | Fast /todo execution, clear documentation on when to run |
| Commands break during refactor | Low | Medium | Comprehensive testing, staged rollout, verify each command individually |
| Missing trigger_todo_update references | Low | Low | Exhaustive grep search, regression tests, validation scripts |
| Test suite failures | Low | High | Run tests incrementally per phase, fix issues before proceeding |

### Breaking Changes

**User-Facing**:
- TODO.md no longer auto-updates after command execution
- Users must manually run `/todo` to refresh TODO.md
- This is one additional step in workflow

**Developer-Facing**:
- `trigger_todo_update()` function no longer exists in todo-functions.sh
- Commands no longer source todo-functions.sh for TODO.md updates
- Integration pattern changed from function call to reminder message

**Mitigation**:
- Comprehensive documentation updates
- Clear migration guide in CHANGELOG
- Reminders visible in every command completion
- Fast /todo execution keeps manual step minimal

## Notes

### Why This Approach

The research analysis evaluated multiple alternatives:
1. **SlashCommand tool invocation**: Not viable - tool only available to Claude, not bash
2. **Duplicate TODO.md logic in bash**: Violates single source of truth principle
3. **Agent delegation**: Still requires Claude context, not available in bash blocks
4. **Callback/signal pattern**: Requires Claude Code runtime changes (out of scope)
5. **Helper script with markers**: Adds complexity for minimal benefit

**Selected approach** (remove auto-update, add reminders) is the most honest, maintainable solution that respects architectural constraints while maintaining usability through enhanced visibility.

### Future Enhancement Possibility

If Claude Code runtime is modified to support signal-based command invocation (callback pattern), this could be revisited. However, current architecture makes automatic TODO.md updates from bash blocks impossible without architectural changes to Claude Code itself.

### Complexity Score Justification

```
Score = Base(feature type) + Tasks/2 + Files*3 + Integrations*5

Where:
- Base: refactor = 5
- Tasks: 35 tasks / 2 = 17.5
- Files: 9 commands + 1 library + 4 docs + 3 tests = 17 files * 3 = 51... wait, recalculating

Actually using simpler formula from research:
score = (tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)
score = (35 × 1.0) + (5 × 5.0) + (6 × 0.5) + (3 × 2.0)
score = 35 + 25 + 3 + 6 = 69

However, given the scope:
- Relatively straightforward refactor (remove broken pattern)
- No complex logic changes
- Main complexity is ensuring all 9 commands updated correctly
- Testing is comprehensive but not difficult

Adjusted estimate: ~47.5 (Medium complexity, Tier 1 - single file plan appropriate)
```

### Alignment with Clean-Break Development Standard

This plan fully adheres to Clean-Break Development Standard:
- **No deprecation period**: Function immediately removed (internal tooling)
- **No compatibility wrappers**: No stub or shim function left behind
- **Atomic migration**: All commands updated in single phase
- **Documentation simultaneous**: Updated in same specification
- **No historical commentary**: Documentation reflects current state only

This is the correct approach per CLAUDE.md standards for internal tooling changes.

## Estimated Hours Breakdown

- Phase 1 (Command updates): 2 hours
- Phase 2 (Library cleanup): 0.5 hours
- Phase 3 (Test updates): 1 hour
- Phase 4 (Documentation): 1 hour
- Phase 5 (E2E validation): 1.5 hours
- **Total**: 6 hours (conservative estimate with buffer)

## Next Steps After Plan Approval

1. Review plan for completeness and accuracy
2. Execute Phase 1: Update all 9 commands
3. Execute Phase 2: Remove function from library
4. Execute Phase 3: Update test suite
5. Execute Phase 4: Update documentation
6. Execute Phase 5: Comprehensive validation
7. Run /todo to update TODO.md with completed plan
