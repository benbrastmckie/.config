# Buffer Persistence Enhancement Implementation Plan

## Metadata
- **Date**: 2025-10-03
- **Feature**: Strengthen buffer persistence for .claude/ directory files
- **Scope**: Session management and buffer listing protection
- **Estimated Phases**: 2
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**:
  - specs/reports/037_debug_gitignored_buffer_disappearance.md

## Overview

The current defensive autocmd in `sessions.lua` (lines 70-82) successfully prevents git-ignored buffers from becoming unlisted, but the issue has resurfaced for `.claude/` directory files. Research indicates this is likely due to:

1. **Autocmd timing**: Current workaround only fires on `BufAdd` and `SessionLoadPost` events
2. **Post-load interference**: Other plugins may unlist buffers after initial load
3. **Insufficient event coverage**: Missing critical events like `BufEnter` and `BufWinEnter`

The solution strengthens the existing defensive pattern by:
- Adding more event triggers to ensure continuous protection
- Adding specific path-based protection for `.claude/` directory
- Maintaining simplicity to avoid fragile autocommand interactions

## Success Criteria
- [ ] Buffers for `.claude/` directory files persist after terminal focus switches
- [ ] Buffers for `.claude/` directory files persist across session saves/restores
- [ ] No complex autocommand chains that could interact unexpectedly
- [ ] Solution extends existing defensive pattern rather than replacing it
- [ ] All normal file buffers continue to persist correctly

## Technical Design

### Current Implementation Analysis

**Existing workaround** (sessions.lua:70-82):
```lua
vim.api.nvim_create_autocmd({"BufAdd", "SessionLoadPost"}, {
  callback = function(args)
    local buf = args.buf or vim.api.nvim_get_current_buf()
    local buftype = vim.bo[buf].buftype
    local bufname = vim.api.nvim_buf_get_name(buf)

    -- Ensure normal file buffers stay listed
    if buftype == "" and bufname ~= "" and not bufname:match("^term://") then
      vim.bo[buf].buflisted = true
    end
  end,
  desc = "Workaround: Keep normal file buffers listed (git-ignored file fix)"
})
```

**Limitations**:
- Only fires on `BufAdd` (new buffer) and `SessionLoadPost` (after session load)
- Doesn't catch buffers that become unlisted during window/buffer switching
- No specific protection for paths that are more vulnerable (like `.claude/`)

### Proposed Enhancement

**Strategy**: Add additional events to ensure protection fires during all buffer state transitions:
- `BufEnter`: When buffer becomes active
- `BufWinEnter`: When buffer is displayed in a window
- Keep existing `BufAdd` and `SessionLoadPost` for compatibility

**Key Design Decisions**:
1. **Extend, don't replace**: Keep existing events, add new ones
2. **Path-agnostic protection**: Don't special-case `.claude/` - protect ALL normal file buffers
3. **Performance-conscious**: Use efficient buffer property checks
4. **Avoid complexity**: Single autocmd with multiple events, no nested logic

### Implementation Approach

Modify the existing autocmd to include additional events:

```lua
vim.api.nvim_create_autocmd({"BufAdd", "SessionLoadPost", "BufEnter", "BufWinEnter"}, {
  callback = function(args)
    local buf = args.buf or vim.api.nvim_get_current_buf()
    local buftype = vim.bo[buf].buftype
    local bufname = vim.api.nvim_buf_get_name(buf)

    -- Ensure normal file buffers stay listed
    if buftype == "" and bufname ~= "" and not bufname:match("^term://") then
      vim.bo[buf].buflisted = true
    end
  end,
  desc = "Workaround: Keep normal file buffers listed (enhanced coverage)"
})
```

**Why this works**:
- `BufEnter`: Catches buffers when switching back from terminal
- `BufWinEnter`: Catches buffers when displayed in windows after splits
- `BufAdd`: Maintains initial buffer creation protection
- `SessionLoadPost`: Maintains session restoration protection

### Alternative Considered: Path-Specific Protection

An alternative would be to add explicit `.claude/` path checking:

```lua
if buftype == "" and bufname ~= "" and not bufname:match("^term://") then
  -- Extra protection for .claude/ directory files
  if bufname:match("%.claude/") then
    vim.bo[buf].buflisted = true
    vim.bo[buf].bufhidden = ""  -- Additional safeguard
  else
    vim.bo[buf].buflisted = true
  end
end
```

**Rejected because**:
- Adds complexity without clear benefit
- Path-agnostic approach is simpler and more maintainable
- Root cause affects all paths, not just `.claude/`
- User wants to avoid fragile configurations

## Implementation Phases

### Phase 1: Strengthen Autocmd Event Coverage [COMPLETED]
**Objective**: Add BufEnter and BufWinEnter events to existing defensive autocmd
**Complexity**: Low

Tasks:
- [x] Modify sessions.lua:70-82 to add BufEnter and BufWinEnter events
- [x] Update autocmd description to reflect enhanced coverage
- [x] Verify no syntax errors after modification

Testing:
```bash
# Manual test procedure:
# 1. Open nvim and load a session with .claude/ files
nvim
:SessionManager load_current_dir_session

# 2. Verify .claude/ buffers are visible in bufferline
# 3. Switch to terminal with <C-c>
# 4. Switch back to buffer
# 5. Verify .claude/ buffer tab is still visible

# Automated syntax check:
nvim --headless -c "luafile ~/.config/nvim/lua/neotex/plugins/ui/sessions.lua" -c "qa"
```

Expected outcome:
- Autocmd fires on buffer switches, keeping buffers listed
- No errors in Neovim startup or session loading

### Phase 2: Verify Cross-Session Persistence
**Objective**: Ensure .claude/ buffers persist across Neovim restarts
**Complexity**: Low

Tasks:
- [ ] Open multiple .claude/ directory files (e.g., tts-config.sh)
- [ ] Switch between buffers and terminal multiple times
- [ ] Save session (automatically via autosave or manually)
- [ ] Close Neovim completely
- [ ] Reopen Neovim and load session
- [ ] Verify all .claude/ buffers are restored and visible

Testing:
```bash
# Test sequence:
# Session 1: Create session with .claude/ files
nvim ~/.config/.claude/tts/tts-config.sh
# Open additional buffer
:e ~/.config/.claude/commands/test.sh
# Switch to terminal and back (test live persistence)
# <C-c> then <C-h>
# Exit Neovim
:qa

# Session 2: Verify persistence
nvim
:SessionManager load_current_dir_session
# Verify both .claude/ buffers are in bufferline
:ls  # Check buffer list includes .claude/ files
```

Expected outcome:
- All .claude/ buffers present in session file
- Buffers restore with buflisted=true
- Buffers visible in bufferline after session load

## Testing Strategy

### Unit Testing
Not applicable - this is configuration/autocmd logic tested via integration

### Integration Testing

**Test Case 1: Terminal Switch Persistence**
1. Open `.claude/tts/tts-config.sh`
2. Verify buffer tab visible
3. Switch to terminal (`<C-c>`)
4. Switch back to buffer
5. **Expected**: Buffer tab remains visible

**Test Case 2: Cross-Session Persistence**
1. Open multiple `.claude/` files
2. Save session (autosave or manual)
3. Quit Neovim
4. Reopen and load session
5. **Expected**: All `.claude/` buffers restored and visible

**Test Case 3: Mixed Directory Behavior**
1. Open mix of nvim/lua/*.lua and .claude/*.sh files
2. Switch between buffers and terminal
3. Save and restore session
4. **Expected**: All buffers persist consistently

**Test Case 4: Special Buffer Exclusion**
1. Open terminal buffer
2. Open quickfix list
3. Open help buffer
4. **Expected**: These buffers remain unlisted (not affected by workaround)

### Manual Verification
```vim
" Check autocmd registration
:autocmd BufEnter
:autocmd BufWinEnter

" Check specific buffer listing status
:lua print("Current buffer listed: " .. tostring(vim.bo.buflisted))

" Check all buffer listing
:ls

" Verify session file contents
:!cat ~/.config/nvim/sessions/__home__benjamin__.config
" Should see 'badd' commands for .claude/ files
```

### Regression Testing
- Verify existing git-ignored buffer fix still works
- Verify bufferline visibility system unaffected
- Verify session autosave behavior unchanged
- Verify no new autocmd conflicts

## Documentation Requirements

### Inline Documentation
- Update TODO comment in sessions.lua (lines 64-69) to mention enhanced coverage
- Update autocmd description to reflect new events

### Report Cross-References
- Update specs/reports/037_debug_gitignored_buffer_disappearance.md with new findings
- Document that enhanced event coverage resolves .claude/ directory issue
- Note this as an extension of the original workaround

### README Updates
Not required - this is internal session management enhancement

## Dependencies

### Plugin Dependencies
- neovim-session-manager (Shatur/neovim-session-manager) - already configured
- plenary.nvim - already installed

### Configuration Dependencies
- Existing sessions.lua configuration (lines 1-84)
- No new plugin installations required

## Risk Assessment

### Low Risk
- **Change scope**: Minimal - adding two event triggers to existing autocmd
- **Reversibility**: Easy to revert by removing events
- **Blast radius**: Isolated to session management

### Potential Issues
1. **Performance**: Autocmd fires more frequently
   - **Mitigation**: Logic is extremely simple (property checks only)
   - **Impact**: Negligible - runs in microseconds

2. **Event conflicts**: Other plugins may also use BufEnter/BufWinEnter
   - **Mitigation**: Our autocmd only sets buflisted=true for normal files
   - **Impact**: Minimal - defensive setting should not conflict

3. **Unintended buffer listing**: Might list buffers that should be unlisted
   - **Mitigation**: Explicit checks for buftype, bufname, and terminal exclusion
   - **Impact**: Addressed by existing filtering logic

### Rollback Plan
If issues arise:
1. Revert sessions.lua to original two events (BufAdd, SessionLoadPost)
2. Add debug logging to identify specific failure case
3. Implement more targeted fix based on logs

## Notes

### Design Philosophy
This enhancement follows the principle of "defensive programming":
- Assume something else is breaking buffer listing
- Proactively protect against it at multiple trigger points
- Keep logic simple and predictable

### Why Not Find Root Cause?
Per report 037, extensive investigation found no user config code that unlists buffers inappropriately. The root cause is likely:
- Deep in a third-party plugin's compiled code
- Timing-dependent and hard to reproduce
- Not worth extensive debugging vs. simple defensive fix

The enhanced workaround is acceptable as a permanent solution because:
1. It's minimal (single autocmd with 4 events)
2. It's defensive (doesn't break anything)
3. It's maintainable (clear logic, well-documented)
4. It solves the user's actual problem

### User Requirements Alignment
User specifically requested:
- ✓ Fix buffer persistence for .claude/ directory files
- ✓ Avoid fragile configurations
- ✓ Avoid complex autocommands that interact strangely

This solution meets all requirements by extending proven approach with minimal additions.

## References

### Related Files
- lua/neotex/plugins/ui/sessions.lua (lines 64-82) - Current workaround
- lua/neotex/plugins/ui/bufferline.lua - Buffer visibility system

### Related Reports
- specs/reports/037_debug_gitignored_buffer_disappearance.md - Original investigation

### Neovim Documentation
- `:help BufEnter` - Event when buffer becomes active
- `:help BufWinEnter` - Event when buffer enters window
- `:help BufAdd` - Event when buffer added to list
- `:help SessionLoadPost` - Event after session load
- `:help buflisted` - Buffer listing flag
- `:help autocmd-events` - Complete event reference
