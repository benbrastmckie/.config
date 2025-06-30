# Smart Sync Specification for Himalaya Email Client

## Overview

This document specifies the implementation of a smart sync feature for the Himalaya email plugin that provides fast, responsive syncing while keeping local emails up to date. The feature will intelligently check for new emails and only sync what's necessary, avoiding slow full syncs when not needed.

## Research Summary

### Key Findings

1. **Himalaya is Stateless**: Himalaya itself doesn't handle synchronization - it only reads from IMAP or local Maildir
2. **mbsync for Synchronization**: All actual syncing is handled by mbsync
3. **Check Without Sync**: `himalaya envelope list --disable-cache` can check IMAP directly without local sync
4. **Incremental Sync**: mbsync supports `MaxMessages` to limit sync scope

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

#### Phase 1: Smart Check Function

Add a new function to check for new emails without syncing:

```lua
-- In sync/mbsync.lua
function M.check_new_emails(opts)
  opts = opts or {}
  local account = opts.account or config.get_current_account_name()
  local folder = opts.folder or 'INBOX'
  
  -- Get current local count
  local local_emails = utils.get_email_list(account, folder, 1, 1)
  local local_count = local_emails and #local_emails or 0
  
  -- Check remote count (bypass cache)
  local remote_cmd = {
    config.config.binaries.himalaya or 'himalaya',
    'envelope', 'list',
    '--disable-cache',
    '-f', folder,
    '-a', account,
    '-o', 'json',
    '--page-size', '1'  -- Just need count, not all emails
  }
  
  local result = vim.fn.system(remote_cmd)
  local success, data = pcall(vim.json.decode, result)
  
  if success and data then
    -- Himalaya might return total count in metadata
    local remote_count = #data
    return {
      has_new = remote_count > local_count,
      local_count = local_count,
      remote_count = remote_count,
      new_count = math.max(0, remote_count - local_count)
    }
  end
  
  return nil, "Failed to check remote emails"
end
```

#### Phase 2: Smart Sync Command

Modify the existing sync infrastructure to support smart sync:

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

#### Phase 3: Async Implementation

Make the check asynchronous to avoid blocking:

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

#### Phase 4: Integration with Keymaps

Update the keymap to use smart sync:

```lua
-- In init.lua, update the keymap
{ '<leader>ms', ':HimalayaSmartSync<CR>', desc = 'Smart sync inbox' },
{ '<leader>mS', ':HimalayaSyncInbox<CR>', desc = 'Force sync inbox' },
{ '<leader>mF', ':HimalayaSyncFull<CR>', desc = 'Full sync all folders' },
```

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

1. **Create check_new_emails function** in `sync/mbsync.lua`
2. **Add HimalayaSmartSync command** in `init.lua`
3. **Update keymaps** to use smart sync as default
4. **Add configuration options** in `core/config.lua`
5. **Test with various email scenarios**
6. **Update documentation** and help text

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

## Conclusion

This smart sync feature will significantly improve the user experience by:
- Reducing unnecessary full syncs
- Providing faster feedback about email status
- Maintaining the robustness of the existing sync system
- Integrating seamlessly with current workflows

The implementation leverages Himalaya's stateless nature and mbsync's capabilities to create an efficient, user-friendly email sync experience.