# Research Report: Task #89

**Task**: 89 - gmail_himalaya_folder_label_sync
**Started**: 2026-02-13T14:00:00Z
**Completed**: 2026-02-13T14:15:00Z
**Effort**: Low (research only)
**Dependencies**: None
**Sources/Inputs**: Himalaya CLI, mbsync configuration, Gmail IMAP documentation, local testing
**Artifacts**: This report
**Standards**: report-format.md

## Executive Summary

- Gmail labels map directly to IMAP folders; Himalaya can create/delete folders that sync as Gmail labels
- Current configuration uses Maildir backend with mbsync for sync; Himalaya folder operations work on local Maildir only
- Gmail-to-Himalaya sync requires mbsync; new Gmail labels created in browser will NOT auto-appear in Himalaya without mbsyncrc changes
- Bidirectional sync is partially supported but requires manual mbsyncrc configuration for new custom folders

## Context & Scope

This research investigates the bidirectional synchronization behavior between Gmail labels/folders and Himalaya email client, specifically:
1. Whether changes made in Gmail web interface sync to Himalaya
2. Whether Himalaya can create/delete folders that sync back to Gmail
3. Best practices for managing labels/folders across both interfaces

## Findings

### 1. Gmail Label-to-IMAP Folder Mapping

Gmail implements labels as IMAP folders with specific behaviors:
- Standard IMAP commands (`CREATE`, `RENAME`, `DELETE`) work on Gmail labels
- System labels are prefixed with `[Gmail]/` (e.g., `[Gmail]/Sent Mail`, `[Gmail]/Trash`)
- Custom labels appear as standard IMAP folders
- Messages with multiple labels appear in multiple IMAP folders (technical copies sharing same Message-ID)

Reference: [Gmail IMAP Extensions Documentation](https://developers.google.com/workspace/gmail/imap/imap-extensions)

### 2. Current Configuration Architecture

The current Himalaya setup uses a **two-tier architecture**:

```
Gmail Server (IMAP) <--> mbsync <--> Local Maildir <--> Himalaya CLI
```

From `/home/benjamin/.config/himalaya/config.toml`:
```toml
[accounts.gmail]
backend.type = "maildir"
backend.root-dir = "/home/benjamin/Mail/Gmail"
backend.maildirpp = true
```

**Key insight**: Himalaya reads from local Maildir, NOT directly from Gmail IMAP. This means:
- Himalaya folder operations modify local Maildir structure
- mbsync handles synchronization between local Maildir and Gmail IMAP
- The `Create Both` directive in mbsyncrc enables bidirectional folder creation

### 3. Gmail -> Himalaya Sync Behavior

**For system folders** (INBOX, Sent, Drafts, Trash, Spam, All Mail):
- Fully configured in mbsyncrc with explicit channel mappings
- Changes sync bidirectionally via mbsync

**For custom labels** (e.g., EuroTrip, CrazyTown, Letters):
- Current mbsyncrc uses explicit patterns:
  ```
  Channel gmail-folders
  Patterns "EuroTrip" "CrazyTown" "Letters"
  Create Both
  ```
- **New Gmail labels created in browser will NOT auto-sync** because they are not in the Patterns list

**For new labels to auto-sync**, the mbsyncrc would need:
```
Channel gmail-folders
Far :gmail-remote:
Near :gmail-local:
Patterns * ![Gmail]*
Create Both
Expunge Both
```
This syncs all folders except system `[Gmail]/*` folders (which have dedicated channels).

### 4. Himalaya -> Gmail Sync Behavior

**Tested folder creation**:
```bash
$ himalaya folder add TestFolder123 --account gmail
Folder TestFolder123 successfully created!
```

**Result**: Folder created in local Maildir at `~/Mail/Gmail/.TestFolder123/`

**Sync to Gmail**: Requires mbsync to run with appropriate patterns. Since the current pattern list is explicit, new local folders will NOT sync to Gmail without:
1. Adding the folder name to the Patterns list, OR
2. Changing to wildcard patterns

**Tested folder deletion**:
```bash
$ himalaya folder delete TestFolder123 --account gmail --yes
Folder TestFolder123 successfully deleted!
```

**Result**: Local folder contents deleted, directory structure partially remains. Gmail sync depends on mbsync `Remove Both` configuration (currently not set).

### 5. Himalaya Folder Commands

Available commands from `himalaya folder --help`:

| Command | Description | Gmail Sync Behavior |
|---------|-------------|---------------------|
| `folder add <name>` | Create folder | Creates locally; needs mbsync for Gmail |
| `folder list` | List all folders | Shows local Maildir folders |
| `folder expunge <name>` | Remove deleted messages | Local only |
| `folder purge <name>` | Delete all messages | Local only; needs mbsync |
| `folder delete <name>` | Delete folder entirely | Local only; needs mbsync + Remove Both |

### 6. mbsync Configuration Options for Folders

From [mbsync documentation](https://isync.sourceforge.io/mbsync.html):

| Option | Values | Description |
|--------|--------|-------------|
| `Create` | None/Far/Near/Both | Auto-create missing mailboxes |
| `Remove` | None/Far/Near/Both | Propagate mailbox deletions |
| `Expunge` | None/Far/Near/Both | Permanently remove deleted messages |
| `Patterns` | IMAP wildcards | Match multiple mailboxes (`*` matches all) |

Current configuration uses `Create Both` and `Expunge Both` but NOT `Remove Both`, meaning:
- New folders can be created bidirectionally (if in Patterns)
- Deleted messages are expunged bidirectionally
- Deleted folders are NOT propagated

## Recommendations

### Option A: Enable Full Bidirectional Sync (Recommended)

Modify `~/.mbsyncrc` gmail-folders channel:

```diff
Channel gmail-folders
Far :gmail-remote:
Near :gmail-local:
-Patterns "EuroTrip" "CrazyTown" "Letters"
+Patterns * ![Gmail]* !INBOX
Create Both
Expunge Both
+Remove Both
SyncState *
```

This enables:
- Auto-discovery of new Gmail labels created in browser
- Auto-sync of new Himalaya folders to Gmail
- Propagation of folder deletions

### Option B: Keep Explicit Folder List (Current)

Maintain current explicit patterns for predictable behavior. When creating a new label:

1. Create in Gmail web interface
2. Add to mbsyncrc Patterns list
3. Run `mbsync gmail-folders`
4. Folder appears in Himalaya

Or when creating in Himalaya:
1. Run `himalaya folder add <name>`
2. Add to mbsyncrc Patterns list
3. Run `mbsync gmail-folders`
4. Label appears in Gmail

### Workflow for Himalaya Users

**To create a new folder/label that syncs to Gmail**:
```bash
# 1. Create locally
himalaya folder add "NewLabel" --account gmail

# 2. Edit mbsyncrc to add to Patterns (if using explicit list)

# 3. Sync to Gmail
mbsync gmail-folders
```

**To see Gmail labels in Himalaya**:
```bash
# 1. Ensure label is in mbsyncrc Patterns

# 2. Sync from Gmail
mbsync gmail

# 3. List folders
himalaya folder list --account gmail
```

## Decisions

1. **Document limitations**: Users should understand that Himalaya with Maildir backend operates on local files; Gmail sync is via mbsync
2. **Consider wildcard patterns**: For users who frequently create/delete labels, wildcard patterns provide better UX
3. **Add Remove Both**: If folder deletion propagation is desired, add `Remove Both` to mbsyncrc channels

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Wildcard patterns sync unwanted folders | Low | Use exclusion patterns `![Gmail]*` |
| Accidental folder deletion propagates | Medium | Backup before adding `Remove Both` |
| Gmail rate limits (2500 MB/day download) | Low | Use incremental sync, avoid full resync |
| Multiple labels cause duplicate downloads | Medium | Accept as Gmail IMAP limitation |

## Appendix

### Search Queries Used
- "Himalaya email client folder management create delete rename IMAP 2025"
- "Gmail IMAP labels folders mapping sync behavior changes 2025"
- "mbsync isync create delete folders Gmail sync bidirectional"
- "mbsync sync new folders created server Gmail automatic discovery"

### References
- [GitHub - pimalaya/himalaya](https://github.com/pimalaya/himalaya)
- [Gmail IMAP Extensions](https://developers.google.com/workspace/gmail/imap/imap-extensions)
- [isync/mbsync ArchWiki](https://wiki.archlinux.org/title/Isync)
- [mbsync manual](https://isync.sourceforge.io/mbsync.html)
- [Gmail Labels vs Folders Guide](https://www.getinboxzero.com/blog/post/gmail-labels-vs-folders)

### Local Files Examined
- `/home/benjamin/.config/himalaya/config.toml`
- `/home/benjamin/.mbsyncrc`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/config/folders.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/sync/mbsync.lua`
