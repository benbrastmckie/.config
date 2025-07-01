# Himalaya Plugin - User-Facing Commands Analysis

## Overview
This document analyzes all user-facing commands in the Himalaya email plugin, documenting their functionality, dependencies, and potential breaking points during refactoring.

## Command List

### Main Commands

#### 1. `:Himalaya [folder]`
- **Purpose**: Open Himalaya email list
- **Function**: `ui.show_email_list(args)`
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.ui` - Main UI module
  - `neotex.plugins.tools.himalaya.utils` - For folder completion
- **Completion**: Returns available folders via `utils.get_folders()`
- **Potential Break Points**:
  - Changes to UI module structure
  - Changes to utils.get_folders() API
  - Email list display logic

#### 2. `:HimalayaToggle`
- **Purpose**: Toggle Himalaya sidebar open/closed
- **Function**: Checks for existing window with 'himalaya-list' filetype and toggles
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.ui` - For show_email_list()
  - `neotex.util.notifications` - For user feedback
  - Window management (vim.api.nvim_list_wins)
- **Potential Break Points**:
  - Changes to filetype naming ('himalaya-list')
  - Window detection logic
  - UI module show_email_list() method

#### 3. `:HimalayaWrite [recipient]`
- **Purpose**: Compose new email
- **Function**: `ui.compose_email(args)`
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.ui` - For compose functionality
- **Potential Break Points**:
  - Compose UI implementation
  - Email buffer creation logic

### Email Compose Commands

#### 4. `:HimalayaSend`
- **Purpose**: Send current email from compose buffer
- **Function**: Creates confirmation dialog, then calls `main.send_current_email()`
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.ui.main` - For send functionality
  - `neotex.util.notifications` - For user feedback
  - Floating window API for confirmation dialog
- **Potential Break Points**:
  - main.send_current_email() implementation
  - Confirmation dialog structure
  - Buffer detection for current email

#### 5. `:HimalayaSaveDraft`
- **Purpose**: Save current email as draft and close
- **Function**: `main.close_and_save_draft()`
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.ui.main` - For draft saving
- **Potential Break Points**:
  - Draft saving logic
  - Buffer management

#### 6. `:HimalayaDiscard`
- **Purpose**: Discard current email without saving
- **Function**: Creates confirmation dialog, then calls `main.close_without_saving()`
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.ui.main` - For buffer closing
  - `neotex.util.notifications` - For user feedback
  - Floating window API for confirmation dialog
- **Potential Break Points**:
  - Buffer cleanup logic
  - State management for discarded emails

### Sync Commands

#### 7. `:HimalayaFastCheck`
- **Purpose**: Fast check using Himalaya's IMAP mode
- **Function**: Complex flow using mbsync.himalaya_fast_check()
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.sync.mbsync` - For fast check
  - `neotex.plugins.tools.himalaya.sync.manager` - For state management
  - `neotex.plugins.tools.himalaya.core.config` - For account info
  - `neotex.plugins.tools.himalaya.ui.state` - For UI state
  - `neotex.util.notifications` - For user feedback
- **Features**:
  - OAuth auto-refresh support
  - Debug mode support
  - Interactive prompt for downloading new emails
  - Integration with sync manager for state tracking
- **Potential Break Points**:
  - OAuth refresh logic
  - Sync manager state tracking
  - IMAP check implementation
  - Account configuration changes

#### 8. `:HimalayaSyncInbox`
- **Purpose**: Sync inbox only
- **Function**: Uses mbsync.sync() with inbox channel
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.sync.mbsync` - For sync operation
  - `neotex.plugins.tools.himalaya.sync.manager` - For state management
  - `neotex.plugins.tools.himalaya.core.config` - For account config
  - `neotex.plugins.tools.himalaya.ui` - For refresh and progress
  - `neotex.plugins.tools.himalaya.utils` - For cache clearing
- **Features**:
  - Progress callback support
  - Auto-refresh timer for sidebar
  - Cache clearing on success
  - Error handling and notifications
- **Potential Break Points**:
  - Channel configuration (mbsync.inbox_channel)
  - Progress callback API
  - Timer management
  - Cache invalidation

#### 9. `:HimalayaSyncFull`
- **Purpose**: Sync all folders
- **Function**: Same as SyncInbox but with all_channel
- **Dependencies**: Same as HimalayaSyncInbox
- **Potential Break Points**: Same as HimalayaSyncInbox

#### 10. `:HimalayaCancelSync`
- **Purpose**: Cancel all sync processes
- **Function**: Kills all mbsync processes and cleans up
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.sync.mbsync` - For stop()
  - `neotex.plugins.tools.himalaya.sync.lock` - For lock cleanup
  - `neotex.plugins.tools.himalaya.ui` - For UI refresh
  - System process management (pgrep, kill)
- **Features**:
  - Kills both internal and external mbsync processes
  - Cleans up stale locks
  - Refreshes UI state
- **Potential Break Points**:
  - Process detection logic
  - Lock cleanup timing
  - UI refresh coordination

### Setup Commands

#### 11. `:HimalayaSetup`
- **Purpose**: Run setup wizard
- **Function**: `wizard.run()`
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.setup.wizard` - Setup wizard
- **Potential Break Points**:
  - Wizard flow changes
  - Configuration structure

#### 12. `:HimalayaHealth`
- **Purpose**: Show health check report
- **Function**: `health.show_report()`
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.setup.health` - Health checks
- **Potential Break Points**:
  - Health check implementation
  - Report format

#### 13. `:HimalayaFixCommon`
- **Purpose**: Fix common issues automatically
- **Function**: `health.fix_common_issues()`
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.setup.health` - Fix logic
- **Potential Break Points**:
  - Fix implementation details
  - Issue detection logic

### OAuth Commands

#### 14. `:HimalayaRefreshOAuth`
- **Purpose**: Refresh OAuth token
- **Function**: `oauth.refresh()`
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.sync.oauth` - OAuth module
- **Potential Break Points**:
  - OAuth implementation
  - Token storage

#### 15. `:HimalayaOAuthRefresh`
- **Purpose**: Manually refresh OAuth token with feedback
- **Function**: `oauth.refresh()` with callback
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.sync.oauth` - OAuth module
  - `neotex.util.notifications` - For user feedback
- **Potential Break Points**:
  - OAuth callback API
  - Error message formatting

### Maintenance Commands

#### 16. `:HimalayaCleanup`
- **Purpose**: Clean up processes and locks
- **Function**: Stops syncs and cleans locks
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.sync.mbsync` - For stop()
  - `neotex.plugins.tools.himalaya.sync.lock` - For cleanup
  - `neotex.util.notifications` - For feedback
- **Potential Break Points**:
  - Process management
  - Lock file handling

#### 17. `:HimalayaFixMaildir`
- **Purpose**: Fix UIDVALIDITY files in maildir
- **Function**: `wizard.fix_uidvalidity_files()`
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.setup.wizard` - Fix function
  - `neotex.plugins.tools.himalaya.core.config` - For maildir path
- **Potential Break Points**:
  - Maildir structure assumptions
  - UIDVALIDITY file format

#### 18. `:HimalayaMigrate`
- **Purpose**: Migrate from old plugin version
- **Function**: `migration.migrate_from_old()`
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.setup.migration` - Migration logic
- **Potential Break Points**:
  - Old configuration detection
  - Migration path logic

### Debug Commands

#### 19. `:HimalayaDebug`
- **Purpose**: Show debug information in floating window
- **Function**: Collects system, config, sync, OAuth status
- **Dependencies**:
  - Multiple core modules for status collection
  - Floating window API
- **Features**:
  - System info (platform, nvim version)
  - Configuration status
  - Sync state details
  - Binary availability checks
  - OAuth status
- **Potential Break Points**:
  - Status collection APIs
  - Window display logic

#### 20. `:HimalayaDebugSyncState`
- **Purpose**: Debug sync state values
- **Function**: Prints detailed sync state to messages
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.core.state` - State access
  - `neotex.plugins.tools.himalaya.sync.mbsync` - Status
  - `neotex.plugins.tools.himalaya.ui.sidebar` - Sidebar state
  - `neotex.plugins.tools.himalaya.ui.main` - Sync status line
- **Potential Break Points**:
  - State structure changes
  - Status API changes

#### 21. `:HimalayaSyncInfo`
- **Purpose**: Show detailed sync status in floating window
- **Function**: Comprehensive sync information display
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.sync.manager` - Sync info
  - `neotex.plugins.tools.himalaya.sync.mbsync` - Process status
  - `neotex.plugins.tools.himalaya.sync.lock` - Lock status
  - System process inspection (pgrep, ps)
- **Features**:
  - Current sync details
  - Sync history
  - Process information
  - Lock status
  - Refresh with 'r' key
- **Potential Break Points**:
  - Sync manager API
  - Process detection logic
  - History tracking

### UI Commands

#### 22. `:HimalayaRestore`
- **Purpose**: Restore previous session
- **Function**: `ui.prompt_session_restore()`
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.ui` - Session management
- **Potential Break Points**:
  - Session storage format
  - Restore logic

#### 23. `:HimalayaSyncStatus`
- **Purpose**: Show sync status
- **Function**: Quick status check via mbsync.get_status()
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.sync.mbsync` - Status API
  - `neotex.util.notifications` - For feedback
- **Potential Break Points**:
  - Status API structure

#### 24. `:HimalayaRefresh`
- **Purpose**: Refresh email sidebar
- **Function**: `ui.refresh_email_list()`
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.ui` - Refresh logic
- **Potential Break Points**:
  - Buffer detection
  - Refresh implementation

### Placeholder Commands (Not Implemented)

#### 25. `:HimalayaFolder`
- **Purpose**: Change folder
- **Status**: TODO - Shows "not implemented" message

#### 26. `:HimalayaAccounts`
- **Purpose**: Switch account
- **Status**: TODO - Shows "not implemented" message

#### 27. `:HimalayaTrash`
- **Purpose**: View trash
- **Status**: TODO - Shows "not implemented" message

#### 28. `:HimalayaTrashStats`
- **Purpose**: Show trash statistics
- **Status**: TODO - Shows "not implemented" message

### Test/Debug Commands

#### 29. `:HimalayaTestNotify`
- **Purpose**: Test notifications
- **Function**: Sends test notifications of all types
- **Dependencies**:
  - `neotex.util.notifications` - All notification types

#### 30. `:HimalayaDebugJson`
- **Purpose**: Debug Himalaya JSON parsing
- **Function**: Tests folder list and email list JSON parsing
- **Dependencies**:
  - `neotex.plugins.tools.himalaya.utils` - For himalaya commands
  - `neotex.plugins.tools.himalaya.core.logger` - Debug logging
- **Potential Break Points**:
  - JSON parsing logic
  - Command execution

#### 31. `:HimalayaRawTest [args]`
- **Purpose**: Test raw Himalaya command output
- **Function**: Executes himalaya command and shows raw output
- **Dependencies**:
  - Direct himalaya binary execution
  - JSON parsing
- **Features**:
  - Shows raw command output
  - Tests JSON parsing
  - Opens results in split window

#### 32. `:HimalayaBackupAndFresh`
- **Purpose**: Backup and fresh start wizard
- **Function**: 3-step wizard for backup/delete/recreate
- **Dependencies**:
  - Multiple modules for state reset
  - File system operations
  - UI cleanup
- **Features**:
  - Calculates email count and size
  - Creates timestamped backups
  - Resets all plugin state
  - Recreates maildir structure
  - Optional setup wizard launch
- **Potential Break Points**:
  - State reset completeness
  - Maildir structure assumptions
  - Module initialization order

## Critical Dependencies

### Core Modules
1. **config** - Account and plugin configuration
2. **state** - Global state management
3. **utils** - Utility functions and caching

### UI Modules
1. **ui** - Main UI orchestration
2. **ui.main** - Buffer management and actions
3. **ui.sidebar** - Sidebar display
4. **ui.state** - UI-specific state
5. **ui.notifications** - User feedback

### Sync Modules
1. **sync.mbsync** - Mbsync process management
2. **sync.manager** - Unified sync state management
3. **sync.oauth** - OAuth token handling
4. **sync.lock** - Lock file management

### Setup Modules
1. **setup.wizard** - Configuration wizard
2. **setup.health** - Health checks
3. **setup.migration** - Version migration

## Refactoring Considerations

### High-Risk Areas
1. **State Management** - Many commands depend on consistent state
2. **Process Management** - Sync commands rely on process control
3. **UI Buffer Management** - Commands assume specific buffer structures
4. **Configuration Structure** - Account configuration format is critical
5. **OAuth Flow** - Token refresh must work reliably

### Safe Refactoring Targets
1. **Notification Messages** - Can be updated without breaking functionality
2. **Debug Commands** - Used for troubleshooting, not core functionality
3. **Floating Window Styling** - Visual changes won't break commands
4. **Error Message Formatting** - Can be improved without API changes

### Testing Requirements
1. **Command Existence** - All commands must remain available
2. **Argument Handling** - Optional arguments must work
3. **Completion Functions** - Tab completion must function
4. **Error States** - Commands must handle missing config gracefully
5. **State Consistency** - Commands must maintain valid state

## Usage Patterns

### Common Workflows
1. **Email Reading**: HimalayaToggle → Navigate → Read
2. **Email Composing**: HimalayaWrite → Edit → HimalayaSend
3. **Syncing**: HimalayaFastCheck → HimalayaSyncInbox
4. **Troubleshooting**: HimalayaHealth → HimalayaDebug → HimalayaFixCommon

### Keybinding Integration
The plugin provides keymaps via `M.get_keymaps()` for which-key integration:
- `<leader>m` - Mail prefix
- Various subcommands for common operations

### Session Management
- Commands support session save/restore
- State persistence across nvim restarts
- Graceful handling of incomplete operations