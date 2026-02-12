# Implementation Plan: Refactor Himalaya Keybindings

- **Task**: 71 - refactor_himalaya_keybindings_flatten_email_actions
- **Status**: [NOT STARTED]
- **Effort**: 1.5-2 hours
- **Dependencies**: None
- **Research Inputs**: Task 71 research (identified root cause and solution)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

Refactor himalaya keybindings to eliminate the `<leader>me` subgroup conflict and add requested keybindings. The current `<leader>me` email actions subgroup (lines 552-586 in which-key.lua) conflicts with the compose buffer's `<leader>me` send mapping. This plan removes the redundant subgroup (since single-letter buffer-local keys exist), changes `<leader>ma` to `<leader>mA` for switch account, adds new sidebar/list keybindings, and adds email preview `<leader>m` mappings.

## Goals & Non-Goals

**Goals**:
- Remove `<leader>me` email actions subgroup from which-key.lua
- Remove `is_himalaya_buffer` helper function (no longer needed)
- Change `<leader>ma` to `<leader>mA` for switch account globally
- Add `c` (change folder) and `e` (compose) to sidebar keymaps
- Change `c` from compose to change folder in email list, add `e` for compose
- Add `<leader>m` mappings to email preview buffer for common actions
- Update help messages to reflect new keybindings

**Non-Goals**:
- Changing the fundamental 3-state preview model
- Adding new features beyond keybinding reorganization
- Modifying compose buffer keymaps (they work correctly)

## Risks & Mitigations

- **Risk**: Breaking existing workflows. **Mitigation**: Single-letter keys in email list remain functional; only adding alternatives.
- **Risk**: Help messages become outdated. **Mitigation**: Update all help content in same phase.
- **Risk**: Conditional visibility logic errors. **Mitigation**: Use existing `is_himalaya_email` function pattern.

## Implementation Phases

### Phase 1: Update which-key.lua Global Mappings [NOT STARTED]

**Goal**: Remove email actions subgroup and update global mail mappings.

**Tasks**:
- [ ] Remove `is_himalaya_buffer` function (lines 548-550)
- [ ] Remove email actions subgroup block (lines 552-586)
- [ ] Change `<leader>ma` to `<leader>mA` for switch account (line 531)
- [ ] Verify compose buffer mappings remain unchanged (`<leader>me`, `<leader>md`, `<leader>mq` with cond=is_mail)

**Files to modify**:
- `lua/neotex/plugins/editor/which-key.lua`

**Timing**: 20 minutes

**Verification**:
- Load Neovim, open mail buffer, verify `<leader>me` sends email
- Verify `<leader>mA` switches account
- Open himalaya sidebar, verify `<leader>me` subgroup no longer appears

---

### Phase 2: Add Email Preview Leader Mappings [NOT STARTED]

**Goal**: Add `<leader>m` mappings for email actions in email preview buffers.

**Tasks**:
- [ ] Add email preview mappings section in which-key.lua with cond=is_himalaya_email:
  - `<leader>mr` - reply
  - `<leader>mR` - reply all
  - `<leader>mf` - forward
  - `<leader>md` - delete
  - `<leader>ma` - archive
  - `<leader>mn` - compose new
  - `<leader>m/` - search

**Files to modify**:
- `lua/neotex/plugins/editor/which-key.lua`

**Timing**: 15 minutes

**Verification**:
- Open email in preview mode
- Trigger which-key with `<leader>m`
- Verify email actions appear and function correctly

---

### Phase 3: Update Sidebar Keymaps in ui.lua [NOT STARTED]

**Goal**: Add `c` (change folder) and `e` (compose) keybindings to sidebar.

**Tasks**:
- [ ] Add `c` keymap for change folder (call main.show_folder_picker)
- [ ] Add `e` keymap for compose email (call main.compose_email)
- [ ] Update keybindings table in `get_keybinding` function

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` (setup_sidebar_keymaps function, ~line 434)

**Timing**: 15 minutes

**Verification**:
- Open himalaya sidebar
- Press `c`, verify folder picker appears
- Press `e`, verify compose buffer opens

---

### Phase 4: Update Email List Keymaps in ui.lua [NOT STARTED]

**Goal**: Change `c` from compose to change folder, add `e` for compose in email list.

**Tasks**:
- [ ] Change `c` keymap to call show_folder_picker instead of compose_email (line 339-344)
- [ ] Add `e` keymap for compose email
- [ ] Update keybindings table in `get_keybinding` function

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` (setup_email_list_keymaps function)

**Timing**: 15 minutes

**Verification**:
- Open email list
- Press `c`, verify folder picker appears
- Press `e`, verify compose buffer opens

---

### Phase 5: Update Help Messages [NOT STARTED]

**Goal**: Update all help content to reflect new keybindings.

**Tasks**:
- [ ] Update folder_help.lua:
  - Change `<leader>ma` to `<leader>mA` in base_folder_mgmt section
  - Update Quick Actions section: `c` = change folder, `e` = compose
  - Remove Mail Menu (`<leader>me`) reference
- [ ] Update commands/ui.lua show_help messages:
  - Remove `<leader>me` reference from list help
  - Update sidebar help to include `c` and `e`

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua`
- `lua/neotex/plugins/tools/himalaya/commands/ui.lua`

**Timing**: 20 minutes

**Verification**:
- Open email list, press `?` or `gH`, verify updated help content
- Open sidebar, press `?`, verify updated help content

---

### Phase 6: Validation and Testing [NOT STARTED]

**Goal**: Comprehensive testing of all keybinding changes.

**Tasks**:
- [ ] Test global mappings:
  - `<leader>mA` switches account
  - `<leader>mm` toggles sidebar
  - `<leader>mw` writes email
- [ ] Test compose buffer:
  - `<leader>me` sends email
  - `<leader>md` saves draft
  - `<leader>mq` discards
- [ ] Test email list:
  - `c` opens folder picker
  - `e` opens compose
  - Single-letter actions (r, R, f, d, a, m, /) still work
- [ ] Test sidebar:
  - `c` opens folder picker
  - `e` opens compose
  - `<CR>` selects folder
- [ ] Test email preview:
  - `<leader>mr` replies
  - `<leader>mR` replies all
  - `<leader>mf` forwards
  - `<leader>md` deletes
  - `<leader>ma` archives
  - `<leader>mn` composes new
  - `<leader>m/` searches
- [ ] Run headless validation: `nvim --headless -c "lua require('neotex.plugins.editor.which-key')" -c "q"`

**Timing**: 25 minutes

**Verification**:
- All tests pass
- No error notifications
- Help messages accurate

## Testing & Validation

- [ ] Neovim loads without errors
- [ ] which-key shows correct mail group mappings
- [ ] Compose buffer `<leader>me` sends email (no conflict)
- [ ] Email preview shows `<leader>m` actions in which-key
- [ ] Sidebar `c` and `e` keys function correctly
- [ ] Email list `c` and `e` keys function correctly
- [ ] All help dialogs show updated keybindings
- [ ] No regression in existing single-letter keybindings

## Artifacts & Outputs

- plans/implementation-001.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (post-implementation)

## Rollback/Contingency

If issues arise:
1. Revert which-key.lua changes to restore `<leader>me` subgroup
2. Revert ui.lua keybinding changes
3. Revert help message updates
4. Git reset to pre-implementation commit
