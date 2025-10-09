# Himalaya Drafts System

## Overview

The drafts system supports both local drafts and Gmail-synced drafts.

## How Drafts Work

### Gmail Drafts (via Himalaya)
- When you compose an email, it's saved locally as a draft
- Use `:w` to save the draft locally
- The draft can be synced to Gmail using himalaya's `template save` command
- Gmail drafts appear in the Drafts folder and sync bidirectionally

### Local-Only Drafts
- Stored in `~/.local/share/nvim/himalaya/drafts/`
- Saved as JSON files with full content and metadata
- Persist across Neovim sessions
- Can be converted to Gmail drafts later

## Commands

### Creating Drafts
- `<leader>mc` - Compose new email (creates local draft)
- `:w` in compose buffer - Save draft locally
- `<leader>s` in compose buffer - Send email

### Managing Drafts
- `gs` in Drafts folder - Refresh draft list (fetches from Gmail)
- `gD` on a draft - Delete draft (local or remote)
- `Enter` on a draft - Open draft for editing

### Cleanup Commands
- `:HimalayaCleanupDrafts` - Various cleanup options
  - Clean up all drafts
  - Clean up empty drafts
  - Clean up old drafts (> 7 days)
  - Nuclear cleanup (remove everything)

## Technical Details

### Storage Format
Local drafts are stored as JSON files containing:
- `content`: Full email content (headers + body)
- `account`: Associated email account
- `metadata`: Parsed headers (from, to, subject, etc.)
- `created_at`, `updated_at`: Timestamps

### Sync Behavior
- Drafts folder shows both local and Gmail drafts
- Local drafts have IDs like `draft_timestamp_id`
- Gmail drafts have numeric IDs from himalaya
- Bulk operations handle both types correctly

## Best Practices

1. **For temporary drafts**: Just use local storage (automatic with `:w`)
2. **For important drafts**: Let them sync to Gmail
3. **Clean up regularly**: Use cleanup commands to remove old test drafts
4. **Don't mix formats**: The system handles both, but pick one approach per draft

## Troubleshooting

### Drafts not showing
- Check if drafts exist: `ls ~/.local/share/nvim/himalaya/drafts/`
- Run `:HimalayaMigrateDrafts` if you have old EML files
- Use `gs` to refresh the draft list

### Sync errors
- Drafts don't require mbsync - they use himalaya directly
- Check himalaya configuration: `himalaya account list`
- Verify draft folder exists: `himalaya folder list`

### Cleanup issues
- Use `:HimalayaCleanupDrafts` > "NUCLEAR cleanup" as last resort
- This removes ALL draft files and resets the index