# Fix Duplicate Headers in Email Preview (Version 2)

## Issue
Email previews were still showing duplicate headers even after the first fix.

## Root Cause Analysis
The himalaya `message read` command outputs:
1. Summary headers (From, To, Subject, Date)
2. Separator line (dashes)
3. Full email with all headers repeated
4. Empty line
5. Email body

The previous fix wasn't correctly identifying where the actual body starts.

## Solution
New approach that's more robust:
1. Find all occurrences of "Subject:" in the output
2. If there are 2+ Subject headers, use the position of the last one
3. Find the empty line after the last Subject header
4. Everything after that empty line is the body

```lua
-- Find all Subject: headers
local subject_positions = {}
-- ... find all positions ...

if #subject_positions >= 2 then
  -- Use the last Subject header position
  local last_subject_pos = subject_positions[#subject_positions]
  -- Find empty line after it
  local body_start = output:find("\n\n", last_subject_pos)
  if body_start then
    body = output:sub(body_start + 2)
  end
end
```

## Why This Works
- The Subject header is reliably present in both header sections
- It's typically the last header before the body
- By finding the LAST Subject header, we skip all the duplicate headers
- The empty line after headers is a standard email format marker

## Fallback Strategy
If the Subject-based approach fails:
1. Look for double newline after dashes
2. As last resort, use first double newline found

## Result
Email previews now correctly show:
- Single set of headers (from cached data)
- Separator line
- Just the email body content
- Footer with shortcuts