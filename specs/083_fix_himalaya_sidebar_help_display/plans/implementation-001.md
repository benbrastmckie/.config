# Implementation Plan: Task #83

- **Task**: 83 - Fix Himalaya sidebar help display inaccuracies
- **Status**: [NOT STARTED]
- **Effort**: 1-2 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

This plan addresses inaccuracies in the Himalaya email sidebar help display. Research confirmed that both `gH` and `?` keybindings work, but the help display shows `gH` instead of the more standard `?`. The footer in email_list.lua also has errors (e.g., `c:compose` should be `e:compose` since `c` is for "Change folder"). The plan updates three files to use `?` consistently in help displays while keeping `gH` as an undocumented alternative.

### Research Integration

Key findings from research-001.md:
- Both `gH` and `?` are properly configured and functional (lines 255-269 of config/ui.lua)
- The folder help shows `gH` but not `?` (folder_help.lua line 81)
- The footer has incorrect keybinding labels (`c:compose` should be `e:compose`)
- The compose help already correctly shows `?` as the help key (folder_help.lua lines 159-181)

## Goals & Non-Goals

**Goals**:
- Update folder_help.lua to show `?` instead of `gH` in the "Other" section
- Simplify the footer in email_list.lua to just show `?:help`
- Update commands/ui.lua messages to reference `?` instead of `gH`
- Maintain consistency with compose help which already shows `?`

**Non-Goals**:
- Removing the `gH` keybinding from code (it works and provides an alternative)
- Adding additional keybindings to help displays
- Restructuring the entire help system

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Users accustomed to `gH` documentation may be confused | Low | Low | Keep `gH` working as undocumented alternative; `?` is more intuitive |
| Footer becomes too minimal | Low | Low | Users can press `?` to see comprehensive help |
| Inconsistent help across different contexts | Medium | Low | Verify all three files use consistent `?` pattern |

## Implementation Phases

### Phase 1: Update folder_help.lua [NOT STARTED]

**Goal**: Replace `gH` with `?` in the base_other section to match compose help pattern.

**Tasks**:
- [ ] Edit line 81 in folder_help.lua to change `gH` to `?`
- [ ] Verify the change matches the compose help format (lines 159-181)

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua` - Line 81: change `gH` to `?`

**Verification**:
- Open Himalaya sidebar, press `?` to confirm help displays correctly
- Verify the "Other" section shows `?` instead of `gH`

---

### Phase 2: Simplify email_list.lua footer [NOT STARTED]

**Goal**: Replace the verbose footer with a simple `?:help` indicator.

**Tasks**:
- [ ] Locate line 1379 in email_list.lua
- [ ] Replace the full keybinding list with simple `?:help`

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Line 1379: simplify footer

**Verification**:
- Open Himalaya email list view
- Verify footer shows `?:help` instead of the verbose mapping list
- Confirm footer is still visible and readable

---

### Phase 3: Update commands/ui.lua messages [NOT STARTED]

**Goal**: Update show_help() messages to reference `?` instead of `gH`.

**Tasks**:
- [ ] Update sidebar message (line 11) to reference `?` instead of `gH`
- [ ] Update compose message (line 12) to reference `?` instead of `gH`
- [ ] Update list message (line 13) to reference `?` instead of `gH`

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/commands/ui.lua` - Lines 11-13: update all messages

**Verification**:
- Trigger show_help() in each context (sidebar, compose, list)
- Verify messages reference `?` for full help

---

### Phase 4: Verification and Testing [NOT STARTED]

**Goal**: Verify all changes work correctly and help displays are consistent.

**Tasks**:
- [ ] Test `?` keybinding in email list view
- [ ] Test `gH` keybinding still works (undocumented alternative)
- [ ] Verify footer displays correctly
- [ ] Verify all show_help() messages are correct
- [ ] Run nvim --headless module load test

**Timing**: 15 minutes

**Verification**:
- All keybindings work as expected
- Help displays are consistent across all contexts
- No Lua errors on module load

## Testing & Validation

- [ ] Module loads without errors: `nvim --headless -c "lua require('neotex.plugins.tools.himalaya.ui.folder_help')" -c "q"`
- [ ] Module loads without errors: `nvim --headless -c "lua require('neotex.plugins.tools.himalaya.ui.email_list')" -c "q"`
- [ ] Module loads without errors: `nvim --headless -c "lua require('neotex.plugins.tools.himalaya.commands.ui')" -c "q"`
- [ ] `?` keybinding opens help in email list view
- [ ] `gH` keybinding still opens help (undocumented)
- [ ] Footer shows simplified `?:help` text
- [ ] Help popup shows `?` not `gH` in "Other" section

## Artifacts & Outputs

- plans/implementation-001.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (upon completion)

## Rollback/Contingency

All changes are simple string replacements in three files. If issues arise:
1. Revert changes to folder_help.lua line 81
2. Revert changes to email_list.lua line 1379
3. Revert changes to commands/ui.lua lines 11-13
4. Git checkout can restore original files if needed
