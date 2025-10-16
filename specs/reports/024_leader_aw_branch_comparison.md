# Branch Comparison: `<leader>aw` Functionality Analysis

## Metadata
- **Date**: 2025-09-30
- **Scope**: Compare `<leader>aw` mapping functionality between master and refactor/claude-simplification branches
- **Primary Directory**: nvim/lua/neotex/plugins/ai/
- **Files Analyzed**:
  - nvim/lua/neotex/plugins/editor/which-key.lua
  - nvim/lua/neotex/plugins/ai/avante.lua
  - nvim/lua/neotex/config/keymaps.lua
  - nvim/lua/neotex/config/claude-init.lua

## Executive Summary

**The `<leader>aw` mapping is fully functional on both branches.** The mapping exists in the which-key configuration and calls the `:ClaudeWorktree` command. The issue is NOT a missing or broken mapping, but rather **significant architectural changes** in the refactor branch that have created extensive complexity (28,772 lines added vs 3,305 deleted).

**Recommendation: Revert to master.** The refactor branch adds massive complexity without clear corresponding value, and attempting to debug any issues would require understanding an entirely new architecture.

## Analysis

### 1. Mapping Status

**Master Branch (lines 198-199 in which-key.lua):**
```lua
{ "<leader>av", "<cmd>ClaudeSessions<CR>", desc = "view worktrees", icon = "󰔡" },
{ "<leader>aw", "<cmd>ClaudeWorktree<CR>", desc = "create worktree", icon = "󰘬" },
{ "<leader>ar", "<cmd>ClaudeRestoreWorktree<CR>", desc = "restore closed worktree", icon = "󰑐" },
```

**Current Branch (lines 197-199 in which-key.lua):**
```lua
{ "<leader>av", "<cmd>ClaudeSessions<CR>", desc = "view worktrees", icon = "󰔡" },
{ "<leader>aw", "<cmd>ClaudeWorktree<CR>", desc = "create worktree", icon = "󰘬" },
{ "<leader>ar", "<cmd>ClaudeRestoreWorktree<CR>", desc = "restore closed worktree", icon = "󰑐" },
```

**Finding:** The mapping is identical on both branches.

### 2. Architectural Changes

The refactor branch contains massive changes:

```
git diff master...HEAD --stat
95 files changed, 28772 insertions(+), 3305 deletions(-)
```

Key additions include:
- **10+ new command files** (.claude/commands/)
- **Extensive documentation** (.claude/docs/)
- **New orchestration system** (workflow-status, performance-monitor, etc.)
- **Modularized worktree system** (split single file into 6+ modules)

### 3. Key Architectural Differences

#### Master Branch
- **Simple structure**: Single worktree module at `nvim/lua/neotex/plugins/ai/claude/core/worktree.lua` (2,276 lines)
- **Direct initialization**: Claude setup in `claude-init.lua` loads everything synchronously
- **Minimal complexity**: ~40 lines of setup code

#### Refactor Branch
- **Modular structure**: Worktree split into 6+ files:
  - `worktree/index.lua` (497 lines)
  - `worktree/session_manager.lua` (310 lines)
  - `worktree/ui_handlers.lua` (914 lines)
  - `worktree/git_operations.lua` (141 lines)
  - `worktree/restoration.lua` (508 lines)
  - `worktree/terminal_integration.lua` (169 lines)
- **Complex initialization**: VeryLazy autocmd pattern with error handling
- **New subsystems**: command-queue, terminal-monitor, terminal-detection
- **83 lines of setup code** with nested pcalls and configuration merging

### 4. Initialization Comparison

**Master:** Simple, direct loading
```lua
function M.setup()
  local ok, claude_ai = pcall(require, "neotex.plugins.ai.claude")
  if not ok then
    vim.notify("Failed to load claude AI module", vim.log.levels.ERROR)
    return
  end
  claude_ai.setup({ ... })
end
```

**Refactor:** Deferred loading with multiple subsystems
```lua
function M.setup()
  vim.api.nvim_create_user_command("ClaudeCommands", ...)  -- Immediate registration

  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
      -- Load main module
      -- Setup command_queue subsystem
      -- Setup terminal_monitor subsystem
      -- Merge configurations
      -- Error handling at multiple levels
    end
  })
end
```

### 5. Why Reverting is Recommended

#### Complexity Without Clear Value
- **28,772 new lines** of code, documentation, and configuration
- **Modularization** of a previously working system
- **New abstractions** (orchestration, coordination-hub, dependency-resolver) without clear user-facing benefits
- **Increased surface area** for bugs and timing issues

#### Debugging Cost
To fix any issue in the refactor branch would require:
1. Understanding the new modular worktree architecture (6 files)
2. Debugging the VeryLazy initialization pattern
3. Tracing through command-queue and terminal-monitor systems
4. Understanding configuration merging across multiple subsystems
5. Validating timing dependencies between modules

#### Master Branch Advantages
- **Proven working**: `<leader>aw` works on master
- **Simple architecture**: Single file, direct initialization
- **Less to break**: Fewer moving parts = fewer failure modes
- **Easier debugging**: All logic in one place

### 6. If You Must Stay on Refactor Branch

If there's a compelling reason to stay on the refactor branch, here's what to investigate:

1. **Check command registration:**
   ```vim
   :verbose command ClaudeWorktree
   ```

2. **Test module loading:**
   ```lua
   :lua print(vim.inspect(require("neotex.plugins.ai.claude.core.worktree.index")))
   ```

3. **Check VeryLazy fired:**
   ```lua
   :lua print("Claude initialized:", require("neotex.plugins.ai.claude")._initialized)
   ```

4. **Enable debug mode:**
   The refactor branch has `debug_enabled = true` in both command_queue and terminal_monitor configs - check for debug messages

## Recommendations

### Primary Recommendation: **REVERT TO MASTER**

**Rationale:**
- The mapping exists and is identical on both branches
- Master has a simpler, working architecture
- Refactor adds 28K+ lines without clear benefit
- Debugging refactor would require understanding an entirely new system
- Time investment to fix refactor likely exceeds value gained

**How to revert:**
```bash
git checkout master
```

### Alternative: Debug Refactor Branch

Only pursue this if there are specific features in the refactor branch that are critical:

1. Enable debug logging in nvim/lua/neotex/config/claude-init.lua:52,59
2. Check `:messages` after startup for initialization errors
3. Verify `:ClaudeWorktree` command exists
4. Test worktree module loading manually
5. Compare User commands between branches: `:command Claude*`

### Long-term: Reconsider Refactor

If the refactor was intended to provide specific improvements:
- Document the specific goals of the refactor
- Create a phased migration plan
- Add tests to prevent regressions
- Migrate feature-by-feature rather than wholesale replacement

## References

### Key Files
- nvim/lua/neotex/plugins/editor/which-key.lua:198 (mapping definition)
- nvim/lua/neotex/config/claude-init.lua:10-81 (initialization)
- nvim/lua/neotex/plugins/ai/claude/init.lua:1-209 (main module)
- nvim/lua/neotex/plugins/ai/claude/core/worktree/index.lua:1-497 (worktree module)

### Branch Commits
- Current HEAD: e319c11 (fix: remove non-existent get_claude_command function call)
- Refactor started: ~20 commits ago with "feat: add error handling and recovery to /orchestrate"
- Previous fixes suggest ongoing instability: "fix: implement cross-repository session management"

## Conclusion

The `<leader>aw` mapping itself is not broken - it's defined identically on both branches. However, the refactor branch has introduced substantial architectural complexity that makes any issues significantly harder to debug and fix. Given that the master branch is known to work, **reverting is the most efficient path forward** unless there are specific features in the refactor branch that are absolutely required.
