# Debugging Duplicate Headers Issue

## Summary
The email preview is showing duplicate headers. Despite multiple fixes, users still see headers repeated.

## Debugging Steps

1. **Use debug command to inspect raw himalaya output**:
   ```vim
   :HimalayaDebugOutput <email_id>
   ```
   This will show:
   - Raw output from himalaya
   - Header counts (Subject:, From:, etc.)
   - First 1000 characters
   - Full output with line numbers

2. **Check logs**:
   ```vim
   :HimalayaLogs
   ```
   Look for:
   - "Raw himalaya output structure"
   - "Subject header positions"
   - "Used ... method" to see which parsing method was used

3. **Enhanced logging added**:
   - Logs the total Subject: count in output
   - Logs all Subject: positions found
   - Logs which parsing method is used
   - Logs body preview after parsing

## Parsing Strategy

The current approach tries multiple methods in order:

1. **Multiple Subject Headers Method** (preferred):
   - If 2+ "Subject:" headers found
   - Uses position of LAST Subject header
   - Finds empty line after it
   - Everything after that is body

2. **Dashes + Double Newline Method**:
   - Finds separator dashes
   - Looks for double newline after dashes
   - Body starts after double newline

3. **First Double Newline Method**:
   - As last resort
   - Finds first double newline
   - Everything after is body

## Expected Himalaya Output Format

```
From: sender
To: recipient
Subject: subject line
Date: date
--------------------------------------

From: Full Sender <email@example.com>
To: recipient@example.com
Subject: subject line
Date: full date

Email body content here...
```

## Testing Process

1. Open sidebar and navigate to INBOX
2. Enable preview mode (press Enter)
3. Hover over an email
4. Run `:HimalayaDebugOutput <email_id>` with that email's ID
5. Check the output to see:
   - How many Subject headers are present
   - Where the body actually starts
   - If headers are included in the body

## Next Steps

Based on the debug output, we can:
1. Adjust the parsing logic
2. Add more specific patterns
3. Handle edge cases better