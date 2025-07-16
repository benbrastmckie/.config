-- File Utilities for Himalaya
-- File operations and path utilities

local M = {}

local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Ensure directory exists
function M.ensure_dir(path)
  local dir = vim.fn.fnamemodify(path, ':h')
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, 'p')
    logger.debug('Created directory', { path = dir })
  end
end

-- Read file contents
function M.read_file(path)
  local f = io.open(path, 'r')
  if not f then
    return nil, 'Failed to open file: ' .. path
  end
  
  local content = f:read('*all')
  f:close()
  
  return content
end

-- Write file contents
function M.write_file(path, content)
  M.ensure_dir(path)
  
  local f = io.open(path, 'w')
  if not f then
    return false, 'Failed to open file for writing: ' .. path
  end
  
  f:write(content)
  f:close()
  
  return true
end

-- Append to file
function M.append_file(path, content)
  M.ensure_dir(path)
  
  local f = io.open(path, 'a')
  if not f then
    return false, 'Failed to open file for appending: ' .. path
  end
  
  f:write(content)
  f:close()
  
  return true
end

-- Check if file exists
function M.exists(path)
  return vim.fn.filereadable(path) == 1
end

-- Check if directory exists
function M.is_dir(path)
  return vim.fn.isdirectory(path) == 1
end

-- Get file modification time
function M.mtime(path)
  local stat = vim.loop.fs_stat(path)
  if stat then
    return stat.mtime.sec
  end
  return nil
end

-- Get file size
function M.size(path)
  local stat = vim.loop.fs_stat(path)
  if stat then
    return stat.size
  end
  return 0
end

-- List files in directory
function M.list_dir(path, filter)
  local files = {}
  
  local handle = vim.loop.fs_scandir(path)
  if not handle then
    return files
  end
  
  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then break end
    
    if not filter or filter(name, type) then
      table.insert(files, {
        name = name,
        type = type,
        path = path .. '/' .. name
      })
    end
  end
  
  return files
end

-- List files recursively
function M.list_dir_recursive(path, filter, max_depth)
  max_depth = max_depth or 10
  local files = {}
  
  local function scan(dir, depth)
    if depth > max_depth then return end
    
    local items = M.list_dir(dir, filter)
    for _, item in ipairs(items) do
      table.insert(files, item)
      
      if item.type == 'directory' then
        scan(item.path, depth + 1)
      end
    end
  end
  
  scan(path, 1)
  return files
end

-- Copy file
function M.copy_file(src, dest)
  local content, err = M.read_file(src)
  if not content then
    return false, err
  end
  
  return M.write_file(dest, content)
end

-- Move file
function M.move_file(src, dest)
  -- Try rename first
  local ok = os.rename(src, dest)
  if ok then
    return true
  end
  
  -- Fall back to copy and delete
  local copy_ok, err = M.copy_file(src, dest)
  if not copy_ok then
    return false, err
  end
  
  os.remove(src)
  return true
end

-- Delete file
function M.delete_file(path)
  return os.remove(path) ~= nil
end

-- Create temporary file
function M.temp_file(prefix, suffix)
  prefix = prefix or 'himalaya'
  suffix = suffix or '.tmp'
  
  local tmpdir = vim.fn.tempname()
  vim.fn.mkdir(tmpdir, 'p')
  
  local path = tmpdir .. '/' .. prefix .. '_' .. os.time() .. suffix
  return path
end

-- Get home directory
function M.home()
  return vim.fn.expand('~')
end

-- Expand path (handle ~ and environment variables)
function M.expand(path)
  return vim.fn.expand(path)
end

-- Join path components
function M.join(...)
  local parts = {...}
  return table.concat(parts, '/')
end

-- Get directory name from path
function M.dirname(path)
  return vim.fn.fnamemodify(path, ':h')
end

-- Get base name from path
function M.basename(path)
  return vim.fn.fnamemodify(path, ':t')
end

-- Get file extension
function M.extension(path)
  return vim.fn.fnamemodify(path, ':e')
end

-- Remove file extension
function M.remove_extension(path)
  return vim.fn.fnamemodify(path, ':r')
end

-- Make path relative to base
function M.relative(path, base)
  -- Normalize paths
  path = vim.fn.fnamemodify(path, ':p')
  base = vim.fn.fnamemodify(base, ':p')
  
  -- Find common prefix
  local i = 1
  while i <= #path and i <= #base and path:sub(i, i) == base:sub(i, i) do
    i = i + 1
  end
  
  -- Build relative path
  local relative = path:sub(i)
  
  -- Count directories to go up
  local up_count = 0
  for _ in base:sub(i):gmatch('/') do
    up_count = up_count + 1
  end
  
  -- Build final path
  if up_count > 0 then
    relative = string.rep('../', up_count) .. relative
  end
  
  return relative
end

-- Find files matching pattern
function M.glob(pattern)
  return vim.fn.glob(pattern, false, true)
end

-- Check if path is absolute
function M.is_absolute(path)
  return path:sub(1, 1) == '/' or path:sub(1, 1) == '~'
end

-- Normalize path (resolve . and ..)
function M.normalize(path)
  return vim.fn.fnamemodify(path, ':p')
end

return M