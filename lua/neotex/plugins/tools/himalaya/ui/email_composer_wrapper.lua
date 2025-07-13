-- Email Composer Wrapper
-- Redirects old email_composer calls to the new Maildir-based implementation
-- This allows gradual migration without breaking existing code

local M = {}

-- Import the Maildir-based composer
local maildir_composer = require('neotex.plugins.tools.himalaya.ui.email_composer_maildir')

-- Re-export all functions from the new composer
for k, v in pairs(maildir_composer) do
  M[k] = v
end

-- Compatibility shims for old API if needed

-- Old API: save_draft(buffer, trigger)
-- New API: save_draft(buffer, trigger) - same signature
-- No change needed

-- Old API: sync_draft_to_remote(draft, content) 
-- New API: Not needed - mbsync handles it
M.sync_draft_to_remote = function(draft, content)
  -- No-op - mbsync handles remote sync automatically
  return true
end

-- Old API: update_ui_after_save(draft)
-- New API: Not needed - UI updates handled in save_draft
M.update_ui_after_save = function(draft)
  -- No-op for compatibility
end

-- Old API: parse_headers_for_display(lines)
-- New API: Not used, but provide for compatibility
M.parse_headers_for_display = function(lines)
  local headers = {}
  local in_body = false
  
  for _, line in ipairs(lines) do
    if in_body then
      break
    elseif line == '' then
      in_body = true
    else
      local header, value = line:match('^([^:]+):%s*(.*)$')
      if header then
        headers[header:lower()] = value
      end
    end
  end
  
  return headers
end

return M