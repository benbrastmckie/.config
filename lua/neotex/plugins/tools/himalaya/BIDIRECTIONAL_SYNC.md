# Himalaya Bidirectional Sync Implementation

## Overview

The Himalaya email client is configured to use a **maildir backend**, which means it operates on local mail files stored at `/home/benjamin/Mail/Gmail`. True bidirectional synchronization between Gmail and Himalaya requires `mbsync` to sync changes between the IMAP server and local maildir.

## Architecture

```
Gmail IMAP Server <--[mbsync]--> Local Maildir <--[Himalaya]--> Neovim UI
```

1. **Gmail IMAP Server**: The remote email server
2. **mbsync**: Handles bidirectional sync between IMAP and local files
3. **Local Maildir**: Mail files stored at `~/Mail/Gmail`
4. **Himalaya**: Reads/writes local maildir files only
5. **Neovim UI**: Displays and manages emails through Himalaya

## Key Commands

### Sync Operations

- **`<leader>ms`** (`:HimalayaEnhancedSync`): Run full bidirectional sync with Gmail
- **`:HimalayaForceSync`**: Force sync with `mbsync --force` flag
- **`:HimalayaCancelSync`**: Cancel ongoing sync operation
- **`:HimalayaQuickSync`**: Sync current folder only
- **`:HimalayaAlternativeSync`**: Fallback sync when mbsync fails

### Delete Operations

When you delete an email in Himalaya:
1. Email is moved to local trash or marked as deleted
2. `sync_after_delete()` automatically runs to push changes to Gmail
3. The deletion syncs to Gmail via mbsync

## How Enhanced Sync Works

The enhanced sync (`native_sync.lua`) now performs these steps:

1. **Check mbsync availability**: Falls back to local refresh if not available
2. **Run mbsync**: Executes `mbsync -a` to sync all accounts
3. **Handle OAuth failures**: Automatically tries OAuth refresh if auth fails
4. **Clear cache**: Clears Himalaya's email cache after sync
5. **Refresh UI**: Updates the email list display

## Sync After Delete

When you delete an email (gD in sidebar):
1. Himalaya moves email to trash folder locally
2. `sync_after_delete()` runs `mbsync -H` (push changes to server)
3. Gmail reflects the deletion

## Background Sync

- Runs silently with `mbsync -a -q`
- Clears cache and refreshes view on success
- No notifications for background operations

## Troubleshooting

### Sync Not Working?

1. **Check mbsync configuration**:
   ```bash
   mbsync --version
   cat ~/.mbsyncrc
   ```

2. **Verify OAuth tokens**:
   ```vim
   :HimalayaOAuthStatus
   :HimalayaRefreshOAuth
   ```

3. **Force sync**:
   ```vim
   :HimalayaForceSync
   ```

### Delete Not Syncing?

1. **Check trash folder configuration**:
   ```toml
   # In ~/.config/himalaya/config.toml
   folder.alias.trash = "[Gmail].Trash"
   ```

2. **Manually sync after delete**:
   ```vim
   :HimalayaEnhancedSync
   ```

### OAuth Issues?

1. **Refresh tokens**:
   ```vim
   :HimalayaRefreshOAuth
   ```

2. **Check systemd timer**:
   ```bash
   systemctl --user status gmail-oauth2-refresh.timer
   ```

3. **Reconfigure account**:
   ```vim
   :HimalayaReconfigureGmail
   ```

## Configuration Requirements

### mbsync Configuration
Your `~/.mbsyncrc` should have:
- `AuthMechs XOAUTH2` for OAuth authentication
- Proper channel configuration for bidirectional sync
- No conflicts between `Path` and `SubFolders Maildir++`

### Himalaya Configuration
Your `~/.config/himalaya/config.toml` should have:
- `backend.type = "maildir"`
- Proper folder aliases for Gmail
- OAuth2 configuration for SMTP

## Important Notes

1. **Himalaya uses maildir backend**: It cannot sync directly with IMAP
2. **mbsync is required**: For any server synchronization
3. **Delete operations**: Need explicit sync to propagate to Gmail
4. **Cache clearing**: Essential after sync to see updated emails
5. **OAuth tokens**: Must be refreshed periodically for sync to work