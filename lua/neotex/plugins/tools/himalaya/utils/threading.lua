-- Email Threading Utilities
-- Provides subject normalization and thread grouping for email conversations
-- Used by the email list UI to display threaded email views

local M = {}

-- Logger for debugging
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Reply/forward prefix patterns to strip
-- Common patterns across email clients and languages:
-- Re: (English), AW: (German Antwort), SV: (Scandinavian Svar)
-- Fwd:/FW: (Forward), Rif: (Italian Riferimento)
local PREFIX_PATTERNS = {
  "^%s*[Rr][Ee]:%s*",          -- Re:
  "^%s*[Aa][Ww]:%s*",          -- AW: (German)
  "^%s*[Ss][Vv]:%s*",          -- SV: (Scandinavian)
  "^%s*[Ff][Ww][Dd]?:%s*",     -- Fwd:/FW:
  "^%s*[Rr][Ii][Ff]:%s*",      -- Rif: (Italian)
  "^%s*%[[^%]]*%]%s*",         -- [bracketed tags] like [JIRA-123]
}

--- Normalize an email subject for thread grouping
--- Strips reply/forward prefixes and normalizes whitespace
--- @param subject string|nil The email subject to normalize
--- @return string The normalized subject
function M.normalize_subject(subject)
  if not subject then
    return ""
  end

  -- Convert to string if needed
  subject = tostring(subject)

  -- Trim leading/trailing whitespace
  subject = subject:gsub("^%s+", ""):gsub("%s+$", "")

  -- Keep stripping prefixes until no more match
  local changed = true
  while changed do
    changed = false
    for _, pattern in ipairs(PREFIX_PATTERNS) do
      local new_subject = subject:gsub(pattern, "")
      if new_subject ~= subject then
        subject = new_subject
        changed = true
        break  -- Restart from beginning after any change
      end
    end
  end

  -- Final trim
  subject = subject:gsub("^%s+", ""):gsub("%s+$", "")

  -- Normalize internal whitespace (multiple spaces -> single space)
  subject = subject:gsub("%s+", " ")

  -- Convert to lowercase for case-insensitive matching
  subject = subject:lower()

  return subject
end

--- Parse email date into timestamp for comparison
--- @param date_str string|nil Date string from email
--- @return number Timestamp (defaults to 0 if unparseable)
local function parse_date(date_str)
  if not date_str then
    return 0
  end

  -- Try common formats
  -- Format: "2026-02-13 14:30:00" or "2026-02-13T14:30:00"
  local year, month, day, hour, min, sec = date_str:match("(%d+)-(%d+)-(%d+)[T ]?(%d*):?(%d*):?(%d*)")
  if year then
    return os.time({
      year = tonumber(year),
      month = tonumber(month),
      day = tonumber(day),
      hour = tonumber(hour) or 0,
      min = tonumber(min) or 0,
      sec = tonumber(sec) or 0,
    })
  end

  return 0
end

--- Thread data structure
--- @class ThreadEntry
--- @field normalized_subject string The normalized subject used as thread key
--- @field emails table Array of email objects in this thread
--- @field latest_date number Timestamp of most recent email
--- @field latest_email table The most recent email object
--- @field thread_count number Number of emails in thread
--- @field has_unread boolean Whether any email in thread is unread

--- Build a thread index from a list of emails
--- Groups emails by normalized subject for thread display
--- @param emails table Array of email objects
--- @param opts table|nil Options: { exclude_drafts = boolean }
--- @return table Thread index: { [normalized_subject] = ThreadEntry }
--- @return table Order: Array of normalized subjects in display order (by latest date)
function M.build_thread_index(emails, opts)
  opts = opts or {}

  if not emails or #emails == 0 then
    return {}, {}
  end

  local thread_index = {}

  for _, email in ipairs(emails) do
    -- Skip drafts if requested
    if opts.exclude_drafts and email.flags and email.flags.draft then
      goto continue
    end

    local subject = email.subject or ""
    local normalized = M.normalize_subject(subject)

    -- Use empty string key for emails with no meaningful subject
    if normalized == "" then
      normalized = "(no subject)"
    end

    -- Initialize thread entry if needed
    if not thread_index[normalized] then
      thread_index[normalized] = {
        normalized_subject = normalized,
        emails = {},
        latest_date = 0,
        latest_email = nil,
        thread_count = 0,
        has_unread = false,
      }
    end

    local entry = thread_index[normalized]

    -- Add email to thread
    table.insert(entry.emails, email)
    entry.thread_count = entry.thread_count + 1

    -- Track latest email by date
    local email_date = 0
    if email.mtime then
      email_date = email.mtime
    elseif email.date then
      email_date = parse_date(email.date)
    end

    if email_date > entry.latest_date then
      entry.latest_date = email_date
      entry.latest_email = email
    elseif not entry.latest_email then
      -- No date info, just use first email
      entry.latest_email = email
    end

    -- Check unread status
    if not entry.has_unread then
      local is_unread = true
      if email.flags then
        if type(email.flags) == "table" then
          for _, flag in ipairs(email.flags) do
            if flag == "Seen" then
              is_unread = false
              break
            end
          end
        end
      end
      if is_unread then
        entry.has_unread = true
      end
    end

    ::continue::
  end

  -- Sort threads by latest date (descending - newest first)
  local order = {}
  for normalized, _ in pairs(thread_index) do
    table.insert(order, normalized)
  end

  table.sort(order, function(a, b)
    return thread_index[a].latest_date > thread_index[b].latest_date
  end)

  logger.debug('Built thread index', {
    total_emails = #emails,
    thread_count = #order,
  })

  return thread_index, order
end

--- Get emails within a thread sorted by date
--- @param thread_entry ThreadEntry The thread entry
--- @param ascending boolean If true, sort oldest first; if false, newest first
--- @return table Sorted array of emails
function M.get_sorted_thread_emails(thread_entry, ascending)
  if not thread_entry or not thread_entry.emails then
    return {}
  end

  local emails = vim.deepcopy(thread_entry.emails)

  table.sort(emails, function(a, b)
    local date_a = a.mtime or parse_date(a.date) or 0
    local date_b = b.mtime or parse_date(b.date) or 0

    if ascending then
      return date_a < date_b
    else
      return date_a > date_b
    end
  end)

  return emails
end

--- Check if a thread should be displayed collapsed
--- @param thread_entry ThreadEntry The thread entry
--- @param expanded_threads table Set of expanded thread IDs (normalized subjects)
--- @return boolean True if thread should be displayed collapsed
function M.is_collapsed(thread_entry, expanded_threads)
  if not thread_entry then
    return true
  end

  -- Single-email threads are never "collapsed" in the UI sense
  if thread_entry.thread_count <= 1 then
    return false
  end

  -- Check if explicitly expanded
  if expanded_threads and expanded_threads[thread_entry.normalized_subject] then
    return false
  end

  return true
end

--- Format thread count indicator for display
--- @param count number Number of emails in thread
--- @return string Formatted count indicator (e.g., "[3]" or "")
function M.format_thread_count(count)
  if not count or count <= 1 then
    return ""
  end
  return string.format("[%d]", count)
end

return M
