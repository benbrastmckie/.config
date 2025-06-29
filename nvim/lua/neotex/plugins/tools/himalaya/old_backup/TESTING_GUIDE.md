# Himalaya Email Plugin Testing Guide

This guide provides step-by-step instructions for testing the refactored Himalaya email plugin for Neovim.

## Prerequisites

Before testing, ensure you have:
- [mbsync](https://isync.sourceforge.io/) installed
- [himalaya](https://github.com/soywod/himalaya) CLI installed
- Gmail OAuth credentials configured
- The plugin loaded in your Neovim configuration

## Initial Setup Verification

### 1. Check Plugin Loading

Open Neovim and run:
```vim
:echo luaeval('require("neotex.plugins.tools.himalaya").version')
```

**Expected**: Should output `2.0.0`

### 2. Verify Health Check

Run the health check command:
```vim
:HimalayaHealth
```

**Expected Output**:
- ✅ Binaries: OK (himalaya, mbsync, flock found)
- ✅ Maildir Structure: OK
- ✅ UIDVALIDITY Files: OK
- ✅ OAuth Tokens: OK
- ✅ Folder Mappings: OK
- ✅ Sync Processes: OK

**If any check fails**, note the suggested fix command and run it.

### 3. Check Available Commands

Verify all commands are loaded:
```vim
:command Himalaya
```

**Expected**: Should show all Himalaya* commands:
- `:Himalaya` - Open email list
- `:HimalayaWrite` - Compose new email
- `:HimalayaSyncInbox` - Sync inbox only
- `:HimalayaSyncAll` - Sync all folders
- `:HimalayaCancelSync` - Cancel ongoing sync
- `:HimalayaSetup` - Run setup wizard
- `:HimalayaHealth` - Show health check
- `:HimalayaFixCommon` - Fix common issues
- `:HimalayaCleanup` - Clean up stale locks
- `:HimalayaMigrate` - Migrate from old version
- `:HimalayaOAuthRefresh` - Refresh OAuth token
- `:HimalayaOAuthStatus` - Show OAuth status

## Core Functionality Testing

### 1. OAuth Token Management

#### Check OAuth Status
```vim
:HimalayaOAuthStatus
```

**Expected Output**:
```
OAuth Status:
  Has token: true
  Last refresh: [recent timestamp]
  Environment loaded: true
```

#### Test Token Refresh
```vim
:HimalayaOAuthRefresh
```

**Expected**: Should complete without errors and show "OAuth token refreshed successfully"

### 2. Email List Display

#### Open Email List
```vim
:Himalaya
```

**Expected**:
- Sidebar opens on the left (40 columns wide)
- Shows folder list with icons
- INBOX is selected by default
- Email list displays with subjects, senders, and dates

#### Test Folder Navigation
- Press `j`/`k` to navigate folders
- Press `Enter` to switch folders

**Expected**: Email list updates to show selected folder's contents

#### Test Email Selection
- Navigate to an email with `j`/`k`
- Press `Enter` to view email

**Expected**: Email content displays in main window

### 3. Sync Operations

#### Test Inbox Sync
```vim
:HimalayaSyncInbox
```

**Expected**:
- Progress notification appears
- Sync completes without errors
- Email list refreshes automatically if open

#### Test Full Sync
```vim
:HimalayaSyncAll
```

**Expected**:
- Progress notification for all folders
- Takes longer than inbox-only sync
- All folders update

#### Test Sync Cancellation
Start a sync, then immediately:
```vim
:HimalayaCancelSync
```

**Expected**: Sync stops and shows "Sync cancelled" message

### 4. Email Composition

#### Create New Email
```vim
:HimalayaWrite
```

**Expected**:
- New buffer opens with email template
- Headers include To:, Subject:, etc.
- Cursor positioned in To: field

#### Test With Recipient
```vim
:HimalayaWrite test@example.com
```

**Expected**: To: field pre-filled with the email address

## Advanced Testing

### 1. Lock Management

#### Check for Stale Locks
```vim
:HimalayaCleanup
```

**Expected**: Shows number of cleaned locks (usually 0 if no issues)

### 2. Configuration Validation

#### Check Current Configuration
```vim
:lua print(vim.inspect(require('neotex.plugins.tools.himalaya.core.config').get_current_account()))
```

**Expected**: Shows your Gmail account configuration with:
- Correct email address
- Maildir path with trailing slash
- Folder mappings
- OAuth settings

### 3. Error Recovery

#### Test OAuth Failure Recovery
1. Temporarily break OAuth (rename environment file)
2. Try to sync:
   ```vim
   :HimalayaSyncInbox
   ```

**Expected**:
- Error message about OAuth failure
- Automatic refresh attempt
- Clear error reporting

3. Restore OAuth file and retry

### 4. UI Responsiveness

#### Test Multiple Operations
1. Open email list
2. Start a sync
3. Navigate folders during sync
4. Try to view an email

**Expected**: UI remains responsive, operations queue properly

## Common Issues and Solutions

### Issue: "No OAuth token found"
**Solution**: Run `:HimalayaOAuthRefresh` or configure OAuth in terminal:
```bash
himalaya account configure gmail
```

### Issue: "UIDVALIDITY format error"
**Solution**: Run `:HimalayaFixCommon` to automatically fix

### Issue: "Multiple mbsync processes"
**Solution**: 
1. Run `:HimalayaCleanup`
2. If persists, manually kill processes:
   ```bash
   killall mbsync
   ```

### Issue: "Maildir missing trailing slash"
**Solution**: Edit config to add trailing slash to `maildir_path`

### Issue: Sync appears stuck
**Solution**:
1. Run `:HimalayaCancelSync`
2. Run `:HimalayaCleanup`
3. Retry sync operation

## Performance Testing

### 1. Large Folder Test
Navigate to your largest folder (e.g., All Mail):
```vim
:Himalaya All_Mail
```

**Expected**: 
- Initial load may take a moment
- Pagination works smoothly
- Navigation remains responsive

### 2. Concurrent Operations
1. Start email list
2. Begin composing email
3. Trigger sync

**Expected**: All operations work without interference

## Logging and Debugging

### Enable Verbose Logging
Add to your config:
```lua
require('neotex.plugins.tools.himalaya').setup({
  debug = {
    verbose_sync = true,
    log_oauth = true,
  }
})
```

### View Logs
Check Neovim messages:
```vim
:messages
```

## Final Verification Checklist

- [ ] Plugin loads without errors
- [ ] Health check passes all tests
- [ ] OAuth token refreshes successfully
- [ ] Email list displays and navigates properly
- [ ] Sync operations complete without errors
- [ ] Email composition works
- [ ] Lock cleanup functions properly
- [ ] Error messages are clear and helpful
- [ ] UI remains responsive during operations
- [ ] Auto-refresh works after sync (if sidebar is open)

## Reporting Issues

If you encounter problems:

1. Run `:HimalayaHealth` and note any failures
2. Check `:messages` for error details
3. Try `:HimalayaFixCommon` for automatic fixes
4. Include the output of:
   ```vim
   :lua print(require('neotex.plugins.tools.himalaya').version)
   :HimalayaOAuthStatus
   ```

## Next Steps

Once all tests pass:
1. Configure auto-sync if desired (in your plugin config)
2. Set up keybindings for frequently used commands
3. Customize UI settings (sidebar width, date format, etc.)
4. Explore advanced features like the picker integration