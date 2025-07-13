-- Test script to verify local_storage removal fixes

local M = {}

function M.test()
  print("Testing local_storage removal fixes...")
  
  -- Test 1: Can we load email_preview?
  local ok1, email_preview = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_preview')
  if ok1 then
    print("✓ email_preview loads successfully")
  else
    print("✗ email_preview failed to load: " .. tostring(email_preview))
  end
  
  -- Test 2: Can we load main UI?
  local ok2, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
  if ok2 then
    print("✓ main UI loads successfully")
  else
    print("✗ main UI failed to load: " .. tostring(main))
  end
  
  -- Test 3: Can we load utils?
  local ok3, utils = pcall(require, 'neotex.plugins.tools.himalaya.utils')
  if ok3 then
    print("✓ utils loads successfully")
  else
    print("✗ utils failed to load: " .. tostring(utils))
  end
  
  -- Test 4: Can we initialize the plugin?
  local ok4, himalaya = pcall(require, 'neotex.plugins.tools.himalaya')
  if ok4 then
    print("✓ himalaya plugin loads successfully")
    
    -- Try to setup
    local ok5, err = pcall(function()
      himalaya.setup({})
    end)
    
    if ok5 then
      print("✓ himalaya setup completed successfully")
    else
      print("✗ himalaya setup failed: " .. tostring(err))
    end
  else
    print("✗ himalaya plugin failed to load: " .. tostring(himalaya))
  end
  
  return ok1 and ok2 and ok3 and ok4
end

return M