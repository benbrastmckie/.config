-- Autolist utilities module
local M = {}

-- Detect if a line is a list item
function M.is_list_item(line)
  local list_types = {"-", "*", "+", "%d%."}
  
  for _, pattern in ipairs(list_types) do
    if line:match("^%s*" .. pattern .. "%s") then
      return true
    end
  end
  
  return false
end

-- Suppress notifications for specific operations
function M.silent_exec(func)
  -- Save previous notification function
  local old_notify = vim.notify
  -- Create temporary notification function that filters out autolist messages
  vim.notify = function(msg, level, opts)
    if not msg:match("recalculate") and not msg:match("indent") then
      old_notify(msg, level, opts)
    end
  end
  
  -- Execute the function with pcall and get status and result
  local status, result = pcall(func)
  
  -- Restore original notification function
  vim.notify = old_notify
  
  return status, result
end

-- Close completion menu and prevent reopening
function M.close_completion_menu(delay)
  delay = delay or 1000
  
  pcall(function()
    local cmp = require('cmp')
    if cmp and cmp.visible() then
      cmp.close()
    end
  end)
  
  -- Set flag to prevent cmp menu from reopening right away
  _G._prevent_cmp_menu = true
  
  -- Clear the prevent_cmp_menu flag after a delay
  vim.defer_fn(function()
    _G._prevent_cmp_menu = false
  end, delay)
  
  -- Add a final close at the very end
  vim.defer_fn(function()
    pcall(function()
      local cmp = require('cmp')
      if cmp and cmp.visible() then
        cmp.close()
      end
    end)
  end, 50)
end

return M