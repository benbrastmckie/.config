# Himalaya Plugin Dependencies

## Module Dependency Graph

```
┌─────────────────────────────────────────────────────────┐
│                      init.lua                           │
│  (Entry point, commands, setup)                         │
└────────────────┬────────────────────────────────────────┘
                 │
    ┌────────────┴────────────┬──────────────┬───────────┐
    │                         │              │           │
    ▼                         ▼              ▼           ▼
┌─────────┐           ┌──────────┐    ┌──────────┐ ┌──────────┐
│ config  │           │  utils   │    │   ui/*   │ │ setup/*  │
│         │           │          │    │          │ │          │
└────┬────┘           └────┬─────┘    └────┬─────┘ └────┬─────┘
     │                     │               │            │
     └─────────┬───────────┴───────────────┴────────────┘
               │
               ▼
         ┌──────────┐     ┌──────────┐     ┌──────────┐
         │  state   │     │  logger  │     │ sync/*   │
         │          │     │          │     │          │
         └──────────┘     └──────────┘     └──────────┘
```

## Circular Dependencies Identified

1. **ui/main.lua ↔ sync/manager.lua**
   - UI calls sync operations
   - Sync updates UI status
   - *Solution: Use events/callbacks*

2. **core/state.lua ↔ ui/state.lua**
   - Duplicate state management
   - *Solution: Merge into single module*

3. **utils.lua → multiple modules → utils.lua**
   - Utils used everywhere and uses other modules
   - *Solution: Extract into focused modules*

## External Dependencies

### Required Binaries
- **himalaya** - CLI email client
- **mbsync** (isync) - IMAP synchronization
- **flock** - Process locking
- **secret-tool** (optional) - Keychain access

### Lua Dependencies
- **plenary.nvim** - Async operations and utilities
- **nvim core modules** - vim.api, vim.fn, vim.loop

### System Dependencies
- **OAuth tokens** - Stored in system keychain
- **Maildir structure** - ~/Mail/[Account]/
- **Configuration files** - ~/.mbsyncrc, ~/.config/himalaya/

## Module Relationships

### Core Layer
- **config.lua** - Used by all modules for settings
- **logger.lua** - Used by all modules for notifications
- **state.lua** - Shared state across UI and sync

### Service Layer
- **sync/manager.lua** - Orchestrates mbsync and oauth
- **sync/mbsync.lua** - Depends on lock.lua
- **sync/oauth.lua** - Depends on external scripts
- **sync/lock.lua** - No internal dependencies

### UI Layer
- **ui/main.lua** - Depends on all core and sync modules
- **ui/sidebar.lua** - Depends on state and utils
- **ui/notifications.lua** - Depends on logger
- **ui/state.lua** - Persists UI preferences

### Setup Layer
- **setup/wizard.lua** - Depends on config and health
- **setup/health.lua** - Checks all dependencies
- **setup/migration.lua** - Updates config and state

## Recommendations for Refactor

1. **Break circular dependencies**
   - Implement event system for UI updates
   - Use callbacks instead of direct calls

2. **Consolidate state management**
   - Single source of truth in core/state.lua
   - Clear separation of concerns

3. **Extract focused modules from utils.lua**
   - CLI operations → core/himalaya_cli.lua
   - Email parsing → core/email_service.lua

4. **Establish clear layer boundaries**
   - UI should not directly call sync
   - Sync should not know about UI

## Navigation
- [← Additional Documentation](README.md)