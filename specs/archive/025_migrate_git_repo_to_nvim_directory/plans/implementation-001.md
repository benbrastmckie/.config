# Implementation Plan: Task #25

- **Task**: 25 - migrate_git_repo_to_nvim_directory
- **Status**: [COMPLETED]
- **Effort**: 1-2 hours
- **Dependencies**: None (standalone migration)
- **Research Inputs**: specs/25_migrate_git_repo_to_nvim_directory/reports/research-001.md
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: general

## Overview

Migrate the git repository from managing ~/.config/ to managing only ~/.config/nvim/ by using git-filter-repo to rewrite history. The nvim/ directory contents become the new root, while .claude/ and specs/ are preserved as subdirectories with full commit history (927 commits for nvim/, 1516 for .claude/). This enables clean separation since other .config/ contents are now managed by .dotfiles/ via home-manager/NixOS.

### Research Integration

Research report (research-001.md) recommends:
- Use `git-filter-repo` with multiple `--path` arguments
- Work on a fresh clone for safety
- Use `--path-rename nvim/:` to make nvim/ contents the root
- Available via `nix-shell -p git-filter-repo`

## Goals & Non-Goals

**Goals**:
- Make nvim/ contents the new repository root (init.lua, lua/, after/ at top level)
- Preserve .claude/ and specs/ as subdirectories with full history
- Maintain all 927 commits touching nvim/ files
- Maintain all 1516 commits touching .claude/ files
- Update remote and push new history
- Ensure Neovim loads correctly from new structure

**Non-Goals**:
- Preserve history for other .config/ directories (fish/, ghostty/, etc.)
- Maintain backward compatibility with old repository structure
- Keep commit hashes unchanged (history rewrite required)
- Create a new GitHub repository (reuse existing remote)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Force push destroys collaborator work | Medium | Low | Single-user repository; no collaborators affected |
| Worktree references break | Low | Low | No linked worktrees exist (verified in research) |
| Original repository corrupted | High | Low | Work on fresh clone in /tmp; original untouched |
| .claude/ path references break | Medium | Medium | Verify and update CLAUDE.md paths after migration |
| Neovim fails to load | High | Low | Test with `nvim --headless` before pushing |
| Git filter-repo unavailable | Medium | Low | Use nix-shell -p git-filter-repo |

## Implementation Phases

### Phase 1: Pre-Migration Preparation [COMPLETED]

**Goal**: Verify repository state and create safety backup

**Tasks**:
- [ ] Verify no linked worktrees exist: `git worktree list`
- [ ] Verify no submodules: `git submodule status`
- [ ] Note current branch: himalaya
- [ ] Create backup of .git directory: `cp -r .git .git.backup`
- [ ] Verify remote access: `git ls-remote origin`
- [ ] Ensure working directory is clean: `git status`

**Timing**: 10 minutes

**Files to modify**: None (verification only)

**Verification**:
- git worktree list shows only main worktree
- git submodule status shows nothing
- .git.backup directory exists
- git status shows clean working tree

---

### Phase 2: Clone and Filter Repository [COMPLETED]

**Goal**: Create filtered clone with nvim/ as root and .claude/, specs/, CLAUDE.md preserved

**Tasks**:
- [ ] Clone repository to temporary location: `git clone ~/.config /tmp/nvim-config`
- [ ] Change to cloned directory: `cd /tmp/nvim-config`
- [ ] Run git-filter-repo with multi-path filter:
  ```bash
  nix-shell -p git-filter-repo --run "git-filter-repo \
    --path nvim/ \
    --path .claude/ \
    --path specs/ \
    --path CLAUDE.md \
    --path-rename nvim/:"
  ```
- [ ] Verify resulting structure: `ls -la` shows init.lua, lua/, .claude/, specs/

**Timing**: 15 minutes

**Files to modify**:
- `/tmp/nvim-config/` - Entire filtered repository

**Verification**:
- ls shows: init.lua, lua/, after/, .claude/, specs/, CLAUDE.md
- git log --oneline | wc -l shows filtered commit count
- git log --oneline -- lua/ | wc -l shows nvim history preserved
- git log --oneline -- .claude/ | wc -l shows .claude history preserved

---

### Phase 3: Move .git to Final Location [COMPLETED]

**Goal**: Install the filtered .git into ~/.config/nvim/

**Tasks**:
- [ ] Remove old backup (or rename for safety): `mv ~/.config/.git.backup ~/.config/.git.backup.old`
- [ ] Copy filtered .git to nvim directory: `cp -r /tmp/nvim-config/.git ~/.config/nvim/.git`
- [ ] Change to nvim directory: `cd ~/.config/nvim`
- [ ] Reset working tree to match repository: `git checkout .`
- [ ] Copy .claude/ to nvim/: `cp -r ~/.config/.claude ~/.config/nvim/.claude`
- [ ] Copy specs/ to nvim/: `cp -r ~/.config/specs ~/.config/nvim/specs`
- [ ] Copy CLAUDE.md to nvim/: `cp ~/.config/CLAUDE.md ~/.config/nvim/CLAUDE.md`
- [ ] Add new files to git: `git add .claude/ specs/ CLAUDE.md`
- [ ] Verify git status shows expected state

**Timing**: 15 minutes

**Files to modify**:
- `~/.config/nvim/.git/` - New git directory
- `~/.config/nvim/.claude/` - Copied from parent
- `~/.config/nvim/specs/` - Copied from parent
- `~/.config/nvim/CLAUDE.md` - Copied from parent

**Verification**:
- git status shows nvim/ as repository root
- ls ~/.config/nvim/.git exists
- ls ~/.config/nvim/.claude/ shows .claude contents
- ls ~/.config/nvim/specs/ shows task artifacts

---

### Phase 4: Verify History Preservation [COMPLETED]

**Goal**: Confirm all important commit history is preserved

**Tasks**:
- [ ] Check total commit count: `git log --oneline | wc -l`
- [ ] Check nvim file history: `git log --oneline -- lua/ | head -20`
- [ ] Check .claude file history: `git log --oneline -- .claude/ | head -20`
- [ ] Check specs history: `git log --oneline -- specs/ | head -10`
- [ ] Verify recent commits make sense: `git log --oneline -20`
- [ ] Check that file paths are correct (no nvim/ prefix): `git log --stat -1`

**Timing**: 10 minutes

**Files to modify**: None (verification only)

**Verification**:
- Commit history shows commits for lua/, .claude/, specs/
- File paths in commits do not show nvim/ prefix for lua files
- Recent commits are recognizable

---

### Phase 5: Update Remote and Push [COMPLETED]

**Goal**: Push filtered history to remote repository

**Tasks**:
- [ ] Verify current remote URL: `git remote -v`
- [ ] Optionally update remote URL for new repo name: `git remote set-url origin git@github.com:benbrastmckie/nvim.git` (or keep as .config.git)
- [ ] Force push all branches: `git push --force --all`
- [ ] Force push tags: `git push --force --tags`
- [ ] Verify remote updated: `git fetch origin && git log origin/himalaya --oneline -5`

**Timing**: 10 minutes

**Files to modify**: None (git operations only)

**Verification**:
- git push completes without error
- git fetch shows updated remote
- Remote history matches local

---

### Phase 6: Post-Migration Verification [COMPLETED]

**Goal**: Verify Neovim functions correctly and clean up

**Tasks**:
- [ ] Test Neovim loads: `nvim --headless -c "lua print('OK')" -c "q"`
- [ ] Test Neovim checkhealth: `nvim --headless -c "checkhealth" -c "q"`
- [ ] Verify task management works: `cat specs/TODO.md | head -20`
- [ ] Verify state.json accessible: `cat specs/state.json | head -10`
- [ ] Clean up temporary clone: `rm -rf /tmp/nvim-config`
- [ ] Clean up old backup (after confirming success): Keep ~/.config/.git.backup.old for 1 week
- [ ] Update any hardcoded paths in CLAUDE.md if needed

**Timing**: 15 minutes

**Files to modify**:
- `~/.config/nvim/CLAUDE.md` - Update paths if needed (verify first)

**Verification**:
- nvim --headless commands succeed
- Task management files readable
- Temporary files cleaned up

## Testing & Validation

- [ ] git status shows clean working tree in ~/.config/nvim
- [ ] nvim --headless -c "lua require('lazy')" -c "q" succeeds (plugin manager loads)
- [ ] git log shows preserved history for lua/, .claude/, specs/
- [ ] No nvim/ prefix in file paths within commits
- [ ] Remote repository updated with new structure
- [ ] Original .config/ directory has backup of .git

## Artifacts & Outputs

- plans/implementation-001.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (on completion)
- ~/.config/nvim/.git/ (migrated repository)
- ~/.config/nvim/.claude/ (preserved task management)
- ~/.config/nvim/specs/ (preserved artifacts)

## Rollback/Contingency

If migration fails:
1. Remove failed .git from nvim/: `rm -rf ~/.config/nvim/.git`
2. Restore backup: `mv ~/.config/.git.backup.old ~/.config/.git`
3. Verify original repo works: `cd ~/.config && git status`
4. Clean up copied files: `rm -rf ~/.config/nvim/.claude ~/.config/nvim/specs ~/.config/nvim/CLAUDE.md`

If push fails:
1. Do not force push again immediately
2. Verify remote access: `git ls-remote origin`
3. Check for branch protection rules on GitHub
4. Consider creating new repository if remote is corrupted
