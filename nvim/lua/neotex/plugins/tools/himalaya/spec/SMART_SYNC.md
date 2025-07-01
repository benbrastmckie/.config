# Smart Sync Specification for Himalaya Email Client

## Implementation Status

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 1 | Smart Check Function (mbsync) | ❌ FAILED |
| Phase 2 | Smart Sync Command | ❌ FAILED |
| Phase 3 | Async Implementation | ❌ FAILED |
| Phase 4 | Keymap Integration | ❌ FAILED |
| Phase 5 | Himalaya IMAP Integration | ✅ COMPLETED |
| Phase 6 | Dual-Backend Configuration | ✅ COMPLETED |

**Current Status**: 
- mbsync dry-run approach (Phases 1-4) did not provide performance benefits - it added 55s overhead before the regular sync
- `<leader>mc` and HimalayaSmartSync have been removed 
- `<leader>mz` - Fast check now automatically uses gmail-imap account if configured
- Dual-backend approach implemented: maildir for reading, IMAP for checking

## Overview

This document specifies the implementation of a smart sync feature for the Himalaya email plugin that provides fast, responsive syncing while keeping local emails up to date. The feature will intelligently check for new emails and only sync what's necessary, avoiding slow full syncs when not needed.

## Design Principles

1. **Minimal New Modules**: Work within existing infrastructure, only adding new functions to existing modules
2. **Keymap Management**: All keymaps defined in which-key.lua, preserving existing functionality
3. **Incremental Migration**: Add new keymaps alongside existing ones, migrate once proven stable

## Research Summary

### Key Findings

1. **Himalaya is Stateless**: Himalaya itself doesn't handle synchronization - it only reads from IMAP or local Maildir
2. **mbsync for Synchronization**: All actual syncing is handled by mbsync
3. **Himalaya Reads Local First**: When a local Maildir exists (after mbsync), Himalaya reads from it, not from IMAP
4. **No --disable-cache Flag**: The `--disable-cache` flag doesn't exist in current Himalaya versions
5. **mbsync Dry-Run**: `mbsync --dry-run` can check for new emails without downloading them
6. **Incremental Sync**: mbsync supports `MaxMessages` to limit sync scope

### Current Implementation

- **Full Sync**: `HimalayaSyncFull` syncs all folders using mbsync channel "gmail"
- **Inbox Sync**: `HimalayaSyncInbox` syncs only inbox using mbsync channel "gmail-inbox"
- **OAuth Integration**: Auto-refresh OAuth tokens when authentication fails
- **Progress Tracking**: Complex progress parsing from mbsync output
- **Lock Management**: Prevents concurrent syncs

## Smart Sync Design

### Goals

1. **Fast Check**: Quickly determine if new emails exist
2. **Minimal Sync**: Only sync what's necessary (recent emails)
3. **User Feedback**: Clear status messages about sync state
4. **Integration**: Work seamlessly with existing sync infrastructure

### Implementation Strategy

#### Phase 1: Smart Check Function ✅ COMPLETED

**What it does**: Adds a new function to the existing `sync/mbsync.lua` module that checks if new emails exist on the server without downloading them.

**Why it's useful**: Currently, checking for new emails requires a full sync which can take 30+ seconds. This function uses `mbsync --dry-run` to check the IMAP server, returning results in 2-3 seconds.

**Implementation Details**:
- Uses `mbsync --dry-run --verbose` to check without syncing
- Parses output for "Far: +N" pattern where N is the number of new messages
- Supports both synchronous and asynchronous operation
- Includes OAuth token refresh on authentication errors

```lua
-- In sync/mbsync.lua
function M.check_new_emails(opts)
  opts = opts or {}
  local account = opts.account or config.get_current_account_name()
  local folder = opts.folder or 'INBOX'
  
  -- Get current local count
  local local_emails, total_count = utils.get_email_list(account, folder, 1, 200)
  local local_count = total_count or (local_emails and #local_emails) or 0
  
  -- Use mbsync in dry-run mode to check for new messages
  local account_config = config.get_current_account()
  local channel = account_config.mbsync and account_config.mbsync.inbox_channel or 'gmail-inbox'
  
  -- Run mbsync in dry-run mode
  local cmd = {'mbsync', '--dry-run', '--verbose', channel}
  local result = vim.fn.system(cmd)
  
  -- Parse output for "Far: +5" which means 5 new messages
  local new_messages = 0
  for line in result:gmatch("[^\r\n]+") do
    local far_new = line:match("Far:%s+%+(%d+)")
    if far_new then
      new_messages = tonumber(far_new) or 0
      break
    end
  end
  
  return {
    has_new = new_messages > 0,
    local_count = local_count,
    remote_count = local_count + new_messages,
    new_count = new_messages
  }
end
```

#### Phase 2: Smart Sync Command ✅ COMPLETED

**What it does**: Adds a new command to `init.lua` that combines the check function with existing sync functionality.

**Why it's useful**: Users can quickly check if they have new mail without waiting for a full sync. If no new emails exist, they get instant feedback. If new emails are found, only then does a sync occur.

**Module Reuse**: This command reuses all existing infrastructure:
- Uses existing `mbsync.sync()` function for actual syncing
- Uses existing OAuth refresh mechanisms
- Uses existing progress tracking and notifications
- Uses existing UI refresh functions

**Implementation Status**: Added to init.lua as `HimalayaSmartSync` command

```lua
-- Add to init.lua commands section
cmd('HimalayaSmartSync', function()
  local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
  local ui = require('neotex.plugins.tools.himalaya.ui')
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local notify = require('neotex.util.notifications')
  
  -- Check if config is initialized
  if not config.is_initialized() then
    notify.himalaya('Himalaya not configured. Run :HimalayaSetup', notify.categories.ERROR)
    return
  end
  
  notify.himalaya('Checking for new emails...', notify.categories.STATUS)
  
  -- Check for new emails
  mbsync.check_new_emails({
    callback = function(status, error)
      if error then
        notify.himalaya('Failed to check emails: ' .. error, notify.categories.ERROR)
        return
      end
      
      if not status.has_new then
        notify.himalaya('Inbox up to date - no new emails', notify.categories.SUCCESS)
        return
      end
      
      -- New emails detected - run smart sync
      notify.himalaya(string.format('Found %d new emails, syncing...', status.new_count), 
                     notify.categories.STATUS)
      
      -- Use existing sync with progress tracking
      local account = config.get_current_account()
      local channel = account.mbsync and account.mbsync.inbox_channel or 'gmail-inbox'
      
      mbsync.sync(channel, {
        on_progress = function(progress)
          if ui.notifications and ui.notifications.show_sync_progress then
            ui.notifications.show_sync_progress(progress)
          end
        end,
        callback = function(success, error)
          if success then
            local utils = require('neotex.plugins.tools.himalaya.utils')
            utils.clear_email_cache()
            
            notify.himalaya(string.format('Smart sync complete! %d new emails synced', 
                          status.new_count), notify.categories.SUCCESS)
            
            if ui.is_email_buffer_open() then
              ui.refresh_email_list()
            end
          else
            ui.notifications.handle_sync_error(error)
          end
        end
      })
    end
  })
end, {
  desc = 'Smart sync - check and sync only if new emails'
})
```

#### Phase 3: Async Implementation ✅ COMPLETED

**What it does**: Enhances the check_new_emails function to support both synchronous and asynchronous operation using Neovim's jobstart API.

**Why it's useful**: 
- **Non-blocking UI**: The check happens in the background, so Neovim remains responsive while checking the server
- **Better User Experience**: Users can continue editing while the check runs
- **Network Resilience**: Network delays don't freeze the editor
- **Progress Indication**: Can show "Checking..." status without blocking

**Technical Benefits**:
- Prevents UI freezing during network operations
- Allows cancellation of long-running checks
- Enables parallel operations (e.g., checking multiple folders simultaneously in future)

**Implementation Status**: The function now supports both sync and async modes. The HimalayaSmartSync command uses async mode by default.

```lua
-- Enhanced check_new_emails with async support
function M.check_new_emails(opts)
  opts = opts or {}
  local callback = opts.callback
  
  if not callback then
    -- Synchronous version (backward compatible)
    return M._check_new_emails_sync(opts)
  end
  
  -- Asynchronous version
  vim.fn.jobstart({
    config.config.binaries.himalaya or 'himalaya',
    'envelope', 'list',
    '--disable-cache',
    '-f', opts.folder or 'INBOX',
    '-a', opts.account or config.get_current_account_name(),
    '-o', 'json',
    '--page-size', '1'
  }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      local result = table.concat(data, '\n')
      local success, parsed = pcall(vim.json.decode, result)
      
      if success and parsed then
        -- Get local count
        local local_emails = utils.get_email_list(
          opts.account or config.get_current_account_name(),
          opts.folder or 'INBOX',
          1, 1
        )
        local local_count = local_emails and #local_emails or 0
        local remote_count = #parsed
        
        callback({
          has_new = remote_count > local_count,
          local_count = local_count,
          remote_count = remote_count,
          new_count = math.max(0, remote_count - local_count)
        })
      else
        callback(nil, "Failed to parse remote email list")
      end
    end,
    on_stderr = function(_, data)
      local error_msg = table.concat(data, '\n')
      callback(nil, error_msg)
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        callback(nil, "Check failed with exit code: " .. code)
      end
    end
  })
end
```

#### Phase 4: Integration with Keymaps ✅ COMPLETED

**What it does**: Adds new keymaps in which-key.lua alongside existing ones, allowing gradual migration.

**Why it's useful**: 
- Preserves existing workflow while testing new functionality
- Allows A/B comparison of sync methods
- Easy rollback if issues arise
- Clear migration path once proven stable

**Implementation Status**: Added to which-key.lua with non-conflicting keybindings:

```lua
-- In which-key.lua, within the existing himalaya section
{
  ["<leader>m"] = {
    name = "+mail",
    -- Existing keymaps remain unchanged
    s = { ":HimalayaSyncInbox<CR>", "Sync inbox" },
    S = { ":HimalayaSyncFull<CR>", "Sync all" },
    
    -- New smart sync keymap (non-conflicting)
    c = { ":HimalayaSmartSync<CR>", "check & sync (smart)" },
  }
}
```

**Current Keybindings**:
- `<leader>mz` - Fast check using Himalaya IMAP (Phase 5)
- `<leader>ms` - Sync inbox (original behavior preserved)
- `<leader>mS` - Sync all folders (original behavior preserved)

**Migration Strategy**:
1. Current: `<leader>mc` for smart sync, existing keymaps unchanged
2. After testing period, can swap:
   - `<leader>ms` → Smart sync (most common use)
   - `<leader>mS` → Force sync inbox
   - `<leader>mF` → Force full sync

### Configuration Options

Add configuration options for smart sync behavior:

```lua
-- In core/config.lua defaults
sync = {
  -- ... existing options ...
  
  -- Smart sync settings
  smart_sync = {
    enabled = true,
    check_method = 'himalaya', -- 'himalaya' or 'imap'
    max_recent_messages = 500,  -- For mbsync MaxMessages
    folders_to_check = {'INBOX'}, -- Folders to check for smart sync
  },
},
```

### User Experience

1. **<leader>ms** - Smart sync (default)
   - Shows "Checking for new emails..."
   - If no new: "Inbox up to date - no new emails"
   - If new: "Found X new emails, syncing..."
   - Progress bar during sync
   - "Smart sync complete! X new emails synced"

2. **<leader>mS** - Force inbox sync
   - Always syncs inbox regardless of new emails

3. **<leader>mF** - Full sync
   - Syncs all folders

### Implementation Plan

1. **Add check_new_emails function** to existing `sync/mbsync.lua` module
   - No new files needed
   - Reuses existing config and utils modules
   
2. **Add HimalayaSmartSync command** to existing commands in `init.lua`
   - Placed alongside existing sync commands
   - Reuses all existing sync infrastructure
   
3. **Add new keymaps** in `which-key.lua`
   - Preserve existing keymaps
   - Add new ones for testing
   - Document migration plan
   
4. **Add configuration options** to existing config structure in `core/config.lua`
   - Extend existing sync configuration
   - No new config modules
   
5. **Test with various email scenarios**
   - Test alongside existing sync methods
   - Compare performance and reliability
   
6. **Update help text** in existing help system
   - Add new keymaps to help display
   - Update command descriptions

### Technical Considerations

1. **Performance**: Checking via `--disable-cache` is fast but requires network
2. **Accuracy**: Email counts might not match exactly due to:
   - Filtered emails (spam, etc.)
   - Folder differences between IMAP and local
3. **Fallback**: If check fails, fall back to regular sync
4. **OAuth**: Ensure OAuth token is valid before checking

### Future Enhancements

1. **Background Checks**: Periodic background checks for new emails
2. **Smart Folder Detection**: Automatically detect which folders have new emails
3. **Differential Sync**: Sync only specific emails based on criteria
4. **Notification Integration**: System notifications for new emails

## Implementation Priority

1. **High Priority**:
   - Basic smart sync command
   - Integration with existing sync infrastructure
   - User feedback messages

2. **Medium Priority**:
   - Async implementation
   - Configuration options
   - Enhanced progress tracking

3. **Low Priority**:
   - Background checks
   - Advanced folder detection
   - System notifications

## Testing Strategy

1. **Unit Tests**:
   - Test check_new_emails with mock data
   - Test sync decision logic

2. **Integration Tests**:
   - Test with real email accounts
   - Test OAuth refresh during check
   - Test error handling

3. **User Acceptance**:
   - Speed comparison vs full sync
   - Accuracy of new email detection
   - User experience flow

## Module Reuse Summary

**No new modules are created**. The implementation only adds:
- One new function (`check_new_emails`) to existing `sync/mbsync.lua`
- One new command (`HimalayaSmartSync`) to existing command list in `init.lua`
- New keymaps in `which-key.lua` alongside existing ones
- Configuration options to existing config structure

**All functionality reuses**:
- Existing OAuth refresh mechanisms
- Existing progress tracking system
- Existing notification system
- Existing UI refresh functions
- Existing lock management
- Existing error handling

### Phase 5: Himalaya IMAP Integration ✅ COMPLETED

**What it does**: Enhances the check_new_emails function to use Himalaya's direct IMAP access for faster response times.

**Why it's useful**: 
- **Faster checks**: Direct IMAP queries can return in under 1 second vs 2-3 seconds for mbsync dry-run
- **More accurate**: Gets real-time server state without sync metadata issues
- **Flexible queries**: Can check specific criteria (unread only, date ranges, etc.)

**Implementation Status**: The `HimalayaFastCheck` command is now available via `<leader>mz`. It attempts to use Himalaya directly to check for new emails, falling back to mbsync if Himalaya cannot connect.

**Implementation Approach**:

1. **Hybrid Configuration**: Add a separate IMAP account configuration alongside the existing maildir setup:
```toml
# In ~/.config/himalaya/config.toml
[accounts.gmail-imap]
email = "benbrastmckie@gmail.com"
backend.type = "imap"
backend.host = "imap.gmail.com"
backend.port = 993
backend.encryption = "tls"
backend.login = "benbrastmckie@gmail.com"
backend.auth.type = "oauth2"
# ... rest of OAuth config matching SMTP
```

2. **Enhanced Check Function**:
```lua
function M.check_new_emails_himalaya(opts)
  opts = opts or {}
  local account = opts.account or config.get_current_account_name()
  local folder = opts.folder or 'INBOX'
  
  -- Get local count from maildir account
  local local_count = M.get_local_email_count(account, folder)
  
  -- Get remote count using IMAP account
  local cmd = {
    'himalaya',
    'envelope', 'list',
    '-a', account .. '-imap',  -- Use IMAP variant
    '-f', folder,
    '-s', '1',  -- Just get count, not all emails
    '-o', 'json'
  }
  
  -- Run async check
  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      -- Parse response to get total count
      local result = vim.json.decode(table.concat(data, '\n'))
      local remote_count = #result  -- or result.total if available
      
      opts.callback({
        has_new = remote_count > local_count,
        local_count = local_count,
        remote_count = remote_count,
        new_count = remote_count - local_count
      })
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        -- Fall back to mbsync method
        M.check_new_emails_mbsync(opts)
      end
    end
  })
end
```

3. **Configuration Options**:
```lua
sync = {
  smart_sync = {
    method = 'himalaya', -- 'himalaya' or 'mbsync'
    himalaya_imap_suffix = '-imap', -- Account suffix for IMAP variant
    check_timeout = 5000, -- 5 second timeout
    fallback_to_mbsync = true, -- Use mbsync if himalaya fails
  }
}
```

**Benefits**:
- Sub-second response times for email checks
- No need for full mbsync process
- Can check specific folders or criteria
- OAuth token reuse from existing config

**Challenges**:
- Requires dual account configuration (maildir + IMAP)
- Need to ensure OAuth tokens are shared properly
- Must handle connection failures gracefully

## Lessons Learned

### mbsync Dry-Run Failure

The mbsync dry-run approach (Phases 1-4) was implemented but failed to provide any performance benefits:

1. **No Time Savings**: The dry-run check took 55 seconds, which was then followed by the regular sync taking another 40 seconds (95s total)
2. **Added Overhead**: Instead of speeding things up, it just added an extra 55-second check before the normal sync
3. **Root Cause**: mbsync dry-run still needs to connect to the IMAP server and negotiate the full protocol, making it nearly as slow as a regular sync
4. **Conclusion**: The HimalayaSmartSync command and `<leader>mc` keymap were removed as they provided no value

This validates that Phase 5 (direct Himalaya IMAP access) is the correct approach for fast email checking.

### Phase 5/6 Implementation Success

The Himalaya IMAP integration (Phases 5-6) has been successfully implemented:

1. **Fast Checks**: Using `<leader>mz` now checks Gmail for new emails in ~1-2 seconds
2. **Dual-Backend**: gmail-imap account configured for IMAP checks, gmail account for maildir reading
3. **UI Integration**: Added "Checking for new mail" status with search icon (🔍) in sidebar header
4. **Notification Improvements**: ANSI escape codes are cleaned from stderr output for readability
5. **Error Handling**: Gracefully handles empty maildir and missing IMAP account configuration

### Implementation Details

1. **Configuration Fix**: Initial IMAP config had syntax error - `backend.encryption = "tls"` should be `backend.encryption.type = "tls"`
2. **Command Ordering**: Himalaya requires query arguments ("order by") to come last in command
3. **Empty Maildir**: Fixed parsing errors by returning `{}, 0` instead of `nil` for empty folders
4. **Notification Cleaning**: Added `gsub('\27%[[0-9;]*m', '')` to remove ANSI codes from error messages
5. **ID Mismatch Issue**: Discovered that maildir and IMAP use completely different ID systems:
   - Maildir IDs: Sequential numbers (e.g., 3678) based on local storage order
   - IMAP UIDs: Server-assigned unique identifiers (e.g., 131823) that persist across sessions
   - Solution: Changed to compare email subjects instead of IDs for new mail detection
6. **OAuth Authentication Required**: The gmail-imap account needs OAuth authentication before use:
   - Himalaya and mbsync use separate OAuth token storage systems
   - Pre-flight check using `himalaya account show` to detect if account is authenticated
   - Clear error messages if authentication is needed: "Run: himalaya account configure gmail-imap"
   - Without authentication, himalaya envelope list commands will hang indefinitely
   - Cannot automatically refresh Himalaya OAuth tokens like mbsync (different storage mechanism)

## Original Lessons Learned

1. **Himalaya Architecture**: Himalaya reads from local Maildir when it exists, not directly from IMAP. The `--disable-cache` flag doesn't exist in current versions.

2. **mbsync Dry-Run**: The `mbsync --dry-run --verbose` command provides perfect information for checking new emails without downloading them. The output includes "Far: +N" where N is the number of new messages.

3. **Integration Approach**: Working within existing modules and reusing infrastructure made the implementation cleaner and more maintainable.

4. **Async Benefits**: Using Neovim's jobstart for async operations prevents UI freezing during the 2-3 second check operation.

5. **Himalaya Modes**: Himalaya can work in both maildir mode (reading local files) and IMAP mode (direct server access), allowing for flexible architectures.

## Performance Comparison

| Method | Check Time | Pros | Cons |
|--------|------------|------|------|
| Full mbsync | 30+ seconds | Complete sync | Very slow for just checking |
| mbsync dry-run | 55+ seconds | None found | Slower than regular sync, no benefits |
| Himalaya IMAP | 1-2 seconds | Fast, accurate, flexible | Requires dual account config |

## Implementation Recommendations

1. **Current Status**: Phase 5/6 dual-backend approach is fully implemented and working:
   - `<leader>mz` performs fast IMAP checks
   - gmail-imap account configured for checking
   - gmail account continues to use maildir for reading
   - UI shows "Checking for new mail" status with search icon

2. **Future Enhancements**:
   - Background periodic checks with notifications
   - Caching to avoid repeated checks within short timeframe
   - Check multiple folders simultaneously
   - Selective sync of specific emails

3. **Key Learnings for Future Development**:
   - Always test performance assumptions (mbsync dry-run was slower)
   - Dual-backend approach provides best flexibility
   - Clean error output for better user experience
   - Proper command argument ordering is critical for CLI tools

### Phase 6: Dual-Backend Himalaya Configuration (Maildir + IMAP) ✅ COMPLETED

**What it does**: Configures Himalaya to use both maildir (primary) and IMAP (for checking) backends simultaneously, enabling fast new email detection while maintaining local storage.

**Why it's useful**:
- **Best of both worlds**: Local maildir for fast access and offline reading, IMAP for real-time checks
- **Performance**: Sub-second checks for new emails without the overhead of mbsync
- **Seamless integration**: Automatically triggers mbsync only when new emails are detected
- **No duplicate OAuth**: Can potentially reuse the same OAuth tokens for both backends

**Implementation Approach**:

1. **Dual Account Configuration**:
```toml
# ~/.config/himalaya/config.toml

# Primary account - reads from local maildir
[accounts.gmail]
default = true
email = "benbrastmckie@gmail.com"
backend.type = "maildir"
backend.root-dir = "/home/benjamin/Mail/Gmail"
backend.maildirpp = true
# ... existing SMTP config for sending ...

# Secondary account - reads from IMAP for checking
[accounts.gmail-imap]
email = "benbrastmckie@gmail.com"
backend.type = "imap"
backend.host = "imap.gmail.com"
backend.port = 993
backend.encryption = "tls"
backend.login = "benbrastmckie@gmail.com"
backend.auth.type = "oauth2"
backend.auth.method = "xoauth2"
backend.auth.client-id = "${GMAIL_CLIENT_ID}"
backend.auth.auth-url = "https://accounts.google.com/o/oauth2/auth"
backend.auth.token-url = "https://www.googleapis.com/oauth2/v3/token"
backend.auth.pkce = true
# Can potentially share the same OAuth tokens as SMTP
backend.auth.scopes = ["https://mail.google.com/"]
```

2. **Enhanced Fast Check Function**:
```lua
function M.himalaya_dual_check(opts)
  opts = opts or {}
  local account_name = opts.account or config.get_current_account_name()
  local imap_account = account_name .. '-imap'
  local folder = opts.folder or 'INBOX'
  
  -- Step 1: Get local email count/IDs from maildir account
  local local_emails = utils.get_email_list(account_name, folder, 1, 50)
  local highest_local_id = M.get_highest_email_id(local_emails)
  
  -- Step 2: Get remote email count/IDs from IMAP account
  local cmd = {
    'himalaya', 'envelope', 'list',
    '-a', imap_account,  -- Use IMAP variant
    '-f', folder,
    '-s', '50',
    '-o', 'json'
  }
  
  -- Run async check against IMAP
  vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      if code == 0 then
        -- Compare IDs to detect new emails
        local highest_remote_id = M.get_highest_email_id(remote_emails)
        
        if highest_remote_id > highest_local_id then
          -- New emails detected!
          local new_count = M.count_new_emails(remote_emails, highest_local_id)
          
          -- Prompt to sync
          vim.ui.input({
            prompt = string.format('%d new emails. Sync now? (y/n): ', new_count)
          }, function(input)
            if input == 'y' then
              -- Trigger mbsync to update maildir
              vim.cmd('HimalayaSyncInbox')
            end
          end)
        else
          notify.himalaya('Maildir is up to date', notify.categories.SUCCESS)
        end
      else
        -- IMAP check failed, fall back to current behavior
        notify.himalaya('IMAP check failed, maildir may be out of date', notify.categories.WARNING)
      end
    end
  })
end
```

3. **Workflow**:
   - Normal operation: Himalaya reads from local maildir (fast, offline-capable)
   - Check for new mail: `<leader>mz` uses gmail-imap account to check IMAP directly
   - If new emails found: Prompt user to run mbsync
   - After sync: Return to reading from maildir

4. **Benefits**:
   - **No changes to existing workflow**: Still primarily uses maildir
   - **Fast checks**: IMAP checks complete in <1 second
   - **Efficient syncing**: Only sync when actually needed
   - **OAuth reuse**: Can potentially use same tokens for SMTP and IMAP

5. **Technical Considerations**:

   a. **OAuth Token Sharing**:
   - Both SMTP and IMAP use the same Gmail OAuth2 endpoints
   - Tokens might be shareable if stored in the same location
   - May need to adjust scopes to include both SMTP and IMAP permissions

   b. **Account Naming**:
   - Keep primary account name unchanged (`gmail`)
   - Add `-imap` suffix for IMAP variant
   - Easy to identify which backend is being used

   c. **Error Handling**:
   - If IMAP account not configured, fall back to current behavior
   - If IMAP check fails, warn user but don't break workflow
   - Clear messaging about which backend is being used

6. **Future Enhancements**:
   - **Selective sync**: Only sync specific emails or folders
   - **Background checks**: Periodic IMAP checks with notifications
   - **Smart caching**: Cache IMAP results to reduce API calls
   - **Parallel operations**: Check multiple folders simultaneously

**Implementation Priority**: HIGH - This provides the best performance improvement while maintaining the existing maildir-based workflow.

## Conclusion

This smart sync feature significantly improves the user experience by:
- Reducing unnecessary full syncs (30+ seconds → 2-3 seconds for checks, potentially <1 second with IMAP)
- Providing immediate feedback about email status
- Maintaining the robustness of the existing sync system
- Integrating seamlessly with current workflows

The implementation leverages mbsync's dry-run capability to create an efficient, user-friendly email sync experience, while respecting the existing codebase structure and avoiding unnecessary module proliferation. The proposed Himalaya IMAP enhancement would further improve response times for an even better user experience.