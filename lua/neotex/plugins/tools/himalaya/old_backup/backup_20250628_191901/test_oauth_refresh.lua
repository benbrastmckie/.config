-- Test OAuth Refresh Module
-- Commands to test automatic OAuth token refresh

local M = {}

local notify = require('neotex.util.notifications')

-- Test 1: Simulate expired token by clearing the current one
function M.test_expired_token()
  notify.himalaya('=== Testing OAuth Refresh (Simulated Expired Token) ===', notify.categories.USER_ACTION)
  
  -- Step 1: Backup current token
  local backup_cmd = 'secret-tool lookup service himalaya-cli username gmail-smtp-oauth2-access-token > /tmp/oauth-token-backup 2>/dev/null'
  os.execute(backup_cmd)
  
  notify.himalaya('1. Backed up current token', notify.categories.STATUS)
  
  -- Step 2: Replace with an invalid token to simulate expiration
  local invalid_token = 'ya29.INVALID_TOKEN_TO_SIMULATE_EXPIRATION'
  local replace_cmd = string.format(
    'echo "%s" | secret-tool store --label="Gmail OAuth2 Access Token (test)" service himalaya-cli username gmail-smtp-oauth2-access-token',
    invalid_token
  )
  os.execute(replace_cmd)
  
  notify.himalaya('2. Replaced token with invalid one to simulate expiration', notify.categories.STATUS)
  notify.himalaya('3. Now run :HimalayaSyncInbox - it should detect the bad token and auto-refresh', notify.categories.INFO)
  notify.himalaya('4. After test, run :HimalayaTestRestore to restore your backup', notify.categories.WARNING)
end

-- Test 2: Check refresh service directly
function M.test_refresh_service()
  notify.himalaya('=== Testing OAuth Refresh Service ===', notify.categories.USER_ACTION)
  
  -- Check service status
  local status_cmd = 'systemctl --user status gmail-oauth2-refresh.service | head -10'
  local status = vim.fn.system(status_cmd)
  
  notify.himalaya('Current service status:', notify.categories.INFO)
  for line in status:gmatch('[^\r\n]+') do
    if line:match('Active:') or line:match('oauth') or line:match('OAuth') then
      notify.himalaya(line, notify.categories.STATUS)
    end
  end
  
  -- Trigger refresh
  notify.himalaya('\nTriggering manual refresh...', notify.categories.USER_ACTION)
  local refresh_result = os.execute('systemctl --user start gmail-oauth2-refresh.service 2>&1')
  
  if refresh_result == 0 then
    -- Wait and check result
    vim.defer_fn(function()
      local check_cmd = 'systemctl --user status gmail-oauth2-refresh.service | grep -A2 "Active:"'
      local result = vim.fn.system(check_cmd)
      notify.himalaya('\nRefresh result:', notify.categories.INFO)
      notify.himalaya(vim.trim(result), notify.categories.STATUS)
    end, 2000)
  else
    notify.himalaya('Failed to trigger refresh service', notify.categories.ERROR)
  end
end

-- Test 3: Force timeout scenario
function M.test_timeout_detection()
  notify.himalaya('=== Testing Timeout Detection ===', notify.categories.USER_ACTION)
  
  -- Create a test script that simulates mbsync timeout
  local test_script = [[#!/bin/bash
echo "Reading configuration file /home/benjamin/.mbsyncrc"
echo "Channel gmail-inbox"
echo "Opening far side store gmail-remote..."
echo "Connecting to imap.gmail.com..."
echo "Authenticating with SASL mechanism XOAUTH2..."
sleep 2
echo "Socket error on imap.gmail.com ([2607:f8b0:4023:c03::6d]:993): timeout."
exit 1
]]
  
  -- Write test script
  local script_path = '/tmp/test-mbsync-timeout'
  local f = io.open(script_path, 'w')
  if f then
    f:write(test_script)
    f:close()
    os.execute('chmod +x ' .. script_path)
    
    notify.himalaya('Created test script that simulates OAuth timeout', notify.categories.STATUS)
    notify.himalaya('The sync system should detect this and trigger auto-refresh', notify.categories.INFO)
    
    -- You could hook this into the sync system for testing
    -- For now, just show what would happen
    notify.himalaya('\nWhen this pattern is detected:', notify.categories.INFO)
    notify.himalaya('1. System detects "Socket error.*timeout" + "XOAUTH2"', notify.categories.STATUS)
    notify.himalaya('2. Triggers automatic OAuth refresh', notify.categories.STATUS)
    notify.himalaya('3. Retries sync with fresh token', notify.categories.STATUS)
  else
    notify.himalaya('Failed to create test script', notify.categories.ERROR)
  end
end

-- Restore backed up token
function M.restore_token()
  notify.himalaya('=== Restoring Backed Up Token ===', notify.categories.USER_ACTION)
  
  local restore_cmd = 'cat /tmp/oauth-token-backup 2>/dev/null | secret-tool store --label="Gmail OAuth2 Access Token (restored)" service himalaya-cli username gmail-smtp-oauth2-access-token'
  local result = os.execute(restore_cmd)
  
  if result == 0 then
    notify.himalaya('✅ Token restored successfully', notify.categories.SUCCESS)
    os.remove('/tmp/oauth-token-backup')
  else
    notify.himalaya('❌ Failed to restore token - you may need to run :HimalayaRefreshOAuth', notify.categories.ERROR)
  end
end

-- Check current token status
function M.check_token_status()
  notify.himalaya('=== Current OAuth Token Status ===', notify.categories.USER_ACTION)
  
  -- Get token age
  local token_time_cmd = 'stat -c %Y ~/.local/share/keyrings/login.keyring 2>/dev/null || echo 0'
  local token_time = tonumber(vim.fn.system(token_time_cmd)) or 0
  local current_time = os.time()
  local age_minutes = math.floor((current_time - token_time) / 60)
  
  notify.himalaya(string.format('Keyring last modified: %d minutes ago', age_minutes), notify.categories.INFO)
  
  -- Check last refresh
  local refresh_log = vim.fn.system('journalctl --user -u gmail-oauth2-refresh.service -n 5 --no-pager | grep -E "Started|Finished|OAuth2"')
  if refresh_log and refresh_log ~= '' then
    notify.himalaya('\nRecent refresh history:', notify.categories.INFO)
    for line in refresh_log:gmatch('[^\r\n]+') do
      notify.himalaya(line, notify.categories.STATUS)
    end
  end
  
  -- Next scheduled refresh
  local next_refresh = vim.fn.system('systemctl --user list-timers gmail-oauth2-refresh.timer --no-pager | grep gmail')
  if next_refresh and next_refresh ~= '' then
    notify.himalaya('\nNext scheduled refresh:', notify.categories.INFO)
    notify.himalaya(vim.trim(next_refresh), notify.categories.STATUS)
  end
end

return M