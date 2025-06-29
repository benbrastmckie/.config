-- Debug OAuth token lookup
-- Run with :luafile %

local logger = require("neotex.plugins.tools.himalaya.core.logger")

logger.info("=== OAuth Token Debug ===")

-- Test 1: Direct secret-tool lookup
logger.info("Test 1: Direct secret-tool lookup")
local cmds = {
  {
    name = "Access Token",
    cmd = "secret-tool lookup service himalaya-cli username gmail-smtp-oauth2-access-token 2>/dev/null | head -c 20"
  },
  {
    name = "Refresh Token", 
    cmd = "secret-tool lookup service himalaya-cli username gmail-smtp-oauth2-refresh-token 2>/dev/null | wc -c"
  },
  {
    name = "Client Secret",
    cmd = "secret-tool lookup service himalaya-cli username gmail-smtp-oauth2-client-secret 2>/dev/null | wc -c"
  }
}

for _, test in ipairs(cmds) do
  local handle = io.popen(test.cmd)
  if handle then
    local result = handle:read('*a')
    handle:close()
    logger.info("  " .. test.name .. ": " .. (result ~= "" and result or "empty"))
  end
end

-- Test 2: Check OAuth module
logger.info("\nTest 2: OAuth module functions")
local oauth = require("neotex.plugins.tools.himalaya.sync.oauth")
logger.info("  has_token(): " .. tostring(oauth.has_token()))

-- Test 3: Get full status
logger.info("\nTest 3: Full OAuth status")
local status = oauth.get_status()
logger.info("  Has token: " .. tostring(status.has_token))
logger.info("  Token info:")
if status.token_info then
  logger.info("    Access token: " .. tostring(status.token_info.has_access_token))
  logger.info("    Refresh token: " .. tostring(status.token_info.has_refresh_token))
  logger.info("    Client secret: " .. tostring(status.token_info.has_client_secret))
end