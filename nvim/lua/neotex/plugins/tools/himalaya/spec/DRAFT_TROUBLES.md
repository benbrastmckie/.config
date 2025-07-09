# Himalaya Draft Functionality Troubleshooting Report

## Overview
This document chronicles the extensive challenges encountered while implementing draft functionality for the Himalaya email client integration in Neovim. The draft system presented numerous technical hurdles due to limitations in the himalaya CLI, email format requirements, and complex state management needs.

## Core Issues Encountered

### 1. Draft Content Not Persisting
**Symptoms:**
- Draft content (To, Subject, Body) was lost when closing and reopening drafts (CURRENT)
- Fields showing as empty or `vim.NIL` when reopened

**Root Causes:**
- Himalaya CLI bug: `himalaya message read` only returns headers for drafts, not full content
- Incorrect handling of vim.NIL values in Lua
- Missing CRLF line endings required by RFC-compliant email format

**Solutions Implemented:**
- Created workaround to read draft content directly from local maildir files
- Added comprehensive vim.NIL handling throughout the codebase
- Implemented proper CRLF line endings (`\r\n`) instead of Unix line endings (`\n`)
- Added Message-ID header generation for RFC compliance

### 2. Invalid ID Errors
**Symptoms:**
- "invalid value 'Drafts' for '<ID>': invalid digit found in string" errors
- Folder names being passed as email IDs to himalaya commands

**Root Cause:**
- Improper parameter handling in execute_himalaya function
- Missing validation of ID parameters before command execution

**Solution:**
- Added comprehensive ID validation in execute_himalaya
- Implemented checks to prevent folder names from being used as IDs
- Added specific validation for read and delete commands

### 3. Draft Subject Not Showing in Sidebar
**Symptoms:**
- All drafts showing "(No subject)" in sidebar despite having subjects (CURRENT)
- Subject line only appearing after sending and creating new draft

**Root Causes:**
- Himalaya returns empty subject for drafts in envelope list
- Cache not being populated with draft content
- Email list not looking up draft content from cache

**Solutions Attempted:**
- Modified email_list.lua to look up draft subjects from cache
- Added caching of draft content when composed
- Implemented draft-specific subject lookup logic
- **Still unresolved** - himalaya envelope list limitation

### 4. Preview Issues
**Symptoms:**
- "Loading email content..." stuck in preview
- Preview content disappearing after opening draft
- Preview showing wrong draft content
- Preview not showing at all for drafts (CURRENT)

**Root Causes:**
- Cache invalidation issues
- Preview using local file loading that selected most recent file
- Missing preview content update functions
- Async loading race conditions

**Solutions:**
- Removed local file loading in preview
- Always clear cache for drafts before preview
- Create placeholder content for drafts during loading
- Fixed preview buffer management

### 5. Duplicate Draft Creation
**Symptoms:**
- Opening a draft created a new duplicate draft
- Multiple drafts showing same content
- Each save creating new draft instead of updating existing

**Root Causes:**
- Himalaya creating new draft on save instead of updating
- Buffer management not tracking which buffer owns which draft
- Auto-save triggering during draft opening

**Solutions:**
- Added draft_id_to_buffer mapping to track ownership
- Modified sync_draft_to_maildir to accept existing draft ID
- Removed draft deletion during auto-save
- Implemented buffer reuse for same draft

### 6. Draft Deletion After Sending
**Symptoms:**
- Drafts remaining in Drafts folder after email sent (CURRENT)
- Both original draft and scheduling draft persisting
- Draft cleanup not working

**Root Causes:**
- Missing draft metadata in scheduler
- Incorrect account/folder information for deletion
- Draft ID not being passed through send pipeline

**Solutions:**
- Added draft metadata to scheduler queue items
- Enhanced scheduler to delete drafts after successful send
- Added comprehensive logging for draft cleanup
- Fixed draft folder lookup for deletion

### 7. Buffer Management Issues
**Symptoms:**
- Error when closing compose buffers with `:bd!`
- "attempt to index global 'body_cache' (a nil value)"
- Sidebar opening during email composition

**Root Causes:**
- body_cache variable declaration order in email_cache.lua
- Missing nil checks in buffer cleanup
- Refresh triggers during composition

**Solutions:**
- Moved body_cache declaration to module level
- Added existence checks before refresh
- Fixed sidebar state checks

### 8. Empty Draft Content
**Current Issue - Unresolved:**
- New drafts showing no content when created
- Preview shows empty for new drafts (CURRENT)
- Opening new draft shows no content

**Investigation:**
- Added extensive logging to track content flow
- Logging shows empty content being saved
- Issue appears to be in initial buffer creation

## Technical Discoveries

### Himalaya CLI Limitations
1. `himalaya message read` returns only headers for drafts, not full content
2. `himalaya envelope list` returns empty subjects for drafts
3. `himalaya message save` requires RFC-compliant format with CRLF
4. No direct draft update command - must delete and recreate

### Email Format Requirements
1. Must use CRLF (`\r\n`) line endings
2. Requires Message-ID header
3. Empty line required between headers and body
4. Headers must be properly formatted with colons

### Neovim Integration Challenges
1. vim.NIL handling differs from nil in Lua
2. Async operations require careful state management
3. Buffer lifecycle events can trigger during saves
4. File I/O needs proper error handling

## Workarounds Implemented

### 1. Direct Maildir Reading
```lua
-- Read draft directly from maildir since himalaya won't return content
local draft_dir = vim.fn.expand('~/.local/share/himalaya/' .. opts.account .. '/.maildir/' .. opts.folder .. '/new/')
```

### 2. Subject Caching System
- Store draft subjects in cache when composed
- Look up subjects from cache for sidebar display
- Clear and refresh cache on updates

### 3. Buffer-to-Draft Mapping
- Track which buffer owns which draft ID
- Prevent multiple buffers for same draft
- Reuse existing buffers when reopening

### 4. Comprehensive Logging
- Added logger module for debugging
- Log all himalaya commands and responses
- Track draft lifecycle events

## Remaining Issues

1. **Draft subjects not showing in sidebar** - Requires himalaya CLI fix or alternative envelope list implementation
2. **Empty content in new drafts** - Under investigation, appears to be buffer initialization issue
3. **Performance with many drafts** - Each draft requires separate read for content

## Recommendations

1. **File GitHub issue** for himalaya draft read bug -  Completed
2. **Consider alternative draft storage** outside of himalaya for better control
3. **Implement draft-specific envelope list** that includes full draft reading
4. **Add draft content validation** before save to prevent empty drafts
5. **Create comprehensive test suite** for draft operations

## Lessons Learned

1. Always validate third-party CLI outputs and handle edge cases
2. Email format standards (RFC) must be strictly followed
3. State management in async environments requires careful design
4. Comprehensive logging is essential for debugging complex integrations
5. Workarounds may be necessary when upstream tools have limitations

## Code References

Key files modified:
- `lua/neotex/plugins/tools/himalaya/ui/email_composer.lua:81-89` - Draft content parsing
- `lua/neotex/plugins/tools/himalaya/utils.lua:448-460` - Draft saving with CRLF
- `lua/neotex/plugins/tools/himalaya/ui/email_preview.lua:287-298` - Draft preview fix
- `lua/neotex/plugins/tools/himalaya/core/scheduler.lua:510-566` - Draft cleanup after send
- `lua/neotex/plugins/tools/himalaya/debug_drafts.lua:10-72` - Debug utilities

## Status

As of 2025-07-09:
- Basic draft functionality working with workarounds
- Major issues resolved except sidebar subject display
- New issue discovered with empty draft content
- Comprehensive logging in place for further debugging
