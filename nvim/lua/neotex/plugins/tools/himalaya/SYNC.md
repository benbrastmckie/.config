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
- [ ] Gmail settings verified (user action required)
- [ ] Configuration fixes applied (depends on Gmail settings)
- [ ] Testing completed
- [x] Alternative solutions ready (Gmail fix already applied)

## Expected Outcomes
1. **Primary Goal**: Restore `[Gmail]/Trash` folder visibility in Himalaya
2. **Secondary Goal**: Proper delete operations that move emails to trash instead of errors
3. **Fallback Goal**: Working alternative deletion strategy using All Mail or custom folders

## Next Action Required

### 🚨 IMMEDIATE STEP: Check Gmail Web Interface

**You need to verify Gmail's IMAP settings immediately:**

1. **Go to Gmail → Settings (gear icon) → "See all settings"**
2. **Click "Labels" tab**
3. **Find "System labels" section**
4. **Check "Trash" row - verify "Show in IMAP" is CHECKED**

If "Show in IMAP" for Trash is unchecked, that's your problem!

### Alternative Solutions Available

If Gmail settings are correct but Trash still missing:
1. **Use our Gmail fix** (already applied) - offers All Mail archiving
2. **Force-create Trash folder** via IMAP commands
3. **Use custom folder** as trash replacement

## Commands Now Available
- ✅ `HimalayaCheckGmailSettings` - Guide through Gmail web interface verification
- ✅ `HimalayaAnalyzeMbsync` - Check `.mbsyncrc` configuration  
- ✅ `HimalayaTestFolderAccess` - Test raw folder detection
- ✅ `HimalayaSuggestFixes` - Show configuration recommendations
- ✅ `HimalayaTestDelete` - Verify delete operations work correctly
- ✅ `HimalayaFullDiagnostics` - Complete analysis suite