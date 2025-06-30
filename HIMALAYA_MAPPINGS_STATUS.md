# Himalaya Email Plugin - Mappings Status Report

Generated: 2025-06-29

## Mapping Overview

All Himalaya mappings are under `<leader>m` prefix.

## Status Legend
- ✅ Fully Implemented
- ⚠️  Partial Implementation / Has TODOs
- ❌ Not Implemented (placeholder/TODO)
- 🔧 Has Issues

## Detailed Mapping Status

### Main Commands

| Keymap | Description | Command | Status | Notes |
|--------|-------------|---------|--------|-------|
| `<leader>mo` | Open mail | `:Himalaya<CR>` | ✅ | Calls `ui.show_email_list()` |
| `<leader>ms` | Sync inbox | `:HimalayaSyncInbox<CR>` | ✅ | Syncs inbox using mbsync |
| `<leader>mS` | Sync all | `:HimalayaSyncFull<CR>` | ✅ | Syncs all folders using mbsync |
| `<leader>mk` | Cancel sync | `:HimalayaCancelSync<CR>` | ✅ | Calls `mbsync.stop()` |
| `<leader>mw` | Write email | `:HimalayaWrite<CR>` | ✅ | Calls `ui.compose_email()` |
| `<leader>mr` | Restore session | `:HimalayaRestore<CR>` | ✅ | Calls `ui.prompt_session_restore()` |
| `<leader>mU` | Cleanup | `:HimalayaCleanup<CR>` | ✅ | Stops syncs and cleans locks |
| `<leader>mi` | Sync status | `:HimalayaSyncStatus<CR>` | ✅ | Shows sync status |
| `<leader>mf` | Change folder | `:HimalayaFolder<CR>` | ❌ | TODO: Not implemented |
| `<leader>ma` | Switch account | `:HimalayaAccounts<CR>` | ❌ | TODO: Not implemented |
| `<leader>mR` | Refresh OAuth | `:HimalayaRefreshOAuth<CR>` | ✅ | Calls `oauth.refresh()` |
| `<leader>mt` | View trash | `:HimalayaTrash<CR>` | ❌ | TODO: Not implemented |
| `<leader>mT` | Trash stats | `:HimalayaTrashStats<CR>` | ❌ | TODO: Not implemented |
| `<leader>mX` | Backup & fresh | `:HimalayaBackupAndFresh<CR>` | ❌ | TODO: Not implemented |

### Command Implementation Details

#### Fully Implemented Commands ✅

1. **Himalaya** (line 60-70)
   - Shows email list with optional folder argument
   - Has folder completion

2. **HimalayaToggle** (line 72-77)
   - Toggles email sidebar
   - Calls `ui.toggle_email_sidebar()`

3. **HimalayaWrite** (line 79-85)
   - Compose new email
   - Calls `ui.compose_email()`

4. **HimalayaSyncInbox** (line 88-118)
   - Syncs inbox only
   - Uses mbsync with progress callback
   - Clears cache and refreshes UI on success

5. **HimalayaSyncFull** (line 120-148)
   - Syncs all folders
   - Similar to inbox sync but uses all_channel

6. **HimalayaCancelSync** (line 151-159)
   - Cancels ongoing sync
   - Calls `mbsync.stop()`

7. **HimalayaSetup** (line 162-167)
   - Runs setup wizard
   - Calls `wizard.run()`

8. **HimalayaHealth** (line 169-174)
   - Shows health check report
   - Calls `health.show_report()`

9. **HimalayaFixCommon** (line 176-181)
   - Fixes common issues automatically
   - Calls `health.fix_common_issues()`

10. **HimalayaRefreshOAuth** (line 184-189)
    - Refreshes OAuth token
    - Calls `oauth.refresh()`

11. **HimalayaOAuthStatus** (line 191-205)
    - Shows OAuth status with details
    - Shows token existence, environment, last refresh

12. **HimalayaCleanup** (line 208-224)
    - Stops all syncs
    - Cleans up lock files
    - Shows cleanup results

13. **HimalayaFixMaildir** (line 227-244)
    - Fixes UIDVALIDITY files in maildir
    - Calls `wizard.fix_uidvalidity_files()`

14. **HimalayaMigrate** (line 247-252)
    - Migrates from old plugin version
    - Calls `migration.migrate_from_old()`

15. **HimalayaRestore** (line 255-260)
    - Restores previous session
    - Calls `ui.prompt_session_restore()`

16. **HimalayaSyncStatus** (line 262-273)
    - Shows current sync status
    - Checks if sync is running

#### Not Implemented Commands ❌

1. **HimalayaFolder** (line 276-282)
   - Shows "not implemented" notification
   - TODO comment present

2. **HimalayaAccounts** (line 284-290)
   - Shows "not implemented" notification
   - TODO comment present

3. **HimalayaTrash** (line 292-298)
   - Shows "not implemented" notification
   - TODO comment present

4. **HimalayaTrashStats** (line 300-306)
   - Shows "not implemented" notification
   - TODO comment present

5. **HimalayaBackupAndFresh** (line 308-314)
   - Shows "not implemented" notification
   - TODO comment present

### Buffer-Specific Keymaps

The plugin defines buffer-specific keymaps for three filetypes:
- `himalaya-list`: Email list buffer
- `himalaya-email`: Email reading buffer  
- `himalaya-compose`: Email compose buffer

These are defined in `config.lua` via `setup_buffer_keymaps()` function and are automatically detected by which-key.

## Issues Found

### 1. Missing Error Handling
- Many commands don't have try-catch blocks
- No validation of account configuration before operations

### 2. Incomplete Features
- 5 commands show "not implemented" message
- Folder picker functionality missing
- Account switcher functionality missing
- Trash management not implemented
- Backup functionality not implemented

### 3. UI Consistency
- Some commands use `notify.himalaya()` while others don't
- Inconsistent error reporting

## Recommendations

1. **Priority 1: Implement Missing Commands**
   - Folder picker (telescope-based)
   - Account switcher
   - Basic trash viewer

2. **Priority 2: Add Error Handling**
   - Wrap commands in pcall
   - Check account config before operations
   - Better error messages

3. **Priority 3: Complete Features**
   - Trash statistics
   - Backup and fresh start functionality

4. **Priority 4: UI Improvements**
   - Consistent notifications
   - Progress indicators for long operations
   - Better feedback for user actions