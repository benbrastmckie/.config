# Implementation Plan: Himalaya Keybinding Refactor (Revised)

- **Task**: 67 - Review and revise himalaya compose buffer mappings
- **Version**: 002
- **Status**: [COMPLETED]
- **Effort**: 2-3 hours
- **Dependencies**: Tasks 64, 65 (related keymap fixes)
- **Research Inputs**: [research-001.md](../reports/research-001.md), [research-002.md](../reports/research-002.md)
- **Artifacts**: plans/implementation-002.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Revision Summary

**Version 001**: Focused narrowly on compose buffer `<leader>ms` conflict
**Version 002**: Comprehensive refactor addressing all 5 Himalaya environments with unified 2-letter mapping scheme

### Key Changes from v001

1. **Send mapping changed**: `<leader>ms` -> `<leader>me` (avoids sync conflict, E for Email/Envelope)
2. **Compose subgroup eliminated**: Remove `<leader>mc*` 3-letter group entirely
3. **Broader scope**: Addresses all environments, not just compose buffer
4. **Email actions subgroup simplified**: `<leader>me*` 3-letter mappings removed from non-compose contexts

## Overview

Comprehensive refactor of Himalaya keybindings across 5 environments to enforce 2-letter maximum for all leader mappings while maintaining clear, predictable functionality.

### Research Integration

Research report 002 identified:
- 5 distinct environments: email list, email preview, email reader, compose buffer, pickers
- Critical `<leader>ms` conflict between "sync inbox" (global) and "send email" (compose)
- 3-letter mappings (`<leader>mcd`, `<leader>mce`, etc.) violating 2-letter maximum
- Well-organized single-letter quick actions in sidebar (preserve these)

### Final Mapping Scheme

**Compose Buffer (2-letter maximum)**:
| Key | Action | Notes |
|-----|--------|-------|
| `<leader>me` | Send email | E for Email/Envelope |
| `<leader>md` | Save draft | D for Draft |
| `<leader>mq` | Quit/discard | Q for Quit |
| `<C-d>` | Save draft | Keep buffer-local |
| `<C-q>` | Discard | Keep buffer-local |
| `<C-a>` | Attach | Keep buffer-local |

**Global Mail (unchanged)**: `<leader>ms` remains "sync inbox"

## Goals & Non-Goals

**Goals**:
- Enforce 2-letter maximum for ALL leader mappings
- Use `<leader>me` for send in compose buffers (context-sensitive)
- Remove `<leader>mc*` 3-letter subgroup entirely
- Update help menus to reflect new scheme
- Maintain backward compatibility where possible

**Non-Goals**:
- Changing single-letter quick actions in sidebar (they're well-organized)
- Modifying Ctrl-based buffer-local shortcuts (they're fine)
- Changing underlying himalaya commands

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| User muscle memory for `<leader>mce` | Medium | Medium | Keep as deprecated alias temporarily |
| which-key conditional registration | Low | Low | Test thoroughly before committing |
| Conflict with other `<leader>me` mappings | Medium | Low | Audit all configurations for conflicts |

## Implementation Phases

### Phase 1: Add 2-letter compose mappings [COMPLETED]

**Goal**: Add new 2-letter compose buffer mappings in separate wk.add block.

**Tasks**:
- [ ] Create new wk.add block after main mail group for compose-buffer-only mappings
- [ ] Add `<leader>me` (send email) with `cond = is_compose_buffer`
- [ ] Add `<leader>md` (save draft) with `cond = is_compose_buffer`
- [ ] Add `<leader>mq` (quit/discard) with `cond = is_compose_buffer`
- [ ] Ensure new block runs AFTER the main mail mappings block

**Timing**: 20 minutes

**Files to modify**:
- `lua/neotex/plugins/editor/which-key.lua`

**Verification**:
- Open compose buffer with `:HimalayaWrite`
- Press `<leader>` and verify `me`, `md`, `mq` appear with compose-specific descriptions
- Verify mappings only appear in compose buffers

---

### Phase 2: Remove 3-letter compose mappings [COMPLETED]

**Goal**: Remove the `<leader>mc*` subgroup that violates 2-letter maximum.

**Tasks**:
- [ ] Remove `<leader>mc` group definition (compose subgroup)
- [ ] Remove `<leader>mcd` (save draft) - replaced by `<leader>md`
- [ ] Remove `<leader>mcD` (discard) - replaced by `<leader>mq`
- [ ] Remove `<leader>mce` (send) - replaced by `<leader>me`
- [ ] Remove `<leader>mcq` (quit) - replaced by `<leader>mq`
- [ ] Remove the conditional `<leader>ms` (send) mapping that was causing the conflict

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/editor/which-key.lua`

**Verification**:
- Open compose buffer
- Verify `<leader>mc` subgroup no longer appears in which-key popup
- Verify `<leader>me`, `<leader>md`, `<leader>mq` work correctly

---

### Phase 3: Update help menus [COMPLETED]

**Goal**: Update help content to reflect new 2-letter mapping scheme.

**Tasks**:
- [ ] Update or create compose-specific help content showing:
  - `<leader>me` - Send email
  - `<leader>md` - Save draft
  - `<leader>mq` - Quit/discard
  - `<C-d>` - Save draft (Ctrl shortcut)
  - `<C-q>` - Discard (Ctrl shortcut)
  - `<C-a>` - Attach file
- [ ] Wire up `?` in compose buffer to show compose-specific help
- [ ] Ensure help menu in sidebar doesn't show compose mappings

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua` - Add compose help section
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Ensure `?` calls appropriate help

**Verification**:
- Open compose buffer and press `?`
- Verify help shows 2-letter compose shortcuts
- Open sidebar and press `?`
- Verify sidebar help doesn't show compose-only mappings

---

### Phase 4: Update comments and documentation [COMPLETED]

**Goal**: Update comments in codebase to reflect the actual mapping scheme.

**Tasks**:
- [ ] Update comment in `config/ui.lua` about available mappings (was referencing `<leader>mce`)
- [ ] Verify email_composer.lua comments are accurate
- [ ] Remove any references to the old `<leader>mc*` subgroup

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/ui.lua`
- `lua/neotex/plugins/tools/himalaya/ui/email_composer.lua`

**Verification**:
- Read through comments in modified files
- Ensure no references to deprecated `<leader>mc*` mappings

---

### Phase 5: Verification and testing [COMPLETED]

**Goal**: Comprehensive testing of all compose buffer mappings.

**Tasks**:
- [ ] Test `<leader>me` sends email from compose buffer
- [ ] Test `<leader>md` saves draft
- [ ] Test `<leader>mq` discards email
- [ ] Test `<leader>ms` syncs inbox from non-compose buffer (not changed)
- [ ] Test which-key popup shows correct descriptions in both contexts
- [ ] Test help menu shows correct information
- [ ] Run neovim headless module load tests

**Timing**: 20 minutes

**Verification**:
```bash
nvim --headless -c "lua require('neotex.plugins.editor.which-key')" -c "q"
nvim --headless -c "lua require('neotex.plugins.tools.himalaya.ui.folder_help')" -c "q"
nvim --headless -c "lua require('neotex.plugins.tools.himalaya.config.ui')" -c "q"
```

---

## Testing & Validation

- [ ] Module loads without errors in headless mode
- [ ] `<leader>me` sends email in compose buffer
- [ ] `<leader>md` saves draft in compose buffer
- [ ] `<leader>mq` discards in compose buffer
- [ ] `<leader>ms` syncs inbox in non-compose buffers
- [ ] Help menu shows 2-letter compose shortcuts
- [ ] No 3-letter `<leader>mc*` mappings exist

## Artifacts & Outputs

- plans/implementation-002.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (upon completion)
- Modified files:
  - `lua/neotex/plugins/editor/which-key.lua`
  - `lua/neotex/plugins/tools/himalaya/config/ui.lua`
  - `lua/neotex/plugins/tools/himalaya/ui/folder_help.lua`
  - `lua/neotex/plugins/tools/himalaya/ui/email_composer.lua`

## Rollback/Contingency

If the new mapping scheme causes issues:
1. Revert which-key.lua changes via git
2. Alternative: Keep `<leader>mc*` subgroup but document as deprecated
3. Alternative: Use `<leader>m<S-e>` (shift-e) for send to avoid conflicts
