# Draft Ordering Fix Implementation Plan

This document outlines the systematic fix for the draft ordering and duplicate display issues in the Himalaya plugin.

## Problem Analysis

### Current Issues
1. **Duplicate Drafts**: Drafts appear twice due to flawed merging of himalaya and filesystem data
2. **Invalid Timestamps**: Dates show as 1970-01-01 due to scientific notation in filenames breaking parsing
3. **Inconsistent Ordering**: Drafts jump positions after creation/save due to cache synchronization issues
4. **Architectural Complexity**: Current hybrid approach creates multiple failure points

### Root Causes
1. **Filename Generation Bug**: Using `vim.loop.hrtime()` creates numbers too large, formatted as scientific notation
2. **Dual Data Sources**: Attempting to merge himalaya's cached data with filesystem creates synchronization issues
3. **Flawed Matching Logic**: Subject+from matching fails for untitled drafts and different from field formats
4. **Parser Limitations**: Maildir parser regex cannot handle scientific notation in filenames

### Affected Components
- `core/maildir.lua` - Filename generation
- `ui/email_list.lua` - Draft display and merging logic
- `core/draft_manager_maildir.lua` - Draft listing

## Design Decision: Filesystem as Single Source of Truth

For the drafts folder, we will use ONLY filesystem data, bypassing himalaya's envelope list entirely. This approach:
- Eliminates synchronization issues
- Provides immediate updates
- Simplifies the codebase significantly
- Maintains compatibility with preview functionality

## Phase-Based Implementation

### Phase 1: Fix Filename Generation ✅ COMPLETE

**Goal**: Ensure Maildir-compliant filenames without scientific notation

1. **Pre-Phase Analysis**:
   - [x] Identified scientific notation issue in hrtime usage
   - [x] Confirmed mbsync filename format compatibility requirements
   - [x] Plan filename format that works with existing parsers

2. **Implementation**:
   ```lua
   -- In core/maildir.lua, modify M.generate_filename()
   -- Change from:
   local filename = string.format(
     "%d.%s_%s.%s,%s:2,%s",
     timestamp,
     hrtime,  -- This becomes scientific notation
     unique,
     hostname,
     info,
     flag_str
   )
   
   -- To:
   local filename = string.format(
     "%d.%d_%d.%s,%s:2,%s",
     timestamp,
     math.floor(hrtime / 1000000),  -- Convert nanoseconds to milliseconds
     vim.loop.getpid(),
     hostname,
     info,
     flag_str
   )
   ```

3. **Testing**:
   - [x] Create new draft and verify filename format
   - [x] Ensure parser can handle new format
   - [x] Verify no scientific notation in filenames
   - [x] Check sorting works correctly

4. **Cleanup**:
   - [x] Remove any workarounds for scientific notation
   - [x] Ensure consistent formatting throughout

### Phase 2: Remove Hybrid Draft Display Logic ✅ COMPLETE

**Goal**: Use filesystem as single source of truth for drafts

1. **Pre-Phase Analysis**:
   - [x] Map all code paths that fetch draft data
   - [x] Identify himalaya envelope list dependencies
   - [x] Plan preview functionality preservation

2. **Implementation**:
   ```lua
   -- In ui/email_list.lua, replace complex merging with:
   if is_drafts then
     -- Use draft_manager directly, bypass himalaya
     local draft_manager = require('..draft_manager_maildir')
     local draft_list = draft_manager.list(account_name)
     
     -- Convert to email format for display
     emails = {}
     for _, draft in ipairs(draft_list) do
       local email = {
         id = draft.filename,  -- Use filename as stable ID
         subject = draft.subject or 'Untitled',
         from = draft.from or '',
         to = draft.to or '',
         date = os.date('%Y-%m-%d %H:%M:%S', draft.mtime),
         mtime = draft.mtime,
         draft_filepath = draft.filepath,
         flags = { draft = true }
       }
       table.insert(emails, email)
     end
     
     total_count = #emails
   else
     -- Non-draft folders continue using himalaya
     utils.get_emails_async(...)
   end
   ```

3. **Testing**:
   - [x] Verify no duplicates in draft display
   - [x] Test draft creation shows immediately
   - [x] Confirm sorting remains stable
   - [x] Check preview still works

4. **Cleanup**:
   - [x] Delete all draft merging logic
   - [x] Remove complex matching code
   - [x] Simplify email_keys logic

### Phase 3: Enhance Draft Preview Integration ✅ COMPLETE

**Goal**: Ensure preview works with filesystem-based drafts

1. **Pre-Phase Analysis**:
   - [x] Trace preview code paths
   - [x] Identify ID usage for preview
   - [x] Plan ID mapping strategy

2. **Implementation**:
   - Preview system already handles filesystem drafts correctly
   - Uses filename as ID which works with existing preview logic
   - load_draft_content function in email_preview.lua checks for filesystem drafts

3. **Testing**:
   - [x] Preview system verified to work with filename IDs
   - [x] Content displays correctly from filesystem
   - [x] No changes needed - existing system handles it

### Phase 4: Optimize Performance (Day 2-3)

**Goal**: Ensure fast draft listing and updates

1. **Pre-Phase Analysis**:
   - [ ] Profile current draft listing performance
   - [ ] Identify any bottlenecks
   - [ ] Plan caching strategy if needed

2. **Implementation**:
   - [ ] Add minimal caching if needed
   - [ ] Optimize file reading
   - [ ] Reduce unnecessary refreshes

3. **Testing**:
   - [ ] Measure draft list load time
   - [ ] Test with many drafts (50+)
   - [ ] Verify instant updates

### Phase 5: Final Cleanup and Documentation (Day 3)

**Goal**: Remove all compatibility code and document the new system

1. **Implementation**:
   - [ ] Remove ALL temporary compatibility code
   - [ ] Delete unused functions
   - [ ] Simplify data structures

2. **Documentation**:
   - [ ] Update this file with results
   - [ ] Update module documentation
   - [ ] Create user-facing documentation
   - [ ] Update parent README.md

3. **Metrics**:
   ```markdown
   ## Refactor Results
   - Lines removed: ~65
   - Code reduction: ~30% in draft display logic
   - Functions deleted: 0 (simplified existing functions)
   - Complexity eliminated: Draft merging logic, dual data source handling
   ```

## Testing Strategy

### Unit Tests
```lua
-- test_drafts_filesystem.lua
describe("Draft filesystem operations", function()
  it("generates valid maildir filenames", function()
    local filename = maildir.generate_filename({'D'})
    assert.no_match("e%+", filename)  -- No scientific notation
  end)
  
  it("parses all filename formats", function()
    -- Test mbsync format
    -- Test our format
    -- Test edge cases
  end)
end)
```

### Integration Tests
```lua
-- test_drafts_display.lua
describe("Draft display", function()
  it("shows drafts immediately after creation", function()
    -- Create draft
    -- Refresh sidebar
    -- Verify appears at top
  end)
  
  it("maintains order after save", function()
    -- Create multiple drafts
    -- Save one
    -- Verify order unchanged
  end)
end)
```

### Manual Testing Checklist
- [ ] Create new draft - appears at top immediately
- [ ] Save draft - position maintained
- [ ] Close/reopen sidebar - order preserved
- [ ] Preview draft - content displays
- [ ] Multiple drafts - no duplicates
- [ ] Draft with same subject - displays correctly
- [ ] Untitled draft - shows "Untitled"
- [ ] Performance with 50+ drafts

## Implementation Timeline

- **Day 1**: Phase 1 (Filename fix) + Phase 2 start
- **Day 2**: Phase 2 complete + Phase 3
- **Day 3**: Phase 4 + Phase 5

## Success Criteria

1. **No Duplicate Drafts**: Each draft appears exactly once
2. **Stable Ordering**: Drafts maintain position across operations
3. **Valid Timestamps**: No 1970-01-01 dates
4. **Immediate Updates**: New drafts appear instantly
5. **Working Preview**: All drafts can be previewed
6. **Performance**: <100ms to display draft list
7. **Code Reduction**: At least 30% reduction in email_list.lua complexity

## Risk Mitigation

1. **Preview Breakage**: Maintain draft_filepath for direct reading
2. **Performance Issues**: Add simple mtime-based cache if needed
3. **Compatibility**: Ensure mbsync drafts still display correctly

## Post-Implementation Review

After implementation:
1. Measure actual code reduction
2. Document any discovered edge cases
3. Update test suite with regression tests
4. Consider applying pattern to other folders if successful

## Navigation
- [< Parent Directory](../README.md)
- [Guidelines](CODE_STANDARDS.md)
