# Fix Duplicate Headers in Email Preview

## Issue
Email previews were showing headers twice:
1. First set from our preview rendering
2. Second set from the email body itself

## Root Cause
The `himalaya message read` command returns output in this format:
```
From: sender
To: recipient (or vim.NIL)
Subject: subject line
Date: date
--------------------------------------

From: Full Sender <email@example.com>
To: recipient@example.com
Cc: cc@example.com
Subject: subject line

Email body content here...
```

We were only removing the first divider line but not the second set of headers.

## Solution
Enhanced the parsing to:
1. Find the divider line (dashes)
2. Extract content after the divider
3. Find the empty line after the second set of headers
4. Extract only the body content

```lua
-- Find divider
local divider_pos = output:find("\n%-+\n")
if divider_pos then
  -- Get content after divider
  local full_content = output:sub(content_start + 1)
  
  -- Find body start (after headers)
  local body_start = full_content:find("\n\n")
  if body_start then
    body = full_content:sub(body_start + 2)
  end
end
```

## Additional Fixes
1. **Hide vim.NIL**: Don't show "To: vim.NIL" in headers
2. **Debug logging**: Added logging to help troubleshoot parsing

## Result
Email previews now show:
- Clean headers at the top (from cached email data)
- Separator line
- Just the email body content (no duplicate headers)
- Footer with keyboard shortcuts