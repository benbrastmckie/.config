-- Debug sync configuration
-- Run with :luafile %

local logger = require("neotex.plugins.tools.himalaya.core.logger")
local config = require("neotex.plugins.tools.himalaya.core.config")
local mbsync = require("neotex.plugins.tools.himalaya.sync.mbsync")

logger.info("=== Sync Configuration Debug ===")

-- Get account info
local account = config.get_current_account()
logger.info("Current account: " .. (account.name or 'gmail'))
logger.info("Maildir path: " .. (account.maildir_path or 'not set'))
logger.info("Inbox channel: " .. (account.mbsync and account.mbsync.inbox_channel or 'not set'))

-- Check mbsync binary
logger.info("\nChecking mbsync:")
local has_mbsync = mbsync.check_mbsync()
logger.info("  mbsync found: " .. tostring(has_mbsync))

-- Check mbsync config
logger.info("\nChecking mbsync config file:")
local mbsyncrc = vim.fn.expand("~/.mbsyncrc")
local exists = vim.fn.filereadable(mbsyncrc) == 1
logger.info("  ~/.mbsyncrc exists: " .. tostring(exists))

if exists then
  -- Check if gmail-inbox channel exists
  local handle = io.popen('grep -q "^Channel.*gmail-inbox" ~/.mbsyncrc 2>/dev/null && echo "found" || echo "not found"')
  if handle then
    local result = handle:read('*a'):gsub('\n', '')
    handle:close()
    logger.info("  gmail-inbox channel: " .. result)
  end
end

-- Test sync command
logger.info("\nTesting mbsync command directly:")
local test_cmd = "mbsync -l gmail-inbox 2>&1 | head -10"
local handle = io.popen(test_cmd)
if handle then
  local output = handle:read('*a')
  handle:close()
  logger.info("mbsync output:")
  for line in output:gmatch('[^\n]+') do
    logger.info("  " .. line)
  end
end