# Himalaya Email Plugin for NeoVim

A comprehensive email management system that integrates the Himalaya CLI email client directly into NeoVim, providing a complete email workflow with local storage, automatic synchronization, and rich UI features.

## Quick Start

See [INSTALLATION.md](INSTALLATION.md) for complete setup instructions.

## Features

### 📧 **Email Management**
- **Multi-account support** - Manage personal and work emails seamlessly
- **Offline access** - Read and compose emails without internet connection
- **Real-time sync** - Automatic background synchronization every 5 minutes
- **Rich UI** - Floating windows with email list, reading, and composition views

### 🔍 **Navigation & Search**
- **Telescope integration** - Fuzzy search for folders, accounts, and emails
- **Quick folder switching** - Browse all email folders with unread counts
- **Account switching** - Switch between accounts with status indicators
- **Email search** - Full-text search across all emails

### ✉️ **Email Operations**
- **Compose emails** - Rich composition interface with signatures
- **Reply/Forward** - Reply, reply-all, and forward with quoted content
- **Email management** - Delete, move, copy, and flag emails
- **Attachment handling** - View and download email attachments

### ⚡ **Performance**
- **Local storage** - Instant email access from Maildir format
- **Background sync** - Non-blocking IMAP synchronization
- **Efficient UI** - Fast buffer switching and window management

## Architecture

```
IMAP Server <--[mbsync]--> Local Maildir <--> Himalaya CLI <--> NeoVim Interface
     |                          |                                    |
  Gmail/Work              ~/Mail/Gmail                          User Actions
                          ~/Mail/Work
```

The plugin uses a hybrid approach combining:
- **Himalaya CLI** for email operations and OAuth2 authentication
- **mbsync** for automatic IMAP synchronization
- **Local Maildir** storage for offline access and performance
- **NeoVim Lua** for rich UI and seamless integration

## Usage

### Global Keymaps

| Keymap | Command | Description |
|--------|---------|-------------|
| `<leader>me` | `:Himalaya` | Open email list |
| `<leader>mw` | `:HimalayaWrite` | Compose new email |
| `<leader>mf` | `:HimalayaFolders` | Browse folders |
| `<leader>ma` | `:HimalayaAccounts` | Switch accounts |
| `<leader>ms` | `:HimalayaSync` | Manual sync |

### Email List Navigation

| Keymap | Action | Description |
|--------|--------|-------------|
| `<CR>` | Read | Open selected email |
| `gw` | Write | Compose new email |
| `gr` | Reply | Reply to email |
| `gR` | Reply All | Reply to all recipients |
| `gf` | Forward | Forward email |
| `gD` | Delete | Delete email |
| `gm` | Folder | Change folder |
| `ga` | Account | Switch account |
| `gC` | Copy | Copy email to folder |
| `gM` | Move | Move email to folder |

### Email Reading

| Keymap | Action | Description |
|--------|--------|-------------|
| `gr` | Reply | Reply to current email |
| `gR` | Reply All | Reply to all recipients |
| `gf` | Forward | Forward current email |
| `gD` | Delete | Delete current email |
| `q` | Close | Close email view |

### Email Composition

| Command | Description |
|---------|-------------|
| `:w` | Save draft |
| `:HimalaySend` | Send email |
| `:q` | Cancel composition |

## Commands

### Core Commands

- **`:Himalaya [folder]`** - Open email list (optionally specify folder)
- **`:HimalayaWrite [email]`** - Compose new email (optionally specify recipient)
- **`:HimalayaFolders`** - Open folder picker
- **`:HimalayaAccounts`** - Open account picker
- **`:HimalayaSync[!]`** - Manual sync (use `!` to force)

### Email Operations

- **`:HimalayaRead <id>`** - Read specific email by ID
- **`:HimalayaReply[!] <id>`** - Reply to email (use `!` for reply-all)
- **`:HimalayaForward <id>`** - Forward email
- **`:HimalayaDelete <id>`** - Delete email
- **`:HimalayaMove <id> <folder>`** - Move email to folder
- **`:HimalayaCopy <id> <folder>`** - Copy email to folder

### Advanced Operations

- **`:HimalayaSearch <query>`** - Search emails
- **`:HimalayaFlag[!] <id> <flag>`** - Add flag (use `!` to remove)
- **`:HimalayaAttachments <id>`** - List email attachments
- **`:HimalayaDownload <id> <attachment>`** - Download attachment
- **`:HimalayaConfigure [account]`** - Configure account

## Configuration

The plugin can be configured by passing options to the setup function:

```lua
require('neotex.plugins.tools.himalaya').setup({
  -- Himalaya executable path
  executable = 'himalaya',
  
  -- Default account
  default_account = 'personal',
  
  -- Account configuration
  accounts = {
    personal = { 
      name = 'Your Name', 
      email = 'your-email@gmail.com' 
    },
    work = { 
      name = 'Work Name', 
      email = 'work@company.com' 
    },
  },
  
  -- UI configuration
  ui = {
    email_list = {
      width = 0.8,
      height = 0.8,
      preview = true,
    },
    compose = {
      width = 0.9,
      height = 0.9,
    },
  },
  
  -- Picker preference
  folder_picker = 'telescope', -- 'telescope', 'fzf', 'native'
  
  -- Sync settings
  auto_sync = true,
  sync_interval = 300, -- 5 minutes
  
  -- Email settings
  html_viewer = 'w3m',
  editor = vim.env.EDITOR or 'nvim',
})
```

### Customizing Keymaps

To customize keymaps, modify the `keymaps` section in the configuration:

```lua
require('neotex.plugins.tools.himalaya').setup({
  keymaps = {
    -- Email list navigation
    read_email = '<CR>',
    write_email = 'gw',
    reply = 'gr',
    reply_all = 'gR',
    forward = 'gf',
    delete = 'gD',
    change_folder = 'gm',
    change_account = 'ga',
    -- Add your custom keymaps here
  },
})
```

## File Structure

```
lua/neotex/plugins/tools/himalaya/
├── README.md              # This documentation
├── INSTALLATION.md        # Complete installation guide
├── init.lua              # Main plugin interface
├── config.lua            # Configuration management
├── commands.lua          # Command definitions
├── ui.lua                # Buffer and window management
├── picker.lua            # Telescope/fzf integration
└── utils.lua             # Utility functions and CLI integration
```

### Module Overview

- **`init.lua`** - Plugin entry point, lazy.nvim integration, and setup function
- **`config.lua`** - Configuration management, keymaps, and plugin state
- **`commands.lua`** - All user commands with tab completion and validation
- **`ui.lua`** - Email interface, floating windows, and buffer management
- **`picker.lua`** - Telescope/fzf integration for folder/account selection
- **`utils.lua`** - Himalaya CLI integration, email operations, and sync functionality

## Integration

### Telescope

The plugin integrates seamlessly with Telescope for:
- Folder browsing with unread counts
- Account switching with status indicators
- Email search with fuzzy matching

### Auto-sync

Automatic email synchronization runs in the background:
- Syncs every 5 minutes by default
- Non-blocking operation
- Triggers UI refresh after sync completion
- Manual sync available via `:HimalayaSync`

### Multi-account Support

Switch between accounts effortlessly:
- Independent folder structures
- Separate sync status
- Account-specific signatures
- Context-aware composition

## Dependencies

### Required
- **Himalaya CLI** - Email client backend
- **mbsync (isync)** - IMAP synchronization
- **GNOME Keyring** - Secure credential storage

### Optional
- **Telescope.nvim** - Enhanced folder/account picking
- **fzf-lua** - Alternative picker interface
- **w3m** - HTML email viewing

## Troubleshooting

### Common Issues

1. **"Himalaya CLI not found"**
   - Ensure Himalaya is installed and in PATH
   - Check configuration with `himalaya --version`

2. **"SASL mechanism XOAUTH2 not available"**
   - Install `cyrus-sasl-xoauth2` package
   - Set `SASL_PATH` environment variable

3. **"cannot list maildir entries"**
   - Run initial sync: `mbsync -a`
   - Check mail directory exists: `ls ~/Mail/`

4. **OAuth2 authentication fails**
   - Reconfigure account: `himalaya account configure`
   - Check Google Cloud Console settings

### Debug Commands

```bash
# Check Himalaya status
himalaya account list

# Test CLI integration
himalaya envelope list --output json

# Check sync status
systemctl --user status mbsync.timer

# Monitor sync logs
journalctl --user -u mbsync.service -f
```

## Navigation

- [← Tools Directory](../README.md)
- [Installation Guide →](INSTALLATION.md)
