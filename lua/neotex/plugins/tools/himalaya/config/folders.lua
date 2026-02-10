-- Folder Configuration Module
-- Manages folder mappings between IMAP and local names, and maildir paths

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Module state
local module_state = {
  folder_configs = {},
  maildir_root = nil
}

-- Default folder configurations
-- Gmail: OAuth2 authentication via Google APIs
-- Logos: Password authentication via Protonmail Bridge (127.0.0.1)
M.defaults = {
  gmail = {
    -- Maildir settings (discovered requirements)
    maildir_path = "~/Mail/Gmail/", -- Trailing slash REQUIRED for Maildir++

    -- Folder name mapping (IMAP -> Local)
    folder_map = {
      ["INBOX"] = "INBOX",
      ["[Gmail]/All Mail"] = "All_Mail",
      ["[Gmail]/Sent Mail"] = "Sent",
      ["[Gmail]/Drafts"] = "Drafts",
      ["[Gmail]/Trash"] = "Trash",
      ["[Gmail]/Spam"] = "Spam",
      ["[Gmail]/Starred"] = "Starred",
      ["[Gmail]/Important"] = "Important",
    },

    -- Reverse mapping for operations (Local -> IMAP)
    local_to_imap = {
      ["INBOX"] = "INBOX",
      ["All_Mail"] = "[Gmail]/All Mail",
      ["Sent"] = "[Gmail]/Sent Mail",
      ["Drafts"] = "[Gmail]/Drafts",
      ["Trash"] = "[Gmail]/Trash",
      ["Spam"] = "[Gmail]/Spam",
      ["Starred"] = "[Gmail]/Starred",
      ["Important"] = "[Gmail]/Important",
    }
  },

  -- Logos Labs (Protonmail Bridge) - uses password auth, not OAuth
  -- Folder names match mbsync channels: INBOX, Sent, Drafts, Trash, Archive
  logos = {
    -- Maildir settings
    maildir_path = "~/Mail/Logos/", -- Trailing slash REQUIRED for Maildir++

    -- Folder name mapping (IMAP -> Local)
    -- Protonmail uses simple folder names without prefix hierarchy
    folder_map = {
      ["INBOX"] = "INBOX",
      ["Sent"] = "Sent",
      ["Drafts"] = "Drafts",
      ["Trash"] = "Trash",
      ["Archive"] = "Archive",
    },

    -- Reverse mapping for operations (Local -> IMAP)
    local_to_imap = {
      ["INBOX"] = "INBOX",
      ["Sent"] = "Sent",
      ["Drafts"] = "Drafts",
      ["Trash"] = "Trash",
      ["Archive"] = "Archive",
    }
  }
}

-- Initialize module with configuration
function M.init(config)
  -- Extract folder configurations from accounts
  module_state.folder_configs = {}
  
  if config.accounts then
    for account_name, account_config in pairs(config.accounts) do
      module_state.folder_configs[account_name] = {
        maildir_path = account_config.maildir_path or M.defaults[account_name] and M.defaults[account_name].maildir_path,
        folder_map = account_config.folder_map or M.defaults[account_name] and M.defaults[account_name].folder_map or {},
        local_to_imap = account_config.local_to_imap or M.defaults[account_name] and M.defaults[account_name].local_to_imap or {}
      }
    end
  end
  
  -- Set maildir root from sync config
  if config.sync and config.sync.maildir_root then
    module_state.maildir_root = config.sync.maildir_root
  end
  
  logger.debug('Folders module initialized', {
    account_count = vim.tbl_count(module_state.folder_configs),
    maildir_root = module_state.maildir_root
  })
end

-- Get local folder name from IMAP name
function M.get_local_folder_name(imap_name, account_name)
  local folder_config = module_state.folder_configs[account_name]
  if folder_config and folder_config.folder_map then
    return folder_config.folder_map[imap_name] or imap_name
  end
  return imap_name
end

-- Get IMAP folder name from local name
function M.get_imap_folder_name(local_name, account_name)
  local folder_config = module_state.folder_configs[account_name]
  if folder_config and folder_config.local_to_imap then
    return folder_config.local_to_imap[local_name] or local_name
  end
  return local_name
end

-- Get maildir path for an account
function M.get_maildir_path(account_name)
  -- First check account-specific configuration
  local folder_config = module_state.folder_configs[account_name]
  if folder_config and folder_config.maildir_path then
    return vim.fn.expand(folder_config.maildir_path)
  end
  
  -- Then check if we have a maildir_root configured
  if module_state.maildir_root then
    return vim.fn.expand(module_state.maildir_root .. '/' .. account_name .. '/')
  end
  
  -- Default fallback
  return vim.fn.expand('~/Mail/' .. account_name .. '/')
end

-- Get full path to a specific folder
function M.get_folder_path(account_name, folder_name)
  local maildir_path = M.get_maildir_path(account_name)
  local local_folder = M.get_local_folder_name(folder_name, account_name)
  
  -- INBOX is special - no dot prefix
  if local_folder == 'INBOX' then
    return maildir_path .. 'INBOX'
  end
  
  -- Handle folders that already have dots
  if local_folder:match("^%.") then
    return maildir_path .. local_folder
  else
    return maildir_path .. '.' .. local_folder
  end
end

-- Get all folders for an account
function M.get_all_folders(account_name)
  local folder_config = module_state.folder_configs[account_name]
  if not folder_config then
    return {}
  end
  
  local folders = {}
  -- Get from folder_map
  if folder_config.folder_map then
    for imap_name, local_name in pairs(folder_config.folder_map) do
      table.insert(folders, {
        imap_name = imap_name,
        local_name = local_name
      })
    end
  end
  
  return folders
end

-- Check if a folder exists in configuration
function M.has_folder(account_name, folder_name)
  local folder_config = module_state.folder_configs[account_name]
  if not folder_config then
    return false
  end
  
  -- Check if it's an IMAP name
  if folder_config.folder_map and folder_config.folder_map[folder_name] then
    return true
  end
  
  -- Check if it's a local name
  if folder_config.local_to_imap and folder_config.local_to_imap[folder_name] then
    return true
  end
  
  return false
end

-- Update folder mapping for an account
function M.update_folder_mapping(account_name, imap_name, local_name)
  local folder_config = module_state.folder_configs[account_name]
  if not folder_config then
    module_state.folder_configs[account_name] = {
      folder_map = {},
      local_to_imap = {}
    }
    folder_config = module_state.folder_configs[account_name]
  end
  
  -- Update both mappings
  folder_config.folder_map[imap_name] = local_name
  folder_config.local_to_imap[local_name] = imap_name
  
  logger.info('Folder mapping updated', {
    account = account_name,
    imap = imap_name,
    local_name = local_name
  })
end

-- Get maildir root directory
function M.get_maildir_root()
  return module_state.maildir_root
end

-- Set maildir root directory
function M.set_maildir_root(path)
  module_state.maildir_root = path
  logger.info('Maildir root updated', { path = path })
end

-- Get special folders (Drafts, Sent, Trash)
function M.get_special_folders(account_name)
  local folder_config = module_state.folder_configs[account_name]
  
  -- If we have mappings, try to find special folders
  if folder_config and folder_config.folder_map then
    local special = {
      drafts = nil,
      sent = nil,
      trash = nil
    }
    
    -- Look for common patterns in folder mappings
    for imap_name, local_name in pairs(folder_config.folder_map) do
      if imap_name:match('Drafts') then
        special.drafts = local_name
      elseif imap_name:match('Sent') then
        special.sent = local_name
      elseif imap_name:match('Trash') then
        special.trash = local_name
      end
    end
    
    -- Use found mappings or defaults
    return {
      drafts = special.drafts or 'Drafts',
      sent = special.sent or 'Sent',
      trash = special.trash or 'Trash'
    }
  end
  
  -- Default special folders
  return {
    drafts = 'Drafts',
    sent = 'Sent',
    trash = 'Trash'
  }
end

return M