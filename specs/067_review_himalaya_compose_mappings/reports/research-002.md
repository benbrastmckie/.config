# Research Report: Task #67

**Task**: 67 - review_himalaya_compose_mappings
**Started**: 2026-02-11
**Completed**: 2026-02-11
**Effort**: Medium (4-6 hours estimated for implementation)
**Dependencies**: None
**Sources/Inputs**: Local configuration analysis, which-key.lua, himalaya UI modules
**Artifacts**: specs/067_review_himalaya_compose_mappings/reports/research-002.md
**Standards**: report-format.md

## Executive Summary

- Identified 5 distinct Himalaya environments with inconsistent keybinding patterns
- Found critical conflict: `<leader>ms` is mapped to both "sync inbox" (global) and "send email" (compose buffer)
- Current compose buffer mappings use 3-letter patterns (`<leader>mcd`, `<leader>mce`) violating the 2-letter maximum requirement
- Email list/sidebar has well-organized single-letter quick actions (d, a, r, R, f, m, c) while other environments are inconsistent
- Proposed unified 2-letter mapping scheme with environment-specific leader subgroups

## Context and Scope

This research analyzes all Himalaya keybindings across 5 environments to identify inconsistencies and propose a unified systematic approach. The goal is to ensure all mappings use maximum 2 letters for leader mappings while maintaining clear, predictable functionality.

## Findings

### Environment 1: Email List/Sidebar (himalaya-list)

**Location**: `ui/config/ui.lua:setup_email_list_keymaps()`, `ui/folder_help.lua`

| Key | Action | Source |
|-----|--------|--------|
| `j/k` | Move up/down | Default Vim |
| `<CR>` | Open email (3-state preview) | Buffer keymap |
| `<Space>` | Toggle selection | Buffer keymap |
| `n` | Select email | Buffer keymap |
| `p` | Deselect email | Buffer keymap |
| `<C-d>` | Next page | Buffer keymap |
| `<C-u>` | Previous page | Buffer keymap |
| `F` | Refresh list | Buffer keymap |
| `q` | Close sidebar | Buffer keymap |
| `?` / `gH` | Show help | Buffer keymap |
| `<Esc>` | Hide preview / regress state | Buffer keymap |
| `d` | Delete email(s) | Buffer keymap |
| `a` | Archive email(s) | Buffer keymap |
| `r` | Reply | Buffer keymap |
| `R` | Reply all | Buffer keymap |
| `f` | Forward | Buffer keymap |
| `m` | Move email(s) | Buffer keymap |
| `c` | Compose new | Buffer keymap |
| `/` | Search | Buffer keymap |

**Assessment**: Well-organized with single-letter quick actions. Good separation between navigation and actions.

### Environment 2: Email Preview (himalaya-email / himalaya-preview)

**Location**: `ui/config/ui.lua:setup_preview_keymaps()`, `ui/email_preview.lua`

| Key | Action | Source |
|-----|--------|--------|
| `q` | Close preview | Buffer keymap |
| `j/k` | Next/prev email (or scroll in FOCUS mode) | Buffer keymap |
| `?` | Show help | Buffer keymap |
| `<Esc>` | Return to sidebar | Focus mode keymap |
| `<CR>` | Open email in buffer | Focus mode keymap |
| `<C-d>/<C-u>` | Half-page scroll | Focus mode keymap |
| `<C-f>/<C-b>` | Full page scroll | Focus mode keymap |

**Note**: Per task 56, single-letter action mappings were removed. Actions use `<leader>m` menu.

### Environment 3: Email Reader (himalaya-email full buffer)

**Location**: `ui/email_reader.lua:setup_reader_keymaps()`

| Key | Action | Source |
|-----|--------|--------|
| `q` | Close email reader | Buffer keymap |
| `<Esc>` | Close email reader | Buffer keymap |
| `?` | Show help | Buffer keymap |

**Note**: Per task 56, no single-letter action mappings. Actions via `<leader>m` menu.

### Environment 4: Compose Buffer (mail filetype + draft buffer)

**Location**: `which-key.lua` (lines 549-559), `ui/email_composer.lua`, `config/ui.lua:setup_compose_keymaps()`

**Which-key Mappings (conditional on `is_compose_buffer`)**:
| Key | Action | Source |
|-----|--------|--------|
| `<leader>ms` | Send email | which-key (CONFLICT) |
| `<leader>mc` | compose group | which-key |
| `<leader>mcd` | Save draft | which-key |
| `<leader>mcD` | Discard email | which-key |
| `<leader>mce` | Send email | which-key |
| `<leader>mcq` | Quit (discard) | which-key |

**Buffer-local Keymaps** (from config/ui.lua):
| Key | Action | Source |
|-----|--------|--------|
| `<C-d>` | Save draft | Buffer keymap |
| `<C-q>` | Discard email | Buffer keymap |
| `<C-a>` | Attach file | Buffer keymap |
| `?` | Show help | Buffer keymap |

**Issues Identified**:
1. **CONFLICT**: `<leader>ms` is mapped to "sync inbox" globally AND "send email" in compose buffers
2. 3-letter mappings (`<leader>mcd`, `<leader>mce`, `<leader>mcD`, `<leader>mcq`) violate 2-letter maximum
3. Missing dedicated send shortcut that doesn't conflict

### Environment 5: Account/Folder Selection (vim.ui.select pickers)

**Location**: `ui/email_list.lua:pick_folder()`, `ui/email_list.lua:pick_account()`

These use Neovim's native `vim.ui.select` interface:
| Key | Action | Source |
|-----|--------|--------|
| `j/k` | Navigate items | vim.ui.select default |
| `<CR>` | Select item | vim.ui.select default |
| `<Esc>` / `q` | Cancel | vim.ui.select default |

**Note**: No custom keybindings needed - uses standard Neovim UI.

### Global Mail Leader Mappings (which-key)

**Location**: `which-key.lua` (lines 534-601)

| Key | Action | Condition |
|-----|--------|-----------|
| `<leader>ma` | Switch account | Always |
| `<leader>mf` | Change folder | Always |
| `<leader>mF` | Recreate folders | Always |
| `<leader>mh` | Health check | Always |
| `<leader>mi` | Sync status | Always |
| `<leader>mm` | Toggle sidebar | Always |
| `<leader>ms` | Sync inbox | Always (CONFLICT) |
| `<leader>mS` | Full sync | Always |
| `<leader>mt` | Toggle auto-sync | Always |
| `<leader>mw` | Write email | Always |
| `<leader>mW` | Setup wizard | Always |
| `<leader>mx` | Cancel all syncs | Always |
| `<leader>mX` | Backup & fresh | Always |

**Email Actions Subgroup** (`<leader>me`, conditional on himalaya buffer):
| Key | Action |
|-----|--------|
| `<leader>mer` | Reply |
| `<leader>meR` | Reply all |
| `<leader>mef` | Forward |
| `<leader>med` | Delete |
| `<leader>mem` | Move |
| `<leader>mea` | Archive |
| `<leader>men` | New email |
| `<leader>me/` | Search |

### Inconsistencies Identified

1. **Critical Conflict**: `<leader>ms` maps to both "sync inbox" (global) and "send email" (compose buffer)
2. **3-Letter Mappings**: Compose buffer uses `<leader>mcd`, `<leader>mce`, `<leader>mcD`, `<leader>mcq`
3. **Redundant Mappings**: `<leader>mw` (write email) vs `c` in sidebar (compose new)
4. **Action Duplication**: Email actions available via both single-letter (sidebar) and `<leader>me*` (which-key)

## Recommendations

### Proposed Unified Mapping Scheme

**Principle**: All leader mappings use maximum 2 letters. Environment-specific actions use single letters where appropriate.

#### Global Mail Mappings (`<leader>m*`)

| Key | Action | Notes |
|-----|--------|-------|
| `<leader>ma` | Switch account | Keep |
| `<leader>mc` | Compose new email | New - unified compose entry |
| `<leader>mf` | Change folder | Keep |
| `<leader>mh` | Health check | Keep (or move to subgroup) |
| `<leader>mi` | Sync info/status | Keep |
| `<leader>mm` | Toggle sidebar | Keep |
| `<leader>ms` | Sync inbox | Keep (remove compose conflict) |
| `<leader>mS` | Full sync | Keep |
| `<leader>mt` | Toggle auto-sync | Keep |
| `<leader>mw` | Write/compose | Keep (alias for `<leader>mc`) |
| `<leader>mx` | Cancel syncs | Keep |

#### Compose Buffer Mappings

| Key | Action | Notes |
|-----|--------|-------|
| `<leader>me` | Send email | New - replaces `<leader>mce` |
| `<leader>md` | Save draft | New - replaces `<leader>mcd` |
| `<leader>mq` | Quit/discard | New - replaces `<leader>mcq` |
| `<C-d>` | Save draft | Keep buffer-local |
| `<C-q>` | Discard | Keep buffer-local |
| `<C-a>` | Attach | Keep buffer-local |

**Note**: The `<leader>mc` group would be eliminated, replaced with direct 2-letter mappings.

#### Email Action Mappings (in himalaya buffers)

Keep the current single-letter quick actions in sidebar (`d`, `a`, `r`, `R`, `f`, `m`, `c`, `/`).

For which-key menu, simplify:

| Key | Action | Notes |
|-----|--------|-------|
| `<leader>md` | Delete | Works with selection |
| `<leader>mr` | Reply | Single email |
| `<leader>mR` | Reply all | Single email |
| `<leader>mF` | Forward | Conflicts with recreate folders - needs resolution |

### Key Conflicts to Resolve

1. **`<leader>ms`**: Remove the compose buffer conditional mapping. Send should be `<leader>me` in compose buffers.

2. **`<leader>mF`**: Currently "recreate folders". If Forward becomes `<leader>mF`, need to move recreate folders to a different key (perhaps `<leader>mXf` under maintenance subgroup).

3. **`<leader>mc`**: Currently the compose subgroup. Could become "compose new" at top level, removing the subgroup.

### Alternative Scheme: Contextual Leader Groups

Another approach is to use different leader subgroups per environment:

- `<leader>mm*` - Mail management (sync, folders, accounts)
- `<leader>mc*` - Compose actions (send, draft, discard)
- `<leader>me*` - Email actions (reply, forward, delete)

This maintains the 2-letter maximum while allowing more functionality:

| Environment | Mappings |
|-------------|----------|
| Global | `<leader>mm` (toggle), `<leader>mms` (sync), `<leader>mma` (accounts) |
| Compose | `<leader>mcs` (send), `<leader>mcd` (draft), `<leader>mcq` (quit) |
| Email List | `<leader>med` (delete), `<leader>mer` (reply), `<leader>mef` (forward) |

**Issue**: This still uses 3 letters (`<leader>mcs`), violating the requirement.

### Final Recommendation

The simplest solution maintaining 2-letter maximum:

1. **Remove compose subgroup** - Use direct `<leader>m*` mappings
2. **Use context-aware mappings** - Same key does different things based on buffer type
3. **Send should be `<leader>me`** in compose buffers (E for Email/Envelope)

**Proposed Final Compose Mappings**:
| Key | Action |
|-----|--------|
| `<leader>me` | Send email (compose buffer only) |
| `<leader>md` | Save draft (compose buffer only) |
| `<leader>mq` | Quit/discard (compose buffer only) |

This requires conditional which-key definitions but maintains 2-letter maximum.

## Decisions

1. **2-Letter Maximum**: Enforced for all leader mappings
2. **Context-Aware**: Same leader key can have different actions based on buffer type
3. **Single-Letter Quick Actions**: Preserved in sidebar for efficiency
4. **Conflict Resolution**: `<leader>ms` remains "sync inbox", compose send moves to `<leader>me`

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| User muscle memory disruption | Document changes clearly, consider transition period |
| Conflict with existing global mappings | Audit all `<leader>m*` mappings across configuration |
| which-key conditional complexity | Test thoroughly with is_compose_buffer() function |

## Appendix

### Files Analyzed

1. `lua/neotex/plugins/editor/which-key.lua` - Global and conditional mappings
2. `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Buffer-local keymaps
3. `lua/neotex/plugins/tools/himalaya/ui/email_composer.lua` - Compose buffer setup
4. `lua/neotex/plugins/tools/himalaya/ui/email_reader.lua` - Reader keymaps
5. `lua/neotex/plugins/tools/himalaya/ui/email_preview.lua` - Preview keymaps
6. `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - List keymaps
7. `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua` - Help content
8. `lua/neotex/plugins/tools/himalaya/commands/ui.lua` - UI commands
9. `lua/neotex/plugins/tools/himalaya/commands/email.lua` - Email commands

### References

- Task 56: Removed single-letter action mappings from preview/reader
- Neovim which-key documentation for conditional mappings
