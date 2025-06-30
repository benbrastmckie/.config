# Himalaya UI Refactor Specification

## Overview
This document outlines the systematic refactor of the Himalaya UI to reproduce the exact functionality from the old ui.lua while maintaining a clean, modular directory structure.

## Refactor Status Summary
**PHASES COMPLETED**: 0, 1, 3, 4 (Phase 2 skipped as unnecessary)
**CURRENT PHASE**: 5 - Systematic Testing

### What Has Been Done:
1. **Utils Module**: Replaced all stub functions with real himalaya CLI integration
2. **UI Functions**: Added all missing functions to ui/main.lua from old UI
3. **Keymaps**: Configured all keymaps in core/config.lua
4. **Email Formatting**: Fixed to match old UI display exactly
5. **Module Cleanup**: Removed unused stub modules, kept focused architecture

### Architecture Achieved:
- `utils.lua`: All email operations and himalaya CLI integration
- `ui/main.lua`: All UI functionality (display, compose, actions)
- `core/config.lua`: Configuration and keymaps
- `ui/state.lua`: Persistent UI state (session restoration)
- `core/state.lua`: Runtime state (sync status, cache)

## Current Issues
The UI was broken during refactoring, missing critical functionality from the original `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/old_backup/ui.lua`.

## Original Functionality Inventory

### 1. Core UI Management
- **Buffer tracking** (email_list, email_read, email_compose)
- **UI initialization** with proper config state management
- **Session state management** (current account, folder, pagination)

### 2. Email List Display
- **Sidebar toggle** functionality
- **Email list formatting** with status icons, pagination info, sync status
- **Smart maildir setup** checking
- **Async email loading** with loading states
- **Real-time sync status updates** with detailed progress

### 3. Email Reading
- **Email content display** with proper formatting
- **URL extraction and numbering** 
- **Header parsing** (From, To, CC, Subject, Date)
- **Attachment handling**
- **Link navigation** (gl command)

### 4. Email Composition
- **New email composition**
- **Reply** (single and reply-all)
- **Forward** functionality
- **Draft saving** (placeholder)
- **Send email** with validation

### 5. Email Management
- **Delete** with smart error handling
  - Missing trash folder handling
  - Permanent delete option
  - Move to custom folder
- **Archive** to appropriate folders (All_Mail, Archive, etc.)
- **Spam** marking with folder detection
- **Move to folder** functionality

### 6. Navigation & Actions
- **Pagination** (next/prev page)
- **Email selection** from list
- **Window management** with stack
- **Keyboard shortcuts** for all actions
- **Session restoration** (manual)

### 7. Search & Utilities
- **Email search** functionality
- **Attachment viewing**
- **Tag management**
- **Email info display**
- **URL opening** in browser

### 8. State Persistence
- **Save/restore session** state
- **Sidebar configuration** persistence
- **Selected email tracking**
- **Search results caching**

## Proposed File Structure

```
himalaya/
|-- core/
|   |-- config.lua           # (existing) Configuration management
|   |-- logger.lua           # (existing) Logging utilities
|   |-- email_operations.lua # Email CRUD operations (from utils)
|   |-- folders.lua          # Folder operations (from utils)
|   |-- system.lua           # System checks and init (from utils)
|   |-- cache.lua            # Cache management (from utils)
|-- sync/
|   |-- mbsync.lua          # (existing) mbsync integration
|   |-- utils.lua           # Sync utilities (from utils)
|-- ui/
|   |-- init.lua            # Main entry point, exports all functionality
|   |-- main.lua            # Core UI orchestration
|   |-- email_list.lua      # Email list display and formatting
|   |-- email_view.lua      # Email reading and content display
|   |-- email_compose.lua   # Email composition (new, reply, forward)
|   |-- email_actions.lua   # Delete, archive, spam, move operations
|   |-- search.lua          # Search functionality
|   |-- session.lua         # Session save/restore
|   |-- sync_status.lua     # Sync status monitoring and display
|   |-- utils.lua           # UI utilities (URL handling, formatting)
|   |-- sidebar.lua         # (existing) Sidebar management
|   |-- window_stack.lua    # (existing) Window stacking
|   |-- state.lua           # (existing) State management
|   |-- notifications.lua   # (existing) Notification system
|   |-- REFACTOR.md         # This document
|-- utils.lua               # (to be removed after redistribution)
```

## Implementation Status

### ✅ Phase 0: Utils Redistribution [COMPLETED]
**Status**: All utils.lua functionality has been properly implemented with real himalaya CLI integration.

**What was done**:
- ✅ Replaced all stub functions in utils.lua with real implementations
- ✅ Added execute_himalaya() for proper CLI integration
- ✅ Implemented email caching for pagination support
- ✅ Added smart delete with trash folder detection
- ✅ Implemented all email operations (send, delete, move, search)
- ✅ Added folder operations
- ✅ Decided against creating many new modules - kept functionality in existing utils.lua

## Implementation Plan

### Phase 0: Utils Redistribution [COMPLETED]
Before starting the main refactor, redistribute functionality from utils.lua to appropriate modules:

1. **Email operations → email_operations.lua** (new core module):
   - `execute_himalaya()` - Core himalaya CLI wrapper
   - `get_email_list()` - Fetch emails with caching
   - `get_email_content()` - Read individual email
   - `send_email()` - Send email functionality
   - `delete_email()` - Delete operations
   - `smart_delete_email()` - Enhanced delete with trash handling
   - `move_email()` - Move between folders
   - `copy_email()` - Copy to folders
   - `search_emails()` - Email search
   - `manage_flag()` - Flag management
   - `get_email_attachments()` - Attachment listing
   - `download_attachment()` - Attachment downloads

2. **Sync operations → sync/utils.lua**:
   - `sync_mail()` - Mail synchronization
   - `validate_mbsync_config()` - Config validation
   - `handle_mbsync_config_issues()` - Error handling
   - `handle_sync_failure()` - Sync failure handling
   - `offer_alternative_sync()` - Alternative sync methods
   - `alternative_sync()` - Himalaya-based sync
   - `smart_sync()` - OAuth-aware sync
   - `start_auto_sync()` - Auto sync timer
   - `stop_auto_sync()` - Stop auto sync
   - `diagnose_oauth_auth()` - OAuth diagnostics
   - `manual_oauth_refresh()` - Manual OAuth refresh

3. **Folder operations → folders.lua** (new core module):
   - `get_folders()` - List folders
   - `create_folder()` - Create new folder
   - `get_unread_count()` - Unread count
   - `get_email_count()` - Total count

4. **UI utilities → ui/utils.lua**:
   - `truncate_string()` - String truncation for display
   - `format_date()` - Date formatting
   - `parse_email_content()` - Parse email from buffer
   - `format_email_for_sending()` - Format for sending
   - `show_config_help()` - Configuration help display

5. **System utilities → core/system.lua** (new):
   - `check_himalaya_available()` - Check himalaya CLI
   - `get_account_status()` - Account status
   - `configure_account()` - Account configuration
   - `init()` - Initialize plugin
   - `cleanup()` - Cleanup function

6. **Cache management → core/cache.lua** (new):
   - `clear_email_cache()` - Clear cache
   - `force_clear_all_caches()` - Clear all caches
   - Email cache implementation

7. **Tag/flag operations → email_actions.lua**:
   - `manage_tag()` - Tag management
   - `expunge_deleted()` - Expunge emails
   - `get_email_info()` - Email information

### ✅ Phase 1: Core Functionality [COMPLETED]
**Status**: All missing UI functions have been added to ui/main.lua

**What was done**:
- ✅ Added read_current_email() for reading emails from the list
- ✅ Added close_current_view() with window stack integration
- ✅ Added close_himalaya() for complete cleanup
- ✅ Added refresh_current_view() for view updates
- ✅ Added get_current_email_id() helper function
- ✅ Added update_email_display() for pagination updates
- ✅ Added all reply/forward functions (reply_email, reply_current_email, etc.)
- ✅ Added delete functions with smart trash handling
- ✅ Added archive and spam functions
- ✅ Added search functionality
- ✅ Added attachment viewing
- ✅ Added URL/link handling
- ✅ Added session restoration functions
- ✅ Updated ui/init.lua to export all new functions

### Phase 1: Core Functionality [COMPLETED]
1. **Update main.lua** to include all missing core functions:
   - `read_current_email()`
   - `close_current_view()`
   - `close_himalaya()`
   - `refresh_current_view()`
   - `get_current_email_id()`
   - `update_email_display()`

2. **Create email_view.lua** for email reading:
   - `read_email(email_id)`
   - `format_email_content(email_content)`
   - `process_email_body(body_lines, urls)`
   - `parse_email_for_reply(email_content)`
   - `open_link_under_cursor()`
   - `open_url(url)`

3. **Create email_compose.lua** for composition:
   - `compose_email(to_address, draft_mode)`
   - `reply_email(email_id, reply_all)`
   - `reply_current_email()`
   - `reply_all_current_email()`
   - `forward_email(email_id)`
   - `forward_current_email()`
   - `send_current_email()`
   - `close_and_save_draft()`
   - `close_without_saving()`
   - `attach_file()`

4. **Create email_actions.lua** for management:
   - `delete_current_email()`
   - `handle_missing_trash_folder(email_id, suggested_folders)`
   - `permanent_delete_email(email_id)`
   - `move_email_to_folder(email_id, folder)`
   - `prompt_custom_folder_move(email_id)`
   - `archive_current_email()`
   - `spam_current_email()`

### ⏭️ Phase 2: Enhanced Features [SKIPPED]
**Status**: Skipped - functionality already implemented in main.lua

**Decision**: 
- All email viewing, composing, and action functionality is already implemented in main.lua
- compose.lua and email_list.lua have stub implementations
- Moving functions between files would add complexity without benefit
- Keeping everything in main.lua follows the "avoid creating millions of modules" directive

### Phase 2: Enhanced Features [SKIPPED]
5. **Create search.lua** for search:
   - `search_emails(query)`
   - `show_search_results(results)`

6. **Create session.lua** for persistence:
   - `can_restore_session()`
   - `restore_session()`
   - `prompt_session_restore()`
   - `sync_sidebar_config()`
   - `save_sidebar_config()`

7. **Create sync_status.lua** for sync monitoring:
   - `get_sync_status_line()`
   - `get_sync_status_line_detailed()`
   - `start_sync_status_updates()`
   - `stop_sync_status_updates()`
   - `update_sidebar_sync_status()`
   - `refresh_sidebar_header()`

8. **Create utils.lua** for UI utilities:
   - `show_attachments(email_id)`
   - `manage_tags()`
   - `show_email_info()`
   - `debug_buffers()`

### ✅ Phase 3: Integration [COMPLETED]
**Status**: All integration work completed

**What was done**:
- ✅ Added setup_buffer_keymaps() to core/config.lua with all keymaps from old UI
- ✅ Updated ui/main.lua to call setup_buffer_keymaps when creating buffers
- ✅ Fixed email list formatting to match old UI exactly
- ✅ Added missing functions (close_without_saving, close_and_save_draft)
- ✅ Exported all functions in ui/init.lua

### Phase 3: Integration [COMPLETED]
9. **Update init.lua** to properly export all functionality
10. **Update email_list.lua** to use the old formatting style
11. **Ensure all keymaps are properly set up**
12. **Test all functionality matches the old UI**

### ✅ Phase 4: Cleanup and Optimization [COMPLETED]
**Status**: Cleanup completed, codebase optimized

**What was done**:
- ✅ Removed unused stub modules (compose.lua, email_list.lua)
- ✅ Verified no circular dependencies exist
- ✅ Kept both state modules as they serve different purposes:
  - core/state.lua: Runtime state (sync status, cache)
  - ui/state.lua: Persistent UI state (session restoration)
- ✅ No redundant code found - all functions have unique purposes
- ✅ Module exports are already optimized in ui/init.lua

**Clean architecture achieved**:
- utils.lua: All email operations and CLI integration
- ui/main.lua: All UI functionality
- Other modules: Specific focused functionality

### Phase 4: Cleanup and Optimization [COMPLETED]
13. **Remove redundant code**:
    - Identify duplicate functions across modules
    - Remove unused helper functions
    - Consolidate similar functionality
    - Remove dead code paths

14. **Clean up dependencies**:
    - Remove circular dependencies
    - Minimize cross-module dependencies
    - Remove unused requires/imports
    - Consolidate utility functions

15. **Remove old compatibility shims**:
    - Remove old_config references once migration complete
    - Clean up temporary compatibility code
    - Remove deprecated function calls
    - Update to use new module structure consistently

16. **Optimize module exports**:
    - Only export public API functions
    - Make internal functions local
    - Remove unnecessary module table entries
    - Clean up init.lua to only export what's needed

### Phase 5: Systematic Testing [IN PROGRESS]
**Status**: Basic functionality confirmed working!

**Progress**:
- ✅ Sidebar opens successfully with <leader>mo
- ✅ Sidebar now toggles properly with <leader>mo (fixed is_open state tracking)
- ✅ Email list loads and displays (200 emails cached)
- ✅ Pagination info shows correctly with total email count
- ✅ Fixed config access pattern (was incorrectly accessing config.binaries instead of config.config.binaries)
- ✅ Pagination with gn/gp works (fixed missing state fields)
- ✅ Email opening with <CR> works (added folder parameter to read command)
- ✅ Closing with q works

**Fixed Issues**:
1. Added missing state fields (current_page, page_size, total_emails)
2. Fixed sidebar.is_open state tracking
3. Updated get_email_list to return total count for proper pagination display
4. Added folder parameter to email reading command

**Additional fixes**:
5. Fixed all command mappings (sync_inbox → sync, stop_sync → stop, etc.)
6. Added proper error handling for sync commands
7. Fixed account configuration checks
8. Added all missing commands (with TODO placeholders for unimplemented features)

**Command Status**:
- ✅ Working: Toggle, Open, Sync (inbox/full), Cancel sync, Write, Cleanup, OAuth refresh, Restore session
- 🚧 TODO: Folder picker, Account switcher, Trash viewer, Trash stats, Backup & fresh

**Ready to continue testing**:

17. **Basic Functionality Testing** (with user):
    ```
    □ Start Neovim fresh
    □ Run :Himalaya (or keybind) - sidebar should open
    □ Check loading state appears while fetching emails
    □ Verify email list displays with correct formatting
    □ Check pagination info shows correctly
    ```

18. **Email List Navigation**:
    ```
    □ Press j/k to navigate up/down in email list
    □ Press <CR> on an email - should open in floating window
    □ Press q in email view - should return to list
    □ Press gn for next page (if multiple pages)
    □ Press gp for previous page
    □ Press r to refresh email list
    ```

19. **Email Reading**:
    ```
    □ Open an email with <CR>
    □ Verify headers display correctly (From, To, Subject, Date)
    □ Check body text is readable
    □ If email has URLs, verify they show as [1], [2], etc.
    □ Press gl on a link line - should offer to open URL
    □ Press q to close email view
    ```

20. **Email Composition**:
    ```
    □ Press c from email list to compose new email
    □ Verify compose window opens with template
    □ Fill in To: field
    □ Fill in Subject: field
    □ Type email body
    □ Press gs to send (verify it sends)
    □ Press q to save as draft (verify prompt)
    □ Press Q to discard (verify it closes without saving)
    ```

21. **Reply and Forward**:
    ```
    □ Open an email
    □ Press gr for reply - verify reply window with quoted text
    □ Press gR for reply all - verify all recipients included
    □ Press gf for forward - verify forward template
    □ Send a reply and verify it works
    ```

22. **Email Management**:
    ```
    □ Select an email in list
    □ Press gD for delete
      - If trash folder missing, verify options menu appears
      - Choose an option and verify email is removed
    □ Press gA for archive
      - Verify email moves to archive folder
      - If no archive folder, verify fallback options
    □ Press gS for spam
      - Verify email moves to spam folder
    ```

23. **Folder and Account Navigation**:
    ```
    □ Press gm to switch folders
      - Verify folder picker appears
      - Select different folder and verify it loads
    □ Press ga to switch accounts (if multiple configured)
      - Verify account switch works
      - Verify email list updates
    ```

24. **Search Functionality**:
    ```
    □ Press / from email list
    □ Enter search query
    □ Verify search results display
    □ Open a search result
    □ Return to normal email list
    ```

25. **Sync Status**:
    ```
    □ Start mbsync in another terminal
    □ Verify sync status appears in email list header
    □ Check status updates every 5 seconds
    □ Verify status disappears when sync completes
    ```

26. **Session Restoration**:
    ```
    □ Open email list and read an email
    □ Close Neovim completely
    □ Reopen Neovim
    □ Run session restore command
    □ Verify it offers to restore previous session
    □ Accept and verify folder/email restored
    ```

27. **Edge Cases**:
    ```
    □ Test with empty inbox
    □ Test with malformed email
    □ Test with very long subject/from fields
    □ Test pagination with exactly page_size emails
    □ Test delete on last email in list
    □ Test with no network connection
    ```

28. **Performance Testing**:
    ```
    □ Open folder with 100+ emails
    □ Verify list loads within 2 seconds
    □ Navigate quickly with j/k - should be responsive
    □ Open and close multiple emails rapidly
    □ Switch folders quickly
    ```

29. **Final Cleanup Verification**:
    ```
    □ Run :checkhealth himalaya (if implemented)
    □ Check for any error messages in :messages
    □ Verify no duplicate functionality
    □ Confirm all keybinds work as documented
    □ Verify help documentation is accurate
    ```

## Key Compatibility Requirements

### 1. Buffer Variables
Must maintain these buffer variables for compatibility:
- `vim.b[buf].himalaya_emails` - Email list data
- `vim.b[buf].himalaya_email_id` - Current email ID
- `vim.b[buf].himalaya_email` - Email content
- `vim.b[buf].himalaya_urls` - Extracted URLs
- `vim.b[buf].himalaya_account` - Current account
- `vim.b[buf].himalaya_folder` - Current folder
- `vim.b[buf].himalaya_compose` - Compose mode flag
- `vim.b[buf].himalaya_reply_to` - Reply email ID
- `vim.b[buf].himalaya_forward` - Forward email ID
- `vim.b[buf].himalaya_attachments` - Attachment list
- `vim.b[buf].himalaya_search` - Search query

### 2. State Management
Must use the old config state structure:
```lua
old_config.state = {
  current_account = 'gmail',
  current_folder = 'INBOX',
  current_page = 1,
  page_size = 25,
  total_emails = 0
}
```

### 3. Email List Format
Must match the exact format from the old UI:
- Header: `Himalaya - {email} - {folder}`
- Pagination: `Page {n} | {count} emails`
- Sync status line (if syncing)
- Separator line
- Email entries: `[status] from  subject  date`
- Footer with keymaps

### 4. Keymap Requirements
All original keymaps must work:
- Email list: `r`, `gn`, `gp`, `gm`, `ga`, `gw`, `gD`, `gA`, `gS`
- Email view: `gl`, `gr`, `gR`, `gf`, `gD`, `q`
- Compose: `gs`, `q`, `Q`

## Migration Steps

1. **Backup current ui/ directory**
2. **Create new files according to structure**
3. **Copy functions from old ui.lua to appropriate new files**
4. **Update imports and module references**
5. **Test each component individually**
6. **Integration testing for full workflow**
7. **Remove old_backup once verified**

## Testing Checklist

- [ ] Email list displays correctly in sidebar
- [ ] Can read individual emails
- [ ] Can compose new emails
- [ ] Can reply to emails (single and all)
- [ ] Can forward emails
- [ ] Can delete emails (with trash folder handling)
- [ ] Can archive emails
- [ ] Can mark emails as spam
- [ ] Pagination works correctly
- [ ] Sync status updates display
- [ ] Session restoration works
- [ ] All keymaps function properly
- [ ] Window management works correctly
- [ ] Search functionality works
- [ ] Attachment viewing works
- [ ] URL link navigation works

## Notes

- The refactor should maintain 100% compatibility with the old UI behavior
- No new features should be added during this refactor
- Focus on code organization without changing functionality
- Preserve all notification messages and categories
- Keep the same visual layout and formatting
- Phase 4 ensures no cruft or redundancy remains after refactor
- Phase 5 provides comprehensive testing to verify everything works
