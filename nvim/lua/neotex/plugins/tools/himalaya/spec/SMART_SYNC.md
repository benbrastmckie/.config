# Smart Sync Specification for Himalaya Email Client

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

**What it does**: Adds a new function to the existing `sync/mbsync.lua` module that checks if new emails exist on the server without downloading them.

**Why it's useful**: Currently, checking for new emails requires a full sync which can take 30+ seconds. This function uses Himalaya's `--disable-cache` flag to query the IMAP server directly, returning results in under 2 seconds.

Add this function to the existing mbsync module:

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

**What it does**: Adds a new command to `init.lua` that combines the check function with existing sync functionality.

**Why it's useful**: Users can quickly check if they have new mail without waiting for a full sync. If no new emails exist, they get instant feedback. If new emails are found, only then does a sync occur.

**Module Reuse**: This command reuses all existing infrastructure:
- Uses existing `mbsync.sync()` function for actual syncing
- Uses existing OAuth refresh mechanisms
- Uses existing progress tracking and notifications
- Uses existing UI refresh functions

Add to the existing commands section in init.lua:

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

Enhance the existing function with async support:

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

**What it does**: Adds new keymaps in which-key.lua alongside existing ones, allowing gradual migration.

**Why it's useful**: 
- Preserves existing workflow while testing new functionality
- Allows A/B comparison of sync methods
- Easy rollback if issues arise
- Clear migration path once proven stable

**Implementation in which-key.lua**:

```lua
-- In which-key.lua, within the existing himalaya section
{
  ["<leader>m"] = {
    name = "+mail",
    -- Existing keymaps remain unchanged
    s = { ":HimalayaSyncInbox<CR>", "Sync inbox" },
    S = { ":HimalayaSyncFull<CR>", "Sync all" },
    
    -- New smart sync keymaps added alongside
    i = { ":HimalayaSmartSync<CR>", "Smart sync (check first)" },
    I = { ":HimalayaSyncInbox<CR>", "Force inbox sync" },
    F = { ":HimalayaSyncFull<CR>", "Force full sync" },
  }
}
```

**Migration Strategy**:
1. Keep existing `<leader>ms` and `<leader>mS` unchanged initially
2. Add new keymaps `<leader>mi` (smart), `<leader>mI` (force inbox), `<leader>mF` (force full)
3. After testing period, swap keymaps:
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

## Conclusion

This smart sync feature will significantly improve the user experience by:
- Reducing unnecessary full syncs
- Providing faster feedback about email status
- Maintaining the robustness of the existing sync system
- Integrating seamlessly with current workflows

The implementation leverages Himalaya's stateless nature and mbsync's capabilities to create an efficient, user-friendly email sync experience, while respecting the existing codebase structure and avoiding unnecessary module proliferation.