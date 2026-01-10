# Plugin Development Process

## Plugin Structure

### Minimal Plugin Layout
```
my-plugin.nvim/
├── lua/
│   └── my-plugin/
│       └── init.lua       -- Main module
├── plugin/
│   └── my-plugin.lua      -- Auto-loaded on startup (optional)
├── doc/
│   └── my-plugin.txt      -- Help documentation
├── tests/
│   └── my-plugin_spec.lua -- Tests
└── README.md
```

### Full Plugin Layout
```
my-plugin.nvim/
├── lua/
│   └── my-plugin/
│       ├── init.lua       -- Main entry (setup function)
│       ├── config.lua     -- Configuration handling
│       ├── commands.lua   -- User commands
│       ├── keymaps.lua    -- Keymap setup
│       ├── autocmds.lua   -- Autocommands
│       └── utils.lua      -- Utility functions
├── plugin/
│   └── my-plugin.lua      -- Vim plugin loader
├── after/
│   └── ftplugin/          -- Filetype overrides
├── doc/
│   └── my-plugin.txt      -- Vimdoc help
├── tests/
│   ├── minimal_init.lua   -- Test configuration
│   └── my-plugin_spec.lua -- Test files
├── .github/
│   └── workflows/
│       └── ci.yml         -- CI configuration
├── LICENSE
└── README.md
```

## Main Module Pattern

### init.lua
```lua
local M = {}

-- Default configuration
local defaults = {
  enabled = true,
  feature_x = false,
  mappings = {
    toggle = "<leader>m",
  },
}

-- Current config
M.config = {}

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})

  if not M.config.enabled then
    return
  end

  -- Initialize features
  require("my-plugin.commands").setup()
  require("my-plugin.keymaps").setup(M.config.mappings)
end

-- Public API functions
function M.toggle()
  -- Implementation
end

return M
```

### config.lua
```lua
local M = {}

M.defaults = {
  enabled = true,
  debug = false,
  options = {
    timeout = 1000,
  },
}

function M.get(key)
  local config = require("my-plugin").config
  if key then
    return config[key]
  end
  return config
end

function M.set(key, value)
  local config = require("my-plugin").config
  config[key] = value
end

return M
```

## Testing Workflow

### Test File Structure
```lua
-- tests/my-plugin_spec.lua
describe("my-plugin", function()
  local plugin = require("my-plugin")

  before_each(function()
    -- Reset state before each test
    plugin.setup({})
  end)

  describe("setup", function()
    it("uses default config when no options provided", function()
      plugin.setup()
      assert.is_true(plugin.config.enabled)
    end)

    it("merges user config with defaults", function()
      plugin.setup({ debug = true })
      assert.is_true(plugin.config.debug)
      assert.is_true(plugin.config.enabled)  -- Default preserved
    end)
  end)

  describe("toggle", function()
    it("toggles state", function()
      local initial = plugin.is_active()
      plugin.toggle()
      assert.not_equals(initial, plugin.is_active())
    end)
  end)
end)
```

### Minimal Test Init
```lua
-- tests/minimal_init.lua
local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
vim.opt.rtp:prepend(plenary_path)

-- Add plugin to runtime path
vim.opt.rtp:prepend(".")

-- Disable swap files for testing
vim.opt.swapfile = false
```

### Running Tests
```bash
# Run all tests
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

# Run specific test file
nvim --headless -c "PlenaryBustedFile tests/my-plugin_spec.lua"
```

## Documentation

### Vimdoc Format
```
*my-plugin.txt*    My Plugin description

CONTENTS                                              *my-plugin-contents*

1. Introduction ......................................... |my-plugin|
2. Setup .......................................... |my-plugin-setup|
3. Commands ...................................... |my-plugin-commands|
4. API ................................................ |my-plugin-api|

==============================================================================
1. INTRODUCTION                                             *my-plugin*

Description of what the plugin does.

==============================================================================
2. SETUP                                               *my-plugin-setup*

Call the setup function with options:
>lua
    require("my-plugin").setup({
      enabled = true,
    })
<
                                               *my-plugin-config-enabled*
enabled ~
    Enable the plugin. Default: `true`

==============================================================================
3. COMMANDS                                         *my-plugin-commands*

                                                          *:MyPluginToggle*
:MyPluginToggle
    Toggle the plugin state.

==============================================================================
4. API                                                    *my-plugin-api*

                                                     *my-plugin.toggle()*
toggle()
    Toggle the active state.

vim:tw=78:ts=8:ft=help:norl:
```

### Generate Helptags
```vim
:helptags doc/
```

## Publishing

### Pre-Publish Checklist
1. [ ] Tests pass
2. [ ] Documentation complete
3. [ ] README has usage examples
4. [ ] LICENSE file present
5. [ ] No hardcoded paths or user-specific config
6. [ ] Works with default Neovim (no hidden dependencies)

### README Template
```markdown
# my-plugin.nvim

Brief description.

## Features

- Feature 1
- Feature 2

## Requirements

- Neovim >= 0.9.0

## Installation

### lazy.nvim
\`\`\`lua
{
  "author/my-plugin.nvim",
  opts = {},
}
\`\`\`

## Configuration

\`\`\`lua
require("my-plugin").setup({
  enabled = true,
})
\`\`\`

## Usage

Usage examples.

## License

MIT
```

### CI Configuration
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: rhysd/action-setup-vim@v1
        with:
          neovim: true
          version: stable

      - name: Install plenary
        run: |
          git clone --depth 1 https://github.com/nvim-lua/plenary.nvim \
            ~/.local/share/nvim/lazy/plenary.nvim

      - name: Run tests
        run: |
          nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: JohnnyMorganz/stylua-action@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          args: --check lua/
```

## Best Practices

### Lazy Loading Support
```lua
-- In init.lua
function M.setup(opts)
  -- Defer heavy initialization
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      M._do_heavy_init()
    end,
  })
end
```

### Avoid Global State
```lua
-- Bad: global state
_G.my_plugin_state = {}

-- Good: module-local state
local M = {}
M._state = {}
```

### Error Handling
```lua
function M.risky_operation()
  local ok, result = pcall(function()
    -- Potentially failing code
  end)

  if not ok then
    vim.notify("my-plugin: " .. result, vim.log.levels.ERROR)
    return nil
  end

  return result
end
```

### User-Friendly Errors
```lua
function M.setup(opts)
  vim.validate({
    enabled = { opts.enabled, "boolean", true },
    timeout = { opts.timeout, "number", true },
  })
end
```
