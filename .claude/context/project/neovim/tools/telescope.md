# Telescope.nvim

## Overview
Telescope is a highly extensible fuzzy finder for Neovim. It provides a unified interface for searching files, buffers, grep results, and more.

## Setup

### Basic Configuration
```lua
return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  cmd = "Telescope",
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
  },
  opts = {
    defaults = {
      sorting_strategy = "ascending",
      layout_config = {
        horizontal = { prompt_position = "top" },
      },
    },
  },
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)
    telescope.load_extension("fzf")
  end,
}
```

## Built-in Pickers

### File Pickers
```lua
require("telescope.builtin").find_files()
require("telescope.builtin").git_files()
require("telescope.builtin").oldfiles()
```

### Grep Pickers
```lua
require("telescope.builtin").live_grep()
require("telescope.builtin").grep_string()
```

### Buffer/Tab Pickers
```lua
require("telescope.builtin").buffers()
require("telescope.builtin").current_buffer_fuzzy_find()
```

### LSP Pickers
```lua
require("telescope.builtin").lsp_references()
require("telescope.builtin").lsp_definitions()
require("telescope.builtin").lsp_document_symbols()
require("telescope.builtin").diagnostics()
```

### Git Pickers
```lua
require("telescope.builtin").git_commits()
require("telescope.builtin").git_branches()
require("telescope.builtin").git_status()
```

## Custom Pickers

### Basic Picker Structure
```lua
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function my_picker(opts)
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = "My Picker",
    finder = finders.new_table({
      results = { "item1", "item2", "item3" },
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        print("Selected: " .. selection[1])
      end)
      return true
    end,
  }):find()
end
```

### Finder Types

#### Static Table Finder
```lua
finder = finders.new_table({
  results = { "a", "b", "c" },
})
```

#### Entry Maker
```lua
finder = finders.new_table({
  results = {
    { name = "Item 1", path = "/path/1" },
    { name = "Item 2", path = "/path/2" },
  },
  entry_maker = function(entry)
    return {
      value = entry,
      display = entry.name,
      ordinal = entry.name,
      path = entry.path,
    }
  end,
})
```

#### Async Job Finder
```lua
finder = finders.new_async_job({
  command_generator = function(prompt)
    return { "rg", "--files", "--glob", "*" .. prompt .. "*" }
  end,
  entry_maker = function(line)
    return {
      value = line,
      display = line,
      ordinal = line,
    }
  end,
})
```

## Previewers

### File Previewer
```lua
local previewers = require("telescope.previewers")

previewer = previewers.new_buffer_previewer({
  title = "File Preview",
  define_preview = function(self, entry, status)
    local content = vim.fn.readfile(entry.path)
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, content)
  end,
})
```

### Builtin Previewers
```lua
previewer = previewers.vim_buffer_cat.new(opts)
previewer = previewers.git_file_diff.new(opts)
```

## Sorters

### Available Sorters
```lua
local sorters = require("telescope.sorters")

sorter = sorters.get_generic_sorter(opts)      -- Basic fuzzy
sorter = sorters.get_fzy_sorter(opts)          -- fzy algorithm
sorter = sorters.fuzzy_with_index_bias(opts)   -- Prefers earlier matches
```

### FZF Native (Recommended)
```lua
-- After loading extension
sorter = require("telescope").extensions.fzf.native_fzf_sorter()
```

## Actions

### Default Actions
```lua
local actions = require("telescope.actions")

-- In attach_mappings
map("i", "<CR>", actions.select_default)
map("i", "<C-x>", actions.select_horizontal)
map("i", "<C-v>", actions.select_vertical)
map("i", "<C-t>", actions.select_tab)
map("i", "<C-c>", actions.close)
map("n", "q", actions.close)
```

### Custom Actions
```lua
attach_mappings = function(prompt_bufnr, map)
  map("i", "<C-y>", function()
    local selection = action_state.get_selected_entry()
    vim.fn.setreg("+", selection.value)
    actions.close(prompt_bufnr)
  end)
  return true  -- Use default mappings too
end
```

### Send to Quickfix
```lua
map("i", "<C-q>", actions.send_to_qflist + actions.open_qflist)
map("i", "<M-q>", actions.send_selected_to_qflist + actions.open_qflist)
```

## Configuration Options

### Layout Configuration
```lua
opts = {
  defaults = {
    layout_strategy = "horizontal",  -- or "vertical", "flex", "center"
    layout_config = {
      horizontal = {
        prompt_position = "top",
        preview_width = 0.55,
        results_width = 0.8,
      },
      vertical = {
        mirror = false,
      },
      width = 0.87,
      height = 0.80,
      preview_cutoff = 120,
    },
  },
}
```

### Sorting Configuration
```lua
opts = {
  defaults = {
    sorting_strategy = "ascending",  -- or "descending"
    selection_strategy = "reset",    -- or "follow", "row"
  },
}
```

### File Ignore Patterns
```lua
opts = {
  defaults = {
    file_ignore_patterns = {
      "node_modules",
      ".git/",
      "%.lock",
    },
  },
}
```

## Extensions

### Loading Extensions
```lua
config = function(_, opts)
  local telescope = require("telescope")
  telescope.setup(opts)

  -- Load extensions after setup
  telescope.load_extension("fzf")
  telescope.load_extension("file_browser")
end
```

### Common Extensions
| Extension | Purpose |
|-----------|---------|
| fzf-native | Faster sorting |
| file_browser | File browser |
| project | Project switching |
| frecency | Frequency/recency sort |
| ui-select | vim.ui.select |

### Using Extensions
```lua
-- Command
:Telescope file_browser

-- Lua
require("telescope").extensions.file_browser.file_browser()
```

## Themes

### Dropdown Theme
```lua
require("telescope.builtin").find_files(
  require("telescope.themes").get_dropdown({
    previewer = false,
  })
)
```

### Ivy Theme
```lua
require("telescope.builtin").find_files(
  require("telescope.themes").get_ivy()
)
```

### Cursor Theme
```lua
require("telescope.builtin").find_files(
  require("telescope.themes").get_cursor()
)
```

## Troubleshooting

### Debug Picker
```lua
:Telescope find_files debug=true
```

### Check Health
```vim
:checkhealth telescope
```

### Common Issues
1. **Slow**: Install fzf-native extension
2. **Missing icons**: Install nvim-web-devicons
3. **No previewer**: Check file is readable
4. **Extension not found**: Load after telescope.setup()
