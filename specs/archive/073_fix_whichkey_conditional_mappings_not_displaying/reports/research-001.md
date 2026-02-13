# Research Report: Task #73

**Task**: 73 - fix_whichkey_conditional_mappings_not_displaying
**Started**: 2026-02-12T00:00:00Z
**Completed**: 2026-02-12T00:30:00Z
**Effort**: 1-2 hours
**Dependencies**: None
**Sources/Inputs**: which-key.nvim GitHub, local configuration analysis
**Artifacts**: specs/073_fix_whichkey_conditional_mappings_not_displaying/reports/research-001.md
**Standards**: report-format.md

## Executive Summary

- The `cond` parameter in which-key.nvim v3 is evaluated **only once** at registration time, not dynamically at display time
- This is a known limitation documented in [GitHub Issue #880](https://github.com/folke/which-key.nvim/issues/880), closed as "not planned"
- The solution is to use the **`buffer = 0`** option with `wk.add()` in ftplugin files, as demonstrated by the existing `after/ftplugin/tex.lua` in this codebase
- Compose-specific keybindings should be registered per-buffer when the compose buffer is created

## Context and Scope

The task describes compose-specific keybindings (`<leader>me`, `<leader>md`, `<leader>mq`) not appearing in the which-key menu when composing emails, despite the `is_mail()` helper returning true and filetype being correct.

The current implementation in `which-key.lua` (lines 547-551):
```lua
wk.add({
  { "<leader>me", "<cmd>HimalayaSend<CR>", desc = "send email", icon = "", cond = is_mail },
  { "<leader>md", "<cmd>HimalayaSaveDraft<CR>", desc = "save draft", icon = "", cond = is_mail },
  { "<leader>mq", "<cmd>HimalayaDiscard<CR>", desc = "quit/discard", icon = "", cond = is_mail },
})
```

## Findings

### Root Cause: `cond` is Evaluated Once

The which-key.nvim plugin evaluates the `cond` parameter **only once** when mappings are registered, not dynamically each time the popup appears.

From [GitHub Issue #880](https://github.com/folke/which-key.nvim/issues/880):
> "The `cond` parameter is evaluated only once which, in my opinion, greatly reduces its usefulness."

The issue was closed as "Not Planned" on January 10, 2025, indicating this behavior will not change.

### Why Current Implementation Fails

1. `wk.add()` is called during which-key setup (plugin config phase)
2. At that time, no buffer is open with filetype "mail"
3. `is_mail()` returns `false` because `vim.bo.filetype` is not "mail"
4. The condition is cached as `false` and never re-evaluated
5. When a compose buffer is opened later, the mappings remain hidden

### Working Solution: Buffer-Local Registration

The existing `after/ftplugin/tex.lua` demonstrates the correct pattern:

```lua
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>l", group = "latex", icon = "", buffer = 0 },
    { "<leader>la", "<cmd>lua PdfAnnots()<CR>", desc = "annotate", icon = "", buffer = 0 },
    -- ...
  })
end
```

Key insight: **`buffer = 0`** means "current buffer" - the mapping is registered only for that specific buffer and appears only when that buffer is active.

### Alternative Approaches Considered

1. **FileType autocommand with `buffer = 0`** - Requires creating `after/ftplugin/mail.lua` or modifying the himalaya compose setup
2. **Function-wrapped keybindings** - Use a function that checks filetype and executes action, but this doesn't affect which-key display
3. **Buffer-local registration at buffer creation time** - Modify `email_composer.lua` to register which-key mappings when compose buffer is created

### Recommended Approach

Option 3 (buffer-local registration at buffer creation) is best because:
- Compose buffers are already created programmatically via `email_composer.create_compose_buffer()`
- The compose setup function already exists (`M.setup_compose_keymaps(buf)`)
- No need for ftplugin file for "mail" filetype (would affect non-himalaya mail buffers)

### Implementation Location

Modify `lua/neotex/plugins/tools/himalaya/ui/email_composer.lua`:

In the `setup_compose_keymaps(buf)` function (line 134), add which-key buffer-local registration:

```lua
function M.setup_compose_keymaps(buf)
  local opts = { buffer = buf, noremap = true, silent = true }

  -- Register buffer-local which-key mappings
  local ok_wk, wk = pcall(require, "which-key")
  if ok_wk then
    wk.add({
      { "<leader>me", "<cmd>HimalayaSend<CR>", desc = "send email", icon = "", buffer = buf },
      { "<leader>md", "<cmd>HimalayaSaveDraft<CR>", desc = "save draft", icon = "", buffer = buf },
      { "<leader>mq", "<cmd>HimalayaDiscard<CR>", desc = "quit/discard", icon = "", buffer = buf },
    })
  end

  -- Rest of existing function...
end
```

Then remove the `cond = is_mail` mappings from `which-key.lua` (lines 547-551) since they're now handled per-buffer.

### What to Remove from which-key.lua

Lines 546-551 should be removed:
```lua
-- Compose buffer keymaps (visible only when composing email - filetype "mail")
wk.add({
  { "<leader>me", "<cmd>HimalayaSend<CR>", desc = "send email", icon = "", cond = is_mail },
  { "<leader>md", "<cmd>HimalayaSaveDraft<CR>", desc = "save draft", icon = "", cond = is_mail },
  { "<leader>mq", "<cmd>HimalayaDiscard<CR>", desc = "quit/discard", icon = "", cond = is_mail },
})
```

### Similar Pattern for Email Preview

The same pattern should be applied to email preview keymaps (lines 553-583) that use `cond = is_himalaya_email`. Those should be moved to the relevant setup function.

## Decisions

1. Use `buffer = buf` pattern (not `buffer = 0`) when registering in Lua functions, since `buf` is the specific buffer number
2. Keep registration in `email_composer.lua` rather than creating a new ftplugin file
3. Remove `cond`-based mappings from which-key.lua to avoid confusion

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Duplicate mappings if old code not removed | Implementation plan must include removal of cond-based mappings |
| Mappings not registered if which-key not loaded | Already protected by `pcall(require, "which-key")` |
| Performance with many compose buffers | Minimal - registration is lightweight |

## Appendix

### Search Queries Used
- "which-key.nvim v3 cond parameter conditional mappings documentation 2026"
- "which-key.nvim cond not working conditional mappings not showing issue GitHub 2025 2026"
- "wk.add which-key v3 buffer option filetype ftplugin 2025"

### References
- [which-key.nvim GitHub Repository](https://github.com/folke/which-key.nvim)
- [Issue #880: Feature request for dynamic cond evaluation](https://github.com/folke/which-key.nvim/issues/880) - Closed as "Not Planned"
- [Issue #135: Keymapping based on file type](https://github.com/folke/which-key.nvim/issues/135) - Original discussion of filetype-based mappings
- [Issue #165: Display mappings on specific filetype](https://github.com/folke/which-key.nvim/issues/165) - Buffer-local solution
- [Discussion #805: Buffer/filetype specific key configuration](https://github.com/folke/which-key.nvim/discussions/805) - Community workarounds
- [which-key.nvim Documentation](https://github.com/folke/which-key.nvim/blob/main/doc/which-key.nvim.txt)
