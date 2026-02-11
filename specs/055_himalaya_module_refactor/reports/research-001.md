# Research Report: Task #55

**Task**: 55 - himalaya_module_refactor
**Started**: 2026-02-10T12:00:00Z
**Completed**: 2026-02-10T12:30:00Z
**Effort**: 4-6 hours estimated
**Dependencies**: himalaya CLI, Neovim 0.9+
**Sources/Inputs**: Local codebase analysis, himalaya CLI documentation, himalaya.nvim plugin research
**Artifacts**: specs/055_himalaya_module_refactor/reports/research-001.md
**Standards**: report-format.md, neovim-lua.md

## Executive Summary

- The himalaya module is an extensive custom implementation (90+ files) with sophisticated architecture
- Current implementation focuses heavily on composition, drafts, and sync - but email reading UX is weak
- **Critical Gap**: No dedicated "open email" action - preview-only workflow with no way to focus/read emails
- **Selection exists but is incomplete**: Checkboxes are always displayed but selection toggle is broken/unused
- Recommended approach: Implement mutt-style keybindings with proper email opening and selection workflows

## Context and Scope

### Research Objectives
1. Analyze current himalaya module implementation
2. Identify intended UX and current limitations
3. Document gaps in email reading and selection functionality
4. Design recommendations for improvement

### Scope Boundaries
- Focus on UX improvements, not architectural refactoring
- Preserve existing draft/sync infrastructure
- Target mutt-like email workflow experience

## Findings

### 1. Current Module Architecture

**Directory Structure** (90+ Lua files):
```
lua/neotex/plugins/tools/himalaya/
├── init.lua                 # Main entry point
├── _plugin.lua              # lazy.nvim spec
├── commands/               # User commands (email.lua, sync.lua, ui.lua, utility.lua)
├── config/                 # Configuration modules (accounts, folders, oauth, ui, validation)
├── core/                   # Core systems (state, config, api, events, logger, errors)
├── data/                   # Data management (cache, drafts, maildir, scheduler, search, templates)
├── features/               # Feature modules (attachments, contacts, headers, images, views, accounts)
├── sync/                   # Sync infrastructure (manager, mbsync, coordinator, lock, oauth)
├── setup/                  # Setup wizard and health checks
├── ui/                     # UI components (main, sidebar, email_list, email_preview, email_composer)
├── utils/                  # Utility functions
└── test/                   # Test suite (extensive)
```

**Key Design Decisions**:
- Custom implementation - not using official himalaya.nvim plugin
- Uses himalaya CLI as backend (not IMAP directly)
- Maildir-based local storage with mbsync for sync
- Sophisticated draft system with filesystem persistence
- Event-driven architecture with orchestrator pattern

### 2. Current User Experience

**Available Commands** (documented in commands/init.lua):
| Command | Description | Status |
|---------|-------------|--------|
| `:Himalaya` | Open email client | Works |
| `:HimalayaToggle` | Toggle sidebar | Works |
| `:HimalayaWrite` | Compose new email | Works |
| `:HimalayaSend` | Send email | Works |
| `:HimalayaFolder [name]` | Switch folders | Works |
| `:HimalayaAccounts` | Account picker | Works |
| `:HimalayaSearch [query]` | Search emails | Works |
| `:HimalayaRefresh` | Refresh list | Works |

**Keybindings in Email List** (config/ui.lua):
| Key | Intended Action | Current Status |
|-----|-----------------|----------------|
| `<CR>` | Open email/draft | **BROKEN** - calls undefined `handle_enter()` |
| `<Space>` | Toggle selection | **BROKEN** - calls undefined `toggle_selection()` |
| `d` | Delete selected | Calls undefined function |
| `m` | Move selected | Calls undefined function |
| `c` | Compose | Works (via command) |
| `r` | Reply | Calls undefined function |
| `R` | Reply all | Calls undefined function |
| `f` | Forward | Calls undefined function |
| `n` | Next page | Works (via email_list.next_page) |
| `p` | Previous page | Works (via email_list.prev_page) |
| `/` | Search | Calls undefined function |
| `gr` | Refresh | Calls undefined `refresh()` |
| `?` | Help | Calls undefined function |

### 3. Critical Gaps Identified

#### Gap 1: No Way to Open Emails
The current implementation has:
- `email_preview.lua` - Shows floating preview window on CursorHold
- No dedicated "read email" function that opens in a proper buffer
- Preview is ephemeral and cannot be focused/scrolled easily
- No way to read long emails completely

**Evidence from code**:
```lua
-- email_list.lua line 173: calls email_list.handle_enter()
-- BUT handle_enter() is NOT defined in email_list.lua
keymap('n', '<CR>', function()
  local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
  if ok and email_list.handle_enter then
    email_list.handle_enter()  -- UNDEFINED FUNCTION
  end
end)
```

#### Gap 2: Selection Mode is Broken
- Checkboxes `[ ]` are always rendered on every email line (email_list.lua:649)
- `toggle_email_selection()` exists in state.lua but is never called
- Keybinding calls `toggle_selection()` which doesn't exist
- Batch operations (delete_selected, move_selected, etc.) won't work

**Evidence**:
```lua
-- email_list.lua line 649: Always shows checkbox
local checkbox = is_selected and '[x] ' or '[ ] '
-- BUT <Space> keymap calls non-existent function:
keymap('n', '<Space>', function()
  if ok and email_list.toggle_selection then
    email_list.toggle_selection()  -- UNDEFINED FUNCTION
  end
end)
```

#### Gap 3: Preview-Only Workflow
- Preview only shows on `CursorHold` (500ms delay by default)
- Preview window closes when leaving sidebar
- Cannot navigate or scroll within preview
- No way to mark emails as read/unread
- Reply/forward from preview uses stored email_id in state, not focused email

### 4. Himalaya CLI Capabilities (Not Fully Utilized)

The himalaya CLI supports:
```
message read     - Read message content (used)
message thread   - Read thread/conversation (NOT USED)
message reply    - Reply to message (used via compose)
message forward  - Forward message (used via compose)
message copy     - Copy message (NOT USED)
message move     - Move message (used)
message delete   - Delete message (used)

flag add         - Add flags (NOT USED - no mark read/unread)
flag remove      - Remove flags (NOT USED)
flag set         - Set flags (NOT USED)

envelope list    - List emails (used)
envelope thread  - Thread view (NOT USED)
```

**Underutilized Features**:
1. Flag management (mark read/unread, star, etc.)
2. Thread/conversation view
3. Copy to folder (only move is implemented)

### 5. Comparison with Official himalaya.nvim

The [official plugin](https://github.com/JostBrand/himalaya.nvim) provides:
- `gw` - write email
- `gr` - reply
- `gR` - reply all
- `gf` - forward
- `ga` - download attachments
- `gC` - copy
- `gM` - move
- `gD` - delete
- Folder picker integration (telescope/fzf)
- Contact completion

**Current implementation is missing**:
- Consistent `g` prefix keymap convention
- Copy operation (only move)
- Proper attachment download UI

## Recommendations

### Recommendation 1: Implement Proper Email Reading

**Problem**: Cannot open/read emails - only ephemeral preview exists

**Solution**: Create `read_email()` function that opens email in proper buffer

```lua
-- Proposed: ui/email_reader.lua
function M.open_email(email_id)
  -- 1. Close preview if open
  -- 2. Create new buffer with email content
  -- 3. Set filetype himalaya-email
  -- 4. Apply syntax highlighting
  -- 5. Setup buffer-local keymaps (reply, forward, delete, etc.)
  -- 6. Mark email as read via flag command
end
```

**Keybinding**: `<CR>` or `o` to open, `q` to close and return to list

### Recommendation 2: Fix Selection System

**Problem**: Selection UI exists but interaction is broken

**Solution**: Implement missing `toggle_selection()` function

```lua
-- Add to email_list.lua
function M.toggle_selection()
  local line_num = vim.fn.line('.')
  local line_map = state.get('email_list.line_map')
  local metadata = line_map[line_num]

  if metadata and metadata.email_id then
    -- Get full email data for batch operations
    local emails = state.get('email_list.emails')
    local email_data = emails[metadata.email_index]

    state.toggle_email_selection(metadata.email_id, email_data)
    M.update_selection_display()  -- Already exists
  end
end
```

**Keybindings**:
- `<Space>` or `x` - Toggle selection on current email
- `v` - Enter visual selection mode (multi-select)
- `*` - Select all
- `u` - Unselect all

### Recommendation 3: Adopt mutt-style Keybindings

**Current**: Inconsistent keybindings with broken mappings

**Proposed Keymap Scheme**:

| Key | Action | Context |
|-----|--------|---------|
| `j/k` | Navigate emails | List |
| `<CR>` or `o` | Open email | List |
| `q` | Close/Back | Reader/List |
| `r` | Reply | Reader |
| `R` | Reply All | Reader |
| `f` | Forward | Reader |
| `d` | Delete | Reader/List |
| `m` | Move to folder | Reader/List |
| `a` | Archive | Reader/List |
| `s` | Spam | Reader/List |
| `<Space>` or `x` | Toggle selection | List |
| `c` | Compose new | List |
| `/` | Search | List |
| `g` followed by key | Extra actions | Both |
| `gr` | Refresh | List |
| `gs` | Sync | List |
| `gf` | Folder picker | List |
| `ga` | Account picker | List |
| `gH` | Show help | Both |

### Recommendation 4: Implement Flag Management

**Current**: No way to mark read/unread or star emails

**Solution**: Add flag commands using himalaya CLI

```lua
-- Proposed: commands/flags.lua
function M.toggle_read()
  local email_id = get_current_email_id()
  local is_read = is_email_read(email_id)

  if is_read then
    -- himalaya flag remove <id> seen
    utils.run_himalaya({'flag', 'remove', tostring(email_id), 'seen'})
  else
    -- himalaya flag add <id> seen
    utils.run_himalaya({'flag', 'add', tostring(email_id), 'seen'})
  end

  refresh_email_list()
end
```

**Keybindings**:
- `N` - Toggle read/unread
- `!` - Toggle flagged/starred

### Recommendation 5: Add Thread View Support

**Current**: Flat email list only

**Solution**: Use himalaya's thread support

```lua
-- Use: himalaya envelope thread -a <account> -f <folder>
-- Use: himalaya message thread <id>
```

**Keybinding**: `t` to toggle thread view

### Recommendation 6: Improve Help System

**Current**: `?` and `gH` call undefined help functions

**Solution**: Implement context-aware floating help window

```lua
function M.show_help(context)
  local help_lines = {
    list = {
      "Email List Keybindings:",
      "",
      "<CR>     Open email",
      "<Space>  Toggle selection",
      "j/k      Navigate",
      "c        Compose",
      "d        Delete",
      "m        Move",
      "r        Reply",
      "/        Search",
      "gr       Refresh",
      "gf       Folders",
      "ga       Accounts",
      "q        Quit",
    },
    -- ... reader, compose contexts
  }

  show_floating_help(help_lines[context])
end
```

## Implementation Priority

1. **P0 (Critical)**: Fix `<CR>` to open emails properly
2. **P0 (Critical)**: Fix `<Space>` selection toggle
3. **P1 (High)**: Implement consistent keybindings
4. **P1 (High)**: Add flag management (read/unread)
5. **P2 (Medium)**: Add help system
6. **P2 (Medium)**: Thread view support
7. **P3 (Low)**: Contact completion integration

## Risks and Mitigations

### Risk 1: Breaking Existing Functionality
**Impact**: High - Users rely on draft/compose workflow
**Mitigation**: All changes additive; preserve existing compose/draft infrastructure

### Risk 2: Keybinding Conflicts
**Impact**: Medium - May conflict with user's global mappings
**Mitigation**: Use buffer-local mappings; document all bindings; make configurable

### Risk 3: Himalaya CLI Compatibility
**Impact**: Medium - CLI version differences may cause issues
**Mitigation**: Check CLI version on startup; handle gracefully

## Appendix

### Search Queries Used
- himalaya.nvim neovim plugin documentation features 2025

### References
- [himalaya.nvim GitHub](https://github.com/JostBrand/himalaya.nvim) - Official Neovim frontend
- himalaya CLI help output (message, envelope, flag subcommands)
- Local codebase: lua/neotex/plugins/tools/himalaya/**/*.lua

### Files Analyzed
- init.lua, _plugin.lua, himalaya-plugin.lua
- commands/init.lua, commands/email.lua, commands/ui.lua
- config/init.lua, config/ui.lua
- core/state.lua, core/config.lua
- ui/main.lua, ui/email_list.lua, ui/email_preview.lua, ui/sidebar.lua
- data/drafts.lua, data/cache.lua

### Code Metrics
- Total files: 90+
- Lines of code: ~15,000+ (estimated)
- Test files: 40+
- Commands defined: 50+
