# Himalaya Plugin Architecture

A comprehensive guide to the Himalaya plugin's modular architecture, dependency management, and development patterns.

## Current Architecture Overview

The Himalaya plugin follows a layered architecture with some pragmatic compromises for functionality. This document reflects the actual implementation as of the Phase 1-5 refactoring completion.

## Module Structure

```
┌─────────────┐
│  init.lua   │ (Entry point - orchestrates all layers)
└──────┬──────┘
       │ 
       ├─────────────────────────────────────────────┐
       │                                             │
┌──────┴──────────────────────────────┐      ┌───────┴──────┐
│         Core Layer                  │      │ Setup Layer  │
├─────────────────────────────────────┤      ├──────────────┤
│ config.lua (with UI dependencies*)  │      │ wizard.lua   │
│ state.lua (unified state)           │      │ health.lua   │
│ logger.lua (logging)                │      │ migration.lua│
│ commands.lua (command registry*)    │      └──────────────┘
└───────┬─────────────────────────────┘
        │                                    
┌───────┴─────────────────────────────┐
│        Service Layer                │
├─────────────────────────────────────┤
│ utils.lua (Himalaya CLI operations) │
│ sync/manager.lua (sync orchestration)│
│ sync/mbsync.lua (mbsync integration)│
│ sync/oauth.lua (OAuth management)   │
│ sync/lock.lua (process locking)     │
└──────────────┬──────────────────────┘
               │                             
┌──────────────┴──────────────────────┐
│          UI Layer                   │
├─────────────────────────────────────┤
│ ui/init.lua (UI facade/setup)       │
│ ui/main.lua (UI coordination)       │
│ ui/email_list.lua (email listing)   │
│ ui/email_viewer.lua (email viewing) │
│ ui/email_composer.lua (composition) │
│ ui/sidebar.lua (sidebar management) │
│ ui/notifications.lua (user feedback)│
│ ui/window_stack.lua (window mgmt)   │
│ ui/float.lua (floating windows)     │
└─────────────────────────────────────┘

* = Contains architectural compromises (see below)
```

## Architectural Compromises

### Current Implementation Reality

While the ideal architecture would have strict unidirectional dependencies, the current implementation contains several pragmatic compromises:

1. **config.lua UI Dependencies**
   - Contains keybinding definitions that directly reference UI functions
   - Uses `require('neotex.plugins.tools.himalaya.ui.main')` for operations
   - This violates pure layering but provides convenient configuration

2. **commands.lua Cross-Layer Dependencies**
   - Located in core layer but depends on service layer (sync modules)
   - Uses lazy loading to access UI functions
   - Acts more as a coordination layer than pure core functionality

3. **sync/manager.lua UI Updates**
   - Uses `pcall` to optionally import UI modules for status updates
   - This soft dependency allows sync to work without UI but update it if available

## Actual Module Dependencies

### Core Layer
- **config.lua** 
  - Imports: `ui.main` (for keybinding actions), external notification system
  - Exports: Configuration data, keybinding definitions
  - Compromise: Contains UI dependencies for keybinding functionality
  
- **state.lua**
  - Imports: Only external dependencies (vim)
  - Exports: Unified state management API
  - Clean: No internal dependencies
  
- **logger.lua**
  - Imports: Only external dependencies (vim)
  - Exports: Logging API
  - Clean: No internal dependencies
  
- **commands.lua**
  - Imports: `sync/*` modules, lazy-loaded UI functions
  - Exports: Command definitions and registration
  - Compromise: Cross-layer dependencies for command implementation

### Service Layer
- **utils.lua**
  - Imports: `core.config`, `core.logger`
  - Exports: Himalaya CLI operations, email parsing utilities
  - Clean: Only depends on core layer
  
- **sync/manager.lua**
  - Imports: `core.state`, `core.logger`, soft UI dependencies via pcall
  - Exports: Unified sync coordination
  - Compromise: Optional UI updates through soft dependencies
  
- **sync/mbsync.lua**
  - Imports: `core.config`, `core.logger`, `sync.lock`
  - Exports: mbsync integration
  - Clean: Proper layering
  
- **sync/oauth.lua**
  - Imports: `core.config`, `core.state`
  - Exports: OAuth token management
  - Clean: Proper layering
  
- **sync/lock.lua**
  - Imports: `core.logger`
  - Exports: Process locking utilities
  - Clean: Minimal dependencies

### UI Layer
- **ui/init.lua**
  - Imports: `ui.main`
  - Exports: Setup function, re-exports main UI functions
  - Role: Backward compatibility facade
  
- **ui/main.lua**
  - Imports: Core layer, service layer, other UI modules
  - Exports: Main UI operations and coordination
  - Clean: Proper upward dependencies
  
- **ui/email_list.lua**
  - Imports: `core.state`, `utils`, `ui.sidebar`, `ui.notifications`
  - Exports: Email list functionality
  - Clean: Proper dependencies
  
- **ui/email_viewer.lua**
  - Imports: `core.state`, `core.logger`, `ui.window_stack`
  - Exports: Email viewing functionality
  - Clean: Proper dependencies
  
- **ui/email_composer.lua**
  - Imports: `core.state`, `ui.window_stack`, `utils`
  - Exports: Email composition functionality
  - Clean: Proper dependencies

### Setup Layer
- **setup/wizard.lua**
  - Imports: All layers as needed
  - Exports: Setup wizard functionality
  - Expected: Can depend on any layer
  
- **setup/health.lua**
  - Imports: All layers for health checking
  - Exports: Health check functionality
  - Expected: Can depend on any layer

## Dependency Rules (Ideal vs Actual)

### Ideal Rules
1. Core Layer → No internal dependencies
2. Service Layer → Core only
3. UI Layer → Core + Service
4. Setup Layer → Any layer

### Actual Implementation
1. Core Layer → Some UI dependencies (config.lua), service dependencies (commands.lua)
2. Service Layer → Core + soft UI dependencies (sync/manager.lua)
3. UI Layer → Core + Service (follows ideal)
4. Setup Layer → Any layer (follows ideal)

## External Dependencies

### Required Binaries
- **himalaya** - CLI email client (`himalaya --version`)
- **mbsync** (isync) - IMAP synchronization (`mbsync --version`)
- **flock** - Process locking (standard on Unix systems)
- **secret-tool** (Linux) - Keychain access
- **security** (macOS) - Keychain access

### Lua Dependencies
- **Neovim built-ins** - vim.api, vim.fn, vim.loop, vim.ui
- **neotex.util.notifications** - Centralized notification system
- **plenary.nvim** (optional) - Used minimally for async operations

### System Requirements
- **Maildir format** - ~/Mail/[account]/ directory structure
- **OAuth tokens** - System keychain or ~/.config/himalaya/oauth/
- **Configuration** - ~/.mbsyncrc, ~/.config/himalaya/
- **Scripts** - OAuth refresh scripts in scripts/ directory

## Common Development Patterns

### State Management
All state goes through unified `core/state.lua`:
```lua
local state = require('neotex.plugins.tools.himalaya.core.state')

-- UI state
state.set_current_folder('INBOX')
state.set_current_account('gmail')

-- Selection state  
state.toggle_email_selection(email_id, email_data)
state.clear_email_selections()

-- Sync state
state.set('sync.status', 'running')
state.set('sync.progress', { current = 10, total = 100 })

-- Session persistence
state.save_session()
state.restore_session()
```

### Error Handling
Consistent pattern across all modules:
```lua
local ok, result = pcall(operation)
if not ok then
  logger.error('Operation failed', { 
    context = 'function_name',
    error = result,
    account = current_account 
  })
  notify.himalaya(
    'Operation failed: ' .. vim.fn.fnamemodify(result, ':t'),
    notify.categories.ERROR
  )
  return nil, result
end
```

### Notifications
User feedback through notification system:
```lua
local notify = require('neotex.util.notifications')

-- Category-based notifications
notify.himalaya('Email sent', notify.categories.USER_ACTION)
notify.himalaya('Sync started', notify.categories.STATUS)
notify.himalaya('Connection failed', notify.categories.ERROR)
notify.himalaya('OAuth refreshing', notify.categories.BACKGROUND)

-- Debug mode notifications
if notify.config.modules.himalaya.debug_mode then
  notify.himalaya('Debug: ' .. message, notify.categories.BACKGROUND)
end
```

### Module Initialization
Standard initialization pattern:
```lua
local M = {}

-- Module-level state
local module_state = {
  initialized = false,
  -- other state
}

-- Initialization function
function M.init(dependencies)
  if module_state.initialized then return end
  
  -- Store dependencies
  module_state.deps = dependencies
  
  -- Initialize module
  -- ...
  
  module_state.initialized = true
end

-- Public API
function M.some_operation()
  if not module_state.initialized then
    error("Module not initialized")
  end
  -- implementation
end

return M
```

## Architecture Evolution Path

### Current Pragmatic Issues
1. **Keybinding coupling** - Config directly references UI functions
2. **Command layer confusion** - Commands.lua acts as orchestration but lives in core
3. **Soft dependencies** - pcall imports avoid hard dependencies but indicate coupling

### Future Improvements (Post Phase 7)
1. **Event System** - Decouple layers through event bus
   ```lua
   -- Instead of direct UI calls
   events.emit('email:selected', email_id)
   events.on('sync:progress', update_ui)
   ```

2. **Keybinding Abstraction** - Move keybindings to separate module
   ```lua
   -- keybindings.lua (new module at higher layer)
   local ui = require('himalaya.ui')
   return {
     ['<leader>mo'] = ui.open_email,
     ['<leader>mc'] = ui.compose_email,
   }
   ```

3. **Command Orchestration Layer** - Move commands.lua to proper orchestration layer
   ```
   init.lua
     └── orchestration/
           └── commands.lua (can access all layers)
   ```

4. **Dependency Injection** - Pass dependencies explicitly
   ```lua
   -- In init.lua
   local sync_manager = require('sync.manager')
   sync_manager.init({
     on_progress = ui.update_sync_status,
     on_complete = ui.refresh_email_list
   })
   ```

## Testing Architecture Compliance

### Check for Dependency Violations
```bash
# Find UI imports in core layer (should only be in config.lua)
grep -r "require.*\.ui\." core/ --include="*.lua"

# Find sync imports in core layer (should only be in commands.lua)  
grep -r "require.*\.sync\." core/ --include="*.lua"

# Find pcall imports (soft dependencies)
grep -r "pcall(require" . --include="*.lua" | grep -v test
```

### Validate Module Structure
```bash
# List all Lua modules by directory
find . -name "*.lua" -type f | grep -E "(core|sync|ui|setup)/" | sort

# Check for undocumented modules
find . -name "*.lua" | grep -v -E "(spec|docs|scripts|test)" | sort
```

## Design Principles

### Followed Principles
1. **Single Responsibility** - Each module has clear purpose
2. **State Centralization** - All state in core/state.lua
3. **Consistent Error Handling** - Unified patterns across modules
4. **Fail Gracefully** - Errors don't crash the plugin

### Compromised Principles  
1. **Strict Layering** - Some cross-layer dependencies exist
2. **Dependency Inversion** - Direct dependencies instead of abstractions
3. **Pure Functions** - Some modules have side effects across layers

## Summary

The Himalaya plugin architecture represents a pragmatic balance between ideal software architecture and practical Neovim plugin requirements. While not purely layered, it achieves:

- **Modularity** - Clear separation of concerns
- **Maintainability** - Most dependencies flow upward
- **Functionality** - All features work reliably
- **Performance** - Minimal overhead from architecture

Future refactoring phases (post Phase 7) can address the architectural compromises by introducing proper event systems and dependency injection patterns.

## Navigation
- [← Documentation](README.md)
- [Test Checklist](TEST_CHECKLIST.md)
- [Sync Implementation](SYNC_STAT.md)
