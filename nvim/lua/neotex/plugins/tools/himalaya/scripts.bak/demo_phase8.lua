-- Himalaya Phase 8 Feature Demo Script
-- Shows how to use all the new Phase 8 features
-- Usage: :HimalayaDemoPhase8

local M = {}

function M.demo()
  local notify = require('neotex.util.notifications')
  
  notify.himalaya("=== Himalaya Phase 8 Feature Demo ===", notify.categories.USER_ACTION)
  
  local demos = {
    {
      title = "1. Multiple Account Support",
      commands = {
        ":HimalayaAccountList - View all configured email accounts",
        ":HimalayaAccountSwitch gmail - Switch to gmail account", 
        ":HimalayaUnifiedInbox - View emails from all accounts in one view"
      }
    },
    {
      title = "2. Attachment Management",
      commands = {
        "Open an email with attachments, then:",
        ":HimalayaAttachments - List all attachments in current email",
        ":HimalayaAttachmentView - Interactive picker to view attachment",
        ":HimalayaAttachmentSave 1 ~/Downloads/ - Save attachment 1"
      }
    },
    {
      title = "3. Trash System",
      commands = {
        "Press 'd' on an email in the list to move to trash",
        ":HimalayaTrashList - View all emails in trash",
        ":HimalayaTrashRecover <id> - Recover email from trash",
        ":HimalayaTrashEmpty - Permanently delete all trash (with confirmation)"
      }
    },
    {
      title = "4. Email Headers",
      commands = {
        "Open any email, then:",
        ":HimalayaHeaders - View all headers for current email",
        "Custom headers can be added when composing emails"
      }
    },
    {
      title = "5. Image Display", 
      commands = {
        "Open an email with images, then:",
        ":HimalayaImageView - Display images in terminal",
        "Supports: Kitty, iTerm2, Sixel, Unicode blocks, ASCII art"
      }
    },
    {
      title = "6. Contact Management",
      commands = {
        ":HimalayaContacts - View all contacts",
        ":HimalayaContacts john - Search for 'john'",
        ":HimalayaContactAdd john@example.com 'John Doe' - Add contact",
        ":HimalayaContactScan - Extract contacts from existing emails"
      }
    }
  }
  
  -- Create floating window with demo info
  local float = require('neotex.plugins.tools.himalaya.ui.float')
  local lines = {
    "╔═══════════════════════════════════════════════════════╗",
    "║           Himalaya Phase 8 Feature Demo               ║", 
    "╚═══════════════════════════════════════════════════════╝",
    ""
  }
  
  for _, demo in ipairs(demos) do
    table.insert(lines, "▶ " .. demo.title)
    table.insert(lines, "")
    for _, cmd in ipairs(demo.commands) do
      table.insert(lines, "  " .. cmd)
    end
    table.insert(lines, "")
  end
  
  table.insert(lines, "────────────────────────────────────────────────────")
  table.insert(lines, "")
  table.insert(lines, "Tips:")
  table.insert(lines, "• Use :HimalayaTestPhase8 for interactive testing")
  table.insert(lines, "• All features maintain backward compatibility")
  table.insert(lines, "• Check :HimalayaHealth for configuration status")
  table.insert(lines, "")
  table.insert(lines, "Press 'q' or <Esc> to close this window")
  
  float.show('Phase 8 Feature Demo', lines)
end

-- Quick test function to verify all modules load
function M.verify_modules()
  local modules = {
    'features.accounts',
    'features.attachments', 
    'features.trash',
    'features.headers',
    'features.images',
    'features.contacts',
    'core.commands.features',
    'ui.features'
  }
  
  local notify = require('neotex.util.notifications')
  local all_ok = true
  
  notify.himalaya("Verifying Phase 8 modules...", notify.categories.STATUS)
  
  for _, module in ipairs(modules) do
    local ok, _ = pcall(require, 'neotex.plugins.tools.himalaya.' .. module)
    if ok then
      notify.himalaya("✓ " .. module, notify.categories.STATUS)
    else
      notify.himalaya("✗ " .. module, notify.categories.ERROR)
      all_ok = false
    end
  end
  
  if all_ok then
    notify.himalaya("All Phase 8 modules loaded successfully!", notify.categories.USER_ACTION)
  else
    notify.himalaya("Some modules failed to load", notify.categories.ERROR)
  end
end

return M