-- Gmail IMAP Settings Diagnostics
-- Tools to verify and guide users through Gmail web interface settings

local M = {}

-- Check Gmail IMAP settings via user guidance
function M.check_gmail_settings()
  print("=== Gmail IMAP Settings Verification ===")
  print()
  print("Please check the following settings in your Gmail web interface:")
  print()
  print("1. Go to Gmail → Settings (gear icon) → 'See all settings' → Labels")
  print("2. Under 'System labels', verify these settings:")
  print("   ✓ Inbox: 'Show in IMAP' should be CHECKED")
  print("   ✓ Sent Mail: 'Show in IMAP' should be CHECKED") 
  print("   ✓ Drafts: 'Show in IMAP' should be CHECKED")
  print("   ✓ All Mail: 'Show in IMAP' should be CHECKED")
  print("   ✓ Spam: 'Show in IMAP' should be CHECKED")
  print("   ✓ Trash: 'Show in IMAP' should be CHECKED  ← KEY SETTING")
  print()
  print("3. Go to 'Forwarding and POP/IMAP' tab:")
  print("   ✓ 'When I mark a message in IMAP as deleted:'")
  print("     → Should be 'Auto-Expunge off' (recommended)")
  print("   ✓ 'When a message is marked as deleted and expunged:'")
  print("     → Should be 'Move the message to the Bin'")
  print()
  print("💡 Tips:")
  print("- Changes may take 5-10 minutes to take effect")
  print("- Try logging out and back into Gmail if changes don't appear")
  print("- Some G Suite/Workspace accounts may have restricted settings")
  print()
  print("After checking/changing these settings:")
  print("- Try running :HimalayaListFolders again to see if Trash appears")
  print("- If Trash still doesn't appear, run :HimalayaAnalyzeMbsync next")
end

-- Provide detailed explanation of Gmail IMAP behavior
function M.explain_gmail_imap()
  print("=== Understanding Gmail IMAP Behavior ===")
  print()
  print("📧 How Gmail IMAP Works:")
  print("• Gmail uses labels instead of traditional folders")
  print("• IMAP folders are created from Gmail labels")
  print("• System labels (Inbox, Sent, Trash) can be hidden from IMAP")
  print("• All emails are stored in 'All Mail' unless explicitly deleted")
  print()
  print("🗂️ Gmail System Labels:")
  print("• [Gmail]/All Mail - Contains all emails (Gmail's archive)")
  print("• [Gmail]/Sent Mail - Sent messages")
  print("• [Gmail]/Drafts - Draft messages")
  print("• [Gmail]/Trash - Deleted messages (30-day retention)")
  print("• [Gmail]/Spam - Spam/junk messages")
  print("• [Gmail]/Important - Important messages (if enabled)")
  print()
  print("⚙️ 'Show in IMAP' Setting:")
  print("• Controls whether a label appears as an IMAP folder")
  print("• When disabled, the folder is invisible to email clients")
  print("• Must be enabled for Himalaya to see and use the folder")
  print()
  print("🔄 Delete Behavior:")
  print("• Gmail can auto-expunge (permanently delete) or move to Trash")
  print("• Recommended: Disable auto-expunge, move to Trash instead")
  print("• This preserves emails for 30 days before permanent deletion")
end

-- Interactive troubleshooting guide
function M.interactive_troubleshooting()
  print("=== Interactive Gmail IMAP Troubleshooting ===")
  print()
  
  local questions = {
    {
      question = "Can you see Gmail's web interface and access Settings?",
      yes_action = "Great! Continue with the settings verification.",
      no_action = "Check your internet connection and Gmail login status."
    },
    {
      question = "Do you see the 'Labels' tab in Gmail Settings?",
      yes_action = "Perfect! Look for the 'System labels' section.",
      no_action = "You might be using an old Gmail interface. Try the new Gmail interface."
    },
    {
      question = "Can you see 'System labels' with Inbox, Sent Mail, Trash, etc?",
      yes_action = "Excellent! Check if 'Show in IMAP' is enabled for each.",
      no_action = "This might be a G Suite/Workspace account with restricted access."
    },
    {
      question = "Is 'Show in IMAP' checked for the Trash label?",
      yes_action = "Good! The issue might be elsewhere. Check mbsync configuration.",
      no_action = "Found the problem! Enable 'Show in IMAP' for Trash and wait 5-10 minutes."
    }
  }
  
  for i, q in ipairs(questions) do
    print(string.format("%d. %s", i, q.question))
    print("   ✓ YES: " .. q.yes_action)
    print("   ✗ NO:  " .. q.no_action)
    print()
  end
  
  print("🔍 Additional Checks:")
  print("• Account type: Personal Gmail vs G Suite/Workspace")
  print("• Admin restrictions: Some organizations disable IMAP settings")
  print("• Two-factor authentication: Ensure app passwords are set up correctly")
  print("• IMAP access: Verify IMAP is enabled in 'Forwarding and POP/IMAP' settings")
end

-- Setup commands for this module
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaCheckGmailSettings', M.check_gmail_settings, {
    desc = 'Guide through Gmail IMAP settings verification'
  })
  
  vim.api.nvim_create_user_command('HimalayaExplainGmailIMAP', M.explain_gmail_imap, {
    desc = 'Explain how Gmail IMAP works and common issues'
  })
  
  vim.api.nvim_create_user_command('HimalayaTroubleshootGmail', M.interactive_troubleshooting, {
    desc = 'Interactive Gmail IMAP troubleshooting guide'
  })
end

return M