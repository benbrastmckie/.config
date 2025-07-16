# Himalaya Plugin Architecture V3: Pragmatic Excellence

## Philosophy: Evolution, Not Revolution

This architecture combines the **pragmatic wisdom** from the current implementation with the **elegant design principles** of a clean modular structure. Rather than a complete rewrite, this represents a thoughtful evolution that preserves what works while addressing architectural debt.

## Design Principles

### 🎯 **Core Tenets**
- **Respect existing functionality** - No features lost during refactoring
- **Pragmatic compromises** - Acknowledge where ideal architecture meets real-world needs
- **Incremental improvement** - Evolution through targeted refactoring, not revolution
- **Developer productivity** - Maintain development velocity throughout transition

### 📏 **Structural Guidelines**
- **Max 6-8 files per directory** for improved navigation
- **Target 200-350 lines per file** for maintainability
- **Clear module boundaries** with well-defined interfaces
- **Minimal circular dependencies** through careful layering

## Current State Acknowledgment

### What Works Well (Preserve)
- ✅ **Unified state management** through `core/state.lua`
- ✅ **Consistent error handling** patterns across modules
- ✅ **Solid command system** in `commands/` directory
- ✅ **Working UI components** with clear separation
- ✅ **Reliable sync infrastructure** 
- ✅ **Comprehensive test coverage**

### Architectural Debt (Address)
- ⚠️ **Oversized modules**: `utils.lua` (2,046 lines), `ui/main.lua` (1,800 lines)
- ⚠️ **Mixed concerns**: Configuration contains UI dependencies
- ⚠️ **Monolithic utilities**: Single file handles 6 different domains
- ⚠️ **Directory overcrowding**: `core/` (19 files), `ui/` (14 files)

## Target Architecture

### Directory Structure

```
himalaya/
├── core/                    # Essential system services (6 files)
│   ├── api.lua             # Himalaya CLI interface (250 lines)
│   ├── state.lua           # Unified application state (300 lines) ✅ Keep as-is
│   ├── logger.lua          # Logging infrastructure (200 lines) ✅ Keep as-is  
│   ├── events.lua          # Event constants & basic utilities (150 lines)
│   ├── errors.lua          # Error handling & recovery (250 lines)
│   └── performance.lua     # Performance monitoring (200 lines)
├── config/                  # Configuration management (6 files)
│   ├── init.lua            # Configuration facade (100 lines)
│   ├── accounts.lua        # Account definitions & credentials (300 lines)
│   ├── folders.lua         # Folder mapping & structure (200 lines)
│   ├── oauth.lua           # OAuth settings & token management (250 lines)
│   ├── ui.lua              # UI preferences & keybindings (250 lines)
│   └── validation.lua      # Config validation & migration (300 lines)
├── data/                    # Data operations & persistence (7 files)  
│   ├── init.lua            # Data module exports (50 lines)
│   ├── cache.lua           # Email caching with smart invalidation (300 lines)
│   ├── drafts.lua          # Draft management & Maildir operations (350 lines)
│   ├── search.lua          # Email search & indexing (300 lines)
│   ├── templates.lua       # Email templates & expansion (350 lines)
│   ├── scheduler.lua       # Email scheduling & queues (350 lines)
│   └── maildir.lua         # Maildir format operations (250 lines)
├── utils/                   # Domain-specific utilities (6 files)
│   ├── init.lua            # Utility exports & common functions (100 lines)
│   ├── string.lua          # String formatting & manipulation (250 lines)
│   ├── email.lua           # Email formatting & validation (300 lines)
│   ├── cli.lua             # Himalaya CLI execution & parsing (350 lines)
│   ├── file.lua            # File operations & path utilities (200 lines)
│   └── async.lua           # Async operations & coordination (300 lines)
├── commands/                # User commands (6 files) ✅ Keep structure
│   ├── init.lua            # Command registration (100 lines)
│   ├── email.lua           # Email operations (350 lines)
│   ├── ui.lua              # UI commands (300 lines)
│   ├── sync.lua            # Sync commands (150 lines)
│   ├── utility.lua         # General utilities (350 lines)
│   └── orchestrator.lua    # Event orchestration (400 lines)
├── ui/                      # User interface (8 files)
│   ├── init.lua            # UI module exports (50 lines)
│   ├── coordinator.lua     # Main UI coordination (350 lines)
│   ├── session.lua         # Session & buffer management (300 lines)
│   ├── email_list.lua      # Email list display (400 lines)
│   ├── email_preview.lua   # Email reading interface (350 lines)
│   ├── email_composer.lua  # Email composition (400 lines)
│   ├── sidebar.lua         # Folder sidebar (300 lines)
│   └── notifications.lua   # UI notifications (200 lines)
├── features/                # Extended functionality (6 files) ✅ Keep as-is
├── sync/                    # Email synchronization (5 files) ✅ Keep as-is
├── setup/                   # Plugin setup (2 files) ✅ Keep as-is
└── test/                    # Testing infrastructure ✅ Keep as-is
```

## Layered Architecture with Pragmatic Dependencies

### Layer Definition

```
┌─────────────────────────────────────────────────────────────┐
│                    Setup & Commands Layer                   │
│  setup/, commands/ - Can access any layer for coordination  │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────────────────┐
│                     UI Layer                                │
│     ui/ - User interface components                         │
│     Depends on: core, config, data, utils                   │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────────────────┐
│                   Service Layers                            │
│  features/, sync/ - Extended functionality                  │
│  Depends on: core, config, data, utils                      │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────────────────┐
│                  Foundation Layers                          │
│  core/, config/, data/, utils/ - Core functionality         │
│  Minimal interdependencies within this layer                │
└─────────────────────────────────────────────────────────────┘
```

### Dependency Rules

#### Strict Rules (Must Follow)
1. **UI Layer** → Foundation + Service layers only
2. **Service Layer** (features/, sync/) → Foundation layers only  
3. **Foundation Layer** → Minimal cross-dependencies within layer

#### Pragmatic Exceptions (With Justification)
1. **config/ui.lua** → May reference UI functions for keybinding definitions
2. **commands/** → May access any layer (coordination responsibility)
3. **setup/** → May access any layer (initialization responsibility)

## Test-Driven Development Protocol

### 🧪 **Core Testing Philosophy**
Every phase follows strict test-driven development:

1. **Pre-Phase**: Analyze and plan with test coverage in mind
2. **Implementation**: Write tests alongside refactoring
3. **Validation**: `:HimalayaTest all` must pass 100% before proceeding
4. **Documentation**: Update test results and coverage metrics
5. **User Approval**: Manual testing confirmation required

### 📋 **Testing Checklist Template**
Each phase must complete:
```markdown
- [ ] Run `:HimalayaTest all` - baseline before changes
- [ ] Implement refactoring with backward compatibility
- [ ] Write new unit tests for refactored modules
- [ ] Run `:HimalayaTest all` - must achieve 100% pass rate
- [ ] Update integration tests if needed
- [ ] Document any test failures and fixes
- [ ] Commit with descriptive message
- [ ] Request manual testing from user
- [ ] Receive approval before next phase
```

## Implementation Timeline

### Phase 1: Utils Refactoring (Week 1)
**Goal**: Split `utils.lua` (2,046 lines) into focused modules

**Structure**:
```
utils/
├── init.lua       # Backward compatibility & exports (100 lines)
├── string.lua     # String utilities (250 lines)
├── email.lua      # Email formatting (300 lines)
├── cli.lua        # CLI operations (350 lines)
├── file.lua       # File operations (200 lines)
└── async.lua      # Async utilities (300 lines)
```

**New Tests Required**: ~25 unit tests across utils modules

### Phase 2: Configuration Restructuring (Week 2)
**Goal**: Split `core/config.lua` (1,204 lines) into domain modules

**Structure**:
```
config/
├── init.lua       # Unified interface (100 lines)
├── accounts.lua   # Account management (300 lines)
├── folders.lua    # Folder mapping (200 lines)
├── oauth.lua      # OAuth settings (250 lines)
├── ui.lua         # UI & keybindings (250 lines)*
└── validation.lua # Config validation (300 lines)
```

**Pragmatic Compromise**: `config/ui.lua` contains UI dependencies (documented)  
**New Tests Required**: ~20 unit tests for config modules

### Phase 3: UI Architecture Cleanup (Week 3)
**Goal**: Split `ui/main.lua` (1,800 lines) into manageable components

**Changes**:
- Extract `ui/coordinator.lua` (350 lines)
- Extract `ui/session.lua` (300 lines)
- Trim `ui/email_list.lua` to 400 lines
- Trim `ui/email_preview.lua` to 350 lines

**New Tests Required**: ~15 unit tests for UI modules

### Phase 4: Data Layer Organization (Week 4)
**Goal**: Create `data/` directory for data operations

**Structure**:
```
data/
├── init.lua       # Module exports (50 lines)
├── cache.lua      # Email caching (300 lines)
├── drafts.lua     # Draft management (350 lines)
├── search.lua     # Search operations (300 lines)
├── templates.lua  # Template system (350 lines)
├── scheduler.lua  # Email scheduling (350 lines)
└── maildir.lua    # Maildir operations (250 lines)
```

**New Tests Required**: ~30 unit tests for data modules

### Phase 5: Final Validation (Week 5)
**Goal**: Complete architecture validation and documentation

**Tasks**:
- Run architecture compliance scripts
- Full integration testing
- Performance regression testing
- Documentation updates
- Final manual testing approval

## Development Patterns (Preserved from Current Architecture)

### 🗃️ **State Management Pattern**
**Status**: ✅ **Keep Exactly As-Is** - This pattern works perfectly

```lua
local state = require('neotex.plugins.tools.himalaya.core.state')

-- UI state management
state.set_current_folder('INBOX')
state.set_current_account('gmail')

-- Selection management  
state.toggle_email_selection(email_id, email_data)
state.clear_email_selections()

-- Sync state tracking
state.set('sync.status', 'running')
state.set('sync.progress', { current = 10, total = 100 })

-- Session persistence
state.save_session()
state.restore_session()
```

### ⚠️ **Error Handling Pattern**
**Status**: ✅ **Preserve Exactly** - Excellent consistent pattern

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

### 📢 **Notification System**
**Status**: ✅ **Keep Current Categories** - Well-designed system

```lua
local notify = require('neotex.util.notifications')

-- Categorized notifications (preserve exactly)
notify.himalaya('Email sent', notify.categories.USER_ACTION)
notify.himalaya('Sync started', notify.categories.STATUS)  
notify.himalaya('Connection failed', notify.categories.ERROR)
notify.himalaya('OAuth refreshing', notify.categories.BACKGROUND)

-- Debug mode support
if notify.config.modules.himalaya.debug_mode then
  notify.himalaya('Debug: ' .. message, notify.categories.BACKGROUND)
end
```

### 🔧 **Module Initialization Pattern**
**Status**: ✅ **Standardize Across New Modules**

```lua
local M = {}

-- Module-level state  
local module_state = {
  initialized = false,
  deps = nil
}

-- Standard initialization with dependency injection
function M.init(dependencies)
  if module_state.initialized then return end
  
  -- Store dependencies for testability
  module_state.deps = dependencies or {}
  
  -- Module-specific initialization
  -- ...
  
  module_state.initialized = true
end

-- Ensure initialization before operations
function M.some_operation()
  if not module_state.initialized then
    error("Module not initialized. Call M.init() first.")
  end
  -- implementation
end

return M
```

## Import Patterns for New Architecture

### Foundation Layer Imports
```lua
-- Core services (available everywhere)
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local state = require('neotex.plugins.tools.himalaya.core.state')
local events = require('neotex.plugins.tools.himalaya.core.events')

-- Configuration (available everywhere) 
local config = require('neotex.plugins.tools.himalaya.config')

-- Utilities (available everywhere)
local utils = require('neotex.plugins.tools.himalaya.utils')
local cli = require('neotex.plugins.tools.himalaya.utils.cli')

-- Data operations
local data = require('neotex.plugins.tools.himalaya.data')
local drafts = require('neotex.plugins.tools.himalaya.data.drafts')
```

### Service & UI Layer Imports
```lua
-- UI components (for other UI modules)
local ui = require('neotex.plugins.tools.himalaya.ui')
local coordinator = require('neotex.plugins.tools.himalaya.ui.coordinator')

-- Features (when needed)
local features = require('neotex.plugins.tools.himalaya.features')
local contacts = require('neotex.plugins.tools.himalaya.features.contacts')

-- Sync operations  
local sync = require('neotex.plugins.tools.himalaya.sync')
```

### Backward Compatibility
```lua
-- Old imports continue to work during transition:
local utils = require('neotex.plugins.tools.himalaya.utils')
utils.execute_himalaya(...)  -- Still works via utils/init.lua

-- New granular imports also available:
local cli = require('neotex.plugins.tools.himalaya.utils.cli')
cli.execute_himalaya(...)    -- Direct access to specific utility
```

## External Dependencies & System Requirements

### Required Binaries (Unchanged)
```bash
# Core email functionality
himalaya --version          # CLI email client
mbsync --version            # IMAP synchronization (isync package)

# System utilities
flock                       # Process locking (standard on Unix)
secret-tool                 # Linux keychain access
security                    # macOS keychain access
```

### Lua Dependencies (Preserved)
```lua
-- Neovim built-ins (no changes)
vim.api, vim.fn, vim.loop, vim.ui

-- External notifications (keep current integration)
require('neotex.util.notifications')

-- Optional async support (minimal usage)
require('plenary.nvim')  -- Only where absolutely necessary
```

### System Requirements (Document Current State)
```bash
# Maildir structure (preserve exactly)
~/Mail/[account]/
  ├── .Drafts/
  ├── .Sent/
  ├── INBOX/
  └── ...

# Configuration files (no changes to format)
~/.mbsyncrc
~/.config/himalaya/

# OAuth tokens (preserve current storage)
System keychain or ~/.config/himalaya/oauth/

# OAuth refresh scripts (keep current)
scripts/gmail_oauth_refresh.sh
scripts/outlook_oauth_refresh.sh
```

## Testing & Validation Strategy

### Architecture Compliance Testing
```bash
#!/bin/bash
# scripts/check_architecture.sh

echo "🔍 Checking architectural compliance..."

# Check for UI imports in foundation layers (should be minimal)
echo "Checking foundation layer purity..."
ui_in_foundation=$(find core/ config/ data/ utils/ -name "*.lua" -exec grep -l "require.*\.ui\." {} \; 2>/dev/null)
if [[ -n "$ui_in_foundation" ]]; then
  echo "⚠️  UI dependencies in foundation layers:"
  echo "$ui_in_foundation"
else
  echo "✅ Foundation layers are UI-independent"
fi

# Check for oversized files (>400 lines)
echo "Checking file sizes..."
oversized=$(find . -name "*.lua" -not -path "./test/*" -exec wc -l {} \; | awk '$1 > 400 {print $2 " (" $1 " lines)"}')
if [[ -n "$oversized" ]]; then
  echo "⚠️  Oversized files:"
  echo "$oversized"
else
  echo "✅ All files under 400 lines"
fi

# Check directory file counts (max 8 files)
echo "Checking directory sizes..."
for dir in core config data utils ui commands features sync setup; do
  if [[ -d "$dir" ]]; then
    count=$(find "$dir" -maxdepth 1 -name "*.lua" | wc -l)
    if (( count > 8 )); then
      echo "⚠️  $dir/ has $count files (max 8 recommended)"
    else
      echo "✅ $dir/ has $count files"
    fi
  fi
done

# Check for circular dependencies
echo "Checking for potential circular dependencies..."
# Implementation would scan require statements for cycles

echo "Architecture check complete!"
```

### Functional Testing Integration
```lua
-- Preserve all current test infrastructure
test/
├── commands/        # Command-specific tests ✅ Keep all
├── features/        # Feature tests ✅ Keep all  
├── integration/     # Workflow tests ✅ Keep all
├── performance/     # Performance tests ✅ Keep all
└── utils/          # Test utilities ✅ Keep all

-- Add architecture-specific tests
test/
├── architecture/
│   ├── test_imports.lua      # Validate import patterns
│   ├── test_file_sizes.lua   # Check size constraints
│   └── test_dependencies.lua # Check layer compliance
└── unit/           # New unit tests for refactored modules
    ├── utils/      # Tests for each utils module
    ├── config/     # Tests for each config module
    ├── data/       # Tests for each data module
    └── ui/         # Tests for refactored UI modules
```

### Test Writing Guidelines

#### Unit Test Template
```lua
-- test/unit/utils/test_string.lua
local test_framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local string_utils = require('neotex.plugins.tools.himalaya.utils.string')

local M = {}

function M.test_truncate_string()
  -- Test normal truncation
  test_framework.assert_equals(
    string_utils.truncate('very long string', 10),
    'very lo...',
    'Should truncate long strings'
  )
  
  -- Test short string preservation
  test_framework.assert_equals(
    string_utils.truncate('short', 10),
    'short',
    'Should preserve short strings'
  )
  
  -- Test edge cases
  test_framework.assert_equals(
    string_utils.truncate(nil, 10),
    '',
    'Should handle nil input'
  )
end

function M.test_format_date()
  -- Test date formatting
  local timestamp = os.time({year=2024, month=1, day=15})
  test_framework.assert_equals(
    string_utils.format_date(timestamp),
    'Jan 15',
    'Should format date correctly'
  )
end

return M
```

#### Integration Test Guidelines
- Test complete workflows across modules
- Verify backward compatibility
- Test error handling paths
- Validate state consistency

### Test Execution Commands
```vim
" Run all tests
:HimalayaTest all

" Run specific test category
:HimalayaTest unit
:HimalayaTest integration
:HimalayaTest performance

" Run tests for specific module
:HimalayaTest unit/utils
:HimalayaTest unit/config
```

## Test Coverage Growth

| Phase | Starting Tests | New Tests | Total Tests |
|-------|----------------|-----------|-------------|
| Current | 122 | 0 | 122 |
| Phase 1 (Utils) | 122 | ~25 | ~147 |
| Phase 2 (Config) | 147 | ~20 | ~167 |
| Phase 3 (UI) | 167 | ~15 | ~182 |
| Phase 4 (Data) | 182 | ~30 | ~212 |
| Phase 5 (Final) | 212 | ~10 | ~222 |

## Benefits Realized

### 👨‍💻 **Developer Experience**
- **Predictable structure**: Know exactly where to find functionality
- **Focused modules**: No overwhelming 2,000-line files
- **Clear interfaces**: Well-defined module boundaries
- **Easy testing**: Smaller, focused modules are easier to test

### 🔧 **Maintainability**
- **Single responsibility**: Each module has one clear purpose
- **Logical grouping**: Related functionality organized together
- **Manageable sizes**: All files under 400 lines
- **Clear dependencies**: Understand what depends on what

### 🚀 **Performance**  
- **Lazy loading**: Load only needed modules
- **Reduced memory**: Smaller modules loaded on demand
- **Better caching**: More granular dependency tracking
- **Faster startup**: Reduced initial load time

### 🧪 **Testability**
- **Pure functions**: Utilities accept parameters instead of globals
- **Dependency injection**: Easy to mock dependencies
- **Isolated modules**: Test components without side effects
- **Clear interfaces**: Well-defined testing boundaries

## Future Evolution Path

### Near-term Improvements (Post-refactoring)
1. **Event System Enhancement**: Further decouple layers through robust event bus
2. **Dependency Injection**: Move toward explicit dependency injection patterns
3. **Plugin Architecture**: Enable feature modules to be truly optional
4. **Performance Monitoring**: Built-in performance tracking and optimization

### Long-term Vision  
1. **Microservice Architecture**: Each feature as independent service
2. **Hot Reloading**: Reload individual modules without restart
3. **Plugin API**: Third-party plugin development support
4. **Configuration DSL**: More expressive configuration language

## Architectural Compromises (Acknowledged)

### Pragmatic Decisions
1. **Config UI Dependencies**: `config/ui.lua` references UI functions for keybindings
   - **Why**: Essential for user experience, configuration convenience
   - **Mitigation**: Clearly documented, isolated to one module

2. **Command Layer Access**: `commands/` can access any layer
   - **Why**: Commands need to coordinate across all functionality
   - **Mitigation**: Commands act as thin coordination layer, minimal logic

3. **Gradual Migration**: Preserve backward compatibility during transition
   - **Why**: Maintain stability, allow incremental testing
   - **Mitigation**: Remove compatibility shims after successful migration

### Future Improvements
1. **Event-Driven Keybindings**: Replace direct UI references with events
2. **Command Interface Standardization**: Formal command interface contracts  
3. **Dependency Graph Visualization**: Tools to understand and optimize dependencies

## Success Criteria

### 🎯 **Per-Phase Requirements**

1. **100% existing test pass rate** - No regression allowed
2. **New module test coverage** - All new modules must have tests
3. **Backward compatibility tests** - Old imports must still work
4. **Performance benchmarks** - No degradation in performance
5. **Manual testing approval** - User validates functionality

## Summary

This architecture represents an **evolution, not revolution** approach with **rigorous testing at every step**. By enforcing comprehensive testing for each phase, we ensure:

- ✅ **Zero regression** - All tests must pass before proceeding  
- ✅ **Incremental validation** - Each phase independently tested and approved
- ✅ **Comprehensive coverage** - New tests for all refactored modules
- ✅ **User confidence** - Manual testing approval before next phase
- ✅ **Clean commits** - Each phase atomically committed when complete

The result is a **professional-grade email client** with clean architecture that has been **thoroughly tested at every step** of the migration process.

## Navigation
- [← Current Architecture](ARCHITECTURE.md)
- [← V2 Design](ARCHITECTURE_V2.md)  
- [Future Features](FUTURE_FEATURES.md)
- [Testing Strategy](TEST_CHECKLIST.md)
