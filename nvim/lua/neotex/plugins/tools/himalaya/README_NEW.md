# Himalaya Email Client Integration

Complete email client integration for Neovim using the [Himalaya CLI](https://github.com/soywod/himalaya), providing a modern, keyboard-driven email experience directly within your editor.

## Features

### Core Functionality
- **Neo-tree style sidebar** for persistent email browsing
- **Floating windows** for reading and composing emails
- **Multiple account support** with easy switching
- **Full keyboard navigation** using familiar Vim keybindings
- **Clickable URLs** with `<Ctrl+Click>` support
- **Draft management** with auto-save and recovery

### UI/UX
- **Persistent state** across Neovim sessions
- **Smart window management** with proper focus restoration
- **Loading indicators** and graceful error handling
- **Auto-refresh** capabilities for real-time updates
- **Responsive layout** that adapts to terminal size

### Email Operations
- Read, reply, reply-all, forward, and delete emails
- Compose new emails with rich text support
- Draft saving with automatic recovery
- URL extraction and click-to-open functionality
- Thread-aware email organization

## Installation & Setup

### Prerequisites
1. **Himalaya CLI installed**: Follow the [official installation guide](https://github.com/soywod/himalaya#installation)
2. **Email account configured** with Himalaya CLI (run `himalaya account setup` first)
3. **mbsync/isync** (optional, for offline email sync)

### Configuration
The plugin is automatically loaded when the tools configuration is enabled. No additional setup required if Himalaya CLI is properly configured.

#### Email Account Setup
```bash
# Configure your email account with Himalaya
himalaya account setup

# Test the configuration
himalaya account list
himalaya email list
```

#### Maildir Structure (if using mbsync)
If you use mbsync for offline email sync, ensure your maildir follows the Maildir++ format. The plugin includes conversion utilities if needed.

## Usage

### Opening Email Client
```
<leader>ml    " Open email list (main entry point)
```

### Email List Navigation (Sidebar)
```
j/k           " Navigate up/down through emails
<CR>          " Open selected email
R             " Refresh email list
q             " Close email client
```

### Email Reading
```
q             " Close email and return to list
gr            " Reply to current email
gR            " Reply all to current email
gf            " Forward current email
gD            " Delete current email
L             " Open link under cursor
```

### Email Composing
```
ZZ            " Send email
Q             " Discard draft
q             " Save as draft and close
```

### URL Handling
```
L             " Open link under cursor
<Ctrl+Click>  " Click to open URLs (in floating windows)
```

## Keybindings Reference

### Global Keymaps
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>ml` | Open Email List | Main entry point to email client |
| `<leader>mc` | Compose Email | Start composing a new email |
| `<leader>mr` | Refresh | Refresh current email view |

### Email List (Sidebar)
| Key | Action | Description |
|-----|--------|-------------|
| `j` / `<Down>` | Next Email | Move to next email |
| `k` / `<Up>` | Previous Email | Move to previous email |
| `<CR>` | Open Email | Open selected email for reading |
| `R` | Refresh | Refresh email list |
| `q` | Close | Close email client |

### Email Reading
| Key | Action | Description |
|-----|--------|-------------|
| `q` | Close | Close email and return to list |
| `gr` | Reply | Reply to current email |
| `gR` | Reply All | Reply to all recipients |
| `gf` | Forward | Forward current email |
| `gD` | Delete | Delete current email |
| `L` | Open Link | Open URL under cursor |
| `<Ctrl+Click>` | Click Link | Click to open URLs |

### Email Composing
| Key | Action | Description |
|-----|--------|-------------|
| `ZZ` | Send | Send the email |
| `Q` | Discard | Discard draft without saving |
| `q` | Save Draft | Save as draft and close |

## Configuration

### Account Settings
Configure email accounts through the Himalaya CLI:
```bash
himalaya account setup gmail  # Setup Gmail account
himalaya account setup work   # Setup work email account
```

### Plugin Configuration
The plugin uses sensible defaults but can be customized:

```lua
-- In your Neovim configuration (optional customization)
require('neotex.plugins.tools.himalaya.config').setup({
  default_account = 'gmail',
  sidebar_width = 50,
  auto_refresh = true,
  refresh_interval = 60000, -- 1 minute
})
```

### Sidebar Settings
- **Width**: Adjustable sidebar width (default: 50 columns)
- **Position**: Left-side placement (integrated with neo-tree style)
- **Persistence**: Maintains state across Neovim sessions

## Architecture

### Window Management
- **Sidebar**: Persistent email list using neo-tree pattern
- **Floating Windows**: Email reading and composing
- **Focus Stack**: Smart focus restoration when closing nested windows

### State Management
- Session persistence for current folder and account
- Draft auto-save and recovery
- Window layout preferences

### Error Handling
- Graceful degradation when Himalaya CLI is unavailable
- Clear error messages with suggested fixes
- Automatic retry mechanisms for temporary failures

## Troubleshooting

### Common Issues

#### "himalaya command not found"
**Solution**: Install Himalaya CLI:
```bash
# Using cargo
cargo install himalaya

# Using package manager (varies by OS)
# See: https://github.com/soywod/himalaya#installation
```

#### "cannot find configuration for account"
**Solution**: Configure your email account:
```bash
himalaya account setup your-account-name
```

#### "cannot list maildir entries"
**Problem**: Maildir structure mismatch between mbsync and Himalaya.
**Solution**: Run the provided maildir conversion script or reconfigure mbsync to use Maildir++ format.

#### Email subjects showing as "table: 0x..."
**Problem**: JSON parsing issue (should be fixed in current version).
**Solution**: Update to latest version or restart Neovim.

#### Navigation getting "stuck" in background buffers
**Problem**: Focus management issue with floating windows.
**Solution**: Use `q` to close windows properly, or restart email client with `<leader>ml`.

### Performance Tips
- Use auto-refresh sparingly for large inboxes
- Consider using mbsync for faster local email access
- Limit sidebar width on smaller terminals

### Debug Mode
Enable debug output:
```bash
# Check Himalaya CLI functionality
himalaya account list
himalaya email list --account your-account

# Check Neovim integration
:messages  " View recent log messages
```

## Integration with Other Tools

### mbsync/isync
- Compatible with offline email synchronization
- Supports Maildir++ format conversion
- Maintains folder structure and metadata

### External URL Handlers
- Uses system default browser for URL opening
- Configurable URL handlers through Himalaya CLI settings

### Git Integration
- Email client state is excluded from git tracking
- Configuration files can be version controlled

## Contributing

This plugin is part of the neotex Neovim configuration. For issues or improvements:

1. Check existing issues in the main repository
2. Test with latest Himalaya CLI version
3. Provide detailed error messages and steps to reproduce
4. Consider contributing improvements or bug fixes

## See Also

- [Himalaya CLI Documentation](https://github.com/soywod/himalaya)
- [mbsync/isync Setup Guide](http://isync.sourceforge.net/)
- [Neotex Configuration Overview](../../../../README.md)
- [Tools Plugin Directory](../README.md)
