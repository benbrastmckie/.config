-- Autolist commands module
local M = {}
local operations = require("neotex.plugins.tools.autolist.util.list_operations")

function M.setup()
  -- Define user commands for list operations
  vim.api.nvim_create_user_command('AutolistIndent', function()
    operations.indent_list_item()
  end, {})
  
  vim.api.nvim_create_user_command('AutolistUnindent', function()
    operations.unindent_list_item()
  end, {})
  
  vim.api.nvim_create_user_command('AutolistRecalculate', function()
    operations.recalculate_list()
  end, {})
  
  vim.api.nvim_create_user_command('AutolistCycleNext', function()
    operations.cycle_next()
  end, {})
  
  vim.api.nvim_create_user_command('AutolistCyclePrev', function()
    operations.cycle_prev()
  end, {})
  
  vim.api.nvim_create_user_command('AutolistIncrementCheckbox', function()
    operations.toggle_checkbox()
  end, {})
  
  vim.api.nvim_create_user_command('AutolistDecrementCheckbox', function()
    operations.toggle_checkbox_reverse()
  end, {})
  
  -- Compatibility with autolist.nvim built-in commands
  vim.api.nvim_create_user_command('AutolistNewBullet', function()
    local auto = require("autolist.auto")
    if auto and auto.new_bullet then
      auto.new_bullet()
    end
  end, {})
  
  vim.api.nvim_create_user_command('AutolistNewBulletBefore', function()
    local auto = require("autolist.auto")
    if auto and auto.new_bullet_before then
      auto.new_bullet_before()
    end
  end, {})
  
  -- Debugging command
  vim.api.nvim_create_user_command('DebugMappings', function()
    local modes = {'i', 'n', 'v'}
    local keys = {'<Tab>', '<S-Tab>', '<C-D>'}
    
    for _, mode in ipairs(modes) do
      for _, key in ipairs(keys) do
        print(string.format("Mode: %s, Key: %s", mode, key))
        vim.cmd(string.format("verbose %smap %s", mode, key))
        print("---")
      end
    end
  end, {})
  
  -- Define global functions for backward compatibility
  _G.IncrementCheckbox = operations.toggle_checkbox
  _G.DecrementCheckbox = operations.toggle_checkbox_reverse
end

return M