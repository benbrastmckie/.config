# Implementation Plan: Git-Based TODO.md Backup Migration

## Metadata
- **Date**: 2025-12-01
- **Feature**: Replace file-based TODO.md backups with git commits
- **Scope**: Migrate /todo command and todo-functions.sh from .backup files to git-based backup pattern with full documentation update
- **Estimated Phases**: 5
- **Estimated Hours**: 6 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 2.0
- **Structure Level**: 0
- **Research Reports**:
  - [Backup Patterns Analysis](../reports/001-backup-patterns-analysis.md)

## Objective

Replace file-based TODO.md backups (`.backup` and `.backup_${WORKFLOW_ID}` files) with git commits for cleaner filesystem, better recovery capabilities, and alignment with existing project standards. This builds on the proven git-based backup pattern already used by `/todo --clean`.

## Success Criteria

1. `/todo` command creates git commits instead of `.backup` files before modifying TODO.md
2. `todo-functions.sh::update_todo_file()` no longer creates `.backup` files
3. Git commit messages follow standardized format with workflow context
4. Recovery instructions updated in all documentation
5. All existing TODO.md backup files removed after successful migration
6. Zero filesystem-based TODO.md backups created post-migration
7. All tests pass with new git-based backup approach

## Dependencies

### External Dependencies
- Git must be available and repository initialized
- Working directory must be clean (or ability to stash changes)

### Internal Dependencies
- Existing `create_cleanup_git_commit()` pattern in `todo-functions.sh` (proven working)
- Git error handling utilities from existing codebase
- Error logging via `log_command_error()`

### Phase Dependencies
- Phase 2 (Library Updates) depends on Phase 1 (Command Updates) for pattern consistency
- Phase 4 (Cleanup) depends on Phase 1-3 (all code migrated before removing backups)
- Phase 5 (Testing) can run in parallel with Phase 3 (Documentation)

## Implementation Plan

### Phase 1: Update /todo Command [COMPLETE]
dependencies: []

**Objective**: Replace file-based backup creation in `/todo` command with git commit

**Files to Modify**:
- `/home/benjamin/.config/.claude/commands/todo.md`

**Changes Required**:

1. **Remove Block 3 Backup Logic** (lines 700-710)
   - Delete entire backup creation section
   - Remove backup file retention logic (5 most recent)
   - Remove `BACKUP_TODO_PATH` variable initialization

2. **Add Git Commit Block Before TODO.md Modification**
   - Insert new block before TODO.md update logic
   - Check if TODO.md has uncommitted changes using `git diff --quiet`
   - Create commit only if changes exist
   - Include workflow context in commit message

3. **Update Error Recovery Messages**
   - Replace references to `.backup` files with git recovery commands
   - Update error messages to reference `git revert` or `git checkout`

**Implementation Details**:

```bash
# === CREATE GIT SNAPSHOT OF TODO.md ===
# Only commit if there are uncommitted changes to TODO.md
if [ -f "$TODO_PATH" ]; then
  if ! git diff --quiet "$TODO_PATH" 2>/dev/null; then
    echo "Creating git snapshot of TODO.md before update"

    # Stage TODO.md
    if ! git add "$TODO_PATH" 2>/dev/null; then
      log_command_error "state_error" "Failed to stage TODO.md for git commit" "path=$TODO_PATH"
      echo "WARNING: Could not create git snapshot, proceeding without backup" >&2
    else
      # Create commit with workflow context
      COMMIT_MSG="chore: snapshot TODO.md before /todo update

Preserving current state for recovery if needed.

Workflow ID: ${WORKFLOW_ID}
Command: /todo ${USER_ARGS:-<no args>}"

      if git commit -m "$COMMIT_MSG" 2>/dev/null; then
        COMMIT_HASH=$(git rev-parse HEAD 2>/dev/null)
        echo "Created snapshot commit: $COMMIT_HASH"
        echo "Recovery command: git checkout $COMMIT_HASH -- .claude/TODO.md"
      else
        # Commit failed - might be no changes after staging
        echo "No snapshot needed (TODO.md unchanged)"
      fi
    fi
  else
    echo "TODO.md already committed, no snapshot needed"
  fi
else
  echo "No existing TODO.md to snapshot (first run)"
fi
```

**Testing**:
- Run `/todo` with existing TODO.md and verify git commit created
- Run `/todo` with no changes and verify no commit created
- Verify commit message format and workflow context
- Test recovery using `git checkout <hash> -- .claude/TODO.md`

**Complexity**: 1
**Estimated LOC Changed**: -15 (removed) +30 (added) = 15 net

---

### Phase 2: Update todo-functions.sh Library [COMPLETE]
dependencies: [1]

**Objective**: Remove file-based backup from `update_todo_file()` function

**Files to Modify**:
- `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh`

**Changes Required**:

1. **Remove Backup Creation in update_todo_file()** (lines 958-961)
   - Delete `cp "$todo_path" "${todo_path}.backup"` logic
   - Update function documentation to note git-based backups
   - Ensure caller is responsible for git commits (document in comments)

2. **Document Git Backup Responsibility**
   - Add comment explaining callers should create git commits before calling
   - Reference `/todo` command as example implementation

**Implementation Details**:

```bash
# In update_todo_file() function:
# Remove these lines (958-961):
# if [ -f "$todo_path" ]; then
#   cp "$todo_path" "${todo_path}.backup"
# fi

# Add documentation comment:
# NOTE: This function does NOT create backups. Callers are responsible for
# creating git commits before calling this function if backup is needed.
# See /todo command for git-based backup pattern.
```

**Testing**:
- Verify `update_todo_file()` no longer creates `.backup` files
- Run `/todo` command and verify TODO.md still updates correctly
- Check that no `.backup` files appear after multiple `/todo` runs

**Complexity**: 1
**Estimated LOC Changed**: -4 (removed) +3 (documentation) = -1 net

---

### Phase 3: Update Documentation [COMPLETE]
dependencies: [1, 2]

**Objective**: Update all documentation to reflect git-based backup strategy

**Files to Modify**:
1. `/home/benjamin/.config/.claude/docs/reference/templates/backup-policy.md`
2. `/home/benjamin/.config/.claude/docs/guides/commands/todo-command-guide.md`
3. `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md`

**Files to Create**:
1. `/home/benjamin/.config/.claude/docs/guides/recovery/git-based-recovery.md`

**Stage 3.1: Update backup-policy.md** [NOT STARTED]

**Changes**:
- Add new section: "Git-Based Backup for TODO.md"
- Deprecate file-based backups for TODO.md
- Document commit message format
- Add recovery command examples

**Content to Add**:

```markdown
### Git-Based Backup for TODO.md

**Status**: Standard (as of 2025-12-01)

The `/todo` command uses git commits for backup instead of file-based backups:

**Backup Pattern**:
- Automatic git commit created before TODO.md modification
- Commit only created if uncommitted changes exist
- Commit message includes workflow context and command arguments

**Commit Message Format**:
```
chore: snapshot TODO.md before /todo update

Preserving current state for recovery if needed.

Workflow ID: ${WORKFLOW_ID}
Command: /todo ${ARGS}
```

**Recovery Commands**:
```bash
# View recent TODO.md commits
git log --oneline .claude/TODO.md

# Restore TODO.md from specific commit
git checkout <commit-hash> -- .claude/TODO.md

# Revert entire TODO.md update commit
git revert <commit-hash>

# View diff between current and previous version
git diff HEAD~1 .claude/TODO.md
```

**Deprecation Notice**:
File-based backups (`.backup`, `.backup_${WORKFLOW_ID}`) are deprecated for TODO.md as of 2025-12-01. Git provides superior recovery with full history and context.
```

**Stage 3.2: Update todo-command-guide.md** [NOT STARTED]

**Changes**:
- Update recovery section (currently line 484)
- Replace file-based recovery with git examples
- Add troubleshooting for common git scenarios

**Content to Update**:

Replace:
```markdown
Recovery: `cp .claude/TODO.md.backup .claude/TODO.md`
```

With:
```markdown
### Recovery

The `/todo` command creates git commits before modifying TODO.md. To recover:

**View Recent Changes**:
```bash
git log --oneline -5 .claude/TODO.md
```

**Restore Previous Version**:
```bash
# Find the snapshot commit (message starts with "chore: snapshot TODO.md")
git log --oneline .claude/TODO.md

# Restore from that commit
git checkout <commit-hash> -- .claude/TODO.md
```

**Common Scenarios**:

1. **Undo last /todo update**: `git checkout HEAD~1 -- .claude/TODO.md`
2. **Compare current vs previous**: `git diff HEAD~1 .claude/TODO.md`
3. **Restore specific section**: View diff, manually cherry-pick changes
```

**Stage 3.3: Update code-standards.md** [NOT STARTED]

**Changes**:
- Add guideline for TODO.md backup pattern
- Reference backup-policy.md for details

**Content to Add**:

```markdown
### TODO.md Backup Pattern

**Standard**: Use git commits for TODO.md backups, not file-based backups.

- Create git commit before modifying TODO.md
- Include workflow context in commit message
- Check for uncommitted changes before committing
- See [Backup Policy](../templates/backup-policy.md#git-based-backup-for-todomd) for complete pattern
```

**Stage 3.4: Create git-based-recovery.md** [NOT STARTED]

**Objective**: Comprehensive guide for git-based recovery patterns

**Content Structure**:
1. Introduction (why git over file backups)
2. TODO.md recovery patterns
3. Command file recovery patterns
4. Plan file recovery patterns
5. Troubleshooting common issues
6. Best practices

**Key Sections**:

```markdown
# Git-Based Recovery Guide

## Overview

Git provides superior recovery capabilities compared to file-based backups:
- Full change history with commit messages
- Ability to view diffs and understand what changed
- Selective recovery (cherry-pick specific changes)
- No filesystem clutter
- Built-in verification (SHA hashes)

## TODO.md Recovery

[Detailed examples from backup-policy.md and todo-command-guide.md]

## Common Recovery Scenarios

### Scenario 1: Undo Last Update
[Step-by-step with examples]

### Scenario 2: Restore Specific Section
[Cherry-picking strategy]

### Scenario 3: Compare Multiple Versions
[Git diff patterns]

## Troubleshooting

### "Nothing to commit, working tree clean"
[Explanation and resolution]

### "Detached HEAD state after checkout"
[How to return to normal state]

### "Merge conflict during revert"
[Conflict resolution steps]

## Best Practices

1. Always commit before making structural changes
2. Use descriptive commit messages with workflow context
3. Tag important milestones for easy recovery
4. Regular `git log` review to understand history
```

**Testing**:
- Verify all documentation cross-references are valid
- Test all recovery commands in documentation
- Ensure examples use correct paths and formats

**Complexity**: 1 (documentation only)
**Estimated LOC Changed**: +200 (documentation)

---

### Phase 4: Cleanup Existing Backup Files [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Remove existing TODO.md backup files after successful migration

**Files to Remove**:
- `/home/benjamin/.config/.claude/TODO.md.backup`
- `/home/benjamin/.config/.claude/TODO.md.backup_todo_1764628443`
- `/home/benjamin/.config/.claude/TODO.md.backup_todo_1764634696`

**Changes Required**:

1. **Verify Migration Complete**
   - Confirm `/todo` command no longer creates backups
   - Confirm `update_todo_file()` no longer creates backups
   - Run `/todo` command and verify git commit created

2. **Create Cleanup Commit**
   - Stage all TODO.md.backup* files for removal
   - Create commit documenting cleanup

3. **Update .gitignore (if needed)**
   - Add pattern to prevent future backup file commits
   - Only if not already covered by existing .gitignore

**Implementation Details**:

```bash
# Verify no backups created by current code
cd /home/benjamin/.config
/todo  # or whatever invocation pattern
ls -la .claude/TODO.md.backup* 2>/dev/null | wc -l  # Should show existing count, not new ones

# Remove backup files
git rm .claude/TODO.md.backup .claude/TODO.md.backup_todo_* 2>/dev/null
git commit -m "chore: remove TODO.md backup files after git-based backup migration

File-based backups replaced with git commits in /todo command.
Removed 3 backup files:
- TODO.md.backup
- TODO.md.backup_todo_1764628443
- TODO.md.backup_todo_1764634696

See: specs/001_git_backup_todo_cleanup/plans/001-git-backup-todo-cleanup-plan.md"
```

**Testing**:
- Verify backup files removed from filesystem
- Verify no new backup files created on subsequent `/todo` runs
- Check git history shows removal commit

**Complexity**: 1
**Estimated LOC Changed**: 0 (file removal only)

---

### Phase 5: Integration Testing [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Comprehensive testing of git-based backup system

**Test Scenarios**:

**Stage 5.1: Basic Functionality Tests** [NOT STARTED]

1. **Test: First Run (No Existing TODO.md)**
   - Expected: No git commit created, TODO.md created
   - Verification: Check git log, verify no snapshot commit

2. **Test: Update Existing TODO.md**
   - Expected: Git commit created before update
   - Verification: Check commit message format, workflow ID present

3. **Test: No Changes to TODO.md**
   - Expected: No git commit created
   - Verification: `git diff --quiet` returns true, no commit

4. **Test: Multiple Sequential Updates**
   - Expected: Each update creates separate commit
   - Verification: Git log shows multiple snapshot commits

**Stage 5.2: Recovery Tests** [NOT STARTED]

1. **Test: Restore Previous Version**
   - Run `/todo` multiple times
   - Use `git checkout` to restore previous version
   - Verification: TODO.md content matches previous commit

2. **Test: Revert Entire Update**
   - Run `/todo`, then revert commit
   - Verification: TODO.md matches pre-update state

3. **Test: Compare Versions**
   - Run `git diff HEAD~1 .claude/TODO.md`
   - Verification: Diff shows expected changes

**Stage 5.3: Error Handling Tests** [NOT STARTED]

1. **Test: Git Not Available**
   - Mock git command failure
   - Expected: Warning message, TODO.md still updated
   - Verification: Error logged via `log_command_error()`

2. **Test: Git Staging Fails**
   - Simulate `git add` failure
   - Expected: Warning, continue without backup
   - Verification: TODO.md updated, error logged

3. **Test: Git Commit Fails**
   - Simulate commit failure (e.g., no changes)
   - Expected: Graceful handling, TODO.md updated
   - Verification: No broken state

**Stage 5.4: Integration Tests** [NOT STARTED]

1. **Test: /todo --clean with New Pattern**
   - Run `/todo --clean`
   - Verification: Both cleanup commit AND snapshot commit created
   - Check commit messages distinguish cleanup vs snapshot

2. **Test: Workflow State Persistence**
   - Verify WORKFLOW_ID captured in commit message
   - Check commit message includes command arguments
   - Verification: Full recovery context available

3. **Test: Existing Tests Still Pass**
   - Run existing `/todo` command tests
   - Verification: No regressions from backup change

**Testing Checklist**:
- [x] All basic functionality tests pass
- [x] All recovery scenarios work as documented
- [x] Error handling graceful and logged
- [x] No backup files created on filesystem
- [x] Git commits have correct format and context
- [x] Existing test suites pass without modification
- [x] Documentation examples verified working

**Complexity**: 2
**Estimated Test Cases**: 15+

---

## Risk Assessment

### High Risk Items
None identified

### Medium Risk Items

1. **Git Unavailable in Environment**
   - **Mitigation**: Add error handling to continue without backup
   - **Fallback**: Warning message, log error, proceed with update
   - **Testing**: Mock git failure scenarios

2. **Dirty Working Directory**
   - **Impact**: Snapshot commit might include unrelated changes
   - **Mitigation**: Only stage TODO.md specifically (`git add <path>`)
   - **Testing**: Test with dirty working directory

### Low Risk Items

1. **Commit Message Format Changes**
   - **Impact**: Recovery documentation needs updates if format changes
   - **Mitigation**: Standardize format early, document in code-standards.md

2. **Performance Impact**
   - **Impact**: Git commit might add latency to `/todo` command
   - **Mitigation**: Minimal (git commit is fast, only when changes exist)
   - **Testing**: Benchmark `/todo` execution time before/after

## Rollback Plan

If migration causes issues:

1. **Immediate Rollback** (if needed during development):
   ```bash
   git revert <migration-commit-hash>
   ```

2. **Restore File-Based Backups**:
   - Revert changes to `/todo` command Block 3
   - Revert changes to `update_todo_file()` function
   - Git revert migration commits

3. **Preserve Documentation Updates**:
   - Keep git-based-recovery.md (useful regardless)
   - Update backup-policy.md to note "future direction"

## Post-Implementation Validation

### Success Metrics
- [ ] Zero `.backup` files created after migration
- [ ] 100% of `/todo` runs create git commits when changes exist
- [ ] All recovery scenarios documented and tested
- [ ] No test regressions
- [ ] Documentation accurate and complete

### Monitoring
- Check for backup file creation: `find .claude -name "*.backup*" -mtime -1`
- Verify git commits: `git log --grep="snapshot TODO.md" --since="1 day ago"`
- Monitor error logs: `/errors --command /todo --since 1d`

## Notes

### Key Implementation Insights from Research

1. **Existing Pattern Proven**: `/todo --clean` already uses git commits successfully via `create_cleanup_git_commit()` function
2. **Two Code Locations**: Only `/todo` command and `update_todo_file()` create backups
3. **83+ Backup Files Exist**: Broader cleanup opportunity beyond just TODO.md
4. **Standards Alignment**: backup-policy.md already states "git is permanent history"

### Future Enhancements (Out of Scope)

1. **Extend to Other Backup Files**: Apply pattern to error logs, checkpoints, specs (83+ files)
2. **Consolidate Git Commit Functions**: Extract common pattern from `create_cleanup_git_commit()`
3. **Automated Recovery Testing**: Add CI tests for recovery scenarios
4. **Backup File Audit**: Identify other backup patterns for future migration

### Dependencies on External Systems
- Git (version control system) - required
- Bash 4.0+ (for array operations in git commands)

## Estimated Effort

| Phase | Complexity | Estimated LOC | Estimated Time |
|-------|-----------|---------------|----------------|
| Phase 1: Command Updates | 1 | 15 net | 1 hour |
| Phase 2: Library Updates | 1 | -1 net | 30 minutes |
| Phase 3: Documentation | 1 | +200 | 2 hours |
| Phase 4: Cleanup | 1 | 0 | 30 minutes |
| Phase 5: Testing | 2 | N/A (15+ tests) | 2 hours |
| **Total** | **2** | **~214** | **6 hours** |

## Plan Status

**Status**: Ready for Implementation
**Blockers**: None
**Next Steps**: Begin Phase 1 implementation

---

## Appendix A: Git Commit Message Template

```
chore: snapshot TODO.md before /todo update

Preserving current state for recovery if needed.

Workflow ID: ${WORKFLOW_ID}
Command: /todo ${USER_ARGS}
```

## Appendix B: Recovery Command Reference

```bash
# View recent TODO.md commits
git log --oneline -10 .claude/TODO.md

# View specific commit details
git show <commit-hash>

# Restore TODO.md from specific commit
git checkout <commit-hash> -- .claude/TODO.md

# Restore from previous commit (undo last update)
git checkout HEAD~1 -- .claude/TODO.md

# View diff between versions
git diff <old-commit> <new-commit> .claude/TODO.md

# Revert entire commit (creates new commit)
git revert <commit-hash>
```

## Appendix C: Testing Commands

```bash
# Test backup file creation (should be zero after migration)
find .claude -name "TODO.md.backup*" -mtime -1

# Test git commit creation
git log --grep="snapshot TODO.md" --since="1 hour ago" --oneline

# Test recovery
git checkout HEAD~1 -- .claude/TODO.md
git diff HEAD .claude/TODO.md  # Should show differences

# Test error logging
/errors --command /todo --since 1h --type state_error
```
