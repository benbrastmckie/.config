# Himalaya Email Client for NeoVim

A streamlined email management system that integrates the Himalaya CLI email client into NeoVim with native IMAP sync, automatic sidebar updates, and seamless OAuth2 authentication.

## Features

### 📧 **Email Management**
- **Bidirectional sync** - mbsync integration for true Gmail ↔ Local synchronization
- **Automatic OAuth refresh** - Seamless Gmail authentication via NixOS configuration
- **Real-time updates** - Sidebar automatically refreshes every 60 seconds when open
- **Offline access** - Local maildir storage for instant access

### 🔍 **Navigation & Interface**
- **Persistent sidebar** - Email list stays open during operations
- **Smart pagination** - Navigate through emails with `gn`/`gp`
- **Folder browsing** - Quick folder switching with auto-detection
- **Session persistence** - Remembers current folder and selection across restarts

### ✉️ **Email Operations**
- **Compose/Reply/Forward** - Rich composition interface with templates
- **Local trash system** - Delete emails to local trash with full recovery
- **Smart folder detection** - Auto-detects Gmail folders (`[Gmail].All Mail`, etc.)
- **Background operations** - Non-blocking email operations with visual feedback

### ⚡ **Performance & Automation**
- **Auto-refresh** - Sidebar updates automatically every 60 seconds
- **Background sync** - Silent email fetching without user notifications
- **Smart caching** - Efficient email list management
- **OAuth automation** - Automatic token refresh on sync failure and via systemd timer
- **External sync detection** - Shows when sync is running in another Neovim instance
- **Automatic retry** - Retries sync after OAuth token refresh

## Usage

### Global Keymaps

| Keymap | Command | Description |
|--------|---------|-------------|
| `<leader>mo` | `:Himalaya` | Open email list in sidebar |
| `<leader>ms` | `:HimalayaSyncInbox` | Quick inbox sync |
| `<leader>mS` | `:HimalayaSyncFull` | Full account sync |
| `<leader>mk` | `:HimalayaCancelSync` | Cancel current sync |
| `<leader>mw` | `:HimalayaWrite` | Compose new email |
| `<leader>mX` | `:HimalayaBackupAndFresh` | Backup mail & start fresh |

### Email List Navigation (Sidebar)

| Keymap | Action | Description |
|--------|--------|-------------|
| `<CR>` | Read | Open email in floating window |
| `gr` | Reply | Reply to selected email |
| `gR` | Reply All | Reply to all recipients |
| `gf` | Forward | Forward selected email |
| `gD` | Delete | Delete to local trash |
| `gA` | Archive | Archive email (auto-detects folder) |
| `gS` | Spam | Mark as spam (auto-detects folder) |
| `gm` | Folder | Change folder |
| `gn` / `gp` | Page | Next/previous page |
| `r` | Refresh | Manual refresh |
| `q` | Close | Close sidebar |

### Email Reading (Floating Window)

| Keymap | Action | Description |
|--------|--------|-------------|
| `gr` | Reply | Reply to current email |
| `gR` | Reply All | Reply to all recipients |
| `gf` | Forward | Forward current email |
| `gD` | Delete | Delete current email |
| `gl` | Links | Open link under cursor |
| `q` | Close | Close and return to sidebar |

## Commands

### Streamlined Sync System

- **`:HimalayaSyncInbox`** - Quick inbox-only sync (60 second timeout)
- **`:HimalayaSyncFull`** - Full account sync (essential folders only)
- **`:HimalayaCancelSync`** - Cancel current sync operation
- **`:HimalayaCleanup`** - Emergency cleanup - kill processes and reset state
- **`:HimalayaSyncStatus`** - Show current sync status

When a sync is already running in another Neovim instance, the sidebar will display:
- **`🔄 Syncing: External (1 process)`** - Indicates external sync is active
- New syncs are prevented until the external sync completes
- This prevents email duplication and sync conflicts

### Core Email Operations

- **`:Himalaya [folder]`** - Open email sidebar
- **`:HimalayaWrite [email]`** - Compose new email
- **`:HimalayaReply[!] <id>`** - Reply (use `!` for reply-all)
- **`:HimalayaForward <id>`** - Forward email
- **`:HimalayaDelete <id>`** - Delete email (to trash)
- **`:HimalayaSearch <query>`** - Search emails
- **`:HimalayaFolder`** - Browse folders
- **`:HimalayaAccounts`** - Switch accounts

### Session Management

- **`:HimalayaRestore[!]`** - Restore previous session (use `!` to skip prompt)

### Trash Management

- **`:HimalayaTrash`** - Visual trash browser
- **`:HimalayaTrashStats`** - Trash statistics
- **`:HimalayaTrashRestore <id>`** - Restore deleted email
- **`:HimalayaTrashPurge <id>`** - Permanently delete

### Setup & Authentication

- **`:HimalayaSetupMaildir`** - Set up maildir++ structure for new accounts
- **`:HimalayaBackupAndFresh`** - Backup existing mail directory and start fresh
- **`:HimalayaRefreshOAuth`** - Manual OAuth token refresh
- **`:HimalayaOAuthDiagnostics`** - Diagnose OAuth authentication issues
- **`:HimalayaTestOAuth [type]`** - Test OAuth refresh mechanisms:
  - `status` - Check current token status and refresh schedule
  - `service` - Test systemd refresh service
  - `expired` - Simulate expired token to test auto-refresh
  - `timeout` - Show timeout detection logic
- **`:HimalayaTestRestore`** - Restore token after testing

## Architecture

### Maildir++ Sync System
```
Gmail IMAP <--[mbsync/Maildir++]<--[OAuth2]--> Local Maildir++ <--[Himalaya CLI]--> NeoVim Interface
     |                                              |                                      |
  Server State                          ~/Mail/Gmail/{cur,new,.Sent}           Sidebar + Windows
```

### Maildir++ Structure
```
~/Mail/Gmail/
├── cur/           # Read inbox emails
├── new/           # Unread inbox emails  
├── tmp/           # Temporary files
├── .Sent/         # Sent emails (dot prefix)
├── .Drafts/       # Draft emails (dot prefix)
├── .Trash/        # Trash emails (dot prefix)
└── .uidvalidity   # Maildir metadata
```

### Components
- **mbsync** - Bidirectional IMAP sync with Maildir++ format and OAuth2
- **Himalaya CLI** - Native Maildir++ operations and email interface
- **Streamlined Sync** - Atomic process management with timeouts
- **OAuth Integration** - Automatic token management via NixOS

### Authentication Flow
1. **NixOS home-manager** - Configures mbsync with Maildir++ format and systemd timer
2. **OAuth2 Tokens** - Stored securely via secret-tool keyring
3. **Automatic Refresh** - Two-tier approach:
   - **Proactive**: Systemd timer refreshes token every 45 minutes
   - **Reactive**: Sync automatically refreshes expired tokens and retries
4. **Seamless Operation** - No manual token management required

## First-Time Setup

When you first open Himalaya (`<leader>mo`), if no mail directory exists, you'll be prompted to:

1. **Automatic Maildir Creation** - The system will:
   - Connect to your IMAP server to discover all folders
   - Create a proper maildir++ directory structure
   - Set up folders matching your email labels/folders
   - Configure the directory for use with mbsync and Himalaya

2. **Manual Setup** - If you prefer, you can run `:HimalayaSetupMaildir` at any time

The setup process:
- Detects your IMAP folder structure (works with Gmail, Outlook, etc.)
- Creates proper maildir++ format (INBOX in root, other folders with dot prefix)
- Handles special folders like `[Gmail]/Sent Mail` → `.Gmail.Sent Mail`
- Creates required `cur/`, `new/`, and `tmp/` subdirectories

### Backup and Fresh Start

If you need to start fresh with your email setup, use `<leader>mX` or `:HimalayaBackupAndFresh`:

1. **Shows Current Status** - Displays directory size and email count
2. **Creates Timestamped Backup** - Moves existing mail to `~/Mail/Gmail.backup-YYYYMMDD-HHMMSS`
3. **Cleans All State** - Removes sync state, cache, and lock files
4. **Sets Up Fresh** - Creates new maildir++ structure from scratch

This is useful for:
- Resolving persistent sync issues
- Starting fresh after configuration changes
- Cleaning up after testing
- Recovering from corrupted state

## OAuth2 Token Management

### Automatic Token Refresh

The system handles OAuth token expiration automatically with a two-tier approach:

1. **Proactive Refresh** - A systemd timer refreshes tokens every 45 minutes (before the 1-hour expiration)
2. **Reactive Refresh** - If a sync fails due to expired token:
   - Automatically detects authentication failure or socket timeout
   - Triggers systemd OAuth refresh service
   - Waits for refresh completion
   - Automatically retries the sync with fresh token

No manual intervention is required - expired tokens are handled seamlessly during sync operations.

## Environment Requirements

### Required Environment Variables for OAuth2

For mbsync and OAuth2 authentication to work properly, two environment variables must be set:

1. **SASL_PATH** - Path to SASL plugins (including XOAUTH2)
2. **GMAIL_CLIENT_ID** - OAuth2 client ID for Gmail API access

**Important**: Neovim must be started from an environment where both variables are already set.

#### For NixOS Users
If you're using home-manager with `sessionVariables`, ensure you start Neovim from:
- A terminal that has loaded the session variables
- Not from a desktop launcher that bypasses shell initialization

#### For Non-NixOS Users
Set both variables in your shell configuration (`~/.bashrc`, `~/.zshrc`, etc.):
```bash
export SASL_PATH="/usr/lib/sasl2:/usr/lib64/sasl2:/usr/local/lib/sasl2"
export GMAIL_CLIENT_ID="your-client-id-here"
```

#### Verify Environment Variables
Before starting Neovim, verify both environment variables are set:
```bash
echo $SASL_PATH
# Should output your SASL plugin paths

echo $GMAIL_CLIENT_ID
# Should output your OAuth2 client ID
```

If these variables are not set when Neovim starts:
- **Missing SASL_PATH**: mbsync authentication will hang at "Authenticating with SASL mechanism XOAUTH2..."
- **Missing GMAIL_CLIENT_ID**: OAuth token refresh will fail with "Missing OAuth2 credentials"

## Configuration

### Current Setup (Gmail)

```lua
{
  default_account = 'gmail',
  accounts = {
    gmail = { 
      name = 'Benjamin Brast-McKie', 
      email = 'benbrastmckie@gmail.com' 
    },
  },
  auto_refresh = {
    enabled = true,
    interval_seconds = 60,
    refresh_after_operations = true
  },
  trash = {
    enabled = true,
    directory = "~/Mail/Gmail/.trash",
    retention_days = 30,
    auto_cleanup = true
  },
  external_sync = {
    enabled = true  -- Detect syncs from other Neovim instances
  }
}
```

### Auto-Refresh Settings

```lua
-- Toggle auto-refresh
:HimalayaAutoRefresh toggle

-- Set custom interval (seconds)
:HimalayaAutoRefresh 30   -- 30 seconds
:HimalayaAutoRefresh 120  -- 2 minutes

-- Manual control
:HimalayaAutoRefresh start
:HimalayaAutoRefresh stop
```

### NixOS Maildir++ Configuration

The mbsync and Maildir++ setup is configured via NixOS home-manager:

```nix
# In home.nix
programs.mbsync = {
  enable = true;
  extraConfig = ''
    # Gmail IMAP account with XOAUTH2 support
    IMAPAccount gmail
    Host imap.gmail.com
    Port 993
    User benbrastmckie@gmail.com
    AuthMechs XOAUTH2
    PassCmd "secret-tool lookup service himalaya-cli username gmail-smtp-oauth2-access-token"
    TLSType IMAPS

    # Gmail remote store
    IMAPStore gmail-remote
    Account gmail

    # Gmail local store - MAILDIR++ FORMAT
    MaildirStore gmail-local
    Inbox ~/Mail/Gmail/
    SubFolders Maildir++

    # Inbox channel - emails go to root cur/new directories
    Channel gmail-inbox
    Far :gmail-remote:INBOX
    Near :gmail-local:
    Create Both
    Expunge Both
    SyncState *

    # Subfolders without manual dot prefix (added automatically)
    Channel gmail-sent
    Far :gmail-remote:"[Gmail]/Sent Mail"
    Near :gmail-local:Sent
    Create Both
    Expunge Both
    SyncState *
    
    # Additional channels for Drafts, Trash, etc.
  '';
};
```

## Notification System

Integrates with the unified notification system:

### Categories
- **Email Operations** (always shown): Send, delete, move operations
- **Background Sync** (debug only): Auto-refresh, cache updates
- **OAuth Status** (debug only): Token refresh notifications

### Configuration
```bash
:NotifyDebug himalaya     # Toggle Himalaya debug notifications
:Notifications history    # View recent notifications
```

## File Structure

```
lua/neotex/plugins/tools/himalaya/
├── README.md                 # This documentation  
├── UI.md                     # UI documentation
├── config.lua               # Configuration management
├── commands.lua             # User commands
├── external_sync_simple.lua # External sync detection (simplified)
├── picker.lua               # Telescope integration
├── sidebar.lua              # Email sidebar
├── state.lua                # State management
├── streamlined_sync.lua     # Maildir++ sync system with atomic locking
├── trash_manager.lua        # Local trash system
├── trash_operations.lua     # Trash operations (move, restore, delete)
├── trash_ui.lua             # Trash user interface
├── ui.lua                   # Main email interface
├── utils.lua                # Core Himalaya CLI operations
└── window_stack.lua         # Window management
```

## Troubleshooting

### Quick Diagnostics
1. **`:HimalayaSyncStatus`** - Current sync status and statistics
2. **`himalaya folder list`** - Test Himalaya CLI access to Maildir++
3. **`:HimalayaSyncInbox`** - Test streamlined sync functionality
4. **`:HimalayaCleanup`** - Reset sync state if needed

### Common Issues

**"Mail sync failed"**
- **Cause**: OAuth token expired, network issues, or Gmail server load
- **Solution**: 
  - If OAuth expired: System will auto-refresh and retry (watch for "🔑 Triggering OAuth token refresh...")
  - For other issues: `:HimalayaCancelSync` then `:HimalayaSyncInbox` to retry
  - Check network connection if persistent

**"No such file or directory" error**
- **Cause**: Maildir++ structure not properly initialized  
- **Solution**: `:HimalayaCleanup` followed by `:HimalayaSyncInbox` to rebuild structure

**Sync hanging or timing out**
- **Cause**: Gmail server load or large email volume
- **Solution**: Use `:HimalayaCancelSync` then retry with `:HimalayaSyncInbox` for quick inbox-only sync

**Missing folders in Himalaya**
- **Cause**: Folders not yet synced or created
- **Solution**: Run `:HimalayaSyncFull` to sync all folders, then use `himalaya folder list` to verify

### OAuth Troubleshooting

Check OAuth token status:
```bash
# Run OAuth diagnostics in Neovim
:HimalayaOAuthDiagnostics

# Test OAuth refresh mechanisms
:HimalayaTestOAuth status    # Check current token status
:HimalayaTestOAuth service   # Test refresh service
:HimalayaTestOAuth expired   # Simulate expired token

# Manually trigger OAuth refresh
:HimalayaRefreshOAuth
```

Check system configuration:
```bash
# Verify tokens are stored in keyring
secret-tool lookup service himalaya-cli username gmail-smtp-oauth2-access-token

# Check systemd timer status
systemctl --user status gmail-oauth2-refresh.timer

# View recent refresh logs
journalctl --user -u gmail-oauth2-refresh.service -n 20
```

Verify NixOS configuration:
```bash
# Check mbsync configuration is properly generated
ls -la ~/.mbsyncrc
cat ~/.mbsyncrc | grep "SubFolders Maildir++"
```

### External Sync Detection

**"🔄 Syncing: External (1 process)" in sidebar**
- **Cause**: An mbsync process is running from another Neovim instance
- **Behavior**: New syncs are prevented until external sync completes
- **Solution**: Wait for external sync to finish, or use `killall mbsync` if stuck

This simplified external sync detection prevents conflicts without complex takeover logic.

## Summary

A complete, streamlined email solution featuring:

✅ **Maildir++ Format** - Industry-standard email storage with proper folder hierarchy  
✅ **Streamlined Sync System** - Atomic process management with intelligent timeouts  
✅ **NixOS Integration** - Permanent configuration via home-manager with no cruft  
✅ **OAuth2 Authentication** - Secure token management via system keyring  
✅ **Automatic Token Refresh** - Proactive timer + reactive sync-failure detection  
✅ **Himalaya CLI Integration** - Native maildir operations with folder support  
✅ **Clean Architecture** - No backwards compatibility or legacy code  
✅ **Robust Error Handling** - Emergency cleanup and sync status monitoring
✅ **External Sync Detection** - Prevents conflicts across multiple Neovim instances

The system provides reliable Gmail ↔ Local synchronization using mbsync with Maildir++ format, ensuring compatibility between mbsync and Himalaya CLI while maintaining a clean, maintainable configuration through NixOS home-manager. OAuth token expiration is handled automatically with no manual intervention required.