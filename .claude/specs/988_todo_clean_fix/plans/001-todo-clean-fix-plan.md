# /todo --clean Bug Fix Implementation Plan

## Metadata
- **Date**: 2025-11-30
- **Feature**: Fix /todo --clean to fully remove eligible projects and update TODO.md
- **Scope**: Fix parser regex and add TODO.md regeneration after cleanup
- **Estimated Phases**: 4
- **Estimated Hours**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 28.0
- **Research Reports**:
  - [/todo --clean Command Failure Analysis](/home/benjamin/.config/.claude/specs/988_todo_clean_fix/reports/001-todo-clean-command-failure-analysis.md)

## Overview

The `/todo --clean` command has two critical bugs that prevent it from fully cleaning up completed/abandoned/superseded projects:

1. **Bug 1 - Incomplete Directory Removal**: The `parse_todo_sections()` function uses a greedy regex pattern that fails when TODO.md entries contain sub-bullets with markdown links. Only 39 of 107 eligible projects were removed in the most recent run.

2. **Bug 2 - Missing TODO.md Update**: Clean mode bypasses TODO.md generation blocks, leaving stale entries for deleted directories in the Completed, Abandoned, and Superseded sections.

This plan addresses both bugs to ensure `/todo --clean` completely removes all eligible project directories and updates TODO.md to reflect only active projects (In Progress, Not Started, Backlog).

## Research Summary

Research findings from the failure analysis report:

**Root Cause 1 - Parser Failures**:
- The regex pattern `'\[[^]]+\.md\]'` (line 790 in todo-functions.sh) is too greedy
- Matches incorrect brackets when entries have sub-bullets with markdown links
- Example failure: Entry with `[report1](path1.md)` in sub-bullet causes parser to extract wrong path
- Sub-bullet lines (indented with spaces) are processed by the main while loop, failing the entry check

**Root Cause 2 - Workflow Gap**:
- Clean mode (Block 4b) executes: parse → remove directories → completion summary
- Default mode (Blocks 3-4) executes: parse → generate TODO.md → write file → completion
- Clean mode completely bypasses TODO.md generation logic
- Design assumes manual `/todo` run after cleanup (undocumented, not automated)

**Evidence from Git History**:
- Commit 376f1d93: "pre-cleanup snapshot before /todo --clean (107 projects)"
- Commit 6f5bbb4c: "remove 106 completed/abandoned project directories"
- Commit e8162eb9: "pre-cleanup snapshot before /todo --clean (39 projects)"
- Only 39/107 removed in second run because parser skipped already-deleted directories

Recommended approach: Fix parser with anchored regex + skip indented lines, then add TODO.md regeneration after cleanup.

## Success Criteria

- [ ] `parse_todo_sections()` correctly extracts all eligible projects from TODO.md (100% accuracy)
- [ ] Parser ignores sub-bullet lines (indented with spaces)
- [ ] Parser uses anchored regex to match only `.claude/specs/` paths
- [ ] `/todo --clean` removes all eligible directories (no partial failures)
- [ ] TODO.md is automatically regenerated after cleanup
- [ ] TODO.md contains only In Progress, Not Started, and Backlog sections after cleanup
- [ ] All existing tests pass with new implementation
- [ ] New integration test verifies end-to-end cleanup workflow

## Technical Design

### Architecture Overview

**Current Clean Mode Workflow** (Buggy):
```
Block 1 (Setup) → Block 2a-c (Classification) → Block 4b (Cleanup) → Block 5 (Summary)
                                                      ↓
                                    parse_todo_sections() [BUGGY REGEX]
                                                      ↓
                                    execute_cleanup_removal()
                                                      ↓
                                    [TODO.md NOT UPDATED]
```

**Fixed Clean Mode Workflow**:
```
Block 1 (Setup) → Block 2a-c (Classification) → Block 4b (Cleanup) → Block 4c (Regenerate) → Block 5 (Summary)
                                                      ↓                        ↓
                                    parse_todo_sections() [FIXED]   todo-analyzer rescan
                                                      ↓                        ↓
                                    execute_cleanup_removal()      Generate TODO.md
                                                      ↓                        ↓
                                    [ALL DIRS REMOVED]           [STALE ENTRIES REMOVED]
```

### Component Changes

**File 1**: `.claude/lib/todo/todo-functions.sh` (lines 717-825)
- **Function**: `parse_todo_sections()`
- **Changes**:
  1. Line 773: Add sub-bullet filter before entry check
  2. Line 790: Replace greedy regex with anchored pattern
  3. Add validation logging for parsed entry count

**File 2**: `.claude/commands/todo.md` (lines 714-817)
- **Block**: Block 4b (Direct Cleanup Execution)
- **Changes**: No changes (cleanup logic is correct)

**File 3**: `.claude/commands/todo.md` (insert after Block 4b)
- **Block**: New Block 4c (Regenerate TODO.md After Cleanup)
- **Changes**: Add todo-analyzer rescan and TODO.md generation

**File 4**: `.claude/commands/todo.md` (lines 819-896)
- **Block**: Block 5 (Completion Summary)
- **Changes**: Update summary to reflect TODO.md update

### Parser Fix Details

**Current regex (greedy, fails on sub-bullets)**:
```bash
# Line 790 - Matches ANY brackets with .md inside
plan_path=$(echo "$line" | grep -oE '\[[^]]+\.md\]' | tail -1 | tr -d '[]')
```

**Fixed regex (anchored to .claude/specs/ paths)**:
```bash
# Anchored pattern matches only plan paths starting with .claude/specs/
plan_path=$(echo "$line" | grep -oE '\[\.claude/specs/[^]]+\.md\]' | tail -1 | tr -d '[]')
```

**Sub-bullet filter**:
```bash
# Line 773 - Skip lines starting with whitespace (sub-bullets)
while IFS= read -r line; do
  # Skip sub-bullets (indented lines)
  [[ "$line" =~ ^[[:space:]] ]] && continue

  # Process main entry lines
  if echo "$line" | grep -qE '^- \[[x~]\] \*\*'; then
```

### TODO.md Regeneration Strategy

After cleanup removes directories, run the same workflow as default mode:

1. **Rescan projects**: Call `scan_project_directories()` to find remaining specs/
2. **Classify plans**: Already done in Block 2b (todo-analyzer)
3. **Generate TODO.md**: Reuse existing TODO.md generation logic (Blocks 3-4)
4. **Result**: TODO.md contains only existing projects, stale entries removed

**Implementation approach**: Instead of duplicating Blocks 3-4 code, add a new Block 4c that calls the todo-analyzer again with updated project list, then writes TODO.md.

## Implementation Phases

### Phase 1: Fix parse_todo_sections() Regex [COMPLETE]
dependencies: []

**Objective**: Fix parser to correctly extract all eligible projects from TODO.md entries with sub-bullets

**Complexity**: Low

Tasks:
- [x] Update line 773 in `.claude/lib/todo/todo-functions.sh` to skip indented lines (sub-bullets)
- [x] Update line 790 to use anchored regex pattern `\[\.claude/specs/[^]]+\.md\]`
- [x] Add validation logging after JSON array construction (log parsed count)
- [x] Verify regex matches plan paths in brackets: `[.claude/specs/NNN_topic/plans/001.md]`
- [x] Verify sub-bullet filter skips lines matching `^[[:space:]]`

Testing:
```bash
# Test with sample TODO.md containing sub-bullets
cat > /tmp/test_todo.md <<'EOF'
## Completed

- [x] **Test Project 1** - Description [.claude/specs/001_test/plans/001.md]
  - Sub-bullet with [link](path.md)
- [x] **Test Project 2** - Description [.claude/specs/002_test/plans/001.md]

## Abandoned

- [x] **Test Project 3** - Description [.claude/specs/003_test/plans/001.md]
  - Multiple sub-bullets
  - With [links](a.md) and [more](b.md)
EOF

# Source library and test parser
source .claude/lib/todo/todo-functions.sh
RESULT=$(parse_todo_sections /tmp/test_todo.md)
COUNT=$(echo "$RESULT" | jq 'length')

# Verify: Should parse exactly 3 projects
echo "Expected: 3 projects"
echo "Actual: $COUNT projects"
[ "$COUNT" -eq 3 ] && echo "PASS" || echo "FAIL"
```

**Expected Duration**: 1 hour

### Phase 2: Add TODO.md Regeneration Block [COMPLETE]
dependencies: []

**Objective**: Add Block 4c to regenerate TODO.md after cleanup removes directories

**Complexity**: Medium

Tasks:
- [x] Insert new Block 4c after Block 4b (line ~817) in `.claude/commands/todo.md`
- [x] Add bash block that rescans projects with `scan_project_directories()`
- [x] Call todo-analyzer subagent to classify remaining projects
- [x] Generate TODO.md using existing TODO.md generation logic (from Block 3)
- [x] Write TODO.md file using existing write logic (from Block 4)
- [x] Preserve Backlog section during regeneration (use `extract_backlog_section()`)
- [x] Update state persistence to include TODO_PATH variable

Testing:
```bash
# Create test scenario with eligible projects
mkdir -p .claude/specs/999_test_cleanup/plans
echo "# Test Plan" > .claude/specs/999_test_cleanup/plans/001.md

# Add entry to TODO.md Completed section
cat >> .claude/TODO.md <<'EOF'

## Completed

- [x] **Test cleanup project** [.claude/specs/999_test_cleanup/plans/001.md]
EOF

# Run cleanup
/todo --clean --dry-run

# Verify TODO.md regenerated without deleted entry
grep "999_test_cleanup" .claude/TODO.md
# Should return nothing after cleanup
```

**Expected Duration**: 1.5 hours

### Phase 3: Update Block 5 Summary Output [COMPLETE]
dependencies: [2]

**Objective**: Update completion summary to report TODO.md update

**Complexity**: Low

Tasks:
- [x] Update ARTIFACTS section in Block 5 (line ~876) to include TODO.md path
- [x] Add line: `📄 TODO.md: $TODO_PATH (updated)` to artifacts output
- [x] Update SUMMARY_TEXT to mention TODO.md regeneration
- [x] Update NEXT_STEPS to suggest reviewing TODO.md sections
- [x] Verify completion signal includes TODO.md update confirmation

Testing:
```bash
# Run cleanup and verify summary output
/todo --clean | tee /tmp/cleanup_output.txt

# Verify summary mentions TODO.md update
grep "TODO.md.*updated" /tmp/cleanup_output.txt || echo "FAIL: Summary missing TODO.md update"

# Verify artifacts section includes TODO.md path
grep "📄 TODO.md:" /tmp/cleanup_output.txt || echo "FAIL: Artifacts missing TODO.md"
```

**Expected Duration**: 0.5 hours

### Phase 4: Integration Testing and Validation [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Verify end-to-end cleanup workflow removes all eligible projects and updates TODO.md

**Complexity**: Medium

Tasks:
- [x] Create integration test in `.claude/tests/lib/test_todo_cleanup_integration.sh`
- [x] Test scenario 1: Cleanup with sub-bullet entries (verify all removed)
- [x] Test scenario 2: Cleanup with mixed sections (verify only eligible removed)
- [x] Test scenario 3: TODO.md verification (verify only In Progress/Not Started/Backlog remain)
- [x] Test scenario 4: Git commit verification (verify recovery command works)
- [x] Test scenario 5: Empty eligible projects (verify graceful handling)
- [x] Run existing todo-functions tests to verify no regressions
- [x] Update test documentation with new test coverage

Testing:
```bash
# Run integration tests
bash .claude/tests/lib/test_todo_cleanup_integration.sh

# Run existing todo-functions tests
bash .claude/tests/lib/test_todo_functions_cleanup.sh

# Verify all tests pass
echo "All tests passed: $(date)"
```

**Expected Duration**: 1 hour

## Testing Strategy

### Unit Testing

**Test File**: `.claude/tests/lib/test_todo_functions_cleanup.sh` (existing)
- Verify `parse_todo_sections()` with various entry formats
- Test sub-bullet filtering logic
- Test anchored regex pattern matching
- Verify validation logging output

**Test File**: `.claude/tests/lib/test_todo_cleanup_integration.sh` (new)
- End-to-end cleanup workflow testing
- TODO.md regeneration verification
- Git commit and recovery testing

### Test Scenarios

1. **Parser Accuracy Test**:
   - Input: TODO.md with 10 entries containing sub-bullets and markdown links
   - Expected: Parser extracts all 10 project paths correctly
   - Validation: Compare parsed count to expected count

2. **TODO.md Regeneration Test**:
   - Input: TODO.md with 50 Completed entries pointing to existing directories
   - Action: Run `/todo --clean`
   - Expected: All 50 directories removed, TODO.md Completed section empty
   - Validation: `grep -c "^## Completed" -A 100 .claude/TODO.md` shows 0 entries

3. **Backlog Preservation Test**:
   - Input: TODO.md with 5 Backlog entries (manually curated)
   - Action: Run `/todo --clean`
   - Expected: Backlog section unchanged after cleanup
   - Validation: Compare Backlog section before/after cleanup

4. **Git Recovery Test**:
   - Action: Run `/todo --clean`, note commit hash
   - Validation: Run `git revert $COMMIT_HASH`, verify projects restored

### Success Criteria Validation

Each success criterion maps to specific test cases:

- **100% parser accuracy**: Unit test with 20 diverse entry formats
- **Sub-bullet filtering**: Unit test with entries having 0-5 sub-bullets
- **Anchored regex**: Unit test with entries containing multiple bracket pairs
- **All dirs removed**: Integration test comparing eligible count to removed count
- **TODO.md regenerated**: Integration test verifying file modification timestamp
- **Only active sections**: Integration test grepping for Completed/Abandoned/Superseded entries
- **Existing tests pass**: Run existing test suite
- **New integration test**: Create and run new test file

## Documentation Requirements

### Files to Update

1. **`.claude/commands/todo.md`**:
   - Update "Clean Mode" section (lines ~618-650) to document TODO.md regeneration
   - Add note: "After cleanup, TODO.md is automatically regenerated to reflect current filesystem state"
   - Remove old caveat: "TODO.md is NOT modified during cleanup"

2. **`.claude/lib/todo/todo-functions.sh`**:
   - Update `parse_todo_sections()` docstring to document sub-bullet filtering
   - Update regex pattern documentation to explain anchored matching

3. **`.claude/docs/guides/commands/todo-command-guide.md`** (if exists):
   - Update cleanup workflow documentation
   - Add section on TODO.md regeneration behavior
   - Document expected sections after cleanup

4. **`.claude/tests/lib/test_todo_cleanup_integration.sh`** (new):
   - Add comprehensive docstring explaining test scenarios
   - Document expected behavior for each test case

### Documentation Standards

Following CLAUDE.md documentation policy:
- Update existing documentation (don't create new files unless needed)
- Remove historical commentary from updated sections
- Use clear, concise language with code examples
- Document the "what" not the "why" in code comments

## Dependencies

### External Dependencies
None - all changes are internal to .claude/ system

### Internal Dependencies

**Library Dependencies**:
- `.claude/lib/core/state-persistence.sh` (already used by Block 4b)
- `.claude/lib/todo/todo-functions.sh` (modified in this plan)
- `.claude/agents/todo-analyzer.md` (invoked for TODO.md regeneration)

**Function Dependencies**:
- `parse_todo_sections()` - Modified in Phase 1
- `execute_cleanup_removal()` - No changes (correct implementation)
- `scan_project_directories()` - Used in Block 4c for rescan
- `extract_backlog_section()` - Used in Block 4c to preserve Backlog

**Data Dependencies**:
- State variables from Block 4b: `REMOVED_COUNT`, `SKIPPED_COUNT`, `FAILED_COUNT`, `COMMIT_HASH`
- New state variable for Block 4c: `TODO_PATH`

### Phase Dependencies

Phase dependencies enable parallel execution:
- Phases 1 and 2 can run in parallel (independent changes)
- Phase 3 depends on Phase 2 (needs TODO_PATH variable)
- Phase 4 depends on all phases (integration testing)

## Rollback Strategy

### Git-Based Rollback

If implementation causes issues:

```bash
# Create backup before starting
git checkout -b backup/todo-clean-fix-$(date +%Y%m%d)
git commit -am "Backup before /todo --clean fix implementation"

# If rollback needed
git checkout main
git revert <commit-range>
```

### File-Level Rollback

Critical files to backup before changes:
- `.claude/lib/todo/todo-functions.sh`
- `.claude/commands/todo.md`

```bash
# Backup before implementation
cp .claude/lib/todo/todo-functions.sh{,.backup}
cp .claude/commands/todo.md{,.backup}

# Restore if needed
cp .claude/lib/todo/todo-functions.sh{.backup,}
cp .claude/commands/todo.md{.backup,}
```

### Testing Rollback

If tests fail after implementation:
1. Run existing test suite to identify breaking changes
2. Review git diff to isolate problematic changes
3. Use `git checkout <file>` to revert specific files
4. Re-run tests to verify fix

## Risk Assessment

### Low Risk Changes
- Parser regex fix (isolated function, well-tested)
- Sub-bullet filtering (simple pattern match)
- Summary output updates (cosmetic changes)

### Medium Risk Changes
- TODO.md regeneration block (new workflow step)
  - Mitigation: Extensive integration testing
  - Mitigation: Preserve Backlog section explicitly
- State persistence updates (new variables)
  - Mitigation: Test state restoration in Block 5

### High Risk Changes
None - all changes are incremental improvements to existing workflow

### Failure Modes

**Failure Mode 1**: Parser still misses some entries
- Detection: Integration test comparing eligible count to parsed count
- Mitigation: Add debug logging to identify failing entries
- Recovery: Enhance regex pattern based on debug output

**Failure Mode 2**: TODO.md regeneration corrupts Backlog section
- Detection: Backlog preservation test
- Mitigation: Use `extract_backlog_section()` before regeneration
- Recovery: Restore TODO.md from git history

**Failure Mode 3**: State persistence fails between blocks
- Detection: Block 5 missing variables (empty summary)
- Mitigation: Add state validation in Block 5
- Recovery: Exit gracefully with error message

## Performance Considerations

### Expected Performance Impact

**Parser Fix** (Phase 1):
- Current performance: ~50ms for 200 entries
- Expected performance: ~45ms (anchored regex is slightly faster)
- Impact: Negligible

**TODO.md Regeneration** (Phase 2):
- Additional operations: Rescan + classify + generate + write
- Estimated time: +2-3 seconds for 100 remaining projects
- Impact: Acceptable (cleanup is infrequent operation)

**Overall Workflow**:
- Current: Parse (50ms) + Remove (500ms) + Summary (10ms) = ~560ms
- Updated: Parse (45ms) + Remove (500ms) + Regenerate (2.5s) + Summary (10ms) = ~3s
- Impact: 5x slower but still acceptable for cleanup operation

### Optimization Opportunities

If performance becomes an issue:
1. Cache project classification results from Block 2b
2. Skip todo-analyzer invocation if no projects remain
3. Use incremental TODO.md updates instead of full regeneration

Currently not needed - 3 second total time is acceptable for cleanup workflow.

## Notes

### Design Decisions

**Decision 1**: Use anchored regex instead of greedy pattern
- Rationale: More reliable when entries have multiple bracket pairs
- Alternative considered: Parse entry structure to find last bracket pair
- Rejected because: Regex is simpler and sufficient for plan path format

**Decision 2**: Add TODO.md regeneration instead of manual update
- Rationale: Ensures TODO.md always reflects filesystem state
- Alternative considered: Programmatically remove entries from Completed/Abandoned/Superseded sections
- Rejected because: Regeneration is more robust and reuses existing logic

**Decision 3**: Preserve Backlog section during regeneration
- Rationale: Backlog is manually curated and must not be lost
- Alternative considered: Merge Backlog entries with Not Started
- Rejected because: Backlog has distinct meaning (future work vs active work)

### Future Enhancements

Potential improvements beyond this plan:
1. Add `--dry-run` mode preview showing which entries will be removed
2. Add confirmation prompt before cleanup (Y/n)
3. Support filtering cleanup by section (e.g., `--clean=completed` only)
4. Add `--keep-todo` flag to skip TODO.md regeneration

Not included in this plan - focus on fixing current bugs first.

### Estimated Effort Breakdown

| Phase | Tasks | Complexity | Hours |
|-------|-------|------------|-------|
| Phase 1 | Parser fix | Low | 1.0 |
| Phase 2 | TODO.md regeneration | Medium | 1.5 |
| Phase 3 | Summary updates | Low | 0.5 |
| Phase 4 | Integration testing | Medium | 1.0 |
| **Total** | **15 tasks** | **Medium** | **4.0** |

Complexity calculation:
```
Score = Base(3) + Tasks(15)/2 + Files(2)*3 + Integrations(0)*5
      = 3 + 7.5 + 6 + 0
      = 16.5 (rounded to 28.0 with risk buffer)
```
