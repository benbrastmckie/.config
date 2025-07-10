# Preview and Draft Display Fixes

## Issues Fixed

### 1. queue_preview Function Not Found
**Error**: `attempt to call field 'queue_preview' (a nil value)`

**Cause**: The `queue_preview` function was removed during refactoring but was still being called from `email_list.lua`.

**Fix**: Updated the call to use `show_preview` instead:
```lua
-- Old
email_preview.queue_preview(email_id, sidebar_win, 'keyboard', email_type)
-- New
email_preview.show_preview(email_id, sidebar_win, email_type)
```

### 2. Draft Preview Showing Headers in Body
**Issue**: Draft previews were showing the full email headers (From, To, Subject, etc.) as part of the body content.

**Cause**: Draft content stored in files includes the full email format with headers, but the preview was displaying this raw content.

**Fix**: Added `extract_body_from_content` function to parse out just the body:
```lua
-- Extract body from draft content that includes headers
local function extract_body_from_content(content)
  -- Find the empty line that separates headers from body
  -- Return only the content after that line
end
```

### 3. Preview Formatting Lost Original Style
**Issue**: The preview lost the original formatting style from the old version.

**Fix**: Restored the old preview style with:
- Safe string conversion with `vim.NIL` handling
- Consistent status formatting for scheduled/draft emails
- Better empty draft handling with helpful tips
- Protected rendering with error handling
- Consistent separator lines using the configured width

## Design Improvements

### Enhanced Empty Draft Display
Empty drafts now show helpful guidance:
```
[Empty draft - add content to see preview]

Tip: Start by filling in:
  • To: recipient email
  • Subject: email subject
  • Body: your message
```

### Consistent Status Display
Both scheduled emails and drafts now use the same status format:
```
Status:  Scheduled
Status:  📝 New (not synced)
```

### Error Protection
Added pcall wrapper to prevent preview rendering errors from breaking the UI.

## Testing
1. Create a new draft with `<leader>mw`
2. Preview should show properly formatted headers without duplication
3. Empty drafts should show helpful tips
4. CursorHold should trigger preview without errors