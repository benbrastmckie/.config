-- Himalaya Phase 9 Feature Demonstration Script
-- Shows practical examples of Phase 9 features
-- Usage: :lua require('neotex.plugins.tools.himalaya.scripts.demo_phase9').interactive_demo()

local M = {}

-- Helper function to show a message with delay
local function show_message(message, category, delay)
  delay = delay or 0
  vim.defer_fn(function()
    require('neotex.util.notifications').himalaya(message, category)
  end, delay)
end

-- Demo 1: Undo Send System
function M.demo_undo_send()
  local notify = require('neotex.util.notifications')
  
  notify.himalaya("=== Phase 9 Demo: Undo Send System ===", notify.categories.USER_ACTION)
  
  show_message("The Undo Send System provides a 60-second delay before sending emails", notify.categories.STATUS, 1000)
  show_message("When composing an email, you'll see send options:", notify.categories.STATUS, 2000)
  show_message("  • Send Now (immediate)", notify.categories.STATUS, 3000)
  show_message("  • Send with Undo (60s delay)", notify.categories.STATUS, 4000)
  show_message("  • Schedule Later (coming soon)", notify.categories.STATUS, 5000)
  
  show_message("Commands to try:", notify.categories.USER_ACTION, 6500)
  show_message("  :HimalayaWrite - Compose email (choose 'Send with Undo')", notify.categories.STATUS, 7500)
  show_message("  :HimalayaSendQueue - View queued emails", notify.categories.STATUS, 8500)
  show_message("  :HimalayaUndoSend - Cancel a queued email", notify.categories.STATUS, 9500)
  
  show_message("Demo complete! Try composing an email to see it in action.", notify.categories.USER_ACTION, 11000)
end

-- Demo 2: Advanced Search
function M.demo_advanced_search()
  local notify = require('neotex.util.notifications')
  
  notify.himalaya("=== Phase 9 Demo: Advanced Search ===", notify.categories.USER_ACTION)
  
  show_message("Advanced Search supports Gmail-style operators", notify.categories.STATUS, 1000)
  show_message("Search examples:", notify.categories.USER_ACTION, 2000)
  
  local examples = {
    "from:john@example.com - Find emails from specific sender",
    "subject:meeting has:attachment - Meeting emails with attachments",
    "after:2024-01-01 before:2024-12-31 - Date range search",
    "is:unread from:github.com - Unread emails from GitHub",
    "newer_than:7d larger:10MB - Recent large emails",
    "\"exact phrase\" OR alternative - Phrase or keyword search"
  }
  
  for i, example in ipairs(examples) do
    show_message("  " .. example, notify.categories.STATUS, 2000 + i * 1000)
  end
  
  show_message("Commands to try:", notify.categories.USER_ACTION, 9000)
  show_message("  :HimalayaSearch - Open search UI", notify.categories.STATUS, 10000)
  show_message("  :HimalayaSearch from:example.com - Direct search", notify.categories.STATUS, 11000)
  show_message("  :HimalayaSearchClear - Clear search cache", notify.categories.STATUS, 12000)
  
  show_message("Demo complete! Try searching your emails.", notify.categories.USER_ACTION, 13500)
end

-- Demo 3: Email Templates
function M.demo_email_templates()
  local notify = require('neotex.util.notifications')
  
  notify.himalaya("=== Phase 9 Demo: Email Templates ===", notify.categories.USER_ACTION)
  
  show_message("Email Templates make composing common emails faster", notify.categories.STATUS, 1000)
  show_message("Built-in templates available:", notify.categories.USER_ACTION, 2000)
  
  local templates = {
    "Meeting Request - Schedule meetings with time options",
    "Follow Up - Follow up on previous communication",
    "Thank You - Express gratitude professionally",
    "Out of Office - Automatic reply setup"
  }
  
  for i, template in ipairs(templates) do
    show_message("  • " .. template, notify.categories.STATUS, 2000 + i * 1000)
  end
  
  show_message("Template features:", notify.categories.USER_ACTION, 7000)
  show_message("  • Variable substitution: {{name}}, {{date}}", notify.categories.STATUS, 8000)
  show_message("  • Conditional content: {{#if urgent}}...{{/if}}", notify.categories.STATUS, 9000)
  show_message("  • System variables: {{current_date}}, {{sender_name}}", notify.categories.STATUS, 10000)
  
  show_message("Commands to try:", notify.categories.USER_ACTION, 11500)
  show_message("  :HimalayaTemplates - Manage templates", notify.categories.STATUS, 12500)
  show_message("  :HimalayaTemplateUse - Use template to compose", notify.categories.STATUS, 13500)
  show_message("  :HimalayaTemplateNew - Create custom template", notify.categories.STATUS, 14500)
  show_message("  :HimalayaWrite - Compose (offers template option)", notify.categories.STATUS, 15500)
  
  show_message("Demo complete! Try using a template.", notify.categories.USER_ACTION, 17000)
end

-- Demo 4: Show Phase 9 Overview
function M.demo_overview()
  local notify = require('neotex.util.notifications')
  
  notify.himalaya("=== Phase 9 Himalaya Feature Overview ===", notify.categories.USER_ACTION)
  
  show_message("✅ IMPLEMENTED FEATURES:", notify.categories.USER_ACTION, 1000)
  show_message("1. Undo Send System - 60-second delay with cancellation", notify.categories.STATUS, 2000)
  show_message("2. Advanced Search - Gmail-style operators and filters", notify.categories.STATUS, 3000)
  show_message("3. Email Templates - Variable substitution and presets", notify.categories.STATUS, 4000)
  
  show_message("⏳ COMING SOON:", notify.categories.STATUS, 5500)
  show_message("4. Email Scheduling - Send emails at specific times", notify.categories.STATUS, 6500)
  show_message("5. Multiple Account Views - Unified, split, tabbed views", notify.categories.STATUS, 7500)
  show_message("6. Window Management - Better coordination and layouts", notify.categories.STATUS, 8500)
  
  show_message("🚀 HOW TO GET STARTED:", notify.categories.USER_ACTION, 10000)
  show_message("1. Run :HimalayaTestPhase9 to test features", notify.categories.STATUS, 11000)
  show_message("2. Try :HimalayaWrite and explore send options", notify.categories.STATUS, 12000)
  show_message("3. Use :HimalayaSearch to find emails quickly", notify.categories.STATUS, 13000)
  show_message("4. Create templates with :HimalayaTemplates", notify.categories.STATUS, 14000)
  
  show_message("Phase 9 brings powerful email productivity features!", notify.categories.USER_ACTION, 15500)
end

-- Interactive demo menu
function M.interactive_demo()
  local demo_options = {
    { name = "1. Undo Send System Demo", fn = M.demo_undo_send },
    { name = "2. Advanced Search Demo", fn = M.demo_advanced_search },
    { name = "3. Email Templates Demo", fn = M.demo_email_templates },
    { name = "4. Phase 9 Overview", fn = M.demo_overview },
    { name = "5. Run Feature Tests", fn = function()
      require('neotex.plugins.tools.himalaya.scripts.test_phase9').interactive_test()
    end },
  }
  
  vim.ui.select(demo_options, {
    prompt = "Select a Phase 9 demo:",
    format_item = function(item)
      return item.name
    end
  }, function(choice)
    if choice and choice.fn then
      choice.fn()
    end
  end)
end

-- Command to show all Phase 9 commands
function M.show_all_commands()
  local float = require('neotex.plugins.tools.himalaya.ui.float')
  
  local lines = {
    "╭─────────────────────────────────────────────────────────╮",
    "│                 Phase 9 Command Reference               │",
    "├─────────────────────────────────────────────────────────┤",
    "",
    "📧 EMAIL COMPOSITION:",
    "  :HimalayaWrite [to] - Compose email (offers templates)",
    "",
    "⏰ UNDO SEND SYSTEM:",
    "  :HimalayaSendQueue - Show queued emails with timers",
    "  :HimalayaUndoSend [id] - Cancel queued email",
    "",
    "🔍 ADVANCED SEARCH:",
    "  :HimalayaSearch [query] - Search with operators",
    "  :HimalayaSearchClear - Clear search cache",
    "",
    "📧 EMAIL TEMPLATES:",
    "  :HimalayaTemplates - Template management UI",
    "  :HimalayaTemplateNew - Create new template",
    "  :HimalayaTemplateEdit [id] - Edit template",
    "  :HimalayaTemplateDelete [id] - Delete template",
    "  :HimalayaTemplateUse [id] - Use template to compose",
    "",
    "🧪 TESTING & DEMOS:",
    "  :HimalayaTestPhase9 - Run feature tests",
    "  :lua require('...demo_phase9').interactive_demo()",
    "",
    "🔗 SEARCH OPERATORS:",
    "  Text: from: to: cc: subject: body: filename:",
    "  Date: date: before: after: newer_than: older_than:",
    "  Status: is: has: starred: attachment:",
    "  Size: size: larger: smaller:",
    "  Logic: OR, NOT, \"exact phrases\"",
    "",
    "📝 TEMPLATE VARIABLES:",
    "  {{variable}} - Basic substitution",
    "  {{#if var}}...{{/if}} - Conditional blocks",
    "  System vars: {{current_date}}, {{sender_name}}",
    "",
    "╰─────────────────────────────────────────────────────────╯"
  }
  
  float.show('Phase 9 Commands', lines)
end

return M