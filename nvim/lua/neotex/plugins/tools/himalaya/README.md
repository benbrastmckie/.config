# Himalaya Email Plugin for NeoVim

A streamlined email management system that integrates the Himalaya CLI email client directly into NeoVim, providing a complete email workflow with local storage, automatic synchronization, and a sidebar + floating window UI architecture.

## Quick Start

See [INSTALLATION.md](INSTALLATION.md) for complete setup instructions.

## Features

### 📧 **Email Management**
- **Single account support** - Currently configured for Gmail account
- **Offline access** - Read and compose emails without internet connection  
- **Manual sync** - On-demand email synchronization via `:HimalayaSync`
- **Sidebar + Floating UI** - Persistent email list sidebar with floating email reading and composition windows

### 🔍 **Navigation & Organization**
- **Sidebar email list** - Persistent email list with pagination (30 emails per page)
- **Folder browsing** - Switch between email folders (INBOX, Sent, Drafts, etc.)
- **Email pagination** - Navigate through email pages with `gn`/`gp`
- **Session persistence** - Remembers current folder, account, and selected email across restarts

### ✉️ **Email Operations**
- **Compose emails** - Rich composition interface with templates
- **Reply/Forward** - Reply, reply-all, and forward with properly quoted content
- **Email management** - Delete, archive, and mark emails as spam
- **Smart folder detection** - Automatically finds correct folders (e.g., `[Gmail].All Mail` for archiving)

### ⚡ **Performance & Reliability** 
- **Local Maildir storage** - Instant email access from local file system
- **Stable navigation** - Window stack management prevents "stuck in background buffer" issues
- **Auto-refresh** - Email list refreshes after operations (delete, move, send, etc.)
- **Smart caching** - Email list caching with 30-second timeout for better performance

## Architecture

### Sidebar + Floating Window Design

```
┌─────────────────┬────────────────────────────────────┐
│   Email List   │           Main Editing Area        │
│   (Sidebar)    │                                    │
│                │  ┌─────────────────────────────┐   │
│ ● INBOX (12)   │  │      Email Reading          │   │
│   Sent         │  │      (Floating Window)      │   │
│   Drafts       │  │                             │   │
│   All Mail     │  │  ┌─────────────────────┐   │   │
│                │  │  │    Compose Email    │   │   │
│                │  │  │  (Modal Floating)   │   │   │
│                │  │  │                     │   │   │
│                │  │  └─────────────────────┘   │   │
│                │  └─────────────────────────────┘   │
└─────────────────┴────────────────────────────────────┘
```

### Data Flow

```
IMAP Server <--[mbsync]--> Local Maildir <--> Himalaya CLI <--> NeoVim Interface
     |                          |                                    |
   Gmail                 ~/Mail/Gmail                    Sidebar + Floating Windows
```

### Component Architecture

- **Himalaya CLI** - Email operations and OAuth2 authentication
- **mbsync** - Manual IMAP synchronization (triggered via `:HimalayaSync`)
- **Local Maildir** - Offline storage in `~/Mail/Gmail/` directory
- **Sidebar UI** - Persistent email list using neo-tree-style patterns
- **Window Stack** - Proper focus management for floating windows
- **State Management** - Session persistence and configuration storage

## Usage

### Global Keymaps

| Keymap | Command | Description |
|--------|---------|-------------|
| `<leader>ml` | `:Himalaya` | Open email list in sidebar |
| `<leader>mw` | `:HimalayaWrite` | Compose new email |
| `<leader>mf` | `:HimalayaFolders` | Browse folders |
| `<leader>ms` | `:HimalayaSync` | Manual sync |

### Email List Navigation (Sidebar)

| Keymap | Action | Description |
|--------|--------|-------------|
| `<CR>` | Read | Open selected email in floating window |
| `gw` | Write | Compose new email |
| `gr` | Reply | Reply to selected email |
| `gR` | Reply All | Reply to all recipients |
| `gf` | Forward | Forward selected email |
| `gD` | Delete | Delete email (moves to trash or prompts) |
| `gA` | Archive | Archive email (smart folder detection) |
| `gS` | Spam | Mark email as spam (smart folder detection) |
| `gm` | Folder | Change folder |
| `gn` | Next Page | Navigate to next page of emails |
| `gp` | Previous Page | Navigate to previous page of emails |
| `r` | Refresh | Refresh email list |
| `q` | Close | Close Himalaya entirely |

### Email Reading (Floating Window)

| Keymap | Action | Description |
|--------|--------|-------------|
| `gr` | Reply | Reply to current email |
| `gR` | Reply All | Reply to all recipients |
| `gf` | Forward | Forward current email |
| `gD` | Delete | Delete current email |
| `gl` | Links | Go to link under cursor |
| `q` | Close | Close email and return to sidebar |

### Email Composition (Floating Window)

| Keymap | Action | Description |
|--------|--------|-------------|
| `ZZ` | Send | Send email |
| `q` | Save Draft | Save as draft and close |
| `Q` | Discard | Discard without saving |

## Commands

### Core Commands

- **`:Himalaya [folder]`** - Open email list in sidebar (optionally specify folder)
- **`:HimalayaWrite [email]`** - Compose new email (optionally specify recipient)
- **`:HimalayaFolders`** - Open folder picker (via vim.ui.select)
- **`:HimalayaSync[!]`** - Manual email sync (use `!` to force)
- **`:HimalayaClose`** - Close Himalaya and cleanup all buffers

### Email Operations

- **`:HimalayaRead <id>`** - Read specific email by ID
- **`:HimalayaReply[!] <id>`** - Reply to email (use `!` for reply-all)
- **`:HimalayaForward <id>`** - Forward email
- **`:HimalayaDelete <id>`** - Delete email
- **`:HimalayaMove <id> <folder>`** - Move email to folder
- **`:HimalayaCopy <id> <folder>`** - Copy email to folder

### Session Management

- **`:HimalayaRestore[!]`** - Restore previous session (use `!` to skip prompt)

### Debug & Maintenance

- **`:HimalayaDebug`** - Debug buffer state
- **`:HimalayaConfigValidate`** - Validate mbsync configuration
- **`:HimalayaConfigHelp`** - Show configuration help
- **`:HimalayaAlternativeSync`** - Try alternative sync method

## Configuration

The plugin can be configured by passing options to the setup function:

```lua
require('neotex.plugins.tools.himalaya').setup({
  -- Himalaya executable path
  executable = 'himalaya',
  
  -- Default account (currently single account)
  default_account = 'gmail',
  
  -- Account configuration
  accounts = {
    gmail = { 
      name = 'Benjamin Brast-McKie', 
      email = 'benbrastmckie@gmail.com' 
    },
  },
  
  -- UI configuration for floating windows
  ui = {
    email_list = {
      width = 0.8,
      height = 0.8,
    },
  },
  
  -- Sync settings (manual sync only)
  auto_sync = true,
  sync_interval = 300, -- 5 minutes (currently unused - manual sync only)
})
```

### Default Configuration (Currently Active)

The plugin is currently configured with minimal options for Gmail:

```lua
M.config = {
  executable = 'himalaya',
  default_account = 'gmail',
  accounts = {
    gmail = { name = 'Benjamin Brast-McKie', email = 'benbrastmckie@gmail.com' },
  },
  ui = {
    email_list = {
      width = 0.8,
      height = 0.8,
    },
  },
  -- Basic keymaps
  keymaps = {
    read_email = '<CR>',
    write_email = 'gw',
    reply = 'gr',
    reply_all = 'gR',
    forward = 'gf',
    delete = 'gD',
    change_folder = 'gm',
    refresh = 'r',
  },
  -- Sync settings
  auto_sync = true,
  sync_interval = 300,
}
```

### State Management

The plugin automatically saves and restores session state including:

- **Current account** and **folder** 
- **Selected email** and **sidebar position**
- **Search queries** and **pagination state**
- **Sidebar width** and **configuration preferences**

State is saved to `~/.local/share/nvim/himalaya/state.json` and automatically restored when reopening Neovim.

### Smart Email Operations

#### Archive Function (`gA`)
Automatically detects the correct archive folder:
- **Gmail**: Uses `[Gmail].All Mail` 
- **Other providers**: Looks for `Archive`, `All Mail`, `ARCHIVE`, etc.
- **Fallback**: Prompts user to select folder if none found

#### Spam Function (`gS`) 
Automatically detects spam/junk folders:
- **Gmail**: Uses `[Gmail].Spam` (if available)
- **Other providers**: Looks for `Spam`, `Junk`, `SPAM`, etc.
- **Fallback**: Prompts user for folder selection

#### Delete Function (`gD`)
Intelligent delete handling:
- **First attempt**: Move to trash folder
- **Missing trash**: Prompts for permanent delete or custom folder
- **Headless mode**: Automatically handles without prompts

## File Structure

```
lua/neotex/plugins/tools/himalaya/
├── README.md              # This documentation
├── UI.md                  # Implementation details and debug features
├── SYNC.md                # Gmail sync diagnostics and fixes
├── init.lua              # Main plugin interface
├── config.lua            # Configuration management and keymaps
├── commands.lua          # Command definitions and tab completion
├── ui.lua                # Sidebar + floating window management
├── sidebar.lua           # Persistent email list sidebar
├── window_stack.lua      # Window hierarchy and focus management  
├── state.lua             # Session persistence and state management
├── picker.lua            # Folder/account selection interfaces
├── utils.lua             # Himalaya CLI integration and email operations
└── util/                  # Diagnostic and troubleshooting tools
    ├── README.md          # Diagnostic tools documentation
    ├── init.lua          # Main utilities interface
    ├── diagnostics.lua   # Complete diagnostic suite
    ├── gmail_settings.lua # Gmail IMAP settings verification
    ├── mbsync_analyzer.lua # mbsync configuration analysis
    ├── folder_diagnostics.lua # Folder access testing
    └── operation_tester.lua # Email operation testing
```

### Module Overview

- **`init.lua`** - Plugin entry point and setup function
- **`config.lua`** - Configuration management, keymaps, and g-command handlers
- **`commands.lua`** - All user commands with tab completion and validation
- **`ui.lua`** - Email interface, email operations, and display formatting
- **`sidebar.lua`** - Persistent sidebar implementation with neo-tree patterns
- **`window_stack.lua`** - Window hierarchy tracking for proper focus management
- **`state.lua`** - Session persistence, state management, and auto-save
- **`picker.lua`** - vim.ui.select integration for folder/account selection  
- **`utils.lua`** - Himalaya CLI integration, sync functionality, and email operations
- **`util/`** - **Diagnostic and troubleshooting suite** - [See util/README.md](util/README.md) for comprehensive troubleshooting tools

### Key Features Implemented

- ✅ **Sidebar + Floating Architecture** - Stable navigation with persistent email list
- ✅ **Window Stack Management** - Proper focus restoration prevents "stuck in background"
- ✅ **Session Persistence** - Automatic state save/restore across Neovim sessions
- ✅ **Smart Email Operations** - Auto-detect folders for archive/spam/delete operations
- ✅ **Pagination System** - Navigate through emails with 30 per page default
- ✅ **Auto-refresh** - Email list updates after operations and sync completion

## Integration

### Neovim Integration

The plugin integrates with standard Neovim features:
- **vim.ui.select** - Folder and account selection (no telescope dependency)
- **vim.keymap.set** - Standard keymap configuration
- **vim.notify** - Status messages and error reporting
- **autocommands** - Auto-refresh triggers for email operations

### Auto-refresh System

Email list automatically refreshes after:
- Email operations (delete, move, send, archive, spam)
- Manual sync completion (`:HimalayaSync`)
- Folder changes and account switches
- Email sending and draft operations

### Session Management

Persistent state management includes:
- **Window restoration** - Remembers sidebar position and email selection
- **Folder persistence** - Restores last viewed folder on startup  
- **Account state** - Maintains current account across sessions
- **Search history** - Preserves search queries and results

### Manual Sync Only

Current sync configuration:
- **Manual sync** via `:HimalayaSync` command
- **Background sync** disabled (auto_sync setting unused)
- **On-demand operation** prevents blocking UI operations
- **Error handling** with intelligent sync failure analysis

## Dependencies

### Required
- **Himalaya CLI** - Email client backend and OAuth2 authentication
- **mbsync (isync)** - IMAP synchronization (manual via `:HimalayaSync`)
- **Credential storage** - GNOME Keyring, pass, or similar for OAuth tokens

### Built-in (No External Dependencies)
- **vim.ui.select** - Folder and account selection (replaces Telescope dependency)
- **Standard Neovim APIs** - Buffer management, keymaps, autocommands
- **Lua file I/O** - State persistence and configuration storage

## Troubleshooting

### Common Issues

1. **"No email to delete" / "Failed to move email"**
   - **Cause**: Missing archive/spam folders or email ID extraction issues
   - **Solution**: See [UI.md Debug Features](UI.md#debug-features) for detailed troubleshooting

2. **"cannot find maildir matching name Archive"**
   - **Cause**: Standard folder names don't exist (Gmail uses `[Gmail].All Mail`)
   - **Solution**: Archive function now auto-detects correct folders

3. **"Himalaya command failed: invalid value 'Archive' for '<ID>'"**
   - **Cause**: Command syntax issues (fixed: now uses correct `<TARGET> <ID>` order)
   - **Solution**: Automatically resolved with updated command construction

4. **Email operations don't work in sidebar**
   - **Cause**: Email ID extraction from wrong line numbers
   - **Solution**: Fixed header line calculation (4 header lines before emails)

5. **"Himalaya closed (0 buffers cleaned up)"**
   - **Cause**: Trying to use operations when sidebar not open
   - **Solution**: Open Himalaya with `<leader>ml` first

### Quick Debug Steps

1. **Quick health check**: `:HimalayaQuickHealthCheck` - Fast overview of system status
2. **Complete diagnostics**: `:HimalayaFullDiagnostics` - Comprehensive analysis and troubleshooting
3. **Test delete operation**: `:HimalayaTestDelete` - Test the most common failing operation
4. **Check Gmail settings**: `:HimalayaCheckGmailSettings` - Verify Gmail IMAP settings
5. **Analyze configuration**: `:HimalayaAnalyzeMbsync` - Check mbsync configuration
6. **Test folder access**: `:HimalayaTestFolderAccess` - Verify folder detection

See [util/README.md](util/README.md) for complete diagnostic command reference.

### Gmail-Specific Folder Names

Your Gmail account uses these folder names:
- **Archive**: `[Gmail].All Mail` (auto-detected by `gA`)
- **Sent**: `[Gmail].Sent Mail`
- **Drafts**: `[Gmail].Drafts`
- **Custom folders**: `EuroTrip`, `CrazyTown`, `Letters`

### Debug Commands

```bash
# Check Himalaya status
himalaya account list

# Test folder access
himalaya folder list -a gmail

# Test email list
himalaya envelope list --folder INBOX -a gmail

# Check configuration
himalaya --version
```

## Summary

The Himalaya email plugin provides a complete email management solution within Neovim using a **sidebar + floating window architecture**. Key achievements:

### ✅ **Fully Functional Email Operations**
- **Archive** (`gA`) - Auto-detects `[Gmail].All Mail` for Gmail accounts
- **Delete** (`gD`) - Intelligent trash handling with fallbacks
- **Spam** (`gS`) - Smart spam folder detection
- **Reply/Forward** (`gr`/`gf`) - Proper email composition with quoted content
- **Pagination** (`gn`/`gp`) - Navigate through email pages efficiently

### ✅ **Stable UI Architecture**  
- **Persistent Sidebar** - Email list remains visible during operations
- **Window Stack Management** - Prevents "stuck in background buffer" issues
- **Session Persistence** - Remembers state across Neovim restarts
- **Auto-refresh** - Email list updates after operations

### ✅ **Robust Configuration**
- **Single Gmail Account** - Fully configured and working
- **Smart Folder Detection** - Handles Gmail's `[Gmail].` folder naming
- **Manual Sync** - Reliable on-demand email synchronization
- **Error Handling** - Comprehensive error recovery and user guidance

## Navigation

- [← Tools Directory](../README.md)
- [Debug Features →](UI.md#debug-features)
