# Event Handling Cleanup Plan

## Executive Summary

This document outlines a systematic plan to clean up the Himalaya event handling system, focusing on eliminating redundancy, establishing single sources of truth, and ensuring proper file synchronization. The plan follows the principles outlined in CODE_STANDARDS.md.

## Current Issues

### 1. Duplicate Event Handlers
**Problem**: Multiple handlers for the same event create race conditions and unpredictable behavior.

**Example**: DRAFT_SAVED has handlers in:
- `orchestration/integration.lua` (100ms delay)
- `ui/email_list.lua` (200ms delay)

**Impact**: Inconsistent refresh behavior, potential double-refreshes, timing conflicts.

### 2. File Synchronization Issues
**Problem**: File writes may not be fully flushed to disk when refresh occurs.

**Evidence**: 
- First save works (no previous file state)
- Subsequent saves fail (stale data read)
- Suggests filesystem caching/sync issues

### 3. Event System Fragmentation
**Problem**: Event handling spread across multiple modules without clear ownership.

**Locations**:
- Event definitions: `core/events.lua`
- Event bus: `orchestration/events.lua`
- Integration handlers: `orchestration/integration.lua`
- Module-specific handlers: Various UI modules

## Proposed Architecture

### Design Principles (per CODE_STANDARDS.md)

1. **Single Source of Truth**: One authoritative handler per event
2. **No Redundancy**: Eliminate duplicate handlers
3. **Clean Architecture**: Clear event flow and ownership
4. **Systematic Integration**: Proper coordination between modules

### Event Handler Organization

```
Event Flow:
1. Action occurs (e.g., draft save)
2. Event emitted via central bus
3. Single handler processes event
4. Handler coordinates necessary updates
```

## Implementation Plan

### Phase 1: Audit Existing Event Handlers

**Goal**: Document all event handlers and their purposes.

**Tasks**:
1. Search for all `events.on()` and `events_bus.on()` calls
2. Create matrix of events → handlers → actions
3. Identify duplicates and conflicts
4. Document timing requirements

**Deliverable**: Event handler audit table

### Phase 2: Consolidate Event Handlers

**Goal**: Establish single handler per event with clear ownership.

**Rules**:
1. UI events → Handle in appropriate UI module
2. Data events → Handle in data module or orchestration layer
3. Cross-cutting events → Handle in orchestration layer

**Specific Changes**:

#### DRAFT_SAVED Event
- **Remove**: Handler in `orchestration/integration.lua`
- **Keep**: Handler in `ui/email_list.lua` (closer to UI concern)
- **Enhance**: Add proper file synchronization

#### Other Duplicate Events
- Audit and consolidate following same pattern
- Document rationale for handler location

### Phase 3: Implement File Synchronization

**Goal**: Ensure file writes are complete before processing.

**Changes to `draft_manager_maildir.lua` save function**:

```lua
function M.save(buffer, silent)
  local filepath = M.buffer_drafts[buffer]
  if not filepath then
    return false, 'No draft associated with buffer'
  end
  
  -- Reconstruct the MIME email
  local content = reconstruct_mime_email(buffer)
  
  -- Save with proper synchronization
  local file = io.open(filepath, 'w')
  if file then
    file:write(content)
    file:flush()  -- Force flush to OS
    file:close()
    
    -- Ensure filesystem sync (platform-specific)
    if vim.fn.has('unix') == 1 then
      -- Use sync for critical data
      vim.fn.system({'sync', '-f', filepath})
    end
  else
    return false, 'Failed to write file'
  end
  
  -- Update modification time AFTER sync
  vim.loop.fs_utime(filepath, os.time(), os.time())
  
  -- Mark buffer as unmodified
  vim.api.nvim_buf_set_option(buffer, 'modified', false)
  
  -- Emit event only after file is fully written
  events_bus.emit(event_types.DRAFT_SAVED, {
    filepath = filepath,
    buffer = buffer
  })
  
  -- Notification handling...
end
```

### Phase 4: Optimize Event Timing

**Goal**: Ensure proper sequencing and timing of events.

**Changes**:

1. **Standardize delays**:
   - File write operations: 200ms minimum
   - UI updates: 50ms for responsiveness
   - Network operations: Configure based on operation

2. **Add event sequencing**:
   ```lua
   -- Ensure events complete in order
   events.on(event_constants.DRAFT_SAVED, function(data)
     -- Mark as processing
     state.set('draft.refreshing', true)
     
     vim.defer_fn(function()
       M.refresh_email_list()
       state.set('draft.refreshing', false)
     end, 200)
   end)
   ```

3. **Prevent double-processing**:
   - Check if refresh already in progress
   - Debounce rapid saves

### Phase 5: Testing Strategy

**Goal**: Verify improvements work reliably.

**Test Cases**:

1. **Single Save Test**:
   - Open draft
   - Change subject
   - Save once
   - Verify immediate update

2. **Multiple Save Test**:
   - Open draft
   - Change subject and save
   - Change subject again and save
   - Repeat 5x rapidly
   - Verify all updates appear

3. **Concurrent Operation Test**:
   - Save draft while sync running
   - Verify no conflicts

4. **Platform Test**:
   - Test on different filesystems
   - Verify sync behavior

### Phase 6: Documentation Update

**Goal**: Document new event architecture.

**Updates needed**:
1. Update event flow diagrams
2. Document handler ownership
3. Add troubleshooting guide
4. Update developer guidelines

## Migration Strategy

### Safe Migration Steps

1. **Add file sync first** (non-breaking)
2. **Test with both handlers active**
3. **Remove duplicate handler**
4. **Monitor for issues**
5. **Document lessons learned**

### Rollback Plan

If issues occur:
1. Re-enable removed handler temporarily
2. Add logging to identify root cause
3. Fix and retry

## Success Metrics

1. **Reliability**: 100% of saves update sidebar immediately
2. **Performance**: No noticeable delay in UI updates
3. **Consistency**: Same behavior on all platforms
4. **Maintainability**: Reduced code complexity

## Risk Assessment

### Low Risk
- Adding file flush/sync (backwards compatible)
- Removing duplicate handlers (one is redundant)

### Medium Risk  
- Changing event timing (may affect other features)
- Platform-specific sync behavior

### Mitigation
- Extensive testing before deployment
- Feature flag for new sync behavior
- Gradual rollout

## Implementation Timeline

1. **Week 1**: Audit and documentation
2. **Week 2**: File sync implementation
3. **Week 3**: Handler consolidation
4. **Week 4**: Testing and refinement

## Code Cleanup Opportunities

Following CODE_STANDARDS.md principles:

1. **Remove**: Duplicate event handlers
2. **Simplify**: Event timing logic
3. **Consolidate**: Related event handling
4. **Document**: Clear ownership model

## Conclusion

This plan addresses the root causes of the draft refresh issue while improving the overall event handling architecture. By following the systematic approach outlined in CODE_STANDARDS.md, we ensure a clean, maintainable solution that prevents similar issues in the future.