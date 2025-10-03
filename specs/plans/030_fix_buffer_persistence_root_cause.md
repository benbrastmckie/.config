# Fix Buffer Persistence Root Cause Implementation Plan

## Metadata
- **Date**: 2025-10-03
- **Feature**: Fix buffer persistence root cause by correcting claudecode pattern matching and eliminating timing race conditions
- **Scope**: claudecode.lua pattern matching bug fix and bufferline.lua timing optimization
- **Estimated Phases**: 3
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: Investigation conducted via /orchestrate research phase

## Overview

Comprehensive research has identified the ROOT CAUSE of buffer persistence issues with ignored/hidden files:

### Primary Issue: claudecode.lua Pattern Matching Bug
Lines 97-99 in `lua/neotex/plugins/ai/claudecode.lua` contain overly broad pattern matching:
```lua
if bufname:match("claude") then
  vim.bo.buflisted = false
  vim.bo.bufhidden = "hide"
end
```

This catches ANY buffer with "claude" in the path, including `.claude/` directory files (e.g., `.claude/tts/tts-config.sh`), when it should only target Claude Code terminal buffers.

### Secondary Issue: Bufferline Timing Race Condition
Line 173 in `lua/neotex/plugins/ui/bufferline.lua` uses a 200ms defer_fn:
```lua
end, 200)
```

This creates a timing window during session restoration where buffers aren't properly tracked by the `ensure_tabline_visible()` autocmd, which only gets registered after the delay.

### Research Findings
- **bufferline.nvim plugin**: Innocent - purely a display layer, doesn't modify buffer properties
- **neovim-session-manager plugin**: Innocent - correctly saves/restores based on `:mksession` output
- **Plugin load order**: Creates timing vulnerabilities (session-manager loads on VimEnter, bufferline loads on BufAdd + 200ms delay)
- **Defensive autocmd in sessions.lua**: Fires too early to prevent the claudecode.lua unlisting

### Solution Strategy
This plan implements a **hybrid approach**:
1. **Fix identified root causes** (claudecode pattern, bufferline timing)
2. **Simplify defensive autocmd** from 4 events to 2 events (not complete removal)

**Rationale for keeping simplified defense**: Report 037 documented that the ultimate root cause was never definitively identified. While we've found the primary culprit (claudecode.lua), keeping minimal protection (BufEnter, BufWinEnter) guards against unknown third-party async operations with negligible performance cost.

## Success Criteria
- [ ] Files in `.claude/` directory persist in bufferline after terminal switches
- [ ] Files in `.claude/` directory persist across session save/restore
- [ ] Claude Code terminal buffers remain unlisted (current desired behavior)
- [ ] No timing race conditions during session restoration
- [ ] Pattern matching is precise and doesn't catch unintended buffers
- [ ] Defensive autocmd simplified from 4 events to 2 events (50% reduction)
- [ ] Solution is elegant, maintainable, and balances fixing root causes with defensive robustness

## Technical Design

### Root Cause Analysis

#### Issue 1: Overly Broad Pattern Matching
**Current problematic code** (claudecode.lua:93-104):
```lua
vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
  pattern = "*",
  callback = function()
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname:match("claude") or bufname:match("ClaudeCode") or vim.bo.buftype == "terminal" then
      if bufname:match("claude") then  -- THIS IS TOO BROAD
        vim.bo.buflisted = false
        vim.bo.bufhidden = "hide"
      end
    end
  end,
})
```

**Problems**:
- `bufname:match("claude")` matches `.claude/tts/tts-config.sh` (directory files)
- Should only match terminal buffers with "claude" in their name
- Terminal check on line 97 is redundant and doesn't prevent the unlisting

**Solution**:
Make pattern matching terminal-specific:
```lua
-- Only unlist if it's actually a terminal buffer AND has "claude" in the name
if vim.bo.buftype == "terminal" and (bufname:match("claude") or bufname:match("ClaudeCode")) then
  vim.bo.buflisted = false
  vim.bo.bufhidden = "hide"
end
```

#### Issue 2: Timing Race Condition
**Current problematic code** (bufferline.lua:61-173):
```lua
vim.defer_fn(function()
  bufferline.setup({
    -- ... full configuration ...
  })

  -- Autocmds registered here, 200ms after BufAdd
  vim.api.nvim_create_autocmd({"BufEnter", "WinEnter"}, {
    callback = function()
      ensure_tabline_visible()
    end,
    desc = "Preserve bufferline visibility across window switches"
  })
end, 200)
```

**Problems**:
- 200ms delay means session buffers are restored before autocmds are active
- Creates window where `ensure_tabline_visible()` isn't watching buffer changes
- Defensive autocmd in sessions.lua can't compensate for this timing gap

**Solution**:
Register critical autocmds immediately, only defer the full setup:
```lua
-- Register critical autocmds immediately (before defer)
local function ensure_tabline_visible()
  -- ... existing function ...
end

-- Register autocmds BEFORE defer_fn
vim.api.nvim_create_autocmd({"BufEnter", "WinEnter", "SessionLoadPost"}, {
  callback = ensure_tabline_visible,
  desc = "Preserve bufferline visibility across window switches"
})

-- Defer only the full bufferline.setup()
vim.defer_fn(function()
  bufferline.setup({
    -- ... configuration ...
  })
end, 200)
```

### Design Decisions

1. **Precise Pattern Matching**: Use terminal buffer type check BEFORE pattern matching to avoid catching normal files
2. **Early Autocmd Registration**: Register visibility autocmds before defer_fn to catch session restore
3. **Minimal Change**: Fix only the specific bugs, don't refactor unrelated code
4. **Backward Compatible**: Maintain all existing behavior for legitimate Claude Code terminal buffers
5. **Remove Defensive Workaround**: Once root cause is fixed, the defensive autocmd in sessions.lua can be simplified or removed

## Implementation Phases

### Phase 1: Fix claudecode.lua Pattern Matching [COMPLETED]
**Objective**: Correct overly broad pattern matching to only target terminal buffers
**Complexity**: Low

Tasks:
- [x] Modify claudecode.lua:93-104 to check buftype BEFORE pattern matching
- [x] Change condition from `if bufname:match("claude")` to `if vim.bo.buftype == "terminal" and bufname:match("claude")`
- [x] Remove redundant outer terminal check on line 97
- [x] Verify syntax with headless Neovim test

Testing:
```bash
# Syntax validation
nvim --headless -c "luafile ~/.config/nvim/lua/neotex/plugins/ai/claudecode.lua" -c "qa"

# Manual test procedure:
# 1. Open .claude/tts/tts-config.sh
# 2. Verify buffer remains listed: :lua print(vim.bo.buflisted)
# 3. Open Claude Code terminal
# 4. Verify terminal buffer is unlisted: :lua print(vim.bo.buflisted)
```

Expected outcome:
- `.claude/` directory files remain listed
- Claude Code terminal buffers become unlisted
- Pattern matching is precise and explicit

### Phase 2: Fix bufferline.lua Timing Race Condition
**Objective**: Register critical autocmds before defer_fn to eliminate session restore timing gap
**Complexity**: Medium

Tasks:
- [ ] Move `ensure_tabline_visible` function definition before defer_fn (line ~130)
- [ ] Register BufEnter/WinEnter/SessionLoadPost autocmds BEFORE defer_fn
- [ ] Keep bufferline.setup() call inside defer_fn
- [ ] Remove duplicate autocmd registration from inside defer_fn
- [ ] Verify autocmds register in correct order with `:autocmd BufEnter`

Testing:
```bash
# Syntax validation
nvim --headless -c "luafile ~/.config/nvim/lua/neotex/plugins/ui/bufferline.lua" -c "qa"

# Manual test procedure:
# 1. Open nvim with existing session
# 2. Verify buffers appear immediately (no 200ms delay)
# 3. Run :autocmd BufEnter to see autocmd is registered
# 4. Close and reopen nvim
# 5. Verify session buffers persist without delay
```

Expected outcome:
- Autocmds active immediately on plugin load
- No timing gap during session restoration
- Bufferline setup still deferred for smooth initialization

### Phase 3: Simplify Defensive Autocmd
**Objective**: Simplify defensive autocmd in sessions.lua from 4 events to 2 events
**Complexity**: Low

**Rationale**: Research analysis confirms that while the claudecode.lua fix addresses the primary root cause, the defensive autocmd should be **kept but simplified** because:
- Report 037 documented that the ultimate root cause was never definitively identified
- Unknown third-party plugins could potentially unlist buffers
- 45+ files use async operations (vim.defer_fn, vim.schedule) that could modify buffer state
- Performance cost is negligible (microsecond-level checks)
- Simplification from 4 → 2 events still provides value

**Simplification Strategy**:
- **Remove**: BufAdd, SessionLoadPost (no longer needed after root cause fixes)
- **Keep**: BufEnter, BufWinEnter (protection during transitions and async operations)

Tasks:
- [ ] Simplify sessions.lua:72 autocmd events from 4 to 2
- [ ] Change events from `{"BufAdd", "SessionLoadPost", "BufEnter", "BufWinEnter"}` to `{"BufEnter", "BufWinEnter"}`
- [ ] Update comment to explain that BufAdd/SessionLoadPost are no longer needed due to root cause fixes
- [ ] Update comment to explain that BufEnter/BufWinEnter provide protection against unknown async operations
- [ ] Update autocmd description to reflect simplified purpose

Testing:
```bash
# Comprehensive test:
# 1. Open mix of .claude/ files and nvim/lua files
# 2. Switch to terminal and back multiple times
# 3. Save session (autosave or manual)
# 4. Close nvim completely
# 5. Reopen nvim and load session
# 6. Verify ALL buffers restored and visible
# 7. Verify Claude Code terminal still unlisted
# 8. Test for 1-2 weeks in normal usage for edge cases
```

Expected outcome:
- Buffer persistence works with simplified autocmd (2 events instead of 4)
- No redundant BufAdd/SessionLoadPost firing
- Protection maintained against unknown async buffer unlisting
- Cleaner, more maintainable code with clear reasoning

## Testing Strategy

### Unit Testing
Not applicable - this is plugin configuration logic tested via integration

### Integration Testing

**Test Case 1: .claude/ Directory File Persistence**
1. Open `.claude/tts/tts-config.sh`
2. Check buffer listed status: `:lua print(vim.bo.buflisted)` → should be `true`
3. Switch to terminal (`<C-c>`)
4. Switch back to buffer
5. **Expected**: Buffer tab remains visible, buflisted still true

**Test Case 2: Claude Code Terminal Unlisting**
1. Open Claude Code terminal
2. Check buffer listed status: `:lua print(vim.bo.buflisted)` → should be `false`
3. Check bufhidden: `:lua print(vim.bo.bufhidden)` → should be `hide`
4. **Expected**: Terminal buffer not shown in bufferline

**Test Case 3: Session Restoration Timing**
1. Open multiple .claude/ files
2. Save session (autosave or manual)
3. Close Neovim
4. Reopen Neovim
5. Immediately check `:autocmd BufEnter` - autocmd should be registered
6. **Expected**: All buffers restore immediately, no 200ms delay

**Test Case 4: Mixed Buffer Types**
1. Open mix of:
   - .claude/ files (should be listed)
   - nvim/lua files (should be listed)
   - Claude Code terminal (should be unlisted)
   - Quickfix window (should be unlisted)
2. Switch between all buffer types
3. **Expected**: Only normal file buffers appear in bufferline

### Regression Testing
- Verify existing Claude Code functionality unaffected
- Verify bufferline display logic unchanged
- Verify session autosave behavior unchanged
- Verify no new autocmd conflicts

## Documentation Requirements

### Inline Documentation
- Update comment in claudecode.lua to explain precise terminal matching
- Add comment in bufferline.lua explaining why autocmds register early
- Update TODO comment in sessions.lua noting root cause has been fixed

### Code Comments
```lua
-- claudecode.lua example:
-- Only unlist Claude Code terminal buffers, not .claude/ directory files
-- Check buftype == "terminal" BEFORE pattern matching to avoid false positives
if vim.bo.buftype == "terminal" and (bufname:match("claude") or bufname:match("ClaudeCode")) then
  vim.bo.buflisted = false
  vim.bo.bufhidden = "hide"
end
```

### Report Updates
- Create new debug report: specs/reports/038_buffer_persistence_root_cause.md
- Document findings from research phase (claudecode bug + timing race)
- Cross-reference plan 030 and summary 030
- Update report 037 with note that root cause has been identified and fixed

### README Updates
Not required - this is internal bug fix

## Dependencies

### Plugin Dependencies
- greggh/claude-code.nvim - being modified
- akinsho/bufferline.nvim - wrapper config being modified
- Shatur/neovim-session-manager - no changes needed

### Configuration Dependencies
- Existing claudecode.lua configuration (lines 1-107)
- Existing bufferline.lua configuration (lines 1-176)
- Existing sessions.lua configuration (lines 1-87)

## Risk Assessment

### Low Risk
- **Change scope**: Minimal - fixing two specific bugs
- **Reversibility**: Easy to revert by restoring original pattern/timing
- **Blast radius**: Isolated to buffer listing logic

### Potential Issues
1. **Unintended terminal buffers**: Other terminal buffers with "claude" in name might get listed
   - **Mitigation**: Pattern is specific enough (checks buftype first)
   - **Impact**: Minimal - unlikely to have non-Claude terminal buffers with that name

2. **Bufferline visual glitch**: Moving autocmd registration might cause brief visual flash
   - **Mitigation**: Autocmd logic is identical, just registered earlier
   - **Impact**: Minimal - should be visually identical

3. **Plugin load order edge case**: If another plugin relies on bufferline defer timing
   - **Mitigation**: Only autocmds move earlier, full setup still deferred
   - **Impact**: Very low - bufferline is self-contained

### Rollback Plan
If issues arise:
1. Revert claudecode.lua to original pattern matching
2. Revert bufferline.lua to original defer_fn structure
3. Keep defensive autocmd in sessions.lua as permanent solution
4. Create detailed bug report for further investigation

## Notes

### Why This is the Elegant Solution

The research phase conclusively identified TWO bugs:
1. **Overly broad pattern matching** - catches files it shouldn't
2. **Timing race condition** - autocmds register too late

Fixing these bugs at their SOURCE is more elegant than defensive workarounds because:
- **Precise**: Targets only the actual problematic code
- **Maintainable**: Future developers understand the logic
- **Performant**: Doesn't add redundant autocmds firing on every event
- **Correct**: Fixes the actual bug rather than papering over it

### Comparison to Defensive Workaround

**Original defensive approach** (plan 029):
- Added 4 autocmd events: BufAdd, SessionLoadPost, BufEnter, BufWinEnter
- Continuously re-sets buflisted=true for all normal buffers
- Works around the problem but doesn't fix root cause
- Fires on every buffer/window switch

**Root cause fix + simplified defense** (this plan):
- **Fixes claudecode.lua** to not unlist wrong buffers (PRIMARY FIX)
- **Fixes bufferline.lua** timing so autocmds work during session restore (SECONDARY FIX)
- **Simplifies defensive autocmd** from 4 events to 2 events (BufEnter, BufWinEnter only)
- **Reasoning**: Keep minimal protection against unknown third-party async operations
- **Result**: Eliminates identified root causes while maintaining safety net against unknowns

**Benefits of hybrid approach**:
- Fixes the bugs we know about (claudecode pattern, bufferline timing)
- Protects against unknown async operations (report 037 never found definitive root cause)
- Reduces overhead by 50% (2 events instead of 4)
- Maintains robustness without sacrificing performance

### User Requirements Alignment
User specifically requested:
- ✓ Identify root cause (achieved via research phase)
- ✓ Design elegant solution (fix bugs vs. work around them)
- ✓ Avoid fragile configurations (precise pattern matching)
- ✓ Investigate plugin source code (bufferline.nvim & session-manager examined)

This solution meets all requirements by fixing the actual bugs identified through comprehensive research.

## References

### Related Files
- lua/neotex/plugins/ai/claudecode.lua (lines 93-104) - Pattern matching bug
- lua/neotex/plugins/ui/bufferline.lua (lines 61-173) - Timing race condition
- lua/neotex/plugins/ui/sessions.lua (lines 64-84) - Defensive workaround (can be simplified)

### Related Plans
- specs/plans/029_strengthen_buffer_persistence_autocmd.md - Defensive workaround approach

### Related Reports
- specs/reports/037_debug_gitignored_buffer_disappearance.md - Original investigation
- specs/reports/038_buffer_persistence_root_cause.md - New report documenting root cause (to be created)

### External Documentation
- https://github.com/akinsho/bufferline.nvim - Confirmed innocent
- https://github.com/Shatur/neovim-session-manager - Confirmed innocent
- `:help buflisted` - Buffer listing flag
- `:help buftype` - Buffer type categorization
- `:help autocmd-events` - Event reference
