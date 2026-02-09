# Configuration Management

Centralized configuration system for the Himalaya email plugin, providing modular management of accounts, folders, UI preferences, and validation.

## Modules

### init.lua
Unified configuration facade that exports all configuration functionality. Maintains backward compatibility while delegating to specialized modules.

### accounts.lua
Account management and configuration, including email addresses, display names, and account-specific settings.

**Configured Accounts**:
- `gmail` - Primary Gmail account (benbrastmckie@gmail.com) with OAuth2 authentication
- `logos` - Protonmail account (benjamin@logos-labs.ai) via Protonmail Bridge

Both accounts use Maildir backend (synced by mbsync) with SMTP for sending.

### folders.lua
Folder mapping between IMAP and local names, maildir paths, and folder-specific configuration.

### oauth.lua
OAuth settings management including client credentials, refresh commands, and token handling.

### ui.lua
User interface preferences including keybindings, layout settings, and display options. Contains pragmatic UI dependencies for keybinding definitions.

### validation.lua
Configuration validation and migration utilities ensuring settings are correct and compatible.

## Architecture Notes

This directory represents the configuration layer of the Himalaya plugin, extracted from the monolithic `core/config.lua` (1,204 lines) into focused modules during Phase 2 of the architecture refactoring.

### Pragmatic Compromise
The `ui.lua` module contains UI dependencies for keybinding definitions. This is a documented architectural compromise made for user experience and configuration convenience.

## Usage

```lua
-- Import unified config interface
local config = require('neotex.plugins.tools.himalaya.config')

-- Access specific modules if needed
local accounts = require('neotex.plugins.tools.himalaya.config.accounts')
local folders = require('neotex.plugins.tools.himalaya.config.folders')
```

## Navigation
- [← Core Directory](../core/README.md)
- [← Himalaya Plugin](../README.md)