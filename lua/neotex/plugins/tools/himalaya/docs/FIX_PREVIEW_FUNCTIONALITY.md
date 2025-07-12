# Preview Functionality Fixes

## Issues Fixed

### 1. Autocmd Deletion Error
**Error**: `E5108: Error executing lua: Failed to delete autocmd`

**Cause**: Trying to delete an autocmd that may no longer exist.

**Fix**: Wrapped deletion in pcall to handle gracefully:
```lua
if preview_state.autocmd_id then
  pcall(vim.api.nvim_del_autocmd, preview_state.autocmd_id)
  preview_state.autocmd_id = nil
end
```

### 2. Preview Keymaps Not Working
**Issue**: ESC and q keys in preview window didn't work as expected.

**Fix**: Added proper keymaps when creating preview buffer:
- **ESC**: Returns cursor to sidebar (keeps preview mode on)
- **q**: Exits preview mode and returns to sidebar

### 3. Emails Showing "Loading email content..."
**Issue**: Email bodies weren't loading in preview for inbox emails.

**Cause**: The `load_full_content_async` function was just a placeholder.

**Fix**: Implemented full async loading using himalaya CLI:
```lua
function M.load_full_content_async(email_id, account, folder)
  -- Uses 'himalaya message read' command
  -- Parses output to extract body after headers
  -- Updates cache and re-renders preview when loaded
end
```

The function:
1. Runs `himalaya message read -a <account> -f <folder> --preview <id>`
2. Parses the plain text output to extract body content
3. Updates the email cache with the full body
4. Re-renders the preview if it's still showing the same email

## Behavior Summary

### Preview Navigation
- **In Sidebar**:
  - First `<CR>`: Enable preview mode
  - Second `<CR>`: Focus preview window
  - `<ESC>`: Disable preview mode
  - `q`: Close sidebar

- **In Preview**:
  - `<ESC>`: Return to sidebar (preview stays open)
  - `q`: Close preview and return to sidebar

### Content Loading
1. **Immediate**: Shows cached headers and "Loading..." for body
2. **Async**: Loads full content in background
3. **Update**: Preview updates automatically when content arrives

## Testing
1. Open sidebar with `<leader>mo`
2. Press `<CR>` to enable preview mode
3. Hover over emails - preview shows with headers
4. Email bodies load asynchronously and update
5. Press `<CR>` again to focus preview
6. Press `<ESC>` in preview to return to sidebar
7. Press `q` in preview to close it and return