# Jupyter Notebook Support for NeoVim

This plugin provides enhanced Jupyter notebook support in NeoVim with features like cell navigation, execution, and VSCode-like visual styling. It leverages several underlying components to provide a cohesive experience for working with `.ipynb` files and Jupyter-style code blocks in Markdown.

## Features

- 🔍 Visual separation of cells with distinct styling
- 📊 Different highlighting for code and markdown cells
- 🚀 Notebook cell navigation and execution
- 🔄 Conversion between `.ipynb` and other formats (`.md`, `.py`)
- 🔌 Integration with IPython REPL
- ⚙️ Customizable styling and appearance

## Dependencies

This plugin integrates with the following packages:

- [NotebookNavigator.nvim](https://github.com/GCBallesteros/NotebookNavigator.nvim) - For cell navigation and execution
- [jupytext.nvim](https://github.com/GCBallesteros/jupytext.nvim) - For converting between file formats
- [iron.nvim](https://github.com/Vigemus/iron.nvim) - For REPL interaction
- [mini.hipatterns](https://github.com/echasnovski/mini.hipatterns) - For enhanced highlighting

## Key Mappings

Keymaps are defined in the `which-key.lua` configuration. The following mappings are available under the `<leader>j` prefix:

| Mapping | Description |
|---------|-------------|
| `<leader>je` | Execute current cell |
| `<leader>jj` | Move to next cell |
| `<leader>jk` | Move to previous cell |
| `<leader>jn` | Execute cell and move to next |
| `<leader>jo` | Insert cell below current |
| `<leader>jO` | Insert cell above current |
| `<leader>js` | Split current cell |
| `<leader>jc` | Comment current cell |
| `<leader>ji` | Start IPython REPL |
| `<leader>jl` | Send line to REPL |
| `<leader>jf` | Send file to REPL |
| `<leader>jq` | Exit REPL |
| `<leader>jr` | Clear REPL |
| `<leader>jv` | Send visual selection to REPL |
| `<leader>jp` | Convert Python to notebook |
| `<leader>jm` | Convert Markdown to notebook |
| `<leader>jP` | Convert notebook to Python |
| `<leader>jM` | Convert notebook to Markdown |

## Customizing Appearance

The Jupyter notebook styling can be customized by modifying the highlight groups and styling options in the `styling.lua` file.

### Highlight Groups

You can modify the appearance by changing the highlight group definitions in the `setup_highlights()` function in `styling.lua`:

```lua
-- Find this section in the styling.lua file
local function setup_highlights()
  -- Cell separator line
  vim.api.nvim_set_hl(0, "JupyterCellSeparator", { fg = "#6272a4", bold = true })
  -- Code cell background
  vim.api.nvim_set_hl(0, "JupyterCodeCell", { bg = "#1E1E2E" })
  -- Markdown cell background
  vim.api.nvim_set_hl(0, "JupyterMarkdownCell", { bg = "#2D2D3D" })
  -- Cell icons
  vim.api.nvim_set_hl(0, "JupyterCellIcon", { fg = "#89b4fa", bold = true })
  -- Active cell
  vim.api.nvim_set_hl(0, "JupyterActiveCell", { bg = "#363654" })
end
```

### Color Reference

The default colors are based on the Catppuccin Mocha theme. Here's what each color represents:

- `#6272a4`: Blue-purple for cell separators
- `#1E1E2E`: Dark background for code cells
- `#2D2D3D`: Slightly lighter background for markdown cells
- `#89b4fa`: Light blue for cell icons
- `#363654`: Highlighted background for active cells

### Customizing Cell Markers

You can change the cell marker icons by modifying the `setup_signs()` function:

```lua
-- Find this section in the styling.lua file
local function setup_signs()
  vim.fn.sign_define("JupyterCodeSign", { text = "📊", texthl = "JupyterCellIcon" })
  vim.fn.sign_define("JupyterMarkdownSign", { text = "📝", texthl = "JupyterCellIcon" })
  vim.fn.sign_define("JupyterSeparatorSign", { text = "▶", texthl = "JupyterCellIcon" })
end
```

### Customizing Cell Separators

You can change the appearance of cell separators by modifying the virtual text used:

```lua
-- Find this section in the styling.lua file (inside the apply_styling function)
-- Add horizontal separator
vim.api.nvim_buf_set_extmark(bufnr, ns_id, i-1, 0, {
  virt_text = {{"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", "JupyterCellSeparator"}},
  virt_text_pos = "overlay",
  priority = 100,
})
```

### Theme Integration

The Jupyter styling automatically updates when the colorscheme changes due to the colorscheme autocmd:

```lua
-- Apply styling after colorscheme changes
vim.api.nvim_create_autocmd({"ColorScheme"}, {
  group = augroup,
  callback = function()
    pcall(function()
      local styling = require("neotex.plugins.jupyter.styling")
      styling.setup()
    end)
  end
})
```

## Examples

### Integrating with a Custom Theme

You can create a function that sets up Jupyter highlight groups based on your current theme:

```lua
-- Add this to your theme setup code
local function setup_jupyter_theme()
  local bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg or "#000000"
  local fg = vim.api.nvim_get_hl(0, { name = "Normal" }).fg or "#ffffff"
  
  -- Make code cells slightly lighter than the background
  local code_bg = increase_color_brightness(bg, 10)
  -- Make markdown cells even lighter
  local md_bg = increase_color_brightness(bg, 20)
  
  -- Set highlight groups
  vim.api.nvim_set_hl(0, "JupyterCellSeparator", { fg = fg, bold = true })
  vim.api.nvim_set_hl(0, "JupyterCodeCell", { bg = code_bg })
  vim.api.nvim_set_hl(0, "JupyterMarkdownCell", { bg = md_bg })
  vim.api.nvim_set_hl(0, "JupyterCellIcon", { fg = "#89b4fa", bold = true })
end

-- Call this function after loading your theme
setup_jupyter_theme()
```

### Custom Separator Style

To use a different separator style:

```lua
-- Change the separator character (e.g., to a double line)
vim.api.nvim_buf_set_extmark(bufnr, ns_id, i-1, 0, {
  virt_text = {{"═════════════════════════════════════════════════", "JupyterCellSeparator"}},
  virt_text_pos = "overlay",
  priority = 100,
})
```

## File Structure

- `init.lua` - Main plugin file and Lazy.nvim specification
- `styling.lua` - Visual styling implementation
- `autocommands.lua` - Event handlers for loading styling

## Troubleshooting

If the styling doesn't appear:

1. Ensure the sign column is enabled with `:set signcolumn=yes:1`
2. Check if the highlight groups are defined correctly with `:hi JupyterCodeCell`
3. Make sure the autocmds are loaded by running `:lua require("neotex.plugins.jupyter.styling").setup()`