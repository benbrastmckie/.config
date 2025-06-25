# Unified Notification System

The Neovim configuration features a comprehensive notification system that provides consistent, relevant feedback across all modules while minimizing notification fatigue.

## Overview

The unified notification system centralizes all notifications through a single interface, providing intelligent filtering, batching, and categorization. This ensures users receive important information without being overwhelmed by debug messages and background operations.

### Key Features

- **Intelligent Filtering**: Shows only relevant notifications based on context and user preferences
- **Category-based Organization**: Five distinct notification categories with different visibility rules
- **Module-specific Control**: Per-module configuration for fine-grained control
- **Batching & Rate Limiting**: Prevents notification spam during bulk operations
- **Debug Mode**: Toggle detailed notifications for troubleshooting
- **Notification History**: Access to recent notifications and statistics

## Notification Categories

### 1. ERROR (Always Shown)
Critical failures that require immediate attention.

**Examples:**
- Connection failures (Himalaya IMAP, AI providers)
- Command execution errors
- Plugin loading failures
- Configuration validation errors

**Log Level:** `vim.log.levels.ERROR`

### 2. WARNING (Always Shown)
Important issues that need user awareness but don't prevent operation.

**Examples:**
- Deprecated configuration options
- Missing dependencies
- Large file warnings
- Version compatibility issues

**Log Level:** `vim.log.levels.WARN`

### 3. USER_ACTION (Always Shown)
Feedback for user-initiated operations that modify state.

**Examples:**
- Email sent/deleted/moved (Himalaya)
- File saved/opened/closed
- Features enabled/disabled
- Buffer operations completed

**Log Level:** `vim.log.levels.INFO`

### 4. STATUS (Debug Mode Only)
Status updates for ongoing operations.

**Examples:**
- Page navigation (Himalaya)
- Cache updates
- Connection status
- Operation progress

**Log Level:** `vim.log.levels.INFO`

### 5. BACKGROUND (Debug Mode Only)
Background operations and system events.

**Examples:**
- Auto-sync operations
- Cleanup tasks
- Plugin initialization
- Performance optimizations

**Log Level:** `vim.log.levels.DEBUG`

## Module Organization

The notification system is organized by functional modules:

### Himalaya Email Client
- **Email Operations**: Send, delete, move notifications
- **Background Sync**: Cache updates and auto-synchronization
- **Connection Status**: IMAP connection and authentication
- **Navigation**: Page navigation and folder switching

### AI Integration
- **Model Switching**: Provider and model changes
- **API Operations**: Connection status and errors
- **Processing**: Background AI operations

### LSP & Development
- **Diagnostics**: Error and warning updates
- **Server Status**: LSP server connections
- **Formatting**: Code formatting operations
- **Linting**: Code linting operations

### Editor Features
- **File Operations**: File system interactions
- **Feature Toggles**: Configuration changes
- **Buffer Management**: Buffer lifecycle operations
- **Performance**: Optimization reports

### Startup & Configuration
- **Plugin Loading**: Plugin initialization status
- **Configuration**: Config validation and errors
- **Performance**: Startup timing and analysis

## Configuration

### Global Settings

The notification system can be configured in `/lua/neotex/config/notifications.lua`:

```lua
local config = {
  -- Global toggles
  enabled = true,
  debug_mode = false,
  
  -- Module-specific settings
  modules = {
    himalaya = {
      email_operations = true,     -- Show send/delete/move
      background_sync = false,     -- Hide cache updates
      connection_status = false,   -- Hide IMAP status
      pagination = false           -- Hide page navigation
    },
    
    ai = {
      model_switching = true,      -- Show model changes
      api_errors = true,           -- Show API failures
      processing = false           -- Hide background processing
    },
    
    lsp = {
      diagnostics = true,          -- Show error/warning updates
      server_status = false,       -- Hide LSP server status
      formatting = true,           -- Show format operations
      linting = true               -- Show lint operations
    }
  },
  
  -- Performance settings
  batching = {
    enabled = true,
    delay_ms = 1500,
    max_batch_size = 10
  },
  
  rate_limiting = {
    enabled = true,
    cooldown_ms = 1000,
    max_per_minute = 20
  }
}
```

### Quick Configuration

For common use cases, you can quickly adjust notification behavior:

```lua
-- Minimal notifications (errors and user actions only)
local notify = require('neotex.util.notifications')
notify.set_profile('minimal')

-- Verbose notifications (show status updates)
notify.set_profile('verbose')

-- Debug mode (show everything)
notify.set_profile('debug')
```

## Commands

### Global Notification Commands

| Command | Description |
|---------|-------------|
| `:Notifications` | Show notification management menu |
| `:Notifications history` | Display recent notification history |
| `:Notifications config` | Show current configuration |
| `:Notifications stats` | Display notification statistics |
| `:Notifications clear` | Clear notification history |
| `:NotifyDebug [module]` | Toggle debug mode globally or for specific module |

### Module-Specific Commands

Some modules provide their own notification toggles:

| Command | Description |
|---------|-------------|
| `:HimalayaDebug` | Toggle Himalaya notification debug mode |
| `:NotifyDebug himalaya` | Same as above |
| `:NotifyDebug ai` | Toggle AI module debug notifications |
| `:NotifyDebug lsp` | Toggle LSP module debug notifications |

## Keybindings

The following keybindings are available for notification management:

| Key | Description |
|-----|-------------|
| `<leader>nh` | Show notification history |
| `<leader>nc` | Show notification configuration |
| `<leader>nd` | Toggle global debug mode |
| `<leader>ns` | Show notification statistics |
| `<leader>nx` | Clear notification history |

These can be customized in your which-key configuration.

## Usage Examples

### Basic Usage

```lua
local notify = require('neotex.util.notifications')

-- User action notification (always shown)
notify.editor('File saved successfully', notify.categories.USER_ACTION, {
  file = vim.fn.expand('%:t'),
  lines = vim.api.nvim_buf_line_count(0)
})

-- Background operation (debug mode only)
notify.editor('Cache updated', notify.categories.BACKGROUND, {
  cache_size = cache_entries,
  update_time = os.time()
})

-- Error notification (always shown)
notify.lsp('Language server connection failed', notify.categories.ERROR, {
  server = 'lua-ls',
  error_code = 'ECONNREFUSED'
})
```

### Module-Specific Notifications

```lua
-- Himalaya email operations
local notify = require('neotex.util.notifications')

notify.himalaya('Email sent successfully', notify.categories.USER_ACTION, {
  recipient = recipient_email,
  subject = email_subject
})

notify.himalaya('Background sync completed', notify.categories.BACKGROUND, {
  emails_synced = sync_count,
  folder = folder_name
})

-- AI integration
notify.ai('Model switched to GPT-4', notify.categories.USER_ACTION, {
  previous_model = 'gpt-3.5-turbo',
  new_model = 'gpt-4'
})

notify.ai('Processing request', notify.categories.STATUS, {
  request_id = request_id,
  model = current_model
})
```

### Batch Operations

```lua
-- For bulk operations, use batching to prevent spam
local notify = require('neotex.util.notifications')

-- This will automatically batch similar notifications
for i = 1, 100 do
  notify.himalaya('Email deleted', notify.categories.USER_ACTION, {
    email_id = email_ids[i]
  })
end

-- Result: Single notification "100 emails deleted"
```

## Troubleshooting

### Common Issues

#### Too Many Notifications

If you're receiving too many notifications:

1. Check if debug mode is enabled: `:Notifications config`
2. Disable debug mode: `:NotifyDebug` or set `debug_mode = false` in config
3. Adjust module-specific settings to hide background operations

#### Missing Important Notifications

If you're not seeing expected notifications:

1. Verify notifications are enabled: `:Notifications config`
2. Check if the specific module is enabled in configuration
3. Ensure you're not using a minimal notification profile

#### Performance Issues

If notifications are causing performance problems:

1. Enable rate limiting in configuration
2. Reduce batch delay for faster processing
3. Disable modules you don't need
4. Check notification statistics: `:Notifications stats`

### Debug Mode

Debug mode shows all notifications including background operations. This is useful for:

- Troubleshooting configuration issues
- Understanding plugin behavior
- Debugging email synchronization
- Monitoring AI integration

Enable debug mode:
```lua
-- Global debug mode
:NotifyDebug

-- Module-specific debug mode
:NotifyDebug himalaya
:NotifyDebug ai
```

### Notification History

Access recent notifications and statistics:

```lua
-- Show last 50 notifications
:Notifications history

-- Show notification statistics by module
:Notifications stats

-- Clear notification history
:Notifications clear
```

## Best Practices

### For Users

1. **Start with defaults**: The default configuration provides a good balance
2. **Use debug mode sparingly**: Enable only when troubleshooting
3. **Customize by module**: Adjust settings per module based on your workflow
4. **Monitor statistics**: Use `:Notifications stats` to understand your notification patterns

### For Developers

1. **Choose appropriate categories**: Use USER_ACTION for user-initiated operations, BACKGROUND for automatic operations
2. **Provide context**: Include relevant information in the context parameter
3. **Use module-specific functions**: Use `notify.himalaya()`, `notify.ai()`, etc. instead of generic `notify()`
4. **Batch bulk operations**: Use batching for operations that might generate many notifications

## Integration with Other Tools

### Snacks.nvim Backend

The notification system uses Snacks.nvim as its display backend, providing:
- Modern popup styling
- Configurable timeout (4 seconds)
- Right-positioned notifications with margins
- Level-based visual styling

### Which-key Integration

Notification commands are integrated with which-key for easy access:
- `<leader>n` prefix for all notification commands
- Descriptive labels for each command
- Tab completion for module names

### Telescope Integration (Future)

Planned integration with Telescope for:
- Searchable notification history
- Filter notifications by module or category
- Advanced notification management interface

## Migration from Legacy Systems

If you're upgrading from direct `vim.notify` usage:

### Automatic Migration

Use the migration utility to automatically update your configuration:

```lua
-- Analyze current notification usage
:lua require('neotex.util.migrate_notifications').analyze_all()

-- Preview migration changes
:lua require('neotex.util.migrate_notifications').migrate_all(true)

-- Apply migration
:lua require('neotex.util.migrate_notifications').migrate_all(false)
```

### Manual Migration

For manual updates, replace direct vim.notify calls:

```lua
-- Before
vim.notify('Operation completed', vim.log.levels.INFO)

-- After
local notify = require('neotex.util.notifications')
notify.editor('Operation completed', notify.categories.USER_ACTION)
```

## Configuration Examples

### Minimal Setup (Errors and Actions Only)

```lua
local config = {
  debug_mode = false,
  modules = {
    himalaya = { email_operations = true, background_sync = false },
    ai = { model_switching = true, processing = false },
    lsp = { diagnostics = true, server_status = false },
    editor = { file_operations = true, performance = false }
  }
}
```

### Verbose Setup (Development/Debugging)

```lua
local config = {
  debug_mode = true,
  modules = {
    himalaya = { email_operations = true, background_sync = true },
    ai = { model_switching = true, processing = true },
    lsp = { diagnostics = true, server_status = true },
    editor = { file_operations = true, performance = true }
  }
}
```

### Custom Batching Settings

```lua
local config = {
  batching = {
    enabled = true,
    delay_ms = 2000,    -- 2 second delay
    max_batch_size = 5  -- Batch max 5 notifications
  },
  
  rate_limiting = {
    enabled = true,
    cooldown_ms = 500,     -- 500ms cooldown
    max_per_minute = 30    -- Max 30 notifications per minute
  }
}
```

## API Reference

### Core Functions

```lua
local notify = require('neotex.util.notifications')

-- Core notification function
notify.notify(message, category, context)

-- Module-specific functions
notify.himalaya(message, category, context)
notify.ai(message, category, context)
notify.lsp(message, category, context)
notify.editor(message, category, context)
notify.startup(message, category, context)

-- Configuration
notify.setup(config)
notify.set_profile(profile_name)

-- Management
notify.toggle_debug_mode()
notify.toggle_module_debug(module_name)
notify.show_history()
notify.show_stats()
notify.clear_history()
```

### Categories

```lua
local notify = require('neotex.util.notifications')

-- Available categories
notify.categories.ERROR      -- Always shown
notify.categories.WARNING    -- Always shown
notify.categories.USER_ACTION -- Always shown
notify.categories.STATUS     -- Debug mode only
notify.categories.BACKGROUND -- Debug mode only
```

### Context Parameters

Context provides additional information about notifications:

```lua
local context = {
  module = 'himalaya',           -- Module name (automatically set)
  file = 'document.txt',         -- Related file
  operation = 'send',            -- Operation type
  count = 5,                     -- Number of items affected
  duration = 1500,               -- Operation duration (ms)
  error_code = 'ECONNREFUSED',   -- Error code if applicable
  timestamp = os.time()          -- Operation timestamp
}
```

## Support and Contributing

### Getting Help

1. Check this documentation for common issues
2. Use `:Notifications stats` to understand your notification patterns
3. Enable debug mode for detailed troubleshooting
4. Review the configuration in `/lua/neotex/config/notifications.lua`

### Contributing

To contribute to the notification system:

1. Follow the established patterns for new notifications
2. Use appropriate categories and provide context
3. Test with both normal and debug modes
4. Update documentation for new features
5. Consider performance impact of new notifications

The unified notification system provides a powerful, flexible foundation for user feedback while maintaining a clean, distraction-free editing experience.