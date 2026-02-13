# Research Report: Task #84 (Third Pass)

**Task**: 84 - Fix Himalaya email composition UX issue with disruptive header changes
**Started**: 2026-02-13T12:00:00Z
**Completed**: 2026-02-13T12:45:00Z
**Effort**: 1-2 hours (implementation)
**Dependencies**: research-001.md, research-002.md
**Sources/Inputs**: Local codebase analysis, draft lifecycle tracing
**Artifacts**: - specs/084_fix_disruptive_header_changes_himalaya_email/reports/research-003.md
**Standards**: report-format.md

## Executive Summary

- **Critical Bug Found**: `HimalayaSaveDraft` command passes boolean `true` instead of buffer number to `save_draft()`, causing "No draft associated with buffer" error
- **Secondary Issue**: Buffer reload via `checktime`/`FileChangedShell` can destroy buffer-to-draft association if the buffer is recreated (buffer ID changes)
- **Integrated Solution**: Fix the argument bug in commands, disable buffer-local autoread (from research-001/002), and consider `buftype='acwrite'` for complete isolation

## Context & Scope

### New Problem Description
User reports "Failed to save draft: No draft associated with buffer" error when pressing `<leader>md` (which triggers `HimalayaSaveDraft`). This is the third symptom alongside:
1. Header format changes (research-001.md)
2. Data loss from race condition (research-002.md)

### Investigation Focus
1. How are drafts created and associated with buffers?
2. What causes the draft-buffer association to be lost?
3. What is the integrated solution for all three issues?

## Findings

### 1. Draft-Buffer Association Architecture

The draft manager (`data/drafts.lua`) maintains a module-level mapping table:

```lua
-- Buffer to draft path mapping (line 36)
M.buffer_drafts = {}  -- buffer -> filepath
```

**Association is Created**:
- In `M.create()` at line 186: `M.buffer_drafts[buf] = filepath`
- In `M.open()` at line 611: `M.buffer_drafts[buf] = filepath`

**Association is Removed**:
- In `M.delete()` at line 640: `M.buffer_drafts[buffer] = nil`
- In `M.cleanup_draft()` at line 844: `M.buffer_drafts[buffer] = nil`
- Via `BufDelete` autocmd (line 63-68) which calls `M.cleanup_draft(args.buf)`

**Association is Checked**:
- In `M.save()` at line 325: `local filepath = M.buffer_drafts[buffer]`
- In `M.send()` at line 666: `local filepath = M.buffer_drafts[buffer]`
- In `M.get_by_buffer()` at line 806: `local filepath = M.buffer_drafts[buffer]`
- In `M.is_draft()` at line 871: `return M.buffer_drafts[buffer] ~= nil`

### 2. Critical Bug: Wrong Argument Type in HimalayaSaveDraft

**Location**: `commands/email.lua` lines 80-95

```lua
commands.HimalayaSaveDraft = {
  fn = function()
    local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
    local notify = require('neotex.util.notifications')

    if not composer.is_composing() then
      notify.himalaya('No email is being composed', notify.categories.ERROR)
      return
    end

    composer.save_draft(true) -- BUG: true should be vim.api.nvim_get_current_buf()
  end,
  opts = {
    desc = 'Save current email as draft'
  }
}
```

**The Bug**:
- `save_draft(true)` passes boolean `true` as the first argument
- Function signature is `save_draft(buf, trigger)` (`email_composer.lua` line 193)
- So `buf = true` (boolean), `trigger = nil` (defaults to 'manual')
- When `draft_manager.save(buf, silent)` is called, `buf = true`
- `M.buffer_drafts[true]` returns `nil` (no entry for boolean key)
- Error: "No draft associated with buffer"

**Similar Issues in Other Commands**:

Checking `HimalayaDraftSave` (lines 128-144):
```lua
commands.HimalayaDraftSave = {
  fn = function()
    local email_composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
    local notify = require('neotex.util.notifications')

    if not email_composer.is_composing() then
      notify.himalaya('No draft is being composed', notify.categories.ERROR)
      return
    end

    email_composer.save_draft(true)  -- SAME BUG
  end,
```

### 3. Buffer Reload and Association Loss

Even after fixing the argument bug, a secondary issue exists: if the buffer is reloaded via `checktime`/`:e!`, the buffer ID can change, breaking the association.

**Normal Scenario (Working)**:
```
1. Create draft -> buf=42 created
2. M.buffer_drafts[42] = "/path/to/draft"
3. User edits in buf=42
4. save_draft(42) -> M.buffer_drafts[42] exists -> works
```

**Reload Scenario (Breaking)**:
```
1. Create draft -> buf=42 created
2. M.buffer_drafts[42] = "/path/to/draft"
3. Autosave writes to disk
4. checktime triggers FileChangedShell
5. Neovim reloads buffer content (buf=42 still valid, same ID)
   - In this case: buf ID stays same, association preserved
   - BUT: buffer content changes to full MIME format (issue #1/#2)
```

**Alternative Breaking Scenario** (if :e! or explicit reload):
```
1. Create draft -> buf=42 created
2. M.buffer_drafts[42] = "/path/to/draft"
3. User runs :e! manually
4. BufDelete fires -> M.cleanup_draft(42) -> M.buffer_drafts[42] = nil
5. New buffer created (could be same or different ID)
6. Association lost
```

The `BufDelete` autocmd (line 63-68) cleans up the association, but nothing re-establishes it after reload.

### 4. Why Autoread Disable Solves Multiple Issues

Disabling autoread for compose buffers (as recommended in research-001/002) also helps with association:

1. **Prevents Header Changes**: No automatic reload = buffer stays simplified
2. **Prevents Data Loss**: No automatic reload = no race condition
3. **Preserves Association**: Buffer is never deleted = `buffer_drafts` mapping stays valid

However, this doesn't fix the argument bug - that's a separate code defect.

### 5. Alternative Architecture: buftype='acwrite'

Using `buftype='acwrite'` would provide stronger isolation:

```lua
vim.api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
```

**Effects**:
- Buffer is not associated with a file in Neovim's eyes
- `checktime` won't trigger reloads
- `:w` triggers `BufWriteCmd` instead of normal write
- The plugin already has `BufWriteCmd` handler (line 150-157)

**Current buftype (line 165)**:
```lua
vim.api.nvim_buf_set_option(buf, 'buftype', '')  -- Normal file buffer
```

**Considerations**:
- `acwrite` = "autocmd write" - buffer needs write handling via autocmd
- The plugin already uses `BufWriteCmd` for write operations
- This would completely isolate compose buffers from file-based autoread

## Root Cause Summary

### Primary Bug (Immediate Error)
`HimalayaSaveDraft` and `HimalayaDraftSave` commands pass `true` instead of buffer number to `save_draft()`, causing immediate "No draft associated with buffer" error.

### Secondary Issue (From research-001/002)
Global `autoread=true` combined with `FileChangedShell` autocmd causes buffer reload when autosave writes to disk, leading to:
- Header format changes
- Potential data loss
- Association not affected (buffer ID preserved during reload)

## Recommendations

### Fix 1: Correct Argument in Commands (CRITICAL)

**Location**: `commands/email.lua`

**HimalayaSaveDraft** (line 90):
```lua
-- Before
composer.save_draft(true)

-- After
local buf = vim.api.nvim_get_current_buf()
composer.save_draft(buf, 'manual')
```

**HimalayaDraftSave** (line 138):
```lua
-- Before
email_composer.save_draft(true)

-- After
local buf = vim.api.nvim_get_current_buf()
email_composer.save_draft(buf, 'manual')
```

### Fix 2: Disable Autoread for Compose Buffers (From research-001/002)

**Location**: `data/drafts.lua`

In `M.create()` after line 167:
```lua
vim.api.nvim_buf_set_option(buf, 'modified', false)
-- Disable autoread to prevent buffer reload when autosave writes
vim.bo[buf].autoread = false
```

In `M.open()` after line 605:
```lua
vim.api.nvim_buf_set_option(buf, 'modified', false)
-- Disable autoread to prevent buffer reload when autosave writes
vim.bo[buf].autoread = false
```

### Fix 3 (Optional): Use buftype='acwrite'

For complete isolation, change in both `M.create()` and `M.open()`:
```lua
-- Before
vim.api.nvim_buf_set_option(buf, 'buftype', '')

-- After
vim.api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
```

This provides stronger isolation than just disabling autoread.

## Implementation Priority

| Fix | Priority | Effort | Impact |
|-----|----------|--------|--------|
| Fix 1: Argument bug | **CRITICAL** | Low (2 lines) | Fixes immediate error |
| Fix 2: Disable autoread | High | Low (2 lines) | Fixes reload issues |
| Fix 3: buftype='acwrite' | Medium | Low (1 line) | Complete isolation |

**Recommended Order**: Fix 1 first (blocks `<leader>md`), then Fix 2 (addresses research-001/002), Fix 3 optional.

## Integrated Solution

All three issues (header changes, data loss, association error) can be addressed by:

1. **Fixing the argument bug** in `HimalayaSaveDraft` and `HimalayaDraftSave`
2. **Disabling autoread** for compose buffers OR using `buftype='acwrite'`

The combined fix is approximately 5 lines of code across 2 files.

## Decisions

1. **Decision**: Fix argument bug first as it's a blocking defect
   - Rationale: `<leader>md` is completely broken

2. **Decision**: Use `vim.bo[buf].autoread = false` rather than `buftype='acwrite'`
   - Rationale: Less invasive change, preserves file association for debugging
   - Alternative (`acwrite`) can be reconsidered if issues persist

3. **Decision**: Do not modify FileChangedShell autocmd globally
   - Rationale: Buffer-local autoread disable is more targeted

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Other code paths expecting true arg | Low | Low | Grep for `save_draft(true)` patterns |
| Missing other broken commands | Low | Medium | Test all compose commands after fix |
| Autoread disable affects draft recovery | Very Low | Minor | Drafts save to Maildir anyway |

## Appendix

### Files to Modify

1. `lua/neotex/plugins/tools/himalaya/commands/email.lua`
   - Line 90: Change `composer.save_draft(true)` to `composer.save_draft(vim.api.nvim_get_current_buf(), 'manual')`
   - Line 138: Change `email_composer.save_draft(true)` to `email_composer.save_draft(vim.api.nvim_get_current_buf(), 'manual')`

2. `lua/neotex/plugins/tools/himalaya/data/drafts.lua`
   - After line 167 in `M.create()`: Add `vim.bo[buf].autoread = false`
   - After line 605 in `M.open()`: Add `vim.bo[buf].autoread = false`

### Testing Strategy

1. **Test Fix 1**:
   - Create new email with `:HimalayaWrite`
   - Press `<leader>md` (HimalayaSaveDraft)
   - Verify: No error, draft saved notification appears

2. **Test Fix 2** (from research-001/002):
   - Create new email
   - Type content, wait for autosave (5 seconds)
   - Switch windows and back (triggers checktime)
   - Verify: Headers unchanged, content preserved

3. **Integration Test**:
   - Full compose -> save -> send workflow
   - Reply workflow with quoted text
   - Forward workflow

### Search Queries Used

- Local grep: `save_draft`, `buffer_drafts`, `HimalayaSaveDraft`, `BufDelete`
- Code trace: Command -> Composer -> Draft Manager -> buffer_drafts table

### References

- `lua/neotex/plugins/tools/himalaya/commands/email.lua` - Command definitions
- `lua/neotex/plugins/tools/himalaya/ui/email_composer.lua` - Composer UI module
- `lua/neotex/plugins/tools/himalaya/data/drafts.lua` - Draft manager with buffer mapping
- research-001.md - Header format change analysis
- research-002.md - Data loss and race condition analysis
