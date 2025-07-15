# Draft Subject Refresh Issue

## Problem Description

When editing drafts in the Himalaya email client, there's an inconsistent behavior with subject updates in the sidebar:

1. **First save**: Subject updates immediately in the sidebar 
2. **Subsequent saves**: Subject does NOT update in the sidebar L
3. **Close/reopen sidebar**: Subject updates correctly 

This creates a confusing user experience where draft changes appear to save correctly the first time but not on subsequent saves.

## Root Cause Analysis

The issue stems from the email caching mechanism:

### 1. Email Cache Behavior
- The email cache (`email_cache.lua`) stores email metadata including subjects
- When displaying drafts in the sidebar, the code checks the cache for subject information
- The cache is NOT cleared when a draft is saved

### 2. Code Flow for Draft Display

```lua
-- In email_list.lua format_email_list()
if is_draft_folder and (subject == '' or subject == vim.NIL) then
    -- Check email cache for the subject
    local cached = email_cache.get_email(current_account, current_folder, email_id)
    -- Uses cached subject if available
end
```

### 3. Why It Works the First Time
- First save: No cached data exists, so the system reads from filesystem
- Subsequent saves: Cache contains old data, which is used instead of reading updated file
- Close/reopen: Triggers a fresh load, bypassing or clearing the cache

## Current Event System

The DRAFT_SAVED event is properly emitted and handled:

```lua
-- In draft_manager_maildir.lua
events_bus.emit(event_types.DRAFT_SAVED, {
    filepath = filepath,
    buffer = buffer
})

-- In orchestration/integration.lua
events.on(event_constants.DRAFT_SAVED, function(data)
    -- Refreshes the email list
    main.refresh_email_list({ restore_insert_mode = false })
end)
```

However, the refresh still uses cached data!

## Proposed Solution

### 1. Add Email-Specific Cache Clearing

Add a new method to `email_cache.lua`:

```lua
-- Clear cache for a specific email
function M.clear_email(account, folder, email_id)
    if cache[account] and cache[account][folder] and cache[account][folder][email_id] then
        cache[account][folder][email_id] = nil
        logger.debug('Cleared email cache', {
            account = account,
            folder = folder,
            email_id = email_id
        })
    end
end
```

### 2. Extract Email ID from Draft Filepath

Since the DRAFT_SAVED event contains the filepath, we need to extract the email ID:

```lua
-- Helper function to extract email ID from draft filepath
local function get_email_id_from_filepath(filepath)
    -- For maildir files, the filename contains the ID
    -- Example: 1234567890.M123456P12345.hostname:2,DS
    local filename = vim.fn.fnamemodify(filepath, ':t')
    
    -- Extract the timestamp portion which serves as ID
    local id = filename:match('^(%d+)%.')
    return id
end
```

### 3. Update DRAFT_SAVED Handler

Modify the event handler to clear the cache before refreshing:

```lua
events.on(event_constants.DRAFT_SAVED, function(data)
    local state = require('neotex.plugins.tools.himalaya.core.state')
    local current_folder = state.get_current_folder()
    
    if current_folder and (current_folder == 'Drafts' or current_folder:lower():match('draft')) then
        local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
        if sidebar.is_open() then
            -- Extract email ID and clear cache
            if data.filepath then
                local email_id = get_email_id_from_filepath(data.filepath)
                if email_id then
                    local email_cache = require('neotex.plugins.tools.himalaya.core.email_cache')
                    local account = state.get_current_account()
                    email_cache.clear_email(account, current_folder, email_id)
                end
            end
            
            -- Then refresh with fresh data
            vim.defer_fn(function()
                local main = require('neotex.plugins.tools.himalaya.ui.main')
                main.refresh_email_list({ restore_insert_mode = false })
            end, 100)
        end
    end
end)
```

## Alternative Solutions Considered

1. **Clear entire folder cache on save**: Too aggressive, would impact performance
2. **Disable caching for drafts folder**: Would slow down draft list display
3. **Always read from filesystem for drafts**: Current approach, but cache interference prevents this

## Implementation Notes

- The email ID extraction needs to handle different maildir filename formats
- Consider adding a more robust ID tracking system in the draft manager
- May want to add cache TTL (time-to-live) for draft entries specifically
- Test with different email providers as maildir formats may vary

## Benefits

- Consistent behavior: Subject always updates immediately after save
- Minimal performance impact: Only clears one cache entry
- Preserves caching benefits for other operations
- Works with existing event system