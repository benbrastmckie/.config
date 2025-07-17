-- UI Coordinator Module
-- Handles UI component initialization and window/buffer coordination

local M = {}

-- Dependencies
local state = require('neotex.plugins.tools.himalaya.core.state')
local window_stack = require('neotex.plugins.tools.himalaya.ui.window_stack')
local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
local email_composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
local email_preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
local notify = require('neotex.util.notifications')
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Module state
local module_state = {
  initialized = false,
  buffers = {
    email_list = nil,
    email_read = nil,
    email_compose = nil,
  },
  _email_reading_win = nil,  -- Track email reading window for focus restoration
}

-- Initialize UI components
function M.init()
  if module_state.initialized then
    return
  end
  
  -- Initialize state management first
  state.init()
  
  -- Initialize sidebar with state
  sidebar.init()
  
  -- Initialize email list module with buffer reference
  email_list.init(module_state.buffers)
  
  -- Initialize modules
  local config = require('neotex.plugins.tools.himalaya.core.config')
  email_composer.setup(config.config)
  email_preview.setup(config.config)
  
  -- Sync state with sidebar configuration (non-intrusive)
  state.sync_with_sidebar()
  
  module_state.initialized = true
  logger.info('UI coordinator initialized')
end

-- Get buffer tracking table
function M.get_buffers()
  return module_state.buffers
end

-- Set buffer for tracking
function M.set_buffer(name, buf)
  -- Allow setting any valid buffer name
  if type(name) == 'string' then
    module_state.buffers[name] = buf
  end
end

-- Helper function to open a compose buffer in a proper window
function M.open_compose_buffer_in_window(buf, opts)
  if not buf then
    return nil
  end
  
  opts = opts or {}
  
  -- Find or create a suitable window for editing (not sidebar)
  local sidebar_win = sidebar.get_win()
  local current_win = vim.api.nvim_get_current_win()
  local target_win = nil
  
  -- Look for a non-sidebar window
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= sidebar_win and vim.api.nvim_win_is_valid(win) then
      local win_buf = vim.api.nvim_win_get_buf(win)
      local buftype = vim.api.nvim_buf_get_option(win_buf, 'buftype')
      local filetype = vim.api.nvim_buf_get_option(win_buf, 'filetype')
      
      -- Skip special buffers
      if buftype == '' and filetype ~= 'himalaya-preview' then
        target_win = win
        break
      end
    end
  end
  
  -- If no suitable window, create one
  if not target_win then
    -- Save current window position
    local saved_win = current_win
    
    -- If we have a sidebar, position the split correctly
    if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
      -- Move to sidebar temporarily to create split in right place
      vim.api.nvim_set_current_win(sidebar_win)
      vim.cmd('rightbelow vsplit')
      target_win = vim.api.nvim_get_current_win()
      -- Return to original window
      if saved_win ~= sidebar_win and vim.api.nvim_win_is_valid(saved_win) then
        vim.api.nvim_set_current_win(saved_win)
      end
    else
      -- No sidebar, just split current window
      vim.cmd('vsplit')
      target_win = vim.api.nvim_get_current_win()
    end
  end
  
  -- Now set up the compose buffer in the target window
  vim.api.nvim_set_current_win(target_win)
  vim.api.nvim_win_set_buf(target_win, buf)
  
  -- Track in window stack
  window_stack.push({
    type = 'compose',
    buffer = buf,
    window = target_win
  })
  
  -- Position cursor on empty field and enter insert mode
  vim.schedule(function()
    -- Ensure we're still in the right window
    if vim.api.nvim_win_is_valid(target_win) then
      vim.api.nvim_set_current_win(target_win)
    end
    -- Position cursor based on operation type
    if opts.position_to_body then
      email_composer.position_cursor_in_body(buf)
    else
      email_composer.position_cursor_on_empty_field(buf)
    end
    -- Enter insert mode
    vim.cmd('startinsert!')
  end)
  
  return buf
end

-- Open email window (floating)
function M.open_email_window(buf, title, parent_win)
  -- Calculate window size
  local ui = vim.api.nvim_list_uis()[1]
  local width = math.floor(ui.width * 0.8)
  local height = math.floor(ui.height * 0.8)
  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)
  
  -- Create floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = title,
    title_pos = 'center',
  })
  
  -- Window settings
  vim.api.nvim_win_set_option(win, 'wrap', true)
  vim.api.nvim_win_set_option(win, 'linebreak', true)
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  
  -- Track window in stack for proper focus restoration
  -- Use provided parent window or current window as fallback
  window_stack.push(win, parent_win or vim.api.nvim_get_current_win())
  
  return win
end

-- Close current view using window stack
function M.close_current_view()
  -- In test mode, don't attempt window operations
  if _G.HIMALAYA_TEST_MODE then
    logger.debug('close_current_view called in test mode')
    return
  end
  
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()
  
  -- Try to close using window stack first
  if not window_stack.close_current() then
    -- If not in stack, close normally
    vim.cmd('close')
  end
  
  -- Check if we need to refresh email list
  local is_email_buffer = vim.bo[current_buf].filetype == 'himalaya-email'
  
  -- Refresh email list after closing email reading view
  if is_email_buffer then
    vim.defer_fn(function()
      if sidebar.is_open() then
        email_list.refresh_email_list()
      end
    end, 100)
  end
end

-- Close Himalaya entirely (all buffers and sidebar)
function M.close_himalaya()
  -- Save state before closing
  state.save()
  
  -- Close and cleanup sidebar (including buffer)
  sidebar.close_and_cleanup()
  
  -- Close all tracked Himalaya buffers
  local closed_buffers = 0
  for name, buf in pairs(module_state.buffers) do
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
      closed_buffers = closed_buffers + 1
    end
  end
  
  -- Find and close any remaining Himalaya buffers by filetype
  local all_buffers = vim.api.nvim_list_bufs()
  for _, buf in ipairs(all_buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      local ok, filetype = pcall(vim.api.nvim_buf_get_option, buf, 'filetype')
      if ok and filetype and filetype:match('^himalaya%-') then
        vim.api.nvim_buf_delete(buf, { force = true })
        closed_buffers = closed_buffers + 1
      end
    end
  end
  
  -- Clear window stack
  window_stack.clear()
  
  -- Reset buffer tracking
  module_state.buffers = {
    email_list = nil,
    email_read = nil,
    email_compose = nil,
  }
  
  logger.info('Himalaya closed', { buffers_closed = closed_buffers })
end

-- Focus restoration helpers
function M.set_email_reading_window(win)
  module_state._email_reading_win = win
end

function M.get_email_reading_window()
  return module_state._email_reading_win
end

function M.clear_email_reading_window()
  module_state._email_reading_win = nil
end

-- Restore focus after closing compose/preview windows
function M.restore_focus(buf, parent_win, parent_buf)
  vim.defer_fn(function()
    -- First try the stored email reading window (most reliable for replies)
    if module_state._email_reading_win and vim.api.nvim_win_is_valid(module_state._email_reading_win) then
      vim.api.nvim_set_current_win(module_state._email_reading_win)
      module_state._email_reading_win = nil  -- Clear it after use
    elseif parent_win and vim.api.nvim_win_is_valid(parent_win) then
      vim.api.nvim_set_current_win(parent_win)
    elseif parent_buf and vim.api.nvim_buf_is_valid(parent_buf) then
      -- Parent window was closed, try to find a window showing the parent buffer
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == parent_buf then
          vim.api.nvim_set_current_win(win)
          break
        end
      end
    end
  end, 50)
end

return M