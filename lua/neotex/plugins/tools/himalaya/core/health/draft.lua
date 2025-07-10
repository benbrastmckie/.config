-- Draft System Health Check Module
-- Comprehensive health checks for the draft system

local M = {}

local function get_health()
  -- Use vim.health if available (Neovim 0.9+), otherwise use legacy health
  if vim.health then
    return vim.health
  else
    return require('health')
  end
end

-- Check draft system health
function M.check()
  local health = get_health()
  local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
  local state = require('neotex.plugins.tools.himalaya.core.state')
  local config = require('neotex.plugins.tools.himalaya.core.config')
  
  health.report_start('Himalaya Draft System')
  
  -- Check draft storage directory
  local draft_config = config.config.draft
  if draft_config and draft_config.storage then
    local draft_dir = draft_config.storage.base_dir
    if vim.fn.isdirectory(draft_dir) == 1 then
      health.report_ok(string.format("Draft directory exists: %s", draft_dir))
      
      -- Check permissions
      if vim.fn.filewritable(draft_dir) == 2 then
        health.report_ok("Draft directory is writable")
      else
        health.report_error("Draft directory is not writable")
      end
    else
      health.report_warn(string.format("Draft directory not found: %s", draft_dir))
      health.report_info("Directory will be created automatically when needed")
    end
  else
    health.report_error("Draft configuration not found")
  end
  
  -- Check draft count and state
  local draft_count = state.get_draft_count()
  if draft_count > 0 then
    health.report_info(string.format("Active drafts: %d", draft_count))
    
    -- Check for invalid drafts
    local invalid_count = 0
    local drafts = state.get("draft.drafts", {})
    for buffer_id, draft_data in pairs(drafts) do
      if not vim.api.nvim_buf_is_valid(tonumber(buffer_id)) then
        invalid_count = invalid_count + 1
      end
    end
    
    if invalid_count > 0 then
      health.report_warn(string.format("%d draft(s) have invalid buffers", invalid_count))
    else
      health.report_ok("All drafts have valid buffers")
    end
  else
    health.report_info("No active drafts")
  end
  
  -- Check unsaved drafts
  local unsaved = state.get_unsaved_drafts()
  if #unsaved > 0 then
    health.report_warn(string.format("%d draft(s) have unsaved changes", #unsaved))
  else
    health.report_ok("All drafts are saved")
  end
  
  -- Check sync status
  if state.is_draft_syncing() then
    health.report_info("Draft sync in progress")
  else
    local last_sync = state.get("draft.metadata.last_sync")
    if last_sync then
      local age = os.time() - last_sync
      if age < 3600 then -- Less than 1 hour
        health.report_ok(string.format("Last sync: %d minutes ago", math.floor(age / 60)))
      else
        health.report_warn(string.format("Last sync: %d hours ago", math.floor(age / 3600)))
      end
    else
      health.report_info("No sync performed yet")
    end
  end
  
  -- Check pending syncs
  local pending_syncs = state.get("draft.recovery.pending_syncs", {})
  if #pending_syncs > 0 then
    health.report_warn(string.format("%d draft(s) pending sync", #pending_syncs))
  else
    health.report_ok("No pending syncs")
  end
  
  -- Check recovery data
  local last_recovery = state.get("draft.recovery.last_recovery")
  if last_recovery then
    local age = os.time() - last_recovery
    if age < 86400 then -- Less than 24 hours
      health.report_ok(string.format("Last recovery: %d hours ago", math.floor(age / 3600)))
    else
      health.report_info(string.format("Last recovery: %d days ago", math.floor(age / 86400)))
    end
  else
    health.report_info("No recovery performed yet")
  end
  
  -- Check draft manager internal state
  local manager_drafts = draft_manager.get_all()
  local manager_count = #manager_drafts
  if manager_count == draft_count then
    health.report_ok("Draft manager and state are synchronized")
  else
    health.report_warn(string.format("Draft manager (%d) and state (%d) counts don't match", 
      manager_count, draft_count))
  end
  
  -- Check configuration validity
  local ok, err = pcall(function()
    config.validate_draft_config(config.config)
  end)
  
  if ok then
    health.report_ok("Draft configuration is valid")
  else
    health.report_error(string.format("Draft configuration error: %s", err))
  end
  
  -- Check event system integration
  local events = require('neotex.plugins.tools.himalaya.core.events')
  if events.DRAFT_CREATED and events.DRAFT_SAVED then
    health.report_ok("Draft events are defined")
  else
    health.report_error("Draft events are missing")
  end
  
  -- Check notification system integration
  local notify_ok, notify = pcall(require, 'neotex.util.notifications')
  if notify_ok and notify.himalaya then
    health.report_ok("Notification system is available")
  else
    health.report_warn("Notification system not available")
  end
  
  -- Check window stack integration
  local window_stack_ok, window_stack = pcall(require, 'neotex.plugins.tools.himalaya.ui.window_stack')
  if window_stack_ok and window_stack.push_draft then
    health.report_ok("Window stack integration is available")
    
    -- Check if any draft windows are open
    local draft_windows = window_stack.get_draft_windows()
    if #draft_windows > 0 then
      health.report_info(string.format("%d draft windows open", #draft_windows))
    end
  else
    health.report_warn("Window stack integration not available")
  end
  
  -- Check for orphaned files
  if draft_config and draft_config.storage then
    local draft_dir = draft_config.storage.base_dir
    if vim.fn.isdirectory(draft_dir) == 1 then
      local files = vim.fn.glob(draft_dir .. '/*.json', false, true)
      local orphaned = 0
      
      for _, file in ipairs(files) do
        local local_id = vim.fn.fnamemodify(file, ':t:r')
        if not draft_manager.get_by_local_id(local_id) then
          orphaned = orphaned + 1
        end
      end
      
      if orphaned > 0 then
        health.report_warn(string.format("%d orphaned draft file(s) found", orphaned))
      else
        health.report_ok("No orphaned draft files")
      end
    end
  end
  
  -- Performance checks
  local start_time = vim.loop.hrtime()
  
  -- Test state access performance
  for i = 1, 100 do
    state.get_draft_count()
  end
  
  local end_time = vim.loop.hrtime()
  local duration_ms = (end_time - start_time) / 1000000
  
  if duration_ms < 10 then
    health.report_ok(string.format("State access performance: %.2f ms (100 calls)", duration_ms))
  else
    health.report_warn(string.format("State access performance slow: %.2f ms (100 calls)", duration_ms))
  end
end

-- Check draft storage integrity
function M.check_storage_integrity()
  local health = get_health()
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local local_storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  
  health.report_start('Draft Storage Integrity')
  
  local draft_config = config.config.draft
  if not draft_config or not draft_config.storage then
    health.report_error("Draft storage configuration missing")
    return
  end
  
  local draft_dir = draft_config.storage.base_dir
  if vim.fn.isdirectory(draft_dir) ~= 1 then
    health.report_info("Draft directory doesn't exist (will be created when needed)")
    return
  end
  
  local files = vim.fn.glob(draft_dir .. '/*.json', false, true)
  local total_files = #files
  local corrupt_files = 0
  local valid_files = 0
  
  for _, file in ipairs(files) do
    local ok, data = pcall(function()
      local content = vim.fn.readfile(file)
      return vim.json.decode(table.concat(content, '\n'))
    end)
    
    if ok and data and data.local_id then
      valid_files = valid_files + 1
    else
      corrupt_files = corrupt_files + 1
    end
  end
  
  health.report_info(string.format("Total draft files: %d", total_files))
  
  if corrupt_files > 0 then
    health.report_warn(string.format("%d corrupt draft file(s)", corrupt_files))
  else
    health.report_ok("All draft files are valid")
  end
  
  health.report_ok(string.format("%d valid draft file(s)", valid_files))
end

-- Quick health check (minimal)
function M.quick_check()
  local health = get_health()
  local state = require('neotex.plugins.tools.himalaya.core.state')
  local config = require('neotex.plugins.tools.himalaya.core.config')
  
  health.report_start('Draft System Quick Check')
  
  -- Basic functionality
  local draft_count = state.get_draft_count()
  health.report_info(string.format("Active drafts: %d", draft_count))
  
  -- Configuration
  local draft_config = config.config.draft
  if draft_config then
    health.report_ok("Draft configuration loaded")
  else
    health.report_error("Draft configuration missing")
  end
  
  -- Storage
  if draft_config and draft_config.storage then
    local draft_dir = draft_config.storage.base_dir
    if vim.fn.isdirectory(draft_dir) == 1 then
      health.report_ok("Draft storage accessible")
    else
      health.report_info("Draft storage will be created when needed")
    end
  end
end

return M