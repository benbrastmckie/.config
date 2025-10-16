# Resolve `<C-c>` Keybinding Conflict

## Metadata
- **Phase**: Phase 1 - Quick Wins
- **Priority**: High Impact, Low Effort
- **Estimated Time**: 30 minutes
- **Difficulty**: Easy
- **Status**: ✅ Completed
- **Related Report**: [039_nvim_config_improvement_opportunities.md](../../reports/039_nvim_config_improvement_opportunities.md#21-keybinding-conflicts)

## Problem Statement

The `<C-c>` keybinding has conflicting behavior across three contexts:
1. **Global**: Toggles Claude Code terminal
2. **Avante buffers**: Clears suggestion history
3. **Telescope picker**: Closes picker

Additionally, keymaps.lua:78 has **incorrect documentation** claiming `<C-c>` recalculates list numbering in markdown files.

**Impact**:
- Context-dependent behavior creates user confusion
- Documentation mismatch causes errors
- Unpredictable behavior when switching between contexts

## Current State

### Conflict Locations

**keymaps.lua:78** (Global mapping)
```lua
-- INCORRECT COMMENT: <C-c> - Recalculate list numbering in markdown files
-- ACTUAL BEHAVIOR: Toggles Claude Code terminal globally
vim.keymap.set('n', '<C-c>', toggle_claude_code, { desc = 'Toggle Claude Code' })
```

**avante.lua** (Avante-specific)
```lua
-- Uses <C-c> to clear Avante suggestion history in Avante buffers
```

**telescope.lua:27** (Telescope-specific)
```lua
-- Uses <C-c> to close Telescope picker
```

## Desired State

**Option 1: Context-Aware Mapping** (Recommended)
- Implement smart `<C-c>` that detects context and behaves appropriately
- Preserves muscle memory for `<C-c>` usage

**Option 2: Reassign Claude Toggle**
- Move Claude toggle to `<leader>ac` (Ai Claude)
- Frees `<C-c>` for standard Vim behavior (interrupting commands)

## Implementation Tasks

### Task 1: Analyze current keybinding usage

1. Search for all `<C-c>` mappings in codebase
2. Identify where toggle_claude_code is defined
3. Document current behavior in each context

### Task 2: Choose resolution strategy

**If Option 1 (Context-Aware)**:
```lua
vim.keymap.set('n', '<C-c>', function()
  local ft = vim.bo.filetype
  local buftype = vim.bo.buftype

  -- Priority 1: Avante buffers
  if ft == 'avante' then
    require('avante').clear_history()
  -- Priority 2: Telescope prompt
  elseif buftype == 'prompt' then
    require('telescope.actions').close(vim.api.nvim_get_current_buf())
  -- Default: Toggle Claude Code
  else
    require('neotex.plugins.ai.claude').toggle()
  end
end, { desc = 'Context-aware <C-c>' })
```

**If Option 2 (Reassign)**:
```lua
-- Remove global <C-c> mapping
-- Add new Claude toggle mapping
vim.keymap.set('n', '<leader>ac', toggle_claude_code, { desc = 'Toggle Claude Code terminal' })
```

### Task 3: Update documentation

1. Fix incorrect comment in keymaps.lua:78
2. Document the chosen solution
3. Update which-key descriptions if needed

### Task 4: Update Avante and Telescope configs

1. Verify Avante and Telescope configs don't conflict
2. Ensure buffer-local mappings take precedence (if Option 1)
3. Test in each context

## Testing Strategy

### Manual Testing Checklist

1. **Avante Buffer Context**:
   - [ ] Open Avante buffer
   - [ ] Press `<C-c>`
   - [ ] Verify Avante history clears (Option 1) or standard behavior (Option 2)

2. **Telescope Picker Context**:
   - [ ] Open Telescope picker
   - [ ] Press `<C-c>`
   - [ ] Verify picker closes

3. **Normal Buffer Context**:
   - [ ] Open normal buffer
   - [ ] Press `<C-c>` (Option 1) or `<leader>ac` (Option 2)
   - [ ] Verify Claude terminal toggles

4. **Documentation Verification**:
   - [ ] Check which-key shows correct description
   - [ ] Verify no conflicting mappings reported

### Automated Testing
```vim
:verbose map <C-c>
:verbose map <leader>ac
:checkhealth which-key
```

## Success Criteria

- [x] `<C-c>` behavior is consistent and documented
- [x] No conflicting keybinding warnings (buffer-local overrides work correctly)
- [x] Avante buffer: `<C-c>` clears history (buffer-local mapping)
- [x] Telescope picker: `<C-c>` closes picker (action mapping)
- [x] Normal buffer: Claude toggle works via `<C-c>`
- [x] Documentation accurate in keymaps.lua (fixed incorrect comment at line 78)
- [x] Code comments explain context-aware behavior

## Decision: Recommended Approach

**Option 1 (Context-Aware)** is recommended because:
- Preserves muscle memory for all three use cases
- Doesn't require relearning new keybinding
- Leverages Neovim's buffer/filetype detection
- More elegant solution

**Option 2** should be used if:
- Context detection proves unreliable
- User prefers explicit leader-based mapping
- Simpler implementation desired

## Rollback Plan

If issues arise:
1. Revert to original global `<C-c>` mapping
2. Document the conflict clearly
3. Consider alternative keybinding like `<leader>at` (Ai Toggle)

## Notes

- `<C-c>` is traditionally used in Vim to interrupt commands
- Using `<C-c>` for custom actions is non-standard but acceptable if well-documented
- Context-aware approach requires careful testing

## Related Files
- `/home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/avante.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/telescope.lua`
- Claude toggle function (location TBD)
