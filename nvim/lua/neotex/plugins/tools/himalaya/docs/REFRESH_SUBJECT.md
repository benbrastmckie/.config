# Draft Subject Refresh Issue

## Problem Description

When editing drafts in the Himalaya email client, there's an inconsistent behavior with subject updates in the sidebar:

1. **First save**: Subject updates immediately in the sidebar ✓
2. **Subsequent saves**: Subject does NOT update in the sidebar ✗
3. **Close/reopen sidebar**: Subject updates correctly ✓

This creates a confusing user experience where draft changes appear to save correctly the first time but not on subsequent saves.

## Root Cause Analysis

After deeper investigation, the issue is more complex than initially understood:

### 1. ID Mismatch Issue
The fundamental problem is an **ID mismatch** between how drafts are cached and how they're cleared:

```lua
-- In email_list.lua (line 389):
email.id = draft.filename  -- Full filename like "1752088678.388349_6.nandi,U=1:2,DS"

-- In email_cache.lua:
cache[account][folder][email_id_str] = normalized  -- Stores by full filename

-- In our attempted fix:
local email_id = filename:match('^(%d+)%.')  -- Extracts only "1752088678"
email_cache.clear_email(account, folder, email_id)  -- Tries to clear by timestamp only
```

**Result**: Cache clearing fails because `"1752088678"` ≠ `"1752088678.388349_6.nandi,U=1:2,DS"`

### 2. Draft Display Architecture

The system uses a two-tier approach for draft display:

1. **Filesystem as Source of Truth** (lines 381-404 in email_list.lua):
   - Drafts are read directly from maildir filesystem
   - Each draft's filename becomes its ID
   - Fresh data is loaded on each sidebar refresh

2. **Cache for Subject Lookup** (lines 701-725 in email_list.lua):
   - When subject is empty, cache is consulted
   - Cache stores by full filename ID
   - Stale cache data overrides fresh filesystem data

### 3. Why It Works the First Time

- **First save**: No cache entry exists, so filesystem data is used directly
- **Subsequent saves**: Cache contains stale data which takes precedence
- **Close/reopen**: Full refresh bypasses cache lookup logic

## Alternative Solutions

### Solution 1: Fix ID Extraction (Minimal Change)
**Approach**: Use the full filename as the cache key when clearing

```lua
-- In orchestration/integration.lua DRAFT_SAVED handler:
local filename = vim.fn.fnamemodify(data.filepath, ':t')
-- Use full filename as ID, not just timestamp
email_cache.clear_email(account, current_folder, filename)
```

**Pros**:
- Minimal code change
- Preserves existing architecture
- Quick fix

**Cons**:
- Doesn't address underlying architectural inconsistency
- Cache still exists unnecessarily for drafts

### Solution 2: Disable Cache for Drafts (Clean Architecture)
**Approach**: Never cache drafts since filesystem is always authoritative

```lua
-- In email_cache.lua store_emails():
if folder:lower():match('draft') then
    -- Skip caching for draft folders
    return
end

-- In email_list.lua format_email_list():
-- Remove the cache lookup logic for drafts (lines 701-725)
```

**Pros**:
- Architecturally clean - single source of truth
- Eliminates the problem entirely
- Simplifies code
- Follows "no redundancy" principle from CODE_STANDARDS.md

**Cons**:
- Requires removing more code
- May need to update tests

### Solution 3: Always Clear Draft Cache on Display (Defensive)
**Approach**: Clear all draft cache entries before displaying draft list

```lua
-- In email_list.lua process_email_list_results():
if is_drafts then
    -- Clear entire draft folder cache to ensure fresh data
    email_cache.clear_folder(account_name, folder)
    
    -- Continue with filesystem read...
```

**Pros**:
- Ensures fresh data every time
- Simple to implement
- Works with existing architecture

**Cons**:
- Clears more than necessary
- Doesn't fix root cause

### Solution 4: Use Consistent IDs (Comprehensive)
**Approach**: Standardize on timestamp-only IDs throughout the system

```lua
-- In email_list.lua when creating draft emails:
email.id = draft.timestamp  -- Use timestamp only, not full filename

-- In draft_manager_maildir.lua:
-- Add timestamp field extraction from filename

-- Update all ID references to use timestamp consistently
```

**Pros**:
- Creates consistent ID system
- Enables proper caching
- More maintainable long-term

**Cons**:
- Requires changes in multiple files
- Risk of breaking other functionality

### Solution 5: Smart Cache Invalidation (Event-Driven)
**Approach**: Track draft modifications and invalidate cache intelligently

```lua
-- Add to draft_manager_maildir.lua save():
-- Store last modification time
vim.api.nvim_buf_set_var(buffer, 'himalaya_draft_mtime', os.time())

-- In email_cache.lua:
-- Add modification time tracking
-- Invalidate cache if mtime is newer than cached_at
```

**Pros**:
- Preserves caching benefits
- Automatic invalidation
- Works for all scenarios

**Cons**:
- More complex implementation
- Additional metadata to track

## Recommended Solution

Based on the **Himalaya Development Guidelines** principles of:
- **No Redundancy**: Eliminate duplicate functionality
- **Single Source of Truth**: One authoritative module for each domain
- **Simplicity**: Reduce complexity and cognitive load

**I recommend Solution 2: Disable Cache for Drafts**

This solution:
1. Eliminates the redundancy of caching filesystem data
2. Establishes filesystem as the single source of truth for drafts
3. Simplifies the codebase by removing unnecessary cache lookups
4. Prevents this class of bugs permanently
5. Aligns with the notification system's emphasis on clean architecture

## Implementation Status

✅ **IMPLEMENTED** - Solution 2 has been successfully implemented:

### Changes Made:

1. **email_cache.lua**:
   - Added check in `store_emails()` to skip caching draft folders
   - Removed draft-specific logging from `store_email()`
   - Drafts are now never cached, eliminating staleness issues

2. **email_list.lua**:
   - Removed cache lookup logic for drafts (lines 701-725)
   - Removed debug logging for draft entries
   - Subject now comes directly from filesystem read

3. **Result**:
   - Draft subjects update immediately on every save
   - No stale cache data can interfere
   - Cleaner, simpler code
   - Filesystem is the single source of truth for drafts

### Why This Works:

- Drafts are already read from the filesystem in `process_email_list_results()`
- The draft manager parses headers (including subject) directly from maildir files
- No cache means no staleness - every display shows current file contents
- Performance impact is negligible since draft folders typically contain few emails

This solution permanently fixes the refresh issue while improving code maintainability.