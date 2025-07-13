-- Fix draft accounts in index
local M = {}

function M.fix_draft_accounts()
  local local_storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local logger = require('neotex.plugins.tools.himalaya.core.logger')
  local notify = require('neotex.util.notifications')
  
  -- Get current account
  local current_account = config.get_current_account_name()
  if not current_account then
    notify.himalaya('No current account configured', notify.categories.ERROR)
    return 0
  end
  
  -- Initialize storage
  local_storage.setup()
  
  local fixed_count = 0
  
  -- Update all drafts with 'default' account to current account
  for local_id, draft_info in pairs(local_storage.index) do
    if draft_info.account == 'default' then
      draft_info.account = current_account
      fixed_count = fixed_count + 1
      
      -- Also update the JSON file
      local draft_data = local_storage.load(local_id)
      if draft_data then
        draft_data.account = current_account
        local_storage.save(local_id, draft_data)
      end
    end
  end
  
  -- Save updated index
  local_storage._save_index()
  
  logger.info('Fixed draft accounts', {
    fixed = fixed_count,
    new_account = current_account
  })
  
  notify.himalaya(
    string.format('Updated %d drafts to account: %s', fixed_count, current_account),
    notify.categories.USER_ACTION
  )
  
  return fixed_count
end

return M