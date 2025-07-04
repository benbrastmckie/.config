# Standard Patterns for vim.ui.select and vim.ui.input

This document defines the standard patterns for using `vim.ui.select` and `vim.ui.input` with dressing.nvim enhancements throughout the Neovim configuration.

## Simple Yes/No Confirmation (Safe Action)

```lua
vim.ui.select({"Yes", "No"}, {
  prompt = "Continue?",
  kind = "confirmation",
}, function(choice)
  if choice == "Yes" then
    -- action
  end
end)
```

## Dangerous Confirmation (Defaults to No)

```lua
vim.ui.select({"No", "Yes"}, {
  prompt = "Delete all files?",
  kind = "confirmation",
  format_item = function(item)
    if item == "Yes" then
      return " " .. item  -- Check mark
    else
      return " " .. item  -- X mark
    end
  end,
}, function(choice)
  if choice == "Yes" then
    -- dangerous action
  end
end)
```

## Action Confirmations with Nerdfont Icons

```lua
-- Example: Delete confirmation with icon
local prompt = string.format(" Delete file \"%s\"?", filename)

vim.ui.select({"No", "Yes"}, {
  prompt = prompt,
  kind = "confirmation",
  format_item = function(item)
    if item == "Yes" then
      return " " .. item  -- Check mark
    else
      return " " .. item  -- X mark
    end
  end,
}, function(choice)
  if choice == "Yes" then
    -- delete file
  end
end)
```

## Multiple Choice Selection

```lua
vim.ui.select({"Option 1", "Option 2", "Cancel"}, {
  prompt = "Choose option:",
}, function(choice)
  if choice and choice ~= "Cancel" then
    -- handle choice
  end
end)
```

## Direct vim.ui.select for Complex Cases

```lua
vim.ui.select(folders, {
  prompt = "Select folder:",
  format_item = function(item)
    return " " .. item  -- Folder icon
  end
}, function(choice)
  if choice then
    -- handle selection
  end
end)
```

## Text Input with vim.ui.input

```lua
vim.ui.input({
  prompt = "Enter name: ",
  default = current_name,
}, function(input)
  if input and input ~= "" then
    -- handle input
  end
end)
```

## Backend Selection Logic

The dressing configuration automatically selects the appropriate backend:

- **Confirmations (2-3 items)**: Uses builtin floating window
- **Code Actions**: Uses telescope for searchability
- **Large Lists (>3 items)**: Uses telescope for fuzzy finding
- **Small Lists (≤3 items)**: Uses builtin for speed

## Nerdfont Icons Reference

Common icons used in confirmations:

-  Delete/Trash
-  Save/Floppy disk
-  Send/Paper plane
-  Discard/Cancel
-  Edit/Pencil
-  Copy/Duplicate
-  Move/Arrow
-  Rename/Edit
-  Restore/Undo
-  Quit/Exit door
-  Question/Unknown
-  Folder/Directory
-  File/Document
-  Warning/Alert
-  Info/Information
-  Success/Check
-  Error/X

## Examples in Context

### File Operations
```lua
-- Delete file
if misc.confirm_action('delete', 'file "config.lua"') then
  vim.fn.delete(filepath)
end

-- Save changes
if misc.confirm_action('save', 'modified buffer') then
  vim.cmd('write')
end
```

### Email Operations
```lua
-- Send email
if misc.confirm_action('send', 'email to team@company.com') then
  send_email(email_data)
end

-- Discard draft
if misc.confirm_action('discard', 'unsaved email draft') then
  close_draft_buffer()
end
```

### Session Management
```lua
-- Restore session
vim.ui.select(sessions, {
  prompt = "Select session to restore:",
  format_item = function(session)
    return " " .. session.name .. " (" .. session.date .. ")"
  end,
  kind = "session"  -- Uses telescope due to potentially many items
}, function(session)
  if session then
    restore_session(session)
  end
end)
```

## Migration Guide

When updating existing code:

1. Replace `vim.fn.confirm()` with `misc.confirm()`
2. Replace custom input prompts with `vim.ui.select`
3. Use `misc.confirm_action()` for common operations
4. Add `kind` parameter to help dressing choose the right backend
5. Use nerdfont icons instead of emoji or text prefixes