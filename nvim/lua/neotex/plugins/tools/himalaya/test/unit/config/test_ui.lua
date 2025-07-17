-- Unit tests for UI configuration module

local test_framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local ui = require('neotex.plugins.tools.himalaya.config.ui')

local M = {}

-- Test metadata
M.test_metadata = {
  name = "UI Configuration Tests",
  description = "Tests for UI configuration and display settings",
  count = 8,
  category = "unit",
  tags = {"config", "ui", "display"},
  estimated_duration_ms = 150
}

-- Test module initialization
function M.test_init()
  local config = {
    ui = {
      sidebar = {
        width = 50,
        position = 'right'
      },
      email_list = {
        page_size = 50
      }
    }
  }
  
  ui.init(config)
  
  -- Test merged settings
  local sidebar = ui.get_sidebar_settings()
  test_framework.assert.equals(sidebar.width, 50, 'Should override default width')
  test_framework.assert.equals(sidebar.position, 'right', 'Should override default position')
  test_framework.assert.truthy(sidebar.show_icons, 'Should preserve default show_icons')
  
  local email_list = ui.get_email_list_settings()
  test_framework.assert.equals(email_list.page_size, 50, 'Should override page size')
  test_framework.assert.truthy(email_list.date_format, 'Should preserve default date format')
end

-- Test get setting by path
function M.test_get_setting()
  local config = {
    ui = {
      sidebar = {
        width = 45
      },
      preview = {
        position = 'bottom',
        height = 25
      }
    }
  }
  
  ui.init(config)
  
  -- Test nested path access
  test_framework.assert.equals(
    ui.get('sidebar.width'),
    45,
    'Should get nested setting'
  )
  
  test_framework.assert.equals(
    ui.get('preview.position'),
    'bottom',
    'Should get preview position'
  )
  
  -- Test default value
  test_framework.assert.equals(
    ui.get('nonexistent.path', 'default'),
    'default',
    'Should return default for non-existent path'
  )
  
  -- Test partial path
  local sidebar = ui.get('sidebar')
  test_framework.assert.truthy(sidebar, 'Should get entire section')
  test_framework.assert.equals(sidebar.width, 45, 'Should have width in section')
end

-- Test confirmation requirements
function M.test_requires_confirmation()
  local config = {
    ui = {
      confirm = {
        delete = true,
        send = false,
        discard_draft = true
      }
    }
  }
  
  ui.init(config)
  
  test_framework.assert.truthy(
    ui.requires_confirmation('delete'),
    'Should require delete confirmation'
  )
  
  test_framework.assert.falsy(
    ui.requires_confirmation('send'),
    'Should not require send confirmation'
  )
  
  -- Test default (unspecified actions default to true)
  test_framework.assert.truthy(
    ui.requires_confirmation('unknown_action'),
    'Should default to requiring confirmation'
  )
end

-- Test update settings
function M.test_update_settings()
  local config = {
    ui = {
      sidebar = {
        width = 40
      }
    }
  }
  
  ui.init(config)
  
  -- Update existing setting
  ui.update_settings('sidebar.width', 60)
  test_framework.assert.equals(
    ui.get('sidebar.width'),
    60,
    'Should update setting'
  )
  
  -- Add new setting
  ui.update_settings('sidebar.custom_option', true)
  test_framework.assert.truthy(
    ui.get('sidebar.custom_option'),
    'Should add new setting'
  )
  
  -- Create nested path
  ui.update_settings('new.nested.value', 'test')
  test_framework.assert.equals(
    ui.get('new.nested.value'),
    'test',
    'Should create nested path'
  )
end

-- Test getting specific settings groups
function M.test_get_settings_groups()
  local config = {
    ui = {
      sidebar = { width = 35 },
      email_list = { page_size = 25 },
      preview = { position = 'float' },
      compose = { wrap_at = 80 },
      confirm = { delete = false }
    }
  }
  
  ui.init(config)
  
  -- Test each getter
  local sidebar = ui.get_sidebar_settings()
  test_framework.assert.equals(sidebar.width, 35, 'Should get sidebar settings')
  
  local email_list = ui.get_email_list_settings()
  test_framework.assert.equals(email_list.page_size, 25, 'Should get email list settings')
  
  local preview = ui.get_preview_settings()
  test_framework.assert.equals(preview.position, 'float', 'Should get preview settings')
  
  local compose = ui.get_compose_settings()
  test_framework.assert.equals(compose.wrap_at, 80, 'Should get compose settings')
  
  local confirm = ui.get_confirm_settings()
  test_framework.assert.equals(confirm.delete, false, 'Should get confirm settings')
end

-- Test keybinding retrieval
function M.test_get_keybinding()
  -- Note: keybindings are currently hardcoded in the module
  -- This tests the default implementation
  
  test_framework.assert.equals(
    ui.get_keybinding('himalaya-list', 'open'),
    '<CR>',
    'Should get list open keybinding'
  )
  
  test_framework.assert.equals(
    ui.get_keybinding('himalaya-preview', 'close'),
    'q',
    'Should get preview close keybinding'
  )
  
  test_framework.assert.equals(
    ui.get_keybinding('himalaya-compose', 'send'),
    '<C-s>',
    'Should get compose send keybinding'
  )
  
  test_framework.assert.is_nil(
    ui.get_keybinding('unknown-filetype', 'action'),
    'Should return nil for unknown filetype'
  )
end

-- Test buffer keymap setup
function M.test_setup_buffer_keymaps()
  -- Create a test buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-list')
  
  -- Setup keymaps
  ui.setup_buffer_keymaps(buf)
  
  -- Check that tab is disabled
  local keymaps = vim.api.nvim_buf_get_keymap(buf, 'n')
  local found_tab = false
  for _, keymap in ipairs(keymaps) do
    if keymap.lhs == '<Tab>' then
      found_tab = true
      test_framework.assert.equals(
        keymap.rhs,
        '',
        'Tab should be mapped to <Nop>'
      )
      break
    end
  end
  
  test_framework.assert.truthy(found_tab, 'Should have tab mapping')
  
  -- Cleanup
  vim.api.nvim_buf_delete(buf, { force = true })
end

-- Test default values preservation
function M.test_defaults_preserved()
  -- Initialize with empty config
  ui.init({})
  
  -- Check all defaults are present
  local sidebar = ui.get_sidebar_settings()
  test_framework.assert.equals(sidebar.width, 40, 'Should have default width')
  test_framework.assert.equals(sidebar.position, 'left', 'Should have default position')
  
  local email_list = ui.get_email_list_settings()
  test_framework.assert.equals(email_list.page_size, 30, 'Should have default page size')
  
  local preview = ui.get_preview_settings()
  test_framework.assert.equals(preview.position, 'right', 'Should have default preview position')
  
  test_framework.assert.truthy(
    ui.requires_confirmation('delete'),
    'Should default to requiring confirmation'
  )
end

-- Add standardized interface
M.get_test_count = function() return M.test_metadata.count end
M.get_test_list = function()
  local names = {}
  for key, value in pairs(M) do
    if type(value) == "function" and key:match("^test_") then
      table.insert(names, key:gsub("^test_", ""):gsub("_", " "))
    end
  end
  return names
end

return M