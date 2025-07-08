-- Himalaya UI Highlight Groups
-- Define custom highlight groups for the email client

local M = {}

-- Define highlight groups
function M.setup()
  local hl = vim.api.nvim_set_hl
  
  -- Email status highlights
  hl(0, 'HimalayaUnread', { bold = true })
  hl(0, 'HimalayaRead', { fg = '#888888' })
  hl(0, 'HimalayaFlagged', { fg = '#ff0000' })
  hl(0, 'HimalayaDraft', { fg = '#ffaa00' })
  
  -- Account color highlights for multi-account views
  hl(0, 'HimalayaAccountRed', { fg = '#ff6b6b' })
  hl(0, 'HimalayaAccountGreen', { fg = '#51cf66' })
  hl(0, 'HimalayaAccountYellow', { fg = '#ffd43b' })
  hl(0, 'HimalayaAccountBlue', { fg = '#4dabf7' })
  hl(0, 'HimalayaAccountMagenta', { fg = '#ff6cc9' })
  hl(0, 'HimalayaAccountCyan', { fg = '#20e3b2' })
  hl(0, 'HimalayaAccountOrange', { fg = '#ff922b' })
  hl(0, 'HimalayaAccountPurple', { fg = '#9c36b5' })
  
  -- UI element highlights
  hl(0, 'HimalayaHeader', { bold = true, fg = '#4dabf7' })
  hl(0, 'HimalayaSeparator', { fg = '#444444' })
  hl(0, 'HimalayaSelected', { bg = '#333333' })
  hl(0, 'HimalayaPreview', { fg = '#aaaaaa' })
  
  -- Sync status highlights
  hl(0, 'HimalayaSyncing', { fg = '#ffd43b' })
  hl(0, 'HimalayaSyncError', { fg = '#ff6b6b' })
  hl(0, 'HimalayaSyncSuccess', { fg = '#51cf66' })
end

-- Get highlight group for account
function M.get_account_highlight(account_index)
  local colors = {
    'HimalayaAccountRed',
    'HimalayaAccountGreen',
    'HimalayaAccountYellow',
    'HimalayaAccountBlue',
    'HimalayaAccountMagenta',
    'HimalayaAccountCyan',
    'HimalayaAccountOrange',
    'HimalayaAccountPurple'
  }
  
  local index = ((account_index - 1) % #colors) + 1
  return colors[index]
end

return M