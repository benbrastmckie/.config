# Implementation Plan: Task #84

- **Task**: 84 - Fix Himalaya email composition UX issue with disruptive header changes
- **Status**: [COMPLETED]
- **Effort**: 1-2 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md), [research-002.md](../reports/research-002.md), [research-003.md](../reports/research-003.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

Three related issues were identified during email composition in Himalaya: (1) header format changes when autosave triggers buffer reload, (2) data loss from race condition between autosave and checktime, and (3) "No draft associated with buffer" error due to incorrect argument type in save commands. The solution requires fixing the argument bug in two command definitions and disabling buffer-local autoread for compose buffers. Total implementation is approximately 5 lines of code across 2 files.

### Research Integration

- **research-001.md**: Identified autoread/checktime as root cause of header changes; recommended `vim.bo[buf].autoread = false`
- **research-002.md**: Confirmed data loss race condition between autosave clearing modified flag and FileChangedShell reloading
- **research-003.md**: Discovered critical argument bug where `save_draft(true)` passes boolean instead of buffer number

## Goals & Non-Goals

**Goals**:
- Fix the "No draft associated with buffer" error when using HimalayaSaveDraft/HimalayaDraftSave commands
- Prevent automatic buffer reload that causes header format changes during email composition
- Prevent data loss from race condition between autosave and checktime
- Maintain simplified header format in buffer while preserving full MIME on disk

**Non-Goals**:
- Changing the dual-format architecture (simplified buffer view vs full MIME on disk)
- Modifying global autoread behavior or FileChangedShell autocmd
- Implementing buftype='acwrite' (deferred as optional future enhancement)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Other code paths call save_draft incorrectly | Low | Low | Grep for `save_draft(true)` patterns after fix |
| Autoread disable affects external file sync | Minor | Low | User can manually reload with :e! if needed |
| Existing buffers not retroactively fixed | Minor | Low | Affects only new compose sessions |

## Implementation Phases

### Phase 1: Fix Argument Bug in Email Commands [COMPLETED]

**Goal**: Correct the `save_draft(true)` calls to pass proper buffer number and trigger arguments

**Tasks**:
- [ ] Edit `lua/neotex/plugins/tools/himalaya/commands/email.lua` line 90
- [ ] Change `composer.save_draft(true)` to `composer.save_draft(vim.api.nvim_get_current_buf(), 'manual')`
- [ ] Edit same file line 138
- [ ] Change `email_composer.save_draft(true)` to `email_composer.save_draft(vim.api.nvim_get_current_buf(), 'manual')`

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/commands/email.lua` - Fix HimalayaSaveDraft (line 90) and HimalayaDraftSave (line 138) commands

**Verification**:
- Run `:HimalayaWrite` to compose new email
- Press `<leader>md` (HimalayaSaveDraft) - should succeed without "No draft associated with buffer" error
- Verify "Draft saved" notification appears

---

### Phase 2: Disable Autoread for Compose Buffers [COMPLETED]

**Goal**: Prevent automatic buffer reload when autosave writes full MIME headers to disk

**Tasks**:
- [ ] Edit `lua/neotex/plugins/tools/himalaya/data/drafts.lua` in M.create() function
- [ ] Add `vim.bo[buf].autoread = false` after line 167 (after setting modified = false)
- [ ] Edit same file in M.open() function
- [ ] Add `vim.bo[buf].autoread = false` after line 605 (after setting modified = false)

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/data/drafts.lua` - Add autoread disable in M.create() and M.open()

**Verification**:
- Create new email with `:HimalayaWrite`
- Type content in body
- Wait for autosave (5 seconds)
- Verify headers remain simplified (From/To/Cc/Bcc/Subject only)
- Switch windows and back (triggers FocusGained)
- Verify no "File changed on disk" message
- Verify all content preserved

---

### Phase 3: Integration Testing [COMPLETED]

**Goal**: Verify all three issues are resolved across different workflows

**Tasks**:
- [ ] Test new email composition workflow end-to-end
- [ ] Test reply workflow with quoted text
- [ ] Test forward workflow
- [ ] Test manual draft save with `<leader>md`
- [ ] Test autosave behavior (wait 5+ seconds, switch windows)
- [ ] Verify headers stay simplified throughout entire session
- [ ] Verify `:e!` still works for manual reload when explicitly requested

**Timing**: 30 minutes

**Verification**:
- All workflows complete without errors
- Headers remain simplified throughout session
- No data loss during window switching
- Manual save commands work correctly

## Testing & Validation

- [ ] `:HimalayaWrite` creates compose buffer with simplified headers
- [ ] `<leader>md` saves draft without error
- [ ] Autosave (5 seconds) does not cause header format change
- [ ] Window focus change does not trigger buffer reload
- [ ] Reply workflow maintains simplified headers
- [ ] Forward workflow maintains simplified headers
- [ ] `:e!` explicitly reloads buffer (expected behavior, full MIME shown)
- [ ] Draft content persists correctly to disk in full MIME format

## Artifacts & Outputs

- `lua/neotex/plugins/tools/himalaya/commands/email.lua` - Fixed command definitions
- `lua/neotex/plugins/tools/himalaya/data/drafts.lua` - Buffer-local autoread disabled
- `specs/084_fix_disruptive_header_changes_himalaya_email/summaries/implementation-summary-YYYYMMDD.md` - Implementation summary

## Rollback/Contingency

If issues arise:
1. Revert the 4-line changes (2 in email.lua, 2 in drafts.lua)
2. Both files use simple patterns that are easily reversible
3. No database migrations or persistent state changes involved
4. Git revert of the commit will fully restore previous behavior
