-- Unit tests for configuration validation module

local test_framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local validation = require('neotex.plugins.tools.himalaya.config.validation')

local M = {}

-- Test account validation
function M.test_validate_accounts()
  -- Test no accounts
  local config = {}
  local valid, errors = validation.validate(config)
  test_framework.assert.falsy(valid, 'Should fail with no accounts')
  
  local found_account_error = false
  for _, err in ipairs(errors) do
    if err:match('No accounts configured') then
      found_account_error = true
      break
    end
  end
  test_framework.assert.truthy(found_account_error, 'Should have no accounts error')
  
  -- Test invalid account name
  config = {
    accounts = {
      ['invalid@name'] = { email = 'test@example.com' }
    }
  }
  valid, errors = validation.validate(config)
  test_framework.assert.falsy(valid, 'Should fail with invalid account name')
  
  -- Test maildir path without trailing slash
  config = {
    accounts = {
      test = {
        email = 'test@example.com',
        maildir_path = '~/Mail/Test'  -- Missing trailing slash
      }
    }
  }
  valid, errors = validation.validate(config)
  test_framework.assert.falsy(valid, 'Should fail without trailing slash')
  
  found_slash_error = false
  for _, err in ipairs(errors) do
    if err:match('trailing slash') then
      found_slash_error = true
      break
    end
  end
  test_framework.assert.truthy(found_slash_error, 'Should have trailing slash error')
  
  -- Test valid config
  config = {
    accounts = {
      gmail = {
        email = 'user@gmail.com',
        maildir_path = '~/Mail/Gmail/'
      }
    }
  }
  valid, errors = validation.validate(config)
  test_framework.assert.truthy(valid, 'Should pass with valid config')
  test_framework.assert.equals(#errors, 0, 'Should have no errors')
end

-- Test draft configuration validation
function M.test_validate_draft_config()
  -- Test invalid storage type
  local config = {
    accounts = { gmail = {} },
    drafts = {
      storage = {
        type = 'invalid_type'
      }
    }
  }
  local valid, errors = validation.validate(config)
  test_framework.assert.falsy(valid, 'Should fail with invalid storage type')
  
  -- Test invalid sync interval
  config = {
    accounts = { gmail = {} },
    drafts = {
      sync = {
        interval = -1
      }
    }
  }
  valid, errors = validation.validate(config)
  test_framework.assert.falsy(valid, 'Should fail with negative interval')
  
  -- Test invalid recovery settings
  config = {
    accounts = { gmail = {} },
    drafts = {
      recovery = {
        backup_count = 'not_a_number',
        auto_recover = 'not_a_boolean'
      }
    }
  }
  valid, errors = validation.validate(config)
  test_framework.assert.falsy(valid, 'Should fail with invalid recovery settings')
  test_framework.assert.truthy(#errors >= 2, 'Should have multiple errors')
end

-- Test sync configuration validation
function M.test_validate_sync()
  -- Test invalid lock timeout
  local config = {
    accounts = { gmail = {} },
    sync = {
      lock_timeout = 'not_a_number'
    }
  }
  local valid, errors = validation.validate(config)
  test_framework.assert.falsy(valid, 'Should fail with invalid lock timeout')
  
  -- Test invalid coordination settings
  config = {
    accounts = { gmail = {} },
    sync = {
      coordination = {
        heartbeat_interval = -10,
        takeover_threshold = 'invalid',
        sync_cooldown = nil
      }
    }
  }
  valid, errors = validation.validate(config)
  test_framework.assert.falsy(valid, 'Should fail with invalid coordination settings')
end

-- Test UI configuration validation  
function M.test_validate_ui()
  -- Test invalid sidebar width
  local config = {
    accounts = { gmail = {} },
    ui = {
      sidebar = {
        width = 5,  -- Too small
        position = 'invalid_position'
      }
    }
  }
  local valid, errors = validation.validate(config)
  test_framework.assert.falsy(valid, 'Should fail with invalid sidebar settings')
  
  -- Test invalid email list settings
  config = {
    accounts = { gmail = {} },
    ui = {
      email_list = {
        page_size = 0,
        preview_lines = -1
      }
    }
  }
  valid, errors = validation.validate(config)
  test_framework.assert.falsy(valid, 'Should fail with invalid email list settings')
  
  -- Test invalid preview settings
  config = {
    accounts = { gmail = {} },
    ui = {
      preview = {
        position = 'diagonal',  -- Invalid position
        width = 5,              -- Too small
        height = 2              -- Too small
      }
    }
  }
  valid, errors = validation.validate(config)
  test_framework.assert.falsy(valid, 'Should fail with invalid preview settings')
  test_framework.assert.truthy(#errors >= 3, 'Should have multiple UI errors')
end

-- Test configuration migration
function M.test_migrate()
  -- Test OAuth migration
  local old_config = {
    accounts = {
      gmail = {
        oauth_client_id_env = 'OLD_GMAIL_ID',
        oauth_client_secret_env = 'OLD_GMAIL_SECRET'
      }
    }
  }
  
  local new_config, migrations = validation.migrate(old_config)
  
  -- Check migrations were applied
  test_framework.assert.truthy(
    new_config.accounts.gmail.oauth,
    'Should create oauth section'
  )
  test_framework.assert.equals(
    new_config.accounts.gmail.oauth.client_id_env,
    'OLD_GMAIL_ID',
    'Should migrate client ID'
  )
  test_framework.assert.is_nil(
    new_config.accounts.gmail.oauth_client_id_env,
    'Should remove old field'
  )
  test_framework.assert.truthy(
    #migrations > 0,
    'Should report migrations'
  )
  
  -- Test maildir path migration
  old_config = {
    accounts = {
      test = {
        maildir_path = '~/Mail/Test'  -- Missing trailing slash
      }
    }
  }
  
  new_config, migrations = validation.migrate(old_config)
  test_framework.assert.equals(
    new_config.accounts.test.maildir_path,
    '~/Mail/Test/',
    'Should add trailing slash'
  )
end

-- Test needs_migration check
function M.test_needs_migration()
  -- Test old OAuth format
  local config = {
    accounts = {
      gmail = {
        oauth_client_id_env = 'GMAIL_ID'
      }
    }
  }
  test_framework.assert.truthy(
    validation.needs_migration(config),
    'Should detect old OAuth format'
  )
  
  -- Test missing trailing slash
  config = {
    accounts = {
      test = {
        maildir_path = '~/Mail/Test'
      }
    }
  }
  test_framework.assert.truthy(
    validation.needs_migration(config),
    'Should detect missing trailing slash'
  )
  
  -- Test modern config
  config = {
    accounts = {
      gmail = {
        oauth = {
          client_id_env = 'GMAIL_ID'
        },
        maildir_path = '~/Mail/Gmail/'
      }
    }
  }
  test_framework.assert.falsy(
    validation.needs_migration(config),
    'Should not need migration for modern config'
  )
end

-- Test complete validation workflow
function M.test_complete_validation()
  -- Valid complete configuration
  local config = {
    accounts = {
      gmail = {
        email = 'user@gmail.com',
        maildir_path = '~/Mail/Gmail/',
        oauth = {
          client_id_env = 'GMAIL_CLIENT_ID',
          client_secret_env = 'GMAIL_CLIENT_SECRET',
          refresh_command = 'refresh-gmail'
        }
      }
    },
    sync = {
      lock_timeout = 300,
      coordination = {
        enabled = true,
        heartbeat_interval = 30
      }
    },
    ui = {
      sidebar = {
        width = 40,
        position = 'left'
      },
      email_list = {
        page_size = 30
      }
    },
    drafts = {
      storage = {
        type = 'maildir'
      },
      sync = {
        interval = 300
      }
    }
  }
  
  local valid, errors = validation.validate(config)
  test_framework.assert.truthy(valid, 'Complete config should be valid')
  test_framework.assert.equals(#errors, 0, 'Should have no validation errors')
end

return M