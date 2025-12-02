# Git-Based Recovery Guide

## Overview

Git provides superior recovery capabilities compared to file-based backups:
- Full change history with commit messages
- Ability to view diffs and understand what changed
- Selective recovery (cherry-pick specific changes)
- No filesystem clutter
- Built-in verification (SHA hashes)

## TODO.md Recovery

### View Recent Changes

List recent commits that modified TODO.md:

```bash
# Show last 10 commits
git log --oneline -10 .claude/TODO.md

# Show commits with dates and authors
git log --pretty=format:"%h %ad %s" --date=short .claude/TODO.md

# Show commits from last 7 days
git log --since="7 days ago" --oneline .claude/TODO.md
```

### Identify Snapshot Commits

The `/todo` command creates snapshot commits with a specific message pattern:

```bash
# Find snapshot commits
git log --grep="snapshot TODO.md" --oneline .claude/TODO.md

# Find snapshot commits from specific workflow
git log --grep="Workflow ID: todo_123456" --oneline .claude/TODO.md
```

### Restore Previous Version

**Method 1: Checkout from specific commit**

```bash
# 1. Find the commit hash
git log --oneline .claude/TODO.md

# 2. Restore from that commit
git checkout <commit-hash> -- .claude/TODO.md

# 3. Verify the restored content
cat .claude/TODO.md

# 4. Commit the restoration
git add .claude/TODO.md
git commit -m "chore: restore TODO.md from <commit-hash>

Restored due to: [reason for restoration]"
```

**Method 2: Undo last update**

```bash
# Restore from immediately prior commit
git checkout HEAD~1 -- .claude/TODO.md

# Commit the restoration
git add .claude/TODO.md
git commit -m "chore: revert TODO.md to previous version"
```

### Compare Versions

View differences between versions:

```bash
# Compare current with previous
git diff HEAD~1 .claude/TODO.md

# Compare two specific commits
git diff <old-commit> <new-commit> .claude/TODO.md

# View specific commit's changes
git show <commit-hash>:.claude/TODO.md

# Show diff with context
git diff -U10 HEAD~1 .claude/TODO.md
```

### Revert Entire Commit

If the entire `/todo` update needs to be undone:

```bash
# 1. Find the commit to revert
git log --oneline .claude/TODO.md

# 2. Revert the commit (creates new commit)
git revert <commit-hash>

# 3. If conflicts occur, resolve and continue
git status
# ... resolve conflicts ...
git add .claude/TODO.md
git revert --continue
```

## Common Recovery Scenarios

### Scenario 1: Undo Last /todo Update

**Situation**: Just ran `/todo` and realized the output is incorrect.

**Solution**:
```bash
# Quick restore from previous version
git checkout HEAD~1 -- .claude/TODO.md

# Review the restored version
git diff HEAD .claude/TODO.md

# Commit the restoration
git add .claude/TODO.md
git commit -m "chore: revert TODO.md - incorrect classification"
```

### Scenario 2: Restore Specific Section

**Situation**: Most of the TODO.md update is correct, but one section needs to be restored from a previous version.

**Solution**:
```bash
# 1. View the diff to identify changes
git diff HEAD~1 .claude/TODO.md

# 2. Extract the specific section from old version
git show HEAD~1:.claude/TODO.md | grep -A 20 "## Backlog"

# 3. Manually edit TODO.md to restore just that section
# (Use your editor to cherry-pick the content)

# 4. Commit the partial restoration
git add .claude/TODO.md
git commit -m "chore: restore Backlog section from previous TODO.md"
```

### Scenario 3: Compare Multiple Versions

**Situation**: Need to understand what changed across several `/todo` runs.

**Solution**:
```bash
# List recent TODO.md commits
git log --oneline -5 .claude/TODO.md

# Compare first and last commit in range
git diff <oldest-commit> <newest-commit> .claude/TODO.md

# Or compare sequentially
git diff HEAD~3 HEAD~2 .claude/TODO.md
git diff HEAD~2 HEAD~1 .claude/TODO.md
git diff HEAD~1 HEAD .claude/TODO.md
```

### Scenario 4: Find When Entry Was Added/Removed

**Situation**: A TODO.md entry disappeared and you need to find when.

**Solution**:
```bash
# Search commit messages
git log --all --oneline --grep="entry-keyword" .claude/TODO.md

# Search commit diffs (content changes)
git log -S "entry-keyword" --oneline .claude/TODO.md

# Show commits that changed specific line
git log -L :"/entry-keyword/",+5:.claude/TODO.md
```

## Command File Recovery

Similar patterns apply to command files:

```bash
# View command file history
git log --oneline .claude/commands/todo.md

# Restore command file from backup
git checkout <commit-hash> -- .claude/commands/todo.md

# Compare command versions
git diff HEAD~1 .claude/commands/todo.md
```

## Plan File Recovery

Plans typically don't use git-based backups (yet), but can still leverage git:

```bash
# View plan history
git log --oneline .claude/specs/001_topic/plans/001-plan.md

# Restore plan
git checkout <commit-hash> -- .claude/specs/001_topic/plans/001-plan.md

# Compare plan versions
git diff HEAD~1 .claude/specs/001_topic/plans/001-plan.md
```

## Troubleshooting

### "Nothing to commit, working tree clean"

**Cause**: TODO.md has no uncommitted changes when `/todo` runs.

**Expected Behavior**: No snapshot commit is created. This is normal and indicates TODO.md was already committed.

**No Action Needed**: Snapshot commits are only created when there are uncommitted changes.

### "Detached HEAD state after checkout"

**Cause**: Used `git checkout <commit-hash>` instead of `git checkout <commit-hash> -- <file>`.

**Solution**:
```bash
# Return to your branch
git checkout main  # or your current branch name

# Then use file-specific checkout
git checkout <commit-hash> -- .claude/TODO.md
```

**Prevention**: Always include the file path with `--` separator.

### "Merge conflict during revert"

**Cause**: Changes in the commit being reverted conflict with current state.

**Solution**:
```bash
# 1. View conflict markers
cat .claude/TODO.md

# 2. Edit file to resolve conflicts (between <<<<<<< and >>>>>>>)
# Keep the sections you want, remove conflict markers

# 3. Stage resolved file
git add .claude/TODO.md

# 4. Continue the revert
git revert --continue
```

### "Cannot find snapshot commit"

**Cause**: Looking for wrong commit message pattern.

**Solution**:
```bash
# The exact message pattern is:
git log --grep="snapshot TODO.md" .claude/TODO.md

# If still not found, check all commits:
git log --all --oneline .claude/TODO.md

# Snapshot commits should have message starting with:
# "chore: snapshot TODO.md before /todo update"
```

### "Restored wrong version"

**Cause**: Checked out from wrong commit hash.

**Solution**:
```bash
# Don't panic - git never loses data

# View reflog to see recent HEAD movements
git reflog | head -20

# Find the state before the wrong checkout
# (Look for commit before your checkout command)

# Restore TODO.md from that state
git checkout <reflog-entry> -- .claude/TODO.md
```

## Best Practices

### 1. Always Commit Before Making Structural Changes

Before manually editing TODO.md or running `/todo --clean`:

```bash
# Verify current state
git status

# If TODO.md has changes, commit them
git add .claude/TODO.md
git commit -m "chore: manual TODO.md update before cleanup"

# Then proceed with operations
/todo --clean
```

### 2. Use Descriptive Commit Messages with Workflow Context

The `/todo` command automatically includes workflow context. When manually committing:

```bash
git commit -m "chore: manual TODO.md reorganization

Moved completed projects to archive.
Workflow context: Post-cleanup verification"
```

### 3. Tag Important Milestones for Easy Recovery

Create tags for significant TODO.md states:

```bash
# After major cleanup
git tag -a todo-cleanup-2025-12-01 -m "TODO.md state after major cleanup"

# After project completion
git tag -a todo-project-xyz-complete -m "TODO.md with project XYZ completed"

# List tags
git tag -l "todo-*"

# Restore from tag
git checkout todo-cleanup-2025-12-01 -- .claude/TODO.md
```

### 4. Regular Git Log Review to Understand History

Periodically review TODO.md history:

```bash
# Weekly review
git log --since="1 week ago" --oneline .claude/TODO.md

# Monthly summary
git log --since="1 month ago" --pretty=format:"%ad %s" --date=short .claude/TODO.md

# Count changes
git log --since="1 month ago" --oneline .claude/TODO.md | wc -l
```

### 5. Use Git Aliases for Common Operations

Add to `~/.gitconfig`:

```ini
[alias]
  todo-log = log --oneline -10 .claude/TODO.md
  todo-restore = !git checkout HEAD~1 -- .claude/TODO.md
  todo-diff = diff HEAD~1 .claude/TODO.md
  todo-snapshots = log --grep=\"snapshot TODO.md\" --oneline .claude/TODO.md
```

Usage:
```bash
git todo-log
git todo-restore
git todo-diff
git todo-snapshots
```

## Migration from File-Based Backups

### Cleanup Old Backups

After migrating to git-based backups:

```bash
# List old backup files
find .claude -name "TODO.md.backup*"

# Verify no recent backups being created
ls -lt .claude/TODO.md.backup* 2>/dev/null | head -5

# Remove old backups (after verifying git snapshots working)
rm .claude/TODO.md.backup*
```

### Verify Git-Based System Working

```bash
# 1. Note current TODO.md state
git log -1 --oneline .claude/TODO.md

# 2. Run /todo command
/todo

# 3. Verify snapshot commit created
git log -2 --oneline .claude/TODO.md

# 4. Should see new snapshot commit with "chore: snapshot TODO.md"
```

## See Also

- [Backup Policy](../../reference/templates/backup-policy.md) - Complete backup and retention policy
- [TODO Command Guide](../commands/todo-command-guide.md) - /todo command documentation
- [TODO Organization Standards](../../reference/standards/todo-organization-standards.md) - TODO.md structure standards
- [Code Standards](../../reference/standards/code-standards.md#todomd-backup-pattern) - TODO.md backup pattern requirements
