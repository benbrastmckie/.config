-- Test script to verify successful migration of utilities
-- This should be run with: nvim -u /home/benjamin/.config/nvim/init.lua --cmd "source /home/benjamin/.config/nvim/test_utils.lua"

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

-- Helper to check if global function exists
local function check_global_function(func_name)
  if _G[func_name] ~= nil and type(_G[func_name]) == "function" then
    print("✓ Global function " .. func_name .. " is available")
  else
    print("✗ Global function " .. func_name .. " is missing")
  end
end

-- Verify utility modules
print("\nTesting new utility modules:")
check_module("neotex.utils")
check_module("neotex.utils.buffer")
check_module("neotex.utils.fold")
check_module("neotex.utils.url")
check_module("neotex.utils.diagnostics")
check_module("neotex.utils.misc")

-- Verify backward compatibility (global functions)
print("\nVerifying global function compatibility:")
check_global_function("GotoBuffer")
check_global_function("DisplayMessages")
check_global_function("MarkdownFoldLevel")
check_global_function("OpenUrlUnderCursor")
check_global_function("CopyDiagnosticsToClipboard")
check_global_function("ToggleFoldingMethod")
check_global_function("LoadFoldingState")
check_global_function("SetupUrlMappings")

-- Create a message to display when testing is done
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      print("\nIf no error messages appeared and Neovim started normally, the refactoring Batch 3 was successful.")
      print("You can now exit Neovim with :q\n")
    end, 1000)
  end,
  once = true
})