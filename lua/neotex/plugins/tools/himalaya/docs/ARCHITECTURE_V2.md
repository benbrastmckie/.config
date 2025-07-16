# Himalaya Plugin Architecture V2: Elegant Module Distribution

## Design Principles

This architectural redesign follows key principles for maintainable, scalable code:

- **📁 Directory Limit**: Maximum 6-8 files per directory for navigability
- **📄 File Size Limit**: Maximum 300-400 lines per file for readability  
- **🎯 Single Responsibility**: Each module has one clear, focused purpose
- **🔗 Minimal Dependencies**: Reduced circular dependencies and coupling
- **📊 Logical Grouping**: Related functionality organized together
- **🧪 Testability**: Clear interfaces enable comprehensive testing

## Current State Analysis

### Problems with Current Architecture

1. **Oversized Files**: 5 files exceed 1,000 lines (utils.lua = 2,046 lines!)
2. **Overcrowded Directories**: core/ (19 files), ui/ (14 files) exceed limits
3. **Mixed Concerns**: Single files handling multiple responsibilities
4. **Circular Dependencies**: Complex dependency chains
5. **Monolithic Utilities**: utils.lua contains 6 different concerns

### Quantitative Overview
- **Total Files**: 78 Lua files (33,622 lines)
- **Oversized Files**: 5 files >1,000 lines (need splitting)
- **Large Files**: 13 files 400-1,000 lines (should be split)
- **Overcrowded Directories**: 2 directories >8 files

## New Architecture Design

### Directory Structure Overview

```
himalaya/
├── core/                    # Essential system services (6 files)
├── config/                  # Configuration management (6 files)  
├── data/                    # Data operations & persistence (7 files)
├── utils/                   # Utility functions & helpers (6 files)
├── commands/                # User commands & operations (6 files)
├── ui/                      # User interface components (8 files)
├── features/                # Extended functionality (6 files)
├── sync/                    # Email synchronization (5 files)
├── setup/                   # Plugin setup & initialization (2 files)
└── test/                    # Testing infrastructure (organized)
```

### Detailed Directory Specifications

## 1. Core System Services (`core/`) - 6 Files

**Purpose**: Essential system-level services that other modules depend on.

```lua
core/
├── init.lua              # Core module exports & initialization (50 lines)
├── api.lua              # Himalaya CLI interface wrapper (200 lines)
├── state.lua            # Application state management (300 lines)
├── events.lua           # Event system & constants (150 lines)
├── logger.lua           # Logging infrastructure (200 lines)
└── errors.lua           # Error handling & recovery (250 lines)
```

**Responsibilities**:
- **init.lua**: Consolidated exports for core dependencies
- **api.lua**: Clean interface to Himalaya CLI commands
- **state.lua**: Centralized application state (current folder, page, etc.)
- **events.lua**: Event constants and basic event utilities
- **logger.lua**: Structured logging with levels and categories
- **errors.lua**: Error types, handling, and recovery strategies

## 2. Configuration Management (`config/`) - 6 Files

**Purpose**: All configuration-related functionality separated by concern.

```lua
config/
├── init.lua              # Configuration module exports (50 lines)
├── accounts.lua          # Account configuration & validation (300 lines)
├── folders.lua           # Folder mapping & structure (200 lines)
├── oauth.lua             # OAuth settings & token management (250 lines)
├── ui.lua                # UI preferences & settings (200 lines)
└── validation.lua        # Configuration validation logic (300 lines)
```

**Split from**: Current `core/config.lua` (1,204 lines)

**Responsibilities**:
- **accounts.lua**: Account definitions, credentials, server settings
- **folders.lua**: IMAP folder mapping, local folder structure
- **oauth.lua**: OAuth2 configuration, token refresh, provider settings
- **ui.lua**: UI preferences, keybindings, display options
- **validation.lua**: Configuration validation, migration, defaults

## 3. Data Operations (`data/`) - 7 Files

**Purpose**: Data persistence, caching, and specialized data operations.

```lua
data/
├── init.lua              # Data module exports (50 lines)
├── cache.lua             # Email caching with smart invalidation (300 lines)
├── drafts.lua            # Draft management & Maildir operations (400 lines)
├── search.lua            # Email search & indexing (350 lines)
├── templates.lua         # Email templates & macros (400 lines)
├── scheduler.lua         # Email scheduling & queue management (350 lines)
└── maildir.lua           # Maildir format operations (300 lines)
```

**Split from**: 
- `core/draft_manager_maildir.lua` (857 lines) → `drafts.lua`
- `core/search.lua` (867 lines) → `search.lua`
- `core/templates.lua` (840 lines) → `templates.lua`
- `core/scheduler.lua` (1,217 lines) → `scheduler.lua`

**Responsibilities**:
- **cache.lua**: Email caching, normalization, TTL management
- **drafts.lua**: Draft persistence using Maildir format
- **search.lua**: Email search with caching and filtering
- **templates.lua**: Email template system and expansion
- **scheduler.lua**: Delayed email sending and queue management
- **maildir.lua**: Low-level Maildir operations

## 4. Utility Functions (`utils/`) - 6 Files

**Purpose**: Reusable utility functions organized by domain.

```lua
utils/
├── init.lua              # Utility exports & common functions (100 lines)
├── string.lua            # String formatting & manipulation (250 lines)
├── email.lua             # Email formatting & validation (300 lines)
├── cli.lua               # Himalaya CLI execution & parsing (400 lines)
├── file.lua              # File operations & path utilities (200 lines)
└── async.lua             # Asynchronous operations & promises (300 lines)
```

**Split from**: Current `utils.lua` (2,046 lines)

**Responsibilities**:
- **string.lua**: truncate_string, format_date, format_from, time_ago
- **email.lua**: format_flags, format_size, parse_email_content
- **cli.lua**: execute_himalaya, command validation, result parsing
- **file.lua**: path operations, file I/O, directory management
- **async.lua**: async command execution, promises, debouncing

## 5. User Commands (`commands/`) - 6 Files ✅

**Purpose**: User-facing commands organized by functionality. (Already well-organized)

```lua
commands/
├── init.lua              # Command registration & management (100 lines)
├── email.lua             # Email operations (read, send, delete) (350 lines)
├── ui.lua                # UI commands (show, hide, refresh) (300 lines)
├── sync.lua              # Synchronization commands (150 lines)
├── utility.lua           # General utility commands (350 lines)
└── orchestrator.lua      # Event orchestration & command coordination (500 lines)
```

**Status**: ✅ Current structure is well-designed, minimal changes needed

## 6. User Interface (`ui/`) - 8 Files

**Purpose**: UI components with clear separation of concerns.

```lua
ui/
├── init.lua              # UI module exports & initialization (50 lines)
├── orchestrator.lua      # Main UI coordination & session management (400 lines)
├── buffer_manager.lua    # Buffer lifecycle & management (300 lines)
├── email_list.lua        # Email list display & interaction (400 lines)
├── email_preview.lua     # Email reading interface (350 lines)
├── email_composer.lua    # Email composition interface (400 lines)
├── sidebar.lua           # Folder sidebar & navigation (300 lines)
└── notifications.lua     # UI notifications & messaging (200 lines)
```

**Split from**: 
- `ui/main.lua` (1,800 lines) → `orchestrator.lua` + `buffer_manager.lua`
- Other UI files trimmed to target sizes

**Responsibilities**:
- **orchestrator.lua**: Main UI coordination, window management
- **buffer_manager.lua**: Buffer creation, lifecycle, cleanup
- **email_list.lua**: Email list rendering, pagination, selection
- **email_preview.lua**: Email content display, attachments
- **email_composer.lua**: Email composition, drafts, sending
- **sidebar.lua**: Folder tree, account switching, navigation
- **notifications.lua**: User notifications, status messages

## 7. Extended Features (`features/`) - 6 Files ✅

**Purpose**: Optional advanced features with clean interfaces.

```lua
features/
├── accounts.lua          # Multi-account management (250 lines)
├── attachments.lua       # Attachment handling & preview (300 lines)
├── contacts.lua          # Contact management & autocomplete (350 lines)
├── headers.lua           # Advanced header processing (200 lines)
├── images.lua            # Image display & processing (300 lines)
└── views.lua             # Alternative view modes (150 lines)
```

**Status**: ✅ Current structure is appropriate, minor adjustments only

## 8. Synchronization (`sync/`) - 5 Files ✅

**Purpose**: Email synchronization with external servers.

```lua
sync/
├── coordinator.lua       # Sync coordination & scheduling (200 lines)
├── manager.lua           # Sync operations & state (300 lines)
├── mbsync.lua            # Mbsync integration (400 lines)
├── oauth.lua             # OAuth token refresh (200 lines)
└── lock.lua              # Sync locking & concurrency (150 lines)
```

**Status**: ✅ Well-organized, mbsync.lua might be trimmed slightly

## 9. Setup & Initialization (`setup/`) - 2 Files ✅

**Purpose**: Plugin setup and initial configuration.

```lua
setup/
├── health.lua            # Health checks & diagnostics (200 lines)
└── wizard.lua            # Setup wizard & account configuration (400 lines)
```

**Status**: ✅ Appropriate size and organization

## Module Size Guidelines

### Target File Sizes
- **🎯 Optimal**: 150-300 lines (most modules)
- **📏 Acceptable**: 300-400 lines (complex logic modules)
- **⚠️ Warning**: 400+ lines (requires justification)
- **❌ Too Large**: 500+ lines (must be split)

### Size Categories by Function
- **Initialization files** (`init.lua`): 50-100 lines
- **Utility modules**: 200-300 lines  
- **Core business logic**: 300-400 lines
- **Complex UI components**: 350-400 lines
- **Configuration modules**: 250-350 lines

## Dependency Management

### Import Patterns

#### Core Dependencies (available everywhere):
```lua
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local state = require('neotex.plugins.tools.himalaya.core.state')
local events = require('neotex.plugins.tools.himalaya.core.events')
```

#### Domain-Specific Dependencies:
```lua
-- UI modules
local ui = require('neotex.plugins.tools.himalaya.ui')

-- Utilities
local utils = require('neotex.plugins.tools.himalaya.utils')

-- Configuration
local config = require('neotex.plugins.tools.himalaya.config')
```

### Dependency Injection

**Before** (tight coupling):
```lua
-- In utils/email.lua
local config = require('...config')
local state = require('...state')

function format_email(email)
  local account = config.get_current_account()
  -- ...
end
```

**After** (dependency injection):
```lua
-- In utils/email.lua
function format_email(email, account, options)
  -- Pure function, easily testable
end

-- In caller
local account = config.get_current_account()
local formatted = utils.email.format_email(email, account, options)
```

## Migration Strategy

### Phase 1: Create New Directory Structure
1. Create new directories: `config/`, `data/`, `utils/`
2. Add `init.lua` files for clean exports
3. Ensure all tests still pass

### Phase 2: Split Oversized Files
1. **utils.lua** → 6 focused modules
2. **ui/main.lua** → 2 focused modules  
3. **core/config.lua** → 6 configuration modules
4. **core/scheduler.lua** → refined scheduler module
5. **core/search.lua** → moved to data/search.lua

### Phase 3: Move Files to New Locations
1. Move configuration modules to `config/`
2. Move data operations to `data/`
3. Move utilities to `utils/`
4. Update all import statements

### Phase 4: Dependency Cleanup
1. Update import statements throughout codebase
2. Implement dependency injection patterns
3. Remove circular dependencies
4. Add integration tests

### Phase 5: Verification & Testing
1. Run full test suite
2. Verify all functionality preserved
3. Check performance impact
4. Update documentation

## Benefits of New Architecture

### 📈 **Maintainability**
- **Focused modules**: Each file has single, clear responsibility
- **Predictable locations**: Related functionality grouped logically
- **Reasonable sizes**: No file >400 lines, easy to understand

### 🧪 **Testability**  
- **Pure functions**: Utilities accept parameters instead of global state
- **Dependency injection**: Easy to mock dependencies in tests
- **Isolated modules**: Test individual components without side effects

### 👥 **Developer Experience**
- **Easy navigation**: Know exactly where to find specific functionality
- **Clear interfaces**: Well-defined module boundaries and exports
- **Reduced complexity**: No overwhelming files or directories

### 🚀 **Performance**
- **Lazy loading**: Load only needed modules
- **Reduced memory**: Smaller modules loaded on demand
- **Better caching**: More granular dependency tracking

### 🔧 **Extensibility**
- **Plugin architecture**: Easy to add new features
- **Clean interfaces**: Well-defined extension points
- **Modular design**: Features can be developed independently

## File Organization Examples

### Example: utils/ Module Structure
```lua
-- utils/init.lua
return {
  string = require('neotex.plugins.tools.himalaya.utils.string'),
  email = require('neotex.plugins.tools.himalaya.utils.email'),
  cli = require('neotex.plugins.tools.himalaya.utils.cli'),
  file = require('neotex.plugins.tools.himalaya.utils.file'),
  async = require('neotex.plugins.tools.himalaya.utils.async'),
}

-- Usage in other modules:
local utils = require('neotex.plugins.tools.himalaya.utils')
local formatted = utils.string.truncate(text, 50)
local email_valid = utils.email.validate(address)
```

### Example: config/ Module Structure
```lua
-- config/init.lua  
local config = {
  accounts = require('neotex.plugins.tools.himalaya.config.accounts'),
  folders = require('neotex.plugins.tools.himalaya.config.folders'),
  oauth = require('neotex.plugins.tools.himalaya.config.oauth'),
  ui = require('neotex.plugins.tools.himalaya.config.ui'),
  validation = require('neotex.plugins.tools.himalaya.config.validation'),
}

-- Convenience methods
function config.get_current_account()
  return config.accounts.get_current()
end

return config
```

## Testing Strategy

### Unit Testing Structure
```
test/
├── unit/
│   ├── utils/              # Test each utils module
│   ├── config/             # Test configuration modules  
│   ├── data/               # Test data operations
│   └── ui/                 # Test UI components
├── integration/            # Cross-module integration tests
├── performance/            # Performance regression tests  
└── fixtures/               # Test data and mocks
```

### Module Testing Example
```lua
-- test/unit/utils/test_string.lua
local string_utils = require('neotex.plugins.tools.himalaya.utils.string')

describe('string utilities', function()
  it('truncates long strings', function()
    local result = string_utils.truncate('very long string', 10)
    assert.equals('very lo...', result)
  end)
  
  it('preserves short strings', function()
    local result = string_utils.truncate('short', 10) 
    assert.equals('short', result)
  end)
end)
```

## Conclusion

This architectural redesign transforms the Himalaya plugin from a functional but monolithic codebase into an elegant, maintainable, and extensible email client. By following clear size limits and organizational principles, we create a codebase that will scale gracefully and remain pleasant to work with.

### Key Metrics Achieved:
- ✅ **Max 8 files per directory** (improved navigation)
- ✅ **Max 400 lines per file** (improved readability)  
- ✅ **Clear separation of concerns** (improved maintainability)
- ✅ **Reduced circular dependencies** (improved testability)
- ✅ **Logical functionality grouping** (improved developer experience)

The result is a professional-grade email client architecture ready for long-term development and community contribution.