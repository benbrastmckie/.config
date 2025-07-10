-- Draft Notifications Module
-- Provides consistent notification handling for draft operations

local M = {}

-- Dependencies
local notify = require('neotex.util.notifications')

-- User-initiated actions (always shown)
function M.draft_saved(draft_id, subject)
  notify.himalaya(
    string.format("Draft saved: %s", subject or "Untitled"),
    notify.categories.USER_ACTION,
    { draft_id = draft_id }
  )
end

function M.draft_deleted(draft_id)
  notify.himalaya(
    "Draft deleted",
    notify.categories.USER_ACTION,
    { draft_id = draft_id }
  )
end

function M.draft_sent(subject, recipient)
  notify.himalaya(
    string.format("Email sent: %s", subject or "Untitled"),
    notify.categories.USER_ACTION,
    { recipient = recipient }
  )
end

-- Status updates (debug mode only)
function M.draft_syncing(draft_id)
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya(
      "Syncing draft...",
      notify.categories.STATUS,
      { draft_id = draft_id }
    )
  end
end

function M.draft_autosave(draft_id, trigger)
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya(
      "Auto-saving draft...",
      notify.categories.BACKGROUND,
      { draft_id = draft_id, trigger = trigger }
    )
  end
end

function M.draft_loading(draft_id, source)
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya(
      "Loading draft...",
      notify.categories.STATUS,
      { draft_id = draft_id, source = source }
    )
  end
end

-- Errors (always shown)
function M.draft_save_failed(draft_id, error)
  notify.himalaya(
    string.format("Failed to save draft: %s", error),
    notify.categories.ERROR,
    { draft_id = draft_id, error = error }
  )
end

function M.draft_sync_failed(draft_id, error)
  notify.himalaya(
    string.format("Failed to sync draft: %s", error),
    notify.categories.ERROR,
    { draft_id = draft_id, error = error }
  )
end

function M.draft_load_failed(draft_id, error)
  notify.himalaya(
    string.format("Failed to load draft: %s", error),
    notify.categories.ERROR,
    { draft_id = draft_id, error = error }
  )
end

-- Debug lifecycle tracking
function M.debug_lifecycle(event, draft_id, details)
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya(
      string.format("[Draft Lifecycle] %s", event),
      notify.categories.BACKGROUND,
      vim.tbl_extend("force", { draft_id = draft_id }, details or {})
    )
  end
end

-- Debug sync operations
function M.debug_sync(stage, draft_id, details)
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya(
      string.format("[Draft Sync] %s", stage),
      notify.categories.BACKGROUND,
      vim.tbl_extend("force", { draft_id = draft_id }, details or {})
    )
  end
end

-- Debug state transitions
function M.debug_state_change(draft_id, from_state, to_state, trigger)
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya(
      string.format("[Draft State] %s → %s", from_state, to_state),
      notify.categories.BACKGROUND,
      {
        draft_id = draft_id,
        from = from_state,
        to = to_state,
        trigger = trigger
      }
    )
  end
end

-- Debug buffer operations
function M.debug_buffer(operation, buffer, draft_id, details)
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya(
      string.format("[Draft Buffer] %s", operation),
      notify.categories.BACKGROUND,
      vim.tbl_extend("force", {
        buffer = buffer,
        draft_id = draft_id
      }, details or {})
    )
  end
end

-- Debug storage operations
function M.debug_storage(operation, local_id, details)
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya(
      string.format("[Draft Storage] %s", operation),
      notify.categories.BACKGROUND,
      vim.tbl_extend("force", {
        local_id = local_id
      }, details or {})
    )
  end
end

-- Warnings (shown based on config)
function M.draft_himalaya_bug_detected(draft_id)
  notify.himalaya(
    "Draft content missing (known himalaya issue) - using cached version",
    notify.categories.WARNING,
    { draft_id = draft_id }
  )
end

function M.draft_recovery_attempted(draft_id, method)
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya(
      string.format("Attempting draft recovery via %s", method),
      notify.categories.STATUS,
      { draft_id = draft_id, method = method }
    )
  end
end

-- Helper function to format file sizes
local function format_size(bytes)
  if bytes < 1024 then
    return string.format("%d B", bytes)
  elseif bytes < 1024 * 1024 then
    return string.format("%.1f KB", bytes / 1024)
  else
    return string.format("%.1f MB", bytes / (1024 * 1024))
  end
end

-- Progress notifications for long operations
function M.sync_progress(current, total, folder)
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya(
      string.format("Syncing drafts: %d/%d", current, total),
      notify.categories.STATUS,
      { current = current, total = total, folder = folder }
    )
  end
end

-- Storage statistics (debug mode)
function M.storage_stats(stats)
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya(
      string.format("[Storage] %d drafts, %s total", 
        stats.total_drafts, 
        format_size(stats.total_size)
      ),
      notify.categories.BACKGROUND,
      stats
    )
  end
end

-- Setup event subscriptions for progress notifications
function M.setup()
  local events_bus = require('neotex.plugins.tools.himalaya.orchestration.events')
  local event_types = require('neotex.plugins.tools.himalaya.core.events')
  
  -- Subscribe to sync progress events
  events_bus.on(event_types.DRAFT_SYNC_PROGRESS, function(data)
    if notify.config.modules.himalaya.debug_mode then
      notify.himalaya(
        string.format("Syncing draft (attempt %d/%d)", 
          data.attempt, data.max_retries),
        notify.categories.BACKGROUND,
        data
      )
    end
  end)
  
  -- Subscribe to recovery events
  events_bus.on(event_types.DRAFT_RECOVERY_NEEDED, function(data)
    local identifier = "(empty draft)"
    if data.metadata and data.metadata.subject and data.metadata.subject ~= "" then
      identifier = data.metadata.subject
    elseif data.metadata and data.metadata.to and data.metadata.to ~= "" then
      identifier = "to: " .. data.metadata.to
    elseif data.draft_id then
      identifier = "ID: " .. tostring(data.draft_id)
    end
    
    notify.himalaya(
      string.format("Draft needs recovery: %s", identifier),
      notify.categories.WARNING,
      data
    )
  end)
  
  events_bus.on(event_types.DRAFT_RECOVERED, function(data)
    if data.was_modified then
      notify.himalaya(
        string.format("Recovered unsaved draft: %s", 
          data.draft.metadata.subject or "Untitled"),
        notify.categories.WARNING,
        { draft_id = data.draft.local_id }
      )
    end
  end)
  
  -- Subscribe to conflict events
  events_bus.on(event_types.DRAFT_CONFLICT_DETECTED, function(data)
    notify.himalaya(
      string.format("Draft conflict detected: %s", data.draft_id),
      notify.categories.ERROR,
      data
    )
  end)
  
  events_bus.on(event_types.DRAFT_CONFLICT_RESOLVED, function(data)
    notify.himalaya(
      string.format("Draft conflict resolved: %s", data.draft_id),
      notify.categories.USER_ACTION,
      data
    )
  end)
end

return M