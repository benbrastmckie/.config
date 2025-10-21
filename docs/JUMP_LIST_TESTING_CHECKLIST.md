# Jump List Navigation Testing Checklist

## Prerequisites

Before running these tests, ensure you have:

1. Applied home-manager configuration changes (see KEYBOARD_PROTOCOL_SETUP.md)
2. Rebuilt home-manager: `home-manager switch`
3. Restarted your terminal emulator
4. Restarted Neovim (or run `:source %` on keymaps.lua)

## Phase 3: Cross-Terminal Validation

### Test in Kitty Terminal

- [ ] Launch Kitty terminal
- [ ] Open Neovim
- [ ] Create jump list entries:
  ```vim
  :e /tmp/test1.txt
  :e /tmp/test2.txt
  :e /tmp/test3.txt
  ```
- [ ] Test jump backward with `<C-o>` (should jump to test2.txt, then test1.txt)
- [ ] Test jump forward with `<C-i>` (should jump forward in list)
- [ ] Expected: `<C-i>` jumps forward, NOT switches to next buffer
- [ ] Verify jump list position with `:jumps`
- [ ] Test `<Tab>` still switches buffers correctly
- [ ] Test in markdown file:
  - [ ] Open a .md file
  - [ ] Verify jump list still works
  - [ ] Verify markdown Tab overrides don't interfere

### Test in WezTerm Terminal

- [ ] Launch WezTerm terminal
- [ ] Open Neovim
- [ ] Create jump list entries (same as Kitty test above)
- [ ] Test `<C-o>` backward navigation
- [ ] Test `<C-i>` forward navigation
- [ ] Expected: `<C-i>` jumps forward in jump list
- [ ] Verify with `:jumps`
- [ ] Test `<Tab>` buffer switching
- [ ] Test in markdown file

### Test in Alacritty Terminal (Optional)

**Note**: Alacritty support for keyboard protocol is experimental

- [ ] Launch Alacritty terminal
- [ ] Open Neovim
- [ ] Test jump list navigation
- [ ] Document any limitations
- [ ] If `<C-i>` doesn't work, this is expected (limited protocol support)

### End-to-End Jump List Workflow

Test a realistic workflow across all working terminals:

- [ ] Open multiple files (3+):
  ```vim
  :e ~/.config/nvim/init.lua
  :e ~/.config/nvim/lua/neotex/config/keymaps.lua
  :e ~/.config/nvim/lua/neotex/core/init.lua
  ```
- [ ] Use `:tag`, `gd`, or `/search` to create jumps within files
- [ ] Navigate backward with `<C-o>` multiple times
- [ ] Navigate forward with `<C-i>` multiple times
- [ ] Verify position matches `:jumps` output
- [ ] Expected: Smooth navigation through jump history

## Phase 4: Documentation and Edge Cases

### Edge Case Testing

#### Help Files
- [ ] Open Neovim help: `:help vim`
- [ ] Jump around help tags with `<C-]>` and `<C-o>`
- [ ] Test `<C-i>` jump forward in help
- [ ] Expected: Works normally

#### Terminal Buffers
- [ ] Open terminal in Neovim: `:terminal`
- [ ] Switch to another file, then back
- [ ] Test jump list navigation
- [ ] Expected: Works (terminal buffers are in jump list)

#### Window Splits
- [ ] Create splits: `:split` and `:vsplit`
- [ ] Open different files in each split
- [ ] Jump between files to create jump list entries
- [ ] Test `<C-o>` and `<C-i>` navigation
- [ ] Expected: Jump list is per-window, navigation works

#### Session Persistence (if using session plugins)
- [ ] Create jump list entries
- [ ] Save session
- [ ] Close Neovim
- [ ] Restore session
- [ ] Test if jump list persists
- [ ] Note: This may vary by session plugin

#### Markdown Files
- [ ] Open a markdown file: `:e test.md`
- [ ] Verify `<Tab>` in insert mode still works for lists
- [ ] Verify `<C-i>` in normal mode jumps forward
- [ ] Check `after/ftplugin/markdown.lua` for conflicts
- [ ] Expected: Both behaviors work independently

#### Telescope/Fuzzy Finder Integration
- [ ] Use Telescope file picker (if installed)
- [ ] Open several files via Telescope
- [ ] Verify these create jump list entries
- [ ] Test `<C-o>` and `<C-i>` navigation
- [ ] Expected: Normal jump list behavior

### Tmux Testing (if applicable)

If you use tmux:

- [ ] Start tmux session
- [ ] Launch terminal in tmux
- [ ] Open Neovim
- [ ] Test jump list navigation
- [ ] Note: Tmux may intercept keycodes; keyboard protocol passthrough may be needed
- [ ] Document tmux configuration if needed:
  ```tmux
  set -s extended-keys on
  set -as terminal-features 'xterm-kitty*:extkeys'
  ```

## Verification Criteria

### Successful Implementation

All of these should be true:

- [x] `<C-i>` jumps forward in jump list (not switches buffers)
- [x] `<C-o>` continues to jump backward as before
- [x] `<Tab>` still switches to next buffer
- [x] `<S-Tab>` still switches to previous buffer
- [x] Buffer navigation works as expected
- [x] Jump list behavior consistent across supported terminals
- [x] No conflicts with markdown or other filetype-specific mappings
- [x] Edge cases (help, terminal buffers, splits) work correctly

### Known Limitations

Document any issues found:

- Alacritty: Limited/experimental keyboard protocol support
- SSH sessions: Keyboard protocol may not work over SSH
- Older terminal versions: May not support protocol
- Tmux: May require additional configuration

## Regression Testing

Ensure existing functionality still works:

- [ ] `<Tab>` in insert mode works for completion
- [ ] Markdown `<Tab>` indentation works in insert mode
- [ ] Buffer navigation still functions as before
- [ ] Which-key shows correct keybinding descriptions
- [ ] No errors in `:messages` after navigation

## Documentation Checklist

- [x] Keymaps.lua has explanatory comments
- [x] Setup guide created (KEYBOARD_PROTOCOL_SETUP.md)
- [x] Testing checklist created (this file)
- [ ] User has reviewed setup guide
- [ ] User has applied home-manager changes
- [ ] User has completed testing checklist

## Troubleshooting Results

If issues are found, document them here:

### Issue 1: [Description]
- Terminal: [which terminal]
- Behavior: [what happens]
- Expected: [what should happen]
- Resolution: [how it was fixed or workaround]

### Issue 2: [Description]
- Terminal: [which terminal]
- Behavior: [what happens]
- Expected: [what should happen]
- Resolution: [how it was fixed or workaround]

## Next Steps After Testing

Once all tests pass:

1. Mark implementation as complete
2. Commit changes to git
3. Update any relevant project documentation
4. Consider adding to nvim/CLAUDE.md if this becomes a project standard
5. Close this testing checklist (or keep for reference)

## Success Metrics

- [ ] 100% of required tests passing
- [ ] 0 regressions in existing functionality
- [ ] Clear documentation for future reference
- [ ] Consistent behavior across all supported terminals

## Notes

Add any additional observations or notes here:

---

**Last Updated**: 2025-10-21
**Implementation Plan**: nvim/specs/plans/044_fix_ctrl_i_jump_list_navigation.md
**Setup Guide**: nvim/docs/KEYBOARD_PROTOCOL_SETUP.md
