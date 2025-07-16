-- Main UI module for Himalaya plugin
-- Central hub for all UI components

local M = {}

-- Load UI submodules
local main = require('neotex.plugins.tools.himalaya.ui.main')
M.window_stack = require('neotex.plugins.tools.himalaya.ui.window_stack')
M.sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
M.state = require('neotex.plugins.tools.himalaya.core.state')
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
M.compose_email = main.compose_email
M.open_email_window = main.open_email_window
M.reset_pagination = main.reset_pagination
M.next_page = main.next_page
M.prev_page = main.prev_page
M.refresh_email_list = main.refresh_email_list
M.send_current_email = main.send_current_email
M.is_email_buffer_open = main.is_email_buffer_open
M.get_current_email_id = main.get_current_email_id
M.close_current_view = main.close_current_view
M.close_himalaya = main.close_himalaya
M.update_email_display = main.update_email_display
M.refresh_current_view = main.refresh_current_view
M.reply_current_email = main.reply_current_email
M.reply_all_current_email = main.reply_all_current_email
M.reply_email = main.reply_email
M.parse_email_for_reply = main.parse_email_for_reply
M.forward_current_email = main.forward_current_email
M.forward_email = main.forward_email
M.delete_current_email = main.delete_current_email
M.handle_missing_trash_folder = main.handle_missing_trash_folder
M.permanent_delete_email = main.permanent_delete_email
M.move_email_to_folder = main.move_email_to_folder
M.prompt_custom_folder_move = main.prompt_custom_folder_move
M.archive_current_email = main.archive_current_email
M.spam_current_email = main.spam_current_email
M.search_emails = main.search_emails
M.can_restore_session = main.can_restore_session
M.restore_session = main.restore_session
M.prompt_session_restore = main.prompt_session_restore
M.close_without_saving = main.close_without_saving
M.close_and_save_draft = main.close_and_save_draft
M.stop_sync_status_updates = main.stop_sync_status_updates

-- Also expose main module and buffers for direct access
M.main = main
M.buffers = main.buffers

-- Initialize UI components
function M.setup()
  -- Initialize main UI
  M.init()
  
  -- Setup notifications
  M.notifications.setup()
  
  -- Initialize new UI modules
  local config = require('neotex.plugins.tools.himalaya.core.config')
  
  -- Initialize modules
  local email_preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
  local email_composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
  local features = require('neotex.plugins.tools.himalaya.ui.features')
  
  email_preview.setup(config.config)
  email_composer.setup(config.config)
  
  -- Export Phase 8 UI functions
  M.show_unified_inbox = features.show_unified_inbox
  M.show_attachments_list = features.show_attachments_list
  M.show_trash_list = features.show_trash_list
  M.pick_attachment = features.pick_attachment
  M.show_headers = features.show_headers
  
  -- Setup autocmds for email actions
  local group = vim.api.nvim_create_augroup('HimalayaEmailActions', { clear = true })
  
  -- Refresh sidebar when emails are moved, deleted, or sent
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = { 'HimalayaEmailMoved', 'HimalayaEmailDeleted', 'HimalayaEmailSent' },
    callback = function()
      -- Refresh sidebar if it's open
      if M.sidebar.is_open() then
        vim.defer_fn(function()
          M.refresh_email_list()
        end, 100)
      end
    end,
    desc = 'Refresh Himalaya sidebar after email actions'
  })
  
  -- Refresh sidebar when tags are changed
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'HimalayaTagChanged',
    callback = function()
      -- Refresh sidebar if it's open
      if M.sidebar.is_open() then
        vim.defer_fn(function()
          M.refresh_email_list()
        end, 100)
      end
    end,
    desc = 'Refresh Himalaya sidebar after tag changes'
  })
end

return M