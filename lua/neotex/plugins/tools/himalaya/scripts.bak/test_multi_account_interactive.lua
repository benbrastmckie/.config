-- Interactive test script for Multiple Account Views
-- Run this after opening Neovim with: :luafile %

local function test_multi_account()
  print("=== Multiple Account Views Interactive Test ===")
  print("")
  
  -- Check if plugin is loaded
  local himalaya_ok = pcall(require, 'neotex.plugins.tools.himalaya')
  if not himalaya_ok then
    print("❌ Himalaya plugin not loaded. Run :HimalayaSetup first")
    return
  end
  
  -- Check account status
  print("1. Checking account configuration...")
  vim.cmd('HimalayaAccountStatus')
  vim.defer_fn(function()
    print("   ✓ Account status displayed")
    print("")
    
    -- Test each view mode
    print("2. Testing view modes (watch for changes)...")
    
    -- Focused view
    print("   - Testing Focused View...")
    vim.cmd('HimalayaFocusedView')
    vim.defer_fn(function()
      print("   ✓ Focused view loaded")
      
      -- Unified inbox
      print("   - Testing Unified Inbox...")
      vim.cmd('HimalayaUnifiedInbox')
      vim.defer_fn(function()
        print("   ✓ Unified inbox loaded")
        print("     Check: Do you see emails from all accounts?")
        print("     Check: Are account prefixes visible? e.g., [GMA]")
        
        -- Split view
        print("   - Testing Split View...")
        vim.cmd('HimalayaSplitView')
        vim.defer_fn(function()
          print("   ✓ Split view loaded")
          print("     Check: Are accounts shown side by side?")
          
          -- Tabbed view
          print("   - Testing Tabbed View...")
          vim.cmd('HimalayaTabbedView')
          vim.defer_fn(function()
            print("   ✓ Tabbed view loaded")
            print("     Check: Do you see tabs for each account?")
            
            -- Test navigation
            print("")
            print("3. Testing navigation commands...")
            print("   - Try :HimalayaNextAccount")
            print("   - Try :HimalayaPreviousAccount")
            print("   - Try :HimalayaToggleView")
            print("")
            print("=== Test Complete ===")
            print("See docs/MULTIPLE_ACCOUNT_VIEWS.md for detailed testing steps")
          end, 2000)
        end, 2000)
      end, 2000)
    end, 2000)
  end, 1000)
end

-- Add command for easy testing
vim.api.nvim_create_user_command('TestMultiAccount', test_multi_account, {
  desc = 'Test Multiple Account Views interactively'
})

print("Multiple Account Views Test Loaded!")
print("Run :TestMultiAccount to start the interactive test")
print("Or run: :lua test_multi_account()")

-- Export for direct calling
_G.test_multi_account = test_multi_account