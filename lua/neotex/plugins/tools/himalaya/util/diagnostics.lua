-- Comprehensive Diagnostics Suite
-- Master diagnostics module that orchestrates all diagnostic tools

local M = {}

local gmail_settings = require('neotex.plugins.tools.himalaya.util.gmail_settings')
local mbsync_analyzer = require('neotex.plugins.tools.himalaya.util.mbsync_analyzer')
local folder_diagnostics = require('neotex.plugins.tools.himalaya.util.folder_diagnostics')
local operation_tester = require('neotex.plugins.tools.himalaya.util.operation_tester')

-- Run the complete diagnostic suite
function M.run_full_diagnostics()
  print("🔧 Himalaya Email Client - Full Diagnostics Suite")
  print("=" .. string.rep("=", 60))
  print()
  print("This diagnostic will analyze your Himalaya configuration and")
  print("identify any issues with email operations.")
  print()
  
  local results = {}
  
  -- Phase 1: Gmail IMAP Settings Guidance
  print("📧 PHASE 1: Gmail IMAP Settings Verification")
  print(string.rep("-", 50))
  gmail_settings.check_gmail_settings()
  results.gmail_guidance_provided = true
  print()
  
  -- Phase 2: mbsync Configuration Analysis
  print("⚙️  PHASE 2: mbsync Configuration Analysis")
  print(string.rep("-", 50))
  results.mbsync_analysis = mbsync_analyzer.analyze_mbsync_config()
  print()
  
  -- Phase 3: Folder Access Testing
  print("📁 PHASE 3: Folder Access Testing")
  print(string.rep("-", 50))
  results.folder_access = folder_diagnostics.test_folder_access()
  print()
  
  -- Phase 4: Operation Testing (if folders available)
  if results.folder_access then
    print("🔧 PHASE 4: Email Operation Testing")
    print(string.rep("-", 50))
    results.operations = operation_tester.test_email_retrieval()
    print()
  end
  
  -- Phase 5: Summary and Recommendations
  print("📋 PHASE 5: Summary and Recommendations")
  print(string.rep("-", 50))
  M.provide_summary_recommendations(results)
  
  print()
  print("🏁 Full Diagnostics Complete")
  print()
  print("Use individual diagnostic commands for focused troubleshooting:")
  print("• :HimalayaCheckGmailSettings")
  print("• :HimalayaAnalyzeMbsync")
  print("• :HimalayaTestFolderAccess")
  print("• :HimalayaTestDelete")
  
  return results
end

-- Provide summary and recommendations based on diagnostic results
function M.provide_summary_recommendations(results)
  print("🔍 DIAGNOSTIC SUMMARY:")
  print()
  
  -- Configuration status
  local config_status = "Unknown"
  if results.mbsync_analysis == true then
    config_status = "✓ Found and analyzed"
  elseif results.mbsync_analysis == false then
    config_status = "❌ Not found or invalid"
  end
  print("mbsync configuration:", config_status)
  
  -- Folder access status
  local folder_status = "Unknown"
  local folder_count = 0
  if results.folder_access then
    folder_count = type(results.folder_access) == "table" and #results.folder_access or 0
    folder_status = string.format("✓ %d folders accessible", folder_count)
  else
    folder_status = "❌ No folder access"
  end
  print("Folder access:", folder_status)
  
  -- Operation status
  local operation_status = results.operations and "✓ Basic operations working" or "❌ Operation issues detected"
  print("Email operations:", operation_status)
  
  print()
  
  -- Determine overall health and provide recommendations
  local issues = {}
  local recommendations = {}
  
  if not results.mbsync_analysis then
    table.insert(issues, "mbsync configuration not found or invalid")
    table.insert(recommendations, "1. Check if ~/.mbsyncrc exists and is properly formatted")
    table.insert(recommendations, "2. Verify mbsync/isync is installed")
    table.insert(recommendations, "3. Consider using example configuration: :HimalayaShowExampleConfig")
  end
  
  if not results.folder_access then
    table.insert(issues, "Cannot access any folders")
    table.insert(recommendations, "1. Verify account authentication")
    table.insert(recommendations, "2. Check network connectivity")
    table.insert(recommendations, "3. Run mail sync: mbsync -a")
  elseif type(results.folder_access) == "table" then
    -- Check for missing trash folder
    local has_trash = false
    for _, folder in ipairs(results.folder_access) do
      if folder:match('[Tt]rash') then
        has_trash = true
        break
      end
    end
    
    if not has_trash then
      table.insert(issues, "No trash folder found")
      table.insert(recommendations, "1. Enable 'Show in IMAP' for Trash in Gmail settings")
      table.insert(recommendations, "2. Add trash channel to mbsync configuration")
      table.insert(recommendations, "3. Use All Mail workaround if available")
    end
  end
  
  if not results.operations then
    table.insert(issues, "Email operations not working properly")
    table.insert(recommendations, "1. Check account configuration")
    table.insert(recommendations, "2. Verify email sync status")
    table.insert(recommendations, "3. Test individual operations: :HimalayaTestAll")
  end
  
  -- Report issues and recommendations
  if #issues > 0 then
    print("⚠️  ISSUES DETECTED:")
    for _, issue in ipairs(issues) do
      print("  • " .. issue)
    end
    print()
    
    print("💡 RECOMMENDED ACTIONS:")
    for _, rec in ipairs(recommendations) do
      print("  " .. rec)
    end
  else
    print("✅ NO MAJOR ISSUES DETECTED")
    print("Your Himalaya configuration appears to be working correctly.")
  end
  
  print()
  
  -- Provide next steps based on findings
  print("📝 NEXT STEPS:")
  
  if not results.mbsync_analysis or not results.folder_access then
    print("1. 🚨 PRIORITY: Fix configuration issues above")
    print("2. Run: mbsync -a")
    print("3. Re-run diagnostics: :HimalayaFullDiagnostics")
  elseif #issues > 0 then
    print("1. Address the issues listed above")
    print("2. Focus on Gmail IMAP settings if trash folder missing")
    print("3. Test specific operations: :HimalayaTestDelete")
  else
    print("1. ✅ Configuration looks good!")
    print("2. If you're still having issues, try:")
    print("   • :HimalayaTestDelete (test delete operation)")
    print("   • :HimalayaTestAll (comprehensive operation test)")
  end
end

-- Quick health check (lightweight version)
function M.quick_health_check()
  print("🏥 Himalaya Quick Health Check")
  print("=" .. string.rep("=", 35))
  print()
  
  local config = require('neotex.plugins.tools.himalaya.config')
  local utils = require('neotex.plugins.tools.himalaya.utils')
  
  -- Check 1: Account configured
  local account = config.state.current_account
  local account_status = account and "✓ " .. account or "❌ No account set"
  print("Current account:", account_status)
  
  -- Check 2: Can list folders
  local folder_status = "❌ Cannot access"
  local folder_count = 0
  if account then
    local folders = utils.get_folders(account)
    if folders then
      folder_count = #folders
      folder_status = "✓ " .. folder_count .. " folders"
    end
  end
  print("Folder access:", folder_status)
  
  -- Check 3: mbsync config exists
  local mbsync_path = vim.fn.expand('~/.mbsyncrc')
  local mbsync_status = vim.fn.filereadable(mbsync_path) == 1 and "✓ Found" or "❌ Missing"
  print("mbsync config:", mbsync_status)
  
  -- Check 4: Has trash folder
  local trash_status = "❌ Not found"
  if account then
    local folders = utils.get_folders(account)
    if folders then
      for _, folder in ipairs(folders) do
        if folder:match('[Tt]rash') then
          trash_status = "✓ Found"
          break
        end
      end
    end
  end
  print("Trash folder:", trash_status)
  
  print()
  
  -- Overall health assessment
  local health_score = 0
  if account then health_score = health_score + 1 end
  if folder_count > 0 then health_score = health_score + 1 end
  if vim.fn.filereadable(mbsync_path) == 1 then health_score = health_score + 1 end
  if trash_status:match("✓") then health_score = health_score + 1 end
  
  local health_percentage = math.floor((health_score / 4) * 100)
  local health_indicator = ""
  
  if health_percentage >= 75 then
    health_indicator = "✅ HEALTHY"
  elseif health_percentage >= 50 then
    health_indicator = "⚠️  ISSUES DETECTED"
  else
    health_indicator = "❌ CRITICAL ISSUES"
  end
  
  print(string.format("Overall Health: %s (%d%%)", health_indicator, health_percentage))
  
  if health_percentage < 100 then
    print()
    print("Run :HimalayaFullDiagnostics for detailed analysis")
  end
end

-- Show diagnostic command reference
function M.show_diagnostic_commands()
  print("🔧 Himalaya Diagnostic Commands Reference")
  print("=" .. string.rep("=", 45))
  print()
  
  local commands = {
    {
      category = "Complete Diagnostics",
      commands = {
        {cmd = ":HimalayaFullDiagnostics", desc = "Run complete diagnostic suite"},
        {cmd = ":HimalayaQuickHealthCheck", desc = "Quick health status check"}
      }
    },
    {
      category = "Gmail-Specific",
      commands = {
        {cmd = ":HimalayaCheckGmailSettings", desc = "Verify Gmail IMAP settings"},
        {cmd = ":HimalayaExplainGmailIMAP", desc = "Explain Gmail IMAP behavior"},
        {cmd = ":HimalayaTroubleshootGmail", desc = "Interactive Gmail troubleshooting"}
      }
    },
    {
      category = "Configuration Analysis",
      commands = {
        {cmd = ":HimalayaAnalyzeMbsync", desc = "Analyze mbsync configuration"},
        {cmd = ":HimalayaShowExampleConfig", desc = "Show example Gmail configuration"}
      }
    },
    {
      category = "Folder Diagnostics",
      commands = {
        {cmd = ":HimalayaTestFolderAccess", desc = "Test folder access and detection"},
        {cmd = ":HimalayaCompareFolders", desc = "Compare expected vs actual folders"},
        {cmd = ":HimalayaTestFolderOps", desc = "Test folder operations"}
      }
    },
    {
      category = "Operation Testing",
      commands = {
        {cmd = ":HimalayaTestDelete", desc = "Test delete operation"},
        {cmd = ":HimalayaTestMove <folder>", desc = "Test move operation"},
        {cmd = ":HimalayaTestFlags", desc = "Test flag operations"},
        {cmd = ":HimalayaTestRetrieval", desc = "Test email retrieval"},
        {cmd = ":HimalayaTestAll", desc = "Test all operations"}
      }
    }
  }
  
  for _, category in ipairs(commands) do
    print("📋 " .. category.category .. ":")
    for _, cmd in ipairs(category.commands) do
      print(string.format("  %-30s %s", cmd.cmd, cmd.desc))
    end
    print()
  end
  
  print("💡 Quick Start:")
  print("1. Start with: :HimalayaQuickHealthCheck")
  print("2. For issues: :HimalayaFullDiagnostics")
  print("3. Focus on specific areas using category commands")
end

-- Setup commands for this module
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaFullDiagnostics', M.run_full_diagnostics, {
    desc = 'Run complete Himalaya diagnostics suite'
  })
  
  vim.api.nvim_create_user_command('HimalayaQuickHealthCheck', M.quick_health_check, {
    desc = 'Quick health status check'
  })
  
  vim.api.nvim_create_user_command('HimalayaDiagnosticCommands', M.show_diagnostic_commands, {
    desc = 'Show all available diagnostic commands'
  })
end

-- Setup all diagnostic modules
function M.setup_all()
  M.setup_commands()
  gmail_settings.setup_commands()
  mbsync_analyzer.setup_commands()
  folder_diagnostics.setup_commands()
  operation_tester.setup_commands()
end

return M