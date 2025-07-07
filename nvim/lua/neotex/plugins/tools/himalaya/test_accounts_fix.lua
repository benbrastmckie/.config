-- Quick test for accounts fix
local M = {}

function M.test()
  print("Testing accounts fix...")
  
  -- Test adding account
  local accounts = require('neotex.plugins.tools.himalaya.features.accounts')
  local test_account = {
    name = 'test_fix',
    email = 'test@example.com',
    type = 'imap'
  }
  
  local result = accounts.add_account(test_account)
  
  if result.success then
    print("✓ Account added successfully")
    
    -- Test getting all accounts
    local all = accounts.get_all_accounts()
    if all.test_fix then
      print("✓ Account retrieved successfully")
    else
      print("✗ Failed to retrieve account")
    end
    
    -- Clean up
    accounts.remove_account('test_fix')
    print("✓ Account removed")
  else
    print("✗ Failed to add account:", vim.inspect(result.error))
  end
  
  print("Test complete!")
end

return M