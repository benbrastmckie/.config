# Research Report: Task #70

**Task**: 70 - fix_email_composer_setup_compose_keymaps
**Started**: 2026-02-12T00:00:00Z
**Completed**: 2026-02-12T00:30:00Z
**Effort**: 1-2 hours
**Dependencies**: None (task 69 already completed but added keymaps to wrong location)
**Sources/Inputs**: Local codebase analysis, which-key.lua, email_composer.lua, config/ui.lua
**Artifacts**: specs/070_fix_email_composer_setup_compose_keymaps/reports/research-001.md
**Standards**: report-format.md

## Executive Summary

- Task 69 added compose buffer leader keymaps to `config/ui.lua` but `email_composer.lua` has its own `setup_compose_keymaps()` that gets called directly and does NOT define leader keymaps
- The architecture has TWO keymap setup paths for compose buffers, causing the issue
- **Recommended solution**: Add the leader keymaps to which-key.lua with `cond = is_mail` for centralized management, NOT to email_composer.lua
- This aligns with the research focus: "All which-key mappings should be defined in which-key.lua"

## Context and Scope

### Problem Statement
Task 69 attempted to add `<leader>me`, `<leader>md`, `<leader>mq` keymaps for compose buffers, but placed them in `config/ui.lua:setup_compose_keymaps()`. However, when composing emails, `email_composer.lua:setup_compose_keymaps()` is called directly (lines 110, 500), which shadows the config/ui.lua version.

### Current Architecture

```
                    ┌─────────────────────────────────────────┐
                    │           email_composer.lua            │
                    │                                         │
                    │  create_compose_buffer() [line 83]      │
                    │     └─> M.setup_compose_keymaps(buf)    │
                    │         [line 110]                      │
                    │                                         │
                    │  open_draft() [line 488]                │
                    │     └─> M.setup_compose_keymaps(buf)    │
                    │         [line 500]                      │
                    └─────────────────────────────────────────┘
                                        │
                                        │ CALLS ITS OWN FUNCTION
                                        ▼
                    ┌─────────────────────────────────────────┐
                    │  email_composer.setup_compose_keymaps   │
                    │  [lines 134-153]                        │
                    │                                         │
                    │  - Only sets up BufWriteCmd autocmd     │
                    │  - NO leader keymaps defined            │
                    │  - Comment references task 67           │
                    └─────────────────────────────────────────┘
```

Meanwhile, there is ANOTHER keymap setup path:

```
                    ┌─────────────────────────────────────────┐
                    │           config/ui.lua                 │
                    │                                         │
                    │  setup_buffer_keymaps(bufnr) [line 136] │
                    │    └─> filetype == 'himalaya-compose'?  │
                    │        └─> M.setup_compose_keymaps()    │
                    │            [line 154]                   │
                    └─────────────────────────────────────────┘
                                        │
                                        │ CALLS ITS OWN FUNCTION
                                        ▼
                    ┌─────────────────────────────────────────┐
                    │  config/ui.setup_compose_keymaps        │
                    │  [lines 393-440]                        │
                    │                                         │
                    │  - Defines <leader>me, <leader>md,      │
                    │    <leader>mq keymaps                   │
                    │  - Defines <C-d>, <C-q>, <C-a>          │
                    │  - Has help keymap '?'                  │
                    └─────────────────────────────────────────┘
```

### Why config/ui.lua Keymaps Are Not Applied

The compose buffer uses filetype `mail` (set at email_composer.lua:119), NOT `himalaya-compose`. The config/ui.lua:setup_buffer_keymaps() checks for filetype:

```lua
if filetype == 'himalaya-list' then
  M.setup_email_list_keymaps(bufnr)
elseif filetype == 'himalaya-preview' then
  M.setup_preview_keymaps(bufnr)
elseif filetype == 'himalaya-compose' then     -- <-- NEVER MATCHES
  M.setup_compose_keymaps(bufnr)
elseif filetype == 'himalaya-sidebar' then
  M.setup_sidebar_keymaps(bufnr)
end
```

So even if config.setup_buffer_keymaps() were called, it would NOT apply compose keymaps because the filetype is `mail`, not `himalaya-compose`.

## Findings

### 1. Current Keymap Registration Patterns

The codebase uses THREE different keymap registration patterns:

| Pattern | Location | When Applied | Example |
|---------|----------|--------------|---------|
| which-key.add() | which-key.lua | On which-key load | `<leader>m` mail group |
| buffer-local vim.keymap.set() | config/ui.lua | On buffer_keymaps call | `d` for delete in list |
| buffer-local vim.keymap.set() | email_composer.lua | On compose buffer create | BufWriteCmd autocmd |

### 2. Existing which-key.lua Mail Group

which-key.lua already defines a `<leader>m` mail group (lines 528-544) with global mail commands:
- `<leader>ma` - switch account
- `<leader>mf` - change folder
- `<leader>mm` - toggle sidebar
- `<leader>ms` - sync inbox
- etc.

It also defines an email actions subgroup (lines 546-586) with `cond = is_himalaya_buffer` for actions in himalaya-list and himalaya-email buffers.

### 3. Helper Function for Mail Filetype

which-key.lua already has an `is_mail()` helper function (lines 204-206):
```lua
local function is_mail()
  return vim.bo.filetype == "mail"
end
```

This function is currently UNUSED but was clearly intended for compose buffer keymaps.

### 4. Task 69's Implementation in config/ui.lua

Task 69 added keymaps to config/ui.lua:setup_compose_keymaps (lines 399-404):
```lua
keymap('n', '<leader>me', '<cmd>HimalayaSend<CR>',
  vim.tbl_extend('force', opts, { desc = 'send email' }))
keymap('n', '<leader>md', '<cmd>HimalayaSaveDraft<CR>',
  vim.tbl_extend('force', opts, { desc = 'save draft' }))
keymap('n', '<leader>mq', '<cmd>HimalayaDiscard<CR>',
  vim.tbl_extend('force', opts, { desc = 'quit/discard' }))
```

These are correct, but the function is never called for compose buffers.

### 5. Commands Already Exist

The Himalaya commands for these actions already exist (commands/email.lua):
- `HimalayaSend` (line 51)
- `HimalayaSaveDraft` (line 69)
- `HimalayaDiscard` (line 86)

## Recommendations

### Option A: Add to which-key.lua (RECOMMENDED)

Add the compose-specific keymaps to which-key.lua with `cond = is_mail`:

```lua
-- Compose buffer keymaps (visible only in mail buffers)
wk.add({
  { "<leader>me", "<cmd>HimalayaSend<CR>", desc = "send email", icon = "󰇮", cond = is_mail },
  { "<leader>md", "<cmd>HimalayaSaveDraft<CR>", desc = "save draft", icon = "󰆓", cond = is_mail },
  { "<leader>mq", "<cmd>HimalayaDiscard<CR>", desc = "quit/discard", icon = "󰚌", cond = is_mail },
})
```

**Advantages**:
- Centralized keymap management
- Appears in which-key popup automatically
- Uses existing `is_mail()` helper
- Consistent with other conditional keymaps (LaTeX, Jupyter, etc.)

### Option B: Add to email_composer.lua:setup_compose_keymaps()

Add the keymaps directly to email_composer.lua lines 134-153.

**Disadvantages**:
- Scattered keymap definitions
- Won't appear in which-key popup (no automatic desc display)
- Duplicates what's in config/ui.lua

### Option C: Fix the filetype check in config/ui.lua

Change compose buffer filetype from `mail` to `himalaya-compose`.

**Disadvantages**:
- May break syntax highlighting
- More invasive change
- Still scattered keymaps

## Decisions

1. **Use Option A**: Add keymaps to which-key.lua with `cond = is_mail`
2. **Keep config/ui.lua keymaps**: They serve as backup if buffer-local setup is ever called
3. **Do NOT modify email_composer.lua**: Keep it focused on buffer lifecycle, not keymap definitions

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| `is_mail()` may match non-Himalaya mail buffers | Commands check for active compose buffer before acting |
| Duplicate keymaps if config/ui.lua is ever called | Keymaps are buffer-local, will just override |
| which-key popup may be crowded | Group under existing `<leader>m` menu |

## Appendix

### Search Queries Used
- `setup_compose_keymaps` in himalaya/
- `filetype.*mail` in himalaya/
- `HimalayaSend|HimalayaSaveDraft|HimalayaDiscard` in himalaya/

### Files Examined
- /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua
- /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/email_composer.lua
- /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/config/ui.lua
- /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/commands/email.lua
- /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/init.lua
- /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya-plugin.lua

### Implementation Location
Add to which-key.lua after line 586 (after the email actions subgroup):
```lua
-- Compose buffer keymaps (visible only when composing email)
wk.add({
  { "<leader>me", "<cmd>HimalayaSend<CR>", desc = "send email", icon = "󰇮", cond = is_mail },
  { "<leader>md", "<cmd>HimalayaSaveDraft<CR>", desc = "save draft", icon = "󰆓", cond = is_mail },
  { "<leader>mq", "<cmd>HimalayaDiscard<CR>", desc = "quit/discard", icon = "󰚌", cond = is_mail },
})
```
