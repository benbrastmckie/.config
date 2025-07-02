# Himalaya Testing Checklist

Comprehensive testing checklist for the Himalaya email plugin with all 31 implemented commands and key workflows.

## Overview

This checklist validates functionality after refactoring phases and before major releases. Use this to verify that all commands work correctly and core workflows function as expected.

## Testing Protocol

1. Open Neovim in a clean session
2. Run each command in order
3. Verify expected behavior matches description
4. Mark as tested with date/time and any notes
5. Test key workflows to ensure integration works

## Command Categories

### Core UI Commands (6)

- [ ] `:Himalaya [folder]` - Opens email list in sidebar
  - **Expected**: Email list appears with current folder, pagination info
  - **Test**: Navigate with j/k, emails load correctly
  
- [ ] `:HimalayaToggle` - Toggles sidebar visibility
  - **Expected**: Sidebar shows/hides, preserving state and position
  - **Test**: Toggle multiple times, state persists between toggles
  
- [ ] `:HimalayaWrite [address]` - Opens compose window
  - **Expected**: Floating window with email template, optional pre-filled address
  - **Test**: Can type in To/Subject/Body fields, tab navigation works

- [ ] `:HimalayaRefresh` - Refreshes email sidebar
  - **Expected**: Email list updates with latest emails from maildir
  - **Test**: Refresh after external email changes

- [ ] `:HimalayaRestore` - Restores previous session
  - **Expected**: Prompts to restore last folder/account state
  - **Test**: Close Himalaya, restart Neovim, run command

- [ ] `:HimalayaFolder` - Opens folder picker
  - **Expected**: UI selection dialog with available folders
  - **Test**: Switch folders, verify email list updates

### Email Actions (3)

- [ ] `:HimalayaSend` - Sends current email with confirmation
  - **Expected**: Confirmation prompt, then sends email from compose buffer
  - **Test**: In compose buffer, verify send confirmation and completion
  
- [ ] `:HimalayaSaveDraft` - Saves current email to drafts
  - **Expected**: Email saved to Drafts folder, confirmation notification
  - **Test**: Compose email, save, check Drafts folder for saved email
  
- [ ] `:HimalayaDiscard` - Discards current email with confirmation
  - **Expected**: Confirmation prompt, then closes buffer without saving
  - **Test**: In compose buffer, confirm discard prompt behavior

### Sync Commands (5)

- [ ] `:HimalayaSyncInbox` - Syncs inbox folder only
  - **Expected**: Progress notifications, sidebar updates with new emails
  - **Test**: Monitor progress display, verify inbox email count changes
  
- [ ] `:HimalayaSyncFull` - Full synchronization of all folders
  - **Expected**: Folder-by-folder progress, elapsed time, completion notice
  - **Test**: Monitor sync status in sidebar, all folders processed
  
- [ ] `:HimalayaCancelSync` - Cancels running sync operations
  - **Expected**: All sync processes terminated, status cleared
  - **Test**: Start full sync, then cancel during progress

- [ ] `:HimalayaSyncStatus` - Shows current sync status
  - **Expected**: Displays current sync state and progress information
  - **Test**: Run during active sync and when idle

- [ ] `:HimalayaSyncInfo` - Detailed sync information window
  - **Expected**: Floating window with comprehensive sync details
  - **Test**: Check sync history, timing, and status details

### Setup and Maintenance Commands (8)

- [ ] `:HimalayaSetup` - Launches configuration wizard
  - **Expected**: Interactive setup wizard with account configuration
  - **Test**: Walk through setup process, verify account creation
  
- [ ] `:HimalayaHealth` - Comprehensive health check
  - **Expected**: Health check buffer with dependencies and config status
  - **Test**: Verify shows Himalaya CLI, mbsync, OAuth status
  
- [ ] `:HimalayaFixCommon` - Auto-fixes common configuration issues
  - **Expected**: Scans and attempts to fix known problems
  - **Test**: Run on problematic configuration, verify fixes applied

- [ ] `:HimalayaFixUID` - Fixes UIDVALIDITY maildir issues
  - **Expected**: Resolves UIDVALIDITY conflicts by clearing state files
  - **Test**: Run on account with UIDVALIDITY issues

- [ ] `:HimalayaFixMaildir` - Repairs maildir structure issues
  - **Expected**: Scans and repairs maildir folder structure
  - **Test**: Run on account with maildir problems
  
- [ ] `:HimalayaMigrate` - Migrates configuration from older versions
  - **Expected**: Updates config format, preserves existing settings
  - **Test**: Run on older config format, verify migration success
  
- [ ] `:HimalayaCleanup` - Cleans stale processes and lock files
  - **Expected**: Removes orphaned sync processes and locks
  - **Test**: Check process cleanup, lock file removal

- [ ] `:HimalayaBackupAndFresh` - Creates backup and fresh configuration
  - **Expected**: Backs up current config, starts fresh setup
  - **Test**: Verify backup creation, fresh setup wizard launch

### OAuth Commands (2)

- [ ] `:HimalayaRefreshOAuth` - Refreshes OAuth tokens silently
  - **Expected**: Token refresh without user interaction
  - **Test**: Run for OAuth account, verify token refresh

- [ ] `:HimalayaOAuthRefresh` - Refreshes OAuth with progress feedback
  - **Expected**: Shows refresh progress and completion status
  - **Test**: Monitor refresh process, verify feedback display

### Debug Commands (7)

- [ ] `:HimalayaDebug` - Opens comprehensive debug information window
  - **Expected**: Floating window with config, state, version info
  - **Test**: Verify shows account config, sync state, versions

- [ ] `:HimalayaDebugSyncState` - Detailed sync state information
  - **Expected**: Shows current sync locks, processes, and state
  - **Test**: Check during active sync and idle states
  
- [ ] `:HimalayaTestNotify` - Tests notification system
  - **Expected**: Shows sample notifications at all levels
  - **Test**: Verify info/warn/error/debug notifications appear

- [ ] `:HimalayaDebugJson` - Tests JSON parsing functionality
  - **Expected**: Tests JSON encode/decode with sample data
  - **Test**: Verify JSON parsing works correctly

- [ ] `:HimalayaRawTest` - Raw Himalaya CLI command testing
  - **Expected**: Prompts for command, shows raw output
  - **Test**: Test raw Himalaya CLI commands safely

- [ ] `:HimalayaDebugMbsync` - Debug mbsync integration
  - **Expected**: Shows mbsync configuration and status
  - **Test**: Verify mbsync integration details

- [ ] `:HimalayaGenerateGmailConfig` - Generates Gmail configuration
  - **Expected**: Creates Gmail account configuration template
  - **Test**: Verify generated configuration is valid

## Key Workflow Testing

### Email Reading Workflow
1. [ ] Open Himalaya (`:Himalaya`)
2. [ ] Navigate to email with j/k
3. [ ] Open email with Enter
4. [ ] View headers with 'h'
5. [ ] Close with 'q' (returns to email list)
6. [ ] Verify focus restoration and list state

### Email Composition Workflow
1. [ ] Compose new email (`:HimalayaWrite`)
2. [ ] Fill in recipient (verify tab completion)
3. [ ] Add subject and body content
4. [ ] Send email (`:HimalayaSend`)
5. [ ] Verify confirmation prompt and completion
6. [ ] Check sent folder for sent email

### Reply and Forward Workflow
1. [ ] Open an email from the list
2. [ ] Press 'r' for reply
3. [ ] Verify quoted text and headers included
4. [ ] Test reply composition and sending
5. [ ] Press 'f' for forward from original email
6. [ ] Verify original email content included

### Sync Operation Workflow
1. [ ] Inbox sync (`:HimalayaSyncInbox`)
2. [ ] Monitor progress in sidebar
3. [ ] Verify new email count updates
4. [ ] Full sync (`:HimalayaSyncFull`)
5. [ ] Monitor folder-by-folder progress
6. [ ] Test cancellation (`:HimalayaCancelSync`)

### Multi-Account Workflow (if configured)
1. [ ] Switch accounts using account picker
2. [ ] Verify correct emails and folders shown
3. [ ] Test sync operations per account
4. [ ] Verify OAuth refresh per account

### Error Recovery Workflow
1. [ ] Test UIDVALIDITY fix (`:HimalayaFixUID`)
2. [ ] Test common fixes (`:HimalayaFixCommon`)
3. [ ] Test health check (`:HimalayaHealth`)
4. [ ] Verify error notifications and recovery

## State Persistence Testing

### Session State
1. [ ] Open Himalaya, navigate to specific folder
2. [ ] Select some emails and perform operations
3. [ ] Close Neovim completely
4. [ ] Reopen Neovim and run `:HimalayaRestore`
5. [ ] Verify restores to same folder and state

### Configuration Persistence
1. [ ] Make configuration changes
2. [ ] Restart Neovim
3. [ ] Verify settings persist correctly
4. [ ] Test migration (`:HimalayaMigrate`) if needed

## Performance Benchmarks

Document performance for regression testing:

- [ ] **Time to open with 1000+ emails**: _____ seconds
- [ ] **Memory usage with Himalaya open**: _____ MB
- [ ] **Full sync operation duration**: _____ minutes
- [ ] **Inbox sync operation duration**: _____ seconds
- [ ] **Email search response time**: _____ seconds

## Integration Testing

### Notification System
1. [ ] Verify all notifications use unified system
2. [ ] Test debug notifications with `<leader>ad`
3. [ ] Verify notification categories work correctly

### State Management
1. [ ] Test state persistence across operations
2. [ ] Verify no state conflicts between UI and sync
3. [ ] Test state cleanup on errors

### Architecture Compliance
1. [ ] Verify no circular dependencies
2. [ ] Test module initialization order
3. [ ] Verify proper error handling patterns

## Test Results Log

**Last Full Test Completed**: [DATE]  
**Tester**: [NAME]  
**Plugin Version**: [VERSION]  
**Test Environment**: [OS/NEOVIM VERSION]

### Command Results Summary
- **Passing Commands**: ___/31
- **Failing Commands**: ___/31  
- **Skipped Commands**: ___/31

### Critical Issues Found
[Record any critical issues that prevent normal operation]

### Minor Issues Found
[Record minor issues that don't prevent operation]

### Performance Notes
[Record any performance concerns or improvements]

---

## Notes Section

Use this space to record specific test observations, unexpected behavior, or suggestions for improvements:

[TEST NOTES GO HERE]

## Navigation
- [← Himalaya Plugin](../README.md)
- [Architecture Documentation](ARCHITECTURE.md)
- [Sync Documentation](SYNC_STAT.md)