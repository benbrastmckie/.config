-- Himalaya Utilities and Diagnostics
-- Central module for all diagnostic and utility functions

local M = {}

-- Load diagnostic modules
local diagnostics = require('neotex.plugins.tools.himalaya.util.diagnostics')
local gmail_settings = require('neotex.plugins.tools.himalaya.util.gmail_settings')
local mbsync_analyzer = require('neotex.plugins.tools.himalaya.util.mbsync_analyzer')
local folder_diagnostics = require('neotex.plugins.tools.himalaya.util.folder_diagnostics')
local operation_tester = require('neotex.plugins.tools.himalaya.util.operation_tester')

-- Export main diagnostic functions for easy access
M.run_full_diagnostics = diagnostics.run_full_diagnostics
M.quick_health_check = diagnostics.quick_health_check
M.show_diagnostic_commands = diagnostics.show_diagnostic_commands

-- Export specialized diagnostic functions
M.check_gmail_settings = gmail_settings.check_gmail_settings
M.analyze_mbsync_config = mbsync_analyzer.analyze_mbsync_config
M.test_folder_access = folder_diagnostics.test_folder_access
M.test_delete_operation = operation_tester.test_delete_operation

-- Setup all diagnostic commands
function M.setup_commands()
  diagnostics.setup_all()
end

-- Provide quick access to most common diagnostics
function M.diagnose_delete_issues()
  print("🔍 Diagnosing Delete Operation Issues")
  print("=" .. string.rep("=", 40))
  print()
  
  -- Run focused diagnostics for delete issues
  print("1. Testing folder access...")
  local folders = folder_diagnostics.test_folder_access()
  print()
  
  if folders then
    print("2. Testing delete operation...")
    operation_tester.test_delete_operation()
    print()
    
    print("3. Analyzing mbsync configuration...")
    mbsync_analyzer.analyze_mbsync_config()
  else
    print("❌ Cannot proceed with delete testing - folder access failed")
    print("Run :HimalayaFullDiagnostics for complete analysis")
  end
end

-- Provide quick access to Gmail-specific diagnostics
function M.diagnose_gmail_issues()
  print("📧 Diagnosing Gmail-Specific Issues")
  print("=" .. string.rep("=", 35))
  print()
  
  print("1. Gmail IMAP Settings Guide:")
  gmail_settings.check_gmail_settings()
  print()
  
  print("2. Folder Structure Analysis:")
  folder_diagnostics.compare_folder_structure()
  print()
  
  print("3. mbsync Configuration Review:")
  mbsync_analyzer.analyze_mbsync_config()
end

return M