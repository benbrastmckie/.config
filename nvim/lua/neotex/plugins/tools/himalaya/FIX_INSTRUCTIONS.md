# Fix Instructions for Himalaya Email Sync

## The Real Problem
The mbsync configuration needs a trailing slash for Maildir++ format to work correctly. Without it, mbsync looks for UIDVALIDITY files in the wrong locations.

## Required Changes in home.nix

### 1. Fix mbsync Inbox path (CRITICAL)
Your current config is missing the trailing slash. Change from:
```nix
MaildirStore gmail-local
Inbox ~/Mail/Gmail
SubFolders Maildir++
```

To (ADD the trailing slash):
```nix
MaildirStore gmail-local
Inbox ~/Mail/Gmail/
SubFolders Maildir++
```

### 2. Keep himalaya folder aliases AS-IS (they were correct!)
The working configuration actually used IMAP names for folder aliases. Keep these as they were:
```nix
folder.alias.sent = "[Gmail].Sent Mail"
folder.alias.drafts = "[Gmail].Drafts"
folder.alias.trash = "[Gmail].Trash"
folder.alias.spam = "[Gmail].Spam"
folder.alias.all = "[Gmail].All Mail"

# And keep this too:
folder.sent.name = "[Gmail].Sent Mail"
```

These IMAP names work because himalaya translates them internally when using maildir backend.

## How mbsync and himalaya work together

1. **mbsync** syncs Gmail IMAP folders to local maildir:
   - `[Gmail]/Sent Mail` (IMAP) → `.Sent` (local maildir)
   - `[Gmail]/Drafts` (IMAP) → `.Drafts` (local maildir)
   - `INBOX` (IMAP) → root directory with cur/new/tmp

2. **himalaya** reads from local maildir folders:
   - When configured with `backend.type = "maildir"`, it reads LOCAL folder names
   - So it needs `"Sent"` not `"[Gmail].Sent Mail"`

## Correct Maildir++ Structure
```
~/Mail/Gmail/
├── cur/         # INBOX current messages
├── new/         # INBOX new messages  
├── tmp/         # INBOX temporary
├── .uidvalidity # INBOX uidvalidity (NOT .INBOX.uidvalidity)
├── .Sent/
│   ├── cur/
│   ├── new/
│   ├── tmp/
│   └── .uidvalidity
├── .Drafts/
├── .Trash/
└── ... (other folders with dots)
```

## Common Issues and Solutions

### UIDVALIDITY Errors
If you see errors like:
```
Maildir error: cannot read UIDVALIDITY in /home/benjamin/Mail/Gmail/.
```

This is caused by the MISSING trailing slash in the Inbox path. Without the slash, mbsync looks for UIDVALIDITY in the wrong locations like `/home/benjamin/Mail/Gmail/.Sent.` (note the dot at the end).

### Empty Sync Results
If sync completes but shows "no new messages" when you know you have emails, check:
1. The trailing slash is PRESENT in Inbox path (required for Maildir++)
2. The maildir structure is correctly initialized

## Steps to Fix

1. Update your home.nix - just add the trailing slash to the Inbox path:
   ```nix
   Inbox ~/Mail/Gmail/
   ```
2. Revert the himalaya folder aliases back to IMAP names if you changed them
3. Run `home-manager switch` to apply changes
4. Test the sync

The sync should then work correctly!

## Testing the Fix
After making changes, test with:
```bash
mbsync -V gmail-inbox
```

You should see messages being synced, not UIDVALIDITY errors.

## Summary
Two issues were found:
1. The trailing slash IS required in the mbsync Inbox path for Maildir++ format
2. UIDVALIDITY files must be empty or contain valid mbsync UIDVALIDITY data - not arbitrary timestamps

If you get "Maildir error: cannot read UIDVALIDITY" errors:
1. Make sure you have the trailing slash in Inbox path
2. Create empty UIDVALIDITY files: `touch ~/Mail/Gmail/.uidvalidity`
3. Let mbsync populate them with correct values