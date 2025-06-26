-- Diagnose Display Issues
local M = {}

local notify = require('neotex.util.notifications')

function M.diagnose_sidebar()
  notify.himalaya('=== SIDEBAR DIAGNOSIS ===', notify.categories.USER_ACTION)
  
  local sidebar = require('neotex.plugins.tools.himalaya.sidebar')
  local buf = sidebar.get_buf()
  
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    notify.himalaya('Sidebar buffer not found', notify.categories.ERROR)
    return
  end
  
  -- Get the displayed content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  
  -- Count subjects
  local subjects = {}
  local duplicate_count = 0
  local total_emails = 0
  
  for _, line in ipairs(lines) do
    -- Extract subject from display line
    local subject = line:match('%[.%]%s+(.-)%s+%d+:%d+')
    if subject then
      total_emails = total_emails + 1
      if subjects[subject] then
        subjects[subject] = subjects[subject] + 1
        duplicate_count = duplicate_count + 1
      else
        subjects[subject] = 1
      end
    end
  end
  
  notify.himalaya(string.format('Total emails displayed: %d', total_emails), notify.categories.STATUS)
  notify.himalaya(string.format('Unique subjects: %d', vim.tbl_count(subjects)), notify.categories.STATUS)
  notify.himalaya(string.format('Duplicate displays: %d', duplicate_count), notify.categories.STATUS)
  
  -- Show worst offenders
  local sorted = {}
  for subject, count in pairs(subjects) do
    if count > 1 then
      table.insert(sorted, {subject = subject, count = count})
    end
  end
  table.sort(sorted, function(a, b) return a.count > b.count end)
  
  if #sorted > 0 then
    notify.himalaya('', notify.categories.STATUS)
    notify.himalaya('Most duplicated:', notify.categories.STATUS)
    for i = 1, math.min(3, #sorted) do
      notify.himalaya(string.format('  "%s" appears %d times', 
        sorted[i].subject:sub(1, 40), sorted[i].count), notify.categories.STATUS)
    end
  end
  
  -- Check buffer cache
  local cached_emails = vim.b[buf].himalaya_emails
  if cached_emails then
    notify.himalaya('', notify.categories.STATUS)
    notify.himalaya(string.format('Buffer cache contains %d emails', #cached_emails), notify.categories.STATUS)
  end
end

function M.compare_sources()
  notify.himalaya('=== SOURCE COMPARISON ===', notify.categories.USER_ACTION)
  
  -- Get from Himalaya CLI
  local handle = io.popen('himalaya envelope list -f INBOX --page 1 --page-size 200 -o json 2>/dev/null')
  local cli_emails = {}
  if handle then
    local output = handle:read('*a')
    handle:close()
    local ok, parsed = pcall(vim.json.decode, output)
    if ok and parsed then
      cli_emails = parsed
    end
  end
  
  -- Get from cache
  local utils = require('neotex.plugins.tools.himalaya.utils')
  local config = require('neotex.plugins.tools.himalaya.config')
  local cached_emails = utils.get_email_list(config.state.current_account, 'INBOX', 1, 200)
  
  notify.himalaya(string.format('CLI returns: %d emails', #cli_emails), notify.categories.STATUS)
  notify.himalaya(string.format('Cache returns: %d emails', cached_emails and #cached_emails or 0), notify.categories.STATUS)
  
  -- Compare IDs
  if #cli_emails > 0 and cached_emails and #cached_emails > 0 then
    local cli_ids = {}
    for _, email in ipairs(cli_emails) do
      cli_ids[tostring(email.id)] = true
    end
    
    local cache_ids = {}
    for _, email in ipairs(cached_emails) do
      cache_ids[tostring(email.id)] = true
    end
    
    -- Find duplicates in cache
    local id_counts = {}
    for _, email in ipairs(cached_emails) do
      local id = tostring(email.id)
      id_counts[id] = (id_counts[id] or 0) + 1
    end
    
    local dups = 0
    for id, count in pairs(id_counts) do
      if count > 1 then
        dups = dups + (count - 1)
      end
    end
    
    if dups > 0 then
      notify.himalaya(string.format('⚠️  Cache has %d duplicate IDs!', dups), notify.categories.WARNING)
    end
  end
end

-- Setup commands
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaDiagnoseSidebar', M.diagnose_sidebar, {
    desc = 'Diagnose sidebar display issues'
  })
  
  vim.api.nvim_create_user_command('HimalayaCompareSources', M.compare_sources, {
    desc = 'Compare CLI vs cache email sources'
  })
end

return M