-- Minimal treesitter error recovery for "out of range" errors
-- This file loads after all plugins to ensure proper setup

-- Only proceed if treesitter is available
if not pcall(require, "nvim-treesitter") then
  return
end

-- Store original notify to intercept specific errors
local original_notify = vim.notify

-- Create a debounced parser reset function
local reset_timers = {}
local function debounced_parser_reset(bufnr)
  -- Cancel existing timer for this buffer
  if reset_timers[bufnr] then
    vim.fn.timer_stop(reset_timers[bufnr])
  end
  
  -- Set new timer
  reset_timers[bufnr] = vim.fn.timer_start(100, function()
    reset_timers[bufnr] = nil
    if vim.api.nvim_buf_is_valid(bufnr) then
      local parser = vim.treesitter.get_parser(bufnr)
      if parser then
        pcall(function() parser:invalidate() end)
      end
    end
  end)
end

-- Override vim.notify to catch specific treesitter errors
vim.notify = function(msg, level, opts)
  if type(msg) == "string" and msg:match("Error in decoration provider") and msg:match("out of range") then
    -- Extract buffer number if possible, otherwise use current
    local bufnr = vim.api.nvim_get_current_buf()
    
    -- Schedule parser reset
    vim.schedule(function()
      debounced_parser_reset(bufnr)
    end)
    
    -- Downgrade to debug level
    level = vim.log.levels.DEBUG
  end
  
  return original_notify(msg, level, opts)
end

-- Cleanup timers on buffer delete
vim.api.nvim_create_autocmd("BufDelete", {
  callback = function(ev)
    if reset_timers[ev.buf] then
      vim.fn.timer_stop(reset_timers[ev.buf])
      reset_timers[ev.buf] = nil
    end
  end,
  desc = "Cleanup treesitter reset timers"
})