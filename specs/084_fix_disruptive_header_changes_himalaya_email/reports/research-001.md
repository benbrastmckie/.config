# Research Report: Task #84

**Task**: 84 - Fix Himalaya email composition UX issue with disruptive header changes
**Started**: 2026-02-13T00:00:00Z
**Completed**: 2026-02-13T00:30:00Z
**Effort**: 1-2 hours (implementation)
**Dependencies**: None
**Sources/Inputs**: Local codebase analysis, plugin documentation, Neovim autoread behavior
**Artifacts**: - specs/084_fix_disruptive_header_changes_himalaya_email/reports/research-001.md
**Standards**: report-format.md

## Executive Summary

- Root cause identified: Neovim's autoread/checktime mechanism reloads the compose buffer from disk, which contains full MIME headers, replacing the simplified editing view
- The draft system intentionally maintains a dual format: simplified headers in buffer (From/To/Cc/Bcc/Subject) vs full MIME on disk (with Date, Content-Type, MIME-Version, X-Himalaya-Account)
- Solution: Disable autoread for compose buffers OR ensure buffer content matches disk content

## Context & Scope

### Problem Description
When composing/replying to emails in Himalaya, users experience disruptive UX where:
1. Initial header shows simple format: From, To, Cc, Bcc, Subject
2. Headers suddenly change to full MIME format with additional fields (Mime-Version, Date, Content-Type, X-Himalaya-Account)
3. This causes cursor displacement while the user is actively typing

### Investigation Scope
- Local Himalaya plugin implementation in `lua/neotex/plugins/tools/himalaya/`
- Draft creation and saving workflow
- Neovim autoread and buffer reload mechanisms
- Interaction between autosave and file change detection

## Findings

### 1. Dual Format Architecture

The draft system uses a dual format design (discovered in `data/drafts.lua`):

**File on Disk (Full MIME)** - Lines 100-112:
```lua
local headers = {
  string.format('From: %s', metadata.from or ''),
  string.format('To: %s', metadata.to or ''),
  string.format('Cc: %s', metadata.cc or ''),
  string.format('Bcc: %s', metadata.bcc or ''),
  string.format('Subject: %s', metadata.subject or ''),
  string.format('Date: %s', os.date('!%a, %d %b %Y %H:%M:%S +0000')),
  string.format('X-Himalaya-Account: %s', account),
  'Content-Type: text/plain; charset=utf-8',
  'MIME-Version: 1.0'
}
```

**Buffer Display (Simplified)** - Lines 147-161:
```lua
local edit_lines = {}
table.insert(edit_lines, 'From: ' .. (metadata.from or ''))
table.insert(edit_lines, 'To: ' .. (metadata.to or ''))
table.insert(edit_lines, 'Cc: ' .. (metadata.cc or ''))
table.insert(edit_lines, 'Bcc: ' .. (metadata.bcc or ''))
table.insert(edit_lines, 'Subject: ' .. (metadata.subject or ''))
table.insert(edit_lines, '') -- Empty line between headers and body
```

### 2. Autoread Trigger Chain

The reload is triggered by this sequence:

1. **Global autoread enabled** (`lua/neotex/config/options.lua` line 75):
   ```lua
   autoread = true,  -- Auto-reload files when changed externally
   ```

2. **Checktime on events** (`lua/neotex/config/autocmds.lua` lines 89-97):
   ```lua
   api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
     pattern = "*",
     callback = function()
       if vim.o.autoread and vim.fn.getcmdwintype() == '' then
         vim.cmd('silent! checktime')
       end
     end,
   })
   ```

3. **FileChangedShell handler** (`lua/neotex/config/autocmds.lua` lines 68-84):
   ```lua
   api.nvim_create_autocmd("FileChangedShell", {
     pattern = "*",
     callback = function(args)
       -- File was modified - reload silently
       vim.v.fcs_choice = "reload"
     end,
   })
   ```

### 3. Autosave Timing

The autosave runs every 5 seconds by default (`ui/email_composer.lua` lines 161-189):
```lua
M.config = {
  auto_save_interval = 5,  -- 5 seconds
}

autosave_timers[buf] = vim.fn.timer_start(
  M.config.auto_save_interval * 1000,
  function()
    if vim.api.nvim_buf_is_valid(buf) and
       vim.api.nvim_buf_get_option(buf, 'modified') then
      M.save_draft(buf, 'auto')
    end
  end,
  { ['repeat'] = -1 }
)
```

### 4. Buffer Type Configuration

The compose buffer is created as a normal file buffer (`buftype = ''`) in `data/drafts.lua` line 165:
```lua
vim.api.nvim_buf_set_option(buf, 'buftype', '')
```

This allows Neovim's autoread to apply, unlike other Himalaya buffers (sidebar, preview, reader) which use `buftype = 'nofile'`.

### 5. Save Reconstructs Full MIME

When saving, `reconstruct_mime_email()` (lines 204-317) rebuilds the full MIME structure:
- Adds MIME-Version header if missing
- Adds Date header (always updated to current time)
- Preserves X-Himalaya-Account
- Adds Content-Type header
- Maintains proper header ordering

## Root Cause Summary

The bug occurs because:
1. Draft is created with full MIME headers on disk but simplified view in buffer
2. Autosave writes full MIME content to disk every 5 seconds
3. Any event that triggers `checktime` (window focus, buffer enter) causes Neovim to detect the file changed
4. `FileChangedShell` autocmd reloads the buffer with full MIME content from disk
5. User sees sudden header expansion and cursor displacement

## Recommendations

### Option A: Disable Autoread for Compose Buffers (Recommended)
Add to compose buffer setup:
```lua
vim.api.nvim_buf_set_option(buf, 'autoread', false)
```

**Pros**: Simple, targeted fix, preserves global autoread for other buffers
**Cons**: None significant

### Option B: Use buftype='acwrite'
Change buffer type to trigger custom write behavior without file association:
```lua
vim.api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
```

**Pros**: More semantically correct for a buffer with custom write behavior
**Cons**: May affect other file-related functionality

### Option C: Synchronize File and Buffer Format
Write simplified headers to disk (same as buffer display), only add MIME headers at send time.

**Pros**: Eliminates format mismatch entirely
**Cons**: More complex, may affect draft interoperability with other email clients

### Option D: Handle FileChangedShell for Mail Buffers
Add pattern exception in the FileChangedShell autocmd for mail buffers:
```lua
if vim.bo[args.buf].filetype == 'mail' then
  vim.v.fcs_choice = ""  -- Ignore change
  return
end
```

**Pros**: Targeted to mail filetype
**Cons**: Couples autocmds.lua with Himalaya implementation

## Implementation Approach

**Recommended**: Option A (disable autoread for compose buffers)

Location: `lua/neotex/plugins/tools/himalaya/data/drafts.lua`, after line 167 in `M.create()`:
```lua
vim.api.nvim_buf_set_option(buf, 'modified', false)
-- Disable autoread to prevent buffer reload when autosave writes full MIME headers
vim.bo[buf].autoread = false
```

Also add in `M.open()` after line 605.

## Decisions

1. **Decision**: Use buffer-local autoread disable rather than buftype change
   - Rationale: Minimal impact on existing functionality, compose buffers need to behave like normal file buffers for write operations

2. **Decision**: Do not change the dual-format architecture
   - Rationale: Full MIME headers on disk are needed for Maildir compatibility and email client interoperability

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| User manually runs :e! | Low | Minor (headers shown) | Document behavior |
| Other plugins triggering checktime | Low | Minor | autoread=false handles this |
| Maildir sync conflicts | Very Low | Minor | File is already saved before sync |

## Appendix

### Search Queries Used
- Local grep: `himalaya`, `Mime-Version`, `Content-Type`, `X-Himalaya`, `autoread`, `checktime`, `FileChangedShell`
- Web search: "himalaya.nvim email compose buffer reload headers change cursor jump"
- Web search: "neovim mail plugin compose buffer autoread checktime prevent reload"

### References
- `lua/neotex/plugins/tools/himalaya/data/drafts.lua` - Draft manager with dual format
- `lua/neotex/plugins/tools/himalaya/ui/email_composer.lua` - Compose UI and autosave
- `lua/neotex/config/options.lua` - Global autoread setting
- `lua/neotex/config/autocmds.lua` - FileChangedShell and checktime handlers
- [Neovim autoread documentation](https://neovim.io/doc/user/options.html#'autoread')
- [Neovim buffer options](https://neovim.io/doc/user/options.html#'buftype')

### Files to Modify
1. `lua/neotex/plugins/tools/himalaya/data/drafts.lua`
   - Add `vim.bo[buf].autoread = false` in `M.create()` (after line 167)
   - Add `vim.bo[buf].autoread = false` in `M.open()` (after line 605)

### Testing Strategy
1. Create new email with :HimalayaWrite
2. Start typing in body
3. Wait for autosave (5 seconds)
4. Verify cursor position unchanged
5. Verify headers remain simplified
6. Test reply workflow
7. Test forward workflow
