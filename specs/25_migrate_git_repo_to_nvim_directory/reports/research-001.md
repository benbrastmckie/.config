# Research Report: Task #25

**Task**: 25 - migrate_git_repo_to_nvim_directory
**Started**: 2026-02-02T12:00:00Z
**Completed**: 2026-02-02T12:15:00Z
**Effort**: 1-2 hours
**Dependencies**: None (standalone migration)
**Sources/Inputs**: Web research, codebase analysis, git documentation
**Artifacts**: specs/25_migrate_git_repo_to_nvim_directory/reports/research-001.md
**Standards**: report-format.md

## Executive Summary

- **Recommended approach**: Use `git filter-repo --path nvim/ --path .claude/ --path specs/ --path-rename nvim/:` to create a clean repository focused on nvim/ as root while preserving .claude/ task management
- The current repository has 2725 commits total; 927 touch nvim/, 1516 touch .claude/
- `git-filter-repo` is the modern, safe replacement for `git filter-branch` - available via `nix-shell -p git-filter-repo`
- Alternative simpler approach: Move .git into nvim/ and adjust paths without history rewrite (requires `git log --follow`)

## Context and Scope

**Current State**:
- Repository root: `/home/benjamin/.config/`
- Remote: `git@github.com:benbrastmckie/.config.git`
- Branches: himalaya (current), master, remotes for pack and vimscript
- Total commits: 2725
- No submodules present
- Single worktree (main repository only)
- No symlinks within nvim/ directory

**Migration Goal**:
- New repository root: `/home/benjamin/.config/nvim/`
- Preserve full commit history for nvim configuration
- Everything else in .config/ is now managed by .dotfiles/ via home-manager/NixOS

**Tracked Content Analysis** (git ls-files):
```
Primary content (to keep):
- nvim/           (927 commits) - Neovim configuration
- .claude/        (1516 commits) - Claude Code task management
- specs/          - Task specifications and artifacts

Other tracked content (managed elsewhere now):
- fish/, fonts/, ghostty/, himalaya/, latex/, latexmk/
- Various config files (CLAUDE.md, README.md, etc.)
- Screenshots, docs/, converted_output/
```

## Findings

### Codebase Patterns

**Current Repository Structure**:
- Mixed-purpose repository managing entire .config/
- nvim/ is the primary focus with 927 commits
- .claude/ provides task/project management (1516 commits)
- specs/ contains task artifacts (plans, reports, summaries)
- Other directories are now redundant (managed by home-manager)

**Files in nvim/**:
- init.lua (entry point)
- lua/ (modules), after/ftplugin/ (filetype overrides)
- plugin/, scripts/, sessions/, snippets/, spell/, templates/, tests/
- docs/, deprecated/
- CLAUDE.md, README.md

**Symlink Status**: No symlinks in nvim/ (safe for migration)

### External Resources

#### Tool Comparison

| Tool | Speed | Safety | Recommended |
|------|-------|--------|-------------|
| [git-filter-repo](https://github.com/newren/git-filter-repo) | Fast | High | Yes |
| [git filter-branch](https://git-scm.com/docs/git-filter-branch) | Slow | Low | No (deprecated) |
| git subtree | Medium | Medium | For merges only |

#### Approach 1: git-filter-repo (History Rewrite)

**Pros**:
- Clean history: files appear at root in all commits
- Standard git log works without --follow
- Smaller repository (removes irrelevant history)

**Cons**:
- Rewrites all commit hashes
- Requires force push to remote
- Collaborators must re-clone

**Command** ([source](https://www.git-tower.com/learn/git/faq/git-filter-repo)):
```bash
# In a fresh clone
cd /tmp
git clone git@github.com:benbrastmckie/.config.git nvim-config
cd nvim-config

# Option A: Only nvim/ content (pure Neovim config)
nix-shell -p git-filter-repo --run "git-filter-repo --path nvim/ --path-rename nvim/:"

# Option B: Keep .claude/ and specs/ for task management
nix-shell -p git-filter-repo --run "git-filter-repo \
  --path nvim/ \
  --path .claude/ \
  --path specs/ \
  --path CLAUDE.md \
  --path-rename nvim/:"
```

**Post-migration**:
```bash
# Move to final location
mv /tmp/nvim-config/.git /home/benjamin/.config/nvim/.git
cd /home/benjamin/.config/nvim
git checkout .

# Update remote
git remote set-url origin git@github.com:benbrastmckie/nvim.git
git push --force --all
git push --force --tags
```

#### Approach 2: Simple .git Move (No History Rewrite)

**Pros**:
- No force push required
- Commit hashes preserved
- Simpler, less risky

**Cons**:
- History shows files moving from nvim/ to root
- Requires `git log --follow <file>` for pre-move history
- Repository contains orphaned history for removed files

**Command** ([source](https://gist.github.com/ajaegers/2a8d8cbf51e49bcf17d5)):
```bash
# From .config/
mv .git nvim/.git
cd nvim

# Update paths for remaining files
git add .
git commit -m "Migrate repository root from .config/ to nvim/"

# If keeping .claude/ and specs/
mv ../.claude .
mv ../specs .
mv ../CLAUDE.md .
git add .
git commit -m "Add task management to nvim repository"

# Update remote
git remote set-url origin git@github.com:benbrastmckie/nvim.git
git push
```

#### Approach 3: Subdirectory Filter (Recommended for Clean Split)

This is the cleanest approach using `--subdirectory-filter` ([source](https://www.mankier.com/1/git-filter-repo)):

```bash
cd /tmp
git clone git@github.com:benbrastmckie/.config.git nvim-only
cd nvim-only

# Make nvim/ the repository root
nix-shell -p git-filter-repo --run "git-filter-repo --subdirectory-filter nvim/"

# This is equivalent to:
# git-filter-repo --path nvim/ --path-rename nvim/:
```

### Recommendations

**Recommended: Approach 3 (Subdirectory Filter) with modifications**

Given the requirements, I recommend a hybrid approach:

1. **Primary content**: Use `--subdirectory-filter nvim/` to make nvim/ the new root
2. **Task management**: Decide whether to:
   - (a) Keep .claude/ and specs/ in the new repo (for continued task management)
   - (b) Start fresh with task management (cleaner separation)

**If keeping task management (Option a)**:
```bash
cd /tmp
git clone git@github.com:benbrastmckie/.config.git nvim-config
cd nvim-config

# Filter to keep nvim/, .claude/, specs/, and root CLAUDE.md
nix-shell -p git-filter-repo --run "git-filter-repo \
  --path nvim/ \
  --path .claude/ \
  --path specs/ \
  --path CLAUDE.md \
  --path-rename nvim/:"

# Result: nvim contents at root, .claude/ and specs/ preserved
```

**If fresh start (Option b - cleanest)**:
```bash
cd /tmp
git clone git@github.com:benbrastmckie/.config.git nvim-only
cd nvim-only

nix-shell -p git-filter-repo --run "git-filter-repo --subdirectory-filter nvim/"

# Copy .claude/ framework fresh (without historical tasks)
cp -r /home/benjamin/.config/.claude .
mkdir specs
git add .
git commit -m "Initialize task management framework"
```

## Decisions

1. **Use git-filter-repo**: Modern, safe, fast - available via nix-shell
2. **Work on fresh clone**: Safety feature prevents accidental history corruption
3. **Keep .claude/ and specs/**: Preserves 1516 commits of task management history
4. **Create new remote**: Rename from .config to nvim for clarity

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Force push destroys collaborator work | Notify collaborators; they must re-clone |
| Worktree references break | Remove worktrees before migration, recreate after |
| Symlinks in .config/ break | nvim/ has no symlinks; .config/ symlinks are home-manager managed |
| Branch history inconsistent | Apply filter to --all branches |
| Tags point to wrong commits | Use --tag-rename or re-tag after migration |
| .claude/ paths reference old structure | Update CLAUDE.md and context files after migration |

**Worktree handling** ([source](https://git-scm.com/docs/git-worktree)):
```bash
# Before migration
git worktree list
git worktree remove <path>  # for each linked worktree

# After migration (if needed)
git worktree repair
```

**Current worktree status**: Only main worktree exists (no linked worktrees to remove)

## Appendix

### Search Queries Used
- "git filter-repo move repository to subdirectory preserve history 2025 2026"
- "git migrate repository from parent directory to subdirectory best practices"
- "git filter-repo subdirectory-filter make subdirectory new root preserve history"
- "git move .git directory to subdirectory simple approach without rewriting history"
- "git filter-repo gotchas pitfalls worktrees symlinks migration"

### References
- [git-filter-repo GitHub](https://github.com/newren/git-filter-repo) - Official repository
- [git-filter-repo Manual](https://www.mankier.com/1/git-filter-repo) - Complete documentation
- [Git Tower Guide](https://www.git-tower.com/learn/git/faq/git-filter-repo) - Practical examples
- [GitHub Docs: Splitting a subfolder](https://docs.github.com/en/get-started/using-git/splitting-a-subfolder-out-into-a-new-repository) - Official GitHub guidance
- [git filter-branch issues](https://github.com/newren/git-filter-repo/issues/70) - Why filter-repo replaces filter-branch

### Tool Availability

```bash
# git-filter-repo via nix-shell
nix-shell -p git-filter-repo --run "git-filter-repo --version"

# Alternative: pip install
pip install git-filter-repo
```

### Pre-Migration Checklist

- [ ] Backup existing repository: `cp -r .git .git.backup`
- [ ] Remove worktrees: `git worktree list` (currently none)
- [ ] Check submodules: `git submodule status` (currently none)
- [ ] Note current branch: himalaya
- [ ] Verify remote access: `git ls-remote origin`
- [ ] Coordinate with collaborators (if any)

### Post-Migration Checklist

- [ ] Verify history: `git log --oneline -20`
- [ ] Verify file structure: `ls -la`
- [ ] Update remote URL: `git remote set-url origin <new-url>`
- [ ] Force push all branches: `git push --force --all`
- [ ] Force push tags: `git push --force --tags`
- [ ] Update CLAUDE.md paths if needed
- [ ] Test nvim loads correctly: `nvim --headless -c "q"`
