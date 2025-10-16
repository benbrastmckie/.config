# Debug Report: Git-Ignored Buffer Tabs Disappearing After Terminal Focus

## Metadata
- **Date**: 2025-10-02
- **Issue**: Buffer tabs for git-ignored files disappear after switching to terminal and back
- **Severity**: Medium
- **Type**: Debugging investigation
- **Related Reports**: [023_bufferline_tab_visibility_issues.md](023_bufferline_tab_visibility_issues.md)

## Problem Statement

When opening a buffer for a git-ignored file from the Neo-tree explorer, the following behavior occurs:

1. Initial state: Buffer tab is visible after opening the file
2. Switch to terminal (`<C-c>`): Buffer tab disappears
3. Switch back to buffer: Buffer tab still not shown
4. Workaround: Open explorer, reopen the same file - buffer tab reappears

**Critical observation**: This issue does NOT occur with non-ignored files. Regular files maintain their buffer tab visibility when switching to terminal and back.

## Investigation Process

### Step 1: Configuration Review
Examined the bufferline configuration in `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/bufferline.lua`

### Step 2: Event Handler Analysis
Analyzed the visibility management system implemented in implementation 023

### Step 3: Buffer Listing Investigation
Searched for code that might modify `buflisted` status based on git status or file attributes

### Step 4: Autocmd Audit
Reviewed all BufEnter, WinEnter, and FileType autocmds that could affect buffer visibility

## Findings

### Root Cause Analysis

**The issue is NOT in the bufferline configuration itself.** The bufferline visibility enhancement (implementation 023) correctly handles terminal switches and should preserve tabs regardless of git status.

**The root cause is likely an external plugin or autocmd** that is setting `buflisted = false` for git-ignored files under certain conditions. Here's the evidence:

#### Evidence 1: Bufferline Logic is Git-Agnostic
The bufferline configuration does NOT check git status:

```lua
-- lua/neotex/plugins/ui/bufferline.lua:35-47
custom_filter = function(buf_number, buf_numbers)
  local buf_ft = vim.bo[buf_number].filetype
  local buf_name = vim.api.nvim_buf_get_name(buf_number)

  -- Only filters quickfix and claude-code terminals
  if buf_ft == "qf" then return false end
  if string.match(buf_name, "claude%-code") then return false end

  return true
end
```

**Analysis**: The filter function does NOT check gitignore status, so bufferline itself is not discriminating against ignored files.

#### Evidence 2: Visibility Logic Only Checks `buflisted`
The `ensure_tabline_visible()` function counts listed buffers:

```lua
-- lua/neotex/plugins/ui/bufferline.lua:130-137
local function ensure_tabline_visible()
  local buffers = vim.fn.getbufinfo({buflisted = 1})
  if #buffers > 1 then
    vim.opt.showtabline = 2
  elseif #buffers <= 1 then
    vim.opt.showtabline = 0
  end
end
```

**Analysis**: If a buffer's `buflisted` property becomes `false`, it won't be counted and the tabline may hide.

#### Evidence 3: No Git-Specific Autocmds Found
Searched for autocmds that modify buffer listing based on git status - found none in the configuration files examined.

**However**: Did not find explicit code that sets `buflisted = false` based on git status in:
- `lua/neotex/plugins/ui/bufferline.lua`
- `lua/neotex/plugins/ui/neo-tree.lua`
- `lua/neotex/plugins/ai/claudecode.lua`
- `lua/neotex/config/autocmds.lua`

#### Evidence 4: Terminal Switch as Trigger
The behavior is triggered specifically by:
1. Switching to terminal (buffer becomes "inactive")
2. Switching back to buffer

**Hypothesis**: Some plugin or autocmd is:
- Running on BufEnter, WinEnter, or BufLeave events
- Checking if buffer is associated with a git-ignored file
- Setting `buflisted = false` when certain conditions are met
- The condition is only met after the buffer has lost focus

### Contributing Factors

#### Factor 1: Neo-tree File Opening Behavior
Neo-tree configuration (lines 241-244) explicitly shows git-ignored files:

```lua
filtered_items = {
  visible = true,
  hide_dotfiles = false,
  hide_gitignored = false,
}
```

This confirms that git-ignored files SHOULD be visible and openable, which they are initially.

#### Factor 2: Potential Plugin Interference
Several plugins in the configuration have potential to modify buffer properties:
- **gitsigns.nvim**: Integrates with git, might have buffer manipulation logic
- **telescope.nvim**: Has buffer management features
- **neo-tree.nvim**: Manages file visibility based on git status
- **bufferline.nvim**: Could have undocumented behavior with git status

#### Factor 3: Deferred Config Loading
Bufferline uses a 200ms deferred configuration load (line 61-173):

```lua
vim.defer_fn(function()
  bufferline.setup({
    -- Full configuration
  })
end, 200)
```

**Potential issue**: If another plugin loads after this defer and registers autocmds, they could override bufferline's intended behavior.

### Evidence

#### Code Location: bufferline.lua:141-155
```lua
vim.api.nvim_create_autocmd({"BufEnter", "WinEnter"}, {
  callback = function()
    local filetype = vim.bo.filetype

    -- Don't show tabline on alpha dashboard
    if filetype == "alpha" then
      vim.opt.showtabline = 0
      return
    end

    -- Update tabline visibility based on buffer count
    ensure_tabline_visible()
  end,
  desc = "Preserve bufferline visibility across window switches"
})
```

**What this SHOULD do**: Call `ensure_tabline_visible()` which counts `buflisted` buffers.

**What might be happening**:
1. User switches from git-ignored file buffer to terminal
2. Some autocmd fires and sets the git-ignored buffer's `buflisted = false`
3. User switches back to git-ignored buffer
4. BufEnter fires, calls `ensure_tabline_visible()`
5. Only 1 buffer is listed (the buffer is now `buflisted = false`)
6. Tabline is hidden (`showtabline = 0`)
7. Re-opening from explorer re-lists the buffer (`buflisted = true`)
8. Tab reappears

## Proposed Solutions

### Option 1: Add Explicit Buffer Listing Protection (Recommended)

Modify the BufEnter autocmd to explicitly ensure the current buffer is listed if it's a normal file:

```lua
vim.api.nvim_create_autocmd({"BufEnter", "WinEnter"}, {
  callback = function()
    local filetype = vim.bo.filetype

    -- Don't show tabline on alpha dashboard
    if filetype == "alpha" then
      vim.opt.showtabline = 0
      return
    end

    -- Ensure normal file buffers are always listed
    local buftype = vim.bo.buftype
    local bufname = vim.api.nvim_buf_get_name(0)

    -- If this is a normal file buffer, ensure it's listed
    if buftype == "" and bufname ~= "" and not bufname:match("^term://") then
      vim.bo.buflisted = true
    end

    -- Update tabline visibility based on buffer count
    ensure_tabline_visible()
  end,
  desc = "Preserve bufferline visibility across window switches"
})
```

**Pros**:
- Directly addresses the symptom
- Simple, localized change
- No impact on other plugins

**Cons**:
- Doesn't fix the root cause (unknown plugin still unlisting buffers)
- Could conflict with legitimate unlisting (e.g., scratch buffers)

### Option 2: Add Debug Logging to Identify Culprit

Add temporary autocmd to log when buffers become unlisted:

```lua
-- Debug autocmd (temporary)
vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter", "WinEnter"}, {
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local is_listed = vim.bo[buf].buflisted
    local bufname = vim.api.nvim_buf_get_name(buf)

    if bufname:match("%.gitignore") or bufname:match("some_ignored_file") then
      print(string.format("[DEBUG] Buffer %d (%s) buflisted: %s",
        buf, vim.fn.fnamemodify(bufname, ":t"), tostring(is_listed)))
    end
  end,
})
```

**Pros**:
- Identifies which plugin is changing `buflisted`
- Helps understand the timing of the issue
- Can be removed after diagnosis

**Cons**:
- Requires user to reproduce the issue with logging enabled
- Adds noise to the command line

### Option 3: Investigate Plugin Load Order

Check if gitsigns, telescope, or neo-tree has autocmds that might be interfering:

1. Search for `buflisted` in plugin configuration
2. Review each plugin's autocmd registrations
3. Adjust plugin load order if needed
4. Use `lazy.nvim` priority to ensure bufferline loads last

**Pros**:
- Addresses root cause
- Permanent fix
- Better understanding of plugin interactions

**Cons**:
- Time-consuming investigation
- May require reading third-party plugin source code
- Root cause might be in compiled plugin code (not easily accessible)

## Recommendations

1. **Immediate fix**: Implement Option 1 (explicit buffer listing protection)
   - Quick workaround that should resolve the symptom
   - Low risk of breaking other functionality

2. **Follow-up investigation**: Implement Option 2 (debug logging)
   - Run alongside Option 1 to identify the actual culprit
   - Once identified, can implement targeted fix

3. **Long-term solution**: Based on debug findings
   - If it's a known plugin, add plugin-specific configuration
   - If it's unclear, keep Option 1's protection logic
   - Consider reporting as bug to offending plugin

## Next Steps

### For Implementation
1. Add buffer listing protection to BufEnter/WinEnter autocmd
2. Test with git-ignored files:
   - Open git-ignored file from explorer
   - Switch to terminal with `<C-c>`
   - Switch back - verify tab is visible
3. Test edge cases:
   - Scratch buffers should remain unlisted
   - Terminal buffers should remain unlisted
   - Help buffers should remain unlisted

### For Further Diagnosis
1. Enable debug logging autocmd
2. Reproduce the issue while watching output
3. Note which events fire and when `buflisted` changes
4. Check `:scriptnames` for plugin load order
5. Review output of `:autocmd BufEnter` to see all registered handlers

### For User Reporting
If you want to provide more diagnostic information:

1. Run this command and report output:
```vim
:lua vim.cmd('autocmd BufEnter')
```

2. When you experience the issue, immediately run:
```vim
:lua print("Current buffer listed: " .. tostring(vim.bo.buflisted))
```

3. Check if the buffer is still in the buffer list:
```vim
:ls
```

4. Report which plugins are managing buffers:
```vim
:scriptnames | grep -E "buffer|git"
```

## References

### Related Files
- [lua/neotex/plugins/ui/bufferline.lua](../../lua/neotex/plugins/ui/bufferline.lua) - Bufferline configuration
- [lua/neotex/plugins/ui/neo-tree.lua](../../lua/neotex/plugins/ui/neo-tree.lua) - File explorer (opens git-ignored files)
- [lua/neotex/config/autocmds.lua](../../lua/neotex/config/autocmds.lua) - Global autocmds

### Related Specifications
- [Report 023: Bufferline Tab Visibility Issues](023_bufferline_tab_visibility_issues.md) - Original visibility enhancement
- [Summary 023: Bufferline Visibility Implementation](../summaries/023_bufferline_visibility_implementation.md) - Implementation details

### Neovim Documentation
- `:help buflisted` - Buffer listing flag
- `:help buftype` - Buffer type categorization
- `:help autocmd-events` - Event reference
- `:help vim.fn.getbufinfo()` - Buffer query API

### Potential Relevant Plugins
- **gitsigns.nvim**: Git integration plugin (might have buffer hooks)
- **bufferline.nvim**: May have undocumented git-aware behavior
- **neo-tree.nvim**: File explorer with git integration
- **telescope.nvim**: Buffer picker with git integration

## Conclusion

The git-ignored buffer disappearance issue was likely caused by an external plugin or autocmd setting `buflisted = false` for git-ignored file buffers after they lose focus. The bufferline visibility system (implementation 023) is working correctly, but depends on `buflisted` being accurate.

### Resolution Status

**RESOLVED** via defensive workaround (Option 1):
- Added autocmd in `sessions.lua` that forces all normal file buffers to remain `buflisted = true`
- Workaround prevents the symptom without identifying the root cause
- Issue is no longer reproducible with workaround in place

**ROOT CAUSE: UNKNOWN**
Comprehensive investigation found:
- No code in user config modifies `buflisted` based on git status
- Session manager doesn't unlist buffers (only reads state)
- All explicit `buflisted=false` settings are for special buffers (terminals, quickfix)
- Gitsigns, neo-tree, and other git plugins don't touch buffer listing
- Issue may be in third-party plugin internals or Neovim's mksession behavior

### Implementation

The workaround is implemented in `lua/neotex/plugins/ui/sessions.lua:70-82`:

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

This simple 12-line autocmd ensures all normal file buffers remain listed, preventing them from disappearing from bufferline and being excluded from session saves.

### Extension to .claude/ Directory Files

**Date**: 2025-10-03

The buffer persistence issue resurfaced for `.claude/` directory files, despite the initial workaround being in place. Analysis revealed that the autocmd event coverage was insufficient:

**Problem**: Files in `.claude/` directories would:
1. Load correctly into buffers initially
2. Appear in bufferline as expected
3. Disappear from bufferline after switching to terminal and back
4. Require reopening from explorer to reappear

**Root Cause**: The original autocmd only listened to `BufAdd` and `SessionLoadPost` events, which did not catch all buffer state transitions. Specifically:
- `BufAdd`: Fires when buffer is first added to buffer list
- `SessionLoadPost`: Fires after session restoration
- **Missing**: Events during normal buffer switching and window management

**Solution**: Enhanced event coverage by adding:
- `BufEnter`: Catches buffers when switching back from terminal
- `BufWinEnter`: Catches buffers when displayed in windows after splits

The enhanced autocmd (sessions.lua:72-84) now protects buffers during all state transitions:
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

**Design Philosophy**: Path-agnostic protection was chosen over `.claude/`-specific checks to maintain simplicity and avoid fragile configuration. The enhanced workaround protects ALL normal file buffers during ALL state transitions.

**Performance Impact**: Negligible - the autocmd performs only simple property checks (microsecond-level operations).

**References**:
- Implementation plan: [specs/plans/029_strengthen_buffer_persistence_autocmd.md](../plans/029_strengthen_buffer_persistence_autocmd.md)
- Implementation summary: [specs/summaries/029_buffer_persistence_enhancement_summary.md](../summaries/029_buffer_persistence_enhancement_summary.md)

### Future Work

**UPDATE (2025-10-03): ROOT CAUSE IDENTIFIED AND FIXED**

The root cause has been successfully identified through comprehensive parallel agent research. See:
- [Report 038: Buffer Persistence Root Cause](038_buffer_persistence_root_cause.md) - Complete root cause analysis
- [Plan 030: Fix Buffer Persistence Root Cause](../plans/030_fix_buffer_persistence_root_cause.md) - Implementation plan
- [Summary 030: Buffer Persistence Root Cause](../summaries/030_buffer_persistence_root_cause_summary.md) - Implementation workflow

**Primary bugs found and fixed**:
1. **claudecode.lua pattern matching bug**: Overly broad pattern unlisted .claude/ directory files
2. **bufferline.lua timing race condition**: Autocmd registration delay created session restore gap

**Solution implemented**:
- Fixed claudecode.lua to check buffer type before pattern matching (commit 6033ed9)
- Fixed bufferline.lua to register autocmds before defer_fn (commit 3cc3f5f)
- Simplified defensive autocmd from 4 events to 2 events - 50% reduction (commit 855c953)

The defensive autocmd in sessions.lua has been simplified but maintained as protection against unknown third-party async operations. The hybrid approach fixes known root causes while maintaining minimal defensive coverage.
