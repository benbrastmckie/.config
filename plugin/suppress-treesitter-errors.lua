-- Suppress specific treesitter highlighter errors
-- This is a targeted fix for the "Invalid 'end_col': out of range" error

-- Store the original vim.notify
local original_notify = vim.notify

-- Override vim.notify to filter out specific treesitter errors
vim.notify = function(msg, level, opts)
  -- Check if this is the specific treesitter error we want to suppress
  if type(msg) == "string" and msg:match("Error in decoration provider") and msg:match("out of range") then
    -- Log it at debug level instead of error level
    if level == vim.log.levels.ERROR then
      level = vim.log.levels.DEBUG
    end
  end
  
  -- Call the original notify
  return original_notify(msg, level, opts)
end