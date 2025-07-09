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

### Week 2: Content Handling
1. Implement robust draft parser with state machine
2. Fix content loss in `reopen_draft()`
3. Ensure all draft fields are preserved
4. Add content validation and error recovery

### Week 3: Cache and Display
1. Implement two-tier cache system
2. Fix sidebar subject display
3. Persist draft metadata across sessions
4. Optimize cache invalidation strategy

### Week 4: Preview and Cleanup
1. Rewrite preview system for drafts
2. Fix draft deletion after send
3. Handle all edge cases (network failures, etc.)
4. Add retry logic for failed operations

### Week 5: Testing and Polish
1. Create comprehensive test suite
2. Add debug commands for troubleshooting
3. Document all workarounds and limitations
4. Performance optimization

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

## Conclusion

This comprehensive refactor addresses all current draft issues by:
- Creating a robust state management layer
- Implementing proper ID validation
- Building a smart caching system
- Fixing content parsing and preview
- Ensuring reliable draft cleanup

The modular design allows for incremental implementation while maintaining system stability. Each phase builds on the previous, creating a solid foundation for reliable draft functionality.