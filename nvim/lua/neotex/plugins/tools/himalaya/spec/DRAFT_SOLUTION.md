# Himalaya Draft System Comprehensive Refactor Plan

## Executive Summary

This document outlines a systematic refactor plan to address all current draft functionality issues in the Himalaya Neovim integration. The plan focuses on five critical problems that persist despite previous fixes and proposes a complete architectural overhaul of the draft system.

## Current Critical Issues

1. **Draft content lost when reopening** - Draft fields (To, Subject, Body) are not persisted
2. **Subjects not showing in sidebar** - All drafts display "(No subject)"
3. **Preview not working for drafts** - Preview pane shows nothing or errors
4. **Drafts not deleted after sending** - Sent drafts remain in folder
5. **Empty content in new drafts** - New drafts have no content when created

## Root Cause Analysis

### 1. Fragile Content Parsing
The current parsing logic in `reopen_draft()` attempts to parse himalaya's output but fails due to:
- Inconsistent format detection (looking for `---` dividers)
- Nested header structures causing re-parsing loops
- Multipart content markers being stripped incorrectly
- No validation of parsed content before use

### 2. Broken ID Management
Draft IDs are confused with folder names throughout the codebase:
- "Drafts" string passed as email ID
- No centralized ID validation
- Race conditions between ID generation and usage
- Local draft IDs vs himalaya draft IDs not synchronized

### 3. Aggressive Cache Invalidation
The cache is cleared too frequently:
- Draft folder cache cleared on every refresh
- Individual draft cache cleared before preview
- No persistent subject storage for drafts
- Cache not populated when drafts are listed

### 4. Himalaya CLI Limitations
Working around fundamental himalaya limitations:
- `envelope list` returns empty subjects for drafts
- `message read` returns only headers for drafts
- No draft update command (must delete and recreate)
- Inconsistent response formats

### 5. Asynchronous State Management
Race conditions and timing issues:
- Draft saved before ID assigned
- Preview attempted before content available
- Deletion scheduled before draft fully saved
- Buffer state not synchronized with maildir state

## Proposed Architecture

### Phase 1: Draft State Management Layer

Create a dedicated draft state manager that maintains consistency between:
- Local buffer content
- Draft files on disk
- Himalaya maildir entries
- UI cache for display

```lua
-- New file: lua/neotex/plugins/tools/himalaya/core/draft_manager.lua
local DraftManager = {
  -- Map of buffer_id -> draft_state
  drafts = {},
  
  -- Draft state structure
  -- {
  --   buffer_id = number,
  --   draft_id = string|nil,      -- Himalaya ID (nil until synced)
  --   local_id = string,          -- Temporary ID for tracking
  --   file_path = string,         -- Local draft file
  --   account = string,
  --   folder = string,
  --   content = {
  --     from = string,
  --     to = string,
  --     subject = string,
  --     body = string,
  --     headers = table
  --   },
  --   state = 'new'|'syncing'|'synced'|'sending',
  --   last_saved = timestamp,
  --   last_synced = timestamp
  -- }
}
```

### Phase 2: Robust Content Parser

Replace fragile parsing with a state-machine based parser:

```lua
-- Enhanced parser with validation
function parse_himalaya_draft(content)
  local parser = DraftParser:new()
  
  -- State machine for parsing
  parser:add_state('headers', {
    pattern = '^([^:]+):%s*(.*)$',
    on_match = function(header, value)
      parser:add_header(header, value)
    end,
    next_state = function(line)
      if line == '' then return 'body' end
      if line:match('^%-%-%-') then return 'display_headers' end
      return 'headers'
    end
  })
  
  parser:add_state('body', {
    on_line = function(line)
      -- Handle multipart markers
      if not line:match('^<#part') and not line:match('^<#/part>') then
        parser:add_body_line(line)
      end
    end
  })
  
  return parser:parse(content)
end
```

### Phase 3: ID Validation System

Centralized ID validation and generation:

```lua
-- ID validation module
local IdValidator = {
  -- Validate himalaya ID format
  is_valid_id = function(id)
    if not id or type(id) ~= 'string' then return false end
    if id == 'Drafts' or id:match('^[A-Z]') then return false end
    return id:match('^%d+$') ~= nil
  end,
  
  -- Generate temporary local ID
  generate_local_id = function()
    return string.format('draft_%s_%s', os.time(), vim.fn.rand())
  end,
  
  -- Sanitize ID before use
  sanitize_id = function(id)
    if not IdValidator.is_valid_id(id) then
      error("Invalid draft ID: " .. tostring(id))
    end
    return id
  end
}
```

### Phase 4: Smart Cache Management

Implement a two-tier cache system:

```lua
-- Draft-specific cache
local DraftCache = {
  -- Persistent cache for draft metadata
  metadata_cache = {}, -- subject, from, to, date
  
  -- Volatile cache for content
  content_cache = {},  -- full draft content
  
  -- Cache draft metadata when saved
  cache_draft_metadata = function(draft_id, metadata)
    DraftCache.metadata_cache[draft_id] = {
      subject = metadata.subject,
      from = metadata.from,
      to = metadata.to,
      date = metadata.date,
      cached_at = os.time()
    }
    -- Persist to disk for sidebar display
    DraftCache.persist_metadata()
  end,
  
  -- Get subject for sidebar without clearing cache
  get_draft_subject = function(draft_id)
    local cached = DraftCache.metadata_cache[draft_id]
    if cached and cached.subject then
      return cached.subject
    end
    return nil
  end
}
```

### Phase 5: Preview System Overhaul

Fix preview for all draft states:

```lua
-- Enhanced preview logic
function show_draft_preview(draft_id)
  local draft_state = DraftManager:get_draft(draft_id)
  
  if not draft_state then
    -- Try to load from cache or himalaya
    draft_state = DraftManager:load_draft(draft_id)
  end
  
  if draft_state then
    -- Show content from state, not himalaya
    preview_buffer:set_content(draft_state.content)
  else
    -- Fallback to himalaya with proper parsing
    local content = fetch_and_parse_draft(draft_id)
    preview_buffer:set_content(content)
  end
end
```

### Phase 6: Reliable Draft Deletion

Ensure drafts are deleted after sending:

```lua
-- Track draft through entire send process
function schedule_email_with_draft_cleanup(email_data, draft_info)
  -- Validate draft info
  if draft_info and draft_info.draft_id then
    if not IdValidator.is_valid_id(draft_info.draft_id) then
      logger.warn("Invalid draft ID for cleanup", {id = draft_info.draft_id})
      draft_info = nil
    end
  end
  
  -- Add to scheduler with verified metadata
  scheduler.schedule_email(email_data, {
    metadata = {
      draft_id = draft_info and draft_info.draft_id,
      draft_account = draft_info and draft_info.account,
      draft_folder = draft_info and draft_info.folder,
      cleanup_required = draft_info ~= nil
    }
  })
end

-- In scheduler after send
function cleanup_draft_after_send(metadata)
  if metadata.cleanup_required and metadata.draft_id then
    -- Multiple attempts with fallback
    local deleted = false
    
    -- Try himalaya delete
    deleted = try_delete_draft_himalaya(metadata)
    
    -- Fallback to direct maildir delete
    if not deleted then
      deleted = try_delete_draft_maildir(metadata)
    end
    
    -- Update cache
    if deleted then
      DraftCache.remove_draft(metadata.draft_id)
      DraftManager.remove_draft(metadata.draft_id)
    end
  end
end
```

## Implementation Plan

### Week 1: Foundation ✅
1. ✅ Create `draft_manager.lua` with state tracking
   - Implemented centralized draft state management
   - Tracks buffer ID, draft ID, local ID, and content
   - Provides lookup by buffer ID, draft ID, or local ID
2. ✅ Create `id_validator.lua` with validation functions
   - Validates himalaya numeric IDs
   - Prevents folder names from being used as IDs
   - Provides safe validation and sanitization functions
3. ✅ Update all files to use centralized ID validation
   - Updated utils.lua to use id_validator
   - Enhanced error messages for invalid IDs
4. ✅ Add comprehensive logging for draft lifecycle
   - Added lifecycle logging in email_composer.lua
   - Tracks draft creation, sync success, and sync failures

### Week 2: Content Handling ✅
1. ✅ Implement robust draft parser with state machine
   - Created draft_parser.lua with state-machine based parsing
   - Handles himalaya's display headers and multipart content
   - Properly cleans vim.NIL values
2. ✅ Fix content loss in `reopen_draft()`
   - Replaced fragile parsing with robust parser
   - Fixed handling of nested headers and multipart markers
3. ✅ Ensure all draft fields are preserved
   - Parser preserves all headers and body content
   - Updates draft manager with parsed content
4. ✅ Add content validation and error recovery
   - Added validate_email function
   - Ensures minimum required fields
   - Logs validation errors for debugging

### Week 3: Cache and Display ✅
1. ✅ Implement two-tier cache system
   - Created draft_cache.lua with persistent metadata and volatile content
   - Metadata persists to disk for sidebar display
   - Content cache has 5-minute TTL
2. ✅ Fix sidebar subject display
   - Email list now checks draft cache first for subjects
   - Subjects persist across sessions
   - Cache not cleared on folder refresh
3. ✅ Persist draft metadata across sessions
   - Metadata saved to ~/.cache/nvim/himalaya_draft_metadata.json
   - Automatically loaded on startup
   - Survives neovim restarts
4. ✅ Optimize cache invalidation strategy
   - Only content cache cleared on refresh, not metadata
   - Draft deletion removes from cache
   - Old entries cleaned up after 30 days

### Week 4: Preview and Cleanup ✅
1. ✅ Rewrite preview system for drafts
   - Created load_draft_content function with proper error handling
   - Uses draft cache, draft manager, then himalaya as fallback
   - Synchronous loading for immediate preview
2. ✅ Fix draft deletion after send
   - Added draft_folder to scheduler metadata
   - Integrated with draft_manager for buffer cleanup
   - Remove from all caches on successful deletion
3. ✅ Handle all edge cases (network failures, etc.)
   - Created retry_handler.lua for robust retries
   - Handles lock conflicts and temporary failures
   - Provides exponential backoff with jitter
4. ✅ Add retry logic for failed operations
   - Draft deletion uses retry_handler
   - Distinguishes retryable vs permanent errors
   - User notifications on retry attempts

### Week 5: Testing and Polish ✅
1. ✅ Create comprehensive test suite
   - Created test_draft_refactor.lua with 18 tests
   - Tests cover all refactor components
   - Integrated with HimalayaTest framework
2. ✅ Add debug commands for troubleshooting
   - Created debug_commands.lua with diagnostic tools
   - :HimalayaDraftDebug command with subcommands
   - :HimalayaLogLevel for dynamic log control
3. ✅ Document all workarounds and limitations
   - Created DRAFT_SYSTEM_WORKAROUNDS.md
   - Created draft_system_README.md
   - Documented all himalaya CLI limitations
4. ✅ Performance optimization
   - Created performance.lua module
   - Added debounced draft saving
   - Implemented memoization and caching
   - Added performance monitoring commands

## Migration Strategy

1. **Backward Compatibility**: Keep existing functions but redirect to new system
2. **Gradual Rollout**: Enable new system with feature flag
3. **Data Migration**: Convert existing drafts to new format
4. **Fallback Mode**: Keep old system available for emergency

## Success Metrics

1. **Draft Content Persistence**: 100% of draft content preserved across sessions
2. **Subject Display**: All drafts show correct subjects in sidebar
3. **Preview Reliability**: Preview works for all draft states
4. **Cleanup Success**: 100% of sent drafts are deleted
5. **Performance**: Draft operations complete in <100ms

## Risk Mitigation

1. **Himalaya Changes**: Abstract himalaya interactions for easy updates
2. **Data Loss**: Implement automatic backups before operations
3. **Performance**: Add caching and lazy loading
4. **Complexity**: Modular design with clear interfaces

## Long-term Considerations

1. **Himalaya Replacement**: Design system to work with alternative backends
2. **Offline Support**: Cache drafts for offline editing
3. **Conflict Resolution**: Handle concurrent edits to same draft
4. **Mobile Sync**: Consider future mobile client integration

## Post-Implementation Analysis: Empty Draft Handling

### Issue Discovered
After implementing the 5-phase refactor, testing revealed that new empty drafts created with `<leader>mw` were not being handled properly:

1. **Empty drafts appear with "(No subject)" in sidebar**
2. **Empty content is not preserved through save/parse cycles**
3. **Draft previews show no content when reopened**

### Root Cause Analysis

The issue is not that drafts should have default content, but that the system doesn't handle the natural lifecycle of empty drafts properly. The problem occurs at several points:

#### 1. Empty Content Preservation
- Empty drafts have minimal structure (just headers + empty body)
- When parsed and re-saved, empty content gets lost
- Parser doesn't distinguish between "no content" and "content parsing failed"

#### 2. Sidebar Display Issues
- Empty subjects show as "(No subject)" which is unclear
- No way to distinguish between "user hasn't added subject yet" vs "failed to load subject"
- Timestamps missing for identification

#### 3. Preview System Gaps
- Empty drafts may not preview correctly
- No indication of draft state (new, edited, etc.)

## Comprehensive Empty Draft Solution

### Phase 6: Elegant Empty Draft Handling

#### 6.1 Draft State Enhancement

**Problem**: Current system doesn't track draft editing state
**Solution**: Enhanced draft state tracking

```lua
-- Enhanced draft state in draft_manager.lua
draft_state = {
  buffer_id = number,
  draft_id = string|nil,
  local_id = string,
  account = string,
  folder = string,
  content = {
    from = string,
    to = string,
    subject = string,
    body = string,
    headers = table
  },
  state = 'new'|'editing'|'syncing'|'synced'|'sending',
  created_at = timestamp,
  last_saved = timestamp,
  last_synced = timestamp,
  last_modified = timestamp,  -- NEW: track when user last edited
  is_empty = boolean,         -- NEW: track if draft is still empty
  user_touched = boolean      -- NEW: track if user has made any edits
}
```

#### 6.2 Smart Subject Handling

**Problem**: Empty subjects show as "(No subject)" which is confusing
**Solution**: Context-aware subject display

```lua
-- In draft_cache.lua - enhanced subject retrieval
function M.get_draft_display_subject(account, folder, draft_id)
  local metadata = M.get_draft_metadata(account, folder, draft_id)
  
  if metadata and metadata.subject and metadata.subject ~= '' then
    return metadata.subject
  end
  
  -- Check draft state for better context
  local draft_state = draft_manager.get_draft_by_id(draft_id)
  if draft_state then
    if not draft_state.user_touched then
      return string.format("New Draft (%s)", os.date("%H:%M", draft_state.created_at))
    elseif draft_state.last_modified then
      return string.format("Draft (%s)", os.date("%H:%M", draft_state.last_modified))
    end
  end
  
  -- Fallback with timestamp
  return string.format("Draft (%s)", os.date("%H:%M", metadata.cached_at or os.time()))
end
```

#### 6.3 Content Preservation Pipeline

**Problem**: Empty content gets lost during save/parse cycles
**Solution**: Content-aware preservation

```lua
-- In email_composer.lua - enhanced content tracking
local function track_content_changes(buf)
  -- Track when user makes actual changes
  vim.api.nvim_create_autocmd({'TextChanged', 'TextChangedI'}, {
    buffer = buf,
    callback = function()
      local draft_state = draft_manager.get_draft(buf)
      if draft_state then
        draft_state.user_touched = true
        draft_state.last_modified = os.time()
        
        -- Check if content is still effectively empty
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local parsed = parse_email_buffer(lines)
        
        draft_state.is_empty = (
          (not parsed.to or parsed.to == '') and
          (not parsed.subject or parsed.subject == '') and
          (not parsed.body or parsed.body:match('^%s*$'))
        )
        
        draft_manager.update_draft_state(buf, draft_state)
      end
    end
  })
end
```

#### 6.4 Smart Save Strategy

**Problem**: Empty drafts may not save meaningfully
**Solution**: State-aware saving

```lua
-- In sync_draft_to_maildir - enhanced empty draft handling
local function sync_draft_to_maildir(draft_file, account, existing_draft_id)
  local content = vim.fn.readfile(draft_file)
  local email = parse_email_buffer(content)
  
  -- Enhanced empty draft detection
  local is_effectively_empty = (
    (not email.to or email.to == '') and
    (not email.subject or email.subject == '') and
    (not email.body or email.body:match('^%s*$'))
  )
  
  -- For empty drafts, ensure minimal but valid structure
  if is_effectively_empty then
    email.subject = ''  -- Explicitly empty, not nil
    email.body = ''     -- Explicitly empty, not nil
    
    -- Add metadata to track empty state
    email.headers = email.headers or {}
    email.headers['X-Draft-State'] = 'empty'
    email.headers['X-Draft-Created'] = os.date('!%Y-%m-%dT%H:%M:%SZ')
  else
    -- Remove empty state marker if content added
    if email.headers and email.headers['X-Draft-State'] then
      email.headers['X-Draft-State'] = nil
    end
  end
  
  -- Proceed with save using enhanced structure
  local ok, result = pcall(utils.save_draft, account, draft_folder, email)
  return ok and result
end
```

#### 6.5 Enhanced Preview System

**Problem**: Empty drafts may not preview correctly
**Solution**: State-aware preview

```lua
-- In email_preview.lua - enhanced empty draft preview
function M.show_empty_draft_preview(draft_id, draft_state)
  local preview_lines = {
    '# Empty Draft',
    '',
    string.format('Created: %s', os.date('%Y-%m-%d %H:%M:%S', draft_state.created_at)),
  }
  
  if draft_state.user_touched then
    table.insert(preview_lines, string.format('Last Modified: %s', 
      os.date('%Y-%m-%d %H:%M:%S', draft_state.last_modified)))
  else
    table.insert(preview_lines, 'Status: New (not yet edited)')
  end
  
  table.insert(preview_lines, '')
  table.insert(preview_lines, '## Instructions')
  table.insert(preview_lines, '- Press Enter to open for editing')
  table.insert(preview_lines, '- Draft will be saved automatically as you type')
  table.insert(preview_lines, '- Add recipients in the To: field')
  table.insert(preview_lines, '- Add a subject line')
  table.insert(preview_lines, '- Write your message in the body')
  
  M.set_preview_content(preview_lines, 'markdown')
end
```

#### 6.6 User Experience Enhancements

**Problem**: Users don't understand draft states
**Solution**: Clear status indicators

```lua
-- Enhanced notifications for draft states
function M.show_draft_status(buf)
  local draft_state = draft_manager.get_draft(buf)
  if not draft_state then return end
  
  local status_msg
  if not draft_state.user_touched then
    status_msg = "New empty draft - start typing to begin composing"
  elseif draft_state.is_empty then
    status_msg = "Draft is empty - add recipients and content"
  else
    status_msg = string.format("Draft saved (%s)", 
      os.date('%H:%M:%S', draft_state.last_saved))
  end
  
  notify.himalaya(status_msg, notify.categories.STATUS)
end
```

### Implementation Plan ✅ COMPLETED

#### Step 1: Enhanced Draft State ✅ COMPLETED (1-2 hours)
1. ✅ Updated `draft_manager.lua` with new state fields (last_modified, is_empty, user_touched)
2. ✅ Added content change tracking in `email_composer.lua`
3. ✅ Implemented `is_empty` and `user_touched` logic and update functions

#### Step 2: Smart Subject Display ✅ COMPLETED (1 hour)
1. ✅ Added `get_draft_display_subject` function to `draft_cache.lua`
2. ✅ Modified email list to use new smart subject function
3. ✅ Smart display shows "New Draft (HH:MM)" or "Draft (HH:MM)" based on state

#### Step 3: Content Preservation ✅ COMPLETED (2-3 hours)
1. ✅ Enhanced `sync_draft_to_maildir` with empty draft detection
2. ✅ Added X-Draft-State and X-Draft-Created metadata headers
3. ✅ Empty drafts now maintain structure with explicit empty fields

#### Step 4: Preview Enhancements ✅ COMPLETED (1-2 hours)
1. ✅ Added `show_empty_draft_preview` function to `email_preview.lua`
2. ✅ Updated preview logic to detect and handle empty drafts
3. ✅ Shows helpful instructions, creation time, and editing status

#### Step 5: User Experience ✅ COMPLETED (1 hour)
1. ✅ Content tracking provides seamless state updates
2. ✅ Smart subjects eliminate confusing "(No subject)" displays
3. ✅ Empty draft preview guides users with clear instructions

### Success Criteria

1. **Empty Draft Creation**: `<leader>mw` creates draft that shows meaningful info in sidebar
2. **Content Preservation**: Empty drafts save/load without losing structure
3. **Progressive Enhancement**: Adding content updates all views immediately
4. **Clear Status**: Users understand what state their draft is in
5. **Graceful Handling**: No "(No subject)" or missing content issues

### Testing Protocol

1. **Empty Draft Lifecycle**:
   - Create empty draft
   - Verify sidebar shows timestamp-based title
   - Open preview (should show helpful info)
   - Open for editing (should have clean structure)

2. **Content Addition**:
   - Add recipient → verify auto-save and sidebar update
   - Add subject → verify sidebar shows real subject
   - Add body → verify content preserved

3. **Edge Cases**:
   - Drafts with only recipient
   - Drafts with only subject
   - Drafts with only body
   - Mixed states across multiple drafts

This solution maintains the natural workflow while ensuring robust handling of all draft states.