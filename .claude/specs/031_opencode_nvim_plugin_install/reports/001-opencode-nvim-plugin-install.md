# Research Report: Opencode.nvim Plugin Installation

**Date**: 2025-12-10
**Topic**: Opencode.nvim Plugin Installation
**Status**: Complete

---

## Executive Summary

This report documents the installation process for opencode.nvim, a Neovim plugin that integrates the OpenCode AI coding assistant with the Neovim editor. Multiple plugin implementations exist, with the two primary options being:

1. **NickvanDyke/opencode.nvim** - TUI-based integration with automatic process detection/management
2. **sudo-tee/opencode.nvim** - Full Neovim frontend with chat interface and persistent sessions

Both require the OpenCode CLI (already installed on the user's machine) and support multiple plugin managers including lazy.nvim, packer.nvim, and vim-plug.

---

## Available Plugin Options

### Option 1: NickvanDyke/opencode.nvim (Recommended)

**Repository**: https://github.com/NickvanDyke/opencode.nvim

**Description**: Integrates the opencode AI assistant with Neovim using the native TUI interface, providing streamlined editor-aware research, reviews, and requests.

**Key Features**:
- Auto-connects to any opencode running inside Neovim's CWD or manages an integrated instance
- Context injection via placeholders (@this, @buffer, @buffers, @visible, @diagnostics, @quickfix, @diff, @grapple)
- Built-in prompt library (diagnostics, diff, document, explain, fix, implement, optimize, review, test)
- Real-time buffer reloading when opencode edits files
- Interactive permission request handling
- Multiple provider support (snacks, kitty, wezterm, tmux, custom)
- Statusline component for monitoring opencode state

**Best For**: Users who prefer the native OpenCode TUI and want automatic process management with minimal configuration overhead.

### Option 2: sudo-tee/opencode.nvim

**Repository**: https://github.com/sudo-tee/opencode.nvim

**Description**: A Neovim frontend for opencode that creates a chat interface while capturing editor context. Fork of the original goose.nvim plugin.

**Key Features**:
- Full Neovim-native chat interface (not TUI-based)
- Persistent sessions tied to workspace (similar to Cursor AI)
- Session management and timeline navigation
- File diff viewing and reversion capabilities
- Snapshot system for workspace state management
- Image pasting support
- Current file content, selections, and diagnostics integration

**Best For**: Users who want a fully integrated Neovim chat interface with comprehensive session management and workspace state tracking.

### Option 3: kksimons/nvim-opencode

**Repository**: https://github.com/kksimons/nvim-opencode

**Description**: Simplified plugin that integrates OpenCode directly into the editor with terminal management.

**Key Features**:
- Terminal management (toggle with `<leader>A`)
- Text sharing with accurate line counts
- File context management (add/remove files)
- Session persistence
- Automatic OpenCode detection (PATH, ~/.local/bin, /usr/local/bin, /opt/homebrew/bin)

**Best For**: Users who want a minimal integration focused on terminal management and basic context sharing.

### Option 4: cousine/opencode-context.nvim

**Repository**: https://github.com/cousine/opencode-context.nvim

**Description**: Neovim plugin for interacting with opencode AI assistant TUI session open in a tmux pane.

**Key Features**:
- Tmux integration (sends keystrokes to opencode pane)
- Auto-detects running opencode pane in current tmux window
- Send current buffer, all buffers, visual selections, or diagnostics
- No separate OpenCode instance management (uses existing tmux session)

**Best For**: Users who run OpenCode in tmux and want seamless context sharing between Neovim and the tmux pane.

---

## Prerequisites

### OpenCode CLI

**Status**: Already installed on user's machine

**Verification**:
```bash
# Check OpenCode CLI is available
which opencode

# Check version (required: v0.6.3+ for sudo-tee plugin, any for NickvanDyke)
opencode --version
```

**Installation (if needed)**:
```bash
# Via curl
curl -fsSL https://opencode.ai/install | bash

# Via npm
npm i -g opencode-ai@latest

# Via brew
brew install opencode

# Via Scoop (Windows)
scoop install opencode

# Via Chocolatey (Windows)
choco install opencode
```

**Installation Path Priority**:
1. `$OPENCODE_INSTALL_DIR`
2. `$XDG_BIN_DIR`
3. `$HOME/bin`

### Neovim Requirements

- **Neovim Version**: >= 0.8 (for nvim-opencode), >= 0.9 recommended for others
- **Lua Support**: Required (built-in for modern Neovim)
- **autoread**: Must be enabled (`vim.o.autoread = true`)

---

## Installation Instructions

### Option 1: NickvanDyke/opencode.nvim

#### With lazy.nvim (Recommended)

```lua
{
  "NickvanDyke/opencode.nvim",
  dependencies = {
    -- Recommended for `ask()` and `select()` functions
    -- Required for `snacks` provider
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      -- Your configuration options here
      -- See lua/opencode/config.lua for all options
    }

    -- Required for automatic buffer reloading
    vim.o.autoread = true

    -- Recommended keymaps
    vim.keymap.set({"n", "x"}, "<C-a>",
      function() require("opencode").ask("@this: ", { submit = true }) end,
      { desc = "Ask opencode" })

    vim.keymap.set({"n", "x"}, "<C-x>",
      function() require("opencode").select() end,
      { desc = "Execute opencode action…" })

    vim.keymap.set({"n", "x"}, "ga",
      function() require("opencode").prompt("@this") end,
      { desc = "Add to opencode" })

    vim.keymap.set({"n", "t"}, "<C-.>",
      function() require("opencode").toggle() end,
      { desc = "Toggle opencode" })
  end,
}
```

#### With packer.nvim

```lua
use {
  "NickvanDyke/opencode.nvim",
  requires = {
    { "folke/snacks.nvim" },
  },
  config = function()
    vim.g.opencode_opts = {}
    vim.o.autoread = true
    -- Add keymaps as shown above
  end
}
```

#### With vim-plug

```vim
Plug 'folke/snacks.nvim'
Plug 'NickvanDyke/opencode.nvim'

" In your init.vim or after plug#end()
lua << EOF
vim.g.opencode_opts = {}
vim.o.autoread = true
-- Add keymaps as shown above
EOF
```

#### With nixvim

```nix
programs.nixvim = {
  extraPlugins = [ pkgs.vimPlugins.opencode-nvim ];
};
```

#### Dependencies

**Required**:
- None (opencode CLI must be in PATH or CWD)

**Recommended**:
- `folke/snacks.nvim` - Required for `ask()` and `select()` functions, and for the `snacks` provider

#### Provider Configuration

The plugin auto-detects or manages an opencode instance. Configure your preferred provider:

**Snacks Terminal** (default if snacks.nvim installed):
```lua
vim.g.opencode_opts = {
  provider = {
    enabled = "snacks",
    snacks = {
      -- Additional snacks.nvim terminal options
    }
  }
}
```

**Kitty** (requires remote control via socket):
```lua
vim.g.opencode_opts = {
  provider = {
    enabled = "kitty",
    kitty = {
      -- Additional kitty options
    }
  }
}
```

Enable remote control in `~/.config/kitty/kitty.conf`:
```
allow_remote_control yes
listen_on unix:/tmp/kitty
```

Or start kitty with:
```bash
kitty -o allow_remote_control=yes --single-instance --listen-on unix:@mykitty
```

**WezTerm**:
```lua
vim.g.opencode_opts = {
  provider = {
    enabled = "wezterm",
    wezterm = {
      direction = "bottom",  -- or "top", "left", "right"
      top_level = false,
      percent = 50,
    }
  }
}
```

**Tmux**:
```lua
vim.g.opencode_opts = {
  provider = {
    enabled = "tmux",
    tmux = {
      -- Additional tmux options
    }
  }
}
```

#### Context Placeholders

Use these placeholders in prompts to inject editor context:

| Placeholder | Description |
|------------|-------------|
| `@this` | Visual selection or cursor position |
| `@buffer` | Current buffer content |
| `@buffers` | All open buffers |
| `@visible` | Visible text in current view |
| `@diagnostics` | LSP diagnostics in buffer |
| `@quickfix` | Quickfix list items |
| `@diff` | Git diff output |
| `@grapple` | grapple.nvim tags |

---

### Option 2: sudo-tee/opencode.nvim

#### With lazy.nvim

```lua
{
  "sudo-tee/opencode.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MeanderingProgrammer/render-markdown.nvim",
    -- Optional: completion and picker tools
    "saghen/blink.cmp",  -- or "hrsh7th/nvim-cmp"
    "folke/snacks.nvim", -- or "nvim-telescope/telescope.nvim" or "ibhagwan/fzf-lua"
  },
  config = function()
    require("opencode").setup({
      -- UI positioning
      position = "right",        -- or "left"
      input_position = "bottom", -- or "top"
      width = 40,                -- percentage
      input_height = 15,         -- percentage

      -- Keymap prefix (default: <leader>o)
      keymap_prefix = "<leader>o",
    })
  end,
}
```

#### With packer.nvim

```lua
use {
  "sudo-tee/opencode.nvim",
  requires = {
    "nvim-lua/plenary.nvim",
    "MeanderingProgrammer/render-markdown.nvim",
  },
  config = function()
    require("opencode").setup({})
  end
}
```

#### With vim-plug

```vim
Plug 'nvim-lua/plenary.nvim'
Plug 'MeanderingProgrammer/render-markdown.nvim'
Plug 'sudo-tee/opencode.nvim'

lua << EOF
require("opencode").setup({})
EOF
```

#### Dependencies

**Required**:
- OpenCode CLI (v0.6.3 or higher)
- `nvim-lua/plenary.nvim`
- `MeanderingProgrammer/render-markdown.nvim`

**Optional**:
- Completion: `saghen/blink.cmp` or `hrsh7th/nvim-cmp`
- Picker: `folke/snacks.nvim` or `nvim-telescope/telescope.nvim` or `ibhagwan/fzf-lua`

#### Key Mappings (default)

- `<leader>og` - Toggle opencode UI
- `<cr>` - Submit prompt (in input mode)
- Session management and timeline navigation via UI
- File diff viewing and reversion capabilities

---

### Option 3: kksimons/nvim-opencode

#### With lazy.nvim

```lua
{
  "ksimons/nvim-opencode",
  config = function()
    require("opencode").setup({
      auto_start = true,      -- Auto-start terminal on load
      terminal_cmd = nil,     -- nil = auto-detect, or path to opencode executable
      terminal = {
        split_side = "right", -- or "left"
        split_width_percentage = 0.30,
      },
    })

    -- Key mappings
    vim.keymap.set("n", "<leader>A", require("opencode").toggle_terminal, { desc = "Toggle OpenCode" })
    vim.keymap.set("v", "a", require("opencode").send_selection, { desc = "Send selection to OpenCode" })
    vim.keymap.set("n", "a", require("opencode").send_clipboard, { desc = "Send clipboard to OpenCode" })
    vim.keymap.set("n", "<leader>+", require("opencode").add_current_file, { desc = "Add file to OpenCode" })
    vim.keymap.set("n", "<leader>-", require("opencode").remove_current_file, { desc = "Remove file from OpenCode" })
    vim.keymap.set("n", "<leader>=", require("opencode").toggle_current_file, { desc = "Toggle file in OpenCode" })
    vim.keymap.set("n", "1", require("opencode").focus_editor, { desc = "Focus editor" })
    vim.keymap.set("n", "9", require("opencode").focus_terminal, { desc = "Focus OpenCode" })
  end,
}
```

#### Manual Installation

```bash
git clone https://github.com/ksimons/nvim-opencode.git ~/.config/nvim/pack/plugins/start/nvim-opencode
```

Add to `init.lua`:
```lua
require("opencode").setup()
```

#### Dependencies

**Required**:
- Neovim >= 0.8
- OpenCode installed and available in PATH

#### Auto-detection Paths

The plugin searches for OpenCode in this order:
1. `opencode` in PATH
2. `~/.local/bin/opencode`
3. `/usr/local/bin/opencode`
4. `/opt/homebrew/bin/opencode`

Override with `terminal_cmd` option if needed.

---

### Option 4: cousine/opencode-context.nvim

#### With lazy.nvim

```lua
{
  "cousine/opencode-context.nvim",
  config = function()
    require("opencode-context").setup({
      tmux_target = nil,        -- nil = auto-detect
      auto_detect_pane = true,  -- Auto-detect running opencode pane
    })
  end,
}
```

#### With vim-plug

```vim
Plug 'cousine/opencode-context.nvim'

lua << EOF
require('opencode-context').setup({
  tmux_target = nil,
  auto_detect_pane = true,
})
EOF
```

#### Dependencies

**Required**:
- Tmux
- OpenCode running in a tmux pane

#### Usage

Sends context directly to existing opencode tmux pane via tmux send-keys. No separate OpenCode instance management required.

---

## Installation Verification

### NickvanDyke/opencode.nvim

Run health check after installation:
```vim
:checkhealth opencode
```

Expected output:
- OpenCode CLI detected (if running or in PATH)
- Provider configuration valid
- Dependencies available
- No errors reported

Test functionality:
```vim
" Toggle opencode
<C-.>

" Ask opencode with context
<C-a>

" Execute action menu
<C-x>
```

### sudo-tee/opencode.nvim

Verify installation:
```vim
" Toggle UI
<leader>og

" Check for errors in messages
:messages
```

Expected behavior:
- UI opens without errors
- OpenCode CLI v0.6.3+ detected
- Chat interface renders correctly

### kksimons/nvim-opencode

Verify installation:
```vim
" Toggle terminal
<leader>A

" Check terminal opens and OpenCode starts
" Check for errors in messages
:messages
```

Expected behavior:
- Terminal opens on right side (or configured side)
- OpenCode starts automatically (if auto_start = true)
- Session persists when terminal is toggled

### cousine/opencode-context.nvim

Verify installation:
1. Start OpenCode in tmux pane: `opencode`
2. Open Neovim in another tmux pane
3. Send context to OpenCode
4. Verify OpenCode receives context in tmux pane

---

## Common Issues and Troubleshooting

### Issue 1: "Cannot find opencode"

**Symptoms**:
- Plugin reports "opencode not found" or similar
- `:checkhealth opencode` shows errors

**Solutions**:
1. Verify OpenCode CLI is installed: `which opencode`
2. Check OpenCode is in PATH: `echo $PATH | grep -o "[^:]*opencode[^:]*"`
3. For kksimons plugin, explicitly set path:
   ```lua
   terminal_cmd = "/full/path/to/opencode"
   ```
4. Restart Neovim after PATH changes

### Issue 2: Buffer Reloading Not Working

**Symptoms**:
- OpenCode edits files but Neovim doesn't reload buffers
- Must manually reload with `:e`

**Solutions**:
1. Ensure `vim.o.autoread = true` is set in config
2. Check file permissions (Neovim must have write access)
3. Verify `opts.events.reload` is not disabled in config

### Issue 3: Missing Config File Error

**Symptoms**:
- `Error executing vim.schedule lua callback: Vim:E484: Can't open file ~/.config/opencode/config.json`

**Solutions**:
1. Run OpenCode CLI once to generate config: `opencode --help`
2. Create config directory manually:
   ```bash
   mkdir -p ~/.config/opencode
   ```
3. Ensure OpenCode CLI version is v0.6.3+ (for sudo-tee plugin)

### Issue 4: ProviderModelNotFoundError

**Symptoms**:
- Error about model not found
- Plugin cannot start OpenCode instance

**Solutions**:
1. Check model reference format: `<providerId>/<modelId>`
2. Verify OpenCode CLI configuration: `opencode config`
3. Update OpenCode CLI: `npm i -g opencode-ai@latest`

### Issue 5: Kitty Terminal Provider Setup Issues

**Symptoms**:
- Kitty provider fails to start OpenCode
- "Remote control not enabled" error

**Solutions**:
1. Enable remote control in `~/.config/kitty/kitty.conf`:
   ```
   allow_remote_control yes
   listen_on unix:/tmp/kitty
   ```
2. Restart Kitty
3. Or start Kitty with remote control:
   ```bash
   kitty -o allow_remote_control=yes --single-instance --listen-on unix:@mykitty
   ```

### Issue 6: TUI Display Issues in Neovim Terminal

**Symptoms**:
- OpenCode TUI broken with right border artifacts
- Misaligned input area
- Unstable interaction

**Solutions**:
1. Use NickvanDyke plugin (uses provider integration, not nested terminal)
2. Or run OpenCode in separate terminal/tmux pane
3. Avoid running OpenCode inside Neovim's integrated terminal

### Issue 7: Version Compatibility

**Symptoms**:
- Plugin stops working after OpenCode update
- Breaking changes reported

**Solutions**:
1. Check plugin compatibility with OpenCode version
2. sudo-tee plugin requires v0.6.3+
3. Downgrade OpenCode if needed:
   ```bash
   npm i -g opencode-ai@<version>
   ```
4. Check plugin repository for compatibility notes

### Issue 8: Tmux Auto-detection Fails (opencode-context.nvim)

**Symptoms**:
- Cannot find OpenCode pane
- Context not sent to OpenCode

**Solutions**:
1. Verify OpenCode is running in tmux pane: `tmux list-panes`
2. Manually specify tmux target:
   ```lua
   tmux_target = "session:window.pane"
   ```
3. Ensure auto_detect_pane = true in config

---

## Plugin Comparison Matrix

| Feature | NickvanDyke | sudo-tee | kksimons | cousine |
|---------|-------------|----------|----------|---------|
| **Interface** | TUI | Neovim UI | Terminal | Tmux Integration |
| **Auto-detect OpenCode** | Yes | No | Yes | Yes (tmux) |
| **Process Management** | Yes | Yes | Yes | No (uses tmux) |
| **Context Injection** | Placeholders | Built-in | Manual | Manual |
| **Session Persistence** | No | Yes | Yes | N/A (tmux) |
| **Buffer Reloading** | Yes | Yes | No | No |
| **Permission Handling** | Yes | No | No | No |
| **Statusline Component** | Yes | No | No | No |
| **Diff/Reversion** | No | Yes | No | No |
| **Min Neovim Version** | 0.9+ | 0.9+ | 0.8+ | 0.8+ |
| **Min OpenCode Version** | Any | v0.6.3+ | Any | Any |
| **Primary Dependencies** | snacks.nvim | plenary, render-markdown | None | None (tmux) |
| **Configuration Complexity** | Medium | Low | Low | Low |
| **Best For** | Power users | Cursor-like experience | Minimal setup | Tmux workflows |

---

## Recommendation

### For the User's Setup

Given that the user already has OpenCode CLI installed, the recommended plugin is:

**NickvanDyke/opencode.nvim**

**Rationale**:
1. Most feature-rich with automatic process management
2. Context injection via placeholders is powerful and flexible
3. Built-in prompt library reduces configuration overhead
4. Real-time buffer reloading and permission handling
5. Supports multiple providers (works with user's terminal setup)
6. Active development with health check support

**Installation Steps**:

1. Add to lazy.nvim config:
```lua
{
  "NickvanDyke/opencode.nvim",
  dependencies = {
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  config = function()
    vim.g.opencode_opts = {}
    vim.o.autoread = true

    -- Keymaps
    vim.keymap.set({"n", "x"}, "<C-a>",
      function() require("opencode").ask("@this: ", { submit = true }) end,
      { desc = "Ask opencode" })
    vim.keymap.set({"n", "t"}, "<C-.>",
      function() require("opencode").toggle() end,
      { desc = "Toggle opencode" })
  end,
}
```

2. Run `:Lazy sync` in Neovim

3. Verify installation: `:checkhealth opencode`

4. Test: Press `<C-.>` to toggle OpenCode

**Alternative Recommendation**:

If the user wants a more Cursor-like experience with full chat interface and session management:

**sudo-tee/opencode.nvim**

Note: Requires OpenCode CLI v0.6.3+. Check version first: `opencode --version`

---

## Additional Resources

### Primary Plugin Repositories
- [NickvanDyke/opencode.nvim](https://github.com/NickvanDyke/opencode.nvim) - TUI-based integration with auto process management
- [sudo-tee/opencode.nvim](https://github.com/sudo-tee/opencode.nvim) - Full Neovim frontend with chat interface
- [kksimons/nvim-opencode](https://github.com/kksimons/nvim-opencode) - Minimal terminal management plugin
- [cousine/opencode-context.nvim](https://github.com/cousine/opencode-context.nvim) - Tmux integration plugin

### OpenCode CLI
- [sst/opencode](https://github.com/sst/opencode) - OpenCode CLI main repository
- [OpenCode Documentation](https://opencode.ai/docs/) - Official documentation
- [OpenCode Troubleshooting](https://opencode.ai/docs/troubleshooting/) - CLI troubleshooting guide

### Related Tools
- [lazy.nvim](https://lazy.folke.io/installation) - Modern Neovim plugin manager
- [snacks.nvim](https://github.com/folke/snacks.nvim) - Collection of Neovim utilities (used by NickvanDyke plugin)
- [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) - Markdown rendering (used by sudo-tee plugin)

### Guides and Tutorials
- [Complete Guide to Using OpenCode with Neovim & Tmux](https://keebsforall.com/blogs/mechanical-keyboards-101/complete-guide-to-using-opencode-with-neovim-tmux) - Comprehensive integration guide
- [nixvim OpenCode Plugin](https://nix-community.github.io/nixvim/plugins/opencode/index.html) - NixOS integration

---

## Research Methodology

This research was conducted through:

1. **Web Search**: Searched for opencode.nvim repositories, installation guides, and troubleshooting resources
2. **Repository Analysis**: Examined GitHub repositories for NickvanDyke/opencode.nvim, sudo-tee/opencode.nvim, kksimons/nvim-opencode, and cousine/opencode-context.nvim
3. **Documentation Review**: Analyzed README files, configuration examples, and issue trackers
4. **Cross-reference Validation**: Verified installation methods across multiple plugin managers (lazy.nvim, packer.nvim, vim-plug, nixvim)
5. **Troubleshooting Analysis**: Collected common issues from GitHub issues and community guides

---

## Sources

- [NickvanDyke/opencode.nvim GitHub Repository](https://github.com/NickvanDyke/opencode.nvim)
- [sudo-tee/opencode.nvim GitHub Repository](https://github.com/sudo-tee/opencode.nvim)
- [kksimons/nvim-opencode GitHub Repository](https://github.com/kksimons/nvim-opencode)
- [cousine/opencode-context.nvim GitHub Repository](https://github.com/cousine/opencode-context.nvim)
- [sst/opencode - The open source coding agent](https://github.com/sst/opencode)
- [lazy.nvim Installation Documentation](https://lazy.folke.io/installation)
- [Complete Guide to Using OpenCode with Neovim & Tmux](https://keebsforall.com/blogs/mechanical-keyboards-101/complete-guide-to-using-opencode-with-neovim-tmux)
- [nixvim OpenCode Plugin Documentation](https://nix-community.github.io/nixvim/plugins/opencode/index.html)
- [OpenCode Troubleshooting Documentation](https://opencode.ai/docs/troubleshooting/)
- [Neovim Plugin List - AI Tools](https://yutkat.github.io/my-neovim-pluginlist/ai.html)

---

**End of Report**
