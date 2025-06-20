# Gmail IMAP Sync Diagnostics and Fix Plan

## Problem Summary
Gmail account is missing the Trash folder from Himalaya's folder list, causing "No trash folder found" errors during delete operations. Research indicates this is likely due to Gmail IMAP settings or mbsync configuration issues.

## Research Findings

### Root Causes Identified
1. **Gmail IMAP "Show in IMAP" Settings**: Gmail has specific checkboxes for each system folder that control IMAP visibility
2. **mbsync Configuration Issues**: `.mbsyncrc` might be excluding Gmail folders or missing proper `[Gmail]/Trash` mapping  
3. **Gmail's Non-Standard IMAP**: Gmail uses labels instead of folders, causing visibility issues with email clients

### Common Solutions from Research
- Enable "Trash: Show in IMAP" in Gmail web settings
- Configure proper channel mapping for `[Gmail]/Trash` in mbsync
- Adjust Gmail's "When I mark a message in IMAP as deleted" settings

## Diagnostic and Fix Plan

### Phase 1: Diagnose Gmail IMAP Settings
- [ ] Create command to guide user through Gmail web interface settings verification
- [ ] Check that "Show in IMAP" is enabled for Trash folder in Gmail � Settings � Labels � System labels
- [ ] Verify Gmail � Settings � Forwarding and POP/IMAP � Delete behavior settings

### Phase 2: Examine mbsync Configuration  
- [ ] Read and analyze user's `.mbsyncrc` file
- [ ] Check for Gmail folder patterns and exclusions
- [ ] Verify `[Gmail]/Trash` channel configuration exists
- [ ] Look for potential conflicts (Path + SubFolders Maildir++)

### Phase 3: Test Current Folder Detection
- [ ] Run Himalaya folder list command directly
- [ ] Compare available folders with expected Gmail IMAP folders
- [ ] Test raw IMAP connection to see what Gmail exposes

### Phase 4: Fix Configuration Issues
- [ ] Update `.mbsyncrc` with proper Gmail trash folder mapping if missing
- [ ] Add explicit channel for `[Gmail]/Trash` 
- [ ] Ensure proper quoting and syntax for folder names with spaces/special chars
- [ ] Test configuration changes

### Phase 5: Alternative Solutions
- [ ] If trash folder remains unavailable, implement custom folder workaround
- [ ] Configure to use All Mail as deletion target (Gmail's archive behavior)
- [ ] Update Himalaya delete logic to handle Gmail's label-based system

## Diagnostic Results

### 🔍 Root Cause Identified
**CONFIRMED**: Gmail Trash folder missing due to mbsync configuration issue.

**Current .mbsyncrc Analysis:**
- ✅ Has Gmail IMAP store configured properly (XOAUTH2)
- ✅ Has Gmail local maildir store 
- ✅ Has single "gmail" channel with `Patterns *`
- ❌ **MISSING**: No specific channel for `[Gmail]/Trash` folder
- ⚠️ Uses `Patterns *` which should sync all folders, but Trash is still missing

**Current Folder Status:**
- Available: [Gmail].Sent Mail, [Gmail].All Mail, [Gmail].Drafts + custom folders
- Missing: [Gmail]/Trash, [Gmail]/Spam
- Himalaya sees: 6 folders total, 3 Gmail system folders

### 🎯 Specific Issue
Your mbsync config uses `Patterns *` which should sync all Gmail folders, but Gmail's IMAP is not exposing the Trash folder. This suggests:

1. **Gmail IMAP Setting**: "Show in IMAP" for Trash may be disabled
2. **Gmail Account Setup**: Your Gmail might have non-standard folder configuration

## Implementation Status  
- [x] Research completed
- [x] Plan documented  
- [x] Diagnostics implemented
- [x] Root cause identified
- [x] Comprehensive diagnostic suite created
- [x] Moved tools to util/ directory with documentation
- [x] Local trash implementation plan created
- [x] Phase 6.1: Core trash infrastructure (completed)
- [x] Phase 6.2: Trash operations implementation (completed)
- [x] Phase 6.3: Trash browser UI (completed)
- [ ] Phase 6.4: Management & cleanup features (partial - basic cleanup implemented)
- [x] Basic testing completed

## Expected Outcomes
1. **Primary Goal**: ~~Restore `[Gmail]/Trash` folder visibility in Himalaya~~ → **NEW: Implement local trash directory**
2. **Secondary Goal**: Proper delete operations that move emails to local trash with recovery options
3. **Tertiary Goal**: Full trash management system with UI browser and cleanup automation

## Phase 6: Local Trash Directory Implementation

### 🗂️ USER DECISION: Local Trash Instead of Gmail IMAP Trash

**User preference**: Create local trash directory instead of enabling Gmail IMAP trash folder.

### Benefits of Local Trash Approach
1. **Independent of Gmail settings** - No need to modify Gmail IMAP configuration
2. **Full control** - Complete ownership of deleted emails
3. **Faster operations** - No network dependency for delete operations
4. **Email recovery** - Easy access to deleted emails for salvage
5. **Consistent behavior** - Same trash behavior regardless of email provider

### Implementation Plan

#### Phase 6.1: Local Trash Directory Structure
- [ ] Create local trash directory: `~/Mail/Gmail/trash/` (or user-configurable)
- [ ] Design folder structure for organized trash storage
- [ ] Implement date-based organization (e.g., `YYYY/MM/DD/` subdirectories)
- [ ] Add metadata tracking (original folder, deletion date, email ID)

#### Phase 6.2: Enhanced Delete Operation
- [ ] Modify delete operation to move emails to local trash instead of IMAP trash
- [ ] Preserve original email structure and headers
- [ ] Store deletion metadata (JSON sidecar files or database)
- [ ] Implement atomic move operations to prevent data loss
- [ ] Add progress indicators for large email moves

#### Phase 6.3: Trash Management System
- [ ] Create trash viewing interface (`:HimalayaTrash`)
- [ ] Implement trash browsing with date/folder organization
- [ ] Add email restoration functionality (move back to original folder)
- [ ] Implement permanent deletion (remove from local trash)
- [ ] Add trash cleanup (auto-delete old emails after X days)

#### Phase 6.4: Configuration Options
- [ ] Add trash directory configuration option
- [ ] Configure retention policy (default: 30 days)
- [ ] Add trash size limits and cleanup policies
- [ ] Option to disable/enable local trash vs IMAP trash
- [ ] Backup/export options for trash contents

#### Phase 6.5: UI Integration
- [ ] Add trash folder to folder list (special handling)
- [ ] Implement trash-specific operations (restore, permanent delete)
- [ ] Add trash status indicators (item count, disk usage)
- [ ] Create trash management commands and keymaps
- [ ] Integrate with existing sidebar and navigation

### Technical Implementation Details

#### Directory Structure
```
~/Mail/Gmail/
├── INBOX/           # Regular maildir folders
├── sent/
├── drafts/
└── .trash/          # Local trash directory
    ├── metadata.db  # SQLite database for tracking
    ├── 2024/
    │   ├── 01/
    │   │   ├── 15/  # Daily subdirectories
    │   │   └── 16/
    │   └── 02/
    └── restore_info/ # Backup metadata for restoration
```

#### Metadata Storage Options
**Option A: JSON Sidecar Files**
```json
{
  "email_id": "12345",
  "original_folder": "INBOX", 
  "deleted_date": "2024-01-15T10:30:00Z",
  "deleted_by": "user",
  "restore_path": "INBOX",
  "size_bytes": 5432
}
```

**Option B: SQLite Database**
```sql
CREATE TABLE trash_items (
  id INTEGER PRIMARY KEY,
  email_id TEXT UNIQUE,
  original_folder TEXT,
  deleted_date DATETIME,
  file_path TEXT,
  size_bytes INTEGER,
  restore_info JSON
);
```

#### New Commands to Implement
- `:HimalayaTrash` - Open trash browser
- `:HimalayaTrashRestore <id>` - Restore email to original folder
- `:HimalayaTrashPurge [days]` - Permanently delete old trash items
- `:HimalayaTrashClean` - Clean up orphaned files and metadata
- `:HimalayaTrashStats` - Show trash statistics and disk usage

### Implementation Phases

#### Phase 6.1: Core Infrastructure (Priority: High)
**Tasks:**
- [ ] Create trash directory structure
- [ ] Implement basic file move operations
- [ ] Add metadata storage system
- [ ] Create trash configuration options

**Files to Create/Modify:**
- `trash_manager.lua` - Core trash management
- `config.lua` - Add trash configuration options
- `utils.lua` - Modify delete operations

#### Phase 6.2: Trash Operations (Priority: High)  
**Tasks:**
- [ ] Implement safe email moving to trash
- [ ] Add restoration functionality
- [ ] Create permanent deletion
- [ ] Add error handling and rollback

**Files to Create/Modify:**
- `trash_operations.lua` - Trash-specific operations
- `ui.lua` - Integrate trash operations with UI

#### Phase 6.3: Trash Browser UI (Priority: Medium)
**Tasks:**
- [ ] Create trash folder browser
- [ ] Add date-based navigation
- [ ] Implement trash-specific keymaps
- [ ] Add restoration interface

**Files to Create/Modify:**
- `trash_ui.lua` - Trash browser interface
- `sidebar.lua` - Add trash folder to sidebar
- `keymaps.lua` - Add trash-specific keymaps

#### Phase 6.4: Management & Cleanup (Priority: Low)
**Tasks:**
- [ ] Implement retention policies
- [ ] Add automatic cleanup
- [ ] Create trash statistics
- [ ] Add backup/export functionality

**Files to Create/Modify:**
- `trash_cleanup.lua` - Automated cleanup system
- `trash_stats.lua` - Statistics and reporting

### Configuration Schema

```lua
trash = {
  enabled = true,
  directory = "~/Mail/Gmail/.trash",
  retention_days = 30,
  max_size_mb = 1000,
  organization = "daily", -- "daily", "monthly", "flat"
  metadata_storage = "sqlite", -- "sqlite", "json"
  auto_cleanup = true,
  cleanup_interval_hours = 24
}
```

### User Experience Flow

#### Delete Operation
1. User presses `gD` on an email
2. Email moved to local trash with metadata
3. UI updates immediately (email removed from list)
4. Confirmation: "Email moved to trash (restore available)"

#### Restoration Flow  
1. User opens trash: `:HimalayaTrash`
2. Browse by date or search
3. Select email and press `gR` (restore)
4. Email moved back to original folder
5. Confirmation: "Email restored to INBOX"

#### Cleanup Flow
1. Automatic: Old emails auto-deleted after retention period
2. Manual: `:HimalayaTrashPurge 7` deletes items older than 7 days
3. Confirmation and safety prompts for permanent deletion

## Local Trash System Implementation Summary

### ✅ **Completed Features**

#### Core Infrastructure (Phase 6.1)
- ✅ Local trash directory: `~/Mail/Gmail/.trash/`
- ✅ Date-based organization: `YYYY/MM/DD/` subdirectories
- ✅ JSON metadata tracking with email details
- ✅ Configuration system in `config.lua`
- ✅ Directory structure auto-creation

#### Trash Operations (Phase 6.2)
- ✅ `gD` delete operation now uses local trash
- ✅ Email content preservation in trash files
- ✅ Metadata tracking (ID, folder, date, size)
- ✅ Atomic operations with rollback on failure
- ✅ Integration with existing delete workflow

#### Trash Browser UI (Phase 6.3)
- ✅ `:HimalayaTrash` - Full-featured trash browser
- ✅ Floating window interface with keymaps
- ✅ Email details view (`<CR>`)
- ✅ Restore functionality (`gR`)
- ✅ Permanent delete (`gD`)
- ✅ Real-time refresh (`r`)

#### Management & Cleanup (Phase 6.4 - Partial)
- ✅ Basic cleanup with retention policy
- ✅ Trash statistics and validation
- ✅ File size tracking and reporting

### 📋 **New Commands Available**

#### Diagnostic Commands (Previous)
- ✅ `HimalayaCheckGmailSettings` - Guide through Gmail web interface verification
- ✅ `HimalayaAnalyzeMbsync` - Check `.mbsyncrc` configuration  
- ✅ `HimalayaTestFolderAccess` - Test raw folder detection
- ✅ `HimalayaSuggestFixes` - Show configuration recommendations
- ✅ `HimalayaTestDelete` - Verify delete operations work correctly
- ✅ `HimalayaFullDiagnostics` - Complete analysis suite

#### New Trash Commands
- ✅ `HimalayaTrash` - Open trash browser interface
- ✅ `HimalayaTrashStats` - Show trash statistics
- ✅ `HimalayaTrashList` - List trash contents in terminal
- ✅ `HimalayaTrashRestore <id>` - Restore specific email
- ✅ `HimalayaTrashPurge <id>` - Permanently delete email
- ✅ `HimalayaTrashCleanup` - Clean old items per retention policy
- ✅ `HimalayaTrashValidate` - Validate trash configuration
- ✅ `HimalayaTrashInit` - Manually initialize trash system

### 🎯 **Current Behavior**
1. **Delete Operation (`gD`)**: Emails moved to local trash with full metadata
2. **Trash Browser (`:HimalayaTrash`)**: Visual interface for trash management  
3. **Email Recovery**: Full restoration capability with original folder tracking
4. **Independent Operation**: No dependency on Gmail IMAP settings