# Drafts Maildir Migration Plan (Revised)

This document provides a systematic implementation plan for migrating the draft system from the dual EML/JSON format to pure Maildir format, eliminating redundancies and ensuring consistency with inbox email handling.

## Executive Summary

The current draft system uses a complex dual-format approach (JSON + EML files) that creates unnecessary redundancy with the Maildir format already used by mbsync. This migration will:

1. **Eliminate dual storage** - Use only Maildir format like inbox emails
2. **Remove redundant modules** - Delete 6 draft-specific modules
3. **Unify sync mechanism** - Use mbsync for everything
4. **Simplify ID management** - Use Maildir filenames as IDs
5. **Reduce codebase by ~40%** - Remove ~2000 lines of draft-specific code

## Current Architecture Analysis

### Redundant Components to Remove

1. **Storage Layer Redundancy**
   - `core/local_storage.lua` - Entire JSON/EML storage system (294 lines)
   - Draft-specific storage in `~/.local/share/nvim/himalaya/drafts/`
   - JSON index management and file operations

2. **Draft-Specific Modules**
   - `core/draft_cleanup.lua` - Redundant with Maildir operations
   - `core/draft_migration.lua` - One-time use, then delete
   - `core/draft_nuclear.lua` - Emergency cleanup, not needed with Maildir
   - `core/draft_account_fix.lua` - Workaround for JSON issues
   - `core/health/draft.lua` - Draft-specific health checks

3. **Sync Redundancy**
   - Custom draft sync via `himalaya template save`
   - Remote ID fetching after sync
   - Separate sync status tracking for drafts

4. **ID Management Complexity**
   - Local ID generation (timestamp + hrtime)
   - Remote ID mapping
   - Complex ID lookups across multiple stores

### Components to Simplify

1. **draft_manager_v2.lua**
   - Remove local_storage dependencies
   - Simplify to Maildir operations only
   - Remove sync orchestration (mbsync handles it)
   - Use Maildir filename as single ID

2. **email_composer.lua**
   - Create drafts directly in Maildir
   - Remove EML file management
   - Simplify save operations

3. **email_list.lua**
   - Remove special draft handling
   - Treat drafts like any other folder
   - Simplify refresh logic

## Target Architecture

### Unified Storage
```
~/Mail/Gmail/.Drafts/
├── cur/     # All drafts (local and synced)
├── new/     # Newly created (by himalaya)
└── tmp/     # Temporary during creation
```

### Simplified ID System
- **Draft ID** = Maildir filename (e.g., `1752425097.123456_789.nandi,D:2,`)
- **No mapping** between local and remote IDs
- **Direct reference** in buffers and UI

### Unified Sync
- mbsync handles all folders including drafts
- No custom sync commands
- No remote ID fetching
- Standard conflict resolution

## Implementation Phases

### Phase 1: Maildir Module & Migration Tool (Day 1)

1. **Create Minimal Maildir Module** (`core/maildir.lua`):
   ```lua
   -- Only what's needed, no abstractions for future use
   M.generate_filename(flags) -- Create Maildir filename
   M.parse_filename(filename) -- Extract metadata
   M.read_headers(filepath) -- Read email headers
   M.atomic_write(tmp_path, target_path, content) -- Safe write
   ```

2. **Create Migration Script** (`migrations/draft_to_maildir.lua`):
   - Scan JSON/EML files
   - Convert to Maildir with 'D' flag
   - Preserve metadata in headers
   - Delete source files after verification

3. **Testing**:
   - Test Maildir operations
   - Test migration with real drafts
   - Verify no data loss

### Phase 2: Update Draft Manager (Day 2)

1. **Simplify draft_manager_v2.lua**:
   - Remove all local_storage imports
   - Replace with direct Maildir operations
   - Remove sync methods (let mbsync handle it)
   - Simplify state to just track buffer associations

2. **Remove Complexity**:
   - Delete state management for sync
   - Remove remote ID tracking
   - Delete JSON index code
   - Simplify to ~200 lines (from 846)

3. **Testing**:
   - Test draft CRUD operations
   - Verify mbsync handles sync
   - Check state persistence

### Phase 3: Update Email Composer (Day 3)

1. **Simplify Creation**:
   ```lua
   function M.create_compose_buffer(opts)
     -- Generate Maildir filename
     local filename = maildir.generate_filename({'D'})
     
     -- Write directly to .Drafts/new/
     local draft_path = maildir_path .. '/.Drafts/new/' .. filename
     
     -- Create buffer with draft_path as name
     local buf = vim.api.nvim_create_buf(true, false)
     vim.api.nvim_buf_set_name(buf, draft_path)
     
     -- No complex ID tracking needed
   end
   ```

2. **Simplify Save**:
   - Direct write to Maildir file
   - No JSON metadata updates
   - No sync triggering

3. **Testing**:
   - Test draft creation
   - Test autosave
   - Test buffer management

### Phase 4: Clean Up Sidebar (Day 4)

1. **Remove Special Draft Handling**:
   - Delete local draft merging code
   - Remove draft-specific caching
   - Treat drafts folder like inbox

2. **Simplify Display**:
   - Use himalaya output directly
   - No subject enrichment needed
   - Standard email formatting

3. **Testing**:
   - Verify all drafts appear
   - Test refresh functionality
   - Check performance

### Phase 5: Delete Redundant Code (Day 5)

1. **Delete Modules**:
   ```bash
   rm core/local_storage.lua
   rm core/draft_cleanup.lua
   rm core/draft_migration.lua
   rm core/draft_nuclear.lua
   rm core/draft_account_fix.lua
   rm core/health/draft.lua
   ```

2. **Remove Commands**:
   - Delete draft-specific sync commands
   - Remove cleanup commands
   - Keep only New/Save/Delete

3. **Update Documentation**:
   - Remove references to dual format
   - Update architecture docs
   - Simplify user guide

### Phase 6: Final Integration (Day 6)

1. **Verify Integration**:
   - All tests pass
   - mbsync handles drafts properly
   - UI works seamlessly

2. **Performance Optimization**:
   - Cache Maildir stat() calls
   - Optimize directory scanning
   - Batch UI updates

## Migration Strategy

### User Migration Command
```vim
:HimalayaMigrateDraftsToMaildir
```

### Automatic Migration
On first run after update:
1. Check for JSON/EML drafts
2. Prompt user to migrate
3. Run migration with progress
4. Verify and cleanup

### Safety Measures
1. Backup JSON/EML files before migration
2. Verify each draft after conversion
3. Keep backups for 7 days
4. Provide rollback command

## Benefits Over Current System

1. **Simplicity**
   - Single storage format
   - Standard email tools work
   - No custom sync logic

2. **Performance**
   - No JSON parsing
   - Direct file operations
   - Native mbsync speed

3. **Reliability**
   - Atomic Maildir operations
   - No sync state corruption
   - Standard conflict resolution

4. **Maintainability**
   - 40% less code
   - No abstraction layers
   - Standard email format

## Configuration Changes

### Remove These Settings
```lua
-- Delete entirely
himalaya.drafts = {
  local_storage_path = "...",
  use_json_index = true,
  sync_interval = 30,
  auto_sync = true,
}
```

### Add Minimal Settings
```lua
-- In existing himalaya config
himalaya.maildir = {
  draft_flags = "D",  -- Default flag for drafts
}
```

## Success Metrics

1. **Code Reduction**: Remove >2000 lines
2. **Module Count**: Delete 6 modules
3. **Performance**: 50% faster draft operations
4. **Reliability**: Zero sync conflicts
5. **Simplicity**: No custom storage format

## Risk Mitigation

1. **Data Loss**: Full backup before migration
2. **User Disruption**: Clear migration messages
3. **Sync Issues**: Test with mbsync thoroughly
4. **Performance**: Profile before/after

## Timeline

- **Day 1**: Maildir module + migration tool
- **Day 2**: Simplify draft manager
- **Day 3**: Update email composer
- **Day 4**: Clean up sidebar
- **Day 5**: Delete redundant code
- **Day 6**: Final integration

Total: 6 days (same as before, but much more cleanup)

## Conclusion

This revised plan focuses on **removing complexity** rather than adding new abstractions. By eliminating the dual storage format and leveraging mbsync's existing Maildir support, we can:

- Remove 6 entire modules
- Simplify 4 core modules
- Delete >40% of draft-related code
- Achieve better performance and reliability
- Maintain full functionality

The key insight is that drafts don't need special treatment - they're just emails in a Drafts folder that mbsync can handle like any other folder.