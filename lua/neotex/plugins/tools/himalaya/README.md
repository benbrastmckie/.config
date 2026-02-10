# Himalaya Email Plugin

A comprehensive, modular email client integration for Neovim using the Himalaya CLI tool with clean architecture and unified state management.

## Purpose

This plugin provides a full-featured email interface within Neovim, supporting:
- **Email Management**: Reading, composing, sending, and organizing emails
- **Multiple Providers**: Gmail (OAuth2) and Protonmail (via Bridge) with dual-account support
- **Smart Synchronization**: Full mbsync integration with progress tracking
- **Unified Notifications**: Integrated with Neovim's notification system
- **Session Persistence**: State management across Neovim sessions

## Architecture

The plugin follows a clean layered architecture:
- **Core Layer**: Configuration, commands, state, logging (no external dependencies)
- **Service Layer**: Sync management, utilities, OAuth handling
- **UI Layer**: Modular interface components (list, viewer, composer)
- **Setup Layer**: Installation wizard, health checks, migrations

## Directory Structure

### Core Modules
- **init.lua** - Plugin entry point and command registration
- **utils.lua** - Himalaya CLI integration and email operation utilities

### Subdirectories

- [core/](core/README.md) - Core functionality (commands, config, state, logging)
- [sync/](sync/README.md) - Email synchronization system (manager, mbsync, oauth, locking)
- [ui/](ui/README.md) - Modular user interface components 
- [setup/](setup/README.md) - Setup wizard, health checks, and migrations
- [scripts/](scripts/README.md) - OAuth token management scripts
- [spec/](spec/README.md) - Planning and feature specifications
- [docs/](docs/README.md) - Architecture, testing, and technical documentation

## Key Features

### Email Operations
- **Sidebar Interface**: Neo-tree style email browsing with real-time sync status
- **Modular UI**: Separate components for email list, viewing, and composition
- **Batch Operations**: Multi-select for delete, archive, and spam operations
- **Smart Actions**: Context-aware delete (move to trash vs permanent)

### Synchronization
- **Unified Sync Management**: Single coordinator for all sync operations
- **Automatic Sync**: Keep inbox synced every 15 minutes (starts 2s after Neovim)
- **Progress Tracking**: Real-time progress updates with elapsed time
- **Error Recovery**: Automatic UIDVALIDITY conflict resolution
- **Process Locking**: Prevents concurrent sync operations

### Account Management
- **Multi-Account Support**: Switch between Gmail and Protonmail (Logos) accounts
- **Multiple Account Views**: Unified inbox, split, and tabbed views for multiple accounts
- **OAuth Integration**: Automatic token refresh for Gmail with fallback scripts
- **Protonmail Bridge**: Local IMAP/SMTP via Protonmail Bridge for Logos account
- **Configuration Wizard**: Guided setup for new accounts

### Current Accounts
| Account | Email | Authentication | Backend |
|---------|-------|----------------|---------|
| gmail | benbrastmckie@gmail.com | OAuth2 | Maildir + SMTP |
| logos | benjamin@logos-labs.ai | Protonmail Bridge | Maildir + SMTP |

### State Management
- **Unified State**: Single source of truth for all plugin state
- **Session Persistence**: Remembers folders, selections, and window state
- **Smart Restoration**: Optional session restoration with user confirmation

## Commands

### Main Interface
- `:Himalaya [folder]` - Open email list (with optional folder)
- `:HimalayaToggle` - Toggle email sidebar
- `:HimalayaWrite [address]` - Compose new email

### Email Operations  
- `:HimalayaSend` - Send current email
- `:HimalayaSaveDraft` - Save email as draft
- `:HimalayaDiscard` - Discard current email

### Synchronization
- `:HimalayaSyncInbox` - Sync inbox only  
- `:HimalayaSyncFull` - Full synchronization
- `:HimalayaCancelSync` - Cancel running sync

### Automatic Synchronization
- `:HimalayaAutoSyncToggle` - Toggle automatic inbox syncing (every 15 minutes)

### Multiple Account Views
- `:HimalayaUnifiedInbox` - Show unified inbox for all accounts
- `:HimalayaSplitView` - Show accounts in split windows
- `:HimalayaTabbedView` - Show accounts in tabs
- `:HimalayaToggleView` - Toggle between view modes
- `:HimalayaAccountStatus` - Show account configuration status

### Setup and Maintenance
- `:HimalayaSetup` - Run setup wizard
- `:HimalayaHealth` - Check system health
- `:HimalayaFixUID` - Fix UIDVALIDITY issues

### Debugging
- `:HimalayaSyncInfo` - Show detailed sync status (includes auto-sync information)
- `:HimalayaDebug` - Show debug information
- `:HimalayaDebugJson` - Test JSON parsing
- `:HimalayaTest` - Run tests with picker interface
- `:checkhealth himalaya` - Neovim health check

<!-- TODO: Add command auto-completion for folders and accounts -->
<!-- TODO: Implement command help system with usage examples -->

## Configuration

Basic configuration via lazy.nvim:

```lua
{
  'himalaya-email-plugin',
  dependencies = { 'notification-system' },
  config = function()
    require('neotex.plugins.tools.himalaya').setup({
      accounts = {
        gmail = {
          name = "Personal Gmail",
          email = "user@gmail.com",
          maildir_path = "~/Mail/gmail"
        }
      },
      ui = {
        auto_sync_enabled = true,        -- Enable automatic inbox syncing
        auto_sync_interval = 15 * 60,    -- Sync every 15 minutes
        auto_sync_startup_delay = 2,     -- Start 2 seconds after Neovim
        multi_account = {
          default_mode = 'focused',      -- Start mode: 'focused', 'unified', 'split', 'tabbed'
          show_account_colors = true,    -- Enable account color coding
        },
      },
      -- Keymaps are defined in which-key.lua under <leader>m
      -- See which-key.lua for complete keybinding reference
    })
  end
}
```

## Keybindings

All keybindings are defined under `<leader>m` and configured in `which-key.lua`:

### Core Operations
- `<leader>mm` - Toggle email sidebar
- `<leader>ms` - Sync inbox  
- `<leader>mS` - Full sync (all folders)
- `<leader>mw` - Write/compose new email
- `<leader>mf` - Change folder
- `<leader>ma` - Switch account

### Auto-Sync Controls
- `<leader>mt` - Toggle auto-sync (every 15 minutes)

### Email Management (Compose Buffer Only)
These keybindings are only visible when in a compose buffer:
- `<leader>mc` - Compose subgroup
- `<leader>mce` - Send email
- `<leader>mcd` - Save draft
- `<leader>mcD` - Discard email
- `<leader>mcq` - Quit (discard)

### System & Debugging
- `<leader>mh` - Health check
- `<leader>mi` - Sync status (includes auto-sync information)
- `<leader>mx` - Cancel running syncs
- `<leader>mW` - Setup wizard

See `which-key.lua` for complete keybinding reference and buffer-specific mappings.

## Requirements

### Essential Dependencies
- **Himalaya CLI** - Core email operations (`himalaya --version`)
- **mbsync** - Full email synchronization (`mbsync --version`)

### OAuth Requirements (Gmail)
- Gmail OAuth2 credentials (client_id, client_secret)
- OAuth refresh scripts (included in scripts/)

### Platform Support
- **Linux**: Full support with Secret Service or file-based storage
- **macOS**: Full support with Keychain integration
- **Windows**: Basic support with Credential Manager
- **NixOS**: Special configuration may be required

<!-- TODO: Add installation verification script -->
<!-- TODO: Create platform-specific setup guides -->

## Getting Started

1. **Install Dependencies**: Ensure Himalaya CLI and mbsync are available
2. **Run Setup**: Execute `:HimalayaSetup` for guided configuration
3. **Configure OAuth**: Follow wizard prompts for Gmail authentication
4. **Test Setup**: Run `:HimalayaHealth` to verify configuration
5. **Start Using**: Open email interface with `:Himalaya`

## Troubleshooting

### Common Issues
- **OAuth token expired**: Automatic refresh should handle this
- **UIDVALIDITY changed**: Use `:HimalayaFixUID` to resolve
- **Sync conflicts**: Check `:HimalayaHealth` for diagnostics
- **Missing dependencies**: Verify installation with `:checkhealth himalaya`

### Debug Mode
Enable debug notifications with `<leader>ad` to see detailed operation logs.

## Testing

### Running Tests
The plugin includes a comprehensive testing infrastructure:

- **Run all tests**: `:HimalayaTest` then select "Run All Tests"
- **Run category tests**: `:HimalayaTest` then select category (commands, features, integration, performance)
- **Run specific test**: `:HimalayaTest test_name`
- **Test with picker**: `:HimalayaTest` opens interactive test picker

### Test Organization
Tests are organized in `scripts/` directory:
- `commands/` - Command-specific tests
- `features/` - Feature-specific tests (scheduler, search, templates)
- `integration/` - Full workflow integration tests
- `performance/` - Performance and memory tests
- `utils/` - Test framework and mock data utilities

### Writing Tests
Tests use the included test framework:
```lua
local framework = require('neotex.plugins.tools.himalaya.scripts.utils.test_framework')
local assert = framework.assert

local tests = {}
table.insert(tests, framework.create_test('test_name', function()
  -- Test code here
  assert.equals(actual, expected, "Error message")
end))

_G.himalaya_test = framework.create_suite('Suite Name', tests)
```

## Testing Guides

- [Multiple Account Views Testing](docs/MULTIPLE_ACCOUNT_VIEWS.md) - Comprehensive guide for testing multi-account features

## Future Development

See [spec/README.md](spec/README.md) for implementation roadmap:
- Phase 10: OAuth 2.0 implementation and security enhancements
- Optional: PGP/GPG encryption support

### Future Enhancements (Not Planned)
- Window management improvements (see spec/WINDOW_MANAGEMENT_SPEC.md)
- Email rules and filters
- Integration features (calendar, tasks)

## Navigation
- [< Neovim Tools](../README.md)
- [Architecture Documentation](docs/ARCHITECTURE.md)
- [Development Specifications](spec/README.md)