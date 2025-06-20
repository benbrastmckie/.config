-- Folder Access Diagnostics
-- Tools to test and diagnose folder access and detection issues

local M = {}

local config = require('neotex.plugins.tools.himalaya.config')
local utils = require('neotex.plugins.tools.himalaya.utils')

-- Test current folder access and detection
function M.test_folder_access()
  print("=== Testing Current Folder Access ===")
  
  -- Get current account
  local account = config.state.current_account
  if not account then
    print("❌ No current account set")
    print("Run :Himalaya first to initialize an account")
    return false
  end
  
  print("Current account:", account)
  print()
  
  -- Test Himalaya folder list
  print("🔍 Testing Himalaya folder detection...")
  local folders = utils.get_folders(account)
  
  if not folders then
    print("❌ Failed to get folder list from Himalaya")
    print("This indicates a sync or configuration issue.")
    print()
    print("Possible causes:")
    print("1. Account not properly configured")
    print("2. No mail sync has been performed")
    print("3. mbsync configuration issues")
    print("4. Network/authentication problems")
    return false
  end
  
  print("✓ Himalaya returned", #folders, "folders:")
  for i, folder in ipairs(folders) do
    local indicator = M.categorize_folder(folder)
    print(string.format("%2d. %s%s", i, folder, indicator))
  end
  print()
  
  -- Analyze findings
  local analysis = M.analyze_folders(folders)
  M.report_folder_analysis(analysis)
  
  return folders
end

-- Categorize folder types for better understanding
function M.categorize_folder(folder)
  if folder:match('[Tt]rash') or folder:match('[Bb]in') then
    return " ← TRASH FOLDER"
  elseif folder:match('All Mail') then
    return " ← ALL MAIL (Gmail archive)"
  elseif folder:match('[Ss]pam') or folder:match('[Jj]unk') then
    return " ← SPAM/JUNK FOLDER"
  elseif folder:match('Sent') then
    return " ← SENT FOLDER"
  elseif folder:match('Draft') then
    return " ← DRAFTS FOLDER"
  elseif folder:match('INBOX') then
    return " ← INBOX"
  elseif folder:match('%[Gmail%]') then
    return " ← GMAIL SYSTEM FOLDER"
  else
    return " ← CUSTOM FOLDER"
  end
end

-- Analyze folder list for common issues
function M.analyze_folders(folders)
  local analysis = {
    total_folders = #folders,
    gmail_folders = {},
    system_folders = {},
    custom_folders = {},
    has_trash = false,
    has_spam = false,
    has_all_mail = false,
    has_sent = false,
    has_drafts = false,
    missing_folders = {}
  }
  
  for _, folder in ipairs(folders) do
    if folder:match('%[Gmail%]') then
      table.insert(analysis.gmail_folders, folder)
    end
    
    if folder:match('INBOX') or folder:match('Sent') or folder:match('Draft') or 
       folder:match('[Tt]rash') or folder:match('[Ss]pam') or folder:match('All Mail') then
      table.insert(analysis.system_folders, folder)
    else
      table.insert(analysis.custom_folders, folder)
    end
    
    -- Check for specific folders
    if folder:match('[Tt]rash') or folder:match('[Bb]in') then
      analysis.has_trash = true
    end
    if folder:match('[Ss]pam') or folder:match('[Jj]unk') then
      analysis.has_spam = true
    end
    if folder:match('All Mail') then
      analysis.has_all_mail = true
    end
    if folder:match('Sent') then
      analysis.has_sent = true
    end
    if folder:match('Draft') then
      analysis.has_drafts = true
    end
  end
  
  -- Identify missing standard folders
  local expected_folders = {
    {name = "Trash", has = analysis.has_trash, critical = true},
    {name = "Spam", has = analysis.has_spam, critical = false},
    {name = "Sent", has = analysis.has_sent, critical = false},
    {name = "Drafts", has = analysis.has_drafts, critical = false}
  }
  
  for _, expected in ipairs(expected_folders) do
    if not expected.has then
      table.insert(analysis.missing_folders, {
        name = expected.name,
        critical = expected.critical
      })
    end
  end
  
  return analysis
end

-- Report folder analysis results
function M.report_folder_analysis(analysis)
  print("📊 Folder Analysis:")
  print("Total folders found:", analysis.total_folders)
  print("Gmail system folders:", #analysis.gmail_folders)
  print("Standard system folders:", #analysis.system_folders)
  print("Custom folders:", #analysis.custom_folders)
  print()
  
  print("📋 System Folder Status:")
  local status_items = {
    {"Trash folder", analysis.has_trash},
    {"Spam folder", analysis.has_spam},
    {"Sent folder", analysis.has_sent},
    {"Drafts folder", analysis.has_drafts},
    {"All Mail folder", analysis.has_all_mail}
  }
  
  for _, item in ipairs(status_items) do
    local status = item[2] and "✓ Found" or "❌ Missing"
    print(string.format("  %s: %s", item[1], status))
  end
  print()
  
  -- Report issues
  if #analysis.missing_folders > 0 then
    print("⚠️  Missing Folders:")
    for _, missing in ipairs(analysis.missing_folders) do
      local severity = missing.critical and "CRITICAL" or "OPTIONAL"
      print(string.format("  • %s (%s)", missing.name, severity))
    end
    print()
    
    -- Provide specific guidance for missing trash
    if not analysis.has_trash then
      print("🚨 CRITICAL ISSUE: No Trash folder found!")
      print("This is why delete operations are failing.")
      print()
      print("Possible causes:")
      print("1. Gmail 'Show in IMAP' setting for Trash is disabled")
      print("2. mbsync configuration doesn't sync [Gmail]/Trash")
      print("3. Account uses non-standard folder names")
      print()
      
      if analysis.has_all_mail then
        print("💡 WORKAROUND AVAILABLE:")
        print("Can use 'All Mail' as deletion target (Gmail archive behavior)")
      end
    end
  else
    print("✅ All expected folders found!")
  end
  
  -- List Gmail folders for reference
  if #analysis.gmail_folders > 0 then
    print("📧 Gmail System Folders:")
    for _, folder in ipairs(analysis.gmail_folders) do
      print("  • " .. folder)
    end
    print()
  end
  
  -- List custom folders
  if #analysis.custom_folders > 0 then
    print("📁 Custom Folders:")
    for _, folder in ipairs(analysis.custom_folders) do
      print("  • " .. folder)
    end
    print()
  end
end

-- Test specific folder operations
function M.test_folder_operations()
  print("=== Testing Folder Operations ===")
  
  local account = config.state.current_account
  if not account then
    print("❌ No current account set")
    return false
  end
  
  print("Testing folder operations for account:", account)
  print()
  
  -- Test folder listing
  print("🔍 Testing folder list operation...")
  local folders = utils.get_folders(account)
  
  if folders then
    print("✓ Folder listing successful (" .. #folders .. " folders)")
  else
    print("❌ Folder listing failed")
    print("Check your account configuration and sync status")
    return false
  end
  
  -- Test email listing for INBOX
  print()
  print("📧 Testing email list operation (INBOX)...")
  local emails = utils.get_email_list(account, 'INBOX', 1, 5) -- Get first 5 emails
  
  if emails then
    print("✓ Email listing successful (" .. #emails .. " emails)")
    if #emails > 0 then
      print("  Sample email: " .. (emails[1].subject or "No subject"))
    end
  else
    print("❌ Email listing failed")
    print("Check your INBOX sync status")
  end
  
  -- Test trash folder specifically if it exists
  local has_trash = false
  local trash_folder = nil
  for _, folder in ipairs(folders or {}) do
    if folder:match('[Tt]rash') then
      has_trash = true
      trash_folder = folder
      break
    end
  end
  
  if has_trash then
    print()
    print("🗑️  Testing trash folder access...")
    local trash_emails = utils.get_email_list(account, trash_folder, 1, 5)
    
    if trash_emails then
      print("✓ Trash folder accessible (" .. #trash_emails .. " emails)")
    else
      print("❌ Trash folder access failed")
    end
  else
    print()
    print("⚠️  No trash folder to test")
  end
  
  return true
end

-- Compare expected vs actual folder structure
function M.compare_folder_structure()
  print("=== Expected vs Actual Folder Structure ===")
  
  local account = config.state.current_account
  if not account then
    print("❌ No current account set")
    return false
  end
  
  -- Get actual folders
  local actual_folders = utils.get_folders(account)
  if not actual_folders then
    print("❌ Cannot get actual folder list")
    return false
  end
  
  -- Define expected Gmail folder structure
  local expected_gmail_folders = {
    "[Gmail]/All Mail",
    "[Gmail]/Drafts", 
    "[Gmail]/Sent Mail",
    "[Gmail]/Spam",
    "[Gmail]/Trash"
  }
  
  print("📊 Gmail Folder Structure Comparison:")
  print()
  
  print("Expected Gmail folders:")
  for _, expected in ipairs(expected_gmail_folders) do
    local found = false
    local actual_name = nil
    
    -- Check for exact match or dot notation variant
    for _, actual in ipairs(actual_folders) do
      if actual == expected or actual == expected:gsub("/", ".") then
        found = true
        actual_name = actual
        break
      end
    end
    
    local status = found and "✓ Found" or "❌ Missing"
    local name_info = found and (actual_name ~= expected and " (as: " .. actual_name .. ")" or "") or ""
    print(string.format("  %s: %s%s", expected, status, name_info))
  end
  
  print()
  print("Actual folders found:")
  for _, folder in ipairs(actual_folders) do
    print("  • " .. folder)
  end
  
  print()
  print("💡 Analysis:")
  local missing_count = 0
  for _, expected in ipairs(expected_gmail_folders) do
    local found = false
    for _, actual in ipairs(actual_folders) do
      if actual == expected or actual == expected:gsub("/", ".") then
        found = true
        break
      end
    end
    if not found then
      missing_count = missing_count + 1
    end
  end
  
  if missing_count == 0 then
    print("✅ All expected Gmail folders are present")
  else
    print(string.format("⚠️  %d expected Gmail folders are missing", missing_count))
    print("This suggests Gmail IMAP settings need to be checked")
  end
  
  return true
end

-- Setup commands for this module
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaTestFolderAccess', M.test_folder_access, {
    desc = 'Test current folder detection and access'
  })
  
  vim.api.nvim_create_user_command('HimalayaTestFolderOps', M.test_folder_operations, {
    desc = 'Test folder operations (list, access, etc.)'
  })
  
  vim.api.nvim_create_user_command('HimalayaCompareFolders', M.compare_folder_structure, {
    desc = 'Compare expected vs actual folder structure'
  })
end

return M