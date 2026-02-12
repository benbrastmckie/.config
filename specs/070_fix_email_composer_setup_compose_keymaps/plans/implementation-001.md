# Implementation Plan: Task #70

- **Task**: 70 - fix_email_composer_setup_compose_keymaps
- **Status**: [NOT STARTED]
- **Effort**: 0.5-1 hours
- **Dependencies**: Task 69 completed (keymaps added to wrong location)
- **Research Inputs**: specs/070_fix_email_composer_setup_compose_keymaps/reports/research-001.md
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

Task 69 added compose buffer keymaps (`<leader>me`, `<leader>md`, `<leader>mq`) to `config/ui.lua:setup_compose_keymaps()`, but the `email_composer.lua` module has its own `setup_compose_keymaps()` function that shadows it. The fix is to add these keymaps to `which-key.lua` using the existing `is_mail()` conditional helper, which provides centralized keymap management and proper which-key integration.

### Research Integration

Research identified that:
- The `is_mail()` helper exists in which-key.lua (lines 204-206) but is currently unused
- Adding keymaps with `cond = is_mail` to which-key.lua is the recommended approach
- This aligns with the maintainability goal of centralizing which-key mappings
- The keymaps in `config/ui.lua` are now redundant and should be removed

## Goals and Non-Goals

**Goals**:
- Add `<leader>me`, `<leader>md`, `<leader>mq` keymaps to which-key.lua with `cond = is_mail`
- Remove redundant keymaps from config/ui.lua
- Keymaps should appear in which-key popup when in compose buffer (filetype "mail")

**Non-Goals**:
- Modifying email_composer.lua's setup_compose_keymaps (keep the comment-only structure)
- Changing the keymap bindings or commands themselves
- Adding new functionality beyond fixing the keymap visibility

## Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Keymaps still not visible in compose buffer | Medium | Low | Test with `:lua print(vim.bo.filetype)` to verify "mail" filetype |
| is_mail() condition not working | Medium | Low | Condition already tested with other cond= patterns in which-key.lua |
| Duplicate keymaps causing conflicts | Low | Low | Remove config/ui.lua keymaps in same phase |

## Implementation Phases

### Phase 1: Add keymaps to which-key.lua [NOT STARTED]

**Goal**: Add the compose buffer keymaps to which-key.lua using the `is_mail()` conditional

**Tasks**:
- [ ] Add new wk.add() block after line 586 (after email actions subgroup) with compose keymaps
- [ ] Use `cond = is_mail` for all three keymaps
- [ ] Include appropriate icons matching the mail group style

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/editor/which-key.lua` - Add wk.add() block with compose keymaps

**Code to add** (after line 586):
```lua
-- Compose buffer keymaps (visible only when composing email - filetype "mail")
wk.add({
  { "<leader>me", "<cmd>HimalayaSend<CR>", desc = "send email", icon = "󰇮", cond = is_mail },
  { "<leader>md", "<cmd>HimalayaSaveDraft<CR>", desc = "save draft", icon = "󰆓", cond = is_mail },
  { "<leader>mq", "<cmd>HimalayaDiscard<CR>", desc = "quit/discard", icon = "󰚌", cond = is_mail },
})
```

**Verification**:
- [ ] No Lua syntax errors on Neovim startup
- [ ] Keymaps appear in which-key when opening compose buffer

---

### Phase 2: Remove redundant keymaps from config/ui.lua [NOT STARTED]

**Goal**: Clean up the now-redundant keymaps from config/ui.lua

**Tasks**:
- [ ] Remove lines 397-407 from config/ui.lua (the leader keymap definitions and comment)
- [ ] Keep the `<C-d>` and `<C-q>` ctrl-based keymaps (these are separate functionality)

**Timing**: 10 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Remove redundant leader keymaps

**Lines to remove** (approximately 399-407):
```lua
-- DELETE: These lines are now handled by which-key.lua
keymap('n', '<leader>me', '<cmd>HimalayaSend<CR>',
  vim.tbl_extend('force', opts, { desc = 'send email' }))
keymap('n', '<leader>md', '<cmd>HimalayaSaveDraft<CR>',
  vim.tbl_extend('force', opts, { desc = 'save draft' }))
keymap('n', '<leader>mq', '<cmd>HimalayaDiscard<CR>',
  vim.tbl_extend('force', opts, { desc = 'quit/discard' }))

-- Note: <C-s> removed to avoid conflict with spelling operations
-- Use <leader>me to send emails instead
```

**Verification**:
- [ ] No duplicate keymaps warning in Neovim
- [ ] `<C-d>` and `<C-q>` still work in compose buffer

---

### Phase 3: Verification and Testing [NOT STARTED]

**Goal**: Verify keymaps work correctly in compose buffer

**Tasks**:
- [ ] Open Neovim and compose a new email (`:HimalayaCompose` or through himalaya UI)
- [ ] Verify filetype is "mail" with `:lua print(vim.bo.filetype)`
- [ ] Press `<leader>m` and verify `e`, `d`, `q` options appear in which-key popup
- [ ] Test `<leader>me` sends email (or shows send dialog)
- [ ] Test `<leader>md` saves draft
- [ ] Test `<leader>mq` discards/quits

**Timing**: 10 minutes

**Verification**:
- [ ] All three keymaps visible in which-key popup when in compose buffer
- [ ] Keymaps NOT visible in non-mail buffers (e.g., normal .lua files)
- [ ] Keymaps execute correct commands

## Testing and Validation

- [ ] Neovim starts without errors
- [ ] Compose buffer has filetype "mail"
- [ ] `<leader>m` shows e/d/q options only in compose buffer
- [ ] Each keymap executes the expected Himalaya command
- [ ] No duplicate keymap warnings

## Artifacts and Outputs

- Modified: `lua/neotex/plugins/editor/which-key.lua` (added ~6 lines)
- Modified: `lua/neotex/plugins/tools/himalaya/config/ui.lua` (removed ~9 lines)

## Rollback/Contingency

If implementation fails:
1. Revert which-key.lua changes with `git checkout lua/neotex/plugins/editor/which-key.lua`
2. Revert config/ui.lua changes with `git checkout lua/neotex/plugins/tools/himalaya/config/ui.lua`
3. Keymaps will revert to task 69 state (working but not in which-key)
