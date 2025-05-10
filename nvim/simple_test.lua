-- Simple test script that just loads modules and outputs results
print("Testing utility modules loading")

-- Test main utils module
local utils_ok, utils = pcall(require, "neotex.utils")
print("Main utils module loaded: " .. tostring(utils_ok))

-- Test individual modules
local modules = {
  "buffer", 
  "fold", 
  "url", 
  "diagnostics", 
  "misc"
}

for _, module_name in ipairs(modules) do
  local ok, mod = pcall(require, "neotex.utils." .. module_name)
  print(module_name .. " module loaded: " .. tostring(ok))
  
  -- Check a few key functions in each module
  if ok then
    if module_name == "buffer" then
      print("  buffer.reload_config exists: " .. tostring(type(mod.reload_config) == "function"))
      print("  buffer.close_other_buffers exists: " .. tostring(type(mod.close_other_buffers) == "function"))
    elseif module_name == "misc" then
      print("  misc.toggle_line_numbers exists: " .. tostring(type(mod.toggle_line_numbers) == "function"))
      print("  misc.trim_whitespace exists: " .. tostring(type(mod.trim_whitespace) == "function"))
    elseif module_name == "url" then
      print("  url.open_url_under_cursor exists: " .. tostring(type(mod.open_url_under_cursor) == "function"))
    elseif module_name == "fold" then
      print("  fold.toggle_all_folds exists: " .. tostring(type(mod.toggle_all_folds) == "function"))
    end
  end
end

-- Test whether initialization worked: check for global functions
print("\nTesting global function availability:")
print("ToggleLineNumbers exists: " .. tostring(type(_G.ToggleLineNumbers) == "function"))
print("TrimWhitespace exists: " .. tostring(type(_G.TrimWhitespace) == "function"))
print("GotoBuffer exists: " .. tostring(type(_G.GotoBuffer) == "function"))
print("ToggleAllFolds exists: " .. tostring(type(_G.ToggleAllFolds) == "function"))
print("OpenUrlUnderCursor exists: " .. tostring(type(_G.OpenUrlUnderCursor) == "function"))

-- Check if user commands are defined
local function command_exists(cmd_name)
  local ok = pcall(vim.api.nvim_get_commands, {}, { [cmd_name] = true })
  return ok
end

print("\nTesting command availability:")
print("ReloadConfig command exists: " .. tostring(command_exists("ReloadConfig")))
print("BufCloseOthers command exists: " .. tostring(command_exists("BufCloseOthers")))
print("BufCloseUnused command exists: " .. tostring(command_exists("BufCloseUnused")))
print("TrimWhitespace command exists: " .. tostring(command_exists("TrimWhitespace")))
print("ToggleLineNumbers command exists: " .. tostring(command_exists("ToggleLineNumbers")))

-- Exit
vim.cmd('qa!')