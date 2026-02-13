# Implementation Plan: Task #88

- **Task**: 88 - simplify_himalaya_threading_keybindings
- **Status**: [NOT STARTED]
- **Effort**: 1-2 hours
- **Dependencies**: None
- **Research Inputs**: specs/088_simplify_himalaya_threading_keybindings/reports/research-001.md
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Date**: 2026-02-13

## Overview

Simplify himalaya threading keybindings from 6 keys to 2 keys. Remove vim-fold style keybindings (zo, zc, zR, zM) and the threading toggle (gT), keeping only `<Tab>` for single thread toggle and adding `<S-Tab>` for toggle all threads expand/collapse.

### Research Integration

Key findings from research:
- Current keybindings: `<Tab>`, `zo`, `zc`, `zR`, `zM`, `gT` in ui.lua lines 362-414
- `<S-Tab>` is currently mapped to `<Nop>` in setup_buffer_keymaps() at line 142
- Need new `toggle_all_threads()` function in email_list.lua
- Help menu in folder_help.lua lines 87-96 needs simplification
- get_keybinding() reference table at lines 613-619 needs update

## Goals & Non-Goals

**Goals**:
- Reduce threading keybindings from 6 to 2 for simpler user experience
- Add `<S-Tab>` to toggle all threads (smart: collapse if any expanded, else expand all)
- Keep `<Tab>` for single thread toggle under cursor
- Update help menu to reflect simplified keybindings

**Non-Goals**:
- Preserving vim-fold compatibility (zo/zc/zR/zM intentionally removed)
- Keeping threading on/off toggle (gT intentionally removed)
- Deprecation period (clean-break per project standards)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Users familiar with fold keys | L | M | Simple 2-key interface is intuitive; document in commit |
| S-Tab conflicts elsewhere | L | L | Only applies to himalaya-list filetype |
| Loss of threading toggle | L | L | Feature rarely used; can re-add later if needed |

## Implementation Phases

### Phase 1: Add toggle_all_threads Function [NOT STARTED]

**Goal**: Create the toggle_all_threads() function in email_list.lua

**Tasks**:
- [ ] Add `M.toggle_all_threads()` function after line 170 (after collapse_all_threads)
- [ ] Function checks if any threads are expanded
- [ ] If any expanded: collapse all; else: expand all
- [ ] Call refresh_email_list() after toggling

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Add new function after collapse_all_threads()

**Implementation**:
```lua
--- Toggle all threads expand/collapse
--- If any thread is expanded, collapse all; otherwise expand all
function M.toggle_all_threads()
  local thread_order = state.get('email_list.thread_order', {})
  local any_expanded = false

  -- Check if any threads are currently expanded
  for _, normalized_subject in ipairs(thread_order) do
    if expanded_threads[normalized_subject] then
      any_expanded = true
      break
    end
  end

  -- Toggle: if any expanded, collapse all; otherwise expand all
  if any_expanded then
    M.collapse_all_threads()
  else
    M.expand_all_threads()
  end

  M.refresh_email_list()
end
```

**Verification**:
- Function exists and is exported on module M
- No syntax errors in email_list.lua

---

### Phase 2: Update Keymaps in ui.lua [NOT STARTED]

**Goal**: Remove old keymaps and add S-Tab keymap

**Tasks**:
- [ ] Remove `<S-Tab>` `<Nop>` mapping from setup_buffer_keymaps() (line 142)
- [ ] Remove `zo` keymap (lines 371-377)
- [ ] Remove `zc` keymap (lines 379-385)
- [ ] Remove `zR` keymap (lines 387-394)
- [ ] Remove `zM` keymap (lines 396-403)
- [ ] Remove `gT` keymap (lines 405-414)
- [ ] Add `<S-Tab>` keymap after `<Tab>` keymap calling toggle_all_threads()
- [ ] Update comment to reference Task #88

**Timing**: 20 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Modify setup_buffer_keymaps() and setup_email_list_keymaps()

**Verification**:
- Only `<Tab>` and `<S-Tab>` keymaps remain for threading
- No syntax errors in ui.lua

---

### Phase 3: Update get_keybinding Reference [NOT STARTED]

**Goal**: Update the keybinding reference table

**Tasks**:
- [ ] Remove entries: expand_thread, collapse_thread, expand_all_threads, collapse_all_threads, toggle_threading
- [ ] Add entry: toggle_all_threads = '<S-Tab>'
- [ ] Update comment to reference Task #88

**Timing**: 5 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Modify get_keybinding() table (lines 613-619)

**New content**:
```lua
-- Threading keymaps (Task #88 - simplified)
toggle_thread = '<Tab>',
toggle_all_threads = '<S-Tab>',
```

**Verification**:
- get_keybinding() returns correct values for new keys

---

### Phase 4: Update Help Menu [NOT STARTED]

**Goal**: Simplify the threading section in folder_help.lua

**Tasks**:
- [ ] Replace base_threading content (lines 87-96)
- [ ] Remove zo, zc, zR, zM, gT entries
- [ ] Add S-Tab entry
- [ ] Update Tab description for clarity

**Timing**: 5 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua` - Modify base_threading table

**New content**:
```lua
local base_threading = {
  "Threading:",
  "  <Tab>     - Toggle thread expand/collapse",
  "  <S-Tab>   - Toggle all threads",
  ""
}
```

**Verification**:
- Help menu displays correctly with simplified threading section

---

### Phase 5: Verification and Testing [NOT STARTED]

**Goal**: Verify all changes work correctly

**Tasks**:
- [ ] Load nvim and open himalaya sidebar
- [ ] Test `<Tab>` toggles single thread under cursor
- [ ] Test `<S-Tab>` expands all when all collapsed
- [ ] Test `<S-Tab>` collapses all when any expanded
- [ ] Test `?` shows updated help with 2 threading keys
- [ ] Verify old keys (zo, zc, zR, zM, gT) no longer work

**Timing**: 15 minutes

**Verification**:
- All functionality works as specified
- No regressions in other himalaya functionality

---

## Testing & Validation

- [ ] nvim --headless -c "lua require('neotex.plugins.tools.himalaya.ui.email_list')" -c "q" (no errors)
- [ ] nvim --headless -c "lua require('neotex.plugins.tools.himalaya.config.ui')" -c "q" (no errors)
- [ ] nvim --headless -c "lua require('neotex.plugins.tools.himalaya.ui.folder_help')" -c "q" (no errors)
- [ ] Manual testing of Tab/S-Tab keybindings in himalaya sidebar
- [ ] Manual verification of help menu content

## Artifacts & Outputs

- Modified `lua/neotex/plugins/tools/himalaya/ui/email_list.lua`
- Modified `lua/neotex/plugins/tools/himalaya/config/ui.lua`
- Modified `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua`

## Rollback/Contingency

If implementation fails:
1. Revert all changes with `git checkout -- lua/neotex/plugins/tools/himalaya/`
2. Original keybindings will be restored
3. Research report and plan preserved for future attempt
