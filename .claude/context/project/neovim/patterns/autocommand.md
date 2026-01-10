# Autocommand Patterns

## vim.api.nvim_create_autocmd

### Basic Syntax
```lua
vim.api.nvim_create_autocmd(event, {
  group = augroup,       -- Optional: autocommand group
  pattern = pattern,     -- Pattern to match
  buffer = bufnr,        -- OR: specific buffer
  callback = function,   -- Lua function to execute
  command = string,      -- OR: Vim command to execute
  once = boolean,        -- Run only once
  desc = string,         -- Description
})
```

## Autocommand Groups

### Creating Groups
```lua
-- Create or get group (clear if exists)
local augroup = vim.api.nvim_create_augroup("MyGroup", { clear = true })

-- Don't clear existing
local augroup = vim.api.nvim_create_augroup("MyGroup", { clear = false })
```

### Pattern: Group with Autocmds
```lua
local function setup_autocmds()
  local group = vim.api.nvim_create_augroup("MyConfig", { clear = true })

  vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    pattern = "*",
    callback = function()
      -- Remove trailing whitespace
      vim.cmd([[%s/\s\+$//e]])
    end,
    desc = "Remove trailing whitespace",
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "lua", "python" },
    callback = function()
      vim.opt_local.shiftwidth = 4
    end,
    desc = "Set shiftwidth for specific filetypes",
  })
end
```

## Common Events

### Buffer Events
| Event | Description |
|-------|-------------|
| BufReadPre | Before reading buffer |
| BufReadPost | After reading buffer |
| BufWritePre | Before writing buffer |
| BufWritePost | After writing buffer |
| BufEnter | After entering buffer |
| BufLeave | Before leaving buffer |
| BufNewFile | When creating new file |
| BufDelete | Before deleting buffer |

### File Events
| Event | Description |
|-------|-------------|
| FileType | After filetype is set |
| FileReadPre | Before reading file with :read |
| FileReadPost | After reading file with :read |
| FileWritePre | Before writing with :write |

### Window Events
| Event | Description |
|-------|-------------|
| WinEnter | After entering window |
| WinLeave | Before leaving window |
| WinNew | After creating window |
| WinResized | After window resize |

### UI Events
| Event | Description |
|-------|-------------|
| VimEnter | After Vim starts |
| VimLeave | Before Vim exits |
| ColorScheme | After colorscheme changes |
| UIEnter | After UI attaches |

### Text Change Events
| Event | Description |
|-------|-------------|
| TextChanged | After text change in Normal mode |
| TextChangedI | After text change in Insert mode |
| TextChangedP | After text change in Insert (completion) |
| TextYankPost | After yanking text |

### Insert Events
| Event | Description |
|-------|-------------|
| InsertEnter | When entering Insert mode |
| InsertLeave | When leaving Insert mode |
| InsertCharPre | Before inserting character |

### Other Events
| Event | Description |
|-------|-------------|
| CursorMoved | After cursor moves (Normal) |
| CursorMovedI | After cursor moves (Insert) |
| CursorHold | Cursor idle for 'updatetime' |
| LspAttach | When LSP client attaches |
| LspDetach | When LSP client detaches |

## Common Patterns

### Format on Save
```lua
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true }),
  pattern = { "*.lua", "*.py", "*.ts" },
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})
```

### Highlight on Yank
```lua
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})
```

### Restore Cursor Position
```lua
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("RestoreCursor", { clear = true }),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})
```

### Close Specific Buffers with q
```lua
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("CloseWithQ", { clear = true }),
  pattern = { "help", "qf", "man", "notify" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})
```

### Auto-resize Windows
```lua
vim.api.nvim_create_autocmd("VimResized", {
  group = vim.api.nvim_create_augroup("AutoResize", { clear = true }),
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})
```

### Filetype-Specific Settings
```lua
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("FiletypeSettings", { clear = true }),
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
    vim.opt_local.conceallevel = 2
  end,
})
```

### Check for External Changes
```lua
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = vim.api.nvim_create_augroup("Checktime", { clear = true }),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})
```

## Buffer-Local Autocmds

### Attach to Specific Buffer
```lua
vim.api.nvim_create_autocmd("CursorMoved", {
  buffer = bufnr,  -- Specific buffer
  callback = function()
    -- Only runs in this buffer
  end,
})
```

### Pattern: LSP Buffer Setup
```lua
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf

    -- Buffer-local autocmd
    vim.api.nvim_create_autocmd("CursorHold", {
      buffer = bufnr,
      callback = function()
        vim.diagnostic.open_float(nil, { focus = false })
      end,
    })
  end,
})
```

## Delete Autocmds

### Clear Group
```lua
-- Clear all autocmds in group
vim.api.nvim_clear_autocmds({ group = "MyGroup" })

-- Clear specific pattern in group
vim.api.nvim_clear_autocmds({
  group = "MyGroup",
  event = "BufWritePre",
})
```

### Get Autocmds
```lua
-- List autocmds
local autocmds = vim.api.nvim_get_autocmds({
  group = "MyGroup",
  event = "BufWritePre",
})

for _, ac in ipairs(autocmds) do
  print(vim.inspect(ac))
end
```

## Callback Function Arguments

### Event Data
```lua
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    -- args.id - autocmd ID
    -- args.event - event name
    -- args.group - group ID (if any)
    -- args.match - matched pattern
    -- args.buf - buffer number
    -- args.file - file path
    -- args.data - event-specific data

    print("File:", args.file)
    print("Buffer:", args.buf)
  end,
})
```

### LspAttach Data
```lua
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local bufnr = args.buf

    print("LSP attached:", client.name)
  end,
})
```
