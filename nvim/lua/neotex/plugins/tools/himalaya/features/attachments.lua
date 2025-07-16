-- Attachment Support
-- Handles email attachments including viewing, downloading, and sending

local M = {}

local utils = require('neotex.plugins.tools.himalaya.utils')
local config = require('neotex.plugins.tools.himalaya.core.config')
local state = require('neotex.plugins.tools.himalaya.core.state')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local api = require('neotex.plugins.tools.himalaya.core.api')
local events = require('neotex.plugins.tools.himalaya.commands.orchestrator')
local errors = require('neotex.plugins.tools.himalaya.core.errors')

-- Attachment cache directory
M.cache_dir = vim.fn.stdpath('cache') .. '/himalaya/attachments/'

-- Supported viewer programs
M.viewers = {
  pdf = { 'zathura', 'evince', 'okular', 'mupdf', 'xdg-open' },
  image = { 'feh', 'sxiv', 'eog', 'xdg-open' },
  text = { 'nvim', 'vim', 'less' },
  default = { 'xdg-open', 'open' }
}

-- MIME type mappings
M.mime_types = {
  ['application/pdf'] = 'pdf',
  ['image/jpeg'] = 'image',
  ['image/png'] = 'image',
  ['image/gif'] = 'image',
  ['text/plain'] = 'text',
  ['text/html'] = 'text',
}

-- Initialize attachment system
function M.setup()
  -- Create cache directory
  vim.fn.mkdir(M.cache_dir, 'p')
  
  -- Clean old cached attachments (older than 7 days)
  M.cleanup_cache(7 * 24 * 60 * 60)
end

-- Get attachments for an email
function M.get_attachments(email_id)
  local cmd_args = {'attachment', 'list', email_id}
  local result = utils.execute_himalaya(cmd_args)
  
  if not result.success then
    return api.error("Failed to get attachments: " .. result.error, "ATTACHMENT_LIST_FAILED")
  end
  
  local attachments = result.data or {}
  
  -- Enhance attachment info
  for _, attachment in ipairs(attachments) do
    attachment.human_size = utils.string.human_size(attachment.size or 0)
    attachment.category = M.get_mime_category(attachment.content_type)
    attachment.cached = M.is_cached(email_id, attachment.id)
  end
  
  return api.success(attachments)
end

-- Download an attachment
function M.download(email_id, attachment_id, options)
  options = options or {}
  
  -- Generate cache path
  local cache_path = M.get_cache_path(email_id, attachment_id)
  
  -- Check if already cached
  if not options.force and vim.fn.filereadable(cache_path) == 1 then
    logger.debug("Using cached attachment: " .. cache_path)
    return api.success({ path = cache_path, cached = true })
  end
  
  -- Download attachment
  local cmd_args = {'attachment', 'download', email_id, attachment_id, '-o', cache_path}
  local result = utils.execute_himalaya(cmd_args)
  
  if not result.success then
    return api.error("Failed to download attachment: " .. result.error, "ATTACHMENT_DOWNLOAD_FAILED")
  end
  
  -- Update cache metadata
  M.update_cache_metadata(email_id, attachment_id, {
    downloaded_at = os.time(),
    size = vim.fn.getfsize(cache_path)
  })
  
  logger.info("Downloaded attachment: " .. attachment_id)
  
  return api.success({ path = cache_path, cached = false })
end

-- View an attachment
function M.view(email_id, attachment_id, attachment_info)
  -- Download if needed
  local download_result = M.download(email_id, attachment_id)
  
  if not download_result.success then
    return download_result
  end
  
  local file_path = download_result.data.path
  local mime_type = attachment_info and attachment_info.content_type or 'application/octet-stream'
  local category = M.get_mime_category(mime_type)
  
  -- Find appropriate viewer
  local viewer = M.find_viewer(category)
  
  if not viewer then
    return api.error("No viewer found for type: " .. mime_type, "NO_VIEWER_FOUND")
  end
  
  -- Launch viewer
  local cmd = string.format('%s %s &', viewer, vim.fn.shellescape(file_path))
  local result = os.execute(cmd)
  
  if result ~= 0 then
    return api.error("Failed to open attachment", "VIEWER_FAILED")
  end
  
  logger.info("Opened attachment with: " .. viewer)
  
  return api.success({ viewer = viewer, path = file_path })
end

-- Save attachment to a specific location
function M.save(email_id, attachment_id, save_path, attachment_info)
  -- Download to cache first
  local download_result = M.download(email_id, attachment_id)
  
  if not download_result.success then
    return download_result
  end
  
  local cache_path = download_result.data.path
  
  -- Use original filename if save_path is a directory
  if vim.fn.isdirectory(save_path) == 1 then
    local filename = attachment_info and attachment_info.filename or attachment_id
    save_path = save_path .. '/' .. filename
  end
  
  -- Copy from cache to save location
  local ok, err = pcall(function()
    vim.fn.system({'cp', cache_path, save_path})
  end)
  
  if not ok or vim.v.shell_error ~= 0 then
    return api.error("Failed to save attachment: " .. (err or "copy failed"), "SAVE_FAILED")
  end
  
  logger.info("Saved attachment to: " .. save_path)
  
  return api.success({ path = save_path })
end

-- Add attachments to a draft email
function M.add_to_draft(draft_id, file_paths)
  local attachments = {}
  
  for _, file_path in ipairs(file_paths) do
    if vim.fn.filereadable(file_path) == 0 then
      return api.error("File not found: " .. file_path, "FILE_NOT_FOUND")
    end
    
    -- Check file size
    local size = vim.fn.getfsize(file_path)
    local max_size = config.get('attachments.max_size', 25 * 1024 * 1024) -- 25MB default
    
    if size > max_size then
      return api.error(
        string.format("File too large: %s (max: %s)", 
          utils.string.human_size(size),
          utils.string.human_size(max_size)
        ),
        "ATTACHMENT_TOO_LARGE"
      )
    end
    
    table.insert(attachments, {
      path = file_path,
      filename = vim.fn.fnamemodify(file_path, ':t'),
      size = size
    })
  end
  
  -- Store in draft state
  state.set('drafts.' .. draft_id .. '.attachments', attachments)
  
  logger.info("Added " .. #attachments .. " attachments to draft")
  
  return api.success(attachments)
end

-- Remove attachment from draft
function M.remove_from_draft(draft_id, attachment_index)
  local attachments = state.get('drafts.' .. draft_id .. '.attachments', {})
  
  if attachment_index < 1 or attachment_index > #attachments then
    return api.error("Invalid attachment index", "INVALID_INDEX")
  end
  
  table.remove(attachments, attachment_index)
  state.set('drafts.' .. draft_id .. '.attachments', attachments)
  
  return api.success({ remaining = #attachments })
end

-- Helper functions

-- Get MIME category
function M.get_mime_category(mime_type)
  return M.mime_types[mime_type] or 'default'
end

-- Find appropriate viewer
function M.find_viewer(category)
  local viewers = M.viewers[category] or M.viewers.default
  
  for _, viewer in ipairs(viewers) do
    if vim.fn.executable(viewer) == 1 then
      return viewer
    end
  end
  
  return nil
end

-- Get cache path for attachment
function M.get_cache_path(email_id, attachment_id)
  return M.cache_dir .. email_id .. '_' .. attachment_id
end

-- Check if attachment is cached
function M.is_cached(email_id, attachment_id)
  local cache_path = M.get_cache_path(email_id, attachment_id)
  return vim.fn.filereadable(cache_path) == 1
end

-- Update cache metadata
function M.update_cache_metadata(email_id, attachment_id, metadata)
  local key = 'attachment_cache.' .. email_id .. '.' .. attachment_id
  state.set(key, metadata)
end

-- Clean up old cached attachments
function M.cleanup_cache(max_age_seconds)
  local now = os.time()
  local cleaned = 0
  
  -- Get all cached files
  local files = vim.fn.glob(M.cache_dir .. '*', false, true)
  
  for _, file in ipairs(files) do
    local mtime = vim.fn.getftime(file)
    if now - mtime > max_age_seconds then
      vim.fn.delete(file)
      cleaned = cleaned + 1
    end
  end
  
  if cleaned > 0 then
    logger.info("Cleaned " .. cleaned .. " old attachments from cache")
  end
  
  return cleaned
end

-- Get cache statistics
function M.get_cache_stats()
  local files = vim.fn.glob(M.cache_dir .. '*', false, true)
  local total_size = 0
  
  for _, file in ipairs(files) do
    total_size = total_size + vim.fn.getfsize(file)
  end
  
  return {
    file_count = #files,
    total_size = total_size,
    human_size = utils.string.human_size(total_size),
    cache_dir = M.cache_dir
  }
end

return M