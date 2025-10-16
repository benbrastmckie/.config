# Implement Missing Keybindings

## Metadata
- **Phase**: Phase 2 - Medium Priority
- **Priority**: Medium Impact, Low Effort
- **Estimated Time**: 10 minutes
- **Difficulty**: Easy
- **Status**: ✅ Completed
- **Related Report**: [039_nvim_config_improvement_opportunities.md](../../reports/039_nvim_config_improvement_opportunities.md#23-missing-essential-keybindings)

## Problem Statement

Essential quickfix and location list navigation keybindings are missing.

**Current limitation**:
- Only `<leader>fq` exists to open quickfix list
- No shortcuts for navigating between items
- Must use verbose commands like `:cnext`, `:cprev`, `:cfirst`, `:clast`

**Impact**:
- Reduced productivity when working with search results, compiler errors, or grep matches
- Inconsistent with existing navigation patterns (like `[d`/`]d` for diagnostics)

## Current State

### Existing Keybindings
- `<leader>fq` - Open quickfix list (Telescope)
- `[d` / `]d` - Diagnostic navigation (established pattern)

### Missing Keybindings

**Quickfix Navigation**:
- **Missing**: `[q` / `]q` (prev/next quickfix item)
- **Missing**: `[Q` / `]Q` (first/last quickfix item)
- **Missing**: `[l` / `]l` (prev/next location list item)
- **Missing**: `[L` / `]L` (first/last location list item)

**Current workarounds**:
- `:cnext`, `:cprev`, `:cfirst`, `:clast` for quickfix
- `:lnext`, `:lprev`, `:lfirst`, `:llast` for location list

## Desired State

Add quickfix and location list navigation keybindings following the established `[`/`]` bracket navigation pattern (consistent with `[d`/`]d` for diagnostics).

## Implementation Tasks

### Task 1: Add Quickfix Navigation Keybindings

**File**: `/home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua`

**Add following `[d`/`]d` diagnostic pattern**:
```lua
-- Quickfix navigation
vim.keymap.set('n', ']q', '<cmd>cnext<cr>zz', { desc = 'Next quickfix item' })
vim.keymap.set('n', '[q', '<cmd>cprev<cr>zz', { desc = 'Previous quickfix item' })
vim.keymap.set('n', ']Q', '<cmd>clast<cr>zz', { desc = 'Last quickfix item' })
vim.keymap.set('n', '[Q', '<cmd>cfirst<cr>zz', { desc = 'First quickfix item' })

-- Location list navigation (bonus)
vim.keymap.set('n', ']l', '<cmd>lnext<cr>zz', { desc = 'Next location list item' })
vim.keymap.set('n', '[l', '<cmd>lprev<cr>zz', { desc = 'Previous location list item' })
vim.keymap.set('n', ']L', '<cmd>llast<cr>zz', { desc = 'Last location list item' })
vim.keymap.set('n', '[L', '<cmd>lfirst<cr>zz', { desc = 'First location list item' })
```

**Note**: `zz` centers the cursor after navigation for better visibility.

### Task 2: Document New Keybindings

1. Add comments in keymaps.lua grouping quickfix/location list navigation together
2. Ensure which-key descriptions are clear and consistent
3. Place near existing `[d`/`]d` diagnostic navigation for logical grouping

## Testing Strategy

### Manual Testing Checklist

**Quickfix Navigation**:
1. **Populate quickfix list**:
   - [ ] Run `:grep "test" **/*.lua` or `:make`
   - [ ] Open quickfix list with `<leader>fq`

2. **Test quickfix navigation**:
   - [ ] Press `]q` to go to next item (cursor centers with `zz`)
   - [ ] Press `[q` to go to previous item
   - [ ] Press `]Q` to jump to last item
   - [ ] Press `[Q` to jump to first item
   - [ ] Verify each navigation works and centers screen

**Location List Navigation**:
1. **Populate location list**:
   - [ ] Run `:lvimgrep /test/ **/*.lua`
   - [ ] Verify location list has entries with `:lopen`

2. **Test location list navigation**:
   - [ ] Press `]l` to go to next item
   - [ ] Press `[l` to go to previous item
   - [ ] Press `]L` to jump to last item
   - [ ] Press `[L` to jump to first item
   - [ ] Verify location list is buffer-local (different per buffer)

### which-key Verification
```vim
:WhichKey <leader>
:WhichKey [
:WhichKey ]
```

- Verify new keybindings appear with correct descriptions
- Check grouping is logical and consistent

## Success Criteria

- [x] `]q` / `[q` navigate quickfix list with centered cursor
- [x] `]Q` / `[Q` jump to first/last quickfix item
- [x] `]l` / `[l` navigate location list with centered cursor
- [x] `]L` / `[L` jump to first/last location list item
- [ ] All keybindings show in which-key with correct descriptions (not yet tested)
- [x] No conflicts with existing keybindings (Neovim defaults exist but we override with zz centering)
- [x] Keybindings follow established `[`/`]` navigation pattern

## Keybinding Conflicts Check

**Before implementation, verify no conflicts**:
```vim
:verbose map ]q
:verbose map [q
:verbose map ]Q
:verbose map [Q
:verbose map ]l
:verbose map [l
:verbose map ]L
:verbose map [L
```

If conflicts exist, document and resolve before proceeding.

## Rollback Plan

If issues arise:
1. Remove the added keybindings
2. Git revert the keymaps.lua changes
3. No data loss risk (keybindings are non-destructive)

## Notes

- **`zz` centering**: Common pattern in Neovim for navigation commands, improves visibility
- **Location list vs Quickfix**:
  - Quickfix: Global list (`:grep`, `:make`, `:vimgrep`)
  - Location list: Buffer-local list (`:lvimgrep`, `:lgrep`)
- **Pattern consistency**: Using `[`/`]` matches existing diagnostic navigation (`[d`/`]d`)

## Related Files
- `/home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua`
- which-key configuration file (if separate from keymaps.lua)

## References
- Report Section: [2.3 Missing Essential Keybindings](../../reports/039_nvim_config_improvement_opportunities.md#23-missing-essential-keybindings)
- Existing keybinding patterns: `[d`/`]d` for diagnostics, `<leader>bd` for buffer delete
