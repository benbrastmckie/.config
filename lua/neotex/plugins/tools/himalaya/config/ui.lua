-- UI Configuration Module
-- Manages user interface preferences and keybindings

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Module state
local module_state = {
  ui_settings = {},
  keymaps_setup = false
}

-- Default UI settings
M.defaults = {
  -- Sidebar
  sidebar = {
    width = 40,
    position = 'left',
    show_icons = true,
    relative_dates = true,
  },
  
  -- Email list
  email_list = {
    page_size = 30,
    preview_lines = 2,
    date_format = '%Y-%m-%d %H:%M',
  },
  
  -- Email preview
  preview = {
    position = 'right',    -- 'right', 'bottom', 'float'
    width = 80,           -- For right position
    height = 20,          -- For bottom position
    wrap = true,
    max_height = 40,      -- Maximum height for floating windows
  },
  
  -- Email composition
  compose = {
    default_headers = true,
    auto_complete_contacts = true,
    spell_check = true,
    wrap_at = 72,
  },
  
  -- Confirmation dialogs
  confirm = {
    delete = true,
    send = true,
    discard_draft = true,
  },
  
  -- Notifications
  notifications = {
    position = 'top-right',
    timeout = 3000,
  }
}

-- Initialize module with configuration
function M.init(config)
  module_state.ui_settings = vim.tbl_deep_extend('force', M.defaults, config.ui or {})
  
  logger.debug('UI module initialized', {
    sidebar_width = module_state.ui_settings.sidebar.width,
    preview_position = module_state.ui_settings.preview.position
  })
end

-- Get UI setting by path
function M.get(path, default)
  local value = module_state.ui_settings
  for segment in path:gmatch('[^.]+') do
    if type(value) ~= 'table' then
      return default
    end
    value = value[segment]
  end
  return value ~= nil and value or default
end

-- Get sidebar settings
function M.get_sidebar_settings()
  return module_state.ui_settings.sidebar
end

-- Get email list settings
function M.get_email_list_settings()
  return module_state.ui_settings.email_list
end

-- Get preview settings
function M.get_preview_settings()
  return module_state.ui_settings.preview
end

-- Get compose settings
function M.get_compose_settings()
  return module_state.ui_settings.compose
end

-- Get confirmation settings
function M.get_confirm_settings()
  return module_state.ui_settings.confirm
end

-- Check if confirmation is required for an action
function M.requires_confirmation(action)
  return module_state.ui_settings.confirm[action] ~= false
end

-- Update UI settings
function M.update_settings(path, value)
  local segments = vim.split(path, '.', { plain = true })
  local current = module_state.ui_settings
  
  -- Navigate to the parent of the target
  for i = 1, #segments - 1 do
    if type(current[segments[i]]) ~= 'table' then
      current[segments[i]] = {}
    end
    current = current[segments[i]]
  end
  
  -- Set the value
  current[segments[#segments]] = value
  
  logger.info('UI setting updated', { path = path, value = value })
end

-- Setup buffer-specific keymaps
-- This function contains pragmatic UI dependencies for keybinding definitions
function M.setup_buffer_keymaps(bufnr)
  local keymap = vim.keymap.set
  local opts = { buffer = bufnr, silent = true }
  
  -- Disable tab cycling in all Himalaya buffers
  keymap('n', '<Tab>', '<Nop>', opts)
  keymap('n', '<S-Tab>', '<Nop>', opts)
  keymap('i', '<Tab>', '<Tab>', opts)  -- Keep normal tab in insert mode
  keymap('i', '<S-Tab>', '<S-Tab>', opts)  -- Keep shift-tab in insert mode
  
  -- Delegate to specific keymap setup based on filetype
  local filetype = vim.bo[bufnr].filetype
  
  if filetype == 'himalaya-list' then
    M.setup_email_list_keymaps(bufnr)
  elseif filetype == 'himalaya-preview' then
    M.setup_preview_keymaps(bufnr)
  elseif filetype == 'himalaya-compose' then
    M.setup_compose_keymaps(bufnr)
  elseif filetype == 'himalaya-sidebar' then
    M.setup_sidebar_keymaps(bufnr)
  end
  
  module_state.keymaps_setup = true
end

-- Setup email list keymaps
-- Reorganized keymap scheme per task 56:
-- - Navigation: j/k (default), <C-d>/<C-u> for pagination
-- - Selection: n=select, p=deselect, <Space>=toggle
-- - Actions removed: d, m, c, r, R, f, / (use which-key <leader>m instead)
-- - Refresh: F (was gr)
-- - Close: q
function M.setup_email_list_keymaps(bufnr)
  local keymap = vim.keymap.set
  local opts = { buffer = bufnr, silent = true }

  -- ESC handler for state regression (SWITCH -> OFF)
  keymap('n', '<Esc>', function()
    local ok, email_preview = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_preview')
    if not ok then return end

    local STATES = email_preview.PREVIEW_STATE
    local current_mode = email_preview.get_mode()

    if current_mode == STATES.SWITCH then
      -- In SWITCH mode, ESC hides preview and returns to OFF
      email_preview.exit_switch_mode()
    elseif current_mode == STATES.FOCUS then
      -- In FOCUS mode, ESC returns to SWITCH (handled in preview keymaps)
      -- But if somehow triggered from sidebar, also handle it
      email_preview.exit_focus_mode()
    end
    -- In OFF mode, ESC does nothing (or could close sidebar - TBD)
  end, vim.tbl_extend('force', opts, { desc = 'Hide preview / regress state' }))

  -- Basic navigation - <CR> for 3-state model (task 55)
  keymap('n', '<CR>', function()
    local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
    if ok and email_list.handle_enter then
      email_list.handle_enter()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Open email or draft' }))

  -- Close sidebar
  keymap('n', 'q', function()
    local ok, sidebar = pcall(require, 'neotex.plugins.tools.himalaya.ui.sidebar')
    if ok and sidebar.close then
      sidebar.close()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Close sidebar' }))

  -- Selection toggle with <Space>
  keymap('n', '<Space>', function()
    local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
    if ok and email_list.toggle_selection then
      email_list.toggle_selection()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Toggle email selection' }))

  -- Select email with 'n'
  keymap('n', 'n', function()
    local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
    if ok and email_list.select_email then
      email_list.select_email()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Select email' }))

  -- Deselect email with 'p'
  keymap('n', 'p', function()
    local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
    if ok and email_list.deselect_email then
      email_list.deselect_email()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Deselect email' }))

  -- Pagination with <C-d> (next page) and <C-u> (previous page)
  keymap('n', '<C-d>', function()
    local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
    if ok and email_list.next_page then
      email_list.next_page()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Next page' }))

  keymap('n', '<C-u>', function()
    local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
    if ok and email_list.prev_page then
      email_list.prev_page()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Previous page' }))

  -- Refresh with 'F'
  keymap('n', 'F', function()
    local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
    if ok and email_list.refresh_email_list then
      email_list.refresh_email_list()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Refresh email list' }))

  -- Context-aware help with 'gH' (floating window)
  keymap('n', 'gH', function()
    local ok, folder_help = pcall(require, 'neotex.plugins.tools.himalaya.ui.folder_help')
    if ok and folder_help.show_folder_help then
      folder_help.show_folder_help()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Show context help' }))

  -- Show keybinding help
  keymap('n', '?', function()
    local ok, folder_help = pcall(require, 'neotex.plugins.tools.himalaya.ui.folder_help')
    if ok and folder_help.show_folder_help then
      folder_help.show_folder_help()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Show keybindings help' }))

  -- Email action keymaps (restored for single-key access)
  -- Delete emails (selection-aware: uses custom selection if any emails selected)
  keymap('n', 'd', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok then
      local state = require('neotex.plugins.tools.himalaya.core.state')
      -- Use selection if any emails selected with custom selection (Space/n/p)
      if #state.get_selected_emails() > 0 then
        main.delete_selected_emails()
      else
        main.delete_current_email()
      end
    end
  end, vim.tbl_extend('force', opts, { desc = 'Delete email(s)' }))

  -- Archive emails (selection-aware: uses custom selection if any emails selected)
  keymap('n', 'a', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok then
      local state = require('neotex.plugins.tools.himalaya.core.state')
      -- Use selection if any emails selected with custom selection (Space/n/p)
      if #state.get_selected_emails() > 0 then
        main.archive_selected_emails()
      else
        main.archive_current_email()
      end
    end
  end, vim.tbl_extend('force', opts, { desc = 'Archive email(s)' }))

  -- Reply to current email
  keymap('n', 'r', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok and main.reply_current_email then
      main.reply_current_email()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Reply' }))

  -- Reply all to current email
  keymap('n', 'R', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok and main.reply_all_current_email then
      main.reply_all_current_email()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Reply all' }))

  -- Forward current email
  keymap('n', 'f', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok and main.forward_current_email then
      main.forward_current_email()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Forward' }))

  -- Move emails (selection-aware: uses custom selection if any emails selected)
  keymap('n', 'm', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok then
      local state = require('neotex.plugins.tools.himalaya.core.state')
      -- Use selection if any emails selected with custom selection (Space/n/p)
      if #state.get_selected_emails() > 0 then
        main.move_selected_emails()
      else
        main.move_current_email()
      end
    end
  end, vim.tbl_extend('force', opts, { desc = 'Move email(s)' }))

  -- Compose new email
  keymap('n', 'c', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok and main.compose_email then
      main.compose_email()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Compose new email' }))

  -- Search emails
  keymap('n', '/', function()
    local ok, search = pcall(require, 'neotex.plugins.tools.himalaya.data.search')
    if ok and search.show_search_ui then
      search.show_search_ui()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Search emails' }))
end

-- Setup preview keymaps
-- Per task 56: NO single-letter action mappings in preview
-- Actions should be accessed via which-key <leader>m menu
function M.setup_preview_keymaps(bufnr)
  local keymap = vim.keymap.set
  local opts = { buffer = bufnr, silent = true }

  -- Close preview
  keymap('n', 'q', function()
    local ok, preview = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_preview')
    if ok and preview.close then
      preview.close()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Close preview' }))

  -- Navigation (j/k scroll content in FOCUS mode)
  keymap('n', 'j', function()
    local ok, preview = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_preview')
    if ok and preview.next_email then
      preview.next_email()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Next email' }))

  keymap('n', 'k', function()
    local ok, preview = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_preview')
    if ok and preview.prev_email then
      preview.prev_email()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Previous email' }))

  -- Help - show which-key hint
  keymap('n', '?', function()
    local notify = require('neotex.util.notifications')
    notify.himalaya('Actions: <leader>m for mail menu | q to close', notify.categories.STATUS)
  end, vim.tbl_extend('force', opts, { desc = 'Show help' }))
end

-- Setup compose keymaps
function M.setup_compose_keymaps(bufnr)
  local keymap = vim.keymap.set
  local opts = { buffer = bufnr, silent = true }

  -- Leader mappings (2-letter maximum per task 67)
  -- These appear in which-key popup only when in compose buffer
  keymap('n', '<leader>me', '<cmd>HimalayaSend<CR>',
    vim.tbl_extend('force', opts, { desc = 'send email' }))
  keymap('n', '<leader>md', '<cmd>HimalayaSaveDraft<CR>',
    vim.tbl_extend('force', opts, { desc = 'save draft' }))
  keymap('n', '<leader>mq', '<cmd>HimalayaDiscard<CR>',
    vim.tbl_extend('force', opts, { desc = 'quit/discard' }))

  -- Note: <C-s> removed to avoid conflict with spelling operations
  -- Use <leader>me to send emails instead

  -- Save draft
  keymap('n', '<C-d>', function()
    local ok, composer = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_composer')
    if ok and composer.save_draft then
      composer.save_draft()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Save draft' }))
  
  -- Discard
  keymap('n', '<C-q>', function()
    local ok, composer = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_composer')
    if ok and composer.discard then
      composer.discard()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Discard email' }))
  
  -- Attach file
  keymap('n', '<C-a>', function()
    local ok, composer = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_composer')
    if ok and composer.attach_file then
      composer.attach_file()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Attach file' }))
  
  -- Help - show compose-specific help with 2-letter mappings
  keymap('n', '?', function()
    local ok, folder_help = pcall(require, 'neotex.plugins.tools.himalaya.ui.folder_help')
    if ok and folder_help.show_compose_help then
      folder_help.show_compose_help()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Show help' }))
end

-- Setup sidebar keymaps
function M.setup_sidebar_keymaps(bufnr)
  local keymap = vim.keymap.set
  local opts = { buffer = bufnr, silent = true }
  
  -- Select folder
  keymap('n', '<CR>', function()
    local ok, sidebar = pcall(require, 'neotex.plugins.tools.himalaya.ui.sidebar')
    if ok and sidebar.select_folder then
      sidebar.select_folder()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Select folder' }))
  
  -- Refresh folders
  keymap('n', 'r', function()
    local ok, sidebar = pcall(require, 'neotex.plugins.tools.himalaya.ui.sidebar')
    if ok and sidebar.refresh then
      sidebar.refresh()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Refresh folders' }))
  
  -- Toggle sidebar
  keymap('n', 'q', function()
    local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.ui')
    if ok and commands.toggle_sidebar then
      commands.toggle_sidebar()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Toggle sidebar' }))
  
  -- Switch account
  keymap('n', 'a', function()
    local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.ui')
    if ok and commands.switch_account then
      commands.switch_account()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Switch account' }))
  
  -- Help
  keymap('n', '?', function()
    local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.ui')
    if ok and commands.show_help then
      commands.show_help('sidebar')
    end
  end, vim.tbl_extend('force', opts, { desc = 'Show help' }))
end

-- Get keybinding for an action
function M.get_keybinding(filetype, action)
  -- Updated keybinding configuration per task 56
  -- Sidebar: No single-letter actions, use <leader>m for mail operations
  local keybindings = {
    ['himalaya-list'] = {
      open = '<CR>',
      toggle_select = '<Space>',
      select = 'n',
      deselect = 'p',
      next_page = '<C-d>',
      prev_page = '<C-u>',
      refresh = 'F',
      close = 'q',
      help = '?',
      context_help = 'gH',
      -- Action keys (restored)
      delete = 'd',
      archive = 'a',
      reply = 'r',
      reply_all = 'R',
      forward = 'f',
      move = 'm',
      compose = 'c',
      search = '/'
    },
    ['himalaya-preview'] = {
      close = 'q',
      next = 'j',
      prev = 'k',
      help = '?'
      -- Actions removed: use <leader>m menu
    },
    ['himalaya-compose'] = {
      -- Leader mappings (2-letter maximum per task 67):
      -- <leader>me - send email (E for Email/Envelope)
      -- <leader>md - save draft (D for Draft)
      -- <leader>mq - quit/discard (Q for Quit)
      save_draft = '<C-d>',
      discard = '<C-q>',
      attach = '<C-a>',
      help = '?'
    },
    ['himalaya-sidebar'] = {
      select = '<CR>',
      refresh = 'r',
      close = 'q',
      switch_account = 'a',
      help = '?'
    }
  }

  return keybindings[filetype] and keybindings[filetype][action]
end

return M