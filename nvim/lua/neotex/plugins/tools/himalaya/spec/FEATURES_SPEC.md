# Himalaya Future Features Specification

This document outlines planned features and enhancements for the Himalaya email plugin. These features are organized by priority and complexity.

## High Priority Features

### 1. Enhanced UI/UX Features ✅ COMPLETE

- **Hover Preview**: Preview emails in a second sidebar when hovering ✅
- **Buffer-based Composition**: Compose/reply/forward emails in regular buffers ✅
  - Auto-save to drafts folder ✅
  - Delete drafts when discarding ✅
- **Improved Confirmations**: Use return/escape for confirmation dialogs ✅
- **Accurate Email Count**: Fix "Page 1 | 200 emails" to reflect actual count ✅
- **Remove Noisy Messages**: Remove "Himalaya closed" notification ✅
- **Smart Sync Status**: Refactor sidebar status for sync operations ✅
- **Auto-sync on Start**: Automatic sync when nvim opens ✅
- **Automatic Inbox Sync**: Keep inbox synced every 15 minutes with 2s startup delay ✅
  - Toggle auto-sync with `<leader>mt` ✅
  - Auto-sync status integrated into sync info display ✅
  - Configurable interval and startup delay ✅

**Implementation Details**: See [ENHANCED_UI_UX_SPEC.md](ENHANCED_UI_UX_SPEC.md) for full implementation documentation.

### 2. Email Management Features

- **Attachment Support**: View and manage email attachments
- **Image Display**: Inline image viewing in emails
- **Custom Headers**: Add custom header fields to emails
- **Address Autocomplete**: Complete addresses in format "Name <user@domain>"
- **Local Trash System**:
  - Move deleted emails to local trash
  - Mappings for viewing and recovering trash
  - Automatic trash cleanup
- **Himalaya FAQ Features**: Implement remaining features from [Himalaya FAQ](https://github.com/pimalaya/himalaya?tab=readme-ov-file#faq)

## Medium Priority Features

### 3. Code Quality Improvements

- **Enhanced Error Handling Module** (`core/errors.lua`):

  - Centralized error types and codes
  - Consistent error wrapping with context
  - Error recovery strategies
  - Integration with logging and notifications

- **API Consistency Layer**:

  - Standardize function return values (success, result, error)
  - Implement consistent parameter validation
  - Add type annotations for better IDE support
  - Create module facades to hide implementation details

- **Performance Optimizations**:
  - Add lazy loading for heavy modules
  - Implement caching for repeated operations
  - Optimize state persistence (currently saves entire UI state)
  - Profile and optimize slow operations

### 4. Developer Experience

- **Testing Infrastructure**:

  - Create `test/` directory with unit tests
  - Add integration test suite for critical paths
  - Implement mock modules for external dependencies
  - Add performance benchmarks

- **Observability**:

  - Enhanced logging with configurable log levels
  - Add performance timing for slow operations
  - Create debug mode with detailed operation traces
  - Add health metrics collection

- **Further Modularization**:
  - Split `commands.lua` (1293 lines) by functionality
  - Further modularize `ui/main.lua` (1025 lines)
  - Create focused modules for specific features

## Low Priority Features

### 5. Advanced Features

- **Multiple Account Views**: View emails from multiple accounts simultaneously
- **Advanced Search**: Full-text search with filters and operators
- **Email Templates**: Save and use email templates
- **Scheduling**: Schedule emails to send later
- **Encryption**: PGP/GPG email encryption support
- **Rules and Filters**: Client-side email filtering rules

### 6. Integration Features

- **Calendar Integration**: View and respond to calendar invites
- **Contact Management**: Integrated address book
- **Task Integration**: Convert emails to tasks
- **Note Taking**: Attach notes to emails
- **External Tool Integration**: Integration with external email tools

## Implementation Notes

### From TODO.md

The following features were originally planned and should be considered:

- Improved confirmations using return/escape keys
- Remove unnecessary notifications (e.g., "Himalaya closed")
- Fix email count display accuracy
- Implement attachment support
- Add image viewing capabilities
- Create local trash system with recovery options
- Address autocomplete in "Name <email>" format

### Technical Debt

- Fix TODO in `ui/email_list.lua` line 81 (maildir check implementation)
- Resolve backup directory execution issue (found during refactoring)
- Standardize all error handling patterns
- Complete migration to unified notification system

## Priority Guidelines

When implementing these features:

1. Maintain compatibility with existing functionality
2. Follow established architectural patterns
3. Use the unified notification system consistently
4. Add appropriate debug notifications for troubleshooting
5. Write comprehensive documentation for new features
6. Consider performance impact of new features
7. Maintain clean separation between layers (Core → Service → UI)

## Architecture Refactoring (Phase 8)

### Overview

Implement the ideal architecture with strict unidirectional dependencies, eliminating the current pragmatic compromises documented in ARCHITECTURE.md. This refactoring will establish a clean, maintainable architecture that follows SOLID principles. **This is a breaking change that intentionally removes all backward compatibility to achieve a tight, maintainable codebase.**

### Goals

1. **Eliminate cross-layer dependencies** - Remove UI dependencies from core layer
2. **Implement event-driven architecture** - Decouple layers through events
3. **Establish proper abstractions** - Use interfaces and dependency injection
4. **Remove all backward compatibility** - Clean slate for maintainability
5. **Improve testability** - Enable unit testing of individual layers
6. **Reduce codebase size** - Remove legacy code, compatibility shims, and workarounds

### Proposed Architecture

```
┌─────────────┐
│  init.lua   │ (Minimal orchestrator)
└──────┬──────┘
       │
┌──────┴──────────────────────────────────────┐
│         Orchestration Layer                 │
├─────────────────────────────────────────────┤
│ orchestration/bootstrap.lua                 │
│ orchestration/commands.lua                  │
│ orchestration/keybindings.lua               │
│ orchestration/events.lua (event bus)        │
└───────────────┬─────────────────────────────┘
                │ (events only)
┌───────────────┴─────────────────────────────┐
│            Core Layer                       │
├─────────────────────────────────────────────┤
│ core/config.lua (pure data, no functions)   │
│ core/state.lua (state management)           │
│ core/logger.lua (logging)                   │
│ core/events.lua (event definitions)         │
└───────────────┬─────────────────────────────┘
                │
┌───────────────┴─────────────────────────────┐
│          Service Layer                      │
├─────────────────────────────────────────────┤
│ service/email.lua (email operations)        │
│ service/sync.lua (sync operations)          │
│ service/oauth.lua (oauth operations)        │
│ sync/* (implementation details)             │
│ utils.lua (CLI wrapper)                     │
└───────────────┬─────────────────────────────┘
                │
┌───────────────┴─────────────────────────────┐
│            UI Layer                         │
├─────────────────────────────────────────────┤
│ ui/controllers/* (UI controllers)           │
│ ui/views/* (UI views/windows)               │
│ ui/components/* (reusable UI components)    │
└─────────────────────────────────────────────┘
```

### Implementation Plan

#### Step 1: Create Event System

```lua
-- orchestration/events.lua
local M = {}
local handlers = {}

function M.on(event, handler)
  handlers[event] = handlers[event] or {}
  table.insert(handlers[event], handler)
end

function M.emit(event, data)
  if handlers[event] then
    for _, handler in ipairs(handlers[event]) do
      handler(data)
    end
  end
end

-- core/events.lua (event definitions)
return {
  -- Sync events
  SYNC_STARTED = "sync:started",
  SYNC_PROGRESS = "sync:progress",
  SYNC_COMPLETED = "sync:completed",
  SYNC_FAILED = "sync:failed",

  -- Email events
  EMAIL_SELECTED = "email:selected",
  EMAIL_OPENED = "email:opened",
  EMAIL_SENT = "email:sent",
  EMAIL_DELETED = "email:deleted",

  -- UI events
  UI_REFRESH_REQUESTED = "ui:refresh_requested",
  UI_FOLDER_CHANGED = "ui:folder_changed",
  UI_ACCOUNT_SWITCHED = "ui:account_switched",
}
```

#### Step 2: Extract Pure Configuration

```lua
-- core/config.lua (pure data only)
local M = {}

M.defaults = {
  accounts = {},
  ui = {
    sidebar_width = 30,
    float_width = 80,
    float_height = 20,
  },
  sync = {
    auto_sync = false,
    sync_interval = 300,
  },
  keymaps = {}, -- Just data, no functions
}

function M.get(key)
  -- Pure getter, no side effects
end

function M.set(key, value)
  -- Pure setter, emit CONFIG_CHANGED event
end
```

#### Step 3: Move Keybindings to Orchestration

```lua
-- orchestration/keybindings.lua
local events = require('orchestration.events')
local core_events = require('core.events')

local M = {}

function M.setup()
  local config = require('core.config')
  local keymaps = config.get('keymaps')

  -- Map keys to events instead of direct functions
  vim.keymap.set('n', keymaps.open or '<leader>mo', function()
    events.emit(core_events.UI_OPEN_REQUESTED)
  end)

  vim.keymap.set('n', keymaps.compose or '<leader>mc', function()
    events.emit(core_events.UI_COMPOSE_REQUESTED)
  end)
end
```

#### Step 4: Refactor Commands with Dependency Injection

```lua
-- orchestration/commands.lua
local M = {}

function M.setup(deps)
  local commands = {}

  -- Email commands
  commands.Himalaya = function(args)
    deps.events.emit('ui:open_requested', { folder = args[1] })
  end

  commands.HimalayaSyncFull = function()
    deps.events.emit('sync:full_requested')
  end

  -- Register all commands
  for name, handler in pairs(commands) do
    vim.api.nvim_create_user_command(name, handler, {})
  end
end
```

#### Step 5: Create Service Layer Abstractions

```lua
-- service/email.lua
local M = {}
local events = require('orchestration.events')
local core_events = require('core.events')

function M.init(deps)
  M.utils = deps.utils
  M.state = deps.state
  M.logger = deps.logger
end

function M.list(folder, page)
  -- Implementation using utils
  local emails = M.utils.himalaya_list(folder, page)
  events.emit(core_events.EMAIL_LIST_LOADED, emails)
  return emails
end

function M.send(email_data)
  -- Implementation
  local result = M.utils.himalaya_send(email_data)
  if result.success then
    events.emit(core_events.EMAIL_SENT, email_data)
  end
  return result
end
```

#### Step 6: Refactor UI Layer with Controllers

```lua
-- ui/controllers/email_list.lua
local M = {}

function M.init(deps)
  M.view = deps.view
  M.email_service = deps.email_service
  M.events = deps.events

  -- Subscribe to events
  M.events.on('email:list_requested', function(data)
    M.show_list(data.folder, data.page)
  end)
end

function M.show_list(folder, page)
  local emails = M.email_service.list(folder, page)
  M.view.render(emails)
end
```

#### Step 7: Bootstrap Everything

```lua
-- orchestration/bootstrap.lua
local M = {}

function M.init()
  -- Initialize event system
  local events = require('orchestration.events')

  -- Initialize core layer
  local config = require('core.config')
  local state = require('core.state')
  local logger = require('core.logger')

  -- Initialize service layer with dependencies
  local email_service = require('service.email')
  email_service.init({
    utils = require('utils'),
    state = state,
    logger = logger,
  })

  local sync_service = require('service.sync')
  sync_service.init({
    state = state,
    logger = logger,
    events = events,
  })

  -- Initialize UI layer
  local ui_controllers = {
    email_list = require('ui.controllers.email_list'),
    email_viewer = require('ui.controllers.email_viewer'),
    email_composer = require('ui.controllers.email_composer'),
  }

  for _, controller in pairs(ui_controllers) do
    controller.init({
      email_service = email_service,
      sync_service = sync_service,
      events = events,
      state = state,
    })
  end

  -- Setup commands and keybindings
  require('orchestration.commands').setup({ events = events })
  require('orchestration.keybindings').setup({ events = events })

  -- Wire up cross-layer event handlers
  M.setup_event_routing(events)
end

function M.setup_event_routing(events)
  -- Sync events update UI
  events.on('sync:progress', function(data)
    events.emit('ui:update_sync_status', data)
  end)

  -- UI events trigger services
  events.on('ui:sync_requested', function(data)
    events.emit('sync:start_requested', data)
  end)
end
```

### Migration Strategy - Clean Break Approach

#### Phase 8.1: Create New Architecture (Greenfield)

1. Create entirely new directory structure (himalaya-v2/)
2. Implement clean event system from scratch
3. Build orchestration layer without legacy constraints
4. Design service abstractions without compatibility concerns
5. Write comprehensive test suite for new architecture

#### Phase 8.2: Feature Parity Implementation

1. Reimplement all 31 commands in new architecture
2. No compatibility layers or adapters
3. No migration of old code - rewrite for clarity
4. Test new implementation thoroughly
5. Document all breaking changes

#### Phase 8.3: Hard Cutover

1. Archive old implementation to himalaya-legacy/
2. Move new implementation to main himalaya/
3. Update init.lua to use new bootstrap only
4. Remove ALL deprecated code and patterns
5. Update all documentation from scratch

#### Phase 8.4: Cleanup and Optimization

1. Delete himalaya-legacy/ after verification period
2. Remove any remaining compatibility code
3. Optimize without legacy constraints
4. Reduce total LOC by 30-40% target

### Breaking Changes (Intentional)

1. **Configuration Format**

   - New YAML/TOML based config (no Lua tables)
   - No migration tool - users must reconfigure
   - Cleaner, validated schema

2. **API Changes**

   - All module paths change
   - No compatibility aliases
   - Function signatures optimized for new architecture

3. **State Format**

   - New state serialization format
   - No migration of old state
   - Users start fresh

4. **Removed Features**
   - ui/init.lua facade (unnecessary abstraction)
   - Soft dependencies via pcall
   - Multiple ways to do the same thing
   - Legacy command aliases

### Benefits of Clean Break

1. **Reduced Complexity**: No backward compatibility code
2. **Smaller Codebase**: Target 30-40% reduction in LOC
3. **Better Performance**: No compatibility overhead
4. **Cleaner Architecture**: No compromises for legacy support
5. **Easier Maintenance**: Single way to do things
6. **Faster Development**: No need to consider old patterns

### Code Reduction Examples

```lua
-- OLD: ui/init.lua (compatibility facade)
local M = {}
local ui_main = require('neotex.plugins.tools.himalaya.ui.main')
function M.setup() return ui_main.setup() end
-- ... 50+ lines of re-exports
return M

-- NEW: Removed entirely (users import ui.main directly)
```

```lua
-- OLD: Soft dependencies with pcall
local ok, ui = pcall(require, 'himalaya.ui')
if ok and ui.update_status then
  ui.update_status(data)
end

-- NEW: Event-driven (no UI knowledge needed)
events.emit('sync:progress', data)
```

### Risks and Mitigation

1. **Risk**: User disruption from breaking changes

   - **Mitigation**: Clear migration guide, but NO compatibility code
   - **Philosophy**: Short-term pain for long-term maintainability

2. **Risk**: Loss of user customizations

   - **Mitigation**: Document new extension points clearly
   - **Philosophy**: Better to break than to accumulate technical debt

3. **Risk**: Feature gaps during migration
   - **Mitigation**: Feature freeze on old codebase
   - **Philosophy**: All effort goes to new architecture

### Success Criteria

1. All 31 commands work (may have different internals)
2. Zero cross-layer dependencies (enforced by tooling)
3. 100% test coverage on new codebase
4. 30-40% reduction in total lines of code
5. Zero backward compatibility code
6. Performance improvement of 10%+ (no compatibility overhead)
7. Clean dependency graph with no cycles or workarounds

### Timeline Estimate

- Phase 8.1: 3-4 days (greenfield development)
- Phase 8.2: 7-10 days (reimplement everything cleanly)
- Phase 8.3: 1 day (hard cutover)
- Phase 8.4: 2-3 days (optimization and cleanup)

**Total: 13-18 days of focused development**
_(Longer than compatibility approach but results in cleaner codebase)_

### Implementation Philosophy

1. **No Compromises**: If something requires a hack, redesign it
2. **Single Source of Truth**: One way to do each thing
3. **Explicit Over Implicit**: No magic, no hidden behavior
4. **Break Early**: Fail fast on architectural violations
5. **Document Everything**: But keep code self-documenting

### Post-Refactor Codebase Structure

```
himalaya/
├── init.lua (50 lines max - just bootstrap)
├── orchestration/
│   ├── bootstrap.lua (wire everything together)
│   ├── commands.lua (command → event mapping)
│   ├── keybindings.lua (key → event mapping)
│   └── events.lua (event bus implementation)
├── core/
│   ├── config.lua (pure data structures)
│   ├── state.lua (state management)
│   ├── logger.lua (logging)
│   └── events.lua (event constants)
├── service/
│   ├── email.lua (email operations)
│   ├── sync.lua (sync operations)
│   └── oauth.lua (oauth operations)
├── ui/
│   ├── controllers/ (business logic)
│   ├── views/ (presentation)
│   └── components/ (reusable widgets)
└── config/
    └── schema.yaml (configuration schema)
```

### Notes

- **Breaking Change Notice**: Version 2.0.0 with no upgrade path
- **User Communication**: Announce 30 days before release
- **No Deprecation Period**: Clean cutover
- **Documentation**: Complete rewrite, no references to old system
- **Support Policy**: Old version unsupported after cutover
