# Himalaya Plugin Refactor Specification

## Overview

This document provides a comprehensive plan for refactoring the Himalaya email plugin to improve maintainability, reduce complexity, and establish clearer module boundaries. The refactor focuses on cleanup and reorganization without adding new features.

**Key Principles (from TODO.md GUIDELINES):**
- No need for backwards compatibility or comments about past implementations
- Keep the number of modules and commands minimal - prefer modifying existing modules
- Integrate with existing neovim configuration and notification system
- Work in phases with testing after each phase

## Current State Analysis

### Directory Structure

```
himalaya/
├── init.lua (1407 lines) - Main entry point and command definitions
├── utils.lua (619 lines) - CLI integration and email operations
├── TODO.md - Planning document for refactor and new features
├── core/
│   ├── config.lua (603 lines) - Configuration and keymaps
│   ├── logger.lua - Logging utilities
│   └── state.lua - Runtime state management
├── docs/
│   ├── README.md
│   └── SYNC_STAT.md
├── scripts/
│   ├── README.md
│   └── Various OAuth refresh scripts
├── setup/
│   ├── health.lua - Health checks
│   ├── migration.lua - Migration from old versions
│   └── wizard.lua - Setup wizard
├── spec/
│   ├── FEATURES_SPEC.md (empty)
│   └── REFACTOR_SPEC.md (this file)
├── sync/
│   ├── lock.lua - Process locking
│   ├── manager.lua - Sync orchestration
│   ├── mbsync.lua - mbsync integration
│   └── oauth.lua - OAuth token management
└── ui/
    ├── README.md
    ├── float.lua - Floating window utilities (unused)
    ├── init.lua - UI module exports
    ├── main.lua (2548 lines) - Core UI functionality
    ├── notifications.lua - Smart notification system
    ├── sidebar.lua - Sidebar management
    ├── state.lua - Persistent UI state
    └── window_stack.lua - Window management
```

### Key Issues Identified

1. **Monolithic Files**

   - `init.lua` contains 45+ command definitions inline (1407 lines)
   - `ui/main.lua` contains ALL UI functionality (2548 lines)
   - `utils.lua` mixes various concerns (619 lines)

2. **Architectural Problems**

   - Duplicate state management (`core/state.lua` vs `ui/state.lua`)
   - Commands defined far from their implementations
   - Mixed abstraction levels across modules
   - Circular dependencies between UI and sync modules

3. **Cruft and Redundancy**
   - Unused `ui/float.lua` module
   - Empty spec files
   - Redundant `ui/init.lua` that just re-exports from `ui/main.lua`
   - Multiple OAuth scripts that will eventually be removed

## Refactor Implementation Plan

**Important**: Following the GUIDELINES, prefer working with existing modules rather than creating new ones. Only create new modules when there's a compelling reason (e.g., file size > 800-1000 lines after reorganization, or clear separation of concerns that significantly improves maintainability).

### Phase 1: Documentation and Analysis (1-2 days) ✅ COMPLETE

#### 1.1 Create Directory Documentation ✅

Create README.md files for each directory following the project documentation policy:

- [x] `/himalaya/README.md` - Overview and module index
- [x] `/himalaya/core/README.md` - Core functionality documentation
- [x] `/himalaya/sync/README.md` - Synchronization system documentation
- [x] `/himalaya/setup/README.md` - Setup and configuration documentation
- [x] Update `/himalaya/ui/README.md` - UI components documentation
- [x] Update `/himalaya/scripts/README.md` - Scripts documentation
- [x] Create `/himalaya/spec/README.md` - Specification documents

Each README should include:

- Purpose and functionality overview
- Module descriptions with key functions
- Usage examples where applicable
- Links to subdirectory READMEs
- Parent directory link

#### 1.2 Map Dependencies ✅

- [x] Create dependency graph showing module relationships
- [x] Identify circular dependencies
- [x] Document external command dependencies (himalaya CLI, mbsync, etc.)
- [x] Note differences between NixOS and non-Nix users where relevant

**Created**: `/himalaya/docs/DEPENDENCIES.md` with full dependency analysis

### Phase 2: Core Cleanup and Reorganization (3-4 days)

#### 2.1 Refactor init.lua

Simplify the monolithic init.lua file:

- [ ] Consider whether commands should remain in init.lua or be moved
  - Only create `core/commands.lua` if there's a compelling reason
  - Otherwise, reorganize commands within init.lua for better clarity

- [ ] Simplify `init.lua` structure:
  - Load configuration
  - Set up autocommands
  - Register commands (organized by functionality)
  - Initialize keymaps

**Implementation approach:**

```lua
-- init.lua (simplified)
local M = {}
local commands = require("neotex.plugins.tools.himalaya.core.commands")

function M.setup(opts)
  -- Load config
  -- Set up autocommands
  commands.register_all()
  -- Initialize keymaps
end

return M
```

#### 2.2 Reorganize ui/main.lua

**Evaluate whether splitting is necessary** - Given the guideline to minimize modules, consider:

- [ ] First attempt to reorganize within ui/main.lua:
  - Group related functions together
  - Extract only if the file remains unmanageable
  - Use clear section comments to delineate functionality

- [ ] If splitting is justified (>2000 lines after reorganization), create minimal modules:
  - `ui/email_viewer.lua` - Email reading/display (if >500 lines)
  - `ui/email_composer.lua` - Compose/send functionality (if >500 lines)
  - Keep list, navigation, and actions in ui/main.lua

- [ ] Update `ui/main.lua` to orchestrate these modules

  - Keep only high-level coordination logic
  - Delegate specific functionality to appropriate modules

- [ ] Remove redundant `ui/init.lua`

**Implementation approach:**

- Extract functions by functionality group
- Maintain existing function signatures
- Use consistent module patterns
- Preserve all keybindings and commands

#### 2.3 Consolidate State Management

- [ ] Merge `ui/state.lua` into `core/state.lua`

  - Create clear namespaces for different state types
  - Implement proper state synchronization
  - Add state change events/callbacks

- [ ] State structure:
  ```lua
  state = {
    runtime = {      -- Non-persistent runtime state
      sync_status = {},
      oauth_tokens = {},
      active_account = nil,
    },
    ui = {           -- Persistent UI state
      last_folder = {},
      sidebar_width = 30,
      view_mode = "list",
    },
    session = {      -- Session-specific state
      buffers = {},
      windows = {},
      current_email = nil,
    }
  }
  ```

#### 2.4 Reorganize utils.lua

**Evaluate need for new modules** - Following minimal module guideline:

- [ ] Assess if utils.lua can be reorganized internally first
  - Group CLI operations together
  - Group email operations together
  - Clear section separation

- [ ] Only create new modules if utils.lua remains > 800 lines:
  - Consider `core/himalaya_cli.lua` only if CLI operations > 400 lines
  - Otherwise keep everything in a well-organized utils.lua

### Phase 3: Architecture Improvements (2-3 days)

#### 3.1 Establish Clear Module Hierarchy

```
┌─────────────┐
│   init.lua  │
└──────┬──────┘
       │
┌──────┴───────────────────────────┐
│            Core Layer            │
├──────────────────────────────────┤
│ commands.lua  │ config.lua       │
│ himalaya_cli.lua │ email_service.lua │
│ state.lua     │ logger.lua       │
└──────────────┬───────────────────┘
               │
┌──────────────┴───────────────────┐
│          Service Layer           │
├──────────────────────────────────┤
│ sync/manager.lua │ sync/oauth.lua│
│ sync/mbsync.lua  │ sync/lock.lua │
└──────────────┬───────────────────┘
               │
┌──────────────┴───────────────────┐
│            UI Layer              │
├──────────────────────────────────┤
│ ui/main.lua    │ ui/sidebar.lua  │
│ ui/email_*.lua │ ui/notifications│
└──────────────────────────────────┘
```

- [ ] Enforce dependency flow (UI → Service → Core)
- [ ] Remove circular dependencies
- [ ] Create clear interfaces between layers

#### 3.2 Standardize Error Handling

- [ ] Implement consistent error handling pattern:

  ```lua
  local ok, result = pcall(function_that_might_fail)
  if not ok then
    logger.error("Context: " .. result)
    return nil, result
  end
  ```

- [ ] Use `core/logger.lua` for all logging
- [ ] Remove duplicate notification code

#### 3.3 Clean Up Obsolete Code

- [ ] Remove unused `ui/float.lua`
- [ ] Remove old refactor documentation (`ui/REFACTOR.md`)
- [ ] Clean up completed TODO items
- [ ] Remove commented-out code

### Phase 4: Testing and Validation (1-2 days)

#### 4.1 Functional Testing

Test each refactored component:

- [ ] Command execution (all 45+ commands)
- [ ] Email list navigation
- [ ] Email viewing
- [ ] Email composition and sending
- [ ] Sync functionality
- [ ] OAuth token refresh
- [ ] State persistence

#### 4.2 Performance Testing

- [ ] Verify no performance regressions
- [ ] Check memory usage with large email lists
- [ ] Test sync performance

#### 4.3 Integration Testing

- [ ] Test with different account configurations
- [ ] Verify NixOS vs non-Nix compatibility
- [ ] Test all keybindings
- [ ] Verify notification system

### Phase 5: Progress Tracking and Documentation

#### 5.0 Progress Tracking (Throughout)
- [ ] Update TODO.md after each phase completion
- [ ] Update this REFACTOR_SPEC.md with completion status
- [ ] Request user testing after each phase
- [ ] Commit changes only after user confirms testing

### Phase 6: Final Documentation (1 day)

#### 5.1 Update Documentation

- [ ] Update main plugin documentation
- [ ] Document any API changes
- [ ] Update setup instructions if needed
- [ ] Add migration notes if necessary

#### 5.2 Code Comments

- [ ] Add function documentation for public APIs
- [ ] Document complex algorithms
- [ ] Add usage examples in key modules

## Implementation Guidelines

### Code Style

- Use consistent `M = {}` module pattern
- Prefer local functions for internal operations
- Follow 2-space indentation
- Keep line length ~100 characters
- Use descriptive variable names

### Testing Strategy

- Test after each sub-phase
- Use `:checkhealth himalaya` frequently
- Manual testing of all user-facing functionality
- Manual testing of all user-facing functionality after each phase

### Commit Strategy

- Commit after each completed sub-phase
- Use descriptive commit messages
- Reference this spec in commit messages
- Keep commits atomic and focused

## Success Criteria

1. **Reduced Complexity**

   - No single file > 800 lines
   - Clear module responsibilities
   - Simplified dependency graph

2. **Improved Maintainability**

   - Easy to locate functionality
   - Clear separation of concerns
   - Consistent patterns throughout

3. **Preserved Functionality**

   - All existing features work
   - No performance regressions
   - No need to maintain backward compatibility (per guidelines)

4. **Better Documentation**
   - README.md in each directory
   - Clear module documentation
   - Updated user documentation

## Notes

- OAuth scripts remain separate (no consolidation)
- No new features added during this refactor
- Focus on organization and cleanup only
- Future features spec will be developed separately
- Prefer modifying existing modules over creating new ones
- No backward compatibility requirements
- Integrate with neovim's notification system (`nvim/docs/NOTIFICATIONS.md`)
- Test with user after each phase before committing
