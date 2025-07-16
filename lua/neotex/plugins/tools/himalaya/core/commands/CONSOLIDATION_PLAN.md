# Command Module Consolidation Plan

## Current Structure (8 modules, 106 commands)
1. **email.lua** (374 lines, 19 commands) - Email operations, templates, search
2. **sync.lua** (341 lines, 8 commands) - Sync operations, OAuth
3. **ui.lua** (142 lines, 8 commands) - UI operations, folder navigation
4. **draft.lua** (407 lines, 18 commands) - Draft operations, testing
5. **features.lua** (401 lines, 14 commands) - Accounts, attachments, trash, contacts
6. **debug.lua** (519 lines, 16 commands) - Debug, test, async monitoring
7. **accounts.lua** (139 lines, 9 commands) - Account switching, view modes
8. **setup.lua** (296 lines, 14 commands) - Setup, health, migrations

## Proposed Structure (4 modules)

### 1. **email_commands.lua** (~800 lines)
Merge: email.lua + draft.lua + search/template parts
- Core email operations (write, send, discard)
- Draft management (save, list, delete, sync)
- Templates (create, edit, use)
- Search functionality
- Schedule operations
- ~37 commands total

### 2. **ui_commands.lua** (~600 lines)
Merge: ui.lua + accounts.lua + view parts from features.lua
- Main UI operations (open, toggle, refresh)
- Folder navigation
- Account switching
- View modes (unified, split, tabbed)
- Attachments and images
- ~25 commands total

### 3. **sync_commands.lua** (~350 lines)
Keep: sync.lua (mostly unchanged)
- Sync operations
- OAuth management
- Auto-sync control
- ~8 commands total

### 4. **utility_commands.lua** (~900 lines)
Merge: setup.lua + debug.lua + maintenance parts
- Setup and configuration
- Health checks
- Debug operations
- Test runners
- Async monitoring
- Migrations and fixes
- ~36 commands total

## Benefits
- Reduces from 8 to 4 modules (50% reduction)
- More logical grouping by functionality
- Easier to find related commands
- Maintains clear separation of concerns
- Reduces cognitive load

## Migration Strategy
1. Create new consolidated modules
2. Move commands maintaining exact functionality
3. Update init.lua to load new modules
4. Test all commands work correctly
5. Remove old modules