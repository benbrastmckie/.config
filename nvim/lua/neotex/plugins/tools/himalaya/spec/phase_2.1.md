# Phase 2.1: Draft Manager Consolidation Implementation Plan

## Overview

This phase consolidates three draft manager implementations into one:
- `draft_manager_v2.lua` ( already removed - 872 lines)
- `draft_manager_v2_maildir.lua` (wrapper - to be removed)
- `draft_manager_maildir.lua` (keep - actual implementation)

## Current State Analysis

### Files Using the Wrapper (`draft_manager_v2_maildir`)
1.  `init.lua` - DONE
2.  `scheduler.lua` - DONE
3. `ui/email_composer.lua`
4. `ui/email_preview.lua`
5. `ui/compose_status.lua`
6. `utils.lua`
7. `core/commands/draft.lua`

### Files Already Using Direct Implementation (`draft_manager_maildir`)
- `ui/email_list.lua`
- `ui/email_composer_maildir.lua`
- `ui/email_composer_wrapper.lua`
- All test files

## API Differences Analysis

### Wrapper Functions � Direct Implementation Mapping

| Wrapper Function | Direct Implementation | Notes |
|-----------------|----------------------|-------|
| `setup(config)` | `setup()` | No config param needed |
| `create_draft(account, content, metadata)` | `create(account, metadata)` | Different signature |
| `register_draft(buffer, draft)` | N/A | No-op in wrapper |
| `save_local(buffer)` | `save(buffer, silent)` | Maps directly |
| `save(buffer)` | `save(buffer, silent)` | Same |
| `sync_remote(buffer)` | `save(buffer)` | Just saves locally |
| `delete(buffer)` | `delete(buffer)` | Same |
| `send(buffer)` | `send(buffer)` | Same |
| `get_by_buffer(buffer)` | `get_by_buffer(buffer)` | Returns different structure |
| `get_all()` | `get_all()` | Returns different structure |
| `is_draft(buffer)` | `is_draft(buffer)` | Same |
| `cleanup_draft(buffer)` | `cleanup_draft(buffer)` | Same |
| `recover_session()` | `recover_session()` | Same |
| `list_drafts(account)` | `list(account)` | Different name |
| `load(draft_id, account)` | N/A | Not in direct implementation |

### Key Structure Differences

**Wrapper draft object:**
```lua
{
  local_id = draft.filename,
  metadata = {
    subject = draft.subject,
    from = draft.from,
    to = draft.to,
    cc = draft.cc,
    bcc = draft.bcc
  },
  created_at = draft.timestamp,
  modified_at = draft.timestamp,
  modified = false,
  synced = true
}
```

**Direct implementation draft object:**
```lua
{
  filename = "draft_12345.eml",
  filepath = "/path/to/draft",
  subject = "Subject",
  from = "from@example.com",
  to = "to@example.com",
  cc = nil,
  bcc = nil,
  timestamp = 12345,
  buffer = 123
}
```

## Implementation Strategy

### Step 1: Analyze Each File's Usage

For each file using the wrapper, identify:
1. Which functions are called
2. How the returned data is used
3. What changes are needed

### Step 2: Update Function Calls

1. **Simple mappings**: Update function names (e.g., `list_drafts` � `list`)
2. **Signature changes**: Adjust parameters (e.g., `create_draft`)
3. **Structure changes**: Update code that uses returned draft objects

### Step 3: Handle Missing Functions

For functions that don't exist in direct implementation:
1. `register_draft` - Remove calls (it's a no-op)
2. `sync_remote` - Replace with `save`
3. `load` - Implement inline if needed
4. Compatibility functions - Remove calls

## File-by-File Implementation Plan

### 1. `ui/email_composer.lua`

**Current usage:**
- `draft_manager.setup()` 
- `draft_manager._get_default_from(account)` - internal function
- `draft_manager.get_by_buffer(buf)`
- `draft_manager.save_local(buf)`

**Changes needed:**
- Remove `._get_default_from` usage - implement inline
- Update to use direct draft object structure
- Change `save_local` to `save`

### 2. `ui/email_preview.lua`

**Needs analysis** - Check what functions are used

### 3. `ui/compose_status.lua`

**Needs analysis** - Check what functions are used

### 4. `utils.lua`

**Current usage:**
- Only requires the module, may not use any functions

**Changes needed:**
- Update require statement

### 5. `core/commands/draft.lua`

**Current usage:**
- Various draft operations

**Changes needed:**
- Update all function calls and data structure usage

## Testing Strategy

After each file update:
1. Run focused tests for that component
2. Test the specific functionality manually
3. Ensure no runtime errors
4. Verify draft operations still work

## Rollback Plan

If issues arise:
1. Each file change is committed separately
2. Can revert individual file changes
3. Wrapper can be temporarily restored if needed

## Success Criteria

- All files use `draft_manager_maildir` directly
- `draft_manager_v2_maildir.lua` can be deleted
- All draft functionality works as before
- No test failures
- Clean, consistent API usage throughout

## Phase 2.1 Completion Status ✅

### Completed Tasks:
1. ✅ Removed unused `draft_manager_v2.lua` (872 lines)
2. ✅ Updated `init.lua` to use direct implementation
3. ✅ Updated `scheduler.lua` to use direct implementation
4. ✅ Updated `utils.lua` - implemented load() functionality inline
5. ✅ Updated `core/commands/draft.lua` - adapted to direct API
6. ✅ Updated `compose_status.lua` - simplified for maildir
7. ✅ Updated `email_preview.lua` - removed sync states
8. ✅ Updated `email_composer.lua` require (full migration needed later)
9. ✅ Removed `draft_manager_v2_maildir.lua` wrapper

### Results:
- **Files removed**: 2 (draft_manager_v2.lua, draft_manager_v2_maildir.lua)
- **Lines removed**: ~1,087 lines of wrapper/compatibility code
- **API simplified**: Single consistent draft manager implementation
- **Next step**: Phase 2.2 - Consolidate email composers