# Himalaya Folder Mapping Analysis

## Key Findings

### 1. Folder Structure Differences

The maildir backend uses different folder names than what's configured in himalaya:

**In `~/.config/himalaya/config.toml`:**
```toml
folder.alias.sent = "[Gmail].Sent Mail"
folder.alias.drafts = "[Gmail].Drafts"
folder.alias.trash = "[Gmail].Trash"
folder.alias.spam = "[Gmail].Spam"
folder.alias.all = "[Gmail].All Mail"
```

**In mbsync configuration (`~/.mbsyncrc`):**
```
Channel gmail-sent
Far :gmail-remote:"[Gmail]/Sent Mail"
Near :gmail-local:Sent

Channel gmail-trash
Far :gmail-remote:"[Gmail]/Trash"
Near :gmail-local:Trash
```

**Actual maildir folders (`~/Mail/Gmail/`):**
- `.Sent` (Maildir++ format with dot prefix)
- `.Trash`
- `.Drafts`
- `.Spam`
- `.All_Mail`

### 2. The Mismatch

1. **Himalaya config** uses Gmail IMAP folder names: `[Gmail].Sent Mail`
2. **mbsync** maps these to local names: `[Gmail]/Sent Mail` → `Sent`
3. **Maildir** stores them with dots: `.Sent`
4. **Himalaya CLI** sees them without dots: `Sent`

### 3. Why Old Version Worked

The old version (commit 33db5a7503e0) didn't have any special folder mapping logic. It worked because:

1. It was passing folder names directly to himalaya CLI
2. The utils.lua had the same basic structure for `execute_himalaya()`
3. No folder name translation was happening

### 4. The Current Problem

The himalaya configuration is using IMAP folder names (`[Gmail].Sent Mail`) when it should be using the local maildir folder names (`Sent`) since the backend is set to maildir.

## Solution

Update `~/.config/himalaya/config.toml` to use the actual maildir folder names:

```toml
# Change from:
folder.alias.sent = "[Gmail].Sent Mail"
folder.alias.drafts = "[Gmail].Drafts"
folder.alias.trash = "[Gmail].Trash"
folder.alias.spam = "[Gmail].Spam"
folder.alias.all = "[Gmail].All Mail"

# To:
folder.alias.sent = "Sent"
folder.alias.drafts = "Drafts"
folder.alias.trash = "Trash"
folder.alias.spam = "Spam"
folder.alias.all = "All_Mail"  # Note the underscore

# And update:
folder.sent.name = "Sent"  # Instead of "[Gmail].Sent Mail"
```

## Why This Happens

When using maildir backend, himalaya reads from the local filesystem, not from IMAP. The folder names in the configuration should match what's actually on disk, not the IMAP folder names. The mbsync configuration handles the translation between IMAP names and local names, but himalaya doesn't know about that translation when using maildir backend.

## Alternative Solutions

1. **Use IMAP backend in himalaya** - This would make the `[Gmail].Sent Mail` names correct, but would be slower
2. **Create symlinks** - Link the expected names to actual folders
3. **Modify the Neovim plugin** - Add folder name translation logic (not recommended)

The cleanest solution is to fix the himalaya configuration to match the actual maildir folder names.