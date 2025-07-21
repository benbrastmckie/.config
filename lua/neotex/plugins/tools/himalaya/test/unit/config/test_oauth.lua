-- Unit tests for OAuth configuration module

local test_framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local oauth = require('neotex.plugins.tools.himalaya.config.oauth')

local M = {}

-- Test metadata
M.test_metadata = {
  name = "OAuth Configuration Tests",
  description = "Tests for OAuth configuration and token management",
  count = 7,
  category = "unit",
  tags = {"config", "oauth", "authentication"},
  estimated_duration_ms = 200
}

-- Save original env values
local saved_env = {}

function M.setup()
  -- Save environment variables
  saved_env.GMAIL_CLIENT_ID = vim.fn.getenv('GMAIL_CLIENT_ID')
  saved_env.GMAIL_CLIENT_SECRET = vim.fn.getenv('GMAIL_CLIENT_SECRET')
end

function M.teardown()
  -- Restore environment variables
  for key, value in pairs(saved_env) do
    if value and value ~= vim.NIL then
      vim.fn.setenv(key, value)
    else
      vim.fn.setenv(key, nil)
    end
  end
end

-- Test module initialization
function M.test_init()
  local config = {
    accounts = {
      gmail = {
        oauth = {
          client_id_env = 'GMAIL_CLIENT_ID',
          client_secret_env = 'GMAIL_CLIENT_SECRET',
          refresh_command = 'refresh-gmail'
        }
      },
      outlook = {
        oauth = {
          client_id_env = 'OUTLOOK_CLIENT_ID',
          client_secret_env = 'OUTLOOK_CLIENT_SECRET',
          refresh_command = 'refresh-outlook'
        }
      }
    },
    sync = {
      auto_refresh_oauth = true,
      oauth_refresh_cooldown = 600
    }
  }
  
  oauth.init(config)
  
  -- Test OAuth config was initialized
  local gmail_oauth = oauth.get_oauth_config('gmail')
  test_framework.assert.truthy(gmail_oauth, 'Should have Gmail OAuth config')
  test_framework.assert.equals(
    gmail_oauth.refresh_command,
    'refresh-gmail',
    'Should have refresh command'
  )
  
  -- Test sync settings
  test_framework.assert.truthy(
    oauth.is_auto_refresh_enabled(),
    'Auto refresh should be enabled'
  )
  test_framework.assert.equals(
    oauth.get_refresh_cooldown(),
    600,
    'Should have custom cooldown'
  )
end

-- Test uses_oauth check
function M.test_uses_oauth()
  local config = {
    accounts = {
      with_oauth = {
        oauth = {
          client_id_env = 'TEST_ID',
          refresh_command = 'test-refresh'
        }
      },
      without_oauth = {}
    }
  }
  
  oauth.init(config)
  
  test_framework.assert.truthy(
    oauth.uses_oauth('with_oauth'),
    'Should detect OAuth account'
  )
  
  test_framework.assert.falsy(
    oauth.uses_oauth('without_oauth'),
    'Should detect non-OAuth account'
  )
  
  test_framework.assert.falsy(
    oauth.uses_oauth('nonexistent'),
    'Should return false for non-existent account'
  )
end

-- Test credential retrieval
function M.test_get_credentials()
  -- Set test environment variables
  vim.fn.setenv('TEST_CLIENT_ID', 'test_id_123')
  vim.fn.setenv('TEST_CLIENT_SECRET', 'test_secret_456')
  
  local config = {
    accounts = {
      test = {
        oauth = {
          client_id_env = 'TEST_CLIENT_ID',
          client_secret_env = 'TEST_CLIENT_SECRET'
        }
      }
    }
  }
  
  oauth.init(config)
  
  -- Test getting credentials
  test_framework.assert.equals(
    oauth.get_client_id('test'),
    'test_id_123',
    'Should get client ID from env'
  )
  
  test_framework.assert.equals(
    oauth.get_client_secret('test'),
    'test_secret_456',
    'Should get client secret from env'
  )
  
  -- Test has_credentials
  test_framework.assert.truthy(
    oauth.has_credentials('test'),
    'Should have credentials'
  )
  
  -- Test missing credentials
  vim.fn.setenv('TEST_CLIENT_ID', nil)
  test_framework.assert.falsy(
    oauth.has_credentials('test'),
    'Should not have credentials without ID'
  )
end

-- Test refresh command
function M.test_get_refresh_command()
  local config = {
    accounts = {
      gmail = {
        oauth = {
          refresh_command = 'custom-refresh-gmail',
          configure_command = 'custom-configure-gmail'
        }
      }
    }
  }
  
  oauth.init(config)
  
  test_framework.assert.equals(
    oauth.get_refresh_command('gmail'),
    'custom-refresh-gmail',
    'Should get refresh command'
  )
  
  test_framework.assert.equals(
    oauth.get_configure_command('gmail'),
    'custom-configure-gmail',
    'Should get configure command'
  )
  
  test_framework.assert.is_nil(
    oauth.get_refresh_command('nonexistent'),
    'Should return nil for non-existent account'
  )
end

-- Test OAuth validation
function M.test_validate()
  -- Set up partial credentials
  vim.fn.setenv('PARTIAL_CLIENT_ID', 'some_id')
  vim.fn.setenv('PARTIAL_CLIENT_SECRET', nil)
  
  local config = {
    accounts = {
      valid = {
        oauth = {
          client_id_env = 'PARTIAL_CLIENT_ID',
          client_secret_env = 'PARTIAL_CLIENT_SECRET',
          refresh_command = 'refresh-valid'
        }
      },
      missing_command = {
        oauth = {
          client_id_env = 'SOME_ID',
          client_secret_env = 'SOME_SECRET'
          -- missing refresh_command
        }
      }
    }
  }
  
  oauth.init(config)
  
  -- Test validation with missing secret
  local valid, errors = oauth.validate('valid')
  test_framework.assert.falsy(valid, 'Should fail validation')
  test_framework.assert.truthy(
    #errors > 0,
    'Should have validation errors'
  )
  
  -- Test validation with missing command
  valid, errors = oauth.validate('missing_command')
  test_framework.assert.falsy(valid, 'Should fail validation for missing command')
  
  local found_command_error = false
  for _, err in ipairs(errors) do
    if err:match('refresh_command') then
      found_command_error = true
      break
    end
  end
  test_framework.assert.truthy(
    found_command_error,
    'Should have error about missing refresh command'
  )
end

-- Test update OAuth config
function M.test_update_oauth_config()
  local config = {
    accounts = {
      test = {
        oauth = {
          client_id_env = 'OLD_ID',
          refresh_command = 'old-refresh'
        }
      }
    }
  }
  
  oauth.init(config)
  
  -- Update config
  oauth.update_oauth_config('test', {
    client_id_env = 'NEW_ID',
    new_field = 'new_value'
  })
  
  local updated = oauth.get_oauth_config('test')
  test_framework.assert.equals(
    updated.client_id_env,
    'NEW_ID',
    'Should update existing field'
  )
  test_framework.assert.equals(
    updated.new_field,
    'new_value',
    'Should add new field'
  )
  test_framework.assert.equals(
    updated.refresh_command,
    'old-refresh',
    'Should preserve non-updated field'
  )
end

-- Test default OAuth configurations
function M.test_defaults()
  local config = {
    accounts = {
      gmail = {}  -- No OAuth specified, should use defaults
    }
  }
  
  oauth.init(config)
  
  local gmail_oauth = oauth.get_oauth_config('gmail')
  test_framework.assert.truthy(gmail_oauth, 'Should have default Gmail OAuth')
  test_framework.assert.equals(
    gmail_oauth.client_id_env,
    'GMAIL_CLIENT_ID',
    'Should use default client ID env'
  )
  test_framework.assert.equals(
    gmail_oauth.refresh_command,
    'refresh-gmail-oauth2',
    'Should use default refresh command'
  )
end

-- Add standardized interface

return M