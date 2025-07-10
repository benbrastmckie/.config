# Email Composer Tab Navigation Fix

## Issue
When pressing Tab in insert mode on the Subject line of a new draft, an error occurred:
```
Error executing vim.schedule lua callback: ...email_composer.lua:143: Cursor position outside buffer
```

## Root Cause
The Tab navigation code was trying to set the cursor position to a line that didn't exist in the buffer. When on the Subject line (typically the last header), pressing Tab would find the empty line separator but then try to jump to `i + 1`, which could be beyond the buffer's line count.

## Solution
Added proper bounds checking and buffer management:

1. **Ensure body line exists**: If the empty separator line is the last line in the buffer, add a new line for the body content
2. **Safe cursor positioning**: Use `math.min()` to ensure we never try to set cursor beyond buffer bounds
3. **Proper mode handling**: Exit and re-enter insert mode to ensure cursor is positioned correctly

### Enhanced Tab Navigation
```lua
-- Tab in insert mode:
-- - From any header field: Jump to next unfilled header or body
-- - If at end of headers: Create body line if needed and jump there
-- - If in body: Insert a regular tab character

-- Added bounds checking:
local body_line = math.min(i + 1, #lines)
vim.api.nvim_win_set_cursor(0, { body_line, 0 })
```

### Added Shift-Tab Navigation
Now supports backward navigation:
- From body: Jump back to Subject line
- From any header: Jump to previous header field
- Useful for quickly reviewing/editing email fields

## Usage
- **Tab**: Move to next field or body
- **Shift-Tab**: Move to previous field
- Both work in insert mode for seamless editing

## Testing
1. Create new draft with `<leader>mw`
2. Fill in To: field, press Tab → moves to Cc:
3. Press Tab on Subject: → moves to body (creates line if needed)
4. Press Shift-Tab in body → returns to Subject:
5. No more cursor position errors!