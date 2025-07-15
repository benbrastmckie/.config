#!/usr/bin/env nvim -l
-- Test script to verify email_preview API completeness

-- Add the config path to package.path
local config_dir = vim.fn.expand('~/.config/nvim')
package.path = package.path .. ';' .. config_dir .. '/lua/?.lua'

-- Load the email_preview module
local preview = require('neotex.plugins.tools.himalaya.ui.email_preview')

-- List of expected functions based on usage in config.lua
local expected_functions = {
  'is_preview_mode',
  'enable_preview_mode',
  'disable_preview_mode', 
  'show_preview',
  'focus_preview',
  'is_preview_shown',
  'get_preview_state',
  'ensure_preview_window',
  'get_current_preview_id',
  'is_preview_visible',
  'toggle_preview_mode',
  'hide_preview',
  'setup',
}

print("Checking email_preview API completeness...")
print("=========================================")

local missing = {}
local found = {}

for _, func_name in ipairs(expected_functions) do
  if type(preview[func_name]) == 'function' then
    table.insert(found, func_name)
  else
    table.insert(missing, func_name)
  end
end

print("\nFound functions (" .. #found .. "):")
for _, func in ipairs(found) do
  print("  ✓ " .. func)
end

if #missing > 0 then
  print("\nMissing functions (" .. #missing .. "):")
  for _, func in ipairs(missing) do
    print("  ✗ " .. func)
  end
else
  print("\nAll expected functions are present!")
end

-- Test basic functionality
print("\nTesting basic functionality...")
print("------------------------------")

-- Test preview mode toggling
print("Initial preview mode:", preview.is_preview_mode())
preview.enable_preview_mode()
print("After enable:", preview.is_preview_mode())
preview.disable_preview_mode()
print("After disable:", preview.is_preview_mode())
preview.toggle_preview_mode()
print("After toggle:", preview.is_preview_mode())

print("\nAPI test complete!")