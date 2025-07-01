-- Test baseline functionality before refactoring
-- Run this in Neovim to verify commands work

local function test_commands()
  local results = {}
  
  -- Test if Himalaya loads
  local ok, himalaya = pcall(require, 'neotex.plugins.tools.himalaya')
  results.module_loads = ok
  
  -- Test if UI module loads
  local ok2, ui = pcall(require, 'neotex.plugins.tools.himalaya.ui')
  results.ui_loads = ok2
  
  -- Test if main UI module loads
  local ok3, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
  results.main_loads = ok3
  
  -- Print results
  print("Test Results:")
  print("- Module loads: " .. tostring(results.module_loads))
  print("- UI loads: " .. tostring(results.ui_loads))
  print("- Main UI loads: " .. tostring(results.main_loads))
  
  return results
end

return test_commands()