# Unified Notification System Refactor

## Executive Summary

This document outlines a comprehensive refactor of the notification system throughout the entire Neovim configuration. The current system suffers from inconsistent patterns, notification spam, and poor user experience across multiple modules. This plan creates a unified notification system that leverages the existing Snacks.nvim infrastructure to provide consistent, user-friendly notifications across all configuration areas.

## Current State Analysis

### Existing Infrastructure
- **Snacks.nvim**: Modern notification system with popup styling (4s timeout, compact style, right-positioned)
- **Global notify level**: Set to `vim.log.levels.INFO`
- **Widespread usage**: 61+ files with 500+ notification calls across entire configuration
- **Inconsistent patterns**: Mix of direct `vim.notify` calls and module-specific wrappers

### Major Notification Sources

1. **Himalaya Email Client**: 200+ calls (highest volume)
2. **Core Utilities**: `/lua/neotex/util/` modules (50+ calls)
3. **AI Integration**: Avante, Claude Code, MCP tools (40+ calls)
4. **Plugin Management**: Bootstrap, lazy loading (30+ calls)
5. **Editor Features**: LSP, formatting, linting (25+ calls)
6. **Text Processing**: VimTeX, language tools (20+ calls)

### Key Problems Identified

1. **Notification Spam**: Bulk operations generate excessive notifications
2. **Inconsistent Log Levels**: Similar operations use different levels across modules
3. **Poor User Experience**: Important notifications lost in debug noise
4. **Fragmented Systems**: Multiple notification approaches across codebase
5. **Missing Context**: Notifications lack actionable information
6. **No Central Control**: Users cannot configure notification behavior globally

## Proposed Unified Architecture

### 1. Core Notification Module
**Location**: `/lua/neotex/util/notifications.lua`

```lua
-- Unified notification system for entire Neovim configuration
local M = {}

-- Global configuration
M.config = {
  enabled = true,
  debug_mode = false,
  rate_limit_ms = 1000,
  batch_delay_ms = 1500,
  max_history = 200,
  
  -- Module-specific settings
  modules = {
    himalaya = { enabled = true, debug_mode = false },
    ai = { enabled = true, debug_mode = false },
    lsp = { enabled = true, debug_mode = false },
    editor = { enabled = true, debug_mode = false },
    startup = { enabled = true, debug_mode = false }
  }
}

-- Notification categories
M.categories = {
  -- Critical notifications (always shown)
  ERROR = { 
    level = vim.log.levels.ERROR, 
    always_show = true,
    examples = { "Connection failed", "Command error", "Plugin failure" }
  },
  
  -- Important warnings (always shown)
  WARNING = { 
    level = vim.log.levels.WARN, 
    always_show = true,
    examples = { "Config deprecated", "Missing dependency", "Large file" }
  },
  
  -- User-initiated actions (always shown unless disabled)
  USER_ACTION = { 
    level = vim.log.levels.INFO, 
    always_show = true,
    examples = { "Email sent", "File saved", "Buffer closed", "Feature toggled" }
  },
  
  -- Status updates (debug mode only)
  STATUS = { 
    level = vim.log.levels.INFO, 
    debug_only = true,
    examples = { "Page loaded", "Cache updated", "Connection established" }
  },
  
  -- Background operations (debug mode only)
  BACKGROUND = { 
    level = vim.log.levels.DEBUG, 
    debug_only = true,
    examples = { "Auto-sync", "Cleanup", "Initialization", "Plugin loading" }
  }
}

-- Core notification function
function M.notify(message, category, context)
  -- Apply filtering, batching, and context enhancement
  -- Delegate to Snacks.nvim for display
end

-- Module-specific notification functions
function M.himalaya(message, category, context)
  context = vim.tbl_extend('force', context or {}, { module = 'himalaya' })
  return M.notify(message, category, context)
end

function M.ai(message, category, context)
  context = vim.tbl_extend('force', context or {}, { module = 'ai' })
  return M.notify(message, category, context)
end

function M.lsp(message, category, context)
  context = vim.tbl_extend('force', context or {}, { module = 'lsp' })
  return M.notify(message, category, context)
end

function M.editor(message, category, context)
  context = vim.tbl_extend('force', context or {}, { module = 'editor' })
  return M.notify(message, category, context)
end

function M.startup(message, category, context)
  context = vim.tbl_extend('force', context or {}, { module = 'startup' })
  return M.notify(message, category, context)
end
```

### 2. Configuration Integration
**Location**: `/lua/neotex/config/notifications.lua`

```lua
-- Global notification configuration
local notifications = require('neotex.util.notifications')

-- User-configurable notification preferences
local config = {
  -- Global settings
  enabled = true,
  debug_mode = false,
  
  -- Module toggles
  modules = {
    himalaya = {
      email_operations = true,     -- Send, delete, move
      background_sync = false,     -- Cache updates, auto-sync
      connection_status = false,   -- IMAP connection messages
      pagination = false           -- Page navigation
    },
    
    ai = {
      model_switching = true,      -- Provider/model changes
      api_errors = true,           -- Connection failures
      processing = false           -- Background AI operations
    },
    
    lsp = {
      diagnostics = true,          -- Error/warning updates
      server_status = false,       -- LSP server connection
      formatting = true,           -- Format operations
      linting = true               -- Lint operations
    },
    
    editor = {
      file_operations = true,      -- Save, open, close
      feature_toggles = true,      -- Setting changes
      buffer_management = true,    -- Buffer operations
      performance = false          -- Optimization reports
    },
    
    startup = {
      plugin_loading = false,      -- Plugin initialization
      config_errors = true,        -- Configuration issues
      performance = false          -- Startup timing
    }
  },
  
  -- Advanced settings
  batching = {
    enabled = true,
    delay_ms = 1500,
    max_batch_size = 10
  },
  
  rate_limiting = {
    enabled = true,
    cooldown_ms = 1000,
    max_per_minute = 20
  },
  
  history = {
    enabled = true,
    max_entries = 200,
    persist = false
  }
}

-- Apply configuration
notifications.setup(config)

return config
```

### 3. Smart Filtering and Batching

```lua
-- Intelligent notification processing
function M.should_show_notification(category, message, context)
  local module = context.module or 'general'
  local module_config = M.config.modules[module]
  
  -- Always show critical notifications
  if category.always_show and category ~= M.categories.USER_ACTION then
    return true
  end
  
  -- Check module-specific settings
  if module_config and not module_config.enabled then
    return false
  end
  
  -- Debug mode shows everything for enabled modules
  if M.config.debug_mode or (module_config and module_config.debug_mode) then
    return true
  end
  
  -- Apply category filtering
  if category.debug_only then
    return false
  end
  
  -- Check rate limiting
  if M.is_rate_limited(message, context) then
    return false
  end
  
  return true
end

-- Batch similar notifications
function M.batch_notifications(notifications)
  -- Group by module and category
  -- Create summary notifications
  -- Apply intelligent merging
end
```

## Implementation Plan

### Phase 1: Core Infrastructure (Week 1)

#### 1.1 Create Unified Notification Module
**File**: `/lua/neotex/util/notifications.lua`

- Implement core notification system
- Create category-based filtering
- Add module-specific functions
- Integrate with Snacks.nvim backend

#### 1.2 Global Configuration
**File**: `/lua/neotex/config/notifications.lua`

- Define user-configurable preferences
- Create module-specific settings
- Implement configuration validation
- Add setup function integration

#### 1.3 Update Utility Documentation
**File**: `/lua/neotex/util/README.md`

- Add notifications module documentation
- Update available commands list
- Add usage examples
- Document configuration options

### Phase 2: High-Impact Module Migration (Week 2)

#### 2.1 Himalaya Email Client
**Files**: All files in `/lua/neotex/plugins/tools/himalaya/`

```lua
-- Before:
vim.notify('Email sent successfully', vim.log.levels.INFO)
vim.notify('Cached 200 emails for gmail/INBOX', vim.log.levels.INFO)

-- After:
local notify = require('neotex.util.notifications')
notify.himalaya('Email sent successfully', notify.categories.USER_ACTION, {
  email_id = email_id,
  recipient = recipient
})
notify.himalaya('Cached emails', notify.categories.BACKGROUND, {
  count = count,
  folder = folder
})
```

#### 2.2 Core Utilities
**Files**: `/lua/neotex/util/misc.lua`, `/lua/neotex/util/diagnostics.lua`, etc.

```lua
-- Before:
vim.notify('Trailing whitespace removed from ' .. lines_modified .. ' lines', vim.log.levels.INFO)

-- After:
local notify = require('neotex.util.notifications')
notify.editor('Trailing whitespace removed', notify.categories.USER_ACTION, {
  lines_modified = lines_modified,
  file = vim.fn.expand('%:t')
})
```

#### 2.3 Bootstrap and Plugin Management
**Files**: `/lua/neotex/bootstrap.lua`, plugin configs

```lua
-- Before:
vim.notify('Loading configuration...', vim.log.levels.INFO)

-- After:
local notify = require('neotex.util.notifications')
notify.startup('Configuration loaded', notify.categories.BACKGROUND, {
  startup_time = startup_time,
  plugin_count = plugin_count
})
```

### Phase 3: Remaining Modules (Week 3)

#### 3.1 AI Integration
**Files**: `/lua/neotex/plugins/ai/`, MCP tools

```lua
-- Before:
vim.notify('Model switched to: ' .. model, vim.log.levels.INFO)

-- After:
local notify = require('neotex.util.notifications')
notify.ai('Model switched', notify.categories.USER_ACTION, {
  model = model,
  provider = provider
})
```

#### 3.2 LSP and Development Tools
**Files**: Linting, formatting, LSP configs

```lua
-- Before:
vim.notify('Linting enabled for ' .. filetype, vim.log.levels.INFO)

-- After:
local notify = require('neotex.util.notifications')
notify.lsp('Linting enabled', notify.categories.USER_ACTION, {
  filetype = filetype,
  linter = linter_name
})
```

#### 3.3 Text Processing and Language Tools
**Files**: VimTeX, language-specific tools

```lua
-- Before:
vim.notify('VimTeX compilation completed', vim.log.levels.INFO)

-- After:
local notify = require('neotex.util.notifications')
notify.editor('Document compiled', notify.categories.USER_ACTION, {
  compiler = 'vimtex',
  output = output_file
})
```

### Phase 4: Advanced Features and Commands (Week 4)

#### 4.1 User Commands
**File**: `/lua/neotex/util/notifications.lua`

```lua
-- Notification management commands
vim.api.nvim_create_user_command('Notifications', function(opts)
  local notifications = require('neotex.util.notifications')
  
  if opts.args == 'history' then
    notifications.show_history()
  elseif opts.args == 'debug' then
    notifications.toggle_debug_mode()
  elseif opts.args == 'config' then
    notifications.show_config()
  elseif opts.args == 'clear' then
    notifications.clear_history()
  elseif opts.args == 'stats' then
    notifications.show_stats()
  else
    notifications.show_help()
  end
end, {
  nargs = '?',
  complete = function()
    return { 'history', 'debug', 'config', 'clear', 'stats', 'help' }
  end,
  desc = 'Manage global notification system'
})

-- Module-specific debug toggles
vim.api.nvim_create_user_command('NotifyDebug', function(opts)
  local notifications = require('neotex.util.notifications')
  local module = opts.args
  
  if module == '' then
    notifications.toggle_global_debug()
  else
    notifications.toggle_module_debug(module)
  end
end, {
  nargs = '?',
  complete = function()
    return { 'himalaya', 'ai', 'lsp', 'editor', 'startup' }
  end,
  desc = 'Toggle debug mode for notification modules'
})
```

#### 4.2 Which-key Integration
**File**: Plugin which-key configuration

```lua
-- Add notification management to which-key
wk.register({
  ["<leader>n"] = {
    name = "Notifications",
    h = { "<cmd>Notifications history<cr>", "Show history" },
    c = { "<cmd>Notifications config<cr>", "Show config" },
    d = { "<cmd>NotifyDebug<cr>", "Toggle debug" },
    s = { "<cmd>Notifications stats<cr>", "Show stats" },
    x = { "<cmd>Notifications clear<cr>", "Clear history" },
  }
})
```

#### 4.3 Performance Monitoring
**File**: `/lua/neotex/util/notifications.lua`

```lua
-- Track notification performance
M.stats = {
  total_notifications = 0,
  filtered_notifications = 0,
  batched_notifications = 0,
  by_module = {},
  by_category = {},
  performance = {
    avg_processing_time = 0,
    max_processing_time = 0
  }
}

function M.show_stats()
  -- Display comprehensive notification statistics
  -- Show filtering effectiveness
  -- Display performance metrics
end
```

## Migration Strategy

### Automated Migration Tools

#### 1. Pattern Detection Script
**File**: `/lua/neotex/util/migrate_notifications.lua`

```lua
-- Automated notification migration utility
local M = {}

function M.analyze_file(filepath)
  -- Detect notification patterns
  -- Suggest appropriate categories
  -- Generate migration diff
end

function M.migrate_file(filepath, dry_run)
  -- Apply notification system updates
  -- Add module imports
  -- Replace vim.notify calls
end

function M.migrate_all(dry_run)
  -- Process entire configuration
  -- Generate migration report
  -- Apply changes if not dry run
end
```

#### 2. Configuration Validator
**File**: `/lua/neotex/util/validate_notifications.lua`

```lua
-- Validate notification system configuration
local M = {}

function M.validate_config()
  -- Check configuration consistency
  -- Validate module settings
  -- Report configuration issues
end

function M.lint_notifications()
  -- Check for notification anti-patterns
  -- Suggest optimizations
  -- Report potential spam sources
end
```

### Migration Workflow

1. **Analysis Phase**: Run detection script to identify all notification usage
2. **Planning Phase**: Review suggested migrations and categories
3. **Module-by-Module**: Migrate one module at a time with testing
4. **Validation Phase**: Run linting and validation tools
5. **Performance Testing**: Monitor notification performance and user experience

## Documentation Strategy

### Primary Documentation
**File**: `/docs/NOTIFICATIONS.md`

- Comprehensive user guide
- Configuration examples
- Troubleshooting guide
- Best practices

### Module Documentation Updates

#### Utility README
**File**: `/lua/neotex/util/README.md`

```markdown
## Notification System

The unified notification system provides consistent notification management across all modules.

### Usage

```lua
local notify = require('neotex.util.notifications')

-- User actions (always shown)
notify.editor('File saved', notify.categories.USER_ACTION)

-- Background operations (debug mode only)
notify.editor('Cache updated', notify.categories.BACKGROUND)
```

### Commands

| Command | Description |
|---------|-------------|
| `:Notifications history` | Show notification history |
| `:Notifications config` | Show current configuration |
| `:NotifyDebug [module]` | Toggle debug mode |
```

#### Plugin-Specific Documentation
Update README files in:
- `/lua/neotex/plugins/tools/himalaya/README.md`
- `/lua/neotex/plugins/ai/README.md`
- `/lua/neotex/plugins/lsp/README.md`

Each should reference the unified notification system and link to main documentation.

## Success Metrics

### Quantitative Goals
- **Reduce notification volume by 70%** in normal mode across all modules
- **Maintain 100% visibility** for user-initiated actions and errors
- **Zero notification spam** during bulk operations
- **Sub-50ms notification processing** time
- **90%+ user satisfaction** with notification relevance

### Qualitative Goals
- **Consistent experience** across all configuration areas
- **Clear user feedback** for all important operations
- **Easy troubleshooting** via debug modes and history
- **Configurable experience** matching user preferences
- **Maintainable codebase** with unified notification patterns

## Benefits of Unified Approach

### 1. **User Experience**
- Consistent notification behavior across all features
- Configurable verbosity levels
- Reduced notification fatigue
- Clear, contextual information

### 2. **Developer Experience**
- Single API for all notification needs
- Consistent patterns across codebase
- Easy debugging and testing
- Centralized configuration management

### 3. **Maintainability**
- Single source of truth for notification logic
- Easy to modify behavior globally
- Clear separation of concerns
- Automated migration and validation tools

### 4. **Performance**
- Intelligent batching reduces notification overhead
- Rate limiting prevents spam
- Efficient filtering reduces processing
- Performance monitoring and optimization

## Risk Mitigation

### Potential Issues
1. **Breaking existing workflows**: Some users may rely on current notification patterns
2. **Performance impact**: Additional processing overhead
3. **Configuration complexity**: Too many options may confuse users
4. **Migration errors**: Automated migration may introduce bugs

### Mitigation Strategies
1. **Gradual rollout**: Migrate modules progressively with opt-in beta testing
2. **Performance monitoring**: Track notification system performance metrics
3. **Sensible defaults**: Provide good defaults with optional advanced configuration
4. **Comprehensive testing**: Validate all migrations with automated tests
5. **Fallback mechanism**: Maintain backward compatibility during transition

## Timeline

- **Week 1**: Core infrastructure and configuration system
- **Week 2**: Migrate high-impact modules (Himalaya, core utilities)
- **Week 3**: Migrate remaining modules (AI, LSP, text processing)
- **Week 4**: Advanced features, documentation, and testing

## Conclusion

This unified notification system refactor will transform the user experience across the entire Neovim configuration by providing consistent, relevant, and configurable notifications. By leveraging the existing Snacks.nvim infrastructure and implementing intelligent filtering and batching, users will receive the information they need without notification fatigue.

The comprehensive migration strategy ensures minimal disruption while delivering immediate benefits. The system's extensibility and configuration options provide a foundation for continued improvement and customization based on user needs.