# Final Fix for mbsync/himalaya Sync Issue

## The Problem
The mbsync configuration has a trailing slash in the Inbox path which causes Maildir++ to create incorrect paths like `/home/benjamin/Mail/Gmail//.Sent`

## Required Change in home.nix

Find this line in your mbsync configuration:
```nix
Inbox ~/Mail/Gmail/
```

Change it to (remove the trailing slash):
```nix
Inbox ~/Mail/Gmail
```

## Why This Matters
- With the trailing slash, mbsync creates paths like: `~/Mail/Gmail//.Sent`
- Without it, mbsync correctly creates: `~/Mail/Gmail/.Sent`
- The double slash breaks UIDVALIDITY file reading

## Steps to Fix
1. Edit your home.nix and remove the trailing slash from the Inbox line
2. Run `home-manager switch`
3. The sync should now work correctly

## Test It
After making the change, run:
```bash
mbsync -V gmail-inbox
```

You should see messages being synced instead of UIDVALIDITY errors.