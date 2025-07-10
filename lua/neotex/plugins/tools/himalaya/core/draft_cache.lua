-- Draft-specific Cache System
-- Two-tier cache for draft metadata and content
--
-- This module solves the sidebar subject display issue by maintaining
-- persistent metadata that survives cache invalidation.

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local performance = require('neotex.plugins.tools.himalaya.core.performance')
local state = require('neotex.plugins.tools.himalaya.core.state')

-- Cache data structures
M.metadata_cache = {}  -- Persistent cache for draft metadata (subject, from, to)
M.content_cache = {}   -- Volatile cache for full draft content
M.cache_file = vim.fn.stdpath('cache') .. '/himalaya_draft_metadata.json'

-- Initialize cache
function M.init()
  -- Load persistent metadata from disk
  M.load_metadata()
  
  logger.debug('Draft cache initialized', {
    metadata_count = vim.tbl_count(M.metadata_cache),
    cache_file = M.cache_file
  })
end

-- Generate cache key
local function make_cache_key(account, folder, draft_id)
  return string.format('%s:%s:%s', account, folder, draft_id)
end

-- Cache draft metadata (persisted to disk)
function M.cache_draft_metadata(account, folder, draft_id, metadata)
  local timer = performance.start_timer('cache_draft_metadata')
  if not draft_id or draft_id == '' then
    logger.warn('Cannot cache metadata without draft ID')
    performance.end_timer(timer)
    return false
  end
  
  local key = make_cache_key(account, folder, draft_id)
  
  -- Check if we're updating existing metadata
  local existing = M.metadata_cache[key]
  local is_update = existing ~= nil
  local subject_changed = existing and existing.subject ~= (metadata.subject or '')
  
  M.metadata_cache[key] = {
    subject = metadata.subject or '',
    from = metadata.from or '',
    to = metadata.to or '',
    date = metadata.date or os.date('%Y-%m-%d %H:%M:%S'),
    cached_at = os.time(),
    -- Store additional fields that might be useful
    cc = metadata.cc or '',
    bcc = metadata.bcc or '',
    flags = metadata.flags or { 'Draft' }
  }
  
  -- Persist to disk
  M.save_metadata()
  
  logger.info('Draft metadata cached', {
    key = key,
    subject = metadata.subject,
    has_subject = (metadata.subject ~= nil and metadata.subject ~= ''),
    is_update = is_update,
    subject_changed = subject_changed,
    old_subject = existing and existing.subject or nil
  })
  
  performance.end_timer(timer)
  return true
end

-- Get draft metadata (from persistent cache)
function M.get_draft_metadata(account, folder, draft_id)
  if not draft_id or draft_id == '' then
    return nil
  end
  
  local key = make_cache_key(account, folder, draft_id)
  local cached = M.metadata_cache[key]
  
  if cached then
    logger.debug('Draft metadata retrieved from cache', {
      key = key,
      subject = cached.subject,
      age = os.time() - cached.cached_at
    })
  end
  
  return cached
end

-- Get draft subject specifically (convenience method)
function M.get_draft_subject(account, folder, draft_id)
  local metadata = M.get_draft_metadata(account, folder, draft_id)
  if metadata and metadata.subject and metadata.subject ~= '' then
    return metadata.subject
  end
  return nil
end

-- Get smart display subject for drafts (NEW for Phase 6)
function M.get_draft_display_subject(account, folder, draft_id)
  local metadata = M.get_draft_metadata(account, folder, draft_id)
  
  -- ALWAYS prefer the actual subject if it exists
  if metadata and metadata.subject and metadata.subject ~= '' then
    logger.debug('Using cached subject for display', {
      draft_id = draft_id,
      subject = metadata.subject
    })
    return metadata.subject
  end
  
  -- Only use smart display for truly empty subjects
  local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager')
  local draft_state = draft_manager.get_draft_by_id(draft_id)
  
  if draft_state then
    -- Check if draft state has a subject
    if draft_state.content and draft_state.content.subject and draft_state.content.subject ~= '' then
      logger.debug('Using draft state subject for display', {
        draft_id = draft_id,
        subject = draft_state.content.subject
      })
      return draft_state.content.subject
    end
    
    -- Only show time-based subjects for truly empty drafts
    if not draft_state.user_touched then
      return string.format("New Draft (%s)", os.date("%H:%M", draft_state.created_at))
    elseif draft_state.last_modified then
      return string.format("Draft (%s)", os.date("%H:%M", draft_state.last_modified))
    end
  end
  
  -- Fallback with timestamp
  return string.format("Draft (%s)", os.date("%H:%M", metadata and metadata.cached_at or os.time()))
end

-- Cache full draft content (volatile)
function M.cache_draft_content(account, folder, draft_id, content)
  if not draft_id or draft_id == '' then
    return false
  end
  
  local key = make_cache_key(account, folder, draft_id)
  
  M.content_cache[key] = {
    content = content,
    cached_at = os.time()
  }
  
  -- Also update metadata cache
  if content then
    M.cache_draft_metadata(account, folder, draft_id, content)
  end
  
  logger.debug('Draft content cached', {
    key = key,
    has_content = content ~= nil
  })
  
  return true
end

-- Get full draft content (from volatile cache)
function M.get_draft_content(account, folder, draft_id)
  if not draft_id or draft_id == '' then
    return nil
  end
  
  local key = make_cache_key(account, folder, draft_id)
  local cached = M.content_cache[key]
  
  if cached then
    -- Check if cache is too old (5 minutes)
    if os.time() - cached.cached_at > 300 then
      logger.debug('Draft content cache expired', { key = key })
      M.content_cache[key] = nil
      return nil
    end
    
    return cached.content
  end
  
  return nil
end

-- Clear specific draft from cache
function M.clear_draft(account, folder, draft_id)
  if not draft_id or draft_id == '' then
    return
  end
  
  local key = make_cache_key(account, folder, draft_id)
  
  -- Only clear content cache, keep metadata
  M.content_cache[key] = nil
  
  logger.debug('Draft content cache cleared', { key = key })
end

-- Clear all drafts for a folder (content only, keep metadata)
function M.clear_folder_drafts(account, folder)
  local pattern = string.format('^%s:%s:', account, folder)
  local cleared = 0
  
  for key, _ in pairs(M.content_cache) do
    if key:match(pattern) then
      M.content_cache[key] = nil
      cleared = cleared + 1
    end
  end
  
  logger.debug('Folder draft cache cleared', {
    account = account,
    folder = folder,
    cleared = cleared
  })
end

-- Remove draft metadata (when draft is deleted)
function M.remove_draft_metadata(account, folder, draft_id)
  if not draft_id or draft_id == '' then
    return
  end
  
  local key = make_cache_key(account, folder, draft_id)
  
  M.metadata_cache[key] = nil
  M.content_cache[key] = nil
  
  -- Persist removal
  M.save_metadata()
  
  logger.debug('Draft removed from cache', { key = key })
end

-- Load metadata from disk
function M.load_metadata()
  local ok, data = pcall(vim.fn.readfile, M.cache_file)
  if not ok or not data or #data == 0 then
    logger.debug('No existing draft metadata cache found')
    return
  end
  
  local json_str = table.concat(data, '\n')
  local ok2, metadata = pcall(vim.json.decode, json_str)
  if ok2 and metadata then
    M.metadata_cache = metadata
    logger.info('Draft metadata loaded from disk', {
      count = vim.tbl_count(metadata)
    })
  else
    logger.error('Failed to parse draft metadata cache', { error = metadata })
  end
end

-- Save metadata to disk
function M.save_metadata()
  -- Create cache directory if it doesn't exist
  local cache_dir = vim.fn.fnamemodify(M.cache_file, ':h')
  vim.fn.mkdir(cache_dir, 'p')
  
  local ok, json_str = pcall(vim.json.encode, M.metadata_cache)
  if not ok then
    logger.error('Failed to encode draft metadata', { error = json_str })
    return
  end
  
  local ok2, err = pcall(vim.fn.writefile, { json_str }, M.cache_file)
  if not ok2 then
    logger.error('Failed to save draft metadata', { error = err })
  else
    logger.debug('Draft metadata saved to disk', {
      count = vim.tbl_count(M.metadata_cache)
    })
  end
end

-- Clean old metadata entries
function M.cleanup_old_metadata(max_age_days)
  max_age_days = max_age_days or 30
  local max_age = max_age_days * 24 * 60 * 60
  local now = os.time()
  local removed = 0
  
  for key, metadata in pairs(M.metadata_cache) do
    if metadata.cached_at and (now - metadata.cached_at) > max_age then
      M.metadata_cache[key] = nil
      removed = removed + 1
    end
  end
  
  if removed > 0 then
    M.save_metadata()
    logger.info('Cleaned old draft metadata', {
      removed = removed,
      max_age_days = max_age_days
    })
  end
end

-- Get all cached subjects for an account/folder
function M.get_all_subjects(account, folder)
  local pattern = string.format('^%s:%s:', account, folder)
  local subjects = {}
  
  for key, metadata in pairs(M.metadata_cache) do
    if key:match(pattern) then
      local draft_id = key:match(':([^:]+)$')
      if draft_id and metadata.subject then
        subjects[draft_id] = metadata.subject
      end
    end
  end
  
  return subjects
end

-- Get cache statistics
function M.get_stats()
  local stats = {
    metadata_count = vim.tbl_count(M.metadata_cache),
    content_count = vim.tbl_count(M.content_cache),
    cache_file = M.cache_file,
    oldest_metadata = nil,
    newest_metadata = nil
  }
  
  -- Find oldest and newest cached items
  local oldest_time = math.huge
  local newest_time = 0
  
  for _, metadata in pairs(M.metadata_cache) do
    if metadata.cached_at then
      if metadata.cached_at < oldest_time then
        oldest_time = metadata.cached_at
      end
      if metadata.cached_at > newest_time then
        newest_time = metadata.cached_at
      end
    end
  end
  
  if oldest_time < math.huge then
    stats.oldest_metadata = os.date('%Y-%m-%d %H:%M:%S', oldest_time)
  end
  
  if newest_time > 0 then
    stats.newest_metadata = os.date('%Y-%m-%d %H:%M:%S', newest_time)
  end
  
  return stats
end

-- Debug: Print cache contents
function M.debug_print_cache()
  print("=== Draft Cache Contents ===")
  print(string.format("Metadata entries: %d", vim.tbl_count(M.metadata_cache)))
  print(string.format("Content entries: %d", vim.tbl_count(M.content_cache)))
  print("")
  
  print("Metadata Cache:")
  for key, metadata in pairs(M.metadata_cache) do
    print(string.format("  %s:", key))
    print(string.format("    Subject: %s", metadata.subject or "(no subject)"))
    print(string.format("    From: %s", metadata.from or "(no from)"))
    print(string.format("    Cached: %s", os.date('%Y-%m-%d %H:%M:%S', metadata.cached_at)))
  end
  
  print("\nContent Cache:")
  for key, content in pairs(M.content_cache) do
    print(string.format("  %s: cached at %s", 
      key, os.date('%Y-%m-%d %H:%M:%S', content.cached_at)))
  end
end

-- Initialize on load
M.init()

-- Register debug command
vim.api.nvim_create_user_command('DebugDraftCache', M.debug_print_cache, {})

return M