# Himalaya Plugin Architecture

## Module Hierarchy

The Himalaya plugin follows a strict layered architecture to ensure maintainability and prevent circular dependencies.

```
┌─────────────┐
│   init.lua  │ (Entry point)
└──────┬──────┘
       │
┌──────┴───────────────────────────────────┐
│            Core Layer                    │
├──────────────────────────────────────────┤
│ config.lua    │ state.lua                │
│ logger.lua    │ commands.lua             │
└──────────────┬───────────────────────────┘
               │
┌──────────────┴───────────────────────────┐
│          Service Layer                   │
├──────────────────────────────────────────┤
│ sync/manager.lua │ sync/oauth.lua        │
│ sync/mbsync.lua  │ sync/lock.lua         │
│ utils.lua (CLI operations)               │
└──────────────┬───────────────────────────┘
               │
┌──────────────┴───────────────────────────┐
│            UI Layer                      │
├──────────────────────────────────────────┤
│ ui/main.lua      │ ui/sidebar.lua        │
│ ui/email_list.lua│ ui/email_viewer.lua   │
│ ui/email_composer.lua│ ui/notifications.lua│
│ ui/window_stack.lua │ ui/float.lua       │
└──────────────┬───────────────────────────┘
               │
┌──────────────┴───────────────────────────┐
│          Setup Layer                     │
├──────────────────────────────────────────┤
│ setup/wizard.lua │ setup/health.lua      │
│ setup/migration.lua                      │
└──────────────────────────────────────────┘
```

## Dependency Rules

### Strict Rules (MUST follow):
1. **Core Layer** - Cannot depend on any other layers
2. **Service Layer** - Can only depend on Core layer
3. **UI Layer** - Can depend on Core and Service layers
4. **Setup Layer** - Can depend on Core, Service, and UI layers
5. **No circular dependencies** - A module cannot depend on a module that depends on it

### Module Responsibilities

#### Core Layer
- **config.lua**: Configuration management, account settings
- **state.lua**: All state management (UI state, sync state, selections)
- **logger.lua**: Logging infrastructure
- **commands.lua**: Command definitions and registration

#### Service Layer
- **sync/manager.lua**: Coordinates all sync operations
- **sync/mbsync.lua**: mbsync integration
- **sync/oauth.lua**: OAuth token management
- **sync/lock.lua**: Process locking to prevent conflicts
- **utils.lua**: Himalaya CLI operations, email parsing

#### UI Layer
- **ui/main.lua**: UI coordination and shared utilities
- **ui/email_list.lua**: Email list display and navigation
- **ui/email_viewer.lua**: Email viewing functionality
- **ui/email_composer.lua**: Email composition
- **ui/sidebar.lua**: Sidebar window management
- **ui/notifications.lua**: User notifications
- **ui/window_stack.lua**: Window management stack
- **ui/float.lua**: Floating window utilities

#### Setup Layer
- **setup/wizard.lua**: Initial setup wizard
- **setup/health.lua**: Health checks
- **setup/migration.lua**: Migration utilities

## Import Guidelines

### Correct imports by layer:

#### Core modules can import:
```lua
-- Nothing from other layers, only external deps
local logger = require('neotex.plugins.tools.himalaya.core.logger')
```

#### Service modules can import:
```lua
-- Core layer only
local config = require('neotex.plugins.tools.himalaya.core.config')
local state = require('neotex.plugins.tools.himalaya.core.state')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
```

#### UI modules can import:
```lua
-- Core layer
local config = require('neotex.plugins.tools.himalaya.core.config')
local state = require('neotex.plugins.tools.himalaya.core.state')

-- Service layer
local utils = require('neotex.plugins.tools.himalaya.utils')
local sync_manager = require('neotex.plugins.tools.himalaya.sync.manager')
```

#### Setup modules can import:
```lua
-- Any layer
local config = require('neotex.plugins.tools.himalaya.core.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local ui = require('neotex.plugins.tools.himalaya.ui')
```

## Common Patterns

### State Management
All state operations go through `core/state.lua`:
```lua
local state = require('neotex.plugins.tools.himalaya.core.state')
state.set('ui.current_folder', 'INBOX')
local folder = state.get('ui.current_folder')
```

### Error Handling
Consistent error handling pattern:
```lua
local ok, result = pcall(risky_operation)
if not ok then
  logger.error("Context: " .. result)
  notifications.show("Operation failed: " .. result, "error")
  return nil, result
end
```

### Notifications
User-facing messages through UI layer:
```lua
local notifications = require('neotex.plugins.tools.himalaya.ui.notifications')
notifications.show('Email sent successfully', 'success')
```

### Logging
Debug/error logging through core layer:
```lua
local logger = require('neotex.plugins.tools.himalaya.core.logger')
logger.debug('Processing email', { id = email_id })
logger.error('Sync failed', { error = error_msg })
```