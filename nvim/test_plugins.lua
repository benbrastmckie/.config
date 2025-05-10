-- Test script to verify successful reorganization of plugin loading
-- This should be run with: nvim -u /home/benjamin/.config/nvim/init.lua --cmd "source /home/benjamin/.config/nvim/test_plugins.lua"

local function count_plugins()
  -- Get the count of loaded plugins from lazy.nvim
  local lazy_ok, lazy = pcall(require, "lazy")
  if not lazy_ok then
    print("❌ Lazy.nvim not loaded")
    return 0
  end
  
  local plugins = lazy.plugins()
  local count = 0
  for _ in pairs(plugins) do
    count = count + 1
  end
  
  return count
end

local function check_plugin(plugin_name)
  -- Check if a specific plugin is loaded
  local lazy_ok, lazy = pcall(require, "lazy")
  if not lazy_ok then
    print("❌ Lazy.nvim not loaded")
    return false
  end
  
  local plugins = lazy.plugins()
  
  for _, plugin in pairs(plugins) do
    if plugin.name == plugin_name then
      print("✓ Plugin " .. plugin_name .. " is loaded")
      return true
    end
  end
  
  print("❌ Plugin " .. plugin_name .. " is not loaded")
  return false
end

-- Create a message to display when testing is done
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      print("\n=== Plugin Loading Test Results ===")
      
      -- Count loaded plugins
      local plugin_count = count_plugins()
      print("\nTotal plugins loaded: " .. plugin_count)
      
      -- Check some key plugins to verify they loaded correctly
      print("\nChecking key plugins:")
      check_plugin("telescope.nvim")
      check_plugin("nvim-treesitter")
      check_plugin("gitsigns.nvim")
      check_plugin("which-key.nvim")
      check_plugin("mini.nvim")
      
      print("\nNote: You should see approximately the same number of plugins loaded")
      print("as with the original configuration. If the count is significantly lower,")
      print("it could indicate an issue with the new plugin loading structure.\n")
      
      print("You can now exit Neovim with :q\n")
    end, 2000)
  end,
  once = true
})