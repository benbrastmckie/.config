-- Himalaya Email Client Utilities
-- Core utility functions for email operations
--
-- Email Count Architecture:
-- 1. Counts are fetched from himalaya using fetch_folder_count() with binary search
-- 2. Counts are stored in state module using state.set_folder_count()
-- 3. Counts are automatically updated after sync by sync/manager.lua
-- 4. UI displays counts from state.get_folder_count() with age indicator

local M = {}

local config = require('neotex.plugins.tools.himalaya.core.config')
local notify = require('neotex.util.notifications')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local state = require('neotex.plugins.tools.himalaya.core.state')
local id_validator = require('neotex.plugins.tools.himalaya.core.id_validator')

-- Load utility modules
local string_utils = require('neotex.plugins.tools.himalaya.utils.string')
local email_utils = require('neotex.plugins.tools.himalaya.utils.email')
local cli_utils = require('neotex.plugins.tools.himalaya.utils.cli')
local file_utils = require('neotex.plugins.tools.himalaya.utils.file')
local async_utils = require('neotex.plugins.tools.himalaya.utils.async')

-- Re-export for backward compatibility
M.truncate_string = string_utils.truncate_string
M.format_flags = email_utils.format_flags
M.format_date = string_utils.format_date
M.format_from = string_utils.format_from
M.format_size = string_utils.format_size
M.execute_himalaya = cli_utils.execute_himalaya
M.format_email_for_sending = email_utils.format_email_for_sending
M.parse_email_content = email_utils.parse_email_content

-- Cache for all emails to support pagination without repeatedly fetching
local email_cache = {}
local cache_timestamp = 0
local cache_timeout = 30000 -- 30 seconds

-- Clear email cache (call when emails are modified)
function M.clear_email_cache(account, folder)
  if account and folder then
    local cache_key = account .. '|' .. folder
    email_cache[cache_key] = nil
  else
    -- Clear entire cache
    email_cache = {}
  end
  cache_timestamp = 0
end

-- Get folders for account
function M.get_folders(account)
  -- In test mode, return mock folders
  if _G.HIMALAYA_TEST_MODE then
    return {
      { name = "INBOX", path = "/" },
      { name = "Sent", path = "/" },
      { name = "Drafts", path = "/" },
      { name = "Trash", path = "/" }
    }
  end
  
  local account_config = config.get_account(account)
  if not account_config then
    -- Don't log error in test mode
    if not _G.HIMALAYA_TEST_MODE then
      logger.error('Account not found', { account = account })
    end
    return {}
  end
  
  -- Use CLI to get folders
  local args = { 'folder', 'list' }
  local result = cli_utils.execute_himalaya(args, { account = account })
  
  if not result then
    -- Fallback to maildir scanning if CLI fails
    return M.scan_maildir_folders(account)
  end
  
  -- Convert to expected format
  local folders = {}
  for _, folder in ipairs(result) do
    table.insert(folders, {
      name = folder.name or folder,
      path = folder.path or '/'
    })
  end
  
  return folders
end

-- Scan maildir folders
function M.scan_maildir_folders(account)
  local account_config = config.get_account(account)
  if not account_config or not account_config.maildir_path then
    return {}
  end
  
  local maildir = vim.fn.expand(account_config.maildir_path)
  local folders = {}
  
  -- Always include INBOX
  table.insert(folders, { name = "INBOX", path = "/" })
  
  -- Scan for Maildir++ folders (start with .)
  local scan_dir = vim.fn.expand(maildir)
  if file_utils.is_dir(scan_dir) then
    local items = file_utils.list_dir(scan_dir, function(name, type)
      return type == 'directory' and name:sub(1, 1) == '.'
    end)
    
    for _, item in ipairs(items) do
      local folder_name = item.name:sub(2) -- Remove leading dot
      table.insert(folders, {
        name = folder_name,
        path = "/"
      })
    end
  end
  
  return folders
end

-- Get email list for a folder
function M.get_email_list(account, folder, page, page_size)
  page = page or 1
  page_size = page_size or 50
  
  local cache_key = account .. '|' .. folder
  local now = vim.loop.hrtime() / 1000000
  
  -- Check cache
  if email_cache[cache_key] and (now - cache_timestamp) < cache_timeout then
    local cached_emails = email_cache[cache_key]
    local start_idx = (page - 1) * page_size + 1
    local end_idx = page * page_size
    
    return vim.list_slice(cached_emails, start_idx, end_idx)
  end
  
  -- Fetch emails from CLI
  local args = { 'envelope', 'list', '-s', page_size * 3 } -- Fetch extra for caching
  local result = cli_utils.execute_himalaya(args, {
    account = account,
    folder = folder,
    show_loading = true
  })
  
  if not result then
    return {}
  end
  
  -- Cache all emails
  email_cache[cache_key] = result
  cache_timestamp = now
  
  -- Return requested page
  local start_idx = (page - 1) * page_size + 1
  local end_idx = page * page_size
  
  return vim.list_slice(result, start_idx, end_idx)
end

-- Get email list with smart filling for partial pages
function M.get_email_list_smart_fill(account, folder, page, page_size)
  local emails = M.get_email_list(account, folder, page, page_size)
  
  -- If we got less than requested and it's not page 1, try to fill from previous pages
  if #emails < page_size and page > 1 then
    local needed = page_size - #emails
    local previous_page = page - 1
    
    while needed > 0 and previous_page > 0 do
      local prev_emails = M.get_email_list(account, folder, previous_page, needed)
      
      -- Prepend previous emails
      for i = #prev_emails, 1, -1 do
        table.insert(emails, 1, prev_emails[i])
        needed = needed - 1
        if needed == 0 then break end
      end
      
      previous_page = previous_page - 1
    end
  end
  
  return emails
end

-- Get email content
function M.get_email_content(account, email_id, folder)
  -- For draft IDs, read from maildir
  if email_id and email_id:match('^draft_') then
    return M.read_draft_from_maildir(account, email_id)
  end
  
  local args = { 'message', 'read', email_id }
  return cli_utils.execute_himalaya(args, { 
    account = account,
    folder = folder,
    show_loading = true
  })
end

-- Send email
function M.send_email(account, email_data)
  -- Format email
  local formatted = email_utils.format_email_for_sending(email_data)
  
  -- Write to temporary file
  local temp_file = file_utils.temp_file('himalaya_send', '.eml')
  local ok, err = file_utils.write_file(temp_file, formatted)
  
  if not ok then
    os.remove(temp_file)
    return false, err
  end
  
  -- Send using CLI
  local args = { 'send' }
  local result = cli_utils.execute_himalaya(args, {
    account = account,
    show_loading = true,
    loading_msg = 'Sending email...'
  })
  
  -- Clean up temp file
  os.remove(temp_file)
  
  return result ~= nil, result
end

-- Get email by ID
function M.get_email_by_id(account, folder, email_id)
  -- For draft IDs, use special handling
  if email_id and email_id:match('^draft_') then
    local draft_content = M.read_draft_from_maildir(account, email_id)
    if draft_content then
      return {
        id = email_id,
        subject = draft_content.subject or 'Draft',
        from = draft_content.from,
        to = draft_content.to,
        date = draft_content.date,
        flags = { draft = true }
      }
    end
    return nil
  end
  
  -- Check cache first
  local cache_key = account .. '|' .. folder
  if email_cache[cache_key] then
    for _, email in ipairs(email_cache[cache_key]) do
      if email.id == email_id then
        return email
      end
    end
  end
  
  -- Fetch from CLI
  local args = { 'envelope', 'get', email_id }
  return cli_utils.execute_himalaya(args, {
    account = account,
    folder = folder
  })
end

-- Read draft from maildir
function M.read_draft_from_maildir(account, email_id)
  local draft_manager = require("neotex.plugins.tools.himalaya.data.drafts")
  
  -- Extract filename from draft ID
  local filename = email_id:match('^draft_(.+)$')
  if not filename then
    return nil
  end
  
  -- Find draft folder
  local draft_folder = M.find_draft_folder(account)
  if not draft_folder then
    return nil
  end
  
  -- Get account config
  local account_config = config.get_account(account)
  if not account_config or not account_config.maildir_path then
    return nil
  end
  
  -- Build maildir path
  local maildir_base = vim.fn.expand(account_config.maildir_path)
  local folder_path
  
  if draft_folder == 'Drafts' then
    folder_path = maildir_base .. '.Drafts'
  else
    folder_path = maildir_base .. draft_folder:gsub('/', '.')
  end
  
  -- Look in cur directory
  local draft_path = folder_path .. '/cur/' .. filename
  if not file_utils.exists(draft_path) then
    -- Try new directory
    draft_path = folder_path .. '/new/' .. filename
    if not file_utils.exists(draft_path) then
      return nil
    end
  end
  
  -- Read and parse email
  local content = file_utils.read_file(draft_path)
  if content then
    local lines = vim.split(content, '\n')
    return email_utils.parse_email_content(lines)
  end
  
  return nil
end

-- Find draft folder for account
function M.find_draft_folder(account)
  local account_config = config.get_account(account)
  if not account_config then
    return nil
  end
  
  -- Check folder mapping
  if account_config.folder_map then
    for imap, local_name in pairs(account_config.folder_map) do
      if local_name == 'Drafts' or imap:lower():match('draft') then
        return local_name
      end
    end
  end
  
  -- Default draft folder
  return 'Drafts'
end

-- Find sent folder for account
function M.find_sent_folder(account)
  local account_config = config.get_account(account)
  if not account_config then
    return nil
  end
  
  -- Check folder mapping
  if account_config.folder_map then
    for imap, local_name in pairs(account_config.folder_map) do
      if local_name == 'Sent' or imap:lower():match('sent') then
        return local_name
      end
    end
  end
  
  -- Check IMAP special folders
  local folders = M.get_folders(account)
  for _, folder in ipairs(folders) do
    if folder.name:lower():match('sent') then
      return folder.name
    end
  end
  
  -- Default sent folder
  return 'Sent'
end

-- Save draft using maildir
function M.save_draft(account, folder, email_data)
  local draft_manager = require("neotex.plugins.tools.himalaya.data.drafts")
  
  -- Ensure we have a draft folder
  folder = folder or M.find_draft_folder(account)
  if not folder then
    return nil, 'No draft folder found'
  end
  
  -- Save draft
  local draft_id = draft_manager.create(account, email_data)
  
  if draft_id then
    -- Clear cache for draft folder
    M.clear_email_cache(account, folder)
    
    -- Emit draft saved event
    local events = require('neotex.plugins.tools.himalaya.core.events')
    local orchestrator = require('neotex.plugins.tools.himalaya.commands.orchestrator')
    orchestrator.emit(events.DRAFT_SAVED, {
      account = account,
      folder = folder,
      draft_id = draft_id
    })
  end
  
  -- Return in expected format
  if draft_id then
    return {
      id = tostring(draft_id),
      folder = folder
    }
  end
  
  return nil
end

-- Delete email
function M.delete_email(account, folder, email_id)
  -- For draft IDs, use draft manager
  if email_id and email_id:match('^draft_') then
    local draft_manager = require("neotex.plugins.tools.himalaya.data.drafts")
    return draft_manager.delete_draft(account, folder, email_id)
  end
  
  local args = { 'message', 'delete', email_id }
  local result = cli_utils.execute_himalaya(args, {
    account = account,
    folder = folder
  })
  
  if result then
    -- Clear cache
    M.clear_email_cache(account, folder)
  end
  
  return result ~= nil
end

-- Fetch folder count using binary search
function M.fetch_folder_count(account, folder)
  -- Try different page sizes to find total count
  local page_sizes = { 1000, 500, 100, 50, 10 }
  
  for _, size in ipairs(page_sizes) do
    local args = { 'envelope', 'list', '-s', size }
    local result = cli_utils.execute_himalaya(args, {
      account = account,
      folder = folder
    })
    
    if result and #result < size then
      -- Found exact count
      return #result
    end
  end
  
  -- If we still don't know, do binary search
  local low = 1000
  local high = 10000
  local last_known_count = 1000
  
  while low <= high do
    local mid = math.floor((low + high) / 2)
    local args = { 'envelope', 'list', '-s', mid }
    local result = cli_utils.execute_himalaya(args, {
      account = account,
      folder = folder
    })
    
    if result then
      if #result < mid then
        -- Found exact count
        return #result
      else
        -- There are at least 'mid' emails
        last_known_count = mid
        low = mid + 1
      end
    else
      -- Error, try smaller size
      high = mid - 1
    end
  end
  
  return last_known_count .. '+'
end

-- Smart delete that moves to trash
function M.smart_delete_email(account, email_id)
  local current_folder = state.get_current_folder()
  
  -- If already in trash, delete permanently
  if current_folder and current_folder:lower():match('trash') then
    return M.delete_email(account, current_folder, email_id)
  end
  
  -- Find trash folder
  local trash_folder = nil
  local folders = M.get_folders(account)
  
  for _, folder in ipairs(folders) do
    if folder.name:lower():match('trash') or folder.name:lower():match('deleted') then
      trash_folder = folder.name
      break
    end
  end
  
  -- Move to trash if found, otherwise delete
  if trash_folder then
    return M.move_email(email_id, trash_folder)
  else
    return M.delete_email(account, current_folder, email_id)
  end
end

-- Move email to folder
function M.move_email(email_id, target_folder)
  local account = config.get_current_account_name()
  local current_folder = state.get_current_folder()
  
  if not account or not current_folder then
    return false, 'No account or folder selected'
  end
  
  local args = { 'message', 'move', email_id, target_folder }
  local result = cli_utils.execute_himalaya(args, {
    account = account,
    folder = current_folder
  })
  
  if result then
    -- Clear cache for both folders
    M.clear_email_cache(account, current_folder)
    M.clear_email_cache(account, target_folder)
  end
  
  return result ~= nil
end

-- Search emails
function M.search_emails(account, query)
  local args = { 'envelope', 'list', query }
  return cli_utils.execute_himalaya(args, { account = account })
end

-- Get email attachments
function M.get_email_attachments(account, email_id)
  local args = { 'attachment', 'list', email_id }
  return cli_utils.execute_himalaya(args, { account = account })
end

-- Manage email tags
function M.manage_tag(email_id, tag, action)
  local account = config.get_current_account_name()
  local folder = state.get_current_folder()
  
  if not account or not folder then
    return false
  end
  
  local args = { 'flag', action, tag, email_id }
  local result = cli_utils.execute_himalaya(args, {
    account = account,
    folder = folder
  })
  
  if result then
    -- Clear cache
    M.clear_email_cache(account, folder)
  end
  
  return result ~= nil
end

-- Get email info
function M.get_email_info(email_id)
  local account = config.get_current_account_name()
  local folder = state.get_current_folder()
  
  if not account or not folder then
    return nil
  end
  
  return M.get_email_content(account, email_id, folder)
end

-- Get emails asynchronously
function M.get_emails_async(account, folder, page, page_size, callback)
  -- For test mode, return mock data immediately
  if _G.HIMALAYA_TEST_MODE then
    local mock_emails = {}
    if folder == 'INBOX' then
      mock_emails = {
        {
          id = "test-001",
          subject = "Test Email 1",
          from = { name = "Test Sender", address = "sender@test.com" },
          date = os.date("%Y-%m-%d %H:%M:%S"),
          flags = { unread = true }
        },
        {
          id = "test-002", 
          subject = "Test Email 2",
          from = { name = "Another Sender", address = "another@test.com" },
          date = os.date("%Y-%m-%d %H:%M:%S"),
          flags = { unread = false }
        }
      }
    end
    -- Use vim.schedule to simulate async behavior
    vim.schedule(function()
      callback(mock_emails, #mock_emails)
    end)
    return
  end
  
  -- Use async CLI execution
  local args = { 'envelope', 'list' }
  
  -- Add pagination
  if page and page_size then
    local offset = (page - 1) * page_size
    table.insert(args, '-s')
    table.insert(args, tostring(page_size))
    if offset > 0 then
      table.insert(args, '--offset')
      table.insert(args, tostring(offset))
    end
  end
  
  cli_utils.execute_himalaya_async(args, {
    account = account,
    folder = folder
  }, function(result, error)
    if error then
      callback(nil, 0, error)
    else
      -- Get total count (approximate)
      local total_count = #(result or {})

      -- If we got a full page, there might be more
      if result and #result == page_size then
        -- Try to get a more accurate count
        local count_args = { 'envelope', 'list', '-s', '1000' }
        local count_result = cli_utils.execute_himalaya(count_args, {
          account = account,
          folder = folder
        })
        if count_result then
          total_count = #count_result
        end
      end

      callback(result, total_count)
    end
  end)
end

-- Re-export utility sub-modules
M.string = string_utils
M.email = email_utils
M.cli = cli_utils
M.file = file_utils
M.async = async_utils
M.fn = async_utils
M.perf = {
  measure = function(fn, label)
    local start = vim.loop.hrtime()
    local result = {fn()}
    local duration = (vim.loop.hrtime() - start) / 1000000
    
    if label then
      logger.debug(string.format("Performance: %s took %.2fms", label, duration))
    end
    
    return duration, unpack(result)
  end,
  
  benchmark = function(fn, iterations)
    iterations = iterations or 100
    local times = {}
    
    for i = 1, iterations do
      local duration = M.perf.measure(fn)
      table.insert(times, duration)
    end
    
    table.sort(times)
    local sum = 0
    for _, time in ipairs(times) do
      sum = sum + time
    end
    
    return {
      min = times[1],
      max = times[#times],
      avg = sum / iterations,
      median = times[math.floor(#times / 2)],
      iterations = iterations
    }
  end
}

-- Table utilities (for backward compatibility)
M.table = {
  deep_merge = function(t1, t2)
    local result = vim.deepcopy(t1)
    
    for k, v in pairs(t2) do
      if type(v) == "table" and type(result[k]) == "table" then
        result[k] = M.table.deep_merge(result[k], v)
      else
        result[k] = v
      end
    end
    
    return result
  end,
  
  filter = function(tbl, predicate)
    local result = {}
    
    for k, v in pairs(tbl) do
      if predicate(v, k) then
        result[k] = v
      end
    end
    
    return result
  end,
  
  map = function(tbl, mapper)
    local result = {}
    
    for k, v in pairs(tbl) do
      result[k] = mapper(v, k)
    end
    
    return result
  end,
  
  group_by = function(tbl, key_fn)
    local result = {}
    
    for _, item in ipairs(tbl) do
      local key = key_fn(item)
      result[key] = result[key] or {}
      table.insert(result[key], item)
    end
    
    return result
  end
}

-- Backward compatibility for validate.email
M.validate = {
  email = email_utils.validate_email
}

return M