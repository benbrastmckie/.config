-- Comprehensive Delete Operation Diagnostics
-- Traces every step of the delete operation to find the root cause

local M = {}

-- Debug wrapper for delete_current_email
function M.debug_delete_operation()
  print("=== DELETE OPERATION DIAGNOSTICS ===")
  
  -- Step 1: Check current buffer context
  print("\n1. BUFFER CONTEXT:")
  local buf = vim.api.nvim_get_current_buf()
  local filetype = vim.bo[buf].filetype
  print("   Current buffer:", buf)
  print("   Filetype:", filetype)
  print("   Buffer name:", vim.api.nvim_buf_get_name(buf))
  
  -- Step 2: Check email ID extraction methods
  print("\n2. EMAIL ID EXTRACTION:")
  local buffer_email_id = vim.b[buf].himalaya_email_id
  print("   Buffer variable email_id:", buffer_email_id or "nil")
  
  local ui = require('neotex.plugins.tools.himalaya.ui')
  local cursor_email_id = ui.get_current_email_id()
  print("   Cursor-based email_id:", cursor_email_id or "nil")
  
  -- Test cursor position and email data
  if filetype == 'himalaya-list' then
    local line_num = vim.fn.line('.')
    local email_index = line_num - 4
    local emails = vim.b.himalaya_emails
    print("   Current line:", line_num)
    print("   Calculated email index:", email_index)
    print("   Emails in buffer:", emails and #emails or "nil")
    
    if emails and email_index > 0 and emails[email_index] then
      print("   Email at index:", emails[email_index].id or "nil")
      print("   Subject:", emails[email_index].subject or "nil")
    else
      print("   No email found at calculated index")
    end
  end
  
  -- Step 3: Check trash system configuration
  print("\n3. TRASH SYSTEM:")
  local config = require('neotex.plugins.tools.himalaya.config')
  local trash_manager = require('neotex.plugins.tools.himalaya.trash_manager')
  
  print("   Trash enabled in config:", config.config.trash and config.config.trash.enabled or "nil")
  print("   Trash manager enabled:", trash_manager.is_enabled())
  print("   Trash directory:", trash_manager.get_trash_directory())
  
  -- Step 4: Test actual delete function call
  print("\n4. DELETE FUNCTION TEST:")
  local email_id = buffer_email_id or cursor_email_id
  
  if email_id then
    print("   Found email_id:", email_id)
    print("   Current account:", config.state.current_account)
    print("   Current folder:", config.state.current_folder)
    
    -- Test the smart_delete_email function
    local utils = require('neotex.plugins.tools.himalaya.utils')
    print("   Calling smart_delete_email...")
    
    local success, error_type, extra = utils.smart_delete_email(config.state.current_account, email_id)
    print("   Result - Success:", success)
    print("   Result - Error type:", error_type)
    print("   Result - Extra info:", extra)
    
  else
    print("   ERROR: No email_id found!")
  end
  
  -- Step 5: Check keymap binding
  print("\n5. KEYMAP VERIFICATION:")
  local keymaps = vim.api.nvim_buf_get_keymap(buf, 'n')
  local gD_keymap = nil
  for _, keymap in ipairs(keymaps) do
    if keymap.lhs == 'gD' then
      gD_keymap = keymap
      break
    end
  end
  
  if gD_keymap then
    print("   gD keymap found:", gD_keymap.rhs or "nil")
    print("   gD description:", gD_keymap.desc or "nil")
  else
    print("   ERROR: No gD keymap found in buffer!")
  end
  
  print("\n=== DIAGNOSTICS COMPLETE ===")
end

-- Wrapper that can be called as a command
function M.run_diagnostics()
  M.debug_delete_operation()
end

-- Setup command
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaDeleteDiagnostics', M.run_diagnostics, {
    desc = 'Run comprehensive delete operation diagnostics'
  })
end

return M