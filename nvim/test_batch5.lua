-- Test script for Batch 5 (URL Handling and Specialized Features)
-- Run with: nvim -u /home/benjamin/.config/nvim/init.lua --cmd "source /home/benjamin/.config/nvim/test_batch5.lua"

local function test_utils_loaded()
  print("\n=== Testing Utility Module Loading ===")
  log_to_file("\n=== Testing Utility Module Loading ===")
  
  -- Test loading of utils module
  local utils_ok, utils = pcall(require, "neotex.utils")
  if utils_ok and type(utils) == "table" then
    print("✓ Base utils module loaded successfully")
    log_to_file("✓ Base utils module loaded successfully")
  else
    print("❌ Failed to load base utils module")
    log_to_file("❌ Failed to load base utils module")
    return false
  end
  
  -- Test individual utility modules
  local modules = {
    "buffer",
    "fold",
    "url",
    "diagnostics",
    "misc"
  }
  
  local all_passed = true
  for _, module_name in ipairs(modules) do
    local module_ok, module = pcall(require, "neotex.utils." .. module_name)
    if module_ok and type(module) == "table" then
      print("✓ " .. module_name .. " module loaded successfully")
    else
      print("❌ Failed to load " .. module_name .. " module")
      all_passed = false
    end
  end
  
  return all_passed
end

local function test_buffer_functions()
  print("\n=== Testing Buffer Utility Functions ===")
  
  local buffer_ok, buffer = pcall(require, "neotex.utils.buffer")
  if not buffer_ok then
    print("❌ Failed to load buffer module")
    return false
  end
  
  -- Test that functions exist
  local functions = {
    "goto_buffer",
    "display_messages",
    "reload_config",
    "close_other_buffers",
    "close_unused_buffers",
    "save_all_buffers",
    "jump_to_alternate"
  }
  
  local all_passed = true
  for _, func_name in ipairs(functions) do
    if type(buffer[func_name]) == "function" then
      print("✓ " .. func_name .. " function exists")
    else
      print("❌ " .. func_name .. " function is missing")
      all_passed = false
    end
  end
  
  -- Test that commands exist
  local commands = {
    "ReloadConfig",
    "BufCloseOthers",
    "BufCloseUnused",
    "BufSaveAll"
  }
  
  for _, cmd_name in ipairs(commands) do
    local cmd_exists = pcall(vim.api.nvim_get_commands, {}, { [cmd_name] = true })
    if cmd_exists then
      print("✓ " .. cmd_name .. " command exists")
    else
      print("❌ " .. cmd_name .. " command is missing")
      all_passed = false
    end
  end
  
  return all_passed
end

local function test_misc_functions()
  print("\n=== Testing Miscellaneous Utility Functions ===")
  
  local misc_ok, misc = pcall(require, "neotex.utils.misc")
  if not misc_ok then
    print("❌ Failed to load misc module")
    return false
  end
  
  -- Test that functions exist
  local functions = {
    "get_os",
    "exists",
    "safe_execute",
    "defer",
    "log",
    "toggle_line_numbers",
    "trim_whitespace",
    "random_string",
    "get_visual_selection_info",
    "show_selection_info"
  }
  
  local all_passed = true
  for _, func_name in ipairs(functions) do
    if type(misc[func_name]) == "function" then
      print("✓ " .. func_name .. " function exists")
    else
      print("❌ " .. func_name .. " function is missing")
      all_passed = false
    end
  end
  
  -- Test that commands exist
  local commands = {
    "ToggleLineNumbers",
    "TrimWhitespace",
    "SelectionInfo"
  }
  
  for _, cmd_name in ipairs(commands) do
    local cmd_exists = pcall(vim.api.nvim_get_commands, {}, { [cmd_name] = true })
    if cmd_exists then
      print("✓ " .. cmd_name .. " command exists")
    else
      print("❌ " .. cmd_name .. " command is missing")
      all_passed = false
    end
  end
  
  -- Test random string generation
  local random_str = misc.random_string(10)
  if type(random_str) == "string" and #random_str == 10 then
    print("✓ random_string generates strings of correct length")
  else
    print("❌ random_string failed to generate a string of correct length")
    all_passed = false
  end
  
  return all_passed
end

local function test_url_functions()
  print("\n=== Testing URL Utility Functions ===")
  
  local url_ok, url = pcall(require, "neotex.utils.url")
  if not url_ok then
    print("❌ Failed to load url module")
    return false
  end
  
  -- Test that functions exist
  local functions = {
    "extract_urls_from_line",
    "open_url_at_position",
    "open_url_at_mouse",
    "open_url_under_cursor",
    "setup_url_mappings"
  }
  
  local all_passed = true
  for _, func_name in ipairs(functions) do
    if type(url[func_name]) == "function" then
      print("✓ " .. func_name .. " function exists")
    else
      print("❌ " .. func_name .. " function is missing")
      all_passed = false
    end
  end
  
  -- Test URL extraction
  local test_urls = {
    { line = "Check out https://neovim.io for more information", count = 1 },
    { line = "Email me at user@example.com for help", count = 1 },
    { line = "See [documentation](https://github.com/neovim/neovim)", count = 1 },
    { line = "No URLs here", count = 0 }
  }
  
  for _, test in ipairs(test_urls) do
    local extracted = url.extract_urls_from_line(test.line)
    if #extracted == test.count then
      print("✓ URL extraction works for: " .. test.line)
    else
      print("❌ URL extraction failed for: " .. test.line)
      all_passed = false
    end
  end
  
  -- Check that gx mapping is set up
  local gx_map = vim.fn.maparg("gx", "n")
  if gx_map ~= "" then
    print("✓ gx mapping is set up")
  else
    print("❌ gx mapping is not set up")
    all_passed = false
  end
  
  return all_passed
end

local function test_fold_functions()
  print("\n=== Testing Fold Utility Functions ===")
  
  local fold_ok, fold = pcall(require, "neotex.utils.fold")
  if not fold_ok then
    print("❌ Failed to load fold module")
    return false
  end
  
  -- Test that functions exist
  local functions = {
    "toggle_all_folds",
    "markdown_fold_level",
    "toggle_fold_enable",
    "toggle_folding_method",
    "load_folding_state"
  }
  
  local all_passed = true
  for _, func_name in ipairs(functions) do
    if type(fold[func_name]) == "function" then
      print("✓ " .. func_name .. " function exists")
    else
      print("❌ " .. func_name .. " function is missing")
      all_passed = false
    end
  end
  
  -- Check that global functions exist
  local global_funcs = {
    "ToggleAllFolds",
    "MarkdownFoldLevel",
    "ToggleFoldingMethod",
    "LoadFoldingState"
  }
  
  for _, func_name in ipairs(global_funcs) do
    if type(_G[func_name]) == "function" then
      print("✓ Global " .. func_name .. " function exists")
    else
      print("❌ Global " .. func_name .. " function is missing")
    end
  end
  
  return all_passed
end

-- Log the results to a file for headless testing
local function log_to_file(msg)
  local log_path = vim.fn.stdpath("config") .. "/test_batch5_results.log"
  local f = io.open(log_path, "a")
  if f then
    f:write(msg .. "\n")
    f:close()
  end
end

-- Clear the log file
io.open(vim.fn.stdpath("config") .. "/test_batch5_results.log", "w"):close()

-- Create a message to display when testing is done
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      -- Also log results to file
      log_to_file("=== Batch 5 Testing Results ===")
      print("\n=== Batch 5 Testing Results ===")
      log_to_file("\n=== Batch 5 Testing Results ===")
      
      local utils_passed = test_utils_loaded()
      local buffer_passed = test_buffer_functions()
      local misc_passed = test_misc_functions()
      local url_passed = test_url_functions()
      local fold_passed = test_fold_functions()
      
      print("\n=== Overall Test Results ===")
      log_to_file("\n=== Overall Test Results ===")
      
      if utils_passed then
        print("✓ Utility module loading tests passed")
        log_to_file("✓ Utility module loading tests passed")
      else
        print("❌ Utility module loading tests failed")
        log_to_file("❌ Utility module loading tests failed")
      end
      
      if buffer_passed then
        print("✓ Buffer utility tests passed")
        log_to_file("✓ Buffer utility tests passed")
      else
        print("❌ Buffer utility tests failed")
        log_to_file("❌ Buffer utility tests failed")
      end
      
      if misc_passed then
        print("✓ Miscellaneous utility tests passed")
        log_to_file("✓ Miscellaneous utility tests passed")
      else
        print("❌ Miscellaneous utility tests failed")
        log_to_file("❌ Miscellaneous utility tests failed")
      end
      
      if url_passed then
        print("✓ URL utility tests passed")
        log_to_file("✓ URL utility tests passed")
      else
        print("❌ URL utility tests failed")
        log_to_file("❌ URL utility tests failed")
      end
      
      if fold_passed then
        print("✓ Fold utility tests passed")
        log_to_file("✓ Fold utility tests passed")
      else
        print("❌ Fold utility tests failed")
        log_to_file("❌ Fold utility tests failed")
      end
      
      local all_passed = utils_passed and buffer_passed and misc_passed and url_passed and fold_passed
      
      if all_passed then
        print("\n=== All tests passed successfully! Batch 5 implementation complete. ===")
        log_to_file("\n=== All tests passed successfully! Batch 5 implementation complete. ===")
      else
        print("\n=== Some tests failed. Please review the output above for details. ===")
        log_to_file("\n=== Some tests failed. Please review the output above for details. ===")
      end
      
      print("\nYou can now exit Neovim with :q\n")
      log_to_file("\nTest completed at: " .. os.date())
    end, 500)
  end,
  once = true
})