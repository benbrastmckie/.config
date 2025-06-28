# Himalaya Email Plugin - Comprehensive Revision Plan

## Executive Summary

This document combines the systematic refactor plan with unfinished phases from the original REFACTOR.md, incorporating all recent discoveries about mbsync/maildir integration issues.

## Current State & Discoveries

### Recent Critical Discoveries
1. **UIDVALIDITY Format**: mbsync requires empty files, not timestamps
2. **Maildir Path**: Trailing slash critical for Maildir++ format (initially correct)
3. **Folder Mapping**: Local names (All_Mail) differ from IMAP names ([Gmail]/All Mail)
4. **OAuth Environment**: Must load from systemd for NixOS users

### Completed Phases (from REFACTOR.md)
- Phase 1-10: Core sync, UI, process management, OAuth refresh
- External sync detection and simplified status display
- Automatic OAuth token refresh on authentication failures
- Single sync enforcement with flock

### Remaining Unfinished Work

#### Phase 11: OAuth2 & Maildir Issues (Partially Complete)
**Status**: OAuth auto-refresh ✅, Maildir fixes ✅, Documentation ⏳
- Need comprehensive OAuth setup documentation
- Need automated OAuth health checks
- Need better first-time setup experience

#### Phase 12: Progress Display Fix
**Status**: Not started
**Issue**: Progress shows "0/1894" and never increments
**Plan**: Simplify to basic "Syncing..." indicator

#### Phase 13: Configuration Validation
**Status**: Partially complete
**Need**: Comprehensive config validation and health checks

## Systematic Refactor Plan

### Architecture Goals
1. **Modular Design**: Clear separation of concerns
2. **Fail-Safe Operations**: Graceful degradation
3. **User Transparency**: Clear, actionable feedback
4. **Minimal Configuration**: Smart defaults

### Proposed Module Structure
```
himalaya/
|-- core/
|   |-- config.lua        # Unified configuration
|   |-- state.lua         # State management
|   `-- logger.lua        # Structured logging
|-- sync/
|   |-- mbsync.lua        # Simplified mbsync wrapper (~200 lines)
|   |-- oauth.lua         # OAuth management
|   `-- lock.lua          # Process locking with flock
|-- email/
|   |-- client.lua        # Himalaya CLI wrapper
|   |-- folders.lua       # Folder name mapping
|   `-- cache.lua         # Email cache management
|-- ui/
|   |-- sidebar.lua       # Email list view
|   |-- reader.lua        # Email reading view
|   |-- composer.lua      # Email composition
|   `-- notifications.lua # Smart error messages
|-- setup/
|   |-- wizard.lua        # First-time setup
|   |-- health.lua        # Health checks
|   `-- migration.lua     # Version migration
`-- docs/
    |-- README.md         # User documentation
    |-- TROUBLESHOOTING.md # Common issues
    `-- DEVELOPMENT.md    # Developer guide
```

## Implementation Phases

### Phase 1: Core Simplification (1 week)

#### 1.1 Sync System Overhaul
Replace 1800+ lines in streamlined_sync.lua with:
```lua
-- sync/mbsync.lua
local M = {}
local lock = require('himalaya.sync.lock')
local oauth = require('himalaya.sync.oauth')

function M.sync(channel, opts)
  opts = opts or {}
  
  -- Check OAuth first
  if not oauth.is_valid() then
    if opts.auto_refresh then
      return oauth.refresh_and_retry(function()
        return M.sync(channel, opts)
      end)
    else
      return false, "OAuth token invalid"
    end
  end
  
  -- Use flock for safety
  local cmd = lock.wrap_command({'mbsync', channel})
  
  local job_id = vim.fn.jobstart(cmd, {
    on_stdout = opts.on_progress,
    on_exit = function(_, code)
      if opts.callback then
        opts.callback(code == 0, code)
      end
    end
  })
  
  return job_id
end

return M
```

#### 1.2 Configuration Consolidation
```lua
-- core/config.lua
local M = {}

M.defaults = {
  accounts = {
    gmail = {
      -- Discovered requirements
      maildir_path = "~/Mail/Gmail/", -- Trailing slash required!
      folder_map = {
        -- IMAP -> Local mapping
        ["[Gmail]/All Mail"] = "All_Mail",
        ["[Gmail]/Sent Mail"] = "Sent",
        ["[Gmail]/Spam"] = "Spam",
      },
      -- OAuth settings
      oauth = {
        client_id_env = "GMAIL_CLIENT_ID",
        token_command = "himalaya account configure gmail",
      }
    }
  },
  sync = {
    lock_timeout = 300, -- 5 minutes
    auto_refresh_oauth = true,
  },
  ui = {
    auto_sync_on_open = false, -- Prevent race conditions
    show_simple_progress = true, -- Just "Syncing..."
  }
}

function M.validate()
  local issues = {}
  
  -- Check maildir paths have trailing slash
  -- Verify OAuth environment variables
  -- Validate folder mappings
  
  return issues
end

return M
```

### Phase 2: Smart Setup & Diagnostics (1 week)

#### 2.1 Setup Wizard
```lua
-- setup/wizard.lua
local M = {}

function M.run()
  local steps = {
    M.check_dependencies,
    M.setup_oauth,
    M.create_maildir,
    M.verify_sync,
    M.configure_keymaps
  }
  
  for i, step in ipairs(steps) do
    local ok, err = step()
    if not ok then
      vim.notify(string.format("Setup failed at step %d: %s", i, err), vim.log.levels.ERROR)
      M.offer_fixes(err)
      return false
    end
  end
  
  vim.notify("Himalaya setup complete! Press <leader>ml to open email.", vim.log.levels.INFO)
  return true
end

function M.check_dependencies()
  -- Check for mbsync, himalaya, flock
  -- Verify versions
  -- Check NixOS-specific requirements
end

function M.setup_oauth()
  -- Check existing OAuth
  -- Guide through himalaya account configure
  -- Verify token validity
  -- Set up auto-refresh
end

function M.create_maildir()
  -- Create structure with correct permissions
  -- CRITICAL: Create empty UIDVALIDITY files
  -- Set up folder mappings
end

return M
```

#### 2.2 Health Check System
```lua
-- setup/health.lua
local M = {}

function M.check()
  local checks = {
    {
      name = "UIDVALIDITY files",
      test = M.check_uidvalidity,
      fix = "Run :HimalayaFixMaildir"
    },
    {
      name = "OAuth tokens",
      test = M.check_oauth,
      fix = "Run :HimalayaSetupOAuth"
    },
    {
      name = "Maildir structure",
      test = M.check_maildir,
      fix = "Check trailing slash in config"
    },
    {
      name = "Sync processes",
      test = M.check_no_stuck_syncs,
      fix = "Run :HimalayaCleanup"
    }
  }
  
  local report = {}
  for _, check in ipairs(checks) do
    local ok, details = check.test()
    table.insert(report, {
      name = check.name,
      ok = ok,
      details = details,
      fix = not ok and check.fix or nil
    })
  end
  
  return report
end

function M.check_uidvalidity()
  -- Find all .uidvalidity files
  -- Verify they're empty or valid mbsync format
  -- Return specific issues found
end

return M
```

### Phase 3: UI Improvements (1 week)

#### 3.1 Smart Notifications
```lua
-- ui/notifications.lua
local M = {}

M.error_map = {
  ["UIDVALIDITY"] = {
    message = "Maildir structure issue detected",
    action = "Run :HimalayaHealth for details",
    level = vim.log.levels.WARN
  },
  ["Authentication failed"] = {
    message = "OAuth token expired",
    action = "Refreshing automatically...",
    level = vim.log.levels.INFO,
    auto_action = function()
      require('himalaya.sync.oauth').refresh()
    end
  },
  ["Socket timeout"] = {
    message = "Connection timeout",
    action = "Check network or try again",
    level = vim.log.levels.WARN
  }
}

function M.handle_sync_error(error_text)
  for pattern, handler in pairs(M.error_map) do
    if error_text:match(pattern) then
      vim.notify(handler.message .. ". " .. handler.action, handler.level)
      if handler.auto_action then
        vim.defer_fn(handler.auto_action, 100)
      end
      return
    end
  end
  
  -- Generic error
  vim.notify("Sync error: " .. error_text, vim.log.levels.ERROR)
end

return M
```

#### 3.2 Simplified Progress
```lua
-- ui/sidebar.lua updates
function M.show_sync_status()
  local sync = require('himalaya.sync.mbsync')
  local status = sync.get_status()
  
  if status.running then
    -- Simple, honest progress
    return "🔄 Syncing email..."
  elseif status.last_error then
    return "⚠️  Sync failed (see :messages)"
  else
    return "✓ Synced " .. M.format_time_ago(status.last_sync)
  end
end
```

### Phase 4: Documentation & Migration (3 days)

#### 4.1 Comprehensive User Guide
```markdown
# himalaya/docs/README.md

## Installation

### Prerequisites
- Neovim 0.8+
- mbsync (isync) 1.4+
- himalaya 0.9+
- flock (usually pre-installed)

### Quick Start
```lua
-- In your Neovim config
{
  'neotex/himalaya.nvim',
  config = function()
    require('himalaya').setup({
      -- Minimal config needed!
    })
  end
}
```

### First Run
1. Open Neovim
2. Run `:HimalayaSetup`
3. Follow the interactive setup
4. Start using with `<leader>ml`

## Troubleshooting

### UIDVALIDITY Errors
**Symptom**: `Maildir error: cannot read UIDVALIDITY`

**Cause**: Invalid UIDVALIDITY file format

**Fix**:
```bash
find ~/Mail -name ".uidvalidity" -exec sh -c 'echo -n > "{}"' \;
```

### OAuth Issues
**Symptom**: Sync hangs at authentication

**Fix**:
1. Check token: `:HimalayaOAuthStatus`
2. Refresh: `:HimalayaOAuthRefresh`
3. Reconfigure: Run `himalaya account configure` in terminal

### Folder Mapping Issues
**Symptom**: Can't find Archive/Spam folders

**Cause**: IMAP names vs local names mismatch

**Fix**: Names are automatically mapped:
- `[Gmail]/All Mail` -> `All_Mail`
- `[Gmail]/Spam` -> `Spam`
```

#### 4.2 Migration Script
```lua
-- setup/migration.lua
local M = {}

function M.migrate_from_old()
  local changes = {}
  
  -- Fix UIDVALIDITY files
  local fixed = M.fix_uidvalidity_files()
  if fixed > 0 then
    table.insert(changes, string.format("Fixed %d UIDVALIDITY files", fixed))
  end
  
  -- Update config structure
  if M.migrate_config() then
    table.insert(changes, "Updated configuration format")
  end
  
  -- Clear old state
  if M.clear_old_state() then
    table.insert(changes, "Cleared obsolete state files")
  end
  
  if #changes > 0 then
    vim.notify("Migration complete:\n" .. table.concat(changes, "\n"), vim.log.levels.INFO)
  end
end

return M
```

## Success Metrics

1. **Setup Success**: 95%+ complete without manual intervention
2. **Sync Reliability**: Zero duplicate processes, clear errors
3. **Code Reduction**: From ~5000 to ~2000 lines
4. **User Satisfaction**: Reduced support requests by 80%

## Timeline

- **Week 1**: Core simplification (Phase 1)
- **Week 2**: Setup & diagnostics (Phase 2)  
- **Week 3**: UI improvements (Phase 3)
- **Week 4**: Documentation & migration (Phase 4)

## Key Discoveries Integration

### UIDVALIDITY Fix
- All maildir setup functions create empty files
- Health check detects invalid formats
- Migration script fixes existing installations

### Folder Mapping
- Built-in mapping table for Gmail folders
- Automatic detection of local folder names
- Clear documentation of naming conventions

### OAuth Improvements
- Environment variable loading from systemd
- Automatic token refresh on failure
- Clear setup wizard for first-time users

## Conclusion

This systematic refactor addresses all discovered issues while maintaining the plugin's excellent UI/UX. By focusing on simplicity, reliability, and clear communication, we create a maintainable email client that "just works."
