# Implementation Plan: Review Himalaya Compose Mappings

- **Task**: 67 - Review and revise himalaya compose buffer mappings
- **Status**: [NOT STARTED]
- **Effort**: 1-2 hours
- **Dependencies**: Tasks 64, 65 (related keymap fixes)
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

The compose buffer mappings in himalaya have two issues: (1) the `<leader>ms` send mapping is overridden by the unconditional sync inbox mapping due to registration order in the same wk.add block, and (2) compose-specific shortcuts use 3-letter patterns (`<leader>mcd`, `<leader>mce`) which violates the 2-letter maximum requirement. The solution is to register compose-specific mappings in a separate wk.add block after the general mail mappings, ensuring conditional mappings take precedence.

### Research Integration

Research report identified:
- `<leader>ms` appears twice in the same wk.add block (lines 542 and 549 in which-key.lua)
- Unconditional mapping takes precedence over conditional one when in same block
- email_composer.lua comment suggests `<leader>ms` was the intended send mapping
- Available 2-letter keys: `<leader>md` (draft), `<leader>mq` (quit)

## Goals & Non-Goals

**Goals**:
- Make `<leader>ms` send email in compose buffers (context-sensitive)
- Add 2-letter shortcuts for save draft (`<leader>md`) and quit/discard (`<leader>mq`)
- Keep existing `<leader>mc*` subgroup for which-key discoverability
- Update help menus and comments to reflect actual mappings

**Non-Goals**:
- Changing the underlying himalaya commands (they work correctly)
- Modifying Ctrl-based shortcuts in config/ui.lua (those are fine)
- Restructuring the entire mail keymap namespace

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| which-key condition not taking precedence when in separate block | High | Low | Test with actual compose buffer after implementation |
| User confusion about context-sensitive `<leader>ms` | Medium | Medium | Document in help menu that key behavior varies by buffer type |
| Breaking existing muscle memory for `<leader>mce` users | Low | Low | Keep `<leader>mce` as alternative (backward compatible) |

## Implementation Phases

### Phase 1: Restructure which-key compose mappings [NOT STARTED]

**Goal**: Move compose-specific mappings to a separate wk.add block that runs after general mail mappings, ensuring conditional mappings override unconditional ones.

**Tasks**:
- [ ] Remove the conditional `<leader>ms` (send) from the main mail wk.add block (line 549)
- [ ] Create a new wk.add block after the main mail group for compose-buffer overrides
- [ ] Add `<leader>ms` (send email) with `cond = is_compose_buffer` in the new block
- [ ] Add `<leader>md` (save draft) with `cond = is_compose_buffer`
- [ ] Add `<leader>mq` (quit/discard) with `cond = is_compose_buffer`
- [ ] Keep existing `<leader>mc*` subgroup for discoverability (no changes needed)

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/editor/which-key.lua` - Restructure compose mappings registration

**Verification**:
- Open a compose buffer with `:HimalayaWrite`
- Verify `<leader>ms` shows "send email" in which-key popup
- Verify `<leader>md` shows "save draft" in which-key popup
- Verify `<leader>mq` shows "discard" in which-key popup
- Outside compose buffer, verify `<leader>ms` shows "sync inbox"

---

### Phase 2: Update comments and documentation [NOT STARTED]

**Goal**: Update comments in related files to reflect the actual 2-letter mapping scheme.

**Tasks**:
- [ ] Update comment in `config/ui.lua` line 397-398 to reference `<leader>ms` instead of `<leader>mce`
- [ ] Verify email_composer.lua comment (lines 137-141) is accurate (already mentions `<leader>ms`)

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Update comment

**Verification**:
- Read the updated comments to confirm accuracy

---

### Phase 3: Update help menu content [NOT STARTED]

**Goal**: Add compose-specific shortcuts to the help menu shown in compose buffers.

**Tasks**:
- [ ] Create a new help content function for compose buffers in folder_help.lua (or create compose_help.lua)
- [ ] Add compose shortcuts section showing:
  - `<leader>ms` - Send email
  - `<leader>md` - Save draft
  - `<leader>mq` - Quit/discard
  - `<C-d>` - Save draft (Ctrl shortcut)
  - `<C-q>` - Discard (Ctrl shortcut)
  - `<C-a>` - Attach file
- [ ] Wire up the `?` keymap in compose buffer to show compose-specific help

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua` - Add compose help content
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Ensure `?` calls compose help

**Verification**:
- Open compose buffer and press `?`
- Verify help popup shows 2-letter compose shortcuts

---

### Phase 4: Verification and testing [NOT STARTED]

**Goal**: Comprehensive testing of all compose buffer mappings.

**Tasks**:
- [ ] Test `<leader>ms` sends email from compose buffer
- [ ] Test `<leader>ms` syncs inbox from non-compose mail buffer
- [ ] Test `<leader>md` saves draft
- [ ] Test `<leader>mq` discards email
- [ ] Test `<leader>mce` still works (backward compatibility)
- [ ] Test which-key popup shows correct descriptions in both contexts
- [ ] Run neovim headless module load test

**Timing**: 15 minutes

**Verification**:
```bash
nvim --headless -c "lua require('neotex.plugins.editor.which-key')" -c "q"
nvim --headless -c "lua require('neotex.plugins.tools.himalaya.ui.folder_help')" -c "q"
nvim --headless -c "lua require('neotex.plugins.tools.himalaya.config.ui')" -c "q"
```

---

## Testing & Validation

- [ ] Module loads without errors in headless mode
- [ ] `<leader>ms` is context-sensitive (send in compose, sync elsewhere)
- [ ] `<leader>md` saves draft in compose buffer
- [ ] `<leader>mq` discards in compose buffer
- [ ] Existing `<leader>mc*` mappings still work
- [ ] Help menu shows accurate information

## Artifacts & Outputs

- plans/implementation-001.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (upon completion)
- Modified files:
  - `lua/neotex/plugins/editor/which-key.lua`
  - `lua/neotex/plugins/tools/himalaya/config/ui.lua`
  - `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua`

## Rollback/Contingency

If the conditional mapping approach fails:
1. Revert which-key.lua changes via git
2. Alternative: Use different key for compose send (e.g., `<leader>mE` with capital E)
3. Alternative: Remove sync inbox shortcut entirely (only accessible via full sync `<leader>mS`)
