# Himalaya Email Plugin for Neovim

A robust email client plugin for Neovim that integrates [himalaya-cli](https://github.com/pimalaya/himalaya) with [mbsync](https://isync.sourceforge.io/) for a complete email experience.

## Features

- 📧 **Email Management**: Read, compose, reply, and forward emails
- 🔄 **Robust Sync**: Automatic OAuth refresh and smart error handling
- 📁 **Smart Folders**: Automatic mapping between IMAP and local folders
- 🏥 **Health Checks**: Built-in diagnostics and automatic fixes
- 🧙 **Setup Wizard**: Guided first-time configuration
- 🔐 **OAuth Support**: Secure authentication with automatic token refresh

## Prerequisites

- Neovim 0.8+
- [mbsync](https://isync.sourceforge.io/) (isync) 1.4+
- [himalaya](https://github.com/pimalaya/himalaya) 0.9+
- flock (usually pre-installed on Linux/macOS)
- secret-tool (optional, for GNOME keyring)

### Installation

Install prerequisites:
```bash
# macOS
brew install isync himalaya

# Linux (Debian/Ubuntu)
sudo apt install isync himalaya

# NixOS - add to configuration.nix
environment.systemPackages = with pkgs; [
  isync
  himalaya
];
```

## Quick Start

### 1. Install the Plugin

Using [lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{
  dir = vim.fn.expand("~/.config/nvim/lua/neotex/plugins/tools/himalaya"),
  name = 'himalaya.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    require('neotex.plugins.tools.himalaya').setup({
      -- Optional: override defaults
      accounts = {
        gmail = {
          email = 'your-email@gmail.com',
        }
      }
    })
  end,
  keys = {
    { '<leader>ml', ':Himalaya<CR>', desc = 'Email list' },
    { '<leader>ms', ':HimalayaSyncInbox<CR>', desc = 'Sync inbox' },
    { '<leader>mc', ':HimalayaWrite<CR>', desc = 'Compose email' },
  }
}
```

### 2. Run Setup Wizard

After installation, run:
```vim
:HimalayaSetup
```

The wizard will guide you through:
1. Checking dependencies
2. Configuring OAuth authentication
3. Creating maildir structure
4. Testing email sync
5. Setting up keymaps

### 3. Configure OAuth (if needed)

If OAuth setup is required:
1. Exit Neovim
2. Run in terminal: `himalaya account configure gmail`
3. Follow the browser authentication flow
4. Return to Neovim

## Configuration

### Minimal Configuration

The plugin works with minimal configuration:
```lua
require('himalaya').setup({})
```

### Full Configuration Example

```lua
require('himalaya').setup({
  accounts = {
    gmail = {
      email = 'your-email@gmail.com',
      maildir_path = '~/Mail/Gmail/', -- Trailing slash required!
      
      -- Custom folder mappings (optional)
      folder_map = {
        ['[Gmail]/All Mail'] = 'All_Mail',
        ['[Gmail]/Sent Mail'] = 'Sent',
      },
      
      -- mbsync channel names
      mbsync = {
        inbox_channel = 'gmail-inbox',
        all_channel = 'gmail',
      }
    }
  },
  
  sync = {
    auto_refresh_oauth = true,    -- Auto-refresh expired tokens
    auto_sync_on_open = false,    -- Don't sync automatically
  },
  
  ui = {
    sidebar = {
      width = 40,
      position = 'left',
    },
    show_simple_progress = true,  -- Simple sync progress
  },
  
  setup = {
    auto_run = true,              -- Show setup hints if not configured
    check_health_on_startup = true, -- Run diagnostics on startup
  }
})
```

## Key Mappings

Default mappings with `<leader>m` prefix:

| Key | Description |
|-----|-------------|
| `<leader>ml` | Open email list |
| `<leader>ms` | Sync inbox |
| `<leader>mS` | Sync all folders |
| `<leader>mc` | Compose new email |
| `<leader>mh` | Health check |
| `<leader>mx` | Cancel sync |

### Email List Buffer

| Key | Description |
|-----|-------------|
| `<CR>` | Read email |
| `r` | Reply |
| `R` | Reply all |
| `f` | Forward |
| `d` | Delete |
| `D` | Delete permanently |
| `gA` | Archive |
| `gS` | Mark as spam |
| `q` | Close |

### Email Reading Buffer

| Key | Description |
|-----|-------------|
| `r` | Reply |
| `R` | Reply all |
| `f` | Forward |
| `d` | Delete |
| `a` | Show attachments |
| `q` | Close |

## Commands

### Main Commands
- `:Himalaya [folder]` - Open email list
- `:HimalayaWrite [to]` - Compose new email
- `:HimalayaReply <id>` - Reply to email
- `:HimalayaForward <id>` - Forward email

### Sync Commands
- `:HimalayaSyncInbox` - Quick inbox sync
- `:HimalayaSyncAll` - Full account sync
- `:HimalayaCancelSync` - Cancel ongoing sync

### Setup & Maintenance
- `:HimalayaSetup` - Run setup wizard
- `:HimalayaHealth` - Show health check
- `:HimalayaFixCommon` - Fix common issues
- `:HimalayaCleanup` - Clean up locks/processes

### OAuth Commands
- `:HimalayaOAuthRefresh` - Refresh token manually
- `:HimalayaOAuthStatus` - Show OAuth status

## Troubleshooting

### Common Issues

#### UIDVALIDITY Errors
**Symptom**: `Maildir error: cannot read UIDVALIDITY`

**Fix**:
```bash
find ~/Mail -name ".uidvalidity" -exec sh -c 'echo -n > "{}"' \;
```
Or run: `:HimalayaFixMaildir`

#### OAuth Authentication Failed
**Symptom**: Sync hangs at "Authenticating with XOAUTH2"

**Fix**:
1. Check status: `:HimalayaOAuthStatus`
2. Try refresh: `:HimalayaOAuthRefresh`
3. Reconfigure: `himalaya account configure gmail` (in terminal)

#### Folder Not Found (Archive/Spam)
**Symptom**: Can't archive or mark as spam

**Cause**: IMAP folder names differ from local names

**Fix**: Names are automatically mapped:
- `[Gmail]/All Mail` → `All_Mail`
- `[Gmail]/Spam` → `Spam`

#### Multiple Sync Processes
**Symptom**: "Another sync is already running"

**Fix**: `:HimalayaCleanup`

### NixOS Specific

For NixOS users, ensure OAuth environment variables are available:
```nix
# In home-manager configuration
systemd.user.sessionVariables = {
  GMAIL_CLIENT_ID = "your-client-id";
  SASL_PATH = "${pkgs.cyrus_sasl}/lib/sasl2";
};
```

### Health Check

Run `:HimalayaHealth` to diagnose issues:
```
🏥 Himalaya Health Check
────────────────────────────────────────
✅ Binaries: OK
✅ Maildir Structure: OK
✅ UIDVALIDITY Files: OK
❌ OAuth Tokens: ISSUES
  - No OAuth token found
  💡 Fix: :HimalayaSetupOAuth or run "himalaya account configure" in terminal
✅ Folder Mappings: OK
✅ Sync Processes: OK
────────────────────────────────────────
⚠️  Some issues detected. Run suggested fixes.
```

## Migration from Old Version

If upgrading from the old plugin version:
```vim
:HimalayaMigrate
```

This will:
- Backup old files
- Fix UIDVALIDITY files
- Update configuration
- Clear old state
- Run health check

## Architecture

The plugin follows a modular architecture:

```
himalaya/
├── core/           # Core functionality
│   ├── config.lua    # Configuration management
│   ├── logger.lua    # Logging system
│   └── state.lua     # State management
├── sync/           # Sync management
│   ├── mbsync.lua    # mbsync integration
│   ├── oauth.lua     # OAuth token management
│   └── lock.lua      # Process locking
├── ui/             # User interface components
│   ├── init.lua      # Main UI module
│   ├── email_list.lua # Email list display
│   ├── compose.lua    # Email composition
│   ├── sidebar.lua    # Sidebar functionality
│   └── notifications.lua # Smart notifications
├── setup/          # Setup and diagnostics
│   ├── wizard.lua    # Setup wizard
│   ├── health.lua    # Health checks
│   └── migration.lua # Version migration
└── docs/           # Documentation
```

Key improvements in v2:
- Simplified sync system (1800+ lines → ~200 lines)
- Automatic OAuth token refresh
- Smart error messages with suggested fixes
- Robust process management with flock
- Comprehensive health checks

## Contributing

Contributions are welcome! Please:
1. Check existing issues first
2. Follow the existing code style
3. Add tests for new features
4. Update documentation

## License

MIT License - see LICENSE file for details