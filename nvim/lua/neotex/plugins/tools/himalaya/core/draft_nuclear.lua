-- Nuclear draft cleanup - removes everything
local M = {}

function M.nuclear_cleanup()
  local notify = require('neotex.util.notifications')
  local logger = require('neotex.plugins.tools.himalaya.core.logger')
  
  local draft_dir = vim.fn.stdpath('data') .. '/himalaya/drafts/'
  
  -- Get all files
  local all_files = vim.fn.glob(draft_dir .. '*', false, true)
  local deleted_count = 0
  
  for _, file in ipairs(all_files) do
    local filename = vim.fn.fnamemodify(file, ':t')
    -- Skip the index file
    if filename ~= '.index.json' then
      if vim.fn.delete(file) == 0 then
        deleted_count = deleted_count + 1
      end
    end
  end
  
  -- Clear the index
  local local_storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  local_storage._clear_all()
  
  logger.info('Nuclear cleanup complete', {
    deleted_files = deleted_count,
    draft_dir = draft_dir
  })
  
  notify.himalaya(
    string.format('Deleted %d draft files (nuclear cleanup)', deleted_count),
    notify.categories.USER_ACTION
  )
  
  return deleted_count
end

return M