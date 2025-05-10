-- Test script to verify successful migration of configuration
-- This should be run with: nvim -u /home/benjamin/.config/nvim/init.lua --cmd "source /home/benjamin/.config/nvim/test_configs.lua"

local function check_module(module_name)
  local ok, mod = pcall(require, module_name)
  if ok then
    print("✓ Module " .. module_name .. " loaded successfully")
    if type(mod) == "table" and type(mod.setup) == "function" then
      local setup_ok, _ = pcall(mod.setup)
      if setup_ok then
        print("  ✓ Setup function executed successfully")
      else
        print("  ✗ Setup function failed")
      end
    end
  else
    print("✗ Failed to load module: " .. module_name)
  end
end

-- Verify new configuration modules
print("\nTesting new configuration modules:")
check_module("neotex.config")
check_module("neotex.config.options")
check_module("neotex.config.keymaps")
check_module("neotex.config.autocmds")

-- Verify that old modules still work (for backward compatibility)
print("\nVerifying backward compatibility:")
check_module("neotex.core")
check_module("neotex.core.options")
check_module("neotex.core.keymaps")
check_module("neotex.core.autocmds")

-- Create a message to display when testing is done
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      print("\nIf no error messages appeared and Neovim started normally, the refactoring Batch 2 was successful.")
      print("Check that keymaps work as expected.")
      print("You can now exit Neovim with :q\n")
    end, 1000)
  end,
  once = true
})