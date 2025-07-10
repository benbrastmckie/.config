-- Enhanced Sidebar Module for Draft Integration
-- Shows sync status and draft state indicators

local M = {}

-- Dependencies
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
local sync_engine = require('neotex.plugins.tools.himalaya.core.sync_engine')
local draft_notifications = require('neotex.plugins.tools.himalaya.core.draft_notifications')

-- Get draft sync status for display
function M.get_draft_sync_status(draft_id, account)
  -- First check if this is a managed draft
  local draft = draft_manager.get_by_remote_id(draft_id)
  
  if draft then
    -- Active draft in editor
    if draft.state == draft_manager.states.NEW then
      return '📝' -- New, not synced
    elseif draft.state == draft_manager.states.SYNCING then
      return '🔄' -- Currently syncing
    elseif draft.state == draft_manager.states.SYNCED then
      return '✅' -- Synced
    elseif draft.state == draft_manager.states.ERROR then
      return '❌' -- Sync error
    end
  end
  
  -- Not an active draft, just a saved draft
  return '💾' -- Saved draft
end

-- Format draft line with sync status
function M.format_draft_line(email, checkbox, from, subject, date)
  local draft_status = M.get_draft_sync_status(email.id, email.account)
  
  -- Truncate fields
  from = require('neotex.plugins.tools.himalaya.utils').truncate_string(from, 25)
  subject = require('neotex.plugins.tools.himalaya.utils').truncate_string(subject, 45)
  
  -- Format: [checkbox][status] from | subject date
  return string.format('%s%s %s | %s  %s', 
    checkbox, draft_status, from, subject, date)
end

-- Get sync queue status for header
function M.get_sync_queue_status()
  local status = sync_engine.get_status()
  
  if status.queue_size == 0 then
    return nil -- No sync activity
  end
  
  local parts = {}
  
  if status.pending > 0 then
    table.insert(parts, string.format('%d pending', status.pending))
  end
  
  if status.in_progress > 0 then
    table.insert(parts, string.format('%d syncing', status.in_progress))
  end
  
  if status.failed > 0 then
    table.insert(parts, string.format('%d failed', status.failed))
  end
  
  if #parts > 0 then
    return '⟳ Draft sync: ' .. table.concat(parts, ', ')
  end
  
  return nil
end

-- Enhanced format_email_list that integrates draft status
function M.enhance_email_list_formatting(original_format_fn)
  return function(emails)
    local lines = original_format_fn(emails)
    
    -- Find draft section and enhance it
    local in_drafts = false
    local current_folder = require('neotex.plugins.tools.himalaya.core.state').get_current_folder()
    local draft_folder = require('neotex.plugins.tools.himalaya.utils').find_draft_folder(
      require('neotex.plugins.tools.himalaya.core.state').get_current_account()
    )
    
    if current_folder == draft_folder then
      in_drafts = true
    end
    
    -- If in drafts folder, replace the draft formatting
    if in_drafts and type(lines) == 'table' then
      local email_start_line = lines.email_start_line or 1
      local metadata = lines.metadata or {}
      
      -- Re-format draft lines with sync status
      for line_num, meta in pairs(metadata) do
        if type(line_num) == 'number' and meta.is_draft then
          local email_index = meta.email_index
          if email_index and emails[email_index] then
            local email = emails[email_index]
            
            -- Get original components
            local checkbox = meta.selected and '[x] ' or '[ ] '
            
            -- Parse from field (it can be a table, string, or other type)
            local from = ''
            if email.from then
              if type(email.from) == 'table' then
                from = email.from.name or email.from.addr or ''
              elseif type(email.from) == 'string' then
                from = email.from
                -- Extract email from "Name <email@example.com>" format
                if from:match('<(.+)>') then
                  from = from:match('<(.+)>')
                end
              else
                from = tostring(email.from)
              end
            end
            local subject = email.subject or '(No subject)'
            local date = email.date or ''
            
            -- Create enhanced line (pass the parsed from string, not the raw email.from)
            lines[line_num] = M.format_draft_line(email, checkbox, from, subject, date)
          end
        end
      end
    end
    
    -- Add sync status to header if there's activity
    local sync_status = M.get_sync_queue_status()
    if sync_status then
      -- Find the empty line after the header and insert sync status
      for i = 1, #lines do
        if lines[i] == '' then
          table.insert(lines, i, sync_status)
          break
        end
      end
    end
    
    return lines
  end
end

-- Setup enhanced sidebar features
function M.setup()
  -- Hook into the email list formatting
  local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
  local original_format = email_list.format_email_list
  
  if original_format then
    email_list.format_email_list = M.enhance_email_list_formatting(original_format)
  end
  
  -- Set up auto-refresh when sync status changes
  local events_bus = require('neotex.plugins.tools.himalaya.orchestration.events')
  local event_types = require('neotex.plugins.tools.himalaya.core.events')
  
  -- Refresh on draft sync events
  events_bus.on(event_types.DRAFT_SYNCED, function(data)
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    if sidebar.is_open() then
      vim.schedule(function()
        email_list.refresh_email_list()
      end)
    end
  end)
  
  events_bus.on(event_types.DRAFT_SYNC_FAILED, function(data)
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    if sidebar.is_open() then
      vim.schedule(function()
        email_list.refresh_email_list()
      end)
    end
  end)
  
  -- Subscribe to draft lifecycle events
  events_bus.on(event_types.DRAFT_CREATED, function(data)
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    local state = require('neotex.plugins.tools.himalaya.core.state')
    -- Refresh if in drafts folder
    if sidebar.is_open() and state.get_current_folder() == 'Drafts' then
      vim.schedule(function()
        email_list.refresh_email_list()
      end)
    end
  end)
  
  events_bus.on(event_types.DRAFT_DELETED, function(data)
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    -- Remove from sidebar immediately
    if sidebar.is_open() then
      vim.schedule(function()
        -- TODO: Implement remove_email_from_list if not already available
        -- For now, just refresh the list
        email_list.refresh_email_list()
      end)
    end
  end)
end

-- Get draft counts for folder display
function M.get_draft_counts(account, folder)
  local all_drafts = draft_manager.get_all()
  local counts = {
    total = 0,
    new = 0,
    syncing = 0,
    synced = 0,
    error = 0
  }
  
  for _, draft in ipairs(all_drafts) do
    if draft.account == account then
      counts.total = counts.total + 1
      
      if draft.state == draft_manager.states.NEW then
        counts.new = counts.new + 1
      elseif draft.state == draft_manager.states.SYNCING then
        counts.syncing = counts.syncing + 1
      elseif draft.state == draft_manager.states.SYNCED then
        counts.synced = counts.synced + 1
      elseif draft.state == draft_manager.states.ERROR then
        counts.error = counts.error + 1
      end
    end
  end
  
  return counts
end

return M