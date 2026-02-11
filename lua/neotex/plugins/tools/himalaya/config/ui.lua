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
function M.setup_email_list_keymaps(bufnr)
  local keymap = vim.keymap.set
  local opts = { buffer = bufnr, silent = true }

  -- Note: This is a simplified version. The full implementation
  -- requires access to UI modules which creates a dependency.
  -- This is the documented architectural compromise.

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

  -- Basic navigation
  keymap('n', '<CR>', function()
    -- Delegate to email list module
    local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
    if ok and email_list.handle_enter then
      email_list.handle_enter()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Open email or draft' }))
  
  -- Selection
  keymap('n', '<Space>', function()
    local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
    if ok and email_list.toggle_selection then
      email_list.toggle_selection()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Toggle email selection' }))
  
  -- Actions
  keymap('n', 'd', function()
    local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.email')
    if ok and commands.delete_selected then
      commands.delete_selected()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Delete selected emails' }))
  
  keymap('n', 'm', function()
    local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.email')
    if ok and commands.move_selected then
      commands.move_selected()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Move selected emails' }))
  
  keymap('n', 'c', function()
    local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.email')
    if ok and commands.compose then
      commands.compose()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Compose new email' }))
  
  keymap('n', 'r', function()
    local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.email')
    if ok and commands.reply then
      commands.reply()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Reply to email' }))
  
  keymap('n', 'R', function()
    local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.email')
    if ok and commands.reply_all then
      commands.reply_all()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Reply all' }))
  
  keymap('n', 'f', function()
    local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.email')
    if ok and commands.forward then
      commands.forward()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Forward email' }))
  
  -- Navigation
  keymap('n', 'n', function()
    local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
    if ok and email_list.next_page then
      email_list.next_page()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Next page' }))
  
  keymap('n', 'p', function()
    local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
    if ok and email_list.prev_page then
      email_list.prev_page()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Previous page' }))
  
  -- Search
  keymap('n', '/', function()
    local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.email')
    if ok and commands.search then
      commands.search()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Search emails' }))
  
  -- Refresh
  keymap('n', 'gr', function()
    local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
    if ok and email_list.refresh then
      email_list.refresh()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Refresh email list' }))
  
  -- Help
  keymap('n', '?', function()
    local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.ui')
    if ok and commands.show_help then
      commands.show_help('list')
    end
  end, vim.tbl_extend('force', opts, { desc = 'Show help' }))
end

-- Setup preview keymaps
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
  
  -- Navigation
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
  
  -- Actions
  keymap('n', 'r', function()
    local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.email')
    if ok and commands.reply then
      commands.reply()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Reply to email' }))
  
  keymap('n', 'R', function()
    local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.email')
    if ok and commands.reply_all then
      commands.reply_all()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Reply all' }))
  
  keymap('n', 'f', function()
    local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.email')
    if ok and commands.forward then
      commands.forward()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Forward email' }))
  
  keymap('n', 'd', function()
    local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.email')
    if ok and commands.delete_current then
      commands.delete_current()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Delete email' }))
  
  -- Help
  keymap('n', '?', function()
    local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.ui')
    if ok and commands.show_help then
      commands.show_help('preview')
    end
  end, vim.tbl_extend('force', opts, { desc = 'Show help' }))
end

-- Setup compose keymaps
function M.setup_compose_keymaps(bufnr)
  local keymap = vim.keymap.set
  local opts = { buffer = bufnr, silent = true }
  
  -- Send email
  keymap('n', '<C-s>', function()
    local ok, composer = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_composer')
    if ok and composer.send then
      composer.send()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Send email' }))
  
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
  
  -- Help
  keymap('n', '?', function()
    local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.ui')
    if ok and commands.show_help then
      commands.show_help('compose')
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
  -- This would be populated from a keybinding configuration
  -- For now, return defaults
  local keybindings = {
    ['himalaya-list'] = {
      open = '<CR>',
      select = '<Space>',
      delete = 'd',
      move = 'm',
      compose = 'c',
      reply = 'r',
      reply_all = 'R',
      forward = 'f',
      next_page = 'n',
      prev_page = 'p',
      search = '/',
      refresh = 'gr',
      help = '?'
    },
    ['himalaya-preview'] = {
      close = 'q',
      next = 'j',
      prev = 'k',
      reply = 'r',
      reply_all = 'R',
      forward = 'f',
      delete = 'd',
      help = '?'
    },
    ['himalaya-compose'] = {
      send = '<C-s>',
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