-- Himalaya Email Client Picker Integration
-- Telescope and fzf integration for folder/account selection

local M = {}

local config = require('neotex.plugins.tools.himalaya.config')
local utils = require('neotex.plugins.tools.himalaya.utils')

-- Setup telescope integration
function M.setup_telescope()
  local has_telescope, telescope = pcall(require, 'telescope')
  if not has_telescope then
    return
  end
  
  -- Register custom pickers
  telescope.setup({
    extensions = {
      himalaya = {
        folder_preview = true,
        account_preview = true,
      },
    },
  })
  
  -- Load extension if available
  pcall(telescope.load_extension, 'himalaya')
end

-- Show folder picker using Telescope
function M.show_folders_telescope()
  local has_telescope, telescope = pcall(require, 'telescope')
  if not has_telescope then
    M.show_folders_native()
    return
  end
  
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  
  -- Get folders for current account
  local folders = utils.get_folders(config.state.current_account)
  if not folders then
    vim.notify('Failed to get folders', vim.log.levels.ERROR)
    return
  end
  
  -- Create folder entries with metadata
  local folder_entries = {}
  for _, folder in ipairs(folders) do
    local unread_count = utils.get_unread_count(config.state.current_account, folder)
    local total_count = utils.get_email_count(config.state.current_account, folder)
    local display = string.format('%-30s [%d emails, %d unread]', 
                                 folder, total_count or 0, unread_count or 0)
    table.insert(folder_entries, {
      value = folder,
      display = display,
      ordinal = folder,
    })
  end
  
  pickers.new({}, {
    prompt_title = config.get_current_account().name .. ' - Select Folder',
    finder = finders.new_table({
      results = folder_entries,
      entry_maker = function(entry)
        return {
          value = entry.value,
          display = entry.display,
          ordinal = entry.ordinal,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          config.switch_folder(selection.value)
          require('neotex.plugins.tools.himalaya.ui').show_email_list({selection.value})
        end
      end)
      return true
    end,
  }):find()
end

-- Show account picker using Telescope
function M.show_accounts_telescope()
  local has_telescope, telescope = pcall(require, 'telescope')
  if not has_telescope then
    M.show_accounts_native()
    return
  end
  
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  
  -- Create account entries
  local account_entries = {}
  for account_name, account_info in pairs(config.config.accounts) do
    local unread_count = utils.get_unread_count(account_name, 'INBOX')
    local current = account_name == config.state.current_account and ' (current)' or ''
    local display = string.format('%-20s %-30s [INBOX: %d unread]%s', 
                                 account_info.name, account_info.email, 
                                 unread_count or 0, current)
    table.insert(account_entries, {
      value = account_name,
      display = display,
      ordinal = account_info.name .. ' ' .. account_info.email,
    })
  end
  
  pickers.new({}, {
    prompt_title = 'Select Account',
    finder = finders.new_table({
      results = account_entries,
      entry_maker = function(entry)
        return {
          value = entry.value,
          display = entry.display,
          ordinal = entry.ordinal,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          if config.switch_account(selection.value) then
            require('neotex.plugins.tools.himalaya.ui').show_email_list()
          end
        end
      end)
      return true
    end,
  }):find()
end

-- Show folder picker using fzf-lua
function M.show_folders_fzf()
  local has_fzf, fzf = pcall(require, 'fzf-lua')
  if not has_fzf then
    M.show_folders_native()
    return
  end
  
  local folders = utils.get_folders(config.state.current_account)
  if not folders then
    vim.notify('Failed to get folders', vim.log.levels.ERROR)
    return
  end
  
  -- Create folder entries
  local folder_entries = {}
  for _, folder in ipairs(folders) do
    local unread_count = utils.get_unread_count(config.state.current_account, folder)
    local total_count = utils.get_email_count(config.state.current_account, folder)
    local display = string.format('%-30s [%d emails, %d unread]', 
                                 folder, total_count or 0, unread_count or 0)
    table.insert(folder_entries, display)
  end
  
  fzf.fzf_exec(folder_entries, {
    prompt = 'Select Folder> ',
    actions = {
      ['default'] = function(selected)
        if selected and selected[1] then
          local folder = selected[1]:match('^(%S+)')
          if folder then
            config.switch_folder(folder)
            require('neotex.plugins.tools.himalaya.ui').show_email_list({folder})
          end
        end
      end,
    },
  })
end

-- Show account picker using fzf-lua
function M.show_accounts_fzf()
  local has_fzf, fzf = pcall(require, 'fzf-lua')
  if not has_fzf then
    M.show_accounts_native()
    return
  end
  
  local account_entries = {}
  for account_name, account_info in pairs(config.config.accounts) do
    local unread_count = utils.get_unread_count(account_name, 'INBOX')
    local current = account_name == config.state.current_account and ' (current)' or ''
    local display = string.format('%-20s %-30s [INBOX: %d unread]%s', 
                                 account_info.name, account_info.email, 
                                 unread_count or 0, current)
    table.insert(account_entries, display)
  end
  
  fzf.fzf_exec(account_entries, {
    prompt = 'Select Account> ',
    actions = {
      ['default'] = function(selected)
        if selected and selected[1] then
          -- Extract account name from display string
          local account_name = nil
          for name, info in pairs(config.config.accounts) do
            if selected[1]:find(info.name, 1, true) then
              account_name = name
              break
            end
          end
          
          if account_name and config.switch_account(account_name) then
            require('neotex.plugins.tools.himalaya.ui').show_email_list()
          end
        end
      end,
    },
  })
end

-- Native folder picker (fallback)
function M.show_folders_native()
  local folders = utils.get_folders(config.state.current_account)
  if not folders then
    vim.notify('Failed to get folders', vim.log.levels.ERROR)
    return
  end
  
  -- Create selection buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-picker')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  
  -- Format folder list
  local lines = {
    config.get_current_account().name .. ' - Select Folder',
    string.rep('─', 40),
    '',
  }
  
  for i, folder in ipairs(folders) do
    local unread_count = utils.get_unread_count(config.state.current_account, folder)
    local total_count = utils.get_email_count(config.state.current_account, folder)
    local line = string.format('%d. %-25s [%d emails, %d unread]', 
                              i, folder, total_count or 0, unread_count or 0)
    table.insert(lines, line)
  end
  
  table.insert(lines, '')
  table.insert(lines, string.rep('─', 40))
  table.insert(lines, '<CR>:select  q:close')
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Store folder list
  vim.b[buf].himalaya_folders = folders
  
  -- Set up keymap for selection
  vim.keymap.set('n', '<CR>', function()
    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    local folder_index = line_num - 3 -- Account for header lines
    if folder_index > 0 and folder_index <= #folders then
      local folder = folders[folder_index]
      vim.api.nvim_buf_delete(buf, { force = true })
      config.switch_folder(folder)
      require('neotex.plugins.tools.himalaya.ui').show_email_list({folder})
    end
  end, { buffer = buf, silent = true })
  
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end, { buffer = buf, silent = true })
  
  -- Open in floating window
  local ui = require('neotex.plugins.tools.himalaya.ui')
  ui.open_email_window(buf, 'Select Folder')
end

-- Native account picker (fallback)
function M.show_accounts_native()
  local accounts = {}
  for account_name, account_info in pairs(config.config.accounts) do
    table.insert(accounts, {name = account_name, info = account_info})
  end
  
  -- Create selection buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-picker')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  
  local lines = {
    'Select Account',
    string.rep('─', 40),
    '',
  }
  
  for i, account in ipairs(accounts) do
    local unread_count = utils.get_unread_count(account.name, 'INBOX')
    local current = account.name == config.state.current_account and ' (current)' or ''
    local line = string.format('%d. %-15s %-25s [INBOX: %d unread]%s', 
                              i, account.info.name, account.info.email, 
                              unread_count or 0, current)
    table.insert(lines, line)
  end
  
  table.insert(lines, '')
  table.insert(lines, string.rep('─', 40))
  table.insert(lines, '<CR>:select  q:close')
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  vim.b[buf].himalaya_accounts = accounts
  
  -- Set up keymap for selection
  vim.keymap.set('n', '<CR>', function()
    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    local account_index = line_num - 3
    if account_index > 0 and account_index <= #accounts then
      local account = accounts[account_index]
      vim.api.nvim_buf_delete(buf, { force = true })
      if config.switch_account(account.name) then
        require('neotex.plugins.tools.himalaya.ui').show_email_list()
      end
    end
  end, { buffer = buf, silent = true })
  
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end, { buffer = buf, silent = true })
  
  -- Open in floating window
  local ui = require('neotex.plugins.tools.himalaya.ui')
  ui.open_email_window(buf, 'Select Account')
end

-- Main folder picker function (chooses method based on config)
function M.show_folders()
  local picker_type = config.config.folder_picker
  
  if picker_type == 'telescope' then
    M.show_folders_telescope()
  elseif picker_type == 'fzf' then
    M.show_folders_fzf()
  else
    M.show_folders_native()
  end
end

-- Main account picker function (chooses method based on config)
function M.show_accounts()
  local picker_type = config.config.folder_picker
  
  if picker_type == 'telescope' then
    M.show_accounts_telescope()
  elseif picker_type == 'fzf' then
    M.show_accounts_fzf()
  else
    M.show_accounts_native()
  end
end

-- Email search picker using Telescope
function M.search_emails_telescope(query)
  local has_telescope, telescope = pcall(require, 'telescope')
  if not has_telescope then
    vim.notify('Telescope not available for search', vim.log.levels.WARN)
    return
  end
  
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  
  -- Perform search
  local results = utils.search_emails(config.state.current_account, query)
  if not results then
    vim.notify('Search failed', vim.log.levels.ERROR)
    return
  end
  
  pickers.new({}, {
    prompt_title = 'Search Results: ' .. query,
    finder = finders.new_table({
      results = results,
      entry_maker = function(email)
        local status = email.flags and email.flags.seen and ' ' or '*'
        local from = utils.truncate_string(email.from or 'Unknown', 25)
        local subject = utils.truncate_string(email.subject or '(No subject)', 50)
        local display = string.format('[%s] %s  %s', status, from, subject)
        
        return {
          value = email,
          display = display,
          ordinal = from .. ' ' .. subject,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and selection.value.id then
          require('neotex.plugins.tools.himalaya.ui').read_email(selection.value.id)
        end
      end)
      return true
    end,
  }):find()
end

-- Contact picker for email composition (future enhancement)
function M.show_contacts()
  -- TODO: Implement contact picker integration
  -- This would integrate with contacts from OAuth2 scopes
  vim.notify('Contact picker not yet implemented', vim.log.levels.INFO)
end

return M