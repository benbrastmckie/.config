# Research Report: Task #56 - Supplemental Keymap Inventory

**Task**: 56 - himalaya_pagination_display_fix
**Started**: 2026-02-10T12:00:00Z
**Completed**: 2026-02-10T12:30:00Z
**Type**: Supplemental Research (research-002)
**Dependencies**: research-001 (pagination display issues)
**Sources/Inputs**: Local codebase analysis, keymap definitions
**Artifacts**: specs/056_himalaya_pagination_display_fix/reports/research-002.md
**Standards**: report-format.md, neovim-lua.md

## Executive Summary

- Complete keymap inventory across 6 himalaya buffer contexts (sidebar/email-list, preview, focus mode, compose, reader, search)
- Documented the 3-state progressive preview model: OFF -> SWITCH -> FOCUS -> BUFFER_OPEN
- Identified inconsistencies between documented help (gH popup) and actual keybindings
- Pagination uses `n/p` keys which conflicts with selection toggle pattern
- Which-key integration provides `<leader>m` group for global himalaya access

## Context & Scope

This supplemental research provides a comprehensive mapping of all keybindings in the himalaya email plugin across all contexts. The goal is to identify:
1. Complete keymap coverage by buffer type
2. Inconsistencies and gaps
3. Patterns that could be improved for uniformity

## Findings

### 1. Which-Key Global Integration (`<leader>m`)

**File**: `lua/neotex/plugins/editor/which-key.lua:534-558`

| Key | Action | Icon | Notes |
|-----|--------|------|-------|
| `<leader>ma` | Switch account | HimalayaAccounts | |
| `<leader>mf` | Change folder | HimalayaFolder | |
| `<leader>mF` | Recreate folders | HimalayaRecreateFolders | |
| `<leader>mh` | Health check | HimalayaHealth | |
| `<leader>mi` | Sync status | HimalayaSyncInfo | |
| `<leader>mm` | Toggle sidebar | HimalayaToggle | Main entry point |
| `<leader>ms` | Sync inbox | HimalayaSyncInbox | |
| `<leader>mS` | Full sync | HimalayaSyncFull | |
| `<leader>mt` | Toggle auto-sync | HimalayaAutoSyncToggle | |
| `<leader>mw` | Write email | HimalayaWrite | |
| `<leader>mW` | Setup wizard | HimalayaSetup | |
| `<leader>mx` | Cancel all syncs | HimalayaCancelSync | |
| `<leader>mX` | Backup & fresh | HimalayaBackupAndFresh | |

**Compose Subgroup** (conditional on compose buffer):
| Key | Action | Icon |
|-----|--------|------|
| `<leader>mcd` | Save draft | HimalayaSaveDraft |
| `<leader>mcD` | Discard email | HimalayaDiscard |
| `<leader>mce` | Send email | HimalayaSend |
| `<leader>mcq` | Quit (discard) | HimalayaDiscard |

### 2. Sidebar/Email List Buffer Keymaps

**File**: `lua/neotex/plugins/tools/himalaya/config/ui.lua:162-288`

**Filetype**: `himalaya-list`

| Key | Action | Function | File:Line | Notes |
|-----|--------|----------|-----------|-------|
| `<Tab>` | Disabled | `<Nop>` | ui.lua:141 | Prevents buffer cycling |
| `<S-Tab>` | Disabled | `<Nop>` | ui.lua:142 | Prevents buffer cycling |
| `<Esc>` | Hide preview / regress state | email_preview.exit_switch_mode() | ui.lua:172-188 | Context-aware based on preview state |
| `<CR>` | Open email or draft | email_list.handle_enter() | ui.lua:191-197 | Implements 3-state model |
| `<Space>` | Toggle selection | email_list.toggle_selection() | ui.lua:200-205 | For batch operations |
| `d` | Delete selected | commands.email.delete_selected() | ui.lua:208-213 | Batch delete |
| `m` | Move selected | commands.email.move_selected() | ui.lua:215-220 | Move to folder |
| `c` | Compose new | commands.email.compose() | ui.lua:222-227 | New email |
| `r` | Reply | commands.email.reply() | ui.lua:229-234 | Reply to current |
| `R` | Reply all | commands.email.reply_all() | ui.lua:236-241 | Reply all |
| `f` | Forward | commands.email.forward() | ui.lua:243-248 | Forward email |
| `n` | Next page | email_list.next_page() | ui.lua:251-256 | **Pagination key** |
| `p` | Previous page | email_list.prev_page() | ui.lua:258-263 | **Pagination key** |
| `/` | Search | commands.email.search() | ui.lua:266-271 | Search emails |
| `gr` | Refresh | email_list.refresh() | ui.lua:274-279 | Refresh list |
| `?` | Show help | commands.ui.show_help('list') | ui.lua:282-287 | Context help |

### 3. Preview Buffer Keymaps (SWITCH Mode)

**File**: `lua/neotex/plugins/tools/himalaya/config/ui.lua:290-354`

**Filetype**: `himalaya-preview`

| Key | Action | Function | File:Line | Notes |
|-----|--------|----------|-----------|-------|
| `q` | Close preview | preview.close() | ui.lua:296-301 | Return to sidebar |
| `j` | Next email | preview.next_email() | ui.lua:304-308 | **In SWITCH mode** |
| `k` | Previous email | preview.prev_email() | ui.lua:310-316 | **In SWITCH mode** |
| `r` | Reply | commands.email.reply() | ui.lua:319-324 | |
| `R` | Reply all | commands.email.reply_all() | ui.lua:326-331 | |
| `f` | Forward | commands.email.forward() | ui.lua:333-338 | |
| `d` | Delete | commands.email.delete_current() | ui.lua:340-345 | |
| `?` | Show help | commands.ui.show_help('preview') | ui.lua:348-353 | |

### 4. Preview Buffer Keymaps (FOCUS Mode)

**File**: `lua/neotex/plugins/tools/himalaya/ui/email_preview.lua:1085-1155`

When preview is focused (second CR press), these keymaps are activated:

| Key | Action | Function | File:Line | Notes |
|-----|--------|----------|-----------|-------|
| `j` | Scroll down | normal! j | email_preview.lua:1097-1101 | **In FOCUS mode only** |
| `k` | Scroll up | normal! k | email_preview.lua:1103-1107 | **In FOCUS mode only** |
| `<C-d>` | Half-page down | normal! <C-d> | email_preview.lua:1110-1114 | |
| `<C-u>` | Half-page up | normal! <C-u> | email_preview.lua:1116-1120 | |
| `<C-f>` | Page down | normal! <C-f> | email_preview.lua:1122-1126 | |
| `<C-b>` | Page up | normal! <C-b> | email_preview.lua:1128-1132 | |
| `<CR>` | Open in buffer | open_email_in_buffer() | email_preview.lua:1135-1139 | Third CR opens full buffer |
| `<Esc>` | Return to SWITCH | exit_focus_mode() | email_preview.lua:1142-1146 | |
| `q` | Return to SWITCH | exit_focus_mode() | email_preview.lua:1148-1152 | |

### 5. Email Composition Buffer Keymaps

**File**: `lua/neotex/plugins/tools/himalaya/config/ui.lua:356-400`

**Filetype**: `himalaya-compose`

| Key | Action | Function | File:Line | Notes |
|-----|--------|----------|-----------|-------|
| `<C-s>` | Send email | composer.send() | ui.lua:362-367 | Send with 60s delay |
| `<C-d>` | Save draft | composer.save_draft() | ui.lua:370-375 | Manual save |
| `<C-q>` | Discard | composer.discard() | ui.lua:378-383 | Discard email |
| `<C-a>` | Attach file | composer.attach_file() | ui.lua:386-391 | File attachment |
| `?` | Show help | commands.ui.show_help('compose') | ui.lua:394-399 | |

**Additional Compose Behavior** (email_composer.lua):
- `:w` / `<leader>w` - Triggers draft save via BufWriteCmd autocmd (line 145-150)
- Autosave every 5 seconds if buffer modified (configurable)

### 6. Email Reader Buffer Keymaps

**File**: `lua/neotex/plugins/tools/himalaya/ui/email_reader.lua:49-107`

**Filetype**: `himalaya-email` (full buffer view)

| Key | Action | Function | File:Line | Notes |
|-----|--------|----------|-----------|-------|
| `q` | Close reader | M.close() | email_reader.lua:53-55 | Return to sidebar |
| `<Esc>` | Close reader | M.close() | email_reader.lua:57-59 | |
| `r` | Reply | commands.email.reply() | email_reader.lua:62-67 | |
| `R` | Reply all | commands.email.reply_all() | email_reader.lua:69-74 | |
| `f` | Forward | commands.email.forward() | email_reader.lua:77-82 | |
| `d` | Delete | commands.email.delete_current() | email_reader.lua:85-91 | |
| `a` | Archive | commands.email.archive_current() | email_reader.lua:94-100 | |
| `?` | Show help | notify with key summary | email_reader.lua:103-106 | Inline notification |

### 7. Sidebar/Folder Keymaps

**File**: `lua/neotex/plugins/tools/himalaya/config/ui.lua:402-445`

**Filetype**: `himalaya-sidebar`

| Key | Action | Function | File:Line | Notes |
|-----|--------|----------|-----------|-------|
| `<CR>` | Select folder | sidebar.select_folder() | ui.lua:408-413 | |
| `r` | Refresh folders | sidebar.refresh() | ui.lua:416-420 | |
| `q` | Toggle sidebar | commands.ui.toggle_sidebar() | ui.lua:423-429 | Close sidebar |
| `a` | Switch account | commands.ui.switch_account() | ui.lua:432-437 | |
| `?` | Show help | commands.ui.show_help('sidebar') | ui.lua:440-445 | |

### 8. Search Results Buffer Keymaps

**File**: `lua/neotex/plugins/tools/himalaya/data/search.lua:864-886`

| Key | Action | Function | File:Line | Notes |
|-----|--------|----------|-----------|-------|
| `r` | Refine search | vim.ui.input prompt | search.lua:867-877 | Modify search query |
| `n` | New search | show_search_ui() | search.lua:879-882 | Fresh search |
| `q` | Close | :bdelete | search.lua:884 | |
| `<Esc>` | Close | :bdelete | search.lua:885 | |

### 9. Template Manager Keymaps

**File**: `lua/neotex/plugins/tools/himalaya/data/templates.lua:797-839`

| Key | Action | Description |
|-----|--------|-------------|
| `n` | New template | Create new template |
| `e` | Edit template | Edit selected template |
| `d` | Delete template | Delete with confirmation |
| `p` | Preview template | Preview with variables |
| `q` | Close | Close buffer |
| `<Esc>` | Close | Close buffer |

### 10. Context-Aware Help (gH)

**File**: `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua`

The help content varies by folder type:

**Inbox/Regular Folders**:
```
Navigation: j/k, gn/gp (pages)
Email Actions: <CR>, gr, gR, gf, gD, gA, gS, gM, n/N
Folder: ga, gm, gs
Other: gH, q
```

**Draft Folder**:
```
Draft Actions: <CR> (edit), gD (delete), n/N (select)
```

**Trash Folder**:
```
Email Actions: <CR>, gD (permanent), gM (restore), n/N
```

**Note**: The help references `gn/gp` for pagination but actual implementation uses `n/p`!

## Identified Issues

### Issue 1: Pagination Key Mismatch with Help
**Severity**: Medium

Help in folder_help.lua shows:
- `gn` - Next page
- `gp` - Previous page

Actual implementation in ui.lua shows:
- `n` - Next page
- `p` - Previous page

**Impact**: User confusion when reading help.

### Issue 2: Selection Toggle Pattern Inconsistency
**Severity**: Medium

Help shows:
- `n/N` - Select/deselect email

Actual implementation:
- `<Space>` - Toggle selection
- `n` - Next page (conflicts!)

**Impact**: `n` key serves dual purpose (pagination AND described as selection).

### Issue 3: Missing g-prefix Pattern
**Severity**: Low

Several actions in help use `g` prefix pattern (`gr`, `gR`, `gf`, `gD`, `gA`, `gS`, `gM`, `gn`, `gp`, `gH`) but the actual implementation often uses single keys:
- `r` instead of `gr` for reply
- `R` instead of `gR` for reply all
- `n/p` instead of `gn/gp` for pagination

**Impact**: Inconsistent keybinding philosophy.

### Issue 4: Preview Footer Inconsistency
**Severity**: Low

Email preview footer (email_preview.lua:469-481) shows:
- Regular: `esc:sidebar gr:reply gR:reply-all gf:forward q:exit gD:delete gA:archive gS:spam`
- Draft: `esc:sidebar return:edit gD:delete q:exit`
- Scheduled: `esc:sidebar gD:cancel q:exit`

But the keymaps (ui.lua) bind:
- `r` for reply (not `gr`)
- `R` for reply all (not `gR`)
- `f` for forward (not `gf`)

### Issue 5: Missing Scheduled Email Keymaps
**Severity**: Medium

Help mentions `gE` for editing scheduled emails but no implementation found in the keymap search.

### Issue 6: Incomplete Keybinding Documentation
**Severity**: Low

The keybindings reference table in ui.lua (lines 450-494) is accurate but doesn't include:
- Preview footer keybindings
- Scheduled email actions
- FOCUS mode scroll bindings

## Preview State Model Documentation

### 3-State Progressive Preview Model

```
OFF ─────────> SWITCH ─────────> FOCUS ─────────> BUFFER_OPEN
      (CR)            (CR)             (CR)

<──────────── <──────────────
    (ESC)           (ESC/q)
```

**States**:
1. **OFF**: No preview shown, sidebar in normal navigation
2. **SWITCH**: Preview shown, j/k switches between emails in sidebar
3. **FOCUS**: Preview focused, j/k scrolls preview content
4. **BUFFER_OPEN**: Email opened in full buffer (terminal state)

**Key behavior changes by state**:
| Key | OFF | SWITCH | FOCUS |
|-----|-----|--------|-------|
| `j` | Move down in list | Move to next email (updates preview) | Scroll preview down |
| `k` | Move up in list | Move to prev email (updates preview) | Scroll preview up |
| `<CR>` | Enter SWITCH mode | Enter FOCUS mode | Open in buffer |
| `<Esc>` | N/A | Return to OFF | Return to SWITCH |

## Recommendations

### 1. Normalize Pagination Keys
**Current**: `n/p`
**Recommendation**: Use `gn/gp` to match help documentation and free `n` for other uses

### 2. Consolidate g-prefix Pattern
Either:
- Use g-prefix consistently (`gr`, `gR`, `gf`, etc.) - matches help
- Remove g-prefix from help to match actual bindings

### 3. Add Missing Scheduled Email Edit Keymap
Implement `gE` for editing scheduled email timing as documented in help.

### 4. Update Help System
Ensure folder_help.lua accurately reflects actual keybindings.

### 5. Document Preview State Model
Add user-visible documentation about the 3-state preview model and how keybindings change between states.

## Appendix

### Files Examined
- `lua/neotex/plugins/editor/which-key.lua`
- `lua/neotex/plugins/tools/himalaya/config/ui.lua`
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua`
- `lua/neotex/plugins/tools/himalaya/ui/email_preview.lua`
- `lua/neotex/plugins/tools/himalaya/ui/email_reader.lua`
- `lua/neotex/plugins/tools/himalaya/ui/email_composer.lua`
- `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua`
- `lua/neotex/plugins/tools/himalaya/data/search.lua`
- `lua/neotex/plugins/tools/himalaya/data/templates.lua`
- `lua/neotex/plugins/tools/himalaya/config/init.lua`

### Keybinding Count by Context
| Context | Keybindings |
|---------|-------------|
| Which-Key Global | 17 |
| Sidebar/Email List | 15 |
| Preview (SWITCH) | 8 |
| Preview (FOCUS) | 9 |
| Compose | 5 |
| Reader | 8 |
| Search Results | 4 |
| Templates | 6 |
| **Total** | **72+** |
