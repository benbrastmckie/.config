# Himalaya Email Client Integration Status Report

## Overview
This document tracks the implementation and configuration of the Himalaya email client with bidirectional Gmail synchronization using mbsync and XOAUTH2 authentication.

##  Completed Tasks

### 1. XOAUTH2 Authentication Support
- **Problem**: mbsync didn't have XOAUTH2 support for Gmail OAuth2 authentication
- **Solution**: Custom NixOS configuration building mbsync with integrated XOAUTH2 plugin
- **Implementation**: 
  ```nix
  cyrus-sasl-with-xoauth2 = cyrus_sasl.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ [ cyrus-sasl-xoauth2 ];
    postInstall = (oldAttrs.postInstall or "") + ''
      cp ${cyrus-sasl-xoauth2}/lib/sasl2/* $out/lib/sasl2/
    '';
  });
  ```
- **Status**:  Working - mbsync can authenticate with Gmail using XOAUTH2

### 2. Environment Variable Configuration
- **Problem**: mbsync couldn't find XOAUTH2 plugin and OAuth refresh was failing
- **Solution**: Proper environment variables set in `~/.config/fish/conf.d/private.fish`
  - `GMAIL_CLIENT_ID`: For OAuth client identification
  - `SASL_PATH`: For XOAUTH2 plugin discovery
- **Status**:  Working in interactive shells

### 3. Sync State Corruption Recovery
- **Problem**: Multiple killed mbsync processes corrupted `.mbsyncstate` files
- **Impact**: mbsync tried to re-download all 7,677 INBOX emails, hitting Gmail rate limits
- **Solution**: Rebuilt INBOX sync state from existing local emails
  - Processed 7,677 existing emails
  - Created proper UID mappings (Remote: 350001-357672, Local: 1-7672)
  - Preserved email flags (Seen, Replied, Flagged)
- **Status**:  Complete for INBOX

### 4. Himalaya Enhanced Sync Integration
- **Problem**: `<leader>ms` keymap wasn't providing proper user feedback
- **Solution**: Enhanced sync function with:
  - Immediate "Mail sync started..." notification
  - Real-time progress updates
  - Progress warnings at 30s, 1min, 2min, 5min intervals
  - No automatic process termination (let sync complete)
- **Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/native_sync.lua`
- **Status**:  Implemented, needs testing

### 5. NixOS Configuration Management
- **Approach**: All mbsync/isync configuration managed through NixOS home-manager
- **Benefits**: Reproducible, version-controlled email configuration
- **Status**:  Active configuration

##   Current Issues

### 1. OAuth Token Refresh Service
- **Problem**: `gmail-oauth2-refresh.service` fails with "Missing OAuth2 credentials"
- **Root Cause**: `GMAIL_CLIENT_ID` environment variable not available to systemd service
- **Current Error**: 
  ```
  Jun 24 11:20:47 nandi refresh-gmail-oauth2[748345]: Missing OAuth2 credentials. Please reconfigure: himalaya account configure gmail
  ```
- **Impact**: OAuth tokens can't be automatically refreshed

### 2. Sync State Missing for Large Folders
- **Folders Needing Rebuild**:
  - `Sent`: 26,617 emails (missing .mbsyncstate)
  - `All Mail`: 24,962 emails (missing .mbsyncstate)
  - `Spam`: 1 email (missing .mbsyncstate)
  - `Trash`: 1 email (missing .mbsyncstate)
- **Impact**: These folders will attempt full re-download when synced

## =' Required Fixes

### 1. Fix Systemd Service Environment (HIGH PRIORITY)
**Problem**: OAuth refresh service lacks environment variables

**Solution Options**:

**Option A - NixOS Configuration** (Recommended):
```nix
systemd.user.services.gmail-oauth2-refresh.Service.Environment = [
  "GMAIL_CLIENT_ID=${config.home.sessionVariables.GMAIL_CLIENT_ID}"
];
```

**Option B - Manual Service Override**:
```bash
systemctl --user edit gmail-oauth2-refresh.service
```
Add:
```ini
[Service]
Environment="GMAIL_CLIENT_ID=your_actual_client_id_here"
```

**Expected Result**: OAuth token refresh will work automatically

### 2. Test Complete Email Sync Workflow
After fixing OAuth refresh:

1. **Test mbsync directly**:
   ```bash
   mbsync gmail-inbox  # Should only sync new emails
   ```

2. **Test Himalaya integration**:
   - Open Himalaya in Neovim
   - Press `<leader>ms`
   - Should see progress notifications
   - New emails should appear

3. **Test bidirectional sync**:
   - Delete email in Himalaya sidebar (`gD`)
   - Should sync deletion to Gmail
   - Send email to yourself in Gmail
   - Should appear in Himalaya after sync

### 3. Rebuild Large Folder Sync States (OPTIONAL)
- Only necessary if you plan to sync Sent/All Mail folders
- Can be done incrementally to avoid hitting rate limits
- INBOX sync sufficient for basic email workflow

## =Ë Testing Checklist

### Environment Setup
- [ ] Restart shell to ensure environment variables are loaded
- [ ] Verify `echo $GMAIL_CLIENT_ID` returns your client ID
- [ ] Verify `echo $SASL_PATH` points to XOAUTH2 plugin

### OAuth Authentication
- [ ] Fix systemd service environment variables
- [ ] Test OAuth refresh: `systemctl --user start gmail-oauth2-refresh.service`
- [ ] Verify refresh succeeds: `systemctl --user status gmail-oauth2-refresh.service`

### Email Synchronization
- [ ] Test INBOX sync: `mbsync gmail-inbox`
- [ ] Should complete quickly (only new emails)
- [ ] No "OVERQUOTA" or "AUTHENTICATIONFAILED" errors
- [ ] New emails appear in `~/Mail/Gmail/INBOX/`

### Himalaya Integration
- [ ] Open Neovim with Himalaya
- [ ] Test sync: `<leader>ms`
- [ ] Should see "Mail sync started..." immediately
- [ ] Progress notifications should appear
- [ ] Should complete with "Mail sync completed successfully!"
- [ ] New emails should be visible in Himalaya

### Bidirectional Sync Verification
- [ ] Delete email in Himalaya (gD key)
- [ ] Should see deletion sync notification
- [ ] Verify email deleted in Gmail web interface
- [ ] Send test email to yourself
- [ ] Run `<leader>ms` in Himalaya
- [ ] New email should appear in Himalaya

## =Ê Current Configuration Status

### Working Components
-  mbsync binary with XOAUTH2 support
-  Gmail IMAP authentication
-  INBOX sync state (7,677 emails mapped)
-  Himalaya enhanced sync UI
-  NixOS-managed configuration

### Needs Attention
-   OAuth token automatic refresh
-   Large folder sync states
-   Complete workflow testing

## <¯ Success Criteria

The email integration will be considered fully functional when:

1. **Automatic OAuth refresh works** without manual intervention
2. **`<leader>ms` completes successfully** and shows new emails
3. **Bidirectional sync works**: deletions in Himalaya sync to Gmail
4. **New Gmail emails appear** in Himalaya after sync
5. **No rate limiting issues** due to proper sync state management

## =Á Key Files Modified

### Configuration Files
- `/home/benjamin/.mbsyncrc` - Generated by NixOS home-manager
- `/home/benjamin/.config/himalaya/config.toml` - Himalaya configuration
- `/home/benjamin/.config/fish/conf.d/private.fish` - Environment variables

### Neovim Integration
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/native_sync.lua` - Enhanced sync
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/commands.lua` - Commands
- Keymap: `<leader>ms` ’ `HimalayaEnhancedSync`

### System Services
- `~/.config/systemd/user/gmail-oauth2-refresh.service` - OAuth refresh
- `~/.config/systemd/user/gmail-oauth2-refresh.timer` - Automatic refresh schedule

### Sync State Files
- `/home/benjamin/Mail/Gmail/INBOX/.mbsyncstate` -  Rebuilt (7,677 emails)
- `/home/benjamin/Mail/Gmail/Letters/.mbsyncstate` -  Exists (1,530 emails)
- `/home/benjamin/Mail/Gmail/Drafts/.mbsyncstate` -  Exists (271 emails)
- Other folders:   Need rebuilding for full sync

---

**Next Session Goal**: Fix OAuth refresh environment variables and complete end-to-end testing of the email workflow.