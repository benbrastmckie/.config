# UIDVALIDITY Fix for mbsync

## The Problem
When creating fresh maildir structures, we were creating `.uidvalidity` files with timestamp content like "1751141277". However, mbsync expects these files to either be:
1. Empty (so it can create its own format)
2. In mbsync's specific format (two lines with numeric UIDs)

When mbsync encounters invalid UIDVALIDITY content, it fails with:
```
Maildir error: cannot read UIDVALIDITY in /home/benjamin/Mail/Gmail/.
```

## The Solution
Create empty UIDVALIDITY files and let mbsync populate them:

```bash
# Fix all UIDVALIDITY files in Gmail maildir
find ~/Mail/Gmail -name ".uidvalidity" -exec sh -c 'echo -n > "{}"' \;
```

After this, mbsync will create proper UIDVALIDITY files that look like:
```
1751141470
1965
```

## Automated Fix
The maildir setup now automatically:
1. Creates empty UIDVALIDITY files instead of timestamp-filled ones
2. Runs `fix_uidvalidity_files()` after creating fresh maildir
3. Detects invalid UIDVALIDITY format in diagnostics

## Manual Recovery
If you encounter UIDVALIDITY errors after creating a fresh maildir:
1. Run `:HimalayaCleanup` to stop all syncs
2. Empty all UIDVALIDITY files: `find ~/Mail/Gmail -name ".uidvalidity" -exec sh -c 'echo -n > "{}"' \;`
3. Run `:HimalayaSyncInbox` - mbsync will populate the files correctly