-- Himalaya Phase 8 Feature Testing Script
-- Interactive testing for all Phase 8 features
-- Usage: :HimalayaTestPhase8

local M = {}


-- Helper to check debug mode
local function is_debug_mode()
  local config = require('neotex.plugins.tools.himalaya.core.config')
  return config.get('debug_mode', false)
end

-- Test 1: Multiple Account Support
function M.test_accounts()
  local notify = require('neotex.util.notifications')
  local accounts = require('neotex.plugins.tools.himalaya.features.accounts')
  
  if is_debug_mode() then
    notify.himalaya("=== Testing Multiple Account Support ===", notify.categories.STATUS)
  end
  
  -- Test adding a demo account
  local demo_account = {
    name = 'demo_account',
    email = 'demo@example.com',
    type = 'imap',
    imap_host = 'imap.example.com',
    imap_port = 993,
    smtp_host = 'smtp.example.com',
    smtp_port = 587
  }
  
  -- Show current accounts
  vim.cmd('HimalayaAccountList')
  
  vim.defer_fn(function()
    -- Try to add demo account
    local result = accounts.add_account(demo_account)
    if result.success then
      notify.himalaya("✓ Demo account added successfully", notify.categories.USER_ACTION)
      notify.himalaya("Try: :HimalayaAccountSwitch demo_account", notify.categories.STATUS)
    else
      notify.himalaya("Demo account already exists or error: " .. tostring(result.error), notify.categories.STATUS)
    end
    
    -- Show unified inbox command
    notify.himalaya("Try: :HimalayaUnifiedInbox to see all accounts", notify.categories.STATUS)
  end, 1000)
end

-- Test 2: Attachment Features
function M.test_attachments()
  local notify = require('neotex.util.notifications')
  local ui = require('neotex.plugins.tools.himalaya.ui')
  
  notify.himalaya("=== Testing Attachment Features ===", notify.categories.STATUS)
  
  -- Check if we have an email open
  local email_id = ui.get_current_email_id()
  
  if email_id then
    notify.himalaya("Current email ID: " .. email_id, notify.categories.STATUS)
    vim.cmd('HimalayaAttachments')
  else
    notify.himalaya("No email selected. Open an email first, then run:", notify.categories.STATUS)
    notify.himalaya("  :HimalayaAttachments - List attachments", notify.categories.STATUS)
    notify.himalaya("  :HimalayaAttachmentView - View attachment", notify.categories.STATUS)
    notify.himalaya("  :HimalayaAttachmentSave <id> [path] - Save attachment", notify.categories.STATUS)
  end
end

-- Test 3: Trash System
function M.test_trash()
  local notify = require('neotex.util.notifications')
  local trash = require('neotex.plugins.tools.himalaya.features.trash')
  
  notify.himalaya("=== Testing Trash System ===", notify.categories.STATUS)
  
  -- Show trash stats
  local stats = trash.get_stats()
  notify.himalaya(string.format("Trash contains %d items, %s total", 
    stats.total, stats.human_size), notify.categories.STATUS)
  
  -- Show trash list
  vim.cmd('HimalayaTrashList')
  
  vim.defer_fn(function()
    notify.himalaya("Available trash commands:", notify.categories.STATUS)
    notify.himalaya("  :HimalayaTrashRecover <id> - Recover email", notify.categories.STATUS)
    notify.himalaya("  :HimalayaTrashEmpty - Empty trash (with confirmation)", notify.categories.STATUS)
    notify.himalaya("  'd' in email list - Move to trash", notify.categories.STATUS)
  end, 1000)
end

-- Test 4: Custom Headers
function M.test_headers()
  local notify = require('neotex.util.notifications')
  local headers = require('neotex.plugins.tools.himalaya.features.headers')
  local ui = require('neotex.plugins.tools.himalaya.ui')
  
  notify.himalaya("=== Testing Custom Headers ===", notify.categories.STATUS)
  
  -- Test header validation
  local test_headers = {
    ['X-Priority'] = '1',
    ['X-Custom-Tag'] = 'important',
    ['Organization'] = 'Test Org'
  }
  
  for name, value in pairs(test_headers) do
    local valid, err = headers.validate_header(name, value)
    if valid then
      notify.himalaya(string.format("✓ Valid header: %s: %s", name, value), notify.categories.STATUS)
    else
      notify.himalaya(string.format("✗ Invalid header: %s (%s)", name, err), notify.categories.ERROR)
    end
  end
  
  -- Show headers for current email
  local email_id = ui.get_current_email_id()
  if email_id then
    vim.cmd('HimalayaHeaders')
  else
    notify.himalaya("Open an email and run :HimalayaHeaders to view all headers", notify.categories.STATUS)
  end
end

-- Test 5: Image Display
function M.test_images()
  local notify = require('neotex.util.notifications')
  local images = require('neotex.plugins.tools.himalaya.features.images')
  
  notify.himalaya("=== Testing Image Display ===", notify.categories.STATUS)
  
  -- Detect available protocol
  local protocol = images.detect_protocol()
  
  if protocol then
    notify.himalaya("✓ Detected image protocol: " .. protocol, notify.categories.STATUS)
    
    -- Check for available tools
    local tools = {
      kitty = vim.fn.executable('kitten') == 1,
      sixel = vim.fn.executable('img2sixel') == 1,
      blocks = vim.fn.executable('chafa') == 1 or vim.fn.executable('timg') == 1,
      ascii = vim.fn.executable('jp2a') == 1 or vim.fn.executable('ascii-image-converter') == 1
    }
    
    notify.himalaya("Available image tools:", notify.categories.STATUS)
    for tool, available in pairs(tools) do
      notify.himalaya(string.format("  %s: %s", tool, available and "✓" or "✗"), notify.categories.STATUS)
    end
    
    notify.himalaya("Open an email with images and run :HimalayaImageView", notify.categories.STATUS)
  else
    notify.himalaya("✗ No image display protocol detected", notify.categories.ERROR)
    notify.himalaya("Install one of: kitty terminal, img2sixel, chafa, timg, jp2a", notify.categories.STATUS)
  end
end

-- Test 6: Contact Management
function M.test_contacts()
  local notify = require('neotex.util.notifications')
  
  notify.himalaya("=== Testing Contact Management ===", notify.categories.STATUS)
  
  -- Clear module cache to avoid loading errors
  package.loaded['neotex.plugins.tools.himalaya.features.contacts'] = nil
  package.loaded['neotex.plugins.tools.himalaya.utils.enhanced'] = nil
  
  -- Try to load contacts module with error handling
  local ok, contacts = pcall(require, 'neotex.plugins.tools.himalaya.features.contacts')
  if not ok then
    notify.himalaya("Failed to load contacts module: " .. tostring(contacts), notify.categories.ERROR)
    notify.himalaya("This might be due to a missing dependency or syntax error", notify.categories.STATUS)
    return
  end
  
  -- Add a test contact
  local test_contact = {
    email = 'test@example.com',
    name = 'Test User',
    organization = 'Test Organization',
    source = 'manual'
  }
  
  local result = contacts.add_contact(test_contact)
  if result.success then
    notify.himalaya("✓ Test contact added", notify.categories.USER_ACTION)
  end
  
  -- Search contacts
  local search_results = contacts.search('test', { limit = 5 })
  notify.himalaya(string.format("Found %d contacts matching 'test'", #search_results), notify.categories.STATUS)
  
  -- Show contacts
  vim.cmd('HimalayaContacts test')
  
  vim.defer_fn(function()
    notify.himalaya("Contact commands:", notify.categories.STATUS)
    notify.himalaya("  :HimalayaContacts [search] - List/search contacts", notify.categories.STATUS)
    notify.himalaya("  :HimalayaContactAdd <email> [name] - Add contact", notify.categories.STATUS)
    notify.himalaya("  :HimalayaContactScan - Scan emails for contacts", notify.categories.STATUS)
  end, 1000)
end

-- Test 7: Run all tests
function M.run_all_tests()
  local tests = {
    M.test_accounts,
    M.test_attachments,
    M.test_trash,
    M.test_headers,
    M.test_images,
    M.test_contacts
  }
  
  local notify = require('neotex.util.notifications')
  notify.himalaya("=== Running All Phase 8 Tests ===", notify.categories.STATUS)
  
  -- Run tests with delays
  for i, test in ipairs(tests) do
    vim.defer_fn(function()
      test()
    end, i * 2000)  -- 2 second delay between tests
  end
  
  vim.defer_fn(function()
    notify.himalaya("=== All Tests Complete ===", notify.categories.USER_ACTION)
  end, (#tests + 1) * 2000)
end

-- Test 8: Show available commands
function M.show_commands()
  local commands = require('neotex.plugins.tools.himalaya.core.commands')
  local float = require('neotex.plugins.tools.himalaya.ui.float')
  
  -- Get Phase 8 commands
  local all_commands = commands.list_commands()
  local phase8_patterns = {
    'Account', 'Attachment', 'Trash', 'Image', 'Contact', 'Header', 'Unified'
  }
  
  local phase8_commands = {}
  for _, cmd in ipairs(all_commands) do
    for _, pattern in ipairs(phase8_patterns) do
      if cmd:match(pattern) then
        table.insert(phase8_commands, cmd)
        break
      end
    end
  end
  
  -- Sort commands
  table.sort(phase8_commands)
  
  -- Create display
  local lines = {
    "╭─────────────────────────────────────────────╮",
    "│       Phase 8 Himalaya Commands             │",
    "├─────────────────────────────────────────────┤",
    "",
    "Account Management:",
    "  :HimalayaAccountList - List all accounts",
    "  :HimalayaAccountSwitch <name> - Switch account",
    "  :HimalayaUnifiedInbox - Show all accounts",
    "",
    "Attachments:",
    "  :HimalayaAttachments - List attachments",
    "  :HimalayaAttachmentView [id] - View attachment",
    "  :HimalayaAttachmentSave <id> [path] - Save",
    "",
    "Trash Management:",
    "  :HimalayaTrashList - Show trash",
    "  :HimalayaTrashRecover <id> - Recover email",
    "  :HimalayaTrashEmpty - Empty trash",
    "",
    "Other Features:",
    "  :HimalayaHeaders - Show email headers",
    "  :HimalayaImageView - View images in email",
    "  :HimalayaContacts [search] - List contacts",
    "  :HimalayaContactAdd <email> [name] - Add",
    "  :HimalayaContactScan - Scan for contacts",
    "",
    "╰─────────────────────────────────────────────╯"
  }
  
  float.show('Phase 8 Commands', lines)
end

-- Main interactive test function using Telescope
function M.interactive_test()
  local ok, telescope = pcall(require, 'telescope')
  if not ok then
    -- Fallback to vim.ui.select if Telescope not available
    M.interactive_test_fallback()
    return
  end
  
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  
  local test_options = {
    { name = "Test Multiple Account Support", fn = M.test_accounts, icon = "📧" },
    { name = "Test Attachment Features", fn = M.test_attachments, icon = "📎" },
    { name = "Test Trash System", fn = M.test_trash, icon = "🗑️" },
    { name = "Test Custom Headers", fn = M.test_headers, icon = "📋" },
    { name = "Test Image Display", fn = M.test_images, icon = "🖼️" },
    { name = "Test Contact Management", fn = M.test_contacts, icon = "👥" },
    { name = "Run All Tests", fn = M.run_all_tests, icon = "🚀" },
    { name = "Show Available Commands", fn = M.show_commands, icon = "📖" },
  }
  
  pickers.new({}, {
    prompt_title = "Himalaya Phase 8 Feature Tests",
    finder = finders.new_table {
      results = test_options,
      entry_maker = function(entry)
        return {
          value = entry,
          display = string.format("%s %s", entry.icon, entry.name),
          ordinal = entry.name,
        }
      end
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and selection.value.fn then
          selection.value.fn()
        end
      end)
      return true
    end,
  }):find()
end

-- Fallback function using vim.ui.select
function M.interactive_test_fallback()
  local test_options = {
    { name = "1. Test Multiple Account Support", fn = M.test_accounts },
    { name = "2. Test Attachment Features", fn = M.test_attachments },
    { name = "3. Test Trash System", fn = M.test_trash },
    { name = "4. Test Custom Headers", fn = M.test_headers },
    { name = "5. Test Image Display", fn = M.test_images },
    { name = "6. Test Contact Management", fn = M.test_contacts },
    { name = "7. Run All Tests", fn = M.run_all_tests },
    { name = "8. Show Available Commands", fn = M.show_commands },
  }
  
  vim.ui.select(test_options, {
    prompt = "Select a Phase 8 test:",
    format_item = function(item)
      return item.name
    end
  }, function(choice)
    if choice and choice.fn then
      choice.fn()
    end
  end)
end

return M