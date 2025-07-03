-- Preview-related commands for testing and debugging
local M = {}

-- Dependencies
local email_preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
local email_cache = require('neotex.plugins.tools.himalaya.core.email_cache')
local notify = require('neotex.util.notifications')

-- Register preview-related commands
function M.register()
  -- Test preview functionality
  vim.api.nvim_create_user_command('HimalayaPreviewTest', function()
    notify.himalaya('Testing preview functionality...', notify.categories.STATUS)
    
    -- Get current cursor position
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
    local email_id = email_list.get_email_id_from_line(line)
    
    if email_id then
      notify.himalaya('Showing preview for email ID: ' .. email_id, notify.categories.INFO)
      email_preview.show_preview(email_id, vim.api.nvim_get_current_win())
    else
      notify.himalaya('No email found at cursor position', notify.categories.WARN)
    end
  end, { desc = 'Test email preview at cursor' })
  
  -- Clear preview cache
  vim.api.nvim_create_user_command('HimalayaPreviewCacheClear', function()
    email_cache.clear_all()
    notify.himalaya('Preview cache cleared', notify.categories.INFO)
  end, { desc = 'Clear preview cache' })
  
  -- Show cache statistics
  vim.api.nvim_create_user_command('HimalayaPreviewCacheStats', function()
    local stats = email_cache.get_stats()
    local lines = {
      'Email Cache Statistics:',
      string.format('  Total emails: %d', stats.total_emails),
      string.format('  Accounts: %d', stats.accounts),
      string.format('  Folders: %d', stats.folders),
      string.format('  Cache hits: %d', stats.hits),
      string.format('  Cache misses: %d', stats.misses),
      string.format('  Hit rate: %.2f%%', stats.hit_rate * 100),
      string.format('  Stores: %d', stats.stores),
      string.format('  Evictions: %d', stats.evictions),
    }
    
    for _, line in ipairs(lines) do
      print(line)
    end
  end, { desc = 'Show preview cache statistics' })
  
  -- Toggle preview
  vim.api.nvim_create_user_command('HimalayaPreviewToggle', function()
    email_preview.config.enabled = not email_preview.config.enabled
    local status = email_preview.config.enabled and 'enabled' or 'disabled'
    notify.himalaya('Email preview ' .. status, notify.categories.INFO)
  end, { desc = 'Toggle email preview' })
  
  -- Cleanup preview buffers
  vim.api.nvim_create_user_command('HimalayaPreviewCleanup', function()
    email_preview.cleanup_preview_buffers()
    notify.himalaya('Preview buffers cleaned up', notify.categories.INFO)
  end, { desc = 'Cleanup preview buffers' })
end

return M