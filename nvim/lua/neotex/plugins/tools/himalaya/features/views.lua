-- View Management for Himalaya
-- Provides interface for multi-account view modes

local M = {}

local multi_account = require('neotex.plugins.tools.himalaya.ui.multi_account')

-- Show unified inbox view (all accounts combined)
function M.show_unified_inbox()
  multi_account.create_unified_view()
end

-- Show split view (side-by-side accounts)
function M.show_split_view()
  multi_account.create_split_view()
end

-- Show tabbed view (accounts in tabs)
function M.show_tabbed_view()
  multi_account.create_tabbed_view()
end

-- Show focused view (single account)
function M.show_focused_view()
  multi_account.create_focused_view()
end

-- Toggle between view modes
function M.toggle_view_mode()
  multi_account.toggle_mode()
end

return M