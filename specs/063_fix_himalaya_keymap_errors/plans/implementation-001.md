# Implementation Plan: Task #63

- **Task**: 63 - Fix himalaya keymap errors and help menu
- **Status**: [NOT STARTED]
- **Effort**: 1-2 hours
- **Dependencies**: Task 62 (keymaps restored)
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

The research confirmed that the single-letter keymaps (r, R, f, d, a, m, c, /) added in task 62 are working correctly. The errors "No email to reply to" and "No email to forward" are expected behavior when the cursor is not positioned on an email line (lines 1-5 are header/pagination/separator, emails start at line 6+).

The issue is user-facing: the help menu and footer display outdated keymap information, leading to confusion. This plan updates the help displays to accurately reflect the new single-letter keymaps.

### Research Integration

Key findings integrated into this plan:
- Keymaps in `config/ui.lua` are correctly implemented with buffer-local scope
- `folder_help.lua` shows old `<leader>me*` patterns instead of new single-letter keys
- Footer in `email_list.lua` (line 1063) needs updating to show quick action keymaps
- Error messages are technically correct but could be more helpful

## Goals & Non-Goals

**Goals**:
- Update help menu to prominently display single-letter keymaps
- Update footer to show quick action keymaps
- Improve discoverability of keymap actions for users
- Maintain backward compatibility with which-key menu (`<leader>me*`)

**Non-Goals**:
- Changing keymap logic (confirmed working correctly)
- Modifying error messages (current behavior is correct)
- Adding new keymaps beyond what task 62 implemented

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Help content exceeds window width | L | L | Test with various terminal widths |
| Footer too long for narrow sidebars | M | M | Keep footer concise, test in sidebar |

## Implementation Phases

### Phase 1: Update Help Menu [NOT STARTED]

**Goal**: Update `folder_help.lua` to display single-letter keymaps prominently while still mentioning the which-key menu for discoverability.

**Tasks**:
- [ ] Replace old `base_actions` section with new single-letter keymaps
- [ ] Add note about which-key menu availability
- [ ] Adjust window width if needed for new content

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua` - Update `base_actions` table (lines 69-79)

**Specific Changes**:

Replace lines 69-79:
```lua
local base_actions = {
  "Actions (<leader>me):",
  "  <leader>men - New email",
  "  <leader>mer - Reply",
  "  <leader>meR - Reply all",
  "  <leader>mef - Forward",
  "  <leader>med - Delete",
  "  <leader>mem - Move",
  "  <leader>me/ - Search",
  ""
}
```

With:
```lua
local base_actions = {
  "Quick Actions (on email line):",
  "  r         - Reply",
  "  R         - Reply all",
  "  f         - Forward",
  "  d         - Delete",
  "  a         - Archive",
  "  m         - Move",
  "  c         - Compose new",
  "  /         - Search",
  "",
  "Mail Menu (<leader>me):",
  "  Also available via which-key",
  ""
}
```

**Verification**:
- Open sidebar with `<leader>mm`
- Press `gH` to show help
- Verify single-letter keymaps are displayed
- Verify window displays correctly

---

### Phase 2: Update Footer [NOT STARTED]

**Goal**: Update the footer in `email_list.lua` to show quick action keymaps for better discoverability.

**Tasks**:
- [ ] Update footer line to show single-letter keymaps
- [ ] Keep footer concise to fit sidebar width

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Update footer (line 1063)

**Specific Changes**:

Replace line 1063:
```lua
table.insert(lines, '<C-d>/<C-u>:page | n/p:select | F:refresh | <leader>me:email actions | gH:help')
```

With:
```lua
table.insert(lines, '<C-d>/<C-u>:page | r/R/f:reply | d/a/m:actions | c:compose | gH:help')
```

**Verification**:
- Open sidebar with `<leader>mm`
- Check footer shows updated keymaps
- Verify footer fits in sidebar without wrapping

---

### Phase 3: Test and Verify [NOT STARTED]

**Goal**: Verify all changes work correctly and keymaps function as documented.

**Tasks**:
- [ ] Test help menu displays correctly
- [ ] Test footer displays correctly
- [ ] Test single-letter keymaps on email lines
- [ ] Test keymaps on non-email lines (verify expected error)
- [ ] Test which-key menu still works (`<leader>me`)

**Timing**: 15 minutes

**Verification**:
- All keymaps work when cursor is on email line
- Appropriate errors shown when cursor is on header/separator
- Help menu accurately reflects available actions
- Footer provides at-a-glance keymap reference

## Testing & Validation

- [ ] Help menu shows single-letter keymaps prominently
- [ ] Footer shows quick action keymaps
- [ ] All documented keymaps work correctly on email lines
- [ ] which-key menu (`<leader>me`) still accessible
- [ ] No visual glitches in help popup or footer

## Artifacts & Outputs

- Updated `folder_help.lua` with new help content
- Updated `email_list.lua` with new footer

## Rollback/Contingency

If issues arise, revert the two file changes:
- Restore original `base_actions` in `folder_help.lua`
- Restore original footer line in `email_list.lua`
