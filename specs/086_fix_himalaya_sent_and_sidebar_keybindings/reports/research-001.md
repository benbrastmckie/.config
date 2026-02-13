# Research Report: Task #86

**Task**: 86 - Fix himalaya sent folder display and sidebar keybindings
**Started**: 2026-02-13
**Completed**: 2026-02-13
**Effort**: 2-4 hours
**Dependencies**: None
**Sources/Inputs**: Local codebase analysis, himalaya CLI documentation, config files
**Artifacts**: This research report
**Standards**: report-format.md, subagent-return.md

## Executive Summary

- **Sent folder issue**: Investigation reveals the himalaya config has incorrect folder aliases. The config uses `[Gmail].Sent Mail` but the actual maildir folder is just `Sent`. The `message.send.save-copy = true` setting is correctly enabled.
- **Sidebar keybindings**: The help menu (triggered by `?`) in the sidebar uses `folder_help.lua` but does not include all available commands like sync operations.
- **Missing single-letter mappings**: Several useful commands exist only under `<leader>m` (sync inbox, full sync, etc.) but lack single-letter sidebar shortcuts.

## Context and Scope

### What Was Researched
1. Himalaya CLI configuration for sent folder behavior
2. Current sidebar keybinding implementation in `config/ui.lua`
3. Help menu implementation in `ui/folder_help.lua`
4. Which-key configuration for `<leader>m` mail group
5. Available himalaya commands not mapped to sidebar

### Constraints
- The sidebar uses `himalaya-list` filetype for keybindings
- Single-letter keybindings in sidebar are defined in `setup_email_list_keymaps()` in `config/ui.lua`
- The `?` help menu is a floating window showing static content from `folder_help.lua`

## Findings

### 1. Sent Folder Issue

**Root Cause Identified**: The himalaya config at `~/.config/himalaya/config.toml` has incorrect folder aliases:

```toml
# Current (incorrect for maildir backend):
folder.alias.sent = "[Gmail].Sent Mail"

# Actual folder in maildir structure:
# ~/Mail/Gmail/.Sent
```

The folder listing from `himalaya folder list -a gmail` shows:
```
| NAME      | DESC                                 |
|-----------|--------------------------------------|
| Sent      | /home/benjamin/Mail/Gmail/.Sent      |
```

**Solution**: Update folder aliases to match the actual maildir++ folder names:

For Gmail account (using maildir backend):
```toml
folder.aliases.sent = "Sent"
folder.aliases.drafts = "Drafts"
folder.aliases.trash = "Trash"
folder.aliases.inbox = "INBOX"
```

The `message.send.save-copy = true` setting is correctly enabled in both accounts.

**Note**: The config currently uses `folder.alias.sent` (singular) but himalaya v1.1.0 documentation shows `folder.aliases.sent` (plural). Need to verify the correct syntax.

### 2. Current Sidebar Keybindings

The sidebar (`himalaya-list` filetype) keybindings are defined in `lua/neotex/plugins/tools/himalaya/config/ui.lua` in `setup_email_list_keymaps()`:

| Key | Action | Description |
|-----|--------|-------------|
| `<CR>` | `handle_enter()` | Open email (3-state model) |
| `<Esc>` | State regression | SWITCH -> OFF mode |
| `q` | `sidebar.close()` | Close sidebar |
| `<Space>` | `toggle_selection()` | Toggle email selection |
| `n` | `select_email()` | Select email |
| `p` | `deselect_email()` | Deselect email |
| `<C-d>` | `next_page()` | Next page |
| `<C-u>` | `prev_page()` | Previous page |
| `F` | `refresh_email_list()` | Refresh list |
| `?` | `show_folder_help()` | Show help |
| `gH` | `show_folder_help()` | Show context help |
| `d` | `delete_current_email()` | Delete email |
| `a` | `archive_current_email()` | Archive email |
| `r` | `reply_current_email()` | Reply |
| `R` | `reply_all_current_email()` | Reply all |
| `f` | `forward_current_email()` | Forward |
| `m` | `move_current_email()` | Move email |
| `c` | `pick_folder()` | Change folder |
| `e` | `compose_email()` | Compose new |
| `/` | `show_search_ui()` | Search |
| `<Tab>` | `toggle_current_thread()` | Toggle thread |
| `zo`/`zc` | Expand/collapse thread | Thread fold operations |
| `zR`/`zM` | Expand/collapse all | All thread operations |
| `gT` | `toggle_threading()` | Toggle threading mode |

### 3. Missing Sidebar Keybindings

Commands available via `<leader>m` that lack sidebar shortcuts:

| Which-key | Command | Suggested Sidebar Key |
|-----------|---------|----------------------|
| `<leader>mA` | HimalayaAccounts | `A` (switch account) |
| `<leader>ms` | HimalayaSyncInbox | `s` (sync inbox) |
| `<leader>mS` | HimalayaSyncFull | `S` (full sync) |
| `<leader>mt` | HimalayaAutoSyncToggle | (consider `t` for toggle) |
| `<leader>mi` | HimalayaSyncInfo | `i` (info/status) |

### 4. Help Menu Analysis

The help menu in `ui/folder_help.lua` shows static content that does NOT include:
- Sync operations (s/S)
- Account switching (A)
- Auto-sync toggle
- Threading keybindings (though these are documented under `zo`/`zc`/etc.)

Current help content structure:
1. Navigation section (j/k, C-d/C-u)
2. Selection section (Space, n, p)
3. Quick Actions section (r, R, f, d, a, m, c, e, /)
4. Other section (F refresh, ? help, q quit)

### 5. Himalaya Sent Folder Configuration

Per the [himalaya config.sample.toml](https://github.com/pimalaya/himalaya/blob/master/config.sample.toml):

```toml
# Controls saving a copy of sent messages to the sent folder
message.send.save-copy = true  # Default: true

# The sent folder alias (used by save-copy)
folder.aliases.sent = "Sent"
```

The current config has `message.send.save-copy = true` which should save sent emails, but the folder alias mismatch (`[Gmail].Sent Mail` vs `Sent`) may be causing the issue.

## Recommendations

### Fix 1: Correct Folder Aliases (Nix Config)

Update `~/.config/himalaya/config.toml` (via Nix home-manager config):

```toml
# Per-account folder aliases for Gmail (maildir backend)
[accounts.gmail]
# ... existing config ...
folder.aliases.inbox = "INBOX"
folder.aliases.sent = "Sent"
folder.aliases.drafts = "Drafts"
folder.aliases.trash = "Trash"

# Per-account folder aliases for Logos (maildir backend)
[accounts.logos]
# ... existing config ...
folder.aliases.inbox = "INBOX"
folder.aliases.sent = "Sent"
folder.aliases.drafts = "Drafts"
folder.aliases.trash = "Trash"
```

**Note**: Verify the exact TOML syntax for himalaya v1.1.0 (may be `folder.aliases.sent` per account or global).

### Fix 2: Add Missing Sidebar Keybindings

In `lua/neotex/plugins/tools/himalaya/config/ui.lua`, add to `setup_email_list_keymaps()`:

```lua
-- Sync inbox (new)
keymap('n', 's', function()
  local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
  if ok and main.sync_inbox then
    main.sync_inbox()
  end
end, vim.tbl_extend('force', opts, { desc = 'Sync inbox' }))

-- Full sync (new)
keymap('n', 'S', function()
  local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
  if ok and main.sync_all then
    main.sync_all()
  end
end, vim.tbl_extend('force', opts, { desc = 'Full sync' }))

-- Switch account (new)
keymap('n', 'A', function()
  local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
  if ok and main.show_account_picker then
    main.show_account_picker()
  end
end, vim.tbl_extend('force', opts, { desc = 'Switch account' }))

-- Sync status/info (new)
keymap('n', 'i', function()
  vim.cmd('HimalayaSyncInfo')
end, vim.tbl_extend('force', opts, { desc = 'Sync status info' }))
```

### Fix 3: Update Help Menu

In `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua`, update `get_help_content()`:

Add to `base_actions`:
```lua
local base_actions = {
  "Quick Actions (on email line):",
  "  r         - Reply",
  "  R         - Reply all",
  "  f         - Forward",
  "  d         - Delete",
  "  a         - Archive",
  "  m         - Move",
  "  c         - Change folder",
  "  e         - Compose new",
  "  /         - Search",
  "",
  "Sync & Accounts:",  -- NEW SECTION
  "  s         - Sync inbox",
  "  S         - Full sync (all folders)",
  "  A         - Switch account",
  "  i         - Sync status info",
  "",
}
```

And update `base_other`:
```lua
local base_other = {
  "Other:",
  "  F         - Refresh list",
  "  ?         - Show this help",
  "  q         - Quit sidebar",
  "",
  "Threading (on thread root):",
  "  <Tab>     - Toggle thread expand",
  "  zo/zc     - Expand/collapse thread",
  "  zR/zM     - Expand/collapse all",
  "  gT        - Toggle threading mode",
  "",
  "Press any key to close..."
}
```

### Fix 4: Update Keybinding Reference

Update `get_keybinding()` function in `config/ui.lua` to include new keybindings:
```lua
['himalaya-list'] = {
  -- ... existing ...
  sync_inbox = 's',
  sync_full = 'S',
  switch_account = 'A',
  sync_info = 'i',
}
```

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Folder alias syntax differs in himalaya v1.1.0 | Medium | Test with `himalaya check -a gmail` after config change |
| New keybindings conflict with existing | Low | Keys s/S/A/i are not currently used in sidebar |
| Help menu width overflow | Low | Keep line lengths under 45 chars |

## Appendix

### Search Queries Used
- `himalaya config.sample.toml message.send.save-copy sent folder`
- `himalaya email CLI sent folder copy message after send configuration`

### Key Files Analyzed
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/config/ui.lua` - Keybindings
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/folder_help.lua` - Help menu
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` - Global keybindings
- `/home/benjamin/.config/himalaya/config.toml` - Himalaya CLI configuration
- `/home/benjamin/Mail/Gmail/` - Maildir structure

### References
- [himalaya config.sample.toml](https://github.com/pimalaya/himalaya/blob/master/config.sample.toml) - Official configuration reference
- [himalaya GitHub](https://github.com/pimalaya/himalaya) - CLI documentation
