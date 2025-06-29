-- Main UI module for Himalaya plugin
-- Central hub for all UI components

local M = {}

-- Load UI submodules
local main = require('neotex.plugins.tools.himalaya.ui.main')
M.window_stack = require('neotex.plugins.tools.himalaya.ui.window_stack')
M.sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
M.state = require('neotex.plugins.tools.himalaya.ui.state')
M.notifications = require('neotex.plugins.tools.himalaya.ui.notifications')

-- Re-export main UI functions for backward compatibility
M.init = main.init
M.toggle_email_sidebar = main.toggle_email_sidebar
M.show_email_list = main.show_email_list
M.format_email_list = main.format_email_list
M.get_sync_status_line = main.get_sync_status_line
M.start_sync_status_updates = main.start_sync_status_updates
M.stop_sync_status_updates = main.stop_sync_status_updates
M.update_sidebar_sync_status = main.update_sidebar_sync_status
M.refresh_sidebar_header = main.refresh_sidebar_header
M.read_email = main.read_email
M.format_email_content = main.format_email_content
M.process_email_body = main.process_email_body
M.compose_email = main.compose_email
M.open_email_window = main.open_email_window
M.reset_pagination = main.reset_pagination
M.next_page = main.next_page
M.prev_page = main.prev_page
M.refresh_email_list = main.refresh_email_list
M.send_current_email = main.send_current_email
M.is_email_buffer_open = main.is_email_buffer_open

-- Also expose main module for direct access
M.main = main

-- Initialize UI components
function M.setup()
  -- Initialize main UI
  M.init()
  
  -- Setup notifications
  M.notifications.setup()
  
  -- Any other UI-wide initialization
end

return M