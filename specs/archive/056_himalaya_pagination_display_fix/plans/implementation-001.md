# Implementation Plan: Task #56

- **Task**: 56 - himalaya_pagination_display_fix
- **Status**: [COMPLETED]
- **Effort**: 3-5 hours
- **Dependencies**: Task #55 (3-state preview model - completed)
- **Research Inputs**: research-001.md (pagination root causes), research-002.md (keymap inventory)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, neovim-lua.md, state-management.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

This plan addresses two major issues: (1) fixing the pagination display bug where next_page() is blocked when total_emails is 0, and (2) comprehensively reorganizing keymaps per explicit user requirements. The reorganization removes 3-letter mappings, separates sidebar vs reader buffer keymaps, changes pagination keys to `<C-d>`/`<C-u>`, and adds selection keymaps `n`/`p`.

### Research Integration

From research-001:
- Pagination guard condition `state.get_current_page() * state.get_page_size() < state.get_total_emails()` fails when total_emails is 0
- Need to allow pagination when total is unknown (0)

From research-002:
- Complete keymap inventory across 6 buffer contexts identified
- Help documentation (folder_help.lua) shows different keymaps than actual implementation
- 72+ keybindings currently defined across contexts

## Goals & Non-Goals

**Goals**:
- Fix pagination to work when total_emails is unknown
- Reorganize sidebar keymaps per user requirements
- Remove all single-letter action keys from email reader buffer
- Add selection keymaps (`n` = select, `p` = deselect, `<Space>` = toggle)
- Change pagination to `<C-d>` (next) / `<C-u>` (previous)
- Replace `gr` (refresh) with `F`
- Open emails in full buffer (not split)
- Register compose-only mappings with which-key for contextual display

**Non-Goals**:
- Rewriting the 3-state preview model (task 55 completed)
- Changing which-key global `<leader>m` group bindings
- Modifying search results or template manager keymaps

## Keymap Reorganization Summary

### Sidebar/Email List Buffer (`himalaya-list`)

| Key | Current Action | New Action | Notes |
|-----|---------------|------------|-------|
| `j` | Move down (default) | Move down | Keep |
| `k` | Move up (default) | Move up | Keep |
| `q` | - | Quit/close | Add |
| `<CR>` | 3-state model | 3-state model | Keep (task 55) |
| `<Esc>` | Regress state | Back/close | Keep |
| `<Space>` | Toggle selection | Toggle selection | Keep |
| `n` | Next page | Select email | Change |
| `p` | Previous page | Deselect email | Change |
| `<C-d>` | - | Next page | Add |
| `<C-u>` | - | Previous page | Add |
| `d` | Delete selected | - | **Remove** (no single-letter actions) |
| `m` | Move selected | - | **Remove** (broken, use which-key) |
| `c` | Compose | - | **Remove** (broken, use which-key) |
| `r` | Reply | - | **Remove** (broken, use which-key) |
| `R` | Reply all | - | **Remove** (broken, use which-key) |
| `f` | Forward | - | **Remove** (broken, use which-key) |
| `/` | Search | - | **Remove** (broken, use which-key) |
| `gr` | Refresh | - | Remove 2-letter mapping |
| `F` | - | Refresh | Add single-letter refresh |
| `?` | Help | Help | Keep |

### Email Reader Buffer (`himalaya-email`)

| Key | Current Action | New Action | Notes |
|-----|---------------|------------|-------|
| `q` | Close reader | Close reader | Keep |
| `<Esc>` | Close reader | Close reader | Keep |
| `j` | Move down (default) | Move down | Keep (scrolling) |
| `k` | Move up (default) | Move up | Keep (scrolling) |
| `r` | Reply | - | **Remove** |
| `R` | Reply all | - | **Remove** |
| `f` | Forward | - | **Remove** |
| `d` | Delete | - | **Remove** |
| `a` | Archive | - | **Remove** |
| `?` | Help | Which-key prompt | Modify (show which-key) |

Reader actions (reply, delete, archive, forward) should be accessed via `<leader>m` which-key group.

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Breaking existing user muscle memory | Medium | High | Document changes clearly |
| `<C-d>`/`<C-u>` conflict with scroll | Medium | Medium | Only apply in sidebar buffer |
| which-key context not showing correctly | Low | Low | Test compose buffer detection |
| Email opens in wrong location | Low | Low | Test window management |

## Implementation Phases

### Phase 1: Fix Pagination Guard Condition [COMPLETED]

**Goal**: Allow pagination to work even when total_emails is unknown (0)

**Tasks**:
- [ ] Modify `next_page()` in email_list.lua to allow advancement when total=0
- [ ] Add debug logging for pagination state
- [ ] Test pagination with unknown total

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Fix guard condition at line 1237

**Verification**:
- Press `n` (or new key after Phase 2) moves to page 2
- Page indicator updates in header
- Emails display correctly on page 2

---

### Phase 2: Reorganize Sidebar Keymaps [COMPLETED]

**Goal**: Implement new keymap scheme for sidebar/email-list buffer

**Tasks**:
- [ ] Remove single-letter action keys: `d`, `m`, `c`, `r`, `R`, `f`, `/`
- [ ] Remove `gr` refresh binding
- [ ] Add `F` for refresh
- [ ] Change `n` from next_page to select_email
- [ ] Change `p` from prev_page to deselect_email
- [ ] Add `<C-d>` for next_page
- [ ] Add `<C-u>` for prev_page
- [ ] Add `q` for quit/close sidebar
- [ ] Update get_keybinding() reference table

**Timing**: 1 hour

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` - setup_email_list_keymaps() at line 163

**Verification**:
- `<C-d>` advances page
- `<C-u>` goes to previous page
- `n` selects email under cursor
- `p` deselects email under cursor
- `<Space>` toggles selection
- `F` refreshes email list
- Single-letter action keys no longer bound

---

### Phase 3: Implement Selection Functions [COMPLETED]

**Goal**: Add select/deselect functions for `n`/`p` keys

**Tasks**:
- [ ] Verify `toggle_selection()` exists in email_list.lua
- [ ] Add `select_email()` function if not exists
- [ ] Add `deselect_email()` function if not exists
- [ ] Ensure visual feedback for selected emails

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Add selection functions

**Verification**:
- `n` adds email to selection
- `p` removes email from selection
- Selection state visible in sidebar

---

### Phase 4: Clean Email Reader Keymaps [COMPLETED]

**Goal**: Remove single-letter action keys from reader buffer

**Tasks**:
- [ ] Remove `r`, `R`, `f`, `d`, `a` keymaps from email_reader.lua
- [ ] Keep navigation keys: `q`, `<Esc>`, `j`, `k`
- [ ] Update help display to reference which-key

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_reader.lua` - setup_reader_keymaps() at line 49

**Verification**:
- Single-letter keys do not trigger actions in reader
- Navigation keys still work
- `?` shows which-key hint

---

### Phase 5: Email Opens in Full Buffer [COMPLETED]

**Goal**: Change email display from split to full buffer

**Tasks**:
- [ ] Modify `open_email_buffer()` to use full buffer instead of vsplit
- [ ] Ensure proper focus management after open
- [ ] Handle return to sidebar on close

**Timing**: 45 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_reader.lua` - open_email_buffer() at line 180

**Verification**:
- Third `<CR>` press opens email in full buffer (not split)
- `q` or `<Esc>` returns to sidebar
- Sidebar state preserved

---

### Phase 6: Register Compose Keymaps with which-key [COMPLETED]

**Goal**: Make compose-only mappings show contextually in which-key

**Tasks**:
- [ ] Review compose buffer detection in which-key.lua
- [ ] Add conditional keymaps for compose context under `<leader>mc`
- [ ] Ensure keymaps only appear when in compose buffer

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/editor/which-key.lua` - Compose subgroup around line 550

**Verification**:
- In compose buffer, `<leader>m` shows compose-specific options
- Outside compose buffer, compose options hidden
- `<leader>mcd` (save draft), `<leader>mce` (send) work correctly

---

### Phase 7: Update Help Documentation [COMPLETED]

**Goal**: Sync help content with new keymaps

**Tasks**:
- [ ] Update folder_help.lua to reflect new keybindings
- [ ] Update email_reader.lua help message
- [ ] Update any other help strings referencing old keymaps

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua` - Help content
- `lua/neotex/plugins/tools/himalaya/ui/email_reader.lua` - Help string

**Verification**:
- `?` in sidebar shows correct keybindings
- Help matches actual functionality

---

### Phase 8: Integration Testing [COMPLETED]

**Goal**: Verify all changes work together

**Tasks**:
- [ ] Test full email workflow: open sidebar -> navigate -> select -> read -> close
- [ ] Test pagination: `<C-d>`/`<C-u>` navigation
- [ ] Test selection: `n`/`p`/`<Space>` toggling
- [ ] Test reader: opens full buffer, no action keys
- [ ] Test compose: which-key shows compose options
- [ ] Test refresh: `F` refreshes email list

**Timing**: 30 minutes

**Verification**:
- All keymaps work as documented
- No conflicts between contexts
- Smooth user experience

## Testing & Validation

- [ ] Pagination advances correctly with `<C-d>`
- [ ] Pagination returns with `<C-u>`
- [ ] Selection toggle with `<Space>` works
- [ ] Select with `n` adds to selection
- [ ] Deselect with `p` removes from selection
- [ ] Refresh with `F` updates email list
- [ ] Email opens in full buffer (not split)
- [ ] Reader has no single-letter action keys
- [ ] Compose mappings show in which-key contextually
- [ ] Help documentation accurate

## Artifacts & Outputs

- Modified `lua/neotex/plugins/tools/himalaya/ui/email_list.lua`
- Modified `lua/neotex/plugins/tools/himalaya/config/ui.lua`
- Modified `lua/neotex/plugins/tools/himalaya/ui/email_reader.lua`
- Modified `lua/neotex/plugins/editor/which-key.lua`
- Modified `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua`

## Rollback/Contingency

If implementation fails:
1. Git restore modified files to pre-implementation state
2. Keymaps are buffer-local, so Neovim restart clears any session state
3. No database or persistent state changes in this task
