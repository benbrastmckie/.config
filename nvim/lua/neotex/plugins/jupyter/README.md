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

The styling system now automatically adapts to your current colorscheme! Highlight groups are defined dynamically based on your theme colors in the `setup_highlights()` function in `styling.lua`:

```lua
-- Find this section in the styling.lua file
local function setup_highlights()
  -- Get colors from current theme
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  local comment = vim.api.nvim_get_hl(0, { name = "Comment" })
  local func = vim.api.nvim_get_hl(0, { name = "Function" })
  
  -- Convert RGB values to hex if they exist, or use fallbacks
  local function to_hex(rgb)
    if not rgb then return nil end
    return string.format("#%06x", rgb)
  end
  
  local normal_bg = to_hex(normal.bg) or "#282828"
  local normal_fg = to_hex(normal.fg) or "#ebdbb2"
  local comment_fg = to_hex(comment.fg) or "#928374"
  local function_fg = to_hex(func.fg) or "#8ec07c"
  
  -- Cell separator line (use comment color)
  vim.api.nvim_set_hl(0, "JupyterCellSeparator", { fg = comment_fg, bold = true })
  
  -- Code cell background (slightly different from normal bg)
  vim.api.nvim_set_hl(0, "JupyterCodeCell", { bg = adjust_color(normal_bg, 10) })
  
  -- Markdown cell background (slightly lighter than code cells)
  vim.api.nvim_set_hl(0, "JupyterMarkdownCell", { bg = adjust_color(normal_bg, 20) })
  
  -- Cell icons (use function color)
  vim.api.nvim_set_hl(0, "JupyterCellIcon", { fg = function_fg, bold = true })
  
  -- Active cell (brighter than inactive cells)
  vim.api.nvim_set_hl(0, "JupyterActiveCell", { bg = adjust_color(normal_bg, 30) })
end
```

### Automatic Theme Integration

The Jupyter styling now automatically derives colors from your current theme:

- **Cell separators**: Uses your theme's Comment color
- **Code cell background**: Slightly brighter than your Normal background
- **Markdown cell background**: Even brighter than code cells for distinction
- **Cell icons**: Uses your theme's Function color
- **Active cell highlighting**: Automatically highlights the cell under your cursor

When you change colorschemes, the Jupyter styling will automatically update to match!

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

The Jupyter styling automatically updates when the colorscheme changes due to the colorscheme autocmd. The new implementation continuously monitors colorscheme changes:

```lua
-- Set up an autocmd to refresh highlights when colorscheme changes
vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = function()
    -- Re-setup all highlights with the new colorscheme
    setup_highlights()
    
    -- Reapply to all open buffers
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local bufname = vim.api.nvim_buf_get_name(buf)
      if bufname:match("%.ipynb$") and vim.api.nvim_buf_is_loaded(buf) then
        apply_styling(buf)
      end
    end
  end,
})
```

### Active Cell Highlighting

A new feature highlights the cell under your cursor as you navigate through the notebook:

```lua
-- Highlight active cell when cursor moves
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
  pattern = "*.ipynb",
  group = group,
  callback = function()
    highlight_active_cell()
  end
})
```

The active cell is highlighted with the `JupyterActiveCell` highlight group, which is automatically derived from your theme but with increased brightness for better visibility.

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