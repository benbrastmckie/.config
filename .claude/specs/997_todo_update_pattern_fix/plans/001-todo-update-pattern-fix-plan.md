# TODO.md Update Pattern Fix - Implementation Plan

## Metadata
- **Date**: 2025-12-01
- **Feature**: Fix broken TODO.md update pattern across 5 commands
- **Scope**: Replace silent-fail bash execution pattern with trigger_todo_update() delegation pattern in /plan, /build, /implement, /revise, and /research commands
- **Estimated Phases**: 6
- **Estimated Hours**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 35.0
- **Structure Level**: 0
- **Research Reports**:
  - [TODO Update Pattern Analysis](../reports/001-todo-update-pattern-analysis.md)

---

## Overview

The TODO.md update mechanism has an inconsistency where 5 commands use a broken pattern that silently fails, while 3 commands (/repair, /errors, /debug) use the correct `trigger_todo_update()` function from todo-functions.sh.

**Root Cause**: The broken pattern attempts to execute a markdown file with bash:
```bash
bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true
```

This fails because:
1. `.claude/commands/todo.md` is markdown, not executable
2. All errors are suppressed with `2>/dev/null || true`
3. Success message prints regardless of actual outcome

**Correct Pattern**: Use the `trigger_todo_update()` function:
```bash
trigger_todo_update "descriptive reason"
```

---

## Success Criteria
- [ ] All 5 commands (/plan, /build, /implement, /revise, /research) update TODO.md successfully
- [ ] No silent failures - all errors produce visible warnings
- [ ] Backlog and Saved sections preserved across updates
- [ ] trigger_todo_update() called with descriptive reason in each command
- [ ] New plans/research/builds appear in TODO.md immediately after creation
- [ ] Parent commands continue execution despite TODO update failures (non-blocking)

---

## Technical Design

### Architecture Overview

The fix uses delegation to the existing `trigger_todo_update()` function in `todo-functions.sh` (lines 1113-1133). This function:
1. Sources the todo-analyzer agent
2. Executes TODO.md regeneration
3. Logs warnings on failure (non-blocking)
4. Returns 0 regardless of outcome (parent command continues)

### Component Interaction

```
Command (e.g., /plan)
    │
    ▼
trigger_todo_update("plan created")
    │
    ▼
todo-analyzer agent
    │
    ▼
TODO.md updated
```

### Pattern Replacement

**Before** (broken):
```bash
bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true
echo "✓ Updated TODO.md"
```

**After** (working):
```bash
trigger_todo_update "descriptive reason"
```

---

## Implementation Phases

### Phase 1: Fix /plan Command [COMPLETE]
dependencies: []

**Objective**: Replace broken pattern in /plan command with trigger_todo_update() delegation

**Complexity**: Low

**Tasks**:
- [x] Verify todo-functions.sh is already sourced in plan.md
- [x] Replace broken pattern at line ~1509 with `trigger_todo_update "plan created"`
- [x] Remove the redundant "✓ Updated TODO.md" echo line
- [x] Test `/plan` with test description

**Affected File**:
- `.claude/commands/plan.md` (line 1508-1509)

**Testing**:
```bash
# Run /plan with test description
/plan "test feature for TODO update verification"

# Verify plan appears in TODO.md
grep -l "test feature" .claude/TODO.md

# Verify warning appears if TODO update fails (simulate by moving todo-functions.sh temporarily)
```

**Expected Duration**: 0.5 hours

---

### Phase 2: Fix /build Command [COMPLETE]
dependencies: [1]

**Objective**: Replace broken pattern in /build command with trigger_todo_update() delegation

**Complexity**: Low

**Tasks**:
- [x] Verify todo-functions.sh is already sourced in build.md
- [x] Replace broken pattern at line ~347 with `trigger_todo_update "build phase started"`
- [x] Replace broken pattern at line ~1061 with `trigger_todo_update "build phase completed"`
- [x] Remove redundant "✓ Updated TODO.md" echo lines
- [x] Test `/build` on existing plan

**Affected File**:
- `.claude/commands/build.md` (lines 347, 1061)

**Testing**:
```bash
# Run /build on existing plan
/build .claude/specs/997_todo_update_pattern_fix/plans/001-todo-update-pattern-fix-plan.md

# Verify TODO.md reflects build progress
grep -l "997_todo_update" .claude/TODO.md
```

**Expected Duration**: 0.5 hours

---

### Phase 3: Fix /implement Command [COMPLETE]
dependencies: [1]

**Objective**: Replace broken pattern in /implement command with trigger_todo_update() delegation

**Complexity**: Low

**Tasks**:
- [x] Verify todo-functions.sh is already sourced in implement.md
- [x] Replace broken pattern at line ~346 with `trigger_todo_update "implementation phase started"`
- [x] Replace broken pattern at line ~1058 with `trigger_todo_update "implementation phase completed"`
- [x] Remove redundant "✓ Updated TODO.md" echo lines
- [x] Test `/implement` on existing plan

**Affected File**:
- `.claude/commands/implement.md` (lines 346, 1058)

**Testing**:
```bash
# Run /implement on existing plan
/implement .claude/specs/997_todo_update_pattern_fix/plans/001-todo-update-pattern-fix-plan.md

# Verify TODO.md reflects implementation progress
grep -l "997_todo_update" .claude/TODO.md
```

**Expected Duration**: 0.5 hours

---

### Phase 4: Fix /revise Command [COMPLETE]
dependencies: [1]

**Objective**: Replace broken pattern in /revise command with trigger_todo_update() delegation

**Complexity**: Low

**Tasks**:
- [x] Verify todo-functions.sh is already sourced in revise.md
- [x] Replace broken pattern at line ~1292 with `trigger_todo_update "plan revised"`
- [x] Remove redundant "✓ Updated TODO.md" echo line
- [x] Test `/revise` on existing plan

**Affected File**:
- `.claude/commands/revise.md` (line 1292)

**Testing**:
```bash
# Run /revise on existing plan
/revise ".claude/specs/997_todo_update_pattern_fix/plans/001-todo-update-pattern-fix-plan.md add additional testing step"

# Verify revised plan appears in TODO.md
grep -l "997_todo_update" .claude/TODO.md
```

**Expected Duration**: 0.5 hours

---

### Phase 5: Fix /research Command [COMPLETE]
dependencies: [1]

**Objective**: Replace broken pattern in /research command with trigger_todo_update() delegation

**Complexity**: Low

**Tasks**:
- [x] Verify todo-functions.sh is already sourced in research.md
- [x] Replace broken pattern at line ~1235 with `trigger_todo_update "research report created"`
- [x] Remove redundant "✓ Updated TODO.md" echo line
- [x] Test `/research` with test description

**Affected File**:
- `.claude/commands/research.md` (line 1235)

**Testing**:
```bash
# Run /research with test description
/research "test research for TODO update verification"

# Verify research report appears in TODO.md
grep -l "test research" .claude/TODO.md
```

**Expected Duration**: 0.5 hours

---

### Phase 6: Integration Testing [COMPLETE]
dependencies: [1, 2, 3, 4, 5]

**Objective**: Verify all commands integrate correctly with TODO.md update mechanism

**Complexity**: Medium

**Tasks**:
- [x] Test /plan → TODO.md integration (create new plan, verify appears in Not Started)
- [x] Test /build → TODO.md integration (run build, verify status updates)
- [x] Test /implement → TODO.md integration (run implement, verify phase progress)
- [x] Test /revise → TODO.md integration (revise plan, verify revision appears)
- [x] Test /research → TODO.md integration (create research, verify appears in Research section)
- [x] Test error handling (simulate failure, verify warning but non-blocking)
- [x] Test Backlog/Saved preservation (add manual entries, run command, verify preserved)

**Test Cases**:

1. **Test /plan → TODO.md integration**:
   - Create new plan with `/plan "test feature"`
   - Verify plan appears in TODO.md Not Started section
   - Verify plan entry has correct format with artifacts

2. **Test /build → TODO.md integration**:
   - Run `/build` on test plan
   - Verify plan status updates in TODO.md
   - Verify completion moves plan to Completed section

3. **Test /implement → TODO.md integration**:
   - Run `/implement` on test plan
   - Verify phase progress updates in TODO.md

4. **Test /revise → TODO.md integration**:
   - Run `/revise` on test plan
   - Verify revision appears in TODO.md

5. **Test /research → TODO.md integration**:
   - Run `/research "test analysis"`
   - Verify research entry appears in Research section

6. **Test error handling**:
   - Simulate TODO update failure (invalid permissions)
   - Verify warning message appears
   - Verify parent command continues execution (non-blocking)

7. **Test Backlog/Saved preservation**:
   - Add manual entries to Backlog and Saved sections
   - Run any command with TODO update
   - Verify manual entries preserved

**Testing**:
```bash
# Run full integration test suite
./run_all_tests.sh

# Or run specific TODO integration tests
bash .claude/tests/integration/test_todo_integration.sh
```

**Expected Duration**: 1.5 hours

---

## Testing Strategy

### Overall Test Approach

**Test Categories**:
1. **Unit Tests**: Verify trigger_todo_update() function behavior in isolation
2. **Integration Tests**: Verify each command's TODO.md update integration
3. **Error Handling Tests**: Verify non-blocking failure behavior
4. **Preservation Tests**: Verify Backlog/Saved sections preserved

**Test Commands**:
```bash
# Run full test suite
./run_all_tests.sh

# Run specific TODO function tests
bash .claude/tests/lib/test_todo_functions.sh

# Run integration tests
bash .claude/tests/integration/test_todo_integration.sh
```

**Coverage Requirements**:
- All 5 affected commands tested
- Both success and failure paths verified
- Backlog/Saved preservation confirmed

---

## Documentation Requirements

**Files to Update**:
- [ ] No new documentation required (using existing patterns)
- [ ] Update TODO.md after implementation to reflect completion

**Documentation Standards**:
- Follow existing documentation patterns from todo-organization-standards.md
- No new user-facing documentation needed (internal fix)

---

## Dependencies

### External Dependencies

**Library Requirements**:
- `todo-functions.sh` - Already sourced by all affected commands from prior refactors
- `trigger_todo_update()` function - Available at lines 1113-1133 of todo-functions.sh

**Pre-existing Working Patterns**:
- Working pattern from `/repair` (line 1460): `trigger_todo_update "repair plan created"`
- Working pattern from `/errors` (lines 723-724): `trigger_todo_update "error analysis complete"`
- Working pattern from `/debug` (lines 1485, 1488): `trigger_todo_update "debug plan created"`

### Prerequisites

- No blocking prerequisites - can begin implementation immediately
- todo-functions.sh library already verified working

---

## File Modifications Summary

| File | Lines | Change Description |
|------|-------|-------------------|
| `.claude/commands/plan.md` | ~1509 | Replace broken pattern with `trigger_todo_update "plan created"` |
| `.claude/commands/build.md` | ~347, ~1061 | Replace broken pattern with `trigger_todo_update "build phase completed"` |
| `.claude/commands/implement.md` | ~346, ~1058 | Replace broken pattern with `trigger_todo_update "implementation phase completed"` |
| `.claude/commands/revise.md` | ~1292 | Replace broken pattern with `trigger_todo_update "plan revised"` |
| `.claude/commands/research.md` | ~1235 | Replace broken pattern with `trigger_todo_update "research report created"` |

**Total Changes**: 5 files, 8 replacements

---

## Risk Assessment

**Risk Level**: Low

**Mitigations**:
1. **Silent failure elimination**: trigger_todo_update() logs warnings on failure
2. **Non-blocking design**: Update failures don't break parent commands (return 0)
3. **Pattern proven**: 3 commands already using this pattern successfully
4. **No core logic changes**: Only updating TODO.md integration mechanism
5. **Backwards compatible**: Existing TODO.md content preserved

**Rollback Strategy**:
- Simple revert of pattern changes
- No database/state changes required
- TODO.md can be manually regenerated with `/todo`

---

## References

- Research Report: [TODO Update Pattern Analysis](../reports/001-todo-update-pattern-analysis.md)
- TODO Functions Library: `.claude/lib/todo/todo-functions.sh`
- Working Examples: `.claude/commands/repair.md`, `.claude/commands/errors.md`, `.claude/commands/debug.md`
- Standards: `.claude/docs/reference/standards/todo-organization-standards.md`
- Prior Implementation: `.claude/specs/991_commands_todo_tracking_refactor/summaries/001-implementation-summary.md`
