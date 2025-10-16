# Worktree Session Cross-Repository Issues Research Report

## Metadata
- **Date**: 2025-09-30
- **Scope**: Analysis of worktree deletion and cleanup failures in Claude session management
- **Primary Directory**: nvim/lua/neotex/plugins/ai/claude/core/worktree
- **Files Analyzed**: 8 files (ui_handlers.lua, session_manager.lua, git_operations.lua, index.lua)

## Executive Summary

The Claude worktree session management system has critical bugs when sessions from different git repositories are persisted in a shared session file. The system attempts to delete worktrees from Repository A while operating in Repository B, causing "not a git repository" errors. Additionally, the stale session detection is flawed - it only checks directory existence rather than git worktree registration, allowing orphaned sessions to persist indefinitely.

**Required Behavior (User Requirements):**
1. `<leader>av` picker must ONLY show worktrees for the currently open git repository
2. Opening `<leader>av` must automatically clean up stale sessions that were already removed
3. Stale worktrees that still exist but aren't registered should be shown and cleanable via `<C-x>`
4. All operations must run in the correct git repository context

### Critical Issues
1. **Cross-repository sessions shown** - Sessions from ModelChecker repo shown when in .config repo (MUST HIDE)
2. **No automatic cleanup on picker open** - Removed worktrees persist until manual `<C-x>` cleanup
3. **Wrong git context for commands** - Git commands run in wrong directory, not the worktree's repo
4. **Flawed stale detection** - Only checks `test -d`, not actual git worktree registration
5. **No repository association** - Sessions don't track which git repo they belong to

## Problem Analysis

### Issue 1: Cross-Repository Session Persistence

**Current Behavior:**
```json
// ~/.local/share/nvim/claude-worktree-sessions.json
{
  "type_hints": {
    "worktree_path": "/home/benjamin/Documents/Philosophy/Projects/ModelChecker-refactor-type_hints",
    "branch": "refactor/type_hints",
    ...
  }
}
```

Sessions from **ModelChecker** repo are stored in the same file as sessions from **.config** repo.

**When Opening Picker in .config Repo:**
- Picker shows both .config worktrees AND ModelChecker worktrees
- User tries to delete a ModelChecker worktree
- Git commands fail: "not a git repository"

**Root Cause:**
Sessions are stored globally across all repositories without tracking which repo they belong to.

### Issue 2: Wrong Git Context

**Current Implementation (ui_handlers.lua:505-514):**
```lua
local parent_dir = vim.fn.fnamemodify(entry.worktree, ':h')

Job:new({
  command = "git",
  args = { "worktree", "remove", entry.worktree, "--force" },
  cwd = parent_dir,  -- WRONG: Just parent of worktree path
  ...
}):start()
```

**Problem:**
- `:h` modifier just removes last path component
- For `/home/user/Projects/ModelChecker-feature-foo`, parent is `/home/user/Projects`
- That directory is NOT a git repository!
- Git commands fail because cwd is not in any git repo

**Correct Approach:**
Need to find the **main git repository root** that owns this worktree:
```lua
-- Get the git root from worktree list
local worktrees = git_ops.list_worktrees()
local main_repo_root = nil
for _, wt in ipairs(worktrees) do
  if wt.path then
    main_repo_root = git_ops.get_git_root() -- when in main repo
    break
  end
end
```

But wait - we can't get the git root if we're in the wrong repository!

### Issue 3: Flawed Stale Detection

**Current Implementation (ui_handlers.lua:662-664):**
```lua
local exists = vim.fn.system("test -d " .. session.worktree_path .. " && echo 1 || echo 0")
if vim.trim(exists) == "0" then
  sessions[name] = nil  -- Mark as stale
  ...
end
```

**Problem:**
- Only checks if directory exists
- Doesn't check if worktree is registered in git
- A worktree directory can exist but not be in `git worktree list`!
- A worktree from a different repo will have an existing directory

**Example Scenario:**
1. User creates ModelChecker worktree
2. User switches to .config repo
3. ModelChecker worktree directory still exists at `/home/.../ModelChecker-feature-foo`
4. Cleanup says "directory exists, not stale!"
5. But it's not in `.config`'s git worktree list
6. Session persists even though it's irrelevant to current repo

**Correct Detection:**
```lua
-- Check if worktree is in current repo's worktree list
local git_ops = require('...')
local current_worktrees = git_ops.list_worktrees()
local found_in_git = false

for _, wt in ipairs(current_worktrees) do
  if wt.path == session.worktree_path or wt.branch == session.branch then
    found_in_git = true
    break
  end
end

-- Stale if not in git OR directory doesn't exist
if not found_in_git or not vim.fn.isdirectory(session.worktree_path) then
  -- Stale!
end
```

### Issue 4: Git Worktree Prune Not Used

**From Web Research:**
Git provides `git worktree prune` specifically for cleaning up administrative files for deleted worktrees.

**Current Code:**
Does NOT use `git worktree prune` anywhere!

**When It's Needed:**
- When a worktree directory is manually deleted
- When `git worktree remove` fails
- Before attempting to delete a branch whose worktree is gone

**Proper Flow:**
```bash
# Try to remove worktree
git worktree remove /path/to/worktree

# If that fails because directory is already gone:
git worktree prune  # Clean up administrative files

# Then delete the branch
git branch -D branch-name
```

## Technical Details

### Session Data Structure

Current format lacks repository identification:
```json
{
  "session-name": {
    "worktree_path": "/full/path/to/worktree",
    "branch": "feature/name",
    "type": "feature",
    "created": "2025-09-30 16:00"
    // MISSING: git_root or repo_id!
  }
}
```

### Git Worktree Command Context

**Critical Rule:**
All `git worktree` commands must be run from within a git repository that owns those worktrees!

**Current Violations:**
1. Line 506: `local parent_dir = vim.fn.fnamemodify(entry.worktree, ':h')`
   - Gets `/home/user/Projects` not the git repo root
   - Not necessarily a git repository

2. Line 514: `cwd = parent_dir`
   - Runs git in a non-repo directory
   - Results in "not a git repository" error

**Correct Approach:**
```lua
-- Option 1: Store git_root in session data
local git_root = session.git_root  -- Get from session

-- Option 2: Discover from worktree path (unreliable if deleted)
-- Navigate up from worktree path looking for .git

-- Option 3: Use current git root (WRONG for cross-repo)
local git_root = git_ops.get_git_root()  -- Only works if same repo

-- Option 4: Try to infer from branch name in git worktree list
-- Search all repos? Not practical.

-- BEST: Store git_root when creating session
```

### Worktree List Detection

**Current `git worktree list` Output (in .config repo):**
```
worktree /home/benjamin/.config
HEAD ce6c6e7
branch refs/heads/refactor/claude-simplification
```

**Sessions Show:**
```
- ModelChecker (not in this repo's worktree list!)
- ModelChecker-refactor-type_hints (not in this repo's worktree list!)
```

**Detection Logic Should:**
1. Get current repo's worktree list
2. Filter sessions to only show sessions for current repo
3. Mark sessions from other repos as "different repository"
4. Don't show cross-repo sessions in picker (or show separately)

## Root Causes

### Primary Root Cause
**Global session storage without repository scoping**

The session file at `~/.local/share/nvim/claude-worktree-sessions.json` stores sessions from ALL repositories in a single file, but the system assumes all sessions belong to the current repository.

### Secondary Root Causes

1. **No repository identification in session data**
   - Sessions don't store `git_root` field
   - Can't determine which repo owns a session
   - Can't filter by repository

2. **Incorrect git command execution directory**
   - Uses `fnamemodify(path, ':h')` which is NOT the git root
   - Should use `git rev-parse --show-toplevel` or stored git_root

3. **Stale detection only checks directory existence**
   - Should check `git worktree list` registration
   - Should verify worktree belongs to current repo
   - Current check: `test -d <path>` (insufficient)

4. **Missing git worktree prune**
   - Not used anywhere in the codebase
   - Needed when worktrees are manually deleted
   - Prevents administrative file buildup

## Failure Scenarios

### Scenario 1: Cross-Repository Deletion
```
1. User creates worktree in ModelChecker repo
2. User switches to .config repo
3. User opens <leader>av picker
4. Picker shows ModelChecker worktree (shouldn't!)
5. User presses Ctrl-d to delete it
6. parent_dir = "/home/user/Documents/Philosophy/Projects"
7. Git runs in that directory (NOT a git repo)
8. ERROR: "not a git repository"
```

### Scenario 2: Orphaned Session Persists
```
1. Worktree deleted manually (outside Neovim)
2. User runs Ctrl-x cleanup
3. Check: test -d /path/to/worktree
4. Directory still exists (was deleted from git, not filesystem)
5. Cleanup says "not stale" because directory exists
6. Session persists indefinitely
```

### Scenario 3: Git Worktree Prune Needed
```
1. User deletes worktree directory manually
2. Git still has administrative files in .git/worktrees/
3. Try to delete branch: error "worktree still exists"
4. Need to run: git worktree prune
5. Currently not implemented
```

## Recommendations

### Solution 1: Add Repository Scoping with Auto-Cleanup (REQUIRED)

**Add git_root field to sessions:**
```lua
sessions[name] = {
  worktree_path = worktree_path,
  branch = branch,
  type = type,
  git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", ""),  -- ADD THIS
  created = os.date("%Y-%m-%d %H:%M"),
}
```

**Filter sessions by current repository WITH automatic cleanup on picker open:**
```lua
function M.telescope_sessions(...)
  local current_git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
  local git_ops = require('neotex.plugins.ai.claude.core.worktree.git_operations')
  local registered_worktrees = git_ops.list_worktrees()

  -- Build set of registered worktree paths for current repo
  local registered_paths = {}
  for _, wt in ipairs(registered_worktrees) do
    registered_paths[wt.path] = true
  end

  -- Filter to only sessions for current repository AND auto-cleanup
  local relevant_sessions = {}
  local removed_count = 0

  for name, session in pairs(sessions) do
    -- Skip sessions from other repositories (don't show, don't delete from storage)
    if session.git_root and session.git_root ~= current_git_root then
      -- Keep in global storage but don't show
      goto continue
    end

    -- For sessions in current repo, check if they're stale
    local is_stale = false

    -- AUTOMATIC CLEANUP: Stale if directory doesn't exist
    if vim.fn.isdirectory(session.worktree_path) == 0 then
      is_stale = true
    end

    -- AUTOMATIC CLEANUP: Stale if not in git worktree list
    if not registered_paths[session.worktree_path] then
      is_stale = true
    end

    if is_stale then
      -- AUTO-REMOVE stale session from storage
      sessions[name] = nil
      removed_count = removed_count + 1
    else
      -- Keep for display
      relevant_sessions[name] = session
    end

    ::continue::
  end

  -- Save sessions after auto-cleanup
  if removed_count > 0 then
    save_sessions_fn(sessions)
    vim.notify(string.format("Auto-cleaned %d stale session(s)", removed_count), vim.log.levels.INFO)
  end

  -- Use relevant_sessions in picker instead of all sessions
  -- Now only shows current repo's active sessions
end
```

**Key Changes:**
1. **Repository filtering**: Only shows sessions where `git_root == current_git_root`
2. **Automatic cleanup on open**: Removes stale sessions before showing picker
3. **Preserve cross-repo sessions**: Sessions from other repos stay in storage but aren't shown
4. **Dual stale detection**: Directory missing OR not in git worktree list

### Solution 2: Fix Git Command Execution (REQUIRED)

**Use stored git_root for commands:**
```lua
-- Ctrl-d delete operation
local git_root = entry.git_root or vim.fn.getcwd()  -- Fallback to cwd for old sessions

Job:new({
  command = "git",
  args = { "worktree", "remove", entry.worktree, "--force" },
  cwd = git_root,  -- Use the repo that owns this worktree!
  ...
}):start()
```

### Solution 3: Enhanced Ctrl-x Manual Cleanup (REQUIRED)

**Note**: Since automatic cleanup happens on picker open, Ctrl-x now handles edge cases and provides user control.

**Enhanced Ctrl-x for remaining stale detection:**
```lua
-- Ctrl-x: Manual cleanup of edge cases
local cleanup_stale = function(prompt_bufnr)
  local git_ops = require('neotex.plugins.ai.claude.core.worktree.git_operations')
  local current_git_root = git_ops.get_git_root()
  local registered_worktrees = git_ops.list_worktrees()

  -- Build set of registered paths
  local registered_paths = {}
  for _, wt in ipairs(registered_worktrees) do
    registered_paths[wt.path] = true
  end

  -- Check each session IN CURRENT REPO ONLY
  local cleaned = 0
  local cleaned_names = {}

  for name, session in pairs(sessions) do
    -- Skip sessions from other repos
    if session.git_root and session.git_root ~= current_git_root then
      goto continue
    end

    local is_stale = false

    -- Stale if not in git worktree list (already removed from git)
    if not registered_paths[session.worktree_path] then
      is_stale = true
    end

    -- Stale if directory doesn't exist
    if vim.fn.isdirectory(session.worktree_path) == 0 then
      is_stale = true
    end

    if is_stale then
      sessions[name] = nil
      cleaned = cleaned + 1
      table.insert(cleaned_names, name)
    end

    ::continue::
  end

  if cleaned > 0 then
    save_sessions_fn(sessions)
    vim.notify(
      string.format("Cleaned up %d stale session(s): %s", cleaned, table.concat(cleaned_names, ", ")),
      vim.log.levels.INFO
    )

    -- Refresh picker to show updated list
    actions.close(prompt_bufnr)
    vim.schedule(function()
      M.telescope_sessions(sessions, current_session_ref, config, sync_with_git_fn, save_sessions_fn)
    end)
  else
    vim.notify("No stale sessions found", vim.log.levels.INFO)
  end
end
```

**Behavior:**
- Ctrl-x only operates on current repo's sessions
- Redundant with auto-cleanup, but gives user manual control
- Useful if sessions become stale while picker is open
- Always refreshes picker after cleanup

### Solution 4: Add Git Worktree Prune (RECOMMENDED)

**Add prune before branch deletion:**
```lua
-- After failed worktree remove OR before branch delete
Job:new({
  command = "git",
  args = { "worktree", "prune" },
  cwd = git_root,
  on_exit = function()
    -- Now safe to delete branch
    Job:new({
      command = "git",
      args = { "branch", "-D", branch },
      cwd = git_root,
      ...
    }):start()
  end
}):start()
```

### Solution 5: Handle Deletion of Missing Worktrees (RECOMMENDED)

**Check if worktree exists before trying to remove:**
```lua
-- Check if worktree directory exists
if vim.fn.isdirectory(entry.worktree) == 0 then
  -- Directory already gone, just prune and delete branch
  Job:new({
    command = "git",
    args = { "worktree", "prune" },
    cwd = git_root,
    on_exit = function()
      -- Delete branch
      -- Remove from sessions
      -- Notify user
    end
  }):start()
else
  -- Directory exists, remove normally
  Job:new({
    command = "git",
    args = { "worktree", "remove", entry.worktree, "--force" },
    cwd = git_root,
    ...
  }):start()
end
```

## Implementation Priority

### Critical (Must Fix - Per User Requirements)
1. **Add git_root to session data** - Track which repository owns each session
2. **Automatic cleanup on picker open** - Remove stale sessions when opening `<leader>av`
3. **Repository filtering** - Only show sessions for current git repository
4. **Use git_root for git commands** - Fix "not a git repository" errors

### High Priority
5. **Fix Ctrl-x cleanup** - Check git worktree list, not just directory existence
6. **Add git worktree prune** - Handle manually deleted worktrees
7. **Preserve cross-repo sessions** - Keep in storage but don't display

### Medium Priority
8. **Migration for existing sessions** - Add git_root to old session data
9. **Better error messages** - Distinguish between different failure modes

## User Requirements Summary

**When user opens `<leader>av`:**
1. ✓ Shows ONLY worktrees from current git repository
2. ✓ Automatically removes stale sessions (deleted from git or missing directories)
3. ✓ Notifies user of auto-cleanup count

**When user presses `<C-x>`:**
1. ✓ Scans current repo's sessions for stale entries
2. ✓ Removes any found (redundant with auto-cleanup but gives manual control)
3. ✓ Refreshes picker to show updated list

**What makes a session "stale":**
1. Directory doesn't exist at worktree_path
2. Not registered in `git worktree list` for current repo
3. Both checks must be performed

## Migration Strategy

### For Existing Sessions Without git_root

**Option 1: Best Effort Discovery**
```lua
-- Try to discover git_root from worktree path
local function discover_git_root(worktree_path)
  -- Try common patterns
  local base_name = vim.fn.fnamemodify(worktree_path, ':t')
  -- e.g., "ModelChecker-feature-foo" -> "ModelChecker"
  local project = base_name:match("^([^%-]+)")

  local parent = vim.fn.fnamemodify(worktree_path, ':h')
  local potential_root = parent .. "/" .. project

  -- Check if it's a git repo
  local result = vim.fn.system("cd " .. potential_root .. " && git rev-parse --show-toplevel 2>/dev/null")
  if vim.v.shell_error == 0 then
    return vim.trim(result)
  end

  return nil
end
```

**Option 2: Remove Old Sessions**
```lua
-- On load, remove sessions without git_root
for name, session in pairs(sessions) do
  if not session.git_root then
    vim.notify("Removing legacy session without git_root: " .. name, vim.log.levels.WARN)
    sessions[name] = nil
  end
end
```

**Option 3: Manual Re-Registration**
Ask user to recreate sessions (cleanest but requires user action).

## Code References

### Files Requiring Changes

1. **ui_handlers.lua:58-135** - `create_worktree_with_claude()`
   - Add git_root to session data when creating

2. **ui_handlers.lua:505-557** - `delete_session()` in Ctrl-d mapping
   - Use session.git_root for git commands
   - Add worktree existence check
   - Implement git worktree prune

3. **ui_handlers.lua:661-668** - Stale detection in Ctrl-x mapping
   - Check git worktree list registration
   - Compare session.git_root to current repo
   - Mark cross-repo sessions as stale

4. **ui_handlers.lua:207-217** - `telescope_sessions()` main function
   - Filter sessions to current repository
   - Or separate cross-repo sessions into different section

5. **session_manager.lua:179-207** - `save/restore_sessions()`
   - Handle sessions from multiple repositories
   - Consider per-repo session files

6. **git_operations.lua** - Add helper functions
   - `is_worktree_registered(path)` - Check if in git worktree list
   - `prune_worktrees()` - Wrapper for git worktree prune
   - `get_repo_for_worktree(path)` - Find which repo owns a worktree

### Session Data Schema Update

**Old Schema:**
```lua
{
  worktree_path = string,
  branch = string,
  type = string,
  created = string,
  session_id = string,
  tab_id = string|nil
}
```

**New Schema:**
```lua
{
  worktree_path = string,
  branch = string,
  type = string,
  created = string,
  session_id = string,
  tab_id = string|nil,
  git_root = string,  -- NEW: Repository root path
}
```

## Testing Approach

### Test Case 1: Cross-Repository Sessions
```
1. Create worktree in Repo A
2. Switch to Repo B (different git repo)
3. Open <leader>av
4. Verify: Should NOT show Repo A sessions
5. Or: Show in separate section labeled "Other Repositories"
```

### Test Case 2: Orphaned Worktree Cleanup
```
1. Create worktree
2. Manually delete worktree directory (rm -rf)
3. Run Ctrl-x cleanup
4. Verify: Session is detected as stale and removed
```

### Test Case 3: Missing Worktree Deletion
```
1. Create worktree
2. Manually delete worktree directory
3. Run Ctrl-d to delete the session
4. Verify: Uses git worktree prune
5. Verify: Branch is deleted successfully
6. Verify: Session is removed from JSON
```

### Test Case 4: Same-Repository Operations
```
1. Create worktrees in current repo
2. Run all Ctrl operations (d/t/o/n/x/h)
3. Verify: All operations work correctly
4. Verify: No "not a git repository" errors
```

## Alternative Approaches

### Approach A: Per-Repository Session Files
Instead of one global session file, use:
```
~/.local/share/nvim/claude-worktrees/<repo-hash>.json
```

**Pros:**
- Natural repository isolation
- No need for git_root filtering
- Simpler logic

**Cons:**
- More complex file management
- Need hash generation
- Harder to migrate existing sessions

### Approach B: Hybrid - Session Registry
```json
// ~/.local/share/nvim/claude-session-registry.json
{
  "/home/user/.config": {
    "git_root": "/home/user/.config",
    "sessions": { ... }
  },
  "/home/user/Projects/ModelChecker": {
    "git_root": "/home/user/Projects/ModelChecker",
    "sessions": { ... }
  }
}
```

**Pros:**
- Clear repository separation
- Easy to manage
- Good migration path

**Cons:**
- More nesting
- Slightly more complex access patterns

## References

### Codebase Files
- ui_handlers.lua:467-557 - Delete session implementation
- ui_handlers.lua:650-686 - Cleanup stale implementation
- session_manager.lua:179-207 - Session persistence
- git_operations.lua:114-122 - Git root detection

### External Resources
- Git Worktree Documentation: https://git-scm.com/docs/git-worktree
- Stack Overflow: "How to delete a git working tree branch when its working directory has been removed"
- Git worktree prune command reference

### Related Reports
- claude-worktree-branch-analysis.md - Earlier analysis of worktree branch issues

## Next Steps

1. **Implement git_root field** in session creation (ui_handlers.lua:98-135)
2. **Update deletion logic** to use session.git_root (ui_handlers.lua:505-557)
3. **Fix stale detection** to check git worktree list (ui_handlers.lua:661-668)
4. **Add repository filtering** to telescope picker (ui_handlers.lua:207-331)
5. **Add git worktree prune** to deletion flow (ui_handlers.lua:507-556)
6. **Migrate existing sessions** - Either remove or attempt discovery

## Impact Assessment

**Without Fix:**
- Ctrl-d fails for any cross-repo session (100% failure rate)
- Ctrl-x never detects orphaned sessions (0% effectiveness)
- Sessions accumulate across all repos (memory leak)
- User confusion from seeing irrelevant sessions

**With Fix:**
- Ctrl-d works correctly in all scenarios
- Ctrl-x properly detects all stale sessions
- Each repo shows only its own sessions
- Clean, repo-scoped session management
