-- Test Search Helper for Himalaya Plugin Tests
-- Provides search functionality for tests since core search doesn't have filter_emails

local M = {}

-- Simple email filter function for tests
function M.filter_emails(emails, query)
  if not emails or not query then
    return {}
  end
  
  local results = {}
  
  -- Parse simple search syntax
  local field, value = query:match("^(%w+):(.+)$")
  
  if field and value then
    -- Field-specific search
    value = value:lower()
    
    for _, email in ipairs(emails) do
      local match = false
      
      if field == "subject" and email.subject then
        match = email.subject:lower():find(value, 1, true)
      elseif field == "from" and email.from then
        if type(email.from) == "string" then
          match = email.from:lower():find(value, 1, true)
        elseif type(email.from) == "table" then
          local from_str = email.from.email or email.from.name or ""
          match = from_str:lower():find(value, 1, true)
        end
      elseif field == "to" and email.to then
        if type(email.to) == "string" then
          match = email.to:lower():find(value, 1, true)
        elseif type(email.to) == "table" then
          for _, recipient in ipairs(email.to) do
            local to_str = type(recipient) == "string" and recipient or (recipient.email or "")
            if to_str:lower():find(value, 1, true) then
              match = true
              break
            end
          end
        end
      elseif field == "body" and email.body then
        match = email.body:lower():find(value, 1, true)
      elseif field == "date" then
        -- Simple date search (exact match)
        if email.date and email.date:find(value) then
          match = true
        end
      end
      
      if match then
        table.insert(results, email)
      end
    end
  else
    -- General search across all fields
    local search_term = query:lower()
    
    for _, email in ipairs(emails) do
      local match = false
      
      -- Check subject
      if email.subject and email.subject:lower():find(search_term, 1, true) then
        match = true
      end
      
      -- Check from
      if not match and email.from then
        if type(email.from) == "string" then
          match = email.from:lower():find(search_term, 1, true)
        elseif type(email.from) == "table" then
          local from_str = email.from.email or email.from.name or ""
          match = from_str:lower():find(search_term, 1, true)
        end
      end
      
      -- Check body
      if not match and email.body and email.body:lower():find(search_term, 1, true) then
        match = true
      end
      
      if match then
        table.insert(results, email)
      end
    end
  end
  
  return results
end

-- Search with date range support
function M.search_date_range(emails, start_date, end_date)
  local results = {}
  
  -- Convert dates to timestamps for comparison
  local start_ts = type(start_date) == "number" and start_date or os.time(start_date)
  local end_ts = type(end_date) == "number" and end_date or os.time(end_date)
  
  for _, email in ipairs(emails) do
    if email.timestamp then
      local email_ts = email.timestamp
      if email_ts >= start_ts and email_ts <= end_ts then
        table.insert(results, email)
      end
    end
  end
  
  return results
end

-- Cache for search results (for testing cache performance)
M.cache = {}

function M.cached_search(emails, query)
  local cache_key = query .. ":" .. #emails
  
  if M.cache[cache_key] then
    return M.cache[cache_key]
  end
  
  local results = M.filter_emails(emails, query)
  M.cache[cache_key] = results
  
  return results
end

-- Clear cache
function M.clear_cache()
  M.cache = {}
end

return M