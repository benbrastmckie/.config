-- Context-aware help display for different folder types
local M = {}

local state = require('neotex.plugins.tools.himalaya.core.state')
local utils = require('neotex.plugins.tools.himalaya.utils')

-- Determine folder type from current folder
function M.get_folder_type()
  local current_folder = state.get_current_folder()
  local current_account = state.get_current_account()
  
  if not current_folder or not current_account then
    return 'inbox'
  end
  
  -- Check if it's drafts folder
  local draft_folder = utils.find_draft_folder(current_account)
  if current_folder == draft_folder then
    return 'drafts'
  end
  
  -- Check other folder types by name pattern
  local folder_lower = current_folder:lower()
  
  if folder_lower:match('trash') or folder_lower:match('deleted') or folder_lower:match('bin') then
    return 'trash'
  elseif folder_lower:match('sent') then
    return 'sent'
  elseif folder_lower:match('spam') or folder_lower:match('junk') then
    return 'spam'
  elseif folder_lower:match('archive') or folder_lower:match('all.mail') or folder_lower:match('all_mail') then
    return 'archive'
  elseif folder_lower:match('starred') or folder_lower:match('flagged') then
    return 'starred'
  elseif folder_lower:match('important') then
    return 'important'
  else
    return 'inbox'
  end
end

-- Get help content for specific folder type
-- Updated keymaps per task 56
function M.get_help_content(folder_type)
  local base_navigation = {
    "Navigation:",
    "  j/k       - Move up/down",
    "  <C-d>     - Next page",
    "  <C-u>     - Previous page",
    ""
  }

  local base_selection = {
    "Selection:",
    "  <Space>   - Toggle selection",
    "  n         - Select email",
    "  p         - Deselect email",
    ""
  }

  local base_folder_mgmt = {
    "Folder Management:",
    "  <leader>ma - Switch account",
    "  <leader>mf - Change folder",
    "  <leader>ms - Sync folder",
    ""
  }

  local base_actions = {
    "Quick Actions (on email line):",
    "  r         - Reply",
    "  R         - Reply all",
    "  f         - Forward",
    "  d         - Delete",
    "  a         - Archive",
    "  m         - Move",
    "  c         - Compose new",
    "  /         - Search",
    "",
    "Mail Menu (<leader>me):",
    "  Also available via which-key",
    ""
  }

  local base_other = {
    "Other:",
    "  F         - Refresh list",
    "  gH        - Show this help",
    "  q         - Quit sidebar",
    "",
    "Press any key to close..."
  }
  
  -- Build help content by concatenating sections
  local function build_help(title, extra_info)
    local lines = {title, ""}

    -- Add navigation
    for _, line in ipairs(base_navigation) do
      table.insert(lines, line)
    end

    -- Add selection
    for _, line in ipairs(base_selection) do
      table.insert(lines, line)
    end

    -- Add extra info if provided
    if extra_info then
      for _, line in ipairs(extra_info) do
        table.insert(lines, line)
      end
    end

    -- Add actions
    for _, line in ipairs(base_actions) do
      table.insert(lines, line)
    end

    -- Add folder management
    for _, line in ipairs(base_folder_mgmt) do
      table.insert(lines, line)
    end

    -- Add other
    for _, line in ipairs(base_other) do
      table.insert(lines, line)
    end

    return lines
  end

  if folder_type == 'drafts' then
    return build_help("Himalaya Draft Folder Commands", {
      "Draft Actions:",
      "  <CR>      - Open draft (3-state preview)",
      "",
    })
  elseif folder_type == 'trash' then
    return build_help("Himalaya Trash Folder Commands", {
      "Trash Actions:",
      "  <CR>      - Preview email (3-state)",
      "",
    })
  elseif folder_type == 'sent' then
    return build_help("Himalaya Sent Folder Commands", {
      "Sent Actions:",
      "  <CR>      - Preview email (3-state)",
      "",
    })
  elseif folder_type == 'spam' then
    return build_help("Himalaya Spam Folder Commands", {
      "Spam Actions:",
      "  <CR>      - Preview email (3-state)",
      "",
    })
  else
    local title = "Himalaya " .. string.upper(string.sub(folder_type, 1, 1)) .. string.sub(folder_type, 2) .. " Folder Commands"
    return build_help(title, {
      "Preview:",
      "  <CR>      - 3-state preview model",
      "             (OFF -> SWITCH -> FOCUS -> BUFFER)",
      "",
    })
  end
end

-- Show context-aware help
function M.show_folder_help()
  local folder_type = M.get_folder_type()
  local help_lines = M.get_help_content(folder_type)
  
  -- Create floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  
  -- Calculate window size
  local width = 45
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
    title = ' ' .. string.upper(string.sub(folder_type, 1, 1)) .. string.sub(folder_type, 2) .. ' Help ',
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