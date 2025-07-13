# Maildir Draft System

This document describes the new Maildir-based draft system implemented in the Himalaya plugin.

## Overview

The draft system has been completely rewritten to use standard Maildir format, eliminating the complex dual storage system (JSON + EML files) and leveraging mbsync for all synchronization.

## Key Benefits

1. **Simplicity**: Single storage format (Maildir) for all emails including drafts
2. **Reliability**: Atomic file operations and standard email format
3. **Performance**: Direct file operations without JSON parsing
4. **Compatibility**: Works with any email client that supports Maildir
5. **Reduced Code**: ~40% reduction in draft-related code

## Architecture

### Storage Structure
```
~/Mail/AccountName/.Drafts/
├── cur/     # Saved drafts
├── new/     # Newly created drafts
└── tmp/     # Temporary files during atomic operations
```

### Draft Lifecycle

1. **Creation**: Draft created directly in Maildir format with 'D' flag
2. **Editing**: Buffer operates on the Maildir file directly
3. **Saving**: Atomic write operations ensure data integrity
4. **Syncing**: mbsync handles all synchronization automatically
5. **Deletion**: Standard file deletion

## Core Components

### maildir.lua
Minimal Maildir operations module:
- `generate_filename()` - Create Maildir-compliant filenames
- `parse_filename()` - Extract metadata from filenames
- `read_headers()` - Parse email headers
- `atomic_write()` - Safe file operations
- `list_messages()` - List emails with flag filtering

### draft_manager_maildir.lua
Simplified draft management:
- Direct Maildir file operations
- No JSON metadata or remote ID tracking
- Buffer to filepath mapping
- Automatic save on buffer write

### email_composer_maildir.lua
Clean email composition:
- Template generation with proper headers
- Direct draft creation in Maildir
- Simplified save operations
- Reply/forward functionality

## Migration

### From Old System
```vim
:HimalayaMigrateDraftsToMaildir [preview]
```

This command:
1. Reads existing JSON/EML drafts
2. Converts to Maildir format with 'D' flag
3. Preserves metadata in X-Himalaya headers
4. Creates backup before migration
5. Deletes original files after verification

### Verification
```vim
:HimalayaDraftMigrationVerify
```

### Rollback
```vim
:HimalayaDraftMigrationRollback [backup_dir]
```

## Usage

### Creating Drafts
```vim
:HimalayaDraftNew [account]
" or
:HimalayaWrite [email]
```

### Managing Drafts
- **Save**: `<C-s>` or `:w`
- **Send**: `<leader>ms`
- **Delete**: `<leader>md`
- **Close**: `<leader>mc`

### Listing Drafts
Drafts appear in the sidebar like any other folder. They are synced via mbsync and displayed with standard email formatting.

## Configuration

Minimal configuration needed:
```lua
himalaya = {
  maildir = {
    draft_flags = "D",  -- Default flag for drafts
  }
}
```

## Testing

Run comprehensive tests:
```vim
:HimalayaTestMaildirIntegration
```

Individual test suites:
- `:HimalayaTestMaildir` - Foundation tests
- `:HimalayaTestDraftManager` - Draft manager tests
- `:HimalayaTestEmailComposer` - Composer tests

## Removed Features

The following features have been removed as they are no longer needed:

1. **Dual Storage**: No more JSON + EML files
2. **Remote ID Tracking**: mbsync handles synchronization
3. **Custom Sync Logic**: Standard mbsync for all folders
4. **Draft-specific Health Checks**: Use standard Maildir checks
5. **Complex State Management**: Simple buffer tracking only

## Troubleshooting

### Drafts Not Appearing
1. Check Maildir structure exists: `~/Mail/AccountName/.Drafts/`
2. Verify mbsync configuration includes Drafts folder
3. Run `:HimalayaSync` to sync with server

### Migration Issues
1. Check backup location from migration output
2. Verify source drafts exist in `~/.local/share/nvim/himalaya/drafts/`
3. Use rollback command if needed

### Performance
- Drafts load instantly (no JSON parsing)
- Saves are atomic and fast
- No background sync processes

## Technical Details

### Maildir Filename Format
```
timestamp.pid_unique.hostname,info:2,flags
```

Example:
```
1752425097.123456_789.hostname,S=1234:2,D
```

### Draft Flag
The 'D' flag marks emails as drafts in Maildir format. This is a standard flag recognized by most email clients.

### Atomic Operations
All writes use the Maildir atomic process:
1. Write to tmp/
2. Move to new/ or cur/
3. Update size in filename

This ensures no data loss even if interrupted.

## Future Enhancements

1. **Draft Templates**: Save and reuse email templates
2. **Draft Versioning**: Keep history of draft changes
3. **Scheduled Sending**: Queue drafts for later sending
4. **Collaborative Drafts**: Share draft editing (via IMAP)

## Summary

The new Maildir-based draft system provides a clean, reliable, and performant solution for managing email drafts. By leveraging standard email formats and tools, it eliminates complexity while maintaining full functionality.