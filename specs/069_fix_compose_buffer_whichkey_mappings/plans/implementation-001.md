# Implementation Plan: Task #69

- **Task**: 69 - Fix compose buffer which-key mappings not appearing
- **Status**: [COMPLETED]
- **Effort**: 0.5-1 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false
- **Date**: 2026-02-11

## Overview

Fix compose buffer which-key mappings (`<leader>me`, `<leader>md`, `<leader>mq`) not appearing in the popup by switching from which-key's `cond` parameter (which only controls activation, not visibility) to buffer-local keymaps using `vim.keymap.set()` with `buffer = bufnr`. The existing `setup_compose_keymaps()` function in `config/ui.lua` will be extended with the leader mappings, and the conditional which-key registrations will be removed.

### Research Integration

The research report identified that:
1. The `cond` parameter in which-key.nvim controls mapping **activation**, not popup **visibility**
2. Buffer-local keymaps with `desc` fields are automatically discovered and displayed by which-key
3. The existing `config/ui.lua` pattern using `setup_compose_keymaps(bufnr)` is the correct location for these mappings
4. The maintainer (folke) recommends `vim.keymap.set()` with `buffer` parameter for context-specific keymaps

## Goals & Non-Goals

**Goals**:
- Make `<leader>me`, `<leader>md`, `<leader>mq` appear in which-key popup when in compose buffers
- Maintain existing Ctrl shortcuts (`<C-d>`, `<C-q>`, `<C-a>`) alongside new leader mappings
- Follow established codebase patterns for buffer-local keymap setup

**Non-Goals**:
- Changing the which-key registration pattern for other Himalaya buffer types
- Adding new keymaps beyond those already defined in the research report
- Modifying the which-key plugin configuration itself

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Leader mappings conflict with global mappings | Low | Low | Buffer-local mappings take precedence by design |
| which-key doesn't discover buffer-local leader mappings | Medium | Low | Pattern verified in maintainer documentation |
| Icons don't display for buffer-local keymaps | Low | Medium | Icons can be added via `vim.keymap.set` option or separate which-key group |

## Implementation Phases

### Phase 1: Add Buffer-Local Leader Mappings [COMPLETED]

**Goal**: Add `<leader>me`, `<leader>md`, `<leader>mq` mappings to the `setup_compose_keymaps()` function

**Tasks**:
- [ ] Add leader mapping for send email (`<leader>me`)
- [ ] Add leader mapping for save draft (`<leader>md`)
- [ ] Add leader mapping for quit/discard (`<leader>mq`)

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Add leader keymaps to `setup_compose_keymaps()` function (after line 395)

**Implementation Details**:

Insert after line 395 (after `local opts = { buffer = bufnr, silent = true }`):

```lua
-- Leader mappings (2-letter maximum per task 67)
-- These appear in which-key popup only when in compose buffer
keymap('n', '<leader>me', '<cmd>HimalayaSend<CR>',
  vim.tbl_extend('force', opts, { desc = 'send email' }))
keymap('n', '<leader>md', '<cmd>HimalayaSaveDraft<CR>',
  vim.tbl_extend('force', opts, { desc = 'save draft' }))
keymap('n', '<leader>mq', '<cmd>HimalayaDiscard<CR>',
  vim.tbl_extend('force', opts, { desc = 'quit/discard' }))
```

**Verification**:
- Open a compose buffer with `:HimalayaWrite` or reply to an email
- Press `<leader>m` and verify `e`, `d`, `q` options appear in which-key popup
- Test each mapping executes the correct command

---

### Phase 2: Remove Conditional which-key Registrations [COMPLETED]

**Goal**: Remove the redundant `wk.add()` block with `cond = is_compose_buffer` from which-key.lua

**Tasks**:
- [ ] Remove lines 551-557 from which-key.lua (the conditional compose mappings block)

**Timing**: 5 minutes

**Files to modify**:
- `lua/neotex/plugins/editor/which-key.lua` - Remove lines 551-557

**Implementation Details**:

Remove this block:
```lua
-- Compose-specific 2-letter mappings (only visible in compose buffers)
-- These override the email actions subgroup for compose buffers
wk.add({
  { "<leader>me", "<cmd>HimalayaSend<CR>", desc = "send email", icon = "󰊠", cond = is_compose_buffer },
  { "<leader>md", "<cmd>HimalayaSaveDraft<CR>", desc = "save draft", icon = "󰉊", cond = is_compose_buffer },
  { "<leader>mq", "<cmd>HimalayaDiscard<CR>", desc = "quit/discard", icon = "󰆴", cond = is_compose_buffer },
})
```

**Verification**:
- Neovim starts without errors
- In non-compose buffers, `<leader>me` shows email actions subgroup (not send email)
- In compose buffers, `<leader>me` shows "send email" (from buffer-local mapping)

---

### Phase 3: Verification and Testing [COMPLETED]

**Goal**: Comprehensive testing of the fix

**Tasks**:
- [ ] Test compose buffer keymap visibility in which-key popup
- [ ] Test compose buffer keymap functionality (send, draft, discard)
- [ ] Test non-compose buffer keymaps remain unaffected
- [ ] Verify no Neovim startup errors

**Timing**: 10 minutes

**Files to modify**: None (testing phase)

**Test Procedures**:

1. **Startup Test**:
   ```bash
   nvim --headless -c "lua require('neotex.plugins.editor.which-key')" -c "qa" 2>&1 | grep -i error
   ```

2. **Compose Buffer Test**:
   - Open Himalaya: `:HimalayaToggle`
   - Compose new email: press `c` or `:HimalayaWrite`
   - In compose buffer, press `<leader>m`
   - Verify popup shows: `e` send email, `d` save draft, `q` quit/discard
   - Press `<leader>me` and verify send action triggers

3. **Non-Compose Buffer Test**:
   - In email list buffer, press `<leader>m`
   - Press `e` and verify email actions subgroup appears (not send)
   - Verify `d`, `q` show expected non-compose mappings

**Verification**:
- All tests pass
- No regressions in existing Himalaya functionality

## Testing & Validation

- [ ] Neovim starts without errors after changes
- [ ] `<leader>me`, `<leader>md`, `<leader>mq` appear in which-key popup in compose buffers
- [ ] Each mapping executes the correct Himalaya command
- [ ] Non-compose buffers show normal `<leader>m` submenus
- [ ] Existing Ctrl shortcuts (`<C-d>`, `<C-q>`, `<C-a>`) continue to work

## Artifacts & Outputs

- Modified `lua/neotex/plugins/tools/himalaya/config/ui.lua`
- Modified `lua/neotex/plugins/editor/which-key.lua`
- Implementation summary documenting the changes

## Rollback/Contingency

If the fix causes issues:
1. Revert changes to `config/ui.lua` (remove added leader keymaps)
2. Restore the removed block in `which-key.lua` (lines 551-557)
3. The original behavior (keymaps not visible) is restored
