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
function M.get_help_content(folder_type)
  local base_navigation = {
    "Navigation:",
    "  j/k       - Move up/down",
    "  gn        - Next page",
    "  gp        - Previous page",
    ""
  }
  
  local base_folder_mgmt = {
    "Folder Management:",
    "  ga        - Switch account",
    "  gm        - Switch folder",
    "  gs        - Sync folder",
    ""
  }
  
  local base_other = {
    "Other:",
    "  gH        - Show this help",
    "  q         - Quit sidebar",
    "",
    "Press any key to close..."
  }
  
  if folder_type == 'drafts' then
    return {
      "Himalaya Draft Folder Commands",
      "",
      base_navigation[1],
      base_navigation[2],
      base_navigation[3],
      base_navigation[4],
      base_navigation[5],
      "Draft Actions:",
      "  <CR>      - Open draft for editing",
      "  gD        - Delete draft",
      "  n/N       - Select/deselect draft",
      "",
      base_folder_mgmt[1],
      base_folder_mgmt[2],
      base_folder_mgmt[3],
      base_folder_mgmt[4],
      base_folder_mgmt[5],
      base_other[1],
      base_other[2],
      base_other[3],
      base_other[4],
      base_other[5]
    }
  elseif folder_type == 'trash' then
    return {
      "Himalaya Trash Folder Commands",
      "",
      base_navigation[1],
      base_navigation[2],
      base_navigation[3],
      base_navigation[4],
      base_navigation[5],
      "Email Actions:",
      "  <CR>      - Preview email",
      "  gD        - Permanently delete",
      "  gM        - Move to folder (restore)",
      "  n/N       - Select/deselect email",
      "",
      base_folder_mgmt[1],
      base_folder_mgmt[2],
      base_folder_mgmt[3],
      base_folder_mgmt[4],
      base_folder_mgmt[5],
      base_other[1],
      base_other[2],
      base_other[3],
      base_other[4],
      base_other[5]
    }
  elseif folder_type == 'sent' then
    return {
      "Himalaya Sent Folder Commands",
      "",
      base_navigation[1],
      base_navigation[2],
      base_navigation[3],
      base_navigation[4],
      base_navigation[5],
      "Email Actions:",
      "  <CR>      - Preview email",
      "  gf        - Forward email",
      "  gM        - Move to folder",
      "  n/N       - Select/deselect email",
      "",
      base_folder_mgmt[1],
      base_folder_mgmt[2],
      base_folder_mgmt[3],
      base_folder_mgmt[4],
      base_folder_mgmt[5],
      base_other[1],
      base_other[2],
      base_other[3],
      base_other[4],
      base_other[5]
    }
  elseif folder_type == 'spam' then
    return {
      "Himalaya Spam Folder Commands",
      "",
      base_navigation[1],
      base_navigation[2],
      base_navigation[3],
      base_navigation[4],
      base_navigation[5],
      "Email Actions:",
      "  <CR>      - Preview email",
      "  gD        - Delete email",
      "  gM        - Move to folder",
      "  n/N       - Select/deselect email",
      "",
      base_folder_mgmt[1],
      base_folder_mgmt[2],
      base_folder_mgmt[3],
      base_folder_mgmt[4],
      base_folder_mgmt[5],
      base_other[1],
      base_other[2],
      base_other[3],
      base_other[4],
      base_other[5]
    }
  else -- inbox, archive, starred, important, or other regular folders
    return {
      "Himalaya " .. string.upper(string.sub(folder_type, 1, 1)) .. string.sub(folder_type, 2) .. " Folder Commands",
      "",
      base_navigation[1],
      base_navigation[2],
      base_navigation[3],
      base_navigation[4],
      base_navigation[5],
      "Email Actions:",
      "  <CR>      - Preview email",
      "  gr        - Reply to email",
      "  gR        - Reply all",
      "  gf        - Forward email",
      "  gD        - Delete email",
      "  gA        - Archive email",
      "  gS        - Mark as spam",
      "  gM        - Move to folder",
      "  n/N       - Select/deselect email",
      "",
      base_folder_mgmt[1],
      base_folder_mgmt[2],
      base_folder_mgmt[3],
      base_folder_mgmt[4],
      base_folder_mgmt[5],
      base_other[1],
      base_other[2],
      base_other[3],
      base_other[4],
      base_other[5]
    }
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