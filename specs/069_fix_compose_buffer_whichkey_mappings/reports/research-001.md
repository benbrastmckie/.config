# Research Report: Task #69

**Task**: 69 - fix_compose_buffer_whichkey_mappings
**Started**: 2026-02-11T12:00:00Z
**Completed**: 2026-02-11T12:30:00Z
**Effort**: 1-2 hours
**Dependencies**: None
**Sources/Inputs**: which-key.nvim documentation, GitHub discussions, existing codebase patterns
**Artifacts**: - specs/069_fix_compose_buffer_whichkey_mappings/reports/research-001.md
**Standards**: report-format.md, subagent-return.md

## Executive Summary

- The `cond` parameter in which-key.nvim does NOT dynamically update popup display based on buffer context; it only controls whether a mapping is active, not its visibility in the popup at render time
- The recommended solution from which-key's maintainer (folke) is to use `vim.keymap.set()` with `buffer = bufnr` parameter and `desc` field for buffer-local keymaps
- Which-key automatically discovers and displays buffer-local keymaps with `desc` fields, so no separate which-key registration is needed
- The existing `config/ui.lua` pattern using `setup_compose_keymaps()` should be extended to include the leader mappings

## Context and Scope

### Problem Statement

Compose buffer which-key mappings (`<leader>me`, `<leader>md`, `<leader>mq`) don't appear in the which-key popup even though `is_compose_buffer()` returns true in compose buffers.

### Current Implementation (which-key.lua lines 551-557)

```lua
-- Compose-specific 2-letter mappings (only visible in compose buffers)
wk.add({
  { "<leader>me", "<cmd>HimalayaSend<CR>", desc = "send email", icon = "...", cond = is_compose_buffer },
  { "<leader>md", "<cmd>HimalayaSaveDraft<CR>", desc = "save draft", icon = "...", cond = is_compose_buffer },
  { "<leader>mq", "<cmd>HimalayaDiscard<CR>", desc = "quit/discard", icon = "...", cond = is_compose_buffer },
})
```

### Root Cause

The `cond` parameter determines whether a mapping is **enabled/active**, not whether it appears in the which-key popup. According to which-key documentation, `cond` is defined as "(boolean|fun():boolean) condition to enable the mapping" - evaluated for functionality, not popup visibility.

When which-key renders its popup, it shows all registered mappings that match the current key prefix. The `cond` function may filter out the **action** but not the **display** entry. More critically, the popup rendering happens before the `cond` check resolves in the buffer context.

## Findings

### 1. How which-key's `cond` Parameter Works

From the [which-key.nvim GitHub](https://github.com/folke/which-key.nvim) documentation:

- `cond` is described as "condition to enable the mapping"
- It controls whether a mapping is **functional**, not its **popup visibility**
- The documentation states that `desc`, `group`, and `icon` are "evaluated every time the popup is shown" but does not say the same for `cond`
- The `cond` parameter's evaluation timing appears to be at mapping execution time, not popup render time

**Key Finding**: Using `cond` for conditional popup display is a misunderstanding of the API. The `cond` parameter is designed for disabling mappings (like during certain modes), not for context-aware popup menus.

### 2. Maintainer-Recommended Solution

From [GitHub Issue #241](https://github.com/folke/which-key.nvim/issues/241), folke (the maintainer) recommends:

> "Rather than relying solely on which-key, use Neovim's native `vim.keymap.set` function directly. which-key will automatically recognize and display descriptions (`desc` field) defined in those native keymaps."

Additionally, the `buffer=0` parameter is mentioned as a way to scope mappings to specific buffers.

### 3. Community Best Practices

From [GitHub Discussion #805](https://github.com/folke/which-key.nvim/discussions/805):

The most reliable approach for buffer-specific which-key mappings is to:
1. Use `nvim/after/ftplugin/[filetype].lua` files, OR
2. Use autocommands with `buffer = bufnr` parameter

The pattern is:
```lua
vim.keymap.set("n", "<leader>x", function() ... end, {
  buffer = bufnr,
  desc = "Action description"
})
```

which-key automatically discovers buffer-local keymaps with `desc` fields and displays them in the popup.

### 4. Existing Pattern in Himalaya Codebase

The codebase already has a pattern in `lua/neotex/plugins/tools/himalaya/config/ui.lua`:

```lua
function M.setup_compose_keymaps(bufnr)
  local keymap = vim.keymap.set
  local opts = { buffer = bufnr, silent = true }

  -- Save draft
  keymap('n', '<C-d>', function()
    local ok, composer = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_composer')
    if ok and composer.save_draft then
      composer.save_draft()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Save draft' }))

  -- Discard
  keymap('n', '<C-q>', function() ... end, vim.tbl_extend('force', opts, { desc = 'Discard email' }))

  -- Attach file
  keymap('n', '<C-a>', function() ... end, vim.tbl_extend('force', opts, { desc = 'Attach file' }))
end
```

This function is called from `email_composer.lua`:
```lua
function M.create_compose_buffer(opts)
  ...
  -- Setup buffer-local keymaps
  M.setup_compose_keymaps(buf)
  ...
end
```

### 5. Himalaya's Multi-Environment Architecture

The plugin manages 5 environments:
1. **Sidebar** (himalaya-sidebar filetype) - Folder navigation
2. **Email List** (himalaya-list filetype) - Email listing with selection
3. **Preview** (himalaya-preview filetype) - Email preview pane
4. **Reader** (himalaya-email filetype) - Full email reading
5. **Compose** (mail filetype) - Email composition

Each environment has its own keymap setup function in `config/ui.lua`:
- `setup_email_list_keymaps(bufnr)`
- `setup_preview_keymaps(bufnr)`
- `setup_compose_keymaps(bufnr)`
- `setup_sidebar_keymaps(bufnr)`

## Recommendations

### Recommended Approach: Extend Buffer-Local Keymap Pattern

**Solution**: Add the leader mappings (`<leader>me`, `<leader>md`, `<leader>mq`) to the existing `setup_compose_keymaps()` function in `config/ui.lua`, rather than using which-key's `cond` parameter.

**Benefits**:
1. Follows existing codebase patterns
2. Uses the maintainer-recommended approach
3. Keymaps will automatically appear in which-key popup when in compose buffer
4. Keymaps will automatically NOT appear when in other buffers
5. No complex conditional logic needed
6. Single source of truth for compose keymaps

### Implementation Details

1. **Modify `config/ui.lua` `setup_compose_keymaps()`**:
   Add leader keymaps alongside existing Ctrl keymaps:

   ```lua
   function M.setup_compose_keymaps(bufnr)
     local keymap = vim.keymap.set
     local opts = { buffer = bufnr, silent = true }

     -- Leader mappings (2-letter maximum per task 67)
     -- These will appear in which-key popup only when in compose buffer
     keymap('n', '<leader>me', '<cmd>HimalayaSend<CR>',
       vim.tbl_extend('force', opts, { desc = 'send email' }))
     keymap('n', '<leader>md', '<cmd>HimalayaSaveDraft<CR>',
       vim.tbl_extend('force', opts, { desc = 'save draft' }))
     keymap('n', '<leader>mq', '<cmd>HimalayaDiscard<CR>',
       vim.tbl_extend('force', opts, { desc = 'quit/discard' }))

     -- Existing Ctrl mappings...
     keymap('n', '<C-d>', function() ... end, vim.tbl_extend('force', opts, { desc = 'Save draft' }))
     keymap('n', '<C-q>', function() ... end, vim.tbl_extend('force', opts, { desc = 'Discard email' }))
     keymap('n', '<C-a>', function() ... end, vim.tbl_extend('force', opts, { desc = 'Attach file' }))
   end
   ```

2. **Remove conditional registrations from `which-key.lua`**:
   Remove lines 551-557 (the `wk.add` block with `cond = is_compose_buffer`)

3. **Optional: Add which-key group icon for compose**:
   If the `<leader>m` group doesn't show properly in compose buffers, add a buffer-local group registration:

   ```lua
   -- In setup_compose_keymaps()
   local wk = require('which-key')
   wk.add({
     { "<leader>m", group = "mail (compose)", icon = "...", buffer = bufnr }
   })
   ```

### Alternative Approaches Considered

| Approach | Pros | Cons |
|----------|------|------|
| **ftplugin/mail.lua** | Standard Neovim pattern | Compose buffer uses generic "mail" filetype shared with other mail scenarios |
| **FileType autocmd** | Clean separation | Extra indirection; filetype "mail" is too generic |
| **which-key `buffer` param** | Direct which-key integration | Less established pattern; may have similar issues as `cond` |
| **Dynamic re-registration** | Could work with `wk.add()` on BufEnter | Over-engineered; re-registers on every buffer switch |

The recommended approach (extending `setup_compose_keymaps`) is preferred because:
- It follows the existing himalaya architecture
- It's called at the right time (when compose buffer is created)
- It uses standard Neovim APIs that which-key automatically integrates with
- It maintains a single source of truth for compose keymaps

## Decisions

1. **Use buffer-local keymaps instead of which-key `cond`**: Buffer-local keymaps with `desc` are automatically discovered by which-key for popup display
2. **Extend existing pattern**: Add to `config/ui.lua setup_compose_keymaps()` rather than creating new infrastructure
3. **Keep Ctrl shortcuts**: The existing `<C-d>`, `<C-q>`, `<C-a>` shortcuts remain as quick-access alternatives
4. **Remove which-key conditional registration**: The `wk.add` block with `cond = is_compose_buffer` should be removed

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Leader mappings conflict with global mappings | Low | Buffer-local mappings take precedence; conflicts are intentional overrides |
| which-key doesn't pick up buffer-local leader mappings | Low | Verified in documentation; widely used pattern |
| Compose buffer created before keymaps module loaded | Low | `email_composer.lua` already requires `config/ui` indirectly through existing keymap setup |
| Icons don't display in buffer-local keymaps | Medium | Add explicit icon parameter to keymap or register separate which-key group |

## Appendix

### Search Queries Used
- "which-key.nvim cond parameter conditional mappings dynamic popup 2025 2026"
- "which-key.nvim buffer parameter buffer-local keymaps ftplugin filetype"
- "neovim buffer-local keymaps which-key desc integration best practice vim.keymap.set"

### References
- [which-key.nvim GitHub Repository](https://github.com/folke/which-key.nvim)
- [GitHub Issue #241 - Register keymaps for different buffer or filetype](https://github.com/folke/which-key.nvim/issues/241)
- [GitHub Discussion #805 - buffer/filetype specific key configuration](https://github.com/folke/which-key.nvim/discussions/805)
- [Neovim map.html documentation](https://neovim.io/doc/user/map.html)
- [Learn Vimscript the Hard Way - Buffer-Local Options and Mappings](https://learnvimscriptthehardway.stevelosh.com/chapters/11.html)

### Relevant Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` - Current which-key configuration with problematic `cond` usage
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/config/ui.lua` - Buffer keymap setup functions (target for changes)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_composer.lua` - Compose buffer creation
