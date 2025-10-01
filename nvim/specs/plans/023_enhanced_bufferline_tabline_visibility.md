# Enhanced Bufferline Tabline Visibility Implementation Plan

## Metadata
- **Date**: 2025-10-01
- **Feature**: Enhanced showtabline Event Handling (Robust Fix)
- **Scope**: Fix bufferline tab visibility when switching between normal buffers, terminals, and sidebars
- **Estimated Phases**: 3
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**:
  - /home/benjamin/.config/nvim/specs/reports/023_bufferline_tab_visibility_issues.md

## Overview

This plan implements Solution 2 from the research report: Enhanced showtabline Event Handling. The solution adds comprehensive autocmd-based event handling to preserve bufferline visibility when switching between normal file buffers and unlisted buffers (terminals, sidebars).

### Problem Statement
Currently, bufferline tabs disappear when:
- Switching to Claude Code terminal (<C-c>)
- Opening Neo-tree sidebar
- Entering any unlisted buffer context
- Sometimes when opening git-ignored files

The tabs only reappear when returning focus to a normal file buffer.

### Root Cause
1. Only `BufAdd` event triggers tabline visibility checks
2. Missing `BufEnter`/`WinEnter` handlers to preserve visibility during navigation
3. `always_show_bufferline = false` hides tabs when current window has unlisted buffer
4. No special handling for alpha dashboard vs terminal/sidebar contexts

### Solution Approach
Add comprehensive event handlers that:
- Monitor `BufEnter` and `WinEnter` events to maintain tabline visibility
- Use `TermLeave` to restore visibility when exiting terminals
- Implement smart context detection (alpha dashboard vs terminal/sidebar)
- Centralize visibility logic in a reusable function

## Success Criteria
- [ ] Bufferline remains visible when switching to Claude Code terminal
- [ ] Bufferline remains visible when opening Neo-tree sidebar
- [ ] Bufferline remains visible for git-ignored files
- [ ] Bufferline still hides on alpha dashboard
- [ ] Bufferline still hides with only one buffer in session
- [ ] No performance degradation from frequent autocmd triggers
- [ ] All existing bufferline functionality preserved

## Technical Design

### Architecture Decisions

**Decision 1: In-place enhancement vs separate module**
- **Choice**: Enhance existing bufferline.lua configuration in-place
- **Rationale**:
  - Single file keeps related logic together
  - Avoid premature abstraction (YAGNI principle)
  - Easier to maintain visibility logic alongside bufferline setup
- **Trade-off**: Bufferline.lua will grow, but module extraction can be done later if needed

**Decision 2: Event handler strategy**
- **Choice**: Use multiple specific autocmds rather than catch-all handlers
- **Events**: `BufEnter`, `WinEnter`, `TermLeave`, `BufDelete`
- **Rationale**:
  - Precise control over when visibility checks occur
  - Better performance (targeted events vs polling)
  - Clear separation of concerns

**Decision 3: Visibility logic centralization**
- **Choice**: Create `ensure_tabline_visible()` local function
- **Rationale**:
  - DRY principle - reused across multiple autocmds
  - Single source of truth for visibility rules
  - Easier to test and debug

**Decision 4: Alpha dashboard handling**
- **Choice**: Early return in event handlers for alpha filetype
- **Rationale**:
  - Preserves existing clean dashboard appearance
  - Avoids conflict with existing Alpha autocmds
  - Minimal change to existing behavior

### Component Interactions

```
┌─────────────────────────────────────────────────────────────┐
│                    Neovim Event System                      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Events: BufEnter, WinEnter, TermLeave
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Enhanced Event Handlers (NEW)                  │
│                                                             │
│  ┌──────────────────────────────────────────┐              │
│  │  ensure_tabline_visible()                │              │
│  │  - Count listed buffers                  │              │
│  │  - Set showtabline = 0 or 2              │              │
│  │  - Respect alpha dashboard context       │              │
│  └──────────────────────────────────────────┘              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Sets vim.opt.showtabline
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Bufferline Plugin (Existing)                   │
│  - Renders tabs based on showtabline setting               │
│  - Filters unlisted buffers via custom_filter              │
│  - always_show_bufferline = false (unchanged)              │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

**Scenario: User switches to Claude terminal**

```
1. User in file buffer (showtabline = 2, tabs visible)
   ↓
2. User presses <C-c>
   ↓
3. BufLeave(file) → WinEnter(terminal) → BufEnter(terminal)
   ↓
4. NEW: BufEnter autocmd fires
   - Checks: filetype != "alpha" ✓
   - Calls: ensure_tabline_visible()
   - Counts: 2 listed buffers (file still exists)
   - Sets: showtabline = 2
   ↓
5. Bufferline plugin renders tabs
   ↓
6. RESULT: Tabs remain visible ✓
```

**Scenario: User closes to single buffer**

```
1. User has 2 buffers open (showtabline = 2)
   ↓
2. User runs :bdelete
   ↓
3. BufDelete event fires
   ↓
4. NEW: BufDelete autocmd fires
   - Calls: ensure_tabline_visible()
   - Counts: 1 listed buffer remaining
   - Sets: showtabline = 0
   ↓
5. RESULT: Tabs hide ✓
```

### API Design

**New Function: ensure_tabline_visible()**

```lua
local function ensure_tabline_visible()
  local buffers = vim.fn.getbufinfo({buflisted = 1})
  if #buffers > 1 then
    vim.opt.showtabline = 2
  elseif #buffers <= 1 then
    vim.opt.showtabline = 0
  end
end
```

**Properties**:
- **Pure function**: No side effects beyond showtabline
- **Idempotent**: Safe to call multiple times
- **Fast**: Simple buffer count check
- **Stateless**: No global state dependencies

## Implementation Phases

### Phase 1: Create Visibility Management Function [COMPLETED]
**Objective**: Add centralized visibility logic function
**Complexity**: Low

Tasks:
- [x] Add `ensure_tabline_visible()` local function after line 126 in bufferline.lua
- [x] Implement buffer counting logic using `vim.fn.getbufinfo({buflisted = 1})`
- [x] Add conditional showtabline setting (0 for <=1 buffers, 2 for >1)
- [x] Add inline documentation explaining visibility rules

Testing:
```lua
-- Manual test in Neovim command line
:lua local buffers = vim.fn.getbufinfo({buflisted = 1}); vim.print(#buffers)
:set showtabline?
```

Expected outcome:
- Function defined and callable
- No syntax errors
- Ready for autocmd integration

Files modified:
- /home/benjamin/.config/nvim/lua/neotex/plugins/ui/bufferline.lua

### Phase 2: Add Enhanced Event Handlers [COMPLETED]
**Objective**: Implement autocmds for buffer/window navigation events
**Complexity**: Medium

Tasks:
- [x] Add BufEnter autocmd that calls ensure_tabline_visible()
- [x] Add WinEnter autocmd that calls ensure_tabline_visible()
- [x] Add alpha dashboard check (early return if filetype == "alpha")
- [x] Add TermLeave autocmd with deferred visibility check
- [x] Add BufDelete autocmd to handle buffer cleanup
- [x] Add descriptive `desc` fields to all autocmds
- [x] Ensure autocmds created in vim.defer_fn context (after line 126)

Implementation location:
- Insert after line 126 in bufferline.lua
- Inside the existing `vim.defer_fn(function() ... end, 200)` block
- After the Alpha integration autocmds (lines 111-125)

Testing:
```bash
# In Neovim, check autocmds were created
:autocmd BufEnter
:autocmd WinEnter
:autocmd TermLeave
:autocmd BufDelete
```

Expected outcome:
- All autocmds registered successfully
- Descriptive help text visible in :autocmd output
- No duplicate autocmd registrations

Files modified:
- /home/benjamin/.config/nvim/lua/neotex/plugins/ui/bufferline.lua

### Phase 3: Testing and Validation
**Objective**: Verify all test cases from research report
**Complexity**: Medium

Tasks:
- [ ] Test 1: Single buffer startup (expect no tabline)
- [ ] Test 2: Multiple buffer startup (expect tabline visible)
- [ ] Test 3: Terminal switch with <C-c> (expect tabs persist)
- [ ] Test 4: Neo-tree toggle (expect tabs persist)
- [ ] Test 5: Git-ignored file (expect tab visible)
- [ ] Test 6: Alpha dashboard (expect no tabline)
- [ ] Test 7: Buffer close to single (expect tabline hides)
- [ ] Performance test: Monitor autocmd frequency with :profile

Testing approach:
```bash
# Start fresh Neovim session
nvim test1.lua test2.lua

# Verify tabline visible
:set showtabline?  # Should be 2

# Switch to Claude terminal
<C-c>
# Verify tabs still visible

# Return to buffer
<C-c>
# Verify tabs still visible

# Close one buffer
:bdelete
# Verify tabs hide

# Test alpha dashboard
:Alpha
# Verify no tabline
```

Validation criteria:
- All 7 test cases pass
- No visual regressions
- No error messages in :messages
- Smooth transitions (no flickering)

Files modified:
- None (testing only)

## Testing Strategy

### Unit Testing
- **Function testing**: Manually invoke `ensure_tabline_visible()` in various buffer states
- **Autocmd verification**: Use `:autocmd` to verify handlers registered
- **Buffer count accuracy**: Verify `getbufinfo({buflisted = 1})` returns expected counts

### Integration Testing
- **End-to-end workflows**: Test complete user journeys (file → terminal → file)
- **Cross-component**: Verify interaction with Claude Code, Neo-tree, Alpha plugins
- **Edge cases**: Empty sessions, many buffers, rapid switching

### Performance Testing
- **Autocmd frequency**: Profile event firing frequency
- **Visibility function cost**: Time `ensure_tabline_visible()` execution
- **User-perceived lag**: Verify no noticeable delays

### Regression Testing
- **Existing behavior**: Confirm all original bufferline features still work
- **Alpha dashboard**: Verify clean dashboard appearance preserved
- **Single buffer UX**: Confirm tabline still hides with one buffer

## Debugging Strategy

### Diagnostic Commands
```vim
" Check showtabline value
:set showtabline?

" List buffers with listing status
:lua vim.print(vim.fn.getbufinfo())

" Check autocmd registration
:autocmd BufEnter
:autocmd WinEnter

" Force visibility check
:lua ensure_tabline_visible()  -- Will fail - function is local

" Alternative: reload config
:source %
```

### Logging Strategy
If issues arise, add temporary debugging:

```lua
local function ensure_tabline_visible()
  local buffers = vim.fn.getbufinfo({buflisted = 1})
  -- DEBUG: Uncomment to diagnose
  -- vim.notify(string.format("Buffers: %d, Setting showtabline to %d", #buffers, #buffers > 1 and 2 or 0))

  if #buffers > 1 then
    vim.opt.showtabline = 2
  elseif #buffers <= 1 then
    vim.opt.showtabline = 0
  end
end
```

### Common Issues and Solutions

**Issue**: Tabs flicker when switching
- **Diagnosis**: Multiple autocmds firing rapidly
- **Solution**: Add debouncing with `vim.defer_fn()`

**Issue**: Tabs don't hide with single buffer
- **Diagnosis**: Buffer count logic incorrect
- **Solution**: Check `buflisted` flag on buffers

**Issue**: Performance degradation
- **Diagnosis**: Autocmds firing too frequently
- **Solution**: Profile and optimize event selection

## Documentation Requirements

### Inline Documentation
- [ ] Add function docstring for `ensure_tabline_visible()`
- [ ] Add comments explaining autocmd purpose
- [ ] Document alpha dashboard special handling

### Configuration Comments
- [ ] Update bufferline.lua header comments to mention enhanced visibility
- [ ] Add reference to research report in comments

### No External Documentation Required
- Feature is transparent to users
- No new commands or keybindings
- Existing bufferline behavior simply improved

## Dependencies

### Plugin Dependencies
- **akinsho/bufferline.nvim**: Core plugin (already installed)
- **goolord/alpha-nvim**: Dashboard integration (already configured)
- **greggh/claude-code.nvim**: Terminal integration (already configured)
- **nvim-neo-tree/neo-tree.nvim**: Sidebar integration (already configured)

### Neovim Version Requirements
- **Minimum**: 0.8+ (for `vim.api.nvim_create_autocmd` API)
- **Current config**: Targeting modern Neovim (0.9+)

### No External Dependencies
- Pure Lua implementation
- Uses only Neovim stdlib APIs
- No shell commands or external tools

## Rollback Plan

### If Implementation Fails
1. **Simple rollback**: Remove added code (lines 127+)
2. **Fallback solution**: Implement Solution 1 (set `always_show_bufferline = true`)
3. **Restore original**: Git revert to pre-implementation commit

### Fallback Code (Solution 1)
```lua
-- Minimal fallback if Solution 2 causes issues
-- Change line 28 in bufferline.lua
always_show_bufferline = true,  -- Simple fix
```

## Risk Assessment

### Low Risk
- **Scope**: Changes contained to single file
- **Reversibility**: Easy to rollback
- **Impact**: Improves existing feature, doesn't add new ones

### Potential Issues
1. **Autocmd performance**: Mitigated by targeted events
2. **Event ordering**: Mitigated by defer_fn timing
3. **Plugin conflicts**: Mitigated by alpha filetype check

### Mitigation Strategies
- Test in clean Neovim instance first
- Add logging for debugging
- Keep fallback solution ready
- Monitor `:messages` for errors

## Notes

### Design Decisions
- **No new global state**: Function is local, pure
- **Minimal changes**: Enhances existing config, no architectural changes
- **Backwards compatible**: Preserves all existing behavior

### Future Enhancements
If additional customization needed:
- Extract to `/home/benjamin/.config/nvim/lua/neotex/util/bufferline-manager.lua`
- Add user command `:BufferlineToggleAlwaysShow` for manual override
- Add configuration table for visibility rules

### Alternative Approaches Considered
- **Solution 1**: `always_show_bufferline = true` - Too simple, loses single-buffer hiding
- **Solution 3**: Hybrid approach - More complex, same outcome
- **Solution 4**: Custom module - Over-engineering for current need

**Chosen approach (Solution 2) balances**:
- Robustness: Handles all edge cases
- Simplicity: In-place enhancement
- Maintainability: Centralized logic
- Performance: Event-driven, not polling

## References

### Research Report
- /home/benjamin/.config/nvim/specs/reports/023_bufferline_tab_visibility_issues.md
  - Section: Solution 2 (lines 283-337)
  - Section: Testing Plan (lines 407-437)
  - Section: Technical Deep Dive (lines 207-254)

### Configuration Files
- /home/benjamin/.config/nvim/lua/neotex/plugins/ui/bufferline.lua
  - Line 9: showtabline initialization
  - Line 28: always_show_bufferline setting
  - Line 112-125: Alpha integration pattern (template for new autocmds)
  - Line 126: Insertion point for new code

### Neovim Documentation
- `:help showtabline` - Tabline visibility option
- `:help buflisted` - Buffer listing flag
- `:help autocmd-events` - BufEnter, WinEnter, TermLeave events
- `:help vim.fn.getbufinfo()` - Buffer information API

### Related Issues
- Research report Finding 1: Incomplete showtabline logic
- Research report Finding 3: Missing TermLeave/WinLeave handlers
- Test case 3: Terminal switch behavior
- Test case 6: Alpha dashboard compatibility
