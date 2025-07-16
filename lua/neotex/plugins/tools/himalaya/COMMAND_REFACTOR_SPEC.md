# Himalaya Command System Refactor Specification

## Current State Analysis

### Command-Related Locations
1. **`himalaya/commands/`** - 2 orphaned utility scripts
   - `debug_himalaya_output.lua` - Debug utility (not registered as command)
   - `migrate_drafts.lua` - One-time migration script (not registered)

2. **`himalaya/core/commands/`** - Active command system (4 consolidated modules)
   - `init.lua` - Registry and registration
   - `email_commands.lua` - Email operations 
   - `ui_commands.lua` - UI operations
   - `sync_commands.lua` - Sync operations
   - `utility_commands.lua` - Debug/setup/maintenance

3. **`himalaya/orchestration/commands.lua`** - Unused orchestration layer
   - Error handling and retry logic
   - Event emission for command lifecycle
   - Hook support for extensibility

### Issues Identified
1. **Confusing structure**: Three different command-related locations
2. **Orphaned utilities**: Scripts in `himalaya/commands/` not integrated
3. **Unused infrastructure**: Orchestration layer not utilized
4. **Naming inconsistency**: Mix of `/commands/` and `/core/commands/`

## Proposed Refactor Plan

### Option 1: Flatten to Single Location (Recommended)
Move all command-related code to `himalaya/commands/` and remove nested structure.

```
himalaya/
├── commands/
│   ├── init.lua              # Registry system
│   ├── email.lua             # Email operations
│   ├── ui.lua                # UI operations  
│   ├── sync.lua              # Sync operations
│   ├── utility.lua           # Debug/setup/maintenance
│   └── orchestrator.lua      # Command execution wrapper (optional)
├── core/                     # Core business logic only
└── orchestration/            # Remove or repurpose
```

**Benefits**:
- Single, clear location for all commands
- Follows common Neovim plugin patterns
- Removes confusion about where commands live
- Shorter require paths

**Migration Steps**:
1. Move `core/commands/*` files to `commands/`
2. Integrate orphaned utilities into appropriate modules
3. Update all require paths
4. Remove empty directories
5. Optional: Integrate orchestration features

### Option 2: Keep Core Structure, Clean Up Orphans
Keep current `core/commands/` structure but clean up inconsistencies.

```
himalaya/
├── core/
│   └── commands/
│       ├── init.lua
│       ├── email.lua
│       ├── ui.lua
│       ├── sync.lua
│       └── utility.lua
├── commands/                 # Remove this directory
└── orchestration/
    └── commands.lua          # Rename to orchestrator.lua
```

**Benefits**:
- Minimal changes to working system
- Maintains current architecture
- Less risk of breaking changes

**Migration Steps**:
1. Integrate `debug_himalaya_output` into `utility.lua`
2. Move `migrate_drafts` to a migrations archive
3. Remove `himalaya/commands/` directory
4. Rename orchestration file for clarity

### Option 3: Full Integration with Orchestration
Leverage the orchestration layer for all commands.

```
himalaya/
├── commands/
│   ├── init.lua              # Registry + orchestration integration
│   ├── definitions/          # Command definitions
│   │   ├── email.lua
│   │   ├── ui.lua
│   │   ├── sync.lua
│   │   └── utility.lua
│   └── orchestrator.lua      # Command execution engine
```

**Benefits**:
- Automatic error handling for all commands
- Event emission for monitoring
- Retry logic where appropriate
- Hook support for extensibility

**Migration Steps**:
1. Move command definitions to subdirectory
2. Integrate orchestrator into init.lua
3. Wrap all command handlers with orchestration
4. Add event listeners for logging/monitoring

## Recommendation

**I recommend Option 1**: Flatten to single `himalaya/commands/` location.

### Rationale:
1. **Simplicity**: One clear location for all command code
2. **Convention**: Follows typical Neovim plugin structure
3. **Discoverability**: Developers know exactly where to find commands
4. **Clean hierarchy**: Commands at top level, core logic deeper
5. **Minimal nesting**: Reduces require path complexity

### Implementation Plan for Option 1:

#### Phase 1: Prepare Migration
1. Create migration checklist
2. Identify all files that require path updates
3. Test current functionality baseline

#### Phase 2: Move Files
1. Move `core/commands/*.lua` to `commands/`
2. Update module names (remove `_commands` suffix)
3. Integrate orphaned utilities:
   - Add `HimalayaDebugOutput` command to utility.lua
   - Archive migrate_drafts.lua if no longer needed

#### Phase 3: Update Paths
1. Update all require statements throughout codebase
2. Update init.lua in main plugin
3. Update any documentation references

#### Phase 4: Clean Up
1. Remove empty `core/commands/` directory
2. Remove orphaned `commands/` files
3. Consider integrating orchestration features

#### Phase 5: Optional Enhancement
1. Integrate orchestrator for error handling
2. Add command execution events
3. Implement retry logic for appropriate commands

### File Mapping

| Current Path | New Path | Notes |
|-------------|----------|-------|
| `core/commands/init.lua` | `commands/init.lua` | No changes needed |
| `core/commands/email_commands.lua` | `commands/email.lua` | Remove suffix |
| `core/commands/ui_commands.lua` | `commands/ui.lua` | Remove suffix |
| `core/commands/sync_commands.lua` | `commands/sync.lua` | Remove suffix |
| `core/commands/utility_commands.lua` | `commands/utility.lua` | Remove suffix |
| `commands/debug_himalaya_output.lua` | Integrate into `commands/utility.lua` | As new command |
| `commands/migrate_drafts.lua` | Archive or delete | One-time migration |
| `orchestration/commands.lua` | `commands/orchestrator.lua` | Optional integration |

### Success Criteria
1. All commands continue to work exactly as before
2. Single, clear location for all command code
3. No orphaned or duplicate files
4. Clean directory structure
5. Updated documentation reflecting new structure

### Risk Mitigation
1. Create full backup before migration
2. Test each command after path updates
3. Use git commits between each phase
4. Have rollback plan ready
5. Update tests to reflect new paths