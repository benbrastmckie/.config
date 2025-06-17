-- neotex.config.keymaps
-- Keymapping configuration

--[[ KEYBINDINGS - COMPLETE REFERENCE
-----------------------------------------------------------

📖 COMPLETE DOCUMENTATION: See docs/MAPPINGS.md for comprehensive keybinding reference
Please maintain consistency between this file and docs/MAPPINGS.md when making changes.

This file defines global keybindings, with special handling for terminal, markdown,
and Avante AI buffers. The file organizes keymaps by functionality and uses helper
functions for consistent definitions.

Global keymaps use the `map()` function with descriptions, while buffer-specific maps
use the `buf_map()` function via special setup functions like `set_terminal_keymaps()`,
which are called by autocmds when specific filetypes are detected.

----------------------------------------------------------------------------------
TERMINAL MODE KEYBINDINGS                      | DESCRIPTION
----------------------------------------------------------------------------------
<Esc>                                          | Exit terminal mode to normal mode
<C-t>                                          | Toggle terminal window
<C-h>, <C-j>, <C-k>, <C-l>                     | Navigate between windows
<C-a>                                          | Ask Avante AI a question (non-lazygit only)
<M-h>, <M-l>, <M-Left>, <M-Right>              | Resize terminal window horizontally

----------------------------------------------------------------------------------
GENERAL KEYBINDINGS                            | DESCRIPTION
----------------------------------------------------------------------------------
<Space>                                        | Leader key for command sequences
<C-z>                                          | Disabled (prevents accidental suspension)
<C-t>                                          | Toggle terminal window
<C-s>                                          | Show spelling suggestions with Telescope
<CR> (Enter)                                   | Clear search highlighting
<C-p>                                          | Find files with Telescope
<C-;>                                          | Toggle comments for current line/selection
<S-m>                                          | Show help for word under cursor
<C-m>                                          | Search man pages with Telescope

----------------------------------------------------------------------------------
NAVIGATION KEYBINDINGS                         | DESCRIPTION
----------------------------------------------------------------------------------
Y                                              | Yank (copy) from cursor to end of line
E                                              | Go to end of previous word
m                                              | Center cursor at top of screen
<C-h>, <C-j>, <C-k>, <C-l>                    | Navigate between windows
<A-Left>, <A-Right>, <A-h>, <A-l>             | Resize window horizontally
<Tab>                                          | Go to next buffer (by modified time)
<S-Tab>                                        | Go to previous buffer (by modified time)
<C-u>, <C-d>                                   | Scroll half-page up/down (with centering)
<S-h>, <S-l>                                   | Go to start/end of display line
J, K                                           | Navigate display lines (respects wrapping)

----------------------------------------------------------------------------------
TEXT MANIPULATION                              | DESCRIPTION
----------------------------------------------------------------------------------
<A-j>, <A-k>                                   | Move current line or selection up/down
<, >                                           | Decrease/increase indentation (preserves selection)

----------------------------------------------------------------------------------
MARKDOWN-SPECIFIC KEYBINDINGS                  | DESCRIPTION
----------------------------------------------------------------------------------
<CR> (Enter)                                   | Create new bullet point
o                                              | Create new bullet point below
O                                              | Create new bullet point above
<Tab>                                          | Indent bullet and recalculate numbers
<S-Tab>                                        | Unindent bullet and recalculate numbers
dd                                             | Delete line and recalculate list numbers
d (visual mode)                                | Delete selection and recalculate numbers
<C-n>                                          | Toggle checkbox status ([ ] ↔ [x])
<C-c>                                          | Recalculate list numbering

----------------------------------------------------------------------------------
AVANTE AI BUFFER KEYBINDINGS                   | DESCRIPTION
----------------------------------------------------------------------------------
<C-t>                                          | Toggle Avante interface
<C-c>                                          | Reset/clear Avante content
<C-m>                                          | Select model for current provider
<C-p>                                          | Select provider and model
<C-s>                                          | Stop AI generation
<C-d>                                          | Select provider/model with default option
<CR> (Enter)                                   | Create new line (prevents submission)
--]]

local M = {}

function M.setup()
  ------------------------------------------
  -- CONFIGURATION AND UTILITY FUNCTIONS --
  ------------------------------------------
  local opts = { noremap = true, silent = true }

  -- Helper function for more readable keymap definition
  local function map(mode, key, cmd, options, description)
    local opts = vim.tbl_deep_extend("force",
      { noremap = true, silent = true, desc = description },
      options or {}
    )
    vim.keymap.set(mode, key, cmd, opts)
  end

  -- Helper for buffer-local mapping
  local function buf_map(bufnr, mode, key, cmd, description)
    vim.api.nvim_buf_set_keymap(
      bufnr or 0,
      mode,
      key,
      cmd,
      { noremap = true, silent = true, desc = description }
    )
  end

  ----------------------------------------
  -- BUFFER-SPECIFIC KEYMAP FUNCTIONS  --
  ----------------------------------------

  -- Terminal mappings setup function triggered by an auto-command
  function _G.set_terminal_keymaps()
    -- Set the terminal window as fixed
    vim.wo.winfixbuf = true

    -- Terminal navigation
    buf_map(0, "t", "<esc>", "<C-\\><C-n>", "Exit terminal mode")
    buf_map(0, "t", "<C-h>", "<Cmd>wincmd h<CR>", "Navigate left")
    buf_map(0, "t", "<C-j>", "<Cmd>wincmd j<CR>", "Navigate down")
    buf_map(0, "t", "<C-k>", "<Cmd>wincmd k<CR>", "Navigate up")
    buf_map(0, "t", "<C-l>", "<Cmd>wincmd l<CR>", "Navigate right")

    -- Terminal resizing
    buf_map(0, "t", "<M-Right>", "<Cmd>vertical resize -2<CR>", "Resize right")
    buf_map(0, "t", "<M-Left>", "<Cmd>vertical resize +2<CR>", "Resize left")
    buf_map(0, "t", "<M-l>", "<Cmd>vertical resize -2<CR>", "Resize right")
    buf_map(0, "t", "<M-h>", "<Cmd>vertical resize +2<CR>", "Resize left")

    -- Avante integration (only for non-lazygit buffers)
    if vim.bo.filetype ~= "lazygit" then
      buf_map(0, "t", "<C-a>", "<Cmd>AvanteAsk<CR>", "Ask Avante")
      buf_map(0, "n", "<C-a>", "<Cmd>AvanteAsk<CR>", "Ask Avante")
      buf_map(0, "v", "<C-a>", "<Cmd>AvanteAsk<CR>", "Ask Avante")
    end
  end

  -- Markdown mappings setup function triggered by an auto-command
  function _G.set_markdown_keymaps()
    -- Load the autolist module
    local ok, autolist = pcall(require, "neotex.plugins.tools.autolist.util")

    -- Tab settings for markdown
    vim.opt.tabstop = 2
    vim.opt.shiftwidth = 2
    vim.opt.softtabstop = 2

    -- Only set the keymaps if the autolist module is loaded
    if ok and autolist and autolist.operations then
      -- Use the autolist handlers for various key mappings

      -- List creation/management
      vim.keymap.set("i", "<CR>", autolist.operations.enter_handler,
        { expr = true, buffer = true, desc = "Smart list handling for Enter" })

      -- Indentation keymaps
      vim.keymap.set("i", "<Tab>", autolist.operations.tab_handler,
        { expr = true, buffer = true, desc = "Smart list indent" })

      vim.keymap.set("i", "<S-Tab>", autolist.operations.shift_tab_handler,
        { expr = true, buffer = true, desc = "Smart list unindent" })

      vim.keymap.set("i", "<C-D>", autolist.operations.shift_tab_handler,
        { expr = true, buffer = true, desc = "Smart list unindent (C-D)" })

      -- Normal mode keymaps
      vim.keymap.set("n", "<C-n>", "<cmd>AutolistIncrementCheckbox<CR>",
        { buffer = true, desc = "Increment checkbox" })

      vim.keymap.set("n", "<A-n>", "<cmd>AutolistDecrementCheckbox<CR>",
        { buffer = true, desc = "Decrement checkbox" })

      vim.keymap.set("n", "o", "o<cmd>AutolistNewBullet<cr>",
        { buffer = true, desc = "New bullet below" })

      vim.keymap.set("n", "O", "O<cmd>AutolistNewBulletBefore<cr>",
        { buffer = true, desc = "New bullet above" })

      vim.keymap.set("n", ">", "><cmd>AutolistRecalculate<cr>",
        { buffer = true, desc = "Indent bullet" })

      vim.keymap.set("n", "<", "<<cmd>AutolistRecalculate<cr>",
        { buffer = true, desc = "Unindent bullet" })

      vim.keymap.set("n", "<C-c>", "<cmd>AutolistRecalculate<cr>",
        { buffer = true, desc = "Recalculate list" })

      -- Deletion with list recalculation
      vim.keymap.set("n", "dd", "dd<cmd>AutolistRecalculate<cr>",
        { buffer = true, desc = "Delete and recalculate" })

      vim.keymap.set("v", "d", "d<cmd>AutolistRecalculate<cr>",
        { buffer = true, desc = "Delete and recalculate" })
    else
      -- Fallback in case the module isn't loaded for some reason
      buf_map(0, "i", "<CR>", "<CR><cmd>AutolistNewBullet<cr>", "New bullet point")
      buf_map(0, "n", "o", "o<cmd>AutolistNewBullet<cr>", "New bullet below")
      buf_map(0, "n", "O", "O<cmd>AutolistNewBulletBefore<cr>", "New bullet above")
      buf_map(0, "n", "<C-n>", "<cmd>lua IncrementCheckbox()<CR>", "Increment checkbox")
      buf_map(0, "n", "<A-n>", "<cmd>lua DecrementCheckbox()<CR>", "Decrement checkbox")
    end
  end

  -- Avante AI buffer mappings setup function triggered by an auto-command
  function _G.set_avante_keymaps()
    -- Helper for buffer-local Avante mappings
    local function avante_map(mode, key, cmd, description)
      buf_map(0, mode, key, cmd, description)
    end

    -- Toggle Avante interface
    avante_map("n", "<C-t>", "<cmd>AvanteToggle<CR>", "Toggle Avante interface")
    avante_map("i", "<C-t>", "<cmd>AvanteToggle<CR>", "Toggle Avante interface")
    avante_map("n", "q", "<cmd>AvanteToggle<CR>", "Toggle Avante interface")

    -- Reset/clear Avante content
    avante_map("n", "<C-c>", "<cmd>AvanteClear history<CR>", "Clear chat history")
    avante_map("i", "<C-c>", "<cmd>AvanteClear history<CR>", "Clear chat history")

    -- Model and provider selection
    avante_map("n", "<C-m>", "<cmd>AvanteModel<CR>", "Select model")
    avante_map("i", "<C-m>", "<cmd>AvanteModel<CR>", "Select model")
    avante_map("n", "<C-s>", "<cmd>AvanteProvider<CR>", "Select provider")
    avante_map("i", "<C-s>", "<cmd>AvanteProvider<CR>", "Select provider")

    -- Generation control
    avante_map("n", "<C-x>", "<cmd>AvanteStop<CR>", "Stop generation")
    avante_map("i", "<C-x>", "<cmd>AvanteStop<CR>", "Stop generation")

    -- Prevent accidental submission
    avante_map("i", "<CR>", "<CR>", "Create new line")
  end

  ---------------------------------
  -- GENERAL KEYBOARD MAPPINGS  --
  ---------------------------------

  -- Prevents common mode mistakes
  map("n", "<C-z>", "<nop>", {}, "Disable suspend")
  map("n", "gc", "<nop>", {}, "Disable gc mappings")
  map("n", "gcc", "<nop>", {}, "Disable gcc mappings")

  -- Terminal integration
  map("n", "<C-t>", "<cmd>ToggleTerm<CR>", { remap = true }, "Toggle terminal")
  map("t", "<C-t>", "<cmd>ToggleTerm<CR>", { remap = true }, "Toggle terminal")

  -- Spelling assistance
  map("n", "<C-s>", function()
    require("telescope.builtin").spell_suggest(require("telescope.themes").get_cursor({
      previewer = false,
      layout_config = { width = 50, height = 15 }
    }))
  end, { remap = true }, "Spelling suggestions")

  -- Search functionality
  map("n", "<CR>", "<cmd>noh<CR>", {}, "Clear search highlights")
  map("n", "<C-p>", "<cmd>Telescope find_files<CR>", { remap = true }, "Find files")

  -- Comment toggling with mini.comment
  map("n", "<C-;>", function()
    local mini_comment = require('mini.comment')
    if mini_comment.toggle_lines then
      mini_comment.toggle_lines(vim.fn.line('.'), vim.fn.line('.'))
    else
      mini_comment.toggle()
    end
  end, {}, "Toggle comment on current line")

  -- Direct mapping for visual mode commenting
  map("v", "<C-;>", "gc", { remap = true }, "Toggle comment on selection")

  -- Help integration
  map("n", "<S-m>", '<cmd>Telescope help_tags cword=true<cr>', {}, "Help for word under cursor")
  map("n", "<C-m>", '<cmd>Telescope man_pages<cr>', {}, "Search man pages")

  ------------------------
  -- TEXT EDITING KEYS --
  ------------------------

  -- Fix standard behaviors
  map("n", "Y", "y$", {}, "Yank to end of line")
  map("n", "E", "ge", {}, "Go to end of previous word")
  map("v", "Y", "y$", {}, "Yank to end of line")

  -- Cursor centering
  map("n", "m", "zt", {}, "Center cursor at top")
  map("v", "m", "zt", {}, "Center cursor at top")

  -- Window navigation
  map("n", "<C-h>", "<C-w>h", {}, "Navigate left")
  map("n", "<C-j>", "<C-w>j", {}, "Navigate down")
  map("n", "<C-k>", "<C-w>k", {}, "Navigate up")
  map("n", "<C-l>", "<C-w>l", {}, "Navigate right")

  -- Window resizing
  map("n", "<A-Left>", ":vertical resize -2<CR>", {}, "Decrease width")
  map("n", "<A-Right>", ":vertical resize +2<CR>", {}, "Increase width")
  map("n", "<A-h>", ":vertical resize -2<CR>", {}, "Decrease width")
  map("n", "<A-l>", ":vertical resize +2<CR>", {}, "Increase width")

  -- Buffer navigation using utils.buffer module
  local buffer_utils_loaded = false

  -- Try to use the new utils.buffer module first
  local ok, buffer_utils = pcall(require, "neotex.util.buffer")
  if ok and buffer_utils and buffer_utils.goto_buffer then
    buffer_utils_loaded = true

    -- Use the new functions with the same keybindings
    map("n", "<TAB>", function() buffer_utils.goto_buffer(1, 1) end, {}, "Next buffer")
    map("n", "<S-TAB>", function() buffer_utils.goto_buffer(1, -1) end, {}, "Previous buffer")
  end

  -- If we couldn't load the buffer utils, use fallbacks
  if not buffer_utils_loaded then
    -- Try using the global function if it exists
    if _G.GotoBuffer then
      map("n", "<TAB>", function() _G.GotoBuffer(1, 1) end, {}, "Next buffer")
      map("n", "<S-TAB>", function() _G.GotoBuffer(1, -1) end, {}, "Previous buffer")
    else
      -- Ultimate fallback
      map("n", "<TAB>", ":bnext<CR>", {}, "Next buffer")
      map("n", "<S-TAB>", ":bprevious<CR>", {}, "Previous buffer")
    end
  end

  -- Line manipulation
  map("n", "<A-j>", "<Esc>:m .+1<CR>==", {}, "Move line down")
  map("n", "<A-k>", "<Esc>:m .-2<CR>==", {}, "Move line up")
  map("x", "<A-j>", ":move '>+1<CR>gv-gv", {}, "Move selection down")
  map("x", "<A-k>", ":move '<-2<CR>gv-gv", {}, "Move selection up")
  map("v", "<A-j>", ":m'>+<CR>gv", {}, "Move selection down")
  map("v", "<A-k>", ":m-2<CR>gv", {}, "Move selection up")

  -- Scrolling with centering
  map("n", "<c-u>", "<c-u>zz", {}, "Scroll up with centering")
  map("n", "<c-d>", "<c-d>zz", {}, "Scroll down with centering")

  -- Line navigation
  map("v", "<S-h>", "g^", {}, "Go to start of display line")
  map("v", "<S-l>", "g$", {}, "Go to end of display line")
  map("n", "<S-h>", "g^", {}, "Go to start of display line")
  map("n", "<S-l>", "g$", {}, "Go to end of display line")

  -- Indentation
  map("v", "<", "<gv", {}, "Decrease indent and reselect")
  map("v", ">", ">gv", {}, "Increase indent and reselect")
  map("n", "<", "<S-v><<esc>", {}, "Decrease indent for line")
  map("n", ">", "<S-v>><esc>", {}, "Increase indent for line")

  -- Visual line navigation
  map("n", "J", "gj", {}, "Move down display line")
  map("n", "K", "gk", {}, "Move up display line")
  map("v", "J", "gj", {}, "Move down display line")
  map("v", "K", "gk", {}, "Move up display line")

  return true
end

return M
