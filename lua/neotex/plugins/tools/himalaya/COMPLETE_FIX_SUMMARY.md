# Complete Fix Summary for Himalaya Email Sync

## Root Causes Identified

### 1. mbsync Configuration (home.nix)
**Issue**: Missing trailing slash in Inbox path
```nix
# Current (WRONG):
Inbox ~/Mail/Gmail

# Should be:
Inbox ~/Mail/Gmail/
```
The trailing slash is REQUIRED for Maildir++ format. Without it, mbsync looks for UIDVALIDITY files in wrong locations.

### 2. Himalaya Folder Configuration (home.nix)
**Status**: Actually CORRECT as-is
```nix
folder.alias.sent = "[Gmail].Sent Mail"
folder.alias.drafts = "[Gmail].Drafts"
# etc...
```
These IMAP names are correct. Himalaya translates them internally when using maildir backend.

### 3. Archive/Spam Functions in Neovim Plugin
**Issue**: Looking for IMAP folder names in local folder list
The old code searches for `[Gmail]/All Mail` in the list of folders, but himalaya returns `All_Mail` when using maildir backend.

## How It All Works Together

1. **mbsync** syncs between Gmail IMAP and local maildir:
   - IMAP: `[Gmail]/Sent Mail` → Local: `~/Mail/Gmail/.Sent`
   - IMAP: `[Gmail]/All Mail` → Local: `~/Mail/Gmail/.All_Mail`

2. **himalaya** with maildir backend sees local folders:
   - Returns: `Sent`, `All_Mail`, `Trash`, etc.
   - NOT: `[Gmail]/Sent Mail`, `[Gmail]/All Mail`

3. **himalaya folder aliases** map special folders:
   - When you say `folder.alias.sent = "[Gmail].Sent Mail"`
   - Himalaya knows to use the local `Sent` folder

## Required Fixes

### 1. In home.nix - Add trailing slash:
```nix
MaildirStore gmail-local
Inbox ~/Mail/Gmail/
SubFolders Maildir++
```

### 2. In Neovim plugin (ui.lua) - Fix archive function:
```lua
-- In archive_current_email() function, change:
local archive_folders = {'Archive', 'All Mail', '[Gmail]/All Mail', '[Gmail].All Mail', 'ARCHIVE', 'Archived'}

-- To:
local archive_folders = {'All_Mail', 'Archive', 'All Mail', 'ARCHIVE', 'Archived'}
```

### 3. In Neovim plugin (ui.lua) - Fix spam function:
```lua
-- In spam_current_email() function, change:
local spam_folders = {'Spam', 'Junk', '[Gmail].Spam', '[Gmail]/Spam', 'SPAM', 'JUNK'}

-- To:
local spam_folders = {'Spam', 'Junk', 'SPAM', 'JUNK'}
```

## Why The Old Version "Worked"

The old version would fail to find archive/spam folders and likely fell back to some default behavior. The sync issues were masking the folder name mismatch problem.

## Testing After Fixes

1. Update home.nix and run `home-manager switch`
2. Test sync: `mbsync -V gmail-inbox`
3. In Neovim: `:HimalayaDiagnose` to check structure
4. Try archiving an email with `gA` - it should move to All_Mail folder