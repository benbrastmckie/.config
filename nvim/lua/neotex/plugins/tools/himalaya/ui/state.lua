-- Himalaya State Management
-- Session persistence and improved UX state handling

local M = {}

-- Default state structure
M.state = {
  current_account = nil,
  current_folder = 'INBOX',
  selected_email = nil,
  sidebar_width = 50,
  sidebar_position = 'left',
  last_query = nil,
  last_search_results = nil,
  window_positions = {},
  session_timestamp = nil,
}

-- State file path
local function get_state_file()
  local data_dir = vim.fn.stdpath('data') .. '/himalaya'
  vim.fn.mkdir(data_dir, 'p')
  return data_dir .. '/state.json'
end

-- Save state to disk
function M.save()
  local state_file = get_state_file()
  
  -- Add timestamp
  M.state.session_timestamp = os.time()
  
  local encoded = vim.fn.json_encode(M.state)
  
  local file = io.open(state_file, 'w')
  if file then
    file:write(encoded)
    file:close()
    return true
  else
    vim.notify('Failed to save Himalaya state', vim.log.levels.WARN)
    return false
  end
end

-- Load state from disk
function M.load()
  local state_file = get_state_file()
  
  if vim.fn.filereadable(state_file) == 1 then
    local content = vim.fn.readfile(state_file)
    if #content > 0 then
      local ok, decoded = pcall(vim.fn.json_decode, content[1])
      if ok and type(decoded) == 'table' then
        -- Merge with default state to handle new fields
        M.state = vim.tbl_extend('force', M.state, decoded)
        return true
      else
        vim.notify('Failed to parse Himalaya state file', vim.log.levels.WARN)
      end
    end
  end
  
  return false
end

-- Get current state
function M.get_state()
  return M.state
end

-- Update specific state field
function M.set(key, value)
  if M.state[key] ~= nil then
    M.state[key] = value
    return true
  end
  return false
end

-- Get specific state field
function M.get(key)
  return M.state[key]
end

-- Set current account
function M.set_current_account(account)
  M.state.current_account = account
end

-- Get current account
function M.get_current_account()
  return M.state.current_account
end

-- Get current folder
function M.get_current_folder()
  return M.state.current_folder
end

-- Set current folder
function M.set_current_folder(folder)
  M.state.current_folder = folder
  M.save()
end

-- Get current page
function M.get_current_page()
  return M.state.current_page
end

-- Set current page
function M.set_current_page(page)
  M.state.current_page = page
  M.save()
end

-- Get page size
function M.get_page_size()
  return M.state.page_size
end

-- Set total emails
function M.set_total_emails(count)
  M.state.total_emails = count
end

-- Get total emails
function M.get_total_emails()
  return M.state.total_emails or 0
end

-- Check if initialized
function M.is_initialized()
  return M.state ~= nil
end


-- Set selected email
function M.set_selected_email(email_id)
  M.state.selected_email = email_id
end

-- Get selected email
function M.get_selected_email()
  return M.state.selected_email
end

-- Set sidebar width
function M.set_sidebar_width(width)
  M.state.sidebar_width = width
end

-- Get sidebar width
function M.get_sidebar_width()
  return M.state.sidebar_width
end

-- Set sidebar position
function M.set_sidebar_position(position)
  if position == 'left' or position == 'right' then
    M.state.sidebar_position = position
    return true
  end
  return false
end

-- Get sidebar position
function M.get_sidebar_position()
  return M.state.sidebar_position
end

-- Set last search query
function M.set_last_query(query)
  M.state.last_query = query
end

-- Get last search query
function M.get_last_query()
  return M.state.last_query
end

-- Store search results
function M.set_search_results(results)
  M.state.last_search_results = results
end

-- Get search results
function M.get_search_results()
  return M.state.last_search_results
end

-- Store window position for email
function M.set_window_position(email_id, position)
  M.state.window_positions[email_id] = position
end

-- Get window position for email
function M.get_window_position(email_id)
  return M.state.window_positions[email_id]
end

-- Clear window positions (cleanup)
function M.clear_window_positions()
  M.state.window_positions = {}
end

-- Reset state to defaults
function M.reset()
  M.state = {
    current_account = nil,
    current_folder = 'INBOX',
    selected_email = nil,
    sidebar_width = 50,
    sidebar_position = 'left',
    last_query = nil,
    last_search_results = nil,
    window_positions = {},
    session_timestamp = nil,
  }
end

-- Get session age in minutes
function M.get_session_age()
  if M.state.session_timestamp then
    return math.floor((os.time() - M.state.session_timestamp) / 60)
  end
  return nil
end

-- Check if state is fresh (less than 24 hours old)
function M.is_state_fresh()
  local age = M.get_session_age()
  return age and age < (24 * 60) -- 24 hours in minutes
end

-- Auto-save functionality
local auto_save_timer = nil

-- Start auto-save timer (saves every 5 minutes)
function M.start_auto_save(interval_minutes)
  interval_minutes = interval_minutes or 5
  local interval_ms = interval_minutes * 60 * 1000
  
  if auto_save_timer then
    auto_save_timer:stop()
    auto_save_timer:close()
  end
  
  auto_save_timer = vim.loop.new_timer()
  auto_save_timer:start(interval_ms, interval_ms, vim.schedule_wrap(function()
    M.save()
  end))
end

-- Stop auto-save timer
function M.stop_auto_save()
  if auto_save_timer then
    auto_save_timer:stop()
    auto_save_timer:close()
    auto_save_timer = nil
  end
end

-- Initialize state management
function M.init()
  -- Load existing state
  M.load()
  
  -- Start auto-save
  M.start_auto_save()
  
  -- Setup cleanup autocmd
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = vim.api.nvim_create_augroup('HimalayaState', { clear = true }),
    callback = function()
      M.stop_auto_save()
      M.save()
    end,
    desc = 'Save Himalaya state on exit'
  })
end

-- Sync state with sidebar
function M.sync_with_sidebar()
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  
  -- Update sidebar width from state
  if M.state.sidebar_width ~= sidebar.get_width() then
    sidebar.set_width(M.state.sidebar_width)
  end
  
  -- Update sidebar position from state
  if M.state.sidebar_position ~= sidebar.config.position then
    sidebar.set_position(M.state.sidebar_position)
  end
end

-- Export state for debugging
function M.export_state()
  return vim.deepcopy(M.state)
end

-- Import state (for testing/debugging)
function M.import_state(new_state)
  if type(new_state) == 'table' then
    M.state = vim.tbl_extend('force', M.state, new_state)
    return true
  end
  return false
end

return M