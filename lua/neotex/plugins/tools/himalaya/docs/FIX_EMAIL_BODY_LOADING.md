# Email Body Loading Fix

## Issue
Emails in INBOX showing "Loading email content..." with error:
```
attempt to call field 'set_email_body' (a nil value)
```

## Root Cause
The function name was incorrect - `email_cache` module has `store_email_body`, not `set_email_body`.

## Fixes Applied

### 1. Corrected Function Name
```lua
-- Wrong
email_cache.set_email_body(account, folder, email_id, body)

-- Correct
email_cache.store_email_body(account, folder, email_id, body)
```

### 2. Added Debug Logging
Added logging to help troubleshoot himalaya output parsing:
```lua
logger.debug('Himalaya output received', { 
  email_id = email_id,
  output_length = #output,
  first_lines = vim.split(output, '\n')[1]
})
```

### 3. Improved Error Handling
Added fallback for emails not in cache:
```lua
if email then
  -- Update existing email
  email.body = body
  M.render_preview(email, preview_state.buf)
else
  -- Create minimal structure if not cached
  local minimal_email = {
    id = email_id,
    body = body,
    subject = '(Email loaded directly)',
    -- ... other fields
  }
  M.render_preview(minimal_email, preview_state.buf)
end
```

### 4. Consistent ID Handling
Ensure email_id is always a string:
```lua
email_id = tostring(email_id)
```

## How It Works

1. **Initial Display**: Shows cached headers with "Loading..." body
2. **Async Load**: Runs `himalaya message read` in background
3. **Parse Output**: Extracts body after headers/divider
4. **Update Cache**: Stores body with `store_email_body`
5. **Re-render**: Updates preview with full content

## Testing
1. Open sidebar and enable preview mode
2. Hover over INBOX emails
3. Preview should show headers immediately
4. Body should load and appear within 1-2 seconds
5. Check logs with `:HimalayaLogs` if issues persist