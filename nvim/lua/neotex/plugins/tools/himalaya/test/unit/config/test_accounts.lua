-- Unit tests for accounts configuration module

local test_framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local accounts = require('neotex.plugins.tools.himalaya.config.accounts')

local M = {}

-- Test module initialization
function M.test_init()
  local config = {
    accounts = {
      test_account = {
        email = 'test@example.com',
        display_name = 'Test User'
      }
    },
    current_account = 'test_account'
  }
  
  accounts.init(config)
  
  test_framework.assert.equals(
    accounts.get_current_account_name(),
    'test_account',
    'Should set current account'
  )
  
  local account = accounts.get_account('test_account')
  test_framework.assert.truthy(account, 'Should have test account')
  test_framework.assert.equals(account.email, 'test@example.com', 'Should have email')
end

-- Test account switching
function M.test_switch_account()
  local config = {
    accounts = {
      account1 = { email = 'user1@example.com' },
      account2 = { email = 'user2@example.com' }
    },
    current_account = 'account1'
  }
  
  accounts.init(config)
  
  -- Test valid switch
  local ok, err = accounts.switch_account('account2')
  test_framework.assert.truthy(ok, 'Should switch successfully')
  test_framework.assert.equals(
    accounts.get_current_account_name(),
    'account2',
    'Should update current account'
  )
  
  -- Test invalid switch
  ok, err = accounts.switch_account('nonexistent')
  test_framework.assert.falsy(ok, 'Should fail for non-existent account')
  test_framework.assert.truthy(err:match('not found'), 'Should have error message')
end

-- Test email retrieval
function M.test_get_account_email()
  local config = {
    accounts = {
      explicit = { email = 'explicit@example.com' },
      email_as_name = {}
    }
  }
  
  accounts.init(config)
  
  -- Test explicit email
  test_framework.assert.equals(
    accounts.get_account_email('explicit'),
    'explicit@example.com',
    'Should return explicit email'
  )
  
  -- Test email as account name fallback
  test_framework.assert.equals(
    accounts.get_account_email('user@domain.com'),
    'user@domain.com',
    'Should use account name as email if it contains @'
  )
  
  -- Test nil for non-existent
  test_framework.assert.is_nil(
    accounts.get_account_email('nonexistent'),
    'Should return nil for non-existent account'
  )
end

-- Test display name
function M.test_get_account_display_name()
  local config = {
    accounts = {
      with_name = { 
        email = 'user@example.com',
        display_name = 'John Doe'
      },
      without_name = {
        email = 'noname@example.com'
      }
    }
  }
  
  accounts.init(config)
  
  -- Test explicit display name
  test_framework.assert.equals(
    accounts.get_account_display_name('with_name'),
    'John Doe',
    'Should return display name'
  )
  
  -- Test fallback to account name
  test_framework.assert.equals(
    accounts.get_account_display_name('nonexistent'),
    'nonexistent',
    'Should return account name as fallback'
  )
end

-- Test formatted from header
function M.test_get_formatted_from()
  local config = {
    accounts = {
      full = {
        email = 'user@example.com',
        display_name = 'John Doe'
      },
      email_only = {
        email = 'simple@example.com'
      }
    }
  }
  
  accounts.init(config)
  
  -- Test with display name
  test_framework.assert.equals(
    accounts.get_formatted_from('full'),
    'John Doe <user@example.com>',
    'Should format with display name'
  )
  
  -- Test without display name
  test_framework.assert.equals(
    accounts.get_formatted_from('email_only'),
    'simple@example.com',
    'Should return just email without display name'
  )
  
  -- Test non-existent account
  test_framework.assert.is_nil(
    accounts.get_formatted_from('nonexistent'),
    'Should return nil for non-existent account'
  )
end

-- Test mbsync config
function M.test_get_mbsync_config()
  local config = {
    accounts = {
      gmail = {
        email = 'user@gmail.com',
        mbsync = {
          inbox_channel = 'gmail-inbox',
          all_channel = 'gmail-all'
        }
      },
      no_mbsync = {
        email = 'user@example.com'
      }
    }
  }
  
  accounts.init(config)
  
  -- Test account with mbsync config
  local mbsync = accounts.get_mbsync_config('gmail')
  test_framework.assert.truthy(mbsync, 'Should have mbsync config')
  test_framework.assert.equals(
    mbsync.inbox_channel,
    'gmail-inbox',
    'Should have inbox channel'
  )
  
  -- Test account without mbsync config
  mbsync = accounts.get_mbsync_config('no_mbsync')
  test_framework.assert.truthy(mbsync, 'Should return empty table')
  test_framework.assert.equals(
    vim.tbl_count(mbsync),
    0,
    'Should be empty'
  )
end

-- Test update account
function M.test_update_account()
  local config = {
    accounts = {
      test = {
        email = 'old@example.com',
        display_name = 'Old Name'
      }
    }
  }
  
  accounts.init(config)
  
  -- Update account
  local ok = accounts.update_account('test', {
    display_name = 'New Name',
    custom_field = 'custom_value'
  })
  
  test_framework.assert.truthy(ok, 'Should update successfully')
  
  local account = accounts.get_account('test')
  test_framework.assert.equals(
    account.display_name,
    'New Name',
    'Should update existing field'
  )
  test_framework.assert.equals(
    account.custom_field,
    'custom_value',
    'Should add new field'
  )
  test_framework.assert.equals(
    account.email,
    'old@example.com',
    'Should preserve non-updated fields'
  )
end

return M