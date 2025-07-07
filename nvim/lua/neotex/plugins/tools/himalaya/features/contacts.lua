-- Address Autocomplete and Contact Management
-- Manages email contacts with autocomplete functionality

local M = {}

local state = require('neotex.plugins.tools.himalaya.core.state')
local config = require('neotex.plugins.tools.himalaya.core.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local utils_enhanced = require('neotex.plugins.tools.himalaya.utils.enhanced')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local api = require('neotex.plugins.tools.himalaya.core.api')

-- Contact schema
local contact_schema = {
  email = "",             -- Email address (primary key)
  name = "",              -- Display name
  first_name = "",        -- First name
  last_name = "",         -- Last name
  organization = "",      -- Organization/company
  frequency = 0,          -- How often contacted
  last_contact = 0,       -- Last contact timestamp
  tags = {},              -- Tags for categorization
  notes = "",             -- Additional notes
  source = ""             -- Where contact came from (sent, received, manual)
}

-- Contacts database file
M.db_file = vim.fn.stdpath('data') .. '/himalaya/contacts.json'

-- Initialize contacts system
function M.setup()
  -- Create data directory
  vim.fn.mkdir(vim.fn.fnamemodify(M.db_file, ':h'), 'p')
  
  -- Load contacts database
  M.load_database()
  
  -- Scan existing emails for contacts
  if config.get('contacts.auto_scan', true) then
    vim.defer_fn(function()
      M.scan_emails_for_contacts()
    end, 5000) -- Delay to avoid startup impact
  end
end

-- Load contacts database
function M.load_database()
  if vim.fn.filereadable(M.db_file) == 0 then
    return {}
  end
  
  local content = vim.fn.readfile(M.db_file)
  content = table.concat(content, "\n")
  
  local ok, contacts = pcall(vim.json.decode, content)
  if not ok then
    logger.error("Failed to load contacts database: " .. tostring(contacts))
    return {}
  end
  
  return contacts
end

-- Save contacts database
function M.save_database(contacts)
  local ok, json = pcall(vim.json.encode, contacts)
  if not ok then
    logger.error("Failed to encode contacts database: " .. tostring(json))
    return false
  end
  
  local file = io.open(M.db_file, 'w')
  if file then
    file:write(json)
    file:close()
    return true
  end
  
  return false
end

-- Add or update contact
function M.add_contact(contact_info)
  -- Validate email
  if not contact_info.email or not utils_enhanced.validate.email(contact_info.email) then
    return api.error("Invalid email address", "INVALID_EMAIL")
  end
  
  local contacts = M.load_database()
  local email = contact_info.email:lower()
  
  -- Update existing or create new
  if contacts[email] then
    -- Merge with existing
    for key, value in pairs(contact_info) do
      if value ~= "" and value ~= nil then
        contacts[email][key] = value
      end
    end
  else
    -- Create new contact
    contacts[email] = vim.tbl_extend("force", {
      email = email,
      added_at = os.time()
    }, contact_info)
  end
  
  M.save_database(contacts)
  
  logger.debug("Added/updated contact: " .. email)
  
  return api.success(contacts[email])
end

-- Get contact by email
function M.get_contact(email)
  local contacts = M.load_database()
  return contacts[email:lower()]
end

-- Search contacts
function M.search(query, options)
  options = options or {}
  local contacts = M.load_database()
  local results = {}
  
  query = query:lower()
  
  for email, contact in pairs(contacts) do
    local match = false
    
    -- Search in email
    if email:find(query, 1, true) then
      match = true
    end
    
    -- Search in name
    if contact.name and contact.name:lower():find(query, 1, true) then
      match = true
    end
    
    -- Search in organization
    if contact.organization and contact.organization:lower():find(query, 1, true) then
      match = true
    end
    
    -- Search in tags
    if options.include_tags then
      for _, tag in ipairs(contact.tags or {}) do
        if tag:lower():find(query, 1, true) then
          match = true
          break
        end
      end
    end
    
    if match then
      table.insert(results, contact)
    end
  end
  
  -- Sort by relevance/frequency
  table.sort(results, function(a, b)
    -- Exact email match first
    local a_exact = a.email:lower() == query
    local b_exact = b.email:lower() == query
    
    if a_exact ~= b_exact then
      return a_exact
    end
    
    -- Then by frequency
    return (a.frequency or 0) > (b.frequency or 0)
  end)
  
  -- Apply limit
  if options.limit and #results > options.limit then
    local limited = {}
    for i = 1, options.limit do
      limited[i] = results[i]
    end
    results = limited
  end
  
  return results
end

-- Autocomplete function for email addresses
function M.complete(prefix)
  if #prefix < 2 then
    return {}
  end
  
  local results = M.search(prefix, { limit = 10 })
  local completions = {}
  
  for _, contact in ipairs(results) do
    local display = contact.email
    if contact.name then
      display = string.format('"%s" <%s>', contact.name, contact.email)
    end
    
    table.insert(completions, {
      word = display,
      abbr = display,
      menu = contact.organization or "",
      info = string.format(
        "Contact: %s\nFrequency: %d\nLast contact: %s",
        contact.name or contact.email,
        contact.frequency or 0,
        contact.last_contact and os.date("%Y-%m-%d", contact.last_contact) or "Never"
      ),
      user_data = contact
    })
  end
  
  return completions
end

-- Extract contacts from email
function M.extract_from_email(email_data)
  local contacts = {}
  
  -- Extract from From field
  if email_data.from then
    local email, name = M.parse_address(email_data.from)
    if email then
      table.insert(contacts, {
        email = email,
        name = name,
        source = 'received'
      })
    end
  end
  
  -- Extract from To field
  if email_data.to then
    for _, address in ipairs(M.parse_address_list(email_data.to)) do
      if address.email then
        address.source = 'sent'
        table.insert(contacts, address)
      end
    end
  end
  
  -- Extract from CC field
  if email_data.cc then
    for _, address in ipairs(M.parse_address_list(email_data.cc)) do
      if address.email then
        address.source = 'sent'
        table.insert(contacts, address)
      end
    end
  end
  
  return contacts
end

-- Parse email address
function M.parse_address(address_str)
  -- Match "Name" <email@domain.com>
  local name, email = address_str:match('^"?([^"<>]+)"?%s*<([^>]+)>$')
  
  if not email then
    -- Try just email
    email = address_str:match('^<?([^<>]+@[^<>]+)>?$')
  end
  
  if email then
    email = email:gsub("^%s+", ""):gsub("%s+$", "")
    if name then
      name = name:gsub("^%s+", ""):gsub("%s+$", "")
    end
  end
  
  return email, name
end

-- Parse address list
function M.parse_address_list(address_list_str)
  local addresses = {}
  
  -- Split by comma, handling quoted names
  local in_quotes = false
  local current = ""
  
  for char in address_list_str:gmatch(".") do
    if char == '"' then
      in_quotes = not in_quotes
    end
    
    if char == "," and not in_quotes then
      local email, name = M.parse_address(current)
      if email then
        table.insert(addresses, { email = email, name = name })
      end
      current = ""
    else
      current = current .. char
    end
  end
  
  -- Don't forget the last one
  if current ~= "" then
    local email, name = M.parse_address(current)
    if email then
      table.insert(addresses, { email = email, name = name })
    end
  end
  
  return addresses
end

-- Scan emails for contacts
function M.scan_emails_for_contacts()
  logger.info("Scanning emails for contacts...")
  
  local account = config.get_current_account_name()
  local scanned = 0
  local added = 0
  
  -- Get recent emails
  local result = utils.execute_himalaya(
    {'envelope', 'list', '--page', '1', '--page-size', '100'},
    { account = account, folder = 'INBOX' }
  )
  
  if result.success and result.data then
    for _, email in ipairs(result.data) do
      local contacts = M.extract_from_email(email)
      
      for _, contact in ipairs(contacts) do
        local existing = M.get_contact(contact.email)
        
        if not existing then
          M.add_contact(contact)
          added = added + 1
        else
          -- Update frequency
          M.update_contact_frequency(contact.email)
        end
      end
      
      scanned = scanned + 1
    end
  end
  
  -- Also scan sent folder
  result = utils.execute_himalaya(
    {'envelope', 'list', '--page', '1', '--page-size', '100'},
    { account = account, folder = 'Sent' }
  )
  
  if result.success and result.data then
    for _, email in ipairs(result.data) do
      local contacts = M.extract_from_email(email)
      
      for _, contact in ipairs(contacts) do
        M.update_contact_frequency(contact.email)
      end
      
      scanned = scanned + 1
    end
  end
  
  logger.info(string.format("Scanned %d emails, added %d new contacts", scanned, added))
end

-- Update contact frequency
function M.update_contact_frequency(email, timestamp)
  local contacts = M.load_database()
  email = email:lower()
  
  if contacts[email] then
    contacts[email].frequency = (contacts[email].frequency or 0) + 1
    contacts[email].last_contact = timestamp or os.time()
    M.save_database(contacts)
  end
end

-- Get recent contacts
function M.get_recent(limit)
  limit = limit or 10
  local contacts = M.load_database()
  local recent = {}
  
  for _, contact in pairs(contacts) do
    if contact.last_contact then
      table.insert(recent, contact)
    end
  end
  
  -- Sort by last contact
  table.sort(recent, function(a, b)
    return (a.last_contact or 0) > (b.last_contact or 0)
  end)
  
  -- Limit results
  local results = {}
  for i = 1, math.min(limit, #recent) do
    results[i] = recent[i]
  end
  
  return results
end

-- Get frequent contacts
function M.get_frequent(limit)
  limit = limit or 10
  local contacts = M.load_database()
  local frequent = {}
  
  for _, contact in pairs(contacts) do
    if (contact.frequency or 0) > 0 then
      table.insert(frequent, contact)
    end
  end
  
  -- Sort by frequency
  table.sort(frequent, function(a, b)
    return (a.frequency or 0) > (b.frequency or 0)
  end)
  
  -- Limit results
  local results = {}
  for i = 1, math.min(limit, #frequent) do
    results[i] = frequent[i]
  end
  
  return results
end

-- Export contacts
function M.export(format)
  format = format or 'csv'
  local contacts = M.load_database()
  
  if format == 'csv' then
    local lines = {'email,name,organization,frequency,last_contact,tags'}
    
    for _, contact in pairs(contacts) do
      local line = string.format(
        '"%s","%s","%s",%d,%s,"%s"',
        contact.email,
        contact.name or "",
        contact.organization or "",
        contact.frequency or 0,
        contact.last_contact and os.date("%Y-%m-%d", contact.last_contact) or "",
        table.concat(contact.tags or {}, ";")
      )
      table.insert(lines, line)
    end
    
    return table.concat(lines, "\n")
  elseif format == 'json' then
    return vim.json.encode(contacts)
  else
    return nil, "Unsupported format: " .. format
  end
end

-- Import contacts
function M.import(data, format)
  format = format or 'csv'
  
  if format == 'csv' then
    -- Simple CSV parsing (assumes no commas in values)
    local lines = vim.split(data, '\n')
    local imported = 0
    
    for i = 2, #lines do -- Skip header
      local line = lines[i]
      if line ~= "" then
        local email, name, org = line:match('^"([^"]+)","([^"]*)","([^"]*)"')
        
        if email and utils_enhanced.validate.email(email) then
          M.add_contact({
            email = email,
            name = name ~= "" and name or nil,
            organization = org ~= "" and org or nil,
            source = 'imported'
          })
          imported = imported + 1
        end
      end
    end
    
    return imported
  elseif format == 'json' then
    local ok, contacts = pcall(vim.json.decode, data)
    if not ok then
      return nil, "Invalid JSON data"
    end
    
    local imported = 0
    for email, contact in pairs(contacts) do
      if utils_enhanced.validate.email(email) then
        M.add_contact(contact)
        imported = imported + 1
      end
    end
    
    return imported
  else
    return nil, "Unsupported format: " .. format
  end
end

return M