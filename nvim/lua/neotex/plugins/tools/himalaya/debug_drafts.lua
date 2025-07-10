-- Debug module for draft issues

local M = {}

local logger = require('neotex.plugins.tools.himalaya.core.logger')
local utils = require('neotex.plugins.tools.himalaya.utils')
local config = require('neotex.plugins.tools.himalaya.core.config')
local email_cache = require('neotex.plugins.tools.himalaya.core.email_cache')

function M.debug_draft_list()
  local account = config.get_current_account_name()
  local draft_folder = utils.find_draft_folder(account)
  
  if not draft_folder then
    print("No draft folder found for account: " .. account)
    return
  end
  
  print("=== Draft Debug Info ===")
  print("Account: " .. account)
  print("Draft Folder: " .. draft_folder)
  print("")
  
  -- Get draft list from himalaya
  local args = { 'envelope', 'list', '--page', '1', '--page-size', '10', 'order by date desc' }
  local result = utils.execute_himalaya(args, { account = account, folder = draft_folder })
  
  if result and type(result) == 'table' then
    print("Drafts found: " .. #result)
    print("")
    
    for i, draft in ipairs(result) do
      print(string.format("Draft %d:", i))
      print("  ID: " .. tostring(draft.id))
      print("  Subject from envelope: '" .. tostring(draft.subject) .. "'")
      print("  Subject is nil: " .. tostring(draft.subject == nil))
      print("  Subject is empty: " .. tostring(draft.subject == ''))
      print("  From: " .. vim.inspect(draft.from))
      print("  To: " .. vim.inspect(draft.to))
      print("  Date: " .. tostring(draft.date))
      print("  Flags: " .. vim.inspect(draft.flags))
      
      -- Check cache
      local cached = email_cache.get_email(account, draft_folder, draft.id)
      if cached then
        print("  Cached data:")
        print("    Subject: '" .. tostring(cached.subject) .. "'")
        print("    ID: " .. tostring(cached.id))
      else
        print("  No cached data")
      end
      
      -- Try to read the draft to see actual subject
      print("  Reading draft content...")
      local content_result = utils.get_email_by_id(account, draft_folder, draft.id)
      if content_result then
        print("    Actual subject: '" .. tostring(content_result.subject) .. "'")
      else
        print("    Failed to read draft content")
      end
      
      print("")
    end
  else
    print("Failed to get draft list")
    print("Result: " .. vim.inspect(result))
  end
  
  -- Check cache stats
  local stats = email_cache.get_stats()
  print("Cache stats: " .. vim.inspect(stats))
end

function M.debug_draft_content(draft_id)
  if not draft_id then
    print("Usage: :DebugDraftContent <draft_id>")
    return
  end
  
  local account = config.get_current_account_name()
  local draft_folder = utils.find_draft_folder(account)
  
  print("=== Draft Content Debug ===")
  print("Account: " .. account)
  print("Draft Folder: " .. draft_folder)
  print("Draft ID: " .. draft_id)
  print("")
  
  -- Read draft using himalaya
  local args = { 'message', 'read', tostring(draft_id) }
  local result = utils.execute_himalaya(args, { account = account, folder = draft_folder })
  
  if result then
    print("Draft content type: " .. type(result))
    if type(result) == 'string' then
      print("Content length: " .. #result)
      print("First 500 chars:")
      print(result:sub(1, 500))
    else
      print("Parsed result:")
      print(vim.inspect(result))
    end
  else
    print("Failed to read draft")
  end
end

-- Register commands
vim.api.nvim_create_user_command('DebugDraftList', M.debug_draft_list, {})
vim.api.nvim_create_user_command('DebugDraftContent', function(opts)
  M.debug_draft_content(opts.args)
end, { nargs = 1 })

return M