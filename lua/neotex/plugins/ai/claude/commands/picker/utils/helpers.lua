-- neotex.plugins.ai.claude.commands.picker.utils.helpers
-- General helper utilities for picker module

local M = {}

--- Get file permissions in rwx format
--- @param filepath string Path to file
--- @return string|nil Permissions string (rwxr-xr-x format) or nil if file doesn't exist
function M.get_file_permissions(filepath)
  local perms = vim.fn.getfperm(filepath)
  if perms == "" then
    return nil
  end
  return perms
end

--- Set file permissions
--- @param filepath string Path to file
--- @param permissions string Permissions string (rwxr-xr-x format)
--- @return boolean Success status
function M.set_file_permissions(filepath, permissions)
  if not permissions or permissions == "" then
    return false
  end
  return vim.fn.setfperm(filepath, permissions) == 1
end

--- Copy file permissions from source to destination
--- @param src string Source file path
--- @param dest string Destination file path
--- @return boolean Success status
function M.copy_file_permissions(src, dest)
  local perms = M.get_file_permissions(src)
  if not perms then
    return false
  end
  return M.set_file_permissions(dest, perms)
end

--- Check if file exists and is readable
--- @param filepath string Path to file
--- @return boolean True if file exists and is readable
function M.is_file_readable(filepath)
  return filepath and vim.fn.filereadable(filepath) == 1
end

--- Read file contents
--- @param filepath string Path to file
--- @param max_lines number|nil Maximum number of lines to read (nil for all)
--- @return table|nil Array of lines or nil on error
function M.read_file(filepath, max_lines)
  if not M.is_file_readable(filepath) then
    return nil
  end

  local success, lines
  if max_lines then
    success, lines = pcall(vim.fn.readfile, filepath, "", max_lines)
  else
    success, lines = pcall(vim.fn.readfile, filepath)
  end

  return success and lines or nil
end

--- Write file contents
--- @param filepath string Path to file
--- @param lines table Array of lines to write
--- @return boolean Success status
function M.write_file(filepath, lines)
  local success = pcall(vim.fn.writefile, lines, filepath)
  return success
end

--- Create directory if it doesn't exist
--- @param dir string Directory path
--- @return boolean Success status
function M.ensure_directory(dir)
  if vim.fn.isdirectory(dir) == 1 then
    return true
  end
  return vim.fn.mkdir(dir, "p") == 1
end

--- Get filename from path
--- @param filepath string Full file path
--- @return string Filename (without directory)
function M.get_filename(filepath)
  return vim.fn.fnamemodify(filepath, ":t")
end

--- Get filename without extension
--- @param filepath string Full file path
--- @return string Filename without extension
function M.get_filename_stem(filepath)
  return vim.fn.fnamemodify(filepath, ":t:r")
end

--- Get file extension
--- @param filepath string Full file path
--- @return string File extension (including dot, e.g., ".md")
function M.get_extension(filepath)
  return vim.fn.fnamemodify(filepath, ":e")
end

--- Send notification using neotex notification system
--- @param message string Notification message
--- @param level string Notification level ("INFO", "WARN", "ERROR")
function M.notify(message, level)
  local notify = require("neotex.util.notifications")
  local category = notify.categories[level] or notify.categories.INFO
  notify.editor(message, category)
end

--- Format display string with consistent spacing
--- @param prefix string Prefix character (e.g., "*" for local)
--- @param indent string Indent string (e.g., " ├─")
--- @param name string Artifact name
--- @param description string Description text
--- @param name_width number Width for name column (default 38)
--- @return string Formatted display string
function M.format_display(prefix, indent, name, description, name_width)
  name_width = name_width or 38
  return string.format(
    "%s%s %-" .. name_width .. "s %s",
    prefix,
    indent,
    name,
    description or ""
  )
end

--- Get tree character based on position
--- @param is_last boolean True if this is the last item in a list
--- @return string Tree character ("└─" for last, "├─" otherwise)
function M.get_tree_char(is_last)
  return is_last and "└─" or "├─"
end

--- Truncate string to maximum length
--- @param str string String to truncate
--- @param max_len number Maximum length
--- @return string Truncated string
function M.truncate(str, max_len)
  if not str then
    return ""
  end
  return str:sub(1, max_len)
end

--- Strip surrounding quotes from string
--- @param str string String that may have quotes
--- @return string String without surrounding quotes
function M.strip_quotes(str)
  if not str then
    return ""
  end
  -- Strip double quotes
  str = str:gsub('^"(.-)"$', '%1')
  -- Strip single quotes
  str = str:gsub("^'(.-)'$", '%1')
  return str
end

return M
