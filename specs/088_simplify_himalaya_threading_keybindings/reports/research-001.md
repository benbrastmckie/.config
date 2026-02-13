# Research Report: Task #88

**Task**: 88 - simplify_himalaya_threading_keybindings
**Started**: 2026-02-13T00:00:00Z
**Completed**: 2026-02-13T00:05:00Z
**Effort**: 1-2 hours
**Dependencies**: None
**Sources/Inputs**: Local configuration files, existing keybinding patterns
**Artifacts**: - specs/088_simplify_himalaya_threading_keybindings/reports/research-001.md
**Standards**: report-format.md, neovim-lua.md

## Executive Summary

- Current implementation has 6 threading keybindings: `<Tab>`, `zo`, `zc`, `zR`, `zM`, `gT`
- Task requires reducing to 2 keybindings: `<Tab>` (single thread toggle), `<S-Tab>` (toggle all threads)
- `<S-Tab>` is currently mapped to `<Nop>` in setup_buffer_keymaps(), needs to be remapped
- New toggle_all function needed in email_list.lua to cycle between expand_all and collapse_all
- Help menu (folder_help.lua) needs significant simplification

## Context and Scope

The himalaya email client plugin currently has verbose threading keybindings inherited from vim fold conventions (zo, zc, zR, zM) plus custom mappings (Tab, gT). This task simplifies the interface to just two keybindings for a more streamlined user experience.

## Findings

### Current Threading Keybindings (ui.lua lines 362-414)

| Key | Function | Location |
|-----|----------|----------|
| `<Tab>` | toggle_current_thread() | Line 364-369 |
| `zo` | expand_current_thread() | Line 372-377 |
| `zc` | collapse_current_thread() | Line 380-385 |
| `zR` | expand_all_threads() + refresh | Line 388-394 |
| `zM` | collapse_all_threads() + refresh | Line 397-403 |
| `gT` | toggle_threading() | Line 406-414 |

### Current Tab/S-Tab Handling (ui.lua lines 140-144)

Both `<Tab>` and `<S-Tab>` are disabled in setup_buffer_keymaps() before filetype-specific keymaps are applied:

```lua
-- Disable tab cycling in all Himalaya buffers
keymap('n', '<Tab>', '<Nop>', opts)
keymap('n', '<S-Tab>', '<Nop>', opts)
```

Then `<Tab>` is remapped in setup_email_list_keymaps() at line 364.

### Current Help Menu Content (folder_help.lua lines 87-96)

```lua
local base_threading = {
  "Threading:",
  "  <Tab>     - Toggle thread expand",
  "  zo        - Expand thread",
  "  zc        - Collapse thread",
  "  zR        - Expand all threads",
  "  zM        - Collapse all threads",
  "  gT        - Toggle threading on/off",
  ""
}
```

### Existing Threading Functions (email_list.lua)

| Function | Line | Description |
|----------|------|-------------|
| M.toggle_threading() | 127-134 | Enable/disable threading feature entirely |
| M.expand_all_threads() | 157-164 | Expand all threads in current view |
| M.collapse_all_threads() | 167-170 | Collapse all threads |
| M.toggle_current_thread() | 186-209 | Toggle single thread under cursor |
| M.expand_current_thread() | 211-224 | Expand single thread |
| M.collapse_current_thread() | 227-240 | Collapse single thread |

### get_keybinding() Configuration (ui.lua lines 613-619)

The keybinding reference table also needs updating:

```lua
-- Threading keymaps (Task #81)
toggle_thread = '<Tab>',
expand_thread = 'zo',
collapse_thread = 'zc',
expand_all_threads = 'zR',
collapse_all_threads = 'zM',
toggle_threading = 'gT',
```

## Implementation Approach

### 1. Create toggle_all_threads Function

A new function `M.toggle_all_threads()` is needed in email_list.lua to intelligently toggle between expanded and collapsed states:

```lua
function M.toggle_all_threads()
  local thread_order = state.get('email_list.thread_order', {})
  local any_expanded = false

  -- Check if any threads are currently expanded
  for _, normalized_subject in ipairs(thread_order) do
    if expanded_threads[normalized_subject] then
      any_expanded = true
      break
    end
  end

  -- Toggle: if any expanded, collapse all; otherwise expand all
  if any_expanded then
    M.collapse_all_threads()
  else
    M.expand_all_threads()
  end

  M.refresh_email_list()
end
```

### 2. Update Keymaps in setup_email_list_keymaps()

**Remove** (lines 372-414):
- `zo` keymap
- `zc` keymap
- `zR` keymap
- `zM` keymap
- `gT` keymap

**Add** after the `<Tab>` keymap:
```lua
-- S-Tab toggles all threads expand/collapse
keymap('n', '<S-Tab>', function()
  local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
  if ok and email_list.toggle_all_threads then
    email_list.toggle_all_threads()
  end
end, vim.tbl_extend('force', opts, { desc = 'Toggle all threads expand/collapse' }))
```

### 3. Update setup_buffer_keymaps()

The `<S-Tab>` line at 142 should NOT disable `<S-Tab>` since it will now be used:

Change line 142 from:
```lua
keymap('n', '<S-Tab>', '<Nop>', opts)
```
to:
```lua
-- <S-Tab> is used for toggle all threads in email list
-- Don't disable it here
```

Or simply remove line 142 entirely and let the filetype-specific setup handle it.

### 4. Update Help Menu (folder_help.lua)

Replace lines 87-96:
```lua
local base_threading = {
  "Threading:",
  "  <Tab>     - Toggle thread expand/collapse",
  "  <S-Tab>   - Toggle all threads",
  ""
}
```

### 5. Update get_keybinding() Reference Table

Replace lines 613-619:
```lua
-- Threading keymaps (Task #88 - simplified)
toggle_thread = '<Tab>',
toggle_all_threads = '<S-Tab>',
```

## Files to Modify

1. **lua/neotex/plugins/tools/himalaya/ui/email_list.lua**
   - Add `M.toggle_all_threads()` function after `M.collapse_all_threads()`

2. **lua/neotex/plugins/tools/himalaya/config/ui.lua**
   - Remove `zo`, `zc`, `zR`, `zM`, `gT` keymaps from setup_email_list_keymaps() (lines 372-414)
   - Add `<S-Tab>` keymap after `<Tab>` keymap
   - Update or remove `<S-Tab>` `<Nop>` mapping in setup_buffer_keymaps() (line 142)
   - Update get_keybinding() threading section (lines 613-619)

3. **lua/neotex/plugins/tools/himalaya/ui/folder_help.lua**
   - Simplify base_threading section (lines 87-96)

## Decisions

1. **Toggle logic**: Use "any expanded -> collapse all, else expand all" for S-Tab behavior
2. **Remove gT**: The toggle threading on/off feature is being removed to simplify interface
3. **Keep Tab behavior**: Single thread toggle under cursor remains unchanged
4. **No deprecation period**: Clean removal of old keybindings per clean-break development standard

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Users accustomed to vim fold keys | Document change in commit message; behavior is still accessible via two keys |
| Loss of threading toggle (gT) | Feature can be re-added later if needed; simplification is intentional |
| S-Tab conflicts in other modes | Only applies to himalaya-list filetype; insert mode S-Tab preserved |

## Appendix

### Search Queries Used
- Local file search: ui.lua, folder_help.lua, email_list.lua
- Grep patterns: threading function signatures, keybinding definitions

### References
- Task #81: Original threading implementation
- lua/neotex/plugins/tools/himalaya/ui/email_list.lua: Threading functions
- lua/neotex/plugins/tools/himalaya/config/ui.lua: Keybinding setup
- lua/neotex/plugins/tools/himalaya/ui/folder_help.lua: Help content
