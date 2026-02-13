# Research Report: Task #85

**Task**: Fix FileChangedShell autocmd to respect buffer-local autoread setting
**Date**: 2026-02-13
**Focus**: FileChangedShell autocmd autoread buffer-local settings

## Summary

The global FileChangedShell autocmd unconditionally reloads all changed files, bypassing buffer-local `autoread = false` settings. The fix requires checking `vim.bo[args.buf].autoread` before setting `vim.v.fcs_choice = "reload"`. This is a minimal 2-line change that preserves existing behavior for most buffers while respecting explicit autoread disabling.

## Findings

### 1. Current FileChangedShell Implementation

**Location**: `lua/neotex/config/autocmds.lua` lines 68-84

```lua
api.nvim_create_autocmd("FileChangedShell", {
  pattern = "*",
  callback = function(args)
    local bufname = vim.api.nvim_buf_get_name(args.buf)

    -- Check if file still exists
    if vim.fn.filereadable(bufname) == 0 then
      -- File was deleted - mark as not modified and don't reload
      vim.bo[args.buf].modified = false
      vim.v.fcs_choice = ""
    else
      -- File was modified - reload silently
      vim.v.fcs_choice = "reload"  -- PROBLEM: unconditional reload
    end
  end,
})
```

**Issue**: The `else` branch unconditionally sets `fcs_choice = "reload"` without checking the buffer's autoread setting.

### 2. vim.v.fcs_choice Values

According to the [Neovim documentation](https://neovim.io/doc/user/vvars.html), `vim.v.fcs_choice` accepts:

| Value | Behavior |
|-------|----------|
| `"reload"` | Reload the buffer (fails if file deleted) |
| `"edit"` | Reload and detect fileformat/encoding options |
| `"ask"` | Prompt the user for action |
| `""` (empty) | Default; autocommand handles everything (no automatic action) |

For our use case:
- `"reload"` - Automatic reload (current default behavior)
- `""` - No reload (desired for `autoread = false` buffers)

### 3. vim.bo.autoread Behavior

The `autoread` option is **global-local** per [Neovim options documentation](https://neovim.io/doc/user/options.html):
- Has both a global value (`vim.go.autoread`) and buffer-local values (`vim.bo[buf].autoread`)
- New buffers inherit the global value
- Setting `vim.bo[buf].autoread = false` only affects that specific buffer

**Verified via headless test**:
```
Global autoread: true
Buffer autoread: false  (after vim.bo[buf].autoread = false)
```

### 4. Task 84 Implementation

Task 84 correctly disabled autoread for Himalaya compose buffers:

**In M.create() (line 168)**:
```lua
vim.bo[buf].autoread = false
```

**In M.open() (line 607)**:
```lua
vim.bo[buf].autoread = false
```

However, this is ineffective because the global FileChangedShell autocmd bypasses the autoread check entirely and forces reload via `fcs_choice = "reload"`.

### 5. FileChangedShell Priority

Per [Neovim autocmd documentation](https://neovim.io/doc/user/autocmd.html):

> "Note that if a FileChangedShell autocommand is defined you will not get a warning message or prompt. The autocommand is expected to handle this."

This confirms that our FileChangedShell autocmd takes complete responsibility for handling file changes. The standard autoread behavior is bypassed because we define this autocmd.

### 6. Correct Implementation Pattern

The autocmd should check buffer-local autoread before deciding to reload:

```lua
api.nvim_create_autocmd("FileChangedShell", {
  pattern = "*",
  callback = function(args)
    local bufname = vim.api.nvim_buf_get_name(args.buf)

    -- Check if file still exists
    if vim.fn.filereadable(bufname) == 0 then
      -- File was deleted - mark as not modified and don't reload
      vim.bo[args.buf].modified = false
      vim.v.fcs_choice = ""
    elseif vim.bo[args.buf].autoread == false then
      -- Buffer has autoread explicitly disabled - respect it
      vim.v.fcs_choice = ""
    else
      -- File was modified and autoread is enabled - reload silently
      vim.v.fcs_choice = "reload"
    end
  end,
})
```

### 7. Edge Cases

| Scenario | vim.bo.autoread | Expected fcs_choice |
|----------|-----------------|---------------------|
| Normal buffer (default) | true (inherited) | "reload" |
| Himalaya compose buffer | false (explicit) | "" |
| File deleted | any | "" |
| New buffer, never touched | true (inherited) | "reload" |

**Note on nil vs false**: When checking `vim.bo[args.buf].autoread`, Lua returns the buffer-local value if set, otherwise falls back to the global value. The comparison `== false` catches only explicitly disabled buffers.

## Recommendations

### Implementation (2 lines changed)

**File**: `lua/neotex/config/autocmds.lua`

**Change at line 79-81**:
```lua
-- Before (lines 79-81):
else
  -- File was modified - reload silently
  vim.v.fcs_choice = "reload"
end

-- After:
elseif vim.bo[args.buf].autoread == false then
  -- Buffer has autoread explicitly disabled - respect it
  vim.v.fcs_choice = ""
else
  -- File was modified and autoread is enabled - reload silently
  vim.v.fcs_choice = "reload"
end
```

### Verification

1. **Test autoread = false buffers**: Create a Himalaya compose buffer, make external changes, trigger checktime - verify no reload
2. **Test autoread = true buffers**: Normal file, external changes, trigger checktime - verify automatic reload
3. **Test deleted files**: Delete external file while buffer open - verify no crash, buffer marked unmodified

## Decisions

1. **Decision**: Check for explicit `autoread == false` rather than truthiness check
   - **Rationale**: `vim.bo[buf].autoread` returns the effective value (buffer-local if set, else global), so we need exact comparison to detect explicit disabling

2. **Decision**: Keep empty string `""` for no-reload, not `"ask"`
   - **Rationale**: `"ask"` would prompt the user, which defeats the purpose of silent compose buffers

3. **Decision**: Do not modify task 84's implementation
   - **Rationale**: Setting `vim.bo[buf].autoread = false` is the correct approach; the bug is in the FileChangedShell handler

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking other buffers with autoread = false | Very Low | Low | The fix respects explicit settings, which is correct behavior |
| Race condition in autoread check | Very Low | None | Reading vim.bo is synchronous |
| Performance impact | None | None | Single boolean check per FileChangedShell event |

## References

- [Neovim v:fcs_choice documentation](https://neovim.io/doc/user/vvars.html)
- [Neovim autoread option documentation](https://neovim.io/doc/user/options.html)
- [Neovim FileChangedShell autocmd documentation](https://neovim.io/doc/user/autocmd.html)
- Task 84 implementation summary: `specs/084_fix_disruptive_header_changes_himalaya_email/summaries/implementation-summary-20260213.md`

## Next Steps

1. Run `/plan 85` to create implementation plan with the 2-line fix
2. Implement the change in `lua/neotex/config/autocmds.lua`
3. Test with Himalaya compose workflow to verify fix
