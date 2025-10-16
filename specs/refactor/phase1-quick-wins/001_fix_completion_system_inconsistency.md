# Fix Completion System Inconsistency

## Metadata
- **Phase**: Phase 1 - Quick Wins
- **Priority**: High Impact, Low Effort
- **Estimated Time**: 15 minutes
- **Difficulty**: Easy
- **Status**: ✅ Completed
- **Related Report**: [039_nvim_config_improvement_opportunities.md](../../reports/039_nvim_config_improvement_opportunities.md#12-deprecatedoutdated-patterns)

## Problem Statement

Two plugins (`lean.nvim` and `mini.nvim`) reference the deprecated `hrsh7th/nvim-cmp` as a dependency, despite the project having migrated to `blink.cmp` for completion.

**Impact**:
- Potential plugin conflicts
- Unnecessary plugin loading
- Confusion about active completion system
- Maintenance burden

## Current State

### lean.nvim (line 69)
```lua
dependencies = {
  'neovim/nvim-lspconfig',
  'nvim-lua/plenary.nvim',
  'hrsh7th/nvim-cmp',  -- ← DEPRECATED: Project uses blink.cmp
},
```

### mini.nvim (line 90)
```lua
dependencies = {
  'nvim-treesitter/nvim-treesitter-textobjects',
  'hrsh7th/nvim-cmp',  -- ← DEPRECATED: Unnecessary reference
  { 'echasnovski/mini.icons' },
},
```

## Desired State

Remove `nvim-cmp` references from both plugin configurations and verify compatibility with `blink.cmp`.

## Implementation Tasks

### Task 1: Remove nvim-cmp from lean.nvim
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/lsp/lean.nvim`

1. Read the file to examine context
2. Remove `'hrsh7th/nvim-cmp'` from dependencies array (line 69)
3. Verify no other references to nvim-cmp in the file
4. Check if lean.nvim requires explicit blink.cmp integration

**Expected Result**:
```lua
dependencies = {
  'neovim/nvim-lspconfig',
  'nvim-lua/plenary.nvim',
  -- nvim-cmp removed
},
```

### Task 2: Remove nvim-cmp from mini.nvim
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/mini.nvim`

1. Read the file to examine context
2. Remove `'hrsh7th/nvim-cmp'` from dependencies array (line 90)
3. Verify no other references to nvim-cmp in the file

**Expected Result**:
```lua
dependencies = {
  'nvim-treesitter/nvim-treesitter-textobjects',
  -- nvim-cmp removed
  { 'echasnovski/mini.icons' },
},
```

### Task 3: Verify blink.cmp compatibility

1. Search for blink.cmp configuration
2. Verify lean.nvim and mini.nvim work with blink.cmp
3. Test completion functionality after changes

## Testing Strategy

### Manual Testing
1. Restart Neovim after changes
2. Open Lean file (if available) and test completion
3. Test mini.nvim text objects and features
4. Verify no nvim-cmp errors in `:messages`

### Verification Commands
```vim
:Lazy load lean.nvim
:Lazy load mini.nvim
:checkhealth blink.cmp
:messages
```

## Success Criteria

- [x] `nvim-cmp` removed from lean.lua dependencies
- [x] `nvim-cmp` removed from mini.lua dependencies
- [x] `nvim-cmp` removed from avante.lua dependencies (bonus fix)
- [x] No hard dependencies on nvim-cmp remain
- [ ] No nvim-cmp loading errors on startup (to be verified on restart)
- [ ] Completion works with blink.cmp (to be verified on restart)
- [ ] No plugin conflicts reported (to be verified on restart)

## Rollback Plan

If issues arise:
1. Git revert the changes
2. Investigate blink.cmp compatibility issues
3. Consider keeping nvim-cmp temporarily if critical dependency

## Notes

- Both plugins likely don't actually require nvim-cmp
- lean.nvim may have nvim-cmp integration but should work without it
- mini.nvim is modular and doesn't require any specific completion framework
- This is a safe change with minimal risk

## Related Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/lsp/lean.nvim`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/mini.nvim`
- Blink.cmp configuration (location TBD during task execution)
