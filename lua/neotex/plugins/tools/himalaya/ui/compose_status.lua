-- Compose Status Line Module
-- Shows draft state and sync status in composer buffers

local M = {}

-- Dependencies
local draft_manager = require("neotex.plugins.tools.himalaya.data.drafts")
-- sync_engine removed - using himalaya template save directly

-- Store timers indexed by buffer number
local timers = {}

-- Get draft status for statusline
function M.get_draft_status(buf)
  local draft = draft_manager.get_by_buffer(buf)
  if not draft then
    return ''
  end
  
  local parts = {}
  
  -- Draft state icon
  local is_modified = draft.buffer and vim.api.nvim_buf_is_valid(draft.buffer) and 
                     vim.api.nvim_buf_get_option(draft.buffer, 'modified')
  local state_icon = is_modified and '📝' or '✅'
  
  table.insert(parts, state_icon)
  
  -- Draft filename
  table.insert(parts, draft.filename or 'Local')
  
  -- Draft age
  if draft.timestamp then
    local age = os.time() - draft.timestamp
    if age < 60 then
      table.insert(parts, 'just now')
    elseif age < 3600 then
      table.insert(parts, string.format('%dm ago', math.floor(age / 60)))
    else
      table.insert(parts, string.format('%dh ago', math.floor(age / 3600)))
    end
  end
  
  return table.concat(parts, ' ')
end

-- Get sync queue status
function M.get_sync_status()
  -- Sync status is now handled per-draft
  return ''
end

-- REMOVED: The rest of the old sync status code
local function removed_code()
  if false then
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
      timers[buf] = nil
      return
    end
    
    -- Force statusline redraw for this buffer
    vim.api.nvim_buf_call(buf, function()
      vim.cmd('redrawstatus')
    end)
  end))
  
  -- Store timer in module table
  timers[buf] = timer
  
  -- Clean up timer on buffer unload
  vim.api.nvim_create_autocmd('BufUnload', {
    buffer = buf,
    once = true,
    callback = function()
      if timers[buf] then
        timers[buf]:stop()
        timers[buf] = nil
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
  -- Simplified setup - sync events no longer needed with maildir
  -- Status is determined by buffer modified state
end

return M