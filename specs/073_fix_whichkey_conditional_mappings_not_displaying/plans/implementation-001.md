# Implementation Plan: Task #73

- **Task**: 73 - fix_whichkey_conditional_mappings_not_displaying
- **Status**: [NOT STARTED]
- **Effort**: 1.5-2 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

Fix compose-specific keybindings (`<leader>me`, `<leader>md`, `<leader>mq`) not appearing in which-key menu by replacing the `cond` parameter approach with buffer-local registration using `wk.add()` with `buffer = buf`. The `cond` parameter in which-key.nvim v3 is evaluated only once at registration time, not dynamically, making it unsuitable for filetype-conditional mappings.

### Research Integration

Research report confirms:
- GitHub Issue #880 documents this as a known limitation, closed as "Not Planned"
- The existing `after/ftplugin/tex.lua` demonstrates the correct `buffer = 0` pattern
- Buffer-local registration at buffer creation time is the recommended solution

## Goals and Non-Goals

**Goals**:
- Make `<leader>me`, `<leader>md`, `<leader>mq` visible in which-key when composing emails
- Make email preview keybindings visible when viewing emails (himalaya-email buffers)
- Follow the established pattern from `after/ftplugin/tex.lua`
- Remove deprecated `cond`-based mappings from which-key.lua

**Non-Goals**:
- Modify which-key.nvim plugin behavior
- Change the actual keybinding functionality
- Refactor other conditional mappings (e.g., pandoc group)

## Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Duplicate mappings if old code not removed | Medium | Low | Phase 3 explicitly removes cond-based mappings |
| which-key not loaded when buffer created | Low | Low | Already protected by pcall pattern |
| Email preview mappings require separate handler | Medium | Medium | Phase 2 addresses preview buffer registration |

## Implementation Phases

### Phase 1: Add buffer-local which-key registration to email_composer.lua [NOT STARTED]

**Goal**: Register compose-specific keybindings per-buffer when compose buffer is created.

**Tasks**:
- [ ] Add which-key registration in `setup_compose_keymaps(buf)` function
- [ ] Include `<leader>me` (send email), `<leader>md` (save draft), `<leader>mq` (quit/discard)
- [ ] Use `buffer = buf` (specific buffer number, not `buffer = 0`)
- [ ] Protect with `pcall(require, "which-key")` pattern

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_composer.lua` - Add which-key buffer-local registration in setup_compose_keymaps function (after line 135)

**Verification**:
- Open compose buffer with `:HimalayaWrite`
- Press `<leader>m` and verify `e`, `d`, `q` mappings appear
- Verify mappings do NOT appear in non-compose buffers

---

### Phase 2: Add buffer-local which-key registration to email preview [NOT STARTED]

**Goal**: Register email preview keybindings when opening email preview buffers.

**Tasks**:
- [ ] Identify where himalaya-email buffers are created (likely in email preview module)
- [ ] Add which-key registration for preview keybindings (`<leader>mr`, `<leader>mR`, `<leader>mf`, `<leader>md`, `<leader>ma`, `<leader>mn`, `<leader>m/`)
- [ ] Use `buffer = buf` pattern matching Phase 1

**Timing**: 45 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` or similar - Add which-key registration when preview buffer is created

**Verification**:
- Open an email from the list
- Press `<leader>m` and verify preview keybindings appear
- Verify mappings do NOT appear in non-preview buffers

---

### Phase 3: Remove deprecated cond-based mappings from which-key.lua [NOT STARTED]

**Goal**: Clean up which-key.lua by removing mappings now handled per-buffer.

**Tasks**:
- [ ] Remove compose buffer keymaps block (lines 546-551)
- [ ] Remove email preview keymaps block (lines 553-583)
- [ ] Remove `is_mail` helper function if no longer used
- [ ] Remove `is_himalaya_email` helper function if no longer used

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/editor/which-key.lua` - Remove lines 546-583 (compose and preview keymaps with cond)

**Verification**:
- Verify which-key.lua loads without errors
- Verify no duplicate mappings appear
- Verify other himalaya keymaps (non-conditional) still work

---

### Phase 4: Testing and validation [NOT STARTED]

**Goal**: Comprehensive testing of all modified functionality.

**Tasks**:
- [ ] Test compose buffer keybindings appear in which-key menu
- [ ] Test email preview keybindings appear in which-key menu
- [ ] Test keybindings do not appear in unrelated buffers
- [ ] Test keybinding functionality still works (send, draft, discard, reply, etc.)
- [ ] Verify no regression in other himalaya features

**Timing**: 20 minutes

**Files to modify**: None (testing only)

**Verification**:
- Full workflow test: open sidebar, compose email, verify keybindings visible and functional
- Full workflow test: open email from list, verify preview keybindings visible and functional
- Open unrelated file type (e.g., Lua), verify no himalaya-specific keybindings appear

## Testing and Validation

- [ ] Compose buffer: `<leader>me`, `<leader>md`, `<leader>mq` appear in which-key menu
- [ ] Email preview: `<leader>mr`, `<leader>mR`, `<leader>mf`, `<leader>md`, `<leader>ma`, `<leader>mn`, `<leader>m/` appear
- [ ] Non-himalaya buffers: none of the above keybindings appear
- [ ] All keybindings execute their intended functions correctly
- [ ] No errors in nvim startup or plugin loading

## Artifacts and Outputs

- `lua/neotex/plugins/tools/himalaya/ui/email_composer.lua` - Modified with which-key registration
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Modified with which-key registration (or relevant file)
- `lua/neotex/plugins/editor/which-key.lua` - Cleaned up, cond-based mappings removed
- `specs/073_fix_whichkey_conditional_mappings_not_displaying/summaries/implementation-summary-YYYYMMDD.md`

## Rollback/Contingency

If implementation fails:
1. Revert changes to `email_composer.lua`
2. Revert changes to email preview module
3. Restore removed lines in `which-key.lua`
4. The cond-based approach, while not displaying in which-key, does not break functionality

All changes are additive (buffer-local registration) followed by removal (cond-based mappings), so partial rollback is safe.
