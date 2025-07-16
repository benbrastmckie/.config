-- String Utilities for Himalaya
-- String formatting, manipulation, and display utilities

local M = {}

-- Truncate string to specified length
function M.truncate(str, max_length, ellipsis)
  if not str then return '' end
  
  -- Handle vim.NIL specifically
  if str == vim.NIL then return '' end
  
  -- Convert to string
  local str_value = tostring(str)
  
  ellipsis = ellipsis or '...'
  if #str_value <= max_length then
    return str_value
  end
  return str_value:sub(1, max_length - #ellipsis) .. ellipsis
end

-- Backward compatibility wrapper
function M.truncate_string(str, max_length)
  return M.truncate(str, max_length)
end

-- Format date for display
function M.format_date(date)
  if not date then return 'Unknown' end
  
  -- If date is already a string, return it
  if type(date) == 'string' then
    -- Try to parse common date formats
    local month, day = date:match('(%a+) (%d+)')
    if month and day then
      return month:sub(1, 3) .. ' ' .. string.format('%2s', day)
    end
    return date:sub(1, 10)
  end
  
  -- If date is a timestamp
  if type(date) == 'number' then
    return os.date('%b %d', date)
  end
  
  return 'Unknown'
end

-- Format from field
function M.format_from(from)
  if not from then return 'Unknown' end
  
  -- Extract name or email
  local name = from:match('^"?([^"<]+)"?%s*<') or from:match('^([^@]+)@') or from
  
  -- Clean up and truncate
  name = name:gsub('^%s+', ''):gsub('%s+$', '')
  return M.truncate(name, 20)
end

-- Format file size
function M.format_size(size)
  if not size or size == 0 then return '0B' end
  
  local units = {'B', 'KB', 'MB', 'GB'}
  local unit_index = 1
  local formatted_size = tonumber(size) or 0
  
  while formatted_size >= 1024 and unit_index < #units do
    formatted_size = formatted_size / 1024
    unit_index = unit_index + 1
  end
  
  if unit_index == 1 then
    return string.format('%dB', formatted_size)
  else
    return string.format('%.1f%s', formatted_size, units[unit_index])
  end
end

-- Template string interpolation
function M.template(str, vars)
  return (str:gsub("${([^}]+)}", function(key)
    return tostring(vars[key] or "")
  end))
end

-- Convert to human-readable size (alias for format_size)
function M.human_size(bytes)
  return M.format_size(bytes)
end

-- Time ago formatter
function M.time_ago(timestamp)
  local now = os.time()
  local diff = now - timestamp
  
  if diff < 60 then
    return "just now"
  elseif diff < 3600 then
    local minutes = math.floor(diff / 60)
    return string.format("%d minute%s ago", minutes, minutes == 1 and "" or "s")
  elseif diff < 86400 then
    local hours = math.floor(diff / 3600)
    return string.format("%d hour%s ago", hours, hours == 1 and "" or "s")
  elseif diff < 86400 * 7 then
    local days = math.floor(diff / 86400)
    return string.format("%d day%s ago", days, days == 1 and "" or "s")
  elseif diff < 86400 * 30 then
    local weeks = math.floor(diff / (86400 * 7))
    return string.format("%d week%s ago", weeks, weeks == 1 and "" or "s")
  else
    local months = math.floor(diff / (86400 * 30))
    return string.format("%d month%s ago", months, months == 1 and "" or "s")
  end
end

-- Escape special characters for shell
function M.shell_escape(str)
  if not str then return '' end
  -- Escape single quotes by replacing them with '\''
  return "'" .. str:gsub("'", "'\\''") .. "'"
end

-- Remove ANSI color codes
function M.strip_ansi(str)
  if not str then return '' end
  return str:gsub('\27%[[0-9;]*m', '')
end

-- Pad string to specified length
function M.pad_right(str, len, char)
  char = char or ' '
  local str_len = #str
  if str_len >= len then
    return str
  end
  return str .. string.rep(char, len - str_len)
end

-- Pad string to specified length (left)
function M.pad_left(str, len, char)
  char = char or ' '
  local str_len = #str
  if str_len >= len then
    return str
  end
  return string.rep(char, len - str_len) .. str
end

-- Split string by delimiter
function M.split(str, delimiter)
  delimiter = delimiter or ','
  local result = {}
  local pattern = string.format("([^%s]+)", delimiter)
  
  for match in str:gmatch(pattern) do
    table.insert(result, match)
  end
  
  return result
end

-- Join strings with delimiter
function M.join(tbl, delimiter)
  delimiter = delimiter or ', '
  return table.concat(tbl, delimiter)
end

-- Trim whitespace from string
function M.trim(str)
  if not str then return '' end
  return str:match("^%s*(.-)%s*$")
end

-- Capitalize first letter
function M.capitalize(str)
  if not str or #str == 0 then return str end
  return str:sub(1, 1):upper() .. str:sub(2)
end

-- Convert to title case
function M.title_case(str)
  return str:gsub("(%a)([%w_']*)", function(first, rest)
    return first:upper() .. rest:lower()
  end)
end

return M