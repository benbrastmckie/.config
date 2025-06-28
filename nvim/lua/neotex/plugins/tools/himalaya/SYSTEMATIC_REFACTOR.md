# Himalaya Email Plugin - Systematic Refactor Plan

## Executive Summary

This revision plan addresses the need for a systematic, maintainable approach to the Himalaya email plugin based on recent discoveries about mbsync/maildir integration issues and the current state of the codebase.

## Current State Analysis

### What's Working Well
1. **Core Email Operations**: Reading, composing, sending emails via Himalaya CLI
2. **UI/UX**: Clean sidebar interface with Neo-tree style navigation
3. **State Management**: Session persistence and restoration
4. **Trash System**: Complete local trash implementation
5. **OAuth Auto-refresh**: Automatic token refresh on authentication failures
6. **Single Sync Enforcement**: Prevents multiple concurrent syncs

### Critical Issues Discovered
1. **UIDVALIDITY Format**: mbsync requires empty files or specific format, not timestamps
2. **Maildir Path Configuration**: Trailing slash required for Maildir++ format
3. **Folder Name Mapping**: Local maildir names differ from IMAP names
4. **Complex Sync System**: 1800+ lines of sync code that's overly complex
5. **Documentation Scatter**: Multiple fix files without central documentation

## Proposed Architecture

### Core Principles
1. **Separation of Concerns**: Clear boundaries between sync, UI, and email operations
2. **Fail-Safe Design**: Graceful degradation when sync issues occur
3. **User Transparency**: Clear feedback about what's happening
4. **Minimal Configuration**: Smart defaults with override options

### Module Structure
```
himalaya/
├── core/
│   ├── config.lua        # Centralized configuration
│   ├── state.lua         # State management
│   └── utils.lua         # Shared utilities
├── sync/
│   ├── mbsync.lua        # mbsync integration (simplified)
│   ├── oauth.lua         # OAuth handling
│   └── diagnostics.lua   # Sync health checks
├── email/
│   ├── operations.lua    # Read, compose, send, move
│   ├── folders.lua       # Folder management
│   └── trash.lua         # Trash system
├── ui/
│   ├── sidebar.lua       # Email list sidebar
│   ├── windows.lua       # Window management
│   └── keymaps.lua       # Centralized keybindings
├── setup/
│   ├── maildir.lua       # Maildir structure management
│   ├── wizard.lua        # First-time setup wizard
│   └── health.lua        # Health checks
├── commands.lua          # User commands
├── init.lua             # Plugin entry point
└── README.md            # Comprehensive documentation
```

## Implementation Phases

### Phase 1: Core Refactoring (1-2 weeks)

#### 1.1 Consolidate Configuration
- Merge scattered config into single `core/config.lua`
- Add config validation with helpful error messages
- Include all discovered requirements (trailing slash, UIDVALIDITY format)

#### 1.2 Simplify Sync System
```lua
-- sync/mbsync.lua - Maximum 200 lines
local M = {}

function M.sync_inbox(callback)
  -- Use flock for process safety
  local cmd = {'flock', '-n', '/tmp/mbsync-gmail.lock', 'mbsync', 'gmail-inbox'}
  
  vim.fn.jobstart(cmd, {
    stdout_buffered = false,
    on_stdout = function(_, data)
      -- Simple progress parsing
      M.parse_progress(data)
    end,
    on_exit = function(_, code)
      if code == 0 then
        callback(true)
      else
        M.handle_error(code, callback)
      end
    end
  })
end

function M.parse_progress(data)
  -- Extract only essential progress info
  -- Skip complex parsing - just show "Syncing..." or "X/Y messages"
end

return M
```

#### 1.3 Extract Email Operations
- Move all email operations to `email/operations.lua`
- Separate folder management into `email/folders.lua`
- Keep trash system but move to `email/trash.lua`

### Phase 2: Setup & Diagnostics (1 week)

#### 2.1 First-Time Setup Wizard
```lua
-- setup/wizard.lua
local M = {}

function M.run()
  -- Step 1: Check dependencies (mbsync, himalaya)
  -- Step 2: Verify OAuth setup
  -- Step 3: Create maildir structure
  -- Step 4: Test sync
  -- Step 5: Show success/next steps
end

return M
```

#### 2.2 Health Check System
```lua
-- setup/health.lua
local M = {}

function M.check()
  local issues = {}
  
  -- Check mbsync installation
  -- Check maildir structure
  -- Check UIDVALIDITY files
  -- Check OAuth tokens
  -- Check folder mappings
  
  return {
    ok = #issues == 0,
    issues = issues,
    fixes = M.suggest_fixes(issues)
  }
end

return M
```

#### 2.3 Automatic Diagnostics
- Run health check on startup
- Show non-intrusive warning if issues found
- Provide `:HimalayaHealth` command for details

### Phase 3: UI Modernization (1 week)

#### 3.1 Simplify UI Components
- Reduce ui.lua from 1800+ lines to ~500
- Extract window management to separate module
- Use Neovim's native UI components where possible

#### 3.2 Better Error Handling
```lua
-- ui/notifications.lua
local M = {}

function M.show_sync_error(error)
  -- Smart error messages based on common issues
  if error:match("UIDVALIDITY") then
    vim.notify("Maildir structure issue detected. Run :HimalayaHealth for details", vim.log.levels.WARN)
  elseif error:match("Authentication failed") then
    vim.notify("OAuth token expired. Refreshing...", vim.log.levels.INFO)
    -- Trigger auto-refresh
  else
    vim.notify("Sync failed: " .. error, vim.log.levels.ERROR)
  end
end

return M
```

#### 3.3 Progressive Enhancement
- Basic email list always works (even without sync)
- Sync status shown unobtrusively
- Graceful degradation when sync unavailable

### Phase 4: Documentation & Testing (1 week)

#### 4.1 Comprehensive Documentation
```markdown
# himalaya/README.md

## Quick Start
1. Install prerequisites: `brew install isync himalaya`
2. Run setup: `:HimalayaSetup`
3. Start using: `<leader>ml` to open email

## Architecture
[Clear explanation of how components work together]

## Troubleshooting
### Common Issues
1. **UIDVALIDITY Errors**
   - Cause: Invalid file format
   - Fix: Run `:HimalayaFixMaildir`

2. **OAuth Authentication Failed**
   - Cause: Expired token
   - Fix: Automatic (wait for refresh) or `:HimalayaReauth`

[Complete troubleshooting guide]
```

#### 4.2 Integration Tests
```lua
-- tests/integration_spec.lua
describe("himalaya setup", function()
  it("creates correct maildir structure", function()
    -- Test UIDVALIDITY files are empty
    -- Test folder names are correct
    -- Test permissions are set
  end)
  
  it("handles OAuth refresh correctly", function()
    -- Test auto-refresh triggers
    -- Test manual refresh works
    -- Test error handling
  end)
end)
```

### Phase 5: Migration & Cleanup (3 days)

#### 5.1 Migration Script
```lua
-- setup/migrate.lua
local M = {}

function M.from_old_version()
  -- Backup old configuration
  -- Fix UIDVALIDITY files
  -- Update folder mappings
  -- Clear old state
  -- Show migration summary
end

return M
```

#### 5.2 Remove Legacy Code
- Delete all experimental/unused modules
- Remove complex sync monitoring
- Clean up dead code paths

#### 5.3 Deprecation Notices
- Add warnings for removed features
- Provide migration guides
- Update which-key descriptions

## Key Improvements

### 1. Simplified Sync
- From 1800+ lines to ~200 lines
- Clear error handling
- No fake progress indicators

### 2. Better User Experience
- Automatic setup wizard
- Smart error messages
- Health check system

### 3. Maintainable Codebase
- Clear module boundaries
- Comprehensive tests
- Single source of truth for docs

### 4. Robust Operation
- Handles all discovered edge cases
- Graceful degradation
- Clear recovery paths

## Success Metrics

1. **Setup Success Rate**: 95%+ users complete setup without manual intervention
2. **Sync Reliability**: No duplicate processes, clear error messages
3. **Code Simplicity**: 50% reduction in total lines of code
4. **Documentation**: Single README answers 90% of questions

## Timeline

- **Week 1-2**: Core refactoring (Phase 1)
- **Week 3**: Setup & diagnostics (Phase 2)
- **Week 4**: UI modernization (Phase 3)
- **Week 5**: Documentation & testing (Phase 4)
- **Week 6**: Migration & cleanup (Phase 5)

## Backward Compatibility

### Breaking Changes
1. Configuration structure changes
2. Some commands renamed for clarity
3. Complex sync options removed

### Migration Path
1. Automatic migration on first run
2. Clear warnings for breaking changes
3. Fallback options for critical features

## Conclusion

This systematic refactor will transform the Himalaya plugin from a complex, partially-broken system into a robust, maintainable email client. By focusing on simplicity, reliability, and user experience, we can create a plugin that "just works" while being easy to understand and extend.