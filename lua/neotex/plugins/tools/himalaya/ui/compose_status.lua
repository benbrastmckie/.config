-- Compose Status Line Module
-- Shows draft state and sync status in composer buffers

local M = {}

-- Dependencies
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
local sync_engine = require('neotex.plugins.tools.himalaya.core.sync_engine')

-- Get draft status for statusline
function M.get_draft_status(buf)
  local draft = draft_manager.get_by_buffer(buf)
  if not draft then
    return ''
  end
  
  local parts = {}
  
  -- Draft state icon
  local state_icon = ''
  if draft.state == draft_manager.states.NEW then
    state_icon = '📝'
  elseif draft.state == draft_manager.states.SYNCING then
    state_icon = '🔄'
  elseif draft.state == draft_manager.states.SYNCED then
    state_icon = '✅'
  elseif draft.state == draft_manager.states.ERROR then
    state_icon = '❌'
  end
  
  table.insert(parts, state_icon)
  
  -- Draft ID if synced
  if draft.remote_id then
    table.insert(parts, '#' .. draft.remote_id)
  else
    table.insert(parts, 'Local')
  end
  
  -- Last sync time
  if draft.last_sync then
    local age = os.time() - draft.last_sync
    if age < 60 then
      table.insert(parts, 'just now')
    elseif age < 3600 then
      table.insert(parts, string.format('%dm ago', math.floor(age / 60)))
    else
      table.insert(parts, string.format('%dh ago', math.floor(age / 3600)))
    end
  end
  
  -- Error message if any
  if draft.sync_error then
    table.insert(parts, '(' .. draft.sync_error .. ')')
  end
  
  return table.concat(parts, ' ')
end

-- Get sync queue status
function M.get_sync_status()
  local status = sync_engine.get_status()
  
  if status.queue_size == 0 then
    return ''
  end
  
  local parts = {}
  
  if status.in_progress > 0 then
    table.insert(parts, '⟳ Syncing')
  elseif status.pending > 0 then
    table.insert(parts, '⏳ Pending')
  end
  
  if status.failed > 0 then
    table.insert(parts, string.format('⚠️  %d failed', status.failed))
  end
  
  return table.concat(parts, ' ')
end

-- Setup statusline for compose buffers
function M.setup_statusline(buf)
  -- Create buffer-local statusline
  vim.api.nvim_buf_call(buf, function()
    vim.opt_local.statusline = [[%{luaeval("require('neotex.plugins.tools.himalaya.ui.compose_status').statusline(" . winbufnr(0) . ")")}]]
  end)
  
  -- Update on timer
  local timer = vim.loop.new_timer()
  timer:start(1000, 1000, vim.schedule_wrap(function()
    if not vim.api.nvim_buf_is_valid(buf) then
      timer:stop()
      return
    end
    
    -- Force statusline redraw for this buffer
    vim.api.nvim_buf_call(buf, function()
      vim.cmd('redrawstatus')
    end)
  end))
  
  -- Store timer for cleanup
  vim.api.nvim_buf_set_var(buf, 'himalaya_status_timer', timer)
  
  -- Clean up timer on buffer unload
  vim.api.nvim_create_autocmd('BufUnload', {
    buffer = buf,
    once = true,
    callback = function()
      if timer then
        timer:stop()
      end
    end
  })
end

-- Generate statusline content
function M.statusline(buf)
  local parts = {}
  
  -- Left side
  table.insert(parts, ' 📧 Himalaya Compose ')
  
  -- Draft status
  local draft_status = M.get_draft_status(buf)
  if draft_status ~= '' then
    table.insert(parts, '│ ' .. draft_status .. ' ')
  end
  
  -- Sync status
  local sync_status = M.get_sync_status()
  if sync_status ~= '' then
    table.insert(parts, '│ ' .. sync_status .. ' ')
  end
  
  -- Spacer
  table.insert(parts, '%=')
  
  -- Right side - standard vim info
  table.insert(parts, ' %l:%c │ %p%% ')
  
  return table.concat(parts)
end

-- Setup module
function M.setup()
  -- Subscribe to sync events for real-time updates
  local events_bus = require('neotex.plugins.tools.himalaya.orchestration.events')
  local event_types = require('neotex.plugins.tools.himalaya.core.events')
  
  events_bus.on(event_types.DRAFT_SYNC_PROGRESS, function(data)
    -- Update status for relevant buffer
    local draft = draft_manager.get_by_local_id(data.draft_id)
    if draft and vim.api.nvim_buf_is_valid(draft.buffer) then
      vim.schedule(function()
        -- Force statusline redraw
        vim.api.nvim_buf_call(draft.buffer, function()
          vim.cmd('redrawstatus')
        end)
      end)
    end
  end)
  
  -- Also subscribe to other draft events for immediate updates
  local update_events = {
    event_types.DRAFT_SYNC_STARTED,
    event_types.DRAFT_SYNCED,
    event_types.DRAFT_SYNC_FAILED,
    event_types.DRAFT_SAVED
  }
  
  for _, event in ipairs(update_events) do
    events_bus.on(event, function(data)
      -- Find buffer for this draft
      local draft = draft_manager.get_by_local_id(data.draft_id)
      if draft and vim.api.nvim_buf_is_valid(draft.buffer) then
        vim.schedule(function()
          vim.api.nvim_buf_call(draft.buffer, function()
            vim.cmd('redrawstatus')
          end)
        end)
      end
    end)
  end
  
  -- Hook into composer setup
  local composer = require('neotex.plugins.tools.himalaya.ui.email_composer_v2')
  local original_setup_mappings = composer.setup_buffer_mappings
  
  if original_setup_mappings then
    composer.setup_buffer_mappings = function(buf)
      -- Call original
      original_setup_mappings(buf)
      
      -- Add statusline
      M.setup_statusline(buf)
    end
  end
end

return M