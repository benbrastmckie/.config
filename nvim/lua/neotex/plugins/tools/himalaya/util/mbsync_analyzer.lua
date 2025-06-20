-- mbsync Configuration Analyzer
-- Tools to analyze and diagnose mbsync configuration issues

local M = {}

-- Analyze mbsync configuration file
function M.analyze_mbsync_config()
  print("=== Analyzing mbsync Configuration ===")
  
  local config_file = vim.fn.expand('~/.mbsyncrc')
  print("Checking mbsync config at:", config_file)
  
  if vim.fn.filereadable(config_file) == 0 then
    print("❌ ERROR: .mbsyncrc file not found!")
    print("Expected location:", config_file)
    print()
    print("Possible solutions:")
    print("1. Check if you're using a different config location")
    print("2. Verify your mail sync setup (mbsync/isync)")
    print("3. Check if config is managed by Nix/home-manager")
    print("4. Look for config in: ~/.config/mbsync/config")
    return false
  end
  
  local config_content = vim.fn.readfile(config_file)
  
  print("✓ Found .mbsyncrc file (" .. #config_content .. " lines)")
  print()
  
  -- Analyze configuration structure
  local analysis = M.parse_config(config_content)
  M.report_analysis(analysis)
  M.provide_recommendations(analysis)
  
  return true
end

-- Parse mbsync configuration into structured data
function M.parse_config(config_lines)
  local analysis = {
    accounts = {},
    stores = {},
    channels = {},
    groups = {},
    gmail_references = {},
    patterns = {},
    issues = {}
  }
  
  local current_section = nil
  local current_type = nil
  local line_num = 0
  
  for _, line in ipairs(config_lines) do
    line_num = line_num + 1
    local trimmed = line:match("^%s*(.-)%s*$") -- trim whitespace
    
    if trimmed == "" or trimmed:match("^#") then
      -- Skip empty lines and comments
      goto continue
    end
    
    -- Detect section headers
    local section_match = trimmed:match("^(%w+)%s+(.+)")
    if section_match then
      local section_type = trimmed:match("^(%w+)")
      current_type = section_type
      current_section = trimmed:match("^%w+%s+(.+)")
      
      if section_type == "IMAPAccount" then
        analysis.accounts[current_section] = {line = line_num, config = {}}
      elseif section_type == "IMAPStore" or section_type == "MaildirStore" then
        analysis.stores[current_section] = {
          line = line_num, 
          type = section_type,
          config = {},
          is_gmail = current_section:lower():match("gmail") ~= nil
        }
      elseif section_type == "Channel" then
        analysis.channels[current_section] = {
          line = line_num,
          config = {},
          is_gmail = current_section:lower():match("gmail") ~= nil
        }
      elseif section_type == "Group" then
        analysis.groups[current_section] = {line = line_num, channels = {}}
      end
    else
      -- Parse configuration options within sections
      local key, value = trimmed:match("^(%w+)%s+(.+)")
      if key and current_section then
        if current_type == "Channel" and analysis.channels[current_section] then
          analysis.channels[current_section].config[key] = value
          
          -- Track patterns specifically
          if key == "Patterns" then
            table.insert(analysis.patterns, {
              line = line_num,
              channel = current_section,
              pattern = value
            })
          end
        elseif current_type == "IMAPStore" or current_type == "MaildirStore" then
          if analysis.stores[current_section] then
            analysis.stores[current_section].config[key] = value
          end
        elseif current_type == "IMAPAccount" then
          if analysis.accounts[current_section] then
            analysis.accounts[current_section].config[key] = value
          end
        end
      end
    end
    
    -- Track Gmail-specific references
    if trimmed:match("%[Gmail%]") then
      table.insert(analysis.gmail_references, {
        line = line_num,
        content = trimmed,
        section = current_section
      })
    end
    
    ::continue::
  end
  
  return analysis
end

-- Report analysis findings
function M.report_analysis(analysis)
  print("📊 Configuration Analysis:")
  print()
  
  -- Report accounts
  if vim.tbl_count(analysis.accounts) > 0 then
    print("✓ IMAP Accounts found:")
    for name, account in pairs(analysis.accounts) do
      local auth = account.config.AuthMechs or "Unknown"
      local host = account.config.Host or "Unknown"
      print(string.format("  Line %d: %s (Host: %s, Auth: %s)", account.line, name, host, auth))
    end
  else
    print("⚠️  No IMAP accounts found")
  end
  print()
  
  -- Report stores
  local gmail_stores = 0
  if vim.tbl_count(analysis.stores) > 0 then
    print("✓ Stores found:")
    for name, store in pairs(analysis.stores) do
      local indicator = store.is_gmail and " (Gmail)" or ""
      print(string.format("  Line %d: %s (%s)%s", store.line, name, store.type, indicator))
      if store.is_gmail then
        gmail_stores = gmail_stores + 1
      end
    end
  else
    print("❌ No stores found")
  end
  print()
  
  -- Report channels  
  local gmail_channels = 0
  local has_trash_channel = false
  if vim.tbl_count(analysis.channels) > 0 then
    print("✓ Channels found:")
    for name, channel in pairs(analysis.channels) do
      local indicator = channel.is_gmail and " (Gmail)" or ""
      local patterns = channel.config.Patterns or "None"
      print(string.format("  Line %d: %s%s - Patterns: %s", channel.line, name, indicator, patterns))
      
      if channel.is_gmail then
        gmail_channels = gmail_channels + 1
      end
      
      -- Check for trash references in this channel
      if name:lower():match("trash") or 
         (channel.config.Master and channel.config.Master:match("[Tt]rash")) or
         (channel.config.Far and channel.config.Far:match("[Tt]rash")) then
        has_trash_channel = true
      end
    end
  else
    print("❌ No channels found")
  end
  print()
  
  -- Report Gmail-specific findings
  print("🔍 Gmail-Specific Analysis:")
  print("Gmail stores:", gmail_stores)
  print("Gmail channels:", gmail_channels) 
  print("Has trash channel:", has_trash_channel and "✓ YES" or "❌ NO")
  print("Gmail folder references:", #analysis.gmail_references)
  print()
  
  if #analysis.gmail_references > 0 then
    print("Gmail folder references found:")
    for _, ref in ipairs(analysis.gmail_references) do
      print(string.format("  Line %d: %s", ref.line, ref.content))
    end
    print()
  end
  
  -- Report patterns
  if #analysis.patterns > 0 then
    print("📋 Folder Patterns:")
    for _, pattern in ipairs(analysis.patterns) do
      local warning = ""
      if pattern.pattern:match("!") then
        warning = " ⚠️ (excludes folders)"
      elseif pattern.pattern == "*" then
        warning = " (syncs all folders)"
      end
      print(string.format("  Line %d (%s): %s%s", pattern.line, pattern.channel, pattern.pattern, warning))
    end
    print()
  end
end

-- Provide configuration recommendations
function M.provide_recommendations(analysis)
  print("📋 Recommendations:")
  print()
  
  local issues = {}
  
  -- Check for Gmail-specific issues
  local gmail_stores = 0
  local gmail_channels = 0
  local has_trash_channel = false
  
  for _, store in pairs(analysis.stores) do
    if store.is_gmail then gmail_stores = gmail_stores + 1 end
  end
  
  for name, channel in pairs(analysis.channels) do
    if channel.is_gmail then gmail_channels = gmail_channels + 1 end
    if name:lower():match("trash") or 
       (channel.config.Master and channel.config.Master:match("[Tt]rash")) then
      has_trash_channel = true
    end
  end
  
  if gmail_stores == 0 then
    table.insert(issues, "❌ No Gmail stores found - add Gmail IMAP and Maildir stores")
  end
  
  if gmail_channels == 0 then
    table.insert(issues, "❌ No Gmail channels found - add Gmail sync channels")
  end
  
  if not has_trash_channel then
    table.insert(issues, "❌ No trash channel found - this is likely why delete operations fail")
    print("💡 PRIORITY FIX: Add a trash channel:")
    print("   Channel gmail-trash")
    print("   Master :gmail-remote:\"[Gmail]/Trash\"")
    print("   Slave :gmail-local:trash")
    print("   Create Slave")
    print()
  end
  
  -- Check for problematic patterns
  for _, pattern in ipairs(analysis.patterns) do
    if pattern.pattern:match("!.*Gmail") then
      table.insert(issues, "⚠️ Pattern excludes Gmail folders: " .. pattern.pattern)
    end
  end
  
  if #issues > 0 then
    print("🚨 Issues Found:")
    for _, issue in ipairs(issues) do
      print("  " .. issue)
    end
    print()
  else
    print("✅ Configuration looks good!")
    print("If folders are still missing, check Gmail IMAP settings.")
    print()
  end
  
  print("📝 Next Steps:")
  print("1. Fix any issues listed above")
  print("2. Run: mbsync -a")
  print("3. Test with: :HimalayaListFolders")
  print("4. If still failing: :HimalayaCheckGmailSettings")
end

-- Show example Gmail configuration
function M.show_example_config()
  print("=== Example Gmail mbsync Configuration ===")
  print()
  print("# Complete Gmail setup with all standard folders")
  print()
  print("# Gmail IMAP account")
  print("IMAPAccount gmail")
  print("Host imap.gmail.com")
  print("Port 993")
  print("User your-email@gmail.com")
  print("AuthMechs XOAUTH2  # or LOGIN with app password")
  print("PassCmd \"your-password-command\"")
  print("TLSType IMAPS")
  print()
  print("# Gmail remote store")
  print("IMAPStore gmail-remote")
  print("Account gmail")
  print()
  print("# Gmail local store")
  print("MaildirStore gmail-local")
  print("Path ~/Mail/Gmail/")
  print("Inbox ~/Mail/Gmail/INBOX")
  print("SubFolders Maildir++")
  print()
  print("# Gmail channels (recommended: separate channels)")
  print("Channel gmail-inbox")
  print("Master :gmail-remote:")
  print("Slave :gmail-local:")
  print("Patterns \"INBOX\"")
  print("Create Slave")
  print("SyncState *")
  print()
  print("Channel gmail-sent")
  print("Master :gmail-remote:\"[Gmail]/Sent Mail\"")
  print("Slave :gmail-local:sent")
  print("Create Slave")
  print()
  print("Channel gmail-drafts")  
  print("Master :gmail-remote:\"[Gmail]/Drafts\"")
  print("Slave :gmail-local:drafts")
  print("Create Slave")
  print()
  print("Channel gmail-trash")
  print("Master :gmail-remote:\"[Gmail]/Trash\"")
  print("Slave :gmail-local:trash")
  print("Create Slave")
  print()
  print("Channel gmail-spam")
  print("Master :gmail-remote:\"[Gmail]/Spam\"") 
  print("Slave :gmail-local:spam")
  print("Create Slave")
  print()
  print("Channel gmail-all")
  print("Master :gmail-remote:\"[Gmail]/All Mail\"")
  print("Slave :gmail-local:archive")
  print("Create Slave")
  print()
  print("# Group all Gmail channels")
  print("Group gmail")
  print("Channel gmail-inbox")
  print("Channel gmail-sent")
  print("Channel gmail-drafts")
  print("Channel gmail-trash")
  print("Channel gmail-spam")
  print("Channel gmail-all")
  print()
  print("💡 Alternative: Single channel with patterns")
  print("# If you prefer one channel (current setup):")
  print("Channel gmail")
  print("Master :gmail-remote:")
  print("Slave :gmail-local:")
  print("Patterns *")
  print("Create Both")
  print("SyncState *")
  print("Expunge Both")
end

-- Setup commands for this module
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaAnalyzeMbsync', M.analyze_mbsync_config, {
    desc = 'Analyze mbsync configuration for issues'
  })
  
  vim.api.nvim_create_user_command('HimalayaShowExampleConfig', M.show_example_config, {
    desc = 'Show example Gmail mbsync configuration'
  })
end

return M