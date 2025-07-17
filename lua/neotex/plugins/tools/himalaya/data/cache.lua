-- Email cache module for Himalaya
-- Provides centralized caching with proper data normalization
-- Prevents userdata issues by storing only simple types

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Cache structure: account -> folder -> email_id -> email_data
local cache = {}

-- Store email body separately (for preview content)
local body_cache = {}

-- Cache statistics for debugging
local stats = {
  hits = 0,
  misses = 0,
  stores = 0,
  evictions = 0,
}

-- Configuration
M.config = {
  max_emails_per_folder = 1000,
  ttl = 300, -- 5 minutes
}

-- Initialize the cache
function M.init(config)
  if config then
    M.config = vim.tbl_extend('force', M.config, config)
  end
  logger.debug('Email cache initialized', { config = M.config })
end

-- Safe string conversion that handles userdata
local function safe_tostring(value, default)
  default = default or 'Unknown'
  if not value then
    return default
  end
  
  local t = type(value)
  if t == 'string' then
    return value
  elseif t == 'number' or t == 'boolean' then
    return tostring(value)
  elseif t == 'table' then
    -- Try common email field patterns
    if value.name then
      return safe_tostring(value.name, default)
    elseif value.addr then
      return safe_tostring(value.addr, default)
    elseif value[1] then
      return safe_tostring(value[1], default)
    else
      -- Try tostring metamethod
      local ok, str = pcall(tostring, value)
      if ok and str and str ~= 'table' then
        return str
      end
    end
  else
    -- Handle userdata and other types
    local ok, str = pcall(tostring, value)
    if ok and str and not str:match('^userdata') and not str:match('^table:') then
      return str
    end
  end
  
  return default
end

-- Normalize complex fields to simple strings
function M.normalize_email(email)
  if not email then
    return nil
  end
  
  local normalized = {
    id = safe_tostring(email.id, ''),
    subject = safe_tostring(email.subject, 'No Subject'),
    date = safe_tostring(email.date, 'Unknown'),
    flags = {},
    -- Store timestamp for TTL
    cached_at = os.time(),
  }
  
  -- Handle flags array
  if email.flags and type(email.flags) == 'table' then
    for _, flag in ipairs(email.flags) do
      table.insert(normalized.flags, tostring(flag))
    end
  end
  
  -- Handle from field
  normalized.from = safe_tostring(email.from, 'Unknown')
  if type(email.from) == 'table' then
    normalized.from_addr = safe_tostring(email.from.addr)
    normalized.from_name = safe_tostring(email.from.name)
  end
  
  -- Handle to field
  if type(email.to) == 'table' and (vim.islist and vim.islist(email.to) or (email.to[1] ~= nil)) then
    -- Handle multiple recipients
    local recipients = {}
    for _, recipient in ipairs(email.to) do
      table.insert(recipients, safe_tostring(recipient, 'Unknown'))
    end
    normalized.to = table.concat(recipients, ', ')
  else
    normalized.to = safe_tostring(email.to, 'Unknown')
    if type(email.to) == 'table' then
      normalized.to_addr = safe_tostring(email.to.addr)
      normalized.to_name = safe_tostring(email.to.name)
    end
  end
  
  -- Handle cc field
  if email.cc then
    if type(email.cc) == 'table' and (vim.islist and vim.islist(email.cc) or (email.cc[1] ~= nil)) then
      local cc_list = {}
      for _, cc in ipairs(email.cc) do
        table.insert(cc_list, safe_tostring(cc, ''))
      end
      normalized.cc = table.concat(cc_list, ', ')
    else
      normalized.cc = safe_tostring(email.cc)
    end
  end
  
  -- Handle body (store separately if needed)
  if email.body then
    normalized.has_body = true
    -- Don't store full body in main cache to save memory
  end
  
  -- Handle attachments
  if email.attachments and type(email.attachments) == 'table' then
    normalized.attachments = {}
    for _, attachment in ipairs(email.attachments) do
      if type(attachment) == 'table' then
        table.insert(normalized.attachments, {
          name = tostring(attachment.name or 'attachment'),
          size = tonumber(attachment.size) or 0,
          type = tostring(attachment.type or 'unknown'),
        })
      end
    end
  end
  
  return normalized
end

-- Store multiple emails
function M.store_emails(account, folder, emails)
  if not account or not folder then
    logger.error('Invalid account or folder for cache storage')
    return
  end
  
  -- Skip caching for draft folders - filesystem is the source of truth
  if folder:lower():match('draft') then
    logger.debug('Skipping cache for draft folder', { 
      folder = folder,
      account = account 
    })
    return
  end
  
  -- Initialize cache structure
  if not cache[account] then cache[account] = {} end
  if not cache[account][folder] then cache[account][folder] = {} end
  
  local folder_cache = cache[account][folder]
  local stored = 0
  
  for _, email in ipairs(emails or {}) do
    local normalized = M.normalize_email(email)
    if normalized and normalized.id then
      folder_cache[normalized.id] = normalized
      stored = stored + 1
      stats.stores = stats.stores + 1
    end
  end
  
  -- Evict old entries if cache is too large
  M.evict_old_entries(account, folder)
  
  logger.debug('Stored emails in cache', {
    account = account,
    folder = folder,
    count = stored,
    total_in_folder = vim.tbl_count(folder_cache),
  })
end

-- Store single email
function M.store_email(account, folder, email)
  if not account or not folder or not email then
    return
  end
  
  M.store_emails(account, folder, { email })
end

-- Get email by ID
function M.get_email(account, folder, email_id)
  if not account or not folder or not email_id then
    return nil
  end
  
  local email_id_str = tostring(email_id)
  
  if cache[account] and cache[account][folder] and cache[account][folder][email_id_str] then
    local email = cache[account][folder][email_id_str]
    
    -- Check TTL
    if os.time() - email.cached_at > M.config.ttl then
      -- Expired, remove from cache
      cache[account][folder][email_id_str] = nil
      stats.evictions = stats.evictions + 1
      stats.misses = stats.misses + 1
      return nil
    end
    
    stats.hits = stats.hits + 1
    return email
  end
  
  stats.misses = stats.misses + 1
  return nil
end

-- Get all cached emails for a folder
function M.get_folder_emails(account, folder)
  if not account or not folder then
    return {}
  end
  
  if not cache[account] or not cache[account][folder] then
    return {}
  end
  
  local emails = {}
  local now = os.time()
  
  for id, email in pairs(cache[account][folder]) do
    -- Check TTL
    if now - email.cached_at <= M.config.ttl then
      table.insert(emails, email)
    else
      -- Remove expired
      cache[account][folder][id] = nil
      stats.evictions = stats.evictions + 1
    end
  end
  
  return emails
end

-- Evict old entries when cache is too large
function M.evict_old_entries(account, folder)
  if not cache[account] or not cache[account][folder] then
    return
  end
  
  local folder_cache = cache[account][folder]
  local count = vim.tbl_count(folder_cache)
  
  if count <= M.config.max_emails_per_folder then
    return
  end
  
  -- Create sorted list by cached_at time
  local emails = {}
  for id, email in pairs(folder_cache) do
    table.insert(emails, { id = id, cached_at = email.cached_at })
  end
  
  table.sort(emails, function(a, b)
    return a.cached_at < b.cached_at
  end)
  
  -- Remove oldest entries
  local to_remove = count - M.config.max_emails_per_folder
  for i = 1, to_remove do
    if emails[i] then
      folder_cache[emails[i].id] = nil
      stats.evictions = stats.evictions + 1
    end
  end
  
  logger.debug('Evicted old cache entries', {
    account = account,
    folder = folder,
    evicted = to_remove,
    remaining = vim.tbl_count(folder_cache),
  })
end

-- Get email count for a folder
function M.get_folder_count(account, folder)
  if cache[account] and cache[account][folder] then
    return vim.tbl_count(cache[account][folder])
  end
  return 0
end

-- Clear cache for a specific folder
function M.clear_folder(account, folder)
  if cache[account] and cache[account][folder] then
    local count = vim.tbl_count(cache[account][folder])
    cache[account][folder] = {}
    logger.debug('Cleared folder cache', {
      account = account,
      folder = folder,
      cleared = count,
    })
  end
end

-- Clear all cache
function M.clear_all()
  local total = 0
  for _, account_cache in pairs(cache) do
    for _, folder_cache in pairs(account_cache) do
      total = total + vim.tbl_count(folder_cache)
    end
  end
  
  cache = {}
  logger.debug('Cleared all cache', { cleared = total })
end

-- Get cache statistics
function M.get_stats()
  local total_emails = 0
  local accounts = vim.tbl_count(cache)
  local folders = 0
  
  for _, account_cache in pairs(cache) do
    folders = folders + vim.tbl_count(account_cache)
    for _, folder_cache in pairs(account_cache) do
      total_emails = total_emails + vim.tbl_count(folder_cache)
    end
  end
  
  return vim.tbl_extend('force', stats, {
    total_emails = total_emails,
    accounts = accounts,
    folders = folders,
    hit_rate = stats.hits > 0 and (stats.hits / (stats.hits + stats.misses)) or 0,
  })
end

-- Clear a specific email from cache
function M.clear_email(account, folder, email_id)
  if cache[account] and cache[account][folder] then
    cache[account][folder][tostring(email_id)] = nil
  end
  
  -- Also clear body cache
  local key = string.format('%s:%s:%s', account, folder, email_id)
  body_cache[key] = nil
end

function M.store_email_body(account, folder, email_id, body)
  local key = string.format('%s:%s:%s', account, folder, email_id)
  body_cache[key] = {
    body = body,
    cached_at = os.time(),
  }
end

function M.get_email_body(account, folder, email_id)
  local key = string.format('%s:%s:%s', account, folder, email_id)
  local cached = body_cache[key]
  
  if cached and os.time() - cached.cached_at <= M.config.ttl then
    return cached.body
  end
  
  -- Expired or not found
  if cached then
    body_cache[key] = nil
  end
  return nil
end

return M