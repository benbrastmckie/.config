# Implementation Summary: Task #67

**Completed**: 2026-02-11
**Duration**: ~15 minutes

## Changes Made

Refactored Himalaya compose buffer keybindings to use a 2-letter maximum scheme, eliminating the 3-letter `<leader>mc*` subgroup and resolving the `<leader>ms` conflict between "sync inbox" (global) and "send email" (compose).

### New Compose Buffer Mappings

| Key | Action | Notes |
|-----|--------|-------|
| `<leader>me` | Send email | E for Email/Envelope |
| `<leader>md` | Save draft | D for Draft |
| `<leader>mq` | Quit/discard | Q for Quit |
| `<C-d>` | Save draft | Buffer-local shortcut |
| `<C-q>` | Discard | Buffer-local shortcut |
| `<C-a>` | Attach file | Buffer-local shortcut |

### Removed Mappings

- `<leader>mc` group (compose subgroup)
- `<leader>mcd` (save draft) - replaced by `<leader>md`
- `<leader>mcD` (discard) - replaced by `<leader>mq`
- `<leader>mce` (send) - replaced by `<leader>me`
- `<leader>mcq` (quit) - replaced by `<leader>mq`
- Conditional `<leader>ms` (send) - removed to preserve global sync inbox

## Files Modified

- `lua/neotex/plugins/editor/which-key.lua` - Replaced 3-letter compose subgroup with 2-letter mappings
- `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua` - Added compose-specific help content
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Updated keybinding comments and help handler
- `lua/neotex/plugins/tools/himalaya/ui/email_composer.lua` - Updated mapping documentation comments

## Verification

- Neovim startup: Success
- which-key module loading: Success
- folder_help module loading: Success
- config.ui module loading: Success
- No syntax errors in modified files

## Manual Testing Guide

### Test 1: Verify which-key popup shows 2-letter mappings

1. Open Neovim: `nvim`
2. Start composing an email: `:HimalayaWrite`
3. Press `<leader>` (Space key) and wait for which-key popup
4. Press `m` to see mail submenu

**Expected**:
- Should see `me` - "send email"
- Should see `md` - "save draft"
- Should see `mq` - "quit/discard"
- Should NOT see `mc` group (3-letter subgroup removed)

### Test 2: Send email functionality

1. In compose buffer, write a test email:
   ```
   From: your@email.com
   To: test@example.com
   Cc:
   Bcc:
   Subject: Test 2-letter send mapping

   Testing <leader>me send mapping.
   ```
2. Press `<leader>me` (Space + m + e)

**Expected**:
- Email should be sent successfully
- No error about `<leader>ms` conflict
- Should return to email list

### Test 3: Save draft functionality

1. Start composing: `:HimalayaWrite`
2. Write partial email content
3. Test both shortcuts:
   - Press `<leader>md` (Space + m + d)
   - Verify draft is saved
   - Edit draft again
   - Press `<C-d` (Ctrl+d)

**Expected**:
- Both `<leader>md` and `<C-d>` should save draft
- Draft should appear in drafts folder

### Test 4: Quit/discard functionality

1. Start composing: `:HimalayaWrite`
2. Write some content
3. Press `<leader>mq` (Space + m + q)
4. Confirm discard when prompted

**Expected**:
- Email should be discarded
- Should return to email list
- Draft should not be saved

Alternative:
- Try `<C-q>` (Ctrl+q) instead

### Test 5: Verify sync inbox still works

1. Open Neovim in himalaya sidebar
2. Press `<leader>ms` (Space + m + s)

**Expected**:
- Should sync inbox (NOT send email)
- This verifies the conflict was resolved
- `<leader>ms` should NEVER send an email

### Test 6: Help menu shows compose shortcuts

1. Start composing: `:HimalayaWrite`
2. Press `?` in compose buffer

**Expected**:
- Help popup should show compose-specific help
- Should list:
  - `<leader>me` - Send email
  - `<leader>md` - Save draft
  - `<leader>mq` - Quit/discard
  - `<C-d>` - Save draft
  - `<C-q>` - Discard
  - `<C-a>` - Attach file

### Test 7: Old 3-letter mappings are gone

1. In compose buffer, press `<leader>mc`

**Expected**:
- Should NOT show a compose subgroup
- Should show general mail menu instead
- Confirms `<leader>mc*` mappings were removed

### Test 8: Context sensitivity of mappings

1. Open himalaya sidebar (email list)
2. Press `<leader>me`

**Expected**:
- Should do nothing or show error
- `<leader>me` should ONLY work in compose buffers
- Confirms conditional registration is working

### Test 9: Attach file functionality

1. Start composing: `:HimalayaWrite`
2. Press `<C-a>` (Ctrl+a)
3. Select a file to attach

**Expected**:
- File picker should open
- Should be able to attach file
- Confirms buffer-local keymaps still work

### Test 10: Full compose workflow

1. Open Neovim: `nvim`
2. Navigate to himalaya sidebar
3. Press `c` (quick compose) or `:HimalayaWrite`
4. Fill in email fields
5. Press `<C-a>` to attach a file (optional)
6. Press `<leader>md` to save draft
7. Edit draft further
8. Press `<leader>me` to send
9. Verify email was sent

**Expected**:
- Entire workflow should work smoothly
- No keymap conflicts
- All 2-letter mappings function correctly

## Checklist Summary

- [ ] which-key shows `me`, `md`, `mq` in compose buffer
- [ ] which-key does NOT show `mc` subgroup
- [ ] `<leader>me` sends email from compose buffer
- [ ] `<leader>md` saves draft
- [ ] `<leader>mq` discards email
- [ ] `<C-d>`, `<C-q>`, `<C-a>` buffer shortcuts work
- [ ] `<leader>ms` syncs inbox (not send email)
- [ ] `?` in compose buffer shows correct help
- [ ] Old `<leader>mc*` mappings are removed
- [ ] Mappings are context-aware (compose only)
- [ ] Full compose workflow works end-to-end

## Notes

- The `<leader>ms` mapping now consistently means "sync inbox" in all contexts
- Compose buffers use `<leader>me` for sending, which is mnemonic (E for Email/Envelope)
- Help menu in compose buffers (`?`) now shows compose-specific help with 2-letter mappings
- Ctrl-key buffer-local shortcuts (`<C-d>`, `<C-q>`, `<C-a>`) remain unchanged
