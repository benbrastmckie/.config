# Implementation Plan: Task #86

- **Task**: 86 - Fix himalaya sent folder display and sidebar keybindings
- **Status**: [NOT STARTED]
- **Effort**: 2-3 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, state-management.md, neovim-lua.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

This plan addresses three issues: (1) the sent folder configuration mismatch in himalaya config, (2) missing sync/account keybindings in the email list sidebar, and (3) updating the help menu to document all available keybindings. The research identified that the root cause of sent emails not appearing is a folder alias mismatch in the himalaya config (`[Gmail].Sent Mail` vs `Sent`), and that useful sync commands lack single-letter sidebar shortcuts.

### Research Integration

- Sent folder issue is a config problem in `~/.config/himalaya/config.toml` - uses Gmail IMAP-style folder names but backend is maildir with different folder names
- Keys `s`, `S`, `A`, `i` are available in the `himalaya-list` filetype and not currently mapped
- The `sync_all()` function is referenced in commands/sync.lua but may not exist in main.lua - needs implementation
- Help menu in `folder_help.lua` needs a new "Sync & Accounts" section

## Goals & Non-Goals

**Goals**:
- Document the himalaya config fix for sent folder aliases (user must update Nix config)
- Add sidebar keybindings for `s` (sync inbox), `S` (full sync), `A` (switch account), `i` (sync info)
- Update help menu with new keybindings and threading documentation
- Implement missing `sync_all()` function if not present in main.lua
- Update `get_keybinding()` configuration table for consistency

**Non-Goals**:
- Automatically modifying the himalaya config (managed by Nix home-manager)
- Adding auto-sync toggle to sidebar (already available via `<leader>mt`)
- Changing existing keybindings

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| `sync_all()` not implemented in main.lua | Medium | Medium | Create the function wrapping sync manager |
| Key conflicts in sidebar | Low | Low | Verified s/S/A/i are unused |
| Help menu window overflow | Low | Low | Keep line lengths under 45 chars |

## Implementation Phases

### Phase 1: Document Himalaya Config Fix [NOT STARTED]

**Goal**: Create documentation explaining the sent folder configuration fix that the user needs to apply via Nix home-manager.

**Tasks**:
- [ ] Create a config fix documentation file in the task reports directory
- [ ] Document the correct folder aliases for maildir backend
- [ ] Include verification commands (`himalaya folder list -a gmail`)

**Timing**: 0.25 hours

**Files to modify**:
- `specs/086_fix_himalaya_sent_and_sidebar_keybindings/reports/config-fix.md` - Create new documentation

**Verification**:
- Documentation file exists with clear instructions

---

### Phase 2: Implement sync_all Function [NOT STARTED]

**Goal**: Ensure the `sync_all()` function exists in main.lua to support full folder synchronization.

**Tasks**:
- [ ] Check if `sync_all()` exists in main.lua
- [ ] If missing, implement `sync_all()` wrapping the sync manager's full sync capability
- [ ] Follow the pattern of `sync_inbox()` for consistency

**Timing**: 0.5 hours

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/main.lua` - Add `sync_all()` function if missing

**Verification**:
- `:HimalayaSyncFull` command executes without errors
- `main.sync_all()` can be called from Lua

---

### Phase 3: Add Sidebar Keybindings [NOT STARTED]

**Goal**: Add single-letter keybindings for sync and account operations to the email list sidebar.

**Tasks**:
- [ ] Add `s` keymap for sync inbox in `setup_email_list_keymaps()`
- [ ] Add `S` keymap for full sync in `setup_email_list_keymaps()`
- [ ] Add `A` keymap for switch account in `setup_email_list_keymaps()`
- [ ] Add `i` keymap for sync info in `setup_email_list_keymaps()`
- [ ] Update `get_keybinding()` table with new mappings

**Timing**: 0.5 hours

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Add keybindings to `setup_email_list_keymaps()` and `get_keybinding()`

**Verification**:
- Press `s` in email list - triggers inbox sync
- Press `S` in email list - triggers full sync
- Press `A` in email list - shows account picker
- Press `i` in email list - shows sync info floating window

---

### Phase 4: Update Help Menu [NOT STARTED]

**Goal**: Update the help menu to include all available keybindings including new sync operations and threading commands.

**Tasks**:
- [ ] Add "Sync & Accounts" section to `get_help_content()` in folder_help.lua
- [ ] Add `s`, `S`, `A`, `i` keybindings to the new section
- [ ] Add "Threading" section documenting `<Tab>`, `zo`/`zc`, `zR`/`zM`, `gT`
- [ ] Ensure line lengths stay under 45 characters for window fit

**Timing**: 0.5 hours

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua` - Update `get_help_content()` with new sections

**Verification**:
- Press `?` in email list sidebar
- Verify help window shows "Sync & Accounts" section with new keybindings
- Verify help window shows "Threading" section with fold-style keybindings
- Window displays correctly without overflow

---

### Phase 5: Testing and Validation [NOT STARTED]

**Goal**: Verify all changes work correctly together.

**Tasks**:
- [ ] Test each new keybinding in the email list sidebar
- [ ] Verify help menu displays all new content correctly
- [ ] Test sync operations complete without errors
- [ ] Verify account switching works from sidebar
- [ ] Run nvim --headless to check for Lua errors

**Timing**: 0.5 hours

**Files to modify**:
- None (testing only)

**Verification**:
- All keybindings trigger correct actions
- No Lua errors in log
- Help menu displays correctly
- Module loads without error: `nvim --headless -c "lua require('neotex.plugins.tools.himalaya.config.ui')" -c "q"`

---

## Testing & Validation

- [ ] `s` in sidebar triggers inbox sync
- [ ] `S` in sidebar triggers full sync
- [ ] `A` in sidebar opens account picker
- [ ] `i` in sidebar shows sync info
- [ ] `?` shows updated help with all keybindings
- [ ] No Lua errors on module load
- [ ] Help window fits content without overflow

## Artifacts & Outputs

- Config fix documentation: `specs/086_fix_himalaya_sent_and_sidebar_keybindings/reports/config-fix.md`
- Modified files:
  - `lua/neotex/plugins/tools/himalaya/config/ui.lua`
  - `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua`
  - `lua/neotex/plugins/tools/himalaya/ui/main.lua` (if sync_all missing)

## Rollback/Contingency

If implementation causes issues:
1. Revert changes to `ui.lua`, `folder_help.lua`, and `main.lua`
2. Use `git checkout HEAD -- <files>` to restore original state
3. New keybindings are additive - removing them has no cascading effects
