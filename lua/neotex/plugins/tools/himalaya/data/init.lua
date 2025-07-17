-- Data Layer Module
-- Centralized exports for all data operations

local M = {}

-- Sub-modules
M.cache = require('neotex.plugins.tools.himalaya.data.cache')
M.drafts = require('neotex.plugins.tools.himalaya.data.drafts')
M.search = require('neotex.plugins.tools.himalaya.data.search')
M.templates = require('neotex.plugins.tools.himalaya.data.templates')
M.scheduler = require('neotex.plugins.tools.himalaya.data.scheduler')
M.maildir = require('neotex.plugins.tools.himalaya.data.maildir')

-- Initialize all data modules
function M.init(config)
  -- Initialize cache with config
  if config and config.cache then
    M.cache.init(config.cache)
  end
  
  -- Initialize scheduler
  M.scheduler.init()
  
  -- Initialize templates
  M.templates.init()
  
  return M
end

-- Clear all data caches
function M.clear_all()
  M.cache.clear_all()
  -- Add other clear operations as needed
end

-- Get data layer statistics
function M.get_stats()
  local stats = {
    cache = M.cache.get_stats(),
    scheduled_emails = #M.scheduler.get_all_scheduled(),
    draft_count = vim.tbl_count(M.drafts.buffer_drafts or {}),
    template_count = vim.tbl_count(M.templates.get_all_templates()),
  }
  
  return stats
end

return M