# Himalaya Email Integration for NeoVim

A comprehensive email management system integrating the Himalaya CLI email client into NeoVim with automatic OAuth2 authentication, real-time sidebar updates, and native IMAP synchronization.

## Overview

### Current Implementation

The Himalaya email plugin provides a complete email workflow within NeoVim featuring:

- **Native Himalaya sync** using direct IMAP connection (eliminates mbsync dependencies)
- **Automatic OAuth2 management** via NixOS configuration and systemd timer
- **Real-time sidebar updates** with 60-second background refresh intervals
- **Local trash system** with full email recovery capabilities
- **Smart folder detection** for Gmail-specific folder names
- **Seamless authentication** with automatic token refresh

### Architecture

```
Gmail IMAP ←→ Himalaya CLI ←→ NeoVim Interface
     ↓              ↓              ↓
OAuth2 Auth    Local Storage   Sidebar + Windows
     ↓              ↓              ↓
Systemd Timer  ~/Mail/Gmail/   Auto Updates
```

## Key Features

### Email Management
- **Enhanced sync system** - Native Himalaya IMAP operations (no external sync tools)
- **Automatic updates** - Sidebar refreshes every 60 seconds when open
- **OAuth automation** - Seamless token refresh via NixOS systemd configuration
- **Local storage** - Offline email access with instant operations

### User Interface
- **Persistent sidebar** - Email list remains visible during operations
- **Floating windows** - Email reading and composition in modal windows
- **Smart pagination** - Navigate through email pages efficiently
- **Session persistence** - Maintains state across NeoVim restarts

### Email Operations
- **Complete CRUD operations** - Read, compose, reply, forward, delete
- **Local trash system** - Independent trash with full recovery (no IMAP dependency)
- **Smart folder detection** - Auto-detects Gmail folders (`[Gmail].All Mail`, etc.)
- **Background operations** - Non-blocking operations with visual feedback

## Configuration

### NixOS OAuth Setup

Authentication is managed system-wide through NixOS configuration:

```nix
# home.nix
home.sessionVariables = {
  GMAIL_CLIENT_ID = "your-oauth-client-id";
};

systemd.user.services.gmail-oauth2-refresh = {
  Unit = {
    Description = "Refresh Gmail OAuth2 tokens";
    After = [ "graphical-session.target" ];
  };
  Service = {
    Type = "oneshot";
    ExecStart = "${config.home.homeDirectory}/.nix-profile/bin/refresh-gmail-oauth2";
  };
  Install.WantedBy = [ "default.target" ];
};

systemd.user.timers.gmail-oauth2-refresh = {
  Unit.Description = "Timer for Gmail OAuth2 token refresh";
  Timer = {
    OnCalendar = "daily";
    Persistent = true;
  };
  Install.WantedBy = [ "timers.target" ];
};
```

### Plugin Configuration

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

## User Interface

### Global Keymaps

| Keymap | Command | Description |
|--------|---------|-------------|
| `<leader>ml` | `:Himalaya` | Open email sidebar |
| `<leader>ms` | `:HimalayaEnhancedSync` | Enhanced mail sync |
| `<leader>mw` | `:HimalayaWrite` | Compose new email |

### Sidebar Operations

| Keymap | Action | Description |
|--------|--------|-------------|
| `<CR>` | Read | Open email in floating window |
| `gr` / `gR` | Reply | Reply / Reply All |
| `gf` | Forward | Forward email |
| `gD` | Delete | Move to local trash |
| `gA` | Archive | Auto-detect archive folder |
| `gS` | Spam | Auto-detect spam folder |
| `gn` / `gp` | Page | Navigate email pages |
| `r` | Refresh | Manual refresh |

## Commands

### Enhanced Sync System

- **`:HimalayaEnhancedSync`** - Native Himalaya sync with automatic OAuth refresh
- **`:HimalayaQuickSync`** - Quick refresh of current folder view
- **`:HimalayaAutoRefresh [option]`** - Manage automatic updates
  - `toggle` - Enable/disable auto-refresh
  - `start` / `stop` - Manual control
  - `[seconds]` - Set custom interval

### OAuth Management

- **`:HimalayaRefreshOAuth`** - Manual OAuth token refresh
- **`:HimalayaOAuthStatus`** - Check authentication status
- **`:HimalayaOAuthTroubleshoot`** - Comprehensive OAuth diagnostics

### Diagnostics

- **`:HimalayaQuickHealthCheck`** - System health overview
- **`:HimalayaFullDiagnostics`** - Complete diagnostic suite
- **`:HimalayaTestDelete`** - Test delete operation functionality

## Technical Implementation

### Sync System

The enhanced sync system eliminates mbsync complications by using Himalaya's native IMAP capabilities:

```lua
-- Native sync using Himalaya CLI
function M.enhanced_sync()
  local cmd = string.format('himalaya envelope list --account=%s --folder=INBOX', account)
  -- Execute via jobstart with proper error handling
  -- Auto-refresh sidebar on completion
end
```

### Auto-Update System

Automatic sidebar updates keep email current without user intervention:

```lua
-- Auto-refresh timer (60-second intervals)
M.state.refresh_timer = vim.loop.new_timer()
M.state.refresh_timer:start(60000, 60000, function()
  if M.is_sidebar_open() then
    native_sync.background_sync()
  end
end)
```

### OAuth Integration

OAuth token management is handled automatically:

1. **NixOS sets GMAIL_CLIENT_ID** system-wide
2. **Systemd timer refreshes tokens** daily
3. **Enhanced sync auto-refreshes** tokens before operations
4. **Fallback mechanisms** handle token failures gracefully

### Notification Integration

Integrates with the unified notification system:

- **Email operations** (always shown): Send, delete, move confirmations
- **Background sync** (debug only): Auto-refresh status
- **OAuth status** (debug only): Token refresh notifications

## File Structure

```
lua/neotex/plugins/tools/himalaya/
├── himalaya.lua             # Main plugin definition
├── config.lua               # Configuration management
├── commands.lua             # User commands
├── ui.lua                   # Email interface
├── utils.lua                # Core email operations
├── native_sync.lua          # Enhanced native sync system
├── auto_updates.lua         # Automatic sidebar updates
├── trash_manager.lua        # Local trash system
└── util/                    # Diagnostic and troubleshooting tools
```

## Benefits

### Eliminates Common Issues
- **No mbsync OAuth problems** - Direct Himalaya IMAP eliminates sync complexity
- **No manual token refresh** - Automatic OAuth management via systemd
- **No stale sidebar** - Auto-refresh keeps email current
- **No lost emails** - Local trash system with full recovery

### Provides Seamless Experience
- **Background operations** - Non-blocking sync and updates
- **Visual feedback** - Clear status indicators and notifications
- **Smart automation** - Context-aware folder detection and operations
- **Persistent state** - Maintains context across sessions

### Maintainable Configuration
- **Declarative setup** - NixOS configuration ensures reproducibility
- **System integration** - Leverages OS-level authentication management
- **Unified notifications** - Consistent user feedback across all operations
- **Comprehensive diagnostics** - Built-in troubleshooting and health monitoring

## Summary

The Himalaya email integration provides a complete, streamlined email management solution within NeoVim that eliminates common synchronization and authentication issues through:

1. **Native IMAP operations** using Himalaya CLI directly
2. **Automated OAuth management** via NixOS system configuration
3. **Real-time sidebar updates** with intelligent background refresh
4. **Local trash system** independent of IMAP server limitations
5. **Smart folder detection** for Gmail-specific folder structures
6. **Comprehensive diagnostics** for troubleshooting and maintenance

This approach provides a seamless, reliable email experience that integrates naturally with the NeoVim workflow while maintaining the flexibility and power of the Himalaya CLI email client.