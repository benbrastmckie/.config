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
- **OAuth automation** - Automatic token refresh via systemd timer

## Usage

### Global Keymaps

| Keymap | Command | Description |
|--------|---------|-------------|
| `<leader>mo` | `:Himalaya` | Open email list in sidebar |
| `<leader>ms` | `:HimalayaSyncInbox` | Quick inbox sync |
| `<leader>mS` | `:HimalayaSyncFull` | Full account sync |
| `<leader>mk` | `:HimalayaCancelSync` | Cancel current sync |
| `<leader>mw` | `:HimalayaWrite` | Compose new email |

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

### Core Email Operations

- **`:Himalaya [folder]`** - Open email sidebar
- **`:HimalayaWrite [email]`** - Compose new email
- **`:HimalayaReply[!] <id>`** - Reply (use `!` for reply-all)
- **`:HimalayaForward <id>`** - Forward email
- **`:HimalayaFolder`** - Browse folders

### Trash Management

- **`:HimalayaTrash`** - Visual trash browser
- **`:HimalayaTrashStats`** - Trash statistics
- **`:HimalayaTrashRestore <id>`** - Restore deleted email
- **`:HimalayaTrashPurge <id>`** - Permanently delete

### OAuth & Authentication

- **`:HimalayaRefreshOAuth`** - Manual OAuth token refresh
- **`:HimalayaOAuthStatus`** - Check OAuth status
- **`:HimalayaOAuthTroubleshoot`** - OAuth diagnostics

### Diagnostics

- **`:HimalayaQuickHealthCheck`** - System health overview
- **`:HimalayaFullDiagnostics`** - Comprehensive diagnostics
- **`:HimalayaTestDelete`** - Test delete operations

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
1. **NixOS home-manager** - Configures mbsync with Maildir++ format
2. **OAuth2 Tokens** - Stored securely via secret-tool keyring
3. **Automatic Refresh** - mbsync handles OAuth token refresh automatically
4. **Seamless Operation** - No manual token management required

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
├── himalaya.lua             # Main plugin definition
├── config.lua               # Configuration management
├── commands.lua             # User commands
├── ui.lua                   # Email interface
├── utils.lua                # Core email operations
├── streamlined_sync.lua     # Clean sync system with atomic locking
├── fresh_sync.lua          # Quick testing and fresh maildir creation
├── trash_manager.lua        # Local trash system
├── trash_operations.lua     # Trash operations (move, restore, delete)
└── util/                    # Diagnostic tools
    ├── diagnostics.lua      # Health checks
    ├── gmail_settings.lua   # Gmail configuration
    └── oauth_manager.lua    # OAuth utilities
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
- **Solution**: `:HimalayaCancelSync` then `:HimalayaSyncInbox` to retry, or check network connection

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
# Verify tokens are stored in keyring
secret-tool lookup service himalaya-cli username gmail-smtp-oauth2-access-token

# Test direct mbsync authentication  
mbsync gmail-inbox

# Check mbsync configuration
cat ~/.mbsyncrc | grep -A5 -B5 "XOAUTH2"
```

Verify NixOS configuration:
```bash
# Check mbsync configuration is properly generated
ls -la ~/.mbsyncrc
cat ~/.mbsyncrc | grep "SubFolders Maildir++"
```

## Summary

A complete, streamlined email solution featuring:

✅ **Maildir++ Format** - Industry-standard email storage with proper folder hierarchy  
✅ **Streamlined Sync System** - Atomic process management with intelligent timeouts  
✅ **NixOS Integration** - Permanent configuration via home-manager with no cruft  
✅ **OAuth2 Authentication** - Secure token management via system keyring  
✅ **Himalaya CLI Integration** - Native maildir operations with folder support  
✅ **Clean Architecture** - No backwards compatibility or legacy code  
✅ **Robust Error Handling** - Emergency cleanup and sync status monitoring

The system provides reliable Gmail ↔ Local synchronization using mbsync with Maildir++ format, ensuring compatibility between mbsync and Himalaya CLI while maintaining a clean, maintainable configuration through NixOS home-manager.