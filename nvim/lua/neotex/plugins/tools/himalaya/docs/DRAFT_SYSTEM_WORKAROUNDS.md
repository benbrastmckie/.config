# Himalaya Draft System - Workarounds and Limitations

This document describes the workarounds implemented in the Himalaya Neovim plugin to address limitations in the himalaya CLI and maildir format.

## Table of Contents
1. [Draft Content Loss Issue](#draft-content-loss-issue)
2. [Subject Not Showing in Sidebar](#subject-not-showing-in-sidebar)
3. [Draft Preview Limitations](#draft-preview-limitations)
4. [Draft Deletion After Send](#draft-deletion-after-send)
5. [ID Validation Requirements](#id-validation-requirements)
6. [Multipart Content Handling](#multipart-content-handling)
7. [Race Conditions and Locks](#race-conditions-and-locks)

## Draft Content Loss Issue

### Problem
When reopening a draft, the himalaya CLI command `message read` only returns headers for draft emails, not the full content including the body.

### Root Cause
This is a bug/limitation in himalaya CLI where it treats drafts differently from regular messages. The CLI appears to only parse headers when reading drafts from the maildir.

### Workaround
1. **Direct Maildir Reading**: When himalaya returns only headers, we read the draft file directly from the maildir location
2. **Fallback Chain**: 
   - First try: himalaya `message read`
   - Second try: Direct file read from `~/.local/share/himalaya/<account>/Drafts/cur/`
   - Third try: Check draft cache

### Code Location
- `lua/neotex/plugins/tools/himalaya/ui/email_composer.lua:reopen_draft()`
- `lua/neotex/plugins/tools/himalaya/ui/email_preview.lua:load_draft_content()`

## Subject Not Showing in Sidebar

### Problem
The himalaya CLI command `envelope list` returns empty subjects for draft emails, showing "(No subject)" even when drafts have subjects.

### Root Cause
Himalaya doesn't properly index draft metadata in its envelope listing. This appears to be because drafts are not fully processed like sent/received emails.

### Workaround
1. **Two-Tier Cache System**:
   - Persistent metadata cache stored in `~/.cache/nvim/himalaya_draft_metadata.json`
   - Volatile content cache for performance
2. **Cache Population**: When saving a draft, we immediately cache its metadata
3. **Sidebar Display**: Email list checks cache first before displaying "(No subject)"

### Code Location
- `lua/neotex/plugins/tools/himalaya/core/draft_cache.lua`
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua:format_email_item()`

## Draft Preview Limitations

### Problem
Draft preview often shows wrong content or fails to load, especially after switching between drafts.

### Root Cause
1. Himalaya's `message read` limitation for drafts
2. Buffer state management issues
3. Async operation race conditions

### Workaround
1. **Synchronous Loading**: Preview loading is now synchronous to prevent race conditions
2. **Multiple Data Sources**: Check draft manager, cache, then himalaya
3. **State Validation**: Verify draft ID before loading

### Code Location
- `lua/neotex/plugins/tools/himalaya/ui/email_preview.lua:show_email()`

## Draft Deletion After Send

### Problem
Drafts are not automatically deleted from the maildir after being sent, causing clutter.

### Root Cause
1. Himalaya doesn't track the relationship between composed emails and their draft origins
2. No built-in draft cleanup mechanism

### Workaround
1. **Metadata Tracking**: Store draft metadata (ID, account, folder) when scheduling send
2. **Post-Send Cleanup**: After successful send, delete draft using himalaya CLI
3. **Retry Logic**: Use exponential backoff for deletion in case of locks

### Code Location
- `lua/neotex/plugins/tools/himalaya/core/scheduler.lua:cleanup_draft_after_send()`

## ID Validation Requirements

### Problem
Folder names like "Drafts" were being passed as email IDs, causing "invalid digit found in string" errors.

### Root Cause
Inconsistent ID handling throughout the codebase, with some functions accepting any string as an ID.

### Workaround
1. **Centralized Validation**: All IDs must pass through `id_validator.lua`
2. **Whitelist Approach**: Only numeric strings are valid IDs
3. **Folder Name Blacklist**: Explicitly reject known folder names

### Code Location
- `lua/neotex/plugins/tools/himalaya/core/id_validator.lua`
- `lua/neotex/plugins/tools/himalaya/utils.lua:execute_himalaya()`

## Multipart Content Handling

### Problem
Himalaya returns multipart markers (`<#part>`, `<#/part>`) in draft content, which shouldn't be displayed to users.

### Root Cause
Himalaya's message format includes MIME multipart boundaries as visible text markers.

### Workaround
1. **State Machine Parser**: Parse email content with awareness of multipart sections
2. **Marker Removal**: Strip multipart markers in `parse_himalaya_draft()`
3. **Plain Text Extraction**: Extract only text/plain parts for display

### Code Location
- `lua/neotex/plugins/tools/himalaya/core/draft_parser.lua`

## Race Conditions and Locks

### Problem
"cannot open id mapper database" errors when multiple operations access himalaya simultaneously.

### Root Cause
Himalaya uses SQLite for its ID mapping database, which has limited concurrent access.

### Workaround
1. **Retry Handler**: Exponential backoff with jitter for retryable errors
2. **Lock Detection**: Specific handling for database lock errors
3. **Operation Serialization**: Queue operations where possible

### Code Location
- `lua/neotex/plugins/tools/himalaya/core/retry_handler.lua`

## Performance Considerations

### Line Ending Format
- **Issue**: Himalaya expects CRLF line endings per email RFC
- **Workaround**: Convert LF to CRLF when saving drafts
- **Location**: `utils.lua:save_draft()`

### vim.NIL Handling
- **Issue**: Lua's vim.NIL can appear in parsed data
- **Workaround**: Clean vim.NIL to empty strings in parser
- **Location**: `draft_parser.lua:clean_value()`

### Cache Expiration
- **Issue**: Stale cache entries can accumulate
- **Workaround**: 30-day automatic cleanup, 5-minute content cache TTL
- **Location**: `draft_cache.lua:cleanup_old_metadata()`

## Testing Workarounds

To test these workarounds:
1. Run `:HimalayaDraftDebug validate` to check system integrity
2. Use `:HimalayaDraftDebug state` to inspect draft manager
3. Check `:HimalayaDraftDebug cache` for cache contents
4. Enable debug logging with `:HimalayaLogLevel debug`

## Future Improvements

When himalaya CLI is updated, these workarounds can be simplified:
1. Remove direct maildir reading once `message read` works for drafts
2. Remove subject cache once `envelope list` includes draft subjects
3. Simplify retry logic if database locking is improved
4. Remove multipart marker stripping if format changes

## Debug Commands Reference

- `:HimalayaDraftDebug` - Show debug menu
- `:HimalayaDraftDebug state` - Show draft manager state
- `:HimalayaDraftDebug cache` - Show cache contents
- `:HimalayaDraftDebug buffer` - Analyze current buffer
- `:HimalayaDraftDebug validate` - System integrity check
- `:HimalayaDraftDebug parser` - Test parser on buffer
- `:HimalayaDraftDebug maildir` - Show maildir drafts
- `:HimalayaLogLevel <level>` - Set log level