# Himalaya Testing Checklist

## Overview
This checklist documents all 28 implemented commands and their expected behavior. Use this to verify functionality after each refactoring phase.

## Testing Protocol
1. Open Neovim
2. Run each command
3. Verify expected behavior
4. Mark as tested with date/time

## Command Categories

### Core UI Commands (3)
- [ ] `:Himalaya` - Opens email list in main window
  - Expected: Email list appears with folders in sidebar
  - Test: Navigate with j/k, folders visible
  
- [ ] `:HimalayaToggle` - Toggles sidebar visibility
  - Expected: Sidebar shows/hides, preserving state
  - Test: Toggle multiple times, state persists
  
- [ ] `:HimalayaWrite` - Opens compose window
  - Expected: New buffer with email template
  - Test: Can type in To/Subject/Body fields

### Email Actions (3)
- [ ] `:HimalayaSend` - Sends email with confirmation
  - Expected: Confirmation prompt appears before sending
  - Test: In compose buffer, prompts for confirmation
  
- [ ] `:HimalayaSaveDraft` - Saves to drafts folder
  - Expected: Email saved to Drafts, notification shown
  - Test: Compose email, save, check Drafts folder
  
- [ ] `:HimalayaDiscard` - Discards with confirmation
  - Expected: Confirmation prompt, then closes buffer
  - Test: In compose buffer, confirms before discarding

### Sync Commands (4)
- [ ] `:HimalayaFastCheck` - Quick IMAP check
  - Expected: Fast sync notification, new count shown
  - Test: Run command, see notification
  
- [ ] `:HimalayaSyncInbox` - Syncs inbox only
  - Expected: Progress notification, inbox updates
  - Test: Run command, monitor progress
  
- [ ] `:HimalayaSyncFull` - Full sync all folders
  - Expected: Progress for each folder, completion notice
  - Test: Run command, watch all folders sync
  
- [ ] `:HimalayaCancelSync` - Kills all sync processes
  - Expected: All sync processes terminated
  - Test: Start sync, then cancel

### Setup/Maintenance Commands (7)
- [ ] `:HimalayaSetup` - Configuration wizard
  - Expected: Interactive setup wizard launches
  - Test: Opens wizard interface
  
- [ ] `:HimalayaHealth` - Health check report
  - Expected: Checkhealth buffer with diagnostics
  - Test: Shows config, CLI, dependencies status
  
- [ ] `:HimalayaFixCommon` - Auto-fix common issues
  - Expected: Attempts fixes, reports results
  - Test: Run and check output
  
- [ ] `:HimalayaCleanup` - Clean processes/locks
  - Expected: Kills processes, removes lock files
  - Test: Cleans up stale processes
  
- [ ] `:HimalayaFixMaildir` - Fix UIDVALIDITY issues
  - Expected: Scans and fixes maildir issues
  - Test: Run on account with maildir
  
- [ ] `:HimalayaMigrate` - Migrate old config
  - Expected: Migrates from old format
  - Test: Check migration logic
  
- [ ] `:HimalayaBackupAndFresh` - Full reset wizard
  - Expected: Backs up and resets configuration
  - Test: Prompts for backup location

### OAuth Commands (2)
- [ ] `:HimalayaRefreshOAuth` - Basic refresh
  - Expected: Refreshes OAuth tokens silently
  - Test: Run for OAuth account
  
- [ ] `:HimalayaOAuthRefresh` - Refresh with feedback
  - Expected: Shows refresh progress/status
  - Test: Run and see feedback

### Debug Commands (6)
- [ ] `:HimalayaDebug` - Full debug info window
  - Expected: Opens buffer with debug information
  - Test: Shows config, state, versions
  
- [ ] `:HimalayaDebugSyncState` - Sync state details
  - Expected: Shows detailed sync status
  - Test: Displays sync locks, processes
  
- [ ] `:HimalayaSyncInfo` - Detailed sync status window
  - Expected: Formatted sync information display
  - Test: Shows all sync details
  
- [ ] `:HimalayaTestNotify` - Test notifications
  - Expected: Shows test notifications at all levels
  - Test: See info/warn/error notifications
  
- [ ] `:HimalayaDebugJson` - Test JSON parsing
  - Expected: Tests JSON encode/decode
  - Test: Outputs JSON test results
  
- [ ] `:HimalayaRawTest` - Raw command testing
  - Expected: Allows testing raw himalaya commands
  - Test: Prompts for command to test

## Key Workflows to Test

### Email Reading Workflow
1. [ ] Open Himalaya (`:Himalaya`)
2. [ ] Navigate to email with j/k
3. [ ] Open email with Enter
4. [ ] View headers with 'h'
5. [ ] Close with 'q' (returns to list)

### Email Composition Workflow
1. [ ] Compose new (`:HimalayaWrite`)
2. [ ] Fill in recipient (tab completion works)
3. [ ] Add subject and body
4. [ ] Send (`:HimalayaSend`)
5. [ ] Verify sent folder updated

### Reply/Forward Workflow
1. [ ] Open an email
2. [ ] Press 'r' for reply
3. [ ] Verify quoted text included
4. [ ] Press 'f' for forward
5. [ ] Verify original included

### Sync Workflow
1. [ ] Fast check (`:HimalayaFastCheck`)
2. [ ] See new email count
3. [ ] Full sync (`:HimalayaSyncFull`)
4. [ ] Monitor progress notifications
5. [ ] Cancel if needed (`:HimalayaCancelSync`)

### Multi-Account Workflow
1. [ ] Switch accounts (if configured)
2. [ ] Verify correct emails shown
3. [ ] Test sync per account
4. [ ] OAuth refresh per account

## State Persistence Tests
1. [ ] Open Himalaya, navigate to folder
2. [ ] Close Neovim completely
3. [ ] Reopen Neovim
4. [ ] Open Himalaya - should restore position

## Performance Benchmarks
- [ ] Time to open with 1000+ emails: _____
- [ ] Memory usage with Himalaya open: _____
- [ ] Sync operation duration: _____

## Notes Section
Record any issues or unexpected behavior here:

---

Last full test completed: [DATE]
Tester: [NAME]