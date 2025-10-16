# Claude Module Refactor - Testing Plan

## Overview
Comprehensive testing strategy for verifying the refactored Claude modules work correctly after implementing the clean architecture design from `refactor_claude.md`.

## Testing Approach
Manual testing without formal test framework, focusing on real-world usage and integration verification.

## Test Categories

### 1. Module Loading Tests
Verify all modules load without errors and dependencies resolve correctly.

#### Test Cases
- [ ] Basic module loading: `require("neotex.ai-claude")` succeeds
- [ ] All submodules load without errors
  - [ ] `neotex.ai-claude.config`
  - [ ] `neotex.ai-claude.core.session`
  - [ ] `neotex.ai-claude.core.worktree`
  - [ ] `neotex.ai-claude.core.visual`
  - [ ] `neotex.ai-claude.infra.persistence`
  - [ ] `neotex.ai-claude.infra.git`
  - [ ] `neotex.ai-claude.infra.terminal`
  - [ ] `neotex.ai-claude.ui.telescope`
- [ ] No circular dependency errors
- [ ] No missing module errors

#### Test Commands
```bash
# Basic load test
nvim --headless +'lua require("neotex.ai-claude")' +qa

# Submodule test
nvim --headless +'lua
  local modules = {
    "neotex.ai-claude.config",
    "neotex.ai-claude.core.session",
    "neotex.ai-claude.core.worktree",
    "neotex.ai-claude.core.visual"
  }
  for _, m in ipairs(modules) do
    local ok, err = pcall(require, m)
    print(m, ":", ok and "OK" or err)
  end
' +qa
```

### 2. Initialization Tests
Test the setup process and configuration management.

#### Test Cases
- [ ] `claude.setup()` with default config works
- [ ] `claude.setup()` with custom config applies settings
- [ ] Multiple setup calls are idempotent (no errors)
- [ ] `is_initialized` flag prevents re-initialization
- [ ] Configuration validation catches invalid options

#### Test Commands
```lua
-- Default setup
local claude = require("neotex.ai-claude")
claude.setup()
assert(claude.is_initialized == true)

-- Custom config
claude.setup({
  session = { max_age_hours = 72 },
  worktree = { default_type = "bugfix" }
})

-- Verify config applied
local config = require("neotex.ai-claude.config").get()
assert(config.session.max_age_hours == 72)
assert(config.worktree.default_type == "bugfix")
```

### 3. Session Management Tests
Verify session creation, persistence, and restoration.

#### Test Cases
- [ ] `smart_toggle()` opens a new session when none exists
- [ ] `smart_toggle()` closes an active session
- [ ] `resume_session()` without ID shows picker
- [ ] `resume_session(id)` loads specific session
- [ ] `save_session_state()` persists to disk
- [ ] `list_sessions()` returns all available sessions
- [ ] Session restoration based on branch context
- [ ] Session restoration based on worktree context
- [ ] Old sessions (>48h) are not auto-restored

#### Test Commands
```lua
local claude = require("neotex.ai-claude")
claude.setup()

-- Test toggle
local ok1, err1 = claude.smart_toggle()  -- Should open
print("Open:", ok1, err1)

local ok2, err2 = claude.smart_toggle()  -- Should close
print("Close:", ok2, err2)

-- Test session list
local sessions = claude.list_sessions()
print("Sessions found:", #sessions)

-- Test save
claude.save_session_state()
```

### 4. Worktree Management Tests
Verify worktree operations and git integration.

#### Test Cases
- [ ] `create_worktree_with_claude()` creates new worktree
- [ ] Worktree creation validates git repository
- [ ] `list_worktrees()` returns existing worktrees
- [ ] `switch_worktree()` changes directories correctly
- [ ] `delete_worktree()` removes worktree and cleans up
- [ ] Session association with worktree works
- [ ] WezTerm integration spawns tabs (if enabled)

#### Test Commands
```lua
local claude = require("neotex.ai-claude")
claude.setup()

-- List worktrees
local worktrees = claude.list_worktrees()
for _, wt in ipairs(worktrees) do
  print(wt.branch, wt.path)
end

-- Create worktree (interactive)
-- claude.create_worktree_with_claude({
--   name = "test-feature",
--   type = "feature"
-- })
```

### 5. Visual Selection Tests
Test sending visual selections to Claude.

#### Test Cases
- [ ] `send_visual_to_claude()` with provided text
- [ ] Visual selection extraction from buffer
- [ ] Context inclusion (filename, filetype, range)
- [ ] Message formatting with code blocks
- [ ] Queue functionality when Claude unavailable
- [ ] Prompt template application

#### Test Commands
```lua
local claude = require("neotex.ai-claude")
claude.setup()

-- Test with explicit text
local ok, err = claude.send_visual_to_claude({
  text = "function hello() return 'world' end",
  context = {
    filename = "test.lua",
    filetype = "lua"
  }
})
print("Send result:", ok, err)
```

### 6. Command Tests
Verify all user commands work correctly.

#### Test Cases
- [ ] `:ClaudeToggle` toggles session
- [ ] `:ClaudeSessions` opens session picker
- [ ] `:ClaudeWorktree` prompts for creation
- [ ] `:ClaudeWorktrees` shows worktree picker
- [ ] `:ClaudeRestoreWorktree` switches worktree
- [ ] `:ClaudeSendVisual` sends selection
- [ ] `:ClaudeNativeSessions` finds native sessions
- [ ] `:ClaudeHealth` displays health status

#### Test Commands
```vim
" Test each command
:ClaudeHealth
:ClaudeSessions
:ClaudeWorktrees
:echo "Visual test" | normal V | ClaudeSendVisual
```

### 7. Keybinding Tests
Verify all keybindings work in appropriate modes.

#### Test Cases
- [ ] `<C-c>` toggles Claude in normal mode
- [ ] `<C-c>` toggles Claude in insert mode
- [ ] `<C-c>` toggles Claude in visual mode
- [ ] `<C-c>` toggles Claude in terminal mode
- [ ] `<leader>as` opens session picker
- [ ] `<leader>aw` creates worktree
- [ ] `<leader>av` views worktrees
- [ ] No keymap conflicts detected

#### Test Commands
```vim
" Check keymaps
:verbose map <C-c>
:verbose map <leader>a

" Test in different modes
:normal <C-c>
:startinsert | execute "normal \<C-c>"
```

### 8. Infrastructure Layer Tests
Test I/O operations and external integrations.

#### Git Operations
- [ ] Git commands execute correctly
- [ ] Repository detection works
- [ ] Branch operations succeed
- [ ] Worktree operations complete
- [ ] Non-git directories handled gracefully

#### Terminal Operations
- [ ] Claude buffer detection works
- [ ] Terminal spawning succeeds
- [ ] Message sending to Claude works
- [ ] WezTerm CLI integration (if available)

#### Persistence Operations
- [ ] Session files saved to correct location
- [ ] JSONL format correctly written
- [ ] Session loading parses JSONL
- [ ] Native session detection works
- [ ] Corrupted files handled gracefully

### 9. UI/Telescope Tests
Verify telescope pickers and previews.

#### Test Cases
- [ ] Session picker displays sessions
- [ ] Session preview shows correct info
- [ ] Worktree picker displays worktrees
- [ ] Worktree preview shows details
- [ ] Selection callbacks execute
- [ ] Delete action (`<C-d>`) works
- [ ] Create new action (`<C-n>`) works
- [ ] Age formatting displays correctly

### 10. Error Handling Tests
Verify graceful failure and helpful error messages.

#### Test Cases
- [ ] Non-git directory: Clear error message
- [ ] Claude not installed: Helpful error
- [ ] Invalid session ID: Graceful failure
- [ ] Corrupted session file: Recovery attempt
- [ ] Missing dependencies: Clear message
- [ ] Config validation: Specific errors

#### Test Commands
```lua
-- Test in non-git directory
vim.cmd("cd /tmp")
local claude = require("neotex.ai-claude")
local ok, err = claude.create_worktree_with_claude()
assert(not ok)
assert(err:match("git"))
```

### 11. Performance Tests
Measure impact on startup and runtime.

#### Test Cases
- [ ] Startup time < 10ms additional
- [ ] Lazy loading works correctly
- [ ] Memory usage reasonable
- [ ] No blocking operations
- [ ] Large session files load quickly

#### Test Commands
```bash
# Measure startup
nvim --startuptime startup.log
grep -i claude startup.log

# Profile loading
nvim +'profile start profile.log' +'profile func *' \
     +'lua require("neotex.ai-claude").setup()' \
     +'profile stop' +qa
```

### 12. Migration Verification
Ensure clean break from old architecture.

#### Test Cases
- [ ] Old module paths no longer exist
- [ ] No references to `neotex.core.claude-*`
- [ ] All commands still available
- [ ] Existing sessions still load
- [ ] No compatibility layer remnants

#### Test Commands
```bash
# Check old modules deleted
ls ~/.config/nvim/lua/neotex/core/claude-* 2>/dev/null
# Should return nothing

# Check references updated
grep -r "neotex.core.claude" ~/.config/nvim --include="*.lua"
# Should return nothing

# Verify new paths
grep -r "neotex.ai-claude" ~/.config/nvim --include="*.lua"
# Should show updated references
```

## Real-World Workflow Test

Complete end-to-end workflow test:

1. **Create Worktree Session**
   ```vim
   :ClaudeWorktree
   " Enter: test-feature
   " Select: Feature
   ```

2. **Send Code to Claude**
   ```vim
   " Select some code visually
   V
   :ClaudeSendVisual
   ```

3. **Switch Sessions**
   ```vim
   :ClaudeSessions
   " Select different session
   ```

4. **Resume Previous Work**
   ```vim
   :ClaudeRestoreWorktree
   " Select previous worktree
   ```

5. **Check Health**
   ```vim
   :ClaudeHealth
   " Verify all systems operational
   ```

## Success Criteria

### Critical (Must Pass)
- ✅ No errors on Neovim startup
- ✅ All commands execute without errors
- ✅ Core functions (toggle, sessions, worktrees) work
- ✅ No circular dependencies
- ✅ Configuration loads correctly

### Important (Should Pass)
- ✅ Keybindings work in all modes
- ✅ Telescope pickers function correctly
- ✅ Session persistence works
- ✅ Error messages are helpful
- ✅ Performance impact minimal

### Nice to Have
- ✅ WezTerm integration works
- ✅ Native session compatibility
- ✅ Queue functionality for visual sends
- ✅ All edge cases handled gracefully

## Test Execution Checklist

### Phase 1: Basic Functionality (30 min)
- [ ] Module loading
- [ ] Initialization
- [ ] Health check
- [ ] Basic commands

### Phase 2: Core Features (45 min)
- [ ] Session management
- [ ] Worktree operations
- [ ] Visual selection
- [ ] Keybindings

### Phase 3: Integration (30 min)
- [ ] Telescope pickers
- [ ] Git operations
- [ ] Terminal operations
- [ ] Persistence

### Phase 4: Edge Cases (30 min)
- [ ] Error handling
- [ ] Non-git directories
- [ ] Missing Claude
- [ ] Corrupted files

### Phase 5: Performance (15 min)
- [ ] Startup time
- [ ] Memory usage
- [ ] Responsiveness

### Phase 6: Real Workflow (30 min)
- [ ] Complete workflow test
- [ ] Multiple sessions
- [ ] Context switching
- [ ] Data persistence

## Known Issues / Limitations

Document any issues found during testing:

1. **Issue**: [Description]
   - **Impact**: [Low/Medium/High]
   - **Workaround**: [If any]
   - **Fix**: [Planned resolution]

## Testing Notes

- Test in both git and non-git directories
- Test with and without Claude installed
- Test with empty and populated session directories
- Test in different Neovim configurations (minimal vs full)
- Test with different terminal emulators

## Automation Opportunities

While not implementing formal tests yet, consider future automation:
- Shell script to run all command tests
- Lua script for API testing
- GitHub Actions for CI testing
- Performance benchmarking script

## Sign-off

- [ ] All critical tests passed
- [ ] All important tests passed
- [ ] Performance acceptable
- [ ] No regressions from old module
- [ ] Ready for production use

---

*Last tested: [Date]*
*Tested by: [Name]*
*Neovim version: [Version]*
*Platform: [OS/Architecture]*