# Research Report: Task 71

**Task**: 71 - Refactor himalaya keybindings to flatten email actions and eliminate `<leader>me` group conflicts
**Started**: 2026-02-12T00:00:00Z
**Completed**: 2026-02-12T00:15:00Z
**Effort**: 1-2 hours estimated
**Dependencies**: None
**Sources/Inputs**: Local configuration files, which-key.lua, ui.lua, email_composer.lua, folder_help.lua
**Artifacts**: specs/071_refactor_himalaya_keybindings_flatten_email_actions/reports/research-001.md
**Standards**: report-format.md

## Executive Summary

- Current architecture has `<leader>me` conflict: email actions subgroup (himalaya-list/email) vs send email (mail compose)
- which-key's `cond` feature enables context-specific mappings but creates user confusion when same key does different things
- Proposed 2-letter scheme is mostly valid but needs adjustments for conflicts with existing global mappings
- Four files require modification: which-key.lua, config/ui.lua, ui/email_composer.lua, ui/folder_help.lua

## Context and Scope

This research examines the current himalaya keybinding architecture to enable a refactoring that:
1. Eliminates the `<leader>me` subgroup that creates conflicts between contexts
2. Flattens all email actions to 2-letter sequences maximum
3. Maintains buffer-local single-letter keymaps in email list context

### Filetypes in Use

| Context | Filetype | Window Type |
|---------|----------|-------------|
| Sidebar | `himalaya-sidebar` | Left sidebar (folder tree) |
| Email List | `himalaya-list` | Main list view |
| Email Preview | `himalaya-email` | Email content preview |
| Compose | `mail` | Email composition buffer |

## Findings

### 1. Current State Analysis

#### which-key.lua (lines 529-593)

**Global Mail Group (`<leader>m`)** - Always visible:
```lua
<leader>ma  - HimalayaAccounts (switch account)
<leader>mf  - HimalayaFolder (change folder)
<leader>mF  - HimalayaRecreateFolders
<leader>mh  - HimalayaHealth
<leader>mi  - HimalayaSyncInfo
<leader>mm  - HimalayaToggle (toggle sidebar)
<leader>ms  - HimalayaSyncInbox
<leader>mS  - HimalayaSyncFull
<leader>mt  - HimalayaAutoSyncToggle
<leader>mw  - HimalayaWrite (compose)
<leader>mW  - HimalayaSetup
<leader>mx  - HimalayaCancelSync
<leader>mX  - HimalayaBackupAndFresh
```

**Email Actions Subgroup (`<leader>me`)** - Only in himalaya-list/himalaya-email (via `cond = is_himalaya_buffer`):
```lua
<leader>me  - GROUP "email actions"
<leader>mer - reply
<leader>meR - reply all
<leader>mef - forward
<leader>med - delete
<leader>mem - move
<leader>mea - archive
<leader>men - new email
<leader>me/ - search
```

**Compose Buffer (`<leader>m*`)** - Only in mail filetype (via `cond = is_mail`):
```lua
<leader>me  - HimalayaSend (CONFLICT!)
<leader>md  - HimalayaSaveDraft
<leader>mq  - HimalayaDiscard
```

#### config/ui.lua - Buffer-Local Keymaps

**Email List (`himalaya-list`)** - Single-letter keys (lines 169-353):
```lua
<CR>      - Open email (3-state preview model)
q         - Close sidebar
<Space>   - Toggle selection
n         - Select email
p         - Deselect email
<C-d>     - Next page
<C-u>     - Previous page
F         - Refresh
gH        - Context help
?         - Keybinding help
d         - Delete (selection-aware)
a         - Archive (selection-aware)
r         - Reply
R         - Reply all
f         - Forward
m         - Move (selection-aware)
c         - Compose new
/         - Search
<Esc>     - Hide preview/regress state
```

**Sidebar (`himalaya-sidebar`)** - Single-letter keys (lines 434-477):
```lua
<CR>      - Select folder
r         - Refresh folders
q         - Toggle sidebar
a         - Switch account
?         - Show help
```

**Preview (`himalaya-preview`)** - Minimal keys (lines 358-390):
```lua
q         - Close preview
j/k       - Next/prev email (navigation)
?         - Show help
```

**Compose (`himalaya-compose`)** - Control keys (lines 393-431):
```lua
<C-d>     - Save draft
<C-q>     - Discard
<C-a>     - Attach file
?         - Show help
```

### 2. Conflict Analysis

#### Primary Conflict: `<leader>me`

The key `<leader>me` has three different meanings depending on context:
1. In **himalaya-list/himalaya-email**: Opens "email actions" subgroup
2. In **mail** (compose buffer): Sends email
3. In **other contexts**: Does nothing (neither condition satisfied)

This creates user confusion because:
- The same key sequence has different behaviors
- which-key shows different menus depending on buffer type
- Users expect consistent behavior across the mail workflow

#### Proposed Scheme Conflict Check

**Global Mail Commands (`<leader>m*`)** - Checking proposed against existing:

| Proposed | Current Usage | Conflict? |
|----------|---------------|-----------|
| `<leader>mA` | (none) | NO - Safe |
| `<leader>mc` | (none) | NO - Safe |
| `<leader>mF` | HimalayaRecreateFolders | YES - Already used |
| `<leader>mh` | HimalayaHealth | YES - Already used |
| `<leader>mi` | HimalayaSyncInfo | YES - Already used |
| `<leader>mm` | HimalayaToggle | YES - Already used |
| `<leader>ms` | HimalayaSyncInbox | YES - Already used |
| `<leader>mS` | HimalayaSyncFull | YES - Already used |
| `<leader>mt` | HimalayaAutoSyncToggle | YES - Already used |
| `<leader>mw` | HimalayaWrite | YES - Already used |
| `<leader>mW` | HimalayaSetup | YES - Already used |
| `<leader>mx` | HimalayaCancelSync | YES - Already used |
| `<leader>mX` | HimalayaBackupAndFresh | YES - Already used |

**Finding**: The proposed scheme lists global commands that already exist. These are NOT changes, they're the current state.

#### Email Actions - Buffer-Local (Already Implemented)

The single-letter keys in email list are already implemented in config/ui.lua. The proposed scheme matches current implementation:

| Key | Proposed | Current (ui.lua) | Match? |
|-----|----------|------------------|--------|
| `c` | compose | compose | YES |
| `r` | reply | reply | YES |
| `R` | reply all | reply all | YES |
| `f` | forward | forward | YES |
| `d` | delete | delete | YES |
| `a` | archive | archive | YES |
| `m` | move | move | YES |
| `/` | search | search | YES |
| `<Space>` | toggle selection | toggle selection | YES |

**Finding**: Buffer-local single-letter keymaps are already correctly implemented. The issue is only the `<leader>me` subgroup in which-key.

### 3. The Real Problem

The `<leader>me` "email actions" subgroup in which-key.lua (lines 552-586) duplicates functionality that already exists as buffer-local single-letter keys. This creates:

1. **Redundancy**: Same actions accessible via `d` and `<leader>med`
2. **Conflict**: `<leader>me` means "email actions menu" in list but "send" in compose
3. **Confusion**: which-key shows different menus in different contexts

### 4. Recommended Solution

**Remove the `<leader>me` email actions subgroup entirely from which-key.lua.**

Rationale:
- Buffer-local single-letter keys (d, a, r, R, f, m, c, /) already provide the functionality
- These are faster to use than 3-letter sequences
- Eliminates the conflict with compose buffer's `<leader>me` send command
- Compose buffer's `<leader>me` (send), `<leader>md` (draft), `<leader>mq` (quit) are already 2-letter

**Alternative consideration**: If menu discoverability is desired, could rename compose `<leader>me` to `<leader>mE` (capital E) to disambiguate, but removing the redundant subgroup is cleaner.

### 5. Implementation Checklist

#### Files to Modify

1. **which-key.lua** (`lua/neotex/plugins/editor/which-key.lua`)
   - Remove lines 548-586 (email actions subgroup conditional on `is_himalaya_buffer`)
   - Keep lines 589-593 (compose buffer mappings conditional on `is_mail`)
   - Remove `is_himalaya_buffer` function if no longer needed

2. **config/ui.lua** (`lua/neotex/plugins/tools/himalaya/config/ui.lua`)
   - Update comments in `get_keybinding` (line 480) to remove `<leader>me` references
   - Update `setup_preview_keymaps` help message (line 388)
   - No functional changes needed - buffer-local keymaps are correct

3. **folder_help.lua** (`lua/neotex/plugins/tools/himalaya/ui/folder_help.lua`)
   - Remove "Mail Menu (`<leader>me`):" section from help content (line 80)
   - Update compose help content (lines 173-175) if needed

4. **commands/ui.lua** (`lua/neotex/plugins/tools/himalaya/commands/ui.lua`)
   - Update help message (line 13) to remove `<leader>me` reference

#### Verification Steps

1. Open himalaya sidebar (`<leader>mm`)
2. Verify single-letter keys work in email list (d, a, r, R, f, m, c, /)
3. Verify `<leader>m` shows only global mail commands (no "email actions" subgroup)
4. Compose new email (`<leader>mw`)
5. Verify `<leader>me` sends email, `<leader>md` saves draft, `<leader>mq` discards
6. Check `?` help in each context shows correct keybindings

### 6. which-key `cond` Behavior Note

The `cond` function in which-key enables context-sensitive mappings:
- When condition returns true, mapping is shown and active
- When condition returns false, mapping is hidden and inactive
- This allows same key to have different meanings in different buffers
- However, this can create user confusion when overused

The current implementation uses `cond` correctly for compose buffer specific mappings. The issue is the redundant email actions subgroup that creates perceived conflicts.

## Decisions

1. **Remove redundancy**: The `<leader>me` subgroup will be removed since buffer-local single-letter keys are faster and already implemented
2. **Keep compose mappings**: The `<leader>me/md/mq` in compose context are appropriate 2-letter sequences
3. **No changes to buffer-local keys**: The single-letter keys in email list are already correct

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Users accustomed to `<leader>me*` sequences | Document change; single-letter alternatives are faster |
| Discoverability of email actions | Update `?` help to list all single-letter keys prominently |
| Regression in compose buffer | Compose mappings unchanged; add test verification |

## Appendix

### Search Queries Used

- `grep -r "leader.*me" lua/` - Find all `<leader>me` references
- `grep -r "is_himalaya" lua/` - Find himalaya condition functions
- `grep -r "filetype.*himalaya" lua/` - Find filetype assignments

### References

- which-key.nvim v3 API documentation
- Current config files (read timestamps at research start)

### Key Code Blocks

**Current email actions subgroup (to be removed)**:
```lua
-- which-key.lua lines 552-586
local function is_himalaya_buffer()
  return is_himalaya_list() or is_himalaya_email()
end

wk.add({
  { "<leader>me", group = "email actions", icon = "...", cond = is_himalaya_buffer },
  { "<leader>mer", function() ... end, desc = "reply", cond = is_himalaya_buffer },
  -- ... more 3-letter sequences
})
```

**Current compose mappings (to keep)**:
```lua
-- which-key.lua lines 589-593
wk.add({
  { "<leader>me", "<cmd>HimalayaSend<CR>", desc = "send email", cond = is_mail },
  { "<leader>md", "<cmd>HimalayaSaveDraft<CR>", desc = "save draft", cond = is_mail },
  { "<leader>mq", "<cmd>HimalayaDiscard<CR>", desc = "quit/discard", cond = is_mail },
})
```
