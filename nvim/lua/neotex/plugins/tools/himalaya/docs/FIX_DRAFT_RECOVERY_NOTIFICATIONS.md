# Draft Recovery Notifications Fix

## Issue
When opening Neovim, multiple "Draft needs recovery: 0" messages were appearing. These messages were confusing because:
1. The "0" was actually the draft ID, not meaningful content
2. Empty drafts were triggering recovery notifications
3. The messages didn't provide useful information about what needed recovery

## Root Cause Analysis
1. **Empty Drafts**: Draft files were created but abandoned without any content
2. **Poor Notification Format**: When a draft had no subject, the notification fell back to showing the draft_id (which was "0")
3. **No Cleanup**: Empty orphaned drafts were never cleaned up

## Solution
Made two key improvements:

### 1. Better Notification Messages
Changed the notification to show more meaningful information:
```lua
-- Old: Shows draft_id when no subject (confusing "0")
data.metadata and data.metadata.subject or data.draft_id

-- New: Shows descriptive text based on available information
local identifier = "(empty draft)"
if data.metadata and data.metadata.subject and data.metadata.subject ~= "" then
  identifier = data.metadata.subject
elseif data.metadata and data.metadata.to and data.metadata.to ~= "" then
  identifier = "to: " .. data.metadata.to
elseif data.draft_id then
  identifier = "ID: " .. tostring(data.draft_id)
end
```

### 2. Automatic Cleanup of Empty Drafts
Added logic to automatically clean up orphaned drafts that have no meaningful content:
```lua
-- Check if draft has any meaningful content
local has_content = false
if stored.metadata then
  has_content = (stored.metadata.subject and stored.metadata.subject ~= "") or
               (stored.metadata.to and stored.metadata.to ~= "") or
               (stored.content and stored.content:match("[^\n%s]"))
end

if has_content then
  -- Emit recovery event for drafts with content
else
  -- Clean up empty orphaned draft
  storage.delete(stored.local_id)
end
```

## Design Principles Applied
1. **User-Friendly Messages**: Notifications should provide meaningful context
2. **Automatic Cleanup**: Don't keep empty drafts that provide no value
3. **Progressive Disclosure**: Show the most relevant information available (subject > recipient > ID)

## Prevention
To prevent similar issues:
1. Consider adding a minimum content threshold before creating draft files
2. Implement periodic cleanup of old empty drafts
3. Add more context to recovery notifications (e.g., last modified date)
4. Consider not creating draft files until the user adds content

## Manual Cleanup
If you want to manually clean up existing empty drafts:
```bash
rm ~/.local/share/nvim/himalaya/drafts/0.json
```