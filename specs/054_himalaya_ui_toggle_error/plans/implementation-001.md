# Implementation Plan: Task #54

- **Task**: 54 - himalaya_ui_toggle_error
- **Status**: [IMPLEMENTING]
- **Effort**: 1.5-2 hours
- **Dependencies**: None
- **Research Inputs**: specs/054_himalaya_ui_toggle_error/reports/research-001.md
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

Fix the Himalaya UI toggle error and reorganize keybindings per user requirements. The root cause is a function name mismatch: `commands/ui.lua` calls `main.toggle()` but `ui/main.lua` exposes `toggle_email_sidebar()`. Additionally, keybindings need reorganization: rename `<leader>mo` to `<leader>mm`, remove redundant 'open without toggle' mapping, and create a compose-buffer-specific subgroup for compose actions.

### Research Integration

Research report identified:
- Root cause: `main.toggle()` does not exist; should be `main.toggle_email_sidebar()`
- `Himalaya` command may also have similar issue (calls `main.open()` which does not exist)
- Compose-specific actions (`<leader>md`, `<leader>mD`, `<leader>me`, `<leader>mq`) should appear only in compose buffers

## Goals & Non-Goals

**Goals**:
- Fix the toggle function mismatch to eliminate the nil error
- Fix potential `Himalaya` command issue (open function)
- Change `<leader>mo` keybinding to `<leader>mm` for mail toggle
- Remove 'open without toggle' mapping (not needed per user)
- Add compose-buffer-specific which-key subgroup for compose actions
- Update all documentation and references

**Non-Goals**:
- Refactoring the entire himalaya module architecture
- Adding new features beyond the scope of this fix
- Changing other keybinding patterns

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Breaking other callers of toggle/open functions | Medium | Low | Search for all callers before changes |
| Which-key conditional groups not working as expected | Medium | Medium | Test with and without compose buffer active |
| User muscle memory disruption from keybinding change | Low | Low | User explicitly requested this change |

## Implementation Phases

### Phase 1: Fix Toggle and Open Function Calls [COMPLETED]

**Goal**: Fix the nil function errors in commands/ui.lua

**Tasks**:
- [ ] Update `HimalayaToggle` command to call `main.toggle_email_sidebar()` instead of `main.toggle()`
- [ ] Update `Himalaya` command to call proper function (either `main.show_email_list({})` or add `open()` wrapper)
- [ ] Add `M.toggle` and `M.open` aliases in `ui/main.lua` for API consistency (optional but recommended)

**Timing**: 20 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/commands/ui.lua` - Fix function calls (lines 22, 32)
- `lua/neotex/plugins/tools/himalaya/ui/main.lua` - Add aliases (optional)

**Verification**:
- Run `:HimalayaToggle` without error
- Run `:Himalaya` without error
- Verify sidebar opens and closes correctly

---

### Phase 2: Update Keybinding from mo to mm [COMPLETED]

**Goal**: Change the toggle sidebar keybinding from `<leader>mo` to `<leader>mm`

**Tasks**:
- [ ] Update which-key.lua: change `<leader>mo` to `<leader>mm` for HimalayaToggle
- [ ] Remove any 'open without toggle' mapping if it exists (research indicates `<leader>ml` was mentioned in wizard)
- [ ] Search codebase for any references to `<leader>mo` and update

**Timing**: 20 minutes

**Files to modify**:
- `lua/neotex/plugins/editor/which-key.lua` - Change keybinding (line 539)
- `lua/neotex/plugins/tools/himalaya/README.md` - Update documentation

**Verification**:
- `<leader>mm` toggles the Himalaya sidebar
- `<leader>mo` no longer works (or is unmapped)

---

### Phase 3: Create Compose-Buffer-Specific Subgroup [COMPLETED]

**Goal**: Move compose-specific actions to a subgroup that only appears when in a compose buffer

**Tasks**:
- [ ] Create a compose-specific subgroup `<leader>mc` (compose) within the mail group
- [ ] Move compose-specific keybindings under this subgroup:
  - `<leader>mcd` - save draft (was `<leader>md`)
  - `<leader>mcD` - discard email (was `<leader>mD`)
  - `<leader>mce` - send email (was `<leader>me`)
  - `<leader>mcq` - quit/discard (was `<leader>mq`)
- [ ] Add condition to the compose subgroup to only show when `is_compose_buffer()` returns true
- [ ] Keep global mail actions at the `<leader>m` level

**Timing**: 40 minutes

**Files to modify**:
- `lua/neotex/plugins/editor/which-key.lua` - Add compose subgroup with conditional display

**Verification**:
- Open Himalaya sidebar: compose group not visible in which-key
- Open compose buffer: compose group visible in which-key
- All compose actions work from compose buffer
- Non-compose actions still work globally

---

### Phase 4: Update Documentation [IN PROGRESS]

**Goal**: Update all documentation to reflect keybinding changes

**Tasks**:
- [ ] Update himalaya README.md with new keybindings
- [ ] Search for any other documentation files mentioning `<leader>mo`
- [ ] Document the compose-buffer-specific subgroup

**Timing**: 20 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/README.md`
- Any other documentation files found

**Verification**:
- Documentation accurately reflects new keybindings
- No outdated references to `<leader>mo`

---

### Phase 5: Verification and Testing [NOT STARTED]

**Goal**: Verify all changes work correctly

**Tasks**:
- [ ] Test `:HimalayaToggle` command
- [ ] Test `:Himalaya` command
- [ ] Test `<leader>mm` keybinding
- [ ] Test compose-specific actions from compose buffer
- [ ] Verify which-key shows correct groups based on context
- [ ] Run `nvim --headless -c "lua require('neotex.plugins.tools.himalaya')" -c "q"` to verify module loads

**Timing**: 20 minutes

**Files to modify**: None (testing only)

**Verification**:
- All tests pass
- No Lua errors on startup
- Keybindings work as expected

## Testing & Validation

- [ ] `:HimalayaToggle` opens/closes sidebar without error
- [ ] `:Himalaya` opens email client without error
- [ ] `<leader>mm` toggles sidebar
- [ ] `<leader>mo` is unmapped
- [ ] Compose subgroup only visible in compose buffer
- [ ] All compose actions work from compose buffer
- [ ] Neovim loads without Lua errors

## Artifacts & Outputs

- `specs/054_himalaya_ui_toggle_error/plans/implementation-001.md` (this file)
- `specs/054_himalaya_ui_toggle_error/summaries/implementation-summary-{DATE}.md` (after completion)

## Rollback/Contingency

If changes cause issues:
1. Revert changes to `commands/ui.lua` and `which-key.lua`
2. Git checkout the previous versions of modified files
3. The fix is localized to 2-3 files, making rollback straightforward
