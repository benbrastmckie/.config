# Himalaya Email Plugin

A comprehensive, modular email client integration for Neovim using the Himalaya CLI tool with clean architecture and unified state management.

## Purpose

This plugin provides a full-featured email interface within Neovim, supporting:
- **Email Management**: Reading, composing, sending, and organizing emails
- **Multiple Providers**: Gmail integration via OAuth2, IMAP support
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
- **Progress Tracking**: Real-time progress updates with elapsed time
- **Error Recovery**: Automatic UIDVALIDITY conflict resolution
- **Process Locking**: Prevents concurrent sync operations

### Account Management
- **Multi-Account Support**: Switch between Gmail, IMAP, and other accounts
- **OAuth Integration**: Automatic token refresh with fallback scripts
- **Configuration Wizard**: Guided setup for new accounts

### State Management
- **Unified State**: Single source of truth for all plugin state
- **Session Persistence**: Remembers folders, selections, and window state
- **Smart Restoration**: Optional session restoration with user confirmation

## Recent Major Refactoring (Phases 1-5 Complete)

The plugin recently underwent comprehensive refactoring:
- ✅ **Phase 1-3**: Modularized UI components (1000+ lines → focused modules)
- ✅ **Phase 4**: Unified state management (removed dual state systems)
- ✅ **Phase 5**: Architecture improvements and notification standardization

**Status**: Core refactoring complete, testing phases pending

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

### Setup and Maintenance
- `:HimalayaSetup` - Run setup wizard
- `:HimalayaHealth` - Check system health
- `:HimalayaFixUID` - Fix UIDVALIDITY issues

### Debugging
- `:HimalayaDebug` - Show debug information
- `:HimalayaDebugJson` - Test JSON parsing
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
      keymaps = {
        toggle = "<leader>mh",
        compose = "<leader>mc"
      }
    })
  end
}
```

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

## Future Development

See [spec/FEATURES_SPEC.md](spec/FEATURES_SPEC.md) for planned enhancements:
- Enhanced UI/UX features (hover preview, buffer composition)
- Advanced email management (attachments, images, local trash)
- Performance optimizations and code quality improvements

## Navigation
- [← Neovim Tools](../README.md)
- [Architecture Documentation](docs/ARCHITECTURE.md)
- [Development Specifications](spec/README.md)