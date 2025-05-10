-- Test script to verify successful refactoring changes
-- This should be run with: nvim -u /home/benjamin/.config/nvim/init.lua --cmd "source /home/benjamin/.config/nvim/test_changes.lua"

local function check_module(module_name)
  local ok, _ = pcall(require, module_name)
  if ok then
    print("✓ Module " .. module_name .. " loaded successfully")
  else
    print("✗ Failed to load module: " .. module_name)
  end
end

-- Verify that core modules still work
check_module("neotex.core")
check_module("neotex.core.options")
check_module("neotex.core.keymaps")
check_module("neotex.core.autocmds")
check_module("neotex.core.functions")

-- Verify new modules
check_module("neotex.utils")
check_module("neotex.config")

-- Create a message to display when testing is done
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      print("\nIf no error messages appeared and Neovim started normally, the refactoring Batch 1 was successful.")
      print("You can now exit Neovim with :q\n")
    end, 1000)
  end,
  once = true
})