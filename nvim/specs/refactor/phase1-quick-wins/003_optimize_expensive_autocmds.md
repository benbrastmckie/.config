# Optimize Expensive Autocmds

## Metadata
- **Phase**: Phase 1 - Quick Wins
- **Priority**: High Impact, Low Effort
- **Estimated Time**: 20 minutes
- **Difficulty**: Easy
- **Status**: ✅ Completed
- **Related Report**: [039_nvim_config_improvement_opportunities.md](../../reports/039_nvim_config_improvement_opportunities.md#32-expensive-startup-operations)

## Problem Statement

The file reload autocmd (lines 108-116 in autocmds.lua) fires on `CursorHold` and `CursorHoldI` events, causing it to execute on **every cursor movement pause**. This creates excessive I/O operations and 5-10ms lag per cursor pause.

**Impact**:
- 5-10ms delay per cursor pause
- Excessive file system checks
- Degraded editing experience
- Unnecessary battery drain on laptops

## Current State

### autocmds.lua:108-116 (Expensive Pattern)
```lua
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  callback = function()
    -- File reload check logic
    -- Executes on EVERY cursor pause (CursorHold events)
  end,
})
```

**Events Breakdown**:
- `FocusGained`: Window gains focus ✓ (appropriate)
- `BufEnter`: Enter buffer ✓ (appropriate)
- `CursorHold`: Cursor hasn't moved for `updatetime` ms ✗ (too frequent)
- `CursorHoldI`: Same as CursorHold but in insert mode ✗ (too frequent)

## Desired State

Remove cursor-based events and rely only on focus/buffer entry events for file reload checks.

```lua
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  pattern = "*",
  callback = function()
    -- File reload check logic (same as before)
  end,
})
```

## Implementation Tasks

### Task 1: Remove CursorHold events from file reload autocmd

**File**: `/home/benjamin/.config/nvim/lua/neotex/config/autocmds.lua`

1. Read autocmds.lua to locate the file reload autocmd (lines 108-116)
2. Remove `CursorHold` and `CursorHoldI` from the event list
3. Keep `FocusGained` and `BufEnter` events
4. Verify no other logic depends on cursor events

**Expected Change**:
```lua
-- BEFORE
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {

-- AFTER
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
```

### Task 2: Review terminal setup autocmds (lines 36-80)

**Issue**: Multiple `vim.defer_fn` delays with different timings create unpredictable initialization.

1. Read lines 36-80 in autocmds.lua
2. Identify all `vim.defer_fn` calls
3. Consolidate to single deferred initialization if possible
4. Document timing rationale

**Potential Optimization**:
```lua
-- BEFORE (multiple defer_fn with 50ms, 100ms, 1000ms delays)
vim.defer_fn(function() ... end, 50)
vim.defer_fn(function() ... end, 100)
vim.defer_fn(function() ... end, 1000)

-- AFTER (single consolidated init)
vim.defer_fn(function()
  -- Initialize all terminal setup in sequence
  setup_terminal_options()
  setup_terminal_keymaps()
  setup_terminal_autocommands()
end, 100)  -- Single sensible delay
```

### Task 3: Verify no regressions

1. Test file reload on focus change
2. Test file reload on buffer switch
3. Verify terminal setup still works
4. Check for any timing-dependent bugs

## Testing Strategy

### Performance Testing

**Before Changes**:
```vim
:lua vim.cmd('profile start profile.log')
:lua vim.cmd('profile func *')
:lua vim.cmd('profile file *')
" Move cursor and pause several times
:lua vim.cmd('profile pause')
:lua vim.cmd('profile dump')
```

**After Changes**:
- Repeat profile and compare results
- Expect significantly fewer autocmd fires

### Manual Testing Checklist

1. **File Reload Testing**:
   - [ ] Edit file externally (e.g., `echo "test" >> file.txt`)
   - [ ] Switch back to Neovim (FocusGained)
   - [ ] Verify file reloads automatically
   - [ ] Switch between buffers (BufEnter)
   - [ ] Verify no reload errors

2. **Cursor Movement Testing**:
   - [ ] Move cursor and pause (no autocmd should fire now)
   - [ ] Verify no lag during cursor pauses
   - [ ] Check `:messages` for errors

3. **Terminal Testing**:
   - [ ] Open terminal
   - [ ] Verify terminal options set correctly
   - [ ] Test terminal keymaps work
   - [ ] No initialization errors

### Automated Verification
```vim
:autocmd CursorHold  " Should not show file reload autocmd
:autocmd CursorHoldI " Should not show file reload autocmd
:autocmd FocusGained " Should show file reload autocmd
:autocmd BufEnter    " Should show file reload autocmd
```

## Success Criteria

- [ ] `CursorHold` and `CursorHoldI` removed from file reload autocmd
- [ ] File reload still works on `FocusGained` and `BufEnter`
- [ ] No cursor movement lag
- [ ] Terminal setup autocmds consolidated (if feasible)
- [ ] No timing-related bugs introduced
- [ ] Smoother editing experience

## Performance Impact

**Expected Improvements**:
- **Cursor movement lag**: Reduce from 5-10ms to 0ms
- **Autocmd fires**: Reduce from ~100/min to ~2/min (focus/buffer only)
- **I/O operations**: 98% reduction in file stat calls
- **Battery life**: Measurable improvement on laptops

## Rollback Plan

If issues arise:
1. Revert to original autocmd event list
2. Investigate why FocusGained/BufEnter insufficient
3. Consider alternative events like `BufWritePost` for specific use cases

## Notes

- `CursorHold` fires after `updatetime` milliseconds of inactivity (default 4000ms)
- Removing these events is safe for file reload checks
- External file changes are better detected via `FocusGained` (when returning to Neovim)
- Buffer switches (`BufEnter`) catch file changes when navigating within Neovim

## Related Files
- `/home/benjamin/.config/nvim/lua/neotex/config/autocmds.lua`
- File reload callback function (within autocmds.lua)
- Terminal setup functions (within autocmds.lua)

## References
- Report Section: [3.2 Expensive Startup Operations](../../reports/039_nvim_config_improvement_opportunities.md#32-expensive-startup-operations)
- Performance target: 10-20ms startup time savings
