# Himalaya Architecture Evolution Specification

## Overview

This specification outlines the evolution of the Himalaya email plugin architecture from its current state (with phases 1-5 of refactoring complete) to a more maintainable, event-driven architecture. This is an **evolutionary approach** that preserves existing functionality while improving internal structure.

## Current State Assessment

### Completed Refactoring (Phases 1-5)

The Himalaya plugin has already undergone significant refactoring:

1. **Phase 1**: UI layout refactoring ✅
2. **Phase 2**: Enhanced UI/UX features ✅  
3. **Phase 3**: Unified state management ✅
4. **Phase 4**: Centralized notification system ✅
5. **Phase 5**: Email preview in sidebar ✅

### Current Architecture

```
himalaya/
├── init.lua                    # Entry point & orchestration
├── core/                       # Core functionality
│   ├── commands.lua           # Command registry (1400+ lines)
│   ├── config.lua             # Configuration (has UI deps)
│   ├── state.lua              # Unified state management
│   └── logger.lua             # Logging system
├── service/                    # Service layer
│   ├── email.lua              # Email operations
│   └── sync.lua               # Sync operations
├── sync/                       # Sync implementation
│   ├── manager.lua            # Sync orchestration
│   ├── mbsync.lua             # mbsync integration
│   └── oauth.lua              # OAuth handling
├── ui/                         # UI layer
│   ├── main.lua               # UI coordination (1000+ lines)
│   ├── sidebar.lua            # Sidebar component
│   ├── email_list.lua         # Email list view
│   ├── email_viewer.lua       # Email viewer
│   ├── email_composer.lua     # Email composition
│   └── init.lua               # Backward compatibility facade
└── setup/                      # Setup & diagnostics
    ├── wizard.lua             # Setup wizard
    └── health.lua             # Health checks
```

### Architectural Compromises

Current pragmatic compromises that work but violate pure layering:

1. **Config with UI deps**: `config.lua` contains keybinding functionality
2. **Commands know UI**: `commands.lua` directly calls UI functions
3. **Soft dependencies**: `sync/manager.lua` uses pcall for optional UI updates
4. **Cross-layer coupling**: Direct dependencies between layers

## Goals for Evolution

1. **Preserve Functionality**: All 31+ commands continue working
2. **Improve Maintainability**: Better separation of concerns
3. **Enable New Features**: Support planned features from spec files
4. **Gradual Migration**: No breaking changes for users
5. **Better Testing**: Enable unit testing of components
6. **Performance**: Maintain or improve current performance

## Proposed Evolution Architecture

### Target Architecture

```
┌─────────────┐
│  init.lua   │ (Bootstrap & compatibility)
└──────┬──────┘
       │
┌──────┴──────────────────────────────────────┐
│         Orchestration Layer (New)           │
├─────────────────────────────────────────────┤
│ orchestration/                              │
│   ├── bootstrap.lua      # Initialize all   │
│   ├── events.lua         # Event bus        │
│   ├── commands.lua       # Command routing  │
│   └── keybindings.lua    # Key mapping      │
└───────────────┬─────────────────────────────┘
                │ Events & Dependencies
┌───────────────┴─────────────────────────────┐
│            Core Layer                       │
├─────────────────────────────────────────────┤
│ core/                                       │
│   ├── config.lua         # Pure config data │
│   ├── state.lua          # State + events   │
│   ├── logger.lua         # Enhanced logging │
│   ├── errors.lua         # Error handling   │
│   ├── events.lua         # Event constants  │
│   └── commands/          # Split commands   │
│       ├── ui.lua                            │
│       ├── email.lua                         │
│       ├── sync.lua                          │
│       └── setup.lua                         │
└───────────────┬─────────────────────────────┘
                │
┌───────────────┴─────────────────────────────┐
│          Service Layer                      │
├─────────────────────────────────────────────┤
│ service/                                    │
│   ├── email.lua          # Email facade     │
│   ├── sync.lua           # Sync facade      │
│   ├── accounts.lua       # Multi-account    │
│   ├── search.lua         # Advanced search  │
│   ├── templates.lua      # Email templates  │
│   └── rules.lua          # Email rules      │
├─────────────────────────────────────────────┤
│ Features from new specs:                    │
│   ├── attachments.lua    # Attachment mgmt  │
│   ├── send_queue.lua     # Delayed send     │
│   ├── scheduler.lua      # Email scheduling │
│   ├── encryption.lua     # PGP/GPG support  │
│   └── trash.lua          # Local trash      │
└───────────────┬─────────────────────────────┘
                │
┌───────────────┴─────────────────────────────┐
│            UI Layer                         │
├─────────────────────────────────────────────┤
│ ui/                                         │
│   ├── controllers/       # Business logic   │
│   │   ├── email_list.lua                    │
│   │   ├── email_viewer.lua                  │
│   │   └── email_composer.lua                │
│   ├── views/             # Presentation     │
│   │   ├── sidebar.lua                       │
│   │   ├── unified_inbox.lua                 │
│   │   └── account_switcher.lua              │
│   ├── components/        # Reusable widgets │
│   │   ├── window_manager.lua                │
│   │   ├── notifications.lua                 │
│   │   └── image_viewer.lua                  │
│   └── main.lua           # UI coordinator   │
├─────────────────────────────────────────────┤
│ New UI Features:                            │
│   ├── oauth_setup.lua    # OAuth UI         │
│   ├── trash_viewer.lua   # Trash management │
│   └── address_complete.lua # Autocomplete   │
└─────────────────────────────────────────────┘
```

## Implementation Phases

### Phase 6: Event System Foundation
**Duration**: 1 week  
**Goal**: Introduce event system without breaking existing code

1. **Create Event Bus**:
   ```lua
   -- orchestration/events.lua
   local M = {}
   local handlers = {}
   local notify = require('neotex.util.notifications')
   
   function M.on(event, handler, options)
     options = options or {}
     handlers[event] = handlers[event] or {}
     table.insert(handlers[event], {
       handler = handler,
       priority = options.priority or 50,
       module = options.module
     })
     -- Sort by priority
     table.sort(handlers[event], function(a, b)
       return a.priority > b.priority
     end)
   end
   
   function M.emit(event, data)
     if handlers[event] then
       for _, h in ipairs(handlers[event]) do
         local ok, err = pcall(h.handler, data)
         if not ok then
           notify.himalaya(
             string.format("Event handler error: %s", err),
             notify.categories.ERROR,
             { event = event, module = h.module }
           )
         end
       end
     end
   end
   ```

2. **Define Core Events**:
   ```lua
   -- core/events.lua
   return {
     -- Lifecycle
     INIT_STARTED = "himalaya:init:started",
     INIT_COMPLETED = "himalaya:init:completed",
     
     -- Account management
     ACCOUNT_ADDED = "account:added",
     ACCOUNT_REMOVED = "account:removed",
     ACCOUNT_SWITCHED = "account:switched",
     
     -- Email operations
     EMAIL_LIST_REQUESTED = "email:list:requested",
     EMAIL_LIST_LOADED = "email:list:loaded",
     EMAIL_SELECTED = "email:selected",
     EMAIL_OPENED = "email:opened",
     EMAIL_SENT = "email:sent",
     EMAIL_DELETED = "email:deleted",
     EMAIL_MOVED = "email:moved",
     
     -- Sync operations
     SYNC_REQUESTED = "sync:requested",
     SYNC_STARTED = "sync:started",
     SYNC_PROGRESS = "sync:progress",
     SYNC_COMPLETED = "sync:completed",
     SYNC_FAILED = "sync:failed",
     
     -- UI events
     UI_REFRESH_REQUESTED = "ui:refresh:requested",
     UI_WINDOW_OPENED = "ui:window:opened",
     UI_WINDOW_CLOSED = "ui:window:closed",
     
     -- Feature events
     SEARCH_REQUESTED = "search:requested",
     SEARCH_COMPLETED = "search:completed",
     TEMPLATE_APPLIED = "template:applied",
     RULE_TRIGGERED = "rule:triggered"
   }
   ```

3. **Gradually Adopt Events**: Start emitting events alongside existing calls

### Phase 7: Command System Refactoring ✅ COMPLETE
**Duration**: 1 week  
**Goal**: Split monolithic commands.lua and add orchestration  
**Status**: Implemented with full backward compatibility

1. **Split Commands by Domain**:
   ```lua
   -- core/commands/email.lua
   local M = {}
   local events = require('orchestration.events')
   local core_events = require('core.events')
   
   function M.setup(register)
     register("HimalayaSend", function(opts)
       events.emit(core_events.EMAIL_SEND_REQUESTED, {
         args = opts.args
       })
     end, {
       nargs = "?",
       desc = "Send email"
     })
   end
   ```

2. **Command Orchestrator**:
   ```lua
   -- orchestration/commands.lua
   local M = {}
   local registered_commands = {}
   
   function M.setup()
     local function register(name, handler, options)
       registered_commands[name] = {
         handler = handler,
         options = options
       }
     end
     
     -- Load all command modules
     require('core.commands.ui').setup(register)
     require('core.commands.email').setup(register)
     require('core.commands.sync').setup(register)
     require('core.commands.setup').setup(register)
     
     -- Register with vim
     for name, cmd in pairs(registered_commands) do
       vim.api.nvim_create_user_command(name, cmd.handler, cmd.options)
     end
   end
   ```

### Phase 8: Service Layer Enhancement
**Duration**: 2 weeks  
**Goal**: Implement new features with proper abstraction

1. **Account Management Service**:
   ```lua
   -- service/accounts.lua
   local M = {}
   local providers = require('core.providers')
   local state = require('core.state')
   local events = require('orchestration.events')
   
   function M.add_account(email, config)
     -- Implementation from EMAIL_MANAGEMENT_FEATURES_SPEC
     local account = providers.create_account(email, config)
     state.add_account(account)
     events.emit('account:added', account)
     return account
   end
   ```

2. **Feature Services**: Implement services for:
   - Attachment handling
   - Send queue (undo send)
   - Email templates
   - Search engine
   - Rules engine
   - Trash management

### Phase 9: UI Layer Evolution
**Duration**: 2 weeks  
**Goal**: Implement MVC pattern with controllers

1. **Extract Controllers**:
   ```lua
   -- ui/controllers/email_list.lua
   local M = {}
   
   function M.init(deps)
     M.view = deps.views.email_list
     M.service = deps.services.email
     M.events = deps.events
     
     -- Subscribe to events
     M.events.on('email:list:requested', function(data)
       M.load_emails(data.folder, data.page)
     end)
   end
   
   function M.load_emails(folder, page)
     local emails = M.service.list(folder, page)
     M.view.render(emails)
     M.events.emit('email:list:loaded', emails)
   end
   ```

2. **Window Management**: Centralized window manager from specs

3. **New UI Components**: Implement from specs:
   - Unified inbox view
   - Account switcher
   - OAuth setup wizard
   - Image viewer
   - Address autocomplete

### Phase 10: Integration and Polish
**Duration**: 1 week  
**Goal**: Complete integration and optimize

1. **Performance Optimization**:
   - Lazy loading of heavy modules
   - Caching improvements
   - Event batching

2. **Testing Infrastructure**:
   - Unit tests for each layer
   - Integration tests for workflows
   - Performance benchmarks

3. **Documentation**:
   - Architecture guide
   - API documentation
   - Migration guide for customizations

## Migration Strategy

### Incremental Approach

1. **Parallel Implementation**: New architecture runs alongside old
2. **Feature Flags**: Toggle between old and new implementations
3. **Gradual Cutover**: Move features one at a time
4. **Compatibility Layer**: Maintain old APIs during transition

### Compatibility Preservation

```lua
-- init.lua maintains backward compatibility
local M = {}

-- Old API preserved
function M.setup(config)
  -- Forward to new orchestration
  require('orchestration.bootstrap').init(config)
end

-- Keep old command names
function M.open()
  vim.cmd('Himalaya')
end

return M
```

### User Impact Mitigation

1. **No Breaking Changes**: All commands work identically
2. **Same Keybindings**: User muscle memory preserved
3. **Config Migration**: Automatic config format conversion
4. **Graceful Degradation**: Fall back to old code if needed

## Success Metrics

1. **Functionality**: All existing features continue working
2. **Performance**: No degradation (target 5-10% improvement)
3. **Maintainability**: Clear module boundaries and dependencies
4. **Testability**: 80%+ code coverage achievable
5. **Code Quality**: 15-20% reduction in complexity
6. **New Features**: All spec features implementable

## Implementation Timeline

- **Week 1**: Event system foundation (Phase 6)
- **Week 2**: Command refactoring (Phase 7)
- **Week 3-4**: Service layer enhancement (Phase 8)
- **Week 5-6**: UI layer evolution (Phase 9)
- **Week 7**: Integration and polish (Phase 10)

Total: 7 weeks for complete evolution

## Risk Management

### Technical Risks

1. **Regression Risk**: Mitigated by comprehensive testing
2. **Performance Risk**: Mitigated by profiling and benchmarks
3. **Complexity Risk**: Mitigated by incremental approach

### User Experience Risks

1. **Breaking Changes**: Avoided by compatibility layer
2. **Learning Curve**: Mitigated by keeping same commands
3. **Customization Loss**: Mitigated by migration guides

## Conclusion

This evolutionary approach transforms the Himalaya plugin architecture while preserving its functionality and user experience. By building on the existing refactored codebase (phases 1-5) and taking an incremental approach, we can achieve a clean, maintainable architecture without disrupting users.

The key principles:
- **Evolution over Revolution**: Build on what works
- **User First**: No breaking changes
- **Pragmatic Design**: Some coupling is acceptable
- **Incremental Progress**: Small, tested changes
- **Feature Enablement**: Architecture supports new features

This approach delivers the architectural improvements needed to support the ambitious feature set outlined in the spec files while maintaining the stability users expect.
