# Research Report: Task #84 (Additional)

**Task**: 84 - Fix Himalaya email composition UX issue with disruptive header changes
**Started**: 2026-02-13T00:00:00Z
**Completed**: 2026-02-13T01:00:00Z
**Effort**: 1-2 hours (implementation)
**Dependencies**: research-001.md findings
**Sources/Inputs**: Neovim autoread documentation, local codebase analysis, FileChangedShell behavior
**Artifacts**: - specs/084_fix_disruptive_header_changes_himalaya_email/reports/research-002.md
**Standards**: report-format.md

## Executive Summary

- The "File changed on disk. Buffer reloaded." message and data loss stem from a race condition between autosave and FileChangedShell
- When autosave writes to disk, the buffer's `modified` flag is cleared. If another checktime occurs before the user makes new edits, Neovim sees an unmodified buffer with a changed file and reloads automatically
- The root cause is that `vim.v.fcs_choice = "reload"` unconditionally reloads ALL buffers, including mail buffers with unsaved changes that occur between autosave and reload
- Solution: Either (A) disable autoread per research-001.md, or (B) check modified flag in FileChangedShell before setting fcs_choice to reload

## Context & Scope

### Expanded Problem Description
Users report two related but distinct symptoms:
1. **Header format changes** (covered in research-001.md): Simplified headers transform to full MIME headers
2. **"File changed on disk" messages with data loss**: Users lose unsaved changes when the buffer is reloaded

This additional research focuses on the second symptom and how it relates to the first.

### Investigation Questions
1. What external process modifies the draft file?
2. Why are unsaved buffer changes lost on reload?
3. How to prevent data loss when file changes on disk?

## Findings

### 1. Process Modifying Draft Files

The draft file is modified by **the autosave mechanism within the plugin itself**, not by an external process like mbsync or IMAP sync.

**Evidence from `email_composer.lua` (lines 161-177)**:
```lua
-- Create new timer
autosave_timers[buf] = vim.fn.timer_start(
  M.config.auto_save_interval * 1000,  -- 5 seconds default
  function()
    if vim.api.nvim_buf_is_valid(buf) and
       vim.api.nvim_buf_get_option(buf, 'modified') then
      M.save_draft(buf, 'auto')
    end
  end,
  { ['repeat'] = -1 }
)
```

**Evidence from `drafts.lua` (lines 331-351)**:
```lua
-- Save directly to file
local file = io.open(filepath, 'w')
if file then
  file:write(content)
  file:close()
end

-- Touch the file to update modification time
vim.loop.fs_utime(filepath, os.time(), os.time())

-- Mark buffer as unmodified
vim.api.nvim_buf_set_option(buffer, 'modified', false)
```

The autosave:
1. Writes full MIME content to disk (different from simplified buffer content)
2. Explicitly updates file modification time via `fs_utime()`
3. Clears the buffer's `modified` flag

### 2. Why Unsaved Changes Are Lost

The data loss occurs through this sequence:

```
T=0.0s: User is typing in compose buffer (modified=true)
T=5.0s: Autosave triggers
        - Writes current content to disk (full MIME format)
        - Calls fs_utime() to update mtime
        - Sets buffer modified=false
T=5.1s: User continues typing (modified=true again)
T=5.5s: FocusGained/BufEnter triggers checktime
        - Neovim compares file mtime vs internal timestamp
        - File mtime is newer (changed at T=5.0s)
        - FileChangedShell fires
T=5.5s: FileChangedShell autocmd in autocmds.lua
        - Sets vim.v.fcs_choice = "reload" unconditionally
        - Buffer is reloaded from disk
        - Content reverts to T=5.0s state
        - User loses changes made between T=5.0s and T=5.5s
```

**Critical code in `autocmds.lua` (lines 68-84)**:
```lua
api.nvim_create_autocmd("FileChangedShell", {
  pattern = "*",
  callback = function(args)
    local bufname = vim.api.nvim_buf_get_name(args.buf)

    -- Check if file still exists
    if vim.fn.filereadable(bufname) == 0 then
      vim.bo[args.buf].modified = false
      vim.v.fcs_choice = ""
    else
      -- File was modified - reload silently
      vim.v.fcs_choice = "reload"  -- PROBLEM: Unconditional reload
    end
  end,
})
```

### 3. Neovim's Default Protection vs Current Override

According to [Neovim documentation](https://neovim.io/doc/user/editing.html):
> "If there are no changes in the buffer and 'autoread' is set, the buffer is reloaded. Otherwise, you are offered the choice of reloading the file."

However, the current FileChangedShell autocmd **overrides** this protection by setting `fcs_choice = "reload"` unconditionally, bypassing the modified-buffer check.

Per [Neovim autocmd documentation](https://neovim.io/doc/user/autocmd.html):
> "If a FileChangedShell autocommand exists the warning message and prompt is not given."

This means the autocmd suppresses Neovim's built-in "file changed" dialog that would normally ask the user before reloading a modified buffer.

### 4. The Race Condition Window

The vulnerability exists in the time window between:
- When autosave clears `modified=false`
- When the user makes their next edit (sets `modified=true`)

During this window (which can be as short as a few hundred milliseconds), any `checktime` call will find:
- `autoread=true` (global setting)
- `modified=false` (just cleared by autosave)
- File mtime newer than buffer timestamp

Result: Automatic reload without prompt.

### 5. Triggers for checktime

Multiple events can trigger `checktime` during the vulnerable window:

1. **FocusGained** (lines 89-97 in autocmds.lua):
   - Triggered by switching to another window/app and back
   - Common during email composition when checking reference material

2. **BufEnter** (same autocmd):
   - Triggered by switching between buffers
   - Common when checking other emails while composing

3. **WezTerm OSC 7** (lines 131-140 in autocmds.lua):
   - Triggers BufEnter events for tab title updates

### 6. Why mbsync Is Not The Cause

Initial hypothesis was that mbsync might be modifying draft files. Analysis confirms this is not the case:

1. **Drafts are local-only**: The drafts folder is in local Maildir (`~/Mail/Gmail/.Drafts/`)
2. **mbsync sync direction**: mbsync typically syncs new/changed messages FROM remote TO local, not the reverse for drafts
3. **Timing correlation**: The reload happens immediately after autosave (5 second interval matches user reports)

## Root Cause Summary

The data loss is a **self-inflicted race condition**:

1. Plugin's autosave writes file and clears `modified` flag
2. Global autocmd triggers `checktime` on common events
3. Plugin's FileChangedShell handler unconditionally reloads
4. Changes made after autosave but before checktime are lost

The key insight: The plugin is triggering the reload of its own buffers because:
- It modifies files directly (autosave)
- It doesn't exempt its buffers from global reload behavior

## Recommendations

### Option A: Disable Autoread for Compose Buffers (From research-001.md)

Add to `drafts.lua` after buffer creation:
```lua
vim.bo[buf].autoread = false
```

**Pros**:
- Single point of fix
- Addresses both header change and data loss issues
- Buffer-local, doesn't affect other buffers

**Cons**:
- None significant

### Option B: Check Modified Flag in FileChangedShell

Modify `autocmds.lua` to respect the modified flag:
```lua
api.nvim_create_autocmd("FileChangedShell", {
  pattern = "*",
  callback = function(args)
    local bufname = vim.api.nvim_buf_get_name(args.buf)

    if vim.fn.filereadable(bufname) == 0 then
      vim.bo[args.buf].modified = false
      vim.v.fcs_choice = ""
    elseif vim.bo[args.buf].modified then
      -- Buffer has unsaved changes - don't auto-reload
      vim.v.fcs_choice = ""  -- Let Neovim prompt the user
    else
      vim.v.fcs_choice = "reload"
    end
  end,
})
```

**Pros**:
- Protects ALL buffers from data loss, not just mail
- More aligned with Neovim's default behavior

**Cons**:
- Wider impact, may affect workflows that rely on silent reload
- User will see prompt for all modified buffers when files change

### Option C: Filetype-Specific Exception in FileChangedShell

```lua
api.nvim_create_autocmd("FileChangedShell", {
  pattern = "*",
  callback = function(args)
    local bufname = vim.api.nvim_buf_get_name(args.buf)
    local filetype = vim.bo[args.buf].filetype

    if vim.fn.filereadable(bufname) == 0 then
      vim.bo[args.buf].modified = false
      vim.v.fcs_choice = ""
    elseif filetype == 'mail' then
      -- Don't auto-reload mail buffers (handled by Himalaya)
      vim.v.fcs_choice = ""
    else
      vim.v.fcs_choice = "reload"
    end
  end,
})
```

**Pros**:
- Targeted fix for mail buffers only
- Preserves existing behavior for other file types

**Cons**:
- Couples global autocmd with plugin-specific behavior

### Option D: Delay Checktime After Autosave

Have autosave temporarily disable the checktime trigger:
```lua
-- In email_composer.lua autosave callback
vim.b[buf].himalaya_skip_checktime = true
M.save_draft(buf, 'auto')
vim.defer_fn(function()
  if vim.api.nvim_buf_is_valid(buf) then
    vim.b[buf].himalaya_skip_checktime = false
  end
end, 500)
```

**Pros**:
- Very targeted fix
- Handles the race condition directly

**Cons**:
- More complex
- Requires coordination between multiple modules

## Recommended Solution

**Primary: Option A** (disable autoread for compose buffers) as recommended in research-001.md.

This single change addresses both issues:
1. Prevents header format changes (no reload means buffer stays simplified)
2. Prevents data loss (no automatic reload at all)

**Secondary consideration**: Option B should be evaluated independently as a general improvement to prevent data loss across all buffers, not just for this specific issue.

## Decisions

1. **Decision**: Primary fix is Option A (buffer-local autoread=false)
   - Rationale: Single change solves both reported symptoms
   - Location: `drafts.lua` lines 167 (in M.create) and 605 (in M.open)

2. **Decision**: Document that silent reload (Option B consideration) may be revisited
   - Rationale: Current FileChangedShell behavior has broader data loss implications
   - This is a separate enhancement, not blocking the current fix

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| External changes to draft file not detected | Low | Minor | User can manually reload with :e! if needed |
| Other Himalaya modules expect autoread | Very Low | Low | Review other modules for autoread assumptions |
| Autosave still writes full MIME to disk | N/A | None | This is expected behavior, just won't trigger reload |

## Appendix

### Search Queries Used
- Web search: "neovim autoread buffer modified flag reload loses changes vim.v.fcs_choice"
- Web search: "neovim FileChangedShell buffer modified changes lost autoread reload behavior"
- Local grep: `autoread|checktime|FileChangedShell|fcs_choice`

### References
- [Neovim Editing Documentation](https://neovim.io/doc/user/editing.html) - autoread and checktime behavior
- [Neovim Autocmd Documentation](https://neovim.io/doc/user/autocmd.html) - FileChangedShell and v:fcs_choice
- [Vim Tips Wiki - Reload file without losing undo](https://vim.fandom.com/wiki/Reload_file_without_losing_undo_history)
- `lua/neotex/plugins/tools/himalaya/ui/email_composer.lua` - Autosave timer implementation
- `lua/neotex/plugins/tools/himalaya/data/drafts.lua` - Draft save and buffer management
- `lua/neotex/config/autocmds.lua` - FileChangedShell and checktime autocmds
- `lua/neotex/config/options.lua` - Global autoread setting

### Files to Modify

Primary fix (same as research-001.md):
1. `lua/neotex/plugins/tools/himalaya/data/drafts.lua`
   - Add `vim.bo[buf].autoread = false` in `M.create()` after line 167
   - Add `vim.bo[buf].autoread = false` in `M.open()` after line 605

### Testing Strategy

1. Open Himalaya and create a new email with :HimalayaWrite
2. Type several lines of content in the body
3. Wait for autosave (5 seconds)
4. Continue typing more content
5. Switch to another window and back (triggers FocusGained)
6. Verify:
   - No "File changed on disk" message appears
   - All typed content is preserved
   - Headers remain in simplified format
7. Manually run :e! to verify external reload still works when explicitly requested
8. Test reply and forward workflows with same verification steps
