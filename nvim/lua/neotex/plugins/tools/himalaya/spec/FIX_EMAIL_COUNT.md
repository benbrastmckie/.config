# Email Count Fix

## Issue
The email list was showing "Page 1 / 40 | 1000 emails" incorrectly because:
1. The `fetch_folder_count_async` function returns 1000 when it gets a full page of emails
2. This 1000 is just the page limit, not the actual total count
3. The sync manager was storing this incorrect count

## Fix Applied
1. Modified `sync/manager.lua` to NOT store the count when it's exactly 1000
2. This prevents the incorrect count from being cached

## To Clear Existing Bad Count
If you're still seeing "1000 emails", you can:
1. Restart nvim to clear the in-memory state
2. Or run this command to clear the cached count:
   ```vim
   :lua require('neotex.plugins.tools.himalaya.core.state').set_folder_count('gmail', 'INBOX', nil)
   ```

## How It Works Now
- If the folder has < 1000 emails: Shows exact count
- If the folder has >= 1000 emails: Shows "Page X / ?" with estimated count like "30+ emails"
- The count will only be exact after fetching all pages or using proper pagination