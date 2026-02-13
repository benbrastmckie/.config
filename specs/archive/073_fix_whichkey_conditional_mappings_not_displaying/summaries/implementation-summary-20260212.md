# Implementation Summary: Task #73

**Completed**: 2026-02-12
**Duration**: ~15 minutes

## Changes Made

Fixed compose-specific keybindings (`<leader>me`, `<leader>md`, `<leader>mq`) and email preview keybindings not appearing in the which-key menu. The root cause was that the `cond` parameter in which-key.nvim v3 is evaluated only once at registration time, not dynamically when the menu is displayed. This made it unsuitable for filetype-conditional mappings.

The solution follows the established pattern from `after/ftplugin/tex.lua`: register keymaps buffer-locally using `wk.add()` with `buffer = buf` when the specific buffer type is created.

## Files Modified

- `lua/neotex/plugins/tools/himalaya/ui/email_composer.lua`
  - Added buffer-local which-key registration in `setup_compose_keymaps(buf)` function
  - Registers `<leader>me` (send), `<leader>md` (draft), `<leader>mq` (quit) per-buffer

- `lua/neotex/plugins/tools/himalaya/ui/email_preview.lua`
  - Added buffer-local which-key registration in `get_or_create_preview_buffer()` function
  - Registers email preview keymaps (`<leader>mr`, `<leader>mR`, `<leader>mf`, `<leader>md`, `<leader>ma`, `<leader>mn`, `<leader>m/`) per-buffer

- `lua/neotex/plugins/editor/which-key.lua`
  - Removed deprecated `cond`-based mappings for compose and email preview
  - Removed unused helper functions: `is_mail`, `is_himalaya_list`, `is_himalaya_email`
  - Added comment explaining the new buffer-local registration pattern

## Verification

- Neovim startup: Success (no errors)
- email_composer module loading: Success
- email_preview module loading: Success
- which-key module loading: Success
- Compose keymap registration: Success
- Preview buffer creation with keymaps: Success

## Technical Notes

The buffer-local registration pattern works as follows:
1. When a compose buffer is created, `setup_compose_keymaps(buf)` is called
2. Inside this function, we call `wk.add({...})` with `buffer = buf` for each mapping
3. This registers the mappings only for that specific buffer
4. When which-key is triggered in that buffer, it displays the buffer-local mappings

This approach is consistent with how the codebase already handles LaTeX-specific keymaps in `after/ftplugin/tex.lua`.
