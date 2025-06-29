-- Test script for OAuth functionality
-- Run with :luafile %

local oauth = require("neotex.plugins.tools.himalaya.sync.oauth")
local logger = require("neotex.plugins.tools.himalaya.core.logger")

logger.info("=== OAuth Test Script ===")

-- Test 1: Check environment loading
logger.info("Test 1: Loading environment variables...")
local env = oauth.load_environment()
if env.GMAIL_CLIENT_ID then
  logger.info("  Environment loaded successfully")
else
  logger.warn("  GMAIL_CLIENT_ID not found in environment")
end

-- Test 2: Check token status
logger.info("Test 2: Checking OAuth token status...")
local status = oauth.get_status()
logger.info("  Has token: " .. tostring(status.has_token))
logger.info("  Environment loaded: " .. tostring(status.environment_loaded))
logger.info("  Last refresh: " .. (status.last_refresh > 0 and os.date("%Y-%m-%d %H:%M:%S", status.last_refresh) or "never"))

-- Test 3: Try ensure_token
logger.info("Test 3: Testing ensure_token function...")
oauth.ensure_token('gmail', function(success, error)
  if success then
    logger.info("  Token successfully ensured!")
  else
    logger.error("  Failed to ensure token: " .. (error or "unknown error"))
  end
  
  -- Final status check
  logger.info("Final status check:")
  local final_status = oauth.get_status()
  logger.info("  Has token: " .. tostring(final_status.has_token))
end)