-- Draft folder help display
local M = {}

-- Show help for draft folder keymaps
function M.show_draft_help()
  local notify = require('neotex.util.notifications')
  
  -- Create help content
  local help_lines = {
    "Himalaya Draft Folder Commands",
    "",
    "Navigation:",
    "  j/k       - Move up/down",
    "  gn        - Next page",
    "  gp        - Previous page", 
    "",
    "Draft Actions:",
    "  <CR>      - Open draft for editing",
    "  gD        - Delete draft",
    "  n/N       - Select/deselect draft",
    "",
    "Folder Management:",
    "  ga        - Switch account",
    "  gm        - Switch folder",
    "  gs        - Sync drafts",
    "",
    "Other:",
    "  gH        - Show this help",
    "  q         - Quit sidebar",
    "",
    "Press any key to close..."
  }
  
  -- Create floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  
  -- Calculate window size
  local width = 40
  local height = #help_lines
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  -- Create window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
    title = ' Draft Help ',
    title_pos = 'center'
  })
  
  -- Set up close on any key
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', { silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', { silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', ':close<CR>', { silent = true })
  
  -- Close on any other key press
  local close_keys = {'j', 'k', 'h', 'l', 'g', 'G', '0', '$', 'w', 'b', 'e', '<Space>'}
  for _, key in ipairs(close_keys) do
    vim.api.nvim_buf_set_keymap(buf, 'n', key, ':close<CR>', { silent = true })
  end
end

return M