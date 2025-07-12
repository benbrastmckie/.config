# Restored Old Preview Style and Behavior

## Changes Made to Match f1952264b8c0

### 1. Window Positioning (Key Change)
**Old**: Used `relative = 'editor'` with exact position calculation
**New**: Changed back from `relative = 'win'` to `relative = 'editor'`

This makes the preview window:
- Position relative to the entire editor, not the parent window
- Appear exactly to the right of the sidebar with 1 column gap
- Match the sidebar's height minus 2 for borders
- Have a fixed 80 character width

### 2. Window Configuration
```lua
return {
  relative = 'editor',
  width = 80,  -- Fixed 80 character width
  height = win_height - 2,  -- Match sidebar height
  row = win_pos[1],     -- Align with sidebar top
  col = win_pos[2] + sidebar_width + 1,  -- Right of sidebar
  style = 'minimal',
  border = M.config.border,
  title = ' Email Preview ',  -- Added title
  title_pos = 'center',
  focusable = true,  -- Make clickable
  zindex = 50,
  noautocmd = false,
}
```

### 3. Visual Appearance
- **Title Bar**: Added " Email Preview " centered title
- **Footer**: Added keymap hints at bottom
  - Drafts: "esc:sidebar return:edit gD:delete"
  - Regular: "esc:sidebar gr:reply gR:reply-all gf:forward"
  - All: "q:exit" and action keys
- **Separator**: Uses "─" characters for footer separator

### 4. Syntax Highlighting
Restored mail-specific syntax highlighting:
- Headers (From, To, Subject) highlighted as Keywords
- Email addresses underlined
- Quoted text (lines starting with >) shown as comments

### 5. Buffer Settings
Changed to match old version:
- `bufhidden = 'hide'` instead of 'wipe' (keeps buffer in memory)
- `undolevels = -1` (disable undo for performance)
- `filetype = 'mail'` (always set for syntax)
- `modifiable = false` by default

### 6. Configuration Defaults
Restored original values:
- Width: 80 (was changed to 100)
- Max height: 30 (was changed to 40)
- Added mouse_delay: 1000ms
- Added focusable: false default
- Added auto_close: true

## Result
The preview now appears exactly as it did in the old version:
- Fixed position to the right of sidebar
- Consistent 80 character width
- Professional appearance with title and footer
- Clear keymap hints for user actions
- Proper syntax highlighting for email content

## Testing
1. Open sidebar with `<leader>mo`
2. Enable preview mode with `<CR>`
3. Preview appears to the right with:
   - Fixed 80 char width
   - Title bar showing " Email Preview "
   - Footer with keyboard shortcuts
   - Proper email syntax highlighting