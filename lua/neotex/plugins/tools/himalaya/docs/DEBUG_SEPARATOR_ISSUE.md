# Debug Separator Issue

## Problem
The separator bar is not consistently appearing after headers. Sometimes it shows, sometimes it doesn't.

## Investigation Steps

1. Run `:HimalayaDebugOutput <email_id>` on the problematic email
2. Check `:HimalayaLogs` to see:
   - "Processing email with full headers"
   - "Found header end at..." messages
   - Which parsing path was taken

## Possible Issues

1. **No empty line between headers and body**: Some emails might not have a clear empty line separating headers from body content.

2. **Header detection failing**: The pattern matching for headers might not catch all cases.

3. **Different email formats**: Emails from different sources might have different formatting.

## Current Logic

The code tries to find the end of headers by:
1. Looking for an empty line (most common)
2. Looking for a line that doesn't match header pattern
3. Fallback: check first 10 lines for empty line
4. Last resort: look for Subject:/Date: and add separator after

## Solution Approaches

1. **Force separator after specific headers**: Always add separator after Date: or Subject: header
2. **Simplify logic**: Just count lines that look like headers and add separator after them
3. **Use the parsing info**: The himalaya output parser already identifies where headers end