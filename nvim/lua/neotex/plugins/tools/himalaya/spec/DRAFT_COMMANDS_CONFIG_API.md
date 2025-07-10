# Draft Commands and Configuration API Documentation (Phase 5)

This document describes the draft command system and configuration schema implemented in Phase 5.

## Overview

The draft system now provides:
- Comprehensive command set for all draft operations
- Flexible configuration system with validation
- Integration with the centralized command registry
- Consistent user experience across all draft features

## Draft Commands

All draft commands are registered through the centralized command system and follow consistent patterns.

### Creation and Editing

#### `:HimalayaDraftNew [account]`
Create a new email draft.
- **Optional Args**: Account name (e.g., 'gmail', 'work')
- **Completion**: Available account names
- **Example**: `:HimalayaDraftNew gmail`

#### `:HimalayaDraftSave`
Save the current draft to local storage.
- **Context**: Current buffer must be a draft
- **Notifications**: Shows "Draft saved: [subject]"

#### `:HimalayaDraftSend`
Send the current draft as an email.
- **Context**: Current buffer must be a draft
- **Behavior**: Saves draft, sends email, closes buffer
- **Notifications**: Shows "Email sent: [subject]"

### Synchronization

#### `:HimalayaDraftSync`
Sync the current draft with the remote server.
- **Context**: Current buffer must be a draft
- **Notifications**: Shows "Syncing draft..." then result

#### `:HimalayaDraftSyncAll`
Sync all unsaved drafts.
- **Behavior**: Queues all modified drafts for sync
- **Notifications**: Shows count of drafts being synced

### Management

#### `:HimalayaDraftList`
Display all active drafts in a floating window.
- **Display**: Shows subject, recipients, status, timestamps
- **Legend**: [✓] Synced, [✗] Unsaved changes

#### `:HimalayaDraftDelete`
Delete the current draft.
- **Context**: Current buffer must be a draft
- **Confirmation**: Optional based on config
- **Behavior**: Deletes local and remote copies

#### `:HimalayaDraftInfo`
Show detailed information about the current draft.
- **Display**: Metadata, status, IDs, timestamps, errors

### Status

#### `:HimalayaDraftStatus`
Show draft system status.
- **Display**: Total drafts, unsaved count, sync status, last sync time

### Autosave

#### `:HimalayaDraftAutosaveEnable`
Enable automatic draft saving.

#### `:HimalayaDraftAutosaveDisable`
Disable automatic draft saving.

## Configuration Schema

The draft system configuration is part of the main Himalaya configuration under the `draft` key.

### Complete Configuration Example

```lua
{
  draft = {
    -- Storage settings
    storage = {
      base_dir = vim.fn.stdpath('data') .. '/himalaya/drafts',
      format = 'json',     -- 'json' or 'eml'
      compression = false, -- Enable compression (future feature)
    },
    
    -- Sync settings
    sync = {
      auto_sync = true,        -- Automatically sync drafts
      sync_interval = 300,     -- Sync interval in seconds (5 minutes)
      sync_on_save = true,     -- Sync when saving
      retry_attempts = 3,      -- Number of retry attempts
      retry_delay = 5000,      -- Delay between retries (milliseconds)
    },
    
    -- Recovery settings
    recovery = {
      enabled = true,          -- Enable draft recovery
      check_on_startup = true, -- Check for recoverable drafts on startup
      max_age_days = 7,        -- Maximum age for recovery
      backup_unsaved = true,   -- Backup unsaved drafts
    },
    
    -- UI settings
    ui = {
      show_status_line = true, -- Show draft status in statusline
      confirm_delete = true,   -- Confirm before deleting drafts
      auto_save_delay = 30000, -- Autosave delay in milliseconds
    },
    
    -- Integration settings
    integration = {
      use_window_stack = true,    -- Use window stack for draft windows
      emit_events = true,         -- Emit events for draft operations
      use_notifications = true,   -- Use notification system
    }
  }
}
```

### Configuration Options

#### Storage Settings

- **`base_dir`** (string): Base directory for draft storage
  - Default: `vim.fn.stdpath('data') .. '/himalaya/drafts'`
  - Must be a valid directory path

- **`format`** (string): Storage format for drafts
  - Options: `'json'` or `'eml'`
  - Default: `'json'`

- **`compression`** (boolean): Enable compression (future feature)
  - Default: `false`

#### Sync Settings

- **`auto_sync`** (boolean): Enable automatic synchronization
  - Default: `true`

- **`sync_interval`** (number): Interval between sync attempts (seconds)
  - Default: `300` (5 minutes)
  - Must be positive

- **`sync_on_save`** (boolean): Sync immediately after saving
  - Default: `true`

- **`retry_attempts`** (number): Number of sync retry attempts
  - Default: `3`
  - Must be non-negative

- **`retry_delay`** (number): Delay between retries (milliseconds)
  - Default: `5000`
  - Must be non-negative

#### Recovery Settings

- **`enabled`** (boolean): Enable draft recovery system
  - Default: `true`

- **`check_on_startup`** (boolean): Check for recoverable drafts on startup
  - Default: `true`

- **`max_age_days`** (number): Maximum age for draft recovery (days)
  - Default: `7`
  - Must be positive

- **`backup_unsaved`** (boolean): Create backups of unsaved drafts
  - Default: `true`

#### UI Settings

- **`show_status_line`** (boolean): Show draft info in statusline
  - Default: `true`

- **`confirm_delete`** (boolean): Require confirmation before deleting
  - Default: `true`

- **`auto_save_delay`** (number): Delay before autosaving (milliseconds)
  - Default: `30000` (30 seconds)
  - Must be non-negative

#### Integration Settings

- **`use_window_stack`** (boolean): Track draft windows in window stack
  - Default: `true`

- **`emit_events`** (boolean): Emit events for draft operations
  - Default: `true`

- **`use_notifications`** (boolean): Show notifications for operations
  - Default: `true`

## Configuration Validation

The configuration system includes comprehensive validation:

### Validation Function

```lua
local ok, err = config.validate_draft_config(user_config)
if not ok then
  print("Configuration error: " .. err)
end
```

### Validation Rules

1. **Type Checking**: All options must be correct types
2. **Value Ranges**: Numeric values must be within valid ranges
3. **Format Validation**: String options must match allowed values
4. **Required Fields**: Storage base_dir is required

### Validation Messages

The validation system provides clear error messages:
- `"draft.storage.base_dir must be a string"`
- `"draft.storage.format must be 'json' or 'eml'"`
- `"draft.sync.sync_interval must be a positive number"`

## Command Registration

### Module Structure

```lua
-- core/commands/draft.lua
local M = {}

function M.setup(registry)
  local commands = {
    HimalayaDraftNew = {
      fn = function(opts) ... end,
      opts = {
        nargs = '?',
        desc = 'Create new email draft',
        complete = function() ... end
      }
    },
    -- More commands...
  }
  
  registry.register_batch(commands)
end

return M
```

### Integration

The draft command module is loaded automatically:

```lua
-- In core/commands/init.lua
require('neotex.plugins.tools.himalaya.core.commands.draft').setup(M)
```

## Usage Examples

### Basic Workflow

```vim
" Create new draft
:HimalayaDraftNew

" Save draft
:HimalayaDraftSave

" Sync with server
:HimalayaDraftSync

" Send email
:HimalayaDraftSend
```

### Management

```vim
" List all drafts
:HimalayaDraftList

" Check draft status
:HimalayaDraftStatus

" Get info about current draft
:HimalayaDraftInfo

" Delete draft (with confirmation)
:HimalayaDraftDelete
```

### Configuration

```lua
-- In your Neovim config
require('himalaya').setup({
  draft = {
    ui = {
      confirm_delete = false,  -- Disable delete confirmation
      auto_save_delay = 60000, -- Autosave every minute
    },
    sync = {
      sync_interval = 600,     -- Sync every 10 minutes
    }
  }
})
```

## Best Practices

1. **Command Naming**: All draft commands start with `HimalayaDraft`
2. **Consistent Options**: Similar commands use similar option patterns
3. **Error Handling**: Commands validate context and show appropriate messages
4. **Notifications**: All user actions trigger appropriate notifications
5. **Configuration**: Use validation to ensure configuration integrity

## Testing

### Command Testing

```lua
-- Check if commands are registered
local commands = require('neotex.plugins.tools.himalaya.core.commands')
assert(commands.has_command('HimalayaDraftNew'))
```

### Configuration Testing

```lua
-- Test configuration validation
local config = require('neotex.plugins.tools.himalaya.core.config')
local test_config = {
  draft = {
    sync = { sync_interval = -1 } -- Invalid
  }
}
local ok, err = config.validate_draft_config(test_config)
assert(not ok) -- Should fail
```

## Future Enhancements

1. **Autosave Implementation**: Complete autosave timer functionality
2. **Template Support**: Add draft templates
3. **Quick Actions**: Add keybindings for common operations
4. **Batch Operations**: Support operations on multiple drafts
5. **Advanced Search**: Search within drafts