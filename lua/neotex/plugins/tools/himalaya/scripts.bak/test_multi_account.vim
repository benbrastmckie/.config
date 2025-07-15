" Test script for Multi-Account Views
" Run with: nvim -u NONE -S test_multi_account.vim

" Source minimal init
set runtimepath+=/home/benjamin/.config/nvim

" Test the multi-account functionality
lua << EOF
-- Add paths
package.path = package.path .. ";/home/benjamin/.config/nvim/lua/?.lua"

-- Simple test function
local function test_multi_account()
  print("Testing Multi-Account Views")
  print("=" .. string.rep("=", 50))
  
  -- Load multi-account module
  local ok, multi_account = pcall(require, 'neotex.plugins.tools.himalaya.ui.multi_account')
  if not ok then
    print("❌ Failed to load multi_account: " .. tostring(multi_account))
    return
  end
  
  print("✅ Multi-account module loaded successfully")
  
  -- Test basic properties
  print("\nChecking view modes:")
  for name, mode in pairs(multi_account.modes) do
    print("  - " .. name .. ": " .. mode)
  end
  
  -- Test initialization
  print("\nTesting initialization...")
  local ok2, err = pcall(multi_account.setup)
  if ok2 then
    print("✅ Multi-account setup successful")
    print("  - Active accounts: " .. vim.tbl_count(multi_account.state.active_accounts))
    print("  - Current mode: " .. multi_account.state.mode)
  else
    print("❌ Setup failed: " .. tostring(err))
  end
  
  -- Test account color generation
  print("\nTesting account colors...")
  local colors = multi_account.generate_account_colors()
  print("✅ Generated colors for " .. vim.tbl_count(colors) .. " accounts")
  
  -- Test mode functions
  print("\nTesting mode functions...")
  local modes_ok = true
  for _, mode in pairs(multi_account.modes) do
    local ok3, err3 = pcall(multi_account.create_view, mode)
    if not ok3 then
      print("❌ Failed to create " .. mode .. " view: " .. tostring(err3))
      modes_ok = false
    end
  end
  
  if modes_ok then
    print("✅ All view modes can be created")
  end
  
  print("\n✅ Multi-Account Views tests completed!")
end

-- Run test
test_multi_account()
EOF

" Exit
quit!