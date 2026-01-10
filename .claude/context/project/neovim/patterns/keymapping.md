# Keymapping Patterns

## vim.keymap.set API

### Basic Syntax
```lua
vim.keymap.set(mode, lhs, rhs, opts)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| mode | string/table | Mode(s): "n", "i", "v", "x", "s", "o", "t", "c" |
| lhs | string | Key sequence to trigger |
| rhs | string/function | Command or function to execute |
| opts | table | Options (desc, buffer, silent, etc.) |

### Mode Characters
| Mode | Character | Description |
|------|-----------|-------------|
| Normal | "n" | Normal mode |
| Insert | "i" | Insert mode |
| Visual | "v" | Visual and Select mode |
| Visual only | "x" | Visual mode only |
| Select | "s" | Select mode only |
| Operator | "o" | Operator-pending mode |
| Terminal | "t" | Terminal mode |
| Command | "c" | Command-line mode |

## Common Patterns

### String Command
```lua
vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })
```

### Lua Function Callback
```lua
vim.keymap.set("n", "<leader>ff", function()
  require("telescope.builtin").find_files()
end, { desc = "Find files" })
```

### Multiple Modes
```lua
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
```

### Buffer-Local Keymap
```lua
vim.keymap.set("n", "<leader>t", function()
  vim.cmd("terminal")
end, { buffer = true, desc = "Open terminal" })

-- With specific buffer number
vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr })
```

## Option Reference

### Common Options
```lua
{
  desc = "Description",   -- For which-key/documentation
  buffer = true,          -- Buffer-local (true or bufnr)
  silent = true,          -- Don't echo command
  noremap = true,         -- Non-recursive (default)
  nowait = true,          -- Don't wait for more keys
  expr = true,            -- Evaluate rhs as expression
  remap = true,           -- Allow recursive mapping
}
```

### Expression Mappings
```lua
-- Move by display lines when no count
vim.keymap.set("n", "j", function()
  return vim.v.count == 0 and "gj" or "j"
end, { expr = true, desc = "Down (display line)" })

-- Or with string expression
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
```

## Leader Key Patterns

### Define Leader
```lua
-- In init.lua, BEFORE loading plugins
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
```

### Structured Leader Mappings
```lua
-- Group by prefix for which-key
-- <leader>f = Find
vim.keymap.set("n", "<leader>ff", find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", live_grep, { desc = "Find grep" })
vim.keymap.set("n", "<leader>fb", buffers, { desc = "Find buffers" })

-- <leader>g = Git
vim.keymap.set("n", "<leader>gs", git_status, { desc = "Git status" })
vim.keymap.set("n", "<leader>gc", git_commit, { desc = "Git commit" })

-- <leader>l = LSP
vim.keymap.set("n", "<leader>lr", lsp_rename, { desc = "LSP rename" })
vim.keymap.set("n", "<leader>la", code_action, { desc = "LSP code action" })
```

## which-key Integration

### Group Registration
```lua
local wk = require("which-key")

wk.add({
  { "<leader>f", group = "Find" },
  { "<leader>g", group = "Git" },
  { "<leader>l", group = "LSP" },
})
```

### Complete Mapping with which-key
```lua
wk.add({
  { "<leader>f", group = "Find" },
  { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
  { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
  { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
})
```

## Delete Keymap

### Remove Mapping
```lua
vim.keymap.del("n", "<leader>old")
vim.keymap.del({ "n", "v" }, "<C-c>")

-- Buffer-local
vim.keymap.del("n", "<leader>old", { buffer = bufnr })
```

## LSP Keymap Pattern

### On LspAttach
```lua
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    -- Navigation
    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
    map("n", "gr", vim.lsp.buf.references, "Go to references")
    map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
    map("n", "K", vim.lsp.buf.hover, "Hover documentation")

    -- Actions
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("n", "<leader>f", vim.lsp.buf.format, "Format buffer")

    -- Diagnostics
    map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
    map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
    map("n", "<leader>e", vim.diagnostic.open_float, "Show diagnostic")
  end,
})
```

## Common Mappings

### Movement Improvements
```lua
-- Better up/down on wrapped lines
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })

-- Center cursor after jumps
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
```

### Window Management
```lua
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
```

### Clipboard
```lua
-- Yank to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })
vim.keymap.set("n", "<leader>Y", '"+Y', { desc = "Yank line to clipboard" })

-- Paste from system clipboard
vim.keymap.set({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from clipboard" })
```

### Visual Mode
```lua
-- Move selected lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Stay in visual after indent
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")
```

### Terminal Mode
```lua
-- Exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Navigation from terminal
vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h")
vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j")
vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k")
vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l")
```
