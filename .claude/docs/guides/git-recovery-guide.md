# Git Recovery Guide

This guide explains how to recover and view historical file versions using git, eliminating the need for backup files.

## Why No Backup Files?

The `.claude/commands/` directory follows a **clean-break, no-backup philosophy**:

- **All version history managed via git** - Complete change history, not just current state
- **No backup files allowed** - Enforced via `.gitignore` and pre-commit hooks
- **Git provides superior recovery** - View any version, compare changes, restore selectively

Benefits:
- **Zero disk overhead** - No duplicate files cluttering the directory
- **Better navigation** - Only active files visible
- **Complete history** - Every version preserved, not just manual backups
- **Easy comparison** - Compare any two versions instantly

## Recovering Deleted Files

### View a deleted file's content

```bash
# Find the commit where the file was deleted
git log --all --diff-filter=D -- .claude/commands/orchestrate.md

# View the file content from before deletion (use the commit hash from above)
git show <commit-hash>^:.claude/commands/orchestrate.md

# Or use a tag if one was created before deletion
git show cleanup/pre-removal-20251115:.claude/commands/orchestrate.md
```

### Restore a deleted file

```bash
# Restore from the commit before deletion
git checkout <commit-hash>^ -- .claude/commands/orchestrate.md

# Or restore from a specific tag
git checkout cleanup/pre-removal-20251115 -- .claude/commands/orchestrate.md
```

### List all deleted files

```bash
# Show all deleted files in .claude/commands/
git log --diff-filter=D --summary -- .claude/commands/ | grep delete
```

## Viewing Historical Versions

### View a file at a specific point in time

```bash
# View file from 3 commits ago
git show HEAD~3:.claude/commands/coordinate.md

# View file from a specific date
git show 'HEAD@{2025-11-01}':.claude/commands/coordinate.md

# View file from a specific commit
git show a545a17e:.claude/commands/coordinate.md
```

### Find when a file was changed

```bash
# Show all commits that modified a file
git log -- .claude/commands/coordinate.md

# Show commits with diffs
git log -p -- .claude/commands/coordinate.md

# Show one-line summary
git log --oneline -- .claude/commands/coordinate.md
```

## Comparing Versions

### Compare current version with history

```bash
# Compare current file with version from 5 commits ago
git diff HEAD~5 -- .claude/commands/coordinate.md

# Compare current file with specific commit
git diff a545a17e -- .claude/commands/coordinate.md

# Compare current file with version from yesterday
git diff 'HEAD@{yesterday}' -- .claude/commands/coordinate.md
```

### Compare two historical versions

```bash
# Compare version from commit A with commit B
git diff <commit-A> <commit-B> -- .claude/commands/coordinate.md

# Compare versions from two dates
git diff 'HEAD@{2025-11-01}' 'HEAD@{2025-11-15}' -- .claude/commands/coordinate.md
```

## Finding Specific Changes

### Search for when a line was added or removed

```bash
# Show when each line was last modified
git blame .claude/commands/coordinate.md

# Search for commits that added or removed specific text
git log -S "state machine" -- .claude/commands/coordinate.md

# Search for commits that added or removed a regex pattern
git log -G "state.*machine" -- .claude/commands/coordinate.md
```

### Find when a function was changed

```bash
# Show history of a specific function (if language supported)
git log -L :function_name:.claude/commands/coordinate.md
```

## Safety Tags for Recovery

Before major operations (deletions, refactors), create a safety tag:

```bash
# Create a safety tag
git tag cleanup/pre-removal-$(date +%Y%m%d)

# List all safety tags
git tag | grep cleanup/

# Restore entire directory state from a tag
git checkout cleanup/pre-removal-20251115 -- .claude/commands/
```

## Troubleshooting

### "fatal: path not in working tree"

This error means the file doesn't exist in the current commit. Use `git show` instead of `git diff` or `git checkout`:

```bash
# Wrong (if file deleted)
git diff HEAD~5 -- .claude/commands/deleted-file.md

# Correct
git show HEAD~5:.claude/commands/deleted-file.md
```

### Finding the right commit

If you know approximately when a file was deleted or changed:

```bash
# Show commits from last 7 days
git log --since="7 days ago" -- .claude/commands/

# Show commits between two dates
git log --since="2025-11-01" --until="2025-11-15" -- .claude/commands/

# Show commits by author
git log --author="Claude" -- .claude/commands/
```

## Best Practices

1. **Commit frequently** - More commits = finer-grained history
2. **Use descriptive commit messages** - Makes finding changes easier
3. **Create safety tags** - Before major deletions or refactors
4. **Use git log** - Explore history before making changes
5. **Never create backup files** - Git is your backup system

## Related Documentation

- [Development Philosophy](../../CLAUDE.md#development_philosophy) - Clean-break philosophy
- [Command Development Guide](./command-development-guide.md) - Anti-backup policy
- [Git Documentation](https://git-scm.com/doc) - Official git docs
