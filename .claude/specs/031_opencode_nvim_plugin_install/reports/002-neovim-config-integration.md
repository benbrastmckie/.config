# Research Report: Neovim Configuration Integration for opencode.nvim

**Date**: 2025-12-10
**Topic**: Neovim Configuration Integration
**Researcher**: Research Specialist Agent

## Executive Summary

This report documents configuration options and integration patterns for opencode.nvim plugins within Neovim. Three distinct plugins exist for OpenCode integration, each with different feature sets and configuration approaches. The user's existing Neovim configuration uses lazy.nvim with a modular structure under `lua/neotex/plugins/`, organized by category (ai, tools, editor, text, ui, lsp).

## Research Findings

### 1. Available opencode.nvim Plugins

Three separate plugins provide OpenCode integration, each with distinct features:

#### 1.1 NickvanDyke/opencode.nvim

**Repository**: https://github.com/NickvanDyke/opencode.nvim

**Key Features**:
- Auto-connects to opencode instances running in Neovim's CWD
- Prompt library with context injection (buffer, cursor, selection, diagnostics)
- Real-time buffer reload when opencode edits files
- Statusline integration
- Multiple provider support (snacks, kitty, wezterm, tmux, custom)

**Configuration Pattern**:
Uses `vim.g.opencode_opts` rather than a traditional `setup()` function:

```lua
vim.g.opencode_opts = {
  -- Configuration options
}
vim.o.autoread = true
```

**Dependencies**:
- Required: `folke/snacks.nvim` (for `ask()`, `select()`, terminal provider)
- Optional: `folke/lualine.nvim` (for statusline integration)

**Recommended Keymaps**:
| Mapping | Function | Purpose |
|---------|----------|---------|
| `<C-a>` | `ask()` | Query opencode with context |
| `<C-x>` | `select()` | Execute opencode action |
| `ga` | `prompt()` | Add context to opencode |
| `<C-.>` | `toggle()` | Show/hide opencode |
| `<S-C-u>` | `command("session.half.page.up")` | Scroll messages up |
| `<S-C-d>` | `command("session.half.page.down")` | Scroll messages down |

**Core Commands**:
- Session: `list`, `new`, `share`, `interrupt`, `compact`, `page.up/down`, `half.page.up/down`, `first`, `last`, `undo`, `redo`
- Prompt: `submit`, `clear`
- Agent: `cycle`

**Context Placeholders** (usable in prompts):
- `@this`: Selection or cursor position
- `@buffer`: Current buffer
- `@buffers`: Open buffers
- `@visible`: Visible text
- `@diagnostics`, `@quickfix`, `@diff`, `@grapple`

**Provider Configurations**:
- **snacks.terminal**: Built-in terminal management
- **kitty**: Requires "remote control via a socket" enabled
- **wezterm**: Direction, top_level, and percent customization
- **tmux**: Terminal multiplexer support
- **custom**: User-defined provider functions

**Health Check**: Run `:checkhealth opencode` after setup

#### 1.2 sudo-tee/opencode.nvim

**Repository**: https://github.com/sudo-tee/opencode.nvim

**Key Features**:
- Automatic workspace snapshots (lightweight git-like commits)
- Restore points before revert operations
- Comprehensive keymap organization (editor, input_window, output_window, permission)
- Icon configuration (nerdfonts/text presets)
- Picker integration (telescope, fzf, mini.pick, snacks, select)
- Completion integration (blink, nvim-cmp, vim_complete)

**Configuration Pattern**:
Uses standard `setup()` function:

```lua
require('opencode').setup({
  preferred_picker = 'telescope',        -- or 'fzf', 'mini.pick', 'snacks', 'select'
  preferred_completion = 'blink',        -- or 'nvim-cmp', 'vim_complete'
  default_global_keymaps = true,         -- enable/disable default keybindings
  default_mode = 'build',                -- or 'plan', or custom agent config
  keymap_prefix = '<leader>o',           -- global command prefix
})
```

**Dependencies**:
- `nvim-lua/plenary.nvim`
- `MeanderingProgrammer/render-markdown.nvim`
- `saghen/blink.cmp` (or completion plugin of choice)

**Default Keymaps** (`<leader>o` prefix):
- `<leader>og`: Toggle UI
- `<leader>oi`: Open input window
- `<leader>oo`: Open output window
- `<leader>os`: Select session
- `<leader>oR`: Rename session
- `<leader>od`: Open diff view
- `<leader>oc`: Close diff view

**Input Window Keymaps**:
- `<CR>`: Submit (normal/insert modes)
- `~`: File mentions (insert mode)
- `/`: Slash commands (insert mode)
- `<up>`/`<down>`: History navigation

**Output Window Keymaps**:
- `]]`/`[[`: Message navigation
- `i`: Focus input
- `<tab>`: Pane toggle

**Snapshot & Restore Features**:
- `diff_revert_all_last_prompt`: Revert changes since last prompt
- `diff_restore_snapshot_file`: Restore individual file to checkpoint
- `diff_restore_snapshot_all`: Restore all files to restore point
- Distinguishes between session-level and prompt-level changes

**Icon Configuration**:
```lua
icons = {
  preset = 'nerdfonts',  -- or 'text'
  overrides = {}         -- per-key customization
}
```

**UI Configuration**:
```lua
ui = {
  window_width = 0.40,        -- 40% default
  zoom_width = 0.8,           -- 80% when zoomed
  debounce_ms = 250,          -- markdown rendering debounce
}
```

#### 1.3 kksimons/nvim-opencode

**Repository**: https://github.com/kksimons/nvim-opencode

**Key Features**:
- Terminal management with toggle
- Text sharing (selections and clipboard with accurate line counting)
- File context management (add/remove/toggle files)
- Auto-start capability
- Simple split configuration

**Configuration Pattern**:
```lua
require("opencode").setup({
  auto_start = true,                    -- Enable auto-start on plugin load
  terminal_cmd = nil,                   -- Custom command path (nil = auto-detect)
  terminal = {
    split_side = "right",               -- "left" or "right"
    split_width_percentage = 0.30,      -- 30% of screen width
  },
})
```

**Terminal Command Detection Order** (when `terminal_cmd = nil`):
1. `opencode` in PATH
2. `~/.local/bin/opencode`
3. `/usr/local/bin/opencode`
4. `/opt/homebrew/bin/opencode`

**Key Mappings**:
- `<leader>A`: Toggle OpenCode terminal (show/hide while preserving session)
- `1`: Focus editor (intelligently bypasses file explorers)
- `9`: Focus OpenCode terminal
- `a` (visual mode): Send selected text with accurate line counting
- `a` (normal mode): Transmit clipboard/yank register content
- `ESC ESC`: Clear current input line
- `Ctrl+U`: Clear entire input

**File Context Management**:
- `<leader>+`: Add current file (prevents duplicates)
- `<leader>-`: Remove current file
- `<leader>=`: Toggle file context status

### 2. User's Existing Neovim Configuration Structure

**Configuration Entry Point**: `/home/benjamin/.config/nvim/init.lua`

**Architecture**:
- Leader key: `<Space>` (global), `,` (local leader for filetype-specific)
- Plugin manager: lazy.nvim
- Bootstrap module: `neotex/bootstrap.lua` handles initialization
- Configuration modules: `neotex/config/`
- Plugin specifications: `neotex/plugins/`

**Plugin Organization**:
```
nvim/lua/neotex/plugins/
├── ai/           # AI plugins (avante, claudecode, goose, lectic, mcp-hub)
│   ├── init.lua  # AI plugin loader
│   ├── avante.lua
│   ├── claudecode.lua
│   ├── goose/
│   └── ...
├── tools/        # Tool integration plugins
│   ├── init.lua  # Tools plugin loader
│   ├── gitsigns.lua
│   ├── yanky.lua
│   ├── himalaya/
│   └── ...
├── editor/       # Editor enhancement plugins
├── text/         # Text format-specific plugins
├── ui/           # UI enhancement plugins
└── lsp/          # LSP configuration
```

**Plugin Loading Pattern** (from `bootstrap.lua`):
```lua
-- Explicit loading for AI and tools categories
local tools_ok, tools_plugins = pcall(require, "neotex.plugins.tools")
if tools_ok and type(tools_plugins) == "table" then
  vim.list_extend(plugins, tools_plugins)
end

local ai_ok, ai_plugins = pcall(require, "neotex.plugins.ai")
if ai_ok and type(ai_plugins) == "table" then
  vim.list_extend(plugins, ai_plugins)
end
```

**AI Plugin Loader** (`neotex/plugins/ai/init.lua`):
```lua
local ai_plugins = {
  "avante",
  "claudecode",
  "goose",
  "lectic",
  "mcp-hub",
}

for _, plugin_name in ipairs(ai_plugins) do
  local plugin_spec = safe_require("neotex.plugins.ai." .. plugin_name)
  if plugin_spec then
    table.insert(plugins, plugin_spec)
  end
end

return plugins
```

**Example Plugin Spec Pattern** (from `claudecode.lua`):
```lua
return {
  "greggh/claude-code.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    -- Configuration options
  },
  keys = {},
  config = function(_, opts)
    require("claude-code").setup(opts)
  end,
}
```

### 3. Integration Patterns for User's Configuration

Based on the user's existing structure, here are recommended integration patterns for each opencode.nvim variant:

#### 3.1 Integration Pattern for NickvanDyke/opencode.nvim

**File Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/opencode.lua`

```lua
return {
  "NickvanDyke/opencode.nvim",
  event = "VeryLazy",
  dependencies = {
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  init = function()
    -- Configure via vim.g before plugin loads
    vim.g.opencode_opts = {
      -- Provider management
      provider = {
        type = "snacks",  -- or "kitty", "wezterm", "tmux", "custom"
      },

      -- Event handling
      events = {
        reload_on_edit = true,
        permission_requests = "notify",
      },

      -- UI customization
      ui = {
        input_provider = "snacks",
        picker_provider = "snacks",
      },

      -- Context injection defaults
      context = {
        include_diagnostics = true,
        include_buffer = true,
        include_visible = true,
      },
    }

    -- Enable autoread for file change detection
    vim.o.autoread = true
  end,
  keys = {
    { "<C-a>", function() require("opencode").ask() end, desc = "OpenCode: Ask with context" },
    { "<C-x>", function() require("opencode").select() end, desc = "OpenCode: Select action" },
    { "ga", function() require("opencode").prompt() end, desc = "OpenCode: Add context" },
    { "<C-.>", function() require("opencode").toggle() end, desc = "OpenCode: Toggle" },
    { "<S-C-u>", function() require("opencode").command("session.half.page.up") end, desc = "OpenCode: Scroll up" },
    { "<S-C-d>", function() require("opencode").command("session.half.page.down") end, desc = "OpenCode: Scroll down" },
  },
  config = function()
    -- Configuration already set via vim.g.opencode_opts in init
    -- Run health check on first load (optional)
    vim.defer_fn(function()
      vim.cmd("checkhealth opencode")
    end, 1000)
  end,
}
```

**Integration Steps**:
1. Create file at `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/opencode.lua`
2. Add `"opencode"` to ai_plugins list in `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/init.lua`:
   ```lua
   local ai_plugins = {
     "avante",
     "claudecode",
     "goose",
     "lectic",
     "mcp-hub",
     "opencode",  -- Add this line
   }
   ```
3. Restart Neovim and run `:Lazy sync`
4. Verify with `:checkhealth opencode`

#### 3.2 Integration Pattern for sudo-tee/opencode.nvim

**File Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/opencode.lua`

```lua
return {
  "sudo-tee/opencode.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MeanderingProgrammer/render-markdown.nvim",
    "saghen/blink.cmp",  -- User already has blink.cmp
  },
  opts = {
    -- Picker and completion
    preferred_picker = "telescope",      -- Matches user's existing telescope setup
    preferred_completion = "blink",      -- User already uses blink.cmp

    -- Default behavior
    default_global_keymaps = true,
    default_mode = "build",
    keymap_prefix = "<leader>o",         -- Matches user's tools keymap pattern

    -- UI configuration
    ui = {
      window_width = 0.40,               -- Matches claudecode config (40%)
      zoom_width = 0.8,
      debounce_ms = 250,
    },

    -- Icon configuration (no emojis per user's standards)
    icons = {
      preset = "text",                   -- Text preset to avoid emoji issues
      overrides = {},
    },

    -- Keymaps (editor level)
    keymaps = {
      editor = {
        toggle_ui = "<leader>og",
        open_input = "<leader>oi",
        open_output = "<leader>oo",
        select_session = "<leader>os",
        rename_session = "<leader>oR",
        diff_open = "<leader>od",
        diff_close = "<leader>oc",
      },
      input_window = {
        submit_normal = "<CR>",
        submit_insert = "<CR>",
        file_mentions = "~",
        slash_commands = "/",
        history_up = "<up>",
        history_down = "<down>",
      },
      output_window = {
        next_message = "]]",
        prev_message = "[[",
        focus_input = "i",
        toggle_pane = "<tab>",
      },
    },
  },
  config = function(_, opts)
    require("opencode").setup(opts)
  end,
}
```

**Integration Steps**:
1. Create file at `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/opencode.lua`
2. Add `"opencode"` to ai_plugins list in `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/init.lua`
3. Ensure `render-markdown.nvim` is available (may already be installed for avante)
4. Restart Neovim and run `:Lazy sync`

#### 3.3 Integration Pattern for kksimons/nvim-opencode

**File Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/opencode.lua`

```lua
return {
  "kksimons/nvim-opencode",
  event = "VeryLazy",
  opts = {
    auto_start = true,
    terminal_cmd = nil,  -- Auto-detect opencode installation
    terminal = {
      split_side = "right",
      split_width_percentage = 0.30,
    },
  },
  keys = {
    { "<leader>A", desc = "OpenCode: Toggle terminal" },
    { "1", desc = "OpenCode: Focus editor" },
    { "9", desc = "OpenCode: Focus terminal" },
    { "a", mode = "v", desc = "OpenCode: Send selection" },
    { "a", mode = "n", desc = "OpenCode: Send clipboard" },
    { "<leader>+", desc = "OpenCode: Add current file" },
    { "<leader>-", desc = "OpenCode: Remove current file" },
    { "<leader>=", desc = "OpenCode: Toggle file context" },
  },
  config = function(_, opts)
    require("opencode").setup(opts)
  end,
}
```

**Integration Steps**:
1. Create file at `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/opencode.lua`
2. Add `"opencode"` to ai_plugins list in `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/init.lua`
3. Restart Neovim and run `:Lazy sync`

### 4. Configuration Best Practices for User's Setup

#### 4.1 Keymap Namespace Management

The user's configuration uses:
- `<Space>` (leader): Global commands
- `<leader>h`: Avante (AI assistant)
- `<leader>c`: Claude Code (terminal AI)
- `<leader>g`: Git/Goose

**Recommendations**:
- **NickvanDyke/opencode.nvim**: Use `<C-a>`, `<C-x>`, `ga`, `<C-.>` (no conflicts)
- **sudo-tee/opencode.nvim**: Use `<leader>o` prefix (matches tools pattern)
- **kksimons/nvim-opencode**: Use `<leader>A` (capital A to avoid conflicts)

#### 4.2 Terminal Configuration Alignment

User's claudecode config:
```lua
window = {
  split_ratio = 0.40,        -- 40% width
  position = "vertical",     -- Vertical split
}
```

**Recommendations**:
- Match 40% width for consistency: `split_width_percentage = 0.40` or `window_width = 0.40`
- Use right-side positioning to match existing AI tools
- Enable auto-insert mode for terminal consistency

#### 4.3 Emoji and Encoding Standards

From user's nvim/CLAUDE.md:
> **NO EMOJIS IN FILE CONTENT** - they can cause bad characters and encoding issues when saved to disk.

**Recommendations**:
- For sudo-tee/opencode.nvim: Use `icons = { preset = "text" }` instead of "nerdfonts"
- Avoid emoji-based UI indicators in saved configurations
- Runtime UI elements (notifications, pickers) can use emojis as they're not saved

#### 4.4 Plugin Loading Order

User's bootstrap explicitly loads AI plugins:
```lua
local ai_ok, ai_plugins = pcall(require, "neotex.plugins.ai")
if ai_ok and type(ai_plugins) == "table" then
  vim.list_extend(plugins, ai_plugins)
end
```

**Recommendations**:
1. Add opencode to ai_plugins list in `neotex/plugins/ai/init.lua`
2. Use `event = "VeryLazy"` for deferred loading (matches other AI plugins)
3. Ensure dependencies are loaded before main plugin (lazy.nvim handles this)

#### 4.5 Error Handling and Health Checks

User's config uses `safe_require` pattern:
```lua
local function safe_require(module)
  local ok, result = pcall(require, module)
  if not ok then
    vim.notify("Failed to load plugin module: " .. module, vim.log.levels.WARN)
    return {}
  end
  return result
end
```

**Recommendations**:
- For NickvanDyke/opencode.nvim: Run `:checkhealth opencode` after setup
- Add health check to config function:
  ```lua
  config = function()
    vim.defer_fn(function()
      vim.cmd("checkhealth opencode")
    end, 1000)
  end
  ```
- Use `pcall` for plugin initialization in case of missing dependencies

### 5. Comparison Matrix

| Feature | NickvanDyke | sudo-tee | kksimons |
|---------|-------------|----------|----------|
| **Config Pattern** | `vim.g.opencode_opts` | `setup()` function | `setup()` function |
| **Provider Support** | Multiple (snacks, kitty, wezterm, tmux) | Single (built-in) | Single (built-in) |
| **Prompt Library** | Yes (with context placeholders) | No | No |
| **Snapshots/Restore** | No | Yes (git-like checkpoints) | No |
| **Picker Integration** | snacks only | telescope, fzf, mini.pick, snacks | None |
| **Completion Integration** | None | blink, nvim-cmp, vim_complete | None |
| **File Context Mgmt** | Via @buffer/@buffers placeholders | No | Explicit add/remove commands |
| **Statusline Integration** | Yes (lualine) | No | No |
| **Terminal Management** | Provider-dependent | Built-in split | Built-in split |
| **Real-time Buffer Reload** | Yes | No | No |
| **Dependencies** | snacks.nvim (required) | plenary, render-markdown, blink | None |
| **Complexity** | High (many features) | Medium (snapshot system) | Low (simple terminal) |
| **Best For** | Power users, advanced workflows | Snapshot/restore workflows | Simple terminal integration |

### 6. Recommendation for User

Given the user's configuration characteristics:
- Uses lazy.nvim with modular plugin structure
- Already has avante (AI sidebar), claudecode (terminal AI), goose, lectic
- Uses blink.cmp for completion
- Uses telescope for fuzzy finding
- Has strict emoji/encoding standards
- Prefers 40% split width for AI tools

**Recommended Plugin**: **sudo-tee/opencode.nvim**

**Rationale**:
1. **Picker/Completion Integration**: Works with user's existing telescope and blink.cmp
2. **Text Preset**: Supports emoji-free configuration (`icons = { preset = "text" }`)
3. **Standard setup() Pattern**: Matches user's existing plugin patterns (avante, claudecode)
4. **Snapshot Features**: Adds value beyond existing tools (workspace checkpoints)
5. **Keymap Namespace**: `<leader>o` fits naturally with existing tool keymaps
6. **Split Configuration**: Easy to match 40% width standard

**Alternative**: **NickvanDyke/opencode.nvim** if user needs:
- Multiple terminal provider support (kitty, wezterm)
- Prompt library with context injection
- Statusline integration
- Real-time buffer reload on external edits

**Not Recommended**: **kksimons/nvim-opencode** (too simple, features overlap with existing tools)

### 7. Implementation Checklist

For sudo-tee/opencode.nvim integration:

- [ ] Create `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/opencode.lua`
- [ ] Add `"opencode"` to ai_plugins list in `neotex/plugins/ai/init.lua`
- [ ] Configure with text preset: `icons = { preset = "text" }`
- [ ] Set window_width to 0.40 to match existing AI tools
- [ ] Set keymap_prefix to `<leader>o`
- [ ] Configure preferred_picker as "telescope"
- [ ] Configure preferred_completion as "blink"
- [ ] Verify render-markdown.nvim dependency (may already exist from avante)
- [ ] Restart Neovim and run `:Lazy sync`
- [ ] Test keymaps: `<leader>og` (toggle), `<leader>oi` (input), `<leader>oo` (output)
- [ ] Test snapshot features: `<leader>od` (diff), `<leader>oc` (close diff)

## Sources

- [NickvanDyke/opencode.nvim GitHub Repository](https://github.com/NickvanDyke/opencode.nvim)
- [sudo-tee/opencode.nvim GitHub Repository](https://github.com/sudo-tee/opencode.nvim)
- [kksimons/nvim-opencode GitHub Repository](https://github.com/kksimons/nvim-opencode)
- [Complete Guide to Using OpenCode with Neovim & Tmux](https://keebsforall.com/blogs/mechanical-keyboards-101/complete-guide-to-using-opencode-with-neovim-tmux)
- [opencode.nvim: AI Coding Power for Neovim](https://collava.app/c/renews/nvim-articles-plugins-and-cool-stuff/sudo-tee-opencode-nvim-neovim-frontend-fyvjth5se8n)

## Appendices

### Appendix A: Full Configuration Examples

See Section 3 for complete integration patterns for each plugin variant.

### Appendix B: User's AI Plugin Inventory

Current AI plugins in user's configuration:
- **avante.nvim**: AI assistant with sidebar UI, MCP-Hub integration
- **claude-code.nvim**: Terminal-based Claude integration
- **goose**: AI development assistant
- **lectic**: Lean theorem prover assistant
- **mcp-hub.nvim**: Model Context Protocol hub for tool integration

### Appendix C: Keymap Conflict Analysis

| Keymap | Current Usage | OpenCode Variants |
|--------|---------------|-------------------|
| `<leader>h*` | Avante commands | None |
| `<leader>c*` | Claude Code | None |
| `<leader>g*` | Git/Goose | None |
| `<leader>o*` | **Available** | sudo-tee/opencode.nvim |
| `<leader>A` | **Available** | kksimons/nvim-opencode |
| `<C-a>` | **Available** | NickvanDyke/opencode.nvim |
| `<C-x>` | **Available** | NickvanDyke/opencode.nvim |
| `ga` | **Available** | NickvanDyke/opencode.nvim |

No conflicts detected for any variant with proper namespace selection.
